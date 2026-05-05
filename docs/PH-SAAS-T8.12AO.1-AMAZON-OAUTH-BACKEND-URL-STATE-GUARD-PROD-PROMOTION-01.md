# PH-SAAS-T8.12AO.1 — Amazon OAuth Backend URL State Guard PROD Promotion

> Phase : PH-SAAS-T8.12AO.1-AMAZON-OAUTH-BACKEND-URL-STATE-GUARD-PROD-PROMOTION-01
> Date : 2026-05-05
> Environnement : PROD
> Type : promotion PROD Backend + correction config API
> Priorite : P0
> Ticket : KEY-248
> Phase precedente : PH-SAAS-T8.12AO (DEV fix, verdict GO DEV FIX READY)
> Verdict : **GO PARTIEL — USER OAUTH VALIDATION PENDING**

---

## Phrase cible

AMAZON OAUTH BACKEND URL AND STATE GUARD LIVE IN PROD — ENV OVERRIDES VAULT — PROD CALLBACK USES BACKEND PROD — LEGACY_BACKEND_URL CORRECTED — STATE CREATED AND CONSUMED IN SAME ENVIRONMENT — EXPECTED_CHANNEL PRESERVED — INBOUND EMAIL VISIBLE — NO CONNECTOR RESURRECTION — GITOPS STRICT — KEY-248 READY TO CLOSE AFTER USER TEST

---

## 1. Preflight

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend (bastion) | main | `97656c6` (AO fix) | 0 | OK |
| keybuzz-infra | main | `c0a037c` (AO rapport) | untracked docs | OK |
| keybuzz-api | ph147.4/source-of-truth | non modifie | - | Non touche |
| keybuzz-client | ph148/onboarding-activation-replay | non modifie | - | Non touche |

### Runtimes avant intervention

| Service | Image PROD avant | Verdict |
|---|---|---|
| Backend | `v1.0.42-amazon-oauth-inbound-bridge-prod` | A promouvoir |
| API | `v3.5.142-promo-retry-email-prod` | Env var a corriger |
| Client | `v3.5.153-promo-visible-price-prod` | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | Non touche |
| Backend DEV | `v1.0.44-amazon-oauth-env-guard-dev` | Fix AO valide |

### Health avant

| Service | Health | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | OK | 0 | OK |
| API PROD | OK | 0 | OK |

---

## 2. Config PROD avant intervention

| Surface | Variable | Valeur observee | Verdict |
|---|---|---|---|
| Backend PROD | `AMAZON_SPAPI_REDIRECT_URI` | `https://backend.keybuzz.io/.../callback` | Correcte |
| Backend PROD | `NODE_ENV` | production | Correcte |
| Backend PROD | `VAULT_ADDR` | SET | Present |
| Backend PROD | image | `v1.0.42-amazon-oauth-inbound-bridge-prod` | A promouvoir |
| API PROD | `LEGACY_BACKEND_URL` | `http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000` | **BUG** |
| API PROD | image | `v3.5.142-promo-retry-email-prod` | Inchangee |
| Client PROD bundle | `backend-dev.keybuzz.io` | Absent (0 occurrences) | OK |

### Vault truth (inchangee depuis AO)

Le secret Vault `secret/data/keybuzz/amazon_spapi/app` contient toujours `redirect_uri: backend-dev.keybuzz.io`. Le fix env var override rend cette valeur inoffensive.

---

## 3. Build Backend PROD

| Element | Valeur |
|---|---|
| Service | Backend |
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-prod` |
| Digest | `sha256:0c9c259f5b6c5295e20af09559a84254b6e5bbfbe23f1b6596245dd1f1a443f9` |
| Source commit | `97656c6` |
| Source branche | main |
| Methode | Clone propre, `--no-cache`, detached HEAD |
| Build-from-git | Oui |
| Rollback | `v1.0.42-amazon-oauth-inbound-bridge-prod` |

---

## 4. Correction API PROD config

| Variable | Avant | Apres | Methode |
|---|---|---|---|
| `LEGACY_BACKEND_URL` | `http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000` | `http://keybuzz-backend.keybuzz-backend-prod.svc.cluster.local:4000` | Manifest GitOps |

