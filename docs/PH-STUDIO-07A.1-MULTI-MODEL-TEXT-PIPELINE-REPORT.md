# PH-STUDIO-07A.1 — Multi-Model Text Pipeline Report

> Date : 2026-04-03
> Statut : DEPLOYED DEV + PROD

---

## 1. Objectif

Etendre le Studio AI Gateway texte (PH-STUDIO-07A) pour supporter un pipeline multi-modeles structure avec roles distincts par etape (draft, improve, final), support de 3 providers (OpenAI, Anthropic, Gemini), et tracabilite enrichie par step.

## 2. Providers Supportes

| Provider | API | Modele par defaut | Format output | Statut |
|----------|-----|-------------------|---------------|--------|
| OpenAI | `api.openai.com/v1/chat/completions` | gpt-4o-mini | response_format: json_object | Ready |
| Anthropic | `api.anthropic.com/v1/messages` | claude-sonnet-4-20250514 | text (JSON parsing) | Ready |
| Gemini | `generativelanguage.googleapis.com/v1beta` | gemini-2.0-flash | responseMimeType: application/json | Ready |

### Config Vault

| Env | Path |
|-----|------|
| DEV | `secret/keybuzz/dev/studio-llm` |
| PROD | `secret/keybuzz/prod/studio-llm` |

Variables : LLM_PROVIDER, LLM_API_KEY, LLM_MODEL, LLM_BASE_URL, ANTHROPIC_API_KEY, GEMINI_API_KEY, GEMINI_BASE_URL, PIPELINE_MODE, DRAFT_PROVIDER, DRAFT_MODEL, IMPROVE_PROVIDER, IMPROVE_MODEL, FINAL_PROVIDER, FINAL_MODEL

## 3. Pipeline Standard (2 etapes)

```
draft_model → final_model
```

1. **Draft** : premier jet structure respectant le template, utilisant insights et idee
2. **Final** : polish, fluidite, ton humain, version publiable

## 4. Pipeline Premium (3 etapes)

```
draft_model → improve_model → final_model
```

1. **Draft** : structure et completeness
2. **Improve** : restructuration, densification, renforcement des angles
3. **Final** : polish final, lisibilite, naturalite

## 5. Prompts par Etape

| Step | Prompt systeme | Focus |
|------|---------------|-------|
| Draft | DRAFT_SYSTEM | Completeness, structure, template fidelity, insights integration |
| Improve | IMPROVE_SYSTEM | Densify, restructure, strengthen arguments, close gaps |
| Final | FINAL_SYSTEM | Smooth flow, humanize language, perfect hook, organic CTA |
| Single | SINGLE_SYSTEM | All-in-one (equivalent ancien v1) |

Version prompt : **v2** (vs v1 monolithique de PH-STUDIO-07A)

## 6. Tracabilite Pipeline

### Migration 006 — Colonnes ajoutees a ai_generations

| Colonne | Type | But |
|---------|------|-----|
| pipeline_id | UUID | Lie toutes les steps d'une generation |
| pipeline_mode | VARCHAR(50) | single, standard, premium |
| step | VARCHAR(50) | draft, improve, final, single |
| step_order | INT | 1, 2, ou 3 |
| latency_ms | INT | Duree du call LLM en ms |

Chaque step du pipeline est enregistre comme une ligne separee dans ai_generations avec le meme pipeline_id.

## 7. Fichiers Modifies / Crees

### Backend (keybuzz-studio-api/)

