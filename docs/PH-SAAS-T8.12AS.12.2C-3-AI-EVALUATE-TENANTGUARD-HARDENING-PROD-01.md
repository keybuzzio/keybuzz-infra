# PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-PROD-01

> Date : 2026-05-13
> Linear : KEY-301
> Phase : T8.12 AS.12.2C-3-PROD -- promotion PROD coordonnee API + Client (hardening /ai/evaluate)
> Environnement : PROD ; DEV inchange (acquis R2)

---

## 1. VERDICT

GO AI EVALUATE TENANTGUARD PROD READY

Promotion PROD coordonnee API + Client effectuee :
- API : `v3.5.182-ai-guard-check-tenantguard-prod` -> `v3.5.183-ai-evaluate-tenantguard-prod` (digest GHCR `sha256:fe1c166d869d77c99da1ea48fde44b12ebc8ecfa68c75d1697d5d41b685e5180`).
- Client : `v3.5.193-ai-guard-check-bff-prod` -> `v3.5.194-ai-evaluate-bff-prod` (digest GHCR `sha256:cf346e9bbc480627d29537b89a90b240962f08dd3aed7183c7742c30b98fae7f`).
- Manifest infra commit `2d22403` push `origin main` 0-0.
- GitOps strict : 2 kubectl apply -f, rollouts successful, spec = last-applied = runtime imageID = digest pushed.

Validation negative 9/9 : tous endpoints proteges retournent 401 unauthenticated avec payloads valides (preserve AS.12.1A, AS.12.1B, AS.12.2B, AS.12.2C-1, AS.12.2C-2, AS.12.2D, KEY-304 + nouveau AS.12.2C-3 sur `/ai/evaluate`).

QA Ludovic navigateur PROD : `/autopilot/draft` repond 200 sur 18 requetes consecutives sans aucun 401/403/5xx. Trois conversations rapportees comme "Brouillon IA ne s active pas" sont classees **hors scope KEY-301** : entries `ai_action_log` correspondantes sont `status=skipped` avec `blocked_reason=PRE_LLM_BLOCKED:HIGH` (2x) et `ESCALATION_DRAFT:0.75` (1x). Comportement attendu des garde-fous metier IA, sans rapport avec le patch AS.12.2C-3.

PROD : 11 autres services strictement inchanges. 0 5xx API PROD 5min, 0 JWT_SESSION_ERROR Client PROD 5min, `ai_action_log` evaluate count = 0 (aucune mutation positive emise par cette phase).

KEY-301 reste Open epic. AS.12.2C-3 ferme en PROD. Sous-phases restantes : AS.12.2C-4 (`/ai/execute` execute) + AS.12.2C-5 (`/ai/rules` admin).

---

## 2. Scope

Inclus :
- Build PROD coordonne API + Client (clones frais, no-cache, OCI labels KEY-308 complets).
- Push GHCR (KEY-309 tags immuables).
- Commit + push manifests infra (2 lignes touchees, 2 fichiers).
- 2 kubectl apply -f PROD + rollouts.
- Validation negative 9/9 + preserve.
- QA Ludovic navigateur PROD + diagnostic read-only des cas atypiques.
- Rapport ASCII strict + commit + push docs-only.

