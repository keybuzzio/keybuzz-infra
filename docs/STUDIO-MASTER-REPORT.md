# KeyBuzz Studio — MASTER REPORT

> Source de verite unique pour la reprise par un autre agent
> Derniere mise a jour : 2026-04-07
> Phase courante : PH-STUDIO-08.2B (PROD Validation — COMPLETE)

---

## 1. Vision Produit

KeyBuzz Studio (studio.keybuzz.io) est un **Marketing Operating System** autonome concu pour centraliser et piloter les operations marketing de KeyBuzz :

- **Contenu** : creation, versionning, review et publication multi-canal (LinkedIn, Reddit, SEO/GEO)
- **Calendrier editorial** : planification visuelle des publications
- **Assets** : gestion des medias (images, videos, documents)
- **Knowledge** : base de connaissance (brand guides, analyses concurrentielles, etudes de marche) pour alimenter l'IA
- **Automations** : pipelines n8n, agents IA, workflows de publication
- **Ideas** : collecte et scoring d'idees de contenu depuis les signaux de marche
- **Reports** : tableaux de bord de performance et ROI

Studio est **totalement separe** des autres produits KeyBuzz (client, seller, admin, API orders/inbox).

## 2. Perimetre Actuel

### PH-STUDIO-01 (Foundation) — COMPLETE
- [x] Frontend Next.js 16.0.2 + Metronic v9.3.7 + Tailwind 4
- [x] App shell Studio (sidebar, header, footer, dark mode)
- [x] 9 pages placeholder (dashboard, ideas, content, calendar, assets, knowledge, automations, reports, settings)
- [x] Backend Fastify 5 + TypeScript
- [x] 6 modules API (health, auth, content, automation, knowledge, reporting)
- [x] Schema PostgreSQL 17 (12 tables)
- [x] Dockerfiles frontend + backend
- [x] Manifests K8s DEV (studio + studio-api)
- [x] Documentation complete (MASTER REPORT, architecture, rules, workflow)
- [x] Cursor rules (.cursor/rules/studio-rules.mdc)

### PH-STUDIO-02 (DEV Bootstrap) — DEPLOYED
- [x] npm install frontend (688 packages) + backend (89 packages)
- [x] Next.js build OK (12 pages statiques)
- [x] TypeScript backend compile OK
- [x] Fix turbopack root isolation, Fastify logger, deps Metronic
- [x] Docker build + push GHCR (v0.1.0-dev)
- [x] K8s namespaces, secrets, deploiement OK — pods Running
- [x] /health OK, frontend 413ms

### PH-STUDIO-02B (DB Isolation + TLS + Secret Hygiene) — COMPLETE
- [x] DB dediee `keybuzz_studio` creee (12 tables, user `kb_studio`)
- [x] TLS frontend : READY
- [x] Secret hygiene : token Vault efface des docs, regles Cursor renforcees

### PH-STUDIO-03 (PROD Promotion) — DEPLOYED
- [x] Images taggees v0.1.0-prod, DB dediee PROD, K8s PROD complet
- [x] Pods Running, /health OK, TLS OK

### PH-STUDIO-04A (Auth Foundation) — DEPLOYED DEV + PROD
- [x] Schema auth : auth_identities, email_otp_codes, sessions (migration 001)
- [x] Auth service : bootstrap, OTP, session, validate
- [x] Email service : SMTP via relay interne
- [x] Routes auth completes
- [x] Cookie httpOnly `kb_studio_session` (SHA-256, rate limiting OTP)
- [x] Next.js middleware + AuthProvider React
- [x] Pages /login, /setup
- [x] Images v0.2.0-dev / v0.2.0-prod

### PH-STUDIO-04B (Owner Bootstrap + Knowledge / Ideas / Content MVP) — DEPLOYED DEV + PROD
- [x] Owner cree en DEV et PROD via /auth/setup (ludovic@keybuzz.pro, workspace KeyBuzz, role owner)
- [x] Login OTP valide en DEV (email envoye + devCode retourne en DEV)
- [x] Fix auth.service.ts : devCode retourne en DEV meme quand SMTP est configure
- [x] Fix layout auth : `grow w-full` sur auth layout pour centrage correct dans le body flex
- [x] Migration 002 : extension knowledge_documents (status, summary, content_structured, tags, source, created_by), extension content_items (current_version_id), creation table ideas
- [x] Knowledge MVP : backend CRUD complet (GET/POST/PATCH/DELETE) + frontend liste/creation/edition/suppression/filtres
- [x] Ideas MVP : backend CRUD complet + frontend avec inbox, score, canal cible, tags, action "Convert to content"
- [x] Content MVP : backend CRUD complet + versions (POST/GET /content/:id/versions) + frontend avec creation/edition/statuts/historique versions
- [x] Dashboard MVP : endpoint /dashboard/stats + frontend avec compteurs reels et activite recente
- [x] Validation DEV complete : auth, knowledge CRUD, ideas CRUD, content CRUD + versions, dashboard stats, logout — TOUT OK
- [x] Images v0.3.0-dev / v0.3.0-prod (meme SHA = promotion pure)

