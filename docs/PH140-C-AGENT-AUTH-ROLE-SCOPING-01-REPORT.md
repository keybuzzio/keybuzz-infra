# PH140-C — Agent Auth Role Scoping

**Phase** : PH140-C-AGENT-AUTH-ROLE-SCOPING-01
**Environnements** : DEV + PROD
**Tags** : `v3.5.167-agent-auth-scope-dev` / `v3.5.167-agent-auth-scope-prod`

---

## Objectif

Mettre en place un vrai mode agent securise et clair :
- agent peut se connecter
- agent a un perimetre limite
- owner/admin gardent les droits complets
- UI et backend appliquent les memes regles

---

## Audit auth/roles existant

### Ce qui existait deja (PH119/PH121)

| Composant | Etat | Details |
|---|---|---|
| `src/lib/roles.ts` | Complet | Matrice `ROLE_PERMISSIONS` pour owner/admin/agent/viewer |
| `src/features/roles/usePermissions.ts` | Complet | Hook `usePermissions()` + `useHasPermission()` |
| `src/features/roles/PermissionGate.tsx` | Complet | Composant garde conditionnel |
| `src/features/tenant/TenantProvider.tsx` | Complet | Expose `currentRole`, `isAgent`, `isOwnerOrAdmin` |
| `middleware.ts` | Complet | RBAC via cookie `currentTenantRole` — redirect `/inbox?rbac=restricted` |
| `src/lib/routeAccessGuard.ts` | Complet | `ADMIN_ONLY_ROUTES` + `isAdminOnlyRoute()` |
| `ClientLayout.tsx` nav filtering | Complet | Agent voit uniquement `/inbox`, `/orders`, `/suppliers`, `/playbooks`, `/help` |
| Role badge top-right | Complet | Badge colore "Agent" dans le menu utilisateur |

### Permissions agent (matrice `ROLE_PERMISSIONS`)

| Permission | owner | admin | agent | viewer |
|---|---|---|---|---|
| canViewConversations | oui | oui | oui | oui |
| canReply | oui | oui | oui | non |
| canAssign | oui | oui | non | non |
| canAccessSettings | oui | oui | non | non |
| canAccessAI | oui | oui | non | non |
| canManageBilling | oui | non | non | non |
| canInviteUsers | oui | oui | non | non |
| canExportData | oui | oui | non | non |
| canManageAgents | oui | oui | non | non |

### Routes admin-only (bloquees pour agent)

`/settings`, `/billing`, `/channels`, `/onboarding`, `/start`, `/dashboard`, `/knowledge`, `/ai-journal`, `/ai-dashboard`, `/admin`

---

## Lacunes corrigees (PH140-C)

### 1. Guard BFF agents POST (403)

**Fichier** : `app/api/agents/route.ts`

Le POST `/api/agents` (creation d'agent) ne verifiait pas le role.
Ajout d'un guard `requirePermission(request, 'canManageAgents')` — retourne 403 si role agent.

### 2. Helper BFF role guard

**Fichier** : `src/lib/bff-role-guard.ts` (nouveau)

Fonction `requirePermission(request, permission)` :
- Recupere la session NextAuth
- Appelle `/tenant-context/me` pour obtenir le role reel du tenant
- Verifie la permission via `getPermissions(role)`
- Retourne 403 si insuffisant, sinon les infos utilisateur

### 3. Menu utilisateur — masquer Parametres pour agents

**Fichier** : `src/components/layout/ClientLayout.tsx`

Le lien "Profil / Parametres" dans le dropdown utilisateur est maintenant conditionnel :
- Visible pour owner/admin
- Masque pour agent/viewer

### 4. Notification RBAC redirect

**Fichier** : `app/inbox/InboxTripane.tsx`

Quand un agent est redirige vers `/inbox?rbac=restricted`, un toast rouge s'affiche :
"Cette section est reservee aux administrateurs"
Le param `rbac` est nettoye de l'URL immediatement apres.

### 5. Bandeau Mode Agent

**Fichier** : `src/components/layout/ClientLayout.tsx`

Bandeau emeraude en haut de page quand connecte en tant qu'agent :
"Mode Agent — Votre espace de travail est limite aux conversations et commandes"
Avec un point pulse pour visibilite.

---

## Fichiers modifies

| Fichier | Action | Description |
|---|---|---|
| `src/lib/bff-role-guard.ts` | Nouveau | Helper requirePermission pour BFF |
| `app/api/agents/route.ts` | Modifie | Guard canManageAgents sur POST |
| `src/components/layout/ClientLayout.tsx` | Modifie | Menu agent reduit + bandeau mode agent |
| `app/inbox/InboxTripane.tsx` | Modifie | Toast notification RBAC redirect |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Modifie | Tag v3.5.167-agent-auth-scope-dev |

---

## Tests

| Cas | Attendu | Resultat |
|---|---|---|
| owner/admin login | Acces complet, toutes les pages | OK |
| agent login | Nav reduite (inbox/orders/suppliers/playbooks/help) | OK |
| agent acces /settings | Redirect /inbox + toast "section reservee" | OK |
| agent acces /billing | Redirect /inbox + toast | OK |
| agent POST /api/agents | 403 Forbidden | OK |
| agent inbox — prendre en charge | Fonctionne (canReply = true) | OK |
| agent inbox — repondre | Fonctionne | OK |
| bandeau agent | Affiche en vert "Mode Agent..." | OK |
| owner menu utilisateur | Lien Parametres visible | OK |
| agent menu utilisateur | Lien Parametres masque | OK |

---

## Non-regressions

| Composant | DEV | PROD |
|---|---|---|
| Inbox (PH140-A/B) | OK | OK |
| Escalade + assignation | OK | OK |
| Workspace agent (PH140-B) | OK | OK |
| Autopilot | OK | OK |
| Signature (PH139) | OK | OK |
| Billing | OK | OK |
| Outbound | OK | OK |

---

## Deploiement

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-client | `v3.5.167-agent-auth-scope-dev` |
| PROD | keybuzz-client | `v3.5.167-agent-auth-scope-prod` |

---

## Rollback

### DEV

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.166-agent-workspace-dev -n keybuzz-client-dev
```

### PROD

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.166-agent-workspace-prod -n keybuzz-client-prod
```

---

## Verdict

**AGENT MODE SECURE — ROLE SCOPE CLEAR — ADMIN SAFE — NO CONFUSION — DEPLOYE DEV + PROD**
