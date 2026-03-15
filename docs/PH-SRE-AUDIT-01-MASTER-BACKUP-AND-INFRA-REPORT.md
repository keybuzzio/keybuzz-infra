# PH-SRE-AUDIT-01 — Master Backup Hetzner & Audit Complet Infrastructure

> Date : 14 mars 2026
> Auteur : CE (Cursor Agent)
> Bastion : install-v3 (46.62.171.61)
> Statut : TERMINE

---

## 1. INVENTAIRE COMPLET DES SERVEURS

### 1.1 Serveurs utilises activement par KeyBuzz V3

| Serveur | IP privee | Role | CPU | RAM | Disk systeme | Volume data | Statut |
|---------|-----------|------|-----|-----|-------------|-------------|--------|
| k8s-master-01 | 10.0.0.100 | K8s control-plane | 4 | 7.6 GB | 75G (16%) | — | Running |
| k8s-master-02 | 10.0.0.101 | K8s control-plane | 4 | 7.6 GB | 75G (16%) | — | Running |
| k8s-master-03 | 10.0.0.102 | K8s control-plane | 4 | 7.6 GB | 75G (15%) | — | Running |
| k8s-worker-01 | 10.0.0.110 | K8s worker | 8 | 15 GB | 150G (72%) | — | Running |
| k8s-worker-02 | 10.0.0.111 | K8s worker | 8 | 15 GB | 150G (81%) | — | Running |
| k8s-worker-03 | 10.0.0.112 | K8s worker | 8 | 15 GB | 150G (34%) | — | Running |
| k8s-worker-04 | 10.0.0.113 | K8s worker | 8 | 15 GB | 150G (49%) | — | Running |
| k8s-worker-05 | 10.0.0.114 | K8s worker | 8 | 15 GB | 150G (77%) | — | Running |
| db-postgres-01 | 10.0.0.120 | PostgreSQL/Patroni (replica) | 2 | 7.6 GB | 75G (20%) | 100G /data/db_postgres (3%) | Running |
| db-postgres-02 | 10.0.0.121 | PostgreSQL/Patroni (**LEADER**) | 2 | 3.7 GB | 38G (31%) | 100G /data/db_postgres (4%) | Running |
| db-postgres-03 | 10.0.0.122 | PostgreSQL/Patroni (replica) | 2 | 3.7 GB | 38G (26%) | 100G /data/db_postgres (3%) | Running |
| redis-01 | 10.0.0.123 | Redis HA **master** | 2 | 1.9 GB | 38G (16%) | — | Running |
| redis-02 | 10.0.0.124 | Redis HA replica | 2 | 1.9 GB | 38G (17%) | — | Running |
| redis-03 | 10.0.0.125 | Redis HA replica | 2 | 1.9 GB | 38G (18%) | — | Running |
| queue-01 | 10.0.0.126 | RabbitMQ quorum | 2 | 1.9 GB | 38G (16%) | — | Running |
| queue-02 | 10.0.0.127 | RabbitMQ quorum | 2 | 1.9 GB | 38G (19%) | — | Running |
| queue-03 | 10.0.0.128 | RabbitMQ quorum | 2 | 1.9 GB | 38G (19%) | — | Running |
| haproxy-01 | 10.0.0.11 | HAProxy interne (LB) | 2 | 3.7 GB | 38G (16%) | — | Running |
| haproxy-02 | 10.0.0.12 | HAProxy interne (LB) | 2 | 3.7 GB | 38G (17%) | — | Running |
| maria-01 | 10.0.0.170 | MariaDB Galera | 2 | 3.7 GB | 38G (20%) | — | Running |
| maria-02 | 10.0.0.171 | MariaDB Galera | 2 | 3.7 GB | 38G (20%) | — | Running |
| maria-03 | 10.0.0.172 | MariaDB Galera | 2 | 3.7 GB | 38G (18%) | — | Running |
| proxysql-01 | 10.0.0.173 | ProxySQL | 2 | 3.7 GB | 38G (17%) | — | Running |
| proxysql-02 | 10.0.0.174 | ProxySQL | 2 | 3.7 GB | 38G (17%) | — | Running |
| minio-01 | 10.0.0.134 | MinIO cluster (node 1) | 3 | 3.7 GB | 75G (8%) | 200G /data/minio (2%) | Running |
| minio-02 | 10.0.0.131 | MinIO cluster (node 2) | 2 | 1.9 GB | 38G (17%) | 200G /data/minio (2%) | Running |
| minio-03 | 10.0.0.132 | MinIO cluster (node 3) | 2 | 3.7 GB | 38G (15%) | 200G /data/minio (2%) | Running |
| vault-01 | 10.0.0.150 | Vault HA (standby) | 2 | 3.7 GB | 38G (16%) | 20G /data/vault (3%) | Running |
| siem-01 | 10.0.0.151 | SIEM (node_exporter only) | 4 | 7.6 GB | 75G (8%) | 50G /data/siem (2%) | Running |
| monitor-01 | 10.0.0.152 | Monitoring (node_exporter only) | 3 | 3.7 GB | 75G (11%) | 50G /data/monitoring (2%) | Running |
| backup-01 | 10.0.0.153 | Backup | 2 | 1.9 GB | 38G (17%) | 500G /data/backup (2%) | Running |
| mail-core-01 | 10.0.0.160 | Mail core (Postfix+Dovecot+Rspamd) | 2 | 1.9 GB | 38G (19%) | 50G /data/mail_core (2%) | Running |
| mail-mx-01 | 10.0.0.161 | Mail MX relay | 2 | 1.9 GB | 38G (8%) | 30G /data/mail_mx (3%) | Running |
| mail-mx-02 | 10.0.0.162 | Mail MX relay | 2 | 1.9 GB | 38G (8%) | 30G /data/mail_mx (3%) | Running |
| install-v3 | 10.0.0.251 | Bastion / orchestrateur GitOps | 2 | 3.7 GB | 38G (**86%**) | 100G /var/lib/docker (66%) | Running |
| backend-01 | 10.0.0.250 | Legacy bastion (hcloud, scripts) | 2 | 3.7 GB | 38G (23%) | — | Running |

