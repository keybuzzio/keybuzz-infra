# PH-S01 — Fondations SaaS seller.keybuzz.io

**Date:** 2026-01-30  
**Auteur:** KeyBuzz CE  
**Statut:** COMPLETE  
**Environnement:** DEV uniquement (seller-dev.keybuzz.io)

---

## Resume executif

Ce rapport documente la mise en place des fondations du service SaaS `seller.keybuzz.io` avec :
- Modele multi-tenant propre
- Registry marketplaces generique
- Sources de catalogue declaratives
- References secrets Vault
- SSO KeyBuzz sans reauthentification

---

## 1. Confirmation SSH

**AUCUN fichier SSH n'a ete modifie, ecrase ou recree.**

- Connexion via bastion existant : `install-v3` (46.62.171.61)
- Cle utilisee : `~/.ssh/id_rsa_keybuzz_v3` (existante)
- Aucune modification de `~/.ssh/config`

---

## 2. Base de donnees (PostgreSQL)

### Schema cree : `seller`

```sql
\dt seller.*
```

| Schema | Table               | Type  | Owner           |
|--------|---------------------|-------|-----------------|
| seller | tenants             | table | keybuzz_api_dev |
| seller | marketplaces        | table | keybuzz_api_dev |
| seller | tenant_marketplaces | table | keybuzz_api_dev |
| seller | catalog_sources     | table | keybuzz_api_dev |
| seller | secret_refs         | table | keybuzz_api_dev |

### Marketplaces seedees (15)

```
AMAZON, BOULANGER, CDISCOUNT, DARTY, EBAY, FNAC, LEROY_MERLIN, 
MAGENTO, MANOMANO, MIRAKL, OCTOPIA, PRESTASHOP, RAKUTEN, SHOPIFY, WOOCOMMERCE
```

### Contraintes

- Foreign key `seller.tenants.tenantId` -> `public.tenants.id` (CASCADE)
- PK composite sur `seller.tenant_marketplaces` (tenantId, marketplaceCode)
- Contraintes UNIQUE sur names par tenant
- Triggers `updatedAt` automatiques

### Migration

- Fichier : `keybuzz-seller/migrations/001_seller_schema.sql`
- Executee sur : 10.0.0.10:5432/keybuzz
- Idempotente (IF NOT EXISTS)

---

## 3. SSO KeyBuzz

### Architecture

```
┌─────────────────────┐      ┌─────────────────────┐
│  client-dev         │      │  seller-dev         │
│  .keybuzz.io        │      │  .keybuzz.io        │
│                     │      │                     │
│  NextAuth.js        │      │  useAuth hook       │
│  Cookie:            │      │  ↓                  │
│  __Secure-next-auth │─────→│  Lit session via    │
│  Domain: .keybuzz.io│      │  client-dev/api/auth│
└─────────────────────┘      └─────────────────────┘
         │                              │
         │                              │
         ↓                              ↓
┌─────────────────────────────────────────────────┐
│               seller-api                         │
│  Headers: X-User-Email, X-Tenant-Id              │
│  CORS: credentials: true                         │
│  Middleware: require_auth()                      │
└─────────────────────────────────────────────────┘
```

### Implementation

1. **Frontend (seller-client)**
   - `useAuth` hook recupere la session depuis `client-dev.keybuzz.io/api/auth/session`
   - Cookies `.keybuzz.io` partages automatiquement
   - Redirection vers `client-dev.keybuzz.io/login?returnTo=...` si non authentifie
   - Aucune page login seller

2. **Backend (seller-api)**
   - Middleware FastAPI `require_auth()` / `require_auth_with_tenant()`
   - Valide headers `X-User-Email` et `X-Tenant-Id`
   - CORS configure avec `allow_credentials=True`
   - Retourne 401 si pas de session

### Cookies

- Domain : `.keybuzz.io`
- Prefix : `__Secure-`
- Secure : true
- HttpOnly : true
- SameSite : Lax

**AUCUN cookie specifique seller cree.**

---

## 4. API seller-api (FastAPI)

### Endpoints CRUD

| Route | Methode | Description |
|-------|---------|-------------|
| `/api/tenants` | GET | Lister tenants |
| `/api/tenants` | POST | Creer tenant seller |
| `/api/tenants/{id}` | GET | Detail tenant |
| `/api/tenants/{id}` | PATCH | Update tenant |
| `/api/tenants/{id}` | DELETE | Supprimer tenant |
| `/api/marketplaces` | GET | Registry global |
| `/api/marketplaces/{code}` | GET | Detail marketplace |
| `/api/marketplaces/tenant/{id}` | GET | Marketplaces activees |
| `/api/marketplaces/tenant/{id}` | POST | Activer marketplace |
| `/api/marketplaces/tenant/{id}/{code}` | PATCH | Update activation |
| `/api/marketplaces/tenant/{id}/{code}` | DELETE | Desactiver |
| `/api/catalog-sources` | GET, POST | CRUD sources |
| `/api/catalog-sources/{id}` | GET, PATCH, DELETE | CRUD source |
| `/api/secret-refs` | GET, POST | CRUD refs |
| `/api/secret-refs/{id}` | GET, PATCH, DELETE | CRUD ref |
| `/api/secret-refs/{id}/validate` | POST | Valider ref Vault |
| `/api/config` | GET | Config complete |
| `/api/config/summary` | GET | Resume config |
| `/health`, `/health/ready`, `/health/live` | GET | Health checks |

