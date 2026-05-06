# PH-SAAS-T8.12AP — Media Buyer Brief Product Parity Truth Audit

> **Date** : 6 mai 2026
> **Environnement** : READ-ONLY GLOBAL
> **Type** : Audit vérité produit + roadmap Linear
> **Priorité** : P0
> **Source** : `KeyBuzz_MediaBuyer_Full.pdf` (31 pages)

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `05d171d1` | M (3 fichiers hors scope) | OK |
| keybuzz-infra | `main` | `40cfc64` | Untracked docs | OK |

- Audit read-only confirmé
- Aucun runtime touché
- Aucun build/deploy
- PDF accessible et extrait (31 pages, 940 lignes texte)

---

## Extraction PDF

- **Pages** : 31
- **Méthode** : Read tool (conversion PDF→texte automatique)
- **Limites** : quelques tableaux avec colonnes fusionnées, caractères accentués remplacés par ASCII
- **Extraction** : complète, aucune page manquante

### Table des sections

| Pages | Section | Sujet |
|---|---|---|
| 1 | 3 promesses fondamentales | Automatisation, protection marges, gain de temps |
| 1 | Le problème | SAV Amazon = cauchemar |
| 2 | La solution | KeyBuzz copilote intelligent |
| 3-5 | Fonctionnalités clés | Centralisation + IA 30+ moteurs + protection marges |
| 6-7 | Détection fraude 180j | Classification acheteur, patterns abus |
| 7-8 | Intelligence livraison | Vérification tracking automatique |
| 8-9 | Retours/garanties/preuves | Photos, garantie fournisseur, alertes qualité |
| 9-10 | ADN vendeur | Apprentissage style, 6 dimensions |
| 10-11 | Règles marketplace | Amazon, Cdiscount, Fnac, Octopia, Mirakl |
| 11 | Score de confiance 8 critères | Policy, coût, fraude, acheteur, ADN, marketplace, escalade, autopilot |
| 11-12 | Garde-fous | 4 niveaux autonomie, plafonds, journal audit |
| 12-13 | Mémoire long terme | 12 types signaux, 6 domaines |
| 13 | Graphe connaissances | Relations acheteurs/produits/fournisseurs/transporteurs |
| 14-16 | Auto-amélioration | Taux acceptation, remboursements évités, dérive |
| 16-18 | 15 playbooks SAV | 15 scénarios, plan min par playbook |
| 19-23 | Plans/pricing | Starter/Pro/Autopilot/Enterprise, tableau comparatif |
| 24-25 | CTA + différenciation | Essai gratuit, comparaison vs chatbot |
| 26-27 | Angles publicitaires | Meta, Google, TikTok ads |
| 28-29 | 5 promesses fortes + objections | Claims marketing + réponses objections |
| 30-31 | Récap technique IA + expansion | 25+ capacités listées, marketplaces futures |

---

## Matrice promesses produit

### Légende statuts

- **PROUVÉ** : fonctionnalité existe et fonctionne en PROD
- **PARTIEL** : le concept existe mais incomplet vs promesse PDF
- **ABSENT** : non implémenté
- **MARKETING À CORRIGER** : claim trompeur vs réalité SaaS
- **ROADMAP** : stratégiquement prévu mais pas encore développé

