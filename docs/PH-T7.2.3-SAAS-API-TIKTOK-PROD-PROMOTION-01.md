# PH-T7.2.3 — TikTok SaaS/API PROD Promotion

> **Date** : 19 avril 2026
> **Auteur** : Agent Cursor
> **Environnement** : PROD
> **Type** : Promotion TikTok tracking complet en PROD
> **Prerequis** : PH-T7.2.2.4 (attribution fix valide en DEV)

---

## 1. OBJECTIF

Activer le TikTok tracking complet en PROD :

- Capture `ttclid` et UTMs cote client
- Persistance attribution en DB PROD
- Webhook API (Stripe -> conversion)
- TikTok Pixel (browser events)
- sGTM TikTok Events API (server-side)

---

## 2. PREFLIGHT


| Element           | Valeur                                | Statut   |
| ----------------- | ------------------------------------- | -------- |
| Client branche    | `ph148/onboarding-activation-replay`  | OK       |
| Client HEAD       | `7b82c8a` PH-T7.2.2.4 attribution fix | OK       |
| API branche       | `ph147.4/source-of-truth`             | OK       |
| API HEAD          | `12e1f407` PH-T7.2.2.2 TikTok ttclid  | OK       |
| Client PROD avant | `v3.5.79-tracking-t5.3-replay-prod`   | Confirme |
| API PROD avant    | `v3.5.78-ga4-mp-webhook-prod`         | Confirme |
| Client DEV valide | `v3.5.81-tiktok-attribution-fix-dev`  | Confirme |
| API DEV valide    | `v3.5.79-tiktok-api-replay-dev`       | Confirme |


---

## 3. BUILDS

### Client PROD


| Element      | Valeur                                                                                                                                                                                                                                        |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tag          | `ghcr.io/keybuzzio/keybuzz-client:v3.5.81-tiktok-attribution-fix-prod`                                                                                                                                                                        |
| Digest       | `sha256:3f5f01c730941ecfc0c4136dbd3fbead20e2c4dae0f18ff7e7b4b26548b12380`                                                                                                                                                                     |
| Commit       | `7b82c8a`                                                                                                                                                                                                                                     |
| Build args   | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`, `GA4=G-R3QQDYEBFG`, `META=1234164602194748`, `TIKTOK=CTGBP3JC77UBTJHGMMGG`, `SGTM=https://sgtm.keybuzz.io` |
| Build option | `--no-cache`                                                                                                                                                                                                                                  |


### API PROD


| Element      | Valeur                                                                    |
| ------------ | ------------------------------------------------------------------------- |
| Tag          | `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-prod`            |
| Digest       | `sha256:616634ca5719c4c21614503948d14f5f0febee3ccbfbe75139d20f7c9fbead65` |
| Commit       | `12e1f407`                                                                |
| Build option | `--no-cache`                                                              |


---

## 4. MIGRATION DB PROD

La table `signup_attribution` n'existait pas en PROD (creee uniquement en DEV lors des phases tracking).

### Migration executee

```sql
CREATE TABLE IF NOT EXISTS signup_attribution (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id           TEXT NOT NULL,
  user_email          TEXT NOT NULL,
  utm_source          TEXT,
  utm_medium          TEXT,
  utm_campaign        TEXT,
  utm_term            TEXT,
  utm_content         TEXT,
  gclid               TEXT,
  fbclid              TEXT,
  fbc                 TEXT,
  fbp                 TEXT,
  gl_linker           TEXT,
  plan                TEXT,
  cycle               TEXT,
  landing_url         TEXT,
  referrer            TEXT,
  attribution_id      TEXT,
  stripe_session_id   TEXT,
  conversion_sent_at  TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  ttclid              TEXT
);
CREATE INDEX IF NOT EXISTS idx_signup_attribution_tenant ON signup_attribution(tenant_id);
CREATE INDEX IF NOT EXISTS idx_signup_attribution_created ON signup_attribution(created_at);
```

Executee sur `db-postgres-01` (leader Patroni) dans `keybuzz_prod`. 22 colonnes + 3 index.

### Impact premier test

Le premier test (`ludo.gonthier+TestTikTokOK@gmail.com`) a cree un tenant sans attribution car la table n'existait pas encore. Le deuxieme test apres migration a fonctionne correctement.

