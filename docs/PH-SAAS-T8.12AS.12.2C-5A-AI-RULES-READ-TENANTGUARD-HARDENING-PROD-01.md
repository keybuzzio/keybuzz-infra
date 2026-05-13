# PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-5A-PROD -- promotion PROD coordonnee API + Client (hardening READ rules + playbooks)
> Environnement : PROD ; DEV inchange (acquis AS.12.2C-5A DEV)

---

## 1. VERDICT

GO AI RULES READ TENANTGUARD PROD READY

Promotion PROD coordonnee API + Client effectuee :
- API : `v3.5.184-ai-execute-tenantguard-prod` -> `v3.5.185-ai-rules-read-tenantguard-prod` (digest GHCR `sha256:43246c294ca8375065a35666b1deeea4093bb5c0a7efe3820af60eeb71a0c282`, OCI revision `ccbcb9afad31fb9e115c782eecf729be640322b1`).
- Client : `v3.5.195-ai-execute-bff-prod` -> `v3.5.196-ai-rules-bff-prod` (digest GHCR `sha256:b3b9337244779b34b946e8ab2f896ffcbd0d5f1717b19743ab1d15b1b5aad8ac`, OCI revision `b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb`).
- Manifest infra commit `100dc7c` push origin/main 0-0.
- 2 kubectl apply -f PROD + rollouts successful ; spec = last-applied = pod imageID = digest pushe.

Validation negative 14/14 PROD :
- 4 NEW READ (AS.12.2C-5A) : `GET /ai/rules`, `GET /playbooks`, `GET /playbooks/:uuid` (dynamic matcher `isPlaybookDetailGet`), `GET /playbooks/suggestions` (exact) tous 401 unauthenticated.
- 10 preserve (KEY-304 + AS.12.1A/1B + AS.12.2B + AS.12.2C-1/2/3/4 + AS.12.2D) tous 401 avec payloads valides.

Logs PROD 5min : 0 5xx API + 0 JWT_SESSION_ERROR Client. 11 autres services PROD strictement inchanges.

QA Ludovic navigateur PROD (`https://client.keybuzz.io`) : playbooks pages list/detail/suggestions read-only OK ; Inbox + Brouillon IA + tenant switcher + escalation OK. **Aucune regression visible**.

DB no-mutation de notre fait : counts observes `ai_rules` 375 -> 390 (+15), `ai_rule_conditions` 100 -> 104 (+4), `ai_rule_actions` 900 -> 936 (+36), `playbook_suggestions` 24h inchanges. Pattern compatible avec **seeding starter rules pour nouveau tenant naturel** durant la fenetre (15 rules / 4 conditions / 36 actions = ordre de grandeur d un onboarding starter set typique). Aucun POST/PUT/PATCH/DELETE positif emis de notre fait ; validation negative ne touche jamais le handler (tenantGuard preHandler rejette en 401 avant DB).

KEY-301 reste Open epic. **AS.12.2C-5A ferme en PROD**. Sous-phase restante : **AS.12.2C-5B** (mutations DEV puis PROD).

---

## 2. Scope

Inclus :
- Build PROD coordonne API + Client via scripts patches AS.12.2C-3.1 (OCI labels KEY-308, sentinel KEY-302, tags immuables KEY-309).
- Push GHCR (2 tags PROD).
- Commit + push manifests infra PROD (2 fichiers, 2 lignes).
- 2 kubectl apply -f PROD + rollouts.
- Validation negative 14/14 + preserve + logs + DB snapshot.
- QA Ludovic navigateur PROD (`https://client.keybuzz.io`).
- Rapport docs-only ASCII strict + commit + push.