Aucun rebuild API necessaire — changement env var uniquement dans le manifest K8s.

---

## 5. GitOps PROD

| Manifest | Image/env avant | Image/env apres | Commit infra |
|---|---|---|---|
| `k8s/keybuzz-backend-prod/deployment.yaml` | `v1.0.42-amazon-oauth-inbound-bridge-prod` | `v1.0.44-amazon-oauth-env-guard-prod` | `30d5056` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `LEGACY_BACKEND_URL: ...backend-dev...` | `LEGACY_BACKEND_URL: ...backend-prod...` | `30d5056` |

### Procedure executee

1. Modifier manifests locaux
2. Verifier diff (2 lignes changees)
3. `git commit` + `git push origin main`
4. `git pull` sur bastion
5. `kubectl apply -f` Backend PROD manifest
6. `kubectl apply -f` API PROD manifest
7. `kubectl rollout status` Backend PROD — succes
8. `kubectl rollout status` API PROD — succes
9. Verification runtime = manifest

### Rollback

Backend :
```yaml
# k8s/keybuzz-backend-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.42-amazon-oauth-inbound-bridge-prod
```

API :
```yaml
# k8s/keybuzz-api-prod/deployment.yaml
- name: LEGACY_BACKEND_URL
  value: "http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000"
```

Puis `kubectl apply -f` + `kubectl rollout status`.

---

## 6. Validation structurelle PROD

| Check | Resultat | Verdict |
|---|---|---|
| Backend PROD health | `{"status":"ok","uptime":101s}` | **PASS** |
| API PROD health | `{"status":"ok"}` | **PASS** |
| Backend PROD image runtime | `v1.0.44-amazon-oauth-env-guard-prod` | **PASS** |
| API PROD image runtime | `v3.5.142-promo-retry-email-prod` (inchangee) | **PASS** |
| `getAmazonAppCredentials()` redirect_uri | `https://backend.keybuzz.io/.../callback` | **PASS** |
| Vault loaded + env var override | `[Amazon Vault] Successfully loaded` + env var prioritaire | **PASS** |
| Cross-env guard (DEV URL simule) | BLOCKED | **PASS** |
| `backend-dev` dans Backend PROD env | absent | **PASS** |
| `backend-dev` dans API PROD env | absent | **PASS** |
| `LEGACY_BACKEND_URL` API PROD | `...keybuzz-backend-prod...` | **PASS** |
| Backend PROD restarts | 0 | **PASS** |
| API PROD restarts | 0 | **PASS** |
| Backend PROD logs | clean (health checks uniquement) | **PASS** |

---

## 7. Validation OAuth PROD controlee

### Simulation structurelle

| Etape OAuth | Attendu | Resultat | Verdict |
|---|---|---|---|
| `getAmazonAppCredentials()` LIVE | `redirect_uri: backend.keybuzz.io` | `backend.keybuzz.io` | **PASS** |
| `login_uri` | `sellercentral-europe.amazon.com` | `sellercentral-europe.amazon.com` | **PASS** |
| `region` | `eu-west-1` | `eu-west-1` | **PASS** |
| `client_id` present | true | true | **PASS** |
| `client_secret` present | true | true | **PASS** |
| Cross-env guard PROD | ACTIVE | ACTIVE | **PASS** |
| Simulated callback host | `backend.keybuzz.io` | `backend.keybuzz.io` | **PASS** |
| Match expected | true | true | **PASS** |

### Test utilisateur reel

Non effectue — requiert interaction Amazon Seller Central.

Recommandation : Ludovic teste en PROD via client.keybuzz.io > Canaux > Connecter Amazon. Verifier que le callback arrive sur `backend.keybuzz.io` et que le state est retrouve.

---

## 8. Non-regression

