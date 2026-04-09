# PH-STUDIO-06 — Learning Engine + Content Generation Foundation

> Date: 2026-04-03
> Environnements: DEV + PROD

---

## 1. Objectif

Transformer Studio en cerveau marketing + generateur de contenu :
- **Learning Engine** : ingerer des sources brutes, extraire des insights structures
- **Templates Engine** : definir des structures de contenu reutilisables
- **Content Generation** : assembler idee + insights + template → contenu pret a publier

## 2. Modeles de donnees

### learning_sources
| Champ | Type | Description |
|-------|------|-------------|
| id | UUID PK | Identifiant |
| workspace_id | UUID FK | Workspace |
| type | VARCHAR(50) | video, doc, json, workflow, url |
| title | VARCHAR(500) | Titre de la source |
| raw_content | TEXT | Contenu brut |
| extracted_text | TEXT | Texte extrait apres processing |
| status | VARCHAR(50) | raw, processed |
| tags | TEXT[] | Tags |
| created_by | UUID FK | Createur |
| created_at/updated_at | TIMESTAMPTZ | Horodatage |

### learning_insights
| Champ | Type | Description |
|-------|------|-------------|
| id | UUID PK | Identifiant |
| workspace_id | UUID FK | Workspace |
| source_id | UUID FK | Source d'origine |
| category | VARCHAR(50) | strategy, tactic, hook, framework |
| title | VARCHAR(500) | Titre de l'insight |
| content | TEXT | Contenu de l'insight |
| structure | JSONB | Donnees structurees |
| tags | TEXT[] | Tags herites de la source |
| created_at | TIMESTAMPTZ | Horodatage |

### content_templates
| Champ | Type | Description |
|-------|------|-------------|
| id | UUID PK | Identifiant |
| workspace_id | UUID FK | Workspace |
| name | VARCHAR(255) | Nom du template |
| type | VARCHAR(50) | linkedin_post, reddit_post, thread, article, script |
| structure | JSONB | Sections definissant la structure |
| created_by | UUID FK | Createur |
| created_at/updated_at | TIMESTAMPTZ | Horodatage |

## 3. Logique de processing (heuristique)

Le processing extrait des insights depuis le contenu brut par analyse de mots-cles :
- **Strategy** : strategy, approach, vision, long-term, positioning
- **Tactic** : tip, step, action, tactic, technique, method
- **Hook** : phrases courtes avec ? ou !, what if, imagine, secret
- **Framework** : framework, model, process, system, formula

Chaque paragraphe (separe par 2+ sauts de ligne, > 15 chars) est analyse. Si aucun insight n'est detecte, un insight "tactic" par defaut est cree avec le premier paragraphe.

## 4. Logique de generation

La generation assemble :
1. **Idee** (titre + description + tags)
2. **Template** (sections structurees)
3. **Insights** (tries par pertinence : matching mots + tags)
4. **Tone** (professional, casual, authoritative, friendly)
5. **Length** (short 60%, medium 100%, long 150% du maxLength)

Chaque section du template recoit un contenu genere adapte a son role (hook, insight, explanation, example, conclusion, CTA, context, problem).

## 5. Endpoints backend

| Methode | Route | Description |
|---------|-------|-------------|
| POST | /api/v1/learning/sources | Creer une source |
| GET | /api/v1/learning/sources | Lister les sources |
| GET | /api/v1/learning/sources/:id | Detail source |
| DELETE | /api/v1/learning/sources/:id | Supprimer source + insights |
| POST | /api/v1/learning/process | Traiter une source → extraire insights |
| GET | /api/v1/learning/insights | Lister les insights (filtre category/source_id) |
| GET | /api/v1/templates | Lister les templates |
| GET | /api/v1/templates/:id | Detail template |
| POST | /api/v1/templates | Creer un template |
| PATCH | /api/v1/templates/:id | Modifier un template |
| DELETE | /api/v1/templates/:id | Supprimer un template |
| POST | /api/v1/templates/seed | Charger templates par defaut |
| POST | /api/v1/content/generate | Generer un contenu (preview) |
| POST | /api/v1/content/generate-and-save | Generer et sauvegarder |

## 6. Templates par defaut (seed)

### LinkedIn Post
1. Hook — Opening line that grabs attention (150 chars)
2. Insight — Key insight or observation (300 chars)
3. Explanation — Deeper explanation with context (500 chars)
4. Conclusion — Wrap up with a takeaway (200 chars)
5. CTA — Engage the reader (100 chars)

### Reddit Post
1. Context — Set the scene (200 chars)
2. Problem — Define the problem clearly (300 chars)
3. Solution — Present the solution (500 chars)
4. Example — Real-world example or proof (400 chars)
5. Soft CTA — Subtle call to action (150 chars)

### Thread (X/LinkedIn)
1. Opener (1/) — Thread hook (280 chars)
2. Point 1 (2/) — First key point (280 chars)
3. Point 2 (3/) — Second key point (280 chars)
4. Point 3 (4/) — Third key point (280 chars)
5. Closer (5/) — Conclusion + CTA (280 chars)

