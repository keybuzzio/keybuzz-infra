# PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2D-PROD -- AI settings + wallet tenantGuard PROD promotion (API + Client)
> Environnement : PROD ; 6 autres services PROD strictement inchanges

---

## 1. VERDICT

GO AI SETTINGS WALLET TENANTGUARD PROD READY

Promotion PROD AS.12.2D livree en API + Client coordonne. Le module AI settings + wallet est desormais couvert par tenantGuard runtime en PROD :
- **API PROD** : v3.5.179 -> **v3.5.180-ai-settings-wallet-tenantguard-prod** (source `e7ad363f`, digest `sha256:bed42ecb...`) -- 11 PROTECTED_ROUTES tuples actifs.
- **Client PROD** : v3.5.190 -> **v3.5.192-ai-settings-wallet-bff-prod** (source `a46eb5f`, digest `sha256:1f80e7b4...`) -- 4 BFF AI migres de Cookie-forward vers injection NextAuth `X-User-Email` + `X-Tenant-Id` + 2 fonctions `ai.service.ts` (`getAISettings`, `getAIWalletStatus`) migrees vers paths relatifs `/api/ai/*`.

Validation post-deploy PROD : T1-T11 11 endpoints AI settings + wallet -> 401, preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot 7 routes -> 401, /health PROD 200, 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart. GitOps MATCH=YES sur API + Client. Rollout API 51s + Client 20s.

QA Ludovic navigateur PROD confirmee : AIModeSwitch charge + Brouillon IA auto visible (les calls `getAISettings` + `getAIWalletStatus` passent maintenant par BFF authentifie) + wallet balance display + autopilot settings + Inbox + tenant switcher + escalation badge + auth flow fonctionnels, aucune banniere d erreur, aucune regression.

Aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun wallet debit/credit, aucun draftText publie, aucun secret. Rollback PROD pret en moins de 5 minutes vers API `v3.5.179-autopilot-tenantguard-prod` + Client `v3.5.190-messages-bff-tenantguard-prod`.

KEY-301 reste Open epic. Defer maintenu : `/ai/global/settings`, `/ai/credits/add`, `/ai/wallet/dev/*`. Surfaces restantes (AS.12.2C mutations LLM, AS.12.2E ops/returns/journal, AS.12.2F intelligence reads) listees roadmap AS.12.2A.

---

## 2. Scope

Inclus :
- Build API PROD `v3.5.180-ai-settings-wallet-tenantguard-prod` depuis commit `e7ad363f`.
- Build Client PROD `v3.5.192-ai-settings-wallet-bff-prod` depuis commit `a46eb5f`.
- Push GHCR (2 cibles).
- Manifests `k8s/keybuzz-api-prod/deployment.yaml` + `k8s/keybuzz-client-prod/deployment.yaml`.
- Validation negative + preserve PROD.
- QA Ludovic navigateur PROD focus AIModeSwitch + Brouillon IA + wallet.
- Rapport docs-only ASCII strict.
- Texte Linear KEY-301 prepare.

