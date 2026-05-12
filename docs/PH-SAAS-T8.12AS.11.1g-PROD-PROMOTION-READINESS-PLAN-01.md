# PH-SAAS-T8.12AS.11.1g-PROD-PROMOTION-READINESS-PLAN-01

> Date : 2026-05-12
> Linear : KEY-304 (principal), KEY-301, KEY-263 (contexte)
> Phase : T8.12 AS.11.1g READINESS PLAN ONLY -- no deploy, no build, no kubectl apply
> Environnement : PROD READINESS audit ; runtime read-only strict

---

## 1. VERDICT

GO PARTIAL PROD PROMOTION PLAN READY WITH RISKS

DEV 6/6 endpoints `/messages/conversations*` proteges et valides (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS). Runtime DEV API v3.5.175 + Client v3.5.189, MATCH=yes GitOps, smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1, QA Ludovic OK. PROD strictement inchange (8 services sur baselines pre-AS.5).

**Risque structurel identifie** : le delta source DEV vs PROD est superieur au scope KEY-304 seul. La promotion PROD bundlera mecaniquement plusieurs autres features livrees en DEV depuis la rollback AS.5.3, notamment :

- KEY-263 (AS.1 escalation notifications base API + Client)
- KEY-302 (Client build args hardening)
- KEY-304 (6 BFF migrations + 6 matchers tenantGuard)
- KEY-305 (fix AI draft consolidated useEffect AS.11.0.6)
- KEY-308 (OCI revision labels)
- KEY-310 (smoke harness V1)

Cette phase plan ne demande PAS la promotion : elle prepare la matrice de decision. La phase execution (AS.11.1g-PROD-PROMOTION-EXECUTION) ne pourra etre lancee qu apres GO Ludovic explicite avec sequencement choisi (bundle complet vs cherry-pick KEY-304 only).

KEY-304 reste In Review. KEY-301 reste Open. KEY-263 reste In Review (debloquable seulement si Ludovic accepte le bundle PROD).

---

## 2. Scope

Cette phase est strictement read-only audit + planification.

Inclus :
- Verification repos preflight + runtime DEV/PROD + GitOps drift.
- Recap source 6/6 endpoints DEV proteges.
- Identification exacte du delta source PROD -> DEV pour API + Client.
- Matrice des risques fonctionnels PROD.
- Plan build futur (tags candidats, build args, OCI labels, KEY-302 verify).
- Plan GitOps futur (manifests, ordre apply, rollback).
- Plan validation PROD futur (read-only post-deploy + scope mutation explicite Ludovic GO requis).
- Rapport docs-only commit + push.
- Commentaires Linear disclosure-controlled apres rapport publie.

Strictement HORS scope :
- Aucun build (no docker build).
- Aucun docker push.
- Aucun kubectl apply / set / patch / edit / set env.
- Aucune modification manifest (API ou Client, DEV ou PROD).
- Aucune mutation DB.
- Aucun test POST / PATCH mutationnel.
- Aucun deploy PROD ni rollback PROD.
- Aucun changement secret / env.
- Aucun changement statut Linear vers Done.
- Aucune promotion KEY-263 dans cette phase.

---

## 3. Sources read

Lectures realisees (chronologie verifie) :

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` -- baseline runtime + GitOps rules + Linear disclosure.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1A-R2-MESSAGES-LIST-TENANTGUARD-REAPPLY-DEV-01.md` -- LIST.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1A-R2-QA-CLOSEOUT-01.md` -- LIST QA.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1C-MESSAGES-DETAIL-TENANTGUARD-DEV-01.md` -- DETAIL.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1C-QA-CLOSEOUT-01.md` -- DETAIL QA.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1D-MESSAGES-REPLY-TENANTGUARD-DEV-01.md` -- REPLY.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1E-MESSAGES-STATUS-TENANTGUARD-DEV-01.md` -- STATUS.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-1-MESSAGES-ASSIGN-TENANTGUARD-DEV-01.md` -- ASSIGN.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-2-MESSAGES-SAV-STATUS-TENANTGUARD-DEV-01.md` -- SAV-STATUS.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-2-QA-MESSAGES-6OF6-CLOSEOUT-01.md` -- QA 6/6.
- `keybuzz-infra/docs/PH-SAAS-T8.12AR.5.2-CONVERSATION-TONE-INTERNAL-METRIC-PROD-PROMOTION-01.md` -- PROD source commits anchor.
- `keybuzz-client/docs/BUILD-ARGS.md` (lu via grep) -- KEY-302 sentinels.
- `keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md` (refere par check-image-tag-available.sh) -- KEY-309 tag policy.

SOT statut : `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` date du `2026-05-11 (AS.6.2 KEY-311)`, indique baselines DEV API `v3.5.168-escalation-notifications-dev` + Client `v3.5.179-as1-1-build-args-fix-dev`. **Cette section est obsolete** apres AS.11.1A-R2 -> AS.11.1F-2. Une mise a jour SOT (re-checkpoint baseline DEV) est suggere mais NON realisee dans cette phase (scope plan only). A traiter par phase AS.6.x SOT refresh ulterieurement.

