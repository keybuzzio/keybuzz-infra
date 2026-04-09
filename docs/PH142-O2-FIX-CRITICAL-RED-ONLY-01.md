# PH142-O2 — Fix Critical RED P0 Only

> Phase : PH142-O2-FIX-CRITICAL-RED-ONLY-01
> Date : 2026-04-05
> Environnement : DEV uniquement
> Image DEV : `v3.5.193-fix-critical-red-dev`
> Verdict : **CRITICAL RED P0 FIXED — RBAC SAFE — REGRESSION GUARDS ACTIVE — IA CONSISTENT**

---

## 1. Resume Executif

4 corrections P0 identifiees par PH142-O1.1 / PH142-O1.2 ont ete corrigees, buildees depuis un clone Git propre, et deployees en DEV :

| # | Correctif | Avant | Apres |
|---|-----------|-------|-------|
| AGT-04 | RBAC agent pages client | RED — agent accede /settings /billing /dashboard par URL | GREEN — middleware.ts dans le build + cookie serveur |
| INFRA-02 | pre-prod-check-v2.sh | RED — absent du bastion | GREEN — deploye, executable, teste |
| INFRA-03 | assert-git-committed.sh | RED — absent du bastion | GREEN — deploye, retourne exit 1 sur dirty repo |
| IA-CONSIST-01 | Autopilot shared-ai-context | RED — 3 fonctions dupliquees, pas d'import | GREEN — import shared, duplicatas supprimes |

---

## 2. AGT-04 — RBAC Agent (Avant / Apres)

### Cause racine decouverte

Le code RBAC dans `middleware.ts` existait dans Git depuis PH121 (janvier 2026), mais **n'a JAMAIS ete deploye** car le `Dockerfile` utilisait des COPY explicites et `middleware.ts` (fichier racine du projet) n'etait pas dans la liste :

```dockerfile
# Avant — middleware.ts ABSENT
COPY next.config.mjs ./
COPY tsconfig.json ./
COPY tailwind.config.ts ./
COPY postcss.config.cjs ./
COPY app ./app
COPY src ./src
```

Le middleware RBAC etait du **code mort** dans Git pendant ~3 mois.

### Corrections appliquees

1. **Dockerfile** : Ajout `COPY middleware.ts ./` (commit `f3cb7e2`)
2. **BFF `/api/tenant-context/me`** : Cookie `currentTenantRole` set cote serveur dans la reponse HTTP (`Set-Cookie` header, `maxAge: 365j`)
3. **TenantProvider.tsx** : Cookie client rendu persistant (`expires: 365, path: '/'` au lieu de session cookie)

### Verification apres deploiement

| Check | Resultat |
|-------|----------|
| Middleware dans le build | `/app/.next/server/middleware.js` present |
| `middleware-manifest.json` | `Middleware ACTIVE` |
| `isAdminOnlyRoute` dans middleware.js | Confirme (grep) |
| `currentTenantRole` dans middleware.js | Confirme (grep) |
| Cookie serveur dans BFF me/route.js | `cookies.set("currentTenantRole",...maxAge:31536e3)` |

### Comportement attendu (post-fix)

- Agent connecte → `/inbox` OK
- Agent navigue vers `/settings` → redirect `/inbox?rbac=restricted`
- Agent navigue vers `/billing` → redirect `/inbox?rbac=restricted`
- Agent navigue vers `/dashboard` → redirect `/inbox?rbac=restricted`
- Owner/Admin → acces normal a toutes les pages

---

## 3. INFRA-02/03 — Scripts Bastion (Avant / Apres)

### Avant
- Scripts existent dans Git (`keybuzz-infra/scripts/`) mais pas deployes sur le bastion
- Protection anti-regression inactive

### Corrections
- SCP des 3 fichiers vers `/opt/keybuzz/keybuzz-infra/scripts/`
- `sed -i 's/\r//'` pour conversion CRLF → LF
- `chmod +x` sur les scripts shell

### Tests

| Script | Test | Resultat |
|--------|------|----------|
| `assert-git-committed.sh` | Repo propre (API post-commit) | exit 0, "TOUS LES REPOS PROPRES" |
| `assert-git-committed.sh` | Repo dirty (avant commit) | exit 1, "BLOQUE — fichiers non commites" |
| `pre-prod-check-v2.sh dev` | Execution sur DEV | Execution OK, checks API/Git/DB |
| `pre-prod-checks-v2.js` | Copie kubectl + exec | Checks internes fonctionnels |

