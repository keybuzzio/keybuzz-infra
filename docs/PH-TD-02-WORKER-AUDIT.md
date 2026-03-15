# PH-TD-02 — Worker Audit (Étape 0)

> Date : 15 mars 2026
> Statut : COMPLÉTÉ

---

## Workers Audités

| Worker | Codebase | Deployment | Replicas | Image avant |
|--------|----------|------------|----------|-------------|
| amazon-orders-worker | keybuzz-backend | keybuzz-backend-dev/prod | 2/1 | v1.0.41-ph263b-scheduler |
| amazon-items-worker | keybuzz-backend | keybuzz-backend-dev/prod | 1/1 | v1.0.41-ph263b-scheduler |
| outbound-worker | keybuzz-api | keybuzz-api-dev/prod | 1/1 | v3.5.96-ph85-ops-action-center |
| backfill-scheduler | keybuzz-backend | keybuzz-backend-dev/prod | 1/1 | v1.0.41-ph263b-scheduler |

## CronJobs Associés

| CronJob | Namespace | Schedule | Image |
|---------|-----------|----------|-------|
| outbound-tick-processor | keybuzz-api-dev/prod | `*/1 * * * *` | curl-jq (HTTP trigger) |
| sla-evaluator | keybuzz-api-dev/prod | `*/1 * * * *` | postgres:17-alpine (SQL) |
| amazon-orders-sync | keybuzz-backend-dev/prod | `*/5 * * * *` | curl (HTTP trigger) |
| amazon-orders-backfill | keybuzz-backend-dev | `3,13,23,33,43,53 * * * *` | curl (HTTP trigger) |

## Erreurs Identifiées

### 1. Outbound Worker — PG 57P01

```
error: Connection terminated unexpectedly
  severity: 'FATAL',
  code: '57P01',     // admin shutdown (Patroni failover)
  routine: 'ProcessInterrupts'
```

**Cause** : Patroni failover ou maintenance PostgreSQL déconnecte les connexions actives.
**Fréquence** : ~3 fois en 3 jours
**Impact** : worker crash → K8s restart → ~10s downtime outbound

### 2. Amazon Orders Worker — Prisma P1001

```
PrismaClientKnownRequestError:
  Can't reach database server at 10.0.0.10:5432
  code: 'P1001'
```

**Cause** : HAProxy temporairement inaccessible pendant failover DB.
**Fréquence** : ~3 fois en 10 jours
**Impact** : worker crash → K8s restart → ~10s downtime sync

### 3. Amazon Items Worker — Même pattern

Même cause et impact que le orders worker.

## Dépendances

| Worker | DB | Secrets | APIs externes |
|--------|----|---------|---------------|
| outbound-worker | keybuzz_prod (pg.Pool) | PGHOST/USER/PASSWORD/DATABASE | SMTP, Amazon SP-API, Octopia API |
| amazon-orders-worker | keybuzz_backend_prod (Prisma) | DATABASE_URL | Amazon SP-API |
| amazon-items-worker | keybuzz_backend_prod (Prisma) | DATABASE_URL | Amazon SP-API |
| backfill-scheduler | keybuzz_backend_prod (Prisma) | DATABASE_URL | - |

## Stratégie Retry Pré-Existante

| Worker | Retry par item | Dead-letter | Backoff |
|--------|---------------|-------------|---------|
| outbound-worker | Oui (5 attempts, markFailed) | outbound_deliveries.status='failed' | Exponentiel 1min-1h |
| orders-worker | Oui (par tenant, retryAfter) | backfill_state.status='ERROR' | 5-30 min |
| items-worker | Oui (par order, continue) | Log uniquement | Fixe 1-5s |

## Worker le Plus Fragile

**outbound-worker** : seul worker sans reconnexion DB automatique et qui traite des données critiques (réponses clients).