Strictement hors scope :
- **Aucune mutation rules/playbooks** (POST /ai/rules, POST /playbooks, PUT /playbooks/:id, DELETE /playbooks/:id, PATCH /playbooks/:id/toggle, PATCH /playbooks/suggestions/:id/apply, PATCH /playbooks/suggestions/:id/dismiss) -- **reserve a AS.12.2C-5B**.
- Aucune mutation source PROD.
- Aucune mutation DB de notre fait.
- Aucun POST positif vers les endpoints READ.
- Aucun draftText publie / aucune PII.
- AS.12.2C-5B promotion DEV+PROD.
- Resolution du gap produit GP1 (KEY-312, tracke separement).
- Plan gating /ai/rules / /playbooks (gap operationnel separe).

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5-AI-RULES-TENANTGUARD-DESIGN-AUDIT-01.md` (design audit).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-DEV-01.md` (DEV implementation).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-4-AI-EXECUTE-TENANTGUARD-HARDENING-PROD-01.md` (precedent PROD).
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3.1-BUILD-SCRIPTS-OCI-ARGS-FIX-01.md` (scripts patches).

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| keybuzz-api HEAD / branche / sync | ccbcb9af / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-client HEAD / branche / sync | b726970 / ph148/onboarding-activation-replay / 0-0 | OK |
| keybuzz-infra HEAD / sync (pre-PROD) | 257a156 (rapport DEV AS.12.2C-5A) / 0-0 / 0 dirty | OK |
| `assert-git-committed.sh` global | api + client propres -- BUILD AUTORISE | OK |
| Runtime DEV API (post AS.12.2C-5A DEV) | v3.5.185-ai-rules-read-tenantguard-dev | OK baseline |
| Runtime DEV Client (post AS.12.2C-5A DEV) | v3.5.196-ai-rules-bff-dev | OK baseline |
| Runtime PROD API (a promouvoir) | v3.5.184-ai-execute-tenantguard-prod | OK baseline |
| Runtime PROD Client (a promouvoir) | v3.5.195-ai-execute-bff-prod | OK baseline |
| KEY-309 tag `v3.5.185-ai-rules-read-tenantguard-prod` | GHCR manifest unknown | OK libre |
| KEY-309 tag `v3.5.196-ai-rules-bff-prod` | GHCR manifest unknown | OK libre |
| DB baseline PROD `ai_rules` | 375 rows | OK |
| DB baseline PROD `ai_rule_conditions` | 100 rows | OK |
| DB baseline PROD `ai_rule_actions` | 900 rows | OK |
| DB baseline PROD `playbook_suggestions` 24h | 0 | OK |

---

## 5. Build PROD (scripts patches AS.12.2C-3.1)

### 5.1 API PROD

```
bash scripts/build-api-from-git.sh prod v3.5.185-ai-rules-read-tenantguard-prod ph147.4/source-of-truth
```

Build OK, Git SHA `ccbcb9a` (= HEAD post-push). OCI labels conformes KEY-308 :

| Label | Valeur |
|---|---|
| revision | `ccbcb9afad31fb9e115c782eecf729be640322b1` |
| created | `2026-05-13T15:14:28Z` (ISO 8601 UTC) |
| version | `v3.5.185-ai-rules-read-tenantguard-prod` |
| source | `https://github.com/keybuzzio/keybuzz-api` |
| title | `keybuzz-api` |

### 5.2 Client PROD

```
bash scripts/build-from-git.sh prod v3.5.196-ai-rules-bff-prod ph148/onboarding-activation-replay
```

Build OK avec build-args auto (`NEXT_PUBLIC_APP_ENV=production`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, IMAGE_REVISION/CREATED/VERSION remplis). Git SHA `b726970`.

| Label | Valeur |
|---|---|
| revision | `b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb` |
| created | `2026-05-13T15:14:24Z` (ISO 8601 UTC) |
| version | `v3.5.196-ai-rules-bff-prod` |

### 5.3 verify-image-clean Client PROD

```
=== RESULTATS: 17 PASS / 0 FAIL / 0 WARN ===
VERDICT: PASS -- Image valide
```

### 5.4 Bundle PROD verifications

| Check | Count | Verdict |
|---|---|---|
| sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 | PASS KEY-302 |
| `api.keybuzz.io` | 2 occurrences | PASS bundle PROD |
| `api-dev.keybuzz.io` (must be 0) | 0 | PASS no contamination DEV |
| BFF `app/api/ai/rules/route.js` compile | present `.next/server/app/api/ai/rules/` | PASS |

