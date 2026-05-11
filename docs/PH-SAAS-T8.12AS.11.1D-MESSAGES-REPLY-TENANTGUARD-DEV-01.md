# PH-SAAS-T8.12AS.11.1D-MESSAGES-REPLY-TENANTGUARD-DEV-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301
> Phase : T8.12 AS.11.1D -- POST /messages/conversations/:id/reply tenantGuard + Client BFF (DEV uniquement)
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO MESSAGES REPLY TENANTGUARD DEV READY

Endpoint POST `/messages/conversations/:id/reply` est desormais couvert par le tenantGuard runtime en DEV. Tests negatifs only 8/8 PASS (no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET wrong-method 404, preserve LIST 401, preserve DETAIL 401, status route encore non protege 400 handler). Aucune mutation messages : DB count SWITAA = 162 avant tests, 162 apres tests (delta 0). Aucun POST positif n a ete emis pendant la phase.

Smoke V1 = PASS=17 WARN=1 FAIL=0 SKIP=1 (le WARN correspond a `/messages/conversations 401 (auth required)` qui est le comportement attendu post tenantGuard depuis AS.11.1A-R2). PROD strictement inchange : 8 services PROD sur leurs baselines pre-AS.11.1D.

KEY-304 reste In Review (NE PAS Done) : 3/6 endpoints `/messages` proteges (LIST + DETAIL + REPLY). Status, assign, sav-status migreront en AS.11.1e -> AS.11.1f. KEY-301 progression 3/6.

---

## 2. Preflight (E0)

| Item | Valeur |
|---|---|
| Bastion | install-v3 (46.62.171.61) |
| API DEV avant | v3.5.171-messages-detail-tenantguard-dev |
| Client DEV avant | v3.5.185-messages-detail-bff-dev |
| GitOps drift DEV | NONE (avant) |
| KEY-309 tag v3.5.172-messages-reply-tenantguard-dev | AVAILABLE |
| KEY-309 tag v3.5.186-messages-reply-bff-dev | AVAILABLE |
| Smoke V1 avant | PASS (PASS_WITH_WARNINGS reference) |
| DB baseline messages SWITAA pre-deploy | 162 |
| PROD images pre-AS.11.1D | 8 services baseline 2026-04 -> 2026-05 |

---

## 3. Sources patches (E1-E3)

| Repo | Branche | HEAD avant | HEAD apres | Fichiers |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 67b5c653 | 76435e22 | src/plugins/tenantGuard.ts |
| keybuzz-client | ph148/onboarding-activation-replay | efa08dd5 | b230aa90 | src/config/api.ts + app/api/messages/conversations/[id]/reply/route.ts (nouveau) |
| keybuzz-infra | main | 891cbda | 2adb753 | k8s/keybuzz-api-dev/deployment.yaml + k8s/keybuzz-client-dev/deployment.yaml |

### 3.1 API tenantGuard.ts (28 insertions, 3 deletions)

Ajout matcher dedie REPLY :

```typescript
function isMessagesConversationReplyPost(method: string, path: string): boolean {
  if (method !== 'POST') return false;
  const prefix = '/messages/conversations/';
  if (!path.startsWith(prefix)) return false;
  const rest = path.substring(prefix.length);
  const segments = rest.split('/');
  if (segments.length !== 2) return false;
  if (!segments[0] || segments[1] !== 'reply') return false;
  return true;
}
```

`isProtected()` etendu :

```typescript
function isProtected(method, path): boolean {
  if (PROTECTED_ROUTES.some(r => r.method === method && r.path === path)) return true;
  if (isMessagesConversationDetailGet(method, path)) return true;
  if (isMessagesConversationReplyPost(method, path)) return true;
  return false;
}
```

Matcher strict : method=POST, prefix=`/messages/conversations/`, exactement 2 segments, segment 1 non vide, segment 2 == literal `reply`. Toute deviation (status, assign, sav-status, reply/extra, GET /reply, 3 segments) -> FALSE -> route non protegee -> AS.11.1e+ scope.

### 3.2 Client api.ts (1 ligne modifiee, 1 commentaire ajoute)

```typescript
// PH-SAAS-T8.12AS.11.1D KEY-304: reply endpoint routed via authenticated BFF (POST).
conversationReply: (id, tenantId) => `/api/messages/conversations/${id}/reply${tenantId ? '?tenantId=' + encodeURIComponent(tenantId) : ''}`,
```

Plus de `${API_CONFIG.baseUrl}` : URL relative qui va donc passer par la route BFF Next.js et non plus en direct.

### 3.3 Client BFF route reply (nouveau, 899 octets)

