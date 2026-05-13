# PH-SAAS-T8.12AS.12.2C-5B-AI-RULES-MUTATIONS-TENANTGUARD-HARDENING-DEV-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-5B -- implementation hardening MUTATIONS rules + playbooks en DEV (tenantGuard API-only)
> Environnement : DEV ; PROD strictement read-only et inchange

---

## 1. VERDICT

GO AI RULES MUTATIONS TENANTGUARD DEV READY

Implementation des 7 endpoints MUTATIONS de la surface rules (5B) livree en DEV selon le design audit AS.12.2C-5 :
- API : `v3.5.185-ai-rules-read-tenantguard-dev` -> `v3.5.186-ai-rules-mut-tenantguard-dev` (digest GHCR `sha256:59d18bc554f3cc6848c8ba55c22761d37734d05275fc6f63db54a90622729ceb`, OCI revision `05bb57cd6b0d312abf69c6e13608a71fbf2929f5`).
- Client DEV : **inchange** `v3.5.196-ai-rules-bff-dev` (aucun patch source Client requis).
- Manifest infra commit `7ba540e` push origin/main 0-0.
- 1 kubectl apply -f DEV API + rollout successful ; spec = last-applied = pod imageID = digest pushe.

Validation negative DEV : **21/21 protections actives** :
- **7 NEW MUTATIONS (AS.12.2C-5B)** : `POST /ai/rules`, `POST /playbooks`, `PUT /playbooks/:id`, `DELETE /playbooks/:id`, `PATCH /playbooks/:id/toggle`, `PATCH /playbooks/suggestions/:id/apply`, `PATCH /playbooks/suggestions/:id/dismiss` tous 401 unauthenticated.
- **4 preserve READ AS.12.2C-5A** : `GET /ai/rules`, `GET /playbooks`, `GET /playbooks/:id`, `GET /playbooks/suggestions` tous 401 (matcher dynamique 5A non casse par 5B).
- **10 preserve KEY-304 + AS.12.1A/1B + AS.12.2B + AS.12.2C-1/2/3/4 + AS.12.2D** tous 401 avec payloads valides.

Logs DEV 5min : 0 5xx API + 0 JWT_SESSION_ERROR Client. PROD strictement inchange (API v3.5.185-prod + Client v3.5.196-prod + 11 autres services).

QA Ludovic navigateur DEV (`https://client-dev.keybuzz.io`) : playbooks pages list/detail/suggestions read-only consultes **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss** ; Inbox + Brouillon IA + tenant switcher + escalation OK. **Aucune regression visible**.

DB no-mutation parfait : `ai_rules`=465, `ai_rule_conditions`=124, `ai_rule_actions`=1116, `playbook_suggestions`=10. **Tous counts strictement identiques pre + post deploy**. Aucun POST/PUT/PATCH/DELETE positif emis : tenantGuard preHandler rejette en 401 avant atteinte du handler.

KEY-301 reste Open epic. **AS.12.2C-5B ferme en DEV**. Sous-phase restante : **AS.12.2C-5B-PROD** (coordinated promotion, eligible apres GO Ludovic).

---

## 2. Scope

Inclus :
- 1 patch source API `src/plugins/tenantGuard.ts` : header doc block 5B + 2 PROTECTED_ROUTES exact (POST /ai/rules + POST /playbooks) + 3 matchers dynamiques (isPlaybookDetailMutation + isPlaybookTogglePatch + isPlaybookSuggestionActionPatch) + 3 lignes isProtected.
- 1 commit + push sur branche imposee (api ph147.4/source-of-truth).
- Build API DEV from-git via scripts patches AS.12.2C-3.1 (KEY-308 OCI complets, KEY-309 immuable).
- 1 docker push GHCR (API uniquement).
- 1 commit + push manifest infra DEV (1 fichier, 1 ligne).
- 1 kubectl apply -f DEV API + rollout.
- Validation negative 21/21 + logs + DB no-mutation snapshot pre/post.
- QA Ludovic navigateur DEV read-only.
- Rapport docs-only ASCII strict + commit + push.