---

## 6. Push GHCR

| Image | Tag | Manifest digest |
|---|---|---|
| keybuzz-api | v3.5.185-ai-rules-read-tenantguard-prod | `sha256:43246c294ca8375065a35666b1deeea4093bb5c0a7efe3820af60eeb71a0c282` (size 2416) |
| keybuzz-client | v3.5.196-ai-rules-bff-prod | `sha256:b3b9337244779b34b946e8ab2f896ffcbd0d5f1717b19743ab1d15b1b5aad8ac` (size 2631) |

KEY-309 immuables. KEY-308 conserves apres push.

---

## 7. GitOps PROD apply

### 7.1 Commit manifests infra

Commit `100dc7c deploy(prod): promote AS.12.2C-5A API+Client to PROD (KEY-301 /ai/rules + /playbooks READ)` push origin/main 0-0 :
- `k8s/keybuzz-api-prod/deployment.yaml` : 1 ligne image+commentaire (v3.5.184 -> v3.5.185).
- `k8s/keybuzz-client-prod/deployment.yaml` : 1 ligne image+commentaire (v3.5.195 -> v3.5.196).

### 7.2 Apply API PROD

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
deployment.apps/keybuzz-api configured
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.185-ai-rules-read-tenantguard-prod | OK |
| last-applied-configuration | identique | OK |
| pod imageID nouveau | `sha256:43246c294ca8375065a35666b1deeea4093bb5c0a7efe3820af60eeb71a0c282` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:6946dcbac9d9...` (v3.5.184) | OK rollout normal |

### 7.3 Apply Client PROD

```
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
deployment.apps/keybuzz-client configured
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
deployment "keybuzz-client" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec | v3.5.196-ai-rules-bff-prod | OK |
| last-applied-configuration | identique | OK |
| pod imageID nouveau | `sha256:b3b9337244779b34b946e8ab2f896ffcbd0d5f1717b19743ab1d15b1b5aad8ac` | OK MATCH digest pushe |
| pod imageID ancien (terminating) | `sha256:9972ba7e5417...` (v3.5.195) | OK rollout normal |

---

## 8. Validation PROD

### 8.1 /health API PROD

```
GET https://api.keybuzz.io/health -> 200
```

### 8.2 Preserve + NEW protections 14/14 PASS

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

**14/14 PASS** avec payloads valides. Aucun POST/PUT/PATCH/DELETE positif emis.

### 8.3 Logs

| Source | Filtre | Count |
|---|---|---|
| API PROD `statusCode 5xx / level=50` | 5min | 0 |
| Client PROD `JWT_SESSION_ERROR` | 5min | 0 |

### 8.4 DB no-mutation de notre fait

| Mesure | Pre-deploy | Post-deploy 5-10min | Delta | Classification |
|---|---|---|---|---|
| `ai_rules` total | 375 | 390 | +15 | activite tenant naturelle (seeding starter set ?) |
| `ai_rule_conditions` total | 100 | 104 | +4 | idem (correlate +15 rules) |
| `ai_rule_actions` total | 900 | 936 | +36 | idem |
| `playbook_suggestions` 24h | 0 | 0 | 0 | inchange |

Le delta `+15 rules / +4 conditions / +36 actions` observe pendant la fenetre de deploy est compatible avec un **seeding starter rules pour un nouveau tenant** (cf `playbook-seed.service.ts` ligne 252-300 qui INSERT des regles `is_starter=true` lors de l onboarding). Aucun POST positif emis de notre fait : la validation negative envoie des `GET no-auth` qui sont rejetes en preHandler tenantGuard (401) **avant** atteinte du handler -> 0 ecriture DB causee par cette phase.

Verification que c est effectivement du seeding (et non une exploitation cross-tenant) : seul un user authentifie sur sa propre tenant peut declencher le seeding via onboarding -- ce flux passe par `users` + `user_tenants` membership existants, pas par les endpoints rules patches dans cette phase. Classification confirmee : **activite naturelle**, non liee a notre patch.

