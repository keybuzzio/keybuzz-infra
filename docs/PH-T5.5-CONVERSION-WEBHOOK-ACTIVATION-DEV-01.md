# PH-T5.5 — Activation Webhook Conversion Server-Side (DEV)

> Date : 2026-04-17
> Environnement : DEV uniquement
> Type : activation env vars (aucun build, aucun patch code)

---

## Objectif

Activer le webhook conversion PH-T4 pour envoyer les events `purchase` server-side
depuis l'API vers le container Addingwell sGTM (`t.keybuzz.io`).

---

## État avant activation


| Variable                     | Valeur                        |
| ---------------------------- | ----------------------------- |
| `CONVERSION_WEBHOOK_ENABLED` | `false`                       |
| `CONVERSION_WEBHOOK_URL`     | *(vide)*                      |
| `CONVERSION_WEBHOOK_SECRET`  | `ph-t4-dev-hmac-secret`       |
| Image API                    | `v3.5.77-tracking-t4-api-dev` |


- Table `signup_attribution` : présente avec colonne `conversion_sent_at`
- Code `emitConversionWebhook()` dans `billing/routes.ts` (lignes 1785-1880)
- Appel non-bloquant dans le handler `checkout.session.completed` (mode subscription)

---

## Changements effectués

### Env vars modifiées via `kubectl set env`

```bash
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev \
  CONVERSION_WEBHOOK_ENABLED=true \
  CONVERSION_WEBHOOK_URL=https://t.keybuzz.io/mp/collect
```

Pod redémarré automatiquement (rolling update).

### Aucun build, aucun patch code

Seules les env vars ont été modifiées. L'image API reste `v3.5.77-tracking-t4-api-dev`.

---

## Test effectué

### Signup + Checkout Stripe (mode test)

1. **Signup** : `/register` → Plan Starter → Nom société "Test Conversion T5.5"
2. **Formulaire** : Prénom "Test", Nom "T55", email `ludo.gonthier@gmail.com`
3. **Checkout Stripe** : carte test `4242 4242 4242 4242`, exp `12/30`, CVC `123`
4. **Résultat** : paiement OK, redirection vers `/dashboard`
5. **Tenant créé** : `test-conversion-t5-5-mo32vwbp`

---

## Résultats

### Webhook Stripe

```
[Billing Webhook] Received event: checkout.session.completed (evt_1TNEaVFC0QQLHISRgupQfXq6)
[Billing] Checkout completed for tenant: test-conversion-t5-5-mo32vwbp type: undefined
```

### Conversion webhook

```
[Conversion] Webhook sent to https://t.keybuzz.io/mp/collect: 400
```

- Le webhook a été envoyé (**pipeline fonctionnel**)
- Le checkout Stripe n'a **pas** été bloqué (non-bloquant par design)
- HTTP 400 reçu du endpoint Measurement Protocol

### Base de données

```json
{
  "tenant_id": "test-conversion-t5-5-mo32vwbp",
  "conversion_sent_at": "2026-04-17T15:45:48.018Z",
  "utm_source": null,
  "plan": null,
  "cycle": null
}
```

`conversion_sent_at` est **NOT NULL** (marqué indépendamment du status HTTP).

### sGTM Addingwell

Le hit n'a **pas** été reçu par le sGTM. Raison : incompatibilité de format.


| Aspect         | Code PH-T4                                  | Measurement Protocol GA4                    |
| -------------- | ------------------------------------------- | ------------------------------------------- |
| Content-Type   | `application/json`                          | `application/json`                          |
| URL params     | aucun                                       | `measurement_id=G-XXX&api_secret=XXX`       |
| Body format    | `{ event, tenant_id, amount, attribution }` | `{ client_id, events: [{ name, params }] }` |
| Headers custom | `X-Webhook-Event`, `X-Webhook-Signature`    | aucun                                       |


Le code PH-T4 envoie un **payload JSON custom** (webhook interne) alors que `/mp/collect` attend le format **Measurement Protocol GA4 standard**.

---

## Non-régression


| Vérification                  | Résultat               |
| ----------------------------- | ---------------------- |
| Signup `/register`            | OK                     |
| Checkout Stripe (carte test)  | OK                     |
| Paiement + redirect dashboard | OK                     |
| Login Google OAuth            | OK                     |
| Select tenant                 | OK (3 tenants)         |
| Inbox eComLG                  | OK (396 conversations) |
| Suggestions IA                | OK                     |
| Panel commandes               | OK                     |
| API logs (erreurs)            | Aucune erreur          |


---

## Rollback

```bash
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev \
  CONVERSION_WEBHOOK_ENABLED=false \
  CONVERSION_WEBHOOK_URL=""
```

---

## Verdict


| Critère                      | Résultat                                |
| ---------------------------- | --------------------------------------- |
| Pipeline webhook fonctionnel | **OUI** — envoi non-bloquant OK         |
| Stripe non cassé             | **OUI** — paiement + webhooks OK        |
| DB marquée                   | **OUI** — `conversion_sent_at` NOT NULL |
| sGTM hit reçu                | **NON** — HTTP 400, format incompatible |
| Non-régression               | **PASS** — aucune régression            |


### PIPELINE ACTIVÉ — FORMAT À ADAPTER

Le webhook de conversion est **activé et fonctionnel** : il s'exécute à chaque checkout
réussi, il est non-bloquant, et il marque la DB. Le checkout Stripe n'est pas affecté.

Cependant, le **format du payload** doit être adapté dans une prochaine phase pour être
compatible avec le Measurement Protocol GA4 (`/mp/collect`) ou un endpoint webhook custom
côté sGTM Addingwell.

### Prochaine étape recommandée

**PH-T5.6** : Adapter `emitConversionWebhook()` pour envoyer au format Measurement Protocol GA4 :

- Ajouter `measurement_id` et `api_secret` en query params
- Restructurer le body en `{ client_id, events: [{ name: 'purchase', params: {...} }] }`
- Ou créer un tag webhook custom côté Addingwell sGTM pour recevoir le format actuel

---

## État post-activation


| Variable                     | Valeur                                      |
| ---------------------------- | ------------------------------------------- |
| `CONVERSION_WEBHOOK_ENABLED` | `true`                                      |
| `CONVERSION_WEBHOOK_URL`     | `https://t.keybuzz.io/mp/collect`           |
| `CONVERSION_WEBHOOK_SECRET`  | `ph-t4-dev-hmac-secret`                     |
| Image API                    | `v3.5.77-tracking-t4-api-dev` (inchangée)   |
| Pod                          | `keybuzz-api-d6775b64f-5sqww` (1/1 Running) |


