#!/bin/bash
# PH9-02 - Install ArgoCD
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-02-install-argocd.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-02 - Install ArgoCD"
echo "[INFO] =========================================="
echo ""

# Create ArgoCD namespace
echo "[INFO] Step 1: Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo "[INFO]   ✅ Namespace created"

# Install ArgoCD
echo ""
echo "[INFO] Step 2: Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ ArgoCD manifests applied"
else
    echo "[ERROR]   ❌ Failed to apply ArgoCD manifests"
    exit 1
fi

# Wait for ArgoCD pods to be ready
echo ""
echo "[INFO] Step 3: Waiting for ArgoCD pods to be ready..."
for i in {1..60}; do
    READY_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c "Running\|Completed" || echo "0")
    TOTAL_PODS=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
    echo "[INFO]   Ready pods: ${READY_PODS}/${TOTAL_PODS}"
    if [ "${READY_PODS}" -ge 5 ] && [ "${READY_PODS}" -eq "${TOTAL_PODS}" ]; then
        echo "[INFO]   ✅ All ArgoCD pods are ready"
        break
    fi
    sleep 10
done

# Display ArgoCD status
echo ""
echo "[INFO] Step 4: ArgoCD status..."
kubectl get pods -n argocd
kubectl get svc -n argocd

# Get initial admin password
echo ""
echo "[INFO] Step 5: Retrieving ArgoCD initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")
if [ -n "$ARGOCD_PASSWORD" ]; then
    echo "[INFO]   ✅ ArgoCD admin password retrieved"
    echo "[INFO]   Password saved to /root/argocd_admin_password.txt"
    echo "$ARGOCD_PASSWORD" > /root/argocd_admin_password.txt
    chmod 600 /root/argocd_admin_password.txt
else
    echo "[WARN]   ⚠️  Could not retrieve ArgoCD admin password (may need to wait longer)"
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-02 ArgoCD Installation Complete"
echo "[INFO] =========================================="
echo ""

