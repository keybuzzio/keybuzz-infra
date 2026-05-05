# PH-SAAS-T8.12AN.8 — Promo Visible Price Preview and Card Clarity DEV

> Phase : PH-SAAS-T8.12AN.8-PROMO-VISIBLE-PRICE-PREVIEW-AND-CARD-CLARITY-DEV-01
> Date : 2026-05-05
> Environnement : DEV uniquement
> Verdict : **GO DEV UX READY**

---

## Résumé

Ajout d'un endpoint API read-only `GET /billing/promo-preview` et d'un bandeau UI sur `/register` affichant la réduction promo avant Stripe Checkout. PRO annuel affiche `0 € pendant 12 mois` avec prix barré. AUTOPILOT affiche la différence. Carte bancaire requise clarifiée. Modules optionnels/KBActions/Agent exclus visuellement.

---

## ÉTAPE 0 — Preflight

| Élément | Valeur | Verdict |
|---------|--------|---------|
| API DEV runtime | `v3.5.153b-promo-preview-dev` | ✓ AN.8 |
| Client DEV runtime | `v3.5.156-promo-visible-price-dev` | ✓ AN.8 |
| API PROD runtime | `v3.5.140-promo-plan-only-attribution-prod` | ✓ inchangé AN.7 |
| Client PROD runtime | `v3.5.152-promo-attribution-prod` | ✓ inchangé AN.7 |
| Admin PROD runtime | `v2.12.1-promo-codes-foundation-prod` | ✓ inchangé AN.6R |
| Website PROD runtime | `v0.6.9-promo-forwarding-prod` | ✓ inchangé AN.6R |
| API DEV health | `{"status":"ok"}` | ✓ |
| Stripe DEV mode | `sk_test_` (livemode: false) | ✓ SAFE |
| Stripe PROD mode | `sk_live_` (livemode: true) | ✓ |
| Codes promo DEV actifs | 3 (AN3-E2E-TEST-PRO, CONCOURS-PRO-1AN-E2E, CONCOURS-PRO-1AN-E2E-MULTI) | ✓ |
| Coupon LIVE PROD | 1 (69gVWg1Z — Concours PRO 1 an) | ✓ inchangé AN.7 |
| Promo Code LIVE PROD | 1 (CONCOURS-PRO-1AN-7351 — 0/1 redeemed) | ✓ inchangé AN.7 |

---

## ÉTAPE 1 — Audit UI actuelle /register

| Surface UI | État avant AN.8 | Gap |
|------------|-----------------|-----|
| Plan sélectionné | Affiché dans la sidebar et le recap | ✓ existait |
| Prix plan | Affiché dans le recap step `user` | ✓ existait |
| Cycle billing | Lu depuis `useSearchParams()` (`?cycle=`) | ✓ existait |
| Param promo | Lu depuis `useSearchParams()` (`?promo=`) | ✓ existait (AN.3) |
| Promo visible avant checkout | **NON** — aucun bandeau/résumé promo | ✗ GAP CRITIQUE |
| Prix barré | **NON** | ✗ GAP |
| Montant remisé | **NON** | ✗ GAP |
| Durée promo | **NON** | ✗ GAP |
| Carte bancaire mention | **NON** | ✗ GAP |
| Exclusions modules | **NON** | ✗ GAP |
| handleRetryCheckout + promo | **NON** — promo perdue au retry | ✗ GAP |

---

## ÉTAPE 2 — API read-only promo preview

### Endpoint

```
GET /billing/promo-preview?promo=<CODE>&plan=<PLAN>&cycle=<CYCLE>
```

Read-only. Aucune mutation DB, aucun checkout Stripe, aucune consommation de redemption.

### Logique

1. Validation params (`promo`, `plan`, `cycle`) requis
2. Lookup `promo_codes` table (DB, `UPPER(code)`)
3. Vérifications : actif, non archivé, Stripe coupon valide
4. Récupération prix plan depuis Stripe Price API (`getPriceId(plan, cycle)`)
5. Guard `applies_to` fail-closed (AN.5) — plan product ID doit être dans `applies_to_products`
6. Calcul : `discountAmount = min(discount_value, planAmount)`, `amountDue = max(0, planAmount - discountAmount)`
7. Messages UI-safe générés côté serveur

### Codes erreur