| ID | Promesse PDF | Surface | Réalité observée | Preuve | Statut | Risque | Action |
|---|---|---|---|---|---|---|---|
| P01 | Centralisation messages Amazon | Inbox | Inbox tripane avec conversations Amazon, messages, filtres | `InboxTripane.tsx`, conversations API | **PROUVÉ** | Faible | RIEN |
| P02 | Commande + articles affichés | Inbox/Orders | Panneau latéral commande, articles, montant, date | `OrderSidePanel.tsx`, orders API | **PROUVÉ** | Faible | RIEN |
| P03 | Suivi livraison temps réel | Orders | Statut livraison, transporteur, code suivi, lien tracking | `orders/page.tsx`, `trackingSource` types | **PARTIEL** | Moyen | CREER_LINEAR |
| P04 | Historique client complet | Inbox | Conversation complète visible, pas d'historique multi-commandes acheteur | Inbox conversation detail | **PARTIEL** | Moyen | CREER_LINEAR |
| P05 | 30+ moteurs IA spécialisés | API | ~20 engines TypeScript dans `keybuzz-api/src/services/` | `strategicResolutionEngine.ts`, `aiQualityScoringEngine.ts`, etc. | **PARTIEL** | Moyen | CORRIGER_COPY_MARKETING |
| P06 | Analyse ton et intention | API/IA | Prompt layers IA analysent le ton, pas de moteur NLP dédié séparé | Prompts IA, `aiAssist` routes | **PROUVÉ** | Faible | RIEN |
| P07 | Historique acheteur 180j / fraude | API | `buyerReputation`, `fraudRisk`, `abuseRisk` dans engines | `strategicResolutionEngine.ts`, `autopilotGuardrails.ts` | **PARTIEL** | Élevé | CREER_LINEAR |
| P08 | Livraison temps réel (2 sec) | API/Client | Tracking dans orders, pas d'analyse instantanée "2 secondes" | Orders tracking, 17TRACK backend | **PARTIEL** | Moyen | CORRIGER_COPY_MARKETING |
| P09 | Analyse preuves/photos IA | API | Routes API `returns/analysis` existent, PAS de parcours UI dédié | `app/api/ai/returns/analysis` | **PARTIEL** | Élevé | CREER_LINEAR |
| P10 | Score confiance 8 critères | API | `aiQualityScoringEngine.ts` : 8 dimensions pondérées | policy_alignment, cost_efficiency, fraud_protection, buyer_context, seller_strategy, marketplace_compliance, escalation_logic, autopilot_safety | **PROUVÉ** | Faible | RIEN |
| P11 | Score confiance affiché UI | Client | Pourcentage affiché sur suggestions dans inbox | `AISuggestionsPanel.tsx` (ConfidenceIndicator) | **PROUVÉ** | Faible | RIEN |
| P12 | Estimation coûts EUR par option | PDF | Le PDF montre des coûts (0€, ~5€, ~10€, etc.). L'UI montre des KBActions, PAS des EUR | `PlaybookSuggestionBanner.tsx` (kbaCost) | **ABSENT** | Élevé | CREER_LINEAR |
| P13 | Protection anti-remboursement | API | `refundProtectionLayer`, `responseStrategy`, `policyPosture` platform-aware | Doctrine seller-first, engines stratégiques | **PROUVÉ** | Faible | RIEN |
| P14 | Classification acheteur (fiable/standard/à risque/abusif) | API | `buyerReputation` dans engines, MAIS pas visible dans l'inbox UI | Engines backend seulement | **PARTIEL** | Élevé | CREER_LINEAR |
| P15 | Détection fraude multi-commandes 90-180j | API | Logique dans engines (`fraudRisk`, `abuseRisk`, cross-tenant), données 90j mentionnées | `crossTenantIntelligenceEngine.ts` | **PARTIEL** | Moyen | AUDIT_TECHNIQUE_DEDIE |
| P16 | Intelligence livraison automatique | Backend | 17TRACK intégré backend, webhooks, carrier status | `trackingWebhook.routes.ts`, `test-17track-api.js` | **PARTIEL** | Moyen | CREER_LINEAR |
| P17 | Gestion retours/garanties structurée | API/Client | Routes API retours existent, PAS de parcours UI dédié retours | `app/api/returns/*` | **PARTIEL** | Élevé | CREER_LINEAR |
| P18 | Alertes qualité SKU (7+ retours) | API | Concept dans engines (`longTermMemoryEngine`), pas d'alerte UI | Backend seulement | **ABSENT** | Moyen | ROADMAP |
| P19 | Ouverture dossier garantie fournisseur | Client/API | Supplier cases existent (`supplier_cases` table, `SupplierPanel.tsx`) | SAV fournisseur fonctionnel | **PROUVÉ** | Faible | RIEN |
| P20 | ADN vendeur (6 dimensions) | API | `extractSellerDNA` dans `strategicResolutionEngine.ts` : `refundTolerance`, `warrantyPreference`, etc. | Engine backend | **PARTIEL** | Moyen | CREER_LINEAR |
| P21 | IA apprend vos décisions (validation/modification) | API/Client | `LearningControlSection` dans settings (standard/adaptive/expert), feedback backend | `AITab.tsx`, `ai.learning.ts` | **PARTIEL** | Moyen | AUDIT_TECHNIQUE_DEDIE |
| P22 | "80%+ des cas validés en 1 clic" | Marketing | Aucune preuve métrique ; stats suggestions existent dans settings | `AISuggestionStats.tsx` | **MARKETING À CORRIGER** | Élevé | CORRIGER_COPY_MARKETING |
| P23 | Règles marketplace auto (Amazon, Cdiscount, Fnac, Octopia, Mirakl) | API | `policyPosture` platform-aware (Amazon, Octopia strict, email/Shopify flexible) | PH-API-T8.12P, T8.12Q | **PARTIEL** | Moyen | CORRIGER_COPY_MARKETING |
| P24 | Garde-fous 4 niveaux autonomie | API | `aiGovernanceEngine.ts` : `MANUAL_ONLY` → `FULL_AUTOPILOT` | Engine governance | **PROUVÉ** | Faible | RIEN |
| P25 | Journal audit complet | Client | AI Journal page, filtres, détail événement, snapshot JSON | `ai-journal/page.tsx` | **PROUVÉ** | Faible | RIEN |
| P26 | Mémoire long terme 12 types signaux | API | `longTermMemoryEngine.ts` : table `ai_long_term_memory`, `getMemoryGraph` | Engine backend | **PROUVÉ** | Faible | RIEN |
| P27 | Graphe connaissances | API | `knowledgeGraphEngine.ts` : requêtes SQL croisées, blocs contexte | Engine backend | **PROUVÉ** | Faible | RIEN |
| P28 | Auto-amélioration IA | API | `aiSelfImprovementEngine.ts`, `aiDashboardEngine.ts` | Engines backend | **PARTIEL** | Faible | RIEN |
| P29 | 15 playbooks SAV prêts | Client/API | 5 starters client, système CRUD complet, triggers variés | `playbooks.service.ts`, `usePlaybooks.ts` | **PARTIEL** | Élevé | CREER_LINEAR |
| P30 | Playbooks activables/désactivables/personnalisables | Client | Toggle, création, édition fonctionnels | `usePlaybooks.ts` (togglePlaybook) | **PROUVÉ** | Faible | RIEN |
| P31 | Starter 97€/mois | Client/Website | Plan Starter à 97€ configuré | `planCapabilities.ts` | **PROUVÉ** | Faible | RIEN |
| P32 | Pro 297€/mois | Client/Website | Plan Pro à 297€ configuré | `planCapabilities.ts` | **PROUVÉ** | Faible | RIEN |
| P33 | Autopilot 497€/mois | Client/Website | Plan Autopilot à 497€ configuré | `planCapabilities.ts` | **PROUVÉ** | Faible | RIEN |
| P34 | Enterprise sur devis | Client | Plan Enterprise dans `planCapabilities.ts` (prix null) | Config client | **PARTIEL** | Moyen | ROADMAP |
| P35 | Prix annuels (78€/238€/398€) | Website | À vérifier sur website | Website pricing page | A AUDITER | Moyen | AUDIT_TECHNIQUE_DEDIE |
| P36 | 14 jours essai gratuit | Client | Trial 14j fonctionnel (`is_trial`, `trial_ends_at`) | tenant_metadata, TrialBanner | **PROUVÉ** | Faible | RIEN |
| P37 | "Sans carte bancaire" | Marketing | Stripe Checkout est requis pour les plans payants. Le trial ne semble pas exiger de CB | Signup flow, billing routes | A AUDITER | Élevé | AUDIT_TECHNIQUE_DEDIE |
| P38 | "5 minutes / Amazon connecté c'est fait" | Marketing | OAuth fonctionne mais nécessite ensuite config Seller Central inbound | Guide inbound AO.10 | **MARKETING À CORRIGER** | Élevé | CORRIGER_COPY_MARKETING |
| P39 | "Amazon disponible, autres arrivent" | Marketing | Amazon + Octopia (Cdiscount/Fnac) + Shopify connectables | Channels page, Octopia adapter | **MARKETING À CORRIGER** | Moyen | CORRIGER_COPY_MARKETING |
| P40 | KBActions Starter = 0 / Pro = 1000 / Autopilot = 3500 | Client | Configuré dans `planCapabilities.ts` | kbActionsMonthly par plan | **PROUVÉ** | Faible | RIEN |
| P41 | "Équipe KeyBuzz gère les cas complexes" (Autopilot) | Marketing | Pas d'équipe KeyBuzz SAV externe documentée | Aucune preuve d'équipe humaine | **ABSENT** | Critique | DECISION_LUDOVIC |
| P42 | "10 secondes par message" | Marketing | Pas de métrique prouvée | Aucune | **MARKETING À CORRIGER** | Moyen | CORRIGER_COPY_MARKETING |
| P43 | "Remboursements évités en EUR" | Client | Aucun dashboard ROI/économies en EUR | Dashboard = KPI support uniquement | **ABSENT** | Élevé | CREER_LINEAR |
| P44 | Canaux : Mirakl | Marketing | PAS dans le produit actuel | Ni dans channels, ni dans API | **ABSENT** | Moyen | ROADMAP |
| P45 | "70-80% des messages en automatique" (Autopilot) | Marketing | Autopilot existe mais aucune preuve de ce taux | Aucune métrique | **MARKETING À CORRIGER** | Élevé | CORRIGER_COPY_MARKETING |

