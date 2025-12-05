# PH9 FINAL VALIDATION — Kubernetes v3 + ArgoCD + ESO + Vault

**Date:** Fri Dec  5 06:10:45 PM UTC 2025

## Summary

- Nodes Ready: 8/8
- API Servers Running: 2/3
- ETCD Pods Running: 1/3
- ESO Pods Running: 1/1
- Secret redis-test-secret: YES
- Pods in CrashLoopBackOff: 17

## Nodes
```
NAME            STATUS     ROLES           AGE     VERSION    INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master-01   Ready      control-plane   7h35m   v1.30.14   91.98.124.228     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-02   NotReady   control-plane   6h40m   v1.30.14   91.98.117.26      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-03   NotReady   control-plane   6h37m   v1.30.14   91.98.165.238     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-01   Ready      <none>          6h35m   v1.30.14   116.203.135.192   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-02   Ready      <none>          6h35m   v1.30.14   91.99.164.62      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-03   Ready      <none>          6h35m   v1.30.14   157.90.119.183    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-04   Ready      <none>          6h35m   v1.30.14   91.98.200.38      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-05   Ready      <none>          6h35m   v1.30.14   188.245.45.242    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
```

## Pods (kube-system)
```
NAME                                       READY   STATUS             RESTARTS         AGE     IP                NODE            NOMINATED NODE   READINESS GATES
calico-kube-controllers-564985c589-7nv5n   0/1     CrashLoopBackOff   60 (3m40s ago)   6h58m   10.244.151.129    k8s-master-01   <none>           <none>
calico-node-6wpxn                          1/1     Running            0                5h9m    91.98.117.26      k8s-master-02   <none>           <none>
calico-node-7cb99                          0/1     CrashLoopBackOff   60 (4m25s ago)   5h9m    91.98.200.38      k8s-worker-04   <none>           <none>
calico-node-bs2q7                          0/1     CrashLoopBackOff   60 (74s ago)     5h9m    157.90.119.183    k8s-worker-03   <none>           <none>
calico-node-mw4pm                          1/1     Running            59 (21m ago)     5h9m    91.98.165.238     k8s-master-03   <none>           <none>
calico-node-p5n2w                          0/1     CrashLoopBackOff   60 (4m14s ago)   5h9m    188.245.45.242    k8s-worker-05   <none>           <none>
calico-node-q65dv                          1/1     Running            0                5h9m    91.98.124.228     k8s-master-01   <none>           <none>
calico-node-r6mc5                          0/1     CrashLoopBackOff   59 (3m54s ago)   5h9m    116.203.135.192   k8s-worker-01   <none>           <none>
calico-node-xlxx4                          0/1     Running            60 (5m14s ago)   5h9m    91.99.164.62      k8s-worker-02   <none>           <none>
coredns-55cb58b774-q7bcw                   1/1     Running            0                7h35m   10.244.151.130    k8s-master-01   <none>           <none>
coredns-55cb58b774-z4gv8                   1/1     Running            0                7h35m   10.244.151.131    k8s-master-01   <none>           <none>
etcd-k8s-master-01                         1/1     Running            0                7h35m   91.98.124.228     k8s-master-01   <none>           <none>
etcd-k8s-master-02                         0/1     CrashLoopBackOff   26 (14m ago)     6h32m   91.98.117.26      k8s-master-02   <none>           <none>
kube-apiserver-k8s-master-01               1/1     Running            0                7h35m   91.98.124.228     k8s-master-01   <none>           <none>
kube-apiserver-k8s-master-02               0/1     Running            25 (16m ago)     6h32m   91.98.117.26      k8s-master-02   <none>           <none>
kube-apiserver-k8s-master-03               0/1     CrashLoopBackOff   91 (12m ago)     6h32m   91.98.165.238     k8s-master-03   <none>           <none>
kube-controller-manager-k8s-master-01      1/1     Running            99               7h35m   91.98.124.228     k8s-master-01   <none>           <none>
kube-controller-manager-k8s-master-02      1/1     Running            18               6h40m   91.98.117.26      k8s-master-02   <none>           <none>
kube-controller-manager-k8s-master-03      0/1     CrashLoopBackOff   84 (12m ago)     6h37m   91.98.165.238     k8s-master-03   <none>           <none>
kube-proxy-4zkww                           0/1     CrashLoopBackOff   53 (3m40s ago)   5h9m    116.203.135.192   k8s-worker-01   <none>           <none>
kube-proxy-b2zgf                           0/1     CrashLoopBackOff   54 (3m38s ago)   5h9m    157.90.119.183    k8s-worker-03   <none>           <none>
kube-proxy-g9ntt                           0/1     CrashLoopBackOff   63 (13m ago)     5h9m    91.98.165.238     k8s-master-03   <none>           <none>
kube-proxy-kjsfh                           1/1     Running            50 (109s ago)    5h9m    91.98.200.38      k8s-worker-04   <none>           <none>
kube-proxy-q8qk2                           1/1     Running            0                25m     91.98.117.26      k8s-master-02   <none>           <none>
kube-proxy-qsz5m                           1/1     Running            53 (5m8s ago)    5h9m    91.98.124.228     k8s-master-01   <none>           <none>
kube-proxy-rgl8r                           0/1     CrashLoopBackOff   53 (19s ago)     5h9m    188.245.45.242    k8s-worker-05   <none>           <none>
kube-proxy-xtjcd                           1/1     Running            52 (5m59s ago)   5h9m    91.99.164.62      k8s-worker-02   <none>           <none>
kube-scheduler-k8s-master-01               1/1     Running            95               7h35m   91.98.124.228     k8s-master-01   <none>           <none>
kube-scheduler-k8s-master-02               1/1     Running            21               6h40m   91.98.117.26      k8s-master-02   <none>           <none>
kube-scheduler-k8s-master-03               1/1     Running            79 (15m ago)     6h37m   91.98.165.238     k8s-master-03   <none>           <none>
```

