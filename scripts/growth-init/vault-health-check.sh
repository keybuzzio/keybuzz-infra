#!/bin/bash
set -e

echo "=== Health checks via kubectl exec ==="

echo "--- Studio API DEV ---"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- wget -q -O - http://localhost:4010/health 2>/dev/null && echo "" || echo "FAIL (wget not available, trying curl)"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- curl -sf http://localhost:4010/health 2>/dev/null && echo "" || echo "Trying node..."
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- node -e "fetch('http://localhost:4010/health').then(r=>r.text()).then(t=>console.log('STATUS:',t)).catch(e=>console.log('ERR:',e.message))" 2>/dev/null || echo "FAIL"

echo ""
echo "--- Studio API PROD ---"
kubectl exec -n keybuzz-studio-api-prod deploy/keybuzz-studio-api -- node -e "fetch('http://localhost:4010/health').then(r=>r.text()).then(t=>console.log('STATUS:',t)).catch(e=>console.log('ERR:',e.message))" 2>/dev/null || echo "FAIL"

echo ""
echo "--- Main API PROD via kubectl exec ---"
kubectl exec -n keybuzz-api-prod deploy/keybuzz-api -- node -e "fetch('http://localhost:3000/api/health').then(r=>r.text()).then(t=>console.log('STATUS:',t)).catch(e=>console.log('ERR:',e.message))" 2>/dev/null || echo "FAIL"

echo ""
echo "--- Backend PROD via kubectl exec ---"
kubectl exec -n keybuzz-backend-prod deploy/keybuzz-backend -- node -e "fetch('http://localhost:3001/api/health').then(r=>r.text()).then(t=>console.log('STATUS:',t)).catch(e=>console.log('ERR:',e.message))" 2>/dev/null || echo "FAIL"

echo ""
echo "--- Vault token TTLs via temporary pod ---"
VAULT_ADDR="http://vault.default.svc.cluster.local:8200"
TOKEN1=$(kubectl get secret vault-root-token -n keybuzz-api-prod -o jsonpath='{.data.VAULT_TOKEN}' | base64 -d)
TOKEN2=$(kubectl get secret vault-app-token -n keybuzz-backend-prod -o jsonpath='{.data.token}' | base64 -d)

echo "TOKEN1 length: ${#TOKEN1}"
echo "TOKEN2 length: ${#TOKEN2}"

kubectl run vault-ttl-check --rm -i --restart=Never --image=curlimages/curl:8.7.1 --timeout=30s -- sh -c "
  echo 'TOKEN1 TTL:'
  curl -sf -H 'X-Vault-Token: $TOKEN1' '$VAULT_ADDR/v1/auth/token/lookup-self' | grep -o '\"ttl\":[0-9]*'
  echo ''
  echo 'TOKEN2 TTL:'
  curl -sf -H 'X-Vault-Token: $TOKEN2' '$VAULT_ADDR/v1/auth/token/lookup-self' | grep -o '\"ttl\":[0-9]*'
" 2>/dev/null || echo "TTL check via pod failed"

echo ""
echo "--- Cleanup ---"
kubectl delete job vault-renew-compat-test-1775854129 -n vault-management 2>/dev/null || true

echo "=== DONE ==="