---

## Audit 12 blocs critiques

### Bloc A — Centralisation messages + commandes + tracking

| Point | Verdict |
|---|---|
| Inbox réelle | **PROUVÉ** — tripane fonctionnel, filtres, canaux |
| Lien conversation/order | **PROUVÉ** — `OrderSidePanel.tsx` dans inbox |
| Tracking Amazon | **PROUVÉ** — statut livraison, transporteur, code suivi |
| 17TRACK | **PARTIEL** — backend uniquement, pas de branding UI |
| Pas de re-demande numéro si connu | **PROUVÉ** — contexte commande injecté dans prompts IA |

### Bloc B — IA 30+ moteurs

| Point | Verdict |
|---|---|
| Engines réels comptés | ~20 fichiers `*Engine.ts` dans `keybuzz-api/src/services/` |
| Prompt layers | Prompts versionnés, multi-couche |
| "30+" wording | **MARKETING À CORRIGER** — ~20 engines, pas 30+ |
| Moteurs distincts vs fonctions internes | Beaucoup sont des modules fonctionnels d'un même pipeline, pas des "moteurs" indépendants |

**Recommandation** : dire "20+ moteurs spécialisés" ou "IA multi-couche avec 20+ modules d'analyse"

### Bloc C — Protection anti-remboursement / seller-first

