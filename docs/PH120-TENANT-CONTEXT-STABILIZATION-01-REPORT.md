# PH120-TENANT-CONTEXT-STABILIZATION-01 — Rapport

**Date** : 23 mars 2026
**Phase** : PH120-TENANT-CONTEXT-STABILIZATION-01
**Type** : Stabilisation critique — tenant context global
**Environnements** : DEV + PROD

---

## 1. Probleme

Le systeme de tenant context dans KeyBuzz presentait plusieurs sources de verite concurrentes, creant des incoherences potentielles entre les pages, les guards et les connecteurs.

### Sources de tenant identifiees (avant PH120)

| Source | Mecanisme | Utilise par |
|---|---|---|
| `TenantProvider` (React context) | Appel API `/tenant-context/me` | La plupart des composants |
| `useTenantId.ts` orphelin | `session.tenantId` (NextAuth) — **JAMAIS peuple** | ai-dashboard, ai-journal |
| `getCurrentTenantId()` deprecated | `localStorage kb_prefs:v1` | ClientLayout, settings, AIModeSwitch, orders, playbooks, ai-journal/storage |
| `getSession()` deprecated | Retourne toujours `null` | ClientLayout (inutile) |
| Cookie `currentTenantId` (httpOnly) | Pose par `/api/tenant-context/switch` | AuthGuard, `/api/auth/me` |

### Risques identifies

1. **`useTenantId.ts` orphelin** : `session.tenantId` n'est jamais injecte dans le JWT NextAuth → retourne `''` → pages ai-dashboard et ai-journal n'envoient aucun tenantId aux appels API
2. **`ClientLayout.tsx`** : utilise `getSession()` (retourne null) et `getCurrentTenantId()` (localStorage) au lieu du `TenantProvider` deja present
3. **5 fichiers** utilisent `getCurrentTenantId()` deprecated qui lit localStorage au lieu du contexte React

---

## 2. Source de verite unique retenue

```
TenantProvider (React Context)
  └── Source: GET /api/tenant-context/me (backend, session-backed)
  └── Expose: useTenant(), useTenantId()
  └── Sync: cookie httpOnly currentTenantId
```

**Priorite** :
1. Backend (session via cookie httpOnly)
2. Fallback API `/tenant-context/me`
3. `localStorage` uniquement pour preferences UX (focus mode, theme) — JAMAIS comme source de tenant

---

## 3. Corrections appliquees

### 3.1 Orphan `useTenantId.ts` (CRITIQUE)

**Avant** : fichier independant lisant `session.tenantId` (jamais peuple)
**Apres** : re-export depuis `TenantProvider` — meme source de verite

```typescript
// PH120: Re-export from TenantProvider (single source of truth)
export { useTenantId } from './TenantProvider';
```

### 3.2 Imports corriges

| Fichier | Avant | Apres |
|---|---|---|
| `app/ai-dashboard/page.tsx` | `from '@/src/features/tenant/useTenantId'` | `from '@/src/features/tenant'` |
| `app/ai-journal/page.tsx` | `from '@/src/features/tenant/useTenantId'` | `from '@/src/features/tenant'` |

### 3.3 ClientLayout.tsx — suppression code deprecated

**Supprime** :
- Import `getSession`, `getCurrentTenantName`, `getCurrentTenantId`
- State `session`, `tenantName` (inutiles)
- `useEffect` appelant 3 fonctions deprecated

**Remplace par** :
- `const { currentRole, isAgent, userEmail, currentTenant, currentTenantId } = useTenant();`
- Focus mode recharge via `currentTenantId` du provider

### 3.4 Autres fichiers migres

| Fichier | Avant | Apres |
|---|---|---|
| `app/settings/page.tsx` | `getCurrentTenantId()` | `useTenantId()` |
| `src/features/ai-ui/AIModeSwitch.tsx` | `getCurrentTenantId()` | `useTenantId()` |
| `app/orders/[orderId]/page.tsx` | `getCurrentTenantId()` import | `useTenantId()` import |
| `src/services/playbooks.service.ts` | `getCurrentTenantId()` | `getLastTenant().id` (non-React, localStorage OK) |
| `src/features/ai-journal/storage.ts` | `getCurrentTenantId()` | `getLastTenant().id` (non-React, localStorage OK) |

### 3.5 Corrections pre-existantes sur le bastion

- `isAIAction` manquant dans `playbooks.service.ts` — ajoute
- Pages playbooks divergentes — alignees depuis le workspace local
- Types `BusinessProfile` divergents — alignes depuis le workspace local

---

## 4. Etat apres PH120

### Sources de tenant (apres)

| Source | Utilise par | Statut |
|---|---|---|
| `TenantProvider` → `useTenant()` / `useTenantId()` | Tous les composants React | **Source unique** |
| `getLastTenant().id` | Services localStorage (playbooks, journal) | OK (non-React) |
| Cookie `currentTenantId` | AuthGuard, middleware | OK (synced) |

### Fonctions deprecated restantes

Les fonctions `getCurrentTenantId()`, `getSession()`, etc. restent dans `session.ts` pour compatibilite mais **ne sont plus importees** dans aucun fichier `src/` ou `app/`.

---

## 5. Validations

### DEV

| Verification | Resultat |
|---|---|
| /login | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /ai-dashboard | 200 |
| /ai-journal | 200 |
| /settings | 200 |
| /playbooks | 200 |
| /billing | 200 |
| API /health | OK |
| Amazon status | `connected: true`, `CONNECTED` |
| Image deployee | `v3.5.79-ph120-tenant-context-dev` |

**PH120 DEV = OK**

### PROD

| Verification | Resultat |
|---|---|
| /login | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /ai-dashboard | 200 |
| /ai-journal | 200 |
| /settings | 200 |
| /playbooks | 200 |
| /billing | 200 |
| API /health | OK |
| Amazon status | `connected: true`, `CONNECTED` |
| Image deployee | `v3.5.79-ph120-tenant-context-prod` |

**PH120 PROD = OK**

---

## 6. Non-regressions

| Module | Statut |
|---|---|
| Login/Auth | OK |
| Dashboard | OK |
| Messages/Inbox | OK |
| Orders/Amazon | OK (connected, tracking) |
| AI Dashboard | OK |
| AI Journal | OK |
| Settings | OK |
| Playbooks | OK |
| Billing | OK |

---

## 7. Images deployees

| Env | Image |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-ph120-tenant-context-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-ph120-tenant-context-prod` |

## 8. Rollback

| Env | Image rollback |
|---|---|
| DEV | `v3.5.77-ph119-role-access-guard-dev` |
| PROD | `v3.5.77-ph119-role-access-guard-prod` |

---

## Verdict

**TENANT CONTEXT STABILIZED AND VALIDATED**
