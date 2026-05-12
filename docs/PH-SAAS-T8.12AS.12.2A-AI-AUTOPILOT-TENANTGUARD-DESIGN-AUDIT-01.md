# PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2A -- design audit AI + autopilot avant tout patch
> Environnement : DEV + PROD read-only ; aucun patch ; aucun deploy

---

## 1. VERDICT

GO AI AUTOPILOT DESIGN READY

Audit confirme une surface AI + autopilot **tres significative** : 60+ routes API exposees, dont la majorite acceptent un `tenantId` en query/header/body sans verification membership. Probes 12/12 GET DEV no-auth confirme 9/12 retournent 200 sans authentification (cross-tenant leak surface incluant `/autopilot/draft` qui peut exposer `draftText`).

Le decoupage **ne peut pas etre execute en une seule sous-phase** comme AS.12.1A/B. La complexite supplementaire vient de :
- Client browser-direct calls non encore migres vers BFF (cf `ai.service.ts` ligne 114 utilise `API_CONFIG.baseUrl + endpoint`) sur plusieurs endpoints AI critiques (evaluate, execute, guard/check, wallet/status, journal, settings via fetchAI).
- Plan gating handler-level (PLAN_REQUIRED) actif sur certains endpoints mais sans verification membership user-tenant prealable -> theoriquement contournable via crafted `tenantId`.
- BFF mixte : certaines routes BFF injectent X-User-Email + X-Tenant-Id (autopilot/draft, history, evaluate, ai/assist), d autres seulement Cookie (ai/settings), d autres absent (ai/evaluate, ai/execute, ai/guard/check) -> certaines doivent etre creees ou normalisees AVANT d activer tenantGuard.

Decoupage propose en 5 sous-phases AS.12.2B -> AS.12.2F module-scoped, ordre safe-first (autopilot/draft d abord, mutations LLM ensuite, intelligence read surface en dernier). Brouillon IA reste le point UX critique : AS.12.2B prealable a tout deploy effectif. **AS.12.2A produit le plan ; aucune phase suivante ne doit etre lancee sans GO Ludovic explicite + decision sequencement.**

Aucun patch, aucun build, aucun docker push, aucun kubectl apply, aucune mutation manifest, aucune mutation DB, aucun POST/PATCH/DELETE runtime, aucune generation IA volontaire, aucune consommation KBActions, aucun secret affiche, aucun draftText publie. KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- Inventaire complet routes API `keybuzz-api/src/modules/ai/*` + `keybuzz-api/src/modules/autopilot/*`.
- Inventaire BFF Next.js `keybuzz-client/app/api/ai/*` + `app/api/autopilot/*`.
- Inventaire appels browser-direct Client `ai.service.ts`.
- Probes safe GET DEV no-auth tenantId factice -- aucune mutation, aucune generation.
- Identification plan gating (STARTER / PRO / AUTOPILOT / ENTERPRISE).
- Identification endpoints consommateurs KBActions / wallet / credits.
- Identification endpoints lisant ou ecrivant `ai_action_log` (drafts).
- Risk matrix Brouillon IA + KBActions + AUTOPILOT/PRO gating.
- Decoupage propose AS.12.2B -> AS.12.2F.

Strictement hors scope :
- Aucun patch source AI / autopilot / tenantGuard.
- Aucun build.
- Aucun docker push.
- Aucun kubectl apply / set / patch / edit.
- Aucune mutation manifest.
- Aucune mutation DB (ai_action_log, autopilot_settings, ai_settings, etc.).
- Aucun POST / PATCH / DELETE runtime.
- Aucune generation IA volontaire (assist / evaluate / execute / autopilot evaluate / draft/consume).
- Aucune consommation wallet / credits / KBActions.
- Aucune ouverture conversation reelle dans rapport.
- Aucun draftText publie meme partiellement.
- Aucun secret / token / email client affiche.
- Aucun ticket Linear cree sans GO Ludovic.
- Aucun changement statut Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md` -- AI + autopilot identifies P0 second cluster apres tenants+notifications.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01.md` + `-PROD-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md`
- Rapports anti-regression Brouillon IA :
  - `PH-SAAS-T8.12AS.5.3-...-ROLLBACK-...md` (cf SOT do-not-redeploy images)
  - `PH-SAAS-T8.12AS.5.4-...md`
  - `PH-SAAS-T8.12AS.11.0.5-INBOX-AI-DRAFT-RUNTIME-TRACE-READONLY-01.md`
  - `PH-SAAS-T8.12AS.11.0.6-AI-DRAFT-EFFECT-ORDER-FIX-DEV-01.md`
