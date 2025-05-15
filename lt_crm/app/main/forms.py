"""Forms for the Main blueprint."""

from flask_wtf import FlaskForm
from wtforms import StringField, TextAreaField, BooleanField, SelectField, DateField, IntegerField, DecimalField, FieldList, FormField, HiddenField
from wtforms.validators import DataRequired, Email, Length, Optional, NumberRange
from datetime import date

# Shipment-related models
from lt_crm.app.models.stock import ShipmentStatus


class ShipmentItemForm(FlaskForm):
    """Form for a shipment item."""
    
    product_id = HiddenField('Product ID', validators=[DataRequired()])
    product_name = StringField('Product Name', render_kw={'readonly': True})
    product_sku = StringField('SKU', render_kw={'readonly': True})
    quantity = IntegerField('Quantity', validators=[DataRequired(), NumberRange(min=1)], default=1)
    cost_price = DecimalField('Cost Price', validators=[Optional()], places=2)
    notes = StringField('Notes', validators=[Optional(), Length(max=255)])


class ShipmentForm(FlaskForm):
    """Form for creating or editing a shipment."""
    
    shipment_number = StringField('Shipment Number', validators=[DataRequired(), Length(max=50)])
    supplier = StringField('Supplier', validators=[Optional(), Length(max=100)])
    expected_date = DateField('Expected Date', validators=[Optional()], default=date.today)
    notes = TextAreaField('Notes', validators=[Optional()])
    status = SelectField('Status', choices=[
        (ShipmentStatus.PENDING.value, 'Pending'),
        (ShipmentStatus.RECEIVED.value, 'Received'),
        (ShipmentStatus.CANCELLED.value, 'Cancelled')
    ], validators=[DataRequired()])
