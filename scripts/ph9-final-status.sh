#!/bin/bash
# PH9 - Rapport de statut final complet

export KUBECONFIG=/root/.kube/config 2>/dev/null || {
    mkdir -p /root/.kube
    scp root@10.0.0.100:/etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || true
    export KUBECONFIG=/root/.kube/config
}

echo "=============================================="
echo "PH9 - RAPPORT DE STATUT COMPLET"
echo "Date: $(date)"
echo "=============================================="
echo ""

echo "=== NŒUDS KUBERNETES ==="
READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
echo "Nœuds Ready: $READY_NODES/$TOTAL_NODES"
kubectl get nodes -o wide 2>/dev/null || echo "Cluster non accessible"

echo ""
echo "=== PODS SYSTÈME (kube-system) ==="
kubectl get pods -n kube-system 2>/dev/null | head -20 || echo "Non accessible"

echo ""
echo "=== CALICO CNI ==="
CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")
CALICO_TOTAL=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l || echo "0")
echo "Calico pods Running: $CALICO_RUNNING/$CALICO_TOTAL"
kubectl get pods -n kube-system -l k8s-app=calico-node 2>/dev/null || echo "Non accessible"

echo ""
echo "=== COREDNS ==="
COREDNS_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")
COREDNS_TOTAL=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers 2>/dev/null | wc -l || echo "0")
echo "CoreDNS pods Running: $COREDNS_RUNNING/$COREDNS_TOTAL"
kubectl get pods -n kube-system -l k8s-app=kube-dns 2>/dev/null || echo "Non accessible"

echo ""
echo "=== ARGOCD ==="
if kubectl get ns argocd &>/dev/null 2>&1; then
    ARGOCD_RUNNING=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    ARGOCD_TOTAL=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
    echo "ArgoCD pods Running: $ARGOCD_RUNNING/$ARGOCD_TOTAL"
    kubectl get pods -n argocd 2>/dev/null | head -10
else
    echo "ArgoCD namespace n'existe pas"
fi

echo ""
echo "=== EXTERNAL SECRETS OPERATOR ==="
if kubectl get ns external-secrets &>/dev/null 2>&1; then
    ESO_RUNNING=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep Running | wc -l || echo "0")
    ESO_TOTAL=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | wc -l || echo "0")
    echo "ESO pods Running: $ESO_RUNNING/$ESO_TOTAL"
    kubectl get pods -n external-secrets 2>/dev/null
else
    echo "External Secrets namespace n'existe pas"
fi

echo ""
echo "=============================================="
echo "RÉSUMÉ"
echo "=============================================="
echo "Nœuds Ready: $READY_NODES/$TOTAL_NODES"
echo "Calico: $CALICO_RUNNING/$CALICO_TOTAL pods Running"
echo "CoreDNS: $COREDNS_RUNNING/$COREDNS_TOTAL pods Running"
echo "ArgoCD: $ARGOCD_RUNNING pods Running"
echo "ESO: $ESO_RUNNING pods Running"
echo "=============================================="

if [ "$READY_NODES" -eq 8 ] && [ "$CALICO_RUNNING" -ge 8 ]; then
    echo ""
    echo "✅ PH9 - CLUSTER OPÉRATIONNEL"
else
    echo ""
    echo "⚠️  PH9 - EN COURS"
    echo "   - Nœuds NotReady à corriger"
    echo "   - Calico à stabiliser"
fi
echo ""

