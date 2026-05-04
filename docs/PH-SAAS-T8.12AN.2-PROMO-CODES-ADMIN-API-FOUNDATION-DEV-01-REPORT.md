# PH-SAAS-T8.12AN.2 — Promo Codes Admin/API Foundation DEV — RAPPORT FINAL

> **Date** : 4 mai 2026
> **Statut** : DEPLOYE ET VALIDE EN DEV
> **Image** : `ghcr.io/keybuzzio/keybuzz-admin:v2.12.0-promo-codes-foundation-dev`
> **Namespace** : `keybuzz-admin-v2-dev`
> **Impact PROD** : AUCUN — DEV uniquement, Stripe TEST mode

---

## 1. OBJECTIF

Implémenter les fondations du système de codes promo KeyBuzz dans l'Admin V2 DEV :
- Création/archivage de codes promo via Stripe TEST (Coupons + Promotion Codes)
- Persistance DB (tables `promo_codes` + `promo_code_audit_log`)
- API routes protégées (RBAC `super_admin`)
- Page UI complète avec tableau, formulaire de création, vue détail, journal d'audit
- Génération de liens promo (`?promo=CODE`)
- Sécurité : `assertTestMode()` bloque toute opération si clé Stripe LIVE détectée

---

## 2. ARCHITECTURE

Tout est implémenté dans `keybuzz-admin-v2` (pas de modification de `keybuzz-api`) :

```
keybuzz-admin-v2/
├── src/
│   ├── lib/stripe.ts                     # Stripe SDK init + assertTestMode()
│   ├── config/stripe-products.ts         # Product IDs SaaS plans
│   ├── features/marketing/
│   │   ├── types.ts                      # Interfaces TypeScript
│   │   └── services/
│   │       └── promo-codes.service.ts    # CRUD DB + Stripe + audit log
│   ├── app/
│   │   ├── api/admin/marketing/promo-codes/
│   │   │   ├── route.ts                  # GET (list) + POST (create)
│   │   │   └── [id]/
│   │   │       ├── route.ts              # GET (detail)
│   │   │       └── archive/route.ts      # POST (archive)
│   │   └── (admin)/marketing/promo-codes/
│   │       └── page.tsx                  # UI page complète (list/create/detail)
│   └── components/layout/Sidebar.tsx     # Ticket icon ajouté
│       config/navigation.ts              # "Promo Codes" dans Marketing
└── Dockerfile                            # stripe + qs + transitive deps
```

---

## 3. TABLES DB

### `promo_codes`
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID PK | ID unique |
| code | VARCHAR(50) UNIQUE | Code promo (ex: `KB-PRO1AN-CONCOURS01`) |
| label | VARCHAR(200) | Nom interne lisible |
| campaign | VARCHAR(200) | Tag campagne marketing |
| type | VARCHAR(50) | `concours` / `agence` / `vip` / `campagne` |
| stripe_coupon_id | VARCHAR(100) | ID Coupon Stripe |
| stripe_promotion_code_id | VARCHAR(100) | ID Promotion Code Stripe |
| discount_type | VARCHAR(20) | `amount_off` / `percent_off` |
| discount_value | NUMERIC(12,2) | Valeur du discount (centimes pour amount_off) |
| currency | VARCHAR(3) | `eur` |
| duration | VARCHAR(20) | `once` / `repeating` / `forever` |
| duration_in_months | INT | Nombre de mois si repeating |
| applies_to_products | TEXT[] | Product IDs Stripe ciblés |
| max_redemptions | INT | Limite d'utilisations |
| expires_at | TIMESTAMPTZ | Date d'expiration |
| owner_tenant_id | VARCHAR(100) | Tenant propriétaire (agence/partenaire) |
| active | BOOLEAN | Statut actif/inactif |
| archived_at | TIMESTAMPTZ | Date d'archivage |
| archived_by | VARCHAR(200) | Email de l'admin qui a archivé |
| created_by | VARCHAR(200) | Email de l'admin créateur |
| created_at | TIMESTAMPTZ | Date de création |

### `promo_code_audit_log`
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID PK | ID unique |
| promo_code_id | UUID FK | Référence vers promo_codes |
| action | VARCHAR(50) | `created` / `archived` |
| actor_email | VARCHAR(200) | Email de l'acteur |
| detail | JSONB | Détails de l'action |
| created_at | TIMESTAMPTZ | Timestamp |

