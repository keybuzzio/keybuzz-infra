# PH143-A — Safe Rebuild Preparation

> Date : 2026-04-05
> Phase : PH143-A-SAFE-REBUILD-PREP-01
> Type : preparation de reconstruction controlee
> Environnement : Git / bastion / DEV

---

## 1. Resume executif

Preparation complete pour une reconstruction controlee du produit. L'etat actuel est fige (tags de sauvegarde pushes sur les 3 repos), PH131-B.2 est identifie avec precision (commits exacts), et des branches de reconstruction sont creees sans toucher a `main` ni a l'environnement DEV.

| Action | Statut |
|---|---|
| Etat actuel fige (backup tags) | **FAIT** |
| PH131-B.2 identifie (client + API) | **FAIT** |
| Branches rebuild creees | **FAIT** |
| Comparaison base vs actuel | **FAIT** |
| Plan rebuild bloc par bloc | **FAIT** |

---

## 2. Etat actuel fige

### keybuzz-client (bastion)

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD | `1a7c51d` — PH148-O3: sync AgentWorkbenchBar types for build compat |
| Tag backup | `backup/pre-ph143-client-20260301` → `1a7c51d` |
| Image DEV deployee | `ghcr.io/keybuzzio/keybuzz-client:v3.5.194-fix-remaining-red-dev` |

### keybuzz-api (bastion)

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD | `5eccf7e` — PH148-O3: fix supervision SQL text/uuid cast |
| Tag backup | `backup/pre-ph143-api-20260301` → `5eccf7e` |
| Image DEV deployee | `ghcr.io/keybuzzio/keybuzz-api:v3.5.194b-fix-remaining-red-dev` |

### keybuzz-infra (bastion)

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD | `5b932a0` — PH142-N-gitops-update-client-v3.5.191-restore-ph138-dev |
| Tag backup | `backup/pre-ph143-infra-20260301` → `5b932a0` |

### Tags pushes vers GitHub

```
keybuzz-client → backup/pre-ph143-client-20260301
keybuzz-api    → backup/pre-ph143-api-20260301
keybuzz-infra  → backup/pre-ph143-infra-20260301
```

---

## 3. PH131-B.2 identifie

### Client

| Element | Valeur |
|---|---|
| Commit | `8542bf0` |
| Date | 2026-03-25 23:54:23 UTC |
| Message | `PH131-B.2: rename Autopilot to Pilotage IA, STARTER upsell preview with locked features` |
| Branche rebuild | `rebuild/ph143-client` → pointe sur `8542bf0` |
| Image a l'epoque | `ghcr.io/keybuzzio/keybuzz-client:v3.5.106-ph131-starter-upsell-dev` |

### API

| Element | Valeur |
|---|---|
| Commit | `06f833b` |
| Date | 2026-03-25 21:27:24 UTC |
| Message | `PH131-B: fix await getPool` |
| Branche rebuild | `rebuild/ph143-api` → pointe sur `06f833b` |

**Note** : PH131-B.2 etait une phase **client-only** (UX/wording). L'API au moment de PH131-B.2 etait au commit `06f833b` (PH131-B).

### Preuve

```
Client: git log --oneline 8542bf0 -1
8542bf0 PH131-B.2: rename Autopilot to Pilotage IA, STARTER upsell preview with locked features

API: git log --oneline 06f833b -1
06f833b PH131-B: fix await getPool
```

Source documentaire : `keybuzz-infra/docs/PH131-B.2-AUTOPILOT-STARTER-UPSELL-03-REPORT.md`

---

## 4. Branches de reconstruction

| Repo | Branche | Point de depart | Pushee |
|---|---|---|---|
| keybuzz-client | `rebuild/ph143-client` | `8542bf0` (PH131-B.2) | GitHub OK |
| keybuzz-api | `rebuild/ph143-api` | `06f833b` (PH131-B) | GitHub OK |

**Principe** :
- `main` reste **intouchee** sur les deux repos
- L'environnement DEV reste deploye sur les images actuelles
- Tout le travail de reconstruction se fera sur les branches `rebuild/ph143-*`
- Chaque bloc = un ou plusieurs commits sur ces branches

---

