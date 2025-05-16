"""Flask application package."""
import os
import sentry_sdk
from flask import Flask, request, g
from flask_talisman import Talisman
from prometheus_flask_exporter import PrometheusMetrics
from sentry_sdk.integrations.flask import FlaskIntegration
from flask_wtf.csrf import CSRFProtect
from .extensions import db, migrate, login_manager, babel, minify, csrf
from .celery_worker import init_celery
from .celery_beat import register_beat_schedule
import json
from decimal import Decimal


# Custom JSON encoder to handle Decimal objects
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(CustomJSONEncoder, self).default(obj)


def get_locale():
    """Get the locale for the current request."""
    # user = getattr(g, 'user', None)
    # if user is not None:
    #     return user.locale
    return request.accept_languages.best_match(['en', 'lt'])


# Initialize security headers
csp = {
    'default-src': ['\'self\''],
    'style-src': ['\'self\'', '\'unsafe-inline\'', 'fonts.googleapis.com', 'cdn.jsdelivr.net'],
    'script-src': ['\'self\'', '\'unsafe-inline\'', '\'unsafe-eval\'', 'cdn.jsdelivr.net'],
    'font-src': ['\'self\'', 'fonts.gstatic.com', 'cdn.jsdelivr.net'],
    'img-src': ['\'self\'', 'data:'],
}

talisman = Talisman(content_security_policy=csp, content_security_policy_nonce_in=['script-src'])


def init_database(app):
    """Initialize database tables if they don't exist."""
    with app.app_context():
        # Check if we can connect to the database
        try:
            # Check if a key table exists
            from sqlalchemy import inspect
            inspector = inspect(db.engine)
            has_tables = inspector.get_table_names()
            
            if not has_tables:
                app.logger.info("No tables found in database - creating all tables")
                db.create_all()
                app.logger.info("Database tables created successfully")
                
                # Set up initial required data
                from .services.accounting import setup_default_accounts
                setup_default_accounts()
                app.logger.info("Default accounting accounts created")
                
                # Create default company settings
                from .models.settings import CompanySettings
                CompanySettings.get_instance()
                app.logger.info("Default company settings created")
                
                return True
            else:
                app.logger.info(f"Database has {len(has_tables)} tables - no initialization needed")
                return False
        except Exception as e:
            app.logger.error(f"Error during database initialization: {str(e)}")
            return False


def create_app(test_config=None):
    """Create and configure an instance of the Flask application."""
    app = Flask(__name__, instance_relative_config=True)

    # Set the custom JSON encoder
    app.json_encoder = CustomJSONEncoder

    # Load configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get("SECRET_KEY", "dev"),
        SQLALCHEMY_DATABASE_URI=os.environ.get(
            "DATABASE_URL", "postgresql://postgres:password@localhost:5432/lt_crm"
        ),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        BABEL_DEFAULT_LOCALE=os.environ.get("BABEL_DEFAULT_LOCALE", "lt"),
        BABEL_DEFAULT_TIMEZONE=os.environ.get("BABEL_DEFAULT_TIMEZONE", "Europe/Vilnius"),
        JWT_SECRET_KEY=os.environ.get("JWT_SECRET_KEY", "jwt-secret-key"),
        JWT_ACCESS_TOKEN_EXPIRES=int(os.environ.get("JWT_ACCESS_TOKEN_EXPIRES", 3600)),  # 1 hour
        JWT_REFRESH_TOKEN_EXPIRES=int(os.environ.get("JWT_REFRESH_TOKEN_EXPIRES", 2592000)),  # 30 days
        # Company information for invoices
        COMPANY_INFO={
            "name": os.environ.get("COMPANY_NAME", "LT CRM"),
            "address": os.environ.get("COMPANY_ADDRESS", "Gedimino pr. 1"),
            "city": os.environ.get("COMPANY_CITY", "Vilnius"),
            "postal_code": os.environ.get("COMPANY_POSTAL_CODE", "01103"),
            "country": os.environ.get("COMPANY_COUNTRY", "Lietuva"),
            "phone": os.environ.get("COMPANY_PHONE", "+370 600 00000"),
            "email": os.environ.get("COMPANY_EMAIL", "info@ltcrm.lt"),
            "company_code": os.environ.get("COMPANY_CODE", "123456789"),
            "vat_code": os.environ.get("COMPANY_VAT_CODE", "LT123456789"),
            "bank_name": os.environ.get("COMPANY_BANK_NAME", "SEB bankas"),
            "bank_account": os.environ.get("COMPANY_BANK_ACCOUNT", "LT123456789012345678"),
            "bank_swift": os.environ.get("COMPANY_BANK_SWIFT", "CBVILT2X"),
        },
        # Disable CSRF protection
        WTF_CSRF_ENABLED=False
    )

    if test_config:
        app.config.update(test_config)

    # Initialize Sentry for error tracking (only in production)
    if not app.debug and not app.testing and os.environ.get("SENTRY_DSN"):
        sentry_sdk.init(
            dsn=os.environ.get("SENTRY_DSN"),
            integrations=[FlaskIntegration()],
            traces_sample_rate=0.2,
            send_default_pii=False,
            environment=os.environ.get("FLASK_ENV", "production"),
        )

    # Initialize Prometheus metrics
    metrics = PrometheusMetrics(app, path='/metrics')
    metrics.info('app_info', 'LT CRM Application Info', version='1.0.0')

    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    csrf.init_app(app)
    minify.init_app(app)
    
    # Configure login
    login_manager.login_view = "auth.login"
    login_manager.login_message = "Please log in to access this page."
    
    # Configure Babel
    babel.init_app(app, locale_selector=get_locale)

    # Register template context processors
    from .context_processors import inject_template_globals
    app.context_processor(inject_template_globals)

    # Enable HTTPS security headers in production
    if not app.debug and not app.testing:
        talisman.init_app(app)

    # Initialize database tables if they don't exist
    init_database(app)

    # Register Celery
    init_celery(app)
    register_beat_schedule(app)

    # Register blueprints
    from .auth import bp as auth_bp
    from .main import bp as main_bp
    from .api import bp as api_bp
    from .api.v1 import bp as api_v1_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(main_bp)
    app.register_blueprint(api_bp, url_prefix="/api")
    app.register_blueprint(api_v1_bp, url_prefix="/api/v1")

    # Initialize limiter for API v1
    from .api.v1 import limiter
    limiter.init_app(app)

    # Register CLI commands
    from .cli import register_commands
    register_commands(app)

    # Register custom Jinja2 filters
    from .filters import register_filters
    register_filters(app)

    # Ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    # Health check endpoint
    @app.route("/health")
    def health_check():
        """Health check endpoint."""
        return {"status": "ok", "version": "1.0.0"}

    return app
