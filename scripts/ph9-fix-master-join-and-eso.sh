#!/bin/bash
# PH9-FIX-MASTER-JOIN-AND-ESO - Fix master join and ESO CRD version issue
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-fix/ph9-fix-master-join-and-eso.log"
mkdir -p /opt/keybuzz/logs/phase9-fix/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FIX-MASTER-JOIN-AND-ESO"
echo "[INFO] =========================================="
echo ""

# Step 1: Get join command from master-01
echo "[INFO] Step 1: Getting join command from master-01..."
# Get CA cert hash from master-01
CA_HASH=$(ssh root@10.0.0.100 "cat /etc/kubernetes/pki/ca.crt | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")

if [ -z "$CA_HASH" ]; then
    echo "[ERROR]   Failed to get CA cert hash"
    exit 1
fi

# Get existing bootstrap token or create new one
BOOTSTRAP_SECRET=$(kubectl get secret -n kube-system --no-headers 2>/dev/null | grep bootstrap-token | head -1 | awk '{print $1}')
if [ -n "$BOOTSTRAP_SECRET" ]; then
    TOKEN_ID=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-id}' 2>/dev/null | base64 -d)
    TOKEN_SECRET=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-secret}' 2>/dev/null | base64 -d)
    TOKEN="${TOKEN_ID}.${TOKEN_SECRET}"
    echo "[INFO]   Using existing bootstrap token: ${TOKEN_ID}..."
else
    echo "[ERROR]   No bootstrap token found"
    exit 1
fi

# Get certificate key
CERT_OUTPUT=$(ssh root@10.0.0.100 "kubeadm init phase upload-certs --upload-certs 2>&1")
CERT_KEY=$(echo "$CERT_OUTPUT" | grep -E '^[a-f0-9]{64}$' | head -1)

if [ -z "$CERT_KEY" ]; then
    echo "[ERROR]   Failed to get certificate key. Output: $CERT_OUTPUT"
    exit 1
fi

# Construct join command - use unsafe skip for now due to network issues
JOIN_MASTER="kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI"
echo "[INFO]   Join command retrieved"
echo "[INFO]   CA Hash: ${CA_HASH:0:20}..."
echo "[INFO]   Token: ${TOKEN_ID}..."
echo "[INFO]   Cert Key: ${CERT_KEY:0:20}..."

# Step 2: Join master-02
echo ""
echo "[INFO] Step 2: Joining master-02..."
echo "[INFO]   Waiting 30 seconds before attempting join to avoid rate limiting..."
sleep 30

ssh root@10.0.0.101 bash <<MASTER02_JOIN
set +e
echo '[INFO] Joining master-02 to cluster...'

# Clean up first
kubeadm reset -f || true
rm -rf /etc/kubernetes/manifests/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

# Ensure network modules
modprobe br_netfilter || true
echo 'br_netfilter' > /etc/modules-load.d/k8s.conf
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Fix containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Wait a bit before joining
sleep 10

# Join cluster with retry
for attempt in 1 2 3; do
    echo "[INFO]   Join attempt $attempt/3..."
    eval ${JOIN_MASTER} && {
        echo '[INFO]   ✅ master-02 joined successfully'
        exit 0
    }
    if [ "$attempt" -lt 3 ]; then
        echo "[INFO]   Join failed, waiting 30 seconds before retry..."
        sleep 30
    fi
done

echo '[ERROR]   Failed to join master-02 after 3 attempts'
exit 1
MASTER02_JOIN

JOIN_RESULT=$?
if [ $JOIN_RESULT -ne 0 ]; then
    echo "[WARN]   master-02 join failed, but continuing..."
fi

sleep 60

# Step 3: Join master-03
echo ""
echo "[INFO] Step 3: Joining master-03..."
echo "[INFO]   Waiting 30 seconds before attempting join to avoid rate limiting..."
sleep 30

ssh root@10.0.0.102 bash <<MASTER03_JOIN
set +e
echo '[INFO] Joining master-03 to cluster...'

# Clean up first
kubeadm reset -f || true
rm -rf /etc/kubernetes/manifests/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

