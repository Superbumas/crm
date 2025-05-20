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
    
    shipment_number = StringField('Shipment Number', validators=[Optional(), Length(max=50)])
    supplier = StringField('Supplier', validators=[Optional(), Length(max=100)])
    expected_date = DateField('Expected Date', validators=[Optional()], default=date.today)
    notes = TextAreaField('Notes', validators=[Optional()])
    status = SelectField('Status', choices=[
        (ShipmentStatus.PENDING.value, 'Pending'),
        (ShipmentStatus.RECEIVED.value, 'Received'),
        (ShipmentStatus.CANCELLED.value, 'Cancelled')
    ], validators=[DataRequired()])


class CompanySettingsForm(FlaskForm):
    """Form for company settings."""
    
    name = StringField("Įmonės pavadinimas", validators=[DataRequired(), Length(max=100)])
    address = StringField("Adresas", validators=[Optional(), Length(max=200)])
    city = StringField("Miestas", validators=[Optional(), Length(max=100)])
    postal_code = StringField("Pašto kodas", validators=[Optional(), Length(max=20)])
    country = StringField("Šalis", validators=[Optional(), Length(max=100)])
    phone = StringField("Telefonas", validators=[Optional(), Length(max=20)])
    email = StringField("El. paštas", validators=[Optional(), Email(), Length(max=120)])
    company_code = StringField("Įmonės kodas", validators=[Optional(), Length(max=50)])
    vat_code = StringField("PVM mokėtojo kodas", validators=[Optional(), Length(max=50)])
    bank_name = StringField("Banko pavadinimas", validators=[Optional(), Length(max=100)])
    bank_account = StringField("Banko sąskaita", validators=[Optional(), Length(max=50)])
    bank_swift = StringField("SWIFT kodas", validators=[Optional(), Length(max=20)])
