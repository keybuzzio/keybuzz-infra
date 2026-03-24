# PH-ADMIN-87.10B — Tenant Actions & Cross-Module Intervention

**Date** : 2026-03-04
**Auteur** : Cursor Executor
**Version** : Admin v2.2.0
**Verdict** : GO — ADMIN v2.2.0 VALIDE DEV + PROD

---

## 1. Resume executif

### Ce qui a ete ajoute
- **3 modules rendus tenant-aware** : Users, Queues, Approvals
- **Composant TenantFilterBanner** : bandeau indiquant le tenant filtre avec lien retour au cockpit
- **Navigation tenant-aware depuis le cockpit** : liens rapides avec `?tenantId=<id>`
- **Filtrage server-side Users** : endpoint `/api/admin/users?tenantId=X` via JOIN `admin_user_tenants`
- **Filtrage client-side Queues & Approvals** : sur le champ `tenantId` des items retournes par l'API main

### Actions possibles depuis le cockpit
- Voir queues du tenant (filtrees)
- Voir approbations du tenant (filtrees)
- Voir utilisateurs admin du tenant (filtres)
- Ouvrir AI Control Center
- Ouvrir Ops Center (marque "global")

### Limites restantes (honnetes)
- **Ops** : dashboard agrege global, pas de breakdown par tenant dans l'API
- **Followups** : scheduler report sans `tenantId` dans les items
- **Audit** : page placeholder
- **Billing** : page placeholder
- **Incidents/Connectors/AI Evaluations** : pas de filtrage tenant implemente

---

## 2. Audit des modules

| Module | Donnees tenant-scopees | Filtre possible | Action realisee |
|---|---|---|---|
| **Users** | `admin_user_tenants` | OUI (server-side JOIN) | `?tenantId=X` sur API + page |
| **Queues** | `QueueEntry.tenantId` | OUI (client-side filter) | `?tenantId=X` sur page |
| **Approvals** | `ApprovalItem.tenantId` | OUI (client-side filter) | `?tenantId=X` sur page |
| **AI Control** | Deja tenant-aware | DEJA (useTenantSelector) | Aucune modification |
| Ops | Agreges globaux | NON | Label "global" ajoute |
| Followups | SchedulerReport sans tenantId | NON | Non filtrable |
| Audit | Placeholder | NON | Placeholder |
| Billing | Placeholder | NON | Placeholder |

---

## 3. Endpoints modifies

### GET /api/admin/users
- **Nouveau** : support `?tenantId=<id>` en query param
- Si `tenantId` fourni : retourne uniquement les users lies via `admin_user_tenants`
- Si absent : retourne tous les users (retro-compatible)
- Methode ajoutee : `usersService.listUsersByTenant(tenantId)`

```sql
SELECT au.* FROM admin_users au
JOIN admin_user_tenants aut ON aut.user_id = au.id
WHERE aut.tenant_id = $1
ORDER BY au.email ASC
```

