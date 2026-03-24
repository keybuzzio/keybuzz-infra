# Récapitulatif des Phases KeyBuzz

> Ce document recense les phases traitées et documentées dans le dossier `keybuzz-infra/docs`.
> **Contenu** : phases `PH{numéro}` (PH0, PH4, PH7, PH10…) et phases `PH-` (PH-INFRA, PH-BILLING…).
> **Exclusion** : les phases PH-ADMIN ne sont pas listées ici.

---

# Partie 1 — Phases PH{numéro}

## PH0, PH0.1, PH4, PH7, PH10

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH0-AUTH-LOGIN-REDIRECT-LOOP-FIX-01** | **Problème** : Boucle infinie après login OTP (affichage "redirecting" sans fin). **Cause** : Cookie `__Host-next-auth.csrf-token` créé avec `Domain=.keybuzz.io` — invalide selon RFC 6265bis (les cookies __Host- ne doivent pas avoir d’attribut Domain). Le navigateur rejetait le cookie → pas de session → AuthGuard 401 → boucle. **Fix** : Suppression attribut Domain pour les cookies __Host-. |
| **PH0.1-SPACE-CREATE-UI-01** | **Objectif** : Création Espace self-serve via l’UI. **Flux** : POST /tenant-context/create → création en DB produit (keybuzz) → sync marketplace via endpoint existant → utilisateur devient owner → espace devient courant → redirection /dashboard. Endpoints implémentés, versions 0.2.71 client, 0.1.96 API. |
| **PH4-03-linear-synthesis** | **EPIC Linear** : Intégration Redis HA avec HAProxy + lb-haproxy. **Objectif** : Un endpoint unique (`redis://:PASSWORD@10.0.0.10:6379/0`) pour toutes les apps KeyBuzz, sans logique Sentinel côté application. Cluster Redis 1 master + 2 replicas + Sentinel derrière HAProxy (haproxy-01/02). Dépendances : PH3 (Volumes XFS), PH4-01 (Redis HA). |
| **PH7-SEC-ESO-SECRETS-01** | **Objectif** : Centraliser les secrets via Vault → External Secrets Operator (ESO) → K8s. **Actions** : Migration stripe, auth, ses vers ExternalSecrets ; suppression des 3 secrets manuels ; ClusterSecretStore vault-backend ; pods API + Client fonctionnels. Vault initialized/unsealed, ESO 3 pods Running. |
| **PH7-SEC-VAULT-STORAGE-01** | Stockage sécurisé des credentials dans Vault — migration des secrets sensibles hors fichiers statiques et variables d’environnement. |
| **PH10-UI-DEPLOY-01** | **Objectif** : Manifests Kubernetes et applications ArgoCD pour KeyBuzz Admin. **Livrables** : deployment.yaml, service.yaml, kustomization.yaml pour dev et prod ; apps ArgoCD keybuzz-admin-dev et keybuzz-admin. Arborescence k8s/keybuzz-admin-* et argocd/apps/. |

---

## PH11 (Product, SRE, Mail)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH11-03-ESO-DATAFROM-FIX** | **Problème** : ExternalSecrets ne synchronisaient pas. **Fix** : correction `dataFrom` pour référencer secrets sources. Pods SecretSynced. |
| **PH11-CLIENT-UI-12** | Évolution interface client — composants, layout, navigation. Version alignée. |
| **PH11-MAIL-REALITY-CHECK-01** | **Audit** : chaîne mail (MX, DKIM, SPF, Postfix, mail-core). Constate écarts config vs réalité. |
| **PH11-MAIL-SES-AUDIT-01** | **Audit** : Amazon SES — domaine vérifié, sandbox vs prod, quotas, bounces. |
| **PH11-PRODUCT-01A-AI-CORE** | Fondations IA produit — pipeline suggestions, classification, premier moteur décisionnel. |
| **PH11-PRODUCT-01B/01C/01D** | Extensions IA — scénarios SAV, templates, débit KBActions, journalisation. |
| **PH11-PRODUCT-02-CONVERSATION-HARDENING** | **Sécurisation** : validation tenantId, isolation données, guards. Résilience conversation. |
| **PH11-PRODUCT-03-MESSAGING-UNIFICATION** | Unification — modèle commun inbound/outbound, normalisation formats, source de vérité unique. |
| **PH11-PRODUCT-03B/03C/03D** | Fix notes persistence, message source. |
| **PH11-PRODUCT-BADGE-IA-01/02** | Badge IA — indicateur suggestions, statut analyse, feedback dans l’UI. |
| **PH11-SES-01** | **Configuration** : Amazon SES — domaine, identités, credentials, envoi transactionnel. |
| **PH11-SRE-04** | **Observabilité** : Prometheus + Grafana, dashboards K8s, métriques pods. |
| **PH11-SRE-05** | **DNS Matrix** — doc enregistrements DNS par env (client, API, admin, inbound). |
| **PH11-SRE-06** | **Runbook** DNS/TLS — renewal Let's Encrypt, vérif certificats, troubleshooting. |
| **PH11-SRE-07** | **Alerting** : Alertmanager, routes, seuils (CPU, mémoire, erreurs). |
| **PH11-SRE-08** | **Watchdog** — alerte si image/tag incohérent entre envs, drift détecté. |
| **PH11-VERSION-01** | Gestion versions — conventions tags, changelog, alignement API/Client/Backend. |

---

