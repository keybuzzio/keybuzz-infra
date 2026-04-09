# PH-STUDIO-07C — Client Intelligence Engine — REPORT

> Date : 2026-04-04
> Phase : PH-STUDIO-07C
> Statut : COMPLETE

---

## 1. Objectif

Permettre a Studio de comprendre un client, generer une strategie marketing, et produire des idees de contenu automatiquement — sans que l'utilisateur ecrive ses idees lui-meme.

## 2. Architecture

```
Client Profile → Sources → LLM Analysis → Strategy → Auto-Generated Ideas
     ↓              ↓            ↓              ↓             ↓
  client_profiles  client_sources  client_analysis  client_strategies  ideas (table existante)
```

### Flow complet
1. Utilisateur cree un **profil client** (business, niche, offer, target, pricing, channels)
2. Ajoute des **sources** (texte, URL, doc, JSON)
3. Lance une **analyse LLM** → produit ICP, pains, SWOT, positioning, tone, competitors, content_angles
4. Genere une **strategie** → angles prioritises, channels recommandes, posting frequency, formats, hooks
5. Genere des **idees automatiquement** → N idees avec titre, description, angle, canal, score, tags → stockees dans la table `ideas`

## 3. Modele de Donnees

### Migration 007 — client-intelligence.sql

| Table | Colonnes principales |
|-------|---------------------|
| client_profiles | id, workspace_id, business_name, niche, description, offer, target_customer, pricing, channels[], created_by |
| client_sources | id, workspace_id, profile_id, type, content_raw, extracted_text, status |
| client_analysis | id, workspace_id, profile_id, swot(JSONB), icp(JSONB), pains(JSONB), positioning(JSONB), tone(JSONB), competitors(JSONB), content_angles(JSONB), llm_provider, llm_model |
| client_strategies | id, workspace_id, analysis_id, content_angles(JSONB), recommended_channels[], posting_frequency, formats(JSONB), hooks_types(JSONB), llm_provider, llm_model |

Indexes sur workspace_id, profile_id, analysis_id pour toutes les tables.

## 4. Endpoints Backend

| Method | Route | Description |
|--------|-------|-------------|
| GET | /api/v1/client/health | Status + LLM availability |
| GET | /api/v1/client/profiles | List profiles |
| GET | /api/v1/client/profiles/:id | Get profile |
| POST | /api/v1/client/profiles | Create profile |
| PATCH | /api/v1/client/profiles/:id | Update profile |
| DELETE | /api/v1/client/profiles/:id | Delete profile |
| GET | /api/v1/client/sources | List sources |
| POST | /api/v1/client/sources | Add source |
| DELETE | /api/v1/client/sources/:id | Delete source |
| GET | /api/v1/client/analyses | List analyses |
| GET | /api/v1/client/analyses/:id | Get analysis detail |
| POST | /api/v1/client/analyze | Run LLM analysis |
| GET | /api/v1/client/strategies | List strategies |
| GET | /api/v1/client/strategies/:id | Get strategy |
| POST | /api/v1/client/strategy | Generate strategy from analysis |
| POST | /api/v1/ideas/generate-from-strategy | Generate N ideas from strategy |

Tous les endpoints sont proteges par auth middleware (workspace-aware).

## 5. Prompts LLM

### Analysis prompt
- System : senior marketing strategist, analyse business + produit ICP/pains/SWOT/positioning/tone/competitors/content_angles
- User : profil client + sources concatenees (max 4000 chars)
- Temperature : 0.5 (precision)
- Output : JSON structure

### Strategy prompt
- System : content strategy expert, cree strategie actionnable
- User : ICP + pains + SWOT + positioning + tone + content_angles
- Temperature : 0.6
- Output : JSON (angles, channels, frequency, formats, hooks)

### Idea generation prompt
- System : creative content strategist, genere N idees specifiques et actionnables
- User : strategie + contexte client (ICP, pains)
- Temperature : 0.8 (creativite)
- Output : JSON (ideas array)

## 6. Frontend

### Page /client
- Liste profils (sidebar gauche, selection active)
- Detail profil (description, offer, target, pricing)
- Sources (table avec type, preview, statut)
- Bouton "Run Analysis" → resultat SWOT 4 quadrants + content angles
- Lien vers /strategy pour generer la strategie

