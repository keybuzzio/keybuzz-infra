# PH-SAAS-T8.12AS.11-MESSAGES-TENANTGUARD-REDESIGN-READONLY-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301, KEY-305, KEY-263
> Phase : T8.12 AS.11 - design read-only de la reprise messages tenantGuard post-AS.5 rollback
> Environnement : DEV + PROD read-only. Aucun patch. Aucun build. Aucun deploy. Aucune mutation runtime.

---

## 1. VERDICT

GO PARTIAL DESIGN READY - ROOT CAUSE STILL UNCLEAR

Resume :
- L analyse statique exhaustive (diff AS.5 + route graph Client + structure API) PERMET d eliminer plusieurs causes possibles mais NE PERMET PAS d isoler la cause exacte de la regression Brouillon IA SWITAA AUTOPILOT observee post-AS.5 sans test runtime parallele (v3.5.179 vs v3.5.180).
- Une recommandation de design AS.11.1 est livree, basee sur "migration endpoint-by-endpoint avec gating Brouillon IA strict a chaque etape" : c est la seule strategie qui isolerait la cause exacte en production sans nouvelle regression masquee.
- KEY-304 reste a Todo / In Review. NE PAS Done. AS.11.1 patch ne doit pas etre lance sans GO Ludovic explicite et sans avoir d abord run un test DevTools network trace en parallele dans une phase intermediaire AS.11.0.5 (proposition).

Aucun patch, aucun build, aucun docker push, aucun kubectl apply, aucun deploy, aucune mutation DB. Runtime DEV+PROD strictement inchanges. Smoke V1 reconfirme PASS=18 WARN=0 FAIL=0 SKIP=1 sur bastion install-v3.

---

## 2. Executive summary

AS.5 a tente une securisation endpoint-by-endpoint stricte de `/messages/conversations*` :
- API : `tenantGuardPlugin` wrapped avec `fastify-plugin` (fix scope parent KEY-301) + `PROTECTED_PREFIXES = ['/messages']` (allowlist stricte).
- Client : 7 nouveaux fichiers BFF Next.js (`app/api/messages/_bff.ts` helper + 6 routes) + redirection des 6 endpoints conversations dans `src/config/api.ts` vers les paths relatifs BFF.

Resultat post-deploy v3.5.169 API + v3.5.180 Client :
- Inbox listing OK initialement.
- Mais `Brouillon IA` SWITAA AUTOPILOT a DISPARU de l interface utilisateur.
- AS.5.1 a tente un mini-fix (useEffect auto-trigger generateSuggestion) mais a affiche "Suggestion IA" au lieu du "Brouillon IA" attendu pour AUTOPILOT. Symptome inacceptable.
- Rollback complet AS.5.3 (runtime API+Client) puis AS.5.4 (source revert byte-equivalent aux anchors safe).

Trois faits cles documentes par cette analyse statique :

1. **L API guard AS.5 (eae84b58) est restrictif**. `PROTECTED_PREFIXES = ['/messages']` + `isProtected()` early-return : aucune autre route n est impactee. Donc l API guard SEUL ne peut pas expliquer la regression `/autopilot/draft` ou la perte de "Brouillon IA".

2. **Le pattern BFF existe deja et fonctionne**. `/api/autopilot/draft` est un BFF Next.js stable, utilise depuis PH143-E.4 par `InboxTripane.tsx` ligne 358 avec `credentials: 'include'`. Le "Brouillon IA" UI label arrive de la, pas de Suggestion IA. Donc le pattern BFF n est pas intrinsequement cassant.

3. **AS.5 a NEUFEMENT introduit 7 fichiers BFF messages**. Aucun de ces fichiers n existait avant. Le helper `_bff.ts` AS.5 est minimaliste (session check + X-User-Email/X-Tenant-Id inject + forward). Le risque venait probablement de l interaction shape/timing entre le nouveau BFF messages list et le useEffect `/autopilot/draft` qui depend de `selectedId`.

Hypothese la plus probable, NON PROUVEE en statique : delai d arrivee de la liste conversations via BFF (overhead +50-200ms) + race condition entre `setSelectedId(...)` et `useEffect(() => fetch /autopilot/draft)`, donnant un `selectedId` initial different (premier element apres tri par defaut) qui n a pas de draft, ou un fetch declenche AVANT l hydratation complete.