---

## 4. Preflight repos

| Repo | Path | Branch | HEAD | Sync origin | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 3f45a7e0 | 0/0 | `D dist/*.js` (artifact compris, OK) | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | 094163b | 0/0 | `M tsconfig.tsbuildinfo` (artifact compris, OK) | OK |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | bb3163f | 0/0 | clean | OK |

Bastion : `install-v3` (46.62.171.61) confirme. Aucune autre IP.

---

## 5. Runtime DEV/PROD

| Env | Service | Spec image | Last-applied | Pod image | Ready | Restarts | MATCH |
|---|---|---|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.175-messages-sav-status-tenantguard-dev | identical | identical | 1/1 | 0 | YES |
| DEV | keybuzz-client | v3.5.189-messages-sav-status-bff-dev | identical | identical | 1/1 | 0 | YES |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod | identical | identical | 1/1 | 0 | YES |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | identical | identical | 1/1 | 7 (13d ago) | YES |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | identical | identical | 1/1 | 0 | YES |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | identical | identical | 1/1 | 0 | YES |
| PROD | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | identical | identical | 1/1 | 0 | YES |
| PROD | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | identical | identical | 1/1 | 0 | YES |
| PROD | backfill-scheduler | v1.0.42-td02-worker-resilience-prod | identical | identical | 1/1 | 0 | YES |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | identical | identical | 1/1 | 0 | YES |

GitOps drift NONE sur les 10 deployments. Pods ready. PROD outbound-worker a 7 restarts mais age 13j -- ne fait pas partie du scope AS.11.1g.

PROD images ne portent PAS d OCI label `org.opencontainers.image.revision` (KEY-308 ajoute aux Dockerfiles APRES la build de ces images PROD). La source commit PROD a donc ete retrouvee via rapports infra (cf section 6 / 7).

---

## 6. DEV 6/6 recap

Source verification dans `keybuzz-api/src/plugins/tenantGuard.ts` HEAD `3f45a7e0` (runtime API DEV v3.5.175) :

| # | Endpoint | Method | Matcher source | Phase | Runtime DEV image | Validation negatifs | DB no-mutation | QA Ludovic | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 1 | /messages/conversations | GET | PROTECTED_ROUTES entry | AS.11.1A-R2 | v3.5.170-messages-list-tenantguard-dev (rolled forward a v3.5.175) | 3/3 PASS | read-only | OK | OK |
| 2 | /messages/conversations/:id | GET | isMessagesConversationDetailGet | AS.11.1C | v3.5.171 (rolled forward) | 7/7 PASS | read-only | OK | OK |
| 3 | /messages/conversations/:id/reply | POST | isMessagesConversationReplyPost | AS.11.1D | v3.5.172 (rolled forward) | 8/8 PASS | messages count delta 0 (162 -> 162) | non clique | OK |
| 4 | /messages/conversations/:id/status | PATCH | isMessagesConversationStatusPatch | AS.11.1E | v3.5.173 (rolled forward) | 8/8 PASS | status_change events delta 0 | non clique | OK |
| 5 | /messages/conversations/:id/assign | PATCH | isMessagesConversationAssignPatch | AS.11.1F-1 | v3.5.174 (rolled forward) | 10/10 PASS | assign events delta 0 (1 -> 1 frozen) | non clique | OK |
| 6 | /messages/conversations/:id/sav-status | PATCH | isMessagesConversationSavStatusPatch | AS.11.1F-2 | v3.5.175-messages-sav-status-tenantguard-dev (current) | 10/10 PASS | sav_status_change delta 0 (1 -> 1 frozen) | non clique | OK |

Client BFF routes presentes bundle v3.5.189 (verifie AS.11.1F-2 build) : 6/6 (list, detail, reply, status, assign, sav-status).

`isProtected()` reference 5 matchers dynamiques + 1 PROTECTED_ROUTES static = 6 endpoints en allowlist runtime DEV.

Smoke V1 DEV courant (re-run dans cette phase, read-only) : PASS=17 WARN=1 FAIL=0 SKIP=1 RESULT=PASS_WITH_WARNINGS (WARN /messages/conversations 401 = attendu).

---

## 7. DEV -> PROD delta

Source PROD anchors retrouves via `keybuzz-infra/docs/PH-SAAS-T8.12AR.5.2-CONVERSATION-TONE-INTERNAL-METRIC-PROD-PROMOTION-01.md` :

| Repo | PROD runtime image | PROD source HEAD | Confidence | DEV runtime image | DEV source HEAD | Commits dans delta | Risk |
|---|---|---|---|---|---|---|---|
| keybuzz-api | v3.5.151-conversation-tone-metric-prod | 0e26bfc3 | HIGH (rapport AR.5.2 documente le commit + digest sha256:29e53af3...) | v3.5.175-messages-sav-status-tenantguard-dev | 3f45a7e0 | 12 commits (dont 4 reverts qui s annulent par paire) | MED-HIGH |
| keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | 0a7306a | HIGH (rapport AR.5.2 documente le commit + digest sha256:8d2e195...) | v3.5.189-messages-sav-status-bff-dev | 094163b0 | 22 commits (dont 7 reverts par paire) | MED-HIGH |

