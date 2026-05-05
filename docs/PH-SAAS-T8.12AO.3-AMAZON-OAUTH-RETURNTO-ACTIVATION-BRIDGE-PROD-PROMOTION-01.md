# PH-SAAS-T8.12AO.3 — Amazon OAuth ReturnTo & Activation Bridge PROD Promotion

> Phase : PH-SAAS-T8.12AO.3-AMAZON-OAUTH-RETURNTO-ACTIVATION-BRIDGE-PROD-PROMOTION-01
> Date : 2026-05-05
> Environnement : PROD
> Type : promotion PROD Backend ciblee + validation structurelle
> Priorite : P0
> Ticket : KEY-248
> Phase precedente : PH-SAAS-T8.12AO.2 (DEV fix, verdict GO DEV FIX READY)
> Verdict : **GO PARTIEL — USER OAUTH VALIDATION PENDING**

---

## Phrase cible

AMAZON OAUTH RETURNTO AND ACTIVATION BRIDGE DEPLOYED IN PROD — UI ROUTES REDIRECT TO CLIENT HOST — BACKEND NEVER SERVES /START — CLIENT_APP_URL SET — 8/8 STRUCTURAL REDIRECT TESTS PASS — OPEN REDIRECT BLOCKED — PROTOCOL RELATIVE BLOCKED — NO CONNECTOR RESURRECTION — GITOPS STRICT — ECOMLG PRESERVED — AWAITING USER E2E OAUTH TEST

---

## 1. Preflight

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend (bastion) | main | `ba494f2` (AO.2) | `.bak` only | OK |
| keybuzz-infra | main | `466bc69` (AO.2 rapport) | unrelated docs | OK |
| keybuzz-api | ph147.4/source-of-truth | non modifie | - | Non touche |
| keybuzz-client | ph148/onboarding-activation-replay | non modifie | - | Non touche |

### Runtimes avant intervention

| Service | Image PROD avant | Verdict |
|---|---|---|
| Backend | `v1.0.44-amazon-oauth-env-guard-prod` | A promouvoir |
| API | `v3.5.142-promo-retry-email-prod` | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | Non touche |
| Backend DEV | `v1.0.45-amazon-oauth-returnto-guard-dev` | Fix AO.2 valide |

### Health avant

| Service | Health | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | OK (uptime 4605s) | 0 | OK |
| API PROD | OK | 0 | OK |
| Backend DEV | OK (uptime 1291s) | 0 | OK |

### Env vars Backend PROD avant

| Variable | Valeur | Verdict |
|---|---|---|
| CLIENT_APP_URL | NOT SET | **A ajouter** |
| AMAZON_SPAPI_REDIRECT_URI | `https://backend.keybuzz.io/.../callback` | OK (AO.1 fix) |
| NODE_ENV | production | OK |

---

## 2. Verification source AO.2

Source commit `ba494f2` verifie sur le bastion :

| Brique | Presente | Verdict |
|---|---|---|
| `buildSafeRedirectUrl()` | Oui (L24-67) | **PASS** |
| Normalisation path relatif via `CLIENT_APP_URL` | Oui (L28, L45-46) | **PASS** |
| Allowlist hosts | Oui (L37: `client.keybuzz.io`, `client-dev.keybuzz.io`) | **PASS** |
| Protection open redirect (host check) | Oui (L50) | **PASS** |
| Protection `//evil.com` (protocol-relative) | Oui (L44) | **PASS** |
| Protection `javascript:` (try/catch fallback) | Oui (L56-58) | **PASS** |
| Ajout propre params (URL API) | Oui (L63-64, `searchParams.set`) | **PASS** |
| State preserve | Oui (L418, `oauthState.returnTo`) | **PASS** |
| `expected_channel` preserve | Oui (L389-390) | **PASS** |
| Aucun hardcode tenant/country | Clean | **PASS** |

---

## 3. Build Backend PROD

| Element | Valeur |
|---|---|
| Service | Backend |
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-amazon-oauth-returnto-guard-prod` |
| Digest | `sha256:e3b2070a95e7ae437cfbfe172354924fc772fd1fa498acdfd831a232ab1b45f5` |
| Source commit | `ba494f2` |
| Source branche | main |
| Methode | Clone propre `/tmp/ao3-build`, `--no-cache`, detached HEAD |
| Build-from-git | Oui |
| Rollback | `v1.0.44-amazon-oauth-env-guard-prod` |

---

## 4. GitOps PROD

| Manifest | Image/env avant | Image/env apres | Commit infra |
|---|---|---|---|
| `k8s/keybuzz-backend-prod/deployment.yaml` | `v1.0.44-amazon-oauth-env-guard-prod` | `v1.0.45-amazon-oauth-returnto-guard-prod` | `06cef80` |
| `k8s/keybuzz-backend-prod/deployment.yaml` | CLIENT_APP_URL: NOT SET | `CLIENT_APP_URL=https://client.keybuzz.io` | `06cef80` |

