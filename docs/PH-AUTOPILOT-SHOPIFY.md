# PH-AUTOPILOT-SHOPIFY — Autopilot SAV Shopify

> Date : 10 avril 2026
> Environnement : DEV uniquement

## Objectif

Activer l'Autopilot pour les conversations Shopify avec exécution contrôlée (draft, safe_mode).

## Modifications appliquées

**Fichier unique modifié** : `/opt/keybuzz/keybuzz-api/src/modules/autopilot/engine.ts`

### A. Routing outbound Shopify
- Ajout `else if (channel === 'shopify') provider = 'smtp';` dans le bloc de routing outbound delivery
- Les réponses Shopify transitent par SMTP (email client), comme prévu

### B. Marketplace Intelligence dans le system prompt
- Import de `analyzeMarketplaceContext` et `buildMarketplaceIntelligenceBlock` depuis `marketplaceIntelligenceEngine.ts`
- Injection du bloc marketplace intelligence dans le system prompt autopilot
- Le profil `SHOPIFY_STANDARD` avec ses guidelines (INVESTIGATE_FIRST, pas de refund auto) est injecté dynamiquement

### C. Contexte Shopify enrichi dans le user prompt
- Bloc conditionnel ajouté exploitant `orderContext.shopifyContext` (chargé par `shared-ai-context.ts` / PH-SHOPIFY-04)
- Informations injectées : statut paiement, statut fulfillment, indicateur remboursement, nombre d'articles, tracking

### D. Fulfillment info channel-aware
- Remplacement du hardcode FBA/FBM par une logique dynamique :
  - `amazon` → FBA/FBM (inchangé)
  - `shopify` → fulfillmentStatus depuis shopifyContext
  - Autres → fulfillmentChannel brut ou "Standard"

### Corrections TypeScript
- Ajout de `shopifyContext?: any` dans l'interface locale `OrderContext`
- Cast `(mpErr as any).message` pour l'erreur unknown
- `const systemPrompt` → `let systemPrompt` pour permettre l'injection dynamique

## Image déployée

| Service | Tag |
|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.239-ph-autopilot-shopify-dev` |

## Données de test créées

| Type | ID | Détails |
|---|---|---|
| Order | `ord-shopify-test-001` | Commande Shopify, 2 produits, 159.97 EUR |
| Conversation | `conv-shopify-test-001` | Canal shopify, client Jean Dupont, status pending |
| Message | `msg-shopify-test-001` | Inbound, demande expédition urgente |

## Validation

### Test Shopify (conv-shopify-test-001)
- `POST /autopilot/evaluate` → **OK**
- Draft généré : 761 chars, cohérent avec contexte Shopify
- Confidence : 0.75 (> threshold 0.45)
- KBActions débités : 6.02 KBA
- safe_mode : draft seulement, pas d'envoi
- False promise detection : fonctionnelle ("je vais immédiatement vérifier")
- AI action log : entrées `autopilot_escalate` (skipped) + `autopilot_draft` (planned)

### Non-régression Amazon (conv-j1-e3-1775488903)
- `POST /autopilot/evaluate` → **OK**
- Draft généré : cohérent avec contexte Amazon
- KBActions débités : 5.89 KBA
- Aucune régression détectée

## Ce qui était déjà en place (non modifié)

| Feature | Source |
|---|---|
| Draft mode / safe_mode | engine.ts (PH133-A) |
| Modes tenant (off/supervised/autonomous) | autopilot_settings (PH131) |
| Wallet / KBActions integration | engine.ts + ai-actions.service |
| UI badges autopilot | AutopilotSection.tsx |
| UI historique autopilot | AutopilotHistorySection.tsx |
| Playbooks Shopify | playbook-engine (channel-agnostic) |
| Shopify order enrichment | shared-ai-context.ts (PH-SHOPIFY-04) |
| Shopify policy profile | marketplaceIntelligenceEngine.ts (PH-SHOPIFY-04) |

## Remarques

- Le plan `PRO` ne donne accès qu'au mode `suggestion` (pas d'autopilot). Seul le plan `AUTOPILOT` ou `ENTERPRISE` permet le mode `supervised`/`autonomous`.
- La clé PLAN_CAPABILITIES utilise `AUTOPILOT` (sans 'E'), pas `autopilote`.
- Le tenant de test a été temporairement upgraé en AUTOPILOT pour la validation, puis restauré en `pro`.

## Verdict

**DEV : VALIDÉ** — L'autopilot fonctionne correctement sur les conversations Shopify, avec draft, marketplace intelligence, contexte enrichi et non-régression Amazon confirmée.
