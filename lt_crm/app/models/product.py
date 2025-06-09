"""Product model for the CRM application."""
import json
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin
import slugify


# Define available columns that can be displayed in product listings
PRODUCT_COLUMNS = {
    "sku": {"name": "SKU", "description": "Produkto kodas", "default": True},
    "name": {"name": "Pavadinimas", "description": "Produkto pavadinimas", "default": True},
    "category": {"name": "Kategorija", "description": "Produkto kategorija", "default": True},
    "barcode": {"name": "Barkodas", "description": "Produkto brūkšninis kodas", "default": False},
    "price_final": {"name": "Kaina", "description": "Galutinė kaina", "default": True},
    "price_old": {"name": "Sena kaina", "description": "Ankstesnė kaina", "default": False},
    "quantity": {"name": "Likutis", "description": "Kiekis sandėlyje", "default": True},
    "model": {"name": "Modelis", "description": "Produkto modelis", "default": False},
    "manufacturer": {"name": "Gamintojas", "description": "Produkto gamintojas", "default": False},
    "delivery_days": {"name": "Pristatymo laikas", "description": "Pristatymo laikas dienomis", "default": False},
    "warranty_months": {"name": "Garantija", "description": "Garantijos laikotarpis", "default": False},
    "weight_kg": {"name": "Svoris", "description": "Produkto svoris (kg)", "default": False}
}


class ProductCategory(TimestampMixin, db.Model):
    """Product category model for organizing products."""
    
    __tablename__ = "product_categories"
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    slug = db.Column(db.String(100), nullable=False, unique=True, index=True)
    description = db.Column(db.Text, nullable=True)
    parent_id = db.Column(db.Integer, db.ForeignKey('product_categories.id'), nullable=True)
    external_id = db.Column(db.String(50), nullable=True, comment="ID in external system (e.g. WooCommerce)")
    image_url = db.Column(db.String(255), nullable=True)
    
    # Relationships
    products = db.relationship('Product', backref='product_category', lazy='dynamic')
    children = db.relationship(
        'ProductCategory',
        backref=db.backref('parent', remote_side=[id]),
        lazy='dynamic'
    )
    
    def __repr__(self):
        """Return string representation of the category."""
        return f"<ProductCategory {self.id}: {self.name}>"
    
    @property
    def full_name(self):
        """Return full category name including parent categories."""
        if self.parent:
            return f"{self.parent.full_name} > {self.name}"
        return self.name
    
    @property
    def product_count(self):
        """Return the number of products in this category."""
        return self.products.count()
    
    @staticmethod
    def generate_slug(name):
        """Generate a slug from the category name."""
        return slugify.slugify(name)
    
    def to_dict(self):
        """Convert category to dictionary."""
        return {
            'id': self.id,
            'name': self.name,
            'slug': self.slug,
            'description': self.description,
            'parent_id': self.parent_id,
            'external_id': self.external_id,
            'image_url': self.image_url,
            'product_count': self.product_count
        }


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
    category_id = db.Column(db.Integer, db.ForeignKey('product_categories.id'), nullable=True)
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
    
    @property
    def category_name(self):
        """Return category name."""
        if self.product_category:
            return self.product_category.name
        return self.category 