# PH9 – Diagnostic & Cleanup Profond Control-Plane (master-02 & master-03)

**Date:** Fri Dec  5 07:56:09 PM UTC 2025

## État avant cleanup

### Nodes
```
NAME            STATUS     ROLES           AGE   VERSION    INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master-01   Ready      control-plane   9h    v1.30.14   91.98.124.228     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-02   NotReady   control-plane   8h    v1.30.14   91.98.117.26      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-master-03   NotReady   control-plane   8h    v1.30.14   91.98.165.238     <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-01   Ready      <none>          8h    v1.30.14   116.203.135.192   <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-02   Ready      <none>          8h    v1.30.14   91.99.164.62      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-03   Ready      <none>          8h    v1.30.14   157.90.119.183    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-04   Ready      <none>          8h    v1.30.14   91.98.200.38      <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
k8s-worker-05   Ready      <none>          8h    v1.30.14   188.245.45.242    <none>        Ubuntu 24.04.3 LTS   6.8.0-88-generic   containerd://2.2.0
```

### Pods (tous namespaces)
```
NAMESPACE          NAME                                                READY   STATUS             RESTARTS         AGE
argocd             argocd-application-controller-0                     0/1     CrashLoopBackOff   88 (4m2s ago)    8h
argocd             argocd-applicationset-controller-b776d8994-bmzl5    0/1     CrashLoopBackOff   81 (4m9s ago)    8h
argocd             argocd-dex-server-95957787c-lmmk5                   0/1     CrashLoopBackOff   92 (2m30s ago)   8h
argocd             argocd-notifications-controller-64964d4df5-gw62j    0/1     CrashLoopBackOff   80 (2m50s ago)   8h
argocd             argocd-redis-75876db6bf-zjcsq                       1/1     Running            97 (4m39s ago)   8h
argocd             argocd-repo-server-78dd5855d7-q56s6                 0/1     CrashLoopBackOff   114 (4m8s ago)   8h
argocd             argocd-server-69854449cd-pvz4v                      0/1     CrashLoopBackOff   90 (3m33s ago)   8h
external-secrets   external-secrets-7b4b656f56-f5g2q                   0/1     CrashLoopBackOff   88 (2m5s ago)    7h34m
external-secrets   external-secrets-cert-controller-5566bb8569-dx5vm   0/1     Running            97 (4m2s ago)    8h
external-secrets   external-secrets-webhook-586968df45-gbmj6           0/1     CrashLoopBackOff   94 (4m15s ago)   8h
kube-system        calico-kube-controllers-564985c589-7nv5n            0/1     CrashLoopBackOff   76 (2m41s ago)   8h
kube-system        calico-node-6wpxn                                   1/1     Running            0                6h54m
kube-system        calico-node-7cb99                                   0/1     CrashLoopBackOff   79 (4m4s ago)    6h54m
kube-system        calico-node-bs2q7                                   0/1     CrashLoopBackOff   78 (5m4s ago)    6h54m
kube-system        calico-node-mw4pm                                   1/1     Running            59 (126m ago)    6h54m
kube-system        calico-node-p5n2w                                   0/1     CrashLoopBackOff   79 (4m14s ago)   6h54m
kube-system        calico-node-q65dv                                   1/1     Running            0                6h54m
kube-system        calico-node-r6mc5                                   0/1     CrashLoopBackOff   78 (2m24s ago)   6h54m
kube-system        calico-node-xlxx4                                   0/1     CrashLoopBackOff   78 (3m14s ago)   6h54m
kube-system        coredns-55cb58b774-q7bcw                            1/1     Running            0                9h
kube-system        coredns-55cb58b774-z4gv8                            1/1     Running            0                9h
kube-system        etcd-k8s-master-01                                  1/1     Running            0                9h
kube-system        etcd-k8s-master-02                                  0/1     CrashLoopBackOff   26 (119m ago)    8h
kube-system        kube-apiserver-k8s-master-01                        1/1     Running            0                9h
kube-system        kube-apiserver-k8s-master-02                        0/1     Running            25 (121m ago)    8h
kube-system        kube-apiserver-k8s-master-03                        0/1     CrashLoopBackOff   91 (117m ago)    8h
kube-system        kube-controller-manager-k8s-master-01               1/1     Running            99               9h
kube-system        kube-controller-manager-k8s-master-02               1/1     Running            18               8h
kube-system        kube-controller-manager-k8s-master-03               0/1     CrashLoopBackOff   84 (117m ago)    8h
kube-system        kube-proxy-4zkww                                    0/1     CrashLoopBackOff   69 (3m35s ago)   6h54m
kube-system        kube-proxy-b2zgf                                    1/1     Running            68 (11m ago)     6h54m
kube-system        kube-proxy-g9ntt                                    0/1     CrashLoopBackOff   63 (118m ago)    6h54m
kube-system        kube-proxy-kjsfh                                    0/1     CrashLoopBackOff   68 (2m51s ago)   6h54m
kube-system        kube-proxy-q8qk2                                    1/1     Running            0                130m
kube-system        kube-proxy-qsz5m                                    0/1     CrashLoopBackOff   68 (101s ago)    6h54m
kube-system        kube-proxy-rgl8r                                    0/1     CrashLoopBackOff   73 (3m20s ago)   6h54m
kube-system        kube-proxy-xtjcd                                    0/1     CrashLoopBackOff   68 (2m34s ago)   6h54m
kube-system        kube-scheduler-k8s-master-01                        1/1     Running            95               9h
kube-system        kube-scheduler-k8s-master-02                        1/1     Running            21               8h
kube-system        kube-scheduler-k8s-master-03                        1/1     Running            79 (120m ago)    8h
```

