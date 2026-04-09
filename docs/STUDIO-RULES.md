# KeyBuzz Studio — Rules

> Last update: 2026-04-07
> Phase: PH-STUDIO-08

---

## Product Rules

1. **Studio is autonomous** — it is a standalone SaaS product, fully separated from client.keybuzz.io, seller.keybuzz.io, and all other KeyBuzz products
2. **No runtime dependencies** — Studio does NOT import from, link to, or depend on any other KeyBuzz frontend or backend at runtime
3. **Explicit connectors only** — any future integration with other KeyBuzz systems (orders, inbox, billing) must be implemented as explicit API connectors, database views, or event consumers — never as direct code imports
4. **Own identity** — Studio has its own database, users table, workspaces, authentication, and secrets
5. **Metronic UI kit** — Metronic v9.3.7 is used as the UI component library, not as an application framework

## Technical Rules

1. **GitOps** — all deployments via ArgoCD sync from keybuzz-infra Git repo
2. **Zero hardcode** — all configuration via environment variables or Vault/ExternalSecrets
3. **Zero cleartext secrets** — secrets never committed to Git, always via K8s secrets or Vault
4. **Next.js 16.0.2 pinned** — do NOT upgrade to 16.1+ (known security vulnerability)
5. **DEV before PROD** — always deploy, validate, and document in DEV before any PROD promotion
6. **Rollback** — use rollback-service.sh exclusively, never kubectl set image
7. **Build from Git** — use build-from-git.sh / build-api-from-git.sh, never direct docker build on bastion
8. **Tag format** — `v<major>.<minor>.<patch>-<feature>-<env>` (e.g., v1.0.0-foundation-dev)
9. **Documentation mandatory** — every phase must produce a phase report and update the MASTER REPORT

## Secret Hygiene (PH-STUDIO-02B)

1. **Aucun secret, token, credential, root token, mot de passe ou URL credentialisee** ne doit apparaitre dans les rapports, logs copies, captures ou documents commites
2. Toujours masquer ou tronquer les valeurs sensibles dans les rapports (ex: `***redacted***`, `hvs.****`)
3. Les DATABASE_URL documentees doivent masquer le password : `postgresql://user:***@host:port/db`
4. Les tokens Vault ne doivent JAMAIS etre ecrits dans les fichiers commites au repo
5. Les credentials Studio sont EXCLUSIVEMENT dans :
   - Vault : `secret/keybuzz/dev/studio-postgres`
   - K8s secret : `keybuzz-studio-api-db` (namespace `keybuzz-studio-api-dev`)
6. Avant chaque commit, verifier avec `grep -r 'hvs\.\|PGPASSWORD=\|password.*=' docs/` qu'aucun secret n'est expose

## Auth Rules (PH-STUDIO-04A)

1. **Email OTP only** — no Google, Microsoft, or password auth for now
2. **No hardcoded users** — no email, userId, or workspaceId in code
3. **Bootstrap owner one-shot** — requires BOOTSTRAP_SECRET from Vault; route returns 409 after first owner
4. **Session token hashed** (SHA-256) — raw token NEVER stored in DB
5. **OTP code hashed** (SHA-256) — raw code NEVER logged in production
6. **Cookie httpOnly** — `kb_studio_session`, Domain=.keybuzz.io, Secure in PROD, SameSite=Lax
7. **Setup route auto-disabled** — POST /auth/setup returns 409 once an owner exists
8. **Rate limiting** — max 5 OTP requests per email per 15 minutes
9. **DEV mode** — devCode returned in DEV even when SMTP is configured (for automated testing)
10. **Future OAuth ready** — auth_identities table supports multiple providers

## Core Product Rules (PH-STUDIO-04B)

1. **No fake seed data** — aucune donnee d'exemple trompeuse dans le produit
2. **Modules metier toujours workspace-aware** — toutes les requetes filtrent par workspace_id
3. **Knowledge / Ideas / Content sont la base du produit** — pas des modules secondaires
4. **Owner via bootstrap data only** — jamais hardcode dans le code
5. **Ideas separees du content** — lifecycle different, table dediee
6. **Content versioning** — chaque contenu a un historique de versions
7. **"Convert idea to content"** — action explicite qui cree un content et marque l'idee comme "converted"
8. **Tous les endpoints protegees** — auth middleware preHandler sur toutes les routes metier

## Build & Deploy Rules (PH-STUDIO-04C)

