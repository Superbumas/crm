# Docker Login Instructions

## Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "Docker Registry Access"
4. Select scopes:
   - ✅ write:packages
   - ✅ read:packages
   - ✅ delete:packages
5. Click "Generate token"
6. **COPY THE TOKEN** (you won't see it again!)

## Step 2: Login to Docker Registry

Run this command and paste your token when prompted for password:

```bash
docker login ghcr.io -u superbumas
```

When prompted for password, paste your Personal Access Token (not your GitHub password!)

## Step 3: Test the Setup

Once logged in, you can build and push your first image:

```powershell
./build-and-push.ps1
```

This will build the Docker images and push them to GitHub Container Registry. 