Hors scope strict :
- **Aucun patch Client** : BFF `/api/playbooks/*` (7 routes) deja safe NextAuth + X-User-Email ; BFF `/api/ai/rules` POST handler **non ajoute** car aucun caller Client `executeAI`/`createAIRule` n existe (CRUD reel passe par `/api/playbooks/*` + `usePlaybooks` hook).
- **Aucun build Client DEV** : runtime Client DEV reste `v3.5.196-ai-rules-bff-dev` (acquis AS.12.2C-5A DEV).
- **Aucun test positif mutationnel** authentifie.
- **Aucune creation / modification / suppression / toggle / apply / dismiss** de regle/playbook/suggestion.
- Aucune fixture / dry-run / fake data.
- Aucun build PROD / push PROD / deploy PROD / manifest PROD.
- AS.12.2C-5B-PROD (coordinated promotion).
- Resolution gap produit GP1 (KEY-312 separe).
- Plan gating /ai/rules + /playbooks (gap operationnel separe).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`.
- `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-DEV-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-PROD-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-DEV-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-PROD-01.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md`.
- `keybuzz-api/src/plugins/tenantGuard.ts` (insertion points apres matchers 5A).
- `keybuzz-api/src/modules/playbooks/routes.ts` (handlers POST/PUT/DELETE/PATCH lignes 61-303).
- `keybuzz-api/src/modules/ai/routes.ts` (handler POST /rules ligne 251).
- `keybuzz-client/app/api/playbooks/route.ts` (BFF GET+POST deja safe).
- `keybuzz-client/app/api/playbooks/[id]/route.ts` (BFF GET+PUT+DELETE deja safe).
- `keybuzz-client/app/api/playbooks/[id]/toggle/route.ts` (BFF PATCH deja safe).
- `keybuzz-client/app/api/playbooks/suggestions/[id]/[action]/route.ts` (BFF PATCH apply/dismiss deja safe).
- `keybuzz-client/src/hooks/usePlaybooks.ts` (8 fetch sites BFF safe).
- `keybuzz-client/app/api/ai/rules/route.ts` (BFF GET cree en 5A, POST non ajoute en 5B faute de caller).

---

## 4. Preflight

| Repo | Path | Branche | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | ccbcb9af (pre-patch) | 0-0 | 0 (dist/ exclu) | OK |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | b726970 | 0-0 | 0 | OK (non touche cette phase) |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | 1bcda82 (post AS.12.2C-5A-PROD) | 0-0 | 0 | OK |

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| Runtime DEV API pre-patch | v3.5.185-ai-rules-read-tenantguard-dev | OK baseline AS.12.2C-5A |
| Runtime DEV Client | v3.5.196-ai-rules-bff-dev | OK (inchange tout au long 5B) |
| Runtime PROD API | v3.5.185-ai-rules-read-tenantguard-prod | OK (read-only) |
| Runtime PROD Client | v3.5.196-ai-rules-bff-prod | OK (read-only) |
| `assert-git-committed.sh` | api + client propres -- BUILD AUTORISE | OK |
| KEY-309 tag `v3.5.186-ai-rules-mut-tenantguard-dev` | GHCR manifest unknown | OK libre |
| DB baseline DEV ai_rules total | 465 rows | OK |
| DB baseline DEV ai_rule_conditions | 124 rows | OK |
| DB baseline DEV ai_rule_actions | 1116 rows | OK |
| DB baseline DEV playbook_suggestions | 10 rows | OK |

---

## 5. Audit endpoints + Client coverage

### 5.1 Endpoints API a proteger (5B)

| # | Method | Path | Source API | Type matcher tenantGuard | Risque DB |
|---|---|---|---|---|---|
| M1 | POST | /ai/rules | `src/modules/ai/routes.ts:251` | exact (PROTECTED_ROUTES) | INSERT ai_rules + conditions + actions |
| M2 | POST | /playbooks | `src/modules/playbooks/routes.ts:61` | exact (PROTECTED_ROUTES) | INSERT ai_rules + cascade conditions + actions (transactionnel) |
| M3 | PUT | /playbooks/:id | `routes.ts:116` | dynamic (isPlaybookDetailMutation) | UPDATE ai_rules + REPLACE conditions + REPLACE actions |
| M4 | DELETE | /playbooks/:id | `routes.ts:179` | dynamic (isPlaybookDetailMutation) | DELETE ai_rules + cascade |
| M5 | PATCH | /playbooks/:id/toggle | `routes.ts:206` | dynamic (isPlaybookTogglePatch) | UPDATE ai_rules SET status |
| M6 | PATCH | /playbooks/suggestions/:id/apply | `routes.ts:259` | dynamic (isPlaybookSuggestionActionPatch) | UPDATE playbook_suggestions + INSERT/UPDATE ai_rules |
| M7 | PATCH | /playbooks/suggestions/:id/dismiss | `routes.ts:284` | dynamic (isPlaybookSuggestionActionPatch) | UPDATE playbook_suggestions SET dismissed |

### 5.2 Client BFF coverage

| Endpoint API | BFF Client | NextAuth | X-User-Email injecte | tenantId via | Patch requis | Verdict |
|---|---|---|---|---|---|---|
| POST /ai/rules | `app/api/ai/rules/route.ts` | GET only (5A) | -- | -- | **POST NON ajoute** (aucun caller Client) | accepte |
| POST /playbooks | `app/api/playbooks/route.ts` | OK | OK | body | NON | safe |
| PUT /playbooks/:id | `app/api/playbooks/[id]/route.ts` | OK | OK | body | NON | safe |
| DELETE /playbooks/:id | `app/api/playbooks/[id]/route.ts` | OK | OK | query | NON | safe |
| PATCH /playbooks/:id/toggle | `app/api/playbooks/[id]/toggle/route.ts` | OK | OK | body | NON | safe |
| PATCH /playbooks/suggestions/:id/apply | `app/api/playbooks/suggestions/[id]/[action]/route.ts` | OK | OK | body | NON | safe |
| PATCH /playbooks/suggestions/:id/dismiss | idem | OK | OK | body | NON | safe |

**Conclusion** : aucun patch Client requis. BFF `/api/playbooks/*` deja safe ; BFF `/api/ai/rules` POST non ajoute par scope minimal (aucun caller actuel pour POST /ai/rules cote Client ; CRUD reel passe par `/api/playbooks/*` + hook `usePlaybooks`).

---

## 6. Patch source

### 6.1 keybuzz-api : `src/plugins/tenantGuard.ts`

Modifications (+89 / -3) sur 1 fichier :

**A. Header doc** : ajout block AS.12.2C-5B detaillant les 7 endpoints + remplacement du commentaire "AS.12.2C-5B deferred" obsolete.

**B. PROTECTED_ROUTES** : ajout 2 entries exact-path apres le bloc 5A :
```typescript
// PH-SAAS-T8.12AS.12.2C-5B KEY-301: AI rules + playbooks MUTATION exact paths.
// PUT/DELETE/PATCH dynamic forms are handled by the dedicated matchers below.
{ method: 'POST', path: '/ai/rules' },
{ method: 'POST', path: '/playbooks' },
```

**C. 3 matchers dynamiques** ajoutes apres `isPlaybookDetailGet` (5A) :
- `isPlaybookDetailMutation` : matche PUT/DELETE /playbooks/:id (1 segment, pas de /, pas de :id null).
- `isPlaybookTogglePatch` : matche PATCH /playbooks/:id/toggle (exactement 2 segments, dernier = `toggle`).
- `isPlaybookSuggestionActionPatch` : matche PATCH /playbooks/suggestions/:id/apply ou /dismiss (prefix `/playbooks/suggestions/`, 2 segments dont dernier `apply` ou `dismiss`).

**D. isProtected** : ajout 3 lignes pour invoquer les 3 nouveaux matchers apres `isPlaybookDetailGet`.

### 6.2 Files changed

| Fichier | Repo | Lignes | Type | Risque | Mitigation |
|---|---|---|---|---|---|
| `src/plugins/tenantGuard.ts` | keybuzz-api | +89/-3 | Add PROTECTED_ROUTES + matchers + doc | matcher dynamique trop permissif | tests negatifs runtime confirment scope ; 5A read non casse |

Aucun autre fichier touche dans aucun repo source.

Commit API : `05bb57cd feat(security): protect AI rules/playbooks mutations via tenantGuard (KEY-301 AS.12.2C-5B)` push origin/ph147.4/source-of-truth 0-0.

Commit Client : **aucun** (BFF playbooks deja safe, /api/ai/rules POST non requis).

---

## 7. Build evidence

### 7.1 Build API DEV

```
bash scripts/build-api-from-git.sh dev v3.5.186-ai-rules-mut-tenantguard-dev ph147.4/source-of-truth
```

Build OK, Git SHA `05bb57c` (= HEAD post-push). Local Image Id `sha256:572a88073b5501f5e07e1d76f7a0da5e1d107e0ad6941a5b6f1f07e5a0a5e5bc`.

OCI labels KEY-308 :

| Label | Valeur | Verdict |
|---|---|---|
| revision | `05bb57cd6b0d312abf69c6e13608a71fbf2929f5` (SHA complet) | PASS |
| created | `2026-05-13T17:40:11Z` (ISO 8601 UTC) | PASS |
| version | `v3.5.186-ai-rules-mut-tenantguard-dev` | PASS |
| source | `https://github.com/keybuzzio/keybuzz-api` | PASS |
| title | `keybuzz-api` | PASS |

### 7.2 Build Client DEV

**Skipped** : aucun patch source Client cette phase. Runtime Client DEV reste `v3.5.196-ai-rules-bff-dev` (image GHCR + pod imageID inchanges).

### 7.3 KEY-309 tag check (pre-push)

```
docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.186-ai-rules-mut-tenantguard-dev
-> manifest unknown (libre)
```

---

## 8. Push GHCR

| Image | Tag | Manifest digest | Size |
|---|---|---|---|
| keybuzz-api | v3.5.186-ai-rules-mut-tenantguard-dev | `sha256:59d18bc554f3cc6848c8ba55c22761d37734d05275fc6f63db54a90622729ceb` | 2416 |

KEY-309 immuable. KEY-308 conserves apres push.

---

## 9. GitOps DEV apply

### 9.1 Commit manifest infra

Commit `7ba540e deploy(dev): promote AS.12.2C-5B API (KEY-301 /ai/rules + /playbooks MUTATIONS tenantGuard)` push origin/main 0-0 :
- `k8s/keybuzz-api-dev/deployment.yaml` : 1 ligne image+commentaire (v3.5.185 -> v3.5.186).
- `k8s/keybuzz-client-dev/deployment.yaml` : **non touche** (Client inchange).

### 9.2 Apply API DEV

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
deployment.apps/keybuzz-api configured
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.186-ai-rules-mut-tenantguard-dev | OK |
| last-applied-configuration | identique | OK |
| pod imageID nouveau | `sha256:59d18bc554f3cc6848c8ba55c22761d37734d05275fc6f63db54a90622729ceb` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:d671a247f59a...` (v3.5.185) | OK rollout normal |

### 9.3 Client DEV (non touche)

```
kubectl -n keybuzz-client-dev get deploy keybuzz-client -o jsonpath="{.spec.template.spec.containers[0].image}"
ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-dev
```

Aucun apply Client cette phase. Runtime Client DEV inchange.

---

## 10. Security validation negative-only

### 10.1 /health DEV

```
GET https://api-dev.keybuzz.io/health -> 200
```

### 10.2 Tests 5B NEW (7 mutations, no-auth, payloads representatifs)

UUIDs fictifs : `tenantId=00000000-...`, `playbookId=22222222-...`, `suggestionId=33333333-...`.

| Test | Endpoint | Method | Matcher | Observed | Verdict |
|---|---|---|---|---|---|
| 5B-N1 | /ai/rules | POST | exact PROTECTED_ROUTES | 401 | PASS |
| 5B-N2 | /playbooks | POST | exact PROTECTED_ROUTES | 401 | PASS |
| 5B-N3 | /playbooks/22222222-...-2222 | PUT | isPlaybookDetailMutation | 401 | PASS |
| 5B-N4 | /playbooks/22222222-...-2222 | DELETE | isPlaybookDetailMutation | 401 | PASS |
| 5B-N5 | /playbooks/22222222-...-2222/toggle | PATCH | isPlaybookTogglePatch | 401 | PASS |
| 5B-N6 | /playbooks/suggestions/33333333-...-3333/apply | PATCH | isPlaybookSuggestionActionPatch | 401 | PASS |
| 5B-N7 | /playbooks/suggestions/33333333-...-3333/dismiss | PATCH | isPlaybookSuggestionActionPatch | 401 | PASS |

### 10.3 Tests preserve 5A READ (4 endpoints)

| Test | Endpoint | Method | Phase | Observed | Verdict |
|---|---|---|---|---|---|
| 5A-N1 | /ai/rules | GET | AS.12.2C-5A | 401 | PASS |
| 5A-N2 | /playbooks | GET | AS.12.2C-5A | 401 | PASS |
| 5A-N3 | /playbooks/22222222-...-2222 | GET (dynamic isPlaybookDetailGet) | AS.12.2C-5A | 401 | PASS |
| 5A-N4 | /playbooks/suggestions | GET | AS.12.2C-5A | 401 | PASS |

Matchers dynamiques 5A et 5B coexistent correctement : `isPlaybookDetailGet` reste limite a GET ; `isPlaybookDetailMutation` capture seulement PUT/DELETE ; aucun conflit observe.

### 10.4 Tests preserve 10 autres protections

| Endpoint | Method | Phase | Observed | Verdict |
|---|---|---|---|---|
| /ai/execute | POST | AS.12.2C-4 | 401 | PASS |
| /ai/evaluate | POST | AS.12.2C-3 | 401 | PASS |
| /ai/assist | POST | AS.12.2C-1 | 401 | PASS |
| /ai/guard/check | POST | AS.12.2C-2 | 401 | PASS |
| /messages/conversations | GET | KEY-304 | 401 | PASS |
| /tenants | GET | AS.12.1A | 401 | PASS |
| /notifications | GET | AS.12.1B | 401 | PASS |
| /autopilot/draft | GET | AS.12.2B | 401 | PASS |
| /ai/settings | GET | AS.12.2D | 401 | PASS |
| /ai/wallet/status | GET | AS.12.2D | 401 | PASS |

**21/21 PASS** avec payloads valides (UUIDs fictifs). **Aucun POST/PUT/PATCH/DELETE positif emis** : tenantGuard preHandler rejette en 401 avant atteinte du handler.

---

## 11. DB no-mutation proof

### 11.1 Counts pre et post deploy

| Mesure | Pre-deploy | Post-deploy 10min | Delta | Verdict |
|---|---|---|---|---|
| `ai_rules` total | 465 | 465 | 0 | PASS |
| `ai_rule_conditions` total | 124 | 124 | 0 | PASS |
| `ai_rule_actions` total | 1116 | 1116 | 0 | PASS |
| `playbook_suggestions` total | 10 | 10 | 0 | PASS |

**Aucune mutation DB observee**. Validation 100% negative confirmee :
- Tests negatifs envoyent payloads `{tenantId, name?, ruleId?, ...}` sans header `X-User-Email`.
- tenantGuard preHandler reject 401 `AUTH_REQUIRED` avant atteinte du handler.
- 0 INSERT / UPDATE / DELETE sur `ai_rules`, `ai_rule_conditions`, `ai_rule_actions`, `playbook_suggestions` causes par cette phase.

Note : ce snapshot 0-delta est plus precis que AS.12.2C-5A-PROD (qui avait observe +15 rules / +4 conditions / +36 actions sur 10min causes par activite tenant naturelle de seeding). En 5B-DEV, la fenetre de validation n a coincide avec aucun seeding/onboarding, d ou le 0-delta strict.

---

## 12. Smoke / logs / QA Ludovic

### 12.1 Smoke V1

`scripts/smoke-v1.sh` absent du repo bastion (cf rapports AS.12.2C-4 + AS.12.2C-5A). Skipped (non bloquant pour cette phase).

### 12.2 Logs DEV

| Source | Filtre | Count | Verdict |
|---|---|---|---|
| API DEV `statusCode 5xx / level=50` | 5min | 0 | PASS |
| Client DEV `JWT_SESSION_ERROR` | 5min | 0 | PASS |

### 12.3 QA Ludovic navigateur DEV

URL DEV : **`https://client-dev.keybuzz.io`** (ingress + NEXTAUTH_URL alignes, cf AS.12.2C-4-PROD section 4 / AS.12.2C-5A).

Resultat Ludovic :
- Playbooks pages list/detail/suggestions consultes en read-only, **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss**.
- Inbox OK.
- Brouillon IA OK sur les cas attendus (pattern PRE_LLM_BLOCKED:HIGH / ESCALATION_DRAFT:0.75 inchange, cf GP1 KEY-312).
- tenant switcher OK.
- escalation badge OK.
- Aucune regression visible.

**Verdict QA** : GO AI RULES MUTATIONS TENANTGUARD DEV READY.

---

## 13. PROD unchanged proof

| Service | PROD image before 5B-DEV | PROD image after 5B-DEV | Status |
|---|---|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.185-ai-rules-read-tenantguard-prod | idem (inchange) | OK |
| keybuzz-client-prod / keybuzz-client | v3.5.196-ai-rules-bff-prod | idem (inchange) | OK |
| keybuzz-api-prod / keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | idem | OK |
| keybuzz-admin-v2-prod / keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | idem | OK |
| keybuzz-backend-prod / amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | idem | OK |
| keybuzz-backend-prod / amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | idem | OK |
| keybuzz-backend-prod / backfill-scheduler | v1.0.42-td02-worker-resilience-prod | idem | OK |
| keybuzz-backend-prod / keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | idem | OK |
| keybuzz-studio-prod / keybuzz-studio | v0.8.0-prod | idem | OK |
| keybuzz-studio-api-prod / keybuzz-studio-api | v0.8.1-prod | idem | OK |
| keybuzz-website-prod / keybuzz-website | v0.6.12-linkedin-insight-seo-prod | idem | OK |
| keybuzz-seller-dev / seller-api | v2.0.5-ph-prod-ftp-02 | idem (hors KEY-301) | OK |
| keybuzz-seller-dev / seller-client | v2.0.7-ph-prod-ftp-02b | idem (hors KEY-301) | OK |

13 services PROD inventories ; **0 promu** cette phase ; **13 strictement inchanges**. Aucun build/push/deploy/manifest PROD touche.

---

## 14. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 7ba540e --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml      # -> v3.5.185-ai-rules-read-tenantguard-dev
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=240s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur GET /playbooks (5A read) pour tenant authentifie -> regression matcher trop large.
- Spike 5xx API DEV.
- Spike JWT_SESSION_ERROR Client DEV durable.
- QA Ludovic confirme list / detail / suggestions playbooks inaccessibles pour son tenant.

Note : Client DEV inchange, donc rollback Client non applicable.

---

## 15. AI feature parity / anti-regression DEV

| Surface | Statut DEV post AS.12.2C-5B | Justification |
|---|---|---|
| Tenant switcher | OK | preserve |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2B+AS.12.2D preserve) ; pattern GP1 (KEY-312) inchange | gap produit hors scope |
| AISuggestionSlideOver | OK (AS.12.2C-1/2/3 preserve) | inchange |
| /ai/execute protection | OK (AS.12.2C-4 preserve) | inchange |
| Playbooks pages list/detail/suggestions read-only | OK (5A preserve, dynamic matcher 5A non casse par 5B) | tenantGuard membership check, BFF deja safe |
| /ai/rules + /playbooks MUTATIONS | NEW protege (5B NEW) | tenantGuard ferme la fabrication cross-tenant de regles |
| Playbooks pages create/edit/delete/toggle (UI mutationnel) | inchange en DEV (non clique par QA, aucun test positif) ; protection cote API active | UX a re-confirmer en QA mutationnelle apres 5B-PROD si necessaire |

---

## 16. Linear text prepared (disclosure-controlled)

### 16.1 KEY-301 commentaire cible (a poster apres methode token disponible)

```
## AS.12.2C-5B hardening MUTATIONS rules + playbooks DEV -- GO READY

Implementation delivered following AS.12.2C-5 design audit (5B scope = MUTATIONS) :
- API tenantGuard.ts : 2 PROTECTED_ROUTES exact (POST /ai/rules + POST /playbooks) + 3 dynamic matchers (isPlaybookDetailMutation for PUT/DELETE /playbooks/:id, isPlaybookTogglePatch for PATCH /playbooks/:id/toggle, isPlaybookSuggestionActionPatch for PATCH /playbooks/suggestions/:id/[apply|dismiss]).
- Client : **no source change**. BFF /api/playbooks/* (7 routes) already safe (NextAuth + X-User-Email). BFF /api/ai/rules POST NOT added (no Client caller exists; real CRUD path is /api/playbooks/* + usePlaybooks hook).

Runtime DEV :
- API : v3.5.185 -> v3.5.186-ai-rules-mut-tenantguard-dev (digest sha256:59d18bc554f3cc6848c8ba55c22761d37734d05275fc6f63db54a90622729ceb, OCI revision 05bb57cd6b0d312abf69c6e13608a71fbf2929f5).
- Client DEV unchanged at v3.5.196-ai-rules-bff-dev.
- Manifest commit 7ba540e, GitOps strict, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complete, KEY-309 immuable.

Validation DEV :
- 21/21 preserve protections at 401 unauthenticated (10 preserve from earlier phases + 4 preserve 5A READ + 7 NEW 5B MUTATIONS).
- 0 5xx API DEV 5min. 0 JWT_SESSION_ERROR Client DEV 5min.
- DB no-mutation : ai_rules 465 / ai_rule_conditions 124 / ai_rule_actions 1116 / playbook_suggestions 10 -- all unchanged pre + post deploy (validation 100% negative ; tenantGuard preHandler rejects 401 before handler).
- PROD strictly unchanged (13 PROD services intact).

QA Ludovic browser DEV (https://client-dev.keybuzz.io) : playbooks pages list/detail/suggestions consulted read-only WITHOUT clicking any create/edit/delete/toggle/apply/dismiss button. Inbox + Brouillon IA + tenant switcher + escalation OK. No regression observed.

Verdict : **GO AI RULES MUTATIONS TENANTGUARD DEV READY**. No rollback triggered.

Remaining KEY-301 sub-phase : AS.12.2C-5B-PROD (coordinated promotion, eligible after Ludovic GO).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no PII, no draftText.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5B-AI-RULES-MUTATIONS-TENANTGUARD-HARDENING-DEV-01.md
```

Note : backlog 35 jeux de commentaires Linear KEY-* accumules en attente d acces token API (gap G6 hors-chat).

---

## 17. Compliance DEV

| Verification | Statut |
|---|---|
| Bastion install-v3 only / 46.62.171.61 | OK |
| Branches imposees respectees (api ph147.4 / client ph148 / infra main) | OK |
| Commit+push AVANT build (PH152) | OK |
| Build from-git fresh clone | OK |
| KEY-309 tag immuable (pre-push manifest unknown) | OK |
| KEY-308 OCI labels complets sur image pushee | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Pas de Client build ni Client apply | OK (Client non touche) |
| spec = last-applied = pod imageID = digest pushe | OK API |
| Aucun patch source PROD | OK |
| Aucune mutation DB de notre fait | OK (counts strictement unchanged) |
| Aucun POST/PUT/PATCH/DELETE positif vers rules/playbooks | OK |
| Aucune creation/modification/suppression/toggle/apply/dismiss de regle | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucun draftText / PII | OK |
| Aucun secret display | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear (prepared, non poste cette phase) | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| PROD strictement read-only | OK |
| QA Ludovic confirme aucune regression UX sur URL correcte client-dev.keybuzz.io | OK |
| Aucun ajout BFF Client inutile (POST /api/ai/rules differe car aucun caller) | OK scope minimal |

---

## 18. Gaps remaining

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-5B-PROD promotion coordonnee reste a livrer apres GO Ludovic | High | Phase suivante |
| G2 | BFF `/api/playbooks/[id]/simulate` et `/[id]/suggestions` pointent vers endpoints API potentiellement absents (cf design audit AS.12.2C-5 section gaps) | Low | Clarifier durant 5B-PROD ou RCA dediee |
| G3 | Plan gating absent sur /ai/rules + /playbooks (requirePlan non applique) | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G4 | Admin v2 mock pur sur rules (`AI_AUTOMATION_RULES_MOCK`) -- aucune connexion API runtime ; future connection necessitera BFF + tenantGuard deja prets | Low | A documenter quand admin v2 branche real rules |
| G5 | BFF /api/ai/rules POST handler differe (pas de caller actuel) -- a creer si future Client integration emerge | Low | Anticipation a faire si caller apparait |
| G6 | Backlog 35 jeux de commentaires Linear KEY-* accumules en attente methode token | Low | Resoudre methode token hors-chat |
| GP1 | (rappel) Brouillon IA silent failure -- Linear KEY-312 cree, decision produit en attente | Medium | Hors scope KEY-301 ; tracking dedie |

---

## 19. Next phase recommendation

**AS.12.2C-5B-PROD** : promotion coordonnee API uniquement (Client PROD reste v3.5.196 inchange).

Build PROD propose :
- Tag API : `v3.5.186-ai-rules-mut-tenantguard-prod` (depuis HEAD `05bb57cd`).
- Aucun build Client (deja a v3.5.196 PROD).

Validation PROD attendue : 21/21 negative protections + 0 5xx + 0 JWT spike + DB no-mutation strict.

QA Ludovic PROD a effectuer sur `https://client.keybuzz.io` :
- playbooks pages list/detail/suggestions read-only ;
- ne pas cliquer create/edit/delete/toggle/apply/dismiss ;
- Inbox + Brouillon IA + tenant switcher + escalation OK.

Apres GO PROD : KEY-301 epic AI rules+playbooks surface complete. Reste alors les gaps generaux KEY-301 epic (G3 plan gating, G4 admin v2 future, G5 BFF POST anticipation, GP1 KEY-312 produit).

---

## 20. Phrase cible finale

AS.12.2C-5B implementation DEV livre : 1 patch source API `src/plugins/tenantGuard.ts` (+89/-3) ; aucun patch Client (BFF playbooks deja safe, BFF /api/ai/rules POST non ajoute car aucun caller Client) ; commit source `05bb57cd feat(security): protect AI rules/playbooks mutations via tenantGuard (KEY-301 AS.12.2C-5B)` push origin/ph147.4/source-of-truth 0-0 ; build API DEV from-git via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets (revision `05bb57cd6b0d312abf69c6e13608a71fbf2929f5`, created `2026-05-13T17:40:11Z`, version `v3.5.186-ai-rules-mut-tenantguard-dev`) ; docker push GHCR API digest `sha256:59d18bc554f3cc6848c8ba55c22761d37734d05275fc6f63db54a90622729ceb` (KEY-309 immuable) ; manifest infra commit `7ba540e` push origin main 0-0 (1 fichier `keybuzz-api-dev/deployment.yaml`, 1 ligne) ; 1 kubectl apply -f API DEV + rollout successful ; spec = last-applied = pod imageID = digest pushe ; Client DEV strictement inchange `v3.5.196-ai-rules-bff-dev` (aucun build/apply Client cette phase) ; preserve+NEW 21/21 (7 NEW MUTATIONS POST /ai/rules + POST /playbooks + PUT /playbooks/:uuid (isPlaybookDetailMutation) + DELETE /playbooks/:uuid (isPlaybookDetailMutation) + PATCH /playbooks/:uuid/toggle (isPlaybookTogglePatch) + PATCH /playbooks/suggestions/:uuid/apply (isPlaybookSuggestionActionPatch) + PATCH /playbooks/suggestions/:uuid/dismiss (isPlaybookSuggestionActionPatch) + 4 preserve 5A READ + 10 autres preserve tous 401 no-auth avec payloads valides) ; 3 nouveaux matchers dynamiques verifies en runtime ; 0 5xx API DEV 5min + 0 JWT spike Client DEV 5min ; DB no-mutation STRICT (`ai_rules`=465, `ai_rule_conditions`=124, `ai_rule_actions`=1116, `playbook_suggestions`=10 -- counts strictement identiques pre + post deploy, aucune mutation causee par cette phase) ; QA Ludovic navigateur DEV `https://client-dev.keybuzz.io` : playbooks pages list/detail/suggestions consultes en read-only **sans cliquer aucun bouton create/edit/delete/toggle/apply/dismiss** + Inbox + Brouillon IA + tenant switcher + escalation OK, aucune regression visible ; PROD strictement read-only et inchange 13 services PROD intacts (api v3.5.185-prod + client v3.5.196-prod + 11 autres) ; aucune mutation source PROD / build dirty / push tag reuse / mutation DB / creation/modification/suppression de regle / generation IA / KBActions / wallet / draftText / PII ; KEY-301 reste Open epic ; AS.12.2C-5B ferme en DEV ; AS.12.2C-5B-PROD eligible apres GO Ludovic ; gaps G1-G6 + GP1 (KEY-312) documentes ; verdict AS.12.2C-5B DEV GO AI RULES MUTATIONS TENANTGUARD DEV READY.

STOP. AS.12.2C-5B DEV livre. Aucun enchainement vers PROD sans GO explicite Ludovic.
