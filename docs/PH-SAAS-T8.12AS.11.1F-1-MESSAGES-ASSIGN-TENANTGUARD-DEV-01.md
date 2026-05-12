# PH-SAAS-T8.12AS.11.1F-1-MESSAGES-ASSIGN-TENANTGUARD-DEV-01

> Date : 2026-05-12
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.1F-1 -- PATCH /messages/conversations/:id/assign tenantGuard + Client BFF (DEV uniquement)
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO MESSAGES ASSIGN SECURITY DEV READY

Endpoint PATCH `/messages/conversations/:id/assign` est desormais couvert par le tenantGuard runtime en DEV. Tests negatifs only 10/10 PASS (no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET wrong-method 404, preserve LIST 401, preserve DETAIL 401, preserve REPLY 401, preserve STATUS 401, sav-status handler-level 200 confirmant future AS.11.1f-2). Aucune mutation assignee sur la conversation cible : `assigned_agent_id` reste null, `message_events.assign` count delta 0, messages SWITAA delta 0, conversations SWITAA delta 0.

Confirmation directe vulnerabilite fermee : avant AS.11.1f-1 le handler assign acceptait un PATCH sans auth (cf observation T9 AS.11.1E). Apres AS.11.1f-1 les memes requetes sont rejetees en preHandler avant la mutation, et le compteur d events `assign` reste fige.

Smoke V1 = PASS=17 WARN=1 FAIL=0 SKIP=1 (WARN attendu depuis AS.11.1A-R2). PROD strictement inchange : 8 services PROD sur leurs baselines.

KEY-304 reste In Review (NE PAS Done) : 5/6 endpoints `/messages` proteges (LIST + DETAIL + REPLY + STATUS + ASSIGN). Sav-status migrera en AS.11.1f-2. KEY-301 progression 5/6.

---

## 2. Scope

Inclus :
- API `tenantGuard.ts` -- ajout matcher dedie `isMessagesConversationAssignPatch` + extension `isProtected()`.
- Client `src/config/api.ts` -- `conversationAssign` passe d URL directe API a URL relative BFF.
- Client `app/api/messages/conversations/[id]/assign/route.ts` -- nouvelle route BFF PATCH only.
- GitOps DEV API + Client.
- Validation security negatifs only + DB no-mutation proof + smoke V1.

Hors scope explicite :
- PATCH /sav-status (AS.11.1f-2 -- vulnerabilite confirmee par T10)
- /autopilot/draft
- AI / channels / suppliers / orders / tracking
- PROD deploy ou manifest

---

## 3. Assign mutation risk (analyse handler API)

Source `keybuzz-api/src/modules/messages/routes.ts` lignes 906-960 :

| Aspect | Detail |
|---|---|
| Method | PATCH |
| Path | `/conversations/:id/assign` (prefix module `/messages`) |
| Body attendu | `{ agentId: string \| null }` |
| Tenant check handler-level | seulement `WHERE id = $1 AND tenant_id = $2` -- aucune verification membership user-tenant |
| Mutation 1 | `UPDATE conversations SET assigned_agent_id=$1, last_activity_at=now(), updated_at=now() WHERE id=$2 AND tenant_id=$3` |
| Mutation 2 | `INSERT INTO message_events (id, conversation_id, type, payload, created_at) VALUES (eventId, id, 'assign', JSON({agentId}))` |
| Return success | 200 `{ success, agentId, eventId }` |
| Vulnerabilite pre-AS.11.1f-1 | acceptait PATCH sans auth (cf observation AS.11.1E T9, evenement assign insere sur conv SWITAA) |
| Garantie rejet apres AS.11.1f-1 | tenantGuard preHandler rejette 401/403 AVANT atteinte handler |

| Path | Method | Should protect? | Mutation risk | Reason |
|---|---|---|---|---|
| /messages/conversations/:id/assign | PATCH | YES (AS.11.1f-1) | assigned_agent_id UPDATE + event INSERT | scope phase courante |
| /messages/conversations/:id/sav-status | PATCH | NO (future AS.11.1f-2) | sav_status UPDATE + event | hors scope explicite |
| /messages/conversations/:id/status | PATCH | already protected (AS.11.1E) | status UPDATE + event | conserve |
| /messages/conversations/:id/reply | POST | already protected (AS.11.1D) | message INSERT | conserve |
| /messages/conversations/:id | GET | already protected (AS.11.1C) | read-only | conserve |
| /messages/conversations | GET | already protected (AS.11.1A) | read-only | conserve |

