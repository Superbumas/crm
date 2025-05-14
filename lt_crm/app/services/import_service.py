"""Import service for handling CSV/XLSX imports."""
import os
import io
import pandas as pd
from werkzeug.utils import secure_filename
from lt_crm.app.services.inventory import import_products_from_dataframe


def parse_product_file(file_obj, file_format=None):
    """
    Parse product file (CSV or XLSX) and return a pandas DataFrame.
    
    Args:
        file_obj: File object or file path
        file_format (str, optional): Format override ('csv' or 'xlsx')
        
    Returns:
        DataFrame: Parsed data
        
    Raises:
        ValueError: If file format is not supported or parsing fails
    """
    # Determine format from filename if not specified
    if not file_format and hasattr(file_obj, 'filename'):
        filename = file_obj.filename.lower()
        if filename.endswith('.csv'):
            file_format = 'csv'
        elif filename.endswith('.xlsx') or filename.endswith('.xls'):
            file_format = 'xlsx'
        else:
            raise ValueError("Unsupported file format. Use CSV or XLSX")
    
    # Handle different input types
    if isinstance(file_obj, str):  # File path
        if file_format == 'csv':
            return pd.read_csv(file_obj)
        elif file_format == 'xlsx':
            return pd.read_excel(file_obj)
    elif hasattr(file_obj, 'read'):  # File-like object
        if file_format == 'csv':
            return pd.read_csv(file_obj)
        elif file_format == 'xlsx':
            return pd.read_excel(file_obj)
    
    raise ValueError("Could not parse file. Unsupported format or invalid file")


def import_products(file_obj, channel=None, reference_id=None, user_id=None):
    """
    Import products from file and create/update products in database.
    
    Args:
        file_obj: File object (from request.files)
        channel (str, optional): Import channel name
        reference_id (str, optional): Reference ID for tracking
        user_id (int, optional): User ID who initiated the import
        
    Returns:
        dict: Summary of import operation
        
    Raises:
        ValueError: If file is invalid or required columns are missing
    """
    try:
        # Parse the file
        df = parse_product_file(file_obj)
        
        # Process products and create stock movements
        summary = import_products_from_dataframe(
            df,
            channel=channel,
            reference_id=reference_id,
            user_id=user_id
        )
        
        return summary
    
    except Exception as e:
        raise ValueError(f"Error importing products: {str(e)}")


def validate_product_data(df):
    """
    Validate product DataFrame for required columns and data types.
    
    Args:
        df (DataFrame): DataFrame to validate
        
    Returns:
        tuple: (is_valid, error_message)
    """
    # Check required columns
    required_cols = ["sku", "name", "price_final"]
    missing_cols = [col for col in required_cols if col not in df.columns]
    
    if missing_cols:
        return False, f"Missing required columns: {', '.join(missing_cols)}"
    
    # Validate SKUs are not empty
    empty_skus = df['sku'].isnull().sum()
    if empty_skus > 0:
        return False, f"Found {empty_skus} rows with empty SKU values"
    
    # Validate price is numeric
    try:
        df['price_final'] = pd.to_numeric(df['price_final'])
    except:
        return False, "Price values must be numeric"
    
    # Check for negative prices
    if (df['price_final'] < 0).any():
        return False, "Found negative price values"
    
    # If quantity is present, ensure it's numeric
    if 'quantity' in df.columns:
        try:
            df['quantity'] = pd.to_numeric(df['quantity'])
        except:
            return False, "Quantity values must be numeric"
    
    return True, "Validation passed"


def generate_import_template(format='xlsx'):
    """
    Generate a template file for product import.
    
    Args:
        format (str): File format ('csv' or 'xlsx')
        
    Returns:
        BytesIO: File content
    """
    # Define template columns with examples
    data = {
        'sku': ['PROD001', 'PROD002'],
        'name': ['Product 1', 'Product 2'],
        'description_html': ['<p>Description 1</p>', '<p>Description 2</p>'],
        'barcode': ['1234567890123', '2345678901234'],
        'quantity': [10, 20],
        'price_final': [19.99, 29.99],
        'price_old': [24.99, ''],
        'category': ['Category 1', 'Category 2'],
        'manufacturer': ['Manufacturer 1', 'Manufacturer 2'],
        'model': ['Model 1', 'Model 2']
    }
    
    df = pd.DataFrame(data)
    output = io.BytesIO()
    
    if format == 'csv':
        df.to_csv(output, index=False)
    else:  # xlsx
        df.to_excel(output, index=False)
    
    output.seek(0)
    return output 