Une phase ulterieure intermediaire AS.11.0.5 (proposition) est OBLIGATOIRE pour isoler la cause par instrumentation runtime : DevTools network panel + console log timings, sur DEV avec image archive v3.5.180 redeployee TEMPORAIREMENT en sandbox (ou pas, si trop risque, alors par analyse statique plus profonde). Sans cela, toute tentative AS.11.1 patch reste un coin a l aveugle.

---

## 3. Preflight

| Item | Expected | Observed | Verdict |
|---|---|---|---|
| keybuzz-api branche | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| keybuzz-api HEAD | safe (b8613f0f ou descendant) | f371a79c (AS.9 OCI labels) | OK |
| keybuzz-api sync | 0/0 | 0/0 | OK |
| keybuzz-client branche | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD | safe (8cdc04a ou descendant) | 4011ada (AS.9 OCI labels) | OK |
| keybuzz-client sync | 0/0 | 0/0 | OK |
| keybuzz-infra HEAD | post AS.10 | 19e48c3 (AS.10) | OK |
| keybuzz-infra sync | 0/0 | 0/0 | OK |
| API DEV runtime | v3.5.168-escalation-notifications-dev | idem | OK |
| Client DEV runtime | v3.5.179-as1-1-build-args-fix-dev | idem | OK |
| API PROD runtime | v3.5.151-conversation-tone-metric-prod | idem | OK |
| Client PROD runtime | v3.5.174-conversation-tone-metric-ux-prod | idem | OK |
| Smoke V1 | PASS, WARN documente, FAIL=0 | PASS=18 WARN=0 FAIL=0 SKIP=1 | OK |

Aucun drift. Design peut commencer sur runtime stable.

---

## 4. AS.5 diff reconstruction

Trois commits experimentaux, tous archives sur origin et reverted dans la chaine de production :

| Commit | Repo | Files | Intent | Runtime deployed? | Regression signal | Reuse? | Avoid? |
|---|---|---|---|---|---|---|---|
| `eae84b58` | keybuzz-api | `src/plugins/tenantGuard.ts` (+57/-3) | wrap tenantGuard avec `fastify-plugin` pour appliquer le hook au scope parent + allowlist `PROTECTED_PREFIXES = ['/messages']` | OUI : built en v3.5.169-messages-tenant-guard-dev, deploye DEV ~ 2026-05-11 06:42, rollback en AS.5.3 | Brouillon IA SWITAA AUTOPILOT absent post-deploy | partiel reuse : la mecanique `fastify-plugin` est correcte pour fixer KEY-301. La logique allowlist `PROTECTED_PREFIXES` est correcte aussi. | AS.11.1 future devra REUTILISER la wrap fastify-plugin + PROTECTED_PREFIXES, c est sain. |
| `57766ea` | keybuzz-client | NEW 7 fichiers BFF (`_bff.ts` helper + 6 routes `app/api/messages/conversations/*`) + `src/config/api.ts` modif (6 endpoints conversations vers paths BFF relatifs) | route les 6 endpoints conversations via BFF Next.js avec session NextAuth + inject X-User-Email + X-Tenant-Id | OUI : built en v3.5.180-messages-bff-tenant-guard-dev, rollback AS.5.3 | probable shape ou timing different conversation list, racing avec /autopilot/draft useEffect dans InboxTripane | helper `_bff.ts` est solide (no log body, no forward Cookie/Authorization, scoped /messages). Routes BFF specifiques sont minimales. | NE PAS reuser tel quel : la modification `src/config/api.ts` etait simultanee sur 6 endpoints. AS.11.1 doit migrer endpoint-par-endpoint avec QA Brouillon IA a chaque etape. |
| `8d8121f` | keybuzz-client | `src/features/ai-ui/AISuggestionSlideOver.tsx` (+36) | ajout useEffect auto-trigger `generateSuggestion` avec garde-fous (one-shot par conv, skip si activeDraft, 500ms debounce) | OUI : built en v3.5.181-inbox-ai-auto-suggestion-dev, rollback meme jour | mauvais comportement UX : affichait "Suggestion IA" alors qu un "Brouillon IA" autopilot etait attendu pour AUTOPILOT. Le commit message dit explicitement "No impact on AS.5 messages tenant guard" -> ne corrige pas la vraie cause. | AS.5.1 etait un faux-fix. Le vrai probleme est qu `initialDraft={autopilotDraft}` arrivait null (timing). | A NE PAS REPRODUIRE. La bonne reponse n est pas un auto-trigger fallback Suggestion IA ; c est de garantir que `autopilotDraft` est correctement charge AVANT l ouverture du slide-over. |

