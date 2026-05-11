# PH-SAAS-T8.12AS.11.1A-R2-MESSAGES-LIST-TENANTGUARD-REAPPLY-DEV-01

> Date : 2026-05-11
> Linear : KEY-304 (principal), KEY-301, KEY-305
> Phase : T8.12 AS.11.1A retry (R2) -- protect /messages/conversations LIST with tenantGuard, reapply existing GHCR images
> Environnement : DEV deploy only ; PROD read-only ; aucun rebuild ; aucun docker push

---

## 1. VERDICT

GO MESSAGES LIST SECURITY DEV READY

NO REBUILD / NO DOCKER PUSH / NO SOURCE PATCH / NO PROD MUTATION.

Reapply GitOps DEV des images deja construites en AS.11.1A :
- API DEV : `v3.5.168-escalation-notifications-dev` -> `v3.5.170-messages-list-tenantguard-dev` (digest sha256:b1d78eb9ec3f...)
- Client DEV : `v3.5.183-ai-draft-effect-order-fix-dev` -> `v3.5.184-messages-list-bff-dev` (digest sha256:7a6453355c38...)

Rollout API + Client successfully. Smoke V1 post-deploy : **PASS=19 WARN=0 FAIL=0 SKIP=0 RESULT=PASS** (toutes les sections valides, /autopilot/draft inclus).

Security validation **6/6 PASS** :
- no-auth direct API -> 401 OK
- bogus user -> 403 OK
- legit SWITAA owner `switaa26@gmail.com` -> 200 size=1189 OK
- Ludovic personnel `ludo.gonthier@gmail.com` cross-tenant tentative SWITAA -> **403** (cross-tenant PROVEN denied)
- `/messages/conversations/:id` detail (non protege par AS.11.1A) -> 200 OK (scope strict)
- `/autopilot/draft` 200 (Brouillon IA route inchangee)

Logs DEV propres : 0 5xx API, 0 JWT_SESSION_ERROR Client.

PROD strictement inchange (5 services PROD identiques pre/post AS.11.1A-R2).

KEY-304 reste In Review jusqu a QA Ludovic navigateur logge avec `switaa26@gmail.com`. Apres QA OK -> Done suggere.

---

## 2. Why R2 was needed

AS.11.1A original avait livre la chaine technique complete (build + push + deploy + security guards) mais avait declenche un rollback DEV apres observation d un 403 sur `/messages/conversations` avec mon test `x-user-email: ludo.gonthier@gmail.com`.

AS.11.0.7 audit a confirme que :
- Le tenantGuard AS.11.1A est ALIGNE avec le modele canonique KeyBuzz (`user_tenants` table ONLY, declare par `tenant-context-routes.ts` ligne 11).
- Ludovic possede deux emails distincts : `ludo.gonthier@gmail.com` (personnel, 7 tenants ecomlg+tests, PAS SWITAA) et `switaa26@gmail.com` (business, SWITAA SASU owner, name="Ludovic GONTHIER" dans la base).
- Le 403 observe en AS.11.1A etait l effet attendu : `ludo.gonthier@gmail.com` n est pas member de SWITAA, donc le tenantGuard le refuse correctement.
- Pour QA SWITAA, Ludovic doit etre logge avec `switaa26@gmail.com`.

AS.11.1A-R2 (cette phase) reapply les memes images sur le runtime DEV pour valider que le tenantGuard fonctionne avec le bon email.

---

## 3. Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| keybuzz-api HEAD | source patch AS.11.1A en place | 3f669057 | OK |
| keybuzz-client HEAD | source patch AS.11.1A en place | dc5e35d | OK |
| keybuzz-infra HEAD | post-AS.11.0.7 audit | 1302121 | OK |
| Sync repos | 0/0 | 0/0 | OK |
| API DEV runtime baseline | v3.5.168 (post-rollback AS.11.1A) | idem | OK |
| Client DEV runtime baseline | v3.5.183 (post-rollback AS.11.1A) | idem | OK |
| KEY-309 tag check v3.5.170 API | TAKEN (deja sur GHCR) | TAKEN | OK |
| KEY-309 tag check v3.5.184 Client | TAKEN (deja sur GHCR) | TAKEN | OK |
| Smoke V1 pre-deploy | PASS | PASS=18 WARN=0 FAIL=0 SKIP=1 | OK |
| PROD images | inchangees | 5 services PROD identiques | OK |

