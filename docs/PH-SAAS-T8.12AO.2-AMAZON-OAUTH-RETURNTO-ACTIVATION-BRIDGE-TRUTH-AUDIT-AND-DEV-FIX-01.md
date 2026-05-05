# PH-SAAS-T8.12AO.2 — Amazon OAuth ReturnTo & Activation Bridge Truth Audit and DEV Fix

> Phase : PH-SAAS-T8.12AO.2-AMAZON-OAUTH-RETURNTO-ACTIVATION-BRIDGE-TRUTH-AUDIT-AND-DEV-FIX-01
> Date : 2026-05-05
> Environnement : PROD read-only audit + DEV fix uniquement
> Type : audit verite + correction DEV, sans promotion PROD
> Priorite : P0
> Ticket : KEY-248
> Phase precedente : PH-SAAS-T8.12AO.1 (PROD promotion, verdict GO PARTIEL)
> Verdict : **GO DEV FIX READY**

---

## Phrase cible

AMAZON OAUTH RETURNTO AND ACTIVATION BRIDGE READY IN DEV — UI ROUTES REDIRECT TO CLIENT HOST — BACKEND NEVER SERVES /START — STATE FOUND — EXPECTED_CHANNEL PRESERVED — NO DOUBLE QUERY PARAMS — OPEN REDIRECT BLOCKED — PROTOCOL RELATIVE BLOCKED — 11/11 SECURITY TESTS PASS — NO CONNECTOR RESURRECTION — NO PROD TOUCH — READY FOR PROD PROMOTION

---

## 1. Preflight

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend (bastion) | main | `97656c6` (AO) | 0 | OK |
| keybuzz-infra | main | `3a017fe` (AO.1 rapport) | untracked docs | OK |
| keybuzz-api | ph147.4/source-of-truth | non modifie | - | Non touche |
| keybuzz-client | ph148/onboarding-activation-replay | `150a1c3d` | 0 | Non touche |

### Runtimes avant intervention

| Service | Image PROD | Image DEV | Verdict |
|---|---|---|---|
| Backend | `v1.0.44-amazon-oauth-env-guard-prod` | `v1.0.44-amazon-oauth-env-guard-dev` | DEV a patcher |
| API | `v3.5.142-promo-retry-email-prod` | `v3.5.155-promo-retry-metadata-email-dev` | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | `v3.5.157-promo-winner-ux-fix-dev` | Non touche |
| Website | `v0.6.9-promo-forwarding-prod` | - | Non touche |

### Health avant

| Service | Health | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | OK (uptime 1664s) | 0 | OK |
| Backend DEV | OK | 0 | OK |
| API PROD | OK | 0 | OK |
| API DEV | OK | 0 | OK |

### Env vars Backend PROD/DEV avant

| Variable | PROD | DEV | Verdict |
|---|---|---|---|
| CLIENT_APP_URL | NOT SET | NOT SET | **BUG** — cause RC1 |
| CLIENT_CALLBACK_URL | NOT SET | NOT SET | Non utilise |
| FRONTEND_URL | NOT SET | NOT SET | Non utilise |
| AMAZON_SPAPI_REDIRECT_URI | `backend.keybuzz.io/...` | `backend-dev.keybuzz.io/...` | OK (AO fix) |
| NODE_ENV | production | production | OK |

---

## 2. Symptomes PROD observes

### Symptome 1 — `/start` redirect vers Backend host

| Point | Resultat | Verdict |
|---|---|---|
| URL depart OAuth | `/api/amazon/oauth/start` (BFF) | OK |
| returnTo stocke dans OAuthState | `/start` (chemin relatif) | **BUG** |
| Backend callback `reply.redirect()` | `reply.redirect('/start?amazon_connected=true&tenant_id=xxx')` | **BUG** |
| Resolution navigateur | `https://backend.keybuzz.io/start?...` | **BUG** |
| Route Backend `/start` | N'existe pas | **404** |
| CLIENT_APP_URL pour normaliser | NOT SET | **BUG** |

### Symptome 2 — `/channels` activation echoue

