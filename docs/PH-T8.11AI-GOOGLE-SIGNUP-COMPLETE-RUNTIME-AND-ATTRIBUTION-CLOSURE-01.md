# PH-T8.11AI — Google Signup Complete Runtime and Attribution Closure

> Date : 29 avril 2026
> Auteur : Agent Cursor
> Phase : PH-T8.11AI-GOOGLE-SIGNUP-COMPLETE-RUNTIME-AND-ATTRIBUTION-CLOSURE-01
> Tickets : KEY-217 (signup_complete sync)

---

## 0. Préflight

| Élément | Valeur | Verdict |
|---|---|---|
| API PROD | `v3.5.123-linkedin-capi-native-prod` | ✅ |
| Client PROD | `v3.5.125-register-console-cleanup-prod` | ✅ |
| Admin PROD | `v2.11.23-marketing-menu-truth-cleanup-prod` | ✅ |
| Google Ads secret PROD | `keybuzz-google-ads` — 4 clés (client_id, client_secret, developer_token, refresh_token) | ✅ présent |
| keybuzz-api | `ph-t72/tiktok-tracking-dev` (lecture seule) | ✅ |
| keybuzz-infra | `main`, HEAD `b1c42f2` | ✅ |
| API PROD health | `{"status":"ok"}` | ✅ |

---

## 1. Google Ads Conversion Action Status

### Méthode d'audit

L'API KeyBuzz n'expose pas d'endpoint pour lister les conversion actions Google Ads (`/ad-accounts/:id/conversions` retourne 404).
Le statut des conversion actions provient de l'observation directe de Ludovic dans Google Ads API/UI le 29 avril 2026.

### Conversion Actions observées (compte `5947963982`)

| Conversion Action | Source | Status | primary_for_goal | include_in_conversions_metric | Category |
|---|---|---|---|---|---|
| **Achat** (purchase) | GA4 import | **Active** | true | true | Purchase |
| **KeyBuzz (web) signup_complete** | GA4 import | **HIDDEN** | false | false | — |
| **KeyBuzz (web) purchase** | GA4 import | Active | — | — | Purchase |

### Interprétation `signup_complete` HIDDEN

Le statut `HIDDEN` signifie que la conversion action a été automatiquement importée depuis GA4 (via le linking GA4 ↔ Google Ads configuré en PH-T8.11X), mais **n'a pas encore été activée comme objectif publicitaire**.

Cela est attendu pour une conversion action fraîchement importée :
- Google Ads importe les key events GA4 automatiquement
- Mais ne les active pas comme objectifs primaires sans action manuelle de l'annonceur
- `primary_for_goal = false` signifie que Google Ads ne l'utilise pas pour optimiser les enchères
- `include_in_conversions_metric = false` signifie qu'elle n'apparaît pas dans la colonne "Conversions" des rapports Ads

### Action requise

**Action manuelle dans Google Ads UI** :
1. Google Ads → Objectifs → Conversions
2. Trouver `KeyBuzz (web) signup_complete`
3. Activer comme objectif primaire
4. Catégorie recommandée : **Lead** ou **Start Trial** (pas "Purchase")
5. Ne PAS créer de conversion manuelle doublon
6. Ne PAS ajouter de tag `AW-18098643667` direct

### Après activation

- La conversion apparaîtra dans les rapports Ads sous la colonne "Conversions"
- Les enchères Smart Bidding pourront optimiser pour `signup_complete`
- Délai de propagation attendu : 4–24h

---

## 2. Runtime Google Test — DB PROD

### Ligne `signup_attribution` vérifiée

