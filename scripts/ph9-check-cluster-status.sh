#!/bin/bash
# PH9 - Vérification complète de l'état du cluster

export KUBECONFIG=/root/.kube/config

echo "======================================="
echo "VÉRIFICATION COMPLÈTE DU CLUSTER"
echo "Date: $(date)"
echo "======================================="
echo ""

echo "=== NODES ==="
kubectl get nodes -o wide
echo ""

echo "=== CONTROL PLANE ==="
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-'
echo ""

echo "=== CALICO ==="
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide
echo ""

echo "=== KUBE-PROXY ==="
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
echo ""

echo "=== COREDNS ==="
kubectl get pods -n kube-system -l k8s-app=kube-dns
echo ""

echo "=== RÉSUMÉ ==="
NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
CONTROL_PLANE_RUNNING=$(kubectl get pods -n kube-system 2>/dev/null | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' | grep -c "1/1" || echo "0")
CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c "1/1" || echo "0")
KUBE_PROXY_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c "1/1" || echo "0")

echo "Nodes Ready: $NODES_READY/8"
echo "Control Plane Running: $CONTROL_PLANE_RUNNING/12"
echo "Calico Running: $CALICO_RUNNING/8"
echo "kube-proxy Running: $KUBE_PROXY_RUNNING/8"
echo ""

echo "=== ESO (si installé) ==="
kubectl get pods -n external-secrets 2>/dev/null || echo "ESO namespace not found"
echo ""

echo "=== ETCD MEMBERS (depuis master-01) ==="
ssh root@10.0.0.100 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "$ETCD_CTR" ]; then
    crictl exec $ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list -w table 2>/dev/null || echo "ETCD member list failed"
else
    echo "ETCD container not found"
fi
EOF

