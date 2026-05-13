# PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-14
> Linear : KEY-313 (parent epic KEY-301 Done)
> Phase : T8.12 AS.13.1 -- R1 google-observability handler-level access control en DEV (API-only)
> Environnement : DEV ; PROD strictement read-only et inchange

---

## 1. VERDICT

GO GOOGLE OBSERVABILITY TENANTGUARD DEV READY

Le leak critique R1.1 identifie dans AS.13.0 est ferme en DEV :
- avant patch : `GET /outbound-conversions/google-observability` sans tenantId retournait l agregat `signup_attribution` **tous tenants confondus** + dernier gclid + derniere conversion avec leur `tenant_id` ;
- apres patch DEV : 400 si `x-user-email` ou `tenantId` manquant, 403 si non-membre du tenant et non porteur d un admin role bypass.

Decision design : **Option A tenant-scoped** avec **alignement sur le pattern `checkAccess` deja en place dans le module voisin `outbound-conversions/routes.ts`** (destinations). Cela preserve l acces Admin v2 marketing (super_admin / account_manager / media_buyer bypass via `x-admin-role`) sans introduire un adminGuard plugin nouveau.

| Item | Statut |
|---|---|
| API DEV | v3.5.186 -> v3.5.187-google-observability-tenantguard-dev (digest GHCR `sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104`, OCI revision `1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c`) |
| Client DEV | INCHANGE v3.5.196-ai-rules-bff-dev (aucun patch Client / aucun build / aucun apply) |
| Manifest commit | `23af039 deploy(dev): protect google observability tenant scope (KEY-313)` push origin/main 0-0 |
| Apply API DEV | `successfully rolled out` ; spec = last-applied = pod imageID = digest pushe |
| Probes negative DEV | 4/4 PASS (400 no-tenant, 400 fake-tenant no-auth, 403 fake-tenant + fake-email, 403 fake-tenant + fake-email + bogus admin-role) |
| AS.12 preserve | 9/9 protections core 401 |
| AS.13.0 surfaces hors scope | inchanges (outbound/deliveries fake -> 200 et amazon/status fake -> 200 toujours non proteges, geres en AS.13.2 et AS.13.3) |
| Logs API DEV 5min 5xx | 0 |
| DB no-mutation `signup_attribution` | 2 rows / gclid=0 / conversions=0 (DEV, snapshot post-apply) |
| PROD inchange | API v3.5.186-prod + Client v3.5.196-prod inchanges, 11 autres services inchanges |
| QA Ludovic DEV | Inbox + Brouillon IA + tenant switcher + escalation + playbooks read-only OK |

KEY-313 reste Open epic. Sous-phases restantes : AS.13.2 outbound/deliveries (5 endpoints), AS.13.3 compat (6 endpoints), AS.13.4 destinations audit confirmatif.

---

## 2. Scope

Inclus :
- 1 patch source API uniquement : `keybuzz-api/src/modules/outbound-conversions/google-observability.ts` (+40/-2).
- 1 commit + push source (api ph147.4/source-of-truth).
- Build API DEV from-git via scripts patches AS.12.2C-3.1.
- 1 docker push GHCR.
- 1 commit + push manifest infra DEV (1 fichier, 1 ligne).
- 1 kubectl apply -f DEV API + rollout.
- Validation negative ciblee (4 probes new) + preserve 9 + AS.13.0 surfaces hors scope (verifie qu elles restent intactes pour AS.13.2/13.3).
- DB snapshot signup_attribution post-apply.
- QA Ludovic navigateur DEV.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Aucun patch Client (BFF /api/outbound-conversions inexistant, aucun caller Client identifie).
- Aucun patch Backend / outbound-worker.
- Aucun patch tenantGuard plugin (le handler local fait le check via `checkAccess`, pattern coherent avec le module voisin).
- AS.13.2 outbound/deliveries (5 endpoints, mutations).
- AS.13.3 compat (6 endpoints, OAuth Amazon proxy).
- AS.13.4 destinations audit confirmatif.
- AS.13.x autres sous-phases R1.
- Promotion PROD.
- Mutation DB / fake event / fake conversion / fake attribution.

