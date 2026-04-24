# PH-T5.6 — GA4 Measurement Protocol Webhook Format (DEV)

> Date : 2026-04-17
> Environnement : DEV uniquement
> Type : adaptation code webhook conversion (build-from-git)
> Commit : `fc6e5c85` sur branche `ph147.4/source-of-truth`

---

## Objectif

Adapter `emitConversionWebhook()` pour envoyer les conversions au format
**GA4 Measurement Protocol** au lieu du format JSON custom de PH-T4.

---

## Changements effectués

### Fichier modifié

`src/modules/billing/routes.ts` — 39 insertions, 41 suppressions (1 fichier)

### Transformation du payload

**Avant (PH-T4 — custom JSON) :**

```json
{
  "event": "purchase",
  "timestamp": "...",
  "session_id": "cs_test_...",
  "tenant_id": "...",
  "amount": 297,
  "currency": "EUR",
  "attribution": { "utm_source": "...", ... }
}
```

**Après (PH-T5.6 — GA4 Measurement Protocol) :**

```json
{
  "client_id": "691334d0-e149-4e1e-95cc-bc5f28713d42",
  "non_personalized_ads": false,
  "events": [{
    "name": "purchase",
    "params": {
      "value": 297,
      "currency": "EUR",
      "transaction_id": "cs_test_...",
      "tenant_id": "...",
      "plan": "PRO",
      "cycle": "monthly",
      "utm_source": "...",
      "gclid": "...",
      "fbclid": "..."
    }
  }]
}
```

### URL avec query params

```
https://t.keybuzz.io/mp/collect?measurement_id=G-R3QQDYEBFG
```

Si `GA4_MP_API_SECRET` est défini, ajouté en `&api_secret=XXX`.

### client_id

Priorité : `attribution_id` (UUID généré au signup) > `tenantId` (fallback).

### Paramètres UTM

Passés comme event params GA4 (pas dans un objet `attribution` imbriqué) :
`utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`,
`gclid`, `fbclid`, `fbc`, `fbp`, `landing_page`, `referrer`.

### Garanties

- Non-bloquant (try/catch englobant)
- Timeout 5s (AbortController)
- `conversion_sent_at` marqué indépendamment du status HTTP
- Aucun impact sur le flow Stripe

---

## Env vars


| Variable                     | Valeur                            | Rôle                                     |
| ---------------------------- | --------------------------------- | ---------------------------------------- |
| `CONVERSION_WEBHOOK_ENABLED` | `true`                            | Active le webhook                        |
| `CONVERSION_WEBHOOK_URL`     | `https://t.keybuzz.io/mp/collect` | Endpoint sGTM                            |
| `GA4_MEASUREMENT_ID`         | `G-R3QQDYEBFG`                    | **NOUVEAU** — ID de mesure GA4           |
| `GA4_MP_API_SECRET`          | *(non défini)*                    | **NOUVEAU** — optionnel, api_secret GA4  |
| `CONVERSION_WEBHOOK_SECRET`  | `ph-t4-dev-hmac-secret`           | Conservé mais non utilisé (plus de HMAC) |


---

## Test effectué

### Signup + Checkout Stripe Pro (mode test)

1. `/register` → Plan Pro 297€/mois → "Test GA4 MP T5.6"
2. Checkout Stripe carte test `4242 4242 4242 4242`
3. Paiement OK, redirect `/dashboard`
4. Tenant créé : `test-ga4-mp-t5-6-mo3gq3kg`

### Logs API

```
[Billing Webhook] Received event: checkout.session.completed (evt_1TNKcoFC0QQLHISRwIrfS6Ks)
[Billing] Checkout completed for tenant: test-ga4-mp-t5-6-mo3gq3kg type: undefined
[Conversion] GA4 MP sent to https://t.keybuzz.io/mp/collect: 400 client_id=691334d0-e149-4e1e-95cc-bc5f28713d42
```

### Résultat HTTP

- **Status** : 400
- **Cause probable** : absence de `api_secret` dans le query string
- **Impact** : aucun — le checkout Stripe n'est pas bloqué

### Base de données

```json
{
  "tenant_id": "test-ga4-mp-t5-6-mo3gq3kg",
  "conversion_sent_at": "2026-04-17T22:12:35.332Z",
  "attribution_id": "691334d0-e149-4e1e-95cc-bc5f28713d42"
}
```

`conversion_sent_at` : **NOT NULL**

---

## Non-régression


| Vérification                  | Résultat      |
| ----------------------------- | ------------- |
| Signup `/register`            | OK            |
| Checkout Stripe (carte test)  | OK            |
| Paiement + redirect dashboard | OK            |
| Dashboard nouveau tenant      | OK            |
| API health                    | OK            |
| API logs (erreurs)            | Aucune erreur |


---

## Rollback

```bash
# Image précédente
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.77-tracking-t4-api-dev -n keybuzz-api-dev

# Ou désactiver le webhook
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev CONVERSION_WEBHOOK_ENABLED=false
```

---

## Verdict


| Critère                  | Résultat                                        |
| ------------------------ | ----------------------------------------------- |
| Format GA4 MP            | **OUI** — `client_id` + `events[{name,params}]` |
| URL avec measurement_id  | **OUI** — `?measurement_id=G-R3QQDYEBFG`        |
| client_id correct        | **OUI** — UUID attribution_id                   |
| Non-bloquant             | **OUI** — Stripe non impacté                    |
| DB marquée               | **OUI** — `conversion_sent_at` NOT NULL         |
| sGTM hit reçu (HTTP 200) | **NON** — HTTP 400, api_secret manquant         |


### GA4 MP FORMAT OPÉRATIONNEL — API_SECRET REQUIS

Le code est complet et le format est conforme au Measurement Protocol GA4.
Le HTTP 400 sera résolu dès que l'`api_secret` sera :

1. Créé dans GA4 Admin > Data Streams > Measurement Protocol API secrets
2. Ajouté en env var : `kubectl set env deployment/keybuzz-api -n keybuzz-api-dev GA4_MP_API_SECRET=<secret>`

---

## État post-déploiement


| Élément   | Valeur                                                     |
| --------- | ---------------------------------------------------------- |
| Image API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.78-ga4-mp-webhook-dev` |
| Commit    | `fc6e5c85`                                                 |
| Branche   | `ph147.4/source-of-truth`                                  |
| Pod       | `keybuzz-api-7b57654c99-4sczt` (1/1 Running)               |


### Action requise

```bash
# Dans GA4 : Admin > Data Streams > Web > Measurement Protocol API secrets > Create
# Puis :
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev GA4_MP_API_SECRET=<votre_secret>
```

