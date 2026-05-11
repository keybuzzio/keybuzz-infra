# PH-SAAS-T8.12AS.11.1C-MESSAGES-DETAIL-TENANTGUARD-DEV-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301, KEY-305
> Phase : T8.12 AS.11.1C - protect GET /messages/conversations/:id DETAIL with tenantGuard + Client BFF
> Environnement : DEV deploy ; PROD read-only ; aucun manifest PROD

---

## 1. VERDICT

GO MESSAGES DETAIL SECURITY DEV READY

NO PROD MUTATION.

DETAIL endpoint `GET /messages/conversations/:id` desormais protege en DEV par le tenantGuard avec un matcher exact (1 segment apres `/messages/conversations/`, pas de sub-path). Client `fetchConversationDetail` route maintenant via le BFF dedie `app/api/messages/conversations/[id]/route.ts` GET-only. Aucun autre endpoint touche.

7 security checks PASS :
- LIST no-auth -> 401 (AS.11.1A preserve)
- DETAIL no-auth -> 401 (nouveau AS.11.1C)
- DETAIL bogus user -> 403
- DETAIL switaa26 owner -> 200 size=3329
- DETAIL Ludovic personnel cross-tenant -> 403 (denied PROVEN)
- `reply` GET no-auth -> 404 (route POST-only, scope strict respecte)
- `/autopilot/draft` -> 200 (route inchangee)

Smoke V1 post-deploy : **PASS=19 WARN=0 FAIL=0 SKIP=0 RESULT=PASS**. Logs DEV : 0 5xx API, 0 JWT_SESSION_ERROR Client. PROD strictement inchange.

KEY-304 progression : 2/6 endpoints `/messages` proteges runtime DEV (LIST + DETAIL). Reste 4 endpoints (reply, status, assign, sav-status).

---

## 2. Scope

3 commits livres :

| Repo | Commit | Files | Message |
|---|---|---|---|
| keybuzz-api | `67b5c653` | src/plugins/tenantGuard.ts | fix(security): protect messages conversation detail with tenant guard (KEY-304) |
| keybuzz-client | `efa08dd` | src/config/api.ts + app/api/messages/conversations/[id]/route.ts | fix(client): route conversation detail through authenticated BFF (KEY-304) |
| keybuzz-infra | `75c0e76` | k8s/keybuzz-api-dev/deployment.yaml + k8s/keybuzz-client-dev/deployment.yaml | deploy(dev): protect messages detail via tenant guard and BFF (KEY-304) |

Aucun autre fichier modifie. Aucun changement reply/status/assign/sav/autopilot/AI/channels/suppliers/orders/tracking.

---

## 3. Route matcher

Le matcher `isProtected(method, path)` accepte maintenant DEUX patterns :

1. **Exact path/method** (AS.11.1A) : `{ method: 'GET', path: '/messages/conversations' }` dans `PROTECTED_ROUTES`.

2. **Pattern detail** (AS.11.1C) : fonction `isMessagesConversationDetailGet(method, path)` qui retourne true uniquement si :
   - `method === 'GET'`
   - `path.startsWith('/messages/conversations/')`
   - le reste (apres `/messages/conversations/`) est une chaine non-vide
   - le reste ne contient PAS de `/` (donc 1 seul segment exact)

Test de matching exhaustif :

| Path | Method | Should protect? | Matcher result | Reason |
|---|---|---|---|---|
| `/messages/conversations` | GET | OUI | TRUE (exact AS.11.1A) | LIST |
| `/messages/conversations` | POST | NON | FALSE | LIST POST n est pas une route officielle |
| `/messages/conversations/abc` | GET | OUI | TRUE (detail AS.11.1C) | DETAIL |
| `/messages/conversations/abc` | POST | NON | FALSE | DETAIL POST n existe pas |
| `/messages/conversations/abc/reply` | POST | NON | FALSE | reply (futur AS.11.1d) |
| `/messages/conversations/abc/reply` | GET | NON | FALSE | reply route POST-only, GET = 404 |
| `/messages/conversations/abc/status` | PATCH | NON | FALSE | status (futur AS.11.1e) |
| `/messages/conversations/abc/assign` | PATCH | NON | FALSE | assign (futur AS.11.1f-1) |
| `/messages/conversations/abc/sav-status` | PATCH | NON | FALSE | sav-status (futur AS.11.1f-2) |
| `/messages/conversations/abc/x/y` | GET | NON | FALSE | deep nested, route inconnue |
| `/messages/conversations/` (trailing slash) | GET | NON | FALSE | rest serait `` longueur 0 -> rejette |

