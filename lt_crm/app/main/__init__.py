"""Main blueprint for the application."""
from flask import Blueprint

bp = Blueprint("main", __name__)

from . import routes  # noqa 