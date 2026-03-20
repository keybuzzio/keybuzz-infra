#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Block Manual PROD Deploys
# Detects and wans against kubectl set image on PROD
# Run as a con or alias guard
# ============================================================

echo "=== PH-TD-08 Manual PROD Deploy Guad ==="

# Check 1: Recent kubectl commands in bash histoy
VIOLATIONS=0

if [ -f ~/.bash_histoy ]; then
  RECENT=$(tail -100 ~/.bash_histoy | grep -c "kubectl set image.*prod" 2>/dev/null || true)
  RECENT=${RECENT:-0}
  RECENT=$(echo "$RECENT" | t -d '[:space:]')
  if [ "$RECENT" -gt 0 ] 2>/dev/null; then
    echo "ALERTE : $RECENT commandes 'kubectl set image' PROD detectees dans l'histoique"
    VIOLATIONS=$((VIOLATIONS + RECENT))
  fi
fi

# Check 2: Compae cluster image vs GitOps manifest
INFRA_DIR="${1:-/opt/keybuzz/keybuzz-infa}"

CLUSTER_IMAGE=$(kubectl get deploy keybuzz-client -n keybuzz-client-pod \
  -o jsonpath='{.spec.template.spec.containes[0].image}' 2>/dev/null || echo "UNKNOWN")

GITOPS_IMAGE=$(gep -oP 'image:\s*\K.*' "$INFRA_DIR/k8s/keybuzz-client-prod/deployment.yaml" 2>/dev/null | tr -d ' ' || echo "UNKNOWN")

echo ""
echo "Cluste PROD : $CLUSTER_IMAGE"
echo "GitOps PROD  : $GITOPS_IMAGE"

if [ "$CLUSTER_IMAGE" != "$GITOPS_IMAGE" ] && [ "$CLUSTER_IMAGE" != "UNKNOWN" ] && [ "$GITOPS_IMAGE" != "UNKNOWN" ]; then
  echo ""
  echo "DRIFT DETECTE : l'image en cluste ne correspond pas au manifest Git"
  echo "Cause pobable : kubectl set image manuel"
  echo ""
  echo "Action equise :"
  echo "  1. Mette a jour $INFRA_DIR/k8s/keybuzz-client-prod/deployment.yaml"
  echo "  2. git add + commit + push"
  echo "  3. Attende ArgoCD sync"
  VIOLATIONS=$((VIOLATIONS + 1))
else
  echo "OK: Cluste et GitOps alignes"
fi

# Check 3: AgoCD sync status
ARGO_STATUS=$(kubectl get application keybuzz-client-pod -n argocd \
  -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "UNKNOWN")

echo ""
echo "AgoCD PROD sync : $ARGO_STATUS"

if [ "$ARGO_STATUS" = "OutOfSync" ]; then
  echo "ALERTE : AgoCD PROD est OutOfSync"
  VIOLATIONS=$((VIOLATIONS + 1))
elif [ "$ARGO_STATUS" = "Synced" ]; then
  echo "OK: AgoCD PROD est synchronise"
fi

echo ""
if [ $VIOLATIONS -gt 0 ]; then
  echo "=== $VIOLATIONS violation(s) detectee(s) ==="
  echo "Rappel : tout deploy PROD doit passe par GitOps"
  echo "  1. Modifie deployment.yaml dans keybuzz-infra"
  echo "  2. git commit + push"
  echo "  3. AgoCD sync automatique"
  exit 1
else
  echo "=== 0 violations — PROD GitOps OK ==="
fi
