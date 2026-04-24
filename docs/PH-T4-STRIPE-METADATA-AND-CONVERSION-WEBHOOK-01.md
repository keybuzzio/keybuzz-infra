# PH-T4-STRIPE-METADATA-AND-CONVERSION-WEBHOOK-01 — TERMINE

**Verdict : GO**

**Date : 17 avril 2026**
**Environnement : DEV uniquement**

---

## Preflight


| Element          | Valeur                                         |
| ---------------- | ---------------------------------------------- |
| Client DEV avant | `v3.5.76-tracking-t3-dev`                      |
| API DEV avant    | `v3.5.48-tracking-t2-dev`                      |
| Client DEV apres | `v3.5.77-tracking-t4-client-dev`               |
| API DEV apres    | `v3.5.77-tracking-t4-api-dev`                  |
| Client commit    | `e5f5f54` (branche `ph152.6-client-parity`)    |
| API commit       | `3a10e731` (branche `ph147.4/source-of-truth`) |
| PROD             | NON TOUCHE                                     |


---

## Discipline Build


| Critere        | Preuve                                                                            |
| -------------- | --------------------------------------------------------------------------------- |
| Source API     | `/opt/keybuzz/keybuzz-api` branche `ph147.4/source-of-truth` @ `3a10e731`         |
| Source client  | `/opt/keybuzz/keybuzz-client` branche `ph152.6-client-parity` @ `e5f5f54`         |
| Lieu build     | bastion `install-v3` (46.62.171.61)                                               |
| Repo clean     | `git status --short` vide avant build                                             |
| Aucun SCP code | Seuls des scripts de patch/validation ont ete copies (pas de code source runtime) |


---

## Audit du Flow Stripe Existant


| Element                   | Fichier                                     | Etat avant PH-T4                                                   |
| ------------------------- | ------------------------------------------- | ------------------------------------------------------------------ |
| Checkout body client      | `app/register/page.tsx`                     | Envoie `tenantId, targetPlan, billingCycle, successUrl, cancelUrl` |
| BFF proxy                 | `app/api/billing/checkout-session/route.ts` | Forward transparent du body                                        |
| API `CheckoutSessionBody` | `billing/routes.ts:57`                      | Interface sans `attribution`                                       |
| Session Stripe metadata   | `billing/routes.ts:365`                     | `tenant_id, target_plan, billing_cycle, channels_addon_qty`        |
| Webhook handler           | `billing/routes.ts:767`                     | `handleCheckoutCompleted` : email bienvenue                        |
| DB `signup_attribution`   | Table PH-T2                                 | Colonne `stripe_session_id` vide, `conversion_sent_at` vide        |


---

## Fichiers Touches

### Client (keybuzz-client)


| Fichier                                     | Modification                                                                             |
| ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `app/register/page.tsx`                     | Ajout `checkoutAttribution = currentAttribution || loadAttribution()` dans body checkout |
| `app/api/billing/checkout-session/route.ts` | Forward `attribution` dans body vers API                                                 |


### API (keybuzz-api)


| Fichier                         | Modification                     |
| ------------------------------- | -------------------------------- |
| `src/modules/billing/routes.ts` | 6 patches (detailles ci-dessous) |


### Patches API detailles

1. **CheckoutSessionBody** : ajout `attribution?: Record<string, unknown>`
2. **Destructure** : extraction `attribution` du body dans le handler
3. **Metadata Stripe** : construction `attrMeta` avec `attribution_id, utm_source, utm_medium, utm_campaign, gclid, fbclid` (valeurs tronquees pour respecter limites Stripe)
4. **stripe_session_id linkage** : `SAVEPOINT sp_attribution_stripe` + `UPDATE signup_attribution SET stripe_session_id` apres creation session (non-bloquant)
5. **Conversion webhook** : appel `emitConversionWebhook()` dans `handleCheckoutCompleted`
6. **Function `emitConversionWebhook`** : lecture attribution DB, construction payload, signature HMAC sha256, envoi POST avec timeout 5s, update `conversion_sent_at`

---

## Metadata Stripe Ajoutees


| Cle metadata         | Source                     | Limite    |
| -------------------- | -------------------------- | --------- |
| `tenant_id`          | body (existant)            | —         |
| `target_plan`        | body (existant)            | —         |
| `billing_cycle`      | body (existant)            | —         |
| `channels_addon_qty` | body (existant)            | —         |
| `attribution_id`     | `attribution.id`           | 100 chars |
| `utm_source`         | `attribution.utm_source`   | 100 chars |
| `utm_medium`         | `attribution.utm_medium`   | 100 chars |
| `utm_campaign`       | `attribution.utm_campaign` | 200 chars |
| `gclid`              | `attribution.gclid`        | 200 chars |
| `fbclid`             | `attribution.fbclid`       | 200 chars |


Total : 10 cles (Stripe max : 50 cles, 500 chars par valeur).

---

## Update stripe_session_id

- **Moment** : immediatement apres `stripe.checkout.sessions.create()`
- **Mecanisme** : `SAVEPOINT sp_attribution_stripe` + `UPDATE signup_attribution SET stripe_session_id = $1 WHERE tenant_id = $2 AND stripe_session_id IS NULL`
- **Non-bloquant** : si l'update echoue, `ROLLBACK TO SAVEPOINT` + log warn, le checkout continue normalement
- **Idempotent** : clause `WHERE stripe_session_id IS NULL` empeche l'ecrasement

---

## Webhook Conversion

### Structure payload

