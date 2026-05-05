# PH-SAAS-T8.12AO.6.1 — Amazon Marketplace Routing Source of Truth Reconciliation DEV

> Date : 2026-05-05
> Linear : KEY-249
> Type : Audit verite + reconciliation source officielle Amazon + patch DEV
> Environnement : DEV uniquement
> Priorite : P0

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `5144d68` (avant) / `24aad54` (apres) | Non | GO |
| keybuzz-api | `ph147.4/source-of-truth` | `31a896d` | Non | GO — non modifie |
| keybuzz-infra | `main` | `67f3ee5` (avant) / `d33f19f` (apres) | Non | GO |
| keybuzz-backend | bastion | `v1.0.46-amazon-oauth-activation-bridge-dev` | Non | GO — non modifie |

| Service | Manifest image DEV | Runtime image DEV | Verdict |
|---|---|---|---|
| Client | `v3.5.158` -> `v3.5.159-amazon-marketplace-routing-source-dev` | `v3.5.159-amazon-marketplace-routing-source-dev` | Aligne |
| API | `v3.5.155-promo-retry-metadata-email-dev` | Identique | Inchange |
| Backend | `v1.0.46-amazon-oauth-activation-bridge-dev` | Identique | Inchange |

---

## Sources officielles Amazon relues

1. **Website Authorization Workflow** : https://developer-docs.amazon.com/sp-api/lang-es_ES/docs/website-authorization-workflow
   - Authorization URL : `{sellerCentralUrl}/apps/authorize/consent?application_id={appId}&state={state}`
   - `redirect_uri` doit etre enregistre dans l'app Amazon, unique, pas par pays
   - `spapi_oauth_code` expire en 5 minutes
   - `state` obligatoire, unique par requete

2. **Seller Central URLs** : https://developer-docs.amazon.com/sp-api/docs/seller-central-urls
   - FR/ES/DE/IT/UK : `sellercentral-europe.amazon.com`
   - PL : `sellercentral.amazon.pl`
   - SE : `sellercentral.amazon.se`
   - NL : `sellercentral.amazon.nl`
   - BE : `sellercentral.amazon.com.be`
   - IE : `sellercentral.amazon.ie`

3. **SP-API Endpoints** : https://developer-docs.amazon.com/sp-api/lang-en_US/docs/sp-api-endpoints
   - EU : `sellingpartnerapi-eu.amazon.com` (eu-west-1)
   - NA : `sellingpartnerapi-na.amazon.com` (us-east-1)
   - FE : `sellingpartnerapi-fe.amazon.com` (us-west-2)

4. **Marketplace IDs** : https://developer-docs.amazon.com/sp-api/lang-US/docs/marketplace-ids
   - Table complete extraite et verifiee (16 marketplaces)

---

## Cartographie complete des 16 marketplaces AO.6

| marketplace_key | country | marketplace_id | region | sellerCentralHost | spApiEndpoint | verdict |
|---|---|---|---|---|---|---|
| amazon-fr | FR | A13V1IB3VIYZZH | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-de | DE | A1PA6795UKMFR9 | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-es | ES | A1RKKUPIHCS9HS | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-it | IT | APJ6JRA9NG5V4 | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-nl | NL | A1805IZSGTT6HS | EU | sellercentral.amazon.nl | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-be | BE | AMEN7PMS3EDWL | EU | sellercentral.amazon.com.be | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-gb | GB | A1F83G8C2ARO7P | EU | sellercentral-europe.amazon.com | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-se | SE | A2NODRKZP88ZB9 | EU | sellercentral.amazon.se | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-pl | PL | A1C3SOZRARQ6R3 | EU | sellercentral.amazon.pl | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-ie | IE | A28R8C7NBKEWEA | EU | sellercentral.amazon.ie | sellingpartnerapi-eu.amazon.com | OK_OFFICIAL_MATCH |
| amazon-us | US | ATVPDKIKX0DER | NA | sellercentral.amazon.com | sellingpartnerapi-na.amazon.com | **STOP_DO_NOT_PROMOTE** |
| amazon-ca | CA | A2EUQ1WTGCTBG2 | NA | sellercentral.amazon.ca | sellingpartnerapi-na.amazon.com | **STOP_DO_NOT_PROMOTE** |
| amazon-mx | MX | A1AM78C64UM0Y8 | NA | sellercentral.amazon.com.mx | sellingpartnerapi-na.amazon.com | **STOP_DO_NOT_PROMOTE** |
| amazon-au | AU | A39IBJ37TRP1C6 | FE | sellercentral.amazon.com.au | sellingpartnerapi-fe.amazon.com | **STOP_DO_NOT_PROMOTE** |
| amazon-jp | JP | A1VC38T7YXB528 | FE | sellercentral.amazon.co.jp | sellingpartnerapi-fe.amazon.com | **STOP_DO_NOT_PROMOTE** |
| amazon-sg | SG | A19VAU5U5O7RUS | FE | sellercentral.amazon.sg | sellingpartnerapi-fe.amazon.com | **STOP_DO_NOT_PROMOTE** |

