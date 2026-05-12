# PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-3 -- AI evaluate tenantGuard hardening DEV
> Environnement : DEV ; runtime DEV restored post-rollback ; PROD strictement inchange (8 services)

---

## 1. VERDICT

NO GO FUNCTIONAL REGRESSION ROLLBACK DONE

Patch initial AS.12.2C-3 livre en DEV (API v3.5.183 + Client v3.5.194) avec tests negatifs 4/4 PASS + DB no-mutation prouvee + preserve checks OK. Mais la QA Ludovic navigateur DEV a detecte une **regression UX confirmee** : le **Brouillon IA auto ne s ouvre plus pour les nouveaux messages** sur la conversation cible SWITAA `commande 4114-...`. L Aide IA fonctionne sur les anciens messages (envoi sur conversation existante OK), mais l auto-open Brouillon IA est casse.

**Rollback GitOps effectue immediatement** : revert commit infra `60d3a33` + 2 kubectl apply. Runtime DEV restore vers API `v3.5.182-ai-guard-check-tenantguard-dev` + Client `v3.5.193-ai-guard-check-bff-dev`. Ludovic confirme post-rollback : **Brouillon IA auto refonctionne**.

PROD strictement inchange tout au long de la phase (8 services sur baselines AS.12.2C-2-PROD). Aucune mutation DB persistante (evaluate_log SWITAA count reste 0 -> 0 puisque tous tests etaient negatifs avant la regression). Aucune generation IA, aucune consommation KBActions, aucun draftText publie.

KEY-301 reste Open epic. AS.12.2C-3 a refaire en R2 apres investigation root cause regression.

---

## 2. Scope (livre puis rollback)

Inclus initialement :
- API : tenantGuard +1 PROTECTED_ROUTES `POST /ai/evaluate` (commit `85555b26`).
- Client : nouveau BFF `app/api/ai/evaluate/route.ts` (NextAuth + X-User-Email + X-Tenant-Id) + migration `evaluateAI` vers `/api/ai/evaluate` relatif (commit `c24d8c9`).
- Build API v3.5.183 + Client v3.5.194 + manifest commit `189fdfb` + apply DEV.
- Validation negative 4/4 PASS + DB no-mutation evaluate_log SWITAA delta 0.