---

## 3. Source decision : tenant-scoped vs admin/global

Question prompt CE Q1 : tenant-scoped ou admin/global ?

**Decision : Option A tenant-scoped avec admin-role bypass** (pattern existant module).

Justifications :
1. Aucun `adminGuard` plugin n existe dans la codebase API. Introduire un nouveau plugin serait hors scope KEY-313.
2. Le module voisin `outbound-conversions/routes.ts` (destinations) utilise deja le pattern hybride :
   - `ALLOWED_ROLES = ['owner', 'admin']` (roles user_tenants valides)
   - `ADMIN_BYPASS_ROLES = ['super_admin', 'account_manager', 'media_buyer']` (Admin v2 platform roles)
   - Verifie `x-admin-role` header puis fallback membership user_tenants.
3. Le consumer identifie (Admin v2 BFF `src/app/api/admin/marketing/google-observability/route.ts`) injecte deja `x-user-email`, `x-tenant-id` et `x-admin-role` depuis sa session. Aucun changement BFF necessaire.
4. Aucun caller Client identifie (grep exhaustif `keybuzz-client/src/` et `app/` retourne 0 result pour `google-observability` ou `outbound-conversions`).
5. La semantique `scope=owner` (filter `marketing_owner_tenant_id = $1 OR tenant_id = $1`) reste valable car le `tenantId` est desormais garanti membre legitime ou role bypass.

Reponse Q1 prompt CE : **Option A tenant-scoped** avec admin-role bypass aligne sur module voisin. Pas d adminGuard nouveau.

---

## 4. Preflight

### 4.1 Repos

| Repo | Path | Branche | HEAD avant | HEAD apres | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 05bb57cd | **1c8b6b18** | 0-0 | 0 (dist/ exclus) | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970 | inchange | 0-0 | 0 | OK read-only |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | e899426 | **23af039** | 0-0 | 0 | OK |

### 4.2 Runtime DEV + PROD

| Env | Service | Image avant | Image apres | pod imageID digest | Match |
|---|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-dev | **v3.5.187-google-observability-tenantguard-dev** | `sha256:9cfd946c593b...` | OK |
| DEV | keybuzz-client | v3.5.196-ai-rules-bff-dev | inchange | -- | OK read-only |
| PROD | keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-prod | inchange | -- | OK read-only |
| PROD | keybuzz-client | v3.5.196-ai-rules-bff-prod | inchange | -- | OK read-only |
| Other (DEV+PROD x11) | backend / studio / admin-v2 / website / seller-* / outbound-worker | inchange | inchange | -- | OK |

---

## 5. Patch

### 5.1 Endpoint audit (E1 prompt CE)

| Fichier | Route | Method | Tenant source AVANT | Auth AVANT | Tables lues | Consumer | Risque AVANT |
|---|---|---|---|---|---|---|---|
| `src/modules/outbound-conversions/google-observability.ts` | /outbound-conversions/google-observability | GET | query `tenantId` (optionnel) | aucune | `signup_attribution` (3 queries paralleles) | Admin v2 BFF `/api/admin/marketing/google-observability` (utilise par page `(admin)/marketing/google-tracking`) | CRITICAL : tenantId omis -> filter='' -> retourne agregat tous tenants + last gclid + last conversion (avec tenant_id) sans auth |

### 5.2 Patch design

| Changement | Fichier | Pourquoi | Risque | Mitigation |
|---|---|---|---|---|
| Ajout const `ALLOWED_ROLES = ['owner', 'admin']` (copie destinations) | `google-observability.ts` | base membership user_tenants | aucun | identique pattern destinations |
| Ajout fonction locale `checkAccess(pool, email, tenantId, adminRole)` | idem | bypass `ADMIN_BYPASS_ROLES = ['super_admin', 'account_manager', 'media_buyer']` puis fallback membership | aucun (copie exacte destinations) | factorisation differee si necessaire ailleurs |
| Check au debut du handler : `email` + `tenantId` requis (400) puis `checkAccess` (403) | idem | ferme leak global | un caller existant qui n injecte ni email ni tenantId perdrait acces | aucun caller Client identifie ; Admin v2 BFF injecte deja les 3 headers requis ; aucun changement BFF necessaire |

