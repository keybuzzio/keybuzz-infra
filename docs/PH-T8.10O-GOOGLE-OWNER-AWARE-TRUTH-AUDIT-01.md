# PH-T8.10O ? Google Owner-Aware Truth Audit

> Date : 25 avril 2026
> Environnement : DEV + lecture PROD
> Type : audit verite Google owner-aware (lecture seule)
> Priorite : P0
> Aucune modification effectuee

---

## VERDICT

### GOOGLE OWNER-AWARE = CAS B ? PRESQUE PRET

La boucle Google est partiellement fonctionnelle grace au pipeline sGTM existant,
mais elle ne passe PAS par le modele owner-aware valide pour Meta et TikTok.
Un petit gap empeche l'alignement complet.

---

## 1. PREFLIGHT

| Repo | Branche | HEAD | Clean |
|---|---|---|---|
| API | `ph147.4/source-of-truth` | `acf5536d` | Oui |
| Client | `ph148/onboarding-activation-replay` | `6d5a796` | Oui |
| Admin | `main` | `be0d6a2` | Oui |

| Service | Image DEV | Image PROD |
|---|---|---|
| API | `v3.5.117-tiktok-native-owner-aware-dev` | `v3.5.117-tiktok-native-owner-aware-prod` |
| Client | ? | `v3.5.116-marketing-owner-stack-prod` |
| Admin | ? | `v2.11.15-tiktok-native-owner-aware-prod` |

---

## 2. AUDIT CLIENT GOOGLE

| Sujet | Emplacement | Etat actuel |
|---|---|---|
| gclid capture | `src/lib/attribution.ts:119` | **OK** ? capture depuis URL params |
| _gl capture (GA4 cross-domain linker) | `src/lib/attribution.ts:124` | **OK** ? capture depuis URL params |
| utm_* capture (5 params) | `src/lib/attribution.ts:114-118` | **OK** ? utm_source/medium/campaign/term/content |
| GA4 gtag.js injection | `SaaSAnalytics.tsx:22,56-89` | **Code OK mais NON actif en PROD** ? `NEXT_PUBLIC_GA4_MEASUREMENT_ID` non injecte au build |
| sGTM client support | `SaaSAnalytics.tsx:24,73,89` | **Code OK** ? si `NEXT_PUBLIC_SGTM_URL` defini, gtag.js charge depuis sGTM au lieu de googletagmanager.com |
| Cross-domain linker | `SaaSAnalytics.tsx:74-76` | **OK** ? configure pour `keybuzz.pro` et `www.keybuzz.pro` |
| GA4 browser events | `src/lib/tracking.ts` | **OK** ? signup_start, signup_step, signup_complete, begin_checkout, purchase |
| Consent Mode v2 | `SaaSAnalytics.tsx:64-69` | **Partiel** ? analytics_storage: granted, ad_storage: denied (pas de CMP) |
| marketing_owner_tenant_id + gclid coexistence | `attribution.ts:35,119` | **OK** ? meme contexte AttributionContext |
| TikTok Pixel (comparaison) | `SaaSAnalytics.tsx:26` | **Code OK** ? meme pattern |
| Meta Pixel (comparaison) | `SaaSAnalytics.tsx:23` | **Code OK** ? meme pattern |

### Constat client :
Le code client est COMPLET pour Google. Capture gclid, _gl, UTMs, GA4 browser events,
cross-domain linker, support sGTM. Mais en PROD, `NEXT_PUBLIC_GA4_MEASUREMENT_ID` n'est
PAS injecte au build, donc GA4 browser est INACTIF dans l'image deployee.

---

## 3. AUDIT API / ATTRIBUTION GOOGLE

| Sujet | Source | Etat actuel |
|---|---|---|
| gclid persiste | `signup_attribution.gclid` | **OK** ? INSERT via `tenant-context-routes.ts:722` |
| _gl persiste | `signup_attribution.gl_linker` | **OK** ? INSERT via `tenant-context-routes.ts:726` |
| ttclid persiste (comparaison) | `signup_attribution.ttclid` | **OK** |
| Pipeline GA4 MP ancien | `billing/routes.ts:1849-1945` | **ACTIF** ? `emitConversionWebhook` envoie purchase a sGTM |
| GA4_MEASUREMENT_ID | env var PROD | **OK** ? `G-R3QQDYEBFG` |
| GA4_MP_API_SECRET | env var PROD | **OK** ? configure |
| CONVERSION_WEBHOOK_URL | env var PROD | **OK** ? `https://t.keybuzz.io/mp/collect` |
| CONVERSION_WEBHOOK_ENABLED | env var PROD | **OK** ? `true` |
| google_ads destination type | `outbound-conversions/routes.ts:14` | **Declare** dans DESTINATION_TYPES |
| Google adapter natif | `adapters/` | **INEXISTANT** ? seuls meta-capi.ts et tiktok-events.ts existent |
| google_ads dans emitter dispatch | `emitter.ts` (ligne ~460) | **Fallback webhook** ? pas de handler dedie |
| emitConversionWebhook owner-aware | `billing/routes.ts:1849` | **NON** ? utilise tenant brut de Stripe metadata |
| emitOutboundConversion owner-aware | `emitter.ts:345-360` | **OUI** ? via `resolveOutboundRoutingTenantId` |

