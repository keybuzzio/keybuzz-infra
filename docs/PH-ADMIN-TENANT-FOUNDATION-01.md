# PH-ADMIN-TENANT-FOUNDATION-01 — Refonte Fondation Multi-Tenant Admin

**Date** : 2026-03-04  
**Statut** : DEPLOYE EN DEV  
**Image** : `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-dev`  
**Commit** : `0d581ab` (keybuzz-admin-v2 main)  
**GitOps** : `b612cf9` (keybuzz-infra main)  
**Rollback** : `v2.10.9-admin-access-fix-dev`

---

## 1. Objectif

Unifier les 4 patterns de tenant context incompatibles coexistant dans Admin V2 en un systeme global coherent, ajouter la creation de tenant, et migrer toutes les pages vers le contexte unifie.

### Probleme initial

| Pattern | Pages | Mecanisme | Persistance |
|---------|-------|-----------|-------------|
| A (`useTenantSelector`) | ai-control, activation, policies, monitoring, debug | Fetch `/api/admin/tenants` (super_admin only) | `localStorage` `kb-admin-selected-tenant` |
| B (URL params) | ai, connectors, incidents, billing | `searchParams.get('tenantId')` | Aucune |
| C (marketing selector) | destinations, delivery-logs | Fetch `/api/admin/marketing/tenants` (role-aware) | `localStorage` `marketing_tenant_id` |
| D (global) | metrics, ops, queues, etc. | Aucun tenant | N/A |

**Consequences** : selection perdue entre pages, doublons API, role-awareness inconsistante, UX confuse.

---

## 2. Architecture cible implementee

```
RootLayout (AuthProvider)
  └─ AdminLayout
       └─ TenantProvider (NOUVEAU - contexte global)
            ├─ Sidebar
            ├─ Topbar + Tenant Selector dropdown (NOUVEAU)
            └─ Pages
                 └─ useCurrentTenant() → tenantId, tenantName, plan
                 └─ RequireTenant wrapper (NOUVEAU) → bloque si pas de tenant
```

**Cle unifiee localStorage** : `kb-admin-tenant`

---

## 3. Fichiers crees

| Fichier | Role |
|---------|------|
| `src/contexts/TenantContext.tsx` | React Context + Provider global. Fetch tenants, persiste selection, expose `useCurrentTenant()` |
| `src/components/ui/RequireTenant.tsx` | Wrapper qui bloque le rendu et affiche "Selectionnez un tenant" si aucun tenant selectionne |

## 4. Fichiers modifies

### Backend / API

| Fichier | Changement |
|---------|------------|
| `src/features/users/types.ts` | +`CreateTenantInput`, +`CreateTenantResult` interfaces |
| `src/features/users/services/users.service.ts` | +`import getPool`, +`createTenant()` methode transactionnelle (users, tenants, user_tenants, tenant_metadata, ai_actions_wallet) |
| `src/app/api/admin/tenants/route.ts` | GET **role-aware** (super_admin/ops_admin = tous, autres = assignes via admin_user_tenants) + POST handler creation tenant |

### Layout / Navigation

| Fichier | Changement |
|---------|------------|
| `src/app/(admin)/layout.tsx` | +`TenantProvider` wrapping global |
| `src/components/layout/Topbar.tsx` | +Tenant selector dropdown avec `useCurrentTenant()`, Building2 icon, plan badge |
| `src/components/ui/TenantFilterBanner.tsx` | Migre de `useSearchParams` vers `useCurrentTenant()` |

### Pages migrees (14 pages)

| Page | Pattern avant | Changement |
|------|---------------|------------|
| `ai-control/page.tsx` | A | `useTenantSelector` → `useCurrentTenant` + `RequireTenant` |
| `ai-control/activation/page.tsx` | A | idem |
| `ai-control/policies/page.tsx` | A | idem |
| `ai-control/monitoring/page.tsx` | A | idem |
| `ai-control/debug/page.tsx` | A | idem |
| `ai/page.tsx` | B | `searchParams.get('tenantId')` → `useCurrentTenant` + `RequireTenant` |
| `connectors/page.tsx` | B | idem |
| `incidents/page.tsx` | B | idem |
| `billing/page.tsx` | B | idem |
| `marketing/destinations/page.tsx` | C | Inline tenant selector supprime, `useCurrentTenant` + `RequireTenant` |
| `marketing/delivery-logs/page.tsx` | C | idem |
| `metrics/page.tsx` | D | +`useCurrentTenant`, tenantId propage dans fetch, +`RequireTenant` |
| `tenants/page.tsx` | Global | +Formulaire creation tenant inline (nom, email, plan, trial, pays) |

