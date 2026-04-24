# PH-TRACKING-SAAS-ARCHITECTURE-AND-PLAN-01

**Phase** : Architecture tracking SaaS
**Date** : 16 avril 2026
**Type** : Analyse + Plan (aucune modification)
**Scope** : `client.keybuzz.io` (SaaS) — connexion avec le tracking website existant

---

## Verdict : TRACKING SAAS ARCHITECTURE READY

---

## 1. DIAGNOSTIC — État actuel

### 1.1 Ce qui existe (Website — keybuzz.pro)


| Composant               | Statut     | Détail                                                        |
| ----------------------- | ---------- | ------------------------------------------------------------- |
| GA4                     | Actif PROD | ID `G-R3QQDYEBFG`, events custom, cross-domain configuré      |
| Meta Pixel              | Actif PROD | ID `1234164602194748`, events standard + custom               |
| UTM forwarding          | Actif PROD | `/pricing` → `client.keybuzz.io/register?plan=X&utm_*=Y`      |
| gclid/fbclid forwarding | Actif PROD | Capturés sur `/pricing`, ajoutés aux liens CTA                |
| Cross-domain GA4        | Configuré  | `linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }`   |
| Consent Mode v2         | Actif      | `analytics_storage: granted`, `ad_storage: denied` par défaut |


### 1.2 Ce qui existe (SaaS — client.keybuzz.io)


| Composant          | Statut     | Détail                                                                   |
| ------------------ | ---------- | ------------------------------------------------------------------------ |
| GA4                | **ABSENT** | Aucun script gtag.js, aucun composant Analytics                          |
| Meta Pixel         | **ABSENT** | Aucun script fbevents.js                                                 |
| UTM capture        | **ABSENT** | `/register` lit `plan` et `cycle` mais ignore `utm_`*, `gclid`, `fbclid` |
| UTM stockage       | **ABSENT** | Aucun sessionStorage/localStorage pour les UTM                           |
| Events conversion  | **ABSENT** | Aucun `signup_start`, `signup_complete`, `payment_success`               |
| Webhook conversion | **ABSENT** | Aucun mécanisme d'émission de données vers le Media Buyer                |
| Attribution DB     | **ABSENT** | Aucune table `user_attribution` ou colonne UTM                           |
| Stripe metadata    | **ABSENT** | `checkout-session` n'envoie pas d'UTM dans metadata Stripe               |


### 1.3 Ce qui fonctionne partiellement


| Composant                     | Statut  | Détail                                                                          |
| ----------------------------- | ------- | ------------------------------------------------------------------------------- |
| `sessionStorage` plan/cycle   | Partiel | `kb_signup_context` sauvegarde plan+cycle pour OAuth redirect, mais PAS les UTM |
| `/signup` → `/register` relay | Partiel | `searchParams.toString()` forward tous les params, UTM inclus si présents       |
| `/register` URL params        | Partiel | Lit `plan`, `cycle`, `step`, `cancelled`, `email`, `oauth` — PAS les UTM        |


### 1.4 Où les données sont perdues

```
keybuzz.pro/pricing?utm_source=meta&utm_campaign=launch
    ↓ CTA → utm_* transmis dans l'URL ✅
client.keybuzz.io/register?plan=pro&utm_source=meta&utm_campaign=launch
    ↓ PERTE 1 : utm_* dans l'URL mais jamais lus ❌
    ↓ PERTE 2 : OAuth Google redirect → perd TOUS les query params ❌
    ↓           (seuls plan/cycle sauvés via kb_signup_context)
    ↓ PERTE 3 : aucun event GA4/Meta émis sur /register ❌
POST /api/auth/create-signup
    ↓ PERTE 4 : payload ne contient PAS les UTM ❌
POST /api/billing/checkout-session
    ↓ PERTE 5 : metadata Stripe ne contient PAS les UTM ❌
Stripe Checkout → /register/success
    ↓ PERTE 6 : aucun event purchase/payment_success émis ❌
    ↓ PERTE 7 : aucun webhook conversion envoyé ❌
```

**Résultat** : le parcours Website → SaaS → Stripe est un trou noir pour le tracking. On perd 100% des données d'attribution au moment de la conversion.

---

## 2. ARCHITECTURE TRACKING SAAS

### 2.A Capture — UTM à l'arrivée

**Point d'entrée** : `/register` (= `/signup` redirige vers `/register`)

Paramètres à capturer depuis `searchParams` au mount :


| Paramètre      | Source    | Obligatoire   |
| -------------- | --------- | ------------- |
| `utm_source`   | URL query | Non           |
| `utm_medium`   | URL query | Non           |
| `utm_campaign` | URL query | Non           |
| `utm_term`     | URL query | Non           |
| `utm_content`  | URL query | Non           |
| `gclid`        | URL query | Non           |
| `fbclid`       | URL query | Non           |
| `plan`         | URL query | Non (déjà lu) |
| `cycle`        | URL query | Non (déjà lu) |


**Timing** : extraction immédiate dans le `useEffect` initial de `RegisterContent`, avant tout redirect ou changement de step.

### 2.B Stockage — Client-side + Backend

#### Client-side (sessionStorage)

Clé : `kb_signup_attribution`

```typescript
interface SignupAttribution {
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  utm_term: string | null;
  utm_content: string | null;
  gclid: string | null;
  fbclid: string | null;
  plan: string | null;
  cycle: string | null;
  landing_url: string;
  referrer: string;
  captured_at: string; // ISO timestamp
}
```

Pourquoi `sessionStorage` + backup `localStorage` :

- `sessionStorage` : scope naturel à l'onglet, meilleur pour le RGPD
- Backup `localStorage` avec clé `kb_signup_attribution_backup` : survit au refresh forcé
- Les deux sont nettoyés après `create-signup` réussi

Pourquoi PAS uniquement le state React :

- Le redirect OAuth Google (ou Azure) fait un full page reload
- Le redirect Stripe Checkout fait un full page reload
- `sessionStorage` survit aux deux, le state React non