## PH12 à PH19

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH12-STRIPE-02** | **Intégration Stripe** : produits, prix, webhooks, checkout, subscription lifecycle. Tables billing, sync état paiement. |
| **PH13-AUTH-OAUTH** | **OAuth** Google et Microsoft — connexion existants + inscription nouveaux. NextAuth providers, callback /register, détection session OAuth. |
| **PH13-TENANT-CONTEXT-01/02** | **Contexte tenant** — sélection espace, persistance localStorage/session, propagation tenantId dans appels API. |
| **PH14-TENANT-LIFECYCLE-01** | **Cycle de vie** — création, suspension, réactivation tenant. Transitions statut, cleanup ressources. |
| **PH15-AMAZON-BACKFILL-ORDERS** | Backfill commandes Amazon — import historique depuis SP-API, workers, progression, idempotence. |
| **PH15-AMAZON-COMMISSION-RATES-API** | API taux commission — récupération frais marketplace Amazon selon catégorie/country. |
| **PH15-AMAZON-CREDENTIALS-VAULT-REPAIR** | **Réparation** : credentials Amazon corrompus ou manquants dans Vault. Réinjection, test connect. |
| **PH15-AMAZON-DB-FOUNDATION** | **Fondation DB** : tables orders, order_items, channels Amazon. Schéma Prisma, migrations. |
| **PH15-AMAZON-DISCONNECT-UX** | UX déconnexion — bouton retirer canal, confirmation, nettoyage tokens, sync channels. |
| **PH15-AMAZON-INBOUND-ADDRESS** | **Adresse inbound** — format canonique `amazon.{tenant}.{country}.{token}@inbound.keybuzz.io`, génération, persistance. |
| **PH15-AMAZON-INBOUND-VALIDATION-UX** | UX validation — affichage adresse à configurer dans Seller Central, statut vérification MX. |
| **PH15-AMAZON-OAUTH-*** | OAuth callback fix, redirect URL, debug flow LWA. Token refresh, scope messaging. |
| **PH15-AMAZON-ORDERS-SYNC** | Sync commandes — workers périodiques, SP-API orders v0, mapping DB, delta sync. |
| **PH15-AMAZON-OUTBOUND-*** | Delivery outbound — SPAPI Messaging API, fallback SMTP, threading, body encoding. |
| **PH15-AMAZON-THREADING-ENCODING** | **Encodage** threading — Subject References, format MIME conforme Amazon. Évite duplication threads. |
| **PH15-AMAZON-WIZARD-*** | Wizard connect Amazon — rewiring étapes, UI apply, validation OAuth, erreurs utilisateur. |
| **PH15-BACKEND-*** | Backend : fix auth, déploiement K8s, correctifs Prisma (migrations, schema). |
| **PH15-CHANNELS-PAGE** | **Page Channels** — liste canaux connectés, statut, actions connect/disconnect. Intégration billing addons. |
| **PH15-INBOUND-*** | Hardening mail gateway, normalisation messages (encoding, headers), routage vers conversation. |
| **PH15-MAIL-OPENDKIM-SETUP** | Setup OpenDKIM — clés DNS, configuration Postfix, signatures emails sortants. |
| **PH15-ONBOARDING-WIZARD-AMAZON** | Wizard onboarding — parcours premier canal Amazon, connexion OAuth, validation inbound. |
| **PH15-ORDERS-*** | Orders : détail réel (API), swap UI données live, recherche, filtres. |
| **PH15-TENANT-SYNC** | Sync tenant — propagation données marketplace, refresh channels, cohérence multi-env. |
| **PH15-TRACKING-*** | Tracking : audit provenance, données réelles transporteur, multi-fulfillment (FBA/FBM), rapports. |
| **PH15.2-AMAZON-ORDERS-BACKFILL-365D** | Backfill 365 jours — import complet historique commandes. Workers, progress UI, batch. |
| **PH16-API-CONNECTION-RESTORE** | Restauration connexion API — endpoints retrouvés, healthcheck, réconciliation état. |
| **PH16-SPACE-CONTEXT-RESTORE** | Restauration contexte Space — sélection espace, sync DB, affichage correct après incident. |
| **PH16.1-SPACE-SYNC-ECOMLG** | Sync Space ecomlg — alignement tenant ecomlg-001, données marketplace, channels. |
| **PH17-DB-ENDPOINT-STABLE** | **Stabilité DB** — PGHOST via HAProxy/LB, failover Patroni, secret correct. Fix régression endpoint. |
| **PH17.1-API-ASSIST-RESTORE** | Restauration API /ai/assist — pipeline IA, endpoints, dépendances. |
| **PH17.2-TLS-STRICT** | TLS strict — désactivation TLS 1.0/1.1, vérification certificats. |
| **PH18-COLLAB-INVITES** | **Invitations collaborateurs** — envoi invite, lien activation, rôle (viewer, agent, admin). Table tenant_users. |
| **PH18-INVITES-EMAIL-DELIVERY** | Livraison emails — templates invite, SES, tracking delivery, bounce handling. |
| **PH19-MESSAGING-PRO** | **Messaging Pro** — plan messaging avancé, quotas, fonctionnalités étendues. |
| **PH19-RBAC-FOCUS** | **RBAC** — rôles (super_admin, ops_admin, viewer), permissions, gates côté UI et API. |

---

## PH24 à PH37

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH24.3-CHANNELS-POLISH** | Polish page Channels — UX, états vides, feedback, cohérence visuelle. |
| **PH24.4/24.4B** | Order panel — import on-demand, trace clic, données commande en temps réel. |
| **PH24.12** | **AI Returns Decision Assist** — panneau retours Amazon, suggestions IA, checklist SAV. |
| **PH25.8/25.9** | Fix PH24.7 ; restore UTF8 en mode AI degraded ; encodage consent/attributs. |
| **PH25.10/10B/10C/10D** | AI UX — panneau suggestions, actions rechargeable, wire DEV, débit KBActions source of truth. |
| **PH25.11** | KBActions rename mapping — cohérence nomenclature produits Stripe vs code. |
| **PH26.2/26.2B/26.2C** | Amazon backfill complete orders, fast progress, orders+items background. |
| **PH26.3/26.3B** | Amazon backfill V2, hyperscalable. |
| **PH26.4/26.4B/26.4C** | Single source of truth mapping, stats UI migration, audit, progress. |
| **PH26.5A-26.5L** | E2E, MIME parsing fix, history backfill, attachment truncation, inbox counters drift, API unavailable, integrity, hosted attachments, raw MIME, context file upload. |
| **PH26.6/26.6B** | DEV golden freeze, global golden state. |
| **PH26.7** | **IA guardrails** — anti-refus automatique, seuils confiance, dégradation gracieuse. |
| **PH26.8/26.8C** | Inbox — filtre par défaut pending, empty state UX, compteurs. |
| **PH26.9** | **Multi-attachments** — hosted UX, pièces partielles, exclusion AI, remplacement. |
| **PH28.x** | Prod audit, rebuild, UI restore, auth spaces, tenant gate, OTP, onboarding, orders redirect, dashboard, inbox, channels, suppliers, AI journal, settings, billing, golden rollback, menu FR. |
| **PH29.x** | DEV UI cache divergence, onboarding hub, tenant realign, parity messages/channels/orders, clone, rollback, API baseURL fix, git golden, AI context, endpoints alignment. |
| **PH30.1-30.5** | Octopia prod finalize, API/dashboard golden compat, messages status workflow, order import fix. |
| **PH31** | **KBActions** — logique produit (plans, quotas, débit, paywall). |
| **PH32.3/32.4** | Supplier thread, routage mailcore, contexte IA fournisseur, email E2E, sync statut SAV supplier_case. |
| **PH33.x** | Register public routes, user persistence, spaces profile KBActions, paywall, entitlement Stripe, billing exempt, trial checkout, onboarding success, playbooks, KBActions access v2. |
| **PH34.1-34.4** | Amazon OAuth immediate unauthorized fix, connect debug, trusted proxy auth, inbound address provisioning, daily budget exceeded, sender policy, Octopia route mismatch. |
| **PH35.1-35.3** | Octopia adapter readonly, outbound adapter, anti-race lock, import completion, prod readonly. |
| **PH36.0-36.4** | P0 stabilisation orders/channels, orders import in messages, Octopia order enrichment, discussions sync, message sync. |
| **PH37** | **Audit global** — inventaire features, dettes, alignement DEV/PROD, roadmap. |