### 7.1 API delta detail (12 commits sur 0e26bfc3..3f45a7e0)

Commits fonctionnels nets (revert pairs annules) :

| Commit | Sujet | KEY |
|---|---|---|
| 070707a1 | feat(notifications): internal escalation notifications + tenant-scoped routes (PH-SAAS-T8.12AS.1, KEY-263) | KEY-263 |
| f371a79c | chore(build): add OCI revision labels to Docker image (KEY-308) | KEY-308 |
| 3f669057 | fix(security): protect messages conversations list with tenant guard (KEY-304) | KEY-304 |
| 67b5c653 | fix(security): protect messages conversation detail with tenant guard (KEY-304) | KEY-304 |
| 76435e22 | fix(security): protect messages reply with tenant guard (KEY-304) | KEY-304 |
| b40b0c64 | fix(security): protect messages status update with tenant guard (KEY-304) | KEY-304 |
| 6e166eac | fix(security): protect messages assign with tenant guard (KEY-304) | KEY-304 |
| 3f45a7e0 | fix(security): protect messages sav-status with tenant guard (KEY-304) | KEY-304 |

Commits revert (paires neutralisees) : `eae84b58` + revert `b8613f0f` (AS.5 global tenant guard, deja annule en source) ; `4d88e989` + revert `a523db7c` (premiere tentative global, deja annule en source).

Fichiers source touches (PROD -> DEV) :

```
Dockerfile                                  -- KEY-308 OCI labels build args
src/lib/escalationNotification.ts           -- KEY-263 AS.1 base
src/modules/ai/ai-assist-routes.ts          -- KEY-263 AS.1 (tenant-scoped routes)
src/modules/autopilot/engine.ts             -- KEY-263 AS.1
src/modules/autopilot/routes.ts             -- KEY-263 AS.1
src/modules/messages/routes.ts              -- KEY-263 AS.1 (escalation field)
src/modules/notifications/routes.ts         -- KEY-263 AS.1 (nouveau endpoint)
src/plugins/tenantGuard.ts                  -- KEY-304 (5 matchers + 1 PROTECTED_ROUTES + fastify-plugin wrap)
```

### 7.2 Client delta detail (22 commits sur 0a7306a..094163b0)

Commits fonctionnels nets (revert pairs annules) :

| Commit | Sujet | KEY |
|---|---|---|
| 37e70ac | feat(inbox): escalation notifications badge + tenant-scoped client (PH-SAAS-T8.12AS.1, KEY-263) | KEY-263 |
| a69477a | fix(inbox): unwire AS.1 escalation badge from InboxTripane to restore conversation list (PH-SAAS-T8.12AS.1.1, KEY-263) | KEY-263 |
| f244a58 | fix(client-build): require explicit API build args for safe bundles (KEY-302) | KEY-302 |
| 4011ada | chore(build): add OCI revision labels to Docker image (KEY-308) | KEY-308 |
| 7a8a2fb | test(smoke): add read-only DEV smoke harness (KEY-310) | KEY-310 |
| e6f29c8 | fix(inbox): prevent AI draft reset from overriding initial draft (KEY-305) | KEY-305 |
| dc5e35d | fix(client): route conversations list through authenticated BFF (KEY-304) | KEY-304 |
| efa08dd | fix(client): route conversation detail through authenticated BFF (KEY-304) | KEY-304 |
| b230aa9 | fix(client): route message reply through authenticated BFF (KEY-304) | KEY-304 |
| bc3a50c | fix(client): route conversation status update through authenticated BFF (KEY-304) | KEY-304 |
| b429238 | fix(client): route conversation assign through authenticated BFF (KEY-304) | KEY-304 |
| 094163b | fix(client): route conversation sav-status through authenticated BFF (KEY-304) | KEY-304 |

Commits revert (paires neutralisees) : `de498b0` + `9a2081c` ; `49a99f9` + `ae915be` ; `a032d83` + `38b1b62` ; `57766ea` + `8cdc04a` ; `8d8121f` + `d468991`. Total 5 paires de tentatives BFF/AI annulees, net effet zero.

Fichiers source touches (PROD -> DEV) :

