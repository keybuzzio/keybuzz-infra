# PH138-F — Billing State Sync + Effective Plan UX

> Date : 31 mars 2026
> Auteur : Agent Cursor
> Statut : **DEV + PROD VALIDE**

---

## 1. Cause Racine

### Source de verite

```
Stripe webhook → handleSubscriptionChange() → billing_subscriptions + tenants.plan
                                             ↓
                              /billing/current (source: "db")
                                             ↓
                                    useCurrentPlan hook
                                             ↓
                                    AutopilotSection UI
```

Fallback pour tenants billing-exempt : `tenants.plan` (source: "fallback").

### Problemes identifies

| # | Probleme | Impact |
|---|---------|--------|
| 1 | Pas de refetch apres retour Stripe checkout | UI montre l'ancien plan |
| 2 | "Necessite Agent KeyBuzz" = texte statique | Dead-end UX, pas de CTA |
| 3 | Mode IA pas mis a jour apres upgrade plan | PRO reste sur "Suggestions" |
| 4 | Comptes PRO/AUTOPILOT arrivent sur mode "off" | Default incorrect |

---

## 2. Corrections (client uniquement)

### Fichier : `src/features/ai-ui/AutopilotSection.tsx`

### Fix 1 — Post-checkout URL detection + refetch

Nouveau `useEffect` qui detecte les query params :
- `?agent_keybuzz=activated` → toast "Agent KeyBuzz active" + refetch x3 (2s interval)
- `?stripe=success` → toast "Plan mis a jour" + refetch x3
- Nettoie les params URL via `history.replaceState`

Pourquoi refetch x3 : le webhook Stripe peut arriver avec un delai de 1-5 secondes.

### Fix 2 — Auto-set mode on upgrade

Dans `upgradePlan()`, apres un `change-plan` reussi :
- Auto-PATCH les settings IA : `{ is_enabled: true, mode: 'supervised'|'autonomous' }`
- PRO → mode `supervised`
- AUTOPILOT → mode `autonomous`
- Silencieux (catch errors), ne bloque pas le reload

### Fix 3 — Initial mode auto-set (premier chargement)

Quand les settings sont chargees pour la premiere fois :
- Si `mode === 'off'` ET `is_enabled === false` ET plan >= PRO
- Auto-PATCH le mode par defaut :
  - PRO → `supervised`
  - AUTOPILOT → `autonomous`
  - ENTERPRISE → `autonomous`
- Ne se declenche qu'une fois (apres save, `is_enabled` = true)

### Fix 4 — "Necessite Agent KeyBuzz" → CTA cliquable

Remplacement du `<p>` statique par un `<span>` clickable :
- `onClick` → appelle `activateAddon()`
- Spinner pendant l'activation
- Texte : "Activer Agent KeyBuzz" (au lieu de "Necessite Agent KeyBuzz")
- `cursor-pointer` + `hover:underline`

---

## 3. Aucun changement backend

- `/billing/current` : inchange
- `/billing/change-plan` : inchange
- `/billing/checkout-session` : inchange
- Webhooks : inchanges
- DB : inchangee

---

## 4. Flow apres corrections

### Upgrade plan (utilisateur existant)

```
1. Clic "Passer au plan Autopilot"
2. → change-plan (si sub active) OU checkout-session (fallback)
3. Si change-plan OK :
   → Auto-PATCH settings IA : { is_enabled: true, mode: 'autonomous' }
   → Toast "Plan mis à jour : Autopilot"
   → Page reload
4. Si checkout-session :
   → Redirect Stripe Checkout
   → Paiement → webhook → DB update
   → Redirect /settings?stripe=success
   → Refetch x3 → UI mise a jour
```

### Achat Agent KeyBuzz

```
1. Clic "Activer Agent KeyBuzz" (CTA cliquable)
2. → POST /api/billing/checkout-agent-keybuzz
3. → Redirect Stripe Checkout
4. → Paiement → webhook → has_agent_keybuzz_addon=true
5. → Redirect /settings?agent_keybuzz=activated
6. → Refetch x3 → blocs "KeyBuzz" et "Les deux" deverrouilles
```

### Premier acces (nouveau compte PRO)

```
1. PRO ouvre /settings → onglet IA
2. Settings chargees : mode='off', is_enabled=false
3. Auto-detection : plan=PRO, mode=off → auto-PATCH { is_enabled: true, mode: 'supervised' }
4. UI affiche "Supervise" comme mode par defaut ✓
```

---

## 5. Tests DEV

| Test | Resultat |
|------|----------|
| Image client | `v3.5.156-billing-state-sync-dev` |
| API health | 200 OK |
| Billing current | plan=PRO, status=active, source=fallback |
| Agent KeyBuzz status | hasAddon=false, canActivate=false |
| PH138-C: enable blocked | checkout_required |
| checkout-session fallback | URL Stripe valide |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |
| /settings?stripe=success | 200 (post-checkout) |

---

## 6. Stripe Addon Alignment

L'addon Agent KeyBuzz suit la subscription principale :
- Ajout comme `subscription.items` supplementaire (pas de 2e subscription)
- Meme cycle billing (monthly/annual) que le plan principal
- Proration automatique via Stripe (`proration_behavior: 'create_prorations'` dans change-plan)
- `findAgentKeybuzzAddonItem()` detecte l'addon dans les items subscription
- Webhook `handleSubscriptionChange` met a jour `has_agent_keybuzz_addon` en DB

---

## 7. Images Deployees

| Service | Tag DEV | Tag PROD |
|---------|---------|----------|
| Client | `v3.5.156-billing-state-sync-dev` | `v3.5.156-billing-state-sync-prod` |
| API | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |
| Worker | `v3.5.153-stripe-checkout-enforced-dev` (inchange) | `v3.5.153-stripe-checkout-enforced-prod` (inchange) |

---

## 8. Tests PROD

| Test | Resultat |
|------|----------|
| Image client PROD | `v3.5.156-billing-state-sync-prod` |
| API health | 200 OK |
| Billing current | plan=PRO, status=active, source=fallback |
| Agent KeyBuzz status | hasAddon=false |
| PH138-C: enable blocked | checkout_required |
| Client /login | 200 |
| Client /settings | 200 |
| Client /billing | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /orders | 200 |
| /settings?stripe=success | 200 (post-checkout) |
| Logs PROD | Aucune erreur PH138-F |

---

## 9. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.155-billing-fallback-dev -n keybuzz-client-dev
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.155-billing-fallback-prod -n keybuzz-client-prod
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod
```

---

## 10. GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` : `v3.5.156-billing-state-sync-dev`
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` : `v3.5.156-billing-state-sync-prod`