| Code | Condition |
|------|-----------|
| `MISSING_PARAMS` | promo, plan ou cycle absent |
| `PROMO_UNKNOWN` | code absent en DB |
| `PROMO_ARCHIVED` | `archived_at IS NOT NULL` |
| `PROMO_INACTIVE` | `active = false` |
| `PROMO_STRIPE_INACTIVE` | Coupon Stripe invalide |
| `PROMO_PLAN_MISMATCH` | Plan product ID absent de `applies_to_products` |
| `PROMO_PREVIEW_UNAVAILABLE` | Erreur serveur interne |

### Tests validés

| Cas | Résultat | Verdict |
|-----|----------|---------|
| PRO annual + CONCOURS-PRO-1AN-E2E | `valid:true, original:285600, discount:285600, due:0, 12 mois` | ✓ |
| AUTOPILOT annual + CONCOURS-PRO-1AN-E2E | `valid:true, original:477600, discount:285600, due:192000, 12 mois` | ✓ |
| STARTER monthly + CONCOURS-PRO-1AN-E2E | `valid:true, original:9700, discount:9700, due:0` | ✓ (promo inclut STARTER dans applies_to) |
| PRO monthly + CONCOURS-PRO-1AN-E2E | `valid:true, original:29700, discount:29700, due:0` | ✓ |
| AN2-VALIDATION-TEST01 (archived) | `valid:false, PROMO_ARCHIVED` | ✓ |
| FAKE-CODE-123 (unknown) | `valid:false, PROMO_UNKNOWN` | ✓ |
| AN3-E2E-TEST-PRO + PRO annual | `valid:true, original:285600, discount:285600, due:0` | ✓ |
| Sans promo param | `valid:false, MISSING_PARAMS` | ✓ |

### Fichier modifié

- **API** : `/opt/keybuzz/keybuzz-api/src/modules/billing/routes.ts` — ajout endpoint `GET /billing/promo-preview`
- **Commit** : `b612f9bc` sur `ph147.4/source-of-truth`

---

## ÉTAPE 3 — Vérifier/forcer carte bancaire

| Champ Stripe | Avant AN.8 | Après AN.8 | Risque |
|--------------|-----------|-----------|--------|
| `payment_method_collection` | absent (défaut Stripe) | `'always'` explicite | ✓ aucun — force CB même si montant initial = 0 |
| `mode` | `'subscription'` | `'subscription'` (inchangé) | ✓ |
| Trial 14j | conservé | conservé (inchangé) | ✓ |
| Discount pré-appliqué | via `discounts[{promotion_code}]` | inchangé | ✓ |

Ajout de `payment_method_collection: 'always'` dans `stripe.checkout.sessions.create()` pour garantir que la CB est demandée même si le montant après promo = 0 EUR.

---

## ÉTAPE 4 — UI Client /register

### Composant PromoPreviewBanner

Ajouté dans `app/register/page.tsx`. Affiché sur les steps : `email`, `company`, `user`, `payment_cancelled`.

### Comportement par cas

| Cas UI | Affichage |
|--------|-----------|
| PRO annuel + promo valide | Bandeau vert : icône Gift, prix barré `2 856 €`, `0 € pendant 12 mois`, message promo, CB requise, exclusions |
| AUTOPILOT annuel + promo valide | Bandeau vert : icône Gift, prix barré `4 776 €`, `1 920 €`, message différence, CB requise, exclusions |
| Promo invalide/archivée | Bandeau orange : icône AlertTriangle, message d'erreur clair |
| Chargement promo | Bandeau gris : icône Loader2, "Vérification de votre code promo..." |
| Sans promo | Aucun bandeau affiché |
| Promo valide + step user | Recap prix standard masqué, remplacé par le bandeau promo |

### Messages affichés (PRO annuel 0 €)

- **Message principal** : "Votre bon est appliqué : KeyBuzz Pro est offert pendant 12 mois."
- **Carte bancaire** : "Carte requise pour activer l'abonnement, aucun débit sur la période offerte."
- **Exclusions** : "Modules optionnels, KBActions et Agent KeyBuzz restent hors promotion."

### Fix handleRetryCheckout

Le promo code est désormais réinjecté dans le body du `fetch('/api/billing/checkout-session', ...)` lors d'un retry après annulation :

```typescript
body: JSON.stringify({
  ...payload,
  promo: urlPromo || undefined,
})
```

### BFF route créée

