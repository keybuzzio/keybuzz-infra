# PH-T7.0 — Multi-Channel Tracking Architecture Decision

> Date : 18 avril 2026
> Environnement : analyse uniquement (aucun build, deploy ou modification code)
> Type : architecture multi-plateformes ads
> Priorite : STRATEGIQUE

---

## VERDICT

### MULTI-CHANNEL TRACKING ARCHITECTURE READY

L'architecture existante (sGTM Addingwell + trigger "All Events" + payload MP enrichi)
est une fondation excellente. Chaque plateforme = 1 tag sGTM supplementaire.

**Google Ads est faisable immediatement** (sGTM seul, `gclid` deja dans le pipeline).
**LinkedIn est quasi-immediat** (email hash a ajouter au payload MP).
Les autres plateformes suivent un pattern repetitif (capturer le click ID + tag sGTM).

**Bloqueur principal** : Consent Mode V2 (`ad_storage: denied` par defaut) empeche
tous les tags ads de fonctionner. Un CMP est indispensable avant activation.

---

## 1. Etat actuel du pipeline

### Architecture operationnelle (PH-T6.2, 18 avril 2026)

```
Website (browser) ──gtag.js──> t.keybuzz.pro ──> sGTM ──> GA4    ✓
                                                      ──> Meta   ✓

SaaS (browser)    ──gtag.js──> t.keybuzz.io  ──> sGTM ──> GA4    ✓
                                                      ──> Meta   ✓

API (webhook)     ──POST /mp/collect──────────> sGTM ──> GA4    ✓
                                                      ──> Meta   ✓
```

### Composants


| Composant       | Detail                                                         |
| --------------- | -------------------------------------------------------------- |
| Container sGTM  | `GTM-NTPDQ7N7` (Addingwell), version 3                         |
| Domaines custom | `t.keybuzz.pro` (website) + `t.keybuzz.io` (SaaS + MP)         |
| Clients sGTM    | GA4 Web (browser) + GA4 Measurement Protocol (`/mp/collect`)   |
| Tags sGTM       | "GA4 - All Events" + "Meta CAPI - All Events"                  |
| Trigger         | "All Events" (personnalise, tous les evenements)               |
| GA4             | `G-R3QQDYEBFG`                                                 |
| Meta Pixel      | `1234164602194748`                                             |
| Webhook API     | `POST https://t.keybuzz.io/mp/collect` (Measurement Protocol)  |
| Deduplication   | `transaction_id` (GA4 purchase), `event_id` + `fbp/fbc` (Meta) |


### Documents de reference


| Document                                                 | Phase                                   |
| -------------------------------------------------------- | --------------------------------------- |
| `PH-T5.0-ADDINGWELL-ARCHITECTURE-DECISION-01.md`         | Decision 1 container / 2 domaines       |
| `PH-T5.2-ADDINGWELL-SGTM-CONFIG-01.md`                   | Config initiale tags GA4 + Meta CAPI    |
| `PH-T5.7-SGTM-TRIGGER-FIX-ALL-EVENTS-01.md`              | Fix trigger All Events (V3)             |
| `PH-T6.2-SAAS-API-PROD-PROMOTION-ADDINGWELL-FINAL-01.md` | Promotion PROD complete                 |
| `MEDIA-BUYER-TRACKING-GUIDE.md`                          | Guide media buyer (UTM, events, access) |
| `PH-T2-ATTRIBUTION-DB-PERSISTENCE-SAFE-01.md`            | Schema DB `signup_attribution`          |
| `PH-T5.6-GA4-MEASUREMENT-PROTOCOL-WEBHOOK-FORMAT-01.md`  | Format payload MP                       |


---

## 2. Inventaire des donnees disponibles

Source : `src/lib/attribution.ts` + table DB `signup_attribution` + payload MP

### Donnees capturees