---

## PH42 à PH69 (Moteurs IA SAV)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH42B** | Nettoyage messages Amazon extraits — extraction buyer_name (subject), order_id (messages/subject), reclassification sender (buyer/seller/amazon_system), détection messages pollués/dupliqués, quality_score par conversation. Livrables : amazon-messages-cleaned.json, audit CSV. |
| **PH42C** | Extraction Trello SAV — export board JSON, script ph42c-trello-extractor, décisions humaines (remboursement, remplacement, garantie) nettoyées et anonymisées. Livrable : trello-sav-cleaned.json. |
| **PH42D** | Fusion datasets SAV — matching progressif (order_id exact → normalise → proximité date/texte) entre messages Amazon et Trello. Livrables : keybuzz_sav_fused_dataset.json (267 cas), high_confidence (20 cas), audit CSV. Utilisé par PH43. |
| **PH43** | **Historical Resolution Engine** — enrichit le system prompt avec patterns historiques du dataset PH42D (296 cas). Recherche par scenario/marketplace/texte, score pertinence, anti-patterns (8 règles). Avant : IA règles génériques ; Après : politique SAV + précédents réels + garde-fous. Fichier : historicalResolutionEngine.ts. |
| **PH43.1** | Audit du Historical Engine — vérification cohérence, couverture dataset. |
| **PH44** | **Tenant AI Policy Layer** — couche politique configurable par tenant entre PH41 et PH43. Table `tenant_ai_policies`. Si null → comportement inchangé (GLOBAL_POLICY + HISTORICAL). S’active uniquement si ligne existe. |
| **PH44.5** | AI Decision Debug & Observability — endpoints debug policy effective, traçabilité des couches injectées. |
| **PH44.6/44.7** | Order context completeness (audit), enrichment — données commande complètes pour le prompt. |
| **PH45** | **Decision Tree Engine** — arbre de décision SAV, classification scenario vers stratégie. Spec + implémentation. |
| **PH45.1** | Audit Decision Tree — validation règles, cas limites. |
| **PH46** | **Response Strategy Engine** — choix stratégie de réponse (REQUEST_INFORMATION, OFFER_REFUND, etc.) selon contexte. |
| **PH47** | **Customer Risk Engine** — catégorisation risque client (score, signaux) selon historique. |
| **PH48** | **Product Value Awareness** — classification valeur commande (LOW/MEDIUM/HIGH), seuils. |
| **PH49** | **Refund Protection Engine** — protection niveau remboursement, signaux anti-pattern refund_first. |
| **PH49.1** | Audit Refund Protection — validation seuils, blocages. |
| **PH50** | **Merchant Behavior Engine** — taux refund/warranty/investigation du vendeur depuis données réelles. |
| **PH51** | **Conversation Learning Engine** — enregistrement learning events (accepted/modified/rejected) pour PH52/PH96. |
| **PH51.1** | Audit Conversation Learning. |
| **PH52** | **Adaptive Response Engine** — signaux adaptatifs (investigation, warranty, refund) selon learning + contexte. |
| **PH52.5-52.7** | Learning Control — toggle collect/apply, UI, Expert Mode Backend (contrôle avancé apprentissage). |
| **PH53** | **Customer Tone Engine** — détection ton client (EMPATHETIC, AGGRESSIVE, etc.), confiance. |
| **PH54** | **Customer Intent Engine** — détection intention (ORDER_STATUS, REFUND_REQUEST, etc.). |
| **PH55** | **Fraud Pattern Detection** — signaux fraude, risk level, guidance. |
| **PH56** | **Delivery Intelligence Layer** — scénario livraison (DELIVERY_WINDOW_EXPIRED, etc.), signaux. |
| **PH57** | **Supplier/Warranty Intelligence Layer** — scénario garantie (WARRANTY_NOT_APPLICABLE, etc.). |
| **PH58** | **Conversation Memory Engine** + **fix inbox** : (1) Mémoire conversation pour contexte ; (2) Bug filtres KPI — useEffect deep-link resetait filtres au clic ; useRef(isInitialDeepLink) ; (3) Race tenantId dans fetchConversationDetail → guard + tenantIdRef. |
| **PH59** | **Context Compression Engine** — compression 4 familles du prompt, ~51 % tokens économisés. |
| **PH60** | **Decision Calibration Engine** — niveau AUTO/GUIDED/HUMAN_REQUIRED selon risque. |
| **PH61** | **Marketplace Intelligence Engine** — analyse contexte marketplace (AMAZON, OCTOPIA, etc.). |
| **PH62** | **Evidence Intelligence Engine** — niveau preuve, signaux pièces jointes. |
| **PH63** | **Abuse Pattern Engine** — analyse abus longitudinal 180j, riskIndicators. |
| **PH64** | **Resolution Prediction Engine** — prédiction résolution probable (refund, warranty, etc.) selon contexte. |
| **PH65** | **Escalation Intelligence Engine** — signaux escalade (délai, insatisfaction, risque juridique). |
| **PH66** | **Self-Protection Engine** — protection vendeur (abus, fraude, patterns récurrents). |
| **PH67** | **Knowledge Retrieval Engine** — récupération base connaissances pour enrichir contexte prompt. |
| **PH67B** | Alignement pipeline debug — cohérence endpoints. |
| **PH68** | **Customer Emotion Engine** — détection émotion client (frustration, colère, satisfaction). |
| **PH69** | **Prompt Stability Guard** — garde-fous stabilité prompt, limites taille, cohérence output. |

