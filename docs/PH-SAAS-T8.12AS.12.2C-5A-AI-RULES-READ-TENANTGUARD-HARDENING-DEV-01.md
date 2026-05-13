# PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-5A -- implementation hardening READ rules + playbooks en DEV (tenantGuard + BFF GET)
> Environnement : DEV ; PROD strictement read-only et inchange

---

## 1. VERDICT

GO AI RULES READ TENANTGUARD DEV READY

Implementation des 4 endpoints READ de la surface rules (5A) livree en DEV selon le design audit AS.12.2C-5 :
- API : `v3.5.184-ai-execute-tenantguard-dev` -> `v3.5.185-ai-rules-read-tenantguard-dev` (digest GHCR `sha256:d671a247f59ab27383daceab55e3fe87d2b594d1f5ac44fb58ba70ea6e40bbcd`, OCI revision `ccbcb9afad31fb9e115c782eecf729be640322b1`).
- Client : `v3.5.195-ai-execute-bff-dev` -> `v3.5.196-ai-rules-bff-dev` (digest GHCR `sha256:7a5f8e83652b694fd4f23ce2417f34ec5892c8d81f4d6a3252ca9ff7177efcae`, OCI revision `b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb`).
- Manifest infra commit `01ca110` push origin/main 0-0.
- 2 kubectl apply -f DEV + rollouts successful ; spec = last-applied = pod imageID = digest pushe.

Validation negative DEV : **14/14 protections actives** :
- 4 NEW READ (AS.12.2C-5A) : `GET /ai/rules`, `GET /playbooks`, `GET /playbooks/:id` (matcher dynamique), `GET /playbooks/suggestions` (exact) tous 401 unauthenticated.
- 10 preserve (KEY-304 + AS.12.1A/1B + AS.12.2B + AS.12.2C-1/2/3/4 + AS.12.2D) tous 401 avec payloads valides.

Logs API DEV 5min : 0 5xx. Logs Client DEV 5min : 1 `JWT_SESSION_ERROR` transient (typique pod terminating durant rollout NextAuth ; accepte par Ludovic comme transient si pas de spike durable). PROD strictement inchange (toutes images DEV-only, 13 services PROD intacts).

QA Ludovic navigateur DEV (`https://client-dev.keybuzz.io`) : Inbox + Brouillon IA + tenant switcher + escalation + playbooks pages read-only OK, **aucune regression visible**.

DB no-mutation : baseline `ai_rules` = 465 rows, `ai_rule_conditions` = 124 rows, `ai_rule_actions` = 1116 rows, `playbook_suggestions` 24h = 0. Aucune mutation rules de notre fait (validation 100% en negatifs).

KEY-301 reste Open epic. **AS.12.2C-5A ferme en DEV**. Sous-phases restantes : **AS.12.2C-5A-PROD** (coordinated promotion) puis **AS.12.2C-5B** (mutations DEV+PROD).

---

## 2. Scope

Inclus :
- 3 patches tenantGuard.ts : header doc + 3 PROTECTED_ROUTES (R1+P1+P7) + nouveau matcher `isPlaybookDetailGet` + 1 ligne isProtected.
- 1 nouveau fichier BFF `app/api/ai/rules/route.ts` GET (~70 lignes, pattern AS.12.2C-2/3/4).
- 2 commits + push sur branches imposees (api ph147.4 / client ph148).
- Build DEV from-git via scripts patches AS.12.2C-3.1 (KEY-308 + KEY-302 + KEY-309).
- 2 docker push GHCR.
- 1 commit + push manifests DEV.
- 2 kubectl apply -f DEV + rollouts.
- Validation negative 14/14 + logs + DB no-mutation.
- QA Ludovic navigateur DEV.
- Rapport docs-only ASCII strict + commit + push.