`app/api/messages/conversations/[id]/reply/route.ts` : POST handler scope only, delegue a `proxyMessages(req, 'POST', /messages/conversations/${id}/reply)`. Pas de GET/PATCH/DELETE handler. Reuse du helper `proxyMessages` deja en place depuis AS.11.1A.

`proxyMessages` injecte automatiquement X-User-Email (depuis getServerSession NextAuth) + X-Tenant-Id, ne forward jamais Cookie/Authorization, ne log jamais le body.

---

## 4. Audit signaux

| Signal | Avant AS.11.1D | Apres AS.11.1D |
|---|---|---|
| POST /reply no-auth | 200/400 handler-level (selon body) | 401 AUTH_REQUIRED preHandler |
| POST /reply bogus user | 200/400 handler-level | 403 NOT_MEMBER preHandler |
| POST /reply ludo personal cross-tenant SWITAA | 200/400 handler-level | 403 NOT_MEMBER preHandler |
| POST /reply switaa26 owner | 200/handler (preserve handler) | non teste (NO positive POST) |
| Client conversationReply target | `${baseUrl}/messages/conversations/...` direct API | relatif `/api/messages/...` via BFF Next.js |

---

## 5. Build

| Item | API | Client |
|---|---|---|
| Source commit | 76435e22bb7613fabdaf9beee7bcb7ae189c2c6b | b230aa9025bddb427359dc9281e9a0a651de47e6 |
| Tag image | v3.5.172-messages-reply-tenantguard-dev | v3.5.186-messages-reply-bff-dev |
| KEY-309 pre-push check | AVAILABLE | AVAILABLE |
| KEY-308 OCI revision | full commit SHA | full commit SHA |
| KEY-308 OCI created | 2026-05-11T21:33:23Z | 2026-05-11T21:35:21Z |
| KEY-308 OCI version | v3.5.172-messages-reply-tenantguard-dev | v3.5.186-messages-reply-bff-dev |
| KEY-302 bundle verify | n/a (API) | api-dev=2 sentinel=0 api-prod=0 OK |
| Digest GHCR | sha256:347cdec7d4a3d9f029b9d329c922dc95def1430b545a735ec3575015a3ea2ca0 | sha256:626cfe4427887159641308525925d0e8de36d3e2d4daa8832c66ee8cc05f4205 |
| docker push | OK | OK |
| Rollback tag | v3.5.171-messages-detail-tenantguard-dev | v3.5.185-messages-detail-bff-dev |

Aucun docker push hors les 2 cibles. Aucun rebuild d image existante.

---

## 6. GitOps

Commit infra `2adb753` modifies 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.171 -> v3.5.172
- `k8s/keybuzz-client-dev/deployment.yaml` : image v3.5.185 -> v3.5.186

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply order :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API OK
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client OK

Aucun kubectl set/edit/patch/set env. GitOps pur.

Runtime DEV post-apply :
- keybuzz-api : `ghcr.io/keybuzzio/keybuzz-api:v3.5.172-messages-reply-tenantguard-dev` MATCH=yes
- keybuzz-client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.186-messages-reply-bff-dev` MATCH=yes
- /health API : `{"status":"ok",...}` 200

---

## 7. Security validation negatifs ONLY (8/8 PASS)

| # | Check | Method | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| 1 | POST reply no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| 2 | POST reply bogus user | kubectl exec curl x-user-email=bogus@example.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 3 | POST reply ludo personal cross-tenant SWITAA | kubectl exec curl x-user-email=ludo.gonthier@gmail.com | 403 NOT_MEMBER | 403 `{"error":"Access denied: not a member of this tenant"}` | PASS |
| 4 | POST reply no tenantId valid email | kubectl exec curl x-user-email=switaa26@gmail.com pas de tenantId | 400 TENANT_ID_MISSING | 400 `{"error":"tenantId is required","code":"TENANT_ID_MISSING"}` | PASS |
| 5 | GET (wrong method) on /reply path | curl https public no header GET | 404 (handler) | 404 | PASS (matcher rejette method != POST) |
| 6 | Preserve AS.11.1A LIST no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 7 | Preserve AS.11.1C DETAIL no-auth | curl https public no header | 401 AUTH_REQUIRED | 401 | PASS |
| 8 | Preserve status route non protege | curl https public no header PATCH /status | handler-level (pas 401) | 400 (handler) | PASS (confirme not yet migrated AS.11.1e) |

Aucun POST positif n a ete emis vers `/messages/conversations/:id/reply` pendant la phase. Tous les tests visent un id factice `00000000-0000-0000-0000-000000000000` et sont rejetes par tenantGuard en preHandler AVANT d atteindre le route handler.

---

## 8. DB no-mutation proof

| Mesure | Quand | Valeur |
|---|---|---|
| messages WHERE tenant_id='switaa-sasu-mnc1x4eq' | E0 preflight (pre-deploy) | 162 |
| messages WHERE tenant_id='switaa-sasu-mnc1x4eq' | post tests negatifs T1-T8 | 162 |
| Delta | -- | 0 |

Source : `SELECT COUNT(*) FROM messages WHERE tenant_id='switaa-sasu-mnc1x4eq'` execute via `kubectl exec deploy/keybuzz-api -- node` avec pool DB DEV. Aucune mutation messages, replies, ai_drafts, ai_suggestions enregistree pendant la phase.

---

## 9. Smoke V1 DEV post-deploy

```
=== Summary ===
PASS=17 WARN=1 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Detail :
- A. Runtime/GitOps : 6/6 PASS (images, drift, pods ready)
- B. Bundle guard : 5/5 PASS (no sentinel, api-dev inline, no prod url, labels Brouillon IA / Valider et envoyer)
- C. API DEV read-only : 3 PASS + 1 WARN (`/messages/conversations 401 auth required` = comportement attendu post AS.11.1A LIST protection)
- D. Client BFF read-only : 3/3 PASS
- E. /autopilot/draft probe : SKIP (pas de SMOKE_CONVERSATION_ID fournie, par design)

