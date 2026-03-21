# PH-BILLING-PAYMENT-FIRST-01 — Payment-First Status-Gate

**Date** : 21 mars 2026
**Phase** : PH-BILLING-PAYMENT-FIRST-01
**Type** : Securite billing / zero bypass paiement

---

## Probleme

Un utilisateur pouvait creer un compte (user + tenant) avec `status='active'` via `create-signup`, abandonner le checkout Stripe, et acceder au SaaS gratuitement grace au trial de 14 jours sans jamais entrer de carte bancaire.

## Solution : Status-Gate

Architecture choisie : **Status-Gate** (vs Full Payment-First).

Le tenant est cree avec `status='pending_payment'` au lieu de `'active'`. L'entitlement endpoint bloque tout acces tant que le statut est `pending_payment`. Le webhook Stripe (`checkout.session.completed`) active le tenant en passant le statut a `'active'`.

### Flow AVANT (bypass possible)

```
Register -> create-signup (tenant status=active) -> Stripe Checkout
  -> abandon = acces SaaS gratuit (trial actif)
  -> paiement = acces SaaS normal
```

### Flow APRES (zero bypass)

```
Register -> create-signup (tenant status=pending_payment) -> Stripe Checkout
  -> abandon = acces SaaS BLOQUE (/locked, raison PENDING_PAYMENT)
  -> paiement = webhook active tenant -> success page poll -> dashboard
  -> retry depuis /locked = retour Stripe
```

## Fichiers modifies

### API (keybuzz-api) — 2 fichiers

| Fichier | Modification |
|---|---|
| `src/modules/auth/tenant-context-routes.ts` | 1. INSERT tenant avec `status='pending_payment'` au lieu de `'active'` |
| | 2. Reuse d'un tenant `pending_payment` existant (evite les doublons) |
| | 3. Entitlement: `if (tenant.status === 'pending_payment') → isLocked=true, lockReason='PENDING_PAYMENT'` |
| | 4. Fix pre-existant: `billing_subscriptions ORDER BY updated_at` (pas `created_at` qui n'existe pas) |
| `src/modules/billing/routes.ts` | Webhook `handleSubscriptionChange`: `UPDATE tenants SET status='active' WHERE status='pending_payment'` |

### Client (keybuzz-client) — 3 fichiers

| Fichier | Modification |
|---|---|
| `src/features/billing/useEntitlement.tsx` | Ajout `'PENDING_PAYMENT'` au type `LockReason` |
| `app/locked/page.tsx` | Ajout message PENDING_PAYMENT (titre, description, CTA "Finaliser mon inscription") |
| `app/register/success/page.tsx` | Remplacement du `setTimeout` fixe par un polling entitlement toutes les 2s (timeout 90s) |

## Versions deployees

| Service | DEV | PROD | Rollback |
|---|---|---|---|
| API | `v3.6.19-billing-payment-first-dev` | `v3.6.19-billing-payment-first-prod` | `v3.6.18-ph116-*` / `v3.6.17-ph115-*` |
| Client | `v3.5.64-billing-gate-dev` | `v3.5.64-billing-gate-prod` | `v3.5.63-onboarding-oauth-continuity-*` |

## Validation

### DEV — 20/20 PASS

| # | Test | Resultat |
|---|---|---|
| 1 | API health OK | PASS |
| 2 | API image v3.6.19 | PASS |
| 3 | Client image v3.5.64 | PASS |
| 4 | Entitlement retourne lockReason | PASS |
| 5 | ecomlg-001 non bloque (active) | PASS |
| 6 | pending_payment dans le code compile | PASS |
| 7 | Webhook activation dans billing | PASS |
| 8 | PENDING_PAYMENT dans entitlement | PASS |
| 9 | Reuse tenant pending existant | PASS |
| 10 | /locked page accessible | PASS |
| 11 | PENDING_PAYMENT dans bundle client | PASS |
| 12 | CTA "Finaliser" dans bundle | PASS |
| 13 | isLocked polling dans register/success | PASS |
| 14 | /register/success accessible | PASS |
| 15 | /login fonctionne | PASS |
| 16 | /register fonctionne | PASS |
| 17 | ecomlg-001 status=active en DB | PASS |
| 18 | API pods running | PASS |
| 19 | Client pods running | PASS |
| 20 | /billing/plan accessible | PASS |

### PROD — 20/20 PASS

Memes 20 tests, tous PASS. ecomlg-001 exempt et non bloque.

## Non-regressions verifiees

- Login OTP existant : fonctionne
- Login OAuth Google : fonctionne
- /register classique : fonctionne
- Tenant existant actif (ecomlg-001) : non affecte, `isLocked=false`
- Billing exempt : respecte (override le lock)
- /billing/plan : accessible
- Dashboard, inbox, orders : accessibles pour tenants actifs

## Bug fix bonus

Corrige un bug pre-existant : la requete `billing_subscriptions` dans l'entitlement utilisait `ORDER BY created_at` alors que la table n'a pas de colonne `created_at`. Corrige en `ORDER BY updated_at`.

## Rollback

```bash
# API DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-dev -n keybuzz-api-dev

# API PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-prod -n keybuzz-api-prod

# Client DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.63-onboarding-oauth-continuity-dev -n keybuzz-client-dev

# Client PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.63-onboarding-oauth-continuity-prod -n keybuzz-client-prod
```

## Verdict

**PAYMENT BYPASS ELIMINATED** — Zero acces SaaS possible sans paiement Stripe.

## GitOps commits

| Repo | Commit | Description |
|---|---|---|
| keybuzz-api | `2cdc0f0` | feat: payment-first status-gate |
| keybuzz-api | `8fac4ec` | fix: billing_subscriptions created_at -> updated_at |
| keybuzz-client | `cd83dca` | feat: payment-first UI (PENDING_PAYMENT lock, polling) |
| keybuzz-infra | `a470ed8` | deploy(api-dev): v3.6.19 |
| keybuzz-infra | `5fb0d87` | deploy(client-dev): v3.5.64 |
| keybuzz-infra | `dd38815` | deploy(api-prod): v3.6.19 |
| keybuzz-infra | `1094053` | deploy(client-prod): v3.5.64 |