Commits anterieurs annexes (KEY-304 chain Client, deja reverted) :
- `de498b0` AS.4 generic BFF proxy tenant-scoped : reverted (9a2081c).
- `49a99f9` AS.4 BFF AI assist : reverted (ae915be).
- `a032d83` AS.4 client-bff drop tenantRequired : reverted (38b1b62).

Pattern global observe : chaque tentative BFF Client large (generic, AI assist, ou messages) a casse au moins un flux utilisateur. Mais le BFF cible deja en production (`/api/autopilot/draft`) fonctionne. Donc le probleme n est pas BFF en soi mais l implementation specifique des couches AS.4/AS.5.

---

## 5. Current route graph (runtime stable v3.5.168 + v3.5.179)

### 5.1 Client

| Flow | Client source | API route final | Method | Direct/BFF | Auth identity | Tenant scope | Criticality | AS.5 impact risk |
|---|---|---|---|---|---|---|---|---|
| fetchConversations | `src/config/api.ts` ligne 9 `conversations(tenantId, q)` | `GET /messages/conversations?tenantId=...` | GET | DIRECT (browser -> api-dev.keybuzz.io) | cookie NextAuth via `credentials: 'include'` (suppose) | tenantId en query | HIGH (Inbox listing) | HIGH (AS.5 BFF migration changea l URL relative) |
| fetchConversationDetail | api.ts ligne 10 | `GET /messages/conversations/:id?tenantId=...` | GET | DIRECT | idem | tenantId en query | HIGH | HIGH |
| sendReply | api.ts ligne 11 | `POST /messages/conversations/:id/reply?tenantId=...` | POST | DIRECT | idem | tenantId en query | CRITICAL (mutation message) | HIGH |
| updateStatus | api.ts ligne 12 | `PATCH /messages/conversations/:id/status?tenantId=...` | PATCH | DIRECT | idem | tenantId en query | HIGH | HIGH |
| assignAgent | api.ts ligne 13 | `PATCH /messages/conversations/:id/assign?tenantId=...` | PATCH | DIRECT | idem | tenantId en query | HIGH | HIGH |
| updateSavStatus | api.ts ligne 14 | `PATCH /messages/conversations/:id/sav-status?tenantId=...` | PATCH | DIRECT | idem | tenantId en query | HIGH | HIGH |
| fetchAutopilotDraft (Brouillon IA) | `app/inbox/InboxTripane.tsx` ligne 358 | `GET /api/autopilot/draft?tenantId=...&conversationId=...` | GET | BFF Next.js (existe deja `app/api/autopilot/draft/route.ts`) | NextAuth session via `credentials: 'include'` | tenantId + conversationId query | CRITICAL (Brouillon IA UI label) | aucun (route BFF non touchee par AS.5) - MAIS dependence en input sur `selectedId` qui vient de fetchConversations |
| AISuggestionSlideOver `initialDraft` | InboxTripane.tsx ligne 1596 -> AISuggestionSlideOver line 214 | n/a (state local) | n/a | n/a | n/a | n/a | CRITICAL (decide label "Brouillon IA" vs "Suggestion IA") | indirect : si autopilotDraft est null, label devient "Suggestion IA" |
| generateSuggestion | AISuggestionSlideOver `useCallback` | `POST /api/ai/assist` (BFF) | POST | BFF Next.js | NextAuth session | tenantId en body | HIGH (Suggestion IA flow) | aucun direct par AS.5 (mais AS.5.1 ajoutait un auto-trigger ici, retire en revert) |
| /channels, /suppliers, /catalogue, /orders | divers services Client | `GET /channels`, `/suppliers`, `/orders` etc. | GET | DIRECT principalement | idem | tenantId query | HIGH (Inbox panels) | aucun par AS.5 (PROTECTED_PREFIXES = '/messages' seul) |
| /notifications | NotificationProvider Client | `GET /api/notifications` (BFF) | GET | BFF Next.js | NextAuth session | tenantId query | HIGH (escalation badge AS.1) | aucun |

