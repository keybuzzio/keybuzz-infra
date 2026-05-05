# PH-SAAS-T8.12AN.9 — Promo Visible Price Preview PROD Promotion

> Phase : PH-SAAS-T8.12AN.9-PROMO-VISIBLE-PRICE-PREVIEW-PROD-PROMOTION-01
> Date : 2026-05-05
> Environnement : PROD
> Verdict : **GO PROD UX READY**

---

## Résumé

Promotion en PROD de la preview visible des codes promo sur `/register`. Le gagnant du concours verra clairement `0 € pendant 12 mois` avec le prix barré avant Stripe Checkout. Patch schema-agnostic pour compatibilité DEV/PROD. Aucun checkout créé, aucun paiement, times_redeemed = 0.

---

## ÉTAPE 0 — Preflight

| Élément | Valeur | Verdict |
|---------|--------|---------|
| API PROD runtime (avant) | `v3.5.140-promo-plan-only-attribution-prod` | ✓ AN.6 |
| Client PROD runtime (avant) | `v3.5.152-promo-attribution-prod` | ✓ AN.6 |
| Admin PROD runtime | Non déployé (namespace vide) | ✓ inchangé |
| Website PROD runtime | `v0.6.9-promo-forwarding-prod` | ✓ inchangé |
| Backend PROD runtime | `v1.0.42-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| API DEV runtime | `v3.5.153b-promo-preview-dev` | ✓ AN.8 |
| Client DEV runtime | `v3.5.156-promo-visible-price-dev` | ✓ AN.8 |
| keybuzz-api branche | `ph147.4/source-of-truth` | ✓ |
| keybuzz-api HEAD | `b612f9bc` (AN.8) | ✓ |
| keybuzz-client branche | `ph148/onboarding-activation-replay` | ✓ |
| keybuzz-client HEAD | `d99c355` (AN.8) | ✓ |
| Stripe LIVE promo code | CONCOURS-PRO-1AN-**** active, redeemed=0/1 | ✓ |
| Stripe LIVE checkout sessions | 0 | ✓ |
| Stripe LIVE charges | 0 | ✓ |

---

## ÉTAPE 1 — Source AN.8 + patch schema-agnostic

### Problème identifié

Les schémas `promo_codes` divergent entre DEV et PROD :

| Colonne | DEV | PROD |
|---------|-----|------|
| Statut actif | `active` (boolean) | `status` (text = 'active') |
| Archivage | `archived_at` (timestamp) | absent (via `status`) |
| Montant remise | `discount_value` (numeric) | `amount_off` (integer) |
| Type remise | `discount_type` (varchar) | absent |
| Scope | absent | `discount_scope` (text) |
| applies_to_products | ARRAY | jsonb |

### Patch appliqué

6 modifications dans `src/modules/billing/routes.ts` :

| # | Zone | Changement |
|---|------|-----------|
| 1 | checkout SQL | `SELECT id, code, ...` → `SELECT *` |
| 2 | checkout active check | `promoRow.archived_at` / `promoRow.active` → schema-agnostic |
| 3 | checkout meta | `discount_type` / `discount_value` → `?? amount_off` / `?? discount_scope` |
| 4 | promo-preview SQL | `SELECT id, code, ...` → `SELECT *` |
| 5 | promo-preview active check | → schema-agnostic (même logique) |
| 6 | promo-preview discount | `discount_value` → `discount_value ?? amount_off` |

Logique schema-agnostic :

```typescript
const isArchived = promoRow.archived_at !== undefined
    ? !!promoRow.archived_at
    : (promoRow.status !== 'active' && promoRow.status !== undefined);
const isActive = promoRow.active !== undefined
    ? promoRow.active === true
    : (promoRow.status === 'active');
