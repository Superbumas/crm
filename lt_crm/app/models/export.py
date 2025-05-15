"""Export configuration models for the CRM application."""
import json
import enum
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin
from lt_crm.app.models.user import User


class ExportFormat(enum.Enum):
    """Supported export formats."""
    
    CSV = "csv"
    XLSX = "xlsx"
    XML = "xml"


class ExportConfig(TimestampMixin, db.Model):
    """Export configuration model for reusable exports."""

    __tablename__ = "export_configs"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    format = db.Column(db.Enum(ExportFormat), nullable=False)
    column_map = db.Column(db.JSON, nullable=False)
    created_by_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    
    # Relationships
    created_by = db.relationship("User", foreign_keys=[created_by_id])
    
    def __repr__(self):
        """Return string representation of the export config."""
        return f"<ExportConfig {self.name}: {self.format}>"
    
    def get_column_map(self):
        """Return column map as dict."""
        if isinstance(self.column_map, str):
            return json.loads(self.column_map)
        return self.column_map or {} 