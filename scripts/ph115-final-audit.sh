#!/bin/bash
set -euo pipefail
NS="keybuzz-api-dev"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "=== PH115 FINAL AUDIT ==="
echo "POD=$POD"

echo ""
echo "--- Execution audit: all entries today ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT action_name, connector_name, effective_mode, execution_result,
           blocked_reason, dry_run, conversation_id, created_at
    FROM ai_execution_attempt_log
    WHERE tenant_id = 'ecomlg-001'
      AND created_at >= CURRENT_DATE
    ORDER BY created_at DESC
  \`);
  console.log('Total entries today: ' + r.rows.length);
  console.log('Real executions (dry_run=false): ' + r.rows.filter(x => !x.dry_run).length);
  console.log('Blocked: ' + r.rows.filter(x => x.blocked_reason).length);
  console.log('');
  for (const row of r.rows) {
    console.log(row.created_at.toISOString().substr(11,8) + ' | ' +
      row.action_name.padEnd(25) + ' | ' +
      row.effective_mode.padEnd(25) + ' | ' +
      row.execution_result.padEnd(25) + ' | ' +
      'dry=' + row.dry_run + ' | ' +
      (row.blocked_reason || '-'));
  }
  await p.end();
})();
"

echo ""
echo "--- Conversation detail: cmmmxgixed103a49965e8964b ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT c.id, c.status, c.channel, c.subject,
           (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id::text) as msg_count,
           (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id::text AND m.direction = 'outbound') as outbound_count
    FROM conversations c
    WHERE c.id = 'cmmmxgixed103a49965e8964b'
  \`);
  console.log(JSON.stringify(r.rows[0], null, 2));
  await p.end();
})();
"

echo ""
echo "--- Last outbound message for this conversation ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  const r = await p.query(\`
    SELECT id, direction, created_at, body
    FROM messages
    WHERE conversation_id = 'cmmmxgixed103a49965e8964b'
    ORDER BY created_at DESC
    LIMIT 3
  \`);
  for (const row of r.rows) {
    console.log(row.direction + ' | ' + row.created_at + ' | ' + (row.body || '').substring(0, 120));
  }
  await p.end();
})();
"

echo ""
echo "=== FINAL AUDIT COMPLETE ==="
