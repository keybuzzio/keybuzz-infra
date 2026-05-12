# PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.1B-PROD -- notifications module tenantGuard PROD promotion
> Environnement : PROD ; API-only ; 7 autres services PROD strictement inchanges

---

## 1. VERDICT

GO NOTIFICATIONS TENANTGUARD PROD READY

Promotion PROD AS.12.1B reussie en API-only. Le module `/notifications` est desormais couvert par le tenantGuard runtime en PROD avec 4 endpoints proteges : LIST + DETAIL + ACK + SIMULATE. Bundle minimal : aucun delta source au-dela de KEY-301 AS.12.1B (1 fichier `keybuzz-api/src/plugins/tenantGuard.ts` au commit `5eadb345`, deja runtime DEV depuis v3.5.178).

Validation post-deploy PROD : T1-T4 no-auth 401 sur 4 endpoints notifications + preserve /messages 6/6 401 + preserve /tenants AS.12.1A 401 + /health 200 + 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart anormal. GitOps MATCH=YES.

QA Ludovic navigateur PROD reconfirmee : escalation badge KEY-263 (polling `/api/notifications` toutes 30s) + Inbox + Brouillon IA + tenant switcher + auth flow fonctionnels, aucune banniere erreur, aucune regression.

Rollback PROD pret en moins de 5 minutes vers `v3.5.177-tenants-directory-guard-prod`.

KEY-301 reste Open (epic). 6 autres surfaces P0/P1 listees AS.12.0 restent a traiter.

---

## 2. Scope

Inclus :
- Build API PROD `v3.5.178-notifications-tenantguard-prod` depuis source commit `5eadb345`.
- Push GHCR (1 cible).
- Manifest `k8s/keybuzz-api-prod/deployment.yaml` (1 ligne image).
- Validation negative + preserve PROD.
- Rapport docs-only ASCII strict.
- Texte Linear KEY-301 prepare.

Strictement hors scope :
- Aucun build Client.
- Aucun deploy Client PROD.
- Aucun touchement Backend / Outbound worker / Amazon workers / Backfill scheduler / Admin-v2.
- Aucune mutation DB.
- Aucun POST / PATCH / DELETE positif PROD.
- Aucun secret manifest / env touche.
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-DEV-01.md` -- DEV validation + commit source + design.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1A-TENANTS-DIRECTORY-LISTING-HARDENING-PROD-01.md` -- precedente promotion API PROD KEY-301.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-STABILIZATION-CLOSEOUT-01.md` -- baseline PROD stable post `/messages` 6/6.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md`

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 5eadb345 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 2f4506c (avant patch) / 0-0 | identique | OK |
| Runtime DEV API | v3.5.178-notifications-tenantguard-dev | identique | OK |
| Runtime PROD API pre | v3.5.177-tenants-directory-guard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.178-notifications-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 81 GB libres (14% used) | OK |

Note : un `git fetch` initial sur `keybuzz-infra` a renvoye un HTTP 500 transient ; retry immediat OK. Aucune action correctrice necessaire.

---

## 5. Build PROD

| Item | Valeur |
|---|---|
| Source commit | 5eadb345e278644986dff7bf48ac91e4db46ffd4 |
| Source ligne | `fix(security): protect notifications module with tenant guard (KEY-301 AS.12.1B)` |
| Tag image | v3.5.178-notifications-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 5eadb345e278644986dff7bf48ac91e4db46ffd4 (= source commit) |
| KEY-308 OCI created | 2026-05-12T13:01:17Z |
| KEY-308 OCI version | v3.5.178-notifications-tenantguard-prod |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built be13b05e167f |
| Digest GHCR | sha256:8c37e5f1c6df852eaa8db287feca3619eed25d8e279fa8da5951df2511e4a977 |
| docker push | OK |
| Rollback tag | v3.5.177-tenants-directory-guard-prod (sha256:cb3ffdc26c23e9147fc5cc19afa299f15189c34d61ce2d597db025cbd2862f0b) |

Source commit `5eadb345` identique entre DEV et PROD. Build-from-Git strict. Aucun docker push hors la cible PROD API.

---

## 6. GitOps PROD

Commit infra `e4d4523` :

```
gitops(prod): promote notifications tenantGuard API (AS.12.1B-PROD KEY-301)
```