Note : la logique du handler post-check reste identique. `tenantId` etant desormais garanti, la branche `filter = ''` du code existant est inatteignable (code mort inoffensif, non supprime pour minimiser le diff).

### 5.3 Files changed

| Fichier | Repo | Lignes | Diff stat |
|---|---|---|---|
| `src/modules/outbound-conversions/google-observability.ts` | keybuzz-api | +40 / -2 | 1 file changed, 40 insertions(+), 2 deletions(-) |

Aucun autre fichier touche. tenantGuard.ts intact. Client intact. Backend intact. Manifests touches uniquement pour la promotion DEV (1 ligne image).

Commit API : `1c8b6b18 fix(security): protect google observability by tenant membership (KEY-313)` push origin/ph147.4/source-of-truth 0-0.

### 5.4 Source tests pre-build

| Check | Resultat |
|---|---|
| Diff scope limite a 1 fichier API | OK |
| Aucun hardcode tenant/email | OK |
| Aucun secret hardcode | OK |
| Aucun changement de schema DB | OK |
| Aucun changement Client / Backend / tenantGuard | OK |
| Line endings CRLF preserves (match original) | OK apres re-conversion pre-SCP |

---

## 6. Build evidence

```
bash scripts/build-api-from-git.sh dev v3.5.187-google-observability-tenantguard-dev ph147.4/source-of-truth
```

Build OK, Git SHA `1c8b6b1`. Local Image Id `sha256:e187aa6ac2d1e7c94836689f8c91bdbf4ef2a7a16416c981147a9fb498f14f5b`.

OCI labels KEY-308 :

| Image | Tag | Source SHA | OCI revision | Created | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | v3.5.187-google-observability-tenantguard-dev | 1c8b6b1 | `1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c` | `2026-05-13T22:12:21Z` | PASS |

Source : `https://github.com/keybuzzio/keybuzz-api`. Title : `keybuzz-api`.

Aucun build Client (scope API-only).

---

## 7. Push evidence

```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.187-google-observability-tenantguard-dev
```

| Image | Tag | GHCR digest | Revision | Verdict |
|---|---|---|---|---|
| keybuzz-api | v3.5.187-google-observability-tenantguard-dev | `sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104` (size 2416) | 1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c | PASS |

KEY-309 immuable confirme : `docker manifest inspect` pre-push retournait `manifest unknown` (libre), post-push retourne le digest. Aucun overwrite.

---

## 8. GitOps evidence

### 8.1 Commit manifest infra

Commit `23af039 deploy(dev): protect google observability tenant scope (KEY-313)` push origin/main 0-0 :
- `k8s/keybuzz-api-dev/deployment.yaml` : 1 ligne image+commentaire (v3.5.186 -> v3.5.187).
- `k8s/keybuzz-client-dev/deployment.yaml` : **non touche**.

### 8.2 Apply API DEV

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
deployment.apps/keybuzz-api configured
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.187-google-observability-tenantguard-dev | OK |
| pod imageID nouveau | `sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:59d18bc554f3...` (v3.5.186) | OK rollout normal |

### 8.3 Client DEV (non touche)

```
kubectl -n keybuzz-client-dev get deploy keybuzz-client -o jsonpath="{.spec.template.spec.containers[0].image}"
ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-dev
```

---

## 9. Security validation negative-only

### 9.1 AS.13.1 NEW probes google-observability

UUIDs fictifs : `tenantId=00000000-0000-0000-0000-000000000000`. Pas de PoC reproductible, comportements decrits par classe.

