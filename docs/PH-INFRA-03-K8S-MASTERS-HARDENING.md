# PH-INFRA-03 -- Kubernetes Masters Network Hardening

> Date: 2026-03-15
> Statut: TERMINEE
> Environnement: Production (Hetzner Cloud)
> Prerequis: PH-INFRA-02 (Hetzner Firewall Hardening)
> Downtime: 0

---

## 1. Contexte

PH-INFRA-02 a securise l'infrastructure en creant des firewalls Hetzner et en fermant les ports publics (DB, Redis, RabbitMQ, SSH). Un risque residuel majeur subsistait : les K8s masters utilisent leurs IPs publiques comme `INTERNAL-IP` dans Kubernetes, exposant les ports du control plane a Internet :

| Port | Service | Risque |
|---|---|---|
| 6443 | Kubernetes API | Acces non autorise au cluster |
| 2379 | etcd client | Lecture/ecriture de toutes les donnees du cluster |
| 2380 | etcd peer | Corruption du consensus etcd |
| 10250 | kubelet | Execution de commandes sur les nodes |

Ces 4 ports etaient accessibles depuis `0.0.0.0/0` via le firewall `fw-k3s-masters`.

---

## 2. Architecture reseau

### Masters

| Serveur | IP publique | IP privee | K8s INTERNAL-IP | etcd bind |
|---|---|---|---|---|
| k8s-master-01 | 91.98.124.228 | 10.0.0.100 | 91.98.124.228 | 10.0.0.100 (prive) |
| k8s-master-02 | 91.98.117.26 | 10.0.0.101 | 91.98.117.26 | 91.98.117.26 (public) |
| k8s-master-03 | 91.98.165.238 | 10.0.0.102 | 91.98.165.238 | 91.98.165.238 (public) |

### Workers

| Serveur | IP publique | IP privee | K8s INTERNAL-IP |
|---|---|---|---|
| k8s-worker-01 | 116.203.135.192 | 10.0.0.110 | 10.0.0.110 |
| k8s-worker-02 | 91.99.164.62 | 10.0.0.111 | 10.0.0.111 |
| k8s-worker-03 | 157.90.119.183 | 10.0.0.112 | 10.0.0.112 |
| k8s-worker-04 | 91.98.200.38 | 10.0.0.113 | 10.0.0.113 |
| k8s-worker-05 | 188.245.45.242 | 10.0.0.114 | 10.0.0.114 |

### Bastions

| Serveur | IP publique |
|---|---|
| install-v3 | 46.62.171.61 |
| backend-01 | 91.98.128.153 |

### Point critique

- Le kubeconfig pointe vers `https://10.0.0.100:6443` (IP privee) -- kubectl depuis le bastion passe par le reseau prive et n'est PAS affecte par les firewalls Hetzner
- etcd master-01 bind sur IP privee (10.0.0.100), master-02/03 bind sur IPs publiques
- Le traffic reseau prive (`10.0.0.0/16`) bypass completement les firewalls Hetzner Cloud
- La communication inter-master etcd via IPs publiques necessite un whitelisting explicite

---

## 3. Firewall cree

### keybuzz-k8s-masters-secure (ID 10700227)

| # | Direction | Protocol | Port | Source IPs | Description |
|---|---|---|---|---|---|
| 1 | in | TCP | 6443 | 91.98.124.228/32, 91.98.117.26/32, 91.98.165.238/32, 116.203.135.192/32, 91.99.164.62/32, 157.90.119.183/32, 91.98.200.38/32, 188.245.45.242/32, 46.62.171.61/32, 91.98.128.153/32, 10.0.0.0/16 | K8s API -- masters+workers+bastions |
| 2 | in | TCP | 2379-2380 | 91.98.124.228/32, 91.98.117.26/32, 91.98.165.238/32, 10.0.0.0/16 | etcd -- masters only |
| 3 | in | TCP | 10250 | 91.98.124.228/32, 91.98.117.26/32, 91.98.165.238/32, 116.203.135.192/32, 91.99.164.62/32, 157.90.119.183/32, 91.98.200.38/32, 188.245.45.242/32, 10.0.0.0/16 | kubelet -- masters+workers |
| 4 | in | TCP | 1-65535 | 10.0.0.0/16 | TCP reseau interne |
| 5 | in | UDP | 1-65535 | 10.0.0.0/16 | UDP reseau interne |
| 6 | in | ICMP | - | 10.0.0.0/16 | ICMP reseau interne |

### Serveurs attaches

