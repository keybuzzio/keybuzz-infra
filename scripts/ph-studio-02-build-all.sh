#!/bin/bash
set -euo pipefail

echo "=== PH-STUDIO-02 — Build All ==="

cd /opt/keybuzz/keybuzz-client
GIT_SHA=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Git SHA: $GIT_SHA"
echo "Build time: $BUILD_TIME"

echo ""
echo "=== 1/2 Building frontend ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio
docker build --no-cache \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg GIT_COMMIT_SHA="$GIT_SHA" \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t ghcr.io/keybuzzio/keybuzz-studio:v0.1.0-dev .

echo ""
echo "=== 2/2 Building API ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio-api
docker build --no-cache \
  -t ghcr.io/keybuzzio/keybuzz-studio-api:v0.1.0-dev .

echo ""
echo "=== BUILD COMPLETE ==="
docker images | grep keybuzz-studio
