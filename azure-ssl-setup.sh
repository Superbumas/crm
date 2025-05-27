#!/bin/bash

# Azure VM SSL Setup Script
# This script prepares your Azure Linux VM for SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure VM SSL Setup ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Update system
echo -e "${GREEN}Updating system packages...${NC}"
apt-get update -y

# Install required packages
echo -e "${GREEN}Installing required packages...${NC}"
apt-get install -y curl wget git ufw

# Configure firewall
echo -e "${GREEN}Configuring firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo -e "${GREEN}Firewall status:${NC}"
ufw status

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}Installing Docker...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
else
    echo -e "${YELLOW}Docker is already installed${NC}"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo -e "${YELLOW}Docker Compose is already installed${NC}"
fi

# Create docker group and add user
echo -e "${GREEN}Setting up Docker permissions...${NC}"
groupadd -f docker
if [ ! -z "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    echo -e "${YELLOW}Added $SUDO_USER to docker group${NC}"
fi

# Check Azure VM metadata for public IP
echo -e "${GREEN}Getting Azure VM public IP...${NC}"
PUBLIC_IP=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01&format=text" || echo "Could not retrieve")

echo -e "${GREEN}Azure VM setup complete!${NC}"
echo -e "${YELLOW}=== Next Steps ===${NC}"
echo -e "${YELLOW}1. Your VM's public IP: $PUBLIC_IP${NC}"
echo -e "${YELLOW}2. Configure your domain's A record to point to: $PUBLIC_IP${NC}"
echo -e "${YELLOW}3. Wait for DNS propagation (use 'dig your-domain.com' to check)${NC}"
echo -e "${YELLOW}4. Clone your CRM repository to this VM${NC}"
echo -e "${YELLOW}5. Run: chmod +x setup-ssl.sh && ./setup-ssl.sh your-domain.com${NC}"

echo -e "${GREEN}=== DNS Configuration Example ===${NC}"
echo -e "${YELLOW}In your domain registrar's DNS settings, add:${NC}"
echo -e "${GREEN}A record: your-domain.com -> $PUBLIC_IP${NC}"
echo -e "${GREEN}A record: www.your-domain.com -> $PUBLIC_IP${NC}"

echo -e "${YELLOW}=== Azure Network Security Group ===${NC}"
echo -e "${YELLOW}Ensure your Azure NSG allows:${NC}"
echo -e "${GREEN}- Port 22 (SSH)${NC}"
echo -e "${GREEN}- Port 80 (HTTP)${NC}"
echo -e "${GREEN}- Port 443 (HTTPS)${NC}" 