| Point | Verdict |
|---|---|
| `refundProtectionLayer` | **PROUVÉ** — doctrine seller-first codée |
| `responseStrategy` platform-aware | **PROUVÉ** — `policyPosture` par canal |
| Règles Amazon/Octopia | **PROUVÉ** — bonus risque Amazon +10, Octopia +5 |
| Blocage refund-first | **PROUVÉ** — remboursement = dernier recours |

### Bloc D — Détection fraude/abus 90-180 jours

| Point | Verdict |
|---|---|
| `buyerReputation` | **EXISTE** dans engines backend |
| Risk scoring | **EXISTE** dans `autopilotGuardrails.ts` |
| Historique multi-commandes | **PARTIEL** — logique cross-tenant, mais 180j non prouvé strictement |
| Visibilité UI | **ABSENT** — non affiché dans inbox |
| Utilisation dans prompt IA | **PROUVÉ** — signaux injectés dans contexte |

### Bloc E — Intelligence livraison

| Point | Verdict |
|---|---|
| 17TRACK | **PARTIEL** — backend intégré, pas d'UI branded |
| tracking_events | **PROUVÉ** — types carrier dans orders |
| Prompt IA livraison | **PROUVÉ** — contexte commande/tracking injecté |
| "Colis livré mais client dit non" | **PARTIEL** — logique dans engines, pas de workflow UI dédié |