| Serveur | Firewalls actifs |
|---|---|
| k8s-master-01 | keybuzz-public-firewall (10697211) + keybuzz-k8s-masters-secure (10700227) |
| k8s-master-02 | keybuzz-public-firewall (10697211) + keybuzz-k8s-masters-secure (10700227) |
| k8s-master-03 | keybuzz-public-firewall (10697211) + keybuzz-k8s-masters-secure (10700227) |

### Firewall decommissionne

| Firewall | ID | Serveurs avant | Serveurs apres |
|---|---|---|---|
| fw-k3s-masters | 2449800 | 3 (les 3 masters) | 0 |

---

## 4. Deploiement progressif

### Strategie zero-gap

Pour chaque master :
1. **ATTACHER** `keybuzz-k8s-masters-secure` (union avec l'ancien = toujours permissif)
2. **DETACHER** `fw-k3s-masters` (seul le nouveau restrictif s'applique)
3. Tests immediats

Cette approche garantit qu'il n'y a jamais de moment ou les ports K8s sont bloques.

### Chronologie

| Heure | Action | Resultat |
|---|---|---|
| 12:51 | Firewall cree (ID 10700227) | OK |
| 12:52 | master-01 : attach new + detach old | OK |
| 12:52 | Tests master-01 | 8/8 nodes Ready, etcd healthy (16ms) |
| 12:53 | master-02 : attach new + detach old | OK |
| 12:53 | Tests master-02 | 8/8 nodes Ready, etcd healthy (16ms) |
| 12:54 | master-03 : attach new + detach old | OK |
| 12:54 | Tests master-03 | 8/8 nodes Ready, etcd healthy (21ms) |
| 12:55 | Scan securite | Ports 2379/2380/10250 fermes depuis Internet |

---

## 5. Tests effectues

### Cluster Kubernetes

| Test | Resultat |
|---|---|
| `kubectl get nodes` | 8/8 Ready (3 masters + 5 workers) |
| `kubectl cluster-info` | Control plane running at https://10.0.0.100:6443 |
| Pods en erreur | 0 |

### etcd

| Master | Health | Latency |
|---|---|---|
| k8s-master-01 | healthy | 16ms |
| k8s-master-02 | healthy | 16ms |
| k8s-master-03 | healthy | 21ms |

etcd member list :
- k8s-master-01: `https://10.0.0.100:2380` (IP privee)
- k8s-master-02: `https://91.98.117.26:2380` (IP publique)
- k8s-master-03: `https://91.98.165.238:2380` (IP publique)

### Services web

| Service | HTTP Code |
|---|---|
| client.keybuzz.io | 307 (redirect OK) |
| admin.keybuzz.io | 307 (redirect OK) |
| api.keybuzz.io/health | 200 |

---

## 6. Resultats securite

### Scan ports publics (depuis le bastion -- non whiteliste pour 2379/2380/10250)

| Port | master-01 | master-02 | master-03 | Statut |
|---|---|---|---|---|
| 6443 | OPEN | OPEN | OPEN | Attendu (bastion whiteliste) |
| 2379 | **CLOSED** | **CLOSED** | **CLOSED** | **SECURISE** |
| 2380 | **CLOSED** | **CLOSED** | **CLOSED** | **SECURISE** |
| 10250 | **CLOSED** | **CLOSED** | **CLOSED** | **SECURISE** |
| 22 | CLOSED | CLOSED | CLOSED | Deja ferme (PH-INFRA-02) |
| 5432 | CLOSED | CLOSED | CLOSED | Deja ferme |
| 6379 | CLOSED | CLOSED | CLOSED | Deja ferme |
| 5672 | CLOSED | CLOSED | CLOSED | Deja ferme |
| 8200 | CLOSED | CLOSED | CLOSED | Deja ferme |

### Scan ports prives (reseau 10.0.0.0/16 -- bypass firewall)

| Port | master-01 | master-02 | master-03 |
|---|---|---|---|
| 6443 | OPEN | OPEN | OPEN |
| 2379 | OPEN | CLOSED* | CLOSED* |
| 2380 | OPEN | CLOSED* | CLOSED* |
| 10250 | OPEN | OPEN | OPEN |

*etcd master-02/03 bind sur IP publique, pas sur IP privee. Le traffic etcd inter-master passe par les IPs publiques whitelistees.

---

## 7. Avant / Apres

### Surface d'attaque masters (ports publics)

| Port | Avant PH-INFRA-03 | Apres PH-INFRA-03 |
|---|---|---|
| 6443 (K8s API) | 0.0.0.0/0 (tout Internet) | 11 IPs (3 masters + 5 workers + 2 bastions + 10.0.0.0/16) |
| 2379 (etcd) | 0.0.0.0/0 (tout Internet) | 4 sources (3 masters + 10.0.0.0/16) |
| 2380 (etcd peer) | 0.0.0.0/0 (tout Internet) | 4 sources (3 masters + 10.0.0.0/16) |
| 10250 (kubelet) | 0.0.0.0/0 (tout Internet) | 9 sources (3 masters + 5 workers + 10.0.0.0/16) |

### Score securite

| Metrique | PH-INFRA-02 | PH-INFRA-03 |
|---|---|---|
| Score global | 7/10 | **8.5/10** |
| Ports K8s publics | 4 (0.0.0.0/0) | 0 (tout restreint) |
| etcd public | OUVERT | **FERME** |
| kubelet public | OUVERT | **FERME** |
| K8s API public | OUVERT | Restreint (whitelist) |

---

## 8. Firewalls Hetzner -- Etat final

### Firewalls actifs

| Firewall | ID | Serveurs | Role |
|---|---|---|---|
| keybuzz-public-firewall | 10697211 | 8 | K8s masters + workers (HTTP/HTTPS) |
| keybuzz-bastion-firewall | 10697212 | 2 | Bastions (SSH public) |
| keybuzz-internal-firewall | 10697213 | 38 | DB, cache, queues, monitoring, stockage |
| keybuzz-mail-firewall | 10697214 | 3 | Serveurs mail (SMTP, IMAP) |
| keybuzz-k8s-masters-secure | 10700227 | 3 | K8s masters (API, etcd, kubelet restreints) |
| v3-vault | 10290882 | 3 | Vault servers |
| quarantine-fw | 10687343 | 1 | Serveur quarantaine |

### Firewalls decommissionnes (0 serveurs)

| Firewall | ID | Decommissionne en |
|---|---|---|
| fw-k3s-masters | 2449800 | PH-INFRA-03 |
| fw-ssh-admin | 2449798 | PH-INFRA-02 |
| fw-databases | 2449801 | PH-INFRA-02 |
| fw-mail | 2449802 | PH-INFRA-02 |
| fw-minio | 10087224 | PH-INFRA-02 |
| v3-mx | 10310131 | PH-INFRA-02 |

---

## 9. Rollback

En cas de probleme :

```bash
source /opt/keybuzz/credentials/hcloud.env

# Rollback: reattacher l'ancien firewall permissif
hcloud firewall apply-to-resource fw-k3s-masters --type server --server k8s-master-01
hcloud firewall apply-to-resource fw-k3s-masters --type server --server k8s-master-02
hcloud firewall apply-to-resource fw-k3s-masters --type server --server k8s-master-03

# Optionnel: detacher le nouveau
hcloud firewall remove-from-resource keybuzz-k8s-masters-secure --type server --server k8s-master-01
hcloud firewall remove-from-resource keybuzz-k8s-masters-secure --type server --server k8s-master-02
hcloud firewall remove-from-resource keybuzz-k8s-masters-secure --type server --server k8s-master-03
```

Temps de rollback : < 30 secondes.

---

## 10. Risques residuels et prochaines etapes

### Risques residuels

| Risque | Severite | Mitigation |
|---|---|---|
| K8s masters INTERNAL-IP = IP publique | Moyenne | Migration vers IP privee requiert reconfiguration kubeadm (risque cluster) |
| etcd master-02/03 bind sur IP publique | Moyenne | Reconfiguration etcd pour bind sur IP privee |
| Workers ont des IPs publiques | Basse | Monitore par keybuzz-public-firewall |
| fw-k3s-masters decommissionne mais pas supprime | Tres basse | Suppression possible apres stabilisation |

### Prochaines etapes proposees

| Phase | Description | Priorite |
|---|---|---|
| PH-INFRA-04 | Suppression firewalls decommissionnes | Basse |
| PH-INFRA-05 | Migration masters INTERNAL-IP vers IP privee | Haute (necessaire long terme) |
| PH-INFRA-06 | Restriction K8s API : supprimer bastions de la whitelist 6443 (kubectl uniquement via private) | Moyenne |
| PH-INFRA-07 | Monitoring firewall (alertes si modification non autorisee) | Moyenne |

---

## 11. Criteres de validation

| Critere | Statut |
|---|---|
| Ports masters ne sont plus publics | VALIDE |
| Cluster Kubernetes fonctionne normalement | VALIDE (8/8 nodes, etcd healthy) |
| Aucune interruption de service | VALIDE (0 downtime) |
| Rollback possible | VALIDE (fw-k3s-masters disponible) |
| Securite amelioree | VALIDE (score 7/10 -> 8.5/10) |