---

## 4. Access model confirmation

Re-confirmation read-only via probe runtime (avant deploy R2) :

| Email | Tenant | Membership user_tenants | Expected result under tenantGuard | Verdict |
|---|---|---|---|---|
| `switaa26@gmail.com` (Ludovic business SWITAA) | switaa-sasu-mnc1x4eq | owner | 200 | confirme runtime |
| `ludo.gonthier@gmail.com` (Ludovic personnel) | switaa-sasu-mnc1x4eq | absent | 403 | confirme runtime |
| `ludo.gonthier@gmail.com` (Ludovic personnel) | ecomlg-001 | owner | 200 (si tenantGuard activait /ecomlg-001 route, ce qui n est pas le cas AS.11.1A) | hors scope AS.11.1A |
| bogus / unknown email | n importe quel tenant | absent | 403 | confirme runtime |

---

## 5. GitOps reapply

Modifications strictes :

| Manifest | Avant | Apres |
|---|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | image v3.5.168-escalation-notifications-dev | image v3.5.170-messages-list-tenantguard-dev |
| `k8s/keybuzz-client-dev/deployment.yaml` | image v3.5.183-ai-draft-effect-order-fix-dev | image v3.5.184-messages-list-bff-dev |

Commit infra : `ed06578` `deploy(dev): reapply messages list tenantGuard with correct SWITAA access model (KEY-304)`.

Apply order :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> `deployment.apps/keybuzz-api configured`
2. `kubectl -n keybuzz-api-dev rollout status` -> `deployment "keybuzz-api" successfully rolled out`
3. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> `deployment.apps/keybuzz-client configured`
4. `kubectl -n keybuzz-client-dev rollout status` -> `deployment "keybuzz-client" successfully rolled out`

Aucun `kubectl set/edit/patch/set env`. Aucun `kubectl scale`. GitOps pur.

Pods state stabilized :
- API DEV : `keybuzz-api-86b476749c-l4gpw` ready, digest sha256:b1d78eb9ec3f... (image v3.5.170)
- Client DEV : `keybuzz-client-6d9fdf58d4-mkf8g` ready, digest sha256:7a6453355c38... (image v3.5.184)

---

## 6. Security validation (6/6 PASS)

| # | Check | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| 1 | no-auth `GET /messages/conversations?tenantId=...` (browser direct) | curl direct https | 401 AUTH_REQUIRED | **401** | PASS |
| 2 | bogus user `GET /messages/conversations` (X-User-Email = inconnu) | kubectl exec curl intra-pod | 403 NOT_MEMBER | **403** | PASS |
| 3 | legit SWITAA owner `switaa26@gmail.com` | kubectl exec curl x-user-email=switaa26 | 200 size>0 | **200 size=1189** | PASS |
| 4 | Ludovic personnel `ludo.gonthier@gmail.com` -> SWITAA (cross-tenant) | kubectl exec curl x-user-email=ludo.gonthier | 403 NOT_MEMBER | **403** | PASS -- cross-tenant denied PROVEN |
| 5 | `/messages/conversations/:id` detail (NOT protected by AS.11.1A) | curl direct https no-auth | 200 (scope strict, detail non migre encore) | **200** | PASS (scope strict respecte) |
| 6 | `/autopilot/draft` route inchangee | kubectl exec curl x-user-email=switaa26 | 200 OK shape | **200 size=18** (no draft current state, structure correcte) | PASS |

**Cross-tenant security PROVEN** : un user de `ecomlg-001` (Ludovic personnel) qui tenterait de fetch `/messages/conversations?tenantId=switaa-sasu-mnc1x4eq` est correctement bloque (403 NOT_MEMBER). C est le but securitaire de KEY-304/KEY-301.

---

## 7. Functional validation

### 7.1 Smoke V1 post-deploy

