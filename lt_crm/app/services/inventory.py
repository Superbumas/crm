"""Inventory management services."""
import pandas as pd
from datetime import datetime
from sqlalchemy.exc import SQLAlchemyError
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product
from lt_crm.app.models.stock import StockMovement, MovementReasonCode
from lt_crm.app.models.order import OrderStatus
from lt_crm.app.services.image_service import process_product_images


def import_products_from_dataframe(df, channel=None, reference_id=None, user_id=None):
    """
    Import products from a pandas DataFrame.
    
    Args:
        df (DataFrame): DataFrame containing product data
        channel (str, optional): Import channel
        reference_id (str, optional): Reference ID for tracking
        user_id (int, optional): User ID who initiated the import
        
    Returns:
        dict: Summary of import operation
    """
    # Required columns
    required_cols = ["sku", "name", "price_final"]
    for col in required_cols:
        if col not in df.columns:
            raise ValueError(f"Missing required column: {col}")
    
    summary = {
        "created": 0,
        "updated": 0,
        "skipped": 0,
        "errors": 0,
        "error_details": [],
        "total_rows": len(df)
    }
    
    # Dictionary mapping between possible column names and model field names
    field_mapping = {
        # Standard names
        'sku': 'sku',
        'name': 'name',
        'description_html': 'description_html',
        'description': 'description_html',  # Alternative name
        'barcode': 'barcode',
        'quantity': 'quantity',
        'delivery_days': 'delivery_days',
        'price_final': 'price_final',
        'price': 'price_final',  # Alternative name
        'price_old': 'price_old',
        'category': 'category',
        'main_image_url': 'main_image_url',
        'image_url': 'main_image_url',  # Alternative name
        'manufacturer': 'manufacturer',
        'model': 'model',
        'warranty_months': 'warranty_months',
        'weight_kg': 'weight_kg',
        'parameters': 'parameters',
        'variants': 'variants',
        'delivery_options': 'delivery_options',
        'extra_image_urls': 'extra_image_urls'
    }
    
    # Dictionary to track SKUs that have been processed
    processed_skus = {}
    
    for _, row in df.iterrows():
        try:
            # Convert row to dict, handling NaN values
            product_data = {}
            image_data = {
                'main_image_url': None,
                'extra_image_urls': None
            }
            
            for col in df.columns:
                val = row[col]
                if pd.notna(val):
                    # Map column name if it exists in the mapping
                    field_name = field_mapping.get(col, col)
                    
                    # Separate image data for processing after product creation/update
                    if field_name in ['main_image_url', 'extra_image_urls']:
                        image_data[field_name] = val
                    else:
                        product_data[field_name] = val
            
            # Check for required fields after mapping
            original_sku = product_data.get("sku")
            if not original_sku:
                summary["skipped"] += 1
                summary["error_details"].append("Skipped row with missing SKU")
                continue
            
            # Handle duplicate SKUs by adding suffix if the SKU already exists
            sku = original_sku
            if sku in processed_skus:
                # Found a duplicate SKU - append a suffix number
                counter = processed_skus[sku] + 1
                processed_skus[sku] = counter
                new_sku = f"{sku}_{counter}"
                product_data["sku"] = new_sku
                sku = new_sku
                summary["error_details"].append(f"Duplicate SKU '{original_sku}' modified to '{new_sku}'")
            else:
                processed_skus[sku] = 0
                
            # Check name exists
            if "name" not in product_data:
                summary["skipped"] += 1
                summary["error_details"].append(f"Skipped SKU {sku}: Missing product name")
                continue
                
            # Check price exists
            if "price_final" not in product_data:
                summary["skipped"] += 1
                summary["error_details"].append(f"Skipped SKU {sku}: Missing price")
                continue
            
            # Safely convert price to decimal if it's not already numeric
            try:
                if isinstance(product_data["price_final"], str):
                    # Remove any currency symbols and handle different decimal separators
                    price_str = product_data["price_final"]
                    # Remove currency symbols and spaces
                    price_str = ''.join(c for c in price_str if c.isdigit() or c in '.,')
                    # Handle different decimal separators
                    if ',' in price_str and '.' in price_str:
                        # If both are present, the last one is the decimal separator
                        if price_str.rindex('.') > price_str.rindex(','):
                            price_str = price_str.replace(',', '')
                        else:
                            price_str = price_str.replace('.', '').replace(',', '.')
                    elif ',' in price_str:
                        # If only comma is present, assume it's a decimal separator
                        price_str = price_str.replace(',', '.')
                        
                    product_data["price_final"] = float(price_str)
            except (ValueError, TypeError):
                summary["skipped"] += 1
                summary["error_details"].append(f"Skipped SKU {sku}: Invalid price format")
                continue
                
            # Find existing product or create new one
            product = Product.query.filter_by(sku=sku).first()
            
            # Extract quantity if present for stock movement
            quantity = None
            if "quantity" in product_data:
                try:
                    quantity = int(float(product_data["quantity"]))
                    if quantity < 0:
                        quantity = 0  # Negative quantities are not allowed
                except (ValueError, TypeError):
                    quantity = 0  # Default to 0 if conversion fails
                
            if product:
                # Get initial quantity
                initial_qty = product.quantity
                
                # Update existing product
                for key, value in product_data.items():
                    if key != "quantity" and hasattr(product, key):  # Handle quantity separately and ensure attribute exists
                        try:
                            setattr(product, key, value)
                        except Exception as e:
                            summary["error_details"].append(f"Warning for SKU {sku}: Could not set {key}={value}: {str(e)}")
                
                # If quantity changed, record the difference
                if quantity is not None:
                    qty_delta = quantity - initial_qty
                    if qty_delta != 0:
                        product.quantity = quantity  # Set new quantity
                        
                        # Record stock movement
                        try:
                            movement = StockMovement(
                                product_id=product.id,
                                qty_delta=qty_delta,
                                reason_code=MovementReasonCode.IMPORT,
                                note=f"Importo atnaujinimas: {initial_qty} → {quantity}",
                                channel=channel,
                                reference_id=reference_id,
                                user_id=user_id
                            )
                            db.session.add(movement)
                        except Exception as e:
                            summary["error_details"].append(f"Warning for SKU {sku}: Could not create stock movement: {str(e)}")
                
                db.session.commit()  # Commit to get product ID
                
                # Process images after product is created/updated
                if image_data['main_image_url'] or image_data['extra_image_urls']:
                    try:
                        process_product_images(
                            product.id,
                            main_image_url=image_data['main_image_url'],
                            extra_image_urls=image_data['extra_image_urls']
                        )
                    except Exception as e:
                        summary["error_details"].append(f"Warning for SKU {sku}: Could not process images: {str(e)}")
                
                summary["updated"] += 1
            else:
                # Create new product with only valid fields
                valid_product_data = {}
                for key, value in product_data.items():
                    if hasattr(Product, key):  # Ensure attribute exists in the model
                        valid_product_data[key] = value
                
                # Handle required fields
                if "quantity" in valid_product_data:
                    initial_qty = 0
                    qty = int(float(valid_product_data["quantity"]))
                    if qty < 0:
                        qty = 0  # Negative quantities are not allowed
                else:
                    initial_qty = 0
                    qty = 0
                    valid_product_data["quantity"] = 0
                
                # Create new product
                try:
                    product = Product(**valid_product_data)
                    db.session.add(product)
                    db.session.commit()  # Commit to get product ID
                    
                    # Process images after product is created
                    if image_data['main_image_url'] or image_data['extra_image_urls']:
                        try:
                            process_product_images(
                                product.id,
                                main_image_url=image_data['main_image_url'],
                                extra_image_urls=image_data['extra_image_urls']
                            )
                        except Exception as e:
                            summary["error_details"].append(f"Warning for SKU {sku}: Could not process images: {str(e)}")
                    
                    # Record initial stock movement if quantity > 0
                    if qty > 0:
                        movement = StockMovement(
                            product_id=product.id,
                            qty_delta=qty,
                            reason_code=MovementReasonCode.IMPORT,
                            note=f"Pradinis likutis: {qty}",
                            channel=channel,
                            reference_id=reference_id,
                            user_id=user_id
                        )
                        db.session.add(movement)
                        db.session.commit()
                    
                    summary["created"] += 1
                except Exception as e:
                    db.session.rollback()
                    summary["errors"] += 1
                    summary["error_details"].append(f"Error creating product {sku}: {str(e)}")
                    continue
                    
        except Exception as e:
            summary["errors"] += 1
            summary["error_details"].append(f"Error processing row: {str(e)}")
            continue
            
    return summary


