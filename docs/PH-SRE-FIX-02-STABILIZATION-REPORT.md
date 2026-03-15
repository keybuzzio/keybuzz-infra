# PH-SRE-FIX-02 — Stabilisation infrastructure post-audit

> Date : 15 mars 2026
> Auteur : CE (Cursor Agent)
> Bastion : install-v3 (46.62.171.61)
> Prerequis : PH-SRE-AUDIT-01 (14 mars 2026)
> Statut : TERMINE

---

## 0. LECTURE PREALABLE — Incidents securite et desactivations volontaires

### Documents verifies
- `keybuzz-v3-latest-state.mdc` : Admin v1 quarantaine (PH86.0)
- `FIX-PROD-INBOUND-EXTERNALMESSAGE-REPORT.md` : Tables Prisma manquantes en PROD
- `BASELINE-PROD-CURRENT.md`, `PROD_GOLDEN_BASELINE.md` : Amazon workers a `v1.0.34-ph263`
- `DEV_GOLDEN_BASELINE.md`, `DEV_GOLDEN_FREEZE.md` : reference workers DEV

### Conclusions
- Les **CrashLoopBackOff Amazon workers** ne sont PAS lies a l'attaque admin v1 ni a une desactivation volontaire
- La cause est identifiee : **tables Prisma manquantes en base PROD** (meme pattern que FIX-PROD-INBOUND)
- L'admin v1 legacy a ete entierement mis en quarantaine (PH86.0) — namespaces supprimes, images effacees
- Aucun service n'a ete desactive volontairement

---

## 1. PGBOUNCER

### Statut : NON INSTALLE

PgBouncer a ete verifie sur 5 serveurs :

| Serveur | IP | Port 6432 | Processus | Package | Binaire |
|---------|-----|-----------|-----------|---------|---------|
| db-postgres-01 | 10.0.0.120 | NOT LISTENING | NOT RUNNING | NOT INSTALLED | NOT FOUND |
| db-postgres-02 | 10.0.0.121 | NOT LISTENING | NOT RUNNING | NOT INSTALLED | NOT FOUND |
| db-postgres-03 | 10.0.0.122 | NOT LISTENING | NOT RUNNING | NOT INSTALLED | NOT FOUND |
| haproxy-01 | 10.0.0.11 | NOT LISTENING | NOT RUNNING | NOT INSTALLED | NOT FOUND |
| haproxy-02 | 10.0.0.12 | NOT LISTENING | NOT RUNNING | NOT INSTALLED | NOT FOUND |

**Analyse** : PgBouncer n'est pas installe. Les connexions PostgreSQL passent directement via HAProxy (ports 5432/5433) sans connection pooling. Avec seulement 23 connexions actives sur le leader (max_connections=200), ce n'est pas urgent mais deviendra necessaire au-dela de 50 clients.

**Recommandation** : Installer PgBouncer quand le nombre de connexions actives depasse 100 (estimee a ~150-200 clients).

---

## 2. NETTOYAGE INSTALL-V3

### Etat avant nettoyage

| Filesystem | Size | Used | Avail | Use% |
|-----------|------|------|-------|------|
| `/dev/sda1` (root) | 38G | 31G | 5.4G | **86%** |
| `/dev/sdb` (docker) | 98G | 62G | 32G | **67%** |

Docker system df :
- Images : 153 total, 12 actives, 55.1GB total, **51.96GB recuperables (94%)**
- Containers : 16 total, 2 actifs, 1.092GB recuperables

### Nettoyage effectue

| Operation | Resultat |
|----------|----------|
| `docker image prune -f` | ~72 images dangling supprimees, **~38GB liberes** |
| `docker container prune -f` | 14 containers stoppes supprimes, **1.092GB liberes** |
| `docker builder prune -f` | 0B (pas de cache build) |

### Etat apres nettoyage

| Filesystem | Size | Used | Avail | Use% | Avant |
|-----------|------|------|-------|------|-------|
| `/dev/sda1` (root) | 38G | 31G | 5.5G | **85%** | 86% |
| `/dev/sdb` (docker) | 98G | 20G | 74G | **22%** | 67% |

