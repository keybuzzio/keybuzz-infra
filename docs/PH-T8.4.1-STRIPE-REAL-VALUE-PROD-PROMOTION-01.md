# PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01

> Date : 2026-04-21
> Type : Promotion PROD — valeur réelle Stripe dans outbound conversions
> Priorité : CRITIQUE
> Environnement : PROD

---

## 1. OBJECTIF

Promouvoir en PROD le correctif PH-T8.4.1 validé en DEV : remplacer la valeur
approximative basée sur `PLAN_PRICES` par la valeur réelle issue de Stripe dans
les événements outbound conversions StartTrial et Purchase.

---

## 2. PRÉFLIGHT


| Élément           | Valeur                                               |
| ----------------- | ---------------------------------------------------- |
| Branche           | `ph147.4/source-of-truth`                            |
| HEAD              | `c47af816` (= commit PH-T8.4.1)                      |
| Repo              | Clean                                                |
| Image PROD avant  | `v3.5.92-autopilot-promise-detection-guardrail-prod` |
| Image DEV validée | `v3.5.94-outbound-conversions-real-value-dev`        |
| Confirmation      | PROD ne contenait pas le fix (v3.5.92 < v3.5.94)     |


---

## 3. VÉRIFICATION SOURCE


| Point                  | Résultat                                                     |
| ---------------------- | ------------------------------------------------------------ |
| `PLAN_PRICES` supprimé | ✅ 0 occurrence dans `emitter.ts`                             |
| `stripeValue` présent  | ✅ L.66 (param), L.138 (usage), L.139 (currency)              |
| StartTrial réel Stripe | ✅ `session.amount_total / 100` + `session.currency`          |
| Purchase réel Stripe   | ✅ `subscription.items[*].price.unit_amount * quantity / 100` |
| Currency réelle Stripe | ✅ Dynamique aux deux hooks                                   |


---

## 4. BUILD PROD


| Élément      | Valeur                                                                       |
| ------------ | ---------------------------------------------------------------------------- |
| Image        | `ghcr.io/keybuzzio/keybuzz-api:v3.5.94-outbound-conversions-real-value-prod` |
| Digest       | `sha256:42135f77ee9a692d7cf1b2c5ef376574aae63c624a43e37dbc0c64664e21e57a`    |
| Source       | `keybuzz-api@ph147.4/source-of-truth`                                        |
| Commit       | `c47af816`                                                                   |
| Méthode      | `build-api-from-git.sh` (clone propre)                                       |
| `--no-cache` | oui (build-from-git par défaut)                                              |
| Tag immuable | oui                                                                          |


---

## 5. GITOPS PROD