---

## PH70 à PH86

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH70** | **Workflow Orchestration Engine** — orchestration flux SAV, états, transitions, conditions. |
| **PH71** | **Case Autopilot Engine** — pilotage automatique dossiers, règles, garde-fous. |
| **PH72** | **Action Execution Engine** — exécution actions (refund, replacement, etc.), validation préalable. |
| **PH73** | **Carrier Integration Engine** — intégration transporteurs, tracking, livraison. |
| **PH74** | **Return Management Engine** — gestion retours, workflows, intégration marketplace. |
| **PH75** | **Supplier Case Automation** — automatisation dossiers fournisseur, escalade, suivi. |
| **PH76** | **Autopilot Execution Engine** — moteur exécution plans autopilot, dry-run/real. |
| **PH77** | **Execution Audit Trail** — traçabilité exécutions, journal, conformité. |
| **PH78** | **AI Performance Metrics Engine** — métriques performance IA, taux succès, dégradations. |
| **PH79** | **AI Health Monitoring Engine** — surveillance santé IA, alertes, détection anomalies. |
| **PH80** | **AI Safety Simulation Engine** — simulation exécution avant réel, sandbox. |
| **PH81** | **Human Approval Queue Engine** — file approbation humaine, priorisation, assignation. |
| **PH82** | **Followup Engine** — suivi dossiers, relances, rappels, SLA. |
| **PH83** | **AI Control Center Engine** — centre de contrôle IA, paramètres, kill switches. |
| **PH84** | **SLA Followup Scheduler** — planification relances SLA, deadlines, escalade. |
| **PH85** | **Ops Action Center Engine** — centre actions ops, assign/resolve/snooze, équipes. |
| **PH86.1** | **Admin v2 Foundation** — repo keybuzz-admin-v2, Next.js, déploiement K8s, séparation legacy. |
| **PH86.1A** | **Admin v2 DNS** — exposition DEV/PROD, TLS Let's Encrypt, URLs admin-dev/admin.keybuzz.io. |
| **PH86.1B** | **Admin v2 Auth** — NextAuth CredentialsProvider, Vault bcrypt, RBAC, bootstrap. |

---

## PH90 à PH117 (Moteurs IA avancés)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH90** | **Cost Awareness Engine** — compare 5 options (refund, replacement, return, supplier warranty, carrier investigation). Formules coût, profitabilityRisk (LOW/MEDIUM/HIGH/CRITICAL). Aucun LLM, 0 KBActions. `costAwarenessEngine.ts`. |
| **PH91** | **Buyer Reputation Engine** — réputation acheteur 180j : TRUSTED_BUYER, STANDARD_BUYER, RISKY_BUYER, ABUSIVE_BUYER. Score 0-1, riskIndicators. Sources : historique DB. |
| **PH92** | **Marketplace Policy Engine** — règles SAV par marketplace (AMAZON, CDISCOUNT, OCTOPIA, FNAC, MIRAKL). Profils : ton, refund, preuves, escalade. 6 policy profiles. |
| **PH93** | **Customer Patience Predictor** — tolérance temporelle via 10+ signaux regex. Niveaux HIGH (48h)/MEDIUM (24h)/LOW (12h)/CRITICAL (4h). Escalation risk. |
| **PH94** | **Resolution Cost Optimizer** — compare 6 options, sélectionne la moins coûteuse parmi autorisées. Blocage auto si fraude/abus. Inputs : PH90, PH92, PH91, PH55, PH49. |
| **PH95** | **Global Learning Engine** — synthèse apprentissages (AI acceptance, resolution effectiveness, escalation patterns). **Hors pipeline prompt** — analytics seulement. 4 endpoints. |
| **PH96** | **Seller DNA Engine** — apprend style SAV réel depuis conversation_learning_events + ai_execution_audit. 6 dimensions profil (refundTolerance, warrantyPreference, etc.), 6 classifications (INVESTIGATION_FIRST_SELLER, etc.). Alignement IA avec comportement vendeur. |
| **PH97** | **Multi-Order Context Engine** — détection fraude/abus multi-commande 90j. Analyse patterns multi-order. |
| **PH98** | **AI Quality Scoring Engine** — évaluation qualité décisions IA SAV. Observabilité, DB routing audit. |
| **PH99** | **AI Self-Improvement Engine** — analyse performance IA, patterns amélioration, faiblesses, suggestions. |
| **PH100** | **AI Governance Engine** — gouvernance globale (autonomie, seuils confiance, plafonds risque, blocages). |
| **PH101** | **Knowledge Graph Engine** — graphe relationnel entités SAV (buyer, order, product, incident). |
| **PH102** | **Long-Term Memory Engine** — table ai_long_term_memory, signaux persistants (entity_type, signal_type, occurrences, confiance). |
| **PH103** | **Strategic Resolution Engine** — choix parmi 8 stratégies (empathetic_resolution, strict_policy, escalation, etc.). |
| **PH104** | **Cross-Tenant Intelligence Engine** — signaux globaux anonymisés multi-tenants (produits, transporteurs, fraude). |
| **PH105** | **Autonomous Ops Engine** — plans d’action opérationnels (planification, pas exécution). Dry-run. |
| **PH106** | **Action Dispatcher Engine** — routage actions, validation, mode (dry-run/real). |
| **PH107** | **Connector Abstraction Layer** — 10 connecteurs normalisés (email, amazon, cdiscount, shopify, etc.), simulation sans appel externe. |
| **PH108** | **Autonomous Case Manager** — cycle vie SAV, état dossier, propriétaire, transitions. |
| **PH109** | **Case State Persistence Engine** — tables ai_case_state, ai_case_state_history. Endpoints cycle de vie. |
| **PH110** | **Controlled Real Execution Layer** — fail-safe par défaut. Tables ai_execution_control (allowlist), ai_execution_attempt_log. Kill switches global/connector/tenant. Cascade : pas de policy = simulé ; REAL_ALLOWED exigé. |
| **PH111** | **Controlled Activation Layer** — table ai_activation_policy. Pilotage activations IA (mode, rollout_stage). Qui peut sortir du dry-run. |
| **PH112** | **AI Control Center** — première couche control center, 5 pages ops (Ops, Queues, Approbations, Follow-ups). |
| **PH112-FIX** | Corrections : (1) Hardcodage ecomlg-001 → tenant dynamique ; (2) Version figée Sidebar ; (3) 4 routes API ops manquantes ; (4) Race useApiData/tenant ; (5) X-User-Email. |
| **PH113** | **Real Connector Activation** — activation réelle connecteurs selon allowlist ai_execution_control. |
| **PH114** | **Real Connector Scaling** — scaling connecteurs activés, capacité, charge. |
| **PH115** | **Real Execution Enablement** — activation exécution réelle avec garde-fous PH110. |
| **PH116** | **Real Execution Monitoring** — monitoring exécutions réelles, métriques, alertes. |
| **PH117** | **AI Dashboard tenant** — page /ai-dashboard : niveau autonomie IA, état système, performance (executions, taux succès), impact financier, risques, connecteurs, recommandations. Couche SaaS client-facing. |

