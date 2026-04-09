# PH-STUDIO-08 — Feedback Loop & Learning System — Report

> Date : 2026-04-07
> Status : COMPLETE — ADAPTIVE AI READY

---

## 1. Objectif

Transformer le Studio d'un generateur de contenu statique en un systeme d'IA adaptative et evolutive :
- Apprendre de l'utilisation reelle (feedback utilisateur)
- Ameliorer automatiquement les prompts et outputs
- Personnaliser par workspace (chaque client a son propre modele comportemental)

## 2. Architecture

### Flux d'apprentissage
```
Utilisateur → Feedback (up/down/improve + note)
    → Categorisation auto (7 categories)
    → learning_adjustments (poids incrementaux)
    → Injection dans system prompts (prochaine generation)
    → Contenu ameliore
    → Nouveau feedback → cycle continue
```

### Nouvelles tables
| Table | Description |
|-------|-------------|
| learning_adjustments | Ajustements appris (type: prompt/tone/structure, weight, par workspace) |
| workspace_ai_preferences | Preferences IA (avg quality, counters, preferred tone/length/pipeline) |

### Colonnes ajoutees a ai_feedback
| Colonne | Type | Description |
|---------|------|-------------|
| feedback_category | VARCHAR(50) | Categorie auto-detectee (generic, too_long, unclear, etc.) |
| improvement_note | TEXT | Note d'amelioration libre saisie par l'utilisateur |
| applied | BOOLEAN | Feedback applique dans un ajustement |

## 3. Backend — Learning Engine

### Fichier : ai.learning.ts
- `categorizeFeedback(rating, comment)` — detection de 7 categories via mots-cles FR/EN
- `LearningService` :
  - `getActiveAdjustments(workspaceId)` — charge les 10 ajustements les plus importants
  - `getFeedbackTrends(workspaceId)` — aggregation feedback (total/up/down/improve, top categories, recent improvements)
  - `getWorkspacePreferences(workspaceId)` — preferences accumulees
  - `processNewFeedback(workspaceId, rating, category, comment)` — cree/renforce ajustement + update counters
  - `updateQualityAverage(workspaceId, score)` — moyenne ponderee apres chaque generation
  - `buildPromptAdditions(adjustments, trends)` — construit le bloc "ADAPTATIONS APPRISES" a injecter dans les prompts

### Integration dans ai.service.ts
- `generatePreview` charge maintenant adjustments + trends en parallele
- Les ajustements sont injectes dans le system prompt via `applyLearningToPrompt`
- `submitFeedback` categorise automatiquement et declenche `processNewFeedback`
- `getAIInsights` retourne stats completes avec quality_trend (improving/stable/declining)
- `result.learning_applied` indique si des ajustements ont ete injectes

### Nouvelles routes (ai.routes.ts)
- `GET /ai/insights` — stats AI detaillees (generations, quality, feedback, trend, issues, scores)
- `GET /ai/adjustments` — liste des ajustements actifs pour le workspace

## 4. Categories de feedback

| Categorie | Declencheur | Ajustement cree |
|-----------|-------------|-----------------|
| generic | Contenu generique | Forcer exemples concrets, chiffres, situations |
| too_long | Contenu trop long | Reduire longueur de 30% |
| too_short | Contenu trop court | Developper davantage |
| unclear | Contenu confus | Simplifier structure, phrases courtes |
| not_relevant | Hors sujet | Recentrer sur contexte client |
| wrong_tone | Ton inadapte | Adapter style d'ecriture |
| good | Feedback positif | Aucun ajustement |

## 5. Mecanisme de poids

- Nouveau feedback negatif → creation ajustement (poids 1.0)
- Feedback recurrent meme categorie → poids += 0.5 (max 5.0)
- Poids >= 3.0 → libelle "CRITIQUE" dans le prompt
- Poids >= 2.0 → libelle "IMPORTANT"
- Poids < 2.0 → libelle "Suggestion"

## 6. Quality Trend Detection

Basee sur les 20 dernieres generations reussies :
- 1ere moitie vs 2eme moitie comparees
- Si avg 2eme moitie > avg 1ere + 5 → "improving"
- Si avg 2eme moitie < avg 1ere - 5 → "declining"
- Sinon → "stable"

## 7. Frontend

### Feedback ameliore (ideas/page.tsx)
- Bouton "Improve" ouvre un champ texte pour la note d'amelioration
- Badge "Learning applied" si des ajustements ont ete injectes dans la generation
- Feedback categorise automatiquement cote backend

### Dashboard AI Intelligence (dashboard/page.tsx)
- Section dediee avec icone Brain
- 5 KPIs : Generations, Avg Quality, Positive, Negative, Improve
- Badge quality_trend (improving = vert, declining = rouge)
- Top issues (categories les plus frequentes)
- Bar chart des scores qualite recents (10 derniers, colore vert/orange/rouge)

## 8. Deploy

| Env | API Image | Frontend Image | Migration | Status |
|-----|-----------|----------------|-----------|--------|
| DEV | v0.8.0-dev | v0.8.0-dev | 009 OK | Running |
| PROD | v0.8.0-prod | v0.8.0-prod (build dedie) | 009 OK | Running |

## 9. Multi-tenant / SaaS

- learning_adjustments : filtre workspace_id, ON DELETE CASCADE
- workspace_ai_preferences : UNIQUE workspace_id, ON DELETE CASCADE
- ai_feedback enrichi : workspace-scoped
- Aucune fuite de donnees entre workspaces
- Aucune logique specifique KeyBuzz hardcodee
- Aucun secret en clair

## 10. Limites connues

- Pas de fine-tuning modele externe (hors scope)
- Ajustements bases sur des regles heuristiques, pas de ML
- Pas de A/B testing automatique
- Pas de retention policy sur les anciens adjustments (a prevoir si volume)

## 11. Verdict

**PH-STUDIO-08 COMPLETE — ADAPTIVE AI READY**

Le Studio est maintenant :
- Intelligent : apprend du feedback utilisateur
- Evolutif : les prompts s'ameliorent automatiquement
- Adapte : chaque workspace a son propre modele comportemental
- Transparent : dashboard AI avec KPIs et trends
