# Phase 9 - Kubernetes v3 Deployment

**Date**: 2025-12-05  
**Status**: ✅ Complete

## Overview

Complete Kubernetes v3 cluster deployment with ArgoCD, External Secrets Operator, and Vault integration for KeyBuzz infrastructure.

## Architecture

```
Kubernetes Cluster (v1.30)
├── Control Plane (3 nodes)
│   ├── k8s-master-01 (10.0.0.100)
│   ├── k8s-master-02 (10.0.0.101)
│   └── k8s-master-03 (10.0.0.102)
├── Workers (5 nodes)
│   ├── k8s-worker-01 (10.0.0.110)
│   ├── k8s-worker-02 (10.0.0.111)
│   ├── k8s-worker-03 (10.0.0.112)
│   ├── k8s-worker-04 (10.0.0.113)
│   └── k8s-worker-05 (10.0.0.114)
├── CNI: Calico (10.244.0.0/16)
├── GitOps: ArgoCD
├── Secrets: External Secrets Operator
└── Vault Integration: Kubernetes auth + ClusterSecretStore
```

## Components

### 1. Kubernetes Cluster

- **Version**: v1.30
- **CRI**: containerd
- **Init Tool**: kubeadm
- **Control Plane Endpoint**: 10.0.0.100:6443
- **Pod Network**: Calico (10.244.0.0/16)

### 2. Calico CNI

- **Version**: v3.28.0
- **Network Policy**: Enabled
- **IP Pool**: 10.244.0.0/16

### 3. ArgoCD

- **Namespace**: `argocd`
- **Version**: stable
- **Purpose**: GitOps for application deployment

### 4. External Secrets Operator

- **Namespace**: `external-secrets`
- **Installation**: Helm
- **Purpose**: Sync secrets from Vault to Kubernetes

### 5. Vault Integration

- **Auth Method**: Kubernetes
- **ServiceAccount**: `eso-keybuzz-sa` (keybuzz-system)
- **Vault Role**: `eso-keybuzz`
- **Vault Policy**: `eso-keybuzz-policy`
- **ClusterSecretStore**: `vault-keybuzz`

## Deployment Process

### Step 1: Bootstrap Kubernetes

```bash
cd /opt/keybuzz/keybuzz-infra
bash scripts/ph9-01-bootstrap-k8s.sh
```

**What it does**:
- Prepares all nodes (disable swap, enable IP forwarding)
- Installs containerd, kubelet, kubeadm, kubectl
- Initializes cluster on k8s-master-01
- Joins control plane nodes (k8s-master-02, k8s-master-03)
- Joins worker nodes (k8s-worker-01..05)
- Copies kubeconfig to install-v3

### Step 2: Install Calico CNI

```bash
bash scripts/ph9-01-install-calico.sh
```

**What it does**:
- Applies Calico manifests
- Waits for Calico pods to be ready
- Verifies all nodes are Ready

### Step 3: Install ArgoCD

```bash
bash scripts/ph9-02-install-argocd.sh
```

**What it does**:
- Creates `argocd` namespace
- Installs ArgoCD from official manifests
- Waits for ArgoCD pods to be ready
- Retrieves initial admin password

### Step 4: Install External Secrets Operator

```bash
bash scripts/ph9-03-install-eso.sh
```

**What it does**:
- Adds ESO Helm repository
- Creates `external-secrets` namespace
- Installs ESO via Helm with CRDs
- Waits for ESO pods to be ready

### Step 5: Integrate Vault with Kubernetes

```bash
bash scripts/ph9-04-vault-k8s-integration.sh
```

**What it does**:
- Enables Kubernetes auth in Vault
- Creates Vault policy for ESO
- Creates Vault role for ESO
- Creates Kubernetes ServiceAccount
- Creates ClusterSecretStore

### Step 6: Create Application Namespaces

```bash
bash scripts/ph9-05-create-namespaces.sh
```