FAIL=0. RESULT=PASS_WITH_WARNINGS conforme depuis AS.11.1A-R2.

---

## 10. PROD inchange (table avant/apres)

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

## 11. AI feature parity (anti-regression)

| Surface | Statut DEV post AS.11.1D | Justification |
|---|---|---|
| Inbox liste conversations | inchange (BFF AS.11.1A-R2 reste actif) | LIST endpoint deja protege |
| Inbox detail conversation | inchange (BFF AS.11.1C reste actif) | DETAIL endpoint deja protege |
| Brouillon IA visibilite auto | inchange (consolidated useEffect AS.11.0.6 reste actif) | logique React identique |
| Brouillon IA "Valider et envoyer" UI | bouton present runtime DEV (bundle Client contient label) | non clique pendant phase (consigne explicite Ludovic) |
| autopilot/draft endpoint | inchange (PROBE SKIP smoke E) | endpoint hors scope AS.11.1D |
| Status / assign / sav-status routes | inchange (non encore protegees) | scope futur AS.11.1e -> AS.11.1f |
| Reply send happy path | non teste cote utilisateur | QA Ludovic en charge sans cliquer Valider (consigne) |

Aucune regression observee sur les surfaces non touchees. Aucun message reellement envoye via /reply.

---

## 12. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve dans ce rapport. Toutes les valeurs (162 messages SWITAA, digests, commits, PROD images) sont issues de mesures directes runtime ou GHCR.

---

## 13. Gaps remaining (post AS.11.1D)

| Sous-phase | Endpoint | Method | Risque |
|---|---|---|---|
| AS.11.1e | /messages/conversations/:id/status | PATCH | mutation status, QA sans changer statut |
| AS.11.1f-1 | /messages/conversations/:id/assign | PATCH | mutation assignation, QA sans assigner |
| AS.11.1f-2 | /messages/conversations/:id/sav-status | PATCH | mutation SAV, QA sans changer SAV status |
| AS.11.1g | Promotion PROD coordonnee | n/a | KEY-263 closure conditionnelle post toutes sous-phases DEV |

Pattern matcher reutilisable : helper `isMessagesConversationSubpathProtected(method, path, allowed_actions)` propose au QA closeout AS.11.1C, peut etre adopte en AS.11.1e ou les 3 prochaines sous-phases mergees en une seule si Ludovic le decide.

---

## 14. Linear updates

| Issue | Action | Statut |
|---|---|---|
| KEY-304 | commentaire AS.11.1D poste, disclosure controle | reste In Review (LIST+DETAIL+REPLY OK, 3 endpoints restants) |
| KEY-301 | commentaire progression 3/6 endpoints poste | reste Open/Todo |

### 14.1 KEY-304 commentaire (texte poste)

