"""CLI commands for the application."""
import os
import json
import click
import zipfile
import shutil
from datetime import datetime
from tempfile import mkdtemp
from pathlib import Path
from flask import current_app
from flask.cli import with_appcontext
from lt_crm.app.extensions import db
from lt_crm.app.models.user import User
from lt_crm.app.models.order import Order, OrderItem
from lt_crm.app.models.customer import Customer
from lt_crm.app.models.invoice import Invoice
from lt_crm.app.services.accounting import setup_default_accounts
from lt_crm.app.models.product import Product
from lt_crm.app.models.customer import Customer
from lt_crm.app.models.order import Order, OrderItem, OrderStatus


@click.group()
def translate():
    """Translation and localization commands."""
    pass


@translate.command()
@with_appcontext
def extract():
    """Extract messages to be translated."""
    if not os.path.exists("app/translations"):
        os.makedirs("app/translations")
    os.system(
        "pybabel extract -F babel.cfg -k _l -o app/translations/messages.pot app"
    )
    click.echo("Extracted messages into app/translations/messages.pot")


@translate.command()
@click.argument("lang")
@with_appcontext
def init(lang):
    """Initialize a new language."""
    if not os.path.exists("app/translations/messages.pot"):
        click.echo("messages.pot not found. Run `flask translate extract` first.")
        return
    os.system(
        f"pybabel init -i app/translations/messages.pot -d app/translations -l {lang}"
    )
    click.echo(f"Initialized translation for {lang}")


@translate.command()
@with_appcontext
def update():
    """Update all language translations."""
    if not os.path.exists("app/translations/messages.pot"):
        click.echo("messages.pot not found. Run `flask translate extract` first.")
        return
    os.system(
        "pybabel update -i app/translations/messages.pot -d app/translations"
    )
    click.echo("Updated translations")


@translate.command()
@with_appcontext
def compile():
    """Compile all language translations."""
    if not os.path.exists("app/translations"):
        click.echo("No translations found. Run `flask translate extract` first.")
        return
    os.system("pybabel compile -d app/translations")
    click.echo("Compiled translations")


@click.command("setup-accounts")
@with_appcontext
def setup_accounts():
    """Initialize default accounting accounts."""
    try:
        result = setup_default_accounts()
        click.echo(f"Created {result['created']} new accounts, {result['existing']} already existed.")
    except Exception as e:
        click.echo(f"Error setting up accounts: {str(e)}")