### PH-STUDIO-04C (PROD Auth Runtime Fix) — COMPLETE
- [x] Diagnostic : URL API baked dans le JS frontend PROD pointait vers l'API DEV (`studio-api-dev.keybuzz.io`)
- [x] Cause racine : image PROD = re-tag de l'image DEV, mais `NEXT_PUBLIC_*` est resolu au build time par Next.js
- [x] Correctif : rebuild frontend PROD dedie avec `--build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io`
- [x] Image PROD : `v0.3.1-prod` (rebuild propre, pas de re-tag)
- [x] Validation navigateur reel : login OTP fonctionne, passage a l'ecran code OTP confirme
- [x] Lecon : chaque env necessite son propre build frontend (NEXT_PUBLIC_ != env var runtime)

### PH-STUDIO-05 (Assets + Calendar + Editorial Workflow) — DEPLOYED DEV + PROD
- [x] Migration 003 : extension content_assets (original_name, storage_key, storage_provider, url, tags, updated_at), creation table content_item_assets (join), extension content_calendars (timezone, created_by)
- [x] Assets MVP : upload multipart (@fastify/multipart), stockage local /data/assets/{workspace_id}/, fichier servi via route publique UUID, CRUD complet, tags, lien content-asset (attach/detach)
- [x] Calendar MVP : CRUD complet, lien avec content_items, filtrage par date/canal/statut, vue calendrier mois avec grille 7 colonnes, navigation prev/next, affichage entries par jour
- [x] Workflow editorial : transitions validees (draft→review→approved→scheduled→published→archived), transitions invalides bloquees (HTTP 400), logging activity_logs, boutons "Send to review" / "Approve" / "Schedule" / "Publish" dans la page content
- [x] Dashboard enrichi : 7 cards (knowledge, ideas, content, drafts, scheduled, published, assets), activite recente incluant calendar entries
- [x] Content-Asset linking : attach/detach/list assets par content item
- [x] Frontend PROD = build dedie (lecon PH-STUDIO-04C appliquee)
- [x] Images v0.4.0-dev / v0.4.0-prod
- [x] Validation DEV : 30/30 tests passes (auth, calendar CRUD, assets upload/CRUD/file-serve, workflow transitions 6 etapes + blocage invalide, content-asset linking)
- [x] PROD : health OK, CORS OK, login OTP OK (verifie navigateur reel)

### PH-STUDIO-06 (Learning Engine + Content Generation) — DEPLOYED DEV + PROD
- [x] Migration 004 : creation tables learning_sources, learning_insights, content_templates
- [x] Learning Engine : ajout sources (doc, video, json, workflow, url), processing heuristique (extraction strategies, tactics, hooks, frameworks), listing insights par categorie
- [x] Templates Engine : CRUD templates, seed defaults (LinkedIn Post, Reddit Post, Thread), structure par sections avec labels et descriptions
- [x] Content Generation : endpoint /content/generate (idea + template + tone + length → contenu structure), /content/generate-and-save (generation + sauvegarde en content_items avec version initiale)
- [x] Frontend /learning : ajout sources, processing, vue sources/insights, filtres, accordeons
- [x] Frontend /templates : CRUD templates, seed defaults, edition sections, grille cards
- [x] Generation UI dans /ideas : bouton "Generate" sur idees approuvees, dialog template/tone/length, preview, save as content
- [x] Dashboard enrichi : 10 cards (+ learning_sources, learning_insights, templates), grid responsive 5 colonnes
- [x] Sidebar : ajout Learning et Templates sous "Intelligence"
- [x] Validation DEV : 18/19 tests passes (1 faux positif grep sur liste templates)
- [x] Images v0.5.0-dev / v0.5.0-prod (frontend PROD = build dedie)
- [x] PROD : health OK, baked URL OK, migration appliquee

