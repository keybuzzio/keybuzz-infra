# PH-T7.2.2.3 — TikTok E2E Conversion Validation (DEV)

> **Date** : 18 avril 2026
> **Auteur** : Agent Cursor
> **Environnement** : DEV uniquement
> **Type** : Validation E2E (lecture seule — aucune modification code/infra)
> **Prerequis** : PH-T7.2.2.2 (Replay TikTok on valid branches)

---

## 1. OBJECTIF

Validation complete end-to-end du pipeline TikTok sur DEV :

- Browser Pixel (SubmitForm, InitiateCheckout, CompletePayment)
- Capture `ttclid` depuis URL
- Persistance attribution dans DB
- Propagation vers Stripe metadata
- Conversion webhook vers sGTM
- TikTok Events API (sGTM tag)
- Non-regression GA4 / Meta / fonctionnel

---

## 2. PREFLIGHT (ETAPE 0)


| Verification         | Resultat                                     | Statut |
| -------------------- | -------------------------------------------- | ------ |
| Client image         | `v3.5.80-tiktok-replay-dev`                  | OK     |
| API image            | `v3.5.79-tiktok-api-replay-dev`              | OK     |
| Client pod           | `keybuzz-client-5b69cdb5db-rs6wg` Running    | OK     |
| API pod              | `keybuzz-api-6bfccb658f-7k9f4` Running       | OK     |
| sGTM version         | Version 5 publiee (GTM-NTPDQ7N7)             | OK     |
| sGTM TikTok EAPI tag | Present dans version 5                       | OK     |
| DB `ttclid` column   | Existe dans `signup_attribution` (type text) | OK     |
| Baseline GA4         | `G-R3QQDYEBFG`                               | OK     |
| Baseline Meta        | `1234164602194748`                           | OK     |


---

## 3. TEST URL AVEC TTCLID (ETAPE 1)

**URL testee** :

```
https://client-dev.keybuzz.io/pricing?ttclid=test_ttclid_e2e_001&utm_source=tiktok&utm_medium=cpc&utm_campaign=e2e_test
```


| Script                          | Charge                          | Statut |
| ------------------------------- | ------------------------------- | ------ |
| GA4 (`G-R3QQDYEBFG`)            | gtag.js charge                  | OK     |
| Meta Pixel (`1234164602194748`) | fbevents.js charge              | OK     |
| TikTok Pixel                    | analytics.tiktok.com charge     | OK     |
| `ttclid` dans URL               | Visible dans la barre d'adresse | OK     |


---

## 4. SIGNUP + CHECKOUT (ETAPE 2)

### Flow execute

1. Navigation vers `/register?ttclid=test_ttclid_e2e_001`
2. Saisie email : `ludo.gonthier+tiktoktest@gmail.com`
3. Verification OTP : code `553063` saisi
4. Formulaire entreprise : "TikTok Test E2E SAS" + nom "TikTok TestE2E"
5. Selection plan Pro
6. Redirection Stripe Checkout
7. Carte test : `4242 4242 4242 4242`, exp `12/30`, CVC `424`
8. Paiement valide (saisie manuelle — iframes Stripe inaccessibles en automatisation)
9. Redirection vers `/register/success?session_id=cs_test_b1Wsvr...`
10. Redirection vers `/dashboard`

### Resultats


| Element             | Valeur                               | Statut |
| ------------------- | ------------------------------------ | ------ |
| Tenant ID           | `tiktok-test-e2e-sas-mo4y4fde`       | OK     |
| User email          | `ludo.gonthier+tiktoktest@gmail.com` | OK     |
| Role                | `owner`                              | OK     |
| Plan                | `PRO`                                | OK     |
| Subscription status | `trialing`                           | OK     |
| Stripe customer     | `cus_UMQnKPwUxavszh`                 | OK     |
| Stripe subscription | `sub_1TNhxoFC0QQLHISREa4DxAkx`       | OK     |


---

## 5. VALIDATION BROWSER EVENTS (ETAPE 3)

Events captures sur la page `/register/success` (console logs) :


| Event             | Platform | Console log                                | Statut |
| ----------------- | -------- | ------------------------------------------ | ------ |
| `purchase`        | GA4      | `[TRACKING] GA4 event: purchase`           | OK     |
| `Purchase`        | Meta     | `[TRACKING] Meta event: Purchase`          | OK     |
| `CompletePayment` | TikTok   | `[TRACKING] TikTok event: CompletePayment` | OK     |


### Requetes reseau

- `analytics.tiktok.com/api/v2/pixel` POST → **200 OK**
- `facebook.com/tr/` GET → **200 OK**
- `google-analytics.com/g/collect` POST → **204**

### TikTok Pixel warnings (non-bloquants)

1. `Missing email and phone number` — recommandation enrichissement, pas d'erreur
2. `Missing 'content_id' parameter` — requis uniquement pour Video Shopping Ads

### Deduplication

- `event_id` (= `transactionId`) passe dans `CompletePayment` pour dedup browser/server