Rollback :
- Revert infra commit `60d3a33` -> retour API `v3.5.182-ai-guard-check-tenantguard-dev` + Client `v3.5.193-ai-guard-check-bff-dev`.
- Brouillon IA auto reconfirme fonctionnel par Ludovic.
- Source commits API `85555b26` + Client `c24d8c9` restent en historique source (revert affecte uniquement les images runtime via manifest revert).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-LLM-MUTATIONS-TENANTGUARD-DESIGN-AUDIT-01.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md`
- `keybuzz-api/src/modules/ai/routes.ts` (POST /evaluate handler ligne 288-355).
- `keybuzz-client/src/services/ai.service.ts` (evaluateAI ligne 172).
- `keybuzz-client/src/features/ai-ui/AIDecisionPanel.tsx` (consumer ligne 101, auto-call `.catch(() => null)`).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| Source sync 3 repos | 0/0 | OK |
| Runtime DEV API pre | v3.5.182-ai-guard-check-tenantguard-dev | OK |
| Runtime DEV Client pre | v3.5.193-ai-guard-check-bff-dev | OK |
| Runtime PROD API + Client | v3.5.182 + v3.5.193 (inchanges) | OK |
| KEY-309 tag avail | AVAILABLE pour API v3.5.183 + Client v3.5.194 | OK |
| Smoke V1 DEV pre | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. Audit handler /ai/evaluate

Source `keybuzz-api/src/modules/ai/routes.ts:288-355` :
- POST /evaluate
- Plan guard PH130 (STARTER -> 403)
- Calls `checkGuardrails` + reads `ai_settings` + reads `ai_rules`
- INSERTs into `ai_action_log` (status=blocked ou planned)
- Updates `ai_settings.consecutive_errors` on error path
- Suggestions LLM = mock (string template "[Mock] Auto-suggestion from rule ...")
- Pas de vrai LLM call dans le code present, mais MUTATION DB ai_action_log toujours executee

Consumer Client : `AIDecisionPanel.tsx:101` -- auto-call `evaluateAI({ tenantId, conversationId, channel, text: lastMessageText }).catch(() => null)` sur slide-over open.

---

## 6. Design implementee initialement

Patch coordonne API + Client (meme pattern AS.12.2C-2) :
- tenantGuard +1 entry PROTECTED_ROUTES static `POST /ai/evaluate`.
- BFF Next.js `/api/ai/evaluate` (NextAuth check 401 + injection X-User-Email + X-Tenant-Id, forward body raw POST).
- `ai.service.ts::evaluateAI` migre de `fetchAI('/ai/evaluate', POST)` browser-direct vers `fetch('/api/ai/evaluate', POST)` relative.

---

## 7. Patch summary (livre puis revert via manifest)

| Repo | HEAD apres patch | Statut runtime apres rollback |
|---|---|---|
| keybuzz-api | 85555b26cbcdfb1c7223d562453cc99c028cd91d | image runtime restore v3.5.182 (source `1ecb6ab8`) ; commit source 85555b26 reste en historique |
| keybuzz-client | c24d8c9263e3da21460fec3425fce1cc1af24604 | image runtime restore v3.5.193 (source `bc05ec9`) ; commit source c24d8c9 reste en historique |
| keybuzz-infra | 189fdfb (deploy commit) + 60d3a33 (revert commit) | runtime restore via revert manifest |

---

## 8. Build (livre)

| API | Client |
|---|---|
| v3.5.183-ai-evaluate-tenantguard-dev | v3.5.194-ai-evaluate-bff-dev |
| Source commit 85555b26 | Source commit c24d8c9 |
| Digest sha256:ce9c2cde7a76992124393b42eab1529ef73af2395eff4b814a79bf46b0f172ff | Digest sha256:2beee35ab49179452b8999957077b47d5225d91c6b20b6408dc3088bfc6d0993 |
| KEY-308 OCI revision OK | KEY-308 OCI revision OK ; KEY-302 bundle verify api-dev=2 sentinel=0 api-prod=0 OK |

Images poussees sur GHCR. Reutilisables potentiellement pour AS.12.2C-3-R2 selon root cause analysis.

---

## 9. GitOps DEV (apply puis revert)

Commit infra `189fdfb` (deploy AS.12.2C-3 a v3.5.183 + v3.5.194), suivi du commit infra `60d3a33` (revert) :

```
chronologie infra main:
  189fdfb deploy(dev): protect /ai/evaluate via tenant guard + new BFF (KEY-301 AS.12.2C-3)
  60d3a33 Revert "deploy(dev): protect /ai/evaluate via tenant guard + new BFF (KEY-301 AS.12.2C-3)"
```

Apply :
1. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API v3.5.183 OK
2. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client v3.5.194 OK
3. Regression Brouillon IA detectee par Ludovic
4. `git revert 189fdfb --no-edit` + push origin main (commit `60d3a33`)
5. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` -> rollout API v3.5.182 OK
6. `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` -> rollout Client v3.5.193 OK
7. /health DEV 200 ; Ludovic reconfirme Brouillon IA auto fonctionnel.

---

## 10. Validation negative (avant rollback)

| # | Check | Expected | Observed | Verdict |
|---|---|---|---|---|
| T1 | POST /ai/evaluate no-auth | 401 AUTH_REQUIRED | 401 | PASS |
| T2 | POST /ai/evaluate bogus user | 403 NOT_MEMBER | 403 | PASS |
| T3 | POST /ai/evaluate ludo cross-tenant SWITAA | 403 NOT_MEMBER | 403 | PASS |
| T4 | POST /ai/evaluate no tenantId valid email | 400 TENANT_ID_MISSING | 400 | PASS |

Aucun POST positif emis. evaluate_log SWITAA pre/post tests : 0 / 0 (delta 0). Aucune mutation ai_action_log.

Preserve checks 8/8 PASS : KEY-304 /messages + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot + AS.12.2D /ai settings/wallet + AS.12.2C-1 /ai/assist + AS.12.2C-2 /ai/guard/check tous 401.

Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable. 0 5xx logs API DEV.

---

## 11. Regression UX detectee (QA Ludovic)

QA Ludovic navigateur DEV apres apply (avant rollback) :

> Le brouillon IA ne s'ouvre plus automatiquement pour les nouveau message sur mon compte switaa26@gmail.com avec la conversation qui a pour titre "commande 4114-...", mais l'Aide IA fonctionne bien. Sur les anciens messages, si je renvoie un message sur une conversation existante, j'ai l'impression que ca fonctionne, mais pas pour les nouveaux messages.

Conclusion : un comportement UX critique (auto-open Brouillon IA sur nouveau message) est casse par le patch. Cela suggere que `evaluateAI` participe a une chaine de declenchement qui aboutit a l affichage Brouillon IA, et que cette chaine echoue silencieusement post-patch (`.catch(() => null)` absorbe l erreur).