### Page /strategy
- Liste strategies (sidebar gauche)
- Detail : channels recommandes, posting frequency
- Content angles avec priority badges
- Formats et hooks types
- Section "Generate Ideas" avec compteur (1-20)
- Lien vers /ideas apres generation

### Sidebar
- "Client" (Users icon) et "Strategy" (Target icon) sous la section "Intelligence"

### Dashboard
- 13 cards (ajout client_profiles_count + client_strategies_count)

## 7. Provider Auto-Detection

Le ClientService detecte automatiquement le meilleur provider disponible :
1. Si `LLM_PROVIDER != none` et `LLM_API_KEY` present → utilise le provider configure
2. Si `GEMINI_API_KEY` present → utilise Gemini automatiquement
3. Sinon → erreur explicite "No LLM configured"

Pas d'heuristique brute pour l'analyse client (regle du prompt).

## 8. Validations

### DEV
- [x] Migration 007 appliquee (4 tables creees)
- [x] API health 200
- [x] Frontend 200
- [x] Pods Running
- [x] Logs propres (aucune erreur)
- [x] Endpoints client/health accessible (401 = auth required, attendu)

### PROD
- [x] Migration 007 appliquee (4 tables creees)
- [x] API health 200
- [x] Frontend 200
- [x] Pods Running

## 9. Images Docker

```
DEV  : ghcr.io/keybuzzio/keybuzz-studio:v0.7.3-dev / keybuzz-studio-api:v0.7.3-dev
PROD : ghcr.io/keybuzzio/keybuzz-studio:v0.7.3-prod / keybuzz-studio-api:v0.7.3-prod
```

Frontend PROD = build dedie (lecon PH-STUDIO-04C).

## 10. Limites Connues

| Limite | Impact | Mitigation |
|--------|--------|------------|
| LLM requis pour analyse | Si aucun LLM configure, analyse impossible | Erreur explicite, pas de fallback heuristique |
| Sources texte only (MVP) | Pas de parsing PDF/HTML automatique | Utilisateur colle le texte extrait |
| Pas de re-analyse | Chaque analyse cree un nouvel enregistrement | Historique complet, pas d'ecrasement |
| Pas de benchmark realise | Qualite des prompts non validee en reel | Prevu PH-STUDIO-07D |

## 11. Fichiers Crees / Modifies

### Nouveaux
- `keybuzz-studio-api/src/db/migrations/007-client-intelligence.sql`
- `keybuzz-studio-api/src/modules/client/client.types.ts`
- `keybuzz-studio-api/src/modules/client/client.service.ts`
- `keybuzz-studio-api/src/modules/client/client.routes.ts`
- `keybuzz-studio/app/(studio)/client/page.tsx`
- `keybuzz-studio/app/(studio)/strategy/page.tsx`
- `keybuzz-infra/scripts/ph-studio-07c-build-deploy-dev.sh`
- `keybuzz-infra/scripts/ph-studio-07c-promote-prod.sh`

### Modifies
- `keybuzz-studio-api/src/routes/index.ts` — import + registration clientRoutes
- `keybuzz-studio-api/src/modules/dashboard/dashboard.service.ts` — compteurs client_profiles + client_strategies
- `keybuzz-studio/config/menu.config.tsx` — ajout Client + Strategy dans sidebar
- `keybuzz-studio/app/(studio)/dashboard/page.tsx` — 13 cards
- `keybuzz-infra/docs/STUDIO-MASTER-REPORT.md` — phase 07C
- `keybuzz-infra/docs/STUDIO-RULES.md` — regles Client Intelligence
- `.cursor/rules/studio-rules.mdc` — regles Client Intelligence

## 12. Verdict

### PH-STUDIO-07C COMPLETE — CLIENT INTELLIGENCE READY

Studio peut desormais :
- Comprendre un client (profil + sources → analyse LLM structuree)
- Generer une strategie marketing (angles, channels, formats, hooks)
- Produire des idees automatiquement (strategy → N idees stockees)
- Enchainer le flux complet : client → analyse → strategie → idees → contenu
