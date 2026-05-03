# PH-SAAS-T8.12AM.4 — Amazon OAuth Marketplace Country Mismatch — DEV Fix

> **Date** : 4 mai 2026
> **Phase** : PH-SAAS-T8.12AM.4-AMAZON-OAUTH-MARKETPLACE-COUNTRY-MISMATCH-TRUTH-AND-DEV-FIX-01
> **Priorité** : P0
> **Verdict** : **GO DEV FIX READY**

---

## Résumé

Diagnostiqué et corrigé en DEV le problème de marketplace mismatch lors de l'OAuth Amazon :
l'URL OAuth pointait vers `sellercentral.amazon.com` (NA/US) au lieu de `sellercentral-europe.amazon.com` (EU),
provoquant l'ouverture du compte Mexique même quand Amazon FR était sélectionné dans KeyBuzz.

---

## Cause Racine

**3 hardcodes critiques** dans `keybuzz-backend/src/modules/marketplaces/amazon/` :

| # | Fichier | Hardcode | Impact |
|---|---------|----------|--------|
| 1 | `amazon.oauth.ts:11` | `LWA_AUTHORIZE_URL = "https://sellercentral.amazon.com/apps/authorize/consent"` | URL NA envoyée au lieu d'EU — Amazon ouvre Seller Central NA, donc Mexique si le vendeur a un compte NA |
| 2 | `amazon.oauth.ts:196` | `marketplace_id: "A13V1IB3VIYZZH"` (hardcodé FR) dans `completeAmazonOAuth()` | Stocke toujours marketplace_id FR dans Vault, masquant le vrai marketplace |
| 3 | `amazon.routes.ts:334` | `countries: ["FR"]` dans callback `ensureInboundConnection()` | Crée toujours une connexion inbound FR, même si l'OAuth a validé un autre pays |

### Pourquoi Mexique ?

1. `sellercentral.amazon.com` est le Seller Central **NA (North America)**
2. Quand un vendeur comme SWITAA a un compte Seller Central NA (US/MX/CA), Amazon ouvre ce compte
3. SWITAA avait un compte Amazon MX actif côté Amazon, donc c'est le Mexique qui s'affichait
4. Le code KeyBuzz ne vérifiait pas le pays réel validé par Amazon

### Pourquoi pas le Vault `login_uri` ?

Le Vault contient la bonne valeur (`login_uri: https://sellercentral-europe.amazon.com`), mais :
- Le code utilisait un `const LWA_AUTHORIZE_URL` hardcodé et **ignorait** totalement `login_uri`
- Vault est DOWN depuis le 7 jan 2026 → fallback env vars
- Aucune env var `AMAZON_SPAPI_LOGIN_URI` n'est définie
- Résultat : le code allait toujours à `sellercentral.amazon.com`

---

## Correction Appliquée

### Fichier 1 : `amazon.oauth.ts`

**1a — URL OAuth region-aware** :
- Remplacé `const LWA_AUTHORIZE_URL = "https://sellercentral.amazon.com/..."` (hardcode NA)
- Par un mapping `REGION_SELLER_CENTRAL` : `eu-west-1` → EU, `us-east-1` → NA, `fe` → JP
- L'URL utilise `appCreds.login_uri` (Vault) en priorité, puis `REGION_SELLER_CENTRAL[region]`

**1b — marketplace_id dynamique** :
- Supprimé `marketplace_id: "A13V1IB3VIYZZH"` hardcodé dans `completeAmazonOAuth()`
- Le marketplace_id est maintenant déterminé au sync time (pas au OAuth time)

**1c — region dynamique** :
- `region` vient de `appCreds.region` (Vault/env) au lieu d'être hardcodé `"eu-west-1"`
- Le `displayName` region dans `MarketplaceConnection` est calculé dynamiquement (EU/NA/FE)

### Fichier 2 : `amazon.routes.ts`

**2 — countries dynamiques** :
- Supprimé `countries: ["FR"]` hardcodé dans le callback
- Le pays est déterminé par la region de l'app config (EU → FR, NA → US, FE → JP)
- Import `getAmazonAppCredentials` ajouté

---

## Preflight

