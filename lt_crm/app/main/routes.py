"""Routes for the main blueprint."""
from datetime import datetime, timedelta
from io import BytesIO
import pandas as pd
from flask import (
    render_template, flash, redirect, url_for, request, 
    current_app, jsonify, Response, send_file, session
)
from flask_login import current_user, login_required
from werkzeug.utils import secure_filename
from flask_babel import gettext as _
import uuid
import os
import csv
from sqlalchemy import func, text

from . import bp
from lt_crm.app.models.user import User
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product
from lt_crm.app.models.customer import Customer, Contact, Task
from lt_crm.app.models.order import Order, OrderItem, OrderStatus
from lt_crm.app.models.invoice import Invoice, InvoiceStatus, InvoiceItem
from lt_crm.app.models.stock import StockMovement, Shipment, ShipmentItem, ShipmentStatus, MovementReasonCode
from lt_crm.app.models.settings import CompanySettings
from lt_crm.app.main.forms import ShipmentForm, ShipmentItemForm, CompanySettingsForm


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
    
    # Calculate weekly sales data (for the past 7 days)
    today = datetime.now().date()
    
    # Query to get sales per day for the last 7 days
    # This is more database-agnostic than using dow extraction
    weekly_sales_data = []
    for i in range(6, -1, -1):  # Count backwards from 6 to 0 to get oldest to newest days
        day = today - timedelta(days=i)
        day_start = datetime.combine(day, datetime.min.time())
        day_end = datetime.combine(day, datetime.max.time())
        
        # Get sales for this day
        day_sales = db.session.query(
            func.sum(Order.total_amount)
        ).filter(
            Order.created_at >= day_start,
            Order.created_at <= day_end,
            Order.status != OrderStatus.CANCELLED
        ).scalar() or 0
        
        # Use position in array (0-6) rather than weekday
        weekly_sales_data.append((6-i, float(day_sales)))
    
    # Create list of sales by day of week (in order from 7 days ago to today)
    weekly_data = [0] * 7
    for position, total in weekly_sales_data:
        weekly_data[position] = total
    
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
    
    # Count orders by status for chart
    status_counts = {}
    for status in OrderStatus:
        count = Order.query.filter(Order.status == status).count()
        status_counts[status.name.lower()] = count
    
    return render_template(
        "main/dashboard.html", 
        title="Skydelis",
        monthly_sales=monthly_sales,
        sales_growth=sales_growth,
        sales_data=sales_data,
        weekly_data=weekly_data,
        low_stock_products=low_stock_products,
        new_orders=new_orders,
        pending_orders=pending_orders,
        recent_orders=recent_orders,
        status_counts=status_counts,
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
        try:
            # Get form data
            sku = request.form.get("sku")
            name = request.form.get("name")
            description_html = request.form.get("description_html")
            barcode = request.form.get("barcode")
            quantity = request.form.get("quantity", type=int, default=0)
            delivery_days = request.form.get("delivery_days", type=int)
            price_final = request.form.get("price_final", type=float)
            price_old = request.form.get("price_old", type=float)
            category = request.form.get("category")
            main_image_url = request.form.get("main_image_url")
            extra_image_urls = request.form.get("extra_image_urls")
            model = request.form.get("model")
            manufacturer = request.form.get("manufacturer")
            warranty_months = request.form.get("warranty_months", type=int)
            weight_kg = request.form.get("weight_kg", type=float)
            
            # Validate required fields
            if not sku or not name or not price_final:
                flash("Privalomi laukai: SKU, pavadinimas ir kaina", "error")
                return render_template(
                    "main/product_form.html", 
                    title="Naujas produktas",
                    categories=categories
                )
            
            # Check if product SKU already exists
            existing_product = Product.query.filter_by(sku=sku).first()
            if existing_product:
                flash(f"Produktas su SKU '{sku}' jau egzistuoja", "error")
                return render_template(
                    "main/product_form.html", 
                    title="Naujas produktas",
                    categories=categories
                )
            
            # Parse extra_image_urls if it's in JSON format
            parsed_extra_image_urls = None
            if extra_image_urls:
                try:
                    import json
                    parsed_extra_image_urls = json.loads(extra_image_urls)
                except:
                    # If it's not valid JSON, just use as-is for pipe-separated values
                    parsed_extra_image_urls = extra_image_urls
            
            # Create new product
            product = Product(
                sku=sku,
                name=name,
                description_html=description_html,
                barcode=barcode,
                quantity=quantity,
                delivery_days=delivery_days,
                price_final=price_final,
                price_old=price_old,
                category=category,
                main_image_url=main_image_url,
                extra_image_urls=parsed_extra_image_urls,
                model=model,
                manufacturer=manufacturer,
                warranty_months=warranty_months,
                weight_kg=weight_kg
            )
            
            db.session.add(product)
            db.session.commit()
            
            flash(f"Produktas {name} sėkmingai sukurtas", "success")
            return redirect(url_for("main.product_detail", id=product.id))
            
        except Exception as e:
            db.session.rollback()
            flash(f"Klaida kuriant produktą: {str(e)}", "error")
    
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
        try:
            # Get form data
            sku = request.form.get("sku")
            name = request.form.get("name")
            description_html = request.form.get("description_html")
            barcode = request.form.get("barcode")
            quantity = request.form.get("quantity", type=int, default=0)
            delivery_days = request.form.get("delivery_days", type=int)
            price_final = request.form.get("price_final", type=float)
            price_old = request.form.get("price_old", type=float)
            category = request.form.get("category")
            main_image_url = request.form.get("main_image_url")
            extra_image_urls = request.form.get("extra_image_urls")
            model = request.form.get("model")
            manufacturer = request.form.get("manufacturer")
            warranty_months = request.form.get("warranty_months", type=int)
            weight_kg = request.form.get("weight_kg", type=float)
            
            # Validate required fields
            if not sku or not name or not price_final:
                flash("Privalomi laukai: SKU, pavadinimas ir kaina", "error")
                return render_template(
                    "main/product_form.html", 
                    title=f"Redaguoti {product.name}",
                    product=product,
                    categories=categories
                )
            
            # Check if product SKU already exists with different ID
            existing_product = Product.query.filter(Product.sku == sku, Product.id != id).first()
            if existing_product:
                flash(f"Produktas su SKU '{sku}' jau egzistuoja", "error")
                return render_template(
                    "main/product_form.html", 
                    title=f"Redaguoti {product.name}",
                    product=product,
                    categories=categories
                )
            
            # Parse extra_image_urls if it's in JSON format
            parsed_extra_image_urls = None
            if extra_image_urls:
                try:
                    import json
                    parsed_extra_image_urls = json.loads(extra_image_urls)
                except:
                    # If it's not valid JSON, just use as-is for pipe-separated values
                    parsed_extra_image_urls = extra_image_urls
            
            # Update product
            product.sku = sku
            product.name = name
            product.description_html = description_html
            product.barcode = barcode
            product.quantity = quantity
            product.delivery_days = delivery_days
            product.price_final = price_final
            product.price_old = price_old
            product.category = category
            product.main_image_url = main_image_url
            product.extra_image_urls = parsed_extra_image_urls
            product.model = model
            product.manufacturer = manufacturer
            product.warranty_months = warranty_months
            product.weight_kg = weight_kg
            
            db.session.commit()
            
            flash(f"Produktas {name} sėkmingai atnaujintas", "success")
            return redirect(url_for("main.product_detail", id=product.id))
            
        except Exception as e:
            db.session.rollback()
            flash(f"Klaida atnaujinant produktą: {str(e)}", "error")
    
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
    try:
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
        
        # Get related invoices for each order
        order_invoices = {}
        order_ids = [order.id for order in orders]
        if order_ids:
            invoices = Invoice.query.filter(Invoice.order_id.in_(order_ids)).all()
            for invoice in invoices:
                if invoice.order_id not in order_invoices:
                    order_invoices[invoice.order_id] = []
                order_invoices[invoice.order_id].append(invoice)
        
        return render_template(
            "main/orders.html",
            title="Užsakymai",
            orders=orders,
            pagination=pagination,
            order_invoices=order_invoices,
        )
    except Exception as e:
        # Log the error
        current_app.logger.error(f"Error in orders route: {str(e)}")
        # Rollback the session
        db.session.rollback()
        # Show error message
        flash(f"An error occurred while loading orders: {str(e)}", "error")
        # Return empty list
        return render_template(
            "main/orders.html",
            title="Užsakymai",
            orders=[],
            pagination=None,
            order_invoices={},
        )


@bp.route("/invoices")
@login_required
def invoices():
    """Invoices list page."""
    try:
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
    except Exception as e:
        # Log the error
        current_app.logger.error(f"Error in invoices route: {str(e)}")
        # Rollback the session
        db.session.rollback()
        # Show error message
        flash(f"An error occurred while loading invoices: {str(e)}", "error")
        # Return empty list
        return render_template(
            "main/invoices.html",
            title="Sąskaitos faktūros",
            invoices=[],
            pagination=None,
            now=datetime.now(),
        )


@bp.route("/invoices/<int:id>")
@login_required
def invoice_detail(id):
    """Invoice detail page."""
    # Get invoice WITHOUT eager loading to avoid the dynamic relationship error
    invoice = Invoice.query.get_or_404(id)
    
    # Manually load the items with their products to avoid the dynamic loading issue
    items = InvoiceItem.query.filter_by(invoice_id=id).options(
        db.joinedload(InvoiceItem.product)
    ).all()
    
    # Debug logging
    current_app.logger.info(f"Invoice {id}: Found {len(items)} items")
    for idx, item in enumerate(items):
        current_app.logger.info(f"Item {idx+1}: product_id={item.product_id}, has_product={item.product is not None}, description={item.description}")
    
    return render_template(
        "main/invoice_detail.html",
        title=f"Sąskaita {invoice.invoice_number}",
        invoice=invoice,
        invoice_items=items
    )


@bp.route("/invoices/<int:id>/pdf")
@login_required
def invoice_pdf(id):
    """Generate and download invoice PDF."""
    # Get invoice and load items separately (since it's a dynamic relationship)
    invoice = Invoice.query.get_or_404(id)
    
    # Manually load the items with their products to avoid the dynamic loading issue
    items = InvoiceItem.query.filter_by(invoice_id=id).options(
        db.joinedload(InvoiceItem.product)
    ).all()
    
    # Debug logging
    current_app.logger.info(f"Invoice PDF {id}: Found {len(items)} items")
    for idx, item in enumerate(items):
        current_app.logger.info(f"PDF Item {idx+1}: product_id={item.product_id}, has_product={item.product is not None}, description={item.description}")
    
    try:
        # Import necessary libraries for PDF generation
        from weasyprint import HTML
        from io import BytesIO
        import tempfile
        
        # Get company settings
        company_settings = CompanySettings.get_instance()
        
        # Prepare the template for PDF generation
        rendered_template = render_template(
            "main/invoice_pdf.html",
            invoice=invoice,
            invoice_items=items,
            company_info=company_settings.to_dict()
        )
        
        # Generate PDF from the template
        pdf_file = BytesIO()
        HTML(string=rendered_template).write_pdf(pdf_file)
        pdf_file.seek(0)
        
        # Set the PDF filename
        filename = f"invoice_{invoice.invoice_number.replace('/', '-')}.pdf"
        
        # Return the PDF as a download
        return send_file(
            pdf_file,
            as_attachment=True,
            download_name=filename,
            mimetype='application/pdf'
        )
    except ImportError:
        # Handle case where WeasyPrint is not installed
        flash("PDF generation requires the WeasyPrint library", "error")
        return redirect(url_for('main.invoice_detail', id=id))
    except Exception as e:
        current_app.logger.exception("Error generating PDF")
        flash(f"Error generating PDF: {str(e)}", "error")
        return redirect(url_for('main.invoice_detail', id=id))


@bp.route("/invoices/export-pdf")
@login_required
def invoices_export_pdf():
    """Export multiple invoices as PDF."""
    try:
        # Import necessary libraries for PDF generation
        from weasyprint import HTML
        from io import BytesIO
        import zipfile
        
        # Get invoice IDs from query params
        invoice_ids = request.args.get('ids', '').split(',')
        if not invoice_ids or invoice_ids[0] == '':
            flash("No invoices selected for export", "error")
            return redirect(url_for('main.invoices'))
        
        # Query invoices
        invoices = Invoice.query.filter(Invoice.id.in_(invoice_ids)).all()
        if not invoices:
            flash("No invoices found with the provided IDs", "error")
            return redirect(url_for('main.invoices'))
        
        # Get company settings
        company_settings = CompanySettings.get_instance()
        
        # Create a ZIP file in memory
        memory_file = BytesIO()
        
        with zipfile.ZipFile(memory_file, 'w') as zf:
            # Add each invoice as a PDF
            for invoice in invoices:
                # Generate the PDF
                pdf_buffer = BytesIO()
                
                # Manually load the items with their products for this invoice
                invoice_items = InvoiceItem.query.filter_by(invoice_id=invoice.id).options(
                    db.joinedload(InvoiceItem.product)
                ).all()
                
                # Debug logging
                current_app.logger.info(f"PDF Export - Invoice {invoice.id}: Found {len(invoice_items)} items")
                for idx, item in enumerate(invoice_items):
                    current_app.logger.info(f"PDF Item {idx+1}: product_id={item.product_id}, has_product={item.product is not None}")
                
                rendered_template = render_template(
                    "main/invoice_pdf.html",
                    invoice=invoice,
                    invoice_items=invoice_items,
                    company_info=company_settings.to_dict()
                )
                HTML(string=rendered_template).write_pdf(pdf_buffer)
                pdf_buffer.seek(0)
                
                # Create a safe filename
                safe_invoice_number = invoice.invoice_number.replace('/', '-').replace(' ', '_')
                filename = f"invoice_{safe_invoice_number}.pdf"
                
                # Add to ZIP
                zf.writestr(filename, pdf_buffer.getvalue())
        
        # Set the memory file pointer to the beginning
        memory_file.seek(0)
        
        # Return the ZIP file as a download
        return send_file(
            memory_file,
            as_attachment=True,
            download_name="invoices_export.zip",
            mimetype="application/zip"
        )
    except ImportError:
        flash("PDF generation requires the WeasyPrint library", "error")
        return redirect(url_for('main.invoices'))
    except Exception as e:
        current_app.logger.exception("Error during batch PDF export")
        flash(f"Error during PDF export: {str(e)}", "error")
        return redirect(url_for('main.invoices'))


@bp.route("/invoices/export-csv")
@login_required
def invoices_export_csv():
    """Export invoices as CSV."""
    try:
        import csv
        from io import StringIO
        from datetime import datetime
        
        # Get selected invoice IDs from query parameters
        invoice_ids = request.args.getlist('ids', type=int)
        
        # If no IDs provided, get invoices based on filters
        if not invoice_ids:
            # Get filter parameters
            status = request.args.get('status')
            start_date = request.args.get('start_date')
            end_date = request.args.get('end_date')
            search_query = request.args.get('q')
            
            # Base query
            query = Invoice.query
            
            # Apply filters
            if status and status in [e.value for e in InvoiceStatus]:
                query = query.filter(Invoice.status == InvoiceStatus(status))
            
            if start_date:
                try:
                    start_date = datetime.strptime(start_date, '%Y-%m-%d')
                    query = query.filter(Invoice.issue_date >= start_date)
                except ValueError:
                    pass
            
            if end_date:
                try:
                    end_date = datetime.strptime(end_date, '%Y-%m-%d')
                    query = query.filter(Invoice.issue_date <= end_date)
                except ValueError:
                    pass
            
            if search_query:
                search = f"%{search_query}%"
                query = query.filter(
                    db.or_(
                        Invoice.invoice_number.ilike(search),
                        Invoice.billing_name.ilike(search),
                        Invoice.billing_email.ilike(search)
                    )
                )
            
            # Get filtered invoices, limit to 1000 for performance
            invoices = query.order_by(Invoice.created_at.desc()).limit(1000).all()
        else:
            # Get specified invoices
            invoices = Invoice.query.filter(Invoice.id.in_(invoice_ids)).all()
        
        if not invoices:
            flash("No invoices found to export", "error")
            return redirect(url_for('main.invoices'))
        
        # Create CSV file in memory
        csv_data = StringIO()
        csv_writer = csv.writer(csv_data)
        
        # Write header
        header = [
            'Invoice Number', 'Status', 'Issue Date', 'Due Date', 'Customer/Billing Name',
            'Customer Email', 'Subtotal Amount', 'Tax Amount', 'Total Amount', 'Created At'
        ]
        csv_writer.writerow(header)
        
        # Write data rows
        for invoice in invoices:
            row = [
                invoice.invoice_number,
                invoice.status.value,
                invoice.issue_date.strftime('%Y-%m-%d') if invoice.issue_date else '',
                invoice.due_date.strftime('%Y-%m-%d') if invoice.due_date else '',
                invoice.customer.name if invoice.customer else invoice.billing_name,
                invoice.customer.email if invoice.customer else invoice.billing_email,
                f"{invoice.subtotal_amount:.2f}",
                f"{invoice.tax_amount:.2f}" if invoice.tax_amount else '0.00',
                f"{invoice.total_amount:.2f}",
                invoice.created_at.strftime('%Y-%m-%d %H:%M:%S')
            ]
            csv_writer.writerow(row)
        
        # Set the data pointer to the beginning
        csv_data.seek(0)
        
        # Generate timestamp for filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Return CSV file
        return Response(
            csv_data.getvalue(),
            mimetype="text/csv",
            headers={"Content-Disposition": f"attachment;filename=invoices_export_{timestamp}.csv"}
        )
        
    except Exception as e:
        current_app.logger.exception("Error during CSV export")
        flash(f"Error exporting to CSV: {str(e)}", "error")
        return redirect(url_for('main.invoices'))


@bp.route("/orders/<int:id>")
@login_required
def order_detail(id):
    """Order detail page."""
    order = Order.query.get_or_404(id)
    
    # Get related invoices
    invoices = Invoice.query.filter_by(order_id=id).all()
    
    return render_template(
        "main/order_detail.html",
        title=f"Užsakymas {order.order_number}",
        order=order,
        invoices=invoices
    )


@bp.route("/products/<int:id>")
@login_required
def product_detail(id):
    """Product detail page."""
    product = Product.query.get_or_404(id)
    
    # Get stock movements for this product using raw SQL to avoid enum issues
    sql = text("""
        SELECT 
            id, product_id, qty_delta, reason_code, note, channel, reference_id, user_id, created_at, updated_at
        FROM stock_movements 
        WHERE product_id = :product_id
        ORDER BY created_at DESC
        LIMIT 10
    """)
    
    result = db.session.execute(sql, {"product_id": id})
    
    # Create StockMovement-like objects with dictionary access for the template
    class MovementDict(dict):
        def __getattr__(self, key):
            return self.get(key)
    
    stock_movements = []
    for row in result:
        movement = MovementDict({
            'id': row.id,
            'product_id': row.product_id,
            'qty_delta': row.qty_delta,
            'reason_code': row.reason_code,  # This will be a string, not an enum
            'note': row.note,
            'channel': row.channel,
            'reference_id': row.reference_id,
            'user_id': row.user_id,
            'created_at': row.created_at,
            'updated_at': row.updated_at
        })
        stock_movements.append(movement)
    
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


@bp.route("/products/import-file", methods=["POST"])
@login_required
def product_import_file():
    """Import products from file (CSV, Excel, etc.)."""
    if 'csv_file' not in request.files:
        flash("Nėra pasirinktas failas", "error")
        return redirect(url_for('main.products'))
    
    file = request.files['csv_file']
    if file.filename == '':
        flash("Nėra pasirinktas failas", "error")
        return redirect(url_for('main.products'))
    
    # Get file extension
    file_ext = file.filename.rsplit('.', 1)[1].lower() if '.' in file.filename else ''
    
    # Check allowed extensions
    allowed_extensions = {'csv', 'xlsx', 'xls', 'tsv', 'txt'}
    if file_ext not in allowed_extensions:
        flash(f"Nepalaikomas failo formatas. Naudokite: {', '.join(allowed_extensions)}", "error")
        return redirect(url_for('main.products'))
    
    try:
        # Get form parameters for text files
        encoding = request.form.get('encoding', '')
        delimiter = request.form.get('delimiter', ',')
        has_header = 'has_header' in request.form
        
        # Fix tab delimiter if needed
        if delimiter == '\\t':
            delimiter = '\t'
        
        # Use our improved import service
        from lt_crm.app.services.import_service import import_products
        
        # Import the products directly - this function handles parsing internally
        result = import_products(
            file_obj=file,
            channel="web",
            reference_id=None,
            user_id=current_user.id,
            encoding=encoding or None,
            delimiter=delimiter,
            has_header=has_header
        )
        
        # Show success message
        flash(f"Sėkmingai importuota: {result.get('created', 0)} sukurta, {result.get('updated', 0)} atnaujinta, {result.get('skipped', 0)} praleista", "success")
        
    except ValueError as e:
        flash(f"Klaida importuojant: {str(e)}", "error")
    except Exception as e:
        current_app.logger.exception("Error importing products")
        flash(f"Klaida importuojant produktus: {str(e)}", "error")
    
    return redirect(url_for('main.products'))


@bp.route("/orders/new", methods=["GET", "POST"])
@login_required
def order_new():
    """Create a new order."""
    if request.method == "POST":
        try:
            # Get form data
            source = request.form.get("source")
            status = request.form.get("status")
            shipping_name = request.form.get("shipping_name")
            shipping_email = request.form.get("shipping_email")
            shipping_phone = request.form.get("shipping_phone")
            shipping_address = request.form.get("shipping_address")
            shipping_city = request.form.get("shipping_city")
            shipping_postal_code = request.form.get("shipping_postal_code")
            shipping_country = request.form.get("shipping_country")
            shipping_notes = request.form.get("shipping_notes")
            shipping_method = request.form.get("shipping_method")
            shipping_amount = request.form.get("shipping_amount", type=float, default=0)
            tax_amount = request.form.get("tax_amount", type=float, default=0)
            
            # Get product IDs, prices, and quantities
            product_ids = request.form.getlist("product_ids[]")
            prices = request.form.getlist("prices[]")
            quantities = request.form.getlist("quantities[]")
            
            # Validate that there's at least one product
            if not product_ids or not prices or not quantities or len(product_ids) == 0:
                flash("You must add at least one product to the order", "error")
                products = Product.query.order_by(Product.name).all()
                return render_template("main/order_form.html", title="Naujas užsakymas", products=products)
            
            # Calculate total amount
            total_amount = sum(float(prices[i]) * int(quantities[i]) for i in range(len(product_ids)) if product_ids[i])
            total_amount += shipping_amount + tax_amount
            
            # Generate order number (format: ORD-00001)
            last_order = Order.query.order_by(Order.id.desc()).first()
            order_num = 1
            if last_order and last_order.order_number:
                try:
                    # Extract the numeric part of the last order number
                    order_num = int(last_order.order_number.split('-')[-1]) + 1
                except (ValueError, IndexError):
                    order_num = 1
            
            order_number = f"ORD-{order_num:05d}"
            
            # Create customer if needed (based on email)
            customer = None
            if shipping_email:
                customer = Customer.query.filter_by(email=shipping_email).first()
                if not customer:
                    customer = Customer(
                        name=shipping_name,
                        email=shipping_email,
                        phone=shipping_phone,
                        address=shipping_address,
                        city=shipping_city,
                        country=shipping_country
                    )
                    db.session.add(customer)
                    db.session.flush()  # Get ID without committing
            
            # Create the order
            new_order = Order(
                order_number=order_number,
                customer_id=customer.id if customer else None,
                status=OrderStatus(status),
                total_amount=total_amount,
                tax_amount=tax_amount,
                shipping_amount=shipping_amount,
                shipping_name=shipping_name,
                shipping_email=shipping_email,
                shipping_phone=shipping_phone,
                shipping_address=shipping_address,
                shipping_city=shipping_city,
                shipping_postal_code=shipping_postal_code,
                shipping_country=shipping_country,
                shipping_method=shipping_method,
                notes=shipping_notes
            )
            
            db.session.add(new_order)
            db.session.flush()  # Get the order ID without committing
            
            # Create order items
            for i in range(len(product_ids)):
                if not product_ids[i]:  # Skip empty rows
                    continue
                
                product_id = int(product_ids[i])
                price = float(prices[i])
                quantity = int(quantities[i])
                
                order_item = OrderItem(
                    order_id=new_order.id,
                    product_id=product_id,
                    quantity=quantity,
                    price=price
                )
                db.session.add(order_item)
            
            db.session.commit()
            
            # Process inventory changes if order is created with a special status (not NEW)
            # This ensures stock movements are created when an order is created with SHIPPED status
            if new_order.status != OrderStatus.NEW:
                from lt_crm.app.services.inventory import process_order_stock_changes
                try:
                    movements = process_order_stock_changes(new_order, None)
                    current_app.logger.info(f"Created {len(movements)} stock movements for new order {new_order.id}")
                except Exception as e:
                    current_app.logger.warning(f"Error processing stock changes for new order {new_order.id}: {str(e)}")
            
            flash(f"Order {order_number} created successfully", "success")
            return redirect(url_for('main.order_detail', id=new_order.id))
            
        except Exception as e:
            db.session.rollback()
            flash(f"Error creating order: {str(e)}", "error")
            products = Product.query.order_by(Product.name).all()
            return render_template("main/order_form.html", title="Naujas užsakymas", products=products)
    
    # Get all active products for the order form
    products = Product.query.order_by(Product.name).all()
    
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
    current_app.logger.info(f"Updating order {id} status...")
    
    try:
        status = request.form.get("status")
        current_app.logger.info(f"Requested status update for order {id}: {status}")
        
        if not status or status not in [e.value for e in OrderStatus]:
            current_app.logger.error(f"Invalid status '{status}' for order {id}")
            return jsonify({"error": f"Invalid status: {status}"}), 400
        
        # Store old status for comparison
        old_status = order.status
        
        # Update the status
        order.status = OrderStatus(status)
        
        # If status is shipped, set shipped_at date
        if order.status == OrderStatus.SHIPPED and not order.shipped_at:
            order.shipped_at = datetime.now()
        
        # Save the status change
        db.session.commit()
        
        # Debug log
        current_app.logger.info(f"Order {order.id} status updated from {old_status} to {order.status}")
        
        # Process inventory changes based on status
        from lt_crm.app.services.inventory import process_order_stock_changes
        
        try:
            movements = process_order_stock_changes(order, old_status)
            current_app.logger.info(f"Created {len(movements)} stock movements for order {order.id}")
            
            # Return information about the movements
            return jsonify({
                "message": "Status updated successfully",
                "movements_created": len(movements),
                "new_status": order.status.value
            }), 200
            
        except Exception as e:
            current_app.logger.error(f"Error processing order inventory changes: {str(e)}")
            # We don't roll back the status change even if inventory processing failed
            return jsonify({
                "message": "Status updated but inventory processing failed",
                "error": str(e),
                "new_status": order.status.value
            }), 500
            
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error updating order status: {str(e)}")
        return jsonify({"error": str(e)}), 500


@bp.route("/customers/<int:id>")
@login_required
def customer_detail(id):
    """Customer detail page."""
    customer = Customer.query.get_or_404(id)
    
    # Get related contacts
    contacts = Contact.query.filter_by(customer_id=id).all()
    
    # Get related tasks
    tasks = Task.query.filter_by(customer_id=id).order_by(Task.due_date).all()
    
    # Get customer's orders
    orders = Order.query.filter_by(customer_id=id).order_by(Order.created_at.desc()).all()
    
    # Get customer's invoices
    invoices = Invoice.query.filter_by(customer_id=id).order_by(Invoice.created_at.desc()).all()
    
    return render_template(
        "main/customer_detail.html",
        title=f"Klientas: {customer.name}",
        customer=customer,
        contacts=contacts,
        tasks=tasks,
        orders=orders,
        invoices=invoices,
        now=datetime.now()
    )


@bp.route("/invoices/new-from-order/<int:order_id>")
@login_required
def invoice_new_from_order(order_id):
    """Create a new invoice from an order."""
    order = Order.query.get_or_404(order_id)
    
    current_app.logger.info(f"Creating invoice for order ID: {order_id}, Number: {order.order_number}")
    
    # Check if invoice already exists for this order
    existing_invoice = Invoice.query.filter_by(order_id=order_id).first()
    if existing_invoice:
        current_app.logger.warning(f"Invoice {existing_invoice.invoice_number} already exists for order ID: {order_id}")
        flash(f"Sąskaita faktūra #{existing_invoice.invoice_number} jau sukurta užsakymui #{order.order_number} (ID: {order_id})", "info")
        return redirect(url_for('main.invoice_detail', id=existing_invoice.id))
    
    try:
        # Generate invoice number (format: LT-INV-00001)
        last_invoice = Invoice.query.order_by(Invoice.id.desc()).first()
        invoice_num = 1
        if last_invoice and last_invoice.invoice_number:
            try:
                # Extract the numeric part of the last invoice number
                current_app.logger.info(f"Last invoice number: {last_invoice.invoice_number}")
                parts = last_invoice.invoice_number.split('-')
                if len(parts) >= 3:
                    invoice_num = int(parts[-1]) + 1
                else:
                    current_app.logger.warning(f"Invalid invoice number format: {last_invoice.invoice_number}")
            except (ValueError, IndexError) as e:
                current_app.logger.error(f"Error parsing invoice number: {str(e)}")
                invoice_num = 1
        
        invoice_number = f"LT-INV-{invoice_num:05d}"
        current_app.logger.info(f"Generated new invoice number: {invoice_number}")
        
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
            notes=f"Sąskaita faktūra sukurta iš užsakymo {order.order_number}"
        )
        
        db.session.add(new_invoice)
        db.session.flush()  # Get the invoice ID without committing
        
        # Copy order items to invoice items
        order_items = OrderItem.query.filter_by(order_id=order_id).all()
        current_app.logger.info(f"Found {len(order_items)} order items to copy to invoice")
        
        for order_item in order_items:
            # Get product details if available
            product_name = ""
            if order_item.product:
                product_name = order_item.product.name
            
            # Create invoice item
            invoice_item = InvoiceItem(
                invoice_id=new_invoice.id,
                product_id=order_item.product_id,
                description=product_name if product_name else f"Item from order {order.order_number}",
                quantity=order_item.quantity,
                price=order_item.price,
                tax_rate=order_item.tax_rate if order_item.tax_rate else 0,
                subtotal=order_item.subtotal
            )
            db.session.add(invoice_item)
            current_app.logger.info(f"Added invoice item for product ID: {order_item.product_id}, quantity: {order_item.quantity}")
        
        db.session.commit()
        
        current_app.logger.info(f"Invoice {invoice_number} created successfully with {len(order_items)} items")
        flash(f"Sąskaita faktūra {invoice_number} sėkmingai sukurta", "success")
        return redirect(url_for('main.invoice_detail', id=new_invoice.id))
    except Exception as e:
        db.session.rollback()
        current_app.logger.exception(f"Error creating invoice: {str(e)}")
        flash(f"Klaida kuriant sąskaitą faktūrą: {str(e)}", "error")
        return redirect(url_for('main.order_detail', id=order_id))


