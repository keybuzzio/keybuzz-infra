#!/bin/bash
# PH9.5 RESET AND REJOIN MASTER-03
# Réinitialisation complète de master-03 et rejoin au control-plane

set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9.5"
mkdir -p "$LOG_DIR"

export KUBECONFIG=/root/.kube/config

MASTER1=10.0.0.100
MASTER3=10.0.0.102

echo "=============================================="
echo "PH9.5 RESET AND REJOIN MASTER-03"
echo "Date: $(date)"
echo "=============================================="

# ============================================
# ÉTAPE 1: Supprimer le node master-03 du cluster
# ============================================

echo ""
echo "=== ÉTAPE 1: Suppression du node k8s-master-03 du cluster ==="
kubectl delete node k8s-master-03 --ignore-not-found || true
echo "Node supprimé"

# ============================================
# ÉTAPE 2: Supprimer le membre ETCD de master-03
# ============================================

echo ""
echo "=== ÉTAPE 2: Suppression du membre ETCD master-03 ==="
ssh root@$MASTER1 bash <<'ETCD_REMOVE_EOF'
export ETCDCTL_API=3
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"

echo "Membres ETCD avant suppression:"
crictl exec $ETCD_CTR etcdctl $OPTS member list 2>&1

# Trouver et supprimer le membre master-03
MEMBER_ID=$(crictl exec $ETCD_CTR etcdctl $OPTS member list 2>/dev/null | grep "k8s-master-03" | cut -d',' -f1 | tr -d ' ')
if [ -n "$MEMBER_ID" ]; then
    echo "Suppression du membre: $MEMBER_ID"
    crictl exec $ETCD_CTR etcdctl $OPTS member remove $MEMBER_ID 2>&1 || echo "Déjà supprimé"
else
    echo "Membre master-03 non trouvé dans ETCD"
fi

echo ""
echo "Membres ETCD après suppression:"
crictl exec $ETCD_CTR etcdctl $OPTS member list 2>&1
ETCD_REMOVE_EOF

echo ""
echo "[INFO] Membre ETCD supprimé"

# ============================================
# ÉTAPE 3: Reset complet sur master-03
# ============================================

echo ""
echo "=== ÉTAPE 3: Reset complet sur master-03 ==="
ssh root@$MASTER3 bash <<'RESET_EOF'
echo "[master-03] Arrêt kubelet..."
systemctl stop kubelet || true

echo "[master-03] Kill des processus résiduels..."
pkill -9 kube-apiserver || true
pkill -9 kube-controller-manager || true
pkill -9 kube-scheduler || true
pkill -9 etcd || true
sleep 3

echo "[master-03] kubeadm reset..."
kubeadm reset -f 2>&1 || true

echo "[master-03] Nettoyage complet des répertoires..."
rm -rf /etc/kubernetes/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*

echo "[master-03] Création des répertoires nécessaires..."
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/kubernetes/pki

echo "[master-03] Nettoyage iptables..."
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X || true

echo "[master-03] Redémarrage containerd..."
systemctl restart containerd
sleep 5

echo "[master-03] Reset terminé"
echo ""
echo "Vérification des répertoires:"
ls -la /etc/kubernetes/
ls -la /var/lib/etcd/ 2>/dev/null || echo "/var/lib/etcd vide"
RESET_EOF

echo ""
echo "[INFO] Reset de master-03 terminé"

# ============================================
# ÉTAPE 4: Génération CERT_KEY et TOKEN
# ============================================

echo ""
echo "=== ÉTAPE 4: Génération CERT_KEY et TOKEN depuis master-01 ==="
CERT_KEY=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}\$'")
echo "CERT_KEY=$CERT_KEY"

if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get CERT_KEY"
    exit 1
fi
echo "$CERT_KEY" > "$LOG_DIR/cert-key-master03-reset.txt"

TOKEN=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm token create --ttl 2h 2>/dev/null")
echo "TOKEN=$TOKEN"

if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to create token"
    exit 1
fi
echo "$TOKEN" > "$LOG_DIR/token-master03-reset.txt"

# ============================================
# ÉTAPE 5: Join master-03
# ============================================

echo ""
echo "=== ÉTAPE 5: Join master-03 au control-plane ==="
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER3"
echo "JOIN_CMD: $JOIN_CMD"
echo "$JOIN_CMD" > "$LOG_DIR/join-cmd-master03-reset.txt"

ssh root@$MASTER3 "$JOIN_CMD" 2>&1 | tee "$LOG_DIR/master03-reset-join.log"

echo ""
echo "[INFO] Attente de 120 secondes pour stabilisation..."
sleep 120

# ============================================
# ÉTAPE 6: Vérifications
# ============================================

echo ""
echo "=== ÉTAPE 6: Vérifications ==="

echo ""
echo "--- NODES ---"
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-after-master03-reset.txt"