| Donnee             | Client           | DB                      | Payload MP | Source                                      |
| ------------------ | ---------------- | ----------------------- | ---------- | ------------------------------------------- |
| `gclid`            | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `fbclid`           | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `fbp`              | OUI              | OUI                     | OUI        | Cookie `_fbp`                               |
| `fbc`              | OUI              | OUI                     | OUI        | Cookie `_fbc` ou synthetise depuis `fbclid` |
| `_gl` (GA linker)  | OUI              | OUI (`gl_linker`)       | NON        | `URLSearchParams`                           |
| `utm_source`       | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `utm_medium`       | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `utm_campaign`     | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `utm_term`         | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `utm_content`      | OUI              | OUI                     | OUI        | `URLSearchParams`                           |
| `email` (hashable) | OUI (signup)     | OUI (`users`)           | NON        | Formulaire register                         |
| `phone` (hashable) | OUI (onboarding) | OUI (`tenant_metadata`) | NON        | Formulaire onboarding                       |
| `transaction_id`   | OUI (Stripe)     | OUI                     | OUI        | `session.id`                                |
| `value`            | OUI              | OUI                     | OUI        | `session.amount_total`                      |
| `currency`         | OUI              | OUI                     | OUI        | `session.currency`                          |


### Donnees NON capturees


| Donnee        | Plateforme  | Parametre URL                                   |
| ------------- | ----------- | ----------------------------------------------- |
| `ttclid`      | TikTok      | `?ttclid=xxx`                                   |
| `sc_click_id` | Snapchat    | `?ScCid=xxx`                                    |
| `epik`        | Pinterest   | `?epik=xxx`                                     |
| `twclid`      | X (Twitter) | `?twclid=xxx`                                   |
| `li_fat_id`   | LinkedIn    | `?li_fat_id=xxx` (optionnel, email hash suffit) |


### Fichiers cles


| Fichier                                     | Role                                       |
| ------------------------------------------- | ------------------------------------------ |
| `src/lib/attribution.ts` (L58)              | `CLICK_ID_PARAMS = ['gclid', 'fbclid']`    |
| `src/lib/attribution.ts` (L18-41)           | Interface `AttributionContext`             |
| `src/lib/tracking.ts` (L58-113)             | Fonctions tracking GA4 + Meta browser      |
| `src/components/tracking/SaaSAnalytics.tsx` | Chargement gtag.js + Meta Pixel            |
| `scripts/ph-t4-patch-api.js` (L185-277)     | Corps `emitConversionWebhook` (reference)  |
| `app/register/page.tsx` (L84-91)            | `initAttribution()` au montage `/register` |


---

## 3. Analyse par plateforme

### Google Ads


| Propriete          | Detail                                                          |
| ------------------ | --------------------------------------------------------------- |
| API                | Google Ads Conversion API (offline) / sGTM natif                |
| Identifiant requis | `gclid` (**DEJA CAPTURE**) ou enhanced conversions (email hash) |
| Tag sGTM           | Natif Google (Conversion Linker + Ads Conversion Tracking)      |
| Template           | Built-in, pas de communautaire                                  |
| Dedup              | Via `transaction_id` / `order_id`                               |
| Prerequis sGTM     | Ajouter 2 tags : Conversion Linker + Google Ads Conversion      |
| Prerequis code     | **AUCUN**                                                       |


### TikTok Ads


| Propriete          | Detail                                                    |
| ------------------ | --------------------------------------------------------- |
| API                | TikTok Events API (S2S)                                   |
| Identifiant requis | `ttclid` (**NON CAPTURE**) + email hash SHA-256 (backup)  |
| Tag sGTM           | Addingwell template communautaire (galerie GTM)           |
| Dedup              | Via `event_id` partage avec le Pixel browser              |
| Prerequis sGTM     | Ajouter tag TikTok Events API                             |
| Prerequis code     | Capturer `ttclid` dans `attribution.ts` + DB + payload MP |


### LinkedIn Ads


| Propriete          | Detail                                                     |
| ------------------ | ---------------------------------------------------------- |
| API                | LinkedIn Conversions API (CAPI)                            |
| Identifiant requis | `SHA256_EMAIL` (**prioritaire**) + `li_fat_id` (optionnel) |
| Tag sGTM           | Addingwell template communautaire                          |
| Dedup              | Via `event_id`                                             |
| Prerequis sGTM     | Ajouter tag LinkedIn CAPI                                  |
| Prerequis code     | Ajouter email hash au payload MP                           |


### Snapchat Ads


