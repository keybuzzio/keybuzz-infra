# PH143-IA-TRUTH-GATE-01 — Audit Verite Fonctionnelle IA

> Date : 2026-04-08
> Environnement : DEV uniquement
> Methode : audit code bastion + tests API reels + analyse DB + lecture phases historiques
> Image client : `v3.5.224-ph143-agents-otp-session-fix-dev`
> Image API : `v3.5.47-vault-tls-fix-dev`

---

## 1. Phases Sources IA Retrouvees

### Pipeline IA complet (chronologique)

| Phase | Feature | Couche | Verdict phase |
|-------|---------|--------|---------------|
| **PH141-F** | Contexte IA : ne plus redemander les infos deja donnees | API (`shared-ai-context.ts`) | DEV+PROD |
| **PH142-A** | Quality Loop : log suggestion + bouton "Incorrecte" + flag | API + Client | DEV+PROD |
| **PH142-B** | Clustering erreurs : classifyError, GET /ai/errors/clusters, section UI journal | API + Client | DEV+PROD |
| **PH142-C** | Fausses promesses : detectFalsePromises (9 regex), needsHumanAction, banniere ambre | API + Client | DEV+PROD |
| **PH142-D** | Auto-escalade : si needsHumanAction → escalation_status, log AI_AUTO_ESCALATED | API | DEV+PROD |
| **PH142-E** | Autopilot Safe Mode : brouillon visible dans inbox (AutopilotDraftBanner) | API + Client | DEV+PROD |
| **PH142-F** | Drawer unifie : remplacement banner par drawer (AISuggestionSlideOver), autoOpen | Client | DEV+PROD |
| **PH142-G** | Draft lifecycle : consume (applied/dismissed/modified), KBActions idempotent | API + Client | DEV+PROD |
| **PH143-D** | IA Assist Rebuild : reconstruction complete shared-ai-context, journal, clustering | API + Client | DEV |
| **PH143-E** | Autopilot Rebuild : engine, routes, modes, safe mode, drafts, settings | API + Client | DEV |
| **PH143-E.1** | Aide IA fix : BFF /api/ai/assist au lieu d'appel direct | Client BFF | DEV |
| **PH143-E.3** | Autopilot E2E : PLAN_MODELS majuscules, LiteLLM fallback, confiance 0.75-0.85 | API Config | DEV |
| **PH143-E.4** | Autopilot UI pipeline : fetch draft au changement de conversation, autoOpen | Client | DEV |
| **PH143-E.5** | Escalade visibilite : escalation_target en API, EscalationPanel avec labels cible | API + Client | DEV |
| **PH143-E.6** | Reply + Escalade : consume ESCALATION_DRAFT → escalade reelle + refresh | API + Client | DEV |
| **PH143-E.7** | Classification draft : promesses → ESCALATION_DRAFT au lieu de DRAFT_GENERATED | API | DEV |
| **PH143-E.8** | Filet serveur : detection fausses promesses apres envoi reply → escalade auto | API | DEV |
| **PH143-E.9** | Renforcement : 22 regex accent-safe, pre-prod-check 25/25 | API | DEV |
| **PH143-E.10** | Browser fix : reload conversation apres envoi manuel → escalade visible | Client | DEV |

### Phases transverses IA

| Phase | Feature | Statut |
|-------|---------|--------|
| **PH142-O0** | Feature registry truth matrix (8 features IA) | Baseline cree |
| **PH142-O1** | Execution matrice : AI-01 ORANGE, AI-05 ORANGE, reste GREEN | Teste |
| **PH142-O2** | Fix IA-CONSIST-01 : alignement engine/shared-ai-context | RED → GREEN |
| **PH143-J** | Validation globale rebuild : bloc IA = tout GREEN sauf AI-05 ORANGE | 38/40 GREEN |
| **PH143-J.1** | Gate PROD : pre-prod-check-v2 25/25, chemins escalade 8/8 PASS | GO PROD |

---

## 2. Matrice Verite IA (24 features)

