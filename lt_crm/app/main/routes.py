"""Routes for the main blueprint."""
from datetime import datetime, timedelta
from flask import render_template, request, jsonify, redirect, url_for, flash, send_file
from flask_login import login_required
from . import bp
from ..models.product import Product
from ..models.order import Order, OrderStatus
from ..models.invoice import Invoice, InvoiceStatus
from ..models.stock import StockMovement
from ..extensions import db
from sqlalchemy import func
from ..models.customer import Customer


@bp.route("/")
def index():
    """Home page."""
    return render_template("main/index.html", title="Home")


@bp.route("/dashboard")
@login_required
def dashboard():
    """Dashboard page with sales chart and low stock alerts."""
    # Get monthly sales data
    current_month = datetime.now().month
    current_year = datetime.now().year
    
    # Calculate monthly sales for the current year
    monthly_sales_data = db.session.query(
        func.extract('month', Order.created_at).label('month'),
        func.sum(Order.total_amount).label('total')
    ).filter(
        func.extract('year', Order.created_at) == current_year,
        Order.status != OrderStatus.CANCELLED
    ).group_by(
        func.extract('month', Order.created_at)
    ).all()
    
    # Create a list of sales by month (for the chart)
    sales_data = [0] * 12
    for month, total in monthly_sales_data:
        sales_data[int(month) - 1] = float(total or 0)
    
    # Get current month sales
    monthly_sales = db.session.query(
        func.sum(Order.total_amount)
    ).filter(
        func.extract('month', Order.created_at) == current_month,
        func.extract('year', Order.created_at) == current_year,
        Order.status != OrderStatus.CANCELLED
    ).scalar() or 0
    
    # Calculate growth from previous month
    prev_month = current_month - 1 if current_month > 1 else 12
    prev_year = current_year if current_month > 1 else current_year - 1
    
    prev_month_sales = db.session.query(
        func.sum(Order.total_amount)
    ).filter(
        func.extract('month', Order.created_at) == prev_month,
        func.extract('year', Order.created_at) == prev_year,
        Order.status != OrderStatus.CANCELLED
    ).scalar() or 0
    
    if prev_month_sales > 0:
        sales_growth = round(((monthly_sales - prev_month_sales) / prev_month_sales) * 100)
    else:
        sales_growth = 100 if monthly_sales > 0 else 0
    
    # Get low stock products
    low_stock_products = Product.query.filter(Product.quantity <= 10).order_by(Product.quantity).limit(5).all()
    
    # Get new orders (last 24h)
    yesterday = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    new_orders = Order.query.filter(Order.created_at >= yesterday).count()
    
    # Get pending orders
    pending_orders = Order.query.filter(Order.status.in_([OrderStatus.PAID, OrderStatus.PACKED])).count()
    
    # Recent orders
    recent_orders = Order.query.order_by(Order.created_at.desc()).limit(10).all()
    
    return render_template(
        "main/dashboard.html", 
        title="Skydelis",
        monthly_sales=monthly_sales,
        sales_growth=sales_growth,
        sales_data=sales_data,
        low_stock_products=low_stock_products,
        new_orders=new_orders,
        pending_orders=pending_orders,
        recent_orders=recent_orders,
    )


@bp.route("/products")
@login_required
def products():
    """Products list page."""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    # Base query
    query = Product.query
    
    # Apply filters
    if request.args.get('q'):
        search = f"%{request.args.get('q')}%"
        query = query.filter(
            (Product.name.ilike(search)) | 
            (Product.sku.ilike(search)) | 
            (Product.barcode.ilike(search))
        )
    
    if request.args.get('category'):
        query = query.filter(Product.category == request.args.get('category'))
    
    if request.args.get('stock') == 'in_stock':
        query = query.filter(Product.quantity > 0)
    elif request.args.get('stock') == 'low':
        query = query.filter((Product.quantity > 0) & (Product.quantity <= 10))
    elif request.args.get('stock') == 'out_of_stock':
        query = query.filter(Product.quantity == 0)
    
    # Execute query with pagination
    pagination = query.order_by(Product.created_at.desc()).paginate(page=page, per_page=per_page)
    products = pagination.items
    
    # Get unique categories for filter dropdown
    categories = db.session.query(Product.category).filter(Product.category.isnot(None)).distinct().all()
    categories = [c[0] for c in categories if c[0]]
    
    return render_template(
        "main/products.html",
        title="Produktai",
        products=products,
        pagination=pagination,
        categories=categories,
    )


@bp.route("/products/new", methods=["GET", "POST"])
@login_required
def product_new():
    """Add new product page."""
    categories = db.session.query(Product.category).filter(Product.category.isnot(None)).distinct().all()
    categories = [c[0] for c in categories if c[0]]
    
    if request.method == "POST":
        # Handle product creation via HTMX
        # Implementation details would go here
        pass
    
    return render_template(
        "main/product_form.html",
        title="Naujas produktas",
        categories=categories,
    )


