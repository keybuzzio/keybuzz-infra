# Vision projet KeyBuzz

> Derniere mise a jour : 2026-04-21
> Role : synthese durable pour comprendre KeyBuzz avant d'agir.

## Definition courte

KeyBuzz est un SaaS B2B de support client et d'automatisation SAV pour vendeurs e-commerce. Le coeur produit n'est pas un chatbot generique : c'est un moteur de support e-commerce qui relie messages, commandes, marketplace, politique SAV, IA controlee, playbooks, facturation et garde-fous humains.

Positionnement fonctionnel :

- centraliser les conversations client multi-canal;
- enrichir chaque conversation avec commande, tracking, retour, fournisseur, historique et contexte tenant;
- proposer ou executer des reponses IA sous controle;
- proteger le vendeur contre les remboursements/refus/actions automatiques mal calibrees;
- rendre mesurable l'usage IA via KBActions et billing Stripe.

## Produit SaaS principal

### Client SaaS

Chemin local principal : `C:\DEV\KeyBuzz\V3`

Stack : Next.js 14, React 18, TypeScript, NextAuth, Tailwind.

Surfaces principales :

- `/inbox` : centre operationnel SAV, tripane, conversations, messages, commande, contexte, suggestions IA, escalade, assignation.
- `/orders` : cockpit commandes, details commande, import/sync, tracking.
- `/channels` : Amazon, Octopia, Shopify et canaux.
- `/playbooks` : playbooks IA API-backed, simulation, suggestions.
- `/settings` : tenant, signature, IA, agents, espaces, billing.
- `/billing` : plans, KBActions, canaux, historique, options.
- `/ai-dashboard` et `/ai-journal` : supervision et journal IA.
- `/register`, `/start`, `/onboarding` : acquisition et activation.

Le dossier `app/api/*` contient de nombreuses routes BFF Next.js qui proxient ou encadrent les appels vers l'API SaaS. Beaucoup de bugs historiques viennent d'un BFF incomplet ou d'un mauvais forwarding `X-Tenant-Id`.

### API SaaS

Source historique : repo `keybuzz-api` sur bastion/GitHub, mais des morceaux existent dans `V3\backend-src`, `V3\src`, rapports et images deploiement.

Stack documentee : Fastify, Node.js, TypeScript, Postgres.

Domaines :

- conversations/messages;
- inbound/outbound;
- autopilot;
- IA engines;
- orders/tracking;
- billing/KBActions/Stripe;
- tenant context;
- agents/RBAC/escalation;
- connectors Amazon/Octopia/Shopify;
- metrics/admin internal endpoints.

### Admin v2

Chemins locaux :

- `C:\DEV\KeyBuzz\keybuzz-admin-v2`
- docs `PH-ADMIN-*` dans `keybuzz-infra/docs`

Stack : Next.js 14, Metronic-like admin, NextAuth, pg.

Role :

- cockpit tenants;
- users/admin users;
- billing usage/costs;
- queues/incidents/audit;
- feature flags;
- AI control center;
- system health;
- metrics internes.

Note importante : rapport `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md` documente que PROD doit appeler le service K8s API via le port service 80, pas `:3001`.

### Studio / Growth

Chemins :

- `C:\DEV\KeyBuzz\V3\keybuzz-studio`
- `C:\DEV\KeyBuzz\V3\keybuzz-studio-api`

Stack :

- Studio front : Next.js 16, React 19, Tailwind 4, React Query, tables, DnD, motion.
- Studio API : Fastify 5, TypeScript, pg, nodemailer.

Role d'apres docs `STUDIO-*` et rapports `PH-STUDIO-*` :

- idees, assets, calendrier, workflow;
- generation/learning/quality engine;
- gateway IA texte;
- client intelligence;
- init KeyBuzz Growth.

### Seller API

Chemin : `C:\DEV\KeyBuzz\V3\seller-api`

Stack : FastAPI, Python 3.12, SQLAlchemy async, Alembic, Redis, RabbitMQ, boto3, zeep.

Role : backend seller/multi-tenant event-driven, probablement connecteurs/flux e-commerce separes.

## Infra

Sources :

- `C:\DEV\KeyBuzz\V3\keybuzz-infra`
- `C:\DEV\KeyBuzz\V3\Infra`
- `C:\DEV\KeyBuzz\V3\k8s`
- `C:\DEV\KeyBuzz\V3\ansible`

Architecture documentee :

- Kubernetes kubeadm HA, pas K3s pour l'etat moderne.
- GitOps avec manifests `k8s/*` et ArgoCD.
- Postgres HA/Patroni, acces applicatif via HAProxy `10.0.0.10:5432`.
- Redis, RabbitMQ, MinIO, Vault/External Secrets selon historique.
- Distinction stricte DEV/PROD.

Attention : certains anciens dossiers/scripts parlent de K3s, Galera, ProxySQL, modules d'installation V2. Ils sont utiles pour l'historique, mais la memoire actuelle doit privilegier les rapports recents et les sources de verite.

## Donnees et DB

Source cle : `DB-ARCHITECTURE-CONTRACT.md`

Regle majeure : architecture dual-DB.

- Product DB : `keybuzz` / `keybuzz_prod`
  - source principale pour API, conversations, messages, orders, tenants, billing, IA, admin, tenant_channels, etc.
- Backend Prisma DB : `keybuzz_backend` / `keybuzz_backend_prod`
  - tables Prisma exclusives, notamment `MarketplaceConnection`, `OAuthState`, certains modeles backend.

Pieges :

