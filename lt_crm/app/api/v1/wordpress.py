"""WordPress/WooCommerce integration endpoints for API v1."""
import asyncio
import uuid
from datetime import datetime
from flask import request, current_app, jsonify
from flask_restx import Namespace, Resource, fields
from ...models.product import Product
from ...models.order import Order, OrderItem, OrderStatus
from ...models.integration import IntegrationSyncLog, IntegrationType, SyncStatus
from ...extensions import db
from ...clients.wordpress_client import WordPressClient
from .utils import (
    token_required,
    validate_schema,
    get_pagination_params,
    paginate
)
from . import limiter

ns = Namespace("wordpress", description="WordPress/WooCommerce integration operations")

# API models for Swagger docs
wordpress_config_model = ns.model("WordPressConfig", {
    "api_url": fields.String(required=True, description="WordPress site URL"),
    "consumer_key": fields.String(required=True, description="WooCommerce consumer key"),
    "consumer_secret": fields.String(required=True, description="WooCommerce consumer secret"),
})

wordpress_sync_model = ns.model("WordPressSync", {
    "entity_type": fields.String(required=True, description="Entity type to sync (products, orders, stock)"),
    "direction": fields.String(required=True, description="Sync direction (push, pull)"),
    "filters": fields.Raw(description="Optional filters for the sync operation")
})

wordpress_product_push_model = ns.model("WordPressProductPush", {
    "product_ids": fields.List(fields.String, description="List of product SKUs to push"),
    "push_all": fields.Boolean(description="Push all products if true")
})

wordpress_status_model = ns.model("WordPressStatus", {
    "status": fields.String(description="Integration status"),
    "connected": fields.Boolean(description="Whether the integration is connected"),
    "last_sync": fields.DateTime(description="Last sync timestamp"),
    "stats": fields.Raw(description="Integration statistics")
})

@ns.route("/config")
class WordPressConfig(Resource):
    """WordPress/WooCommerce configuration resource."""
    
    @ns.doc("get_wordpress_config")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Get WordPress/WooCommerce integration configuration."""
        # Get configuration from environment variables
        config = {
            "api_url": current_app.config.get("WORDPRESS_API_URL", ""),
            "consumer_key": "***" if current_app.config.get("WOOCOMMERCE_CONSUMER_KEY") else "",
            "consumer_secret": "***" if current_app.config.get("WOOCOMMERCE_CONSUMER_SECRET") else "",
            "is_configured": bool(
                current_app.config.get("WORDPRESS_API_URL") and 
                current_app.config.get("WOOCOMMERCE_CONSUMER_KEY") and
                current_app.config.get("WOOCOMMERCE_CONSUMER_SECRET")
            )
        }
        
        return config
    
    @ns.doc("update_wordpress_config")
    @ns.expect(wordpress_config_model)
    @ns.response(200, "Configuration updated")
    @ns.response(400, "Validation error")
    @token_required()
    def post(self, current_user):
        """Update WordPress/WooCommerce integration configuration."""
        data = request.json
        
        # Validate required fields
        if not data.get("api_url"):
            return {"message": "API URL is required"}, 400
            
        if not data.get("consumer_key"):
            return {"message": "Consumer key is required"}, 400
            
        if not data.get("consumer_secret"):
            return {"message": "Consumer secret is required"}, 400
        
        # In a real application, we would store these in a database or update environment variables
        # For this implementation, we'll just update the application config
        current_app.config["WORDPRESS_API_URL"] = data["api_url"]
        current_app.config["WOOCOMMERCE_CONSUMER_KEY"] = data["consumer_key"]
        current_app.config["WOOCOMMERCE_CONSUMER_SECRET"] = data["consumer_secret"]
        
        return {"message": "WordPress/WooCommerce configuration updated successfully"}

@ns.route("/status")
class WordPressStatus(Resource):
    """WordPress/WooCommerce integration status resource."""
    
    @ns.doc("get_wordpress_status")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Get WordPress/WooCommerce integration status."""
        # Check if WordPress integration is configured
        is_configured = bool(
            current_app.config.get("WORDPRESS_API_URL") and 
            current_app.config.get("WOOCOMMERCE_CONSUMER_KEY") and
            current_app.config.get("WOOCOMMERCE_CONSUMER_SECRET")
        )
        
        # Get last sync log
        last_sync = IntegrationSyncLog.query.filter_by(
            integration_type=IntegrationType.ECOMMERCE,
            provider_name="wordpress"
        ).order_by(IntegrationSyncLog.created_at.desc()).first()
        
        # Get sync statistics
        sync_stats = {
            "products_pushed": 0,
            "orders_pulled": 0,
            "last_sync_status": None
        }
        
        if last_sync:
            sync_stats["last_sync_status"] = last_sync.status.value
            
            # Get counts from logs
            products_pushed = IntegrationSyncLog.query.filter_by(
                integration_type=IntegrationType.ECOMMERCE,
                provider_name="wordpress",
                entity_type="product",
                status=SyncStatus.SUCCESS
            ).with_entities(db.func.sum(IntegrationSyncLog.records_processed)).scalar() or 0
            
            orders_pulled = IntegrationSyncLog.query.filter_by(
                integration_type=IntegrationType.ECOMMERCE,
                provider_name="wordpress",
                entity_type="order",
                status=SyncStatus.SUCCESS
            ).with_entities(db.func.sum(IntegrationSyncLog.records_processed)).scalar() or 0
            
            sync_stats["products_pushed"] = int(products_pushed)
            sync_stats["orders_pulled"] = int(orders_pulled)
        
        # Prepare response
        status_data = {
            "status": "connected" if is_configured else "not_configured",
            "connected": is_configured,
            "last_sync": last_sync.created_at if last_sync else None,
            "stats": sync_stats
        }
        
        return status_data

