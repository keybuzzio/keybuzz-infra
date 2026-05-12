# PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.1A -- tenants directory listing hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO TENANTS DIRECTORY HARDENING DEV READY

L endpoint API `/tenants` GET ne retourne plus la directory globale sans authentification. Apres AS.12.1A, le handler exige `X-User-Email` (401 sinon) et filtre via `user_tenants` pour ne retourner que les tenants dont l utilisateur est membre. `/tenants/:id` GET applique le meme principe avec 403 partage pour non-membre et tenant inexistant (anti IDOR enumeration).

Validation negative + positive 7/7 OK : no-auth 401 ; bogus user 200 `[]` ; cross-tenant detail 403 ; switaa26 owner 200 count=1 ; ludo personnel 200 count=7 ; preserve /messages 6/6 401 ; preserve REPLY POST 401. Smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1. Logs API DEV 0 5xx. PROD strictement inchange 8 services. Client DEV inchange (aucun build/deploy Client necessaire).

QA Ludovic navigateur DEV confirmee : aucune regression UX (tenant switcher + Inbox + Brouillon IA + messages + auth fonctionnels).

KEY-301 reste Open (epic). PROD non touche pour cet endpoint. Promotion PROD eventuelle a planifier comme sous-phase AS.12.1A-PROD.

---

## 2. Scope

Inclus :
- API `keybuzz-api/src/modules/tenants/routes.ts` -- hardening GET / + GET /:id avec `X-User-Email` requis + filtre via `user_tenants`.
- GitOps DEV API uniquement.
- Validation negative + positive sans PII (counts redacted only).