```
Dockerfile                                                       -- KEY-308 + KEY-302 build args
app/api/messages/_bff.ts                                         -- KEY-304 helper
app/api/messages/conversations/route.ts                          -- KEY-304 LIST
app/api/messages/conversations/[id]/route.ts                     -- KEY-304 DETAIL
app/api/messages/conversations/[id]/reply/route.ts               -- KEY-304 REPLY
app/api/messages/conversations/[id]/status/route.ts              -- KEY-304 STATUS
app/api/messages/conversations/[id]/assign/route.ts              -- KEY-304 ASSIGN
app/api/messages/conversations/[id]/sav-status/route.ts          -- KEY-304 SAV-STATUS
app/api/notifications/route.ts                                   -- KEY-263 AS.1
docs/BUILD-ARGS.md                                               -- KEY-302 docs
scripts/check-client-build-args.sh                               -- KEY-302 guard
scripts/smoke/README.md                                          -- KEY-310 docs
scripts/smoke/readonly-smoke-dev.sh                              -- KEY-310 harness
scripts/verify-client-bundle-api-url.sh                          -- KEY-302 verify
src/config/api.ts                                                -- KEY-304 (6 endpoints relative)
src/features/ai-ui/AISuggestionSlideOver.tsx                     -- KEY-305 consolidated useEffect
src/features/inbox/components/AgentWorkbenchBar.tsx              -- KEY-263 badge
src/features/inbox/hooks/useEscalationNotifsCount.ts             -- KEY-263 hook
src/services/notifications.service.ts                            -- KEY-263 service
```

### 7.3 Bundle vs cherry-pick decision

**Constat critique** : la promotion PROD via tag `v3.5.176-messages-tenantguard-prod` + `v3.5.190-messages-bff-tenantguard-prod` construit a partir de HEAD DEV courant bundlera mecaniquement KEY-263 + KEY-302 + KEY-304 + KEY-305 + KEY-308 + KEY-310.

Deux options pour le sequencement PROD :

#### Option A -- BUNDLE complet (recommande en premier lieu)

Promouvoir HEAD DEV courant tel quel.

- Avantages : simplicite, source = runtime, pas de divergence DEV/PROD source apres promotion, KEY-263 finalement deboucle, KEY-305 AI draft fix livre en PROD, KEY-308 + KEY-310 + KEY-302 deviennent les baselines PROD pour les phases futures.
- Risques : blast radius eleve, multi-feature simultane, regressions potentielles non strictement KEY-304.

#### Option B -- Cherry-pick branche KEY-304 only

Creer une branche temporaire qui ne contient que les commits KEY-304 (7 commits API tenantGuard + 7 commits Client BFF) sur top du commit PROD source (0e26bfc3 pour API, 0a7306a pour Client).

- Avantages : blast radius minimal, scope KEY-304 strict, KEY-263 etc. restent en backlog.
- Risques : divergence source DEV/PROD prolongee, prochaine promotion devra reproduire l effort, KEY-304 isole de KEY-302 cree risque de regression KEY-302 sur premiere rebuild future.

**Recommandation** : Option A (bundle) est plus sain a long terme MAIS doit etre validee explicitement par Ludovic, en particulier sur KEY-263 AS.1 (qui avait deja un patch correctif AS.1.1 mais reste un changement comportemental visible cote Inbox).

---

## 8. Risk matrix

| # | Risk | Cause possible | Detection | Rollback trigger | Severity |
|---|---|---|---|---|---|
| R1 | NextAuth cookies PROD differents de DEV (domaine, secure flags) | Cookies set sur client-dev.keybuzz.io vs client.keybuzz.io ; getServerSession peut echouer en PROD si secret/host different | Logs Client 5xx + JWT_SESSION_ERROR + smoke /api/auth/session non 200 | toute requete BFF retourne 401 NO_SESSION pour utilisateur authentifie legitime | HIGH |
| R2 | API_URL_INTERNAL non defini en namespace PROD Client | BFF helper getApiInternalUrl() retourne string vide -> 503 BFF_MISCONFIGURED | Logs Client + smoke V1 /api/messages/conversations | toute requete BFF retourne 503 | HIGH |
| R3 | tenant_id manquant dans appels Client legacy non encore migres | conversationStats / autres routes hors scope KEY-304 utilisent encore baseUrl direct, mais ce delta n est pas touche par AS.11.1g | Logs API 5xx | non specifique a AS.11.1g | LOW |
| R4 | Build args PROD Client mal positionnes (NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io) | Si build sans args explicites -> sentinel `__MUST_BE_SET_BY_BUILD_ARG__` casse npm build | KEY-302 guard catch au build | rollback build (n a pas atteint PROD) | LOW (build-time fail) |
| R5 | KEY-263 AS.1 escalation badge revenir en PROD (Inbox UI) | Bundle inclut feat(inbox): escalation notifications badge + AS.1.1 unwire fix | QA UI Inbox PROD : badge AS.1 visible ou pas, conversation list visible | si Inbox cassee -> rollback | MED |
| R6 | KEY-305 AI draft consolidated useEffect comportement DIFFERENT sur conversations PROD | DEV target a une distribution de conversations differente de PROD (volumes, types) ; le fix AS.11.0.6 a ete QA-OK en DEV mais pas en PROD | Logs Client Brouillon IA + QA Ludovic PROD | si Brouillon IA disparait ou hydrate incorrectement | MED |
| R7 | tenantGuard reject de session valide PROD pour ludovic.gonthier@gmail.com qui est admin sur d autres tenants | user_tenants table PROD doit contenir les bindings attendus pour Ludovic ET ses ressources | Test PROD post-deploy avec switaa26 + autre tenant | 403 NOT_MEMBER sur un tenant ou Ludovic devrait avoir acces | HIGH |
| R8 | message_events PROD volumes (audit log croissance) | Aucune mutation supplementaire vs baseline ; tenantGuard rejette avant handler -> moins d events insered (positif) | Monitoring DB | non-trigger rollback | LOW (positive impact) |
| R9 | Smoke V1 PROD-readonly non implementee (V1 = DEV only) | Pas de couverture automatique post-deploy PROD ; doit etre Ludovic QA manuel | absence | risque masque jusqu QA | MED |
| R10 | KEY-263 AS.1 declenche nouvelle regression Inbox (replay de l incident PH152 / AS.5) | meme code base que AS.5 mais AS.5 a ete revert et AS.1.1 deja applique en DEV runtime SANS regression observee | logs API 5xx + logs Client + QA | si Inbox PROD casse | MED |
| R11 | OCI labels absents sur PROD post-deploy si build args oublies | KEY-308 ne fait pas fail build si args absents (defaut "unknown"), donc PROD pourrait avoir "unknown" si oubli ; non-critique mais documente | docker image inspect post-build | non-trigger rollback | LOW |
| R12 | KEY-309 tag re-use accidentel | Si build a la mauvaise heure et tag pre-existe sur GHCR | scripts/registry/check-image-tag-available.sh pre-push | rollback build avant push | LOW (check existant) |

