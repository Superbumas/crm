"""Image handling service for the CRM application."""
import os
import requests
from PIL import Image
from io import BytesIO
from urllib.parse import urlparse
from werkzeug.utils import secure_filename
from flask import current_app
from lt_crm.app.extensions import db
from lt_crm.app.models.product import Product

def download_and_store_image(image_url, product_sku, is_main=True):
    """
    Download image from URL and store it locally.
    
    Args:
        image_url (str): URL of the image to download
        product_sku (str): SKU of the product
        is_main (bool): Whether this is the main product image
        
    Returns:
        str: Local path to the stored image or None if failed
    """
    try:
        # Validate URL
        parsed = urlparse(image_url)
        if not parsed.scheme or not parsed.netloc:
            return None
            
        # Download image
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()
        
        # Open image to validate and get format
        img = Image.open(BytesIO(response.content))
        
        # Generate filename
        original_ext = os.path.splitext(parsed.path)[1].lower()
        if not original_ext:
            original_ext = f".{img.format.lower()}" if img.format else ".jpg"
            
        filename = secure_filename(f"{'main' if is_main else 'extra'}_{product_sku}{original_ext}")
        
        # Determine storage directory based on SKU
        sku_num = int(''.join(filter(str.isdigit, product_sku)) or '0')
        range_dir = f"{(sku_num // 1000) * 1000}-{((sku_num // 1000) + 1) * 1000 - 1}"
        
        # Create directory if it doesn't exist
        storage_dir = os.path.join(current_app.config['PRODUCT_IMAGES_DIR'], range_dir)
        os.makedirs(storage_dir, exist_ok=True)
        
        # Save image
        img_path = os.path.join(storage_dir, filename)
        img.save(img_path, quality=85, optimize=True)
        
        # If webp, also save in original format for compatibility
        if img.format.lower() == 'webp':
            non_webp_ext = '.jpg'
            non_webp_filename = os.path.splitext(filename)[0] + non_webp_ext
            non_webp_path = os.path.join(storage_dir, non_webp_filename)
            img.convert('RGB').save(non_webp_path, 'JPEG', quality=85, optimize=True)
            
        return os.path.join(range_dir, filename)
        
    except Exception as e:
        current_app.logger.error(f"Failed to download image {image_url}: {str(e)}")
        return None

def process_product_images(product_id, main_image_url=None, extra_image_urls=None):
    """
    Process and store product images.
    
    Args:
        product_id (int): Product ID
        main_image_url (str, optional): Main image URL
        extra_image_urls (list, optional): List of extra image URLs
        
    Returns:
        tuple: (main_image_path, list_of_extra_image_paths)
    """
    product = Product.query.get(product_id)
    if not product:
        return None, []
        
    main_image_path = None
    extra_image_paths = []
    
    # Process main image
    if main_image_url:
        main_image_path = download_and_store_image(main_image_url, product.sku, is_main=True)
        if main_image_path:
            product.main_image_url = main_image_path
            
    # Process extra images
    if extra_image_urls:
        for url in extra_image_urls:
            path = download_and_store_image(url, product.sku, is_main=False)
            if path:
                extra_image_paths.append(path)
        
        if extra_image_paths:
            product.extra_image_urls = extra_image_paths
            
    db.session.commit()
    return main_image_path, extra_image_paths

def get_image_url(image_path, fallback_url=None):
    """
    Get the full URL for an image path, with fallback for webp.
    
    Args:
        image_path (str): Relative path to the image
        fallback_url (str, optional): Fallback URL if image doesn't exist
        
    Returns:
        str: Full URL to the image
    """
    if not image_path:
        return fallback_url
        
    # Check if file exists
    full_path = os.path.join(current_app.config['PRODUCT_IMAGES_DIR'], image_path)
    if not os.path.exists(full_path):
        return fallback_url
        
    # If webp, check for jpg version
    if image_path.lower().endswith('.webp'):
        jpg_path = os.path.splitext(image_path)[0] + '.jpg'
        full_jpg_path = os.path.join(current_app.config['PRODUCT_IMAGES_DIR'], jpg_path)
        if os.path.exists(full_jpg_path):
            return f"/static/images/products/{jpg_path}"
            
    return f"/static/images/products/{image_path}" 