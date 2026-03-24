# PH120-MINIMAL-FIX-REINTRO-05 — Rapport

> Date : 2026-03-24
> Phase : PH120-MINIMAL-FIX-REINTRO-05
> Type : Fix minimal cible — suppression lenteur PH120 sans perdre PH119

---

## 1. Rappel Root Cause (issue de PH-DEV-SLOWDOWN-DIFF-AUDIT-01)

Le commit `3edc104` (PH-SOURCE-OF-TRUTH-FIX-02) avait inclus les changements PH120 qui remplacaient des lectures synchrones (session/localStorage) par des fetches API asynchrones en cascade :

| Couche | Mecanisme lent | Timeout |
|---|---|---|
| AuthGuard | Fetch `/api/auth/me` + loading max | 12s |
| TenantProvider | Fetch `/api/tenant-context/me` | API dependent |
| EntitlementGuard | Fetch entitlement + loading max | 8s |

**Consequence** : chaque chargement de page devait attendre 3 fetches sequentiels avant de rendre quoi que ce soit. Total potentiel : 20+ secondes de loading.

La baseline `v3.5.77-ph119-role-access-guard` etait rapide car tout etait synchrone (session NextAuth cache + localStorage).

---

## 2. Fichiers modifies (4 fichiers)

### A. `src/features/tenant/useTenantId.ts` — REVERTI

| Avant (PH120 lent) | Apres (fix minimal) |
|---|---|
| Re-export depuis `TenantProvider` (async API fetch) | `useSession()` synchrone (NextAuth cache) |

### B. `src/components/layout/ClientLayout.tsx` — REVERTI

| Element | Avant (PH120 lent) | Apres (fix minimal) |
|---|---|---|
| Tenant reads | `useTenant()` async | `getSession()` + `getCurrentTenantId()` sync |
| Theme defaut | `"dark"` | `"light"` |
| EntitlementGuard | Wrapper JSX separee (8s timeout) | Inline dans LayoutContent (sync) |
| Paywall logic | Deplacee dans EntitlementGuard | Inline avec useEffect + cookie kb_payment_gate |
| LOCK_EXEMPT_ROUTES | Supprime | Restaure |
| Sidebar isItemLocked | Supprime | Restaure (liens desactives si locked) |
| useRouter | Supprime | Restaure (pour redirect /locked) |

### C. `src/components/auth/AuthGuard.tsx` — REDUIT

| Parametre | Avant | Apres |
|---|---|---|
| `FETCH_TIMEOUT_MS` | 10 000 ms | **5 000 ms** |
| `MAX_LOADING_MS` | 12 000 ms | **5 000 ms** |
| AbortController | Conserve | Conserve |
| Retry / error state | Conserve | Conserve |
| Keep-alive 3 failures | Conserve | Conserve |

### D. `middleware.ts` — CORRIGE

| Element | Avant (PH120) | Apres (fix minimal) |
|---|---|---|
| Redirect non-auth | `/auth/signin` | `/login` |
| Cookie `kb_payment_gate` | Supprime | Restaure |
| Imports `routeAccessGuard` | Conserve | Conserve |

---

## 3. Ce qui est conserve (PH119)

| Element | Fichier | Status |
|---|---|---|
| `routeAccessGuard.ts` | `src/lib/routeAccessGuard.ts` | **GARDE** — centralisation routes |
| `TenantProvider.tsx` | `src/features/tenant/TenantProvider.tsx` | **GARDE** — RBAC context |
| `useAuth()` hook | `src/components/auth/AuthGuard.tsx` | **GARDE** — AbortController + retry |
| Imports middleware | `middleware.ts` | **GARDE** — `isPublicRoute`, `isAdminOnlyRoute`, `API_PUBLIC_PREFIXES` |
| Settings/types alignes | Multiples fichiers | **GARDES** — aucun revert |
| Playbooks alignes | Multiples fichiers | **GARDES** — aucun revert |
| Amazon fixes | `orders/routes.ts`, `compat/routes.ts` | **NON TOUCHES** |

