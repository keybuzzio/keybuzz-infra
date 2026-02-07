# PH31 â€” KBActions Product Logic Report
**Date**: 2026-02-07  
**Environment auditÃ©**: DEV (`api-dev.keybuzz.io`) + PROD (`api.keybuzz.io`)  
**Tenant test**: `ecomlg-001` (plan: `pro`)

---

## 1. LOGIQUE ACTUELLE

### 1.1 Architecture double wallet

Le systÃ¨me comporte **deux wallets parallÃ¨les** pour chaque tenant :

| Wallet | Table DB | UnitÃ© | RÃ´le |
|--------|----------|-------|------|
| **KBActions Wallet** | `ai_actions_wallet` + `ai_actions_ledger` | KBActions (dÃ©cimal) | Source de vÃ©ritÃ© pour le client |
| **USD Credits Wallet** | `ai_credits_wallet` + `ai_credits_ledger` | USD | Tracking interne + topup dÃ©bordement |

### 1.2 Formule de conversion actuelle

```
Fichier: src/config/kbactions.ts

KBACTIONS_PRICE_USD = 0.02
KBACTIONS_MULTIPLIER = 3.0
MIN_KBACTIONS = 0.10

Formule: KBA = max(0.10, round((costUSD Ã— 3.0) / 0.02))
       = max(0.10, costUSD Ã— 150)
```

**Exemples rÃ©els (extraits du ledger DEV, 30 derniÃ¨res gÃ©nÃ©rations) :**

| Date | CoÃ»t USD | KBActions dÃ©bitÃ©es | Conversation |
|------|----------|-------------------|--------------|
| 2026-02-07 16:43 | $0.007149 | 1.07 | test-english |
| 2026-02-07 16:43 | $0.007629 | 1.14 | test-check-rules |
| 2026-02-07 16:35 | $0.005946 | 0.89 | cmmksmt6nv... |
| 2026-02-04 19:07 | $0.008955 | 1.34 | cmml8be7ch... |
| 2026-02-04 00:06 | $0.011607 | 1.74 | cmml43wxbc... |
| 2026-02-03 09:59 | $0.015498 | 2.32 | cmml4yyzy9... |

**Statistiques sur 30 appels :**
- Min : 0.46 KBA ($0.003)
- Max : 3.23 KBA ($0.022)
- Moyenne : 1.46 KBA ($0.010)
- CoÃ»t total : $0.293 pour 30 appels

### 1.3 Flux de consommation complet

```
1. POST /ai/assist
   â”œâ”€ Kill switch global â†’ bloque
   â”œâ”€ Kill switch tenant â†’ bloque
   â”œâ”€ AI enabled check â†’ bloque si dÃ©sactivÃ©
   â”œâ”€ checkActionsAvailable() â†’ si remaining <= 0 â†’ HTTP 402 "actions_exhausted"
   â”œâ”€ checkBudgetWithCredits() â†’ si budget Ã©puisÃ© ET pas de crÃ©dits â†’ HTTP 402
   â”‚
   â”œâ”€ chatCompletion() via LiteLLM â†’ appel LLM rÃ©el
   â”‚
   â”œâ”€ POST-GÃ‰NÃ‰RATION :
   â”‚   â”œâ”€ actualCost = result.usage.costUsdEst || 0.01
   â”‚   â”œâ”€ kbActionsToDebit = computeKBActions(actualCost)  â† FORMULE TOKEN-BASED
   â”‚   â”œâ”€ debitKBActions(tenantId, requestId, kbActionsToDebit)  â† IDEMPOTENT
   â”‚   â””â”€ useCredits(tenantId, actualCost)  â† AUSSI dÃ©bitÃ© en USD si source=credits
   â”‚
   â””â”€ RÃ©ponse: { kbActionsConsumed, kbActionsRemaining, suggestions, ... }
```

### 1.4 Allocations par plan (actuel)