### PH-STUDIO-07A (Studio AI Gateway — Text Only) — DEPLOYED DEV + PROD
- [x] Migration 005 : creation table ai_generations (tracking des generations IA)
- [x] Module backend AI autonome : src/modules/ai/ (types, providers, prompts, service, routes)
- [x] Provider abstraction : OpenAI + Anthropic (fetch natif, pas de SDK), extensible
- [x] Fallback heuristique : si LLM indisponible ou non configure, generation par template-filling (existant ameliore)
- [x] Prompt system v1 : system prompt + user prompt structure (idee + template + insights + tone + length + variantes)
- [x] Selection insights pertinents : scoring mots-cles + tags + canal cible, top 5 injectes dans le prompt
- [x] Quality score heuristique : structure completeness + content richness + uniqueness + hook presence (0-100)
- [x] Endpoints AI : GET /ai/health, POST /ai/generate-preview (1-3 variantes), POST /ai/generate-and-save
- [x] Tracabilite : table ai_generations (provider, model, prompt_version, tokens, cost, status, error)
- [x] Config env : LLM_PROVIDER/LLM_API_KEY/LLM_MODEL/LLM_BASE_URL/LLM_TIMEOUT_MS/LLM_MAX_TOKENS/LLM_TEMPERATURE
- [x] Vault paths : secret/keybuzz/dev/studio-llm + secret/keybuzz/prod/studio-llm (initialises provider=none)
- [x] Frontend enrichi : dialog generation avec selectors (template/tone/length/variantes), tabs variantes, quality score, provider badge, fallback indicator
- [x] Dashboard enrichi : 11 cards (+ AI Generations count)
- [x] Validation DEV : 13/13 tests passes (auth, health, preview 1/2 variantes, generate-and-save, tracking, frontend)
- [x] Images v0.6.0-dev / v0.6.0-prod (frontend PROD = build dedie)
- [x] PROD : health OK, pods Running, migration appliquee

### PH-STUDIO-07A.1 (Multi-Model Text Pipeline) — DEPLOYED DEV + PROD
- [x] Migration 006 : colonnes pipeline tracking (pipeline_id, pipeline_mode, step, step_order, latency_ms) sur ai_generations
- [x] GeminiProvider : support Google AI API (generativelanguage.googleapis.com) avec systemInstruction, responseMimeType=application/json
- [x] Provider factory : createProviderFromKeyMap() pour instanciation dynamique par step
- [x] Pipeline orchestration : 3 modes (single, standard=draft→final, premium=draft→improve→final)
- [x] Prompts specialises par etape : DRAFT (structure+completeness), IMPROVE (densify+strengthen), FINAL (polish+humanize)
- [x] Prompt version v2 (distingue single/draft/improve/final vs ancien v1 monolithique)
- [x] Tracabilite enrichie : chaque step du pipeline enregistre separement (pipeline_id commun, step, step_order, latency_ms, cost)
- [x] Temperature adaptative : step final utilise temperature reduite (-0.2) pour coherence
- [x] Config env etendue : ANTHROPIC_API_KEY, GEMINI_API_KEY, GEMINI_BASE_URL, PIPELINE_MODE, DRAFT_PROVIDER/MODEL, IMPROVE_PROVIDER/MODEL, FINAL_PROVIDER/MODEL
- [x] Frontend enrichi : selecteur pipeline mode (Single/Standard/Premium), affichage steps (draft:openai/gpt-4o-mini → final:anthropic/claude), latence totale, cout total
- [x] Health endpoint enrichi : available_providers, default_pipeline_mode, pipeline_modes
- [x] Script benchmark 5 cas de test (LinkedIn single/standard/premium, Reddit 2-variants, Founder premium)
- [x] Cost tracking : Gemini models ajoutes (gemini-2.0-flash, gemini-1.5-pro) dans COST_PER_1K
- [x] Images v0.7.0-dev / v0.7.0-prod (frontend PROD = build dedie)
- [x] DEV : migration OK, pods Running, health 200, build OK
- [x] PROD : migration OK, pods Running, health 200, frontend 200

### PH-STUDIO-07C (Client Intelligence Engine) — DEPLOYED DEV + PROD
- [x] Migration 007 : creation tables client_profiles, client_sources, client_analysis, client_strategies
- [x] Module backend client/ : types, service (analyse LLM, strategie LLM, generation idees LLM), routes
- [x] Endpoints : profiles CRUD, sources CRUD, POST /client/analyze, POST /client/strategy, POST /ideas/generate-from-strategy
- [x] Analyse client LLM : ICP, pains, SWOT, positioning, tone, competitors, content_angles
- [x] Strategie LLM : content angles prioritises, channels recommandes, posting frequency, formats, hooks types
- [x] Generation d'idees auto : strategy → N idees avec titre, angle, canal, score, tags, stockees dans ideas
- [x] Frontend /client : profil client, sources, lancement analyse, resultats SWOT/angles, lien vers /strategy
- [x] Frontend /strategy : visualisation strategie, angles/formats/hooks, generation d'idees avec compteur
- [x] Sidebar : Client (Users icon) + Strategy (Target icon) sous "Intelligence"
- [x] Dashboard enrichi : 13 cards (+ client_profiles_count, client_strategies_count)
- [x] LLM requis (pas heuristique brute) : utilise le provider configure (Gemini par defaut via GEMINI_API_KEY)
- [x] Provider auto-detection : si LLM_PROVIDER=none mais GEMINI_API_KEY present, utilise Gemini automatiquement
- [x] Images v0.7.3-dev / v0.7.3-prod (frontend PROD = build dedie)
- [x] DEV : migration OK, pods Running, health 200, tables creees (4 tables client_*)
- [x] PROD : migration OK, pods Running, health 200, frontend 200