## 5. Fichiers supprimes

| Fichier | Raison |
|---------|--------|
| `src/hooks/useTenantSelector.ts` | Remplace par `useCurrentTenant()` depuis TenantContext |
| `src/app/api/admin/marketing/tenants/route.ts` | Remplace par GET `/api/admin/tenants` role-aware |

---

## 6. Tenant Creation — Details techniques

### Methode `usersService.createTenant()`

Transaction PostgreSQL qui replique la logique de `/create-signup` du SaaS API :

1. Find/create user par email dans table `users`
2. Generer `tenant_id` = slug(name) + timestamp base36
3. INSERT `tenants` (plan, status `active`)
4. INSERT `user_tenants` (role `owner`)
5. INSERT `tenant_metadata` (trial, country) — SAVEPOINT (tolerant si schema different)
6. INSERT `ai_actions_wallet` (init 0) — SAVEPOINT (tolerant)
7. COMMIT ou ROLLBACK complet

### Endpoint POST `/api/admin/tenants`

- **Roles autorises** : `super_admin`, `ops_admin`, `account_manager`
- **Payload** : `{ name, ownerEmail, plan?, trialDays?, country? }`
- **Response** : `{ tenantId, userId, plan, status, trialEndsAt }`

---

## 7. GET `/api/admin/tenants` — Role-awareness

| Role | Tenants retournes |
|------|-------------------|
| `super_admin`, `ops_admin` | Tous les tenants |
| `account_manager`, `media_buyer`, `agent` | Tenants assignes via `admin_user_tenants` |

---

## 8. Pages qui restent globales (pas de tenant requis)

- `/` (Control Center dashboard)
- `/ops` (Ops Center)
- `/queues`, `/approvals`, `/followups` (queues globales)
- `/tenants` (liste des tenants)
- `/users` (gestion admin users)
- `/settings`, `/settings/profile`
- `/system-health`, `/feature-flags`
- `/audit` (audit global)

---

## 9. Validation

### Build
- `npm run build` : 0 erreurs TypeScript
- 40 pages statiques + routes dynamiques compilees

### Build-from-git
- Clone propre depuis GitHub
- Working tree CLEAN
- Image Docker buildee et pushee vers `ghcr.io`

### Deploiement DEV
- Manifest GitOps mis a jour
- Pod `keybuzz-admin-v2-78c56c8bcb-whn9l` Running
- Image verifiee : `v2.11.0-tenant-foundation-dev`

---

## 10. Impact / Non-regression

| Domaine | Impact |
|---------|--------|
| API SaaS (`keybuzz-api`) | AUCUNE modification |
| Metriques existantes | Preservees (metrics page enrichie avec tenantId) |
| Webhook outbound | Preserve (destinations/delivery-logs migres sans regression) |
| RBAC | Preserve + enrichi (GET tenants role-aware) |
| Pages globales | Non impactees (ops, queues, approvals, etc.) |
| Marketing pages | Simplifiees (inline selector supprime, contexte global) |

---

## 11. Rollback

```bash
# Revenir a l'image precedente
cd /opt/keybuzz/keybuzz-infra
sed -i 's/v2.11.0-tenant-foundation-dev/v2.10.9-admin-access-fix-dev/' k8s/keybuzz-admin-v2-dev/deployment.yaml
kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml
kubectl rollout restart deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

---

## 12. Prochaines etapes

1. **Validation fonctionnelle navigateur** : tester la navigation, la persistance du tenant, la creation de tenant
2. **Promotion PROD** : apres validation DEV complete
3. **Enrichissement metrics proxy** : propager `x-tenant-id` dans le header vers le backend SaaS
4. **Migration pages globales restantes** : followups, approvals, queues (si tenant-scoping necessaire)