---

# Partie 2 — Phases PH- (préfixe tiret)

## PH-AI

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AI-N1-ENTERPRISE-01** | **Objectif** : Remplacer le mock par LiteLLM Enterprise. **Livrables** : Tracking tokens/€ par tenant ; budgets quotidiens par plan (starter/pro/autopilot) ; UI consommation IA ; guardrails (global_kill_switch, tenant_kill_switch, budget check) ; rollback documenté. Architecture : checkGuardrails() → getTenantPlan() avant chaque appel LLM. |

---

## PH-AMAZON

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AMAZON-OUTBOUND-SOURCE-OF-TRUTH-LOCK-01** | **Source de vérité** outbound Amazon. `determineAmazonProvider.ts` : channel≠amazon → erreur ; orderId → SPAPI_ORDER ; sinon SMTP. Jest 6 suites, healthcheck, 9 deliveries E2E 250 OK. |
| **PH-AMAZON-OUTBOUND-TRUTH-03** | **Problème** : Messages outbound (sans commande) acceptés par Postfix (250 OK) mais invisibles dans Seller Central. **Cause** : From `noreply@keybuzz.io` non reconnu par Amazon. **Solution** : `getInboundAddressForTenant()` — récupération adresse inbound validée depuis `inbound_addresses` ; envoi depuis cette adresse pour que Amazon associe au vendeur. Worker modifié, validation 9 deliveries visibles Seller Central. |

---

## PH-ATTACHMENTS

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-ATTACHMENTS-DOWNLOAD-TRUTH-01** | **Problèmes** : (1) HTTP 500 sur /attachments/xxx — storage_key NULL (migrations sans upload MinIO) ; (2) MIME brut dans body au lieu de "[Pièce jointe reçue]" + attachment. **Fixes** : gestion gracieuse storage_key NULL (réponse explicite) ; parser MIME appelé dans inboxConversation.service. |

---

## PH-AUDIT

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AUDIT-CLIENT-API-PARITY-01** | **Audit** : Inventaire versions réelles (digests SHA256), audit bundle client. Constat : API DEV=PROD identique ; Client digest différents (URLs build-time). Migration Amazon SP-API v2026 : non effectuée (workers toujours orders/v0). |
| **PH-AUDIT-DETTES-01** | **Constats** : Infra Stripe V1 complète ; UI Billing OK ; ~50+ mocks non câblés ; tenantId "kbz-001" hardcodé ; Admin UI shell only ; Auth social mock (pas OAuth réel) ; aucun secret exposé. Tableau PH par PH. |
| **PH-AUDIT-FEATURES-RUNTIME-REPORT** | **Audit runtime** : Conversations DEV/PROD testées, /ai/policy/effective — couches active (historicalContext, decisionTree, refundProtection, etc.). Validation conditions réelles PH41-PH117. |
| **PH-AUDIT-FIX-CLIENT-DEV-ALIGNMENT-REPORT** | **Problème** : Client DEV buildé avant sync fichiers PH117 sur bastion → features AI Dashboard absentes. **Solution** : Rebuild avec fichiers confirmés (app/ai-dashboard, api/ai/dashboard, ClientLayout, I18nProvider). Image v3.5.60-ph117-aligned-dev. |

---

## PH-BILLING

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-BILLING-HARD-UI-GATE-01** | Porte d’accès côté UI — bloquer tout rendu layout tant que l’entitlement charge ou que le tenant est `pending_payment`. |
| **PH-BILLING-PAYMENT-FIRST-01** | Status-Gate Payment-First — création tenant avec `pending_payment`, blocage accès SaaS jusqu’au paiement Stripe. |
| **PH-BILLING-SERVER-GATE-01** | Porte côté serveur — Set-Cookie BFF pour `kb_payment_gate`, correction du bug `useEntitlement` sur `currentTenantId` null. |
| **PH-BILLING-SIGNUP-FIX-REDIRECT** | Correction bypass Stripe — `/signup` remplacé par redirect vers `/register`, tous les CTAs pointent vers `/register`. |
| **PH-BILLING-SIGNUP-FIX-REDIRECT-v2** | Fix minimal — `/signup` devient redirect pur vers `/register`, pipeline PH-TD-08 premier usage réel. |
| **PH-BILLING-SIGNUP-ROOTCAUSE-01** | Audit des points d’entrée self-signup — cartographie, aucun entrypoint ne passait par Stripe. |

---

## PH-CHANNELS

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-CHANNELS-ANTIFRAUD-PROD-ON** | **Anomalie** : Tenant switaa addon_qty=2, canaux actifs=0. Addon Stripe non nettoyé. **Fix** : POST /channels/sync-billing action "remove". Sync antifraude activée. |
| **PH-CHANNELS-BILLING-INTEGRATION** | **Intégration** Billing/Channels — sync addon Stripe par canal, table tenant_channels, produit addon. |
| **PH-CHANNELS-FIX-04** | **Causes** : (1) Commit GitOps jamais pushé ; (2) Raisonnement provider global → Amazon DE copiait FR ; (3) Bouton Retirer absent. **Fix** : déploiement, marketplace_key, nouvelle page. |
| **PH-CHANNELS-STRIPE-PROD-CHECK** | Audit Stripe Live — produits addon, prix, variables d’environnement PROD. |
| **PH-CHANNELS-STRIPE-SYNC-ON** | Activation sync Stripe — addon canal, subscriptions testées, tags v3.5.59-channels-stripe-sync. |

