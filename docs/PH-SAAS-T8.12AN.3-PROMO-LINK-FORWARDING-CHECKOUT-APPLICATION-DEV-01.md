# PH-SAAS-T8.12AN.3 — Promo Link Forwarding & Checkout Application DEV

**Date** : 2026-05-04
**Auteur** : Agent Cursor (CE)
**Environnement** : DEV uniquement
**Verdict** : **GO DEV LINK CHECKOUT READY**

---

## Objectif

Brancher en DEV les liens promo generés par l'Admin (AN.2) sur le vrai parcours signup/checkout :
```
Lien promo Admin → Website /pricing?promo=CODE → Client /register?promo=CODE
→ API checkout → Stripe Checkout avec discounts[] pre-applique
```

## Sources relues

| Document | Lu |
|---------|-----|
| CE_PROMPTING_STANDARD.md | Oui |
| RULES_AND_RISKS.md | Oui |
| PH-SAAS-T8.12AN-PROMO-CODES-LINKS-ATTRIBUTION-AND-STRIPE-TRUTH-AUDIT-01.md | Oui |
| PH-SAAS-T8.12AN.1-STRIPE-DEV-PROMO-COUPON-TRIAL-UPGRADE-BEHAVIOR-PROOF-01.md | Oui |
| PH-SAAS-T8.12AN.2-PROMO-CODES-ADMIN-API-FOUNDATION-DEV-01-REPORT.md | Oui |
| PH-WEBSITE-T8.11AK-PRICING-ATTRIBUTION-FORWARDING-CLOSURE-01.md | Oui |
| PH138-K-STRIPE-CHECKOUT-ENFORCEMENT-FINAL-01-REPORT.md | Oui |
| PH-T8.4.1-STRIPE-REAL-VALUE-01.md | Oui |

## Preflight

| Repo | Branche | HEAD avant | Dirty | Verdict |
|------|---------|-----------|-------|---------|
| keybuzz-api (bastion) | ph147.4/source-of-truth | 6511ed7c | Non | OK |
| keybuzz-client (bastion) | ph148/onboarding-activation-replay | b2bba25 | Non | OK |
| keybuzz-admin-v2 | main | 22a268e | Non | OK |
| keybuzz-infra | main | bc4bffd | Untracked docs | OK |
| keybuzz-website | main | 0b9d1ea | Non | OK |

| Service | DEV image avant | PROD image (inchangee) |
|---------|----------------|----------------------|
| API | v3.5.150-amazon-inbound-visible-dev | v3.5.139-amazon-oauth-inbound-bridge-prod |
| Client | v3.5.154-amazon-inbound-visible-ux-dev | v3.5.151-amazon-oauth-inbound-bridge-prod |
| Website | v0.6.7-pricing-attribution-forwarding-dev | v0.6.8-tiktok-browser-pixel-prod |
| Admin | v2.12.0-promo-codes-foundation-dev | aucune |

## Patches appliques

### 1. Website — promo forwarding (keybuzz-website)

**Fichier** : `src/app/pricing/page.tsx` (ligne 275)
**Commit** : `7fc942b` on `main`

Ajout de `"promo"` au tableau `utmKeys` existant. Le mécanisme `utmSuffix` existant s'applique automatiquement.

```
Avant : [..., "li_fat_id", "_gl"]
Apres : [..., "li_fat_id", "_gl", "promo"]
```

| Parametre | Forwarde |
|-----------|---------|
| promo | Oui (nouveau) |
| utm_source/medium/campaign/term/content | Oui |
| gclid/fbclid/ttclid/li_fat_id/_gl | Oui |
| marketing_owner_tenant_id | Oui |

### 2. Client — register capture + BFF forward

**Fichiers** :
- `app/register/page.tsx` — capture `promo` via `searchParams.get('promo')`, passe au checkout BFF
- `app/api/billing/checkout-session/route.ts` — forward `promo` vers l'API
- `src/lib/attribution.ts` — ajout `promo: string | null` a `AttributionContext`

**Commit** : `b0968c6` on `ph148/onboarding-activation-replay`

