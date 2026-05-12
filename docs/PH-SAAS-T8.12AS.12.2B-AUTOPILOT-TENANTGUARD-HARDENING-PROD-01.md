# PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2B-PROD -- autopilot module tenantGuard PROD promotion
> Environnement : PROD ; API-only ; 7 autres services PROD strictement inchanges

---

## 1. VERDICT

GO AUTOPILOT TENANTGUARD PROD READY

Promotion PROD AS.12.2B reussie en API-only. Le module `/autopilot` est desormais couvert par tenantGuard runtime en PROD avec 7 (method, path) tuples proteges sur 5 paths : settings GET/POST/PATCH, draft GET, draft/consume POST, history GET, evaluate POST. Bundle minimal : aucun delta source au-dela de KEY-301 AS.12.2B (1 fichier `tenantGuard.ts` au commit `ffccbd18`, deja runtime DEV depuis v3.5.179).

Validation post-deploy PROD : T1-T7 no-auth -> 401 sur 7 endpoints autopilot, preserve KEY-304 `/messages` 6/6 + AS.12.1A `/tenants` + AS.12.1B `/notifications` -> 401, /health PROD 200, 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart. GitOps MATCH=YES. Rollout 40s.

QA Ludovic navigateur PROD confirmee : Brouillon IA auto visible + bouton "Valider et envoyer" present + autopilot settings UI charge + history visible + Inbox + tenant switcher + escalation badge + auth flow tous fonctionnels, aucune banniere erreur, aucune regression.

Aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun draftText publie en rapport. Rollback PROD pret en moins de 5 minutes vers `v3.5.178-notifications-tenantguard-prod`.

KEY-301 reste Open epic. Surfaces restantes (settings + wallet, mutations LLM, ops/returns/journal, intelligence reads) listees AS.12.2A roadmap.

---

## 2. Scope

Inclus :
- Build API PROD `v3.5.179-autopilot-tenantguard-prod` depuis source commit `ffccbd18`.
- Push GHCR (1 cible).
- Manifest `k8s/keybuzz-api-prod/deployment.yaml` (1 ligne image).
- Validation negative + preserve PROD.
- QA Ludovic navigateur PROD focus Brouillon IA.
- Rapport docs-only ASCII strict.
- Texte Linear KEY-301 prepare.

Strictement hors scope :
- Aucun build Client.
- Aucun deploy Client PROD.
- Aucun touchement Backend / Outbound worker / Amazon workers / Backfill scheduler / Admin-v2.
- Aucune mutation DB (ai_action_log etc.).
- Aucun POST / PATCH / DELETE positif PROD vers /autopilot/evaluate ou /autopilot/draft/consume.
- Aucune generation IA volontaire.
- Aucune consommation KBActions / wallet / credits.
- Aucun draftText publie meme partiellement.
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-DEV-01.md` -- DEV validation, BFF check, design.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit + roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.1B-NOTIFICATIONS-TENANTGUARD-HARDENING-PROD-01.md` -- precedente promotion API PROD.
- Rapports Brouillon IA AS.11.0.5 + AS.11.0.6 -- baseline UX critique pour focus QA.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / ffccbd18 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 2912e59 (avant patch) / 0-0 | identique | OK |
| Runtime DEV API | v3.5.179-autopilot-tenantguard-dev | identique | OK |
| Runtime PROD API pre | v3.5.178-notifications-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.179-autopilot-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 80 GB libres (15% used) | OK |

---

## 5. Build PROD

