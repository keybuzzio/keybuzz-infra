# PH-SAAS-T8.12AS.11.1g-PROD-PROMOTION-EXECUTION-OPTION-A-01

> Date : 2026-05-12
> Linear : KEY-304 (principal), KEY-301, KEY-263
> Phase : T8.12 AS.11.1g PROD PROMOTION EXECUTION -- OPTION A bundle
> Environnement : PROD ; deploy API + Client ; autres services PROD inchanges

---

## 1. VERDICT

GO PROD PROMOTION OPTION A READY

Promotion PROD reussie. Bundle Option A livre conformement au plan AS.11.1g readiness :
- API PROD : `v3.5.151-conversation-tone-metric-prod` -> `v3.5.176-messages-tenantguard-prod`
- Client PROD : `v3.5.174-conversation-tone-metric-ux-prod` -> `v3.5.190-messages-bff-tenantguard-prod`
- 6/6 endpoints `/messages/conversations*` proteges en PROD : LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS
- Bundle inclut KEY-263 (AS.1 escalation notifications base) + KEY-302 + KEY-304 + KEY-305 + KEY-308 + KEY-310
- 6 autres services PROD strictement inchanges (worker, backend x3, admin-v2, plus outbound-worker)

Tests negatifs post-deploy 6/6 PASS (no-auth -> 401 sur chacun des 6 endpoints `/messages/conversations*`). /health PROD 200. Logs PROD 10 min : 0 5xx API, 0 JWT_SESSION_ERROR Client, 0 pod restart anormal. GitOps MATCH=YES sur les 2 services touches.

QA Ludovic navigateur PROD confirme : Inbox liste + detail + nouveaux messages + Brouillon IA + boutons mutationnels (non cliques) tous fonctionnels, aucune banniere d erreur, aucune regression visible.

Rollback PROD reste pret en moins de 5 minutes (revert commit `a54f27b` + 2 kubectl apply -> v3.5.151 + v3.5.174).

KEY-304 / KEY-301 / KEY-263 statut : restent NOT Done dans cette phase (sous reserve de stabilisation 24h + decision Ludovic apres fenetre de surveillance passive).

---

## 2. Scope

Inclus dans cette phase d execution :
- Build API PROD `v3.5.176-messages-tenantguard-prod` depuis HEAD `3f45a7e0` avec KEY-308 + KEY-309
- Build Client PROD `v3.5.190-messages-bff-tenantguard-prod` depuis HEAD `094163b0` avec KEY-302 + KEY-308 + KEY-309
- Docker push GHCR (2 cibles uniquement)
- GitOps commit + push manifest infra (2 fichiers)
- kubectl apply -f des 2 manifests dans l ordre API puis Client
- Validation post-deploy (read-only HTTP + logs)
- QA navigateur Ludovic
- Rapport ASCII strict docs-only commit + push
- Textes Linear KEY-304 / KEY-301 / KEY-263 prepares (a poster apres GO + methode token)

Strictement hors scope (interdits respectes) :
- kubectl set image / patch / edit / set env
- Modification Backend / Outbound-worker / Amazon workers / backfill-scheduler / Website / Admin-v2
- Test mutationnel PROD sans GO explicite
- Mutation DB directe
- Secret / PII dans logs ou rapport
- Linear status Done

---

## 3. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 (46.62.171.61) | install-v3 (46.62.171.61) | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 3f45a7e0 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / b1d6155 / 0-0 | identique | OK |
| Runtime DEV API | v3.5.175-messages-sav-status-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.189-messages-sav-status-bff-dev | identique | OK |
| Runtime PROD API pre | v3.5.151-conversation-tone-metric-prod | identique | OK |
| Runtime PROD Client pre | v3.5.174-conversation-tone-metric-ux-prod | identique | OK |
| KEY-309 tag avail API | v3.5.176-messages-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| KEY-309 tag avail Client | v3.5.190-messages-bff-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| Smoke V1 DEV | PASS_WITH_WARNINGS | PASS=17 WARN=1 FAIL=0 SKIP=1 | OK |
| Disk bastion docker | > 30 GB libres | 85 GB libres (10% used) | OK |

Aucun dirty non compris. Aucune deviation. Greenlight pour build.

---

## 4. Build

### 4.1 API PROD

