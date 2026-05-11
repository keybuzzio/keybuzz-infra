# PH-SAAS-T8.12AS.11.1A-MESSAGES-LIST-BFF-TENANTGUARD-DEV-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301, KEY-305
> Phase : T8.12 AS.11.1A - protect /messages/conversations LIST endpoint + Client BFF migration (rollbacked)
> Environnement : DEV patche + deploye + rollback complet. PROD strictement inchange.

---

## 1. VERDICT

NO GO FUNCTIONAL REGRESSION ROLLBACK DONE

Le patch API tenantGuard + Client BFF pour `/messages/conversations` (LIST) a ete livre, builde, push GHCR, deploye DEV, validee en security (no-auth 401 OK, bogus user 403 OK), mais **a echoue le check membership pour le compte de test Ludovic** : `ludo.gonthier@gmail.com` n est PAS dans la table `user_tenants` pour `switaa-sasu-mnc1x4eq` (seuls 4 emails y sont : `switaa26@gmail.com` owner + 3 agents). Le mecanisme par lequel Ludovic accede a SWITAA en navigateur est probablement une autre voie (superadmin, owner_email column, role server-side) que la table `user_tenants` referencee par le tenantGuard.

Rollback DEV applique immediatement :
- API DEV revert vers `v3.5.168-escalation-notifications-dev` (digest pre-AS.11.1A)
- Client DEV revert vers `v3.5.183-ai-draft-effect-order-fix-dev` (AS.11.0.6 baseline)
- Smoke V1 post-rollback : PASS=18 WARN=0 FAIL=0 SKIP=1 RESULT=PASS

PROD strictement inchange (5 services PROD identiques pre/post AS.11.1A).

KEY-304 reste In Review. La phase AS.11.1A est REUSSIE pour la chaine technique (build/push/deploy/security checks) mais ECHOUE pour la chaine fonctionnelle (Ludovic = exemple representatif de "vrai user" dont la session NextAuth email n est pas mappee au membership user_tenants pour SWITAA).

Une phase prerequis AS.11.0.7 (proposition) doit reconcilier le mecanisme d acces user vs membership user_tenants AVANT de reprendre AS.11.1A.

---

## 2. Scope realisee

3 commits livres :

| Repo | Commit | Message | Statut |
|---|---|---|---|
| keybuzz-api | `3f669057` | fix(security): protect messages conversations list with tenant guard (KEY-304) | applique puis revert via redeploy |
| keybuzz-client | `dc5e35d` | fix(client): route conversations list through authenticated BFF (KEY-304) | applique puis revert via redeploy |
| keybuzz-infra | `ffb45b8` puis `4b5290f` | deploy(dev) puis rollback(dev) | manifest move forward + back |

Note : les commits source applicatifs (API et Client) restent sur les branches respectives. Le rollback est purement GitOps (manifest revert). Pour eviter toute confusion future, les images `v3.5.170-messages-list-tenantguard-dev` (API) et `v3.5.184-messages-list-bff-dev` (Client) sont a ajouter dans la liste **DO_NOT_REDEPLOY** de la SOT (cf section 10).

---

## 3. Patch realise (4 fichiers)

### 3.1 API : `src/plugins/tenantGuard.ts`

Modifications :
- Ajout `import fp from 'fastify-plugin'`.
- Wrap du plugin via `fp(tenantGuardImpl, { name: 'tenant-guard' })` pour que le hook `preHandler` s applique au scope parent (fix KEY-301).
- Allowlist stricte `PROTECTED_ROUTES: [{method: 'GET', path: '/messages/conversations'}]`.
- Fonction `isProtected(method, path)` : exact match method + path (pas prefix).
- Hook : early-return si `!isProtected(...)` -> aucune route hors allowlist n est impactee.

Diff stat : 1 file changed, 49 insertions(+), 3 deletions(-).

### 3.2 Client : `src/config/api.ts`

Une seule entree modifiee : `conversations` -> path relatif BFF `/api/messages/conversations?tenantId=...`. Les 5 autres entrees conversations (detail, reply, status, assign, sav-status) restent en direct API `${baseUrl}/...`.

### 3.3 Client : `app/api/messages/_bff.ts` (nouveau, 4152 bytes)

