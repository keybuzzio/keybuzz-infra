#!/bin/bash
# PH9 - Rapport de statut complet

export KUBECONFIG=/root/.kube/config 2>/dev/null || {
    mkdir -p /root/.kube
    scp root@10.0.0.100:/etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || true
    export KUBECONFIG=/root/.kube/config
}

echo "=============================================="
echo "PH9 - RAPPORT DE STATUT"
echo "Date: $(date)"
echo "=============================================="
echo ""

echo "=== NŒUDS ==="
kubectl get nodes -o wide 2>/dev/null || echo "Cluster non accessible"

echo ""
echo "=== PODS SYSTÈME (kube-system) ==="
kubectl get pods -n kube-system 2>/dev/null | head -20 || echo "Non accessible"

echo ""
echo "=== CALICO ==="
kubectl get pods -n kube-system -l k8s-app=calico-node 2>/dev/null || echo "Non accessible"

echo ""
echo "=== ARGOCD ==="
kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD non installé ou non accessible"

echo ""
echo "=== EXTERNAL SECRETS OPERATOR ==="
kubectl get pods -n external-secrets 2>/dev/null || echo "ESO non installé ou non accessible"

echo ""
echo "=============================================="