---

## 6. VALIDATION API / SERVER-SIDE (ETAPE 4)

### signup_attribution

```json
{
  "id": "b4ca29b0-2a36-4776-91ba-f36b2004c307",
  "tenant_id": "tiktok-test-e2e-sas-mo4y4fde",
  "user_email": "ludo.gonthier+tiktoktest@gmail.com",
  "ttclid": null,
  "gclid": null,
  "fbclid": null,
  "fbp": "fb.1.1776428335013.824256521998960206",
  "utm_source": null,
  "utm_medium": null,
  "utm_campaign": null,
  "landing_url": "https://client-dev.keybuzz.io/register",
  "attribution_id": "782f50d0-8d1c-44a3-ae7e-3faa8d117849",
  "conversion_sent_at": "2026-04-18T23:07:56.969Z"
}
```

### Constatations


| Verification             | Resultat                                                     | Statut  |
| ------------------------ | ------------------------------------------------------------ | ------- |
| Row `signup_attribution` | Creee                                                        | OK      |
| `ttclid` persiste        | **null**                                                     | **BUG** |
| UTMs persistes           | **null** (utm_source, utm_medium, utm_campaign)              | **BUG** |
| `fbp` (cookie Meta)      | Capture correctement                                         | OK      |
| `conversion_sent_at`     | Renseigne (`2026-04-18T23:07:56.969Z`)                       | OK      |
| `landing_url`            | `https://client-dev.keybuzz.io/register` (sans query params) | INFO    |


### Conversion webhook

- `conversion_sent_at` est renseigne → le webhook de conversion a ete envoye vers sGTM
- **Mais** : le payload ne contient PAS `ttclid` (null) ni UTMs → l'attribution TikTok cote serveur est incomplete

---

## 7. BUG IDENTIFIE — PERTE DES QUERY PARAMS

### Description

Le `ttclid` et les UTMs (`utm_source`, `utm_medium`, `utm_campaign`) sont presents dans l'URL de navigation mais ne sont PAS captures par `captureAttribution()`.

### Evidence

- `landing_url` stocke : `https://client-dev.keybuzz.io/register` (sans `?ttclid=...&utm_source=...`)
- `ttclid`, `gclid`, `fbclid`, tous les UTMs : `null`
- `fbp` capture (source cookie, pas URL) : confirme que `captureAttribution` s'est executee

### Hypothese root cause

La fonction `captureAttribution` (fichier `src/lib/attribution.ts`) est appelee avec des `searchParams` vides. Deux hypotheses :

1. **Redirect interne** : la page `/register` effectue une redirection interne (ex: check-user, OTP flow) qui supprime les query params avant que `captureAttribution` ne lise l'URL
2. **First-touch timing** : `captureAttribution` est appelee sur un render ou les `useSearchParams()` ne sont pas encore resolus (Next.js async)

### Impact

- **Browser events TikTok** : NON impacte (le Pixel TikTok lit directement `window.location.href` au moment du chargement)
- **Server-side attribution** : IMPACTE — le webhook sGTM n'a pas le `ttclid`, donc le tag TikTok Events API ne peut pas attribuer la conversion
- **Stripe metadata** : IMPACTE — le `ttclid` n'est pas dans les metadata Stripe

### Code concerne

- `src/lib/attribution.ts` : fonction `captureAttribution` (bundle ref: module 38225, export `qs`)
- Le code de capture `ttclid: r("ttclid")` est correct — le probleme est en amont (params absents)

### Correction necessaire (PH suivante)

Capturer les query params **des le premier render** (ou via un effet `useEffect` sur `useSearchParams()`) et les persister en `sessionStorage` immediatement, avant toute redirection.

---

## 8. VALIDATION DB (ETAPE 6)


| Table                   | Verification    | Resultat                                    | Statut  |
| ----------------------- | --------------- | ------------------------------------------- | ------- |
| `signup_attribution`    | Row existe      | `b4ca29b0-...`                              | OK      |
| `signup_attribution`    | `ttclid` column | Existe (type text)                          | OK      |
| `signup_attribution`    | `ttclid` value  | null                                        | **BUG** |
| `tenants`               | Tenant cree     | `tiktok-test-e2e-sas-mo4y4fde`, PRO, active | OK      |
| `users`                 | User cree       | `6ea77cfc-...`, owner                       | OK      |
| `billing_customers`     | Stripe customer | `cus_UMQnKPwUxavszh`                        | OK      |
| `billing_subscriptions` | Subscription    | `sub_1TNhxoFC0QQLHISREa4DxAkx`, trialing    | OK      |


---

## 9. NON-REGRESSION (ETAPE 7)

### Pages testees


| Page      | URL          | Statut | Notes                             |
| --------- | ------------ | ------ | --------------------------------- |
| Dashboard | `/dashboard` | OK     | KPIs, supervision, canaux         |
| Inbox     | `/inbox`     | OK     | TripaneLayout, filtres, recherche |
| Orders    | `/orders`    | OK     | Cockpit SAV, filtres              |
| Channels  | `/channels`  | OK     | 0/3 canaux, bouton ajouter        |
| Billing   | `/billing`   | OK     | Plan Pro, KBActions, historique   |
| Pricing   | `/pricing`   | OK     | Plans, comparatif, FAQ, CTA       |


