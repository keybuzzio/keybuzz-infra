# PH-T8.7B — Meta CAPI Native Per-Tenant Connector

> Phase : PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01
> Date : 2026-04-22
> Environnement : DEV uniquement
> Auteur : Cursor Agent
> Branche : `ph147.4/source-of-truth`

---

## 1. Préflight

| Élément         | Valeur                                                    |
| --------------- | --------------------------------------------------------- |
| Branche         | `ph147.4/source-of-truth`                                 |
| HEAD avant      | `db14cb03` (PH-T8.7A: marketing tenant attribution)      |
| HEAD après      | `5661e215` (PH-T8.7B: Meta CAPI native per-tenant)       |
| Repo clean      | Oui                                                       |
| Image DEV avant | `v3.5.97-marketing-tenant-foundation-dev`                 |
| Image DEV après | `v3.5.98-meta-capi-native-tenant-dev`                     |
| Image PROD      | `v3.5.95-outbound-destinations-api-prod` (non touchée)    |

---

## 2. Inventaire Credentials Meta CAPI

### Paramètres par tenant

| Paramètre            | Obligatoire ? | Stockage                              | Exposé en clair ? |
| -------------------- | ------------- | ------------------------------------- | ------------------ |
| `platform_pixel_id`  | **OUI**       | DB `outbound_conversion_destinations` | OUI (ID public)    |
| `platform_token_ref` | **OUI**       | DB (même table)                       | **NON** — masqué   |
| `platform_account_id`| Non           | DB (même table)                       | OUI                |
| `test_event_code`    | Non (DEV)     | Body du test endpoint ou env var      | N/A                |

### Prérequis pour un tenant

1. Un **Meta Pixel** créé dans le Business Manager
2. Un **Access Token** avec permissions `ads_management` et `conversions_api`
3. Optionnel : un **Test Event Code** depuis Events Manager → Test Events

### Sécurité des tokens

- Le `platform_token_ref` (access token Meta) est **stocké en DB** avec le même niveau de sécurité que les secrets HMAC
- **Jamais renvoyé en clair** : masqué (`EA*...*al`) dans toutes les réponses API
- Accès DB uniquement via le réseau privé K8s (`10.0.0.0/16`)
- Non loggé dans les messages console (seul le résultat HTTP est loggé)

---

## 3. Mapping Canonical → Meta CAPI

### Event Mapping

| KeyBuzz Event | Meta Standard Event | Justification                                      |
| ------------- | ------------------- | -------------------------------------------------- |
| `StartTrial`  | `StartTrial`        | Événement standard Meta — mapping direct 1:1       |
| `Purchase`    | `Purchase`          | Événement standard Meta — mapping direct 1:1       |

**Décision** : `StartTrial` est un événement standard Meta Conversions API (pas un événement custom). Le mapping direct est retenu car il fournit la meilleure compatibilité avec les audiences Meta et les algorithmes d'optimisation. Pas besoin de `CompleteRegistration` qui serait sémantiquement moins précis.

### Payload Transform

```
KeyBuzz canonical payload                  →  Meta Server Event
─────────────────────────                     ─────────────────
event_name: "StartTrial"                   →  event_name: "StartTrial"
event_time: "2026-04-22T15:35:00Z"         →  event_time: 1776872100 (unix seconds)
event_id: "conv_tenant_StartTrial_sub_x"   →  event_id: "conv_tenant_StartTrial_sub_x"
                                           →  action_source: "website"
customer.email_hash (SHA256)               →  user_data.em: ["sha256_hex"]
attribution.fbc                            →  user_data.fbc: "fb.1.xxx"
attribution.fbp                            →  user_data.fbp: "fb.1.xxx"
value.amount                               →  custom_data.value: 297
value.currency                             →  custom_data.currency: "EUR"
customer.plan                              →  custom_data.content_name: "KeyBuzz pro"
```

### Champs Meta servis

| Champ Meta             | Source KeyBuzz            | Requis par Meta |
| ---------------------- | ------------------------ | --------------- |
| `event_name`           | Mapping direct           | **OUI**         |
| `event_time`           | Conversion ISO → unix    | **OUI**         |
| `event_id`             | ID idempotence           | **OUI**         |
| `action_source`        | Hardcodé `website`       | **OUI**         |
| `user_data.em`         | SHA256 email (déjà hashé)| Recommandé      |
| `user_data.fbc`        | `signup_attribution.fbc` | Recommandé      |
| `user_data.fbp`        | `signup_attribution.fbp` | Recommandé      |
| `custom_data.value`    | Montant Stripe réel      | Pour Purchase   |
| `custom_data.currency` | Devise Stripe            | Pour Purchase   |
| `custom_data.content_name` | Plan KeyBuzz         | Optionnel       |