Hors scope :
- **Aucun endpoint mutation** : POST /ai/rules, POST /playbooks, PUT /playbooks/:id, DELETE /playbooks/:id, PATCH /playbooks/:id/toggle, PATCH /playbooks/suggestions/:id/apply, PATCH /playbooks/suggestions/:id/dismiss -- **reserve a AS.12.2C-5B**.
- Aucune mutation BFF playbooks (`/api/playbooks/*` deja safe, non touche).
- Aucune mutation ai.service.ts Client (aucun caller actif `/ai/rules` cote Client).
- Aucune mutation source admin v2 (mock pur, hors runtime).
- Aucun build / push / deploy PROD.
- Aucune mutation DB de notre fait.
- Aucune creation / modification / suppression de regle.
- AS.12.2C-5B (mutations) differe.
- AS.12.2C-5A-PROD (promotion) differe.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01.md` (design audit).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-*-01.md` (DEV+PROD precedents).
- `keybuzz-api/src/plugins/tenantGuard.ts` (PROTECTED_ROUTES + matchers + isProtected + insertion points).
- `keybuzz-api/src/modules/ai/routes.ts` (handler /rules ligne 233-289).
- `keybuzz-api/src/modules/playbooks/routes.ts` (handlers 9 endpoints).
- `keybuzz-client/app/api/ai/evaluate/route.ts` (template BFF, deja safe pattern).
- `keybuzz-client/app/api/playbooks/*` (7 BFF deja safe).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-api HEAD pre-patch / sync | d7f2a8fd / 0-0 | OK |
| keybuzz-client HEAD pre-patch / sync | 14a4ea66 / 0-0 | OK |
| keybuzz-infra HEAD pre-patch / sync | 1ce705c (rapport AS.12.2C-5 design audit) / 0-0 / 0 dirty | OK |
| `assert-git-committed.sh` global | api + client propres -- BUILD AUTORISE | OK |
| Runtime DEV API pre-patch | v3.5.184-ai-execute-tenantguard-dev | OK baseline |
| Runtime DEV Client pre-patch | v3.5.195-ai-execute-bff-dev | OK baseline |
| Runtime PROD API/Client | v3.5.184 / v3.5.195 (post AS.12.2C-4-PROD) | OK read-only |
| KEY-309 tag `v3.5.185-ai-rules-read-tenantguard-dev` | GHCR manifest unknown | OK libre |
| KEY-309 tag `v3.5.196-ai-rules-bff-dev` | GHCR manifest unknown | OK libre |
| DB baseline DEV ai_rules total | 465 rows | OK |
| DB baseline DEV ai_rule_conditions | 124 rows | OK |
| DB baseline DEV ai_rule_actions | 1116 rows | OK |
| DB baseline DEV playbook_suggestions 24h | 0 | OK |
| Smoke V1 DEV | scripts/smoke-v1.sh absent du bastion | NOTE saute |

---

## 5. Patch sources

### 5.1 keybuzz-api : `src/plugins/tenantGuard.ts`

Modifications (+52 / -2) :

**A. Header doc** : replace le commentaire generique `/ai/rules, /ai/rules remains unprotected ...` par un block detaille AS.12.2C-5A documentant les 4 endpoints proteges + le contexte CRUD `/playbooks` + l absence de BFF refactor requis + le decoupage 5A/5B.

**B. PROTECTED_ROUTES** : ajout 3 entries exact-path apres l entree AS.12.2C-4 (POST /ai/execute) :

```typescript
// PH-SAAS-T8.12AS.12.2C-5A KEY-301: AI rules + playbooks READ surface.
// Exact-path entries; the dynamic /playbooks/:id matcher (isPlaybookDetailGet)
// is checked AFTER static lookup so /playbooks/suggestions resolves here, not
// as a dynamic detail id.
{ method: 'GET', path: '/ai/rules' },
{ method: 'GET', path: '/playbooks' },
{ method: 'GET', path: '/playbooks/suggestions' },
```

**C. Matcher `isPlaybookDetailGet`** : nouvelle fonction (~22 lignes avec JSDoc) insere avant `isProtected`. Pattern strict :
- method = 'GET' obligatoire
- prefix `/playbooks/` obligatoire
- 1 seul segment apres le prefix (pas de '/' supplementaire)
- exclut implicitement `/playbooks/abc/toggle`, `/playbooks/abc/simulate`, etc. (sub-endpoints scope 5B)
- `/playbooks/suggestions` est resolu par static match avant arrivee au matcher

**D. isProtected update** : ajout `if (isPlaybookDetailGet(method, path)) return true;` apres les autres matchers.

Commit : `ccbcb9af feat(security): protect /ai/rules + /playbooks GET endpoints via tenantGuard (KEY-301 AS.12.2C-5A)` push origin/ph147.4/source-of-truth 0-0.

### 5.2 keybuzz-client : `app/api/ai/rules/route.ts` (nouveau)