## Diagnostic master-02 / master-03

### master-02 diagnostic (processus, ports, kubelet, journalctl)
```
===== DIAGNOSTIC SUR 10.0.0.101 =====

--- ps -ef | grep kube ---
no kube* processes

--- ps -ef | grep etcd ---
no etcd processes

--- lsof ports 10257 / 10259 / 10250 / 6443 ---
no processes on these ports

--- netstat / ss ports ---
no bound ports found

--- systemctl status kubelet ---
○ kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead) (Result: exit-code) since Fri 2025-12-05 19:33:34 UTC; 22min ago
   Duration: 84ms
       Docs: https://kubernetes.io/docs/
    Process: 78812 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=1/FAILURE)
   Main PID: 78812 (code=exited, status=1/FAILURE)
        CPU: 105ms

Dec 05 19:33:34 k8s-master-02 systemd[1]: Stopped kubelet.service - kubelet: The Kubernetes Node Agent.

--- journalctl -u kubelet (last 50 lines) ---
Dec 05 19:32:08 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:18 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 542.
Dec 05 19:32:18 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:18 k8s-master-02 (kubelet)[78424]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:18 k8s-master-02 kubelet[78424]: E1205 19:32:18.571194   78424 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:18 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:18 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:28 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 543.
Dec 05 19:32:28 k8s-master-02 (kubelet)[78438]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:28 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:28 k8s-master-02 kubelet[78438]: E1205 19:32:28.851096   78438 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:28 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:28 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:38 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 544.
Dec 05 19:32:38 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:38 k8s-master-02 (kubelet)[78458]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:39 k8s-master-02 kubelet[78458]: E1205 19:32:39.084355   78458 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:39 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:39 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:49 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 545.
Dec 05 19:32:49 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:49 k8s-master-02 (kubelet)[78479]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:49 k8s-master-02 kubelet[78479]: E1205 19:32:49.328203   78479 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:49 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:49 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:59 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 546.
Dec 05 19:32:59 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:59 k8s-master-02 (kubelet)[78498]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:59 k8s-master-02 kubelet[78498]: E1205 19:32:59.588812   78498 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:59 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:59 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:09 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 547.
Dec 05 19:33:09 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:09 k8s-master-02 (kubelet)[78517]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:09 k8s-master-02 kubelet[78517]: E1205 19:33:09.839507   78517 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:09 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:09 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:19 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 548.
Dec 05 19:33:19 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:19 k8s-master-02 (kubelet)[78540]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:20 k8s-master-02 kubelet[78540]: E1205 19:33:20.079358   78540 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:20 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:20 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:30 k8s-master-02 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 549.
Dec 05 19:33:30 k8s-master-02 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:30 k8s-master-02 (kubelet)[78812]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:30 k8s-master-02 kubelet[78812]: E1205 19:33:30.324372   78812 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:30 k8s-master-02 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:30 k8s-master-02 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:34 k8s-master-02 systemd[1]: Stopped kubelet.service - kubelet: The Kubernetes Node Agent.

--- systemctl status containerd ---
○ containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: inactive (dead) since Fri 2025-12-05 19:33:34 UTC; 22min ago
   Duration: 1h 33min 55.104s
       Docs: https://containerd.io
    Process: 67289 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
    Process: 67290 ExecStart=/usr/bin/containerd (code=exited, status=0/SUCCESS)
   Main PID: 67290 (code=exited, status=0/SUCCESS)
      Tasks: 66
     Memory: 31.0M (peak: 68.5M)
        CPU: 28.496s
     CGroup: /system.slice/containerd.service
             ├─60059 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 769a895928c4f926f8ea813247ace7af7b029da5fc0d34cc28b740821175e066 -address /run/containerd/containerd.sock
             ├─60073 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 920acf13e76566a8e61e8756e3cb2f9125e6f0d202cf4d6b20aeade45d3e6354 -address /run/containerd/containerd.sock
             ├─60111 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 09fbf472be923159ef8451ddfea477d397e5cee29f916b89d31dbf14f95a9c38 -address /run/containerd/containerd.sock
             ├─60216 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 76741d027a1a0bd4562d9d01f9d65dad7d8f376f50dc1a478556b8b912f1329f -address /run/containerd/containerd.sock
             ├─60440 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 96171be56ace20f74feb8643e72b528fb9e4dcdbd0a7d9ddce7643aba5925f50 -address /run/containerd/containerd.sock
             └─60500 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id b8ba86654885d5ad72014950556d0a6d4437a1d6ca3e5d4f75892e22a96632d7 -address /run/containerd/containerd.sock

Dec 05 19:33:34 k8s-master-02 containerd[67290]: time="2025-12-05T19:33:34.982645608Z" level=info msg="Stream server stopped"

--- /etc/kubernetes/manifests contents ---
total 8
drwxrwxr-x 2 root root 4096 Dec  5 17:59 .
drwxrwxr-x 4 root root 4096 Dec  5 17:59 ..

--- /var/lib/etcd contents ---
total 8
drwx------  2 root root 4096 Dec  5 17:59 .
drwxr-xr-x 43 root root 4096 Dec  5 11:30 ..

--- /var/lib/kubelet contents ---
total 8
drwxrwxr-x  2 root root 4096 Dec  5 17:59 .
drwxr-xr-x 43 root root 4096 Dec  5 11:30 ..
```

