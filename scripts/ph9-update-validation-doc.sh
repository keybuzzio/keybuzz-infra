#!/bin/bash
# PH9-UPDATE-VALIDATION-DOC - Update PH9-FINAL-VALIDATION.md with current cluster status
set -e

cd /opt/keybuzz/keybuzz-infra
export KUBECONFIG=/root/.kube/config

DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

{
    echo "# PH9 FINAL VALIDATION — Kubernetes v3 + ArgoCD + ESO + Vault"
    echo ""
    echo "**Date:** $(date)"
    echo ""
    echo "## Summary"
    echo ""
    NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    API_SERVERS=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
    ETCD_PODS=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
    ESO_PODS=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    SECRET_EXISTS=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo "YES" || echo "NO")
    CRASHLOOP=$(kubectl get pods -A --no-headers 2>/dev/null | grep -c CrashLoopBackOff || echo "0")
    echo "- Nodes Ready: $NODES_READY/8"
    echo "- API Servers Running: $API_SERVERS/3"
    echo "- ETCD Pods Running: $ETCD_PODS/3"
    echo "- ESO Pods Running: $ESO_PODS/1"
    echo "- Secret redis-test-secret: $SECRET_EXISTS"
    echo "- Pods in CrashLoopBackOff: $CRASHLOOP"
    echo ""
    echo "## Nodes"
    echo "\`\`\`"
    kubectl get nodes -o wide 2>&1 || echo "kubectl get nodes failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (kube-system)"
    echo "\`\`\`"
    kubectl get pods -n kube-system -o wide 2>&1 | head -50 || echo "kubectl get pods -n kube-system failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (external-secrets)"
    echo "\`\`\`"
    kubectl get pods -n external-secrets -o wide 2>&1 || echo "kubectl get pods -n external-secrets failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (argocd)"
    echo "\`\`\`"
    kubectl get pods -n argocd -o wide 2>&1 || echo "kubectl get pods -n argocd failed"
    echo "\`\`\`"
} > "$DOC"

echo "[INFO] Documentation updated: $DOC"