#### Enrichissement de `kb_signup_context` existant

Le mécanisme `kb_signup_context` existant (plan+cycle pour OAuth) sera étendu pour inclure les UTM :

```typescript
sessionStorage.setItem('kb_signup_context', JSON.stringify({
  plan: selectedPlan,
  cycle: billingCycle,
  attribution: { utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid }
}));
```

#### Backend (DB)

Nouvelle table `signup_attribution` :

```sql
CREATE TABLE signup_attribution (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  user_email TEXT NOT NULL,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_term TEXT,
  utm_content TEXT,
  gclid TEXT,
  fbclid TEXT,
  plan TEXT,
  cycle TEXT,
  landing_url TEXT,
  referrer TEXT,
  stripe_session_id TEXT,
  conversion_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_signup_attribution_tenant ON signup_attribution(tenant_id);
CREATE INDEX idx_signup_attribution_created ON signup_attribution(created_at);
```

Pourquoi une table dédiée (pas des colonnes sur `tenants`) :

- Séparation des concerns (acquisition vs exploitation)
- Extensible (plusieurs inscriptions, A/B tests futurs)
- Requêtable indépendamment pour analytics
- Multi-tenant safe (chaque row a son `tenant_id`)

### 2.C Tracking events

#### Events à implémenter côté SaaS


| Event             | Déclencheur                                | GA4 Event         | Meta Pixel Event       | Paramètres                                   |
| ----------------- | ------------------------------------------ | ----------------- | ---------------------- | -------------------------------------------- |
| Signup Start      | Mount de `/register` avec plan sélectionné | `signup_start`    | `InitiateCheckout`     | plan, cycle, utm_source                      |
| Signup Step       | Changement d'étape dans /register          | `signup_step`     | —                      | step_name, step_number                       |
| Signup Complete   | Retour success de `create-signup`          | `signup_complete` | `CompleteRegistration` | plan, cycle, email (hashé), company_country  |
| Checkout Redirect | Redirect vers Stripe Checkout              | `begin_checkout`  | `InitiateCheckout`     | plan, cycle, value, currency                 |
| Payment Success   | `/register/success` — entitlement unlocked | `purchase`        | `Purchase`             | plan, cycle, value, currency, transaction_id |


#### Events à NE PAS implémenter côté SaaS (déjà sur le website)

- `view_pricing` — website uniquement
- `select_plan` — website uniquement (le SaaS reçoit le plan pré-sélectionné)
- `click_signup` / `Lead` — website uniquement

#### Page /register — points d'injection des events

```
Step: plan       → signup_start (si plan pré-sélectionné) ou select_plan (si choix sur /register)
Step: email      → signup_step(step_name='email', step_number=2)
Step: code       → signup_step(step_name='code', step_number=3)
Step: company    → signup_step(step_name='company', step_number=4)
Step: user       → signup_step(step_name='user', step_number=5)
Step: checkout   → begin_checkout (avant redirect Stripe)
```

#### Page /register/success — event de conversion finale

```
status === 'success' → purchase + Purchase
  Avec: plan, cycle, value (montant mensuel), currency (EUR), transaction_id (session_id)
```

### 2.D Liaison outils — GA4 + Meta Pixel

#### GA4 — même propriété


| Config          | Valeur                                                      |
| --------------- | ----------------------------------------------------------- |
| Measurement ID  | `G-R3QQDYEBFG` (identique au website)                       |
| Cross-domain    | `linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }` |
| Consent Mode v2 | Identique au website                                        |


Injection via variable d'environnement build-time :

- `NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG` (ajout au Dockerfile `--build-arg`)

#### Meta Pixel — même pixel ID


| Config            | Valeur                                                                  |
| ----------------- | ----------------------------------------------------------------------- |
| Pixel ID          | `1234164602194748` (identique au website)                               |
| Advanced Matching | `em` (email hashé SHA-256), `fn` (prénom), `ln` (nom), `ph` (téléphone) |


Injection via variable d'environnement build-time :

- `NEXT_PUBLIC_META_PIXEL_ID=1234164602194748` (ajout au Dockerfile `--build-arg`)

#### Composant SaaS Analytics

Nouveau composant `src/components/tracking/SaaSAnalytics.tsx` :

- Client component (`'use client'`)
- Chargé dans `app/layout.tsx` via `next/script` strategy `afterInteractive`
- N'injecte les scripts que sur les pages publiques (/register, /register/success, /pricing)
- Sur les pages protégées (inbox, dashboard, etc.) : PAS de tracking tiers (vie privée utilisateur)

```
Pages avec tracking GA4 + Meta Pixel :
  /register (toutes les étapes)
  /register/success
  /pricing (si accédé depuis le SaaS)
  /login (page_view uniquement)

Pages SANS tracking tiers :
  /inbox, /dashboard, /orders, /settings, /billing, /ai-journal, etc.
  → Ces pages sont l'espace de travail de l'utilisateur, PAS le funnel d'acquisition
```

### 2.E Server-side — Webhook conversion + CAPI ready

#### Architecture webhook

```
Stripe Webhook (checkout.session.completed)
    ↓
API Fastify: /billing/webhook handler
    ↓
Lire metadata Stripe (tenant_id, plan, cycle)
    ↓
Lire signup_attribution (utm_*, gclid, fbclid)
    ↓
Lire tenant + user data (email, name, company, country)
    ↓
Assembler payload conversion
    ↓
POST → CONVERSION_WEBHOOK_URL (env var)
    ↓
Marquer signup_attribution.conversion_sent_at
```

#### Payload webhook conversion