### Bloc F — Retours, garanties, preuves, photos

| Point | Verdict |
|---|---|
| Demande de preuves | **PARTIEL** — via messages inbox, pas de workflow structuré |
| Pièces jointes | **PROUVÉ** — upload/download attachments |
| Analyse photo réelle | **PARTIEL** — API route existe, pas de parcours UI |
| Garantie fournisseur | **PROUVÉ** — supplier cases, dossier SAV |
| Alerte qualité SKU | **ABSENT** — concept dans memory engine, pas d'UI |
| Coût estimé | **ABSENT** — pas d'estimation EUR dans UI |

### Bloc G — ADN vendeur / apprentissage

| Point | Verdict |
|---|---|
| Feedback utilisateur | **PROUVÉ** — `LearningControlSection`, modes standard/adaptive/expert |
| Validation/modification suggestions | **PROUVÉ** — suggestions acceptables/modifiables |
| Mémoire style vendeur | **PARTIEL** — `extractSellerDNA` dans engine, apprentissage pas évident en UI |
| Seuils remboursement | **PARTIEL** — dans engines, pas configurable par le vendeur en UI |
| Persistance | **PROUVÉ** — tables `learning_adjustments`, `ai_feedback` |

### Bloc H — Score confiance 8 critères

| Point | Verdict |
|---|---|
| Calcul | **PROUVÉ** — `aiQualityScoringEngine.ts`, 8 dimensions pondérées |
| Critères | **PROUVÉ** — policy, coût, fraude, acheteur, ADN, marketplace, escalade, autopilot |
| Affichage UI | **PROUVÉ** — % dans suggestions panel |
| Journal IA | **PARTIEL** — types incluent `confidence_score` mais pas affiché en colonne |
| Alternatives écartées | **ABSENT** en UI — pas de comparaison visible |

### Bloc I — Garde-fous / Autopilot

| Point | Verdict |
|---|---|
| Auto-send | **PROUVÉ** — Autopilot mode dans settings |
| maxMode | Non trouvé dans le code |
| Plan gates | **PROUVÉ** — `planCapabilities.ts`, `FeatureGate` |
| Human validation | **PROUVÉ** — modes supervised/autonomous |
| Agent KeyBuzz (équipe externe) | **ABSENT** — aucune équipe humaine externe documentée |
| Cases high risk | **PROUVÉ** — escalade automatique, `EscalationPanel.tsx` |
| Audit log | **PROUVÉ** — Journal IA |

### Bloc J — Mémoire long terme / graphe connaissances

| Point | Verdict |
|---|---|
| Tables mémoire | **PROUVÉ** — `ai_long_term_memory` |
| Produits/fournisseurs/transporteurs | **PROUVÉ** — knowledge graph engine |
| Clusters retours | **PARTIEL** — logique engine, pas d'UI dédiée |
| Patterns fraude | **PROUVÉ** — dans engines |
| Relation graph | **PROUVÉ** — `knowledgeGraphEngine.ts` |

### Bloc K — 15 playbooks SAV

| Point | Verdict |
|---|---|
| Playbooks existants | **PARTIEL** — 5 starters client, système CRUD complet |
| Activables/désactivables | **PROUVÉ** |
| Personnalisables | **PROUVÉ** — création/édition/triggers |
| Différences plan | **PARTIEL** — `hasBasicPlaybooks` / `hasAdvancedPlaybooks` dans capabilities |
| Templates vs IA | **PROUVÉ** — triggers, conditions, actions |
| "15 scénarios prêts" | **PARTIEL** — 5 visibles client, potentiellement plus via API seed |

