# PH-T8.7B — Audit Meta CAPI Per-Tenant

> Date : 2026-04-22
> Branche : `ph147.4/source-of-truth`
> Commit audité : `5661e215`

---

## A. Credentials Meta CAPI


| Paramètre             | Obligatoire | Stockage DB                        | Exposé API | Sécurité            |
| --------------------- | ----------- | ---------------------------------- | ---------- | ------------------- |
| `platform_pixel_id`   | OUI         | `outbound_conversion_destinations` | OUI        | ID public Meta      |
| `platform_token_ref`  | OUI         | `outbound_conversion_destinations` | **MASQUÉ** | `EA*...*al`         |
| `platform_account_id` | NON         | `outbound_conversion_destinations` | OUI        | ID Business Manager |
| `test_event_code`     | NON         | Body request / env var             | N/A        | Pas stocké          |


---

## B. Adapter Meta CAPI


| Critère                    | Résultat                                                          |
| -------------------------- | ----------------------------------------------------------------- |
| Fichier                    | `src/modules/outbound-conversions/adapters/meta-capi.ts`          |
| API Meta version           | `v21.0` (configurable via `META_API_VERSION`)                     |
| Endpoint                   | `https://graph.facebook.com/v21.0/{pixel_id}/events`              |
| Méthode auth               | `access_token` dans le body JSON (pas en header, conformité Meta) |
| Événements supportés       | `StartTrial`, `Purchase`                                          |
| Mapping                    | Direct 1:1 (événements standard Meta)                             |
| `action_source`            | `website` (hardcodé, conforme aux conversions web)                |
| `user_data.em`             | SHA256 lowercase email (déjà hashé côté KeyBuzz)                  |
| `user_data.fbc`            | Passé directement depuis `signup_attribution`                     |
| `user_data.fbp`            | Passé directement depuis `signup_attribution`                     |
| `custom_data.value`        | Montant Stripe réel (EUR)                                         |
| `custom_data.content_name` | Nom du plan KeyBuzz                                               |
| Timeout                    | 15s (vs 10s pour webhook — Meta peut être plus lent)              |
| Token dans les logs        | **NON** — seul le résultat HTTP est loggé                         |


---

## C. Routing par Destination Type


| Critère          | Résultat                                             |
| ---------------- | ---------------------------------------------------- |
| Discrimination   | `destination_type` dans `getActiveDestinations()`    |
| `webhook`        | `sendToWebhookDestination()` — HMAC + HTTP POST      |
| `meta_capi`      | `sendToMetaCapiDest()` → `sendToMetaCapi()`          |
| Coexistence      | **OUI** — même tenant peut avoir webhook + meta_capi |
| Env var fallback | Uniquement pour webhook (rétrocompatibilité)         |
| Retry meta_capi  | 3 tentatives, backoff 0/5s/15s (identique webhook)   |
| Delivery logs    | Partagés dans `outbound_conversion_delivery_logs`    |
| Idempotence      | Partagée dans `conversion_events` (event_id global)  |


---

## D. Sécurité Token


| Critère                     | Résultat                                                              |
| --------------------------- | --------------------------------------------------------------------- |
| Stockage                    | PostgreSQL, réseau privé K8s uniquement                               |
| Masquage API                | 2 premiers + 2 derniers caractères visibles, reste `*`                |
| Token dans les logs serveur | NON — seul `[OutboundConv] ... HTTP xxx` est loggé                    |
| Token dans delivery_logs DB | NON — `error_message` contient le message d'erreur Meta, pas le token |
| Token dans les réponses API | MASQUÉ dans LIST, CREATE, UPDATE, TEST                                |
| Token dans le body Meta API | OUI (requis par Meta) — HTTPS uniquement                              |
| Chiffrement at-rest         | NON (phase future — AES-256-GCM)                                      |


---

## E. CRUD Meta CAPI


| Opération | Validation meta_capi                             | Résultat          |
| --------- | ------------------------------------------------ | ----------------- |
| CREATE    | `pixel_id` + `token_ref` obligatoires            | ✅ 400 si manquant |
| CREATE    | `endpoint_url` auto-généré                       | ✅ Graph API URL   |
| LIST      | `platform_token_ref` masqué                      | ✅ `EA*...*al`     |
| UPDATE    | Changement pixel_id → auto-update endpoint_url   | ✅ Vérifié         |
| UPDATE    | Changement token_ref → stocké, masqué en réponse | ✅ Vérifié         |
| TEST      | Route vers Meta CAPI au lieu de webhook          | ✅ Vérifié         |
| TEST      | Accepte `test_event_code` en body                | ✅ Vérifié         |


---

## F. Tenant Safety


| Critère                               | Résultat                                               |
| ------------------------------------- | ------------------------------------------------------ |
| Destinations scopées par `tenant_id`  | ✅ `WHERE tenant_id = $1` sur toutes les requêtes       |
| RBAC vérifié                          | ✅ `user_tenants` check pour chaque opération           |
| Cross-tenant leakage                  | ✅ Impossible — isolation par requête SQL               |
| Idempotence key inclut tenant_id      | ✅ `conv_{tenantId}_{event}_{subId}`                    |
| Test exclusion inclut tenant_id       | ✅ `tenant_billing_exempt WHERE tenant_id = $1`         |
| Delivery logs liés via destination_id | ✅ Chaque log pointe vers une destination tenant-scoped |


---

## G. Non-Régression


| Composant                       | Impact      | Vérifié |
| ------------------------------- | ----------- | ------- |
| Webhook destinations existantes | Aucun       | ✅       |
| HMAC signing webhook            | Aucun       | ✅       |
| Idempotence conversion_events   | Aucun       | ✅       |
| Test exclusion                  | Aucun       | ✅       |
| Stripe billing webhook          | Aucun       | ✅       |
| Metrics /metrics/overview       | Aucun       | ✅       |
| API health                      | OK          | ✅       |
| PROD                            | Non touchée | ✅       |


---

## H. Résumé


| Élément            | Status                                  |
| ------------------ | --------------------------------------- |
| Adapter Meta CAPI  | ✅ Opérationnel                          |
| Routing multi-type | ✅ Opérationnel                          |
| Token sécurisé     | ✅ Masqué                                |
| CRUD meta_capi     | ✅ Complet                               |
| Test delivery Meta | ✅ Fonctionnel                           |
| Tenant isolation   | ✅ Vérifiée                              |
| Non-régression     | ✅ Complète                              |
| Image DEV          | ✅ `v3.5.98-meta-capi-native-tenant-dev` |
| PROD               | ✅ Inchangée                             |