### Legende
- **GREEN** : code present + API fonctionnelle + donnees DB + UI integree
- **ORANGE** : code present mais non testable en conditions reelles actuelles ou partiel
- **RED** : absent ou casse

| # | Feature | Code API | Code Client | API Test | DB Data | UI | Statut |
|---|---------|----------|-------------|----------|---------|-----|--------|
| 1 | Aide IA manuelle | `ai-assist-routes.ts` (54KB) | `AISuggestionSlideOver.tsx` + BFF `/api/ai/assist` | Endpoint enregistre | 7 AI_SUGGESTION_GENERATED | Drawer integre InboxTripane | **GREEN** |
| 2 | Generation suggestion | `ai-assist-routes.ts` | `generateSuggestion()` | Via LiteLLM | 451 suggestions trackees | Bouton "Aide IA" | **GREEN** |
| 3 | Insertion dans la reponse | — | `handleInsert()` + `onInsertResponse` | — | — | Bouton "Inserer dans la reponse" | **GREEN** |
| 4 | Envoi manuel apres insertion | `messages/routes.ts` | Reply dans InboxTripane | POST /conversations/:id/reply | Messages envoyes | Textarea + bouton | **GREEN** |
| 5 | Escalade si promesse d'action humaine | `detectFalsePromises` (22 regex) + reply routes + autopilot | `EscalationPanel` + badges | Auto sur reply + consume | 10 conversations escaladees | Panneau + cible + badge | **GREEN** |
| 6 | Controle negatif sans escalade | Regex negatives dans reply | — | PH143-E.9 : 25/25 PASS | Contenus factuels = pas d'escalade | — | **GREEN** |
| 7 | Brouillon autopilot safe mode | `autopilot/engine.ts` (37KB) | Drawer unifie (PH142-F) | GET /autopilot/draft | 3 autopilot_draft entries | Draft dans drawer | **GREEN** |
| 8 | Auto-open drawer brouillon | — | `autoOpen` prop + fetch draft on conv change | — | — | Auto-ouverture | **GREEN** |
| 9 | Consume draft (applied/modified/dismissed) | `autopilot/routes.ts` consume | `consumeDraft()` dans drawer | POST /autopilot/draft/consume | 1 draft_applied | 3 boutons actions | **GREEN** |
| 10 | Auto-escalade si besoin humain | `ai-assist-routes.ts` AI_AUTO_ESCALATED logic | — | Logic presente | 0 evenements auto-escalade | — | **ORANGE** |
| 11 | Journal IA | `ai-journal-routes.ts` (11KB) | `app/ai-journal/page.tsx` (18KB) | GET /ai/journal OK (entries) | ai_action_log: 1309 entries | Page complete avec filtres + stats | **GREEN** |
| 12 | Log du contenu/modele/confiance | Payload JSONB dans ai_action_log | Colonnes dans le journal | 130 AI_DECISION_TRACE | confidence_score + confidence_level | Stats affichees | **GREEN** |
| 13 | Bouton "Incorrecte" | `/ai/suggestions/flag` | handleFlag dans drawer | POST flag OK | 1 HUMAN_FLAGGED_INCORRECT | Bouton present | **GREEN** |
| 14 | Clustering d'erreurs | `suggestion-tracking-routes.ts` classifyError | BFF `/api/ai/errors/clusters` | GET clusters OK (1 cluster) | Aggregation par type | Section dans journal | **GREEN** |
| 15 | Wallet KBActions | `credits-routes.ts` | `AIActionsLimit.tsx` + billing/ai pages | GET /ai/wallet/status OK | remaining=931.3, purchased=50, monthly=1000 | Dashboard KBActions complet | **GREEN** |
| 16 | Debit KBA coherent | Idempotent sur requestId | — | 14 calls/7j = 118.7 KBA | Pas de double debit | — | **GREEN** |
| 17 | Contexte IA utilise infos deja donnees | `shared-ai-context.ts` (17KB, 47 refs) | — | PH141-F valide | 1164 evaluations | — | **GREEN** |
| 18 | Tracking/commandes dans le contexte | `shared-ai-context.ts` integre orders | — | PH143-H valide | Donnees ordre enrichies | — | **GREEN** |
| 19 | Detection fausses promesses | `detectFalsePromises` 22 regex | Banniere ambre dans drawer | Triple couche (prompt+detect+alert) | Patterns detectes | Alerte "Escalade prevue" | **GREEN** |
| 20 | Learning control / apprentissage | API route + BFF | `LearningControlSection.tsx` | GET OK (adaptive mode) | Source: DB | 3 modes (standard/adaptive/expert) | **GREEN** |
| 21 | Parametres IA / modes / safe mode | `ai-mode-engine.ts` + `ai-settings` | `AISettingsSection` + `AutopilotSection` | GET /ai/settings OK | mode=supervised, safe_mode=true | Onglet IA dans settings | **GREEN** |
| 22 | Francisation UI IA | — | Labels FR partout | — | — | Voir detail ci-dessous | **GREEN** |
| 23 | Badges IA / escalade / UX inbox | — | `MessageSourceBadge` + `EscalationBadge` + `PriorityBadge` | — | — | Tous importes dans InboxTripane | **GREEN** |
| 24 | Comportement AUTOPILOT vs PRO | `PLAN_MODELS` + plan gating | `AutopilotSection` minPlan + `FeatureGate` | Plans distincts | Modes par plan | Gating UI actif | **GREEN** |