---

## PH-DEPLOY / PH-EMERGENCY / PH-I18N

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-DEPLOY-PROCESS-ROOTCAUSE-01** | **5 causes** : SCP sans commit ; COPY . . Dockerfile ; pas verify-image ; release gate absent ; ArgoCD PROD cassé. Timeline PH117/signup-fix. |
| **PH-EMERGENCY-CLIENT-RESTORE-DEV-PROD** | v3.5.60-signup-fix cassé (menu, focus, paywall). Snapshots ; GitOps ; DEV→v3.5.59, PROD→v3.5.58. Service restored. |
| **PH-I18N-ESCAPED-STRINGS-01** | **Problème** : "\u00e9" affiché littéralement (ex: "activ\u00e9"). **Cause** : Séquences Unicode dans JSX text. **Fix** : Remplacer par caractères UTF-8 directs (é). |

---

## PH-INBOUND / PH-INFRA

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-INBOUND-TRUTH-VERIFY-02** | Vérification adresse inbound ecomlg-001 : `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`. Preuves logs MX (status=sent), mail-core (INBOUND_RECEIVED). SEULE valide pour ecomlg-001/Amazon/FR. |
| **PH-INFRA-01-HETZNER-FIREWALL-AUDIT** | **Audit uniquement** — inventaire 48 serveurs Hetzner. 5 risques CRITIQUES : PG 5432, Redis 6379, RMQ 5672/15672, etcd 2379/2380 exposés Internet. Score 2/10. Plan hardening 6 phases. |
| **PH-INFRA-02-HETZNER-FIREWALL-HARDENING** | 4 firewalls créés : keybuzz-public-firewall (80,443), keybuzz-bastion-firewall (22), keybuzz-internal-firewall (réseau privé only), keybuzz-mail-firewall. PG/Redis/RMQ/MinIO fermés. SSH 47→2 bastions. Score 7/10. Rollback possible. |
| **PH-INFRA-03-K8S-MASTERS-HARDENING** | Firewall keybuzz-k8s-masters-secure : whitelist 6443, etcd/kubelet fermés. fw-k3s-masters décommissionné. Score 8.5/10. |
| **PH-INFRA-04-K8S-MASTERS-PRIVATE-NETWORK-MIGRATION** | Masters migrés vers IPs privées 10.0.0.100/101/102. Certs apiserver régénérés. etcd member update. Firewall keybuzz-k8s-masters-hardened : 6443 bastions only. Score 9.5/10. 0 downtime. |
| **PH-INFRA-05-06-07** | PH05 : Audit kubelet workers, port 10250 fermé. PH06 : PG/Redis/RMQ/Monitoring tous fermés. PH07 : Ingress rate limit 10rps, bot protection (masscan, sqlmap, nikto bloqués). 15/15 Ingress. |
| **PH-INFRA-08-09-10** | PH08 : PG/Redis/RabbitMQ/NodeExporter bind IP privée (3/3 chacun). Failover Patroni attendu. PH09 : Monitoring control plane partiel. PH10 : fail2ban bastion, 12 IPs bannies. Score 9.7/10. |

---

## PH-MINIO / PH-MVP

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-MINIO-HA-VERIFY-01** | Vérification MinIO HA — test résilience avec 1 nœud down, upload/download restent fonctionnels. |
| **PH-MVP-02-EXEC-01** | **3 fixes** : (1) Décodage sujets MIME RFC 2047 (=?UTF-8?Q?...) ; (2) Logo KeyBuzz + redirect /dashboard ou /inbox ; (3) rbac=restricted → toast "Accès restreint". |
| **PH-MVP-ATTACHMENTS-FINALIZE-02** | Parser v3 : body "[Pièce jointe reçue]" + attachments[] avec downloadUrl. Conservation texte. Migration messages existants. |
| **PH-MVP-ATTACHMENTS-RENDER-01** | Architecture : Email inbound → API parser → MinIO + message_attachments DB. API /attachments/:id. UI affiche liens au lieu de base64. |
| **PH-MVP-INBOUND-FIX-01** | Parser forward Amazon, stripHtml, sanitization UI body, décodage MIME customerName. MinIO déployé. Tables vides initialement. |
| **PH-MVP-INBOUND-MIME-PARSER-HARDEN-01** | mailparser installé. Détection MIME/binaire. Extraction body + attachments. PDFs extraits. mimeParser.service.ts. |
| **PH-MVP-INBOUND-SOURCE-OF-TRUTH-01** | Table inbound_addresses : marketplace, country, token, emailAddress. Persistance immuable. Génération côté backend. Client affiche sans modifier. |
| **PH-MVP-P0P1-FIX-01** | **P0** : Vault password rotaté, ESO SecretSyncedError → fix config + force sync. **P1** : Inbox données réelles ; attachments proxy streaming + tenantId. |

---

## PH-ONBOARDING

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-ONBOARDING-OAUTH-CONTINUITY-01** | **Problème** : OAuth Google → /register affiche formulaire email + bouton Google → clic boucle vers /login. **Fixes** : callback vers /register avec ?oauth=google ; Register détecte session OAuth, saute formulaire. |
| **PH-ONBOARDING-OAUTH-PLAN-CONTINUITY-01** | **Problème** : Plan choisi + "Continuer Google" → redirect /login, plan perdu. **Cause** : /api/auth/signin sans provider → NextAuth pages.signIn. **Fix** : signIn('google', { callbackUrl }) avec plan/cycle/step. |
| **PH-ONBOARDING-PLAN-STATE-CONTINUITY-01** | **Problème** : Mode annuel + plan PRO + "Continuer Google" → retour sélection forfait, annuel perdu. **Cause** : redirect NextAuth compare url relative avec baseUrl → startsWith échoue. **Fix** : resolved = url.startsWith('/') ? baseUrl+url : url ; + sessionStorage fallback plan/cycle. |

---