```json
{
  "event": "conversion.signup_completed",
  "timestamp": "2026-04-16T14:30:00Z",
  "event_id": "conv_<uuid>",
  "user": {
    "email_hash": "<sha256(email)>",
    "email": "jean@exemple.fr",
    "firstName": "Jean",
    "lastName": "Dupont",
    "phone": "+33612345678"
  },
  "company": {
    "name": "MaBoutique SAS",
    "country": "FR",
    "city": "Paris",
    "zipCode": "75001"
  },
  "subscription": {
    "plan": "pro",
    "cycle": "monthly",
    "amount": 297,
    "currency": "EUR",
    "trialDays": 14,
    "stripeSessionId": "cs_live_xxx"
  },
  "attribution": {
    "utm_source": "meta",
    "utm_medium": "cpc",
    "utm_campaign": "launch_q2",
    "utm_term": null,
    "utm_content": "video_a",
    "gclid": null,
    "fbclid": "AbCdEfGh12345",
    "landing_url": "https://client.keybuzz.io/register?plan=pro&...",
    "referrer": "https://www.keybuzz.pro/pricing"
  }
}
```

#### Facebook CAPI ready (Addingwell)

Le webhook est conçu pour être consommé par :

- **Addingwell** (server-side tracking proxy) — mode recommandé
- **Facebook Conversions API** directement (via Make/Zapier ou custom)
- **Google Ads Offline Conversions** (via import CSV ou API)

Configuration via env vars API :

```
CONVERSION_WEBHOOK_URL=https://...    # URL fournie par le Media Buyer
CONVERSION_WEBHOOK_SECRET=xxx         # HMAC signature pour sécuriser
```

Le webhook inclut un header `X-Webhook-Signature: sha256=<hmac>` pour que le destinataire puisse vérifier l'authenticité.

---

## 3. FLOW COMPLET

### 3.1 Schéma global

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WEBSITE (keybuzz.pro)                             │
│                                                                     │
│   Pub Meta/Google/TikTok                                            │
│     ↓                                                               │
│   keybuzz.pro/?utm_source=meta&utm_campaign=launch                  │
│     ↓  GA4: page_view | Meta: PageView                              │
│   keybuzz.pro/pricing                                               │
│     ↓  GA4: view_pricing | Meta: ViewContent                        │
│   Clic CTA "Commencer avec Pro"                                     │
│     ↓  GA4: select_plan, click_signup | Meta: InitiateCheckout, Lead│
│     ↓                                                               │
│   ══ SORTIE → UTM + gclid + fbclid + plan + cycle dans l'URL ════  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    SAAS (client.keybuzz.io)                          │
│                                                                     │
│   /register?plan=pro&cycle=monthly&utm_source=meta&utm_campaign=... │
│     ↓  [A] CAPTURE : lire tous les UTM + gclid + fbclid            │
│     ↓  [B] STOCKAGE : sessionStorage + localStorage backup         │
│     ↓  [C] EVENT : GA4: signup_start | Meta: InitiateCheckout      │
│                                                                     │
│   Étapes inscription (email → OTP → company → user)                 │
│     ↓  [C] EVENTS : GA4: signup_step(step_name, step_number)       │
│                                                                     │
│   POST /api/auth/create-signup                                      │
│     ↓  [D] UTM inclus dans le body (attribution object)            │
│     ↓  [E] Backend stocke en table signup_attribution               │
│     ↓  [C] EVENT : GA4: signup_complete | Meta: CompleteRegistration│
│                                                                     │
│   POST /api/billing/checkout-session                                │
│     ↓  [F] UTM dans metadata Stripe (utm_source, utm_campaign...)  │
│     ↓  [C] EVENT : GA4: begin_checkout                             │
│     ↓  Redirect → Stripe Checkout                                   │
│                                                                     │
│   /register/success?session_id=cs_xxx                               │
│     ↓  Polling entitlement...                                       │
│     ↓  status === 'success'                                         │
│     ↓  [C] EVENT : GA4: purchase | Meta: Purchase                  │
│     ↓  (value=montant, currency=EUR, transaction_id=session_id)    │
│                                                                     │
│   ═══════════════ CONVERSION FINALE (client-side) ═════════════════ │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    SERVER-SIDE (API Fastify)                         │
│                                                                     │
│   Stripe Webhook: checkout.session.completed                        │
│     ↓  Lire metadata (tenant_id, utm_*)                            │
│     ↓  Enrichir depuis signup_attribution + users + tenants        │
│     ↓  POST → CONVERSION_WEBHOOK_URL                                │
│     ↓  (user + company + subscription + attribution)               │
│                                                                     │
│   ═══════════════ CONVERSION FINALE (server-side) ═════════════════ │
│     ↓                                                               │
│   Facebook CAPI / Google Ads / Addingwell / CRM Media Buyer         │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Flow détaillé par scénario

#### Scénario A : Visiteur organique (pas de pub)

```
keybuzz.pro → /pricing → CTA → client.keybuzz.io/register?plan=pro&cycle=monthly
  → utm_* = null, gclid = null, fbclid = null
  → Events GA4/Meta émis avec plan/cycle mais sans attribution
  → Webhook conversion émis sans attribution (attribution.utm_source = null)
  → Le Media Buyer voit : conversion organique, pas d'attribution campagne
```

#### Scénario B : Visiteur pub Meta (CPC)

```
Meta Ad → keybuzz.pro/?utm_source=meta&utm_medium=cpc&utm_campaign=launch&fbclid=ABC
  → /pricing → CTA
  → client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=meta&...&fbclid=ABC
  → CAPTURE : utm_source=meta, fbclid=ABC stockés en sessionStorage
  → Inscription + Stripe → Events purchase avec attribution
  → Webhook : attribution.utm_source=meta, attribution.fbclid=ABC
  → Media Buyer envoie vers Facebook CAPI avec fbclid → Meta Ads attribue la conversion
```

#### Scénario C : Visiteur pub Google (CPC)

```
Google Ad → keybuzz.pro/?gclid=XYZ
  → /pricing → CTA
  → client.keybuzz.io/register?plan=starter&gclid=XYZ
  → CAPTURE : gclid=XYZ
  → Webhook : attribution.gclid=XYZ
  → Media Buyer importe la conversion dans Google Ads via gclid
```