### Tracking non-regression


| Script                          | Charge | Statut                       |
| ------------------------------- | ------ | ---------------------------- |
| GA4 (`G-R3QQDYEBFG`)            | OK     | Pas de regression            |
| Meta Pixel (`1234164602194748`) | OK     | Pas de regression            |
| TikTok Pixel                    | OK     | Nouveau (ajoute PH-T7.2.2.2) |


### Erreurs pre-existantes (non liees au TikTok)

- `next-auth CLIENT_FETCH_ERROR` (debug level) : intermittent sur navigation, pre-existant

---

## 10. SYNTHESE GLOBALE

### Ce qui FONCTIONNE


| Composant                | Description                                                             | Statut |
| ------------------------ | ----------------------------------------------------------------------- | ------ |
| TikTok Pixel (browser)   | Script charge, events SubmitForm/InitiateCheckout/CompletePayment fires | **OK** |
| TikTok Pixel POST        | `analytics.tiktok.com/api/v2/pixel` → 200                               | **OK** |
| Deduplication `event_id` | `transactionId` passe dans CompletePayment                              | **OK** |
| Signup complet           | User, tenant, billing crees correctement                                | **OK** |
| Stripe Checkout          | Trial Pro, subscription trialing                                        | **OK** |
| Conversion webhook       | `conversion_sent_at` renseigne                                          | **OK** |
| sGTM TikTok EAPI tag     | Present dans version 5 publiee                                          | **OK** |
| GA4 non-regression       | `purchase` event fire sur /register/success                             | **OK** |
| Meta non-regression      | `Purchase` event fire sur /register/success                             | **OK** |
| App fonctionnelle        | 6 pages core testees OK                                                 | **OK** |
| DB schema                | Colonne `ttclid` presente dans `signup_attribution`                     | **OK** |
| API code                 | `ttclid` dans INSERT et SELECT des routes billing/tenant-context        | **OK** |


### Ce qui NE FONCTIONNE PAS


| Composant                | Description                                                | Severite                |
| ------------------------ | ---------------------------------------------------------- | ----------------------- |
| `ttclid` persistance     | Non capture par `captureAttribution` (query params perdus) | **P1**                  |
| UTMs persistance         | Meme cause — utm_source/medium/campaign tous null          | **P1**                  |
| Server-side attribution  | Webhook sGTM envoye SANS `ttclid`                          | **P2** (consequence P1) |
| Stripe metadata `ttclid` | Non present dans les metadata Stripe                       | **P2** (consequence P1) |
| TikTok Events Manager    | Non verifie (necessite acces ads.tiktok.com)               | **INFO**                |


---

## 11. VERDICT

### Pipeline TikTok : PARTIELLEMENT OPERATIONNEL

Le pipeline **browser-side** (Pixel TikTok) est **100% fonctionnel** :

- Le Pixel charge, les events fires, le POST retourne 200
- La deduplication `event_id` est en place

Le pipeline **server-side** (Events API via sGTM) est **code OK mais donnees manquantes** :

- Le code API est correct (ttclid dans INSERT/SELECT)
- Le tag sGTM est deploye (version 5)
- **MAIS** les donnees ne remontent pas car `captureAttribution` perd les query params

### Action requise : PH-T7.2.2.4

Corriger la capture des query params dans `attribution.ts` pour :

1. Lire `useSearchParams()` des le premier render
2. Persister en `sessionStorage` AVANT toute redirection
3. S'assurer que le `landing_url` inclut les query params

---

## 12. IMAGES DEPLOYEES (inchangees)


| Service | Image                                                         | Namespace            |
| ------- | ------------------------------------------------------------- | -------------------- |
| Client  | `ghcr.io/keybuzzio/keybuzz-client:v3.5.80-tiktok-replay-dev`  | `keybuzz-client-dev` |
| API     | `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-dev` | `keybuzz-api-dev`    |


---

## 13. ROLLBACK

Aucune modification effectuee pendant cette validation. Pas de rollback necessaire.
Les images de rollback restent celles documentees dans PH-T7.2.2.2 :

- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev`
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.47-vault-tls-fix-dev`

---

## 14. DONNEES DE TEST CREEES


| Ressource           | Valeur                               | A nettoyer ?    |
| ------------------- | ------------------------------------ | --------------- |
| Tenant              | `tiktok-test-e2e-sas-mo4y4fde`       | Oui (DEV)       |
| User                | `ludo.gonthier+tiktoktest@gmail.com` | Oui (DEV)       |
| Stripe customer     | `cus_UMQnKPwUxavszh`                 | Non (test mode) |
| Stripe subscription | `sub_1TNhxoFC0QQLHISREa4DxAkx`       | Non (test mode) |


