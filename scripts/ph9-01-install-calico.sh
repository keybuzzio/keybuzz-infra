#!/bin/bash
# PH9-01 - Install Calico CNI
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-01-install-calico.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-01 - Install Calico CNI"
echo "[INFO] =========================================="
echo ""

# Verify kubeconfig
if [ ! -f /root/.kube/config ]; then
    echo "[ERROR] kubeconfig not found at /root/.kube/config"
    exit 1
fi

# Install Calico
echo "[INFO] Step 1: Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Calico manifests applied"
else
    echo "[ERROR]   ❌ Failed to apply Calico manifests"
    exit 1
fi

# Wait for Calico pods to be ready
echo ""
echo "[INFO] Step 2: Waiting for Calico pods to be ready..."
for i in {1..60}; do
    READY_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep calico | grep -c "Running\|Completed" || echo "0")
    TOTAL_PODS=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep calico | wc -l || echo "0")
    echo "[INFO]   Ready Calico pods: ${READY_PODS}/${TOTAL_PODS}"
    if [ "${TOTAL_PODS}" -ge 3 ] && [ "${READY_PODS}" -eq "${TOTAL_PODS}" ]; then
        echo "[INFO]   ✅ All Calico pods are ready"
        break
    fi
    sleep 10
done

# Wait for all nodes to be ready
echo ""
echo "[INFO] Step 3: Waiting for all nodes to be ready..."
for i in {1..30}; do
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
    echo "[INFO]   Ready nodes: ${READY_NODES}/${TOTAL_NODES}"
    if [ "${READY_NODES}" -ge 8 ] && [ "${READY_NODES}" -eq "${TOTAL_NODES}" ]; then
        echo "[INFO]   ✅ All nodes are ready"
        break
    fi
    sleep 10
done

# Display status
echo ""
echo "[INFO] Step 4: Cluster status..."
kubectl get nodes
kubectl get pods -n kube-system | grep calico

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-01 Calico CNI Installation Complete"
echo "[INFO] =========================================="
echo ""

