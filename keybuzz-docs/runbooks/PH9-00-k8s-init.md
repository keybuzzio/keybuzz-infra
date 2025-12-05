# PH9-00 Kubernetes v3 Initialization

**Date**: 2025-12-05  
**Status**: ✅ Complete

## Summary

Successfully initialized Kubernetes v1.30 cluster with 3 control plane nodes and 5 worker nodes, installed Calico CNI, ArgoCD, External Secrets Operator, and integrated with Vault.

## Cluster Architecture

### Control Plane Nodes
- **k8s-master-01** (10.0.0.100) - Initial control plane
- **k8s-master-02** (10.0.0.101) - Control plane replica
- **k8s-master-03** (10.0.0.102) - Control plane replica

### Worker Nodes
- **k8s-worker-01** (10.0.0.110)
- **k8s-worker-02** (10.0.0.111)
- **k8s-worker-03** (10.0.0.112)
- **k8s-worker-04** (10.0.0.113)
- **k8s-worker-05** (10.0.0.114)

## Installation Steps

### 1. Kubernetes Cluster Bootstrap

**Playbook**: `ansible/playbooks/k8s_cluster_v3.yml`  
**Role**: `ansible/roles/k8s_cluster_v3`

**Components Installed**:
- containerd (CRI)
- kubelet, kubeadm, kubectl (v1.30)
- Kubernetes cluster via kubeadm

**Initialization**:
```bash
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=10.0.0.100:6443 \
  --upload-certs
```

**Join Commands**:
- Control plane: Saved to `/root/k8s_join_control_plane.txt` on k8s-master-01
- Workers: Saved to `/root/k8s_join_workers.txt` on k8s-master-01

### 2. Calico CNI Installation

**Script**: `scripts/ph9-01-install-calico.sh`

**Manifest**: Calico v3.28.0
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

**Pod Network CIDR**: `10.244.0.0/16`

### 3. ArgoCD Installation

**Script**: `scripts/ph9-02-install-argocd.sh`

**Namespace**: `argocd`  
**Manifest**: ArgoCD stable release

**Access**:
- Initial admin password: Saved to `/root/argocd_admin_password.txt` on install-v3
- Service: `argocd-server` in namespace `argocd`

### 4. External Secrets Operator Installation

**Script**: `scripts/ph9-03-install-eso.sh`

**Installation Method**: Helm  
**Repository**: `external-secrets/external-secrets`  
**Namespace**: `external-secrets`  
**CRDs**: Installed automatically

### 5. Vault Kubernetes Integration

**Script**: `scripts/ph9-04-vault-k8s-integration.sh`

**Components**:
- Kubernetes auth enabled in Vault
- ServiceAccount: `eso-keybuzz-sa` in `keybuzz-system`
- Vault role: `eso-keybuzz`
- Vault policy: `eso-keybuzz-policy`
- ClusterSecretStore: `vault-keybuzz`

### 6. Application Namespaces

**Script**: `scripts/ph9-05-create-namespaces.sh`

**Namespaces Created**:
- `keybuzz-system` - System components and ESO
- `keybuzz-apps` - KeyBuzz applications
- `erp-system` - ERPNext system
- `observability` - Monitoring and logging

## Verification Commands

**Check cluster status**:
```bash
export KUBECONFIG=/root/.kube/config
kubectl get nodes
kubectl get pods --all-namespaces
```

**Check ArgoCD**:
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

**Check External Secrets Operator**:
```bash
kubectl get pods -n external-secrets
kubectl get crds | grep externalsecrets
```

**Check Vault integration**:
```bash
kubectl get clustersecretstore vault-keybuzz
kubectl get externalsecret -n keybuzz-system
```

## Files Created

- `ansible/roles/k8s_cluster_v3/` - Kubernetes cluster role
- `ansible/playbooks/k8s_cluster_v3.yml` - Cluster deployment playbook
- `scripts/ph9-01-bootstrap-k8s.sh` - Bootstrap script
- `scripts/ph9-01-install-calico.sh` - Calico installation
- `scripts/ph9-02-install-argocd.sh` - ArgoCD installation
- `scripts/ph9-03-install-eso.sh` - ESO installation
- `scripts/ph9-04-vault-k8s-integration.sh` - Vault integration
- `scripts/ph9-05-create-namespaces.sh` - Namespace creation
- `scripts/ph9-06-test-eso.sh` - ESO test script
- `k8s/tests/test-redis-externalsecret.yaml` - Test ExternalSecret

## Next Steps

1. Configure ArgoCD applications for KeyBuzz services
2. Set up monitoring and observability stack
3. Deploy ERPNext via ArgoCD
4. Configure ingress controllers
5. Set up backup and disaster recovery

