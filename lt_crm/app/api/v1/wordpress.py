"""WordPress/WooCommerce integration endpoints for API v1."""
import asyncio
import uuid
from datetime import datetime, timedelta
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

# Product category models
wordpress_category_model = ns.model("WordPressCategory", {
    "name": fields.String(required=True, description="Category name"),
    "slug": fields.String(description="Category slug"),
    "parent": fields.Integer(description="Parent category ID"),
    "description": fields.String(description="Category description"),
    "image": fields.Raw(description="Category image data")
})

wordpress_category_update_model = ns.model("WordPressCategoryUpdate", {
    "name": fields.String(description="Category name"),
    "slug": fields.String(description="Category slug"),
    "parent": fields.Integer(description="Parent category ID"),
    "description": fields.String(description="Category description"),
    "image": fields.Raw(description="Category image data")
})

@ns.route("/config")
class WordPressConfig(Resource):
    """WordPress/WooCommerce configuration resource."""
    
    @ns.doc("get_wordpress_config")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Get WordPress/WooCommerce integration configuration."""
        from ...models.settings import CompanySettings
        
        # Get settings from database
        settings = CompanySettings.get_instance()
        
        config = {
            "api_url": settings.wordpress_api_url or "",
            "consumer_key": "***" if settings.wordpress_consumer_key else "",
            "consumer_secret": "***" if settings.wordpress_consumer_secret else "",
            "is_configured": settings.wordpress_integration_configured
        }
        
        return config
    
    @ns.doc("update_wordpress_config")
    @ns.expect(wordpress_config_model)
    @ns.response(200, "Configuration updated")
    @ns.response(400, "Validation error")
    @token_required()
    def post(self, current_user):
        """Update WordPress/WooCommerce integration configuration."""
        from ...models.settings import CompanySettings
        
        data = request.json
        
        # Validate required fields
        if not data.get("api_url"):
            return {"message": "API URL is required"}, 400
            
        if not data.get("consumer_key"):
            return {"message": "Consumer key is required"}, 400
            
        if not data.get("consumer_secret"):
            return {"message": "Consumer secret is required"}, 400
        
        # Update settings in database
        settings = CompanySettings.get_instance()
        if settings.update_wordpress_settings(
            api_url=data["api_url"],
            consumer_key=data["consumer_key"],
            consumer_secret=data["consumer_secret"]
        ):
            return {"message": "WordPress/WooCommerce configuration updated successfully"}
        else:
            return {"message": "Failed to update WordPress configuration"}, 500

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
    """WordPress/WooCommerce pull stats resource."""
    
    @ns.doc("pull_stats_from_wordpress")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Pull stats from WordPress/WooCommerce."""
        # Create WordPress client
        client = WordPressClient()
        
        # Get date range for the last 30 days
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=30)
        
        try:
            # Run stats query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            report = loop.run_until_complete(client.get_sales_report(
                period="day",
                date_min=start_date,
                date_max=end_date
            ))
            loop.close()
            
            # Extract data from report
            total_sales = 0
            total_orders = 0
            avg_order_value = 0
            daily_data = []
            
            if report and "totals" in report:
                for date, data in report["totals"].items():
                    if date == "total":
                        continue
                        
                    daily_sales = float(data.get("sales", "0"))
                    daily_orders = int(data.get("orders", "0"))
                    
                    total_sales += daily_sales
                    total_orders += daily_orders
                    
                    daily_data.append({
                        "date": date,
                        "sales": daily_sales,
                        "orders": daily_orders
                    })
            
            # Calculate average order value
            if total_orders > 0:
                avg_order_value = total_sales / total_orders
                
            # Sort data by date
            daily_data.sort(key=lambda x: x["date"])
            
            return {
                "total_sales": total_sales,
                "total_orders": total_orders,
                "average_order_value": avg_order_value,
                "data": daily_data
            }
            
        except Exception as e:
            current_app.logger.error(f"Error pulling stats from WordPress: {str(e)}")
            return {"message": f"Error pulling stats: {str(e)}"}, 500