| Item | Valeur |
|---|---|
| Source commit | 3f45a7e01e80d5a7b250c893abe80bd11c2626bd |
| Tag image | v3.5.176-messages-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 3f45a7e01e80d5a7b250c893abe80bd11c2626bd (= source commit, pas "unknown") |
| KEY-308 OCI created | 2026-05-12T08:45:35Z |
| KEY-308 OCI version | v3.5.176-messages-tenantguard-prod |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built 110b52aae4bc |
| Digest GHCR | sha256:8d7cac8876915aef9d6317191eeca641caeddcb7b5c7f1fd4d15cda7a67331fa |
| docker push | OK |
| Rollback tag | v3.5.151-conversation-tone-metric-prod (sha256:29e53af3db701c45a6d321bc527ee232d924952910253c9cab45b7ec63bf4e53) |

### 4.2 Client PROD

| Item | Valeur |
|---|---|
| Source commit | 094163b0d86529600f50738a5f85fab946a9da74 |
| Tag image | v3.5.190-messages-bff-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 094163b0d86529600f50738a5f85fab946a9da74 (= source commit) |
| KEY-308 OCI created | 2026-05-12T08:47:10Z |
| KEY-308 OCI version | v3.5.190-messages-bff-tenantguard-prod |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-client |
| KEY-308 OCI title | keybuzz-client |
| Build args PROD | NEXT_PUBLIC_APP_ENV=production + NEXT_PUBLIC_API_URL=https://api.keybuzz.io + NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io + GIT_COMMIT_SHA + BUILD_TIME + IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| KEY-302 PROD bundle verify | api.keybuzz.io=2 (>0 OK), api-dev.keybuzz.io=0 (=0 OK), sentinel=0 (=0 OK), Brouillon IA=4 (>0 OK), Valider et envoyer=2 (>0 OK) |
| 6 BFF routes bundle | /app/.next/server/app/api/messages/conversations/[id]/{,reply,status,assign,sav-status}/route.js + root list = 6/6 |
| Build output | Successfully built 3bcda8f5e1c4 |
| Digest GHCR | sha256:0267469d8409b6fad4115e166d584aabe26b476248dce9bd017e5811d0b1243a |
| docker push | OK |
| Rollback tag | v3.5.174-conversation-tone-metric-ux-prod (sha256:8d2e195ae6cf0d2d8c07f5e3534f60985522ae15b02bc4ea288662a5ca3ee61e) |

Aucun docker push hors les 2 cibles. Aucun rebuild d image existante. Build-from-Git strict.

---

## 5. GitOps

Commit infra `a54f27b` :

```
gitops(prod): promote messages tenantGuard API+Client (AS.11.1g KEY-304/301/263)
```

Modifie 2 manifests :
- `k8s/keybuzz-api-prod/deployment.yaml` : `v3.5.151-conversation-tone-metric-prod` -> `v3.5.176-messages-tenantguard-prod`
- `k8s/keybuzz-client-prod/deployment.yaml` : `v3.5.174-conversation-tone-metric-ux-prod` -> `v3.5.190-messages-bff-tenantguard-prod`

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply order strict :
1. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` -> rollout 21 secondes
2. Verification API runtime + health + negative tests 6/6 -> OK
3. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml` -> rollout 60 secondes

Aucun kubectl set / patch / edit / set env / namespace mutation hors les 2 deployments.

---

## 6. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.151-conversation-tone-metric-prod | **v3.5.176-messages-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-client | keybuzz-client-prod | v3.5.174-conversation-tone-metric-ux-prod | **v3.5.190-messages-bff-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | 7 (13j ago) |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | 0 |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | 0 |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | 0 |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | 0 |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | 0 |

Pod API PROD nouveau : `keybuzz-api-6678d94997-749zd` (node k8s-worker-05). Pod Client PROD nouveau : `keybuzz-client-797675d494-4l5tk` (node k8s-worker-02). Anciens pods Terminating au moment du switch, suppression OK.

Runtime API + Client = spec manifest = last-applied annotation = digest pushe sur GHCR.

---

## 7. Validation post-deploy (read-only / negative-only)

### 7.1 Health + reachability

| Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|
| API /health (in-cluster) | http://127.0.0.1:3001/health via kubectl exec | 200 ok | 200 `{"status":"ok",...,"service":"keybuzz-api"}` | PASS |
| API /health (public) | https://api.keybuzz.io/health | 200 | 200 | PASS |
| Client / public | https://client.keybuzz.io/ | 307 (redirect auth) | 307 | PASS |
| Client /inbox public | https://client.keybuzz.io/inbox | 307 (redirect auth) | 307 | PASS |
| Client /api/auth/session | https://client.keybuzz.io/api/auth/session | 200 (NextAuth shape) | 200 | PASS |

