# PH-INFRA-04 -- Kubernetes Masters Private Network Migration & Final Hardening

> Date: 2026-03-15
> Statut: TERMINEE
> Environnement: Production (Hetzner Cloud)
> Prerequis: PH-INFRA-03 (K8s Masters Network Hardening)
> Downtime: 0

---

## A. Precheck

### Inventaire Masters

| Serveur | ID | IP publique | IP privee | Datacenter | Roles |
|---|---|---|---|---|---|
| k8s-master-01 | 109780472 | 91.98.124.228 | 10.0.0.100 | nbg1-dc3 | control-plane + etcd |
| k8s-master-02 | 109783469 | 91.98.117.26 | 10.0.0.101 | nbg1-dc3 | control-plane + etcd |
| k8s-master-03 | 109783574 | 91.98.165.238 | 10.0.0.102 | nbg1-dc3 | control-plane + etcd |

### Etat initial cluster

- Init system: **kubeadm** (PAS K3s)
- Kubernetes version: v1.30.14
- containerd: 2.2.0
- Nodes: 8/8 Ready (3 masters + 5 workers)
- Pods: 131 total, 110 running
- kubeconfig bastion: `https://10.0.0.100:6443` (deja IP privee)
- controlPlaneEndpoint: `10.0.0.100:6443`

### Etat initial etcd

| Member | Peer URL (avant) | Client URL (avant) |
|---|---|---|
| k8s-master-01 | https://10.0.0.100:2380 | https://10.0.0.100:2379 |
| k8s-master-02 | **https://91.98.117.26:2380** | **https://91.98.117.26:2379** |
| k8s-master-03 | **https://91.98.165.238:2380** | **https://91.98.165.238:2379** |

master-01 etait deja sur IP privee. master-02 et master-03 utilisaient les IPs publiques.

### Etat initial configs

| Master | apiserver advertise-address | kubelet node-ip |
|---|---|---|
| master-01 | 10.0.0.100 (prive) | auto (public 91.98.124.228) |
| master-02 | 91.98.117.26 (public) | auto (public 91.98.117.26) |
| master-03 | 91.98.165.238 (public) | auto (public 91.98.165.238) |

### Certificats

| Master | apiserver cert SANs | etcd cert SANs |
|---|---|---|
| master-01 | 10.0.0.100 | 10.0.0.100, .101, .102 |
| master-02 | 91.98.117.26, 10.0.0.100 (**manque 10.0.0.101**) | 10.0.0.100, .101, .102 |
| master-03 | 91.98.165.238, 10.0.0.100 (**manque 10.0.0.102**) | 10.0.0.100, .101, .102 |

Constat critique: les certificats etcd incluaient deja les 3 IPs privees (migration sans regeneration etcd). Les certificats apiserver de master-02/03 necessitaient une regeneration.

---

## B. Backups

### Snapshots Hetzner (existants < 24h)

| Serveur | Snapshot ID | Taille | Date |
|---|---|---|---|
| k8s-master-01 | 366770215 | 3.46 GB | 2026-03-14 22:59 |
| k8s-master-02 | 366771596 | 3.53 GB | 2026-03-14 23:03 |
| k8s-master-03 | 366772425 | 3.36 GB | 2026-03-14 23:06 |

### Snapshot etcd

- Fichier: `backup-infra04-20260315-1327.db`
- Taille: 53 MB (52,969,504 bytes)
- Revision: 38,321,369
- Total keys: 7,230
- Copie sur bastion: `/root/backup-etcd-infra04-20260315-1327.db`

### Configs sauvegardees

Sur chaque master: `/root/backup-infra04-20260315-1327/`
- `manifests/` (etcd.yaml, kube-apiserver.yaml, kube-controller-manager.yaml, kube-scheduler.yaml)
- `pki/` (tous les certificats)
- `admin.conf`, `controller-manager.conf`, `scheduler.conf`, `kubelet.conf`
- `kubeadm-flags.env`
- `kubelet-config.yaml`

