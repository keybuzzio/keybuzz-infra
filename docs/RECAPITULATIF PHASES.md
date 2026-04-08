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

## PH118 à PH126 (Role Access, Agent Foundations, Escalation, Workbench)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH118-ONBOARDING-HARDENING-01** | **Durcissement onboarding** : annulation Stripe sans spinner bloquant, étape `payment_cancelled`, reprise du paiement depuis `/register` et `/locked` (checkout Stripe direct pour `PENDING_PAYMENT`). |
| **PH119-ROLE-ACCESS-GUARD-01** | **Contrôle d'accès centralisé** — `routeAccessGuard.ts` source unique pour routes publiques, sans tenant, exemptées billing, shell, admin. Correction écarts (`/invite`, `/workspace-setup`, `/ai-dashboard`). |
| **PH120-TENANT-CONTEXT-STABILIZATION-01** | **Stabilisation contexte tenant** — `TenantProvider` source de vérité, correction hook `useTenantId`, migration depuis `getCurrentTenantId` déprécié. |
| **PH120-MINIMAL-FIX-REINTRO-05** | Correction lenteur post-PH120 en rétablissant lectures synchrones (revert ciblé `useTenantId`/`ClientLayout`), timeouts AuthGuard réduits, cookie paywall réaligné. |
| **PH120-DIFF-AUDIT-RECOVERY-03** | Audit différentiel lecture seule — cause racine de la régression PH120 : initialisation asynchrone du focus mode / `currentTenantId` dans `ClientLayout` vs localStorage synchrone. |
| **PH121-ROLE-AGENT-FOUNDATION-01** | **Fondation rôles et agents** — rôle `viewer`, matrice permissions, hooks `useRole`/`usePermissions`, `PermissionGate`, `RoleBadge`, endpoints BFF `/api/roles/*`, types préparés pour l'escalade. |
| **PH122-ESCALATION-ASSIGNMENT-FOUNDATION-01** | **Fondation assignation** IA vs humain — BFF assign/unassign, hook et UI `AssignmentPanel`/badges inbox, mapping `assignedAgentId`/`assignedType`, structure `EscalationRecord`. |
| **PH122-DIFF-AUDIT-RECOVERY-02** | Audit régressions PH122 — réécriture massive `InboxTripane`, signatures `conversations.service` sans `tenantId`, perte fournisseurs/stats. Plan correctif strictement additif. |
| **PH122-SAFE-REBUILD-03** | Reconstruction safe PH122 sur base PH121 — diff uniquement additif (~+30 lignes, 0 suppression), conservation fonctionnalités existantes, validation DEV/PROD. |
| **PH122-ASSIGNMENT-SELF-AGENT-FIX-04** | Correction du 400 au clic « Prendre » — envoi du `tenantId` au BFF et en-tête `X-Tenant-Id` vers l'API pour assign/unassign. |
| **PH123-ESCALATION-INTELLIGENCE-FOUNDATION-01** | **Fondation escalade** — colonnes DB `escalation_*`, routes API Fastify + BFF escalate/deescalate/status, panneau et hook d'escalade côté client. |
| **PH124-AGENT-WORKBENCH-FOUNDATION-01** | **Workbench agent** — barre filtres rapides (`AgentWorkbenchBar`) et panneau synthèse traitement (`TreatmentStatusPanel`), patch additif sur `InboxTripane`. |
| **PH124-AGENT-FILTERS-ACTION-FIX-02** | Correction filtres workbench inopérants — ajout `agentFilter` et `currentUser` aux dépendances du `useMemo` `filteredConversations`. |
| **PH125-AGENT-QUEUE-MY-WORK-01** | **File « Mon travail »** — filtre « À reprendre » (escalade/recommandé sans assignation), résumé compact, tri par priorité. |
| **PH126-AGENT-PRIORITY-LAYER-01** | **Couche priorité** — scoring multi-critères (`conversationPriority.ts`), `PriorityBadge`, synthèse urgents, toggle « Prioritaires d'abord ». |

---

