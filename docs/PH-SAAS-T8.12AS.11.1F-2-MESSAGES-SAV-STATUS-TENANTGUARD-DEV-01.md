# PH-SAAS-T8.12AS.11.1F-2-MESSAGES-SAV-STATUS-TENANTGUARD-DEV-01

> Date : 2026-05-12
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.1F-2 -- PATCH /messages/conversations/:id/sav-status tenantGuard + Client BFF (DEV uniquement)
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO MESSAGES SAV-STATUS SECURITY DEV READY

Endpoint PATCH `/messages/conversations/:id/sav-status` est desormais couvert par le tenantGuard runtime en DEV. Avec cette sous-phase, **6/6 endpoints `/messages/conversations*` sont proteges** (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS).

Tests negatifs only 10/10 PASS : no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET wrong-method 404, preserve LIST/DETAIL/REPLY/STATUS/ASSIGN 401 (5 preserves au lieu de 4 -- aucun endpoint cousin n est plus handler-level).

Preuve DB no-mutation totale sur la conversation cible SWITAA : tous les champs et compteurs gele a la valeur pre-tests, delta 0 sur sav_status, sav_updated_at, updated_at, sav_status_change events, all events, messages count, conversations count.

Smoke V1 = PASS=17 WARN=1 FAIL=0 SKIP=1. Logs DEV 0 5xx API, 0 JWT_SESSION_ERROR Client. PROD strictement inchange 8 services.

KEY-304 reste In Review (NE PAS Done) -- attente phase synthese 6/6 + QA Ludovic + PROD promotion AS.11.1g. KEY-301 progression 6/6 endpoints `/messages`.

---

## 2. Scope

Inclus :
- API `tenantGuard.ts` -- ajout matcher dedie `isMessagesConversationSavStatusPatch` + extension `isProtected()`.
- Client `src/config/api.ts` -- `conversationSavStatus` passe d URL directe API a URL relative BFF.
- Client `app/api/messages/conversations/[id]/sav-status/route.ts` -- nouvelle route BFF PATCH only.
- GitOps DEV API + Client.
- Validation security negatifs only + DB no-mutation proof + smoke V1.

Hors scope explicite :
- /autopilot/draft
- /escalation (endpoint distinct hors perimetre messages)
- AI / channels / suppliers / orders / tracking
- PROD deploy ou manifest
- KEY-304 closure (attente synthese 6/6)

Aucune dependance ajoutee. Dockerfile, package.json, next.config et env inchanges.

---

## 3. Sav-status mutation risk (analyse handler API)

Source `keybuzz-api/src/modules/messages/routes.ts` lignes 851-905 :

| Aspect | Detail |
|---|---|
| Method | PATCH |
| Path | `/conversations/:id/sav-status` (prefix module `/messages`) |
| Body attendu | `{ savStatus: 'to_process' \| 'waiting' \| 'in_progress' \| 'closed' \| null }` |
| Tenant check handler-level | seulement `WHERE id = $1 AND tenant_id = $2` -- aucune verification membership user-tenant |
| Mutation 1 | `UPDATE conversations SET sav_status=$1, sav_updated_at=now(), updated_at=now() WHERE id=$2 AND tenant_id=$3` |
| Mutation 2 | `INSERT INTO message_events (id, conversation_id, type, payload, created_at) VALUES (eventId, id, 'sav_status_change', JSON({from, to}))` |
| Return success | 200 `{ success, savStatus, eventId }` |
| Vulnerabilite pre-AS.11.1f-2 | acceptait PATCH sans auth (cf AS.11.1f-1 T10 observation : 200, event insere, updated_at mute) |
| Garantie rejet apres AS.11.1f-2 | tenantGuard preHandler rejette 401/403 AVANT atteinte handler |

