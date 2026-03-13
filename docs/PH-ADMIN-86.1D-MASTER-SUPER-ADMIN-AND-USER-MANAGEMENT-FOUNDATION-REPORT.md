# PH-ADMIN-86.1D — Master Super Admin + User Management Foundation

**Date** : 2026-03-13
**Statut** : Terminé (DEV + PROD)
**Auteur** : Cursor Executor

---

## 1. Objectif

Créer le compte personnel maître de Ludovic (`ludovic@keybuzz.pro`) et poser la fondation du User Management pour l'Admin v2.

---

## 2. Architecture retenue

### Base de données PostgreSQL

3 tables créées dans les bases DEV (`keybuzz`) et PROD (`keybuzz_prod`) :

| Table | Rôle |
|---|---|
| `admin_users` | Comptes admin (id UUID, email, password_hash, role, is_active, must_set_password, timestamps) |
| `admin_user_tenants` | Mapping N-N utilisateurs ↔ tenants (user_id → tenant_id) |
| `admin_setup_tokens` | Tokens de configuration mot de passe (SHA-256 hashé, expiration 24h, usage unique) |

Indexes : `idx_admin_users_email`, `idx_admin_setup_tokens_hash`, `idx_admin_user_tenants_user`

### Connexion DB depuis Admin v2

- Module `src/lib/db.ts` : Pool PostgreSQL (max 5 connexions, timeout 5s)
- Credentials via Vault + ESO (aucun hardcodage)
- Vault paths : `keybuzz/admin-v2/postgres` (DEV), `keybuzz/admin-v2/postgres-prod` (PROD)
- ExternalSecrets : `keybuzz-admin-v2-postgres` dans les deux namespaces

---

## 3. Compte maître

| Champ | DEV | PROD |
|---|---|---|
| Email | ludovic@keybuzz.pro | ludovic@keybuzz.pro |
| Rôle | super_admin | super_admin |
| ID | 1f123832-446d-4baa-81b0-c1d3ca96a6ec | 08e0dcaa-37d8-4f02-8e69-a987bbe99a8d |
| Créé par | system-bootstrap | system-bootstrap |
| Statut | Actif, mot de passe configuré | Actif, en attente de configuration |

---

## 4. Flow "Set Password"

### Processus

1. Le compte est créé avec `must_set_password = true` et `password_hash = NULL`
2. Un token de setup est généré (UUID v4), hashé en SHA-256, stocké dans `admin_setup_tokens`
3. L'URL `/set-password?token=<raw_token>` est communiquée à l'utilisateur
4. L'utilisateur visite l'URL, entre et confirme son mot de passe (min 10 caractères)
5. Le mot de passe est hashé en bcrypt (cost 12) et stocké dans `admin_users.password_hash`
6. Le token est marqué comme utilisé (`used_at = NOW()`)
7. L'utilisateur peut se connecter via `/login`

### Sécurité

- Token : SHA-256 hashé en base, le plaintext n'est jamais stocké
- Expiration : 24h
- Usage unique : invalidé après utilisation
- Mot de passe : bcrypt cost 12, minimum 10 caractères
- Confirmation obligatoire avant soumission

---

## 5. Authentification renforcée

### NextAuth mis à jour (`src/lib/auth.ts`)

Deux sources d'authentification en cascade :

1. **Utilisateurs DB** (`admin_users`) — source principale
   - Vérifie : email trouvé, compte actif, `password_hash` existant, `must_set_password = false`
   - Enregistre `last_login_at` à chaque connexion
2. **Bootstrap Vault** — fallback de secours
   - Même mécanisme que PH86.1B (env vars `ADMIN_BOOTSTRAP_*`)
   - Conservé comme break-glass account

### Middleware

Routes publiques ajoutées : `/set-password`, `/api/admin/set-password`

---

## 6. API Routes

| Méthode | Endpoint | Auth | Rôle requis |
|---|---|---|---|
| GET | `/api/admin/users` | Oui | super_admin |
| POST | `/api/admin/users` | Oui | super_admin |
| GET | `/api/admin/users/[id]` | Oui | super_admin |
| PUT | `/api/admin/users/[id]` | Oui | super_admin |
| POST | `/api/admin/setup-token` | Oui | super_admin |
| POST | `/api/admin/set-password` | Non | Token valide |
| GET | `/api/admin/set-password?token=X` | Non | — |

---

## 7. RBAC

Hiérarchie de rôles centralisée (`src/features/users/constants.ts`) :

1. `super_admin` — Accès total
2. `ops_admin` — Opérations
3. `account_manager` — Gestion comptes
4. `support_agent` — Support
5. `viewer` — Lecture seule

Source typée unique, jamais hardcodée dans les composants.

---

## 8. Pages UI

