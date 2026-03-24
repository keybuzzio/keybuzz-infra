# PH-DEV-SLOWDOWN-DIFF-AUDIT-01 — Rapport

> Date : 2026-03-24
> Phase : Audit differentiel lenteurs DEV
> Scope : v3.5.77 (rapide) vs v3.5.82 (lent)
> Verdict : **DEV SLOWDOWN ROOT CAUSE IDENTIFIED — READY FOR MINIMAL FIX**

---

## 1. Scope compare

| Element | Baseline (rapide) | Rebuild (lent) |
|---|---|---|
| Image | `v3.5.77-ph119-role-access-guard-dev` | `v3.5.82-source-of-truth-fix-dev` |
| Commit Git | Bastion dirty (pre-PH120) | `3edc104` (post-PH120 sync) |
| Diff | — | 24 fichiers, +5265 / -4716 lignes |

**Point critique** : Le commit `3edc104` (sync source of truth) a inclus des changements PH120 qui etaient sur le bastion APRES le build v3.5.77. Le build v3.5.77 n'a JAMAIS contenu ces changements PH120.

---

## 2. Root cause principale

### L'architecture de chargement a ete modifiee de SYNCHRONE a ASYNCHRONE

**v3.5.77 (rapide) — chaine de chargement :**

```
AuthGuard (fetch /auth/me, rapide)
  → LayoutContent lit localStorage SYNCHRONE
    → getCurrentTenantId() = instant
    → getCurrentTenantName() = instant
    → getSession() = instant
  → Page affichee immediatement avec donnees locales
```

**v3.5.82 (lent) — chaine de chargement :**

```
AuthGuard (fetch /auth/me, timeout 10s, max loading 12s)
  → TenantProvider (fetch /api/tenant-context/me, ASYNC)
    → Attente reponse API...
    → EntitlementGuard (fetch /api/billing, timeout 8s)
      → Attente reponse API...
      → LayoutContent peut enfin s'afficher
        → useTenant() retourne les donnees
        → Page affichee
```

**Impact** : 3 couches d'attente API sequentielles au lieu d'une seule + localStorage.

---

## 3. Fichiers critiques et changements exacts

### 3.1 — `src/features/tenant/useTenantId.ts`

| v3.5.77 | v3.5.82 |
|---|---|
| `useSession()` de NextAuth | `useTenantId()` re-exporte de TenantProvider |
| Session deja en cache client | Attente API `/api/tenant-context/me` |
| **SYNCHRONE** (donnee en memoire) | **ASYNCHRONE** (fetch reseau) |

**Impact** : TOUTES les pages utilisant `useTenantId()` (dashboard, settings, orders, ai-dashboard, ai-journal, playbooks) attendent desormais une reponse API au lieu de lire un cache local.

### 3.2 — `src/components/layout/ClientLayout.tsx`

| v3.5.77 | v3.5.82 |
|---|---|
| `getSession()` synchrone | `useTenant()` async |
| `getCurrentTenantId()` synchrone | `currentTenantId` via TenantProvider |
| `getCurrentTenantName()` synchrone | `currentTenant` via TenantProvider |
| Entitlement inline dans LayoutContent | Nouveau `EntitlementGuard` component |
| Gate : `tenantLoading \|\| entitlementLoading` | Gate dans EntitlementGuard (8s timeout) |
| Theme default : `"light"` | Theme default : `"dark"` |

**Impact** :
- Le layout attend TenantProvider + EntitlementGuard avant d'afficher quoi que ce soit
- Le theme passe de light a dark (flash visuel)

### 3.3 — `src/components/auth/AuthGuard.tsx`

| v3.5.77 | v3.5.82 |
|---|---|
| Pas de timeout | `FETCH_TIMEOUT_MS = 10_000` (10s) |
| Pas de max loading | `MAX_LOADING_MS = 12_000` (12s) |
| Logout au 1er echec keep-alive | Tolere 3 echecs consecutifs |
| Pas d'AbortController | AbortController sur chaque fetch |
| Status: loading/auth/unauth | Status: + `error` |

**Impact** :
- Si l'API est lente, l'utilisateur voit "Verification..." pendant jusqu'a 12 secondes
- Apres 12s, un bouton "Reessayer" apparait au lieu d'un redirect
- La tolerance aux echecs keep-alive masque des problemes de connectivite

### 3.4 — `middleware.ts`

| v3.5.77 | v3.5.82 |
|---|---|
| Pas de token → `/login` | Pas de token → `/auth/signin` |
| Cookie `kb_payment_gate` verifie | Cookie supprime (billing gate client-side) |
| Routes hardcodees | Import depuis `routeAccessGuard.ts` |

**Impact** :
- Redirect vers `/auth/signin` au lieu de `/login` = hop supplementaire possible
- Billing gate enleve du middleware (server-side) et deplace vers EntitlementGuard (client-side) = le navigateur doit charger l'app et fetch avant de savoir si l'utilisateur est bloque

### 3.5 — `src/lib/routeAccessGuard.ts` (NOUVEAU)

Fichier de 130 lignes centralisant les listes de routes. Pas d'impact performance direct. Bon refactoring (PH119).

### 3.6 — Pages modifiees (9 fichiers)

Tous remplaces de `getCurrentTenantId()` (sync) par `useTenantId()` (async TenantProvider) :
- `app/ai-dashboard/page.tsx` — 703 lignes
- `app/ai-journal/page.tsx` — 791 lignes
- `app/orders/page.tsx` — 1784 lignes
- `app/orders/[orderId]/page.tsx` — 954 lignes
- `app/settings/page.tsx` — 506 lignes
- `app/playbooks/**` — 4 fichiers