### Bloc L — Plans/pricing/claims marketing

| Point | Verdict |
|---|---|
| Prix réels | **PROUVÉ** — 97/297/497€ dans planCapabilities |
| Trial réel | **PROUVÉ** — 14j, AUTOPILOT_ASSISTED |
| CB requise | **A AUDITER** — Stripe utilisé mais trial peut ne pas exiger CB |
| "5 minutes" | **MARKETING À CORRIGER** — OAuth + config Seller Central inbound |
| "Amazon connecté c'est fait" | **MARKETING À CORRIGER** — nécessite config inbound dans SC |
| KBActions | **PROUVÉ** — 0/1000/3500 par plan |
| Agent KeyBuzz (Autopilot) | **ABSENT** — pas d'équipe humaine SAV externe |
| Connecteurs disponibles | **PARTIEL** — Amazon + Octopia/Cdiscount + Shopify; Fnac branding mais pas connecteur dédié; Mirakl absent |

---

## Classification Linear

### Ticket parent proposé

**KEY-AP : MEDIA BUYER BRIEF PRODUCT PARITY AUDIT**
- Source : `KeyBuzz_MediaBuyer_Full.pdf` (31 pages)
- Rapport : `PH-SAAS-T8.12AP-MEDIA-BUYER-BRIEF-PRODUCT-PARITY-TRUTH-AUDIT-01.md`

### Sous-tickets P0 (claim marketing faux ou dangereux)

| Titre | Priorité | Pourquoi | Scope | Acceptance criteria |
|---|---|---|---|---|
| **AP.1 — Marketing copy corrections (claims faux/trompeurs)** | P0 | 8+ claims PDF ne correspondent pas à la réalité SaaS. Risque légal et confiance client. | PDF/Website/Ads copy | Chaque claim listé a une version corrigée validée |
| **AP.2 — "Équipe KeyBuzz gère vos cas" (Autopilot) vérité** | P0 | Le PDF promet une équipe humaine KeyBuzz. Si elle n'existe pas, c'est une promesse fausse majeure. | Décision produit/marketing | Ludovic tranche : équipe réelle à créer OU claim à retirer |

### Sous-tickets P1 (fonctionnalité vendue mais absente/partielle)

| Titre | Priorité | Pourquoi | Scope | Acceptance criteria |
|---|---|---|---|---|
| **AP.3 — Buyer reputation / fraud score visible dans Inbox** | P1 | Le PDF promet une classification acheteur (fiable/standard/à risque/abusif). L'engine existe mais rien n'est affiché en UI. | Client inbox | Badge/indicateur réputation acheteur visible dans conversation detail |
| **AP.4 — ROI / économies dashboard (EUR, pas KBActions)** | P1 | Le PDF montre des économies en EUR. Aucun dashboard ROI n'existe. | Client dashboard | Métriques : remboursements évités, coût moyen résolution, économie estimée |
| **AP.5 — 15 playbooks SAV seed complet** | P1 | Le PDF promet 15 scénarios prêts. Seuls 5 starters sont dans le client. | API + Client | 15 playbooks préconfigurés, alignés sur les 15 du PDF |
| **AP.6 — Estimation coûts résolution en EUR dans Inbox** | P1 | Le PDF montre un tableau coûts (0€, ~5€, ~10€, etc.). L'UI n'affiche que des KBActions. | Client inbox | Coût estimé en EUR par option de résolution visible |
| **AP.7 — Photo/evidence analysis UI workflow** | P1 | Le PDF promet "analyse des preuves". L'API existe mais aucun parcours UI. | Client inbox | Workflow : upload photo → analyse IA → résultat affiché |

### Sous-tickets P2 (fonctionnalité stratégique roadmap)