| Path | Method | Should protect? | Mutation risk | Reason |
|---|---|---|---|---|
| /messages/conversations/:id/sav-status | PATCH | YES (AS.11.1f-2) | sav_status UPDATE + event INSERT | scope phase courante (derniere) |
| /messages/conversations/:id/assign | PATCH | already protected (AS.11.1f-1) | assignee UPDATE + event | conserve |
| /messages/conversations/:id/status | PATCH | already protected (AS.11.1E) | status UPDATE + event | conserve |
| /messages/conversations/:id/reply | POST | already protected (AS.11.1D) | message INSERT | conserve |
| /messages/conversations/:id | GET | already protected (AS.11.1C) | read-only | conserve |
| /messages/conversations | GET | already protected (AS.11.1A) | read-only | conserve |

Matcher strict : method=PATCH, prefix=`/messages/conversations/`, exactement 2 segments, segment 2 == literal `sav-status` (le hyphen fait partie du literal). Aucun risque de match accidentel sur les autres action segments (status, assign, reply distincts).

---

## 4. Patch

| Repo | Branche | HEAD avant | HEAD apres | Fichiers |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 6e166eac | 3f45a7e0 | src/plugins/tenantGuard.ts |
| keybuzz-client | ph148/onboarding-activation-replay | b4292384 | 094163b0 | src/config/api.ts + app/api/messages/conversations/[id]/sav-status/route.ts (nouveau) |
| keybuzz-infra | main | 65bca19 | 7e50b01 | k8s/keybuzz-api-dev/deployment.yaml + k8s/keybuzz-client-dev/deployment.yaml |

### 4.1 API tenantGuard.ts (27 insertions, 2 deletions)

Ajout matcher dedie SAV-STATUS :

```typescript
function isMessagesConversationSavStatusPatch(method: string, path: string): boolean {
  if (method !== 'PATCH') return false;
  const prefix = '/messages/conversations/';
  if (!path.startsWith(prefix)) return false;
  const rest = path.substring(prefix.length);
  const segments = rest.split('/');
  if (segments.length !== 2) return false;
  if (!segments[0] || segments[1] !== 'sav-status') return false;
  return true;
}
```

Extension `isProtected()` -- desormais 6 matchers actifs :

```typescript
function isProtected(method, path): boolean {
  if (PROTECTED_ROUTES.some(r => r.method === method && r.path === path)) return true;
  if (isMessagesConversationDetailGet(method, path)) return true;
  if (isMessagesConversationReplyPost(method, path)) return true;
  if (isMessagesConversationStatusPatch(method, path)) return true;
  if (isMessagesConversationAssignPatch(method, path)) return true;
  if (isMessagesConversationSavStatusPatch(method, path)) return true;  // NEW AS.11.1F-2
  return false;
}
```

### 4.2 Client api.ts

```typescript
// PH-SAAS-T8.12AS.11.1F-2 KEY-304: sav-status endpoint routed via authenticated BFF (PATCH).
conversationSavStatus: (id, tenantId) => `/api/messages/conversations/${id}/sav-status${tenantId ? '?tenantId=' + encodeURIComponent(tenantId) : ''}`,
```

URL relative -> route BFF Next.js. `updateConversationSavStatus` cote service est seul consommateur, aucune autre modification du service.

### 4.3 Client BFF route sav-status (nouveau, 936 octets)

`app/api/messages/conversations/[id]/sav-status/route.ts` : PATCH handler scope only, delegue a `proxyMessages(req, 'PATCH', /messages/conversations/${id}/sav-status)`. Pas de GET/POST/DELETE handler. Reuse helper `proxyMessages` existant.

`proxyMessages` injecte X-User-Email (depuis getServerSession NextAuth) + X-Tenant-Id, ne forward jamais Cookie/Authorization, ne log jamais le body.

---

## 5. Build

