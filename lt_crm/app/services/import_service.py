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
    Parse a product file (CSV, TSV, Excel) into a pandas DataFrame.
    
    Args:
        file_obj: File object (from request.files)
        file_format (str, optional): Force file format ('csv', 'tsv', 'xlsx', 'xls')
        encoding (str, optional): File encoding (auto-detected if None)
        delimiter (str, optional): CSV delimiter character
        
    Returns:
        DataFrame: Parsed product data
        
    Raises:
        ValueError: If file format is unsupported or parsing fails
    """
    # Determine file format from filename if not specified
    if not file_format:
        filename = getattr(file_obj, 'filename', '')
        if filename.lower().endswith('.xlsx'):
            file_format = 'xlsx'
        elif filename.lower().endswith('.xls'):
            file_format = 'xls'
        elif filename.lower().endswith('.tsv'):
            file_format = 'tsv'
        elif filename.lower().endswith('.txt'):
            file_format = 'tsv'  # Assume tab-separated for .txt files
        else:
            file_format = 'csv'  # Default to CSV
    
    try:
        if file_format in ['xlsx', 'xls']:
            # Parse Excel file
            df = pd.read_excel(file_obj, engine='openpyxl' if file_format == 'xlsx' else 'xlrd')
        else:
            # Parse CSV/TSV file
            if file_format == 'tsv':
                delimiter = '\t'
            
            # Auto-detect encoding if not specified
            if not encoding:
                # Read a sample to detect encoding
                sample = file_obj.read(10000)
                file_obj.seek(0)  # Reset file position
                
                # Try to detect encoding
                detected = chardet.detect(sample)
                encoding = detected.get('encoding', 'utf-8')
                
                # If chardet suggests a problematic encoding, try common alternatives
                if encoding and encoding.lower() in ['charmap', 'windows-1252', 'cp1252']:
                    # Try UTF-8 first, then UTF-8 with BOM, then the detected encoding
                    for test_encoding in ['utf-8', 'utf-8-sig', 'windows-1252', 'iso-8859-1']:
                        try:
                            file_obj.seek(0)
                            test_df = pd.read_csv(file_obj, encoding=test_encoding, delimiter=delimiter, 
                                               low_memory=False, dtype=str, nrows=5)
                            encoding = test_encoding
                            logger.info(f"Successfully tested encoding: {encoding}")
                            break
                        except UnicodeDecodeError:
                            continue
                        except Exception:
                            continue
                    file_obj.seek(0)  # Reset for final read
                
                logger.info(f"Using encoding: {encoding}")
            
            # Parse CSV with detected/specified encoding
            try:
                df = pd.read_csv(file_obj, encoding=encoding, delimiter=delimiter, 
                               low_memory=False, dtype=str)
            except UnicodeDecodeError as e:
                logger.warning(f"Encoding {encoding} failed: {e}")
                # Try other encodings
                encodings_to_try = ['utf-8', 'utf-8-sig', 'windows-1252', 'iso-8859-1', 'cp1252']
                df = None
                for enc in encodings_to_try:
                    try:
                        file_obj.seek(0)
                        df = pd.read_csv(file_obj, encoding=enc, delimiter=delimiter, 
                                       low_memory=False, dtype=str)
                        logger.info(f"Successfully parsed with encoding: {enc}")
                        break
                    except UnicodeDecodeError:
                        logger.warning(f"Encoding {enc} failed, trying next...")
                        continue
                
                if df is None:
                    # Last resort - read as binary and decode with error handling
                    file_obj.seek(0)
                    content = file_obj.read()
                    if isinstance(content, bytes):
                        content = content.decode('utf-8', errors='replace')
                    from io import StringIO
                    df = pd.read_csv(StringIO(content), delimiter=delimiter, 
                                   low_memory=False, dtype=str)
        
        logger.info(f"Successfully parsed {len(df)} rows with columns: {list(df.columns)}")
        
        # Debug: Check extra_image_urls column specifically
        if 'extra_image_urls' in df.columns:
            non_null_count = df['extra_image_urls'].notna().sum()
            logger.info(f"extra_image_urls column found with {non_null_count} non-null values")
            
            # Log first few non-null values for debugging
            sample_values = df['extra_image_urls'].dropna().head(3)
            for idx, value in sample_values.items():
                logger.info(f"Sample extra_image_urls[{idx}]: {str(value)[:200]}...")
        else:
            logger.warning("extra_image_urls column not found in CSV")
            logger.info(f"Available columns: {list(df.columns)}")
        
        return df
        
    except Exception as e:
        logger.exception(f"Error parsing file: {str(e)}")
        raise ValueError(f"Error parsing file: {str(e)}")


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
        
        # DEBUG: Check if extra_image_urls column exists and show sample data
        if 'extra_image_urls' in df.columns:
            logger.info(f"FOUND extra_image_urls column!")
            sample_data = df['extra_image_urls'].dropna().head(3).tolist()
            logger.info(f"Sample extra_image_urls values: {sample_data}")
        else:
            logger.warning(f"extra_image_urls column NOT FOUND! Available columns: {list(df.columns)}")
            # Check for similar column names
            similar_cols = [col for col in df.columns if 'image' in col.lower() or 'url' in col.lower()]
            logger.info(f"Columns containing 'image' or 'url': {similar_cols}")
        
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
    
    # DEBUG: Log all column names to see what we actually have
    logger.info(f"ALL COLUMNS IN DATAFRAME: {list(df.columns)}")
    logger.info(f"COLUMN TYPES: {dict(df.dtypes)}")
    
    # Convert JSON fields if they're strings
    json_cols = ['extra_image_urls', 'parameters', 'variants', 'delivery_options']
    for col in json_cols:
        if col in df.columns:
            logger.info(f"FOUND JSON COLUMN '{col}' with {df[col].notna().sum()} non-null values")
            # Log first few values to see what we're working with
            sample_values = df[col].dropna().head(3).tolist()
            logger.info(f"SAMPLE VALUES for '{col}': {sample_values}")
            
            # If strings that look like JSON, parse them
            df[col] = df[col].apply(lambda x: 
                                   pd.NA if pd.isna(x) else
                                   (try_parse_json(x) if isinstance(x, str) else x))
            # Log results
            parsed_count = df[col].apply(lambda x: isinstance(x, list)).sum()
            logger.info(f"Column '{col}': {parsed_count} values successfully parsed as lists")
        else:
            logger.warning(f"JSON COLUMN '{col}' NOT FOUND in DataFrame!")
    
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