#!/bin/bash
# Script to set up necessary secrets in Fly.io for LT CRM deployment

# Ensure flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "Error: flyctl is not installed. Please install it first."
    echo "Visit: https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "You are not logged in to Fly.io. Please login first."
    flyctl auth login
fi

# Set app name
APP_NAME="lt-crm"
if [ -n "$1" ]; then
    APP_NAME=$1
fi

echo "Setting up secrets for app: $APP_NAME"

# Generate a secure random secret key
SECRET_KEY=$(openssl rand -hex 32)
echo "Generated random SECRET_KEY"

# Prompt for PostgreSQL password
read -p "Enter PostgreSQL password: " POSTGRES_PASSWORD

# Prompt for Sentry DSN (optional)
read -p "Enter Sentry DSN (optional, press Enter to skip): " SENTRY_DSN

# Set secrets
echo "Setting secrets in Fly.io..."

flyctl secrets set \
    SECRET_KEY="$SECRET_KEY" \
    POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@${APP_NAME}-db.internal:5432/lt_crm" \
    REDIS_URL="redis://${APP_NAME}-redis.internal:6379/0" \
    CELERY_BROKER_URL="redis://${APP_NAME}-redis.internal:6379/1" \
    CELERY_RESULT_BACKEND="redis://${APP_NAME}-redis.internal:6379/1" \
    --app "$APP_NAME"

# Set Sentry DSN if provided
if [ -n "$SENTRY_DSN" ]; then
    flyctl secrets set SENTRY_DSN="$SENTRY_DSN" --app "$APP_NAME"
    echo "Sentry DSN configured."
fi

echo "Secrets setup completed for $APP_NAME"
echo "You can now deploy your application with: flyctl deploy" 