Helper Next.js BFF :
- `getServerSession(authOptions)` -> userEmail (401 NO_SESSION sinon).
- Extract tenantId from query or x-tenant-id header.
- Forward `${API_URL_INTERNAL}/messages/...` avec X-User-Email + X-Tenant-Id headers.
- Pas de log body. Pas de forward Cookie/Authorization. Body raw pour non-GET.
- 502 sur upstream fetch failure, 503 sur misconfig.

### 3.4 Client : `app/api/messages/conversations/route.ts` (nouveau, 824 bytes)

Une seule route GET : `proxyMessages(req, 'GET', '/messages/conversations')`. Pas de POST/PATCH/DELETE.

---

## 4. Build (KEY-302 + KEY-308 + KEY-309)

### 4.1 API build

| Item | Valeur |
|---|---|
| Source commit | 3f6690579e06aba2fc2e8befcde1267deefb23d9 |
| Tag image | v3.5.170-messages-list-tenantguard-dev |
| KEY-309 pre-push check | exit 0 AVAILABLE |
| KEY-308 OCI revision | 3f6690579e06aba2fc2e8befcde1267deefb23d9 (full SHA, embedded) |
| Build duration | 1m3s |
| Digest GHCR | sha256:b1d78eb9ec3f1597dd902d382905ca1169f5b4afd98c1c6a76e884c66210049e |

### 4.2 Client build

| Item | Valeur |
|---|---|
| Source commit | dc5e35daa47afdeb277a6ab89ec0287ca860e407 |
| Tag image | v3.5.184-messages-list-bff-dev |
| KEY-309 pre-push check | exit 0 AVAILABLE |
| KEY-302 verify | api-dev=2, api.kbz=0 (OK strict) |
| KEY-308 OCI revision | dc5e35daa47afdeb277a6ab89ec0287ca860e407 |
| Build duration | 1m40s |
| Digest GHCR | sha256:7a6453355c38de9f1d508b24087d7dd6e17680b7ee4c14c7fc262dc3ba8a5239 |

Les deux images sont sur GHCR. **A ne PAS redeployer sans correction du membership Ludovic (cf section 10)**.

---

## 5. GitOps DEV (puis rollback)

### 5.1 Apply order initial (move forward)

Commit infra `ffb45b8` : `deploy(dev): protect messages list via tenant guard and BFF (KEY-304)`.

1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> API DEV roule v3.5.170.
2. `kubectl -n keybuzz-api-dev rollout status` -> OK.
3. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> Client DEV roule v3.5.184.
4. `kubectl -n keybuzz-client-dev rollout status` -> OK.

### 5.2 Apply rollback

Commit infra `4b5290f` : `rollback(dev): AS.11.1A blocked - Ludovic membership not in user_tenants SWITAA (KEY-304)`.

1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> API DEV revient v3.5.168.
2. `kubectl -n keybuzz-api-dev rollout status` -> OK.
3. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> Client DEV revient v3.5.183.
4. `kubectl -n keybuzz-client-dev rollout status` -> OK.

Total rollback : ~3 minutes.

---

## 6. Security validation (les checks de securite ont PASSE)

Tests executes pendant la fenetre v3.5.170/v3.5.184 :

| Check | Method | Expected | Observed | Verdict |
|---|---|---|---|---|
| no-auth `GET /messages/conversations?tenantId=...` (browser direct) | curl direct https | 401 AUTH_REQUIRED | 401 | PASS |
| bogus user `GET /messages/conversations` (X-User-Email = inconnu) via pod | curl intra-pod | 403 NOT_MEMBER | 403 | PASS |
| valid auth Ludovic via pod | curl intra-pod x-user-email=ludo.gonthier@gmail.com | 200 + body | **403** NOT_MEMBER | **FAIL** |
| Detail endpoint (non protege par AS.11.1A) | curl direct https | 200 (pas dans PROTECTED_ROUTES) | (sample_conv_id vide car list returned 403 -> chained fail) | NOT_TESTED |

**La securite fonctionne** : les 2 premiers checks confirment que le tenantGuard refuse correctement les requetes sans auth ou avec auth invalide.

**Le probleme** : le compte de test que CE utilise (`ludo.gonthier@gmail.com`) n est pas membre de SWITAA dans la table `user_tenants` :

```
members SWITAA :
  olyara369@gmail.com     role=agent
  switaa26@gmail.com      role=owner
  switaa26+ph140f@gmail.com role=agent
  olyara369+switaa@gmail.com role=agent

Ludovic memberships:
  tenant=ecomlg-001                role=owner
  tenant=test-amz-truth02-...      role=owner
  ... (8 tenants au total, mais PAS switaa-sasu-mnc1x4eq)
```