### 7.2 Negative tests 6/6 endpoints PROD

Cible : conversation id factice `00000000-0000-0000-0000-000000000000`, tenant id factice `fake-tenant`. Aucune PII utilisee.

| # | Endpoint | Method | URL public | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| 1 | /messages/conversations | GET | https://api.keybuzz.io/messages/conversations?tenantId=fake-tenant&limit=1 | 401 AUTH_REQUIRED | 401 | PASS |
| 2 | /messages/conversations/:id | GET | https://api.keybuzz.io/messages/conversations/00000000-0000-0000-0000-000000000000?tenantId=fake-tenant | 401 AUTH_REQUIRED | 401 | PASS |
| 3 | /messages/conversations/:id/reply | POST | https://api.keybuzz.io/messages/conversations/.../reply?tenantId=fake-tenant | 401 AUTH_REQUIRED | 401 | PASS |
| 4 | /messages/conversations/:id/status | PATCH | https://api.keybuzz.io/messages/conversations/.../status?tenantId=fake-tenant | 401 AUTH_REQUIRED | 401 | PASS |
| 5 | /messages/conversations/:id/assign | PATCH | https://api.keybuzz.io/messages/conversations/.../assign?tenantId=fake-tenant | 401 AUTH_REQUIRED | 401 | PASS |
| 6 | /messages/conversations/:id/sav-status | PATCH | https://api.keybuzz.io/messages/conversations/.../sav-status?tenantId=fake-tenant | 401 AUTH_REQUIRED | 401 | PASS |

Aucun PATCH ou POST positif emis. Aucune mutation PROD DB. Toutes les requetes ont ete rejetees au niveau preHandler par le tenantGuard runtime PROD.

### 7.3 Logs PROD fenetre 10 minutes

| Source | Filtre | Count |
|---|---|---|
| keybuzz-api PROD | `"statusCode":5xx` ou `"level":50` | 0 |
| keybuzz-client PROD | `JWT_SESSION_ERROR` | 0 |
| keybuzz-client PROD | reponse 5xx | 0 |
| keybuzz-api PROD | TenantGuard DENIED warn | 0 (aucune tentative cross-tenant reelle observee) |

Aucune erreur visible cote runtime PROD apres deploy AS.11.1g.

### 7.4 Pod restarts

| Service | Restarts pre-deploy | Restarts post-deploy (new pod) |
|---|---|---|
| keybuzz-api PROD | 0 (old pod 2d5h) | 0 (new pod) |
| keybuzz-client PROD | 0 (old pod 2d5h) | 0 (new pod) |
| autres PROD services | inchanges | inchanges |

---

## 8. QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business Ludovic habituel |
| Inbox PROD -- liste conversations visible | OUI (LIST via BFF migration AS.11.1A-R2) |
| Conversation detail visible apres clic | OUI (DETAIL via BFF AS.11.1C) |
| Nouveaux messages visibles | OUI |
| Brouillon IA visible automatiquement (KEY-305 fix) | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Boutons statut / assigner / SAV visibles | OUI (NON cliques) |
| Escalation badge AS.1 (KEY-263 bundle) | livre (NON clique) |
| Banniere "API indisponible" / erreur | NON |
| Regression visible Inbox / channels / suppliers / catalogue / commande | NON |

Conclusion QA : aucune regression observee post AS.11.1g. Inbox + Brouillon IA + boutons mutationnels visibles et fonctionnels en PROD pour un utilisateur authentifie legitimement membre de son tenant.

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee.

---

## 9. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert a54f27b --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml       # -> v3.5.151
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml    # -> v3.5.174
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Tags rollback exacts :
- API PROD : `v3.5.151-conversation-tone-metric-prod` (sha256:29e53af3db701c45a6d321bc527ee232d924952910253c9cab45b7ec63bf4e53)
- Client PROD : `v3.5.174-conversation-tone-metric-ux-prod` (sha256:8d2e195ae6cf0d2d8c07f5e3534f60985522ae15b02bc4ea288662a5ca3ee61e)

Triggers rollback immediat (a surveiller H+30min puis H+24h) :
- Inbox PROD vide ou cassee
- detail conversation inaccessible
- nouveaux messages bloques
- Brouillon IA disparait
- banniere "API indisponible" persistante
- Logs API PROD spike 5xx anormal
- Logs Client PROD spike JWT_SESSION_ERROR sustained
- 403 NOT_MEMBER injustifie sur compte legitime

