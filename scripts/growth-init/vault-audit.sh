#!/bin/bash
set -e

echo "=== STUDIO API DEV — Deployment ==="
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-dev -o jsonpath='Image: {.spec.template.spec.containers[0].image}{"\n"}'
echo "Env vars from secrets:"
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-dev -o jsonpath='{range .spec.template.spec.containers[0].env[*]}  env {.name} -> {.valueFrom.secretKeyRef.name}/{.valueFrom.secretKeyRef.key}{"\n"}{end}' 2>/dev/null || true
echo "EnvFrom:"
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-dev -o jsonpath='{range .spec.template.spec.containers[0].envFrom[*]}  envFrom -> {.secretRef.name}{"\n"}{end}' 2>/dev/null || true

echo ""
echo "=== STUDIO API PROD — Deployment ==="
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-prod -o jsonpath='Image: {.spec.template.spec.containers[0].image}{"\n"}'
echo "Env vars from secrets:"
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-prod -o jsonpath='{range .spec.template.spec.containers[0].env[*]}  env {.name} -> {.valueFrom.secretKeyRef.name}/{.valueFrom.secretKeyRef.key}{"\n"}{end}' 2>/dev/null || true
echo "EnvFrom:"
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-prod -o jsonpath='{range .spec.template.spec.containers[0].envFrom[*]}  envFrom -> {.secretRef.name}{"\n"}{end}' 2>/dev/null || true

echo ""
echo "=== K8S SECRETS STUDIO DEV ==="
kubectl get secrets -n keybuzz-studio-api-dev --no-headers 2>/dev/null | awk '{print $1}'

echo ""
echo "=== K8S SECRETS STUDIO PROD ==="
kubectl get secrets -n keybuzz-studio-api-prod --no-headers 2>/dev/null | awk '{print $1}'

echo ""
echo "=== VAULT-TOKEN-RENEW — Studio refs? ==="
STUDIO_COUNT=$(kubectl get configmap vault-renew-script -n vault-management -o jsonpath='{.data}' 2>/dev/null | grep -ci "studio" || true)
echo "Studio refs in CronJob: ${STUDIO_COUNT:-0}"

echo ""
echo "=== VAULT-TOKEN-RENEW RBAC — Studio? ==="
RBAC_COUNT=$(kubectl get clusterrole vault-token-renewer -o yaml 2>/dev/null | grep -ci "studio" || true)
echo "Studio refs in RBAC: ${RBAC_COUNT:-0}"

echo ""
echo "=== VAULT TOKEN CHECK — Any vault-token secret in Studio NS? ==="
kubectl get secret vault-token -n keybuzz-studio-api-dev 2>/dev/null && echo "FOUND in DEV" || echo "NOT FOUND in DEV"
kubectl get secret vault-root-token -n keybuzz-studio-api-dev 2>/dev/null && echo "vault-root-token FOUND in DEV" || echo "vault-root-token NOT FOUND in DEV"
kubectl get secret vault-app-token -n keybuzz-studio-api-dev 2>/dev/null && echo "vault-app-token FOUND in DEV" || echo "vault-app-token NOT FOUND in DEV"
kubectl get secret vault-token -n keybuzz-studio-api-prod 2>/dev/null && echo "FOUND in PROD" || echo "NOT FOUND in PROD"
kubectl get secret vault-root-token -n keybuzz-studio-api-prod 2>/dev/null && echo "vault-root-token FOUND in PROD" || echo "vault-root-token NOT FOUND in PROD"
kubectl get secret vault-app-token -n keybuzz-studio-api-prod 2>/dev/null && echo "vault-app-token FOUND in PROD" || echo "vault-app-token NOT FOUND in PROD"

echo ""
echo "=== AUDIT DONE ==="