| Titre | Priorité | Pourquoi | Scope | Acceptance criteria |
|---|---|---|---|---|
| **AP.8 — Quality alerts SKU (7+ retours/mois)** | P2 | Le PDF promet des alertes qualité produit. Le concept existe dans memory engine mais pas d'UI. | Client + API | Alertes proactives quand un SKU dépasse un seuil de retours |
| **AP.9 — Seller ADN visible + configurable en UI** | P2 | Le PDF promet 6 dimensions d'apprentissage. L'engine existe mais n'est pas configurable par le vendeur. | Client settings | Visualisation ADN + ajustement préférences vendeur |
| **AP.10 — Enterprise plan complet** | P2 | Le PDF mentionne un plan Enterprise. `planCapabilities` a un placeholder mais pas de flux réel. | Billing + sales | Flux devis, onboarding dédié, canaux illimités |
| **AP.11 — Mirakl connector** | P2 | Le PDF promet Mirakl. Non présent dans le produit. | Backend + Client | Connecteur Mirakl fonctionnel |
| **AP.12 — 17TRACK UI / branding livraison** | P2 | 17TRACK est intégré backend mais invisible côté UI. | Client orders/inbox | Indicateur 17TRACK ou carrier detail visible |

### Sous-tickets P3 (polish, documentation)

| Titre | Priorité | Pourquoi | Scope | Acceptance criteria |
|---|---|---|---|---|
| **AP.13 — Journal IA confidence score colonne** | P3 | Le score confiance existe en types mais n'est pas affiché dans la grille. | Client ai-journal | Colonne score confiance dans la liste du journal |
| **AP.14 — Alternatives écartées visibles** | P3 | Le PDF promet "vous voyez les alternatives écartées". Non visible en UI. | Client inbox | Section alternatives dans le détail suggestion |
| **AP.15 — Annual pricing vérification** | P3 | Le PDF annonce des prix annuels (78/238/398€). À vérifier sur le website. | Website pricing | Cohérence prix annuels website vs PDF |

---

## Claims marketing à corriger avant usage acquisition

| # | Claim PDF | Risque | Version recommandée |
|---|---|---|---|
| C01 | "30+ moteurs d'analyse" | Inflation — ~20 engines réels | "Plus de 20 modules IA spécialisés" ou "IA multi-couche avec 20+ moteurs d'analyse" |
| C02 | "Sans carte bancaire" | À vérifier — Stripe est utilisé | Si trial sans CB confirmé : garder. Sinon : "Essai gratuit 14 jours" (retirer "sans CB") |
| C03 | "5 minutes / Amazon connecté c'est fait" | Trompeur — config Seller Central requise après OAuth | "Connexion Amazon en quelques minutes. Configuration guidée pas à pas." |
| C04 | "Amazon disponible aujourd'hui. Les autres arrivent très prochainement." | Inexact — Octopia/Cdiscount + Shopify déjà disponibles | "Amazon et Cdiscount/Fnac (via Octopia) disponibles. Shopify en cours. D'autres marketplaces arrivent." |
| C05 | "80%+ des cas validés en 1 clic" | Non prouvé — aucune métrique | Retirer le pourcentage ou le qualifier : "La majorité des suggestions sont validées en 1 clic" |
| C06 | "70-80% des messages en automatique" (Autopilot) | Non prouvé — aucune métrique | "L'Autopilot gère automatiquement les cas standards" (sans pourcentage) |
| C07 | "10 secondes par message" | Non prouvé | "Répondez en quelques secondes grâce aux suggestions IA" |
| C08 | "Équipe KeyBuzz gère les cas complexes" (Autopilot) | Probablement faux — aucune équipe humaine documentée | **DÉCISION LUDOVIC** : si pas d'équipe → "L'IA escalade les cas complexes vers vos agents seniors" |
| C09 | Mirakl / Darty comme marketplaces | Non disponibles | Retirer Mirakl et Darty de la liste, garder dans "à venir" |
| C10 | Tableau coûts EUR (0€, ~5€, ~10€, etc.) | Non affiché dans l'UI | Garder en marketing aspirationnel mais préciser "estimation IA" — ou implémenter P06 |
| C11 | "L'IA analyse la photo" / "vérifie la cohérence" | API existe mais pas de workflow UI | "L'IA peut analyser les pièces jointes envoyées par les clients" (moins affirmatif) |
| C12 | "15 playbooks SAV prêts à l'emploi dès le jour 1" | 5 starters visibles, pas 15 | Implémenter AP.5 OU corriger : "Playbooks SAV préconfigurés et personnalisables" |