def adjust_stock(product_id, qty_delta, reason_code, channel=None, reference_id=None, note=None, user_id=None):
    """
    Adjust stock for a product and record the movement.
    
    Args:
        product_id (int): Product ID
        qty_delta (int): Quantity change (positive or negative)
        reason_code (MovementReasonCode): Reason for stock adjustment
        channel (str, optional): Channel of adjustment
        reference_id (str, optional): Reference ID (e.g., order number)
        note (str, optional): Additional notes
        user_id (int, optional): User who made the adjustment
        
    Returns:
        StockMovement: The created stock movement record
        
    Raises:
        ValueError: If product not found or invalid qty_delta
        SQLAlchemyError: If database error occurs
    """
    product = Product.query.get(product_id)
    if not product:
        raise ValueError(f"Product with ID {product_id} not found")
    
    # Create movement record
    movement = StockMovement(
        product_id=product_id,
        qty_delta=qty_delta,
        reason_code=reason_code,
        note=note,
        channel=channel,
        reference_id=reference_id,
        user_id=user_id
    )
    
    # Update product quantity
    product.quantity += qty_delta
    
    # Save changes
    db.session.add(movement)
    db.session.add(product)
    
    try:
        db.session.commit()
        return movement
    except SQLAlchemyError as e:
        db.session.rollback()
        raise SQLAlchemyError(f"Error adjusting stock: {str(e)}")


