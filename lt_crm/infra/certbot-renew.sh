#!/bin/bash
# Script to automatically renew LetsEncrypt certificates for LT CRM

# Set working directory
cd "$(dirname "$0")"

# Log file
LOG_FILE="certbot-renewal.log"
EMAIL="admin@example.com"  # Change to your email
DOMAIN="your-domain.com"   # Change to your domain

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting LetsEncrypt certificate renewal"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_message "Error: Docker is not running"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    log_message "Error: docker-compose is not installed"
    exit 1
fi

# Check for existing certificates
if [ ! -d "./certbot/conf/live/$DOMAIN" ]; then
    log_message "No existing certificates found. Attempting initial certificate creation."
    
    # Create initial certificates
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN" \
        -d "www.$DOMAIN"
    
    if [ $? -ne 0 ]; then
        log_message "Failed to create initial certificates"
        exit 1
    fi
    
    log_message "Initial certificates created successfully"
    
    # Reload nginx to apply new certificates
    docker-compose exec nginx nginx -s reload
    log_message "Nginx reloaded with new certificates"
else
    # Renew existing certificates
    log_message "Attempting to renew existing certificates"
    
    docker-compose run --rm certbot renew --quiet
    
    if [ $? -ne 0 ]; then
        log_message "Certificate renewal failed"
        exit 1
    fi
    
    log_message "Certificates renewed successfully"
    
    # Reload nginx to apply renewed certificates
    docker-compose exec nginx nginx -s reload
    log_message "Nginx reloaded with renewed certificates"
fi

log_message "Certificate renewal process completed"
exit 0 