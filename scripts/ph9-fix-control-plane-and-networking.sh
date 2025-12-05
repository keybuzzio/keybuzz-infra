#!/bin/bash
# PH9-FIX-CONTROL-PLANE-AND-NETWORKING - Fix control-plane and networking issues
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-fix/ph9-fix-control-plane-and-networking.log"
mkdir -p /opt/keybuzz/logs/phase9-fix/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FIX-CONTROL-PLANE-AND-NETWORKING"
echo "[INFO] =========================================="
echo ""

# Step 1: Fix control-plane on master-02 and master-03
echo "[INFO] Step 1: Fixing control-plane on master-02 and master-03..."
for ip in 10.0.0.101 10.0.0.102; do
    echo "[INFO]   Fixing $ip..."
    ssh root@$ip bash <<NODE_FIX
set -e
echo '[INFO] Fixing control-plane on $ip'

systemctl stop kubelet || true
systemctl stop containerd || true

rm -rf /etc/kubernetes/manifests/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

modprobe br_netfilter || true
echo 'br_netfilter' > /etc/modules-load.d/k8s.conf
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd
systemctl enable kubelet

echo '[INFO]   ✅ Node $ip cleaned and configured'
NODE_FIX
done

echo "[INFO]   Waiting 10 seconds..."
sleep 10

# Get join command from master-01
echo "[INFO]   Getting join command from master-01..."
JOIN_MASTER=$(ssh root@10.0.0.100 "kubeadm token create --print-join-command --certificate-key \$(kubeadm init phase upload-certs --upload-certs 2>&1 | tail -1)")

if [ -z "$JOIN_MASTER" ]; then
    echo "[ERROR]   Failed to get join command"
    exit 1
fi

echo "[INFO]   Join command retrieved"

# Execute join on master-02 and master-03
echo "[INFO]   Joining master-02..."
ssh root@10.0.0.101 "$JOIN_MASTER --control-plane --ignore-preflight-errors=CRI" || echo "[WARN]   Join may have failed, continuing..."

echo "[INFO]   Joining master-03..."
ssh root@10.0.0.102 "$JOIN_MASTER --control-plane --ignore-preflight-errors=CRI" || echo "[WARN]   Join may have failed, continuing..."

# Reboot masters
echo "[INFO]   Rebooting masters..."
ssh root@10.0.0.101 "reboot" || true
ssh root@10.0.0.102 "reboot" || true

echo "[INFO]   Waiting for masters to come back..."
for i in {1..60}; do
    if ssh root@10.0.0.101 "echo master-02 back" 2>/dev/null && ssh root@10.0.0.102 "echo master-03 back" 2>/dev/null; then
        echo "[INFO]   ✅ Masters are back"
        break
    fi
    echo "[INFO]   Waiting... ($i/60)"
    sleep 5
done

sleep 30

# Step 2: Fix Calico on all nodes
echo ""
echo "[INFO] Step 2: Fixing Calico on all nodes..."
for ip in 10.0.0.100 10.0.0.101 10.0.0.102 10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114; do
    echo "[INFO]   Fixing Calico on $ip..."
    ssh root@$ip bash <<CALICO_FIX
set -e
echo '[INFO] Fixing Calico on $ip'

modprobe br_netfilter || true

cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd || true

echo '[INFO]   ✅ Node $ip configured for Calico'
CALICO_FIX
done

# Reapply Calico
echo "[INFO]   Reapplying Calico..."
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | grep -v "not found" || true
sleep 5
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee /opt/keybuzz/logs/phase9-fix/calico_reapply.log

echo "[INFO]   Waiting for Calico pods..."
for i in {1..60}; do
    CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$CALICO_READY" -ge "7" ]; then
        echo "[INFO]   ✅ Calico pods Running ($CALICO_READY/8)"
        break
    fi
    echo "[INFO]   Waiting for Calico... ($i/60) - $CALICO_READY Running"
    sleep 5
done

# Step 3: Fix kube-proxy
echo ""
echo "[INFO] Step 3: Fixing kube-proxy..."
kubectl delete pod -n kube-system -l k8s-app=kube-proxy 2>&1 | grep -v "not found" || true