### PH-STUDIO-07A.1.1 (LLM Activation & Validation) — ACTIVE DEV + PROD
- [x] Vault DEV + PROD mis a jour : 3 providers (OpenAI, Anthropic, Gemini) — cles API stockees
- [x] K8s secret `keybuzz-studio-api-llm` cree DEV + PROD avec envFrom injection
- [x] Provider actif : OpenAI / gpt-4o-mini (Gemini en quota exceeded sur cle fournie)
- [x] 3 providers disponibles : openai, anthropic, gemini (toutes les cles injectees)
- [x] AI Health : provider=openai, model=gpt-4o-mini, llm_enabled=true
- [x] Client Intelligence valide en DEV : analyse LLM (ICP, SWOT, pains, angles), strategie, 5 idees generees
- [x] Resultats : ICP 5 dimensions, SWOT 3+3+3+3, 4 pains, 3 angles, 3 hooks, 3 formats, 5 idees (scores 75-85)
- [x] PROD infra validee : secret injecte, provider=openai, model=gpt-4o-mini, aucune erreur logs
- [x] Aucune modification code — configuration only
- [x] Aucune fuite de cle API dans logs ou rapports

### PH-STUDIO-07D (Quality Engine — SaaS-Ready) — DEPLOYED DEV + PROD
- [x] Migration 008 : creation tables prompt_templates (workspace-aware, override global) + ai_feedback (thumbs up/down/improve)
- [x] Refactor prompt system v3 : prompts dynamiques charge depuis DB (workspace prompt → fallback global), template user avec variables Mustache-like ({{client_context}}, {{insights_block}}, etc.)
- [x] Prompts system en francais par defaut, anti-generique integre dans les instructions
- [x] Quality Engine v2 : scoring multi-criteres (completeness 25, specificity 20, concreteness 20, uniqueness 15, hook 10), label (weak/average/strong/excellent)
- [x] Anti-genericite : detection phrases generiques (30+ patterns FR/EN), penalite absence chiffre/exemple, detection starts vagues
- [x] Re-generation automatique : si score < 40 ou contenu generique detecte, retry avec contraintes renforcees, garde le meilleur resultat
- [x] Client enrichment automatique : injection automatique client_profile + analysis (top pains, top angles, positioning) dans chaque generation de contenu
- [x] Validation pre-generation : contexte client charge automatiquement pour tout workspace ayant un profil
- [x] Prompts client intelligence ameliores : analyse, strategie, idees — tous en francais, avec contraintes qualite explicites
- [x] Generation idees enrichie : chaque idee doit contenir probleme reel, hook brut, type (story/data/contrarian/how-to/case-study)
- [x] Endpoints feedback : POST /ai/feedback (up/down/improve), GET /ai/feedback (liste)
- [x] Endpoints prompt templates : GET /ai/prompt-templates, POST /ai/prompt-templates (par workspace ou global)
- [x] Frontend feedback : thumbs up / thumbs down / improve dans le dialog de generation, feedback persiste
- [x] Frontend quality badges : label qualite (Weak/Average/Strong/Excellent), badge "Generic" si detecte, details breakdown accessibles
- [x] Aucun biais "KeyBuzz" dans les prompts — tout vient du client_profile (SaaS multi-tenant ready)
- [x] Images v0.7.4-dev / v0.7.4-prod (frontend PROD = build dedie)
- [x] DEV : migration OK, pods Running, health 200, frontend 200
- [x] PROD : migration OK, pods Running, health 200, frontend 200, logs propres

