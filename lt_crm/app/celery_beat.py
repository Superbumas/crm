"""Celery Beat scheduler configuration."""
from celery.schedules import crontab


CELERYBEAT_SCHEDULE = {
    # Order sync tasks - run at different times to avoid overloading
    'sync-pigu-orders': {
        'task': 'app.tasks.sync_pigu_orders',
        'schedule': crontab(minute='0', hour='*/2'),  # Every 2 hours
        'args': (),
    },
    'sync-varle-orders': {
        'task': 'app.tasks.sync_varle_orders',
        'schedule': crontab(minute='30', hour='*/2'),  # Every 2 hours at :30
        'args': (),
    },
    'sync-allegro-orders': {
        'task': 'app.tasks.sync_allegro_orders',
        'schedule': crontab(minute='15', hour='*/2'),  # Every 2 hours at :15
        'args': (),
    },
    
    # Stock sync task - run every hour
    'sync-stock-to-channels': {
        'task': 'app.tasks.sync_stock_to_channels',
        'schedule': crontab(minute='45', hour='*'),  # Every hour at :45
        'args': (),
    },
    
    # Cleanup task to remove old sync logs - run once daily
    'cleanup-old-sync-logs': {
        'task': 'app.tasks.cleanup_old_sync_logs',
        'schedule': crontab(minute='0', hour='3'),  # 3:00 AM
        'args': (30,),  # Keep logs for 30 days
    },
}


def register_beat_schedule(app):
    """Register Celery Beat schedule with the Flask app."""
    app.config['CELERYBEAT_SCHEDULE'] = CELERYBEAT_SCHEDULE
    app.config['CELERY_TIMEZONE'] = app.config.get('BABEL_DEFAULT_TIMEZONE', 'Europe/Vilnius') 