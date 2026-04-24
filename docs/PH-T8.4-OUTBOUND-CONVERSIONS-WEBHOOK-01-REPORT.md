# PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01

> Date : 2026-04-21
> Type : Feature server-side — outbound conversions webhook
> Priorité : STRATÉGIQUE
> Environnement : DEV UNIQUEMENT

---

## 1. OBJECTIF

Créer une brique serveur fiable pour émettre les conversions business réelles (StartTrial, Purchase) vers des systèmes externes via webhook sécurisé (HMAC SHA256), avec idempotence, retry, et exclusion des comptes test.

---

## 2. TRIGGERS RÉELS IDENTIFIÉS


| Event          | Trigger Stripe                                                                     | Fonction hook                       | Garantie                           |
| -------------- | ---------------------------------------------------------------------------------- | ----------------------------------- | ---------------------------------- |
| **StartTrial** | `checkout.session.completed` avec `session.mode === 'subscription'` (excl. addons) | `handleCheckoutCompleted()` L.1555  | CB validée par Stripe, trial actif |
| **Purchase**   | `customer.subscription.updated` quand `status` passe de `trialing` à `active`      | `handleSubscriptionChange()` L.1696 | Paiement réel confirmé             |


### Triggers refusés


| Trigger                              | Raison du refus                         |
| ------------------------------------ | --------------------------------------- |
| signup simple (sans Stripe)          | Aucune preuve CB                        |
| `customer.subscription.created` seul | Pas de preuve de finalisation           |
| `invoice.paid` seul                  | Ambigu (inclut ré-activations past_due) |
| Frontend event                       | Interdit par les règles                 |


---

## 3. DONNÉES DISPONIBLES PAR EVENT


| Champ                       | StartTrial | Purchase | Source                         |
| --------------------------- | ---------- | -------- | ------------------------------ |
| tenant_id                   | ✅          | ✅        | session/subscription metadata  |
| email_hash (SHA256)         | ✅          | ✅        | signup_attribution.user_email  |
| plan                        | ✅          | ✅        | session.metadata.target_plan   |
| billing_cycle               | ✅          | ✅        | session.metadata.billing_cycle |
| value (EUR)                 | ✅          | ✅        | PLAN_PRICES table              |
| utm_source/medium/campaign  | ✅          | ✅        | signup_attribution             |
| gclid/fbclid/fbc/fbp/ttclid | ✅          | ✅        | signup_attribution             |
| stripe_subscription_id      | ✅          | ✅        | Stripe object                  |
| trial_end                   | ✅          | ✅        | Stripe object                  |
| test exclusion              | ✅          | ✅        | tenant_billing_exempt          |


---

## 4. PAYLOAD SCHEMA

