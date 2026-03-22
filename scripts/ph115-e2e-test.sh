#!/bin/bash
set -euo pipefail
NS="keybuzz-api-dev"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "=== PH115 E2E TEST ==="
echo "POD=$POD"
echo ""

echo "=== STEP 1: Find latest Amazon conversation ==="
kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT c.id, c.tenant_id, c.status, c.channel,
           c.subject, c.created_at
    FROM conversations c
    WHERE c.tenant_id = 'ecomlg-001'
      AND c.channel LIKE '%amazon%'
    ORDER BY c.created_at DESC
    LIMIT 5
  \`);
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== STEP 2: Pick conversation and test AI chain ==="
CONV_ID=$(kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT c.id
    FROM conversations c
    WHERE c.tenant_id = 'ecomlg-001'
      AND c.channel LIKE '%amazon%'
      AND c.status != 'resolved'
    ORDER BY c.created_at DESC
    LIMIT 1
  \`);
  if (r.rows.length > 0) console.log(r.rows[0].id);
  else console.log('NONE');
  await p.end();
})();
" 2>&1 | tail -1)
echo "Selected conversation: $CONV_ID"

if [ "$CONV_ID" = "NONE" ]; then
  echo "No open Amazon conversation found. Trying latest regardless of status..."
  CONV_ID=$(kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT c.id
    FROM conversations c
    WHERE c.tenant_id = 'ecomlg-001'
      AND c.channel LIKE '%amazon%'
    ORDER BY c.created_at DESC
    LIMIT 1
  \`);
  console.log(r.rows[0]?.id || 'NONE');
  await p.end();
})();
" 2>&1 | tail -1)
  echo "Using conversation: $CONV_ID"
fi

echo ""
echo "=== STEP 3: AI Pipeline Chain ==="
for EP in \
  "/ai/strategic-resolution?tenantId=ecomlg-001&conversationId=$CONV_ID" \
  "/ai/autonomous-ops?tenantId=ecomlg-001&conversationId=$CONV_ID" \
  "/ai/action-dispatcher?tenantId=ecomlg-001&conversationId=$CONV_ID" \
  "/ai/connector-abstraction?tenantId=ecomlg-001&conversationId=$CONV_ID" \
  "/ai/case-manager?tenantId=ecomlg-001&conversationId=$CONV_ID" \
  "/ai/safe-execution?tenantId=ecomlg-001&conversationId=$CONV_ID"; do
  EP_NAME=$(echo "$EP" | cut -d'?' -f1)
  echo ">> $EP_NAME"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001${EP}', {headers:{'x-user-email':'ludo.gonthier@gmail.com'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    const summary = {};
    if (j.recommendedStrategy) summary.strategy = j.recommendedStrategy;
    if (j.executionMode !== undefined) summary.executionMode = j.executionMode;
    if (j.isRealExecution !== undefined) summary.isRealExecution = j.isRealExecution;
    if (j.safetyChecksPassed !== undefined) summary.safetyChecksPassed = j.safetyChecksPassed;
    if (j.blockedReason !== undefined) summary.blockedReason = j.blockedReason;
    if (j.action !== undefined) summary.action = j.action;
    if (j.connector !== undefined) summary.connector = j.connector;
    if (j.strategy !== undefined) summary.strategy = j.strategy;
    if (j.caseState !== undefined) summary.caseState = j.caseState;
    if (j.stage !== undefined) summary.stage = j.stage;
    console.log(r.statusCode, JSON.stringify(summary));
  });
}).on('error', e => console.log('ERR', e.message));
" 2>&1
done

echo ""
echo "=== STEP 4: PH115 Activation Status ==="
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'ludo.gonthier@gmail.com'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
"

echo ""
echo "=== STEP 5: Execution audit log ==="
kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT id, tenant_id, conversation_id, action_name, connector_name,
           requested_mode, effective_mode, execution_result, blocked_reason,
           dry_run, created_at
    FROM ai_execution_attempt_log
    WHERE tenant_id = 'ecomlg-001'
    ORDER BY created_at DESC
    LIMIT 5
  \`);
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== PH115 E2E TEST COMPLETE ==="