| Propriete          | Detail                                                           |
| ------------------ | ---------------------------------------------------------------- |
| API                | Snapchat Conversions API v3                                      |
| Identifiant requis | `sc_click_id` (param URL `ScCid`) (**NON CAPTURE**) + email hash |
| Tag sGTM           | Template officiel Snap (galerie GTM) + alternative Stape         |
| Dedup              | Via `client_dedup_id`                                            |
| Prerequis sGTM     | Ajouter tag Snapchat CAPI                                        |
| Prerequis code     | Capturer `ScCid` dans `attribution.ts` + DB + payload MP         |


### Pinterest Ads


| Propriete          | Detail                                                     |
| ------------------ | ---------------------------------------------------------- |
| API                | Pinterest Conversions API                                  |
| Identifiant requis | `epik` (Pinterest click ID) (**NON CAPTURE**) + email hash |
| Tag sGTM           | Addingwell template communautaire (docs.addingwell.com)    |
| Dedup              | Via `event_id`                                             |
| Prerequis sGTM     | Ajouter tag Pinterest CAPI                                 |
| Prerequis code     | Capturer `epik` dans `attribution.ts` + DB + payload MP    |


### X Ads (Twitter)


| Propriete          | Detail                                                    |
| ------------------ | --------------------------------------------------------- |
| API                | X/Twitter Conversion API                                  |
| Identifiant requis | `twclid` (**NON CAPTURE**) + email hash                   |
| Tag sGTM           | Addingwell template communautaire                         |
| Dedup              | Via `event_id`                                            |
| Prerequis sGTM     | Ajouter tag X Conversion API                              |
| Prerequis code     | Capturer `twclid` dans `attribution.ts` + DB + payload MP |


### Tableau recapitulatif


| Plateforme      | Click ID requis    | Deja capture | Email hash suffit  | Tag sGTM dispo | Difficulte  | Priorite |
| --------------- | ------------------ | ------------ | ------------------ | -------------- | ----------- | -------- |
| **Google Ads**  | `gclid`            | **OUI**      | OUI (enhanced)     | Natif Google   | **FAIBLE**  | **P1**   |
| **LinkedIn**    | `li_fat_id` (opt.) | NON          | **OUI** (primaire) | Addingwell     | **FAIBLE**  | **P1**   |
| **TikTok**      | `ttclid`           | NON          | OUI (backup)       | Addingwell     | **MOYENNE** | **P2**   |
| **Snapchat**    | `ScCid`            | NON          | OUI (backup)       | Officiel Snap  | **MOYENNE** | **P3**   |
| **Pinterest**   | `epik`             | NON          | OUI (backup)       | Addingwell     | **MOYENNE** | **P3**   |
| **X (Twitter)** | `twclid`           | NON          | OUI (backup)       | Addingwell     | **MOYENNE** | **P4**   |


---

## 4. Gap Analysis

### Tier 1 — Faisable via sGTM SEUL (aucun code)

- **Google Ads** : `gclid` deja dans le payload MP + events browser. Il suffit
d'ajouter un tag Conversion Linker (lit le cookie `_gcl_aw` cree par gtag) et
un tag Google Ads Conversion Tracking dans sGTM.

### Tier 2 — Necessite enrichissement du payload MP (code API uniquement)

- **LinkedIn** : ajouter `user_data.sha256_email_address` au payload MP
- **TikTok** (email-only match) : idem
- **Snap/Pinterest/X** (email-only match) : idem

L'email est deja en DB (`users.email`). La transformation SHA-256(lowercase(email))
peut se faire dans `emitConversionWebhook` cote API.

### Tier 3 — Necessite capture client + API + sGTM

- **TikTok** avec `ttclid` (meilleur match quality score)
- **Snapchat** avec `ScCid`
- **Pinterest** avec `epik`
- **X** avec `twclid`

Pattern identique pour tous : ajouter le parametre a `CLICK_ID_PARAMS` dans
`attribution.ts`, ajouter la colonne en DB, inclure dans le payload MP.

### Donnees disponibles en DB mais absentes du payload MP


