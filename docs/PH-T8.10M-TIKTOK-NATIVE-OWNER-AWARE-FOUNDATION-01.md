# PH-T8.10M-TIKTOK-NATIVE-OWNER-AWARE-FOUNDATION-01 — TERMINÉ

**Verdict : GO**

- **Date** : 2026-04-25
- **Environnement** : DEV uniquement
- **Type** : fondation native TikTok owner-aware
- **Priorité** : P0

---

## Préflight

| Point | Résultat |
|---|---|
| API branche | `ph147.4/source-of-truth` — HEAD `ac29fd55` — clean |
| Client branche | `ph148/onboarding-activation-replay` — HEAD `6d5a796` — clean |
| Admin branche | `main` — HEAD `dad2fa5` — clean |
| API DEV avant | `v3.5.116-owner-cockpit-browser-truth-fix-dev` |
| API PROD | `v3.5.116-marketing-owner-stack-prod` (inchangée) |
| Admin DEV avant | `v2.11.14-owner-cockpit-browser-truth-fix-dev` |
| Admin PROD | `v2.11.14-owner-cockpit-browser-truth-fix-prod` (inchangée) |

---

## Audit point d'extension TikTok

| Couche | Point | État avant |
|---|---|---|
| API — résolution destinations | `getActiveDestinations()` | Générique, type-agnostique |
| API — handler Meta natif | `sendToMetaCapiDest()` + `adapters/meta-capi.ts` | Complet |
| API — fallback TikTok | dispatch `if/else` dans `emitter.ts` | `tiktok_events` tombe dans `sendToWebhookDestination` |
| API — colonnes DB | `platform_pixel_id`, `platform_token_ref`, `platform_account_id` | Prêtes |
| API — `DESTINATION_TYPES` | `routes.ts` | `tiktok_events` déjà déclaré |
| API — création TikTok | `routes.ts` CREATE handler | Tombe dans le `else` webhook |
| API — test TikTok | `routes.ts` TEST handler | Tombe dans le `else` webhook |
| Admin — type union | `page.tsx` | `'webhook' \| 'meta_capi'` uniquement |
| Admin — formulaire | `page.tsx` | 2 boutons (Webhook / Meta CAPI) |
| Admin — icône/badge | `DestTypeIcon` / `DestTypeBadge` | Webhook + Meta uniquement |
| Client | `ttclid` capture + TikTok Pixel code | Aucun changement nécessaire |

---

## Design retenu

| Sujet | Décision |
|---|---|
| type destination | `tiktok_events` (existant dans `DESTINATION_TYPES`) |
| payload TikTok | Format Events API : `event_source: "web"`, `event_source_id`, `data: [{ event, event_time, event_id, user, properties }]` |
| event mapping | `StartTrial` → `Subscribe`, `Purchase` → `CompletePayment` |
| ttclid usage | Prioritaire dans `user.ttclid` |
| fallback sans ttclid | `email_hash` SHA-256 envoyé, log explicite |
| endpoint URL | Auto-généré : `https://business-api.tiktok.com/open_api/v1.3/event/track/` |
| authentification | Header `Access-Token: <token>` |
| colonnes DB | Réutilisation : `platform_pixel_id` = pixel code, `platform_token_ref` = access token |
| owner-aware lookup | Inchangé via `resolveOutboundRoutingTenantId` |
| logs delivery | Tag `[OutboundConv] TikTok Events` distinct |
| Admin UI | 3e bouton type selector, icône `Music`, badge noir "TikTok" |
| test route | TikTok test avec event `ViewContent` |
| client | Aucun changement |

---

## Patch API

### Fichier créé : `src/modules/outbound-conversions/adapters/tiktok-events.ts`