| Item | API | Client |
|---|---|---|
| Source commit | 3f45a7e01e80d5a7b250c893abe80bd11c2626bd | 094163b0d86529600f50738a5f85fab946a9da74 |
| Tag image | v3.5.175-messages-sav-status-tenantguard-dev | v3.5.189-messages-sav-status-bff-dev |
| KEY-309 pre-push check | AVAILABLE | AVAILABLE |
| KEY-308 OCI revision | full commit SHA | full commit SHA |
| KEY-308 OCI created | 2026-05-12T07:31:27Z | 2026-05-12T07:33:23Z |
| KEY-308 OCI version | v3.5.175-messages-sav-status-tenantguard-dev | v3.5.189-messages-sav-status-bff-dev |
| KEY-302 bundle verify | n/a (API) | api-dev=2 sentinel=0 api-prod=0 OK |
| Digest GHCR | sha256:f2387f2665f9bbdb0db1438e6cba4dde437e8b8a05cc3d6b1503ab5be6e19589 | sha256:ef970721bd673076a63167e13ef06a05586c1f428d9cad87f2a0f8dbb23362a4 |
| docker push | OK | OK |
| Rollback tag | v3.5.174-messages-assign-tenantguard-dev | v3.5.188-messages-assign-bff-dev |

Aucun docker push hors les 2 cibles. Aucun rebuild d image existante sur GHCR.

---

## 6. GitOps

Commit infra `7e50b01` modifies 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.174 -> v3.5.175
- `k8s/keybuzz-client-dev/deployment.yaml` : image v3.5.188 -> v3.5.189

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply order :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API OK
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client OK

Aucun kubectl set/edit/patch/set env. GitOps pur.

