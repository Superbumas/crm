"""Celery tasks module."""
import logging
from datetime import datetime, timedelta
from celery.exceptions import MaxRetriesExceededError
from .celery_worker import celery
from .services.accounting import record_order_accounting
from .clients.pigu_client import PiguClient
from .clients.varle_client import VarleClient
from .clients.allegro_client import AllegroClient
from .models.integration import IntegrationSyncLog, IntegrationType, SyncStatus
from .models.product import Product
from .extensions import db


@celery.task(name="lt_crm.app.tasks.example_task")
def example_task(param=None):
    """Example task that can be scheduled via Celery."""
    return f"Task completed with parameter: {param}"


@celery.task(name="lt_crm.app.tasks.send_notification")
def send_notification(user_id, message):
    """Send a notification to a user."""
    # This would connect to a notification service
    # or send an email in a real implementation
    return f"Notification sent to user {user_id}: {message}"


@celery.task(name="lt_crm.app.tasks.process_order_accounting")
def process_order_accounting(order_id):
    """
    Process accounting entries for an order.
    
    Args:
        order_id (int): Order ID to process
        
    Returns:
        str: Processing result
    """
    try:
        transaction = record_order_accounting(order_id)
        if transaction:
            return f"Accounting entries created for order {order_id}, transaction ID: {transaction.id}"
        else:
            return f"Order {order_id} is not in 'paid' status, no entries created"
    except Exception as e:
        return f"Error processing accounting for order {order_id}: {str(e)}"


@celery.task(bind=True, name="lt_crm.app.tasks.sync_pigu_orders", max_retries=3, default_retry_delay=300)
def sync_pigu_orders(self):
    """
    Fetch and sync orders from Pigu marketplace.
    
    Returns:
        str: Sync result message
    """
    log = IntegrationSyncLog(
        integration_type=IntegrationType.ECOMMERCE,
        provider_name="pigu",
        entity_type="order",
        status=SyncStatus.IN_PROGRESS,
        started_at=datetime.utcnow()
    )
    db.session.add(log)
    db.session.commit()
    
    try:
        client = PiguClient()
        result = client.fetch_orders()
        
        log.records_processed = result.get("total", 0)
        log.records_created = result.get("created", 0)
        log.records_updated = result.get("updated", 0)
        log.records_failed = result.get("failed", 0)
        log.status = SyncStatus.SUCCESS
        log.log_data = result.get("details")
        log.completed_at = datetime.utcnow()
        
        db.session.add(log)
        db.session.commit()
        
        return f"Pigu orders sync completed: {log.records_created} created, {log.records_updated} updated"
    except Exception as e:
        log.status = SyncStatus.FAILED
        log.error_message = str(e)
        log.completed_at = datetime.utcnow()
        db.session.add(log)
        db.session.commit()
        
        try:
            self.retry(exc=e)
        except MaxRetriesExceededError:
            return f"Pigu orders sync failed after multiple retries: {str(e)}"
        
        return f"Pigu orders sync failed: {str(e)}"


@celery.task(bind=True, name="lt_crm.app.tasks.sync_varle_orders", max_retries=3, default_retry_delay=300)
def sync_varle_orders(self):
    """
    Fetch and sync orders from Varle marketplace.
    
    Returns:
        str: Sync result message
    """
    log = IntegrationSyncLog(
        integration_type=IntegrationType.ECOMMERCE,
        provider_name="varle",
        entity_type="order",
        status=SyncStatus.IN_PROGRESS,
        started_at=datetime.utcnow()
    )
    db.session.add(log)
    db.session.commit()
    
    try:
        client = VarleClient()
        result = client.fetch_orders()
        
        log.records_processed = result.get("total", 0)
        log.records_created = result.get("created", 0)
        log.records_updated = result.get("updated", 0)
        log.records_failed = result.get("failed", 0)
        log.status = SyncStatus.SUCCESS
        log.log_data = result.get("details")
        log.completed_at = datetime.utcnow()
        
        db.session.add(log)
        db.session.commit()
        
        return f"Varle orders sync completed: {log.records_created} created, {log.records_updated} updated"
    except Exception as e:
        log.status = SyncStatus.FAILED
        log.error_message = str(e)
        log.completed_at = datetime.utcnow()
        db.session.add(log)
        db.session.commit()
        
        try:
            self.retry(exc=e)
        except MaxRetriesExceededError:
            return f"Varle orders sync failed after multiple retries: {str(e)}"
        
        return f"Varle orders sync failed: {str(e)}"