Tables créées automatiquement via `ensureTables()` (pattern `CREATE TABLE IF NOT EXISTS`).

---

## 4. API ROUTES

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/api/admin/marketing/promo-codes` | super_admin | Liste tous les codes (enrichis Stripe) |
| POST | `/api/admin/marketing/promo-codes` | super_admin | Crée coupon + promo code Stripe + DB |
| GET | `/api/admin/marketing/promo-codes/:id` | super_admin | Détail + journal d'audit |
| POST | `/api/admin/marketing/promo-codes/:id/archive` | super_admin | Désactive Stripe + archive DB |

---

## 5. UI ADMIN

### Page `/marketing/promo-codes`
- **Vue liste** : tableau avec Code, Label, Type, Discount, Durée, Utilisations, Statut, Actions
- **Vue création** : formulaire complet (code, label, type, campagne, discount, durée, limites)
- **Vue détail** : toutes les infos + IDs Stripe + lien promo copiable + journal d'audit
- **Actions** : copier lien promo, voir détail, archiver (avec confirmation)
- **Navigation** : icône Ticket dans la sidebar, section Marketing, RBAC super_admin

---

## 6. STRIPE PRODUCTS CIBLÉS

| Product | Stripe ID |
|---------|-----------|
| Starter | `prod_TjrtU3R2CeWUTJ` |
| Pro | `prod_TjrtI6NYNyDBbp` |
| Autopilot | `prod_TjrtoaGcUi0yNB` |

Les discounts s'appliquent uniquement aux plans SaaS. Les addons (Agent KeyBuzz, Canaux) sont automatiquement exclus.

---

## 7. SÉCURITÉ

1. **`assertTestMode()`** : vérifie que `STRIPE_SECRET_KEY` commence par `sk_test_`. Refuse toute mutation sinon.
2. **RBAC** : toutes les routes exigent le rôle `super_admin` via NextAuth session.
3. **Audit log** : chaque action (create, archive) est journalisée avec l'email de l'admin et les détails.
4. **Secret K8s** : `keybuzz-admin-v2-stripe` (créé manuellement, `optional: true` dans le deployment).

---

## 8. COMMITS

### keybuzz-admin-v2
```
22a268e fix: add qs + transitive deps for stripe SDK in Dockerfile
c8005db fix: use Stripe typed params for coupon/promotion code creation
17863cb chore: update lockfile for stripe dependency
58eb3fd PH-SAAS-T8.12AN.2: Promo Codes Admin Foundation DEV
```

### keybuzz-infra
```
28fecef PH-SAAS-T8.12AN.2: Final deployment report
3efea87 PH-SAAS-T8.12AN.2: Admin V2 DEV deployment — add Stripe secret + image tag
```

---

## 9. VALIDATION

### API (in-pod CRUD test)
- `ensureTables()` : tables créées
- Stripe coupon create : `UOKBDJSX`
- Stripe promotion code create : `promo_1TTPL5FC0QQLHISr9fyGHHDq`
- DB insert : `AN2-VALIDATION-TEST01`
- Audit log : 2 entrées (created + archived)
- Archive : Stripe promo code désactivé + DB updated

### UI (navigateur)
- Login admin : OK (ludovic@keybuzz.pro)
- Page `/marketing/promo-codes` : tableau affiché avec données
- Vue détail : toutes les infos + IDs Stripe + lien promo + audit log
- Navigation sidebar : "Promo Codes" visible et actif
- Non-régression : Campaign QA et autres pages marketing fonctionnelles

---

## 10. ROLLBACK

```bash
# En cas de problème
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-dev \
  -n keybuzz-admin-v2-dev
```

---

## 11. PROCHAINES ÉTAPES (hors scope AN.2)

1. **AN.3** : Formulaire de création UI end-to-end (créer un vrai code depuis le navigateur)
2. **AN.4** : Intégration côté client (`/register?promo=CODE` → apply promo code au checkout Stripe)
3. **AN.5** : Dashboard analytics promo codes (redemptions, conversion, revenus)
4. **AN.6** : Promotion PROD (clé Stripe LIVE, deployment prod)