Nouveau fichier BFF Next.js Server (~70 lignes) :
- `import { getServerSession } from 'next-auth'` + `authOptions`.
- `GET` handler : verifie session (401 si absente).
- Lit `tenantId` depuis `searchParams.get('tenantId')` ou header `X-Tenant-Id` (400 si manquant).
- Forward `GET ${API_URL}/ai/rules?tenantId=...` avec headers `X-User-Email` + `X-Tenant-Id` injectes (cache: 'no-store').
- Gestion erreur non-2xx avec extrait stdout 200 chars.
- `export const dynamic = 'force-dynamic'`.

Aucun cookie forward, aucune fuite secret, aucune ecriture cote BFF. **Aucun caller Client actuel** -- BFF cree par anticipation future Client integration (le vrai CRUD ai_rules est via `/api/playbooks/*` deja safe).

Commit : `b726970 feat(security): new BFF /api/ai/rules GET (NextAuth + tenantId) (KEY-301 AS.12.2C-5A)` push origin/ph148/onboarding-activation-replay 0-0.

### 5.3 Scope verifie

Aucune autre source touchee :
- `src/services/ai.service.ts` Client : pas modifie (aucun caller `/ai/rules`).
- `app/api/playbooks/*` Client : pas modifie (deja safe).
- `src/modules/ai/routes.ts` API : pas modifie (handlers existants, protege par tenantGuard preHandler).
- `src/modules/playbooks/routes.ts` API : pas modifie (handlers existants, protege par tenantGuard preHandler).
- Pages UI `/playbooks` : pas modifiees.
- Admin v2 : pas modifie (mock pur, hors runtime).

---

## 6. Build DEV (scripts patches AS.12.2C-3.1)

### 6.1 API DEV

```
bash scripts/build-api-from-git.sh dev v3.5.185-ai-rules-read-tenantguard-dev ph147.4/source-of-truth
```

Build OK, Git SHA `ccbcb9a` (= HEAD post-push). OCI labels conformes KEY-308 :

| Label | Valeur |
|---|---|
| revision | `ccbcb9afad31fb9e115c782eecf729be640322b1` |
| created | `2026-05-13T14:12:34Z` |
| version | `v3.5.185-ai-rules-read-tenantguard-dev` |
| source | `https://github.com/keybuzzio/keybuzz-api` |
| title | `keybuzz-api` |

### 6.2 Client DEV

```
bash scripts/build-from-git.sh dev v3.5.196-ai-rules-bff-dev ph148/onboarding-activation-replay
```

Build OK avec build-args auto (`NEXT_PUBLIC_APP_ENV=development`, `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`, IMAGE_REVISION/CREATED/VERSION remplis). Git SHA `b726970`.

| Label | Valeur |
|---|---|
| revision | `b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb` |
| created | `2026-05-13T14:12:31Z` |
| version | `v3.5.196-ai-rules-bff-dev` |

### 6.3 verify-image-clean Client DEV

```
=== RESULTATS: 17 PASS / 0 FAIL / 0 WARN ===
VERDICT: PASS -- Image valide
```

### 6.4 Bundle DEV verifications

| Check | Count | Verdict |
|---|---|---|
| sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | PASS KEY-302 |
| `api-dev.keybuzz.io` | 2 occurrences | PASS bundle DEV |
| `api.keybuzz.io` standalone | 0 | PASS no contamination PROD |
| BFF `app/api/ai/rules/route.js` compile | present `.next/server/app/api/ai/rules/` | PASS |

---

## 7. Push GHCR

| Image | Tag | Manifest digest |
|---|---|---|
| keybuzz-api | v3.5.185-ai-rules-read-tenantguard-dev | `sha256:d671a247f59ab27383daceab55e3fe87d2b594d1f5ac44fb58ba70ea6e40bbcd` (size 2416) |
| keybuzz-client | v3.5.196-ai-rules-bff-dev | `sha256:7a5f8e83652b694fd4f23ce2417f34ec5892c8d81f4d6a3252ca9ff7177efcae` (size 2631) |

KEY-309 immuables. KEY-308 conserves apres push.

---

## 8. GitOps DEV apply

### 8.1 Commit manifests infra

Commit `01ca110 deploy(dev): promote AS.12.2C-5A API+Client (KEY-301 /ai/rules + /playbooks READ tenantGuard)` push origin/main 0-0. 2 fichiers, 1 ligne chacun (image + commentaire phase + rollback).

