# PH138-M — Agent KeyBuzz PROD Stripe LIVE Recovery

> Date : 2026-04-01
> Statut : **PROD CORRIGE**

---

## Cause racine

Le produit Agent KeyBuzz et ses prix existaient **uniquement en Stripe TEST mode**.
L'API PROD utilise une cle `sk_live_*` et obtenait l'erreur :

```
StripeInvalidRequestError: No such product: 'prod_UFWneeyEEoBCIK';
a similar object exists in test mode, but a live mode key was used to make this request.
```

Les env vars PROD pointaient vers des IDs TEST :

| Variable | Valeur AVANT (TEST) | Valeur APRES (LIVE) |
|---|---|---|
| `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` | `prod_UFWneeyEEoBCIK` | `prod_UFtAMUaGMjxErY` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` | `price_1TH1jjFC0QQLHISRIOPMo7ac` | `price_1THNOUFC0QQLHISR1Tm7B8FW` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` | `price_1TH1jjFC0QQLHISRuArLsIP9` | `price_1THNOVFC0QQLHISRmvYEis5A` |

## Actions effectuees

### 1. Audit Stripe LIVE

- Cle PROD confirmee : `sk_live_*`
- Product `prod_UFWneeyEEoBCIK` : **NOT FOUND** en LIVE (existe en TEST uniquement)
- Price monthly : **NOT FOUND** en LIVE
- Price annual : **NOT FOUND** en LIVE
- Aucun produit "Agent KeyBuzz" existant en LIVE

### 2. Verification montants TEST (reference)

| Element | Montant |
|---|---|
| Monthly | 79700 cents = 797 EUR/mois |
| Annual | 765600 cents = 7656 EUR/an (~20% remise) |
| Product name | "Agent KeyBuzz" |
| Description | "Module IA avance avec escalade vers l'equipe KeyBuzz. Add-on pour plans Autopilot+." |
| Metadata | `kb_type: addon_agent_keybuzz` |

### 3. Creation en Stripe LIVE

Via l'API Stripe depuis le pod PROD (cle `sk_live_*`) :

| Element | ID LIVE cree |
|---|---|
| Product | `prod_UFtAMUaGMjxErY` |
| Price monthly (797 EUR) | `price_1THNOUFC0QQLHISR1Tm7B8FW` |
| Price annual (7656 EUR) | `price_1THNOVFC0QQLHISRmvYEis5A` |

### 4. Mise a jour env vars PROD

```bash
kubectl -n keybuzz-api-prod set env deploy/keybuzz-api \
  STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ=prod_UFtAMUaGMjxErY \
  STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY=price_1THNOUFC0QQLHISR1Tm7B8FW \
  STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL=price_1THNOVFC0QQLHISRmvYEis5A
```

Rollout automatique OK.

## Validation PROD

| Test | Resultat |
|---|---|
| Health API | `{"status":"ok"}` |
| Stripe LIVE Product | `prod_UFtAMUaGMjxErY` - Agent KeyBuzz - active: true |
| Stripe LIVE Price Monthly | `price_1THNOUFC0QQLHISR1Tm7B8FW` - 797 EUR - month |
| Stripe LIVE Price Annual | `price_1THNOVFC0QQLHISRmvYEis5A` - 7656 EUR - year |
| PH138-C enforcement | `checkout_required` |
| billing/current (ecomlg-001) | PRO, active |
| agent-keybuzz-status | hasAddon: false, canActivate: false (billing-exempt, correct) |
| Pages client (login/settings/billing/inbox/dashboard/orders) | 200 |
| API logs | Clean |
| Pods | Running 1/1 |

### Note sur ecomlg-001

Le tenant `ecomlg-001` est billing-exempt sans subscription Stripe LIVE. Le retour "No active subscription" est correct.
Pour un vrai tenant AUTOPILOT avec subscription Stripe LIVE, le checkout redirigera vers Stripe Checkout avec le prix 797 EUR/mois.

## Non-regressions

| Service | Statut |
|---|---|
| billing/current | OK |
| billing/update-agent-keybuzz | checkout_required (PH138-C) |
| billing/agent-keybuzz-status | OK |
| Client pages | 200 |
| API health | OK |
| Outbound worker | Running (inchange) |

## GitOps

| Fichier | Modification |
|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | STRIPE_PRODUCT/PRICE env vars mis a jour avec IDs LIVE |

---

## CRITICAL WARNING

**NE JAMAIS utiliser des IDs Stripe TEST en environnement PROD.**
Cela provoque une erreur immediate `StripeInvalidRequestError: No such product`.
Les modes TEST et LIVE de Stripe ont des catalogues produits completement separes.