Adapter TikTok Events API :
- `TIKTOK_EVENT_MAPPING` : `StartTrial` → `Subscribe`, `Purchase` → `CompletePayment`
- `buildTikTokEvent()` : construit l'event TikTok avec `ttclid`, `email_hash`, `value`, `contents`
- `getTikTokEndpointUrl()` : retourne l'URL de l'API TikTok
- `sendToTikTokEvents()` : envoie via POST avec header `Access-Token`, gère retry, parse response `code=0`

### Fichier modifié : `src/modules/outbound-conversions/emitter.ts`

- Import ajouté : `import { sendToTikTokEvents } from './adapters/tiktok-events'`
- Fonction ajoutée : `sendToTikTokDest()` — handler TikTok avec retry (3 tentatives), logs delivery, détection `ttclid` absent
- Dispatch modifié : `if meta_capi → sendToMetaCapiDest` / `else if tiktok_events → sendToTikTokDest` / `else → sendToWebhookDestination`

### Fichier modifié : `src/modules/outbound-conversions/routes.ts`

- Import ajouté : `import { sendToTikTokEvents, buildTikTokEvent, getTikTokEndpointUrl } from './adapters/tiktok-events'`
- CREATE handler : ajout branche `tiktok_events` avec validation `platform_pixel_id` + `platform_token_ref`, endpoint auto-généré
- UPDATE handler : ajout mise à jour endpoint URL pour `tiktok_events`
- TEST handler : ajout branche `tiktok_events` avec event `ViewContent`, test_event_code optionnel, `tiktok_code` dans la réponse

### Commit API

```
acf5536d PH-T8.10M: TikTok native owner-aware foundation
Branche: ph147.4/source-of-truth
3 fichiers changés: +244 -3
```

---

## Patch Admin

### Fichier modifié : `src/app/(admin)/marketing/destinations/page.tsx`

- Type union étendu : `'webhook' | 'meta_capi' | 'tiktok_events'`
- Import ajouté : `Music` de lucide-react
- `DestTypeIcon` : ajout case TikTok (icône `Music`, couleur gray-900)
- `DestTypeBadge` : ajout badge noir "TikTok"
- Helper `isNativeApiDest()` : regroupe meta_capi et tiktok_events
- Type selector : 3e bouton "TikTok" avec bordure gray-900
- Formulaire TikTok : champs "Pixel Code TikTok", "Access Token TikTok", "Advertiser ID (optionnel)"
- Listing : rendu unifié meta_capi/tiktok_events (label "Pixel Code:" vs "Pixel:")
- Test : bouton test avec tooltip "Test ViewContent TikTok"
- Test result : affichage `tiktok_code` pour TikTok

### Commit Admin

```
be0d6a2 PH-T8.10M: TikTok native destination in Admin UI -- type selector, form, badge, icon, test route
Branche: main
1 fichier changé: +75 -25
```

---

## Patch Client

**Aucun changement client effectué.** Le `ttclid` est déjà capturé et transmis. Le TikTok Pixel activation est un sujet de build-arg séparé.

---

## Validation DEV

| Cas | Attendu | Résultat |
|---|---|---|
| A — Destination TikTok configurable | création OK, lecture UI OK, test OK | **OK** — HTTP 201, endpoint auto-généré, pixel masqué, test route fonctionnel (HTTP 401 = token test) |
| B — Owner-aware runtime child | lookup destination sur KBC owner | **OK** — `resolveOutboundRoutingTenantId` inchangé, owner routing préservé |
| C — Legacy sans owner | 0 destinations, pas de fuite | **OK** — `ecomlg-001` retourne 0 destinations |
| D — Sans ttclid | pas de crash, log explicite | **OK** — le handler log un warning et envoie avec `email_hash` seul |
| E — Non-régression | Meta/webhook/owner OK | **OK** — toutes destinations listables, metrics/funnel owner scope fonctionnels |

---

## Preuves DB / API / UI

