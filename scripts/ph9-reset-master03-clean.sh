#!/bin/bash
# PH9 - Reset complet et réintégration propre de master-03
# IMPORTANT: Ce script ne touche QUE master-03
# master-01 et master-02 restent intacts

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-reset-master03"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/reset-master03-$(date +%Y%m%d-%H%M%S).log"

MASTER1="10.0.0.100"
MASTER2="10.0.0.101"
MASTER3="10.0.0.102"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - RESET COMPLET MASTER-03"
echo "Date: $(date)"
echo "=============================================="
echo ""
echo "⚠️  Ce script ne touche QUE master-03"
echo "✅ master-01 et master-02 restent intacts"
echo ""

# Vérification préalable
echo "=== PHASE 0: Vérification préalable ==="
export KUBECONFIG=/root/.kube/config

echo "[INFO] État actuel des nodes..."
kubectl get nodes -o wide || true

echo ""
echo "[INFO] État ETCD actuel..."
ssh root@$MASTER1 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "$ETCD_CTR" ]; then
    crictl exec $ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list -w table
fi
EOF

echo ""
echo "=== PHASE 1: Retirer master-03 de l'ETCD (depuis master-01) ==="

# Récupérer l'ID du membre master-03 dans ETCD
ETCD_MEMBER_ID=$(ssh root@$MASTER1 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "$ETCD_CTR" ]; then
    crictl exec $ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list | grep "k8s-master-03" | awk -F',' '{print $1}'
fi
EOF
)

if [ -n "$ETCD_MEMBER_ID" ]; then
    echo "[INFO] Removing master-03 (ID: $ETCD_MEMBER_ID) from ETCD cluster..."
    ssh root@$MASTER1 bash << EOF
ETCD_CTR=\$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "\$ETCD_CTR" ]; then
    crictl exec \$ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member remove $ETCD_MEMBER_ID
fi
EOF
    echo "[OK] master-03 retiré de l'ETCD"
else
    echo "[INFO] master-03 n'est pas dans l'ETCD ou déjà retiré"
fi

echo ""
echo "=== PHASE 2: Supprimer le node master-03 de Kubernetes ==="
kubectl delete node k8s-master-03 --force --grace-period=0 2>/dev/null || echo "[INFO] Node déjà supprimé ou inexistant"

echo ""
echo "=== PHASE 3: Reset complet de master-03 ==="
ssh root@$MASTER3 bash << 'EOF'
echo "[INFO] Stopping kubelet..."
systemctl stop kubelet || true

echo "[INFO] Killing all kube processes..."
pkill -9 kube-apiserver || true
pkill -9 kube-scheduler || true
pkill -9 kube-controller-manager || true
pkill -9 etcd || true

echo "[INFO] Running kubeadm reset..."
kubeadm reset -f --cri-socket unix:///var/run/containerd/containerd.sock || true

echo "[INFO] Cleaning directories..."
rm -rf /etc/kubernetes/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/cni/*
rm -rf ~/.kube/*

echo "[INFO] Recreating directories..."
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/kubernetes/pki
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/etcd

echo "[INFO] Restarting containerd..."
systemctl restart containerd
sleep 5

echo "[INFO] Verifying containerd..."
systemctl status containerd --no-pager | head -5

echo "[OK] master-03 reset complete"
EOF

echo ""
echo "=== PHASE 4: Vérifier que l'ETCD a bien 2 membres ==="
ssh root@$MASTER1 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "$ETCD_CTR" ]; then
    echo "ETCD member list après retrait de master-03:"
    crictl exec $ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list -w table
fi
EOF

echo ""
echo "=== PHASE 5: Générer CERT_KEY et TOKEN pour rejoindre ==="

# Générer un nouveau certificate-key
CERT_KEY=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
echo "[INFO] CERT_KEY: $CERT_KEY"

# Créer un nouveau token
TOKEN=$(ssh root@$MASTER1 "export KUBECONFIG=/etc/kubernetes/admin.conf && kubeadm token create --ttl 2h 2>/dev/null")
echo "[INFO] TOKEN: $TOKEN"

# Construire la commande join
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER3"

echo "[INFO] JOIN_CMD: $JOIN_CMD"
echo "$JOIN_CMD" > $LOG_DIR/join-cmd.txt

echo ""
echo "=== PHASE 6: Rejoindre master-03 au cluster ==="
ssh root@$MASTER3 bash << EOF
echo "[INFO] Starting kubelet..."
systemctl enable kubelet
systemctl start kubelet

echo "[INFO] Executing kubeadm join..."
$JOIN_CMD

echo "[INFO] Waiting 30s for stabilization..."
sleep 30

echo "[INFO] Kubelet status..."
systemctl status kubelet --no-pager | head -10
EOF

echo ""
echo "=== PHASE 7: Attendre la stabilisation (120s) ==="
sleep 120

echo ""
echo "=== PHASE 8: Vérification du cluster ==="

echo "[INFO] Nodes:"
kubectl get nodes -o wide

echo ""
echo "[INFO] Control plane pods:"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-'

echo ""
echo "[INFO] ETCD members:"
ssh root@$MASTER1 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -n "$ETCD_CTR" ]; then
    crictl exec $ETCD_CTR etcdctl \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        member list -w table
fi
EOF

echo ""
echo "=== PHASE 9: Stabiliser Calico et kube-proxy ==="

echo "[INFO] Restarting Calico pods..."
kubectl delete pods -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>/dev/null || true

echo "[INFO] Restarting kube-proxy pods..."
kubectl delete pods -n kube-system -l k8s-app=kube-proxy --force --grace-period=0 2>/dev/null || true

echo "[INFO] Waiting 90s for network stabilization..."
sleep 90

echo ""
echo "=== PHASE 10: Stabiliser ESO ==="
kubectl delete pods -n external-secrets --all --force --grace-period=0 2>/dev/null || true
sleep 60

echo ""
echo "=== PHASE 11: Vérification finale ==="

echo "[INFO] Final nodes status:"
kubectl get nodes -o wide

echo ""
echo "[INFO] Final control plane status:"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-'

echo ""
echo "[INFO] Final Calico status:"
kubectl get pods -n kube-system -l k8s-app=calico-node

echo ""
echo "[INFO] Final kube-proxy status:"
kubectl get pods -n kube-system -l k8s-app=kube-proxy

echo ""
echo "[INFO] Final ESO status:"
kubectl get pods -n external-secrets

echo ""
echo "=============================================="
echo "PH9 RESET MASTER-03 TERMINÉ"
echo "Logs: $LOG_FILE"
echo "=============================================="

