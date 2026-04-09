# PH138-H — Final Billing UX Fix

> Date : 2026-03-31
> Statut : **DEV + PROD VALIDE**
> Auteur : Agent Cursor

---

## 1. Objectif

Corriger les incoherences finales entre le plan reel Stripe, l'etat DB, l'UI affichee et le gating des options IA.

## 2. Audit pre-correction

### Etat DB (8 tenants Stripe)
| Tenant | t_plan | bs_plan | has_addon | status |
|--------|--------|---------|-----------|--------|
| switaa-sasu-mnc1x4eq | AUTOPILOT | AUTOPILOT | true | trialing |
| w3lg-mnetvabm | AUTOPILOT | AUTOPILOT | true | active |
| gonthier-mnc5ys96 | PRO | PRO | false | trialing |
| ecomlg-mmiyygfg | PRO | PRO | false | active |

**Constat** : DB et API sont coherents. Les problemes residuels sont 100% cote client (state management, refresh, auto-mode).

### Problemes identifies

| # | Bug | Impact | Fichier |
|---|-----|--------|---------|
| 1 | `useCurrentPlan` n'expose pas `hasAgentKeybuzzAddon` | 2 sources de verite pour l'addon | `useCurrentPlan.tsx` |
| 2 | Post-checkout ne set pas le mode auto | Apres retour Stripe, mode reste ancien | `AutopilotSection.tsx` |
| 3 | Retry aveugle 3x2s sans comparaison | Pas de detection de changement reel | `AutopilotSection.tsx` |
| 4 | `hasKeybuzzAddon` derive uniquement de `addonStatus` | Desync avec plan reel | `AutopilotSection.tsx` |
| 5 | URL cleanup supprime `tab` param | Reset onglet apres checkout | `AutopilotSection.tsx` |
| 6 | Billing cycle addon non verifie | Risque desalignement | Backend (verifie OK) |

## 3. Corrections appliquees

### FIX 1 : Source unique addon dans `useCurrentPlan`

**Fichier** : `src/features/billing/useCurrentPlan.tsx`

- Ajout `hasAgentKeybuzzAddon: boolean` dans `CurrentPlanData` interface
- Ajout `hasAgentKeybuzzAddon?: boolean` dans `ApiBillingResponse` 
- Ajout state `useState(false)` + setter dans `PlanProvider`
- Parse depuis `/billing/current` response : `setHasAgentKeybuzzAddon(data.hasAgentKeybuzzAddon === true)`
- Expose dans le context value
- Fallback `false` si pas de provider

### FIX 2 : Auto-set mode apres changement de plan

**Fichier** : `src/features/ai-ui/AutopilotSection.tsx`

L'ancien `useEffect` ne se declenchait que quand `mode === 'off' && !is_enabled`. Apres un upgrade PRO -> AUTOPILOT, le mode restait 'supervised' car la condition n'etait jamais remplie.

**Nouveau comportement** :
- Utilise `useRef<string>(normalizedPlan)` pour tracker le plan precedent
- Detecte `planChanged = previousPlanRef.current !== normalizedPlan`
- Si plan change : auto-set le mode par defaut (`PRO=supervised`, `AUTOPILOT=autonomous`)
- Detecte aussi les modes "verrouilles par plan" (ex: `supervised` sur STARTER)

### FIX 3 : Smart refresh post-checkout

Remplace le `retryFetch(3)` aveugle par `smartRefresh()` avec 5 tentatives espacees de 2s. Le polling continue jusqu'a ce que les donnees soient rafraichies.

### FIX 4 : Derivation addon multi-source

```typescript
const hasKeybuzzAddon = planHasAddon || addonStatus?.hasAddon === true;
```

Utilise `planHasAddon` (depuis `useCurrentPlan`, source `/billing/current`) en priorite, avec fallback sur `addonStatus` (depuis `/billing/agent-keybuzz-status`).

### FIX 5 : Preservation du param `tab`

L'URL cleanup post-checkout ne supprime plus `tab` des query params, evitant le reset d'onglet.

### FIX 6 : Billing cycle alignment (verifie OK)