### 5.2 API

| Route | Source | Method | Tenant scope mechanism | Tenant guard runtime (current) |
|---|---|---|---|---|
| `/messages/conversations` | `src/modules/messages/routes.ts:86` | GET | tenantId query | aucun (KEY-301 ouvert) |
| `/messages/conversations/:id` | routes.ts:235 | GET | tenantId query | aucun |
| `/messages/conversations/:id/reply` | routes.ts:344 | POST | tenantId query | aucun |
| `/messages/conversations/:id/status` | routes.ts:720 | PATCH | tenantId query | aucun |
| `/messages/conversations/:id/sav-status` | routes.ts:851 | PATCH | tenantId query | aucun |
| `/messages/conversations/:id/assign` | routes.ts:906 | PATCH | tenantId query | aucun |
| `/messages/conversations/:id/escalation` | routes.ts:1033 (PATCH) + 1089 (GET) | PATCH/GET | tenantId query | aucun |
| `/autopilot/draft` | `src/modules/autopilot/routes.ts:214` | GET | tenantId + conversationId query | aucun |
| `/channels`, `/suppliers`, `/orders`, `/stats/*`, `/notifications` | divers | GET majoritaire | tenantId query | aucun |

Le `tenantGuardPlugin` source actuel existe mais N EST PAS WRAPPED `fastify-plugin` -> son hook ne s applique a AUCUNE route. C est la faille KEY-301 documentee en AS.3.

---

## 6. AS.5 regression hypotheses

8 hypotheses analysees pour expliquer la regression "Brouillon IA SWITAA AUTOPILOT absent" sous AS.5 v3.5.180 Client.

| # | Hypothesis | Evidence for | Evidence against | Confidence | Future validation |
|---|---|---|---|---|---|
| H1 | `src/config/api.ts` redirige vers BFF a modifie 6 endpoints simultanement, causant cascade timing | AS.5 commit 57766ea touche 6 endpoints en meme temps. ratio change/test=mauvais | aucune | MED-HIGH | migrer endpoint-par-endpoint en sandbox, observer impact UI a chaque etape |
| H2 | BFF `/api/messages/conversations` route a change la shape des conversations | helper `_bff.ts` archive : "return upstream status + body (no rewriting except for proxy misconfiguration and upstream fetch failure)" -> en theorie pas de rewrite | shape upstream API inchangee, BFF forward raw body | LOW | inspecter `await fetch(...).then(r => r.json())` shape brute en DevTools si re-deploy sandbox |
| H3 | `selectedId` initial different post-BFF (ordre/timing), conduit a un fetch `/autopilot/draft` avec mauvais conv id | BFF ajoute ~50-200ms overhead network. `InboxTripane.useEffect [selectedId]` peut declencher avant que la conversation list soit hydrate | difficile a prouver sans runtime trace | MED-HIGH | DevTools network panel : capturer timestamps `fetch /api/messages/conversations` vs `fetch /api/autopilot/draft` en v3.5.179 vs v3.5.180 |
| H4 | `AISuggestionSlideOver` ouvre avant que `initialDraft` soit populee | `useEffect [initialDraft, autoOpen, conversationId]` ligne 214-222 : si `initialDraft.draftText` AND `autoOpen` AND `conversationId` -> setActiveDraft. Si l ordre arrive mal, activeDraft reste null -> label "Suggestion IA" | aucun changement AS.5 sur ce composant | MED | tester en DevTools : check if `autoOpen=true` et `initialDraft` setActiveDraft non null sous v3.5.180 vs v3.5.179 |
| H5 | `/autopilot/draft` API guard etait actif via PROTECTED_PREFIXES -> 401 | `PROTECTED_PREFIXES = ['/messages']` strict ; `/autopilot/draft` n est PAS dans la liste ; `isProtected('/autopilot/draft') === false` -> return early sans check | code AS.5 archive `src/plugins/tenantGuard.ts` lignes 33-37 clair | LOW (exclu par analyse statique stricte) | not necessary |
| H6 | BFF helper `_bff.ts` forward Cookie ou Authorization malgre la doc qui dit non | helper archive code dit explicitement "never forward Cookie or Authorization" | aucune evidence contre | LOW (exclu par lecture code) | not necessary |
| H7 | Race condition entre fetch conversation list (slow BFF) et init `autopilotDraft` state | InboxTripane line 350-365 useEffect avec `selectedId + currentTenantId` deps -> declenche fetch /autopilot/draft. Si selectedId est null initialement (avant list hydrate), early return + autopilotDraft = null. Quand list arrive et set selectedId, useEffect re-fire -> nouveau fetch. Apparemment OK en theorie. | l useEffect a deja une dep `selectedId` qui doit re-trigger | LOW-MED | DevTools : capturer timing useEffect fire vs autopilotDraft set |
| H8 | AS.5.1 useEffect autotrigger (commit 8d8121f) etait un faux-fix qui a masque la cause | commit message dit "No impact on AS.5 messages tenant guard". L auto-trigger Suggestion IA contournait le manque de Brouillon IA mais montrait "Suggestion IA" -> UX cassee | clair | HIGH (confirme) | n/a (deja confirme) |

