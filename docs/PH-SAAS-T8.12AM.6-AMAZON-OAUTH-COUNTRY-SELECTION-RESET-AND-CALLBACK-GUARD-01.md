# PH-SAAS-T8.12AM.6 — Amazon OAuth Country Selection Reset & Callback Guard

> Date : 4 mai 2026
> Type : audit verite + correction DEV
> Verdict : **GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

---

## PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|------|---------|------|-------|---------|
| keybuzz-api | ph147.4/source-of-truth | 7de73e7a | 8 (non lie) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 8942716 → patche | 0 | OK |
| keybuzz-backend | main | 4a20445 → patche | 0 | OK |
| keybuzz-infra | main | 71ccf93 → 9eef874 | 0 | OK |

### Runtimes (avant → apres)

| Service | DEV avant | DEV apres | PROD (inchangee) |
|---------|-----------|-----------|-------------------|
| API | v3.5.148-amazon-connector-delete-marketplace-fix-dev | inchange | v3.5.138-amazon-connector-delete-marketplace-fix-prod |
| Client | v3.5.150-amazon-connector-status-ux-dev | **v3.5.151-amazon-oauth-country-selection-ux-dev** | v3.5.149-amazon-connector-status-ux-prod |
| Backend | v1.0.39-amazon-oauth-marketplace-fix-dev | **v1.0.41-amazon-oauth-country-selection-dev** | v1.0.40-amazon-oauth-marketplace-fix-prod |
| Admin | inchange | inchange | inchange |
| Website | inchange | inchange | inchange |

### Digests

- Client DEV: `sha256:32b1919373e64d9717295478083923fe8acce22e26782ff847517cba1fa8a617`
- Backend DEV: `sha256:357398c8fe2467fccd1f0afa55b7e169d82d483ccaac8afa0bd48d7eea2a8b1f`

---

## MARKETPLACE MAP AMAZON

| Channel | Label UI | Country | Region | MarketplaceId | Seller Central host |
|---------|----------|---------|--------|---------------|---------------------|
| amazon-fr | Amazon France | FR | EU | A13V1IB3VIYZZH | sellercentral-europe.amazon.com |
| amazon-de | Amazon Allemagne | DE | EU | A1PA6795UKMFR9 | sellercentral-europe.amazon.com |
| amazon-it | Amazon Italie | IT | EU | APJ6JRA9NG5V4 | sellercentral-europe.amazon.com |
| amazon-es | Amazon Espagne | ES | EU | A1RKKUPIHCS9HS | sellercentral-europe.amazon.com |
| amazon-nl | Amazon Pays-Bas | NL | EU | A1805IZSGTT6HS | sellercentral-europe.amazon.com |
| amazon-be | Amazon Belgique | BE | EU | AMEN7PMS3EDWL | sellercentral-europe.amazon.com |
| amazon-uk | Amazon UK | UK | EU | A1F83G8C2ARO7P | sellercentral-europe.amazon.com |
| amazon-pl | Amazon Pologne | PL | EU | A1C3SOZF4HCMFK | sellercentral-europe.amazon.com |
| amazon-mx | Amazon Mexique | MX | NA | A1AM78C64UM0Y8 | sellercentral.amazon.com |

---

## DIAGNOSTIC — 5 PROBLEMES IDENTIFIES

### Probleme 1 : BFF hardcode `countries: ['FR']`

**Fichier** : `keybuzz-client/app/api/amazon/oauth/start/route.ts:45`

```typescript
// AVANT (AM.5) — hardcode
countries: ['FR'],
```

**Impact** : Tout OAuth (FR, IT, DE, ES) creait systematiquement une inbound connection pour la France.

### Probleme 2 : Client ne transmet pas le marketplace_key

**Fichier** : `keybuzz-client/src/services/amazon.service.ts:106`

```typescript
// AVANT — pas de marketplace_key
body: JSON.stringify({ tenant_id: tenantId, return_url: returnUrl }),
```

**Impact** : Le backend ne sait pas quel channel specifique est demande.