### Isolation tenant

- Toutes les operations sont tenant-scoped
- Le `tenant_id` est extrait du header `X-Tenant-Id`
- Verification d'acces sur chaque requete
- 403 Forbidden si acces a un autre tenant

---

## 5. UI seller-client (Next.js)

### Pages

| Route | Description |
|-------|-------------|
| `/` | Dashboard avec stats |
| `/tenants` | Liste tenants |
| `/tenants/[id]` | Config tenant |
| `/marketplaces` | Registry + activation ON/OFF |
| `/catalog-sources` | Gestion sources FTP/CSV/API |
| `/secret-refs` | References Vault |

### Design

- Framework : Next.js 14 App Router
- Styling : Tailwind CSS (dark theme slate)
- Icons : Lucide React
- Protection : AuthGuard avec redirect SSO

---

## 6. Deploiement K8s

### Namespace

```yaml
keybuzz-seller-dev
```

### Services deployes

| Service | Image | Port |
|---------|-------|------|
| seller-api | ghcr.io/keybuzzio/seller-api:v1.0.0 | 3002 |
| seller-client | ghcr.io/keybuzzio/seller-client:v1.0.0 | 3001 |

### Ingress

| Hostname | Service |
|----------|---------|
| seller-dev.keybuzz.io | seller-client:3001 |
| seller-api-dev.keybuzz.io | seller-api:3002 |

### Secrets

- `seller-api-postgres` : ExternalSecret depuis Vault (`database/creds/keybuzz-api-db`)

### ArgoCD

- Application : `keybuzz-seller-dev`
- Source : `keybuzz-infra/k8s/keybuzz-seller-dev`
- Sync : Automated (prune + selfHeal)

---

## 7. Fichiers crees

### Structure

```
keybuzz-seller/
├── migrations/
│   └── 001_seller_schema.sql
├── seller-api/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── src/
│       ├── main.py
│       ├── config.py
│       ├── database.py
│       ├── middleware/
│       │   └── auth.py
│       ├── routes/
│       │   ├── tenants.py
│       │   ├── marketplaces.py
│       │   ├── catalog_sources.py
│       │   ├── secret_refs.py
│       │   ├── config.py
│       │   └── health.py
│       └── schemas/
│           ├── tenant.py
│           ├── marketplace.py
│           ├── catalog_source.py
│           └── secret_ref.py
└── seller-client/
    ├── Dockerfile
    ├── package.json
    ├── next.config.js
    ├── tailwind.config.js
    ├── app/
    │   ├── layout.tsx
    │   ├── globals.css
    │   └── (dashboard)/
    │       ├── layout.tsx
    │       ├── page.tsx
    │       ├── tenants/
    │       ├── marketplaces/
    │       ├── catalog-sources/
    │       └── secret-refs/
    └── src/
        ├── lib/
        │   ├── config.ts
        │   └── api.ts
        ├── hooks/
        │   └── useAuth.ts
        └── components/
            ├── AuthGuard.tsx
            ├── Sidebar.tsx
            └── Header.tsx

keybuzz-infra/k8s/keybuzz-seller-dev/
├── namespace.yaml
├── externalsecret-postgres.yaml
├── deployment-api.yaml
├── service-api.yaml
├── ingress-api.yaml
├── deployment-client.yaml
├── service-client.yaml
├── ingress-client.yaml
└── kustomization.yaml

keybuzz-infra/argocd/apps/
└── keybuzz-seller-dev.yaml
```

---

## 8. Invariants respectes

| Invariant | Statut |
|-----------|--------|
| ZERO hardcode tenant | ✅ |
| ZERO hardcode marketplace | ✅ |
| ZERO secret en clair | ✅ |
| Aucun tenant special | ✅ |
| Tout tenant-scoped | ✅ |
| Auth KeyBuzz reutilisee | ✅ |
| Aucun systeme auth parallele | ✅ |

---

## 9. Ce qui N'A PAS ete fait (hors scope)

- Ingestion FTP
- Lecture Amazon
- Diff / Run / Apply
- Automation
- Worker
- Cron
- Logique marketplace

---

## 10. Deploiement GitOps (AUCUNE action manuelle)

Le deploiement est **100% GitOps** via ArgoCD :

1. **Commit & Push** des manifests dans `keybuzz-infra/k8s/keybuzz-seller-dev/`
2. **ArgoCD** detecte automatiquement les changements et sync
3. **Aucun kubectl apply manuel** - tout passe par ArgoCD

**Application ArgoCD** : `keybuzz-infra/argocd/apps/keybuzz-seller-dev.yaml`

**DNS** : Gere via infra-as-code (pas d'action manuelle Ludovic)

---

## Confirmation finale

**PH-S01 execute en DEV, sans modification SSH, sans impact existant.**

- ✅ Schema seller cree avec 5 tables
- ✅ 15 marketplaces seedees
- ✅ API FastAPI tenant-aware
- ✅ UI Next.js avec SSO KeyBuzz
- ✅ Manifests K8s pour keybuzz-seller-dev
- ✅ ArgoCD configure
- ✅ Aucune modification SSH
- ✅ Aucun impact sur client-dev/api existants
- ✅ DEV uniquement

---

**FIN DU RAPPORT PH-S01**