**Verdict hypotheses** : H1 + H3 + H4 sont les plus probables, MEDIUM-HIGH confidence chacune. Aucune n est CONFIRMED par analyse statique seule. La cause exacte ne sera isolee que par instrumentation runtime DevTools en parallele v3.5.179 vs un re-deploy sandbox temporaire v3.5.180.

---

## 7. Design options

Trois options de reprise KEY-304.

### Option A - API guard only + Client unchanged

Principe : activer le tenant guard API sur `/messages` (wrap `fastify-plugin` + `PROTECTED_PREFIXES`), MAIS ne changer rien cote Client (`src/config/api.ts` reste en direct API).

| Aspect | Evaluation |
|---|---|
| Security gain | PARTIEL : la membership check serait active cote API, mais sans inject X-User-Email depuis NextAuth, le check echoue car le browser ne porte pas X-User-Email naturellement. Le client devrait inclure son email dans une header, ce qui est trivialement spoofable -> securite illusoire. |
| Client risk | nul (aucun changement Client) |
| AI draft risk | nul |
| Scope | tres petit |
| Recommended? | NON |
| Why | sans BFF Client qui injecte X-User-Email cote serveur depuis NextAuth, le check API est trivialement bypassable. C est une fausse securite. |

### Option B - BFF messages dedicated MIGRATION ENDPOINT-BY-ENDPOINT (recommande modifie)

Principe : migrer endpoint-par-endpoint cote Client, AVEC QA Brouillon IA et validation matrix complete A CHAQUE ETAPE. Ne PAS migrer les 6 endpoints conversations simultanement.

Sequence proposee :

1. AS.11.0.5 (proposition, prerequis) : runtime trace DevTools v3.5.179 vs v3.5.180 sandbox temporaire pour identifier la cause exacte AS.5. Sans cela, AS.11.1 reste un coin a l aveugle.

2. AS.11.1a : ajout cote API du wrap `fastify-plugin` + `PROTECTED_PREFIXES = []` (initialement vide). Source-only, build, deploy DEV. Smoke V1 PASS. Pas de Client change. Verification : guard actif mais aucune route protegee donc aucune regression possible. 5 min review Ludovic.

3. AS.11.1b : ajouter `/messages/conversations` (GET list uniquement) a `PROTECTED_PREFIXES`. Modifier UN SEUL endpoint dans `src/config/api.ts` : `conversations(tenantId, q)` vers `${baseUrl}/api/messages/conversations?tenantId=...` (BFF relative). Ajouter `app/api/messages/_bff.ts` helper + `app/api/messages/conversations/route.ts` GET. Build DEV, deploy. Smoke V1 + QA Brouillon IA Ludovic manuel. STOP si autopilotDraft null observe.

4. AS.11.1c : si AS.11.1b OK, ajouter `conversations/:id` GET detail. Smoke + QA.

