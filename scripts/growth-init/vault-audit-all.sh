#!/bin/bash
set -e

check_deploy() {
    local ns="$1"
    local name="$2"
    echo "=== $name ($ns) ==="
    
    IMG=$(kubectl get deployment "$name" -n "$ns" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "NOT FOUND")
    echo "Image: $IMG"
    
    if [ "$IMG" = "NOT FOUND" ]; then
        echo "(deployment not found)"
        echo ""
        return
    fi
    
    echo "Env from secrets:"
    kubectl get deployment "$name" -n "$ns" -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.valueFrom.secretKeyRef.name}/{.valueFrom.secretKeyRef.key}{"\n"}{end}' 2>/dev/null | grep -v "=/$" || echo "  (none)"
    
    echo "EnvFrom:"
    kubectl get deployment "$name" -n "$ns" -o jsonpath='{range .spec.template.spec.containers[0].envFrom[*]}secretRef={.secretRef.name}{"\n"}{end}' 2>/dev/null | grep -v "^$" || echo "  (none)"
    
    HAS_VAULT=$(kubectl get deployment "$name" -n "$ns" -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}{"\n"}{end}' 2>/dev/null | grep -ci "VAULT" || true)
    echo "VAULT_* env vars: $HAS_VAULT"
    
    if [ "$HAS_VAULT" -gt 0 ]; then
        kubectl get deployment "$name" -n "$ns" -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.valueFrom.secretKeyRef.name}/{.valueFrom.secretKeyRef.key}{"\n"}{end}' 2>/dev/null | grep -i "VAULT" || true
    fi
    echo ""
}

echo "###############################################"
echo "# FULL VAULT AUDIT — ALL KEYBUZZ SERVICES     #"
echo "###############################################"
echo ""

echo "--- STUDIO ---"
check_deploy "keybuzz-studio-api-dev" "keybuzz-studio-api"
check_deploy "keybuzz-studio-api-prod" "keybuzz-studio-api"
check_deploy "keybuzz-studio-dev" "keybuzz-studio"
check_deploy "keybuzz-studio-prod" "keybuzz-studio"

echo "--- MAIN API ---"
check_deploy "keybuzz-api-dev" "keybuzz-api"
check_deploy "keybuzz-api-prod" "keybuzz-api"

echo "--- BACKEND ---"
check_deploy "keybuzz-backend-dev" "keybuzz-backend"
check_deploy "keybuzz-backend-prod" "keybuzz-backend"

echo "--- AMAZON WORKERS ---"
check_deploy "keybuzz-api-dev" "amazon-orders-worker"
check_deploy "keybuzz-api-prod" "amazon-orders-worker"
check_deploy "keybuzz-api-dev" "amazon-items-worker"
check_deploy "keybuzz-api-prod" "amazon-items-worker"

echo "--- WEBSITE ---"
check_deploy "keybuzz-website-prod" "keybuzz-website"
check_deploy "keybuzz-www-prod" "keybuzz-www"

echo "--- OUTBOUND WORKER ---"
check_deploy "keybuzz-api-dev" "keybuzz-outbound-worker"
check_deploy "keybuzz-api-prod" "keybuzz-outbound-worker"

echo ""
echo "=== VAULT-TOKEN-RENEW — Covered deployments ==="
kubectl get configmap vault-renew-script -n vault-management -o jsonpath='{.data}' 2>/dev/null | grep -oP 'keybuzz-[a-z-]+' | sort -u || echo "(could not read)"

echo ""
echo "=== CRONJOB STATUS ==="
kubectl get cronjob vault-token-renew -n vault-management -o jsonpath='Schedule: {.spec.schedule} Suspend: {.spec.suspend} Last: {.status.lastScheduleTime}' 2>/dev/null || echo "(not found)"
echo ""

echo "=== ALL SERVICES AUDIT DONE ==="