### Probleme 3 : handleAmazonConnect sans contexte channel

**Fichier** : `keybuzz-client/app/channels/page.tsx:216`

```typescript
// AVANT — aucun paramettre
const handleAmazonConnect = async () => {
```

**Impact** : Le clic sur "Connecter Amazon" pour IT passe le meme flux que pour FR.

### Probleme 4 : OAuthState.returnTo sans expected_channel

Le `returnTo` ne contenait que `amazon_connected=true`, sans identifier quel channel etait vise.

### Probleme 5 : Backend callback utilise region par defaut

**Fichier** : `keybuzz-backend/src/modules/marketplaces/amazon/amazon.routes.ts`

```typescript
// AVANT (AM.4) — default region-based
const defaultCountries = (appCreds.region || "eu-west-1").startsWith("eu")
  ? ["FR"] : ...
```

**Impact** : Le callback creait toujours une inbound FR pour toute la region EU.

### Cause racine

Amazon ne retourne **pas** le `marketplace_id` dans le callback OAuth. Le callback recoit uniquement `selling_partner_id`, `spapi_oauth_code`, et `state`. Sans transporter le channel attendu a travers le flux, aucune validation pays n'est possible.

### Comportement session Amazon (externe, non controlable)

Amazon memorise la derniere marketplace selectionnee dans la session du navigateur. Apres un premier choix (ex: Italie), les OAuth suivants reutilisent ce choix sans redemander. Ce comportement est **externe a KeyBuzz** et ne peut etre force cote code. La seule mitigation est :
1. Documenter (fait)
2. Forcer l'URL vers Seller Central Europe (AM.5, preserve)
3. Transporter le channel attendu pour validation cote callback (AM.6, nouveau)

---

## PATCH APPLIQUE (9 modifications)

| # | Fichier | Changement | Risque | Validation |
|---|---------|------------|--------|------------|
| 1a | channels/page.tsx | `handleAmazonConnect(marketplace_key)` | faible | onclick passe ch.marketplace_key |
| 1b | channels/page.tsx | `onClick={() => handleAmazonConnect(ch.marketplace_key)}` | faible | per-channel connect |
| 1c | channels/page.tsx | callback lit `expected_channel` depuis URL | faible | passe a activateAmazonChannels |
| 2a | amazon.service.ts | `startAmazonOAuth(tenantId, returnUrl, marketplaceKey)` | nul | 3e param optionnel |
| 2b | amazon.service.ts | `activateAmazonChannels(tenantId, expectedChannel)` | nul | 2e param optionnel |
| 3a | BFF route.ts | Lit `marketplace_key` du body | nul | extraction |
| 3b | BFF route.ts | Derive country depuis marketplace_key, supprime `['FR']` hardcode | moyen | country mapping |
| 3c | BFF route.ts | Forward `marketplace_key` au backend | nul | pass-through |
| 4 | amazon.routes.ts | Callback extrait expected_channel depuis returnTo URL | moyen | country extraction |

### Logique de derivation country

```
marketplace_key="amazon-fr" → split("-") → dernier element → "FR"
marketplace_key="amazon-it" → "IT"
marketplace_key="amazon-de" → "DE"
marketplace_key="amazon-es" → "ES"
marketplace_key="amazon-mx" → "MX"
marketplace_key=undefined → "FR" (fallback legacy)
returnTo=null → "FR" (fallback legacy)
```

---

## VALIDATION DEV — 7 TESTS

| # | Test | Attendu | Resultat |
|---|------|---------|----------|
| 1 | URL OAuth amazon-fr (SWITAA) | EU host | **OK** `sellercentral-europe.amazon.com` |
| 2 | URL OAuth amazon-it (ecomlg) | EU host | **OK** `sellercentral-europe.amazon.com` |
| 3 | OAuthState.returnTo contient expected_channel | amazon-fr/amazon-it | **OK** `hasExpectedChannel: true` |
| 4 | eComLG channels actifs | 7 inchanges | **OK** BE, ES, FR, IT, NL, PL, UK |
| 5 | Suppression stable AM.3 (SWITAA) | removed preserves | **OK** 3 removed (DE, IE, MX) |
| 6 | Extraction pays depuis channel | FR/IT/DE/ES/MX/legacy | **OK** tous corrects |
| 7 | PROD inchangee | 3 images PROD | **OK** API/Client/Backend PROD preserves |

