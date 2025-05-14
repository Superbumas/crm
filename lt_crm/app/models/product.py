"""Product model for the CRM application."""
import json
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin


class Product(TimestampMixin, db.Model):
    """Product model representing products in the CRM."""

    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True)
    sku = db.Column(db.String(50), unique=True, nullable=False, index=True)
    name = db.Column(db.String(200), nullable=False)
    description_html = db.Column(db.Text, nullable=True)
    barcode = db.Column(db.String(50), nullable=True)
    quantity = db.Column(db.Integer, default=0)
    delivery_days = db.Column(db.SmallInteger, nullable=True)
    price_final = db.Column(db.Numeric(12, 2), nullable=False)
    price_old = db.Column(db.Numeric(12, 2), nullable=True)
    category = db.Column(db.String(100), nullable=True)
    main_image_url = db.Column(db.String(255), nullable=True)
    extra_image_urls = db.Column(db.JSON, nullable=True)
    model = db.Column(db.String(100), nullable=True)
    manufacturer = db.Column(db.String(100), nullable=True)
    warranty_months = db.Column(db.SmallInteger, nullable=True)
    weight_kg = db.Column(db.Numeric(8, 3), nullable=True)
    parameters = db.Column(db.JSON, nullable=True)
    variants = db.Column(db.JSON, nullable=True)
    delivery_options = db.Column(db.JSON, nullable=True)
    
    # Relationships
    order_items = db.relationship("OrderItem", backref="product", lazy="dynamic")
    stock_movements = db.relationship("StockMovement", backref="product", lazy="dynamic")
    
    def __repr__(self):
        """Return string representation of the product."""
        return f"<Product {self.sku}: {self.name}>"
    
    @property
    def is_in_stock(self):
        """Check if product is in stock."""
        return self.quantity > 0
    
    def get_parameters(self):
        """Return parameters as dict."""
        if isinstance(self.parameters, str):
            return json.loads(self.parameters)
        return self.parameters or {} 