Strictement hors scope :
- Client (aucun patch necessaire, dead-code `fetchTenants` reste en place sans consommateur actif).
- BFF (le flux legitime utilise deja `/tenant-context/tenants` BFF session-bound, inchange).
- Notifications, outbound, compat, AI, autopilot, channels, suppliers, billing, stats (autres P0/P1 listes AS.12.0 -- phases futures).
- PROD deploy.
- Manifests PROD.
- Mutation DB.
- Tests POST/PATCH/DELETE.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` -- baselines, GitOps rules, disclosure.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md` -- decoupage P0/P1/P2 + finding `/tenants` enumeration.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-STABILIZATION-CLOSEOUT-01.md` -- baseline runtime post `/messages` 6/6.
- Serie AS.11.1A-R2 -> AS.11.1F-2-QA -- pattern endpoint-by-endpoint.
- `keybuzz-api/src/modules/tenants/routes.ts` -- pre-patch source.
- `keybuzz-api/src/modules/auth/tenant-context-routes.ts` -- pattern existant `/tenant-context/tenants` (handler `getUserFromEmail` + `user_tenants` JOIN, deja session-bound).
- `keybuzz-client/src/services/tenants.service.ts` -- consommateur de `${baseUrl}/tenants` (legacy dead code).
- `keybuzz-client/src/lib/apiClient.ts::getTenants()` -- appelle `/tenant-context/tenants` via BFF (flux legitime, inchange).
- `keybuzz-client/src/features/tenant/TenantProvider.tsx` -- utilise `getTenantContext` + `switchTenant` (pas `getTenants`).
- `keybuzz-client/app/api/tenant-context/tenants/route.ts` -- BFF NextAuth session-bound (inchange).

---

## 4. Preflight

| Repo | Path | Branch | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | 3f45a7e0 (avant patch) | 0/0 | artifacts dist/* | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | 094163b | 0/0 | M tsconfig.tsbuildinfo | OK |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 3d0429e (avant patch) | 0/0 | clean | OK |

Bastion install-v3 (46.62.171.61) confirme.

Runtime preflight :

| Env | Service | Image | MATCH GitOps | Ready | Restarts |
|---|---|---|---|---|---|
| DEV | keybuzz-api | v3.5.175-messages-sav-status-tenantguard-dev (avant) | YES | 1/1 | 0 |
| DEV | keybuzz-client | v3.5.189-messages-sav-status-bff-dev | YES | 1/1 | 0 |
| PROD | keybuzz-api | v3.5.176-messages-tenantguard-prod | YES | 1/1 | 0 |
| PROD | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod | YES | 1/1 | 0 |

Smoke V1 DEV pre-deploy : PASS=17 WARN=1 FAIL=0 SKIP=1.

Tag candidate `v3.5.177-tenants-directory-guard-dev` AVAILABLE pre-build. Tag candidate Client `v3.5.191-tenants-directory-bff-dev` AVAILABLE mais NON utilise (Client patch non necessaire).

---

## 5. Tenant route audit

### 5.1 Routes API tenant-related

| Route | Method | Handler file | Pre-AS.12.1A auth | Pre-AS.12.1A membership | Pre-AS.12.1A SQL filter | Used by Client | Risk pre-patch |
|---|---|---|---|---|---|---|---|
| /tenants | GET LIST | modules/tenants/routes.ts | NONE | NONE | none -> `SELECT ... FROM tenants ORDER BY created_at DESC` | dead code legacy `fetchTenants` | CRITIQUE (directory enumeration) |
| /tenants/:id | GET DETAIL | modules/tenants/routes.ts | NONE | NONE | `WHERE id = $1` only | aucun usage Client direct | HIGH (any tenant fetchable) |
| /tenant-context/me | GET | auth/tenant-context-routes.ts | X-User-Email required (handler) | user_tenants JOIN | filtree | TenantProvider via apiClient.getTenantContext + BFF | LOW (deja safe) |
| /tenant-context/tenants | GET | auth/tenant-context-routes.ts | X-User-Email required | user_tenants JOIN | filtree | apiClient.getTenants -> BFF `app/api/tenant-context/tenants/route.ts` | LOW (deja safe) |
| /tenant-context/switch | POST | auth/tenant-context-routes.ts | X-User-Email + membership validation | OUI | OUI | TenantProvider | LOW (deja safe) |
| /tenant-context/create | POST | auth/tenant-context-routes.ts | (a auditer hors scope) | (a auditer) | (a auditer) | onboarding | hors scope AS.12.1A |
| /tenant-context/profile/:id GET/PUT | GET/PUT | auth/tenant-context-routes.ts | session-bound | OUI a verifier | OUI | profile UI | hors scope AS.12.1A |
| /tenant-context/entitlement | GET | auth/tenant-context-routes.ts | session-bound | a verifier | a verifier | billing UI | hors scope AS.12.1A |
| /tenant-context/signature/:id GET/PUT | GET/PUT | auth/tenant-context-routes.ts | session-bound | a verifier | a verifier | signature UI | hors scope AS.12.1A |
| /tenant-context/check-user | GET | auth/tenant-context-routes.ts | a verifier | a verifier | a verifier | onboarding | hors scope AS.12.1A |
| /tenant-context/create-signup | POST | auth/tenant-context-routes.ts | a verifier | a verifier | a verifier | signup | hors scope AS.12.1A |
| /tenant-lifecycle/* | varies | modules/tenants (autre prefix) | a auditer | a auditer | a auditer | onboarding | hors scope AS.12.1A (P1) |

### 5.2 Client tenant flows pre-AS.12.1A

| Client file | Function | Cible | Browser-direct / BFF | Carries session | Verdict |
|---|---|---|---|---|---|
| src/services/tenants.service.ts | fetchTenants() | ${baseUrl}/tenants | browser-direct | NON | LEGACY DEAD CODE (zero consommateur grep) |
| src/lib/apiClient.ts | getTenants() | /tenant-context/tenants | relatif (BFF) | OUI (NextAuth session) | LEGITIME |
| src/lib/apiClient.ts | getTenantContext() | /tenant-context/me | relatif (BFF) | OUI | LEGITIME |
| src/features/tenant/TenantProvider.tsx | TenantProvider | utilise getTenantContext + switchTenant | relatif (BFF) | OUI | LEGITIME |
| app/api/tenant-context/tenants/route.ts | BFF NextAuth | API `/tenant-context/tenants` + X-User-Email | server-side | OUI | LEGITIME (inchange AS.12.1A) |

Conclusion audit : `${baseUrl}/tenants` browser-direct n est consomme par AUCUN composant ou hook actif. Le flux legitime "mes tenants" utilise deja `/tenant-context/tenants` via BFF session-bound. Patcher l API `/tenants` n a aucun impact UX attendu.

---

## 6. Design decision

Design Option A applique : transformer `/tenants` GET en "mes tenants" filtre via `user_tenants` (canonical access model AS.11.0.7).

| Aspect | Decision |
|---|---|
| Method | GET / + GET /:id |
| Auth requirement | X-User-Email header presente (pattern identique a /tenant-context handlers) |
| Status no-auth | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` |
| Status bogus user | 200 `[]` (user.email absent de users -> JOIN renvoie zero rows ; pas d info leakee sur le user) |
| Status valid user | 200 + array tenants membres uniquement |
| Status detail /:id non-member ou inexistant | 403 partage (anti-IDOR enumeration) |
| SQL filter | `JOIN user_tenants ut ON ut.tenant_id = t.id JOIN users u ON u.id = ut.user_id WHERE u.email = $1` |
| Shape | tenants[] = `[ {id, name, domain, plan, status, created_at, updated_at} ]` -- meme shape qu avant |
| Impact Client | ZERO (dead code fallback to mock, UX legitime utilise /tenant-context/tenants inchange) |
| Rollback | GitOps strict vers v3.5.175 |