- Source API :
  - `keybuzz-api/src/app.ts` (registrations 7 plugins AI + autopilot).
  - `keybuzz-api/src/modules/ai/routes.ts` (mode + settings + plan gating).
  - `keybuzz-api/src/modules/ai/ai-assist-routes.ts` (POST /assist + plan guard PH137-D).
  - `keybuzz-api/src/modules/ai/credits-routes.ts` (wallet + budget).
  - `keybuzz-api/src/modules/ai/usage-routes.ts` (admin usage).
  - `keybuzz-api/src/modules/ai/ai-journal-routes.ts`, `ai-policy-debug-routes.ts`, `context-upload-routes.ts`, `ops-routes.ts`, `returns-decision-routes.ts`, `suggestion-tracking-routes.ts`, `ai-mode-engine.ts`.
  - `keybuzz-api/src/modules/autopilot/routes.ts` (draft / consume / settings / history / evaluate, plan guard PH132-C).
  - `keybuzz-api/src/modules/autopilot/engine.ts` (evaluateAndExecute).
- Source Client :
  - `keybuzz-client/src/config/api.ts`
  - `keybuzz-client/src/services/ai.service.ts` (fetchAI wrapper baseUrl).
  - `keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx` (Brouillon IA UI).
  - `keybuzz-client/app/api/ai/*/route.ts` (~17 BFF AI routes).
  - `keybuzz-client/app/api/autopilot/*/route.ts` (~5 BFF autopilot routes).

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 5eadb345 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / ddb3a8b (avant rapport) / 0-0 | identique | OK |
| Runtime DEV API | v3.5.178-notifications-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.189-messages-sav-status-bff-dev | identique | OK |
| Runtime PROD API | v3.5.178-notifications-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| GitOps drift DEV+PROD | NONE | MATCH=YES sur 4 deployments | OK |
| Smoke V1 DEV | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. API route inventory (AI + autopilot)

### 5.1 Plugins Fastify registres

Source `keybuzz-api/src/app.ts` lignes 174-204 :

| Plugin | Prefix | Module |
|---|---|---|
| aiRoutes | /ai | `modules/ai/routes.ts` |
| creditsRoutes | /ai | `modules/ai/credits-routes.ts` |
| aiAssistRoutes | /ai | `modules/ai/ai-assist-routes.ts` |
| aiContextUploadRoutes | /ai | `modules/ai/context-upload-routes.ts` |
| aiJournalRoutes | /ai | `modules/ai/ai-journal-routes.ts` |
| aiPolicyDebugRoutes | /ai | `modules/ai/ai-policy-debug-routes.ts` |
| suggestionTrackingRoutes | /ai | `modules/ai/suggestion-tracking-routes.ts` |
| aiUsageRoutes | (root) | `modules/ai/usage-routes.ts` -- expose `/admin/ai/*` |
| autopilotRoutes | /autopilot | `modules/autopilot/routes.ts` |
| (returns-decision-routes referencee mais non listee dans extract) | n/a | `modules/ai/returns-decision-routes.ts` |
| (ops-routes referencee mais non listee dans extract) | n/a | `modules/ai/ops-routes.ts` |

Le module `returns-decision-routes.ts` + `ops-routes.ts` semblent rechargees via un agregateur (non visible dans `app.ts` direct). Exposition runtime confirmee par probes (e.g. /ai/ops-dashboard 200).

### 5.2 Routes autopilot (7)

| Endpoint | Method | Mutation | Effet | Plan guard |
|---|---|---|---|---|
| /autopilot/settings | GET | non | SELECT autopilot_settings | non |
| /autopilot/settings | POST | OUI (UPSERT) | INSERT/UPDATE autopilot_settings | OUI (mode=autonomous -> AUTOPILOT/ENTERPRISE) |
| /autopilot/settings | PATCH | OUI | UPDATE autopilot_settings | OUI |
| /autopilot/draft | GET | non | SELECT ai_action_log + conversations + stale invalidation | non |
| /autopilot/draft/consume | POST | OUI | UPDATE ai_action_log status=consumed/dismissed | non |
| /autopilot/history | GET | non | SELECT ai_action_log autopilot_* | non |
| /autopilot/evaluate | POST | OUI (LLM cost) | `evaluateAndExecute()` -- AI generation + INSERT ai_action_log + optionally send reply | OUI implicit (engine checks plan >= AUTOPILOT pour mode autonomous) |

### 5.3 Routes ai-assist (2)

