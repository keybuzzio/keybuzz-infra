# PH-SAAS-T8.12AN.1 — Stripe DEV Promo Coupon Trial Upgrade Behavior Proof

> Date : 4 mai 2026
> Type : Preuve comportement Stripe controlee — Stripe TEST uniquement
> Priorite : P0 — Billing / Stripe sensible
> Environnement : DEV / Stripe TEST
> Mutations : Stripe TEST uniquement (coupons, promo codes, customers, subscriptions)
> Code modifie : AUCUN
> Build/deploy : AUCUN
> PROD touchee : NON

---

## 0. PREFLIGHT / FREEZE

| Element | Valeur |
|---|---|
| Date/heure | 2026-05-04 ~17:00 CEST |
| Stripe mode | **TEST** (`sk_test_...` confirme via pod DEV) |
| PROD touchee ? | NON |
| Code touche ? | NON |
| Build/deploy ? | NON |
| Autre agent billing actif ? | Aucun detecte |
| Methode d'acces Stripe | kubectl exec dans pod `keybuzz-api-dev` |

---

## 1. PREFLIGHT REPOS

| Repo | Branche (bastion) | HEAD | Dirty ? | Verdict |
|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `6511ed7c` | clean | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `b2bba25` | clean | OK |
| keybuzz-backend | `main` | `f2afd3e` | clean | OK |
| keybuzz-admin | `main` | `e4bffe7` | clean | OK |
| keybuzz-infra | `main` | `0aec2a2` | scripts M (safe) | OK |

---

## 2. SOURCES RELUES

| Document | Lu |
|---|---|
| `PH-SAAS-T8.12AN-PROMO-CODES-LINKS-ATTRIBUTION-AND-STRIPE-TRUTH-AUDIT-01.md` | OUI — integralite |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | OUI |
| `AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` | OUI |
| Stripe docs officielles (coupons, promotion_codes, checkout discounts) | OUI (via connaissances confirmees par tests) |

---

## 3. STRIPE MODE TEST PROUVE

La cle Stripe du pod DEV `keybuzz-api-844fc866fb-mrkkt` (namespace `keybuzz-api-dev`) :

```
STRIPE_KEY_PREFIX=sk_test_...
IS_TEST=true
```

Aucune cle LIVE exposee. Tous les objets crees dans ce rapport sont en mode TEST exclusivement.

---

## 4. CARTOGRAPHIE PRODUITS STRIPE TEST

### 4.1 Produits

| Produit KeyBuzz | Stripe Product ID (TEST) | Type |
|---|---|---|
| KeyBuzz Starter | `prod_TjrtU3R2CeWUTJ` | Plan SaaS |
| KeyBuzz Pro | `prod_TjrtI6NYNyDBbp` | Plan SaaS |
| KeyBuzz Autopilot | `prod_TjrtoaGcUi0yNB` | Plan SaaS |
| KeyBuzz Canal Supplementaire | `prod_TjrtcvXp3I6fJR` | Addon |
| Agent KeyBuzz | `prod_UFWneeyEEoBCIK` | Addon |

### 4.2 Prix

| Plan | Interval | Price ID (TEST tronque) | Montant (EUR) |
|---|---|---|---|
| STARTER | monthly | `price_1SmO9s...` | 97,00 |
| STARTER | yearly | `price_1SmO9t...` | 936,00 |
| PRO | monthly | `price_1SmO9u...wu8e` | 297,00 |
| **PRO** | **yearly** | `price_1SmO9u...GoO2` | **2 856,00** |
| AUTOPILOT | monthly | `price_1SmO9v...` | 497,00 |
| **AUTOPILOT** | **yearly** | `price_1SmO9w...` | **4 776,00** |
| Agent KeyBuzz | monthly | `price_1TH1jj...IOPMo` | 797,00 |
| Agent KeyBuzz | yearly | `price_1TH1jj...uArL` | 7 656,00 |
| Channel addon | monthly | `price_1SmO9x...56XM` | 50,00 |
| Channel addon | yearly | `price_1SmO9x...AiF5` | 480,00 |

### 4.3 Coupons existants pre-AN.1

