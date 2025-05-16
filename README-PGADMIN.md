# Using pgAdmin with the CRM System

This document explains how to use pgAdmin, which has been added to the Docker setup to provide a graphical interface for the PostgreSQL database.

## Accessing pgAdmin

1. Start your Docker environment with:
   ```
   docker-compose up -d
   ```

2. Open your browser and navigate to:
   ```
   http://localhost:5050
   ```

3. Log in with the following credentials:
   - Email: admin@example.com
   - Password: admin

## Connecting to the PostgreSQL Database

Once logged in, follow these steps to connect to your CRM database:

1. Right-click on "Servers" in the left panel and select "Create" > "Server..."

2. In the "General" tab, give your connection a name (e.g., "CRM Database")

3. Switch to the "Connection" tab and enter the following details:
   - Host name/address: `postgres` (use the Docker service name)
   - Port: `5432`
   - Maintenance database: `lt_crm`
   - Username: `postgres`
   - Password: `password`

4. If you want pgAdmin to remember the password, check "Save password"

5. Click "Save" to establish the connection

## Managing Your Database

Once connected, you can:
- Browse tables, views, and other database objects
- Run SQL queries using the Query Tool (right-click on the database and select "Query Tool")
- Create database backups
- View and modify table data
- Manage users, roles, and permissions

## Customizing pgAdmin

If you need to change the default email or password, update the environment variables in the `docker-compose.yml` file:

```yaml
pgadmin:
  image: dpage/pgadmin4
  environment:
    - PGADMIN_DEFAULT_EMAIL=your-email@example.com
    - PGADMIN_DEFAULT_PASSWORD=your-password
```

Then restart the Docker containers:

```
docker-compose down
docker-compose up -d
```

## Persistent Data

The pgAdmin configuration and data are stored in a Docker volume named `pgadmin_data`. This ensures your settings are preserved between container restarts.

## Security Notes

- The default credentials provided are for development purposes only
- For production environments, set strong, unique credentials
- Consider using environment variables or Docker secrets for sensitive information
- Restrict access to pgAdmin by configuring proper firewall rules 