5. AS.11.1d : `reply` POST.

6. AS.11.1e : `status` PATCH.

7. AS.11.1f : `assign` + `sav-status` PATCH.

8. AS.11.1g : promotion PROD (KEY-263) une fois tous les sous-etapes DEV verifiees.

| Aspect | Evaluation |
|---|---|
| Security gain | COMPLET pour `/messages` une fois la sequence terminee. |
| Client risk | LOW si l etape b dans AS.11.1 est validee par QA Ludovic avant les suivantes. Risque MED-HIGH si on revient au pattern "6 endpoints en une fois" AS.5. |
| AI draft risk | LOW si AS.11.1b a un gating QA Brouillon IA blocking. Risque HIGH sans gating. |
| Scope | etale dans le temps : 5-7 sous-phases AS.11.1a a 11.1g. |
| Recommended? | OUI (avec prerequis AS.11.0.5 runtime trace) |
| Why | la seule strategie qui isolerait quel endpoint precis a casse Brouillon IA. Si c est step b qui casse, on revient et on instrumentise. Si tous les steps passent, on a un guard /messages complet sans collision /autopilot/draft. |

### Option C - API guard reads NextAuth cookie directly

Principe : API verifie cookie NextAuth direct, evite le BFF.

| Aspect | Evaluation |
|---|---|
| Security gain | COMPLET (en theorie) |
| Client risk | LOW (cote Client rien ne change) |
| AI draft risk | LOW |
| Scope | tres different : nouvelle dependance API <-> NextAuth |
| Recommended? | NON sans phase de design dediee (`fastify-plugin-cookie` + decryption JWE NextAuth + key partage entre Client et API) |
| Why | couplage API <-> NextAuth nouvelle dimension de design. Risque ajoute (key management, cookie domain `.keybuzz.io`, refresh handling). KEY-306 JWT_SESSION_ERROR PROD montre que NextAuth deja sensible. Forcer l API a parser le JWE NextAuth ajoute une nouvelle surface de bug. Trop ambitieux pour AS.11.1. |

---

## 8. Recommended option

**Option B (migration endpoint-by-endpoint)** est recommandee.

Avec prerequis CRITIQUE : phase intermediaire **AS.11.0.5** (proposition, non-bloquante mais fortement recommandee) avant AS.11.1a :

- AS.11.0.5 type : runtime diagnostic, sandbox DEV, **non-mutationnel pour PROD**, gating Ludovic GO.
- Methode proposee : redeploy temporairement l image v3.5.180-messages-bff-tenant-guard-dev en sandbox / staging, parallele a v3.5.179 stable. DevTools network trace + console log timings sur SWITAA AUTOPILOT, comparant les deux versions.
- Output : identifier l hypothese exacte (H1, H3, H4 ou autre).
- Si AS.11.0.5 trop risque (DEV partage entre testeurs), alternative : analyser plus profondement le source AS.5 archive avec un focus sur `selectedId` initialisation dans InboxTripane et timing race conditions.

Si AS.11.0.5 prouve une hypothese, AS.11.1 design est ajuste en consequence (par exemple si H3 prouvee, AS.11.1b doit incorporer un loading state `selectedId === null` qui bloque le fetch `/autopilot/draft` jusqu a hydration complete).

---

## 9. Future patch boundary (AS.11.1)

Limites strictes pour la future implementation AS.11.1.

