# PH138-K — Stripe Checkout Enforcement Final

> Date : 2026-04-01
> Statut : **DEV + PROD VALIDE**
> Auteur : Agent Cursor

---

## 1. Objectif

Forcer le passage par Stripe Checkout pour toute activation du module Agent KeyBuzz.
Supprimer l'activation directe via `stripe.subscriptions.update()`.
Afficher le prix avant engagement. Respecter le trial.

---

## 2. Modifications

### API — `billing/routes.ts`

#### Endpoint `POST /billing/checkout-agent-keybuzz` (refait integralement)

**AVANT (PH138-G)** :
1. Chemin primaire : `stripe.subscriptions.update()` direct → activation instantanee sans prix affiche
2. Fallback : Checkout Session si le direct echoue

**APRES (PH138-K)** :
1. Toujours creer une Stripe Checkout Session (pas d'activation directe)
2. Inclure tous les items existants + addon Agent KeyBuzz
3. Preserver le trial : `subscription_data.trial_end = existingSub.trial_end`
4. Stocker `previous_subscription_id` dans les metadata de la session

#### `handleCheckoutCompleted` — Nettoyage ancienne subscription

Ajout : quand le checkout addon est complete (`type === 'agent_keybuzz_addon'`), l'ancienne subscription est automatiquement annulee via `stripe.subscriptions.cancel()` pour eviter les doublons.

### API — `pricing.ts`

#### `findPlanItem()` corrige

**AVANT** : excluait uniquement `CHANNEL_ADDON_PRODUCT_ID`
**APRES** : exclut aussi `AGENT_KEYBUZZ_ADDON_PRODUCT_ID`

### Client — `AutopilotSection.tsx`

#### `activateAddon()` simplifie

- Suppression du cas `data.activated` (activation directe impossible)
- Seuls 2 cas restent : `data.alreadyActive` (toast) ou `data.url` (redirect Stripe Checkout)

#### CTA avec prix affiche

- Carte escalade KeyBuzz : "Activer Agent KeyBuzz (797 EUR/mois)"
- Banner addon : "Activer Agent KeyBuzz (797 EUR/mois)"

---

## 3. Tests DEV

### Images deployees

| Service | Image |
|---------|-------|
| API DEV | `v3.5.160-stripe-checkout-final-dev` |
| Client DEV | `v3.5.160-stripe-checkout-final-dev` |
| API PROD | `v3.5.160-stripe-checkout-final-prod` |
| Client PROD | `v3.5.160-stripe-checkout-final-prod` |

### Resultats fonctionnels

| Test | Attendu | Resultat |
|------|---------|---------|
| PRO tenant → addon | Refus 403 | `Agent KeyBuzz requires Autopilot or Enterprise plan.` |
| AUTOPILOT sans addon | **URL Checkout Stripe** | `https://checkout.stripe.com/c/pay/cs_test_...` |
| AUTOPILOT deja actif | alreadyActive | `Agent KeyBuzz is already active.` |
| Billing-exempt | No sub | `No active subscription.` |
| PH138-C enforcement | checkout_required | `L'activation necessite un paiement via Stripe Checkout.` |

### Non-regressions

| Composant | Statut |
|-----------|--------|
| Health API | ok |
| Client pages (login, settings, billing, inbox, dashboard) | Toutes 200 |
| billing/current | OK |
| PH138-C enforcement | OK |
| API logs | Clean |

---

## 4. Comportement Stripe post-fix

| Scenario | Flow | Prix visible | Trial respecte |
|----------|------|-------------|----------------|
| AUTOPILOT sans addon | Stripe Checkout → user voit prix → confirme | **OUI** (797 EUR/mois) | **OUI** (trial_end propage) |
| AUTOPILOT active sans addon | Stripe Checkout → proration calculee | **OUI** (Stripe Checkout) | N/A |
| AUTOPILOT deja actif | Toast "deja actif" | N/A | N/A |
| PRO | Erreur 403 | N/A | N/A |

---

## 5. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.159-autopilot-settings-cta-final-dev -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.159-autopilot-settings-cta-final-prod -n keybuzz-client-prod
```

---

## 6. GitOps

| Fichier | Ancien tag | Nouveau tag |
|---------|-----------|-------------|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.157-real-stripe-upgrade-e2e-dev` | `v3.5.160-stripe-checkout-final-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.159-autopilot-settings-cta-final-dev` | `v3.5.160-stripe-checkout-final-dev` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.157-real-stripe-upgrade-e2e-prod` | `v3.5.160-stripe-checkout-final-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.159-autopilot-settings-cta-final-prod` | `v3.5.160-stripe-checkout-final-prod` |

---

## 7. Fichiers modifies (bastion)

| Fichier | Modifications |
|---------|---------------|
| `keybuzz-api/src/modules/billing/routes.ts` | checkout-agent-keybuzz: suppression activation directe, toujours Checkout Session, trial_end, previous_subscription_id, cleanup ancienne sub dans handleCheckoutCompleted |
| `keybuzz-api/src/modules/billing/pricing.ts` | findPlanItem: exclut AGENT_KEYBUZZ_ADDON_PRODUCT_ID |
| `keybuzz-client/src/features/ai-ui/AutopilotSection.tsx` | activateAddon: suppression data.activated, CTA avec prix 797 EUR |
