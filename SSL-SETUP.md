# SSL Certificate Setup for CRM Application

This guide covers setting up SSL certificates for your CRM application running in Docker on an Azure Linux VM.

## Overview

We use **Let's Encrypt** with **Certbot** for free, automatically renewable SSL certificates. The setup includes:
- Nginx reverse proxy with SSL termination
- Automatic certificate renewal
- Security headers and rate limiting
- Firewall configuration

## Prerequisites

1. **Domain Name**: You need a registered domain (e.g., `mycrm.example.com`)
2. **Azure Linux VM**: With public IP address
3. **DNS Configuration**: Domain pointing to your VM's public IP
4. **Network Security Group**: Ports 80, 443, and 22 open

## Quick Setup (Recommended)

### Step 1: Prepare Azure VM

```bash
# On your Azure Linux VM, run as root:
sudo bash azure-ssl-setup.sh
```

This script will:
- Install Docker and Docker Compose
- Configure the firewall (UFW)
- Display your public IP address
- Provide DNS configuration instructions

### Step 2: Configure DNS

In your domain registrar's DNS settings, add these A records:
```
your-domain.com        → YOUR_VM_PUBLIC_IP
www.your-domain.com    → YOUR_VM_PUBLIC_IP
```

**Wait for DNS propagation** (usually 5-15 minutes). Test with:
```bash
dig your-domain.com
nslookup your-domain.com
```

### Step 3: Deploy with SSL

```bash
# Make the SSL setup script executable
chmod +x setup-ssl.sh

# Run SSL setup (replace with your actual domain)
./setup-ssl.sh your-domain.com your-email@domain.com
```

This will:
- Update nginx configuration with your domain
- Request SSL certificates from Let's Encrypt
- Configure automatic renewal
- Start all services with HTTPS

## Manual Setup

If you prefer manual setup or need to troubleshoot:

### 1. Update docker-compose.yml

The docker-compose.yml has been updated to include:
- Nginx service with SSL configuration
- Certbot service for certificate management
- Proper volume mounts for certificates

### 2. Configure Nginx

Update `lt_crm/infra/nginx/conf.d/app.conf`:
- Replace `your-domain.com` with your actual domain
- Ensure certificate paths match your domain

### 3. Initial Certificate Request

```bash
# Start services
docker-compose up -d nginx certbot

# Request initial certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@domain.com \
    --agree-tos \
    --no-eff-email \
    -d your-domain.com \
    -d www.your-domain.com

# Restart nginx
docker-compose restart nginx
```

## Alternative SSL Solutions

### 1. Azure Application Gateway with SSL

For enterprise setups, consider Azure Application Gateway:
- Managed SSL certificates
- Web Application Firewall (WAF)
- Load balancing capabilities
- Integration with Azure Key Vault

### 2. Cloudflare SSL

If using Cloudflare as your DNS provider:
- Free SSL certificates
- DDoS protection
- Global CDN
- Additional security features

### 3. Traditional CA Certificates

For internal/corporate environments:
- Purchase certificates from trusted CAs
- Longer validity periods
- Extended validation options

## Troubleshooting

### Certificate Request Failed

```bash
# Check nginx logs
docker-compose logs nginx

# Check certbot logs
docker-compose logs certbot

# Verify domain points to your server
curl -I http://your-domain.com/.well-known/acme-challenge/test
```

### DNS Issues

```bash
# Check if domain resolves to your IP
dig your-domain.com A
nslookup your-domain.com

# Test HTTP connectivity
curl -I http://your-domain.com
```

### Firewall Issues

```bash
# Check UFW status
sudo ufw status

# Check if ports are open
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Test external connectivity
telnet your-domain.com 80
telnet your-domain.com 443
```

### Azure Network Security Group

Ensure your Azure NSG rules allow:
- **Port 22**: SSH access
- **Port 80**: HTTP (for ACME challenges)
- **Port 443**: HTTPS (for secure access)

## Security Features

The SSL setup includes:

### Security Headers
- `X-Frame-Options`: Prevents clickjacking
- `X-XSS-Protection`: XSS protection
- `X-Content-Type-Options`: MIME type sniffing protection
- `Strict-Transport-Security`: Forces HTTPS
- `Content-Security-Policy`: Controls resource loading

### Rate Limiting
- **API endpoints**: 10 requests/second
- **Login endpoint**: 3 requests/second
- Burst allowances for normal usage

### SSL Configuration
- TLS 1.2 and 1.3 only
- Strong cipher preferences
- OCSP stapling
- Perfect Forward Secrecy

## Monitoring and Maintenance

### Certificate Renewal

Certificates are automatically renewed every 12 hours. To manually check:

```bash
# Test renewal
docker-compose run --rm certbot renew --dry-run

# Force renewal
docker-compose run --rm certbot renew --force-renewal

# Check certificate expiry
docker-compose run --rm certbot certificates
```

### Logs Monitoring

```bash
# View nginx access logs
docker-compose logs -f nginx

# View application logs
docker-compose logs -f web

# View certificate renewal logs
docker-compose logs certbot
```

### Health Checks

```bash
# Test HTTPS connectivity
curl -I https://your-domain.com

# Check SSL certificate details
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# SSL Labs test (external)
# Visit: https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com
```

## Production Considerations

### Backup Certificates

```bash
# Backup certificates directory
sudo tar -czf ssl-certificates-backup-$(date +%Y%m%d).tar.gz ./certbot/conf/

# Store backup securely (Azure Blob Storage, etc.)
```

### Multiple Domains

To add additional domains:

```bash
# Add to existing certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@domain.com \
    --agree-tos \
    --expand \
    -d your-domain.com \
    -d www.your-domain.com \
    -d api.your-domain.com \
    -d admin.your-domain.com
```

### High Availability

For production HA setup:
- Use Azure Load Balancer with multiple VMs
- Shared storage for certificates (Azure Files)
- Database clustering
- Redis clustering

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Docker and nginx logs
3. Verify DNS configuration
4. Test with Let's Encrypt staging environment first

For Let's Encrypt rate limits and staging:
```bash
# Use staging environment for testing
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@domain.com \
    --agree-tos \
    --staging \
    -d your-domain.com
``` 