# PH33.KBACTIONS.ACCESS.V2 — Report

## Objectif
Corriger la logique d'acces IA : `isAiAllowed = wallet.remaining > 0` (independant du plan).
Ajouter `includedRemaining`, corriger le debit order (included d'abord), et le monthly reset.

## Changements

### A) Backend — checkBudgetWithCredits

**Avant (V1):**
```
if (planIncludesAi && kbWallet.remaining > 0) → ALLOWED
if (kbWallet.purchasedRemaining > 0) → ALLOWED (pour Starter)
else → STARTER_NO_BUDGET (bloque Starter meme avec remaining > 0)
```

**Apres (V2):**
```
isAiAllowed = kbWallet.remaining > 0
if (isAiAllowed) → ALLOWED (source: included ou purchased)
else → ACTIONS_EXHAUSTED (actions: BUY_PACK / UPGRADE_PLAN)
```

Fichier: `keybuzz-api/dist/services/ai-credits.service.js`

### B) Backend — getActionsWallet

Nouveau champ retourne:
- `includedRemaining = max(0, remaining - purchasedRemaining)` (computed)

Fichier: `keybuzz-api/dist/services/ai-actions.service.js`

### C) Backend — debitKBActions

Apres chaque debit, correction automatique de `purchased_remaining`:
```
if (remaining < purchased_remaining) {
    purchased_remaining = max(0, remaining)
}
```
Resultat: le debit consomme d'abord `includedRemaining`, puis `purchasedRemaining`.

### D) Backend — /wallet/status endpoint

Ajout dans la reponse:
- `isAiAllowed: remaining > 0`
- `planIncludesAi` (boolean)
- `kbActions.includedRemaining` (computed)

Fichier: `keybuzz-api/dist/modules/ai/credits-routes.js`

### E) Client — AISuggestionSlideOver.tsx

- Supprime la logique `isAiAllowed === false` separee
- Simplifie: `setExhausted(remaining <= 0)`
- Plus de message "L'IA n'est pas incluse dans le plan Starter"

### F) Client — ai.service.ts

- Supprime le message specifique "plan Starter interdit"
- Message unifie: "KBActions epuisees. Achetez un pack pour continuer."

### G) Client — billing/ai/page.tsx

- Banniere unique "KBActions epuisees" au lieu de "IA non incluse / Credits epuises"
- Ajout `includedRemaining` dans le breakdown
- `isAiAllowed` compute depuis `remaining > 0`

## Tests E2E DEV — 7/7 PASS

| # | Test | Resultat | Detail |
|---|------|----------|--------|
| 1 | **Starter remaining=983 → ALLOWED** | PASS | `allowed:true, source:plan_budget, remaining:983.19` |
| 2 | **Starter remaining=0 → BLOCKED** | PASS | `allowed:false, reason:ACTIONS_EXHAUSTED` |
| 3 | **Pro remaining=983 → ALLOWED** | PASS | `allowed:true, planIncludesAi:true` |
| 4 | **getActionsWallet includedRemaining** | PASS | `includedRemaining:983.19, purchasedRemaining:0, consistent:true` |
| 5 | **Monthly reset (purchased preserved)** | PASS | `remaining:1016.42, purchased:16.42, included:1000, monthly:1000` |
| 6 | **Debit order (included first)** | PASS | After 10: `remaining:140, purchased:50`. After 95 more: `remaining:45, purchased:45` |
| 7 | **HTTP /wallet/status** | PASS | `isAiAllowed:true, remaining:983.19, includedRemaining:983.19` |

### Preuve JSON /wallet/status
```json
{
  "isAiAllowed": true,
  "planIncludesAi": false,
  "remaining": 983.19,
  "includedRemaining": 983.19,
  "purchasedRemaining": 0,
  "includedMonthly": 0
}
```

## Tags / Digest

| Composant | Image | Digest |
|-----------|-------|--------|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.4.1-ph33kb-access-v2-dev` | `sha256:bcfae126...` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph33kb-access-v2-dev` | `sha256:6fe0dd51...` |

### Rollback
```
API:    ghcr.io/keybuzzio/keybuzz-api:v3.4.1-ph33kb-final-dev-2
Client: ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph33kb-final-dev
```

## Git
Commit `23cf80a` — `[DEV] PH33.KBACTIONS.ACCESS.V2: isAiAllowed=remaining>0 any plan + includedRemaining + debit order`

## STOP POINT
PROD non touchee. Validation Ludovic requise.