@celery.task(bind=True, name="lt_crm.app.tasks.sync_allegro_orders", max_retries=3, default_retry_delay=300)
def sync_allegro_orders(self):
    """
    Fetch and sync orders from Allegro marketplace.
    
    Returns:
        str: Sync result message
    """
    log = IntegrationSyncLog(
        integration_type=IntegrationType.ECOMMERCE,
        provider_name="allegro",
        entity_type="order",
        status=SyncStatus.IN_PROGRESS,
        started_at=datetime.utcnow()
    )
    db.session.add(log)
    db.session.commit()
    
    try:
        client = AllegroClient()
        result = client.fetch_orders()
        
        log.records_processed = result.get("total", 0)
        log.records_created = result.get("created", 0)
        log.records_updated = result.get("updated", 0)
        log.records_failed = result.get("failed", 0)
        log.status = SyncStatus.SUCCESS
        log.log_data = result.get("details")
        log.completed_at = datetime.utcnow()
        
        db.session.add(log)
        db.session.commit()
        
        return f"Allegro orders sync completed: {log.records_created} created, {log.records_updated} updated"
    except Exception as e:
        log.status = SyncStatus.FAILED
        log.error_message = str(e)
        log.completed_at = datetime.utcnow()
        db.session.add(log)
        db.session.commit()
        
        try:
            self.retry(exc=e)
        except MaxRetriesExceededError:
            return f"Allegro orders sync failed after multiple retries: {str(e)}"
        
        return f"Allegro orders sync failed: {str(e)}"


@celery.task(bind=True, name="lt_crm.app.tasks.sync_stock_to_channels", max_retries=3, default_retry_delay=300)
def sync_stock_to_channels(self):
    """
    Sync product stock levels to all integrated marketplaces.
    
    Returns:
        str: Sync result message
    """
    log = IntegrationSyncLog(
        integration_type=IntegrationType.ECOMMERCE,
        provider_name="all",
        entity_type="stock",
        status=SyncStatus.IN_PROGRESS,
        started_at=datetime.utcnow()
    )
    db.session.add(log)
    db.session.commit()
    
    products = Product.query.all()
    
    channels = [
        ("pigu", PiguClient()),
        ("varle", VarleClient()),
        ("allegro", AllegroClient())
    ]
    
    results = {}
    total_success = 0
    total_failed = 0
    
    try:
        for channel_name, client in channels:
            channel_result = {
                "success": 0,
                "failed": 0,
                "details": []
            }
            
            try:
                result = client.push_stock(products)
                channel_result["success"] = result.get("success", 0)
                channel_result["failed"] = result.get("failed", 0)
                channel_result["details"] = result.get("details", [])
                
                total_success += channel_result["success"]
                total_failed += channel_result["failed"]
            except Exception as e:
                channel_result["failed"] = len(products)
                channel_result["error"] = str(e)
                total_failed += len(products)
            
            results[channel_name] = channel_result
        
        log.records_processed = len(products) * len(channels)
        log.records_updated = total_success
        log.records_failed = total_failed
        log.status = SyncStatus.SUCCESS if total_failed == 0 else SyncStatus.PARTIAL
        log.log_data = results
        log.completed_at = datetime.utcnow()
        
        db.session.add(log)
        db.session.commit()
        
        return f"Stock sync completed: {total_success} successful, {total_failed} failed across {len(channels)} channels"
    except Exception as e:
        log.status = SyncStatus.FAILED
        log.error_message = str(e)
        log.completed_at = datetime.utcnow()
        db.session.add(log)
        db.session.commit()
        
        try:
            self.retry(exc=e)
        except MaxRetriesExceededError:
            return f"Stock sync failed after multiple retries: {str(e)}"
        
        return f"Stock sync failed: {str(e)}"


@celery.task(name="lt_crm.app.tasks.cleanup_old_sync_logs")
def cleanup_old_sync_logs(days=30):
    """
    Clean up old integration sync logs.
    
    Args:
        days (int): Number of days to keep logs for
        
    Returns:
        int: Number of logs deleted
    """
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        logs = IntegrationSyncLog.query.filter(IntegrationSyncLog.created_at < cutoff_date).all()
        
        if not logs:
            return f"No sync logs older than {days} days found"
        
        count = len(logs)
        for log in logs:
            db.session.delete(log)
        
        db.session.commit()
        return f"Deleted {count} sync logs older than {days} days"
    except Exception as e:
        db.session.rollback()
        return f"Error cleaning up old sync logs: {str(e)}" 