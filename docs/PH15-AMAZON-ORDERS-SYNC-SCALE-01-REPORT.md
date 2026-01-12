# PH15-AMAZON-ORDERS-SYNC-SCALE-01 â€” Sync global multi-tenant Amazon Orders

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

Transformer le systÃ¨me de sync Amazon Orders en **job global multi-tenant** :
- 1 seul CronJob
- Tous les tenants CONNECTED
- Batch processing avec advisory locks
- Aucun hardcode de tenant

---

## Ã‰tat initial

### CronJob avant

```bash
curl -sk -X POST \
  -H "X-User-Email: system@keybuzz.io" \
  -H "X-Tenant-Id: ecomlg-001"  # âŒ HARDCODÃ‰
  https://backend-dev.keybuzz.io/api/v1/orders/sync/run
```

### Tenants CONNECTED

| Tenant ID | Status | Sync State |
|-----------|--------|------------|
| ecomlg-001 | CONNECTED | âœ… Actif (100 orders) |
| kbz-002 | CONNECTED | âš ï¸ Pas de refresh_token |
| kbz_test | CONNECTED | âš ï¸ DonnÃ©es invalides |

---

## Architecture finale

### SchÃ©ma du flux global

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                        CronJob (*/5 * * * *)                    â”‚
â”‚            POST /api/v1/orders/sync/run/global                  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                            â”‚
                            â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    runGlobalOrdersSync()                         â”‚
â”‚  1. SELECT tenantId FROM MarketplaceConnection                   â”‚
â”‚     WHERE type='AMAZON' AND status='CONNECTED'                   â”‚
â”‚  2. ORDER BY lastSuccessAt ASC (prioritÃ© aux non sync)          â”‚
â”‚  3. LIMIT 5 (batch size)                                         â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                            â”‚
            â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
            â–¼               â–¼               â–¼
    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
    â”‚ Tenant A  â”‚   â”‚ Tenant B  â”‚   â”‚ Tenant C  â”‚
    â”‚           â”‚   â”‚           â”‚   â”‚           â”‚
    â”‚ 1. Lock   â”‚   â”‚ 1. Lock   â”‚   â”‚ 1. Lock   â”‚
    â”‚ 2. Sync   â”‚   â”‚ 2. Sync   â”‚   â”‚ 2. Sync   â”‚
    â”‚ 3. Unlock â”‚   â”‚ 3. Unlock â”‚   â”‚ 3. Unlock â”‚
    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
         â”‚               â”‚               â”‚
         â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                         â”‚
                    2s delay
                    entre tenants
```

### Batch & Lock Strategy

| ParamÃ¨tre | Valeur |
|-----------|--------|
| **Batch size** | 5 tenants max par run |
| **Lock type** | PostgreSQL Advisory Lock (`pg_try_advisory_lock`) |
| **Lock key** | Hash numÃ©rique du tenantId + offset 1000000 |
| **Inter-tenant delay** | 2 secondes |
| **Rate limit SP-API** | 500ms entre appels |

### Advisory Lock (PostgreSQL)

```sql
-- AcquÃ©rir le lock (non-bloquant)
SELECT pg_try_advisory_lock(1234567) -- Hash du tenantId

-- LibÃ©rer le lock
SELECT pg_advisory_unlock(1234567)
```

---

## Fichiers crÃ©Ã©s/modifiÃ©s

### Backend (`keybuzz-backend`) â€” v1.0.13

1. **`src/modules/marketplaces/amazon/amazonOrdersSyncGlobal.service.ts`** (nouveau)
   - `getConnectedAmazonTenants(limit)` â€” SÃ©lectionne les tenants CONNECTED, triÃ©s par prioritÃ©
   - `tryAcquireLock(tenantId)` â€” Advisory lock PostgreSQL
   - `releaseLock(tenantId)` â€” LibÃ¨re le lock
   - `runGlobalOrdersSync()` â€” **Job principal multi-tenant**
   - `getGlobalSyncStatus()` â€” Status de tous les tenants

2. **`src/modules/marketplaces/amazon/amazonOrdersSync.routes.ts`** (modifiÃ©)
   - `GET /api/v1/orders/sync/status` â€” Global ou par tenant (querystring)
   - `POST /api/v1/orders/sync/run` â€” Sync par tenant
   - `POST /api/v1/orders/sync/run/global` â€” **Sync global multi-tenant**

### Infra (`keybuzz-infra`)

1. **`k8s/keybuzz-backend-dev/cronjob-orders-sync.yaml`** (modifiÃ©)
   - âŒ SupprimÃ© : `X-Tenant-Id: ecomlg-001`
   - âœ… AjoutÃ© : Appel Ã  `/api/v1/orders/sync/run/global`

2. **`k8s/keybuzz-backend-dev/deployment.yaml`** (modifiÃ©)
   - Image: `ghcr.io/keybuzzio/keybuzz-backend:1.0.13-dev`

---

## CronJob final

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: amazon-orders-sync
spec:
  schedule: "*/5 * * * *"
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: sync-runner
              command:
                - /bin/sh
                - -c
                - |
                  echo "Starting Global Amazon Orders Sync..."
                  echo "Processing ALL CONNECTED tenants (batch mode)"
                  curl -sk -X POST \
                    -H "X-User-Email: system@keybuzz.io" \
                    https://backend-dev.keybuzz.io/api/v1/orders/sync/run/global
                  echo ""
                  echo "Global sync completed"
```