---

## Environnements Stripe

| Environnement | Cle Stripe | IDs a utiliser |
|---|---|---|
| **DEV** (`keybuzz-api-dev`) | `sk_test_*` | IDs TEST (`prod_UFWneeyEEoBCIK`, `price_1TH1jj...`) |
| **PROD** (`keybuzz-api-prod`) | `sk_live_*` | IDs LIVE (`prod_UFtAMUaGMjxErY`, `price_1THNOU...`) |

**Regle absolue** : les IDs d'un mode ne fonctionnent JAMAIS dans l'autre mode.

---

## Rollback

### Niveau 1 — Rollback application (safe)

Revenir a l'image API precedente sans toucher aux env vars Stripe.
Les IDs LIVE restent valides et ne necessitent aucun changement.

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.160-stripe-checkout-final-prod \
  -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

Ce rollback est **safe** car il ne modifie pas les env vars Stripe.

### Niveau 2 — Desactivation addon (manuel uniquement)

Si un addon Agent KeyBuzz a ete active par erreur sur un tenant :

1. Aller sur **Stripe Dashboard** > Customers > trouver le client
2. Ouvrir la subscription
3. Retirer l'item "Agent KeyBuzz" de la subscription
4. Verifier que la DB reflète le changement via le webhook `customer.subscription.updated`

**NE JAMAIS** tenter de desactiver l'addon en modifiant les env vars ou la DB directement.

### INTERDIT — rollback env vars vers TEST

Le bloc suivant est documente comme **reference historique uniquement**.
**NE PAS EXECUTER** — cela casserait immediatement le checkout addon en PROD.

```
# INTERDIT EN PROD — IDs TEST incompatibles avec sk_live_*
# STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ=prod_UFWneeyEEoBCIK  (TEST ONLY)
# STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY=price_1TH1jjFC0QQLHISRIOPMo7ac  (TEST ONLY)
# STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL=price_1TH1jjFC0QQLHISRuArLsIP9  (TEST ONLY)
```

---

## Checklist incident Stripe Addon

En cas d'erreur "Backend error" ou "No such product" sur l'activation addon :

- [ ] Verifier la cle Stripe du pod : `sk_test_*` ou `sk_live_*` ?
- [ ] Verifier `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` : existe dans le bon mode ?
- [ ] Verifier `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` : existe dans le bon mode ?
- [ ] Verifier `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` : existe dans le bon mode ?
- [ ] Verifier que le tenant a une subscription active (`billing_subscriptions`)
- [ ] Verifier que le tenant est AUTOPILOT ou ENTERPRISE
- [ ] Verifier les logs API : `kubectl -n keybuzz-api-prod logs deployment/keybuzz-api --tail=50`
- [ ] Verifier le webhook Stripe : `billing_events` table pour evenements recents

### Commande de diagnostic rapide

```bash
POD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-prod "$POD" -- node -e "
const S = require('stripe')(process.env.STRIPE_SECRET_KEY);
(async()=>{
  const k = (process.env.STRIPE_SECRET_KEY||'').substring(0,7);
  const p = process.env.STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ;
  const m = process.env.STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY;
  console.log('Mode:', k.startsWith('sk_live') ? 'LIVE' : 'TEST');
  try { const r = await S.products.retrieve(p); console.log('Product:', r.id, '- OK'); } catch(e) { console.log('Product:', p, '- ERROR:', e.message); }
  try { const r = await S.prices.retrieve(m); console.log('Price:', r.id, '-', r.unit_amount/100, r.currency, '- OK'); } catch(e) { console.log('Price:', m, '- ERROR:', e.message); }
})();
"
```

---

## IDs de reference

### LIVE (PROD) — source de verite

| Variable | ID |
|---|---|
| `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` | `prod_UFtAMUaGMjxErY` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` | `price_1THNOUFC0QQLHISR1Tm7B8FW` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` | `price_1THNOVFC0QQLHISRmvYEis5A` |

### TEST (DEV) — reference uniquement

| Variable | ID |
|---|---|
| `STRIPE_PRODUCT_ADDON_AGENT_KEYBUZZ` | `prod_UFWneeyEEoBCIK` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_MONTHLY` | `price_1TH1jjFC0QQLHISRIOPMo7ac` |
| `STRIPE_PRICE_ADDON_AGENT_KEYBUZZ_ANNUAL` | `price_1TH1jjFC0QQLHISRuArLsIP9` |

---

## Impact DEV

Aucun changement DEV. Les env vars DEV pointent vers les IDs TEST et utilisent la cle `sk_test_*` — le fonctionnement DEV est inchange.
