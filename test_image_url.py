#!/usr/bin/env python3
"""
Test script to debug get_image_url function.
"""

import os
import sys

# Add the lt_crm directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lt_crm'))

from lt_crm.app import create_app
from lt_crm.app.models.product import Product
from lt_crm.app.services.image_service import get_image_url

def test_image_urls():
    """Test get_image_url function with sample products."""
    app = create_app()
    
    with app.app_context():
        # Get a few sample products
        products = Product.query.limit(5).all()
        
        for product in products:
            print(f"\n=== Product: {product.sku} ===")
            print(f"Name: {product.name}")
            print(f"Database image URL: {product.main_image_url}")
            
            # Test get_image_url function
            processed_url = get_image_url(product.main_image_url)
            print(f"Processed URL: {processed_url}")
            
            # Check if file exists on disk
            if product.main_image_url and not product.main_image_url.startswith('http'):
                full_path = os.path.join(app.config.get('PRODUCT_IMAGES_DIR', ''), product.main_image_url)
                exists = os.path.exists(full_path)
                print(f"File exists on disk: {exists}")
                if exists:
                    file_size = os.path.getsize(full_path)
                    print(f"File size: {file_size} bytes")
                else:
                    print(f"Expected path: {full_path}")

if __name__ == "__main__":
    test_image_urls() 