- Ne pas deplacer ou supprimer les tables legacy/dupliquees sans phase explicite.
- Amazon OAuth peut impliquer les deux bases.
- Les tables PascalCase et snake_case peuvent coexister.
- `ExternalMessage` a ete unifie vers product DB selon PH-TD-05.

## IA et Autopilot

KeyBuzz contient une longue serie de moteurs IA SAV : policy, history, decision tree, customer risk, marketplace intelligence, evidence, escalation, memory, governance, action dispatcher, controlled execution, etc. Les rapports PH42-PH117 decrivent cette progression.

Etat produit moderne :

- suggestions IA manuelles disponibles PRO+;
- playbooks API-backed;
- supervision/journal IA;
- KBActions avec wallet/ledger/billing;
- Autopilot avec settings, safe mode, drafts, consume, guardrails, false promise detection;
- execution reelle encadree par plan, settings, confidence, safe_mode et garde-fous.

Etat Autopilot actuel au 2026-04-21 :

- Handoff escalation fixed DEV + PROD (`v3.5.91` API).
- Client/BFF/API/consume presents.
- Blocage restant documente : `ecomlg-001` est en plan PRO, et `ai-mode-engine.ts` limite PRO a `maxMode='suggestion'`, donc l'autopilot ne genere pas de draft pour ce tenant.
- Un tenant AUTOPILOT (`switaa-sasu-mnc1x4eq` en DEV) prouve que le pipeline fonctionne.

## Plans et billing

Source cle : `FEATURE_TRUTH_MATRIX_V2.md`

Plans modernes :

- STARTER : gate fort, 1 canal, pas d'autopilot.
- PRO : suggestions IA, playbooks, journal IA, 1000 KBActions/mois, 3 canaux, mais pas mode autonome.
- AUTOPILOT : mode autonome/supervise avance, 2000 KBActions/mois, 5 canaux, features premium.

Pieges :

- Incoherences historiques de casse `pro` vs `PRO`.
- `ecomlg-001` est tenant pilote et billing exempt/internal_admin.
- Trial AUTOPILOT peut deverrouiller des features, ce qui rend certains tests addon non concluants.
- Ne jamais exposer les couts LLM au client, uniquement les KBActions.

## Connecteurs

Amazon :

- SP-API, OAuth, inbound address, orders sync/backfill, outbound messaging, threading.
- Les rapports PH15/PH34/PH145/PH150 sont centraux.
- Piege connu : payload Amazon vide `{}` truthy, verifier `OrderStatus` et contenu reel.

Octopia :

- Connect, import, sync, adapter readonly/outbound selon PH30/PH35.

Shopify :

- Integration plus recente, plusieurs rapports PH-SHOPIFY.
- Certaines phases ont ete sources de reconstruction Git/client.

Tracking marketing :

- Website `keybuzz.pro` a GA4/Meta/UTM/cross-domain.
- SaaS `client.keybuzz.io` avait un trou noir attribution selon `PH-TRACKING-SAAS-ARCHITECTURE-AND-PLAN-01`.
- Suite de phases PH-T1..PH-T8 ajoute capture attribution, Addingwell/SGTM, Google Ads, TikTok, LinkedIn, metrics trial/paid, admin metrics.

## Marketing, contenu et Studio

Le dossier `V3\marketing` contient 313 documents PDF/DOCX utiles comme corpus d'alimentation Studio, pas comme source de verite technique.

Clarification importante de Ludovic : tout ce qui est Asphalte/Smoozii sert a alimenter le SaaS Studio. Ce n'est pas un bruit documentaire a ignorer. Le corpus doit nourrir Knowledge, Learning, Templates, Strategy, Client Intelligence, Content Generation, Quality Engine et les prompts/briefs de production.

Sous-ensembles :

- Brand book et plateforme Smoozii.
- SWOT, manifeste, archetype de marque.
- Automatisations n8n et prompts d'audit funnel.
- 202 PDFs d'emails Asphalte dupliques dans deux dossiers, probablement corpus d'inspiration copywriting.
- Content global, landing pages, ads, lead magnets, formulaires.
- Brief Media Buyer KeyBuzz : promesse "Automatisez votre SAV Amazon avec l'IA", "repondez plus vite, remboursez moins, gardez le controle".

Usage correct :

- inspirer copywriting, landing, acquisition, media buying, ton;
- structurer les modules Studio : ideation, calendrier, templates, learning, qualite, strategie;
- adapter les patterns Asphalte/Smoozii a KeyBuzz et aux clients Studio, sans copier aveuglement;
- ne jamais les utiliser pour trancher une question d'architecture ou d'etat runtime.

## Etat de verite Git/runtime

PH152 a etabli une crise de source-of-truth :

- des images DEV/PROD contenaient du code non committe;
- le bastion avait des fichiers modifies/non trackes;
- un reset/clean a supprime du code fantome;
- le processus impose maintenant build depuis Git clean.

Regles modernes :

- un seul repo/branche/commit documente;
- repo clean obligatoire avant build;
- pas de SCP source vers bastion;
- pas de build depuis runtime/pod/dist;
- rapport obligatoire avec image avant/apres, digest, rollback, validation reelle.

## Mental model pour agir

Avant toute phase :

1. Identifier le domaine : client, API, admin, infra, marketing, Studio, seller.
2. Lire la derniere phase du domaine.
3. Verifier si la conversation se termine sur un prompt deja execute ensuite.
4. Verifier les images DEV/PROD et le rapport le plus recent.
5. Faire un patch minimal.
6. DEV only sauf validation explicite.
7. Produire rapport et rollback.