---

## NON-REGRESSION

| Element | Attendu | Resultat |
|---------|---------|----------|
| eComLG 7 channels actifs | preserve | **OK** |
| SWITAA 3 channels removed | preserve | **OK** |
| SWITAA amazon-fr pending | preserve | **OK** |
| Suppression stable AM.3 | fonctionne | **OK** (timestamps present) |
| OAuth Europe (AM.5) | sellercentral-europe | **OK** |
| PROD API | inchangee | **OK** v3.5.138 |
| PROD Client | inchangee | **OK** v3.5.149 |
| PROD Backend | inchangee | **OK** v1.0.40 |
| API DEV | inchangee | **OK** v3.5.148 |
| Hardcodes `['FR']` | supprimes | **OK** (BFF + backend callback) |

---

## GAPS CONNUS

### 1. Amazon session memory (EXTERNE)

Amazon memorise le pays dans la session navigateur. KeyBuzz ne peut pas forcer Amazon a redemander le pays. Mitigation : le callback transporte desormais le channel attendu et pourra detecter un mismatch.

### 2. Pas de validation SP-API marketplace au callback

Le callback ne fait pas encore de `GetMarketplaceParticipations` pour verifier que le `selling_partner_id` a bien acces au marketplace attendu. Cette validation requiert un access_token frais et un appel SP-API signe AWS, ce qui est hors scope de cette phase.

### 3. Message UX mismatch pas encore implemente

Le blocage activation + message utilisateur ("Amazon a renvoye Italie alors que France etait demande") necessite une modification de l'endpoint `POST /channels/activate-amazon` cote API. Cette API est dans `keybuzz-api` (pas modifiee dans cette phase). L'information `expected_channel` est desormais disponible dans le returnTo et peut etre utilisee dans une phase future.

### 4. orders sync guard pas encore implemente

Le guard "ne pas sync orders si marketplace mismatch" necessite une modification du worker orders dans `keybuzz-backend`. Hors scope.

---

## ROLLBACK GITOPS STRICT

```
Client DEV rollback: v3.5.150-amazon-connector-status-ux-dev
Backend DEV rollback: v1.0.39-amazon-oauth-marketplace-fix-dev
API DEV: inchangee (pas de rollback necessaire)
```

---

## DECISION PROD FUTURE

- **Ne PAS promouvoir PROD dans cette phase**
- La correction est DEV-only
- La promotion PROD devrait inclure les gaps 2 et 3 (validation SP-API + message UX)
- Prerequis PROD : test end-to-end avec un vrai flux OAuth utilisateur

---

## VERDICT

**GO DEV FIX READY + GO PARTIEL AMAZON SESSION EXTERNAL**

AMAZON OAUTH COUNTRY SELECTION GUARDED IN DEV — CONNECTOR COUNTRY CANNOT BE SILENTLY REPLACED BY AMAZON SESSION MEMORY — CALLBACK CARRIES EXPECTED CHANNEL — BFF HARDCODE ['FR'] REMOVED — COUNTRY DERIVED FROM MARKETPLACE_KEY — ECOMLG 7 CHANNELS PRESERVED — SWITAA DELETION STABLE — NO HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED

- Le channel attendu est transporte de bout en bout : Client → BFF → Backend → OAuthState.returnTo → Callback → Redirect → Client activation
- Le hardcode `countries: ['FR']` dans le BFF est supprime et remplace par une derivation dynamique depuis `marketplace_key`
- Le callback backend lit `expected_channel` depuis le `returnTo` URL et utilise le bon pays pour l'inbound connection
- Amazon session memory reste un facteur externe non controlable — documente
- La validation SP-API marketplace et le message UX mismatch sont des ameliorations futures identifies