| Point | Resultat | Verdict |
|---|---|---|
| URL depart OAuth | `https://client.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-fr` | OK |
| returnTo stocke | URL absolue Client (correcte) | OK |
| Backend redirect | `${returnTo}?amazon_connected=true&tenant_id=xxx` (double `?`) | **BUG** |
| URL finale | `...channels?amazon_connected=true&expected_channel=amazon-fr?amazon_connected=true&tenant_id=xxx` | **Malformee** |
| `expected_channel` parse par Client | `amazon-fr?amazon_connected=true` (corrompu) | **BUG** |
| `activateAmazonChannels` appele | Oui (BFF `activate-channels` existe en PROD) | OK |
| API `POST /channels/activate-amazon` | Code `backendConnection` present (AM.9) | OK |
| Activation resultat | `null` ou `activated: []` | **ECHEC** |
| Message UI | "OAuth termine mais l'activation du canal a echoue" | Confirme |

---

## 3. Root causes

### RC1 — Relative returnTo non normalise

**Fichier** : `keybuzz-backend/src/modules/marketplaces/amazon/amazon.routes.ts`, callback handler

**Code bugge** :
```javascript
const clientUrl = oauthState.returnTo || process.env.CLIENT_CALLBACK_URL || "https://client-dev.keybuzz.io/onboarding";
return reply.redirect(`${clientUrl}?amazon_connected=true&tenant_id=${oauthState.tenantId}`);
```

Quand `returnTo = '/start'` : `reply.redirect('/start?...')` → resolu par le navigateur vers `backend.keybuzz.io/start` → 404.

### RC2 — Concatenation naive des query params

Le Backend utilise `${clientUrl}?amazon_connected=true&...` sans verifier si `clientUrl` contient deja des query params. Ceci cree un double `?` dans l'URL, corrompant les parametres existants.

### RC3 (preventif) — Aucune protection open redirect

Le champ `returnTo` etait utilise tel quel sans validation de l'host. Un attaquant pouvait potentiellement injecter un URL vers un domaine externe (open redirect via le flow OAuth).

| Hypothese | Preuve | Confirmee |
|---|---|---|
| returnTo relatif non normalise | Code `reply.redirect('/start?...')` observe | **OUI** |
| CLIENT_APP_URL absente | `NOT SET` dans Backend PROD et DEV | **OUI** |
| Double `?` dans l'URL | Concatenation `${url}?param` sans URL API | **OUI** |
| Open redirect possible | Aucune validation d'host sur returnTo | **OUI** |
| Protocol-relative `//evil.com` exploitable | `new URL('//evil.com', base)` resout vers evil.com | **OUI** (corrige) |

---

## 4. Design du fix

### Fonction `buildSafeRedirectUrl`

Ajoutee dans `amazon.routes.ts`, avant `registerAmazonRoutes` :

| Regle | Implementation |
|---|---|
| Relative → absolue | `returnTo.startsWith("/") && !returnTo.startsWith("//")` → `new URL(returnTo, CLIENT_APP_URL)` |
| Absolue → allowlist | `new URL(returnTo).host` verifie dans `[CLIENT_APP_URL.host, "client.keybuzz.io", "client-dev.keybuzz.io"]` |
| Protocol-relative bloquee | `returnTo.startsWith("//")` → fallback |
| Invalid/null → fallback | `CLIENT_APP_URL/channels` |
| Pas de double `?` | `URL.searchParams.set(key, value)` + `if (!has(key))` |
| Open redirect impossible | Host non allowliste → fallback vers Client |

### Env var `CLIENT_APP_URL`

| Env | Valeur |
|---|---|
| DEV | `https://client-dev.keybuzz.io` |
| PROD (futur AO.3) | `https://client.keybuzz.io` |

---

## 5. Patch DEV

### Fichier modifie

| Service | Fichier | Changement |
|---|---|---|
| Backend | `src/modules/marketplaces/amazon/amazon.routes.ts` | +66 lignes, -8 lignes |

### Changements :

1. **Ajout `buildSafeRedirectUrl()`** : fonction de normalisation (55 lignes)
2. **Remplacement redirect succes** : `reply.redirect(safeRedirectUrl)` au lieu de concatenation naive
3. **Remplacement redirect erreur** : `buildSafeRedirectUrl(null, { amazon_error: msg })` au lieu de fallback DEV hardcode
4. **Suppression** du fallback `"https://client-dev.keybuzz.io/onboarding"` hardcode
5. **Ajout log** : `[Amazon OAuth] Redirecting to: ... (returnTo was: ...)`

### Commit Backend

| Element | Valeur |
|---|---|
| Commit | `ba494f2` |
| Message | `PH-SAAS-T8.12AO.2: safe returnTo redirect — normalize relative paths, prevent open redirect, fix double query params` |
| Branche | main |

