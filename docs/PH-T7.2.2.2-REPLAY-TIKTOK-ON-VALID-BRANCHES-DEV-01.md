# PH-T7.2.2.2-REPLAY-TIKTOK-ON-VALID-BRANCHES-DEV-01 — TERMINE

**Verdict : GO — TIKTOK DEV REPLAY SUCCESS ON VALID BRANCHES**

Date : 2026-04-18
Environnement : DEV uniquement

---

## Prerequis


| Element                                | Statut                   |
| -------------------------------------- | ------------------------ |
| TikTok Pixel ID `D7HQO0JC77U2ODPGMDI0` | OK                       |
| TikTok Events API Access Token         | OK (configure dans sGTM) |
| sGTM Version 5 avec tag TikTok EAPI    | OK (publie)              |


---

## Preflight


| Element           | Valeur                                                            |
| ----------------- | ----------------------------------------------------------------- |
| Client branche    | `ph148/onboarding-activation-replay`                              |
| API branche       | `ph147.4/source-of-truth`                                         |
| Client repo clean | Oui                                                               |
| API repo          | Patches ttclid presents (non commites), commites dans cette phase |


---

## Client

### Fichiers modifies


| Fichier client                              | Modifie | Scope TikTok pur ?                                                                                | OK  |
| ------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------- | --- |
| `src/lib/attribution.ts`                    | Oui     | Oui (ttclid interface, CLICK_ID_PARAMS, capture, hasSignals, minimal)                             | OK  |
| `src/lib/tracking.ts`                       | Oui     | Oui (ttq Window, trackTikTok helper, SubmitForm/InitiateCheckout/CompletePayment, event_id dedup) | OK  |
| `src/components/tracking/SaaSAnalytics.tsx` | Oui     | Oui (TIKTOK_PIXEL_ID env, shouldLoad, TikTok Pixel base code)                                     | OK  |
| `Dockerfile`                                | Oui     | Oui (ARG/ENV NEXT_PUBLIC_TIKTOK_PIXEL_ID)                                                         | OK  |


### Commit client

- Hash : `f2a8523`
- Message : `PH-T7.2.2.2: TikTok tracking replay - ttclid capture, browser events, TikTok Pixel, event_id dedup`
- Branche : `ph148/onboarding-activation-replay`

### Image client

- Tag : `ghcr.io/keybuzzio/keybuzz-client:v3.5.80-tiktok-replay-dev`
- Digest : `sha256:a33cf0f45a49d51d90ae0635fad4647f06957092ba3bc6ce8be0b2d243ef3496`

---

## API

### Fichiers modifies


| Fichier API                                 | Modifie | Scope TikTok pur ?                                                               | OK  |
| ------------------------------------------- | ------- | -------------------------------------------------------------------------------- | --- |
| `src/modules/auth/tenant-context-routes.ts` | Oui     | Oui (ttclid dans INSERT signup_attribution + VALUES)                             | OK  |
| `src/modules/billing/routes.ts`             | Oui     | Oui (ttclid dans SELECT attribution, Stripe metadata, conversion webhook params) | OK  |


### Commit API

- Hash : `12e1f407`
- Message : `PH-T7.2.2.2: TikTok ttclid in signup_attribution INSERT/SELECT, Stripe metadata, conversion webhook`
- Branche : `ph147.4/source-of-truth`

### Image API

- Tag : `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-dev`
- Digest : `sha256:56df176031c64c747194c870496c355ed71a13309adbf1a16a369782a9847059`

---

## DB


| Element                                    | Statut                                          |
| ------------------------------------------ | ----------------------------------------------- |
| Colonne `ttclid` dans `signup_attribution` | Existe                                          |
| Type                                       | `text`                                          |
| Donnees                                    | 0 lignes (aucun signup avec ttclid encore)      |
| Action                                     | Aucune (colonne deja presente depuis PH-T7.2.2) |


---

## sGTM


| Element sGTM                                     | Etat                                 |
| ------------------------------------------------ | ------------------------------------ |
| Tag TikTok EAPI present                          | OK                                   |
| Trigger `purchase_event` (event_name = purchase) | OK                                   |
| Pixel ID `D7HQO0JC77U2ODPGMDI0`                  | OK                                   |
| Access Token configure                           | OK                                   |
| Version publiee                                  | v5                                   |
| Action                                           | Aucune (deja correctement configure) |


---

## Validation

### Fonctionnel