Vulnerabilites couvertes apres promotion :
- KEY-304 LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS en PROD
- KEY-301 mitigation `/messages` complete en PROD
- KEY-263 AS.1 escalation notifications base livree en PROD (si bundle)

Vulnerabilites NON couvertes par AS.11.1g :
- Endpoints `/messages/conversations/:id/escalation` (PATCH) -- handler-level encore, scope hors AS.11.1g.
- Autres modules `/notifications`, `/billing`, etc. -- scope hors KEY-304.

---

## 9. Future build plan (NE PAS EXECUTER ICI)

### 9.1 API

Tag candidate : `v3.5.176-messages-tenantguard-prod` (AVAILABLE sur GHCR au moment de l audit).

Commandes attendues (a NE PAS executer dans cette phase) :

```
cd /opt/keybuzz/keybuzz-api
git status --porcelain          # MUST be clean (artifact dist/ tolere)
git rev-parse HEAD              # expected 3f45a7e0 ou successeur si commits ajoutes
git fetch origin -q && git rev-list --left-right --count origin/ph147.4/source-of-truth...HEAD   # expected 0 0

/opt/keybuzz/keybuzz-infra/scripts/registry/check-image-tag-available.sh \
  ghcr.io/keybuzzio/keybuzz-api:v3.5.176-messages-tenantguard-prod
# expected exit 0 AVAILABLE

API_C=$(git rev-parse HEAD)
CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TAG=v3.5.176-messages-tenantguard-prod

docker build --pull --no-cache \
  -t ghcr.io/keybuzzio/keybuzz-api:$TAG \
  --build-arg IMAGE_REVISION=$API_C \
  --build-arg IMAGE_CREATED=$CREATED \
  --build-arg IMAGE_VERSION=$TAG \
  -f Dockerfile .

docker image inspect ghcr.io/keybuzzio/keybuzz-api:$TAG --format '{{json .Config.Labels}}'
# expected revision = $API_C, version = $TAG, source = github

docker push ghcr.io/keybuzzio/keybuzz-api:$TAG
docker inspect ghcr.io/keybuzzio/keybuzz-api:$TAG --format '{{index .RepoDigests 0}}'
# capture digest pour rapport execution
```

### 9.2 Client

Tag candidate : `v3.5.190-messages-bff-tenantguard-prod` (AVAILABLE).

Commandes attendues :

