#!/usr/bin/env python3
"""
Script to check and fix product image URLs.
This ensures all products have local image paths that match existing files.
"""

import os
import sys

# Add the lt_crm directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lt_crm'))

from lt_crm.app import create_app
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product

def check_and_fix_image_urls():
    """Check and fix product image URLs."""
    app = create_app()
    
    with app.app_context():
        # Get all products
        products = Product.query.all()
        print(f"Checking {len(products)} products...")
        
        external_urls = 0
        local_paths = 0
        missing_files = 0
        fixed = 0
        
        for product in products:
            if product.main_image_url:
                if product.main_image_url.startswith('http'):
                    print(f"❌ {product.sku}: Has external URL: {product.main_image_url}")
                    external_urls += 1
                    
                    # Try to find corresponding local file
                    expected_filename = f"main_{product.sku.replace('/', '-').replace('\\', '-').replace(':', '-').replace('*', '-').replace('?', '-').replace('\"', '-').replace('<', '-').replace('>', '-').replace('|', '-')}"
                    
                    # Check for common extensions
                    for ext in ['.jpg', '.png', '.webp', '.jpeg']:
                        expected_path = f"0-999/{expected_filename}{ext}"
                        full_path = os.path.join(app.config['PRODUCT_IMAGES_DIR'], expected_path)
                        
                        if os.path.exists(full_path):
                            print(f"  ✓ Found local file: {expected_path}")
                            product.main_image_url = expected_path
                            fixed += 1
                            break
                    else:
                        print(f"  ⚠ No local file found for {product.sku}")
                        
                else:
                    # Check if local file exists
                    full_path = os.path.join(app.config['PRODUCT_IMAGES_DIR'], product.main_image_url)
                    if os.path.exists(full_path):
                        print(f"✓ {product.sku}: Has valid local path: {product.main_image_url}")
                        local_paths += 1
                    else:
                        print(f"⚠ {product.sku}: Local file missing: {product.main_image_url}")
                        missing_files += 1
            else:
                print(f"- {product.sku}: No image URL")
        
        # Save changes
        if fixed > 0:
            db.session.commit()
            print(f"\n✓ Fixed {fixed} products")
        
        print(f"\nSummary:")
        print(f"  External URLs: {external_urls}")
        print(f"  Valid local paths: {local_paths}")
        print(f"  Missing files: {missing_files}")
        print(f"  Fixed: {fixed}")

if __name__ == "__main__":
    check_and_fix_image_urls() 