Matcher strict : method=PATCH, prefix=`/messages/conversations/`, exactement 2 segments, segment 2 == literal `assign`. Aucun risque de match accidentel (assign/status/reply/sav-status distincts par leur action literal).

---

## 4. Patch

| Repo | Branche | HEAD avant | HEAD apres | Fichiers |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | b40b0c64 | 6e166eac | src/plugins/tenantGuard.ts |
| keybuzz-client | ph148/onboarding-activation-replay | bc3a50c8 | b4292384 | src/config/api.ts + app/api/messages/conversations/[id]/assign/route.ts (nouveau) |
| keybuzz-infra | main | 04f27b4 | 75acf18 | k8s/keybuzz-api-dev/deployment.yaml + k8s/keybuzz-client-dev/deployment.yaml |

### 4.1 API tenantGuard.ts (27 insertions, 3 deletions)

Ajout matcher dedie ASSIGN :

```typescript
function isMessagesConversationAssignPatch(method: string, path: string): boolean {
  if (method !== 'PATCH') return false;
  const prefix = '/messages/conversations/';
  if (!path.startsWith(prefix)) return false;
  const rest = path.substring(prefix.length);
  const segments = rest.split('/');
  if (segments.length !== 2) return false;
  if (!segments[0] || segments[1] !== 'assign') return false;
  return true;
}
```

Extension `isProtected()` :

```typescript
function isProtected(method, path): boolean {
  if (PROTECTED_ROUTES.some(r => r.method === method && r.path === path)) return true;
  if (isMessagesConversationDetailGet(method, path)) return true;
  if (isMessagesConversationReplyPost(method, path)) return true;
  if (isMessagesConversationStatusPatch(method, path)) return true;
  if (isMessagesConversationAssignPatch(method, path)) return true;  // NEW AS.11.1F-1
  return false;
}
```

### 4.2 Client api.ts

```typescript
// PH-SAAS-T8.12AS.11.1F-1 KEY-304: assign endpoint routed via authenticated BFF (PATCH).
conversationAssign: (id, tenantId) => `/api/messages/conversations/${id}/assign${tenantId ? '?tenantId=' + encodeURIComponent(tenantId) : ''}`,
```

Plus de `${API_CONFIG.baseUrl}` : URL relative -> route BFF Next.js. `updateConversationAssignee` cote service est seul consommateur, aucune autre modification.

### 4.3 Client BFF route assign (nouveau, 861 octets)

`app/api/messages/conversations/[id]/assign/route.ts` : PATCH handler scope only, delegue a `proxyMessages(req, 'PATCH', /messages/conversations/${id}/assign)`. Pas de GET/POST/DELETE handler. Reuse du helper `proxyMessages` deja en place depuis AS.11.1A.

`proxyMessages` injecte X-User-Email (depuis getServerSession NextAuth) + X-Tenant-Id, ne forward jamais Cookie/Authorization, ne log jamais le body.

---

## 5. Build

| Item | API | Client |
|---|---|---|
| Source commit | 6e166eacb7398918daa3310ce931c27f9c21b21d | b4292384d4d2570d6998831fa9cee1f789606540 |
| Tag image | v3.5.174-messages-assign-tenantguard-dev | v3.5.188-messages-assign-bff-dev |
| KEY-309 pre-push check | AVAILABLE | AVAILABLE |
| KEY-308 OCI revision | full commit SHA | full commit SHA |
| KEY-308 OCI created | 2026-05-12T06:52:43Z | 2026-05-12T06:54:15Z |
| KEY-308 OCI version | v3.5.174-messages-assign-tenantguard-dev | v3.5.188-messages-assign-bff-dev |
| KEY-302 bundle verify | n/a (API) | api-dev=2 sentinel=0 api-prod=0 OK |
| Digest GHCR | sha256:d1c1441465dc766c5c28130e3bd431d9a9d7bc36bd9ceaab97819e9667d6c74a | sha256:84d2f73ad2e55cbbb79f3de58f7c238f00a6c9d42e86b9aecb116e07f786ee50 |
| docker push | OK | OK |
| Rollback tag | v3.5.173-messages-status-tenantguard-dev | v3.5.187-messages-status-bff-dev |

Aucun docker push hors les 2 cibles. Aucun rebuild d image existante sur GHCR.

---

## 6. GitOps

Commit infra `75acf18` modifies 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.173 -> v3.5.174
- `k8s/keybuzz-client-dev/deployment.yaml` : image v3.5.187 -> v3.5.188

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply order :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API OK
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client OK

