#!/bin/bash
set -e

echo "=========================================="
echo "DIAGNOSTIC COMPLET DU CLUSTER KUBERNETES"
echo "=========================================="
echo ""

MASTER_IP="10.0.0.100"
KUBECONFIG="/etc/kubernetes/admin.conf"

echo "1. ETAT DU CLUSTER"
echo "=================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get nodes -o wide"
echo ""

echo "2. PODS SYSTEME"
echo "==============="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get pods -n kube-system -o wide"
echo ""

echo "3. CONDITIONS DES NODES"
echo "======================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl describe nodes | grep -A 5 'Conditions:' | head -50"
echo ""

echo "4. ETAT DES COMPOSANTS DU CONTROL PLANE"
echo "========================================"
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get cs 2>/dev/null || kubectl get componentstatuses 2>/dev/null || echo 'ComponentStatus deprecated'"
echo ""

echo "5. ETAT ETCD"
echo "============"
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get pods -n kube-system -l component=etcd -o wide"
echo ""

echo "6. ETAT API SERVER"
echo "=================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get pods -n kube-system -l component=kube-apiserver -o wide"
echo ""

echo "7. ETAT KUBE-PROXY"
echo "=================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide"
echo ""

echo "8. ETAT COREDNS"
echo "==============="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide"
echo ""

echo "9. SERVICES"
echo "==========="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get svc -n kube-system"
echo ""

echo "10. ENDPOINTS"
echo "============="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get endpoints -n kube-system"
echo ""

echo "11. EVENTS RECENTS (kube-system)"
echo "================================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl get events -n kube-system --sort-by=.lastTimestamp | tail -20"
echo ""

echo "12. CONNECTIVITE RESEAU ENTRE MASTERS"
echo "======================================"
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "=== Master $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "for peer in 10.0.0.100 10.0.0.101 10.0.0.102; do ping -c 1 -W 2 \$peer >/dev/null 2>&1 && echo \"  -> \$peer: OK\" || echo \"  -> \$peer: FAILED\"; done"
done
echo ""

echo "13. HEALTH API SERVER SUR LES 3 MASTERS"
echo "========================================"
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "=== Master $ip ==="
    curl -k -s https://$ip:6443/healthz && echo " OK" || echo " FAILED"
done
echo ""

echo "14. ETAT KUBELET ET CONTAINERD SUR LES MASTERS"
echo "=============================================="
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "=== Master $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "systemctl is-active kubelet && echo 'kubelet: OK' || echo 'kubelet: FAILED'"
    ssh -o StrictHostKeyChecking=no root@$ip "systemctl is-active containerd && echo 'containerd: OK' || echo 'containerd: FAILED'"
    ssh -o StrictHostKeyChecking=no root@$ip "crictl version 2>&1 | head -3 || echo 'crictl: FAILED'"
done
echo ""

echo "15. ETAT KUBELET ET CONTAINERD SUR LES WORKERS"
echo "=============================================="
for ip in 10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114; do
    echo "=== Worker $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "systemctl is-active kubelet && echo 'kubelet: OK' || echo 'kubelet: FAILED'"
    ssh -o StrictHostKeyChecking=no root@$ip "systemctl is-active containerd && echo 'containerd: OK' || echo 'containerd: FAILED'"
    ssh -o StrictHostKeyChecking=no root@$ip "crictl version 2>&1 | head -3 || echo 'crictl: FAILED'"
done
echo ""

echo "16. CONFIGURATION CONTAINERD (SystemdCgroup)"
echo "============================================"
for ip in 10.0.0.100 10.0.0.101 10.0.0.102 10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114; do
    echo "=== $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "grep -A 2 SystemdCgroup /etc/containerd/config.toml 2>/dev/null || echo 'CONFIG_NOT_FOUND'"
done
echo ""

echo "17. CONFIGURATION DNS"
echo "====================="
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "=== Master $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "cat /etc/resolv.conf | head -5"
done
echo ""

echo "18. VOLUMES MONTS"
echo "================="
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "=== Master $ip ==="
    ssh -o StrictHostKeyChecking=no root@$ip "df -h | grep -E 'Filesystem|/opt/k8s|/var/lib' || echo 'No specific mounts'"
done
echo ""

echo "19. ERREURS DANS LES LOGS ETCD (dernières 10 lignes)"
echo "====================================================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl logs -n kube-system -l component=etcd --tail=10 2>&1 | grep -i error | head -10 || echo 'Pas d erreurs recentes'"
echo ""

echo "20. ERREURS DANS LES LOGS API SERVER (dernières 10 lignes)"
echo "=========================================================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl logs -n kube-system -l component=kube-apiserver --tail=10 2>&1 | grep -i error | head -10 || echo 'Pas d erreurs recentes'"
echo ""

echo "21. FICHIERS DE JOIN"
echo "===================="
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "test -f /root/k8s_join_control_plane.txt && echo 'CONTROL_PLANE_JOIN_FILE: EXISTS' || echo 'CONTROL_PLANE_JOIN_FILE: MISSING'"
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "test -f /root/k8s_join_workers.txt && echo 'WORKER_JOIN_FILE: EXISTS' || echo 'WORKER_JOIN_FILE: MISSING'"
echo ""

echo "22. VERSION KUBERNETES"
echo "======================"
ssh -o StrictHostKeyChecking=no root@$MASTER_IP "export KUBECONFIG=$KUBECONFIG && kubectl version 2>&1 | head -5"
echo ""

echo "=========================================="
echo "DIAGNOSTIC TERMINE"
echo "=========================================="