@bp.route("/invoices/new", methods=["GET", "POST"])
@login_required
def invoice_new():
    """Create a new invoice."""
    if request.method == "POST":
        try:
            # Get form data
            invoice_number = request.form.get("invoice_number")
            customer_id = request.form.get("customer_id")
            status = request.form.get("status", InvoiceStatus.DRAFT.value)
            issue_date_str = request.form.get("issue_date")
            due_date_str = request.form.get("due_date")
            
            # Process dates
            issue_date = None
            if issue_date_str:
                try:
                    issue_date = datetime.strptime(issue_date_str, "%Y-%m-%d").date()
                except ValueError:
                    flash("Invalid issue date format. Use YYYY-MM-DD.", "error")
                    return redirect(url_for("main.invoice_new"))
            
            due_date = None
            if due_date_str:
                try:
                    due_date = datetime.strptime(due_date_str, "%Y-%m-%d").date()
                except ValueError:
                    flash("Invalid due date format. Use YYYY-MM-DD.", "error")
                    return redirect(url_for("main.invoice_new"))
            
            # Get item data from form
            product_ids = request.form.getlist("product_ids[]")
            item_descriptions = request.form.getlist("item_descriptions[]")
            item_quantities = request.form.getlist("item_quantities[]")
            item_prices = request.form.getlist("item_prices[]")
            item_tax_rates = request.form.getlist("item_tax_rates[]")
            
            # Calculate totals
            subtotal = 0
            tax_amount = 0
            
            for i in range(len(item_descriptions)):
                if not item_descriptions[i]:  # Skip empty items
                    continue
                
                quantity = int(item_quantities[i]) if item_quantities[i] else 1
                price = float(item_prices[i]) if item_prices[i] else 0
                tax_rate = float(item_tax_rates[i]) if item_tax_rates[i] else 0
                
                item_subtotal = quantity * price
                item_tax = item_subtotal * (tax_rate / 100)
                
                subtotal += item_subtotal
                tax_amount += item_tax
            
            total_amount = subtotal + tax_amount
            
            # Get billing information
            billing_name = request.form.get("billing_name")
            billing_address = request.form.get("billing_address")
            billing_city = request.form.get("billing_city")
            billing_postal_code = request.form.get("billing_postal_code")
            billing_country = request.form.get("billing_country")
            billing_email = request.form.get("billing_email")
            company_code = request.form.get("company_code")
            vat_code = request.form.get("vat_code")
            payment_details = request.form.get("payment_details")
            notes = request.form.get("notes")
            
            # Create new invoice
            new_invoice = Invoice(
                invoice_number=invoice_number,
                customer_id=customer_id if customer_id else None,
                status=InvoiceStatus(status),
                issue_date=issue_date,
                due_date=due_date,
                subtotal_amount=subtotal,
                tax_amount=tax_amount,
                total_amount=total_amount,
                billing_name=billing_name,
                billing_address=billing_address,
                billing_city=billing_city,
                billing_postal_code=billing_postal_code,
                billing_country=billing_country,
                billing_email=billing_email,
                company_code=company_code,
                vat_code=vat_code,
                payment_details=payment_details,
                notes=notes
            )
            
            db.session.add(new_invoice)
            db.session.flush()  # Get the invoice ID
            
            # Add invoice items
            for i in range(len(item_descriptions)):
                if not item_descriptions[i]:  # Skip empty items
                    continue
                
                quantity = int(item_quantities[i]) if item_quantities[i] else 1
                price = float(item_prices[i]) if item_prices[i] else 0
                tax_rate = float(item_tax_rates[i]) if item_tax_rates[i] else 0
                
                item_subtotal = quantity * price
                
                # Create invoice item using SQLAlchemy class from models
                from lt_crm.app.models.invoice import InvoiceItem
                
                # Get product_id if available
                product_id = int(product_ids[i]) if product_ids[i] else None
                
                invoice_item = InvoiceItem(
                    invoice_id=new_invoice.id,
                    product_id=product_id,
                    description=item_descriptions[i],
                    quantity=quantity,
                    price=price,
                    tax_rate=tax_rate,
                    subtotal=item_subtotal
                )
                db.session.add(invoice_item)
            
            db.session.commit()
            flash(f"Invoice {invoice_number} created successfully", "success")
            return redirect(url_for("main.invoice_detail", id=new_invoice.id))
        except Exception as e:
            db.session.rollback()
            flash(f"Error creating invoice: {str(e)}", "error")
            customers = Customer.query.order_by(Customer.name).all()
            return render_template(
                "main/invoice_form.html",
                title="Nauja sąskaita faktūra",
                customers=customers
            )
    
    # Get all customers for the invoice form
    customers = Customer.query.order_by(Customer.name).all()
    
    # Generate next invoice number (format: LT-INV-00001)
    last_invoice = Invoice.query.order_by(Invoice.id.desc()).first()
    invoice_num = 1
    if last_invoice and last_invoice.invoice_number:
        try:
            # Extract the numeric part of the last invoice number
            invoice_num = int(last_invoice.invoice_number.split('-')[-1]) + 1
        except (ValueError, IndexError):
            invoice_num = 1
    
    invoice_number = f"LT-INV-{invoice_num:05d}"
    
    # Calculate default due date (14 days from today)
    today = datetime.now().date()
    due_date = today + timedelta(days=14)
    
    return render_template(
        "main/invoice_form.html",
        title="Nauja sąskaita faktūra",
        customers=customers,
        invoice_number=invoice_number,
        issue_date=today.strftime("%Y-%m-%d"),
        due_date=due_date.strftime("%Y-%m-%d")
    )


