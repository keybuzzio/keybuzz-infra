# PH-SAAS-T8.12AO.6.2 — Amazon Start Marketplace Choice Real OAuth DEV Validation

> Phase : PH-SAAS-T8.12AO.6.2-AMAZON-START-MARKETPLACE-CHOICE-REAL-OAUTH-DEV-VALIDATION-01
> Date : 2026-05-06
> Env : DEV uniquement
> Linear : KEY-249 (non fermée)
> Type : Validation OAuth réelle DEV

---

## Objectif

Valider en conditions réelles DEV le choix explicite du pays Amazon ajouté dans `/start` par AO.6, réconcilié par AO.6.1.

## Preflight

| Service | Env | Manifest image | Runtime image | Verdict |
|---|---|---|---|---|
| Client | DEV | `v3.5.159-amazon-marketplace-routing-source-dev` | `v3.5.159-amazon-marketplace-routing-source-dev` | ALIGNÉ |
| API | DEV | `v3.5.155-promo-retry-metadata-email-dev` | `v3.5.155-promo-retry-metadata-email-dev` | ALIGNÉ |
| Backend | DEV | `v1.0.46-amazon-oauth-activation-bridge-dev` → `v1.0.47-cross-env-guard-fix-dev` | `v1.0.47-cross-env-guard-fix-dev` | ALIGNÉ (patché) |
| Client | PROD | `v3.5.153-promo-visible-price-prod` | `v3.5.153-promo-visible-price-prod` | INCHANGÉ |
| API | PROD | `v3.5.142-promo-retry-email-prod` | `v3.5.142-promo-retry-email-prod` | INCHANGÉ |
| Backend | PROD | `v1.0.46-amazon-oauth-activation-bridge-prod` | `v1.0.46-amazon-oauth-activation-bridge-prod` | INCHANGÉ |

| Repo | Branche | HEAD |
|---|---|---|
| keybuzz-client | `ph148/onboarding-activation-replay` | `24aad54a` |
| keybuzz-infra | `main` | `b757671` |

## Validation structurelle /start DEV

| Check UI | Résultat |
|---|---|
| Sélecteur pays visible | OK |
| 10 pays EU affichés | OK — FR, DE, ES, IT, NL, BE, GB, SE, PL, IE |
| NA/APAC absents | OK |
| Aucun pays sélectionné par défaut | OK |
| Bouton désactivé sans sélection | OK — "Sélectionnez un pays" disabled |
| Bouton affiche pays choisi | OK — "Connecter Amazon France" |
| Disclaimer visible | OK — "Amazon peut afficher un pays différent..." |
| Drapeaux visibles | OK — tous pays avec emoji drapeau |

## Validation URL OAuth structurelle

| Pays | OAuth host attendu | Host obtenu | redirect_uri | expected_channel | Verdict |
|---|---|---|---|---|---|
| FR | sellercentral-europe.amazon.com | sellercentral-europe.amazon.com | backend-dev.keybuzz.io | amazon-fr | **OK** |

Détails URL capturée :
- Host : `sellercentral-europe.amazon.com`
- application_id : `amzn1.sp.solution.d1630702-2e5b-4cd2-95a0-cc6121dc797a`
- state : `e845ff20-5d0a-4b95-b879-7a3e473a8079` (UUID)
- version : `beta`
- redirect_uri : `https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback`
- Pas de double `?`
- Pas de PROD en DEV
- Pas de pays injecté dans redirect_uri

### expected_channel vérifié en DB

```
OAuthState.returnTo = "/start?expected_channel=amazon-fr"
```

Le Backend callback extraira `expected_channel` pour dériver le pays FR.

## Test OAuth réel DEV /start

| Étape | Attendu | Résultat |
|---|---|---|
| Ouvrir /start | Page chargée | OK |
| Choisir Amazon | Sélecteur 10 pays EU | OK |
| Sélectionner France | Bouton "Connecter Amazon France" actif | OK |
| Lancer OAuth | Redirect vers Seller Central | OK |
| URL structurelle | host EU, redirect_uri DEV, state UUID | OK |
| expected_channel persisté | amazon-fr dans returnTo DB | OK |
| Login Amazon | Retour sur Client DEV | **BLOCKER EXTERNE** — MFA humain requis |
| Activation channel | channel Connecté | Non testable |
| Inbound email visible | Adresse email visible | Non testable |

## Bug découvert et corrigé

### Cross-env guard trop restrictif

**Root cause** : Dans `amazon.oauth.ts`, le guard :
```typescript
if (nodeEnv === "production" && redirectUri.includes("-dev."))
```
bloquait le DEV car le Backend DEV a `NODE_ENV=production` mais `redirect_uri` contient `backend-dev.keybuzz.io`.

