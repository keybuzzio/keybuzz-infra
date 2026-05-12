# PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-2 -- AI guard/check (read-only) tenantGuard hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO AI GUARD CHECK TENANTGUARD DEV READY

Endpoint `POST /ai/guard/check` (read-only handler, pas de LLM, pas de mutation DB, pas de KBActions) est desormais couvert par tenantGuard runtime en DEV. Patch coordonne :
- API : +1 entry PROTECTED_ROUTES static `POST /ai/guard/check`.
- Client : nouveau BFF `app/api/ai/guard/check/route.ts` (NextAuth + injection X-User-Email + X-Tenant-Id).
- Client : `ai.service.ts::checkAIGuard` migre de browser-direct `${baseUrl}/ai/guard/check` vers relative `/api/ai/guard/check`.

Validation 4/4 PASS : no-auth 401, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400. Preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist (toutes 401 no-auth). Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable. Logs API DEV 0 5xx. PROD strictement inchange 8 services.

Note importante : `checkAIGuard` n a **aucun consumer UI** dans `keybuzz-client/src` (export sans usage). La migration vers BFF est donc UX-neutre. QA Ludovic navigateur DEV reconfirmee : Brouillon IA auto + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge + auth fonctionnels.

Aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun draftText publie. KEY-301 reste Open.

---

## 2. Scope

Inclus :
- API tenantGuard : +1 entry PROTECTED_ROUTES static.
- Client BFF : nouveau fichier `app/api/ai/guard/check/route.ts` (POST only, NextAuth-bound).
- Client `ai.service.ts` : 1 fonction migree vers path relatif `/api/ai/...`.
- Build API + Client DEV + GitOps DEV.
- Validation negative + preserve.