Modifie 1 manifest uniquement :
- `k8s/keybuzz-api-prod/deployment.yaml` : `v3.5.177-tenants-directory-guard-prod` -> `v3.5.178-notifications-tenantguard-prod`

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- Rollout duration : **60 secondes**
- Pod API PROD : nouveau pod 1/1 Running, ancien Terminating puis supprime.

Aucun kubectl set / patch / edit / set env. GitOps pur. Aucune mutation hors `k8s/keybuzz-api-prod/deployment.yaml`.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.177-tenants-directory-guard-prod | **v3.5.178-notifications-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-client | keybuzz-client-prod | v3.5.190-messages-bff-tenantguard-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API PROD = spec manifest = last-applied annotation = digest pushe sur GHCR. Tous les 7 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve, no PII)

### 8.1 Negative tests notifications PROD

| # | Endpoint | Method | URL public | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T1 | /notifications | GET | https://api.keybuzz.io/notifications?tenantId=fake&limit=1 | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | /notifications/:fake | GET | https://api.keybuzz.io/notifications/...fake-id | 401 | 401 | PASS |
| T3 | /notifications/:fake/ack | PATCH | idem PATCH body `{}` | 401 | 401 | PASS |
| T4 | /notifications/simulate | POST | idem POST body `{"tenantId":"fake-tenant","title":"x","body":"y"}` | 401 | 401 | PASS |

Aucun POST positif vers conversation reelle ou tenant reel.

### 8.2 Preserve KEY-304 `/messages` 6/6 endpoints PROD

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | 401 | 401 | PASS |
| P2 | /messages/conversations/:fake | GET | 401 | 401 | PASS |
| P3 | /messages/conversations/:fake/reply | POST | 401 | 401 | PASS |
| P4 | /messages/conversations/:fake/status | PATCH | 401 | 401 | PASS |
| P5 | /messages/conversations/:fake/assign | PATCH | 401 | 401 | PASS |
| P6 | /messages/conversations/:fake/sav-status | PATCH | 401 | 401 | PASS |

### 8.3 Preserve AS.12.1A `/tenants` PROD

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P7 | /tenants | GET (no-auth) | 401 | 401 | PASS |

### 8.4 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts (new pod post-rollout) | 0 | 0 | PASS |

### 8.5 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business Ludovic habituel |
| Inbox PROD liste conversations visible | OUI |
| Escalation badge KEY-263 (poll `/api/notifications` 30s) | OUI (count fonctionnel) |
| Brouillon IA auto visible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Tenant switcher fonctionnel | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| Regression visible | NON |

Aucune donnee client copiee dans ce rapport.

---

## 9. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert e4d4523 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.177-tenants-directory-guard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Tag rollback exact : `v3.5.177-tenants-directory-guard-prod` (sha256:cb3ffdc26c23e9147fc5cc19afa299f15189c34d61ce2d597db025cbd2862f0b).