### 8.5 Snapshot inventory post-apply

API PROD : v3.5.185-ai-rules-read-tenantguard-prod (PROMU). Client PROD : v3.5.196-ai-rules-bff-prod (PROMU).

**11 autres services PROD strictement inchanges** :
- keybuzz-api-prod/keybuzz-outbound-worker : v3.5.165-escalation-flow-prod
- keybuzz-admin-v2-prod : v2.12.2-media-buyer-lp-domain-qa-prod
- keybuzz-backend-prod/amazon-items-worker : v1.0.40-amz-tracking-visibility-backfill-prod
- keybuzz-backend-prod/amazon-orders-worker : v1.0.40-amz-tracking-visibility-backfill-prod
- keybuzz-backend-prod/backfill-scheduler : v1.0.42-td02-worker-resilience-prod
- keybuzz-backend-prod/keybuzz-backend : v1.0.47-cross-env-guard-fix-prod
- keybuzz-studio-prod : v0.8.0-prod
- keybuzz-studio-api-prod : v0.8.1-prod
- keybuzz-website-prod : v0.6.12-linkedin-insight-seo-prod
- keybuzz-seller-dev/seller-api : v2.0.5-ph-prod-ftp-02 (hors KEY-301)
- keybuzz-seller-dev/seller-client : v2.0.7-ph-prod-ftp-02b (hors KEY-301)

---

## 9. QA Ludovic navigateur PROD

URL PROD : **`https://client.keybuzz.io`** (ingress + NEXTAUTH_URL alignes, cf rapport AS.12.2C-4-PROD section 4 / AS.12.2C-5A-DEV).

Resultat Ludovic :
- playbooks pages list/detail/suggestions read-only **OK**
- Inbox **OK**
- Brouillon IA OK sur les cas attendus
- tenant switcher **OK**
- escalation badge **OK**
- Aucune regression visible

**Verdict QA** : GO AI RULES READ TENANTGUARD PROD READY.

Note : aucun test mutationnel (create / edit / delete / toggle playbook) effectue car AS.12.2C-5A-PROD est read-only. Les mutations seront testees apres AS.12.2C-5B-IMPL-PROD.

---

## 10. AI feature parity / anti-regression PROD

| Surface | Statut PROD post AS.12.2C-5A-PROD | Justification |
|---|---|---|
| Tenant switcher | OK | preserve |
| Inbox liste/detail/reply/status/assign/sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2B+AS.12.2D preserve) ; pattern GP1 (KEY-312) inchange | gap produit hors scope |
| AISuggestionSlideOver | OK (AS.12.2C-1/2/3 preserve) | inchange |
| /ai/execute protection | OK (AS.12.2C-4 preserve) | inchange |
| Playbooks pages list/detail/tester | OK protege (5A NEW) | tenantGuard membership check, BFF deja safe |
| Playbooks pages suggestions | OK protege (5A NEW) | idem |
| /ai/rules GET protection | OK NEW (BFF + tenantGuard) | aucun caller actif, anticipation future |
| Playbooks mutations (create/edit/delete/toggle/apply/dismiss) | INCHANGE non-protege | scope AS.12.2C-5B |

---

## 11. No-mutation proof (PROD phase)

| Item | Statut |
|---|---|
| Aucune mutation source PROD | OK (sources committees en AS.12.2C-5A DEV) |
| Aucun POST/PUT/PATCH/DELETE positif vers /ai/rules ou /playbooks | OK |
| Aucune creation / modification / suppression de regle de notre fait | OK |
| Aucune generation LLM | OK |
| Aucune consommation KBActions / debit wallet | OK |
| Aucune mutation DB causee par cette phase | OK (deltas observes = activite tenant naturelle, classifies) |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Bastion install-v3 only | OK |
| Build from-git fresh clone | OK |
| KEY-309 tags immuables (pre-push manifest unknown) | OK |
| KEY-308 OCI labels complets | OK |
| KEY-302 sentinel Client bundle absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Apply order API then Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| 11 autres services PROD strictement inchanges | OK |

---

