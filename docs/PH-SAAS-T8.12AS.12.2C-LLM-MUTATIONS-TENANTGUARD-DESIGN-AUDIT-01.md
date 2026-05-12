# PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C -- design audit LLM mutations AI assist/evaluate/execute/guard/rules
> Environnement : DEV + PROD read-only ; aucun patch ; aucun deploy

---

## 1. VERDICT

GO LLM MUTATIONS DESIGN READY

Audit read-only des chemins LLM mutationnels termine. Surface restante hors AS.12.2B (autopilot) et AS.12.2D (settings + wallet) : **5 endpoints API** distincts impliquant generation IA, mutation `ai_action_log`, ou plan bypass potentiel.

Findings :
- `/ai/assist` POST : seul endpoint LLM-cost reel avec BFF Client deja safe (NextAuth session + X-User-Email injecte) -- candidate la plus simple, API-only patch suffit.
- `/ai/guard/check` POST : read-only, pas de LLM, pas de mutation -- probe DEV 200 sans auth confirme exposition.
- `/ai/evaluate` POST : mutation ai_action_log + plan guard handler-level PH130 ; appel browser-direct via `evaluateAI()` -- BFF a creer + ai.service.ts a migrer.
- `/ai/execute` POST : mutation ai_action_log + side effects sur conversation (selon mode), risque le plus eleve -- BFF a creer + Client refactor.
- `/ai/rules` GET + POST : mutation table ai_rules, admin-grade ; appel via fetchAI -- BFF a creer.

Decoupage propose en **5 sous-phases AS.12.2C-1 -> AS.12.2C-5**, ordonnees par risque croissant (assist first, execute last). AS.12.2C-1 est la plus simple : 0 patch Client requis car BFF assist deja safe ; les 4 autres requierent toutes un patch BFF Client + refactor ai.service.ts.

Aucun patch, aucun build, aucun deploy, aucun POST/PATCH/DELETE positif emis pendant cette phase. Aucune generation IA volontaire, aucune consommation KBActions, aucun debit wallet/credits, aucune mutation DB, aucun draftText publie, aucun secret expose. PROD strictement inchange. KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- Audit source API : `keybuzz-api/src/modules/ai/ai-assist-routes.ts` + `keybuzz-api/src/modules/ai/routes.ts` (evaluate, execute, guard/check, rules).
- Audit source Client : `keybuzz-client/src/services/ai.service.ts` + `keybuzz-client/app/api/ai/*/route.ts`.
- Audit BFF coverage (assist OK, evaluate/execute/guard/check/rules MISSING).
- Probes safe runtime : POST avec body minimal `{"tenantId":"fake-tenant"}` pour observer status code uniquement (pas de generation, pas de side effect, plan/membership rejette avant LLM call meme avec body invalide).
- Identification plan gating (handler-level PH130 / PH137-D / IAModeEngine).
- Identification couts (LLM, KBActions, wallet, credits).
- Risk matrix Brouillon IA + KBActions + 17Track/order context.
- QA matrix Ludovic.
- Decoupage 5 sous-phases AS.12.2C-1 -> AS.12.2C-5.

