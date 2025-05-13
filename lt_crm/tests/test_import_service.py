"""Tests for import service."""
import pytest
import pandas as pd
import io
from app.services.import_service import (
    parse_product_file,
    validate_product_data,
    generate_import_template
)


def test_parse_product_file():
    """Test parsing product files from different sources."""
    # Test CSV parsing
    csv_data = "sku,name,price_final\nTEST001,Test Product 1,19.99\nTEST002,Test Product 2,29.99"
    csv_file = io.StringIO(csv_data)
    csv_file.filename = "test.csv"
    
    df = parse_product_file(csv_file)
    assert len(df) == 2
    assert list(df.columns) == ["sku", "name", "price_final"]
    assert df.iloc[0]["sku"] == "TEST001"
    
    # Test XLSX parsing with file-like object
    # This is harder to test directly without a real file
    # We'll test the file format detection instead
    xlsx_file = io.BytesIO()
    xlsx_file.filename = "test.xlsx"
    
    with pytest.raises(ValueError):
        parse_product_file(xlsx_file)  # Will fail but should detect xlsx format


def test_validate_product_data():
    """Test validation of product data."""
    # Valid data
    valid_data = {
        "sku": ["TEST001", "TEST002"],
        "name": ["Test Product 1", "Test Product 2"],
        "price_final": [19.99, 29.99],
        "quantity": [10, 20]
    }
    valid_df = pd.DataFrame(valid_data)
    
    is_valid, message = validate_product_data(valid_df)
    assert is_valid is True
    assert "Validation passed" in message
    
    # Missing required column
    invalid_data = {
        "sku": ["TEST001", "TEST002"],
        "name": ["Test Product 1", "Test Product 2"]
        # Missing price_final
    }
    invalid_df = pd.DataFrame(invalid_data)
    
    is_valid, message = validate_product_data(invalid_df)
    assert is_valid is False
    assert "Missing required columns" in message
    
    # Empty SKU
    empty_sku_data = {
        "sku": ["TEST001", None],
        "name": ["Test Product 1", "Test Product 2"],
        "price_final": [19.99, 29.99]
    }
    empty_sku_df = pd.DataFrame(empty_sku_data)
    
    is_valid, message = validate_product_data(empty_sku_df)
    assert is_valid is False
    assert "empty SKU values" in message
    
    # Negative price
    negative_price_data = {
        "sku": ["TEST001", "TEST002"],
        "name": ["Test Product 1", "Test Product 2"],
        "price_final": [19.99, -29.99]
    }
    negative_price_df = pd.DataFrame(negative_price_data)
    
    is_valid, message = validate_product_data(negative_price_df)
    assert is_valid is False
    assert "negative price values" in message


def test_generate_import_template():
    """Test generating import template files."""
    # Test CSV template
    csv_template = generate_import_template(format="csv")
    assert isinstance(csv_template, io.BytesIO)
    
    # Read the template
    csv_template.seek(0)
    content = csv_template.read().decode("utf-8")
    assert "sku,name,description_html" in content
    assert "PROD001,Product 1" in content
    
    # Test XLSX template
    xlsx_template = generate_import_template(format="xlsx")
    assert isinstance(xlsx_template, io.BytesIO) 