| Champ | Valeur |
|---|---|
| `id` | `51edd8ea-f258-4c55-b473-1fdc5ec51a9d` |
| `tenant_id` | `ludovic-mojol7ds` |
| `user_email` | `ludovic+test-google-20260429@keybuzz.pro` |
| `utm_source` | `google` |
| `utm_medium` | `cpc` |
| `utm_campaign` | `internal-validation-google-signup-20260429` |
| `utm_term` | `signup-complete` |
| `utm_content` | `manual-prod-check` |
| `gclid` | `null` |
| `fbclid` | `null` |
| `fbp` | `fb.1.1776463590193.319177859295313342` (résidu cookie Meta, pas lié au test) |
| `gl_linker` | Présent (cross-domain GA4 fonctionnel) |
| `plan` | `pro` |
| `cycle` | `monthly` |
| `landing_url` | `https://client.keybuzz.io/register?plan=pro&cycle=monthly&utm_source=google&utm_medium=cpc&utm_campaign=internal-validation-google-signup-20260429&utm_term=signup-complete&utm_content=manual-prod-chec` |
| `referrer` | `null` |
| `attribution_id` | `9ae503b9-0a77-4cfa-936d-659c28a85f21` |
| `stripe_session_id` | `null` |
| `conversion_sent_at` | `2026-04-29T06:37:18Z` (~2 min après signup) |
| `created_at` | `2026-04-29T06:35:43Z` |
| `marketing_owner_tenant_id` | `null` |
| `li_fat_id` | `null` |

### Interprétation

- **`gclid = null`** : **NORMAL** — Ce test a été réalisé manuellement en naviguant vers une URL UTM, pas via un clic Google Ads réel. Le `gclid` n'est injecté automatiquement que par un clic Google Ads avec auto-tagging activé.
- **UTMs présents** : ✅ — Tous les 5 paramètres UTM sont correctement capturés depuis l'URL.
- **`gl_linker` présent** : ✅ — Le cross-domain tracking GA4 (`www.keybuzz.pro` → `client.keybuzz.io`) fonctionne.
- **`conversion_sent_at` rempli** : ✅ — Le système CAPI a dispatché les conversions server-side (~2 min après le signup).
- **`fbp` présent** : Side-effect inoffensif — Cookie Meta (`_fbp`) d'une session antérieure, pas lié à ce test Google.
- **`marketing_owner_tenant_id = null`** : Voir section 3.

### Funnel events pour le test tenant

| event_name | source | created_at |
|---|---|---|
| `success_viewed` | client | 2026-04-29T06:37:22Z |
| `dashboard_first_viewed` | client | 2026-04-29T06:37:26Z |

Les micro-steps `register_started` → `tenant_created` → `checkout_started` ne sont pas présents pour ce tenant. Seuls les events post-signup (`success_viewed`, `dashboard_first_viewed`) ont été capturés.

---

## 3. Owner-Aware — Verdict `marketing_owner_tenant_id`

### État actuel

**10 lignes** dans `signup_attribution` PROD :
- **3 avec `marketing_owner_tenant_id = keybuzz-consulting-mo9zndlk`** (tests précédents avec scripts/patches)
- **7 avec `marketing_owner_tenant_id = null`** (dont le test actuel)

### Analyse du code

| Composant | Support `marketing_owner_tenant_id` | Détail |
|---|---|---|
| **DB** (`signup_attribution`) | ✅ Colonne existe | `text, nullable=YES` |
| **API** (compiled PROD) | ✅ INSERT inclut le champ | `tenant-context-routes.js` |
| **API** (outbound-conversions) | ✅ Référencé dans emitter + google-observability | Propagé aux conversions CAPI |
| **API** (funnel + metrics) | ✅ Utilisé pour cohort owner | Routage multi-tenant marketing |
| **Client** (`AttributionContext`) | ❌ **Absent** | Pas dans l'interface TypeScript |
| **Client** (`captureAttribution()`) | ❌ **Pas capturé** | Ne lit pas `marketing_owner_tenant_id` des URL params |
| **Client** (`/register` POST body) | ❌ **Pas envoyé** | Seul `attribution` (type `AttributionContext`) est envoyé |
| **Playbook Admin** | ❌ **Non mentionné** | `acquisition-playbook/page.tsx` ne cite pas ce paramètre |
| **Pricing → Register navigation** | ❌ **UTMs non forwarded** | `PricingCard.tsx` navigue sans reprendre les UTMs |