```
cd /opt/keybuzz/keybuzz-client
git status --porcelain          # M tsconfig.tsbuildinfo tolere
git rev-parse HEAD              # expected 094163b0 ou successeur

/opt/keybuzz/keybuzz-infra/scripts/registry/check-image-tag-available.sh \
  ghcr.io/keybuzzio/keybuzz-client:v3.5.190-messages-bff-tenantguard-prod

CLI_C=$(git rev-parse HEAD)
CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TAG=v3.5.190-messages-bff-tenantguard-prod

docker build --pull --no-cache \
  -t ghcr.io/keybuzzio/keybuzz-client:$TAG \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg GIT_COMMIT_SHA=$CLI_C \
  --build-arg BUILD_TIME=$CREATED \
  --build-arg IMAGE_REVISION=$CLI_C \
  --build-arg IMAGE_CREATED=$CREATED \
  --build-arg IMAGE_VERSION=$TAG \
  -f Dockerfile .

# KEY-302 verify bundle PROD :
CID=$(docker create ghcr.io/keybuzzio/keybuzz-client:$TAG)
docker cp $CID:/app/.next/static /tmp/k302-as111g
docker rm $CID
API_PROD_COUNT=$(grep -roE 'api\.keybuzz\.io[^a-z-]' /tmp/k302-as111g | wc -l)   # MUST be > 0
API_DEV_COUNT=$(grep -roE 'api-dev\.keybuzz\.io' /tmp/k302-as111g | wc -l)        # MUST be 0
SENTINEL=$(grep -roE '__MUST_BE_SET_BY_BUILD_ARG__' /tmp/k302-as111g | wc -l)    # MUST be 0
BROUILLON=$(grep -roE 'Brouillon IA' /tmp/k302-as111g | wc -l)                   # MUST be > 0
VALIDER=$(grep -roE 'Valider et envoyer' /tmp/k302-as111g | wc -l)               # MUST be > 0
rm -rf /tmp/k302-as111g

docker image inspect ghcr.io/keybuzzio/keybuzz-client:$TAG --format '{{json .Config.Labels}}'
docker push ghcr.io/keybuzzio/keybuzz-client:$TAG
docker inspect ghcr.io/keybuzzio/keybuzz-client:$TAG --format '{{index .RepoDigests 0}}'
```

Gates obligatoires pre-push (KEY-309) :
- AVAILABLE check
- OCI revision != "unknown"
- KEY-302 PROD verify : api-prod > 0, api-dev = 0, sentinel = 0, labels Brouillon IA + Valider et envoyer presents

---

## 10. Future GitOps plan (NE PAS EXECUTER ICI)

### 10.1 Fichiers a modifier

- `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` (1 ligne image)
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` (1 ligne image)

Aucun changement aux autres manifests PROD (namespace, ingress, service, externalsecrets, cronjobs).

### 10.2 Diff attendu

```yaml
# keybuzz-api-prod/deployment.yaml
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.151-conversation-tone-metric-prod
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.176-messages-tenantguard-prod

# keybuzz-client-prod/deployment.yaml
- image: ghcr.io/keybuzzio/keybuzz-client:v3.5.174-conversation-tone-metric-ux-prod
+ image: ghcr.io/keybuzzio/keybuzz-client:v3.5.190-messages-bff-tenantguard-prod
```

Diff stat attendu : `2 files changed, 2 insertions(+), 2 deletions(-)`.

### 10.3 Ordre apply

1. `git add k8s/keybuzz-api-prod/deployment.yaml k8s/keybuzz-client-prod/deployment.yaml`
2. `git commit -m 'gitops(prod): promote messages tenantGuard API+Client (AS.11.1g KEY-304/301/263)'`
3. `git push origin main`
4. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
5. `kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s`
6. Verifier spec == last-applied == pod image, /health 200, 0 5xx 5min.
7. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
8. `kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s`
9. Verifier spec == last-applied == pod image, /api/auth/session 200, 0 JWT_SESSION_ERROR 5min.

GitOps strict : aucun kubectl set / patch / edit / set env. Aucun namespace touche hors `keybuzz-api-prod` + `keybuzz-client-prod`.

### 10.4 Cronjobs / workers PROD

`keybuzz-outbound-worker` PROD reste sur `v3.5.165-escalation-flow-prod` -- separe du deployment API. Decision : NE PAS bumper le worker dans AS.11.1g (le worker n appelle pas les routes BFF `/messages` cote Client et n est pas dans le scope KEY-304). KEY-263 escalation worker existant continue d operer sans changement.

### 10.5 Manifest commit propose (a NE PAS executer ici)

```
gitops(prod): promote messages tenantGuard API+Client (AS.11.1g KEY-304/301/263)
```

---

## 11. Future rollback plan (NE PAS EXECUTER ICI)

Rollback PROD strict GitOps :

```
cd /opt/keybuzz/keybuzz-infra
git revert <commit_promotion_AS.11.1g> --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml          # -> v3.5.151
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml       # -> v3.5.174
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Tags rollback exacts :
- API PROD : `v3.5.151-conversation-tone-metric-prod` (sha256:29e53af3db7...)
- Client PROD : `v3.5.174-conversation-tone-metric-ux-prod` (sha256:8d2e195ae6c...)

Triggers rollback immediat :
- Inbox liste PROD vide / cassee
- detail conversation inaccessible
- nouveaux messages bloques
- Brouillon IA disparait
- banniere "API indisponible" persistante
- Logs API PROD > 0 5xx anormal (baseline)
- Logs Client PROD > 0 JWT_SESSION_ERROR sustained
- 403 NOT_MEMBER sur un compte legitime qui devrait avoir acces

Fenetre de surveillance recommandee post-deploy : minimum 30 min Ludovic actif + 24h passif sur metriques.

---

## 12. Future PROD validation matrix (NE PAS EXECUTER ICI)

### 12.1 Read-only / safe checks (PROD post-deploy)

1. Runtime images match :
   - `kubectl -n keybuzz-api-prod get deploy keybuzz-api -o jsonpath='{.spec.template.spec.containers[0].image}'` == nouveau tag
   - meme verification spec / last-applied / pod / digest
