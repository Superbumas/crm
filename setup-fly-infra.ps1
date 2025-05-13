# PowerShell script for setting up Fly.io infrastructure (PostgreSQL and Redis)
# Run this script from the project root directory

Write-Host "Setting up Fly.io infrastructure..." -ForegroundColor Green

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

$appName = "lt-crm"
$region = "ams"  # Amsterdam region, change if needed

# Prompt for PostgreSQL password
$pgPassword = Read-Host -Prompt "Enter PostgreSQL password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPassword)
$postgresPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Setup PostgreSQL
Write-Host "Setting up PostgreSQL on Fly.io..." -ForegroundColor Yellow
try {
    # Check if PostgreSQL app already exists
    & $flyPath apps list | Select-String -Pattern "${appName}-db" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating PostgreSQL app..." -ForegroundColor Yellow
        & $flyPath postgres create --name "${appName}-db" --region $region --password $postgresPassword
        
        # Attach PostgreSQL to main app
        Write-Host "Attaching PostgreSQL to main app..." -ForegroundColor Yellow
        & $flyPath postgres attach --postgres-app "${appName}-db" --app $appName
    } else {
        Write-Host "PostgreSQL app already exists." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error setting up PostgreSQL: $_" -ForegroundColor Red
}

# Setup Redis
Write-Host "Setting up Redis on Fly.io..." -ForegroundColor Yellow
try {
    # Check if Redis app already exists
    & $flyPath apps list | Select-String -Pattern "${appName}-redis" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        # Create a temporary directory for Redis configuration
        $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_.FullName }
        
        # Create Redis fly.toml in the temporary directory
        @"
app = "${appName}-redis"
primary_region = "$region"

[build]
  image = "flyio/redis:6.2.6"

[env]
  REDIS_ARGS = "--requirepass ${postgresPassword}"

[metrics]
  port = 9091
  path = "/metrics"

[[vm]]
  memory = "1gb"
  cpu_kind = "shared"
  cpus = 1
"@ | Out-File -FilePath "$tempDir\fly.toml"
        
        # Create Redis app
        Write-Host "Creating Redis app..." -ForegroundColor Yellow
        Set-Location $tempDir
        & $flyPath launch --no-deploy --copy-config
        & $flyPath deploy
        
        # Return to original directory
        Set-Location -Path $PSScriptRoot
        
        # Clean up temp directory
        Remove-Item -Recurse -Force $tempDir
    } else {
        Write-Host "Redis app already exists." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error setting up Redis: $_" -ForegroundColor Red
}

# Create volume for persistent storage
Write-Host "Creating volume for persistent storage..." -ForegroundColor Yellow
try {
    & $flyPath volumes list --app $appName | Select-String -Pattern "lt_crm_data" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & $flyPath volumes create lt_crm_data --region $region --size 1 --app $appName
    } else {
        Write-Host "Volume already exists." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error creating volume: $_" -ForegroundColor Red
}

Write-Host "Infrastructure setup completed." -ForegroundColor Green
Write-Host "Now run .\setup-fly-secrets.ps1 to set up your secrets, then .\deploy-fly.ps1 to deploy your application." -ForegroundColor Green 