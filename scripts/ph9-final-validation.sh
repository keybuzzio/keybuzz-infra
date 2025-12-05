#!/bin/bash
# PH9-FINAL-VALIDATION - Complete Kubernetes v3 + ArgoCD + ESO + Vault validation
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-final-validation.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FINAL-VALIDATION"
echo "[INFO] =========================================="
echo ""

# Step 1: Verify K8s nodes
echo "[INFO] Step 1: Verifying Kubernetes nodes..."
NODES_OUTPUT=$(kubectl get nodes -o wide 2>&1)
echo "$NODES_OUTPUT"

MASTERS_READY=$(echo "$NODES_OUTPUT" | grep -c "k8s-master.*Ready" || echo "0")
WORKERS_READY=$(echo "$NODES_OUTPUT" | grep -c "k8s-worker.*Ready" || echo "0")
TOTAL_READY=$(echo "$NODES_OUTPUT" | grep -c "Ready" || echo "0")

echo ""
echo "[INFO]   Masters Ready: $MASTERS_READY/3"
echo "[INFO]   Workers Ready: $WORKERS_READY/5"
echo "[INFO]   Total Ready: $TOTAL_READY/8"

if [ "$MASTERS_READY" -lt 3 ] || [ "$WORKERS_READY" -lt 5 ]; then
    echo "[WARN]   ⚠️  Some nodes are not Ready, attempting to fix..."
    if [ -f scripts/ph9-01-bootstrap-k8s.sh ]; then
        echo "[INFO]   Running bootstrap script..."
        bash scripts/ph9-01-bootstrap-k8s.sh || echo "[WARN] Bootstrap script may need manual intervention"
    fi
    # Re-check after fix attempt
    sleep 10
    NODES_OUTPUT=$(kubectl get nodes -o wide 2>&1)
    MASTERS_READY=$(echo "$NODES_OUTPUT" | grep -c "k8s-master.*Ready" || echo "0")
    WORKERS_READY=$(echo "$NODES_OUTPUT" | grep -c "k8s-worker.*Ready" || echo "0")
    echo "[INFO]   After fix attempt - Masters: $MASTERS_READY/3, Workers: $WORKERS_READY/5"
fi

NODES_OK=false
if [ "$MASTERS_READY" -eq 3 ] && [ "$WORKERS_READY" -eq 5 ]; then
    echo "[INFO]   ✅ All nodes Ready"
    NODES_OK=true
else
    echo "[ERROR]   ❌ Not all nodes are Ready"
fi

echo ""

# Step 2: Verify system pods
echo "[INFO] Step 2: Verifying system pods..."
PODS_OUTPUT=$(kubectl get pods -A 2>&1)
echo "$PODS_OUTPUT" | head -50

# Check kube-system namespace
COREDNS_RUNNING=$(echo "$PODS_OUTPUT" | grep -c "coredns.*Running" || echo "0")
KUBE_PROXY_RUNNING=$(echo "$PODS_OUTPUT" | grep -c "kube-proxy.*Running" || echo "0")
CALICO_RUNNING=$(echo "$PODS_OUTPUT" | grep -c "calico.*Running" || echo "0")
CILIUM_RUNNING=$(echo "$PODS_OUTPUT" | grep -c "cilium.*Running" || echo "0")

echo ""
echo "[INFO]   CoreDNS Running: $COREDNS_RUNNING"
echo "[INFO]   Kube-proxy Running: $KUBE_PROXY_RUNNING"
echo "[INFO]   Calico Running: $CALICO_RUNNING"
echo "[INFO]   Cilium Running: $CILIUM_RUNNING"

# Check for CrashLoopBackOff
CRASH_LOOP=$(echo "$PODS_OUTPUT" | grep -c "CrashLoopBackOff" || echo "0")
if [ "$CRASH_LOOP" -gt 0 ]; then
    echo "[WARN]   ⚠️  Found $CRASH_LOOP pods in CrashLoopBackOff"
    echo "[INFO]   CrashLoopBackOff pods:"
    echo "$PODS_OUTPUT" | grep "CrashLoopBackOff" || true
fi

PODS_OK=false
if [ "$COREDNS_RUNNING" -ge 2 ] && [ "$KUBE_PROXY_RUNNING" -ge 8 ] && [ "$CRASH_LOOP" -eq 0 ]; then
    echo "[INFO]   ✅ System pods OK"
    PODS_OK=true
else
    echo "[ERROR]   ❌ Some system pods are not Running"
fi

echo ""

# Step 3: Verify ArgoCD
echo "[INFO] Step 3: Verifying ArgoCD installation..."
kubectl get ns argocd >/dev/null 2>&1 || kubectl create ns argocd

ARGOCD_PODS=$(kubectl get pods -n argocd 2>&1)
echo "$ARGOCD_PODS"

ARGOCD_SERVER=$(echo "$ARGOCD_PODS" | grep -c "argocd-server.*Running" || echo "0")
ARGOCD_REPO=$(echo "$ARGOCD_PODS" | grep -c "argocd-repo-server.*Running" || echo "0")
ARGOCD_CONTROLLER=$(echo "$ARGOCD_PODS" | grep -c "argocd-application-controller.*Running" || echo "0")
ARGOCD_DEX=$(echo "$ARGOCD_PODS" | grep -c "argocd-dex-server.*Running" || echo "0")

