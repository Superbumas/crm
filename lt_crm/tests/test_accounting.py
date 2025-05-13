"""Tests for accounting services."""
import pytest
from datetime import datetime, date
from decimal import Decimal
from app.extensions import db
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.services.accounting import (
    Account,
    Transaction,
    Entry,
    create_transaction,
    record_order_accounting,
    setup_default_accounts
)


def test_setup_default_accounts(app):
    """Test setting up default accounts."""
    with app.app_context():
        # Set up accounts
        result = setup_default_accounts()
        
        # Check result
        assert result["created"] > 0
        assert result["existing"] == 0
        
        # Check that accounts were created
        accounts = Account.query.all()
        assert len(accounts) == 9  # Based on the default accounts list
        
        # Check specific accounts
        sales_account = Account.query.filter_by(code="4000").first()
        assert sales_account.name == "Sales Revenue"
        assert sales_account.account_type == "revenue"
        
        # Run again to test the "existing" case
        result = setup_default_accounts()
        assert result["created"] == 0
        assert result["existing"] == 9


def test_create_transaction(app):
    """Test creating a accounting transaction with entries."""
    with app.app_context():
        # Set up accounts
        setup_default_accounts()
        
        # Get account IDs
        sales_account = Account.query.filter_by(code="4000").first()
        ar_account = Account.query.filter_by(code="1200").first()
        
        # Create transaction data
        transaction_date = date.today()
        entries_data = [
            {
                "account_id": sales_account.id,
                "credit_amount": Decimal("100.00"),
                "description": "Test sale"
            },
            {
                "account_id": ar_account.id,
                "debit_amount": Decimal("100.00"),
                "description": "Test receivable"
            }
        ]
        
        # Create transaction
        transaction = create_transaction(
            date=transaction_date,
            reference_type="test",
            reference_id="TEST-001",
            description="Test transaction",
            entries_data=entries_data
        )
        
        # Check transaction
        assert transaction.date == transaction_date
        assert transaction.reference_type == "test"
        assert transaction.reference_id == "TEST-001"
        assert transaction.total_amount == Decimal("100.00")
        
        # Check entries
        entries = transaction.entries.all()
        assert len(entries) == 2
        
        # Check transaction is balanced
        assert transaction.is_balanced is True


def test_transaction_is_balanced(app):
    """Test the is_balanced property of transactions."""
    with app.app_context():
        # Create a transaction
        transaction = Transaction(
            date=date.today(),
            reference_type="test",
            reference_id="TEST-001",
            description="Test transaction",
            total_amount=Decimal("100.00")
        )
        db.session.add(transaction)
        db.session.flush()
        
        # Add balanced entries
        entry1 = Entry(
            transaction_id=transaction.id,
            account_id=1,  # Placeholder
            debit_amount=Decimal("50.00")
        )
        entry2 = Entry(
            transaction_id=transaction.id,
            account_id=2,  # Placeholder
            debit_amount=Decimal("50.00")
        )
        entry3 = Entry(
            transaction_id=transaction.id,
            account_id=3,  # Placeholder
            credit_amount=Decimal("100.00")
        )
        db.session.add_all([entry1, entry2, entry3])
        db.session.flush()
        
        # Check balance
        assert transaction.is_balanced is True
        
        # Make unbalanced
        entry4 = Entry(
            transaction_id=transaction.id,
            account_id=4,  # Placeholder
            debit_amount=Decimal("10.00")
        )
        db.session.add(entry4)
        db.session.flush()
        
        # Check balance again
        assert transaction.is_balanced is False


def test_record_order_accounting(app):
    """Test recording accounting entries for a paid order."""
    with app.app_context():
        # Set up accounts
        setup_default_accounts()
        
        # Create a product
        product = Product(
            sku="TEST001",
            name="Test Product",
            price_final=Decimal("100.00"),
            quantity=10
        )
        db.session.add(product)
        
        # Create an order
        order = Order(
            order_number="TEST-ORD-001",
            total_amount=Decimal("120.00"),
            tax_amount=Decimal("20.00"),
            status=OrderStatus.NEW
        )
        db.session.add(order)
        db.session.flush()
        
        # Add order item
        item = OrderItem(
            order_id=order.id,
            product_id=product.id,
            quantity=1,
            price=Decimal("100.00")
        )
        db.session.add(item)
        db.session.commit()
        
        # Test with non-paid order - should return None
        result = record_order_accounting(order.id)
        assert result is None
        
        # Change to paid and test again
        order.status = OrderStatus.PAID
        db.session.commit()
        
        transaction = record_order_accounting(order.id)
        assert transaction is not None
        
        # Check transaction details
        assert transaction.reference_type == "order"
        assert transaction.reference_id == order.order_number
        
        # Check entries
        entries = transaction.entries.all()
        assert len(entries) == 5  # Sales, VAT, AR, COGS, Inventory
        
        # Check transaction is balanced
        assert transaction.is_balanced is True
        
        # Test that calling again returns the same transaction (no duplicate)
        transaction2 = record_order_accounting(order.id)
        assert transaction2.id == transaction.id 