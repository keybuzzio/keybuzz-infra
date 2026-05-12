# PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-12
> Linear : KEY-301
> Phase : T8.12 AS.12.2D -- AI settings + wallet tenantGuard hardening DEV
> Environnement : DEV ; PROD strictement inchange (8 services)

---

## 1. VERDICT

GO AI SETTINGS WALLET TENANTGUARD DEV READY

Module AI settings + wallet couvert par tenantGuard runtime en DEV avec 11 (method, path) tuples proteges. Patch en deux volets coordonnes :

- **API** : 11 entries PROTECTED_ROUTES static ajoutees au tenantGuard.
- **Client** : 4 BFF AI (settings + wallet/status + wallet/ledger + wallet/settings) patches pour injecter `X-User-Email` + `X-Tenant-Id` depuis la session NextAuth (au lieu de forward Cookie uniquement) + 2 fonctions service (`getAISettings`, `getAIWalletStatus`) migrees vers paths relatifs `/api/ai/*` au lieu de browser-direct `${baseUrl}/ai/*`.

Validation 13/13 PASS : 11 no-auth 401 (8 GET + 2 PATCH + 1 POST), bogus user 403, ludo cross-tenant SWITAA 403. Preserve KEY-304 /messages 6/6, AS.12.1A /tenants, AS.12.1B /notifications, AS.12.2B /autopilot 7 routes. Smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable. Logs API DEV 0 5xx. PROD strictement inchange 8 services.

QA Ludovic navigateur DEV confirmee avec switaa26@gmail.com (SWITAA AUTOPILOT) : AIModeSwitch charge le mode IA + Brouillon IA auto visible (depend de `getAISettings` + `getAIWalletStatus` maintenant routes via BFF) + Inbox + autopilot settings + tenant switcher + escalation badge fonctionnels, aucune banniere d erreur, aucune regression observable.

Aucune mutation DB, aucune generation IA, aucune consommation KBActions, aucun wallet debit/credit, aucun draftText publie. Defer explicite : `/ai/global/settings` (admin, pas de BFF, garde un acces browser-direct via `getAIGlobalSettings`), `/ai/credits/add` (financial mutation), `/ai/wallet/dev/*` (DEV-only mutations) -- a traiter ulterieurement.

KEY-301 reste Open epic.

---

## 2. Scope

Inclus :
- API tenantGuard : 11 PROTECTED_ROUTES static (8 GET + 2 PATCH + 1 POST).
- Client BFF 4 routes : injection NextAuth `X-User-Email` + `X-Tenant-Id`.
- Client ai.service.ts : 2 fonctions migrees vers paths relatifs.
- Build API + Client DEV + GitOps DEV.
- Validation negative + preserve.
- QA Ludovic navigateur DEV.
- Rapport docs-only ASCII strict.

Strictement hors scope :
- `/ai/global/settings` GET+PATCH (pas de BFF Client, defer).
- `/ai/credits/add` POST (financial mutation, defer).
- `/ai/wallet/dev/topup|consume|set-actions` (DEV-only mutations, defer).
- `/ai/debug/budget` (debug endpoint).
- Assist/evaluate/execute mutations LLM (AS.12.2C scope).
- Tests POST/PATCH positifs sur target reel.
- Generation IA volontaire.
- Consommation KBActions / wallet.
- Mutation DB.
- PROD deploy.
- Linear status Done.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2A-AI-AUTOPILOT-TENANTGUARD-DESIGN-AUDIT-01.md` -- audit roadmap.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2B-AUTOPILOT-TENANTGUARD-HARDENING-DEV-01.md` + `-PROD-01.md` -- precedente sous-phase.
- `keybuzz-api/src/modules/ai/routes.ts` (settings GET + PATCH).
- `keybuzz-api/src/modules/ai/credits-routes.ts` (wallet, budget, credits, ledger).
- `keybuzz-api/src/plugins/tenantGuard.ts` (pre-patch).
- `keybuzz-client/src/services/ai.service.ts` (getAISettings + getAIWalletStatus consumers).
- `keybuzz-client/app/api/ai/settings/route.ts` + `wallet/status/route.ts` + `wallet/ledger/route.ts` + `wallet/settings/route.ts` (4 BFF a patcher).
- Consumers Client : AIModeSwitch.tsx, AIDecisionPanel.tsx, AISuggestionSlideOver.tsx.

