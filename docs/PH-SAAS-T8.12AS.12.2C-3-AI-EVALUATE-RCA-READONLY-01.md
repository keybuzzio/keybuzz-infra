# PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-RCA-READONLY-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-3 RCA -- root cause analysis read-only
> Environnement : DEV restored stable + PROD read-only ; aucun patch ; aucun deploy

---

## 1. VERDICT

GO PARTIAL RCA READY NEEDS DEVTOOLS

Audit read-only complet de la chaine Brouillon IA auto-open. **Conclusion principale : le patch AS.12.2C-3 ne touche AUCUN endpoint dans la chaine Brouillon IA auto-open.** La regression observee par Ludovic est tres probablement **un faux positif lie a une race condition de timing** entre l arrivee du message client et la generation du draft autopilot par le worker server-side, et non un effet du patch tenantGuard.

Hypothese principale (confidence HIGH) : **race condition autopilot worker** -- au moment ou Ludovic a ouvert la conversation post-deploy, le `evaluateAndExecute` (server-side, autopilot engine) n avait pas encore complete la generation du draft. Apres rollback, le delai naturel a permis au draft d etre genere -> Brouillon IA reapparait. Cela explique pourquoi "anciens messages OK" (drafts deja generes) et "nouveaux messages KO" (drafts en cours de generation).

Pour confirmer ou infirmer : capture DevTools Ludovic sur le scenario reproduit (instructions section 12).

R2 design recommande : **re-deployer AS.12.2C-3 sans changement de code** (memes images `v3.5.183` + `v3.5.194` deja sur GHCR) + QA Ludovic obligatoire avec DevTools Network ouvert pour capturer la reponse `/api/autopilot/draft` sur le scenario "nouveau message".

PROD strictement inchange (8 services). DEV stable post-rollback. Aucun patch, build, deploy, mutation DB realises dans cette phase. KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- Lecture comparative source patch (commits `85555b26` API + `c24d8c9` Client) vs source stable.
- Trace complete chaine Brouillon IA auto-open (Client + Server).
- Recherche callers internes server-side de `/ai/evaluate` et `/ai/assist`.
- Identification du composant declencheur auto-open.
- Hypotheses root cause classees par confidence.
- Instructions DevTools capture pour Ludovic (read-only, sans clic mutationnel).
- Design R2 minimal.