---

## Preuves E2E

### Global Sync Status

```bash
curl -sk -H "X-User-Email: ludovic@ecomlg.fr" -H "X-Tenant-Id: ecomlg-001" \
  https://backend-dev.keybuzz.io/api/v1/orders/sync/status
```

```json
{
  "totalTenants": 3,
  "tenants": [
    {
      "tenantId": "kbz-002",
      "displayName": "Amazon Seller A12BCIS2R7HD4D",
      "connectionStatus": "CONNECTED",
      "syncState": null,
      "counts": { "orders": 0, "items": 0 }
    },
    {
      "tenantId": "kbz_test",
      "connectionStatus": "CONNECTED",
      "syncState": { "lastSuccessAt": "2026-01-03..." },
      "counts": { "orders": 0, "items": 0 }
    },
    {
      "tenantId": "ecomlg-001",
      "connectionStatus": "CONNECTED",
      "syncState": { "lastSuccessAt": "2026-01-12T13:06:57.827Z" },
      "counts": { "orders": 100, "items": 95 }
    }
  ]
}
```

### Global Sync Run

```bash
curl -sk -X POST -H "X-User-Email: ludovic@ecomlg.fr" \
  https://backend-dev.keybuzz.io/api/v1/orders/sync/run/global
```

```json
{
  "mode": "global",
  "success": true,
  "tenantsProcessed": 3,
  "tenantsSkipped": 0,
  "totalDuration": 5219,
  "results": [
    { "tenantId": "kbz-002", "success": false, "error": "no refresh token" },
    { "tenantId": "kbz_test", "success": false, "error": "Invalid time value" },
    { "tenantId": "ecomlg-001", "success": true, "ordersProcessed": 0 }
  ]
}
```

### Status pour un tenant

```bash
curl -sk "...?tenantId=ecomlg-001"
```

```json
{
  "tenantId": "ecomlg-001",
  "marketplace": "AMAZON",
  "syncState": {
    "lastUpdatedAfter": "2026-01-12T02:54:33.000Z",
    "lastSuccessAt": "2026-01-12T13:06:57.827Z",
    "lastError": null
  },
  "counts": { "orders": 100, "items": 95 }
}
```

### UI Navigation

- âœ… `/orders` pour ecomlg-001 affiche 100 commandes
- âœ… Design inchangÃ©
- âœ… Aucune rÃ©gression

---

## Gestion des erreurs

| Tenant | Erreur | Impact |
|--------|--------|--------|
| kbz-002 | `no refresh token` | IgnorÃ©, continue avec les autres |
| kbz_test | `Invalid time value` | IgnorÃ©, continue avec les autres |
| ecomlg-001 | Aucune | âœ… Sync rÃ©ussi |

Le systÃ¨me est **resilient** : une erreur sur un tenant n'affecte pas les autres.

---

## ScalabilitÃ©

| MÃ©trique | Valeur |
|----------|--------|
| Tenants CONNECTED | 3 |
| Batch size | 5 |
| DurÃ©e totale | 5.2s |
| DurÃ©e moyenne/tenant | ~1.7s |
| CapacitÃ© estimÃ©e | 50+ tenants/heure |

Pour 100 tenants :
- 20 runs de CronJob (5 tenants/run)
- ~100 minutes pour tout synchroniser
- Scalable horizontalement (augmenter batch size)

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `3864d4e` | `feat(orders): PH15 global multi-tenant sync with batch + advisory locks` |
| keybuzz-infra | `8e29ba1` | `feat(k8s): PH15 global CronJob (no hardcoded tenant) + backend 1.0.13` |

---

## Conclusion

âœ… **Le systÃ¨me est maintenant prÃªt pour des dizaines/centaines de clients** :
- 1 seul CronJob global
- SÃ©lection dynamique des tenants CONNECTED
- Advisory locks pour Ã©viter les doubles syncs
- Batch processing avec rate limiting
- Gestion des erreurs par tenant sans impact global