## 5. Comparaison haut niveau : PH131-B.2 vs etat actuel

### Delta global

| Repo | Commits depuis PH131-B.2 | Fichiers changes | Fichiers ajoutes |
|---|---|---|---|
| Client | 23 commits | 234 fichiers | 215 fichiers (dont ~180 keybuzz-studio) |
| API | 14 commits | 52 fichiers | 11 fichiers |

### Delta par bloc fonctionnel

#### A. Billing / Plans / Addon

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| `planCapabilities.ts` | Basique | +20 lignes | Restore PH138 capabilities |
| `useCurrentPlan.tsx` | Basique | Refacto significatif (+487/-246) | Refonte PlanProvider |
| BFF agent-keybuzz | Non existant | 2 routes (checkout, update) | Ajout addon |
| API billing/routes.ts | Basique | Modifie + 4 backups supprimes | Nettoyage + pricing fix |
| API billing/pricing.ts | Non existant | Ajoute | Nouveau module pricing |

**Phases source** : PH-BILLING-TRUTH-02, PH142-N

#### B. Agents / RBAC

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| `TenantProvider.tsx` | Cookie basique | Cookie persistent (expires: 365) | PH142-O2 |
| `bff-role-guard.ts` | Non existant | Ajoute (70 lignes) | PH142-O2 |
| `middleware.ts` (Dockerfile) | Non copie | COPY middleware.ts ./ | PH142-O2 |
| `no-access/page.tsx` | Non existant | Ajoute | Page redirect agent |
| API agents/routes.ts | PH131-A basique | Modifie | Ajustements |
| API tenantGuard.ts | Basique | Modifie | Ajustements |

**Phases source** : PH131-A, PH142-O2

#### C. IA Assist

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| `AISuggestionSlideOver.tsx` | Basique | +165 lignes | Enrichi |
| `AutopilotSection.tsx` | PH131-B.2 version | +772/-480 | Refonte complete |
| `MessageSourceBadge.tsx` | Basique | +256/-245 | Refonte |
| `types.ts` (ai-ui) | Basique | +297/-283 | Refonte |
| API shared-ai-context.ts | Non existant | 420 lignes | Nouveau module centralise |
| API ai-mode-engine.ts | Non existant | 217 lignes | Nouveau module |
| API suggestion-tracking-routes.ts | Non existant | Ajoute | Flag erreur IA |

**Phases source** : PH131-C, PH-ENV-ALIGNMENT, PH142-O2

#### D. Autopilot / Safe Mode

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| BFF autopilot routes | Non existant | 4 routes (evaluate, history, draft, consume) | PH131-C |
| API autopilot/engine.ts | Non existant | 821 lignes | Moteur complet |
| API autopilot/routes.ts | Non existant | Ajoute | Routes API |
| AutopilotDraftBanner.tsx | Non existant | 218 lignes | UI brouillon |
| AutopilotConversationFeedback.tsx | Non existant | 180 lignes | UI feedback |
| ConversationActionBar.tsx | Non existant | 105 lignes | Barre d'action |

**Phases source** : PH131-C, PH132-C, PH132-D, PH-ENV-ALIGNMENT, PH142-O2

#### E. Signature / Settings / Deep-links

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| `SignatureTab.tsx` | Non existant | 256 lignes | Nouveau composant |
| `settings/page.tsx` | Basique | +19 lignes | Integration onglet Signature |
| BFF signature route | Non existant | Ajoute | PH141-E |
| API signatureResolver.ts | Non existant | 114 lignes | Resolver signature |

**Phases source** : PH141-E (deep-links), PH142-N

#### F. Dashboard / Supervision / SLA

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| `SupervisionPanel.tsx` | Non existant | 243 lignes | Nouveau composant |
| BFF supervision route | Non existant | 27 lignes | PH142-O3 |
| API dashboard/routes.ts | Summary only | +75 lignes (supervision) | PH142-O3 |
| `InboxTripane.tsx` | Basique | +149 lignes | SLA badges + mapping |
| `AgentWorkbenchBar.tsx` | Basique | +44 lignes | Types elargis |

**Phases source** : PH142-O3