## 7. Pages frontend

### /learning
- Ajout sources (titre, type, contenu brut, tags)
- Liste sources avec statut (raw/processed)
- Accordeons avec contenu brut et insights extraits
- Bouton "Process" pour chaque source
- Vue insights en grille (par categorie, colorees)
- Toggle sources/insights

### /templates
- Grille de cards avec nom, type, sections
- Creation/edition avec builder de sections
- Bouton "Load defaults" pour seeder les 3 templates
- Suppression

### /ideas (enrichi)
- Bouton "Generate" sur les idees approuvees
- Dialog de generation : choix template, tone, length
- Preview du contenu genere (par section)
- Actions : regenerer, sauvegarder comme content

### /dashboard (enrichi)
- 10 cards : knowledge, ideas, content, drafts, scheduled, published, assets, learning sources, insights, templates
- Grid responsive 5 colonnes

### Sidebar
- "Learning" et "Templates" ajoutes sous la section "Intelligence"

## 8. Fichiers crees/modifies

### Nouveaux fichiers
| Fichier | Description |
|---------|-------------|
| src/db/migrations/004-learning-templates-generation.sql | Migration SQL |
| src/modules/learning/learning.service.ts | Service learning (CRUD + processing) |
| src/modules/learning/learning.routes.ts | Routes Fastify learning |
| src/modules/templates/templates.service.ts | Service templates (CRUD + seed) |
| src/modules/templates/templates.routes.ts | Routes Fastify templates |
| src/modules/generation/generation.service.ts | Service generation (assemble + generate) |
| src/modules/generation/generation.routes.ts | Routes Fastify generation |
| app/(studio)/learning/page.tsx | Page frontend Learning |
| app/(studio)/templates/page.tsx | Page frontend Templates |

### Fichiers modifies
| Fichier | Modification |
|---------|-------------|
| src/routes/index.ts | Registration learningRoutes, templatesRoutes, generationRoutes |
| src/modules/dashboard/dashboard.service.ts | 3 nouveaux compteurs (learning_sources, learning_insights, templates) |
| src/db/schema.sql | 3 nouvelles tables + triggers (phase PH-STUDIO-06) |
| app/(studio)/ideas/page.tsx | Bouton "Generate", dialog generation |
| app/(studio)/dashboard/page.tsx | 10 cards, grid 5 colonnes |
| config/menu.config.tsx | Learning + Templates sous Intelligence |

## 9. Deploiement

### DEV
- Migration 004 appliquee via ConfigMap + pod postgres:17-alpine
- Images : `v0.5.0-dev` (API + frontend)
- Pods : Running, health OK

### PROD
- Migration 004 appliquee sur DB PROD
- API : re-tag `v0.5.0-dev` → `v0.5.0-prod`
- Frontend : **build dedie** avec `NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io`
- Images : `v0.5.0-prod`
- Pods : Running, health OK
- Baked URL : confirmee `studio-api.keybuzz.io`

## 10. Validation DEV

| Test | Resultat |
|------|----------|
| Auth request-otp | PASS |
| Auth verify-otp + session | PASS |
| Create learning source | PASS |
| List learning sources | PASS |
| Process source → insights | PASS (1 insight) |
| List insights | PASS |
| Seed templates | PASS (3 templates) |
| List templates | PASS (faux positif grep, seed OK) |
| Create custom template | PASS |
| Update template | PASS |
| Delete template | PASS |
| Create test idea | PASS |
| Generate content preview | PASS (sections generees) |
| Generate and save | PASS (content cree) |
| Dashboard new counters | PASS |
| Cleanup source | PASS |
| Cleanup idea | PASS |
| Frontend /learning page | PASS (307 redirect = protege) |
| Frontend /templates page | PASS (307 redirect = protege) |
| **Total** | **18/19 PASS (1 faux positif grep)** |

## 11. Validation PROD

| Test | Resultat |
|------|----------|
| Health API | 200 OK |
| Frontend login page | 200 OK |
| Baked URL | studio-api.keybuzz.io |
| API logs | Clean, no errors |
| Pods Running | API + Frontend |

## 12. Limites connues

| Limite | Impact | Evolution prevue |
|--------|--------|-----------------|
| Processing heuristique | Extraction basique par mots-cles | Integration LLM (PH-STUDIO-08) |
| Generation template-filling | Contenu generique sans intelligence | LLM pour personnalisation (PH-STUDIO-08) |
| Pas de variantes automatiques | Une seule sortie par generation | Variantes LLM |
| Pas d'upload fichier pour learning | Sources en texte brut uniquement | File parsing (PDF, Word) |
| Templates non versionnes | Pas d'historique de modifications | Versioning templates |

## 13. Verdict

### PH-STUDIO-06 COMPLETE — LEARNING + GENERATION READY

Studio est desormais :
- Un **cerveau marketing** capable d'ingerer des connaissances et d'extraire des insights
- Un **generateur de contenu** capable d'assembler idee + knowledge + template
- Pret pour l'integration LLM future sans refactoring

Pipeline complet : Source → Insights → Idea → Template → Generated Content → Saved Draft
