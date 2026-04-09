# PH142-C — AI Action Consistency

> Date : 2026-04-03
> Statut : DEV + PROD deployes

---

## Objectif

Garantir que toute promesse d'action faite par l'IA est suivie d'une action reelle (information directe ou transmission a l'equipe humaine). Eliminer les fausses promesses du type "je vais contacter", "je vais verifier".

## Architecture de la solution

### 1. Prevention (prompt rules)
Regles injectees dans le system prompt pour empecher l'IA de generer des fausses promesses.

### 2. Detection post-generation
Analyse regex de la suggestion generee pour detecter les patterns restants.

### 3. Alerte UI
Banniere d'avertissement dans le slide-over si une fausse promesse est detectee.

## Changements

### API (`keybuzz-api`)

**`src/modules/ai/shared-ai-context.ts`** :
- Ajout section `=== REGLE ANTI-FAUSSE PROMESSE (CRITIQUE) ===` dans `getScenarioRules()`
  - Liste des phrases interdites ("je vais contacter", "je vais verifier", etc.)
  - Reformulations obligatoires ("notre equipe va...", "je transmets...")
- Ajout 2 interdictions dans `getWritingRules()` :
  - JAMAIS promettre une action non executable
  - JAMAIS utiliser "je vais" + action physique
- Mise a jour CAS 6 (question produit) : "notre equipe va verifier"

**`src/modules/ai/ai-assist-routes.ts`** :
- Ajout `needsHumanAction` et `falsePromisePatterns` dans `AssistResponse` interface
- Ajout fonction `detectFalsePromises(text)` : 9 patterns regex
  - `je_vais_contacter`, `je_vais_verifier`, `je_vais_investiguer`
  - `je_reviens`, `je_vais_m_assurer`, `je_prends_contact`
  - `je_vais_faire`, `je_regarde`, `je_me_renseigne`
- Post-LLM : detection sur `suggestions[0].content`
- Si detecte : log `AI_FALSE_PROMISE_DETECTED` dans `ai_action_log`
- Champs `needsHumanAction` + `falsePromisePatterns` dans la reponse API

### Client (`keybuzz-client`)

**`src/features/ai-ui/AISuggestionSlideOver.tsx`** :
- State `needsHumanAction` (reset a chaque regeneration)
- Lecture de `response.needsHumanAction` apres generation
- Banniere d'avertissement ambre si fausse promesse detectee :
  "Cette suggestion contient une promesse d'action. Verifiez et reformulez si necessaire."

## Tests DEV (8/8 pass)

```
Health check:                           OK
Pattern detection:
  "Je vais contacter le transporteur"   -> DETECTE (correct)
  "Je vais verifier aupres de..."       -> DETECTE (correct)
  "Je reviens vers vous"                -> DETECTE (correct)
  "Je vais prendre contact"             -> DETECTE (correct)
  "Commande en cours de livraison"      -> NON detecte (correct)
  "Notre equipe va verifier"            -> NON detecte (correct)
  "Je transmets votre demande"          -> NON detecte (correct)
  "Colis en transit, numero ABC123"     -> NON detecte (correct)
Non-regression journal:                 OK (1298 events)
Non-regression clusters (PH142-B):      OK (1 flag, 1 cluster)
Non-regression flag (PH142-A):          OK
Prompt rules in build:                  PRESENT
```

## Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API     | `v3.5.185-ai-action-consistency-dev` | `v3.5.185-ai-action-consistency-prod` |
| Client  | `v3.5.185-ai-action-consistency-dev` | `v3.5.185-ai-action-consistency-prod` |

## Non-regression

- PH142-A (quality loop) : intact
- PH142-B (error clustering) : intact
- Journal IA : fonctionnel
- Suggestions IA : intactes
- Billing : non touche
- Autopilot : non touche

## Health checks PROD

```
API    : https://api.keybuzz.io/health  -> 200 OK
Client : https://client.keybuzz.io      -> 200 OK
Pods   : keybuzz-api 1/1 Running, keybuzz-client 1/1 Running
```

## Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-error-clustering-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.184-ai-error-clustering-dev -n keybuzz-client-dev
```

## Rollback PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.184-ai-error-clustering-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.184-ai-error-clustering-prod -n keybuzz-client-prod
```
