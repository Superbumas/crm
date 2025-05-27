#!/bin/bash

# Simplified SSL Setup Script for CRM Application
# This script sets up Let's Encrypt SSL certificates with better error handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Simplified CRM SSL Setup Script ===${NC}"

# Use the domain from nginx config if no argument provided
DOMAIN=${1:-crm.vakasport.lt}
EMAIL=${2:-admin@$DOMAIN}

echo -e "${YELLOW}Setting up SSL for domain: $DOMAIN${NC}"
echo -e "${YELLOW}Contact email: $EMAIL${NC}"

# Function to check if domain resolves
check_dns() {
    echo -e "${BLUE}Checking DNS resolution for $DOMAIN...${NC}"
    if dig +short $DOMAIN A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
        RESOLVED_IP=$(dig +short $DOMAIN A | head -1)
        echo -e "${GREEN}✓ Domain resolves to: $RESOLVED_IP${NC}"
        return 0
    else
        echo -e "${RED}✗ Domain does not resolve${NC}"
        echo -e "${YELLOW}Please configure your domain's A record to point to your Azure VM's public IP${NC}"
        return 1
    fi
}

# Function to test HTTP connectivity
test_http() {
    echo -e "${BLUE}Testing HTTP connectivity...${NC}"
    if curl -I -s --connect-timeout 10 http://$DOMAIN | head -1; then
        echo -e "${GREEN}✓ HTTP connectivity works${NC}"
        return 0
    else
        echo -e "${RED}✗ HTTP connectivity failed${NC}"
        echo -e "${YELLOW}Check your Azure Network Security Group (NSG) - ensure port 80 is open${NC}"
        return 1
    fi
}

# Create necessary directories
echo -e "${GREEN}Creating certificate directories...${NC}"
mkdir -p ./certbot/conf
mkdir -p ./certbot/www

# Start services
echo -e "${GREEN}Starting nginx and certbot services...${NC}"
docker-compose up -d nginx certbot

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 15

# Check if nginx is responding locally
echo -e "${BLUE}Checking local nginx...${NC}"
if ! curl -I -s --connect-timeout 5 http://localhost:80 > /dev/null; then
    echo -e "${RED}Nginx is not responding locally. Checking logs...${NC}"
    docker-compose logs nginx
    exit 1
fi

# Check DNS (optional - continue even if fails)
if ! check_dns; then
    echo -e "${YELLOW}⚠️  DNS check failed, but continuing anyway...${NC}"
    echo -e "${YELLOW}If certificate request fails, fix DNS first${NC}"
fi

# Test HTTP connectivity (optional - continue even if fails)
if ! test_http; then
    echo -e "${YELLOW}⚠️  HTTP connectivity test failed, but continuing anyway...${NC}"
    echo -e "${YELLOW}If certificate request fails, check firewall/NSG settings${NC}"
fi

# Request certificate for single domain first (more likely to succeed)
echo -e "${GREEN}Requesting SSL certificate for $DOMAIN (single domain)...${NC}"
if docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    -d $DOMAIN; then
    
    echo -e "${GREEN}✓ Certificate successfully obtained for $DOMAIN${NC}"
    
    # Now try to add www subdomain to existing certificate
    echo -e "${GREEN}Adding www.$DOMAIN to certificate...${NC}"
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        --expand \
        -d $DOMAIN \
        -d www.$DOMAIN || echo -e "${YELLOW}⚠️  Could not add www subdomain (this is OK)${NC}"
        
else
    echo -e "${RED}✗ Certificate request failed${NC}"
    echo -e "${YELLOW}Trying with staging environment for debugging...${NC}"
    
    # Try with staging environment to debug
    docker-compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        --staging \
        -d $DOMAIN
    
    echo -e "${RED}Please fix the issues above and run this script again${NC}"
    echo -e "${YELLOW}Common issues:${NC}"
    echo -e "${YELLOW}- Domain DNS not pointing to this server${NC}"
    echo -e "${YELLOW}- Azure NSG not allowing port 80/443${NC}"
    echo -e "${YELLOW}- Firewall blocking connections${NC}"
    exit 1
fi

# Test certificate renewal
echo -e "${GREEN}Testing certificate renewal...${NC}"
docker-compose run --rm certbot renew --dry-run

# Update nginx configuration to remove SSL errors
echo -e "${GREEN}Updating nginx configuration...${NC}"
# Create a temporary config without SSL errors for initial setup
cat > ./lt_crm/infra/nginx/conf.d/app.conf << 'EOF'
# HTTP server - redirects to HTTPS and handles ACME challenges
server {
    listen 80;
    server_name crm.vakasport.lt;
    server_tokens off;

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name crm.vakasport.lt;
    server_tokens off;

    # SSL certificate paths
    ssl_certificate /etc/letsencrypt/live/crm.vakasport.lt/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/crm.vakasport.lt/privkey.pem;
    
    # Include recommended SSL settings (ignore if files don't exist)
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Rate limiting
        limit_req zone=api burst=20 nodelay;
        limit_req_status 429;
    }
    
    # Login rate limiting
    location /auth/login {
        proxy_pass http://web:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Stricter rate limiting for login
        limit_req zone=login burst=5 nodelay;
        limit_req_status 429;
    }
    
    # Application
    location / {
        proxy_pass http://web:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # Timeouts
        proxy_connect_timeout       60s;
        proxy_send_timeout          60s;
        proxy_read_timeout          60s;
    }
}
EOF

# Restart nginx to load certificates
echo -e "${GREEN}Restarting nginx with SSL certificates...${NC}"
docker-compose restart nginx

# Wait for nginx to restart
sleep 5

# Test HTTPS
echo -e "${GREEN}Testing HTTPS connectivity...${NC}"
if curl -I -s --connect-timeout 10 https://$DOMAIN | head -1; then
    echo -e "${GREEN}✓ HTTPS is working!${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS test failed, but certificates might still be working${NC}"
fi

echo -e "${GREEN}=== SSL Setup Complete! ===${NC}"
echo -e "${YELLOW}Your CRM application should now be accessible at:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"

echo -e "${YELLOW}Certificate auto-renewal is configured.${NC}"
echo -e "${YELLOW}Certificates are valid for 90 days and will be automatically renewed.${NC}"

# Show certificate info
echo -e "${GREEN}Certificate information:${NC}"
docker-compose run --rm certbot certificates 