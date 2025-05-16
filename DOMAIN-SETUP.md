# Setting Up Your Domain With CRM Application

This guide covers how to configure your domain to point to your CRM application running on an Azure VM.

## Prerequisites

- A registered domain name
- CRM application running on Azure VM with HTTP (port 80) enabled
- Access to your domain's DNS management

## Steps to Configure Your Domain

### 1. Set Up DNS Records

1. Log in to your domain registrar's website (e.g., GoDaddy, Namecheap, etc.)
2. Navigate to the DNS management section
3. Create an A record:
   - Type: A
   - Host/Name: @ (or subdomain like "crm" if desired)
   - Value/Points to: Your Azure VM's public IP address
   - TTL: 3600 (or as desired)
4. If you want "www" to work as well, add a CNAME record:
   - Type: CNAME
   - Host/Name: www
   - Value/Points to: Your domain name
   - TTL: 3600 (or as desired)

### 2. Restart Your Docker Services

After updating the docker-compose.yml to use port 80:

```bash
# Go to your application directory
cd /path/to/your/crm

# Stop current containers
docker-compose down

# Start with new configuration
docker-compose up -d
```

### 3. Verify Configuration

1. Wait for DNS propagation (can take up to 48 hours, but often much less)
2. Visit your domain in a browser (e.g., http://yourdomain.com)
3. You should now see your CRM application without needing to specify a port

### 4. Troubleshooting

If you can't access your site via the domain:

1. Verify that port 80 is open in your Azure Network Security Group
2. Confirm your VM's public IP address matches the A record
3. Check if Docker is running properly using `docker-compose ps`
4. Check application logs with `docker-compose logs web`
5. Verify with `nslookup yourdomain.com` that DNS is resolving to your VM's IP

### 5. Additional Security Considerations

For a production environment, consider:

1. Setting up HTTPS with Let's Encrypt or another SSL certificate provider
2. Implementing a reverse proxy like Nginx for better security and performance
3. Restricting access to pgAdmin and other administrative interfaces 