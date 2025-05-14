"""Inventory management services."""
import pandas as pd
from datetime import datetime
from sqlalchemy.exc import SQLAlchemyError
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product
from lt_crm.app.models.stock import StockMovement, MovementReasonCode
from lt_crm.app.models.order import OrderStatus


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
        "errors": 0,
        "error_details": [],
        "total_rows": len(df)
    }
    
    for _, row in df.iterrows():
        try:
            # Convert row to dict, handling NaN values
            product_data = {}
            for col in df.columns:
                val = row[col]
                if pd.notna(val):
                    product_data[col] = val
            
            sku = product_data.get("sku")
            if not sku:
                raise ValueError("SKU is required")
                
            # Find existing product or create new one
            product = Product.query.filter_by(sku=sku).first()
            
            # Extract quantity if present for stock movement
            quantity = None
            if "quantity" in product_data:
                quantity = int(product_data["quantity"])
            
            if product:
                # Get initial quantity
                initial_qty = product.quantity
                
                # Update existing product
                for key, value in product_data.items():
                    if key != "quantity":  # Handle quantity separately
                        setattr(product, key, value)
                
                # If quantity changed, record the difference
                if quantity is not None:
                    qty_delta = quantity - initial_qty
                    if qty_delta != 0:
                        product.quantity = quantity  # Set new quantity
                        
                        # Record stock movement
                        movement = StockMovement(
                            product_id=product.id,
                            qty_delta=qty_delta,
                            reason_code=MovementReasonCode.IMPORT,
                            note=f"Import update: {initial_qty} → {quantity}",
                            channel=channel,
                            reference_id=reference_id,
                            user_id=user_id
                        )
                        db.session.add(movement)
                
                summary["updated"] += 1
            else:
                # Create new product
                if "quantity" in product_data:
                    initial_qty = 0
                    qty = int(product_data["quantity"])
                else:
                    initial_qty = 0
                    qty = 0
                    product_data["quantity"] = 0
                
                product = Product(**product_data)
                db.session.add(product)
                db.session.flush()  # Get the product ID
                
                # Record stock movement if quantity > 0
                if qty > 0:
                    movement = StockMovement(
                        product_id=product.id,
                        qty_delta=qty,
                        reason_code=MovementReasonCode.IMPORT,
                        note=f"Initial import: {qty}",
                        channel=channel,
                        reference_id=reference_id,
                        user_id=user_id
                    )
                    db.session.add(movement)
                
                summary["created"] += 1
                
        except Exception as e:
            summary["errors"] += 1
            summary["error_details"].append(f"Error with SKU {row.get('sku', 'unknown')}: {str(e)}")
    
    # Commit all changes
    try:
        db.session.commit()
    except SQLAlchemyError as e:
        db.session.rollback()
        raise ValueError(f"Database error during import: {str(e)}")
    
    summary["timestamp"] = datetime.now().isoformat()
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
        note=f"Stock reserved for order #{order_id}",
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
    movements = []
    
    # When order is shipped, deduct the stock
    if order.status == OrderStatus.SHIPPED and (old_status is None or old_status != OrderStatus.SHIPPED):
        for item in order.items:
            # Deduct stock for each item
            movement = adjust_stock(
                product_id=item.product_id,
                qty_delta=-item.quantity,
                reason_code=MovementReasonCode.SALE,
                reference_id=order.order_number,
                note=f"Order {order.order_number} shipped",
                channel="order"
            )
            movements.append(movement)
    
    # When order is returned, add stock back
    elif order.status == OrderStatus.RETURNED and old_status != OrderStatus.RETURNED:
        for item in order.items:
            # Add stock back for each item
            movement = adjust_stock(
                product_id=item.product_id,
                qty_delta=item.quantity,
                reason_code=MovementReasonCode.RETURN,
                reference_id=order.order_number,
                note=f"Order {order.order_number} returned",
                channel="order"
            )
            movements.append(movement)
    
    # When order is cancelled, add stock back if it was previously shipped
    elif order.status == OrderStatus.CANCELLED and old_status == OrderStatus.SHIPPED:
        for item in order.items:
            movement = adjust_stock(
                product_id=item.product_id,
                qty_delta=item.quantity,
                reason_code=MovementReasonCode.RETURN,
                reference_id=order.order_number,
                note=f"Order {order.order_number} cancelled after shipping",
                channel="order"
            )
            movements.append(movement)
    
    return movements 