## Pods (external-secrets)
```
NAME                                                READY   STATUS             RESTARTS         AGE     IP              NODE            NOMINATED NODE   READINESS GATES
external-secrets-7b4b656f56-f5g2q                   1/1     Running            70 (5m49s ago)   5h49m   10.244.78.244   k8s-worker-04   <none>           <none>
external-secrets-cert-controller-5566bb8569-dx5vm   0/1     Running            75 (25s ago)     6h33m   10.244.78.245   k8s-worker-04   <none>           <none>
external-secrets-webhook-586968df45-gbmj6           0/1     CrashLoopBackOff   77 (5m7s ago)    6h33m   10.244.55.217   k8s-worker-05   <none>           <none>
```

## Pods (argocd)
```
NAME                                               READY   STATUS             RESTARTS         AGE     IP              NODE            NOMINATED NODE   READINESS GATES
argocd-application-controller-0                    0/1     CrashLoopBackOff   71 (39s ago)     6h34m   10.244.36.218   k8s-worker-01   <none>           <none>
argocd-applicationset-controller-b776d8994-bmzl5   1/1     Running            66 (3m53s ago)   6h34m   10.244.7.151    k8s-worker-03   <none>           <none>
argocd-dex-server-95957787c-lmmk5                  1/1     Running            76 (8m3s ago)    6h34m   10.244.78.243   k8s-worker-04   <none>           <none>
argocd-notifications-controller-64964d4df5-gw62j   0/1     CrashLoopBackOff   64 (2m48s ago)   6h34m   10.244.118.71   k8s-worker-02   <none>           <none>
argocd-redis-75876db6bf-zjcsq                      1/1     Running            80 (9m3s ago)    6h34m   10.244.36.220   k8s-worker-01   <none>           <none>
argocd-repo-server-78dd5855d7-q56s6                0/1     CrashLoopBackOff   90 (3m47s ago)   6h34m   10.244.55.215   k8s-worker-05   <none>           <none>
argocd-server-69854449cd-pvz4v                     0/1     CrashLoopBackOff   72 (4m3s ago)    6h34m   10.244.7.139    k8s-worker-03   <none>           <none>
```
