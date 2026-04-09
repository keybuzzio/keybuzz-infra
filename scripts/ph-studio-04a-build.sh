#!/usr/bin/env bash
set -euo pipefail

# PH-STUDIO-04A — Build auth-enabled images
TAG="v0.2.0-dev"
REGISTRY="ghcr.io/keybuzzio"
REPO_DIR="/opt/keybuzz/keybuzz-studio"
REPO_API_DIR="/opt/keybuzz/keybuzz-studio-api"

echo "=== PH-STUDIO-04A BUILD ==="

# Pull latest code
echo "--- Pulling keybuzz-studio ---"
cd "$REPO_DIR"
git pull origin main 2>/dev/null || git pull 2>/dev/null || echo "WARN: git pull failed, using current state"

echo "--- Pulling keybuzz-studio-api ---"
cd "$REPO_API_DIR"
git pull origin main 2>/dev/null || git pull 2>/dev/null || echo "WARN: git pull failed, using current state"

# Build API
echo "--- Building keybuzz-studio-api:${TAG} ---"
cd "$REPO_API_DIR"
docker build -t "${REGISTRY}/keybuzz-studio-api:${TAG}" .
echo "API image built."

# Build Frontend
echo "--- Building keybuzz-studio:${TAG} ---"
cd "$REPO_DIR"
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  -t "${REGISTRY}/keybuzz-studio:${TAG}" .
echo "Frontend image built."

# Push
echo "--- Pushing images ---"
docker push "${REGISTRY}/keybuzz-studio-api:${TAG}"
docker push "${REGISTRY}/keybuzz-studio:${TAG}"

echo "=== BUILD COMPLETE ==="
docker images | grep keybuzz-studio | grep "${TAG}"