## PH127 à PH135 (AI Assist, Plans, Autopilot, Email Pipeline)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH127-SAFE-AI-ASSIST-01** | **Suggestions IA déterministes** (assign, escalade, statut, brouillon) dans panneau dédié, validation humaine obligatoire, sans endpoint IA opaque ni envoi automatique. |
| **PH128-AI-SUPERVISION-FOUNDATION-01** | **Fondation supervision IA** — table `ai_suggestion_events`, routes API + BFF tracking/stats, hook `useAISupervision` pour tracer affichage/application/rejet des suggestions. |
| **PH129-PLAN-AUDIT-01** | **Audit système de plans** (code, DB, Stripe) — inventaire incohérences (`free`, casse mixte, `STARTER` absent en prod). Verdict : PLAN SYSTEM INCONSISTENT — FIX REQUIRED. |
| **PH129-PLAN-NORMALIZATION-BUSINESS-02** | **Normalisation plans** — plan canonique en MAJUSCULE, alignement tenants/SLA/KBActions/wallet/Stripe, corrections des écarts identifiés. |
| **PH130-PLAN-GATING-ACTIVATION-01** | **Gating par plan** (frontend + API) — features IA réservées PRO+, modes suggestion/supervisé/autonome selon plan, `403 PLAN_REQUIRED`. |
| **PH131-B-AUTOPILOT-SETTINGS-01** | **Modèle DB `autopilot_settings`** — API CRUD, intégration gating PH130 et UI pour configurer autonomie, actions et escalade sans activer l'automatisation. |
| **PH131-C-AUTOPILOT-ENGINE-SAFE-01** | **Moteur `evaluateAndExecute`** — pipeline contrôlé (plan, mode, safe_mode, LLM, confiance, logs KBA) pour exécution autopilot en environnement sûr (DEV). |
| **PH132-C-AUTOPILOT-CRITICAL-FIXES-01** | Garde plan sur mode `autonomous`, diagnostic contournement Amazon par worker Python, alignement GitOps, logs sorties anticipées du moteur. |
| **PH133-A-AUTOPILOT-CONTEXTUAL-DRAFT-01** | **Autopilot brouillons contextualisés** — alimentation contexte commande (order_ref → `orders`) et temporel pour générer brouillons tracking/retard sans envoi auto. |
| **PH133-B-DELIVERY-TRACKING-TRUTH-RECOVERY-01** | **Récupération vérité suivi livraison** — colonnes dates, backfill `raw_data`, timeline dates Amazon, statuts delivered/in_transit exploitables par IA. |
| **PH133-C-CARRIER-LIVE-TRACKING-TRUTH-RECOVERY-01** | Réduction écart Amazon vs données transporteur (UPS) — table `tracking_events`, enrichissement. DEV validé, arrêt avant PROD. |
| **PH133-D-AMAZON-OUTBOUND-PIPELINE-TRUTH-RECOVERY-01** | Diagnostic et correction **régression pipeline sortant Amazon** (HTML, encodage, chemin worker/SMTP) pour messages correctement formatés. |
| **PH133-F-AMAZON-LINE-BREAK-FIDELITY-01** | Fidélité sauts de ligne Amazon — abandon `<p>` (mal rendus) au profit de `<br>` dans `textToHtmlAmazon()`. |
| **PH133-G-AMAZON-VISUAL-LINE-PRESERVATION-01** | Préservation visuelle paragraphes Amazon — `\n\n` → `<br>&nbsp;<br>` contre compression `<br>` multiples par messagerie acheteur. |
| **PH134-A-AUTOPILOT-DRAFT-BILLING-01** | Correction facturation brouillons autopilot en safe mode — poids `autopilot_draft` et débit KBActions sur chemin `DRAFT_GENERATED`. |
| **PH135-A-AUTOPILOT-BEHAVIOR-CONTROL-01** | **Comportement Autopilot prévisible** — seuil confiance abaissé, prompt « draft-first », brouillons basse confiance, conversion actions none vers reply/escalade. |
| **PH135-B-EMAIL-PIPELINE-SANITY-01** | **Sanity canal email** — dédup inbound (hash + fenêtre), Reply-To sortant via adresses inbound/tenant, stripping citations body. |
| **PH135-C-AMAZON-INBOUND-THREAD-SANITY-01** | **Fils Amazon inbound** — nettoyage relay (`stripAmazonRelay`), dédup sur `amazon-forward`, règles anti-placeholders `[Votre Nom]` dans prompt Autopilot. |
| **PH135-D-INBOUND-BODY-AND-EMAIL-DELIVERY-TRUTH-RECOVERY-01** | Vérité body inbound (ordre strip vs MIME) et réponses Autopilot — création `outbound_deliveries` dans `executeReply` pour livraison réelle. |
| **PH135-E-REPLYTO-SUBJECT-ENCODING-01** | Reply-To Amazon SMTP avec repli adresse inbound validée + décodage MIME sujets (charset ISO/Latin1/UTF-8, pliage RFC 2047). |