2. /health API PROD : `curl -sf https://api.keybuzz.io/health` -> 200 ok
3. Logs API PROD 5min : `kubectl -n keybuzz-api-prod logs deploy/keybuzz-api --since=5m | grep -cE 'statusCode\":5'` -> 0
4. Logs Client PROD 5min : `kubectl -n keybuzz-client-prod logs deploy/keybuzz-client --since=5m | grep -c 'JWT_SESSION_ERROR'` -> 0
5. /api/auth/session PROD : `curl -s https://client.keybuzz.io/api/auth/session` -> 200 JSON
6. Smoke V1 PROD : actuellement non couvert (V1 = DEV only). Une extension PROD-readonly serait un livrable KEY-310 V2.

### 12.2 Negative-only HTTP checks (autorise post-deploy)

Memes patterns que les tests AS.11.1A-R2 ... AS.11.1F-2 mais sur `https://api.keybuzz.io` :

| Check | Expected |
|---|---|
| GET /messages/conversations no-auth | 401 |
| GET /messages/conversations/:fakeid no-auth | 401 |
| POST /messages/conversations/:fakeid/reply no-auth | 401 |
| PATCH /messages/conversations/:fakeid/status no-auth | 401 |
| PATCH /messages/conversations/:fakeid/assign no-auth | 401 |
| PATCH /messages/conversations/:fakeid/sav-status no-auth | 401 |

Aucun PoC ni id de conversation reelle dans les tests PROD post-deploy. Utilisation d un UUID factice uniquement.

### 12.3 Mutation checks PROD

**INTERDITS par defaut.** Toute validation mutationnelle PROD doit faire l objet d une phase dedicate avec GO Ludovic explicite, scope mutation precise, conversation fixture controlee, et plan rollback DB ou preuve idempotente.

### 12.4 QA Ludovic navigateur PROD (apres validation read-only OK)

Sur `https://client.keybuzz.io` connecte avec compte business :
- Inbox liste visible
- detail conversation visible
- nouveaux messages visibles
- Brouillon IA auto visible (KEY-305 dans bundle)
- bouton "Valider et envoyer" visible (NE PAS cliquer sans GO mutationnel separe)
- boutons statut / assigner / SAV visibles (NE PAS cliquer)
- escalation badge AS.1 visible si KEY-263 bundle (NE PAS cliquer)
- aucune banniere erreur
- aucune regression visible

Fenetre QA Ludovic : minimum 30 min directe + monitoring passif 24h.

---

## 13. Linear text prepared

A poster apres rapport commit + push, en disclosure-controlled, **uniquement avec GO Ludovic explicite et methode token agreee** (file bastion `/opt/keybuzz/.linear-token`, env `/root/.linear.env`, ou Ludovic poste lui-meme).

### 13.1 KEY-304 commentaire (texte cible)

```
## AS.11.1g readiness plan ready -- PROD promotion not yet executed

- DEV 6/6 endpoints `/messages/conversations*` protected and validated (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS) per series AS.11.1A-R2 -> AS.11.1F-2 + QA closeout.
- Runtime DEV API v3.5.175 + Client v3.5.189, MATCH=yes GitOps, smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1, QA Ludovic OK.
- PROD strictly unchanged (8 services on pre-AS.5 baselines).

DEV -> PROD delta identified:
- API : 12 commits over PROD source 0e26bfc3 -> DEV HEAD 3f45a7e0. Net effect (after revert pairs) = KEY-263 base + KEY-304 (6 matchers) + KEY-308.
- Client : 22 commits over PROD source 0a7306a -> DEV HEAD 094163b0. Net effect (after revert pairs) = KEY-263 + KEY-302 + KEY-304 (6 BFF routes) + KEY-305 + KEY-308 + KEY-310.

PROD candidate tags AVAILABLE : v3.5.176-messages-tenantguard-prod (API) + v3.5.190-messages-bff-tenantguard-prod (Client).

Two sequencing options identified (rapport sections 7.3 + 8 detail) :
- Option A : bundle full DEV head to PROD (recommended for source/runtime parity).
- Option B : cherry-pick KEY-304-only branch (smaller blast radius, longer divergence).

Future execution phase (AS.11.1g-PROD-PROMOTION-EXECUTION) requires explicit Ludovic GO + sequencing decision. This readiness phase did not build, push, or deploy.

KEY-304 stays In Review.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-PROD-PROMOTION-READINESS-PLAN-01.md
```

### 13.2 KEY-301 commentaire (texte cible)

```
Readiness plan for PROD promotion of /messages tenantGuard mitigation is ready (AS.11.1g rapport committed, no build/push/deploy executed).

DEV 6/6 endpoints `/messages/conversations*` protected and validated. PROD strictly unchanged. Tag candidates AVAILABLE on GHCR.

KEY-301 stays Open while PROD remains on pre-AS.5 baseline. PROD promotion requires explicit Ludovic GO + sequencing decision between bundle vs cherry-pick (rapport sections 7.3 + 8 list risks).

Disclosure controle : pas de PoC, pas de details exploit.
```

