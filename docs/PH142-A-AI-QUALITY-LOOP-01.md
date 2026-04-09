# PH142-A — AI Quality Loop

> Date : 3 avril 2026
> Auteur : Agent Cursor
> Type : amélioration IA continue
> Statut : **DEV + PROD DEPLOYES**

---

## Objectif

Permettre de détecter et corriger facilement les erreurs IA en production via un système de logging + flag.

## Ce qui existait déjà

| Composant | Existe | Manquait |
|---|---|---|
| `ai_action_log` table | Oui | Pas de logging du contenu suggestion |
| `ai_journal_events` table | Oui | - |
| `ai_suggestion_events` table | Oui (track applied/dismissed) | Pas de flag "incorrect" |
| Journal page `/ai-journal` | Oui (lecture ai_action_log + journal) | - |
| Suggestion tracking routes | Oui (POST track, GET stats) | Pas de flag endpoint |
| Bouton flag dans le slideover | Non | Ajouté |

## Modifications

### 1. Log IA enrichi (API)

**Fichier** : `src/modules/ai/ai-assist-routes.ts`

Après chaque suggestion IA réussie, un INSERT dans `ai_action_log` avec :
- `id` : identifiant unique généré
- `action_type` : `AI_SUGGESTION_GENERATED`
- `summary` : contenu de la suggestion (300 premiers caractères)
- `payload` (JSONB) : `requestId`, `model`, `promptSummary` (500 chars), `response` (1000 chars), `suggestionsCount`, `orderRef`, `orderContextUsed`
- `confidence_score` : score de confiance moyen
- `confidence_level` : `high` / `medium` / `low`

### 2. Flag erreur (API)

**Fichier** : `src/modules/ai/suggestion-tracking-routes.ts`

Nouvel endpoint : `POST /ai/suggestions/flag`
- Params : `{ conversationId, tenantId, requestId?, reason? }`
- Crée une entrée `HUMAN_FLAGGED_INCORRECT` dans `ai_action_log`
- Payload JSONB : `flagId`, `requestId`, `reason`, `flaggedAt`, `flaggedBy`

### 3. Bouton "Incorrecte" (Client)

**Fichier** : `src/features/ai-ui/AISuggestionSlideOver.tsx`

- Bouton "Incorrecte" (icône ThumbsDown) ajouté dans le footer, entre "Regénérer" et "Fermer"
- Au hover : fond rouge subtil
- Au clic : appel `POST /api/ai/suggestions/flag`, puis affiche "Signalée" (état rouge)
- Reset automatique quand on regénère une suggestion

### 4. Route BFF (Client)

**Fichier** : `app/api/ai/suggestions/flag/route.ts` (nouveau)

- Proxy vers `POST /ai/suggestions/flag` sur l'API backend

## Tests DEV

| Test | Résultat |
|---|---|
| Génération suggestion | `AI_SUGGESTION_GENERATED` logué avec confidence 0.85, contenu, model |
| Vérification log | Entrée dans `ai_action_log` avec ID, summary, payload JSONB |
| Flag incorrect | `POST /ai/suggestions/flag` → 200 OK |
| Vérification flag | `HUMAN_FLAGGED_INCORRECT` enregistré avec raison |
| Journal API | Les deux entrées visibles dans `GET /ai/journal` |

## Non-régression

- Autopilot : non impacté (logging fire-and-forget, try/catch)
- Billing : non touché
- Auth : non touché
- Inbox/messages : non touché

## Images déployées

| Env | Service | Image |
|---|---|---|
| **DEV** | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-quality-loop-dev` |
| **DEV** | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.183-ai-quality-loop-dev` |
| **PROD** | API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-quality-loop-prod` |
| **PROD** | Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.183-ai-quality-loop-prod` |

## Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.182-ai-context-fix-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.181-critical-polish-dev -n keybuzz-client-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.182-ai-context-fix-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.181-critical-polish-prod -n keybuzz-client-prod
```

## Historique IA consultable

Le Journal IA existant (`/ai-journal`) affiche désormais :
- Les suggestions générées (`AI_SUGGESTION_GENERATED`) avec le contenu et la confiance
- Les flags "incorrecte" (`HUMAN_FLAGGED_INCORRECT`) avec la raison

Cela permet de consulter facilement les dernières réponses IA et d'identifier les erreurs signalées.

## Verdict

**AI QUALITY LOOP ACTIVE — LOG + FLAG + HISTORY — CLEAN OUTPUT**
