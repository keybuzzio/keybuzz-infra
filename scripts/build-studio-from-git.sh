#!/bin/bash
set -euo pipefail

# ============================================================
# PH-STUDIO-02 — Build Studio Frontend From Clean Git Clone
# Clones keybuzz-client, builds keybuzz-studio/ subfolder
# ZERO risk of bastion contamination
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV="${1:-}"
TAG="${2:-}"
BRANCH="${3:-main}"

if [ -z "$ENV" ] || [ -z "$TAG" ]; then
  echo "Usage: $0 <dev|prod> <tag> [branch]"
  echo "Example: $0 dev v0.1.0-dev main"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: Environment must be 'dev' or 'prod'"
  exit 1
fi

if [ "$ENV" = "dev" ] && [[ "$TAG" != *"-dev" ]]; then
  echo "BLOQUE : tag DEV doit finir par '-dev'"
  exit 1
fi

if [ "$ENV" = "prod" ] && [[ "$TAG" != *"-prod" ]]; then
  echo "BLOQUE : tag PROD doit finir par '-prod'"
  exit 1
fi

IMAGE="ghcr.io/keybuzzio/keybuzz-studio:${TAG}"
BUILD_DIR="/tmp/keybuzz-studio-build-$$"

echo "=== PH-STUDIO-02 Build Studio Frontend From Git ==="
echo "Environment: $ENV"
echo "Tag: $TAG"
echo "Branch: $BRANCH"
echo "Build dir: $BUILD_DIR"
echo ""

echo "--- Step 1: Cloning keybuzz-client ($BRANCH) ---"
rm -rf "$BUILD_DIR"
git clone --depth 1 --branch "$BRANCH" \
  https://github.com/keybuzzio/keybuzz-client.git "$BUILD_DIR" 2>&1

cd "$BUILD_DIR/keybuzz-studio"
GIT_SHA=$(cd "$BUILD_DIR" && git rev-parse --short HEAD)
echo "PASS: Cloned at $GIT_SHA"

echo ""
echo "--- Step 2: Clean state verification ---"
DIRTY=$(cd "$BUILD_DIR" && git status --porcelain)
if [ -n "$DIRTY" ]; then
  echo "FATAL: Fresh clone is dirty"
  rm -rf "$BUILD_DIR"
  exit 1
fi
echo "PASS: Clone is clean"

BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$ENV" = "dev" ]; then
  STUDIO_API_URL="https://studio-api-dev.keybuzz.io"
  APP_ENV="development"
else
  STUDIO_API_URL="https://studio-api.keybuzz.io"
  APP_ENV="production"
fi

echo ""
echo "--- Step 3: Docker build ---"
echo "Image: $IMAGE"
echo "Studio API URL: $STUDIO_API_URL"
echo ""

docker build --no-cache \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL="$STUDIO_API_URL" \
  --build-arg NEXT_PUBLIC_APP_ENV="$APP_ENV" \
  --build-arg GIT_COMMIT_SHA="$GIT_SHA" \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t "$IMAGE" .

echo ""
echo "--- Step 4: Cleanup ---"
rm -rf "$BUILD_DIR"
echo "PASS: Build directory removed"

echo ""
echo "=== STUDIO FRONTEND BUILD OK ==="
echo "Image: $IMAGE"
echo "Git SHA: $GIT_SHA"
echo "Source: github.com/keybuzzio/keybuzz-client@$BRANCH (keybuzz-studio/)"
echo ""
echo "Next: docker push $IMAGE"