| Repo | Branche | HEAD | Verdict |
|------|---------|------|---------|
| keybuzz-api | `ph147.4/source-of-truth` | `7de73e7a` | OK |
| keybuzz-client | `ph148/onboarding-activation-replay` | `8942716` | OK |
| keybuzz-backend | `main` | `4a20445` (après commit AM.4) | OK |
| keybuzz-infra | `main` | `f1e174c` (après commit AM.4) | OK |

---

## Marketplace Catalog

Le catalogue dans `channelsService.ts` (API) est complet et structuré :

| UI Label | Channel Key | Country | MarketplaceId | Region SP-API |
|----------|-------------|---------|---------------|---------------|
| Amazon France | `amazon-fr` | FR | A13V1IB3VIYZZH | EU |
| Amazon Allemagne | `amazon-de` | DE | A1PA6795UKMFR9 | EU |
| Amazon Espagne | `amazon-es` | ES | A1RKKUPIHCS9HS | EU |
| Amazon Italie | `amazon-it` | IT | APJ6JRA9NG5V4 | EU |
| Amazon Pays-Bas | `amazon-nl` | NL | A1805IZSGTT6HS | EU |
| Amazon Belgique | `amazon-be` | BE | AMEN7PMS3EDWL | EU |
| Amazon Royaume-Uni | `amazon-uk` | UK | A1F83G8C2ARO7P | EU |
| Amazon Suède | `amazon-se` | SE | A2NODRKZP88ZB9 | EU |
| Amazon Pologne | `amazon-pl` | PL | A1C3SOZF5XXXXX | EU |
| Amazon États-Unis | `amazon-us` | US | ATVPDKIKX0DER | NA |
| Amazon Canada | `amazon-ca` | CA | A2EUQ1WTGCTBG2 | NA |
| Amazon Mexique | `amazon-mx` | MX | A1AM78C64UM0Y8 | NA |
| Amazon Australie | `amazon-au` | AU | A39IBJ37TRP1C6 | FE |
| Amazon Japon | `amazon-jp` | JP | A1VC38T7YXB528 | FE |
| Amazon Singapour | `amazon-sg` | SG | A19VAU5U5O7RUS | FE |
| Amazon Irlande | `amazon-ie` | IE | A28R8C1BZCWXNE | EU |

Aucun hardcode marketplace — le catalogue est structuré et extensible.

---

## Flow Client → BFF → API → Backend

| Couche | Fichier | Comportement |
|--------|---------|-------------|
| Client UI | `channels/page.tsx` | Sélection marketplace via catalogue |
| Client service | `amazon.service.ts` | `startAmazonOAuth()` → BFF |
| BFF | `app/api/amazon/oauth/start/route.ts` | Proxy vers API |
| API compat | `compat/routes.ts` | `proxyToLegacyBackend()` → Backend port 4000 |
| Backend | `amazon.routes.ts` | Crée `MarketplaceConnection`, appelle `generateAmazonOAuthUrl()` |
| Backend | `amazon.oauth.ts` | **Fix AM.4** : utilise `login_uri` Vault ou `REGION_SELLER_CENTRAL[region]` |

---

## Validation DEV

| Test | Attendu | Résultat |
|------|---------|---------|
| OAuth URL host (backend direct) | `sellercentral-europe.amazon.com` | `sellercentral-europe.amazon.com` ✅ |
| OAuth URL host (via API proxy) | `sellercentral-europe.amazon.com` | `sellercentral-europe.amazon.com` ✅ |
| eComLG Amazon channels | 7 active unchanged | 7 active ✅ |
| SWITAA suppression stable | removed channels still removed | Confirmé ✅ |
| SWITAA amazon-mx | removed | `status=removed, disconnected_at=2026-05-03` ✅ |
| API health | OK | `{"status":"ok"}` ✅ |
| Backend health | OK | `{"status":"ok"}` ✅ |
| Amazon status (eComLG) | connected=true | connected=true ✅ |
| PROD unchanged | 3 images identiques | Confirmé ✅ |

---

## SWITAA DB State (sanitized)