**What it does**:
- Creates `keybuzz-system` namespace
- Creates `keybuzz-apps` namespace
- Creates `erp-system` namespace
- Creates `observability` namespace

### Step 7: Test External Secrets Operator

```bash
bash scripts/ph9-06-test-eso.sh
```

**What it does**:
- Verifies ClusterSecretStore exists
- Creates test ExternalSecret
- Waits for secret sync
- Verifies secret was created

## Verification

### Cluster Status

```bash
export KUBECONFIG=/root/.kube/config
kubectl get nodes
kubectl get pods --all-namespaces
```

### ArgoCD Status

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### External Secrets Operator Status

```bash
kubectl get pods -n external-secrets
kubectl get clustersecretstore
kubectl get externalsecret --all-namespaces
```

### Vault Integration

```bash
# On vault-01
vault read auth/kubernetes/role/eso-keybuzz
vault policy read eso-keybuzz-policy

# On install-v3
kubectl get clustersecretstore vault-keybuzz -o yaml
kubectl get serviceaccount eso-keybuzz-sa -n keybuzz-system
```

## Troubleshooting

### Nodes Not Ready

```bash
# Check kubelet status
systemctl status kubelet

# Check kubelet logs
journalctl -u kubelet -f

# Check node conditions
kubectl describe node <node-name>
```

### Calico Pods Not Starting

```bash
# Check Calico pods
kubectl get pods -n kube-system | grep calico

# Check Calico logs
kubectl logs -n kube-system -l k8s-app=calico-node
```

### External Secrets Not Syncing

```bash
# Check ExternalSecret status
kubectl describe externalsecret <name> -n <namespace>

# Check ESO logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# Check ClusterSecretStore
kubectl describe clustersecretstore vault-keybuzz
```

### Vault Authentication Issues

```bash
# Verify Kubernetes auth is enabled
vault auth list

# Check Vault role configuration
vault read auth/kubernetes/role/eso-keybuzz

# Test service account token
kubectl get secret -n keybuzz-system $(kubectl get sa eso-keybuzz-sa -n keybuzz-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d
```

## Security Considerations

1. **Vault Integration**: Uses Kubernetes service account authentication
2. **Secrets Management**: All secrets synced from Vault via ESO
3. **Network Policies**: Calico network policies can be applied
4. **RBAC**: Kubernetes RBAC configured for service accounts
5. **TLS**: All Vault connections use TLS

## Next Steps

1. **ArgoCD Applications**: Configure ArgoCD applications for KeyBuzz services
2. **Monitoring**: Deploy Prometheus, Grafana, and other observability tools
3. **Ingress**: Configure ingress controller (NGINX or Traefik)
4. **Backup**: Set up Velero for cluster backup
5. **ERPNext Deployment**: Deploy ERPNext via ArgoCD with Vault secrets

## Files and Scripts

- `ansible/roles/k8s_cluster_v3/` - Kubernetes cluster Ansible role
- `ansible/playbooks/k8s_cluster_v3.yml` - Cluster deployment playbook
- `scripts/ph9-01-bootstrap-k8s.sh` - Bootstrap script
- `scripts/ph9-01-install-calico.sh` - Calico installation
- `scripts/ph9-02-install-argocd.sh` - ArgoCD installation
- `scripts/ph9-03-install-eso.sh` - ESO installation
- `scripts/ph9-04-vault-k8s-integration.sh` - Vault integration
- `scripts/ph9-05-create-namespaces.sh` - Namespace creation
- `scripts/ph9-06-test-eso.sh` - ESO test script
- `k8s/tests/test-redis-externalsecret.yaml` - Test ExternalSecret

## Conclusion

✅ **Kubernetes cluster deployed** (3 masters + 5 workers)  
✅ **Calico CNI installed**  
✅ **ArgoCD installed**  
✅ **External Secrets Operator installed**  
✅ **Vault integration configured**  
✅ **Application namespaces created**  
✅ **ESO test successful**

The Kubernetes cluster is ready for application deployment via ArgoCD with secrets managed by Vault through External Secrets Operator.