Strictement hors scope :
- Aucun patch, aucun build, aucun deploy.
- Aucun POST artificiel.
- Aucune generation IA forcee.
- Aucune mutation DB.
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-DEV-01.md` -- NO GO rapport.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.0.5-INBOX-AI-DRAFT-RUNTIME-TRACE-READONLY-01.md` -- baseline UX Brouillon IA.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.0.6-AI-DRAFT-EFFECT-ORDER-FIX-DEV-01.md` -- AS.11.0.6 consolidated useEffect.
- Source API : `keybuzz-api/src/modules/ai/routes.ts`, `keybuzz-api/src/modules/autopilot/engine.ts`, `keybuzz-api/src/modules/autopilot/routes.ts`, `keybuzz-api/src/modules/inbound/routes.ts`.
- Source Client : `keybuzz-client/src/services/ai.service.ts`, `keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx`, `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx`, `keybuzz-client/app/inbox/InboxTripane.tsx`, `keybuzz-client/app/api/autopilot/draft/route.ts`, `keybuzz-client/app/api/ai/evaluate/route.ts`.

---

## 4. Preflight runtime

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| keybuzz-api HEAD | 85555b26 (commit source AS.12.2C-3 reste en historique) | OK |
| keybuzz-client HEAD | c24d8c9 (commit source AS.12.2C-3 reste en historique) | OK |
| keybuzz-infra HEAD | a03d007 (post-rollback rapport) | OK |
| Runtime DEV API | v3.5.182-ai-guard-check-tenantguard-dev (rolled back) | OK |
| Runtime DEV Client | v3.5.193-ai-guard-check-bff-dev (rolled back) | OK |
| Runtime PROD API | v3.5.182-ai-guard-check-tenantguard-prod (inchange) | OK |
| Runtime PROD Client | v3.5.193-ai-guard-check-bff-prod (inchange) | OK |

---

## 5. Diff source patch vs stable

### 5.1 API diff (commit `85555b26`)

| Fichier | Type | Lignes |
|---|---|---|
| `src/plugins/tenantGuard.ts` | modification | +15 / -3 |

Modification :
- Section docstring : +13 lignes (description AS.12.2C-3).
- PROTECTED_ROUTES : +1 entry `{ method: 'POST', path: '/ai/assist' }` puis `{ method: 'POST', path: '/ai/evaluate' }`.

Aucun autre fichier modifie. Aucun handler change. La logique de `evaluateAndExecute` (autopilot engine, source du Brouillon IA server-side) est strictement inchangee.

### 5.2 Client diff (commit `c24d8c9`)

| Fichier | Type | Lignes |
|---|---|---|
| `src/services/ai.service.ts` | modification | +12 / -1 |
| `app/api/ai/evaluate/route.ts` | nouveau | +59 |

Modification `ai.service.ts` :
- Fonction `evaluateAI` : remplacement de `fetchAI('/ai/evaluate', POST, body)` browser-direct par `fetch('/api/ai/evaluate', POST, body)` relative.

Nouveau BFF `app/api/ai/evaluate/route.ts` :
- POST handler avec `getServerSession(authOptions)` + injection `X-User-Email` + `X-Tenant-Id` -> forward `${API_URL}/ai/evaluate`.

Aucun autre fichier Client modifie. Aucun composant UI touche. Aucun import deplace. Pas de change a `AISuggestionSlideOver`, `AIDecisionPanel`, `InboxTripane`, `app/api/autopilot/draft/route.ts`.

---

## 6. Trace chaine Brouillon IA auto-open

### 6.1 Server-side (declenchement draft)

```
Inbound webhook (Octopia / Shopify / Amazon)
   -> POST /inbound/...
      -> INSERT messages (nouveau message client)
      -> evaluateAndExecute(conversationId, tenantId, 'inbound')   [function call DIRECT, NO HTTP]
         -> loadSettings + resolveIAMode + checkActionsAvailable
         -> loadFullConversationContext + loadEnrichedOrderContext
         -> evaluateGuardrails (anti-abus, anti-fraude)
         -> getAISuggestion(context, plan, orderContext, ...)
            -> appel LLM provider (LiteLLM/OpenAI/etc., NO HTTP /ai/*)
         -> validateDraft (post-LLM guardrails)
         -> debitKBActions
         -> INSERT ai_action_log (action_type = autopilot_draft, status = skipped/blocked/completed, payload = { draftText, ... })
```

**Aucune etape de cette chaine ne fait d appel HTTP a `/ai/evaluate`.** L autopilot engine genere son propre draft sans passer par le route handler `/ai/evaluate`.

### 6.2 Client-side (consumption draft)

```
InboxTripane.tsx (app/inbox/InboxTripane.tsx)
   -> useEffect deps [selectedId, currentTenantId]   [fires on conv change, NOT new message arrival]
      -> fetch('/api/autopilot/draft?tenantId=...&conversationId=...', { credentials: 'include' })
         -> BFF Next.js app/api/autopilot/draft/route.ts
            -> getServerSession(authOptions) -> userEmail
            -> fetch(`${API_URL_INTERNAL}/autopilot/draft?...`, { X-User-Email, X-Tenant-Id })
               -> API /autopilot/draft handler (autopilot/routes.ts:215)
                  -> tenantGuard preHandler (KEY-304, deja actif AS.11.1C)
                  -> SELECT ai_action_log autopilot_* WHERE conversation_id + tenant_id ORDER BY created_at DESC LIMIT 1
                  -> return { hasDraft, draftText, confidence, logId, ... }
      -> if (data.hasDraft && data.draftText)
         -> setAutopilotDraft(...)
         -> setAutopilotAutoOpen(true)
   -> render <AISuggestionSlideOver initialDraft={autopilotDraft} autoOpen={autopilotAutoOpen} ... />
      -> useEffect [initialDraft, autoOpen, conversationId]   (consolidated AS.11.0.6)
         -> if (initialDraft?.draftText && autoOpen)
            -> setActiveDraft(initialDraft)
            -> slide-over s ouvre auto
```

**Le client passe par `/api/autopilot/draft` (BFF) qui appelle `/autopilot/draft` (API).** Pas de passage par `/ai/evaluate`.

### 6.3 Conclusion chaine

La chaine Brouillon IA auto-open passe par :
- `/inbound/*` (EXEMPT prefix tenantGuard, webhook)
- `evaluateAndExecute()` (function call interne, pas de HTTP)
- INSERT `ai_action_log` autopilot_*
- `/api/autopilot/draft` (BFF Client)
- `/autopilot/draft` (API, deja protege depuis AS.11.1C/B)
- `AISuggestionSlideOver` consolidated useEffect (AS.11.0.6)

**Aucun de ces endpoints n a ete modifie par AS.12.2C-3.**

---

## 7. Callers internes de /ai/evaluate (server-side)

| Source code search | Results |
|---|---|
| `grep -rnE "'/ai/evaluate'\|\"/ai/evaluate\"" /opt/keybuzz/keybuzz-api/src` | seul match = docstring tenantGuard.ts + PROTECTED_ROUTES entry, aucun caller |
| `grep -rnE "await fetch\(" /opt/keybuzz/keybuzz-api/src` | 10 callers detectes : compat proxy + Octopia/Shopify auth + ad platforms + frankfurter currency. **Aucun n appelle `/ai/evaluate`** |
| `grep -rnE "getAISuggestion\|callLLM\|/api/ai\|invokeAI" /opt/keybuzz/keybuzz-api/src` | `getAISuggestion` defini dans autopilot/engine.ts:565 -- mais appel direct LLM provider, pas via `/ai/evaluate` |

**Conclusion** : aucun composant server-side n appelle `/ai/evaluate` via HTTP. Le route `/ai/evaluate` est **uniquement Client-facing** (via Client browser-direct ou BFF). Aucun outbound-worker, aucun inbound webhook, aucune chain interne ne le touche.

---

## 8. Composants Client utilisant /ai/evaluate

| Consumer | Auto-call ? | Pattern |
|---|---|---|
| `ai.service.ts::evaluateAI` | export uniquement | function definition |
| `AIDecisionPanel.tsx::generateSuggestions` | **NON** (PH25.9 explicit comment "No auto-call without consent") | bouton clic uniquement (`onClick={generateSuggestions}` lignes 209, 228, 428) |

**Conclusion** : `evaluateAI` n est **PAS auto-call** post-mount. Il est appele uniquement quand l utilisateur clique sur le bouton "Generer suggestions" dans AIDecisionPanel. Le pattern PH25.9 a explicitement supprime l auto-call pour eviter la consommation KBActions involontaire.

---

## 9. Hypotheses root cause (confidence ordering)

### H1 -- Race condition autopilot worker / timing (confidence HIGH)

Au moment ou Ludovic a teste post-deploy AS.12.2C-3 :
- nouveau message arrive via webhook -> evaluateAndExecute lance asynchrone
- Ludovic ouvre la conversation **avant** que evaluateAndExecute finisse de generer le draft
- InboxTripane fetch `/api/autopilot/draft` -> handler retourne `hasDraft: false` (pas encore d entry autopilot_* dans ai_action_log)
- AISuggestionSlideOver ne s ouvre pas auto

Apres rollback :
- delai naturel laisse autopilot worker finir
- Ludovic re-teste -> `/api/autopilot/draft` retourne `hasDraft: true`
- Brouillon IA auto-open

Cela explique aussi pourquoi "anciens messages OK" (drafts deja generes) et "nouveaux messages KO" (worker n a pas encore complete).

**Cette hypothese est compatible avec le fait que AS.12.2C-3 ne touche RIEN dans la chaine Brouillon IA.**

### H2 -- False positive timing UI (confidence MED)

Ludovic peut avoir mal interprete : la conversation testee avait peut-etre un draft genere a `created_at` anterieur a l ouverture conv, mais une logique de cache cote Next.js BFF (cache: 'no-store' OK mais maybe other layer?) qui rendait stale data. Moins probable car AS.12.2C-3 ne touche pas le BFF /api/autopilot/draft.

### H3 -- Cookies / session edge case (confidence LOW)

Si le Client v3.5.194 build a inadvertently casse les cookies NextAuth pour `/api/autopilot/draft`, cela pourrait empecher la session de remonter au BFF.

Mais : le patch Client ne touche aucun fichier auth, aucun middleware, aucun cookie. Build cache may differ but the source files for the autopilot/draft BFF are byte-identical. Confidence LOW.

### H4 -- Mismatch tenantId / membership (confidence MED-LOW)

Si `currentTenantId` cote Client est differ from session.tenant cote NextAuth, et que l API tenantGuard verifie membership avec un mismatch... mais cela existait deja en stable v3.5.193 (KEY-304 deja actif sur /autopilot/draft). Confidence LOW.

### H5 -- Build / chunking webpack regression (confidence VERY LOW)

Si la nouvelle BFF route /api/ai/evaluate a influence le chunking webpack et casse le module timing... possible mais tres peu probable. Pas de change a webpack config.

### H6 -- Behavior change in `fetch('/api/...')` vs `fetchAI` baseUrl (confidence VERY LOW)

`evaluateAI` n etait pas auto-call (cf section 8), donc cette difference n affecte pas l auto-open Brouillon IA.

---

## 10. Top hypothesis : race condition autopilot worker

Probabilites :
- H1 (race condition) : ~70% (le timing entre patch deploy + test + rollback peut facilement coincider avec le worker delay)
- H2 (timing UI false positive) : ~15%
- H3 + H4 + H5 + H6 : ~15% total

**Test discriminant** : re-deployer AS.12.2C-3 et observer DevTools Network sur le scenario reproduit. Si `/api/autopilot/draft` retourne `{hasDraft: false}` pour le nouveau message a l ouverture, c est H1 (race). Si `/api/autopilot/draft` retourne 4xx ou shape differente, c est autre chose.

---

## 11. Preuves indirectes en faveur de H1

| Preuve | Statut |
|---|---|
| Le patch ne touche AUCUN endpoint de la chaine Brouillon IA auto-open | OUI (cf section 5 + 6) |
| `/ai/evaluate` n est appele par AUCUN composant auto-call cote Client | OUI (cf section 8) |
| `/ai/evaluate` n est appele par AUCUN service server-side interne | OUI (cf section 7) |
| Le rollback restore exactement les memes images Client + API | OUI (rollback infra commit `60d3a33`) |
| Le delai entre patch + test + rollback (~5-10 minutes) suffit pour que le worker termine | TRES PROBABLE |
| Le pattern "anciens messages OK / nouveaux KO" est typique d une race condition de worker async | OUI |

---

## 12. DevTools capture instructions pour Ludovic (Etape R2 prerequis)

Si Ludovic accepte de reproduire pour confirmer / infirmer H1, voici les instructions de capture **read-only sans clic mutationnel** :

### 12.1 Reproduction avec instrumentation devtools (sans modifier le DEV)

1. Ouvrir Chrome DevTools (F12) -> onglet **Network** -> activer "Preserve log" et filtrer par "draft" et "evaluate".
2. Onglet **Console** -> activer.
3. Connecte avec `switaa26@gmail.com` sur `https://client-dev.keybuzz.io`.
4. Selectionner la conversation `commande 4114-...`.
5. **Attendre 30 secondes** que le poll autopilot/draft s execute.
6. Si Brouillon IA s ouvre auto : tout va bien (probable apres delai naturel post-rollback).
7. Si Brouillon IA ne s ouvre PAS auto :
   - Dans Network tab, trouver la ligne `GET /api/autopilot/draft?tenantId=...&conversationId=...`
   - Cliquer dessus -> onglet "Response" -> capturer le JSON (sans copier de draftText, juste les champs `hasDraft`, `confidence`, `actionType`)
   - Ou copier le status code et headers
8. Idem chercher si une requete `/api/ai/evaluate` POST a ete envoyee (probablement non puisque pas auto-call).

### 12.2 Decision arbre selon capture

| Observation devtools | Diagnostic | Action |
|---|---|---|
| `/api/autopilot/draft` 200 `{hasDraft: false}` | **H1 confirme : race condition autopilot worker** | R2 = re-apply AS.12.2C-3 sans changement code + ajouter retry / wait dans QA |
| `/api/autopilot/draft` 401/403 | session BFF perdue | R2 = investiguer auth flow |
| `/api/autopilot/draft` shape differente (`hasDraft: true` mais slide-over n ouvre pas) | bug Client AISuggestionSlideOver | R2 = investigation React state / consolidated useEffect |
| `/api/ai/evaluate` POST present avec 401/403 | patch a quand meme un effet (mais quel ?) | R2 = investiguer ce caller mysterieux |
| Aucune erreur reseau | code Client ne fait pas la requete | R2 = investiguer event listeners |

---

## 13. R2 design propose

### 13.1 Option A -- "Re-deploy + DevTools" (recommande)

1. Re-deploy AS.12.2C-3 sans changement code (images existantes deja sur GHCR `v3.5.183-ai-evaluate-tenantguard-dev` + `v3.5.194-ai-evaluate-bff-dev`).
2. QA Ludovic avec DevTools ouvert (cf section 12).
3. Capturer reponse `/api/autopilot/draft` au moment du scenario "nouveau message".
4. Decider selon arbre 12.2 :
   - Si H1 confirme : reapply final + rapport AS.12.2C-3-R2 GO READY (avec note "race condition not a regression").
   - Si autre cause : rollback + patch additionnel selon root cause.

### 13.2 Option B -- "Patch defensif sans re-deploy AS.12.2C-3"

Si Ludovic ne veut pas re-tester, on peut patcher proactivement le code Client InboxTripane pour mieux gerer le delai autopilot worker :
- ajouter un retry sur `/api/autopilot/draft` apres delai si `hasDraft: false`
- OU ajouter un setTimeout(refetch, 5000) pour re-checker apres 5s.

Mais cela touche code ortho au scope AS.12.2C-3 -> phase dediee (par exemple AS.11.0.8 Brouillon IA retry).

### 13.3 Option C -- "Skip AS.12.2C-3"

Si l investigation est trop couteuse, on peut **skipper la protection de `/ai/evaluate`** dans la roadmap KEY-301. Risque accepte : le route reste exploitable cross-tenant pour generer des ai_action_log entries (mock LLM sans cout reel actuellement). A documenter explicitement dans KEY-301.

**Recommandation CE** : Option A.

---

## 14. Validation R2 requise (si Option A)

| Check | Methode |
|---|---|
| Tests negatifs 4/4 PASS (no-auth, bogus, cross-tenant, missing tenantId) | re-execute serie tests |
| DB no-mutation evaluate_log SWITAA delta 0 | mesure pre/post tests |
| Preserve previous protections | re-execute serie preserve checks |
| Smoke V1 PASS_WITH_WARNINGS | re-run smoke |
| QA Ludovic navigateur Brouillon IA auto-open OK | observation + DevTools capture si necessaire |

---

## 15. Rollback R2 prevu

Si R2 confirme regression non liee au patch :
- Garder le patch en place (aucune action).
- Documenter le faux positif.

Si R2 confirme regression liee au patch (autre que H1) :
- Rollback identique a AS.12.2C-3 NO GO : `git revert <infra_commit>` + 2 kubectl apply.

Tag rollback exact : API `v3.5.182-ai-guard-check-tenantguard-dev` + Client `v3.5.193-ai-guard-check-bff-dev`.

---

## 16. PROD strictement inchange

| Service | Image PROD |
|---|---|
| keybuzz-api PROD | v3.5.182-ai-guard-check-tenantguard-prod |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod |
| keybuzz-client PROD | v3.5.193-ai-guard-check-bff-prod |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod |
| amazon-items-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| amazon-orders-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| backfill-scheduler PROD | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche durant cette phase RCA.

---

## 17. No-mutation proof (RCA phase)

| Item | Statut |
|---|---|
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun docker push | OK |
| Aucun kubectl apply / set / patch | OK |
| Aucune modification manifest | OK |
| Aucune mutation DB | OK |
| Aucun POST artificiel vers /ai/evaluate | OK |
| Aucune generation IA forcee | OK |
| Aucune consommation KBActions | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| KEY-301 statut Done NON applique | OK |

---

## 18. Linear text prepared

A poster apres rapport commit + push avec methode token agreee. Backlog : 25 jeux de commentaires accumules.

### 18.1 KEY-301 commentaire RCA (texte cible)

```
## AS.12.2C-3 RCA -- root cause is most likely not the patch itself

Read-only audit of the Brouillon IA auto-open chain shows that the AS.12.2C-3 patch (tenantGuard on /ai/evaluate + new BFF + service migration) touches **zero** endpoint in the auto-open chain.

Trace confirmed :
- Server-side : inbound webhook triggers `evaluateAndExecute()` (direct function call, no HTTP), which writes ai_action_log autopilot_* rows. No internal HTTP call to /ai/evaluate.
- Client-side : InboxTripane polls `/api/autopilot/draft` BFF (unchanged by AS.12.2C-3), which calls `/autopilot/draft` API (already protected since AS.11.1C, unchanged).
- `evaluateAI` Client function has no auto-call consumer (AIDecisionPanel comment PH25.9 explicitly removed auto-call without consent).

Hypothesis ranking :
- H1 (confidence HIGH ~70%) : race condition between inbound webhook arrival and autopilot worker draft generation timing. Pattern "old messages OK / new messages KO" is typical of an async worker race. The natural delay during rollback let the worker complete, giving the false impression that the rollback fixed something.
- H2 to H6 (confidence LOW total ~30%) : Cookie/session edge cases, mismatch tenantId, webpack chunking. Unlikely given the patch surface is just one BFF route + one PROTECTED_ROUTES entry.

R2 design : re-apply the same AS.12.2C-3 patch (images v3.5.183-ai-evaluate-tenantguard-dev + v3.5.194-ai-evaluate-bff-dev already on GHCR) and have Ludovic capture DevTools Network tab response of /api/autopilot/draft during the failing scenario. Decision tree provided in the internal report.

KEY-301 stays Open. AS.12.2C-3 remains NO GO until R2 confirms or refutes the race condition hypothesis.

PROD strictly unchanged throughout. No patch, build, deploy, mutation, or Linear status change in this RCA phase.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-RCA-READONLY-01.md
```

---

## 19. Compliance RCA

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Aucun patch source | OK |
| Aucun build | OK |
| Aucun deploy | OK |
| Aucune mutation DB | OK |
| Aucun POST artificiel | OK |
| Aucune generation IA | OK |
| Aucune consommation KBActions | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement inchange | OK |

---

## 20. Phrase cible finale

AS.12.2C-3 RCA livre en read-only strict : trace complete de la chaine Brouillon IA auto-open confirme que le patch AS.12.2C-3 ne touche aucun endpoint dans cette chaine (server-side `evaluateAndExecute` = function call direct, aucun HTTP vers /ai/evaluate ; Client-side `/api/autopilot/draft` BFF inchange depuis AS.11.1C/B ; `evaluateAI` Client a zero auto-call consumer par design PH25.9) ; hypothese H1 race condition autopilot worker confidence HIGH ~70%, hypotheses H2-H6 confidence LOW total ~30% ; pattern observe "anciens messages OK / nouveaux KO" typique d une race condition async worker ; test discriminant = capture DevTools Network tab Ludovic sur `/api/autopilot/draft` au moment du scenario nouveau message ; R2 design Option A recommande (re-apply AS.12.2C-3 sans changement code, images existantes deja sur GHCR `v3.5.183-ai-evaluate-tenantguard-dev` + `v3.5.194-ai-evaluate-bff-dev`) + capture DevTools + decision arbre selon reponse `/api/autopilot/draft` ; rollback R2 prevu identique a AS.12.2C-3 NO GO ; PROD strictement inchange 8 services ; aucun patch, build, deploy, mutation DB, generation IA, KBActions, draftText, PII dans cette phase RCA ; KEY-301 reste Open epic ; verdict AS.12.2C-3-RCA GO PARTIAL RCA READY NEEDS DEVTOOLS.

STOP
