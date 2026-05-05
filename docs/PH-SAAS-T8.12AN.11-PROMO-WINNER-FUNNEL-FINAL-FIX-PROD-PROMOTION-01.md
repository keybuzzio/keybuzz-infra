# PH-SAAS-T8.12AN.11 — Promo Winner Funnel Final Fix PROD Promotion

> Phase : PH-SAAS-T8.12AN.11-PROMO-WINNER-FUNNEL-FINAL-FIX-PROD-PROMOTION-01
> Date : 2026-05-05
> Environnement : PROD
> Type : promotion PROD ciblée API uniquement, GitOps strict
> Verdict : **GO PROD FINAL FIX**

---

## Résumé

Promotion en PROD du fix AN.10.2 validé en DEV. Ce fix corrige le dernier blocage du parcours bon concours PRO 1 an : le webhook `checkout.session.completed` peut désormais envoyer un email de bienvenue promo-aware quel que soit le `discount_type` du coupon Stripe.

Changement : **1 ligne** dans `billing/routes.ts` — condition simplifiée de `if (promoCode && promoDiscountType === 'plan_only')` à `if (promoCode)`.

Aucun checkout LIVE créé, aucun paiement, aucun email PROD envoyé pendant cette phase.

---

## Sources de vérité lues

| Document | Statut |
|---|---|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu |
| `AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` | Lu |
| `PH-SAAS-T8.12AN.8-PROMO-VISIBLE-PRICE-PREVIEW-AND-CARD-CLARITY-DEV-01.md` | Lu |
| `PH-SAAS-T8.12AN.9-PROMO-VISIBLE-PRICE-PREVIEW-PROD-PROMOTION-01.md` | Lu |
| `PH-SAAS-T8.12AN.10.1-PROMO-WINNER-FUNNEL-DEV-BROWSER-E2E-VALIDATION-01.md` | Lu |
| `PH-SAAS-T8.12AN.10.2-PROMO-RETRY-CHECKOUT-METADATA-EMAIL-FIX-DEV-01.md` | Lu |
| `PH-SAAS-T8.12Y.4-TRANSACTIONAL-EMAIL-DESIGN-PROD-PROMOTION-01.md` | Lu |

Note : `PH-SAAS-T8.12AN.10` n'existe pas en fichier distinct — le travail est documenté dans AN.10.1 et AN.10.2.

---

## ÉTAPE 0 — Preflight

