"""Integration models for the CRM application."""
import enum
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin


class IntegrationType(enum.Enum):
    """Integration type enum."""
    
    ECOMMERCE = "ecommerce"
    ACCOUNTING = "accounting"
    SHIPPING = "shipping"
    INVENTORY = "inventory"
    OTHER = "other"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class SyncStatus(enum.Enum):
    """Sync status enum."""
    
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"
    PARTIAL = "partial"
    
    def __str__(self):
        """Return string representation of the enum value."""
        return self.value


class IntegrationSyncLog(TimestampMixin, db.Model):
    """IntegrationSyncLog model for tracking integration syncs."""

    __tablename__ = "integration_sync_logs"

    id = db.Column(db.Integer, primary_key=True)
    integration_type = db.Column(db.Enum(IntegrationType), nullable=False)
    provider_name = db.Column(db.String(50), nullable=False)
    status = db.Column(db.Enum(SyncStatus), default=SyncStatus.PENDING, nullable=False)
    
    records_processed = db.Column(db.Integer, default=0)
    records_created = db.Column(db.Integer, default=0)
    records_updated = db.Column(db.Integer, default=0)
    records_failed = db.Column(db.Integer, default=0)
    
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    
    entity_type = db.Column(db.String(50), nullable=True)  # e.g., "product", "order"
    error_message = db.Column(db.Text, nullable=True)
    log_data = db.Column(db.JSON, nullable=True)
    
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    
    def __repr__(self):
        """Return string representation of the sync log."""
        return f"<IntegrationSyncLog {self.id} - {self.integration_type.value}:{self.provider_name} {self.status.value}>" 