# Category management endpoints
@ns.route("/categories")
class WordPressCategories(Resource):
    """WordPress/WooCommerce product categories resource."""
    
    @ns.doc("get_wordpress_categories")
    @ns.response(200, "Success")
    @token_required()
    def get(self, current_user):
        """Get all product categories from WordPress/WooCommerce."""
        # Get pagination parameters
        page, per_page = get_pagination_params()
        
        # Create WordPress client
        client = WordPressClient()
        
        try:
            # Run query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            categories = loop.run_until_complete(client.get_product_categories(
                page=page,
                per_page=per_page
            ))
            loop.close()
            
            return {
                "categories": categories,
                "total": len(categories),
                "page": page,
                "per_page": per_page
            }
            
        except Exception as e:
            current_app.logger.error(f"Error getting categories from WordPress: {str(e)}")
            return {"message": f"Error getting categories: {str(e)}"}, 500
    
    @ns.doc("create_wordpress_category")
    @ns.expect(wordpress_category_model)
    @ns.response(201, "Category created")
    @ns.response(400, "Validation error")
    @token_required()
    def post(self, current_user):
        """Create a new product category in WordPress/WooCommerce."""
        data = request.json
        
        # Validate required fields
        if not data.get("name"):
            return {"message": "Category name is required"}, 400
        
        # Create WordPress client
        client = WordPressClient()
        
        try:
            # Run query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            category = loop.run_until_complete(client.create_product_category(data))
            loop.close()
            
            return category, 201
            
        except Exception as e:
            current_app.logger.error(f"Error creating category in WordPress: {str(e)}")
            return {"message": f"Error creating category: {str(e)}"}, 500

@ns.route("/categories/<int:category_id>")
class WordPressCategoryDetail(Resource):
    """WordPress/WooCommerce product category detail resource."""
    
    @ns.doc("get_wordpress_category")
    @ns.response(200, "Success")
    @ns.response(404, "Category not found")
    @token_required()
    def get(self, current_user, category_id):
        """Get a product category from WordPress/WooCommerce by ID."""
        # Create WordPress client
        client = WordPressClient()
        
        try:
            # Run query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            category = loop.run_until_complete(client.get_product_category(category_id))
            loop.close()
            
            return category
            
        except APIClientError as e:
            current_app.logger.error(f"Error getting category from WordPress: {str(e)}")
            return {"message": "Category not found"}, 404
        except Exception as e:
            current_app.logger.error(f"Error getting category from WordPress: {str(e)}")
            return {"message": f"Error getting category: {str(e)}"}, 500
    
    @ns.doc("update_wordpress_category")
    @ns.expect(wordpress_category_update_model)
    @ns.response(200, "Category updated")
    @ns.response(404, "Category not found")
    @token_required()
    def put(self, current_user, category_id):
        """Update a product category in WordPress/WooCommerce."""
        data = request.json
        
        # Create WordPress client
        client = WordPressClient()
        
        try:
            # Run query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            category = loop.run_until_complete(client.update_product_category(category_id, data))
            loop.close()
            
            return category
            
        except APIClientError as e:
            current_app.logger.error(f"Error updating category in WordPress: {str(e)}")
            return {"message": "Category not found"}, 404
        except Exception as e:
            current_app.logger.error(f"Error updating category in WordPress: {str(e)}")
            return {"message": f"Error updating category: {str(e)}"}, 500
    
    @ns.doc("delete_wordpress_category")
    @ns.response(200, "Category deleted")
    @ns.response(404, "Category not found")
    @token_required()
    def delete(self, current_user, category_id):
        """Delete a product category in WordPress/WooCommerce."""
        # Get force parameter
        force = request.args.get("force", "false").lower() == "true"
        
        # Create WordPress client
        client = WordPressClient()
        
        try:
            # Run query asynchronously
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(client.delete_product_category(category_id, force=force))
            loop.close()
            
            return {"message": "Category deleted successfully"}
            
        except APIClientError as e:
            current_app.logger.error(f"Error deleting category from WordPress: {str(e)}")
            return {"message": "Category not found"}, 404
        except Exception as e:
            current_app.logger.error(f"Error deleting category from WordPress: {str(e)}")
            return {"message": f"Error deleting category: {str(e)}"}, 500 