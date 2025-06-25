"""Customer model for the CRM application."""
from datetime import datetime

from app.extensions import db
from app.models.base import TimestampMixin


class Customer(TimestampMixin, db.Model):
    """Customer model representing CRM customers."""

    __tablename__ = "customers"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), index=True, unique=True, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    company = db.Column(db.String(100), nullable=True)
    address = db.Column(db.String(200), nullable=True)
    city = db.Column(db.String(100), nullable=True)
    country = db.Column(db.String(100), default="Lithuania")
    status = db.Column(db.String(20), default="active")
    source = db.Column(db.String(50), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    assigned_to = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)

    # Relationships
    contacts = db.relationship("Contact", backref="customer", lazy="dynamic", cascade="all, delete-orphan")
    tasks = db.relationship("Task", backref="customer", lazy="dynamic", cascade="all, delete-orphan")
    orders = db.relationship("Order", backref="customer", lazy="dynamic")
    invoices = db.relationship("Invoice", backref="customer", lazy="dynamic")

    def __repr__(self):
        """Return string representation of the customer."""
        return f"<Customer {self.name}>"


class Contact(TimestampMixin, db.Model):
    """Contact model representing customer contacts."""

    __tablename__ = "contacts"

    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    position = db.Column(db.String(100), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    is_primary = db.Column(db.Boolean, default=False)
    notes = db.Column(db.Text, nullable=True)

    def __repr__(self):
        """Return string representation of the contact."""
        return f"<Contact {self.name} - {self.customer.name}>"


class Task(TimestampMixin, db.Model):
    """Task model representing CRM tasks."""

    __tablename__ = "tasks"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    customer_id = db.Column(db.Integer, db.ForeignKey("customers.id"), nullable=False)
    status = db.Column(db.String(20), default="pending")
    priority = db.Column(db.String(20), default="medium")
    due_date = db.Column(db.DateTime, nullable=True)
    assigned_to = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    completed_at = db.Column(db.DateTime, nullable=True)

    def __repr__(self):
        """Return string representation of the task."""
        return f"<Task {self.title} - {self.customer.name}>" 