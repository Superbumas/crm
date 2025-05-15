"""
Script to create the shipment tables in the database
"""
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.stock import Shipment, ShipmentItem, ShipmentStatus

app = create_app()

with app.app_context():
    print("=== CREATING SHIPMENT TABLES ===")
    
    # Create the shipment tables
    Shipment.__table__.create(db.engine, checkfirst=True)
    ShipmentItem.__table__.create(db.engine, checkfirst=True)
    
    print("Shipment tables created successfully.") 