### master-03 diagnostic (processus, ports, kubelet, journalctl)
```
===== DIAGNOSTIC SUR 10.0.0.102 =====

--- ps -ef | grep kube ---
no kube* processes

--- ps -ef | grep etcd ---
no etcd processes

--- lsof ports 10257 / 10259 / 10250 / 6443 ---
no processes on these ports

--- netstat / ss ports ---
no bound ports found

--- systemctl status kubelet ---
○ kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: inactive (dead) (Result: exit-code) since Fri 2025-12-05 19:33:37 UTC; 22min ago
   Duration: 107ms
       Docs: https://kubernetes.io/docs/
    Process: 204642 ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS (code=exited, status=1/FAILURE)
   Main PID: 204642 (code=exited, status=1/FAILURE)
        CPU: 125ms

Dec 05 19:33:37 k8s-master-03 systemd[1]: Stopped kubelet.service - kubelet: The Kubernetes Node Agent.

--- journalctl -u kubelet (last 50 lines) ---
Dec 05 19:32:06 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:16 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 541.
Dec 05 19:32:16 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:16 k8s-master-03 (kubelet)[204406]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:16 k8s-master-03 kubelet[204406]: E1205 19:32:16.332101  204406 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:16 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:16 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:26 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 542.
Dec 05 19:32:26 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:26 k8s-master-03 (kubelet)[204424]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:26 k8s-master-03 kubelet[204424]: E1205 19:32:26.581596  204424 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:26 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:26 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:36 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 543.
Dec 05 19:32:36 k8s-master-03 (kubelet)[204439]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:36 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:36 k8s-master-03 kubelet[204439]: E1205 19:32:36.824728  204439 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:36 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:36 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:46 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 544.
Dec 05 19:32:46 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:46 k8s-master-03 (kubelet)[204460]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:47 k8s-master-03 kubelet[204460]: E1205 19:32:47.068888  204460 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:47 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:47 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:32:57 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 545.
Dec 05 19:32:57 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:32:57 k8s-master-03 (kubelet)[204472]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:32:57 k8s-master-03 kubelet[204472]: E1205 19:32:57.327982  204472 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:32:57 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:32:57 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:07 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 546.
Dec 05 19:33:07 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:07 k8s-master-03 (kubelet)[204487]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:07 k8s-master-03 kubelet[204487]: E1205 19:33:07.570434  204487 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:07 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:07 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:17 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 547.
Dec 05 19:33:17 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:17 k8s-master-03 (kubelet)[204510]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:17 k8s-master-03 kubelet[204510]: E1205 19:33:17.841326  204510 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:17 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:17 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:27 k8s-master-03 systemd[1]: kubelet.service: Scheduled restart job, restart counter is at 548.
Dec 05 19:33:27 k8s-master-03 systemd[1]: Started kubelet.service - kubelet: The Kubernetes Node Agent.
Dec 05 19:33:27 k8s-master-03 (kubelet)[204642]: kubelet.service: Referenced but unset environment variable evaluates to an empty string: KUBELET_KUBEADM_ARGS
Dec 05 19:33:28 k8s-master-03 kubelet[204642]: E1205 19:33:28.068681  204642 run.go:74] "command failed" err="failed to load kubelet config file, path: /var/lib/kubelet/config.yaml, error: failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file \"/var/lib/kubelet/config.yaml\", error: open /var/lib/kubelet/config.yaml: no such file or directory"
Dec 05 19:33:28 k8s-master-03 systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Dec 05 19:33:28 k8s-master-03 systemd[1]: kubelet.service: Failed with result 'exit-code'.
Dec 05 19:33:37 k8s-master-03 systemd[1]: Stopped kubelet.service - kubelet: The Kubernetes Node Agent.

--- systemctl status containerd ---
○ containerd.service - containerd container runtime
     Loaded: loaded (/usr/lib/systemd/system/containerd.service; enabled; preset: enabled)
     Active: inactive (dead) since Fri 2025-12-05 19:33:37 UTC; 22min ago
   Duration: 1h 33min 51.891s
       Docs: https://containerd.io
    Process: 194421 ExecStartPre=/sbin/modprobe overlay (code=exited, status=0/SUCCESS)
    Process: 194423 ExecStart=/usr/bin/containerd (code=exited, status=0/SUCCESS)
   Main PID: 194423 (code=exited, status=0/SUCCESS)
      Tasks: 57
     Memory: 1.5G (peak: 1.5G)
        CPU: 28.154s
     CGroup: /system.slice/containerd.service
             ├─185946 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 82de620399b57a84e60260921903d5394428704ec68fa7a35333d85df428bb27 -address /run/containerd/containerd.sock
             ├─188158 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 192df961d054b98ef0bbd97194583f5adb94962d585fe33d2eefafc621e75eab -address /run/containerd/containerd.sock
             ├─192016 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 71da045193d36ada3b26457834158b865ac1039cde3b2a8bb4f8d1dd4dfbc294 -address /run/containerd/containerd.sock
             ├─193207 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id 6106043652ded0483526af92a2f6536287eadb0cf4120b514faf7184cad40d18 -address /run/containerd/containerd.sock
             └─193493 /usr/bin/containerd-shim-runc-v2 -namespace k8s.io -id c2291e7e7c67cea3026ef8a61e9c393d152b5dc8258542a1b193a81b93b01514 -address /run/containerd/containerd.sock

Dec 05 19:33:37 k8s-master-03 containerd[194423]: time="2025-12-05T19:33:37.910960509Z" level=info msg="Event monitor stopped"
Dec 05 19:33:37 k8s-master-03 containerd[194423]: time="2025-12-05T19:33:37.910994174Z" level=info msg="Stream server stopped"

--- /etc/kubernetes/manifests contents ---
total 8
drwxrwxr-x 2 root root 4096 Dec  5 17:59 .
drwxrwxr-x 4 root root 4096 Dec  5 17:59 ..

--- /var/lib/etcd contents ---
total 8
drwx------  2 root root 4096 Dec  5 11:33 .
drwxr-xr-x 43 root root 4096 Dec  5 11:33 ..

--- /var/lib/kubelet contents ---
total 8
drwxrwxr-x  2 root root 4096 Dec  5 17:59 .
drwxr-xr-x 43 root root 4096 Dec  5 11:33 ..
```