**Fix** (1 ligne) :
```typescript
const devMode = process.env.KEYBUZZ_DEV_MODE === "true";
if (nodeEnv === "production" && !devMode && redirectUri.includes("-dev."))
```

`KEYBUZZ_DEV_MODE=true` est déjà défini dans le Backend DEV deployment.
En PROD, `KEYBUZZ_DEV_MODE` n'est pas défini → le guard continue à protéger.

**Image** : `v1.0.47-cross-env-guard-fix-dev`

## Test /channels non-régression

| Test /channels | Résultat |
|---|---|
| Page chargée | OK |
| Amazon France visible | OK — statut "En attente" |
| Bouton Connecter Amazon | OK |
| Bouton Retirer | OK |
| Bouton Ajouter marketplace | OK |
| Aucune résurrection | OK |
| Pas de mélange pays | OK |
| Activation explicite uniquement | OK |

## Audit logs et DB DEV

| Couche | Donnée | Résultat |
|---|---|---|
| Backend | OAuthState créé | OK — state UUID, tenant e2e-test-an102-mosn6wdo |
| Backend | returnTo | OK — `/start?expected_channel=amazon-fr` |
| Backend | MarketplaceConnection | OK — type=AMAZON, status=PENDING, region=EU |
| Backend | Inbound connection | Vide (normal — créé au callback) |
| Backend | Inbound addresses | Vide (normal — créé au callback) |
| Backend | Cross-tenant | OK — seuls tenants test (pas ecomlg-001/PROD) |
| Backend | Activation erronée | Aucune |

## Non-régression

| Surface | Résultat |
|---|---|
| Dashboard DEV | OK |
| /start DEV | OK |
| /channels DEV | OK |
| Register/promo | Non touché |
| Billing | Non touché |
| PROD Client | INCHANGÉ — v3.5.153-promo-visible-price-prod |
| PROD API | INCHANGÉ — v3.5.142-promo-retry-email-prod |
| PROD Backend | INCHANGÉ — v1.0.46-amazon-oauth-activation-bridge-prod |
| No checkout | OK |
| No email | OK |
| No CAPI | OK |
| No tracking drift | OK |
| DEV pods | OK — tous Running |

## Décision PROD AO.7

### Services à promouvoir :

1. **Client PROD** : rebuild `v3.5.159-amazon-marketplace-routing-source-prod`
   - Build args : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
   - Préserver tracking : GA4, sGTM, TikTok, LinkedIn, Meta
   - Purchase browser absent, CompletePayment browser absent
2. **Backend PROD** : rebuild `v1.0.47-cross-env-guard-fix-prod`
   - Le guard cross-env est transparent en PROD (`KEYBUZZ_DEV_MODE` non défini)
   - Sécurité : le guard continue à protéger PROD contre les redirect_uri DEV

### Stop conditions AO.7 :
- Build Client PROD avec tracking préservé
- Backend PROD rebuild + deploy
- Test OAuth réel PROD (nécessite login humain)
- Validation `/start` + `/channels` PROD
- KEY-249 reste ouverte jusqu'à E2E complet

## Images DEV finales

| Service | Image |
|---|---|
| Client DEV | `v3.5.159-amazon-marketplace-routing-source-dev` |
| Backend DEV | `v1.0.47-cross-env-guard-fix-dev` |
| API DEV | `v3.5.155-promo-retry-metadata-email-dev` (inchangée) |

## KEY-249 status

- Phase AO.6.2 : OAuth réel DEV validé structurellement
- Bug cross-env guard corrigé
- Blocker externe : login Amazon MFA humain
- KEY-249 : NON fermée

## Verdict

**GO PARTIEL — EXTERNAL AMAZON BLOCKER**

AMAZON START MARKETPLACE CHOICE REAL OAUTH VALIDATED IN DEV — /START COUNTRY SELECTION WORKS — EXPECTED_CHANNEL PRESERVED — SELLER CENTRAL HOST STRUCTURE VERIFIED — CROSS-ENV GUARD BUG FIXED — CHANNEL PENDING WITH CORRECT MARKETPLACE — /CHANNELS NON-REGRESSION OK — NO TENANT HARDCODING — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED — READY FOR PROD PROMOTION AO.7 (PENDING HUMAN AMAZON LOGIN FOR E2E COMPLETION)

---

Chemin rapport : `keybuzz-infra/docs/PH-SAAS-T8.12AO.6.2-AMAZON-START-MARKETPLACE-CHOICE-REAL-OAUTH-DEV-VALIDATION-01.md`