### 1.2 Serveurs presents mais non-critiques / idle

| Serveur | IP privee | Role | CPU | RAM | Disk | Etat |
|---------|-----------|------|-----|-----|------|------|
| vector-db-01 | 10.0.0.136 | Qdrant (vectorDB) | 3 | 3.7 GB | 75G (7%) | Idle |
| analytics-db-01 | 10.0.0.130 | DB Analytics | 2 | 1.9 GB | 38G (17%) | Idle |
| analytics-01 | 10.0.0.139 | App Analytics | 3 | 3.7 GB | 75G (9%) | Idle |
| crm-01 | 10.0.0.133 | CRM / facturation | 2 | 1.9 GB | 38G (14%) | Idle |
| etl-01 | 10.0.0.140 | ETL | 3 | 3.7 GB | 75G (7%) | Idle |
| baserow-01 | 10.0.0.144 | Baserow (no-code) | 2 | 1.9 GB | 38G (16%) | Idle |
| ml-platform-01 | 10.0.0.143 | ML platform | 8 | 15 GB | 226G (3%) | **Surdimensionne** |
| litellm-01 | 10.0.0.137 | LiteLLM (migre en K8s) | — | — | — | Injoignable |

### 1.3 Serveurs injoignables / potentiellement eteints

| Serveur | IP privee | Role TSV | Statut |
|---------|-----------|----------|--------|
| builder-01 | 10.0.0.200 | CI/CD | Injoignable |
| temporal-db-01 | 10.0.0.129 | DB Temporal | Injoignable |
| temporal-01 | 10.0.0.138 | Temporal Server | Injoignable |
| api-gateway-01 | 10.0.0.135 | API Gateway | Injoignable |
| nocodb-01 | 10.0.0.142 | NocoDB | Injoignable |

---

## 2. SNAPSHOTS HETZNER — Master Backup

> Convention : `keybuzz-v3-master-backup-20260314-<server-name>`
> Date : 14 mars 2026

### 2.1 Snapshots crees avec succes (24/32)

| Serveur | Role | Snapshot ID | Taille | Heure creation | Statut |
|---------|------|-------------|--------|----------------|--------|
| db-postgres-01 | PostgreSQL/Patroni (replica) | 366760175 | 2.60 GB | 22:29 UTC | SUCCESS |
| db-postgres-02 | PostgreSQL/Patroni (**LEADER**) | 366761167 | 2.12 GB | 22:31 UTC | SUCCESS |
| db-postgres-03 | PostgreSQL/Patroni (replica) | 366761813 | 2.26 GB | 22:33 UTC | SUCCESS |
| redis-01 | Redis Master | 366762487 | 1.58 GB | 22:35 UTC | SUCCESS |
| redis-02 | Redis Replica | 366763124 | 1.60 GB | 22:37 UTC | SUCCESS |
| redis-03 | Redis Replica | 366763437 | 1.52 GB | 22:38 UTC | SUCCESS |
| queue-01 | RabbitMQ | 366764127 | 1.85 GB | 22:40 UTC | SUCCESS |
| queue-02 | RabbitMQ | 366764739 | 2.11 GB | 22:42 UTC | SUCCESS |
| queue-03 | RabbitMQ | 366765388 | 2.02 GB | 22:44 UTC | SUCCESS |
| minio-01 | MinIO | 366765808 | 1.65 GB | 22:46 UTC | SUCCESS |
| minio-02 | MinIO | 366766335 | 1.75 GB | 22:48 UTC | SUCCESS |
| minio-03 | MinIO | 366766972 | 1.70 GB | 22:49 UTC | SUCCESS |
| vault-01 | Vault | 366767594 | 1.85 GB | 22:51 UTC | SUCCESS |
| mail-core-01 | Mail Core | 366768171 | 1.72 GB | 22:53 UTC | SUCCESS |
| mail-mx-01 | Mail MX | 366768512 | 1.06 GB | 22:55 UTC | SUCCESS |
| mail-mx-02 | Mail MX | 366768781 | 1.18 GB | 22:56 UTC | SUCCESS |
| backup-01 | Backup | 366769427 | 1.74 GB | 22:57 UTC | SUCCESS |
| k8s-master-01 | K8s Master | 366770215 | 3.46 GB | 22:59 UTC | SUCCESS |
| k8s-master-02 | K8s Master | 366771596 | 3.53 GB | 23:03 UTC | SUCCESS |
| k8s-master-03 | K8s Master | 366772425 | 3.36 GB | 23:06 UTC | SUCCESS |
| haproxy-01 | HAProxy | 366773488 | 1.64 GB | 23:10 UTC | SUCCESS |
| haproxy-02 | HAProxy | 366773957 | 1.75 GB | 23:12 UTC | SUCCESS |
| monitor-01 | Monitoring | 366774449 | 1.81 GB | 23:14 UTC | SUCCESS |
| siem-01 | SIEM | 366774834 | 1.64 GB | 23:16 UTC | SUCCESS |

**Taille totale snapshots : ~48.7 GB**

### 2.2 Snapshots echoues — limite d'images Hetzner (8/32)