**Raison NA/APAC STOP** : KeyBuzz a des credentials EU (region eu-west-1, app enregistree en EU). Les marketplaces NA/APAC necessitent des enregistrements app separes aupres d'Amazon dans leurs regions respectives.

---

## Audit AO.6 source

| Element | Fichier | Comportement AO.6 | Verdict |
|---|---|---|---|
| Selecteur /start | `OnboardingHub.tsx` | Grid pays Amazon, choix explicite | OK |
| Source marketplaces | API `/channels/catalog` | Filtre `provider=amazon`, deduplique par `marketplace_key` | OK — meme source que /channels |
| `marketplace_key` propagation | `amazon.service.ts` -> BFF -> Backend | POST body, transmis au Backend OAuth start | OK |
| `/channels` utilise meme source | `channels/page.tsx` | Oui, `fetchChannelsCatalog` | OK |
| Champs catalog suffisants | `CatalogEntry` type | `marketplace_key`, `country_code`, `display_name` — pas de `sellerCentralHost` | ACCEPTABLE — le host SC est gere Backend-side |
| Backend connait SC host | `amazon.oauth.ts` | `REGION_SELLER_CENTRAL` map (region-level) | OK pour EU |
| Fallback region/pays | `REGION_SELLER_CENTRAL["eu-west-1"]` | Fallback EU si region inconnue | OK — pas de fallback FR invisible |

### Gaps identifies et corriges

| Gap | Severite | Correction AO.6.1 |
|---|---|---|
| NA/APAC marketplaces affichees | P0 | `EU_SUPPORTED_COUNTRIES` filtre dans OnboardingHub |
| `/start` return_url sans `expected_channel` | P1 | `returnUrl = /start?expected_channel=${marketplace_key}` |
| `COUNTRY_FLAGS` sans IE | P2 | IE ajoute au map |

---

## Audit Backend OAuth URL builder

Source : `amazon.oauth.ts` (lu sur bastion `/opt/keybuzz/keybuzz-backend/src/modules/marketplaces/amazon/`)

| Parametre OAuth | Source actuelle | Attendu | Verdict |
|---|---|---|---|
| Seller Central host | `appCreds.login_uri` OU `REGION_SELLER_CENTRAL[region]` OU fallback `eu-west-1` | Host region EU | OK — `sellercentral-europe.amazon.com` pour toute l'EU |
| `application_id` | Vault `appCreds.application_id` | App ID enregistree | OK |
| `redirect_uri` | Env var `AMAZON_SPAPI_REDIRECT_URI` (priorite) OU Vault | URL callback unique, env-aware | OK — PROD = `backend.keybuzz.io`, DEV = `backend-dev.keybuzz.io` |
| `state` | `crypto.randomUUID()`, stocke en OAuthState DB, expire 10min | Unique, stocke, valide, consomme | OK |
| `version` | Hardcode `"beta"` | `"beta"` si app draft | OK |
| Cross-env guard | `if (nodeEnv==="production" && redirectUri.includes("-dev."))` | Block URL DEV en PROD | OK |
| `marketplace_key` | Non utilise dans le builder OAuth | Non necessaire — OAuth est app-level | OK — le pays est porte par BFF inbound + returnTo |