| Page        | Statut | Detail                                                  |
| ----------- | ------ | ------------------------------------------------------- |
| /register   | OK     | Page plan selection, auth redirect, attribution capture |
| /start      | OK     | AuthGuard OK, redirect dashboard                        |
| /dashboard  | OK     | Tenant ecomlg-001, donnees chargees                     |
| /inbox      | OK     | 396 conversations, detail message OK                    |
| /settings   | OK     | AuthGuard OK, page chargee                              |
| API /health | OK     | `{"status":"ok","service":"keybuzz-api"}`               |


### TikTok


| Element                                    | OK/NOK | Detail                                                  |
| ------------------------------------------ | ------ | ------------------------------------------------------- |
| TikTok Pixel ID dans bundle                | OK     | `D7HQO0JC77U2ODPGMDI0` dans layout chunk + server chunk |
| `ttq` (TiktokAnalyticsObject)              | OK     | Present dans bundle                                     |
| `analytics.tiktok.com/events.js` charge    | OK     | HTTP 200, Pixel D7HQO0JC77U2ODPGMDI0                    |
| `analytics.tiktok.com/api/v2/pixel` events | OK     | HTTP 200, PageView fire                                 |
| `analytics.tiktok.com/api/v2/pixel/act`    | OK     | HTTP 200                                                |
| `ttclid` dans attribution bundle           | OK     | Present dans chunk 7085                                 |
| SubmitForm event                           | OK     | Present dans bundle                                     |
| CompletePayment event                      | OK     | Present dans bundle                                     |
| event_id dedup (CompletePayment)           | OK     | Present dans bundle                                     |
| API `ttclid` dans tenant-context-routes.js | OK     | 1 occurrence dans dist                                  |
| API `ttclid` dans billing/routes.js        | OK     | 1 occurrence dans dist                                  |
| sGTM tag TikTok pret                       | OK     | Version 5 publiee                                       |


### Non-regression


| Element                       | OK/NOK | Detail                                      |
| ----------------------------- | ------ | ------------------------------------------- |
| GA4 (G-R3QQDYEBFG)            | OK     | Events page_view + scroll fires, HTTP 204   |
| Meta Pixel (1234164602194748) | OK     | PageView fire, fbevents.js charge, HTTP 200 |
| Google Ads                    | OK     | Aucun impact (pas modifie)                  |


### Test E2E avec ttclid

URL testee : `https://client-dev.keybuzz.io/register?utm_source=tiktok&utm_medium=cpc&utm_campaign=test_campaign&ttclid=test_ttclid_123`


| Element                     | OK/NOK       | Detail                                          |
| --------------------------- | ------------ | ----------------------------------------------- |
| Page charge                 | OK           | /register avec params                           |
| TikTok Pixel fire           | OK           | 3 requetes analytics.tiktok.com reussies        |
| GA4 inclut ttclid dans URL  | OK           | `dl=...&ttclid=test_ttclid_123`                 |
| Meta inclut ttclid dans URL | OK           | `dl=...&ttclid=test_ttclid_123`                 |
| Attribution capture         | OK           | First-touch strategy fonctionne                 |
| Server-side TikTok EAPI     | Non testable | Requiert achat reel (Stripe -> webhook -> sGTM) |


---

## Rollback

### Client

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.79-tracking-t5.3-replay-dev -n keybuzz-client-dev
```

### API

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.78-ga4-mp-webhook-dev -n keybuzz-api-dev
```

---

## Resume images deployees


| Service     | Avant                              | Apres                           |
| ----------- | ---------------------------------- | ------------------------------- |
| Client DEV  | `v3.5.79-tracking-t5.3-replay-dev` | `v3.5.80-tiktok-replay-dev`     |
| API DEV     | `v3.5.78-ga4-mp-webhook-dev`       | `v3.5.79-tiktok-api-replay-dev` |
| Client PROD | Inchange                           | Inchange                        |
| API PROD    | Inchange                           | Inchange                        |
| Website     | Inchange                           | Inchange                        |


---

## Conclusion

**TIKTOK DEV REPLAY SUCCESS ON VALID BRANCHES**

- Replay strict des elements classe A (client) et classe B (API) du rapport forensique
- Aucun fichier non autorise modifie
- Branches correctes utilisees (`ph148/onboarding-activation-replay` et `ph147.4/source-of-truth`)
- TikTok Pixel actif et fonctionnel sur DEV
- GA4 et Meta Pixel intacts
- sGTM tag TikTok EAPI pret pour les conversions server-side
- Rollback pret

Aucune autre action effectuee.