### Queues et Approvals
- Aucun endpoint modifie (donnees viennent de l'API main)
- Filtrage client-side sur `QueueEntry.tenantId` et `ApprovalItem.tenantId`

---

## 4. UI modifiee

### Composant TenantFilterBanner (NOUVEAU)
- Fichier : `src/components/ui/TenantFilterBanner.tsx`
- Affiche : icone Building2 + "Filtre sur le tenant : {tenantId}"
- Lien : "Retour au cockpit tenant" → `/tenants/{tenantId}`
- Conditionnel : ne s'affiche que si `?tenantId=` present dans l'URL

### Cockpit tenant `/tenants/[id]` (MODIFIE)
- Liens rapides modifies :
  - `Queues du tenant` → `/queues?tenantId={id}`
  - `Approbations du tenant` → `/approvals?tenantId={id}`
  - `Utilisateurs du tenant` → `/users?tenantId={id}`
  - `AI Control Center` → `/ai-control` (deja tenant-aware via selector)
  - `Ops Center (global)` → `/ops` (label honnete)

### Users `/users` (MODIFIE)
- Lit `tenantId` depuis l'URL via `useSearchParams()`
- Passe le filtre a l'API
- Affiche TenantFilterBanner
- Suspense wrapper pour SSG Next.js 14

### Queues `/queues` (MODIFIE)
- Lit `tenantId` depuis l'URL
- Filtre client-side les items par `tenantId`
- Recalcule les KPI sur les items filtres
- Affiche TenantFilterBanner
- Suspense wrapper

### Approvals `/approvals` (MODIFIE)
- Lit `tenantId` depuis l'URL
- Filtre client-side les items par `tenantId`
- Recalcule les KPI (count, critical, high) sur les items filtres
- Affiche TenantFilterBanner
- Suspense wrapper

---

## 5. Preuve DB → API → UI → Navigation

### DEV — ecomlg-001

| Etape | Resultat |
|---|---|
| Cockpit `/tenants/ecomlg-001` | 261 conversations, 182 ouvertes, 830 messages, 0/15 playbooks |
| Lien "Queues du tenant" | Navigue vers `/queues?tenantId=ecomlg-001` |
| Queues filtrees | 0 cas en queue (correct) |
| Retour cockpit | Lien fonctionne → `/tenants/ecomlg-001` |
| Lien "Approbations du tenant" | Navigue vers `/approvals?tenantId=ecomlg-001` |
| Approbations filtrees | 2 en attente, 2 priorite haute |
| Retour cockpit | Lien fonctionne |
| `/users?tenantId=ecomlg-001` | "Aucun utilisateur" (correct : 0 dans admin_user_tenants) |
| `/users?tenantId=w3lg-mmyxgv0k` | 2 users affiches (correct : 2 dans admin_user_tenants) |

### PROD — ecomlg-001

| Etape | Resultat |
|---|---|
| Cockpit `/tenants/ecomlg-001` | 269 conversations, 135 ouvertes, 863 messages, 0/15 playbooks |
| Lien "Approbations du tenant" | Navigue vers `/approvals?tenantId=ecomlg-001` |
| Approbations filtrees | 2 en attente, bandeau filter visible |
| Retour cockpit | Lien "Retour au cockpit tenant" fonctionne |
| Version sidebar | v2.2.0 |

---

## 6. Deploiement

| | DEV | PROD |
|---|---|---|
| **Commit source** | `11683dcca0a8b6fe633668c442fd6355ff457406` | Meme |
| **Tag image** | `v2.2.0-ph-admin-87-10b-dev` | `v2.2.0-ph-admin-87-10b-prod` |
| **Digest** | `sha256:48b16f3e690f...` | `sha256:48b16f3e690f...` |
| **Pod** | `keybuzz-admin-v2-5bcd99665b-pdt5f` | `keybuzz-admin-v2-6ccb48495b-9k8sz` |
| **Version runtime** | v2.2.0 | v2.2.0 |
| **Image precedente** | `v2.1.9-ph-admin-87-10a-dev` | `v2.1.9-ph-admin-87-10a-prod` |

### Commits Git
1. `cc43e3e` — feat(ph-admin-87.10b): tenant-aware cross-module navigation & filtering
2. `c9c9ddd` — fix: wrap useSearchParams in Suspense boundaries for Next.js 14 SSG
3. `11683dc` — fix: ensure use client directive is first line in queues/approvals pages

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.9-ph-admin-87-10a-dev -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.9-ph-admin-87-10a-prod -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## 8. Fichiers modifies / crees

| Fichier | Action |
|---|---|
| `src/components/ui/TenantFilterBanner.tsx` | CREE — bandeau filtre tenant |
| `src/features/users/services/users.service.ts` | MODIFIE — ajout `listUsersByTenant()` |
| `src/app/api/admin/users/route.ts` | MODIFIE — support `?tenantId=X` |
| `src/app/(admin)/users/page.tsx` | MODIFIE — filtre URL + banner + Suspense |
| `src/app/(admin)/queues/page.tsx` | MODIFIE — filtre client-side + banner + Suspense |
| `src/app/(admin)/approvals/page.tsx` | MODIFIE — filtre client-side + banner + Suspense |
| `src/app/(admin)/tenants/[id]/page.tsx` | MODIFIE — liens rapides tenant-aware |
| `src/components/layout/Sidebar.tsx` | MODIFIE — version bump v2.2.0 |

---

## 9. Dettes restantes

| Dette | Severite | Description |
|---|---|---|
| Ops non filtrable | Basse | L'API main retourne des agreges globaux sans breakdown tenant |
| Followups non filtrable | Basse | SchedulerReport n'inclut pas `tenantId` dans les items |
| Audit placeholder | Moyenne | Page non connectee aux donnees reelles |
| Billing placeholder | Moyenne | Page non connectee aux donnees reelles |
| AI Control pre-selection URL | Basse | AI Control est tenant-aware via selector mais ne lit pas `?tenantId` depuis l'URL |
| TenantFilterBanner Suspense | Cosmetique | Le composant necessite Suspense car il utilise `useSearchParams()` |

---

## 10. Regles respectees

- [x] Zero hardcodage tenant
- [x] Zero placeholder
- [x] Zero bouton mort
- [x] Zero lien generique trompeur
- [x] Zero action simulee
- [x] GitOps strict (commit → push → build → push → deploy → validate)
- [x] Tags immuables (v2.2.0-ph-admin-87-10b-dev / prod)
- [x] Rollback documente
- [x] DEV puis PROD avec meme discipline
- [x] Validation navigateur reelle (browser-driven)
- [x] DB → API → UI → Navigation prouve