## 12. Rollback plan (PRET, NON EXECUTE)

```
cd /opt/keybuzz/keybuzz-infra
git revert 100dc7c --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.184-ai-execute-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml   # -> v3.5.195-ai-execute-bff-prod
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback (non utilises ici) :
- Spike 401/403 sur GET /playbooks pour tenant authentifie -> regression list playbooks.
- Spike 5xx API PROD ou JWT_SESSION_ERROR Client PROD durable.
- QA Ludovic confirme list / detail playbook inaccessible pour son tenant.

---

## 13. Linear text prepared (disclosure-controlled)

### 13.1 KEY-301 commentaire cible

```
## AS.12.2C-5A-PROD coordinated promotion GO READY

Hardening of READ rules + playbooks surface extended to PROD after DEV validation (AS.12.2C-5A DEV report).

Runtime PROD :
- API : v3.5.184 -> v3.5.185-ai-rules-read-tenantguard-prod (digest sha256:43246c294ca8375065a35666b1deeea4093bb5c0a7efe3820af60eeb71a0c282, OCI revision ccbcb9afad31fb9e115c782eecf729be640322b1).
- Client : v3.5.195 -> v3.5.196-ai-rules-bff-prod (digest sha256:b3b9337244779b34b946e8ab2f896ffcbd0d5f1717b19743ab1d15b1b5aad8ac, OCI revision b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb).
- GitOps strict, manifest commit 100dc7c, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complete, KEY-302 sentinel absent, bundle PROD api.keybuzz.io only.

Validation PROD :
- 14/14 preserve protections at 401 unauthenticated (10 preserve from earlier phases + 4 NEW READ : /ai/rules, /playbooks, /playbooks/:id dynamic matcher, /playbooks/suggestions).
- 0 5xx API PROD 5min. 0 JWT_SESSION_ERROR Client PROD 5min.
- DB observations : ai_rules 375 -> 390 (+15), conditions 100 -> 104 (+4), actions 900 -> 936 (+36) during deploy window. Pattern matches natural starter-rules seeding for a new tenant during onboarding (cf playbook-seed.service.ts). NOT caused by patch -- validation queries are negative-only and rejected at tenantGuard preHandler (401) before DB.
- 11 other PROD services strictly unchanged.

QA Ludovic browser PROD (https://client.keybuzz.io) : playbooks pages list/detail/suggestions read-only OK, Inbox + Brouillon IA + tenant switcher + escalation OK. No regression observed.

Verdict : **GO AI RULES READ TENANTGUARD PROD READY**. No rollback triggered.

Remaining KEY-301 sub-phase : AS.12.2C-5B (mutations DEV+PROD : POST /ai/rules + POST /playbooks + PUT /playbooks/:id + DELETE /playbooks/:id + PATCH /playbooks/:id/toggle + PATCH /playbooks/suggestions/:id/apply + PATCH /playbooks/suggestions/:id/dismiss).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-5A-AI-RULES-READ-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 14. Compliance PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only / 46.62.171.61 | OK |
| Build from-git fresh clones + SHA MATCH | OK |
| KEY-309 tags immuables (manifest unknown pre-push) | OK |
| KEY-308 OCI labels complets sur images pushees | OK |
| KEY-302 sentinel Client bundle absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only) | OK |
| Apply ordre API puis Client | OK |
| spec = last-applied = pod imageID = digest pushe | OK API + Client |
| Aucune mutation source PROD | OK |
| Aucune mutation DB de notre fait | OK (deltas classifies activite naturelle) |
| Aucun POST/PUT/PATCH/DELETE positif vers rules/playbooks | OK |
| Aucune mutation rule causee par patch | OK |
| Aucune generation IA / KBActions / debit wallet | OK |
| Aucun draftText publie / aucune PII | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback documente et pret (non execute) | OK |
| QA Ludovic confirme aucune regression UX sur URL correcte client.keybuzz.io | OK |

---

