# PH-SAAS-T8.12AO.7 — Amazon Start Marketplace Choice PROD Promotion

**Date** : 2026-05-06
**Auteur** : Cursor Agent
**Phase** : PH-SAAS-T8.12AO.7-AMAZON-START-MARKETPLACE-CHOICE-PROD-PROMOTION-01
**Environnement** : PROD
**Type** : promotion PROD Client + Backend
**Linear** : KEY-249 (reste ouvert — validation utilisateur pending)

---

## Résumé

Promotion en PROD des changements validés en DEV dans les phases AO.6, AO.6.1 et AO.6.2 :

1. **Client** : `/start` affiche un choix explicite du pays Amazon avant OAuth, filtré aux 10 marketplaces EU supportées
2. **Backend** : fix cross-env guard (`KEYBUZZ_DEV_MODE`) permettant au DEV de fonctionner quand `NODE_ENV=production`

---

## 0. Preflight

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `24aad54a` | Non | OK |
| keybuzz-infra | `main` | `16d3066` | Docs non critiques | OK |
| keybuzz-backend (bastion) | `main` | `d7f48fc` → `c62f376` (post-commit) | `amazon.oauth.ts` (AO.6.2 fix) | OK |

### Runtimes avant promotion

| Service | Env | Image | Verdict |
|---|---|---|---|
| Client | DEV | `v3.5.159-amazon-marketplace-routing-source-dev` | ALIGNÉ |
| Client | PROD | `v3.5.153-promo-visible-price-prod` | BASELINE |
| Backend | DEV | `v1.0.47-cross-env-guard-fix-dev` | ALIGNÉ |
| Backend | PROD | `v1.0.46-amazon-oauth-activation-bridge-prod` | BASELINE |
| API | PROD | `v3.5.142-promo-retry-email-prod` | INCHANGÉ |
| Website | PROD | `v0.6.9-promo-forwarding-prod` | INCHANGÉ |

---

## 1. Source Lock

| Brique | Point vérifié | Résultat |
|---|---|---|
| Client | `EU_SUPPORTED_COUNTRIES` filtre 10 pays | OK |
| Client | `expected_channel` dans returnUrl | OK — ligne 99 |
| Client | Drapeau IE ajouté | OK — ligne 31 |
| Client | `/channels` inchangé | OK |
| Backend | `KEYBUZZ_DEV_MODE === "true"` dans guard | OK — ligne 73 |
| Backend | Guard PROD bloque backend-dev | OK — `!devMode &&` |
| Backend | `AMAZON_SPAPI_REDIRECT_URI` env-aware | OK — vault.ts |

---

## 2. Builds PROD

### Backend commit préalable

```
[main c62f376] fix(amazon): cross-env guard accounts for KEYBUZZ_DEV_MODE (PH-SAAS-T8.12AO.6.2, KEY-249)
 1 file changed, 2 insertions(+), 1 deletion(-)
```

### Images construites

| Service | Tag | Source commit | Digest |
|---|---|---|---|
| Client PROD | `v3.5.159-amazon-marketplace-routing-source-prod` | `24aad54a` | `sha256:0f3291aa5840533537f5fcce97f1c3106c2ec890cac35ec8ea77b4ff41914437` |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `c62f376` | `sha256:0a86583d1971f0da7da55e0cabd7c5f215c6be33148269f333e61c04702244e0` |

### Build args tracking PROD (Client)

- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=production`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`
- `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro`
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`
- `NEXT_PUBLIC_META_PIXEL_ID=1234164602194748`

---

## 3. GitOps PROD

| Manifest | Image avant | Image après | Commit |
|---|---|---|---|
| `keybuzz-client-prod/deployment.yaml` | `v3.5.153-promo-visible-price-prod` | `v3.5.159-amazon-marketplace-routing-source-prod` | `29084f0` |
| `keybuzz-backend-prod/deployment.yaml` | `v1.0.46-amazon-oauth-activation-bridge-prod` | `v1.0.47-cross-env-guard-fix-prod` | `29084f0` |

Aucune modification API/Website/Admin/OW.

---

## 4. Rollout PROD

| Service | Pod | Image | Restarts | Health | Verdict |
|---|---|---|---|---|---|
| Client PROD | `keybuzz-client-5cc5d56df-jh25r` | `v3.5.159-amazon-marketplace-routing-source-prod` | 0 | Running 1/1 | OK |
| Backend PROD | `keybuzz-backend-5bc765c7d8-6qqp6` | `v1.0.47-cross-env-guard-fix-prod` | 0 | Running 1/1 | OK |

Runtime = Manifest. 0 restart anormal.

---

## 5. Validation structurelle PROD /start

| Check | Résultat |
|---|---|
| `/start` se charge | OK |
| Bundle contient EU set (FR,DE,ES,IT,NL,BE,GB,UK,SE,PL,IE) | OK — `page-de0fcb2b6dff79dd.js` |
| Bundle contient `expected_channel` | OK — serveur chunk |
| Bundle contient `marketplace_key` | OK |
| Bundle contient `country_code` filter | OK |
| Validation visuelle directe | PARTIEL — tous les tenants PROD ont déjà Amazon connecté |

Note : la validation visuelle du sélecteur de pays a été réalisée en DEV (AO.6.2). Le bundle PROD est construit depuis la même source (`24aad54a`).

---

## 6. Validation URL OAuth PROD

| Variable | Valeur | Attendu | Verdict |
|---|---|---|---|
| `KEYBUZZ_DEV_MODE` | `false` | `false` | OK |
| `AMAZON_SPAPI_REDIRECT_URI` | `https://backend.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback` | idem | OK |
| `CLIENT_APP_URL` | `https://client.keybuzz.io` | idem | OK |
| `NODE_ENV` | `production` | `production` | OK |