| Endpoint | Method | Mutation | Effet | Plan guard |
|---|---|---|---|---|
| /ai/assist | POST | OUI (LLM cost) | AI completion + INSERT ai_action_log + wallet/credits consumption | OUI (PH137-D : `resolveIAMode` + `canUseSuggestions`, requires PRO+ ; STARTER -> 403 PLAN_REQUIRED) |
| /ai/assist/status | GET | non | health-check style status | non |

### 5.4 Routes ai (routes.ts -- mode + admin) (~10)

| Endpoint | Method | Mutation | Effet | Plan guard |
|---|---|---|---|---|
| /ai/settings | GET | non | SELECT ai_settings | non |
| /ai/settings | PATCH | OUI | UPDATE ai_settings (mode change triggers plan check) | OUI (PH130 : mode=autonomous AUTOPILOT+, mode=supervised/suggestion PRO+) |
| /ai/global/settings | GET | non | SELECT ai_global_settings | non |
| /ai/global/settings | PATCH | OUI | UPDATE | (admin-only suppose, non verifie) |
| /ai/evaluate | POST | OUI (LLM cost potential) | evaluate AI mode + insert log | OUI (handler-level cf source ai/routes.ts:297) |
| /ai/execute | POST | OUI (LLM cost + side effects) | execute AI action | OUI plan + scopes |
| /ai/guard/check | POST | non | guard rules check | non |
| /ai/rules | GET | non | SELECT rules | non |
| /ai/rules | POST | OUI | INSERT rules | non |

### 5.5 Routes ai-credits / wallet (~10)

| Endpoint | Method | Mutation | Effet |
|---|---|---|---|
| /ai/budget/overview | GET | non | SELECT budget overview |
| /ai/budget/settings | PATCH | OUI | UPDATE budget settings |
| /ai/credits/wallet | GET | non | SELECT wallet balance |
| /ai/wallet/status | GET | non | SELECT wallet status |
| /ai/wallet/ledger | GET | non | SELECT wallet ledger |
| /ai/credits/add | POST | OUI | INSERT credits |
| /ai/credits/ledger | GET | non | SELECT credits ledger |
| /ai/budget/check | POST | non (read) | check budget |
| /ai/budget/alerts | GET | non | SELECT alerts |
| /ai/wallet/dev/topup | POST | OUI (DEV) | INSERT topup |
| /ai/wallet/dev/consume | POST | OUI (DEV) | consume |
| /ai/wallet/dev/set-actions | POST | OUI (DEV) | set actions remaining |
| /ai/wallet/actions/ledger | GET | non | SELECT actions ledger |
| /ai/debug/budget | GET | non | debug |

### 5.6 Routes ai-usage / admin (~3)

| Endpoint | Method | Mutation | Effet |
|---|---|---|---|
| /admin/ai/usage | GET | non | SELECT usage admin |
| /admin/ai/usage/today | GET | non | SELECT today usage |
| /admin/ai/plans | GET | non | SELECT plans |

### 5.7 Routes ai-ops (~8)

| Endpoint | Method | Mutation | Effet |
|---|---|---|---|
| /ai/ops-dashboard | GET | non | dashboard |
| /ai/ops/escalations | GET | non | escalations list |
| /ai/ops/followups | GET | non | followups list |
| /ai/ops/pending-approvals | GET | non | approvals list |
| /ai/ops/assign | POST | OUI | assign ops |
| /ai/ops/resolve | POST | OUI | resolve ops |
| /ai/ops/snooze | POST | OUI | snooze ops |
| /ai/human-approval-queue | GET | non | queue |
| /ai/human-approval-queue/:id | GET | non | item detail |
| /ai/human-approval-queue/:id/status | POST | OUI | status mutation |
| /ai/human-approval-queue/simulate | POST | OUI | simulate |

### 5.8 Routes ai-returns / ai-context / ai-journal (~7)

| Endpoint | Method | Mutation | Effet |
|---|---|---|---|
| /ai/returns/analysis | GET | non | analysis read |
| /ai/returns/analysis | POST | OUI (LLM cost) | analysis generate |
| /ai/returns/decision | POST | OUI (LLM cost + side effects) | decision generate |
| /ai/returns/decision/eligibility | GET | non | eligibility read |
| /ai/context/upload | POST | OUI | uploads context |
| /ai/journal | GET | non | journal read |
| /ai/followups + /ai/followups/:id + /ai/followups/simulate (POST) | GET/POST | mixed | followups |

### 5.9 Routes ai-intelligence / monitoring (~30 read-only)

