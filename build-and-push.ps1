# PowerShell script to build and push LT CRM Docker images
param(
    [string]$ImageTag = "latest"
)

# Configuration
$REGISTRY = "ghcr.io"
$REPO_OWNER = "superbumas"  # Your GitHub username
$REPO_NAME = "crm"

# Image names
$WEB_IMAGE = "$REGISTRY/$REPO_OWNER/$REPO_NAME/web:$ImageTag"
$WORKER_IMAGE = "$REGISTRY/$REPO_OWNER/$REPO_NAME/worker:$ImageTag"

Write-Host "🚀 Building and pushing LT CRM Docker images..." -ForegroundColor Green
Write-Host "📦 Web image: $WEB_IMAGE" -ForegroundColor Yellow
Write-Host "📦 Worker image: $WORKER_IMAGE" -ForegroundColor Yellow
Write-Host ""

try {
    # Build images
    Write-Host "🔨 Building web image..." -ForegroundColor Blue
    docker build -t $WEB_IMAGE -f lt_crm/infra/Dockerfile .
    if ($LASTEXITCODE -ne 0) { throw "Failed to build web image" }

    Write-Host "🔨 Building worker image (same as web for now)..." -ForegroundColor Blue
    docker tag $WEB_IMAGE $WORKER_IMAGE
    if ($LASTEXITCODE -ne 0) { throw "Failed to tag worker image" }

    # Push images
    Write-Host "📤 Pushing web image..." -ForegroundColor Magenta
    docker push $WEB_IMAGE
    if ($LASTEXITCODE -ne 0) { throw "Failed to push web image" }

    Write-Host "📤 Pushing worker image..." -ForegroundColor Magenta
    docker push $WORKER_IMAGE
    if ($LASTEXITCODE -ne 0) { throw "Failed to push worker image" }

    Write-Host "✅ Successfully built and pushed images!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔄 To deploy on server, run:" -ForegroundColor Cyan
    Write-Host "ssh andrius@20.166.16.9 'cd /home/andrius/crm && docker-compose pull && docker-compose up -d'" -ForegroundColor White
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
} 