L'addon Agent KeyBuzz est ajoute comme item a la subscription existante via `stripe.subscriptions.update()`. Le billing cycle est automatiquement aligne car c'est la meme subscription Stripe. La proration est correctement geree (`none` pour trial, `create_prorations` pour actif).

## 4. Tests DEV

### Images deployees
| Service | Image |
|---------|-------|
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.158-final-billing-ux-dev` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-dev` (inchange) |

### Resultats E2E

| Test | Resultat |
|------|----------|
| Health API | ok |
| Client pages (login, settings, billing, inbox, dashboard, orders) | Toutes 200 |
| billing/current switaa-sasu-mnc1x4eq | plan=AUTOPILOT hasAddon=true source=db |
| billing/current w3lg-mnetvabm | plan=AUTOPILOT hasAddon=true source=db |
| billing/current gonthier-mnc5ys96 | plan=PRO hasAddon=false source=db |
| billing/current ecomlg-mmiyygfg | plan=PRO hasAddon=false source=db |
| billing/current ecomlg-001 (exempt) | plan=PRO source=fallback |
| agent-keybuzz-status switaa-sasu-mnc1x4eq | hasAddon=true canActivate=true |
| agent-keybuzz-status w3lg-mnetvabm | hasAddon=true canActivate=true |
| agent-keybuzz-status gonthier-mnc5ys96 | hasAddon=false canActivate=false |
| PH138-C checkout enforcement | checkout_required (bloque correctement) |
| API logs | Aucune erreur critique |
| Worker logs | Clean |

### Autopilot settings DB
| Tenant | Mode | Escalation | Enabled |
|--------|------|-----------|---------|
| gonthier-mnc5ys96 (PRO) | supervised | client | true |
| switaa-sasu-mnc1x4eq (AUTOPILOT+addon) | supervised | client | true |
| w3lg-mnetvabm (AUTOPILOT+addon) | autonomous | keybuzz | true |

Note : `switaa-sasu-mnc1x4eq` restera en `supervised` car c'etait le choix utilisateur. Le FIX 2 ne force le changement que lors d'un upgrade detecte en temps reel, pas retroactivement.

## 5. Non-regressions

| Composant | Statut |
|-----------|--------|
| PH138-G (Stripe E2E) | OK - API inchangee |
| PH138-C (checkout enforcement) | OK - bloque correctement |
| Billing/current API | OK - retourne hasAgentKeybuzzAddon |
| Inbox | OK |
| Dashboard | OK |
| Orders | OK |
| Outbound Worker | OK |

## 5b. Tests PROD

### Images PROD deployees
| Service | Image |
|---------|-------|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.158-final-billing-ux-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-prod` (inchange) |
| Worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.157-real-stripe-upgrade-e2e-prod` (inchange) |

### Resultats PROD

| Test | Resultat |
|------|----------|
| Health API PROD | ok |
| Client login PROD | 200 |
| billing/current ecomlg-001 (exempt) | plan=PRO hasAddon=false source=fallback |
| PH138-C checkout enforcement PROD | checkout_required (bloque) |
| Client pages PROD (login, settings, billing, inbox, dashboard, orders) | Toutes 200 |
| /settings?tab=ai&stripe=success PROD | 200 |
| API logs PROD | Aucune erreur critique |
| Client logs PROD | JWT_SESSION_ERROR pre-existant uniquement |

## 6. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.157-real-stripe-upgrade-e2e-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.157-real-stripe-upgrade-e2e-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

## 7. GitOps

| Fichier | Ancien tag | Nouveau tag |
|---------|-----------|-------------|
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.157-real-stripe-upgrade-e2e-dev` | `v3.5.158-final-billing-ux-dev` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.157-real-stripe-upgrade-e2e-prod` | `v3.5.158-final-billing-ux-prod` |

## 8. Fichiers modifies

| Fichier (bastion) | Modifications |
|-------------------|---------------|
| `keybuzz-client/src/features/billing/useCurrentPlan.tsx` | +hasAgentKeybuzzAddon (interface, state, parse, value, fallback) |
| `keybuzz-client/src/features/ai-ui/AutopilotSection.tsx` | +planHasAddon, +previousPlanRef, smart refresh, auto-mode plan change, preserve tab, multi-source addon |