Triggers rollback immediat :
- escalation badge ne charge plus en PROD (fetch `/api/notifications` echoue de maniere non transitoire)
- Inbox PROD cassee
- Brouillon IA disparait
- spike 5xx API PROD anormal
- spike JWT_SESSION_ERROR Client PROD
- 403 NOT_MEMBER injustifie sur compte legitime PROD

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 10. PROD unchanged proof (7 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.1B-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Seul `keybuzz-api-prod/keybuzz-api` est passe de v3.5.177 a v3.5.178. Aucun manifest PROD autre touche.

---

## 11. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.1B-PROD | Justification |
|---|---|---|
| Tenant switcher | OK (BFF /tenant-context/tenants session-bound inchange) | aucun changement Client |
| Inbox liste conversations | OK (BFF AS.11.1A-R2) | KEY-304 LIST protected |
| Inbox detail / reply / status / assign / sav-status | OK runtime | KEY-304 6/6 preserves |
| Escalation badge KEY-263 (poll `/api/notifications`) | OK (BFF deja session-bound) | comportement vise : tenantGuard accepte X-User-Email injecte par BFF |
| Brouillon IA visibilite auto | OK | inchange |
| Auth flow PROD | OK | inchange |
| Channels / suppliers / commande / catalogue | inchanges | hors scope KEY-301 AS.12.1B |
| /notifications cross-tenant sans auth | **FERMEE** | objectif phase courante |

Aucune regression observee.

---

## 12. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digest sha256:8c37e5f1c6..., commits e4d4523 + 5eadb345, rollout 60s, log counts 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 13. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 13 jeux de commentaires accumules (serie AS.11.1D -> AS.12.1B PROD).

### 13.1 KEY-301 commentaire AS.12.1B-PROD (texte cible)

```
## AS.12.1B-PROD promotion executed -- notifications module hardened in PROD

- API PROD : v3.5.177-tenants-directory-guard-prod -> v3.5.178-notifications-tenantguard-prod (source commit 5eadb345, same as DEV runtime v3.5.178-notifications-tenantguard-dev).
- Client PROD strictly unchanged (v3.5.190). No Client build, no Client deploy. The escalation badge polling flow already used the existing session-bound BFF route ; tenantGuard now accepts those legitimate calls and rejects unauthenticated ones.
- 6 other PROD services strictly unchanged (outbound-worker, backend, Amazon workers x2, backfill scheduler, admin-v2).
- GitOps MATCH=yes. Rollout 60s.
- Validation post-deploy PROD : all 4 notifications endpoints (LIST + DETAIL + ACK + SIMULATE) return 401 unauthenticated ; KEY-304 /messages 6/6 preserved 401 ; AS.12.1A /tenants preserved 401 ; /health PROD 200 ; 0 API 5xx ; 0 Client JWT_SESSION_ERROR ; 0 pod restart.
- Ludovic QA navigateur PROD reconfirmed : escalation badge + Inbox + Brouillon IA + tenant switcher + auth flow all functional, no error banner, no regression.

Notifications cross-tenant surface is now closed in PROD.

KEY-301 stays Open as an epic. Remaining surfaces from AS.12.0 audit still pending : AI suite + autopilot (P0), legacy compat proxy (P0), outbound (P0/P1 alongside), channels + suppliers + integrations + marketplace OAuth (P1), tenant-lifecycle + teams + agents + roles (P1), billing + stats family (P1), orders + tracking (P2), remaining surface (P2). Next sub-phases on Ludovic GO.

Rollback ready in less than 5 minutes via revert infra commit e4d4523.

Disclosure controle : pas de PoC, pas de details exploit, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. Compliance AS.12.1B-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (deja AS.12.1B DEV : api 5eadb345 push ; infra e4d4523 push pre-apply) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| API-only (aucun build/push Client) | OK |
| KEY-308 OCI labels non "unknown" | OK (revision = source commit) |
| KEY-309 pre-push tag check AVAILABLE | OK |
| Digest documente | OK (sha256:8c37e5f1c6...) |
| Rollback plan documente et tag rollback | OK section 9 (v3.5.177 sha256:cb3ffdc26c...) |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod/keybuzz-api | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK |
| Aucun POST / PATCH / DELETE positif PROD | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 7 autres PROD services strictement unchanged | OK |
| Pod API PROD restart count = 0 post-deploy | OK |

---

## 15. Phrase cible finale

AS.12.1B-PROD livre : promotion PROD du hardening notifications API en API-only ; image PROD v3.5.177-tenants-directory-guard-prod -> v3.5.178-notifications-tenantguard-prod depuis source commit 5eadb345 (identique runtime DEV AS.12.1B) ; digest GHCR sha256:8c37e5f1c6df852eaa8db287feca3619eed25d8e279fa8da5951df2511e4a977 ; commit infra `e4d4523` ; rollout API PROD 60s ; GitOps MATCH=yes ; 7 autres services PROD strictement inchanges (worker, backend, Amazon workers x2, backfill scheduler, admin-v2, Client PROD inchange v3.5.190) ; validation PROD T1-T4 negatifs 401 sur 4 endpoints notifications + preserve KEY-304 /messages 6/6 401 + preserve AS.12.1A /tenants 401 + /health 200 ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (escalation badge KEY-263 + Inbox + Brouillon IA + tenant switcher + auth fonctionnels, aucune banniere, aucune regression) ; rollback PROD pret en < 5 min vers v3.5.177-tenants-directory-guard-prod ; aucune mutation DB, aucun POST/PATCH/DELETE positif PROD, aucune PII publiee, aucun secret, aucun deploy hors API PROD ; KEY-301 reste Open epic ; verdict AS.12.1B-PROD GO NOTIFICATIONS TENANTGUARD PROD READY.

STOP