@bp.route("/products/<int:id>/edit", methods=["GET", "POST"])
@login_required
def product_edit(id):
    """Edit product page."""
    product = Product.query.get_or_404(id)
    
    categories = db.session.query(Product.category).filter(Product.category.isnot(None)).distinct().all()
    categories = [c[0] for c in categories if c[0]]
    
    if request.method == "POST":
        # Handle product update via HTMX
        # Implementation details would go here
        pass
    
    return render_template(
        "main/product_form.html",
        title=f"Redaguoti {product.name}",
        product=product,
        categories=categories,
    )


@bp.route("/orders")
@login_required
def orders():
    """Orders list page."""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    # Base query
    query = Order.query
    
    # Apply filters
    if request.args.get('q'):
        search = f"%{request.args.get('q')}%"
        query = query.filter(
            (Order.order_number.ilike(search)) | 
            (Order.shipping_name.ilike(search)) | 
            (Order.shipping_email.ilike(search))
        )
    
    if request.args.get('status'):
        statuses = request.args.get('status').split(',')
        query = query.filter(Order.status.in_([OrderStatus(s) for s in statuses]))
    
    if request.args.get('source'):
        query = query.filter(Order.source == request.args.get('source'))
    
    # Execute query with pagination
    pagination = query.order_by(Order.created_at.desc()).paginate(page=page, per_page=per_page)
    orders = pagination.items
    
    return render_template(
        "main/orders.html",
        title="Užsakymai",
        orders=orders,
        pagination=pagination,
    )


@bp.route("/invoices")
@login_required
def invoices():
    """Invoices list page."""
    page = request.args.get('page', 1, type=int)
    per_page = 20
    
    # Base query
    query = Invoice.query
    
    # Apply filters
    if request.args.get('q'):
        search = f"%{request.args.get('q')}%"
        query = query.filter(
            (Invoice.invoice_number.ilike(search)) | 
            (Invoice.billing_name.ilike(search)) | 
            (Invoice.billing_email.ilike(search))
        )
    
    if request.args.get('status'):
        query = query.filter(Invoice.status == InvoiceStatus(request.args.get('status')))
    
    if request.args.get('date_from'):
        try:
            date_from = datetime.strptime(request.args.get('date_from'), '%Y-%m-%d')
            query = query.filter(Invoice.issue_date >= date_from)
        except ValueError:
            pass
    
    if request.args.get('date_to'):
        try:
            date_to = datetime.strptime(request.args.get('date_to'), '%Y-%m-%d')
            query = query.filter(Invoice.issue_date <= date_to)
        except ValueError:
            pass
    
    # Execute query with pagination
    pagination = query.order_by(Invoice.created_at.desc()).paginate(page=page, per_page=per_page)
    invoices = pagination.items
    
    return render_template(
        "main/invoices.html",
        title="Sąskaitos faktūros",
        invoices=invoices,
        pagination=pagination,
        now=datetime.now(),
    )


@bp.route("/invoices/<int:id>/pdf")
@login_required
def invoice_pdf(id):
    """Generate and download invoice PDF."""
    invoice = Invoice.query.get_or_404(id)
    
    # Here would be the logic to generate or retrieve the PDF
    # For now, we'll just return a placeholder
    
    return jsonify({"message": "PDF generation not implemented yet", "invoice_id": id})


@bp.route("/invoices/export-pdf")
@login_required
def invoices_export_pdf():
    """Export multiple invoices as PDF."""
    # Here would be the logic to export multiple invoices
    # For now, we'll just return a placeholder
    
    return jsonify({"message": "Batch PDF export not implemented yet"})


@bp.route("/invoices/export-csv")
@login_required
def invoices_export_csv():
    """Export invoices as CSV."""
    # Here would be the logic to export invoices to CSV
    # For now, we'll just return a placeholder
    
    return jsonify({"message": "CSV export not implemented yet"})


@bp.route("/orders/<int:id>")
@login_required
def order_detail(id):
    """Order detail page."""
    order = Order.query.get_or_404(id)
    return render_template(
        "main/order_detail.html",
        title=f"Užsakymas {order.order_number}",
        order=order
    )


@bp.route("/products/<int:id>")
@login_required
def product_detail(id):
    """Product detail page."""
    product = Product.query.get_or_404(id)
    
    # Get stock movements for this product
    stock_movements = StockMovement.query.filter_by(product_id=id).order_by(StockMovement.created_at.desc()).limit(10).all()
    
    return render_template(
        "main/product_detail.html",
        title=product.name,
        product=product,
        stock_movements=stock_movements
    )