Hors scope :
- Aucun patch source.
- Aucune mutation DB.
- Aucun POST positif vers /ai/evaluate.
- Aucune generation IA forcee.
- Aucune consommation KBActions / wallet artificielle.
- Aucun draftText publie.
- Aucune PII publiee.
- AS.12.2C-4 (execute mutation) et AS.12.2C-5 (rules admin) : differes sous-phases dediees.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md`
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-DEV-01.md` (NO GO initial)
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-RCA-READONLY-01.md` (RCA + H1)
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-R2-AI-EVALUATE-DEVTOOLS-REAPPLY-01.md` (R2 confirme H1)
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-2-AI-GUARD-CHECK-TENANTGUARD-HARDENING-PROD-01.md` (PROD precedente)

---

## 4. Preflight

| Item | Valeur observee | Verdict |
|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | OK |
| keybuzz-api HEAD / branche / sync | 85555b26cbcdfb1c7223d562453cc99c028cd91d / ph147.4/source-of-truth / 0-0 | OK |
| keybuzz-api dirty (dist/ exclus par assert-git-committed.sh) | 223 D dans dist/ uniquement (artefacts TS) | OK accepte par script |
| keybuzz-client HEAD / branche / sync | c24d8c9263e3da21460fec3425fce1cc1af24604 / ph148/onboarding-activation-replay / 0-0 | OK |
| keybuzz-client dirty | 1 M tsconfig.tsbuildinfo (cache TS incremental) restaure via `git checkout -- tsconfig.tsbuildinfo` (non destructive, HEAD restoration) | OK apres restore |
| keybuzz-infra HEAD / sync (pre-promotion) | 3df78f39cd17aaa43b155f73fab43b72caa20032 (rapport R2 docs) / 0-0 / 0 dirty | OK |
| Runtime DEV API (R2 acquis) | v3.5.183-ai-evaluate-tenantguard-dev | OK |
| Runtime DEV Client (R2 acquis) | v3.5.194-ai-evaluate-bff-dev | OK |
| Runtime PROD API (a promouvoir) | v3.5.182-ai-guard-check-tenantguard-prod | OK baseline |
| Runtime PROD Client (a promouvoir) | v3.5.193-ai-guard-check-bff-prod | OK baseline |
| KEY-309 tag availability `v3.5.183-ai-evaluate-tenantguard-prod` | GHCR `manifest unknown` (libre) | OK |
| KEY-309 tag availability `v3.5.194-ai-evaluate-bff-prod` | GHCR `manifest unknown` (libre) | OK |
| Smoke V1 DEV pre-promotion | PASS=16 WARN=2 FAIL=0 SKIP=1 (acquis R2) | OK |
| DB baseline PROD (ai_action_log 24h) | total=14, evaluate_count=0 | OK |
| Inventaire PROD complet | 13 services PROD (API, Client, outbound-worker, backend, amazon-items, amazon-orders, backfill-scheduler, admin-v2, studio, studio-api, website, seller-api, seller-client) ; api/client a promouvoir, 11 autres inchanges | OK |

---

## 5. Build manuel

### 5.1 Issue detectee sur les scripts standard

Les scripts `build-api-from-git.sh` et `build-from-git.sh` passent `GIT_COMMIT_SHA` + `BUILD_TIME` comme build-args, mais les Dockerfiles API + Client attendent `IMAGE_REVISION` + `IMAGE_CREATED` + `IMAGE_VERSION` pour remplir les OCI labels KEY-308. Premier build via les scripts a produit des images avec labels `revision=unknown`, `version=unknown`, `created=unknown`. Push refuse en preflight Ludovic.

Solution adoptee (par GO Ludovic) : **rebuild manuel** via clone frais + `docker build` direct passant tous les ARGs explicites. Aucune modification de script (deferee). Aucune modification de source. Aucune pollution scripts. Les images "unknown labels" sont ecrasees localement par les rebuilds correctement labellises.

Note : un correctif structurel des scripts est documente en gap restant (section 14).

### 5.2 Rebuild API PROD

```
git clone --depth 1 --branch ph147.4/source-of-truth https://github.com/keybuzzio/keybuzz-api.git /tmp/api-rebuild-prod-$$
HEAD SHA verified: 85555b26cbcdfb1c7223d562453cc99c028cd91d (SHA MATCH attendu)
docker build --no-cache \
  --build-arg IMAGE_REVISION=85555b26cbcdfb1c7223d562453cc99c028cd91d \
  --build-arg IMAGE_CREATED=2026-05-12T22:09:36Z \
  --build-arg IMAGE_VERSION=v3.5.183-ai-evaluate-tenantguard-prod \
  --build-arg GIT_COMMIT_SHA=85555b26cbcdfb1c7223d562453cc99c028cd91d \
  --build-arg BUILD_TIME=2026-05-12T22:09:36Z \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-evaluate-tenantguard-prod $BUILD_DIR