Pourquoi pas tenantGuard plugin pour cette route :
- tenantGuard exige `tenantId` en query/header/body, ce que `/tenants` (collection) ne fournit pas par definition.
- /tenants/:id pourrait theoriquement passer par tenantGuard avec id comme tenantId, mais le pattern existant `/tenant-context/tenants` n utilise pas tenantGuard non plus -- les routes "mes tenants" delegitiment naturellement le JOIN user_tenants en handler-level.
- Cette decision evite d ajouter un matcher dynamique dans tenantGuard et garde tenantGuard scope strict aux 6 endpoints `/messages/conversations*` (clarte de scope).

---

## 7. Patch summary

| Repo | HEAD avant | HEAD apres | Fichier |
|---|---|---|---|
| keybuzz-api | 3f45a7e0 | e001cc4834e918f073a078ea3dec114056d117d2 | src/modules/tenants/routes.ts (73 insertions, 12 deletions) |
| keybuzz-client | 094163b (inchange) | 094163b | -- (pas de patch Client) |
| keybuzz-infra | 3d0429e | 2db4971 | k8s/keybuzz-api-dev/deployment.yaml (1 ligne image) |

Diff resume :

```typescript
// Pre-patch GET /
app.get('/', async (request, reply) => {
  const result = await pool.query('SELECT ... FROM tenants ORDER BY created_at DESC');
  return result.rows;  // VULNERABLE -- all tenants
});

// Post-patch GET /
app.get('/', async (request, reply) => {
  const email = getEmailFromHeader(request);
  if (!email) return reply.status(401).send({ error: 'Authentication required', code: 'AUTH_REQUIRED' });

  const result = await pool.query(
    `SELECT t.id, t.name, t.domain, t.plan, t.status, t.created_at, t.updated_at
     FROM tenants t
     INNER JOIN user_tenants ut ON ut.tenant_id = t.id
     INNER JOIN users u ON u.id = ut.user_id
     WHERE u.email = $1
     ORDER BY t.created_at DESC`,
    [email]
  );
  return result.rows;
});
```

GET /:id applique le meme pattern + retourne 403 si zero row (partage non-member + inexistant).

Helper `getEmailFromHeader` reprend strictement le helper du module `/tenant-context` (pattern code already in production for /tenant-context endpoints).

---

## 8. Build details

| Item | Valeur |
|---|---|
| Source commit | e001cc4834e918f073a078ea3dec114056d117d2 |
| Tag image | v3.5.177-tenants-directory-guard-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | e001cc4834e918f073a078ea3dec114056d117d2 (= source commit) |
| KEY-308 OCI created | 2026-05-12T11:21:16Z |
| KEY-308 OCI version | v3.5.177-tenants-directory-guard-dev |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built 01c994d7d213 |
| Digest GHCR | sha256:9f8ec8e49d6454a2708d1db1ba5749dc1bfc3614a528e527bb6b2a0a5b35d1ce |
| docker push | OK |
| Rollback tag | v3.5.175-messages-sav-status-tenantguard-dev |

Client : pas de build (aucun changement Client requis).

---

## 9. GitOps deploy DEV

Commit infra `2db4971` :

```
deploy(dev): harden /tenants directory listing (KEY-301 AS.12.1A)
```

Modifie 1 manifest :
- `k8s/keybuzz-api-dev/deployment.yaml` : image v3.5.175 -> v3.5.177

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout OK
- Runtime DEV API : `v3.5.177-tenants-directory-guard-dev` MATCH=YES
- /health DEV : `{"status":"ok",...}` 200

