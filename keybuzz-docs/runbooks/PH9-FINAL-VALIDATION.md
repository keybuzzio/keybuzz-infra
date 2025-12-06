# PH9 FINAL VALIDATION — Kubernetes HA (3 masters), ESO, ArgoCD, Vault

**Date:** Sat Dec  6 12:30:14 AM UTC 2025

## Summary

- Nodes Ready: 8/8
- API Servers Running: 2/3
- ETCD Pods Running: 1/3
- Calico Nodes Running: 4/8
- kube-proxy Running: 5/8
- ESO Pods Running: 1/1

## Nodes
```
NAME            STATUS   ROLES           AGE   VERSION    INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master-01   Ready    control-plane   13h   v1.30.14   91.98.124.228     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-02   Ready    control-plane   12h   v1.30.14   91.98.117.26      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-03   Ready    control-plane   12h   v1.30.14   91.98.165.238     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-01   Ready    <none>          12h   v1.30.14   116.203.135.192   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-02   Ready    <none>          12h   v1.30.14   91.99.164.62      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-03   Ready    <none>          12h   v1.30.14   157.90.119.183    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-04   Ready    <none>          12h   v1.30.14   91.98.200.38      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-05   Ready    <none>          12h   v1.30.14   188.245.45.242    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
```

## kube-system pods
```
NAME                                       READY   STATUS             RESTARTS         AGE     IP                NODE            NOMINATED NODE   READINESS GATES
calico-kube-controllers-564985c589-bsmz4   0/1     CrashLoopBackOff   3 (18s ago)      3m35s   10.244.118.77     k8s-worker-02   <none>           <none>
calico-node-62jtg                          1/1     Running            0                3m36s   91.98.117.26      k8s-master-02   <none>           <none>
calico-node-6vltf                          0/1     Running            4 (58s ago)      3m35s   116.203.135.192   k8s-worker-01   <none>           <none>
calico-node-fdx4m                          1/1     Running            1 (93s ago)      3m36s   91.98.165.238     k8s-master-03   <none>           <none>
calico-node-fzwbf                          0/1     CrashLoopBackOff   4 (17s ago)      3m35s   91.99.164.62      k8s-worker-02   <none>           <none>
calico-node-hhww4                          1/1     Running            0                3m35s   91.98.124.228     k8s-master-01   <none>           <none>
calico-node-lhptd                          0/1     CrashLoopBackOff   3 (45s ago)      3m36s   91.98.200.38      k8s-worker-04   <none>           <none>
calico-node-mvzxd                          0/1     CrashLoopBackOff   4 (45s ago)      3m35s   188.245.45.242    k8s-worker-05   <none>           <none>
calico-node-vnlxd                          0/1     Completed          4                3m36s   157.90.119.183    k8s-worker-03   <none>           <none>
coredns-55cb58b774-q7bcw                   1/1     Running            0                13h     10.244.151.130    k8s-master-01   <none>           <none>
coredns-55cb58b774-z4gv8                   1/1     Running            0                13h     10.244.151.131    k8s-master-01   <none>           <none>
etcd-k8s-master-01                         1/1     Running            0                13h     91.98.124.228     k8s-master-01   <none>           <none>
etcd-k8s-master-02                         0/1     CrashLoopBackOff   33 (118s ago)    12h     91.98.117.26      k8s-master-02   <none>           <none>
kube-apiserver-k8s-master-01               1/1     Running            0                13h     91.98.124.228     k8s-master-01   <none>           <none>
kube-apiserver-k8s-master-02               0/1     Running            32 (5m11s ago)   12h     91.98.117.26      k8s-master-02   <none>           <none>
kube-apiserver-k8s-master-03               0/1     CrashLoopBackOff   96 (2m46s ago)   12h     91.98.165.238     k8s-master-03   <none>           <none>
kube-controller-manager-k8s-master-01      1/1     Running            99               13h     91.98.124.228     k8s-master-01   <none>           <none>
kube-controller-manager-k8s-master-02      1/1     Running            19 (4h56m ago)   12h     91.98.117.26      k8s-master-02   <none>           <none>
kube-controller-manager-k8s-master-03      1/1     Running            87 (5m46s ago)   12h     91.98.165.238     k8s-master-03   <none>           <none>
kube-proxy-7bjzv                           1/1     Running            2 (76s ago)      2m34s   91.98.124.228     k8s-master-01   <none>           <none>
kube-proxy-7wnkp                           1/1     Running            0                2m34s   91.98.117.26      k8s-master-02   <none>           <none>
kube-proxy-cqw4p                           0/1     CrashLoopBackOff   1 (3s ago)       2m34s   188.245.45.242    k8s-worker-05   <none>           <none>
kube-proxy-pd9r8                           0/1     CrashLoopBackOff   1 (14s ago)      2m34s   91.98.200.38      k8s-worker-04   <none>           <none>
kube-proxy-vd4f2                           0/1     CrashLoopBackOff   2 (5s ago)       2m34s   91.99.164.62      k8s-worker-02   <none>           <none>
kube-proxy-xhp4w                           1/1     Running            2 (25s ago)      2m34s   116.203.135.192   k8s-worker-01   <none>           <none>
kube-proxy-xpgb8                           1/1     Running            2 (2m31s ago)    2m34s   157.90.119.183    k8s-worker-03   <none>           <none>
kube-proxy-zzzpl                           1/1     Running            2 (65s ago)      2m34s   91.98.165.238     k8s-master-03   <none>           <none>
kube-scheduler-k8s-master-01               1/1     Running            95               13h     91.98.124.228     k8s-master-01   <none>           <none>
kube-scheduler-k8s-master-02               1/1     Running            22 (4h56m ago)   12h     91.98.117.26      k8s-master-02   <none>           <none>
kube-scheduler-k8s-master-03               1/1     Running            81 (7m18s ago)   12h     91.98.165.238     k8s-master-03   <none>           <none>
```

## external-secrets pods
```
NAME                                                READY   STATUS             RESTARTS      AGE   IP              NODE            NOMINATED NODE   READINESS GATES
external-secrets-7b4b656f56-tdzwj                   1/1     Running            2 (60s ago)   93s   10.244.7.156    k8s-worker-03   <none>           <none>
external-secrets-cert-controller-5566bb8569-rxgsf   0/1     CrashLoopBackOff   1 (2s ago)    93s   10.244.78.195   k8s-worker-04   <none>           <none>
external-secrets-webhook-586968df45-6q799           0/1     Running            2 (89s ago)   93s   10.244.55.219   k8s-worker-05   <none>           <none>
```

## redis-test-secret
```
NOT FOUND
```

## ETCD final member list
```
time="2025-12-06T00:26:40Z" level=warning msg="runtime connect using default endpoints: [unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead."
time="2025-12-06T00:26:40Z" level=fatal msg="execing command in container: input is not a terminal"
ERROR: Failed to check ETCD
```

## Process

Control-plane repair executed via ph9-execute-claude-plan.sh
All logs available in /opt/keybuzz/logs/phase9-execute-claude-plan/
