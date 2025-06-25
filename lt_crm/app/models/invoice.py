"""Invoice model for the CRM application."""
import enum
from app.extensions import db
from app.models.base import TimestampMixin
from sqlalchemy import func


class InvoiceStatus(enum.Enum):
    """Invoice status enum."""
    
    DRAFT = "draft"
    ISSUED = "issued"
    PAID = "paid"
    CANCELLED = "cancelled"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class Invoice(TimestampMixin, db.Model):
    """Invoice model representing customer invoices."""

    __tablename__ = "invoices"

    id = db.Column(db.Integer, primary_key=True)
    invoice_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    order_id = db.Column(db.Integer, db.ForeignKey("orders.id"), nullable=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=True)
    status = db.Column(db.Enum(InvoiceStatus), default=InvoiceStatus.DRAFT, nullable=False)
    issue_date = db.Column(db.Date, nullable=True)
    due_date = db.Column(db.Date, nullable=True)
    
    total_amount = db.Column(db.Numeric(12, 2), nullable=False)
    tax_amount = db.Column(db.Numeric(12, 2), nullable=True)
    subtotal_amount = db.Column(db.Numeric(12, 2), nullable=True)
    
    # Billing information
    billing_name = db.Column(db.String(100), nullable=True)
    billing_address = db.Column(db.String(200), nullable=True)
    billing_city = db.Column(db.String(100), nullable=True)
    billing_postal_code = db.Column(db.String(20), nullable=True)
    billing_country = db.Column(db.String(100), default="Lithuania")
    billing_email = db.Column(db.String(120), nullable=True)
    company_code = db.Column(db.String(50), nullable=True)
    vat_code = db.Column(db.String(50), nullable=True)
    
    notes = db.Column(db.Text, nullable=True)
    payment_details = db.Column(db.Text, nullable=True)
    pdf_url = db.Column(db.String(255), nullable=True)
    
    # Relationships
    items = db.relationship("InvoiceItem", backref="invoice", lazy="dynamic", cascade="all, delete-orphan")
    
    def __repr__(self):
        """Return string representation of the invoice."""
        return f"<Invoice {self.invoice_number} - {self.status.value}>"

    @property
    def item_count(self):
        """Return number of items in the invoice."""
        try:
            # Use scalar() instead of count() to avoid transaction issues
            return db.session.query(func.count(InvoiceItem.id)).filter(InvoiceItem.invoice_id == self.id).scalar() or 0
        except Exception:
            # Return 0 if there's an error
            return 0


class InvoiceItem(TimestampMixin, db.Model):
    """InvoiceItem model representing items in an invoice."""

    __tablename__ = "invoice_items"

    id = db.Column(db.Integer, primary_key=True)
    invoice_id = db.Column(db.Integer, db.ForeignKey("invoices.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=True)
    description = db.Column(db.String(255), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    price = db.Column(db.Numeric(12, 2), nullable=False)
    tax_rate = db.Column(db.Numeric(5, 2), nullable=True)
    subtotal = db.Column(db.Numeric(12, 2), nullable=False)
    
    # Relationship with Product
    product = db.relationship("Product", backref="invoice_items", lazy=True)
    
    def __repr__(self):
        """Return string representation of the invoice item."""
        return f"<InvoiceItem {self.id} - Invoice {self.invoice_id}>" 