---

## PH136 à PH139 (GitOps, Carrier, IA Consistency, Signature)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH136-A-GITOPS-ROLLBACK-HARDENING-01** | **Durcissement GitOps** — scripts rollback et détection drift, alignement manifests/cluster, règles pour éviter `kubectl set image` comme source de vérité. |
| **PH136-B-MULTI-CARRIER-TRACKING-AGGREGATOR-01** | **Chaîne providers suivi** (17track + fallback UPS) pour alimenter statut transporteur au-delà d'un seul adaptateur vendeur. |
| **PH137-B-AUTOPILOT-SMART-RESPONSE-PROD-VALIDATION** | Validation PROD « smart response » autopilot sur 10 conversations réelles (scénarios, confiance, safety, logs API/worker). |
| **PH137-B-UX-DRAFT-CLARITY-01** | **Refonte UX bandeau brouillon IA** — libellés clairs, envoi 1 clic, modifier/ignorer, toasts, auto-scroll, intégration envoi direct depuis inbox. |
| **PH137-C-IA-CONSISTENCY-ENGINE-01** | **Moteur cohérence IA** — module `shared-ai-context.ts` pour unifier prompt, contexte commande/tracking et règles entre Autopilot et Aide IA (PRO). |
| **PH138-E-BILLING-FALLBACK-UX-01** | UX de secours — si `change-plan` échoue (pas d'abonnement Stripe), redirection vers checkout au lieu de dead-end pour tenants exempt ou sans souscription. |
| **PH138-F-BILLING-STATE-SYNC-AND-EFFECTIVE-PLAN-UX** | Synchro UI après retour Stripe (refetch), réglage auto mode IA selon plan, CTA « Agent KeyBuzz » activable. |
| **PH138-I-AUTOPILOT-SETTINGS-CTA-FINALIZATION-01** | Finalisation CTA Paramètres IA — correction boutons désactivés bloquant clics sur cartes verrouillées, audit zones cliquables. |
| **PH138-K-STRIPE-CHECKOUT-ENFORCEMENT-FINAL-01** | **Enforcement Stripe** — activation Agent KeyBuzz uniquement via session Checkout (plus d'update directe), affichage prix, préservation trial. |
| **PH139-SIGNATURE-IDENTITY-01** | **Identité et signature unifiées** — champs `tenant_settings`, `signatureResolver`, injection worker/outbound, prompts IA et endpoints/UI. DEV validé. |
| **PH139-B-AGENT-DEFAULT-AND-CLEAN-MODEL-01** | Création automatique agent admin « client » à l'inscription tenant, blocage type `keybuzz`, résolution signature avec fallback nom agent admin actif. |
| **PH139-C-SIGNATURE-UX-FINALIZATION-01** | Onglet Paramètres « Signature » (aperçu live, `resolvedPreview`, sauvegarde autonome), priorité settings → agent → tenant, route BFF/API. |

---

## PH140 (Agents, Escalation, Invitation, Supervision)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH140-A-ESCALATION-REAL-FLOW-01** | **Escalade exploitable** — `escalation_target`, statut `escalated`, assignation qui repasse en open/in_progress, filtre `?escalated=true`, inbox filtre « Escalade » et bouton « Prendre en charge ». |
| **PH140-B-AGENT-WORKSPACE-01** | **Workspace agent** — `AgentWorkbenchBar` (4 vues), `ConversationActionBar` (actions 1 clic), badges et en-tête conversation, correction affichage Unicode. |
| **PH140-C-AGENT-AUTH-ROLE-SCOPING-01** | **Mode agent sécurisé** — garde BFF sur POST `/api/agents`, menu « Paramètres » masqué pour agents, toast RBAC, bandeau « Mode Agent ». |
| **PH140-D-AGENT-INVITE-ACTIVATE-LOGIN-UNIFICATION-01** | Unifier agents et space-invites — création agent déclenche email invitation, statuts UI, redirection post-accept vers `/inbox` pour agents. |
| **PH140-E-AGENT-INVITE-AUTH-TENANT-RECOVERY-01** | Corriger E2E invite — bypass `check-email` si invite, redirect post-OTP vers `/invite/continue`, cookies `currentTenantRole`, routes publiques `/api/invite`. |
| **PH140-F-AGENT-INVITE-E2E-TRACE-RECOVERY-01** | Réparation acceptation invitation (middleware `/api/space-invites` public, flux simplifié `login?invite_token`, `credentials: 'include'`, logs BFF). |
| **PH140-G-REAL-BROWSER-INVITE-LOOP-ROOT-CAUSE-01** | Élimination boucle login post-OTP — `SessionProvider` stale → `window.location.href`, retry `getSession()` sur `/invite/continue`, fix `magic/start` (APP_ENV). |
| **PH140-H-OTP-GATED-REAL-INVITE-FIX-01** | Post-invite OTP — reload complet post-accept (`window.location.href`), backend lie `agents.user_id` à l'accept, sidebar agent correcte. |
| **PH140-I-INVITE-LOGIN-UX-POLISH-01** | **UX invitation** — `GET /space-invites/resolve`, email prérempli, bandeau tenant, titre dédié, envoi OTP automatique. |
| **PH140-J-AGENT-HARD-ACCESS-LOCKDOWN-01** | **Verrouillage dur agent** — garde `ClientLayout` + middleware `/no-access` + 403 API admin-only pour empêcher accès direct pages réservées. |
| **PH140-K-ASSIGNMENT-SEMANTICS-01** | Clarification assignation — libellés « Remettre en file », « Prendre en charge », « Responsable », filtres workbench, `canTakeOver` sans blocage IA. |
| **PH140-L-AGENT-SUPERVISION-01** | **Panneau supervision** — KPIs file/assignés/escalade/résolus, alertes, charge par agent, lien vers inbox filtré. |
| **PH140-M-SLA-PRIORITY-01** | **Priorité/urgence** par ancienneté dernier message (badges +4h/+24h), tri prioritaire par défaut, KPIs enrichis supervision. |

---

## PH141 à PH142 (Agent Limits, Feature Registry, Validation)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH141-A-AGENT-LIMITS-GATING-01** | **Plafonds agents par plan** (client + API 403 `AGENT_LIMIT_REACHED`), compteur, masquage bouton Ajouter, bannière upsell. |
| **PH141-B-AGENT-LIMITS-ALIGNMENT-01** | Alignement limites produit (Pro 2, Autopilot 3), exclusion agent KeyBuzz du plafond interne, `KEYBUZZ_AGENT_LIMITS` + type `keybuzz`. |
| **PH141-F-AI-CONTEXT-UTILIZATION-01** | Correction prompts IA pour utiliser infos déjà présentes dans le message client — règle prioritaire + ajustements `shared-ai-context`/`ai-assist-routes`. |
| **PH142-O0-FEATURE-REGISTRY-TRUTH-MATRIX-01** | **Audit documentaire** — matrice de vérité et registre features (36–40 features, domaines, `FEATURE_TRUTH_MATRIX`/`feature_registry.json`) — sans code. |
| **PH142-O1-FEATURE-MATRIX-EXECUTION-01** | **Exécution validation produit** sur matrice en DEV (API/DB/scripts/navigateur) — statuts GREEN/ORANGE/RED pour 40 features. |
| **PH142-O1.2-MULTI-PLAN-VALIDATION-01** | Validation multi-plans (STARTER, PRO, AUTOPILOT) — tests navigateur réels et API/DB pour comparer comportements selon plan. |
| **PH142-O2-FIX-CRITICAL-RED-ONLY-01** | **Correctifs P0 uniquement** — RBAC agent (middleware Docker + cookie `currentTenantRole`), scripts bastion `pre-prod-check-v2`/`assert-git-committed`, cohérence import `shared-ai-context` Autopilot. |

---

## PH143 (Rebuild, Francisation, Release Line, Agents, IA, PROD Promotion)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH143-B-BILLING-PLANS-ADDON-01** | **Reconstruction facturation** (BILL-01 à BILL-06) sur branches rebuild — CTAs upgrade, addon Agent KeyBuzz, `hasAgentKeybuzzAddon`, gating, `billing/current` cohérent. |
| **PH143-C-AGENTS-RBAC-REBUILD-01** | **Reconstruction agents + RBAC** — limites par plan, rejet type `keybuzz`, cookie/middleware, routes admin bloquées pour agents, Dockerfile avec `middleware.ts`. |
| **PH143-E.5-AUTOPILOT-ESCALATION-VISIBILITY-AND-HANDOFF-01** | Exposition `escalation_target` en API et UI (badge/panel escalade), alignement avec prise en main « Prendre la main ». |
| **PH143-E.6-AUTOPILOT-REPLY-PLUS-ESCALATION-FIX-01** | Correction bug : valider brouillon escalade envoyait message sans déclencher escalade réelle — logique dans `POST /autopilot/draft/consume` pour `ESCALATION_DRAFT`. |
| **PH143-E.8-UNIFY-HUMAN-ACTION-SEND-PATHS-01** | **Filet serveur** sur `POST /conversations/:id/reply` — détection « fausses promesses » et escalade auto pour tous chemins d'envoi (pas seulement consume). |
| **PH143-FR-FULL-FRANCISATION-01** | **Francisation client** — séquences Unicode → caractères accentués, mojibake, derniers libellés anglais → français, sans changement logique métier. |
| **PH143-FR.2-FULL-FRANCISATION-AND-REGRESSION-FIX-01** | Suite francisation + correctifs UX — accents/unicode résiduels, playbooks visibles (guard `tenantId`), suppression option « Agent KeyBuzz » au formulaire création. |
| **PH143-FR.3-IA-ACCENTS-AND-PLAYBOOKS-REAL-FIX-01** | Accents manquants `LearningControlSection` (et FAQ pricing) ; playbooks via `getPlaybooks(overrideTenantId)` pour utiliser tenant session plutôt que localStorage. |
| **PH143-FR.4-PLAYBOOKS-REAL-SESSION-FIX-01** | Correction page Playbooks vide (Total 0) — merge `main` pour `usePlaybooks` + API ; diagnostic `useTenantId()` vide car `tenantId` absent du JWT. |
| **PH143-R1-RELEASE-LINE-RECOVERY-AUDIT-01** | **Audit ligne release** — cartographie branches, identification base saine (`e87da0e`), contamination Studio via merge FR.4, delta DEV/PROD/branche polluée. |
| **PH143-R2-CLEAN-RELEASE-BRANCH-REBUILD-01** | **Reconstruction release propre** — branche `release/client-v3.5.220` depuis base saine, cherry-picks playbooks (API backend + engine), `.dockerignore` anti-Studio. |
| **PH143-R3-CLEAN-RELEASE-PROD-PROMOTION-01** | **Promotion PROD contrôlée** — image `v3.5.220-ph143-clean-release-prod` depuis `release/client-v3.5.220`, GitOps, rollout cluster, pre-prod check. |
| **PH143-ROLLBACK-URGENT-01** | Rollback urgence DEV client `v3.5.219` → `v3.5.218` via script GitOps ; PROD inchangée. |
| **PH143-J-GLOBAL-VALIDATION-REBUILD-01** | **Validation globale finale** ligne rebuild PH143 (matrice rejouée en DEV) — 38/40 GREEN, synthèse par domaine et deltas vs PH143-G/H/I. |
| **PH143-J.1-FINAL-PROD-GATE-01** | **Gate PROD finale** — tests exhaustifs chemins critiques envoi (promesses/consume), pre-prod-check 25/25, avant autorisation PROD. |
| **PH143-UX-ESCALATION-CLEAN-01** | Refonte UX escalade — remplacement gros encadré par badge compact inline, tooltip au clic, alignement Metronic. |
| **PH143-UX-REGRESSION-GATE-01** | Gate non-régression DEV (API, routes, accessibilité, données) avant promotion PROD des polish UX Escalade et Mon travail. |
| **PH143-UX-PROD-PROMOTION-01** | Déploiement PROD deux polish UX (badge escalade + filtres « Mon travail »), image `v3.5.215-ph143-ux-polish-prod`, API inchangée. |
| **PH143-AGENTS-INVITE-RECOVERY-01** | **Audit flux agents/invitations** — chaîne UI→BFF→API, limites plan, bypass billing-exempt, linkage `agents.user_id` à l'acceptation. |
| **PH143-AGENTS-R2-FULL-MODULE-TRUTH-RECOVERY-01** | Réalignement module Agents sur vérité historique — quota x/y, bannière limite, `sendAgentInvite` auto, renvoi invite, statuts détaillés. |
| **PH143-AGENTS-R3-REAL-FLOW-AND-QUOTA-FIX-01** | Correction compteur quota erroné, flux invitation renvoyant vers « Créer un compte », message upsell trompeur AUTOPILOT ; règles métier quota + redirection `login?invite_token=`. |
| **PH143-AGENTS-R4-HISTORICAL-FLOW-RESTORE-01** | **Restauration règles validées historiquement** — quota avec owner inclus total, libellés simples, suppression écrans/flows inventés en R3 pour invite. |
| **PH143-AGENTS-R5-REAL-OTP-SESSION-COMPLETION-01** | **Correction post-OTP invités** — `window.location.href` vers `/invite/continue` pour forcer reload et que `SessionProvider` lise la session après OTP. |
| **PH143-IA-TRUTH-GATE-01** | **Audit vérité fonctionnelle IA** — phases sources, matrice 24 features (code, API, DB, UI), statuts GREEN/ORANGE/RED. Résultat : 23 GREEN / 1 ORANGE / 0 RED. |
| **PH143-P2-PROD-PROMOTION-AGENTS-IA-01** | **Promotion PROD finale** client + API `v3.5.224-ph143-agents-ia-prod` (client SHA R5, API avec linkage `user_id` accept invite), smoke tests, GitOps. |

---

# Partie 2 — Phases PH- (préfixe tiret)

## PH-AI

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AI-N1-ENTERPRISE-01** | **Objectif** : Remplacer le mock par LiteLLM Enterprise. **Livrables** : Tracking tokens/€ par tenant ; budgets quotidiens par plan (starter/pro/autopilot) ; UI consommation IA ; guardrails (global_kill_switch, tenant_kill_switch, budget check) ; rollback documenté. Architecture : checkGuardrails() → getTenantPlan() avant chaque appel LLM. |
| **PH-AI-ASSIST-RELIABILITY-01** | **Fiabilité `POST /ai/assist`** (inbox) — le backend renvoyait `status: "limited"` avec fallback alors que le client ne traitait que `success` → affichage « Impossible de générer ». Correction chemin frontend et logique associée. |

---

## PH-AMAZON / PH-AMZ

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AMAZON-OUTBOUND-SOURCE-OF-TRUTH-LOCK-01** | **Source de vérité** outbound Amazon. `determineAmazonProvider.ts` : channel≠amazon → erreur ; orderId → SPAPI_ORDER ; sinon SMTP. Jest 6 suites, healthcheck, 9 deliveries E2E 250 OK. |
| **PH-AMAZON-OUTBOUND-TRUTH-03** | **Problème** : Messages outbound (sans commande) acceptés par Postfix (250 OK) mais invisibles dans Seller Central. **Cause** : From `noreply@keybuzz.io` non reconnu par Amazon. **Solution** : `getInboundAddressForTenant()` — récupération adresse inbound validée depuis `inbound_addresses` ; envoi depuis cette adresse pour que Amazon associe au vendeur. Worker modifié, validation 9 deliveries visibles Seller Central. |
| **PH-AMZ-UI-STATE-TRUTH-01** | Bouton « Synchroniser Amazon » (Commandes) affiché uniquement si canal Amazon réellement `active` (croisement `/api/channels/list`), et plus sur la base `has_messages` / statut trompeur. |
| **PH-AMZ-INBOUND-ADDRESS-TRUTH-01** | Audit et correctifs génération/affichage adresse inbound Amazon — provisioning API (compat), sync `tenant_channels`, BFF URL correcte, appel post-OAuth pour activer le flux. |

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

## PH-AUTH

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AUTH-RATELIMIT-AUDIT-CONSOLIDATION-01** | Audit et consolidation limites (ingress NGINX, etc.) — assouplissement ciblé (client, API, admin) pour supprimer les 503 post-login dus au rate limiting trop strict, validation DEV/PROD. |
| **PH-AUTH-SESSION-LOGOUT-STABILITY-02** | **Stabilité session/déconnexion** — réduction déconnexions intempestives (keep-alive, JWT, double polling), simplification flux logout et allègement chaîne d'appels au chargement. |

---

## PH-AUTOPILOT

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-AUTOPILOT-UI-FEEDBACK-01** | Visibilité actions autopilot dans l'inbox (historique filtré par conversation, badge, injection suggestion) — uniquement frontend / DEV, sans toucher au moteur backend. |

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

## PH-DEPLOY / PH-EMERGENCY / PH-ENV

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-DEPLOY-PROCESS-ROOTCAUSE-01** | **5 causes** : SCP sans commit ; COPY . . Dockerfile ; pas verify-image ; release gate absent ; ArgoCD PROD cassé. Timeline PH117/signup-fix. |
| **PH-EMERGENCY-CLIENT-RESTORE-DEV-PROD** | v3.5.60-signup-fix cassé (menu, focus, paywall). Snapshots ; GitOps ; DEV→v3.5.59, PROD→v3.5.58. Service restored. |
| **PH-ENV-ALIGNMENT-STRICT-01** | **Réalignement strict DEV/PROD** — commits code « dirty » du bastion dans Git, puis build et déploiement images API + client `v3.5.120-env-aligned-*` depuis dépôt propre. |

---

## PH-I18N

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-I18N-ESCAPED-STRINGS-01** | **Problème** : "\u00e9" affiché littéralement (ex: "activ\u00e9"). **Cause** : Séquences Unicode dans JSX text. **Fix** : Remplacer par caractères UTF-8 directs (é). |

---

## PH-INBOUND / PH-INFRA

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-INBOUND-TRUTH-VERIFY-02** | Vérification adresse inbound ecomlg-001 : `amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io`. Preuves logs MX (status=sent), mail-core (INBOUND_RECEIVED). SEULE valide pour ecomlg-001/Amazon/FR. |
| **PH-INBOUND-PIPELINE-TRUTH-04** | **Correction pipeline inbound E2E** — déclenchement autopilot depuis backend après création conversation, alignement casse marketplace pour `lastInboundAt`, mise à jour bonne base pour adresses inbound. |
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

## PH-MAIL (compléments)

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-MAIL-AUDIT-DELIVERABILITY-01** | **Audit délivrabilité** `@keybuzz.io` — TLS, MX, SPF, réputation IP, alignement From/myorigin. Liste causes critiques (spam/reports). |
| **PH-MAIL-FIX-DELIVERABILITY-02A** | Correctifs « safe » sur `mail-core-01` — TLS Let's Encrypt (`mail.keybuzz.io`), alignement `myorigin`/Return-Path ; SPF `-all` en action DNS manuelle ; MX/pipeline Amazon non modifiés. |
| **PH-MAIL-OBSERVE-07** | **Validation réelle délivrabilité** (SPF/DKIM/DMARC/TLS OK sur Gmail) ; constat que messages peuvent finir en spam à cause de la réputation historique domaine/IP. |

---

## PH-ONBOARDING

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-ONBOARDING-OAUTH-CONTINUITY-01** | **Problème** : OAuth Google → /register affiche formulaire email + bouton Google → clic boucle vers /login. **Fixes** : callback vers /register avec ?oauth=google ; Register détecte session OAuth, saute formulaire. |
| **PH-ONBOARDING-OAUTH-PLAN-CONTINUITY-01** | **Problème** : Plan choisi + "Continuer Google" → redirect /login, plan perdu. **Cause** : /api/auth/signin sans provider → NextAuth pages.signIn. **Fix** : signIn('google', { callbackUrl }) avec plan/cycle/step. |
| **PH-ONBOARDING-PLAN-STATE-CONTINUITY-01** | **Problème** : Mode annuel + plan PRO + "Continuer Google" → retour sélection forfait, annuel perdu. **Cause** : redirect NextAuth compare url relative avec baseUrl → startsWith échoue. **Fix** : resolved = url.startsWith('/') ? baseUrl+url : url ; + sessionStorage fallback plan/cycle. |

---

## PH-ORDER-IMPORT

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-ORDER-IMPORT-TENANT-ISOLATION-CRITICAL-02** | **Correction critique fuite commandes Amazon entre tenants** — credentials Vault partagées + `import-one`/`sync-all` sans vérification canal Amazon actif. Isolation rétablie. |

---

## PH-PLAYBOOKS

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-PLAYBOOKS-TRUTH-RECOVERY-01** | **Audit technique** — constat que playbooks stockés uniquement en `localStorage` (pas de vérité serveur), risques liés à `lastTenantId` / page vide. |
| **PH-PLAYBOOKS-BACKEND-MIGRATION-02** | **Unification Playbooks** — page `/playbooks` passe du localStorage à l'API/backend (`ai_rules`) via hook unifié pour aligner UI, inbox et moteur IA. |

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
| **PH-PROD-ALIGNMENT-FROM-DEV-01** | **Audit et alignement PROD sur DEV** — images, routes API/BFF, bundles PH122–PH125, variables d'environnement pour valider comportement attendu en production. |

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

## PH-STUDIO

| Phase | Description — éléments essentiels |
|-------|----------------------------------|
| **PH-STUDIO-02-DEV-BOOTSTRAP** | **Bootstrap DEV Studio** — images Docker (`keybuzz-studio`/`keybuzz-studio-api`), déploiement K8s (`keybuzz-studio-dev`, `keybuzz-studio-api-dev`), ingress, secrets Vault/DB, tests runtime `/health`. |
| **PH-STUDIO-04C-PROD-AUTH-RUNTIME-FIX** | Correctif auth PROD — frontend PROD appelait API DEV à cause de `NEXT_PUBLIC_STUDIO_API_URL` figé au build. Rebuild image PROD avec URL API PROD pour lever échec CORS. |
| **PH-STUDIO-07A-STUDIO-AI-GATEWAY-TEXT-ONLY** | **Passerelle IA Studio texte uniquement** — module `ai/` dédié (providers OpenAI/Anthropic, fallback heuristique), secrets Vault `studio-llm`, routes Fastify et table `ai_generations`. |
| **PH-STUDIO-07C-CLIENT-INTELLIGENCE** | **Moteur Client Intelligence** — profils, sources, analyse LLM (ICP, SWOT, etc.), stratégie marketing et génération automatique d'idées vers table `ideas`. |
| **PH-STUDIO-07D-QUALITY-ENGINE** | **Quality Engine SaaS-ready** — prompts dynamiques v3 (FR), anti-généricité et scoring, réinjection client, feedback utilisateur, templates par workspace, badges qualité UI. |
| **PH-STUDIO-08-FEEDBACK-LEARNING** | **Boucle feedback et apprentissage** — tables `learning_adjustments`/`workspace_ai_preferences`, catégorisation feedback, injection « ADAPTATIONS APPRISES » dans prompts suivants. |
| **PH-STUDIO-08.2-KEYBUZZ-GROWTH-INIT** | Parcours « growth » KeyBuzz en DEV — profil enrichi, sources, analyse, stratégie, idées et contenu pour valider E2E les briques 07A/07C/07D et 08. |
| **PH-STUDIO-08.2B-PROD-VALIDATION** | **Validation PROD post-promotion** — images/pods, schéma DB (migration 009), cohérence données KeyBuzz et usage réel UI sur `studio.keybuzz.io`. |

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

*Document généré à partir des rapports présents dans `keybuzz-infra/docs`. Dernière mise à jour : 1er mars 2026.*
