"""Stock movement model for the CRM application."""
import enum
from datetime import datetime
from app.extensions import db
from app.models.base import TimestampMixin


class MovementReasonCode(enum.Enum):
    """Movement reason code enum."""
    
    IMPORT = "IMPORT"
    SALE = "SALE"
    RETURN = "RETURN"
    MANUAL_ADJ = "MANUAL_ADJ"
    SHIPMENT = "SHIPMENT"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class ShipmentStatus(enum.Enum):
    """Shipment status enum."""
    
    PENDING = "pending"
    RECEIVED = "received"
    CANCELLED = "cancelled"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class Shipment(TimestampMixin, db.Model):
    """Shipment model representing incoming product shipments."""
    
    __tablename__ = "shipments"
    
    id = db.Column(db.Integer, primary_key=True)
    shipment_number = db.Column(db.String(50), unique=True, nullable=False)
    supplier = db.Column(db.String(100), nullable=True)
    expected_date = db.Column(db.Date, nullable=True)
    arrival_date = db.Column(db.Date, nullable=True)
    status = db.Column(db.Enum(ShipmentStatus), nullable=False, default=ShipmentStatus.PENDING)
    notes = db.Column(db.Text, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    
    # Relationships
    shipment_items = db.relationship("ShipmentItem", backref="shipment", lazy="dynamic", cascade="all, delete-orphan")
    
    def __repr__(self):
        """Return string representation of the shipment."""
        return f"<Shipment {self.shipment_number}>"
    
    def item_count(self):
        """Safely get the count of shipment items."""
        try:
            # Use scalar() instead of count() to avoid transaction issues
            from sqlalchemy import func
            return db.session.query(func.count(ShipmentItem.id)).filter(ShipmentItem.shipment_id == self.id).scalar() or 0
        except Exception:
            # Return 0 if there's an error
            return 0
    
    def receive_shipment(self):
        """Process the shipment arrival and update stock quantities."""
        from sqlalchemy import text
        from lt_crm.app.models.product import Product
        
        if self.status == ShipmentStatus.RECEIVED:
            return False  # Already received
            
        for item in self.shipment_items:
            product = Product.query.get(item.product_id)
            if product:
                # Update product quantity directly
                product.quantity += item.quantity
                db.session.add(product)
                
                # Create a stock movement record directly using the model
                movement = StockMovement(
                    product_id=item.product_id,
                    qty_delta=item.quantity,
                    reason_code=MovementReasonCode.SHIPMENT,
                    note=f"Siuntos gavimas: {self.shipment_number}",
                    reference_id=str(self.id),
                    user_id=self.user_id
                )
                db.session.add(movement)
            
        # Update shipment status and arrival date
        self.status = ShipmentStatus.RECEIVED
        self.arrival_date = datetime.now().date()
        db.session.add(self)
        
        return True


class ShipmentItem(db.Model):
    """ShipmentItem model representing items in a shipment."""
    
    __tablename__ = "shipment_items"
    
    id = db.Column(db.Integer, primary_key=True)
    shipment_id = db.Column(db.Integer, db.ForeignKey("shipments.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    cost_price = db.Column(db.Numeric(12, 2), nullable=True)
    notes = db.Column(db.String(255), nullable=True)
    
    # Relationships
    product = db.relationship("Product", backref="shipment_items")
    
    def __repr__(self):
        """Return string representation of the shipment item."""
        return f"<ShipmentItem {self.id} - Shipment {self.shipment_id}, Product {self.product_id}: {self.quantity}>"


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