## PH-PROD

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-PROD-FTP-01.1-VAULT-WRITE-FIX** | **Fix** : credentials FTP exposés via Vault write. Passage secrets K8s, suppression token. |
| **PH-PROD-FTP-01.1B-VAULT-ALIGN** | FTP durable Vault KV v2 — pattern KeyBuzz, credentials Vault, 0 secret clair. |
| **PH-PROD-FTP-02-MATCHING-UX-PERSISTENCE** | Matching CSV — sample values, UI claire, mapping relu à l’ouverture, formulaire pré-rempli. |
| **PH-PROD-FTP-02B-MATCHING-VISIBILITY-FIX** | Correction visibilité matching — sample_values, couleur verte, champs désactivés, bloc rendu UI corrigé. |
| **PH-PROD-LAST-KNOWN-GOOD-RESTORE** | Restauration PROD v3.5.58 (last known good) — preuve régression focus mode, rollback validé. |
| **PH-PROD-MINIO-HA-01** | MinIO HA prod — cluster 3 nœuds, HAProxy LB, credentials Vault/ESO. Résilience. |
| **PH-PROD-MINIO-HA-02** | MinIO interne only — 0 accès public, PJ via API KeyBuzz authentifiée uniquement. |

---

## PH-RESTORE / PH-ROLLBACK

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-RESTORE-AMAZON-CONTEXT-01** | Restauration contexte Amazon + inbound — format canonique adresse, code génération, validation MX. |
| **PH-ROLLBACK-DEV-PH116** | Rollback DEV vers PH116 (Real Execution Monitoring) — état 100 % fonctionnel. |
| **PH-ROLLBACK-PROD-PH115** | Rollback API PROD de PH116 vers PH115 — isolation pour diagnostic symptômes UI. |
| **PH-ROLLBACK-PROD-PH116** | Rollback PROD vers PH116 — alignement avec DEV, API seule modifiée. |

---

## PH-S01 (Seller Foundations)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-S01-SELLER-FOUNDATIONS-REPORT** | **Fondations** seller.keybuzz.io : schéma PostgreSQL seller ; registry marketplaces ; sources catalogue déclaratives ; SecretRefs Vault ; SSO KeyBuzz sans reauth. Multi-tenant. |
| **PH-S01.1-REMEDIATION-REPORT** | **Drifts** : Auth headers spoofables → middleware introspection cookie/JWT ; FK public.tenants → seller.tenants autonome ; seed marketplaces vérifié. |
| **PH-S01.2-POSTDEPLOY-PROOFS** | ArgoCD keybuzz-seller-dev Synced. Health Degraded (ExternalSecret Vault permission). Ressources synchronisées. |
| **PH-S01.2B-RETURNTO-SSO-REPORT** | Paramètre returnTo pour login client-dev → seller-dev. Validation URLs *.keybuzz.io. Cookie + callback redirect. |
| **PH-S01.2C-RETURNTO-TENANT-REPORT** | **Bug** : Après select-tenant, reste sur client /inbox au lieu de redirect returnTo. **Fix** : Consommation cookie dans /select-tenant, redirect vers storedReturnTo. |
| **PH-S01.2D-COOKIE-DOMAIN-REPORT** | cookies session domain=.keybuzz.io pour SSO cross-subdomain. Production only. httpOnly, sameSite=lax, secure. |

---

## PH-S02 (Catalog Sources)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-S02-CATALOG-SOURCES-REPORT** | Gestion déclarative des sources produits — aucun FTP/API appelé, multi-tenant, UX métier. |
| **PH-S02.1-FTP-CONNECTION-REPORT** | Connexion FTP et sélection fichiers — exploration passive uniquement, aucun téléchargement. |

---

## PH-S03 (Matching FTP)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-S03.0-AUDIT-MATCHING-FTP** | **Audit** Catalog Sources + FTP + Matching CSV — diagnostic sans modification, schéma flows, points de blocage. |
| **PH-S03.1-MATCHING-STABILIZATION-REPORT** | **Stabilisation** — proxy same-origin, verrouillage PUT /fields, wizard robuste, status `ready`. |
| **PH-S03.1B-POSTDEPLOY-PROOFS** | Preuves post-déploiement PH-S03.1. |
| **PH-S03.2-FTP-SECRETREF-REPORT** | FTP via SecretRef — credentials K8s/Vault, plus de mot de passe en clair. |
| **PH-S03.2B-POSTDEPLOY-PROOFS** | Preuves post-déploiement PH-S03.2. |
| **PH-S03.2E-404-ROUTING-DEBUG** | Debug routing 404 — diagnostic distingo 404 métier vs routing. |
| **PH-S03.2F-404-FIX-REPORT** | Correction 404 « Tester la connexion » FTP — routes FTP absentes de l’image déployée. |
| **PH-S03.2G-SELLERAPI-ROUTES-FIX-REPORT** | Correction routes Seller API. |
| **PH-S03.2I-NO-404-CLOSEOUT** | Clôture correctif 404. |
| **PH-S03.2J-GITOPS-CLEANUP** | Nettoyage GitOps. |
| **PH-S03.3A-WIZARD-UNKNOWN-ERROR-FIX** | **Fix** erreur « Unknown » wizard — diagnostic, correction affichage/backend. |
| **PH-S03.3B-CLOSEOUT** | Clôture PH-S03.3 — validation, preuves, rapport. |
| **PH-S03.4-DELETE-AND-MAPPING-REWORK** | Suppression + refonte mapping — simplification UX, cohérence données. |
| **PH-S03.4B-WIZARD-NO-MAPPING-VERIFY** | Vérification wizard sans mapping. |
| **PH-S03.5-UNKNOWN-ERROR-GLOBAL-FIX** | Fix global erreur Unknown. |
| **PH-S03.5B-CATALOG-SOURCES-UNKNOWN-ERROR** | Erreur Unknown sources catalogue. |
| **PH-S03.5C-CLOSEOUT** | Clôture PH-S03.5. |
| **PH-S03.5D-AUTONOMOUS-DEPLOY-PROOFS** | Preuves déploiement autonome. |
| **PH-S03.5E-PLAYWRIGHT-PROOF** | Preuve Playwright E2E. |
| **PH-S03.6-CATALOG-SOURCES-BLOCKER-FIX** | Correction blocker catalogue. |
| **PH-S03.7-TENANT-BINDING-AND-WIZARD-MINIMAL** | Liaison tenant et wizard minimal. |
| **PH-S03.8-FTP-PERSISTENCE-FIX** | Persistance FTP corrigée. |
| **PH-S03.8B-FTP-READ-AFTER-WRITE** | Lecture FTP après écriture. |
| **PH-S03.9-FTP-BROWSE-MATCH-FIX** | Fix browse et match FTP. |
| **PH-S03.9R-ROLLBACK-NO-PASSWORD-DB** | Rollback sans mot de passe en base. |
| **PH-S03.9S-NO-PASSWORD-IN-URL** | Suppression mot de passe dans l’URL. |
| **PH-S03.FINAL-FIX-UNKNOWN+WIZARD** | Fix final Unknown + wizard. |