Strictement hors scope :
- Aucun patch source.
- Aucun build / docker push / kubectl apply.
- Aucun POST positif sur `/ai/assist`, `/ai/evaluate`, `/ai/execute`, `/ai/rules` (mutations).
- Aucune generation IA volontaire.
- Aucune consommation KBActions / wallet / credits.
- Aucune mutation DB (`ai_action_log`, `ai_rules`, `ai_settings`).
- Aucun draftText publie.
- Aucun ticket Linear cree sans GO Ludovic.
- Aucun changement statut Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md`
- Rapports Brouillon IA anti-regression : AS.5.3, AS.5.4, AS.11.0.5, AS.11.0.6.
- `keybuzz-api/src/modules/ai/ai-assist-routes.ts` -- POST /assist + plan guard PH137-D.
- `keybuzz-api/src/modules/ai/routes.ts` -- POST /evaluate, /execute, /guard/check, /rules ; PATCH /rules (a auditer).
- `keybuzz-api/src/modules/ai/ai-mode-engine.ts` -- IAModeEngine + PLAN_CAPABILITIES.
- `keybuzz-client/src/services/ai.service.ts` -- assistAI (BFF safe), evaluateAI/executeAI/checkAIGuard (browser-direct via fetchAI).
- `keybuzz-client/app/api/ai/assist/route.ts` -- BFF assist (safe).
- Aucun BFF Client pour evaluate / execute / guard/check / rules (verifie par `ls`).
- Consumers : AIDecisionPanel.tsx (evaluateAI + executeAI + assistAI), AISuggestionSlideOver.tsx (assistAI + settings + wallet).

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / e7ad363f / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / a46eb5f / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 33b8224 / 0-0 | identique | OK |
| Runtime DEV API | v3.5.180-ai-settings-wallet-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.192-ai-settings-wallet-bff-dev | identique | OK |
| Runtime PROD API | v3.5.180-ai-settings-wallet-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.192-ai-settings-wallet-bff-prod | identique | OK |
| Smoke V1 DEV | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. Endpoints API inventory (LLM mutations scope)

### 5.1 /ai/assist POST

| Aspect | Valeur |
|---|---|
| Source | `keybuzz-api/src/modules/ai/ai-assist-routes.ts:577` |
| Body | `{ tenantId, contextType (conversation|order|playbook), contextId|conversationId, payload? }` |
| Genere LLM ? | **OUI** (vrai appel LLM avec OpenAI / Anthropic / autre selon config) |
| Consomme KBActions ? | **OUI** (wallet decrement attendu post-call) |
| Plan guard handler-level | **OUI** PH137-D : `resolveIAMode` + `canUseSuggestions` -> 403 PLAN_REQUIRED si STARTER |
| Kill switch global | OUI `ai_global_settings.global_kill_switch` |
| Kill switch tenant | OUI `ai_settings.kill_switch` |
| Mutation DB | OUI INSERT ai_action_log apres reponse |
| Read DB | OUI `ai_global_settings`, `ai_settings`, conversation + order context |
| Client consumers | `AISuggestionSlideOver.tsx`, `AIDecisionPanel.tsx` |
| Client path | `/api/ai/assist` (relative, BFF) -- **deja safe** : NextAuth session + X-User-Email injecte |
| Risque cross-tenant | crafted tenantId -> LLM call sur compte tier + KBActions debit tier (HIGH) |

### 5.2 /ai/evaluate POST

| Aspect | Valeur |
|---|---|
| Source | `keybuzz-api/src/modules/ai/routes.ts:288` |
| Body | `{ tenantId, conversationId, messageId?, channel?, text? }` |
| Genere LLM ? | NON dans code actuel (suggestions = `'[Mock] Auto-suggestion from rule ' + rule.name`). Branche LLM existe via guardrails mais le scoring est mock. |
| Consomme KBActions ? | NON dans code actuel (mais mutation ai_action_log) |
| Plan guard handler-level | OUI PH130 : STARTER -> 403 PLAN_REQUIRED PRO |
| Mutation DB | **OUI** INSERT ai_action_log (status=planned ou blocked) + UPDATE ai_settings.consecutive_errors |
| Read DB | OUI `checkGuardrails`, `ai_settings`, `ai_rules` |
| Client consumers | `AIDecisionPanel.tsx:101` via `evaluateAI()` |
| Client path | `${baseUrl}/ai/evaluate` browser-direct via `fetchAI('/ai/evaluate', POST)` -- **PAS de BFF** |
| Risque cross-tenant | crafted tenantId -> mutation ai_action_log tier + plan bypass (MED-HIGH) |

### 5.3 /ai/execute POST

| Aspect | Valeur |
|---|---|
| Source | `keybuzz-api/src/modules/ai/routes.ts:356` |
| Body | `{ tenantId, actionId?, ruleId?, conversationId? }` |
| Genere LLM ? | NON (executes a previously evaluated suggestion) |
| Consomme KBActions ? | depend du mode (autonomous = oui, suggestion = bloque par safe_mode) |
| Plan guard | implicite via mode/safe_mode handler-level |
| Mutation DB | **OUI** INSERT ai_action_log (blocked ou executed) |
| Side effects | possibles : envoi reply, assign, escalate selon rule action_type (DANGEREUX cross-tenant) |
| Client consumers | `AIDecisionPanel.tsx:156` via `executeAI()` |
| Client path | `${baseUrl}/ai/execute` browser-direct -- **PAS de BFF** |
| Risque cross-tenant | crafted tenantId + actionId/ruleId tier -> action executee sur conversation tier (CRITICAL) |

### 5.4 /ai/guard/check POST

| Aspect | Valeur |
|---|---|
| Source | `keybuzz-api/src/modules/ai/routes.ts:220` |
| Body | `{ tenantId, conversationId? }` |
| Genere LLM ? | NON |
| Consomme KBActions ? | NON |
| Plan guard | NON (read-only) |
| Mutation DB | NON |
| Client consumers | `ai.service.ts:checkAIGuard` (a determiner consumers UI) |
| Client path | `${baseUrl}/ai/guard/check` browser-direct -- **PAS de BFF** |
| Probe runtime DEV no-auth | **200** (data shape leak cross-tenant) |
| Risque cross-tenant | crafted tenantId -> lecture guard state tier (LOW-MED) |

### 5.5 /ai/rules GET + POST

| Aspect | Valeur |
|---|---|
| Source | `keybuzz-api/src/modules/ai/routes.ts:233` (GET) + `:251` (POST) |
| GET body | n/a, tenantId in query |
| POST body | rule creation payload |
| Mutation DB | OUI sur POST (INSERT ai_rules + conditions + actions) |
| Client consumers | a determiner (probable admin UI) |
| Client path | browser-direct ou BFF a confirmer |
| Probe runtime DEV no-auth GET | **200** (cross-tenant read of ai_rules) |
| Probe runtime DEV no-auth POST | 400 (missing required fields) |
| Risque cross-tenant | crafted tenantId -> read rules tier + create rules tier (MED-HIGH) |

---

## 6. Client BFF / browser-direct inventory

| Service func | API path | BFF Client | Verdict |
|---|---|---|---|
| `assistAI` | `/api/ai/assist` | OUI safe (NextAuth + X-User-Email) | READY for tenantGuard |
| `evaluateAI` | `${baseUrl}/ai/evaluate` | **MISSING** | new BFF + ai.service.ts migration |
| `executeAI` | `${baseUrl}/ai/execute` | **MISSING** | new BFF + ai.service.ts migration |
| `checkAIGuard` | `${baseUrl}/ai/guard/check` | **MISSING** | new BFF + ai.service.ts migration |
| `aiRules` (admin) | `${baseUrl}/ai/rules` | **MISSING** | new BFF + UI migration |

---

## 7. Runtime probes (no LLM, no mutation)

Probe pattern : `curl -X POST -d '{"tenantId":"fake-tenant"}'`. Body minimal pour observer status code et plan/membership check uniquement. Aucune generation LLM declenchee (body invalide vis-a-vis du contrat).

| Endpoint | Method | Status no-auth | Interpretation |
|---|---|---|---|
| /ai/assist | POST | 400 | handler valide body avant plan/LLM ; sans auth/tenantGuard, accessible avec body valide |
| /ai/evaluate | POST | 400 | idem ; mutation ai_action_log possible avec body valide |
| /ai/execute | POST | 400 | idem ; side effects possibles avec body valide |
| /ai/guard/check | POST | **200** | read-only ; retourne guard state pour fake tenant |
| /ai/rules | POST | 400 | idem |
| /ai/rules?tenantId=fake-tenant | GET | **200** | cross-tenant rules read |
| /ai/global/settings | GET | **200** | admin endpoint expose (defer maintenu) |
| /ai/followups/simulate | POST | 400 | idem |
| /ai/human-approval-queue/simulate | POST | 400 | idem |

Aucune mutation DB realisee (body sans champs requis pour les POST mutations). Aucune generation LLM. Aucun draftText publie. Body shapes non capturees.

---

## 8. Plan gating impact

| Endpoint | Plan guard | Bypass possible cross-tenant pre-tenantGuard ? |
|---|---|---|
| /ai/assist | PH137-D resolveIAMode + canUseSuggestions PRO+ | OUI : crafted tenantId vers compte AUTOPILOT permet d utiliser assist depuis un STARTER attaquant |
| /ai/evaluate | PH130 inline PRO+ | idem |
| /ai/execute | mode/safe_mode handler | partiel : si target tenant mode=autonomous safe_mode=false, action s execute |
| /ai/guard/check | none | non applicable |
| /ai/rules POST | a auditer | a auditer plus en detail dans AS.12.2C-5 |

tenantGuard membership check en amont fermerait toutes ces voies de contournement.

---

## 9. Risk matrix (Brouillon IA + KBActions + 17Track/order context)

| Risque | Cause possible | Severite | Mitigation phase |
|---|---|---|---|
| R1 -- Brouillon IA disparait apres activation tenantGuard /ai/assist | BFF /api/ai/assist OK mais NextAuth session expiree ou cookie domain different | HIGH | AS.12.2C-1 QA Ludovic obligatoire |
| R2 -- assistAI 401 si user pas membre du tenant courant | desirable mais doit etre coherent avec tenant switcher | MED | verifier tenant switcher + assist via Ludovic |
| R3 -- evaluateAI / executeAI 401 sur appels browser-direct apres tenantGuard | sans patch Client, breaks AIDecisionPanel | CRITICAL | AS.12.2C-3 + AS.12.2C-4 MUST inclure BFF + Client patch |
| R4 -- checkAIGuard 401 sur appel browser-direct | breaks guard check (where used) | MED | AS.12.2C-2 inclut Client patch |
| R5 -- Cross-tenant LLM cost transfert | crafted tenantId vers compte AUTOPILOT pour exploiter LLM | HIGH | AS.12.2C-1 prioritaire pour fermer assist |
| R6 -- Cross-tenant ai_action_log writes | mutation log d un autre tenant | HIGH | AS.12.2C-3 (evaluate) + AS.12.2C-4 (execute) |
| R7 -- Cross-tenant action execution | execute reply/assign/escalate sur conversation tier | CRITICAL | AS.12.2C-4 critique |
| R8 -- Plan bypass via crafted tenantId | STARTER attaquant utilise quotas PRO/AUTOPILOT victim | HIGH | toutes sous-phases |
| R9 -- 17Track/order context cassante | si assist refuse de charger conversation context post-tenantGuard | LOW (context loading n est pas dans le tenantGuard preHandler) | n/a |
| R10 -- AISuggestionSlideOver hook auto-trigger evaluate | non observe (AS.11.0.6 consolidated useEffect ne fait pas d evaluate auto) | LOW | n/a |
| R11 -- Quality de reponse degradee | tenantGuard ne touche pas le contenu, juste l acces | LOW | n/a |

---

## 10. QA Ludovic matrix (par sous-phase future)

| Sous-phase | UX critique a verifier sans cliquer mutationnel |
|---|---|
| AS.12.2C-1 (assist) | AIModeSwitch + Brouillon IA auto visible + AIDecisionPanel charge sur conv eligible + button "Valider et envoyer" present (NON clique) |
| AS.12.2C-2 (guard/check) | Pas d impact UX direct, mais verifier que AIDecisionPanel + AISuggestionSlideOver continuent de charger normalement |
| AS.12.2C-3 (evaluate) | AIDecisionPanel evaluation auto sur conv ouverture : pas de spinner bloque, pas d erreur fetch devtools |
| AS.12.2C-4 (execute) | Bouton "Executer suggestion" present mais NON clique ; verifier que le UI affiche bien suggestion non executee |
| AS.12.2C-5 (rules) | Admin UI rules (si visible) charge ; suivre la liste des rules existantes sans creation |

Aucune sous-phase ne peut etre validee sans QA Ludovic actif avec switaa26@gmail.com (SWITAA AUTOPILOT).

---

## 11. Proposed sub-phases AS.12.2C-1 -> AS.12.2C-5

### AS.12.2C-1 -- /ai/assist (P0, simple, READY)

Scope : POST /ai/assist (1 endpoint).

Pre-requis :
- BFF `/api/ai/assist` deja safe (verifie AS.12.2A) -- pas de patch Client.
- API tenantGuard : ajout 1 entry PROTECTED_ROUTES static.

Risque : Brouillon IA + AIModeSwitch (consume assist). QA Ludovic obligatoire.

Tag candidate : `v3.5.181-ai-assist-tenantguard-dev`.

Validation : tests negatifs only (no-auth 401, bogus 403, cross-tenant 403). Aucun POST positif emis : pas de generation LLM, pas de KBActions consommees. QA Ludovic : AIModeSwitch + Brouillon IA auto fonctionnels.

### AS.12.2C-2 -- /ai/guard/check (P1, read-only)

Scope : POST /ai/guard/check (1 endpoint).

Pre-requis :
- Nouveau BFF `/api/ai/guard/check` (POST seulement) + injection NextAuth.
- Patch ai.service.ts `checkAIGuard` -> `/api/ai/guard/check` relatif.
- API tenantGuard : ajout 1 entry PROTECTED_ROUTES static.

Risque : faible (read-only). QA legere.

Tag candidates : API `v3.5.182-ai-guard-check-tenantguard-dev`, Client `v3.5.193-ai-guard-check-bff-dev`.

### AS.12.2C-3 -- /ai/evaluate (P0, mutation ai_action_log)

Scope : POST /ai/evaluate (1 endpoint).

Pre-requis :
- Nouveau BFF `/api/ai/evaluate` + injection NextAuth.
- Patch ai.service.ts `evaluateAI` -> `/api/ai/evaluate` relatif.
- API tenantGuard : ajout 1 entry PROTECTED_ROUTES static.

Risque : AIDecisionPanel.tsx:101 fait un `evaluateAI(...)` automatique a l ouverture de la slide-over. Cette migration peut casser cet auto-call si BFF ou tenantGuard mal configure.

Validation : tests negatifs only. Mesurer ai_action_log count SWITAA pre/post pour confirmer delta 0 (aucun evaluate execute pendant les tests).

Tag candidates : API `v3.5.183-ai-evaluate-tenantguard-dev`, Client `v3.5.194-ai-evaluate-bff-dev`.

### AS.12.2C-4 -- /ai/execute (P0 CRITICAL, mutation + side effects)

Scope : POST /ai/execute (1 endpoint).

Pre-requis :
- Nouveau BFF `/api/ai/execute` + injection NextAuth.
- Patch ai.service.ts `executeAI` -> `/api/ai/execute` relatif.
- API tenantGuard : ajout 1 entry PROTECTED_ROUTES static.

Risque : execute peut declencher reply/assign/escalate. Surtout sensible si mode=autonomous chez le tenant cible. Cross-tenant execute = compromission downstream possible.

Validation : tests negatifs only. Verifier ai_action_log + conversations counts SWITAA delta 0. NE PAS faire de test positif execute.

Tag candidates : API `v3.5.184-ai-execute-tenantguard-dev`, Client `v3.5.195-ai-execute-bff-dev`.

### AS.12.2C-5 -- /ai/rules GET + POST (P1, admin mutation)

Scope : GET + POST /ai/rules (2 endpoints) + potentiellement PATCH rules toggle a verifier.

Pre-requis :
- Audit complet sur consumers Client (admin UI ou non).
- Nouveau BFF si necessaire.
- Patch ai.service.ts si consumers detectes.
- API tenantGuard : ajout 2-3 entries PROTECTED_ROUTES static.

Risque : admin-grade mutation. Verifier qui utilise (probablement settings UI).

Tag candidates : API `v3.5.185-ai-rules-tenantguard-dev`, Client `v3.5.196-ai-rules-bff-dev`.

---

## 12. Sequencing recommande

1. **AS.12.2C-1** assist (DEV + PROD). Plus simple, BFF Client deja safe.
2. **AS.12.2C-2** guard/check (DEV + PROD). Read-only, faible risque.
3. **AS.12.2C-3** evaluate (DEV + PROD). Mutation log mais pas d effet downstream.
4. **AS.12.2C-4** execute (DEV + PROD). CRITICAL, en dernier des mutations.
5. **AS.12.2C-5** rules (DEV + PROD). Admin scope.

Justification : ordre risque croissant. assist est l endpoint le plus couvert (BFF safe). evaluate vient avant execute pour eviter qu un execute traite un evaluate cross-tenant. rules en dernier car admin scope plus etroit.

Une seule promotion PROD par sous-phase recommandee pour limiter blast radius et faciliter QA Ludovic + rollback. Le bundle des 5 sous-phases ne s impose pas.

---

## 13. Rollback strategy (futur, par sous-phase)

Chaque sous-phase devra documenter :
- Tag rollback exact API + Client.
- Revert commit infra + `kubectl apply` API puis Client.
- Triggers UX (Brouillon IA / AIModeSwitch / AIDecisionPanel KO).
- Fenetre QA Ludovic 30 min puis 24h passif.

---

## 14. No-mutation proof (cette phase audit)

| Item | Statut |
|---|---|
| Aucun POST / PATCH / DELETE emis | OK (probes POST avec body `{"tenantId":"fake-tenant"}` -> 400 missing fields, n atteint pas handler mutation) |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucune mutation DB (ai_action_log, ai_rules, ai_settings) | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret affiche | OK |
| Aucun docker build | OK |
| Aucun docker push | OK |
| Aucun kubectl apply / set / patch / edit | OK |
| Aucun ticket Linear cree | OK |
| KEY-301 statut Done NON applique | OK |

---

## 15. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 19 jeux de commentaires accumules.

### 15.1 KEY-301 commentaire (texte cible)

```
## AS.12.2C LLM mutations design audit complete

