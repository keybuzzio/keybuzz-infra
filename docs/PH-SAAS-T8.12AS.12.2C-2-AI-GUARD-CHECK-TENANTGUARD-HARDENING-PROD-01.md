# PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-2-PROD -- AI guard/check tenantGuard PROD promotion (API + Client)
> Environnement : PROD ; 6 autres services PROD strictement inchanges

---

## 1. VERDICT

GO AI GUARD CHECK TENANTGUARD PROD READY

Promotion PROD AS.12.2C-2 reussie en API + Client coordonne. L endpoint `POST /ai/guard/check` (read-only, no LLM, no mutation, no KBActions) est desormais couvert par tenantGuard runtime en PROD :
- **API PROD** : v3.5.181 -> **v3.5.182-ai-guard-check-tenantguard-prod** (source `1ecb6ab8`, digest `sha256:b1092dd815e9...`)
- **Client PROD** : v3.5.192 -> **v3.5.193-ai-guard-check-bff-prod** (source `bc05ec97`, digest `sha256:2dba6e1f891d...`)

Validation post-deploy PROD : T1 no-auth 401, T2 no body 400 (rejet preHandler avant atteinte handler read-only). Preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist (toutes 401 no-auth). /health PROD 200, 0 5xx API + 0 JWT_SESSION_ERROR Client + 0 pod restart. GitOps MATCH=YES. Rollouts API 21s + Client 21s. Client KEY-302 PROD bundle verify : api.keybuzz.io=2, api-dev=0, sentinel=0, Brouillon IA=4, Valider et envoyer=2.

QA Ludovic navigateur PROD confirmee : Brouillon IA auto visible + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge + auth flow fonctionnels, aucune banniere d erreur, aucune regression.

`checkAIGuard` n a aucun consumer UI dans le Client (export sans usage) -> migration BFF UX-neutre confirmee en PROD comme en DEV.

Aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun draftText publie. Rollback PROD pret en moins de 5 minutes vers API `v3.5.181-ai-assist-tenantguard-prod` + Client `v3.5.192-ai-settings-wallet-bff-prod`.

KEY-301 reste Open epic. AS.12.2C-3 (evaluate), AS.12.2C-4 (execute), AS.12.2C-5 (rules) restent a livrer.

---

## 2. Scope

