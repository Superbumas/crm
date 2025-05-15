import sys
from lt_crm.app.models.stock import StockMovement, MovementReasonCode
from lt_crm.app.extensions import db
from lt_crm.app import create_app

app = create_app()
with app.app_context():
    movements = StockMovement.query.filter(StockMovement.reason_code == MovementReasonCode.SALE).all()
    print(f'Found {len(movements)} movements with reason SALE')
    for m in movements:
        print(f'ID: {m.id}, Product: {m.product_id}, Delta: {m.qty_delta}, Note: {m.note}, Created: {m.created_at}')

    # Also check raw database
    from sqlalchemy import text
    result = db.session.execute(text("SELECT * FROM stock_movements WHERE reason_code = 'SALE' ORDER BY created_at DESC LIMIT 10"))
    print("\nRaw SQL query results:")
    for row in result:
        print(f'ID: {row.id}, Product: {row.product_id}, Delta: {row.qty_delta}, Note: {row.note}, Created: {row.created_at}') 