Hors scope :
- /ai/evaluate, /ai/execute, /ai/rules (sous-phases AS.12.2C-3..5).
- POST positif vers /ai/guard/check (par precaution, meme si read-only).
- /ai/global/settings + /ai/credits/add + /ai/wallet/dev/* (defer maintenu).
- PROD deploy.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-1-AI-ASSIST-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md` -- precedente.
- `keybuzz-api/src/modules/ai/routes.ts` -- handler POST /guard/check ligne 220-231 (read-only).
- `keybuzz-client/src/services/ai.service.ts` -- checkAIGuard ligne 156.
- `keybuzz-client/app/api/ai/wallet/status/route.ts` -- pattern BFF reference (AS.12.2D).

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / 28a31d96 / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / a46eb5f / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 568d45b / 0-0 | identique | OK |
| Runtime DEV API pre | v3.5.181-ai-assist-tenantguard-dev | identique | OK |
| Runtime DEV Client pre | v3.5.192-ai-settings-wallet-bff-dev | identique | OK |
| Runtime PROD API | v3.5.181-ai-assist-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.192-ai-settings-wallet-bff-prod | identique | OK |
| KEY-309 tag avail API | v3.5.182-ai-guard-check-tenantguard-dev AVAILABLE | AVAILABLE | OK |
| KEY-309 tag avail Client | v3.5.193-ai-guard-check-bff-dev AVAILABLE | AVAILABLE | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. Audit + design

### 5.1 Handler API source

Source `keybuzz-api/src/modules/ai/routes.ts:220-231` :

```typescript
app.post('/guard/check', async (request, reply) => {
  const { tenantId, conversationId } = request.body;
  if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
  try {
    const pool = await getPool();
    const guard = await checkGuardrails(pool, tenantId, conversationId);
    return reply.send({ ...guard, checked_at: new Date().toISOString() });
  } catch (error) {
    request.log.error(error);
    return reply.status(503).send({ error: 'Database unavailable' });
  }
});
```

Read-only confirme : aucune INSERT/UPDATE/DELETE ; aucun appel LLM ; aucune consommation wallet/KBActions. `checkGuardrails` lit ai_settings + autres tables sans muter.

### 5.2 Client consumer audit

| Function | Source | Path | Consumers UI |
|---|---|---|---|
| `checkAIGuard` | `ai.service.ts:156` | `${baseUrl}/ai/guard/check` browser-direct | ZERO (export sans usage detecte) |

Aucun appel `checkAIGuard(...)` dans `keybuzz-client/src/**/*.tsx`. La migration vers BFF n a donc aucun impact UX.

### 5.3 Design

| Aspect | Decision |
|---|---|
| API pattern | PROTECTED_ROUTES static +1 entry POST /ai/guard/check |
| BFF Client | nouveau fichier POST-only + NextAuth check 401 + injection X-User-Email + X-Tenant-Id |
| Client service migration | `checkAIGuard` -> `/api/ai/guard/check` relatif |
| Cookie forward | non (X-User-Email only, pattern AS.12.2B/2D) |

---

## 6. Patch summary

| Repo | HEAD avant | HEAD apres | Fichier |
|---|---|---|---|
| keybuzz-api | 28a31d96 | 1ecb6ab87651108dea4183a7f8b20dabb39f48dd | src/plugins/tenantGuard.ts (+13 / -3) |
| keybuzz-client | a46eb5f | bc05ec97d4a8565189459442c6053def6356eca5 | 2 fichiers (+71 / -1) |
| keybuzz-infra | 568d45b | f14b119 | 2 manifests DEV (2 +/2 -) |

Detail Client :
- `app/api/ai/guard/check/route.ts` (nouveau, 60 lignes) -- POST only avec session NextAuth + injection X-User-Email + X-Tenant-Id.
- `src/services/ai.service.ts` -- `checkAIGuard` migre vers `fetch('/api/ai/guard/check', ...)` direct (path relatif).

---

## 7. Build

### 7.1 API

| Item | Valeur |
|---|---|
| Source commit | 1ecb6ab87651108dea4183a7f8b20dabb39f48dd |
| Tag image | v3.5.182-ai-guard-check-tenantguard-dev |
| KEY-308 OCI revision | 1ecb6ab87651108dea4183a7f8b20dabb39f48dd |
| KEY-309 pre-push check | AVAILABLE |
| Digest GHCR | sha256:254c57e1a50ebec419c9939ca1bd6d9c7f55d5cdffd59ac2c1fe8cbd4b1d30bb |
| Rollback tag | v3.5.181-ai-assist-tenantguard-dev |

### 7.2 Client

| Item | Valeur |
|---|---|
| Source commit | bc05ec97d4a8565189459442c6053def6356eca5 |
| Tag image | v3.5.193-ai-guard-check-bff-dev |
| KEY-308 OCI revision | bc05ec97d4a8565189459442c6053def6356eca5 |
| KEY-309 pre-push check | AVAILABLE |
| Build args DEV | NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io + ... |
| KEY-302 bundle verify | api-dev=2 sentinel=0 api-prod=0 OK |
| Digest GHCR | sha256:9da664991ef206f2546b1b3ecc25713d4c101ab8e9ef4f11618f2b2c312b19e3 |
| Rollback tag | v3.5.192-ai-settings-wallet-bff-dev |

---

## 8. GitOps deploy DEV

Commit infra `f14b119` :

```
deploy(dev): protect /ai/guard/check via tenant guard + new BFF (KEY-301 AS.12.2C-2)
```

Modifie 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : v3.5.181 -> v3.5.182
- `k8s/keybuzz-client-dev/deployment.yaml` : v3.5.192 -> v3.5.193

Apply ordre :
1. API DEV -> rollout OK
2. Client DEV -> rollout OK

Runtime DEV post-apply :
- API : v3.5.182-ai-guard-check-tenantguard-dev MATCH=YES
- Client : v3.5.193-ai-guard-check-bff-dev MATCH=YES
- /health DEV : 200 ok

---

## 9. Validation negative (no PII, no mutation)

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | POST /ai/guard/check no-auth | curl https public body `{"tenantId":"fake-tenant"}` | 401 AUTH_REQUIRED | 401 | PASS |
| T2 | POST /ai/guard/check bogus user (in-cluster) | x-user-email=bogus@example.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |
| T3 | POST /ai/guard/check ludo cross-tenant SWITAA (in-cluster) | x-user-email=ludo.gonthier@gmail.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |
| T4 | POST /ai/guard/check no tenantId valid email (in-cluster) | x-user-email=switaa26@gmail.com body `{}` | 400 TENANT_ID_MISSING | 400 | PASS |

4/4 PASS. Aucun POST positif emis (par precaution, meme si endpoint read-only). Handler `checkGuardrails` n a pas tourne sur les tests negatifs (rejet preHandler).

---

## 10. Preserve checks

| # | Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | /messages/conversations no-auth | https://api-dev.keybuzz.io/messages/conversations?tenantId=fake | 401 | 401 | PASS |
| P2 | /tenants no-auth | https://api-dev.keybuzz.io/tenants | 401 | 401 | PASS |
| P3 | /notifications no-auth | https://api-dev.keybuzz.io/notifications?tenantId=fake | 401 | 401 | PASS |
| P4 | /autopilot/draft no-auth | https://api-dev.keybuzz.io/autopilot/draft?tenantId=fake&conversationId=fake | 401 | 401 | PASS |
| P5 | /ai/settings no-auth | https://api-dev.keybuzz.io/ai/settings?tenantId=fake | 401 | 401 | PASS |
| P6 | /ai/wallet/status no-auth | https://api-dev.keybuzz.io/ai/wallet/status?tenantId=fake | 401 | 401 | PASS |
| P7 | /ai/assist no-auth | POST https://api-dev.keybuzz.io/ai/assist | 401 | 401 | PASS |

KEY-304, AS.12.1A, AS.12.1B, AS.12.2B, AS.12.2D, AS.12.2C-1 integralement preserves.

---

## 11. Smoke V1 + logs

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Aucune nouvelle deterioration vs pre-deploy.

| Source | Filtre | Count |
|---|---|---|
| API DEV 5min | statusCode 5xx ou level=50 | 0 |

---

## 12. QA Ludovic navigateur DEV

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth DEV | switaa26@gmail.com (SWITAA AUTOPILOT) |
| Inbox liste + detail | OUI |
| Brouillon IA auto visible | OUI |
| AISuggestionSlideOver charge | OUI |
| AIDecisionPanel charge | OUI |
| Qualite reponse visuellement | inchangee |
| AIModeSwitch + wallet display (AS.12.2D) | OUI |
| Tenant switcher | OUI |
| Escalation badge | OUI |
| Banniere erreur | NON |
| 401 errors devtools sur Client legitime | NON observe |
| Regression visible | NON |

`checkAIGuard` n a aucun consumer UI -- migration BFF transparente UX. Brouillon IA + AISuggestionSlideOver continuent de fonctionner sans aucun impact.

---

## 13. Rollback plan

```
cd /opt/keybuzz/keybuzz-infra
git revert f14b119 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.181
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml   # -> v3.5.192
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=240s
```

PROD inchange (rien a rollback PROD).

---

## 14. PROD unchanged proof

| Service | Image |
|---|---|
| keybuzz-api PROD | v3.5.181-ai-assist-tenantguard-prod |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod |
| keybuzz-client PROD | v3.5.192-ai-settings-wallet-bff-prod |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod |
| amazon-items-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| amazon-orders-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| backfill-scheduler PROD | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche.

---

## 15. Linear text prepared

A poster apres rapport commit + push avec methode token agreee. Backlog : 22 jeux de commentaires accumules.

### 15.1 KEY-301 commentaire (texte cible)

```
## AS.12.2C-2 AI guard/check (read-only) hardened in DEV