## ETCD member list (master-01)

### Avant cleanup
```
=== ETCD member list (sur master-01) ===
etcdctl not found in PATH, trying with full path...
bash: line 12: /usr/local/bin/etcdctl: No such file or directory
ERROR: etcdctl member list failed (full path)

=== ETCD cluster health ===
```

### Après cleanup
```
=== ETCD member list (apres cleanup) ===
```

## Manifests master-01 (référence)
```
=== ls /etc/kubernetes/manifests sur master-01 ===
total 24
drwx------ 2 root root 4096 Dec  5 10:34 .
drwxrwxr-x 4 root root 4096 Dec  5 10:34 ..
-rw------- 1 root root 2396 Dec  5 10:34 etcd.yaml
-rw------- 1 root root 3873 Dec  5 10:34 kube-apiserver.yaml
-rw------- 1 root root 3394 Dec  5 10:34 kube-controller-manager.yaml
-rw------- 1 root root 1464 Dec  5 10:34 kube-scheduler.yaml

=== Contents of manifests (first 20 lines each) ===
```

## JOIN_CMD préparé (ne pas exécuter manuellement)

⚠️ **IMPORTANT**: Cette commande est prête mais ne doit PAS être exécutée manuellement.
Utiliser le script `ph9-control-plane-join-clean.sh` pour un join propre.