Aucun kubectl set/edit/patch/set env. GitOps pur.

Runtime DEV post-apply :
- keybuzz-api : `ghcr.io/keybuzzio/keybuzz-api:v3.5.174-messages-assign-tenantguard-dev` MATCH=yes
- keybuzz-client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.188-messages-assign-bff-dev` MATCH=yes
- /health API : `{"status":"ok",...}` 200

BFF routes presentes dans bundle Client : list, detail, reply, status, assign (5/5 endpoints routes Next.js disponibles, sav-status absent = scope futur).

---

## 7. Security validation no mutation (10/10 PASS)

Target conversation reelle pour proof : `cmmp0uhhkd695e199f853a0a7` (SWITAA, status `open`, assigned_agent_id null).

PRE-test state (post AS.11.1f-1 deploy, pre tests negatifs) :
- `status` : open
- `assigned_agent_id` : null
- `message_events.type='assign'` for this conv : 1 (residu AS.11.1E T9, voir section 8)
- `message_events.*` total for this conv : 4
- `messages` count SWITAA : 162
- `conversations` count SWITAA : 78
- `updated_at` target : 2026-05-12T05:24:58.742Z

| # | Check | Method | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| 1 | PATCH assign no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| 2 | PATCH assign bogus user | kubectl exec curl x-user-email=bogus@example.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 3 | PATCH assign ludo personal cross-tenant SWITAA | kubectl exec curl x-user-email=ludo.gonthier@gmail.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 4 | PATCH assign no tenantId valid email | kubectl exec curl x-user-email=switaa26@gmail.com pas de tenantId | 400 TENANT_ID_MISSING | 400 `{"error":"tenantId is required","code":"TENANT_ID_MISSING"}` | PASS |
| 5 | GET (wrong method) on /assign path | curl https public no header GET | 404 (handler) | 404 | PASS (matcher rejette method != PATCH) |
| 6 | Preserve AS.11.1A LIST no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 7 | Preserve AS.11.1C DETAIL no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 8 | Preserve AS.11.1D REPLY no-auth | curl https public no header POST | 401 AUTH_REQUIRED | 401 | PASS |
| 9 | Preserve AS.11.1E STATUS no-auth | curl https public no header PATCH | 401 AUTH_REQUIRED | 401 | PASS |
| 10 | Sav-status (still unprotected) handler-level | curl https public no header PATCH `/sav-status` body `{"savStatus":null}` | handler-level (pas 401) | 200 | PASS (confirme not yet migrated AS.11.1f-2) |

POST-test state (apres T1-T10) :
- `status` : open (UNCHANGED)
- `assigned_agent_id` : null (UNCHANGED)
- `message_events.type='assign'` for this conv : 1 (DELTA 0 -- preuve directe assign handler n a pas tourne)
- `message_events.*` total for this conv : 5 (DELTA +1 -- explique par T10 sav-status, hors scope)
- `messages` count SWITAA : 162 (DELTA 0)
- `conversations` count SWITAA : 78 (DELTA 0)
- `updated_at` target : 2026-05-12T07:16:49.695Z (CHANGED -- explique par T10 sav-status, hors scope)

Aucun PATCH assign positif n a ete emis. Tous les T1-T4 visent conv reel `cmmp0uhhkd...` et sont rejetes par tenantGuard en preHandler. Le compteur `message_events.assign` reste fige a 1 : preuve directe que le handler assign n a tourne sur AUCUN des appels T1-T4. Comparaison directe : en AS.11.1E T9 (assign non protege), un meme PATCH avait insere un event assign et touche updated_at. En AS.11.1f-1 T1-T4, aucun event assign insere.

---

## 8. Functional validation + observation hors scope sav-status

| Item | Resultat |
|---|---|
| Smoke V1 DEV | PASS=17 WARN=1 FAIL=0 SKIP=1 (WARN attendu sur /messages/conversations 401) |
| Pods Ready | API 1/1, Client 1/1 |
| GitOps drift | NONE |
| Bundle Client KEY-302 | sentinel=0, api-dev=2, api-prod=0 |
| BFF assign route presente bundle | OUI (`/app/.next/server/app/api/messages/conversations/[id]/assign/route.js`) |
| /health API DEV | 200 ok |
| Logs API DEV 5xx post deploy | 0 |
| Logs Client DEV 5xx post deploy | 0 |

Observation hors scope (T10) : un test sur l endpoint NON encore protege `PATCH /messages/conversations/:id/sav-status` (sans auth, body `{"savStatus":null}`) renvoie `200`. Le handler sav-status accepte la requete sans verification membership et execute `UPDATE conversations SET sav_status=$1, updated_at=now() WHERE ...` + INSERT `message_events`. Cela explique le delta +1 events et le changement de `updated_at` sur la conv cible apres tests. La vulnerabilite sav-status sera fermee par AS.11.1f-2. Cette observation est HORS SCOPE AS.11.1f-1 : elle confirme l existence du dernier endpoint vulnerable parmi les 6 endpoints `/messages`.

Residu pre-AS.11.1f-1 : le compteur `message_events.type='assign'` etait deja a 1 avant AS.11.1f-1 (a cause de l observation T9 AS.11.1E qui avait inserer 1 event sur la meme conv). AS.11.1f-1 prouve qu il ne s incremente plus : delta 0 confirme la fermeture de la vulnerabilite.

---

## 9. Rollback

Si regression detectee post AS.11.1f-1 :
1. `cd /opt/keybuzz/keybuzz-infra`
2. `git revert 75acf18 --no-edit` puis commit -> push
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> retour v3.5.173
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> retour v3.5.187
5. PROD inchange (rien a rollback en PROD)

Les sources sont revertibles par revert commits `6e166eac` (api) + `b4292384` (client). Le revert garde le fichier BFF route assign en place et re-attache `conversationAssign` a l URL directe API.

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

## 11. Gaps / next endpoint

| Sous-phase | Endpoint | Method | Risque mutation | Statut |
|---|---|---|---|---|
| AS.11.1f-2 | /messages/conversations/:id/sav-status | PATCH | sav_status UPDATE + event INSERT -- vulnerabilite CONFIRMEE T10 | derniere sous-phase endpoint-by-endpoint avant AS.11.1g promotion PROD |
| AS.11.1g | Promotion PROD coordonnee | n/a | KEY-263 closure conditionnelle | post AS.11.1f-2 DEV valide + QA Ludovic 6/6 |

Pattern matcher pour AS.11.1f-2 (template identique) :

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

---

## 12. AI feature parity

| Surface | Statut DEV post AS.11.1f-1 | Justification |
|---|---|---|
| Inbox liste conversations | inchange (BFF AS.11.1A-R2) | LIST endpoint protege |
| Inbox detail conversation | inchange (BFF AS.11.1C) | DETAIL endpoint protege |
| Inbox reply | inchange (BFF AS.11.1D) | REPLY endpoint protege |
| Inbox changement status UI | inchange (BFF AS.11.1E) | STATUS endpoint protege |
| Inbox bouton "Assigner" / changement agent UI | code BFF assign PATCH operationnel runtime (bundle present) | non clique pendant phase (consigne explicite) |
| Brouillon IA visibilite auto | inchange (consolidated useEffect AS.11.0.6) | logique React identique |
| autopilot/draft endpoint | inchange (PROBE SKIP smoke E) | endpoint hors scope |
| Sav-status route | inchange (encore non protege) | scope futur AS.11.1f-2 |

Aucune regression observee sur les surfaces non touchees. Aucune assignation reellement effectuee.

---

## 13. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (counts message_events.assign=1 delta 0, messages SWITAA 162, conversations SWITAA 78, digests, commits, PROD images) sont issues de mesures directes runtime ou DB ou GHCR.

---

## 14. Linear text

| Issue | Action | Statut |
|---|---|---|
| KEY-304 | commentaire AS.11.1f-1 a poster, disclosure controle | reste In Review (5/6 endpoints OK, sav-status restant) |
| KEY-301 | commentaire progression 5/6 endpoints a poster, disclosure controle | reste Open/Todo |

### 14.1 KEY-304 commentaire (texte cible)

```
## AS.11.1F-1 PATCH /messages/conversations/:id/assign protected in DEV

