"""WordPress/WooCommerce API client."""
import os
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union
import httpx
from flask import current_app
from .base_client import BaseAPIClient
from ..exceptions import APIError, APIClientError
from ..models.order import Order, OrderItem, OrderStatus
from ..models.product import Product
from ..extensions import db


class WordPressClient(BaseAPIClient):
    """Client for WordPress/WooCommerce API integration."""

    def __init__(self):
        """Initialize the WordPress/WooCommerce API client."""
        from ..models.settings import CompanySettings
        
        # Get settings from database
        settings = CompanySettings.get_instance()
        
        base_url = settings.wordpress_api_url or ""
        if not base_url:
            self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
            self.logger.warning("WordPress API URL not configured in settings")
        
        self.consumer_key = settings.wordpress_consumer_key or ""
        self.consumer_secret = settings.wordpress_consumer_secret or ""
        
        if not self.consumer_key or not self.consumer_secret:
            self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
            self.logger.warning("WooCommerce API credentials not configured in settings")
        
        super().__init__(base_url=base_url)
    
    def _get_auth(self):
        """
        Get authentication for WooCommerce API.
        
        Returns:
            tuple: Authentication tuple (consumer_key, consumer_secret)
        """
        return (self.consumer_key, self.consumer_secret)
    
    async def request(self, method: str, endpoint: str, **kwargs) -> Any:
        """
        Make an API request to WooCommerce.
        
        Args:
            method: HTTP method
            endpoint: API endpoint (without base URL)
            **kwargs: Additional arguments to pass to the request
        
        Returns:
            Any: Response data
            
        Raises:
            APIClientError: If the request fails
        """
        url = f"{self.base_url}/wp-json/wc/v3/{endpoint.lstrip('/')}"
        headers = self._get_headers()
        
        # Add headers from kwargs if present
        if "headers" in kwargs:
            headers.update(kwargs.pop("headers"))
        
        self.logger.debug(f"Making {method} request to {url}")
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.request(
                    method,
                    url,
                    headers=headers,
                    auth=self._get_auth(),
                    **kwargs
                )
                
                response.raise_for_status()
                return response.json()
        except httpx.HTTPStatusError as e:
            error_data = {}
            try:
                error_data = e.response.json()
            except:
                pass
            
            error_message = error_data.get("message", str(e))
            self.logger.error(f"API error: {error_message}")
            raise APIClientError(f"WooCommerce API error: {error_message}")
        except httpx.RequestError as e:
            self.logger.error(f"Request failed: {str(e)}")
            raise APIClientError(f"WooCommerce request failed: {str(e)}")
    
    async def get_products(self, page: int = 1, per_page: int = 50) -> List[Dict]:
        """
        Get products from WooCommerce.
        
        Args:
            page: Page number
            per_page: Number of products per page
        
        Returns:
            List[Dict]: List of products
        """
        return await self.request(
            "GET", 
            "/products", 
            params={"page": page, "per_page": per_page}
        )
    
    async def get_product(self, product_id: Union[int, str]) -> Dict:
        """
        Get a product from WooCommerce by ID.
        
        Args:
            product_id: Product ID
        
        Returns:
            Dict: Product data
        """
        return await self.request("GET", f"/products/{product_id}")
    
    async def create_product(self, product_data: Dict) -> Dict:
        """
        Create a product in WooCommerce.
        
        Args:
            product_data: Product data
        
        Returns:
            Dict: Created product data
        """
        return await self.request("POST", "/products", json=product_data)
    
    async def update_product(self, product_id: Union[int, str], product_data: Dict) -> Dict:
        """
        Update a product in WooCommerce.
        
        Args:
            product_id: Product ID
            product_data: Product data to update
        
        Returns:
            Dict: Updated product data
        """
        return await self.request("PUT", f"/products/{product_id}", json=product_data)
    
    async def delete_product(self, product_id: Union[int, str], force: bool = False) -> Dict:
        """
        Delete a product in WooCommerce.
        
        Args:
            product_id: Product ID
            force: Whether to permanently delete the product
        
        Returns:
            Dict: Deleted product data
        """
        return await self.request(
            "DELETE", 
            f"/products/{product_id}", 
            params={"force": force}
        )
    
    async def get_orders(
        self, 
        status: Optional[str] = None,
        after: Optional[datetime] = None,
        before: Optional[datetime] = None,
        page: int = 1, 
        per_page: int = 50
    ) -> List[Dict]:
        """
        Get orders from WooCommerce.
        
        Args:
            status: Order status
            after: Get orders after this date
            before: Get orders before this date
            page: Page number
            per_page: Number of orders per page
        
        Returns:
            List[Dict]: List of orders
        """
        params = {"page": page, "per_page": per_page}
        
        if status:
            params["status"] = status
            
        if after:
            params["after"] = after.isoformat()
            
        if before:
            params["before"] = before.isoformat()
            
        return await self.request("GET", "/orders", params=params)
    
    async def get_order(self, order_id: Union[int, str]) -> Dict:
        """
        Get an order from WooCommerce by ID.
        
        Args:
            order_id: Order ID
        
        Returns:
            Dict: Order data
        """
        return await self.request("GET", f"/orders/{order_id}")
    
    async def update_order(self, order_id: Union[int, str], order_data: Dict) -> Dict:
        """
        Update an order in WooCommerce.
        
        Args:
            order_id: Order ID
            order_data: Order data to update
        
        Returns:
            Dict: Updated order data
        """
        return await self.request("PUT", f"/orders/{order_id}", json=order_data)
    
    async def get_sales_report(
        self, 
        period: str = "month", 
        date_min: Optional[datetime] = None,
        date_max: Optional[datetime] = None
    ) -> Dict:
        """
        Get sales report from WooCommerce.
        
        Args:
            period: Report period (day, week, month, year)
            date_min: Start date
            date_max: End date
        
        Returns:
            Dict: Sales report data
        """
        params = {"period": period}
        
        if date_min:
            params["date_min"] = date_min.strftime("%Y-%m-%d")
            
        if date_max:
            params["date_max"] = date_max.strftime("%Y-%m-%d")
            
        return await self.request("GET", "/reports/sales", params=params)
    
    def format_crm_product_for_woocommerce(self, product: Product) -> Dict:
        """
        Format a CRM product for WooCommerce API.
        
        Args:
            product: CRM product model
        
        Returns:
            Dict: Formatted product data for WooCommerce
        """
        # Convert parameters to WooCommerce attributes
        attributes = []
        if product.parameters:
            params = product.get_parameters()
            for key, value in params.items():
                attributes.append({
                    "name": key,
                    "position": 0,
                    "visible": True,
                    "variation": False,
                    "options": [str(value)]
                })
        
        # Format product data
        product_data = {
            "name": product.name,
            "type": "simple",
            "regular_price": str(product.price_final),
            "description": product.description_html or "",
            "short_description": "",
            "sku": product.sku,
            "manage_stock": True,
            "stock_quantity": product.quantity,
            "categories": [{"name": product.category}] if product.category else [],
            "attributes": attributes,
            "meta_data": [
                {"key": "barcode", "value": product.barcode or ""},
                {"key": "manufacturer", "value": product.manufacturer or ""},
                {"key": "model", "value": product.model or ""},
                {"key": "delivery_days", "value": product.delivery_days or 0},
                {"key": "warranty_months", "value": product.warranty_months or 0},
                {"key": "weight_kg", "value": str(product.weight_kg) if product.weight_kg else ""}
            ]
        }
        
        # Handle images
        images = []
        if product.main_image_url:
            images.append({"src": product.main_image_url, "position": 0})
            
        if product.extra_image_urls:
            for i, url in enumerate(product.extra_image_urls, start=1):
                images.append({"src": url, "position": i})
                
        if images:
            product_data["images"] = images
            
        # Handle sale price
        if product.price_old and product.price_old > product.price_final:
            product_data["sale_price"] = str(product.price_final)
            product_data["regular_price"] = str(product.price_old)
            
        return product_data
    
    def convert_woo_order_to_crm(self, woo_order: Dict) -> Dict:
        """
        Convert a WooCommerce order to CRM order format.
        
        Args:
            woo_order: WooCommerce order data
        
        Returns:
            Dict: CRM order data
        """
        # Map WooCommerce status to CRM status
        status_map = {
            "pending": OrderStatus.NEW,
            "processing": OrderStatus.IN_PROGRESS,
            "on-hold": OrderStatus.PENDING,
            "completed": OrderStatus.COMPLETED,
            "cancelled": OrderStatus.CANCELLED,
            "refunded": OrderStatus.CANCELLED,
            "failed": OrderStatus.CANCELLED
        }
        
        # Get billing and shipping info
        billing = woo_order.get("billing", {})
        shipping = woo_order.get("shipping", {})
        
        # Format customer data
        customer_data = {
            "name": f"{billing.get('first_name', '')} {billing.get('last_name', '')}".strip(),
            "email": billing.get("email", ""),
            "phone": billing.get("phone", ""),
            "address": f"{billing.get('address_1', '')} {billing.get('address_2', '')}".strip(),
            "city": billing.get("city", ""),
            "postal_code": billing.get("postcode", ""),
            "country": billing.get("country", ""),
            "company": billing.get("company", "")
        }
        
        # Format shipping data
        shipping_data = None
        if shipping:
            shipping_data = {
                "name": f"{shipping.get('first_name', '')} {shipping.get('last_name', '')}".strip(),
                "address": f"{shipping.get('address_1', '')} {shipping.get('address_2', '')}".strip(),
                "city": shipping.get("city", ""),
                "postal_code": shipping.get("postcode", ""),
                "country": shipping.get("country", ""),
                "company": shipping.get("company", "")
            }
        
        # Format order items
        items = []
        for item in woo_order.get("line_items", []):
            items.append({
                "sku": item.get("sku", ""),
                "name": item.get("name", ""),
                "quantity": item.get("quantity", 0),
                "price": item.get("price", 0),
                "total": item.get("total", 0)
            })
        
        # Format order data
        order_data = {
            "external_id": str(woo_order.get("id", "")),
            "external_reference": woo_order.get("number", ""),
            "status": status_map.get(woo_order.get("status", ""), OrderStatus.NEW),
            "order_date": woo_order.get("date_created", ""),
            "total": woo_order.get("total", 0),
            "shipping_cost": woo_order.get("shipping_total", 0),
            "tax": woo_order.get("total_tax", 0),
            "notes": woo_order.get("customer_note", ""),
            "payment_method": woo_order.get("payment_method_title", ""),
            "shipping_method": ", ".join([
                method.get("method_title", "") 
                for method in woo_order.get("shipping_lines", [])
            ]),
            "channel": "woocommerce",
            "customer": customer_data,
            "shipping": shipping_data,
            "items": items
        }
        
        return order_data 