#### Scénario D : Visiteur direct (pas de website)

```
Directement → client.keybuzz.io/signup ou /register
  → Pas d'UTM, pas de gclid/fbclid
  → Events signup/purchase émis (pour comptage total)
  → Webhook émis sans attribution
```

#### Scénario E : Inscription OAuth Google (redirect)

```
/register?plan=pro&utm_source=meta&fbclid=ABC
  → CAPTURE immédiate → sessionStorage
  → Clic "Continuer avec Google" → sessionStorage.setItem('kb_signup_context', {..., attribution: {...}})
  → Redirect Google OAuth → full page reload → callback /register?plan=pro&oauth=google
  → UTM PAS dans l'URL de retour, MAIS récupérés depuis kb_signup_context
  → Flux continue normalement
```

---

## 4. RISQUES IDENTIFIÉS

### R1 — Perte UTM sur OAuth redirect (CRITIQUE)

**Risque** : Quand l'utilisateur choisit Google OAuth, le redirect Google supprime tous les query params. Au retour, le callback est `/register?plan=pro&step=company&oauth=google` — les UTM ont disparu.

**Mitigation** : Le mécanisme `kb_signup_context` existant est étendu pour inclure les UTM. Au mount de `/register`, les UTM sont d'abord capturés depuis l'URL, puis si absents, restaurés depuis `kb_signup_context` (sessionStorage).

**Séquence** :

1. Mount initial : UTM dans l'URL → capturés + stockés en sessionStorage
2. Clic Google : UTM ajoutés à `kb_signup_context`
3. Retour OAuth : UTM absents de l'URL → restaurés depuis `kb_signup_context`

### R2 — Multi-tenant leakage (CRITIQUE)

**Risque** : Les données d'attribution d'un tenant pourraient être visibles par un autre.

**Mitigation** :

- Table `signup_attribution` a un `tenant_id` obligatoire
- Le webhook ne contient que les données du tenant concerné
- Aucune API de lecture des attributions n'est exposée au client (admin only)
- Les events GA4/Meta côté client ne contiennent PAS de `tenant_id` (seul GA4/Meta reçoivent des events anonymisés)

### R3 — Double tracking (MODÉRÉ)

**Risque** : Le même event `InitiateCheckout` pourrait être émis deux fois : une fois sur le website (clic CTA) et une fois sur le SaaS (mount /register).

**Mitigation** :

- Le website émet `InitiateCheckout` + `Lead` au clic CTA (intent)
- Le SaaS émet `signup_start` (custom event GA4, pas `InitiateCheckout`) pour le signup
- Le SaaS émet `InitiateCheckout` Meta uniquement à `/register` avec un paramètre `content_category: 'saas_signup'` pour distinguer
- Le `purchase` / `Purchase` n'est émis QUE côté SaaS (jamais sur le website)
- Event dedup : `event_id` unique pour chaque event Meta (basé sur `sessionId + timestamp`)

### R4 — Race condition onboarding (FAIBLE)

**Risque** : L'utilisateur pourrait fermer l'onglet entre `create-signup` et le redirect Stripe, perdant les UTM avant qu'ils ne soient envoyés à Stripe.

**Mitigation** :

- Les UTM sont stockés en DB dès `create-signup` (AVANT le redirect Stripe)
- Le webhook de conversion lit depuis la DB, pas depuis metadata Stripe
- Les metadata Stripe sont un bonus (pour le dashboard Stripe), pas la source de vérité

### R5 — Stripe timing (FAIBLE)

**Risque** : Le webhook Stripe `checkout.session.completed` arrive parfois avant que le client ne charge `/register/success`.

**Mitigation** :

- Les events client-side (`purchase`) et le webhook server-side sont indépendants
- Le webhook server-side est la source de vérité pour l'attribution (pas le client-side `purchase`)
- Si le client-side `purchase` rate, le webhook compense côté CAPI

### R6 — Consent Mode & RGPD (MODÉRÉ)

**Risque** : Charger GA4/Meta Pixel sur le SaaS pourrait poser des problèmes RGPD.

**Mitigation** :

- Consent Mode v2 actif : `ad_storage: denied` par défaut
- GA4/Meta chargés UNIQUEMENT sur les pages du funnel (/register, /register/success), PAS sur l'espace de travail
- L'utilisateur n'est pas un "visiteur" quand il est dans son inbox — le tracking s'arrête
- Le webhook server-side ne dépend PAS du consent client (Stripe event = 1st party data)

### R7 — sessionStorage limité à un onglet (FAIBLE)

**Risque** : Si l'utilisateur ouvre `/register` dans un nouvel onglet, les UTM du premier onglet ne sont pas transférés.

**Mitigation** :

- Backup en `localStorage` (clé `kb_signup_attribution_backup`)
- TTL de 30 minutes sur le backup localStorage (nettoyé automatiquement)
- Cas d'usage rare : l'utilisateur arrive normalement via un seul clic CTA

---

## 5. PLAN D'IMPLÉMENTATION

### Vue d'ensemble


| Phase     | Scope                                | Risque      | Prérequis |
| --------- | ------------------------------------ | ----------- | --------- |
| **PH-T1** | Capture UTM client-side              | Très faible | Aucun     |
| **PH-T2** | Stockage DB + payload create-signup  | Faible      | PH-T1     |
| **PH-T3** | GA4 + Meta Pixel + events SaaS       | Modéré      | PH-T1     |
| **PH-T4** | Stripe metadata + webhook conversion | Modéré      | PH-T2     |
| **PH-T5** | Server-side CAPI (Addingwell ready)  | Faible      | PH-T4     |


### PH-T1 — Capture UTM client-side

**Objectif** : Lire et stocker les UTM à l'arrivée sur `/register`

**Fichiers modifiés** :

- `app/register/page.tsx` — ajout extraction UTM dans `RegisterContent`

**Changements** :

