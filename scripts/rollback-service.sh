#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# GitOps Rollback Script — KeyBuzz v3
# PH136-A: Official rollback procedure (NO kubectl set image)
#
# Usage:
#   ./rollback-service.sh <service> <env> <version>
#
# Examples:
#   ./rollback-service.sh api dev v3.5.143-inbound-body-email-fix-dev
#   ./rollback-service.sh worker prod v3.6.08-inbound-body-email-fix-prod
#   ./rollback-service.sh client prod v3.5.130-some-fix-prod
#   ./rollback-service.sh backend dev v1.0.41-some-fix-dev
#
# This script:
#   1. Updates the manifest YAML (source of truth)
#   2. Applies it to the cluster
#   3. Waits for rollout
#   4. Verifies the deployment
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INFRA_ROOT="/opt/keybuzz/keybuzz-infra"

if [ $# -ne 3 ]; then
  echo -e "${RED}Usage: $0 <service> <env> <version>${NC}"
  echo ""
  echo "Services: api, worker, client, backend"
  echo "Envs: dev, prod"
  echo ""
  echo "Example: $0 api dev v3.5.143-inbound-body-email-fix-dev"
  exit 1
fi

SERVICE="$1"
ENV="$2"
VERSION="$3"

case "$SERVICE" in
  api)
    NAMESPACE="keybuzz-api-${ENV}"
    DEPLOYMENT="keybuzz-api"
    CONTAINER="keybuzz-api"
    REGISTRY="ghcr.io/keybuzzio/keybuzz-api"
    MANIFEST="${INFRA_ROOT}/k8s/keybuzz-api-${ENV}/deployment.yaml"
    ;;
  worker)
    NAMESPACE="keybuzz-api-${ENV}"
    DEPLOYMENT="keybuzz-outbound-worker"
    CONTAINER="worker"
    REGISTRY="ghcr.io/keybuzzio/keybuzz-api"
    MANIFEST="${INFRA_ROOT}/k8s/keybuzz-api-${ENV}/outbound-worker-deployment.yaml"
    ;;
  client)
    NAMESPACE="keybuzz-client-${ENV}"
    DEPLOYMENT="keybuzz-client"
    CONTAINER="keybuzz-client"
    REGISTRY="ghcr.io/keybuzzio/keybuzz-client"
    MANIFEST="${INFRA_ROOT}/k8s/keybuzz-client-${ENV}/deployment.yaml"
    ;;
  backend)
    NAMESPACE="keybuzz-backend-${ENV}"
    DEPLOYMENT="keybuzz-backend"
    CONTAINER="keybuzz-backend"
    REGISTRY="ghcr.io/keybuzzio/keybuzz-backend"
    MANIFEST="${INFRA_ROOT}/k8s/keybuzz-backend-${ENV}/deployment.yaml"
    ;;
  *)
    echo -e "${RED}Unknown service: $SERVICE${NC}"
    echo "Valid: api, worker, client, backend"
    exit 1
    ;;
esac

FULL_IMAGE="${REGISTRY}:${VERSION}"

echo "═══════════════════════════════════════════════════"
echo -e "  ${YELLOW}GitOps Rollback${NC}"
echo "═══════════════════════════════════════════════════"
echo "  Service:    $SERVICE"
echo "  Env:        $ENV"
echo "  Version:    $VERSION"
echo "  Image:      $FULL_IMAGE"
echo "  Namespace:  $NAMESPACE"
echo "  Deployment: $DEPLOYMENT"
echo "  Manifest:   $MANIFEST"
echo "═══════════════════════════════════════════════════"

# Step 1: Verify manifest exists
if [ ! -f "$MANIFEST" ]; then
  echo -e "${RED}ERROR: Manifest not found: $MANIFEST${NC}"
  exit 1
fi

# Step 2: Show current image
CURRENT=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null || echo "NOT_FOUND")
echo ""
echo -e "Current:  ${YELLOW}${CURRENT}${NC}"
echo -e "Target:   ${GREEN}${FULL_IMAGE}${NC}"
echo ""

if [ "$CURRENT" = "$FULL_IMAGE" ]; then
  echo -e "${GREEN}Already at target version. Nothing to do.${NC}"
  exit 0
fi

# Step 3: Update manifest (sed)
echo "[1/4] Updating manifest..."
sed -i "s|image: ${REGISTRY}:[^ ]*|image: ${FULL_IMAGE}|g" "$MANIFEST"

UPDATED=$(grep "image: ${REGISTRY}" "$MANIFEST" | head -1 | xargs)
echo "  Manifest now: $UPDATED"

# Step 4: Apply manifest
echo "[2/4] Applying manifest..."
kubectl apply -f "$MANIFEST"

# Step 5: Wait for rollout
echo "[3/4] Waiting for rollout..."
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s

# Step 6: Verify
echo "[4/4] Verifying..."
DEPLOYED=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath="{.spec.template.spec.containers[0].image}")
echo "  Cluster image: $DEPLOYED"

if [ "$DEPLOYED" = "$FULL_IMAGE" ]; then
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  ROLLBACK SUCCESSFUL${NC}"
  echo -e "${GREEN}  $SERVICE ($ENV) -> $VERSION${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "${YELLOW}REMINDER: Sync this manifest to your local Git repo${NC}"
  echo "  File: $MANIFEST"
else
  echo -e "${RED}ERROR: Deployed image mismatch!${NC}"
  echo "  Expected: $FULL_IMAGE"
  echo "  Got:      $DEPLOYED"
  exit 1
fi
