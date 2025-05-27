#!/bin/bash

# SSL Setup Script for CRM Application
# This script sets up Let's Encrypt SSL certificates for your domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CRM SSL Setup Script ===${NC}"

# Check if domain is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide your domain name${NC}"
    echo "Usage: $0 your-domain.com"
    echo "Example: $0 mycrm.example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-admin@$DOMAIN}

echo -e "${YELLOW}Setting up SSL for domain: $DOMAIN${NC}"
echo -e "${YELLOW}Contact email: $EMAIL${NC}"

# Create necessary directories
echo -e "${GREEN}Creating certificate directories...${NC}"
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Update nginx configuration with actual domain
echo -e "${GREEN}Updating nginx configuration...${NC}"
sed -i "s/your-domain.com/$DOMAIN/g" ./lt_crm/infra/nginx/conf.d/app.conf

# Start services without SSL first
echo -e "${GREEN}Starting services for initial certificate generation...${NC}"
docker-compose up -d nginx certbot

# Wait for nginx to be ready
echo -e "${YELLOW}Waiting for nginx to start...${NC}"
sleep 10

# Request certificate
echo -e "${GREEN}Requesting SSL certificate from Let's Encrypt...${NC}"
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

# Test certificate renewal
echo -e "${GREEN}Testing certificate renewal...${NC}"
docker-compose run --rm certbot renew --dry-run

# Restart nginx to load certificates
echo -e "${GREEN}Restarting nginx with SSL certificates...${NC}"
docker-compose restart nginx

echo -e "${GREEN}=== SSL Setup Complete! ===${NC}"
echo -e "${YELLOW}Your CRM application should now be accessible at:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo -e "${GREEN}https://www.$DOMAIN${NC}"

echo -e "${YELLOW}Certificate auto-renewal is configured and will run every 12 hours.${NC}"
echo -e "${YELLOW}Certificates are valid for 90 days and will be automatically renewed.${NC}"

# Show certificate info
echo -e "${GREEN}Certificate information:${NC}"
docker-compose run --rm certbot certificates 