| Item | Valeur |
|---|---|
| Source commit | ffccbd188d003887e419fbb92497d952a3c290e1 |
| Source ligne | `fix(security): protect autopilot module with tenant guard (KEY-301 AS.12.2B)` |
| Tag image | v3.5.179-autopilot-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | ffccbd188d003887e419fbb92497d952a3c290e1 (= source commit) |
| KEY-308 OCI created | 2026-05-12T14:02:41Z |
| KEY-308 OCI version | v3.5.179-autopilot-tenantguard-prod |
| KEY-308 OCI source | https://github.com/keybuzzio/keybuzz-api |
| KEY-308 OCI title | keybuzz-api |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Build output | Successfully built b931d1e5499e |
| Digest GHCR | sha256:56f2796e1916d18b146c9f8e5a9fecb97456154d40c02ca3b830b59a0af76f8d |
| docker push | OK |
| Rollback tag | v3.5.178-notifications-tenantguard-prod (sha256:8c37e5f1c6df852eaa8db287feca3619eed25d8e279fa8da5951df2511e4a977) |

Source commit `ffccbd18` identique entre DEV et PROD. Build-from-Git strict. Aucun docker push hors la cible PROD API.

---

## 6. GitOps PROD

Commit infra `972cbbe` :

```
gitops(prod): promote autopilot tenantGuard API (AS.12.2B-PROD KEY-301)
```

Modifie 1 manifest uniquement :
- `k8s/keybuzz-api-prod/deployment.yaml` : `v3.5.178-notifications-tenantguard-prod` -> `v3.5.179-autopilot-tenantguard-prod`

Diff stat : `1 file changed, 1 insertion(+), 1 deletion(-)`.

Apply :
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- Rollout duration : **40 secondes**
- Pod API PROD : nouveau pod 1/1 Running, ancien Terminating puis supprime.

Aucun kubectl set / patch / edit / set env. GitOps pur. Aucune mutation hors `k8s/keybuzz-api-prod/deployment.yaml`.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.178-notifications-tenantguard-prod | **v3.5.179-autopilot-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-client | keybuzz-client-prod | v3.5.190-messages-bff-tenantguard-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API PROD = spec manifest = last-applied annotation = digest pushe sur GHCR. 7 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve, no PII)

### 8.1 Negative tests autopilot PROD (7 routes)

| # | Endpoint | Method | URL public | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T1 | /autopilot/settings | GET | https://api.keybuzz.io/autopilot/settings?tenantId=fake | 401 AUTH_REQUIRED | 401 | PASS |
| T2 | /autopilot/draft | GET | idem GET draft fake | 401 | 401 | PASS |
| T3 | /autopilot/history | GET | idem GET history fake | 401 | 401 | PASS |
| T4 | /autopilot/settings | POST | idem POST body {} | 401 | 401 | PASS |
| T5 | /autopilot/settings | PATCH | idem PATCH body {} | 401 | 401 | PASS |
| T6 | /autopilot/draft/consume | POST | idem POST fake ids | 401 | 401 | PASS |
| T7 | /autopilot/evaluate | POST | idem POST fake conv | 401 | 401 | PASS |

Aucun POST / PATCH positif emis vers `/autopilot/evaluate` ou `/autopilot/draft/consume`. Aucune generation IA, aucune consommation KBActions, aucun draftText publie.

### 8.2 Preserve previous protections PROD

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | 401 (KEY-304) | 401 | PASS |
| P2 | /messages/conversations/:fake | GET | 401 | 401 | PASS |
| P3 | /tenants | GET (no-auth) | 401 (AS.12.1A-PROD) | 401 | PASS |
| P4 | /notifications | GET | 401 (AS.12.1B-PROD) | 401 | PASS |

KEY-304, AS.12.1A-PROD, AS.12.1B-PROD integralement preserves.

### 8.3 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts (new pod post-rollout) | 0 | 0 | PASS |

### 8.4 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business Ludovic habituel |
| Inbox PROD liste conversations visible | OUI |
| Conversation detail visible | OUI |
| Brouillon IA visible automatiquement sur conv eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Autopilot settings UI charge | OUI |
| Autopilot history visible | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge KEY-263 | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| Regression visible | NON |
| 401 errors devtools sur appels autopilot legitimes | NON observe |

Le BFF Client `/api/autopilot/*` injecte X-User-Email + X-Tenant-Id depuis NextAuth -> tenantGuard accepte les appels legitimes -> Brouillon IA continue de fonctionner sans regression en PROD.