1. **NEXT_PUBLIC_* is baked at build time** — inlined into JS by Next.js at `docker build`, NOT read at runtime
2. **Frontend PROD = dedicated build** — NEVER re-tag a DEV frontend image as PROD; each env needs its own build with correct `--build-arg NEXT_PUBLIC_STUDIO_API_URL`
3. **API images can be re-tagged** — backend env vars are read at runtime, promotion par `docker tag` OK
4. **NEXT_PUBLIC_STUDIO_API_URL** — DEV: `https://studio-api-dev.keybuzz.io`, PROD: `https://studio-api.keybuzz.io`

## Editorial Workflow Rules (PH-STUDIO-05)

1. **Workflow states**: draft → review → approved → scheduled → published → archived
2. **Transitions validated server-side** — invalid transitions return HTTP 400
3. **Activity logging** — all status transitions logged to `activity_logs`
4. **Assets stored locally** in `/data/assets/{workspace_id}/` (MVP, S3/MinIO planned)
5. **Asset file serving** — public route with UUID-based security
6. **Upload limit** — 10MB per file via `@fastify/multipart`
7. **Content-Asset linking** — many-to-many via `content_item_assets` join table
8. **Calendar** — link to content items, filter by date range/channel/status
9. **Idea → Content → Assets → Calendar** — full editorial pipeline

## Learning & Generation Rules (PH-STUDIO-06)

1. **Learning structure obligatoire** — toute source doit etre traitee (processed) avant que ses insights soient utilisables
2. **Content base sur knowledge uniquement** — pas de generation "vide" sans source ou idee
3. **Templates par sections** — chaque template definit des sections avec name/label/description/maxLength
4. **Processing heuristique** — extraction par mots-cles (strategy, tactic, hook, framework), pas d'IA LLM pour le MVP
5. **Generation template-filling** — assemblage idee + insights pertinents + structure template
6. **Insights scorees par pertinence** — matching mots-cles et tags entre idee et insights
7. **Tone et length parametrables** — professional/casual/authoritative/friendly et short/medium/long
8. **Templates seedables** — POST /templates/seed charge 3 templates par defaut (LinkedIn, Reddit, Thread) si aucun n'existe
9. **generate-and-save atomique** — genere ET sauvegarde en content_items + content_versions en une seule requete
10. **Sidebar Learning + Templates** — sous la section "Intelligence" du menu

## Studio AI Rules (PH-STUDIO-07A)

1. **Studio AI separe du moteur SAV** — aucun import runtime depuis le moteur LLM KeyBuzz support
2. **Texte only pour l'instant** — image/video generation hors scope jusqu'a PH-STUDIO-07B
3. **Jamais de generation sans knowledge** — toujours une idee + template + insights (meme si insights vides, le refus est propre)
4. **Frontend PROD = build dedie** — rappel : NEXT_PUBLIC_* est baked au build time
5. **Provider abstraction** — OpenAI et Anthropic supportes, extensible via interface LLMProvider
6. **Fallback heuristique** — si LLM non configure ou en erreur, generation par template-filling
7. **Vault paths LLM** — secret/keybuzz/dev/studio-llm et secret/keybuzz/prod/studio-llm
8. **Aucune cle API en clair** — jamais dans Git, manifests, ou docs
9. **Quality score informatif** — score 0-100, pas bloquant mais visible dans l'UI
10. **Tracabilite** — chaque generation enregistree dans ai_generations (provider, model, tokens, cost)
11. **Variantes** — jusqu'a 3 variantes par generation, selectionnable dans l'UI
12. **Prompts versiones** — prompt_version tracee dans ai_generations pour audit

## Multi-Model Pipeline Rules (PH-STUDIO-07A.1)

1. **3 pipeline modes** — single (1 pass), standard (draft→final), premium (draft→improve→final)
2. **Roles par etape** — draft=structure+completeness, improve=densify+strengthen, final=polish+humanize
3. **Ne jamais faire 3 passes redondantes** — chaque step a un role distinct, pas de repetition
4. **Texte only toujours** — image/video generation hors scope
5. **Provider par step** — chaque etape peut utiliser un provider/modele different via DRAFT_PROVIDER/IMPROVE_PROVIDER/FINAL_PROVIDER
6. **Gemini supported** — Google AI API (generativelanguage.googleapis.com), ready for Vertex migration
7. **Temperature adaptative** — step final utilise temperature reduite (-0.2) pour coherence et lisibilite
8. **Pipeline tracking** — chaque step enregistre separement dans ai_generations (pipeline_id commun, step, step_order, latency_ms)
9. **Fallback pipeline** — si un step echoue, fallback heuristique global avec is_fallback=true
10. **Prompt version v2** — prompts specialises par step (vs v1 monolithique), tracked dans ai_generations
11. **Cost aggregation** — cout total = somme des couts de chaque step
12. **Benchmark script** — 5 cas de test comparant heuristic/single/standard/premium