Le matcher est testable, deterministe, et lisible (pas de regex). Couvre exactement DETAIL sans capture les sub-paths.

---

## 4. Patch

### 4.1 API `src/plugins/tenantGuard.ts`

Ajout :
- Comment AS.11.1C dans la docstring du plugin (decrit scope etendu : LIST + DETAIL).
- Fonction helper `isMessagesConversationDetailGet(method, path)` (5 lignes logique pure, testable).
- `isProtected(method, path)` etendu : retourne TRUE si soit exact route tuple match (AS.11.1A) soit detail pattern match (AS.11.1C).

Diff stat : `1 file changed, 35 insertions(+), 8 deletions(-)`.

Aucun changement de logique `checkMembership`, `extractTenantId`, `isExempt`. Pas de touche au membership SQL.

### 4.2 Client `src/config/api.ts`

Une seule entree modifiee : `conversationDetail`. Ligne :

```diff
- conversationDetail: (id, tenantId?) => `${API_CONFIG.baseUrl}/messages/conversations/${id}...`
+ // PH-SAAS-T8.12AS.11.1C KEY-304: detail endpoint routed via authenticated BFF.
+ conversationDetail: (id, tenantId?) => `/api/messages/conversations/${id}...`
```

Les 4 autres entrees conversations (reply, status, assign, sav-status) restent en direct API.

### 4.3 Client `app/api/messages/conversations/[id]/route.ts` (nouveau, 856 bytes)

Route Next.js dynamic segment :

```typescript
export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } },
): Promise<NextResponse> {
  return proxyMessages(req, 'GET', `/messages/conversations/${params.id}`);
}
```

Pas de POST/PATCH/DELETE handler. Reuse du helper `proxyMessages` deja en place depuis AS.11.1A.

---

## 5. Build

| Item | API | Client |
|---|---|---|
| Source commit | 67b5c653b295a84492c72aeb524cb3605e28f3bb | efa08dd55079ff2fd1cb33725936ae9901038e5a |
| Tag image | v3.5.171-messages-detail-tenantguard-dev | v3.5.185-messages-detail-bff-dev |
| KEY-309 pre-push check | AVAILABLE | AVAILABLE |
| KEY-308 OCI revision | full commit SHA | full commit SHA |
| KEY-302 verify bundle | n/a (API) | api-dev=2 api.kbz=0 OK |
| Build duration | 1m3s | 1m39s |
| Digest GHCR | sha256:0032b807db6f... | sha256:77c50b85b523... |
| docker push | OK | OK |

Aucun docker push hors les 2 cibles. Aucun rebuild d image existante.

---

## 6. GitOps

Commit infra `75c0e76` modifies 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.170 -> v3.5.171
- `k8s/keybuzz-client-dev/deployment.yaml` : image v3.5.184 -> v3.5.185

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply order :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API OK
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client OK

Aucun kubectl set/edit/patch/set env. GitOps pur.

---

## 7. Security validation (7/7 PASS)

| # | Check | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| 1 | LIST no-auth (preserve AS.11.1A) | curl direct https no header | 401 | **401** | PASS |
| 2 | DETAIL no-auth (nouveau AS.11.1C) | curl direct https no header | 401 | **401** | PASS |
| 3 | DETAIL bogus user | kubectl exec curl x-user-email=bogus | 403 NOT_MEMBER | **403** | PASS |
| 4 | DETAIL legit SWITAA owner | kubectl exec curl x-user-email=switaa26 | 200 + shape | **200 size=3329** | PASS |
| 5 | DETAIL Ludovic personnel cross-tenant SWITAA | kubectl exec curl x-user-email=ludo.gonthier | 403 NOT_MEMBER | **403** | PASS (cross-tenant denied PROVEN) |
| 6 | reply GET no-auth (route POST-only, scope strict respecte) | curl direct https | 404 (route not found pour GET) ou 200 sans guard | **404** | PASS (route Fastify POST-only) |
| 7 | /autopilot/draft (route inchangee) | kubectl exec curl x-user-email=switaa26 | 200 + shape | **200 size=18** | PASS |

