# PH15-AMAZON-ORDERS-SYNC-01 â€” Sync incrÃ©mental Amazon Orders

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

Mettre en place un **sync incrÃ©mental** des commandes Amazon pour le tenant ecomlg-001 :
1. Delta sync avec `lastUpdatedAfter`
2. Import complet des `order_items`
3. Ã‰tat de synchronisation persistant
4. CronJob automatique (toutes les 5 minutes)

---

## Architecture

### Tables utilisÃ©es

| Table | Usage |
|-------|-------|
| `Order` | Commandes Amazon (upsert par `tenantId + marketplace + externalOrderId`) |
| `OrderItem` | Items de commandes (recrÃ©Ã©s Ã  chaque sync) |
| `MarketplaceSyncState` | Ã‰tat de sync (`cursor` = `lastUpdatedAfter`) |

### Sync State

```
MarketplaceSyncState:
  - tenantId: ecomlg-001
  - type: AMAZON
  - cursor: "2026-01-12T02:54:23.000Z"  (lastUpdatedAfter)
  - lastPolledAt: "2026-01-12T12:18:48.923Z"
  - lastSuccessAt: "2026-01-12T12:18:54.521Z"
  - lastError: null
```

---

## Fichiers crÃ©Ã©s/modifiÃ©s

### Backend (`keybuzz-backend`) â€” v1.0.12

1. **`src/modules/marketplaces/amazon/amazonOrdersSync.service.ts`** (nouveau)
   - `getOrCreateSyncState(tenantId)` â€” CrÃ©e/rÃ©cupÃ¨re l'Ã©tat de sync
   - `updateSyncState(tenantId, updates)` â€” Met Ã  jour l'Ã©tat
   - `fetchOrdersDelta(params)` â€” Appelle SP-API avec `LastUpdatedAfter`
   - `fetchOrderItemsWithRetry(params)` â€” RÃ©cupÃ¨re items avec pagination et retry
   - `upsertOrderWithItems(tenantId, order, items)` â€” Upsert idempotent
   - `runOrdersDeltaSync(tenantId)` â€” **Job principal de sync**
   - `getSyncStatus(tenantId)` â€” Retourne l'Ã©tat + counts
   - `syncMissingItems(tenantId)` â€” Sync items manquants

2. **`src/modules/marketplaces/amazon/amazonOrdersSync.routes.ts`** (nouveau)
   - `GET /api/v1/orders/sync/status` â€” Statut de sync
   - `POST /api/v1/orders/sync/run` â€” Trigger manuel delta sync
   - `POST /api/v1/orders/sync/items` â€” Sync items manquants

3. **`src/modules/marketplaces/marketplaces.routes.ts`** (modifiÃ©)
   - Import et enregistrement de `registerAmazonOrdersSyncRoutes`

### Infra (`keybuzz-infra`)

1. **`k8s/keybuzz-backend-dev/cronjob-orders-sync.yaml`** (nouveau)
   ```yaml
   schedule: "*/5 * * * *"  # Every 5 minutes
   concurrencyPolicy: Forbid
   ```

2. **`k8s/keybuzz-backend-dev/deployment.yaml`** (modifiÃ©)
   - Image: `ghcr.io/keybuzzio/keybuzz-backend:1.0.12-dev`

---

## Rate Limiting

- **500ms** entre chaque appel API
- **2s+ backoff** en cas de 429 (rate limited)
- **3 retries** avec backoff exponentiel
- **Pagination** complÃ¨te pour orders et items

---

## RÃ©sultats

### Avant sync

| MÃ©trique | Valeur |
|----------|--------|
| Orders | 94 |
| Items | 40 |
| Sync state | null |

### AprÃ¨s sync

| MÃ©trique | Valeur |
|----------|--------|
| Orders | **100** (+6) |
| Items | **95** (+55) |
| Sync state | âœ… Actif |

### Sync Status Endpoint

```bash
curl -sk -H "X-User-Email: ludovic@ecomlg.fr" -H "X-Tenant-Id: ecomlg-001" \
  https://backend-dev.keybuzz.io/api/v1/orders/sync/status
```

```json
{
  "tenantId": "ecomlg-001",
  "marketplace": "AMAZON",
  "syncState": {
    "lastUpdatedAfter": "2026-01-12T02:54:23.000Z",
    "lastPolledAt": "2026-01-12T12:18:48.923Z",
    "lastSuccessAt": "2026-01-12T12:18:54.521Z",
    "lastError": null
  },
  "counts": {
    "orders": 100,
    "items": 95
  }
}
```

---

## Validation UI

- **Tenant**: eComLG (ecomlg-001)
- **Total affichÃ©**: 100 commandes
- **En transit**: 82
- **Design**: âœ… InchangÃ©
- **Liens "Voir"**: âœ… Fonctionnels

---

## TLS Compliance (PH17.2)

- âœ… Aucun `NODE_TLS_REJECT_UNAUTHORIZED=0`
- âœ… Vault accessible via `vault.keybuzz.io` avec `hostAliases`

---

## Scheduling

| CronJob | Schedule | Description |
|---------|----------|-------------|
| `amazon-orders-sync` | `*/5 * * * *` | Delta sync toutes les 5 minutes |

```bash
kubectl -n keybuzz-backend-dev get cronjob
# NAME                 SCHEDULE      SUSPEND   ACTIVE
# amazon-orders-sync   */5 * * * *   False     0
```

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `dea861a` | `feat(orders): PH15 incremental sync + items + sync state` |
| keybuzz-infra | `444dbd2` | `feat(k8s): PH15 amazon orders sync CronJob + backend 1.0.12` |

---

## Prochaines Ã©tapes (optionnel)

1. Ajouter un endpoint `GET /api/v1/orders/sync/history` pour voir l'historique des runs
2. Alerting si `lastError` non null depuis > 30 min
3. Dashboard de monitoring sync (items count par order, etc.)