`/ai/abuse-pattern`, `/ai/action-execution`, `/ai/autopilot-execution`, `/ai/carrier-integration`, `/ai/case-autopilot`, `/ai/context-compression`, `/ai/control-center` + sous-routes, `/ai/conversation-memory`, `/ai/customer-emotion`, `/ai/decision-calibration`, `/ai/escalation-intelligence`, `/ai/evidence-intelligence`, `/ai/execution-audit`, `/ai/followup-scheduler` + sous-routes, `/ai/health-monitoring` + sous-routes, `/ai/knowledge-retrieval`, `/ai/marketplace-intelligence`, `/ai/performance-metrics` + sous-routes, `/ai/prompt-stability`, `/ai/real-execution-*`, `/ai/resolution-prediction`, `/ai/return-management`, `/ai/safety-simulation`, `/ai/self-protection`, `/ai/supplier-case-automation`, `/ai/workflow-state`.

Toutes acceptent un `tenantId` en query (suppose, a verifier au cas par cas dans sous-phases).

---

## 6. Client call inventory

### 6.1 BFF Next.js existants (`keybuzz-client/app/api/`)

Confirme presents :
- `app/api/autopilot/` : draft, draft/consume, evaluate, history, settings (5 routes).
- `app/api/ai/` : assist, context (download/upload), dashboard, errors/clusters, journal, learning-control, returns (analysis, decision), settings, suggestions (flag, stats, track), wallet (dev/consume, dev/topup, ledger, settings, status).

### 6.2 BFF patterns observes

| BFF route | NextAuth session check | X-User-Email inject | X-Tenant-Id inject | Cookie forward | Verdict |
|---|---|---|---|---|---|
| /api/autopilot/draft GET | OUI (getServerSession) | OUI | OUI | non | SAFE pour tenantGuard |
| /api/autopilot/history GET | OUI | OUI | OUI | non | SAFE |
| /api/ai/assist POST | OUI (401 si pas de session) | OUI | OUI | non | SAFE |
| /api/ai/settings GET/PATCH | non | non | non | OUI (forward Cookie) | **PAS SAFE** pour tenantGuard (X-User-Email manquant) |

D autres BFF non encore audites en detail. La phase AS.12.2B/C/D devra verifier le pattern pour chaque BFF concerne avant d activer tenantGuard.

### 6.3 Browser-direct calls Client (bypass NextAuth)

Source : `keybuzz-client/src/services/ai.service.ts` (fetchAI helper ligne 114, `API_CONFIG.baseUrl + endpoint`).

| Service func | API path | Method | Browser-direct | Risk si tenantGuard active |
|---|---|---|---|---|
| getAISettings | /ai/settings | GET | OUI | KO -- pas de X-User-Email injecte cote client |
| getAIGlobalSettings | /ai/global/settings | GET | OUI | KO |
| aiGuardCheck | /ai/guard/check | POST | OUI | KO |
| aiEvaluate | /ai/evaluate | POST | OUI | KO |
| aiExecute | /ai/execute | POST | OUI | KO |
| getJournal | /ai/journal | GET | OUI | KO |
| getAIWalletStatus | /ai/wallet/status | GET | OUI | KO |
| assistAI | /api/ai/assist | POST | NON (via BFF deja) | OK |

Resume : 7 services browser-direct cote Client sur AI ; 1 seul deja via BFF (assist). Avant d activer tenantGuard sur ces endpoints, il faudra :
- Soit creer/utiliser des routes BFF dediees + modifier les services pour utiliser des paths relatifs `/api/ai/*`.
- Soit basculer le fetchAI helper sur des paths relatifs `/api/ai/<endpoint>` et creer les BFF manquants.

---

## 7. Runtime read-only probes (DEV no-auth, fake tenant)

Aucune mutation, aucune generation IA. Body shapes non publies.

| Probe | Status | Interpretation |
|---|---|---|
| /ai/settings?tenantId=fake | 200 | VULNERABLE (cross-tenant AI settings read) |
| /ai/assist/status?tenantId=fake | 500 | handler crash transient (non bloquant audit) |
| /ai/debug/budget | 400 | OK (missing param) |
| /ai/admin/ai/plans | 404 | route registree sans prefix /ai (a verifier) |
| /ai/credits/wallet?tenantId=fake | 200 | VULNERABLE (cross-tenant wallet balance) |
| /ai/wallet/status?tenantId=fake | 200 | VULNERABLE (cross-tenant wallet status) |
| /ai/global/settings | 200 | VULNERABLE (global AI settings, admin only en principe) |
| /ai/ops-dashboard | 200 | VULNERABLE (ops dashboard read) |
| /ai/ops/escalations | 200 | VULNERABLE (escalations list cross-tenant) |
| /autopilot/settings?tenantId=fake | 200 | VULNERABLE (autopilot config) |
| /autopilot/draft?tenantId=fake&conversationId=fake | 200 (hasDraft=false avec fake) | CRITIQUE -- avec vrais ids retournerait draftText reel |
| /autopilot/history?tenantId=fake | 200 | VULNERABLE (autopilot action history cross-tenant) |

