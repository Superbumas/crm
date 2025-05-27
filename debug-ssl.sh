#!/bin/bash

# SSL Debug Script for CRM Application
# This script helps diagnose SSL setup issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMAIN=${1:-crm.vakasport.lt}

echo -e "${BLUE}=== SSL Setup Debugging for $DOMAIN ===${NC}"

# 1. Check DNS resolution
echo -e "\n${YELLOW}1. Checking DNS resolution...${NC}"
echo -e "${GREEN}Checking if $DOMAIN resolves:${NC}"
if dig +short $DOMAIN A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    RESOLVED_IP=$(dig +short $DOMAIN A | head -1)
    echo -e "${GREEN}✓ Domain resolves to: $RESOLVED_IP${NC}"
else
    echo -e "${RED}✗ Domain does not resolve or no A record found${NC}"
fi

echo -e "${GREEN}Checking www.$DOMAIN:${NC}"
if dig +short www.$DOMAIN A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
    WWW_IP=$(dig +short www.$DOMAIN A | head -1)
    echo -e "${GREEN}✓ www.$DOMAIN resolves to: $WWW_IP${NC}"
else
    echo -e "${RED}✗ www.$DOMAIN does not resolve${NC}"
fi

# 2. Check if services are running
echo -e "\n${YELLOW}2. Checking Docker services...${NC}"
docker-compose ps

# 3. Check nginx logs
echo -e "\n${YELLOW}3. Recent nginx logs:${NC}"
docker-compose logs --tail=20 nginx

# 4. Check certbot logs
echo -e "\n${YELLOW}4. Recent certbot logs:${NC}"
docker-compose logs --tail=20 certbot

# 5. Test HTTP connectivity
echo -e "\n${YELLOW}5. Testing HTTP connectivity...${NC}"
echo -e "${GREEN}Testing local nginx (port 80):${NC}"
if curl -I -s --connect-timeout 5 http://localhost:80 | head -1; then
    echo -e "${GREEN}✓ Local nginx responds on port 80${NC}"
else
    echo -e "${RED}✗ Local nginx not responding on port 80${NC}"
fi

echo -e "${GREEN}Testing external HTTP access to $DOMAIN:${NC}"
if curl -I -s --connect-timeout 10 http://$DOMAIN | head -1; then
    echo -e "${GREEN}✓ External HTTP access works${NC}"
else
    echo -e "${RED}✗ External HTTP access failed${NC}"
fi

# 6. Test ACME challenge path
echo -e "\n${YELLOW}6. Testing ACME challenge path...${NC}"
echo -e "${GREEN}Testing /.well-known/acme-challenge/ path:${NC}"
if curl -I -s --connect-timeout 10 http://$DOMAIN/.well-known/acme-challenge/test | head -1; then
    echo -e "${GREEN}✓ ACME challenge path accessible${NC}"
else
    echo -e "${RED}✗ ACME challenge path not accessible${NC}"
fi

# 7. Check firewall status (if UFW is available)
echo -e "\n${YELLOW}7. Checking firewall status...${NC}"
if command -v ufw &> /dev/null; then
    echo -e "${GREEN}UFW status:${NC}"
    sudo ufw status 2>/dev/null || echo "Cannot check UFW status (permission denied)"
else
    echo -e "${YELLOW}UFW not available${NC}"
fi

# 8. Check port availability
echo -e "\n${YELLOW}8. Checking port availability...${NC}"
echo -e "${GREEN}Listening ports:${NC}"
netstat -tlnp 2>/dev/null | grep -E ':80|:443' || echo "No HTTP/HTTPS ports found listening"

# 9. Suggest fixes
echo -e "\n${BLUE}=== Recommended Actions ===${NC}"

if ! dig +short $DOMAIN A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' > /dev/null; then
    echo -e "${RED}🔧 DNS Issue: Configure your domain's A record to point to your Azure VM's public IP${NC}"
fi

echo -e "${YELLOW}📋 Manual certificate request (for testing):${NC}"
echo -e "${GREEN}docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@$DOMAIN --agree-tos --no-eff-email --staging -d $DOMAIN${NC}"

echo -e "${YELLOW}📋 If DNS is correct, try requesting certificate without www:${NC}"
echo -e "${GREEN}docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@$DOMAIN --agree-tos --no-eff-email -d $DOMAIN${NC}"

echo -e "${YELLOW}📋 Check Azure Network Security Group allows:${NC}"
echo -e "${GREEN}- Inbound port 80 (HTTP)${NC}"
echo -e "${GREEN}- Inbound port 443 (HTTPS)${NC}"
echo -e "${GREEN}- Inbound port 22 (SSH)${NC}" 