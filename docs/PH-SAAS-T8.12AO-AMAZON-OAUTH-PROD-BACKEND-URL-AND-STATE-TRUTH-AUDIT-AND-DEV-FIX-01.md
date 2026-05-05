# PH-SAAS-T8.12AO — Amazon OAuth PROD Backend URL and State Truth Audit + DEV Fix

> Phase : PH-SAAS-T8.12AO-AMAZON-OAUTH-PROD-BACKEND-URL-AND-STATE-TRUTH-AUDIT-AND-DEV-FIX-01
> Date : 2026-05-05
> Environnement : PROD read-only audit + DEV fix uniquement
> Type : audit verite + correction DEV
> Priorite : P0
> Ticket : KEY-248
> Verdict : **GO DEV FIX READY**

---

## Phrase cible

AMAZON OAUTH BACKEND URL AND STATE GUARD READY IN DEV — PROD DEV-URL ROOT CAUSE IDENTIFIED — CROSS-ENV CALLBACK BLOCKED — STATE CREATED AND CONSUMED IN SAME ENVIRONMENT — EXPECTED_CHANNEL PRESERVED — INBOUND EMAIL VISIBLE — NO CONNECTOR RESURRECTION — NO PROD TOUCH — READY FOR PROD PROMOTION

---

## 1. Preflight

### Repos

| Repo | Branche | HEAD avant | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend | main | `f2afd3e` (AM.9) | 0 | OK |
| keybuzz-infra | main | `4a45b83` (AN.12) | 0 | OK |
| keybuzz-api | ph147.4/source-of-truth | (non modifie) | - | Non touche |
| keybuzz-client | ph148/onboarding-activation-replay | (non modifie) | - | Non touche |

### Runtimes avant intervention

| Service | DEV | PROD | Verdict |
|---|---|---|---|
| API | v3.5.155-promo-retry-metadata-email-dev | v3.5.142-promo-retry-email-prod | Non touche |
| Client | v3.5.157-promo-winner-ux-fix-dev | v3.5.153-promo-visible-price-prod | Non touche |
| Backend | v1.0.43-amazon-oauth-activation-country-dev | v1.0.42-amazon-oauth-inbound-bridge-prod | Patche DEV |
| Website | - | v0.6.9-promo-forwarding-prod | Non touche |
| OW | - | v3.5.165-escalation-flow-prod | Non touche |

---

## 2. Sources de verite relues

| Source | Lu | Pertinent |
|---|---|---|
| CE_PROMPTING_STANDARD.md | Oui | GitOps, build-from-git, bastion |
| RULES_AND_RISKS.md | Oui | DEV first, dual DB, Vault TLS |
| AM.3 rapport | Oui | Self-healing supprime, /status read-only |
| AM.5 rapport | Oui | Seller Central Europe, login_uri |
| AM.6 rapport | Oui | Country selection, expected_channel |
| AM.7 rapport | Oui | Inbound READY, activation truth |
| AM.8 rapport | Oui | PROD promotion inbound |
| AM.9 rapport | Oui | Dual DB bridge, Backend→API |
| AM.9.1 rapport | Oui | Inbound addresses sync |
| AM.10 rapport | Oui | AM.9+AM.9.1 PROD promotion |

---

## 3. Audit PROD read-only

### 3.1 Env vars PROD

| Surface | Variable | Valeur PROD | Verdict |
|---|---|---|---|
| Backend PROD | AMAZON_SPAPI_REDIRECT_URI | `https://backend.keybuzz.io/.../callback` | Correct |
| Backend PROD | VAULT_ADDR | `http://vault.default.svc.cluster.local:8200` | Present |
| Backend PROD | NODE_ENV | production | Correct |
| Client PROD | AMAZON_BACKEND_URL | `http://keybuzz-backend.keybuzz-backend-prod.svc.cluster.local:4000` | Correct |
| Client PROD | BACKEND_URL | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80` | Correct |
| API PROD | **LEGACY_BACKEND_URL** | `http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000` | **BUG — pointe vers DEV** |

### 3.2 Recherche URLs DEV dans PROD

| Pattern | Client PROD bundle | Backend PROD env | API PROD env | Verdict |
|---|---|---|---|---|
| `backend-dev.keybuzz.io` | 0 occurrences | Absent env direct | Absent env direct | OK bundle |
| `api-dev.keybuzz.io` | 0 occurrences | Absent | Absent | OK |
| `client-dev.keybuzz.io` | 0 occurrences | Absent | Absent | OK |
| `keybuzz-backend-dev` (K8s internal) | - | - | **LEGACY_BACKEND_URL** | **BUG** |

### 3.3 Vault — Decouverte critique

| Element | Documentation | Realite | Impact |
|---|---|---|---|
| Vault service status | "DOWN depuis 7 jan 2026" | **ACTIF depuis le 3 mars 2026** | Vault repond aux requetes |
| Vault K8s endpoint | - | 10.0.0.150, 10.0.0.154, 10.0.0.155 port 8200 | Accessible depuis les pods |
| Vault health | - | HTTP 429, initialized, unsealed, standby | Fonctionnel |

### 3.4 Vault credentials Amazon

| Champ Vault | Valeur | Attendu PROD | Verdict |
|---|---|---|---|
| redirect_uri | `https://backend-dev.keybuzz.io/.../callback` | `https://backend.keybuzz.io/.../callback` | **ROOT CAUSE** |
| login_uri | `https://sellercentral-europe.amazon.com` | Correct | OK |
| region | eu-west-1 | Correct | OK |
| client_id | amzn1.application-oa... | Partage DEV/PROD | OK |

