#!/bin/bash
# PH9.5 Cleanup and Join master-03

set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9.5"
mkdir -p "$LOG_DIR"

export KUBECONFIG=/root/.kube/config

MASTER1=10.0.0.100
MASTER3=10.0.0.102

echo "=============================================="
echo "PH9.5 CLEANUP AND JOIN MASTER-03"
echo "Date: $(date)"
echo "=============================================="

echo ""
echo "=== ÉTAPE 1: Cleanup complet sur master-03 ==="
ssh root@$MASTER3 bash <<'CLEANUP_EOF'
echo "[master-03] Arrêt kubelet..."
systemctl stop kubelet || true

echo "[master-03] Kill des processus résiduels..."
pkill -9 kube-scheduler || true
pkill -9 kube-controller-manager || true
pkill -9 kube-apiserver || true
pkill -9 etcd || true

echo "[master-03] Attente 3 secondes..."
sleep 3

echo "[master-03] Vérification ports..."
ss -ntlp | grep -E "10257|10259|10250|6443|2379|2380" || echo "Ports libres"

echo "[master-03] kubeadm reset..."
kubeadm reset -f 2>&1 || true

echo "[master-03] Nettoyage répertoires..."
rm -rf /etc/kubernetes/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

echo "[master-03] Création répertoires..."
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/kubernetes/pki

echo "[master-03] Redémarrage containerd..."
systemctl restart containerd
sleep 3

echo "[master-03] Cleanup terminé"
CLEANUP_EOF

echo ""
echo "=== ÉTAPE 2: Génération CERT_KEY ==="
CERT_KEY=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}\$'")
echo "CERT_KEY=$CERT_KEY"

if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get CERT_KEY"
    exit 1
fi

echo ""
echo "=== ÉTAPE 3: Création du token ==="
TOKEN=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm token create --ttl 2h 2>/dev/null")
echo "TOKEN=$TOKEN"

if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to create token"
    exit 1
fi

echo ""
echo "=== ÉTAPE 4: Exécution JOIN sur master-03 ==="
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER3"
echo "JOIN_CMD: $JOIN_CMD"

ssh root@$MASTER3 "$JOIN_CMD" 2>&1 | tee "$LOG_DIR/master03-join-final.log"

echo ""
echo "=== ÉTAPE 5: Attente 120 secondes ==="
sleep 120

echo ""
echo "=== ÉTAPE 6: Vérification ==="
echo "--- Nodes ---"
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-after-master03.txt"

echo ""
echo "--- ETCD pods ---"
kubectl get pods -n kube-system | grep etcd

echo ""
echo "--- ETCD members (3 attendus) ---"
ssh root@$MASTER1 'ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1); crictl exec $ETCD_CTR etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list' 2>&1 | tee "$LOG_DIR/etcd-members-3.txt"

echo ""
echo "--- Control plane pods ---"
kubectl get pods -n kube-system | grep -E "etcd-|kube-apiserver-|kube-controller-|kube-scheduler-" | tee "$LOG_DIR/control-plane-final.txt"

echo ""
echo "=============================================="
echo "PH9.5 CLEANUP AND JOIN MASTER-03 TERMINÉ"
echo "=============================================="