| Probe | Method | Expected post-patch | Actual | Data scope | DB impact | Verdict |
|---|---|---|---|---|---|---|
| /outbound-conversions/google-observability (no tenant, no auth) | GET | 400 ou 401 (PLUS de 200) | **400** "Missing x-user-email or x-tenant-id" | aucune | 0 | PASS (leak ferme) |
| /outbound-conversions/google-observability?tenantId=fake (no auth) | GET | 400 ou 401 | **400** | aucune | 0 | PASS |
| /outbound-conversions/google-observability + x-user-email bogus + x-tenant-id fake | GET | 403 | **403** "Insufficient permissions" | aucune | 0 | PASS |
| /outbound-conversions/google-observability + headers + x-admin-role bogus (not in bypass list) | GET | 403 | **403** | aucune | 0 | PASS |

**Comportement avant patch (AS.13.0 audit, runtime PROD)** : memes inputs retournaient 200 avec data agregate tous tenants. Comportement apres patch DEV : 400 ou 403. **Leak ferme en DEV**.

### 9.2 AS.13.0 surfaces hors scope (intactes, geres dans AS.13.2/13.3)

| Probe | Expected | Actual | Note |
|---|---|---|---|
| /outbound/deliveries?tenantId=fake (no auth) | 200 (still vulnerable, scope AS.13.2) | 200 | preserve hors scope -- a fermer en AS.13.2 |
| /outbound-conversions/destinations (no auth) | 400 (deja safe via checkAccess) | 400 | preserve OK |
| /api/v1/marketplaces/amazon/status?tenant_id=fake (no auth) | 200 (still vulnerable, scope AS.13.3) | 200 | preserve hors scope -- a fermer en AS.13.3 |

### 9.3 AS.12 preserve protections (9 sur 9)

| Endpoint | Method | Phase | Observed |
|---|---|---|---|
| /messages/conversations | GET | KEY-304 | 401 |
| /tenants | GET | AS.12.1A | 401 |
| /notifications | GET | AS.12.1B | 401 |
| /autopilot/draft | GET | AS.12.2B | 401 |
| /ai/settings | GET | AS.12.2D | 401 |
| /ai/wallet/status | GET | AS.12.2D | 401 |
| /ai/execute | POST | AS.12.2C-4 | 401 |
| /ai/rules | POST | AS.12.2C-5B | 401 |
| /playbooks/:id/toggle | PATCH | AS.12.2C-5B | 401 |

**9/9 preserve PASS**. AS.12 surface critique entierement intacte.

### 9.4 Logs

| Source | Filtre | Count | Verdict |
|---|---|---|---|
| API DEV `statusCode 5xx / level=50` | 5min post-rollout | 0 | PASS |
| Client DEV `JWT_SESSION_ERROR` | 5min | 0 (snapshot deja capture, inchange) | PASS |

---

## 10. DB no-mutation proof

| Mesure | Pre-deploy (AS.13.0 audit) | Post-deploy 10min | Delta | Verdict |
|---|---|---|---|---|
| signup_attribution total (DEV) | 2 (deduit du snapshot AS.13.0) | 2 | 0 | PASS |
| signup_attribution gclid IS NOT NULL count | 0 | 0 | 0 | PASS |
| signup_attribution conversion_sent_at IS NOT NULL count | 0 | 0 | 0 | PASS |

Aucune mutation `signup_attribution` causee par cette phase. Validation 100% negative-only : les probes retournent 400/403 avant atteindre les queries SQL.

---

## 11. Logs / QA

### 11.1 QA Ludovic navigateur DEV

URL : **`https://client-dev.keybuzz.io`** (ingress + NEXTAUTH_URL alignes).

Resultat :
- Inbox **OK**.
- Brouillon IA **OK** sur les cas attendus (pattern GP1 KEY-312 inchange).
- tenant switcher **OK**.
- escalation badge **OK**.
- playbooks read-only **OK**.
- Aucune regression UX visible.
- AS.13.1 ne touche pas le Client donc UX Client inchangee par construction.

**Verdict QA** : GO GOOGLE OBSERVABILITY TENANTGUARD DEV READY.