### Verdict

**GAP P2** — Le système owner-aware est **half-implemented** :
- Le backend (API + DB + conversions CAPI + funnel + metrics) est **prêt** et fonctionne quand la valeur est fournie.
- Le frontend (client Next.js) **ne capture pas** `marketing_owner_tenant_id` depuis les URL params et **ne l'envoie pas** au backend.
- Les 3 rows existantes avec `owner` ont été créées par des scripts de test, pas par le flux normal.

### Pour les vraies campagnes KeyBuzz

Si le suivi owner-aware est souhaité :
1. Ajouter `marketing_owner_tenant_id` à `AttributionContext` dans `src/lib/attribution.ts`
2. Le capturer dans `captureAttribution()` depuis `searchParams.get('marketing_owner_tenant_id')`
3. Mettre à jour le Playbook Admin pour recommander l'inclusion du paramètre dans les URLs publicitaires
4. Mettre à jour `PricingCard.tsx` pour forwarder les UTMs + owner lors de la navigation vers `/register`

**Pas de patch dans cette phase** — scope distinct, ticket P2 à créer.

### Note sur le forwarding UTM `/pricing` → `/register`

Le composant `PricingCard.tsx` navigue vers `/register?plan=...&cycle=...` **sans reprendre les UTMs** de l'URL courante. Cependant, dans le test de Ludovic, les UTMs sont correctement dans la `landing_url`. Cela signifie que :
- Le site `www.keybuzz.pro/pricing` (keybuzz-website) inclut les UTMs dans les liens vers `client.keybuzz.io/register`
- OU Ludovic a navigué directement vers `/register` avec les UTMs dans l'URL

Le forwarding UTM client-side est un **GAP mineur** car le scénario réel passe par le site marketing (`keybuzz.pro`) qui est un domaine séparé.

---

## 4. GA4 / Google Ads Visibilité

### GA4

| Élément | Statut |
|---|---|
| `signup_complete` event | ✅ Reçu en Realtime |
| `purchase` event | ✅ Reçu en Realtime |
| `begin_checkout` event | ✅ Reçu en Realtime |
| Key event `signup_complete` | ✅ Activé (★) |
| Key event `purchase` | ✅ Activé (★) |
| Measurement ID | `G-R3QQDYEBFG` |
| Linking Google Ads | ✅ Compte `594-796-3982` lié |

### Google Ads

| Conversion Action | Statut actuel | Action requise |
|---|---|---|
| `Achat` (purchase) | ✅ Active, primary, incluse dans conversions | Aucune |
| `KeyBuzz (web) signup_complete` | ⚠️ HIDDEN, non primary, non incluse | **Activation manuelle** dans UI Google Ads |
| `KeyBuzz (web) purchase` | ✅ Active | Aucune |

### Délai de propagation

Après activation manuelle de `signup_complete` :
- Apparition dans les rapports Ads : **4–24h**
- Conversions du test actuel : probablement **ignorées** car `internal-validation` (pas de clic Ads réel, pas de `gclid`)
- Premières conversions réelles : dès qu'un utilisateur cliquera sur une annonce Google Ads → signup → `signup_complete` sera comptabilisé

---

## 5. Funnel et Delivery Logs — Clarification

### `/marketing/funnel`

**Nature** : Tableau de bord micro-steps d'onboarding (de `register_started` à `activation_completed`).
**Ce n'est PAS** un rapport d'attribution campagne.

Le funnel montre :
- Les étapes de conversion du processus de signup (16 steps)
- Un owner-aware cohort quand `marketing_owner_tenant_id` est présent
- Les volumes et taux de conversion entre étapes

**Pas trompeur** — correctement spécialisé pour le parcours utilisateur post-clic.

### `/marketing/delivery-logs`

**Nature** : Logs de livraison des conversions CAPI server-side.

**Destinations actives PROD** :