1. Extraire `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`, `gclid`, `fbclid` depuis `searchParams`
2. Stocker dans `sessionStorage` clé `kb_signup_attribution`
3. Backup dans `localStorage` clé `kb_signup_attribution_backup` (TTL 30min)
4. Étendre `kb_signup_context` (OAuth) pour inclure les UTM
5. Au mount : si UTM absents de l'URL, tenter restore depuis `kb_signup_context`

**Validation** :

- Naviguer vers `/register?plan=pro&utm_source=test&gclid=abc`
- Vérifier `sessionStorage.getItem('kb_signup_attribution')` dans DevTools
- Vérifier persistence après OAuth redirect simulé

**Rollback** : Revert du fichier `register/page.tsx` — aucun impact fonctionnel

### PH-T2 — Stockage DB + payload create-signup

**Objectif** : Persister les UTM en base de données lors de la création du tenant

**Fichiers modifiés** :

- `app/register/page.tsx` — inclure attribution dans body `create-signup`
- `app/api/auth/create-signup/route.ts` — forward attribution dans le payload BFF
- **API (keybuzz-api)** : `src/modules/tenants/routes.ts` (ou équivalent create-signup handler) — INSERT dans `signup_attribution`

**Changements** :

1. Ajouter l'objet `attribution` dans le body de `handleUserSubmit` → `create-signup`
2. Le BFF forward tel quel vers l'API backend
3. L'API crée un row dans `signup_attribution` après création du tenant
4. Migration SQL : `CREATE TABLE signup_attribution` (voir section 2.B)

**Validation** :

- Inscription complète en DEV avec UTM dans l'URL
- Vérifier en base : `SELECT * FROM signup_attribution WHERE tenant_id = 'xxx'`
- Vérifier que les UTM sont bien peuplés

**Rollback** : DROP TABLE `signup_attribution` + revert code — le flux d'inscription ne dépend pas de cette table

### PH-T3 — GA4 + Meta Pixel + events SaaS

**Objectif** : Installer GA4/Meta sur le SaaS et émettre les events de conversion

**Fichiers créés** :

- `src/lib/tracking.ts` — librairie tracking typée (GA4 + Meta)
- `src/components/tracking/SaaSAnalytics.tsx` — composant client (charge gtag.js + fbevents.js)

**Fichiers modifiés** :

- `app/layout.tsx` — import SaaSAnalytics
- `app/register/page.tsx` — appels events (signup_start, signup_step, signup_complete, begin_checkout)
- `app/register/success/page.tsx` — event purchase/Purchase
- `Dockerfile` — build args `NEXT_PUBLIC_GA_ID`, `NEXT_PUBLIC_META_PIXEL_ID`

**Changements** :

1. Créer `src/lib/tracking.ts` — helpers typés : `trackGA4(event, params)`, `trackMeta(event, params)`
2. Créer `SaaSAnalytics.tsx` — charge gtag.js/fbevents.js uniquement sur les pages funnel
3. Ajouter dans `layout.tsx` le composant SaaSAnalytics
4. Injecter les appels tracking dans les transitions de step de `/register`
5. Injecter `purchase` / `Purchase` dans `/register/success` quand `status === 'success'`
6. Ajouter build args au Dockerfile

**Validation** :

- GA4 Debug View (temps réel) : vérifier events `signup_start`, `signup_complete`, `purchase`
- Meta Pixel Helper (extension Chrome) : vérifier events `InitiateCheckout`, `CompleteRegistration`, `Purchase`
- Vérifier que les pages protégées (inbox, dashboard) ne chargent PAS gtag/fbevents

**Rollback** : Supprimer composant + revert layout.tsx — aucun impact fonctionnel

### PH-T4 — Stripe metadata + webhook conversion

**Objectif** : Enrichir la session Stripe avec les UTM et émettre un webhook à la conversion

**Fichiers modifiés** :

- `app/register/page.tsx` — inclure UTM dans body `checkout-session`
- `app/api/billing/checkout-session/route.ts` — forward metadata
- **API (keybuzz-api)** : handler `checkout-session` — ajouter `metadata` à la session Stripe
- **API (keybuzz-api)** : handler `billing/webhook` — sur `checkout.session.completed`, émettre webhook

**Changements** :

1. Lire les UTM depuis `sessionStorage` au moment du redirect checkout
2. Les inclure dans le body de `checkout-session` comme `metadata`
3. L'API les passe dans `stripe.checkout.sessions.create({ metadata: { utm_source, ... } })`
4. Dans le handler webhook Stripe :
  - Lire `metadata` de la session
  - Enrichir depuis `signup_attribution` + `users` + `tenants`
  - POST vers `CONVERSION_WEBHOOK_URL` si configuré
  - Marquer `signup_attribution.conversion_sent_at`

**Validation** :

- Créer un tenant de test avec UTM
- Vérifier dans le dashboard Stripe : metadata visible sur la session
- Vérifier le webhook reçu (via webhook.site ou RequestBin)

**Rollback** : Env var `CONVERSION_WEBHOOK_URL` non définie → webhook non émis, aucun impact

### PH-T5 — Server-side CAPI (Addingwell ready)

**Objectif** : Préparer l'intégration server-side pour Facebook CAPI via Addingwell

**Fichiers créés/modifiés** :

- **API (keybuzz-api)** : `src/modules/billing/conversionWebhook.ts` — module dédié

**Changements** :

1. Module autonome `conversionWebhook.ts` :
  - Accepte un payload structuré (user + company + subscription + attribution)
  - Signe le payload avec HMAC (header `X-Webhook-Signature`)
  - Retry avec exponential backoff (max 3 tentatives)
  - Log succès/échec dans les logs API
2. Configuration via env vars :
  - `CONVERSION_WEBHOOK_URL` — URL de destination
  - `CONVERSION_WEBHOOK_SECRET` — clé HMAC
  - `CONVERSION_WEBHOOK_ENABLED` — toggle (default: false)