Commande :
```
SMOKE_API_BASE_URL=https://api-dev.keybuzz.io
SMOKE_BASE_URL=https://client-dev.keybuzz.io
SMOKE_TENANT_ID=switaa-sasu-mnc1x4eq
SMOKE_USER_EMAIL=switaa26@gmail.com           # correct membership SWITAA
SMOKE_EXPECTED_API_IMAGE=...v3.5.170-messages-list-tenantguard-dev
SMOKE_EXPECTED_CLIENT_IMAGE=...v3.5.184-messages-list-bff-dev
SMOKE_CONVERSATION_ID=cmmp0uhhkd695e199f853a0a7   # known SWITAA conv
```

Resultat :
```
PASS=19 WARN=0 FAIL=0 SKIP=0
RESULT=PASS
```

Detail :
- A. Runtime/GitOps : 6/6 PASS
- B. Bundle guard : 5/5 PASS
- C. API DEV read-only : 4/4 PASS dont `/messages/conversations 200 size=1189`
- D. Client/BFF : 3/3 PASS
- E. `/autopilot/draft` probe : PASS (hasDraft=false sur cette conv test, structure correcte)

### 7.2 Logs

| Source | Window | Signal | Count |
|---|---|---|---|
| API DEV | 5 min | 5xx | 0 |
| Client DEV | 5 min | JWT_SESSION_ERROR | 0 |

Aucune erreur post-deploy.

### 7.3 QA Ludovic navigateur

Pour completer la validation UX, Ludovic doit :
1. Ouvrir `client-dev.keybuzz.io` logge avec **`switaa26@gmail.com`** (compte business SWITAA owner). Si actuellement logge avec `ludo.gonthier@gmail.com`, faire logout + login avec switaa26.
2. Verifier l Inbox SWITAA affiche bien la liste des conversations (via BFF route `app/api/messages/conversations/route.ts` qui forward `X-User-Email: switaa26@gmail.com`).
3. Selectionner une conversation AUTOPILOT eligible avec draft existant. Verifier le label **"Brouillon IA"** s affiche AUTOMATIQUEMENT (pas "Suggestion IA"). Cf AS.11.0.6 fix effect order.
4. Verifier le bouton "Valider et envoyer" visible. **NE PAS cliquer**.
5. Tester la negative case : se logger avec `ludo.gonthier@gmail.com` -> tenter d acceder a SWITAA. L Inbox doit etre vide / erreur d acces / 403 visible.

Apres QA OK : KEY-304 -> Done suggere (LIST protected, autres endpoints suivront en AS.11.1c-f).

---

## 8. Rollback if any

Non applique (toutes validations PASS). Documente pour reference rapide si Ludovic decouvrirait un probleme :

```bash
cd /opt/keybuzz/keybuzz-infra
sed -i 's|keybuzz-api:v3.5.170-messages-list-tenantguard-dev|keybuzz-api:v3.5.168-escalation-notifications-dev|g' k8s/keybuzz-api-dev/deployment.yaml
sed -i 's|keybuzz-client:v3.5.184-messages-list-bff-dev|keybuzz-client:v3.5.183-ai-draft-effect-order-fix-dev|g' k8s/keybuzz-client-dev/deployment.yaml
git add k8s/keybuzz-api-dev/deployment.yaml k8s/keybuzz-client-dev/deployment.yaml
git commit -m 'rollback(dev): AS.11.1A-R2 reverted after QA (KEY-304)'
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client
```

Estime : 3 minutes.

---

## 9. PROD unchanged

| Service | PROD image | Statut |
|---|---|---|
| API | v3.5.151-conversation-tone-metric-prod | INCHANGE |
| Client | v3.5.174-conversation-tone-metric-ux-prod | INCHANGE |
| Backend | v1.0.47-cross-env-guard-fix-prod | INCHANGE |
| Website | v0.6.12-linkedin-insight-seo-prod | INCHANGE |
| Admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | INCHANGE |
| Worker | v3.5.165-escalation-flow-prod | INCHANGE |

Aucun manifest PROD touche. Aucun rebuild. Aucun docker push. Aucun kubectl apply sur namespace `-prod`.

---

## 10. Gaps / next endpoint

1. **QA Ludovic navigateur** : doit etre fait avec `switaa26@gmail.com` pour valider Brouillon IA visible (cf section 7.3). HIGH priority avant de passer a AS.11.1c.