## Client Intelligence Rules (PH-STUDIO-07C)

1. **Toute generation doit partir d'un client_profile** — jamais de contenu sans profil client
2. **Jamais de contenu sans strategie** — le flux est : profile → analysis → strategy → ideas
3. **Toujours passer par analysis → strategy → ideas** — pas de raccourci
4. **LLM requis pour analyse** — pas d'heuristique brute, l'analyse client necessite un provider LLM actif
5. **Provider auto-detection** — si LLM_PROVIDER=none mais GEMINI_API_KEY present, utilise Gemini automatiquement
6. **Analyse stockee en DB** — chaque analyse est persistee dans client_analysis avec provider/model traces
7. **Strategie liee a une analyse** — client_strategies.analysis_id reference obligatoire
8. **Ideas generees automatiquement** — POST /ideas/generate-from-strategy cree des ideas dans la table ideas (source_type='strategy')
9. **Multi-workspace** — toutes les tables client_ filtrent par workspace_id
10. **JSON structured output** — les champs analysis (icp, pains, swot, positioning, tone, competitors) sont JSONB

## Quality Engine Rules (PH-STUDIO-07D)

1. **Aucun contenu generique autorise** — detection automatique phrases generiques (30+ patterns FR/EN)
2. **Toujours base sur client + strategie** — injection automatique client_profile + analysis dans chaque generation
3. **Prompts parametrables** — table prompt_templates, workspace override → fallback global
4. **Systeme multi-tenant obligatoire** — aucun biais "KeyBuzz" dans les prompts, tout vient du client_profile
5. **Re-generation automatique** — si score < 40 ou contenu generique, retry avec contraintes renforcees
6. **Quality score v2** — multi-criteres (completeness, specificity, concreteness, uniqueness, hook), label weak/average/strong/excellent
7. **Prompt version v3** — prompts system/user en francais par defaut, anti-generique integre
8. **Feedback utilisateur** — table ai_feedback (up/down/improve), UI thumbs up/down dans le dialog generation
9. **Idees enrichies** — chaque idee doit contenir probleme reel, hook brut, type (story/data/contrarian/how-to/case-study)
10. **Aucune generation "vide"** — client context charge automatiquement si profil existant

## Feedback Loop & Learning Rules (PH-STUDIO-08)

1. **Feedback = source principale d'apprentissage** — chaque feedback utilisateur est categorise et traite automatiquement
2. **Chaque contenu doit pouvoir etre ameliore** — UI thumbs up/down + "Improve" avec champ texte
3. **Systeme adaptatif par workspace** — chaque workspace accumule ses propres learning_adjustments et preferences
4. **Learning adjustments injectes dans les prompts** — les contraintes apprises sont ajoutees automatiquement aux system prompts
5. **Poids incrementaux** — si un meme probleme revient (ex: "generic"), le poids de l'ajustement augmente (max 5.0)
6. **Categorisation automatique** — 7 categories (generic, too_long, too_short, unclear, not_relevant, wrong_tone, good)
7. **Quality trend** — detection automatique de la tendance (improving/stable/declining) sur les 20 dernieres generations
8. **Aucune fuite entre workspaces** — learning_adjustments et workspace_ai_preferences sont strictement workspace-scoped
9. **Feedback jamais expose publiquement** — toutes les routes feedback/insights/adjustments sont auth-protegees
10. **Dashboard AI Intelligence** — KPIs (generations, avg quality, feedback breakdown, top issues, trend)

## Agent Rules

1. CE (Cursor Executor) executes, does not decide on product scope
2. Every phase MUST update STUDIO-MASTER-REPORT.md
3. Every new prompt SHOULD enrich .cursor/rules/studio-rules.mdc if relevant
4. Any blocker must be documented in the phase report with clear remediation path
5. Zero manual action should be asked of Ludovic unless absolutely unavoidable
6. **Secret hygiene obligatoire** — voir section ci-dessus
