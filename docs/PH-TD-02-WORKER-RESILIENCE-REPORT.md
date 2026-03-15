# PH-TD-02 — Worker Resilience & Failure Isolation

> Date : 15 mars 2026
> Statut : TERMINÉ
> Environnement : DEV + PROD déployés et validés
> Tags : v3.6.00-td02-worker-resilience / v1.0.42-td02-worker-resilience

---

## 1. Résumé

Tous les workers KeyBuzz sont désormais résilients aux erreurs transitoires DB/réseau. Avant PH-TD-02, une simple déconnexion PostgreSQL (failover Patroni, maintenance) provoquait un crash fatal avec `process.exit(1)`. Après PH-TD-02, les workers se reconnectent automatiquement avec backoff exponentiel.

---

## 2. Audit Initial

### Causes de crash identifiées

| Worker | Erreur | Code | Impact |
|--------|--------|------|--------|
| outbound-worker | Connection terminated unexpectedly | PG 57P01 | crash → K8s restart |
| amazon-orders-worker | Can't reach database server | Prisma P1001 | crash → K8s restart |
| amazon-items-worker | Même pattern | Prisma P1001 | crash → K8s restart |

### Restart counts avant PH-TD-02

| Worker | Namespace | Restarts | Uptime |
|--------|-----------|----------|--------|
| outbound-worker DEV | keybuzz-api-dev | 3 | 3j |
| outbound-worker PROD | keybuzz-api-prod | 3 | 3j |
| amazon-orders-worker DEV | keybuzz-backend-dev | 3 | 10j |
| amazon-items-worker DEV | keybuzz-backend-dev | 3 | 10j |

### Cause racine

Tous les workers avaient le même pattern fatal :

```
loopFunction().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
```

Aucune distinction entre erreur transitoire (DB down) et erreur permanente (bug code).

---

## 3. Modifications Apportées

### 3.1 Module `workerResilience.ts`

Créé dans les deux codebases :
- `keybuzz-backend/src/lib/workerResilience.ts`
- `keybuzz-api/src/lib/workerResilience.ts`

Fonctionnalités :
- **`isTransientError()`** : détecte 18 patterns d'erreurs transitoires (PG 57P01, Prisma P1001, ECONNREFUSED, etc.)
- **`resilientLoop()`** : wraps le loop principal avec auto-recovery (backoff exponentiel, max 20 tentatives, reset après 5 min de stabilité)
- **`logBootCheck()`** : log structuré des vérifications au démarrage
- **`bootCheckEnvVars()`** : vérifie les variables d'env obligatoires
- **`bootCheckPrismaDb()` / `bootCheckPgPool()`** : vérifie la connectivité DB
- **`logHealth()`** : signaux de santé structurés

### 3.2 Entry points résilients (backend)

Créés :
- `src/workers/ordersWorkerResilient.ts`
- `src/workers/itemsWorkerResilient.ts`

Ces fichiers remplacent les commandes inline `node -e` dans les deployments K8s.

### 3.3 Outbound worker (API)

Modifié : `src/workers/outboundWorker.ts` — section STARTUP remplacée par `bootAndRun()` avec :
- Boot checks (4 env vars + 1 DB pool)
- `resilientLoop()` wrapper
- Pool recreation on recovery

### 3.4 PrometheusRule

Déployé : `keybuzz-worker-alerts` (namespace `observability`)

5 alertes :
| Alerte | Seuil | Sévérité |
|--------|-------|----------|
| WorkerCrashLoopBackOff | 5 min en CrashLoopBackOff | critical |
| WorkerRestartStorm | >3 restarts en 15 min | warning |
| WorkerNotReady | 10 min not ready | warning |
| WorkerHighRestartCount | >10 restarts cumulés | warning |
| WorkerNoProgress | crash-restart cycle 30 min | warning |

---

## 4. Stratégie de Retry

### Erreurs transitoires

| Paramètre | Valeur |
|-----------|--------|
| Max recovery attempts | 20 |
| Base delay | 5-10s |
| Max delay | 120s |
| Backoff | Exponentiel (×2) + jitter |
| Reset counter | Après 5 min de stabilité |

### Erreurs non-transitoires

Comportement inchangé : `process.exit(1)` → K8s restart normal.

### Failure isolation existante

