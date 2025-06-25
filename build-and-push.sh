#!/bin/bash
set -e

# Configuration
REGISTRY="ghcr.io"
REPO_OWNER="superbumas"  # Your GitHub username
REPO_NAME="crm"
IMAGE_TAG=${1:-latest}  # Use first argument as tag, default to 'latest'

# Image names
WEB_IMAGE="$REGISTRY/$REPO_OWNER/$REPO_NAME/web:$IMAGE_TAG"
WORKER_IMAGE="$REGISTRY/$REPO_OWNER/$REPO_NAME/worker:$IMAGE_TAG"

echo "🚀 Building and pushing LT CRM Docker images..."
echo "📦 Web image: $WEB_IMAGE"
echo "📦 Worker image: $WORKER_IMAGE"
echo ""

# Build images
echo "🔨 Building web image..."
docker build -t "$WEB_IMAGE" -f lt_crm/infra/Dockerfile .

echo "🔨 Building worker image (same as web for now)..."
docker tag "$WEB_IMAGE" "$WORKER_IMAGE"

# Push images
echo "📤 Pushing web image..."
docker push "$WEB_IMAGE"

echo "📤 Pushing worker image..."
docker push "$WORKER_IMAGE"

echo "✅ Successfully built and pushed images!"
echo ""
echo "🔄 To deploy on server, run:"
echo "ssh andrius@20.166.16.9 'cd /home/andrius/crm && docker-compose pull && docker-compose up -d'" 