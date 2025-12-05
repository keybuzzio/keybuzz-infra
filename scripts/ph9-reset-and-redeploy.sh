#!/bin/bash
# PH9-RESET-AND-REDEPLOY - Complete Kubernetes cluster reset and redeployment
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-reset-and-redeploy.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

MASTERS=("10.0.0.100" "10.0.0.101" "10.0.0.102")
WORKERS=("10.0.0.110" "10.0.0.111" "10.0.0.112" "10.0.0.113" "10.0.0.114")
ALL_NODES=("${MASTERS[@]}" "${WORKERS[@]}")

echo "[INFO] =========================================="
echo "[INFO] PH9-RESET-AND-REDEPLOY"
echo "[INFO] =========================================="
echo ""

# Step 1: Reset all nodes
echo "[INFO] Step 1: Resetting all Kubernetes nodes..."
for ip in "${ALL_NODES[@]}"; do
    echo "[INFO]   Resetting node $ip..."
    ssh root@$ip bash <<RESET_NODE
set -e
echo "[INFO] Resetting kubeadm on $ip"
kubeadm reset -f || true
systemctl stop kubelet || true
systemctl stop containerd || true

rm -rf /etc/kubernetes/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

# Load br_netfilter module
modprobe br_netfilter || true
echo "br_netfilter" > /etc/modules-load.d/k8s.conf

# Configure sysctl
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null 2>&1

# Fix containerd config
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml || true
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

# Restart services
systemctl restart containerd || true
systemctl enable containerd || true
systemctl enable kubelet || true

echo "[INFO] Node $ip reset complete"
RESET_NODE
done

echo "[INFO]   ✅ All nodes reset"
echo ""

# Step 2: Reboot all nodes
echo "[INFO] Step 2: Rebooting all nodes..."
for ip in "${ALL_NODES[@]}"; do
    echo "[INFO]   Rebooting $ip..."
    ssh root@$ip "reboot" || true
done

echo "[INFO]   Waiting for nodes to come back online..."
sleep 30

# Wait for SSH to be available
for ip in "${ALL_NODES[@]}"; do
    echo "[INFO]   Waiting for $ip..."
    for i in {1..30}; do
        if ssh -o ConnectTimeout=5 root@$ip "echo OK" &>/dev/null; then
            echo "[INFO]     ✅ $ip is back online"
            break
        fi
        sleep 2
    done
done

echo ""

# Step 3: Bootstrap master-01
echo "[INFO] Step 3: Bootstrapping master-01 (10.0.0.100)..."
ssh root@10.0.0.100 bash <<BOOTSTRAP_MASTER
set -e
kubeadm init \
  --apiserver-advertise-address=10.0.0.100 \
  --control-plane-endpoint=10.0.0.100:6443 \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs \
  | tee /opt/keybuzz/logs/phase9-reset/kubeadm_init_master01.log

mkdir -p ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config
BOOTSTRAP_MASTER

# Copy kubeconfig to install-v3
echo "[INFO]   Copying kubeconfig to install-v3..."
mkdir -p /root/.kube
scp root@10.0.0.100:/etc/kubernetes/admin.conf /root/.kube/config

export KUBECONFIG=/root/.kube/config

echo "[INFO]   ✅ Master-01 bootstrapped"
echo ""

# Step 4: Get join commands
echo "[INFO] Step 4: Getting join commands..."
JOIN_MASTER=$(ssh root@10.0.0.100 "kubeadm token create --print-join-command 2>/dev/null")
CERT_KEY=$(ssh root@10.0.0.100 "kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1")
JOIN_MASTER_FULL="$JOIN_MASTER --control-plane --certificate-key $CERT_KEY"
JOIN_WORKER="$JOIN_MASTER"

echo "[INFO]   Join master command: $JOIN_MASTER_FULL"
echo "[INFO]   Join worker command: $JOIN_WORKER"

# Save to file
cat > /root/k8s_join.txt <<EOF
JOIN_MASTER=$JOIN_MASTER_FULL
JOIN_WORKER=$JOIN_WORKER
EOF

echo ""

# Step 5: Join other masters
echo "[INFO] Step 5: Joining other masters..."
for ip in 10.0.0.101 10.0.0.102; do
    echo "[INFO]   Joining master $ip..."
    ssh root@$ip "$JOIN_MASTER_FULL" || echo "[WARN] Join failed for $ip"
done

echo ""

# Step 6: Join workers
echo "[INFO] Step 6: Joining workers..."
for ip in "${WORKERS[@]}"; do
    echo "[INFO]   Joining worker $ip..."
    ssh root@$ip "$JOIN_WORKER" || echo "[WARN] Join failed for $ip"