**Cross-tenant security PROVEN end-to-end** : un user ecomlg-001 tentant de lire un detail de conversation SWITAA est correctement bloque (403) au niveau API meme si le frontend leak le conversationId. C est le but securitaire de KEY-304.

---

## 8. Functional validation

### 8.1 Smoke V1 post-deploy

Variables exportees :
- SMOKE_USER_EMAIL=switaa26@gmail.com (correct membership SWITAA)
- SMOKE_EXPECTED_API_IMAGE=v3.5.171-messages-detail-tenantguard-dev
- SMOKE_EXPECTED_CLIENT_IMAGE=v3.5.185-messages-detail-bff-dev
- SMOKE_CONVERSATION_ID=cmmp0uhhkd... (known SWITAA conv)

Resultat :
```
PASS=19 WARN=0 FAIL=0 SKIP=0
RESULT=PASS
```

Detail :
- A. Runtime/GitOps : 6/6 PASS (images match expected, spec=last-applied, pods ready)
- B. Bundle guard : 5/5 PASS (sentinel absent, api-dev inline, PROD URL absent, Brouillon IA + Valider et envoyer presents)
- C. API DEV : 4/4 PASS dont `/messages/conversations 200 size=1189` (switaa26 membership)
- D. Client/BFF : 3/3 PASS
- E. `/autopilot/draft` probe : PASS (route inchangee)

### 8.2 Logs post-rollout

| Source | Window | Signal | Count |
|---|---|---|---|
| API DEV | 2 min | 5xx | 0 |
| Client DEV | 2 min | JWT_SESSION_ERROR | 0 |

Aucune anomalie post-deploy.

### 8.3 QA Ludovic navigateur

A executer par Ludovic (logge avec `switaa26@gmail.com` business SWITAA) :
1. Ouvrir `client-dev.keybuzz.io` -> Inbox SWITAA -> liste conversations visible (LIST OK, AS.11.1A preserve).
2. Selectionner une conversation -> detail conversation s ouvre, messages visibles (DETAIL via BFF AS.11.1C nouveau).
3. Brouillon IA visible automatiquement (AS.11.0.6 fix preserve).
4. Boutons `Valider et envoyer` / `Modifier` / `Ignorer` visibles (NON cliques).
5. Aucune banniere "API indisponible".

Validation indirecte cote API : section 7 + 8.1 confirment que le flux LIST + DETAIL + autopilot/draft fonctionne pour `switaa26@gmail.com`. La QA navigateur viendra confirmer le rendu UI.

---

## 9. Rollback (non applique)

Si QA Ludovic KO ou regression decouverte :

```bash
cd /opt/keybuzz/keybuzz-infra
sed -i 's|keybuzz-api:v3.5.171-messages-detail-tenantguard-dev|keybuzz-api:v3.5.170-messages-list-tenantguard-dev|g' k8s/keybuzz-api-dev/deployment.yaml
sed -i 's|keybuzz-client:v3.5.185-messages-detail-bff-dev|keybuzz-client:v3.5.184-messages-list-bff-dev|g' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-api-dev/deployment.yaml k8s/keybuzz-client-dev/deployment.yaml
git commit -m 'rollback(dev): AS.11.1C revert after QA failure (KEY-304)'
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client
```

Estime : 3 minutes. Restore to AS.11.1A-R2 baseline (API v3.5.170 + Client v3.5.184).

---

## 10. PROD unchanged

| Service | PROD image | Statut |
|---|---|---|
| API | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| Worker | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `-prod`.

---

## 11. Gaps / next endpoint