@bp.route("/invoices/<int:id>/edit", methods=["GET", "POST"])
@login_required
def invoice_edit(id):
    """Edit an existing invoice."""
    invoice = Invoice.query.get_or_404(id)
    
    # Only draft invoices can be edited
    if invoice.status != InvoiceStatus.DRAFT:
        flash("Tik juodraščio būsenos sąskaitos gali būti redaguojamos.", "error")
        return redirect(url_for("main.invoice_detail", id=invoice.id))
    
    # Manually load the items with their products to avoid the dynamic loading issue
    invoice_items = InvoiceItem.query.filter_by(invoice_id=id).options(
        db.joinedload(InvoiceItem.product)
    ).all()
    
    # Debug logging
    current_app.logger.info(f"Invoice Edit {id}: Found {len(invoice_items)} items")
    for idx, item in enumerate(invoice_items):
        current_app.logger.info(f"Edit Item {idx+1}: product_id={item.product_id}, has_product={item.product is not None}, description={item.description}")
    
    if request.method == "POST":
        try:
            # Get form data
            invoice_number = request.form.get("invoice_number")
            customer_id = request.form.get("customer_id")
            status = request.form.get("status", InvoiceStatus.DRAFT.value)
            issue_date_str = request.form.get("issue_date")
            due_date_str = request.form.get("due_date")
            
            # Process dates
            issue_date = None
            if issue_date_str:
                try:
                    issue_date = datetime.strptime(issue_date_str, "%Y-%m-%d").date()
                except ValueError:
                    flash("Invalid issue date format. Use YYYY-MM-DD.", "error")
                    return redirect(url_for("main.invoice_edit", id=invoice.id))
            
            due_date = None
            if due_date_str:
                try:
                    due_date = datetime.strptime(due_date_str, "%Y-%m-%d").date()
                except ValueError:
                    flash("Invalid due date format. Use YYYY-MM-DD.", "error")
                    return redirect(url_for("main.invoice_edit", id=invoice.id))
            
            # Get item data from form
            product_ids = request.form.getlist("product_ids[]")
            item_descriptions = request.form.getlist("item_descriptions[]")
            item_quantities = request.form.getlist("item_quantities[]")
            item_prices = request.form.getlist("item_prices[]")
            item_tax_rates = request.form.getlist("item_tax_rates[]")
            
            # Calculate totals
            subtotal = 0
            tax_amount = 0
            
            for i in range(len(item_descriptions)):
                if not item_descriptions[i]:  # Skip empty items
                    continue
                
                quantity = int(item_quantities[i]) if item_quantities[i] else 1
                price = float(item_prices[i]) if item_prices[i] else 0
                tax_rate = float(item_tax_rates[i]) if item_tax_rates[i] else 0
                
                item_subtotal = quantity * price
                item_tax = item_subtotal * (tax_rate / 100)
                
                subtotal += item_subtotal
                tax_amount += item_tax
            
            total_amount = subtotal + tax_amount
            
            # Get billing information
            billing_name = request.form.get("billing_name")
            billing_address = request.form.get("billing_address")
            billing_city = request.form.get("billing_city")
            billing_postal_code = request.form.get("billing_postal_code")
            billing_country = request.form.get("billing_country")
            billing_email = request.form.get("billing_email")
            company_code = request.form.get("company_code")
            vat_code = request.form.get("vat_code")
            payment_details = request.form.get("payment_details")
            notes = request.form.get("notes")
            
            # Update invoice
            invoice.invoice_number = invoice_number
            invoice.customer_id = customer_id if customer_id else None
            invoice.status = InvoiceStatus(status)
            invoice.issue_date = issue_date
            invoice.due_date = due_date
            invoice.subtotal_amount = subtotal
            invoice.tax_amount = tax_amount
            invoice.total_amount = total_amount
            invoice.billing_name = billing_name
            invoice.billing_address = billing_address
            invoice.billing_city = billing_city
            invoice.billing_postal_code = billing_postal_code
            invoice.billing_country = billing_country
            invoice.billing_email = billing_email
            invoice.company_code = company_code
            invoice.vat_code = vat_code
            invoice.payment_details = payment_details
            invoice.notes = notes
            
            # Delete existing items
            InvoiceItem.query.filter_by(invoice_id=invoice.id).delete()
            
            # Add updated invoice items
            for i in range(len(item_descriptions)):
                if not item_descriptions[i]:  # Skip empty items
                    continue
                
                quantity = int(item_quantities[i]) if item_quantities[i] else 1
                price = float(item_prices[i]) if item_prices[i] else 0
                tax_rate = float(item_tax_rates[i]) if item_tax_rates[i] else 0
                
                item_subtotal = quantity * price
                
                # Get product_id if available
                product_id = int(product_ids[i]) if product_ids[i] else None
                
                # Create invoice item
                invoice_item = InvoiceItem(
                    invoice_id=invoice.id,
                    product_id=product_id,
                    description=item_descriptions[i],
                    quantity=quantity,
                    price=price,
                    tax_rate=tax_rate,
                    subtotal=item_subtotal
                )
                db.session.add(invoice_item)
            
            db.session.commit()
            flash(f"Sąskaita {invoice_number} atnaujinta sėkmingai", "success")
            return redirect(url_for("main.invoice_detail", id=invoice.id))
        except Exception as e:
            db.session.rollback()
            flash(f"Klaida atnaujinant sąskaitą: {str(e)}", "error")
            customers = Customer.query.order_by(Customer.name).all()
            return render_template(
                "main/invoice_form.html",
                title="Redaguoti sąskaitą faktūrą",
                invoice=invoice,
                invoice_items=invoice_items,
                customers=customers,
                edit_mode=True
            )
    
    # Get all customers for the invoice form
    customers = Customer.query.order_by(Customer.name).all()
    
    return render_template(
        "main/invoice_form.html",
        title="Redaguoti sąskaitą faktūrą",
        invoice=invoice,
        invoice_items=invoice_items,
        customers=customers,
        edit_mode=True,
        issue_date=invoice.issue_date.strftime("%Y-%m-%d") if invoice.issue_date else "",
        due_date=invoice.due_date.strftime("%Y-%m-%d") if invoice.due_date else ""
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
        
        # Return the updated status HTML for HTMX to update
        status_html = f"""
        <span id="invoice-status" class="badge badge-info">
            Išrašyta
        </span>
        """
        
        return status_html
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500 


@bp.route("/api/products/search")
@login_required
def product_search_api():
    """Search products API for dropdowns."""
    query = request.args.get('q', '')
    limit = request.args.get('limit', 10, type=int)
    
    # Search products by name, SKU, or barcode
    if query:
        products = Product.query.filter(
            (Product.name.ilike(f'%{query}%')) | 
            (Product.sku.ilike(f'%{query}%')) | 
            (Product.barcode.ilike(f'%{query}%'))
        ).limit(limit).all()
    else:
        products = Product.query.order_by(Product.name).limit(limit).all()
    
    # Format products for select2 dropdown
    results = [{
        'id': product.id,
        'text': f"{product.name} ({product.sku})",
        'sku': product.sku,
        'price': float(product.price_final),
        'description': product.name
    } for product in products]
    
    return jsonify({
        'results': results
    }) 


@bp.route("/shipments")
@login_required
def shipments():
    """Display list of shipments."""
    try:
        # Get page and search parameters
        page = request.args.get("page", 1, type=int)
        q = request.args.get("q", "")
        status = request.args.get("status", "")
        
        # Query shipments
        query = Shipment.query
        
        # Apply filters
        if q:
            query = query.filter(Shipment.shipment_number.ilike(f"%{q}%") | 
                                Shipment.supplier.ilike(f"%{q}%"))
        
        if status:
            query = query.filter(Shipment.status == ShipmentStatus(status))
        
        # Order and paginate
        query = query.order_by(Shipment.created_at.desc())
        per_page = 20  # Set a hardcoded per_page value
        pagination = query.paginate(page=page, per_page=per_page)
        shipments = pagination.items
        
        return render_template(
            "main/shipments.html",
            shipments=shipments,
            pagination=pagination,
            ShipmentStatus=ShipmentStatus,
        )
    except Exception as e:
        # Log the error
        current_app.logger.error(f"Error in shipments route: {str(e)}")
        # Rollback the session
        db.session.rollback()
        # Show error message
        flash(f"An error occurred while loading shipments: {str(e)}", "error")
        # Return empty list
        return render_template(
            "main/shipments.html",
            shipments=[],
            pagination=None,
            ShipmentStatus=ShipmentStatus,
        )


@bp.route("/shipments/new", methods=["GET", "POST"])
@login_required
def shipment_new():
    """Create a new shipment."""
    form = ShipmentForm()
    
    if form.validate_on_submit():
        # Generate shipment number if not provided
        if not form.shipment_number.data:
            last_shipment = Shipment.query.order_by(Shipment.id.desc()).first()
            shipment_num = 1
            if last_shipment and last_shipment.shipment_number:
                try:
                    # Extract the numeric part of the last shipment number
                    shipment_num = int(last_shipment.shipment_number.split('-')[-1]) + 1
                except (ValueError, IndexError):
                    shipment_num = 1
            
            form.shipment_number.data = f"SHIP-{shipment_num:05d}"
        
        # Create the shipment
        shipment = Shipment(
            shipment_number=form.shipment_number.data,
            supplier=form.supplier.data,
            expected_date=form.expected_date.data,
            notes=form.notes.data,
            status=ShipmentStatus(form.status.data),
            user_id=current_user.id
        )
        
        db.session.add(shipment)
        db.session.commit()
        
        flash(f"Siunta {shipment.shipment_number} sėkmingai sukurta", "success")
        return redirect(url_for('main.shipment_edit', id=shipment.id))
    
    return render_template(
        "main/shipment_form.html",
        title="Nauja siunta",
        form=form,
        shipment=None,
        ShipmentStatus=ShipmentStatus
    )


@bp.route("/shipments/<int:id>", methods=["GET"])
@login_required
def shipment_detail(id):
    """Shipment detail page."""
    shipment = Shipment.query.get_or_404(id)
    
    return render_template(
        "main/shipment_detail.html",
        title=f"Siunta {shipment.shipment_number}",
        shipment=shipment,
        ShipmentStatus=ShipmentStatus
    )


@bp.route("/shipments/<int:id>/edit", methods=["GET", "POST"])
@login_required
def shipment_edit(id):
    """Edit shipment page."""
    shipment = Shipment.query.get_or_404(id)
    form = ShipmentForm(obj=shipment)
    
    if form.validate_on_submit():
        # Update shipment data
        form.populate_obj(shipment)
        shipment.status = ShipmentStatus(form.status.data)
        
        db.session.add(shipment)
        db.session.commit()
        
        flash(f"Siunta {shipment.shipment_number} sėkmingai atnaujinta", "success")
        return redirect(url_for('main.shipment_detail', id=shipment.id))
    
    # Get items for this shipment
    items = ShipmentItem.query.filter_by(shipment_id=id).all()
    
    return render_template(
        "main/shipment_form.html",
        title=f"Redaguoti siuntą {shipment.shipment_number}",
        form=form,
        shipment=shipment,
        items=items,
        ShipmentStatus=ShipmentStatus
    )


@bp.route("/shipments/<int:id>/add-item", methods=["POST"])
@login_required
def shipment_add_item(id):
    """Add an item to a shipment."""
    shipment = Shipment.query.get_or_404(id)
    
    # Check if we can modify the shipment
    if shipment.status == ShipmentStatus.RECEIVED:
        flash("Negalima keisti jau gautos siuntos", "error")
        return redirect(url_for('main.shipment_detail', id=shipment.id))
    
    # Get product info
    product_id = request.form.get('product_id')
    if not product_id:
        flash("Nepasirinktas produktas", "error")
        return redirect(url_for('main.shipment_edit', id=shipment.id))
    
    product = Product.query.get(product_id)
    if not product:
        flash("Produktas nerastas", "error")
        return redirect(url_for('main.shipment_edit', id=shipment.id))
    
    # Create shipment item
    quantity = request.form.get('quantity', type=int, default=1)
    cost_price = request.form.get('cost_price', type=float)
    notes = request.form.get('notes')
    
    item = ShipmentItem(
        shipment_id=shipment.id,
        product_id=product.id,
        quantity=quantity,
        cost_price=cost_price,
        notes=notes
    )
    
    db.session.add(item)
    db.session.commit()
    
    flash(f"Produktas {product.name} pridėtas į siuntą", "success")
    return redirect(url_for('main.shipment_edit', id=shipment.id))


@bp.route("/shipments/<int:id>/remove-item/<int:item_id>", methods=["DELETE"])
@login_required
def shipment_remove_item(id, item_id):
    """Remove an item from a shipment."""
    shipment = Shipment.query.get_or_404(id)
    item = ShipmentItem.query.get_or_404(item_id)
    
    # Check if the item belongs to this shipment
    if item.shipment_id != shipment.id:
        return jsonify({"error": "Item does not belong to this shipment"}), 400
    
    # Check if we can modify the shipment
    if shipment.status == ShipmentStatus.RECEIVED:
        return jsonify({"error": "Cannot modify a received shipment"}), 400
    
    try:
        db.session.delete(item)
        db.session.commit()
        return "", 204  # No content, successful deletion
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@bp.route("/shipments/<int:id>/receive", methods=["PUT"])
@login_required
def shipment_receive(id):
    """Mark a shipment as received and update stock levels."""
    shipment = Shipment.query.get_or_404(id)
    
    # Check if shipment is already received
    if shipment.status == ShipmentStatus.RECEIVED:
        return jsonify({"error": "Shipment is already received"}), 400
    
    # Check if shipment has items
    if shipment.shipment_items.count() == 0:
        return jsonify({"error": "Shipment has no items"}), 400
    
    try:
        # Process the shipment arrival
        shipment.receive_shipment()
        db.session.commit()
        
        return jsonify({
            "message": "Shipment received successfully",
            "status": shipment.status.value,
            "arrival_date": shipment.arrival_date.strftime('%Y-%m-%d') if shipment.arrival_date else None
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500 


@bp.route("/settings", methods=["GET", "POST"])
@login_required
def settings():
    """Settings page."""
    # All users can access company information settings
    
    # Get company settings
    settings = CompanySettings.get_instance()
    form = CompanySettingsForm(obj=settings)
    
    if request.method == "POST" and form.validate_on_submit():
        # Only allow admin users to update settings
        if not current_user.is_admin:
            flash("Jūs neturite teisių atnaujinti nustatymus. Tik peržiūrėti.", "error")
            return redirect(url_for("main.settings"))
            
        # Update settings
        form.populate_obj(settings)
        db.session.commit()
        
        flash("Nustatymai sėkmingai atnaujinti", "success")
        return redirect(url_for("main.settings"))
    
    return render_template(
        "main/settings.html",
        title="Nustatymai",
        settings=settings,
        form=form,
        is_admin=current_user.is_admin
    )


@bp.route("/orders/<int:id>/edit", methods=["GET", "POST"])
@login_required
def order_edit(id):
    """Edit an existing order."""
    order = Order.query.get_or_404(id)
    
    if request.method == "POST":
        try:
            # Get form data
            shipping_name = request.form.get("shipping_name")
            shipping_email = request.form.get("shipping_email")
            shipping_phone = request.form.get("shipping_phone")
            shipping_address = request.form.get("shipping_address")
            shipping_city = request.form.get("shipping_city")
            shipping_postal_code = request.form.get("shipping_postal_code")
            shipping_country = request.form.get("shipping_country")
            shipping_notes = request.form.get("shipping_notes")
            shipping_method = request.form.get("shipping_method")
            payment_method = request.form.get("payment_method")
            tracking_number = request.form.get("tracking_number")
            status = request.form.get("status")
            
            # Store old status for comparison if status is being changed
            old_status = order.status
            status_changed = status and status != old_status.value
            
            # Update order data
            order.shipping_name = shipping_name
            order.shipping_email = shipping_email
            order.shipping_phone = shipping_phone
            order.shipping_address = shipping_address
            order.shipping_city = shipping_city
            order.shipping_postal_code = shipping_postal_code
            order.shipping_country = shipping_country
            order.shipping_method = shipping_method
            order.notes = shipping_notes
            order.payment_method = payment_method
            order.tracking_number = tracking_number
            
            # Update status if provided and different
            if status_changed:
                order.status = OrderStatus(status)
                
                # If status is shipped, set shipped_at date
                if order.status == OrderStatus.SHIPPED and not order.shipped_at:
                    order.shipped_at = datetime.now()
            
            # Save changes
            db.session.commit()
            
            # Process stock changes if status changed
            if status_changed:
                from lt_crm.app.services.inventory import process_order_stock_changes
                try:
                    movements = process_order_stock_changes(order, old_status)
                    current_app.logger.info(f"Created {len(movements)} stock movements for order {order.id} status change")
                except Exception as e:
                    current_app.logger.warning(f"Error processing stock changes for order {order.id}: {str(e)}")
            
            flash(f"Užsakymas {order.order_number} sėkmingai atnaujintas", "success")
            return redirect(url_for('main.order_detail', id=order.id))
            
        except Exception as e:
            db.session.rollback()
            flash(f"Klaida atnaujinant užsakymą: {str(e)}", "error")
    
    # Get all active products for the order form
    products = Product.query.order_by(Product.name).all()
    
    return render_template(
        "main/order_edit.html",
        title=f"Redaguoti užsakymą {order.order_number}",
        order=order,
        products=products
    )


@bp.route("/customers")
@login_required
def customers():
    """Customers list page."""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = 20
        
        # Base query
        query = Customer.query
        
        # Apply filters
        if request.args.get('q'):
            search = f"%{request.args.get('q')}%"
            query = query.filter(
                (Customer.name.ilike(search)) | 
                (Customer.email.ilike(search)) | 
                (Customer.phone.ilike(search))
            )
        
        # Execute query with pagination
        pagination = query.order_by(Customer.name).paginate(page=page, per_page=per_page)
        customers = pagination.items
        
        return render_template(
            "main/customers.html",
            title="Klientai",
            customers=customers,
            pagination=pagination
        )
    except Exception as e:
        # Log the error
        current_app.logger.error(f"Error in customers route: {str(e)}")
        # Rollback the session
        db.session.rollback()
        # Show error message
        flash(f"Įvyko klaida gaunant klientų sąrašą: {str(e)}", "error")
        # Return empty list
        return render_template(
            "main/customers.html",
            title="Klientai",
            customers=[],
            pagination=None
        )


@bp.route("/orders/<int:id>/delete", methods=["DELETE"])
@login_required
def order_delete(id):
    """Delete an order."""
    order = Order.query.get_or_404(id)
    
    try:
        # Check if order has associated invoices first
        invoices = Invoice.query.filter_by(order_id=id).all()
        if invoices:
            return jsonify({
                "success": False,
                "message": "Negalima ištrinti užsakymo, nes jam priskirtos sąskaitos faktūros. Pirmiausia ištrinkite sąskaitas."
            }), 400
        
        # Get order number for the success message
        order_number = order.order_number
        
        # Delete order items first (due to foreign key constraint)
        OrderItem.query.filter_by(order_id=id).delete()
        
        # Delete the order
        db.session.delete(order)
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": f"Užsakymas {order_number} sėkmingai ištrintas"
        }), 200
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting order: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Klaida trinant užsakymą: {str(e)}"
        }), 500 