| Coupon | Type | Duration | Risque |
|---|---|---|---|
| `ANNUAL30` | 30% off | once | Consomme sur 1 seul invoice — OK pour annual, insuffisant pour monthly |
| `LAUNCH50` | 50% off | once | Idem |

---

## 5. OBJETS STRIPE TEST CREES

### 5.1 Coupons

| Objet | ID TEST | Type | Duration | Months | Amount | Currency | Applies to | Metadata |
|---|---|---|---|---|---|---|---|---|
| **Coupon A** (once risk) | `yhJ295Fh` | amount_off | **once** | - | 285600 | EUR | Plans SaaS (3 products) | `phase=PH-SAAS-T8.12AN.1, purpose=once_trial_risk_proof` |
| **Coupon B** (repeating candidate) | `mJMJmUAy` | amount_off | **repeating** | **12** | 285600 | EUR | Plans SaaS (3 products) | `phase=PH-SAAS-T8.12AN.1, purpose=repeating_12m_candidate` |

### 5.2 Promotion Codes

| Code | ID TEST | Coupon | Max redemptions | Active (post-cleanup) |
|---|---|---|---|---|
| `AN1-ONCE-RISK-TEST01` | `promo_1TTNqs...NUZp` | Coupon A | 1 | **false** (deactivated) |
| `AN1-REPEAT12-PRO-TEST01` | `promo_1TTNqs...kjkF` | Coupon B | 1 | **false** (deactivated) |
| `AN1-REPEAT12-MULTI-TEST01` | `promo_1TTNqs...8bWT` | Coupon B | unlimited | **false** (deactivated) |

---

## 6. TEST 1 : COUPON ONCE + TRIAL 14 JOURS

**Objectif** : Prouver si `duration=once` est consomme pendant le trial / facture 0.

**Setup** : Customer TEST + subscription PRO annual + trial 14j + Coupon A (once, 285600 cents).