---

## 4. Preflight

| Item | Valeur attendue | Valeur observee | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branch / HEAD / sync | ph147.4/source-of-truth / ffccbd18 (avant patch) / 0-0 | identique | OK |
| keybuzz-client branch / HEAD / sync | ph148/onboarding-activation-replay / 094163b (avant patch) / 0-0 | identique | OK |
| keybuzz-infra branch / HEAD / sync | main / 9a5c77d (avant patch) / 0-0 | identique | OK |
| Runtime DEV API pre | v3.5.179-autopilot-tenantguard-dev | identique | OK |
| Runtime DEV Client pre | v3.5.189-messages-sav-status-bff-dev | identique | OK |
| Runtime PROD API | v3.5.179-autopilot-tenantguard-prod | identique | OK |
| Runtime PROD Client | v3.5.190-messages-bff-tenantguard-prod | identique | OK |
| KEY-309 tag avail API | v3.5.180-ai-settings-wallet-tenantguard-dev AVAILABLE | AVAILABLE | OK |
| KEY-309 tag avail Client | v3.5.192-ai-settings-wallet-bff-dev AVAILABLE | AVAILABLE | OK |
| Smoke V1 DEV pre-deploy | PASS_WITH_WARNINGS | PASS=16 WARN=2 FAIL=0 SKIP=1 | OK |

---

## 5. Audit + design

### 5.1 BFF Client AI pre-patch

| BFF | Methode | NextAuth session | X-User-Email | Cookie forward | Verdict |
|---|---|---|---|---|---|
| /api/ai/settings | GET+PATCH | non | non | OUI | unsafe pour tenantGuard |
| /api/ai/wallet/status | GET | non | non | OUI | unsafe |
| /api/ai/wallet/ledger | GET | non | non | OUI | unsafe |
| /api/ai/wallet/settings | GET+PATCH | non | non | OUI | unsafe |

### 5.2 Client browser-direct via ai.service.ts pre-patch

| Service func | Path actuel | BFF disponible ? | Decision |
|---|---|---|---|
| getAISettings | `${baseUrl}/ai/settings` | OUI `/api/ai/settings` | migrer vers BFF |
| getAIWalletStatus | `${baseUrl}/ai/wallet/status` | OUI `/api/ai/wallet/status` | migrer vers BFF |
| getAIGlobalSettings | `${baseUrl}/ai/global/settings` | NON | defer (hors scope AS.12.2D) |
| getAIJournal | `${baseUrl}/ai/journal` | OUI `/api/ai/journal` | defer (scope AS.12.2E) |
| evaluateAI / executeAI / checkAIGuard | `${baseUrl}/ai/{evaluate,execute,guard/check}` | NON | defer (scope AS.12.2C) |

### 5.3 Design decision