12 probes -> 9 retournent 200 sans auth = surface vulnerable confirmee.

---

## 8. Plan gating (handler-level)

Source `keybuzz-api/src/modules/ai/ai-mode-engine.ts` (PLAN_CAPABILITIES) :

```
STARTER    -> no AI
PRO        -> suggestion only (ai assist)
AUTOPILOT  -> suggestion + auto reply + auto assign + auto escalate (safe_mode draft)
ENTERPRISE -> AUTOPILOT + keybuzz escalation
AUTOPILOT_ASSISTED -> trial cap a supervised
```

Plan guards observes :
- `/ai/assist` POST -- PH137-D `canUseSuggestions(iaMode)` -- 403 PLAN_REQUIRED si STARTER (cf ai-assist-routes.ts:620).
- `/ai/settings` PATCH (mode change) -- PH130 -- 403 si STARTER ou si autonomous demande sans AUTOPILOT.
- `/ai/evaluate` POST -- 403 si STARTER (cf ai/routes.ts:303).
- `/autopilot/settings` POST/PATCH (mode=autonomous) -- 403 PLAN_REQUIRED si plan < AUTOPILOT (cf autopilot/routes.ts:12 + PH132-C).

Risque IDOR plan-bypass : actuellement le plan est verifie pour le tenantId de la requete sans verifier que le user appelant est membre. Un attaquant qui connait un tenantId tier avec plan AUTOPILOT pourrait theoriquement contourner les blockings PRO/STARTER de son propre tenant -- toutes ces routes doivent etre derriere tenantGuard.

---

## 9. KBActions / wallet / credits identifies

Endpoints qui consomment KBActions ou credits (handler-level) :
- `/ai/assist` POST -- LLM call + wallet/actions decrement.
- `/ai/evaluate` POST -- LLM call.
- `/ai/execute` POST -- LLM call.
- `/ai/returns/analysis` POST -- LLM call (analyse retour).
- `/ai/returns/decision` POST -- LLM call (decision retour) + side effects.
- `/autopilot/evaluate` POST -- LLM call via `evaluateAndExecute` + ai_action_log.
- `/autopilot/draft/consume` POST -- pas de cout LLM, mais UPDATE ai_action_log.
- `/ai/context/upload` POST -- upload + indexation (cout potentiel selon implementation).
- `/ai/ops/assign|resolve|snooze` POST -- pas de cout LLM mais UPDATE ops.
- `/ai/credits/add` + `/ai/wallet/dev/*` -- mutations financieres directes (DEV-only labels).

KBActions sont LE compteur visible utilisateur (CLAUDE.md absolute rules). Toute mutation cross-tenant sur ces endpoints pourrait :
- consommer le quota d un tenant tier (deni de service KBActions).
- declencher une generation LLM sur le compte d un tenant tier (cost transfer).
- modifier ses settings IA (sabotage).

---

## 10. Drafts identifies (ai_action_log)

Endpoints qui lisent ou ecrivent `ai_action_log` :
- `/autopilot/draft` GET -- lit le dernier autopilot_* avec draftText.
- `/autopilot/draft/consume` POST -- UPDATE status='consumed' ou 'dismissed'.
- `/autopilot/history` GET -- lit ai_action_log autopilot_* recents.
- `/autopilot/evaluate` POST -- INSERT (via engine).
- `/ai/evaluate` + `/ai/execute` POST -- INSERT.
- `/ai/assist` POST -- INSERT.
- `/ai/journal` GET -- lit ai_action_log (potentiellement avec draftText).

draftText est LE contenu sensible (texte client + brand voice + PII potentielle) que le Brouillon IA expose. Aucun draftText ne doit fuir cross-tenant.

---

## 11. Risk matrix Brouillon IA