| Page | Description |
|---|---|
| `/users` | Liste des utilisateurs avec statut (actif/inactif/en attente), rôle, dernière connexion |
| `/users` (create) | Formulaire inline de création d'utilisateur avec sélection de rôle |
| `/set-password` | Page publique de configuration de mot de passe (token-based) |
| `/settings/profile` | Mise à jour pour afficher les données réelles du compte connecté |

Navigation sidebar mise à jour avec section "Administration" contenant "Utilisateurs".

---

## 9. Infrastructure

### Vault

| Path | Environnement | Contenu |
|---|---|---|
| `keybuzz/admin-v2/postgres` | DEV | PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD |
| `keybuzz/admin-v2/postgres-prod` | PROD | PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD |

### External Secrets

| Namespace | Nom | Status |
|---|---|---|
| keybuzz-admin-v2-dev | keybuzz-admin-v2-postgres | SecretSynced |
| keybuzz-admin-v2-prod | keybuzz-admin-v2-postgres | SecretSynced |

### Docker images

| Env | Tag |
|---|---|
| DEV | `v0.5.0-ph86.1d-user-management-dev` |
| PROD | `v0.5.0-ph86.1d-user-management-prod` |

### Dépendances ajoutées

- `pg` ^8.13.1 (PostgreSQL client)
- `@types/pg` ^8.11.10

---

## 10. Tests et preuves

### DEV

- Login `ludovic@keybuzz.pro` : HTTP 200
- Session JWT : `{"name":"ludovic","email":"ludovic@keybuzz.pro","role":"super_admin"}`
- Users API (authentifié) : retourne les données du compte maître
- Token validation (valide) : `{"valid":true}`
- Token validation (fake) : `{"valid":false}`
- Token re-validation (après usage) : `{"valid":false}` — usage unique confirmé
- Set password : `{"success":true}`
- DB state post-setup : `must_set_password: false`, `has_password: true`

### PROD

- admin.keybuzz.io/login : HTTP 200
- admin.keybuzz.io/set-password : HTTP 200
- admin.keybuzz.io/users (no auth) : HTTP 307 (redirect login)

### Non-régression

- client-dev.keybuzz.io : HTTP 307 (OK)
- client.keybuzz.io : HTTP 307 (OK)

---

## 11. GitOps

### keybuzz-admin-v2

Commit `e37ce7e` — 19 fichiers, +1177 / -115 lignes

### keybuzz-infra

Commit `6351f15` — 5 fichiers (deployments + ESO manifests)

---

## 12. Bootstrap existant

Le bootstrap technique (env vars `ADMIN_BOOTSTRAP_*`) est conservé comme fallback.
Il sera évalué pour désactivation dans une phase ultérieure, une fois le compte maître pleinement validé par Ludovic.

---

## 13. Setup URLs

### DEV

Mot de passe déjà configuré.

### PROD

URL de configuration (expire le 14 mars 2026, usage unique) :

```
https://admin.keybuzz.io/set-password?token=bfa9a920-7218-4d01-9d74-ea738b4dbaf4
```

---

## 14. Fichiers modifiés/créés

### Admin v2 (keybuzz-admin-v2)

- `src/lib/db.ts` — Module PostgreSQL
- `src/lib/auth.ts` — NextAuth DB + bootstrap
- `src/middleware.ts` — Routes publiques set-password
- `src/features/users/types.ts` — Types utilisateurs
- `src/features/users/constants.ts` — Rôles, labels
- `src/features/users/services/users.service.ts` — CRUD + tokens
- `src/app/api/admin/users/route.ts` — GET/POST users
- `src/app/api/admin/users/[id]/route.ts` — GET/PUT user
- `src/app/api/admin/setup-token/route.ts` — Génération token
- `src/app/api/admin/set-password/route.ts` — Set password
- `src/app/(auth)/set-password/page.tsx` — Page set-password
- `src/app/(admin)/users/page.tsx` — Liste utilisateurs
- `src/app/(admin)/settings/profile/page.tsx` — Profil mis à jour
- `src/config/navigation.ts` — Section Administration
- `src/components/layout/Sidebar.tsx` — Icône Users
- `package.json` — pg + @types/pg
- `Dockerfile` — COPY pg modules
- `next.config.mjs` — outputFileTracingIncludes pg

### Infrastructure (keybuzz-infra)

- `k8s/keybuzz-admin-v2-dev/deployment.yaml` — Tag + PG env vars
- `k8s/keybuzz-admin-v2-dev/externalsecret-postgres.yaml` — ESO DEV
- `k8s/keybuzz-admin-v2-prod/deployment.yaml` — Tag + PG env vars
- `k8s/keybuzz-admin-v2-prod/externalsecret-postgres.yaml` — ESO PROD
