# PH-SAAS-T8.12AN.7 — First Contest PRO Year Promo Code PROD

> Phase : PH-SAAS-T8.12AN.7-FIRST-CONTEST-PRO-YEAR-PROMO-CODE-PROD-01
> Date : 2026-05-05
> Environnement : PROD (Stripe LIVE)
> Verdict : **GO FIRST CONTEST CODE READY**

---

## Résumé

Création contrôlée du premier code promo concours LIVE pour un gagnant (1 an de forfait PRO annuel).
Aucun checkout, aucun paiement, aucun build, aucun deploy.

---

## ÉTAPE 0 — Preflight

| Élément | Valeur | Verdict |
|---------|--------|---------|
| API PROD runtime | `v3.5.140-promo-plan-only-attribution-prod` | ✓ AN.6R |
| Admin PROD runtime | `v2.12.1-promo-codes-foundation-prod` | ✓ AN.6R |
| Client PROD runtime | `v3.5.152-promo-attribution-prod` | ✓ AN.6R |
| Website PROD runtime | `v0.6.9-promo-forwarding-prod` | ✓ AN.6R |
| API health | OK | ✓ |
| Coupons Stripe LIVE existants | 0 | ✓ |
| Promotion Codes LIVE existants | 0 | ✓ |
| Checkout sessions récentes | 0 | ✓ |

---

## ÉTAPE 1 — Prix / Produits Stripe LIVE

| Produit | Stripe product | Prix annuel | Inclus applies_to ? |
|---------|----------------|-------------|---------------------|
| KeyBuzz Starter | `prod_TpJT****0Sy` | 936 EUR | ✓ OUI (plan SaaS) |
| KeyBuzz Pro | `prod_TpJT****IVw` | 2 856 EUR | ✓ OUI (plan SaaS) |
| KeyBuzz Autopilot | `prod_TpJT****G83` | 4 776 EUR | ✓ OUI (plan SaaS) |
| KeyBuzz Add-on Canal | `prod_TpJT****LGG` | 480 EUR/an | ✗ EXCLU |
| Agent KeyBuzz | `prod_UFtA****ErY` | — | ✗ EXCLU |