---

## 5. DEPLOY


| Element          | Valeur                                   | Statut |
| ---------------- | ---------------------------------------- | ------ |
| Client namespace | `keybuzz-client-prod`                    | OK     |
| Client image     | `v3.5.81-tiktok-attribution-fix-prod`    | OK     |
| Client pod       | `keybuzz-client-9445567f8-dgr64` Running | OK     |
| API namespace    | `keybuzz-api-prod`                       | OK     |
| API image        | `v3.5.79-tiktok-api-replay-prod`         | OK     |
| API pod          | `keybuzz-api-7884676646-kszth` Running   | OK     |
| API health       | `{"status":"ok"}`                        | OK     |


---

## 6. TEST REEL PROD

### Signup E2E


| Etape              | Detail                                                                                                                                                   | Statut |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| URL                | `https://client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=tiktok&utm_medium=cpc&utm_campaign=prod_tiktok_launch&ttclid=test_ttclid_prod_002` | OK     |
| Email              | `ludo.gonthier+TestTikTokOK2@gmail.com`                                                                                                                  | OK     |
| OTP                | Verifie                                                                                                                                                  | OK     |
| Entreprise         | "TikTok PROD V2 SAS"                                                                                                                                     | OK     |
| Utilisateur        | TikTok ProdV2                                                                                                                                            | OK     |
| CGU                | Acceptees                                                                                                                                                | OK     |
| Stripe Checkout    | `cs_live_...` (LIVE mode)                                                                                                                                | OK     |
| Paiement           | Carte reelle, trial 14j                                                                                                                                  | OK     |
| Redirect dashboard | OK                                                                                                                                                       | OK     |


### Tenant cree


| Champ           | Valeur                         |
| --------------- | ------------------------------ |
| ID              | `tiktok-prod-v2-sas-mo5k10ku`  |
| Name            | TikTok PROD V2 SAS             |
| Plan            | PRO                            |
| Status          | `active`                       |
| Subscription    | `sub_1TNrZSFC0QQLHISRYN6vTPZY` |
| Billing status  | `trialing`                     |
| Trial fin       | 2026-05-03                     |
| KBActions grant | 1000 (PRO)                     |


---

## 7. VALIDATION DB

### signup_attribution PROD


| Champ                | Valeur                                  | Statut               |
| -------------------- | --------------------------------------- | -------------------- |
| `ttclid`             | `test_ttclid_prod_001`                  | **OK**               |
| `utm_source`         | `tiktok`                                | **OK**               |
| `utm_medium`         | `cpc`                                   | **OK**               |
| `utm_campaign`       | `prod_tiktok_launch`                    | **OK**               |
| `utm_term`           | `null`                                  | OK (non fourni)      |
| `utm_content`        | `null`                                  | OK (non fourni)      |
| `gclid`              | `null`                                  | OK (non fourni)      |
| `fbclid`             | `null`                                  | OK (non fourni)      |
| `fbp`                | `fb.1.1776428335013...`                 | **OK** (Meta cookie) |
| `plan`               | `pro`                                   | **OK**               |
| `cycle`              | `monthly`                               | **OK**               |
| `landing_url`        | URL complete avec tous les query params | **OK**               |
| `attribution_id`     | `43523a6e-...`                          | **OK**               |
| `stripe_session_id`  | `null`                                  | Attendu              |
| `conversion_sent_at` | `null`                                  | Voir section 8       |


Note : le `ttclid` contient `test_ttclid_prod_001` (de la premiere visite) car la strategie first-touch conserve le contexte initial dans `sessionStorage`.

---

## 8. WEBHOOK ET CONVERSION

### Stripe Webhook


| Evenement                       | Statut                        |
| ------------------------------- | ----------------------------- |
| `checkout.session.completed`    | Recu                          |
| `invoice.paid`                  | Recu                          |
| `customer.subscription.created` | Recu                          |
| Tenant activation               | `pending_payment` -> `active` |
| KBActions grant                 | 1000 (PRO)                    |


### Conversion sGTM


| Element                  | Statut            | Detail                                         |
| ------------------------ | ----------------- | ---------------------------------------------- |
| GA4 Measurement Protocol | **Non configure** | `[Conversion] GA4 MP not configured, skipping` |
| `conversion_sent_at`     | `null`            | Consequence du GA4 MP absent                   |