| Donnee  | Table DB                | Necessite pour                                      |
| ------- | ----------------------- | --------------------------------------------------- |
| `email` | `users.email`           | LinkedIn, TikTok, Snap, Pinterest, X (hash SHA-256) |
| `phone` | `tenant_metadata.phone` | TikTok, Snap (hash SHA-256, format E.164)           |


### Transformations necessaires

```
email → lowercase → SHA-256 → sha256_email_address
phone → format E.164 → SHA-256 → sha256_phone_number
```

Ces transformations peuvent etre faites :

- **Cote API** (dans `emitConversionWebhook`) — recommande
- **Cote sGTM** (variables custom) — possible mais moins flexible

---

## 5. Architecture cible

### Schema

```
                           ┌─────────────────────────────────────────┐
                           │    sGTM GTM-NTPDQ7N7 (Addingwell)      │
                           │                                         │
 Website gtag.js ─────────>│  Client GA4 Web                        │
 SaaS gtag.js ────────────>│           │                             │
                           │           ▼                             │
                           │    Trigger: All Events                  │
                           │           │                             │
 API emitConversionWebhook>│  Client GA4 MP ──┘                     │
   POST /mp/collect        │           │                             │
                           │     ┌─────┴─────────────────────┐      │
                           │     │                           │      │
                           │     ▼                           ▼      │
                           │  Conversion Linker    GA4 All Events   │
                           │     │                     │             │
                           │     ▼                     ▼             │
                           │  Google Ads Conv.    Meta CAPI         │
                           │                                         │
                           │  TikTok Events API                     │
                           │  LinkedIn CAPI                         │
                           │  Snapchat CAPI                         │
                           │  Pinterest CAPI                        │
                           │  X Conversion API                      │
                           └─────┬───┬───┬───┬───┬───┬───┬──────────┘
                                 │   │   │   │   │   │   │
                                 ▼   ▼   ▼   ▼   ▼   ▼   ▼
                               GA4 Meta GAds TT  LI  Sn  Pi  X
```

### Mapping events


| Event source  | Event name       | Google Ads       | TikTok             | LinkedIn       | Snap             | Pinterest    | X          |
| ------------- | ---------------- | ---------------- | ------------------ | -------------- | ---------------- | ------------ | ---------- |
| Browser       | `page_view`      | —                | `Pageview`         | —              | `PAGE_VIEW`      | `page_visit` | `PageView` |
| Browser       | `signup_start`   | —                | `SubmitForm`       | —              | —                | —            | —          |
| Browser       | `begin_checkout` | `begin_checkout` | `InitiateCheckout` | —              | `START_CHECKOUT` | `checkout`   | —          |
| Browser + API | `purchase`       | **purchase**     | `CompletePayment`  | **conversion** | `PURCHASE`       | `checkout`   | `Purchase` |


### Deduplication

- Meme `event_id` partage entre browser et API pour chaque conversion
- Chaque tag de plateforme recoit `event_id` = `transaction_id` (Stripe session ID)
- Les plateformes deduplicent nativement quand un meme `event_id` arrive via browser ET server

### Routing (triggers)

- **Phase initiale** : tous les tags sur le trigger "All Events" existant
- **Phase avancee** : triggers conditionnels par `event_name` pour chaque tag
(ex: Google Ads Conversion ne recoit que `purchase`, pas `page_view`)

---

## 6. Strategie de deploiement

### Phase 1 — Google Ads (sGTM SEUL, aucun code)

**Justification** : `gclid` deja dans le payload. Google Ads est la plateforme
la plus utilisee. Zero modification code.


| Action                   | Detail                                                                |
| ------------------------ | --------------------------------------------------------------------- |
| 1. Conversion Linker     | Ajouter tag sGTM natif "Conversion Linker"                            |
| 2. Google Ads Conversion | Ajouter tag "Google Ads Conversion Tracking" avec Conversion ID/Label |
| 3. Trigger               | "All Events" filtre sur `event_name = purchase`                       |
| 4. Test                  | Mode preview sGTM + Google Ads conversion diagnostics                 |


**Prerequis** : compte Google Ads actif avec Conversion ID et Label.
**Complexite : FAIBLE** / **Temps : ~1h sGTM config**

### Phase 1 bis — CMP Consent (prerequis pour TOUS les tags ads)

