#!/bin/bash
# PH9-01 - Bootstrap Kubernetes Cluster
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-01-bootstrap-k8s.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] =========================================="
echo "[INFO] PH9-01 - Bootstrap Kubernetes Cluster"
echo "[INFO] =========================================="
echo ""

# Pull latest changes
echo "[INFO] Step 1: Pulling latest changes..."
git pull --rebase

# Verify Ansible inventory
echo ""
echo "[INFO] Step 2: Verifying Ansible inventory..."
if ! ansible-inventory -i ansible/inventory/hosts.yml --list | grep -q k8s_masters; then
    echo "[ERROR] Kubernetes hosts not found in inventory"
    exit 1
fi
echo "[INFO]   ✅ Kubernetes hosts found in inventory"

# Verify SSH connectivity to all K8s nodes
echo ""
echo "[INFO] Step 3: Verifying SSH connectivity..."
ansible k8s_masters:k8s_workers -i ansible/inventory/hosts.yml -m ping || {
    echo "[ERROR] SSH connectivity check failed"
    exit 1
}
echo "[INFO]   ✅ SSH connectivity verified"

# Deploy Kubernetes cluster
echo ""
echo "[INFO] Step 4: Deploying Kubernetes cluster..."
ansible-playbook \
    -i ansible/inventory/hosts.yml \
    ansible/playbooks/k8s_cluster_v3.yml \
    2>&1 | tee /opt/keybuzz/logs/phase9/k8s_cluster_deploy.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "[INFO]   ✅ Kubernetes cluster deployment completed"
else
    echo "[ERROR]   ❌ Kubernetes cluster deployment failed"
    exit 1
fi

# Verify kubeconfig
echo ""
echo "[INFO] Step 5: Verifying kubeconfig..."
if [ -f /root/.kube/config ]; then
    export KUBECONFIG=/root/.kube/config
    kubectl cluster-info
    echo "[INFO]   ✅ kubeconfig configured"
else
    echo "[ERROR]   ❌ kubeconfig not found"
    exit 1
fi

# Wait for nodes to be ready
echo ""
echo "[INFO] Step 6: Waiting for all nodes to be ready..."
export KUBECONFIG=/root/.kube/config
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

kubectl get nodes

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-01 Kubernetes Bootstrap Complete"
echo "[INFO] =========================================="
echo ""

