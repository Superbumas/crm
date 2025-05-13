"""Base models and mixins."""
from datetime import datetime
from app.extensions import db


class TimestampMixin:
    """Mixin for adding timestamp fields to models."""
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow) 