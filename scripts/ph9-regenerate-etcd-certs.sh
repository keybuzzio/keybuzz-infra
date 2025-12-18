#!/bin/bash
# Régénère les certs etcd/apiserver-etcd-client sur master-01 et distribue vers master-02/03
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-etcd-certs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9-etcd-certs-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

MASTER1=10.0.0.100
MASTER2=10.0.0.101
MASTER3=10.0.0.102

echo "[INFO] Stop kubelet master-01"
ssh root@$MASTER1 "systemctl stop kubelet"

TS=$(date +%Y%m%d-%H%M%S)
echo "[INFO] Backup PKI etcd master-01"
ssh root@$MASTER1 "mkdir -p /etc/kubernetes/pki/etcd-bak-$TS && cp -a /etc/kubernetes/pki/etcd/* /etc/kubernetes/pki/etcd-bak-$TS/"

echo "[INFO] Regenerate etcd certs on master-01"
ssh root@$MASTER1 "kubeadm init phase certs etcd-ca --cert-dir /etc/kubernetes/pki/etcd || true"
ssh root@$MASTER1 "kubeadm init phase certs etcd-server --cert-dir /etc/kubernetes/pki/etcd"
ssh root@$MASTER1 "kubeadm init phase certs etcd-peer --cert-dir /etc/kubernetes/pki/etcd"
ssh root@$MASTER1 "kubeadm init phase certs etcd-healthcheck-client --cert-dir /etc/kubernetes/pki/etcd"
ssh root@$MASTER1 "kubeadm init phase certs apiserver-etcd-client --cert-dir /etc/kubernetes/pki"

echo "[INFO] Distribute PKI to master-02 and master-03"
ssh root@$MASTER1 "tar czf /tmp/etcd-pki-$TS.tgz -C /etc/kubernetes/pki etcd apiserver-etcd-client.crt apiserver-etcd-client.key"
scp root@$MASTER1:/tmp/etcd-pki-$TS.tgz root@$MASTER2:/tmp/
scp root@$MASTER1:/tmp/etcd-pki-$TS.tgz root@$MASTER3:/tmp/
ssh root@$MASTER2 "systemctl stop kubelet && rm -rf /etc/kubernetes/pki/etcd && tar xzf /tmp/etcd-pki-$TS.tgz -C /etc/kubernetes/pki"
ssh root@$MASTER3 "systemctl stop kubelet && rm -rf /etc/kubernetes/pki/etcd && tar xzf /tmp/etcd-pki-$TS.tgz -C /etc/kubernetes/pki"

echo "[INFO] Wipe /var/lib/etcd on 3 masters"
ssh root@$MASTER1 "rm -rf /var/lib/etcd/*"
ssh root@$MASTER2 "rm -rf /var/lib/etcd/*"
ssh root@$MASTER3 "rm -rf /var/lib/etcd/*"

echo "[INFO] Start kubelet in order 01 -> 02 -> 03"
ssh root@$MASTER1 "systemctl start kubelet"
sleep 40
ssh root@$MASTER2 "systemctl start kubelet"
sleep 40
ssh root@$MASTER3 "systemctl start kubelet"

echo "[INFO] Check etcd on master-01"
ssh root@$MASTER1 "crictl ps | grep etcd && crictl logs \$(crictl ps --name etcd -q | head -1) | tail -50" || true

echo "[INFO] Test API"
export KUBECONFIG=/root/.kube/config
kubectl get nodes -o wide || true

echo "[INFO] Log: $LOG_FILE"