Inclus :
- Build API PROD `v3.5.182-ai-guard-check-tenantguard-prod` depuis commit `1ecb6ab8`.
- Build Client PROD `v3.5.193-ai-guard-check-bff-prod` depuis commit `bc05ec97`.
- Push GHCR (2 cibles).
- Manifests `k8s/keybuzz-api-prod/deployment.yaml` + `k8s/keybuzz-client-prod/deployment.yaml` (2 lignes image).
- Validation negative + preserve PROD.
- QA Ludovic navigateur PROD.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- Aucun touchement autres services PROD (worker, backend, Amazon workers, backfill, admin-v2).
- Aucune mutation DB.
- Aucun POST positif PROD vers /ai/guard/check.
- Aucune generation IA.
- Aucune consommation KBActions / wallet / credits.
- Aucun draftText publie.
- /ai/evaluate, /ai/execute, /ai/rules (sous-phases AS.12.2C-3..5).
- /ai/global/settings, /ai/credits/add, /ai/wallet/dev/* (defer maintenu).
- Aucun changement Linear vers Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-DEV-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-PROD-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md`
- `keybuzz-client/docs/BUILD-ARGS.md`, `keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md`.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 1ecb6ab8 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / bc05ec9 / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 7565a57 / 0-0 | identique | OK |
| Runtime DEV API | v3.5.182-ai-guard-check-tenantguard-dev | identique | OK |
| Runtime DEV Client | v3.5.193-ai-guard-check-bff-dev | identique | OK |
| Runtime PROD API pre | v3.5.181-ai-assist-tenantguard-prod | identique | OK |
| Runtime PROD Client pre | v3.5.192-ai-settings-wallet-bff-prod | identique | OK |
| KEY-309 tag avail API PROD | v3.5.182-ai-guard-check-tenantguard-prod AVAILABLE | AVAILABLE | OK |
| KEY-309 tag avail Client PROD | v3.5.193-ai-guard-check-bff-prod AVAILABLE | AVAILABLE | OK |
| Disk bastion docker | > 30 GB libres | 73 GB libres (22% used) | OK |

---

## 5. Build PROD

### 5.1 API PROD

| Item | Valeur |
|---|---|
| Source commit | 1ecb6ab87651108dea4183a7f8b20dabb39f48dd |
| Tag image | v3.5.182-ai-guard-check-tenantguard-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | 1ecb6ab87651108dea4183a7f8b20dabb39f48dd |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Digest GHCR | sha256:b1092dd815e93f6de6a254e3d84c719b3f57b5662c5b68b6d03250972dd6c768 |
| Rollback tag | v3.5.181-ai-assist-tenantguard-prod (sha256:fa238d56a4f4...) |

### 5.2 Client PROD

| Item | Valeur |
|---|---|
| Source commit | bc05ec97d4a8565189459442c6053def6356eca5 |
| Tag image | v3.5.193-ai-guard-check-bff-prod |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | bc05ec97d4a8565189459442c6053def6356eca5 |
| Build args PROD | NEXT_PUBLIC_APP_ENV=production + NEXT_PUBLIC_API_URL=https://api.keybuzz.io + NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io + GIT_COMMIT_SHA + BUILD_TIME + IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| KEY-302 PROD bundle verify | api.keybuzz.io=2 (>0 OK), api-dev=0 (=0 OK), sentinel=0 (=0 OK), Brouillon IA=4 (>0 OK), Valider et envoyer=2 (>0 OK) |
| Digest GHCR | sha256:2dba6e1f891d11d82783d7a9defb70e3d5d5a3cc55a80811cd53b829659f3b2e |
| Rollback tag | v3.5.192-ai-settings-wallet-bff-prod (sha256:1f80e7b42e1f...) |

Source commits identiques DEV/PROD. Build-from-Git strict. Aucun docker push hors les 2 cibles.

---

## 6. GitOps PROD

Commit infra `71e2520` :

```
gitops(prod): promote /ai/guard/check tenantGuard API+Client (AS.12.2C-2-PROD KEY-301)
```

Modifie 2 manifests :
- `k8s/keybuzz-api-prod/deployment.yaml` : v3.5.181 -> v3.5.182
- `k8s/keybuzz-client-prod/deployment.yaml` : v3.5.192 -> v3.5.193

Apply ordre :
1. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` -> rollout 21s
2. /health API verifie 200
3. `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml` -> rollout 21s

Aucun kubectl set / patch / edit / set env. GitOps pur.

---

## 7. Runtime PROD post-deploy

| Service | Namespace | Image pre | Image post | MATCH | Pods Ready | Restarts |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | v3.5.181-ai-assist-tenantguard-prod | **v3.5.182-ai-guard-check-tenantguard-prod** | YES | 1/1 | 0 |
| keybuzz-client | keybuzz-client-prod | v3.5.192-ai-settings-wallet-bff-prod | **v3.5.193-ai-guard-check-bff-prod** | YES | 1/1 | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | identique | YES | 1/1 | inchange |
| keybuzz-backend | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | identique | YES | 1/1 | inchange |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | identique | YES | 1/1 | inchange |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | identique | YES | 1/1 | inchange |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | identique | YES | 1/1 | inchange |

Runtime API + Client PROD = spec manifest = last-applied = digest pushe sur GHCR. 6 autres services PROD strictement inchanges.

---

## 8. Validation PROD (negative + preserve, no PII)

### 8.1 Negative tests /ai/guard/check PROD

| # | Endpoint | Method | Body | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| T1 | /ai/guard/check | POST | `{"tenantId":"fake-tenant"}` | 401 AUTH_REQUIRED | 401 `{"error":"Authentication required","code":"AUTH_REQUIRED"}` | PASS |
| T2 | /ai/guard/check | POST | `{}` (no tenantId) | 400 TENANT_ID_MISSING | 400 | PASS |

Aucun POST positif PROD emis. Handler read-only `checkGuardrails` n a pas tourne.

### 8.2 Preserve previous PROD protections

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | 401 (KEY-304) | 401 | PASS |
| P2 | /tenants | GET (no-auth) | 401 (AS.12.1A-PROD) | 401 | PASS |
| P3 | /notifications | GET | 401 (AS.12.1B-PROD) | 401 | PASS |
| P4 | /autopilot/draft | GET | 401 (AS.12.2B-PROD) | 401 | PASS |
| P5 | /ai/settings | GET | 401 (AS.12.2D-PROD) | 401 | PASS |
| P6 | /ai/wallet/status | GET | 401 (AS.12.2D-PROD) | 401 | PASS |
| P7 | /ai/assist | POST | 401 (AS.12.2C-1-PROD) | 401 | PASS |

KEY-304, AS.12.1A-PROD, AS.12.1B-PROD, AS.12.2B-PROD, AS.12.2D-PROD, AS.12.2C-1-PROD integralement preserves.

### 8.3 Health + logs

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| /health PROD public | 200 | 200 | PASS |
| Logs API PROD 5 min, 5xx ou level=50 | 0 | 0 | PASS |
| Logs Client PROD 5 min, JWT_SESSION_ERROR | 0 | 0 | PASS |
| Pod API PROD restarts | 0 | 0 | PASS |

### 8.4 QA Ludovic navigateur PROD

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth PROD | compte business habituel |
| Inbox liste + detail | OUI |
| Brouillon IA visible automatiquement | OUI |
| AISuggestionSlideOver charge | OUI |
| AIDecisionPanel charge | OUI |
| Qualite reponse visuellement | inchangee |
| AIModeSwitch + wallet display | OUI |
| Tenant switcher | OUI |
| Escalation badge KEY-263 | OUI |
| Auth flow | OUI |
| Banniere erreur | NON |
| 401 errors devtools | NON observe |
| Regression visible | NON |

`checkAIGuard` n a aucun consumer UI -> migration BFF en PROD est transparente. Brouillon IA + AISuggestionSlideOver + AIDecisionPanel continuent de fonctionner.

Aucune donnee client copiee. Aucun draftText publie.

---

## 9. DB / mutation no-impact (PROD)

Aucun POST positif PROD emis vers `/ai/guard/check`. Toutes les requetes negatives sont rejetees par tenantGuard preHandler (401) ou par extractTenantId (400) AVANT atteinte du handler. Le handler est read-only (juste `checkGuardrails`) -- meme dans le pire cas d un POST valide, aucune mutation DB n est possible. Aucun LLM call. Aucune consommation KBActions / wallet / credits.

---

## 10. Rollback plan (PRET, NON EXECUTE)

Rollback PROD strict GitOps en moins de 5 minutes :

```
cd /opt/keybuzz/keybuzz-infra
git revert 71e2520 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.181-ai-assist-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml   # -> v3.5.192-ai-settings-wallet-bff-prod
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Tags rollback exacts :
- API PROD : `v3.5.181-ai-assist-tenantguard-prod` (sha256:fa238d56a4f4...)
- Client PROD : `v3.5.192-ai-settings-wallet-bff-prod` (sha256:1f80e7b42e1f...)

Triggers rollback immediat :
- Brouillon IA disparait en PROD
- AISuggestionSlideOver / AIDecisionPanel KO
- 401 errors devtools sur /api/ai/guard/check legitime (n etait pas appele auparavant non plus, mais a surveiller)
- spike 5xx API PROD anormal
- spike JWT_SESSION_ERROR Client PROD

Fenetre de surveillance recommandee : 30 min actives + 24h passives.

---

## 11. PROD unchanged proof (6 autres services)

| Namespace | Workload | Image runtime (pre + post AS.12.2C-2-PROD) |
|---|---|---|
| keybuzz-api-prod | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-backend-prod | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-backend-prod | amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod | backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2-prod | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Seuls keybuzz-api-prod/keybuzz-api et keybuzz-client-prod/keybuzz-client modifies. Aucun manifest PROD autre touche.

---

## 12. AI feature parity / anti-regression

| Surface | Statut PROD post AS.12.2C-2-PROD | Justification |
|---|---|---|
| Tenant switcher | OK | inchange |
| Inbox liste / detail / reply / status / assign / sav-status | OK (KEY-304 PROD) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B-PROD) | inchange |
| AIModeSwitch (BFF /api/ai/settings) | OK (AS.12.2D-PROD) | inchange |
| Brouillon IA auto + wallet balance | OK | verifie QA Ludovic |
| AISuggestionSlideOver + AIDecisionPanel | OK | verifie QA Ludovic |
| /ai/assist | OK (AS.12.2C-1-PROD) | inchange |
| /ai/guard/check protection | activated PROD | objectif phase |
| Channels / suppliers / commande / catalogue | inchanges | hors scope |
| /ai/evaluate, /ai/execute, /ai/rules | inchanges (sous-phases futures) | scope futur |

---

## 13. Linear text prepared

A poster apres rapport commit + push avec methode token agreee. Backlog : 23 jeux de commentaires accumules.

### 13.1 KEY-301 commentaire AS.12.2C-2-PROD (texte cible)

```
## AS.12.2C-2-PROD promotion executed -- /ai/guard/check hardened in PROD

Coordinated API + Client promotion under KEY-301.

- API PROD : v3.5.181-ai-assist-tenantguard-prod -> v3.5.182-ai-guard-check-tenantguard-prod (source commit 1ecb6ab8, identical to DEV).
- Client PROD : v3.5.192-ai-settings-wallet-bff-prod -> v3.5.193-ai-guard-check-bff-prod (source commit bc05ec97, identical to DEV). The Client patch introduces a new BFF /api/ai/guard/check (NextAuth + X-User-Email + X-Tenant-Id) and migrates ai.service.ts::checkAIGuard from browser-direct to relative path.
- 6 other PROD services strictly unchanged.
- GitOps MATCH=yes on API + Client PROD. Rollouts API 21s + Client 21s.
- Client KEY-302 PROD bundle verify : api.keybuzz.io=2, api-dev=0, sentinel=0, Brouillon IA=4, Valider et envoyer=2.

Handler is read-only (no LLM, no DB mutation, no KBActions). The Client function `checkAIGuard` has zero UI consumers, so the BFF migration is UX-neutral.

Validation post-deploy PROD : POST /ai/guard/check no-auth -> 401, no body -> 400 (rejected at preHandler). Preserve checks : KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist all 401 unauthenticated. /health PROD 200. 0 API 5xx. 0 Client JWT_SESSION_ERROR. 0 pod restart.

Ludovic QA navigateur PROD reconfirmed : Brouillon IA auto + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge all functional, no regression.

KEY-301 stays Open as an epic. Remaining LLM-mutation sub-phases pending : AS.12.2C-3 evaluate (P0 mutation log), AS.12.2C-4 execute (P0 critical), AS.12.2C-5 rules (P1 admin). All 3 require Client BFF + service migration.

Rollback ready in less than 5 minutes via revert infra commit 71e2520.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. Compliance AS.12.2C-2-PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (api 1ecb6ab8 + Client bc05ec97 + infra 71e2520) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-308 OCI labels non "unknown" (API + Client) | OK |
| KEY-302 Client bundle PROD verify | OK (api.keybuzz.io>0, api-dev=0, sentinel=0, Brouillon IA + Valider et envoyer presents) |
| KEY-309 pre-push tag check AVAILABLE (API + Client) | OK |
| Digests documentes | OK (sha256:b1092dd815e9... + sha256:2dba6e1f891d...) |
| Rollback plan documente et tags rollback | OK section 10 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit / set env | OK |
| Aucun deploy hors keybuzz-api-prod + keybuzz-client-prod | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK |
| Aucun POST positif PROD vers /ai/guard/check | OK |
| Aucune generation IA | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 NOT marked Done | OK (reste Open epic) |
| 6 autres PROD services strictement unchanged | OK |
| Pod API + Client PROD restart count = 0 post-deploy | OK |

---

## 15. Phrase cible finale

AS.12.2C-2-PROD livre : promotion PROD coordonnee API + Client du hardening /ai/guard/check (handler read-only) ; API PROD v3.5.181-ai-assist-tenantguard-prod -> v3.5.182-ai-guard-check-tenantguard-prod (commit 1ecb6ab8, digest sha256:b1092dd815e93f6de6a254e3d84c719b3f57b5662c5b68b6d03250972dd6c768) ; Client PROD v3.5.192-ai-settings-wallet-bff-prod -> v3.5.193-ai-guard-check-bff-prod (commit bc05ec97, digest sha256:2dba6e1f891d11d82783d7a9defb70e3d5d5a3cc55a80811cd53b829659f3b2e) ; Client patch ajoute BFF `/api/ai/guard/check` (NextAuth + X-User-Email + X-Tenant-Id) + migre `checkAIGuard` vers path relatif ; commit infra `71e2520` ; rollouts API 21s + Client 21s ; GitOps MATCH=yes ; KEY-302 Client PROD bundle verify api.keybuzz.io=2 api-dev=0 sentinel=0 Brouillon IA=4 Valider et envoyer=2 ; 6 autres services PROD strictement inchanges ; validation PROD T1 no-auth 401 + T2 no body 400 + preserve KEY-304 /messages + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist 401 + /health 200 ; logs PROD 5min 0 5xx + 0 JWT_SESSION_ERROR + 0 restart ; QA Ludovic navigateur PROD reconfirmee (Brouillon IA + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge fonctionnels, aucune banniere, aucune regression) ; checkAIGuard sans consumer UI -> migration BFF UX-neutre ; rollback PROD pret en < 5 min vers API v3.5.181 + Client v3.5.192 ; aucune mutation DB, aucun POST positif PROD, aucune generation LLM, aucune consommation KBActions/wallet/credits, aucun draftText, aucune PII publiee, aucun secret, aucun deploy hors API+Client PROD ; KEY-301 reste Open epic ; AS.12.2C-3/4/5 (evaluate, execute, rules) restent a livrer ; verdict AS.12.2C-2-PROD GO AI GUARD CHECK TENANTGUARD PROD READY.

STOP