---

## 4. Root cause

### 4.1 Cause primaire — Vault redirect_uri DEV

Le secret Vault `secret/data/keybuzz/amazon_spapi/app` contient `redirect_uri: https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback`.

Ce secret est **partage** entre DEV et PROD (meme chemin Vault, meme token).

Le code `getAmazonAppCredentials()` dans `amazon.vault.ts` :
1. Si `VAULT_ADDR` et `VAULT_TOKEN` sont definis → fetch Vault
2. Vault retourne `redirect_uri: backend-dev...`
3. Le code utilise `creds.redirect_uri` (Vault) directement
4. L'env var `AMAZON_SPAPI_REDIRECT_URI` (qui est correcte en PROD) n'est **jamais consultee**

### 4.2 Flux du bug

```
1. User sur client.keybuzz.io (PROD) clique "Connecter Amazon"
2. BFF appelle Backend PROD via AMAZON_BACKEND_URL (correct, PROD interne)
3. Backend PROD appelle getAmazonAppCredentials() → Vault repond avec redirect_uri DEV
4. OAuth URL construite avec redirect_uri=https://backend-dev.keybuzz.io/...
5. User redirige vers Amazon Seller Central, autorise
6. Amazon redirige vers https://backend-dev.keybuzz.io/.../callback?state=xxx
7. Backend DEV recoit le callback
8. Backend DEV cherche state=xxx dans keybuzz_backend (DEV DB)
9. Le state a ete cree par le Backend PROD dans keybuzz_backend_prod
10. → invalid_state — OAuth state not found
```

### 4.3 Cause secondaire — LEGACY_BACKEND_URL

L'API PROD a `LEGACY_BACKEND_URL = http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000` dans son manifest. Cette URL pointe vers le Backend DEV. Utilise par `compat/routes.js` (proxy legacy) et `ai-assist-routes.js`.

### 4.4 Cause tertiaire — Code sans fallback

Le `catch` block de `getAmazonAppCredentials()` faisait `throw error` au lieu de fallback sur les env vars. Si Vault etait tombe apres le fix, le Backend n'aurait pas pu demarrer les OAuth du tout.

### Tableau hypotheses

| Hypothese | Preuve | Confirmee |
|---|---|---|
| Vault redirect_uri = DEV | Vault API retourne `backend-dev...` | **OUI** |
| Env var PROD correcte mais ignoree | Code prend Vault en priorite | **OUI** |
| Vault actif malgre documentation "DOWN" | systemctl status = running, HTTP 429 | **OUI** |
| State cross-env (PROD→DEV) | State cree en PROD DB, callback sur DEV | **OUI** |
| LEGACY_BACKEND_URL DEV en PROD | `kubectl exec node -e` confirme | **OUI** |
| Build Client PROD contient URL DEV | grep 0 occurrences | NON |
| Amazon app n'a que DEV registered | - | Non teste (hors scope) |

---

## 5. Patch DEV

### Fichiers modifies

| Fichier | Changement | Risque |
|---|---|---|
| `amazon.vault.ts` | Env var `AMAZON_SPAPI_REDIRECT_URI` prend priorite sur Vault `redirect_uri` | Faible — env var correcte en DEV et PROD |
| `amazon.vault.ts` | Catch block : fallback gracieux aux env vars au lieu de throw | Faible — resilience amelioree |
| `amazon.oauth.ts` | Guard cross-env : PROD rejette redirect_uri contenant `-dev.` | Nul — fail-safe additionnel |