Second LLM-mutation sub-phase under KEY-301 (after AS.12.2C-1 assist). The /ai/guard/check endpoint is now covered by tenantGuard runtime in DEV with a coordinated API + Client patch :

- API : +1 PROTECTED_ROUTES static POST /ai/guard/check.
- Client : new BFF /api/ai/guard/check (NextAuth + X-User-Email + X-Tenant-Id) + ai.service.ts checkAIGuard migrated from browser-direct to relative path.

Handler is read-only (no LLM, no DB mutation, no KBActions). The Client function `checkAIGuard` has zero UI consumers in the current codebase (exported but never called), so the BFF migration is UX-neutral.

Validation negative 4/4 PASS : no-auth 401, bogus 403, cross-tenant 403, missing tenantId 400. No positive POST issued. No mutation. Preserve checks : KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist all 401 unauthenticated.

Runtime DEV : API v3.5.182-ai-guard-check-tenantguard-dev + Client v3.5.193-ai-guard-check-bff-dev. GitOps MATCH=yes. Logs API DEV 5min : 0 5xx. Smoke V1 stable.

Ludovic QA navigateur DEV with switaa26@gmail.com (SWITAA AUTOPILOT) confirmed : Brouillon IA auto + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge all functional, no regression.

PROD strictly unchanged (8 services).

Remaining LLM-mutation sub-phases pending : AS.12.2C-3 evaluate (P0 mutation log), AS.12.2C-4 execute (P0 critical), AS.12.2C-5 rules (P1 admin).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 16. Compliance

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API 1ecb6ab8 + Client bc05ec97 + infra f14b119) | OK |
| Build-from-Git | OK |
| KEY-308 OCI labels non "unknown" (API + Client) | OK |
| KEY-309 pre-push check AVAILABLE (API + Client) | OK |
| KEY-302 Client bundle verify | OK (api-dev=2, sentinel=0, api-prod=0) |
| Digests documentes | OK |
| Rollback plan documente | OK |
| GitOps strict | OK |
| Aucune mutation DB | OK (handler read-only + no POST positif) |
| Aucun POST positif | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions/wallet | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Smoke V1 DEV stable | OK |
| QA Ludovic DEV OK | OK |

---

## 17. Phrase cible finale

AS.12.2C-2 livre : endpoint `POST /ai/guard/check` (read-only handler, pas de LLM, pas de mutation DB, pas de KBActions) protege par tenantGuard runtime en DEV via 1 PROTECTED_ROUTES static + nouveau BFF Client `/api/ai/guard/check` + migration `ai.service.ts::checkAIGuard` vers path relatif ; tests negatifs 4/4 PASS (no-auth 401, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400) ; preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings + wallet + AS.12.2C-1 /ai/assist 401 ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK avec switaa26@gmail.com (SWITAA AUTOPILOT) : Brouillon IA + AISuggestionSlideOver + AIDecisionPanel + Inbox + tenant switcher + escalation badge fonctionnels, aucune regression ; checkAIGuard sans consumer UI (export seul) -> migration BFF transparente UX ; runtime DEV API v3.5.182-ai-guard-check-tenantguard-dev (commit 1ecb6ab8, digest sha256:254c57e1...) + Client v3.5.193-ai-guard-check-bff-dev (commit bc05ec97, digest sha256:9da66499...) MATCH=yes GitOps ; PROD strictement inchange 8 services ; aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun draftText publie, aucune PII, aucun ticket Linear cree ; KEY-301 reste Open epic ; AS.12.2C-3/4/5 (evaluate, execute, rules) restent a livrer ; verdict AS.12.2C-2 GO AI GUARD CHECK TENANTGUARD DEV READY.

STOP