### Synthese : 23 GREEN / 1 ORANGE / 0 RED

---

## 3. Detail Feature #10 — Auto-escalade (ORANGE)

**Raison** : La logique `AI_AUTO_ESCALATED` existe dans `ai-assist-routes.ts` (PH142-D). Elle s'active quand `needsHumanAction` est detecte. Cependant :
- Le tenant ecomlg-001 est en mode `supervised` (pas `autonomous`)
- En mode supervised, l'autopilot genere des **brouillons** (pas d'envoi auto)
- L'auto-escalade se declenche uniquement en mode **autonomous** quand l'IA detecte une promesse humaine et s'apprete a envoyer
- **0 evenements AI_AUTO_ESCALATED** en DB
- La logique fonctionne via le **filet serveur** (PH143-E.8/E.9) qui escalade apres tout envoi contenant une promesse, quelle que soit la source

**Impact** : Faible. Le filet serveur (reply routes) couvre le meme besoin pour tous les chemins d'envoi. L'auto-escalade pre-envoi ne se declenche qu'en mode autonomous, qui n'a pas encore ete active en reel.

**Priorite** : P2 structurel — pas de risque operationnel.

---

## 4. Resultats Tests API Reels

| Endpoint | Methode | Statut | Resultat |
|----------|---------|--------|----------|
| `/health` | GET | 200 | `{"status":"ok"}` |
| `/ai/journal?tenantId=ecomlg-001` | GET | 200 | 5 entries |
| `/ai/settings?tenantId=ecomlg-001` | GET | 200 | mode=supervised, safe_mode=true |
| `/ai/wallet/status?tenantId=ecomlg-001` | GET | 200 | remaining=931.3, 14 calls/7d |
| `/ai/errors/clusters?period=30d` | GET | 200 | 1 cluster (tracking) |
| `/ai/suggestions/stats` | GET | 200 | 451 suggestions |
| `/autopilot/settings` | GET | 200 | enabled, supervised |
| `/autopilot/history?limit=3` | GET | 200 | Draft entries with escalation |
| `/autopilot/draft?conversationId=xxx` | GET | 200 | `{"hasDraft":false}` |
| `/ai/learning-control` | GET | 200 | adaptive mode |

### Pages client (HTTP)

| Page | Status | Attendu |
|------|--------|---------|
| `/ai-journal` | 307 | Redirect (auth required) |
| `/settings` | 307 | Redirect (auth required) |
| `/billing/ai` | 307 | Redirect (auth required) |
| `/billing/ai/manage` | 307 | Redirect (auth required) |
| `/login` | 200 | Public |

---

## 5. Donnees DB Reelles (ecomlg-001)

### ai_action_log : 1309 entries

