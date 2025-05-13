"""Tests for API clients."""
import pytest
import json
from datetime import datetime, timezone
from unittest.mock import patch
import httpx
from httpx import MockResponse
from app.clients.pigu_client import PiguClient
from app.clients.varle_client import VarleClient
from app.clients.allegro_client import AllegroClient
from app.exceptions import APIClientError, APIConnectionError, APITimeoutError


@pytest.fixture
def pigu_orders_response():
    """Return a sample Pigu orders API response."""
    return {
        "orders": [
            {
                "order_id": "12345",
                "status": "paid",
                "total_amount": "100.00",
                "shipping_amount": "5.00",
                "tax_amount": "21.00",
                "shipping": {
                    "full_name": "Jonas Jonaitis",
                    "address": "Gedimino pr. 1",
                    "city": "Vilnius",
                    "postal_code": "01103",
                    "country": "Lithuania",
                    "phone": "+37060012345",
                    "email": "jonas@example.com"
                },
                "payment_method": "card",
                "payment_id": "payment123",
                "items": [
                    {
                        "sku": "TEST001",
                        "quantity": 2,
                        "price": 42.50,
                        "tax_rate": 21.0
                    }
                ]
            }
        ]
    }


@pytest.fixture
def varle_orders_response():
    """Return a sample Varle orders API response."""
    return {
        "data": [
            {
                "order_number": "V67890",
                "status": "paid",
                "total": "150.00",
                "shipping_fee": "3.99",
                "vat_amount": "31.50",
                "customer": {
                    "firstname": "Petras",
                    "lastname": "Petraitis",
                    "phone": "+37069987654",
                    "email": "petras@example.com"
                },
                "shipping_address": {
                    "street": "Konstitucijos pr. 20",
                    "city": "Vilnius",
                    "postcode": "09308",
                    "country": "Lithuania"
                },
                "items": [
                    {
                        "sku": "TEST002",
                        "quantity": 1,
                        "price": 146.01,
                        "vat_rate": 21.0
                    }
                ]
            }
        ]
    }


@pytest.fixture
def allegro_orders_response():
    """Return a sample Allegro orders API response."""
    return {
        "orders": [
            {
                "id": "ALG12345",
                "status": "READY_FOR_PROCESSING",
                "summary": {
                    "totalToPay": {
                        "amount": "200.00",
                        "currency": "PLN"
                    },
                    "shipmentSummary": {
                        "shippingPrice": {
                            "amount": "10.00",
                            "currency": "PLN"
                        }
                    }
                },
                "buyer": {
                    "email": "kupiec@example.pl"
                },
                "delivery": {
                    "address": {
                        "firstName": "Jan",
                        "lastName": "Kowalski",
                        "street": "ul. Marszałkowska 1",
                        "city": "Warszawa",
                        "zipCode": "00-001",
                        "countryCode": "PL"
                    },
                    "phoneNumber": "+48123456789",
                    "method": {
                        "name": "Courier"
                    }
                },
                "lineItems": [
                    {
                        "offer": {
                            "external": {
                                "id": "TEST003"
                            }
                        },
                        "quantity": 1,
                        "price": {
                            "amount": "190.00",
                            "currency": "PLN"
                        }
                    }
                ]
            }
        ]
    }


class TestPiguClient:
    """Test the Pigu API client."""

    def test_fetch_orders_success(self, monkeypatch, pigu_orders_response):
        """Test successfully fetching orders from Pigu."""
        # Mock the request method
        def mock_request(*args, **kwargs):
            return pigu_orders_response

        # Apply the mock
        monkeypatch.setattr(PiguClient, "request", mock_request)

        # Create client and fetch orders
        client = PiguClient()
        result = client.fetch_orders()

        # Verify result
        assert result["total"] == 1
        assert "created" in result
        assert "updated" in result
        assert "failed" in result
        assert "details" in result

    def test_fetch_orders_api_error(self, monkeypatch):
        """Test handling API errors when fetching orders."""
        # Mock the request method to raise an exception
        def mock_request(*args, **kwargs):
            raise APIClientError("API Error")

        # Apply the mock
        monkeypatch.setattr(PiguClient, "request", mock_request)

        # Create client and test exception handling
        client = PiguClient()
        with pytest.raises(APIClientError):
            client.fetch_orders()

    def test_push_stock_success(self, monkeypatch):
        """Test successfully pushing stock updates to Pigu."""
        # Mock response for successful update
        mock_response = {
            "results": [
                {"sku": "TEST001", "status": "success"},
                {"sku": "TEST002", "status": "success"}
            ]
        }

        # Mock the post method
        def mock_post(*args, **kwargs):
            return mock_response

        # Apply the mock
        monkeypatch.setattr(PiguClient, "post", mock_post)

        # Create mock products
        class MockProduct:
            def __init__(self, sku, quantity):
                self.sku = sku
                self.quantity = quantity

        products = [
            MockProduct("TEST001", 10),
            MockProduct("TEST002", 5)
        ]

        # Create client and push stock
        client = PiguClient()
        result = client.push_stock(products)

        # Verify result
        assert result["success"] == 2
        assert result["failed"] == 0
        assert len(result["details"]) == 2


