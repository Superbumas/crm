"""Pigu marketplace API client."""
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from .base_client import BaseAPIClient
from ..exceptions import APIError
from ..models.order import Order, OrderItem, OrderStatus
from ..models.product import Product
from ..extensions import db


class PiguClient(BaseAPIClient):
    """Client for Pigu API integration."""

    def __init__(self):
        """Initialize the Pigu API client."""
        base_url = os.environ.get("PIGU_API_URL", "https://api.pigu.lt/v1")
        api_key = os.environ.get("PIGU_API_KEY")
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
            headers["Authorization"] = f"Bearer {self.api_key}"
        return headers
    
    def fetch_orders(self, days_back: int = 7) -> Dict[str, Any]:
        """
        Fetch orders from Pigu marketplace.
        
        Args:
            days_back (int): How many days back to fetch orders
            
        Returns:
            Dict[str, Any]: Result summary containing totals and details
            
        Raises:
            APIError: On any API errors
        """
        since_date = (datetime.utcnow() - timedelta(days=days_back)).strftime("%Y-%m-%d")
        
        try:
            # Fetch orders from Pigu API
            response = self.get(
                "orders",
                params={"since": since_date, "status": "all"}
            )
            
            orders_data = response.get("orders", [])
            self.logger.info(f"Fetched {len(orders_data)} orders from Pigu")
            
            # Process orders
            created = 0
            updated = 0
            failed = 0
            details = []
            
            for order_data in orders_data:
                try:
                    # Extract order info
                    order_number = order_data.get("order_id")
                    if not order_number:
                        raise ValueError("Missing order_id")
                    
                    # Look for existing order
                    order = Order.query.filter_by(order_number=f"pigu-{order_number}").first()
                    
                    # Map Pigu status to our status
                    status_map = {
                        "new": OrderStatus.NEW,
                        "paid": OrderStatus.PAID,
                        "shipped": OrderStatus.SHIPPED,
                        "cancelled": OrderStatus.CANCELLED,
                        # Add more mappings as needed
                    }
                    
                    pigu_status = order_data.get("status", "new").lower()
                    status = status_map.get(pigu_status, OrderStatus.NEW)
                    
                    # Extract financials
                    total_amount = float(order_data.get("total_amount", 0))
                    shipping_amount = float(order_data.get("shipping_amount", 0))
                    tax_amount = float(order_data.get("tax_amount", 0))
                    
                    # Extract shipping info
                    shipping_data = order_data.get("shipping", {})
                    shipping_info = {
                        "name": shipping_data.get("full_name"),
                        "address": shipping_data.get("address"),
                        "city": shipping_data.get("city"),
                        "postal_code": shipping_data.get("postal_code"),
                        "country": shipping_data.get("country", "Lithuania"),
                        "phone": shipping_data.get("phone"),
                        "email": shipping_data.get("email")
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
                            order_number=f"pigu-{order_number}",
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
                            notes="Imported from Pigu"
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
                                tax_rate=float(item_data.get("tax_rate", 0)),
                                variant_info=item_data.get("variant_info")
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
                    self.logger.error(f"Failed to process Pigu order {order_data.get('order_id')}: {str(e)}")
                    failed += 1
                    details.append({
                        "order_number": f"pigu-{order_data.get('order_id')}",
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
            self.logger.error(f"Error fetching orders from Pigu: {str(e)}")
            raise APIError(f"Failed to fetch Pigu orders: {str(e)}")
    
    def push_stock(self, products: List[Product]) -> Dict[str, Any]:
        """
        Push stock updates to Pigu marketplace.
        
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
                    "quantity": product.quantity,
                    "is_in_stock": product.quantity > 0
                })
            
            # Send updates in batches of 100
            batch_size = 100
            for i in range(0, len(stock_updates), batch_size):
                batch = stock_updates[i:i+batch_size]
                
                try:
                    response = self.post(
                        "inventory/update",
                        json_data={"items": batch}
                    )
                    
                    # Process response
                    results = response.get("results", [])
                    for result in results:
                        sku = result.get("sku")
                        status = result.get("status")
                        
                        if status == "success":
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
                                "error": result.get("error")
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
            self.logger.error(f"Error updating stock in Pigu: {str(e)}")
            raise APIError(f"Failed to update stock in Pigu: {str(e)}") 