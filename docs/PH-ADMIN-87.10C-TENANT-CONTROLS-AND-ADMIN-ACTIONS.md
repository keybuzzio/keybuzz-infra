# PH-ADMIN-87.10C — TENANT CONTROLS & ADMIN ACTIONS

**Date** : 2026-03-21
**Auteur** : Cursor Agent (demande Ludovic)
**Version** : v2.3.0
**Statut** : DEPLOYE DEV + PROD

---

## 1. Resume executif

### Actions ajoutees (permanentes)
- **Suspendre** un tenant (status → `suspended`)
- **Reactiver** un tenant (status → `active`)
- **Changer le plan** (FREE / STARTER / PRO / AUTOPILOT)
- **Assigner un admin** au tenant
- **Retirer un admin** du tenant

### Action temporaire (test)
- **Hard delete** tenant — suppression destructive reelle de toutes les donnees liees
- Demandee explicitement par Ludovic pour les tests OAuth / creation de comptes
- A retirer dans une phase ulterieure

### RBAC
Toutes les actions sont **super_admin only**. Aucun autre role ne peut executer ces mutations.

### Audit
Chaque mutation cree une entree dans `admin_actions_log` avec action, tenant_id, actor_email, metadata, created_at.

---

## 2. Cartographie d'impact tenant

### Schema `tenants`
| Colonne | Type | Description |
|---|---|---|
| id | varchar | Identifiant unique (ex: `ecomlg-001`) |
| name | varchar | Nom affiche |
| domain | varchar | Domaine |
| plan | varchar | Plan (STARTER, PRO, AUTOPILOT, FREE) |
| status | varchar | Statut (active, suspended, pending_payment) |
| created_at | timestamp | Date creation |
| updated_at | timestamp | Date derniere modification |

### Tables avec FK ON DELETE CASCADE (auto-nettoyees)
12 tables : `agents`, `conversations`, `messages`, `inbound_addresses`, `inbound_connections`, `integrations`, `marketplace_octopia_accounts`, `space_invites`, `teams`, `tenant_ai_policies`, `tenant_metadata`

### Table FK bloquante
`cancel_reasons` — FK vers `tenants` sans CASCADE, doit etre supprimee manuellement avant le tenant

### Tables avec `tenant_id` sans FK (67 tables)
Nettoyees dynamiquement lors du hard delete : `ai_rules`, `ai_actions_ledger`, `ai_credits_wallet`, `billing_subscriptions`, `admin_user_tenants`, `tenant_channels`, `ai_rule_conditions`, `ai_rule_actions`, etc.

