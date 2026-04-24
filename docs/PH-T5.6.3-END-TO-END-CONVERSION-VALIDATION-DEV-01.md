# PH-T5.6.3-END-TO-END-CONVERSION-VALIDATION-DEV-01

> Date : 18 avril 2026
> Environnement : DEV uniquement
> Type : validation finale tracking end-to-end
> Aucun build, aucun patch code, aucune modification branche

---

## VERDICT

### TRACKING NOT FULLY VALIDATED — BLOCKER IDENTIFIÉ

Le pipeline API → sGTM est **opérationnel** (HTTP 200).
Le tag sGTM → GA4/Meta ne **forward pas** les events vers GA4.

---

## Préflight (ÉTAPE 0)


| Élément                      | Valeur                             |
| ---------------------------- | ---------------------------------- |
| Client DEV image             | `v3.5.79-tracking-t5.3-replay-dev` |
| API DEV image                | `v3.5.78-ga4-mp-webhook-dev`       |
| sGTM version                 | Version 2 (publiée 18/04/2026)     |
| `CONVERSION_WEBHOOK_ENABLED` | `true`                             |
| `CONVERSION_WEBHOOK_URL`     | `https://t.keybuzz.io/mp/collect`  |
| `GA4_MEASUREMENT_ID`         | `G-R3QQDYEBFG`                     |
| `GA4_MP_API_SECRET`          | **SET** (`BqL-n...`)               |
| Stripe key                   | `sk_test_...` (mode test)          |
| Stripe webhook secret        | `whsec_...` (configuré)            |
| `/mp/collect` HTTP preflight | **200**                            |
| Aucun build                  | Confirmé                           |
| Aucun patch                  | Confirmé                           |


---

## Test Funnel Complet (ÉTAPE 1)

### 1. Website → SaaS


| CTA Website | URL                                                       | Attribution  |
| ----------- | --------------------------------------------------------- | ------------ |
| Starter     | `client.keybuzz.io/register?plan=starter&cycle=monthly`   | plan + cycle |
| Pro         | `client.keybuzz.io/register?plan=pro&cycle=monthly`       | plan + cycle |
| Autopilot   | `client.keybuzz.io/register?plan=autopilot&cycle=monthly` | plan + cycle |
| GA4 gtag.js | `G-R3QQDYEBFG` présent dans HTML                          | Actif        |


UTM params (`utm_source`, `utm_medium`, `gclid`, `fbclid`) : capturés par gtag.js
depuis l'URL d'arrivée, stockés dans cookies GA4. Non présents dans les CTAs eux-mêmes.

### 2. Signup


| Élément        | Résultat                                                |
| -------------- | ------------------------------------------------------- |
| URL            | `client-dev.keybuzz.io/register?plan=pro&cycle=monthly` |
| Formulaire     | Complété (Test E2E PH563)                               |
| OTP            | Validé (code DEV affiché)                               |
| Tenant créé    | `test-e2e-ph563-mo3wa85t`                               |
| Plan           | PRO                                                     |
| Status initial | `pending_payment`                                       |


### 3. Attribution capturée


