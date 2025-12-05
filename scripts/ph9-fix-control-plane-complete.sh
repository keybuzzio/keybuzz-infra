#!/bin/bash
# PH9-FIX-CONTROL-PLANE-COMPLETE - Complete fix for control-plane and networking
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-fix/ph9-fix-control-plane-complete.log"
mkdir -p /opt/keybuzz/logs/phase9-fix/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FIX-CONTROL-PLANE-COMPLETE"
echo "[INFO] =========================================="
echo ""

# Step 1: Restart kubelet on master-02 and master-03
echo "[INFO] Step 1: Restarting kubelet on master-02 and master-03..."
for ip in 10.0.0.101 10.0.0.102; do
    echo "[INFO]   Restarting kubelet on $ip..."
    ssh root@$ip "systemctl start kubelet && systemctl enable kubelet" 2>&1 || echo "[WARN]   Failed to start kubelet on $ip"
done

sleep 30

# Step 2: Check if nodes are Ready
echo ""
echo "[INFO] Step 2: Checking node status..."
kubectl get nodes 2>&1 | tee /opt/keybuzz/logs/phase9-fix/nodes_status.log

# Step 3: Fix Calico on all nodes
echo ""
echo "[INFO] Step 3: Fixing Calico on all nodes..."
for ip in 10.0.0.100 10.0.0.101 10.0.0.102 10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114; do
    echo "[INFO]   Fixing Calico on $ip..."
    ssh root@$ip bash <<CALICO_FIX
modprobe br_netfilter || true
cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system || true
CALICO_FIX
done

# Delete and recreate Calico pods
kubectl delete pod -n kube-system -l k8s-app=calico-node 2>&1 | grep -v "not found" || true
sleep 30

# Step 4: Fix kube-proxy
echo ""
echo "[INFO] Step 4: Fixing kube-proxy..."
kubectl delete pod -n kube-system -l k8s-app=kube-proxy 2>&1 | grep -v "not found" || true
sleep 30

# Step 5: Fix ESO CRD version issue
echo ""
echo "[INFO] Step 5: Fixing ESO CRD version issue..."
# Check current CRD version
CRD_VERSION=$(kubectl get crd externalsecrets.external-secrets.io -o jsonpath='{.spec.versions[0].name}' 2>/dev/null || echo "")
echo "[INFO]   Current ExternalSecret CRD version: $CRD_VERSION"

# If v1beta1, ensure ESO uses it
if [ "$CRD_VERSION" = "v1beta1" ]; then
    echo "[INFO]   CRD is v1beta1, checking ESO deployment..."
    # Restart ESO to pick up correct CRD version
    kubectl delete pod -n external-secrets -l app.kubernetes.io/name=external-secrets 2>&1 | grep -v "not found" || true
    sleep 30
fi

# Step 6: Test API connectivity
echo ""
echo "[INFO] Step 6: Testing API connectivity..."
kubectl delete pod test-conn -n default 2>&1 | grep -v "not found" || true
sleep 2

kubectl run test-conn --image=busybox:1.36 --restart=Never -- sh -c "wget -qO- --timeout=10 https://kubernetes.default.svc.cluster.local/api || wget -qO- --timeout=10 https://10.96.0.1/api" 2>&1 | tee /opt/keybuzz/logs/phase9-fix/test_api_pod.log || echo "[WARN]   API test may have failed"

sleep 10
kubectl delete pod test-conn -n default 2>&1 | grep -v "not found" || true

# Step 7: Wait for ESO to be ready
echo ""
echo "[INFO] Step 7: Waiting for ESO to be ready..."
for i in {1..60}; do
    ESO_READY=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$ESO_READY" -ge "1" ]; then
        echo "[INFO]   ✅ ESO pod Running"
        break
    fi
    echo "[INFO]   Waiting for ESO... ($i/60) - $ESO_READY Running"
    sleep 5
done

# Step 8: Re-execute Vault integration
echo ""
echo "[INFO] Step 8: Re-executing Vault integration..."
bash scripts/ph9-finalize-vault-eso-complete.sh 2>&1 | tee /opt/keybuzz/logs/phase9-fix/finalize_vault.log || echo "[WARN]   Vault integration may have issues"

# Step 9: Test ExternalSecret
echo ""
echo "[INFO] Step 9: Testing ExternalSecret..."
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

# Step 10: Final validation
echo ""
echo "[INFO] Step 10: Final validation..."
kubectl get nodes -o wide 2>&1 | tee /opt/keybuzz/logs/phase9-fix/nodes_final.log
kubectl get pods -A 2>&1 | tee /opt/keybuzz/logs/phase9-fix/pods_final.log

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

CRASHLOOP=$(kubectl get pods -A --no-headers 2>/dev/null | grep -c CrashLoopBackOff || echo "0")
echo "[INFO] Pods in CrashLoopBackOff: $CRASHLOOP"

echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-FIX-CONTROL-PLANE-COMPLETE Finished"
echo "[INFO] =========================================="
echo ""