1. **QA Ludovic navigateur** : a faire avec `switaa26@gmail.com` business SWITAA pour confirmer Inbox + detail conversation + Brouillon IA UX.

2. **AS.11.1d (suivant) : reply POST**. Pattern : ajouter `{ method: 'POST', path: '/messages/conversations/:id/reply' }` matcher (regex ou helper). Client BFF route POST. Risque : mutation - validation envoi message obligatoire (mais sans cliquer Valider/envoyer dans la phase QA).

3. **Sequence AS.11.1e (status), AS.11.1f-1 (assign), AS.11.1f-2 (sav-status)** : PATCH methods. Pattern identique au AS.11.1d.

4. **AS.11.1g promotion PROD** : seulement apres tous les sous-endpoints `/messages` valides DEV + KEY-263 closure.

5. **Image AS.11.1A-R2 v3.5.170 + v3.5.184** : restees sur GHCR mais NON runtime apres AS.11.1C (replaced par v3.5.171 + v3.5.185). A documenter en SOT pour eviter confusion future, mais reutilisables si rollback AS.11.1C necessaire.

---

## 12. Linear text prepared, posted

Postee sur KEY-304 et KEY-301.

### 12.1 KEY-304

```
## AS.11.1C -- DETAIL endpoint protected DEV

Source patch + build + deploy :
- API commit 67b5c653 : tenantGuard etendu avec matcher detail (1 segment apres /messages/conversations/)
- Client commit efa08dd : BFF route detail GET-only + api.ts conversationDetail via BFF
- Infra commit 75c0e76 : manifests DEV API + Client mis a jour
- Images : v3.5.171 (API, digest sha256:0032b807db6f...) + v3.5.185 (Client, digest sha256:77c50b85b523...)

Security validation 7/7 PASS :
- LIST no-auth 401, DETAIL no-auth 401, DETAIL bogus 403, DETAIL switaa26 200, DETAIL Ludovic perso 403 (cross-tenant), reply GET 404 (POST-only), /autopilot/draft 200 inchange.

Smoke V1 PASS=19 WARN=0 FAIL=0 SKIP=0. Logs propres 0 5xx, 0 JWT.

KEY-304 progression : 2/6 endpoints `/messages` proteges (LIST + DETAIL). Reste reply, status, assign, sav-status.

Reste In Review. QA Ludovic navigateur avec switaa26@gmail.com recommandee avant AS.11.1d.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1C-MESSAGES-DETAIL-TENANTGUARD-DEV-01.md
```

### 12.2 KEY-301

```
Partial runtime mitigation in DEV extended to /messages/conversations/:id DETAIL. Cross-tenant access denied PROVEN for an ecomlg-001 user trying to read SWITAA detail.

Progression KEY-301 : 2/6 endpoints `/messages` proteges. Continue endpoint-by-endpoint sequence AS.11.1d -> AS.11.1f.

KEY-301 stays Open. Pas de PoC ni details exploit.
```

---

### 12.bis Phrase cible finale

AS.11.1C livre la protection DETAIL `/messages/conversations/:id` GET en DEV (API commit 67b5c653 + Client commit efa08dd + Infra commit 75c0e76) ; matcher tenantGuard etendu avec helper `isMessagesConversationDetailGet` (1 segment strict pas de sub-path) ; Client BFF dynamic route `[id]/route.ts` GET-only ; build local + push GHCR images v3.5.171 + v3.5.185 avec KEY-302/308/309 obligatoires respectes ; GitOps DEV apply API+Client successfully rolled out ; security validation 7/7 PASS (LIST no-auth 401, DETAIL no-auth 401, DETAIL bogus 403, DETAIL switaa26 200 size=3329, DETAIL Ludovic perso cross-tenant 403 PROVEN denied, reply GET 404 route POST-only scope strict, /autopilot/draft inchange) ; smoke V1 PASS=19 ; logs propres ; PROD strictement inchange ; KEY-304 progression 2/6 endpoints proteges ; verdict AS.11.1C GO MESSAGES DETAIL SECURITY DEV READY en attente QA Ludovic navigateur switaa26@gmail.com.

STOP