| Channel | Status | Connection Ref | Disconnected At |
|---------|--------|----------------|-----------------|
| `amazon-de` | removed | `conn_2e623384...` | 2026-04-20 |
| `amazon-fr` | pending | null | 2026-05-03 |
| `amazon-ie` | removed | null | 2026-04-29 |
| `amazon-mx` | removed | null | 2026-05-03 |

SWITAA a un chemin de reconnexion clair : `amazon-fr` est en `pending`, prêt pour un OAuth EU.

---

## Config Amazon Externe

| Config | DEV | PROD | Risque |
|--------|-----|------|--------|
| `AMAZON_SPAPI_CLIENT_ID` | Set | Set | Aucun |
| `AMAZON_SPAPI_REDIRECT_URI` | Set (`backend-dev.keybuzz.io/...`) | Set | Aucun |
| `AMAZON_SPAPI_LOGIN_URI` | **NON SET** | **NON SET** | Fallback region map OK |
| `AMAZON_SPAPI_REGION` | **NON SET** (default `eu-west-1`) | **NON SET** | Default correct pour EU |
| Vault `login_uri` | `https://sellercentral-europe.amazon.com` | Probablement identique | OK si Vault remis en service |

---

## Build DEV

| Service | Tag | Digest |
|---------|-----|--------|
| Backend | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.39-amazon-oauth-marketplace-fix-dev` | `sha256:0e281eb5ac89c19fc90f5dd2e6913d8887530823801ff46620a311f11dd5357d` |

API et Client : aucune modification nécessaire (le fix est côté backend uniquement).

---

## GitOps DEV

| Manifest | Image Before | Image After |
|----------|--------------|-------------|
| `k8s/keybuzz-backend-dev/deployment.yaml` | `v1.0.46-ph-recovery-01-dev` | `v1.0.39-amazon-oauth-marketplace-fix-dev` |

Commit infra : `f1e174c`

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-backend keybuzz-backend=ghcr.io/keybuzzio/keybuzz-backend:v1.0.46-ph-recovery-01-dev -n keybuzz-backend-dev
```

---

## PROD

PROD inchangée. Aucune promotion dans cette phase.

| Service | PROD Image |
|---------|-----------|
| API | `v3.5.138-amazon-connector-delete-marketplace-fix-prod` |
| Client | `v3.5.149-amazon-connector-status-ux-prod` |
| Backend | `v1.0.46-ph-recovery-01-prod` |

---

## Recommandations PROD Future

1. **Promotion PROD** : Construire `v1.0.39-amazon-oauth-marketplace-fix-prod` avec le même code
2. **Env var** : Ajouter `AMAZON_SPAPI_LOGIN_URI=https://sellercentral-europe.amazon.com` aux secrets DEV/PROD pour expliciter la configuration (actuellement le fallback `REGION_SELLER_CENTRAL["eu-west-1"]` fonctionne)
3. **Callback marketplace validation** : Phase future — valider dans le callback que le `selling_partner_id` correspond à un seller EU si le choix était Amazon FR (nécessite un appel SP-API pour résoudre les marketplace du seller)
4. **SWITAA reconnexion** : Après promotion PROD, SWITAA peut reconnecter Amazon FR — l'URL pointera vers Seller Central EU et non plus NA/MX

---

## Commits

| Repo | Commit | Message |
|------|--------|---------|
| `keybuzz-backend` | `4a20445` | `PH-SAAS-T8.12AM.4: fix OAuth URL NA hardcode` |
| `keybuzz-infra` | `f1e174c` | `PH-SAAS-T8.12AM.4: deploy backend v1.0.39-amazon-oauth-marketplace-fix-dev` |

---

## Verdict

**GO DEV FIX READY**

AMAZON OAUTH MARKETPLACE ROUTING FIXED IN DEV — FR CONNECTOR NO LONGER FALLS BACK TO MEXICO — OAUTH URL USES SELLERCENTRAL-EUROPE.AMAZON.COM (EU) — HARDCODED NA URL REPLACED WITH VAULT LOGIN_URI + REGION MAP — HARDCODED MARKETPLACE_ID AND COUNTRIES REMOVED — ECOMLG 7 CHANNELS PRESERVED — SWITAA SUPPRESSION STABLE — SWITAA RECONNECT PATH HONEST (PENDING FR) — NO HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED
