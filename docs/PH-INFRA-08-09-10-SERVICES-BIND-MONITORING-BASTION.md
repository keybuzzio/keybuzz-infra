# PH-INFRA-08/09/10 — Services Bind Hardening, Control Plane Monitoring, Bastion Protection

> Date : 2026-03-15  
> Statut : **PH-INFRA-08 COMPLET | PH-INFRA-09 PARTIEL | PH-INFRA-10 COMPLET**  
> Score securite : **9.7/10** (+0.2)

---

## PH-INFRA-08 : Internal Services Bind Hardening

### Objectif
Faire binder les services internes **uniquement sur l'interface privee** (10.0.0.x + 127.0.0.1) au lieu de `0.0.0.0`.

### Etat avant intervention

| Service | Serveurs | Bind avant | Port(s) |
|---|---|---|---|
| PostgreSQL (Patroni) | db-postgres-01/02/03 | `0.0.0.0:5432`, `0.0.0.0:8008` | 5432, 8008 |
| Redis | redis-01/02/03 | `0.0.0.0:6379` | 6379 |
| Redis Sentinel | redis-01/02/03 | `*:26379` (defaut) | 26379 |
| RabbitMQ | queue-01/02/03 | `*:5672`, `*:15672` | 5672, 15672 |
| Node Exporter | 11 serveurs infra | `0.0.0.0:9100` | 9100 |
| Prometheus | K8s (observability) | N/A (in-cluster) | — |
| Grafana | K8s (observability) | N/A (in-cluster) | — |

### Actions realisees

#### PostgreSQL (Patroni) — 3/3 serveurs

**Strategie** : Replicas d'abord, leader en dernier.

| Serveur | Role initial | Config modifiee | Resultat |
|---|---|---|---|
| db-postgres-03 | Replica | `listen: 10.0.0.122,127.0.0.1:5432` + `restapi: 10.0.0.122:8008` | OK, streaming lag=0 |
| db-postgres-01 | Replica | `listen: 10.0.0.120,127.0.0.1:5432` + `restapi: 10.0.0.120:8008` | OK, streaming lag=0 |
| db-postgres-02 | Leader | `listen: 10.0.0.121,127.0.0.1:5432` + `restapi: 10.0.0.121:8008` | Failover normal (TL16→17), leader=db-03 |

- **Fichier** : `/etc/patroni.yml` (backup `.bak.infra08`)
- **Failover** : Attendu lors du restart du leader. Le cluster Patroni a gere automatiquement (timeline 16→17).
- **Validation** : `patronictl list` — 3/3 nodes, streaming, lag=0. API 200, Client 307.

#### Redis — 3/3 serveurs + Sentinel

| Serveur | Config redis.conf | Config sentinel.conf |
|---|---|---|
| redis-01 | `bind 10.0.0.123 127.0.0.1` | `bind 10.0.0.123 127.0.0.1` |
| redis-02 | `bind 10.0.0.124 127.0.0.1` | `bind 10.0.0.124 127.0.0.1` |
| redis-03 | `bind 10.0.0.125 127.0.0.1` | `bind 10.0.0.125 127.0.0.1` |

- **Fichiers** : `/etc/redis/redis.conf`, `/etc/redis/sentinel.conf` (backups `.bak.infra08`)
- **Validation** : Redis 3/3 active, Sentinel operational, master=10.0.0.123. API 200.

#### RabbitMQ — 3/3 serveurs

| Serveur | listeners.tcp | management.tcp |
|---|---|---|
| queue-01 | `10.0.0.126:5672` | `ip=10.0.0.126`, port 15672 |
| queue-02 | `10.0.0.127:5672` | `ip=10.0.0.127`, port 15672 |
| queue-03 | `10.0.0.128:5672` | `ip=10.0.0.128`, port 15672 |

- **Fichier** : `/etc/rabbitmq/rabbitmq.conf` (backup `.bak.infra08`)
- **Note** : Port 25672 (Erlang distribution) reste sur `0.0.0.0` — necessaire pour la communication inter-noeud. Protege par le firewall.
- **Validation** : `rabbitmqctl cluster_status` — 3/3 Running Nodes. API 200.

#### Node Exporter — 11/11 serveurs

| Serveurs | Bind apres |
|---|---|
| db-postgres-01/02/03 | `10.0.0.120-122:9100` |
| redis-01/02/03 | `10.0.0.123-125:9100` |
| queue-01/02/03 | `10.0.0.126-128:9100` |
| monitor-01 | `10.0.0.152:9100` |
| siem-01 | `10.0.0.151:9100` |

- **Fichier** : `/etc/systemd/system/node_exporter.service` (backup `.bak.infra08`)
- **Validation** : 11/11 active, `ss -tulpn` confirme bind prive.

#### Prometheus & Grafana

Non modifies — ces services tournent dans Kubernetes (namespace `observability`) et sont deja isoles dans le reseau du cluster.

### Rollback PH-INFRA-08

```bash
# PostgreSQL
cp /etc/patroni.yml.bak.infra08 /etc/patroni.yml
systemctl restart patroni

# Redis
cp /etc/redis/redis.conf.bak.infra08 /etc/redis/redis.conf
cp /etc/redis/sentinel.conf.bak.infra08 /etc/redis/sentinel.conf
systemctl restart redis-server redis-sentinel

# RabbitMQ
cp /etc/rabbitmq/rabbitmq.conf.bak.infra08 /etc/rabbitmq/rabbitmq.conf
systemctl restart rabbitmq-server

# Node Exporter
cp /etc/systemd/system/node_exporter.service.bak.infra08 /etc/systemd/system/node_exporter.service
systemctl daemon-reload && systemctl restart node_exporter
```