| Destination | Type | Tenant | Statut |
|---|---|---|---|
| KeyBuzz Consulting — Meta CAPI | `meta_capi` | `keybuzz-consulting-mo9zndlk` | ✅ active, test=success |
| KeyBuzz Consulting — LinkedIn CAPI | `linkedin_capi` | `keybuzz-consulting-mo9zndlk` | ✅ active, test=success |
| KeyBuzz Consulting — TikTok | `tiktok_events` | `keybuzz-consulting-mo9zndlk` | ⚠️ active mais business/API bloqué |

**Google n'apparaît PAS** dans les delivery logs. C'est **correct by design** :
- Google conversions passent via **GA4 client-side → sGTM → GA4 → import automatique Google Ads**
- Ce chemin est **opaque** pour le système de delivery logs CAPI de l'Admin
- Les delivery logs ne montrent que les conversions envoyées **directement par l'API** (Meta CAPI, TikTok Events API, LinkedIn CAPI)

**Aucune action corrective nécessaire** — les surfaces Admin sont spécialisées, pas trompeuses.

### Recommandation P3 optionnelle

Un encart informatif dans `/marketing/delivery-logs` pourrait clarifier :
> « Google/YouTube : les conversions sont routées via GA4 + sGTM. Elles n'apparaissent pas ici. Voir Google Tracking. »

Non prioritaire — ticket P3 si souhaité.

---

## 6. Non-Régression

| Vérification | Résultat |
|---|---|
| Meta CAPI | ✅ Destination active, test=success, inchangée |
| TikTok CAPI | ✅ Destination active (business/API bloqué, inchangé) |
| LinkedIn CAPI | ✅ Destination active, test=success, inchangée |
| Google spend sync | ✅ `google` = 2 rows, £0.0628 (inchangé depuis PH-T8.11AF) |
| Meta spend sync | ✅ `meta` = 16 rows, £445.20 (inchangé) |
| `/metrics` | ✅ Meta + Google présents |
| Tag AW direct | ✅ Absent du bundle client PROD |
| `api-dev.keybuzz.io` | ✅ Absent du bundle client PROD |
| API PROD restarts | 0 |
| Client PROD restarts | 0 |
| Admin PROD restarts | 0 |
| Outbound worker restarts | 7 (pré-existant, non lié) |
| DEV images | ✅ Inchangées |
| Secrets exposés | ✅ Aucun dans ce rapport |

### Images runtime confirmées

| Service | PROD | DEV |
|---|---|---|
| API | `v3.5.123-linkedin-capi-native-prod` | `v3.5.123-linkedin-capi-native-dev` |
| Client | `v3.5.125-register-console-cleanup-prod` | `v3.5.125-register-console-cleanup-dev` |
| Admin | `v2.11.23-marketing-menu-truth-cleanup-prod` | `v2.11.30-marketing-menu-truth-cleanup-dev` |

---

## 7. Linear

### KEY-217 — Google Ads `signup_complete` sync

**Statut : RESTER OUVERT** avec action claire.

**Fait** :
- ✅ GA4 key event `signup_complete` activé et fonctionnel
- ✅ Google Ads ↔ GA4 linking opérationnel
- ✅ Conversion action `KeyBuzz (web) signup_complete` importée dans Google Ads
- ✅ DB `signup_attribution` correctement peuplée avec UTMs Google
- ✅ `conversion_sent_at` rempli (CAPI dispatch fonctionnel)

**Reste** :
- ⚠️ `signup_complete` est HIDDEN dans Google Ads (non activée comme objectif)
- **Action** : Activation manuelle dans Google Ads UI → Objectifs → Conversions → `KeyBuzz (web) signup_complete` → Activer comme primary, catégorie Lead/Start Trial
- Après activation : re-vérifier sous 24h que la conversion est visible dans les rapports Ads
- **Fermer KEY-217** après confirmation post-activation

### Nouveau ticket P2 recommandé — Owner-Aware Attribution Gap

**Titre** : `[P2] Implémenter marketing_owner_tenant_id dans le client (AttributionContext)`