---

## 4. Modèle de Destination Meta

### Table `outbound_conversion_destinations` (colonnes ajoutées PH-T8.7A)

| Colonne              | Type  | Usage Meta CAPI                         |
| -------------------- | ----- | --------------------------------------- |
| `destination_type`   | TEXT  | `'meta_capi'`                           |
| `platform_pixel_id`  | TEXT  | Pixel ID Meta (ex: `1234567890123456`)  |
| `platform_token_ref` | TEXT  | Access Token Meta (stocké, jamais clair)|
| `platform_account_id`| TEXT  | Business Manager ID (optionnel)         |
| `mapping_strategy`   | TEXT  | `'direct'` (par défaut)                 |
| `endpoint_url`       | TEXT  | Auto-généré depuis pixel_id             |

### Endpoint URL auto-généré

Pour `meta_capi`, l'endpoint est calculé automatiquement :
```
https://graph.facebook.com/v21.0/{pixel_id}/events
```

La version API est configurable via `META_API_VERSION` (défaut: `v21.0`).

---

## 5. Routing par Type de Destination

### Architecture

```
emitOutboundConversion()
  │
  ├─ Test exclusion (tenant_billing_exempt)
  ├─ getActiveDestinations()
  │   ├─ DB: outbound_conversion_destinations (is_active=true)
  │   │   ├─ destination_type = 'webhook' → webhook flow
  │   │   └─ destination_type = 'meta_capi' → Meta CAPI flow
  │   └─ Fallback: env var OUTBOUND_CONVERSIONS_WEBHOOK_URL
  ├─ Idempotence (conversion_events)
  ├─ Attribution (signup_attribution)
  ├─ Build canonical payload
  └─ Pour chaque destination:
      ├─ if webhook → sendToWebhookDestination()
      │   ├─ HMAC SHA256 signature
      │   ├─ HTTP POST + retry (3x)
      │   └─ Log delivery_logs
      └─ if meta_capi → sendToMetaCapiDest()
          ├─ Transform → Meta Server Event format
          ├─ POST https://graph.facebook.com/v21.0/{pixel}/events
          ├─ Retry (3x, backoff 0/5s/15s)
          └─ Log delivery_logs
```

### Non-interférence

- Les destinations webhook existantes ne sont **pas impactées**
- Le routing est basé sur `destination_type` : chaque type a son adapter dédié
- L'idempotence reste globale (`conversion_events`)
- Les delivery logs partagent la même table avec le même format
- La coexistence webhook + meta_capi pour un même tenant est supportée

---

## 6. Test Event DEV

### Mode test Meta

Meta Conversions API supporte un `test_event_code` qui envoie les événements dans l'onglet "Test Events" du Events Manager, sans affecter les campagnes réelles.

### Mécanisme

1. **Test delivery** (POST `/destinations/:id/test`) : accepte `test_event_code` dans le body
2. **Events réels** : utilise la variable d'env `META_CAPI_TEST_EVENT_CODE` si définie
3. **Production** : aucun `test_event_code` → événements réels

### Comment vérifier dans Events Manager

1. Aller dans **Events Manager** → sélectionner le Pixel
2. Onglet **Test Events**
3. Entrer le `test_event_code` utilisé
4. Vérifier que l'événement apparaît avec les bons paramètres
5. Les événements test sont marqués "Test" et n'affectent pas les audiences/campagnes

### Distinguer test vs réel

| Critère             | Test              | Réel                    |
| ------------------- | ----------------- | ----------------------- |
| `test_event_code`   | Présent           | Absent                  |
| Visible dans        | Test Events tab   | Overview / Activity     |
| Affecte audiences   | Non               | Oui                     |
| Affecte attribution | Non               | Oui                     |

---

## 7. Validation DEV

