#!/usr/bin/env python3
"""
Debug script to check extra image URLs in import and database.
"""

import os
import sys
import json

# Add the lt_crm directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lt_crm'))

from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product

def debug_extra_images():
    """Debug extra image URLs in the system."""
    app = create_app()
    
    with app.app_context():
        print("=== DEBUGGING EXTRA IMAGES ===\n")
        
        # Check products with extra_image_urls
        products_with_extra = Product.query.filter(Product.extra_image_urls.isnot(None)).all()
        print(f"Products with extra_image_urls field not null: {len(products_with_extra)}")
        
        if products_with_extra:
            for product in products_with_extra[:5]:  # Show first 5
                print(f"  - SKU: {product.sku}")
                print(f"    Name: {product.name}")
                print(f"    Extra URLs type: {type(product.extra_image_urls)}")
                print(f"    Extra URLs value: {product.extra_image_urls}")
                print(f"    Extra URLs repr: {repr(product.extra_image_urls)}")
                if isinstance(product.extra_image_urls, list):
                    print(f"    List length: {len(product.extra_image_urls)}")
                print()
        
        # Check if any products have extra images as strings
        all_products = Product.query.limit(10).all()
        print(f"\nChecking sample of {len(all_products)} products for extra image data:")
        
        for product in all_products:
            if product.extra_image_urls:
                print(f"  - SKU: {product.sku}")
                print(f"    Type: {type(product.extra_image_urls)}")
                print(f"    Value: {product.extra_image_urls}")
                print()
        
        # Check what columns were imported
        print("\n=== CHECKING IMPORT FILE STRUCTURE ===")
        
        # Look for any CSV files in the current directory
        import glob
        csv_files = glob.glob("*.csv")
        
        if csv_files:
            print(f"Found CSV files: {csv_files}")
            
            for csv_file in csv_files[:1]:  # Check first CSV file
                print(f"\nAnalyzing: {csv_file}")
                try:
                    import pandas as pd
                    df = pd.read_csv(csv_file, nrows=5)  # Read first 5 rows
                    
                    print(f"Columns in file: {list(df.columns)}")
                    
                    # Check for extra image related columns
                    extra_cols = [col for col in df.columns if 'extra' in col.lower() or 'additional' in col.lower() or 'gallery' in col.lower()]
                    if extra_cols:
                        print(f"Potential extra image columns: {extra_cols}")
                        
                        for col in extra_cols:
                            print(f"\nColumn '{col}' sample values:")
                            for idx, val in enumerate(df[col].head()):
                                if pd.notna(val):
                                    print(f"  Row {idx}: {repr(val)}")
                    else:
                        print("No extra image columns found")
                        
                except Exception as e:
                    print(f"Error reading CSV: {e}")
        else:
            print("No CSV files found in current directory")

if __name__ == "__main__":
    debug_extra_images() 