Hypotheses root cause a investiguer pour R2 :
- H1 : le BFF `/api/ai/evaluate` retourne une erreur (401/403/500/503) que le `.catch(() => null)` masque, alors que pre-patch l appel browser-direct retournait 200 (handler atteint sans tenantGuard).
- H2 : NextAuth session non disponible cote BFF dans certains contextes Client (par exemple en mode SSR de la conversation ou hook hors-session ?). Verifier `getServerSession(authOptions)`.
- H3 : `X-Tenant-Id` injecte par le BFF est different du `body.tenantId` envoye par le Client, causant un mismatch dans le handler API.
- H4 : Le `tenantId` envoye par `AIDecisionPanel.tsx:101` est `effectiveTenantId` qui peut differer du current tenant cote NextAuth -- a investiguer.
- H5 : Race condition avec `useEscalationNotifsCount` (poll 30s) qui declenche le re-render avant que la session NextAuth soit stable.

Logs API DEV 0 5xx pendant la regression, donc l API n a pas plante. Probable que le 401/403/4xx du BFF ou API soit absorbee par le `.catch(() => null)`.

---

## 12. Rollback proof

| Mesure | Pre-rollback (post-apply v3.5.183/v3.5.194) | Post-rollback (v3.5.182/v3.5.193) |
|---|---|---|
| Runtime API DEV | v3.5.183-ai-evaluate-tenantguard-dev | v3.5.182-ai-guard-check-tenantguard-dev |
| Runtime Client DEV | v3.5.194-ai-evaluate-bff-dev | v3.5.193-ai-guard-check-bff-dev |
| GitOps MATCH | YES | YES |
| /health DEV | 200 | 200 |
| Brouillon IA auto UX | KO (auto-open casse nouveaux messages) | OK (Ludovic confirme) |
| evaluate_log SWITAA count | 0 | 0 (no positive POST during tests) |

Rollback complet en environ 90 secondes (revert + 2 apply + 2 rollout).

---

## 13. PROD strictement inchange

| Service | Image PROD (inchangee tout au long) |
|---|---|
| keybuzz-api PROD | v3.5.182-ai-guard-check-tenantguard-prod |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod |
| keybuzz-client PROD | v3.5.193-ai-guard-check-bff-prod |
| keybuzz-backend PROD | v1.0.47-cross-env-guard-fix-prod |
| amazon-items-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| amazon-orders-worker PROD | v1.0.40-amz-tracking-visibility-backfill-prod |
| backfill-scheduler PROD | v1.0.42-td02-worker-resilience-prod |
| keybuzz-admin-v2 PROD | v2.12.2-media-buyer-lp-domain-qa-prod |

Aucun manifest PROD touche. Aucun docker push prod-tag. Aucun kubectl apply sur namespace `*-prod`.

---

## 14. Plan R2 propose (AS.12.2C-3-R2)

### Etape 1 -- root cause analysis

Re-deploy DEV avec instrumentation temporaire :
- ajouter logs serveur cote BFF `/api/ai/evaluate` (status code + error body, sans PII)
- ajouter logs cote AIDecisionPanel.tsx pour capturer l erreur du `.catch(() => null)` (console.error temporaire DEV-only)
- monitorer logs API tenantGuard `[TenantGuard] DENIED` pendant QA Ludovic

OU plus simple : Ludovic ouvre devtools (Network tab + Console) sur DEV apres re-apply images v3.5.183 + v3.5.194 et reproduit le scenario nouveau message -> capture status code + payload de `/api/ai/evaluate`.

### Etape 2 -- corriger ou ajuster

Selon root cause :
- Si erreur de session : BFF ajustement (ex : fallback X-User-Email depuis header upstream si session manquante)
- Si mismatch tenantId : align body.tenantId et X-Tenant-Id
- Si plan guard handler-level bloque avant Brouillon IA : verifier que SWITAA est bien AUTOPILOT cote DEV
- Si bug Client (re-render race) : adjustement AIDecisionPanel

### Etape 3 -- AS.12.2C-3-R2 deploy

Si root cause clair et fix non invasif :
- Mettre a jour BFF/Client/API selon root cause
- Re-build API v3.5.183-... ou v3.5.185 selon discipline tag
- Re-build Client v3.5.194-... ou v3.5.195 selon discipline tag
- Apply DEV
- QA Ludovic obligatoire avant cloture

---

## 15. Sub-phases pending

