# PH15-AMAZON-ORDERS-SYNC-SCALE-02 â€” Hardening global sync

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

Rendre le sync global "prod-ready" :
- Aucun tenant ne casse le run
- Dates invalides corrigÃ©es automatiquement
- Token manquant = SKIPPED (pas ERROR)
- Reason codes structurÃ©s

---

## ProblÃ¨mes rÃ©solus

### Avant

| Tenant | Status | Erreur |
|--------|--------|--------|
| kbz-002 | âŒ FAILED | "no refresh token" |
| kbz_test | âŒ FAILED | "Invalid time value" |
| ecomlg-001 | âœ… SUCCESS | - |

### AprÃ¨s (hardened)

| Tenant | Status | Reason Code | Action |
|--------|--------|-------------|--------|
| kbz-002 | â­ï¸ SKIPPED | TOKEN_MISSING | Ignore, continue |
| kbz_test | âœ… SUCCESS | SUCCESS | Date fixÃ©e, 7 items sync |
| ecomlg-001 | âœ… SUCCESS | SUCCESS | - |

---

## ImplÃ©mentation

### 1. Fonction `safeDate()`

```typescript
function safeDate(value: any, fallbackDaysAgo: number = 7): Date {
  if (!value) {
    const fallback = new Date();
    fallback.setDate(fallback.getDate() - fallbackDaysAgo);
    return fallback;
  }
  
  // Si valide ISO date
  if (typeof value === "string" && /^\d{4}-\d{2}-\d{2}/.test(value)) {
    const parsed = new Date(value);
    if (!isNaN(parsed.getTime())) return parsed;
  }
  
  // Fallback (UUID, garbage, etc.)
  console.warn(`[SafeDate] Invalid: "${value}", using fallback`);
  const fallback = new Date();
  fallback.setDate(fallback.getDate() - fallbackDaysAgo);
  return fallback;
}
```

### 2. VÃ©rification refresh_token AVANT sync

```typescript
async function hasValidCredentials(tenantId: string): Promise<boolean> {
  try {
    const creds = await getAmazonTenantCredentials(tenantId);
    return !!(creds && creds.refresh_token);
  } catch (error) {
    return false;
  }
}
```

### 3. Reason Codes

```typescript
export enum SyncReasonCode {
  SUCCESS = "SUCCESS",
  SKIPPED_LOCK_UNAVAILABLE = "LOCK_UNAVAILABLE",
  SKIPPED_NOT_CONNECTED = "NOT_CONNECTED",
  SKIPPED_TOKEN_MISSING = "TOKEN_MISSING",
  SKIPPED_INVALID_DATE_FIXED = "INVALID_DATE_FIXED",
  ERROR_RATE_LIMIT = "AMAZON_RATE_LIMIT",
  ERROR_UNKNOWN = "UNKNOWN_ERROR",
}
```

### 4. Correction automatique des cursor invalides

```typescript
async function fixInvalidSyncState(tenantId: string): Promise<void> {
  const state = await prisma.marketplaceSyncState.findFirst({...});
  
  if (state?.cursor && !/^\d{4}-\d{2}-\d{2}/.test(state.cursor)) {
    // Cursor invalide (UUID, etc.) -> corriger
    const safeCursor = safeDate(state.cursor, 7);
    await prisma.marketplaceSyncState.update({
      where: { id: state.id },
      data: { cursor: safeCursor.toISOString() },
    });
  }
}
```

---

## Flux d'Ã©ligibilitÃ©

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚              Tenants CONNECTED (MarketplaceConnection)     â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                           â”‚
                           â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                    Pour chaque tenant:                     â”‚
â”‚  1. hasValidCredentials(tenantId)?                        â”‚
â”‚     - Non â†’ SKIPPED (TOKEN_MISSING)                       â”‚
â”‚     - Oui â†’ continuer                                     â”‚
â”‚  2. fixInvalidSyncState(tenantId)                         â”‚
â”‚     - Corrige cursor si invalide                          â”‚
â”‚  3. â†’ Eligible                                            â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                           â”‚
                           â–¼
            Traitement des tenants Ã©ligibles
            (avec locks, batch, delays)
```

---

## Preuve E2E

### Global Sync Run

```bash
curl -sk -X POST \
  -H "X-User-Email: cron@system.keybuzz.io" \
  -H "X-Tenant-Id: ecomlg-001" \
  https://backend-dev.keybuzz.io/api/v1/orders/sync/run/global
```

```json
{
  "mode": "global",
  "success": true,
  "summary": {
    "total": 3,
    "success": 2,
    "skipped": 1,
    "failed": 0
  },
  "totalDuration": 8126,
  "results": [
    {
      "tenantId": "kbz-002",
      "status": "skipped",
      "reasonCode": "TOKEN_MISSING",
      "message": "No refresh token in Vault - reconnect Amazon required"
    },
    {
      "tenantId": "kbz_test",
      "status": "success",
      "reasonCode": "SUCCESS",
      "itemsProcessed": 7
    },
    {
      "tenantId": "ecomlg-001",
      "status": "success",
      "reasonCode": "SUCCESS"
    }
  ]
}
```

### Date corrigÃ©e pour kbz_test

**Avant** :
```json
{ "lastUpdatedAfter": "f45c563a-c72e-4025-abe9-96d8d0a86a69" }
```

**AprÃ¨s** :
```json
{ "lastUpdatedAfter": "2026-01-12T02:54:23.000Z" }
```

### Status avec hasRefreshToken

```json
{
  "totalTenants": 3,
  "tenantsWithToken": 2,
  "tenants": [
    { "tenantId": "kbz-002", "hasRefreshToken": false },
    { "tenantId": "kbz_test", "hasRefreshToken": true },
    { "tenantId": "ecomlg-001", "hasRefreshToken": true }
  ]
}
```

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `764d7b2` | feat(orders): PH15 hardened global sync |
| keybuzz-infra | `8d3195c` | feat(k8s): PH15 hardened CronJob + backend 1.0.14 |

---

## RÃ©sumÃ©

âœ… **Le sync global est maintenant "prod-ready"** :

| FonctionnalitÃ© | Status |
|----------------|--------|
| Safe dates (fallback) | âœ… |
| Token check avant sync | âœ… |
| Reason codes structurÃ©s | âœ… |
| Auto-fix cursor invalide | âœ… |
| Un tenant problÃ©matique n'affecte pas les autres | âœ… |
| Messages d'erreur clairs | âœ… |

Le systÃ¨me peut maintenant gÃ©rer des dizaines/centaines de tenants sans crash.