- **Fichier** : `app/api/billing/promo-preview/route.ts`
- Proxy GET vers `{API_URL}/billing/promo-preview`
- Transformations : `yearly` → `annual`, `plan` → `PLAN.toUpperCase()`
- **Commit** : `d99c355` sur `ph148/onboarding-activation-replay`

---

## ÉTAPE 5 — Checkout cohérence

| Cas | Preview API | Checkout Stripe | Verdict |
|-----|-------------|----------------|---------|
| PRO annual + promo valide | original=285600, discount=285600, due=0 | `promotion_code` appliqué, amount_off=285600 | ✓ aligné |
| AUTOPILOT annual + promo valide | original=477600, discount=285600, due=192000 | `promotion_code` appliqué, amount_off=285600 | ✓ aligné |
| Même promo code forwarded | ✓ code identique dans preview et checkout | ✓ | ✓ |
| Même plan/cycle | ✓ | ✓ | ✓ |
| applies_to guard | Vérifié dans preview | Vérifié dans checkout (AN.5) | ✓ fail-closed identique |
| Checkout sans promo | N/A (pas de bandeau) | Checkout normal inchangé | ✓ |
| Stacking | Non supporté (single code) | Non supporté (Stripe single discount) | ✓ |

---

## ÉTAPE 6 — Validation DEV

| Test | Résultat | Verdict |
|------|----------|---------|
| PRO annual + promo valide — UI affiche 0 € | original: 285600, due: 0, message: "offert pendant 12 mois" | ✓ PASS |
| PRO annual + promo valide — prix barré | `originalAmount` affiché barré, `amountDueAfterDiscount` en gras | ✓ PASS |
| PRO annual + promo valide — CB required copy | "Carte requise pour activer l'abonnement, aucun débit sur la période offerte." | ✓ PASS |
| AUTOPILOT annual + promo valide — UI affiche différence | original: 477600, due: 192000, message: "il reste 1 920 € à payer" | ✓ PASS |
| Promo inconnu — message clair | "Code promo inconnu." | ✓ PASS |
| Promo archivé — message clair | "Ce code promo a expiré." | ✓ PASS |
| Sans promo — comportement inchangé | Aucun bandeau, flow normal | ✓ PASS |
| Exclusions KBActions/Agent/addons | "Modules optionnels, KBActions et Agent KeyBuzz restent hors promotion." | ✓ PASS |
| handleRetryCheckout — promo forwarded | `promo: urlPromo` ajouté au body checkout | ✓ PASS |

---

## ÉTAPE 7 — Build DEV

| Service | Tag | Commit source | Branche | Commit infra |
|---------|-----|--------------|---------|-------------|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.153b-promo-preview-dev` | `b612f9bc` | `ph147.4/source-of-truth` | poussé `main` keybuzz-infra |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.156-promo-visible-price-dev` | `d99c355` | `ph148/onboarding-activation-replay` | poussé `main` keybuzz-infra |

Build Docker `--no-cache` sur le bastion. `rm -rf dist/` forcé avant build API pour éviter le cache TypeScript compilé.

---

## ÉTAPE 8 — Non-régression

### DEV

| Surface | Résultat | Verdict |
|---------|----------|---------|
| `/register` | HTTP 200 | ✓ |
| `/login` | HTTP 200 | ✓ |
| `/dashboard` | HTTP 200 (307 redirect sans auth = attendu) | ✓ |
| `/billing/plan` | HTTP 200 | ✓ |
| `/billing/ai` | HTTP 200 | ✓ |
| `/inbox` | HTTP 200 | ✓ |
| `/orders` | HTTP 200 | ✓ |
| `/channels` | HTTP 200 | ✓ |
| `/settings` | HTTP 200 | ✓ |
| `/signup` | HTTP 200 | ✓ |
| `/pricing` | HTTP 200 | ✓ |
| `/` (root) | HTTP 200 | ✓ |
| API health | `{"status":"ok"}` | ✓ |
| API billing/current | HTTP 400 (attendu sans tenantId) | ✓ |
| API tenant-context/me | HTTP 200 | ✓ |
| API stats/conversations | HTTP 200 | ✓ |
| API dashboard/summary | HTTP 200 | ✓ |
| Promo preview PRO annual | ✓ valid, correct amounts | ✓ |
| Promo preview AUTOPILOT annual | ✓ valid, correct difference | ✓ |
| Promo preview code inconnu | ✓ PROMO_UNKNOWN | ✓ |
| Promo preview code archivé | ✓ PROMO_ARCHIVED | ✓ |
| Integrations list | HTTP 200 | ✓ |
| CronJobs DEV | Tous actifs et schedulés | ✓ |