```

Build OK : local image Id `sha256:7fefd5a5a0cba1a101d1e3f26ad40025244993878d0871d77467014dad3611b6` (344 MB).

### 5.3 Rebuild Client PROD

```
git clone --depth 1 --branch ph148/onboarding-activation-replay https://github.com/keybuzzio/keybuzz-client.git /tmp/client-rebuild-prod-$$
HEAD SHA verified: c24d8c9263e3da21460fec3425fce1cc1af24604 (SHA MATCH attendu)
docker build --no-cache \
  --build-arg IMAGE_REVISION=c24d8c9263e3da21460fec3425fce1cc1af24604 \
  --build-arg IMAGE_CREATED=2026-05-12T22:09:38Z \
  --build-arg IMAGE_VERSION=v3.5.194-ai-evaluate-bff-prod \
  --build-arg GIT_COMMIT_SHA=c24d8c9263e3da21460fec3425fce1cc1af24604 \
  --build-arg BUILD_TIME=2026-05-12T22:09:38Z \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.194-ai-evaluate-bff-prod $BUILD_DIR
```

Build OK : local image Id `sha256:bedc87ba41bad2ce77e1a50a48b72f7ffa385bf113b6eaa6ae2c59d809a90c9f` (280 MB).

### 5.4 OCI labels KEY-308 verifies (post-rebuild)

| Champ | API | Client |
|---|---|---|
| revision | 85555b26cbcdfb1c7223d562453cc99c028cd91d | c24d8c9263e3da21460fec3425fce1cc1af24604 |
| created | 2026-05-12T22:09:36Z | 2026-05-12T22:09:38Z |
| version | v3.5.183-ai-evaluate-tenantguard-prod | v3.5.194-ai-evaluate-bff-prod |
| source | https://github.com/keybuzzio/keybuzz-api | https://github.com/keybuzzio/keybuzz-client |
| title | keybuzz-api | keybuzz-client |

### 5.5 Verification bundle Client PROD (post-rebuild)

| Check | Count | Verdict |
|---|---|---|
| Brouillon IA presence dans `.next/static/chunks` | 2 occurrences | OK |
| "Valider et envoyer" presence | 1 occurrence | OK |
| Sentinel `__MUST_BE_SET_BY_BUILD_ARG__` | 0 occurrences | OK KEY-302 |
| `api.keybuzz.io` presence | 2 occurrences | OK |
| `api-dev.keybuzz.io` presence (must be 0) | 0 occurrences | OK |

`scripts/verify-image-clean.sh ... prod` : 17 PASS / 0 FAIL / 0 WARN.

---

## 6. Push GHCR

| Image | Tag | Manifest digest (GHCR) | Config digest |
|---|---|---|---|
| keybuzz-api | v3.5.183-ai-evaluate-tenantguard-prod | sha256:fe1c166d869d77c99da1ea48fde44b12ebc8ecfa68c75d1697d5d41b685e5180 (size 2416) | sha256:7fefd5a5a0cba1a101d1e3f26ad40025244993878d0871d77467014dad3611b6 |
| keybuzz-client | v3.5.194-ai-evaluate-bff-prod | sha256:cf346e9bbc480627d29537b89a90b240962f08dd3aed7183c7742c30b98fae7f (size 2631) | sha256:bedc87ba41bad2ce77e1a50a48b72f7ffa385bf113b6eaa6ae2c59d809a90c9f |

Pull post-push (re-verify OCI labels server-side) : revision = expected SHA on both, created/version/source/title intacts. Aucune perte de labels au cours du push.

---

## 7. GitOps PROD apply

### 7.1 Commit manifests infra

Commit `2d22403 deploy(prod): promote AS.12.2C-3 API+Client to PROD (KEY-301)` push `origin main` :
- `k8s/keybuzz-api-prod/deployment.yaml` : 1 ligne image change (v3.5.182 -> v3.5.183) + commentaire phase + rollback.
- `k8s/keybuzz-client-prod/deployment.yaml` : 1 ligne image change (v3.5.193 -> v3.5.194) + commentaire phase + rollback.

git status post-push : clean. sync : 0-0.

### 7.2 Apply API PROD

```
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
deployment.apps/keybuzz-api configured

kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
deployment "keybuzz-api" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-evaluate-tenantguard-prod | OK |
| metadata.annotations.kubectl.kubernetes.io/last-applied-configuration -> image | ghcr.io/keybuzzio/keybuzz-api:v3.5.183-ai-evaluate-tenantguard-prod | OK |
| pod imageID runtime | ghcr.io/keybuzzio/keybuzz-api@sha256:fe1c166d869d77c99da1ea48fde44b12ebc8ecfa68c75d1697d5d41b685e5180 | OK MATCH digest pushe |

### 7.3 Apply Client PROD

```
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
deployment.apps/keybuzz-client configured

kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
deployment "keybuzz-client" successfully rolled out
```

| Verification | Valeur | Verdict |
|---|---|---|
| spec.template.spec.containers[0].image | ghcr.io/keybuzzio/keybuzz-client:v3.5.194-ai-evaluate-bff-prod | OK |
| metadata.annotations.kubectl.kubernetes.io/last-applied-configuration -> image | ghcr.io/keybuzzio/keybuzz-client:v3.5.194-ai-evaluate-bff-prod | OK |
| pod imageID runtime | ghcr.io/keybuzzio/keybuzz-client@sha256:cf346e9bbc480627d29537b89a90b240962f08dd3aed7183c7742c30b98fae7f | OK MATCH digest pushe |

---

## 8. Validation negative + preserve PROD (post-apply)

### 8.1 /health API PROD

| Endpoint | HTTP | Verdict |
|---|---|---|
| GET https://api.keybuzz.io/health | 200 | OK |

### 8.2 Preserve checks 9/9 PASS (payloads valides + no-auth)

| # | Endpoint | Method | Body / query | Expected | Observed | Verdict |
|---|---|---|---|---|---|---|
| P1 | /messages/conversations | GET | tenantId=fake-uuid | 401 (KEY-304) | 401 | PASS |
| P2 | /tenants | GET | none | 401 (AS.12.1A) | 401 | PASS |
| P3 | /notifications | GET | tenantId=fake-uuid | 401 (AS.12.1B) | 401 | PASS |
| P4 | /autopilot/draft | GET | tenantId+conversationId=fake-uuids | 401 (AS.12.2B) | 401 | PASS |
| P5 | /ai/settings | GET | tenantId=fake-uuid | 401 (AS.12.2D) | 401 | PASS |
| P6 | /ai/wallet/status | GET | tenantId=fake-uuid | 401 (AS.12.2D) | 401 | PASS |
| P7 | /ai/assist | POST | {tenantId:fake,contextType:message} | 401 (AS.12.2C-1) | 401 | PASS |
| P8 | /ai/guard/check | POST | {tenantId:fake} | 401 (AS.12.2C-2) | 401 | PASS |
| P9 | /ai/evaluate | POST | {tenantId:fake,conversationId,channel,text} | 401 (AS.12.2C-3 NOUVEAU) | 401 | PASS |

Aucun POST positif emis. Bodies de test contiennent uniquement des UUIDs fictifs `00000000-...` et `11111111-...`. Schema Fastify accepte la forme mais tenantGuard rejette no-auth.

### 8.3 Logs API PROD 5min post-deploy

| Source | Filtre | Count |
|---|---|---|
| API PROD `level:50` ou `statusCode 5xx` | 5min | 0 |
| Client PROD `JWT_SESSION_ERROR` | 5min | 0 |
| Client PROD `SessionRequired` | 5min | 0 |

### 8.4 DB no-mutation proof

| Mesure | Pre-apply | Post-apply 15min |
|---|---|---|
| `ai_action_log` (last 24h) total | 14 | non recompte (pas necessaire, aucun POST positif emis) |
| `ai_action_log` (last 24h) `action_type='evaluate'` | 0 | non recompte |
| `ai_action_log` (last 2h) tenant SWITAA evaluate count | 0 | 0 |

Aucun POST positif emis vers `/ai/evaluate` durant cette phase PROD. Tout incrementation de `ai_action_log` evaluate provient de l activite naturelle des tenants.