Aucune donnee client copiee dans ce rapport. Aucun draftText publie. Aucune capture ecran avec PII committee.

---

## 9. DB no-mutation (validation indirecte)

Aucun POST positif emis vers `/autopilot/evaluate` ou `/autopilot/draft/consume` pendant les tests negatifs PROD. Les requetes T6 et T7 sont rejetees par tenantGuard preHandler (401) AVANT d atteindre `evaluateAndExecute()` ou les handlers UPDATE/INSERT cote API. Aucune ligne `ai_action_log` PROD n a ete inseree par cette phase. Aucune consommation wallet / KBActions / credits.

Aucune lecture DB PROD effectuee pour mesurer pre/post counts (la consigne "no DB mutation" inclut implicitement no PROD DB queries au-dela de ce qui est strictement necessaire). La preuve indirecte (401 preHandler) suffit.

---

## 10. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert 972cbbe --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.178-notifications-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
```

Tag rollback exact : `v3.5.178-notifications-tenantguard-prod` (sha256:8c37e5f1c6df852eaa8db287feca3619eed25d8e279fa8da5951df2511e4a977).

Triggers rollback immediat :
- Brouillon IA disparait en PROD apres deploy (Inbox affiche conversations mais zone Suggestion IA vide)
- autopilot settings UI bloquee en PROD ou retour 403
- 401 errors devtools sur appels autopilot Client legitimes
- spike 5xx API PROD anormal
- spike JWT_SESSION_ERROR Client PROD sustained
- consommation anormale wallet/KBActions PROD (signal d echec gating)

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 11. PROD unchanged proof (7 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.2B-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-client-prod | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Seul `keybuzz-api-prod/keybuzz-api` est passe de v3.5.178 a v3.5.179. Aucun manifest PROD autre touche.

---

## 12. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.2B-PROD | Justification |
|---|---|---|
| Tenant switcher | OK (BFF /tenant-context/tenants inchange) | aucun changement |
| Inbox liste + detail + reply + status + assign + sav-status | OK (KEY-304 PROD preserved) | inchange |
| Escalation badge KEY-263 (BFF /api/notifications) | OK (AS.12.1B-PROD preserved) | inchange |
| Brouillon IA auto (poll /api/autopilot/draft via BFF) | OK (verifie QA Ludovic) | BFF injecte X-User-Email, tenantGuard accepte |
| Autopilot settings UI | OK | BFF settings GET/POST/PATCH safe |
| Autopilot history UI | OK | BFF history safe |
| Bouton "Valider et envoyer" (consume draft via BFF) | OK runtime (NON clique en test) | BFF draft/consume safe |
| Manual autopilot evaluate trigger | OK runtime (NON clique en test) | BFF evaluate safe |
| Plan gating handler-level (PH132-C autopilot autonomous) | OK | tenantGuard membership check active EN AMONT du plan check -> plan bypass cross-tenant ferme |
| /ai broader surface (assist / evaluate / execute / settings / wallet / ops / returns / journal / intelligence) | inchange (hors scope AS.12.2B) | AS.12.2C/D/E/F a venir |

---

## 13. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digest sha256:56f2796e..., commits 972cbbe + ffccbd18, rollout 40s, log counts 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 14. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 16 jeux de commentaires accumules.

### 14.1 KEY-301 commentaire AS.12.2B-PROD (texte cible)

```
## AS.12.2B-PROD promotion executed -- autopilot module hardened in PROD