**Justification** : `SaaSAnalytics.tsx` definit `ad_storage: 'denied'` et
`ad_personalization: 'denied'` par defaut. Sans consentement explicite, aucun
tag ads ne recevra de donnees.


| Action                | Detail                                                |
| --------------------- | ----------------------------------------------------- |
| 1. Choix CMP          | Cookiebot, Axeptio, Didomi, ou custom                 |
| 2. Integration client | Script CMP sur les pages funnel                       |
| 3. Consent Mode V2    | Mettre a jour les defaults selon le choix utilisateur |
| 4. Test               | Verifier que `ad_storage: granted` apres consentement |


**Complexite : MOYENNE** / **Temps : ~4h (choix + integration + test)**

### Phase 2 — LinkedIn (sGTM + enrichissement payload API)

**Justification** : KeyBuzz cible des vendeurs e-commerce (B2B). LinkedIn est
la plateforme B2B par excellence. Le match repose sur email hash (deja en DB).


| Action      | Detail                                                                     |
| ----------- | -------------------------------------------------------------------------- |
| 1. API      | Ajouter `sha256_email_address` et `sha256_phone_number` dans le payload MP |
| 2. Tag sGTM | Ajouter "LinkedIn CAPI" (template Addingwell)                              |
| 3. Trigger  | "All Events" filtre sur `event_name = purchase`                            |
| 4. Test     | Mode preview sGTM + LinkedIn Campaign Manager conversion diagnostics       |


**Prerequis** : compte LinkedIn Ads + access token API.
**Complexite : FAIBLE-MOYENNE** / **Temps : ~3h (1h API + 1h sGTM + 1h test)**

### Phase 3 — TikTok (client + API + sGTM)

**Justification** : audience B2C et media buyers. Necessite la capture de `ttclid`.


| Action       | Detail                                                           |
| ------------ | ---------------------------------------------------------------- |
| 1. Client    | Ajouter `ttclid` a `CLICK_ID_PARAMS` dans `attribution.ts` (L58) |
| 2. Interface | Ajouter `ttclid` a `AttributionContext`                          |
| 3. DB        | Ajouter colonne `ttclid TEXT` a `signup_attribution`             |
| 4. API       | Inclure `ttclid` dans le payload MP                              |
| 5. Tag sGTM  | Ajouter "TikTok Events API" (template Addingwell)                |
| 6. Test      | Mode preview sGTM + TikTok Events Manager diagnostics            |


**Prerequis** : compte TikTok Ads + access token + Pixel ID.
**Complexite : MOYENNE** / **Temps : ~5h (2h code + 1h DB + 1h sGTM + 1h test)**

### Phase 4 — Snap / Pinterest / X (client + API + sGTM)

**Justification** : plateformes secondaires. Meme pattern que TikTok.


| Action       | Detail                                                   |
| ------------ | -------------------------------------------------------- |
| 1. Client    | Ajouter `ScCid`, `epik`, `twclid` a `CLICK_ID_PARAMS`    |
| 2. Interface | Ajouter les 3 champs a `AttributionContext`              |
| 3. DB        | Ajouter 3 colonnes a `signup_attribution`                |
| 4. API       | Inclure dans le payload MP                               |
| 5. Tags sGTM | 3 tags (Snapchat CAPI, Pinterest CAPI, X Conversion API) |
| 6. Test      | Preview + diagnostics par plateforme                     |


**Prerequis** : comptes ads + tokens pour chaque plateforme.
**Complexite : MOYENNE** / **Temps : ~6h (pattern identique x3)**

---

## 7. Risques