| Aspect | Decision |
|---|---|
| Pattern API | PROTECTED_ROUTES static (11 entries) -- pattern KEY-301 AS.12.2B identique |
| Pattern Client BFF | injection `X-User-Email` + `X-Tenant-Id` depuis `getServerSession(authOptions)` (pattern AS.12.2B `getAuthHeaders` helper) |
| Pattern Client service | migrer fetch direct vers paths relatifs `/api/ai/*` |
| Endpoints proteges | 11 (method, path) tuples : settings GET+PATCH, wallet/status GET, wallet/ledger GET, wallet/actions/ledger GET, credits/wallet GET, credits/ledger GET, budget/overview GET, budget/settings PATCH, budget/alerts GET, budget/check POST |
| Endpoints defer | /ai/global/settings (no BFF), /ai/credits/add (financial), /ai/wallet/dev/* (DEV-only mutations) |

---

## 6. Patch summary

| Repo | HEAD avant | HEAD apres | Fichiers |
|---|---|---|---|
| keybuzz-api | ffccbd18 | e7ad363f08d1541bdd9c8d453bb28077366d6f71 | src/plugins/tenantGuard.ts (+35 lignes) |
| keybuzz-client | 094163b | a46eb5fe788c2fb0f53f2f6eb9c6dbb0ea201260 | 5 fichiers (+110 / -41 lignes) |
| keybuzz-infra | 9a5c77d | 9160218 | k8s/keybuzz-api-dev/deployment.yaml + k8s/keybuzz-client-dev/deployment.yaml |

Detail Client (5 fichiers) :
- `src/services/ai.service.ts` -- 2 fonctions getAISettings + getAIWalletStatus migrees vers fetch relatif `/api/...`.
- `app/api/ai/settings/route.ts` -- helper `getAuthHeaders` ajoute, GET+PATCH injectent X-User-Email + X-Tenant-Id.
- `app/api/ai/wallet/status/route.ts` -- inline injection X-User-Email + X-Tenant-Id (au lieu de Cookie forward).
- `app/api/ai/wallet/ledger/route.ts` -- idem.
- `app/api/ai/wallet/settings/route.ts` -- idem GET (overview) + PATCH (settings).

Aucun changement aux helpers `extractTenantId` / `checkMembership` ni aux matchers existants `/messages` ou `/notifications` ou `/autopilot`. Reutilisation pure du mecanisme tenantGuard.

---

## 7. Build

### 7.1 API

| Item | Valeur |
|---|---|
| Source commit | e7ad363f08d1541bdd9c8d453bb28077366d6f71 |
| Tag image | v3.5.180-ai-settings-wallet-tenantguard-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | e7ad363f08d1541bdd9c8d453bb28077366d6f71 |
| KEY-308 OCI created | 2026-05-12T14:22:13Z |
| KEY-308 OCI version | v3.5.180-ai-settings-wallet-tenantguard-dev |
| Build args | IMAGE_REVISION + IMAGE_CREATED + IMAGE_VERSION |
| Digest GHCR | sha256:648209d142afd9f7af0ac37cd9d64bec3506d5331334ebb78e28b3e38b0c908d |
| Rollback tag | v3.5.179-autopilot-tenantguard-dev |

### 7.2 Client

| Item | Valeur |
|---|---|
| Source commit | a46eb5fe788c2fb0f53f2f6eb9c6dbb0ea201260 |
| Tag image | v3.5.192-ai-settings-wallet-bff-dev |
| KEY-309 pre-push check | AVAILABLE |
| KEY-308 OCI revision | a46eb5fe788c2fb0f53f2f6eb9c6dbb0ea201260 |
| KEY-308 OCI created | 2026-05-12T14:25:10Z |
| Build args PROD URL | NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io |
| KEY-302 bundle verify | api-dev=2 sentinel=0 api-prod=0 OK |
| Digest GHCR | sha256:91e8c9ce63f8297c2b8d8aa104b067cadf5e54141049478fe684523fc28b395f |
| Rollback tag | v3.5.189-messages-sav-status-bff-dev |

---

## 8. GitOps deploy DEV

Commit infra `9160218` :

```
deploy(dev): protect AI settings + wallet via tenant guard and BFF migration (KEY-301 AS.12.2D)
```

Modifie 2 manifests :
- `k8s/keybuzz-api-dev/deployment.yaml` : v3.5.179 -> v3.5.180
- `k8s/keybuzz-client-dev/deployment.yaml` : v3.5.189 -> v3.5.192

Apply ordre :
1. API DEV -> rollout OK
2. Client DEV -> rollout OK

Runtime DEV post-apply :
- API : v3.5.180-ai-settings-wallet-tenantguard-dev MATCH=YES
- Client : v3.5.192-ai-settings-wallet-bff-dev MATCH=YES
- /health DEV : 200 ok

---

## 9. Validation negative (no-mutation, no PII)

### 9.1 Tests no-auth (external)

| # | Endpoint | Method | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T1 | /ai/settings | GET | 401 AUTH_REQUIRED | 401 | PASS |
| T2 | /ai/wallet/status | GET | 401 | 401 | PASS |
| T3 | /ai/wallet/ledger | GET | 401 | 401 | PASS |
| T4 | /ai/wallet/actions/ledger | GET | 401 | 401 | PASS |
| T5 | /ai/credits/wallet | GET | 401 | 401 | PASS |
| T6 | /ai/credits/ledger | GET | 401 | 401 | PASS |
| T7 | /ai/budget/overview | GET | 401 | 401 | PASS |
| T8 | /ai/budget/alerts | GET | 401 | 401 | PASS |
| T9 | /ai/settings | PATCH | 401 | 401 | PASS |
| T10 | /ai/budget/settings | PATCH | 401 | 401 | PASS |
| T11 | /ai/budget/check | POST | 401 | 401 | PASS |

### 9.2 Tests bogus + cross-tenant (in-cluster)

| # | Check | Source | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| T12 | GET /ai/settings bogus | x-user-email=bogus@example.com tenantId=switaa | 403 NOT_MEMBER | 403 | PASS |
| T13 | GET /ai/wallet/status ludo cross-tenant SWITAA | x-user-email=ludo.gonthier@gmail.com tenantId=switaa-sasu-mnc1x4eq | 403 NOT_MEMBER | 403 | PASS |

13/13 PASS. Aucun PATCH ou POST positif emis. Aucune mutation DB. Aucune generation IA. Aucune consommation KBActions / wallet / credits.

---

## 10. Preserve checks

| # | Check | URL | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| P1 | GET /messages/conversations no-auth | https://api-dev.keybuzz.io/messages/conversations?tenantId=fake | 401 (KEY-304) | 401 | PASS |
| P2 | GET /tenants no-auth | https://api-dev.keybuzz.io/tenants | 401 (AS.12.1A) | 401 | PASS |
| P3 | GET /notifications no-auth | https://api-dev.keybuzz.io/notifications?tenantId=fake | 401 (AS.12.1B) | 401 | PASS |
| P4 | GET /autopilot/draft no-auth | https://api-dev.keybuzz.io/autopilot/draft?tenantId=fake&conversationId=fake | 401 (AS.12.2B) | 401 | PASS |

KEY-304, AS.12.1A, AS.12.1B, AS.12.2B integralement preserves.

---

## 11. Smoke V1 + logs

```
=== Summary ===
PASS=16 WARN=2 FAIL=0 SKIP=1
RESULT=PASS_WITH_WARNINGS
```

Aucune nouvelle deterioration. Les 2 WARN sont les memes que pre-deploy (LIST messages 401 + LIST notifications 401, comportements attendus depuis AS.11.1A et AS.12.1B). Le smoke V1 ne probe pas AI settings ni wallet, donc pas d evolution PASS->WARN sur ce scope.

| Source | Filtre | Count |
|---|---|---|
| API DEV 5min | statusCode 5xx ou level=50 | 0 |

---

## 12. QA Ludovic navigateur DEV

QA confirmee par Ludovic sans donnees client copiees :

| Item | Resultat |
|---|---|
| Compte session NextAuth DEV | `switaa26@gmail.com` (SWITAA owner, plan AUTOPILOT) |
| Tenant courant | SWITAA |
| AIModeSwitch charge correctement (mode IA visible) | OUI |
| Brouillon IA visible automatiquement sur conv eligible | OUI |
| Bouton "Valider et envoyer" visible | OUI (NON clique) |
| Wallet balance / KBActions display si visible UI | OUI |
| Autopilot settings UI charge | OUI (deja proteges AS.12.2B) |
| Inbox liste + detail visible | OUI |
| Tenant switcher fonctionnel | OUI |
| Escalation badge | OUI |
| Auth flow OK | OUI |
| Banniere erreur visible | NON |
| 401 errors devtools sur appels Client legitimes | NON observe |
| Regression visible | NON |

Le BFF Client `/api/ai/settings` + `/api/ai/wallet/status` injectent maintenant X-User-Email + X-Tenant-Id -> tenantGuard accepte les appels legitimes -> Brouillon IA + AIModeSwitch + wallet display continuent de fonctionner sans regression.

Aucune donnee client copiee. Aucun draftText publie. Aucune capture ecran PII committee.

---

## 13. Rollback plan (PRET, NON EXECUTE)

Si regression detectee :

```
cd /opt/keybuzz/keybuzz-infra
git revert 9160218 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.179-autopilot-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml   # -> v3.5.189-messages-sav-status-bff-dev
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=240s
```

Rollback rapide (< 3 minutes). PROD inchange (rien a rollback en PROD).

Triggers rollback :
- AIModeSwitch ne charge plus (settings GET via BFF echoue de maniere non transitoire)
- Brouillon IA disparait (getAISettings fail cascade)
- wallet balance disparait UI
- spike 5xx API DEV
- 403 NOT_MEMBER injustifie

---

## 14. PROD unchanged proof

| Namespace | Workload | Image runtime (avant + apres AS.12.2D) |
|---|---|---|
| keybuzz-api-prod | keybuzz-api | v3.5.179-autopilot-tenantguard-prod |
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

A poster apres rapport commit + push, **uniquement avec GO Ludovic explicite et methode token agreee**. Backlog : 17 jeux de commentaires accumules.

### 15.1 KEY-301 commentaire (texte cible)

```
## AS.12.2D AI settings + wallet hardened in DEV

Fourth KEY-301 sub-phase under the AI roadmap (after AS.12.2A audit and AS.12.2B autopilot). The AI settings + wallet endpoints are now covered by tenantGuard runtime in DEV.

11 endpoints now protected (DEV) -- 8 GET + 2 PATCH + 1 POST :
- /ai/settings GET + PATCH (AI mode read + update with plan guard handler-level)
- /ai/wallet/status + /ai/wallet/ledger + /ai/wallet/actions/ledger GET
- /ai/credits/wallet + /ai/credits/ledger GET
- /ai/budget/overview GET, /ai/budget/settings PATCH, /ai/budget/alerts GET, /ai/budget/check POST

Validation negative 13/13 PASS : 11 no-auth 401, bogus user 403, cross-tenant 403. No POST/PATCH issued positively ; no AI generation, no KBActions consumed, no wallet debit/credit.

Client patch in same phase : 4 BFF routes (settings + wallet/status + wallet/ledger + wallet/settings) migrated from cookie-forward to X-User-Email + X-Tenant-Id injection from NextAuth session ; 2 service functions (`getAISettings`, `getAIWalletStatus`) migrated from browser-direct to relative BFF paths.

Preserve checks : KEY-304 messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot still 401 unauthenticated.

Runtime DEV : API v3.5.180-ai-settings-wallet-tenantguard-dev + Client v3.5.192-ai-settings-wallet-bff-dev. GitOps MATCH=yes. Logs API DEV 5min : 0 5xx. Smoke V1 stable (PASS=16 WARN=2 FAIL=0 SKIP=1).

Ludovic QA navigateur DEV with switaa26@gmail.com (SWITAA AUTOPILOT) confirmed : AIModeSwitch loads, Brouillon IA auto visible, wallet balance display OK, no error banner, no regression.

Deferred to later sub-phases (explicit, no breaking change introduced) :
- /ai/global/settings (admin-only, no BFF on Client yet ; needs new BFF + service migration)
- /ai/credits/add (financial mutation, needs additional safety review)
- /ai/wallet/dev/topup|consume|set-actions (DEV-only mutations)

PROD strictly unchanged (8 services on AS.12.2B-PROD baseline).

KEY-301 stays Open. NOT marked Done in this phase.

Disclosure controle : pas de PoC, pas de details exploit, pas de draftText, pas de PII.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2D-AI-SETTINGS-WALLET-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 16. Compliance AS.12.2D

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Repos clean (artifacts toleres) | OK |
| commit + push avant build (API e7ad363f + Client a46eb5f + infra 9160218) | OK |
| Build-from-Git | OK |
| Tag immuable (no :latest) | OK |
| KEY-308 OCI labels non "unknown" (API + Client) | OK |
| KEY-302 Client bundle verify (api-dev=2 sentinel=0 api-prod=0) | OK |
| KEY-309 pre-push check AVAILABLE (API + Client) | OK |
| Digests documentes | OK |
| Rollback plan documente | OK section 13 |
| GitOps strict (kubectl apply -f only) | OK |
| No kubectl set / patch / edit | OK |
| Aucun deploy hors API+Client DEV | OK |
| ASCII strict rapport | OK |
| Aucune mutation DB | OK (no positive POST/PATCH) |
| Aucune generation IA | OK |
| Aucune consommation KBActions / wallet / credits | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Disclosure controle Linear (texte prepare) | OK |
| KEY-301 statut Done NON applique | OK |
| Smoke V1 DEV pre + post deploy stable | OK |
| QA Ludovic navigateur DEV OK | OK (AIModeSwitch + Brouillon IA fonctionnels) |
| Defer documente : /ai/global/settings + /ai/credits/add + /ai/wallet/dev/* | OK section 2 + 15 |

---

## 17. Phrase cible finale

AS.12.2D livre : module AI settings + wallet 11 endpoints (8 GET + 2 PATCH + 1 POST) proteges par tenantGuard runtime en DEV via PROTECTED_ROUTES static ; 4 BFF Client (settings + wallet/status + wallet/ledger + wallet/settings) migres de Cookie-forward vers injection NextAuth `X-User-Email` + `X-Tenant-Id` ; 2 fonctions service ai.service.ts (getAISettings + getAIWalletStatus) migrees vers paths relatifs `/api/ai/*` ; tests negatifs 13/13 PASS (11 no-auth 401 + bogus 403 + ludo cross-tenant SWITAA 403) ; preserve KEY-304 /messages 6/6 + AS.12.1A /tenants + AS.12.1B /notifications + AS.12.2B /autopilot 401 ; smoke V1 PASS=16 WARN=2 FAIL=0 SKIP=1 stable ; logs API DEV 0 5xx ; QA Ludovic navigateur DEV OK avec switaa26@gmail.com (SWITAA AUTOPILOT) : AIModeSwitch + Brouillon IA + wallet display + Inbox + autopilot settings + tenant switcher fonctionnels, aucune regression ; runtime DEV API v3.5.180-ai-settings-wallet-tenantguard-dev (commit e7ad363f, digest sha256:648209d142...) + Client v3.5.192-ai-settings-wallet-bff-dev (commit a46eb5f, digest sha256:91e8c9ce63...) MATCH=yes GitOps ; PROD strictement inchange 8 services ; aucune mutation DB, aucune generation IA, aucune consommation KBActions/wallet/credits, aucun draftText publie, aucune PII publiee ; defer documente /ai/global/settings + /ai/credits/add + /ai/wallet/dev/* ; KEY-301 reste Open epic ; verdict AS.12.2D GO AI SETTINGS WALLET TENANTGUARD DEV READY.

STOP