### 8.2 Apply API DEV

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
deployment.apps/keybuzz-api configured
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.185-ai-rules-read-tenantguard-dev | OK |
| pod imageID nouveau | `sha256:d671a247f59ab27383daceab55e3fe87d2b594d1f5ac44fb58ba70ea6e40bbcd` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:50ebb39228ea...` (v3.5.184) | OK rollout normal |

### 8.3 Apply Client DEV

```
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
deployment.apps/keybuzz-client configured
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=300s
deployment "keybuzz-client" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.196-ai-rules-bff-dev | OK |
| pod imageID nouveau | `sha256:7a5f8e83652b694fd4f23ce2417f34ec5892c8d81f4d6a3252ca9ff7177efcae` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:10ab15de30c1...` (v3.5.195) | OK rollout normal |

---

## 9. Validation DEV

### 9.1 /health DEV

```
GET https://api-dev.keybuzz.io/health -> 200
```

### 9.2 Preserve + NEW protections 14/14 PASS

| # | Endpoint | Method | Phase | Body / query | Observed | Verdict |
|---|---|---|---|---|---|---|
| 5A-N1 | /ai/rules | GET | NEW | `tenantId=fake-uuid` | 401 | PASS |
| 5A-N2 | /playbooks | GET | NEW | `tenantId=fake-uuid` | 401 | PASS |
| 5A-N3 | /playbooks/22222222-2222-2222-2222-222222222222 | GET | NEW (dynamic matcher) | `tenantId=fake-uuid` | 401 | PASS |
| 5A-N4 | /playbooks/suggestions | GET | NEW (exact) | `tenantId=fake-uuid` | 401 | PASS |
| P1 | /ai/execute | POST | AS.12.2C-4 preserve | `{tenantId,ruleId,conversationId}` | 401 | PASS |
| P2 | /ai/evaluate | POST | AS.12.2C-3 preserve | `{tenantId,conversationId}` | 401 | PASS |
| P3 | /ai/assist | POST | AS.12.2C-1 preserve | `{tenantId,contextType}` | 401 | PASS |
| P4 | /ai/guard/check | POST | AS.12.2C-2 preserve | `{tenantId}` | 401 | PASS |
| P5 | /messages/conversations | GET | KEY-304 preserve | `tenantId=fake-uuid` | 401 | PASS |
| P6 | /tenants | GET | AS.12.1A preserve | -- | 401 | PASS |
| P7 | /notifications | GET | AS.12.1B preserve | `tenantId=fake-uuid` | 401 | PASS |
| P8 | /autopilot/draft | GET | AS.12.2B preserve | `tenantId=fake-uuid&conversationId=fake` | 401 | PASS |
| P9 | /ai/settings | GET | AS.12.2D preserve | `tenantId=fake-uuid` | 401 | PASS |
| P10 | /ai/wallet/status | GET | AS.12.2D preserve | `tenantId=fake-uuid` | 401 | PASS |

**14/14 PASS** avec payloads valides (UUIDs fictifs). Aucun POST / PATCH / PUT / DELETE positif emis.

### 9.3 Dynamic matcher `isPlaybookDetailGet` verifie en runtime

Test 5A-N3 confirme : `GET /playbooks/22222222-2222-2222-2222-222222222222?tenantId=fake-uuid` retourne 401 (tenantGuard rejette pour absence X-User-Email). Le matcher `isPlaybookDetailGet` resoult bien le pattern dynamique et active la protection.

Test 5A-N4 confirme : `GET /playbooks/suggestions?tenantId=fake-uuid` retourne 401 et est resolu par PROTECTED_ROUTES static (avant matcher dynamique), conforme au design (priorite exact > dynamique).

### 9.4 Logs

| Source | Filtre | Count |
|---|---|---|
| API DEV `statusCode 5xx / level=50` | 5min | 0 |
| Client DEV `JWT_SESSION_ERROR` | 5min | 1 |

Le `JWT_SESSION_ERROR` Client unique est un transient typique pendant rollout pod terminating (la session NextAuth peut brievement fail entre l ancien et le nouveau pod). 1 occurrence sur 5min ne constitue pas un spike. Accepte par Ludovic comme transient.

### 9.5 DB no-mutation

| Mesure | Pre-deploy | Post-validation 5min |
|---|---|---|
| `ai_rules` total | 465 | inchange (aucune mutation positive emise) |
| `ai_rule_conditions` total | 124 | inchange |
| `ai_rule_actions` total | 1116 | inchange |
| `playbook_suggestions` 24h | 0 | inchange |

Aucun POST / PUT / PATCH / DELETE positif emis. Aucune creation / modification / suppression de regle. tenantGuard rejette en preHandler avant atteinte du handler -> 0 ecriture DB de notre fait.

### 9.6 Snapshot inventory post-apply

DEV API : `v3.5.185-ai-rules-read-tenantguard-dev` (PROMU). DEV Client : `v3.5.196-ai-rules-bff-dev` (PROMU). 11 autres services DEV inchanges.

**PROD strictement inchange** :

| Namespace / Deploy | Image PROD (inchangee) |
|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.184-ai-execute-tenantguard-prod |
| keybuzz-api-prod / keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| keybuzz-admin-v2-prod / keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |
| keybuzz-backend-prod / amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod / amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod |
| keybuzz-backend-prod / backfill-scheduler | v1.0.42-td02-worker-resilience-prod |
| keybuzz-backend-prod / keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| keybuzz-client-prod / keybuzz-client | v3.5.195-ai-execute-bff-prod |
| keybuzz-studio-prod / keybuzz-studio | v0.8.0-prod |
| keybuzz-studio-api-prod / keybuzz-studio-api | v0.8.1-prod |
| keybuzz-website-prod / keybuzz-website | v0.6.12-linkedin-insight-seo-prod |
| keybuzz-seller-dev / seller-api | v2.0.5-ph-prod-ftp-02 (hors KEY-301) |
| keybuzz-seller-dev / seller-client | v2.0.7-ph-prod-ftp-02b (hors KEY-301) |

13 services PROD inventories, 11 strictement inchanges (api + client non-PROD touches cette phase). 2 hors KEY-301.

---

## 10. QA Ludovic navigateur DEV

URL DEV correcte : **`https://client-dev.keybuzz.io`** (ingress + NEXTAUTH_URL alignes, cf rapport AS.12.2C-4-PROD section 4).