---

## PH-S04

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-S04.0-FTP-SIMPLE-MVP** | **FTP Simple MVP** — wizard 4 étapes, password body only, pas de mapping wizard. Onboarding catalog. |

---

## PH-SRE

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-SRE-AUDIT-01** | **Inventaire** 52 serveurs Hetzner (K8s, PG, Redis, RMQ, MinIO, Vault, mail). État backups, cluster, risques. Prérequis PH-INFRA-01. |
| **PH-SRE-BACKUP-06** | **DR** : pg_dump -Fc (keybuzz, keybuzz_backend, keybuzz_prod) + globals ; redis-cli --rdb ; MinIO kubectl cp ; K8s state (12 namespaces). Cron 04:00 UTC. ~14 MB/jour. Restauration testée (80 tables keybuzz_prod OK). Vault/Secrets exclus. |
| **PH-SRE-DB-ENDPOINT-NONREGRESSION-02** | **Régression** : PGHOST 10.0.0.122 (node) au lieu de 10.0.0.10 (LB). Failover PG non détecté par HAProxy. Fix : secret + deployment revert. |
| **PH-SRE-FIX-02** | PgBouncer non installé. CrashLoopBackOff Amazon workers : tables Prisma manquantes en keybuzz_prod (DB mixte API+Backend). |
| **PH-SRE-FIX-03** | Alertmanager 100% CPU → restart (3%) ; containerd 273 GB libérés ; root install-v3 85%→52%. Pas touché : workers Amazon, migrations. |
| **PH-SRE-FIX-04** | Création 6 tables + 7 enums + 15 index dans keybuzz_prod. Owner keybuzz_api_prod. Workers PROD 0 restarts. |
| **PH-SRE-FIX-05** | GC containerd timer ; Redis maxmemory 1500MB allkeys-lru ; surveillance alertmanager 15min ; disques workers 6h seuil 75%. |
| **PH-SRE-MIGRATION-CHECKPOINT-01** | 52/52 backups Hetzner ; 24 snapshots manuels ; 344+ images rotation 7j. Rollback possible. |

---

## PH-TD (Tech Debt)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-TD-01-DB-AUDIT** | Audit complet bases PostgreSQL — inventaire databases (keybuzz, keybuzz_backend, keybuzz_prod), users, connexions. |
| **PH-TD-01A-PROD-DB-FUNCTIONAL-GAP-CLOSURE** | Fermeture écart fonctionnel PROD — création 7 tables manquantes, validation structurelle DEV vs PROD. |
| **PH-TD-01B-DB-ACCESS-MAPPING** | Carte d’accès bases de données. |
| **PH-TD-01C-MIGRATION-PLAN** | Plan de migration DB. |
| **PH-TD-01C-SAFE-DB-SPLIT-REPORT** | Rapport split DB sécurisé. |
| **PH-TD-01D-POST-SPLIT-CLEANUP** | Nettoyage post-split. |
| **PH-TD-01E-LEGACY-TABLE-CLEANUP** | Nettoyage tables legacy. |
| **PH-TD-01F-DB-GUARDRAILS** | Garde-fous bases de données. |
| **PH-TD-02-WORKER-AUDIT** | **Audit workers** — amazon-orders, amazon-items, outbound, backfill, CronJobs. Erreurs PG 57P01, résilience. |
| **PH-TD-02-WORKER-RESILIENCE-REPORT** | Rapport résilience workers. |
| **PH-TD-03-FINAL-TECH-DEBT-AUDIT** | Audit final dette technique. |
| **PH-TD-04-FINAL-DEBT-CLEANUP** | Nettoyage final dette. |
| **PH-TD-05-EXTERNALMESSAGE-UNIFICATION** | **Unification** ExternalMessage — source de vérité unique keybuzz_prod, migration depuis sources multiples. |
| **PH-TD-05-MIGRATION-PLAN** | Plan migration ExternalMessage. |
| **PH-TD-06-BUILD-PIPELINE-HARDENING** | **Problème** : Build DEV avant sync PH117 → desalignement. **Scripts** : build-client.sh, verify-build-consistency.sh, client-runtime-audit.sh. Guardrails : dirty check, tag env, fichiers requis, /ai-dashboard dans bundle, 0 URL autre env. |
| **PH-TD-07-FRONTEND-RELEASE-GATE** | **Problème** : Promotion PROD avec régression (focus ON par défaut). **Gate** : 10 routes critiques ; pattern getFocusMode `null!==x&&"true"===x` = PASS (OFF si null). Blocage si fail. |
| **PH-TD-07-FRONTEND-RELEASE-GATE-REPORT** | Rapport gate frontend. |
| **PH-TD-08-SAFE-DEPLOY-PIPELINE** | **Objectif** : Éliminer builds contaminés. **Flow** : git clone bastion → build-from-git.sh (COPY explicite) → verify-image-clean.sh (non-régression) → gate OK → push GHCR. PROD : frontend-release-gate (routes, focus OFF). Blocage si gate fail. |
| **PH-TD-08-SAFE-DEPLOY-PIPELINE-REPORT** | Rapport détaillé pipeline, scripts, guardrails. |

---

## PH-UI

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-UI-ROOTCAUSE-01-REPORT** | **Fichiers** : ClientLayout.tsx central (layout, sidebar, burger, focus mode, onboarding). **Cause menu** : sidebar fixed + translate ; burger lg:hidden. **Focus** : getFocusMode() localStorage. Aucun fichier fantome. |

---

---

## Phases PH_ (underscore)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH_AUTH_FIX** | **Auth** : OTP sécurisé (SHA-256, Redis), fix TLS, suppression devCode. Session Redis, rotation tokens. |
| **PH_VAULT_*** | Vault : audit HA, rebuild cluster, provisioning, migration Raft, cutover. Stockage sécurisé credentials. |

---

*Document généré à partir des rapports présents dans `keybuzz-infra/docs`. Dernière mise à jour : 17 mars 2026.*
