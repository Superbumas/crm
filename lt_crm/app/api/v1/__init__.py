"""API v1 blueprint for the application."""
from flask import Blueprint
from flask_restx import Api
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

bp = Blueprint("api_v1", __name__, url_prefix="/v1")
api = Api(
    bp,
    version="1.0",
    title="LT CRM API",
    description="Lithuanian CRM REST API - Version 1",
    doc="/docs",
)

# Rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200 per minute"],
    storage_uri="memory://",
)

# Import namespaces
from .auth import ns as auth_ns
from .products import ns as products_ns
from .orders import ns as orders_ns
from .invoices import ns as invoices_ns

# Add namespaces
api.add_namespace(auth_ns, path="/auth")
api.add_namespace(products_ns, path="/products")
api.add_namespace(orders_ns, path="/orders")
api.add_namespace(invoices_ns, path="/invoices") 