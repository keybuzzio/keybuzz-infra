# PH33.KBACTIONS.FINAL.MODEL — Refactor logique KBActions (Option B)

## Regle fonctionnelle officielle

L'IA est utilisable si :
- `planIncludesAi === true` ET `wallet.remaining > 0`
- OU `wallet.purchasedRemaining > 0` (tout plan, y compris Starter)

| Plan | Packs achetes | IA |
|------|--------------|-----|
| Starter | 0 | BLOCKED (STARTER_NO_BUDGET) |
| Starter | > 0 | ALLOWED (purchased_credits) |
| Pro | remaining > 0 | ALLOWED (plan_budget) |
| Pro | remaining = 0 | BLOCKED (ACTIONS_EXHAUSTED) |
| Autopilot | remaining > 0 | ALLOWED (plan_budget) |

## Modifications backend

### `checkBudgetWithCredits()` (ai-credits.service.js)

Remplace l'ancienne logique USD-based par une logique KBActions-based :

```
1. Get KBActions wallet (getActionsWallet)
2. planIncludesAi = plan in [pro, autopilot, enterprise]
3. Si planIncludesAi && remaining > 0 → ALLOWED (source: plan_budget)
4. Si purchasedRemaining > 0 → ALLOWED (source: purchased_credits)
5. Si planIncludesAi → BLOCKED (ACTIONS_EXHAUSTED)
6. Sinon → BLOCKED (STARTER_NO_BUDGET)
```

La reponse inclut maintenant un bloc `kbActions` :
```json
{
  "kbActions": {
    "remaining": 983.19,
    "purchasedRemaining": 0,
    "includedMonthly": 1000,
    "planIncludesAi": true
  }
}
```

### `/wallet/status` (credits-routes.js)

Nouveaux champs dans la reponse :
- `isAiAllowed: boolean` — compute depuis plan + wallet
- `planIncludesAi: boolean` — true pour Pro/Autopilot/Enterprise

### Regles wallet

| Champ | Source | Modifie par changement plan |
|-------|--------|-----------------------------|
| `includedMonthly` | planCapabilities | Oui (suit le plan actuel) |
| `purchasedRemaining` | Achats pack Stripe | NON (jamais touche) |
| `remaining` | included + purchased | Recalcule au reset mensuel |

### Securite anti-abus

- Grant initial idempotent par `subscriptionId` (cle : `initial_grant_{subId}`)
- `grantInitialKBActions` utilise SET (pas +=) pour eviter double-credit
- Replay webhook = solde inchange (verifie par test E2E)

## Modifications frontend

### `AISuggestionSlideOver.tsx`
- Utilise `isAiAllowed` du wallet status pour determiner l'etat exhausted
- Si `isAiAllowed === false` → mode exhausted avec modale d'achat

### `billing/ai/page.tsx`
- Banniere rouge si IA inactive (STARTER sans packs OU credits epuises)
- Banniere bleue si Starter avec packs achetes (IA active via packs)
- Affichage du statut IA (active/inactive) sous le solde

### `ai.service.ts`
- Interface `AIWalletStatus` etendue avec `isAiAllowed`, `planIncludesAi`, `kbActions`

## Tests E2E DEV (7/7 PASS)

| # | Scenario | Resultat |
|---|----------|----------|
| 1 | Starter + 0 pack → IA bloquee | PASS (STARTER_NO_BUDGET) |
| 2 | Starter + pack 50 → IA OK | PASS (purchased_credits, remaining=50) |
| 3 | Pro 1000 inclus → IA OK | PASS (plan_budget, remaining=983.19) |
| 4 | Pro → downgrade Starter → credits conserves | PASS (purchased=100 conserve) |
| 5 | Upgrade Starter → Pro → credits cumules | PASS (purchased=50, remaining=1000) |
| 6 | Replay webhook → pas de double grant | PASS (1 seule entree ledger) |
| 7 | wallet/status includes isAiAllowed | PASS (isAiAllowed=true) |

## Images DEV

| Composant | Tag |
|-----------|-----|
| API | `v3.4.1-ph33kb-final-dev-2` |
| Client | `v3.4.2-ph33kb-final-dev` |

## Rollback

| Composant | Tag rollback |
|-----------|-------------|
| API | `v3.4.1-ph343-daily-budget-fix-dev` |
| Client | `v3.4.2-ph343-budget-ux-dev` |

## Git

Commits :
- `[DEV] PH33.KBACTIONS.FINAL.MODEL: KBActions-based AI authorization (Option B)`
- `[DEV] PH33.KBACTIONS.FINAL: Fix post-build patch for KBActions authorization`

## STOP POINT

PROD non touchee. Deployer DEV uniquement.