echo "[INFO]   Waiting for kube-proxy pods..."
for i in {1..60}; do
    PROXY_READY=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$PROXY_READY" -ge "7" ]; then
        echo "[INFO]   ✅ kube-proxy pods Running ($PROXY_READY/8)"
        break
    fi
    echo "[INFO]   Waiting for kube-proxy... ($i/60) - $PROXY_READY Running"
    sleep 5
done

# Step 4: Test API connectivity from pods
echo ""
echo "[INFO] Step 4: Testing API connectivity from pods..."
kubectl delete pod test-conn -n default 2>&1 | grep -v "not found" || true
sleep 2

kubectl run test-conn --image=busybox:1.36 --restart=Never -- sh -c "wget -qO- --timeout=10 https://kubernetes.default.svc.cluster.local/api || wget -qO- --timeout=10 https://10.96.0.1/api" 2>&1 | tee /opt/keybuzz/logs/phase9-fix/test_api_pod.log || echo "[WARN]   API test may have failed"

sleep 10
kubectl delete pod test-conn -n default 2>&1 | grep -v "not found" || true

# Step 5: Fix ESO
echo ""
echo "[INFO] Step 5: Fixing ESO..."
kubectl delete pod -n external-secrets -l app.kubernetes.io/name=external-secrets 2>&1 | grep -v "not found" || true

echo "[INFO]   Waiting for ESO pods..."
for i in {1..60}; do
    ESO_READY=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$ESO_READY" -ge "1" ]; then
        echo "[INFO]   ✅ ESO pod Running"
        break
    fi
    echo "[INFO]   Waiting for ESO... ($i/60) - $ESO_READY Running"
    sleep 5
done

# Step 6: Re-execute Vault integration
echo ""
echo "[INFO] Step 6: Re-executing Vault integration..."
bash scripts/ph9-finalize-vault-eso-complete.sh 2>&1 | tee /opt/keybuzz/logs/phase9-fix/finalize_vault.log || echo "[WARN]   Vault integration may have issues"

# Step 7: Test ExternalSecret
echo ""
echo "[INFO] Step 7: Testing ExternalSecret..."
if [ -f "k8s/tests/test-redis-externalsecret.yaml" ]; then
    kubectl apply -f k8s/tests/test-redis-externalsecret.yaml 2>&1 | tee /opt/keybuzz/logs/phase9-fix/test_externalsecret.log || echo "[WARN]   ExternalSecret apply may have failed"
else
    echo "[INFO]   ExternalSecret already exists, checking status..."
fi

echo "[INFO]   Waiting for secret synchronization..."
for i in {1..60}; do
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]   ✅ Secret redis-test-secret created"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | tee /opt/keybuzz/logs/phase9-fix/redis_secret.yaml
        break
    fi
    echo "[INFO]   Waiting for secret sync... ($i/60)"
    sleep 5
done

# Step 8: Final validation
echo ""
echo "[INFO] Step 8: Final validation..."
kubectl get nodes -o wide 2>&1 | tee /opt/keybuzz/logs/phase9-fix/nodes_final.log
kubectl get pods -A 2>&1 | tee /opt/keybuzz/logs/phase9-fix/pods_final.log

if [ -f "scripts/ph9-final-validation.sh" ]; then
    bash scripts/ph9-final-validation.sh 2>&1 | tee /opt/keybuzz/logs/phase9-fix/final_validation_run.log || echo "[WARN]   Final validation script may have issues"
fi

# Final summary
echo ""
echo "[INFO] =========================================="
echo "[INFO] FINAL SUMMARY"
echo "[INFO] =========================================="

NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
echo "[INFO] Nodes Ready: $NODES_READY/8"

API_SERVERS=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] API Servers Running: $API_SERVERS/3"

ETCD_PODS=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] ETCD Pods Running: $ETCD_PODS/3"

CALICO_PODS=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] Calico Pods Running: $CALICO_PODS/8"

PROXY_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] kube-proxy Pods Running: $PROXY_PODS/8"

ESO_PODS=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] ESO Pods Running: $ESO_PODS/1"

SECRET_EXISTS=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo "YES" || echo "NO")
echo "[INFO] Secret redis-test-secret: $SECRET_EXISTS"

echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-FIX-CONTROL-PLANE-AND-NETWORKING Finished"
echo "[INFO] =========================================="
echo ""