@click.command("export-user-data")
@click.argument("user_id", type=int)
@with_appcontext
def export_user_data(user_id):
    """Export all data for a user as a ZIP file with JSON content (GDPR)."""
    user = User.query.get(user_id)
    if not user:
        click.echo(f"Error: User with ID {user_id} not found.")
        return
    
    try:
        # Create temporary directory
        temp_dir = mkdtemp()
        temp_path = Path(temp_dir)
        
        # Build user data structure
        data = {
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_active": user.is_active,
                "is_admin": user.is_admin,
                "last_login": user.last_login.isoformat() if user.last_login else None,
                "created_at": user.created_at.isoformat() if user.created_at else None,
                "updated_at": user.updated_at.isoformat() if user.updated_at else None,
            },
        }
        
        # Get customer info if exists
        customer = Customer.query.filter_by(user_id=user.id).first()
        if customer:
            data["customer"] = {
                "id": customer.id,
                "name": customer.name,
                "email": customer.email,
                "phone": customer.phone,
                "company": customer.company,
                "vat_code": customer.vat_code,
                "address": customer.address,
                "city": customer.city,
                "postal_code": customer.postal_code,
                "country": customer.country,
                "created_at": customer.created_at.isoformat() if customer.created_at else None,
                "updated_at": customer.updated_at.isoformat() if customer.updated_at else None,
            }
            
            # Get customer orders
            orders = Order.query.filter_by(customer_id=customer.id).all()
            data["orders"] = []
            for order in orders:
                order_data = {
                    "id": order.id,
                    "order_number": order.order_number,
                    "status": order.status.value,
                    "total_amount": str(order.total_amount),
                    "tax_amount": str(order.tax_amount) if order.tax_amount else None,
                    "shipping_amount": str(order.shipping_amount) if order.shipping_amount else None,
                    "discount_amount": str(order.discount_amount) if order.discount_amount else None,
                    "shipping_name": order.shipping_name,
                    "shipping_address": order.shipping_address,
                    "shipping_city": order.shipping_city,
                    "shipping_postal_code": order.shipping_postal_code,
                    "shipping_country": order.shipping_country,
                    "shipping_phone": order.shipping_phone,
                    "shipping_email": order.shipping_email,
                    "payment_method": order.payment_method,
                    "shipping_method": order.shipping_method,
                    "created_at": order.created_at.isoformat() if order.created_at else None,
                    "items": [],
                }
                
                # Get order items
                items = OrderItem.query.filter_by(order_id=order.id).all()
                for item in items:
                    item_data = {
                        "id": item.id,
                        "product_id": item.product_id,
                        "quantity": item.quantity,
                        "price": str(item.price),
                        "tax_rate": str(item.tax_rate) if item.tax_rate else None,
                        "discount_amount": str(item.discount_amount) if item.discount_amount else None,
                    }
                    order_data["items"].append(item_data)
                
                data["orders"].append(order_data)
            
            # Get customer invoices
            invoices = Invoice.query.filter_by(customer_id=customer.id).all()
            data["invoices"] = []
            for invoice in invoices:
                invoice_data = {
                    "id": invoice.id,
                    "invoice_number": invoice.invoice_number,
                    "order_id": invoice.order_id,
                    "total_amount": str(invoice.total_amount),
                    "tax_amount": str(invoice.tax_amount) if invoice.tax_amount else None,
                    "status": invoice.status,
                    "issue_date": invoice.issue_date.isoformat() if invoice.issue_date else None,
                    "due_date": invoice.due_date.isoformat() if invoice.due_date else None,
                    "paid_date": invoice.paid_date.isoformat() if invoice.paid_date else None,
                    "created_at": invoice.created_at.isoformat() if invoice.created_at else None,
                }
                data["invoices"].append(invoice_data)
        
        # Write JSON to file
        with open(temp_path / "user_data.json", "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Create ZIP file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        zip_filename = f"user_{user_id}_data_export_{timestamp}.zip"
        zip_path = Path(current_app.instance_path) / zip_filename
        
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
            zipf.write(temp_path / "user_data.json", arcname="user_data.json")
        
        # Clean up temp directory
        shutil.rmtree(temp_dir)
        
        click.echo(f"User data exported successfully to: {zip_path}")
        return str(zip_path)
    
    except Exception as e:
        click.echo(f"Error exporting user data: {str(e)}")
        if 'temp_dir' in locals():
            shutil.rmtree(temp_dir)


@click.command("delete-user-data")
@click.argument("user_id", type=int)
@click.option("--export/--no-export", default=True, help="Export data before deletion")
@click.option("--confirm", is_flag=True, help="Confirm deletion without prompt")
@with_appcontext
def delete_user_data(user_id, export, confirm):
    """Delete user data with anonymization for GDPR compliance."""
    user = User.query.get(user_id)
    if not user:
        click.echo(f"Error: User with ID {user_id} not found.")
        return
    
    # Export data before deletion if requested
    if export:
        click.echo("Exporting user data before deletion...")
        export_user_data(user_id)
    
    if not confirm:
        confirmation = click.prompt(
            f"Are you sure you want to delete and anonymize data for user {user.username} (ID: {user_id})? "
            "This action cannot be undone. Type 'DELETE' to confirm",
            type=str
        )
        if confirmation != "DELETE":
            click.echo("Deletion cancelled.")
            return
    
    try:
        # Find associated customer
        customer = Customer.query.filter_by(user_id=user.id).first()
        
        if customer:
            # Anonymize customer data
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
            anon_email = f"anonymized_{timestamp}@deleted.example.com"
            
            customer.name = "Anonymized User"
            customer.email = anon_email
            customer.phone = "DELETED"
            customer.company = "DELETED" if customer.company else None
            customer.vat_code = "DELETED" if customer.vat_code else None
            customer.address = "DELETED"
            customer.city = "DELETED"
            customer.postal_code = "DELETED"
            customer.country = "DELETED"
            customer.user_id = None  # Disconnect from user
            
            # Find all orders for this customer and anonymize shipping info
            orders = Order.query.filter_by(customer_id=customer.id).all()
            for order in orders:
                order.shipping_name = "Anonymized User"
                order.shipping_address = "DELETED"
                order.shipping_city = "DELETED"
                order.shipping_postal_code = "DELETED"
                order.shipping_country = "DELETED"
                order.shipping_phone = "DELETED"
                order.shipping_email = anon_email
                order.notes = "DELETED" if order.notes else None
            
            # Commit changes before deleting user
            db.session.commit()
        
        # Anonymize user before deletion
        user.username = f"deleted_user_{timestamp}"
        user.email = anon_email
        user.password_hash = None
        user.is_active = False
        
        # Commit final changes and delete user
        db.session.commit()
        
        click.echo(f"User data for ID {user_id} has been anonymized successfully.")
    
    except Exception as e:
        db.session.rollback()
        click.echo(f"Error anonymizing user data: {str(e)}")


@click.command("seed-demo")
@with_appcontext
def seed_demo():
    """Seed database with Lithuanian sample products and orders for demo purposes."""
    from lt_crm.app.models.product import Product
    from lt_crm.app.models.customer import Customer
    from lt_crm.app.models.order import Order, OrderItem, OrderStatus
    
    # Create demo products
    products = [
        {
            "sku": "LT-DUONA-01",
            "name": "Juoda ruginė duona",
            "description_html": "<p>Tradicinė lietuviška ruginė duona, kepta pagal senovinį receptą.</p>",
            "barcode": "4750010001234",
            "quantity": 50,
            "delivery_days": 3,
            "price_final": 3.99,
            "category": "Duonos gaminiai",
            "manufacturer": "Vilniaus Duona",
            "weight_kg": 0.8,
            "parameters": {"ingredients": "ruginiai miltai, vanduo, druska, raugas"}
        },
        {
            "sku": "LT-SURIS-01",
            "name": "Džiugas sūris (12 mėn)",
            "description_html": "<p>Ilgai brandintas lietuviškas kietasis sūris.</p>",
            "barcode": "4750010005678",
            "quantity": 30,
            "delivery_days": 5,
            "price_final": 15.99,
            "price_old": 17.99,
            "category": "Pieno produktai",
            "manufacturer": "Džiugas",
            "weight_kg": 0.5,
            "parameters": {"fat_percentage": "40%", "aging": "12 months"}
        },
        {
            "sku": "LT-GIRA-01",
            "name": "Naminio skonio gira",
            "description_html": "<p>Natūraliai fermentuota gira pagal tradicinį receptą.</p>",
            "barcode": "4750010009876",
            "quantity": 100,
            "delivery_days": 2,
            "price_final": 2.49,
            "category": "Gėrimai",
            "manufacturer": "Gubernija",
            "weight_kg": 1.5,
            "parameters": {"volume": "1.5L", "ingredients": "vanduo, rugiai, cukrus, mielės"}
        },
        {
            "sku": "LT-MED-01",
            "name": "Lietuviškas liepų medus",
            "description_html": "<p>Natūralus liepų žiedų medus iš Lietuvos bitynų.</p>",
            "barcode": "4750010002345",
            "quantity": 25,
            "delivery_days": 4,
            "price_final": 8.99,
            "category": "Bitininkystės produktai",
            "manufacturer": "Lietuvos Bitininkai",
            "weight_kg": 0.5,
            "parameters": {"type": "liepų žiedų", "region": "Dzūkija"}
        },
        {
            "sku": "LT-SILKE-01",
            "name": "Silkė pataluose",
            "description_html": "<p>Tradicinis lietuviškas patiekalas - marinuotos silkės filė su daržovių sluoksniais.</p>",
            "barcode": "4750010003456",
            "quantity": 15,
            "delivery_days": 3,
            "price_final": 5.49,
            "category": "Kulinarija",
            "manufacturer": "Vičiūnai",
            "weight_kg": 0.4,
            "parameters": {"ingredients": "silkės filė, burokėliai, morkos, svogūnai, majonezas"}
        }
    ]
    
    # Create products if they don't exist
    created_products = []
    for product_data in products:
        product = Product.query.filter_by(sku=product_data["sku"]).first()
        if not product:
            product = Product(**product_data)
            db.session.add(product)
            created_products.append(product)
    
    # Create demo customer if doesn't exist
    customer = Customer.query.filter_by(email="demo@example.lt").first()
    if not customer:
        customer = Customer(
            name="Jonas Jonaitis",
            email="demo@example.lt",
            phone="+37060012345",
            company="UAB Demo Įmonė",
            notes="VAT code: LT123456789",
            address="Gedimino pr. 1",
            city="Vilnius",
            country="Lithuania"
        )
        db.session.add(customer)
    
    # We need to commit here to get IDs for the next step
    db.session.commit()
    
    # Create demo orders
    if created_products and Order.query.count() < 5:
        # Create order 1
        order1 = Order(
            order_number="LT-ORD-001",
            customer_id=customer.id,
            status=OrderStatus.SHIPPED,
            total_amount=29.97,
            tax_amount=5.20,
            shipping_amount=5.99,
            shipping_name="Jonas Jonaitis",
            shipping_address="Gedimino pr. 1",
            shipping_city="Vilnius",
            shipping_postal_code="01103",
            shipping_country="Lithuania",
            shipping_phone="+37060012345",
            shipping_email="demo@example.lt",
            payment_method="credit_card",
            shipping_method="courier",
            tracking_number="LT1234567890"
        )
        db.session.add(order1)
        db.session.flush()  # Get the order ID without committing
        
        # Add items to order 1
        item1 = OrderItem(
            order_id=order1.id,
            product_id=created_products[0].id,  # Juoda ruginė duona
            quantity=2,
            price=3.99,
            tax_rate=21.00
        )
        item2 = OrderItem(
            order_id=order1.id,
            product_id=created_products[2].id,  # Naminio skonio gira
            quantity=3,
            price=2.49,
            tax_rate=21.00
        )
        db.session.add_all([item1, item2])
        
        # Create order 2
        order2 = Order(
            order_number="LT-ORD-002",
            customer_id=customer.id,
            status=OrderStatus.PAID,
            total_amount=24.98,
            tax_amount=4.33,
            shipping_amount=0,
            shipping_name="Jonas Jonaitis",
            shipping_address="Gedimino pr. 1",
            shipping_city="Vilnius",
            shipping_postal_code="01103",
            shipping_country="Lithuania",
            shipping_phone="+37060012345",
            shipping_email="demo@example.lt",
            payment_method="bank_transfer",
            shipping_method="pickup"
        )
        db.session.add(order2)
        db.session.flush()  # Get the order ID without committing
        
        # Add items to order 2
        item3 = OrderItem(
            order_id=order2.id,
            product_id=created_products[1].id,  # Džiugas sūris
            quantity=1,
            price=15.99,
            tax_rate=21.00
        )
        item4 = OrderItem(
            order_id=order2.id,
            product_id=created_products[3].id,  # Lietuviškas liepų medus
            quantity=1,
            price=8.99,
            tax_rate=21.00
        )
        db.session.add_all([item3, item4])
    
    # Commit all changes
    db.session.commit()
    
    # Print summary
    click.echo(f"Created {len(created_products)} new products")
    if customer:
        click.echo(f"Created or verified demo customer: {customer.name}")
    click.echo("Demo seed completed successfully!")


def register_commands(app):
    """Register CLI commands with the Flask application."""
    app.cli.add_command(translate)
    app.cli.add_command(setup_accounts)
    app.cli.add_command(export_user_data)
    app.cli.add_command(delete_user_data)
    app.cli.add_command(seed_demo) 