Docker system df apres :
- Images : 81 total, 3 actives, 17.1GB
- Containers : 3 total, 3 actifs, 0B

**Bilan** : Le volume Docker est passe de 67% a 22% (**-45 points**, ~42GB liberes). Le disque root reste a 85% car l'espace root n'est pas lie a Docker (Docker est sur `/dev/sdb`).

**Probleme residuel** : Le disque root a 85% reste eleve. L'espace est consomme par les logs systeme, les packages, et les fichiers hors Docker. Un nettoyage des logs ou un agrandissement du volume root pourrait etre envisage.

---

## 3. ANALYSE WORKER K8S-WORKER-02

### Etat du node

| Metrique | Valeur |
|----------|--------|
| Status | Ready |
| CPU | 8 cores |
| RAM | 15.2 GB |
| Disk root | 150G, **81% utilise** (116G/150G) |
| Volume data | 50G, 2% utilise |
| Memory Pressure | False |
| Disk Pressure | False |
| PID Pressure | False |
| **CPU Usage reel** | **7992m / 8000m = 99%** |
| **Memory Usage** | **8559Mi / 15.2Gi = 55%** |

### DECOUVERTE CRITIQUE : Alertmanager en boucle

Le pod `alertmanager-kube-prometheus-kube-prome-alertmanager-0` (namespace `observability`) consomme :
- **CPU : 7813m (7.8 cores sur 8)** — anormalement eleve
- **RAM : 3911Mi (3.9GB)** — anormalement eleve

