"""Accounting services and models."""
from datetime import datetime
from decimal import Decimal
from sqlalchemy.exc import SQLAlchemyError
from lt_crm.app.extensions import db
from lt_crm.app.models.order import Order, OrderStatus
from lt_crm.app.models.base import TimestampMixin


class Account(TimestampMixin, db.Model):
    """Account model representing accounting accounts."""
    
    __tablename__ = "accounts"
    
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(20), unique=True, nullable=False, index=True)
    name = db.Column(db.String(100), nullable=False)
    account_type = db.Column(db.String(50), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    
    # Relationships
    entries = db.relationship("Entry", backref="account", lazy="dynamic")
    
    def __repr__(self):
        """Return string representation of the account."""
        return f"<Account {self.code}: {self.name}>"


class Transaction(TimestampMixin, db.Model):
    """Transaction model representing accounting transactions."""
    
    __tablename__ = "transactions"
    
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.Date, nullable=False, index=True)
    reference_type = db.Column(db.String(50), nullable=False)
    reference_id = db.Column(db.String(50), nullable=False)
    description = db.Column(db.String(255), nullable=True)
    total_amount = db.Column(db.Numeric(12, 2), nullable=False)
    is_posted = db.Column(db.Boolean, default=False)
    
    # Relationships
    entries = db.relationship("Entry", backref="transaction", lazy="dynamic", cascade="all, delete-orphan")
    
    def __repr__(self):
        """Return string representation of the transaction."""
        return f"<Transaction {self.id}: {self.reference_type} {self.reference_id}>"
    
    @property
    def is_balanced(self):
        """Check if transaction is balanced (debits = credits)."""
        debits = sum(entry.debit_amount or 0 for entry in self.entries)
        credits = sum(entry.credit_amount or 0 for entry in self.entries)
        return debits == credits


class Entry(TimestampMixin, db.Model):
    """Entry model representing accounting entries in a transaction."""
    
    __tablename__ = "entries"
    
    id = db.Column(db.Integer, primary_key=True)
    transaction_id = db.Column(db.Integer, db.ForeignKey("transactions.id"), nullable=False)
    account_id = db.Column(db.Integer, db.ForeignKey("accounts.id"), nullable=False)
    debit_amount = db.Column(db.Numeric(12, 2), nullable=True)
    credit_amount = db.Column(db.Numeric(12, 2), nullable=True)
    description = db.Column(db.String(255), nullable=True)
    
    def __repr__(self):
        """Return string representation of the entry."""
        return f"<Entry {self.id}: {self.account_id} DR:{self.debit_amount} CR:{self.credit_amount}>"


def create_transaction(date, reference_type, reference_id, description, entries_data):
    """
    Create a new accounting transaction with entries.
    
    Args:
        date (datetime.date): Transaction date
        reference_type (str): Type of reference (e.g., 'order', 'invoice')
        reference_id (str): Reference ID (e.g., order number)
        description (str): Transaction description
        entries_data (list): List of entry dictionaries with account_id, 
                             debit_amount, credit_amount, description
    
    Returns:
        Transaction: Created transaction
        
    Raises:
        ValueError: If transaction is not balanced
        SQLAlchemyError: If database error occurs
    """
    # Calculate total amount
    total_amount = sum(entry.get("debit_amount", 0) or 0 for entry in entries_data)
    
    # Create transaction
    transaction = Transaction(
        date=date,
        reference_type=reference_type,
        reference_id=reference_id,
        description=description,
        total_amount=total_amount
    )
    db.session.add(transaction)
    db.session.flush()  # Get transaction ID
    
    # Create entries
    for entry_data in entries_data:
        entry = Entry(
            transaction_id=transaction.id,
            account_id=entry_data["account_id"],
            debit_amount=entry_data.get("debit_amount"),
            credit_amount=entry_data.get("credit_amount"),
            description=entry_data.get("description")
        )
        db.session.add(entry)
    
    # Check if transaction is balanced
    db.session.flush()
    if not transaction.is_balanced:
        db.session.rollback()
        raise ValueError("Transaction is not balanced")
    
    # Save changes
    try:
        db.session.commit()
        return transaction
    except SQLAlchemyError as e:
        db.session.rollback()
        raise SQLAlchemyError(f"Error creating transaction: {str(e)}")