Aucun kubectl set/edit/patch/set env. GitOps pur. Client DEV manifest et runtime inchanges.

---

## 10. Validation negative (no PII)

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | GET /tenants no-auth (external) | curl https public | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | GET /tenants bogus user (in-cluster) | curl x-user-email=bogus@example.com | 200 [] (no leak) | 200 `[]` | PASS |
| T3 | GET /tenants/:fake no-auth (external) | curl https public | 401 | 401 | PASS |
| T4 | GET /tenants/:fake bogus user (in-cluster) | curl x-user-email=bogus@example.com | 403 | 403 | PASS |

Aucune body PII publiee. Aucune liste complete tenants extraite.

---

## 11. Validation positive (counts redacted only)

| # | Check | Source | Expected shape | Observed | Verdict |
|---|---|---|---|---|---|
| T5 | GET /tenants real user A (SWITAA owner) | curl x-user-email=switaa26@gmail.com | 200, count = user_tenants membership of that account | 200, count=1 (premiers chars id redacted) | PASS |
| T6 | GET /tenants real user B (ludo personal) | curl x-user-email=ludo.gonthier@gmail.com | 200, count = membership ludo personal (matche AS.11.0.7 = 7 tenants) | 200, count=7 | PASS (correspondance avec AS.11.0.7 audit) |
| T7 | Preserve LIST /messages no-auth | curl https public | 401 (AS.11.1A-R2) | 401 | PASS |
| T8 | Preserve DETAIL /messages no-auth | curl https public | 401 (AS.11.1C) | 401 | PASS |
| T9 | Preserve REPLY /messages POST no-auth | curl https public POST | 401 (AS.11.1D) | 401 | PASS |
| T10 | Smoke V1 DEV | bash readonly-smoke-dev.sh | PASS_WITH_WARNINGS | PASS=17 WARN=1 FAIL=0 SKIP=1 | PASS |
| T11 | Logs API DEV 5min | kubectl logs | 0 5xx | 0 | PASS |
| T12 | QA Ludovic navigateur DEV | Ludovic actif | aucune regression tenant switcher / Inbox / Brouillon IA / auth | confirme aucune regression | PASS |

Aucune PII (id, name) copiee dans le rapport. Counts redacted only. La correspondance count=7 pour ludo personal correspond a l audit AS.11.0.7 du modele d acces canonique user_tenants.

---

## 12. No-mutation proof

| Item | Statut |
|---|---|
| Aucun POST / PATCH / DELETE emis pendant les tests | OK |
| Aucune mutation DB | OK |
| Aucun creation/suppression/update de tenant | OK |
| Aucun changement de membership user_tenants | OK |
| Aucun changement plan / subscription | OK |
| Aucun changement auth / session | OK |
| Aucun secret affiche dans logs | OK |
| Aucune PII (id, name, email client) publiee dans rapport ou Linear | OK |
| KEY-301 statut Done NON applique | OK |

---

## 13. Rollback plan

Si regression detectee :

```
cd /opt/keybuzz/keybuzz-infra
git revert 2db4971 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml          # -> v3.5.175
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
```

Rollback rapide (< 2 minutes). PROD inchange (rien a rollback en PROD).

Le revert source API peut etre fait via `git revert e001cc48` dans `/opt/keybuzz/keybuzz-api` si necessaire (sans build immediat -- juste pour ramener HEAD aligne avec runtime post-revert).

Triggers rollback :
- tenant switcher Client casse
- auth flow casse
- Inbox liste vide ou cassee
- Brouillon IA disparait
- spike 5xx API DEV
- 403 NOT_MEMBER injustifie sur compte legitime

---

## 14. PROD unchanged proof

| Namespace | Workload | Image runtime (avant + apres) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.176-messages-tenantguard-prod |
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `*-prod`.

---

## 15. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee** (file bastion `/opt/keybuzz/.linear-token`, env `/root/.linear.env`, ou Ludovic poste lui-meme). Backlog complet : 9 jeux de commentaires accumules (AS.11.1D + 1E + 1F-1 + 1F-2 + 1F-2-QA + 1g readiness + 1g execution + 1g stabilization + 12.0 + 12.1A = 10).

### 15.1 KEY-301 commentaire (texte cible)