@bp.route("/invoices/<int:id>/delete", methods=["DELETE"])
@login_required
def invoice_delete(id):
    """Delete an invoice."""
    invoice = Invoice.query.get_or_404(id)
    
    try:
        # Only allow deletion of draft invoices
        if invoice.status != InvoiceStatus.DRAFT:
            return jsonify({
                "success": False,
                "message": "Negalima ištrinti išrašytos arba apmokėtos sąskaitos faktūros. Tik juodraštis gali būti ištrintas."
            }), 400
        
        # Get invoice number for the success message
        invoice_number = invoice.invoice_number
        
        # Delete invoice items first (due to foreign key constraint)
        InvoiceItem.query.filter_by(invoice_id=id).delete()
        
        # Delete the invoice
        db.session.delete(invoice)
        db.session.commit()
        
        return jsonify({
            "success": True,
            "message": f"Sąskaita faktūra {invoice_number} sėkmingai ištrinta"
        }), 200
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error deleting invoice: {str(e)}")
        return jsonify({
            "success": False,
            "message": f"Klaida trinant sąskaitą faktūrą: {str(e)}"
        }), 500 


@bp.route("/reports")
@login_required
def reports():
    """Reports dashboard page."""
    return render_template(
        "main/reports.html",
        title="Ataskaitos",
    )


