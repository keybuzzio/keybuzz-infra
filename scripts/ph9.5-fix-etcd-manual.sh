#!/bin/bash
# PH9.5 Fix ETCD Manual - Suppression membre orphelin et rejoin master-02

set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9.5"
mkdir -p "$LOG_DIR"

export KUBECONFIG=/root/.kube/config

MASTER1=10.0.0.100
MASTER2=10.0.0.101
MASTER3=10.0.0.102

echo "=============================================="
echo "PH9.5 FIX ETCD MANUAL"
echo "Date: $(date)"
echo "=============================================="

# Fonction pour exécuter etcdctl
run_etcdctl() {
    local CMD="$@"
    ssh root@$MASTER1 "ETCD_CTR=\$(crictl ps --name etcd -q 2>/dev/null | head -1); crictl exec \$ETCD_CTR etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key $CMD" 2>&1
}

echo ""
echo "=== ÉTAPE 1: Liste des membres ETCD actuels ==="
run_etcdctl "member list" | tee "$LOG_DIR/etcd-before-cleanup.txt"

echo ""
echo "=== ÉTAPE 2: Suppression du membre orphelin (7268a97e53f7248) ==="
run_etcdctl "member remove 7268a97e53f7248" 2>&1 || echo "Member may already be removed or does not exist"

echo ""
echo "=== ÉTAPE 3: Liste des membres ETCD après cleanup ==="
run_etcdctl "member list" | tee "$LOG_DIR/etcd-after-cleanup.txt"

echo ""
echo "=== ÉTAPE 4: Génération CERT_KEY ==="
CERT_KEY=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}\$'")
echo "CERT_KEY=$CERT_KEY"
echo "$CERT_KEY" > "$LOG_DIR/cert-key.txt"

echo ""
echo "=== ÉTAPE 5: Création du token ==="
TOKEN=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm token create --ttl 2h 2>/dev/null")
echo "TOKEN=$TOKEN"
echo "$TOKEN" > "$LOG_DIR/token.txt"

echo ""
echo "=== ÉTAPE 6: Construction de la commande JOIN ==="
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER2"
echo "JOIN_CMD=$JOIN_CMD"
echo "$JOIN_CMD" > "$LOG_DIR/join-cmd.txt"

echo ""
echo "=== ÉTAPE 7: Préparation master-02 (si pas déjà fait) ==="
ssh root@$MASTER2 bash <<'PREP_EOF'
echo "[master-02] État actuel..."
ls -la /etc/kubernetes/manifests/ 2>/dev/null || echo "No manifests"
ls -la /var/lib/etcd/ 2>/dev/null || echo "No etcd data"
PREP_EOF

echo ""
echo "=== ÉTAPE 8: Exécution du JOIN sur master-02 ==="
set +e
ssh root@$MASTER2 "$JOIN_CMD" 2>&1 | tee "$LOG_DIR/master02-join-manual.log"
JOIN_RESULT=$?
set -e

echo ""
echo "[INFO] Join result: $JOIN_RESULT"

echo ""
echo "=== ÉTAPE 9: Attente 120 secondes ==="
sleep 120

echo ""
echo "=== ÉTAPE 10: Vérification ==="
echo "--- Nodes ---"
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-after-manual.txt"

echo ""
echo "--- ETCD pods ---"
kubectl get pods -n kube-system | grep etcd | tee "$LOG_DIR/etcd-pods-after.txt"

echo ""
echo "--- ETCD members ---"
run_etcdctl "member list" | tee "$LOG_DIR/etcd-members-final.txt"

echo ""
echo "=============================================="
echo "PH9.5 FIX ETCD MANUAL TERMINÉ"
echo "=============================================="

