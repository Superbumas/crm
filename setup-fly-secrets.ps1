# PowerShell script for setting up Fly.io secrets
# Run this script from the project root directory

Write-Host "Setting up Fly.io secrets..." -ForegroundColor Green

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

Write-Host "Setting up secrets for app: $appName" -ForegroundColor Yellow

# Generate a secure random secret key
$secretKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
Write-Host "Generated random SECRET_KEY" -ForegroundColor Green

# Prompt for PostgreSQL password
$pgPassword = Read-Host -Prompt "Enter PostgreSQL password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPassword)
$postgresPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Prompt for Sentry DSN (optional)
$sentryDsn = Read-Host -Prompt "Enter Sentry DSN (optional, press Enter to skip)"

# Set secrets
Write-Host "Setting secrets in Fly.io..." -ForegroundColor Yellow

$secretsCommand = "$flyPath secrets set " + 
                 "SECRET_KEY=`"$secretKey`" " +
                 "POSTGRES_PASSWORD=`"$postgresPassword`" " +
                 "DATABASE_URL=`"postgresql://postgres:$postgresPassword@${appName}-db.internal:5432/lt_crm`" " +
                 "REDIS_URL=`"redis://${appName}-redis.internal:6379/0`" " +
                 "CELERY_BROKER_URL=`"redis://${appName}-redis.internal:6379/1`" " +
                 "CELERY_RESULT_BACKEND=`"redis://${appName}-redis.internal:6379/1`" " +
                 "--app `"$appName`""

Invoke-Expression $secretsCommand

# Set Sentry DSN if provided
if ($sentryDsn) {
    Write-Host "Setting Sentry DSN..." -ForegroundColor Yellow
    & $flyPath secrets set SENTRY_DSN="$sentryDsn" --app "$appName"
    Write-Host "Sentry DSN configured." -ForegroundColor Green
}

Write-Host "Secrets setup completed for $appName" -ForegroundColor Green
Write-Host "You can now deploy your application with: .\deploy-fly.ps1" -ForegroundColor Green 