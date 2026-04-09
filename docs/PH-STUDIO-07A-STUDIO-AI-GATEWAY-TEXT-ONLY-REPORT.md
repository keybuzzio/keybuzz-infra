# PH-STUDIO-07A — Studio AI Gateway (Text Only) — REPORT

> Date : 2026-04-03
> Phase : PH-STUDIO-07A
> Status : **COMPLETE**

---

## 1. Objectif

Creer un moteur IA texte autonome pour Studio, separe du moteur LLM existant de KeyBuzz support.
Le moteur permet de generer du contenu texte de qualite a partir de Ideas + Learning Insights + Templates.

## 2. Architecture AI Studio

### Separation stricte
- Module dedie : `src/modules/ai/` (5 fichiers)
- Aucun import runtime depuis le moteur LLM SAV existant
- Secrets Vault propres : `secret/keybuzz/{env}/studio-llm`
- Logs, metriques, couts propres via table `ai_generations`

### Module AI

| Fichier | Role |
|---------|------|
| `ai.types.ts` | Types (AIGenerateInput, AIGenerateResult, LLMProvider, PromptContext, etc.) |
| `ai.providers.ts` | Abstraction provider (OpenAI, Anthropic) avec factory `createProvider()` |
| `ai.prompts.ts` | Prompt system v1 (system prompt + user prompt structure), estimation couts |
| `ai.service.ts` | Service principal (orchestration generation, fallback, quality score, logging) |
| `ai.routes.ts` | Routes Fastify (health, generate-preview, generate-and-save) |

### Provider Abstraction

Interface `LLMProvider` avec methode `generateText(messages, options)`.

Providers implementes :
- **OpenAI** — `fetch` natif vers `/v1/chat/completions`, JSON mode, usage tracking
- **Anthropic** — `fetch` natif vers `/v1/messages`, system prompt separe, usage tracking

Fallback :
- Si LLM non configure (`LLM_PROVIDER=none`) ou en erreur, generation heuristique (template-filling ameliore)
- Erreur tracee proprement dans `ai_generations` avec status `fallback`

## 3. Configuration Vault

### Paths

| Env | Path |
|-----|------|
| DEV | `secret/keybuzz/dev/studio-llm` |
| PROD | `secret/keybuzz/prod/studio-llm` |

### Variables

| Variable | Description | Defaut |
|----------|-------------|--------|
| LLM_PROVIDER | openai / anthropic / none | none |
| LLM_API_KEY | Cle API (vide = heuristique) | — |
| LLM_MODEL | Modele a utiliser | gpt-4o-mini |
| LLM_BASE_URL | URL custom (optionnel) | — |
| LLM_TIMEOUT_MS | Timeout appel LLM | 30000 |
| LLM_MAX_TOKENS | Tokens max reponse | 2000 |
| LLM_TEMPERATURE | Temperature | 0.7 |

Etat actuel : `LLM_PROVIDER=none` (mode heuristique). Pret pour activation LLM des qu'une API key est configuree.

## 4. Prompt System

### Version : v1

- **System prompt** : role Studio content engine, regles qualite, conventions par canal
- **User prompt** : structure idee + template sections + insights pertinents + tone + length + variantes
- **Output format** : JSON avec `variants[].sections[]` (name, label, content)

### Selection des insights

Avant generation, scoring des insights du workspace :
- +1 point par mot-cle commun (>3 chars) entre idee et insight
- +3 points par tag commun
- +2 points si canal cible = hook et insight est de type hook
- Top 5 insights injectes dans le prompt

### Refus de generation

Si pas d'idee ou pas de template : erreur HTTP 404/400 claire, pas de generation vide.

