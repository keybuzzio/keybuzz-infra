#!/bin/bash
set -e

log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $1"; }

log "=== VAULT ROTATION COMPATIBILITY TEST ==="
log ""

log "--- STEP 1: Pre-rotation state — all pods ==="
echo "STUDIO API DEV:"
kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o wide --no-headers 2>/dev/null || echo "  (none)"
echo "STUDIO API PROD:"
kubectl get pods -n keybuzz-studio-api-prod -l app=keybuzz-studio-api -o wide --no-headers 2>/dev/null || echo "  (none)"
echo "STUDIO FRONTEND DEV:"
kubectl get pods -n keybuzz-studio-dev --no-headers 2>/dev/null || echo "  (none)"
echo "STUDIO FRONTEND PROD:"
kubectl get pods -n keybuzz-studio-prod --no-headers 2>/dev/null || echo "  (none)"
echo "MAIN API PROD:"
kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o wide --no-headers 2>/dev/null || echo "  (none)"
echo "BACKEND PROD:"
kubectl get pods -n keybuzz-backend-prod -l app=keybuzz-backend -o wide --no-headers 2>/dev/null || echo "  (none)"
echo "WEBSITE PROD:"
kubectl get pods -n keybuzz-website-prod --no-headers 2>/dev/null || echo "  (none)"

log ""
log "--- STEP 2: Record Studio pod UIDs (pre-rotation) ==="
STUDIO_DEV_UID=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null || echo "none")
STUDIO_PROD_UID=$(kubectl get pods -n keybuzz-studio-api-prod -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null || echo "none")
log "Studio API DEV pod UID: $STUDIO_DEV_UID"
log "Studio API PROD pod UID: $STUDIO_PROD_UID"

log ""
log "--- STEP 3: Trigger CronJob manual run ==="
JOB_NAME="vault-renew-compat-test-$(date +%s)"
kubectl create job --from=cronjob/vault-token-renew "$JOB_NAME" -n vault-management 2>&1
log "Job created: $JOB_NAME"

log ""
log "--- STEP 4: Wait for job completion ==="
for i in $(seq 1 30); do
    STATUS=$(kubectl get job "$JOB_NAME" -n vault-management -o jsonpath='{.status.conditions[0].type}' 2>/dev/null || true)
    if [ "$STATUS" = "Complete" ] || [ "$STATUS" = "Failed" ]; then
        break
    fi
    sleep 2
done
log "Job status: $STATUS"

log ""
log "--- STEP 5: CronJob logs ==="
POD_NAME=$(kubectl get pods -n vault-management -l job-name="$JOB_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl logs "$POD_NAME" -n vault-management 2>/dev/null || echo "(no logs)"

log ""
log "--- STEP 6: Post-rotation — verify Studio pods NOT restarted ==="
STUDIO_DEV_UID_AFTER=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null || echo "none")
STUDIO_PROD_UID_AFTER=$(kubectl get pods -n keybuzz-studio-api-prod -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.uid}' 2>/dev/null || echo "none")
log "Studio API DEV — before=$STUDIO_DEV_UID after=$STUDIO_DEV_UID_AFTER"
log "Studio API PROD — before=$STUDIO_PROD_UID after=$STUDIO_PROD_UID_AFTER"

if [ "$STUDIO_DEV_UID" = "$STUDIO_DEV_UID_AFTER" ]; then
    log "OK: Studio DEV pod NOT restarted (expected)"
else
    log "WARNING: Studio DEV pod WAS restarted!"
fi

if [ "$STUDIO_PROD_UID" = "$STUDIO_PROD_UID_AFTER" ]; then
    log "OK: Studio PROD pod NOT restarted (expected)"
else
    log "WARNING: Studio PROD pod WAS restarted!"
fi

log ""
log "--- STEP 7: Verify all services respond ==="
STUDIO_DEV_SVC=$(kubectl get svc -n keybuzz-studio-api-dev -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "none")
if [ "$STUDIO_DEV_SVC" != "none" ]; then
    STUDIO_DEV_IP=$(kubectl get svc "$STUDIO_DEV_SVC" -n keybuzz-studio-api-dev -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "none")
    STUDIO_DEV_PORT=$(kubectl get svc "$STUDIO_DEV_SVC" -n keybuzz-studio-api-dev -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "none")
    STUDIO_HEALTH=$(curl -sf -o /dev/null -w '%{http_code}' "http://${STUDIO_DEV_IP}:${STUDIO_DEV_PORT}/health" 2>/dev/null || echo "FAIL")
    log "Studio API DEV /health: $STUDIO_HEALTH"
fi

API_PROD_SVC=$(kubectl get svc keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "none")
if [ "$API_PROD_SVC" != "none" ]; then
    API_HEALTH=$(curl -sf -o /dev/null -w '%{http_code}' "http://${API_PROD_SVC}:3000/api/health" 2>/dev/null || echo "FAIL")
    log "Main API PROD /health: $API_HEALTH"
fi

BACKEND_PROD_SVC=$(kubectl get svc keybuzz-backend -n keybuzz-backend-prod -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "none")
if [ "$BACKEND_PROD_SVC" != "none" ]; then
    BACKEND_HEALTH=$(curl -sf -o /dev/null -w '%{http_code}' "http://${BACKEND_PROD_SVC}:3001/api/health" 2>/dev/null || echo "FAIL")
    log "Backend PROD /health: $BACKEND_HEALTH"
fi

log ""
log "--- STEP 8: Vault token TTLs (post-rotation) ==="
VAULT_ADDR="http://vault.default.svc.cluster.local:8200"
TOKEN1=$(kubectl get secret vault-root-token -n keybuzz-api-prod -o jsonpath='{.data.VAULT_TOKEN}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [ -n "$TOKEN1" ]; then
    TTL1=$(curl -sf -H "X-Vault-Token: $TOKEN1" "${VAULT_ADDR}/v1/auth/token/lookup-self" 2>/dev/null | grep -oP '"ttl":\s*\K[0-9]+' || echo "FAIL")
    log "TOKEN1 (API) TTL: ${TTL1}s ($(( TTL1 / 3600 ))h)"
fi

TOKEN2=$(kubectl get secret vault-app-token -n keybuzz-backend-prod -o jsonpath='{.data.token}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
if [ -n "$TOKEN2" ]; then
    TTL2=$(curl -sf -H "X-Vault-Token: $TOKEN2" "${VAULT_ADDR}/v1/auth/token/lookup-self" 2>/dev/null | grep -oP '"ttl":\s*\K[0-9]+' || echo "FAIL")
    log "TOKEN2 (Backend) TTL: ${TTL2}s ($(( TTL2 / 3600 ))h)"
fi

log ""
log "=== VAULT ROTATION COMPATIBILITY TEST DONE ==="