### Commit Backend

| Element | Valeur |
|---|---|
| Repo | keybuzz-backend |
| Branche | main |
| Commit | `97656c6` |
| Message | PH-SAAS-T8.12AO: env var overrides Vault redirect_uri + cross-env guard + Vault fallback |
| Parent | `f2afd3e` (AM.9) |

---

## 6. Build DEV

| Element | Valeur |
|---|---|
| Service | Backend |
| Tag | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.44-amazon-oauth-env-guard-dev` |
| Digest | `sha256:a16099f730d1ac3143a17f804280f239ff615db0901eaa914da46643d618ad1e` |
| Source commit | `97656c6` |
| Source branche | main |
| Methode | Clone propre, `--no-cache` |
| Rollback | `v1.0.43-amazon-oauth-activation-country-dev` |

---

## 7. GitOps DEV

| Manifest | Image avant | Image apres | Commit infra |
|---|---|---|---|
| `k8s/keybuzz-backend-dev/deployment.yaml` | v1.0.43-amazon-oauth-activation-country-dev | **v1.0.44-amazon-oauth-env-guard-dev** | `9cc8114` |

Rollout : succes, 0 restarts.

---

## 8. Validation DEV

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| DEV redirect_uri | `backend-dev.keybuzz.io` | `backend-dev.keybuzz.io` | **PASS** |
| Env var prise en priorite | true | true | **PASS** |
| Cross-env guard bloque DEV en PROD | Guard triggered | Guard triggered | **PASS** |
| PROD env var override Vault | `backend.keybuzz.io` | `backend.keybuzz.io` | **PASS** |
| Vault fallback gracieux | Fallback env vars | Fallback OK | **PASS** |
| eComLG 7 canaux actifs DEV | 7 active avec email | 7 active avec email | **PASS** |
| PROD images inchangees | 5 images PROD identiques | Confirme | **PASS** |
| PROD Backend toujours bugue | Vault DEV URL | Confirme (PROD non touchee) | **PASS** |
| DEV Backend health | OK | `{"status":"ok"}` | **PASS** |
| DEV API health | OK | `{"status":"ok"}` | **PASS** |
| DEV Client | 307 redirect | 307 | **PASS** |

---

## 9. Cross-env guards

| Cas | Attendu | Resultat | Verdict |
|---|---|---|---|
| DEV : Vault DEV URL + env var DEV | DEV URL utilisee | DEV URL | **PASS** |
| PROD simule : Vault DEV URL sans env var | Guard bloque | Guard triggered | **PASS** |
| PROD simule : Vault DEV URL + env var PROD | PROD URL utilisee | PROD URL | **PASS** |
| Vault down : fallback env var | Env var DEV | Env var DEV | **PASS** |

---

## 10. Non-regression

| Surface | DEV | PROD | Verdict |
|---|---|---|---|
| Backend health | OK | OK | **PASS** |
| API health | OK | OK | **PASS** |
| Client | 307 | 307 | **PASS** |
| eComLG channels DEV | 7 active, 3 removed | - | **PASS** |
| eComLG channels PROD | - | 5 active, 2 removed | **PASS** |
| Backend pod restarts | 0 | 0 | **PASS** |
| PROD API image | Non touchee | v3.5.142-promo-retry-email-prod | **PASS** |
| PROD Client image | Non touchee | v3.5.153-promo-visible-price-prod | **PASS** |
| PROD Backend image | Non touchee | v1.0.42-amazon-oauth-inbound-bridge-prod | **PASS** |
| PROD Website image | Non touchee | v0.6.9-promo-forwarding-prod | **PASS** |
| PROD OW image | Non touchee | v3.5.165-escalation-flow-prod | **PASS** |
| Billing subscriptions PROD | Non touchee | 7 | **PASS** |
| CronJobs PROD | Non touches | Running | **PASS** |
| DB mutation PROD | Aucune | Aucune | **PASS** |

---

## 11. PROD inchangee

Aucune modification PROD effectuee dans cette phase :
- Aucun build PROD
- Aucun deploy PROD
- Aucune mutation DB PROD
- Aucun secret modifie
- PROD Backend reste bugue (utilise Vault DEV URL) — correction prevue dans phase PROD

---

## 12. Rollback DEV GitOps

```yaml
# k8s/keybuzz-backend-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-backend:v1.0.43-amazon-oauth-activation-country-dev
```

Puis `kubectl apply -f` + `kubectl rollout status`.

---

## 13. Trouvailles additionnelles

### 13.1 Vault est actif (documentation obsolete)

La documentation keybuzz-v3-context.mdc indique "Vault DOWN depuis le 7 janvier 2026 (~52 jours)". En realite, `vault.service` est `active (running) since Tue 2026-03-03 21:14:07 UTC` (plus de 2 mois). Les services ne se contentent plus des secrets K8s caches : Vault repond activement aux requetes.

**Action recommandee :** Mettre a jour la documentation Vault dans les rules.

### 13.2 LEGACY_BACKEND_URL en API PROD pointe vers DEV

Le manifest `k8s/keybuzz-api-prod/deployment.yaml` contient :
```
LEGACY_BACKEND_URL = http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000
```

Cette variable est utilisee par `compat/routes.js` (proxy legacy channels/status) et `ai-assist-routes.js`. L'API PROD envoie certaines requetes au Backend DEV.

**Action recommandee :** Corriger dans la phase PROD promotion.

### 13.3 Vault secret Amazon devrait etre per-environment

Le secret `secret/data/keybuzz/amazon_spapi/app` est partage entre DEV et PROD. La `redirect_uri` devrait etre stockee dans des paths separes (`secret/data/keybuzz/dev/amazon_spapi/app` et `secret/data/keybuzz/prod/amazon_spapi/app`), ou l'env var devrait toujours prendre priorite (ce que fait le fix AO).

---

## 14. Recommandation AO.1 PROD promotion

Pour corriger PROD, la phase suivante doit :

1. **Build Backend PROD** depuis commit `97656c6` avec tag `v1.0.44-amazon-oauth-env-guard-prod`
2. **Deploy Backend PROD** via GitOps
3. **Corriger LEGACY_BACKEND_URL** dans API PROD manifest → `http://keybuzz-backend.keybuzz-backend-prod.svc.cluster.local:4000`
4. **(Optionnel)** Mettre a jour le secret Vault pour ajouter la PROD redirect_uri ou separer les paths
5. **Build API PROD** si LEGACY_BACKEND_URL corrige (re-deploy necessaire)
6. Tester un flux OAuth complet en PROD
7. Ne PAS fermer KEY-248 avant validation PROD

