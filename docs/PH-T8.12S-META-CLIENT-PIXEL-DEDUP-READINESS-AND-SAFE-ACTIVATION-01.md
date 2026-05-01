# PH-T8.12S-META-CLIENT-PIXEL-DEDUP-READINESS-AND-SAFE-ACTIVATION-01

> **Objectif** : Traiter le dernier gap de parite tracking Client funnel — Meta Pixel. Auditer la deduplication Meta browser/CAPI, activer le Pixel si safe, bloquer les events business dangereux.

---

## Sources relues

- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md`
- `PH-T8.12R-CLIENT-GA4-SGTM-PARITY-AND-TRACKING-DOC-RECONCILIATION-01.md`
- `PH-T8.12Q-ACQUISITION-TRACKING-PARITY-VISUAL-QA-AND-CLEANUP-01.md`
- `PH-T8.12P-TIKTOK-BROWSER-PIXEL-CUTOVER-AND-DEDUP-01.md`
- `PH-T8.11Z-ANALYTICS-BASELINE-CLEAN-READINESS-01.md`
- `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md`
- `PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md`
- `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-AUDIT.md`

---

## Preflight

| Repo | Branche | HEAD | Dirty | Decision |
|------|---------|------|-------|----------|
| keybuzz-infra | `main` | `ca4a4b6` | Non | OK |
| keybuzz-client (source) | `ph-t812p/tiktok-browser-pixel` | `3325f03` | Non | Source patch |

### Images PROD avant intervention

| Service | Image |
|---------|-------|
| Client | `v3.5.145-client-ga4-sgtm-parity-prod` |
| Website | `v0.6.8-tiktok-browser-pixel-prod` |
| API (principal) | `v3.5.130-platform-aware-refund-strategy-prod` |
| API (outbound-worker) | `v3.5.165-escalation-flow-prod` |
| Admin | `v2.11.35-agency-launch-kit-prod` |

---

## Audit Meta browser (Client code)

### Events Meta envoyes par le navigateur

| Fonction | Event Meta | Declencheur | event_id Meta |
|----------|-----------|-------------|---------------|
| `SaaSAnalytics` init | **PageView** | Page funnel load | Non |
| `trackSignupStart` | **Lead** | Clic plan `/register` | Non |
| `trackSignupComplete` | **CompleteRegistration** | Succes create-signup | Non |
| `trackBeginCheckout` | **InitiateCheckout** | URL Stripe recue | Non |
| `trackPurchase` | **Purchase** | `/register/success` entitlement | Non |

**Constat : aucun `event_id` n'est transmis aux appels `fbq('track', ...)`.** Cela rend impossible la deduplication Meta entre browser et CAPI pour les events partages.

### Fichiers audites

- `src/components/tracking/SaaSAnalytics.tsx` — chargement conditionnel Pixel
- `src/lib/tracking.ts` — fonctions tracking
- `app/register/page.tsx` — appels Lead, CompleteRegistration, InitiateCheckout
- `app/register/success/page.tsx` — appel Purchase

### Protection pages

- Funnel : `/register`, `/login` (et sous-chemins)
- Bloque : `/inbox`, `/dashboard`, `/orders`, `/settings`, etc. (BLOCKED_PREFIXES)
- `shouldLoad = !isBlockedPage(pathname) && isFunnelPage(pathname) && (GA4_ID || META_PIXEL_ID || ...)`

---

## Audit Meta CAPI server-side

### Events Meta envoyes par le serveur

| Event KeyBuzz | Event Meta CAPI | event_id server | Trigger Stripe |
|---------------|-----------------|-----------------|----------------|
| StartTrial | **StartTrial** | `conv_{tenant}_{StartTrial}_{sub_id}` | `checkout.session.completed` |
| Purchase | **Purchase** | `conv_{tenant}_{Purchase}_{sub_id}` | subscription `trialing → active` |
| Test | **PageView** | `test_{tenant}_{timestamp}` | Admin test button |

### Architecture

`emitOutboundConversion()` → destinations actives → `sendToMetaCapiDest()` → `sendToMetaCapi()` → `POST graph.facebook.com/v21.0/{pixel_id}/events`

Idempotence : `ON CONFLICT (event_id) DO NOTHING` dans `conversion_events`.

---

## Gate deduplication Meta

| Event Meta | Browser | Server | Meme event_name | Meme event_id | Decision |
|------------|---------|--------|-----------------|----------------|----------|
| **PageView** | OUI (auto) | Test seulement | N/A | N/A | **SAFE** |
| **Lead** | OUI | NON | N/A | N/A | **SAFE** |
| **CompleteRegistration** | OUI | NON (`StartTrial` ≠ `CompleteRegistration`) | **NON** | N/A | **SAFE** |
| **InitiateCheckout** | OUI | NON | N/A | N/A | **SAFE** |
| **Purchase** | OUI (sans event_id) | OUI (avec event_id) | **OUI** | **NON** | **STOP DEDUP** |

### Decision

**Option A selectionnee** : activer Meta Pixel Client avec `Purchase` browser retire.

- **PageView** : safe (auto Pixel, test server = contexte different)
- **Lead** : safe (aucun equivalent server-side)
- **CompleteRegistration** : safe (server envoie `StartTrial`, event_name different)
- **InitiateCheckout** : safe (aucun equivalent server-side)
- **Purchase** : **RETIRE du browser** — identique au pattern TikTok `CompletePayment` (PH-T8.12P)

---

## Patch

### Modification

Fichier : `src/lib/tracking.ts`
Branche : `ph-t812s/meta-pixel-dedup-safe` (depuis `ph-t812p/tiktok-browser-pixel` @ `3325f03`)
Commit : `5840a18`

```diff
@@ -127,13 +127,6 @@ export function trackPurchase(params: {
     value: params.value,
     items: [{ item_name: `KeyBuzz ${params.plan}`, price: params.value }],
   });