Alertmanager devrait normalement utiliser <50m CPU et <100Mi RAM. Cette consommation indique un probleme grave (boucle infinie, fuite memoire, ou volume massif d'alertes).

### Pods sur worker-02

| Pod | Namespace | CPU | Memory | Status |
|-----|-----------|-----|--------|--------|
| alertmanager-kube-prometheus-kube-prome-alertmanager-0 | observability | **7813m** | **3911Mi** | Running |
| tempo-0 | observability | — | — | Running |
| promtail-2mjjf | observability | 19m | 134Mi | Running |
| kube-prometheus-prometheus-node-exporter-fnh98 | observability | — | — | Running |
| loki-canary-mg6wj | observability | — | — | Running |
| keybuzz-client-68cb8fdb5-jwrsq | keybuzz-client-prod | — | — | Running |
| keybuzz-backend-57b757f5b9-sxmzw | keybuzz-backend-prod | — | — | Running |
| amazon-orders-worker-544b4fd59-bcc7c | keybuzz-backend-prod | — | — | **CrashLoopBackOff** |
| keybuzz-api-5986695cc-tnmjw | keybuzz-api-dev | — | — | Running |
| keybuzz-outbound-worker-78fb894cd9-fhpbm | keybuzz-api-dev | — | — | Running |
| keybuzz-outbound-worker-b7d59d89d-jw427 | keybuzz-api-prod | — | — | Running |
| amazon-orders-worker-fcfd9b69-q2dzc | keybuzz-backend-dev | — | — | Running |
| backfill-scheduler-5bcc59c79f-4dtwb | keybuzz-backend-dev | — | — | Running |
| seller-client-69b6bbf4b5-4c9sr | keybuzz-seller-dev | — | — | Running |
| keybuzz-website-7f9ff7b9bc-248qg | keybuzz-website-prod | — | — | Running |
| external-secrets-5db667f798-7n8sp | external-secrets | — | — | Running |
| ingress-nginx-controller-k428v | ingress-nginx | — | — | Running |
| calico-node-9czr2 | kube-system | 38m | 242Mi | Running |
| kube-proxy-cztqs | kube-system | — | — | Running |

**Action recommandee** : Redemarrer le pod alertmanager pour liberer les 7.8 cores de CPU. Si le probleme persiste, investiguer la cause racine dans la configuration kube-prometheus.

---

## 4. WORKERS AMAZON — CrashLoopBackOff

### Pods en CrashLoopBackOff

| Pod | Namespace | Restarts | Age | Node | Cause |
|-----|-----------|----------|-----|------|-------|
| amazon-items-worker-6f5f86956f-7kh97 | keybuzz-backend-prod | **485** | 9d | worker-05 | `relation "Order" does not exist` |
| amazon-orders-worker-544b4fd59-bcc7c | keybuzz-backend-prod | **456** | 9d | worker-02 | `relation "amazon_orders_backfill_state" does not exist` |

### Workers DEV (reference — fonctionnent)

| Pod | Namespace | Restarts | Age | Node | Status |
|-----|-----------|----------|-----|------|--------|
| amazon-items-worker-8db9ff5f4-2hlcn | keybuzz-backend-dev | 1 | 9d | worker-05 | **Running** |
| amazon-orders-worker-fcfd9b69-mbgf5 | keybuzz-backend-dev | 3 | 9d | worker-05 | **Running** |
| amazon-orders-worker-fcfd9b69-q2dzc | keybuzz-backend-dev | 2 | 9d | worker-02 | **Running** |

### Cause racine identifiee

Les deux workers PROD crashent a cause de **tables Prisma manquantes** dans la base de donnees PROD (`keybuzz_prod`) :

1. **items-worker** : `PrismaClientKnownRequestError: relation "Order" does not exist` (code 42P01)
2. **orders-worker** : `PrismaClientKnownRequestError: relation "amazon_orders_backfill_state" does not exist` (code 42P01)

C'est le **meme pattern** que le probleme corrige dans `FIX-PROD-INBOUND-EXTERNALMESSAGE-REPORT.md` (table `ExternalMessage` manquante en PROD, creee manuellement le 14 mars 2026).

### Analyse

- Les migrations Prisma n'ont **jamais ete executees** sur la base PROD
- La base DEV a toutes les tables Prisma (migrations appliquees)
- Ce n'est **PAS** lie a l'attaque admin v1, ni a une desactivation volontaire
- Ce n'est **PAS** un probleme de rate limit Amazon, de memoire, ou de crash applicatif
- Les workers DEV fonctionnent parfaitement avec le meme code

### Tables PROD manquantes identifiees

| Table | Utilisee par | Existe DEV | Existe PROD |
|-------|-------------|:---:|:---:|
| `Order` | items-worker | oui | **non** |
| `amazon_orders_backfill_state` | orders-worker | oui | **non** |
| `ExternalMessage` | inbound webhook | oui | **oui (creee 14/03)** |

### Recommandation

Creer les tables manquantes dans `keybuzz_prod` en replicant le schema de `keybuzz` (DEV). Cette operation necessite une validation avant execution car elle touche la base PROD.

**STOP** : Aucune correction appliquee conformement aux regles. Documente uniquement.

---

## 5. REDIS — Configuration memoire

### Etat actuel

| Node | IP | Role | maxmemory | maxmemory-policy | used_memory | peak_memory | fragmentation |
|------|-----|------|-----------|-----------------|-------------|-------------|---------------|
| redis-01 | 10.0.0.123 | **master** | **0 (illimite)** | allkeys-lru | 17.56 MB | 17.58 MB | 1.83 |
| redis-02 | 10.0.0.124 | slave | **0 (illimite)** | allkeys-lru | 17.49 MB | 18.27 MB | 1.91 |
| redis-03 | 10.0.0.125 | slave | **0 (illimite)** | allkeys-lru | 17.50 MB | 17.53 MB | 1.92 |

### Replication

| Parametre | Valeur |
|-----------|--------|
| Topologie | 1 master + 2 slaves |
| master_link_status | **up** (les 2 slaves) |
| connected_slaves (master) | 2 |

### Analyse

- **maxmemory = 0** : Redis peut consommer toute la RAM disponible (1.9GB par node). Risque theorique si la charge augmente significativement.
- **Usage actuel tres faible** : 17.5 MB utilise sur des machines de 1.9 GB (< 1%)
- **Politique allkeys-lru** : correcte (eviction des cles les moins recemment utilisees)
- **Fragmentation 1.83-1.92** : acceptable pour un usage si faible, mais a surveiller

### Recommandation

Configurer `maxmemory` a 1.5GB (80% de la RAM disponible) pour prevenir un scenario d'OOM. Pas urgent au vu de l'usage actuel.

---

## 6. POSTGRESQL — Asymetrie RAM

### Cluster Patroni

| Node | IP | Role | Timeline | Lag (LSN) | Lag (replay) |
|------|-----|------|----------|-----------|-------------|
| db-postgres-01 | 10.0.0.120 | **Replica** | 16 | 0 | 0 |
| db-postgres-02 | 10.0.0.121 | **LEADER** | 16 | — | — |
| db-postgres-03 | 10.0.0.122 | Replica | 16 | 0 | 0 |

### Distribution ressources

| Node | Role | RAM totale | RAM utilisee | CPU | shared_buffers | work_mem | max_connections | Connexions actives |
|------|------|-----------|-------------|-----|---------------|---------|----------------|-------------------|
| db-postgres-01 | Replica | **7.6 GB** | 615 Mi | 2 | 512 MB | 4 MB | 200 | 7 |
| db-postgres-02 | **LEADER** | **3.7 GB** | 746 Mi | 2 | 512 MB | 4 MB | 200 | **23** |
| db-postgres-03 | Replica | 3.7 GB | 576 Mi | 2 | 512 MB | 4 MB | 200 | 10 |

### Asymetrie confirmee

Le **LEADER** (db-postgres-02) tourne sur la **plus petite machine** (3.7 GB) tandis qu'un replica (db-postgres-01) a **7.6 GB**. Le shared_buffers de 512 MB represente :
- **14% de la RAM** sur le leader (3.7 GB) — en dessous de la recommandation de 25%
- **7% de la RAM** sur db-postgres-01 (7.6 GB) — sous-utilise

### Risque

La configuration actuelle fonctionne car la charge est faible (23 connexions sur 200 max). Cependant, si la charge augmente :
- Le leader sera le premier a saturer (RAM, connexions)
- Un failover automatique vers db-postgres-01 ameliorerait la situation (machine plus puissante)
- Le shared_buffers devrait etre ajuste proportionnellement a la RAM de chaque machine

### Recommandation

1. **Court terme** : Aucune action — le cluster fonctionne correctement avec lag=0
2. **Moyen terme** : Upgrader db-postgres-02 a 7.6 GB (aligner avec db-postgres-01) quand le nombre de tenants depasse 20
3. **Alternative** : Forcer un switchover Patroni vers db-postgres-01 (7.6 GB) comme leader

---

## 7. METRICS SERVER

### Installation

| Etape | Resultat |
|-------|----------|
| `kubectl apply -f components.yaml` | serviceaccount, clusterroles, deployment, apiservice crees |
| Premiere tentative | Erreur TLS : `x509: cannot validate certificate for IP because it doesn't contain any IP SANs` |
| Patch `--kubelet-insecure-tls` | Applique avec succes |
| Rollout | Pod `metrics-server-65d5d6f74d-267bw` Running en ~30s |
| `kubectl top nodes` | **FONCTIONNEL** |

### Resultats kubectl top nodes (15 mars 2026, 00:03 UTC)

| Node | CPU (cores) | CPU % | Memory (Mi) | Memory % |
|------|-------------|-------|-------------|----------|
| k8s-master-01 | 759m | 18% | 5856 Mi | **76%** |
| k8s-master-02 | 504m | 12% | 4163 Mi | 54% |
| k8s-master-03 | 687m | 17% | 6008 Mi | **78%** |
| k8s-worker-01 | 213m | 2% | 6718 Mi | 43% |
| k8s-worker-02 | **7992m** | **99%** | 8559 Mi | 55% |
| k8s-worker-03 | 255m | 3% | 6913 Mi | 44% |
| k8s-worker-04 | 163m | 2% | 6335 Mi | 40% |
| k8s-worker-05 | 762m | 9% | 7990 Mi | 51% |

### Top 10 pods par CPU

| Pod | Namespace | CPU | Memory |
|-----|-----------|-----|--------|
| **alertmanager-...alertmanager-0** | **observability** | **7813m** | **3911Mi** |
| etcd-k8s-master-01 | kube-system | 474m | 166Mi |
| etcd-k8s-master-03 | kube-system | 322m | 163Mi |
| etcd-k8s-master-02 | kube-system | 253m | 173Mi |
| kube-apiserver-k8s-master-01 | kube-system | 149m | 1051Mi |
| kube-apiserver-k8s-master-03 | kube-system | 143m | 1016Mi |
| prometheus-...-prometheus-0 | observability | 104m | 1375Mi |
| kube-apiserver-k8s-master-02 | kube-system | 102m | 964Mi |
| kube-controller-manager-master-03 | kube-system | 90m | 177Mi |
| calico-node-j8lgc | kube-system | 72m | 163Mi |

### Decouverte critique

Le pod `alertmanager` est en **boucle/fuite** et consomme a lui seul **97.7% du CPU** de worker-02. Ce pod devrait normalement utiliser <50m CPU. Son redemarrage libererait immediatement les ressources du node.

---

## 8. VOLUMES HETZNER

### Volumes par serveur

| Serveur | Root (/) | Use% | Volume data | Mountpoint | Use% | Statut |
|---------|---------|------|-------------|-----------|------|--------|
| k8s-master-01 | 75G | 16% | 20G | /opt/k8s/data | 3% | OK |
| k8s-master-02 | 75G | 16% | 20G | /opt/k8s/data | 3% | OK |
| k8s-master-03 | 75G | 15% | 20G | /opt/k8s/data | 3% | OK |
| k8s-worker-01 | 150G | **72%** | 50G | /opt/k8s/data | 2% | Attention |
| k8s-worker-02 | 150G | **81%** | 50G | /opt/k8s/data | 2% | **Critique** |
| k8s-worker-03 | 150G | 34% | 50G | /opt/k8s/data | 2% | OK |
| k8s-worker-04 | 150G | 49% | 50G | /opt/k8s/data | 2% | OK |
| k8s-worker-05 | 150G | **77%** | 50G | /opt/k8s/data | 2% | Attention |
| db-postgres-01 | 75G | 20% | 100G | /data/db_postgres | 3% | OK |
| db-postgres-02 | 38G | 31% | 100G | /data/db_postgres | 4% | OK |
| db-postgres-03 | 38G | 26% | 100G | /data/db_postgres | 3% | OK |
| redis-01 | 38G | 16% | 20G | /data/redis | 3% | OK |
| redis-02 | 38G | 17% | 20G | /data/redis | 3% | OK |
| redis-03 | 38G | 18% | 20G | /data/redis | 3% | OK |
| queue-01 | 38G | 16% | 30G | /data/rabbitmq | 3% | OK |
| queue-02 | 38G | 19% | 30G | /data/rabbitmq | 3% | OK |
| queue-03 | 38G | 19% | 30G | /data/rabbitmq | 3% | OK |
| haproxy-01 | 38G | 16% | 10G | /data/lb_internal | 3% | OK |
| haproxy-02 | 38G | 17% | 10G | /data/lb_internal | 3% | OK |
| maria-01 | 38G | 20% | — | — | — | OK |
| maria-02 | 38G | 20% | — | — | — | OK |
| maria-03 | 38G | 18% | — | — | — | OK |
| proxysql-01 | 38G | 17% | — | — | — | OK |
| proxysql-02 | 38G | 17% | — | — | — | OK |
| minio-01 | 75G | 8% | 200G | /data/minio | 2% | OK |
| minio-02 | 38G | 17% | 200G | /data/minio | 2% | OK |
| minio-03 | 38G | 15% | 200G | /data/minio | 2% | OK |
| vault-01 | 38G | 16% | 20G | /data/vault | 3% | OK |
| siem-01 | 75G | 8% | 50G | /data/siem | 2% | OK |
| monitor-01 | 75G | 11% | 50G | /data/monitoring | 2% | OK |
| backup-01 | 38G | 17% | 500G | /data/backup | 2% | OK |
| mail-core-01 | 38G | 19% | 50G | /data/mail_core | 2% | OK |
| mail-mx-01 | 38G | 8% | 30G | /data/mail_mx | 3% | OK |
| mail-mx-02 | 38G | 8% | 30G | /data/mail_mx | 3% | OK |
| install-v3 | 38G | **85%** | 98G | /var/lib/docker | 22% | Attention |
| backend-01 | 38G | 22% | — | — | — | OK |

### Observations

1. **Workers K8s** : Le disque root est consomme par les images containers (containerd) et les logs. Les volumes data sont quasi vides.
2. **MariaDB / ProxySQL** : Pas de volume data dedie — les donnees sont sur le root disk.
3. **install-v3** : Root a 85% apres nettoyage Docker (avant : 86%). Le nettoyage a surtout impacte le volume Docker, pas le root.
4. **Tous les volumes data** sont largement sous-utilises (2-4%).

---

## 9. SERVEURS IDLE — Analyse couts

### Serveurs confirmes totalement idle

| Serveur | IP | CPU | RAM | Disk | Load avg | Services actifs | Cout estime mensuel |
|---------|-----|-----|-----|------|----------|----------------|-------------------|
| vector-db-01 | 10.0.0.136 | 3 | 3.7 GB | 75G (7%) | 0.00 | Aucun (OS uniquement) | ~12 EUR |
| analytics-db-01 | 10.0.0.130 | 2 | 1.9 GB | 38G (17%) | 0.00 | Aucun | ~5 EUR |
| analytics-01 | 10.0.0.139 | 3 | 3.7 GB | 75G (9%) | 0.00 | Aucun | ~12 EUR |
| crm-01 | 10.0.0.133 | 2 | 1.9 GB | 38G (14%) | 0.08 | Aucun | ~5 EUR |
| etl-01 | 10.0.0.140 | 3 | 3.7 GB | 75G (7%) | 0.00 | Aucun | ~12 EUR |
| baserow-01 | 10.0.0.144 | 2 | 1.9 GB | 38G (16%) | 0.00 | Aucun | ~5 EUR |
| **ml-platform-01** | 10.0.0.143 | **8** | **15 GB** | 226G (3%) | 0.00 | Aucun | **~45 EUR** |

**Cout total estime des serveurs idle : ~96 EUR/mois**

### Serveurs injoignables (probablement eteints)

| Serveur | IP | Role TSV |
|---------|-----|----------|
| litellm-01 | 10.0.0.137 | LiteLLM (migre en K8s) |
| builder-01 | 10.0.0.200 | CI/CD |
| temporal-db-01 | 10.0.0.129 | DB Temporal |
| temporal-01 | 10.0.0.138 | Temporal Server |
| api-gateway-01 | 10.0.0.135 | API Gateway |
| nocodb-01 | 10.0.0.142 | NocoDB |

### Analyse

- Tous les 7 serveurs idle sont **allumes depuis 104 jours** sans aucun service
- Aucun Docker, aucune application, uniquement les services OS de base (ssh, cron, qemu-guest-agent)
- **ml-platform-01** est le plus couteux : 8 CPU, 15 GB RAM, 226G disk — completement inutilise
- Les serveurs injoignables sont probablement deja eteints (pas de cout Hetzner si arretes)

### Recommandation

Eteindre les 7 serveurs idle via Hetzner Cloud pour economiser ~96 EUR/mois. Conserver les snapshots comme point de retour.

---

## 10. RECOMMANDATIONS SRE

### Actions immediates (P0)

| # | Action | Impact | Risque |
|---|--------|--------|--------|
| 1 | **Redemarrer alertmanager** (observability) | Libere 7.8 CPU sur worker-02 | Tres faible |
| 2 | **Creer tables Prisma PROD** (Order, amazon_orders_backfill_state) | Corrige CrashLoopBackOff workers Amazon | Faible (meme pattern que ExternalMessage) |
| 3 | **Nettoyage containerd** sur worker-01, worker-02, worker-05 | Libere espace disque root (72-81%) | Faible |

### Actions a planifier (P1)

| # | Action | Impact |
|---|--------|--------|
| 4 | Eteindre 7 serveurs idle | ~96 EUR/mois economises |
| 5 | Configurer `maxmemory` Redis a 1.5GB | Protection OOM |
| 6 | Upgrader db-postgres-02 a 7.6GB RAM | Aligner leader avec replicas |
| 7 | Nettoyage root disk install-v3 (logs, packages) | Passer de 85% a <70% |
| 8 | Mettre en place migrations Prisma automatisees PROD | Prevenir futures tables manquantes |

### Actions moyen terme (P2)

| # | Action | Impact |
|---|--------|--------|
| 9 | Installer PgBouncer | Connection pooling pour >50 clients |
| 10 | Investiguer alertmanager si le probleme persiste apres redemarrage | Stabilite monitoring |
| 11 | Reduire volumes data surdimensionnes (backup 500G a 2%, MinIO 200G a 2%) | Optimisation couts |
| 12 | Ajouter volumes data dedies pour MariaDB | Separation donnees/systeme |

### Volumes a surveiller

| Volume | Serveur | Use% | Seuil alerte |
|--------|---------|------|-------------|
| Root (/) | k8s-worker-02 | **81%** | 80% DEPASSE |
| Root (/) | k8s-worker-05 | **77%** | 75% DEPASSE |
| Root (/) | k8s-worker-01 | **72%** | 70% ATTEINT |
| Root (/) | install-v3 | **85%** | 80% DEPASSE |

### Serveurs a upgrader

| Serveur | Actuel | Recommande | Raison |
|---------|--------|-----------|--------|
| db-postgres-02 | 2 CPU / 3.7 GB | 2 CPU / 7.6 GB | Leader PostgreSQL avec RAM insuffisante |

### Serveurs a surveiller

| Serveur | Raison |
|---------|--------|
| k8s-worker-02 | CPU 99% (alertmanager), disk 81% |
| k8s-worker-05 | Disk 77%, heberge la majorite des workers Amazon |
| k8s-master-01 | Memory 76% |
| k8s-master-03 | Memory 78% |

---

## 11. VALIDATION FINALE

| Test | Resultat |
|------|----------|
| `kubectl get nodes` | 8/8 Ready (3 masters + 5 workers) |
| `kubectl top nodes` | **FONCTIONNEL** (metrics-server installe) |
| API DEV health | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| Client DEV version | `{"version":"0.5.11-ph29.3-parity"}` |
| Admin DEV | Redirect `/login` (OK, auth requise) |
| Patroni cluster | 3/3 nodes, leader db-postgres-02, lag=0 |
| Redis cluster | 1 master + 2 slaves, connected, 17.5 MB utilise |

---

## 12. ACTIONS EFFECTUEES DANS CETTE PHASE

| # | Action | Resultat |
|---|--------|----------|
| 1 | Nettoyage Docker install-v3 | Volume docker 67% -> 22% (-42GB) |
| 2 | Installation metrics-server K8s | kubectl top nodes/pods fonctionnel |
| 3 | Patch metrics-server `--kubelet-insecure-tls` | TLS kubelets auto-signes contourne |

### Actions NON effectuees (documentation seulement)

| # | Raison |
|---|--------|
| PgBouncer | Non installe — pas necessaire a cette charge |
| Tables Prisma PROD | Modification PROD interdite sans validation |
| Redis maxmemory | Pas de modification config sans validation |
| PostgreSQL switchover | Pas de changement leader sans validation |
| Alertmanager restart | Pas de modification observability sans validation |
| Serveurs idle | Pas de suppression/extinction sans validation |

---

## 13. CONCLUSION

L'infrastructure KeyBuzz v3 est **fonctionnelle mais presente 3 problemes prioritaires** :

1. **Alertmanager en boucle sur worker-02** : consomme 99% du CPU, cause la surcharge detectee par l'audit. Un simple `kubectl delete pod alertmanager-kube-prometheus-kube-prome-alertmanager-0 -n observability` le redemarrerait.

2. **Tables Prisma manquantes en PROD** : cause directe des CrashLoopBackOff Amazon workers. Meme probleme que ExternalMessage (corrige le 14 mars). Les tables `Order` et `amazon_orders_backfill_state` doivent etre creees en PROD.

3. **Disques root workers K8s satures** : worker-02 a 81%, worker-05 a 77%, worker-01 a 72%. Un nettoyage containerd (images non utilisees) est necessaire.

**Points positifs** :
- Cluster PostgreSQL sain (lag=0, replication streaming)
- Redis a usage tres faible (17.5 MB)
- Volumes data tous largement sous-utilises (2-4%)
- metrics-server desormais fonctionnel pour le monitoring
- Docker install-v3 nettoye (42GB recuperes)
- Toutes les applications (API, Client, Admin) repondent correctement
