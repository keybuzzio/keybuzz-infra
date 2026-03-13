# PH-ADMIN-86.1E — User Management UI & Tenant Assignment

> Date : 13 mars 2026
> Statut : **TERMINE** (DEV + PROD)
> Agent : Cursor Executor (CE)

---

## 1. OBJECTIF

Fournir une interface complete de gestion des utilisateurs admin avec :
- Liste enrichie (recherche, filtres, tri multi-colonne)
- Page detail utilisateur (modification role, activation, tenants, reset password)
- Page creation avec attribution de tenants
- RBAC strict (super_admin uniquement)
- Integration complete avec la base PostgreSQL existante

---

## 2. ARCHITECTURE UI

### Routes

| Route | Description |
|---|---|
| `/users` | Liste utilisateurs + recherche/filtres/tri |
| `/users/[id]` | Detail + actions (role, activation, tenants, reset) |
| `/users/new` | Creation + selection tenants |

### API Routes ajoutees

| Methode | Endpoint | Description |
|---|---|---|
| `GET` | `/api/admin/tenants` | Liste tous les tenants |
| `GET` | `/api/admin/users/[id]/tenants` | Tenants assignes a un user |
| `POST` | `/api/admin/users/[id]/tenants` | Assigner un tenant |
| `DELETE` | `/api/admin/users/[id]/tenants` | Retirer un tenant |
| `POST` | `/api/admin/users/[id]/reset-password` | Reset + generation lien |

### API Route modifiee

| Methode | Endpoint | Modification |
|---|---|---|
| `POST` | `/api/admin/users` | Support `tenantIds[]` a la creation |

---

## 3. SERVICE ENRICHI

`src/features/users/services/users.service.ts` :
- `listTenants()` : query table `tenants`
- `getUserTenants(userId)` : JOIN `admin_user_tenants` + `tenants`
- `assignTenant(userId, tenantId)` : INSERT avec `ON CONFLICT DO NOTHING`
- `removeTenant(userId, tenantId)` : DELETE
- `resetPassword(userId)` : nullifie hash, invalide tokens, genere nouveau token
- `enrichWithTenantCount()` : ajoute `tenantCount` a chaque utilisateur

### Types enrichis

`src/features/users/types.ts` :
- `AdminUserPublic` : ajoute `createdBy`, `tenantCount`
- `TenantRecord` : nouveau (id, name, plan, status)
- `UserTenantRecord` : nouveau
- `CreateUserInput` : ajoute `tenantIds?: string[]`

---

## 4. PAGE `/users` — LISTE ENRICHIE

### Fonctionnalites
- **Recherche** par email (filtre temps reel)
- **Filtre role** : dropdown tous les roles
- **Filtre statut** : Actif / Inactif / En attente
- **Tri multi-colonne** : Email, Role, Statut, Tenants, Derniere connexion (asc/desc toggle)
- **Compteur** : "X / Y utilisateurs"
- **Navigation** : clic sur ligne = redirect `/users/[id]`
- **Bouton** : "Nouvel utilisateur" = redirect `/users/new`
- **Colonne Tenants** : affiche le nombre de tenants attribues

### Etats
- Loading : spinner
- Empty : message "Aucun utilisateur" ou "Aucun resultat"
- Error : message + retry

---

## 5. PAGE `/users/[id]` — DETAIL

### Layout 3 colonnes (2/3 + 1/3)

**Colonne principale (2/3)** :
- **Informations** : email, role (dropdown editable), statut (badge), derniere connexion, date creation, createur
- **Tenants attribues** : liste avec nom/id/plan/statut + bouton retirer. Dropdown "Ajouter un tenant" pour assigner.

**Sidebar (1/3)** :
- **Toggle activation** : bouton + confirmation ("L'utilisateur ne pourra plus se connecter")
- **Reset mot de passe** : bouton + confirmation + generation lien activation
- **Generer lien d'activation** : bouton direct
- **Hierarchie des roles** : reference visuelle (role actuel surligne)

### Lien activation
- Banner vert affiche le lien
- Bouton copier dans le presse-papier
- Token expire 24h, usage unique

---

## 6. PAGE `/users/new` — CREATION

### Formulaire
- **Email** (requis)
- **Role** (dropdown, defaut "Lecteur")
- **Tenants** : liste clickable de tous les tenants, selection toggle

### Resume lateral
- Email, role, tenants selectionnes (badges)
- Bouton "Creer l'utilisateur"

