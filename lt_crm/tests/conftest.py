"""Pytest configuration file."""
import pytest
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.user import User


@pytest.fixture
def app():
    """Create and configure a Flask app for testing."""
    app = create_app({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "WTF_CSRF_ENABLED": False,
    })

    with app.app_context():
        db.create_all()
        # Create a test user
        user = User(username="test_user", email="test@example.com")
        user.set_password("password")
        db.session.add(user)
        db.session.commit()
        
        yield app
        
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    """Create a test client for the app."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """Create a test CLI runner for the app."""
    return app.test_cli_runner()


@pytest.fixture
def auth(client):
    """Authentication helper for tests."""
    class AuthActions:
        def login(self, email="test@example.com", password="password"):
            return client.post(
                "/login",
                data={"email": email, "password": password},
                follow_redirects=True,
            )
            
        def logout(self):
            return client.get("/logout", follow_redirects=True)
            
    return AuthActions() 