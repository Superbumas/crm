"""Celery configuration module."""
import os

from celery import Celery


def make_celery(app_name=__name__):
    """Create a Celery instance."""
    broker_url = os.environ.get("CELERY_BROKER_URL", "redis://localhost:6379/1")
    result_backend = os.environ.get("CELERY_RESULT_BACKEND", "redis://localhost:6379/1")

    celery = Celery(
        app_name,
        broker=broker_url,
        result_backend=result_backend,
        include=["app.tasks"],
    )

    # Load additional configuration from Flask app if needed
    celery.conf.update(
        result_expires=3600,  # Task results expire after 1 hour
        task_serializer="json",
        accept_content=["json"],
        result_serializer="json",
        timezone=os.environ.get("BABEL_DEFAULT_TIMEZONE", "Europe/Vilnius"),
        enable_utc=True,
        worker_prefetch_multiplier=1,
        worker_max_tasks_per_child=1000,
        # Beat scheduler settings
        beat_schedule={},  # Will be set by Flask app
        beat_max_loop_interval=300,  # 5 minutes
    )

    return celery


# Create celery instance
celery = make_celery()


# Define a function to initialize Celery with Flask app context
def init_celery(app):
    """Initialize Celery with Flask app context."""
    celery.conf.update(app.config)

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery 