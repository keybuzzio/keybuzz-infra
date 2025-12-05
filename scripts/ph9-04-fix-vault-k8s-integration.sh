#!/bin/bash
# PH9-04-FIX - Fix Vault Kubernetes Integration
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-reset/ph9-04-fix-vault-k8s-integration.log"
mkdir -p /opt/keybuzz/logs/phase9-reset/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-04-FIX - Vault Kubernetes Integration"
echo "[INFO] =========================================="
echo ""

# Step 1: Enable Kubernetes auth in Vault (if not already enabled)
echo "[INFO] Step 1: Enabling Kubernetes auth in Vault..."
ssh root@10.0.0.150 bash <<VAULT_AUTH
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

# Enable Kubernetes auth
vault auth enable kubernetes 2>&1 || echo "Kubernetes auth may already be enabled"
VAULT_AUTH

# Step 2: Get Kubernetes API server info from install-v3
echo "[INFO] Step 2: Getting Kubernetes API server info..."
K8S_API=$(kubectl cluster-info | grep "Kubernetes control plane" | awk '{print $NF}' | sed 's|https://||' || echo "10.0.0.100:6443")
K8S_CA_CERT=$(kubectl get secret -n kube-system $(kubectl get sa default -n kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)

# Step 3: Create service account for Vault
echo "[INFO] Step 3: Creating service account for Vault..."
kubectl create serviceaccount vault-auth -n kube-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create clusterrolebinding vault-auth-binding \
    --clusterrole=system:auth-delegator \
    --serviceaccount=kube-system:vault-auth \
    --dry-run=client -o yaml | kubectl apply -f -

# Get service account token
SA_TOKEN=$(kubectl get secret -n kube-system $(kubectl get sa vault-auth -n kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)

# Step 4: Configure Vault Kubernetes auth
echo "[INFO] Step 4: Configuring Vault Kubernetes auth..."
ssh root@10.0.0.150 bash <<VAULT_CONFIG
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

vault write auth/kubernetes/config \\
    token_reviewer_jwt="${SA_TOKEN}" \\
    kubernetes_host="https://${K8S_API}" \\
    kubernetes_ca_cert="${K8S_CA_CERT}" 2>&1

echo "[INFO]   ✅ Kubernetes auth configured"
VAULT_CONFIG

# Step 5: Create Vault policy for ESO
echo ""
echo "[INFO] Step 5: Creating Vault policy for ESO..."

ssh root@10.0.0.150 bash <<VAULT_POLICY
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

# Create policy for ESO
cat <<EOF > /tmp/eso-keybuzz-policy.hcl
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
EOF

vault policy write eso-keybuzz-policy /tmp/eso-keybuzz-policy.hcl 2>&1
echo "[INFO]   ✅ Policy eso-keybuzz-policy created"
VAULT_POLICY

# Step 6: Create Vault role for ESO
echo ""
echo "[INFO] Step 6: Creating Vault role for ESO..."

ssh root@10.0.0.150 bash <<VAULT_ROLE
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

vault write auth/kubernetes/role/eso-keybuzz \\
    bound_service_account_names=eso-keybuzz-sa \\
    bound_service_account_namespaces=keybuzz-system \\
    policies=eso-keybuzz-policy \\
    ttl=24h 2>&1

echo "[INFO]   ✅ Role eso-keybuzz created"
VAULT_ROLE

# Step 7: Create ClusterSecretStore
echo ""
echo "[INFO] Step 7: Creating ClusterSecretStore..."

cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-keybuzz
spec:
  provider:
    vault:
      server: "https://vault.keybuzz.io:8200"
      path: "kv"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "auth/kubernetes"
          role: "eso-keybuzz"
          serviceAccountRef:
            name: eso-keybuzz-sa
            namespace: keybuzz-system
EOF

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ ClusterSecretStore created"
else
    echo "[ERROR]   ❌ Failed to create ClusterSecretStore"
    exit 1
fi

# Verify ClusterSecretStore
echo ""
echo "[INFO] Step 8: Verifying ClusterSecretStore..."
kubectl get clustersecretstore vault-keybuzz -o yaml | head -30

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-04-FIX Vault Kubernetes Integration Complete"
echo "[INFO] =========================================="
echo ""