```
Fichier: src/config/kbactions.ts â†’ PLAN_KBACTIONS_MONTHLY

starter:    0 KBActions/mois    (budget quotidien: $0.00)
pro:       50 KBActions/mois    (budget quotidien: $0.50)
business: 200 KBActions/mois    (budget quotidien: N/A)
enterprise: 1000 KBActions/mois (budget quotidien: N/A)
```

### 1.5 Packs d'achat (inconsistance dÃ©tectÃ©e)

| Source | Pack 1 | Pack 2 | Pack 3 |
|--------|--------|--------|--------|
| **Backend** (`kbactions.ts`) | 100 KBA / 5â‚¬ | 300 KBA / 12â‚¬ (popular) | 1000 KBA / 35â‚¬ |
| **Client** (`AIActionsLimit.tsx`) | 50 actions / 5â‚¬ | 150 actions / 12â‚¬ (popular) | 500 actions / 35â‚¬ |

âš ï¸ **IncohÃ©rence critique** : le client affiche des quantitÃ©s diffÃ©rentes du backend.

### 1.6 Comportement Ã  solde zÃ©ro

**Backend** : HTTP 402 `actions_exhausted` â†’ blocage immÃ©diat, pas de gÃ©nÃ©ration IA.

**Client** : 
- Affiche `AIActionsLimitBlock` ("Limite d'actions IA atteinte")
- Bouton "Ajouter des actions IA" â†’ ouvre modal d'achat
- Bouton "Continuer sans IA" â†’ ferme le panneau

---

## 2. Ã‰CARTS AVEC LA VISION PRODUIT

### ðŸ”´ Ã‰CART CRITIQUE #1 â€” Conversion liÃ©e aux tokens

**Vision** : "Une KBAction n'est PAS un token IA. Ne PAS lier les KBActions aux tokens."

**RÃ©alitÃ©** : La formule `KBA = costUSD Ã— 150` est **100% dÃ©rivÃ©e du coÃ»t token**. 
Le coÃ»t USD lui-mÃªme vient de `calculateCost(model, promptTokens, completionTokens)` dans `litellm.service.ts`.

**ConsÃ©quence** : Le nombre de KBActions consommÃ©es varie directement avec la longueur de la rÃ©ponse LLM. Une conversation longue = plus de tokens = plus de KBActions. Ce n'est pas une abstraction mÃ©tier, c'est un markup sur le coÃ»t token.

### ðŸ”´ Ã‰CART CRITIQUE #2 â€” Pas de pondÃ©ration par source/type

**Vision** :

| OpÃ©ration | CoÃ»t attendu |
|-----------|-------------|
| Suggestion simple Inbox | 0.2 â€“ 0.3 KBA |
| RÃ©ponse contextualisÃ©e | 0.5 KBA |
| Analyse piÃ¨ce jointe | 0.7 KBA |
| Playbook auto | 0.3 â€“ 0.6 KBA |
| Simulation | 0.2 KBA |
| Action IA lourde | 1.0 KBA |

**RÃ©alitÃ©** : **AUCUNE** pondÃ©ration par type d'opÃ©ration. Toutes les opÃ©rations passent par `computeKBActions(actualCost)` qui ne connaÃ®t que le coÃ»t USD.

**ConsÃ©quence** : Une simple suggestion coÃ»te en moyenne 1.46 KBActions (la moyenne rÃ©elle), alors que la vision prÃ©voit 0.2-0.3. C'est **5x plus cher** que le modÃ¨le mental du produit.

### ðŸ”´ Ã‰CART CRITIQUE #3 â€” Allocations plan non alignÃ©es VSL

**Vision** : "Le forfait Starter dÃ©marre avec 1000 KBActions incluses"

**RÃ©alitÃ©** :
- Starter : **0** KBActions/mois
- Pro : **50** KBActions/mois

Avec la consommation moyenne actuelle (1.46 KBA/appel), 50 KBActions Pro = **~34 assists/mois**, soit ~1 par jour.

La VSL promet "5 Ã  10 rÃ©ponses par jour, 150 Ã  300 interactions/mois" avec 1000 KBActions. Avec le coÃ»t moyen actuel, 1000 KBActions = ~685 assists/mois, ce qui est cohÃ©rent avec la promesse.