## 5. Endpoints Backend

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/api/v1/ai/health` | Status provider, LLM active, modele |
| POST | `/api/v1/ai/generate-preview` | Preview 1-3 variantes (pas de sauvegarde) |
| POST | `/api/v1/ai/generate-and-save` | Generation + sauvegarde content_items + content_versions |

### Input generate-preview / generate-and-save

```json
{
  "idea_id": "uuid",
  "template_id": "uuid",
  "tone": "professional|casual|authoritative|friendly",
  "length": "short|medium|long",
  "variations": 1-3
}
```

### Output

```json
{
  "title": "...",
  "variants": [{ "sections": [...], "body": "..." }],
  "provider": "heuristic|openai|anthropic",
  "model": "heuristic|gpt-4o-mini|...",
  "prompt_version": "v1",
  "quality_scores": [78],
  "is_fallback": false,
  "tokens_in": null,
  "tokens_out": null,
  "estimated_cost": null
}
```

## 6. Quality Score

Score heuristique 0-100, informatif :

| Critere | Points max |
|---------|-----------|
| Structure completeness (sections remplies) | 40 |
| Content richness (mots par section) | 30 |
| Uniqueness (sections non dupliquees) | 15 |
| Hook presence (si requis par template) | 15 |

## 7. Tracabilite

### Table `ai_generations` (migration 005)

| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | PK |
| workspace_id | UUID | FK workspaces |
| user_id | UUID | FK users |
| provider | VARCHAR(50) | openai/anthropic/heuristic |
| model | VARCHAR(100) | Modele utilise |
| input_type | VARCHAR(50) | content_generation |
| source_idea_id | UUID | FK ideas |
| source_template_id | UUID | FK content_templates |
| prompt_version | VARCHAR(50) | v1 |
| tokens_in | INT | Tokens input (si LLM) |
| tokens_out | INT | Tokens output (si LLM) |
| estimated_cost | NUMERIC(10,6) | Cout estime USD |
| status | VARCHAR(50) | success/fallback/error |
| error_message | TEXT | Message erreur si echec |
| created_at | TIMESTAMPTZ | Timestamp |

## 8. Frontend

### Dialog generation enrichi (/ideas)

- Selecteur template, tone, length, nombre de variantes (1-3)
- Affichage multi-variantes avec tabs V1/V2/V3
- Badge provider/model
- Badge fallback si mode heuristique
- Badge quality score (vert >= 70%, gris < 70%)
- Affichage cout estime (si LLM actif)
- Boutons Regenerate / Save as content

### Dashboard

11 cards avec compteur `AI Generations` (icone Wand2, couleur fuchsia).

## 9. Validations

### DEV — 13/13 tests passes

| Test | Resultat |
|------|----------|
| Auth session | PASS |
| AI health (provider: none, heuristic) | PASS |
| Dashboard ai_generations_count | PASS |
| Template available | PASS |
| Test idea created | PASS |
| Generate preview 1 variant — variants | PASS |
| Generate preview 1 variant — provider | PASS |
| Generate preview 1 variant — quality_scores | PASS |
| Generate preview 2 variants | PASS |
| Generate-and-save — content | PASS |
| Generate-and-save — metadata | PASS |
| AI generations tracked (3) | PASS |
| Frontend /login HTTP 200 | PASS |

### PROD

| Verification | Resultat |
|-------------|----------|
| Migration 005 appliquee | OK (CREATE TABLE + 3 INDEX) |
| API image v0.6.0-prod | re-tag from DEV |
| Frontend v0.6.0-prod | build dedie (PROD API URL) |
| Pods Running | API + Frontend |
| /health HTTP 200 | OK |
| Frontend /login HTTP 200 | OK |

## 10. Images Docker

```
ghcr.io/keybuzzio/keybuzz-studio-api:v0.6.0-dev   (DEV)
ghcr.io/keybuzzio/keybuzz-studio-api:v0.6.0-prod  (PROD — re-tag)
ghcr.io/keybuzzio/keybuzz-studio:v0.6.0-dev        (DEV)
ghcr.io/keybuzzio/keybuzz-studio:v0.6.0-prod       (PROD — build dedie)
```

## 11. Limites

| Limite | Mitigation |
|--------|------------|
| Mode heuristique uniquement (pas de LLM actif) | Ajouter API key dans Vault pour activer |
| Quality score basique | Ameliorable avec feedback utilisateur |
| Pas d'image/video generation | Prevu PH-STUDIO-07B |
| Pas d'auto-post | Prevu phases ulterieures |
| Cout estimation approximative | Basee sur rates publics, ajustable |

## 12. Documentation mise a jour

- [x] STUDIO-MASTER-REPORT.md — section PH-STUDIO-07A ajoutee
- [x] STUDIO-RULES.md — section "Studio AI Rules" ajoutee
- [x] .cursor/rules/studio-rules.mdc — section "STUDIO AI RULES" ajoutee

## 13. Verdict

### **PH-STUDIO-07A COMPLETE — STUDIO AI TEXT GATEWAY READY**

Studio dispose desormais de :
- Un moteur IA texte **autonome**, separe du moteur SAV
- Branche a **Knowledge / Ideas / Templates**
- Capable de produire du contenu texte **serieux et tracable**
- Pret pour l'activation LLM (OpenAI ou Anthropic) via simple configuration Vault