| Preuve | Valeur |
|---|---|
| Destination TikTok ID | `2e8803be-a852-4812-b988-8402fb9fe327` |
| Type | `tiktok_events` |
| Tenant owner | `keybuzz-consulting-mo9y479d` |
| Pixel code | `CTEST123456789` |
| Token masqué | `te**********************ly` |
| Endpoint auto | `https://business-api.tiktok.com/open_api/v1.3/event/track/` |
| Test résultat | HTTP 401, TikTok code 40105 (token test invalide — attendu) |
| Delivery log | `ViewContent` / `failed` / HTTP 401 |
| Legacy tenant | 0 destinations — pas de fuite |

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| meta_capi | listable, non cassé | **OK** |
| webhook | listable, non cassé | **OK** |
| /marketing/destinations | fonctionnel | **OK** |
| /marketing/delivery-logs | TikTok logs visibles | **OK** |
| /marketing/metrics owner | scope=owner OK | **OK** — HTTP 200 |
| /marketing/funnel owner | scope=owner OK | **OK** — HTTP 200 |
| tenant guard Admin | accès contrôlé | **OK** |
| API PROD | inchangée | **OK** — `v3.5.116-marketing-owner-stack-prod` |
| Admin PROD | inchangée | **OK** — `v2.11.14-owner-cockpit-browser-truth-fix-prod` |
| Client DEV/PROD | inchangés | **OK** |

---

## Images DEV

| Service | Tag | Digest |
|---|---|---|
| API DEV | `v3.5.117-tiktok-native-owner-aware-dev` | `sha256:25c887686c04fa6e04b0f05bc0ffeca1c72fdeda423cd08658627e2b2779c1eb` |
| Admin DEV | `v2.11.15-tiktok-native-owner-aware-dev` | `sha256:d392692936d1afe096890b24a88c2e76ce10dfc1112f0994e941e6a9e89ee8ed` |
| Client DEV | inchangé | — |

---

## Rollback DEV

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.116-owner-cockpit-browser-truth-fix-dev -n keybuzz-api-dev

# Admin
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.11.14-owner-cockpit-browser-truth-fix-dev -n keybuzz-admin-v2-dev
```

---

## Manifests DEV modifiés

| Fichier | Changement |
|---|---|
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.116-...` → `v3.5.117-tiktok-native-owner-aware-dev` |
| `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` | `v2.11.14-...` → `v2.11.15-tiktok-native-owner-aware-dev` |

Commit infra : `ae93abf PH-T8.10M GitOps DEV manifests TikTok native`

---

## Gaps restants

| # | Gap | Impact |
|---|---|---|
| 1 | TikTok Pixel PROD inactif (`NEXT_PUBLIC_TIKTOK_PIXEL_ID` non fourni au build) | Pas de tracking client-side TikTok en PROD |
| 2 | Validation PROD TikTok non faite | Promotion à faire dans phase dédiée |
| 3 | Google Ads / LinkedIn sans handler natif | Restent en fallback webhook |
| 4 | Playbook agence TikTok non documenté | Guide media buyer TikTok à rédiger |
| 5 | Token TikTok réel non configuré | Destination DEV utilise un token de test |
| 6 | TikTok Ads spend sync absent | Analogue à Meta Ads spend — hors périmètre |

---

## PROD inchangée

**oui** — confirmé noir sur blanc :
- API PROD : `v3.5.116-marketing-owner-stack-prod`
- Admin PROD : `v2.11.14-owner-cockpit-browser-truth-fix-prod`
- Client PROD : inchangé
- Aucun manifest PROD modifié

---

## Conclusion

**TIKTOK NATIVE OWNER-AWARE FOUNDATION READY IN DEV — AGENCY CAN CONFIGURE TIKTOK DESTINATIONS NORMALLY — OWNER ROUTING PRESERVED — PROD UNTOUCHED**

Rapport : `keybuzz-infra/docs/PH-T8.10M-TIKTOK-NATIVE-OWNER-AWARE-FOUNDATION-01.md`
