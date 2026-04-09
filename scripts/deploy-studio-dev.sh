#!/bin/bash
set -euo pipefail

# ============================================================
# PH-STUDIO-02 — Full Studio DEV Deployment
# Build + Push + Deploy (frontend + API)
# Run from bastion: /opt/keybuzz/keybuzz-infra/scripts/deploy-studio-dev.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="${1:-v0.1.0-dev}"
BRANCH="${2:-main}"

FRONTEND_IMAGE="ghcr.io/keybuzzio/keybuzz-studio:${TAG}"
API_IMAGE="ghcr.io/keybuzzio/keybuzz-studio-api:${TAG}"

echo "========================================"
echo "  PH-STUDIO-02 — Studio DEV Deployment"
echo "========================================"
echo "Tag: $TAG"
echo "Branch: $BRANCH"
echo "Frontend: $FRONTEND_IMAGE"
echo "API: $API_IMAGE"
echo ""

echo "=== STEP 1/6: Build Studio Frontend ==="
"$SCRIPT_DIR/build-studio-from-git.sh" dev "$TAG" "$BRANCH"

echo ""
echo "=== STEP 2/6: Build Studio API ==="
"$SCRIPT_DIR/build-studio-api-from-git.sh" dev "$TAG" "$BRANCH"

echo ""
echo "=== STEP 3/6: Push Frontend ==="
docker push "$FRONTEND_IMAGE"
echo "PASS: Frontend pushed"

echo ""
echo "=== STEP 4/6: Push API ==="
docker push "$API_IMAGE"
echo "PASS: API pushed"

echo ""
echo "=== STEP 5/6: Apply K8s manifests ==="
INFRA_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

kubectl apply -f "$INFRA_DIR/k8s/keybuzz-studio-dev/"
echo ""
kubectl apply -f "$INFRA_DIR/k8s/keybuzz-studio-api-dev/"
echo "PASS: K8s manifests applied"

echo ""
echo "=== STEP 6/6: Verify pods ==="
echo "--- Frontend pods ---"
kubectl get pods -n keybuzz-studio-dev -l app=keybuzz-studio
echo ""
echo "--- API pods ---"
kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api
echo ""

echo "Waiting 30s for pods to start..."
sleep 30

echo ""
echo "--- Final pod status ---"
kubectl get pods -n keybuzz-studio-dev
kubectl get pods -n keybuzz-studio-api-dev
echo ""

echo "--- Health check API ---"
API_POD=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  kubectl exec -n keybuzz-studio-api-dev "$API_POD" -- wget -qO- http://localhost:4010/health 2>/dev/null || echo "WARN: Health check failed (pod may still be starting)"
else
  echo "WARN: No API pod found yet"
fi

echo ""
echo "========================================"
echo "  STUDIO DEV DEPLOYMENT COMPLETE"
echo "========================================"
echo "Frontend: $FRONTEND_IMAGE"
echo "API: $API_IMAGE"
echo "Frontend URL: https://studio-dev.keybuzz.io"
echo "API URL: https://studio-api-dev.keybuzz.io"
echo ""
echo "Verify:"
echo "  kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio"
echo "  kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api"
echo "  curl https://studio-api-dev.keybuzz.io/health"