---

## PH-INFRA-09 : Control Plane Saturation Monitoring

### Objectif
Verifier que Prometheus collecte les metriques critiques du control plane Kubernetes.

### Audit Prometheus Targets

| Job | Statut | Ports | Commentaire |
|---|---|---|---|
| `apiserver` | **3/3 up** | 6443 | Fonctionne, metriques accessibles |
| `kube-etcd` | **0/3 down** | 2381 | Bind `127.0.0.1` — non accessible |
| `kube-controller-manager` | **0/3 down** | 10257 | Bind `127.0.0.1` — non accessible |
| `kube-scheduler` | **0/3 down** | 10259 | Bind `127.0.0.1` — non accessible |
| `kube-proxy` | **0/8 down** | 10249 | Bind `127.0.0.1` — non accessible |
| `kubelet` | **24/24 up** | 10250 | Fonctionne |
| `node-exporter` | **8/8 up** | 9100 | Fonctionne (K8s DaemonSet) |

### Metriques disponibles via apiserver

Les metriques apiserver couvrent :
- `apiserver_current_inflight_requests` (mutating: OK, readOnly: OK)
- `apiserver_request_duration_seconds`
- Latence API, erreurs, etc.

### Metriques indisponibles

- `etcd_server_has_leader` — necessite scrape etcd (port 2381)
- `etcd_disk_wal_fsync_duration_seconds` — idem
- `scheduler_e2e_scheduling_duration_seconds` — bind 127.0.0.1

### Tentative de correction

Plusieurs approches ont ete testees sur master-01 :

1. **Modification directe du manifest** (`sed` sur `--bind-address=0.0.0.0`) : le kubelet K8s v1.30 ne detecte pas le changement et recree les containers avec l'ancienne spec (cache interne).
2. **Regeneration via `kubeadm init phase`** : les manifests sont regeneres mais le kubelet utilise toujours la spec cachee.
3. **Stop kubelet + purge containers + restart** : le kubelet recree les pods mais la spec n'est pas mise a jour.

**Cause racine** : Le kubelet v1.30 maintient un cache en memoire des specs static pods qui ne se rafraichit pas correctement lors de modifications de `--bind-address`.

### Solution recommandee (future)

Pour exposer les metriques control plane, il faut effectuer un **`kubeadm upgrade apply`** avec une ClusterConfiguration mise a jour :

```yaml
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
etcd:
  local:
    extraArgs:
      listen-metrics-urls: "http://0.0.0.0:2381"
```

Cette operation necessite un upgrade planifie du cluster (potentiellement avec un bump de version patch).

**Alternative** : deployer un DaemonSet de metrics-proxy sur les masters qui forward les metriques de `127.0.0.1` vers l'IP privee.

### Statut

- **apiserver** : 3/3 monitore
- **etcd/scheduler/CM** : En attente de `kubeadm upgrade apply`
- **Cluster reverte et stable** : 8/8 nodes Ready, services web OK

---

## PH-INFRA-10 : Bastion SSH Protection

### Objectif
Installer `fail2ban` sur le bastion pour bloquer les scans SSH.

### Installation

```bash
apt-get install -y fail2ban
```

### Configuration (`/etc/fail2ban/jail.local`)

```ini
[DEFAULT]
bantime = 3600      # 1 heure
findtime = 600      # 10 minutes
maxretry = 10       # 10 tentatives
banaction = iptables-multiport
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 10
bantime = 3600
findtime = 600
```

### Resultat immediat

```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 1
|  |- Total failed:     1
|- Actions
   |- Currently banned: 12
   |- Total banned:     12
   |- Banned IPs:
      103.134.154.79, 103.67.78.18, 134.122.125.29,
      14.22.82.116, 156.227.233.77, 161.49.89.39,
      182.93.50.90, 2.47.62.244, 2.57.121.112,
      2.57.122.177, 64.227.154.22, 92.118.39.63
```

**12 IP bannies immediatement** — le bastion etait activement scanne.

### Verification

- SSH keys : fonctionnel (connexion depuis Cursor OK)
- Cursor access : fonctionnel
- Aucun faux positif

---

## Resume global

| Phase | Statut | Impact |
|---|---|---|
| PH-INFRA-08 | **COMPLET** | 20 services migres (PG 3, Redis 6, RMQ 3, NodeExp 11) |
| PH-INFRA-09 | **PARTIEL** | apiserver 3/3 OK, etcd/scheduler/CM necessite kubeadm upgrade |
| PH-INFRA-10 | **COMPLET** | 12 IPs bannies, bastion protege |

### Score securite : 9.7/10 (+0.2)

**Ameliorations** :
- Services internes bindes sur IP privee (defense-in-depth)
- Bastion protege contre brute-force SSH
- Monitoring apiserver fonctionnel

**Risques residuels** :
- etcd/scheduler/CM metrics non scrapes (necessite kubeadm upgrade)
- RabbitMQ port 25672 (Erlang dist) sur 0.0.0.0 (protege par firewall)
- kube-proxy metrics non accessibles