2. **AS.11.1c suivant** : `/messages/conversations/:id` GET detail. Pattern identique : ajouter `{ method: 'GET', path: '/messages/conversations/:id' }` au `PROTECTED_ROUTES`. Note : ":id" est un path parameter Fastify ; la fonction `isProtected(method, path)` actuelle compare exact path. Il faudra adapter pour pattern match dynamique OU utiliser `path.startsWith('/messages/conversations/') && method === 'GET'` avec exclusion explicite du list path.

3. **Documentation isInternalUser** : non-impact sur tenantGuard, mais utile a documenter dans la SOT pour eviter confusion future.

4. **Update users with multi-email** : Ludovic-style 2 emails. Pas un bug, c est par design (compte personnel vs business SASU). A documenter en CLAUDE.md / SOT si necessite pour eviter confusion d agent CE future.

5. **PROD promotion AS.1 + AS.11.1g** : reste bloquee jusqu a sequence AS.11.1c-f livree.

---

## 11. Linear text prepared, posted

Postee sur KEY-304 et KEY-301.

### 11.1 KEY-304 commentaire

```
## AS.11.1A-R2 -- reapply DEV reussi avec access model correct

Reapply GitOps DEV sans rebuild ni patch source :
- API DEV v3.5.168 -> v3.5.170-messages-list-tenantguard-dev (digest sha256:b1d78eb9ec3f...)
- Client DEV v3.5.183 -> v3.5.184-messages-list-bff-dev (digest sha256:7a6453355c38...)
- Commit infra ed06578

Security validation 6/6 PASS :
- no-auth /messages/conversations -> 401 OK
- bogus user -> 403 OK
- SWITAA owner switaa26@gmail.com -> 200 size=1189 OK
- Ludovic personnel ludo.gonthier@gmail.com tentative SWITAA -> 403 (cross-tenant denied PROVEN)
- /messages/conversations/:id detail (NOT protected encore) -> 200 (scope strict respecte)
- /autopilot/draft -> 200 (route inchangee)

Smoke V1 post-deploy : PASS=19 WARN=0 FAIL=0 SKIP=0 (toutes sections valides).
Logs DEV : 0 5xx API, 0 JWT_SESSION_ERROR Client.
PROD strictement inchange (5 services).

KEY-304 reste In Review jusqu a QA Ludovic navigateur logge avec switaa26@gmail.com. Apres QA OK -> Done suggere pour LIST endpoint.

AS.11.1c (suivant) : `/messages/conversations/:id` GET detail. Pattern identique mais necessite adaptation `isProtected` pour path parameter (`:id`).

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1A-R2-MESSAGES-LIST-TENANTGUARD-REAPPLY-DEV-01.md
```

### 11.2 KEY-301 commentaire

```
## AS.11.1A-R2 -- LIST endpoint protege DEV

Premier endpoint `/messages/conversations` (GET LIST) protege en DEV par tenantGuard wrap fastify-plugin + PROTECTED_ROUTES strict ['GET /messages/conversations'].

Validation 6/6 PASS : cross-tenant denied proven (Ludovic personnel ne peut plus acceder SWITAA list).

KEY-301 (faille tenantGuard runtime) progressivement comblee endpoint-par-endpoint. AS.11.1A-R2 = 1 endpoint protected. AS.11.1c-f restant : detail, reply, status, assign, sav-status.

Pas de PoC ni de details exploit dans ce comment.

KEY-301 reste Open. Sera close quand AS.11.1g aura proteger toutes les routes /messages.
```

---

### 11.bis Phrase cible finale

AS.11.1A-R2 a reapply GitOps DEV les images AS.11.1A deja construites (API v3.5.170 + Client v3.5.184 digests sha256:b1d78eb9ec3f... et sha256:7a6453355c38...) sans rebuild ni patch source ; rollout API + Client successfully ; security validation 6/6 PASS (no-auth 401, bogus 403, switaa26 owner 200, Ludovic personnel cross-tenant 403 PROVEN denied, detail 200 scope strict, autopilot/draft 200 inchange) ; smoke V1 PASS=19 WARN=0 FAIL=0 SKIP=0 ; logs propres (0 5xx, 0 JWT) ; PROD strictement inchange ; rollback documente pret en 3 min si QA KO ; verdict AS.11.1A-R2 GO MESSAGES LIST SECURITY DEV READY en attente QA Ludovic navigateur logge avec switaa26@gmail.com.

STOP