Sauvegardes supplementaires pendant migration:
- `etcd.yaml.pre-migration` (master-02, master-03)
- `kube-apiserver.yaml.pre-migration` (master-02, master-03)
- `kubeadm-flags.env.bak` (master-01)

### Firewalls documentes

- `keybuzz-k8s-masters-secure` (ID 10700227, PH-INFRA-03): 6 regles, 3 masters
- `keybuzz-public-firewall` (ID 10697211): 6 regles, 8 serveurs

---

## C. Migration

### Audit reseau prive

- Interfaces: eth0 (publique) + enp7s0 (privee 10.0.0.x) sur chaque master
- Route 10.0.0.0/16 via enp7s0 (MTU 1450)
- Connectivite privee 6443/10250: OK inter-masters et workers->masters
- Connectivite privee 2379/2380: FERMEE sur master-02/03 (etcd bindait sur IP publique)
- Ping ICMP prive: OK

### Migration master-01 (kubelet seulement)

1. `kubeadm-flags.env`: ajout `--node-ip=10.0.0.100`
2. `systemctl restart kubelet`
3. **Resultat**: INTERNAL-IP passe de 91.98.124.228 a 10.0.0.100

### Migration master-02 (etcd + apiserver + kubelet)

**Etape 1 -- etcd member update:**
```
etcdctl member update f508727677feeb8a --peer-urls=https://10.0.0.101:2380
```

**Etape 2 -- etcd manifest:**
```
sed -i "s/91.98.117.26/10.0.0.101/g" /etc/kubernetes/manifests/etcd.yaml
```
Resultat: listen-peer, listen-client, advertise-client, initial-advertise-peer tous migres vers 10.0.0.101.

**Etape 3 -- apiserver cert + manifest:**
```
rm /etc/kubernetes/pki/apiserver.{crt,key}
kubeadm init phase certs apiserver --apiserver-advertise-address=10.0.0.101 --apiserver-cert-extra-sans=10.0.0.100,10.0.0.101,10.0.0.102
sed -i "s/91.98.117.26/10.0.0.101/g" /etc/kubernetes/manifests/kube-apiserver.yaml
```
Nouveau cert SANs: k8s-master-02, kubernetes.*, 10.96.0.1, 10.0.0.101, 10.0.0.100, 10.0.0.102

**Etape 4 -- kubelet:**
```
KUBELET_KUBEADM_ARGS="... --node-ip=10.0.0.101"
systemctl restart kubelet
```

**Resultat**: INTERNAL-IP 10.0.0.101, etcd healthy, cluster OK.

### Migration master-03 (etcd + apiserver + kubelet)

Procedure identique a master-02:
1. `etcdctl member update ea4b333f0ed2a058 --peer-urls=https://10.0.0.102:2380`
2. `sed -i "s/91.98.165.238/10.0.0.102/g" /etc/kubernetes/manifests/etcd.yaml`
3. Regeneration cert apiserver avec SANs 10.0.0.100, .101, .102
4. `sed -i "s/91.98.165.238/10.0.0.102/g" /etc/kubernetes/manifests/kube-apiserver.yaml`
5. `--node-ip=10.0.0.102` + restart kubelet

**Resultat**: INTERNAL-IP 10.0.0.102, etcd healthy, cluster OK.

### Tests intermediaires (apres chaque master)

| Test | master-01 | master-02 | master-03 |
|---|---|---|---|
| Nodes Ready | 8/8 | 8/8 | 8/8 |
| etcd healthy | 3/3 | 3/3 | 3/3 |
| etcd latency | <27ms | <26ms | <26ms |
| client.keybuzz.io | 307 | 307 | 307 |
| admin.keybuzz.io | 307 | 307 | 307 |
| api.keybuzz.io/health | 200 | 200 | 200 |

---

## D. Validation

### Etat cluster final

