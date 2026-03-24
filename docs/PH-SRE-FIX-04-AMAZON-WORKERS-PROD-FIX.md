# PH-SRE-FIX-04 — Correction Amazon Workers PROD

> Date : 15 mars 2026
> Auteur : CE (Cursor)
> Environnement : PROD (keybuzz-backend-prod)
> Base de donnees : keybuzz_prod sur db-postgres-02 (10.0.0.121, leader)
> Statut : **TERMINE — SUCCES**

---

## 1. Resume executif

### Probleme

Les pods `amazon-orders-worker` et `amazon-items-worker` en PROD etaient en **CrashLoopBackOff** depuis 9 jours (~583 et ~555 restarts respectivement). Cause : tables Prisma manquantes dans la base `keybuzz_prod`.

### Cause racine

**Desalignement architectural des bases de donnees** :

| Env | Secret `keybuzz-backend-db` | Base cible | Schema |
|---|---|---|---|
| **DEV** | `kb_backend@keybuzz_backend` | `keybuzz_backend` | Prisma PascalCase (40 tables) |
| **PROD** | `keybuzz_api_prod@keybuzz_prod` | `keybuzz_prod` | API snake_case (74 tables) |

Les workers DEV connectent a `keybuzz_backend` qui contient toutes les tables Prisma. Les workers PROD connectent a `keybuzz_prod` qui ne contenait PAS les tables Prisma des workers Amazon.

### Solution

Creation des 6 tables manquantes + 7 enums + 15 index + 1 FK + 1 trigger dans `keybuzz_prod`, avec owner `keybuzz_api_prod`.

### Resultat

| Pod | Avant | Apres |
|---|---|---|
| `amazon-orders-worker` | CrashLoopBackOff (555 restarts) | **Running** (0 restarts) |
| `amazon-items-worker` | CrashLoopBackOff (583 restarts) | **Running** (0 restarts) |

---

## 2. Diagnostic detaille

### 2.1 Erreurs workers

**amazon-orders-worker** :
```
PrismaClientKnownRequestError: Raw query failed. Code: 42P01
Message: relation "amazon_orders_backfill_state" does not exist
```

**amazon-items-worker** :
```
PrismaClientKnownRequestError: Raw query failed. Code: 42P01
Message: relation "Order" does not exist
```

### 2.2 Tables utilisees par les workers (analyse code source)

| Table | orders-worker | items-worker | Operations |
|---|---|---|---|
| `Order` | SELECT, COUNT | SELECT, JOIN | Lecture ordres Amazon |
| `OrderItem` | JOIN | LEFT JOIN | Lecture items commande |
| `amazon_orders_backfill_state` | SELECT, INSERT, UPDATE | — | Etat backfill par tenant |
| `amazon_backfill_locks` | INSERT, DELETE, SELECT | INSERT, DELETE, SELECT | Verrous exclusifs |
| `amazon_backfill_schedule` | (scheduler) | (scheduler) | Planification backfill |
| `amazon_backfill_tenant_metrics` | (scheduler) | (scheduler) | Metriques par tenant |

### 2.3 PostgreSQL PROD (leader)

| Attribut | Valeur |
|---|---|
| Cluster | keybuzz-pg17 |
| Leader | db-postgres-02 (10.0.0.121) |
| Replicas | db-postgres-01, db-postgres-03 (streaming, lag 0) |
| Timeline | 16 |
| Version | PostgreSQL 17.7 |

---

## 3. Diff DEV vs PROD (avant correction)

### 3.1 Tables

| Table | DEV (`keybuzz_backend`) | PROD (`keybuzz_prod`) |
|---|---|---|
| `Order` (PascalCase) | Oui | **NON** |
| `OrderItem` (PascalCase) | Oui | **NON** |
| `amazon_orders_backfill_state` | Oui | **NON** |
| `amazon_backfill_locks` | Oui | **NON** |
| `amazon_backfill_schedule` | Oui | **NON** |
| `amazon_backfill_tenant_metrics` | Oui | **NON** |

### 3.2 Enums

| Enum | DEV | PROD | Valeurs |
|---|---|---|---|
| `BackfillStatus` | Oui | **NON** | PENDING, RUNNING, PAUSED, DONE, ERROR |
| `OrderStatus` | Oui | **NON** | PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED, RETURNED |
| `DeliveryStatus` | Oui | **NON** | PREPARING, SHIPPED, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED, DELAYED, LOST |
| `SavStatus` | Oui | **NON** | NONE, OPEN, IN_PROGRESS, RESOLVED |
| `SlaStatus` | Oui | **NON** | OK, AT_RISK, BREACHED |
| `FulfillmentChannel` | Oui | **NON** | FBM, FBA, UNKNOWN |
| `TrackingSource` | Oui | **NON** | ORDERS_API, REPORTS, AMAZON_FBA, NOT_AVAILABLE |

### 3.3 Comptage tables

| Base | Avant | Apres |
|---|---|---|
| `keybuzz_prod` | 74 tables | **80 tables** (+6) |
| `keybuzz_backend` (DEV) | 40 tables | 40 tables (inchange) |

---

## 4. SQL applique

