"""
Script to create the invoice_items table in the database
"""
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.invoice import InvoiceItem

app = create_app()

with app.app_context():
    print("=== CREATING INVOICE_ITEMS TABLE ===")
    
    # Create the invoice_items table
    InvoiceItem.__table__.create(db.engine, checkfirst=True)
    
    print("Invoice items table created successfully.") 