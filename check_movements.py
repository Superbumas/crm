from lt_crm.app import create_app
from lt_crm.app.extensions import db
from sqlalchemy import text

app = create_app()
with app.app_context():
    # Use raw SQL to avoid any enum conversion issues
    result = db.session.execute(text("SELECT * FROM stock_movements ORDER BY created_at DESC LIMIT 10"))
    print("Recent stock movements:")
    for row in result:
        print(f"ID: {row.id}, Product: {row.product_id}, Reason: {row.reason_code}, Delta: {row.qty_delta}, Note: {row.note}, Created: {row.created_at}") 