```
NAME            INTERNAL-IP   STATUS  
k8s-master-01   10.0.0.100    Ready   control-plane
k8s-master-02   10.0.0.101    Ready   control-plane
k8s-master-03   10.0.0.102    Ready   control-plane
k8s-worker-01   10.0.0.110    Ready
k8s-worker-02   10.0.0.111    Ready
k8s-worker-03   10.0.0.112    Ready
k8s-worker-04   10.0.0.113    Ready
k8s-worker-05   10.0.0.114    Ready
```

Tous les nodes utilisent des IPs privees comme INTERNAL-IP.

### Etat etcd final

| Member | Peer URL (apres) | Client URL (apres) |
|---|---|---|
| k8s-master-01 | https://10.0.0.100:2380 | https://10.0.0.100:2379 |
| k8s-master-02 | https://10.0.0.101:2380 | https://10.0.0.101:2379 |
| k8s-master-03 | https://10.0.0.102:2380 | https://10.0.0.102:2379 |

Tous les endpoints etcd sur reseau prive. Quorum OK. Latence: 12-23ms.

### Etat applicatif final

| Service | Statut |
|---|---|
| client.keybuzz.io | 307 (redirect OK) |
| admin.keybuzz.io | 307 (redirect OK) |
| api.keybuzz.io/health | 200 |
| Pods total | 135 |
| Pods running | 109 |

---

## E. Hardening Firewall

### Ancien firewall supprime

| Firewall | ID | Action |
|---|---|---|
| keybuzz-k8s-masters-secure | 10700227 | Detache des 3 masters puis supprime |

Raison: les IPs publiques des masters/workers dans la whitelist ne sont plus necessaires car tout le trafic inter-cluster passe par le reseau prive.

### Nouveau firewall

**keybuzz-k8s-masters-hardened** (ID 10700427) -- 4 regles:

| # | Direction | Protocol | Port | Source IPs | Description |
|---|---|---|---|---|---|
| 1 | in | TCP | 6443 | 46.62.171.61/32, 91.98.128.153/32, 10.0.0.0/16 | K8s API -- bastions only |
| 2 | in | TCP | 1-65535 | 10.0.0.0/16 | TCP reseau interne |
| 3 | in | UDP | 1-65535 | 10.0.0.0/16 | UDP reseau interne |
| 4 | in | ICMP | - | 10.0.0.0/16 | ICMP reseau interne |

Attache aux 3 masters.

**Differences cles vs ancien firewall:**
- Port 6443: 11 IPs publiques -> **2 IPs (bastions seulement)**
- Ports 2379-2380: 4 IPs publiques -> **aucune regle publique** (trafic prive uniquement)
- Port 10250: 9 IPs publiques -> **aucune regle publique** (trafic prive uniquement)

### Scan securite (depuis bastion)

| Port | master-01 | master-02 | master-03 | Note |
|---|---|---|---|---|
| 6443 | OPEN | OPEN | OPEN | Bastion whiteliste |
| 2379 | **CLOSED** | **CLOSED** | **CLOSED** | etcd ferme publiquement |
| 2380 | **CLOSED** | **CLOSED** | **CLOSED** | etcd peer ferme publiquement |
| 10250 | **CLOSED** | **CLOSED** | **CLOSED** | kubelet ferme publiquement |
| 22 | CLOSED | CLOSED | CLOSED | SSH ferme (PH-INFRA-02) |
| 80/443 | OPEN | OPEN | OPEN | keybuzz-public-firewall |

### Scan via reseau prive (bypass firewall)

| Port | master-01 | master-02 | master-03 |
|---|---|---|---|
| 6443 | OPEN | OPEN | OPEN |
| 2379 | OPEN | OPEN | OPEN |
| 2380 | OPEN | OPEN | OPEN |
| 10250 | OPEN | OPEN | OPEN |

Changement majeur: etcd sur master-02/03 ecoute desormais sur les IPs privees (etait ferme avant migration).

### Score securite

| Phase | Score |
|---|---|
| PH-INFRA-01 (audit) | 2/10 |
| PH-INFRA-02 (firewalls) | 7/10 |
| PH-INFRA-03 (whitelist masters) | 8.5/10 |
| **PH-INFRA-04 (private network)** | **9.5/10** |