### Procedure executee

1. Modifier manifest local (image + CLIENT_APP_URL)
2. Verifier diff (3 insertions, 1 deletion)
3. `git commit` + `git push origin main`
4. `git pull` sur bastion
5. `kubectl apply -f k8s/keybuzz-backend-prod/deployment.yaml`
6. `kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod` — succes
7. Verification runtime = manifest

### Rollback

```yaml
# k8s/keybuzz-backend-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-prod
# Supprimer CLIENT_APP_URL
```
Puis `kubectl apply -f` + `kubectl rollout status`.

---

## 5. Validation structurelle PROD

| Check | Resultat | Verdict |
|---|---|---|
| Backend PROD health | OK (uptime 82s, 0 restarts) | **PASS** |
| API PROD health | OK | **PASS** |
| `CLIENT_APP_URL` | `https://client.keybuzz.io` | **PASS** |
| `AMAZON_SPAPI_REDIRECT_URI` | `https://backend.keybuzz.io/.../callback` | **PASS** |
| `NODE_ENV` | production | **PASS** |
| `backend-dev` dans env | absent | **PASS** |
| `client-dev` dans env | absent | **PASS** |
| Restarts | 0 | **PASS** |
| Logs | Clean (health checks only, no errors) | **PASS** |

### Tests redirect (simulation dans env PROD)

| Cas | Resultat | Verdict |
|---|---|---|
| `/start` relatif | `https://client.keybuzz.io/start?amazon_connected=true&tenant_id=test` | **PASS** |
| `/channels` relatif | `https://client.keybuzz.io/channels?amazon_connected=true&tenant_id=test` | **PASS** |
| Absolu `/channels` avec params | `https://client.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-fr&tenant_id=test` | **PASS** |
| `null` returnTo | `https://client.keybuzz.io/channels?amazon_error=test` | **PASS** |
| Open redirect `evil.com` | Bloque → `client.keybuzz.io/channels` | **PASS** |
| Protocol-relative `//evil.com` | Bloque → `client.keybuzz.io/channels` | **PASS** |
| Backend host `backend.keybuzz.io/start` | Bloque → `client.keybuzz.io/channels` | **PASS** |
| DEV host `client-dev.keybuzz.io/start` | Autorise (allowlist) | **PASS** |

**8/8 tests passent en environnement PROD.**

---

## 6. Test utilisateur OAuth PROD

### Test /start

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| Client PROD /start → Connecter Amazon | URL OAuth Amazon generee | **EN ATTENTE** | PENDING |
| Callback host | `backend.keybuzz.io` | **EN ATTENTE** | PENDING |
| Retour final | `client.keybuzz.io/start?...` | **EN ATTENTE** | PENDING |
| No backend /start 404 | Pas de 404 | **EN ATTENTE** | PENDING |
| No invalid_state | State retrouve | **EN ATTENTE** | PENDING |

### Test /channels

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| Client PROD /channels → Connecter Amazon | URL OAuth Amazon generee | **EN ATTENTE** | PENDING |
| expected_channel preserve | amazon-xx dans URL | **EN ATTENTE** | PENDING |
| Callback host | `backend.keybuzz.io` | **EN ATTENTE** | PENDING |
| Retour final | `client.keybuzz.io/channels?...` | **EN ATTENTE** | PENDING |
| Activation API reussie | inbound_email visible | **EN ATTENTE** | PENDING |
| Status Connecte | channel active | **EN ATTENTE** | PENDING |

**Note** : La validation structurelle prouve que les redirects fonctionneront correctement. Le test utilisateur est recommande pour confirmer le flux E2E complet incluant Amazon Seller Central.

---

## 7. Non-regression

### PROD services

| Service | Image | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | `v1.0.45-amazon-oauth-returnto-guard-prod` | 0 | **PROMU** |
| API PROD | `v3.5.142-promo-retry-email-prod` | 0 | **INCHANGE** |
| Client PROD | `v3.5.153-promo-visible-price-prod` | 0 | **INCHANGE** |
| Website PROD | `v0.6.9-promo-forwarding-prod` (2 replicas) | 0 | **INCHANGE** |
| OW PROD | `v3.5.165-escalation-flow-prod` | 7 (preexistants) | **INCHANGE** |

### eComLG PROD

| Element | Valeur | Verdict |
|---|---|---|
| Amazon connection | READY | **INCHANGE** |
| Countries | FR, BE, ES, IT, PL | **INCHANGE** |
| Marketplace | amazon | **INCHANGE** |

### Billing PROD

| Element | Valeur | Verdict |
|---|---|---|
| Subscriptions | 7 | **INCHANGE** |

### CronJobs PROD

| Job | Status | Verdict |
|---|---|---|
| outbound-tick-processor | Active (last: 18:22) | **PASS** |
| sla-evaluator | Active (last: 18:22) | **PASS** |
| trial-lifecycle-dryrun | Active (last: 08:00) | **PASS** |
| carrier-tracking-poll | Active | **PASS** |
| amazon-orders-sync | Active (last: 18:20) | **PASS** |
| amazon-reports-tracking-sync | Active (last: 18:00) | **PASS** |

