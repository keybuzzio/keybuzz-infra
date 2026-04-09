#!/usr/bin/env bash
set -euo pipefail

echo "--- PROD API Logs ---"
API_POD=$(kubectl get pods -n keybuzz-studio-api-prod -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $API_POD"
kubectl logs --tail=30 -n keybuzz-studio-api-prod "$API_POD" 2>&1 | tail -20

echo ""
echo "--- PROD Frontend baked URL ---"
FE_POD=$(kubectl get pods -n keybuzz-studio-prod -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-studio-prod "$FE_POD" -- grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u

echo ""
echo "--- Direct OTP test ---"
curl -sv -X POST https://studio-api.keybuzz.io/api/v1/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}' 2>&1 | tail -10