#### G. Tracking / Orders

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| API carrierTracking.routes.ts | Non existant | 112 lignes | Nouveau |
| API carrierLiveTracking.service.ts | Non existant | 366 lignes | 17TRACK integration |
| API tracking webhook | Non existant | 112 lignes | Webhook 17TRACK |
| API tracking providers | Non existant | 3 fichiers (277 lignes) | Factory + 17TRACK |
| BFF tracking status route | Non existant | 23 lignes | PH142-O3 |
| API orders/routes.ts | Basique | Refacto (-217/+mix) | Nettoyage |

**Phases source** : PH136-B, PH136-D

#### H. Infra / Checks

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| pre-prod-check-v2.sh | Sur bastion (PH142-O2) | Deploye | PH142-M + O2 |
| assert-git-committed.sh | Sur bastion (PH142-O2) | Deploye | PH142-M + O2 |
| build-from-git.sh | Deja present | Fonctionnel | - |

**Phases source** : PH142-M, PH142-O2

#### I. Hors scope produit (keybuzz-studio)

~180 fichiers dans `keybuzz-studio/` et `keybuzz-studio-api/` ajoutees entre PH131-B.2 et HEAD. **Ce projet est independant** et ne sera PAS inclus dans la reconstruction (pas deploye sur DEV/PROD KeyBuzz).

#### J. Amazon / Octopia

| Element | PH131-B.2 | Actuel | Ecart |
|---|---|---|---|
| API amazonForward.ts | Basique | Modifie (inbound hooks) | PH131-C |
| BFF amazon inbound routes | Non existant | 2 routes | PH-AMZ |
| API octopiaImport.service.ts | Basique | Modifie (trigger autopilot) | PH132-D |
| API inbound routes.ts | Basique | Modifie | PH-AMZ |

**Phases source** : PH-AMZ-INBOUND-ADDRESS-TRUTH, PH-AMZ-MULTI-COUNTRY-TRUTH

---

## 6. Plan de rebuild par blocs

### Sequencement

```
PH143-B → Billing / plans / addon
PH143-C → Agents / RBAC
PH143-D → IA Assist (contexte intelligent + aide IA)
PH143-E → Autopilot / safe mode / consume
PH143-F → Signature / settings / deep-links
PH143-G → Dashboard / supervision / SLA
PH143-H → Tracking / orders
PH143-I → Infra / checks / bastion sync
PH143-J → Validation globale matrice
```

### PH143-B — Billing / Plans / Addon

**Scope** :
- Upgrade plan PRO → AUTOPILOT CTA
- billing/current coherence (plan, status, channels)
- Addon Agent KeyBuzz (CTA, checkout Stripe, etat actif/premium)
- planCapabilities restoration
- PlanProvider fix (useTenant au lieu de localStorage)

**Source de verite** :
- PH-BILLING-TRUTH-02 (PlanProvider fix)
- PH138-* (addon billing — code dans PH142-N)
- FEATURE_TRUTH_MATRIX : BILL-01 a BILL-06

**Fichiers a porter** :
- Client : `useCurrentPlan.tsx`, `planCapabilities.ts`, 3 BFF routes addon
- API : `billing/pricing.ts`, ajustements `billing/routes.ts`

**Tests de verite** :
- GET /billing/current → plan correct, channels correct
- CTA upgrade visible sur PRO
- Addon checkout → redirection Stripe
- GET /billing/current → hasAgentKeybuzzAddon present

**Critere GO** : BILL-01 a BILL-06 GREEN dans la matrice

---

### PH143-C — Agents / RBAC

**Scope** :
- Creation agent (sans type KeyBuzz publique)
- Invitation agent E2E
- Login agent
- RBAC : menu reduit + garde URL (middleware + cookie)
- Page no-access

**Source de verite** :
- PH131-A (agents system)
- PH140-C/I/J (RBAC)
- PH142-O2 (fix middleware Dockerfile + cookie)
- FEATURE_TRUTH_MATRIX : AGT-01 a AGT-04, ESC-01/02

**Fichiers a porter** :
- Client : `TenantProvider.tsx` (cookie persistent), `bff-role-guard.ts`, `no-access/page.tsx`, Dockerfile (COPY middleware.ts)
- API : `agents/routes.ts`, `tenantGuard.ts`