| Point | Resultat |
|---|---|
| Subscription status | `trialing` |
| Trial end | 2026-05-18 |
| Initial invoice amount | **0 EUR** (trial, status=paid) |
| Discount attached to invoice 0 ? | OUI (coupon `yhJ295Fh` present dans invoice.discount) |
| Coupon times_redeemed | **1** (incremente a l'attachement, pas a la consommation) |
| Upcoming invoice after trial | **subtotal=285600, discount=285600, amount_due=0** |
| Le client beneficie-t-il encore de la remise apres trial ? | **OUI** |

### Correction majeure vs hypothese AN

**L'hypothese AN etait partiellement incorrecte.** L'AN affirmait : "`duration=once` est DANGEREUX avec le trial 14 jours — coupon consomme sur la facture a 0". En realite :

- Le coupon `once` est **attache** a la subscription lors de la creation (d'ou `times_redeemed=1`)
- La facture trial est $0 car il n'y a rien a facturer pendant le trial (subtotal=0, pas de line items facturees)
- Le coupon s'applique a la **prochaine facture reelle** apres le trial
- Pour un plan **annual**, cela donne exactement le comportement voulu : 1 an gratuit

**CEPENDANT**, `once` reste **insuffisant pour le cas mensuel** :
- Si le gagnant choisit PRO monthly, `once` ne couvre que **1 mois** (pas 12)
- `repeating 12m` couvre les **12 mois** dans les deux cas (annual ET monthly)

**Verdict TEST 1** : `once` fonctionne pour annual mais PAS pour monthly. `repeating 12m` reste recommande.

---

## 7. TEST 2 : REPEATING 12M + PRO ANNUAL

**Setup** : Customer TEST + subscription PRO annual + trial 14j + Coupon B (repeating 12m, 285600 cents).

| Point | Resultat |
|---|---|
| Subscription status | `trialing` |
| Trial end | 2026-05-18 |
| Initial invoice amount | **0 EUR** (trial) |
| Discount end | 2027-05-04 (~12 mois depuis creation) |
| Upcoming invoice after trial | **subtotal=285600, discount=285600, amount_due=0** |
| Discount applies to plan product | **OUI** |
| Discount months remaining | ~12 mois |

**Verdict TEST 2** : PRO annual integralement couvert par `repeating 12m`. Comportement identique a `once` pour le premier renouvellement annual, mais superieur car il couvre aussi le cas mensuel.

---

## 8. TEST 3 : REPEATING 12M + AUTOPILOT ANNUAL

**Objectif** : Prouver la deduction PRO sur forfait superieur.

**Setup** : Customer TEST + subscription AUTOPILOT annual + trial 14j + Coupon B.

| Point | Resultat |
|---|---|
| AUTOPILOT annual price | 477 600 cents (4 776,00 EUR) |
| PRO annual coupon value | 285 600 cents (2 856,00 EUR) |
| Upcoming subtotal | 477 600 |
| Upcoming discount | 285 600 |
| **Upcoming amount_due** | **192 000 cents (1 920,00 EUR)** |
| **Difference attendue** | **192 000 cents (1 920,00 EUR)** |
| **MATCH** | **true** |
| Tax behavior | Non visible (pas de tax config TEST) |
| Discount applies to plan product | **OUI** (Autopilot est dans applies_to) |

**Verdict TEST 3** : La deduction fonctionne parfaitement. Le gagnant qui choisit AUTOPILOT paie exactement la difference (4 776 - 2 856 = 1 920 EUR).

---

## 9. TEST 4 : ADDONS / AGENT KEYBUZZ EXCLUS

**Objectif** : Prouver que `applies_to.products[]` exclut Agent KeyBuzz et Channel addons.

**Setup** : Customer TEST + subscription PRO monthly + Agent KB monthly + Channel addon x2 + trial 14j + Coupon B.

**Note** : Tous les items en interval `monthly` (Stripe requiert le meme interval par subscription).

| Element | Montant | Discount applique | Net | Attendu | Verdict |
|---|---|---|---|---|---|
| Plan PRO monthly (297 EUR) | 29 700 | **29 700** (100% couvert) | **0** | OUI | **CORRECT** |
| Agent KeyBuzz (797 EUR) | 79 700 | **0** | **79 700** | NON | **CORRECT** |
| Channel addon x2 (100 EUR) | 10 000 | **0** | **10 000** | NON | **CORRECT** |
| **Total** | 119 400 | 29 700 | **89 700** | 89 700 | **ADDONS CORRECTLY EXCLUDED** |

**Verdict TEST 4** : `applies_to.products[]` fonctionne parfaitement. Le discount ne s'applique qu'aux plan products. Les addons sont factures au prix plein.

**Note sur KBActions** : Les KBActions utilisent `mode: 'payment'` (one-time), pas `mode: 'subscription'`. Elles ne passent pas par le checkout subscription et n'ont pas `allow_promotion_codes`. Elles sont **naturellement exclues** du systeme de coupons subscription.

---

## 10. TEST 5 : UPGRADE PENDANT TRIAL

**Objectif** : Verifier que le coupon est preserve lors d'un upgrade PRO → AUTOPILOT pendant le trial.

**Setup** : Customer TEST + PRO annual + trial + Coupon B → `subscriptions.update` vers AUTOPILOT annual.

| Point | Resultat |
|---|---|
| Discount preserved after upgrade | **true** — coupon `mJMJmUAy` toujours present |
| Coupon end date after upgrade | **2027-05-04 (INCHANGE)** |
| Upcoming BEFORE upgrade (PRO) | amount_due=0 (couvert) |
| Upcoming AFTER upgrade (AUTOPILOT) | **amount_due=192 000 (1 920 EUR)** |
| Expected (AUTOPILOT - coupon) | 192 000 |
| **MATCH** | **true** |
| Proration behavior | `none` (pas de proration pendant trial) |
| Addons unaffected | N/A (pas d'addons dans ce test) |

**Verdict TEST 5** : L'upgrade pendant trial **preserve le coupon**. La valeur du coupon s'applique au nouveau plan (AUTOPILOT) et la difference est correctement calculee. C'est le comportement exact requis pour le cas concours.

---

## 11. TEST 6 : MAX REDEMPTIONS / REUTILISATION

**Objectif** : Prouver `max_redemptions=1`.

**Setup** : Promotion code `AN1-REPEAT12-PRO-TEST01` avec `max_redemptions=1`.

| Tentative | Resultat | Verdict |
|---|---|---|
| 1ere utilisation (customer A) | **SUCCESS** — discount applique | OK |
| Etat promo apres 1ere | `times_redeemed=1, active=false` (auto-desactive) | **AUTO-LOCK** |
| 2eme utilisation (customer B) | **BLOCKED** — "This promotion code has been used up." | **CORRECT** |

**Decouverte importante** : Stripe **auto-desactive** le promotion code quand `max_redemptions` est atteint. Pas besoin de logique cote KeyBuzz pour bloquer la reutilisation.

**Verdict TEST 6** : `max_redemptions=1` fonctionne parfaitement pour le cas concours single-winner.

---

## 12. TEST 7 : LIEN PRE-APPLIQUE VS SAISIE CHECKOUT

**Objectif** : Comparer `discounts[]` et `allow_promotion_codes`.

### 12.1 Resultats API

| Test | Methode | Resultat | Session creee |
|---|---|---|---|
| **7A** | `discounts: [{ promotion_code: promoId }]` | **SUCCESS** | OUI |
| **7B** | `allow_promotion_codes: true` | **SUCCESS** | OUI |
| **7C** | `discounts[]` + `allow_promotion_codes` ensemble | **ERREUR** : "You may only specify one of these parameters" | NON |
| **7D** | `discounts: [{ coupon: couponId }]` | **SUCCESS** (bypass max_redemptions) | OUI |

### 12.2 Decouverte critique

**`discounts[]` et `allow_promotion_codes` sont mutuellement exclusifs.** Stripe refuse la combinaison des deux. Cela signifie :

- **Pas de risque de double discount / stacking**
- L'API doit choisir l'un ou l'autre par session

### 12.3 Recommandation

| Mode | UX | Cas d'usage | Risque | Recommandation |
|---|---|---|---|---|
| `allow_promotion_codes` (actuel) | User saisit manuellement | Codes publics, campagnes generiques | Code partageable | **Garder comme defaut (deja actif)** |
| `discounts[{promotion_code}]` | Aucune saisie, pre-applique | **Liens concours, agence, VIP** | Lien controlable | **RECOMMANDE pour liens promo** |
| `discounts[{coupon}]` direct | Bypass redemption limits | Admin override uniquement | **Dangereux** — bypass max_redemptions | **NE JAMAIS utiliser cote user** |

### 12.4 Logique API future (AN.2+)

```
SI promo param present dans body checkout-session :
  → Resoudre promotion_code ID depuis code
  → Passer discounts: [{ promotion_code: resolvedId }]
  → NE PAS passer allow_promotion_codes
SINON :
  → Garder allow_promotion_codes: true (comportement actuel)
```

---

## 13. CLEANUP / ARCHIVAGE TEST

| Objet TEST | Action | Etat final |
|---|---|---|
| Promo `AN1-ONCE-RISK-TEST01` | Desactive | `active=false` |
| Promo `AN1-REPEAT12-PRO-TEST01` | Desactive (deja auto-lock) | `active=false` |
| Promo `AN1-REPEAT12-MULTI-TEST01` | Desactive | `active=false` |
| 6 subscriptions TEST | Annulees | `canceled` |
| 3 checkout sessions TEST | Expirees | `expired` |
| Coupon `yhJ295Fh` (once) | Metadata cleanup marque | Actif mais marque `test_cleanup_status=archived_by_AN1` |
| Coupon `mJMJmUAy` (repeating) | Metadata cleanup marque | Actif mais marque `test_cleanup_status=archived_by_AN1` |
| 8 customers TEST | Non supprimes (Stripe TEST, sans impact) | Restent en TEST |

**Aucun objet LIVE cree. Aucun objet LIVE modifie.**

---

## 14. ANALYSE TRACKING / BILLING IMPACT

| Event | Source valeur actuelle | Impact coupon/promo | Verdict |
|---|---|---|---|
| **StartTrial** | `session.amount_total / 100` | amount_total=0 (trial), inchange avec ou sans coupon | **SAFE** |
| **Purchase** | `Σ(item.plan.amount × qty) / 100` | Utilise le prix catalogue, pas post-discount | **A VERIFIER** en AN.2 — `invoice.amount_paid` serait plus fidele |
| **SubscriptionRenewed** | Meme source | Stripe applique le discount sur la facture | **SAFE** cote facturation |
| **Upgrade** | `subscriptions.update` webhook | Discount preserve (TEST 5) | **SAFE** |
| **KBActions** | mode `payment` | Pas de coupon applicable | **SAFE** |
| **CAPI/GA4/Meta/TikTok/LinkedIn** | Aucun emit pendant ces tests | Aucune pollution | **SAFE** |

### Point d'attention AN.2

Le code actuel dans `handleSubscriptionUpdated` calcule la valeur Purchase comme la somme des `unit_amount` (prix catalogue). Avec un coupon actif, la valeur envoyee aux plateformes marketing sera le prix **avant** discount, pas le montant reellement paye. Selon la strategie marketing :

- **Prix catalogue** = utile pour ROAS brut
- **Prix reel post-discount** = utile pour ROAS net et comptabilite

Decision a prendre en AN.2 : utiliser `invoice.amount_paid` ou `session.amount_total` pour les events Purchase.

---

## 15. DECISION ARCHITECTURE

### 15.1 Tableau de decision final

| Sujet | Decision | Preuve | Confiance |
|---|---|---|---|
| **Type coupon** | `amount_off` (montant fixe EUR) | TEST 2, 3 : deduction exacte, difference calculable | **HAUTE** |
| **Duration** | `repeating` + `duration_in_months=12` | TEST 2 : couvre annual ET monthly. TEST 1 : `once` marche pour annual mais rate monthly | **HAUTE** |
| **Products** | `applies_to.products[]` = 3 plan products | TEST 4 : addons exclus parfaitement | **HAUTE** |
| **Trial** | SAFE — coupon pas gaspille sur facture trial $0 | TEST 1 + TEST 2 : upcoming post-trial montre discount actif | **HAUTE** |
| **Upgrade** | `subscriptions.update` preserve le discount | TEST 5 : PRO→AUTOPILOT, coupon maintenu, difference correcte | **HAUTE** |
| **Addons** | Exclus via `applies_to.products` | TEST 4 : Agent KB disc=0, Channel disc=0 | **HAUTE** |
| **KBActions** | Naturellement exclus (mode payment) | Architecture Stripe + AN | **HAUTE** |
| **Link mode** | `discounts[{promotion_code}]` pour liens promo | TEST 7A : session creee OK. TEST 7C : mutuellement exclusif avec allow_promo_codes = SAFE | **HAUTE** |
| **Max redemptions** | `max_redemptions=1` sur promotion code | TEST 6 : auto-desactive apres 1 usage, 2eme bloque | **HAUTE** |
| **Tracking** | Purchase value actuelle = catalogue (pre-discount) — a verifier en AN.2 | Analyse code webhook | **MOYENNE** |
| **Admin foundation** | Architecture AN validee, prete pour AN.2 | Tous tests confirment le design | **HAUTE** |

### 15.2 Correction AN

| Point AN original | Correction AN.1 |
|---|---|
| "`duration=once` est DANGEREUX avec le trial" | **Partiellement faux** — `once` fonctionne pour annual (pas gaspille sur $0). Mais insuffisant pour monthly. `repeating 12m` reste recommande. |
| Comportement trial + coupon "non prouve" | **PROUVE** — facture trial = $0 subtotal, discount s'applique a la prochaine facture reelle |

### 15.3 Gate AN.1 : resultats

Les 4 points a prouver identifies dans AN (section 6.3) :

| Gate | Resultat | Statut |
|---|---|---|
| `repeating 12m` non consomme sur invoice trial 0 | **CONFIRME** — upcoming post-trial montre discount actif | **PASSE** |
| Upgrade PRO→AUTOPILOT preserve coupon | **CONFIRME** — discount maintenu, difference correcte | **PASSE** |
| `applies_to` exclut addons | **CONFIRME** — Agent KB et Channel a disc=0 | **PASSE** |
| Valeur Purchase reflete montant reel | **PARTIELLEMENT** — valeur actuelle = catalogue, pas post-discount | **A TRAITER AN.2** |

### 15.4 Test E2E DEV applicatif requis avant AN.2 ?

**NON** — le comportement Stripe est prouve au niveau API. AN.2 peut implementer directement les endpoints CRUD Admin + table `promo_codes` + logique `discounts[]` dans le checkout. Un test E2E sera effectue dans AN.4 (contest E2E DEV).

---

## 16. RISQUES RESTANTS

| Risque | Severite | Mitigation | Phase |
|---|---|---|---|
| Purchase value != montant reel post-discount | MOYENNE | Utiliser `invoice.amount_paid` ou `session.amount_total` | AN.2 |
| `once` utilise par erreur au lieu de `repeating` | FAIBLE | Admin UI impose `repeating` par defaut | AN.2 |
| `discounts[{coupon}]` utilise au lieu de `discounts[{promotion_code}]` | HAUTE | Jamais exposer `coupon` directement — toujours via `promotion_code` | AN.2 |
| Coupons TEST laisses actifs (archivage metadata seulement) | NULLE | Stripe TEST mode, aucun impact | - |
| allow_promotion_codes reste actif globalement | FAIBLE | Un user pourrait entrer un code non destine. Stacking impossible (mutuellement exclusif). | AN.3 |

---

## 17. INTERDITS RESPECTES

| Interdit | Respecte |
|---|---|
| Pas de code modifie | **OUI** |
| Pas de build | **OUI** |
| Pas de deploy | **OUI** |
| Pas de mutation DB | **OUI** |
| Pas de mutation Stripe LIVE | **OUI** |
| Pas de coupon LIVE | **OUI** |
| Pas de paiement reel | **OUI** |
| Pas de faux event marketing | **OUI** |
| Pas de secret expose | **OUI** |
| Pas de tenant hardcode | **OUI** |
| Pas de PROD | **OUI** |

---

## 18. VERDICT

### GO IMPLEMENT DEV

STRIPE DEV PROMO BEHAVIOR PROVED — REPEATING 12M PLAN-ONLY COUPON VALIDATED — PRO YEAR CONTEST CASE SAFE — AUTOPILOT UPGRADE DIFFERENCE VERIFIED — KBACTIONS/AGENT/ADDONS EXCLUDED — TRIAL DOES NOT WASTE DISCOUNT — NO CODE — NO BUILD — NO DEPLOY — READY FOR ADMIN/API PROMO FOUNDATION DEV

### Detail verdict

- **`repeating` + `duration_in_months=12`** : valide pour annual ET monthly
- **`amount_off=285600` (PRO annual)** : deduction exacte sur AUTOPILOT (reste 1 920 EUR)
- **`applies_to.products[]`** : addons exclus confirmé
- **Trial 14j** : coupon NON gaspille, s'applique a la premiere facture reelle
- **Upgrade PRO→AUTOPILOT** : coupon preserve, difference correcte
- **`max_redemptions=1`** : auto-desactivation Stripe confirmee
- **`discounts[]` vs `allow_promotion_codes`** : mutuellement exclusifs = pas de stacking
- **Correction AN** : `once` n'est pas "dangereux" pour annual, mais `repeating 12m` reste superieur

### Prochaine phase recommandee

**AN.2 — Promo Foundation API/Admin DEV** :
1. Table `promo_codes` (migration DB)
2. Endpoints CRUD API (`/admin/promo-codes`)
3. Logique conditionnelle `discounts[]` vs `allow_promotion_codes` dans checkout
4. Page Admin `/marketing/promo-codes` (CRUD + generateur de liens)
5. Fix optionnel : Purchase value source (`invoice.amount_paid`)

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12AN.1-STRIPE-DEV-PROMO-COUPON-TRIAL-UPGRADE-BEHAVIOR-PROOF-01.md
```