@bp.route("/reports/sales-summary")
@login_required
def sales_summary_report():
    """Sales summary report."""
    # Get date range from request or default to current month
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    
    # Default to current month if no dates specified
    today = datetime.now().date()
    if not start_date_str:
        start_date = datetime(today.year, today.month, 1).date()
    else:
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        except ValueError:
            start_date = datetime(today.year, today.month, 1).date()
    
    if not end_date_str:
        # Last day of current month
        end_date = today
    else:
        try:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
        except ValueError:
            end_date = today
    
    # Get orders within the date range
    orders = Order.query.filter(
        func.date(Order.created_at) >= start_date,
        func.date(Order.created_at) <= end_date,
        Order.status != OrderStatus.CANCELLED
    ).all()
    
    # Calculate total sales
    total_sales = sum(order.total_amount for order in orders)
    
    # Calculate sales by status
    sales_by_status = {}
    for status in OrderStatus:
        status_orders = [order for order in orders if order.status == status]
        sales_by_status[status.name] = {
            'count': len(status_orders),
            'total': sum(order.total_amount for order in status_orders)
        }
    
    # Calculate sales by day
    sales_by_day = {}
    for order in orders:
        day = order.created_at.strftime('%Y-%m-%d')
        if day not in sales_by_day:
            sales_by_day[day] = {'count': 0, 'total': 0}
        sales_by_day[day]['count'] += 1
        sales_by_day[day]['total'] += order.total_amount
    
    # Sort days for chart display
    sorted_days = sorted(sales_by_day.keys())
    daily_sales_data = [float(sales_by_day[day]['total']) for day in sorted_days]
    
    # Calculate previous period for comparison
    date_diff = (end_date - start_date).days + 1
    prev_end_date = start_date - timedelta(days=1)
    prev_start_date = prev_end_date - timedelta(days=date_diff-1)
    
    # Get previous period orders
    prev_orders = Order.query.filter(
        func.date(Order.created_at) >= prev_start_date,
        func.date(Order.created_at) <= prev_end_date,
        Order.status != OrderStatus.CANCELLED
    ).all()
    
    prev_total_sales = sum(order.total_amount for order in prev_orders)
    
    # Calculate growth percentage
    if prev_total_sales > 0:
        growth_percentage = ((total_sales - prev_total_sales) / prev_total_sales) * 100
    else:
        growth_percentage = 100 if total_sales > 0 else 0
    
    # Get top selling products during this period
    product_sales = {}
    for order in orders:
        for item in order.items:
            if item.product_id not in product_sales:
                product_name = item.product.name if item.product else f"Product {item.product_id}"
                product_sales[item.product_id] = {
                    'name': product_name,
                    'quantity': 0,
                    'total': 0
                }
            product_sales[item.product_id]['quantity'] += item.quantity
            product_sales[item.product_id]['total'] += item.quantity * item.price
    
    # Sort products by sales amount
    top_products = sorted(
        product_sales.values(), 
        key=lambda x: x['total'], 
        reverse=True
    )[:10]  # Top 10 products
    
    # Get payment method distribution if available
    payment_methods = {}
    for order in orders:
        payment_method = order.payment_method or 'Unknown'
        if payment_method not in payment_methods:
            payment_methods[payment_method] = {'count': 0, 'total': 0}
        payment_methods[payment_method]['count'] += 1
        payment_methods[payment_method]['total'] += order.total_amount
    
    return render_template(
        "main/reports/sales_summary.html",
        title="Pardavimų ataskaita",
        start_date=start_date,
        end_date=end_date,
        total_sales=total_sales,
        orders_count=len(orders),
        sales_by_status=sales_by_status,
        sorted_days=sorted_days,
        daily_sales_data=daily_sales_data,
        prev_start_date=prev_start_date,
        prev_end_date=prev_end_date,
        prev_total_sales=prev_total_sales,
        growth_percentage=growth_percentage,
        top_products=top_products,
        payment_methods=payment_methods,
        avg_order_value=total_sales / len(orders) if orders else 0
    )


