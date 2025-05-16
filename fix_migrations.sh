#!/bin/bash
# Script to fix migration issues in the Docker container

echo "Fixing migration issues for LT CRM..."

# Create migrations directory in the Docker container
docker-compose exec web mkdir -p /app/migrations

# Copy migrations from lt_crm/migrations to the Docker container
echo "Copying migration files to Docker container..."
docker cp lt_crm/migrations/alembic.ini $(docker-compose ps -q web):/app/migrations/
docker cp lt_crm/migrations/env.py $(docker-compose ps -q web):/app/migrations/
docker cp lt_crm/migrations/README $(docker-compose ps -q web):/app/migrations/
docker cp lt_crm/migrations/script.py.mako $(docker-compose ps -q web):/app/migrations/

# Create versions directory and copy migration files
docker-compose exec web mkdir -p /app/migrations/versions
docker cp lt_crm/migrations/versions/. $(docker-compose ps -q web):/app/migrations/versions/

# Apply migrations
echo "Applying database migrations..."
docker-compose exec web flask db upgrade

# Setup default accounts
echo "Setting up default accounts..."
docker-compose exec web flask setup-accounts

echo "Migration fix complete!"