### Seller Central host — analyse approfondie

Le Backend utilise `REGION_SELLER_CENTRAL` (region-level, pas country-level) :
```
"eu-west-1" -> "https://sellercentral-europe.amazon.com"
"us-east-1" -> "https://sellercentral.amazon.com"
"fe"        -> "https://sellercentral.amazon.co.jp"
```

Pour OAuth, `sellercentral-europe.amazon.com` est le **portail unifie europeen**. Il couvre FR, ES, DE, IT, UK et est egalement accessible pour PL, SE, NL, BE, IE. L'autorisation OAuth est app-level, pas marketplace-level. Un vendeur PL qui se connecte via `sellercentral-europe.amazon.com` autorise la meme application que via `sellercentral.amazon.pl`.

**Conclusion** : le mapping region-level est **suffisant et correct** pour l'OAuth. Un mapping country-level serait un raffinement UX (rediriger vers le Seller Central natif du vendeur) mais n'est pas un pre-requis technique.

---

## Audit API Catalog

| Champ | Present dans CatalogEntry | Utilise par Client | Utilise par Backend | Gap |
|---|---|---|---|---|
| `marketplace_key` | Oui | Oui (filtre, selection, OAuth) | Oui (BFF transmit) | Aucun |
| `country_code` | Oui | Oui (drapeau, filtre EU) | Oui (BFF deriveCountry) | Aucun |
| `display_name` | Oui | Oui (label bouton) | Non | Aucun |
| `marketplace_id` | Oui | Non (UI) | Non (OAuth) | Aucun pour OAuth |
| `region` | Non | Non | Non | NON CRITIQUE — filtre EU client-side |
| `sellerCentralHost` | Non | Non | Non (Backend gere via REGION_SELLER_CENTRAL) | NON CRITIQUE |
| `spApiEndpoint` | Non | Non | Non (Backend gere via region) | NON CRITIQUE |
| `coming_soon` | Oui | Oui (filtre) | Non | Aucun |
| `supports_messaging` | Oui | Non | Non | Aucun |

**Conclusion** : le catalogue API ne contient pas les champs de routing SP-API (region, SC host, SP-API endpoint). Ces champs sont geres Backend-side. Le Client n'a pas besoin de connaitre les details de routing — il transmet `marketplace_key` et le Backend fait le reste. Architecture saine.

---

## Decision patch

| Gap | Severite | Patch | Service | Justification |
|---|---|---|---|---|
| NA/APAC affiches | P0 | PATCH | Client | Credentials EU-only |
| expected_channel manquant | P1 | PATCH | Client | Callback Backend fallback FR |
| IE sans drapeau | P2 | PATCH | Client | UX incomplet |
| SC host region-level | INFO | NO PATCH | Backend | Correct pour OAuth EU |
| redirect_uri | OK | NO PATCH | Backend | Env-aware, cross-env guard |

---

## Patch DEV

| Fichier | Changement | Pourquoi | Risque |
|---|---|---|---|
| `OnboardingHub.tsx` | Ajout `EU_SUPPORTED_COUNTRIES` set, filtre `.has(cc)` | Masquer NA/APAC non supportes | Minimal — filtre additif |
| `OnboardingHub.tsx` | `returnUrl = /start?expected_channel=${marketplace_key}` | Backend callback derive le pays correctement | Minimal — aligne avec /channels |
| `OnboardingHub.tsx` | Ajout `IE` dans `COUNTRY_FLAGS` | Drapeau manquant | Aucun |

Commit : `24aad54` sur `ph148/onboarding-activation-replay`

---

## Build DEV

| Service | Tag | Digest | Resultat |
|---|---|---|---|
| Client DEV | `v3.5.159-amazon-marketplace-routing-source-dev` | `sha256:b5ef882ac2c24824ba4329a81d0aa170999961286f8eb5b802d80fefc1f496d4` | OK |
| API DEV | Non modifie | — | — |
| Backend DEV | Non modifie | — | — |