Resultat Ludovic :
- Inbox OK
- Brouillon IA auto OK (sur conversations non bloquees par garde-fous metier GP1)
- tenant switcher OK
- escalation badge OK
- playbooks pages read-only semblent OK (list + detail + suggestions)
- aucun comportement casse observe
- 1 `JWT_SESSION_ERROR` accepte comme transient rollout (pas de spike durable)

**Verdict QA** : GO AI RULES READ TENANTGUARD DEV READY.

Note : aucun test mutationnel (create / edit / delete / toggle playbook) effectue car AS.12.2C-5A est read-only. Les mutations seront testees apres AS.12.2C-5B-IMPL.

---

## 11. AI feature parity / anti-regression DEV

| Surface | Statut DEV post AS.12.2C-5A | Justification |
|---|---|---|
| Tenant switcher | OK | preserve |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2B+AS.12.2D preserve) | inchange ; pattern GP1 (KEY-312) inchange |
| AISuggestionSlideOver | OK (AS.12.2C-1/2/3 preserve) | inchange |
| /ai/execute protection | OK (AS.12.2C-4 preserve) | inchange |
| Playbooks pages list/detail/tester | OK protege (5A NEW) | tenantGuard membership check, BFF deja safe |
| Playbooks pages suggestions | OK protege (5A NEW) | idem |
| /ai/rules GET protection | OK NEW (BFF + tenantGuard) | aucun caller actif, anticipation future |
| Playbooks mutations (create/edit/delete/toggle/apply/dismiss) | INCHANGE non-protege | scope AS.12.2C-5B |

---

## 12. No-mutation proof (DEV phase)

| Item | Statut |
|---|---|
| Aucun patch source PROD | OK |
| Aucun build / push / deploy PROD | OK |
| Aucun POST / PUT / PATCH / DELETE positif vers /ai/rules ou /playbooks | OK |
| Aucune creation / modification / suppression de regle | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucune mutation DB (ai_rules/conditions/actions/suggestions) | OK (counts inchanges) |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Bastion install-v3 only | OK |
| GitOps strict (kubectl apply -f only) | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement read-only | OK |
| Branches imposees respectees (api ph147.4 / client ph148 / infra main) | OK |
| Commit+push AVANT build (PH152) | OK |
| Build from-git fresh clone | OK |
| KEY-309 + KEY-308 + KEY-302 conformes | OK |