```json
{
  "event_name": "StartTrial | Purchase",
  "event_id": "conv_{tenant_id}_{event_name}_{stripe_subscription_id}",
  "event_time": "2026-04-21T19:28:00.000Z",
  "customer": {
    "tenant_id": "...",
    "email_hash": "sha256_of_email",
    "plan": "pro",
    "billing_cycle": "monthly"
  },
  "subscription": {
    "stripe_subscription_id": "sub_...",
    "status": "trialing | active",
    "trial_end": "ISO8601 | null",
    "current_period_end": "ISO8601 | null"
  },
  "attribution": {
    "utm_source": "...",
    "utm_medium": "...",
    "utm_campaign": "...",
    "utm_term": "...",
    "utm_content": "...",
    "gclid": "...",
    "fbclid": "...",
    "fbc": "...",
    "fbp": "...",
    "ttclid": "...",
    "landing_url": "...",
    "referrer": "..."
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

Compatible Zapier, sGTM, n8n, custom.

---

## 5. SIGNATURE

- Algorithme : **HMAC SHA256**
- Header : `X-KeyBuzz-Signature: sha256=<hex>`
- Secret : variable d'environnement `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET`
- Corps signé : JSON stringifié du payload complet
- Aucun secret en dur

### Headers émis


| Header                | Valeur                              |
| --------------------- | ----------------------------------- |
| `Content-Type`        | `application/json`                  |
| `X-KeyBuzz-Event`     | `StartTrial` ou `Purchase`          |
| `X-KeyBuzz-Event-Id`  | `conv_{tenant_id}_{event}_{sub_id}` |
| `X-KeyBuzz-Signature` | `sha256=<hmac_hex>`                 |


---

## 6. DESTINATION


| Variable d'environnement              | Usage                                 |
| ------------------------------------- | ------------------------------------- |
| `OUTBOUND_CONVERSIONS_WEBHOOK_URL`    | URL de destination (vide = désactivé) |
| `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET` | Secret HMAC (optionnel)               |


Une seule destination. Pas de multi-destination dans cette phase.

---

## 7. IDEMPOTENCE

- Clé unique : `conv_{tenant_id}_{event_name}_{stripe_subscription_id}`
- Table DB : `conversion_events` (créée automatiquement au premier appel)
- Vérification avant envoi : si `status = 'sent'` → skip
- `ON CONFLICT (event_id) DO NOTHING` sur l'INSERT

### Schema table `conversion_events`


| Colonne         | Type          | Description             |
| --------------- | ------------- | ----------------------- |
| id              | UUID (PK)     | Auto-generated          |
| event_id        | TEXT (UNIQUE) | Clé d'idempotence       |
| tenant_id       | TEXT          | Tenant source           |
| event_name      | TEXT          | StartTrial ou Purchase  |
| payload         | JSONB         | Payload complet envoyé  |
| status          | TEXT          | pending / sent / failed |
| attempts        | INTEGER       | Nombre de tentatives    |
| last_attempt_at | TIMESTAMPTZ   | Dernière tentative      |
| created_at      | TIMESTAMPTZ   | Création                |


---

## 8. RETRY


| Paramètre         | Valeur                    |
| ----------------- | ------------------------- |
| Tentatives max    | 3                         |
| Délai tentative 1 | immédiat                  |
| Délai tentative 2 | 5 secondes                |
| Délai tentative 3 | 15 secondes               |
| Timeout HTTP      | 10 secondes               |
| Status < 500      | Accepté (pas de retry)    |
| Status >= 500     | Retry                     |
| Erreur réseau     | Retry                     |
| Après 3 échecs    | `status = 'failed'` en DB |


---

## 9. EXCLUSION TEST

- Méthode : `SELECT exempt FROM tenant_billing_exempt WHERE tenant_id = $1 AND exempt = true`
- Si exempt → skip total, aucune émission
- Tenant `ecomlg-001` (exempt = true, reason = internal_admin) → correctement exclu ✅

---

## 10. VALIDATION DEV


| Cas | Test                                 | Résultat                             |
| --- | ------------------------------------ | ------------------------------------ |
| 0   | Table `conversion_events` créée auto | ✅                                    |
| 1   | Module emitter chargé                | ✅ `typeof = function`                |
| 2   | Hooks dans billing routes            | ✅ 2 occurrences                      |
| 3   | Pas de webhook URL → skip            | ✅ `skipping StartTrial`              |
| 4   | Tenant exempt (ecomlg-001) → skip    | ✅ `exempt, skipping`                 |
| 5   | StartTrial → httpbin.org             | ✅ HTTP 200 (attempt 1)               |
| 6   | Purchase → httpbin.org               | ✅ HTTP 200 (attempt 1)               |
| 7   | Idempotence (ré-envoi)               | ✅ `already sent, skipping`           |
| 8   | Retry (URL 500)                      | ✅ 3 tentatives, 23s, status `failed` |
| 9   | État DB                              | ✅ 2 `sent`, 1 `failed`               |


### Non-régression


| Check                 | Résultat                                                         |
| --------------------- | ---------------------------------------------------------------- |
| API DEV health        | ✅ HTTP 200                                                       |
| Billing module        | ✅ chargé                                                         |
| Billing webhook route | ✅ intacte                                                        |
| Autopilot module      | ✅ chargé                                                         |
| Metrics module        | ✅ chargé                                                         |
| Backend DEV           | ✅ inchangé `v1.0.46-ph-recovery-01-dev`                          |
| Client DEV            | ✅ inchangé                                                       |
| PROD                  | ✅ inchangée `v3.5.92-autopilot-promise-detection-guardrail-prod` |


---

## 11. BUILD


| Élément       | Valeur                                                                          |
| ------------- | ------------------------------------------------------------------------------- |
| Image         | `ghcr.io/keybuzzio/keybuzz-api:v3.5.93-outbound-conversions-dev`                |
| Digest        | `sha256:3b411f6fbfa5fd88bc472f155f2ab4618d78b0025b00dc4cd8abb8a4d8902242`       |
| Source        | `keybuzz-api@ph147.4/source-of-truth`                                           |
| Commit        | `4c7b2cea`                                                                      |
| Méthode       | `build-api-from-git.sh` (clone propre)                                          |
| GitOps commit | `77c1e2e`                                                                       |
| Rollback      | `rollback-service.sh api dev v3.5.92-autopilot-promise-detection-guardrail-dev` |


---

## 12. FICHIERS MODIFIÉS


| Fichier                                             | Action   | Lignes                        |
| --------------------------------------------------- | -------- | ----------------------------- |
| `src/modules/outbound-conversions/emitter.ts`       | **CRÉÉ** | 250 lignes                    |
| `src/modules/billing/routes.ts`                     | MODIFIÉ  | +45 lignes (import + 2 hooks) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ  | image + 2 env vars            |


---

## 13. ARCHITECTURE

```
Stripe webhook
  │
  ├── checkout.session.completed (subscription)
  │     └── handleCheckoutCompleted()
  │           ├── emitConversionWebhook() ← existant (GA4 MP)
  │           └── emitOutboundConversion('StartTrial') ← NOUVEAU
  │
  └── customer.subscription.updated (active, was trialing)
        └── handleSubscriptionChange()
              └── emitOutboundConversion('Purchase') ← NOUVEAU
                    │
                    ├── [1] Test exclusion (tenant_billing_exempt)
                    ├── [2] Idempotence check (conversion_events)
                    ├── [3] Attribution enrichment (signup_attribution)
                    ├── [4] Payload build (generic JSON)
                    ├── [5] HMAC SHA256 signature
                    ├── [6] HTTP POST + retry (3x)
                    └── [7] DB status update (sent/failed)
```

---

## 14. LIMITES


| Limitation              | Raison                                  | Contournement                    |
| ----------------------- | --------------------------------------- | -------------------------------- |
| Une seule destination   | Phase 1, simplicité                     | Multi-destination en PH-T8.5     |
| Pas de file d'attente   | Envoi synchrone dans le webhook handler | Acceptable pour le volume actuel |
| Pas de replay UI        | Pas d'interface d'admin                 | Query DB `conversion_events`     |
| Retry max 20s           | Pas de queue asynchrone                 | Suffisant pour les webhooks      |
| Valeur = prix plan fixe | Pas le montant Stripe réel              | Précis pour les plans standards  |


---

## 15. ACTIVATION

Pour activer l'émission des conversions, il suffit de renseigner les env vars :

```yaml
- name: OUTBOUND_CONVERSIONS_WEBHOOK_URL
  value: "https://votre-endpoint.example.com/webhook"
- name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
  value: "votre-secret-hmac"
```

Sans URL, le module est inactif (skip silencieux).

---

## VERDICT

**OUTBOUND CONVERSIONS SERVER-SIDE READY — REAL DATA ONLY — DEV SAFE**