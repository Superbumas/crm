"""Tests for the export service."""
import io
import json
import pandas as pd
import pytest
import xml.etree.ElementTree as ET
from datetime import datetime
from decimal import Decimal
from unittest.mock import patch, MagicMock
from lt_crm.app.models.product import Product
from lt_crm.app.services.export_service import ExportService


@pytest.fixture
def export_service():
    """Create an instance of ExportService for testing."""
    return ExportService()


@pytest.fixture
def mock_products():
    """Create a list of mock product objects."""
    products = []
    
    # Create 5 mock products
    for i in range(1, 6):
        product = MagicMock(spec=Product)
        product.id = i
        product.sku = f"SKU-{i}"
        product.name = f"Product {i}"
        product.description_html = f"<p>Description for product {i}</p>"
        product.barcode = f"BARCODE-{i}"
        product.quantity = i * 10
        product.price_final = Decimal(f"{i}9.99")
        product.category = "Test Category"
        product.manufacturer = "Test Manufacturer"
        product.is_in_stock = True
        product.created_at = datetime(2021, 1, i)
        
        # Add a property method for testing
        product.get_parameters = lambda: {"key": "value"}
        
        products.append(product)
    
    return products


@pytest.fixture
def mock_query(mock_products):
    """Create a mock SQLAlchemy query object that returns the mock products."""
    mock_query = MagicMock()
    mock_query.all.return_value = mock_products
    return mock_query


def test_build_dataframe(export_service, mock_query):
    """Test building a DataFrame from query results."""
    # Define a column map
    column_map = {
        "id": "ID",
        "sku": "SKU",
        "name": "Product Name",
        "price_final": "Price",
        "quantity": "Stock"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Check that the dataframe was built correctly
    assert isinstance(df, pd.DataFrame)
    assert len(df) == 5
    assert list(df.columns) == ["ID", "SKU", "Product Name", "Price", "Stock"]
    assert df["SKU"].tolist() == ["SKU-1", "SKU-2", "SKU-3", "SKU-4", "SKU-5"]


def test_build_dataframe_with_property_method(export_service, mock_query):
    """Test building a DataFrame with a property method."""
    # Define a column map that includes a property method
    column_map = {
        "sku": "SKU",
        "is_in_stock": "In Stock"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Check that the property method was called correctly
    assert df["In Stock"].tolist() == [True, True, True, True, True]


def test_build_dataframe_empty_results(export_service):
    """Test building a DataFrame from empty query results."""
    # Create a mock query that returns no results
    mock_empty_query = MagicMock()
    mock_empty_query.all.return_value = []
    
    # Define a column map
    column_map = {"id": "ID", "sku": "SKU"}
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_empty_query, column_map)
    
    # Check that the dataframe was built correctly
    assert isinstance(df, pd.DataFrame)
    assert len(df) == 0
    assert list(df.columns) == ["ID", "SKU"]


def test_to_csv(export_service, mock_query):
    """Test exporting to CSV."""
    # Define a column map
    column_map = {
        "sku": "SKU",
        "name": "Product Name",
        "price_final": "Price"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Export to CSV
    content, mime_type = export_service.to_csv(df)
    
    # Check the results
    assert isinstance(content, bytes)
    assert mime_type == "text/csv"
    
    # Check that the CSV content is correct
    csv_content = content.decode("utf-8-sig")
    assert "SKU,Product Name,Price" in csv_content
    assert "SKU-1,Product 1,19.99" in csv_content


def test_to_xlsx(export_service, mock_query):
    """Test exporting to Excel."""
    # Define a column map
    column_map = {
        "sku": "SKU",
        "name": "Product Name",
        "price_final": "Price"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Export to Excel
    content, mime_type = export_service.to_xlsx(df)
    
    # Check the results
    assert isinstance(content, bytes)
    assert mime_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    
    # We can't easily check the Excel content, but we can verify it's not empty
    assert len(content) > 0


def test_to_xml(export_service, mock_query):
    """Test exporting to XML."""
    # Define a column map
    column_map = {
        "sku": "SKU",
        "name": "Name",
        "price_final": "Price"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Export to XML
    content, mime_type = export_service.to_xml(df, root="products", item_tag="product")
    
    # Check the results
    assert isinstance(content, bytes)
    assert mime_type == "application/xml"
    
    # Parse the XML content
    root = ET.fromstring(content)
    
    # Check that the XML structure is correct
    assert root.tag == "products"
    products = root.findall("product")
    assert len(products) == 5
    
    # Check some values
    first_product = products[0]
    assert first_product.find("SKU").text == "SKU-1"
    assert first_product.find("Name").text == "Product 1"
    assert first_product.find("Price").text == "19.99"


def test_to_google_merchant_xml(export_service, mock_query):
    """Test exporting to Google Merchant XML."""
    # Define a column map suitable for Google Merchant
    column_map = {
        "sku": "id",
        "name": "title",
        "description_html": "description",
        "main_image_url": "image_link",
        "price_final": "price",
        "is_in_stock": "availability",
        "manufacturer": "brand"
    }
    
    # Build the dataframe
    df = export_service.build_dataframe(mock_query, column_map)
    
    # Mock current_app config
    with patch("lt_crm.app.services.export_service.current_app") as mock_app:
        mock_app.config.get.return_value = "https://example.com"
        
        # Export to Google Merchant XML
        content, mime_type = export_service.to_google_merchant_xml(df)
    
    # Check the results
    assert isinstance(content, bytes)
    assert mime_type == "application/xml"
    
    # Parse the XML content to check structure
    # Note: This is a simple check, not a comprehensive validation
    root = ET.fromstring(content)
    
    # Check basic structure
    assert root.tag == "rss"
    assert root.get("version") == "2.0"
    
    channel = root.find("channel")
    assert channel is not None
    
    # Check that we have 5 items
    items = channel.findall("item")
    assert len(items) == 5


def test_validate_column_map(export_service):
    """Test validating column map keys against model attributes."""
    # Create valid and invalid column maps
    valid_map = {
        "id": "ID",
        "sku": "SKU",
        "name": "Name",
        "is_in_stock": "In Stock"  # A property
    }
    
    invalid_map = {
        "id": "ID",
        "sku": "SKU",
        "non_existent_attr": "Invalid",
        "another_invalid": "Another"
    }
    
    # Test valid map
    is_valid, invalid_keys = export_service.validate_column_map(valid_map, Product)
    assert is_valid is True
    assert len(invalid_keys) == 0
    
    # Test invalid map
    is_valid, invalid_keys = export_service.validate_column_map(invalid_map, Product)
    assert is_valid is False
    assert set(invalid_keys) == {"non_existent_attr", "another_invalid"} 