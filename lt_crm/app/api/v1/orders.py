"""Order endpoints for API v1."""
from datetime import datetime
from flask import request, current_app
from flask_restx import Namespace, Resource, fields
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.extensions import db
from app.api.v1.utils import (
    token_required,
    validate_schema,
    get_pagination_params,
    paginate
)
from app.services.inventory import adjust_stock, process_order_stock_changes, reserve_stock
from app.services.accounting import record_order_accounting
from app.api.v1.schemas import OrderSchema, OrderListSchema, OrderStatusUpdateSchema
from app.api.v1 import limiter

ns = Namespace("orders", description="Order operations")

# API models for Swagger docs
order_item_model = ns.model("OrderItem", {
    "product_id": fields.Integer(required=True, description="Product ID"),
    "quantity": fields.Integer(required=True, description="Quantity"),
    "price": fields.String(required=True, description="Price per unit"),
    "tax_rate": fields.String(description="Tax rate"),
    "discount_amount": fields.String(description="Discount amount"),
    "variant_info": fields.Raw(description="Variant information")
})

order_model = ns.model("Order", {
    "customer_id": fields.Integer(description="Customer ID"),
    "total_amount": fields.String(required=True, description="Total order amount"),
    "tax_amount": fields.String(description="Tax amount"),
    "shipping_amount": fields.String(description="Shipping amount"),
    "discount_amount": fields.String(description="Discount amount"),
    "shipping_name": fields.String(description="Shipping name"),
    "shipping_address": fields.String(description="Shipping address"),
    "shipping_city": fields.String(description="Shipping city"),
    "shipping_postal_code": fields.String(description="Shipping postal code"),
    "shipping_country": fields.String(description="Shipping country"),
    "shipping_phone": fields.String(description="Shipping phone"),
    "shipping_email": fields.String(description="Shipping email"),
    "payment_method": fields.String(description="Payment method"),
    "shipping_method": fields.String(description="Shipping method"),
    "notes": fields.String(description="Order notes"),
    "items": fields.List(fields.Nested(order_item_model), required=True, description="Order items")
})

order_status_model = ns.model("OrderStatus", {
    "status": fields.String(required=True, description="Order status", 
                           enum=["new", "paid", "packed", "shipped", "returned", "cancelled"])
})

