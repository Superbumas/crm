#!/bin/bash
# Script to open port 80 on Azure VM Network Security Group

# Replace these values with your actual resource names
RESOURCE_GROUP="your-resource-group-name"
NSG_NAME="your-vm-nsg-name"

# Open port 80 for HTTP
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $NSG_NAME \
  --name AllowHTTP \
  --protocol tcp \
  --direction inbound \
  --priority 1001 \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 80 \
  --access allow

echo "Port 80 has been opened in the Network Security Group $NSG_NAME"

# Open ports in the firewall for the CRM application
sudo ufw allow 5050/tcp
sudo ufw allow 5432/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "Firewall ports opened for CRM application" 