### PH-STUDIO-08 (Feedback Loop & Learning System) — DEPLOYED DEV + PROD
- [x] Migration 009 : enrichissement ai_feedback (feedback_category, improvement_note, applied), creation tables learning_adjustments + workspace_ai_preferences
- [x] Learning Service : categorizeFeedback (detection auto 7 categories : generic, too_long, too_short, unclear, not_relevant, wrong_tone, good)
- [x] Learning Adjustments : creation automatique d'ajustements basee sur le feedback negatif, poids incremente si pattern recurrent (max 5.0)
- [x] Workspace Preferences : table workspace_ai_preferences (preferred_tone, avg_quality_score, total_generations, total_feedback_up/down)
- [x] Prompt evolution dynamique : injection automatique des learning_adjustments actifs + feedback trends dans les system prompts
- [x] Quality Engine v2 enrichi : historique qualite via workspace_ai_preferences.avg_quality_score (moyenne ponderee), trend detection (improving/stable/declining)
- [x] Personalisation par workspace : chaque workspace accumule son propre modele comportemental (adjustments, preferences, feedback trends)
- [x] API Insights : GET /ai/insights (total_generations, avg_quality, feedback breakdown, quality_trend, top_issues, recent_scores)
- [x] API Adjustments : GET /ai/adjustments (liste des ajustements actifs)
- [x] Feedback enrichi : POST /ai/feedback accepte improvement_note, categorise automatiquement, declenche processNewFeedback (counters + adjustments)
- [x] Dashboard AI Intelligence : section dediee avec 5 KPIs (generations, avg quality, positive/negative/improve), top issues, bar chart qualite recente, badge quality_trend
- [x] Frontend feedback ameliore : champ texte "improvement_note" (apparait au clic "Improve"), badge "Learning applied" si ajustements actifs injectes
- [x] Dashboard enrichi : stats ai_feedback (total/up/down/improve) + ai_quality (avg_score, total_generations) integrees dans les stats dashboard
- [x] Images v0.8.0-dev / v0.8.0-prod (frontend PROD = build dedie)
- [x] DEV : migration OK, pods Running, health 200, frontend 200
- [x] PROD : migration OK, pods Running, health 200, frontend 200

### PH-STUDIO-08.1 (Hotfix Insights) — DEPLOYED DEV
- [x] Fix getAIInsights : colonne quality_scores n'existait pas dans ai_generations
- [x] Remplacement par comptage generations + ratio feedback pour quality trend
- [x] LLM_TIMEOUT_MS augmente de 30s a 90s (support generation 15 idees)
- [x] Image v0.8.1-dev (API uniquement)

### PH-STUDIO-08.2 (Full Auto Growth Init — KeyBuzz) — COMPLETE DEV
- [x] Profil client KeyBuzz enrichi (niche, pains, differentiation, positionnement IA+Humain+Controle)
- [x] 5 sources creees (produit, pains SAV reels, situations concretes, vision, differentiation vs concurrents)
- [x] Analyse LLM complete : ICP precis, 3 pains high severity, SWOT credible, positioning fort, tone pro+empathique
- [x] Strategie generee : angles LinkedIn/Reddit, formats article/infographie/webinaire, 3-5x/week
- [x] 13 idees generees (top 5 selectionnees, scores 82-90)
- [x] 5 contenus premium generes (score moyen 87.2%, pipeline 3 etapes)
- [x] Contenus en francais, hooks forts, exemples concrets e-commerce
- [x] 4 feedbacks soumis (2 UP, 1 DOWN "trop generique", 1 IMPROVE "plus concret")
- [x] 1 learning adjustment cree automatiquement (constraint injection)
- [x] Re-generation avec learning_applied=true (adaptation visible)
- [x] Dashboard AI Insights operationnel (5 generations, avg 87.2%, trend improving)
- [x] Rapport PH-STUDIO-08.2-KEYBUZZ-GROWTH-INIT-REPORT.md cree

### PH-STUDIO-08.2B (PROD Promotion & Runtime Validation) — COMPLETE
- [x] Hotfix v0.8.1 promu en PROD (fix getAIInsights + timeout 90s)
- [x] LLM_TIMEOUT_MS augmente de 30s a 90s en PROD
- [x] Profil client KeyBuzz enrichi en PROD
- [x] 5 sources creees en PROD (produit, pains, situations, vision, differentiation)
- [x] Analyse LLM PROD : ICP, 7 pains, SWOT, positioning, tone, 2 competitors, 3 angles
- [x] Strategie PROD : 5 angles, 5 formats, 3-5x/week
- [x] 20 idees en PROD, 5 approuvees
- [x] 3 contenus premium generes en PROD (score moyen 90%, en francais)
- [x] 3 feedbacks soumis (1 UP, 1 DOWN, 1 IMPROVE), 1 learning adjustment cree
- [x] AI Insights PROD operationnel (avg 90%, trend stable)
- [x] 7 pages frontend PROD HTTP 200, donnees visibles
- [x] Templates seedes en PROD (LinkedIn, Reddit, Thread)
- [x] Rapport PH-STUDIO-08.2B-PROD-VALIDATION-REPORT.md cree