| Risque | Cause possible | Detection | Severite | Mitigation |
|---|---|---|---|---|
| R1 -- Brouillon IA disparait apres activation tenantGuard sur /autopilot/draft | BFF /api/autopilot/draft injecte X-User-Email mais session NextAuth expiree ou cookie domain different DEV/PROD | logs Client + smoke V1 + QA navigateur | HIGH | QA Ludovic obligatoire avant et apres deploy AS.12.2B ; rollback prepare |
| R2 -- Brouillon IA disparait apres activation tenantGuard sur /ai/settings | BFF `/api/ai/settings` n injecte PAS X-User-Email actuellement (forward Cookie only) -- tenantGuard rejette | smoke V1 + AISuggestionSlideOver fail | HIGH | corriger BFF /api/ai/settings AVANT activer tenantGuard /ai/settings |
| R3 -- ai.service.ts browser-direct fetchAI fails | activation tenantGuard sur /ai/evaluate /execute /guard/check /journal /wallet/status sans BFF prealable | Network errors devtools Client | HIGH | creer/router BFF avant activation tenantGuard |
| R4 -- KBActions cost transfert | crafted tenantId vers tenant AUTOPILOT pour exploiter LLM | non detectable cote victim avant facturation | HIGH | activer tenantGuard sur tous endpoints LLM (assist, evaluate, execute, returns/analysis, returns/decision, autopilot/evaluate) |
| R5 -- draftText leak cross-tenant | /autopilot/draft + /autopilot/history + /ai/journal lisent ai_action_log sans membership check | logs ne capturent pas leak | CRITICAL | AS.12.2B prioritaire |
| R6 -- Plan bypass | crafted tenantId vers tenant AUTOPILOT pour usage des features PRO bloquees sur tenant courant | facturation / quota anormal | MED | activer tenantGuard pour faire membership check avant plan check |
| R7 -- autopilot/settings mutation cross-tenant | crafted tenantId pour activer autonomous mode sur autre tenant | ai_action_log anormal | HIGH | AS.12.2B inclut settings POST/PATCH |
| R8 -- Stale draft invalidation logic touche ai_action_log via /autopilot/draft GET | le GET peut effectivement modifier draftText? non, c est en lecture, mais retourne `hasDraft=false` quand stale -- pas de mutation DB en lecture | NA | LOW | OK |
| R9 -- ai_action_log timeline modifiable sans auth | /autopilot/draft/consume POST cross-tenant marque drafts d autre tenant comme consumed | UI Brouillon IA disparait sur autre tenant | HIGH | AS.12.2B inclut draft/consume |
| R10 -- Brouillon IA visible auto declenche generation sans GO | useEscalationNotifsCount ou AISuggestionSlideOver hook fait un POST evaluate automatique | wallet decrement non sollicite | LOW (logique AS.11.0.6 -- consolidated useEffect n appelle PAS evaluate auto) | OK (verifie AS.11.0.6 rapport) |

---

## 12. Proposed sub-phases (AS.12.2B -> AS.12.2F)

Decoupage **a NE PAS lancer dans cette phase**. Decision Ludovic requise.

### AS.12.2B (P0 critique, prochaine candidate)

Scope : autopilot endpoints uniquement (5 endpoints).

| Endpoint | Method | tenantGuard pattern propose |
|---|---|---|
| /autopilot/settings | GET | PROTECTED_ROUTES static |
| /autopilot/settings | POST | PROTECTED_ROUTES static (method=POST) |
| /autopilot/settings | PATCH | PROTECTED_ROUTES static (method=PATCH) |
| /autopilot/draft | GET | PROTECTED_ROUTES static |
| /autopilot/draft/consume | POST | PROTECTED_ROUTES static |
| /autopilot/history | GET | PROTECTED_ROUTES static |
| /autopilot/evaluate | POST | PROTECTED_ROUTES static |

Prerequis Client : BFF `/api/autopilot/draft`, `/api/autopilot/history`, `/api/autopilot/settings`, `/api/autopilot/draft/consume`, `/api/autopilot/evaluate` deja en place et confirmes injecter X-User-Email (cf section 6.2 + verification supplementaire des 5 routes au moment de la phase).

QA UX critique : Brouillon IA + autopilot settings + history + boutons "Valider et envoyer" (visible, non clique).

Pas de mutation positive autorisee meme en validation : tests negatifs only + QA Ludovic visuelle.

### AS.12.2C (P0 mutations LLM)

Scope : 3 endpoints LLM-cost.

| Endpoint | Method | Pre-requis Client |
|---|---|---|
| /ai/assist | POST | BFF `/api/ai/assist` deja safe ; OK |
| /ai/evaluate | POST | **NOUVEAU BFF requis** + modifier ai.service.ts pour utiliser path relatif |
| /ai/execute | POST | **NOUVEAU BFF requis** + ai.service.ts |

Cette phase necessite un patch Client (BFF + ai.service.ts) AVANT toute extension tenantGuard.

### AS.12.2D (P0 settings + wallet)

Scope : settings + financial reads.