| #   | Risque                                                                       | Impact                               | Mitigation                                                                                                  |
| --- | ---------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| R1  | **Double tracking** : browser + API envoient `purchase` a la meme plateforme | Conversions comptees en double       | Deduplication via `event_id` = `transaction_id` dans chaque tag                                             |
| R2  | **Mauvaise attribution** : event assigne au mauvais canal                    | ROAS faussee                         | Verifier que chaque click ID est correctement mappe dans le tag sGTM                                        |
| R3  | **Donnees manquantes** : click ID perdu (cookies supprimes, redirect OAuth)  | Match rate degrade                   | Email hash comme fallback ; `initAttribution` a deja une strategie first-touch avec backup localStorage     |
| R4  | **RGPD / Consent Mode**                                                      | Non-conformite legale                | `SaaSAnalytics.tsx` utilise deja Consent Mode v2. Ajouter un CMP pour gerer le consentement utilisateur     |
| R5  | **Mauvaise deduplication** : `event_id` different entre browser et API       | Conversions en double                | S'assurer que `transaction_id` Stripe est utilise partout comme `event_id`                                  |
| R6  | **Volume Addingwell** : tags supplementaires = requetes sortantes            | Cout augmente                        | Les requetes sortantes ne sont PAS facturees par Addingwell (seules les entrantes comptent) — risque faible |
| R7  | **Tokens / credentials** : chaque plateforme necessite un access token       | Securite                             | Stocker les tokens dans les variables built-in GTM (cryptees)                                               |
| R8  | **Consent Mode V2 : `ad_storage: denied`**                                   | Tags ads ne recoivent pas de donnees | **BLOQUEUR** — implementer un CMP avant d'activer les tags ads                                              |


### Risque critique R8 — Detail

Actuellement dans `src/components/tracking/SaaSAnalytics.tsx` (ligne 65-70) :

```javascript
window.gtag('consent', 'default', {
  analytics_storage: 'granted',
  ad_storage: 'denied',
  ad_user_data: 'denied',
  ad_personalization: 'denied',
});
```

**Consequence** : `ad_storage: denied` empeche le Conversion Linker de Google Ads
de lire/ecrire le cookie `_gcl_aw`. Les autres tags ads (TikTok, LinkedIn, etc.)
respectent egalement ce signal. Tant que le consentement n'est pas accorde via un
CMP, **aucun tag ads ne fonctionnera cote browser**.

**Le webhook API (server-side)** n'est PAS affecte par Consent Mode car il envoie
directement en Measurement Protocol. Cependant, les events browser (page_view,
begin_checkout) ne seront pas transmis aux plateformes ads sans consentement.

**Solutions** :

1. Implementer un CMP (Cookiebot, Axeptio, Didomi) qui met a jour les valeurs
  Consent Mode quand l'utilisateur accepte
2. Pour le SaaS B2B, considerer `ad_storage: granted` par defaut (risque RGPD
  plus faible car pas de donnees personnelles sensibles dans le funnel)
3. Alternative : ne compter que sur le webhook API server-side pour les conversions
  (bypass Consent Mode) et accepter de perdre les events funnel intermediaires

---

## 8. Roadmap


| Phase  | Plateforme  | Actions                                          | Complexite     | Code                    | sGTM | Prerequis                         |
| ------ | ----------- | ------------------------------------------------ | -------------- | ----------------------- | ---- | --------------------------------- |
| **P1** | Google Ads  | 2 tags sGTM (Conversion Linker + Ads Conversion) | Faible         | NON                     | OUI  | Compte Google Ads + Conversion ID |
| **P1** | CMP Consent | Implementer CMP pour `ad_storage: granted`       | Moyenne        | OUI (client)            | NON  | Choix CMP                         |
| **P2** | LinkedIn    | Email hash dans payload MP + tag sGTM            | Faible-Moyenne | OUI (API)               | OUI  | Compte LinkedIn Ads + Token       |
| **P3** | TikTok      | `ttclid` capture + DB + payload + tag sGTM       | Moyenne        | OUI (client + API + DB) | OUI  | Compte TikTok Ads + Token         |
| **P4** | Snapchat    | `ScCid` capture + tag sGTM                       | Moyenne        | OUI (client + API + DB) | OUI  | Compte Snap Ads + Token           |
| **P4** | Pinterest   | `epik` capture + tag sGTM                        | Moyenne        | OUI (client + API + DB) | OUI  | Compte Pinterest Ads + Token      |
| **P4** | X (Twitter) | `twclid` capture + tag sGTM                      | Moyenne        | OUI (client + API + DB) | OUI  | Compte X Ads + Token              |


**Ordre recommande** : P1 (Google Ads + CMP) → P2 (LinkedIn) → P3 (TikTok) → P4 (Snap/Pinterest/X)

### Estimation totale


