"""Authentication blueprint for the application."""
from flask import Blueprint

bp = Blueprint("auth", __name__)

from .routes import *  # noqa 