| Élément             | Valeur                                                                          |
| ------------------- | ------------------------------------------------------------------------------- |
| Fichier modifié     | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`                            |
| Commit infra        | `3e4ada8`                                                                       |
| Image avant         | `v3.5.92-autopilot-promise-detection-guardrail-prod`                            |
| Image après         | `v3.5.94-outbound-conversions-real-value-prod`                                  |
| Env vars ajoutées   | `OUTBOUND_CONVERSIONS_WEBHOOK_URL=""`, `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET=""` |
| `kubectl set image` | NON utilisé                                                                     |


### Diff exact

```diff
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.92-autopilot-promise-detection-guardrail-prod
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.94-outbound-conversions-real-value-prod
+            - name: OUTBOUND_CONVERSIONS_WEBHOOK_URL
+              value: ""
+            - name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
+              value: ""
```

---

## 6. DEPLOY PROD


| Élément | Valeur                                               |
| ------- | ---------------------------------------------------- |
| Rollout | `deployment "keybuzz-api" successfully rolled out`   |
| Pod     | `keybuzz-api-5779776754-wb4lw` (Running, 0 restarts) |
| Health  | `{"status":"ok"}`                                    |
| Noeud   | `k8s-worker-02`                                      |


---

## 7. VALIDATION PROD RÉELLE

### Cas A — StartTrial


| Test             | Attendu           | Résultat                                                |
| ---------------- | ----------------- | ------------------------------------------------------- |
| Webhook émis     | HTTP 200          | ✅ `sent for prod-test-t841-trial: HTTP 200 (attempt 1)` |
| `value.amount`   | 0 (trial gratuit) | ✅ `amount=0`                                            |
| `value.currency` | EUR               | ✅ `currency=EUR`                                        |
| Pas de doublon   | idempotence       | ✅ `already sent, skipping`                              |


### Cas B — Purchase


| Test                  | Attendu                   | Résultat                                                   |
| --------------------- | ------------------------- | ---------------------------------------------------------- |
| Purchase EUR émis     | HTTP 200                  | ✅ `sent for prod-test-t841-purchase: HTTP 200 (attempt 2)` |
| `value.amount`        | 497 (réel Stripe)         | ✅ `amount=497`                                             |
| `value.currency`      | EUR                       | ✅ `currency=EUR`                                           |
| Purchase GBP payload  | amount=2376, currency=GBP | ✅ Payload correct en DB                                    |
| Purchase GBP delivery | HTTP 200                  | ⚠️ httpbin.org timeout (3x), status `failed`               |


> Note : le test GBP a échoué en delivery à cause de timeouts httpbin.org (réseau externe),
> mais le payload en DB confirme `amount=2376 currency=GBP` — la construction du payload
> avec devise non-EUR est correctement implémentée.

### Cas C — Tenant test exclu


| Test               | Attendu             | Résultat                                                          |
| ------------------ | ------------------- | ----------------------------------------------------------------- |
| `ecomlg-001` exclu | `skipping Purchase` | ✅ `Tenant ecomlg-001 is exempt (test account), skipping Purchase` |


### Cas D — Non-régression


| Check            | Résultat                                        |
| ---------------- | ----------------------------------------------- |
| API PROD health  | ✅ HTTP 200                                      |
| Billing module   | ✅ chargé                                        |
| Metrics module   | ✅ chargé                                        |
| Autopilot module | ✅ chargé                                        |
| Pod restarts     | ✅ 0                                             |
| Stripe webhook   | ✅ inchangé                                      |
| DEV inchangée    | ✅ `v3.5.94-outbound-conversions-real-value-dev` |


---

## 8. PREUVES — PAYLOADS DB

### StartTrial (preuve montant 0, devise EUR)

```
conv_prod-test-t841-trial_StartTrial_sub_prod_t841_trial | StartTrial | sent | amount=0 currency=EUR
```

### Purchase EUR (preuve montant réel 497)

```
conv_prod-test-t841-purchase_Purchase_sub_prod_t841_purchase | Purchase | sent | amount=497 currency=EUR
```

### Purchase GBP (preuve devise non-EUR)

```
conv_prod-test-t841-gbp_Purchase_sub_prod_t841_gbp | Purchase | failed | amount=2376 currency=GBP
```

> Les 3 rows de test ont été nettoyées après validation.

### Preuve idempotence

```
[OutboundConv] Event conv_prod-test-t841-trial_StartTrial_sub_prod_t841_trial already sent, skipping
```

### Preuve exclusion test

```
[OutboundConv] Tenant ecomlg-001 is exempt (test account), skipping Purchase
```

---

## 9. VALEUR AVANT / APRÈS

### Avant (PROD v3.5.92)

Module outbound conversions **absent** de PROD. Aucun événement émis.

### Après (PROD v3.5.94)


| Event      | Source valeur                           | Exemple                            |
| ---------- | --------------------------------------- | ---------------------------------- |
| StartTrial | `session.amount_total / 100`            | `{ amount: 0, currency: "EUR" }`   |
| Purchase   | `Σ(item.price.unit_amount × qty) / 100` | `{ amount: 297, currency: "EUR" }` |


Aucune estimation par plan. Aucun `PLAN_PRICES`. Valeur 100% Stripe.

---

## 10. ROLLBACK PROD


| Élément             | Valeur                                                                            |
| ------------------- | --------------------------------------------------------------------------------- |
| Image avant         | `v3.5.92-autopilot-promise-detection-guardrail-prod`                              |
| Image après         | `v3.5.94-outbound-conversions-real-value-prod`                                    |
| Commande rollback   | `rollback-service.sh api prod v3.5.92-autopilot-promise-detection-guardrail-prod` |
| Manifest à remettre | Remplacer l'image dans `k8s/keybuzz-api-prod/deployment.yaml`                     |
| Supprimer env vars  | `OUTBOUND_CONVERSIONS_WEBHOOK_URL`, `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET`         |


---

## 11. IMPACT


| Domaine            | Impact             |
| ------------------ | ------------------ |
| Structure payload  | ✅ Aucun changement |
| Idempotence        | ✅ Inchangée        |
| Exclusion test     | ✅ Inchangée        |
| Signature HMAC     | ✅ Inchangée        |
| Retry              | ✅ Inchangé         |
| Admin              | ✅ Non touché       |
| Client SaaS        | ✅ Non touché       |
| Tracking / metrics | ✅ Non touché       |
| Autopilot          | ✅ Non touché       |
| Billing Stripe     | ✅ Non touché       |


---

## VERDICT

**REAL VALUE FROM STRIPE RESTORED IN PROD — NO ESTIMATION — NON REGRESSION OK**