@bp.route("/reports/inventory-status")
@login_required
def inventory_status_report():
    """Inventory status report."""
    # Get filter parameters
    category = request.args.get('category')
    stock_filter = request.args.get('stock_status')
    
    # Base query
    query = Product.query
    
    # Apply filters
    if category:
        query = query.filter(Product.category == category)
    
    if stock_filter == 'low_stock':
        query = query.filter(Product.quantity > 0, Product.quantity <= 10)
    elif stock_filter == 'out_of_stock':
        query = query.filter(Product.quantity == 0)
    elif stock_filter == 'in_stock':
        query = query.filter(Product.quantity > 10)
    
    # Get products
    products = query.order_by(Product.category, Product.name).all()
    
    # Calculate inventory value
    total_inventory_value = sum(product.quantity * product.price_final for product in products)
    
    # Get categories for filter dropdown
    categories = db.session.query(Product.category).filter(Product.category.isnot(None)).distinct().all()
    categories = [c[0] for c in categories if c[0]]
    
    # Group products by category
    products_by_category = {}
    for product in products:
        category = product.category or 'Uncategorized'
        if category not in products_by_category:
            products_by_category[category] = []
        products_by_category[category].append(product)
    
    # Calculate category totals
    category_totals = {}
    for cat, prods in products_by_category.items():
        category_totals[cat] = {
            'count': len(prods),
            'value': sum(p.quantity * p.price_final for p in prods),
            'qty': sum(p.quantity for p in prods)
        }
    
    # Identify low stock products
    low_stock_products = [p for p in products if p.quantity > 0 and p.quantity <= 10]
    out_of_stock_products = [p for p in products if p.quantity == 0]
    
    return render_template(
        "main/reports/inventory_status.html",
        title="Inventoriaus ataskaita",
        products=products,
        total_inventory_value=total_inventory_value,
        categories=categories,
        products_by_category=products_by_category,
        category_totals=category_totals,
        low_stock_products=low_stock_products,
        out_of_stock_products=out_of_stock_products,
        selected_category=category,
        selected_stock_filter=stock_filter
    )