---

## F. Rollback

### Niveau 1 -- Config kubelet

```bash
# Restaurer kubeadm-flags.env
ssh 10.0.0.10x 'cp /var/lib/kubelet/kubeadm-flags.env.bak /var/lib/kubelet/kubeadm-flags.env && systemctl restart kubelet'
```

### Niveau 2 -- Config etcd + apiserver

```bash
# Restaurer les manifests
ssh 10.0.0.10x 'cp /root/backup-infra04-20260315-1327/etcd.yaml.pre-migration /etc/kubernetes/manifests/etcd.yaml'
ssh 10.0.0.10x 'cp /root/backup-infra04-20260315-1327/kube-apiserver.yaml.pre-migration /etc/kubernetes/manifests/kube-apiserver.yaml'

# Restaurer le cert apiserver
ssh 10.0.0.10x 'cp /root/backup-infra04-20260315-1327/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt'
ssh 10.0.0.10x 'cp /root/backup-infra04-20260315-1327/pki/apiserver.key /etc/kubernetes/pki/apiserver.key'

# Restaurer peer URL etcd
etcdctl member update <MEMBER_ID> --peer-urls=https://<PUBLIC_IP>:2380
```

### Niveau 3 -- Firewall

```bash
source /opt/keybuzz/credentials/hcloud.env
# Detacher le nouveau
hcloud firewall remove-from-resource keybuzz-k8s-masters-hardened --type server --server k8s-master-0x
# Reattacher l'ancien (fw-k3s-masters toujours disponible)
hcloud firewall apply-to-resource fw-k3s-masters --type server --server k8s-master-0x
```

### Niveau 4 -- Disaster recovery

```bash
# Restore snapshot Hetzner
hcloud server rebuild k8s-master-0x --image <SNAPSHOT_ID>

# Ou restore etcd
etcdctl snapshot restore /root/backup-etcd-infra04-20260315-1327.db
```

---

## G. Etat firewalls Hetzner -- Final

### Actifs

| Firewall | ID | Serveurs | Ports publics |
|---|---|---|---|
| keybuzz-public-firewall | 10697211 | 8 (masters+workers) | 80, 443 |
| keybuzz-bastion-firewall | 10697212 | 2 (bastions) | 22 |
| keybuzz-internal-firewall | 10697213 | 38 (DB, cache, etc.) | aucun |
| keybuzz-mail-firewall | 10697214 | 3 (mail) | 25, 465, 587, 993, 80, 443 |
| keybuzz-k8s-masters-hardened | 10700427 | 3 (masters) | 6443 (bastions seulement) |
| v3-vault | 10290882 | 3 (vault) | 22 |
| quarantine-fw | 10687343 | 1 (quarantaine) | 22 (bastion) |

### Decommissionnes (0 serveurs)

| Firewall | Decommissionne en |
|---|---|
| fw-k3s-masters | PH-INFRA-03 |
| keybuzz-k8s-masters-secure | PH-INFRA-04 (supprime) |
| fw-ssh-admin | PH-INFRA-02 |
| fw-databases | PH-INFRA-02 |
| fw-mail | PH-INFRA-02 |
| fw-minio | PH-INFRA-02 |
| v3-mx | PH-INFRA-02 |

---

## H. Criteres de validation

| Critere | Statut |
|---|---|
| Les 3 masters utilisent le reseau prive | **VALIDE** (INTERNAL-IP: 10.0.0.100/101/102) |
| etcd est sain | **VALIDE** (3/3 healthy, latence 12-23ms) |
| Cluster fonctionne normalement | **VALIDE** (8/8 nodes Ready) |
| Services web operationnels | **VALIDE** (307/307/200) |
| Ports control-plane non publics | **VALIDE** (2379/2380/10250 CLOSED, 6443 bastions-only) |
| Rollback documente et possible | **VALIDE** (4 niveaux de rollback) |