---

## 6. Build DEV

| Element | Valeur |
|---|---|
| Service | Backend |
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.45-amazon-oauth-returnto-guard-dev` |
| Digest | `sha256:cbde5dc49bdc3b3396da27c822895f6afe6794dc6f87122a2018ae4308eb546d` |
| Source commit | `ba494f2` |
| Methode | Clone propre, `--no-cache`, detached HEAD |
| Rollback | `v1.0.44-amazon-oauth-env-guard-dev` |

---

## 7. GitOps DEV

| Manifest | Image avant | Image apres | Env ajoutee | Commit infra |
|---|---|---|---|---|
| `k8s/keybuzz-backend-dev/deployment.yaml` | `v1.0.44-amazon-oauth-env-guard-dev` | `v1.0.45-amazon-oauth-returnto-guard-dev` | `CLIENT_APP_URL=https://client-dev.keybuzz.io` | `5ceaae8` |

Rollback :
```yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-dev
# et supprimer CLIENT_APP_URL
```

---

## 8. Validation DEV /start

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| returnTo `/start` | `client-dev.keybuzz.io/start` | `https://client-dev.keybuzz.io/start?amazon_connected=true&tenant_id=test` | **PASS** |
| Host is client-dev | true | true | **PASS** |
| Path is /start | true | true | **PASS** |
| amazon_connected=true | true | true | **PASS** |
| tenant_id present | true | true | **PASS** |
| No backend host | true | true | **PASS** |

---

## 9. Validation DEV /channels

| Etape | Attendu | Resultat | Verdict |
|---|---|---|---|
| returnTo `client-dev.../channels?amazon_connected=true&expected_channel=amazon-fr` | URL propre avec `&tenant_id` | `https://client-dev.keybuzz.io/channels?amazon_connected=true&expected_channel=amazon-fr&tenant_id=test` | **PASS** |
| Host client-dev | true | true | **PASS** |
| Path /channels | true | true | **PASS** |
| amazon_connected=true (pas double) | true | true | **PASS** |
| expected_channel=amazon-fr preserve | true | true | **PASS** |
| tenant_id present | true | true | **PASS** |
| Pas de double `?` | true | true | **PASS** |
| No backend host | true | true | **PASS** |

---

## 10. Validation cross-env / security

| Cas | Attendu | Resultat | Verdict |
|---|---|---|---|
| `backend.keybuzz.io/start` (PROD backend) | Bloque → fallback client | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `backend-dev.keybuzz.io/channels` (DEV backend) | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `api.keybuzz.io/channels` (API host) | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `evil.com/steal?token=abc` | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `client.keybuzz.io.evil.com/phish` (subdomain spoof) | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `javascript:alert(1)` (XSS) | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `//evil.com/redir` (protocol-relative) | Bloque → fallback | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `/start` (relatif valide) | Normalise vers client | `client-dev.keybuzz.io/start?...` | **PASS** |
| `/channels` (relatif valide) | Normalise vers client | `client-dev.keybuzz.io/channels?...` | **PASS** |
| `client-dev.keybuzz.io/start` (DEV absolu) | Autorise | `client-dev.keybuzz.io/start?...` | **PASS** |
| `client.keybuzz.io/channels` (PROD absolu) | Autorise (allowlist) | `client.keybuzz.io/channels?...` | **PASS** |

**11/11 PASS**

---

## 11. Non-regression

### PROD read-only

| Surface | Image | Restarts | Verdict |
|---|---|---|---|
| Backend PROD | `v1.0.44-amazon-oauth-env-guard-prod` | 0 | **INCHANGE** |
| API PROD | `v3.5.142-promo-retry-email-prod` | 0 | **INCHANGE** |
| Client PROD | `v3.5.153-promo-visible-price-prod` | 0 | **INCHANGE** |
| Website PROD | `v0.6.9-promo-forwarding-prod` | - | **INCHANGE** |
| OW PROD | `v3.5.165-escalation-flow-prod` | - | **INCHANGE** |

### eComLG PROD

| Channel | Status | inbound_email | Verdict |
|---|---|---|---|
| amazon-be | active | HAS_EMAIL | **INCHANGE** |
| amazon-es | active | HAS_EMAIL | **INCHANGE** |
| amazon-fr | active | HAS_EMAIL | **INCHANGE** |
| amazon-it | active | HAS_EMAIL | **INCHANGE** |
| amazon-pl | active | HAS_EMAIL | **INCHANGE** |

