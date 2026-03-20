#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Safe Client Build Script
# HARD BLOCKS builds from dirty workspace
# Replaces the old build-client.sh (WARNING-only guardrail)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Arguments ---
ENV="${1:-}"
TAG="${2:-}"
CLIENT_DIR="${3:-/opt/keybuzz/keybuzz-client}"

if [ -z "$ENV" ] || [ -z "$TAG" ]; then
  echo "Usage: $0 <dev|prod> <tag> [client-dir]"
  echo "Example: $0 dev v3.5.61-feature-name-dev"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: Environment must be 'dev' or 'prod'"
  exit 1
fi

IMAGE="ghcr.io/keybuzzio/keybuzz-client:${TAG}"

echo "=== PH-TD-08 Safe Client Build ==="
echo "Environment: $ENV"
echo "Tag: $TAG"
echo "Source: $CLIENT_DIR"
echo ""

# ============================================================
# GUARDRAIL 1: HARD BLOCK — workspace MUST be clean
# ============================================================
echo "--- GUARDRAIL 1: Workspace clean check ---"
cd "$CLIENT_DIR"

DIRTY=$(git status --porcelain 2>/dev/null || echo "NOT_GIT")
if [ "$DIRTY" = "NOT_GIT" ]; then
  echo "FATAL: $CLIENT_DIR is not a git repository"
  exit 1
fi

if [ -n "$DIRTY" ]; then
  echo "BUILD BLOQUE : workspace non propre"
  echo ""
  echo "Fichiers non commites :"
  echo "$DIRTY"
  echo ""
  echo "Action requise :"
  echo "  1. git add -A"
  echo "  2. git commit -m 'description'"
  echo "  3. git push origin \$(git rev-parse --abbrev-ref HEAD)"
  echo "  4. Relancer ce script"
  exit 1
fi
echo "PASS: Workspace propre"

# ============================================================
# GUARDRAIL 2: HARD BLOCK — HEAD must match GitHub
# ============================================================
echo ""
echo "--- GUARDRAIL 2: Git sync check ---"
git fetch origin --quiet 2>/dev/null

LOCAL=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "NOT_FOUND")

if [ "$REMOTE" = "NOT_FOUND" ]; then
  echo "BUILD BLOQUE : branche '$BRANCH' non trouvee sur origin"
  echo "Action requise : git push -u origin $BRANCH"
  exit 1
fi

if [ "$LOCAL" != "$REMOTE" ]; then
  echo "BUILD BLOQUE : HEAD local different de GitHub"
  echo "  LOCAL:  $LOCAL"
  echo "  REMOTE: $REMOTE"
  echo ""
  echo "Action requise : git push origin $BRANCH"
  exit 1
fi
echo "PASS: Synchronise avec GitHub ($LOCAL)"

# ============================================================
# GUARDRAIL 3: Tag suffix must match environment
# ============================================================
echo ""
echo "--- GUARDRAIL 3: Tag validation ---"

if [ "$ENV" = "dev" ] && [[ "$TAG" != *"-dev" ]]; then
  echo "BUILD BLOQUE : tag DEV doit finir par '-dev'"
  echo "Tag fourni : $TAG"
  exit 1
fi

if [ "$ENV" = "prod" ] && [[ "$TAG" != *"-prod" ]]; then
  echo "BUILD BLOQUE : tag PROD doit finir par '-prod'"
  echo "Tag fourni : $TAG"
  exit 1
fi
echo "PASS: Tag suffix correct"

# ============================================================
# GUARDRAIL 4: Required files
# ============================================================
echo ""
echo "--- GUARDRAIL 4: Required files ---"
REQUIRED=(
  "src/components/layout/ClientLayout.tsx"
  "src/lib/i18n/I18nProvider.tsx"
  "app/layout.tsx"
  "package.json"
  "Dockerfile"
  "next.config.mjs"
  "tsconfig.json"
)
MISSING=0
for f in "${REQUIRED[@]}"; do
  if [ ! -f "$f" ]; then
    echo "  MISSING: $f"
    MISSING=$((MISSING + 1))
  fi
done
if [ $MISSING -gt 0 ]; then
  echo "BUILD BLOQUE : $MISSING fichiers requis manquants"
  exit 1
fi
echo "PASS: Tous les fichiers requis presents"

# ============================================================
# BUILD
# ============================================================
GIT_SHA=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ "$ENV" = "dev" ]; then
  API_URL="https://api-dev.keybuzz.io"
  APP_ENV=""
else
  API_URL="https://api.keybuzz.io"
  APP_ENV="production"
fi

echo ""
echo "=== BUILD ==="
echo "Image: $IMAGE"
echo "Git SHA: $GIT_SHA"
echo "Build time: $BUILD_TIME"
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
  exit $BUILD_EXIT
fi

echo ""
echo "=== BUILD OK ==="
echo "Image: $IMAGE"
echo "SHA: $GIT_SHA"
echo ""
echo "Prochaine etape :"
echo "  $SCRIPT_DIR/verify-image-clean.sh $IMAGE $ENV"
