# PH-T8.4.1-STRIPE-REAL-VALUE-01

> Date : 2026-04-21
> Type : Correction valeur réelle des conversions
> Priorité : CRITIQUE
> Environnement : DEV UNIQUEMENT

---

## 1. OBJECTIF

Remplacer la valeur approximative basée sur les prix plans fixes (`PLAN_PRICES`) par la
valeur réelle issue de Stripe dans les événements outbound conversions StartTrial et Purchase.

---

## 2. SOURCE STRIPE


| Event          | Source Stripe             | Champ montant                                                        | Conversion  |
| -------------- | ------------------------- | -------------------------------------------------------------------- | ----------- |
| **StartTrial** | `Stripe.Checkout.Session` | `session.amount_total` (centimes)                                    | `/100`      |
| **Purchase**   | `Stripe.Subscription`     | `subscription.items.data[*].price.unit_amount * quantity` (centimes) | `somme/100` |



| Event          | Source devise                               | Champ            |
| -------------- | ------------------------------------------- | ---------------- |
| **StartTrial** | `session.currency`                          | ex: `eur`, `gbp` |
| **Purchase**   | `subscription.items.data[0].price.currency` | ex: `eur`, `gbp` |


---

## 3. VALEUR AVANT / APRÈS

### Avant (PH-T8.4)

```
PLAN_PRICES = { starter: 97, pro: 297, autopilot: 497, autopilote: 497 }
value.amount = PLAN_PRICES[plan.toLowerCase()] || 0
value.currency = 'EUR' (hardcoded)
```

Problèmes :

- Approximatif (ne reflète pas les promotions, cycles annuels, addons)
- Currency toujours EUR (même si Stripe facture en GBP)
- Aucune donnée Stripe réelle

### Après (PH-T8.4.1)

```
// StartTrial
value.amount = session.amount_total / 100  // 0 pour un trial
value.currency = session.currency.toUpperCase()

// Purchase
value.amount = Σ(item.price.unit_amount × item.quantity) / 100
value.currency = items[0].price.currency.toUpperCase()

// Fallback si données absentes
value.amount = 0  // jamais d'estimation
value.currency = 'EUR'
```

---

## 4. MODIFICATIONS


| Fichier                                       | Action  | Détail                                                                                    |
| --------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| `src/modules/outbound-conversions/emitter.ts` | MODIFIÉ | `-11 / +7 lignes` : supprimé `PLAN_PRICES`, ajouté param `stripeValue?`, valeur dynamique |
| `src/modules/billing/routes.ts`               | MODIFIÉ | `+13 lignes` : extraction `session.amount_total` + `subscription.items` aux deux hooks    |


### Changements emitter.ts

- **Supprimé** : constante `PLAN_PRICES` (97/297/497 hardcodés)
- **Ajouté** : paramètre optionnel `stripeValue?: { amount: number; currency: string }`
- **Modifié** : `amount = stripeValue?.amount ?? 0` (au lieu de `PLAN_PRICES[plan]`)
- **Modifié** : `currency = stripeValue?.currency?.toUpperCase() || 'EUR'` (au lieu de `'EUR'` hardcodé)

### Changements billing/routes.ts

**StartTrial hook** (handleCheckoutCompleted) :

```typescript
}, {
  amount: (session.amount_total || 0) / 100,
  currency: (session.currency || 'eur').toUpperCase(),
});
```

**Purchase hook** (handleSubscriptionChange) :

```typescript
const subItems = subscription.items?.data || [];
const purchaseAmount = subItems.reduce((sum, item) => {
  return sum + ((item.price?.unit_amount || 0) * (item.quantity || 1));
}, 0) / 100;
const purchaseCurrency = (subItems[0]?.price?.currency || 'eur').toUpperCase();
```

---

## 5. PAYLOAD EXEMPLE

### StartTrial (trial gratuit)

```json
{
  "event_name": "StartTrial",
  "value": {
    "amount": 0,
    "currency": "EUR"
  }
}
```

### Purchase (plan Pro mensuel)

```json
{
  "event_name": "Purchase",
  "value": {
    "amount": 297,
    "currency": "EUR"
  }
}
```

### Purchase (plan Pro + addon, facturé en GBP)

```json
{
  "event_name": "Purchase",
  "value": {
    "amount": 250.50,
    "currency": "GBP"
  }
}
```

---

## 6. VALIDATION DEV


| Cas | Test                              | Résultat                                     |
| --- | --------------------------------- | -------------------------------------------- |
| 1   | `PLAN_PRICES` supprimé du build   | ✅ 0 occurrence                               |
| 2   | `stripeValue` param dans emitter  | ✅ 3 occurrences                              |
| 3   | StartTrial value=0 EUR            | ✅ HTTP 200, amount=0 en DB                   |
| 4   | Purchase value=497 EUR            | ✅ HTTP 200, amount=497 en DB                 |
| 5   | Purchase value=250.50 GBP         | ✅ HTTP 200, amount=250.5, currency=GBP en DB |
| 6   | Sans stripeValue → defaults 0/EUR | ✅ HTTP 200, amount=0, currency=EUR           |
| 7   | Idempotence                       | ✅ `already sent, skipping`                   |
| 8   | Exclusion test (ecomlg-001)       | ✅ `exempt, skipping`                         |


### Non-régression


| Check            | Résultat                                               |
| ---------------- | ------------------------------------------------------ |
| API DEV health   | ✅ HTTP 200                                             |
| Billing module   | ✅ chargé                                               |
| Metrics module   | ✅ chargé                                               |
| Autopilot module | ✅ chargé                                               |
| PROD inchangée   | ✅ `v3.5.92-autopilot-promise-detection-guardrail-prod` |


---

## 7. BUILD


| Élément       | Valeur                                                                      |
| ------------- | --------------------------------------------------------------------------- |
| Image         | `ghcr.io/keybuzzio/keybuzz-api:v3.5.94-outbound-conversions-real-value-dev` |
| Digest        | `sha256:8dc7013433e9fe18bd671e187221027e4bf3e314b304298ef1043577a0997d91`   |
| Source        | `keybuzz-api@ph147.4/source-of-truth`                                       |
| Commit        | `c47af816`                                                                  |
| Méthode       | `build-api-from-git.sh` (clone propre)                                      |
| GitOps commit | `438d51a`                                                                   |
| Rollback      | `rollback-service.sh api dev v3.5.93-outbound-conversions-dev`              |


---

## 8. IMPACT


| Domaine            | Impact                                                              |
| ------------------ | ------------------------------------------------------------------- |
| Structure payload  | ✅ Aucun changement (même champs `value.amount` et `value.currency`) |
| Idempotence        | ✅ Inchangée                                                         |
| Exclusion test     | ✅ Inchangée                                                         |
| Attribution        | ✅ Inchangée                                                         |
| Signature HMAC     | ✅ Inchangée                                                         |
| Retry              | ✅ Inchangé                                                          |
| Metrics existantes | ✅ Aucun impact                                                      |
| Stripe webhook     | ✅ Aucun impact                                                      |
| Billing            | ✅ Aucun impact                                                      |
| PROD               | ✅ Non touchée                                                       |


---

## 9. LIMITES


| Limitation                            | Raison                                         |
| ------------------------------------- | ---------------------------------------------- |
| StartTrial amount = 0 pour les trials | Normal : pas de paiement à l'inscription trial |
| Si Stripe n'envoie pas `items.data`   | Fallback amount = 0 (pas d'estimation)         |
| Addons inclus dans le montant total   | Reflète le montant réel total facturé          |


---

## VERDICT

**REAL VALUE FROM STRIPE — NO ESTIMATION — DEV SAFE**