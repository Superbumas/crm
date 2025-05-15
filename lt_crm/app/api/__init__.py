"""API blueprint for the application."""
from flask import Blueprint
from flask_restx import Api
import json
from decimal import Decimal


# Custom function to handle Decimal serialization in flask-restx
def output_json(data, code, headers=None):
    """Make a Flask response with a JSON encoded body.
    
    This custom encoder properly handles Decimal values by converting them to floats.
    """
    class DecimalEncoder(json.JSONEncoder):
        def default(self, o):
            if isinstance(o, Decimal):
                return float(o)
            return super(DecimalEncoder, self).default(o)
    
    resp = json.dumps(data, cls=DecimalEncoder) + "\n"
    resp_headers = headers or {}
    resp_headers["Content-Type"] = "application/json"
    return resp, code, resp_headers


bp = Blueprint("api", __name__)
api = Api(
    bp,
    version="1.0",
    title="LT CRM API",
    description="Lithuanian CRM REST API",
    doc="/docs"
)

# Set the custom output_json function
api.representation('application/json')(output_json)

from . import routes  # noqa 