| Donnee | Capturee | Persistee flow | Envoyee checkout |
|--------|---------|---------------|-----------------|
| promo | Oui (searchParams) | Oui (attribution) | Oui (body.promo) |
| plan | Oui | Oui | Oui |
| cycle | Oui | Oui | Oui |
| UTMs | Oui | Oui (attribution) | Oui (via attribution) |
| marketing_owner_tenant_id | Oui | Oui | Oui |

### 3. API — promo validation + discounts[]

**Fichier** : `src/modules/billing/routes.ts`
**Commit** : `a81d90c3` on `ph147.4/source-of-truth`

Logique ajoutee dans `POST /billing/checkout-session` :

1. Si `promo` fourni :
   - Recherche dans `promo_codes` table (UPPER match)
   - Verification : code existe, active=true, archived_at IS NULL
   - Verification Stripe : `stripe.promotionCodes.retrieve()` → active=true
   - Session avec `discounts: [{ promotion_code: stripePromotionCodeId }]`
   - `allow_promotion_codes` NON passe (mutuellement exclusif)
   - Metadata Stripe enrichie : `promo_code`, `keybuzz_promo_code_id`, `stripe_promotion_code_id`, `promo_discount_type`, `promo_discount_value`

2. Si pas de promo :
   - Comportement existant inchange (`allow_promotion_codes: true`)

| Cas | Comportement |
|-----|-------------|
| no promo | allow_promotion_codes: true (existant) |
| promo active | discounts[] avec promotion_code, metadata enrichie |
| promo archived | 400 PROMO_ARCHIVED |
| promo unknown | 400 PROMO_UNKNOWN |
| promo Stripe inactive | 400 PROMO_STRIPE_INACTIVE |
| promo max redemption reached | Gere par Stripe (erreur Stripe) |

### 4. Admin link generator

Deja fonctionnel depuis AN.2 : `PROMO_LINK_BASE_URL + ?promo=CODE`

- DEV : `https://client-dev.keybuzz.io/register?promo=CODE`
- PROD (non promu) : `https://client.keybuzz.io/register?promo=CODE`

### 5. Attribution / DB

**Decision** : Option C — reporter a AN.4.

Le promo code est stocke dans les **metadata Stripe** de la session Checkout :
- `promo_code` : code en clair
- `keybuzz_promo_code_id` : UUID DB
- `stripe_promotion_code_id` : ID Stripe
- `promo_discount_type` : type de discount
- `promo_discount_value` : valeur

La table `signup_attribution` n'est pas modifiee (pas de colonne `promo_code` ajoutee).
C'est suffisant comme source de verite car Stripe est la seule source financiere.

## Builds et deploys

| Service | Commit | Image | Rollback DEV |
|---------|--------|-------|-------------|
| API | a81d90c3 | ghcr.io/keybuzzio/keybuzz-api:v3.5.151-promo-checkout-dev | v3.5.150-amazon-inbound-visible-dev |
| Client | b0968c6 | ghcr.io/keybuzzio/keybuzz-client:v3.5.155-promo-register-dev | v3.5.154-amazon-inbound-visible-ux-dev |
| Website | 7fc942b | ghcr.io/keybuzzio/keybuzz-website:v0.6.8-promo-forwarding-dev | v0.6.7-pricing-attribution-forwarding-dev |

## GitOps DEV

| Manifest | Ancienne image | Nouvelle image | Commit infra |
|----------|---------------|---------------|-------------|
| k8s/keybuzz-api-dev/deployment.yaml | v3.5.150-amazon-inbound-visible-dev | v3.5.151-promo-checkout-dev | 2a7ddd3 |
| k8s/keybuzz-client-dev/deployment.yaml | v3.5.154-amazon-inbound-visible-ux-dev | v3.5.155-promo-register-dev | 2a7ddd3 |
| k8s/website-dev/deployment.yaml | v0.6.7-pricing-attribution-forwarding-dev | v0.6.8-promo-forwarding-dev | 2a7ddd3 |

Verification : manifest = runtime = annotation ✓

## Tests E2E (Stripe TEST)

Promo code utilise : `AN3-E2E-TEST-PRO` (coupon `9eNxNLWm`, promotion code `promo_1TTS6FFC0QQLHISRHtmY12Vp`)