def record_order_accounting(order_id):
    """
    Record accounting entries for an order when paid.
    
    Args:
        order_id (int): Order ID
        
    Returns:
        Transaction: Created transaction or None if not applicable
        
    Raises:
        ValueError: If order not found or already processed
    """
    order = Order.query.get(order_id)
    if not order:
        raise ValueError(f"Order with ID {order_id} not found")
    
    # Only process paid orders
    if order.status != OrderStatus.PAID:
        return None
    
    # Check if transaction already exists
    existing = Transaction.query.filter_by(
        reference_type="order",
        reference_id=order.order_number
    ).first()
    
    if existing:
        return existing  # Already processed
    
    # Get accounts
    sales_account = Account.query.filter_by(code="4000").first()
    vat_account = Account.query.filter_by(code="2200").first()
    ar_account = Account.query.filter_by(code="1200").first()
    cogs_account = Account.query.filter_by(code="5000").first()
    inventory_account = Account.query.filter_by(code="1300").first()
    
    # Ensure all required accounts exist
    if not all([sales_account, vat_account, ar_account, cogs_account, inventory_account]):
        raise ValueError("Required accounting accounts not found")
    
    # Calculate totals
    total_amount = order.total_amount
    tax_amount = order.tax_amount or Decimal("0.00")
    sales_amount = total_amount - tax_amount
    
    # Calculate COGS (simplified - in real world would be based on product costs)
    cogs_amount = sales_amount * Decimal("0.60")  # Assuming 60% COGS
    
    # Prepare entries data
    entries_data = [
        # Sales entry
        {
            "account_id": sales_account.id,
            "credit_amount": sales_amount,
            "description": f"Sales revenue for order {order.order_number}"
        },
        # VAT entry
        {
            "account_id": vat_account.id,
            "credit_amount": tax_amount,
            "description": f"VAT for order {order.order_number}"
        },
        # AR entry
        {
            "account_id": ar_account.id,
            "debit_amount": total_amount,
            "description": f"Accounts receivable for order {order.order_number}"
        },
        # COGS entry
        {
            "account_id": cogs_account.id,
            "debit_amount": cogs_amount,
            "description": f"Cost of goods sold for order {order.order_number}"
        },
        # Inventory entry
        {
            "account_id": inventory_account.id,
            "credit_amount": cogs_amount,
            "description": f"Inventory reduction for order {order.order_number}"
        }
    ]
    
    # Create transaction
    transaction = create_transaction(
        date=datetime.now().date(),
        reference_type="order",
        reference_id=order.order_number,
        description=f"Accounting entries for order {order.order_number}",
        entries_data=entries_data
    )
    
    return transaction


def setup_default_accounts():
    """
    Set up default accounting accounts if they don't exist.
    
    Returns:
        dict: Summary of created accounts
    """
    default_accounts = [
        {"code": "1000", "name": "Cash", "account_type": "asset"},
        {"code": "1200", "name": "Accounts Receivable", "account_type": "asset"},
        {"code": "1300", "name": "Inventory", "account_type": "asset"},
        {"code": "2000", "name": "Accounts Payable", "account_type": "liability"},
        {"code": "2200", "name": "VAT Payable", "account_type": "liability"},
        {"code": "3000", "name": "Equity", "account_type": "equity"},
        {"code": "4000", "name": "Sales Revenue", "account_type": "revenue"},
        {"code": "5000", "name": "Cost of Goods Sold", "account_type": "expense"},
        {"code": "6000", "name": "Operating Expenses", "account_type": "expense"}
    ]
    
    summary = {"created": 0, "existing": 0}
    
    for acc_data in default_accounts:
        existing = Account.query.filter_by(code=acc_data["code"]).first()
        if not existing:
            account = Account(**acc_data)
            db.session.add(account)
            summary["created"] += 1
        else:
            summary["existing"] += 1
    
    try:
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        raise
    
    return summary 