### DEV

| Service | Image | Health | Verdict |
|---|---|---|---|
| Backend DEV | `v1.0.45-amazon-oauth-returnto-guard-dev` | OK | **INCHANGE** |

---

## 8. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend | `ba494f2` | PH-SAAS-T8.12AO.2: safe returnTo redirect — normalize relative paths, prevent open redirect, fix double query params |
| keybuzz-infra | `06cef80` | gitops(prod): AO.3 Backend v1.0.45-amazon-oauth-returnto-guard-prod + CLIENT_APP_URL env var |
| keybuzz-infra | (ce rapport) | docs: PH-SAAS-T8.12AO.3 rapport final |

---

## 9. Images Docker

### PROD (apres)

| Service | Tag | Digest | Change |
|---|---|---|---|
| Backend | `v1.0.45-amazon-oauth-returnto-guard-prod` | `sha256:e3b2070a...` | **PROMU** |
| API | `v3.5.142-promo-retry-email-prod` | (inchange) | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | (inchange) | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | (inchange) | Non touche |
| OW | `v3.5.165-escalation-flow-prod` | (inchange) | Non touche |

### DEV (inchange)

| Service | Tag |
|---|---|
| Backend | `v1.0.45-amazon-oauth-returnto-guard-dev` |

---

## 10. Gaps restants

### 10.1 Test utilisateur OAuth PROD non effectue

La validation structurelle est exhaustive (8/8 tests). Le test utilisateur reel Amazon OAuth est recommande pour confirmer le flux E2E complet incluant la validation Amazon Seller Central.

### 10.2 Vault redirect_uri toujours DEV

Le secret Vault `secret/data/keybuzz/amazon_spapi/app` contient toujours `redirect_uri: backend-dev.keybuzz.io`. Le fix env var override (AO.1) rend ceci inoffensif.

### 10.3 OW PROD 7 restarts preexistants

Le outbound worker PROD a 7 restarts preexistants (non lie a cette phase).

### 10.4 Vault DOWN

Vault est toujours DOWN depuis janvier 2026. Les services utilisent les secrets K8s caches.

---

## 11. Rollback

### Backend PROD

```yaml
# k8s/keybuzz-backend-prod/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-prod
# Supprimer la ligne CLIENT_APP_URL
```

Puis :
1. `git commit` + `git push`
2. `git pull` sur bastion
3. `kubectl apply -f k8s/keybuzz-backend-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod`

---

## 12. Linear

KEY-248 mis a jour avec la promotion PROD. **Ne pas fermer** avant test utilisateur OAuth E2E.

---

## 13. Chronologie Amazon OAuth complete

| Phase | Description | Backend | Verdict |
|---|---|---|---|
| AM.3 | Delete marketplace connector | v1.0.38 | DONE |
| AM.6 | Callback reads expected_channel from returnTo | v1.0.39 | DONE |
| AM.7 | ensureInboundConnection creates with READY | v1.0.40 | DONE |
| AM.9 | Dual DB fix — GET inbound-connection route for BFF bridge | v1.0.41 | DONE |
| AM.10 | PROD promotion AM.9 | v1.0.42 | DONE |
| AO | DEV fix — env var overrides Vault redirect_uri + cross-env guard | v1.0.44 | DONE |
| AO.1 | PROD promotion AO — Backend + LEGACY_BACKEND_URL fix | v1.0.44 | DONE |
| **AO.2** | **DEV fix — safe returnTo redirect + CLIENT_APP_URL + open redirect guard** | **v1.0.45** | **DONE** |
| **AO.3** | **PROD promotion AO.2** | **v1.0.45** | **DEPLOYED, VALIDATION PENDING** |

---

## VERDICT

**GO PARTIEL — USER OAUTH VALIDATION PENDING**

AMAZON OAUTH RETURNTO AND ACTIVATION BRIDGE DEPLOYED IN PROD — `buildSafeRedirectUrl()` ACTIVE — `CLIENT_APP_URL=https://client.keybuzz.io` SET — UI ROUTES REDIRECT TO CLIENT HOST (`client.keybuzz.io`) — BACKEND NEVER SERVES `/START` — RELATIVE PATHS NORMALIZED — NO DOUBLE QUERY PARAMS — `expected_channel` PRESERVED — OPEN REDIRECT BLOCKED (8/8 STRUCTURAL TESTS PASS) — PROTOCOL-RELATIVE BLOCKED — NO CONNECTOR RESURRECTION — ECOMLG PRESERVED (READY, 5 COUNTRIES) — BILLING UNCHANGED (7 SUBS) — ALL CRONJOBS ACTIVE — API/CLIENT/WEBSITE/OW UNCHANGED — GITOPS STRICT — AWAITING USER E2E OAUTH TEST TO CLOSE KEY-248
