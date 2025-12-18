#!/bin/bash
# Régénération PKI etcd en SAN privés (10.0.0.100/101/102) et redémarrage kubelet
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-etcd-private"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9-etcd-private-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

M1=10.0.0.100
M2=10.0.0.101
M3=10.0.0.102

echo "[INFO] Stop kubelet sur les 3 masters"
ssh root@$M1 "systemctl stop kubelet"
ssh root@$M2 "systemctl stop kubelet"
ssh root@$M3 "systemctl stop kubelet"

echo "[INFO] Wipe /var/lib/etcd sur les 3 masters"
ssh root@$M1 "rm -rf /var/lib/etcd/*"
ssh root@$M2 "rm -rf /var/lib/etcd/*"
ssh root@$M3 "rm -rf /var/lib/etcd/*"

echo "[INFO] Regenerate PKI etcd sur master-01 (SAN privés uniquement)"
ssh root@$M1 "rm -rf /etc/kubernetes/pki/etcd && mkdir -p /etc/kubernetes/pki/etcd"
ssh root@$M1 "kubeadm init phase certs etcd-ca --cert-dir /etc/kubernetes/pki/etcd || true"
ssh root@$M1 "cat >/tmp/etcd-sans.yaml <<'EOF'
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
etcd:
  local:
    serverCertSANs:
    - 10.0.0.100
    - 10.0.0.101
    - 10.0.0.102
    peerCertSANs:
    - 10.0.0.100
    - 10.0.0.101
    - 10.0.0.102
EOF"
ssh root@$M1 "kubeadm init phase certs etcd-server --config /tmp/etcd-sans.yaml"
ssh root@$M1 "kubeadm init phase certs etcd-peer --config /tmp/etcd-sans.yaml"
ssh root@$M1 "kubeadm init phase certs etcd-healthcheck-client --cert-dir /etc/kubernetes/pki/etcd"
ssh root@$M1 "kubeadm init phase certs apiserver-etcd-client --cert-dir /etc/kubernetes/pki"

echo "[INFO] Distribuer PKI vers master-02 et master-03"
ssh root@$M1 "tar czf /tmp/etcd-pki-sans.tgz -C /etc/kubernetes/pki etcd apiserver-etcd-client.crt apiserver-etcd-client.key"
scp root@$M1:/tmp/etcd-pki-sans.tgz root@$M2:/tmp/
scp root@$M1:/tmp/etcd-pki-sans.tgz root@$M3:/tmp/
ssh root@$M2 "rm -rf /etc/kubernetes/pki/etcd && tar xzf /tmp/etcd-pki-sans.tgz -C /etc/kubernetes/pki"
ssh root@$M3 "rm -rf /etc/kubernetes/pki/etcd && tar xzf /tmp/etcd-pki-sans.tgz -C /etc/kubernetes/pki"

echo "[INFO] Forcer initial-cluster-state=new et IP privées dans etcd.yaml"
for m in $M1 $M2 $M3; do
  ssh root@$m "sed -i \"s|--initial-cluster-state=.*|--initial-cluster-state=new|\" /etc/kubernetes/manifests/etcd.yaml"
  ssh root@$m "sed -i \"s|--initial-cluster=.*|--initial-cluster=k8s-master-01=https://10.0.0.100:2380,k8s-master-02=https://10.0.0.101:2380,k8s-master-03=https://10.0.0.102:2380|\" /etc/kubernetes/manifests/etcd.yaml"
done

echo "[INFO] Redémarrage kubelet ordre 01 -> 02 -> 03"
ssh root@$M1 "systemctl start kubelet"
sleep 40
ssh root@$M2 "systemctl start kubelet"
sleep 40
ssh root@$M3 "systemctl start kubelet"
sleep 40

echo "[INFO] Vérif etcd master-01"
ssh root@$M1 "crictl ps | grep etcd && crictl logs \$(crictl ps --name etcd -q | head -1) | tail -60" || true

echo "[INFO] Test API"
export KUBECONFIG=/root/.kube/config
kubectl get nodes -o wide || true

echo "[INFO] Log: $LOG_FILE"

