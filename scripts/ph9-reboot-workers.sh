#!/bin/bash
# PH9 - Reboot des workers pour stabilisation propre

echo "=== Reboot des workers pour stabilisation propre ==="

WORKERS="10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114"

for ip in $WORKERS; do
    echo "Rebooting worker $ip..."
    ssh root@$ip "reboot" 2>/dev/null || true
done

echo "Workers rebooting. Attente 120s..."
sleep 120

echo "Vérification que les workers sont de retour..."
for ip in $WORKERS; do
    echo -n "Checking $ip: "
    ssh -o ConnectTimeout=5 root@$ip "echo OK" 2>/dev/null || echo "NOT YET"
done

echo ""
echo "=== Vérification du cluster ==="
export KUBECONFIG=/root/.kube/config
kubectl get nodes

echo ""
echo "=== Calico ==="
kubectl get pods -n kube-system -l k8s-app=calico-node

echo ""
echo "=== kube-proxy ==="
kubectl get pods -n kube-system -l k8s-app=kube-proxy