### Ce qui reste a faire (hors blockers)
- [ ] Publication LinkedIn/Reddit
- [ ] Scheduling reel
- [ ] n8n branche
- [ ] Image/video generation
- [ ] CRM
- [ ] Invitations collaborateur
- [ ] RBAC fin
- [ ] Calendar drag-and-drop
- [ ] Asset storage persistant (PVC/S3)
- [ ] Benchmark reel multi-provider (comparaison single/standard/premium + client intelligence)

## 3. Architecture

### Stack
| Composant | Technologie | Version |
|-----------|------------|---------|
| Frontend | Next.js (App Router) | 16.0.2 (PAS 16.1) |
| UI Kit | Metronic Tailwind React | 9.3.7 |
| CSS | Tailwind CSS | 4.1 |
| TypeScript | TypeScript | 5.9 |
| Backend | Fastify | 5.x |
| Database | PostgreSQL | 17 |
| Container | Node 20 Alpine | — |
| Orchestration | K8s + ArgoCD | — |
| Registry | ghcr.io/keybuzzio | — |

### Frontend (keybuzz-studio/)
```
app/
  layout.tsx                  → Root layout (ThemeProvider, Inter font)
  page.tsx                    → Redirect /dashboard
  (auth)/
    layout.tsx                → Auth layout (grow w-full, pas de shell Studio)
    login/page.tsx            → Login email + OTP (InputOTP, devCode DEV)
    setup/page.tsx            → Bootstrap workspace one-shot
  (studio)/
    layout.tsx                → StudioLayout shell (AuthProvider)
    dashboard/page.tsx        → Dashboard reel (13 cards + recent activity + calendar)
    ideas/page.tsx            → Ideas CRUD (inbox, score, canal, convert, generate content)
    content/page.tsx          → Content CRUD (versions, statuts, canal, workflow transitions)
    client/page.tsx           → Client Intelligence (profiles, sources, analyse LLM, resultats)
    strategy/page.tsx         → Strategy (angles, formats, hooks, generation d'idees)
    learning/page.tsx         → Learning (sources + processing + insights)
    templates/page.tsx        → Templates CRUD (sections, types, seed defaults)
    knowledge/page.tsx        → Knowledge CRUD (types, tags, source)
    calendar/page.tsx         → Calendar editorial (vue mois, CRUD entries, lien content)
    assets/page.tsx           → Assets library (upload, preview, tags, grille)
    automations/page.tsx
    reports/page.tsx
    settings/page.tsx
providers/auth-provider.tsx   → AuthProvider context + useAuth hook
services/api.ts               → studioApi (get/post/put/patch/delete)
middleware.ts                 → Route protection (cookie check)
```

### Backend (keybuzz-studio-api/)
```
src/
  index.ts                    → Fastify server
  config/env.ts               → Zod-validated env vars
  config/database.ts          → PostgreSQL pool
  common/auth.ts              → Session middleware (cookie → DB lookup)
  common/errors.ts            → AppError + ZodError handler
  modules/
    health/                   → GET /health, GET /ready
    auth/                     → Setup, OTP, session, me, logout
    dashboard/                → GET /dashboard/stats (enrichi: 10 compteurs + calendar activity)
    knowledge/                → CRUD /api/v1/knowledge
    ideas/                    → CRUD /api/v1/ideas
    content/                  → CRUD /api/v1/content + versions + POST transition + assets link
    assets/                   → POST upload + CRUD /api/v1/assets + GET file (public)
    calendar/                 → CRUD /api/v1/calendar (date/channel/status filters)
    learning/                 → POST sources + GET sources + POST process + GET insights
    templates/                → CRUD /api/v1/templates + POST seed
    generation/               → POST /api/v1/content/generate + POST /api/v1/content/generate-and-save
    ai/                       → Studio AI Gateway (providers, prompts, service, routes)
    client/                   → Client Intelligence (profiles, sources, analysis, strategy, idea generation)
    automation/               → GET /api/v1/automations/runs
    reporting/                → GET /api/v1/reports
  routes/index.ts             → Route registration + auth middleware
  db/schema.sql               → 17 tables + 1 join PostgreSQL
  db/migrations/
    001-auth-tables.sql       → Auth tables
    002-knowledge-ideas-content.sql → Knowledge ext + ideas + content ext
    003-assets-calendar-workflow.sql → Assets ext + content_item_assets + calendar ext
    004-learning-templates-generation.sql → Learning sources/insights + content templates
    005-ai-generations.sql                → AI generation tracking
    006-ai-pipeline-tracking.sql           → Pipeline tracking columns (pipeline_id, mode, step, latency)
    007-client-intelligence.sql            → Client Intelligence tables (profiles, sources, analysis, strategies)
    008-quality-engine.sql                  → Quality Engine (prompt_templates, ai_feedback)
    009-feedback-learning.sql                → Feedback Loop & Learning (learning_adjustments, workspace_ai_preferences, ai_feedback enrichi)
```

