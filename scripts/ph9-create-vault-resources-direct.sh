#!/bin/bash
# PH9-CREATE-VAULT-RESOURCES-DIRECT - Create Vault resources directly via API
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-create-vault-resources-direct.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-CREATE-VAULT-RESOURCES-DIRECT"
echo "[INFO] =========================================="
echo ""

# Step 1: Verify Vault auth is configured
echo "[INFO] Step 1: Verifying Vault auth configuration..."
VAULT_AUTH_CHECK=$(ssh root@10.0.0.150 "export VAULT_ADDR='https://127.0.0.1:8200' && export VAULT_SKIP_VERIFY='true' && export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null) && vault read auth/kubernetes/role/eso-keybuzz 2>&1" | grep -q "bound_service_account_names" && echo "OK" || echo "KO")
echo "[INFO]   Vault auth check: $VAULT_AUTH_CHECK"

# Step 2: Create ClusterSecretStore using kubectl with explicit API version
echo ""
echo "[INFO] Step 2: Creating ClusterSecretStore..."
cat <<EOF | kubectl apply --server-side --force-conflicts -f -
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
    # Try alternative method
    echo "[INFO]   Trying alternative method..."
    kubectl create -f - <<EOF
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
fi

# Step 3: Verify ClusterSecretStore
echo ""
echo "[INFO] Step 3: Verifying ClusterSecretStore..."
kubectl get ClusterSecretStore vault-keybuzz 2>&1 | head -5

# Step 4: Create ExternalSecret
echo ""
echo "[INFO] Step 4: Creating ExternalSecret..."
cat <<EOF | kubectl apply --server-side --force-conflicts -f -
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
    # Try alternative method
    kubectl create -f - <<EOF
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
fi

# Step 5: Wait for secret sync
echo ""
echo "[INFO] Step 5: Waiting for ExternalSecret to sync..."
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

# Step 6: Final verification
echo ""
echo "[INFO] Step 6: Final verification..."

CSS_OK=$(kubectl get ClusterSecretStore vault-keybuzz 2>&1 | grep -q vault-keybuzz && echo 'OK' || echo 'KO')
ES_OK=$(kubectl get externalsecret test-redis-secret -n keybuzz-system 2>&1 | grep -q test-redis-secret && echo 'OK' || echo 'KO')
SECRET_OK=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo 'OK' || echo 'KO')

echo ""
echo "[INFO] =========================================="
echo "[INFO] FINAL SUMMARY"
echo "[INFO] =========================================="
echo "[INFO] ClusterSecretStore vault-keybuzz: $CSS_OK"
echo "[INFO] ExternalSecret test-redis-secret: $ES_OK"
echo "[INFO] Kubernetes Secret redis-test-secret: $SECRET_OK"
echo "[INFO] =========================================="
echo ""

if [ "$SECRET_OK" = "OK" ]; then
    echo "[INFO] Secret details:"
    kubectl get secret redis-test-secret -n keybuzz-system -o yaml | head -20
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-CREATE-VAULT-RESOURCES-DIRECT Finished"
echo "[INFO] =========================================="
echo ""

