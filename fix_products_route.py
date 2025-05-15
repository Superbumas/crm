"""
Fix for the products route to handle missing product_columns variable.
Run this script with Docker exec to update the running container.
"""

import sys
import os

# Path to the routes.py file in the Docker container
ROUTES_FILE = '/app/lt_crm/app/main/routes.py'

# The fixed products route code
FIXED_ROUTE = '''
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
    
    # Define default columns in case PRODUCT_COLUMNS is not available
    default_columns = {
        "sku": {"name": "SKU", "description": "Produkto kodas", "default": True},
        "name": {"name": "Pavadinimas", "description": "Produkto pavadinimas", "default": True},
        "category": {"name": "Kategorija", "description": "Produkto kategorija", "default": True},
        "price_final": {"name": "Kaina", "description": "Galutinė kaina", "default": True},
        "quantity": {"name": "Likutis", "description": "Kiekis sandėlyje", "default": True}
    }
    
    # Try importing PRODUCT_COLUMNS, fallback to default if not available
    try:
        from lt_crm.app.models.product import PRODUCT_COLUMNS
        product_columns = PRODUCT_COLUMNS
    except (ImportError, AttributeError):
        product_columns = default_columns
    
    # Get selected columns or default
    try:
        if hasattr(current_user, 'get_product_columns') and callable(getattr(current_user, 'get_product_columns')):
            selected_columns = current_user.get_product_columns()
        else:
            # Fallback to default columns if user preferences not available
            selected_columns = ["sku", "name", "category", "price_final", "quantity"]
    except Exception:
        selected_columns = ["sku", "name", "category", "price_final", "quantity"]
    
    return render_template(
        "main/products.html",
        title="Produktai",
        products=products,
        pagination=pagination,
        categories=categories,
        product_columns=product_columns,
        selected_columns=selected_columns,
    )
'''

def update_routes_file():
    """Update the routes.py file with the fixed products route."""
    if not os.path.exists(ROUTES_FILE):
        print(f"Error: Routes file not found at {ROUTES_FILE}")
        return False
    
    # Read the current file
    with open(ROUTES_FILE, 'r') as f:
        content = f.read()
    
    # Find the products route
    start_marker = '@bp.route("/products")'
    end_marker = '@bp.route("/products/new"'
    
    start_pos = content.find(start_marker)
    if start_pos == -1:
        print("Error: Could not find products route in file")
        return False
    
    end_pos = content.find(end_marker, start_pos)
    if end_pos == -1:
        print("Error: Could not find the end of products route")
        return False
    
    # Replace the products route
    new_content = content[:start_pos] + FIXED_ROUTE + content[end_pos:]
    
    # Write the updated file
    with open(ROUTES_FILE, 'w') as f:
        f.write(new_content)
    
    print("Successfully updated the products route!")
    return True

if __name__ == "__main__":
    sys.exit(0 if update_routes_file() else 1) 