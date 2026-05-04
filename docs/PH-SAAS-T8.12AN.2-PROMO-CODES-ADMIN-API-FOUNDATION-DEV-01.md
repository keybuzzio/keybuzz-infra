# PH-SAAS-T8.12AN.2 — Promo Codes Admin/API Foundation DEV

> **Date** : 4 mai 2026
> **Statut** : DEPLOYE ET VALIDE EN DEV
> **Image** : `ghcr.io/keybuzzio/keybuzz-admin:v2.12.0-promo-codes-foundation-dev`
> **Prerequis** : AN.1 (Stripe TEST behavior proof — COMPLETE)

---

## Resume

Implementaton du systeme de gestion des codes promo KeyBuzz dans Admin V2 DEV :
- **Stripe SDK** integre dans Admin V2 (mode TEST uniquement)
- **Tables DB** `promo_codes` + `promo_code_audit_log` creees automatiquement (pattern `ensureTables`)
- **API routes** CRUD avec auth `super_admin` et validation
- **UI Admin** complete avec tableau, formulaire de creation, vue detail, journal d'audit, et copie de lien promo
- **Audit log** complet pour tracabilite de toutes les operations

---

## Architecture

```
Admin V2 (keybuzz-admin-v2)
  |
  |-- src/lib/stripe.ts            → Client Stripe (sk_test_ only)
  |-- src/config/stripe-products.ts → IDs produits SaaS plans
  |-- src/features/marketing/
  |   |-- types.ts                  → Types TypeScript promo codes
  |   |-- services/promo-codes.service.ts → CRUD DB + Stripe + audit
  |-- src/app/api/admin/marketing/promo-codes/
  |   |-- route.ts                  → GET (list) + POST (create)
  |   |-- [id]/route.ts             → GET (detail)
  |   |-- [id]/archive/route.ts     → POST (archive)
  |-- src/app/(admin)/marketing/promo-codes/page.tsx → UI page
```

### Decision architecturale : tout dans Admin V2

Le systeme de promo codes est implemente directement dans Admin V2 (pas dans keybuzz-api) car :
- Admin V2 a deja ses propres API routes avec acces DB direct via `pg` Pool
- Les operations marketing/admin vivent dans Admin V2
- 1 seul build/deploy au lieu de 2
- Stripe key isolee dans un secret K8s dedie (`keybuzz-admin-v2-stripe`)
- Zero modification de keybuzz-api = zero risque regression

---

## Fichiers crees/modifies

### keybuzz-admin-v2
| Fichier | Action | Description |
|---------|--------|-------------|
| `package.json` | Modifie | Ajoute `stripe@^14.11.0` |
| `Dockerfile` | Modifie | COPY stripe + qs + 18 sous-dependances dans runner stage |
| `src/lib/stripe.ts` | Cree | Client Stripe + `assertTestMode()` securite |
| `src/config/stripe-products.ts` | Cree | IDs produits SaaS plans + lien promo base URL |
| `src/features/marketing/types.ts` | Cree | Types TypeScript |
| `src/features/marketing/services/promo-codes.service.ts` | Cree | Service CRUD complet |
| `src/app/api/admin/marketing/promo-codes/route.ts` | Cree | API GET+POST |
| `src/app/api/admin/marketing/promo-codes/[id]/route.ts` | Cree | API GET detail |
| `src/app/api/admin/marketing/promo-codes/[id]/archive/route.ts` | Cree | API POST archive |
| `src/app/(admin)/marketing/promo-codes/page.tsx` | Cree | Page UI Admin |
| `src/config/navigation.ts` | Modifie | Ajoute entree "Promo Codes" |
| `src/components/layout/Sidebar.tsx` | Modifie | Ajoute icone `Ticket` |

### keybuzz-infra
| Fichier | Action | Description |
|---------|--------|-------------|
| `k8s/keybuzz-admin-v2-dev/deployment.yaml` | Modifie | Ajoute `STRIPE_SECRET_KEY` env var + nouveau tag image |
| `k8s/keybuzz-admin-v2-dev/externalsecret-stripe.yaml` | Cree | Manifest secret Stripe TEST |

---

## Schema DB