### 13.3 KEY-263 commentaire (texte cible)

```
KEY-263 (escalation notifications PROD promotion) status update post AS.11.1g readiness plan :

- KEY-263 AS.1 base is part of the DEV source delta over PROD (commits 070707a1 API + 37e70ac Client + AS.1.1 unwire fix a69477a Client).
- A bundled AS.11.1g PROD promotion would mechanically unblock KEY-263 alongside KEY-304.
- A cherry-pick-only KEY-304 promotion would leave KEY-263 still blocked.

The sequencing decision belongs to Ludovic and is documented in rapport section 7.3.

KEY-263 stays In Review until Ludovic decides between Option A (bundle) and Option B (cherry-pick) and the AS.11.1g-PROD-PROMOTION-EXECUTION phase is launched.

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 14. Final recommendation

### 14.1 Verdict

GO PARTIAL PROD PROMOTION PLAN READY WITH RISKS

### 14.2 Une phase execution suivante peut etre demandee ?

Oui, sous reserve des conditions ci-dessous.

### 14.3 Conditions requises avant phase execution AS.11.1g-PROD-PROMOTION-EXECUTION

1. **Decision sequencement** Ludovic explicite : Option A bundle (recommandee) OU Option B cherry-pick.
2. **GO Ludovic explicite** pour build PROD + docker push + kubectl apply PROD.
3. **Fenetre de deploiement** : creneau ou Ludovic est disponible pour QA navigateur PROD post-deploy + monitoring 30 min minimum.
4. **Backup mental** : Ludovic confirme avoir le rollback en tete (revert commit + 2 kubectl apply).
5. **PROD stable preflight** : re-verification GitOps drift NONE + pods Ready pre-deploy (etat actuel le confirme mais doit etre rejoue a l instant T).
6. **Smoke V1 DEV PASS** pre-deploy : re-verification que rien n a regresse en DEV depuis l audit AS.11.1g.
7. **Methode Linear** : decision Ludovic sur comment commenter KEY-304 / KEY-301 / KEY-263 apres execution (token bastion, env file, ou Ludovic poste lui-meme).

### 14.4 KEY-263 / KEY-301 / KEY-304 outlook

- **KEY-304** : peut etre debloque Done APRES execution PROD + post-deploy validation + Ludovic QA OK. Ne PAS marquer Done dans cette phase plan.
- **KEY-301** : peut etre debloque APRES execution PROD + validation tenantGuard runtime PROD applique 6 endpoints. Reste Open dans cette phase.
- **KEY-263** : statut conditionnel a la decision sequencement. Option A -> debloquable apres execution. Option B -> reste In Review jusqu a phase ulterieure.

### 14.5 Interdits finaux respectes dans cette phase

- NO BUILD
- NO DOCKER PUSH
- NO KUBECTL APPLY
- NO MANIFEST EDIT
- NO PROD MUTATION
- NO DB MUTATION
- NO SECRET DISPLAY
- NO PII
- NO STATUS DONE Linear

---

## 15. Phrase cible finale

AS.11.1g READINESS PLAN livre en read-only strict : DEV 6/6 endpoints `/messages/conversations*` proteges et valides (LIST AS.11.1A-R2 + DETAIL AS.11.1C + REPLY AS.11.1D + STATUS AS.11.1E + ASSIGN AS.11.1F-1 + SAV-STATUS AS.11.1F-2 + QA Ludovic 6/6 OK) ; runtime DEV API v3.5.175 + Client v3.5.189 MATCH=yes GitOps + smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; PROD strictement inchange 8 services pre-AS.5 ; PROD source anchor API 0e26bfc3 + Client 0a7306a retrouves via rapport AR.5.2 (confidence HIGH) ; delta DEV->PROD API 12 commits (KEY-263 + KEY-304 + KEY-308) + Client 22 commits (KEY-263 + KEY-302 + KEY-304 + KEY-305 + KEY-308 + KEY-310) -- bundle vs cherry-pick decision Ludovic requise ; risk matrix 12 risques classes HIGH/MED/LOW ; tag candidates `v3.5.176-messages-tenantguard-prod` + `v3.5.190-messages-bff-tenantguard-prod` AVAILABLE GHCR ; manifests PROD a modifier identifies (2 fichiers, 2 lignes) ; rollback documente vers v3.5.151 + v3.5.174 ; aucun build, aucun docker push, aucun kubectl apply, aucune mutation manifest, aucune mutation DB, aucun secret, aucune PII, aucun changement statut Done Linear ; KEY-304 reste In Review ; KEY-301 reste Open ; KEY-263 reste In Review (debloquable conditionnellement Option A bundle) ; verdict AS.11.1g GO PARTIAL PROD PROMOTION PLAN READY WITH RISKS ; attente GO Ludovic explicite + decision sequencement + fenetre QA pour phase AS.11.1g-PROD-PROMOTION-EXECUTION separee.

STOP