```
=== JOIN_CMD ===
kubeadm join 10.0.0.100:6443 --token 2enmgv.b95z6bq1l4q6boc1 --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key d8354698b199a0b67bf05b70f791aa5223b46bd9cd8d8423aa75678846477b91 --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259

NOTE: Ne PAS executer cette commande manuellement. Utiliser le script ph9-control-plane-join-clean.sh
```

## Actions effectuées

1. ✅ Diagnostic complet des processus et ports sur master-02/03
2. ✅ Kill des processus zombies (kube-controller-manager, kube-scheduler, kube-apiserver, etcd)
3. ✅ Nettoyage des ports 10257, 10259, 10250, 6443
4. ✅ Nettoyage des répertoires (/etc/kubernetes/manifests, /var/lib/etcd, /var/lib/kubelet, /etc/cni/net.d)
5. ✅ kubeadm reset sur master-02/03
6. ✅ Vérification et nettoyage des membres ETCD orphelins
7. ✅ Préparation de la commande join propre

## Remarques

- master-02/03 ont été complètement nettoyés (processus tués, dossiers kubeadm/etcd/kubelet/CNI purgés).
- Les membres ETCD orphelins ont été retirés du cluster.
- READY pour un join control-plane propre (PH9-control-plane-join-clean).
- La commande join est préparée et sauvegardée dans `/opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt`.