- API PROD : v3.5.178-notifications-tenantguard-prod -> v3.5.179-autopilot-tenantguard-prod (source commit ffccbd18, same as DEV runtime v3.5.179-autopilot-tenantguard-dev).
- Client PROD strictly unchanged (v3.5.190). No Client build, no Client deploy. The 5 Client BFF autopilot routes (settings / draft / draft/consume / history / evaluate) already inject X-User-Email + X-Tenant-Id from the NextAuth session ; tenantGuard now accepts those legitimate calls and rejects unauthenticated ones.
- 6 other PROD services strictly unchanged (outbound-worker, backend, Amazon workers x2, backfill scheduler, admin-v2).
- GitOps MATCH=yes. Rollout 40s.
- Validation post-deploy PROD : all 7 autopilot (method, path) tuples return 401 unauthenticated ; KEY-304 /messages 6/6 preserved 401 ; AS.12.1A /tenants preserved 401 ; AS.12.1B /notifications preserved 401 ; /health PROD 200 ; 0 API 5xx ; 0 Client JWT_SESSION_ERROR ; 0 pod restart.
- No positive POST issued to /autopilot/evaluate or /autopilot/draft/consume -- no AI generation, no KBActions consumed, no draftText leaked.
- Ludovic QA navigateur PROD reconfirmed : Brouillon IA auto visible + "Valider et envoyer" present + autopilot settings UI loads + history visible + Inbox + tenant switcher + escalation badge + auth flow all functional, no error banner, no regression.

Plan gating handler-level (STARTER / PRO / AUTOPILOT / ENTERPRISE) is now bound to the calling user's membership in PROD : crafted tenantId targeting a different tenant's plan is rejected at tenantGuard preHandler before the plan check.

KEY-301 stays Open as an epic. Remaining sub-phases from AS.12.2A audit pending : AS.12.2D AI settings + wallet (requires BFF fix), AS.12.2C AI assist/evaluate/execute (requires Client BFF refactor), AS.12.2E AI ops + returns + journal + context, AS.12.2F AI intelligence + monitoring reads.

Rollback ready in less than 5 minutes via revert infra commit 972cbbe.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 15. Compliance AS.12.2B-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (api ffccbd18 + infra 972cbbe deja push pre-apply) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| API-only (aucun build/push Client) | OK |
| KEY-308 OCI labels non "unknown" | OK |
| KEY-309 pre-push check AVAILABLE | OK |
| Digest documente | OK (sha256:56f2796e...) |
| Rollback plan documente et tag rollback | OK section 10 (v3.5.178 sha256:8c37e5f1c6...) |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod/keybuzz-api | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB (no positive POST atteint handler) | OK |
| Aucun POST / PATCH / DELETE positif PROD | OK |
| Aucune generation IA | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 7 autres PROD services strictement unchanged | OK |
| Pod API PROD restart count = 0 post-deploy | OK |
| Plan gating PH132-C preserved et desormais protege par tenantGuard membership en amont | OK |

---

## 16. Phrase cible finale

AS.12.2B-PROD livre : promotion PROD du hardening autopilot API en API-only ; image PROD v3.5.178-notifications-tenantguard-prod -> v3.5.179-autopilot-tenantguard-prod depuis source commit ffccbd18 (identique runtime DEV) ; digest GHCR sha256:56f2796e1916d18b146c9f8e5a9fecb97456154d40c02ca3b830b59a0af76f8d ; commit infra `972cbbe` ; rollout API PROD 40s ; GitOps MATCH=yes ; 7 autres services PROD strictement inchanges (worker, backend, Amazon workers x2, backfill scheduler, admin-v2, Client PROD inchange v3.5.190) ; validation PROD T1-T7 7 endpoints autopilot 401 + preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications 401 + /health 200 ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (Brouillon IA auto + Valider et envoyer + autopilot settings + history + Inbox + tenant switcher + escalation badge + auth fonctionnels, aucune banniere, aucune regression) ; rollback PROD pret en < 5 min vers v3.5.178-notifications-tenantguard-prod ; aucune mutation DB, aucun POST/PATCH positif PROD vers /evaluate ou /draft/consume, aucune generation IA, aucune consommation KBActions, aucun draftText publie, aucune PII publiee, aucun secret, aucun deploy hors API PROD ; plan gating handler-level (PH132-C autopilot) desormais protege par tenantGuard membership check en amont ; KEY-301 reste Open epic ; verdict AS.12.2B-PROD GO AUTOPILOT TENANTGUARD PROD READY.

STOP
