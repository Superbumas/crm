"""Marshmallow schemas for API v1."""
from marshmallow import Schema, fields, validate, pre_load, post_dump
from decimal import Decimal

# Custom field for Decimal serialization
class DecimalField(fields.Field):
    """Field that serializes Decimal to string and deserializes string to Decimal."""
    
    def _serialize(self, value, attr, obj, **kwargs):
        if value is None:
            return None
        return str(value)
    
    def _deserialize(self, value, attr, data, **kwargs):
        try:
            return Decimal(value)
        except (ValueError, TypeError, decimal.InvalidOperation):
            raise ValidationError("Not a valid decimal value")

# User schemas
class UserSchema(Schema):
    """Schema for User model."""
    
    id = fields.Int(dump_only=True)
    username = fields.Str(required=True, validate=validate.Length(min=3, max=64))
    email = fields.Email(required=True)

class UserLoginSchema(Schema):
    """Schema for user login."""
    
    username = fields.Str(required=True)
    password = fields.Str(required=True, load_only=True)

class TokenSchema(Schema):
    """Schema for authentication tokens."""
    
    access_token = fields.Str(dump_only=True)
    refresh_token = fields.Str(dump_only=True)
    token_type = fields.Str(dump_only=True, default="bearer")

# Product schemas
class ProductSchema(Schema):
    """Schema for Product model."""
    
    id = fields.Int(dump_only=True)
    sku = fields.Str(required=True, validate=validate.Length(min=1, max=50))
    name = fields.Str(required=True, validate=validate.Length(min=1, max=200))
    description_html = fields.Str(allow_none=True)
    barcode = fields.Str(allow_none=True)
    quantity = fields.Int(dump_default=0)
    delivery_days = fields.Int(allow_none=True)
    price_final = DecimalField(required=True)
    price_old = DecimalField(allow_none=True)
    category = fields.Str(allow_none=True)
    main_image_url = fields.Str(allow_none=True)
    extra_image_urls = fields.List(fields.Str(), allow_none=True)
    model = fields.Str(allow_none=True)
    manufacturer = fields.Str(allow_none=True)
    warranty_months = fields.Int(allow_none=True)
    weight_kg = DecimalField(allow_none=True)
    parameters = fields.Dict(allow_none=True)
    variants = fields.Dict(allow_none=True)
    delivery_options = fields.Dict(allow_none=True)
    is_in_stock = fields.Bool(dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)

class ProductListSchema(Schema):
    """Schema for list of products."""
    
    items = fields.List(fields.Nested(ProductSchema))
    total = fields.Int()
    page = fields.Int()
    per_page = fields.Int()
    pages = fields.Int()

# Order schemas
class OrderItemSchema(Schema):
    """Schema for OrderItem model."""
    
    id = fields.Int(dump_only=True)
    product_id = fields.Int(required=True)
    product = fields.Nested(lambda: ProductSchema(only=("id", "sku", "name")), dump_only=True)
    quantity = fields.Int(required=True, validate=validate.Range(min=1))
    price = DecimalField(required=True)
    tax_rate = DecimalField(allow_none=True)
    discount_amount = DecimalField(allow_none=True)
    variant_info = fields.Dict(allow_none=True)
    subtotal = fields.Method("get_subtotal", dump_only=True)
    
    def get_subtotal(self, obj):
        """Calculate subtotal for the item."""
        return str(obj.subtotal) if hasattr(obj, "subtotal") else str(obj.price * obj.quantity)

class OrderSchema(Schema):
    """Schema for Order model."""
    
    id = fields.Int(dump_only=True)
    order_number = fields.Str(dump_only=True)
    customer_id = fields.Int(allow_none=True)
    status = fields.Str()
    total_amount = DecimalField(required=True)
    tax_amount = DecimalField(allow_none=True)
    shipping_amount = DecimalField(allow_none=True)
    discount_amount = DecimalField(allow_none=True)
    
    # Shipping information
    shipping_name = fields.Str(allow_none=True)
    shipping_address = fields.Str(allow_none=True)
    shipping_city = fields.Str(allow_none=True)
    shipping_postal_code = fields.Str(allow_none=True)
    shipping_country = fields.Str(dump_default="Lithuania")
    shipping_phone = fields.Str(allow_none=True)
    shipping_email = fields.Email(allow_none=True)
    
    payment_method = fields.Str(allow_none=True)
    payment_reference = fields.Str(allow_none=True)
    shipping_method = fields.Str(allow_none=True)
    tracking_number = fields.Str(allow_none=True)
    notes = fields.Str(allow_none=True)
    
    items = fields.List(fields.Nested(OrderItemSchema))
    item_count = fields.Int(dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True)

class OrderListSchema(Schema):
    """Schema for list of orders."""
    
    items = fields.List(fields.Nested(OrderSchema))
    total = fields.Int()
    page = fields.Int()
    per_page = fields.Int()
    pages = fields.Int()

class OrderStatusUpdateSchema(Schema):
    """Schema for updating order status."""
    
    status = fields.Str(required=True, validate=validate.OneOf(
        ["new", "paid", "packed", "shipped", "returned", "cancelled"]
    ))
    
# Invoice schemas
class InvoiceSchema(Schema):
    """Schema for Invoice model."""
    
    id = fields.Int(dump_only=True)
    invoice_number = fields.Str(dump_only=True)
    order_id = fields.Int(allow_none=True)
    customer_id = fields.Int(allow_none=True)
    status = fields.Str(dump_only=True)
    issue_date = fields.Date(allow_none=True)
    due_date = fields.Date(allow_none=True)
    
    total_amount = DecimalField(required=True)
    tax_amount = DecimalField(allow_none=True)
    subtotal_amount = DecimalField(allow_none=True)
    
    # Billing information
    billing_name = fields.Str(allow_none=True)
    billing_address = fields.Str(allow_none=True)
    billing_city = fields.Str(allow_none=True)
    billing_postal_code = fields.Str(allow_none=True)
    billing_country = fields.Str(dump_default="Lithuania")
    billing_email = fields.Email(allow_none=True)
    company_code = fields.Str(allow_none=True)
    vat_code = fields.Str(allow_none=True)
    
    notes = fields.Str(allow_none=True)
    payment_details = fields.Str(allow_none=True)
    pdf_url = fields.Str(dump_only=True)
    created_at = fields.DateTime(dump_only=True)
    updated_at = fields.DateTime(dump_only=True) 