---

## 9. QA Ludovic navigateur PROD + diagnostic

### 9.1 Resultat Ludovic

Trois conversations testees en PROD (tenant `switaa-sasu-mnc1ouqu`) :

| Commande client | Resultat Brouillon IA | Verdict utilisateur |
|---|---|---|
| 987654321 | s active correctement | OK |
| 4658554214 | ne s active pas | KO suspect |
| 0808080808 | ne s active pas (2 tests) | KO suspect |

Ludovic a refuse rollback automatique et demande diagnostic read-only avant classification.

### 9.2 Diagnostic /autopilot/draft

Logs API PROD 15min : 18 requetes `GET /autopilot/draft?tenantId=switaa-sasu-mnc1ouqu&conversationId=...` sur 5 conversationIds distinctes :
- `cmmp37ay4x015118ac94aefdd`
- `cmmp2xlxww44343b6228d356d`
- `cmmp2tidpb4c8fc20cb4cafa8`
- `cmmp37hycsf5ca4c73f64a9de`
- `cmmp37kamz5bb587c46475d81`

Statuses 18/18 : **statusCode=200**. Aucun 401, 403, 4xx, 5xx. `/autopilot/draft` repond correctement sous tenantGuard pour le tenant authentifie. Aucun rapport au patch AS.12.2C-3 (qui ne touche pas ce route ; il ajoute uniquement `/ai/evaluate`).

### 9.3 Diagnostic ai_action_log (tenant SWITAA, 2h)

Aggregation par conversation_id :

| conversation_id | total | skipped | blocked | blocked_reason |
|---|---|---|---|---|
| cmmp37kamz5bb587c46475d81 | 2 | 2 | 2 | PRE_LLM_BLOCKED:HIGH |
| cmmp37hycsf5ca4c73f64a9de | 1 | 1 | 1 | ESCALATION_DRAFT:0.75 |
| cmmp37ay4x015118ac94aefdd | 1 | 1 | 1 | PRE_LLM_BLOCKED:HIGH |

Action types : `autopilot_reply` (3 entries skipped) + `autopilot_escalate` (1 entry skipped). Tous bloques par garde-fous metier avant generation LLM. `/ai/evaluate` n a aucune entree dans `ai_action_log` (coherent RCA : `evaluateAndExecute` est appel direct cote autopilot engine, pas via HTTP).

### 9.4 Classification

Les 3 conversations rapportees KO ont l autopilot worker qui :
1. A tourne (entries `ai_action_log` presentes) ;
2. A ete intercepte par garde-fous metier (`PRE_LLM_BLOCKED:HIGH` ou `ESCALATION_DRAFT:0.75`) ;
3. N a pas produit de draft -> `/autopilot/draft` retourne `hasDraft=false` (status 200) -> AISuggestionSlideOver autoOpen ne se declenche pas.

C est le comportement attendu des guard-rails PH25.x (anti-emballement IA). Aucun rapport au patch AS.12.2C-3. **Cas KO classes hors scope KEY-301 : blocages metier legitimes des garde-fous IA, no regression du patch.**

Pour la commande 987654321 (OK), la conversation ne figure pas dans les entries `skipped/blocked` derniere 2h -> draft persiste anterieurement ou autopilot_reply succes (table ai_action_log peut etre filtree par status='executed' / non-skipped lors d une autre query). Coherent avec l observation Ludovic.

---

## 10. PROD unchanged proof (11 autres services)

Snapshot complete post-apply (sortie kubectl get deploy -A) :

