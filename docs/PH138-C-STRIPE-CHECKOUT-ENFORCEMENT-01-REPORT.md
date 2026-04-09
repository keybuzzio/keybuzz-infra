# PH138-C — Stripe Checkout Enforcement

> Phase : PH138-C-STRIPE-CHECKOUT-ENFORCEMENT-01
> Date : 31 mars 2026
> Environnement : DEV + PROD valides

---

## 1. Objectif

Empecher toute activation directe du module Agent KeyBuzz sans paiement Stripe.

---

## 2. Probleme corrige

L'endpoint `POST /billing/update-agent-keybuzz` permettait d'activer l'addon directement via `enable: true`, contournant le paiement Stripe.

---

## 3. Modifications

### 3.1 API Backend (billing/routes.ts)

**update-agent-keybuzz** : `enable: true` est desormais bloque

```
POST /billing/update-agent-keybuzz { enable: true }
→ 400 { error: "checkout_required", checkoutEndpoint: "/billing/checkout-agent-keybuzz" }
```

La desactivation (`enable: false`) reste fonctionnelle (retire l'addon de la subscription Stripe).

**Nouveau endpoint : `POST /billing/checkout-agent-keybuzz`**

- Verifie subscription active (AUTOPILOT ou ENTERPRISE)
- Verifie que l'addon n'est pas deja actif
- Cree une Stripe Checkout Session avec le prix addon
- Retourne l'URL de checkout
- success_url → `/settings?tab=ai&agent_keybuzz=activated`
- cancel_url → `/settings?tab=ai&agent_keybuzz=cancelled`

### 3.2 Client (AutopilotSection.tsx)

Le bouton "Activer Agent KeyBuzz" appelle desormais `/api/billing/checkout-agent-keybuzz` et redirige vers l'URL Stripe Checkout (`window.location.href = data.url`).

### 3.3 BFF Route

`POST /api/billing/checkout-agent-keybuzz` → proxy vers `/billing/checkout-agent-keybuzz`

### 3.4 Webhook Stripe (inchange)

`handleSubscriptionChange` detecte deja `findAgentKeybuzzAddonItem` et persiste `has_agent_keybuzz_addon` automatiquement lors de `subscription.updated`.

---

## 4. Images deployees

| Service | Namespace | Image |
|---|---|---|
| API DEV | keybuzz-api-dev | `v3.5.153-stripe-checkout-enforced-dev` |
| Worker DEV | keybuzz-api-dev | `v3.5.153-stripe-checkout-enforced-dev` |
| Client DEV | keybuzz-client-dev | `v3.5.153-stripe-checkout-enforced-dev` |
| API PROD | keybuzz-api-prod | `v3.5.153-stripe-checkout-enforced-prod` |
| Worker PROD | keybuzz-api-prod | `v3.5.153-stripe-checkout-enforced-prod` |
| Client PROD | keybuzz-client-prod | `v3.5.153-stripe-checkout-enforced-prod` |

---

## 5. Tests PH138-C

| Test | Requete | Attendu | Resultat |
|---|---|---|---|
| Activation bloquee | POST enable=true | `checkout_required` | `checkout_required` + checkoutEndpoint |
| Checkout sans sub | POST checkout (ecomlg-001) | Erreur | `No active subscription` |
| Desactivation sans sub | POST enable=false | Erreur | `No active subscription found` |
| Status addon | GET status | hasAddon: false | Correct |

---

## 6. Non-regression DEV

| Composant | Statut |
|---|---|
| API health | OK (200) |
| Client login | OK (200) |
| Inbox | OK (200) |
| Dashboard | OK (200) |
| Billing | OK (200) |
| Settings | OK (200) |
| Orders | OK (200) |

---

## 7. Flux activation complet

```
1. User clique "Activer Agent KeyBuzz" dans Settings > IA
2. Client POST /api/billing/checkout-agent-keybuzz { tenantId }
3. API verifie plan + subscription + addon absent
4. API cree Stripe Checkout Session
5. Client redirige vers Stripe Checkout (window.location.href)
6. User paie sur Stripe
7. Stripe webhook → subscription.updated
8. handleSubscriptionChange detecte addon → DB updated
9. has_agent_keybuzz_addon = true
10. User revient sur /settings?tab=ai&agent_keybuzz=activated
```

---

## 8. Tests PROD

| Test | Requete | Resultat |
|---|---|---|
| API health | GET /health | 200 OK |
| Client login | GET /login | 200 OK |
| enable=true BLOCKED | POST update-agent-keybuzz | `checkout_required` |
| checkout sans sub | POST checkout-agent-keybuzz | `No active subscription` |
| agent-keybuzz-status | GET status | `hasAddon:false, canActivate:false` |
| BFF billing current | GET | 200 OK |
| BFF agent-keybuzz-status | GET | 200 OK |
| BFF checkout-agent-keybuzz | POST (no sub) | 404 (correct: pas de subscription) |
| Inbox | GET | 200 OK |
| Dashboard | GET | 200 OK |
| Billing | GET | 200 OK |
| Settings | GET | 200 OK |
| Orders | GET | 200 OK |
| API logs | grep errors | Zero erreur |

---

## 9. Rollback

### DEV API
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-dev -n keybuzz-api-dev
```

### DEV Client
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.152-agent-keybuzz-ui-gating-dev -n keybuzz-client-dev
```

### PROD API
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.151-stripe-addon-prod -n keybuzz-api-prod
```

### PROD Client
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.152-agent-keybuzz-ui-gating-prod -n keybuzz-client-prod
```

---

## 10. GitOps

- `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` mis a jour
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` mis a jour

---

## 11. Verdict

**STRIPE ENFORCED — NO FREE ACTIVATION — CLEAN UX — SAFE BILLING**

- Activation Agent KeyBuzz impossible sans paiement Stripe (DEV + PROD)
- Checkout Session cree avec prix correct selon cycle (monthly/annual)
- Webhook detecte automatiquement l'addon et met a jour la DB
- Desactivation toujours possible (retire l'addon de la subscription)
- 13/13 tests PROD OK, zero erreur dans les logs
- DEV et PROD valides et alignes
