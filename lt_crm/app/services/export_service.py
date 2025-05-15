"""Export service for products in various formats."""
import io
import pandas as pd
import xml.dom.minidom as minidom
import xml.etree.ElementTree as ET
from flask import current_app
from sqlalchemy.orm import joinedload
from datetime import datetime
from lxml import etree
from typing import Dict, List, Tuple, Any, Optional


class ExportService:
    """Service for exporting data in various formats."""
    
    def __init__(self):
        """Initialize the export service."""
        self.logger = current_app.logger if current_app else None
    
    def build_dataframe(self, query, column_map: Dict[str, str]) -> pd.DataFrame:
        """
        Build a pandas DataFrame from query results using the column map.
        
        Args:
            query: SQLAlchemy query object with results to export
            column_map: Dictionary mapping internal attribute names to external column names
            
        Returns:
            pandas.DataFrame with renamed columns according to column_map
        """
        # Execute query and get all results
        results = query.all()
        
        if not results:
            return pd.DataFrame(columns=list(column_map.values()))
        
        # Build data rows
        data = []
        for item in results:
            row = {}
            for internal_name, external_name in column_map.items():
                # Handle nested attributes using dot notation
                if "." in internal_name:
                    parts = internal_name.split(".")
                    value = item
                    for part in parts:
                        if hasattr(value, part):
                            value = getattr(value, part)
                        else:
                            value = None
                            break
                else:
                    # Get attribute value if it exists
                    value = getattr(item, internal_name, None)
                
                # Call the value if it's a property method
                if callable(value) and not hasattr(value, '__self__'):
                    value = value()
                
                row[external_name] = value
            
            data.append(row)
        
        # Create dataframe with external column names
        df = pd.DataFrame(data)
        
        # Ensure all columns from column_map exist in dataframe
        for external_name in column_map.values():
            if external_name not in df.columns:
                df[external_name] = None
                
        return df
    
    def to_csv(self, df: pd.DataFrame, **kwargs) -> Tuple[bytes, str]:
        """
        Convert dataframe to CSV bytes.
        
        Args:
            df: Pandas DataFrame to export
            **kwargs: Additional arguments for pandas to_csv
            
        Returns:
            Tuple of (bytes, mime_type)
        """
        output = io.BytesIO()
        
        # Set sensible defaults
        default_params = {
            "index": False,
            "encoding": "utf-8-sig",  # Include BOM for Excel compatibility
            "sep": ",",
            "quotechar": '"',
            "quoting": 1,  # QUOTE_ALL
            "date_format": "%Y-%m-%d %H:%M:%S"
        }
        
        # Override defaults with provided kwargs
        params = {**default_params, **kwargs}
        
        df.to_csv(output, **params)
        return output.getvalue(), "text/csv"
    
    def to_xlsx(self, df: pd.DataFrame, **kwargs) -> Tuple[bytes, str]:
        """
        Convert dataframe to Excel bytes.
        
        Args:
            df: Pandas DataFrame to export
            **kwargs: Additional arguments for pandas to_excel
            
        Returns:
            Tuple of (bytes, mime_type)
        """
        output = io.BytesIO()
        
        # Set sensible defaults
        default_params = {
            "index": False,
            "engine": "openpyxl",
            "sheet_name": "Products"
        }
        
        # Override defaults with provided kwargs
        params = {**default_params, **kwargs}
        
        df.to_excel(output, **params)
        return output.getvalue(), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    
    def to_xml(self, df: pd.DataFrame, root: str = "items", item_tag: str = "item", **kwargs) -> Tuple[bytes, str]:
        """
        Convert dataframe to XML bytes.
        
        Args:
            df: Pandas DataFrame to export
            root: Name of the root element
            item_tag: Name of each item element
            **kwargs: Additional arguments
            
        Returns:
            Tuple of (bytes, mime_type)
        """
        # Create root element
        root_element = ET.Element(root)
        
        # Add each row as an item
        for _, row in df.iterrows():
            item_element = ET.SubElement(root_element, item_tag)
            
            for col, value in row.items():
                # Skip None values
                if pd.isna(value):
                    continue
                    
                # Convert non-string values to string
                if not isinstance(value, str):
                    if isinstance(value, (int, float, bool)):
                        value = str(value)
                    elif isinstance(value, datetime):
                        value = value.strftime("%Y-%m-%d %H:%M:%S")
                    else:
                        value = str(value)
                
                # Create element with column name and value
                col_element = ET.SubElement(item_element, col)
                col_element.text = value
        
        # Convert to string with pretty formatting
        xml_str = minidom.parseString(ET.tostring(root_element, encoding="utf-8")).toprettyxml(indent="  ")
        
        return xml_str.encode("utf-8"), "application/xml"
    
    def to_google_merchant_xml(self, df: pd.DataFrame) -> Tuple[bytes, str]:
        """
        Export data as Google Merchant XML feed.
        
        Args:
            df: Pandas DataFrame with product data
            
        Returns:
            Tuple of (bytes, mime_type)
        """
        # Define the XML namespaces for Google Merchant feed
        nsmap = {
            "g": "http://base.google.com/ns/1.0"
        }
        
        # Create root element with proper namespaces
        root = etree.Element("rss", version="2.0", nsmap={"g": nsmap["g"]})
        channel = etree.SubElement(root, "channel")
        
        # Add feed header information
        title = etree.SubElement(channel, "title")
        title.text = "Product Feed"
        
        description = etree.SubElement(channel, "description")
        description.text = "Product data feed for Google Merchant Center"
        
        link = etree.SubElement(channel, "link")
        link.text = current_app.config.get("SITE_URL", "https://example.com")
        
        # Add each product as an item
        for _, row in df.iterrows():
            item = etree.SubElement(channel, "item")
            
            # Required Google fields
            # Map DataFrame columns to Google Merchant fields
            # Adjust field mappings based on your column_map and DataFrame structure
            
            # Add Google ID (required)
            g_id = etree.SubElement(item, "{%s}id" % nsmap["g"])
            g_id.text = str(row.get("id", row.get("sku", "")))
            
            # Add title (required)
            title = etree.SubElement(item, "title")
            title.text = str(row.get("title", row.get("name", "")))
            
            # Add description (required)
            description = etree.SubElement(item, "description")
            description.text = str(row.get("description", ""))
            
            # Add link (required)
            link = etree.SubElement(item, "link")
            link.text = f"{current_app.config.get('SITE_URL', 'https://example.com')}/products/{row.get('sku', '')}"
            
            # Add image link (required)
            image_link = etree.SubElement(item, "{%s}image_link" % nsmap["g"])
            image_link.text = str(row.get("image_link", row.get("main_image_url", "")))
            
            # Add availability (required)
            availability = etree.SubElement(item, "{%s}availability" % nsmap["g"])
            in_stock = row.get("availability", row.get("in_stock", False))
            availability.text = "in stock" if in_stock else "out of stock"
            
            # Add price (required)
            price = etree.SubElement(item, "{%s}price" % nsmap["g"])
            price_value = row.get("price", row.get("price_final", "0"))
            price.text = f"{price_value} EUR"
            
            # Add brand (recommended)
            if "brand" in row or "manufacturer" in row:
                brand = etree.SubElement(item, "{%s}brand" % nsmap["g"])
                brand.text = str(row.get("brand", row.get("manufacturer", "")))
            
            # Add GTIN/barcode (recommended if available)
            if "gtin" in row or "barcode" in row:
                gtin = etree.SubElement(item, "{%s}gtin" % nsmap["g"])
                gtin.text = str(row.get("gtin", row.get("barcode", "")))
            
            # Add condition (recommended)
            condition = etree.SubElement(item, "{%s}condition" % nsmap["g"])
            condition.text = str(row.get("condition", "new"))
            
            # Add product category (recommended)
            if "product_category" in row or "category" in row:
                product_type = etree.SubElement(item, "{%s}product_type" % nsmap["g"])
                product_type.text = str(row.get("product_category", row.get("category", "")))
            
            # Add optional fields if present in DataFrame
            optional_fields = {
                "mpn": "mpn", 
                "model": "model_number",
                "weight": "weight",
                "shipping_weight": "shipping_weight",
                "size": "size",
                "color": "color",
                "material": "material"
            }
            
            for g_field, df_field in optional_fields.items():
                if df_field in row and not pd.isna(row[df_field]):
                    field = etree.SubElement(item, "{%s}%s" % (nsmap["g"], g_field))
                    field.text = str(row[df_field])
        
        # Convert to bytes
        xml_bytes = etree.tostring(
            root, 
            encoding="UTF-8", 
            xml_declaration=True, 
            pretty_print=True
        )
        
        return xml_bytes, "application/xml"
    
    def validate_xml_against_xsd(self, xml_bytes: bytes, xsd_schema: bytes) -> bool:
        """
        Validate XML against XSD schema.
        
        Args:
            xml_bytes: XML content as bytes
            xsd_schema: XSD schema as bytes
            
        Returns:
            True if valid, False otherwise
        """
        try:
            xml_doc = etree.fromstring(xml_bytes)
            xsd_doc = etree.fromstring(xsd_schema)
            schema = etree.XMLSchema(xsd_doc)
            
            is_valid = schema.validate(xml_doc)
            return is_valid
        except Exception as e:
            if self.logger:
                self.logger.error(f"XML validation error: {str(e)}")
            return False
    
    def validate_column_map(self, column_map: Dict[str, str], model_class) -> Tuple[bool, List[str]]:
        """
        Validate that column map keys exist in the model class.
        
        Args:
            column_map: Dictionary mapping internal attribute names to external column names
            model_class: SQLAlchemy model class to validate against
            
        Returns:
            Tuple of (is_valid, list_of_invalid_keys)
        """
        invalid_keys = []
        
        for internal_name in column_map.keys():
            # Handle nested attributes
            if "." in internal_name:
                parts = internal_name.split(".")
                current_class = model_class
                valid_path = True
                
                for i, part in enumerate(parts[:-1]):
                    if hasattr(current_class, part):
                        attr = getattr(current_class, part)
                        # Get the related class from relationship
                        if hasattr(attr, 'prop') and hasattr(attr.prop, 'mapper'):
                            current_class = attr.prop.mapper.class_
                        else:
                            valid_path = False
                            break
                    else:
                        valid_path = False
                        break
                
                # Check final attribute
                if valid_path and not hasattr(current_class, parts[-1]):
                    valid_path = False
                
                if not valid_path:
                    invalid_keys.append(internal_name)
            else:
                # Check if attribute exists directly on model
                if not hasattr(model_class, internal_name):
                    invalid_keys.append(internal_name)
        
        return len(invalid_keys) == 0, invalid_keys 