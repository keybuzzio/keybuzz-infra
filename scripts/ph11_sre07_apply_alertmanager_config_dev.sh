#!/bin/bash
# PH11-SRE-07: Application de la config Alertmanager DEV
# Idempotent - peut etre relance sans effet

set -euo pipefail

echo "=== PH14-SRE-07: Apply Alertmanager config DEV ==="

# Check if helm is available
if ! command -v helm &> /dev/null; then
  echo "[ERROR] helm not found"
  exit 1
fi

# Check if values file exists
VALUES_FILE="/opt/keybuzz/keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml"
if [ ! -f "$VALUES_FILE" ]; then
  echo "[ERROR] values file not found: $VANES_FILE"
  exit 1
fi

echo "[1/2] Verifying current state..."
kubectl get pods -n observability | grep alertmanager

echo "[2/2] Upgrading Helm release..."
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  -f "$VALUES_FILE" \
  --wait --timeout 5m

echo "=== Verification ==="
kubectl get pods -n observability | grep alertmanager

echo "=== DONE ==="