L acces de Ludovic a SWITAA en navigateur passe donc par un autre mecanisme (probable superadmin/owner_email column dans tenants table, ou role de plateforme cote NextAuth/middleware Client).

---

## 7. Functional validation (blocking check fail)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Smoke V1 PASS sur v3.5.170+v3.5.184 | PASS sans WARN | **PASS_WITH_WARNINGS** (WARN sur /messages/conversations 403 au lieu de 200) | FAIL gating |
| Inbox conversations visible pour Ludovic en navigateur | OUI (cf QA AS.5.3, AS.11.0.6) | NON probable : 403 -> liste vide | FAIL probable (non teste browser) |
| Brouillon IA SWITAA AUTOPILOT visible | OUI baseline | NON probable : selectedId never set -> autopilotDraft null -> label "Suggestion IA" | FAIL probable |
| no DEV browser bundle -> PROD API URL | OK | OK (KEY-302 verify pass) | PASS |
| API logs 5xx | 0 | 0 | PASS |
| Client logs JWT_SESSION_ERROR | low/baseline | 0 (pas de spike) | PASS |

**Gating critique BLOCKING : "Brouillon IA SWITAA AUTOPILOT visible"** ne peut pas etre garanti pour Ludovic (la session NextAuth ludo.gonthier@gmail.com ne passe pas le membership check). Application de la regle AS.11.1A : "If any blocking check fails: rollback DEV via GitOps". ROLLBACK APPLIQUE.

---

## 8. Rollback applique

Cf section 5.2. Total ~3 min. Smoke V1 post-rollback :

```
PASS=18 WARN=0 FAIL=0 SKIP=1
RESULT=PASS
```

Runtime restaure :
- API DEV : v3.5.168-escalation-notifications-dev
- Client DEV : v3.5.183-ai-draft-effect-order-fix-dev (AS.11.0.6)

---

## 9. PROD unchanged

Tous les services PROD INCHANGES :

| Service | PROD image |
|---|---|
| API | v3.5.151-conversation-tone-metric-prod |
| Client | v3.5.174-conversation-tone-metric-ux-prod |
| Backend | v1.0.47-cross-env-guard-fix-prod |
| Website | v0.6.12-linkedin-insight-seo-prod |
| Admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |
| Worker | v3.5.165-escalation-flow-prod |

Aucun deploy PROD pendant AS.11.1A.

---

## 10. Gaps / next endpoint

### 10.1 Images a ajouter DO_NOT_REDEPLOY

A ajouter dans SOT `KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` section 12 (proposition phase doc dediee) :
- `keybuzz-api:v3.5.170-messages-list-tenantguard-dev` -- AS.11.1A rollbackee, source OK mais checkMembership user_tenants ne couvre pas Ludovic.
- `keybuzz-client:v3.5.184-messages-list-bff-dev` -- AS.11.1A rollbackee, compagnon de l API ci-dessus.

Ces images peuvent etre re-utilisees AS-IS apres resolution AS.11.0.7 sans rebuild (le source code est OK, c est la donnee/auth qui doit etre ajustee). Mais elles ne doivent pas etre redeployees sans validation membership.

### 10.2 AS.11.0.7 (proposition prerequis BEFORE AS.11.1A retry)

Phase NEW prerequis :
- audit complet du mecanisme d acces user -> tenant : `tenants.owner_email`, `user_tenants`, `super_admin` flag, NextAuth middleware Client.
- comprendre comment Ludovic accede a SWITAA en navigateur (probable : owner_email comparison ou role server-side au moment de la session).
- decision : soit ajouter Ludovic dans user_tenants SWITAA (mutation DB ad-hoc), soit etendre la fonction `checkMembership` du tenantGuard pour accepter aussi `tenants.owner_email = $1`.
- option preferable : etendre `checkMembership` (plus generique, multi-tenant safe, pas de mutation donnees runtime).

Cette phase est SOURCE-only API + DB read-only investigation. Aucun nouveau build necessaire si on choisit d ajouter Ludovic en user_tenants ad-hoc.

### 10.3 AS.11.1A retry

Apres AS.11.0.7 valide :
- redeploy v3.5.170 (API) + v3.5.184 (Client) sans rebuild (source/Image-tag deja en place).
- re-smoke V1 + QA Ludovic Brouillon IA.