### ðŸŸ¡ Ã‰CART MODÃ‰RÃ‰ #4 â€” Blocage non progressif

**Vision** : "KeyBuzz ne doit jamais arrÃªter un support client en production. Pas de coupure sÃ¨che."

**RÃ©alitÃ©** :
- âœ… Alerte douce cÃ´tÃ© client (2 boutons : acheter / continuer sans IA)
- âœ… Pas de blocage de la rÃ©ponse manuelle
- âŒ Mais l'IA est **immÃ©diatement coupÃ©e** dÃ¨s remaining=0
- âŒ Pas de zone tampon / grÃ¢ce
- âŒ Pas de dÃ©gradation progressive (ex: basculer sur un modÃ¨le plus cheap)

### ðŸŸ¡ Ã‰CART MODÃ‰RÃ‰ #5 â€” Double wallet = complexitÃ©

**Vision** : "Un compteur simple, un solde lisible"

**RÃ©alitÃ©** : Deux wallets parallÃ¨les (KBActions + USD) avec deux ledgers, deux logiques de dÃ©bit. Le client ne voit que les KBActions, mais le backend doit coordonner les deux systÃ¨mes.

**Risque** : DÃ©synchronisation possible entre KBActions (qui bloquent) et USD (qui trackent).

### ðŸŸ¢ POINT POSITIF #1 â€” Idempotence du dÃ©bit

L'implÃ©mentation est idempotente sur `requestId` : un mÃªme appel ne peut pas Ãªtre dÃ©bitÃ© deux fois. C'est une bonne pratique.

### ðŸŸ¢ POINT POSITIF #2 â€” TracabilitÃ© complÃ¨te

Chaque opÃ©ration est logguÃ©e dans `ai_actions_ledger` avec :
- tenant_id, delta (KBA), cost_usd, reason, request_id, conversation_id, created_at

Le Journal IA peut reconstruire l'historique complet. âœ… Conforme Ã  la vision.

### ðŸŸ¢ POINT POSITIF #3 â€” USD non exposÃ© au client

Les rÃ©ponses API n'envoient jamais de donnÃ©es USD au client. Le champ `_internal.balanceUsd` est explicitement marquÃ© "not for client display". âœ… Conforme.

### ðŸŸ¢ POINT POSITIF #4 â€” Reset mensuel automatique

Le wallet se rÃ©initialise automatiquement au 1er du mois avec le quota plan. âœ… Conforme.

---

## 3. RISQUES BUSINESS

### ðŸ”´ Risque majeur : Surconsommation perÃ§ue

Avec 1.46 KBA en moyenne par appel, un client avec 1000 KBActions percevra une consommation **5x plus rapide** que ce que la VSL suggÃ¨re (si la VSL promet ~0.3 KBA/suggestion). 

**Impact** : Client frustrÃ© en 2-3 semaines au lieu de durer le mois.

### ðŸ”´ Risque majeur : VariabilitÃ© imprÃ©visible

Un client peut voir :
- Appel 1 : -0.46 KBA (conversation courte)
- Appel 2 : -3.23 KBA (conversation longue avec contexte commande)

Cette variabilitÃ© x7 va crÃ©er de la confusion et de l'inquiÃ©tude client. La vision dit : "Le client ne doit jamais se demander : Est-ce que cette rÃ©ponse va me coÃ»ter cher ?"

### ðŸŸ¡ Risque modÃ©rÃ© : IncohÃ©rence packs client/serveur

Les packs affichÃ©s au client (50/150/500) ne correspondent pas aux packs backend (100/300/1000). Si un client achÃ¨te "Pack Medium 150 actions", il pourrait recevoir 300 KBActions ou inversement.

### ðŸŸ¡ Risque modÃ©rÃ© : Starter Ã  0 KBActions

Un nouveau client en Starter n'a **aucune** KBAction. Il ne peut pas tester l'IA sans payer. Cela contredit la philosophie d'onboarding.

---

## 4. PROPOSITIONS CONCRÃˆTES