3. Intégration GA4 Measurement Protocol (optionnel, futur) :
  - Envoi server-side du event `purchase` via Measurement Protocol GA4
  - Nécessite `api_secret` GA4 (à configurer plus tard)

**Validation** :

- Webhook test vers endpoint de debug (webhook.site)
- Vérifier signature HMAC
- Vérifier payload complet

**Rollback** : `CONVERSION_WEBHOOK_ENABLED=false` → module inactif

---

## 6. PROMPT CE FINAL — Pour implémentation

```
Prompt CE — PH-T1-CAPTURE-UTM-CLIENT-SIDE-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz v3
Phase : PH-T1-CAPTURE-UTM-CLIENT-SIDE-01
Environnement : DEV uniquement
Type : modification client (Next.js)

---

OBJECTIF :
Capturer les paramètres UTM, gclid et fbclid à l'arrivée sur /register
et les stocker en sessionStorage + localStorage backup.

RÈGLES ABSOLUES :
- DEV uniquement — AUCUN build PROD
- GitOps strict — commit atomique
- ZERO impact sur le flux d'inscription existant
- ZERO hardcode d'UTM ou d'IDs tracking
- Multi-tenant safe
- Rollback = revert commit

FICHIERS À MODIFIER :
1. app/register/page.tsx

CHANGEMENTS PRÉCIS :

1. Dans RegisterContent(), après la lecture de urlPlan/urlCycle (ligne 59-65) :
   - Lire utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid depuis searchParams
   - Stocker dans un state local `attribution` et dans sessionStorage clé `kb_signup_attribution`
   - Backup dans localStorage clé `kb_signup_attribution_backup` avec TTL 30 minutes

2. Dans le bloc de restauration OAuth (ligne 70-80) :
   - Étendre kb_signup_context pour inclure les UTM
   - Au restore, récupérer aussi les UTM depuis le contexte sauvegardé

3. Dans handleGoogleAuth (ligne 161-169) :
   - Ajouter les UTM dans le payload sessionStorage kb_signup_context

INTERFACE TypeScript :
interface SignupAttribution {
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  utm_term: string | null;
  utm_content: string | null;
  gclid: string | null;
  fbclid: string | null;
  landing_url: string;
  referrer: string;
  captured_at: string;
}

VALIDATION :
- Naviguer vers /register?plan=pro&utm_source=test&gclid=abc
- Ouvrir DevTools → Application → Session Storage
- Vérifier présence de kb_signup_attribution avec les bonnes valeurs
- Simuler OAuth : stocker en kb_signup_context, effacer sessionStorage, recharger avec plan seul
- Vérifier que les UTM sont restaurés depuis kb_signup_context

CONTRAINTES :
- NE PAS modifier le flux plan/email/code/company/user/checkout
- NE PAS modifier le CSS ou le layout
- NE PAS ajouter de dépendances npm
- NE PAS toucher les autres pages (inbox, dashboard, etc.)

BUILD & DEPLOY (quand prêt) :
- Build DEV sur bastion : docker build --no-cache --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io -t ghcr.io/keybuzzio/keybuzz-client:v<VERSION>-tracking-t1-dev .
- Deploy DEV : kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v<VERSION>-tracking-t1-dev -n keybuzz-client-dev

VERDICT ATTENDU : UTM CAPTURE OPERATIONAL — SESSION STORAGE OK — OAUTH RESILIENT

STOP
```

```
Prompt CE — PH-T2-UTM-STORAGE-DB-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz v3
Phase : PH-T2-UTM-STORAGE-DB-01
Environnement : DEV uniquement
Type : modification client + API

---

OBJECTIF :
Persister les UTM en base de données lors de la création du tenant.

PRÉREQUIS :
- PH-T1 terminé et validé (UTM capturés en sessionStorage)

RÈGLES ABSOLUES :
- DEV uniquement — AUCUN build PROD
- GitOps strict — commit atomique par service
- ZERO impact sur le flux d'inscription existant
- ZERO modification des tables existantes (nouvelle table uniquement)
- Multi-tenant safe (tenant_id obligatoire)
- Rollback = DROP TABLE + revert code

CHANGEMENTS :

1. Migration SQL (sur bastion, via kubectl exec) :
   CREATE TABLE signup_attribution (...) — voir PH-TRACKING-SAAS-ARCHITECTURE doc section 2.B

2. Client (app/register/page.tsx) :
   Dans handleUserSubmit, lire sessionStorage kb_signup_attribution et inclure dans le body de create-signup
   Clé: "attribution" dans le JSON body

3. BFF (app/api/auth/create-signup/route.ts) :
   Forward tel quel (déjà le cas avec body pass-through)

4. API (keybuzz-api, src/modules/tenants/ ou tenant-context) :
   Après INSERT dans tenants + user_tenants, INSERT dans signup_attribution

VALIDATION :
- Inscription DEV complète avec ?utm_source=test&utm_campaign=validation
- SELECT * FROM signup_attribution WHERE tenant_id = '<new_tenant>'
- Vérifier utm_source = 'test', utm_campaign = 'validation'
- Inscription SANS UTM : vérifier row créé avec utm_* = null

VERDICT ATTENDU : UTM PERSISTED IN DB — CREATE-SIGNUP ENRICHED

STOP
```