### 10.4 Next endpoints (AS.11.1c -> AS.11.1f)

Toujours attendu :
- AS.11.1c : `/messages/conversations/:id` GET detail.
- AS.11.1d : `/messages/conversations/:id/reply` POST.
- AS.11.1e : `/messages/conversations/:id/status` PATCH.
- AS.11.1f : `/messages/conversations/:id/{assign,sav-status}` PATCH.

Chaque sous-phase reproduit le pattern AS.11.1A : 1 entree dans PROTECTED_ROUTES + 1 entree dans api.ts + 1 route BFF Client + tests no-auth/bogus/valid + QA Brouillon IA. Conditionnees a AS.11.0.7 + AS.11.1A retry OK.

### 10.5 Image tag dette

AS.11.1A produit 2 nouvelles images (API v3.5.170 + Client v3.5.184) qui ne sont pas en runtime. KEY-309 cleaner aurait ete d eviter le push si on savait que la validation echouait. Process retenu : push d abord puis validation, ce qui rend le rollback simple (manifest only, pas de rebuild). Acceptable, mais a documenter en KEY-309 process si re-tentative se reproduit.

---

## 11. Linear text prepared, posted

Postee sur KEY-304. KEY-305 a la confirmation parce que KEY-305 est deja Done.

Texte controle (no PII, no exploit) :

```
## AS.11.1A -- premiere migration BFF/messages LIST -- BLOCKED + ROLLED BACK DEV

Source patch livre et build :
- API `3f669057` : tenantGuard wrap fastify-plugin + PROTECTED_ROUTES strict ['GET /messages/conversations']
- Client `dc5e35d` : BFF helper + GET conversations list route + api.ts UN entry modifie
- Images sur GHCR : keybuzz-api:v3.5.170-messages-list-tenantguard-dev + keybuzz-client:v3.5.184-messages-list-bff-dev
- KEY-302/KEY-308/KEY-309 obligatoires respectes

Apply DEV reussi (rollout API+Client OK). Security checks PASS :
- no-auth `/messages/conversations` -> 401 OK
- bogus user -> 403 OK
- valid Ludovic email -> **403 NOT_MEMBER** (Ludovic absent de user_tenants SWITAA)

Blocking check fail : la session NextAuth `ludo.gonthier@gmail.com` ne mappe pas a un membership `user_tenants` pour `switaa-sasu-mnc1x4eq` (members : switaa26@gmail.com owner + 3 agents). L acces de Ludovic a SWITAA en navigateur passe par un autre mecanisme (probable owner_email column dans tenants table ou role server-side) NON couvert par la fonction `checkMembership` du tenantGuard actuel.

Rollback DEV applique :
- API DEV revert v3.5.168-escalation-notifications-dev
- Client DEV revert v3.5.183-ai-draft-effect-order-fix-dev (AS.11.0.6 baseline)
- smoke V1 post-rollback : PASS=18 WARN=0 FAIL=0 SKIP=1
- ~3 min total

PROD strictement inchange.

Prerequis pour AS.11.1A retry : phase AS.11.0.7 (proposition) qui reconcilie le mecanisme d acces user vs membership user_tenants. Option preferable : etendre `checkMembership` API pour accepter aussi `tenants.owner_email`. Source-only API patch.

KEY-304 reste In Review.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1A-MESSAGES-LIST-BFF-TENANTGUARD-DEV-01.md
```

---

### 11.bis Phrase cible finale

AS.11.1A a livre la chaine technique complete (API tenantGuard wrap fastify-plugin + PROTECTED_ROUTES strict, Client BFF helper + route GET conversations list, build local + push GHCR sur 2 nouvelles images v3.5.170 + v3.5.184, deploy DEV via GitOps API+Client, security checks PASS no-auth 401 + bogus user 403) mais a echoue le check membership pour `ludo.gonthier@gmail.com` qui n est pas dans `user_tenants` pour SWITAA (seul mecanisme actuel verifie par le tenantGuard) ; rollback DEV applique immediatement (API revert v3.5.168 + Client revert v3.5.183 AS.11.0.6 baseline, smoke V1 PASS=18) ; PROD strictement inchange ; AS.11.0.7 (proposition) prerequis avant AS.11.1A retry pour reconcilier user_tenants vs owner_email vs role server-side ; verdict AS.11.1A NO GO FUNCTIONAL REGRESSION ROLLBACK DONE.

STOP