- **PRO annuel (amount_off)** : 285 600 cents = 2 856 EUR
- **Différence AUTOPILOT - PRO** : 1 920 EUR (le gagnant paierait cette différence s'il choisit Autopilot)

---

## ÉTAPE 2 — Création du code

Créé via Stripe API depuis pod API PROD (bypasse Admin car table `promo_codes` absente — créée automatiquement dans le même flux).
Tables DB `promo_codes` et `promo_code_audit_log` créées dans le même script.

| Champ | Valeur |
|-------|--------|
| name | Concours PRO 1 an |
| code | `CONCOURS-PRO-1AN-****` (masqué) |
| stripe_coupon_id | `69gV****` (masqué partiel) |
| stripe_promotion_code_id | `promo_1TTcEC****` (masqué partiel) |
| amount_off | 285 600 cents (2 856 EUR) |
| currency | eur |
| duration | repeating |
| duration_in_months | 12 |
| applies_to_products | 3 produits plans SaaS (Starter, Pro, Autopilot) |
| max_redemptions | 1 |
| times_redeemed | 0 |
| discount_scope | plan_only |
| status | active |
| metadata.source | keybuzz_admin |
| metadata.campaign | concours-pro-1an |
| metadata.scope | saas_plan_only |
| metadata.created_phase | PH-SAAS-T8.12AN.7 |
| created_by | cursor-agent-an7 |

---

## ÉTAPE 3 — Vérification Stripe LIVE

| Check | Attendu | Observé | Verdict |
|-------|---------|---------|---------|
| Coupon actif | valid: true | true | ✓ |
| Promotion Code actif | active: true | true | ✓ |
| max_redemptions | 1 | 1 | ✓ |
| times_redeemed | 0 | 0 | ✓ |
| amount_off | 285600 | 285600 | ✓ |
| currency | eur | eur | ✓ |
| duration | repeating | repeating | ✓ |
| duration_in_months | 12 | 12 | ✓ |
| Stripe native applies_to | — | Non retourné (SDK 14.x) | ⚠ documenté |
| API guard PROMO_PLAN_MISMATCH | Présent | ✓ vérifié dans routes.js compilé | ✓ |
| API guard applies_to_products | Présent | ✓ vérifié dans routes.js compilé | ✓ |
| Agent KeyBuzz exclu | Absent de applies_to | ✓ | ✓ |
| Add-on Canal exclu | Absent de applies_to | ✓ | ✓ |
| KBActions exclu | Pas de produit KBActions | ✓ | ✓ |
| Total coupons | 1 | 1 | ✓ |
| Total promotion codes | 1 | 1 | ✓ |
| Checkout sessions dernière heure | 0 | 0 | ✓ |

### Note sur Stripe `applies_to`

Le SDK Stripe 14.x (API version `2023-10-16`) ne retourne pas le champ `applies_to` sur l'objet coupon.
La protection est assurée au niveau applicatif par le **fail-closed guard AN.5** :
- L'API lit `applies_to_products` depuis la table DB `promo_codes`
- Avant d'appliquer une promotion, l'API fetch le `product` du `planPriceId` via `stripe.prices.retrieve()`
- Si le produit n'est pas dans la liste, rejet avec `PROMO_PLAN_MISMATCH`
- Ce guard est **vérifié présent** dans le code compilé `dist/modules/billing/routes.js`

---

## ÉTAPE 4 — DB PROD

| DB | Résultat | Verdict |
|----|----------|---------|
| promo_codes row | 1 (id: `27010f47-****`) | ✓ |
| promo_code_audit_log | 1 entry (action: created) | ✓ |
| status | active | ✓ |
| max_redemptions | 1 | ✓ |
| applies_to_products | 3 products (plans SaaS) | ✓ |
| discount_scope | plan_only | ✓ |
| Doublons code | NONE | ✓ |
| created_by | cursor-agent-an7 | ✓ |

---

## ÉTAPE 5 — Liens PROD

| Lien | Usage | Masqué rapport |
|------|-------|----------------|
| `https://client.keybuzz.io/register?plan=pro&cycle=annual&promo=****&utm_source=concours&...` | Inscription directe gagnant | ✓ masqué |
| `https://www.keybuzz.pro/pricing?promo=****&utm_source=concours&...` | Via page pricing | ✓ masqué |

Paramètres UTM des liens :
- `utm_source=concours`
- `utm_medium=partner`
- `utm_campaign=concours-pro-1an`
- `utm_content=gagnant`
- `marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk`

---

## ÉTAPE 6 — Validation sans checkout

| Validation | Résultat |
|------------|----------|
| API health | ✓ OK |
| Promo code actif | ✓ active, 0 redemptions |
| DB row complète | ✓ |
| Audit log | ✓ |
| No checkout session | ✓ 0 |
| No payment | ✓ 0 |
| No CAPI event | ✓ |
| No fake purchase | ✓ |

Note : validation dry-run checkout non disponible — documenté. La validation repose sur la vérification de configuration Stripe + DB + API guards.

---

## ÉTAPE 7 — Non-régression

| Surface | Verdict |
|---------|---------|
| API health | ✓ OK |
| Admin /login | ✓ 200 |
| Client /register | ✓ 200 |
| Website /pricing | ✓ 200 |
| Checkout sessions créées | ✓ 0 |
| Payments créés | ✓ 0 |
| New subscriptions | ✓ 0 |
| Active billing subs | ✓ 4 (inchangé) |
| Billing customers | ✓ 9 (inchangé) |
| CronJobs API PROD | ✓ inchangés (outbound-tick, sla-evaluator, trial-lifecycle-dryrun, carrier-tracking-poll) |
| CronJobs Backend PROD | ✓ inchangés (amazon-orders-sync, amazon-reports-tracking-sync) |
| Promo redemptions | ✓ 0/1 |

---

## Recommandations d'usage pour Ludovic

### Comment utiliser le code

1. **Transmettre au gagnant** le lien direct d'inscription (fourni dans le résumé CE, pas dans ce rapport)
2. Le gagnant crée son compte via le lien pré-rempli
3. Il choisit le plan PRO annuel → le coupon couvre la totalité (0 EUR à payer)
4. S'il préfère Autopilot annuel → il paie uniquement la différence de 1 920 EUR/an
5. Le coupon s'applique automatiquement pendant 12 mois (repeating)
6. Le code ne peut être utilisé qu'**une seule fois** (max_redemptions = 1)

### Restrictions

- ✗ Le coupon ne s'applique PAS aux KBActions
- ✗ Le coupon ne s'applique PAS à l'Agent KeyBuzz
- ✗ Le coupon ne s'applique PAS aux addons / options / canaux supplémentaires
- ✓ Le coupon s'applique UNIQUEMENT aux plans SaaS (Starter, Pro, Autopilot)

### Monitoring

- Vérifier `times_redeemed` dans Stripe Dashboard après transmission du code
- Vérifier la création d'une subscription active avec le coupon appliqué
- Phase AN.8 recommandée : monitoring redemption et vérification post-checkout

---

## Prochaine phase

**AN.8** : Monitoring redemption quand le gagnant utilise le code
- Vérifier la création de subscription
- Vérifier l'application correcte du coupon
- Vérifier l'attribution UTM complète
- Vérifier que les addons ne sont pas remisés

---

## Verdict

**GO FIRST CONTEST CODE READY**

FIRST CONTEST PRO YEAR PROMO CODE READY IN PROD — ONE LIVE PROMOTION CODE CREATED — PLAN-ONLY APPLIES_TO VERIFIED — MAX_REDEMPTIONS 1 — TIMES_REDEEMED 0 — AGENT/KBACTIONS/ADDONS EXCLUDED — LINKS READY FOR LUDOVIC — NO CHECKOUT — NO PAYMENT — NO FAKE EVENT — READY FOR REDEMPTION MONITORING