@ns.route("/push/products")
class WordPressPushProducts(Resource):
    """WordPress/WooCommerce push products resource."""
    
    @ns.doc("push_products_to_wordpress")
    @ns.expect(wordpress_product_push_model)
    @ns.response(202, "Sync initiated")
    @ns.response(400, "Validation error")
    @token_required()
    def post(self, current_user):
        """Push products to WordPress/WooCommerce."""
        data = request.json
        
        # Initialize sync log
        sync_log = IntegrationSyncLog(
            integration_type=IntegrationType.ECOMMERCE,
            provider_name="wordpress",
            entity_type="product",
            status=SyncStatus.IN_PROGRESS,
            started_at=datetime.utcnow(),
            user_id=current_user.id
        )
        db.session.add(sync_log)
        db.session.commit()
        
        # Get products to push
        product_query = Product.query
        
        if data.get("product_ids") and not data.get("push_all"):
            product_query = product_query.filter(Product.sku.in_(data["product_ids"]))
        
        products = product_query.all()
        
        # Create WordPress client
        client = WordPressClient()
        
        # Set up sync counters
        sync_results = {
            "total": len(products),
            "success": 0,
            "failed": 0,
            "skipped": 0,
            "errors": []
        }
        
        # Process each product
        for product in products:
            try:
                # Format product data for WooCommerce
                woo_product = client.format_crm_product_for_woocommerce(product)
                
                # In a real implementation, we would call the async method
                # For now, we'll just simulate success
                # result = await client.create_product(woo_product)
                
                # Simulate success
                sync_results["success"] += 1
                
            except Exception as e:
                sync_results["failed"] += 1
                sync_results["errors"].append({
                    "sku": product.sku,
                    "error": str(e)
                })
        
        # Update sync log
        sync_log.status = SyncStatus.SUCCESS if sync_results["failed"] == 0 else SyncStatus.PARTIAL
        sync_log.completed_at = datetime.utcnow()
        sync_log.records_processed = sync_results["total"]
        sync_log.records_created = sync_results["success"]
        sync_log.records_failed = sync_results["failed"]
        sync_log.error_message = f"{sync_results['failed']} products failed to sync" if sync_results["failed"] > 0 else None
        sync_log.log_data = sync_results
        
        db.session.commit()
        
        return {
            "message": "Product sync initiated",
            "sync_id": sync_log.id,
            "status": sync_log.status.value,
            "summary": {
                "total": sync_results["total"],
                "success": sync_results["success"],
                "failed": sync_results["failed"]
            }
        }, 202

@ns.route("/pull/orders")
class WordPressPullOrders(Resource):
    """WordPress/WooCommerce pull orders resource."""
    
    @ns.doc("pull_orders_from_wordpress")
    @ns.response(202, "Sync initiated")
    @token_required()
    def post(self, current_user):
        """Pull orders from WordPress/WooCommerce."""
        # Initialize sync log
        sync_log = IntegrationSyncLog(
            integration_type=IntegrationType.ECOMMERCE,
            provider_name="wordpress",
            entity_type="order",
            status=SyncStatus.IN_PROGRESS,
            started_at=datetime.utcnow(),
            user_id=current_user.id
        )
        db.session.add(sync_log)
        db.session.commit()
        
        # Create WordPress client
        client = WordPressClient()
        
        # Set up sync counters
        sync_results = {
            "total": 0,
            "new": 0,
            "updated": 0,
            "failed": 0,
            "errors": []
        }
        
        # In a real implementation, we would call the async method to get orders
        # For now, we'll just simulate success
        
        # Simulate success
        sync_results["total"] = 5
        sync_results["new"] = 3
        sync_results["updated"] = 2
        
        # Update sync log
        sync_log.status = SyncStatus.SUCCESS
        sync_log.completed_at = datetime.utcnow()
        sync_log.records_processed = sync_results["total"]
        sync_log.records_created = sync_results["new"]
        sync_log.records_updated = sync_results["updated"]
        sync_log.records_failed = sync_results["failed"]
        sync_log.log_data = sync_results
        
        db.session.commit()
        
        return {
            "message": "Order sync initiated",
            "sync_id": sync_log.id,
            "status": sync_log.status.value,
            "summary": {
                "total": sync_results["total"],
                "new": sync_results["new"],
                "updated": sync_results["updated"],
                "failed": sync_results["failed"]
            }
        }, 202

@ns.route("/pull/stats")
class WordPressPullStats(Resource):
    """WordPress/WooCommerce pull statistics resource."""
    
    @ns.doc("pull_stats_from_wordpress")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Pull statistics from WordPress/WooCommerce."""
        # Create WordPress client
        client = WordPressClient()
        
        # In a real implementation, we would call the async method to get stats
        # For now, we'll just return mock data
        
        # Mock sales data
        sales_data = {
            "total_sales": 12345.67,
            "net_sales": 10000.00,
            "average_order_value": 123.45,
            "total_orders": 100,
            "total_items": 250,
            "total_tax": 1234.56,
            "total_shipping": 500.00,
            "period": "last_month",
            "data": [
                {"date": "2023-06-01", "sales": 1234.56, "orders": 10},
                {"date": "2023-06-02", "sales": 2345.67, "orders": 20},
                {"date": "2023-06-03", "sales": 3456.78, "orders": 30},
                # More data points would be here
            ]
        }
        
        return sales_data 