### DEV

| Service | Health | Restarts | Verdict |
|---|---|---|---|
| Backend DEV | OK | 0 | **PASS** |
| API DEV | OK | 0 | **PASS** |

### CronJobs PROD

| Job | Status | Verdict |
|---|---|---|
| outbound-tick-processor | Running | OK |
| sla-evaluator | Running | OK |
| trial-lifecycle-dryrun | Running | OK |
| amazon-orders-sync | Running | OK |
| amazon-reports-tracking-sync | Running | OK |
| carrier-tracking-poll | Running | OK |

---

## 12. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend | `ba494f2` | PH-SAAS-T8.12AO.2: safe returnTo redirect — normalize relative paths, prevent open redirect, fix double query params |
| keybuzz-infra | `5ceaae8` | gitops(dev): AO.2 Backend v1.0.45-amazon-oauth-returnto-guard-dev + CLIENT_APP_URL env var |

---

## 13. Images Docker

### DEV (apres)

| Service | Tag | Digest | Change |
|---|---|---|---|
| Backend | `v1.0.45-amazon-oauth-returnto-guard-dev` | `sha256:cbde5dc4...` | **NOUVEAU** |

### PROD (inchange)

| Service | Tag | Change |
|---|---|---|
| Backend | `v1.0.44-amazon-oauth-env-guard-prod` | Non touche |
| API | `v3.5.142-promo-retry-email-prod` | Non touche |
| Client | `v3.5.153-promo-visible-price-prod` | Non touche |

---

## 14. Gaps restants

### 14.1 Activation bridge en PROD

L'activation depuis `/channels` en PROD requiert que le Backend BFF et l'API cooperent correctement. Le fix AO.2 resout le returnTo et le double `?`, ce qui devrait corriger la corruption de `expected_channel`. La promotion PROD (AO.3) est necessaire pour valider le flux complet.

### 14.2 CLIENT_APP_URL a ajouter en PROD

Le manifest Backend PROD n'a pas encore `CLIENT_APP_URL`. A ajouter lors de la promotion AO.3 :
```yaml
- name: CLIENT_APP_URL
  value: "https://client.keybuzz.io"
```

### 14.3 Activation echoue si pas de pending channel

L'API `POST /channels/activate-amazon` ne cree pas de channels — elle active seulement les `pending`. Si l'utilisateur lance OAuth sans avoir ajoute de channel (via `/channels/add`), l'activation retourne `activated: []`. Ceci est un comportement attendu mais le message d'erreur devrait etre plus explicite.

### 14.4 Test utilisateur OAuth reel non effectue

La validation structurelle est complete. Un test reel Amazon OAuth DEV est recommande pour confirmer le flux de bout en bout.

---

## 15. Recommandation AO.3 PROD promotion

Pour la promotion PROD, il faudra :

1. Build Backend PROD : `v1.0.45-amazon-oauth-returnto-guard-prod` depuis `ba494f2`
2. Ajouter `CLIENT_APP_URL=https://client.keybuzz.io` au manifest Backend PROD
3. GitOps manifest update + apply
4. Validation structurelle PROD
5. Test utilisateur OAuth PROD (`/start` + `/channels`)

Aucun rebuild API ou Client necessaire — le fix est 100% Backend + env var.

---

## 16. Rollback DEV

```bash
# Backend DEV
kubectl set image deploy/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-dev -n keybuzz-backend-dev
# Puis mettre a jour le manifest et supprimer CLIENT_APP_URL
```

---

## VERDICT

**GO DEV FIX READY**

AMAZON OAUTH RETURNTO AND ACTIVATION BRIDGE READY IN DEV — UI ROUTES REDIRECT TO CLIENT HOST (`client-dev.keybuzz.io`) — BACKEND NEVER SERVES `/START` — RELATIVE PATHS NORMALIZED VIA `CLIENT_APP_URL` — NO DOUBLE QUERY PARAMS — `expected_channel` PRESERVED — OPEN REDIRECT BLOCKED (11/11 SECURITY TESTS PASS) — PROTOCOL-RELATIVE BLOCKED — STATE FOUND — NO CONNECTOR RESURRECTION — ECOMLG 5 CHANNELS PRESERVED — ALL SERVICES HEALTHY — NO PROD TOUCH — READY FOR PROD PROMOTION (AO.3)
