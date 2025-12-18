#!/bin/bash
# Corrige les IP publiques vers IP privées dans les manifests apiserver/etcd et relance kubelet
set -e

masters=(
  "10.0.0.100 91.98.124.228"
  "10.0.0.101 91.98.117.26"
  "10.0.0.102 91.98.165.238"
)

# Met à jour les manifests kube-apiserver et etcd pour utiliser les IP privées
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  pub=$(echo "$entry" | awk '{print $2}')
  echo "[INFO] Patch $priv (remplace $pub -> $priv)"
  ssh -o StrictHostKeyChecking=no root@"$priv" "sed -i s/$pub/$priv/g /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/etcd.yaml"
  ssh root@"$priv" "sed -i 's|initial-cluster=.*|initial-cluster=k8s-master-01=https://10.0.0.100:2380,k8s-master-02=https://10.0.0.101:2380,k8s-master-03=https://10.0.0.102:2380|; s|initial-cluster-state=new|initial-cluster-state=existing|' /etc/kubernetes/manifests/etcd.yaml"
done

# Redémarre kubelet sur chaque master pour recharger les manifests
for entry in "${masters[@]}"; do
  priv=$(echo "$entry" | awk '{print $1}')
  echo "[INFO] Restart kubelet sur $priv"
  ssh root@"$priv" "systemctl restart kubelet"
done

echo "[OK] Patch terminé. Attendre la stabilisation (60s)"
sleep 60