### Database (26 tables + 1 join)
| Table | But |
|-------|-----|
| workspaces | Espaces de travail multi-tenant |
| users | Utilisateurs Studio |
| memberships | Lien user-workspace + role |
| auth_identities | Identite email/provider |
| email_otp_codes | Codes OTP (hash SHA-256) |
| sessions | Sessions (token hash SHA-256) |
| **ideas** | Inbox idees de contenu (score, canal, tags) |
| content_items | Posts, articles (status, versions, canal, workflow) |
| content_versions | Historique versions contenu |
| content_assets | Medias (original_name, storage_key, provider, tags) |
| **content_item_assets** | Join table content ↔ assets |
| content_calendars | Calendrier editorial (timezone, created_by) |
| **learning_sources** | Sources d'apprentissage brutes (doc, video, json, workflow, url) |
| **learning_insights** | Insights extraits (strategy, tactic, hook, framework) |
| **content_templates** | Templates de contenu reutilisables (sections structurees) |
| **ai_generations** | Tracking des generations IA (provider, model, tokens, cost) |
| **client_profiles** | Profils clients (business, niche, offer, target, channels) |
| **client_sources** | Sources brutes pour analyse client (text, url, doc, json) |
| **client_analysis** | Resultats analyse LLM (ICP, pains, SWOT, positioning, tone, competitors) |
| **client_strategies** | Strategies generees (angles, channels, formats, hooks, frequency) |
| **prompt_templates** | Prompts dynamiques par workspace ou global (system + user template, version) |
| **ai_feedback** | Feedback utilisateur enrichi (up/down/improve, category, improvement_note) |
| **learning_adjustments** | Ajustements appris du feedback (prompt/tone/structure, weight, par workspace) |
| **workspace_ai_preferences** | Preferences IA par workspace (tone, quality avg, counters feedback) |
| publication_targets | Canaux de publication |
| knowledge_documents | Documents reference (type, status, tags, source) |
| automation_runs | Executions de workflows |
| activity_logs | Journal d'audit |
| master_reports | Rapports generes |

## 4. Separation avec les Autres Produits

Studio ne partage RIEN avec keybuzz-client, keybuzz-seller, keybuzz-admin, keybuzz-api, keybuzz-backend.

## 5. DNS / Deploiement

| Env | Frontend | API |
|-----|----------|-----|
| DEV | studio-dev.keybuzz.io | studio-api-dev.keybuzz.io |
| PROD | studio.keybuzz.io | studio-api.keybuzz.io |

### Images Docker actuelles
```
ghcr.io/keybuzzio/keybuzz-studio:v0.8.0-dev      (DEV)
ghcr.io/keybuzzio/keybuzz-studio:v0.8.0-prod     (PROD — build dedie)
ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-dev   (DEV — hotfix insights)
ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-prod  (PROD — re-tag from DEV, hotfix insights)
```
Note : l'image frontend PROD est un rebuild dedie (pas un re-tag) car `NEXT_PUBLIC_*` est baked au build time.
Les images API -dev et -prod ont le meme SHA (promotion pure).

### Owner Studio
| Env | Email | Workspace | Role |
|-----|-------|-----------|------|
| DEV | ludovic@keybuzz.pro | KeyBuzz (slug: keybuzz) | owner |
| PROD | ludovic@keybuzz.pro | KeyBuzz (slug: keybuzz) | owner |

## 6. Decisions Prises

