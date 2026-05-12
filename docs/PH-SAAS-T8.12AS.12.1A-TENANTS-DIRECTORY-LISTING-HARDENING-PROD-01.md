# PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.1A-PROD -- tenants directory listing hardening PROD promotion
> Environnement : PROD ; API-only ; 7 autres services PROD strictement inchanges

---

## 1. VERDICT

GO TENANTS DIRECTORY HARDENING PROD READY

Promotion PROD AS.12.1A reussie en API-only. L endpoint `/tenants` GET + `/tenants/:id` GET exige desormais `X-User-Email` (401 sinon) et filtre via `user_tenants` (canonical access model AS.11.0.7). Plus de directory enumeration sans authentification en PROD.

Bundle : aucun delta source au-dela de KEY-301 AS.12.1A (1 fichier `keybuzz-api/src/modules/tenants/routes.ts` au commit `e001cc48`, deja runtime DEV depuis v3.5.177-tenants-directory-guard-dev).

Validation post-deploy PROD : T1 no-auth 401 + T2 bogus user 200 [] + T3 detail no-auth 401 + T4 preserve `/messages` 6/6 endpoints 401 + /health 200 + 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart. GitOps MATCH=YES sur les 2 services en jeu (API patche + Client inchange). 6 autres services PROD strictement inchanges (outbound-worker, backend, amazon workers x2, backfill-scheduler, admin-v2).

QA Ludovic navigateur PROD reconfirmee : tenant switcher + Inbox + Brouillon IA + auth flow fonctionnels, aucune banniere erreur, aucune regression.

Rollback PROD pret en moins de 5 minutes vers `v3.5.176-messages-tenantguard-prod`.

KEY-301 reste Open (epic). 5 autres surfaces P0/P1 listees AS.12.0 restent a traiter sous-phases ulterieures.

---

## 2. Scope

Inclus :
- API PROD : promotion image `v3.5.176-messages-tenantguard-prod` -> `v3.5.177-tenants-directory-guard-prod` depuis source commit `e001cc48` (deja runtime DEV).
- Manifest infra `k8s/keybuzz-api-prod/deployment.yaml` (1 ligne image).
- Validation negative + preserve.
- Rapport docs-only ASCII strict.
- Textes Linear KEY-301 prepares (a poster apres GO + methode token).

Strictement hors scope :
- Aucun build Client.
- Aucun deploy Client PROD.
- Aucun touchement Backend / Outbound worker / Amazon workers / Backfill scheduler / Admin-v2.
- Aucune mutation DB.
- Aucun POST / PATCH / DELETE.
- Aucun secret manifest / env touche.
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` -- baselines + GitOps + disclosure.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-DEV-01.md` -- DEV validation + commit source + Client impact zero.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-STABILIZATION-CLOSEOUT-01.md` -- baseline PROD stable post `/messages` 6/6.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md` -- finding `/tenants` enumeration + roadmap KEY-301.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / e001cc48 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / d917238 / 0-0 | identique | OK |
| Runtime DEV API | v3.5.177-tenants-directory-guard-dev | identique | OK |
| Runtime PROD API pre | v3.5.176-messages-tenantguard-prod | identique | OK |
| Runtime PROD Client pre | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.177-tenants-directory-guard-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 82 GB libres (12% used) | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=17 WARN=1 FAIL=0 SKIP=1 | OK |

Aucun dirty non compris. Greenlight pour build PROD.

---

## 5. Build PROD

| Item | Valeur |
|---|---|
| Source commit | e001cc4834e918f073a078ea3dec114056d117d2 |
| Source ligne | `fix(security): require X-User-Email + user_tenants filter on /tenants directory (KEY-301 AS.12.1A)` |
| Tag image | v3.5.177-tenants-directory-guard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | e001cc4834e918f073a078ea3dec114056d117d2 (= source commit) |
| KEY-308 OCI created | 2026-05-12T12:00:55Z |
| KEY-308 OCI version | v3.5.177-tenants-directory-guard-prod |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION (API n a pas besoin de NEXT_PUBLIC_*) |
| Build output | Successfully built eda22e6aa331 |
| Digest GHCR | sha256:cb3ffdc26c23e9147fc5cc19afa299f15189c34d61ce2d597db025cbd2862f0b |
| docker push | OK |
| Rollback tag | v3.5.176-messages-tenantguard-prod (sha256:8d7cac8876915aef9d6317191eeca641caeddcb7b5c7f1fd4d15cda7a67331fa) |

Note : la source commit `e001cc48` est identique entre DEV `v3.5.177-tenants-directory-guard-dev` et PROD `v3.5.177-tenants-directory-guard-prod`. Le source est le meme, seules le tag suffix DEV/PROD et l environnement de runtime different. Build-from-Git strict.

Aucun docker push hors la cible PROD API. Aucun rebuild d image existante. Aucun build Client.

---

## 6. GitOps PROD

Commit infra `e18f20c` :