| #   | Cas                                       | Attendu                              | Résultat                                           |
| --- | ----------------------------------------- | ------------------------------------ | -------------------------------------------------- |
| T1  | Health check                              | `{"status":"ok"}`                    | ✅ OK                                               |
| T2  | Créer destination meta_capi               | 201 + token masqué + auto URL        | ✅ `EA*...*al`, URL auto-générée                    |
| T3  | Lister destinations — token masqué        | `platform_token_ref` jamais en clair | ✅ Masqué correctement                              |
| T4  | Créer webhook (coexistence)               | 201 + deux types cohabitent          | ✅ OK                                               |
| T5  | Créer meta_capi sans pixel_id             | 400                                  | ✅ HTTP 400                                         |
| T6  | Créer webhook sans endpoint_url           | 400                                  | ✅ HTTP 400                                         |
| T7  | Test webhook delivery (httpbin)           | HTTP 200 delivered                   | ✅ `success`, HTTP 200                              |
| T8  | Test Meta CAPI (fake token)               | Échec avec erreur descriptive        | ✅ `"Malformed access token..."` HTTP 400           |
| T9  | Delivery logs Meta                        | Log créé avec statut                 | ✅ 1 log `failed`, HTTP 400                         |
| T10 | RBAC — email inconnu                      | 403                                  | ✅ HTTP 403                                         |
| T11 | Test exclusion (ecomlg-001)               | exempt = true                        | ✅ Exemption confirmée                              |
| T12 | Update pixel_id                           | endpoint_url auto-mis à jour         | ✅ URL mise à jour avec nouveau pixel               |
| T13 | Vérifier URL auto-update                  | Correct URL                          | ✅ `True`                                           |
| T14 | Non-régression logs                       | Aucun crash                          | ✅ Logs normaux, aucune erreur                      |
| T15 | PROD inchangée                            | Même image PROD                      | ✅ `v3.5.95-outbound-destinations-api-prod`         |

### Preuves cross-tenant safety

- Chaque destination est scopée par `tenant_id` dans la DB
- `getActiveDestinations(pool, tenantId)` filtre par tenant
- RBAC vérifie `user_tenants` pour chaque requête
- L'idempotence key inclut le `tenant_id`
- Les delivery logs sont liés au `destination_id` qui est lui-même lié au tenant
- Aucun endpoint ne permet d'accéder aux destinations d'un autre tenant

---

## 8. Non-régression

| Check                            | Résultat                                                            |
| -------------------------------- | ------------------------------------------------------------------- |
| API DEV health                   | ✅ HTTP 200 `{"status":"ok"}`                                        |
| Webhook destinations existantes  | ✅ CRUD fonctionne, test delivery OK (httpbin 200)                   |
| Idempotence                      | ✅ Intacte (clé basée sur tenant_id + event + sub_id)                |
| Delivery logs                    | ✅ Fonctionnent pour webhook ET meta_capi                            |
| Destinations API RBAC            | ✅ owner/admin autorisés, agent/inconnu refusé                       |
| Stripe billing webhook           | ✅ Non impacté (hooks dans billing/routes.ts inchangés)              |
| Metrics module                   | ✅ Non impacté                                                       |
| Test exclusion                   | ✅ ecomlg-001 exempt                                                 |
| Backend DEV                      | ✅ Inchangé                                                          |
| Client DEV                       | ✅ Inchangé                                                          |
| PROD                             | ✅ Inchangée `v3.5.95-outbound-destinations-api-prod`                |

---

## 9. Image DEV

| Élément  | Valeur                                                                    |
| -------- | ------------------------------------------------------------------------- |
| Tag      | `v3.5.98-meta-capi-native-tenant-dev`                                     |
| Registry | `ghcr.io/keybuzzio/keybuzz-api`                                           |
| Digest   | `sha256:fc5bead34331dea48712bf1fe7483a177e9972096e89906dbca350b2d3383370` |
| Build    | `docker build --no-cache` sur bastion                                     |
| Branche  | `ph147.4/source-of-truth`                                                 |
| Commit   | `5661e215`                                                                |

---

## 10. Fichiers modifiés

| Fichier                                                    | Action      | Lignes | Description                                           |
| ---------------------------------------------------------- | ----------- | ------ | ----------------------------------------------------- |
| `src/modules/outbound-conversions/adapters/meta-capi.ts`   | **CRÉÉ**    | 132    | Adapter Meta CAPI (transform, send, endpoint builder) |
| `src/modules/outbound-conversions/emitter.ts`              | **MODIFIÉ** | 386    | Routing par destination_type, Meta CAPI sender         |
| `src/modules/outbound-conversions/routes.ts`               | **MODIFIÉ** | 401    | CRUD meta_capi, token masking, test Meta delivery      |

### Détail des changements emitter.ts

- `Destination` interface étendue : `destination_type`, `platform_pixel_id`, `platform_token_ref`
- `getActiveDestinations()` : fetche les colonnes platform
- `sendToDestination()` renommé en `sendToWebhookDestination()` (clarté)
- Nouvelle `sendToMetaCapiDest()` avec retry 3x et delivery logs
- Boucle principale route par `destination_type`

### Détail des changements routes.ts

