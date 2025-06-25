"""Context processors for the application."""
from datetime import datetime
from flask import current_app
from app import get_locale
from app.models.settings import CompanySettings
from sqlalchemy.exc import SQLAlchemyError
from app.extensions import db

def inject_template_globals():
    """Inject global variables into templates."""
    # Get company settings (without a database query if possible)
    company_settings = None
    try:
        company_settings = CompanySettings.get_instance()
    except SQLAlchemyError as e:
        current_app.logger.error(f"Error retrieving company settings: {str(e)}")
        # Rollback the session to clear the failed transaction
        db.session.rollback()
    except Exception as e:
        current_app.logger.error(f"Unexpected error in context processor: {str(e)}")
        # Rollback the session to be safe
        db.session.rollback()

    return {
        'now': datetime.now(),
        'get_locale': get_locale,
        'csrf_token': lambda: '',
        'company_settings': company_settings
    } 