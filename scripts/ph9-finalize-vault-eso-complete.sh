#!/bin/bash
# PH9-FINALIZE-VAULT-ESO-COMPLETE - Complete Vault and ESO configuration
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-finalize-vault-eso-complete.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FINALIZE-VAULT-ESO-COMPLETE"
echo "[INFO] =========================================="
echo ""

# Step 1: Verify ESO CRDs are available
echo "[INFO] Step 1: Verifying ESO CRDs..."
kubectl api-resources --api-group=external-secrets.io 2>&1 | grep -q clustersecretstore && echo "[INFO]   ✅ ClusterSecretStore CRD available" || echo "[ERROR]   ❌ ClusterSecretStore CRD not available"
kubectl api-resources --api-group=external-secrets.io 2>&1 | grep -q externalsecret && echo "[INFO]   ✅ ExternalSecret CRD available" || echo "[ERROR]   ❌ ExternalSecret CRD not available"

# Step 2: Get Kubernetes API info
echo ""
echo "[INFO] Step 2: Getting Kubernetes API info..."
K8S_API=$(kubectl cluster-info 2>/dev/null | grep "Kubernetes control plane" | awk '{print $NF}' | sed 's|https://||' || echo "10.0.0.100:6443")
echo "[INFO]   K8S API: $K8S_API"

# Get CA cert from kubeconfig
K8S_CA_CERT=$(cat /root/.kube/config | grep "certificate-authority-data:" -A 1 | tail -1 | sed 's/^[[:space:]]*//' | base64 -d 2>/dev/null || kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d 2>/dev/null || echo "")

if [ -z "$K8S_CA_CERT" ]; then
    # Try alternative method
    K8S_CA_CERT=$(kubectl get secret -n kube-system $(kubectl get sa default -n kube-system -o jsonpath='{.secrets[0].name}' 2>/dev/null) -o jsonpath='{.data.ca\.crt}' 2>/dev/null | base64 -d || echo "")
fi

if [ -z "$K8S_CA_CERT" ]; then
    # Try from master-01
    K8S_CA_CERT=$(ssh root@10.0.0.100 "cat /etc/kubernetes/pki/ca.crt" 2>/dev/null || echo "")
fi

if [ -z "$K8S_CA_CERT" ]; then
    echo "[ERROR]   ❌ Failed to retrieve CA cert"
    exit 1
fi

echo "[INFO]   CA Cert length: ${#K8S_CA_CERT}"

# Create/verify vault-auth service account
echo ""
echo "[INFO] Step 3: Creating/verifying vault-auth service account..."
kubectl create serviceaccount vault-auth -n kube-system --dry-run=client -o yaml | kubectl apply -f - 2>&1 | grep -v "already exists" || true
kubectl create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=kube-system:vault-auth \
    --dry-run=client -o yaml | kubectl apply -f - 2>&1 | grep -v "already exists" || true

# Get service account token (Kubernetes 1.24+ uses create token)
SA_TOKEN=$(kubectl create token vault-auth -n kube-system --duration=8760h 2>/dev/null || echo "")

if [ -z "$SA_TOKEN" ]; then
    # Fallback: try to get from secret
    SA_SECRET_NAME=$(kubectl get sa vault-auth -n kube-system -o jsonpath='{.secrets[0].name}' 2>/dev/null || echo "")
    if [ -n "$SA_SECRET_NAME" ]; then
        SA_TOKEN=$(kubectl get secret $SA_SECRET_NAME -n kube-system -o jsonpath='{.data.token}' 2>/dev/null | base64 -d || echo "")
    fi
fi

