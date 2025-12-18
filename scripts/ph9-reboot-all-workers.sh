#!/bin/bash
# PH9 - Redémarrage de tous les workers pour stabilisation

export KUBECONFIG=/root/.kube/config

WORKERS="10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114"

echo "======================================="
echo "REDÉMARRAGE DES WORKERS"
echo "Date: $(date)"
echo "======================================="
echo ""

echo "=== État AVANT redémarrage ==="
kubectl get nodes -o wide
echo ""

echo "=== Redémarrage des workers ==="
for ip in $WORKERS; do
    echo "[INFO] Redémarrage du worker $ip..."
    ssh root@$ip "reboot" 2>/dev/null || true
    echo "  ✓ Worker $ip redémarré"
done

echo ""
echo "=== Attente 30 secondes ==="
sleep 30

echo ""
echo "=== Attente que les workers reviennent (max 5 minutes) ==="
TIMEOUT=300
ELAPSED=0
ALL_BACK=false

while [ $ELAPSED -lt $TIMEOUT ]; do
    ALL_BACK=true
    for ip in $WORKERS; do
        if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$ip "echo OK" 2>/dev/null > /dev/null; then
            ALL_BACK=false
            break
        fi
    done
    
    if [ "$ALL_BACK" = true ]; then
        echo "[OK] Tous les workers sont de retour !"
        break
    fi
    
    echo "[INFO] Attente... ($ELAPSED/$TIMEOUT secondes)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ "$ALL_BACK" = false ]; then
    echo "[WARN] Certains workers ne sont pas encore de retour après 5 minutes"
fi

echo ""
echo "=== Attente 60 secondes supplémentaires pour stabilisation ==="
sleep 60

echo ""
echo "=== État APRÈS redémarrage ==="
kubectl get nodes -o wide
echo ""

echo "=== Pods Calico ==="
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
echo ""

echo "=== Pods kube-proxy ==="
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
echo ""

echo "=== Résumé ==="
NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c "1/1" || echo "0")
KUBE_PROXY_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c "1/1" || echo "0")

echo "Nodes Ready: $NODES_READY/8"
echo "Calico Running: $CALICO_RUNNING/8"
echo "kube-proxy Running: $KUBE_PROXY_RUNNING/8"
echo ""

echo "======================================="
echo "REDÉMARRAGE TERMINÉ"
echo "======================================="