class TestVarleClient:
    """Test the Varle API client."""

    def test_fetch_orders_success(self, monkeypatch, varle_orders_response):
        """Test successfully fetching orders from Varle."""
        # Mock the request method
        def mock_request(*args, **kwargs):
            return varle_orders_response

        # Apply the mock
        monkeypatch.setattr(VarleClient, "request", mock_request)

        # Create client and fetch orders
        client = VarleClient()
        result = client.fetch_orders()

        # Verify result
        assert result["total"] == 1
        assert "created" in result
        assert "updated" in result
        assert "failed" in result
        assert "details" in result

    def test_push_stock_partial_success(self, monkeypatch):
        """Test pushing stock updates with partial success."""
        # Mock response for partial success
        mock_response = {
            "results": [
                {"sku": "TEST001", "success": True},
                {"sku": "TEST002", "success": False, "message": "Item not found"}
            ]
        }

        # Mock the post method
        def mock_post(*args, **kwargs):
            return mock_response

        # Apply the mock
        monkeypatch.setattr(VarleClient, "post", mock_post)

        # Create mock products
        class MockProduct:
            def __init__(self, sku, quantity):
                self.sku = sku
                self.quantity = quantity

        products = [
            MockProduct("TEST001", 10),
            MockProduct("TEST002", 5)
        ]

        # Create client and push stock
        client = VarleClient()
        result = client.push_stock(products)

        # Verify result
        assert result["success"] == 1
        assert result["failed"] == 1
        assert len(result["details"]) == 2


class TestAllegroClient:
    """Test the Allegro API client."""

    def test_refresh_token(self, monkeypatch):
        """Test refreshing the OAuth token."""
        # Mock httpx.post
        def mock_post(*args, **kwargs):
            return MockResponse(
                status_code=200,
                json={
                    "access_token": "mock_token",
                    "expires_in": 3600
                }
            )

        # Apply the mock
        monkeypatch.setattr(httpx, "post", mock_post)

        # Create client and refresh token
        client = AllegroClient()
        client._refresh_token()

        # Verify token was set
        assert client.access_token == "mock_token"
        assert client.token_expiry is not None

    def test_fetch_orders_success(self, monkeypatch, allegro_orders_response):
        """Test successfully fetching orders from Allegro."""
        # Mock the get method
        def mock_get(*args, **kwargs):
            return allegro_orders_response

        # Mock token refresh to avoid actual API calls
        def mock_refresh():
            return None

        # Apply the mocks
        monkeypatch.setattr(AllegroClient, "get", mock_get)
        monkeypatch.setattr(AllegroClient, "_refresh_token", mock_refresh)

        # Create client and fetch orders
        client = AllegroClient()
        result = client.fetch_orders()

        # Verify result
        assert result["total"] == 1
        assert "created" in result
        assert "updated" in result
        assert "failed" in result
        assert "details" in result

    def test_push_stock_success(self, monkeypatch):
        """Test successfully pushing stock updates to Allegro."""
        # Mock responses
        def mock_get(*args, **kwargs):
            return {"offers": [{"id": "offer_123"}]}

        def mock_put(*args, **kwargs):
            return {"stock": {"available": 10}}

        # Mock token refresh
        def mock_refresh():
            return None

        # Apply the mocks
        monkeypatch.setattr(AllegroClient, "get", mock_get)
        monkeypatch.setattr(AllegroClient, "put", mock_put)
        monkeypatch.setattr(AllegroClient, "_refresh_token", mock_refresh)

        # Create mock products
        class MockProduct:
            def __init__(self, sku, quantity):
                self.sku = sku
                self.quantity = quantity

        products = [MockProduct("TEST001", 10)]

        # Create client and push stock
        client = AllegroClient()
        result = client.push_stock(products)

        # Verify result
        assert result["success"] == 1
        assert result["failed"] == 0 