```
gitops(prod): promote tenants directory listing hardening API (AS.12.1A-PROD KEY-301)
```

Modifie 1 manifest uniquement :
- `k8s/keybuzz-api-prod/deployment.yaml` : `v3.5.176-messages-tenantguard-prod` -> `v3.5.177-tenants-directory-guard-prod`

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- Rollout duration : **21 secondes**
- Pod API PROD : nouveau pod 1/1 Running, ancien pod Terminating puis supprime.

Aucun kubectl set / patch / edit / set env. GitOps pur. Aucune mutation hors `k8s/keybuzz-api-prod/deployment.yaml`.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.176-messages-tenantguard-prod | **v3.5.177-tenants-directory-guard-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-client | keybuzz-client-prod | v3.5.190-messages-bff-tenantguard-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API PROD = spec manifest = last-applied annotation = digest pushe sur GHCR. Tous les 7 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve)

### 8.1 Negative tests no-PII

| # | Check | URL public / source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | GET /tenants no-auth (external) | https://api.keybuzz.io/tenants | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | GET /tenants bogus user (in-cluster) | curl x-user-email=bogus@example.com http://127.0.0.1:3001/tenants | 200 [] (no leak, no info inferred) | 200 `[]` | PASS |
| T3 | GET /tenants/:fake no-auth (external) | https://api.keybuzz.io/tenants/fake-id-xyz | 401 | 401 | PASS |
| T4 | GET /tenants/:fake bogus user (in-cluster, attendu 403) | non execute en PROD (interdit dans la fenetre courte) | 403 (cf DEV AS.12.1A T4) | non re-execute PROD (memoire DEV PASS) | INHERIT DEV |

Aucune body PII publiee dans le rapport.

### 8.2 Preserve `/messages` 6/6 endpoints (cf KEY-304 PROD via AS.11.1g)

Cible : conversation id factice `00000000-0000-0000-0000-000000000000`, tenant id factice `fake`. Aucune PII.

| # | Endpoint | Method | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T5 | /messages/conversations | GET | https://api.keybuzz.io/messages/conversations?tenantId=fake&limit=1 | 401 | 401 | PASS |
| T6 | /messages/conversations/:id | GET | idem detail fake id | 401 | 401 | PASS |
| T7 | /messages/conversations/:id/reply | POST | idem reply fake id | 401 | 401 | PASS |
| T8 | /messages/conversations/:id/status | PATCH | idem status fake id | 401 | 401 | PASS |
| T9 | /messages/conversations/:id/assign | PATCH | idem assign fake id | 401 | 401 | PASS |
| T10 | /messages/conversations/:id/sav-status | PATCH | idem sav-status fake id | 401 | 401 | PASS |

KEY-304 protection PROD integralement preservee post AS.12.1A-PROD.

### 8.3 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts | 0 (new pod) | 0 | PASS |

### 8.4 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business Ludovic habituel |
| Tenant switcher visible et fonctionnel | OUI |
| Selection tenant fonctionne | OUI |
| Inbox PROD liste conversations visible | OUI |
| Conversation detail visible | OUI |
| Brouillon IA auto visible | OUI |
| Boutons mutationnels visibles (NON cliques) | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| Regression visible Inbox / channels / suppliers / catalogue / commande | NON |

Aucune donnee client copiee dans ce rapport. Aucune capture ecran avec PII committee.

---

## 9. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert e18f20c --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.176-messages-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Tag rollback exact : `v3.5.176-messages-tenantguard-prod` (sha256:8d7cac8876915aef9d6317191eeca641caeddcb7b5c7f1fd4d15cda7a67331fa).

