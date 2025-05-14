"""Custom Jinja2 filters for the application."""
from decimal import Decimal, InvalidOperation
from babel.numbers import format_currency


def euro(value):
    """Format a number as EUR currency."""
    if value is None:
        return "0,00 €"
    
    try:
        # Convert to Decimal if it's not already (handles str, float, int)
        if not isinstance(value, Decimal):
            # Make sure we have a proper string representation
            if isinstance(value, str):
                value = value.replace(',', '.')
            value = Decimal(str(value))
        
        return format_currency(value, "EUR", locale="lt_LT")
    except (InvalidOperation, ValueError, TypeError) as e:
        # Handle conversion errors gracefully
        #print(f"Error converting value '{value}' to currency: {str(e)}")
        return "0,00 €"


def register_filters(app):
    """Register custom filters with the Flask app."""
    app.jinja_env.filters["euro"] = euro 