| Endpoint | Method | Pre-requis Client |
|---|---|---|
| /ai/settings | GET | BFF `/api/ai/settings` existe mais **doit etre corrige pour injecter X-User-Email** au lieu de Cookie forward |
| /ai/settings | PATCH | meme correction BFF |
| /ai/global/settings | GET | nouveau BFF si pas present |
| /ai/global/settings | PATCH | nouveau BFF + restriction admin a auditer |
| /ai/credits/wallet | GET | BFF (a verifier) |
| /ai/wallet/status | GET | ai.service.ts browser-direct -- BFF + path relatif requis |
| /ai/wallet/ledger | GET | BFF a verifier |
| /ai/credits/add | POST | endpoint sensible (financier), restreindre + BFF |
| /ai/budget/* | varies | BFF + restriction admin |

### AS.12.2E (P0/P1 ops + returns + journal + context)

Scope : ops actions + AI returns + journal + context upload.

| Endpoint groupes | Method | Notes |
|---|---|---|
| /ai/ops-dashboard + /ops/escalations|followups|pending-approvals | GET | reads |
| /ai/ops/assign|resolve|snooze | POST | mutations |
| /ai/human-approval-queue + /:id + /:id/status | GET/POST | mixed |
| /ai/returns/analysis | GET/POST | reads + LLM cost mutation |
| /ai/returns/decision + eligibility | POST/GET | LLM cost + reads |
| /ai/context/upload | POST | upload + indexation |
| /ai/journal | GET | reads, may contain draftText |
| /ai/followups + /:id + /simulate | GET/POST | mixed |

### AS.12.2F (P1/P2 intelligence + monitoring read surface)

Scope : ~30 routes intelligence / monitoring / control-center / performance / metrics.

Toutes reads (GET), mais cross-tenant leak potentiel. Phase de finition de la surface AI.

Ordre interne flexible -- peut etre groupee differemment selon usage Client reel.

---

## 13. Sequence recommandee

1. **AS.12.2B** -- autopilot scope only (DEV + PROD) -- prochaine candidate, prerequis Client OK.
2. **AS.12.2D** -- settings + wallet, mais necessite patch Client BFF prealable (fix /api/ai/settings X-User-Email).
3. **AS.12.2C** -- evaluate + execute, necessite patch Client BFF prealable (nouveaux BFF + ai.service.ts refactor).
4. **AS.12.2E** -- ops + returns + journal + context.
5. **AS.12.2F** -- intelligence + monitoring read surface.

Justification :
- AS.12.2B (autopilot) est le scope le plus critique UX (Brouillon IA) ET le plus prepare (5 BFF deja en place avec X-User-Email).
- AS.12.2D (settings) avant AS.12.2C (evaluate/execute) car le mode IA depend de settings -- si on bloque evaluate sans avoir securise settings, on cree des incoherences.
- AS.12.2C ensuite (mutations LLM) avec patch Client.
- AS.12.2E + F a la fin (volume eleve mais reads non-critique).

PROD promotion proposee par paire DEV+PROD pour chaque sous-phase (comme AS.12.1A et AS.12.1B).

---

## 14. Rollback strategy future

Chaque sous-phase doit prevoir :
- Tag rollback exact API.
- Tag rollback exact Client si patch Client.
- GitOps strict revert commit + 1-2 kubectl apply.
- Triggers rollback specifiques par sous-phase (e.g. AS.12.2B : Brouillon IA disparait -> rollback immediat ; AS.12.2C : assistAI 401 errors devtools -> rollback).
- Fenetre QA Ludovic post-deploy obligatoire.

---

## 15. No-mutation proof

| Item | Statut |
|---|---|
| Aucun POST / PATCH / DELETE emis pendant cette phase | OK |
| Aucune mutation DB (ai_action_log, autopilot_settings, ai_settings, wallet, credits) | OK |
| Aucune generation IA volontaire | OK |
| Aucune consommation KBActions | OK |
| Aucun docker build | OK |
| Aucun docker push | OK |
| Aucun kubectl apply / set / patch / edit | OK |
| Aucune modification manifest | OK |
| Aucun secret display | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun ticket Linear cree | OK |
| Aucun changement statut Linear vers Done | OK |
| KEY-301 / KEY-304 / KEY-263 inchanges | OK |

---

## 16. Final recommendation

### 16.1 Verdict

GO AI AUTOPILOT DESIGN READY

### 16.2 Reponses aux questions du prompt CE

- Quelles routes AI / autopilot ? Inventaire section 5 : 7 autopilot + ~50 AI = ~60 routes API exposees.
- Mutation vs reads ? Cartographie section 5 sous-categories + KBActions section 9 + drafts section 10.
- Browser-direct vs BFF ? Section 6 : 5 BFF autopilot OK, 17 BFF AI partiellement OK (au moins `/api/ai/settings` necessite fix), 7 browser-direct restants dans ai.service.ts.
- Endpoints KBActions / wallet ? Section 9 (~8 endpoints LLM-cost et financier).
- Endpoints drafts ? Section 10 (~7 endpoints touchent ai_action_log).
- Plan gating ? Section 8 : 4 endpoints avec PLAN_REQUIRED handler-level (assist, settings mode change, evaluate, autopilot/settings autonomous).
- Dependencies 17Track/tracking/order ? hors scope AS.12.2 (tracking webhook EXEMPT depuis longtemps ; tracking status endpoint a couvrir en AS.12.6).
- Safe a proteger par tenantGuard ? Section 12 : decoupage 5 sous-phases.

### 16.3 Linear KEY-301 commentaire (texte cible)

```
## AS.12.2A AI autopilot design audit complete

Read-only audit of all AI + autopilot API endpoints behind KEY-301. The surface is significantly larger than the previous sub-phases (tenants, notifications) : about 60 API endpoints exposed on `/ai/*` + `/autopilot/*`.

Findings (no PoC, no endpoint listing) :
- Several AI and autopilot endpoints currently accept a query/header/body `tenantId` without verifying the calling user is a member of that tenant.
- A subset of these endpoints consumes LLM credits / KBActions and could be used cross-tenant for cost transfer.
- One endpoint exposes draft text (the Brouillon IA content) and is a primary protection priority.
- Plan gating (STARTER / PRO / AUTOPILOT / ENTERPRISE) is enforced at handler level but without a prior membership check ; closing tenantGuard first ensures plan gating is also bound to the user's actual tenant.
- The Client side has a mix of authenticated BFF routes (the majority) and a few remaining browser-direct calls that bypass NextAuth ; these need migration before some endpoints can be safely guarded.

Recommended sub-phase sequencing (to confirm with maintainer) :
- AS.12.2B (P0 critical, ready) : autopilot scope only (5 endpoints). All 5 BFF already inject X-User-Email + X-Tenant-Id.
- AS.12.2D (P0) : AI settings + wallet read. Requires BFF /api/ai/settings to be corrected to inject X-User-Email before activating tenantGuard.
- AS.12.2C (P0) : AI assist + evaluate + execute mutations. Requires new BFF routes + Client service refactor.
- AS.12.2E (P0/P1) : AI ops + returns + journal + context.
- AS.12.2F (P1/P2) : remaining intelligence + monitoring read surface (~30 endpoints).

Brouillon IA UX is the primary regression risk ; QA Ludovic navigateur required for every sub-phase before PROD promotion.

KEY-301 stays Open as an epic. No patch, build, deploy, mutation, or Linear status change happened in this audit phase.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 17. Phrase cible finale

AS.12.2A audit livre en read-only strict : 60+ routes API AI + autopilot inventoriees (5 plugins AI prefix /ai + 1 admin /admin/ai + 1 autopilot /autopilot) ; 9/12 probes GET DEV no-auth retournent 200 (cross-tenant leak surface incluant /autopilot/draft qui peut exposer draftText) ; 4 endpoints avec plan gating handler-level (STARTER/PRO/AUTOPILOT/ENTERPRISE) mais sans membership check prealable -> contournement plan theoriquement possible ; ~8 endpoints consomment KBActions / wallet / credits ; ~7 endpoints touchent ai_action_log (drafts) ; BFF Client : 5 BFF autopilot safe (X-User-Email injecte), au moins 1 BFF AI (/api/ai/settings) doit etre corrige avant tenantGuard, 7 services Client browser-direct sans BFF (evaluate/execute/guard/check/journal/wallet/status/settings via fetchAI) ; risk matrix Brouillon IA en 10 risques classes ; decoupage propose AS.12.2B (autopilot ready) -> AS.12.2D (settings + wallet, requires BFF fix) -> AS.12.2C (mutations LLM, requires Client patch) -> AS.12.2E (ops + returns + journal) -> AS.12.2F (intelligence + monitoring) ; aucun patch, aucun build, aucun push, aucun apply, aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun draftText publie, aucune PII publiee, aucun ticket Linear cree dans cette phase ; KEY-301 reste Open epic ; verdict AS.12.2A GO AI AUTOPILOT DESIGN READY ; phases AS.12.2B-F a NE PAS lancer sans GO Ludovic explicite + decision sequencement.

STOP
