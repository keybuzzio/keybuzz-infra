#!/bin/bash
set -euo pipefail
NS="keybuzz-api-dev"

echo "=== PH115 KILL SWITCH TEST ==="
echo ""

echo "--- BEFORE: Status with execution enabled ---"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "POD=$POD"

kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('enabled=' + j.enabled + ' liveMode=' + j.liveMode + ' safeMode=' + j.safeMode);
  });
});
"

echo ""
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=killswitch-test', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('BEFORE: mode=' + j.executionMode + ' real=' + j.isRealExecution + ' blocked=' + j.blockedReason);
  });
});
"

echo ""
echo "--- KILL SWITCH: Disabling AI_REAL_EXECUTION_ENABLED ---"
kubectl set env deploy/keybuzz-api -n "$NS" AI_REAL_EXECUTION_ENABLED=false
echo "Waiting for rollout..."
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
sleep 10

echo ""
echo "--- AFTER KILL SWITCH: Verify DRY_RUN ---"
POD2=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "NEW POD=$POD2"

kubectl exec -n "$NS" "$POD2" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('enabled=' + j.enabled + ' liveMode=' + j.liveMode + ' safeMode=' + j.safeMode);
  });
});
"

echo ""
kubectl exec -n "$NS" "$POD2" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=killswitch-test-2', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('AFTER: mode=' + j.executionMode + ' real=' + j.isRealExecution + ' blocked=' + j.blockedReason);
  });
});
"

echo ""
echo "--- RE-ENABLE: Restoring AI_REAL_EXECUTION_ENABLED=true ---"
kubectl set env deploy/keybuzz-api -n "$NS" AI_REAL_EXECUTION_ENABLED=true
echo "Waiting for rollout..."
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
sleep 10

echo ""
echo "--- RESTORED: Verify execution re-enabled ---"
POD3=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "RESTORED POD=$POD3"

kubectl exec -n "$NS" "$POD3" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('enabled=' + j.enabled + ' liveMode=' + j.liveMode + ' safeMode=' + j.safeMode);
  });
});
"

echo ""
kubectl exec -n "$NS" "$POD3" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=killswitch-test-3', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => {
    const j = JSON.parse(d);
    console.log('RESTORED: mode=' + j.executionMode + ' real=' + j.isRealExecution + ' blocked=' + j.blockedReason);
  });
});
"

echo ""
echo "=== KILL SWITCH TEST COMPLETE ==="