| Fichier | Changement |
|---------|-----------|
| `src/modules/ai/ai.types.ts` | Types pipeline (PipelineMode, PipelineStep, PipelineConfig, PipelineStepResult), AIGenerateResult enrichi |
| `src/modules/ai/ai.providers.ts` | GeminiProvider, DEFAULT_MODELS etendu, createProviderFromKeyMap() |
| `src/modules/ai/ai.prompts.ts` | 4 system prompts (DRAFT/IMPROVE/FINAL/SINGLE), buildPromptMessages(step, previousOutput), COST_PER_1K etendu Gemini |
| `src/modules/ai/ai.service.ts` | executePipeline(), executeSingleStep(), buildPipelineConfig(), logStep() avec pipeline tracking |
| `src/modules/ai/ai.routes.ts` | pipeline_mode dans schemas Zod, health enrichi (available_providers, pipeline_modes) |
| `src/config/env.ts` | LLM_PROVIDER inclut 'gemini', ANTHROPIC_API_KEY, GEMINI_API_KEY, GEMINI_BASE_URL, PIPELINE_MODE, DRAFT/IMPROVE/FINAL_PROVIDER/MODEL |
| `src/db/schema.sql` | Phase PH-STUDIO-07A.1, ai_generations enrichi |
| `src/db/migrations/006-ai-pipeline-tracking.sql` | ALTER TABLE ai_generations ADD COLUMN (5 colonnes pipeline) |

### Frontend (keybuzz-studio/)

| Fichier | Changement |
|---------|-----------|
| `app/(studio)/ideas/page.tsx` | Selecteur pipeline mode, steps visualization, latence totale, body de requete enrichi |

### Infra (keybuzz-infra/)

| Fichier | But |
|---------|-----|
| `scripts/ph-studio-07a1-build-deploy-dev.sh` | Build & deploy DEV v0.7.0-dev |
| `scripts/ph-studio-07a1-validate-dev.sh` | Validation DEV (health, pipeline, DB columns) |
| `scripts/ph-studio-07a1-promote-prod.sh` | Promotion PROD v0.7.0-prod |
| `scripts/ph-studio-07a1-benchmark.sh` | Benchmark 5 cas de test |

## 8. Benchmarks

| Cas | Pipeline | Tone | Variants | Description |
|-----|----------|------|----------|-------------|
| 1 | Single | Professional | 1 | LinkedIn post baseline |
| 2 | Standard | Professional | 1 | LinkedIn draft→final |
| 3 | Premium | Professional | 1 | LinkedIn draft→improve→final |
| 4 | Single | Casual | 2 | Reddit 2 variantes |
| 5 | Premium | Friendly | 1 | Founder/build-in-public |

Note : benchmarks executes en mode heuristique tant qu'aucune API key n'est configuree dans Vault. Resultat significatif une fois les cles activees.

## 9. Validations

### DEV

| Check | Resultat |
|-------|----------|
| Git pull + rsync | OK |
| Migration 006 (5 ALTER TABLE + 1 CREATE INDEX) | OK |
| API build v0.7.0-dev | OK |
| Frontend build v0.7.0-dev | OK |
| K8s deploy (API + FE) | OK |
| Pods Running | OK |
| Health /health 200 | OK |

### PROD

| Check | Resultat |
|-------|----------|
| Migration 006 PROD | OK |
| API promotion v0.7.0-prod (re-tag) | OK |
| Frontend PROD build dedie | OK |
| K8s deploy PROD | OK |
| Pods Running | OK |
| Health PROD 200 | OK |
| Frontend PROD 200 | OK |

## 10. Limites

| Limite | Impact | Mitigation |
|--------|--------|------------|
| Aucune API key configuree | Pipeline fonctionne en fallback heuristique | Ajouter cles dans Vault pour activer |
| Gemini non teste en production | Provider code mais non valide avec vrai API | Test reel necessaire apres ajout cle |
| Pas de retry par step | Si un step echoue, fallback global | Retry par step prevu phase suivante |
| Benchmark heuristique uniquement | Pas de comparaison LLM reelle | Executer benchmark apres activation LLM |
| Pas de selection provider dans UI | Provider fixe par env vars | Prevu si multi-tenant |

## 11. Verdict

**PH-STUDIO-07A.1 COMPLETE — MULTI-MODEL TEXT PIPELINE READY**

Le pipeline multi-modeles est en place avec :
- 3 providers supportes (OpenAI, Anthropic, Gemini)
- 3 modes pipeline (single, standard, premium)
- Prompts specialises par etape (v2)
- Tracabilite complete par step (pipeline_id, latency, cost)
- Frontend avec selecteur pipeline mode et visualisation steps
- Deploye DEV et PROD (v0.7.0)
- Fallback heuristique fonctionnel

Prochaine etape : ajouter les API keys dans Vault pour activer les providers LLM reels.
