#!/bin/bash
# PH9 - Forcer apiserver/etcd en IP privées sur les 3 masters et redémarrer kubelet
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-fix-private"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9-fix-private-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

masters=(
  "10.0.0.100 91.98.124.228"
  "10.0.0.101 91.98.117.26"
  "10.0.0.102 91.98.165.238"
)

echo "[INFO] Patch apiserver/etcd pour IP privées (state=new) et wipe etcd data"
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  pub=$(echo "$entry"  | awk '{print $2}')
  echo "[INFO] Patch $priv (remplace $pub -> $priv, force etcd IP privées, state=existing)"
  ssh -o StrictHostKeyChecking=no root@"$priv" bash -c "'
set -e
sed -i s/$pub/$priv/g /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--advertise-address=.*|--advertise-address=$priv|\" /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i \"s|--etcd-servers=.*|--etcd-servers=https://127.0.0.1:2379|\" /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i \"s|--listen-client-urls=.*|--listen-client-urls=https://127.0.0.1:2379,https://$priv:2379|\" /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--advertise-client-urls=.*|--advertise-client-urls=https://$priv:2379|\" /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--initial-advertise-peer-urls=.*|--initial-advertise-peer-urls=https://$priv:2380|\" /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--listen-peer-urls=.*|--listen-peer-urls=https://$priv:2380|\" /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--initial-cluster-state=.*|--initial-cluster-state=new|\" /etc/kubernetes/manifests/etcd.yaml
sed -i \"s|--initial-cluster=.*|--initial-cluster=k8s-master-01=https://10.0.0.100:2380,k8s-master-02=https://10.0.0.101:2380,k8s-master-03=https://10.0.0.102:2380|\" /etc/kubernetes/manifests/etcd.yaml
systemctl stop kubelet
rm -rf /var/lib/etcd/*
systemctl start kubelet
'"
done

echo "[INFO] Attente 90s pour stabilisation..."
sleep 90

echo "[INFO] kubelet status (masters)"
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  echo "--- $priv ---"
  ssh root@"$priv" "systemctl is-active kubelet || true"
done

echo "[INFO] Vérification etcd leader (master-01)"
ssh root@10.0.0.100 "crictl ps | grep etcd && crictl logs \$(crictl ps --name etcd -q | head -1) | tail -40" || true

echo "[INFO] Test API (kubectl get nodes)"
export KUBECONFIG=/root/.kube/config
kubectl get nodes -o wide || true

echo "[INFO] Fin du patch. Relancer Calico/CoreDNS/ArgoCD/ESO si API OK."
echo "[INFO] Log: $LOG_FILE"

