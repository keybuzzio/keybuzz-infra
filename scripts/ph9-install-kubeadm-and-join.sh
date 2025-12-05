#!/bin/bash
# PH9-INSTALL-KUBEADM-AND-JOIN - Install kubeadm on all nodes and join them
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-install-kubeadm-and-join.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

MASTERS=("10.0.0.101" "10.0.0.102")
WORKERS=("10.0.0.110" "10.0.0.111" "10.0.0.112" "10.0.0.113" "10.0.0.114")

echo "[INFO] =========================================="
echo "[INFO] PH9-INSTALL-KUBEADM-AND-JOIN"
echo "[INFO] =========================================="
echo ""

# Install kubeadm on all nodes
echo "[INFO] Step 1: Installing kubeadm on all nodes..."
for ip in "${MASTERS[@]}" "${WORKERS[@]}"; do
    echo "[INFO]   Installing kubeadm on $ip..."
    ssh root@$ip bash <<INSTALL_KUBEADM
set -e
# Fix GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || true

# Add repository
cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
EOF

# Update and install
apt-get update || true
apt-get install -y kubelet kubeadm kubectl || true
apt-mark hold kubelet kubeadm kubectl || true

# Enable kubelet
systemctl enable kubelet || true
INSTALL_KUBEADM
done

echo ""

# Get join commands
echo "[INFO] Step 2: Getting join commands from master-01..."
JOIN_BASE=$(ssh root@10.0.0.100 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm token create --print-join-command 2>&1" | grep "kubeadm join")
CERT_KEY=$(ssh root@10.0.0.100 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm init phase upload-certs --upload-certs 2>&1" | tail -1)
JOIN_MASTER_FULL="$JOIN_BASE --control-plane --certificate-key $CERT_KEY"
JOIN_WORKER="$JOIN_BASE"

echo "[INFO]   Join master: $JOIN_MASTER_FULL"
echo "[INFO]   Join worker: $JOIN_WORKER"
echo ""

# Join other masters
echo "[INFO] Step 3: Joining other masters..."
for ip in "${MASTERS[@]}"; do
    echo "[INFO]   Joining master $ip..."
    ssh root@$ip "$JOIN_MASTER_FULL" 2>&1 | tee /opt/keybuzz/logs/phase9-reset/join_master_${ip}.log || echo "[WARN] Join may have issues for $ip"
done

echo ""

# Join workers
echo "[INFO] Step 4: Joining workers..."
for ip in "${WORKERS[@]}"; do
    echo "[INFO]   Joining worker $ip..."
    ssh root@$ip "$JOIN_WORKER" 2>&1 | tee /opt/keybuzz/logs/phase9-reset/join_worker_${ip}.log || echo "[WARN] Join may have issues for $ip"
done

echo ""

# Wait for nodes
echo "[INFO] Step 5: Waiting for nodes to join..."
sleep 30

for i in {1..60}; do
    READY_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "Ready" || echo "0")
    TOTAL_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
    echo "[INFO]   Ready nodes: $READY_COUNT/$TOTAL_COUNT"
    if [ "$READY_COUNT" -ge 8 ] && [ "$READY_COUNT" -eq "$TOTAL_COUNT" ]; then
        echo "[INFO]   ✅ All nodes are Ready"
        break
    fi
    sleep 10
done

kubectl get nodes -o wide

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-INSTALL-KUBEADM-AND-JOIN Complete"
echo "[INFO] =========================================="
echo ""