---

## Roadmap recommandée

| Phase | Objectif | Priorité | Dépendances | Linear |
|---|---|---|---|---|
| **AP.1** | Marketing copy correction (8+ claims) | P0 | Décision Ludovic sur C08 (équipe KeyBuzz) | AP.1 |
| **AP.2** | Décision "Équipe KeyBuzz" Autopilot | P0 | Business decision | AP.2 |
| **AP.5** | 15 playbooks SAV seed complet | P1 | API playbook seed service | AP.5 |
| **AP.3** | Buyer reputation / fraud score UI inbox | P1 | Engine backend déjà prêt | AP.3 |
| **AP.6** | Coûts EUR résolution dans inbox | P1 | Engine stratégique déjà prêt | AP.6 |
| **AP.4** | Dashboard ROI / économies | P1 | Données résolution, engine dashboard | AP.4 |
| **AP.7** | Photo/evidence analysis UI | P1 | API returns/analysis déjà prête | AP.7 |
| **AP.9** | Seller ADN visible + configurable | P2 | Engine backend déjà prêt | AP.9 |
| **AP.8** | Quality alerts SKU | P2 | Memory engine + notification system | AP.8 |
| **AP.12** | 17TRACK UI livraison | P2 | Backend 17TRACK déjà intégré | AP.12 |
| **AP.10** | Enterprise plan complet | P2 | Billing + sales process | AP.10 |
| **AP.11** | Mirakl connector | P2 | Backend adapter development | AP.11 |
| **AP.13** | Journal IA confidence column | P3 | Client-only | AP.13 |
| **AP.14** | Alternatives écartées visibles | P3 | Engine données déjà disponibles | AP.14 |
| **AP.15** | Annual pricing vérification | P3 | Website check | AP.15 |

---

## Stop conditions rencontrées

1. **P41 — "Équipe KeyBuzz gère les cas complexes"** : ce claim est potentiellement le plus dangereux. Si aucune équipe humaine SAV externe n'existe, promettre une "gestion complète" en Autopilot est faux. **DÉCISION_LUDOVIC requise**.

2. **P37 — "Sans carte bancaire"** : nécessite audit technique du signup flow Stripe pour confirmer si le trial ne demande pas de CB.

3. **P35 — Prix annuels** : à vérifier sur le website actuel.

---

## Confirmation 0 runtime change

- 0 code modifié
- 0 build
- 0 deploy
- 0 mutation DB
- 0 mutation Stripe/billing/CAPI/tracking
- 0 changement runtime
- 0 modification Website/Client/API/Admin
- 0 données test créées

---

## Verdict

### GO PARTIEL — LINEAR REVIEW REQUIRED

- Audit complet : 45 promesses analysées, 12 blocs audités
- Matrice complète avec preuves et statuts
- 12 claims marketing à corriger identifiés
- 15 tickets Linear proposés (2 P0, 5 P1, 5 P2, 3 P3)
- Roadmap ordonnée
- **2 décisions Ludovic requises** avant création Linear P0 :
  - C08 : "Équipe KeyBuzz" Autopilot — vrai ou faux ?
  - C02 : "Sans carte bancaire" — vrai ou faux ?
- Aucun runtime touché

**MEDIA BUYER BRIEF PRODUCT PARITY AUDIT COMPLETE — PROMISES MAPPED AGAINST REAL SAAS — CRITICAL GAPS IDENTIFIED — MARKETING CLAIMS TO CORRECT LISTED — ROADMAP READY — NO CODE — NO BUILD — NO DEPLOY — NO MUTATION**