Runtime DEV post-apply :
- keybuzz-api : `ghcr.io/keybuzzio/keybuzz-api:v3.5.175-messages-sav-status-tenantguard-dev` MATCH=yes
- keybuzz-client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.189-messages-sav-status-bff-dev` MATCH=yes
- /health API : `{"status":"ok",...}` 200

BFF routes presentes dans bundle Client : list, detail, reply, status, assign, sav-status (6/6 endpoints routes Next.js disponibles).

---

## 7. Security validation no mutation (10/10 PASS)

Target conversation reelle pour proof : `cmmp0uhhkd695e199f853a0a7` (SWITAA).

PRE-test state (post AS.11.1f-2 deploy, pre tests negatifs) :
- `status` : open
- `sav_status` : null
- `sav_updated_at` : 2026-05-12T07:16:49.695Z (residu AS.11.1f-1 T10)
- `assigned_agent_id` : null
- `updated_at` : 2026-05-12T07:16:49.695Z
- `message_events.type='sav_status_change'` for this conv : 1 (residu AS.11.1f-1 T10)
- `message_events.*` total for this conv : 5
- `messages` count SWITAA : 162
- `conversations` count SWITAA : 78

| # | Check | Method | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| 1 | PATCH sav-status no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| 2 | PATCH sav-status bogus user | kubectl exec curl x-user-email=bogus@example.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 3 | PATCH sav-status ludo personal cross-tenant SWITAA | kubectl exec curl x-user-email=ludo.gonthier@gmail.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 4 | PATCH sav-status no tenantId valid email | kubectl exec curl x-user-email=switaa26@gmail.com pas de tenantId | 400 TENANT_ID_MISSING | 400 `{"error":"tenantId is required","code":"TENANT_ID_MISSING"}` | PASS |
| 5 | GET (wrong method) on /sav-status path | curl https public no header GET | 404 (handler) | 404 | PASS (matcher rejette method != PATCH) |
| 6 | Preserve AS.11.1A LIST no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 7 | Preserve AS.11.1C DETAIL no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 8 | Preserve AS.11.1D REPLY no-auth | curl https public no header POST | 401 AUTH_REQUIRED | 401 | PASS |
| 9 | Preserve AS.11.1E STATUS no-auth | curl https public no header PATCH | 401 AUTH_REQUIRED | 401 | PASS |
| 10 | Preserve AS.11.1F-1 ASSIGN no-auth | curl https public no header PATCH | 401 AUTH_REQUIRED | 401 | PASS |

POST-test state (apres T1-T10) :
- `status` : open (UNCHANGED)
- `sav_status` : null (UNCHANGED)
- `sav_updated_at` : 2026-05-12T07:16:49.695Z (UNCHANGED)
- `assigned_agent_id` : null (UNCHANGED)
- `updated_at` : 2026-05-12T07:16:49.695Z (UNCHANGED -- frozen pour la premiere fois depuis AS.11.1A car aucun handler n a tourne)
- `message_events.type='sav_status_change'` for this conv : 1 (DELTA 0 -- preuve directe handler sav-status n a pas tourne)
- `message_events.*` total for this conv : 5 (DELTA 0)
- `messages` count SWITAA : 162 (DELTA 0)
- `conversations` count SWITAA : 78 (DELTA 0)

Aucun PATCH sav-status positif n a ete emis. Tous les T1-T4 visent conv reel `cmmp0uhhkd...` et sont rejetes par tenantGuard en preHandler. Le compteur `message_events.sav_status_change` reste fige a 1 : preuve directe que le handler sav-status n a tourne sur AUCUN des appels T1-T4. Comparaison directe : en AS.11.1f-1 T10 (sav-status non protege), un meme PATCH avait insere 1 event sav_status_change et touche updated_at. En AS.11.1f-2 T1-T4, aucun event insere, aucun timestamp mute.

C est la premiere fois depuis AS.11.1A que la conv cible est entierement gele lors d une serie de tests negatifs : 6/6 endpoints rejettent en preHandler.

---

## 8. Functional validation

| Item | Resultat |
|---|---|
| Smoke V1 DEV post-deploy | PASS=17 WARN=1 FAIL=0 SKIP=1 (WARN /messages/conversations 401 = comportement attendu depuis AS.11.1A-R2) |
| Pods Ready | API 1/1, Client 1/1 |
| GitOps drift | NONE |
| Bundle Client KEY-302 | sentinel=0, api-dev=2, api-prod=0 |
| BFF routes presentes bundle | 6/6 (list, detail, reply, status, assign, sav-status) |
| /health API DEV | 200 ok |
| Logs API DEV 5xx (5min) post deploy | 0 |
| Logs Client DEV JWT_SESSION_ERROR (5min) post deploy | 0 |

Aucune observation hors scope : tous les endpoints `/messages` sont desormais proteges. Le seul comportement de mutation sans auth restant possible serait sur des endpoints hors perimetre `/messages` (e.g. `/escalation`, `/notifications`, autres modules) -- ces endpoints sont hors scope KEY-304 et seront traites par leurs propres tickets.

---

## 9. Rollback

Si regression detectee post AS.11.1f-2 :
1. `cd /opt/keybuzz/keybuzz-infra`
2. `git revert 7e50b01 --no-edit` puis commit -> push
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> retour API v3.5.174-messages-assign-tenantguard-dev
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> retour Client v3.5.188-messages-assign-bff-dev
5. PROD inchange (rien a rollback en PROD)

Les sources sont revertibles par revert commits `3f45a7e0` (api) + `094163b0` (client). Le revert garde le fichier BFF route sav-status en place et re-attache `conversationSavStatus` a l URL directe API. Apres rollback : 5/6 endpoints proteges (LIST + DETAIL + REPLY + STATUS + ASSIGN), regression sav-status retour vers handler-level vulnerable.

Trigger rollback immediat si : Inbox liste/detail/reply visible casse, Brouillon IA disparait, nouveaux messages bloques, smoke V1 FAIL.

---

## 10. PROD unchanged (table)

| Namespace | Workload | Image runtime (avant + apres) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.151-conversation-tone-metric-prod |
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `-prod`.

---

## 11. Endpoint-by-endpoint completion 6/6

| Sous-phase | Endpoint | Method | Image API DEV | Image Client DEV | Date |
|---|---|---|---|---|---|
| AS.11.1A-R2 | /messages/conversations | GET (LIST) | v3.5.170-messages-list-tenantguard-dev | v3.5.184-messages-list-bff-dev | 2026-05-11 |
| AS.11.1C | /messages/conversations/:id | GET (DETAIL) | v3.5.171-messages-detail-tenantguard-dev | v3.5.185-messages-detail-bff-dev | 2026-05-11 |
| AS.11.1D | /messages/conversations/:id/reply | POST | v3.5.172-messages-reply-tenantguard-dev | v3.5.186-messages-reply-bff-dev | 2026-05-11 |
| AS.11.1E | /messages/conversations/:id/status | PATCH | v3.5.173-messages-status-tenantguard-dev | v3.5.187-messages-status-bff-dev | 2026-05-12 |
| AS.11.1F-1 | /messages/conversations/:id/assign | PATCH | v3.5.174-messages-assign-tenantguard-dev | v3.5.188-messages-assign-bff-dev | 2026-05-12 |
| AS.11.1F-2 | /messages/conversations/:id/sav-status | PATCH | v3.5.175-messages-sav-status-tenantguard-dev | v3.5.189-messages-sav-status-bff-dev | 2026-05-12 |

6/6 endpoints proteges en DEV. Prochaines etapes possibles :
- Synthese 6/6 + QA Ludovic complete (Inbox + bouton statut + assigner + SAV label sans cliquer = juste verifier pas de banniere d erreur).
- AS.11.1g : promotion PROD coordonnee (necessite KEY-263 closure conditionnelle).
- KEY-304 reste In Review jusqu apres synthese et PROD promotion.
- KEY-301 reste Open jusqu apres PROD promotion.

---

## 12. AI feature parity (anti-regression)

| Surface | Statut DEV post AS.11.1f-2 | Justification |
|---|---|---|
| Inbox liste conversations | inchange (BFF AS.11.1A-R2) | LIST endpoint protege |
| Inbox detail conversation | inchange (BFF AS.11.1C) | DETAIL endpoint protege |
| Inbox reply | inchange (BFF AS.11.1D) | REPLY endpoint protege |
| Inbox changement status UI | inchange (BFF AS.11.1E) | STATUS endpoint protege |
| Inbox assignation UI | inchange (BFF AS.11.1F-1) | ASSIGN endpoint protege |
| Inbox SAV label UI (label "SAV") | code BFF sav-status PATCH operationnel runtime (bundle present) | non clique pendant phase (consigne explicite) |
| Brouillon IA visibilite auto | inchange (consolidated useEffect AS.11.0.6) | logique React identique |
| autopilot/draft endpoint | inchange (PROBE SKIP smoke E) | endpoint hors scope |

Aucune regression observee sur les 5 endpoints precedents. Aucun changement de SAV status reellement effectue.

---

## 13. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (counts message_events.sav_status_change=1 delta 0, messages SWITAA 162, conversations SWITAA 78, digests, commits, PROD images, log counts) sont issues de mesures directes runtime ou DB ou GHCR.

---

## 14. Linear text

| Issue | Action | Statut |
|---|---|---|
| KEY-304 | commentaire AS.11.1f-2 a poster, disclosure controle | reste In Review (6/6 endpoints OK, attente synthese + PROD promotion AS.11.1g) |
| KEY-301 | commentaire progression 6/6 endpoints a poster, disclosure controle | reste Open/Todo (PROD inchange) |

### 14.1 KEY-304 commentaire (texte cible)

```
## AS.11.1F-2 PATCH /messages/conversations/:id/sav-status protected in DEV -- 6/6 endpoints complete

