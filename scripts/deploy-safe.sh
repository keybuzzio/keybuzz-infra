#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Unified Safe Deployment Pipeline
# Single entry point for ALL client deployments
#
# Flow:
#   1. Git clean check
#   2. Git sync check
#   3. Build from clean Git clone
#   4. Verify image
#   5. Release gate (PROD only)
#   6. Push to GHCR
#   7. Update GitOps manifest
#   8. Wait for ArgoCD sync
#   9. Runtime validation
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

# --- Arguments ---
ENV="${1:-}"
TAG="${2:-}"
BRANCH="${3:-main}"

if [ -z "$ENV" ] || [ -z "$TAG" ]; then
  echo "========================================"
  echo " PH-TD-08 Safe Deploy Pipeline"
  echo "========================================"
  echo ""
  echo "Usage: $0 <dev|prod> <tag> [branch]"
  echo ""
  echo "Examples:"
  echo "  $0 dev v3.5.61-feature-name-dev main"
  echo "  $0 prod v3.5.61-feature-name-prod main"
  echo ""
  echo "Flow:"
  echo "  1. Clone fresh from Git"
  echo "  2. Build Docker image"
  echo "  3. Verify image content"
  echo "  4. Release gate (PROD)"
  echo "  5. Push to GHCR"
  echo "  6. Update GitOps manifest"
  echo "  7. Wait ArgoCD sync"
  exit 1
fi

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: Environment must be 'dev' or 'prod'"
  exit 1
fi

IMAGE="ghcr.io/keybuzzio/keybuzz-client:${TAG}"
NAMESPACE="keybuzz-client-${ENV}"
DEPLOY_YAML="$INFRA_DIR/k8s/$NAMESPACE/deployment.yaml"

echo "========================================"
echo " PH-TD-08 Safe Deploy Pipeline"
echo "========================================"
echo "Environment: $ENV"
echo "Tag: $TAG"
echo "Branch: $BRANCH"
echo "Image: $IMAGE"
echo "Manifest: $DEPLOY_YAML"
echo "========================================"
echo ""

# ============================================================
# STEP 1: Build from clean Git clone
# ============================================================
echo "=== STEP 1/7: Build from clean Git clone ==="
"$SCRIPT_DIR/build-from-git.sh" "$ENV" "$TAG" "$BRANCH"
STEP1=$?
if [ $STEP1 -ne 0 ]; then
  echo "PIPELINE ARRETE : build echoue"
  exit 1
fi
echo ""

# ============================================================
# STEP 2: Verify image content
# ============================================================
echo "=== STEP 2/7: Verify image content ==="
"$SCRIPT_DIR/verify-image-clean.sh" "$IMAGE" "$ENV"
STEP2=$?
if [ $STEP2 -ne 0 ]; then
  echo "PIPELINE ARRETE : verification echouee"
  echo "Image $IMAGE est invalide — ne pas pusher"
  exit 1
fi
echo ""

# ============================================================
# STEP 3: Release gate (PROD only)
# ============================================================
if [ "$ENV" = "prod" ]; then
  echo "=== STEP 3/7: Release gate PROD ==="
  "$SCRIPT_DIR/frontend-release-gate.sh" "$IMAGE"
  STEP3=$?
  if [ $STEP3 -ne 0 ]; then
    echo "PIPELINE ARRETE : release gate refuse la promotion PROD"
    exit 1
  fi
  echo ""
else
  echo "=== STEP 3/7: Release gate (skip — DEV) ==="
  echo ""
fi

# ============================================================
# STEP 4: Push to GHCR
# ============================================================
echo "=== STEP 4/7: Push to GHCR ==="
docker push "$IMAGE"
STEP4=$?
if [ $STEP4 -ne 0 ]; then
  echo "PIPELINE ARRETE : push echoue"
  exit 1
fi
echo "PASS: Image pushee"
echo ""

# ============================================================
# STEP 5: Update GitOps manifest
# ============================================================
echo "=== STEP 5/7: Update GitOps manifest ==="

if [ ! -f "$DEPLOY_YAML" ]; then
  echo "ERREUR : manifest $DEPLOY_YAML introuvable"
  exit 1
fi

cd "$INFRA_DIR"

CURRENT_IMAGE=$(grep -oP 'image:\s*\K\S+' "$DEPLOY_YAML" | head -1)
echo "Image actuelle : $CURRENT_IMAGE"
echo "Nouvelle image : $IMAGE"

sed -i "s|image:.*ghcr.io/keybuzzio/keybuzz-client:.*|image: $IMAGE|" "$DEPLOY_YAML"

git add "$DEPLOY_YAML"
git commit -m "deploy($ENV): $TAG"
git push origin main

echo "PASS: Manifest mis a jour et pushe"
echo ""

# ============================================================
# STEP 6: Wait for ArgoCD sync
# ============================================================
echo "=== STEP 6/7: Wait for ArgoCD sync ==="

APP_NAME="keybuzz-client-${ENV}"
MAX_WAIT=120
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  SYNC=$(kubectl get application "$APP_NAME" -n argocd \
    -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "UNKNOWN")
  HEALTH=$(kubectl get application "$APP_NAME" -n argocd \
    -o jsonpath='{.status.health.status}' 2>/dev/null || echo "UNKNOWN")

  echo "  [$ELAPSED s] Sync=$SYNC Health=$HEALTH"

  if [ "$SYNC" = "Synced" ] && [ "$HEALTH" = "Healthy" ]; then
    echo "PASS: ArgoCD synchronise et sain"
    break
  fi

  if [ "$SYNC" = "OutOfSync" ] && [ $ELAPSED -gt 30 ]; then
    echo "ALERTE : ArgoCD toujours OutOfSync apres 30s"
    echo "Verifier : kubectl get application $APP_NAME -n argocd -o yaml"
  fi

  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo "TIMEOUT : ArgoCD n'a pas sync en ${MAX_WAIT}s"
  echo "Verifier manuellement"
fi
echo ""

# ============================================================
# STEP 7: Runtime validation
# ============================================================
echo "=== STEP 7/7: Runtime validation ==="

CLUSTER_IMAGE=$(kubectl get deploy keybuzz-client -n "$NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "UNKNOWN")

echo "Image en cluster : $CLUSTER_IMAGE"
echo "Image attendue   : $IMAGE"

if [ "$CLUSTER_IMAGE" = "$IMAGE" ]; then
  echo "PASS: Image correcte en cluster"
else
  echo "FAIL: Mismatch image cluster vs attendue"
fi

POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -l app=keybuzz-client \
  -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "UNKNOWN")

echo "Pod status: $POD_STATUS"

if [ "$POD_STATUS" = "Running" ]; then
  echo "PASS: Pod en cours d'execution"
else
  echo "ALERTE: Pod status = $POD_STATUS"
fi

# ============================================================
# FINAL
# ============================================================
echo ""
echo "========================================"
echo " DEPLOIEMENT TERMINE"
echo "========================================"
echo "Environment: $ENV"
echo "Image: $IMAGE"
echo "Branch: $BRANCH"
echo "Cluster: $CLUSTER_IMAGE"
echo "ArgoCD: $SYNC"
echo "Pod: $POD_STATUS"
echo "========================================"