@bp.route("/products/<int:id>/delete", methods=["DELETE"])
@login_required
def product_delete(id):
    """Delete a product."""
    product = Product.query.get_or_404(id)
    
    try:
        # Check if product can be deleted
        # For example, check if it's used in any orders
        # order_items = OrderItem.query.filter_by(product_id=id).first()
        # if order_items:
        #     return jsonify({"error": "Product cannot be deleted as it is associated with orders"}), 400
        
        # Delete related stock movements
        StockMovement.query.filter_by(product_id=id).delete()
        
        # Delete the product
        db.session.delete(product)
        db.session.commit()
        
        return "", 204  # No content, successful deletion
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500 


@bp.route("/products/import-csv", methods=["POST"])
@login_required
def product_import_csv():
    """Import products from CSV file."""
    if 'csv_file' not in request.files:
        flash("No file part", "error")
        return redirect(url_for('main.products'))
    
    file = request.files['csv_file']
    if file.filename == '':
        flash("No selected file", "error")
        return redirect(url_for('main.products'))
    
    if file:
        try:
            # Get form parameters
            encoding = request.form.get('encoding', 'utf-8')
            delimiter = request.form.get('delimiter', ',')
            has_header = 'has_header' in request.form
            
            # Convert delimiter from string representation
            if delimiter == '\\t':
                delimiter = '\t'
            
            # Process CSV
            import pandas as pd
            import io
            
            # Read CSV into pandas DataFrame
            df = pd.read_csv(
                io.StringIO(file.stream.read().decode(encoding)), 
                delimiter=delimiter,
                header=0 if has_header else None
            )
            
            # Map column names if header exists, otherwise use default names
            if has_header:
                # Expected columns: sku, name, description, price, cost_price, quantity, category, barcode
                required_columns = ['sku', 'name', 'price']
                if not all(col in df.columns for col in required_columns):
                    flash(f"CSV must contain required columns: {', '.join(required_columns)}", "error")
                    return redirect(url_for('main.products'))
            else:
                # Assign default column names
                df.columns = ['sku', 'name', 'description', 'price', 'cost_price', 
                              'quantity', 'category', 'barcode'][:len(df.columns)]
            
            # Process each row
            products_created = 0
            products_updated = 0
            
            for _, row in df.iterrows():
                # Check if product exists by SKU
                product = Product.query.filter_by(sku=row['sku']).first()
                
                if product:
                    # Update existing product
                    product.name = row['name']
                    if 'description' in row and pd.notna(row['description']):
                        product.description = row['description']
                    if 'price' in row and pd.notna(row['price']):
                        product.price = row['price']
                    if 'cost_price' in row and pd.notna(row['cost_price']):
                        product.cost_price = row['cost_price']
                    if 'quantity' in row and pd.notna(row['quantity']):
                        product.quantity = row['quantity']
                    if 'category' in row and pd.notna(row['category']):
                        product.category = row['category']
                    if 'barcode' in row and pd.notna(row['barcode']):
                        product.barcode = row['barcode']
                    
                    products_updated += 1
                else:
                    # Create new product
                    new_product = Product(
                        sku=row['sku'],
                        name=row['name'],
                        description=row['description'] if 'description' in row and pd.notna(row['description']) else None,
                        price=row['price'],
                        cost_price=row['cost_price'] if 'cost_price' in row and pd.notna(row['cost_price']) else 0,
                        quantity=row['quantity'] if 'quantity' in row and pd.notna(row['quantity']) else 0,
                        category=row['category'] if 'category' in row and pd.notna(row['category']) else None,
                        barcode=row['barcode'] if 'barcode' in row and pd.notna(row['barcode']) else None,
                        is_active=True
                    )
                    db.session.add(new_product)
                    products_created += 1
            
            db.session.commit()
            flash(f"Successfully imported CSV: {products_created} products created, {products_updated} products updated", "success")
            
        except Exception as e:
            db.session.rollback()
            flash(f"Error importing CSV: {str(e)}", "error")
        
    return redirect(url_for('main.products'))


@bp.route("/orders/new", methods=["GET", "POST"])
@login_required
def order_new():
    """Create a new order."""
    if request.method == "POST":
        # Here would be the logic to create a new order
        # For now, we'll just redirect to the orders page
        flash("Order creation not implemented yet", "info")
        return redirect(url_for('main.orders'))
    
    # Get all active products for the order form
    products = Product.query.filter_by(is_active=True).order_by(Product.name).all()
    
    return render_template(
        "main/order_form.html",
        title="Naujas užsakymas",
        products=products
    )