### Strategie de suppression
1. Identifier dynamiquement toutes les tables avec colonne `tenant_id` / `tenantId`
2. Supprimer les lignes de chaque table pour le tenant cible (sauf `admin_actions_log` pour conserver l'audit)
3. Supprimer explicitement `cancel_reasons` (FK bloquante)
4. Supprimer le tenant de la table `tenants` (les FK CASCADE s'executent automatiquement)

---

## 3. Endpoints ajoutes

### A. Suspendre
```
POST /api/admin/tenants/[id]/suspend
```
- RBAC : super_admin
- Effet : `UPDATE tenants SET status = 'suspended'`
- Audit : `TENANT_SUSPENDED`

### B. Reactiver
```
POST /api/admin/tenants/[id]/reactivate
```
- RBAC : super_admin
- Effet : `UPDATE tenants SET status = 'active'`
- Audit : `TENANT_REACTIVATED`

### C. Changer le plan
```
PATCH /api/admin/tenants/[id]/plan
Body: { "plan": "STARTER|PRO|AUTOPILOT|FREE" }
```
- RBAC : super_admin
- Effet : `UPDATE tenants SET plan = $1`
- Audit : `TENANT_PLAN_CHANGED` avec metadata `{ from, to }`

### D. Assigner admin
```
POST /api/admin/tenants/[id]/admins
Body: { "userId": "uuid" }
```
- RBAC : super_admin
- Effet : `INSERT INTO admin_user_tenants`
- Audit : `TENANT_ADMIN_ASSIGNED`

### E. Retirer admin
```
DELETE /api/admin/tenants/[id]/admins
Body: { "userId": "uuid" }
```
- RBAC : super_admin
- Effet : `DELETE FROM admin_user_tenants`
- Audit : `TENANT_ADMIN_REMOVED`

### F. Pre-check impact (hard delete)
```
GET /api/admin/tenants/[id]/impact
```
- RBAC : super_admin
- Retourne : nombre d'enregistrements par table cle (conversations, messages, etc.)

### G. Hard delete
```
DELETE /api/admin/tenants/[id]/hard-delete
Body: { "confirmId": "tenant-id-exact" }
```
- RBAC : super_admin
- Confirmation : `confirmId` doit correspondre exactement a l'ID du tenant
- Audit : `TENANT_HARD_DELETE_STARTED` (avant) + `TENANT_HARD_DELETED` (apres)
- Effet : suppression complete et reelle du tenant et de toutes ses donnees

---

## 4. UI cockpit — panneau controles

### Composant `TenantControlsPanel.tsx`
Ajoute au cockpit `/tenants/[id]`, visible uniquement pour super_admin.

### Sections
1. **Statut du tenant** — Bouton Suspendre / Reactiver (toggle dynamique)
2. **Plan** — Combobox (FREE, STARTER, PRO, AUTOPILOT) + bouton Appliquer
3. **Admins lies** — Combobox d'assignation + liste des admins avec bouton retirer
4. **Zone danger** — Bouton "Supprimer definitivement" (rouge, isole visuellement)

### Modales de confirmation
- **Suspend** : confirmation simple avec nom et ID du tenant
- **Hard delete** : confirmation renforcee obligatoire
  - Message explicite : "ATTENTION : Cette action est permanente et irreversible."
  - Usage reserve aux tests
  - Affichage du pre-check quantifie (donnees qui seront supprimees)
  - Champ texte : l'utilisateur doit taper exactement l'ID du tenant
  - Bouton danger desactive tant que l'ID n'est pas saisi

---

## 5. Audit log

### Table `admin_actions_log`
| Colonne | Type | Description |
|---|---|---|
| id | uuid (gen_random_uuid) | Identifiant unique |
| action | varchar | Type d'action |
| tenant_id | varchar (nullable) | Tenant concerne (null apres hard delete) |
| actor_email | varchar | Email de l'acteur |
| metadata | jsonb | Donnees contextuelles |
| created_at | timestamptz | Horodatage |

### Actions tracees
| Action | Metadata | Plan min |
|---|---|---|
| `TENANT_SUSPENDED` | `{ previousStatus }` | super_admin |
| `TENANT_REACTIVATED` | `{ previousStatus }` | super_admin |
| `TENANT_PLAN_CHANGED` | `{ from, to }` | super_admin |
| `TENANT_ADMIN_ASSIGNED` | `{ userId }` | super_admin |
| `TENANT_ADMIN_REMOVED` | `{ userId }` | super_admin |
| `TENANT_HARD_DELETE_STARTED` | `{ tenantName }` | super_admin |
| `TENANT_HARD_DELETED` | `{ tenantId, tenantName, tablesCleanedCount, totalRecordsDeleted }` | super_admin |

---

## 6. Preuve DB → API → UI → Mutation

### DEV (admin-dev.keybuzz.io)
| Action | Tenant | DB avant | API mutation | DB apres | UI apres | Audit log |
|---|---|---|---|---|---|---|
| Suspend | `ecomlg-mmiyygfg` | status=active | POST /suspend | status=suspended | Bouton → "Reactiver" | TENANT_SUSPENDED |
| Reactivate | `ecomlg-mmiyygfg` | status=suspended | POST /reactivate | status=active | Bouton → "Suspendre" | TENANT_REACTIVATED |
| Plan PRO→STARTER | `ecomlg-mmiyygfg` | plan=PRO | PATCH /plan | plan=STARTER | Combobox = STARTER | TENANT_PLAN_CHANGED {from:PRO,to:STARTER} |
| Plan STARTER→PRO | `ecomlg-mmiyygfg` | plan=STARTER | PATCH /plan | plan=PRO | Combobox = PRO | TENANT_PLAN_CHANGED {from:STARTER,to:PRO} |
| Hard delete | `-mn0k9rc7` | exists (13 tenants) | DELETE /hard-delete | 0 rows (12 tenants) | Redirige /tenants, 12 tenants | TENANT_HARD_DELETE_STARTED + TENANT_HARD_DELETED |

### PROD (admin.keybuzz.io)
| Action | Tenant | DB avant | API mutation | DB apres | UI apres | Audit log |
|---|---|---|---|---|---|---|
| Suspend | `eeeee-mmynd831` | status=active | POST /suspend | status=suspended | Bouton → "Reactiver" | TENANT_SUSPENDED 20:23:55 |
| Reactivate | `eeeee-mmynd831` | status=suspended | POST /reactivate | status=active | Bouton → "Suspendre" | TENANT_REACTIVATED 20:26:16 |
| Plan STARTER→PRO | `eeeee-mmynd831` | plan=STARTER | PATCH /plan | plan=PRO | Combobox = PRO | TENANT_PLAN_CHANGED 20:26:49 |
| Plan PRO→STARTER | `eeeee-mmynd831` | plan=PRO | PATCH /plan | plan=STARTER | Combobox = STARTER | TENANT_PLAN_CHANGED 20:27:40 |
| Hard delete | `coucou-mmyx2cb4` | exists (8 tenants) | DELETE /hard-delete | 0 rows (7 tenants) | Redirige /tenants, 7 tenants | TENANT_HARD_DELETE_STARTED + TENANT_HARD_DELETED 20:28:28 |

---

## 7. Hard delete — Preuve reelle

### DEV
- **Tenant supprime** : `-mn0k9rc7` ("ççççççççç")
- **Plan** : AUTOPILOT
- **Status avant** : pending_payment
- **Donnees** : 0 conversations, 0 messages
- **Resultat** : supprime, DB = 0 rows, UI = 12 tenants (etait 13)
- **Orphelins** : aucun detecte (tenant sans donnees)

### PROD
- **Tenant supprime** : `coucou-mmyx2cb4` ("coucou")
- **Plan** : STARTER
- **Status avant** : active
- **Donnees** : 0 conversations, 0 messages
- **Resultat** : supprime, DB = 0 rows, UI = 7 tenants (etait 8)
- **Orphelins** : aucun detecte (tenant sans donnees)

### Limites connues
- Le hard delete ne peut pas etre annule (pas de soft-delete / archive)
- Les tables sans FK directe sont nettoyees dynamiquement — si une nouvelle table avec `tenant_id` est ajoutee sans FK, elle sera detectee et nettoyee
- La table `admin_actions_log` est volontairement preservee pour conserver la trace d'audit

---

## 8. Deploiement

### Commits source
| SHA | Message |
|---|---|
| `ee528a7a` | `feat(admin): PH-ADMIN-87.10C tenant controls & admin actions` |
| `9dd7c071` | `fix(admin): add TenantControlsPanel render to cockpit page` |

### Images Docker
| Env | Tag | Registry |
|---|---|---|
| DEV | `v2.3.0-ph-admin-87-10c-dev` | `ghcr.io/keybuzzio/keybuzz-admin` |
| PROD | `v2.3.0-ph-admin-87-10c-prod` | `ghcr.io/keybuzzio/keybuzz-admin` |

### Version runtime
- DEV : v2.3.0 (visible dans sidebar)
- PROD : v2.3.0 (visible dans sidebar)

### Pods
- DEV : `keybuzz-admin-v2-dev` namespace, image `v2.3.0-ph-admin-87-10c-dev`
- PROD : `keybuzz-admin-v2-prod` namespace, image `v2.3.0-ph-admin-87-10c-prod`

---

## 9. Rollback

### DEV
```bash
# Image stable precedente
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.2.0-ph-admin-87-10b-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
# Image stable precedente
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.2.0-ph-admin-87-10b-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

### Verification post-rollback
1. `kubectl get pod -n keybuzz-admin-v2-{dev|prod} -o jsonpath='{.items[0].spec.containers[0].image}'` — verifier l'image
2. Naviguer vers `/tenants/[id]` — le panneau "Controles Admin" ne doit plus apparaitre
3. Les endpoints `/api/admin/tenants/[id]/*` retourneront 404

### Points d'attention rollback
- La table `admin_actions_log` restera en DB (pas de migration down necessaire)
- Les mutations deja effectuees (suspend, plan change, hard delete) ne sont PAS reversibles par rollback
- Le rollback ne restore PAS les tenants supprimes par hard delete

---

## 10. Dette future

### Hard delete a retirer
- **Priorite** : moyenne (fonctionnalite temporaire de test)
- **Action** : supprimer le endpoint `DELETE /api/admin/tenants/[id]/hard-delete`, le endpoint impact, et la section "Zone danger" du `TenantControlsPanel`
- **Strategie future recommandee** : soft delete / archive
  - Ajouter un champ `deleted_at` timestamp nullable
  - "Supprimer" = `UPDATE tenants SET deleted_at = NOW(), status = 'archived'`
  - Filtrer les tenants archives de toutes les requetes
  - Permettre la restauration pendant X jours
  - Purge automatique apres la periode de retention

### Ameliorations futures
- Confirmation par email pour les actions destructives
- Historique des actions dans le cockpit tenant (timeline)
- Notification temps reel aux admins concernes
- Rate limiting sur les endpoints d'administration
- Backup automatique avant hard delete

### Normalisation des plans
- Aligner les valeurs en DB : certains tenants ont `pro` (minuscule), d'autres `PRO` (majuscule)
- Le endpoint plan normalise deja en majuscule, mais les anciennes valeurs subsistent

---

## Annexe — Fichiers modifies/crees

### Nouveaux fichiers
| Fichier | Role |
|---|---|
| `src/app/api/admin/tenants/[id]/suspend/route.ts` | Endpoint suspend |
| `src/app/api/admin/tenants/[id]/reactivate/route.ts` | Endpoint reactivate |
| `src/app/api/admin/tenants/[id]/plan/route.ts` | Endpoint change plan |
| `src/app/api/admin/tenants/[id]/admins/route.ts` | Endpoint assign/remove admin |
| `src/app/api/admin/tenants/[id]/impact/route.ts` | Endpoint pre-check impact |
| `src/app/api/admin/tenants/[id]/hard-delete/route.ts` | Endpoint hard delete |
| `src/components/tenant/TenantControlsPanel.tsx` | Composant UI panneau controles |

### Fichiers modifies
| Fichier | Modification |
|---|---|
| `src/features/users/types.ts` | Ajout interfaces TenantImpact, HardDeleteResult, AdminActionLog |
| `src/features/users/services/users.service.ts` | Ajout methodes admin (suspend, reactivate, plan, admins, impact, hard delete, audit) |
| `src/app/(admin)/tenants/[id]/page.tsx` | Import et rendu TenantControlsPanel |
| `src/components/layout/Sidebar.tsx` | Version v2.2.0 → v2.3.0 |
