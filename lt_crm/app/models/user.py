"""User model for the application."""
from datetime import datetime
from flask_login import UserMixin
from werkzeug.security import check_password_hash, generate_password_hash

from app.extensions import db, login_manager
from app.models.base import TimestampMixin


class User(UserMixin, TimestampMixin, db.Model):
    """User model representing application users."""

    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True)
    password_hash = db.Column(db.String(128))
    is_active = db.Column(db.Boolean, default=True)
    is_admin = db.Column(db.Boolean, default=False)
    last_login = db.Column(db.DateTime, nullable=True)

    def __repr__(self):
        """Return string representation of the user."""
        return f"<User {self.username}>"

    def set_password(self, password):
        """Set user password."""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Check if provided password matches user password."""
        return check_password_hash(self.password_hash, password)


@login_manager.user_loader
def load_user(id):
    """Load user from database by ID for login management."""
    return User.query.get(int(id)) 