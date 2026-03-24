# PH-ADMIN-87.12B — RUNTIME FETCH FAILURES & SIDEBAR ACTIVE STATE FIX

> Date : 2026-03-04
> Version : v2.7.1
> Commit : `3ce27c7eb081d90ccb16096f210412d297acb6ba`

---

## 1. Resume executif

### Pages cassees corrigees
- `/ops` — Ops Center
- `/queues` — Queues
- `/approvals` — Approbations
- `/followups` — Follow-ups

### Bug sidebar corrige
- "IA Tenant" et "AI Control Center" restaient tous deux actifs simultanement — resolu

### Environnements valides
- DEV : valide
- PROD : valide — navigation complete des 11 pages

---

## 2. Diagnostic initial

### Erreur runtime
Les 4 pages operations affichaient "Failed to fetch" au chargement.

### Cause racine identifiee
**Double cause :**

| Facteur | Detail |
|---|---|
| Build-arg incorrect | `NEXT_PUBLIC_API_URL=https://admin-api.keybuzz.io` utilise lors du build Docker precedent (v2.7.0) |
| DNS inexistant | `admin-api.keybuzz.io` ne resout vers aucune IP — hostname fantome |
| CSP bloquante | `connect-src` dans `next.config.mjs` n'autorisait que `api-dev.keybuzz.io` et `api.keybuzz.io` |

**Message console exact :**
```
Connecting to 'https://admin-api.keybuzz.io/ai/ops-dashboard' violates the following
Content Security Policy directive: "connect-src 'self' https://api-dev.keybuzz.io https://api.keybuzz.io"
```

Les endpoints reels (`/ai/ops-dashboard`, `/ai/human-approval-queue`, `/ai/followup-scheduler`) existent et repondent correctement sur `api.keybuzz.io` (200 avec payload valide).

### Bug sidebar
```typescript
// AVANT — startsWith trop large
const isActive = item.href === '/'
  ? pathname === '/'
  : pathname.startsWith(item.href);
// /ai-control.startsWith('/ai') → true → double actif
```

---

## 3. Correctifs appliques

### Fichier 1 : `src/components/layout/Sidebar.tsx`

**Logique active state :**
```typescript
// APRES — match exact ou sous-route uniquement
const isActive = item.href === '/'
  ? pathname === '/'
  : pathname === item.href || pathname.startsWith(item.href + '/');
```

**Version :** `v2.7.0` → `v2.7.1`

### Fichier 2 : `next.config.mjs`

**CSP connect-src :**
```
// AVANT
connect-src 'self' https://api-dev.keybuzz.io https://api.keybuzz.io

// APRES
connect-src 'self' https://api-dev.keybuzz.io https://api.keybuzz.io https://admin-api-dev.keybuzz.io https://admin-api.keybuzz.io
```

### Build-args corriges
```bash
# DEV
docker build --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io ...

# PROD
docker build --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io ...
```

---

## 4. Validation runtime PROD

| Page | URL | Endpoint API | Reponse | Rendu UI | Item actif |
|---|---|---|---|---|---|
| Dashboard | `/` | — | — | Stats globales | Dashboard seul |
| Ops Center | `/ops` | `api.keybuzz.io/ai/ops-dashboard` | 200 | 2 cas en attente, 0 follow-ups | Ops Center seul |
| Queues | `/queues` | `api.keybuzz.io/ai/human-approval-queue` | 200 | Empty state (0 cas) | Queues seul |
| Approbations | `/approvals` | `api.keybuzz.io/ai/ops/pending-approvals` | 200 | 2 en attente, 2 haute priorite | Approbations seul |
| Follow-ups | `/followups` | `api.keybuzz.io/ai/followup-scheduler` | 200 | Empty state (0 follow-ups) | Follow-ups seul |
| IA Tenant | `/ai` | interne `/api/admin/tenants/[id]/ai` | 200 | Selecteur tenant | IA Tenant seul |
| AI Control Center | `/ai-control` | `api.keybuzz.io/ai/governance` | 200 | NOMINAL, ASSISTED ONLY | AI Control Center seul |
| Activation | `/ai-control/activation` | `api.keybuzz.io/ai/controlled-activation` | 200 | Matrice 0 actions | Activation seul |
| Policies | `/ai-control/policies` | `api.keybuzz.io/ai/controlled-activation/policies` | 200 | 0 policies | Policies seul |
| Monitoring | `/ai-control/monitoring` | `api.keybuzz.io/ai/health-monitoring` | 200 | Sante systeme | Monitoring seul |
| Debug IA | `/ai-control/debug` | multi-endpoints | 200 | 15 endpoints charges | Debug IA seul |

**Aucun "Failed to fetch" sur aucune page.**
**Un seul item actif par route.**

---

## 5. Navigation sidebar — matrice route → item actif

| Route | Item actif | IA Tenant actif ? | AI Control actif ? |
|---|---|---|---|
| `/ai` | IA Tenant | OUI | NON |
| `/ai-control` | AI Control Center | NON | OUI |
| `/ai-control/activation` | Activation | NON | NON |
| `/ai-control/policies` | Policies | NON | NON |
| `/ai-control/monitoring` | Monitoring | NON | NON |
| `/ai-control/debug` | Debug IA | NON | NON |
| `/ops` | Ops Center | NON | NON |
| `/queues` | Queues | NON | NON |
| `/approvals` | Approbations | NON | NON |
| `/followups` | Follow-ups | NON | NON |

---

## 6. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA source | `3ce27c7eb081d90ccb16096f210412d297acb6ba` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-dev` |
| Digest DEV | `sha256:6973a5078e1cd38cc964b4958a000e8bff4bdd995c1dc9225c813703494f2ea7` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.1-ph-admin-87-12b-prod` |
| Digest PROD | `sha256:d61177be4877144705eba19e2da8c30a7c69a25dca01e3b42adfff0b98f14806` |
| Version runtime | v2.7.1 |
| Build-arg DEV | `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io` |
| Build-arg PROD | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

| Env | Image stable precedente |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.7.0-ph-admin-87-12a-prod` |

---

## 8. Dettes restantes

| ID | Description | Impact |
|---|---|---|
| D1 | `next-auth` CLIENT_FETCH_ERROR background (session refresh) | Debug-level, non-bloquant |
| D2 | `admin-api.keybuzz.io` hostname fantome dans CSP (ajoute par securite mais ne resout pas) | Nettoyage DNS a planifier |
| D3 | Dashboard stats (Queues actives, Approbations, Follow-ups) affichent "—" au lieu de 0 | Feed dashboard non connecte aux endpoints ops |