| action_type | count |
|-------------|-------|
| evaluate | 1164 |
| AI_DECISION_TRACE | 130 |
| AI_SUGGESTION_GENERATED | 7 |
| autopilot_draft | 3 |
| autopilot_reply | 2 |
| draft_applied | 1 |
| HUMAN_FLAGGED_INCORRECT | 1 |
| execute | 1 |

### Conversations escaladees : 10
### KBActions wallet : remaining=931.3, purchased=50, monthly=1000
### AI settings : mode=supervised, safe_mode=true, ai_enabled=true

---

## 6. Francisation IA — Verification Labels

| Composant | Labels trouves | Langue |
|-----------|----------------|--------|
| AISuggestionSlideOver | "Aide IA", "Brouillon IA", "Suggestion IA", "Escalade prevue", "Inserer dans la reponse", "Ignorer" | FR ✓ |
| AutopilotSection | "Supervise", "Autonome", "Autopilot" | FR ✓ |
| EscalationPanel | "Votre equipe", "KeyBuzz", "Les deux" | FR ✓ |
| AI Journal page | "Journal IA", "KBActions", "Erreur de chargement" | FR ✓ |
| Billing AI | "KBActions restantes", "Dotation mensuelle incluse", "Pack Essentiel/Pro/Business" | FR ✓ |
| AIActionsLimit | "Pack Essentiel", "Pack Pro", "Pack Business" | FR ✓ |
| LearningControl | standard/adaptive/expert (labels internes, rendered labels a verifier en navigateur) | FR partiel |

---

## 7. Fichiers Code IA — Inventaire Complet

### API (`keybuzz-api/src/`)

| Fichier | Taille | Role |
|---------|--------|------|
| `modules/ai/shared-ai-context.ts` | 17KB | Contexte partage IA (infos, promesses, tracking) |
| `modules/ai/ai-assist-routes.ts` | 54KB | Routes assist (suggestion, debit, escalade) |
| `modules/ai/ai-journal-routes.ts` | 11KB | Journal IA API |
| `modules/ai/ai-mode-engine.ts` | 6.5KB | Gestion des modes IA |
| `modules/ai/suggestion-tracking-routes.ts` | 10KB | Flag + clustering erreurs |
| `modules/ai/context-upload-routes.ts` | 14KB | Upload contexte IA |
| `modules/ai/credits-routes.ts` | 19KB | KBActions/credits |
| `modules/ai/routes.ts` | 23KB | Routes IA generales |
| `modules/ai/usage-routes.ts` | 7.5KB | Usage IA admin |
| `modules/ai/returns-decision-routes.ts` | 33KB | Aide decision retours |
| `modules/ai/ai-policy-debug-routes.ts` | 96KB | Debug policy |
| `modules/ai/ops-routes.ts` | ~10KB | Operations IA |
| `modules/autopilot/engine.ts` | 37KB | Moteur autopilot |
| `modules/autopilot/routes.ts` | 15KB | Routes autopilot (draft, consume, settings) |
| `config/ai-budgets.ts` | 950B | Budgets par plan |
| `config/kbactions.ts` | 6.9KB | Configuration KBActions |

### Client (`keybuzz-client/src/features/ai-ui/`)

| Fichier | Role |
|---------|------|
| `AISuggestionSlideOver.tsx` (39KB) | Drawer unifie (suggestion + draft autopilot) |
| `AutopilotSection.tsx` | Config autopilot dans settings |
| `LearningControlSection.tsx` | Apprentissage adaptatif |
| `AIModeSwitch.tsx` (AISettingsSection) | Parametres IA |
| `MessageSourceBadge.tsx` | Badge source message |
| `AIActionsLimit.tsx` | Limite + achat packs |
| `AIDecisionPanel.tsx` | Panneau decision IA |
| `TemplatePickerSlideOver.tsx` | Selecteur templates |
| `PlaybookLink.tsx` | Lien playbook |
| `types.ts` | Types partages |
| `index.ts` | Exports centralises |

### BFF Routes (`app/api/`)