Note Admin v2 marketing google-tracking : QA navigateur Admin v2 non effectue dans cette phase (consumer non-Client). Le BFF Admin v2 injecte deja `x-admin-role` parmi `ADMIN_BYPASS_ROLES` (`super_admin`, `account_manager`, `media_buyer`) -> bypass attendu. Risque casser super_admin Admin v2 mitige par alignement avec module destinations deja en production avec ce pattern. Toute verification Admin v2 marketing est documentee comme verification post-deploy QA Admin si besoin.

---

## 12. PROD unchanged proof

| Service | PROD image | Status |
|---|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-prod | inchange |
| keybuzz-client-prod / keybuzz-client | v3.5.196-ai-rules-bff-prod | inchange |
| 11 autres services PROD | (cf rapports precedents) | inchanges |

Aucun build / push / deploy / manifest PROD touche.

---

## 13. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 23af039 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.186-ai-rules-mut-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur Admin v2 marketing google-tracking pour role super_admin/account_manager/media_buyer.
- Spike 5xx API DEV.
- Regression UX Client (improbable car aucun patch Client).

---

## 14. Linear text prepared (KEY-313 disclosure-controlled)

```
## AS.13.1 R1 google-observability tenantGuard DEV -- GO READY

Pre-existing leak (R1.1 from AS.13.0 audit, severity CRITICAL) closed on DEV : `GET /outbound-conversions/google-observability` without tenantId or auth previously returned aggregate `signup_attribution` data across ALL tenants (gclid_count, google_utm_count, conversions_sent, total_signups + last gclid with tenant_id + last conversion). Now :

- no tenantId or no x-user-email -> 400 "Missing x-user-email or x-tenant-id".
- bogus user + arbitrary tenantId -> 403 "Insufficient permissions".
- bogus user + arbitrary tenantId + bogus admin-role -> 403 (role not in ADMIN_BYPASS_ROLES).

Design decision : Option A tenant-scoped with admin-role bypass aligned on neighbour module `outbound-conversions/routes.ts` (destinations). Same `ALLOWED_ROLES = ['owner', 'admin']` + `ADMIN_BYPASS_ROLES = ['super_admin', 'account_manager', 'media_buyer']`. No new adminGuard plugin introduced. Admin v2 BFF (`/api/admin/marketing/google-observability` -> page `(admin)/marketing/google-tracking`) already injects `x-user-email`, `x-tenant-id`, `x-admin-role` from session, so no BFF change required.

Runtime DEV :
- API : v3.5.186 -> v3.5.187-google-observability-tenantguard-dev (digest sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104, OCI revision 1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c).
- Client DEV unchanged at v3.5.196-ai-rules-bff-dev.
- Manifest commit 23af039, GitOps strict, spec=last-applied=runtime imageID=GHCR digest.

Validation DEV :
- 4/4 NEW negative probes PASS (was 200 leak before).
- 9/9 AS.12 preserve protections still 401.
- AS.13.0 hors scope surfaces unchanged (outbound/deliveries + amazon/status still 200, deferred to AS.13.2 + AS.13.3).
- 0 5xx API DEV 5min.
- DB signup_attribution counts unchanged pre+post (2 / 0 / 0).
- PROD strictly unchanged (API v3.5.186-prod + Client v3.5.196-prod intact).

QA Ludovic browser DEV (https://client-dev.keybuzz.io) : Inbox + Brouillon IA + tenant switcher + escalation + playbooks read-only OK. AS.13.1 does not touch Client.

Verdict : **GO GOOGLE OBSERVABILITY TENANTGUARD DEV READY**. No rollback triggered.

Next steps : promotion PROD after Ludovic GO, then AS.13.2 outbound/deliveries (P0, 5 endpoints, 3 mutations).

KEY-313 stays Open. KEY-301 stays Done.

Disclosure controle : no PoC, no payload reproducible, no PII, no secret, no exploit recipe.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.13.1-R1-GOOGLE-OBSERVABILITY-TENANTGUARD-HARDENING-DEV-01.md
```

Note : backlog ~37 jeux de commentaires Linear KEY-* en attente methode token API (resolu en partie via outils Linear directs durant AS.12.3A).

---