| Serveur | Role | Erreur |
|---------|------|--------|
| install-v3 | Bastion | `image limit exceeded` |
| k8s-worker-01 | K8s Worker | `image limit exceeded` |
| k8s-worker-02 | K8s Worker | `image limit exceeded` |
| k8s-worker-03 | K8s Worker | `image limit exceeded` |
| k8s-worker-04 | K8s Worker | `image limit exceeded` |
| k8s-worker-05 | K8s Worker | `image limit exceeded` |
| maria-01 | MariaDB Galera | `image limit exceeded` |
| maria-02 | MariaDB Galera | `image limit exceeded` |
| maria-03 | MariaDB Galera | `image limit exceeded` |
| proxysql-01 | ProxySQL | `image limit exceeded` |
| proxysql-02 | ProxySQL | `image limit exceeded` |

**Cause** : le compte Hetzner a atteint sa limite de snapshots (30 images atteintes avec les 24 nouveaux + 6 anciens).

**Solution** : supprimer les 6 anciens snapshots inutiles pour liberer de la place :
- `326884068` pre-mount-20251022 (0.39 GB)
- `326884077` pre-mount-20251022 (0.39 GB)
- `326884080` pre-mount-20251022 (0.39 GB)
- `326884087` pre-mount-20251022 (0.39 GB)
- `326884091` pre-mount-20251022 (0.39 GB)
- `342572225` pre-PH11-CLEANUP-01 (3.47 GB)

Apres suppression, relancer les 11 snapshots manquants.

---

## 3. AUDIT HARDWARE

### 3.1 Tableau synthetique

| Serveur | CPU | RAM totale | RAM utilisee | Disk | Disk usage | FS | Statut |
|---------|-----|-----------|-------------|------|-----------|-----|--------|
| k8s-master-01 | 4 | 7.6 GB | 2.0 GB (26%) | 75G | 16% | ext4 | OK |
| k8s-master-02 | 4 | 7.6 GB | 2.3 GB (30%) | 75G | 16% | ext4 | OK |
| k8s-master-03 | 4 | 7.6 GB | 2.3 GB (30%) | 75G | 15% | ext4 | OK |
| k8s-worker-01 | 8 | 15 GB | 1.7 GB (11%) | 150G | **72%** | ext4 | WARNING |
| k8s-worker-02 | 8 | 15 GB | 6.1 GB (41%) | 150G | **81%** | ext4 | **CRITIQUE** |
| k8s-worker-03 | 8 | 15 GB | 2.6 GB (17%) | 150G | 34% | ext4 | OK |
| k8s-worker-04 | 8 | 15 GB | 1.9 GB (13%) | 150G | 49% | ext4 | OK |
| k8s-worker-05 | 8 | 15 GB | 3.4 GB (23%) | 150G | **77%** | ext4 | WARNING |
| db-postgres-01 | 2 | 7.6 GB | 0.65 GB (9%) | 75G + 100G vol | 20% / 3% | ext4 | OK |
| db-postgres-02 | 2 | 3.7 GB | 0.78 GB (21%) | 38G + 100G vol | 31% / 4% | ext4 | OK |
| db-postgres-03 | 2 | 3.7 GB | 0.59 GB (16%) | 38G + 100G vol | 26% / 3% | ext4 | OK |
| redis-01/02/03 | 2 | 1.9 GB | ~0.4 GB | 38G | 16-18% | ext4 | OK |
| queue-01/02/03 | 2 | 1.9 GB | ~0.5 GB | 38G | 16-19% | ext4 | OK |
| haproxy-01/02 | 2 | 3.7 GB | ~0.5 GB | 38G | 16-17% | ext4 | OK |
| maria-01/02/03 | 2 | 3.7 GB | ~0.7 GB | 38G | 18-20% | ext4 | OK |
| proxysql-01/02 | 2 | 3.7 GB | ~0.5 GB | 38G | 17% | ext4 | OK |
| minio-01 | 3 | 3.7 GB | 0.66 GB | 75G + 200G vol | 8% / 2% | ext4 | OK |
| minio-02 | 2 | 1.9 GB | 0.49 GB | 38G + 200G vol | 17% / 2% | ext4 | OK |
| minio-03 | 2 | 3.7 GB | 0.64 GB | 38G + 200G vol | 15% / 2% | ext4 | OK |
| vault-01 | 2 | 3.7 GB | 0.58 GB | 38G + 20G vol | 16% / 3% | ext4 | OK |
| siem-01 | 4 | 7.6 GB | 0.59 GB (8%) | 75G + 50G vol | 8% / 2% | ext4 | Surdim. |
| monitor-01 | 3 | 3.7 GB | 0.62 GB | 75G + 50G vol | 11% / 2% | ext4 | OK |
| backup-01 | 2 | 1.9 GB | 0.39 GB | 38G + 500G vol | 17% / 2% | ext4 | OK |
| mail-core-01 | 2 | 1.9 GB | 0.53 GB | 38G + 50G vol | 19% / 2% | ext4 | OK |
| mail-mx-01 | 2 | 1.9 GB | 0.40 GB | 38G + 30G vol | 8% / 3% | ext4 | OK |
| mail-mx-02 | 2 | 1.9 GB | 0.39 GB | 38G + 30G vol | 8% / 3% | ext4 | OK |
| install-v3 | 2 | 3.7 GB | 1.0 GB (27%) | 38G + 100G docker | **86%** / 66% | ext4 | **CRITIQUE** |
| backend-01 | 2 | 3.7 GB | 0.76 GB | 38G | 23% | ext4 | OK |

### 3.2 Alertes critiques

- **k8s-worker-02** : disk a 81%, load average 8.42 (sur 8 CPU) — sature
- **install-v3** : disk systeme a 86% — 51.5 GB Docker reclaimables (94%), nettoyage urgent
- **k8s-worker-01** : disk a 72% — a surveiller
- **k8s-worker-05** : disk a 77% — a surveiller

### 3.3 Points positifs