**Tests de verite** :
- POST /agents {type: "keybuzz"} → 400
- Invitation E2E : formulaire visible, champs corrects
- Agent login : menu 4 liens (pas 12)
- Agent → /settings → redirect /no-access ou /inbox
- Owner → /settings → OK

**Critere GO** : AGT-01 a AGT-04 GREEN

---

### PH143-D — IA Assist

**Scope** :
- Aide IA drawer (AISuggestionSlideOver)
- Contexte intelligent (shared-ai-context)
- Journal IA (ai-journal-routes)
- Flag erreur IA + clustering
- Detection fausses promesses

**Source de verite** :
- PH137-C (shared-ai-context)
- PH141-F (alignement IA)
- PH142-O2 (IA-CONSIST-01)
- FEATURE_TRUTH_MATRIX : AI-01 a AI-07

**Fichiers a porter** :
- Client : `AISuggestionSlideOver.tsx`, `types.ts`
- API : `shared-ai-context.ts`, `ai-mode-engine.ts`, `suggestion-tracking-routes.ts`

**Tests de verite** :
- Bouton aide IA visible → panneau s'ouvre → generation reelle
- GET /ai/errors/clusters → 200
- GET /ai/journal → 200
- shared-ai-context importe dans assist ET autopilot

**Critere GO** : AI-01 a AI-07 GREEN

---

### PH143-E — Autopilot / Safe Mode / Consume

**Scope** :
- Engine autopilot (execution controlee)
- Settings persistantes
- Safe mode (brouillon + validation)
- Draft consume
- KBActions debit
- UI feedback badge
- Auto-escalade

**Source de verite** :
- PH131-C (engine + routes)
- PH132-C/D (plan guard + Octopia trigger)
- PH-ENV-ALIGNMENT
- FEATURE_TRUTH_MATRIX : APT-01 a APT-06, AI-05

**Fichiers a porter** :
- Client : `AutopilotSection.tsx` (refonte complète), `AutopilotDraftBanner.tsx`, `AutopilotConversationFeedback.tsx`, `ConversationActionBar.tsx`, 4 BFF routes
- API : `autopilot/engine.ts`, `autopilot/routes.ts`, `ai-assist-routes.ts` updates

**Dependance** : PH143-D doit etre fait avant (shared-ai-context)

**Tests de verite** :
- GET /autopilot/settings → 200
- POST /autopilot/evaluate → 200
- Brouillon IA visible (AUTOPILOT)
- Boutons Valider/Modifier/Ignorer fonctionnels
- Badge IA dans liste inbox

**Critere GO** : APT-01 a APT-06 GREEN

---

### PH143-F — Signature / Settings / Deep-links

**Scope** :
- Onglet Signature dans settings
- Save + load signature
- Injection dans messages sortants
- Deep-links ?tab= pour tous les onglets

**Source de verite** :
- PH141-E (deep-links + signature)
- PH142-N (restoration)
- FEATURE_TRUTH_MATRIX : SET-01 a SET-03

**Fichiers a porter** :
- Client : `SignatureTab.tsx`, `settings/page.tsx` (integration onglet), BFF route signature
- API : `signatureResolver.ts`, updates outboundWorker si applicable

**Tests de verite** :
- Onglet Signature visible
- Modification + reload = donnees persistees
- ?tab=signature → ouvre le bon onglet
- 10 onglets visibles (owner)

**Critere GO** : SET-01 a SET-03 GREEN

---

### PH143-G — Dashboard / Supervision / SLA

**Scope** :
- Panel supervision dans dashboard
- Badges SLA urgence dans inbox
- Propagation slaState dans mapApiToLocal
- Tri par priorite SLA

**Source de verite** :
- PH140-L/M (supervision concept)
- PH142-O3 (implementation reelle)
- FEATURE_TRUTH_MATRIX : SUP-01, SLA-01

**Fichiers a porter** :
- Client : `SupervisionPanel.tsx`, `InboxTripane.tsx` (slaState mapping), `AgentWorkbenchBar.tsx` (types), BFF supervision route
- API : `dashboard/routes.ts` (GET /supervision)

**Dependance** : aucune (standalone)