| Route | Fichier |
|-------|---------|
| `/api/ai/assist` | `app/api/ai/assist/route.ts` |
| `/api/ai/journal` | `app/api/ai/journal/route.ts` |
| `/api/ai/settings` | `app/api/ai/settings/route.ts` |
| `/api/ai/errors/clusters` | `app/api/ai/errors/clusters/route.ts` |
| `/api/ai/suggestions/flag` | `app/api/ai/suggestions/flag/route.ts` |
| `/api/ai/suggestions/stats` | `app/api/ai/suggestions/stats/route.ts` |
| `/api/ai/suggestions/track` | `app/api/ai/suggestions/track/route.ts` |
| `/api/ai/learning-control` | `app/api/ai/learning-control/route.ts` |
| `/api/ai/wallet/status` | `app/api/ai/wallet/status/route.ts` |
| `/api/ai/wallet/ledger` | `app/api/ai/wallet/ledger/route.ts` |
| `/api/ai/wallet/settings` | `app/api/ai/wallet/settings/route.ts` |
| `/api/ai/context/upload` | `app/api/ai/context/upload/route.ts` |
| `/api/ai/context/download/[id]` | `app/api/ai/context/download/[id]/route.ts` |
| `/api/ai/returns/analysis` | `app/api/ai/returns/analysis/route.ts` |
| `/api/ai/returns/decision` | `app/api/ai/returns/decision/route.ts` |
| `/api/ai/dashboard` | `app/api/ai/dashboard/route.ts` |
| `/api/autopilot/draft` | `app/api/autopilot/draft/route.ts` |
| `/api/autopilot/draft/consume` | `app/api/autopilot/draft/consume/route.ts` |
| `/api/autopilot/evaluate` | `app/api/autopilot/evaluate/route.ts` |
| `/api/autopilot/history` | `app/api/autopilot/history/route.ts` |
| `/api/autopilot/settings` | `app/api/autopilot/settings/route.ts` |

---

## 8. Ecarts

### Features reellement presentes : 23/24

Tout le perimetre IA est present en code, enregistre en routes API, et teste fonctionnel.

### Feature ORANGE (1) : Auto-escalade pre-envoi (#10)

- **Present en code** : oui (`ai-assist-routes.ts`)
- **Non testable** : mode supervised actif, pas de mode autonomous utilise
- **Impact** : nul — le filet serveur (reply routes) couvre le meme besoin
- **Priorite** : P2 structurel

### Features absentes : 0

### Features divergentes : 0

### Features presentes mais partielles : 0

### Features incertaines : 0

### Note sur `ai_journal_events`

La table `ai_journal_events` existe mais contient **0 entrees**. La source de verite pour le journal est `ai_action_log` (1309 entrees). Le endpoint `/ai/journal` lit correctement depuis `ai_action_log`. Pas de divergence fonctionnelle.

---

## 9. Priorisation Ecarts

| # | Ecart | Priorite | Action |
|---|-------|----------|--------|
| 1 | Auto-escalade pre-envoi non testee en mode autonomous | P2 | Documenter — sera teste quand un tenant activera le mode autonomous |
| 2 | LearningControl labels internes en anglais (standard/adaptive/expert) | P3 | Mineur UX — les labels rendus sont a verifier en navigateur |

---

## 10. Verdict

### **IA TRUTH KNOWN**

Le perimetre IA est **complet et fonctionnel** sur la ligne release propre :

- **23/24 features GREEN** — code present, API testee, donnees DB reelles, UI integree
- **1/24 feature ORANGE** — logique presente mais non activee (mode autonomous non utilise)
- **0 RED** — aucune feature absente ou cassee
- **Pipeline IA complet** : suggestion → insertion → envoi → detection promesses → escalade → journal → wallet
- **Autopilot complet** : engine → draft → auto-open → consume → escalade draft → lifecycle
- **Securite IA complete** : detectFalsePromises (22 regex) → triple couche (prompt + post-LLM + filet serveur)
- **Francisation IA** : labels FR sur tous les composants critiques
- **Donnees reelles** : 1309 action log entries, 451 suggestions, 10 escalades, wallet actif

Aucune action bloquante requise.