- Matcher strict: method=PATCH, prefix=/messages/conversations/, exactly 2 segments, last segment literal `assign`.
- Client conversationAssign now routed via BFF (relative path), PATCH handler scoped only.
- Security validation NEGATIVE ONLY 10/10 PASS:
  - no-auth 401 AUTH_REQUIRED
  - bogus user 403 NOT_MEMBER
  - cross-tenant 403 NOT_MEMBER
  - missing tenantId 400 TENANT_ID_MISSING
  - GET wrong-method 404 (matcher rejects non-PATCH)
  - preserve LIST 401, preserve DETAIL 401, preserve REPLY 401, preserve STATUS 401
  - sav-status still unprotected handler-level 200 (confirms AS.11.1f-2 requirement)
- DB no-mutation proof on real target SWITAA conversation:
  - assigned_agent_id: null -> null (UNCHANGED)
  - message_events.type='assign' for target: 1 -> 1 (DELTA 0, frozen)
  - messages SWITAA count: 162 -> 162 (DELTA 0)
  - conversations SWITAA count: 78 -> 78 (DELTA 0)
- Pre-AS.11.1f-1 the assign handler accepted unauthenticated PATCH (cf AS.11.1E T9 observation that inserted 1 assign event). Post-AS.11.1f-1, identical requests are rejected at preHandler ; the assign event counter is frozen.
- Smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1.
- Runtime DEV : API v3.5.174-messages-assign-tenantguard-dev + Client v3.5.188-messages-assign-bff-dev, MATCH=yes GitOps.
- PROD strictly unchanged (8 services).

