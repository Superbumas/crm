"""User model for the application."""
from datetime import datetime
from flask_login import UserMixin
from werkzeug.security import check_password_hash, generate_password_hash
import json

from lt_crm.app.extensions import db, login_manager
from lt_crm.app.models.base import TimestampMixin


class User(UserMixin, TimestampMixin, db.Model):
    """User model representing application users."""

    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), index=True, unique=True)
    email = db.Column(db.String(120), index=True, unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    name = db.Column(db.String(100), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    is_admin = db.Column(db.Boolean, default=False)
    last_login = db.Column(db.DateTime, nullable=True)
    preferences = db.Column(db.JSON, nullable=True)

    def __repr__(self):
        """Return string representation of the user."""
        return f"<User {self.username}>"

    def set_password(self, password):
        """Set user password."""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Check if provided password matches user password."""
        return check_password_hash(self.password_hash, password)

    def get_product_columns(self):
        """Get user's product column preferences or default if not set."""
        if not self.preferences:
            from lt_crm.app.models.product import PRODUCT_COLUMNS
            return [k for k, v in PRODUCT_COLUMNS.items() if v["default"]]
        
        # Handle preferences that might be stored as a string
        prefs = self.preferences
        if isinstance(prefs, str):
            try:
                prefs = json.loads(prefs)
            except:
                prefs = {}
        
        # Return columns from preferences or default
        if not isinstance(prefs, dict) or "product_columns" not in prefs:
            from lt_crm.app.models.product import PRODUCT_COLUMNS
            return [k for k, v in PRODUCT_COLUMNS.items() if v["default"]]
        
        return prefs.get("product_columns", [])

    def set_product_columns(self, columns):
        """Set user's product column preferences using direct SQL."""
        try:
            import logging
            logger = logging.getLogger(__name__)
            
            # Ensure columns is a list of strings
            if not isinstance(columns, list):
                columns = list(columns)
            
            # Log before validation
            logger.info(f"Setting columns (before validation): {columns}")
            
            # Get product columns
            from lt_crm.app.models.product import PRODUCT_COLUMNS
            
            # Validate columns
            valid_columns = [col for col in columns if col in PRODUCT_COLUMNS]
            
            # Ensure sku and name are included
            if 'sku' not in valid_columns:
                valid_columns.insert(0, 'sku')
            if 'name' not in valid_columns:
                if 'sku' in valid_columns:
                    valid_columns.insert(1, 'name')
                else:
                    valid_columns.insert(0, 'name')
            
            # Log after validation
            logger.info(f"Setting columns (after validation): {valid_columns}")
            
            # Create simple prefs dictionary
            prefs = {'product_columns': valid_columns}
            
            # Convert to JSON string for direct SQL update
            prefs_json = json.dumps(prefs)
            logger.info(f"Preferences JSON: {prefs_json}")
            
            # Execute direct SQL update to avoid any ORM issues
            # This bypasses SQLAlchemy's session and JSON handling
            from sqlalchemy import text
            result = db.session.execute(
                text("UPDATE users SET preferences = :prefs WHERE id = :user_id"),
                {'prefs': prefs_json, 'user_id': self.id}
            )
            db.session.commit()
            
            # Reload the user to get the updated preferences
            user = User.query.get(self.id)
            self.preferences = user.preferences
            
            # Log after update
            logger.info(f"After update, preferences: {self.preferences}")
            
            # Verify what was saved
            saved_cols = self.get_product_columns()
            logger.info(f"After update, saved columns: {saved_cols}")
            
            # Check if all columns were saved
            not_saved = [col for col in valid_columns if col not in saved_cols]
            if not_saved:
                logger.error(f"Columns not saved: {not_saved}")
                
            return True
            
        except Exception as e:
            db.session.rollback()
            import logging
            logger = logging.getLogger(__name__)
            logger.exception(f"Error in set_product_columns: {e}")
            return False


@login_manager.user_loader
def load_user(id):
    """Load user from database by ID for login management."""
    return User.query.get(int(id)) 