"""Context processors for the application."""
from datetime import datetime
from flask import current_app
from lt_crm.app import get_locale

def inject_template_globals():
    """Inject global variables into templates."""
    return {
        'now': datetime.now(),
        'get_locale': get_locale,
        'csrf_token': lambda: ''
    } 