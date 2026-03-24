#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <dev|prod> <tag> [branch|sha]"
  echo ""
  echo "  env       : dev or prod"
  echo "  tag       : image tag (e.g. v2.10.2-my-feature-dev)"
  echo "  branch    : git branch or SHA to build from (default: main)"
  echo ""
  echo "Example:"
  echo "  $0 dev v2.10.2-my-feature-dev main"
  echo "  $0 prod v2.10.2-my-feature-prod main"
  exit 1
}

if [ $# -lt 2 ]; then usage; fi

ENV="$1"
TAG="$2"
BRANCH="${3:-main}"
REG="ghcr.io/keybuzzio/keybuzz-admin"
REPO_URL="https://github.com/keybuzzio/keybuzz-admin-v2.git"
TMPDIR="/tmp/build-admin-$$"

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: env must be 'dev' or 'prod'"
  exit 1
fi

if [[ "$ENV" == "dev" ]]; then
  BUILD_API_URL="https://api-dev.keybuzz.io"
  BUILD_APP_ENV="development"
else
  BUILD_API_URL="https://api.keybuzz.io"
  BUILD_APP_ENV="production"
fi

echo "============================================="
echo "  BUILD ADMIN FROM GIT (clean)"
echo "============================================="
echo "  Env     : $ENV"
echo "  Tag     : $TAG"
echo "  Branch  : $BRANCH"
echo "  Image   : $REG:$TAG"
echo "  API URL : $BUILD_API_URL"
echo "  App Env : $BUILD_APP_ENV"
echo "============================================="

echo ""
echo "[1/6] Cleaning temp dir..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

echo "[2/6] Cloning from GitHub..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMPDIR/repo" 2>&1
cd "$TMPDIR/repo"

if [[ "$BRANCH" =~ ^[0-9a-f]{7,40}$ ]]; then
  git fetch --depth 1 origin "$BRANCH"
  git checkout "$BRANCH"
fi

echo ""
echo "[3/6] Verifying clean state..."
STATUS=$(git status --porcelain)
if [ -n "$STATUS" ]; then
  echo "ABORT BUILD — DIRTY REPO"
  echo "$STATUS"
  rm -rf "$TMPDIR"
  exit 1
fi

echo "Working tree CLEAN"
echo "Commit: $(git rev-parse HEAD)"
echo ""

echo "[4/6] Building Docker image..."
docker build \
  --no-cache \
  --build-arg NEXT_PUBLIC_API_URL="$BUILD_API_URL" \
  --build-arg NEXT_PUBLIC_APP_ENV="$BUILD_APP_ENV" \
  -t "$REG:$TAG" \
  .

echo ""
echo "[5/6] Pushing image..."
docker push "$REG:$TAG"

echo ""
echo "[6/6] Cleanup..."
rm -rf "$TMPDIR"

echo ""
echo "============================================="
echo "  BUILD COMPLETE"
echo "============================================="
echo "  Image  : $REG:$TAG"
echo "  Digest : $(docker inspect --format='{{index .RepoDigests 0}}' "$REG:$TAG" 2>/dev/null || echo 'check registry')"
echo "  Commit : recorded above"
echo "============================================="
