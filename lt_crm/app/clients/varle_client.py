"""Varle marketplace API client."""
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from app.clients.base_client import BaseAPIClient
from app.exceptions import APIError
from app.models.order import Order, OrderItem, OrderStatus
from app.models.product import Product
from app.extensions import db


class VarleClient(BaseAPIClient):
    """Client for Varle API integration."""

    def __init__(self):
        """Initialize the Varle API client."""
        base_url = os.environ.get("VARLE_API_URL", "https://api.varle.lt/v1")
        api_key = os.environ.get("VARLE_API_KEY")
        self.api_key = api_key
        
        super().__init__(base_url=base_url)
    
    def _get_headers(self) -> Dict[str, str]:
        """
        Get request headers with API key authentication.
        
        Returns:
            Dict[str, str]: Headers dictionary
        """
        headers = super()._get_headers()
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        return headers
    
    def fetch_orders(self, days_back: int = 7) -> Dict[str, Any]:
        """
        Fetch orders from Varle marketplace.
        
        Args:
            days_back (int): How many days back to fetch orders
            
        Returns:
            Dict[str, Any]: Result summary containing totals and details
            
        Raises:
            APIError: On any API errors
        """
        since_date = (datetime.utcnow() - timedelta(days=days_back)).strftime("%Y-%m-%d")
        
        try:
            # Fetch orders from Varle API
            response = self.get(
                "seller/orders",
                params={"date_from": since_date}
            )
            
            orders_data = response.get("data", [])
            self.logger.info(f"Fetched {len(orders_data)} orders from Varle")
            
            # Process orders
            created = 0
            updated = 0
            failed = 0
            details = []
            
            for order_data in orders_data:
                try:
                    # Extract order info
                    order_number = order_data.get("order_number")
                    if not order_number:
                        raise ValueError("Missing order_number")
                    
                    # Look for existing order
                    order = Order.query.filter_by(order_number=f"varle-{order_number}").first()
                    
                    # Map Varle status to our status
                    status_map = {
                        "new": OrderStatus.NEW,
                        "paid": OrderStatus.PAID,
                        "processing": OrderStatus.PAID,
                        "shipped": OrderStatus.SHIPPED,
                        "canceled": OrderStatus.CANCELLED,
                        # Add more mappings as needed
                    }
                    
                    varle_status = order_data.get("status", "new").lower()
                    status = status_map.get(varle_status, OrderStatus.NEW)
                    
                    # Extract financials
                    total_amount = float(order_data.get("total", 0))
                    shipping_amount = float(order_data.get("shipping_fee", 0))
                    tax_amount = float(order_data.get("vat_amount", 0))
                    
                    # Extract shipping info
                    customer_data = order_data.get("customer", {})
                    shipping_data = order_data.get("shipping_address", {})
                    shipping_info = {
                        "name": f"{customer_data.get('firstname', '')} {customer_data.get('lastname', '')}".strip(),
                        "address": shipping_data.get("street"),
                        "city": shipping_data.get("city"),
                        "postal_code": shipping_data.get("postcode"),
                        "country": shipping_data.get("country", "Lithuania"),
                        "phone": customer_data.get("phone"),
                        "email": customer_data.get("email")
                    }
                    
                    if order:
                        # Update existing order
                        order.status = status
                        order.shipping_name = shipping_info["name"]
                        order.shipping_address = shipping_info["address"]
                        order.shipping_city = shipping_info["city"]
                        order.shipping_postal_code = shipping_info["postal_code"]
                        order.shipping_country = shipping_info["country"]
                        order.shipping_phone = shipping_info["phone"]
                        order.shipping_email = shipping_info["email"]
                        order.tracking_number = order_data.get("tracking_number")
                        
                        db.session.add(order)
                        updated += 1
                        details.append({
                            "order_number": order.order_number,
                            "action": "updated",
                            "status": status.value
                        })
                    else:
                        # Create new order
                        new_order = Order(
                            order_number=f"varle-{order_number}",
                            status=status,
                            total_amount=total_amount,
                            shipping_amount=shipping_amount,
                            tax_amount=tax_amount,
                            shipping_name=shipping_info["name"],
                            shipping_address=shipping_info["address"],
                            shipping_city=shipping_info["city"],
                            shipping_postal_code=shipping_info["postal_code"],
                            shipping_country=shipping_info["country"],
                            shipping_phone=shipping_info["phone"],
                            shipping_email=shipping_info["email"],
                            payment_method=order_data.get("payment_method"),
                            payment_reference=order_data.get("payment_id"),
                            shipping_method=order_data.get("shipping_method"),
                            tracking_number=order_data.get("tracking_number"),
                            notes="Imported from Varle"
                        )
                        
                        # Process order items
                        items_data = order_data.get("items", [])
                        for item_data in items_data:
                            sku = item_data.get("sku")
                            if not sku:
                                continue
                                
                            # Find product by SKU
                            product = Product.query.filter_by(sku=sku).first()
                            if not product:
                                self.logger.warning(f"Product with SKU {sku} not found")
                                continue
                                
                            # Create order item
                            item = OrderItem(
                                product_id=product.id,
                                quantity=int(item_data.get("quantity", 1)),
                                price=float(item_data.get("price", 0)),
                                tax_rate=float(item_data.get("vat_rate", 0)),
                                variant_info=item_data.get("options")
                            )
                            
                            new_order.items.append(item)
                        
                        db.session.add(new_order)
                        created += 1
                        details.append({
                            "order_number": new_order.order_number,
                            "action": "created",
                            "status": status.value
                        })
                    
                    db.session.commit()
                except Exception as e:
                    db.session.rollback()
                    self.logger.error(f"Failed to process Varle order {order_data.get('order_number')}: {str(e)}")
                    failed += 1
                    details.append({
                        "order_number": f"varle-{order_data.get('order_number')}",
                        "action": "failed",
                        "error": str(e)
                    })
            
            return {
                "total": len(orders_data),
                "created": created,
                "updated": updated,
                "failed": failed,
                "details": details
            }
                
        except Exception as e:
            self.logger.error(f"Error fetching orders from Varle: {str(e)}")
            raise APIError(f"Failed to fetch Varle orders: {str(e)}")
    
    def push_stock(self, products: List[Product]) -> Dict[str, Any]:
        """
        Push stock updates to Varle marketplace.
        
        Args:
            products (List[Product]): List of products to update
            
        Returns:
            Dict[str, Any]: Result summary containing totals and details
            
        Raises:
            APIError: On any API errors
        """
        success_count = 0
        failed_count = 0
        details = []
        
        try:
            stock_updates = []
            
            # Prepare stock updates
            for product in products:
                stock_updates.append({
                    "sku": product.sku,
                    "stock": product.quantity,
                    "available": product.quantity > 0
                })
            
            # Send updates in batches of 50 (Varle API limit)
            batch_size = 50
            for i in range(0, len(stock_updates), batch_size):
                batch = stock_updates[i:i+batch_size]
                
                try:
                    response = self.post(
                        "seller/products/stock-update",
                        json_data={"products": batch}
                    )
                    
                    # Process response
                    results = response.get("results", [])
                    for result in results:
                        sku = result.get("sku")
                        success = result.get("success", False)
                        
                        if success:
                            success_count += 1
                            details.append({
                                "sku": sku,
                                "status": "success"
                            })
                        else:
                            failed_count += 1
                            details.append({
                                "sku": sku,
                                "status": "failed",
                                "error": result.get("message", "Unknown error")
                            })
                except Exception as e:
                    # If batch fails, mark all products in batch as failed
                    for item in batch:
                        failed_count += 1
                        details.append({
                            "sku": item["sku"],
                            "status": "failed",
                            "error": str(e)
                        })
            
            return {
                "success": success_count,
                "failed": failed_count,
                "details": details
            }
        except Exception as e:
            self.logger.error(f"Error updating stock in Varle: {str(e)}")
            raise APIError(f"Failed to update stock in Varle: {str(e)}") 