**Impact** : Chaque page attend la resolution de TenantProvider avant de pouvoir faire ses propres appels API metier. Double attente.

---

## 4. Comparaison runtime

| Route | v3.5.77 (rapide) | v3.5.82 (lent) | Cause |
|---|---|---|---|
| /dashboard | AuthGuard → sync → affichage | AuthGuard(12s) → Tenant(API) → Entitlement(8s) → affichage | 3 gates async |
| /inbox | AuthGuard → sync → 267 convos | AuthGuard(12s) → Tenant(API) → Entitlement(8s) → 267 convos | 3 gates async |
| /orders | AuthGuard → sync → 11779 | AuthGuard(12s) → Tenant(API) → Entitlement(8s) → 11779 | 3 gates async |
| /ai-dashboard | AuthGuard → sync → page | AuthGuard → Tenant → Entitlement → crash `safeAutomatic` | crash + 3 gates |
| /settings | AuthGuard → sync → profil | AuthGuard → Tenant → Entitlement → profil | 3 gates async |

---

## 5. Correlation des symptomes

| Symptome | Cause exacte |
|---|---|
| **Lenteur generale** | 3 couches async sequentielles (AuthGuard 12s + TenantProvider API + EntitlementGuard 8s) au lieu de 1 (AuthGuard) + sync |
| **Chargements incomplets** | EntitlementGuard affiche "Chargement..." pendant que les API repondent ; si timeout → page bloquee |
| **Flash visuel** | Theme par defaut passe de `"light"` a `"dark"` |
| **ai-dashboard crash** | `safeAutomatic` undefined dans response API — NON lie aux lenteurs, bug de donnees pre-existant |

**La cause est UNIQUE** : le remplacement des lectures synchrones (localStorage/session cache) par des fetches API asynchrones en cascade (PH120 tenant context).

---

## 6. Decomposition du diff en categories

| Categorie | Fichiers | Impact perf | A garder |
|---|---|---|---|
| **PH120 — Tenant async** | useTenantId.ts, ClientLayout.tsx, 9 pages | **CRITIQUE** — cause des lenteurs | NON — revenir au sync |
| **PH119 — Route guards** | routeAccessGuard.ts, middleware.ts | AUCUN | OUI — bon refactoring |
| **PH-AUTH-SESSION — Resilience** | AuthGuard.tsx, AuthProvider.tsx | MINEUR — timeouts trop longs | OUI mais reduire timeouts |
| **PH119 — Entitlement guard** | ClientLayout.tsx (EntitlementGuard) | MOYEN — ajoute une gate async | A SIMPLIFIER |
| **Settings/Playbooks types** | settings/*.ts, playbooks/* | AUCUN | OUI — alignement types |

---

## 7. Recommandation de correction minimale

### Fix en 3 etapes, par ordre de priorite

#### Etape A — Revenir a useTenantId synchrone (CRITIQUE)

**Fichier** : `src/features/tenant/useTenantId.ts`

Revenir a la version v3.5.77 qui utilise `useSession()` :
```typescript
export function useTenantId(): string {
  const { data: session, status } = useSession();
  if (status === 'authenticated' && session?.tenantId) return session.tenantId;
  return '';
}
```

**Risque** : Aucun — c'est l'exact code de la baseline saine.

#### Etape B — Revenir a ClientLayout sync (CRITIQUE)

**Fichier** : `src/components/layout/ClientLayout.tsx`

Revenir aux lectures synchrones `getSession()`, `getCurrentTenantId()`, `getCurrentTenantName()`.

Supprimer `EntitlementGuard` comme composant wrapper — remettre le check inline.

Remettre le theme par defaut a `"light"`.

Garder : `isShellBypassRoute()` de PH119 (bon refactoring).

**Risque** : Faible — restaure exactement le comportement sain.

#### Etape C — Reduire les timeouts AuthGuard (MINEUR)

**Fichier** : `src/components/auth/AuthGuard.tsx`

Reduire `MAX_LOADING_MS` de 12s a 5s.
Reduire `FETCH_TIMEOUT_MS` de 10s a 5s.
Garder les améliorations (retry, error state, AbortController).

**Risque** : Aucun — ameliore la reactivite.

### Ce qui doit etre conserve tel quel

- `src/lib/routeAccessGuard.ts` (PH119) — bon refactoring
- `middleware.ts` — import depuis routeAccessGuard (mais corriger `/auth/signin` → `/login`)
- `settings/*.ts` — alignement types
- `playbooks/*.tsx` — alignement types

### Ordre de reintroduction conseille

1. Appliquer Etapes A + B + C (corrections sync + timeouts)
2. Build via `build-from-git.sh`
3. Deploy via GitOps DEV
4. Valider fluidite DEV
5. Si OK → PROD

---

## 8. Verdict

### DEV SLOWDOWN ROOT CAUSE IDENTIFIED — READY FOR MINIMAL FIX

**Cause unique** : le commit `3edc104` a inclus les changements PH120 (tenant context async) qui n'etaient PAS dans la baseline v3.5.77. Ces changements remplacent des lectures synchrones (localStorage) par des fetches API en cascade, causant 3 couches d'attente sequentielles sur chaque navigation.

**Le PH120 (tenant context) doit etre retire du code pour retrouver la fluidite, tout en gardant PH119 (route guards) et les corrections AuthGuard.**
