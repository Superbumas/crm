"""
Script to reset invoices in the database
"""
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.invoice import Invoice

app = create_app()

with app.app_context():
    print("=== RESETTING INVOICES ===")
    
    # First check what invoices exist
    print("Current invoices:")
    invoices = Invoice.query.all()
    for invoice in invoices:
        print(f"ID: {invoice.id}, Number: {invoice.invoice_number}, Order ID: {invoice.order_id}")
    
    # Delete all invoices
    count = Invoice.query.delete()
    db.session.commit()
    
    print(f"\nDeleted {count} invoices")
    print("Database reset complete. You can now create new invoices.") 