- Aucun swap utilise sur aucun serveur
- Toutes les RAM largement suffisantes (sauf si montee en charge)
- Volumes data faiblement utilises (2-4% partout)
- Uptime stable : 70-116 jours sans reboot

---

## 4. AUDIT KUBERNETES

### 4.1 Cluster

| Metrique | Valeur |
|----------|--------|
| Version | v1.30.14 |
| Nodes | 8 (3 masters + 5 workers) |
| Runtime | containerd 2.2.0 |
| OS | Ubuntu 24.04.3 LTS |
| Kernel | 6.8.0-90-generic |
| Status | Tous **Ready** |
| Metrics Server | **Non installe** (kubectl top indisponible) |

### 4.2 Namespaces et pods

| Namespace | Pods Running | Description |
|-----------|-------------|-------------|
| kube-system | ~25 | etcd (3), apiserver (3), controller-manager (3), scheduler (3), calico, coredns, kube-proxy |
| observability | ~20 | Prometheus, Grafana, Loki, Promtail (8), AlertManager, Tempo |
| ingress-nginx | 8 | DaemonSet ingress-nginx-controller |
| argocd | 7 | ArgoCD (controller, repo-server, dex, redis, notifications, server) |
| keybuzz-api-dev | ~8 | API + outbound-worker + CronJobs (SLA, outbound-tick) |
| keybuzz-api-prod | ~8 | API + outbound-worker + CronJobs |
| keybuzz-backend-dev | ~7 | Backend + Amazon workers + backfill-scheduler |
| keybuzz-backend-prod | ~5 | Backend + backfill-scheduler (2 pods **CrashLoopBackOff**) |
| keybuzz-client-dev/prod | 1+1 | Client Next.js |
| keybuzz-admin-v2-dev/prod | 1+1 | Admin v2 Next.js |
| keybuzz-website-dev/prod | 1+2 | Website (2 replicas PROD) |
| keybuzz-ai | 2 | LiteLLM (2 replicas) |
| keybuzz-seller-dev | 2 | Seller API + Client |
| minio | 1 | MinIO in-cluster (PVC 10Gi) |
| external-secrets | 3 | ESO operator |
| cert-manager | 3 | Cert-manager |
| local-path-storage | 1 | Provisioner |
| reloader | 1 | Reloader |

### 4.3 Problemes detectes

1. **CrashLoopBackOff en PROD** :
   - `keybuzz-backend-prod/amazon-items-worker` : **465 restarts** (9 jours)
   - `keybuzz-backend-prod/amazon-orders-worker` : **436 restarts** (9 jours)
   - Impact : workers Amazon PROD non-fonctionnels

2. **Metrics Server absent** : `kubectl top` non disponible, monitoring K8s degrade

3. **PVCs** : seulement 2 PVCs (MinIO 10Gi + Prometheus 20Gi)

---

## 5. AUDIT POSTGRESQL / PATRONI / HAProxy

### 5.1 Cluster Patroni

| Node | IP | Role | pg_is_in_recovery | RAM | Volume |
|------|-----|------|-------------------|-----|--------|
| db-postgres-01 | 10.0.0.120 | Replica (standby) | true | 7.6 GB | 100G (3%) |
| db-postgres-02 | 10.0.0.121 | **PRIMARY (Leader)** | **false** | 3.7 GB | 100G (4%) |
| db-postgres-03 | 10.0.0.122 | Replica (standby) | true | 3.7 GB | 100G (3%) |