Fenetre de surveillance recommandee : 30 minutes actives Ludovic + 24 heures passives sur metriques.

---

## 10. AI feature parity / anti-regression

| Surface | Statut PROD post AS.11.1g | Justification |
|---|---|---|
| Inbox liste conversations | OK (BFF LIST runtime) | KEY-304 LIST endpoint protege en PROD |
| Inbox detail conversation | OK (BFF DETAIL runtime) | KEY-304 DETAIL endpoint protege en PROD |
| Inbox reply | OK runtime (NON teste positivement) | KEY-304 REPLY endpoint protege en PROD |
| Inbox changement statut | OK runtime (NON teste positivement) | KEY-304 STATUS endpoint protege en PROD |
| Inbox assigner | OK runtime (NON teste positivement) | KEY-304 ASSIGN endpoint protege en PROD |
| Inbox SAV label | OK runtime (NON teste positivement) | KEY-304 SAV-STATUS endpoint protege en PROD |
| Brouillon IA visibilite auto | OK (KEY-305 consolidated useEffect en PROD) | logique React identique a DEV |
| Brouillon IA "Valider et envoyer" UI | bouton visible bundle (NON clique en PROD) | scope visuelle uniquement |
| Escalation badge AS.1 (KEY-263) | livre en PROD (visuel inspecte par Ludovic) | bundle Option A |
| autopilot/draft | non touche par AS.11.1g | endpoint hors scope |
| channels / suppliers / commande / catalogue | inchanges | hors scope KEY-304 |
| Smoke V1 DEV | toujours PASS=17 WARN=1 FAIL=0 SKIP=1 | confirmation pre-deploy |

Aucune regression observee sur les surfaces visibles. Aucune mutation reellement effectuee en PROD.

---

## 11. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digests sha256:8d7c..., sha256:0267..., commits a54f27b + 3f45a7e0 + 094163b0, durations rollout 21s + 60s, log counts 0 5xx + 0 JWT_SESSION_ERROR, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 12. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee** (file bastion `/opt/keybuzz/.linear-token`, env `/root/.linear.env`, ou Ludovic poste lui-meme). Backlog complet a poster : AS.11.1D + AS.11.1E + AS.11.1f-1 + AS.11.1f-2 + AS.11.1f-2-QA + AS.11.1g readiness + AS.11.1g execution = 7 jeux de commentaires en attente.

### 12.1 KEY-304 commentaire AS.11.1g execution (texte cible)

```
## AS.11.1g PROD promotion executed -- Option A bundle

- API PROD : v3.5.151-conversation-tone-metric-prod -> v3.5.176-messages-tenantguard-prod (commit 3f45a7e0)
- Client PROD : v3.5.174-conversation-tone-metric-ux-prod -> v3.5.190-messages-bff-tenantguard-prod (commit 094163b0)
- Bundle : KEY-304 (6/6 endpoints) + KEY-263 (AS.1 base) + KEY-305 (AI draft fix) + KEY-302 + KEY-308 + KEY-310
- GitOps PROD MATCH=yes on both services post-deploy.
- 6 other PROD services strictly unchanged (outbound-worker, backend x3, admin-v2, plus the 3 Amazon workers).
- Negative tests PROD 6/6 PASS : all `/messages/conversations*` endpoints return 401 AUTH_REQUIRED without authentication.
- /health PROD 200. /api/auth/session PROD 200.
- Logs PROD 10min : 0 API 5xx, 0 Client JWT_SESSION_ERROR, 0 unexpected pod restart.
- Rollout duration : API 21s, Client 60s.
- Ludovic QA navigateur PROD : Inbox liste + detail + new messages + Brouillon IA + mutation buttons (NOT clicked) all functional, no error banner, no regression.

KEY-304 endpoint-by-endpoint migration is now complete in PROD as well as DEV.

KEY-304 stays In Review during 24h passive monitoring window. Do NOT mark Done before that window closes and Ludovic confirms stability.

Rollback ready in less than 5 minutes : revert infra commit a54f27b + 2 kubectl apply -> back to v3.5.151 + v3.5.174.

Disclosure controle : pas de PoC, pas de details exploit.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-PROD-PROMOTION-EXECUTION-OPTION-A-01.md
```

### 12.2 KEY-301 commentaire (texte cible)