```
## AS.11.1D POST /messages/conversations/:id/reply protected in DEV

- Matcher strict: method=POST, prefix=/messages/conversations/, exactly 2 segments, last segment literal `reply`.
- Client conversationReply now routed via BFF (relative path), POST handler scoped only.
- Security validation NEGATIVE ONLY 8/8 PASS:
  - no-auth 401 AUTH_REQUIRED
  - bogus user 403 NOT_MEMBER
  - cross-tenant 403 NOT_MEMBER
  - missing tenantId 400 TENANT_ID_MISSING
  - GET wrong-method 404 (matcher rejects non-POST)
  - preserve LIST 401, preserve DETAIL 401
  - status route still unprotected 400 handler-level (confirms not yet migrated)
- DB no-mutation proof: messages SWITAA count 162 -> 162 (delta 0). No positive POST issued.
- Smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 (WARN /messages/conversations 401 = expected post AS.11.1A LIST protection).
- Runtime DEV : API v3.5.172-messages-reply-tenantguard-dev + Client v3.5.186-messages-reply-bff-dev, MATCH=yes GitOps.
- PROD strictly unchanged (8 services).

KEY-304 remains In Review because status/assign/sav-status remain future phases AS.11.1e -> AS.11.1f. Do NOT mark Done until all 6 endpoints are migrated and validated.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1D-MESSAGES-REPLY-TENANTGUARD-DEV-01.md
```

### 14.2 KEY-301 commentaire (texte poste)

```
Partial runtime mitigation in DEV now covers 3/6 endpoints `/messages` : LIST + DETAIL + REPLY. Cross-tenant access denied PROVEN on POST /reply (ludo personal email targeting SWITAA -> 403 NOT_MEMBER) without any DB mutation (messages count 162 -> 162, delta 0).

Progression KEY-301 : 3/6 endpoints `/messages` proteges runtime DEV. Continue endpoint-by-endpoint sequence AS.11.1e -> AS.11.1f before considering PROD promotion (KEY-263 blocker).

KEY-301 stays Open. PROD strictly unchanged (8 services).

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 15. Rollback plan

Si regression detectee post AS.11.1D :
1. `cd /opt/keybuzz/keybuzz-infra`
2. `git revert 2adb753 --no-edit` puis commit
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> retour v3.5.171
4. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> retour v3.5.185
5. PROD inchange (rien a rollback en PROD)

Les sources API + Client sont revertibles par revert commits 76435e22 (api) + b230aa90 (client). Le revert garde les fichiers BFF route (`app/api/messages/conversations/[id]/reply/route.ts`) en place mais re-attache la const `conversationReply` a l URL directe API : meme code path qu avant.

---

## 16. Compliance AS.11.1D

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repo clean avant build | OK (verifie git status pre-commit) |
| commit + push AVANT build | OK (API 76435e22 push, Client b230aa90 push, infra 2adb753 push) |
| Build-from-Git | OK (docker build avec contexte git repo, no SCP source) |
| Tag immuable (no :latest) | OK |
| KEY-302 build args | OK (NEXT_PUBLIC_API_BASE_URL inject, sentinel=0) |
| KEY-308 OCI labels | OK (revision/created/version/source/title presents) |
| KEY-309 pre-push tag check | OK (les deux tags AVAILABLE avant push) |
| Digest documente | OK (sha256:347c... + sha256:626c...) |
| Rollback plan documente | OK section 15 |
| GitOps strict | OK (kubectl apply -f only) |
| No kubectl set/edit/patch | OK |
| ASCII strict rapport | OK |
| No PROD mutation | OK (PROD images inchange 8 services) |
| No DB mutation | OK (messages SWITAA delta 0) |
| Disclosure controle Linear | OK (pas de PoC, pas de details exploit) |
| KEY-304 NOT marked Done | OK (reste In Review) |
| KEY-301 NOT marked Done | OK (reste Open) |
| No PII / no client data copied | OK |
| Tests negatifs ONLY | OK (aucun POST positif emis) |

---

## 17. Phrase cible finale

AS.11.1D livre : POST `/messages/conversations/:id/reply` protege en DEV avec tenantGuard runtime + Client BFF authentifie ; tests negatifs only 8/8 PASS (no-auth 401, bogus 403, ludo cross-tenant 403, no tenantId 400, GET 404, preserve LIST+DETAIL 401, status non protege 400) ; DB messages SWITAA 162 -> 162 delta 0 ; aucun POST positif emis ; smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; runtime DEV API v3.5.172-messages-reply-tenantguard-dev + Client v3.5.186-messages-reply-bff-dev MATCH=yes GitOps ; PROD strictement inchange (8 services) ; KEY-304 reste In Review (LIST+DETAIL+REPLY OK, 3 endpoints restants : status/assign/sav-status AS.11.1e -> AS.11.1f) ; KEY-301 progression 3/6 ; verdict AS.11.1D GO MESSAGES REPLY TENANTGUARD DEV READY.

STOP
