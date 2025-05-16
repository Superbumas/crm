#!/bin/bash
# Bash script to run LT CRM locally with Docker

echo "Starting LT CRM with Docker..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start the containers
echo "Building and starting containers..."
docker-compose up --build -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 5

# Run database migrations
echo "Running database migrations..."
docker-compose exec -T web flask db upgrade

# Setup default accounts
echo "Setting up default accounts..."
docker-compose exec -T web flask setup-accounts

# Seed demo data (optional)
read -p "Would you like to seed demo data? (y/n): " seedDemo
if [ "$seedDemo" = "y" ]; then
    echo "Seeding demo data..."
    docker-compose exec -T web flask seed-demo
fi

# Show running containers
echo "Services are now running:"
docker-compose ps

echo ""
echo "LT CRM is now available at: http://localhost:80"
echo "Use Ctrl+C to stop viewing logs."
echo "To stop the application, run: docker-compose down"

# Show logs
docker-compose logs -f 