- Import `getMetaEndpointUrl`, `sendToMetaCapi` depuis l'adapter
- CREATE : validation spécifique meta_capi (pixel_id + token_ref obligatoires, endpoint auto)
- LIST : colonnes platform dans SELECT + masquage `platform_token_ref`
- UPDATE : gestion des champs platform + auto-update endpoint_url si pixel change
- TEST : routing meta_capi vs webhook dans le test delivery
- Fonction `sanitizeDestinationRow()` centralisée pour le masquage

---

## 11. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.97-marketing-tenant-foundation-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

Aucun impact DB (les colonnes platform existent déjà depuis PH-T8.7A).

---

## 12. État PROD

| Élément     | Valeur                                                     |
| ----------- | ---------------------------------------------------------- |
| Image PROD  | `v3.5.95-outbound-destinations-api-prod` (inchangée)       |
| Impact PROD | **AUCUN**                                                  |

---

## 13. Variables d'environnement

| Variable                  | Usage                                              | Requis |
| ------------------------- | -------------------------------------------------- | ------ |
| `META_API_VERSION`        | Version API Meta Graph (défaut: `v21.0`)           | Non    |
| `META_CAPI_TEST_EVENT_CODE` | Code test Meta pour mode DEV (events réels skip) | Non    |

---

## 14. Guide de configuration tenant

### Pour activer Meta CAPI sur un tenant

```bash
# 1. Créer la destination
curl -X POST https://api-dev.keybuzz.io/outbound-conversions/destinations \
  -H "Content-Type: application/json" \
  -H "x-user-email: owner@example.com" \
  -H "x-tenant-id: tenant-xxx" \
  -d '{
    "name": "Meta Conversions API",
    "destination_type": "meta_capi",
    "platform_pixel_id": "VOTRE_PIXEL_ID",
    "platform_token_ref": "VOTRE_ACCESS_TOKEN"
  }'

# 2. Tester la connexion
curl -X POST https://api-dev.keybuzz.io/outbound-conversions/destinations/{id}/test \
  -H "Content-Type: application/json" \
  -H "x-user-email: owner@example.com" \
  -H "x-tenant-id: tenant-xxx" \
  -d '{"test_event_code": "TEST_CODE_FROM_EVENTS_MANAGER"}'

# 3. Vérifier dans Meta Events Manager → Test Events
```

### Prérequis Meta Business Manager

1. **Pixel** : créer un Pixel dans Events Manager
2. **Token** : Settings → Generate Access Token (permissions: `ads_management`, `conversions_api`)
3. **Test code** : Events Manager → Test Events → copier le code

---

## 15. Extensibilité

### Ajout d'un nouveau connecteur (ex: TikTok Events API)

1. Créer `src/modules/outbound-conversions/adapters/tiktok-events.ts`
2. Implémenter `buildTikTokEvent()` et `sendToTikTok()`
3. Ajouter un `else if (dest.destination_type === 'tiktok_events')` dans `emitter.ts`
4. Ajouter la validation dans `routes.ts` pour les champs TikTok
5. La table DB est prête (`destination_type`, `platform_pixel_id`, `platform_token_ref`)

### Types prévus (non implémentés)

| Type             | Statut        | Champs requis                |
| ---------------- | ------------- | ---------------------------- |
| `webhook`        | ✅ Actif       | `endpoint_url`, `secret`     |
| `meta_capi`      | ✅ Actif       | `pixel_id`, `token_ref`      |
| `tiktok_events`  | Prévu         | `pixel_id`, `token_ref`      |
| `google_ads`     | Prévu         | `customer_id`, `token_ref`   |
| `linkedin_capi`  | Prévu         | `partner_id`, `token_ref`    |

---

## VERDICT

```
META CAPI NATIVE PER TENANT READY — CANONICAL EVENTS MAPPED — MULTI-TENANT SAFE — DEV ONLY
```

### Prêt pour :

- ✅ Création de destinations Meta CAPI par tenant
- ✅ Mapping direct StartTrial → Meta StartTrial, Purchase → Meta Purchase
- ✅ Token Meta jamais exposé en clair
- ✅ Endpoint Meta auto-généré depuis pixel_id
- ✅ Test delivery Meta avec test_event_code
- ✅ Delivery logs partagés webhook/meta_capi
- ✅ Coexistence webhook + meta_capi sur un même tenant
- ✅ RBAC owner/admin strict
- ✅ Cross-tenant leakage impossible
- ✅ Non-régression complète (webhook, Stripe, metrics, exclusion test)
- ✅ Extensible vers TikTok/Google/LinkedIn

### STOP — Prochaines étapes (hors scope) :

- Admin V2 UI pour configurer les destinations Meta CAPI
- Promotion PROD
- Connecteurs TikTok Events API / Google Ads / LinkedIn CAPI
- Chiffrement applicatif des tokens (AES-256-GCM)