@ns.route("/")
class OrderList(Resource):
    """Order collection resource."""
    
    @ns.doc("list_orders")
    @ns.response(200, "Success")
    @token_required()
    @limiter.limit("200/minute")
    def get(self, current_user):
        """List all orders."""
        page, per_page = get_pagination_params()
        
        # Handle filtering
        query = Order.query
        
        # Filter by status if provided
        status = request.args.get("status")
        if status:
            query = query.filter(Order.status == OrderStatus(status))
        
        # Filter by customer if provided
        customer_id = request.args.get("customer_id", type=int)
        if customer_id:
            query = query.filter(Order.customer_id == customer_id)
            
        # Filter by date range if provided
        date_from = request.args.get("date_from")
        if date_from:
            try:
                date_from = datetime.strptime(date_from, "%Y-%m-%d")
                query = query.filter(Order.created_at >= date_from)
            except ValueError:
                pass
                
        date_to = request.args.get("date_to")
        if date_to:
            try:
                date_to = datetime.strptime(date_to, "%Y-%m-%d")
                date_to = date_to.replace(hour=23, minute=59, second=59)
                query = query.filter(Order.created_at <= date_to)
            except ValueError:
                pass
        
        # Sort by field if provided
        sort_by = request.args.get("sort_by", "created_at")
        sort_dir = request.args.get("sort_dir", "desc")
        
        if hasattr(Order, sort_by):
            sort_col = getattr(Order, sort_by)
            query = query.order_by(sort_col.desc() if sort_dir == "desc" else sort_col.asc())
        else:
            query = query.order_by(Order.created_at.desc())
        
        # Return paginated results
        result = paginate(query, OrderSchema, page, per_page)
        return result
    
    @ns.doc("create_order")
    @ns.expect(order_model)
    @ns.response(201, "Order created")
    @ns.response(400, "Validation error")
    @token_required()
    @validate_schema(OrderSchema)
    def post(self, current_user, data):
        """Create a new order (manual sale)."""
        # Generate order number
        date_str = datetime.now().strftime("%Y%m%d")
        last_order = Order.query.filter(Order.order_number.like(f"ORD-{date_str}%")).order_by(
            Order.id.desc()
        ).first()
        
        if last_order:
            # Extract sequence number and increment
            seq_num = int(last_order.order_number.split("-")[-1])
            next_num = seq_num + 1
        else:
            next_num = 1
            
        order_number = f"ORD-{date_str}-{next_num:04d}"
        
        # Create new order
        order_data = {k: v for k, v in data.items() if k != "items"}
        order_data["order_number"] = order_number
        order_data["status"] = OrderStatus.NEW
        
        order = Order(**order_data)
        db.session.add(order)
        db.session.flush()  # Get order ID for stock reservation
        
        # Add order items
        if "items" in data:
            for item_data in data["items"]:
                # Check if product exists and is in stock
                product = Product.query.get(item_data["product_id"])
                if not product:
                    return {"message": f"Product with ID {item_data['product_id']} not found"}, 400
                
                if item_data.get("quantity", 0) > product.quantity:
                    return {
                        "message": f"Insufficient stock for product {product.sku}. "
                                   f"Available: {product.quantity}, Requested: {item_data['quantity']}"
                    }, 400
                
                # Reserve stock
                try:
                    reserve_stock(
                        product_id=product.id,
                        quantity=item_data.get("quantity", 1),
                        order_id=order.id,
                        user_id=current_user.id
                    )
                except Exception as e:
                    current_app.logger.error(f"Error reserving stock: {str(e)}")
                
                # Create order item
                order_item = OrderItem(order=order, **item_data)
                db.session.add(order_item)
        
        db.session.commit()
        
        schema = OrderSchema()
        return schema.dump(order), 201

@ns.route("/<int:id>")
@ns.param("id", "Order ID")
class OrderResource(Resource):
    """Order resource."""
    
    @ns.doc("get_order")
    @ns.response(200, "Success")
    @ns.response(404, "Order not found")
    @token_required()
    def get(self, id, current_user):
        """Get an order by ID."""
        order = Order.query.get_or_404(id)
        
        schema = OrderSchema()
        return schema.dump(order)

@ns.route("/<int:id>/status")
@ns.param("id", "Order ID")
class OrderStatusResource(Resource):
    """Order status resource."""
    
    @ns.doc("update_order_status")
    @ns.expect(order_status_model)
    @ns.response(200, "Status updated")
    @ns.response(400, "Validation error")
    @ns.response(404, "Order not found")
    @token_required()
    @validate_schema(OrderStatusUpdateSchema)
    def patch(self, id, current_user, data):
        """Update order status."""
        order = Order.query.get_or_404(id)
        
        # Store old status for comparison
        old_status = order.status
        
        try:
            new_status = OrderStatus(data["status"])
            
            # Update status
            order.status = new_status
            db.session.commit()
            
            # Process inventory changes based on status
            try:
                movements = process_order_stock_changes(order, old_status)
                
                # If order is marked as paid, record accounting entries
                if order.status == OrderStatus.PAID and old_status != OrderStatus.PAID:
                    transaction = record_order_accounting(order.id)
                    
                schema = OrderSchema()
                return schema.dump(order)
            except Exception as e:
                # Log the error but don't fail the status update
                current_app.logger.error(f"Error processing order changes: {str(e)}")
                return {
                    "order": OrderSchema().dump(order),
                    "warning": f"Order status updated but additional processing failed: {str(e)}"
                }
            
        except ValueError:
            return {"message": f"Invalid status: {data['status']}"}, 400 