| Phase                 | Temps estime                   |
| --------------------- | ------------------------------ |
| P1 — Google Ads       | ~1h (sGTM seul)                |
| P1 — CMP              | ~4h (client)                   |
| P2 — LinkedIn         | ~3h (API + sGTM)               |
| P3 — TikTok           | ~5h (client + API + DB + sGTM) |
| P4 — Snap/Pinterest/X | ~6h (pattern x3)               |
| **TOTAL**             | **~19h**                       |


---

## 9. Modifications code necessaires (resume)

### `src/lib/attribution.ts` (client)

**Ligne 58** — ajouter les click IDs :

```typescript
// AVANT
const CLICK_ID_PARAMS = ['gclid', 'fbclid'] as const;

// APRES (Phase 3-4)
const CLICK_ID_PARAMS = ['gclid', 'fbclid', 'ttclid', 'ScCid', 'epik', 'twclid'] as const;
```

**Lignes 18-41** — ajouter a l'interface `AttributionContext` :

```typescript
ttclid: string | null;
sc_click_id: string | null;
epik: string | null;
twclid: string | null;
```

### API `emitConversionWebhook` (sur le bastion)

**Phase 2+** — ajouter dans les params du payload MP :

```typescript
const crypto = require('crypto');
const sha256 = (s: string) => crypto.createHash('sha256').update(s.toLowerCase().trim()).digest('hex');

// Dans events[0].params :
sha256_email_address: userEmail ? sha256(userEmail) : null,
sha256_phone_number: userPhone ? sha256(userPhone.replace(/[^+\d]/g, '')) : null,
```

**Phase 3-4** — ajouter les click IDs :

```typescript
ttclid: attribution.ttclid || null,
sc_click_id: attribution.sc_click_id || null,
epik: attribution.epik || null,
twclid: attribution.twclid || null,
```

### DB `signup_attribution`

**Phase 3-4** :

```sql
ALTER TABLE signup_attribution
  ADD COLUMN IF NOT EXISTS ttclid TEXT,
  ADD COLUMN IF NOT EXISTS sc_click_id TEXT,
  ADD COLUMN IF NOT EXISTS epik TEXT,
  ADD COLUMN IF NOT EXISTS twclid TEXT;
```

---

## 10. Matrice de compatibilite sGTM


| Fonctionnalite       | GA4     | Meta            | Google Ads | TikTok       | LinkedIn     | Snapchat   | Pinterest    | X            |
| -------------------- | ------- | --------------- | ---------- | ------------ | ------------ | ---------- | ------------ | ------------ |
| Tag sGTM disponible  | ✓ natif | ✓ communautaire | ✓ natif    | ✓ Addingwell | ✓ Addingwell | ✓ officiel | ✓ Addingwell | ✓ Addingwell |
| Trigger "All Events" | ✓       | ✓               | ✓          | ✓            | ✓            | ✓          | ✓            | ✓            |
| Client GA4 Web       | ✓       | ✓               | ✓          | ✓            | ✓            | ✓          | ✓            | ✓            |
| Client GA4 MP        | ✓       | ✓               | ✓          | ✓            | ✓            | ✓          | ✓            | ✓            |
| Dedup native         | ✓       | ✓               | ✓          | ✓            | ✓            | ✓          | ✓            | ✓            |
| Consent Mode V2      | ✓       | ✓               | ✓          | ✓            | partiel      | partiel    | partiel      | partiel      |


---

## 11. Cout Addingwell


| Scenario            | Requetes entrantes/mois | Tags sortants            | Cout estime   |
| ------------------- | ----------------------- | ------------------------ | ------------- |
| Actuel (GA4 + Meta) | ~2M                     | 2                        | ~100 EUR/mois |
| +Google Ads         | idem                    | 3 (+1 Conversion Linker) | ~100 EUR/mois |
| +Tous (8 tags)      | idem                    | 9                        | ~100 EUR/mois |


**Note** : Addingwell facture uniquement les requetes **entrantes**. L'ajout de
tags sortants supplementaires n'augmente pas le cout tant que le volume de trafic
entrant reste identique.

---

**Aucune modification de code effectuee.**
**Aucun build ou deploy.**
**Aucune modification sGTM.**
**Analyse uniquement.**

STOP