"""Tests for API v1."""
import json
import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.user import User
from lt_crm.app.models.product import Product
from lt_crm.app.models.order import Order, OrderItem, OrderStatus
from lt_crm.app.models.invoice import Invoice, InvoiceStatus
from lt_crm.app.api.v1.utils import generate_jwt_token

@pytest.fixture
def app():
    """Create and configure a Flask app for testing."""
    app = create_app({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "SQLALCHEMY_TRACK_MODIFICATIONS": False,
        "JWT_SECRET_KEY": "test-key",
        "JWT_ACCESS_TOKEN_EXPIRES": 300,  # 5 minutes
        "JWT_REFRESH_TOKEN_EXPIRES": 3600,  # 1 hour
    })

    # Create tables
    with app.app_context():
        db.create_all()
        
        # Create test user
        test_user = User(
            username="testuser",
            email="test@example.com",
            is_active=True,
            is_admin=True
        )
        test_user.set_password("password")
        db.session.add(test_user)
        
        # Create test product
        test_product = Product(
            sku="TEST-001",
            name="Test Product",
            description_html="<p>Test description</p>",
            quantity=100,
            price_final=Decimal("29.99"),
        )
        db.session.add(test_product)
        
        # Create test order
        test_order = Order(
            order_number="ORD-20230101-0001",
            status=OrderStatus.NEW,
            total_amount=Decimal("29.99"),
            shipping_name="Test Customer",
            shipping_address="Test Address",
            shipping_city="Test City",
            shipping_email="customer@example.com"
        )
        db.session.add(test_order)
        
        # Create test order item
        test_order_item = OrderItem(
            order=test_order,
            product=test_product,
            quantity=1,
            price=Decimal("29.99")
        )
        db.session.add(test_order_item)
        
        # Create test invoice
        test_invoice = Invoice(
            invoice_number="INV-20230101-0001",
            order_id=1,
            status=InvoiceStatus.ISSUED,
            issue_date=datetime.now().date(),
            due_date=(datetime.now() + timedelta(days=14)).date(),
            total_amount=Decimal("29.99"),
            billing_name="Test Customer",
            billing_address="Test Address",
            billing_city="Test City",
            billing_email="customer@example.com"
        )
        db.session.add(test_invoice)
        
        db.session.commit()

    yield app

    with app.app_context():
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()

@pytest.fixture
def auth_headers(app):
    """Create authentication headers for API requests."""
    with app.app_context():
        token = generate_jwt_token(1, "access")
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        return headers

def test_login(client):
    """Test user login endpoint."""
    response = client.post(
        "/api/v1/auth/login",
        data=json.dumps({"username": "testuser", "password": "password"}),
        content_type="application/json"
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"

def test_get_products(client, auth_headers):
    """Test getting products list."""
    response = client.get(
        "/api/v1/products/",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "items" in data
    assert len(data["items"]) == 1
    assert data["items"][0]["sku"] == "TEST-001"
    assert data["items"][0]["name"] == "Test Product"
    assert data["items"][0]["price_final"] == "29.99"

def test_get_product_by_sku(client, auth_headers):
    """Test getting a product by SKU."""
    response = client.get(
        "/api/v1/products/TEST-001",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["sku"] == "TEST-001"
    assert data["name"] == "Test Product"
    assert data["price_final"] == "29.99"

def test_create_product(client, auth_headers):
    """Test creating a new product."""
    response = client.post(
        "/api/v1/products/",
        data=json.dumps({
            "sku": "TEST-002",
            "name": "New Test Product",
            "description_html": "<p>New product description</p>",
            "quantity": 50,
            "price_final": "39.99"
        }),
        headers=auth_headers
    )
    
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data["sku"] == "TEST-002"
    assert data["name"] == "New Test Product"
    assert data["price_final"] == "39.99"

def test_update_product(client, auth_headers):
    """Test updating a product."""
    response = client.put(
        "/api/v1/products/TEST-001",
        data=json.dumps({
            "sku": "TEST-001",
            "name": "Updated Test Product",
            "price_final": "49.99"
        }),
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["sku"] == "TEST-001"
    assert data["name"] == "Updated Test Product"
    assert data["price_final"] == "49.99"

def test_delete_product(client, auth_headers):
    """Test deleting a product."""
    response = client.delete(
        "/api/v1/products/TEST-001",
        headers=auth_headers
    )
    
    assert response.status_code == 204
    
    # Verify product is deleted
    response = client.get(
        "/api/v1/products/TEST-001",
        headers=auth_headers
    )
    assert response.status_code == 404

def test_get_orders(client, auth_headers):
    """Test getting orders list."""
    response = client.get(
        "/api/v1/orders/",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert "items" in data
    assert len(data["items"]) == 1
    assert data["items"][0]["order_number"] == "ORD-20230101-0001"
    assert data["items"][0]["total_amount"] == "29.99"
    assert data["items"][0]["shipping_name"] == "Test Customer"

def test_get_order_by_id(client, auth_headers):
    """Test getting an order by ID."""
    response = client.get(
        "/api/v1/orders/1",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["order_number"] == "ORD-20230101-0001"
    assert data["total_amount"] == "29.99"
    assert data["shipping_name"] == "Test Customer"

def test_update_order_status(client, auth_headers):
    """Test updating order status."""
    response = client.patch(
        "/api/v1/orders/1/status",
        data=json.dumps({
            "status": "paid"
        }),
        headers=auth_headers
    )
    
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data["status"] == "paid"

def test_get_invoice_pdf(client, auth_headers):
    """Test getting an invoice PDF."""
    response = client.get(
        "/api/v1/invoices/1/pdf",
        headers=auth_headers
    )
    
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "application/pdf"
    assert response.headers["Content-Disposition"] == "attachment; filename=invoice_INV-20230101-0001.pdf" 