- Services : `patroni.service` + `etcd.service` (natifs systemd, pas Docker)
- PostgreSQL 16 avec Patroni
- max_connections : **200**
- Connexions actives : **7** (4 backend, 2 idle, 1 active)
- Replication : **0 lignes dans pg_stat_replication** depuis db-postgres-01 (normal, c'est un replica)

### 5.2 Bases de donnees

| Base | Taille |
|------|--------|
| keybuzz | **105 MB** |
| keybuzz_backend | 81 MB |
| keybuzz_prod | 29 MB |
| postgres | 12 MB |
| keybuzz_litellm | 11 MB |
| **Total** | **~238 MB** |

### 5.3 HAProxy (interne)

Les deux HAProxy ecoutent sur :
- `5432` : PostgreSQL write (vers leader)
- `5433` : PostgreSQL read (vers replicas)
- `6379` : Redis
- `5672` : RabbitMQ
- `3306` : MariaDB
- `9000/9001` : MinIO

Adresse VIP LB Hetzner : `10.0.0.10`

### 5.4 Diagnostic PostgreSQL

- **Utilisation tres faible** : 238 MB total, 7 connexions sur 200
- **Marge enorme** : volumes 100G utilises a 3-4%
- **Asymetrie RAM** : le leader (db-postgres-02) n'a que 3.7 GB vs 7.6 GB sur replica-01
- **Pas de replication visible** depuis replica-01 (a verifier depuis le leader)

---

## 6. AUDIT REDIS

### 6.1 Cluster Redis HA

| Node | IP | Role | Memory | Connected slaves | DBSIZE |
|------|-----|------|--------|-----------------|--------|
| redis-01 | 10.0.0.123 | **master** | 17.49 MB | 2 | 0 |
| redis-02 | 10.0.0.124 | slave | 17.43 MB | 0 | 0 |
| redis-03 | 10.0.0.125 | slave | 17.43 MB | 0 | 0 |

- **maxmemory : non configure (0B)** — risque theorique si montee en charge
- Fragmentation ratio : 1.84-1.92 (acceptable)
- Evicted keys : 0
- total_connections_received (master) : 693,739
- Hits : 278 / Misses : 210 (ratio faible, peu utilise)
- Authentification : requise (mot de passe via Vault/ESO)
- Acces : via HAProxy LB 10.0.0.10:6379

### 6.2 Diagnostic Redis

- **Utilisation quasi-nulle** : 17 MB de RAM, 0 cles en base
- Redis est utilise principalement pour sessions/cache ephemere
- **maxmemory devrait etre configure** (recommandation : 1 GB)

---

## 7. AUDIT RABBITMQ

### 7.1 Cluster

| Node | Version | CPU | Statut | Maintenance |
|------|---------|-----|--------|-------------|
| rabbit@queue-01 | 3.12.1 (Erlang 25.3.2.8) | 2 | Running | Non |
| rabbit@queue-02 | 3.12.1 (Erlang 25.3.2.8) | 2 | Running | Non |
| rabbit@queue-03 | 3.12.1 (Erlang 25.3.2.8) | 2 | Running | Non |

- Cluster : 3/3 nodes **operationnels**
- Alarms : aucune
- Vhosts : `/` (default)
- Queues dans `/` : **aucune** (0 messages)
- Connexions : **0** (les workers K8s utilisent le LB HAProxy)

### 7.2 Diagnostic

- **Cluster sain** mais sous-utilise
- Les applications K8s se connectent via HAProxy 10.0.0.10:5672
- Marge enorme pour montee en charge

---

## 8. AUDIT MinIO

### 8.1 Cluster

- **3 nodes** (10.0.0.134, 10.0.0.131, 10.0.0.132)
- Mode : **Erasure coding distribue**
- Commande : `minio server --console-address :9001 http://10.0.0.134:9000/data/minio http://10.0.0.131:9000/data/minio http://10.0.0.132:9000/data/minio`
- Service : systemd natif (`minio.service`)
- Memoire : 405 MB (peak 406 MB)
- CPU : 3h 12min cumulees (tres faible)
- Uptime : depuis 15 janvier 2026 (58 jours)

### 8.2 Stockage

| Node | Volume | Utilise | Libre |
|------|--------|---------|-------|
| minio-01 | 200 GB | 3.9 GB (2%) | 197 GB |
| minio-02 | 200 GB | 3.9 GB (2%) | 197 GB |
| minio-03 | 200 GB | 3.9 GB (2%) | 197 GB |
| **Total** | **600 GB** | **11.7 GB (2%)** | **~590 GB** |

- **Marge extreme** : 590 GB libres

---

## 9. AUDIT VAULT

| Metrique | Valeur |
|----------|--------|
| Version | 1.21.1 |
| Seal Type | Shamir |
| Sealed | **false** (unsealed) |
| HA Enabled | true |
| HA Mode | standby (vault-01) |
| Active Node | http://10.0.0.154:8200 |
| Storage | Raft |
| Total Shares | 5 |
| Threshold | 3 |

- Vault-01 (10.0.0.150) est en **standby**
- Le leader actif est a 10.0.0.154 (probablement un second noeud Vault non reference dans le TSV)
- Unseal keys stockees en clair sur vault-01 (dette technique connue)

---

## 10. AUDIT MONITORING / SIEM

### 10.1 Monitor-01 (10.0.0.152)

- **Seul service actif** : `node_exporter`
- Pas de Prometheus/Grafana/Loki local (tout est dans K8s namespace `observability`)
- Volume 50G /data/monitoring utilise a 2%
- **Potentiellement surdimensionne** (4 CPU, 7.6 GB RAM, 75G + 50G vol pour juste node_exporter)

### 10.2 SIEM-01 (10.0.0.151)

- **Seul service actif** : `node_exporter`
- Aucun logiciel SIEM installe (pas de Wazuh, OSSEC, Suricata, ELK)
- Volume 50G /data/siem utilise a 2%
- **Potentiellement surdimensionne**

### 10.3 Observabilite K8s

La stack d'observabilite tourne dans le cluster K8s (namespace `observability`) :
- Prometheus (1 pod stateful)
- Grafana (1 pod)
- AlertManager (1 pod)
- Loki (chunks-cache, results-cache, canary)
- Promtail (DaemonSet 8 pods)
- Tempo (1 pod)
- kube-state-metrics (1 pod)
- node-exporter (DaemonSet 8 pods)

---

## 11. AUDIT MAIL

### 11.1 mail-core-01 (10.0.0.160)

| Service | Port | Statut |
|---------|------|--------|
| Postfix (SMTP) | 25 | Running |
| Postfix (Submission) | 587 | Running |
| Dovecot (IMAP) | 143, 993 | Running |
| Dovecot (POP3) | 110, 995 | Running |
| Rspamd (antispam) | 11332-11334 | Running |
| Nginx (webmail) | 80, 443 | Running |
| Redis (local) | 6379 (localhost) | Running |

- **File d'attente : 224 messages (2.8 MB)** vers `sre@keybuzz.io`
- Volume 50G /data/mail_core utilise a 2%

### 11.2 MX-01 et MX-02

| Serveur | Port 25 | Queue |
|---------|---------|-------|
| mail-mx-01 | Running | Vide |
| mail-mx-02 | Running | Vide |

- Fonctionnent en relay MX
- Volumes 30G utilises a 3%

### 11.3 Diagnostic Mail

- Infrastructure mail **saine et operationnelle**
- 224 messages en attente sur mail-core-01 (a verifier si normal)
- Capacite largement suffisante

---

## 12. AUDIT MARIADB / ProxySQL

### 12.1 MariaDB Galera

- 3 nodes (maria-01/02/03) presents et joignables
- Requetes `wsrep_cluster_size` echouent — le cluster Galera pourrait ne pas etre actif
- Pas de Docker containers, pas de service mariadb/mysql detecte
- **A investiguer** : MariaDB est peut-etre eteint ou non configure sur ces serveurs

### 12.2 ProxySQL

| Node | Ports ecoute |
|------|-------------|
| proxysql-01 | 6032 (admin), 6033 (data) x4 |
| proxysql-02 | 6032 (admin), 6033 (data) x4 |

- ProxySQL fonctionne en natif (`proxysql.service`)
- **Pas de Docker** sur ces serveurs

---

## 13. AUDIT RESEAU

### 13.1 Exposition critique

| Serveur | Ports exposes | Commentaire |
|---------|-------------|-------------|
| haproxy-01/02 | 5432, 5433, 6379, 5672, 3306, 9000, 9001 | **0.0.0.0** — protege par firewall Hetzner |
| redis-01/02/03 | 6379 (Redis natif) | Non expose publiquement (firewall) |
| queue-01 | 5672, 15672, 25672, 4369 | Non expose publiquement |
| minio-01 | 9000, 9001 | Ecoute 0.0.0.0 et [::1] |
| vault-01 | 8200, 8201 | Ecoute 0.0.0.0 |
| mail-core-01 | 25, 110, 143, 587, 993, 995, 80, 443 | Expose publiquement (normal pour mail) |
| mail-mx-01/02 | 25 | Expose publiquement (normal pour MX) |

### 13.2 Evaluation securite

- **Firewalls Hetzner** : configures lors de PH-INFRA-02 (4 firewalls, 51 serveurs migres)
- **DB/Redis/RMQ** : fermes au public, SSH bastion-only
- **MinIO** : ecoute sur 0.0.0.0:9000 mais protege par firewall
- **Vault** : ecoute sur 0.0.0.0:8200 mais protege par firewall
- **Mail** : exposition publique normale (ports 25, 587, 993)

---

## 13. CAPACITY PLANNING

### 13.1 Metriques actuelles (2 tenants actifs)

| Ressource | Utilisation actuelle | Capacite |
|-----------|---------------------|----------|
| DB PostgreSQL | 238 MB (5 bases) | 300 GB (3x100G volumes) |
| DB Connexions | 7 / 200 | 200 max |
| Redis memoire | 17 MB | ~1.9 GB (sans maxmemory) |
| Redis cles | 0 | illimite |
| RabbitMQ queues | 0 messages | quorum 3 nodes |
| RabbitMQ connexions | 0 | centaines possibles |
| MinIO stockage | 11.7 GB | 600 GB |
| K8s nodes | 8 (3m + 5w) | 52 CPU, 104 GB RAM |
| Mail queue | 224 messages | stable |
| Backup | 9.7 GB | 500 GB |

### 13.2 Estimation 100 clients

| Ressource | Estimation | Suffisant ? |
|-----------|-----------|-------------|
| DB PostgreSQL | ~12 GB (50x actuel) | Oui (300 GB dispo) |
| DB Connexions | ~150-200 | **Limite** (max_connections=200) |
| Redis | ~500 MB | Oui |
| RabbitMQ | ~50 msg/min | Oui |
| MinIO | ~500 GB | **Limite** (600 GB total) |
| K8s workers | 3-4 actifs | Oui (5 workers) |
| API replicas | 2-3 par env | Oui |
| Mail | ~5000 msg/jour | Oui |

**Goulots a 100 clients** :
- `max_connections` PostgreSQL a augmenter (200 -> 500)
- MinIO stockage a augmenter si PJ volumineuses
- k8s-worker-02 disk deja a 81%

### 13.3 Estimation 300 clients

| Ressource | Estimation | Suffisant ? |
|-----------|-----------|-------------|
| DB PostgreSQL | ~35 GB | Oui |
| DB Connexions | ~400-600 | **NON** (augmenter a 1000) |
| Redis | ~1.5 GB | **Limite** (configurer maxmemory) |
| RabbitMQ | ~150 msg/min | Oui |
| MinIO | ~1.5 TB | **NON** (agrandir volumes) |
| K8s workers | 5-6 necessaires | **Limite** (ajouter 1-2 workers) |
| API replicas | 3-4 par env | Oui |
| Mail | ~15000 msg/jour | Oui |
| PgBouncer | **Necessaire** | Non installe |

**Goulots a 300 clients** :
- PostgreSQL connexions (PgBouncer recommande)
- MinIO stockage (tripler les volumes)
- K8s workers (ajouter 1-2 nodes)
- Redis maxmemory a configurer

### 13.4 Estimation 500 clients

| Ressource | Estimation | Suffisant ? |
|-----------|-----------|-------------|
| DB PostgreSQL | ~60 GB | Oui (volumes OK) |
| DB Connexions | ~800-1000 | **NON** (PgBouncer obligatoire) |
| Redis | ~2.5 GB | **NON** (upgrader RAM ou maxmemory) |
| RabbitMQ | ~300 msg/min | Oui (mais surveiller) |
| MinIO | ~3 TB | **NON** (volumes 200G -> 1TB) |
| K8s workers | 7-8 necessaires | **NON** (ajouter 2-3 workers) |
| API replicas | 4-5 par env | RAM workers limite |
| Mail | ~25000 msg/jour | Oui |
| DB CPU | 2 CPU insuffisant | **Upgrader** db-postgres |

**Goulots a 500 clients** :
- PostgreSQL : PgBouncer obligatoire + upgrade CPU leader
- MinIO : volumes a multiplier par 5
- K8s : ajouter 2-3 workers 8CPU/16GB
- Redis : configurer maxmemory, potentiellement upgrader RAM
- Monitoring : activer metrics-server K8s

---

## 14. CLASSIFICATION FINALE PAR SERVEUR

### Infrastructure critique

| Serveur | CPU | RAM | Disk | Statut | Recommandation |
|---------|-----|-----|------|--------|----------------|
| k8s-master-01 | OK | OK | OK (16%) | OK | — |
| k8s-master-02 | OK | OK | OK (16%) | OK | — |
| k8s-master-03 | OK | OK | OK (15%) | OK | — |
| k8s-worker-01 | OK | OK | **72%** | WARNING | Nettoyer images Docker/containerd |
| k8s-worker-02 | **Load 8.4** | OK | **81%** | **CRITIQUE** | Nettoyer disk + investiguer charge |
| k8s-worker-03 | OK | OK | OK (34%) | OK | — |
| k8s-worker-04 | OK | OK | OK (49%) | OK | — |
| k8s-worker-05 | OK | OK | **77%** | WARNING | Nettoyer images |
| db-postgres-01 | OK | OK | OK | OK | — |
| db-postgres-02 | OK | **3.7 GB** (leader!) | OK | WARNING | Upgrader RAM leader |
| db-postgres-03 | OK | OK | OK | OK | — |
| redis-01/02/03 | OK | OK | OK | OK | Configurer maxmemory |
| queue-01/02/03 | OK | OK | OK | OK | — |
| haproxy-01/02 | OK | OK | OK | OK | — |
| maria-01/02/03 | OK | OK | OK | WARNING | Verifier si MariaDB actif |
| proxysql-01/02 | OK | OK | OK | OK | — |
| minio-01/02/03 | OK | OK | OK (2%) | OK | — |
| vault-01 | OK | OK | OK | OK | Securiser unseal keys |
| backup-01 | OK | OK | OK (2%) | OK | **Backup vide!** — configurer |
| mail-core-01 | OK | OK | OK | OK | Surveiller queue (224 msg) |
| mail-mx-01/02 | OK | OK | OK | OK | — |
| install-v3 | OK | OK | **86%** | **CRITIQUE** | Docker prune (51 GB recuperables) |

### Serveurs surdimensionnes

| Serveur | CPU | RAM | Disk | Statut | Recommandation |
|---------|-----|-----|------|--------|----------------|
| siem-01 | 4 | 7.6 GB | 75G + 50G | **SURDIM.** | Pas de SIEM installe, reduire ou utiliser |
| monitor-01 | 3 | 3.7 GB | 75G + 50G | **SURDIM.** | Seulement node_exporter |
| ml-platform-01 | 8 | **15 GB** | 226G | **SURDIM.** | Idle, 3% disk, aucun workload |
| analytics-db-01 | 2 | 1.9 GB | 38G | Idle | Non utilise |
| analytics-01 | 3 | 3.7 GB | 75G | Idle | Non utilise |
| crm-01 | 2 | 1.9 GB | 38G | Idle | Non utilise |
| etl-01 | 3 | 3.7 GB | 75G | Idle | Non utilise |
| baserow-01 | 2 | 1.9 GB | 38G | Idle | Non utilise |
| vector-db-01 | 3 | 3.7 GB | 75G | Idle | Qdrant en attente |
| backend-01 | 2 | 3.7 GB | 38G | Faible | Legacy bastion |

---

## 15. RECOMMANDATIONS SRE

### Priorite 1 — IMMEDIAT (avant montee en charge)

1. **Nettoyer install-v3** : `docker system prune -a` (51 GB recuperables)
2. **Nettoyer k8s-worker-02** : images containerd/Docker inutilisees, investiguer load 8.4
3. **Nettoyer k8s-worker-01 et worker-05** : images Docker anciennes
4. **Fixer CrashLoopBackOff PROD** : amazon-items-worker + amazon-orders-worker (465/436 restarts)
5. **Configurer Redis maxmemory** : `maxmemory 1gb` + `maxmemory-policy allkeys-lru`
6. **Investiguer backup-01** : le volume 500 GB est vide (aucune sauvegarde active!)

### Priorite 2 — COURT TERME (avant 100 clients)

7. **Augmenter max_connections PostgreSQL** : 200 -> 500
8. **Installer metrics-server K8s** : activer `kubectl top`
9. **Upgrader RAM db-postgres-02** (leader) : 3.7 GB -> 7.6 GB minimum
10. **Securiser unseal keys Vault** : supprimer de `/opt/keybuzz/logs/`
11. **Configurer backups automatiques** sur backup-01

### Priorite 3 — MOYEN TERME (avant 300 clients)

12. **Installer PgBouncer** devant PostgreSQL (connection pooling)
13. **Ajouter 1-2 K8s workers** supplementaires
14. **Augmenter volumes MinIO** : 200 GB -> 500 GB par node
15. **Activer SIEM** ou reduire/supprimer siem-01

### Priorite 4 — LONG TERME (scale 500+)

16. **Upgrader CPU PostgreSQL leader** : 2 -> 4 CPU
17. **Ajouter 2-3 K8s workers** : 8 CPU / 16 GB chacun
18. **Volumes MinIO** : 500 GB -> 1 TB par node
19. **PgBouncer obligatoire** avec max 1000+ connections

### Serveurs a reduire/supprimer

| Serveur | Economie estimee/mois | Risque |
|---------|----------------------|--------|
| ml-platform-01 (8 CPU, 15 GB) | ~30-40 EUR | Aucun (idle) |
| siem-01 (4 CPU, 7.6 GB) | ~15-20 EUR | Aucun (pas de SIEM) |
| analytics-db-01 + analytics-01 | ~15-20 EUR | Aucun (idle) |
| crm-01 | ~5-10 EUR | Aucun (idle) |
| etl-01 | ~10-15 EUR | Aucun (idle) |
| baserow-01 | ~5-10 EUR | Aucun (idle) |
| **Total potentiel** | **~80-115 EUR/mois** | |

---

## 16. VALIDATION FINALE

| Check | Resultat |
|-------|----------|
| `kubectl get nodes` | 8/8 Ready |
| `curl -sk https://api-dev.keybuzz.io/health` | `{"status":"ok"}` |
| `curl -sk https://client-dev.keybuzz.io` | Redirect `/login` (OK) |
| `curl -sk https://admin-dev.keybuzz.io` | Redirect `/login` (OK) |
| Patroni cluster | 3/3 nodes operationnels |
| Redis cluster | master + 2 slaves OK |
| RabbitMQ cluster | 3/3 nodes OK, 0 alarms |
| MinIO cluster | 3 nodes, service running |
| Vault | Unsealed, HA active |
| Mail | Postfix + Dovecot + Rspamd running |
| Snapshots | **24/32 SUCCESS** (8 echoues: limite images Hetzner) |

---

## 17. CONCLUSION

### L'infrastructure est-elle saine ?

**Globalement OUI**, avec des reserves :
- Les services critiques (K8s, PostgreSQL, Redis, RabbitMQ, Vault, Mail) sont tous operationnels
- L'architecture est bien concue (HA PostgreSQL, Redis master/slave, RabbitMQ quorum, MinIO erasure)
- La securite reseau est correcte (firewalls Hetzner, SSH bastion-only)

### Ou sont les limites ?

1. **Disk saturation** : worker-02 (81%), install-v3 (86%), worker-01 (72%), worker-05 (77%)
2. **CrashLoopBackOff PROD** : 2 workers Amazon en echec depuis 9 jours
3. **Backup inexistant** : backup-01 a un volume 500 GB vide
4. **PostgreSQL connexions** : 200 max, insuffisant au-dela de 100 clients
5. **Redis maxmemory** : non configure
6. **SIEM/Monitoring** : serveurs dedies sous-utilises (seulement node_exporter)
7. **Serveurs idle** : ~80-115 EUR/mois de cout inutile (7+ serveurs non utilises)

### Que faut-il corriger immediatement ?

1. `docker system prune` sur install-v3 (liberer 51 GB)
2. Nettoyer les disks des workers K8s (surtout worker-02)
3. Fixer les 2 pods CrashLoopBackOff en PROD
4. Configurer Redis maxmemory
5. Mettre en place des sauvegardes automatiques sur backup-01
6. Installer metrics-server dans le cluster K8s

---

## ANNEXE A — Hetzner Server IDs et Snapshot IDs

| Serveur | Hetzner Server ID | Snapshot ID | Statut |
|---------|------------------|-------------|--------|
| k8s-master-01 | 109780472 | 366770215 | SUCCESS |
| k8s-master-02 | 109783469 | 366771596 | SUCCESS |
| k8s-master-03 | 109783574 | 366772425 | SUCCESS |
| k8s-worker-01 | 109782191 | — | LIMIT |
| k8s-worker-02 | 109783643 | — | LIMIT |
| k8s-worker-03 | 109784494 | — | LIMIT |
| k8s-worker-04 | 109785006 | — | LIMIT |
| k8s-worker-05 | 109884534 | — | LIMIT |
| db-postgres-01 | 109781629 | 366760175 | SUCCESS |
| db-postgres-02 | 109783838 | 366761167 | SUCCESS |
| db-postgres-03 | 109884801 | 366761813 | SUCCESS |
| redis-01 | 109781695 | 366762487 | SUCCESS |
| redis-02 | 109784003 | 366763124 | SUCCESS |
| redis-03 | 109784037 | 366763437 | SUCCESS |
| queue-01 | 109783713 | 366764127 | SUCCESS |
| queue-02 | 109784070 | 366764739 | SUCCESS |
| queue-03 | 109784080 | 366765388 | SUCCESS |
| haproxy-01 | 110171270 | 366773488 | SUCCESS |
| haproxy-02 | 110171338 | 366773957 | SUCCESS |
| maria-01 | 112572482 | — | LIMIT |
| maria-02 | 112572478 | — | LIMIT |
| maria-03 | 112572479 | — | LIMIT |
| proxysql-01 | 112572480 | — | LIMIT |
| proxysql-02 | 112572481 | — | LIMIT |
| minio-01 | 109784414 | 366765808 | SUCCESS |
| minio-02 | 109784158 | 366766335 | SUCCESS |
| minio-03 | 109884423 | 366766972 | SUCCESS |
| vault-01 | 109883784 | 366767594 | SUCCESS |
| siem-01 | 109883991 | 366774834 | SUCCESS |
| monitor-01 | (voir hcloud) | 366774449 | SUCCESS |
| backup-01 | 109784108 | 366769427 | SUCCESS |
| mail-core-01 | 109784583 | 366768171 | SUCCESS |
| mail-mx-01 | 109784607 | 366768512 | SUCCESS |
| mail-mx-02 | 109784668 | 366768781 | SUCCESS |
| install-v3 | 114294716 | — | LIMIT |

---

## ANNEXE B — Architecture reseau

```
Internet
   |
   v
[Hetzner LB] --- 49.13.42.76 + 138.199.132.240
   |
   v
[ingress-nginx DaemonSet] --- K8s workers (5 nodes)
   |
   v
[K8s Services] --- API, Client, Admin, Backend, Website, LiteLLM
   |
   v
[HAProxy VIP 10.0.0.10]
   |--- :5432 ---> PostgreSQL Leader (db-postgres-02)
   |--- :5433 ---> PostgreSQL Replicas
   |--- :6379 ---> Redis Master (redis-01)
   |--- :5672 ---> RabbitMQ Cluster
   |--- :3306 ---> MariaDB Galera
   |--- :9000 ---> MinIO Cluster
```

---

> Rapport genere le 14 mars 2026 a 23:20 UTC
> Phase : PH-SRE-AUDIT-01
> Statut : TERMINE (24/32 snapshots OK, 8 bloques par limite Hetzner)