### Proposition A : PondÃ©ration mÃ©tier (PRIORITAIRE)

**Ajouter un paramÃ¨tre `source` Ã  la consommation**, avec des poids mÃ©tier fixes :

```typescript
// Nouveau fichier proposÃ©: src/config/kbactions-weights.ts

export const KBACTIONS_WEIGHTS: Record<string, number> = {
  'inbox_suggestion':       0.25,   // Suggestion simple Inbox
  'inbox_contextualized':   0.50,   // RÃ©ponse contextualisÃ©e (avec commande)
  'inbox_regenerate':       0.15,   // RÃ©gÃ©nÃ©rer une rÃ©ponse
  'attachment_analysis':    0.70,   // Analyse piÃ¨ce jointe
  'playbook_auto':          0.40,   // RÃ©ponse automatique playbook
  'playbook_simulation':    0.20,   // Simulation playbook
  'sentiment_analysis':     0.30,   // Analyse sentiment
  'heavy_decision':         1.00,   // Action IA lourde (analyse + dÃ©cision)
};

export function getKBActionsForSource(source: string): number {
  return KBACTIONS_WEIGHTS[source] || 0.50; // dÃ©faut raisonnable
}
```

**Impact** : Remplacer `computeKBActions(actualCost)` par `getKBActionsForSource(source)` dans `ai-assist-routes.ts`. Le coÃ»t USD reste trackÃ© dans le ledger pour analyse interne, mais **n'influence plus le nombre de KBActions**.

### Proposition B : Aligner les allocations plan

```typescript
// Modifier PLAN_KBACTIONS_MONTHLY dans kbactions.ts

export const PLAN_KBACTIONS_MONTHLY: Record<string, number> = {
  starter:    1000,  // Aligner VSL (150-300 interactions/mois)
  pro:        3000,  // Usage intensif
  business:   10000, // Multi-agent
  enterprise: 50000, // IllimitÃ© en pratique
};
```

### Proposition C : Aligner les packs client/serveur

Harmoniser les packs entre backend et client :

```typescript
// UnifiÃ© partout
export const KBACTIONS_PACKS = [
  { id: 'small',  name: 'Pack Starter',  kbActions: 500,  priceEur: 5 },
  { id: 'medium', name: 'Pack Pro',      kbActions: 1500, priceEur: 12 },
  { id: 'large',  name: 'Pack Business', kbActions: 5000, priceEur: 35 },
];
```

### Proposition D : Zone tampon Ã  solde bas

Au lieu d'un blocage sec Ã  0, implÃ©menter :

```
remaining > 10    â†’ Fonctionnement normal
remaining 1-10    â†’ Badge "Solde bas" + suggestion d'achat douce
remaining 0       â†’ DÃ©gradation : utiliser modÃ¨le cheap (kbz-cheap)
                     avec un coÃ»t rÃ©duit (0.1 KBA/appel)
remaining < -20   â†’ Blocage effectif (dette max tolÃ©rÃ©e)
```

### Proposition E : Simplifier le double wallet

Ã€ terme, fusionner les deux systÃ¨mes :
- **Garder uniquement** le KBActions wallet comme source de vÃ©ritÃ©
- Le tracking USD reste dans `ai_usage` (logs internes)
- Supprimer `ai_credits_wallet` / `ai_credits_ledger` qui crÃ©ent de la confusion

---

## 5. IMPACT DEV / PROD

### Si Proposition A (PondÃ©ration mÃ©tier) est implÃ©mentÃ©e :

| Composant | Modification | Impact |
|-----------|-------------|--------|
| `src/config/kbactions.ts` | Ajouter `KBACTIONS_WEIGHTS` | Faible |
| `src/services/ai-actions.service.ts` | Ajouter `getKBActionsForSource()` | Faible |
| `src/modules/ai/ai-assist-routes.ts` | Remplacer `computeKBActions(actualCost)` par `getKBActionsForSource(source)` | ModÃ©rÃ© |
| Client (AISuggestionSlideOver) | Aucun changement | Nul |
| DB | Aucune migration | Nul |

