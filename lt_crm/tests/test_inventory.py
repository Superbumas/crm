"""Tests for inventory services."""
import pytest
import pandas as pd
from io import StringIO
from decimal import Decimal
from app.models.product import Product
from app.models.stock import StockMovement, MovementReasonCode
from app.models.order import Order, OrderItem, OrderStatus
from app.services.inventory import (
    import_products_from_dataframe,
    adjust_stock,
    reserve_stock,
    process_order_stock_changes
)
from app.services.import_service import import_products, parse_product_file, validate_product_data


def test_import_products_from_dataframe(app):
    """Test importing products from a DataFrame."""
    with app.app_context():
        # Create a test DataFrame
        data = {
            "sku": ["TEST001", "TEST002"],
            "name": ["Test Product 1", "Test Product 2"],
            "price_final": [19.99, 29.99],
            "quantity": [10, 20]
        }
        df = pd.DataFrame(data)
        
        # Import products
        summary = import_products_from_dataframe(df)
        
        # Check summary
        assert summary["created"] == 2
        assert summary["errors"] == 0
        
        # Check products were created
        products = Product.query.all()
        assert len(products) == 2
        
        # Check product 1
        product1 = Product.query.filter_by(sku="TEST001").first()
        assert product1.name == "Test Product 1"
        assert float(product1.price_final) == 19.99
        assert product1.quantity == 10
        
        # Check stock movements were created
        movements = StockMovement.query.all()
        assert len(movements) == 2
        
        # Check movements are linked to products
        assert movements[0].product_id == product1.id
        assert movements[0].reason_code == MovementReasonCode.IMPORT


def test_import_products_update_existing(app):
    """Test updating existing products during import."""
    with app.app_context():
        # Create existing product
        product = Product(
            sku="TEST001",
            name="Original Name",
            price_final=Decimal("15.99"),
            quantity=5
        )
        db.session.add(product)
        db.session.commit()
        
        # Create import DataFrame with updated data
        data = {
            "sku": ["TEST001"],
            "name": ["Updated Name"],
            "price_final": [25.99],
            "quantity": [10]
        }
        df = pd.DataFrame(data)
        
        # Import products
        summary = import_products_from_dataframe(df)
        
        # Check summary
        assert summary["updated"] == 1
        assert summary["created"] == 0
        
        # Verify product was updated
        updated_product = Product.query.filter_by(sku="TEST001").first()
        assert updated_product.name == "Updated Name"
        assert float(updated_product.price_final) == 25.99
        assert updated_product.quantity == 10
        
        # Check stock movement was created for quantity change
        movement = StockMovement.query.first()
        assert movement.product_id == updated_product.id
        assert movement.qty_delta == 5  # From 5 to 10 = +5
        assert movement.reason_code == MovementReasonCode.IMPORT


def test_adjust_stock(app):
    """Test adjusting stock quantities."""
    with app.app_context():
        # Create a product
        product = Product(
            sku="TEST001",
            name="Test Product",
            price_final=Decimal("19.99"),
            quantity=10
        )
        db.session.add(product)
        db.session.commit()
        
        # Adjust stock
        movement = adjust_stock(
            product_id=product.id,
            qty_delta=-3,
            reason_code=MovementReasonCode.SALE,
            note="Test adjustment"
        )
        
        # Check product quantity was updated
        product = Product.query.get(product.id)
        assert product.quantity == 7
        
        # Check movement record
        assert movement.product_id == product.id
        assert movement.qty_delta == -3
        assert movement.reason_code == MovementReasonCode.SALE
        assert movement.note == "Test adjustment"


def test_reserve_stock(app):
    """Test reserving stock for orders."""
    with app.app_context():
        # Create a product
        product = Product(
            sku="TEST001",
            name="Test Product",
            price_final=Decimal("19.99"),
            quantity=10
        )
        db.session.add(product)
        
        # Create an order
        order = Order(
            order_number="TEST-ORDER",
            total_amount=Decimal("19.99"),
            status=OrderStatus.NEW
        )
        db.session.add(order)
        db.session.commit()
        
        # Reserve stock
        result = reserve_stock(
            product_id=product.id,
            quantity=3,
            order_id=order.id
        )
        
        # Check result
        assert result is True
        
        # Check product quantity wasn't changed
        product = Product.query.get(product.id)
        assert product.quantity == 10
        
        # Check movement record
        movement = StockMovement.query.first()
        assert movement.product_id == product.id
        assert movement.qty_delta == 0  # No actual change
        assert movement.reason_code == MovementReasonCode.SALE
        assert str(order.id) in movement.note


def test_process_order_stock_changes(app):
    """Test processing stock changes when order status changes."""
    with app.app_context():
        # Create products
        product1 = Product(
            sku="TEST001",
            name="Test Product 1",
            price_final=Decimal("19.99"),
            quantity=10
        )
        product2 = Product(
            sku="TEST002",
            name="Test Product 2",
            price_final=Decimal("29.99"),
            quantity=20
        )
        db.session.add_all([product1, product2])
        
        # Create an order with items
        order = Order(
            order_number="ORD-001",
            total_amount=Decimal("69.97"),
            status=OrderStatus.PAID
        )
        db.session.add(order)
        db.session.flush()
        
        # Add order items
        item1 = OrderItem(
            order_id=order.id,
            product_id=product1.id,
            quantity=2,
            price=Decimal("19.99")
        )
        item2 = OrderItem(
            order_id=order.id,
            product_id=product2.id,
            quantity=1,
            price=Decimal("29.99")
        )
        db.session.add_all([item1, item2])
        db.session.commit()
        
        # Change order status to shipped
        order.status = OrderStatus.SHIPPED
        db.session.commit()
        
        # Process stock changes
        movements = process_order_stock_changes(order, OrderStatus.PAID)
        
        # Check movements
        assert len(movements) == 2
        
        # Check product quantities were updated
        product1 = Product.query.get(product1.id)
        product2 = Product.query.get(product2.id)
        assert product1.quantity == 8  # 10 - 2
        assert product2.quantity == 19  # 20 - 1
        
        # Test returned order
        order.status = OrderStatus.RETURNED
        db.session.commit()
        
        movements = process_order_stock_changes(order, OrderStatus.SHIPPED)
        
        # Check product quantities were restored
        product1 = Product.query.get(product1.id)
        product2 = Product.query.get(product2.id)
        assert product1.quantity == 10  # 8 + 2
        assert product2.quantity == 20  # 19 + 1 