const amountOff = Number(promoRow.discount_value ?? promoRow.amount_off) || 0;
```

- **Commit** : `6d7d3466` sur `ph147.4/source-of-truth`

### Briques AN.8 confirmées

| Brique | Présente | Verdict |
|--------|----------|---------|
| `GET /billing/promo-preview` | ✓ | ✓ |
| read-only (0 mutations) | ✓ | ✓ |
| `payment_method_collection: 'always'` | ✓ | ✓ |
| guard `applies_to` fail-closed | ✓ | ✓ |
| BFF `promo-preview/route.ts` | ✓ | ✓ |
| `PromoPreviewBanner` | ✓ | ✓ |
| prix barré | ✓ | ✓ |
| 0 € pendant 12 mois | ✓ | ✓ |
| différence AUTOPILOT | ✓ | ✓ |
| CB requise copy | ✓ | ✓ |
| exclusions | ✓ | ✓ |
| retry checkout + promo | ✓ | ✓ |

---

## ÉTAPE 2 — Build PROD

| Service | Tag | Digest | Commit source | Branche |
|---------|-----|--------|---------------|---------|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-promo-preview-prod` | `sha256:f0f003af1ed4a1985104a2853e3109225352066c1aedc3499f3dc1ba48bc7475` | `6d7d3466` | `ph147.4/source-of-truth` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.153-promo-visible-price-prod` | `sha256:86bea27f05e72a9ebbd4e2a41fbf9935f39dbf3ca89043bf3ab4070e3e093175` | `d99c355` | `ph148/onboarding-activation-replay` |

Client build args :
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` ✓
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io` ✓
- `NEXT_PUBLIC_APP_ENV=production` ✓
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG` ✓
- `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro` ✓
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10` ✓
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977` ✓
- `NEXT_PUBLIC_META_PIXEL_ID=1234164602194748` ✓

---

## ÉTAPE 3 — Validation image avant GitOps

### API image

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| promo-preview endpoint | 3 occurrences | ✓ |
| payment_method_collection | 1 occurrence | ✓ |
| PROMO_PLAN_MISMATCH | 2 occurrences | ✓ |
| discount_value/amount_off agnostic | 2 occurrences | ✓ |
| promoRow.status check | 4 occurrences | ✓ |
| SELECT * (pas de colonnes hardcodées) | 2 queries confirmées | ✓ |
| Secrets dans le bundle | 0 | ✓ |

### Client image

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| Duration text (pendant mois) | 10 occurrences | ✓ |
| GA4 (G-R3QQDYEBFG) | 5 | ✓ |
| sGTM (t.keybuzz.pro) | 7 | ✓ |
| TikTok (D7PT12JC77U44OJIPC10) | 2 | ✓ |
| LinkedIn (9969977) | 2 | ✓ |
| Meta (1234164602194748) | 2 | ✓ |
| Meta Purchase browser | 0 | ✓ (pas de browser-side purchase) |
| TikTok CompletePayment browser | 0 | ✓ |
| Shopify PNG/SVG | présent | ✓ |
| api.keybuzz.io | confirmé | ✓ |

---

## ÉTAPE 4 — GitOps PROD

| Action | Détail |
|--------|--------|
| Manifest API PROD modifié | `k8s/keybuzz-api-prod/deployment.yaml` |
| Manifest Client PROD modifié | `k8s/keybuzz-client-prod/deployment.yaml` |
| Commit infra | `bd695b3` |
| kubectl apply | ✓ configured |
| Rollout API | ✓ successfully rolled out |
| Rollout Client | ✓ successfully rolled out |
| Runtime = Manifest | ✓ confirmé |

### Rollback GitOps

```
# API PROD rollback
# Modifier k8s/keybuzz-api-prod/deployment.yaml → v3.5.140-promo-plan-only-attribution-prod
# Commit + push + kubectl apply -f

# Client PROD rollback
# Modifier k8s/keybuzz-client-prod/deployment.yaml → v3.5.152-promo-attribution-prod
# Commit + push + kubectl apply -f
```

---

## ÉTAPE 5 — Validation PROD sans checkout

| Test | Résultat | Verdict |
|------|----------|---------|
| API PROD health | `{"status":"ok"}` | ✓ |
| PRO annual + code concours | `valid:true, original:285600, discount:285600, due:0, 12 mois` | ✓ |
| PRO annual message | "Votre bon est appliqué : KeyBuzz Pro est offert pendant 12 mois." | ✓ |
| AUTOPILOT annual + code concours | `valid:true, original:477600, discount:285600, due:192000` | ✓ |
| AUTOPILOT message | "Votre bon déduit 2856 € : il reste 1920 € à payer." | ✓ |
| CB message | "Carte requise pour activer l'abonnement, aucun débit sur la période offerte." | ✓ |
| Exclusions | "Modules optionnels, KBActions et Agent KeyBuzz restent hors promotion." | ✓ |
| Code inconnu | `PROMO_UNKNOWN` | ✓ |
| Sans promo | `MISSING_PARAMS` | ✓ |
| times_redeemed | 0/1 | ✓ |
| Checkout sessions 1h | 0 | ✓ |
| Charges 1h | 0 | ✓ |
| Payment intents 1h | 0 | ✓ |
| New subscriptions 1h | 0 | ✓ |

