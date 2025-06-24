"""Import service for handling CSV/XLSX imports."""
import os
import io
import pandas as pd
import chardet
from werkzeug.utils import secure_filename
from lt_crm.app.services.inventory import import_products_from_dataframe
import logging

# Ensure import_service logger outputs INFO-level logs to the console
logger = logging.getLogger("import_service")
if not logger.hasHandlers():
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)
    logger.addHandler(handler)
logger.setLevel(logging.INFO)


def parse_product_file(file_obj, file_format=None, encoding=None, delimiter=','):
    """
    Parse product file (CSV or XLSX) and return a pandas DataFrame.
    
    Args:
        file_obj: File object or file path
        file_format (str, optional): Format override ('csv' or 'xlsx')
        encoding (str, optional): File encoding (auto-detected if None)
        delimiter (str, optional): CSV delimiter, defaults to comma
        
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
        elif filename.endswith(('.xlsx', '.xls')):
            file_format = 'xlsx'
        elif filename.endswith('.tsv') or filename.endswith('.txt'):
            file_format = 'csv'
            delimiter = '\t'
        else:
            raise ValueError("Unsupported file format. Use CSV, TSV, XLS or XLSX")
    
    # Auto-detect encoding if not specified for CSV files
    if file_format == 'csv' and not encoding:
        try:
            # Get file content for detection
            if hasattr(file_obj, 'read'):
                # Save original position
                if hasattr(file_obj, 'tell'):
                    pos = file_obj.tell()
                
                # Read sample for encoding detection
                sample = file_obj.read(min(1024 * 1024, file_obj.content_length if hasattr(file_obj, 'content_length') else 1024 * 1024))
                
                # Return to original position
                if hasattr(file_obj, 'seek'):
                    file_obj.seek(pos)
                    
                # Detect encoding from sample
                if isinstance(sample, str):
                    # If already decoded, assume utf-8
                    encoding = 'utf-8'
                else:
                    detected = chardet.detect(sample)
                    encoding = detected['encoding'] or 'utf-8'
            else:
                encoding = 'utf-8'  # Fallback
        except Exception:
            encoding = 'utf-8'  # Fallback to UTF-8 on error
    
    # Handle different input types with error handling
    try:
        if isinstance(file_obj, str):  # File path
            if file_format == 'csv':
                return pd.read_csv(file_obj, encoding=encoding or 'utf-8', delimiter=delimiter, 
                                  on_bad_lines='skip', dtype=str)
            elif file_format == 'xlsx':
                return pd.read_excel(file_obj, dtype=str)
        elif hasattr(file_obj, 'read'):  # File-like object
            if file_format == 'csv':
                # For streaming file objects
                content = file_obj.read()
                if isinstance(content, bytes):
                    content = content.decode(encoding or 'utf-8')
                return pd.read_csv(io.StringIO(content), delimiter=delimiter, 
                                  on_bad_lines='skip', dtype=str)
            elif file_format == 'xlsx':
                return pd.read_excel(file_obj, dtype=str)
    except Exception as e:
        raise ValueError(f"Failed to parse file: {str(e)}")
    
    raise ValueError("Could not parse file. Unsupported format or invalid file")


def import_products(file_obj, channel=None, reference_id=None, user_id=None, encoding=None, delimiter=',', has_header=True):
    """
    Import products from file and create/update products in database.
    
    Args:
        file_obj: File object (from request.files)
        channel (str, optional): Import channel name
        reference_id (str, optional): Reference ID for tracking
        user_id (int, optional): User ID who initiated the import
        encoding (str, optional): File encoding (auto-detected if None)
        delimiter (str, optional): CSV delimiter character
        has_header (bool, optional): Whether the file has a header row
        
    Returns:
        dict: Summary of import operation
        
    Raises:
        ValueError: If file is invalid or required columns are missing
    """
    logger.info("Starting product import...")
    try:
        # Parse the file
        df = parse_product_file(file_obj, encoding=encoding, delimiter=delimiter)
        logger.info(f"Parsed file with {len(df)} rows and columns: {list(df.columns)}")
        
        # If no header, assign default column names
        if not has_header and len(df.columns) > 0:
            default_columns = ['sku', 'name', 'description_html', 'barcode', 'quantity', 
                              'price_final', 'price_old', 'category', 'manufacturer', 'model']
            df.columns = default_columns[:len(df.columns)]
        
        # Clean and convert data types
        df = clean_product_dataframe(df)
        logger.info(f"Cleaned DataFrame. Columns: {list(df.columns)}")
        
        # Validate data
        is_valid, error_msg = validate_product_data(df)
        if not is_valid:
            logger.error(f"Validation failed: {error_msg}")
            raise ValueError(error_msg)
        
        # Log each row before import
        for idx, row in df.iterrows():
            logger.info(f"Importing row {idx}: SKU={row.get('sku', '')}, Name={row.get('name', '')}, Price={row.get('price_final', '')}")
        
        # Process products and create stock movements
        summary = import_products_from_dataframe(
            df,
            channel=channel,
            reference_id=reference_id,
            user_id=user_id
        )
        logger.info(f"Import summary: {summary}")
        return summary
    except Exception as e:
        logger.exception(f"Error importing products: {str(e)}")
        raise ValueError(f"Error importing products: {str(e)}")


def clean_product_dataframe(df):
    """
    Clean and prepare a product DataFrame for import.
    
    Args:
        df (DataFrame): Raw DataFrame from file
        
    Returns:
        DataFrame: Cleaned DataFrame with appropriate data types
    """
    # Make a copy to avoid modifying the original
    df = df.copy()
    
    # Strip whitespace from string columns
    for col in df.columns:
        if df[col].dtype == 'object':
            df[col] = df[col].str.strip() if hasattr(df[col], 'str') else df[col]
    
    # Replace empty strings with None/NaN
    df = df.replace(r'^\s*$', pd.NA, regex=True)
    
    # Handle SKU column - ensure it's a string and non-empty
    if 'sku' in df.columns:
        df['sku'] = df['sku'].astype(str)
        # Remove rows with empty SKUs
        df = df[df['sku'].notna() & (df['sku'] != '')]
    
    # Convert numeric columns
    numeric_cols = {
        'price_final': 0.0,
        'price_old': None,
        'quantity': 0,
        'delivery_days': None,
        'warranty_months': None,
        'weight_kg': None
    }
    
    for col, default in numeric_cols.items():
        if col in df.columns:
            try:
                # Try to convert to numeric, coerce errors to NaN
                df[col] = pd.to_numeric(df[col], errors='coerce')
                
                # Replace NaN with default values for required fields
                if default is not None:
                    df[col] = df[col].fillna(default)
            except:
                # If conversion completely fails, set all to default
                if default is not None:
                    df[col] = default
    
    # Convert JSON fields if they're strings
    json_cols = ['extra_image_urls', 'parameters', 'variants', 'delivery_options']
    for col in json_cols:
        if col in df.columns:
            logger.info(f"Processing JSON column '{col}' with {df[col].notna().sum()} non-null values")
            # If strings that look like JSON, parse them
            df[col] = df[col].apply(lambda x: 
                                   pd.NA if pd.isna(x) else
                                   (try_parse_json(x) if isinstance(x, str) else x))
            # Log results
            parsed_count = df[col].apply(lambda x: isinstance(x, list)).sum()
            logger.info(f"Column '{col}': {parsed_count} values successfully parsed as lists")
    
    return df


def try_parse_json(value):
    """Try to parse a string as JSON, return original string if fails."""
    import json
    try:
        # Handle None or empty values
        if pd.isna(value) or value is None or str(value).strip() == '':
            return None
            
        # Convert to string if not already
        value_str = str(value).strip()
        
        # Try to parse as JSON
        parsed = json.loads(value_str)
        logger.info(f"Successfully parsed JSON: {value_str[:100]}... -> {type(parsed)}")
        return parsed
    except json.JSONDecodeError as e:
        logger.warning(f"Failed to parse JSON: {str(value)[:100]}... Error: {str(e)}")
        return value
    except Exception as e:
        logger.warning(f"Unexpected error parsing JSON: {str(value)[:100]}... Error: {str(e)}")
        return value


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
    
    # Note: We no longer check for duplicate SKUs as we'll handle them during import
    
    # Validate price is numeric and not negative
    price_errors = (df['price_final'].isnull() | (df['price_final'] < 0)).sum()
    if price_errors > 0:
        return False, f"Found {price_errors} rows with missing or negative price values"
    
    # If quantity is present, ensure it's not negative
    if 'quantity' in df.columns and (df['quantity'] < 0).any():
        return False, "Found negative quantity values"
    
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