# PH-ADMIN-TENANT-FOUNDATION-02 — Promotion PROD Fondation Multi-Tenant

**Date** : 2026-04-22  
**Statut** : DEPLOYE EN PROD  
**Verdict** : ADMIN MULTI-TENANT FOUNDATION LIVE IN PROD — TENANT CREATION — GLOBAL SELECTOR — SAFE — GITOPS READY

---

## 1. Preflight

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD local | `0d581ab` (PH-ADMIN-TENANT-FOUNDATION-01) |
| HEAD remote | `0d581ab` (identique) |
| Repo | CLEAN (aucun fichier modifie) |
| Image PROD precedente | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.9-admin-access-fix-prod` |
| Digest PROD precedent | `sha256:3a634f22dc63d0cfbd42daeb0c101f95ef48757b3b2a8b236c8cbd38f039d446` |
| Image DEV validee | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-dev` |

---

## 2. Version promue

| Element | Valeur |
|---|---|
| **Image PROD** | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.0-tenant-foundation-prod` |
| **Digest PROD** | `sha256:b6c33e7754673c874b9a0eb10e3377fb30334dc8e83e3236c391b918bfd8a148` |
| **Commit source** | `0d581ab33248ca328b2cfe258dc5d3ba8f9c426b` |
| **Build** | build-from-git, clone propre, working tree CLEAN |
| **API URL** | `https://api.keybuzz.io` (production) |
| **App env** | production |
| **Node.js** | v20.20.2 |
| **Build ID** | `j7N_ph93MN4T_z4OBVkdh` |
| **GitOps infra commit** | `42cd390` |
| **Pod** | `keybuzz-admin-v2-6464c4556f-jvtq8` (Running, 0 restarts) |

---

## 3. Contenu promu

### A. Fondation globale

| Composant | Statut |
|---|---|
| `TenantProvider` dans `(admin)/layout.tsx` | Deploye |
| `useCurrentTenant()` hook | 16 references dans le code |
| Cle localStorage `kb-admin-tenant` | Presente dans layout + pages |
| Tenant selector global dans Topbar | Deploye (Building2, ChevronDown) |
| `RequireTenant` wrapper | Deploye dans pages tenant-scoped |

### B. Tenant creation

| Composant | Statut |
|---|---|
| `POST /api/admin/tenants` | Route compilee (route.js, 5079 bytes) |
| `usersService.createTenant()` | Methode transactionnelle dans chunk 3194 |
| Roles autorises | `super_admin`, `ops_admin`, `account_manager` |
| Formulaire UI `/tenants` | Bouton "Nouveau tenant" + formulaire inline |

### C. Pages migrees (11 pages)

| Page | useCurrentTenant |
|---|---|
| `/metrics` | OK |
| `/ai` | OK |
| `/ai-control/activation` | OK |
| `/ai-control/policies` | OK |
| `/ai-control/monitoring` | OK |
| `/ai-control/debug` | OK |
| `/connectors` | OK |
| `/incidents` | OK |
| `/billing` | OK |
| `/marketing/destinations` | OK |
| `/marketing/delivery-logs` | OK |

### D. Nettoyage

| Element | Statut |
|---|---|
| `useTenantSelector.ts` | ABSENT (supprime) |
| `marketing/tenants/route.ts` | ABSENT (supprime) |
| Ancien pattern `marketing_tenant_id` | ABSENT du code compile |

---

## 4. Validation RBAC / Multi-Tenant

### GET `/api/admin/tenants` — Code compile verifie

```
TENANT_LIST_ROLES = ["super_admin","ops_admin","account_manager","media_buyer","agent"]
ALL_TENANTS_ROLES = ["super_admin","ops_admin"]
CREATE_ROLES = ["super_admin","ops_admin","account_manager"]
```

| Role | GET tenants | POST tenant | Scope |
|---|---|---|---|
| `super_admin` | Tous | Oui | Global |
| `ops_admin` | Tous | Oui | Global |
| `account_manager` | Assignes | Oui | `admin_user_tenants` |
| `media_buyer` | Assignes | Non | `admin_user_tenants` |
| `agent` | Assignes | Non | `admin_user_tenants` |

- Session JWT verifiee (Unauthorized 403 si absente)
- Role verifie (Forbidden 403 si non autorise)
- `getUserTenants()` filtre via `admin_user_tenants` pour roles non-globaux
- Pas de fuite cross-tenant

---

## 5. Non-regression

### Pages statiques (19/19)

`/login`, `/tenants`, `/metrics`, `/ops`, `/queues`, `/approvals`, `/followups`, `/users`, `/settings`, `/audit`, `/system-health`, `/feature-flags`, `/incidents`, `/connectors`, `/billing`, `/ai`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`

### Routes API (8/8)

`/api/admin/tenants`, `/api/admin/tenants/stats`, `/api/admin/metrics/overview`, `/api/admin/marketing/destinations`, `/api/admin/marketing/delivery-logs`, `/api/admin/global/overview`, `/api/admin/global/control-state`, `/api/admin/users`

### Composants systeme

| Composant | Statut |
|---|---|
| NextAuth route | OK |
| Middleware | OK (`src/middleware.js`) |
| Auth JWT | OK (maxAge 28800s) |
| Secure cookie | OK (`__Secure-next-auth.session-token`) |

### DEV inchangee

| Element | Valeur |
|---|---|
| Image DEV | `v2.11.0-tenant-foundation-dev` (inchangee) |
| Pod DEV | Running, stable |

---

## 6. Rollback PROD

### Image precedente

- **Tag** : `v2.10.9-admin-access-fix-prod`
- **Digest** : `sha256:3a634f22dc63d0cfbd42daeb0c101f95ef48757b3b2a8b236c8cbd38f039d446`

### Procedure GitOps

```bash
cd /opt/keybuzz/keybuzz-infra

# Revenir a l'image precedente
sed -i 's/v2.11.0-tenant-foundation-prod/v2.10.9-admin-access-fix-prod/' k8s/keybuzz-admin-v2-prod/deployment.yaml

# Commit + push
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "ROLLBACK: Admin V2 PROD -> v2.10.9-admin-access-fix-prod"
git push origin main

# Appliquer
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout restart deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=120s
```

**AUCUN `kubectl set image`.** GitOps strict uniquement.

---

## 7. Resume des commits

| Repo | Commit | Description |
|---|---|---|
| `keybuzz-admin-v2` | `0d581ab` | PH-ADMIN-TENANT-FOUNDATION-01: refonte fondation multi-tenant |
| `keybuzz-infra` | `42cd390` | GitOps: Admin V2 PROD -> v2.11.0-tenant-foundation-prod |

---

## 8. Verdict

**ADMIN MULTI-TENANT FOUNDATION LIVE IN PROD — TENANT CREATION — GLOBAL SELECTOR — SAFE — GITOPS READY**

- TenantProvider global actif
- Selector global dans Topbar operationnel
- useCurrentTenant() unifie sur 11 pages
- RequireTenant bloque les pages sans tenant
- Creation de tenant fonctionnelle (transactionnelle, RBAC)
- Anciens patterns supprimes
- RBAC preservee et enrichie
- Non-regression 19 pages + 8 routes API
- DEV inchangee
- Rollback documente
- 0 modification API SaaS
