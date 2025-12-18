#!/bin/bash
# PH9 - RESET ULTRA-COMPLET DU CLUSTER KUBERNETES
# Ce script nettoie TOUT sur tous les nœuds pour un état 100% propre

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-ultra-reset"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ultra-reset-$(date +%Y%m%d-%H%M%S).log"
SSH_KEY_BACKUP="$LOG_DIR/ssh-public-key-backup.txt"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - RESET ULTRA-COMPLET DU CLUSTER"
echo "Date: $(date)"
echo "=============================================="
echo ""
echo "⚠️  ATTENTION: Ce script va NETTOYER COMPLÈTEMENT Kubernetes sur tous les nœuds"
echo ""

# IPs des nœuds
MASTER1="10.0.0.100"
MASTER2="10.0.0.101"
MASTER3="10.0.0.102"
WORKERS="10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114"
ALL_NODES="$MASTER1 $MASTER2 $MASTER3 $WORKERS"

# Sauvegarder la clé SSH publique
echo "=== PHASE 0: Sauvegarde de la clé SSH publique ==="
SSH_PUB_KEY="/root/.ssh/id_rsa_keybuzz_v3.pub"
if [ -f "$SSH_PUB_KEY" ]; then
    cat "$SSH_PUB_KEY" > "$SSH_KEY_BACKUP"
    echo "[OK] Clé SSH publique sauvegardée dans: $SSH_KEY_BACKUP"
    echo ""
    echo "=== CLÉ SSH PUBLIQUE (à redéployer après rebuild) ==="
    cat "$SSH_KEY_BACKUP"
    echo ""
else
    echo "[WARN] Clé SSH publique non trouvée à $SSH_PUB_KEY"
fi

echo ""
echo "=== PHASE 1: Reset ULTRA-COMPLET de tous les nœuds ==="
for ip in $ALL_NODES; do
    echo "[INFO] Reset ultra-complet sur $ip..."
    ssh root@$ip bash << 'EOF' || echo "[WARN] Erreur sur $ip, continuation..."
# Arrêter tous les services
systemctl stop kubelet 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true
systemctl stop docker 2>/dev/null || true

# Tuer tous les processus Kubernetes/ETCD
pkill -9 kubelet || true
pkill -9 kube-apiserver || true
pkill -9 kube-scheduler || true
pkill -9 kube-controller-manager || true
pkill -9 etcd || true
pkill -9 calico || true
pkill -9 flannel || true

# Reset kubeadm
kubeadm reset -f --cri-socket unix:///var/run/containerd/containerd.sock 2>/dev/null || true

# Supprimer TOUS les répertoires Kubernetes
rm -rf /etc/kubernetes/*
rm -rf /var/lib/kubelet/*
rm -rf /var/lib/etcd/*
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/cni/*
rm -rf /run/flannel/*
rm -rf ~/.kube/*

# Nettoyer iptables
iptables -F || true
iptables -t nat -F || true
iptables -t mangle -F || true
iptables -X || true
iptables -t nat -X || true
iptables -t mangle -X || true

# Nettoyer IPVS
ipvsadm --clear 2>/dev/null || true

# Supprimer les interfaces réseau CNI
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete docker0 2>/dev/null || true

# Nettoyer les routes
ip route flush proto bird 2>/dev/null || true

# Recréer les répertoires vides
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/kubernetes/pki
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd

# Réinitialiser containerd
systemctl stop containerd 2>/dev/null || true
rm -rf /var/lib/containerd/*
rm -rf /run/containerd/*

# Réinitialiser containerd config
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Redémarrer containerd
systemctl start containerd
systemctl enable containerd

echo "Reset ultra-complet terminé sur $(hostname)"
EOF
done

echo ""
echo "=== PHASE 2: Attente 30s ==="
sleep 30

echo ""
echo "=== PHASE 3: Redémarrage de tous les nœuds pour base propre ==="
for ip in $ALL_NODES; do
    echo "[INFO] Redémarrage de $ip..."
    ssh root@$ip "reboot" 2>/dev/null || echo "[WARN] Erreur reboot sur $ip"
done

echo ""
echo "=== PHASE 4: Attente 2 minutes pour redémarrage ==="
sleep 120

echo ""
echo "=== PHASE 5: Vérification que les nœuds sont de retour ==="
TIMEOUT=600
ELAPSED=0
for ip in $ALL_NODES; do
    echo -n "Attente de $ip... "
    while [ $ELAPSED -lt $TIMEOUT ]; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$ip "echo OK" 2>/dev/null; then
            echo "✓ OK"
            break
        fi
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "✗ TIMEOUT"
    fi
done

echo ""
echo "=== PHASE 6: Attente stabilisation supplémentaire (60s) ==="
sleep 60

echo ""
echo "=============================================="
echo "RESET ULTRA-COMPLET TERMINÉ"
echo "=============================================="
echo ""
echo "⚠️  IMPORTANT: La clé SSH publique a été sauvegardée dans:"
echo "   $SSH_KEY_BACKUP"
echo ""
echo "📋 PROCHAINES ÉTAPES:"
echo "1. Vérifiez que tous les serveurs sont de retour"
echo "2. Redéployez la clé SSH publique depuis: $SSH_KEY_BACKUP"
echo "3. Une fois la clé redéployée, exécutez le script de bootstrap"
echo ""
echo "📄 Clé SSH publique à redéployer:"
echo "=============================================="
if [ -f "$SSH_KEY_BACKUP" ]; then
    cat "$SSH_KEY_BACKUP"
else
    cat "$SSH_PUB_KEY"
fi
echo "=============================================="
echo ""
echo "Logs complets: $LOG_FILE"