Strictement hors scope :
- Aucun touchement Backend / Outbound worker / Amazon workers / Backfill scheduler / Admin-v2.
- Aucune mutation DB (ai_action_log, wallet, etc.).
- Aucun POST / PATCH / DELETE positif PROD.
- Aucune generation IA volontaire.
- Aucune consommation KBActions / wallet / credits.
- Aucun draftText publie.
- /ai/global/settings, /ai/credits/add, /ai/wallet/dev/* (defer maintenu).
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-DEV-01.md` -- DEV validation + design.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-PROD-01.md` -- promotion API PROD precedente.
- `keybuzz-client/docs/BUILD-ARGS.md`, `keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md`.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / e7ad363f / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / a46eb5f / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 29a46b9 / 0-0 | identique | OK |
| Runtime DEV API | v3.5.180-ai-settings-wallet-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.192-ai-settings-wallet-bff-dev | identique | OK |
| Runtime PROD API pre | v3.5.179-autopilot-tenantguard-prod | identique | OK |
| Runtime PROD Client pre | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.180-ai-settings-wallet-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| KEY-309 tag avail Client PROD | v3.5.192-ai-settings-wallet-bff-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 78 GB libres (17% used) | OK |

---

## 5. Build PROD

### 5.1 API PROD

| Item | Valeur |
|---|---|
| Source commit | e7ad363f08d1541bdd9c8d453bb28077366d6f71 |
| Tag image | v3.5.180-ai-settings-wallet-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | e7ad363f08d1541bdd9c8d453bb28077366d6f71 |
| KEY-308 OCI created | 2026-05-12T15:05:11Z |
| KEY-308 OCI version | v3.5.180-ai-settings-wallet-tenantguard-prod |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Digest GHCR | sha256:bed42ecb7f6e42dbe1e0bee2c60480a0939dc3be200b88c7d72756356931fe7b |
| Rollback tag | v3.5.179-autopilot-tenantguard-prod (sha256:56f2796e1916...) |

### 5.2 Client PROD

| Item | Valeur |
|---|---|
| Source commit | a46eb5fe788c2fb0f53f2f6eb9c6dbb0ea201260 |
| Tag image | v3.5.192-ai-settings-wallet-bff-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | a46eb5fe788c2fb0f53f2f6eb9c6dbb0ea201260 |
| KEY-308 OCI created | 2026-05-12T15:07:27Z |
| KEY-308 OCI version | v3.5.192-ai-settings-wallet-bff-prod |
| Build args PROD | NEXT_PUBLIC_APP_ENV=production + NEXT_PUBLIC_API_URL=https://api.keybuzz.io + NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io + GIT_COMMIT_SHA + BUILD_TIME + IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| KEY-302 PROD bundle verify | api.keybuzz.io=2 (>0 OK), api-dev=0 (=0 OK), sentinel=0 (=0 OK), Brouillon IA=4 (>0 OK), Valider et envoyer=2 (>0 OK) |
| Digest GHCR | sha256:1f80e7b42e1ff55bc051070d9e20b2fb0d324f4166391a66311290d47810fb5e |
| Rollback tag | v3.5.190-messages-bff-tenantguard-prod (sha256:0267469d8409...) |

Build-from-Git strict. Aucun docker push hors les 2 cibles. Source commits API + Client identiques entre DEV et PROD.

---

## 6. GitOps PROD

Commit infra `6312030` :

```
gitops(prod): promote AI settings + wallet tenantGuard API+Client (AS.12.2D-PROD KEY-301)
```

Modifie 2 manifests :
- `k8s/keybuzz-api-prod/deployment.yaml` : v3.5.179 -> v3.5.180
- `k8s/keybuzz-client-prod/deployment.yaml` : v3.5.190 -> v3.5.192

Diff stat : `2 files changed, 2 insertions(+), 2 deletions(-)`.

Apply ordre :
1. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` -> rollout 51s
2. /health API verifie 200
3. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml` -> rollout 20s

Aucun kubectl set / patch / edit / set env. GitOps pur. Aucune mutation hors les 2 manifests.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.179-autopilot-tenantguard-prod | **v3.5.180-ai-settings-wallet-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-client | keybuzz-client-prod | v3.5.190-messages-bff-tenantguard-prod | **v3.5.192-ai-settings-wallet-bff-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API + Client PROD = spec manifest = last-applied = digest pushe sur GHCR. 6 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve, no PII)

### 8.1 Negative tests AI settings + wallet PROD (11)

| # | Endpoint | Method | URL public | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T1 | /ai/settings | GET | https://api.keybuzz.io/ai/settings?tenantId=fake | 401 | 401 | PASS |
| T2 | /ai/wallet/status | GET | idem | 401 | 401 | PASS |
| T3 | /ai/wallet/ledger | GET | idem | 401 | 401 | PASS |
| T4 | /ai/wallet/actions/ledger | GET | idem | 401 | 401 | PASS |
| T5 | /ai/credits/wallet | GET | idem | 401 | 401 | PASS |
| T6 | /ai/credits/ledger | GET | idem | 401 | 401 | PASS |
| T7 | /ai/budget/overview | GET | idem | 401 | 401 | PASS |
| T8 | /ai/budget/alerts | GET | idem | 401 | 401 | PASS |
| T9 | /ai/settings | PATCH | idem | 401 | 401 | PASS |
| T10 | /ai/budget/settings | PATCH | idem | 401 | 401 | PASS |
| T11 | /ai/budget/check | POST | idem | 401 | 401 | PASS |

11/11 PASS. Aucun PATCH / POST positif emis. Aucune mutation. Aucune generation IA. Aucune consommation wallet.

### 8.2 Preserve previous protections PROD

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | 401 (KEY-304) | 401 | PASS |
| P2 | /tenants | GET | 401 (AS.12.1A-PROD) | 401 | PASS |
| P3 | /notifications | GET | 401 (AS.12.1B-PROD) | 401 | PASS |
| P4 | /autopilot/draft | GET | 401 (AS.12.2B-PROD) | 401 | PASS |
| P5 | /autopilot/settings | GET | 401 (AS.12.2B-PROD) | 401 | PASS |

KEY-304, AS.12.1A-PROD, AS.12.1B-PROD, AS.12.2B-PROD integralement preserves.

### 8.3 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts (new pod) | 0 | 0 | PASS |

### 8.4 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business habituel |
| AIModeSwitch charge correctement | OUI |
| Brouillon IA visible automatiquement sur conv eligible | OUI |
| Wallet balance / KBActions display si visible UI | OUI |
| Autopilot settings UI charge | OUI (deja proteges AS.12.2B-PROD) |
| Inbox liste + detail visible | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge KEY-263 | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| 401 errors devtools sur appels Client legitimes | NON observe |
| Regression visible | NON |

Le BFF Client `/api/ai/settings` + `/api/ai/wallet/status` (deux migration) + `/api/ai/wallet/ledger` + `/api/ai/wallet/settings` injectent maintenant X-User-Email + X-Tenant-Id depuis NextAuth -> tenantGuard accepte les appels legitimes -> AIModeSwitch + Brouillon IA + wallet display continuent de fonctionner sans regression en PROD.

Aucune donnee client copiee. Aucun draftText publie. Aucune capture ecran PII committee.

---

## 9. DB / mutation no-impact (PROD)

Aucun POST / PATCH positif emis vers `/ai/settings`, `/ai/budget/settings`, ou `/ai/budget/check` en PROD. Toutes les requetes negatives PROD sont rejetees par tenantGuard preHandler (401) AVANT atteinte du handler API. Aucun UPDATE/INSERT execute. Aucune ligne wallet/credits/budget mutee. Aucune consommation KBActions. Aucune lecture DB PROD effectuee par cette phase au-dela de ce qui est strictement necessaire (preuve indirecte par 401 preHandler).

---

## 10. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert 6312030 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.179-autopilot-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml   # -> v3.5.190-messages-bff-tenantguard-prod
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Tags rollback exacts :
- API PROD : `v3.5.179-autopilot-tenantguard-prod` (sha256:56f2796e1916...)
- Client PROD : `v3.5.190-messages-bff-tenantguard-prod` (sha256:0267469d8409...)

Triggers rollback immediat :
- AIModeSwitch ne charge plus en PROD (settings GET via BFF echoue de maniere non transitoire)
- Brouillon IA disparait en PROD (getAISettings + getAIWalletStatus fail cascade)
- wallet balance disparait UI
- spike 5xx API PROD anormal
- spike JWT_SESSION_ERROR Client PROD sustained
- 403 NOT_MEMBER injustifie sur compte legitime PROD

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 11. PROD unchanged proof (6 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.2D-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

`keybuzz-api-prod/keybuzz-api` passe de v3.5.179 a v3.5.180. `keybuzz-client-prod/keybuzz-client` passe de v3.5.190 a v3.5.192. Aucun manifest PROD autre touche.

---

## 12. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.2D-PROD | Justification |
|---|---|---|
| AIModeSwitch (mode IA) | OK (BFF /api/ai/settings inject X-User-Email) | verifie QA Ludovic |
| Brouillon IA auto (poll /api/autopilot/draft + getAISettings + getAIWalletStatus) | OK | tous 3 calls via BFF authentifie |
| Wallet balance / KBActions display | OK (BFF /api/ai/wallet/status inject X-User-Email) | verifie QA Ludovic |
| Autopilot settings UI | OK (AS.12.2B-PROD) | inchange |
| Inbox liste / detail / reply / status / assign / sav-status | OK (KEY-304 PROD) | inchange |
| Escalation badge KEY-263 (BFF /api/notifications) | OK (AS.12.1B-PROD) | inchange |
| Tenant switcher (BFF /tenant-context/tenants) | OK | inchange |
| Channels / suppliers / commande / catalogue | inchanges | hors scope KEY-301 AS.12.2D |
| /ai/global/settings, /ai/credits/add, /ai/wallet/dev/* | inchanges (defer maintenu) | scope futur |

---

## 13. No fake metrics / no fake events

Aucun event GA4 / CAPI / Meta / LinkedIn / TikTok genere pendant la phase. Aucun KPI dashboard touche. Aucun pourcentage non prouve. Toutes les valeurs (digests sha256:bed42ecb..., sha256:1f80e7b4..., commits 6312030 + e7ad363f + a46eb5f, rollouts 51s + 20s, log counts 0 5xx + 0 JWT_SESSION_ERROR + 0 restart, runtime images PROD post-deploy) sont issues de mesures directes runtime ou GHCR.

---

## 14. Linear text prepared

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 18 jeux de commentaires accumules.

### 14.1 KEY-301 commentaire AS.12.2D-PROD (texte cible)

```
## AS.12.2D-PROD promotion executed -- AI settings + wallet hardened in PROD

API + Client coordinated promotion under KEY-301.

- API PROD : v3.5.179-autopilot-tenantguard-prod -> v3.5.180-ai-settings-wallet-tenantguard-prod (source commit e7ad363f, identical to DEV runtime).
- Client PROD : v3.5.190-messages-bff-tenantguard-prod -> v3.5.192-ai-settings-wallet-bff-prod (source commit a46eb5f, identical to DEV runtime). The Client patch migrates 4 AI BFF routes (settings + wallet/status + wallet/ledger + wallet/settings) from cookie-forward to NextAuth X-User-Email + X-Tenant-Id injection, and migrates 2 service functions (getAISettings, getAIWalletStatus) from browser-direct to relative BFF paths.
- 6 other PROD services strictly unchanged (outbound-worker, backend, Amazon workers x2, backfill scheduler, admin-v2).
- GitOps MATCH=yes on API + Client PROD. Rollout API 51s + Client 20s.
- Client KEY-302 PROD bundle verify : api.keybuzz.io=2, api-dev=0, sentinel=0, Brouillon IA=4, Valider et envoyer=2.

Validation post-deploy PROD : all 11 AI settings + wallet endpoints return 401 unauthenticated (8 GET + 2 PATCH + 1 POST). KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot 7 preserved 401. /health PROD 200. 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart.

No positive POST/PATCH issued ; no AI generation, no KBActions consumed, no wallet debit/credit, no draftText leaked.

Ludovic QA navigateur PROD reconfirmed : AIModeSwitch loads + Brouillon IA auto visible + wallet balance display + Inbox + autopilot settings + tenant switcher + escalation badge + auth flow all functional, no error banner, no regression.

Plan gating handler-level (STARTER / PRO / AUTOPILOT / ENTERPRISE) is now bound to the calling user's membership in PROD on the AI settings + wallet surface (in addition to messages + tenants + notifications + autopilot already protected in earlier PROD promotions).

Deferred (explicit, unchanged in this promotion) : /ai/global/settings (admin no BFF), /ai/credits/add (financial mutation), /ai/wallet/dev/* (DEV-only mutations). Remaining KEY-301 sub-phases : AS.12.2C assist/evaluate/execute mutations, AS.12.2E ops + returns + journal + context, AS.12.2F AI intelligence + monitoring reads.

Rollback ready in less than 5 minutes via revert infra commit 6312030.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 15. Compliance AS.12.2D-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (api e7ad363f + Client a46eb5f + infra 6312030) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-308 OCI labels non "unknown" (API + Client) | OK |
| KEY-302 Client bundle PROD verify (api.keybuzz.io>0, api-dev=0, sentinel=0, Brouillon IA + Valider et envoyer presents) | OK |
| KEY-309 pre-push tag check AVAILABLE (API + Client) | OK |
| Digests documentes | OK (sha256:bed42ecb... + sha256:1f80e7b4...) |
| Rollback plan documente et tags rollback | OK section 10 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod + keybuzz-client-prod | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK |
| Aucun POST / PATCH / DELETE positif PROD | OK |
| Aucune generation IA | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 6 autres PROD services strictement unchanged | OK |
| Pod API PROD + Client PROD restart count = 0 post-deploy | OK |
| Defer documente : /ai/global/settings + /ai/credits/add + /ai/wallet/dev/* | OK |

---

## 16. Phrase cible finale

AS.12.2D-PROD livre : promotion PROD coordonnee API + Client du hardening AI settings + wallet ; API PROD v3.5.179-autopilot-tenantguard-prod -> v3.5.180-ai-settings-wallet-tenantguard-prod (commit e7ad363f, digest sha256:bed42ecb7f6e42dbe1e0bee2c60480a0939dc3be200b88c7d72756356931fe7b) ; Client PROD v3.5.190-messages-bff-tenantguard-prod -> v3.5.192-ai-settings-wallet-bff-prod (commit a46eb5f, digest sha256:1f80e7b42e1ff55bc051070d9e20b2fb0d324f4166391a66311290d47810fb5e) ; Client patch migre 4 BFF AI de Cookie-forward vers injection NextAuth `X-User-Email` + `X-Tenant-Id` et 2 fonctions ai.service.ts vers paths relatifs `/api/ai/*` ; commit infra `6312030` ; rollouts API 51s + Client 20s ; GitOps MATCH=yes ; KEY-302 Client PROD bundle verify api.keybuzz.io=2 api-dev=0 sentinel=0 Brouillon IA=4 Valider et envoyer=2 ; validation PROD T1-T11 11 endpoints AI settings + wallet 401 + preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot 401 ; /health 200 ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (AIModeSwitch + Brouillon IA + wallet display + Inbox + autopilot settings + tenant switcher + escalation badge + auth fonctionnels, aucune banniere, aucune regression) ; 6 autres services PROD strictement inchanges ; rollback PROD pret en < 5 min vers API v3.5.179 + Client v3.5.190 ; aucune mutation DB, aucun POST/PATCH positif PROD, aucune generation IA, aucune consommation KBActions/wallet/credits, aucun draftText publie, aucune PII publiee, aucun secret, aucun deploy hors API+Client PROD ; defer maintenu /ai/global/settings + /ai/credits/add + /ai/wallet/dev/* ; KEY-301 reste Open epic ; verdict AS.12.2D-PROD GO AI SETTINGS WALLET TENANTGUARD PROD READY.

STOP
