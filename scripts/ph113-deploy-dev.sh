#!/bin/bash
set -euo pipefail

echo "=== PH113: Safe Real Connector Activation — DEV Deploy ==="
echo "Date: $(date)"

API_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-dev"
NAMESPACE="keybuzz-api-dev"
DEPLOYMENT="keybuzz-api"

# Step 1: Build API
echo ""
echo "--- STEP 1: Build API ---"
cd /opt/keybuzz/keybuzz-api
docker build --no-cache -t "$API_TAG" .
echo "Build OK: $API_TAG"

# Step 2: Push
echo ""
echo "--- STEP 2: Push image ---"
docker push "$API_TAG"
echo "Push OK"

# Step 3: Deploy
echo ""
echo "--- STEP 3: Deploy to DEV ---"
kubectl set image "deploy/$DEPLOYMENT" "$DEPLOYMENT=$API_TAG" -n "$NAMESPACE"
kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s
echo "Deploy OK"

# Step 4: Wait for pod ready
echo ""
echo "--- STEP 4: Wait for pod ---"
sleep 15
POD=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD" ]; then
  echo "ERROR: No pod found"
  exit 1
fi
echo "Pod: $POD"
kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" --no-headers

# Step 5: Create activation policy for ecomlg-001
echo ""
echo "--- STEP 5: Create PH113 activation policy ---"
kubectl exec -n "$NAMESPACE" "$POD" -- node -e "
const { Pool } = require('pg');
(async () => {
  const pool = new Pool();
  try {
    await pool.query(\`
      CREATE TABLE IF NOT EXISTS ai_activation_policy (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id TEXT NOT NULL,
        connector_name TEXT NOT NULL,
        action_name TEXT NOT NULL,
        activation_mode TEXT NOT NULL DEFAULT 'DRY_RUN_ONLY',
        is_enabled BOOLEAN NOT NULL DEFAULT false,
        rollout_stage TEXT NOT NULL DEFAULT 'NONE',
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        UNIQUE (tenant_id, connector_name, action_name)
      )
    \`);
    await pool.query(\`
      INSERT INTO ai_activation_policy (tenant_id, connector_name, action_name, activation_mode, is_enabled, rollout_stage, notes)
      VALUES ('ecomlg-001', 'customer_interaction_connector', 'REQUEST_INFORMATION', 'REAL_WITH_HUMAN_REVIEW', true, 'INTERNAL_TEST', 'PH113: First safe real connector activation')
      ON CONFLICT (tenant_id, connector_name, action_name)
      DO UPDATE SET activation_mode = 'REAL_WITH_HUMAN_REVIEW', is_enabled = true, rollout_stage = 'INTERNAL_TEST', notes = 'PH113: First safe real connector activation', updated_at = NOW()
    \`);
    const res = await pool.query('SELECT * FROM ai_activation_policy WHERE tenant_id = \$1', ['ecomlg-001']);
    console.log('Policy created:', JSON.stringify(res.rows, null, 2));
  } catch (e) { console.error('Policy error:', e.message); }
  await pool.end();
})();
" 2>&1 || echo "WARN: Policy creation may need retry"

# Step 6: Verify endpoints
echo ""
echo "--- STEP 6: Verify endpoints ---"
kubectl exec -n "$NAMESPACE" "$POD" -- node -e "
const http = require('http');
const tests = [
  { name: 'health', path: '/health', headers: {} },
  { name: 'PH113-status', path: '/ai/real-execution-status?tenantId=ecomlg-001', headers: { 'x-user-email': 'ludo.gonthier@gmail.com' } },
  { name: 'PH113-safe-exec', path: '/ai/safe-execution?tenantId=ecomlg-001&channel=amazon', headers: { 'x-user-email': 'ludo.gonthier@gmail.com' } },
  { name: 'PH111-activation', path: '/ai/controlled-activation?tenantId=ecomlg-001', headers: { 'x-user-email': 'ludo.gonthier@gmail.com' } },
  { name: 'PH110-execution', path: '/ai/controlled-execution?tenantId=ecomlg-001', headers: { 'x-user-email': 'ludo.gonthier@gmail.com' } },
  { name: 'PH100-governance', path: '/ai/governance?tenantId=ecomlg-001', headers: { 'x-user-email': 'ludo.gonthier@gmail.com' } },
];

let pass = 0, fail = 0;
function check(t) {
  return new Promise((resolve) => {
    const opts = { hostname: '127.0.0.1', port: 3001, path: t.path, method: 'GET', headers: t.headers, timeout: 10000 };
    const req = http.request(opts, (res) => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => {
        const ok = res.statusCode >= 200 && res.statusCode < 400;
        console.log(ok ? 'PASS' : 'FAIL', t.name, res.statusCode, body.substring(0, 200));
        ok ? pass++ : fail++;
        resolve();
      });
    });
    req.on('error', e => { console.log('FAIL', t.name, e.message); fail++; resolve(); });
    req.on('timeout', () => { req.destroy(); console.log('FAIL', t.name, 'timeout'); fail++; resolve(); });
    req.end();
  });
}
(async () => {
  for (const t of tests) await check(t);
  console.log('---');
  console.log('Results:', pass, 'PASS /', fail, 'FAIL');
  if (fail > 0) process.exit(1);
})();
" 2>&1

echo ""
echo "=== PH113 DEV Deploy Complete ==="
echo "Image: $API_TAG"
echo "Rollback: kubectl set image deploy/$DEPLOYMENT $DEPLOYMENT=ghcr.io/keybuzzio/keybuzz-api:v3.6.14-ph112-ai-control-center-dev -n $NAMESPACE"
