"""Tests for the export API endpoints."""
import json
import pytest
from unittest.mock import patch
from io import BytesIO
from lt_crm.app.models.export import ExportConfig, ExportFormat


@pytest.fixture
def token_headers(app, test_client, create_user, login_user):
    """Get authentication token for API requests."""
    # Create a test user
    user = create_user("testuser", "testuser@example.com", "password123")
    
    # Login to get a token
    response = login_user("testuser", "password123")
    token = response.json.get("access_token")
    
    # Return headers with the token
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def products(app, db):
    """Create test products for use in tests."""
    from lt_crm.app.models.product import Product
    
    products = []
    for i in range(1, 6):
        product = Product(
            sku=f"SKU-{i}",
            name=f"Test Product {i}",
            description_html=f"<p>Description for Test Product {i}</p>",
            price_final=i * 10.99,
            quantity=i * 5,
            category="Test Category",
            manufacturer="Test Manufacturer"
        )
        db.session.add(product)
        products.append(product)
    
    db.session.commit()
    return products


@pytest.fixture
def sample_column_map():
    """Return a sample column map for testing."""
    return {
        "sku": "SKU",
        "name": "Product Name",
        "price_final": "Price",
        "quantity": "Stock",
        "category": "Category"
    }


@pytest.fixture
def export_config(app, db, create_user, sample_column_map):
    """Create a test export configuration."""
    user = create_user("configuser", "configuser@example.com", "password123")
    
    config = ExportConfig(
        name="Test Config",
        format=ExportFormat.CSV,
        column_map=sample_column_map,
        created_by_id=user.id
    )
    
    db.session.add(config)
    db.session.commit()
    
    return config