### Migration transactionnelle (BEGIN ... COMMIT)

```sql
-- 7 enums (CREATE TYPE ... IF NOT EXISTS via DO block)
BackfillStatus, OrderStatus, DeliveryStatus, SavStatus, SlaStatus, FulfillmentChannel, TrackingSource

-- 6 tables (CREATE TABLE IF NOT EXISTS)
"Order", "OrderItem", amazon_orders_backfill_state, amazon_backfill_locks,
amazon_backfill_schedule, amazon_backfill_tenant_metrics

-- 15 index
Order: 6 index (PK + 5 btree dont 1 UNIQUE)
OrderItem: 2 index (PK + orderId)
amazon_orders_backfill_state: 5 index (PK + 3 btree + 1 UNIQUE)
amazon_backfill_locks: 4 index (PK + UNIQUE tenantId/lockType + 2 btree)
amazon_backfill_schedule: 4 index (PK + 3 btree)
amazon_backfill_tenant_metrics: 1 index (PK)

-- 1 FK
OrderItem.orderId -> Order.id (ON UPDATE CASCADE ON DELETE CASCADE)

-- 1 trigger function + trigger
update_amazon_orders_backfill_state_updated_at() BEFORE UPDATE

-- 6 GRANT ALL PRIVILEGES TO keybuzz_api_prod
```

### Resultat execution

```
BEGIN
DO x7 (enums)
CREATE TABLE x6
ALTER TABLE x6 (ownership)
CREATE INDEX x15
ALTER TABLE x1 (FK)
CREATE FUNCTION
ALTER FUNCTION
CREATE TRIGGER
GRANT x6
COMMIT
```

Zero erreur. Transaction committee.

---

## 5. Pods avant / apres

### Avant (9 jours de CrashLoopBackOff)

```
amazon-items-worker-6f5f86956f-7kh97   0/1   CrashLoopBackOff   583 restarts   9d
amazon-orders-worker-544b4fd59-bcc7c    0/1   CrashLoopBackOff   555 restarts   9d
```

### Apres (redemarrage par kubectl delete pod)

```
amazon-items-worker-6f5f86956f-kh4mw   1/1   Running   0 restarts   stable
amazon-orders-worker-544b4fd59-cmzkx    1/1   Running   0 restarts   stable
```

### Verification stabilite (+2 minutes)

Les deux workers sont restes Running avec 0 restarts apres 2 minutes de surveillance.

---

## 6. Logs workers post-fix

### amazon-orders-worker

```
[OrdersWorker-PROD] Starting ORDERS FAST PATH worker...
[OrdersWorker-PROD] Worker ID: amazon-orders-worker-544b4fd59-cmzkx
[OrdersWorker] WORKER_LOOP_START worker=... maxIterations=Infinity scheduler=ACTIVE
[OrdersWorker] CONFIG chunk=30d batchFetch=100 batchUpsert=300 rateLimit=600ms
[OrdersWorker] IDLE worker=... iteration=24 totalPersisted=0
```

- `scheduler=ACTIVE` (connecte au scheduler)
- Boucle IDLE : pas d'ordres a traiter (tables vides, comportement normal)
- **Zero erreur Prisma**

### amazon-items-worker

```
[ItemsWorker-PROD] Starting ITEMS ASYNC BACKGROUND worker...
[ItemsWorker-PROD] Worker ID: amazon-items-worker-6f5f86956f-kh4mw
[ItemsWorker] WORKER_LOOP_START worker=... maxIterations=Infinity scheduler=ACTIVE
[ItemsWorker] CONFIG batch=20 rateLimit=500ms maxCalls=30/min
[ItemsWorker] GLOBAL_NO_WORK scheduler=true
[ItemsWorker] IDLE worker=... iteration=4 totalFilled=0 totalFailed=0
```

- `scheduler=ACTIVE` (connecte au scheduler)
- `GLOBAL_NO_WORK` : pas d'items a traiter (tables vides, comportement normal)
- **Zero erreur Prisma**

---

## 7. Validation cluster

### Nodes (8/8 Ready)

| Node | Status | Role |
|---|---|---|
| k8s-master-01 | Ready | control-plane |
| k8s-master-02 | Ready | control-plane |
| k8s-master-03 | Ready | control-plane |
| k8s-worker-01 | Ready | worker |
| k8s-worker-02 | Ready | worker |
| k8s-worker-03 | Ready | worker |
| k8s-worker-04 | Ready | worker |
| k8s-worker-05 | Ready | worker |

### Pods PROD backend (6/6)

| Pod | Status | Restarts |
|---|---|---|
| amazon-items-worker | Running | 0 |
| amazon-orders-worker | Running | 0 |
| backfill-scheduler | Running | 0 |
| keybuzz-backend | Running | 0 |
| amazon-orders-sync (CronJob) | Completed | 0 |

### Pods PROD API (3/3)

| Pod | Status | Restarts |
|---|---|---|
| keybuzz-api | Running | 0 |
| keybuzz-outbound-worker | Running | 2 |
| outbound-tick-processor (CronJob) | Completed | 0 |

### Endpoints

