"""Order models for the CRM application."""
import enum
from app.extensions import db
from app.models.base import TimestampMixin


class OrderStatus(enum.Enum):
    """Order status enum."""
    
    NEW = "new"
    PAID = "paid"
    PACKED = "packed"
    SHIPPED = "shipped"
    RETURNED = "returned"
    CANCELLED = "cancelled"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class Order(TimestampMixin, db.Model):
    """Order model representing customer orders."""

    __tablename__ = "orders"

    id = db.Column(db.Integer, primary_key=True)
    order_number = db.Column(db.String(20), unique=True, nullable=False, index=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=True)
    status = db.Column(db.Enum(OrderStatus), default=OrderStatus.NEW, nullable=False)
    total_amount = db.Column(db.Numeric(12, 2), nullable=False)
    tax_amount = db.Column(db.Numeric(12, 2), nullable=True)
    shipping_amount = db.Column(db.Numeric(12, 2), nullable=True)
    discount_amount = db.Column(db.Numeric(12, 2), nullable=True)
    
    # Shipping and billing information
    shipping_name = db.Column(db.String(100), nullable=True)
    shipping_address = db.Column(db.String(200), nullable=True)
    shipping_city = db.Column(db.String(100), nullable=True)
    shipping_postal_code = db.Column(db.String(20), nullable=True)
    shipping_country = db.Column(db.String(100), default="Lithuania")
    shipping_phone = db.Column(db.String(20), nullable=True)
    shipping_email = db.Column(db.String(120), nullable=True)
    
    payment_method = db.Column(db.String(50), nullable=True)
    payment_reference = db.Column(db.String(100), nullable=True)
    shipping_method = db.Column(db.String(50), nullable=True)
    tracking_number = db.Column(db.String(100), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    
    # Relationships
    items = db.relationship("OrderItem", backref="order", lazy="dynamic", cascade="all, delete-orphan")
    
    def __repr__(self):
        """Return string representation of the order."""
        return f"<Order {self.order_number} - {self.status.value}>"
    
    @property
    def item_count(self):
        """Return number of items in the order."""
        return self.items.count()


class OrderItem(TimestampMixin, db.Model):
    """OrderItem model representing items in an order."""

    __tablename__ = "order_items"

    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, db.ForeignKey("orders.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    quantity = db.Column(db.Integer, nullable=False, default=1)
    price = db.Column(db.Numeric(12, 2), nullable=False)
    tax_rate = db.Column(db.Numeric(5, 2), nullable=True)
    discount_amount = db.Column(db.Numeric(12, 2), nullable=True)
    variant_info = db.Column(db.JSON, nullable=True)
    
    def __repr__(self):
        """Return string representation of the order item."""
        return f"<OrderItem {self.id} - Order {self.order_id}, Product {self.product_id}>"
    
    @property
    def subtotal(self):
        """Calculate subtotal for the item."""
        return self.price * self.quantity 