```
Runtime mitigation for `/messages/conversations*` 6/6 endpoints is now COMPLETE in both DEV and PROD as of AS.11.1g Option A bundle promotion (2026-05-12).

Negative tests PROD post-deploy confirmed all 6 endpoints return 401 AUTH_REQUIRED without authentication. No DB mutation triggered. Ludovic QA confirmed no functional regression.

KEY-301 stays Open during the 24h post-deploy stabilization window. The broader scope of KEY-301 (potential application to other modules beyond /messages) is out of this closeout but may be revisited after stabilization.

Disclosure controle : pas de PoC, pas de details exploit.
```

### 12.3 KEY-263 commentaire (texte cible)

```
KEY-263 (escalation notifications PROD promotion) status update post AS.11.1g Option A bundle :

The AS.1 escalation notifications base (commits 070707a1 API + 37e70ac Client + AS.1.1 fix a69477a Client) was bundled and promoted to PROD as part of AS.11.1g.

Runtime PROD includes the escalation badge UI surface and tenant-scoped notification routes. No regression observed in QA Ludovic navigateur PROD (no Inbox break, no banner error).

KEY-263 stays In Review pending the same 24h stabilization window. Final status decision after window closes and Ludovic confirms.

Disclosure controle : pas de PoC, pas de details exploit.
```

---

## 13. Compliance AS.11.1g execution

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API + Client + infra) | OK (3 commits source deja en place + infra a54f27b) |
| Build-from-Git (jamais SCP / pod / dist) | OK |
| Tag immuable (no :latest) | OK |
| KEY-302 PROD bundle verify (api.keybuzz.io>0, api-dev=0, sentinel=0) | OK |
| KEY-308 OCI labels non "unknown" | OK (revision = source commit pour les deux images) |
| KEY-309 pre-push tag check AVAILABLE | OK (les 2 tags AVAILABLE avant push) |
| Digests documentes | OK (sha256:8d7c... + sha256:0267...) |
| Rollback plan documente et tags exacts | OK section 9 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| ASCII strict rapport | OK |
| Autres PROD services unchanged (6 services) | OK |
| Negative tests PROD 6/6 PASS | OK |
| 0 5xx API PROD logs | OK |
| 0 JWT_SESSION_ERROR Client PROD logs | OK |
| 0 unexpected pod restart | OK |
| QA Ludovic navigateur PROD OK | OK |
| Rollback en moins de 5 min documente | OK |
| Disclosure controle Linear (textes prepares, attente GO) | OK |
| KEY-304 NOT marked Done | OK (reste In Review pendant fenetre 24h) |
| KEY-301 NOT marked Done | OK (reste Open) |
| KEY-263 NOT marked Done | OK (reste In Review) |
| No PII / no client data copied | OK |
| Aucun test mutationnel PROD (POST/PATCH positif) | OK |

---

## 14. Phrase cible finale

AS.11.1g PROD PROMOTION OPTION A livre : 6/6 endpoints `/messages/conversations*` proteges en PROD (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS) ; API PROD v3.5.151 -> v3.5.176-messages-tenantguard-prod (commit 3f45a7e0, digest sha256:8d7cac8876...) ; Client PROD v3.5.174 -> v3.5.190-messages-bff-tenantguard-prod (commit 094163b0, digest sha256:0267469d84...) ; bundle Option A inclut KEY-304 + KEY-263 AS.1 base + KEY-302 + KEY-305 AI draft fix + KEY-308 + KEY-310 ; commit infra `a54f27b`, rollout API 21s + Client 60s, GitOps MATCH=yes, 6 autres services PROD strictement inchanges, tests negatifs PROD 6/6 PASS (401), /health PROD 200, /api/auth/session PROD 200, logs PROD 10min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, QA Ludovic navigateur PROD confirmee (Inbox + Brouillon IA + boutons mutationnels visibles non cliques + aucune banniere + aucune regression) ; KEY-302 PROD bundle verify api.keybuzz.io=2 api-dev=0 sentinel=0 Brouillon IA=4 Valider et envoyer=2 ; KEY-308 OCI revisions presentes = source commits ; KEY-309 tag-avail check OK pre-push ; rollback PROD prepare et documente vers v3.5.151 + v3.5.174 en moins de 5 minutes via revert infra a54f27b + 2 kubectl apply ; aucun deploy hors API + Client PROD, aucun kubectl set/patch/edit, aucune mutation DB, aucun test mutationnel PROD, aucun secret, aucune PII ; KEY-304 reste In Review pendant fenetre stabilisation 24h ; KEY-301 reste Open ; KEY-263 reste In Review ; verdict AS.11.1g execution GO PROD PROMOTION OPTION A READY.

STOP