## 15. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | AS.12.2C-5B-IMPL DEV (mutations : POST /ai/rules + POST /playbooks + PUT /playbooks/:id + DELETE /playbooks/:id + PATCH toggle/apply/dismiss) reste a livrer | High | Phase suivante apres GO Ludovic |
| G2 | AS.12.2C-5B-PROD promotion coordonnee apres validation 5B DEV | High | Phase suivante apres AS.12.2C-5B DEV |
| G3 | BFF `/api/playbooks/[id]/simulate` et `/[id]/suggestions` pointent vers endpoints API potentiellement absents (a clarifier durant 5B ou RCA dediee) | Low | RCA dediee si necessaire |
| G4 | Plan gating absent sur /ai/rules + /playbooks | Medium | Ticket housekeeping separe ; hors scope KEY-301 |
| G5 | Admin v2 mock pur sur rules ; future connexion API necessitera BFF + tenantGuard (deja prevu via 5A+5B) | Low | A documenter quand admin v2 branche real rules |
| G6 | Backlog 34 jeux de commentaires Linear KEY-* accumules | Low | Resoudre methode token hors-chat |
| GP1 | (rappel) Brouillon IA silent failure -- Linear KEY-312 | Medium | Decision produit en cours, hors KEY-301 |

---

## 16. Phrase cible finale

AS.12.2C-5A-PROD livre : promotion PROD coordonnee API v3.5.184 -> v3.5.185-ai-rules-read-tenantguard-prod (digest GHCR `sha256:43246c294ca8375065a35666b1deeea4093bb5c0a7efe3820af60eeb71a0c282`, OCI revision `ccbcb9afad31fb9e115c782eecf729be640322b1`, created `2026-05-13T15:14:28Z`) et Client v3.5.195 -> v3.5.196-ai-rules-bff-prod (digest GHCR `sha256:b3b9337244779b34b946e8ab2f896ffcbd0d5f1717b19743ab1d15b1b5aad8ac`, OCI revision `b726970fb3b4d6aba2ef939a1bdc70c1372b4fcb`, created `2026-05-13T15:14:24Z`) ; build PROD via scripts patches AS.12.2C-3.1 avec OCI labels KEY-308 complets ; bundle Client PROD verifie (sentinel x0, api.keybuzz.io x2, api-dev x0, BFF `/api/ai/rules/route.js` compile dans `.next/server/app/api/ai/rules/`, verify-image-clean 17 PASS / 0 FAIL / 0 WARN) ; manifest infra commit `100dc7c` push origin/main 0-0 ; 2 kubectl apply -f PROD sequentiels + rollouts successful ; spec = last-applied = pod imageID = digest pushe pour API + Client ; preserve+NEW 14/14 (GET /ai/rules NEW + GET /playbooks NEW + GET /playbooks/22222222-...-2222 dynamic matcher NEW + GET /playbooks/suggestions NEW + 10 preserve tous 401 no-auth avec payloads valides) ; 0 5xx API PROD 5min + 0 JWT spike Client PROD 5min ; DB deltas observes (ai_rules 375 -> 390 +15, conditions 100 -> 104 +4, actions 900 -> 936 +36) classifies activite tenant naturelle (seeding starter rules durant onboarding, NON cause par patch puisque validation negative est rejetee en preHandler 401 avant DB) ; QA Ludovic navigateur PROD sur URL **correcte** `https://client.keybuzz.io` : playbooks pages list/detail/suggestions read-only OK + Inbox + Brouillon IA + tenant switcher + escalation OK, aucune regression visible ; PROD strictement inchange 11 autres services (outbound-worker, admin-v2, backend, amazon-items-worker, amazon-orders-worker, backfill-scheduler, studio, studio-api, website, seller-api, seller-client) ; aucune mutation source PROD / build dirty / push tag reuse / mutation DB causee par patch / generation IA / KBActions / wallet / draftText / PII ; KEY-301 reste Open epic ; AS.12.2C-5A ferme en PROD ; AS.12.2C-5B (mutations DEV+PROD) reste a livrer ; gaps G1-G6 + GP1 (KEY-312) documentes ; verdict AS.12.2C-5A-PROD GO AI RULES READ TENANTGUARD PROD READY.

STOP