---

## 4. Validation DEV

| Test | Resultat |
|---|---|
| Pages HTTP (13/13) | **200** — login, register, dashboard, inbox, orders, billing, settings, ai-dashboard, suppliers, channels, knowledge, playbooks, ai-journal |
| API health | `ok` |
| Amazon status | `connected=True`, `status=CONNECTED` |
| Menu complet | 12 items visibles (Demarrage → Facturation) |
| Focus mode | OFF (desactive par defaut) |
| Theme | Light (bouton "Mode sombre" visible) |
| Bouton "Synchroniser Amazon" | Visible |
| Bouton "Exporter CSV" | Visible |
| Tracking UPS | Visible dans liste commandes (`1Z4971486338334585`) |
| Dashboard stats | 267 conversations, 188 ouvertes, 8 en attente |
| Inbox | 629 refs, 336 interactifs — charge complet |
| Billing | Plan Pro, KBActions, 1/3 canaux |
| Loading infini | Aucun |
| Note | `/ai-dashboard` : erreur API pre-existante `safeAutomatic` (non liee a PH120) |

### Verdicts DEV

- **PH120 MINIMAL FIX DEV PERFORMANCE** = **OK**
- **PH120 MINIMAL FIX DEV UX** = **OK**
- **PH120 MINIMAL FIX DEV FUNCTIONAL** = **OK**

---

## 5. Validation PROD

| Test | Resultat |
|---|---|
| Pages HTTP (13/13) | **200** |
| API health | `ok` |
| Amazon status | `connected=True`, `status=CONNECTED` |
| Register | 3 plans affiches (Starter 97EUR, Pro 297EUR, Autopilot 497EUR) |
| Login | Page chargee, OTP + OAuth Google/Microsoft |
| Dashboard (non auth) | Redirect correcte vers `/login` |
| Redirect | `/login` (corrige depuis `/auth/signin`) |
| Loading infini | Aucun |

### Verdicts PROD

- **PH120 MINIMAL FIX PROD PERFORMANCE** = **OK**
- **PH120 MINIMAL FIX PROD UX** = **OK**
- **PH120 MINIMAL FIX PROD FUNCTIONAL** = **OK**

---

## 6. Images deployees

| Env | Image | SHA256 |
|---|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.83-ph120-minimal-fix-dev` | `sha256:6161a7df9c1e76f84bebd019a96e66711ac1d82cd859bc9b2153863b5570cdf2` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.83-ph120-minimal-fix-prod` | `sha256:fdd8b05dbcc0a4a5dbe1d852266f29f8596a52b1fa46024f0718991a5e07a479` |

Git commit source : `d379f52` (branche `fix/signup-redirect-v2`)

---

## 7. Rollback

| Env | Image rollback |
|---|---|
| DEV | `v3.5.77-ph119-role-access-guard-dev` |
| PROD | `v3.5.77-ph119-role-access-guard-prod` |

Rollback via manifests GitOps uniquement.

---

## 8. Non-regressions

| Element | Status |
|---|---|
| Menu complet | OK |
| Focus mode | OFF par defaut |
| Theme | Light par defaut |
| Amazon connecteur | CONNECTED |
| Boutons sync/export | Visibles |
| Tracking | Visible |
| Onboarding/register | 3 plans affiches |
| Login OTP/OAuth | Fonctionnel |
| Billing/paywall | Inline, cookie kb_payment_gate restaure |
| RBAC sidebar | isItemLocked restaure |
| Pipeline safe | build-from-git.sh utilise |
| GitOps | Manifests commites et pushes |

---

## 9. Verdict Final

## PH120 MINIMAL FIX REINTRODUCED AND VALIDATED

La root cause de la lenteur (lectures async en cascade) a ete supprimee. Les bons apports PH119 (routeAccessGuard, TenantProvider RBAC, AuthGuard resilient) sont conserves. DEV et PROD sont fluides et fonctionnels.