| Decision | Raison |
|----------|--------|
| Next.js 16.0.2 pinne | Metronic v9.3.7 l'utilise ; 16.1 blackliste securite |
| Fastify backend | Aligne avec le pattern API existant KeyBuzz |
| PostgreSQL 17 | Meme engine que le cluster existant |
| Auth email OTP only | Pas de dependance OAuth externe, multi-user ready |
| Table ideas separee | Lifecycle different du contenu, plus propre |
| devCode en DEV meme avec SMTP | Permet test automatise sans acceder a la boite mail |
| Owner via bootstrap endpoint | Pas de SQL sauvage, pas de hardcode dans le code |
| Frontend PROD = build dedie | NEXT_PUBLIC_ est baked au build time, re-tag impossible |
| Workflow editorial valide | Transitions controlees cote API, pas de bypass frontend |
| Assets stockage local | MVP local /data/assets, S3/MinIO prevu pour une phase ulterieure |
| @fastify/multipart pour upload | Limite 10MB par fichier |
| Processing heuristique | Extraction insights par mots-cles, pas d'IA pour le MVP |
| Templates structure par sections | Chaque section a un name/label/description/maxLength |
| Generation template-filling | Assemblage idee + insights + template, IA optionnelle |
| Studio AI autonome | Moteur IA separe du moteur SAV KeyBuzz |
| Provider abstraction | Interface LLMProvider (OpenAI, Anthropic, Gemini), fallback heuristique |
| Vault paths LLM dedies | secret/keybuzz/{env}/studio-llm (API key, model, config) |
| Quality score heuristique | Score 0-100 sur structure, richesse, unicite, hook |
| Variantes multiples | Jusqu'a 3 variantes par generation |
| Pipeline multi-modeles | 3 modes (single/standard/premium), roles par etape (draft/improve/final) |
| GeminiProvider | Google AI API via generativelanguage.googleapis.com, ready for Vertex |
| Prompts specialises | Draft=structure, Improve=densify, Final=polish — version v2 |
| Temperature adaptative | Final step utilise temperature reduite pour coherence |
| Client Intelligence Engine | Analyse client LLM → strategie → generation idees automatique |
| LLM requis pour analyse | Pas d'heuristique brute, toujours LLM pour l'analyse client |
| Provider auto-detection | Si LLM_PROVIDER=none mais GEMINI_API_KEY present, utilise Gemini |
| Pipeline client | client_profile → analysis → strategy → ideas (toujours dans cet ordre) |
| Prompts dynamiques DB | prompt_templates table (workspace override → global fallback) |
| Anti-genericite | Detection 30+ patterns FR/EN, penalite absence chiffres/exemples |
| Re-generation auto | Si score < 40 ou generic, retry avec contraintes renforcees |
| Client enrichment auto | Injection automatique client_profile + analysis dans chaque generation |
| Prompt v3 francais | Prompts system/user en francais par defaut, anti-generique integre |
| Feedback utilisateur | Table ai_feedback (up/down/improve) avec UI thumbs |
| Quality score v2 | Multi-criteres (completeness, specificity, concreteness, uniqueness, hook) |
| Learning Engine | Feedback → categorisation → learning_adjustments → prompt injection automatique |
| Workspace preferences | Preferences IA par workspace (avg quality, counters, trend detection) |
| Personalisation par workspace | Chaque workspace accumule son propre modele comportemental |
| AI Insights dashboard | Section dashboard dediee avec KPIs, trends, issues, bar chart |

## 7. Risques Ouverts

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Pas de RBAC fin | Tous les membres ont le meme acces | Prevu pour une phase ulterieure |
| Email service dependant du relay SMTP | Si relay down, pas d'OTP | Monitoring SMTP, devCode en DEV |
| Pas de backup scheduling | Perte de contenu possible | Prevu phase backup |
| Assets stockage local (emptyDir) | Fichiers perdus si pod restart | PVC ou S3 prevu phase suivante |
| Pas de drag-and-drop calendar | UX basique | Prevu phase UX polish |

## 8. Prochaines Phases

### PH-STUDIO-08A — Benchmark + Image Generation
- Benchmark reel multi-provider (comparaison single/standard/premium + client intelligence)
- Image generation (DALL-E, Midjourney-ready)
- Fine-tuning prompts sur cas reels

### PH-STUDIO-09 — Automations
- Integration n8n
- Workflows de publication
- Event triggers

### PH-STUDIO-10 — Publication
- Publication LinkedIn/Reddit reelle
- Scheduling cron
- Publication targets

## 9. Glossaire

| Terme | Definition |
|-------|-----------|
| Studio | KeyBuzz Studio (studio.keybuzz.io) — Marketing OS |
| Workspace | Espace de travail multi-tenant dans Studio |
| Content Item | Unite de contenu (post, article, thread, script video) |
| Idea | Idee de contenu avec score et canal cible |
| Knowledge Document | Document reference pour l'IA et la strategie |
| Publication Target | Canal de publication (LinkedIn, Reddit, blog) |
| Automation Run | Execution d'un workflow n8n ou agent IA |
| MASTER REPORT | Ce document — source de verite unique |
| CE | Cursor Executor — role de l'agent Cursor |