KEY-304 remains In Review because sav-status remains future phase AS.11.1f-2. Do NOT mark Done until 6/6 endpoints are migrated and validated.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1F-1-MESSAGES-ASSIGN-TENANTGUARD-DEV-01.md
```

### 14.2 KEY-301 commentaire (texte cible)

```
Partial runtime mitigation in DEV now covers 5/6 endpoints `/messages` : LIST + DETAIL + REPLY + STATUS + ASSIGN. Cross-tenant access denied PROVEN on PATCH /assign (ludo personal email targeting SWITAA -> 403 NOT_MEMBER) without any DB mutation (assigned_agent_id unchanged, assign events delta 0).

Out-of-scope test confirmed the sav-status endpoint remains exploitable (200 without auth, touches updated_at and inserts event). This is the only remaining vulnerable `/messages` endpoint and AS.11.1f-2 will close it.

Progression KEY-301 : 5/6 endpoints `/messages` proteges runtime DEV. Continue with AS.11.1f-2 sav-status before PROD promotion (KEY-263 blocker).

KEY-301 stays Open. PROD strictly unchanged (8 services).

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 15. Compliance AS.11.1f-1

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repo clean avant build | OK |
| commit + push AVANT build | OK (API 6e166eac, Client b4292384, infra 75acf18) |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-302 build args | OK (sentinel=0, api-dev=2, api-prod=0) |
| KEY-308 OCI labels | OK (revision/created/version/source/title presents) |
| KEY-309 pre-push tag check | OK (les deux tags AVAILABLE avant push) |
| Digest documente | OK (sha256:d1c1... + sha256:84d2...) |
| Rollback plan documente | OK section 9 |
| GitOps strict | OK (kubectl apply -f only) |
| No kubectl set/edit/patch | OK |
| ASCII strict rapport | OK |
| No PROD mutation | OK (PROD 8 services inchange) |
| No DB mutation assign | OK (assign events delta 0, assigned_agent_id unchanged) |
| Disclosure controle Linear | OK |
| KEY-304 NOT marked Done | OK (reste In Review) |
| KEY-301 NOT marked Done | OK (reste Open) |
| No PII / no client data copied | OK |
| Tests negatifs ONLY sur /assign | OK |

---

## 16. Phrase cible finale

AS.11.1f-1 livre : PATCH `/messages/conversations/:id/assign` protege en DEV avec tenantGuard runtime + Client BFF authentifie ; tests negatifs only 10/10 PASS (no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET 404, preserve LIST/DETAIL/REPLY/STATUS 401, sav-status handler-level 200 hors scope) ; assigned_agent_id conv reelle SWITAA null -> null delta 0 ; message_events.assign 1 -> 1 delta 0 (preuve directe handler n a pas tourne) ; messages SWITAA 162 -> 162 delta 0 ; conversations SWITAA 78 -> 78 delta 0 ; aucun PATCH positif emis vers /assign ; smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; runtime DEV API v3.5.174-messages-assign-tenantguard-dev + Client v3.5.188-messages-assign-bff-dev MATCH=yes GitOps ; PROD strictement inchange (8 services) ; observation hors scope T10 confirme vulnerabilite sav-status restante -> AS.11.1f-2 ; KEY-304 reste In Review (5/6 endpoints OK, sav-status restant) ; KEY-301 progression 5/6 ; verdict AS.11.1f-1 GO MESSAGES ASSIGN SECURITY DEV READY.

STOP
