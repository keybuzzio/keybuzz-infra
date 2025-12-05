#!/bin/bash
# PH9-05 - Create Application Namespaces
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-05-create-namespaces.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-05 - Create Application Namespaces"
echo "[INFO] =========================================="
echo ""

NAMESPACES=("keybuzz-system" "keybuzz-apps" "erp-system" "observability")

for ns in "${NAMESPACES[@]}"; do
    echo "[INFO] Creating namespace: ${ns}..."
    kubectl create namespace ${ns} --dry-run=client -o yaml | kubectl apply -f -
    echo "[INFO]   ✅ Namespace ${ns} created"
done

echo ""
echo "[INFO] Listing all namespaces..."
kubectl get namespaces

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-05 Namespaces Creation Complete"
echo "[INFO] =========================================="
echo ""

