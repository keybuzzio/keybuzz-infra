# PH138-D — Plan Upgrade Checkout UX

> Date : 31 mars 2026
> Auteur : Agent Cursor
> Statut : **DEV + PROD VALIDE**

---

## 1. Objectif

Rendre les CTA d'upgrade de plan cliquables et fonctionnels dans les parametres IA (`AutopilotSection.tsx`).

Avant PH138-D : les messages "Passez au plan X" etaient des textes statiques non cliquables.
Apres PH138-D : chaque mention d'upgrade est un bouton interactif qui declenche le changement de plan.

---

## 2. Audit

### Backend (aucun changement)

Les endpoints necessaires existaient deja :
- `POST /billing/change-plan` : change le plan d'un abonne existant (upgrade immediat, downgrade programme)
- `POST /billing/checkout-session` : cree une Stripe Checkout Session (nouveaux abonnes)
- Webhook `handleSubscriptionChange` : met a jour plan + DB apres paiement

### BFF Routes (aucun changement)

- `/api/billing/change-plan` : proxy vers backend
- `/api/billing/checkout-session` : proxy vers backend

---

## 3. Modifications Client

### Fichier : `src/features/ai-ui/AutopilotSection.tsx`

#### Ajouts

1. **`planPrice()` helper** : retourne le prix mensuel par plan (297 / 497)
2. **`upgrading` state** : tracking du plan en cours d'upgrade (spinner)
3. **`upgradePlan()` fonction** :
   - Verifie si le tenant a une subscription active (`/api/billing/current`)
   - Si oui : appelle `/api/billing/change-plan` (upgrade direct Stripe)
   - Si non : appelle `/api/billing/checkout-session` (redirect Stripe Checkout)
   - Feedback toast + reload page

#### Remplacements

| Zone | Avant | Apres |
|------|-------|-------|
| Banner STARTER | Lien `/billing/plan` statique | 2 boutons : "Passer au Pro" + "Passer a Autopilot" |
| MODE_OPTIONS locked | Texte "Passez au plan X" (amber) | CTA cliquable "Passer au plan X (prix €/mois)" (indigo, hover:underline) |
| ESCALATION_OPTIONS locked | Texte "Passez au plan X" (amber) | CTA cliquable identique |
| AUTO_ACTIONS locked | Texte "Passez au plan X" (amber, Lock icon) | CTA cliquable identique |

---

## 4. Flow Utilisateur

### Avec subscription existante (upgrade)

```
1. Clic "Passer au plan Autopilot (497 €/mois)"
2. → POST /api/billing/change-plan {targetPlan: 'AUTOPILOT', targetCycle: 'monthly'}
3. → Stripe met a jour la subscription (proration)
4. → Toast "Plan mis a jour : Autopilot"
5. → Page reload (features activees)
```

### Sans subscription (premier abonnement)

```
1. Clic "Passer au plan Pro (297 €/mois)"
2. → POST /api/billing/checkout-session {targetPlan: 'PRO', billingCycle: 'monthly'}
3. → Redirect vers Stripe Checkout
4. → Paiement
5. → Redirect vers /settings (features activees)
```

---

## 5. Tests DEV

| Test | Resultat |
|------|----------|
| API health | 200 OK |
| Billing current | plan=PRO, status=active |
| change-plan AUTOPILOT | "No active subscription" (attendu, billing exempt) |
| checkout-session PRO | URL Stripe Checkout valide |
| Agent KeyBuzz status | hasAddon=false |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |

---

## 6. Images Deployees

| Service | Tag DEV | Tag PROD |
|---------|---------|----------|
| Client | `v3.5.154-plan-upgrade-checkout-dev` | `v3.5.154-plan-upgrade-checkout-prod` |
| API | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |
| Worker | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |

---

## 7. Tests PROD

| Test | Resultat |
|------|----------|
| Image client PROD | `v3.5.154-plan-upgrade-checkout-prod` |
| API health | 200 OK |
| Billing current | plan=PRO, status=active |
| change-plan AUTOPILOT | "No active subscription" (attendu, billing exempt) |
| checkout-session PRO | URL Stripe LIVE valide |
| Agent KeyBuzz status | hasAddon=false |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |
| Logs PROD | Pas d'erreur PH138-D (JWT_SESSION_ERROR pre-existant) |

---

## 8. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.153-stripe-checkout-enforced-dev -n keybuzz-client-dev
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.153-stripe-checkout-enforced-prod -n keybuzz-client-prod
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod
```

---

## 9. GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` : `v3.5.154-plan-upgrade-checkout-dev`
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` : `v3.5.154-plan-upgrade-checkout-prod`