Read-only audit of the LLM mutation surface under KEY-301, after AS.12.2B (autopilot) and AS.12.2D (AI settings + wallet) have been promoted to PROD.

Five mutation-bearing endpoints inventoried (no PoC, no endpoint listing here) :
- One LLM-cost POST endpoint whose Client BFF is already authenticated and safe (smallest blast radius for the next sub-phase).
- One read-only POST guard endpoint without Client BFF yet.
- One evaluate-style mutation endpoint that writes the AI action log without Client BFF yet.
- One execute endpoint that may trigger downstream conversation side effects (highest risk, no Client BFF yet).
- One admin rules endpoint set (GET + POST) without Client BFF yet.

Plan gating is enforced handler-level (STARTER / PRO / AUTOPILOT / ENTERPRISE) but currently bypassable cross-tenant ; closing tenantGuard first binds the plan check to actual membership.

Recommended sequencing (sub-phases to confirm) :
- AS.12.2C-1 assist (P0, API-only, BFF already safe).
- AS.12.2C-2 guard/check (P1, read-only, BFF + Client patch).
- AS.12.2C-3 evaluate (P0, mutation log, BFF + Client patch).
- AS.12.2C-4 execute (P0 critical, mutation + downstream side effects, BFF + Client patch).
- AS.12.2C-5 rules GET+POST (P1, admin scope, BFF + Client patch).