**Tests de verite** :
- GET /dashboard/supervision → 200 avec agents + SLA + summary
- GET /dashboard/summary → 200 (non-regression)
- Badge "SLA depasse" visible sur conversations en breach
- Tri par priorite fonctionnel

**Critere GO** : SUP-01, SLA-01 GREEN

---

### PH143-H — Tracking / Orders

**Scope** :
- Endpoints tracking multi-transporteurs
- Integration 17TRACK
- Webhook 17TRACK
- BFF tracking status

**Source de verite** :
- PH136-B/D (tracking stack)
- PH142-O3 (realignement path)
- FEATURE_TRUTH_MATRIX : TRK-01

**Fichiers a porter** :
- API : `carrierTracking.routes.ts`, `carrierLiveTracking.service.ts`, `trackingWebhook.routes.ts`, `services/tracking/*`
- Client : BFF `orders/tracking/status/route.ts`

**Tests de verite** :
- GET /api/v1/orders/tracking/status → 200
- GET /api/v1/orders/:orderId/tracking → 200
- Configuration 17TRACK visible dans response

**Critere GO** : TRK-01 GREEN

---

### PH143-I — Infra / Checks / Bastion Sync

**Scope** :
- assert-git-committed.sh deploye et fonctionnel
- pre-prod-check-v2.sh deploye et fonctionnel
- build-from-git.sh verification

**Source de verite** :
- PH142-M (creation)
- PH142-O2 (deploiement bastion)
- FEATURE_TRUTH_MATRIX : INFRA-01 a INFRA-04

**Actions** :
- Deployer scripts sur bastion depuis branches rebuild
- Verifier permissions executables
- Corriger CRLF si necessaire

**Tests de verite** :
- `assert-git-committed.sh` sur repo dirty → exit 1
- `assert-git-committed.sh` sur repo clean → exit 0
- `pre-prod-check-v2.sh` → execution sans erreur
- `build-from-git.sh` → build fonctionnel

**Critere GO** : INFRA-01 a INFRA-04 GREEN

---

### PH143-J — Validation Globale Matrice

**Scope** :
- Rerun complet FEATURE_TRUTH_MATRIX sur branches rebuild
- 0 RED
- Validation utilisateur

**Actions** :
- Build + deploy depuis branches rebuild
- Tests navigateur reels
- Mise a jour FEATURE_TRUTH_MATRIX
- Rapport final

**Critere GO** : 100% GREEN (ou GATE pour comportement plan attendu)

---

## 7. Risques

| # | Risque | Impact | Mitigation |
|---|---|---|---|
| R1 | Cherry-pick conflits entre blocs | Build cassé | Tester chaque bloc individuellement avant merge |
| R2 | keybuzz-studio polluant le diff | Confusion scope | Exclure explicitement keybuzz-studio des branches rebuild |
| R3 | Fichiers `.bak` / `\r` dans le repo API | Build fails / confusion | Nettoyer dans chaque bloc |
| R4 | Dependances inter-blocs non respectees | Features cassees | PH143-D avant PH143-E (shared-ai-context) |
| R5 | API schema DB manquant | Runtime errors | Verifier tables existantes avant chaque bloc |
| R6 | Variables env manquantes | 500 errors | Documenter env requises par bloc |

---

## 8. Ce qui est EXCLU du rebuild

| Element | Raison |
|---|---|
| keybuzz-studio / keybuzz-studio-api | Projet independant, pas deploye sur DEV/PROD KeyBuzz |
| Amazon SP-API OAuth flow | Fonctionne deja, pas de regression a PH131-B.2 |
| Octopia integration | Fonctionne deja, pas de regression |
| Backend Python (keybuzz-backend) | Non concerne par le rebuild |
| PROD | Aucun changement PROD dans cette phase |

---

## 9. Prochaine etape recommandee

1. **Validation humaine** de ce plan par Ludovic
2. **PH143-B** (Billing) comme premier bloc sur `rebuild/ph143-client` + `rebuild/ph143-api`
3. Build depuis les branches rebuild, deploy DEV
4. Validation navigateur
5. **STOP** pour approbation avant PH143-C

### Ordre d'execution confirme