### Deux pipelines coexistent :

**Pipeline 1 ? ANCIEN (`emitConversionWebhook`)** :
- Declenche sur `checkout.session.completed` uniquement (StartTrial)
- Envoie au format GA4 Measurement Protocol vers `https://t.keybuzz.io/mp/collect` (sGTM)
- sGTM fan-out : GA4 + Meta CAPI + TikTok EAPI + Google Ads Conversion Tracking
- NON owner-aware (tenant brut de session.metadata)
- Inclut gclid dans les params quand present

**Pipeline 2 ? NOUVEAU (`emitOutboundConversion`)** :
- Declenche sur StartTrial ET Purchase
- Owner-aware via `resolveOutboundRoutingTenantId`
- Adapters natifs : Meta CAPI, TikTok Events
- google_ads type declare mais tombe dans le fallback webhook (pas d'adapter)
- Destinations configurees par tenant dans `outbound_conversion_destinations`

### Gap critique :
Le pipeline owner-aware (P2) n'a PAS d'adapter Google natif.
Le pipeline qui envoie reellement a Google (P1) n'est PAS owner-aware.

---

## 4. AUDIT GTM / sGTM / ADDINGWELL

### Infrastructure sGTM

| Element | Valeur | Statut |
|---|---|---|
| Domaine | `t.keybuzz.io` | **Actif** ? DNS 34.120.158.38 (Addingwell/GCP) |
| Container ID | `GTM-NTPDQ7N7` | Version 4 active |
| Version | V4 - Google Ads Integration | Publiee 18/04/2026 |
| HTTP status | 400 (requete sans payload) | **Normal** |

### Tags sGTM actifs (Version 4)

| Tag | Type | Trigger | Statut |
|---|---|---|---|
| Conversion Linker | Conversion Linker | All Events | ACTIF |
| GA4 - All Events | GA4 | All Events | ACTIF |
| Google Ads - Conversion Tracking | Google Ads | purchase_event | ACTIF |
| Meta CAPI - All Events | Meta CAPI | All Events | ACTIF |

### Google Ads Conversion dans sGTM

| Parametre | Valeur |
|---|---|
| Conversion ID | `18098643667` |
| Conversion Label | `zqQPCPXys54cENPFjbZD` |
| Compte Google Ads | `keybuzz.pro@gmail.com` |
| Action de conversion | "Achat" (Purchase) |
| Valeur | Dynamique (event data `value`) |
| Devise | Dynamique (event data `currency`) |

### Validation (PH-T7.1, 18/04/2026)
- 20 requetes envoyees a `pagead2.googlesyndication.com`
- 100% HTTP 200
- Latence P50 35ms, P95 79ms

### Comparaison des modeles

| Modele | Existe ? | Live ? | Suffisant pour l'agence ? | Notes |
|---|---|---|---|---|
| Option A : GA4 browser tags | Oui (SaaSAnalytics) | **Non en PROD** (env var manquante au build) | Insuffisant seul | Tracking basique, pas de conversions Google Ads |
| Option B : sGTM / Addingwell | Oui (t.keybuzz.io) | **Oui** (Version 4, HTTP 200) | **Partiellement** ? fonctionne pour Google Ads mais NON owner-aware | Le pipeline P1 envoie au sGTM qui forwarde a Google Ads |
| Option C : Destination native Google | **Non** | Non | Non | `google_ads` declare dans les types mais aucun adapter |

---

## 5. AUDIT ADMIN

| Surface Admin | Google utile aujourd'hui ? | Gap |
|---|---|---|
| metrics/funnel owner-scoped | Oui (scope=owner) | Pas de ventilation par canal Google specifique |
| ad accounts | **Meta uniquement** (hardcode 'meta') | Google Ads non supporte ? PlatformBadge ne connait que 'meta' |
| destinations | webhook / meta_capi / tiktok_events | **google_ads absent** du type selector UI (`DestinationType`) |
| delivery logs | Generique | Google pas distingue (pas de destination Google a afficher) |
| integration guide | Google Ads = **"Bientot"** | "Prevu ? architecture prete" (ligne 105) |
| integration guide roadmap | Google Ads outbound = **"Non natif"** | "Webhook agence -> Google Offline Conversions" (ligne 812) |
| integration guide roadmap | Google Ads spend sync = **"Non natif"** | "Import manuel ou future phase" (ligne 802) |

### Note : L'integration guide est honnete sur l'etat. Elle indique que TikTok outbound est
aussi "Non natif" alors qu'il a ete implemente depuis (PH-T8.10M). Le guide est donc
legerement desynchronise pour TikTok mais exact pour Google.

---

## 6. VERITE END-TO-END

| Question | Reponse | Preuve |
|---|---|---|
| Un clic Google Ads avec gclid + owner mapping peut-il etre capture sous KBC ? | **OUI** | `attribution.ts` capture gclid + marketing_owner_tenant_id dans le meme contexte. `signup_attribution` les persiste. Owner mapping via `tenants.marketing_owner_tenant_id`. |
| Le lead / tenant enfant remonte-t-il dans le cockpit owner KBC ? | **OUI** | `scope=owner` sur `/metrics/overview`, `/funnel/metrics`, `/funnel/events` agrege tous les enfants. Prouve en DEV et PROD. |
| Une conversion business peut-elle etre renvoyee a Google de facon exploitable ? | **OUI MAIS via sGTM seulement, et NON owner-aware** | Le pipeline P1 (`emitConversionWebhook`) envoie la conversion au sGTM a `t.keybuzz.io/mp/collect`. Le tag Google Ads Conversion Tracking dans sGTM la forwarde a Google Ads. MAIS ce pipeline utilise le tenant brut (pas le owner). |
| L'agence peut-elle se contenter de Google Ads + bonnes URLs, sans dependre de l'Admin ? | **Partiellement** | L'agence peut creer des campagnes Google Ads avec `gclid` auto-tag + UTMs, les leads arrivent dans le cockpit owner, et les conversions sont renvoyees a Google Ads via sGTM. MAIS le retour conversion n'est pas owner-aware, et l'agence n'a pas d'UI self-service pour configurer/voir les Google conversions. |
| La verite business reste-t-elle KeyBuzz ? | **OUI pour l'acquisition** ? gclid capture, attribution persistee, metrics owner-scoped. **NON pour le retour conversion** ? le sGTM est un intermediaire opaque, pas un retour first-class comme Meta CAPI ou TikTok Events. | Le sGTM envoie les conversions mais KeyBuzz n'a pas de visibilite directe sur le delivery Google Ads (pas de delivery log KeyBuzz, pas de status). |
| Le modele est-il coherent avec Meta/TikTok ? | **NON** | Meta = destination native owner-aware avec adapter + delivery logs + Admin UI. TikTok = idem. Google = pipeline ancien non owner-aware via sGTM intermediaire sans delivery logs KeyBuzz. |

---

## 7. DIAGNOSTIC FINAL

### Cas B ? Google presque pret

La base est bonne :
- Capture gclid/UTMs : OK
- Attribution DB : OK
- sGTM avec Google Ads tag : OPERATIONNEL
- Owner mapping : OK
- Owner-scoped metrics/funnel : OK

Le gap restant :
1. **Pipeline conversion Google n'est PAS owner-aware** ? `emitConversionWebhook` utilise le tenant brut
2. **Pas d'adapter natif Google dans le pipeline owner-aware** (`emitOutboundConversion`)
3. **Admin UI ne propose pas google_ads** comme type de destination
4. **GA4 browser inactif en PROD** ? env var `NEXT_PUBLIC_GA4_MEASUREMENT_ID` non injectee au build
5. **Pas de delivery logs KeyBuzz** pour les conversions Google ? opaque via sGTM
6. **Ad accounts Meta-only** ? pas de Google Ads dans l'Admin

### En resume :
Google Ads recoit les conversions via sGTM, mais pas de maniere owner-aware,
pas avec la meme qualite de suivi que Meta/TikTok, et pas avec le meme niveau
de controle agence dans l'Admin.

---

## 8. COMPARAISON DES OPTIONS

| Option | Impact | Taille | Limites | Verdict |
|---|---|---|---|---|
| **Option 1 : Webhook sGTM existant (statu quo)** | L'agence recoit deja les conversions Google Ads via sGTM | Zero effort | NON owner-aware, pas de delivery logs KeyBuzz, opaque, pas first-class | **Fonctionnel mais insuffisant pour le modele agence** |
| **Option 2 : Destination native google_ads first-class** | Alignement complet avec Meta/TikTok : adapter natif, owner-aware, delivery logs, Admin UI | Moyen (1-2 jours) ? adapter + Admin UI + test | Necessite les credentials Google Offline Conversions ou Enhanced Conversions API | **Le plus propre produit, aligne avec le modele** |
| **Option 3 : Doc + URLs + integration guide seulement** | Ameliore la documentation operationnelle | Petit | Ne resout pas le gap owner-aware ni le tracking Google Ads | **Insuffisant** |
| **Option 4 : Rendre emitConversionWebhook owner-aware** | Le sGTM recevrait les conversions pour le bon tenant | Petit (quelques lignes) | Ne donne pas de delivery logs, pas de controle Admin, pas first-class | **Quick win partiel mais dette technique** |

---

## 9. PLUS PETIT CHANTIER SUIVANT

### Recommandation : Option 4 en quick win + Option 2 en phase suivante

**Phase immediate (PH-T8.10P) ? Quick win owner-aware sGTM** :
- Objectif : Rendre `emitConversionWebhook` owner-aware en ajoutant `resolveOutboundRoutingTenantId` AVANT l'envoi au sGTM
- Taille : 5-10 lignes dans `billing/routes.ts`
- Impact : Les conversions Google Ads via sGTM seront correctement attribuees au owner KBC meme pour les tenants enfants
- Risque : Tres faible ? meme logique deja prouvee pour `emitOutboundConversion`

**Phase suivante (PH-T8.10Q) ? Google Ads native destination** :
- Objectif : Creer un adapter natif `google-ads.ts` pour Google Offline Conversions API ou Enhanced Conversions, ajouter le type dans l'Admin UI, et aligner avec Meta/TikTok
- Taille : 1-2 jours
- Impact : Parit? complete Meta/TikTok/Google dans le modele owner-aware
- Prerequis : Credentials Google Ads Offline Conversions API

### Pourquoi c'est le bon prochain move :
1. La Phase immediate (Option 4) debloque l'agence MAINTENANT avec l'infrastructure existante
2. La Phase suivante (Option 2) donne la parite produit mais peut attendre les credentials Google
3. Pas besoin de build client (GA4 browser est un nice-to-have, pas bloquant pour la conversion server-side)

---

## 10. AUCUNE MODIFICATION EFFECTUEE

| Element | Modifie ? |
|---|---|
| keybuzz-api | Non |
| keybuzz-client | Non |
| keybuzz-admin-v2 | Non |
| DB DEV | Non |
| DB PROD | Non |
| sGTM / Addingwell | Non |
| K8s deployments | Non |
| PROD | Inchangee |
| keybuzz-infra | Ce rapport uniquement |

---

## 11. RESUME

```
PH-T8.10O-GOOGLE-OWNER-AWARE-TRUTH-AUDIT-01 ? TERMINE
Verdict : PARTIEL (Cas B)

Preflight
  API : ph147.4/source-of-truth @ acf5536d (clean)
  Client : ph148/onboarding-activation-replay @ 6d5a796 (clean)
  Admin : main @ be0d6a2 (clean)

Client
  gclid + _gl + utm_* : CAPTURES
  GA4 browser : CODE OK, INACTIF EN PROD (env var manquante au build)
  sGTM support : CODE OK (NEXT_PUBLIC_SGTM_URL)
  Cross-domain linker : OK (keybuzz.pro)
  marketing_owner_tenant_id coexistence : OK

API / Attribution
  gclid persiste : OUI (signup_attribution)
  Pipeline sGTM (ancien P1) : ACTIF, NON owner-aware
  Pipeline outbound (nouveau P2) : ACTIF, owner-aware, PAS d'adapter Google
  GA4_MEASUREMENT_ID : G-R3QQDYEBFG (PROD configure)
  google_ads type : DECLARE mais fallback webhook

GTM / sGTM
  t.keybuzz.io : ACTIF (Addingwell, GCP 34.120.158.38)
  sGTM Version 4 : GA4 + Meta CAPI + Google Ads Conversion + Conversion Linker
  Google Ads tag : OPERATIONNEL (ID 18098643667, 100% success 18/04/2026)

Admin
  Destinations : meta_capi + tiktok_events (PAS google_ads)
  Ad accounts : Meta uniquement
  Integration guide : Google Ads = "Bientot" / "Non natif"

Verite end-to-end
  Capture gclid + owner : OUI
  Remontee cockpit owner : OUI
  Retour conversion Google : OUI mais NON owner-aware (via sGTM)
  Agence self-service Google : NON

Diagnostic
  Cas B ? Google presque pret
  Gap principal : pipeline conversion sGTM non owner-aware

Options
  Quick win : rendre emitConversionWebhook owner-aware (5-10 lignes)
  Phase suivante : adapter natif google_ads first-class (1-2 jours)

Prochain chantier
  PH-T8.10P : Owner-aware sGTM conversion pipeline (quick win)

Aucune modification effectuee
  OUI ? lecture seule
```

Rapport : `keybuzz-infra/docs/PH-T8.10O-GOOGLE-OWNER-AWARE-TRUTH-AUDIT-01.md`

---

GOOGLE OWNER-AWARE TRUTH ESTABLISHED ? CURRENT READINESS KNOWN ? MINIMAL NEXT STEP CLEAR ? PROD UNCHANGED

**STOP**