| Future patch boundary | Allowed | Forbidden | Reason |
|---|---|---|---|
| API source | `src/plugins/tenantGuard.ts` (wrap fastify-plugin + PROTECTED_PREFIXES) | tout autre fichier API | minimiser surface |
| API guard scope initial AS.11.1a | `PROTECTED_PREFIXES = []` puis ajout `'/messages/conversations'` (GET only) en AS.11.1b | `'/messages'` global immediatement | repeter erreur AS.5 |
| Client source AS.11.1b | `app/api/messages/_bff.ts` (helper, reuse AS.5 archive content) ; `app/api/messages/conversations/route.ts` (GET only) ; `src/config/api.ts` (modifier UN seul endpoint `conversations`) | 5 autres endpoints conversations dans api.ts ; aucun fichier hors `app/api/messages/**` et `src/config/api.ts` | scope minimal endpoint-by-endpoint |
| Client AS.11.1b API ai/draft surface | (lecture seulement) | `src/features/ai-ui/AISuggestionSlideOver.tsx` ; `app/inbox/InboxTripane.tsx` (autopilot draft logic) | AS.5.1 nous a appris que toucher l UI AI cree des faux-fix |
| Build args | KEY-302 sentinels obligatoires ; KEY-308 OCI labels obligatoires ; KEY-309 tag check obligatoire | rebuild sans args | hardening acquis |
| Tag image | format `vM.m.p-as11-1b-messages-conv-list-bff-dev` (suffixe explicite) | reutilisation d un tag existant | KEY-309 enforced |
| Smoke V1 | PASS required avant build AND apres rollout | bypass smoke | KEY-310 enforced |
| QA Ludovic manuel | obligatoire entre chaque sous-etape AS.11.1a -> AS.11.1g | skip QA | retour AS.5 sinon |
| Rollback plan AS.11.1b | reapply v3.5.179 + revert source `8cdc04a` (AS.5.4 anchor) | rollback partiel | rollback total seul est teste |
| Production AS.11.1 | INTERDIT tant que tous les sous-etapes DEV passes | promotion PROD | KEY-263 reste blocked sinon |

---

## 10. Future validation matrix

A executer obligatoirement avant chaque sous-etape AS.11.1.x.

### 10.1 Pre-patch (avant build/deploy)

| Validation | Method | Blocking? | Notes |
|---|---|---|---|
| smoke V1 PASS | `scripts/smoke/readonly-smoke-dev.sh` avec SMOKE_EXPECTED_*_IMAGE alignes runtime stable | OUI | KEY-310 |
| Brouillon IA visible | QA Ludovic navigateur SWITAA AUTOPILOT, conv recente, voir "Brouillon IA" auto | OUI | confirmation manuelle |
| capture route graph baseline | screenshot DevTools network panel ouverture conv SWITAA | NON (info) | reference post-patch |
| sync repos 0/0 | git rev-list origin...HEAD | OUI | KEY-309 |
| no dirty (sauf artefacts connus) | git status | OUI | |

### 10.2 Post-patch DEV (apres rollout)

| Validation | Method | Blocking? | Notes |
|---|---|---|---|
| smoke V1 PASS (avec nouveaux EXPECTED_IMAGE) | KEY-310 script | OUI | |
| Inbox conversations OK | QA Ludovic, voir liste avec >=N entries | OUI | |
| nouveaux messages affiches | QA Ludovic, ouvrir 1 conv | OUI | |
| Brouillon IA SWITAA AUTOPILOT OK | QA Ludovic, "Brouillon IA visible auto" sur conv recente | OUI ! C est le gating critique. STOP si KO. | KEY-305 |
| `/autopilot/draft` hasDraft=true | curl read-only via kubectl exec | OUI | KEY-310 section E |
| channels actifs OK | QA Ludovic ou curl /channels via BFF pattern | OUI | |
| suppliers/catalogue panel OK | QA Ludovic | OUI | |
| order/tracking panel OK | QA Ludovic conv liee commande | OUI | |
| negative tests : no-auth `/messages` -> 401 | curl direct externe sans NextAuth | OUI | KEY-301/304 |
| negative tests : bogus user -> 403 | nominal une fois BFF en place | OUI | |
| no 5xx logs | kubectl -n keybuzz-api-dev logs --since=10m \| grep statusCode:5 -c | OUI | |
| no JWT_SESSION_ERROR spike | kubectl logs Client DEV --since=10m \| grep JWT_SESSION_ERROR -c (compare baseline) | OUI | KEY-306 |
| no DEV -> PROD API leak in bundle | KEY-302 verify-client-bundle-api-url.sh | OUI | KEY-302 |
| OCI labels non-`unknown` | docker image inspect --format '{{...}}' | OUI | KEY-308 |
| tag immuable nouveau | scripts/registry/check-image-tag-available.sh AVANT push | OUI | KEY-309 |

---

## 11. Gaps

1. **Cause exacte AS.5 -> Brouillon IA absent non isolee en statique**. H1, H3, H4 = MED-HIGH confidence chacune. Phase AS.11.0.5 runtime trace recommandee mais non realisee dans AS.11. Gap traceability principal.

