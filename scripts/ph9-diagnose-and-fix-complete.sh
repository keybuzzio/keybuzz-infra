#!/bin/bash
# PH9 - Diagnostic et correction complète jusqu'à 100% OK
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-diagnose"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-diagnose-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - DIAGNOSTIC ET CORRECTION COMPLÈTE"
echo "Date: $(date)"
echo "=============================================="
echo ""

MASTER01="10.0.0.100"

# Diagnostic sur master-01
echo "=== Diagnostic sur master-01 ==="
echo ""

echo "[INFO] Vérification de containerd..."
ssh root@$MASTER01 "systemctl is-active containerd"

echo "[INFO] Vérification de kubelet..."
ssh root@$MASTER01 "systemctl is-active kubelet"

echo "[INFO] Vérification des conteneurs control-plane..."
ssh root@$MASTER01 "crictl ps -a" 2>&1 | grep -E "kube-apiserver|etcd|kube-controller|kube-scheduler" || echo "Aucun conteneur control-plane trouvé"

echo ""
echo "[INFO] Logs kubelet récents..."
ssh root@$MASTER01 "journalctl -u kubelet -n 100 --no-pager | grep -E 'error|Error|ERROR|fatal|Fatal|FAILED' | tail -20" || echo "Pas d'erreurs récentes dans kubelet"

echo ""
echo "[INFO] Vérification des manifests..."
ssh root@$MASTER01 "ls -la /etc/kubernetes/manifests/"

echo ""
echo "[INFO] Tentative de redémarrage de kubelet..."
ssh root@$MASTER01 "systemctl restart kubelet && sleep 10 && systemctl status kubelet --no-pager | head -10"

echo ""
echo "[INFO] Attente que les pods démarrent..."
sleep 30

echo "[INFO] Vérification des conteneurs après redémarrage..."
ssh root@$MASTER01 "crictl ps -a" 2>&1 | grep -E "kube-apiserver|etcd" || echo "Conteneurs non démarrés"

# Vérifier si le port 6443 est maintenant ouvert
echo ""
echo "[INFO] Vérification du port 6443..."
for i in {1..30}; do
    if ssh root@$MASTER01 "ss -tlnp | grep -q 6443 || netstat -tlnp | grep -q 6443"; then
        echo "[OK] Port 6443 ouvert"
        break
    fi
    echo "[INFO] Attente port 6443... ($i/30)"
    sleep 5
done

# Copier kubeconfig et vérifier
echo ""
echo "[INFO] Copie du kubeconfig..."
mkdir -p /root/.kube
scp root@$MASTER01:/etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || true

export KUBECONFIG=/root/.kube/config

# Vérifier l'accès au cluster
echo ""
echo "[INFO] Vérification de l'accès au cluster..."
for i in {1..20}; do
    if kubectl get nodes &>/dev/null 2>&1; then
        echo "[OK] Cluster accessible"
        kubectl get nodes -o wide
        break
    fi
    echo "[INFO] Attente cluster... ($i/20)"
    sleep 5
done

echo ""
echo "=============================================="
echo "DIAGNOSTIC TERMINÉ"
echo "=============================================="

