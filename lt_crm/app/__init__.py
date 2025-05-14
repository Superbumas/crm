"""Flask application package."""
import os
import sentry_sdk
from flask import Flask, request, g
from flask_talisman import Talisman
from prometheus_flask_exporter import PrometheusMetrics
from sentry_sdk.integrations.flask import FlaskIntegration
from .extensions import db, migrate, login_manager, babel
from .celery_worker import init_celery
from .celery_beat import register_beat_schedule


# Initialize Talisman but defer application until inside create_app
talisman = Talisman(content_security_policy={
    'default-src': "'self'",
    'style-src': "'self' 'unsafe-inline' https://cdn.jsdelivr.net",
    'script-src': "'self' 'unsafe-inline' https://cdn.tailwindcss.com",
    'img-src': "'self' data:",
    'font-src': "'self' https://cdn.jsdelivr.net",
},
    frame_options='DENY',
    session_cookie_secure=True,
    session_cookie_http_only=True,
    force_https=True,
    strict_transport_security=True,
    referrer_policy='strict-origin-when-cross-origin'
)


def get_locale():
    """Get the locale for the current request."""
    # Try to get locale from request arguments
    locale = request.args.get('locale')
    if locale:
        return locale
    
    # Use browser's accept-languages header
    return request.accept_languages.best_match(['en', 'lt'])


def create_app(test_config=None):
    """Create and configure an instance of the Flask application."""
    app = Flask(__name__, instance_relative_config=True)

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