done

echo ""

# Step 7: Wait for nodes to be ready
echo "[INFO] Step 7: Waiting for nodes to be ready..."
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

# Step 8: Install Calico
echo "[INFO] Step 8: Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml \
  | tee /opt/keybuzz/logs/phase9-reset/calico_install.log

echo "[INFO]   Waiting for Calico pods to be ready..."
for i in {1..60}; do
    CALICO_READY=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep calico | grep -c "Running" || echo "0")
    CALICO_TOTAL=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep calico | wc -l || echo "0")
    echo "[INFO]   Calico pods Running: $CALICO_READY/$CALICO_TOTAL"
    if [ "$CALICO_READY" -ge 2 ] && [ "$CALICO_READY" -eq "$CALICO_TOTAL" ]; then
        echo "[INFO]   ✅ Calico is ready"
        break
    fi
    sleep 5
done

kubectl get pods -n kube-system | grep calico

echo ""

# Step 9: Install ArgoCD
echo "[INFO] Step 9: Installing ArgoCD..."
if [ -f scripts/ph9-02-install-argocd.sh ]; then
    chmod +x scripts/ph9-02-install-argocd.sh
    bash scripts/ph9-02-install-argocd.sh \
      | tee /opt/keybuzz/logs/phase9-reset/argocd_install.log
    
    echo "[INFO]   Waiting for ArgoCD pods..."
    sleep 30
    kubectl get pods -n argocd
else
    echo "[ERROR]   Script ph9-02-install-argocd.sh not found"
fi

echo ""

# Step 10: Install ESO
echo "[INFO] Step 10: Installing External Secrets Operator..."
if [ -f scripts/ph9-03-install-eso.sh ]; then
    chmod +x scripts/ph9-03-install-eso.sh
    bash scripts/ph9-03-install-eso.sh \
      | tee /opt/keybuzz/logs/phase9-reset/eso_install.log
    
    echo "[INFO]   Waiting for ESO pods..."
    sleep 20
    kubectl get pods -n external-secrets
else
    echo "[ERROR]   Script ph9-03-install-eso.sh not found"
fi

echo ""

# Step 11: Vault integration
echo "[INFO] Step 11: Configuring Vault ↔ Kubernetes integration..."
if [ -f scripts/ph9-04-vault-k8s-integration.sh ]; then
    chmod +x scripts/ph9-04-vault-k8s-integration.sh
    bash scripts/ph9-04-vault-k8s-integration.sh \
      | tee /opt/keybuzz/logs/phase9-reset/vault_k8s_integration.log
else
    echo "[ERROR]   Script ph9-04-vault-k8s-integration.sh not found"
fi

echo ""

# Step 12: Create namespaces
echo "[INFO] Step 12: Creating namespaces..."
if [ -f scripts/ph9-05-create-namespaces.sh ]; then
    chmod +x scripts/ph9-05-create-namespaces.sh
    bash scripts/ph9-05-create-namespaces.sh \
      | tee /opt/keybuzz/logs/phase9-reset/namespaces.log
fi

echo ""

# Step 13: Test ExternalSecret
echo "[INFO] Step 13: Testing ExternalSecret..."
if [ -f scripts/ph9-06-test-eso.sh ]; then
    chmod +x scripts/ph9-06-test-eso.sh
    bash scripts/ph9-06-test-eso.sh \
      | tee /opt/keybuzz/logs/phase9-reset/test-eso.log
    
    # Verify secret exists
    sleep 10
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]   ✅ ExternalSecret test secret exists"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml | head -20
    else
        echo "[WARN]   ⚠️  ExternalSecret test secret not found, attempting to create..."
        # Create test ExternalSecret manually if needed
        cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: redis-test-secret
  namespace: keybuzz-system
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-keybuzz
    kind: ClusterSecretStore
  target:
    name: redis-test-secret
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: kv/keybuzz/redis
      property: password
EOF
        sleep 15
        if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
            echo "[INFO]   ✅ ExternalSecret test secret created"
        else
            echo "[ERROR]   ❌ ExternalSecret test secret still not found"
        fi
    fi
fi

echo ""

# Step 14: Final validation
echo "[INFO] Step 14: Running final validation..."
if [ -f scripts/ph9-final-validation.sh ]; then
    chmod +x scripts/ph9-final-validation.sh
    bash scripts/ph9-final-validation.sh \
      | tee /opt/keybuzz/logs/phase9-reset/final-validation.log
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-RESET-AND-REDEPLOY Complete"
echo "[INFO] =========================================="
echo ""