---

## ÉTAPE 6 — Non-régression

### PROD

| Surface | Résultat | Verdict |
|---------|----------|---------|
| API PROD health | 200 OK | ✓ |
| billing/current | 400 (attendu sans tenant) | ✓ |
| tenant-context/me | 200 | ✓ |
| stats/conversations | 200 | ✓ |
| dashboard/summary | 200 | ✓ |
| integrations | 200 | ✓ |
| promo-preview | 200 | ✓ |
| Client `/` | 200 | ✓ |
| Client `/register` | 200 | ✓ |
| Client `/login` | 200 | ✓ |
| Client `/signup` | 200 | ✓ |
| Client `/pricing` | 200 | ✓ |
| Client `/dashboard` | 200 | ✓ |
| Client `/billing/plan` | 200 | ✓ |
| Client `/billing/ai` | 200 | ✓ |
| Client `/inbox` | 200 | ✓ |
| Client `/orders` | 200 | ✓ |
| Client `/channels` | 200 | ✓ |
| Client `/settings` | 200 | ✓ |

### Services inchangés

| Service | Image | Verdict |
|---------|-------|---------|
| Website PROD | `v0.6.9-promo-forwarding-prod` | ✓ inchangé |
| Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` | ✓ inchangé |
| CronJobs PROD | Tous actifs et schedulés | ✓ |

### Stripe PROD

| Vérification | Résultat | Verdict |
|-------------|----------|---------|
| Promo code LIVE | CONCOURS-PRO-1AN-**** active=true redeemed=0/1 | ✓ |
| Checkout sessions | 0 | ✓ |
| Charges | 0 | ✓ |
| Payment intents | 0 | ✓ |
| New subscriptions | 0 | ✓ |
| Coupons LIVE | 1 (inchangé AN.7) | ✓ |
| 0 CAPI | ✓ | ✓ |
| 0 fake purchase | ✓ | ✓ |

### Tracking Client

| Pixel/Tag | Présent | Verdict |
|-----------|---------|---------|
| GA4 | ✓ | ✓ |
| sGTM | ✓ | ✓ |
| TikTok | ✓ | ✓ |
| LinkedIn | ✓ | ✓ |
| Meta | ✓ | ✓ |
| Shopify logo | ✓ | ✓ |

### DEV toujours opérationnel

| Surface | Résultat | Verdict |
|---------|----------|---------|
| API DEV | `v3.5.153b-promo-preview-dev` Running, health OK | ✓ |
| Client DEV | `v3.5.156-promo-visible-price-dev` Running | ✓ |

---

## Images finales

| Service | Avant AN.9 | Après AN.9 | Rollback |
|---------|-----------|-----------|----------|
| API PROD | `v3.5.140-promo-plan-only-attribution-prod` | `v3.5.141-promo-preview-prod` | `v3.5.140-promo-plan-only-attribution-prod` |
| Client PROD | `v3.5.152-promo-attribution-prod` | `v3.5.153-promo-visible-price-prod` | `v3.5.152-promo-attribution-prod` |
| Website PROD | `v0.6.9-promo-forwarding-prod` | inchangé | — |
| Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` | inchangé | — |

---

## Recommandation

Ludovic peut envoyer le lien au gagnant. Le lien doit pointer vers :

```
https://client.keybuzz.io/register?plan=pro&cycle=yearly&promo=CONCOURS-PRO-1AN-****
```

Le gagnant verra :
- Prix initial barré : 2 856 € / an
- Prix après promo : **0 € pendant 12 mois**
- "Votre bon est appliqué : KeyBuzz Pro est offert pendant 12 mois."
- "Carte requise pour activer l'abonnement, aucun débit sur la période offerte."
- "Modules optionnels, KBActions et Agent KeyBuzz restent hors promotion."

---

## Verdict

**GO PROD UX READY**

PROMO VISIBLE PRICE PREVIEW LIVE IN PROD — WINNER LINK SHOWS 0 EUR FOR 12 MONTHS BEFORE CHECKOUT — AUTOPILOT DIFFERENCE CLEAR — CARD REQUIREMENT CLARIFIED — PLAN-ONLY SCOPE VISIBLE — AGENT/KBACTIONS/ADDONS EXCLUDED — TIMES_REDEEMED STILL 0 — NO CHECKOUT — NO PAYMENT — TRACKING PRESERVED — READY TO SEND WINNER LINK
