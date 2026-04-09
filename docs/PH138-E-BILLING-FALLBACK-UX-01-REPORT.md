# PH138-E — Billing Fallback UX

> Date : 31 mars 2026
> Auteur : Agent Cursor
> Statut : **DEV + PROD VALIDE**

---

## 1. Cause Racine

### Probleme

Un tenant billing-exempt (ex: `ecomlg-001`) ou sans subscription Stripe reelle provoque
une erreur bloquante quand l'utilisateur clique "Passer au plan X" :

```
1. /billing/current retourne status: "active" (source: "fallback" — lu depuis tenants.plan)
2. upgradePlan() croit que le tenant a une subscription Stripe
3. Appelle /billing/change-plan
4. Backend: 404 "No active subscription found for this tenant"
5. Toast erreur brute affichee → dead-end UX
```

### Tenants concernes

- Tenants billing-exempt (ex: `ecomlg-001` avec `tenant_billing_exempt.exempt = true`)
- Tenants en trial sans subscription Stripe
- Tenants test

---

## 2. Solution

### Modification client uniquement

Fichier : `src/features/ai-ui/AutopilotSection.tsx`

Fonction `upgradePlan()` modifiee :

1. **`redirectToCheckout()`** : helper interne qui appelle `/api/billing/checkout-session` et redirige vers Stripe
2. **Fallback automatique** : si `change-plan` retourne 404 ou "no active subscription", appelle `redirectToCheckout()` au lieu d'afficher l'erreur
3. **Toast informatif** : "Création de votre abonnement..." au lieu de l'erreur brute

### Flow corrige

```
Cas 1 — Tenant avec subscription Stripe active :
  clic → change-plan → upgrade direct → toast "Plan mis à jour" → reload

Cas 2 — Tenant billing-exempt / sans subscription :
  clic → change-plan → 404 → fallback → checkout-session → redirect Stripe Checkout
  (toast: "Création de votre abonnement...")

Cas 3 — Tenant sans aucune donnee billing :
  clic → checkout-session direct → redirect Stripe Checkout
```

### Aucun changement backend

- `/billing/change-plan` : inchange
- `/billing/checkout-session` : inchange
- DB : inchangee
- Webhooks : inchanges

---

## 3. Tests DEV

| Test | Resultat |
|------|----------|
| Image client | `v3.5.155-billing-fallback-dev` |
| API health | 200 OK |
| Billing current (ecomlg-001) | plan=PRO, status=active, source=fallback |
| change-plan AUTOPILOT | 404 "No active subscription" (attendu) |
| checkout-session AUTOPILOT | URL Stripe Checkout valide (fallback) |

---

## 4. Non-regressions

| Test | Resultat |
|------|----------|
| PH138-A: agent-keybuzz-status | hasAddon=false — OK |
| PH138-C: update-agent-keybuzz enable=true | checkout_required — OK |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |

---

## 5. Images Deployees

| Service | Tag DEV | Tag PROD |
|---------|---------|----------|
| Client | `v3.5.155-billing-fallback-dev` | `v3.5.155-billing-fallback-prod` |
| API | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |
| Worker | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |

---

## 6. Tests PROD

| Test | Resultat |
|------|----------|
| Image client PROD | `v3.5.155-billing-fallback-prod` |
| API health | 200 OK |
| Billing current (ecomlg-001) | plan=PRO, status=active, source=fallback |
| change-plan AUTOPILOT | 404 "No active subscription" (attendu — trigger fallback) |
| checkout-session AUTOPILOT | URL Stripe LIVE valide (fallback OK) |
| PH138-A: agent-keybuzz-status | hasAddon=false — OK |
| PH138-C: update-agent-keybuzz | checkout_required — OK |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |
| Logs PROD | Aucune erreur PH138-E |

---

## 7. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.154-plan-upgrade-checkout-dev -n keybuzz-client-dev
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.154-plan-upgrade-checkout-prod -n keybuzz-client-prod
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod
```

---

## 8. GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` : `v3.5.155-billing-fallback-dev`
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` : `v3.5.155-billing-fallback-prod`
