"""API v1 blueprint for the application."""
import os
from functools import wraps
from flask import Blueprint, request, current_app, jsonify
from flask_restx import Api
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import json
from decimal import Decimal
from app.extensions import cache


# Custom function to handle Decimal serialization in flask-restx
def output_json(data, code, headers=None):
    """Make a Flask response with a JSON encoded body.
    
    This custom encoder properly handles Decimal values by converting them to floats.
    """
    from flask import make_response
    
    class DecimalEncoder(json.JSONEncoder):
        def default(self, o):
            if isinstance(o, Decimal):
                return float(o)
            return super(DecimalEncoder, self).default(o)
    
    resp_data = json.dumps(data, cls=DecimalEncoder) + "\n"
    response = make_response(resp_data, code)
    response.headers["Content-Type"] = "application/json"
    
    if headers:
        for key, value in headers.items():
            response.headers[key] = value
    
    return response


bp = Blueprint("api_v1", __name__, url_prefix="/v1")

# Initialize API limiter
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"],
    storage_uri=os.environ.get("REDIS_URL", "memory://"),
)

# Setup Flask-RESTX API
authorizations = {
    "apikey": {
        "type": "apiKey",
        "in": "header",
        "name": "Authorization"
    }
}

api = Api(
    bp,
    version="1.0",
    title="LT CRM API",
    description="Lithuanian CRM REST API v1",
    doc="/docs",
    authorizations=authorizations,
    security="apikey"
)

# Set the custom output_json function
api.representation('application/json')(output_json)

# Register API namespaces
from .auth import ns as auth_ns
from .products import ns as products_ns
from .orders import ns as orders_ns
from .invoices import ns as invoices_ns
from .exports import ns as exports_ns
from .wordpress import ns as wordpress_ns

api.add_namespace(auth_ns, path="/auth")
api.add_namespace(products_ns, path="/products")
api.add_namespace(orders_ns, path="/orders")
api.add_namespace(invoices_ns, path="/invoices")
api.add_namespace(exports_ns, path="/exports")
api.add_namespace(wordpress_ns, path="/wordpress")

@bp.errorhandler(404)
def handle_404(error):
    """Handle 404 errors."""
    return jsonify({"message": "Resource not found"}), 404

@bp.errorhandler(500)
def handle_500(error):
    """Handle 500 errors."""
    return jsonify({"message": "Internal server error"}), 500 