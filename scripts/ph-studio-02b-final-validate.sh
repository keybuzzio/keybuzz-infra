#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  PH-STUDIO-02B — FINAL VALIDATION"
echo "=========================================="

echo ""
echo "=== 1. Pods ==="
kubectl get pods -n keybuzz-studio-dev
echo ""
kubectl get pods -n keybuzz-studio-api-dev | grep -v solver

echo ""
echo "=== 2. API /health ==="
kubectl run v-health --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "=== 3. API /ready (DB connection) ==="
kubectl run v-ready --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "=== 4. Frontend HTTPS ==="
kubectl run v-fe --namespace=keybuzz-studio-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 10 https://studio-dev.keybuzz.io 2>&1 | grep -E "^HTTP|content-type|server" | head -5

echo ""
echo "=== 5. Certificates ==="
kubectl get certificate -A | grep studio

echo ""
echo "=== 6. Logs API (last 8) ==="
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=8 2>&1

echo ""
echo "=== 7. Logs Frontend (last 5) ==="
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=5 2>&1

echo ""
echo "=== 8. Restarts ==="
kubectl get pods -n keybuzz-studio-dev -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}'
kubectl get pods -n keybuzz-studio-api-dev -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}'

echo ""
echo "=== 9. DB tables in keybuzz_studio ==="
export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")
STUDIO_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/studio-postgres 2>/dev/null || echo "")
if [ -n "$STUDIO_PASS" ]; then
  PGPASSWORD="$STUDIO_PASS" psql -h 10.0.0.10 -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) || ' tables' FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null
  PGPASSWORD="$STUDIO_PASS" psql -h 10.0.0.10 -U kb_studio -d keybuzz_studio -t -A -c "SELECT current_database();" 2>/dev/null
else
  echo "Cannot retrieve studio credentials"
fi

echo ""
echo "=== 10. DNS status ==="
dig +short studio-dev.keybuzz.io 2>/dev/null | head -2
echo "studio-api-dev:"
dig +short studio-api-dev.keybuzz.io 2>/dev/null || echo "(no A record)"

echo ""
echo "=========================================="
echo "  VALIDATION COMPLETE"
echo "=========================================="
