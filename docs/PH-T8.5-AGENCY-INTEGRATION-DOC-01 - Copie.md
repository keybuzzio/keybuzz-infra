# KeyBuzz — Server-Side Conversions Webhook

## Guide d'intégration pour agences et media buyers

> Version : 1.0 — 21 avril 2026
> Statut : PRODUCTION
> Contact technique : [contact@keybuzz.io](mailto:contact@keybuzz.io)

---

## Table des matières

1. [Architecture](#1-architecture)
2. [Événements](#2-événements)
3. [Payload complet](#3-payload-complet)
4. [Signature HMAC](#4-signature-hmac)
5. [Comment se connecter](#5-comment-se-connecter)
6. [Exemples d'intégration](#6-exemples-dintégration)
7. [Mapping publicité](#7-mapping-publicité)
8. [Qualité des données](#8-qualité-des-données)
9. [Limites connues](#9-limites-connues)
10. [Quick Start](#10-quick-start)

---

## 1. Architecture

### Flux de données

```
Utilisateur
  │
  ├── Visite le site (attribution capturée : UTM, gclid, fbclid, ttclid...)
  │
  ├── S'inscrit + choisit un plan → Stripe Checkout
  │
  ├── Stripe confirme le trial → Backend émet "StartTrial"
  │
  └── Stripe confirme le paiement → Backend émet "Purchase"
                                           │
                                     Webhook HTTPS POST
                                           │
                                     Votre endpoint
                                  (Zapier, sGTM, Make, custom...)
```

### Principes clés

- **100% server-side** : aucune dépendance au navigateur, aucun pixel, aucun SDK frontend.
- **Données réelles** : chaque événement est déclenché par un webhook Stripe vérifié. Pas de
heuristique, pas de simulation, pas de conversion estimée.
- **Attribution enrichie** : les paramètres UTM, click IDs publicitaires (gclid, fbclid, fbc,
fbp, ttclid) et le hash SHA-256 de l'email sont inclus dans chaque événement.
- **Valeur réelle Stripe** : le montant et la devise proviennent directement de l'objet Stripe
(pas d'estimation par plan).

---

## 2. Événements

### StartTrial


| Propriété                 | Valeur                                                       |
| ------------------------- | ------------------------------------------------------------ |
| **Déclencheur**           | `checkout.session.completed` (Stripe)                        |
| **Conditions**            | Le checkout est de type `subscription` ET n'est pas un addon |
| **Ce que ça signifie**    | L'utilisateur a saisi sa carte bancaire et démarré un trial  |
| `**value.amount`**        | Montant Stripe réel (généralement `0` pour un trial gratuit) |
| `**subscription.status`** | `trialing`                                                   |
| **Garantie**              | Carte bancaire validée par Stripe                            |


### Purchase


| Propriété                 | Valeur                                                               |
| ------------------------- | -------------------------------------------------------------------- |
| **Déclencheur**           | `customer.subscription.updated` (Stripe)                             |
| **Conditions**            | Le statut de la subscription passe de `trialing` à `active`          |
| **Ce que ça signifie**    | Le premier paiement réel a été encaissé par Stripe                   |
| `**value.amount`**        | Montant réel facturé par Stripe (somme des items de la subscription) |
| `**subscription.status`** | `active`                                                             |
| **Garantie**              | Paiement réel confirmé par Stripe                                    |


### Ce qui n'est PAS émis


| Situation                        | Raison                                       |
| -------------------------------- | -------------------------------------------- |
| Simple inscription (sans Stripe) | Aucune preuve de carte bancaire              |
| Visite de page pricing           | Pas une conversion                           |
| Événement frontend / pixel       | Interdit par design                          |
| Renouvellement mensuel           | Seul le premier paiement post-trial est émis |
| Ré-activation après `past_due`   | Ambigu, risque de faux positif               |


---

## 3. Payload complet

Chaque webhook est un `POST` HTTP avec un corps JSON.

### Structure

```json
{
  "event_name": "StartTrial",
  "event_id": "conv_tenant-abc_StartTrial_sub_1PqR2sT3uV",
  "event_time": "2026-04-21T14:30:00.000Z",

  "customer": {
    "tenant_id": "tenant-abc",
    "email_hash": "a3f5b7c9d1e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2",
    "plan": "pro",
    "billing_cycle": "monthly"
  },

  "subscription": {
    "stripe_subscription_id": "sub_1PqR2sT3uV",
    "status": "trialing",
    "trial_end": "2026-05-05T14:30:00.000Z",
    "current_period_end": "2026-05-21T14:30:00.000Z"
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
    "amount": 0,
    "currency": "EUR"
  },

  "data_quality": {
    "has_attribution": true,
    "test_excluded": false,
    "source": "stripe_webhook"
  }
}
```

### Référence des champs


| Champ                                 | Type              | Description                                                    |
| ------------------------------------- | ----------------- | -------------------------------------------------------------- |
| `event_name`                          | string            | `"StartTrial"` ou `"Purchase"`                                 |
| `event_id`                            | string            | Identifiant unique (format : `conv_{tenant}_{event}_{sub_id}`) |
| `event_time`                          | string (ISO 8601) | Horodatage UTC de l'événement                                  |
| `customer.tenant_id`                  | string            | Identifiant du client KeyBuzz                                  |
| `customer.email_hash`                 | string            | null                                                           |
| `customer.plan`                       | string            | Plan souscrit : `starter`, `pro`, `autopilote`                 |
| `customer.billing_cycle`              | string            | `monthly` ou `yearly`                                          |
| `subscription.stripe_subscription_id` | string            | ID Stripe de la subscription                                   |
| `subscription.status`                 | string            | `trialing` (StartTrial) ou `active` (Purchase)                 |
| `subscription.trial_end`              | string            | null                                                           |
| `subscription.current_period_end`     | string            | null                                                           |
| `attribution.utm_*`                   | string            | null                                                           |
| `attribution.gclid`                   | string            | null                                                           |
| `attribution.fbclid`                  | string            | null                                                           |
| `attribution.fbc`                     | string            | null                                                           |
| `attribution.fbp`                     | string            | null                                                           |
| `attribution.ttclid`                  | string            | null                                                           |
| `attribution.landing_url`             | string            | null                                                           |
| `attribution.referrer`                | string            | null                                                           |
| `value.amount`                        | number            | Montant réel Stripe (en unité monétaire, ex: `297` = 297 EUR)  |
| `value.currency`                      | string            | Devise ISO 4217 (`EUR`, `GBP`, `USD`...)                       |
| `data_quality.has_attribution`        | boolean           | `true` si au moins un champ attribution est renseigné          |
| `data_quality.test_excluded`          | boolean           | Toujours `false` (les tests sont exclus en amont)              |
| `data_quality.source`                 | string            | Toujours `"stripe_webhook"`                                    |


### Exemple Purchase EUR

```json
{
  "event_name": "Purchase",
  "event_id": "conv_tenant-abc_Purchase_sub_1PqR2sT3uV",
  "event_time": "2026-05-05T14:30:00.000Z",
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
    "utm_source": "google",
    "utm_medium": "cpc",
    "utm_campaign": "brand-fr",
    "utm_term": null,
    "utm_content": null,
    "gclid": "CjwKCAjw...",
    "fbclid": null,
    "fbc": null,
    "fbp": null,
    "ttclid": null,
    "landing_url": "https://www.keybuzz.pro/?gclid=CjwKCAjw...",
    "referrer": "https://www.google.com/"
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

### Exemple Purchase GBP

```json
{
  "event_name": "Purchase",
  "event_id": "conv_tenant-xyz_Purchase_sub_9AbC8dEf",
  "event_time": "2026-05-10T09:15:00.000Z",
  "customer": {
    "tenant_id": "tenant-xyz",
    "email_hash": "b4a6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4c6d8e0f2a4",
    "plan": "autopilote",
    "billing_cycle": "yearly"
  },
  "subscription": {
    "stripe_subscription_id": "sub_9AbC8dEf",
    "status": "active",
    "trial_end": "2026-05-10T09:15:00.000Z",
    "current_period_end": "2027-05-10T09:15:00.000Z"
  },
  "attribution": {
    "utm_source": "tiktok",
    "utm_medium": "paid",
    "utm_campaign": "launch-uk",
    "utm_term": null,
    "utm_content": null,
    "gclid": null,
    "fbclid": null,
    "fbc": null,
    "fbp": null,
    "ttclid": "E.C.P.abc123...",
    "landing_url": "https://www.keybuzz.pro/pricing?ttclid=E.C.P.abc123",
    "referrer": "https://www.tiktok.com/"
  },
  "value": {
    "amount": 4776,
    "currency": "GBP"
  },
  "data_quality": {
    "has_attribution": true,
    "test_excluded": false,
    "source": "stripe_webhook"
  }
}
```

---

## 4. Signature HMAC

Chaque requête webhook est signée avec HMAC SHA-256 pour garantir l'authenticité.

### Headers HTTP


| Header                | Valeur                        | Description        |
| --------------------- | ----------------------------- | ------------------ |
| `Content-Type`        | `application/json`            | Format du corps    |
| `X-KeyBuzz-Event`     | `StartTrial` ou `Purchase`    | Nom de l'événement |
| `X-KeyBuzz-Event-Id`  | `conv_{tenant}_{event}_{sub}` | ID unique          |
| `X-KeyBuzz-Signature` | `sha256=<hex>`                | Signature HMAC     |


### Comment vérifier la signature

1. Lire le corps brut de la requête (avant parsing JSON)
2. Calculer `HMAC-SHA256(secret, body)` en hexadécimal
3. Comparer avec la valeur après `sha256=` dans le header `X-KeyBuzz-Signature`

### Exemple Node.js

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

// Usage dans un handler Express/Fastify
app.post('/webhook', (req, res) => {
  const rawBody = req.rawBody; // corps brut (string)
  const signature = req.headers['x-keybuzz-signature'];
  const secret = process.env.WEBHOOK_SECRET;

  if (!verifySignature(rawBody, signature, secret)) {
    return res.status(401).send('Invalid signature');
  }

  const payload = JSON.parse(rawBody);
  // Traiter l'événement...
  res.status(200).send('OK');
});
```

### Exemple Python

```python
import hmac
import hashlib

def verify_signature(body: bytes, signature_header: str, secret: str) -> bool:
    expected = 'sha256=' + hmac.new(
        secret.encode('utf-8'),
        body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature_header)

# Usage dans Flask
@app.route('/webhook', methods=['POST'])
def handle_webhook():
    body = request.get_data()
    signature = request.headers.get('X-KeyBuzz-Signature', '')
    secret = os.environ['WEBHOOK_SECRET']

    if not verify_signature(body, signature, secret):
        return 'Invalid signature', 401

    payload = request.get_json()
    # Traiter l'événement...
    return 'OK', 200
```

### Zapier / Make

Si vous utilisez Zapier ou Make, la vérification de signature est optionnelle (le secret
peut être laissé vide côté KeyBuzz). Si vous souhaitez la vérifier, utilisez un step
"Code" (JavaScript ou Python) avec les exemples ci-dessus.

---

## 5. Comment se connecter

### Étapes pour l'agence

```
Étape 1 — Créer votre endpoint
  ├── Zapier : créer un Zap avec trigger "Webhooks by Zapier > Catch Hook"
  ├── Make : créer un scénario avec module "Webhooks > Custom webhook"
  ├── sGTM : créer un Client "Custom webhook"
  └── Custom : exposer un endpoint HTTPS qui accepte POST JSON

Étape 2 — Fournir l'URL à KeyBuzz
  └── Envoyer l'URL HTTPS de votre endpoint à l'équipe KeyBuzz

Étape 3 — Choisir un secret partagé (optionnel)
  └── Définir un secret HMAC pour vérifier l'authenticité des webhooks

Étape 4 — KeyBuzz configure l'envoi
  └── L'équipe renseigne l'URL et le secret dans la configuration PROD

Étape 5 — Tester
  └── Déclencher un vrai trial de test → vérifier la réception
```

### Exigences techniques de votre endpoint


| Exigence         | Détail                                                                       |
| ---------------- | ---------------------------------------------------------------------------- |
| Protocole        | **HTTPS** obligatoire                                                        |
| Méthode          | `POST`                                                                       |
| Content-Type     | `application/json`                                                           |
| Réponse attendue | HTTP `2xx` (200, 201, 204...)                                                |
| Timeout          | Votre endpoint doit répondre en moins de **10 secondes**                     |
| Retry            | KeyBuzz retente 3 fois si votre endpoint ne répond pas (délai : 0s, 5s, 15s) |
| Idempotence      | Utiliser `event_id` pour dédupliquer côté récepteur                          |


---

## 6. Exemples d'intégration

### Zapier

1. Créer un Zap avec trigger **"Webhooks by Zapier > Catch Hook"**
2. Copier l'URL générée par Zapier (ex: `https://hooks.zapier.com/hooks/catch/12345/abcdef/`)
3. Fournir cette URL à KeyBuzz
4. Zapier reçoit automatiquement le JSON — les champs sont accessibles :
  - `event_name` → pour filtrer (StartTrial vs Purchase)
  - `value__amount` → montant
  - `value__currency` → devise
  - `attribution__gclid` → Google Click ID
  - `attribution__fbclid` → Facebook Click ID
  - `customer__email_hash` → hash email
5. Ajouter une action (Google Sheets, CRM, Slack, Meta Conversions API...)

### Make (ex-Integromat)

1. Créer un scénario avec module **"Webhooks > Custom webhook"**
2. Copier l'URL du webhook Make
3. Fournir cette URL à KeyBuzz
4. Configurer la structure de données avec les champs du payload
5. Ajouter des modules pour router vers vos plateformes :
  - **HTTP > Make a request** → Meta Conversions API
  - **Google Sheets > Add a row** → log
  - **Slack > Send a message** → notification

### Server-side Google Tag Manager (sGTM)

1. Créer un **Client** dans sGTM de type "Custom" :
  - Claim path : `/keybuzz-webhook`
  - Lire le corps JSON
  - Extraire `event_name`, `value`, `attribution`, `customer`
2. Créer un **Tag** Meta CAPI / Google Ads :
  - Trigger : le Client webhook
  - Mapper les données (voir section 7)
3. Fournir l'URL de votre container sGTM à KeyBuzz :
  - `https://gtm.votre-domaine.com/keybuzz-webhook`

### Custom (Node.js / Python)

Voir les exemples de vérification de signature dans la section 4.
Après vérification, traiter le payload selon votre logique métier.

---

## 7. Mapping publicité

### Meta (Facebook) Conversions API


| Champ KeyBuzz               | Champ Meta CAPI             | Notes                                    |
| --------------------------- | --------------------------- | ---------------------------------------- |
| `event_name` = `StartTrial` | `event_name` = `StartTrial` | Identique                                |
| `event_name` = `Purchase`   | `event_name` = `Purchase`   | Identique                                |
| `event_time`                | `event_time`                | Convertir en timestamp Unix (secondes)   |
| `event_id`                  | `event_id`                  | Pour la déduplication Meta               |
| `value.amount`              | `custom_data.value`         | Montant réel                             |
| `value.currency`            | `custom_data.currency`      | Devise ISO                               |
| `customer.email_hash`       | `user_data.em`              | SHA-256 — déjà au bon format             |
| `attribution.fbclid`        | `user_data.fbc`             | Utiliser `attribution.fbc` si disponible |
| `attribution.fbp`           | `user_data.fbp`             | Facebook Browser Pixel ID                |
| `data_quality.source`       | `action_source`             | `"website"` (Meta exige cette valeur)    |


**Exemple appel Meta CAPI** :

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

### TikTok Events API


| Champ KeyBuzz               | Champ TikTok                | Notes                        |
| --------------------------- | --------------------------- | ---------------------------- |
| `event_name` = `StartTrial` | `event` = `Subscribe`       | TikTok standard event        |
| `event_name` = `Purchase`   | `event` = `CompletePayment` | TikTok standard event        |
| `event_time`                | `timestamp`                 | ISO 8601 (tel quel)          |
| `event_id`                  | `event_id`                  | Pour la déduplication        |
| `value.amount`              | `properties.value`          | Montant réel                 |
| `value.currency`            | `properties.currency`       | Devise ISO                   |
| `customer.email_hash`       | `user.email`                | SHA-256 — déjà au bon format |
| `attribution.ttclid`        | `context.ad.callback`       | TikTok Click ID              |


### Google Ads — Offline Conversions


| Champ KeyBuzz               | Champ Google           | Notes                                         |
| --------------------------- | ---------------------- | --------------------------------------------- |
| `event_name` = `StartTrial` | `conversion_action`    | Créer une action "StartTrial" dans Google Ads |
| `event_name` = `Purchase`   | `conversion_action`    | Créer une action "Purchase" dans Google Ads   |
| `event_time`                | `conversion_date_time` | Format : `yyyy-mm-dd hh:mm:ss+00:00`          |
| `value.amount`              | `conversion_value`     | Montant réel                                  |
| `value.currency`            | `currency_code`        | Devise ISO                                    |
| `attribution.gclid`         | `gclid`                | Google Click ID                               |


### LinkedIn Conversions API


| Champ KeyBuzz         | Champ LinkedIn                 | Notes                           |
| --------------------- | ------------------------------ | ------------------------------- |
| `event_name`          | `conversionHappenedAt`         | Horodatage                      |
| `value.amount`        | `conversionValue.amount`       | Montant en chaîne               |
| `value.currency`      | `conversionValue.currencyCode` | Devise ISO                      |
| `customer.email_hash` | `user.userIds[].idValue`       | SHA-256, `idType: SHA256_EMAIL` |


---

## 8. Qualité des données

### Exclusion des comptes test

Les comptes internes KeyBuzz (identifiés par le flag `tenant_billing_exempt.exempt = true`)
sont automatiquement exclus. Aucun événement n'est émis pour ces comptes. Vous ne recevrez
jamais de conversion de test.

### Trial vs Paid


| Événement    | Signification                                            | Valeur typique                  |
| ------------ | -------------------------------------------------------- | ------------------------------- |
| `StartTrial` | L'utilisateur a fourni sa CB et démarré un essai gratuit | `0` (pas encore facturé)        |
| `Purchase`   | Le premier paiement réel a été encaissé                  | Montant réel Stripe (ex: `297`) |


Pour l'optimisation publicitaire :

- Utilisez **StartTrial** pour optimiser sur le haut du funnel (acquisition)
- Utilisez **Purchase** pour optimiser sur la valeur réelle (ROAS)

### Currency réelle

La devise provient directement de Stripe. Elle correspond à la devise de facturation
du client, pas à une devise fixe. Exemples : `EUR`, `GBP`, `USD`.

### Idempotence

Chaque événement a un `event_id` unique (format : `conv_{tenant}_{event}_{sub_id}`).
Un même événement n'est jamais émis deux fois par KeyBuzz. Si vous recevez un doublon
(retry après timeout), utilisez `event_id` pour dédupliquer de votre côté.

### Fraîcheur des données d'attribution

Les données d'attribution (`utm_`*, `gclid`, `fbclid`, etc.) sont capturées au moment
de l'inscription de l'utilisateur et stockées en base. Elles sont incluses dans chaque
événement ultérieur (StartTrial, Purchase) pour le même client.

Le champ `data_quality.has_attribution` indique si au moins un paramètre d'attribution
est disponible. Si `false`, l'utilisateur s'est inscrit sans paramètres traçables
(accès direct, lien non tagué...).

---

## 9. Limites connues


| Limitation                  | Détail                                                | Contournement                                          |
| --------------------------- | ----------------------------------------------------- | ------------------------------------------------------ |
| 1 seule destination webhook | Un seul endpoint peut être configuré                  | Utiliser un agrégateur (Zapier/Make) pour redistribuer |
| Retry limité                | 3 tentatives (0s, 5s, 15s)                            | Votre endpoint doit être fiable et répondre < 10s      |
| Pas de replay UI            | Pas d'interface pour re-déclencher un événement       | Contacter le support KeyBuzz                           |
| Pas de mapping direct       | Les plateformes pub ne sont pas appelées directement  | Utiliser sGTM, Zapier ou Make comme intermédiaire      |
| Pas de webhooks historiques | Seuls les événements futurs sont émis                 | Les événements passés ne sont pas rejouables           |
| Configuration par l'équipe  | L'URL est configurée par KeyBuzz, pas en self-service | Contacter l'équipe pour tout changement                |


---

## 10. Quick Start

### En 5 minutes

**1. Créez un endpoint de test**

Le moyen le plus rapide : [https://webhook.site](https://webhook.site)
Copiez l'URL unique générée.

**2. Envoyez l'URL à KeyBuzz**

Contactez l'équipe KeyBuzz avec :

- Votre URL HTTPS
- Un secret partagé (vous choisissez, ex: `mon-secret-agence-2026`)

**3. Attendez le prochain événement réel**

Dès qu'un vrai utilisateur démarre un trial ou paie, vous recevrez le webhook.

**4. Vérifiez la réception**

Sur webhook.site, vous verrez :

- Le corps JSON complet
- Les headers (`X-KeyBuzz-Event`, `X-KeyBuzz-Signature`)

### Test avec curl (simulation locale)

Pour tester votre endpoint avant la mise en production, simulez un webhook :

```bash
# Définir les variables
SECRET="votre-secret-partage"
BODY='{"event_name":"StartTrial","event_id":"conv_test_StartTrial_sub_test","event_time":"2026-04-21T14:30:00.000Z","customer":{"tenant_id":"test","email_hash":"abc123","plan":"pro","billing_cycle":"monthly"},"subscription":{"stripe_subscription_id":"sub_test","status":"trialing","trial_end":null,"current_period_end":null},"attribution":{"utm_source":"test","utm_medium":null,"utm_campaign":null,"utm_term":null,"utm_content":null,"gclid":null,"fbclid":null,"fbc":null,"fbp":null,"ttclid":null,"landing_url":null,"referrer":null},"value":{"amount":0,"currency":"EUR"},"data_quality":{"has_attribution":true,"test_excluded":false,"source":"stripe_webhook"}}'

# Calculer la signature
SIGNATURE="sha256=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')"

# Envoyer le webhook
curl -X POST https://votre-endpoint.example.com/webhook \
  -H "Content-Type: application/json" \
  -H "X-KeyBuzz-Event: StartTrial" \
  -H "X-KeyBuzz-Event-Id: conv_test_StartTrial_sub_test" \
  -H "X-KeyBuzz-Signature: $SIGNATURE" \
  -d "$BODY"
```

### Checklist de vérification

- Mon endpoint accepte les POST HTTPS
- Mon endpoint répond en moins de 10 secondes
- Mon endpoint retourne un status 2xx
- Je déduplique sur `event_id`
- Je vérifie la signature HMAC (optionnel mais recommandé)
- Je mappe `event_name` vers l'événement de ma plateforme pub
- Je mappe `value.amount` et `value.currency` vers la valeur de conversion
- Je mappe `customer.email_hash` vers `user_data.em` (Meta) ou équivalent
- Je mappe les click IDs (`gclid`, `fbclid`, `ttclid`) vers les champs correspondants

---

## Glossaire


| Terme            | Définition                                                                   |
| ---------------- | ---------------------------------------------------------------------------- |
| **StartTrial**   | Événement émis quand un utilisateur démarre un essai gratuit avec CB validée |
| **Purchase**     | Événement émis quand le premier paiement réel est confirmé                   |
| **HMAC SHA-256** | Algorithme de signature pour vérifier l'authenticité du webhook              |
| **event_id**     | Identifiant unique d'un événement, pour la déduplication                     |
| **email_hash**   | SHA-256 de l'email en minuscules, compatible avec les APIs publicitaires     |
| **gclid**        | Google Click Identifier — identifiant de clic Google Ads                     |
| **fbclid**       | Facebook Click Identifier — identifiant de clic Meta                         |
| **fbc**          | Facebook Click Cookie — cookie first-party Meta                              |
| **fbp**          | Facebook Browser Pixel — identifiant navigateur Meta                         |
| **ttclid**       | TikTok Click Identifier — identifiant de clic TikTok                         |
| **sGTM**         | Server-side Google Tag Manager                                               |
| **CAPI**         | Conversions API (Meta)                                                       |


---

*Document généré le 21 avril 2026 — KeyBuzz SaaS v3.5.94*