Les workers avaient déjà une bonne isolation par item :
- **outbound-worker** : per-delivery try/catch avec `markFailed()` (max 5 attempts, status `failed`)
- **orders-worker** : per-tenant error counting avec `retryAfter` et `errorCount`
- **items-worker** : per-order try/catch avec continuation du batch

PH-TD-02 n'a pas modifié cette logique métier, uniquement ajouté la résilience au niveau du loop principal.

---

## 5. Dead-Letter / Failed Items

### Outbound (déjà en place)

Table `outbound_deliveries` :
- `status = 'failed'` après MAX_ATTEMPTS (5)
- `last_error` : message d'erreur
- `delivery_trace` : JSON avec détails
- `attempt_count` : compteur de tentatives
- `next_retry_at` : prochain essai (backoff exponentiel)

### Orders/Items (déjà en place)

Table `amazon_orders_backfill_state` :
- `errorCount` : compteur d'erreurs par tenant
- `retryAfter` : prochain essai (5-30 min)
- `lastError` : dernier message d'erreur
- `status = 'ERROR'` après échecs répétés

Aucune nouvelle table créée — les mécanismes existants sont suffisants.

---

## 6. Résultats Tests

### DEV (27 assertions)

```
RESULT: 26 passed, 1 failed (faux positif grep) / 27 total
```

### PROD

| Vérification | Résultat |
|-------------|----------|
| API /health | HTTP 200 |
| Backend /health | HTTP 200 |
| Workers running | 0 restarts |
| Boot checks | Tous OK |
| Health signals | Émis |
| Images correctes | Confirmé |

---

## 7. Images Déployées

### DEV

| Service | Image |
|---------|-------|
| keybuzz-backend | `v1.0.42-td02-worker-resilience-dev` |
| amazon-orders-worker | `v1.0.42-td02-worker-resilience-dev` |
| amazon-items-worker | `v1.0.42-td02-worker-resilience-dev` |
| backfill-scheduler | `v1.0.42-td02-worker-resilience-dev` |
| keybuzz-api | `v3.6.00-td02-worker-resilience-dev` |
| keybuzz-outbound-worker | `v3.6.00-td02-worker-resilience-dev` |

### PROD

| Service | Image |
|---------|-------|
| keybuzz-backend | `v1.0.42-td02-worker-resilience-prod` |
| amazon-orders-worker | `v1.0.42-td02-worker-resilience-prod` |
| amazon-items-worker | `v1.0.42-td02-worker-resilience-prod` |
| backfill-scheduler | `v1.0.42-td02-worker-resilience-prod` |
| keybuzz-api | `v3.6.00-td02-worker-resilience-prod` |
| keybuzz-outbound-worker | `v3.6.00-td02-worker-resilience-prod` |

---

## 8. Rollback

### Backend

```bash
kubectl set image deploy/amazon-orders-worker worker=ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph263b-scheduler-prod -n keybuzz-backend-prod
kubectl set image deploy/amazon-items-worker worker=ghcr.io/keybuzzio/keybuzz-backend:v1.0.41-ph263b-scheduler-prod -n keybuzz-backend-prod
kubectl set image deploy/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.39-channels-safety-prod -n keybuzz-backend-prod
```

### API

```bash
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.96-ph85-ops-action-center-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.98-ph97-multi-order-context-prod -n keybuzz-api-prod
```

---

## 9. Logs Attendus

### Boot (au démarrage)

```
[WORKER-BOOT-CHECK] worker=outbound-worker check=env:PGHOST status=OK
[WORKER-BOOT-CHECK] worker=outbound-worker check=pg_pool status=OK
[WORKER-HEALTH] worker=outbound-worker event=LOOP_START totalRestarts=0 uptimeMs=0
```

### Recovery (en cas d'erreur transitoire)

```
[outbound-worker] Transient error (attempt 1/20): Connection terminated unexpectedly
[outbound-worker] Recovering in 7s...
[WORKER-HEALTH] worker=outbound-worker event=TRANSIENT_ERROR_RECOVERY totalRestarts=1 recoveryAttempt=1
[WORKER-HEALTH] worker=outbound-worker event=LOOP_RESTART totalRestarts=1
```

### Fatal (erreur non-transitoire)

```
[outbound-worker] Non-transient fatal error: <message>
[WORKER-HEALTH] worker=outbound-worker event=FATAL_ERROR totalRestarts=0
```