### Table `promo_codes`
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID PK | Identifiant unique |
| code | VARCHAR(50) UNIQUE | Code promo (ex: KB-PRO1AN-CONCOURS01) |
| label | VARCHAR(200) | Nom lisible interne |
| campaign | VARCHAR(200) | Identifiant campagne marketing |
| type | VARCHAR(50) | concours / agence / vip / campagne |
| stripe_coupon_id | VARCHAR(100) | ID coupon Stripe |
| stripe_promotion_code_id | VARCHAR(100) | ID promotion code Stripe |
| discount_type | VARCHAR(20) | amount_off / percent_off |
| discount_value | NUMERIC(12,2) | Valeur du discount (cents si amount_off) |
| currency | VARCHAR(3) | eur |
| duration | VARCHAR(20) | once / repeating / forever |
| duration_in_months | INT | Nombre de mois (si repeating) |
| applies_to_products | TEXT[] | IDs produits Stripe SaaS plans |
| max_redemptions | INT | Max utilisations (null = illimite) |
| expires_at | TIMESTAMPTZ | Date d'expiration |
| owner_tenant_id | VARCHAR(100) | Tenant proprietaire (optionnel) |
| active | BOOLEAN | Actif dans Stripe |
| archived_at | TIMESTAMPTZ | Date d'archivage |
| archived_by | VARCHAR(200) | Email de l'archiveur |
| created_by | VARCHAR(200) | Email du createur |
| created_at | TIMESTAMPTZ | Date de creation |
| updated_at | TIMESTAMPTZ | Date de mise a jour |

### Table `promo_code_audit_log`
| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID PK | Identifiant unique |
| promo_code_id | UUID FK | Reference vers promo_codes |
| action | VARCHAR(50) | created / archived / etc. |
| actor_email | VARCHAR(200) | Email de l'acteur |
| detail | JSONB | Details supplementaires |
| created_at | TIMESTAMPTZ | Date de l'action |

---

## Securite

1. **TEST mode only** : `assertTestMode()` refuse toute operation si la cle n'est pas `sk_test_*`
2. **RBAC** : seuls les `super_admin` peuvent creer/archiver des codes promo
3. **Auth** : `getServerSession(authOptions)` verifie la session NextAuth sur chaque endpoint
4. **Audit** : toutes les operations sont tracees dans `promo_code_audit_log`
5. **Secret K8s** : la cle Stripe TEST est injectee via secret K8s, pas hardcodee

---

## Validation DEV

### Tests API (in-pod via kubectl exec)
| Test | Resultat |
|------|----------|
| Tables creees (ensureTables) | OK |
| Coupon Stripe cree (UOKBDJSX) | OK |
| Promotion code Stripe cree (promo_1TTPL5FC0QQLHISR9fyGHHDq) | OK |
| Enregistrement DB (UUID) | OK |
| Audit log created + archived | OK |
| Enrichissement Stripe (times_redeemed) | OK |
| Archivage (Stripe + DB + audit) | OK |

### Tests navigateur (admin-dev.keybuzz.io)
| Test | Resultat |
|------|----------|
| Page /marketing/promo-codes accessible | OK |
| Menu sidebar "Promo Codes" visible (icone Ticket) | OK |
| Tableau avec donnees du test CRUD | OK |
| Vue detail avec toutes les infos | OK |
| Lien promo genere correctement | OK |
| Journal d'audit affiche | OK |
| Auth redirect sans session | OK (307 -> /login) |

---

## Produits SaaS plans Stripe TEST (AN.1)

| Plan | Product ID |
|------|-----------|
| Starter | `prod_TjrtU3R2CeWUTJ` |
| Pro | `prod_TjrtI6NYNyDBbp` |
| Autopilot | `prod_TjrtoaGcUi0yNB` |

`applies_to.products` dans les coupons garantit que les discounts s'appliquent UNIQUEMENT aux plans SaaS, pas aux addons.

---

## Prochaines etapes (AN.3+)

1. **Integration checkout** : modifier `keybuzz-client` pour lire `?promo=CODE` et appliquer le discount lors du checkout Stripe
2. **Dashboard analytics** : tracker les redemptions, taux de conversion par code promo
3. **Promotion PROD** : deployer en PROD avec cle Stripe LIVE (apres validation DEV complete)
4. **Tracking attribution** : lier les codes promo aux sources d'acquisition (Google Ads, TikTok, LinkedIn)

---

## Rollback

```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.35-agency-launch-kit-dev \
  -n keybuzz-admin-v2-dev
```