```
PH143-B (Billing)     ← independant, fondation plan capabilities
     ↓
PH143-C (Agents/RBAC) ← independant, securite
     ↓
PH143-D (IA Assist)   ← prerequis pour PH143-E
     ↓
PH143-E (Autopilot)   ← depend de PH143-D (shared-ai-context)
     ↓
PH143-F (Signature)   ← independant
     ↓
PH143-G (Dashboard)   ← independant
     ↓
PH143-H (Tracking)    ← independant
     ↓
PH143-I (Infra)       ← independant, bastion-only
     ↓
PH143-J (Validation)  ← tout doit etre en place
```

---

## 10. Inventaire des commits a porter (reference)

### Client (23 commits entre PH131-B.2 et HEAD)

```
1a7c51d PH148-O3: sync AgentWorkbenchBar types for build compat
29ee06e PH148-O3: SLA-01+SUP-01+TRKA-01 BFF routes + slaState propagation
f3cb7e2 PH142-O2: add middleware.ts to Dockerfile
8814d45 PH142-O2: RBAC cookie server-side in BFF + persistent client cookie
ccbbf27 PH142-N-restore-PH138-billing-addon-PH141E-deeplinks
1b22fac PH142-N-pending-phase-changes-PH139-PH142
42c0c0e PH-STUDIO-07A.1: Documentation (HORS SCOPE)
f4bfa03 PH-STUDIO-07A.1: Multi-Model Text Pipeline (HORS SCOPE)
c299131 PH-STUDIO-07A: documentation (HORS SCOPE)
8a3c004 Fix Button variant
2bcc4e5 Fix Badge variant
b406f84 Fix JSX template literal
ecce67f Sync all Studio changes PH-STUDIO-03 through PH-STUDIO-07A (HORS SCOPE)
375753b PH-STUDIO-07A: Studio AI Gateway (HORS SCOPE)
c09fc61 PH-STUDIO-02: fix Fastify logger (HORS SCOPE)
6d6e6da PH-STUDIO-02: fix Dockerfile (HORS SCOPE)
f9d59ae PH-STUDIO-01+02: foundation (HORS SCOPE)
032f0d0 PH-PLAYBOOKS-ENGINE-ALIGNMENT-02B: playbook engine BFF
e5034ab PH-PLAYBOOKS-BACKEND-MIGRATION-02: playbooks UI backend API
3fae402 PH-BILLING-TRUTH-02: PlanProvider fix
3ce2f3a PH-AMZ-INBOUND-ADDRESS-TRUTH-02: remove hardcoded FR
8dc1ca5 PH-AMZ-INBOUND-ADDRESS-TRUTH-01: BFF route + provision
364222e PH131-C: autopilot badge + BFF evaluate/history routes
91533fd PH131-C: autopilot badge + BFF evaluate/history routes (dup)
```

**Pertinents produit** : 15 commits (hors 8 Studio)

### API (14 commits entre PH131-B et HEAD)

```
5eccf7e PH148-O3: fix supervision SQL text/uuid cast
6051d5f PH142-O3-fixes (knowledge + supervision)
ad5d68e PH142-O2: align autopilot/engine.ts with shared-ai-context
d20077c PH142-N-pending-phase-changes-API-PH139-PH142
64391bb PH132-D: autopilot trigger for Octopia
c58d20a PH132-C: plan guard autopilot settings
c0ee35a PH-ENV-ALIGNMENT: deployed autopilot engine fix
b6488d5 PH-BILLING-TRUTH: fix channelsIncluded
a290317 PH-AMZ-MULTI-COUNTRY-TRUTH-03: auto-provision
17cc147 PH-AMZ-INBOUND-ADDRESS-TRUTH-02: ON CONFLICT + auto-provision
a349a52 PH-AMZ-INBOUND-ADDRESS-TRUTH-01: local provisioning
574f32f PH131-C: ai_action_log schema fix
a0623c6 PH131-C: compilation fix
8849e45 PH131-C: autopilot engine
```

**Tous pertinents** (pas de Studio dans l'API)

---

**VERDICT : CURRENT STATE SAFELY FROZEN — PH131-B.2 IDENTIFIED — REBUILD LINE READY — NO DESTRUCTIVE ACTION**