2. **Pas de runtime trace v3.5.180 sandbox**. Risque de re-introduire le bug si AS.11.1b est lance sans isoler la cause au prealable.

3. **AS.11.1 sequence longue** : 5-7 sous-etapes signifient 5-7 builds + deploys + QA Ludovic. Cout temps eleve. Justifie vu l incident historique mais a documenter dans le scheduling.

4. **`/autopilot/draft` route source-level non plus protegee** : meme apres AS.11.1g, seul `/messages/conversations*` sera protege. `/autopilot/draft` reste accessible sans tenant guard. KEY-304 etend a `/autopilot` plus tard ; hors scope AS.11.

5. **`/channels`, `/suppliers`, `/orders`, `/stats`** : meme remarque. KEY-304 endpoint-by-endpoint full rollout = phases ulterieures multiples.

6. **API source intermediaire AS.4.1 (`v3.5.169-tenant-guard-scope-fix-dev`)** marque DO_NOT_REDEPLOY avait essaye un guard global (pas allowlist). Source archive seulement. A reference dans AS.11.0.5 si on veut comparer ce qui exact a casse.

7. **PROD KEY-263 promotion AS.1 notifications** : bloquee tant que KEY-304 non resolu. Schedule AS.1 PROD = apres AS.11.1g + QA complete.

---

## 12. Linear text prepared, posted

Texte poste sur KEY-304 (cf section 12.bis URL).

### 12.bis Resume Linear poste (controle)

```
## AS.11 -- design read-only de reprise KEY-304 (no patch, no runtime mutation)

Phase d analyse statique livree :
- diff AS.5 reconstruit (eae84b58 API + 57766ea Client BFF + 8d8121f AS.5.1 useEffect autotrigger).
- route graph Client + API documente.
- 8 hypotheses cause Brouillon IA SWITAA AUTOPILOT absent post-AS.5 evaluees ; H1+H3+H4 = MED-HIGH chacune, aucune CONFIRMED en static.
- 3 options de reprise (A API guard only, B BFF migration endpoint-by-endpoint, C API guard reads NextAuth cookie).

Recommandation : **Option B avec migration endpoint-par-endpoint** (5-7 sous-phases AS.11.1a a AS.11.1g, QA Brouillon IA gating a chaque etape) precede d une phase intermediaire optionnelle AS.11.0.5 (runtime DevTools trace v3.5.179 vs v3.5.180 sandbox) pour isoler la cause exacte AS.5.

KEY-304 reste a NE PAS Done. AS.11.1 patch ne doit pas etre lance sans GO Ludovic explicite, sans AS.11.0.5, et sans matrice de validation pre/post-patch (smoke V1 + QA Brouillon IA + curl negatif).

Aucun patch, aucun build, aucun docker push, aucun kubectl apply, aucun deploy. Runtime DEV+PROD strictement inchanges.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11-MESSAGES-TENANTGUARD-REDESIGN-READONLY-01.md
```

Statut suggere : In Review (design ready, pas Done car implementation/runtime non realisee).

Disclosure controle respecte : pas de PoC, pas de commandes exploitables, pas de detail mecanique fastify-plugin reproductible, pas de noms fichiers sensibles au-dela des references publiques (api.ts, AISuggestionSlideOver.tsx) deja documentees dans les rapports AS.5.x.

---

### 12.ter Phrase cible finale

AS.11 livre l analyse de design read-only pour la reprise KEY-304 : diff AS.5 reconstruit (3 commits), route graph Client + API documente, 8 hypotheses cause Brouillon IA absente analysees sans isolation statique definitive (H1+H3+H4 MED-HIGH), 3 options evaluees, Option B (migration endpoint-by-endpoint avec gating QA Brouillon IA strict) recommandee precede d AS.11.0.5 runtime trace optionnelle ; aucun patch, aucun build, aucun docker push, aucun kubectl apply, aucun deploy, aucune mutation runtime/DB/manifest/secret ; runtime DEV+PROD strictement inchanges ; verdict AS.11 GO PARTIAL DESIGN READY - ROOT CAUSE STILL UNCLEAR.

STOP