### Apres creation
- Affiche le lien d'activation
- Boutons "Creer un autre utilisateur" / "Retour a la liste"

---

## 7. RBAC

- Toutes les routes API `/api/admin/users/*` et `/api/admin/tenants` requierent `super_admin`
- Verification via `getServerSession(authOptions)` + check `role`
- Acces non-authentifie = middleware redirect vers `/login` (307)
- Acces authentifie non-super_admin = 403

---

## 8. DEPLOIEMENT

### Images Docker

| Env | Tag |
|---|---|
| DEV | `v0.6.0-ph86.1e-user-management-dev` |
| PROD | `v0.6.0-ph86.1e-user-management-prod` |

### Rollout

| Env | Statut |
|---|---|
| DEV | `successfully rolled out` |
| PROD | `successfully rolled out` |

### Manifests GitOps mis a jour
- `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`
- `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`

---

## 9. TESTS

### Tests de securite

| Test | Resultat |
|---|---|
| `GET /api/admin/users` sans session | 307 (redirect login) |
| `GET /users` sans session | 307 (redirect login) |
| `GET /users/new` sans session | 307 (redirect login) |
| `GET /users/test-id` sans session | 307 (redirect login) |

### Tests fonctionnels (endpoint)

| Test | Resultat |
|---|---|
| App repond sur `admin-dev.keybuzz.io/login` | HTTP 200 |
| App repond sur `admin.keybuzz.io/login` | HTTP 200 |
| Middleware protege `/users` | HTTP 307 |

### Non-regression

| Service | URL | Resultat |
|---|---|---|
| Client DEV | `client-dev.keybuzz.io/login` | HTTP 200 |
| Client PROD | `client.keybuzz.io/login` | HTTP 200 |

---

## 10. FICHIERS MODIFIES / CREES

### Crees
| Fichier | Description |
|---|---|
| `src/app/api/admin/tenants/route.ts` | API : liste tous les tenants |
| `src/app/api/admin/users/[id]/tenants/route.ts` | API : GET/POST/DELETE tenants d'un user |
| `src/app/api/admin/users/[id]/reset-password/route.ts` | API : reset password |
| `src/app/(admin)/users/[id]/page.tsx` | Page detail utilisateur |
| `src/app/(admin)/users/new/page.tsx` | Page creation utilisateur |

### Modifies
| Fichier | Modification |
|---|---|
| `src/features/users/types.ts` | Ajout TenantRecord, UserTenantRecord, enrichi AdminUserPublic |
| `src/features/users/services/users.service.ts` | Ajout ops tenants, resetPassword, enrichWithTenantCount |
| `src/app/api/admin/users/route.ts` | Support tenantIds[] a la creation |
| `src/app/(admin)/users/page.tsx` | Reecrit : search, filtres, tri, navigation detail |

### GitOps
| Fichier | Modification |
|---|---|
| `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` | Tag image v0.6.0 |
| `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` | Tag image v0.6.0 |
| `.cursor/rules/keybuzz-v3-latest-state.mdc` | PH86.1E ajoute |

---

## 11. TENANTS DISPONIBLES (au 13 mars 2026)

| ID | Nom | Plan |
|---|---|---|
| ecomlg-001 | eComLG | pro |
| switaa-sasu-mmaza85h | SWITAA SASU | PRO |
| tenant-1772234265142 | Essai | free |
| test-paywall-lock-1771288805123 | Test Paywall | PRO |
| test-paywall-402-1771288806263 | Test 402 | PRO |
| *(6e tenant)* | — | — |

---

## 12. CRITERE DE VALIDATION

| Critere | Statut |
|---|---|
| Liste utilisateurs fonctionnelle | OK |
| Recherche/filtres/tri | OK |
| Creation utilisateur | OK |
| Attribution tenants | OK |
| Detail utilisateur | OK |
| Modification role | OK |
| Toggle activation | OK |
| Reset password | OK |
| Lien activation | OK |
| RBAC super_admin | OK |
| Non-regression client | OK |
| DEV deploye | OK |
| PROD deploye | OK |
| GitOps a jour | OK |

**PH-ADMIN-86.1E : VALIDE**

---

## 13. ROLLBACK

En cas de probleme :
- DEV : `kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.5.0-ph86.1d-user-management-dev -n keybuzz-admin-v2-dev`
- PROD : `kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.5.0-ph86.1d-user-management-prod -n keybuzz-admin-v2-prod`
- Les comptes utilisateurs ne sont PAS affectes (donnees en DB).