| Test | Attendu | Resultat |
|------|---------|---------|
| A — PRO annual + promo valid | 200 + Stripe URL avec discounts[] | ✓ 200 + URL |
| B — AUTOPILOT annual + promo valid | 200 + Stripe URL avec discounts[] | ✓ 200 + URL |
| C — promo inconnu (FAKE-CODE-123) | 400 erreur claire | ✓ 400 PROMO_UNKNOWN |
| D — promo archive (AN2-VALIDATION-TEST01) | 400 erreur claire | ✓ 400 PROMO_ARCHIVED |
| E — sans promo (baseline) | 200 + URL, allow_promotion_codes | ✓ 200 + URL |

## Non-regression

| Surface | Resultat |
|---------|---------|
| API DEV /health | ✓ OK |
| API DEV billing/current | ✓ 200 |
| Client DEV /register | ✓ 200 |
| Client DEV /dashboard | ✓ 307 (redirect auth) |
| Client DEV /inbox | ✓ 307 (redirect auth) |
| Admin DEV /promo-codes | ✓ 307 (redirect auth) |
| Admin DEV /campaign-qa | ✓ 307 (redirect auth) |
| API PROD health | ✓ OK (inchangé) |
| API PROD image | ✓ v3.5.139-amazon-oauth-inbound-bridge-prod |
| Client PROD image | ✓ v3.5.151-amazon-oauth-inbound-bridge-prod |
| Website PROD image | ✓ v0.6.8-tiktok-browser-pixel-prod |
| Aucun fake tracking event | ✓ |
| Aucun CAPI/GA4/TikTok/Meta/LinkedIn | ✓ |

## PROD inchangee

Aucune modification PROD. Toutes les baselines preservees :
- API PROD : v3.5.139-amazon-oauth-inbound-bridge-prod
- Client PROD : v3.5.151-amazon-oauth-inbound-bridge-prod
- Backend PROD : v1.0.42-amazon-oauth-inbound-bridge-prod (non touche)
- Admin PROD : pas deploye
- Website PROD : v0.6.8-tiktok-browser-pixel-prod

## Gaps pour AN.4

| Gap | Phase | Bloquant PROD |
|-----|-------|--------------|
| E2E concours complet avec signup DEV controle | AN.4 | Non |
| signup_attribution DB: colonne promo_code | AN.4 | Non (metadata Stripe suffit) |
| Usage reporting (times_redeemed compteurs Admin) | AN.4 | Non |
| Webhook checkout.session.completed: confirmer metadata promo accessible | AN.4 | Non |
| Upgrade PRO → AUTOPILOT depuis app avec promo preserve | AN.4 | Non |
| Client UI: mention "Code promo applique" | AN.5 | Non (nice-to-have) |
| PROD promotion: merger + builder + GitOps PROD | AN.5+ | Oui |
| Website PROD: promo forwarding | AN.5+ | Oui |

## Rollback GitOps DEV

En cas de probleme, rollback en modifiant les manifests DEV :

```yaml
# API
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.150-amazon-inbound-visible-dev
# Client
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.154-amazon-inbound-visible-ux-dev
# Website
image: ghcr.io/keybuzzio/keybuzz-website:v0.6.7-pricing-attribution-forwarding-dev
```

Puis `kubectl apply -f` les manifests concernes.

## Verdict

**GO DEV LINK CHECKOUT READY**

**PROMO LINK CHECKOUT APPLICATION READY IN DEV — WEBSITE FORWARDS PROMO — CLIENT CAPTURES PROMO — STRIPE CHECKOUT RECEIVES PRE-APPLIED DISCOUNT — NO STACKING — PLAN-ONLY DISCOUNT PRESERVED — KBACTIONS/AGENT/ADDONS EXCLUDED — PROMO METADATA READY FOR ATTRIBUTION — NO PROD TOUCH — NO FAKE TRACKING EVENT — READY FOR CONTEST E2E VALIDATION**

---

Rapport complet : `keybuzz-infra/docs/PH-SAAS-T8.12AN.3-PROMO-LINK-FORWARDING-CHECKOUT-APPLICATION-DEV-01.md`