**Risque** : Faible. Le ledger continue de tracker `cost_usd` en parallÃ¨le. Rollback = remettre l'ancienne formule.

### Si Proposition B (Allocations plan) est implÃ©mentÃ©e :

| Impact | DÃ©tail |
|--------|--------|
| DEV | Modifier `PLAN_KBACTIONS_MONTHLY` â†’ rebuild API |
| PROD | MÃªme modification + reset des wallets existants au 1er du mois |
| Risque | **Faible** si fait au reset mensuel naturel |

### Si Proposition C (Packs alignÃ©s) est implÃ©mentÃ©e :

| Impact | DÃ©tail |
|--------|--------|
| Backend | Modifier `KBACTIONS_PACKS` dans `kbactions.ts` |
| Client | Modifier `ACTION_PACKS` dans `AIActionsLimit.tsx` |
| Risque | Faible (cosmÃ©tique + quantitÃ©s) |

---

## 6. Ã‰TAT ACTUEL DES WALLETS

### DEV (`ecomlg-001`)
```
Plan: pro
KBActions remaining: 6.06
Included monthly: 50
Purchased remaining: 0
Reset: 2026-03-01
Credits (USD): $88.00
Credits enabled: true
Calls today: 3 (3.10 KBA)
Calls 7d: 54 (67.78 KBA)
```

### PROD (`ecomlg-001`)
```
Plan: pro
KBActions remaining: 50.00
Included monthly: 50
Purchased remaining: 0
Reset: 2026-03-01
Credits (USD): $0.00
Credits enabled: false
Calls today: 0
Calls 7d: 0
```

---

## 7. RÃ‰SUMÃ‰ DES CONSTATS

| # | Constat | SÃ©vÃ©ritÃ© | Vision vs RÃ©alitÃ© |
|---|---------|----------|-------------------|
| 1 | Conversion = token cost Ã— 150 | ðŸ”´ Critique | KBActions liÃ©es aux tokens |
| 2 | Aucune pondÃ©ration par type | ðŸ”´ Critique | 1 clic naÃ¯f (basÃ© sur USD) |
| 3 | Starter = 0 KBActions | ðŸ”´ Critique | VSL promet 1000 |
| 4 | Pro = 50 KBActions | ðŸŸ¡ ModÃ©rÃ© | ~34 assists/mois seulement |
| 5 | Packs client â‰  server | ðŸŸ¡ ModÃ©rÃ© | Confusion Ã  l'achat |
| 6 | Blocage sec Ã  0 | ðŸŸ¡ ModÃ©rÃ© | Vision = jamais bloquer |
| 7 | Double wallet | ðŸŸ¡ ModÃ©rÃ© | ComplexitÃ© inutile |
| 8 | Idempotence dÃ©bit | ðŸŸ¢ OK | Bonne pratique |
| 9 | TraÃ§abilitÃ© ledger | ðŸŸ¢ OK | Journal complet |
| 10 | USD masquÃ© au client | ðŸŸ¢ OK | Conforme |
| 11 | Reset mensuel auto | ðŸŸ¢ OK | Conforme |

---

## 8. RECOMMANDATION PRIORITAIRE

**Ordre d'implÃ©mentation recommandÃ© :**

1. **Proposition A** (PondÃ©ration mÃ©tier) â†’ PrioritÃ© #1, impact business majeur
2. **Proposition C** (Aligner packs) â†’ Quick win, 10 minutes
3. **Proposition B** (Allocations plan) â†’ Aligner avec VSL avant launch
4. **Proposition D** (Zone tampon) â†’ UX critique pour la rÃ©tention
5. **Proposition E** (Simplifier double wallet) â†’ Tech debt, post-launch

ðŸ›‘ **STOP** : Aucune de ces modifications ne doit Ãªtre dÃ©ployÃ©e en PROD sans validation DEV complÃ¨te et approbation explicite.

---

*Rapport gÃ©nÃ©rÃ© le 2026-02-07 par l'audit PH31 KBActions Product Logic.*