| Champ            | Valeur                                                          |
| ---------------- | --------------------------------------------------------------- |
| `attribution_id` | `c885cc1d-3b35-4821-bcf1-db02d07709cd`                          |
| `plan`           | `pro`                                                           |
| `cycle`          | `monthly`                                                       |
| `fbp`            | `fb.1.1776428335013.824256521998960206`                         |
| `landing_url`    | `https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly` |
| `utm_source`     | null (pas d'UTM dans URL de test)                               |
| `gclid`          | null (pas de gclid dans URL de test)                            |


### 4. Stripe


| Élément          | Résultat                                                      |
| ---------------- | ------------------------------------------------------------- |
| Checkout Session | `cs_test_b1Iao627...` créée                                   |
| Customer         | `cus_UM9ibb8r4HZM2p`                                          |
| Metadata Stripe  | `attribution_id`, `tenant_id`, `target_plan`, `billing_cycle` |
| Payment Method   | `pm_1TNRTdFC0QQLHISRAFX22N4j` (tok_visa)                      |
| Subscription     | `sub_1TNRV8FC0QQLHISR297Nn1GY`                                |
| Status           | `trialing` (14j)                                              |
| Price            | `price_1SmO9uFC0QQLHISRwu8eFnyh` (297 EUR/mois)               |


Note : checkout complété via API Stripe (iframe Stripe non accessible en automatisation).

---

## Validation API (ÉTAPE 2)

### Webhook `customer.subscription.created`

```
[Billing Webhook] Received event: customer.subscription.created (evt_1TNRVAFC0QQLHISRQu9WqVo3)
[Billing] Subscription updated for test-e2e-ph563-mo3wa85t: PRO monthly status=trialing
[Billing] Tenant test-e2e-ph563-mo3wa85t activated from pending_payment
[Billing] KBActions initial grant: 1000 for test-e2e-ph563-mo3wa85t (plan=PRO)
```

### Webhook `checkout.session.completed` (simulé avec signature HMAC valide)

```
[Billing Webhook] Received event: checkout.session.completed (evt_test_ph563_e2e_1776490469204)
[Billing] Checkout completed for tenant: test-e2e-ph563-mo3wa85t type: undefined
[Conversion] GA4 MP sent to https://t.keybuzz.io/mp/collect: 200 client_id=c885cc1d-3b35-4821-bcf1-db02d07709cd
[Billing] Welcome email sent to: ludo.gonthier@gmail.com
```


| Vérification                      | Résultat                                           |
| --------------------------------- | -------------------------------------------------- |
| Webhook Stripe reçu               | **OUI**                                            |
| `emitConversionWebhook` déclenché | **OUI**                                            |
| POST vers `/mp/collect`           | **OUI**                                            |
| HTTP **200**                      | **OUI**                                            |
| `client_id` = `attribution_id`    | **OUI** (`c885cc1d-...`)                           |
| Welcome email                     | **OUI**                                            |
| Non-bloquant                      | **OUI** (response time 1169ms, Stripe non impacté) |


---

## Validation sGTM (ÉTAPE 3)


| Vérification        | Résultat                                      |
| ------------------- | --------------------------------------------- |
| `/mp/collect` claim | **OUI** (HTTP 200, était 400 avant PH-T5.6.2) |
| Client GA4 MP actif | **OUI** (Version 2 publiée)                   |
| Preview Addingwell  | Non accessible (permissions compte)           |


Le sGTM **reçoit et accepte** les hits MP. L'étape sGTM → GA4/Meta est le point de blocage.

---

## Validation GA4 (ÉTAPE 4)


| Vérification               | Résultat                          |
| -------------------------- | --------------------------------- |
| Propriété GA4              | KeyBuzz (a391528180p533203633)    |
| Measurement ID             | `G-R3QQDYEBFG`                    |
| Realtime (30 min)          | **0 utilisateurs, aucune donnée** |
| Event `purchase` visible   | **NON**                           |
| Events browser (page_view) | Visibles sur 7 jours (89 events)  |


### Diagnostic

Les hits browser (gtag.js → `t.keybuzz.pro/g/collect`) apparaissent dans GA4 (89 events, 9 users).
Les hits Measurement Protocol (API → `t.keybuzz.io/mp/collect`) **n'apparaissent pas**.

**Cause probable** : le tag "GA4 - All Events" dans le sGTM est configuré pour forward
vers GA4, mais il ne transmet pas correctement les events reçus via le client MP.
Possibilités :

1. Le tag GA4 dans sGTM utilise un measurement ID différent
2. Le tag ne fire pas sur les events du client GA4 MP (déclencheur "All Pages" = browser only ?)
3. Le tag manque l'API secret pour le forwarding server-to-server

### Action requise

Vérifier dans GTM Server Container (GTM-NTPDQ7N7) :

1. Le tag "GA4 - All Events" : quel measurement ID utilise-t-il ?
2. Le déclencheur du tag : fire-t-il sur TOUS les clients (GA4 Web + GA4 MP) ?
3. Configurer un déclencheur "All Events" (pas "All Pages") si nécessaire

---

## Validation Meta (ÉTAPE 5)


| Vérification                 | Résultat                             |
| ---------------------------- | ------------------------------------ |
| Tag "Meta CAPI - All Events" | Publié dans sGTM v2                  |
| Event `Purchase` visible     | **NON VÉRIFIÉ** (même cause que GA4) |


Si le tag GA4 ne fire pas sur les events MP, le tag Meta CAPI ne fire probablement pas non plus
(même déclencheur).

---

## Validation DB (ÉTAPE 6)

```json
{
  "tenant_id": "test-e2e-ph563-mo3wa85t",
  "attribution_id": "c885cc1d-3b35-4821-bcf1-db02d07709cd",
  "conversion_sent_at": "2026-04-18T05:34:29.433Z",
  "plan": "pro",
  "cycle": "monthly",
  "fbp": "fb.1.1776428335013.824256521998960206",
  "landing_url": "https://client-dev.keybuzz.io/register?plan=pro&cycle=monthly"
}
```


| Vérification                     | Résultat                   |
| -------------------------------- | -------------------------- |
| `conversion_sent_at` IS NOT NULL | **OUI**                    |
| `attribution_id` présent         | **OUI**                    |
| `tenant_id` présent              | **OUI**                    |
| `plan` + `cycle`                 | **OUI** (`pro`, `monthly`) |
| `fbp` capturé                    | **OUI**                    |
| Tenant status                    | `active`                   |


---

## Non-régression (ÉTAPE 7)


| Test                      | Résultat                    |
| ------------------------- | --------------------------- |
| SaaS Dashboard            | 307 (redirect auth, normal) |
| SaaS Login                | **200**                     |
| SaaS Register             | **200**                     |
| SaaS Pricing              | **200**                     |
| API Health                | **200** `{"status":"ok"}`   |
| Website Home              | **200**                     |
| Website Pricing           | **200**                     |
| `t.keybuzz.pro/g/collect` | **200**                     |
| `t.keybuzz.io/g/collect`  | **200**                     |
| API errors (5 min)        | Aucune                      |
| API pod                   | Running (0 restarts)        |
| Client pod                | Running (0 restarts)        |


**Aucune régression.**

---

## Matrice Finale (ÉTAPE 8)


| Étape          | OK/NOK  | Détail                                                            |
| -------------- | ------- | ----------------------------------------------------------------- |
| Website → SaaS | **OK**  | CTAs avec plan+cycle, gtag.js actif                               |
| Attribution    | **OK**  | `attribution_id`, `fbp`, `plan`, `cycle`, `landing_url`           |
| Signup         | **OK**  | Tenant créé, plan PRO, OTP validé                                 |
| Stripe         | **OK**  | Subscription trialing, customer + PM attachés                     |
| API webhook    | **OK**  | `checkout.session.completed` → `emitConversionWebhook` → HTTP 200 |
| sGTM réception | **OK**  | `/mp/collect` claim par GA4 MP client, HTTP 200                   |
| sGTM → GA4     | **NOK** | Tag ne forward pas les events MP vers GA4                         |
| sGTM → Meta    | **NOK** | Même cause — tag ne fire pas sur events MP                        |
| DB             | **OK**  | `conversion_sent_at` NOT NULL, attribution complète               |
| Non-régression | **OK**  | Tous services opérationnels                                       |


---

## Résumé

### Ce qui FONCTIONNE (8/10)

1. Website avec gtag.js et CTAs vers SaaS
2. Capture d'attribution au signup (UTM, fbp, plan, cycle, landing_url)
3. Création tenant + subscription Stripe
4. Webhook Stripe reçu et traité
5. `emitConversionWebhook` envoie le payload GA4 MP
6. sGTM reçoit et accepte le hit (HTTP 200)
7. DB marquée (`conversion_sent_at` NOT NULL)
8. Non-régression OK (aucun impact)

### Ce qui NE FONCTIONNE PAS (2/10)

1. **sGTM → GA4** : le tag "GA4 - All Events" ne forward pas les events Measurement Protocol
2. **sGTM → Meta CAPI** : même cause

### Cause racine

Le tag "GA4 - All Events" dans le sGTM est probablement configuré avec un déclencheur
"All Pages" qui ne fire que sur les events du client GA4 (Web), pas sur les events
du client GA4 MP. Le déclencheur doit être changé en "All Events" ou un déclencheur
custom qui fire sur tous les clients.

### Prochaine étape requise

**PH-T5.7 — Configurer les tags sGTM pour les events Measurement Protocol**

1. Accéder à GTM Server Container `GTM-NTPDQ7N7` (via le bon compte Google)
2. Vérifier le déclencheur du tag "GA4 - All Events"
3. Modifier le déclencheur pour qu'il fire sur **tous les clients** (GA4 Web + GA4 MP)
4. Vérifier que le tag utilise le bon measurement ID (`G-R3QQDYEBFG`)
5. Faire la même vérification pour le tag "Meta CAPI - All Events"
6. Publier Version 3 du container
7. Re-tester avec un hit MP frais et vérifier dans GA4 Realtime

---

**Aucune modification de code KeyBuzz effectuée.**
**Aucun build effectué.**
**Aucune branche modifiée.**

STOP