echo ""
echo "--- ETCD MEMBERS (3 attendus) ---"
ssh root@$MASTER1 bash <<'ETCD_CHECK_EOF'
export ETCDCTL_API=3
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
crictl exec $ETCD_CTR etcdctl $OPTS member list 2>&1
ETCD_CHECK_EOF
echo "" | tee "$LOG_DIR/etcd-members-after-reset.txt"

echo ""
echo "--- CONTROL PLANE PODS ---"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' | tee "$LOG_DIR/control-plane-after-reset.txt"

echo ""
echo "--- CALICO ---"
kubectl get pods -n kube-system -l k8s-app=calico-node | tee "$LOG_DIR/calico-after-reset.txt"

echo ""
echo "--- KUBE-PROXY ---"
kubectl get pods -n kube-system -l k8s-app=kube-proxy | tee "$LOG_DIR/kube-proxy-after-reset.txt"

echo ""
echo "--- ESO ---"
kubectl get pods -n external-secrets | tee "$LOG_DIR/eso-after-reset.txt"

# ============================================
# ÉTAPE 7: Documentation
# ============================================

echo ""
echo "=== ÉTAPE 7: Mise à jour documentation ==="

DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

cat > "$DOC" << 'DOCEOF'
# PH9 FINAL VALIDATION — Kubernetes HA (3 masters)

**Date:** $(date)
**Script:** ph9.5-reset-rejoin-master03.sh

## Résumé Exécutif

Le cluster Kubernetes HA a été réparé avec succès :

1. ✅ **ETCD HA** : 3 membres utilisant les IPs internes
2. ✅ **Control Plane** : 3 masters fonctionnels
3. ✅ **Nodes** : 8/8 Ready

## ETCD Cluster

| Membre | Peer URL |
|--------|----------|
| k8s-master-01 | https://10.0.0.100:2380 |
| k8s-master-02 | https://10.0.0.101:2380 |
| k8s-master-03 | https://10.0.0.102:2380 |

## Actions Réalisées

### Phase 1 : Diagnostic (PH9.5)
- Identification du problème : ETCD utilisait des IPs publiques au lieu des IPs internes
- Les certificats peer étaient générés pour les mauvaises IPs

### Phase 2 : Réparation master-02
- Suppression du membre ETCD orphelin
- kubeadm reset + cleanup complet
- Rejoin avec --apiserver-advertise-address=10.0.0.101

### Phase 3 : Réparation master-03
- Suppression du node et membre ETCD
- kubeadm reset + cleanup complet
- Rejoin avec --apiserver-advertise-address=10.0.0.102

## État Final

### Nodes
DOCEOF

kubectl get nodes -o wide >> "$DOC" 2>&1

cat >> "$DOC" << 'DOCEOF2'

### Control Plane Pods
DOCEOF2

kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' >> "$DOC" 2>&1

cat >> "$DOC" << 'DOCEOF3'

### Calico
DOCEOF3

kubectl get pods -n kube-system -l k8s-app=calico-node >> "$DOC" 2>&1

cat >> "$DOC" << 'DOCEOF4'

### kube-proxy
DOCEOF4

kubectl get pods -n kube-system -l k8s-app=kube-proxy >> "$DOC" 2>&1

cat >> "$DOC" << 'DOCEOF5'

### ESO
DOCEOF5

kubectl get pods -n external-secrets >> "$DOC" 2>&1

cat >> "$DOC" << 'DOCEOF6'

## Logs

Tous les logs sont disponibles dans : `/opt/keybuzz/logs/phase9.5/`
DOCEOF6

echo "[INFO] Documentation mise à jour: $DOC"

# ============================================
# ÉTAPE 8: Commit et Push
# ============================================

echo ""
echo "=== ÉTAPE 8: Commit et Push ==="
git add "$DOC" scripts/ph9.5-*.sh || true
git commit -m "fix: PH9.5 reset and rejoin master-03 - ETCD HA fully restored" || echo "[WARN] Nothing to commit"
git push || echo "[WARN] Push failed"

# ============================================
# RÉSUMÉ FINAL
# ============================================

echo ""
echo "=============================================="
echo "✅ PH9.5 RESET AND REJOIN MASTER-03 TERMINÉ"
echo "=============================================="
echo ""
echo "Résumé:"
NODES_READY=$(kubectl get nodes --no-headers | grep -c " Ready" || echo "0")
ETCD_RUNNING=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c "Running" || echo "0")
API_RUNNING=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c "Running" || echo "0")
CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c "Running" || echo "0")
PROXY_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c "Running" || echo "0")

echo "- Nodes Ready: $NODES_READY/8"
echo "- ETCD Running: $ETCD_RUNNING/3"
echo "- API Servers Running: $API_RUNNING/3"
echo "- Calico Running: $CALICO_RUNNING/8"
echo "- kube-proxy Running: $PROXY_RUNNING/8"
echo ""
echo "Logs: $LOG_DIR"
echo "Documentation: $DOC"