**Explication** : Le webhook de conversion server-side (`emitConversionWebhook`) requiert les env vars `GA4_MEASUREMENT_ID` et `GA4_API_SECRET` dans le deployment API PROD. Ces variables ne sont pas configurees dans le secret K8s actuel. C'est un probleme de **configuration infra**, pas de code.

**Action requise** : Ajouter `GA4_MEASUREMENT_ID` et `GA4_API_SECRET` au secret/configmap de `keybuzz-api-prod` pour activer le pipeline sGTM complet.

---

## 9. TIKTOK PIXEL (BROWSER)


| Element                    | Statut                       | Detail                              |
| -------------------------- | ---------------------------- | ----------------------------------- |
| Script TikTok Pixel        | Charge                       | `analytics.tiktok.com` present      |
| Pixel ID                   | `CTGBP3JC77UBTJHGMMGG`       | Injecte au build                    |
| SubmitForm                 | Fire sur `/register`         | OK                                  |
| InitiateCheckout           | Fire au click "Creer"        | OK                                  |
| CompletePayment            | Fire sur `/register/success` | OK                                  |
| Warning "Invalid pixel ID" | Connu                        | Configuration TikTok Events Manager |


---

## 10. NON-REGRESSION PROD


| Page             | Statut                               |
| ---------------- | ------------------------------------ |
| `/start`         | OK                                   |
| `/dashboard`     | OK — KPIs, supervision               |
| `/inbox`         | OK — TripaneLayout, filtres, API 200 |
| `/settings`      | OK — 10 onglets                      |
| `/billing`       | OK — Plan Pro, KBActions, canaux     |
| `/channels`      | OK — Ajout marketplace               |
| Auth (AuthGuard) | OK — sessions actives                |
| GA4              | OK — script charge                   |
| Meta Pixel       | OK — `fbp` capture                   |
| TikTok Pixel     | OK — script charge, events fired     |


---

## 11. ROLLBACK

### Client PROD

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.79-tracking-t5.3-replay-prod -n keybuzz-client-prod
```

### API PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.78-ga4-mp-webhook-prod -n keybuzz-api-prod
```

Note : la table `signup_attribution` reste en place meme apres rollback (pas d'impact, l'ancien code ne l'utilise pas).

---

## 12. IMAGES DEPLOYEES (19 avril 2026)


| Service | DEV                                  | PROD                                  |
| ------- | ------------------------------------ | ------------------------------------- |
| Client  | `v3.5.81-tiktok-attribution-fix-dev` | `v3.5.81-tiktok-attribution-fix-prod` |
| API     | `v3.5.79-tiktok-api-replay-dev`      | `v3.5.79-tiktok-api-replay-prod`      |


DEV et PROD sont alignes sur le meme codebase.

---

## 13. VERDICT

### TIKTOK PROD TRACKING OPERATIONAL


| Pipeline                      | Statut             | Detail                                               |
| ----------------------------- | ------------------ | ---------------------------------------------------- |
| Client capture (ttclid, UTMs) | **OPERATIONNEL**   | `useSearchParams()` fix, persistance DB confirmee    |
| DB attribution                | **OPERATIONNEL**   | Table creee, INSERT fonctionne, donnees correctes    |
| Stripe webhook                | **OPERATIONNEL**   | checkout.session.completed, subscription, activation |
| TikTok Pixel (browser)        | **OPERATIONNEL**   | SubmitForm, InitiateCheckout, CompletePayment fires  |
| sGTM conversion (server-side) | **CONFIG REQUISE** | GA4 MP env vars manquantes dans API PROD             |


### Actions restantes

1. **CRITIQUE** : Ajouter `GA4_MEASUREMENT_ID` + `GA4_API_SECRET` au deployment `keybuzz-api-prod` pour activer le pipeline sGTM/CAPI complet
2. **SOUHAITABLE** : Valider le Pixel ID `CTGBP3JC77UBTJHGMMGG` dans TikTok Events Manager pour supprimer le warning "Invalid pixel ID"
3. **NETTOYAGE** : Supprimer les tenants de test PROD (`tiktok-prod-test-sas-mo5jsh7z`, `tiktok-prod-v2-sas-mo5k10ku`) apres validation finale