def test_preview_export(app, test_client, token_headers, products, sample_column_map):
    """Test the preview export endpoint."""
    # Prepare request data
    data = {
        "format": "csv",
        "column_map": sample_column_map,
        "limit": 5
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/preview",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert "data" in response.json
    assert "count" in response.json
    assert "format" in response.json
    assert response.json["format"] == "csv"
    assert response.json["count"] == 5
    
    # Check that the preview data contains expected fields
    preview_data = response.json["data"]
    assert len(preview_data) == 5
    assert "SKU" in preview_data[0]
    assert "Product Name" in preview_data[0]
    assert "Price" in preview_data[0]
    assert "Stock" in preview_data[0]


def test_preview_export_with_invalid_column_map(test_client, token_headers, products):
    """Test the preview export endpoint with an invalid column map."""
    # Prepare request data with invalid column
    data = {
        "format": "csv",
        "column_map": {
            "sku": "SKU",
            "invalid_column": "Invalid", 
            "name": "Product Name"
        }
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/preview",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 400
    assert "message" in response.json
    assert "invalid_keys" in response.json
    assert "invalid_column" in response.json["invalid_keys"]


def test_download_export_csv(app, test_client, token_headers, products, sample_column_map):
    """Test the download export endpoint for CSV format."""
    # Prepare request data
    data = {
        "format": "csv",
        "column_map": sample_column_map
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/download",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.content_type == "text/csv"
    assert "attachment" in response.headers["Content-Disposition"]
    assert "export_" in response.headers["Content-Disposition"]
    assert ".csv" in response.headers["Content-Disposition"]
    
    # Check the content
    content = response.data.decode("utf-8-sig")
    assert "SKU,Product Name,Price,Stock,Category" in content


def test_download_export_xlsx(app, test_client, token_headers, products, sample_column_map):
    """Test the download export endpoint for XLSX format."""
    # Prepare request data
    data = {
        "format": "xlsx",
        "column_map": sample_column_map
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/download",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert "attachment" in response.headers["Content-Disposition"]
    assert "export_" in response.headers["Content-Disposition"]
    assert ".xlsx" in response.headers["Content-Disposition"]
    
    # We can't easily check the Excel content, but we can verify it's not empty
    assert len(response.data) > 0


def test_download_export_xml(app, test_client, token_headers, products, sample_column_map):
    """Test the download export endpoint for XML format."""
    # Prepare request data
    data = {
        "format": "xml",
        "column_map": sample_column_map,
        "xml_root": "products",
        "xml_item": "product"
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/download",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.content_type == "application/xml"
    assert "attachment" in response.headers["Content-Disposition"]
    assert "export_" in response.headers["Content-Disposition"]
    assert ".xml" in response.headers["Content-Disposition"]
    
    # Check that the XML is well-formed
    content = response.data.decode("utf-8")
    assert "<?xml" in content
    assert "<products>" in content
    assert "<product>" in content


def test_download_google_merchant_xml(app, test_client, token_headers, products):
    """Test the download export endpoint for Google Merchant XML format."""
    # Prepare request data with Google Merchant column map
    data = {
        "format": "xml",
        "template": "google_merchant",
        "column_map": {
            "sku": "id",
            "name": "title",
            "description_html": "description",
            "price_final": "price",
            "main_image_url": "image_link",
            "is_in_stock": "availability",
            "manufacturer": "brand"
        }
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/download",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.content_type == "application/xml"
    assert "attachment" in response.headers["Content-Disposition"]
    assert "google_merchant_" in response.headers["Content-Disposition"]
    assert ".xml" in response.headers["Content-Disposition"]
    
    # Check that the XML is well-formed
    content = response.data.decode("utf-8")
    assert "<?xml" in content
    assert "<rss" in content
    assert "<channel>" in content
    assert "<item>" in content


def test_create_export_config(app, test_client, token_headers, sample_column_map):
    """Test creating an export configuration."""
    # Prepare request data
    data = {
        "name": "My CSV Export",
        "format": "csv",
        "column_map": sample_column_map
    }
    
    # Make the request
    response = test_client.post(
        "/v1/exports/configs",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 201
    assert "id" in response.json
    assert response.json["name"] == "My CSV Export"
    assert response.json["format"] == "csv"
    
    # Verify that the configuration was saved to the database
    config = ExportConfig.query.get(response.json["id"])
    assert config is not None
    assert config.name == "My CSV Export"


def test_list_export_configs(app, test_client, token_headers, export_config):
    """Test listing export configurations."""
    # Make the request
    response = test_client.get(
        "/v1/exports/configs",
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert "items" in response.json
    assert "total" in response.json
    assert response.json["total"] >= 1
    
    # Check that our export config is in the list
    found = False
    for config in response.json["items"]:
        if config["id"] == export_config.id:
            found = True
            assert config["name"] == export_config.name
            assert config["format"] == export_config.format.value
    
    assert found is True


def test_get_export_config(app, test_client, token_headers, export_config):
    """Test getting a specific export configuration."""
    # Make the request
    response = test_client.get(
        f"/v1/exports/configs/{export_config.id}",
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.json["id"] == export_config.id
    assert response.json["name"] == export_config.name
    assert response.json["format"] == export_config.format.value
    assert response.json["column_map"] == export_config.column_map


def test_update_export_config(app, test_client, token_headers, export_config):
    """Test updating an export configuration."""
    # Prepare request data
    data = {
        "name": "Updated Config Name",
        "format": "xlsx",
        "column_map": {
            "sku": "Product Code",
            "name": "Name",
            "price_final": "Price"
        }
    }
    
    # Make the request
    response = test_client.put(
        f"/v1/exports/configs/{export_config.id}",
        json=data,
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 200
    assert response.json["id"] == export_config.id
    assert response.json["name"] == "Updated Config Name"
    assert response.json["format"] == "xlsx"
    
    # Verify that the configuration was updated in the database
    config = ExportConfig.query.get(export_config.id)
    assert config.name == "Updated Config Name"
    assert config.format == ExportFormat.XLSX


def test_delete_export_config(app, test_client, token_headers, export_config):
    """Test deleting an export configuration."""
    # Make the request
    response = test_client.delete(
        f"/v1/exports/configs/{export_config.id}",
        headers=token_headers
    )
    
    # Check the response
    assert response.status_code == 204
    
    # Verify that the configuration was deleted from the database
    config = ExportConfig.query.get(export_config.id)
    assert config is None 