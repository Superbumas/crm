"""Stock movement model for the CRM application."""
import enum
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin


class MovementReasonCode(enum.Enum):
    """Movement reason code enum."""
    
    IMPORT = "import"
    SALE = "sale"
    RETURN = "return"
    MANUAL_ADJ = "manual_adj"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class StockMovement(TimestampMixin, db.Model):
    """StockMovement model representing product inventory changes."""

    __tablename__ = "stock_movements"

    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    qty_delta = db.Column(db.Integer, nullable=False)
    reason_code = db.Column(db.Enum(MovementReasonCode), nullable=False)
    note = db.Column(db.String(255), nullable=True)
    channel = db.Column(db.String(50), nullable=True)
    reference_id = db.Column(db.String(50), nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    
    def __repr__(self):
        """Return string representation of the stock movement."""
        return f"<StockMovement {self.id} - Product {self.product_id}: {self.qty_delta}>"
    
    def apply_movement(self):
        """Apply the movement to the product's stock quantity."""
        from lt_crm.app.models.product import Product
        
        product = Product.query.get(self.product_id)
        if product:
            product.quantity += self.qty_delta
            db.session.add(product)
            return True
        return False 