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
import logging

# Set up logger for image service
logger = logging.getLogger("image_service")
if not logger.hasHandlers():
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)
    logger.addHandler(handler)
logger.setLevel(logging.INFO)

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
    logger.info(f"Starting image download for SKU {product_sku}: {image_url}")
    try:
        # Validate URL
        parsed = urlparse(image_url)
        if not parsed.scheme or not parsed.netloc:
            logger.error(f"Invalid URL format for SKU {product_sku}: {image_url}")
            return None
            
        logger.info(f"Downloading image from {image_url}")
        # Download image
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()
        logger.info(f"Downloaded {len(response.content)} bytes for SKU {product_sku}")
        
        # Open image to validate and get format
        img = Image.open(BytesIO(response.content))
        logger.info(f"Image format: {img.format}, size: {img.size} for SKU {product_sku}")
        
        # Generate filename
        original_ext = os.path.splitext(parsed.path)[1].lower()
        if not original_ext:
            original_ext = f".{img.format.lower()}" if img.format else ".jpg"
        
        # Create a filesystem-safe filename while preserving the SKU
        # Replace problematic characters but keep the SKU readable
        safe_sku = product_sku.replace('/', '-').replace('\\', '-').replace(':', '-').replace('*', '-').replace('?', '-').replace('"', '-').replace('<', '-').replace('>', '-').replace('|', '-')
        filename = f"{'main' if is_main else 'extra'}_{safe_sku}{original_ext}"
        logger.info(f"Generated filename: {filename} for SKU {product_sku}")
        
        # Determine storage directory based on SKU
        sku_num = int(''.join(filter(str.isdigit, product_sku)) or '0')
        range_dir = f"{(sku_num // 1000) * 1000}-{((sku_num // 1000) + 1) * 1000 - 1}"
        
        # Create directory if it doesn't exist
        storage_dir = os.path.join(current_app.config['PRODUCT_IMAGES_DIR'], range_dir)
        logger.info(f"Storage directory: {storage_dir} for SKU {product_sku}")
        os.makedirs(storage_dir, exist_ok=True)
        
        # Save image
        img_path = os.path.join(storage_dir, filename)
        img.save(img_path, quality=85, optimize=True)
        logger.info(f"Image saved successfully to {img_path} for SKU {product_sku}")
        
        # If webp, also save in original format for compatibility
        if img.format.lower() == 'webp':
            non_webp_ext = '.jpg'
            non_webp_filename = os.path.splitext(filename)[0] + non_webp_ext
            non_webp_path = os.path.join(storage_dir, non_webp_filename)
            img.convert('RGB').save(non_webp_path, 'JPEG', quality=85, optimize=True)
            logger.info(f"Also saved WebP as JPG: {non_webp_path} for SKU {product_sku}")
            
        relative_path = os.path.join(range_dir, filename)
        logger.info(f"Returning relative path: {relative_path} for SKU {product_sku}")
        return relative_path
        
    except Exception as e:
        logger.error(f"Failed to download image {image_url} for SKU {product_sku}: {str(e)}")
        current_app.logger.error(f"Failed to download image {image_url}: {str(e)}")
        return None