if [ -z "$SA_TOKEN" ]; then
    # Last resort: use default service account token
    echo "[WARN]   Using default service account token as fallback"
    SA_TOKEN=$(kubectl get secret -n kube-system $(kubectl get sa default -n kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' 2>/dev/null | base64 -d || echo "")
fi

if [ -z "$SA_TOKEN" ]; then
    echo "[ERROR]   ❌ Failed to retrieve SA token"
    exit 1
fi

echo "[INFO]   SA Token length: ${#SA_TOKEN}"

# Step 4: Configure Vault Kubernetes auth
echo ""
echo "[INFO] Step 4: Configuring Vault Kubernetes auth..."
VAULT_CONFIG_RESULT=$(ssh root@10.0.0.150 bash <<VAULT_CONFIG
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

# Enable kubernetes auth if not already enabled
vault auth enable kubernetes 2>&1 | grep -v "path is already in use" || true

# Write CA cert to temp file
cat > /tmp/k8s_ca.crt <<'CAEOF'
${K8S_CA_CERT}
CAEOF

# Configure auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="${SA_TOKEN}" \
    kubernetes_host="https://${K8S_API}" \
    kubernetes_ca_cert=@/tmp/k8s_ca.crt 2>&1

echo "SUCCESS"
VAULT_CONFIG
)

if echo "$VAULT_CONFIG_RESULT" | grep -q "SUCCESS"; then
    echo "[INFO]   ✅ Kubernetes auth configured"
else
    echo "[ERROR]   ❌ Failed to configure Kubernetes auth"
    echo "$VAULT_CONFIG_RESULT"
    exit 1
fi

# Step 5: Create Vault policy
echo ""
echo "[INFO] Step 5: Creating Vault policy..."
ssh root@10.0.0.150 bash <<VAULT_POLICY
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

cat > /tmp/eso-keybuzz-policy.hcl <<'POLICYEOF'
path "kv/keybuzz/*" {
  capabilities = ["read", "list"]
}

path "kv/data/keybuzz/*" {
  capabilities = ["read"]
}

path "mariadb/creds/erpnext-mariadb-role" {
  capabilities = ["read"]
}

path "database/creds/*" {
  capabilities = ["read"]
}
POLICYEOF

vault policy write eso-keybuzz-policy /tmp/eso-keybuzz-policy.hcl 2>&1 | grep -v "already exists" || true
echo "[INFO]   ✅ Policy eso-keybuzz-policy created"
VAULT_POLICY

# Step 6: Create Vault role
echo ""
echo "[INFO] Step 6: Creating Vault role..."
ssh root@10.0.0.150 bash <<VAULT_ROLE
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

vault write auth/kubernetes/role/eso-keybuzz \
    bound_service_account_names=eso-keybuzz-sa \
    bound_service_account_namespaces=keybuzz-system \
    policies=eso-keybuzz-policy \
    ttl=24h 2>&1 | grep -v "already exists" || true

echo "[INFO]   ✅ Role eso-keybuzz created"
VAULT_ROLE

# Step 7: Create namespace and service account
echo ""
echo "[INFO] Step 7: Creating namespace and service account..."
kubectl create namespace keybuzz-system --dry-run=client -o yaml | kubectl apply -f - 2>&1 | grep -v "already exists" || true
kubectl create serviceaccount eso-keybuzz-sa -n keybuzz-system --dry-run=client -o yaml | kubectl apply -f - 2>&1 | grep -v "already exists" || true

# Step 8: Create ClusterSecretStore
echo ""
echo "[INFO] Step 8: Creating ClusterSecretStore..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-keybuzz
spec:
  provider:
    vault:
      server: https://vault.keybuzz.io:8200
      path: kv
      version: v2
      auth:
        kubernetes:
          mountPath: auth/kubernetes
          role: eso-keybuzz
          serviceAccountRef:
            name: eso-keybuzz-sa
            namespace: keybuzz-system
EOF

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ ClusterSecretStore created"
    sleep 5
    kubectl get ClusterSecretStore vault-keybuzz -o yaml | head -30
else
    echo "[ERROR]   ❌ Failed to create ClusterSecretStore"
    exit 1
fi

# Step 9: Create ExternalSecret
echo ""
echo "[INFO] Step 9: Creating ExternalSecret..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-redis-secret
  namespace: keybuzz-system
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-keybuzz
    kind: ClusterSecretStore
  target:
    name: redis-test-secret
  data:
    - secretKey: redis-password
      remoteRef:
        key: kv/keybuzz/redis
        property: password
EOF

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ ExternalSecret created"
else
    echo "[ERROR]   ❌ Failed to create ExternalSecret"
    exit 1
fi

# Step 10: Wait for secret sync
echo ""
echo "[INFO] Step 10: Waiting for ExternalSecret to sync..."
for i in {1..60}; do
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]   ✅ Secret redis-test-secret created"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml | head -20
        break
    fi
    
    # Check ExternalSecret status
    ES_STATUS=$(kubectl get externalsecret test-redis-secret -n keybuzz-system -o jsonpath='{.status.conditions[0].status}' 2>/dev/null || echo "")
    ES_MESSAGE=$(kubectl get externalsecret test-redis-secret -n keybuzz-system -o jsonpath='{.status.conditions[0].message}' 2>/dev/null || echo "")
    
    if [ -n "$ES_STATUS" ]; then
        echo "[INFO]   ExternalSecret status: $ES_STATUS - $ES_MESSAGE"
    fi
    
    echo "[INFO]   Waiting for secret sync... ($i/60)"
    sleep 5
done

# Step 11: Final verification
echo ""
echo "[INFO] Step 11: Final verification..."

# Check Vault auth
VAULT_AUTH_OK=$(ssh root@10.0.0.150 "export VAULT_ADDR='https://127.0.0.1:8200' && export VAULT_SKIP_VERIFY='true' && export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null) && vault read auth/kubernetes/role/eso-keybuzz 2>&1 | grep -q 'bound_service_account_names' && echo 'OK' || echo 'KO'")

# Check ClusterSecretStore
CSS_OK=$(kubectl get ClusterSecretStore vault-keybuzz 2>&1 | grep -q vault-keybuzz && echo 'OK' || echo 'KO')

# Check ExternalSecret
ES_OK=$(kubectl get externalsecret test-redis-secret -n keybuzz-system 2>&1 | grep -q test-redis-secret && echo 'OK' || echo 'KO')

# Check Secret
SECRET_OK=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo 'OK' || echo 'KO')

echo ""
echo "[INFO] =========================================="
echo "[INFO] FINAL SUMMARY"
echo "[INFO] =========================================="
echo "[INFO] Vault auth/kubernetes configuration: $VAULT_AUTH_OK"
echo "[INFO] Vault role eso-keybuzz: $VAULT_AUTH_OK"
echo "[INFO] Vault policy eso-keybuzz-policy: OK"
echo "[INFO] ClusterSecretStore vault-keybuzz: $CSS_OK"
echo "[INFO] ExternalSecret test-redis-secret: $ES_OK"
echo "[INFO] Kubernetes Secret redis-test-secret: $SECRET_OK"
echo "[INFO] =========================================="
echo ""

# Show ExternalSecret status if exists
if [ "$ES_OK" = "OK" ]; then
    echo "[INFO] ExternalSecret status:"
    kubectl get externalsecret test-redis-secret -n keybuzz-system -o yaml | grep -A 20 "status:" | head -25
    echo ""
fi

# Show Secret if exists
if [ "$SECRET_OK" = "OK" ]; then
    echo "[INFO] Secret details:"
    kubectl get secret redis-test-secret -n keybuzz-system -o yaml | head -20
    echo ""
fi

echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-FINALIZE-VAULT-ESO-COMPLETE Finished"
echo "[INFO] =========================================="
echo ""

