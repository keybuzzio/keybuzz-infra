# PH140-J — Agent Hard Access Lockdown

> **Date** : 2 mars 2026
> **Environnement** : DEV uniquement
> **Tag** : `v3.5.174-agent-hard-access-lockdown-dev`
> **Statut** : DEPLOYE DEV + PROD

---

## Objectif

Empecher reellement un agent d'acceder aux pages et actions reservees aux owner/admin, meme en tapant directement l'URL. Afficher une page "Acces non autorise" claire avec retour vers `/inbox`.

---

## Probleme identifie

Le middleware Next.js utilise le cookie `currentTenantRole` pour bloquer les agents. Ce cookie est set par le `TenantProvider` (client-side) APRES le chargement de la page. En consequence, lors de la premiere navigation directe vers une page admin, le middleware ne bloque pas car le cookie n'est pas encore disponible.

L'ancien comportement se limitait a une redirection silencieuse vers `/inbox?rbac=restricted`, sans message explicite.

---

## Solution implementee : double guard

### 1. Guard ClientLayout (client-side, fiable)

Dans `ClientLayout.tsx`, un guard verifie `isAgent` (depuis `useTenant()`) + `isAdminOnlyRoute(pathname)` AVANT de rendre le contenu. Si l'agent tente d'acceder a une page admin, un ecran "Acces non autorise" est affiche directement a la place du contenu.

**Fichier** : `src/components/layout/ClientLayout.tsx`
- Import de `isAdminOnlyRoute` depuis `routeAccessGuard.ts`
- Si `isAgent && isAdminOnlyRoute(pathname)` : affiche une page claire avec :
  - Icone warning (Settings)
  - Titre "Acces non autorise"
  - Message "Cette section est reservee aux administrateurs"
  - Bouton "Aller a ma boite de reception" → `/inbox`

### 2. Guard middleware (server-side, defense en profondeur)

Le middleware redirige vers `/no-access` si `currentTenantRole=agent|viewer` ET route admin-only.

**Fichier** : `middleware.ts`
- Redirection `/no-access` (au lieu de `/inbox?rbac=restricted`)
- Bloque aussi les API admin-only avec HTTP 403

### 3. Page `/no-access` (fallback)

**Fichier** : `app/no-access/page.tsx`
- Ecran standalone "Acces non autorise"
- Bouton retour vers `/inbox`

### 4. Guards API/BFF (backend)

**Fichier** : `src/lib/routeAccessGuard.ts`
- `ADMIN_ONLY_API_PREFIXES` : liste des endpoints API sensibles
- `isAdminOnlyApiRoute()` : matcher pour le middleware
- Le middleware retourne HTTP 403 JSON pour les agents sur ces endpoints

---

## Routes auditees et protegees

### Pages admin (bloquees pour agents)

| Route | Resultat agent | Resultat owner |
|---|---|---|
| `/settings` | **BLOQUE** — ecran "Acces non autorise" | OK — page complete |
| `/billing` | **BLOQUE** | OK — plan, KBActions, factures |
| `/billing/plan` | **BLOQUE** | OK |
| `/billing/ai` | **BLOQUE** | OK |
| `/channels` | **BLOQUE** | OK |
| `/dashboard` | **BLOQUE** | OK — stats, SLA, activite |
| `/knowledge` | **BLOQUE** | OK |
| `/ai-journal` | **BLOQUE** | OK |
| `/onboarding` | **BLOQUE** | OK |
| `/start` | **BLOQUE** | OK |
| `/admin` | **BLOQUE** | OK |

### Pages agent (accessibles)

| Route | Resultat agent |
|---|---|
| `/inbox` | OK — sidebar filtree, badge "Agent" |
| `/orders` | OK |
| `/suppliers` | OK |
| `/playbooks` | OK |
| `/help` | OK |

### Endpoints API proteges (403 pour agents)

- `/api/billing/change-plan`, `/api/billing/checkout-session`
- `/api/channels/add`
- `/api/agents`
- `/api/tenant-settings/*`
- `/api/tenant-lifecycle/*`
- `/api/tenant-context/create`, `/api/tenant-context/[tenantId]`
- `/api/space-invites/*/invite`
- `/api/ai/settings`, `/api/ai/wallet/dev/*`
- `/api/amazon/oauth/*`, `/api/amazon/disconnect`
- `/api/octopia/connect`, `/api/octopia/disconnect`

---

## Tests realises (navigateur reel)

### Agent (`ludo.gonthier+olyara@gmail.com`, role: agent, tenant: OLYARA)

1. Login OTP reel — arrivee `/inbox` — badge "Agent" visible
2. Navigation directe `/settings` → **ecran "Acces non autorise"**
3. Navigation directe `/billing` → **ecran "Acces non autorise"**
4. Navigation directe `/channels` → **ecran "Acces non autorise"**
5. Navigation directe `/dashboard` → **ecran "Acces non autorise"**
6. Navigation directe `/knowledge` → **ecran "Acces non autorise"**
7. Navigation directe `/ai-journal` → **ecran "Acces non autorise"**
8. Bouton "Aller a ma boite de reception" → redirection `/inbox` OK

### Owner (`ludo.gonthier@gmail.com`, role: owner, tenant: eComLG)

1. Login OTP reel — selection tenant — arrivee `/inbox`
2. Sidebar complete (tous les menus admin visibles)
3. `/settings` → OK, page parametres complete (onglets, formulaires)
4. `/billing` → OK, plan Pro, KBActions, facturation visible
5. `/dashboard` → OK, stats completes (322 conversations, SLA, activite)

---

## Non-regressions

- Login owner/admin : OK
- Login agent invite (PH140-H) : OK
- UX invite prérempli (PH140-I) : non impacte
- Onboarding : non impacte (pas de modification)
- Billing Stripe : non touche

---

## Rollback

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.173-invite-login-ux-polish-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/components/layout/ClientLayout.tsx` | Guard `isAgent + isAdminOnlyRoute` → ecran "Acces non autorise" |
| `src/lib/routeAccessGuard.ts` | Ajout `ADMIN_ONLY_API_PREFIXES` + `isAdminOnlyApiRoute()` |
| `middleware.ts` | Redirection `/no-access` + guard API 403 |
| `app/no-access/page.tsx` | Page standalone "Acces non autorise" |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image → `v3.5.174-agent-hard-access-lockdown-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image → `v3.5.174-agent-hard-access-lockdown-prod` |

---

## Deploiement PROD

- **Image** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.174-agent-hard-access-lockdown-prod`
- **Build args** : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
- **Rollout** : `deployment "keybuzz-client" successfully rolled out`
- **Health** : `HTTP 200` en 0.79s
- **Pod** : `1/1 Running`, 0 restarts

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.173-invite-login-ux-polish-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```