---

## 13. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 01ca110 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.184-ai-execute-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml   # -> v3.5.195-ai-execute-bff-dev
kubectl -n keybuzz-client-dev rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur GET /playbooks pour tenant authentifie -> regression list playbooks.
- Spike 5xx API DEV.
- Spike JWT_SESSION_ERROR Client DEV durable (>5 occurrences soutenues).
- QA Ludovic confirme list / detail playbook inaccessible pour son tenant.

---

## 14. Linear text prepared (disclosure-controlled)

### 14.1 KEY-301 commentaire cible

```
## AS.12.2C-5A hardening READ rules + playbooks DEV -- GO READY

Implementation delivered following the AS.12.2C-5 design audit (5A scope = READ only) :
- API tenantGuard.ts : 3 PROTECTED_ROUTES (GET /ai/rules + GET /playbooks + GET /playbooks/suggestions) + new isPlaybookDetailGet matcher for GET /playbooks/:id dynamic detail.
- Client : new BFF `app/api/ai/rules/route.ts` GET (NextAuth + X-User-Email + X-Tenant-Id forward).
- `/api/playbooks/*` (7 BFF routes) already safe -- no refactor required.

Runtime DEV :
- API : v3.5.184 -> v3.5.185-ai-rules-read-tenantguard-dev (digest sha256:d671a247f59ab27383daceab55e3fe87d2b594d1f5ac44fb58ba70ea6e40bbcd, OCI revision ccbcb9afad31fb9e115c782eecf729be640322b1).
- Client : v3.5.195 -> v3.5.196-ai-rules-bff-dev (digest sha256:7a5f8e83652b694fd4f23ce2417f34ec5892c8d81f4d6a3252ca9ff7177efcae, OCI revision b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb).
- Manifest commit 01ca110, GitOps strict, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complete, KEY-302 sentinel absent, bundle DEV api-dev.keybuzz.io only.

Validation DEV :
- 14/14 preserve protections at 401 unauthenticated (10 preserve from earlier phases + 4 NEW READ : /ai/rules, /playbooks, /playbooks/:id dynamic matcher, /playbooks/suggestions).
- 0 5xx API DEV 5min. 1 JWT_SESSION_ERROR Client DEV transient (rollout pod terminating, accepted as transient).
- DB no-mutation : ai_rules 465 / ai_rule_conditions 124 / ai_rule_actions 1116 / playbook_suggestions 24h 0 -- all unchanged (no positive mutation emitted).
- PROD strictly unchanged (DEV-only manifests touched, 13 PROD services intact).

QA Ludovic browser DEV (https://client-dev.keybuzz.io) : Inbox + Brouillon IA + tenant switcher + escalation + playbooks pages read-only OK. No regression observed.

Verdict : **GO AI RULES READ TENANTGUARD DEV READY**. No rollback triggered.

Remaining KEY-301 sub-phases :
- AS.12.2C-5A-PROD (coordinated promotion, eligible after Ludovic GO).
- AS.12.2C-5B (mutations DEV+PROD : POST /ai/rules + 6 mutation endpoints /playbooks).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-DEV-01.md
```

---

## 15. Compliance DEV

| Verification | Statut |
|---|---|
| Bastion install-v3 only | OK |
| Branches imposees respectees | OK |
| Commit+push AVANT build (PH152) | OK |
| Build from-git fresh clone | OK |
| KEY-309 tags immuables | OK |
| KEY-308 OCI labels complets | OK |
| KEY-302 sentinel Client bundle absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Apply order API then Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| Aucun patch source PROD | OK |
| Aucune mutation DB | OK |
| Aucun POST/PUT/PATCH/DELETE positif | OK |
| Aucune mutation rule (5B differe) | OK |
| Aucune generation LLM / KBActions / debit wallet | OK |
| Aucun draftText / PII | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| PROD strictement read-only | OK |
| QA Ludovic confirme aucune regression UX | OK |

---

## 16. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-5A-PROD promotion coordonnee reste a livrer apres GO Ludovic | High | Phase suivante |
| G2 | AS.12.2C-5B (mutations DEV puis PROD : POST /ai/rules + POST /playbooks + PUT/DELETE /playbooks/:id + PATCH /playbooks/:id/toggle + PATCH /playbooks/suggestions/:id/apply + PATCH /playbooks/suggestions/:id/dismiss) reste a livrer | High | Phase suivante apres AS.12.2C-5A-PROD |
| G3 | BFF `/api/playbooks/[id]/simulate` et `/[id]/suggestions` pointent vers endpoints API potentiellement absents | Low | Clarifier durant 5B ou RCA dediee |
| G4 | Plan gating absent sur /ai/rules + /playbooks | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G5 | Admin v2 mock pur sur rules ; future connexion API necessitera BFF + tenantGuard (deja prevu via 5A+5B) | Low | A documenter quand admin v2 branche |
| G6 | Backlog 33 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |
| GP1 | (rappel) Brouillon IA silent failure -- Linear KEY-312 cree | Medium | Decision produit en cours, hors KEY-301 |

---

## 17. Phrase cible finale

AS.12.2C-5A implementation DEV livre : 2 patches source (API `src/plugins/tenantGuard.ts` +52/-2 : header doc block AS.12.2C-5A + 3 PROTECTED_ROUTES entries `GET /ai/rules` + `GET /playbooks` + `GET /playbooks/suggestions` + nouveau matcher dynamique `isPlaybookDetailGet` 22 lignes + 1 ligne `isProtected` ; Client nouveau `app/api/ai/rules/route.ts` 70 lignes GET BFF NextAuth + X-User-Email + X-Tenant-Id injection) ; commits sources `ccbcb9af` (api ph147.4) + `b726970` (client ph148) push origin 0-0 ; build DEV API + Client from-git via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets ; bundle Client DEV KEY-302 sentinel absent + api-dev.keybuzz.io x2 + api.keybuzz.io x0 + BFF `/api/ai/rules/route.js` compile dans `.next/server/app/api/ai/rules/` ; verify-image-clean 17 PASS / 0 FAIL ; docker push GHCR API digest `sha256:d671a247f59ab27383daceab55e3fe87d2b594d1f5ac44fb58ba70ea6e40bbcd` + Client digest `sha256:7a5f8e83652b694fd4f23ce2417f34ec5892c8d81f4d6a3252ca9ff7177efcae` (KEY-309 immuables) ; manifest infra commit `01ca110` push origin main 0-0 ; 2 kubectl apply -f DEV sequentiels + rollouts successful ; spec = last-applied = pod imageID = digest pushe pour API + Client ; preserve+NEW 14/14 (GET /ai/rules NEW + GET /playbooks NEW + GET /playbooks/22222222-...-2222 dynamic matcher NEW + GET /playbooks/suggestions NEW + 10 preserve POST /ai/execute + POST /ai/evaluate + POST /ai/assist + POST /ai/guard/check + GET /messages/conversations + GET /tenants + GET /notifications + GET /autopilot/draft + GET /ai/settings + GET /ai/wallet/status tous 401 no-auth avec payloads valides) ; 0 5xx API DEV 5min + 1 JWT_SESSION_ERROR Client DEV transient rollout (accepte par Ludovic) ; DB no-mutation `ai_rules`=465 / `ai_rule_conditions`=124 / `ai_rule_actions`=1116 / `playbook_suggestions` 24h=0 tous inchanges (aucun POST/PUT/PATCH/DELETE positif emis, aucune mutation rule) ; QA Ludovic navigateur DEV `https://client-dev.keybuzz.io` : Inbox + Brouillon IA + tenant switcher + escalation + playbooks pages read-only OK, aucune regression UX ; PROD strictement read-only et inchange (13 services PROD intacts dont api v3.5.184-prod + client v3.5.195-prod + 11 autres) ; aucune mutation source PROD / build dirty / push tag reuse / mutation DB / generation IA / KBActions / wallet artificiel / draftText / PII ; KEY-301 reste Open epic ; AS.12.2C-5A ferme en DEV ; AS.12.2C-5A-PROD eligible apres GO Ludovic ; AS.12.2C-5B (mutations) reste a livrer ; gaps G1-G6 + GP1 (KEY-312) documentes ; verdict AS.12.2C-5A DEV GO AI RULES READ TENANTGUARD DEV READY.

STOP