| Élément | Valeur | Verdict |
|---|---|---|
| keybuzz-infra branche | `main` | OK |
| keybuzz-api branche | `ph147.4/source-of-truth` | OK |
| keybuzz-api HEAD | `7a27eafc` (fix AN.10.2) | OK |
| API PROD runtime (avant) | `v3.5.141-promo-preview-prod` | OK |
| API PROD manifest (avant) | `v3.5.141-promo-preview-prod` | OK (aligné) |
| Client PROD runtime | `v3.5.153-promo-visible-price-prod` | OK (inchangé) |
| Website PROD runtime | `v0.6.9-promo-forwarding-prod` | OK (inchangé) |
| Backend PROD runtime | `v1.0.42-amazon-oauth-inbound-bridge-prod` | OK (inchangé) |
| Admin PROD | namespace vide | OK (conforme AN.9) |
| API DEV runtime | `v3.5.155-promo-retry-metadata-email-dev` | OK (fix AN.10.2) |
| API PROD health | `{"status":"ok"}` | OK |
| Stripe LIVE sessions 24h | 1 (code gagnant #1, consommé avant AN.11) | OK |
| Stripe mode | LIVE | OK |

---

## ÉTAPE 1 — Vérification source AN.10.2

Commit : `7a27eafc` — 1 fichier, 1 ligne changée.

| Brique | Vérification | Résultat |
|---|---|---|
| Condition webhook corrigée | `if (promoCode)` à L1793 | OK |
| Plus de gate `plan_only` bloquante | Absente du webhook (L594 est dans les metadata, pas dans le webhook) | OK |
| Email promo-aware template | "bon concours est appliqué" à L1804-1805 | OK |
| Email standard préservé | "Votre abonnement est actif" à L1791 | OK |
| `PROMO_PLAN_MISMATCH` guard | L400 + L573 | OK |
| `payment_method_collection: 'always'` | L424 | OK |
| annual/yearly mapping | L255-256, L508 | OK |
| Schema-agnostic AN.9 | 6 occurrences | OK |
| Pas de hardcode | 0 résultat | OK |
| Pas de changement addon/KBActions | Refs existantes non modifiées | OK |
| Retry metadata supportées | Code identique initial/retry (validé AN.10.2) | OK |

---

## ÉTAPE 2 — Build API PROD

| Service | Tag | Digest | Commit source | Branche | Build-from-git |
|---|---|---|---|---|---|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.142-promo-retry-email-prod` | `sha256:c49ab6f44493669525c08df389568808db6fdf57f57d3fe9aa11e2de025e361f` | `7a27eafc` | `ph147.4/source-of-truth` | Clone propre `/tmp/keybuzz-api-build-an11` |

Build Docker `--no-cache`, `rm -rf dist/` forcé avant build, repo clean vérifié, commit HEAD confirmé.

---

## ÉTAPE 3 — Validation image avant GitOps

| Check image | Résultat | Verdict |
|---|---|---|
| Fix webhook `if (promoCode)` | L1511 dans dist | OK |
| Email promo-aware | 2 refs | OK |
| Email standard | 1 ref | OK |
| PROMO_PLAN_MISMATCH | 2 refs | OK |
| payment_method_collection | 1 ref | OK |
| promo-preview endpoint | 3 refs | OK |
| Schema-agnostic | 2 refs | OK |
| Secrets dans le bundle | 0 | OK |
| `plan_only` gate webhook | ABSENT (supprimée) | OK |

---

## ÉTAPE 4 — GitOps PROD API uniquement

| Action | Détail |
|---|---|
| Manifest modifié | `k8s/keybuzz-api-prod/deployment.yaml` |
| Diff | 1 ligne : image `v3.5.141-promo-preview-prod` → `v3.5.142-promo-retry-email-prod` |
| Commit infra | `e3b18b0` sur `main` |
| Push | `origin/main` OK |
| `kubectl apply -f` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `successfully rolled out` |
| Runtime = Manifest | `v3.5.142-promo-retry-email-prod` confirmé |
| Pod | `keybuzz-api-75f5665fb7-dlhdv` 1/1 Running |
| Restarts | 0 |
| Health post-deploy | `{"status":"ok"}` |

### Rollback GitOps

```
# Modifier k8s/keybuzz-api-prod/deployment.yaml :
# image: ghcr.io/keybuzzio/keybuzz-api:v3.5.141-promo-preview-prod
# git add + commit + push
# kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
# kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

---

## ÉTAPE 5 — Validation PROD sans checkout LIVE

| Test PROD | Attendu | Résultat | Verdict |
|---|---|---|---|
| API health | `{"status":"ok"}` | OK | OK |
| Stripe mode | LIVE | LIVE | OK |
| Promo-preview PRO annual | valid, original=285600, discount=285600, due=0 | Conforme | OK |
| Promo-preview AUTOPILOT annual | valid, original=477600, discount=285600, due=192000 | Conforme | OK |
| Message PRO annual | "offert pendant 12 mois" | Conforme | OK |
| Code LIVE redeemed | 0/1 | 0/1 | OK |
| Checkout sessions 1h | 0 | 0 | OK |
| Charges 1h | 0 | 0 | OK |
| Payment intents 1h | 0 | 0 | OK |
| Client PROD | `v3.5.153-promo-visible-price-prod` | Inchangé | OK |
| Website PROD | `v0.6.9-promo-forwarding-prod` | Inchangé | OK |
| Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` | Inchangé | OK |

---

## ÉTAPE 6 — Non-régression billing / email

| Risque | Vérification | Verdict |
|---|---|---|
| Email standard perdu | Template "abonnement est actif" PRESENT | OK |
| Email promo-aware absent | Template "bon concours" PRESENT | OK |
| Condition promo isolée | `if (promoCode)` PRESENT | OK |
| `payment_method_collection` | PRESENT | OK |
| `PROMO_PLAN_MISMATCH` | PRESENT | OK |
| Existing subscriptions | 7 (inchangé) | OK |
| Existing billing_customers | 10 (inchangé) | OK |
| Code LIVE PROD | active, redeemed=0/1 (inchangé) | OK |
| billing_events 1h | 0 | OK |
| Fake purchase / CAPI | 0 | OK |

---

## ÉTAPE 7 — Non-régression services

| Surface | Résultat | Verdict |
|---|---|---|
| API health | `{"status":"ok"}` | OK |
| Client /register | 200 | OK |
| Client /login | 200 | OK |
| Website /pricing | 200 | OK |
| Website / | 200 | OK |
| CronJobs API PROD | outbound-tick, sla-evaluator, trial-lifecycle, carrier-tracking | OK |
| CronJobs Backend PROD | amazon-orders-sync, amazon-reports-tracking | OK |
| Outbound Worker | `v3.5.165-escalation-flow-prod` (inchangé) | OK |
| Backend | `v1.0.42-amazon-oauth-inbound-bridge-prod` (inchangé) | OK |
| All pods Running | Confirmé | OK |

---

## Images finales

| Service | Avant AN.11 | Après AN.11 | Rollback |
|---|---|---|---|
| API PROD | `v3.5.141-promo-preview-prod` | `v3.5.142-promo-retry-email-prod` | `v3.5.141-promo-preview-prod` |
| Client PROD | `v3.5.153-promo-visible-price-prod` | inchangé | — |
| Website PROD | `v0.6.9-promo-forwarding-prod` | inchangé | — |
| Backend PROD | `v1.0.42-amazon-oauth-inbound-bridge-prod` | inchangé | — |
| Outbound Worker | `v3.5.165-escalation-flow-prod` | inchangé | — |

---

## ÉTAPE 8 — Linear

Token Linear non disponible. Commentaires préparés pour :

- **KEY-245** : Phase AN.11 promue. Webhook promo-aware live. Promo-preview conforme. À garder ouvert pour AN.12.
- **KEY-246** : Retry checkout supporté avec metadata promo. Fix webhook LIVE. À valider avec prochain checkout réel.
- **KEY-247** : Fix webhook email promo-aware LIVE. Condition `plan_only` supprimée. Prêt pour le prochain checkout avec code concours.

---

## Recommandation AN.12

Pour finaliser le parcours gagnant concours :

1. Créer le **nouveau code concours LIVE final** (le premier est consommé)
2. Configurer le coupon Stripe LIVE avec le scope correct (`applies_to_products`)
3. Tester le lien register complet en navigateur PROD avec le nouveau code
4. Vérifier que l'email de bienvenue promo-aware est bien reçu par le gagnant
5. Fermer KEY-245, KEY-246, KEY-247 après confirmation

---

## Verdict

**GO PROD FINAL FIX**

PROMO WINNER FUNNEL FINAL FIX LIVE IN PROD — WEBHOOK EMAIL PROMO-AWARE READY — RETRY CHECKOUT METADATA SUPPORTED — INITIAL CHECKOUT PRESERVED — ANNUAL CYCLE PRESERVED — NO LIVE CHECKOUT — NO PAYMENT — NO EMAIL SENT — API GITOPS STRICT — READY TO CREATE FINAL WINNER CODE
