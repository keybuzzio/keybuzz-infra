#!/bin/bash
# PH9 - Stabilisation du cluster

echo "=== Restart kubelet sur les masters ==="
for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
    echo "Restarting kubelet on $ip..."
    ssh root@$ip 'systemctl restart kubelet' || true
done

echo ""
echo "=== Attente 90s ==="
sleep 90

echo ""
echo "=== État du cluster ==="
export KUBECONFIG=/root/.kube/config

echo "[INFO] Nodes:"
kubectl get nodes -o wide || echo "API not responding yet"

echo ""
echo "[INFO] Control Plane:"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' || echo "API not responding"

echo ""
echo "[INFO] Calico:"
kubectl get pods -n kube-system -l k8s-app=calico-node || echo "API not responding"

echo ""
echo "[INFO] kube-proxy:"
kubectl get pods -n kube-system -l k8s-app=kube-proxy || echo "API not responding"

