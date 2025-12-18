#!/bin/bash
# PH9 - Correction finale control-plane (IP privées), stabilisation Calico/CoreDNS/ArgoCD/ESO
# Objectif : atteindre 100% Ready et composants OK
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-fix-final"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9-fix-final-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config
INFRA_DIR="/opt/keybuzz/keybuzz-infra"

masters=(
  "10.0.0.100 91.98.124.228"
  "10.0.0.101 91.98.117.26"
  "10.0.0.102 91.98.165.238"
)

patch_master() {
  priv=$1
  pub=$2
  echo "[INFO] Patch $priv (remplace $pub -> $priv, force etcd en IP privées)"
  ssh -o StrictHostKeyChecking=no root@"$priv" "
    set -e
    priv_ip=$priv
    pub_ip=$pub
    sed -i \"s/\${pub_ip}/\${priv_ip}/g\" /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--advertise-address=.*|--advertise-address=\${priv_ip}|g\" /etc/kubernetes/manifests/kube-apiserver.yaml
    sed -i \"s|--listen-client-urls=.*|--listen-client-urls=https://127.0.0.1:2379,https://\${priv_ip}:2379|g\" /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--advertise-client-urls=.*|--advertise-client-urls=https://\${priv_ip}:2379|g\" /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--initial-advertise-peer-urls=.*|--initial-advertise-peer-urls=https://\${priv_ip}:2380|g\" /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--listen-peer-urls=.*|--listen-peer-urls=https://\${priv_ip}:2380|g\" /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--initial-cluster-state=.*|--initial-cluster-state=existing|g\" /etc/kubernetes/manifests/etcd.yaml
    sed -i \"s|--initial-cluster=.*|--initial-cluster=k8s-master-01=https://10.0.0.100:2380,k8s-master-02=https://10.0.0.101:2380,k8s-master-03=https://10.0.0.102:2380|g\" /etc/kubernetes/manifests/etcd.yaml
  "
}

echo "[INFO] === Patch apiserver/etcd pour IP privées ==="
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  pub=$(echo "$entry"  | awk '{print $2}')
  patch_master "$priv" "$pub"
done

echo "[INFO] === Restart kubelet sur chaque master ==="
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  echo "[INFO] Restart kubelet sur $priv"
  ssh root@"$priv" "systemctl restart kubelet"
  sleep 10
done

echo "[INFO] Attente 60s pour stabilisation control-plane..."
sleep 60

echo "[INFO] Vérification etcd/apiserver (master-01)"
ssh root@10.0.0.100 "crictl ps -a | grep -E 'etcd|kube-apiserver' || true"

echo "[INFO] Vérification API (kubectl get nodes)..."
if ! kubectl get nodes; then
  echo "[WARN] API encore indisponible, nouvelle attente 30s"
  sleep 30
  kubectl get nodes || true
fi

echo "[INFO] === Stabilisation Calico ==="
kubectl delete pod -n kube-system -l k8s-app=calico-node --force --grace-period=0 || true
sleep 60
kubectl get pods -n kube-system -l k8s-app=calico-node

echo "[INFO] === Stabilisation CoreDNS ==="
kubectl delete pod -n kube-system -l k8s-app=kube-dns --force --grace-period=0 || true
sleep 30
kubectl get pods -n kube-system -l k8s-app=kube-dns

echo "[INFO] === Stabilisation ArgoCD (redéploiement pods en erreur) ==="
if kubectl get ns argocd >/dev/null 2>&1; then
  kubectl delete pod -n argocd -l app.kubernetes.io/name in '(argocd-repo-server,argocd-applicationset-controller,argocd-dex-server,argocd-server)' --force --grace-period=0 || true
  sleep 40
  kubectl get pods -n argocd
fi

echo "[INFO] === Stabilisation ESO (redéploiement pods) ==="
if kubectl get ns external-secrets >/dev/null 2>&1; then
  kubectl delete pod -n external-secrets --all --force --grace-period=0 || true
  sleep 40
  kubectl get pods -n external-secrets
fi

echo "[INFO] === État final ==="
kubectl get nodes -o wide || true
kubectl get pods -n kube-system | head -30 || true
kubectl get pods -n argocd 2>/dev/null || true
kubectl get pods -n external-secrets 2>/dev/null || true

echo "[INFO] Logs : $LOG_FILE"