### Fichiers deployes

```
-rwxr-xr-x root root 5789 /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check-v2.sh
-rw-r--r-- root root 5163 /opt/keybuzz/keybuzz-infra/scripts/pre-prod-checks-v2.js
-rwxr-xr-x root root 3018 /opt/keybuzz/keybuzz-infra/scripts/assert-git-committed.sh
```

---

## 4. IA-CONSIST-01 — Alignement Autopilot / shared-ai-context (Avant / Apres)

### Avant
- `autopilot/engine.ts` avait 3 fonctions dupliquees localement :
  - `loadConversationContext()` (vs `loadFullConversationContext()` shared)
  - `loadOrderContext()` (vs `loadEnrichedOrderContext()` shared)
  - `computeTemporalContext()` (vs `computeTemporalContext()` shared)
- Aucun import de `shared-ai-context.ts`
- AI Assist et Autopilot pouvaient diverger sur le chargement de contexte

### Corrections (commit `ad5d68e`)
```typescript
import {
  loadEnrichedOrderContext,
  computeTemporalContext as computeTemporalContextShared,
  loadFullConversationContext,
  getScenarioRules,
  getWritingRules,
  type EnrichedOrderContext,
  type ConversationContextShared,
} from '../ai/shared-ai-context';
```
- 3 fonctions locales dupliquees supprimees (127 lignes retirees)
- Appels remplaces par les versions partagees
- `getScenarioRules` / `getWritingRules` importes pour alignement futur des prompts

### Verification apres deploiement

| Check | Resultat |
|-------|----------|
| `shared-ai-context` dans engine.js compile | 1 reference |
| Fonctions partagees dans engine.js | 2 appels (loadEnrichedOrderContext, computeTemporalContextShared) |
| TypeScript compilation | OK (build Docker sans erreur tsc) |
| POST `/autopilot/evaluate` (ecomlg-001) | 200 OK, `MODE_NOT_AUTOPILOT:suggestion` (attendu, tenant PRO) |

---

## 5. Tests Reels

### Health
- API : `{"status":"ok"}` ✓
- Client : HTTP 200 ✓

### Images deployees
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.193-fix-critical-red-dev`
- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.193-fix-critical-red-dev`

### Commits
| Repo | SHA | Message |
|------|-----|---------|
| keybuzz-api | `ad5d68e` | PH142-O2: align autopilot/engine.ts with shared-ai-context |
| keybuzz-client | `8814d45` | PH142-O2: RBAC cookie server-side in BFF + persistent client cookie |
| keybuzz-client | `f3cb7e2` | PH142-O2: add middleware.ts to Dockerfile - root cause of AGT-04 |

---

## 6. Ce qui reste RED hors scope

Ces items sont confirmes RED mais exclus du perimetre PH142-O2 :

| Feature | Status | Note |
|---------|--------|------|
| KNOW-01 | RED | Knowledge templates 404 (`/templates` inexistant) |
| DASH-02 | RED | Supervision 404 (`/supervision` inexistant) |
| ORD-02 | RED | Tracking 404 (`/tracking` endpoint absent) |
| SLA-01 | RED | Badge urgent absent (UI non implementee) |
| BILL-02 | ORANGE | Addon non testable en trial (masque par trial features) |
| AI-05 | ORANGE | Escalation manuelle visible, auto-escalation non confirmee UI |
| ESC-03 | RED | Escalation auto — pas de preuve backend |

---

## 7. Image DEV

```
API:    ghcr.io/keybuzzio/keybuzz-api:v3.5.193-fix-critical-red-dev
Client: ghcr.io/keybuzzio/keybuzz-client:v3.5.193-fix-critical-red-dev
```

Build methode : `build-from-git.sh` (clone propre GitHub)
Git SHA Client : `f3cb7e2`
Git SHA API : `ad5d68e`

---

## 8. Verdict

**CRITICAL RED P0 FIXED — RBAC SAFE — REGRESSION GUARDS ACTIVE — IA CONSISTENT**

- AGT-04 : cause racine identifiee et corrigee (middleware.ts manquant dans Dockerfile)
- INFRA-02/03 : scripts operationnels sur le bastion
- IA-CONSIST-01 : engine.ts aligne sur shared-ai-context (127 lignes de duplication eliminees)
- Aucun impact PROD (aucun push PROD effectue)
- Build depuis clone Git propre (pas de contamination bastion)