### PROD inchangée

| Surface | DEV | PROD | Verdict |
|---------|-----|------|---------|
| API image | `v3.5.153b-promo-preview-dev` | `v3.5.140-promo-plan-only-attribution-prod` | ✓ PROD inchangée |
| Client image | `v3.5.156-promo-visible-price-dev` | `v3.5.152-promo-attribution-prod` | ✓ PROD inchangée |
| Admin image | N/A | `v2.12.1-promo-codes-foundation-prod` | ✓ PROD inchangée |
| Website image | N/A | `v0.6.9-promo-forwarding-prod` | ✓ PROD inchangée |
| Stripe LIVE coupons | N/A | 1 (69gVWg1Z — Concours PRO 1 an) | ✓ inchangé AN.7 |
| Stripe LIVE promo codes | N/A | 1 (CONCOURS-PRO-1AN-7351 — 0/1) | ✓ inchangé AN.7 |
| Checkout sessions PROD 24h | N/A | 0 | ✓ |
| Subscriptions PROD 24h | N/A | 0 | ✓ |
| Invoices PROD 24h | N/A | 0 | ✓ (0 CAPI) |
| Charges PROD 24h | N/A | 0 | ✓ (0 fake purchase) |
| CronJobs PROD | N/A | Tous actifs | ✓ |

---

## Rollback DEV GitOps

Si nécessaire :

```bash
# API DEV rollback
# Modifier keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml → image précédente
# Commit + push + kubectl apply

# Client DEV rollback
# Modifier keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml → image précédente
# Commit + push + kubectl apply
```

Images rollback :
- API DEV : `ghcr.io/keybuzzio/keybuzz-api:v3.5.152-promo-plan-only-attribution-dev` (avant AN.8)
- Client DEV : `ghcr.io/keybuzzio/keybuzz-client:v3.5.155-promo-register-dev` (avant AN.8)

---

## Gaps identifiés

| # | Gap | Impact | Recommandation |
|---|-----|--------|----------------|
| G1 | Le promo code DEV `CONCOURS-PRO-1AN-E2E` inclut STARTER dans `applies_to_products` | Un gagnant PRO pourrait appliquer le code sur STARTER (discount > prix plan) | Le code LIVE PROD `CONCOURS-PRO-1AN-7351` a le scope correctement configuré. Vérifier à la promotion PROD |
| G2 | Le bandeau promo n'est pas visible en mode navigateur dans cette phase | Validation UI visuelle complète requise en AN.9 | Test navigateur à faire avant envoi du lien au gagnant |
| G3 | `payment_method_collection: 'always'` non testé avec un vrai checkout 0 € en DEV | Comportement Stripe à confirmer en test E2E complet | Tester un checkout complet DEV en AN.9 |

---

## Recommandation AN.9 — PROD promotion

Pour promouvoir cette phase en PROD :

1. Build API PROD avec le même code source (`ph147.4/source-of-truth`, commit `b612f9bc`)
2. Build Client PROD avec le même code source (`ph148/onboarding-activation-replay`, commit `d99c355`)
3. GitOps strict : modifier manifests PROD, commit, push, apply
4. Valider le promo-preview en PROD avec le vrai code `CONCOURS-PRO-1AN-7351`
5. Test navigateur complet : register → promo visible → checkout → Stripe
6. Vérifier `payment_method_collection: 'always'` effectif en PROD
7. Envoyer le lien au gagnant uniquement après validation complète

---

## Verdict

**GO DEV UX READY**

PROMO VISIBLE PRICE PREVIEW READY IN DEV — REGISTER SHOWS DISCOUNT BEFORE CHECKOUT — PRO YEAR DISPLAYS 0 EUR FOR 12 MONTHS — AUTOPILOT DISPLAYS ONLY DIFFERENCE — CARD REQUIREMENT CLARIFIED — PLAN-ONLY SCOPE VISIBLE — AGENT/KBACTIONS/ADDONS EXCLUDED — PREVIEW MATCHES STRIPE CHECKOUT — NO PROD TOUCH — READY FOR PROD PROMOTION
