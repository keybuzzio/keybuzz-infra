#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Build From Clean Git Clone
# Clones keybuzz-client fresh from GitHub, builds from there
# ZERO risk of bastion contamination
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Arguments ---
ENV="${1:-}"
TAG="${2:-}"
BRANCH="${3:-main}"

if [ -z "$ENV" ] || [ -z "$TAG" ]; then
  echo "Usage: $0 <dev|prod> <tag> [branch]"
  echo "Example: $0 dev v3.5.61-feature-name-dev main"
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

IMAGE="ghcr.io/keybuzzio/keybuzz-client:${TAG}"
BUILD_DIR="/tmp/keybuzz-client-build-$$"

echo "=== PH-TD-08 Build From Clean Git Clone ==="
echo "Environment: $ENV"
echo "Tag: $TAG"
echo "Branch: $BRANCH"
echo "Build dir: $BUILD_DIR"
echo ""

# ============================================================
# STEP 1: Fresh clone
# ============================================================
echo "--- Step 1: Cloning keybuzz-client ($BRANCH) ---"

rm -rf "$BUILD_DIR"
git clone --depth 1 --branch "$BRANCH" \
  https://github.com/keybuzzio/keybuzz-client.git "$BUILD_DIR" 2>&1

cd "$BUILD_DIR"
GIT_SHA=$(git rev-parse --short HEAD)
echo "PASS: Cloned at $GIT_SHA"

# ============================================================
# STEP 2: Verify clean state
# ============================================================
echo ""
echo "--- Step 2: Clean state verification ---"
DIRTY=$(git status --porcelain)
if [ -n "$DIRTY" ]; then
  echo "FATAL: Fresh clone is dirty (should never happen)"
  rm -rf "$BUILD_DIR"
  exit 1
fi
echo "PASS: Clone is clean"

# ============================================================
# STEP 3: Build
# ============================================================
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$ENV" = "dev" ]; then
  API_URL="https://api-dev.keybuzz.io"
  APP_ENV=""
else
  API_URL="https://api.keybuzz.io"
  APP_ENV="production"
fi

echo ""
echo "--- Step 3: Docker build ---"
echo "Image: $IMAGE"
echo "API URL: $API_URL"
echo ""

BUILD_CMD="docker build --no-cache"
BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_API_URL=$API_URL"
BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_API_BASE_URL=$API_URL"
BUILD_CMD="$BUILD_CMD --build-arg GIT_COMMIT_SHA=$GIT_SHA"
BUILD_CMD="$BUILD_CMD --build-arg BUILD_TIME=$BUILD_TIME"

if [ -n "$APP_ENV" ]; then
  BUILD_CMD="$BUILD_CMD --build-arg NEXT_PUBLIC_APP_ENV=$APP_ENV"
fi

BUILD_CMD="$BUILD_CMD -t $IMAGE ."

eval $BUILD_CMD
BUILD_EXIT=$?

if [ $BUILD_EXIT -ne 0 ]; then
  echo "BUILD ECHOUE (exit code $BUILD_EXIT)"
  rm -rf "$BUILD_DIR"
  exit $BUILD_EXIT
fi

# ============================================================
# STEP 4: Cleanup
# ============================================================
echo ""
echo "--- Step 4: Cleanup ---"
rm -rf "$BUILD_DIR"
echo "PASS: Build directory removed"

echo ""
echo "=== BUILD FROM GIT OK ==="
echo "Image: $IMAGE"
echo "Git SHA: $GIT_SHA"
echo "Source: github.com/keybuzzio/keybuzz-client@$BRANCH"
echo ""
echo "Prochaine etape :"
echo "  $SCRIPT_DIR/verify-image-clean.sh $IMAGE $ENV"