@bp.route("/reports/customer-analysis")
@login_required
def customer_analysis_report():
    """Customer purchase analysis report."""
    # Get date range from request or default to current year
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    
    # Default to current year if no dates specified
    today = datetime.now().date()
    if not start_date_str:
        start_date = datetime(today.year, 1, 1).date()
    else:
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        except ValueError:
            start_date = datetime(today.year, 1, 1).date()
    
    if not end_date_str:
        end_date = today
    else:
        try:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
        except ValueError:
            end_date = today
    
    # Get orders within the date range with customers
    orders = Order.query.filter(
        func.date(Order.created_at) >= start_date,
        func.date(Order.created_at) <= end_date,
        Order.status != OrderStatus.CANCELLED,
        Order.customer_id.isnot(None)
    ).all()
    
    # Analyze customer purchases
    customer_purchases = {}
    for order in orders:
        if order.customer_id not in customer_purchases:
            customer_purchases[order.customer_id] = {
                'customer': order.customer,
                'orders_count': 0,
                'total_spent': 0,
                'first_order_date': order.created_at,
                'last_order_date': order.created_at
            }
        
        customer_purchases[order.customer_id]['orders_count'] += 1
        customer_purchases[order.customer_id]['total_spent'] += order.total_amount
        
        # Update first and last order dates
        if order.created_at < customer_purchases[order.customer_id]['first_order_date']:
            customer_purchases[order.customer_id]['first_order_date'] = order.created_at
        if order.created_at > customer_purchases[order.customer_id]['last_order_date']:
            customer_purchases[order.customer_id]['last_order_date'] = order.created_at
    
    # Calculate average order value for each customer
    for customer_id, data in customer_purchases.items():
        data['average_order_value'] = data['total_spent'] / data['orders_count'] if data['orders_count'] > 0 else 0
    
    # Sort customers by total spent (descending)
    top_customers = sorted(
        customer_purchases.values(),
        key=lambda x: x['total_spent'],
        reverse=True
    )
    
    # Count new vs returning customers
    # A customer is considered new if their first order is within the date range
    new_customers = 0
    returning_customers = 0
    
    for customer_id, data in customer_purchases.items():
        if data['first_order_date'] >= datetime.combine(start_date, datetime.min.time()):
            new_customers += 1
        else:
            returning_customers += 1
    
    # Get total customer count
    total_customers = len(customer_purchases)
    
    # Get geographical distribution if data available
    geo_distribution = {}
    for order in orders:
        if not order.shipping_country:
            continue
        
        country = order.shipping_country
        if country not in geo_distribution:
            geo_distribution[country] = {'count': 0, 'total': 0}
        
        geo_distribution[country]['count'] += 1
        geo_distribution[country]['total'] += order.total_amount
    
    return render_template(
        "main/reports/customer_analysis.html",
        title="Klientų analizės ataskaita",
        start_date=start_date,
        end_date=end_date,
        top_customers=top_customers,
        total_customers=total_customers,
        new_customers=new_customers,
        returning_customers=returning_customers,
        geo_distribution=geo_distribution
    )