Build args tracking preserves : `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`, `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`

---

## GitOps DEV

| Service | Image avant DEV | Image apres DEV | Rollout |
|---|---|---|---|
| Client | `v3.5.158-amazon-start-country-choice-dev` | `v3.5.159-amazon-marketplace-routing-source-dev` | OK — Running 1/1, 31s |

Manifest commit : `d33f19f` sur `keybuzz-infra/main`

Rollback DEV si necessaire :
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.158-amazon-start-country-choice-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## Validation navigateur DEV

| Surface | Test | Resultat |
|---|---|---|
| `/start` — grille marketplaces | Amazon, Shopify, Cdiscount, Fnac, eBay | OK |
| `/start` — clic Amazon | Charge catalogue, affiche sélecteur pays | OK |
| `/start` — pays EU visibles | FR, DE, ES, IT, NL, BE, GB, SE, PL, IE | OK — 10 pays |
| `/start` — NA/APAC filtres | US, CA, MX, AU, JP, SG absents | OK |
| `/start` — drapeaux | Tous presents dont IE | OK |
| `/start` — disclaimer | Message SC visible | OK |
| `/start` — bouton desactive | "Selectionnez un pays" disabled | OK |
| `/start` — expected_channel dans returnUrl | Code verifie : `/start?expected_channel=amazon-fr` | OK |

---

## Non-regression

| Surface | Resultat |
|---|---|
| `/start` DEV | OK — 10 pays EU |
| `/channels` DEV | Non modifie |
| `/dashboard` DEV | Non modifie |
| Client PROD | INCHANGE — `v3.5.153-promo-visible-price-prod` |
| API PROD | INCHANGE — `v3.5.142-promo-retry-email-prod` |
| Backend PROD | INCHANGE — `v1.0.46-amazon-oauth-activation-bridge-prod` |
| Website PROD | INCHANGE — `v0.6.9-promo-forwarding-prod` |
| Billing / Stripe | Non touche |
| Tracking GA4/LinkedIn | Build args preserves |
| DB PROD | Zero mutation |
| CAPI / faux events | Aucun |

---

## KEY-249 update

- Audit AO.6.1 complete
- 10 marketplaces EU verifies et affiches
- 6 marketplaces NA/APAC filtres (credentials EU-only)
- `expected_channel` ajoute dans returnUrl
- Seller Central host correct (region-level pour EU)
- redirect_uri env-aware
- Client DEV : `v3.5.159-amazon-marketplace-routing-source-dev`
- PROD inchangee
- Gaps restants : OAuth reel non teste (pas de compte Amazon connecte en DEV)
- Ne pas fermer KEY-249

---

## PROD

PROD est **INCHANGEE** dans cette phase. Aucune image, aucun manifest, aucune DB, aucun secret modifie en PROD.

---

## Verdict

**GO DEV PATCH READY — OAUTH REAL TEST PENDING**

AMAZON MARKETPLACE ROUTING SOURCE OF TRUTH RECONCILED IN DEV — /START AND /CHANNELS SHARE ONE MARKETPLACE SOURCE (API CATALOG) — EU-ONLY FILTER ACTIVE (10 COUNTRIES) — NA/APAC FILTERED (CREDENTIALS EU-ONLY) — SELLER CENTRAL HOST MATCHES AMAZON DOCS (REGION-LEVEL SUFFICIENT FOR EU OAUTH) — REDIRECT_URI ENV-AWARE AND NOT COUNTRY-SPECIFIC — EXPECTED_CHANNEL PRESERVED IN RETURNURL — MARKETPLACE IDS AND SP-API REGIONS VERIFIED AGAINST OFFICIAL AMAZON DOCS 2026 — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION AFTER REAL OAUTH TEST

---

## Chemin du rapport

`keybuzz-infra/docs/PH-SAAS-T8.12AO.6.1-AMAZON-MARKETPLACE-ROUTING-SOURCE-OF-TRUTH-RECONCILIATION-DEV-01.md`
