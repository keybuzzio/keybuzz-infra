#!/bin/bash
# PH9-FINALIZE-VAULT-ESO - Finalize Vault and ESO configuration
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-finalize-vault-eso.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-FINALIZE-VAULT-ESO"
echo "[INFO] =========================================="
echo ""

# Step 1: Get Kubernetes API info
echo "[INFO] Step 1: Getting Kubernetes API info..."
K8S_API=$(kubectl cluster-info 2>/dev/null | grep "Kubernetes control plane" | awk '{print $NF}' | sed 's|https://||' || echo "10.0.0.100:6443")
K8S_CA_CERT=$(kubectl get secret -n kube-system $(kubectl get sa default -n kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)
SA_TOKEN=$(kubectl get secret -n kube-system $(kubectl get sa vault-auth -n kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)

echo "[INFO]   K8S API: $K8S_API"
echo "[INFO]   CA Cert length: ${#K8S_CA_CERT}"
echo "[INFO]   SA Token length: ${#SA_TOKEN}"

# Step 2: Configure Vault Kubernetes auth
echo ""
echo "[INFO] Step 2: Configuring Vault Kubernetes auth..."
ssh root@10.0.0.150 bash <<VAULT_CONFIG
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

# Write config with CA cert from stdin
echo '${K8S_CA_CERT}' | vault write auth/kubernetes/config \
    token_reviewer_jwt="${SA_TOKEN}" \
    kubernetes_host="https://${K8S_API}" \
    kubernetes_ca_cert=@- 2>&1

echo "[INFO]   ✅ Kubernetes auth configured"
VAULT_CONFIG

# Step 3: Create Vault policy
echo ""
echo "[INFO] Step 3: Creating Vault policy..."
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

vault policy write eso-keybuzz-policy /tmp/eso-keybuzz-policy.hcl 2>&1
echo "[INFO]   ✅ Policy eso-keybuzz-policy created"
VAULT_POLICY

# Step 4: Create Vault role
echo ""
echo "[INFO] Step 4: Creating Vault role..."
ssh root@10.0.0.150 bash <<VAULT_ROLE
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

vault write auth/kubernetes/role/eso-keybuzz \
    bound_service_account_names=eso-keybuzz-sa \
    bound_service_account_namespaces=keybuzz-system \
    policies=eso-keybuzz-policy \
    ttl=24h 2>&1

echo "[INFO]   ✅ Role eso-keybuzz created"
VAULT_ROLE

# Step 5: Verify CRDs
echo ""
echo "[INFO] Step 5: Verifying ESO CRDs..."
kubectl get crd | grep externalsecret || echo "[WARN] CRDs not found"

# Step 6: Create ClusterSecretStore
echo ""
echo "[INFO] Step 6: Creating ClusterSecretStore..."
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
    kubectl get ClusterSecretStore vault-keybuzz -o yaml | head -30
else
    echo "[ERROR]   ❌ Failed to create ClusterSecretStore"
    exit 1
fi

# Step 7: Create ExternalSecret
echo ""
echo "[INFO] Step 7: Creating ExternalSecret..."
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

# Step 8: Wait for secret sync
echo ""
echo "[INFO] Step 8: Waiting for ExternalSecret to sync..."
sleep 10

for i in {1..30}; do
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]   ✅ Secret redis-test-secret created"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml | head -20
        break
    fi
    echo "[INFO]   Waiting for secret sync... ($i/30)"
    sleep 5
done

# Step 9: Check ExternalSecret status
echo ""
echo "[INFO] Step 9: Checking ExternalSecret status..."
kubectl get externalsecret test-redis-secret -n keybuzz-system -o yaml | grep -A 10 "status:" || echo "[WARN] Status not available"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-FINALIZE-VAULT-ESO Complete"
echo "[INFO] =========================================="
echo ""

