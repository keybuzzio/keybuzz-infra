#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# GitOps Drift Check — KeyBuzz v3
# PH136-A: Compare cluster state vs Git manifests
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INFRA_ROOT="/opt/keybuzz/keybuzz-infra"
DRIFT_COUNT=0

check() {
  local label="$1"
  local ns="$2"
  local deploy="$3"
  local manifest="$4"

  local cluster_img
  cluster_img=$(kubectl get deployment "$deploy" -n "$ns" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "NOT_DEPLOYED")

  local git_img="MANIFEST_NOT_FOUND"
  if [ -f "$manifest" ]; then
    git_img=$(grep -m1 'image: ghcr.io' "$manifest" | sed 's/.*image: //' | xargs)
  fi

  if [ "$cluster_img" = "$git_img" ]; then
    printf "  %-25s ${GREEN}OK${NC}\n" "$label"
  else
    printf "  %-25s ${RED}DRIFT${NC}\n" "$label"
    echo "    Cluster: $cluster_img"
    echo "    Git:     $git_img"
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi
}

echo "═══════════════════════════════════════════════════"
echo "  GitOps Drift Report"
echo "  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "═══════════════════════════════════════════════════"
echo ""

check "API DEV"         keybuzz-api-dev     keybuzz-api              "${INFRA_ROOT}/k8s/keybuzz-api-dev/deployment.yaml"
check "API PROD"        keybuzz-api-prod    keybuzz-api              "${INFRA_ROOT}/k8s/keybuzz-api-prod/deployment.yaml"
check "Worker DEV"      keybuzz-api-dev     keybuzz-outbound-worker  "${INFRA_ROOT}/k8s/keybuzz-api-dev/outbound-worker-deployment.yaml"
check "Worker PROD"     keybuzz-api-prod    keybuzz-outbound-worker  "${INFRA_ROOT}/k8s/keybuzz-api-prod/outbound-worker-deployment.yaml"
check "Client DEV"      keybuzz-client-dev  keybuzz-client           "${INFRA_ROOT}/k8s/keybuzz-client-dev/deployment.yaml"
check "Client PROD"     keybuzz-client-prod keybuzz-client           "${INFRA_ROOT}/k8s/keybuzz-client-prod/deployment.yaml"
check "Backend DEV"     keybuzz-backend-dev keybuzz-backend          "${INFRA_ROOT}/k8s/keybuzz-backend-dev/deployment.yaml"
check "Backend PROD"    keybuzz-backend-prod keybuzz-backend         "${INFRA_ROOT}/k8s/keybuzz-backend-prod/deployment.yaml"

echo ""
if [ "$DRIFT_COUNT" -eq 0 ]; then
  echo -e "${GREEN}No drift detected. Git = Cluster.${NC}"
else
  echo -e "${RED}$DRIFT_COUNT drift(s) detected! Fix manifests or cluster.${NC}"
fi
