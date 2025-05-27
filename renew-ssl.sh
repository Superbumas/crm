#!/bin/bash

# SSL Certificate Renewal Script for CRM Application
# This script renews Let's Encrypt certificates and updates Docker containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to the CRM directory
cd "$(dirname "$0")"

echo -e "${GREEN}=== SSL Certificate Renewal Check ===${NC}"
echo "$(date): Starting certificate renewal check"

# Check if certificates need renewal
if sudo certbot renew --dry-run --quiet; then
    echo -e "${GREEN}✓ Renewal test passed${NC}"
    
    # Actually renew certificates
    echo -e "${YELLOW}Renewing certificates...${NC}"
    sudo certbot renew --quiet
    
    # Copy renewed certificates to docker volumes
    echo -e "${YELLOW}Updating Docker certificate volumes...${NC}"
    sudo cp -r /etc/letsencrypt/live/ ./certbot/conf/
    sudo cp -r /etc/letsencrypt/archive/ ./certbot/conf/
    sudo cp -r /etc/letsencrypt/renewal/ ./certbot/conf/
    sudo chown -R $USER:$USER ./certbot/
    
    # Restart nginx to load new certificates
    echo -e "${YELLOW}Restarting nginx...${NC}"
    docker-compose restart nginx
    
    # Test HTTPS to make sure it's working
    if curl -I -s --connect-timeout 10 https://crm.vakasport.lt | grep -q "HTTP"; then
        echo -e "${GREEN}✓ HTTPS is working with renewed certificates${NC}"
    else
        echo -e "${RED}✗ HTTPS test failed after renewal${NC}"
        # Send alert or log error
        echo "$(date): HTTPS test failed after certificate renewal" >> /var/log/ssl-renewal.log
    fi
    
    echo -e "${GREEN}✓ Certificate renewal completed successfully${NC}"
    echo "$(date): Certificate renewal completed successfully" >> /var/log/ssl-renewal.log
    
else
    echo -e "${YELLOW}No renewal needed or renewal test failed${NC}"
    echo "$(date): No renewal needed" >> /var/log/ssl-renewal.log
fi

# Show certificate status
echo -e "${GREEN}Current certificate status:${NC}"
sudo certbot certificates 