"""Configuration settings for the CRM application."""
import os

# Base directory of the application
BASE_DIR = os.path.abspath(os.path.dirname(__file__))

# Product images directory
PRODUCT_IMAGES_DIR = os.path.join(BASE_DIR, 'static', 'images', 'products')

# CSRF settings
WTF_CSRF_ENABLED = False

# File upload settings
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
ALLOWED_IMAGE_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
