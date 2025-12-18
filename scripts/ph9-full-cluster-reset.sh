#!/bin/bash
# PH9 - RESET COMPLET DU CLUSTER KUBERNETES
# Ce script réinitialise complètement le cluster pour un état 100% propre

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-full-reset"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/full-reset-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - RESET COMPLET DU CLUSTER KUBERNETES"
echo "Date: $(date)"
echo "=============================================="
echo ""

# IPs des nœuds
MASTER1="10.0.0.100"
MASTER2="10.0.0.101"
MASTER3="10.0.0.102"
WORKERS="10.0.0.110 10.0.0.111 10.0.0.112 10.0.0.113 10.0.0.114"
ALL_NODES="$MASTER1 $MASTER2 $MASTER3 $WORKERS"

echo "=== PHASE 1: Reset de tous les nœuds ==="
for ip in $ALL_NODES; do
    echo "[INFO] Resetting node $ip..."
    ssh root@$ip bash << 'EOF' || true
systemctl stop kubelet 2>/dev/null || true
pkill -9 kube-apiserver 2>/dev/null || true
pkill -9 kube-scheduler 2>/dev/null || true
pkill -9 kube-controller-manager 2>/dev/null || true
pkill -9 etcd 2>/dev/null || true
kubeadm reset -f --cri-socket unix:///var/run/containerd/containerd.sock 2>/dev/null || true
rm -rf /etc/kubernetes/*
rm -rf /var/lib/etcd/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/cni/*
rm -rf ~/.kube/*
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
ipvsadm --clear 2>/dev/null || true
mkdir -p /etc/kubernetes/manifests /etc/kubernetes/pki /var/lib/kubelet /var/lib/etcd
systemctl restart containerd
echo "Reset done on $(hostname)"
EOF
done

echo ""
echo "=== PHASE 2: Attente 10s ==="
sleep 10

echo ""
echo "=== PHASE 3: Initialisation de master-01 ==="
ssh root@$MASTER1 bash << 'EOF'
echo "[INFO] Running kubeadm init on master-01..."
kubeadm init \
    --apiserver-advertise-address=10.0.0.100 \
    --control-plane-endpoint=10.0.0.100:6443 \
    --pod-network-cidr=10.244.0.0/16 \
    --upload-certs \
    --cri-socket unix:///var/run/containerd/containerd.sock

echo "[INFO] Setting up kubeconfig..."
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
echo "Master-01 initialized"
EOF

echo ""
echo "=== PHASE 4: Copie du kubeconfig sur install-v3 ==="
scp root@$MASTER1:/etc/kubernetes/admin.conf /root/.kube/config
export KUBECONFIG=/root/.kube/config
echo "KUBECONFIG copied"

echo ""
echo "=== PHASE 5: Installation de Calico ==="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
echo "Calico applied"

echo ""
echo "=== PHASE 6: Attente 60s pour stabilisation master-01 ==="
sleep 60

echo ""
echo "=== PHASE 7: Génération des commandes JOIN ==="
# Générer CERT_KEY et TOKEN
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
echo "CERT_KEY: $CERT_KEY"

TOKEN=$(ssh root@$MASTER1 "kubeadm token create --ttl 4h")
echo "TOKEN: $TOKEN"

# Discovery hash
DISCOVERY_HASH=$(ssh root@$MASTER1 "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
echo "DISCOVERY_HASH: sha256:$DISCOVERY_HASH"

JOIN_MASTER="kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$DISCOVERY_HASH --control-plane --certificate-key $CERT_KEY"
JOIN_WORKER="kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$DISCOVERY_HASH"

echo "$JOIN_MASTER" > $LOG_DIR/join-master.txt
echo "$JOIN_WORKER" > $LOG_DIR/join-worker.txt

echo ""
echo "=== PHASE 8: Join master-02 ==="
ssh root@$MASTER2 bash << EOF
systemctl enable kubelet
systemctl start kubelet
$JOIN_MASTER --apiserver-advertise-address=10.0.0.101
EOF
echo "Master-02 joined"

echo ""
echo "=== PHASE 9: Attente 60s pour stabilisation master-02 ==="
sleep 60

echo ""
echo "=== PHASE 10: Join master-03 ==="
# Regénérer CERT_KEY (expire vite)
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
JOIN_MASTER="kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$DISCOVERY_HASH --control-plane --certificate-key $CERT_KEY"

ssh root@$MASTER3 bash << EOF
systemctl enable kubelet
systemctl start kubelet
$JOIN_MASTER --apiserver-advertise-address=10.0.0.102
EOF
echo "Master-03 joined"

echo ""
echo "=== PHASE 11: Attente 60s pour stabilisation master-03 ==="
sleep 60

echo ""
echo "=== PHASE 12: Join des 5 workers ==="
for ip in $WORKERS; do
    echo "[INFO] Joining worker $ip..."
    ssh root@$ip bash << EOF
systemctl enable kubelet
systemctl start kubelet
$JOIN_WORKER
EOF
    echo "Worker $ip joined"
done

echo ""
echo "=== PHASE 13: Attente 90s pour stabilisation des workers ==="
sleep 90

echo ""
echo "=== PHASE 14: Vérification du cluster ==="
echo "[INFO] Nodes:"
kubectl get nodes -o wide

echo ""
echo "[INFO] Control Plane pods:"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-'

echo ""
echo "[INFO] Calico pods:"
kubectl get pods -n kube-system -l k8s-app=calico-node

echo ""
echo "[INFO] kube-proxy pods:"
kubectl get pods -n kube-system -l k8s-app=kube-proxy

echo ""
echo "=== PHASE 15: Installation ESO ==="
kubectl create namespace external-secrets 2>/dev/null || true
helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true \
    --wait --timeout 5m || echo "WARN: Helm install may have timed out"

echo ""
echo "=== PHASE 16: Vérification ESO ==="
sleep 30
kubectl get pods -n external-secrets

echo ""
echo "=== PHASE 17: État final du cluster ==="
echo "[INFO] Final Nodes:"
kubectl get nodes -o wide

echo ""
echo "[INFO] Final Control Plane:"
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-'

echo ""
echo "[INFO] Final Calico:"
kubectl get pods -n kube-system -l k8s-app=calico-node

echo ""
echo "[INFO] Final kube-proxy:"
kubectl get pods -n kube-system -l k8s-app=kube-proxy

echo ""
echo "[INFO] Final ESO:"
kubectl get pods -n external-secrets

echo ""
echo "=============================================="
echo "PH9 RESET COMPLET TERMINÉ"
echo "Logs: $LOG_FILE"
echo "=============================================="