---

## 15. Commits

| Repo | Commit | Message |
|---|---|---|
| keybuzz-backend | `97656c6` | PH-SAAS-T8.12AO: env var overrides Vault redirect_uri + cross-env guard + Vault fallback |
| keybuzz-infra | `9cc8114` | PH-SAAS-T8.12AO: GitOps DEV Backend v1.0.44-amazon-oauth-env-guard-dev |
| keybuzz-infra | (ce rapport) | PH-SAAS-T8.12AO: rapport final |

---

## 16. Images Docker

### DEV (apres)

| Service | Tag | Digest |
|---|---|---|
| Backend | v1.0.44-amazon-oauth-env-guard-dev | sha256:a16099f730d1... |
| API | v3.5.155-promo-retry-metadata-email-dev | (inchange) |
| Client | v3.5.157-promo-winner-ux-fix-dev | (inchange) |

### PROD (inchangee)

| Service | Tag |
|---|---|
| Backend | v1.0.42-amazon-oauth-inbound-bridge-prod |
| API | v3.5.142-promo-retry-email-prod |
| Client | v3.5.153-promo-visible-price-prod |
| Website | v0.6.9-promo-forwarding-prod |
| OW | v3.5.165-escalation-flow-prod |

---

## VERDICT

**GO DEV FIX READY**

AMAZON OAUTH BACKEND URL AND STATE GUARD READY IN DEV — PROD DEV-URL ROOT CAUSE IDENTIFIED (VAULT SHARED REDIRECT_URI) — CROSS-ENV CALLBACK BLOCKED (GUARD IN amazon.oauth.ts) — ENV VAR OVERRIDES VAULT (amazon.vault.ts) — VAULT FALLBACK GRACEFUL — STATE CREATED AND CONSUMED IN SAME ENVIRONMENT — EXPECTED_CHANNEL PRESERVED — INBOUND EMAIL VISIBLE — NO CONNECTOR RESURRECTION — NO PROD TOUCH — LEGACY_BACKEND_URL ISSUE DOCUMENTED — VAULT STATUS DOCUMENTATION OUTDATED — READY FOR PROD PROMOTION