@bp.route("/reports/invoice-status")
@login_required
def invoice_status_report():
    """Invoice status report."""
    # Get date range from request or default to current month
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')
    
    # Default to current month if no dates specified
    today = datetime.now().date()
    if not start_date_str:
        start_date = datetime(today.year, today.month, 1).date()
    else:
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        except ValueError:
            start_date = datetime(today.year, today.month, 1).date()
    
    if not end_date_str:
        end_date = today
    else:
        try:
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
        except ValueError:
            end_date = today
    
    # Get invoices within the date range (using issue_date)
    invoices = Invoice.query.filter(
        Invoice.issue_date >= start_date,
        Invoice.issue_date <= end_date
    ).all()
    
    # Calculate totals by status
    status_totals = {}
    for status in InvoiceStatus:
        status_invoices = [inv for inv in invoices if inv.status == status]
        status_totals[status.name] = {
            'count': len(status_invoices),
            'total': sum(inv.total_amount for inv in status_invoices)
        }
    
    # Calculate totals
    total_amount = sum(invoice.total_amount for invoice in invoices)
    total_count = len(invoices)
    
    # Calculate overdue invoices
    overdue_invoices = [
        inv for inv in invoices 
        if inv.status != InvoiceStatus.PAID and inv.due_date and inv.due_date < today
    ]
    
    # Calculate average days to payment for paid invoices
    payment_days = []
    for invoice in invoices:
        if invoice.status == InvoiceStatus.PAID and invoice.issue_date and invoice.paid_date:
            days = (invoice.paid_date - invoice.issue_date).days
            payment_days.append(days)
    
    avg_days_to_payment = sum(payment_days) / len(payment_days) if payment_days else 0
    
    return render_template(
        "main/reports/invoice_status.html",
        title="Sąskaitų faktūrų ataskaita",
        start_date=start_date,
        end_date=end_date,
        invoices=invoices,
        status_totals=status_totals,
        total_amount=total_amount,
        total_count=total_count,
        overdue_invoices=overdue_invoices,
        avg_days_to_payment=avg_days_to_payment
    )


@bp.route("/reports/export/<report_type>", methods=["GET"])
@login_required
def export_report(report_type):
    """Export report data to CSV."""
    try:
        from io import StringIO
        import csv
        
        # Get date range parameters
        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')
        
        # Process date parameters
        today = datetime.now().date()
        
        if start_date_str:
            try:
                start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
            except ValueError:
                start_date = datetime(today.year, today.month, 1).date()
        else:
            start_date = datetime(today.year, today.month, 1).date()
        
        if end_date_str:
            try:
                end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
            except ValueError:
                end_date = today
        else:
            end_date = today
        
        # Create CSV file in memory
        csv_data = StringIO()
        csv_writer = csv.writer(csv_data)
        
        # Generate timestamp for filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{report_type}_{timestamp}.csv"
        
        # Export different reports based on report_type
        if report_type == 'sales_summary':
            # Get orders within the date range
            orders = Order.query.filter(
                func.date(Order.created_at) >= start_date,
                func.date(Order.created_at) <= end_date,
                Order.status != OrderStatus.CANCELLED
            ).all()
            
            # Write header
            header = [
                'Order ID', 'Order Number', 'Customer', 'Created Date', 
                'Status', 'Total Amount', 'Shipping', 'Tax'
            ]
            csv_writer.writerow(header)
            
            # Write data rows
            for order in orders:
                customer_name = order.customer.name if order.customer else order.shipping_name
                row = [
                    order.id,
                    order.order_number,
                    customer_name,
                    order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                    order.status.name,
                    f"{order.total_amount:.2f}",
                    f"{order.shipping_amount:.2f}" if order.shipping_amount else '0.00',
                    f"{order.tax_amount:.2f}" if order.tax_amount else '0.00'
                ]
                csv_writer.writerow(row)
                
        elif report_type == 'inventory_status':
            # Get filter parameters
            category = request.args.get('category')
            stock_filter = request.args.get('stock_status')
            
            # Base query
            query = Product.query
            
            # Apply filters
            if category:
                query = query.filter(Product.category == category)
            
            if stock_filter == 'low_stock':
                query = query.filter(Product.quantity > 0, Product.quantity <= 10)
            elif stock_filter == 'out_of_stock':
                query = query.filter(Product.quantity == 0)
            elif stock_filter == 'in_stock':
                query = query.filter(Product.quantity > 10)
            
            # Get products
            products = query.order_by(Product.category, Product.name).all()
            
            # Write header
            header = [
                'Product ID', 'SKU', 'Name', 'Category', 'Quantity', 
                'Price', 'Value', 'Reorder Status'
            ]
            csv_writer.writerow(header)
            
            # Write data rows
            for product in products:
                stock_status = 'OK'
                if product.quantity == 0:
                    stock_status = 'Out of Stock'
                elif product.quantity <= 10:
                    stock_status = 'Low Stock'
                
                value = product.quantity * product.price_final
                
                row = [
                    product.id,
                    product.sku,
                    product.name,
                    product.category or 'Uncategorized',
                    product.quantity,
                    f"{product.price_final:.2f}",
                    f"{value:.2f}",
                    stock_status
                ]
                csv_writer.writerow(row)
                
        elif report_type == 'customer_analysis':
            # Get orders within the date range with customers
            orders = Order.query.filter(
                func.date(Order.created_at) >= start_date,
                func.date(Order.created_at) <= end_date,
                Order.status != OrderStatus.CANCELLED,
                Order.customer_id.isnot(None)
            ).all()
            
            # Build customer data
            customer_data = {}
            for order in orders:
                if order.customer_id not in customer_data:
                    customer_data[order.customer_id] = {
                        'customer': order.customer,
                        'orders_count': 0,
                        'total_spent': 0,
                        'first_order_date': order.created_at.strftime('%Y-%m-%d'),
                        'last_order_date': order.created_at.strftime('%Y-%m-%d')
                    }
                
                customer_data[order.customer_id]['orders_count'] += 1
                customer_data[order.customer_id]['total_spent'] += order.total_amount
                
                # Update first and last order dates
                order_date = order.created_at.strftime('%Y-%m-%d')
                if order_date < customer_data[order.customer_id]['first_order_date']:
                    customer_data[order.customer_id]['first_order_date'] = order_date
                if order_date > customer_data[order.customer_id]['last_order_date']:
                    customer_data[order.customer_id]['last_order_date'] = order_date
            
            # Write header
            header = [
                'Customer ID', 'Name', 'Email', 'Orders Count', 
                'Total Spent', 'Average Order Value', 'First Order', 'Last Order'
            ]
            csv_writer.writerow(header)
            
            # Write data rows
            for customer_id, data in customer_data.items():
                customer = data['customer']
                avg_order = data['total_spent'] / data['orders_count'] if data['orders_count'] > 0 else 0
                
                row = [
                    customer.id,
                    customer.name,
                    customer.email,
                    data['orders_count'],
                    f"{data['total_spent']:.2f}",
                    f"{avg_order:.2f}",
                    data['first_order_date'],
                    data['last_order_date']
                ]
                csv_writer.writerow(row)
                
        elif report_type == 'invoice_status':
            # Get invoices within the date range
            invoices = Invoice.query.filter(
                Invoice.issue_date >= start_date,
                Invoice.issue_date <= end_date
            ).all()
            
            # Write header
            header = [
                'Invoice ID', 'Invoice Number', 'Customer', 'Issue Date', 
                'Due Date', 'Status', 'Total Amount', 'Days to Payment'
            ]
            csv_writer.writerow(header)
            
            # Write data rows
            for invoice in invoices:
                customer_name = invoice.customer.name if invoice.customer else invoice.billing_name
                
                # Calculate days to payment for paid invoices
                days_to_payment = ''
                if invoice.status == InvoiceStatus.PAID and invoice.issue_date and invoice.paid_date:
                    days_to_payment = (invoice.paid_date - invoice.issue_date).days
                
                row = [
                    invoice.id,
                    invoice.invoice_number,
                    customer_name,
                    invoice.issue_date.strftime('%Y-%m-%d') if invoice.issue_date else '',
                    invoice.due_date.strftime('%Y-%m-%d') if invoice.due_date else '',
                    invoice.status.name,
                    f"{invoice.total_amount:.2f}",
                    days_to_payment
                ]
                csv_writer.writerow(row)
        else:
            return jsonify({"error": f"Unknown report type: {report_type}"}), 400
        
        # Rewind the CSV data pointer
        csv_data.seek(0)
        
        # Return CSV file
        return Response(
            csv_data.getvalue(),
            mimetype="text/csv",
            headers={"Content-Disposition": f"attachment;filename={filename}"}
        )
        
    except Exception as e:
        current_app.logger.exception(f"Error exporting report: {str(e)}")
        flash(f"Error exporting report: {str(e)}", "error")
        return redirect(url_for(f'main.{report_type}_report'))