def reserve_stock(product_id, quantity, order_id, user_id=None):
    """
    Reserve stock for an order.
    This doesn't reduce actual stock but creates a movement record.
    
    Args:
        product_id (int): Product ID
        quantity (int): Quantity to reserve (positive number)
        order_id (int): Order ID for reference
        user_id (int, optional): User who created the order
        
    Returns:
        bool: True if successful
        
    Raises:
        ValueError: If product not found or insufficient stock
    """
    if quantity <= 0:
        raise ValueError("Quantity must be positive")
    
    product = Product.query.get(product_id)
    if not product:
        raise ValueError(f"Product with ID {product_id} not found")
    
    if product.quantity < quantity:
        raise ValueError(f"Insufficient stock for product {product.sku}. Available: {product.quantity}, Requested: {quantity}")
    
    # Create stock movement record for reservation
    # We use SALE reason code but we don't adjust the stock yet
    movement = StockMovement(
        product_id=product_id,
        qty_delta=0,  # No actual change yet
        reason_code=MovementReasonCode.SALE,
        note=f"Atsargos rezervuotos užsakymui #{order_id}",
        reference_id=str(order_id),
        user_id=user_id
    )
    
    db.session.add(movement)
    
    try:
        db.session.commit()
        return True
    except SQLAlchemyError as e:
        db.session.rollback()
        raise SQLAlchemyError(f"Error reserving stock: {str(e)}")


def process_order_stock_changes(order, old_status=None):
    """
    Process stock changes based on order status.
    
    Args:
        order: Order object
        old_status (OrderStatus, optional): Previous order status
        
    Returns:
        list: List of stock movements created
    """
    from flask import current_app
    
    movements = []
    
    # Debug logging
    current_app.logger.info(f"Processing stock changes for order {order.id} (#{order.order_number})")
    current_app.logger.info(f"Order status change: {old_status} -> {order.status}")
    
    # Ensure order items are loaded
    if not hasattr(order, 'items') or not order.items:
        current_app.logger.warning(f"Order {order.id} has no items to process")
        return movements
    
    # Get item count for debugging
    item_count = len(list(order.items))
    current_app.logger.info(f"Order has {item_count} items to process")
    
    # When order is shipped, deduct the stock
    if order.status == OrderStatus.SHIPPED and (old_status is None or old_status != OrderStatus.SHIPPED):
        current_app.logger.info(f"Order {order.id} is marked as SHIPPED - deducting stock")
        
        for item in order.items:
            try:
                # Deduct stock for each item
                current_app.logger.info(f"Processing item product_id: {item.product_id}, quantity: {item.quantity}")
                
                movement = adjust_stock(
                    product_id=item.product_id,
                    qty_delta=-item.quantity,
                    reason_code=MovementReasonCode.SALE,
                    reference_id=str(order.id),
                    note=f"Užsakymas {order.order_number} išsiųstas",
                    channel="order"
                )
                movements.append(movement)
                current_app.logger.info(f"Created stock movement: {movement.id} for product {item.product_id}")
            except Exception as e:
                current_app.logger.error(f"Error processing item {item.id}: {str(e)}")
    
    # When order is returned, add stock back
    elif order.status == OrderStatus.RETURNED and (old_status is None or old_status != OrderStatus.RETURNED):
        current_app.logger.info(f"Order {order.id} is marked as RETURNED - adding stock back")
        
        for item in order.items:
            try:
                # Add stock back for each item
                movement = adjust_stock(
                    product_id=item.product_id,
                    qty_delta=item.quantity,
                    reason_code=MovementReasonCode.RETURN,
                    reference_id=str(order.id),
                    note=f"Užsakymas {order.order_number} grąžintas",
                    channel="order"
                )
                movements.append(movement)
                current_app.logger.info(f"Created stock movement: {movement.id} for product {item.product_id}")
            except Exception as e:
                current_app.logger.error(f"Error processing item {item.id}: {str(e)}")
    
    # When order is cancelled, add stock back if it was previously shipped
    elif order.status == OrderStatus.CANCELLED and old_status == OrderStatus.SHIPPED:
        current_app.logger.info(f"Order {order.id} is cancelled after shipping - adding stock back")
        
        for item in order.items:
            try:
                movement = adjust_stock(
                    product_id=item.product_id,
                    qty_delta=item.quantity,
                    reason_code=MovementReasonCode.RETURN,
                    reference_id=str(order.id),
                    note=f"Užsakymas {order.order_number} atšauktas po išsiuntimo",
                    channel="order"
                )
                movements.append(movement)
                current_app.logger.info(f"Created stock movement: {movement.id} for product {item.product_id}")
            except Exception as e:
                current_app.logger.error(f"Error processing item {item.id}: {str(e)}")
    
    current_app.logger.info(f"Completed processing for order {order.id}, created {len(movements)} stock movements")
    return movements 