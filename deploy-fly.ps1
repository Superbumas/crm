# PowerShell script for deploying to Fly.io
# Run this script from the project root directory

Write-Host "Starting Fly.io deployment process..." -ForegroundColor Green

# Check if fly.toml exists
if (-not (Test-Path -Path "fly.toml")) {
    Write-Host "Error: fly.toml not found in the current directory." -ForegroundColor Red
    exit 1
}

# Check if Dockerfile exists
if (-not (Test-Path -Path "Dockerfile")) {
    Write-Host "Error: Dockerfile not found in the current directory." -ForegroundColor Red
    exit 1
}

# Ensure Fly CLI is installed
$flyPath = "$env:USERPROFILE\.fly\bin\flyctl.exe"
if (-not (Test-Path -Path $flyPath)) {
    Write-Host "Installing Fly CLI..." -ForegroundColor Yellow
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://fly.io/install.ps1')
    $flyPath = "$env:USERPROFILE\.fly\bin\flyctl.exe"
}

# Login to Fly.io if not already logged in
try {
    Write-Host "Checking Fly.io authentication..." -ForegroundColor Yellow
    & $flyPath auth whoami 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Please log in to Fly.io:" -ForegroundColor Yellow
        & $flyPath auth login
    }
} catch {
    Write-Host "Please log in to Fly.io:" -ForegroundColor Yellow
    & $flyPath auth login
}

# Create Fly.io app if it doesn't exist
try {
    Write-Host "Checking if app exists on Fly.io..." -ForegroundColor Yellow
    & $flyPath apps list | Select-String -Pattern "lt-crm" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating new Fly.io app..." -ForegroundColor Yellow
        & $flyPath apps create lt-crm
    }
} catch {
    Write-Host "Creating new Fly.io app..." -ForegroundColor Yellow
    & $flyPath apps create lt-crm
}

# Deploy to Fly.io
Write-Host "Deploying application to Fly.io..." -ForegroundColor Green
try {
    & $flyPath deploy --remote-only
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment successful!" -ForegroundColor Green
    } else {
        Write-Host "Deployment failed. Trying with --dockerfile flag..." -ForegroundColor Yellow
        & $flyPath deploy --remote-only --dockerfile Dockerfile
    }
} catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
    exit 1
}

# Check app status
Write-Host "Checking application status..." -ForegroundColor Yellow
& $flyPath status

Write-Host "Deployment process completed." -ForegroundColor Green 