"""
Diagnostic script to check order and invoice relationships
"""
from lt_crm.app import create_app
from lt_crm.app.models.order import Order
from lt_crm.app.models.invoice import Invoice
from lt_crm.app.extensions import db

app = create_app()

with app.app_context():
    print("=== ORDERS ===")
    orders = Order.query.all()
    for order in orders:
        print(f"ID: {order.id}, Number: {order.order_number}")
    
    print("\n=== INVOICES (ORM) ===")
    invoices = Invoice.query.all()
    for invoice in invoices:
        print(f"ID: {invoice.id}, Number: {invoice.invoice_number}, Order ID: {invoice.order_id}")
    
    print("\n=== INVOICES (SQL) ===")
    sql_invoices = db.session.execute(db.text("SELECT id, invoice_number, order_id FROM invoices")).fetchall()
    for invoice in sql_invoices:
        print(f"ID: {invoice.id}, Number: {invoice.invoice_number}, Order ID: {invoice.order_id}")
    
    print("\n=== INVOICE NUMBER PATTERNS ===")
    invoice_numbers = [inv.invoice_number for inv in sql_invoices]
    for number in invoice_numbers:
        parts = number.split('-')
        if len(parts) >= 3:
            try:
                numeric_part = int(parts[-1])
                print(f"Invoice {number}: numeric part is {numeric_part}")
            except ValueError:
                print(f"Invoice {number}: could not parse numeric part")
        else:
            print(f"Invoice {number}: unexpected format (does not have expected parts)")
            
    # Fix the issue
    print("\n=== FIXING DATABASE ISSUES ===")
    try:
        # Check if there are any existing invoice relationships for order 2
        existing_invoice_for_order2 = db.session.execute(
            db.text("SELECT * FROM invoices WHERE order_id = 2")
        ).fetchone()
        
        if existing_invoice_for_order2:
            print(f"Order 2 already has an invoice (Invoice ID: {existing_invoice_for_order2.id})")
        else:
            # Check if invoice references a non-existent order
            orphaned_invoices = db.session.execute(
                db.text("""
                    SELECT i.* 
                    FROM invoices i 
                    LEFT JOIN orders o ON i.order_id = o.id
                    WHERE i.order_id IS NOT NULL AND o.id IS NULL
                """)
            ).fetchall()
            
            if orphaned_invoices:
                print(f"Found {len(orphaned_invoices)} orphaned invoices (referencing non-existent orders)")
                for inv in orphaned_invoices:
                    print(f"  Invoice ID: {inv.id}, Number: {inv.invoice_number}, references missing Order ID: {inv.order_id}")
            
            print("Ready to fix issues if needed. Uncomment the code block below to apply fixes.")
            """
            # To fix: 
            # 1. Delete any invoice that references order 1 but really should be for order 2
            # 2. Or update the order_id to reference the correct order
            
            # DELETE approach (use with caution)
            # db.session.execute(db.text("DELETE FROM invoices WHERE order_id = 1"))
            
            # UPDATE approach (safer)
            # db.session.execute(db.text("UPDATE invoices SET order_id = 2 WHERE order_id = 1"))
            # db.session.commit()
            """
            
    except Exception as e:
        print(f"Error in fix attempt: {str(e)}")
        
    print("\nScript execution complete") 