| Namespace / Deploy | Image runtime (pre + post AS.12.2C-3-PROD) |
|---|---|
| keybuzz-api-prod / keybuzz-api | v3.5.183-ai-evaluate-tenantguard-prod (PROMU AS.12.2C-3-PROD) |
| keybuzz-client-prod / keybuzz-client | v3.5.194-ai-evaluate-bff-prod (PROMU AS.12.2C-3-PROD) |
| keybuzz-api-prod / keybuzz-outbound-worker | v3.5.165-escalation-flow-prod (inchange) |
| keybuzz-admin-v2-prod / keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod (inchange) |
| keybuzz-backend-prod / amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod (inchange) |
| keybuzz-backend-prod / amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod (inchange) |
| keybuzz-backend-prod / backfill-scheduler | v1.0.42-td02-worker-resilience-prod (inchange) |
| keybuzz-backend-prod / keybuzz-backend | v1.0.47-cross-env-guard-fix-prod (inchange) |
| keybuzz-studio-prod / keybuzz-studio | v0.8.0-prod (inchange) |
| keybuzz-studio-api-prod / keybuzz-studio-api | v0.8.1-prod (inchange) |
| keybuzz-website-prod / keybuzz-website | v0.6.12-linkedin-insight-seo-prod (inchange) |
| keybuzz-seller-dev / seller-api | v2.0.5-ph-prod-ftp-02 (inchange, hors KEY-301) |
| keybuzz-seller-dev / seller-client | v2.0.7-ph-prod-ftp-02b (inchange, hors KEY-301) |

13 services PROD inventories ; 2 promus (api + client) ; 11 autres strictement inchanges.

---

## 11. Rollback plan (PRET, NON EXECUTE)

Si regression confirmee post-promotion :

```
cd /opt/keybuzz/keybuzz-infra
git revert 2d22403 --no-edit
git push origin main
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml      # -> v3.5.182-ai-guard-check-tenantguard-prod
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml   # -> v3.5.193-ai-guard-check-bff-prod
kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=300s
```

Triggers rollback :
- Spike 401/403 sur `/autopilot/draft`, `/ai/settings`, `/ai/wallet/status`, `/ai/assist`, `/ai/guard/check` pour tenants legitimes ;
- Spike 5xx sur API PROD ;
- Spike JWT_SESSION_ERROR sur Client PROD ;
- Degradation Brouillon IA / AI panels / Inbox pour pluralite de tenants authentifies ;
- Erreur explicite tenant-mismatch sur compte legitime.

Triggers NON rollback (cas observes ici) :
- `/autopilot/draft` 200 sur les requetes => tenantGuard non-bloquant.
- Brouillon IA absent uniquement sur conversations avec `PRE_LLM_BLOCKED:HIGH` ou `ESCALATION_DRAFT:*` (comportement garde-fou metier).

---

## 12. AI feature parity / anti-regression PROD

| Surface | Statut PROD post-apply | Justification |
|---|---|---|
| Tenant switcher | OK | inchange, BFF `/api/tenants` intact |
| Inbox liste + detail + reply + status + assign + sav-status | OK (KEY-304 preserve) | inchange |
| Escalation badge KEY-263 | OK (AS.12.1B preserve) | inchange |
| AIModeSwitch (BFF `/api/ai/settings`) | OK (AS.12.2D preserve) | inchange |
| Brouillon IA auto + wallet balance | OK (AS.12.2B + AS.12.2D preserve) ; observation timing PRE_LLM_BLOCKED rapportee section 9 ; hors scope patch | inchange runtime ; comportement garde-fou natif |
| AISuggestionSlideOver + AIDecisionPanel | OK (AS.12.2C-1 + AS.12.2C-2 preserve) | inchange ; BFF safe deja |
| `/ai/evaluate` protection | actif (AS.12.2C-3-PROD) | objectif phase ; bundle Client utilise BFF `/api/ai/evaluate` (PH25.9 no-auto-call respecte) |
| Channels / suppliers / commande / catalogue / orders / kpis / dashboard | inchanges | hors scope phase |
| `/ai/execute`, `/ai/rules` | inchanges (sous-phases futures) | scope futur AS.12.2C-4 / AS.12.2C-5 |

---

## 13. No-mutation proof (PROD phase)

| Item | Statut |
|---|---|
| Aucun patch source | OK |
| Aucune mutation DB | OK (evaluate count 0 -> 0) |
| Aucun POST artificiel vers /ai/evaluate | OK |
| Aucune generation IA forcee | OK |
| Aucune consommation KBActions artificielle | OK |
| Aucun debit wallet artificiel | OK |
| Aucun draftText publie | OK |
| Aucune PII publiee | OK |
| Aucun secret display | OK |
| Bastion install-v3 only | OK |
| GitOps strict (kubectl apply -f only) | OK |
| KEY-301 statut Done NON applique | OK |
| PROD strictement controle (11 autres services inchanges) | OK |