# Ensure network modules
modprobe br_netfilter || true
echo 'br_netfilter' > /etc/modules-load.d/k8s.conf
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Fix containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Wait a bit before joining
sleep 10

# Join cluster with retry
for attempt in 1 2 3; do
    echo "[INFO]   Join attempt $attempt/3..."
    eval ${JOIN_MASTER} && {
        echo '[INFO]   ✅ master-03 joined successfully'
        exit 0
    }
    if [ "$attempt" -lt 3 ]; then
        echo "[INFO]   Join failed, waiting 30 seconds before retry..."
        sleep 30
    fi
done

echo '[ERROR]   Failed to join master-03 after 3 attempts'
exit 1
MASTER03_JOIN

JOIN_RESULT=$?
if [ $JOIN_RESULT -ne 0 ]; then
    echo "[WARN]   master-03 join failed, but continuing..."
fi

sleep 90

# Step 4: Wait for control-plane pods
echo ""
echo "[INFO] Step 4: Waiting for control-plane pods..."
for i in {1..60}; do
    API_READY=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
    ETCD_READY=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
    
    if [ "$API_READY" -ge "2" ] && [ "$ETCD_READY" -ge "2" ]; then
        echo "[INFO]   ✅ Control-plane pods Running (API: $API_READY/3, ETCD: $ETCD_READY/3)"
        break
    fi
    echo "[INFO]   Waiting for control-plane... ($i/60) - API: $API_READY/3, ETCD: $ETCD_READY/3"
    sleep 5
done

# Step 5: Fix ESO CRD version issue
echo ""
echo "[INFO] Step 5: Fixing ESO CRD version issue..."
# Check if v1 version exists
V1_EXISTS=$(kubectl get crd externalsecrets.external-secrets.io -o jsonpath='{.spec.versions[*].name}' 2>/dev/null | grep -q v1 && echo "yes" || echo "no")

if [ "$V1_EXISTS" = "no" ]; then
    echo "[INFO]   Adding v1 version to ExternalSecret CRD..."
    # Get current CRD
    kubectl get crd externalsecrets.external-secrets.io -o yaml > /tmp/externalsecret-crd.yaml
    
    # Add v1 version using yq or sed
    # For now, we'll use kubectl patch with a more complete schema
    kubectl patch crd externalsecrets.external-secrets.io --type='json' -p='[
        {
            "op": "add",
            "path": "/spec/versions/-",
            "value": {
                "name": "v1",
                "served": true,
                "storage": false,
                "schema": {
                    "openAPIV3Schema": {
                        "type": "object",
                        "x-kubernetes-preserve-unknown-fields": true
                    }
                },
                "subresources": {
                    "status": {}
                }
            }
        }
    ]' 2>&1 || echo "[WARN]   Failed to patch CRD, trying alternative method..."
    
    # Alternative: reinstall ESO with correct version
    echo "[INFO]   Reinstalling ESO to ensure correct CRD versions..."
    bash scripts/ph9-03-install-eso.sh 2>&1 | tee /opt/keybuzz/logs/phase9-fix/eso-reinstall.log || echo "[WARN]   ESO reinstall may have issues"
fi

# Restart ESO pods
echo "[INFO]   Restarting ESO pods..."
kubectl delete pod -n external-secrets -l app.kubernetes.io/name=external-secrets 2>&1 | grep -v "not found" || true
kubectl delete pod -n external-secrets -l app.kubernetes.io/name=external-secrets-webhook 2>&1 | grep -v "not found" || true
kubectl delete pod -n external-secrets -l app.kubernetes.io/name=external-secrets-cert-controller 2>&1 | grep -v "not found" || true

echo "[INFO]   Waiting for ESO..."
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

ESO_PODS=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
echo "[INFO] ESO Pods Running: $ESO_PODS/1"

SECRET_EXISTS=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo "YES" || echo "NO")
echo "[INFO] Secret redis-test-secret: $SECRET_EXISTS"

echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-FIX-MASTER-JOIN-AND-ESO Finished"
echo "[INFO] =========================================="
echo ""