**Description** :
Le backend API gère `marketing_owner_tenant_id` (DB, CAPI, funnel, metrics) mais le client Next.js ne le capture pas depuis les URL params. 3/10 attributions ont un owner (via scripts de test), les flux réels arrivent avec `null`.

**Scope** :
1. Ajouter `marketing_owner_tenant_id` à `AttributionContext` dans `src/lib/attribution.ts`
2. Le capturer dans `captureAttribution()` depuis les URL search params
3. Mettre à jour le Playbook Admin pour recommander son inclusion dans les URLs publicitaires
4. Forwarder les UTMs dans `PricingCard.tsx` lors de la navigation `/pricing` → `/register`

### Ticket P3 optionnel — Delivery Logs Info Banner

**Titre** : `[P3] Clarifier l'absence de Google dans Delivery Logs`

**Description** :
Ajouter un encart informatif dans `/marketing/delivery-logs` expliquant que Google/YouTube passent par GA4/sGTM et n'apparaissent pas dans les delivery logs CAPI.

---

## 8. Résumé Verdict

| Critère | Verdict |
|---|---|
| **Google Ads `signup_complete`** | ⚠️ HIDDEN — importée depuis GA4, activation manuelle requise |
| **GA4 `signup_complete`** | ✅ Reçu, key event activé, fonctionnel |
| **DB attribution** | ✅ Tous UTMs capturés, `gl_linker` présent, `conversion_sent_at` rempli |
| **`gclid` interpretation** | ✅ `null` NORMAL — test manuel sans clic Ads |
| **`marketing_owner_tenant_id`** | ⚠️ GAP P2 — API prêt, client pas implémenté |
| **Funnel** | ✅ Correct — micro-steps onboarding, pas attribution campagne |
| **Delivery Logs** | ✅ Correct — CAPI only (Meta/TikTok/LinkedIn), Google absent by design |
| **Non-régression** | ✅ PASS — aucun drift, aucun secret exposé, aucun tag AW |
| **PROD modifiée** | ❌ NON — aucune modification code/build/image/secret |

---

## VERDICT FINAL

**GOOGLE SIGNUP_COMPLETE RUNTIME VERIFIED — GA4 EVENT RECEIVED — GOOGLE ADS ACTION IMPORTED BUT HIDDEN (MANUAL ACTIVATION REQUIRED) — KEYBUZZ ATTRIBUTION QUALIFIED — GCLID NULL EXPECTED — OWNER-AWARE GAP P2 DOCUMENTED — NO AW DIRECT TAG — NO TRACKING DRIFT — PROD UNMODIFIED**

---

## Annexe A — Schema `signup_attribution` (24 colonnes)

```
id (uuid, NOT NULL)
tenant_id (text, NOT NULL)
user_email (text, NOT NULL)
utm_source (text)
utm_medium (text)
utm_campaign (text)
utm_term (text)
utm_content (text)
gclid (text)
fbclid (text)
fbc (text)
fbp (text)
gl_linker (text)
plan (text)
cycle (text)
landing_url (text)
referrer (text)
attribution_id (text)
stripe_session_id (text)
conversion_sent_at (timestamptz)
created_at (timestamptz)
ttclid (text)
marketing_owner_tenant_id (text)
li_fat_id (text)
```

## Annexe B — Destinations CAPI actives PROD

| Nom | Type | Tenant | Statut |
|---|---|---|---|
| KeyBuzz Consulting — Meta CAPI | `meta_capi` | `keybuzz-consulting-mo9zndlk` | Active |
| KeyBuzz Consulting — LinkedIn CAPI | `linkedin_capi` | `keybuzz-consulting-mo9zndlk` | Active |
| KeyBuzz Consulting — TikTok | `tiktok_events` | `keybuzz-consulting-mo9zndlk` | Active (credentials bloquées) |

Pas de destination Google — conversions Google via GA4/sGTM (by design).

## Annexe C — Rollback

**Aucun rollback nécessaire** — cette phase est purement audit/documentation, aucune modification PROD.