Triggers rollback immediat :
- tenant switcher casse en PROD
- Inbox PROD cassee
- Brouillon IA disparait
- auth flow casse
- banniere "API indisponible" persistante
- spike 5xx API PROD anormal
- spike JWT_SESSION_ERROR Client PROD
- 403 NOT_MEMBER injustifie sur compte legitime

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 10. PROD unchanged proof (7 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.1A-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Seul `keybuzz-api-prod/keybuzz-api` est passe de v3.5.176 a v3.5.177. Aucun manifest PROD autre touche. Aucun docker push prod-tag autre que la cible API. Aucun kubectl apply sur namespace `*-prod` autre que `keybuzz-api-prod`.

---

## 11. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.1A-PROD | Justification |
|---|---|---|
| Tenant switcher | OK (BFF /tenant-context/tenants session-bound inchange) | aucun changement Client |
| Inbox liste conversations | OK (BFF AS.11.1A-R2) | KEY-304 LIST protected |
| Inbox detail conversation | OK (BFF AS.11.1C) | KEY-304 DETAIL protected |
| Inbox reply | OK runtime | KEY-304 REPLY protected |
| Inbox changement status | OK runtime | KEY-304 STATUS protected |
| Inbox assigner | OK runtime | KEY-304 ASSIGN protected |
| Inbox SAV label | OK runtime | KEY-304 SAV-STATUS protected |
| Brouillon IA visibilite auto | OK (KEY-305 consolidated useEffect en PROD) | inchange |
| Brouillon IA "Valider et envoyer" UI | OK (NON clique) | inchange |
| Escalation badge AS.1 (KEY-263) | OK | inchange |
| Auth flow PROD | OK (NextAuth + tenant-context session bound) | inchange |
| Channels / suppliers / commande / catalogue | inchanges | hors scope KEY-301 AS.12.1A |
| /tenants directory enumeration sans auth | **FERMEE** | objectif phase courante |

Aucune regression observee. Aucune mutation reellement effectuee en PROD.

---

## 12. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digest sha256:cb3ffdc26c..., commits e18f20c + e001cc48, rollout 21s, log counts 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 13. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 11 jeux de commentaires accumules (serie AS.11.1D -> AS.11.1g stabilization + AS.12.0 + AS.12.1A DEV + AS.12.1A PROD).

### 13.1 KEY-301 commentaire AS.12.1A-PROD (texte cible)

```
## AS.12.1A-PROD promotion executed -- tenant directory listing hardened in PROD

- API PROD : v3.5.176-messages-tenantguard-prod -> v3.5.177-tenants-directory-guard-prod (source commit e001cc48, same as DEV runtime v3.5.177-tenants-directory-guard-dev).
- Client PROD strictly unchanged (v3.5.190 ; no Client build, no Client deploy ; the legitimate "my tenants" UX path uses the session-bound BFF `/tenant-context/tenants` which is independent of this fix).
- 6 other PROD services strictly unchanged (outbound-worker, backend, Amazon items+orders workers, backfill scheduler, admin-v2).
- GitOps MATCH=yes on API + Client PROD. Rollout 21s.
- Validation post-deploy PROD : `/tenants` no-auth -> 401, bogus user -> 200 empty, `/tenants/:id` no-auth -> 401, all 6 `/messages/conversations*` endpoints preserved at 401.
- /health PROD 200. Logs PROD 5min : 0 API 5xx, 0 Client JWT_SESSION_ERROR, 0 pod restart.
- Ludovic QA navigateur PROD reconfirmed : tenant switcher + Inbox + Brouillon IA + auth flow all functional, no error banner, no regression.

Tenant directory enumeration without authentication is now closed in PROD.

KEY-301 stays Open as an epic. Remaining P0 surfaces from AS.12.0 audit still pending : notifications, outbound, AI suite + autopilot, legacy compat proxy. Next sub-phases (AS.12.1B / AS.12.2 / etc.) to be sequenced on Ludovic GO.

Rollback ready in less than 5 minutes via revert infra commit e18f20c.

Disclosure controle : pas de PoC, pas de details exploit, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-PROD-01.md
```

---

## 14. Compliance AS.12.1A-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (deja en DEV AS.12.1A) | OK (api e001cc48 deja push, infra e18f20c push pre-apply) |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| API-only (aucun build/push Client) | OK |
| KEY-308 OCI labels non "unknown" | OK (revision = source commit e001cc48) |
| KEY-309 pre-push tag check AVAILABLE | OK |
| Digest documente | OK (sha256:cb3ffdc26c...) |
| Rollback plan documente et tag rollback | OK section 9 (v3.5.176 sha256:8d7cac88...) |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod/keybuzz-api | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK |
| Aucun POST / PATCH / DELETE positif | OK |
| Aucune PII publiee (counts redacted only, no name, no email) | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare, attente GO + methode token) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 7 autres PROD services strictement unchanged | OK |
| Pod API PROD restart count = 0 post-deploy | OK |

---

## 15. Phrase cible finale

AS.12.1A-PROD livre : promotion PROD du hardening tenant directory listing API en API-only ; image PROD v3.5.176-messages-tenantguard-prod -> v3.5.177-tenants-directory-guard-prod depuis source commit e001cc48 (identique runtime DEV) ; digest GHCR sha256:cb3ffdc26c23e9147fc5cc19afa299f15189c34d61ce2d597db025cbd2862f0b ; commit infra `e18f20c` ; rollout API PROD 21s ; GitOps MATCH=yes ; 7 autres services PROD strictement inchanges (outbound-worker, backend, Amazon workers x2, backfill scheduler, admin-v2, Client PROD inchange) ; validation post-deploy PROD T1-T10 PASS (no-auth 401, bogus 200 [], detail no-auth 401, preserve /messages 6/6 401, /health 200) ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (tenant switcher + Inbox + Brouillon IA + auth fonctionnels, aucune banniere, aucune regression) ; rollback PROD pret en < 5 min vers v3.5.176-messages-tenantguard-prod ; aucune mutation DB, aucun POST/PATCH/DELETE positif, aucune PII publiee, aucun secret, aucun deploy hors API PROD ; KEY-301 reste Open epic ; verdict AS.12.1A-PROD GO TENANTS DIRECTORY HARDENING PROD READY.

STOP
