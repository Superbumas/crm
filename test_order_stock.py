"""Test script to verify order status changes create stock movements."""
import sys
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.order import Order, OrderItem, OrderStatus
from lt_crm.app.models.product import Product
from lt_crm.app.models.stock import StockMovement, MovementReasonCode
from lt_crm.app.services.inventory import process_order_stock_changes
from sqlalchemy import text
from decimal import Decimal

app = create_app()

with app.app_context():
    print("Testing order stock movement creation...")
    
    # Check if we have a product to use
    product = Product.query.first()
    if not product:
        print("Creating a test product...")
        product = Product(
            sku="TEST-PROD-001",
            name="Test Product",
            price_final=Decimal("19.99"),
            quantity=100
        )
        db.session.add(product)
        db.session.commit()
        print(f"Created product with ID {product.id}")
    else:
        print(f"Using existing product with ID {product.id}")
    
    # Create a test order
    order = Order(
        order_number=f"TST-{product.id}",
        status=OrderStatus.PAID,
        total_amount=Decimal("19.99"),
        shipping_name="Test Customer"
    )
    db.session.add(order)
    db.session.flush()  # Get order ID
    
    # Add order item
    order_item = OrderItem(
        order_id=order.id,
        product_id=product.id,
        quantity=1,
        price=Decimal("19.99")
    )
    db.session.add(order_item)
    db.session.commit()
    
    print(f"Created test order with ID {order.id} and status {order.status}")
    
    # Check current stock movements
    movements_before = StockMovement.query.filter(
        StockMovement.reason_code == MovementReasonCode.SALE
    ).count()
    print(f"Stock movements with SALE reason before: {movements_before}")
    
    # Capture current product quantity
    qty_before = product.quantity
    print(f"Product quantity before: {qty_before}")
    
    # Change order status to shipped
    old_status = order.status
    order.status = OrderStatus.SHIPPED
    db.session.commit()
    
    print(f"Updated order status from {old_status} to {order.status}")
    
    # Process stock movements
    movements = process_order_stock_changes(order, old_status)
    print(f"Created {len(movements)} stock movements")
    
    # Check updated stock movements
    movements_after = StockMovement.query.filter(
        StockMovement.reason_code == MovementReasonCode.SALE
    ).count()
    print(f"Stock movements with SALE reason after: {movements_after}")
    
    # Verify product quantity was updated
    db.session.refresh(product)
    qty_after = product.quantity
    print(f"Product quantity after: {qty_after}")
    print(f"Quantity change: {qty_after - qty_before}")
    
    # Get details of the new movement
    if movements:
        print("\nStock movement details:")
        for m in movements:
            print(f"ID: {m.id}, Product: {m.product_id}, Delta: {m.qty_delta}, Reason: {m.reason_code}, Note: {m.note}")
    
    print("\nTest completed.") 