```
Prompt CE — PH-T3-GA4-META-EVENTS-SAAS-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz v3
Phase : PH-T3-GA4-META-EVENTS-SAAS-01
Environnement : DEV uniquement
Type : modification client (Next.js)

---

OBJECTIF :
Installer GA4 + Meta Pixel sur le SaaS et émettre les events de conversion
sur les pages du funnel d'inscription uniquement.

PRÉREQUIS :
- PH-T1 terminé et validé

RÈGLES ABSOLUES :
- DEV uniquement — AUCUN build PROD
- Mêmes IDs que le website (GA4: G-R3QQDYEBFG, Meta: 1234164602194748)
- IDs via NEXT_PUBLIC_GA_ID et NEXT_PUBLIC_META_PIXEL_ID (build args)
- ZERO tracking sur les pages protégées (inbox, dashboard, orders, settings, etc.)
- Cross-domain GA4 identique au website
- Consent Mode v2 identique au website
- ZERO impact onboarding

FICHIERS À CRÉER :
- src/lib/tracking.ts
- src/components/tracking/SaaSAnalytics.tsx

FICHIERS À MODIFIER :
- app/layout.tsx
- app/register/page.tsx
- app/register/success/page.tsx
- Dockerfile (build args)

EVENTS À ÉMETTRE :
- signup_start (step plan avec plan sélectionné)
- signup_step (chaque changement d'étape)
- signup_complete (create-signup OK)
- begin_checkout (redirect Stripe)
- purchase (entitlement unlocked sur /register/success)

VALIDATION :
- GA4 Debug View / Realtime : events visibles
- Meta Pixel Helper : events visibles
- Pages protégées : AUCUN script gtag/fbevents chargé

VERDICT ATTENDU : GA4 + META PIXEL OPERATIONAL ON SAAS FUNNEL

STOP
```

```
Prompt CE — PH-T4-STRIPE-METADATA-WEBHOOK-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz v3
Phase : PH-T4-STRIPE-METADATA-WEBHOOK-01
Environnement : DEV uniquement
Type : modification client + API

---

OBJECTIF :
Enrichir la session Stripe avec les UTM en metadata et émettre un webhook
de conversion server-side au checkout.session.completed.

PRÉREQUIS :
- PH-T2 terminé et validé (UTM en DB)

RÈGLES ABSOLUES :
- DEV uniquement — AUCUN build PROD
- NE PAS modifier la logique Stripe existante (ajout de metadata uniquement)
- NE PAS modifier les prix, plans, ou checkout flow
- Webhook désactivé par défaut (CONVERSION_WEBHOOK_ENABLED=false)
- Signature HMAC obligatoire sur le webhook
- Multi-tenant safe

CHANGEMENTS :
1. Client : inclure UTM dans body checkout-session
2. API : ajouter metadata à stripe.checkout.sessions.create()
3. API : dans le handler webhook Stripe, si checkout.session.completed :
   - Lire metadata
   - Enrichir depuis signup_attribution
   - POST vers CONVERSION_WEBHOOK_URL si activé
   - Marquer conversion_sent_at

VALIDATION :
- Inscription test avec UTM
- Vérifier metadata dans Stripe Dashboard
- Vérifier webhook reçu (webhook.site)
- Vérifier conversion_sent_at en DB

VERDICT ATTENDU : STRIPE METADATA ENRICHED — CONVERSION WEBHOOK OPERATIONAL

STOP
```

```
Prompt CE — PH-T5-SERVER-SIDE-CAPI-READY-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz v3
Phase : PH-T5-SERVER-SIDE-CAPI-READY-01
Environnement : DEV uniquement
Type : modification API

---

OBJECTIF :
Finaliser le module webhook conversion avec retry, signature HMAC,
et préparer l'intégration Addingwell/CAPI.

PRÉREQUIS :
- PH-T4 terminé et validé

RÈGLES ABSOLUES :
- DEV uniquement
- Module autonome, découplé du billing
- Toggle env var
- Retry max 3 avec exponential backoff
- Logs structurés

CHANGEMENTS :
1. Créer src/modules/billing/conversionWebhook.ts
2. Retry logic avec exponential backoff
3. Signature HMAC-SHA256
4. Documentation inline des champs pour le Media Buyer

VALIDATION :
- Test unitaire du module (payload → POST)
- Vérification signature HMAC côté récepteur
- Test retry (simuler 503 puis 200)

VERDICT ATTENDU : CONVERSION WEBHOOK MODULE READY — CAPI COMPATIBLE

STOP
```

---

## 7. STRATÉGIE DE VALIDATION

### 7.1 Tests DEV — Par phase