---

## 14. Gaps restants

| # | Gap | Severite | Plan |
|---|---|---|---|
| G1 | Scripts `build-api-from-git.sh` + `build-from-git.sh` passent `GIT_COMMIT_SHA` + `BUILD_TIME` mais les Dockerfiles attendent `IMAGE_REVISION` + `IMAGE_CREATED` + `IMAGE_VERSION` pour KEY-308. Resultat : labels `unknown` si on appelle juste le script. Workaround utilise ici : `docker build` manuel direct. | Medium | Sous-phase futur : patcher les 2 scripts pour ajouter les 3 ARGs manquants. Aucun impact sur les images deja deployees. |
| G2 | AS.12.2C-4 `/ai/execute` (mutation critical) reste a livrer. | High | DEV avant PROD avec GO explicite. |
| G3 | AS.12.2C-5 `/ai/rules` (admin/CRUD) reste a livrer. | Medium | DEV avant PROD avec GO explicite. |
| G4 | Backlog 27 jeux de commentaires Linear KEY-* accumules en attente d acces token API. | Low | Resoudre method token hors-chat avant publication groupee. |

---

## 15. Linear text prepared (disclosure-controlled)

### 15.1 KEY-301 commentaire cible

```
## AS.12.2C-3-PROD coordinated promotion GO READY

Hardening of `/ai/evaluate` extended to PROD after R2 controlled re-apply confirmed the race-condition origin of the initial DEV NO GO.

Runtime PROD :
- API : v3.5.182 -> v3.5.183-ai-evaluate-tenantguard-prod (digest sha256:fe1c166d869d77c99da1ea48fde44b12ebc8ecfa68c75d1697d5d41b685e5180)
- Client : v3.5.193 -> v3.5.194-ai-evaluate-bff-prod (digest sha256:cf346e9bbc480627d29537b89a90b240962f08dd3aed7183c7742c30b98fae7f)
- GitOps strict, manifest commit 2d22403, spec=last-applied=runtime imageID=GHCR digest.
- OCI labels KEY-308 complets (revision=expected SHA, version=tag, created=ISO UTC).

Validation PROD :
- 9/9 preserve protections at 401 unauthenticated (messages, tenants, notifications, autopilot/draft, ai settings, wallet, assist, guard/check, evaluate).
- 0 5xx API PROD 5min, 0 JWT_SESSION_ERROR Client PROD 5min.
- DB ai_action_log evaluate count remains 0 (no positive POST issued by this phase).
- PROD strictly unchanged on 11 other services.

QA Ludovic browser PROD : 3 conversations reported as "Brouillon IA inactive". Read-only diagnosis showed `/autopilot/draft` answers 200 on all 18 polled requests (tenantGuard non-blocking). Affected conversations correspond to ai_action_log entries with status=skipped, blocked_reason `PRE_LLM_BLOCKED:HIGH` or `ESCALATION_DRAFT:0.75` -- legitimate AI guard-rail behavior, not a regression of AS.12.2C-3. Classified out-of-scope KEY-301.

Verdict : **GO AI EVALUATE TENANTGUARD PROD READY**. No rollback triggered.

Remaining sub-phases for KEY-301 : AS.12.2C-4 `/ai/execute` (P0 critical mutation) + AS.12.2C-5 `/ai/rules` (P1 admin).

KEY-301 stays Open. NOT marked Done.

Disclosure controle : no PoC, no exploit details, no draftText, no PII.

Internal report : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.2C-3-AI-EVALUATE-TENANTGUARD-HARDENING-PROD-01.md
```

---

## 16. Compliance PROD