@bp.route("/orders/<int:id>/update-status", methods=["PUT"])
@login_required
def order_update_status(id):
    """Update an order's status."""
    order = Order.query.get_or_404(id)
    
    try:
        status = request.form.get("status")
        if not status or status not in [e.value for e in OrderStatus]:
            return jsonify({"error": "Invalid status"}), 400
        
        # Update the status
        order.status = OrderStatus(status)
        
        # If status is shipped, set shipped_at date
        if order.status == OrderStatus.SHIPPED and not order.shipped_at:
            order.shipped_at = datetime.now()
        
        db.session.commit()
        return jsonify({"message": "Status updated successfully"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500 


@bp.route("/customers/<int:id>")
@login_required
def customer_detail(id):
    """Customer detail page."""
    # This is a placeholder since we don't have a customer model implemented yet
    # In a real app, you would fetch the customer from the database
    # For now, we'll just redirect to the orders page
    flash(f"Customer detail view not implemented yet (ID: {id})", "info")
    return redirect(url_for('main.orders'))


@bp.route("/invoices/new-from-order/<int:order_id>")
@login_required
def invoice_new_from_order(order_id):
    """Create a new invoice from an order."""
    order = Order.query.get_or_404(order_id)
    
    # Check if invoice already exists for this order
    existing_invoice = Invoice.query.filter_by(order_id=order_id).first()
    if existing_invoice:
        flash(f"Invoice {existing_invoice.invoice_number} already exists for this order", "info")
        return redirect(url_for('main.invoice_detail', id=existing_invoice.id))
    
    try:
        # Generate invoice number (format: LT-INV-00001)
        last_invoice = Invoice.query.order_by(Invoice.id.desc()).first()
        invoice_num = 1
        if last_invoice and last_invoice.invoice_number:
            try:
                # Extract the numeric part of the last invoice number
                invoice_num = int(last_invoice.invoice_number.split('-')[-1]) + 1
            except (ValueError, IndexError):
                invoice_num = 1
        
        invoice_number = f"LT-INV-{invoice_num:05d}"
        
        # Calculate due date (14 days from today)
        today = datetime.now().date()
        due_date = today + timedelta(days=14)
        
        # Create a new invoice from the order
        new_invoice = Invoice(
            invoice_number=invoice_number,
            order_id=order.id,
            customer_id=order.customer_id,
            status=InvoiceStatus.DRAFT,
            issue_date=today,
            due_date=due_date,
            total_amount=order.total_amount,
            tax_amount=order.tax_amount,
            subtotal_amount=order.total_amount - (order.tax_amount or 0),
            billing_name=order.shipping_name,
            billing_address=order.shipping_address,
            billing_city=order.shipping_city,
            billing_postal_code=order.shipping_postal_code,
            billing_country=order.shipping_country,
            billing_email=order.shipping_email,
            notes=f"Invoice created from order {order.order_number}"
        )
        
        db.session.add(new_invoice)
        db.session.commit()
        
        flash(f"Invoice {invoice_number} created successfully from order {order.order_number}", "success")
        return redirect(url_for('main.invoice_detail', id=new_invoice.id))
    except Exception as e:
        db.session.rollback()
        flash(f"Error creating invoice: {str(e)}", "error")
        return redirect(url_for('main.order_detail', id=order_id))


@bp.route("/invoices/new", methods=["GET", "POST"])
@login_required
def invoice_new():
    """Create a new invoice."""
    if request.method == "POST":
        # Here would be the logic to create a new invoice
        # For now, we'll just redirect to the invoices page
        flash("Invoice creation not implemented yet", "info")
        return redirect(url_for('main.invoices'))
    
    # Get all customers for the invoice form
    customers = Customer.query.order_by(Customer.name).all()
    
    return render_template(
        "main/invoice_form.html",
        title="Nauja sąskaita faktūra",
        customers=customers
    )


@bp.route("/invoices/<int:id>")
@login_required
def invoice_detail(id):
    """Invoice detail page."""
    invoice = Invoice.query.get_or_404(id)
    
    return render_template(
        "main/invoice_detail.html",
        title=f"Sąskaita {invoice.invoice_number}",
        invoice=invoice
    )


@bp.route("/invoices/<int:id>/issue", methods=["PUT"])
@login_required
def invoice_issue(id):
    """Issue an invoice."""
    invoice = Invoice.query.get_or_404(id)
    
    try:
        # Change status from draft to issued
        if invoice.status != InvoiceStatus.DRAFT:
            return jsonify({"error": "Only draft invoices can be issued"}), 400
        
        # Update the status
        invoice.status = InvoiceStatus.ISSUED
        
        # Set issue date if not already set
        if not invoice.issue_date:
            invoice.issue_date = datetime.now().date()
        
        db.session.commit()
        return jsonify({"message": "Invoice issued successfully"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500 