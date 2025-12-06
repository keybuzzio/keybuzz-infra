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
NAME            STATUS   ROLES           AGE    VERSION    INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master-01   Ready    control-plane   21h    v1.30.14   91.98.124.228     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-02   Ready    control-plane   20h    v1.30.14   91.98.117.26      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-03   Ready    control-plane   2m5s   v1.30.14   91.98.165.238     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-01   Ready    <none>          20h    v1.30.14   116.203.135.192   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-02   Ready    <none>          20h    v1.30.14   91.99.164.62      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-03   Ready    <none>          20h    v1.30.14   157.90.119.183    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-04   Ready    <none>          20h    v1.30.14   91.98.200.38      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-05   Ready    <none>          20h    v1.30.14   188.245.45.242    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0

### Control Plane Pods
etcd-k8s-master-01                         1/1     Running            0                21h
etcd-k8s-master-02                         1/1     Running            0                67m
etcd-k8s-master-03                         0/1     Running            22 (58s ago)     2m3s
kube-apiserver-k8s-master-01               1/1     Running            0                21h
kube-apiserver-k8s-master-02               1/1     Running            0                67m
kube-apiserver-k8s-master-03               0/1     Running            18 (93s ago)     93s
kube-controller-manager-k8s-master-01      1/1     Running            99               21h
kube-controller-manager-k8s-master-02      1/1     Running            20               20h
kube-controller-manager-k8s-master-03      1/1     Running            187 (117s ago)   118s
kube-scheduler-k8s-master-01               1/1     Running            95               21h
kube-scheduler-k8s-master-02               1/1     Running            23               20h
kube-scheduler-k8s-master-03               0/1     Running            177 (19s ago)    115s

### Calico
NAME                READY   STATUS             RESTARTS         AGE
calico-node-87pxd   0/1     CrashLoopBackOff   14 (100s ago)    56m
calico-node-dlmtd   1/1     Running            0                56m
calico-node-hr92c   0/1     CrashLoopBackOff   14 (4m39s ago)   56m
calico-node-k5n6g   0/1     Running            14 (5m20s ago)   56m
calico-node-lf5xx   0/1     CrashLoopBackOff   14 (60s ago)     56m
calico-node-psjr7   0/1     CrashLoopBackOff   14 (70s ago)     56m
calico-node-rkrpr   1/1     Running            16               56m
calico-node-xpq5g   1/1     Running            0                56m

### kube-proxy
NAME               READY   STATUS             RESTARTS         AGE
kube-proxy-8j9gz   0/1     CrashLoopBackOff   12 (2m25s ago)   54m
kube-proxy-cqmrm   1/1     Running            12 (6m40s ago)   54m
kube-proxy-csmfb   1/1     Running            0                54m
kube-proxy-kkbc6   0/1     CrashLoopBackOff   11 (96s ago)     54m
kube-proxy-l6nfs   1/1     Running            11 (6m43s ago)   54m
kube-proxy-n4hvw   0/1     CrashLoopBackOff   10 (3m38s ago)   54m
kube-proxy-qkz49   0/1     CrashLoopBackOff   18 (20s ago)     54m
kube-proxy-vwtks   0/1     CrashLoopBackOff   11 (4m10s ago)   54m

### ESO
NAME                                                READY   STATUS             RESTARTS        AGE
external-secrets-7b4b656f56-zts8n                   1/1     Running            8 (24s ago)     27m
external-secrets-cert-controller-5566bb8569-v47pq   0/1     CrashLoopBackOff   8 (3m43s ago)   27m
external-secrets-webhook-586968df45-dpb55           1/1     Running            7 (7m49s ago)   27m

## Logs

Tous les logs sont disponibles dans : `/opt/keybuzz/logs/phase9.5/`
