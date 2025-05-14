"""Allegro marketplace API client."""
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
from lt_crm.app.clients.base_client import BaseAPIClient
from lt_crm.app.exceptions import APIError
from lt_crm.app.models.order import Order, OrderItem, OrderStatus
from lt_crm.app.models.product import Product
from lt_crm.app.extensions import db


class AllegroClient(BaseAPIClient):
    """Client for Allegro API integration."""

    def __init__(self):
        """Initialize the Allegro API client."""
        base_url = os.environ.get("ALLEGRO_API_URL", "https://api.allegro.pl")
        client_id = os.environ.get("ALLEGRO_CLIENT_ID")
        client_secret = os.environ.get("ALLEGRO_CLIENT_SECRET")
        self.client_id = client_id
        self.client_secret = client_secret
        self.access_token = None
        self.token_expiry = None
        
        super().__init__(base_url=base_url)
    
    def _get_headers(self) -> Dict[str, str]:
        """
        Get request headers with OAuth authentication.
        
        Returns:
            Dict[str, str]: Headers dictionary
        """
        headers = super()._get_headers()
        
        # Check if we need to refresh the token
        if self._should_refresh_token():
            self._refresh_token()
            
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        
        return headers
    
    def _should_refresh_token(self) -> bool:
        """
        Check if token should be refreshed.
        
        Returns:
            bool: True if token needs refresh, False otherwise
        """
        if not self.access_token or not self.token_expiry:
            return True
            
        # Refresh if token expires in less than 5 minutes
        return datetime.utcnow() + timedelta(minutes=5) >= self.token_expiry
    
    def _refresh_token(self):
        """
        Refresh OAuth access token.
        
        Raises:
            APIError: On authentication failure
        """
        if not self.client_id or not self.client_secret:
            self.logger.error("Missing Allegro API credentials")
            return
            
        try:
            auth_url = f"{self.base_url}/auth/oauth/token"
            
            # Use httpx directly instead of self.request to avoid recursion
            import httpx
            
            response = httpx.post(
                auth_url,
                data={
                    "grant_type": "client_credentials",
                    "client_id": self.client_id,
                    "client_secret": self.client_secret
                },
                headers={
                    "Content-Type": "application/x-www-form-urlencoded"
                }
            )
            
            response.raise_for_status()
            auth_data = response.json()
            
            self.access_token = auth_data.get("access_token")
            expires_in = auth_data.get("expires_in", 3600)  # Default to 1 hour
            self.token_expiry = datetime.utcnow() + timedelta(seconds=expires_in)
            
            self.logger.info("Allegro API token refreshed")
        except Exception as e:
            self.logger.error(f"Failed to refresh Allegro API token: {str(e)}")
            raise APIError(f"Allegro authentication failed: {str(e)}")
    
    def fetch_orders(self, days_back: int = 7) -> Dict[str, Any]:
        """
        Fetch orders from Allegro marketplace.
        
        Args:
            days_back (int): How many days back to fetch orders
            
        Returns:
            Dict[str, Any]: Result summary containing totals and details
            
        Raises:
            APIError: On any API errors
        """
        since_date = (datetime.utcnow() - timedelta(days=days_back)).strftime("%Y-%m-%dT%H:%M:%SZ")
        
        try:
            # Fetch orders from Allegro API
            response = self.get(
                "sale/orders",
                params={"lineItemSentFrom": since_date}
            )
            
            orders_data = response.get("orders", [])
            self.logger.info(f"Fetched {len(orders_data)} orders from Allegro")
            
            # Process orders
            created = 0
            updated = 0
            failed = 0
            details = []
            
            for order_data in orders_data:
                try:
                    # Extract order info
                    order_number = order_data.get("id")
                    if not order_number:
                        raise ValueError("Missing order id")
                    
                    # Look for existing order
                    order = Order.query.filter_by(order_number=f"allegro-{order_number}").first()
                    
                    # Map Allegro status to our status
                    status_map = {
                        "NEW": OrderStatus.NEW,
                        "READY_FOR_PROCESSING": OrderStatus.NEW,
                        "PROCESSING": OrderStatus.PAID,
                        "COMPLETED": OrderStatus.SHIPPED,
                        "CANCELLED": OrderStatus.CANCELLED,
                        # Add more mappings as needed
                    }
                    
                    allegro_status = order_data.get("status", "NEW")
                    status = status_map.get(allegro_status, OrderStatus.NEW)
                    
                    # Extract financials
                    summary = order_data.get("summary", {})
                    total_amount = float(summary.get("totalToPay", {}).get("amount", 0))
                    shipping_data = summary.get("shipmentSummary", {})
                    shipping_amount = float(shipping_data.get("shippingPrice", {}).get("amount", 0))
                    
                    # Calculate tax amount (may need adjustment based on actual API response)
                    tax_amount = 0.0  # Default
                    
                    # Extract shipping info
                    delivery = order_data.get("delivery", {})
                    address = delivery.get("address", {})
                    shipping_info = {
                        "name": f"{address.get('firstName', '')} {address.get('lastName', '')}".strip(),
                        "address": address.get("street"),
                        "city": address.get("city"),
                        "postal_code": address.get("zipCode"),
                        "country": address.get("countryCode", "PL"),
                        "phone": delivery.get("phoneNumber"),
                        "email": order_data.get("buyer", {}).get("email")
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
                        order.tracking_number = delivery.get("trackingNumber")
                        
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
                            order_number=f"allegro-{order_number}",
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
                            payment_method=order_data.get("payment", {}).get("type"),
                            payment_reference=order_data.get("payment", {}).get("id"),
                            shipping_method=delivery.get("method", {}).get("name"),
                            tracking_number=delivery.get("trackingNumber"),
                            notes="Imported from Allegro"
                        )
                        
                        # Process order items
                        line_items = order_data.get("lineItems", [])
                        for item_data in line_items:
                            offer = item_data.get("offer", {})
                            external_id = offer.get("external", {}).get("id")
                            if not external_id:
                                continue
                                
                            # Find product by SKU (external id)
                            product = Product.query.filter_by(sku=external_id).first()
                            if not product:
                                self.logger.warning(f"Product with SKU {external_id} not found")
                                continue
                                
                            # Create order item
                            price_data = item_data.get("price", {})
                            item = OrderItem(
                                product_id=product.id,
                                quantity=int(item_data.get("quantity", 1)),
                                price=float(price_data.get("amount", 0)),
                                variant_info=offer.get("parameters", {})
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
                    self.logger.error(f"Failed to process Allegro order {order_data.get('id')}: {str(e)}")
                    failed += 1
                    details.append({
                        "order_number": f"allegro-{order_data.get('id')}",
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
            self.logger.error(f"Error fetching orders from Allegro: {str(e)}")
            raise APIError(f"Failed to fetch Allegro orders: {str(e)}")
    
    def push_stock(self, products: List[Product]) -> Dict[str, Any]:
        """
        Push stock updates to Allegro marketplace.
        
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
            # Allegro requires individual update for each offer
            for product in products:
                try:
                    # Get offer details by SKU
                    offers_response = self.get(
                        "sale/offers",
                        params={"external.id": product.sku}
                    )
                    
                    offers = offers_response.get("offers", [])
                    if not offers:
                        failed_count += 1
                        details.append({
                            "sku": product.sku,
                            "status": "failed",
                            "error": "Offer not found"
                        })
                        continue
                    
                    offer_id = offers[0].get("id")
                    
                    # Update stock for the offer
                    update_response = self.put(
                        f"sale/offers/{offer_id}/stock",
                        json_data={
                            "stock": {
                                "available": product.quantity,
                                "unit": "UNIT"
                            }
                        }
                    )
                    
                    # Check response
                    if update_response.get("stock", {}).get("available") == product.quantity:
                        success_count += 1
                        details.append({
                            "sku": product.sku,
                            "status": "success"
                        })
                    else:
                        failed_count += 1
                        details.append({
                            "sku": product.sku,
                            "status": "failed",
                            "error": "Stock update failed"
                        })
                except Exception as e:
                    failed_count += 1
                    details.append({
                        "sku": product.sku,
                        "status": "failed",
                        "error": str(e)
                    })
            
            return {
                "success": success_count,
                "failed": failed_count,
                "details": details
            }
        except Exception as e:
            self.logger.error(f"Error updating stock in Allegro: {str(e)}")
            raise APIError(f"Failed to update stock in Allegro: {str(e)}") 