| Phase | Test                           | Outil                                | Critère de succès                                                      |
| ----- | ------------------------------ | ------------------------------------ | ---------------------------------------------------------------------- |
| PH-T1 | UTM capturés en sessionStorage | DevTools Chrome                      | Clé `kb_signup_attribution` présente avec bonnes valeurs               |
| PH-T1 | UTM survivent à OAuth          | Simulation manuelle                  | Après redirect Google, UTM restaurés depuis `kb_signup_context`        |
| PH-T2 | UTM persistés en DB            | `kubectl exec` SQL                   | Row dans `signup_attribution` avec UTM corrects                        |
| PH-T2 | Inscription sans UTM           | Test manuel                          | Row créé avec `utm_*` = null (pas d'erreur)                            |
| PH-T3 | GA4 events visibles            | GA4 DebugView (Realtime)             | Events `signup_start`, `signup_complete`, `purchase` visibles          |
| PH-T3 | Meta events visibles           | Meta Pixel Helper (extension Chrome) | Events `InitiateCheckout`, `CompleteRegistration`, `Purchase` visibles |
| PH-T3 | Pas de tracking hors funnel    | DevTools Network                     | Aucune requête gtag/fbevents sur /inbox, /dashboard, etc.              |
| PH-T4 | Metadata Stripe                | Stripe Dashboard (DEV)               | `utm_source`, `utm_campaign` visibles dans metadata session            |
| PH-T4 | Webhook émis                   | webhook.site / RequestBin            | Payload JSON complet reçu avec user + company + attribution            |
| PH-T5 | Webhook retry                  | Simulation erreur                    | 3 tentatives avec backoff, puis abandon                                |
| PH-T5 | Signature HMAC                 | Vérification manuelle                | Signature valide sur le payload                                        |


### 7.2 Validation GA4 — Checklist

1. Ouvrir GA4 Admin → DebugView (ou Realtime)
2. Naviguer vers `client-dev.keybuzz.io/register?plan=pro&utm_source=test_ga4`
3. Vérifier : event `signup_start` avec paramètre `plan=pro`
4. Compléter l'inscription
5. Vérifier : event `signup_complete` avec paramètre `plan=pro`
6. Compléter le paiement (Stripe test)
7. Vérifier : event `purchase` avec paramètres `value`, `currency`, `transaction_id`
8. Naviguer vers `/inbox`
9. Vérifier : AUCUN event émis (pas de tracking hors funnel)

### 7.3 Validation Meta Pixel — Checklist

1. Installer l'extension "Meta Pixel Helper" dans Chrome
2. Naviguer vers `client-dev.keybuzz.io/register?plan=pro&utm_source=test_meta`
3. Vérifier : `InitiateCheckout` déclenché
4. Compléter l'inscription
5. Vérifier : `CompleteRegistration` déclenché
6. Compléter le paiement
7. Vérifier : `Purchase` déclenché avec `value` et `currency`
8. Vérifier Advanced Matching : email hashé présent dans le payload

### 7.4 Validation conversion réelle — End-to-end

1. Créer une campagne Meta Ads de test (budget 1€, audience restreinte)
2. URL de destination : `keybuzz.pro/pricing?utm_source=meta&utm_medium=cpc&utm_campaign=test_e2e`
3. Cliquer sur la pub → arriver sur /pricing → CTA → /register
4. Compléter l'inscription + paiement Stripe (mode test)
5. Vérifier :
  - GA4 : event `purchase` visible dans Realtime avec `utm_source=meta`
  - Meta Events Manager : event `Purchase` visible dans l'outil de test
  - Webhook : payload reçu sur l'endpoint de test avec attribution complète
  - DB : row dans `signup_attribution` avec `utm_source=meta`, `utm_campaign=test_e2e`
  - Stripe : metadata de la session contient `utm_source=meta`

### 7.5 Cross-domain GA4 — Validation spécifique

1. Naviguer depuis `keybuzz.pro/pricing` vers `client-dev.keybuzz.io/register`
2. Vérifier dans la barre d'adresse : paramètre `_gl=` ajouté par le linker GA4
3. Dans GA4 Realtime : vérifier que la session est la MÊME (pas de nouvelle session)
4. Le `page_view` de `/register` doit apparaître dans la même session que le `click_signup` de `/pricing`

---

## 8. MATRICE DE RESPONSABILITÉ FINALE


| Responsabilité                                               | Website (keybuzz.pro) | SaaS (client.keybuzz.io) |
| ------------------------------------------------------------ | --------------------- | ------------------------ |
| GA4 installé                                                 | Fait                  | **PH-T3**                |
| Meta Pixel installé                                          | Fait                  | **PH-T3**                |
| Events acquisition (view_pricing, select_plan, click_signup) | Fait                  | —                        |
| Events conversion (signup_start, signup_complete, purchase)  | —                     | **PH-T3**                |
| UTM forwarding vers SaaS                                     | Fait                  | —                        |
| UTM capture à l'arrivée                                      | —                     | **PH-T1**                |
| UTM stockage client-side                                     | —                     | **PH-T1**                |
| UTM stockage DB                                              | —                     | **PH-T2**                |
| UTM dans metadata Stripe                                     | —                     | **PH-T4**                |
| Webhook conversion (CAPI)                                    | —                     | **PH-T4** + **PH-T5**    |
| Cross-domain GA4 (code)                                      | Fait                  | **PH-T3**                |
| Consent Mode v2                                              | Fait                  | **PH-T3**                |


---

## 9. DÉPENDANCES ET SÉQUENCE

```
PH-T1 (Capture UTM)
  ├─→ PH-T2 (Stockage DB) ─→ PH-T4 (Stripe + Webhook) ─→ PH-T5 (CAPI)
  └─→ PH-T3 (GA4 + Meta + Events)
```

PH-T1 est le prérequis commun. PH-T2→T4→T5 et PH-T3 peuvent être menés en parallèle après PH-T1.

**Estimation** :


| Phase | Effort estimé | Risque déploiement        |
| ----- | ------------- | ------------------------- |
| PH-T1 | 30 min        | Quasi nul                 |
| PH-T2 | 1h            | Faible (migration SQL)    |
| PH-T3 | 1h30          | Modéré (scripts tiers)    |
| PH-T4 | 2h            | Modéré (webhook + Stripe) |
| PH-T5 | 1h            | Faible (module isolé)     |


---

## 10. DOCUMENTS ASSOCIÉS


| Document                                     | Contenu                                            |
| -------------------------------------------- | -------------------------------------------------- |
| `TRACKING-URL-MAP-WEBSITE-VS-SAAS.md`        | Cartographie complète des responsabilités tracking |
| `PH-WEBSITE-TRACKING-FOUNDATION-01.md`       | Rapport implémentation tracking website            |
| `MEDIA-BUYER-TRACKING-GUIDE.md`              | Guide UTM et events pour le Media Buyer            |
| `BRIEFING-WEBHOOK-CONVERSION-MEDIA-BUYER.md` | Briefing technique webhook conversion              |


---

## 11. ENV VARS NOUVELLES (à ajouter)

### Client (build-time, Dockerfile --build-arg)


| Variable                    | DEV                | PROD               |
| --------------------------- | ------------------ | ------------------ |
| `NEXT_PUBLIC_GA_ID`         | `G-R3QQDYEBFG`     | `G-R3QQDYEBFG`     |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` | `1234164602194748` |


### API (runtime, ConfigMap/Secret K8s)


| Variable                     | DEV                       | PROD                          |
| ---------------------------- | ------------------------- | ----------------------------- |
| `CONVERSION_WEBHOOK_URL`     | (webhook.site pour tests) | (URL Media Buyer)             |
| `CONVERSION_WEBHOOK_SECRET`  | (généré)                  | (généré)                      |
| `CONVERSION_WEBHOOK_ENABLED` | `false`                   | `false` (activé manuellement) |


---

**TRACKING SAAS ARCHITECTURE READY**

**STOP**