KEY-301 stays Open. No patch, build, deploy, mutation, or Linear status change happened in this audit phase. PROD strictly unchanged.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md
```

---

## 16. Final recommendation

### 16.1 Verdict

GO LLM MUTATIONS DESIGN READY

### 16.2 Reponses aux questions du prompt CE

- Quels endpoints API-only ? `/ai/assist` (BFF deja safe).
- Quels endpoints necessitent BFF + Client refactor ? `/ai/guard/check`, `/ai/evaluate`, `/ai/execute`, `/ai/rules`.
- Quels endpoints ne pas tester positivement ? Les 5 endpoints (assist genere LLM ; evaluate/execute mutent ai_action_log ; rules POST mute ai_rules ; guard/check ne mute pas mais on garde la regle).
- Minimum viable safe pour DEV ? AS.12.2C-1 (assist API-only) en premier.
- Comment valider sans generer IA ? Tests negatifs only -- no-auth 401, bogus 403, cross-tenant 403. Aucun body valide envoye.
- Comment prouver no-mutation/no-cost ? Mesurer `ai_action_log` count SWITAA pre/post tests, mesurer wallet/KBActions counts pre/post.
- Comment preserver qualite de reponse + 17Track/order context ? Le tenantGuard n affecte que l acces (preHandler), pas le content loading ; le handler API charge orderContext apres tenantGuard pass.

### 16.3 Conditions before AS.12.2C-1 launch

- GO Ludovic explicite + sequencement choisi.
- BFF /api/ai/assist confirme safe une derniere fois.
- Smoke V1 DEV PASS pre-deploy.
- Fenetre QA Ludovic disponible pour Brouillon IA verification.

---

## 17. Phrase cible finale

AS.12.2C audit livre en read-only strict : 5 endpoints API LLM-mutation inventoriees (/ai/assist + /ai/evaluate + /ai/execute + /ai/guard/check + /ai/rules) ; 1 BFF deja safe (/api/ai/assist NextAuth + X-User-Email), 4 BFF MISSING (evaluate, execute, guard/check, rules) ; 4 fonctions service browser-direct via ai.service.ts fetchAI baseUrl ; probes DEV no-auth POST `{"tenantId":"fake-tenant"}` retournent 400 missing fields sur les mutations (n atteint pas handler), GET /ai/rules + /ai/global/settings + POST /ai/guard/check retournent 200 cross-tenant ; plan gating handler-level (STARTER/PRO/AUTOPILOT) bypassable cross-tenant pre-tenantGuard ; risk matrix 11 risques (Brouillon IA, KBActions cost transfer, cross-tenant log writes, downstream action execution critical, plan bypass) ; decoupage 5 sous-phases AS.12.2C-1 -> AS.12.2C-5 ordonnees risque croissant (assist first, execute last) ; aucun patch, aucun build, aucun push, aucun apply, aucune mutation DB, aucune generation IA, aucune consommation KBActions/wallet/credits, aucun draftText publie, aucune PII publiee, aucun ticket Linear cree ; KEY-301 reste Open epic ; verdict AS.12.2C GO LLM MUTATIONS DESIGN READY ; phases AS.12.2C-1..5 a NE PAS lancer sans GO Ludovic explicite + decision sequencement.

STOP