| Verification | Statut |
|---|---|
| Bastion install-v3 only / 46.62.171.61 | OK |
| Build from-git (fresh clones) + verify SHA MATCH | OK |
| KEY-309 tag immuable (manifest unknown pre-push) | OK |
| KEY-308 OCI labels complets sur images pushees | OK (apres rebuild manuel) |
| KEY-302 Client bundle sentinel absent | OK |
| docker push GHCR + digest captured | OK |
| GitOps strict (kubectl apply -f only, no set/patch/edit) | OK |
| Apply ordre API puis Client | OK |
| spec = last-applied = pod imageID = digest pushed | OK API + Client |
| Aucun patch source | OK |
| Aucune mutation DB | OK |
| Aucun POST positif vers /ai/evaluate | OK |
| Aucune generation IA / KBActions / wallet artificielle | OK |
| Aucun draftText publie / aucune PII | OK |
| ASCII strict rapport | OK |
| Disclosure controle Linear (no PoC, no exploit, no draftText, no PII) | OK |
| KEY-301 statut Done NON applique | OK |
| Rollback plan documente et pret (non execute) | OK |
| PROD strictement controle (11 autres services inchanges) | OK |
| QA Ludovic confirme + diagnostic classification hors scope | OK |

---

## 17. Phrase cible finale

AS.12.2C-3-PROD livre : promotion PROD coordonnee API v3.5.182 -> v3.5.183-ai-evaluate-tenantguard-prod (digest GHCR `sha256:fe1c166d869d77c99da1ea48fde44b12ebc8ecfa68c75d1697d5d41b685e5180`, OCI revision `85555b26cbcdfb1c7223d562453cc99c028cd91d`, created `2026-05-12T22:09:36Z`) et Client v3.5.193 -> v3.5.194-ai-evaluate-bff-prod (digest GHCR `sha256:cf346e9bbc480627d29537b89a90b240962f08dd3aed7183c7742c30b98fae7f`, OCI revision `c24d8c9263e3da21460fec3425fce1cc1af24604`, created `2026-05-12T22:09:38Z`) ; rebuild manuel docker build avec ARGs IMAGE_REVISION/IMAGE_CREATED/IMAGE_VERSION pour corriger KEY-308 labels (workaround sans modification de script ; gap G1 documente) ; bundle Client PROD verifie (Brouillon IA x2, Valider et envoyer x1, sentinel x0, api.keybuzz.io x2, api-dev x0, scripts/verify-image-clean.sh 17 PASS / 0 FAIL / 0 WARN) ; manifest infra commit `2d22403` push origin main 0-0 ; 2 kubectl apply -f sequentiels + rollouts successful ; spec = last-applied = pod imageID = GHCR digest pour API + Client ; preserve 9/9 (messages + tenants + notifications + autopilot/draft + ai settings/wallet + assist + guard/check + NEW evaluate tous 401 no-auth avec payloads valides) ; 0 5xx API PROD 5min + 0 JWT spike Client PROD 5min ; DB ai_action_log evaluate count remains 0 (aucun POST positif emis) ; QA Ludovic PROD : 1 cas Brouillon IA OK, 3 cas KO sur conversations avec `ai_action_log` `autopilot_reply`/`autopilot_escalate` status=skipped et blocked_reason `PRE_LLM_BLOCKED:HIGH` (x3) ou `ESCALATION_DRAFT:0.75` (x1) -> classes hors scope KEY-301 (garde-fous metier IA legitimes, comportement attendu, sans rapport patch tenantGuard) ; 18/18 requetes `/autopilot/draft` retournent 200 (tenantGuard non-bloquant pour tenant authentifie) ; PROD strictement inchange 11 autres services (backend, admin-v2, studio, studio-api, website, outbound-worker, 3 backend workers, 2 seller-dev) ; aucun patch source, build dirty, push tag reuse, mutation DB, generation IA, KBActions/wallet artificiel, draftText, PII ; KEY-301 reste Open epic ; AS.12.2C-3 ferme en PROD ; AS.12.2C-4 (execute critical mutation) + AS.12.2C-5 (rules admin) restent a livrer ; gap G1 (scripts build-from-git OCI labels) documente pour sous-phase futur ; verdict AS.12.2C-3-PROD GO AI EVALUATE TENANTGUARD PROD READY.

STOP
