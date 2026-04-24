# KeyBuzz — Conversions Server-Side

## Guide pour media buyers

> Version : 1.0 — Avril 2026
> En prod, testé et validé

---

## C'est quoi en 30 secondes ?

On t'envoie un webhook HTTPS chaque fois qu'un vrai client KeyBuzz :

- **StartTrial** — il entre sa CB et démarre son essai
- **Purchase** — son premier paiement est encaissé

C'est du **100% backend**, pas de pixel, pas de JS. Les données viennent directement de Stripe,
avec toute l'attribution (UTM, gclid, fbclid, ttclid...) et le hash SHA-256 de l'email.

```
Visiteur → s'inscrit → Stripe → notre backend → webhook vers toi
```

Tu n'as rien à installer. On t'envoie les events, tu les mappes dans tes outils.

---

## Les 2 events

### StartTrial

- Se déclenche quand quelqu'un entre sa CB et démarre un trial
- `value.amount` = `0` (c'est un essai gratuit)
- Tu peux l'utiliser pour optimiser le haut du funnel

### Purchase

- Se déclenche quand le premier vrai paiement passe (fin du trial)
- `value.amount` = montant réel facturé par Stripe (ex : `297` pour le plan Pro)
- `value.currency` = la devise réelle (EUR, GBP...)
- C'est le bon event pour calculer ton ROAS

### Ce qu'on n'envoie PAS

- Les simples inscriptions sans CB
- Les renouvellements mensuels
- Les événements frontend ou pixel
- Les comptes de test internes (filtrés automatiquement)

---

## Le payload que tu reçois

Chaque webhook est un POST JSON. Voici un exemple complet :

```json
{
  "event_name": "Purchase",
  "event_id": "conv_tenant-abc_Purchase_sub_1PqR2sT3uV",
  "event_time": "2026-04-21T14:30:00.000Z",

  "customer": {
    "tenant_id": "tenant-abc",
    "email_hash": "a3f5b7c9d1e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2",
    "plan": "pro",
    "billing_cycle": "monthly"
  },

  "subscription": {
    "stripe_subscription_id": "sub_1PqR2sT3uV",
    "status": "active",
    "trial_end": "2026-05-05T14:30:00.000Z",
    "current_period_end": "2026-06-05T14:30:00.000Z"
  },

  "attribution": {
    "utm_source": "facebook",
    "utm_medium": "cpc",
    "utm_campaign": "spring-2026",
    "utm_term": "saas-support",
    "utm_content": "ad-variant-a",
    "gclid": null,
    "fbclid": "IwAR3xyz...",
    "fbc": "fb.1.1681000000000.IwAR3xyz",
    "fbp": "fb.1.1681000000000.1234567890",
    "ttclid": null,
    "landing_url": "https://www.keybuzz.pro/pricing?utm_source=facebook",
    "referrer": "https://www.facebook.com/"
  },

  "value": {
    "amount": 297,
    "currency": "EUR"
  },

  "data_quality": {
    "has_attribution": true,
    "test_excluded": false,
    "source": "stripe_webhook"
  }
}
```

### Les champs importants pour toi


| Champ                          | C'est quoi                                                 |
| ------------------------------ | ---------------------------------------------------------- |
| `event_name`                   | `"StartTrial"` ou `"Purchase"`                             |
| `event_id`                     | ID unique — utilise-le pour dédupliquer                    |
| `event_time`                   | Quand c'est arrivé (UTC, ISO 8601)                         |
| `customer.email_hash`          | SHA-256 de l'email — prêt pour Meta/TikTok/Google          |
| `customer.plan`                | `starter`, `pro` ou `autopilote`                           |
| `attribution.gclid`            | Google Click ID (si le lead vient de Google Ads)           |
| `attribution.fbclid`           | Facebook Click ID (si le lead vient de Meta)               |
| `attribution.fbc` / `fbp`      | Cookies first-party Meta                                   |
| `attribution.ttclid`           | TikTok Click ID                                            |
| `attribution.utm_*`            | Tous les UTM capturés à l'inscription                      |
| `value.amount`                 | Montant en euros (ou autre devise) — directement de Stripe |
| `value.currency`               | Devise ISO (`EUR`, `GBP`...)                               |
| `data_quality.has_attribution` | `true` si on a au moins un paramètre d'attribution         |


---

## Comment se brancher

### Étape 1 — Crée ton endpoint

Choisis ton outil :

- **Zapier** : crée un Zap avec trigger "Webhooks by Zapier > Catch Hook" et copie l'URL
- **Make** : crée un scénario avec "Webhooks > Custom webhook" et copie l'URL
- **sGTM** : crée un Client custom dans ton container et donne-moi l'URL
- **Custom** : expose un endpoint HTTPS qui accepte du POST JSON

### Étape 2 — Envoie-moi l'URL

Donne-moi :

- Ton URL HTTPS
- Un secret partagé si tu veux vérifier la signature (optionnel)

### Étape 3 — C'est en place

Je branche l'URL côté KeyBuzz. Dès le prochain vrai trial ou paiement, tu reçois le webhook.

### Ce que ton endpoint doit faire

- Accepter les `POST` en HTTPS
- Répondre en moins de 10 secondes
- Retourner un code `2xx` (200, 201, 204...)
- On retente 3 fois si ça échoue (à 0s, 5s, 15s)

---

## Mapping par plateforme

### Meta (Facebook) — Conversions API


| Tu reçois             | Tu envoies à Meta      | Note                                   |
| --------------------- | ---------------------- | -------------------------------------- |
| `event_name`          | `event_name`           | Identique (`StartTrial` ou `Purchase`) |
| `event_time`          | `event_time`           | Convertis en timestamp Unix (secondes) |
| `event_id`            | `event_id`             | Pour la dédupe Meta                    |
| `value.amount`        | `custom_data.value`    | Le montant réel                        |
| `value.currency`      | `custom_data.currency` | La devise                              |
| `customer.email_hash` | `user_data.em`         | Déjà en SHA-256, c'est bon             |
| `attribution.fbc`     | `user_data.fbc`        | Cookie first-party                     |
| `attribution.fbp`     | `user_data.fbp`        | Browser pixel ID                       |


Exemple prêt à envoyer à Meta :

```json
{
  "data": [{
    "event_name": "Purchase",
    "event_time": 1745502600,
    "event_id": "conv_tenant-abc_Purchase_sub_1PqR2sT3uV",
    "action_source": "website",
    "user_data": {
      "em": ["a3f5b7c9d1e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2"],
      "fbc": "fb.1.1681000000000.IwAR3xyz",
      "fbp": "fb.1.1681000000000.1234567890"
    },
    "custom_data": {
      "value": 297,
      "currency": "EUR"
    }
  }]
}
```

### TikTok — Events API


| Tu reçois                   | Tu envoies à TikTok         | Note                  |
| --------------------------- | --------------------------- | --------------------- |
| `event_name` = `StartTrial` | `event` = `Subscribe`       | Event standard TikTok |
| `event_name` = `Purchase`   | `event` = `CompletePayment` | Event standard TikTok |
| `event_time`                | `timestamp`                 | Tel quel (ISO 8601)   |
| `event_id`                  | `event_id`                  | Dédupe                |
| `value.amount`              | `properties.value`          | Montant               |
| `value.currency`            | `properties.currency`       | Devise                |
| `customer.email_hash`       | `user.email`                | Déjà en SHA-256       |
| `attribution.ttclid`        | `context.ad.callback`       | TikTok Click ID       |


### Google Ads — Offline Conversions


| Tu reçois           | Tu envoies à Google    | Note                                                        |
| ------------------- | ---------------------- | ----------------------------------------------------------- |
| `event_name`        | `conversion_action`    | Crée les actions "StartTrial" et "Purchase" dans Google Ads |
| `event_time`        | `conversion_date_time` | Format `yyyy-mm-dd hh:mm:ss+00:00`                          |
| `value.amount`      | `conversion_value`     | Montant                                                     |
| `value.currency`    | `currency_code`        | Devise                                                      |
| `attribution.gclid` | `gclid`                | Google Click ID                                             |


### LinkedIn — Conversions API


| Tu reçois             | Tu envoies à LinkedIn                                  |
| --------------------- | ------------------------------------------------------ |
| `event_time`          | `conversionHappenedAt`                                 |
| `value.amount`        | `conversionValue.amount`                               |
| `value.currency`      | `conversionValue.currencyCode`                         |
| `customer.email_hash` | `user.userIds[].idValue` (avec `idType: SHA256_EMAIL`) |


---

## Exemples concrets avec Zapier

1. Crée un Zap > trigger **"Webhooks by Zapier > Catch Hook"**
2. Copie l'URL et envoie-la moi
3. Zapier te donne directement les champs :
  - `event_name` → filtre StartTrial vs Purchase
  - `value__amount` → le montant
  - `value__currency` → la devise
  - `attribution__gclid` → le click ID Google
  - `attribution__fbclid` → le click ID Meta
  - `customer__email_hash` → le hash email
4. Ajoute une action : Google Sheets, Slack, Meta CAPI, ce que tu veux

## Exemples concrets avec Make

1. Crée un scénario > module **"Webhooks > Custom webhook"**
2. Copie l'URL et envoie-la moi
3. Configure la structure de données avec les champs du payload
4. Route vers tes plateformes :
  - **HTTP > Make a request** → Meta Conversions API
  - **Google Sheets > Add a row** → log
  - **Slack > Send a message** → notif

## Exemples concrets avec sGTM

1. Crée un **Client** custom dans ton container sGTM
2. Lis le body JSON et extrais `event_name`, `value`, `attribution`, `customer`
3. Crée un **Tag** Meta CAPI / Google Ads avec les mappings ci-dessus
4. Envoie-moi l'URL de ton container : `https://gtm.ton-domaine.com/keybuzz-webhook`

---

## Signature (optionnel mais recommandé)

Chaque requête est signée en HMAC SHA-256. Tu la trouves dans le header `X-KeyBuzz-Signature`.

### Les headers que tu reçois


| Header                | Contenu                    |
| --------------------- | -------------------------- |
| `X-KeyBuzz-Event`     | `StartTrial` ou `Purchase` |
| `X-KeyBuzz-Event-Id`  | L'ID unique de l'événement |
| `X-KeyBuzz-Signature` | `sha256=<signature_hex>`   |


### Comment vérifier (Node.js)

```javascript
const crypto = require('crypto');

function verifySignature(body, signatureHeader, secret) {
  const expected = 'sha256=' + crypto
    .createHmac('sha256', secret)
    .update(body)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(signatureHeader)
  );
}
```

### Comment vérifier (Python)

```python
import hmac, hashlib

def verify_signature(body, signature_header, secret):
    expected = 'sha256=' + hmac.new(
        secret.encode(), body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature_header)
```

Si tu utilises Zapier ou Make, la vérification est optionnelle — tu peux la skipper.

---

## Qualité des données

- **Pas de faux positif** : chaque event est déclenché par un vrai webhook Stripe,
pas un pixel ou une heuristique
- **Comptes test exclus** : nos comptes internes sont filtrés automatiquement,
tu ne les verras jamais
- **Montant réel** : la valeur vient directement de Stripe, pas d'estimation
- **Dédupliqué** : chaque event a un `event_id` unique, on ne l'envoie jamais deux fois.
Si tu reçois un doublon (retry après timeout), déduplique sur `event_id`
- **Attribution capturée à l'inscription** : les UTM et click IDs sont stockés quand
l'utilisateur s'inscrit, puis rattachés à chaque event. Le champ `has_attribution`
te dit si on a des données d'attribution ou pas

---

## Bon à savoir

- Pour le moment, on ne peut brancher qu'**une seule URL** de destination.
Si tu as besoin de dispatcher vers plusieurs outils, utilise Zapier ou Make comme hub
- On retente **3 fois** si ton endpoint ne répond pas (0s, 5s, 15s).
Après ça, l'event passe en `failed` côté KeyBuzz
- Il n'y a pas encore d'interface pour rejouer un event.
Si tu en rates un, dis-le moi
- L'URL est configurée de notre côté, pas en self-service pour l'instant

---

## Quick start

### Tester en 5 minutes

1. Va sur [webhook.site](https://webhook.site) et copie l'URL
2. Envoie-la moi
3. Je la branche
4. Au prochain vrai trial ou paiement, tu verras le JSON arriver

### Simuler un webhook en local (curl)

```bash
SECRET="ton-secret"
BODY='{"event_name":"StartTrial","event_id":"conv_test_StartTrial_sub_test","event_time":"2026-04-21T14:30:00.000Z","customer":{"tenant_id":"test","email_hash":"abc123","plan":"pro","billing_cycle":"monthly"},"subscription":{"stripe_subscription_id":"sub_test","status":"trialing","trial_end":null,"current_period_end":null},"attribution":{"utm_source":"test","utm_medium":null,"utm_campaign":null,"utm_term":null,"utm_content":null,"gclid":null,"fbclid":null,"fbc":null,"fbp":null,"ttclid":null,"landing_url":null,"referrer":null},"value":{"amount":0,"currency":"EUR"},"data_quality":{"has_attribution":true,"test_excluded":false,"source":"stripe_webhook"}}'

SIGNATURE="sha256=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')"

curl -X POST https://ton-endpoint.com/webhook \
  -H "Content-Type: application/json" \
  -H "X-KeyBuzz-Event: StartTrial" \
  -H "X-KeyBuzz-Event-Id: conv_test_StartTrial_sub_test" \
  -H "X-KeyBuzz-Signature: $SIGNATURE" \
  -d "$BODY"
```

### Checklist rapide

- Mon endpoint accepte les POST HTTPS
- Il répond en moins de 10 secondes
- Il retourne un 2xx
- Je déduplique sur `event_id`
- Je mappe `event_name` vers l'event de ma plateforme
- Je mappe `value.amount` + `value.currency` vers la valeur de conversion
- Je mappe `customer.email_hash` vers `user_data.em` (Meta) ou équivalent
- Je mappe les click IDs (`gclid`, `fbclid`, `ttclid`)

---

## Référence complète des champs


| Champ                                 | Type          | C'est quoi                                |
| ------------------------------------- | ------------- | ----------------------------------------- |
| `event_name`                          | string        | `"StartTrial"` ou `"Purchase"`            |
| `event_id`                            | string        | ID unique pour dédupliquer                |
| `event_time`                          | string        | Date/heure UTC (ISO 8601)                 |
| `customer.tenant_id`                  | string        | ID du client KeyBuzz                      |
| `customer.email_hash`                 | string / null | SHA-256 de l'email                        |
| `customer.plan`                       | string        | `starter`, `pro` ou `autopilote`          |
| `customer.billing_cycle`              | string        | `monthly` ou `yearly`                     |
| `subscription.stripe_subscription_id` | string        | ID Stripe                                 |
| `subscription.status`                 | string        | `trialing` ou `active`                    |
| `subscription.trial_end`              | string / null | Fin du trial                              |
| `subscription.current_period_end`     | string / null | Fin de la période                         |
| `attribution.utm_source`              | string / null | UTM source                                |
| `attribution.utm_medium`              | string / null | UTM medium                                |
| `attribution.utm_campaign`            | string / null | UTM campaign                              |
| `attribution.utm_term`                | string / null | UTM term                                  |
| `attribution.utm_content`             | string / null | UTM content                               |
| `attribution.gclid`                   | string / null | Google Click ID                           |
| `attribution.fbclid`                  | string / null | Facebook Click ID                         |
| `attribution.fbc`                     | string / null | Facebook Click Cookie                     |
| `attribution.fbp`                     | string / null | Facebook Browser Pixel                    |
| `attribution.ttclid`                  | string / null | TikTok Click ID                           |
| `attribution.landing_url`             | string / null | Landing page                              |
| `attribution.referrer`                | string / null | Referrer                                  |
| `value.amount`                        | number        | Montant réel Stripe                       |
| `value.currency`                      | string        | Devise ISO (`EUR`, `GBP`...)              |
| `data_quality.has_attribution`        | boolean       | `true` si attribution dispo               |
| `data_quality.test_excluded`          | boolean       | Toujours `false` (tests filtrés en amont) |
| `data_quality.source`                 | string        | Toujours `"stripe_webhook"`               |


---

*KeyBuzz SaaS v3.5.94 — Avril 2026*