#!/bin/bash
# PH9-06 - Test External Secrets Operator with Vault
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-06-test-eso.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-06 - Test External Secrets Operator"
echo "[INFO] =========================================="
echo ""

# Verify ClusterSecretStore exists
echo "[INFO] Step 1: Verifying ClusterSecretStore..."
if kubectl get clustersecretstore vault-keybuzz &>/dev/null; then
    echo "[INFO]   ✅ ClusterSecretStore vault-keybuzz exists"
    kubectl get clustersecretstore vault-keybuzz -o yaml | head -20
else
    echo "[ERROR]   ❌ ClusterSecretStore vault-keybuzz not found"
    exit 1
fi

# Create test ExternalSecret
echo ""
echo "[INFO] Step 2: Creating test ExternalSecret..."
kubectl apply -f k8s/tests/test-redis-externalsecret.yaml

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Test ExternalSecret applied"
else
    echo "[ERROR]   ❌ Failed to apply test ExternalSecret"
    exit 1
fi

# Wait for ExternalSecret to sync
echo ""
echo "[INFO] Step 3: Waiting for ExternalSecret to sync..."
for i in {1..30}; do
    STATUS=$(kubectl get externalsecret test-redis-secret -n keybuzz-system -o jsonpath='{.status.conditions[0].status}' 2>/dev/null || echo "Unknown")
    echo "[INFO]   ExternalSecret status: ${STATUS}"
    if [ "$STATUS" = "True" ]; then
        echo "[INFO]   ✅ ExternalSecret synced successfully"
        break
    fi
    sleep 5
done

# Verify secret was created
echo ""
echo "[INFO] Step 4: Verifying secret was created..."
if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
    echo "[INFO]   ✅ Secret redis-test-secret created"
    kubectl get secret redis-test-secret -n keybuzz-system -o yaml | grep -A 5 "data:"
    
    # Check if redis-password key exists
    if kubectl get secret redis-test-secret -n keybuzz-system -o jsonpath='{.data.redis-password}' &>/dev/null; then
        echo "[INFO]   ✅ redis-password key exists in secret"
    else
        echo "[WARN]   ⚠️  redis-password key not found (may be expected if Vault secret doesn't exist)"
    fi
else
    echo "[ERROR]   ❌ Secret redis-test-secret not found"
    exit 1
fi

# Display ExternalSecret details
echo ""
echo "[INFO] Step 5: ExternalSecret details..."
kubectl get externalsecret test-redis-secret -n keybuzz-system -o yaml | head -40

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-06 ESO Test Complete"
echo "[INFO] =========================================="
echo ""