def download_and_store_image_with_index(image_url, product_sku, index):
    """
    Download image from URL and store it locally with an index for extra images.
    
    Args:
        image_url (str): URL of the image to download
        product_sku (str): SKU of the product
        index (int): Index number for the extra image
        
    Returns:
        str: Local path to the stored image or None if failed
    """
    logger.info(f"Starting extra image {index} download for SKU {product_sku}: {image_url}")
    try:
        # Validate URL
        parsed = urlparse(image_url)
        if not parsed.scheme or not parsed.netloc:
            logger.error(f"Invalid URL format for SKU {product_sku} image {index}: {image_url}")
            return None
            
        logger.info(f"Downloading extra image {index} from {image_url}")
        # Download image
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()
        logger.info(f"Downloaded {len(response.content)} bytes for SKU {product_sku} image {index}")
        
        # Open image to validate and get format
        img = Image.open(BytesIO(response.content))
        logger.info(f"Extra image {index} format: {img.format}, size: {img.size} for SKU {product_sku}")
        
        # Generate filename with index
        original_ext = os.path.splitext(parsed.path)[1].lower()
        if not original_ext:
            original_ext = f".{img.format.lower()}" if img.format else ".jpg"
        
        # Create a filesystem-safe filename while preserving the SKU
        # Replace problematic characters but keep the SKU readable
        safe_sku = product_sku.replace('/', '-').replace('\\', '-').replace(':', '-').replace('*', '-').replace('?', '-').replace('"', '-').replace('<', '-').replace('>', '-').replace('|', '-')
        filename = f"extra_{index}_{safe_sku}{original_ext}"
        logger.info(f"Generated filename: {filename} for SKU {product_sku} image {index}")
        
        # Determine storage directory based on SKU
        sku_num = int(''.join(filter(str.isdigit, product_sku)) or '0')
        range_dir = f"{(sku_num // 1000) * 1000}-{((sku_num // 1000) + 1) * 1000 - 1}"
        
        # Create directory if it doesn't exist
        storage_dir = os.path.join(current_app.config['PRODUCT_IMAGES_DIR'], range_dir)
        logger.info(f"Storage directory: {storage_dir} for SKU {product_sku} image {index}")
        os.makedirs(storage_dir, exist_ok=True)
        
        # Save image
        img_path = os.path.join(storage_dir, filename)
        img.save(img_path, quality=85, optimize=True)
        logger.info(f"Extra image {index} saved successfully to {img_path} for SKU {product_sku}")
        
        # If webp, also save in original format for compatibility
        if img.format.lower() == 'webp':
            non_webp_ext = '.jpg'
            non_webp_filename = os.path.splitext(filename)[0] + non_webp_ext
            non_webp_path = os.path.join(storage_dir, non_webp_filename)
            img.convert('RGB').save(non_webp_path, 'JPEG', quality=85, optimize=True)
            logger.info(f"Also saved WebP as JPG: {non_webp_path} for SKU {product_sku} image {index}")
            
        relative_path = os.path.join(range_dir, filename)
        logger.info(f"Returning relative path: {relative_path} for SKU {product_sku} image {index}")
        return relative_path
        
    except Exception as e:
        logger.error(f"Failed to download extra image {index} {image_url} for SKU {product_sku}: {str(e)}")
        current_app.logger.error(f"Failed to download extra image {index} {image_url}: {str(e)}")
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
    logger.info(f"Processing images for product ID {product_id}")
    logger.info(f"Main image URL: {main_image_url}")
    logger.info(f"Extra image URLs: {extra_image_urls}")
    
    product = Product.query.get(product_id)
    if not product:
        logger.error(f"Product with ID {product_id} not found")
        return None, []
        
    main_image_path = None
    extra_image_paths = []
    
    # Process main image
    if main_image_url:
        logger.info(f"Processing main image for SKU {product.sku}")
        main_image_path = download_and_store_image(main_image_url, product.sku, is_main=True)
        if main_image_path:
            product.main_image_url = main_image_path
            logger.info(f"Main image processed successfully: {main_image_path}")
        else:
            logger.error(f"Failed to process main image for SKU {product.sku}")
            
    # Process extra images
    if extra_image_urls and isinstance(extra_image_urls, list):
        logger.info(f"Processing {len(extra_image_urls)} extra images for SKU {product.sku}")
        for index, url in enumerate(extra_image_urls, 1):
            logger.info(f"Processing extra image {index}/{len(extra_image_urls)}: {url}")
            path = download_and_store_image_with_index(url, product.sku, index)
            if path:
                extra_image_paths.append(path)
                logger.info(f"Extra image {index} processed successfully: {path}")
            else:
                logger.error(f"Failed to process extra image {index} for SKU {product.sku}")
        
        if extra_image_paths:
            product.extra_image_urls = extra_image_paths
            logger.info(f"All extra images processed. Total: {len(extra_image_paths)}")
    elif extra_image_urls:
        logger.warning(f"Extra image URLs is not a list for SKU {product.sku}: {type(extra_image_urls)}")
            
    db.session.commit()
    logger.info(f"Image processing completed for SKU {product.sku}")
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