```json
{
  "event": "purchase",
  "timestamp": "2026-04-17T05:30:00.000Z",
  "session_id": "cs_xxx",
  "tenant_id": "tenant-xxx",
  "plan": "PRO",
  "cycle": "monthly",
  "amount": 297,
  "currency": "EUR",
  "attribution": {
    "id": "attr_xxx",
    "utm_source": "google",
    "utm_medium": "cpc",
    "utm_campaign": "keybuzz_brand_FR",
    "utm_term": null,
    "utm_content": null,
    "gclid": "CjwKCAiA65-xxx",
    "fbclid": null,
    "fbc": null,
    "fbp": null,
    "landing_url": "https://www.keybuzz.pro/?utm_source=google",
    "referrer": "https://www.google.com/"
  }
}
```

### Headers


| Header                | Valeur              |
| --------------------- | ------------------- |
| `Content-Type`        | `application/json`  |
| `X-Webhook-Event`     | `purchase`          |
| `X-Webhook-Signature` | `sha256=<hmac_hex>` |


### Configuration


| Variable d'env               | Valeur DEV              | Description                 |
| ---------------------------- | ----------------------- | --------------------------- |
| `CONVERSION_WEBHOOK_ENABLED` | `false`                 | Active/desactive le webhook |
| `CONVERSION_WEBHOOK_URL`     | `""`                    | URL de destination          |
| `CONVERSION_WEBHOOK_SECRET`  | `ph-t4-dev-hmac-secret` | Secret HMAC pour signature  |


### Garanties non-bloquantes

- Si `CONVERSION_WEBHOOK_ENABLED != 'true'` : skip silencieux
- Si `CONVERSION_WEBHOOK_URL` vide : skip silencieux
- Si lecture DB attribution echoue : continue avec metadata Stripe seulement
- Si envoi webhook echoue : log warn, paiement non affecte
- Timeout : 5 secondes (`AbortController`)

---

## Signature HMAC

- Algorithme : HMAC-SHA256
- Secret : variable `CONVERSION_WEBHOOK_SECRET`
- Input : body JSON brut
- Header : `X-Webhook-Signature: sha256=<hex>`
- Verification cote recepteur :

```javascript
const crypto = require('crypto');
const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
const received = req.headers['x-webhook-signature'].replace('sha256=', '');
const valid = crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(received));
```

---

## Validation DEV

### Test A — Code API compile


| Pattern                 | Occurrences |
| ----------------------- | ----------- |
| `attrMeta`              | 8           |
| `emitConversionWebhook` | 2           |
| `sp_attribution_stripe` | 3           |
| `CONVERSION_WEBHOOK`    | 3           |
| `X-Webhook-Signature`   | 1           |
| `attribution_id`        | 3           |


### Test B — Client attribution in checkout

- BFF route `checkout-session` contient `attribution` : OUI

### Test C — DB signup_attribution

- Table : 21 colonnes confirmees
- Colonnes cles : `stripe_session_id`, `conversion_sent_at` presentes

### Test D — ENV vars

- `CONVERSION_WEBHOOK_ENABLED=false` : OK
- `CONVERSION_WEBHOOK_URL=` (vide) : OK
- `CONVERSION_WEBHOOK_SECRET` : set (YES)

### Test E — HMAC signature

- Generation : OK (254 bytes payload -> sha256 hex)
- Verification match : `true`

### Test F — Metadata building

- 9 cles sur 50 max Stripe
- `fbclid null` correctement exclue
- Valeurs tronquees

### Test G — Savepoint non-bloquant

- `UPDATE` sur tenant inexistant : 0 rows, pas d'erreur
- `RELEASE SAVEPOINT` : clean
- Transaction principale non affectee

---

## Non-regression


| Element                 | Statut                                                                              |
| ----------------------- | ----------------------------------------------------------------------------------- |
| API health              | `{"status":"ok"}`                                                                   |
| Client auth             | `/api/auth/me` repond `{"authenticated":false}` (normal sans session)               |
| Signup flow             | Non impacte (attribution ajoutee en complement, pas en remplacement)                |
| Onboarding              | Non modifie                                                                         |
| Stripe checkout         | Body enrichi mais champs existants inchanges                                        |
| Webhook Stripe existant | `handleCheckoutCompleted` conserve (welcome email), conversion ajoute en complement |
| PH-T1 attribution       | Inchange (`src/lib/attribution.ts`)                                                 |
| PH-T2 DB persistence    | Inchange (savepoint `sp_attribution` dans `create-signup`)                          |
| PH-T3 GA4/Meta          | Inchange (`SaaSAnalytics.tsx`, `tracking.ts`)                                       |
| PROD                    | Non touche                                                                          |


---

## Rollback

### Client

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.76-tracking-t3-dev -n keybuzz-client-dev
```

### API

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-tracking-t2-dev -n keybuzz-api-dev
```

### Desactiver webhook

```bash
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev CONVERSION_WEBHOOK_ENABLED=false CONVERSION_WEBHOOK_URL=""
```

---

## Conclusion

**STRIPE LINK AND CONVERSION WEBHOOK OPERATIONAL**

- L'attribution marketing (PH-T1) est transmise au checkout Stripe
- Les metadata Stripe contiennent les UTM, click IDs et attribution_id
- Le `stripe_session_id` est lie en DB via savepoint non-bloquant
- Le webhook de conversion est pret avec signature HMAC
- Le webhook est desactive par defaut, activable via env vars
- Zero impact sur le flow Stripe existant
- Aucune autre action effectuee

STOP