-  trackMeta('Purchase', {
-    content_name: `KeyBuzz ${params.plan}`,
-    currency: 'EUR',
-    value: params.value,
-    content_type: 'product',
-  });
-  // PH-T8.12P: CompletePayment removed from browser — server-side only via Events API
   // event_id mismatch (browser: transactionId vs server: conv_<tenant>_Purchase_<sub_id>)
   // prevents TikTok deduplication — double counting risk eliminated
 }
```

---

## Build

### Build-args

| Arg | Valeur |
|-----|--------|
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` |

### Artefacts

| Element | Valeur |
|---------|--------|
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.146-client-meta-pixel-dedup-safe-prod` |
| Digest | `sha256:ba90a78457c1c2fed92d392be840958f60871890670bc2830ba3af126034c3fa` |
| Source | `ph-t812p/tiktok-browser-pixel` @ `3325f03` |
| Patch | `ph-t812s/meta-pixel-dedup-safe` @ `5840a18` |

### Validations bundle

| Signal | Resultat |
|--------|----------|
| GA4 `G-R3QQDYEBFG` | OK |
| sGTM `t.keybuzz.pro` | OK |
| TikTok `D7PT12JC77U44OJIPC10` | OK |
| LinkedIn `9969977` | OK |
| Meta Pixel `1234164602194748` | OK |
| Meta `fbq init` | OK |
| Meta Purchase browser | RETIRE |
| CompletePayment browser | ABSENT |

---

## GitOps

| Element | Valeur |
|---------|--------|
| Fichier modifie | `k8s/keybuzz-client-prod/deployment.yaml` |
| Infra commit | `29cf181` |
| Push | `main → origin/main` |
| `kubectl apply` | `deployment.apps/keybuzz-client configured` |
| Rollout | `successfully rolled out` |
| Manifest = Runtime | `v3.5.146-client-meta-pixel-dedup-safe-prod` |

---

## Validation visuelle IDE

**En attente de confirmation Ludovic.**

A verifier :

### `/register` et `/login`
- [ ] Meta Pixel : `connect.facebook.net/en_US/fbevents.js` charge (Network)
- [ ] GA4 : `t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` charge (Network)
- [ ] sGTM : requetes vers `t.keybuzz.pro`
- [ ] TikTok : `analytics.tiktok.com` charge
- [ ] LinkedIn : `snap.licdn.com` charge
- [ ] Purchase browser : aucun evenement `Purchase` Meta dans le waterfall
- [ ] CompletePayment : absent

### Pages protegees (`/dashboard`)
- [ ] Aucun tracking publicitaire

---

## Non-regression

| Composant | Statut | Detail |
|-----------|--------|--------|
| Client PROD | **MIS A JOUR** | `v3.5.146-client-meta-pixel-dedup-safe-prod` |
| Website PROD | Inchange | `v0.6.8-tiktok-browser-pixel-prod` |
| API PROD (principal) | Inchange | `v3.5.130-platform-aware-refund-strategy-prod` |
| API PROD (outbound-worker) | Inchange | `v3.5.165-escalation-flow-prod` |
| TikTok Events API | ACTIF | Derniere livraison HTTP 200 |
| Meta CAPI | ACTIF | Derniere livraison HTTP 200 |
| LinkedIn CAPI | ACTIF | Derniere livraison HTTP 201 |
| Client `/register` HTTP | 200 | Accessible |
| Faux events | Aucun | Pas de Purchase/CompletePayment dans logs |
| Fake spend | Aucun | Aucun achat declenche |
| Secrets exposes | Aucun | Aucun token dans rapport ou logs |

---

## Rollback (GitOps strict)

```bash
# 1. Revert le commit GitOps
cd keybuzz-infra
git revert 29cf181
git push origin main

# 2. Appliquer les manifests revertes
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status deploy/keybuzz-client -n keybuzz-client-prod

# Image rollback : v3.5.145-client-ga4-sgtm-parity-prod
```

---

## Gaps restants

| Priorite | Gap | Detail |
|----------|-----|--------|
| P2 | TikTok payload `content_id` | Test Events signale `content_id` manquant sur ViewContent |
| P2 | Meta Purchase browser event_id | Si a l'avenir on veut activer Purchase browser, il faudra aligner event_id avec CAPI |
| P3 | GA4 key events import Google Ads | `signup_complete` importe mais completion funnel a surveiller |

---

## Verdict

**GO META CLIENT PIXEL SAFE**

**META CLIENT PIXEL SAFE ON FUNNEL — PURCHASE SERVER-SIDE ONLY — NO DOUBLE COUNTING — GA4 SGTM TIKTOK LINKEDIN PRESERVED — PROTECTED PAGES CLEAN — NO FAKE EVENT — GITOPS STRICT — VISUAL QA PENDING**