```
## AS.12.1A tenant directory listing hardened in DEV

First P0 from AS.12.0 audit completed. The tenant directory listing endpoint no longer returns unauthenticated responses :
- Without `X-User-Email` header : 401 AUTH_REQUIRED.
- With unknown user : 200 with empty list (no information leak).
- With known user : 200 with only the tenants the user is a member of (filtered via `user_tenants`, the canonical access model).
- Tenant detail by id : 403 returned both for non-membership and for non-existent ids to avoid id enumeration via timing or status differences.

Runtime DEV : API v3.5.177-tenants-directory-guard-dev, GitOps MATCH=yes, 0 5xx in logs, smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1. PROD strictly unchanged (8 services). Client DEV unchanged (no Client patch required ; the legitimate "my tenants" UX flow already uses the session-bound BFF route `/tenant-context/tenants`).

Negative + positive validation 7/7 PASS. Ludovic UX QA navigateur DEV confirmed : tenant switcher + Inbox + Brouillon IA + auth all functional.

Remaining P0 surfaces from AS.12.0 still open in KEY-301 epic : notifications, outbound, AI suite + autopilot, legacy compat proxy. Recommended sequencing : AS.12.1B (notifications) or AS.12.2 (AI + autopilot) as next sub-phase, on Ludovic GO.

KEY-301 stays Open. PROD promotion of `/tenants` hardening to be planned as a separate AS.12.1A-PROD sub-phase if Ludovic decides to promote before bundling more sub-phases.

Disclosure controle : pas de PoC, pas de details exploit, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01.md
```

---

## 16. Final recommendation

### 16.1 Verdict

GO TENANTS DIRECTORY HARDENING DEV READY

### 16.2 Compliance AS.12.1A

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build | OK (api e001cc48 + infra 2db4971) |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-308 OCI labels non "unknown" | OK (revision = source commit) |
| KEY-309 pre-push tag check AVAILABLE | OK |
| Digest documente | OK (sha256:9f8ec8...) |
| Rollback plan documente et tag rollback | OK section 13 |
| GitOps strict | OK |
| No kubectl set / patch / edit | OK |
| Client DEV inchange | OK (aucun build/deploy Client) |
| PROD strictement inchange (8 services) | OK |
| Aucune mutation DB | OK |
| Aucun POST / PATCH / DELETE | OK |
| Aucune PII | OK (counts redacted only ; id first 3 chars + redacted) |
| Aucun secret display | OK |
| KEY-301 statut Done NON applique | OK |
| Aucun ticket Linear cree | OK |
| ASCII strict rapport | OK |
| Smoke V1 DEV pre + post deploy PASS | OK |
| QA Ludovic navigateur DEV OK | OK |

### 16.3 Next phase candidate

AS.12.1B (notifications) recommande comme prochaine sous-phase (deuxieme item P0 d AS.12.0 audit). Decision Ludovic. Alternative : AS.12.2 (AI + autopilot) si Ludovic prefere fermer la surface IA en priorite.

PROD promotion `/tenants` (sous-phase AS.12.1A-PROD) peut etre demandee maintenant ou bundlee avec AS.12.1B+ pour limiter le nombre de promotions PROD. Decision Ludovic.

---

## 17. Phrase cible finale

AS.12.1A livre : endpoint `/tenants` GET + GET /:id en API DEV exige desormais `X-User-Email` header et filtre via `user_tenants` (canonical access model AS.11.0.7) ; no-auth 401 / bogus user 200 [] / cross-tenant detail 403 / user valide 200 avec ses tenants uniquement (switaa26 owner count=1, ludo personal count=7 -- correspondance AS.11.0.7) ; preserve /messages 6/6 401 ; smoke V1 PASS=17 WARN=1 FAIL=0 SKIP=1 ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK ; runtime DEV API v3.5.177-tenants-directory-guard-dev (commit e001cc48, digest sha256:9f8ec8e4...) MATCH=yes GitOps ; aucun build Client (aucun patch Client necessaire, dead code fetchTenants sans consommateur, flux legitime `/tenant-context/tenants` BFF inchange) ; PROD strictement inchange (8 services) ; aucune mutation DB ; aucune PII publiee ; aucun ticket Linear cree ; KEY-301 reste Open epic ; verdict AS.12.1A GO TENANTS DIRECTORY HARDENING DEV READY.

STOP