- Matcher strict: method=PATCH, prefix=/messages/conversations/, exactly 2 segments, last segment literal `sav-status`.
- Client conversationSavStatus now routed via BFF (relative path), PATCH handler scoped only.
- Security validation NEGATIVE ONLY 10/10 PASS:
  - no-auth 401 AUTH_REQUIRED
  - bogus user 403 NOT_MEMBER
  - cross-tenant 403 NOT_MEMBER
  - missing tenantId 400 TENANT_ID_MISSING
  - GET wrong-method 404 (matcher rejects non-PATCH)
  - preserve LIST 401, DETAIL 401, REPLY 401, STATUS 401, ASSIGN 401 (5 preserves)
- DB no-mutation proof on real target SWITAA conversation:
  - sav_status: null -> null (UNCHANGED)
  - sav_updated_at: frozen (UNCHANGED)
  - updated_at: frozen (UNCHANGED -- first time fully frozen since AS.11.1A)
  - message_events.type='sav_status_change' for target: 1 -> 1 (DELTA 0)
  - all events for target: 5 -> 5 (DELTA 0)
  - messages SWITAA: 162 -> 162 (DELTA 0)
- Smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1.
- 0 5xx in API logs, 0 JWT_SESSION_ERROR in Client logs.
- Runtime DEV : API v3.5.175-messages-sav-status-tenantguard-dev + Client v3.5.189-messages-sav-status-bff-dev, MATCH=yes GitOps.
- PROD strictly unchanged (8 services).

