#!/bin/bash
# PH9-03 - Install External Secrets Operator
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-03-install-eso.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-03 - Install External Secrets Operator"
echo "[INFO] =========================================="
echo ""

# Check if Helm is installed
echo "[INFO] Step 1: Checking Helm installation..."
if ! command -v helm &> /dev/null; then
    echo "[INFO]   Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo "[INFO]   ✅ Helm is installed"

# Add External Secrets Operator Helm repository
echo ""
echo "[INFO] Step 2: Adding External Secrets Operator Helm repository..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Create namespace
echo ""
echo "[INFO] Step 3: Creating external-secrets namespace..."
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
echo "[INFO]   ✅ Namespace created"

# Install External Secrets Operator
echo ""
echo "[INFO] Step 4: Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true \
    --wait \
    --timeout 10m

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ External Secrets Operator installed"
else
    echo "[ERROR]   ❌ Failed to install External Secrets Operator"
    exit 1
fi

# Wait for ESO pods to be ready
echo ""
echo "[INFO] Step 5: Waiting for ESO pods to be ready..."
for i in {1..30}; do
    READY_PODS=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -c "Running\|Completed" || echo "0")
    TOTAL_PODS=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | wc -l || echo "0")
    echo "[INFO]   Ready pods: ${READY_PODS}/${TOTAL_PODS}"
    if [ "${READY_PODS}" -ge 2 ] && [ "${READY_PODS}" -eq "${TOTAL_PODS}" ]; then
        echo "[INFO]   ✅ All ESO pods are ready"
        break
    fi
    sleep 10
done

# Display ESO status
echo ""
echo "[INFO] Step 6: External Secrets Operator status..."
kubectl get pods -n external-secrets
kubectl get crds | grep externalsecrets

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-03 External Secrets Operator Installation Complete"
echo "[INFO] =========================================="
echo ""