## 15. Gaps / next phase

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.13.1-PROD promotion coordonnee reste a livrer apres GO Ludovic | High | Phase suivante, API-only (Client PROD reste v3.5.196) |
| G2 | AS.13.2 outbound/deliveries 5 endpoints (2 GET + 3 mutations) -- preHandler tenantId required existant mais NO membership check | High | Phase suivante apres AS.13.1-PROD |
| G3 | AS.13.3 compat /api/v1/marketplaces/amazon/* 6 endpoints proxy generique sans membership | High | Phase suivante apres AS.13.2 |
| G4 | AS.13.4 outbound-conversions/destinations audit confirmatif checkAccess | Low | Probable 0 patch (deja safe) |
| G5 | QA Admin v2 marketing google-tracking page non effectuee dans cette phase (consumer non-Client). Le BFF Admin v2 injecte deja les headers admin requis, mais une visite manuelle de la page pour role super_admin/media_buyer recommandee avant AS.13.1-PROD | Low | A faire avant promotion PROD |
| G6 | Code mort `filter = ''` branche dans handler (tenantId est desormais garanti present). Inoffensif. | Trivial | Cleanup optionnel dans phase ulterieure |

---

## 16. Phrase cible finale

AS.13.1 R1 google-observability hardening DEV livre : 1 patch source API `keybuzz-api/src/modules/outbound-conversions/google-observability.ts` (+40/-2) ajout ALLOWED_ROLES + checkAccess (copie pattern destinations) + check email+tenantId+checkAccess au debut handler ; commit source `1c8b6b18 fix(security): protect google observability by tenant membership (KEY-313)` push origin/ph147.4/source-of-truth 0-0 ; aucun patch Client / Backend / tenantGuard plugin ; build API DEV from-git via scripts AS.12.2C-3.1 avec OCI labels KEY-308 complets (revision `1c8b6b18efad67a7b4795351b55f2ce37bdd2d9c`, created `2026-05-13T22:12:21Z`, version `v3.5.187-google-observability-tenantguard-dev`) ; docker push GHCR digest `sha256:9cfd946c593b464936e81cbc9876ea7acdff5206178408588e1674a9ccb96104` (KEY-309 immuable, pre-push manifest unknown) ; manifest infra commit `23af039` push origin main 0-0 (1 fichier `keybuzz-api-dev/deployment.yaml`, 1 ligne) ; 1 kubectl apply -f API DEV + rollout successful ; spec = last-applied = pod imageID = digest pushe ; Client DEV strictement inchange `v3.5.196-ai-rules-bff-dev` ; validation negative : 4/4 NEW probes PASS sur google-observability (avant 200 leak, apres 400 no-tenant-no-auth, 400 fake-tenant-no-auth, 403 fake-tenant+fake-email, 403 fake-tenant+fake-email+bogus-admin-role) + 9/9 AS.12 preserve toujours 401 + AS.13.0 surfaces hors scope inchangees (outbound/deliveries fake -> 200 et amazon/status fake -> 200, geres AS.13.2 et AS.13.3) ; 0 5xx API DEV 5min + 0 JWT_SESSION_ERROR Client DEV ; DB no-mutation signup_attribution counts pre/post strictement identiques (total=2, gclid=0, conversions=0) ; QA Ludovic navigateur DEV `https://client-dev.keybuzz.io` Inbox + Brouillon IA + tenant switcher + escalation + playbooks read-only OK aucune regression UX visible ; PROD strictement read-only et inchange API v3.5.186-prod + Client v3.5.196-prod + 11 autres services intacts ; aucune mutation source PROD / build dirty / push tag reuse / mutation DB / fake event / fake conversion / fake attribution ; KEY-301 reste Done ; KEY-313 reste Open epic R1 ; AS.13.1 ferme en DEV ; AS.13.1-PROD eligible apres GO Ludovic ; AS.13.2/13.3/13.4 restent a livrer ; gaps G1-G6 documentes ; verdict AS.13.1 DEV GO GOOGLE OBSERVABILITY TENANTGUARD DEV READY.

STOP. AS.13.1 DEV livre. Aucun enchainement vers PROD sans GO explicite Ludovic.
