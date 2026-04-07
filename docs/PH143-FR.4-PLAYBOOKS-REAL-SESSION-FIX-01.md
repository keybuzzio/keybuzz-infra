# PH143-FR.4 — PLAYBOOKS REAL SESSION FIX

**Date** : 7 avril 2026
**Phase** : PH143-FR.4-PLAYBOOKS-REAL-SESSION-FIX-01
**Auteur** : Agent Cursor (CE)

---

## 1. Probleme reproduit

### Symptome
La page Playbooks IA affiche `Total: 0` et "Aucun playbook trouve" pour TOUS les utilisateurs, malgre la presence de 15 starters dans la base de donnees (`ai_rules`).

### Utilisateur test
- Email: `switaa26@gmail.com`
- Tenant: `switaa-sasu-mnc1x4eq` (SWITAA SASU, plan AUTOPILOT)
- 15 playbooks dans `ai_rules` (8 actifs, 7 desactives)

### Etat avant fix
- Image deployee: `v3.5.218-ph143-fr-real-fix-dev` (branch `rebuild/ph143-client`)
- Page playbooks: **VIDE** (Total = 0)

---

## 2. Cause racine finale

### Chaine de causalite

1. **Image deployee = ancien code localStorage** (PH143-FR.3)
   - Le build `v3.5.218` etait fait depuis la branche `rebuild/ph143-client`
   - Cette branche n'avait PAS le hook `usePlaybooks` (migration API backend PH-PLAYBOOKS-BACKEND-MIGRATION-02)
   - Elle utilisait `getPlaybooks()` depuis `playbooks.service.ts` (localStorage)

2. **`useTenantId()` retourne TOUJOURS `""`**
   - Le code FR.3 utilisait `useTenantId()` de `src/features/tenant/useTenantId.ts`
   - Ce hook lit `session.tenantId` via `useSession()` de NextAuth
   - **MAIS** `auth-options.ts` ne met JAMAIS `tenantId` dans la session JWT
   - Commentaire explicite ligne 90: `"tenantId is managed client-side via currentTenantId cookie"`
   - Resultat: `session.tenantId` est TOUJOURS `undefined`

3. **Guard bloque tout**
   - `if (tenantId)` → `if ("")` → `false`
   - `getPlaybooks()` n'est JAMAIS appele
   - L'etat React reste `[]` → page vide

### Pourquoi les phases precedentes n'ont pas fonctionne

| Phase | Ce qui a ete fait | Pourquoi ca n'a pas marche |
|---|---|---|
| PH143-FR.2 | Ajout `useTenantId()` guard | `useTenantId()` retourne `""` car session.tenantId n'est jamais set |
| PH143-FR.3 | Ajout `overrideTenantId` a `getPlaybooks()` | Le code passait `tenantId` de `useTenantId()` qui vaut `""` |

### La vraie solution

Le code local (`main`) avait deja la bonne architecture:
- Hook `usePlaybooks()` depuis `@/src/hooks/usePlaybooks.ts`
- Utilise `useTenant()` de `TenantProvider` (pas `useTenantId()` de NextAuth)
- `TenantProvider` obtient le tenant depuis l'API `/tenant-context/me`
- Appel API: `GET /api/playbooks?tenantId=${currentTenantId}`
- BFF proxy vers le backend: `GET ${API_URL}/playbooks?tenantId=xxx`
- Backend lit depuis `ai_rules` table

**Mais ce code n'etait PAS dans la branche deployee.**

---

## 3. Correction appliquee

### Action
Merge de `origin/main` dans `rebuild/ph143-client` pour obtenir:
- Le hook `usePlaybooks` (API backend) depuis `main`
- La francisation PH143-FR depuis `rebuild/ph143-client`

### Conflits resolus
| Fichier | Resolution |
|---|---|
| `app/playbooks/page.tsx` | → `origin/main` (usePlaybooks hook) |
| `src/features/dashboard/components/SupervisionPanel.tsx` | → `rebuild/ph143-client` (type `data: SupervisionApiData`) |
| `app/inbox/InboxTripane.tsx` | → `origin/main` |
| `app/settings/components/SignatureTab.tsx` | → `origin/main` |
| `src/features/ai-ui/AutopilotSection.tsx` | → `origin/main` |
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | → `origin/main` |

### Verification post-merge
- `usePlaybooks.ts` existe ✓
- `page.tsx` importe `usePlaybooks` ✓
- `LearningControlSection.tsx` francisation = 8 matches ✓
- `AutopilotSection.tsx` francisation = 5 matches ✓

---

## 4. Verification deployee

### Build
- **Image**: `ghcr.io/keybuzzio/keybuzz-client:v3.5.219-ph143-playbooks-real-fix-dev`
- **Source**: branch `rebuild/ph143-client` (merge de `origin/main`)
- **Build args**: `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- **Taille**: 279MB

### Verification structurelle du chunk compile
| Pattern | Attendu | Resultat |
|---|---|---|
| `api/playbooks?tenantId=` | present | ✓ |
| `fetchPlaybooks` | present | ✓ |
| `currentTenantId` | present | ✓ |
| `useTenant` | present (3x) | ✓ |
| `kb_client_playbooks` (localStorage) | absent | ✓ (0) |
| `getPlaybooks` (old service) | absent | ✓ (0) |

### API Smoke Tests
| Endpoint | Status |
|---|---|
| API Health | 200 ✓ |
| Dashboard Summary | 200 ✓ |
| Billing Current | 200 ✓ |
| AI Settings | 200 ✓ |
| Conversations | 200 ✓ |
| Playbooks ecomlg-001 | 200 (15 playbooks) ✓ |
| Playbooks switaa-sasu-mnc1x4eq | 200 (15 playbooks: 8 active, 7 disabled) ✓ |
| Client pages (login, inbox, dashboard, settings, orders, playbooks, billing) | Accessibles ✓ |

---

## 5. Rollback

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.218-ph143-fr-real-fix-dev \
  -n keybuzz-client-dev
```

---

## 6. VERDICT

**PLAYBOOKS API-BASED FIX DEPLOYED — 15 PLAYBOOKS IN DB — STRUCTURALLY VERIFIED**

Validation visuelle manuelle requise par Ludovic:
- [ ] Se connecter avec `switaa26@gmail.com`
- [ ] Page Playbooks: Total = 15, Actifs = 8/9, Inactifs = 6/7
- [ ] Refresh F5 → toujours visibles
- [ ] Navigation aller-retour → toujours visibles
- [ ] Recherche fonctionne
- [ ] Settings > Intelligence Artificielle → accents OK
- [ ] Agents → pas d'option KeyBuzz

**Conditionne a validation visuelle Ludovic.**
**AUCUN push PROD.**
