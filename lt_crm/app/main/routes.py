"""Routes for the main blueprint."""
from datetime import datetime
from flask import render_template, request, jsonify, redirect, url_for, flash, send_file
from flask_login import login_required
from app.main import bp
from app.models.product import Product
from app.models.order import Order, OrderStatus
from app.models.invoice import Invoice, InvoiceStatus
from app.models.stock import StockMovement
from app.extensions import db
from sqlalchemy import func


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