Endpoint-by-endpoint migration 6/6 complete on /messages/conversations* : LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS.

KEY-304 remains In Review pending synthese 6/6 + Ludovic UX QA + AS.11.1g PROD promotion (which itself depends on KEY-263 closure). Do NOT mark Done before all of those.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-2-MESSAGES-SAV-STATUS-TENANTGUARD-DEV-01.md
```

### 14.2 KEY-301 commentaire (texte cible)

```
Runtime mitigation in DEV now covers 6/6 endpoints `/messages/conversations*` (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS). Cross-tenant access denied PROVEN on all 6 endpoints in DEV (ludo personal email targeting SWITAA -> 401/403, no DB mutation).

For the AS.11.1f-2 phase specifically, no mutation of sav_status, sav_updated_at, updated_at, or sav_status_change event count on the target SWITAA conversation : the handler did not execute on any of the 4 negative attempts.

KEY-301 stays Open while PROD remains on the pre-AS.5 baseline (8 services unchanged). PROD promotion (AS.11.1g) is a separate phase and requires synthese 6/6 + Ludovic QA + KEY-263 closure first.

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 15. Compliance AS.11.1f-2

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repo clean avant build | OK |
| commit + push AVANT build | OK (API 3f45a7e0, Client 094163b0, infra 7e50b01) |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-302 build args | OK (sentinel=0, api-dev=2, api-prod=0) |
| KEY-308 OCI labels | OK (revision/created/version/source/title presents) |
| KEY-309 pre-push tag check | OK (les deux tags AVAILABLE avant push) |
| Digest documente | OK (sha256:f238... + sha256:ef97...) |
| Rollback plan documente | OK section 9 |
| GitOps strict | OK (kubectl apply -f only) |
| No kubectl set/edit/patch | OK |
| ASCII strict rapport | OK |
| No PROD mutation | OK (PROD 8 services inchange) |
| No DB mutation sav-status | OK (sav_status delta 0, sav_status_change events delta 0) |
| Disclosure controle Linear | OK (textes prets en attente GO + methode token) |
| KEY-304 NOT marked Done | OK (reste In Review) |
| KEY-301 NOT marked Done | OK (reste Open) |
| No PII / no client data copied | OK |
| Tests negatifs ONLY sur /sav-status | OK |
| Pas de modification Dockerfile / package.json / next.config / env | OK |
| Pas de dependance ajoutee | OK |

---

## 16. Phrase cible finale

AS.11.1f-2 livre : PATCH `/messages/conversations/:id/sav-status` protege en DEV avec tenantGuard runtime + Client BFF authentifie ; tests negatifs only 10/10 PASS (no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET 404, preserve LIST/DETAIL/REPLY/STATUS/ASSIGN 401) ; sav_status conv reelle SWITAA null -> null delta 0 ; sav_updated_at frozen ; updated_at frozen (premiere fois depuis AS.11.1A) ; message_events.sav_status_change 1 -> 1 delta 0 ; messages SWITAA 162 -> 162 ; conversations SWITAA 78 -> 78 ; aucun PATCH positif emis vers /sav-status ; smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; 0 5xx + 0 JWT_SESSION_ERROR sur logs DEV 5min ; runtime DEV API v3.5.175-messages-sav-status-tenantguard-dev + Client v3.5.189-messages-sav-status-bff-dev MATCH=yes GitOps ; PROD strictement inchange (8 services) ; **endpoint-by-endpoint migration 6/6 complete** (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS) ; KEY-304 reste In Review pendant attente synthese + QA + AS.11.1g PROD promotion ; KEY-301 progression 6/6 reste Open ; verdict AS.11.1f-2 GO MESSAGES SAV-STATUS SECURITY DEV READY.

STOP