Apres AS.12.2C-3-R2 success :
- AS.12.2C-4 execute (P0 critical, mutation + side effects downstream)
- AS.12.2C-5 rules GET+POST (P1 admin scope)

---

## 16. Linear text prepared

A poster apres rapport commit + push avec methode token agreee.

### 16.1 KEY-301 commentaire (texte cible)

```
## AS.12.2C-3 NO GO -- functional regression detected and rolled back

Third LLM-mutation sub-phase under KEY-301 (after AS.12.2C-1 assist and AS.12.2C-2 guard/check). The /ai/evaluate hardening was deployed to DEV but Ludovic browser QA detected a UX regression on Brouillon IA auto-open for new messages on a real SWITAA conversation. AIDecisionPanel.tsx:101 auto-calls `evaluateAI(...)` wrapped in `.catch(() => null)` which silently absorbs any post-patch error.

Action taken :
- GitOps revert (infra commit) + 2 kubectl apply DEV.
- Runtime DEV restored to API v3.5.182-ai-guard-check-tenantguard-dev + Client v3.5.193-ai-guard-check-bff-dev in approximately 90 seconds.
- Ludovic reconfirmed Brouillon IA auto-open functional post-rollback.

Tests negatifs 4/4 PASS during the brief deployment window. DB no-mutation proven : evaluate ai_action_log count for SWITAA unchanged (0 -> 0). No positive POST issued. No LLM generation. No KBActions consumed.

PROD strictly unchanged throughout (8 services on AS.12.2C-2-PROD baseline).

Root cause analysis pending. Hypotheses : session unavailable in BFF context, X-Tenant-Id mismatch, plan guard interaction, or Client re-render race condition. AS.12.2C-3-R2 will be planned after root cause is identified (Ludovic devtools capture or temporary instrumentation).

KEY-301 stays Open. AS.12.2C-3 marked NO GO FUNCTIONAL REGRESSION ROLLBACK DONE.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 17. Compliance

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API 85555b26 + Client c24d8c9 + infra 189fdfb) | OK |
| Build-from-Git | OK |
| Tag immuable | OK |
| KEY-308 OCI labels non "unknown" (API + Client) | OK |
| KEY-302 Client bundle DEV verify | OK |
| KEY-309 pre-push check AVAILABLE (API + Client) | OK |
| Digests documentes | OK |
| Rollback execute en < 5 min | OK (~90s) |
| GitOps strict (kubectl apply -f only) | OK |
| Aucune mutation DB persistante (delta 0) | OK |
| Aucun POST positif vers /ai/evaluate | OK |
| Aucune generation IA | OK |
| Aucune consommation KBActions / wallet | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement inchange (8 services) | OK |
| Brouillon IA auto restored post-rollback | OK (Ludovic reconfirme) |

---

## 18. Phrase cible finale

AS.12.2C-3 livre puis rollback : patch coordonne API v3.5.183-ai-evaluate-tenantguard-dev (commit 85555b26) + Client v3.5.194-ai-evaluate-bff-dev (commit c24d8c9) avec nouveau BFF `/api/ai/evaluate` + migration `evaluateAI` vers path relatif ; manifest commit 189fdfb apply DEV ; tests negatifs 4/4 PASS (no-auth 401, bogus 403, ludo cross-tenant SWITAA 403, missing tenantId 400) ; DB no-mutation prouvee evaluate_log SWITAA 0 -> 0 delta 0 ; preserve 8/8 protections precedentes ; smoke V1 stable ; 0 5xx logs ; **QA Ludovic navigateur DEV detecte regression : Brouillon IA auto ne s ouvre plus pour nouveaux messages sur conversation SWITAA `commande 4114-...`, Aide IA fonctionne sur anciens messages** ; rollback GitOps immediat via revert infra commit 60d3a33 + 2 kubectl apply -> runtime DEV restore vers API v3.5.182-ai-guard-check-tenantguard-dev + Client v3.5.193-ai-guard-check-bff-dev ; rollback complet en ~90 secondes ; Ludovic reconfirme post-rollback : **Brouillon IA auto refonctionne** ; PROD strictement inchange tout au long 8 services ; aucune mutation DB persistante, aucun POST positif emis, aucune generation IA, aucune consommation KBActions, aucun draftText publie, aucune PII ; KEY-301 reste Open epic ; AS.12.2C-3-R2 a planifier apres root cause analysis (hypotheses : session BFF, mismatch tenantId, plan guard, race condition Client) ; verdict AS.12.2C-3 NO GO FUNCTIONAL REGRESSION ROLLBACK DONE.

STOP
