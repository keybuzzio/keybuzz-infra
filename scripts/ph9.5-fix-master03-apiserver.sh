#!/bin/bash
# PH9.5 Fix master-03 API server

set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9.5"
mkdir -p "$LOG_DIR"

export KUBECONFIG=/root/.kube/config

MASTER3=10.0.0.102

echo "=============================================="
echo "PH9.5 FIX MASTER-03 API SERVER"
echo "Date: $(date)"
echo "=============================================="

echo ""
echo "=== DIAGNOSTIC master-03 ==="
ssh root@$MASTER3 bash <<'DIAG_EOF'
echo "--- advertise-address dans kube-apiserver.yaml ---"
grep advertise-address /etc/kubernetes/manifests/kube-apiserver.yaml || echo "Not found"

echo ""
echo "--- Ports en écoute (6443, 2379, 2380) ---"
ss -ntlp | grep -E "6443|2379|2380" || echo "No ports listening"

echo ""
echo "--- kubelet status ---"
systemctl status kubelet --no-pager | head -15 || true

echo ""
echo "--- crictl ps (control-plane containers) ---"
crictl ps | grep -E "kube-apiserver|etcd" || echo "No control-plane containers"
DIAG_EOF

echo ""
echo "=== Vérification etcd sur master-03 ==="
ssh root@$MASTER3 bash <<'ETCD_CHECK_EOF'
echo "--- etcd.yaml peer URLs ---"
grep -E "peer-urls|advertise" /etc/kubernetes/manifests/etcd.yaml | head -10 || echo "No etcd.yaml"

echo ""
echo "--- etcd process ---"
ps -ef | grep etcd | grep -v grep | head -3 || echo "No etcd process"
ETCD_CHECK_EOF

echo ""
echo "=== Si API server ne démarre pas, on le redémarre ==="
ssh root@$MASTER3 bash <<'RESTART_EOF'
echo "Restarting kubelet..."
systemctl restart kubelet
sleep 30

echo ""
echo "--- Vérification après restart ---"
crictl ps | grep -E "kube-apiserver|etcd" || echo "Still no containers"
ss -ntlp | grep 6443 || echo "Port 6443 still not listening"
RESTART_EOF

echo ""
echo "=== État final ==="
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-' | grep master-03

echo ""
echo "=============================================="
echo "PH9.5 FIX MASTER-03 TERMINÉ"
echo "=============================================="

