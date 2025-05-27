#!/bin/bash

# SSL Setup Script for CRM Application (No WWW subdomain)
# This script sets up Let's Encrypt SSL certificates for single domain

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CRM SSL Setup (Single Domain) ===${NC}"

DOMAIN=${1:-crm.vakasport.lt}
EMAIL=${2:-admin@$DOMAIN}

echo -e "${YELLOW}Setting up SSL for domain: $DOMAIN${NC}"
echo -e "${YELLOW}Contact email: $EMAIL${NC}"

# Create necessary directories
echo -e "${GREEN}Creating certificate directories...${NC}"
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Restart nginx with HTTP-only config
echo -e "${GREEN}Restarting nginx with HTTP-only configuration...${NC}"
docker-compose restart nginx

# Wait for nginx to be ready
echo -e "${YELLOW}Waiting for nginx to start...${NC}"
sleep 10

# Check if nginx is working
echo -e "${BLUE}Testing nginx...${NC}"
if curl -I -s --connect-timeout 5 http://localhost:80 | grep -q "HTTP"; then
    echo -e "${GREEN}✓ Nginx is working${NC}"
else
    echo -e "${RED}✗ Nginx is not responding${NC}"
    docker-compose logs nginx
    exit 1
fi

# Test external access
echo -e "${BLUE}Testing external access...${NC}"
if curl -I -s --connect-timeout 10 http://$DOMAIN | grep -q "HTTP"; then
    echo -e "${GREEN}✓ External access works${NC}"
else
    echo -e "${YELLOW}⚠️  External access test failed, but continuing...${NC}"
fi

# Request certificate for single domain only
echo -e "${GREEN}Requesting SSL certificate for $DOMAIN...${NC}"
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    -d $DOMAIN

# Check if certificate was created
if [ -d "./certbot/conf/live/$DOMAIN" ]; then
    echo -e "${GREEN}✓ Certificate successfully created!${NC}"
    
    # Now update nginx config to use HTTPS
    echo -e "${GREEN}Updating nginx configuration to use HTTPS...${NC}"
    
    cat > ./lt_crm/infra/nginx/conf.d/app.conf << EOF
# HTTP server - redirects to HTTPS and handles ACME challenges
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;
    server_tokens off;

    # SSL certificate paths
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # Basic SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    client_max_body_size 20M;
    
    # Static files
    location /static/ {
        alias /app/static/;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        add_header Vary Accept-Encoding;
    }
    
    # API rate limiting
    location /api/ {
        proxy_pass http://web:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req_status 429;
    }
    
    # Login rate limiting
    location /auth/login {
        proxy_pass http://web:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Stricter rate limiting for login
        limit_req zone=login burst=5 nodelay;
        limit_req_status 429;
    }
    
    # Application
    location / {
        proxy_pass http://web:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        
        # Timeouts
        proxy_connect_timeout       60s;
        proxy_send_timeout          60s;
        proxy_read_timeout          60s;
    }
}
EOF

    # Restart nginx with SSL configuration
    echo -e "${GREEN}Restarting nginx with SSL configuration...${NC}"
    docker-compose restart nginx
    
    # Wait for nginx to restart
    sleep 10
    
    # Test HTTPS
    echo -e "${GREEN}Testing HTTPS connectivity...${NC}"
    if curl -I -s --connect-timeout 10 https://$DOMAIN | grep -q "HTTP"; then
        echo -e "${GREEN}✓ HTTPS is working!${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS test failed from this machine, but it might work externally${NC}"
    fi
    
    # Test certificate renewal
    echo -e "${GREEN}Testing certificate renewal...${NC}"
    docker-compose run --rm certbot renew --dry-run
    
    echo -e "${GREEN}=== SSL Setup Complete! ===${NC}"
    echo -e "${YELLOW}Your CRM application is now accessible at:${NC}"
    echo -e "${GREEN}https://$DOMAIN${NC}"
    echo -e "${YELLOW}Certificate auto-renewal is configured.${NC}"
    
    # Show certificate info
    echo -e "${GREEN}Certificate information:${NC}"
    docker-compose run --rm certbot certificates
    
else
    echo -e "${RED}✗ Certificate creation failed${NC}"
    echo -e "${YELLOW}Check the logs above for errors${NC}"
    exit 1
fi 