echo ""
echo "[INFO]   ArgoCD Server Running: $ARGOCD_SERVER"
echo "[INFO]   ArgoCD Repo Server Running: $ARGOCD_REPO"
echo "[INFO]   ArgoCD Controller Running: $ARGOCD_CONTROLLER"
echo "[INFO]   ArgoCD Dex Server Running: $ARGOCD_DEX"

ARGOCD_OK=false
if [ "$ARGOCD_SERVER" -ge 1 ] && [ "$ARGOCD_REPO" -ge 1 ] && [ "$ARGOCD_CONTROLLER" -ge 1 ]; then
    echo "[INFO]   ✅ ArgoCD OK"
    ARGOCD_OK=true
else
    echo "[WARN]   ⚠️  ArgoCD not fully deployed, attempting to install..."
    if [ -f scripts/ph9-02-install-argocd.sh ]; then
        bash scripts/ph9-02-install-argocd.sh || echo "[WARN] ArgoCD install may need manual intervention"
    fi
fi

echo ""

# Step 4: Verify ESO
echo "[INFO] Step 4: Verifying External Secrets Operator..."
kubectl get ns external-secrets >/dev/null 2>&1 || kubectl create ns external-secrets

ESO_PODS=$(kubectl get pods -n external-secrets 2>&1)
echo "$ESO_PODS"

ESO_RUNNING=$(echo "$ESO_PODS" | grep -c "external-secrets.*Running" || echo "0")

echo ""
echo "[INFO]   ESO pods Running: $ESO_RUNNING"

ESO_OK=false
if [ "$ESO_RUNNING" -ge 1 ]; then
    echo "[INFO]   ✅ ESO OK"
    ESO_OK=true
else
    echo "[WARN]   ⚠️  ESO not deployed, attempting to install..."
    if [ -f scripts/ph9-03-install-eso.sh ]; then
        bash scripts/ph9-03-install-eso.sh || echo "[WARN] ESO install may need manual intervention"
    fi
fi

echo ""

# Step 5: Verify Vault ↔ K8s integration
echo "[INFO] Step 5: Verifying Vault ↔ K8s integration..."
if [ -f scripts/ph9-04-vault-k8s-integration.sh ]; then
    chmod +x scripts/ph9-04-vault-k8s-integration.sh
    if bash scripts/ph9-04-vault-k8s-integration.sh 2>&1 | tee /opt/keybuzz/logs/phase9/vault_k8s_integration_final.log; then
        echo "[INFO]   ✅ Vault ↔ K8s integration OK"
        VAULT_K8S_OK=true
    else
        echo "[ERROR]   ❌ Vault ↔ K8s integration failed"
        VAULT_K8S_OK=false
    fi
else
    echo "[WARN]   Script ph9-04-vault-k8s-integration.sh not found"
    VAULT_K8S_OK=false
fi

echo ""

# Step 6: Verify ClusterSecretStore
echo "[INFO] Step 6: Verifying ClusterSecretStore..."
CLUSTER_SECRET_STORE=$(kubectl get ClusterSecretStore vault-keybuzz -o yaml 2>&1)
if echo "$CLUSTER_SECRET_STORE" | grep -q "vault-keybuzz"; then
    echo "[INFO]   ✅ ClusterSecretStore vault-keybuzz exists"
    echo "$CLUSTER_SECRET_STORE" | grep -A 5 "server:\|path:\|role:" || true
    CLUSTER_STORE_OK=true
else
    echo "[WARN]   ⚠️  ClusterSecretStore vault-keybuzz not found"
    CLUSTER_STORE_OK=false
fi

echo ""

# Step 7: Verify ExternalSecret test
echo "[INFO] Step 7: Verifying ExternalSecret test..."
if [ -f scripts/ph9-06-test-eso.sh ]; then
    chmod +x scripts/ph9-06-test-eso.sh
    if bash scripts/ph9-06-test-eso.sh 2>&1 | tee /opt/keybuzz/logs/phase9/test-eso-final.log; then
        echo "[INFO]   ✅ ESO test script executed"
    else
        echo "[WARN]   ESO test script had issues"
    fi
fi

# Check for test secret
sleep 5
kubectl get ns keybuzz-system >/dev/null 2>&1 || kubectl create ns keybuzz-system
TEST_SECRET=$(kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1)

if echo "$TEST_SECRET" | grep -q "redis-test-secret"; then
    echo "[INFO]   ✅ ExternalSecret test secret exists"
    echo "$TEST_SECRET" | head -20
    EXTERNAL_SECRET_OK=true
else
    echo "[WARN]   ⚠️  ExternalSecret test secret not found"
    echo "[INFO]   Attempting to create test ExternalSecret..."
    
    # Create a simple test ExternalSecret
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
    
    sleep 10
    TEST_SECRET=$(kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1)
    if echo "$TEST_SECRET" | grep -q "redis-test-secret"; then
        echo "[INFO]   ✅ ExternalSecret test secret created"
        EXTERNAL_SECRET_OK=true
    else
        echo "[ERROR]   ❌ ExternalSecret test secret still not found"
        EXTERNAL_SECRET_OK=false
    fi
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] PH9-FINAL-VALIDATION Summary"
echo "[INFO] =========================================="
echo "[INFO] Kubernetes Nodes: $([ \"$NODES_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] System Pods: $([ \"$PODS_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] ArgoCD: $([ \"$ARGOCD_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] ESO: $([ \"$ESO_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] Vault ↔ K8s: $([ \"$VAULT_K8S_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] ClusterSecretStore: $([ \"$CLUSTER_STORE_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] ExternalSecret Test: $([ \"$EXTERNAL_SECRET_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] =========================================="
echo ""