| Service | URL | Statut |
|---|---|---|
| API DEV | `https://api-dev.keybuzz.io/health` | `{"status":"ok"}` |
| Client DEV | `https://client-dev.keybuzz.io` | Redirect `/login` (OK) |
| Admin DEV | `https://admin-dev.keybuzz.io` | Redirect `/login` (OK) |

---

## 8. Validation pipeline Amazon

Les workers fonctionnent correctement :
- `scheduler=ACTIVE` indique une connexion reussie au `backfill-scheduler`
- Les boucles IDLE sont normales car les tables PROD sont vides (pas encore de donnees backfill)
- Les CronJobs `amazon-orders-sync` s'executent et se completent normalement

Pour que le pipeline commence a traiter des donnees, il faut :
1. Un tenant PROD avec des credentials Amazon SP-API configurees
2. Le scheduler doit activer le backfill pour ce tenant
3. Les workers traiteront alors les ordres/items

---

## 9. Architecture database — constat et recommandation

### Constat

L'architecture actuelle presente un desalignement :

```
DEV:
  keybuzz-backend (Fastify) → keybuzz_backend (Prisma, 40 tables)
  keybuzz-api     (Fastify) → keybuzz        (API, 80 tables)

PROD:
  keybuzz-backend (Fastify) → keybuzz_prod   (API, 80 tables)  ← PAS de DB backend separee
  keybuzz-api     (Fastify) → keybuzz_prod   (API, 80 tables)
```

En DEV, le backend a sa propre base avec son propre schema Prisma.
En PROD, le backend partage la meme base que l'API.

### Risque

Melange de schemas (PascalCase Prisma + snake_case API) dans une meme base.
Les migrations Prisma (`_prisma_migrations`) ne sont pas presentes en PROD — les tables ont ete creees manuellement.

### Recommandation

A moyen terme, creer une base `keybuzz_backend_prod` dediee avec le schema Prisma complet, et mettre a jour le secret `keybuzz-backend-db` en PROD pour pointer vers cette base. Cela alignerait l'architecture DEV/PROD.

---

## 10. Risques restants

| Risque | Severite | Action recommandee |
|---|---|---|
| Schema Prisma PROD non gere par `_prisma_migrations` | MOYENNE | Ajouter table `_prisma_migrations` ou creer base separee |
| Pas de base `keybuzz_backend_prod` separee | FAIBLE | Planifier migration architecture |
| Tables PROD vides (pas de donnees Amazon backfill) | INFO | Normal — remplissage au premier tenant PROD avec SP-API |
| Redis `maxmemory` a 0 (PH-SRE-FIX-02) | FAIBLE | Configurer en phase future |
| Asymetrie PostgreSQL leader/replica (PH-SRE-FIX-02) | FAIBLE | Surveiller |

---

## 11. Chronologie actions

| Heure (UTC) | Action |
|---|---|
| 08:10 | Preflight : identification leader PostgreSQL (db-postgres-02) |
| 08:11 | Verification pods PROD : 2 CrashLoopBackOff confirmes |
| 08:13 | Comparaison tables DEV vs PROD : 6 tables + 7 enums manquants |
| 08:17 | Extraction schema depuis `keybuzz_backend` (pg_dump) |
| 08:19 | Redaction SQL migration transactionnelle |
| 08:20 | Upload et execution migration sur `keybuzz_prod` : **COMMIT OK** |
| 08:20 | Verification : 6/6 tables, 7/7 enums, 22 index, FK, trigger OK |
| 08:21 | Redemarrage workers (`kubectl delete pod`) |
| 08:21 | Workers Running, 0 restarts, logs sains |
| 08:22 | Validation cluster : 8 nodes Ready, endpoints OK |
| 08:23 | Verification stabilite +2min : workers stables, IDLE normal |

---

## 12. Fichiers et artefacts

| Fichier | Contenu |
|---|---|
| `/opt/keybuzz/logs/ph-sre/ph-sre-fix-04/00_start.txt` | Timestamp debut |
| `/opt/keybuzz/logs/ph-sre/ph-sre-fix-04/01_enums_backend.txt` | Enums keybuzz_backend (152 valeurs) |
| `/opt/keybuzz/logs/ph-sre/ph-sre-fix-04/02_enums_prod.txt` | Enums keybuzz_prod (34 valeurs avant) |
| `/opt/keybuzz/logs/ph-sre/ph-sre-fix-04/03_schema_dump.sql` | pg_dump tables cibles (370 lignes) |
| `/tmp/sre_fix04_migrate.sql` | SQL migration applique (bastion + leader) |
| `keybuzz-infra/docs/PH-SRE-FIX-04-AMAZON-WORKERS-PROD-FIX.md` | Ce rapport |

---

## 13. Ce qui n'a PAS ete touche

- Base DEV (`keybuzz`, `keybuzz_backend`) : aucune modification
- Workers DEV : non touches
- Admin v1 legacy : non touche
- Infrastructure K8s : aucune modification
- Secrets/Vault : non modifies
- Configurations workers : non modifiees (memes images, memes deployments)
- Tables existantes `keybuzz_prod` : aucune modification des 74 tables originales
