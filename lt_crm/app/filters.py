"""Custom Jinja2 filters for the application."""
from babel.numbers import format_currency


def euro(value):
    """Format a number as EUR currency."""
    if value is None:
        return "0,00 €"
    return format_currency(value, "EUR", locale="lt_LT")


def register_filters(app):
    """Register custom filters with the Flask app."""
    app.jinja_env.filters["euro"] = euro 