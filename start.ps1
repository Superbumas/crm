# PowerShell script to run LT CRM locally with Docker

Write-Host "Starting LT CRM with Docker..." -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: Docker is not running or not installed. Please install Docker Desktop for Windows." -ForegroundColor Red
    exit 1
}

# Build and start the containers
Write-Host "Building and starting containers..." -ForegroundColor Yellow
docker-compose up --build -d

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Run database migrations
Write-Host "Running database migrations..." -ForegroundColor Yellow
docker-compose exec web flask db upgrade

# Setup default accounts
Write-Host "Setting up default accounts..." -ForegroundColor Yellow
docker-compose exec web flask setup-accounts

# Seed demo data (optional)
$seedDemo = Read-Host "Would you like to seed demo data? (y/n)"
if ($seedDemo -eq "y") {
    Write-Host "Seeding demo data..." -ForegroundColor Yellow
    docker-compose exec web flask seed-demo
}

# Show running containers
Write-Host "Services are now running:" -ForegroundColor Green
docker-compose ps

Write-Host "`nLT CRM is now available at: http://localhost:8000" -ForegroundColor Green
Write-Host "Use Ctrl+C to stop viewing logs." -ForegroundColor Yellow
Write-Host "To stop the application, run: docker-compose down" -ForegroundColor Yellow

# Show logs
docker-compose logs -f 