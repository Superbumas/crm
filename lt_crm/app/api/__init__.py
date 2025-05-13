"""API blueprint for the application."""
from flask import Blueprint
from flask_restx import Api

bp = Blueprint("api", __name__)
api = Api(
    bp,
    version="1.0",
    title="LT CRM API",
    description="Lithuanian CRM REST API",
    doc="/docs",
)

from app.api import routes  # noqa 