Guard cross-env PROD : `production` + `devMode=false` → toute URL contenant `-dev.` sera bloquée. OK.

---

## 7. Validation /channels PROD

| Check | Résultat |
|---|---|
| `/channels` se charge | OK |
| Amazon France "Connecté" visible | OK — OAuth actif depuis 05/05/2026 |
| Adresse inbound visible | OK — `amazon.bon-kb-mosf283z.fr.fq7fep@inbound.keybuzz.io` |
| Compteur canaux | OK — 1/3 |
| Pas de régression UI | OK |

---

## 8. Tracking Client PROD

| Signal | Résultat |
|---|---|
| GA4 `G-R3QQDYEBFG` | OK — 1 fichier |
| sGTM `t.keybuzz.pro` | OK — 2 fichiers |
| TikTok `D7PT12JC77U44OJIPC10` | OK — 1 fichier |
| LinkedIn `9969977` | OK — 1 fichier |
| Meta `1234164602194748` | OK — 1 fichier |
| Meta Purchase browser | ABSENT (correct) |
| TikTok CompletePayment browser | ABSENT (correct) |

---

## 9. Non-régression PROD

| Surface | Résultat |
|---|---|
| API health | OK — `{"status":"ok"}` |
| Backend health | OK — `{"status":"ok","env":"production"}` |
| Client health | OK — HTTP 200 |
| Website health | OK — HTTP 200 |
| API PROD image inchangée | OK — `v3.5.142-promo-retry-email-prod` |
| Website PROD image inchangée | OK — `v0.6.9-promo-forwarding-prod` |
| Admin PROD image inchangée | OK — `v2.12.1-promo-codes-foundation-prod` |
| OW PROD | OK — `v3.5.165-escalation-flow-prod` |
| 0 CrashLoop | OK |
| 0 fake event / checkout / email / CAPI | OK |

---

## 10. Validation utilisateur Ludovic

**PENDING** — Ludovic doit tester sur PROD :

1. `/start` — choisir Amazon France, lancer OAuth, valider MFA, vérifier retour + channel + inbound
2. `/channels` — vérifier existants

KEY-249 reste ouvert.

---

## 11. Rollback GitOps

Si rollback nécessaire :

```bash
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.153-promo-visible-price-prod -n keybuzz-client-prod

# Backend
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-amazon-oauth-activation-bridge-prod -n keybuzz-backend-prod
```

Puis mettre à jour les manifests GitOps.

---

## Verdict

**GO PARTIEL — USER OAUTH VALIDATION PENDING**

AMAZON START MARKETPLACE CHOICE LIVE IN PROD — /START ASKS EXPLICIT AMAZON COUNTRY BEFORE OAUTH — EU-ONLY MARKETPLACES DISPLAYED — EXPECTED_CHANNEL PRESERVED — BACKEND CROSS-ENV GUARD FIX PROMOTED — /CHANNELS UNCHANGED — CLIENT TRACKING PRESERVED — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — GITOPS STRICT — USER OAUTH VALIDATION PENDING

---

## Fichiers modifiés

| Fichier | Action |
|---|---|
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image → `v3.5.159-amazon-marketplace-routing-source-prod` |
| `keybuzz-infra/k8s/keybuzz-backend-prod/deployment.yaml` | Image → `v1.0.47-cross-env-guard-fix-prod` |
| `keybuzz-backend/src/modules/marketplaces/amazon/amazon.oauth.ts` | Commit `c62f376` (guard fix) |

Rapport : `keybuzz-infra/docs/PH-SAAS-T8.12AO.7-AMAZON-START-MARKETPLACE-CHOICE-PROD-PROMOTION-01.md`