| Surface | Resultat | Verdict |
|---|---|---|
| Backend PROD health | OK, 0 restarts | **PASS** |
| API PROD health | OK, 0 restarts | **PASS** |
| Client PROD | Running, 0 restarts | **PASS** |
| Website PROD | Running (2 replicas), 0 restarts | **PASS** |
| OW PROD | Running (7 restarts preexistants, non lie) | **PASS** |
| eComLG channels PROD | 1 amazon (FR,ES,IT) READY | **PASS** |
| Backend PROD image | `v1.0.44-amazon-oauth-env-guard-prod` | **PASS** |
| API PROD image | `v3.5.142-promo-retry-email-prod` (inchangee) | **PASS** |
| Client PROD image | `v3.5.153-promo-visible-price-prod` (inchangee) | **PASS** |
| Website PROD image | `v0.6.9-promo-forwarding-prod` (inchangee) | **PASS** |
| Billing subscriptions PROD | 7 (inchange) | **PASS** |
| CronJobs PROD | running (outbound-tick, sla-evaluator, orders-sync, tracking-sync, lifecycle-dryrun) | **PASS** |
| DEV Backend health | OK | **PASS** |
| DEV Backend redirect_uri | `backend-dev.keybuzz.io` (correct) | **PASS** |

---

## 9. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend | `97656c6` | PH-SAAS-T8.12AO: env var overrides Vault redirect_uri + cross-env guard + Vault fallback |
| keybuzz-infra | `30d5056` | gitops(prod): AO.1 Backend v1.0.44-amazon-oauth-env-guard-prod + fix LEGACY_BACKEND_URL |
| keybuzz-infra | (ce rapport) | PH-SAAS-T8.12AO.1: rapport final |

---

## 10. Images Docker

### PROD (apres)

| Service | Tag | Digest | Change |
|---|---|---|---|
| Backend | `v1.0.44-amazon-oauth-env-guard-prod` | `sha256:0c9c259f5b6c...` | **PROMU** |
| API | `v3.5.142-promo-retry-email-prod` | (inchange) | Env var `LEGACY_BACKEND_URL` fixe |
| Client | `v3.5.153-promo-visible-price-prod` | (inchange) | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | (inchange) | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | (inchange) | Non touche |

### DEV (inchange)

| Service | Tag |
|---|---|
| Backend | `v1.0.44-amazon-oauth-env-guard-dev` |

---

## 11. Gaps restants

### 11.1 Vault redirect_uri toujours DEV

Le secret `secret/data/keybuzz/amazon_spapi/app` contient toujours `redirect_uri: backend-dev.keybuzz.io`. Le fix env var override rend ceci inoffensif, mais idealement les paths Vault devraient etre per-environment.

### 11.2 Test OAuth reel utilisateur non effectue

La validation structurelle est complete et exhaustive. Un test reel Amazon OAuth PROD est recommande pour confirmer le flux de bout en bout.

### 11.3 OW PROD 7 restarts

Le outbound worker PROD a 7 restarts preexistants (non lie a cette phase). A surveiller.

---

## 12. Linear

KEY-248 : commentaire de mise a jour fourni. Ne pas fermer avant test utilisateur reel.

---

## VERDICT

**GO PARTIEL — USER OAUTH VALIDATION PENDING**

AMAZON OAUTH BACKEND URL AND STATE GUARD LIVE IN PROD — ENV OVERRIDES VAULT — PROD CALLBACK USES BACKEND PROD (`backend.keybuzz.io`) — LEGACY_BACKEND_URL CORRECTED (`keybuzz-backend-prod`) — CROSS-ENV GUARD ACTIVE — STATE WILL BE CREATED AND CONSUMED IN SAME ENVIRONMENT — EXPECTED_CHANNEL PRESERVED — INBOUND EMAIL VISIBLE — NO CONNECTOR RESURRECTION — GITOPS STRICT — eComLG PRESERVED — BILLING UNCHANGED — ALL SERVICES HEALTHY — AWAITING USER OAUTH E2E TEST — KEY-248 READY TO CLOSE AFTER USER VALIDATION
