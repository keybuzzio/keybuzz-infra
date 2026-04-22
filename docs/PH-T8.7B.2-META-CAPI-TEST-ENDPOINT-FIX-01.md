# PH-T8.7B.2 — Meta CAPI Test Endpoint Fix

> Phase : PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01
> Date : 2026-04-22
> Environnement : DEV uniquement
> Auteur : Cursor Agent
> Branche : `ph147.4/source-of-truth`

---

## 1. Préflight

| Élément         | Valeur                                                    |
| --------------- | --------------------------------------------------------- |
| Branche         | `ph147.4/source-of-truth`                                 |
| HEAD avant      | `5661e215` (PH-T8.7B: Meta CAPI native)                  |
| HEAD après      | `9b461717` (PH-T8.7B.2: test endpoint fix)               |
| Repo clean      | Oui                                                       |
| Image DEV avant | `v3.5.98-meta-capi-native-tenant-dev`                     |
| Image DEV après | `v3.5.99-meta-capi-test-endpoint-fix-dev`                 |
| Image PROD      | `v3.5.95-outbound-destinations-api-prod` (non touchée)    |

---

## 2. Root Cause

### Problème

Le test endpoint `POST /outbound-conversions/destinations/:id/test` envoyait `ConnectionTest` comme `event_name` pour tous les types de destinations, y compris `meta_capi`.

Meta Conversions API rejette `ConnectionTest` avec `"Invalid parameter"` car :
1. Ce n'est pas un événement standard Meta
2. Le payload de test avait `email_hash: null`, produisant un `user_data` vide — Meta exige au moins un paramètre `user_data`

### Pourquoi ConnectionTest convient aux webhooks

Pour les webhooks, `ConnectionTest` est un événement légitime : c'est notre propre protocole, le destinataire peut l'identifier et le filtrer. Il prouve que la connexion HTTPS + HMAC fonctionne.

### Pourquoi ConnectionTest ne convient PAS à Meta CAPI

Meta impose :
- Un `event_name` standard ou custom valide
- Au moins un champ `user_data` (ex: `em`)
- Un `action_source` valide

`ConnectionTest` sans `user_data` échoue sur ces trois contraintes.

---

## 3. Design du fix

### Pour `destination_type = 'webhook'`

**Inchangé** : `event_name = 'ConnectionTest'`, payload existant.

### Pour `destination_type = 'meta_capi'`

Nouveau payload de test :

| Champ                  | Valeur                                                        |
| ---------------------- | ------------------------------------------------------------- |
| `event_name`           | `PageView` (événement Meta standard léger)                    |
| `event_time`           | `now` (Unix seconds)                                          |
| `event_id`             | `test_{tenantId}_{timestamp}` (unique)                        |
| `action_source`        | `website`                                                     |
| `user_data.em`         | SHA256 de `keybuzz-capi-test@keybuzz.io` (valeur non-sensible)|
| `custom_data`          | `value: 0, currency: EUR`                                     |
| `test_event_code`      | Depuis `body.test_event_code` ou env `META_CAPI_TEST_EVENT_CODE` |

### Choix de PageView

`PageView` est l'événement Meta le plus léger :
- Ne pollue pas les audiences de conversion (Purchase, StartTrial)
- N'affecte pas les campagnes d'optimisation
- Confirme que le pixel + token + pipeline fonctionnent
- Visible dans Events Manager → Test Events

---

## 4. Fichier modifié

| Fichier                                      | Action      | Diff         |
| -------------------------------------------- | ----------- | ------------ |
| `src/modules/outbound-conversions/routes.ts` | **MODIFIÉ** | +10, -3 lignes |

### Changements précis

1. **Nouveau payload Meta test** (lignes 299-303) : construit `metaTestPayload` avec `event_name: 'PageView'` et `email_hash` SHA256 d'une adresse de test
2. **Envoi du metaTestPayload** (ligne 306) : passe `metaTestPayload` au lieu de `testPayload` pour les destinations meta_capi
3. **Delivery logs event_name** (ligne 352) : le nom d'événement loggé reflète l'événement réellement envoyé (`PageView` pour meta_capi, `ConnectionTest` pour webhook)

---

## 5. Validation DEV Meta réelle

### Pixel / Token

| Paramètre       | Valeur             |
| ---------------- | ------------------ |
| Pixel ID         | `1234164602194748` |
| Test Event Code  | `TEST66800`        |

### Résultat Meta CAPI test

```json
{
  "test_result": {
    "status": "success",
    "destination_type": "meta_capi",
    "http_status": 200,
    "events_received": 1,
    "event_id": "test_ecomlg-001_1776877114206",
    "tested_at": "2026-04-22T16:58:34.734Z"
  }
}
```

**`events_received: 1`** — Meta accepte le PageView de test.

### Delivery log Meta

```json
{
  "event_name": "PageView",
  "status": "success",
  "http_status": 200,
  "error_message": null
}
```

### Résultat webhook test

```json
{
  "test_result": {
    "status": "success",
    "destination_type": "webhook",
    "http_status": 200,
    "event_id": "test_ecomlg-001_1776877115252"
  }
}
```

### Delivery log webhook

```json
{
  "event_name": "ConnectionTest",
  "status": "success",
  "http_status": 200
}
```

---

## 6. Tableau de validation

| Cas                          | Attendu                | Résultat                               |
| ---------------------------- | ---------------------- | -------------------------------------- |
| meta_capi PageView test      | `events_received=1`    | ✅ `events_received: 1`, HTTP 200       |
| webhook ConnectionTest       | webhook OK             | ✅ HTTP 200 (httpbin)                   |
| token API masking            | token jamais clair     | ✅ `EA*...gt`                           |
| logs pod                     | token absent           | ✅ 0 occurrences                        |
| delivery_logs                | token absent           | ✅ 0 occurrences                        |
| delivery_logs event_name     | PageView pour meta     | ✅ `"event_name": "PageView"`           |
| delivery_logs event_name     | ConnectionTest pour wh | ✅ `"event_name": "ConnectionTest"`     |
| RBAC                         | 403 inconnu            | ✅ HTTP 403                             |
| PROD inchangée               | même image             | ✅ `v3.5.95-outbound-destinations-api-prod` |

---

## 7. Non-régression

| Check                                | Résultat    |
| ------------------------------------ | ----------- |
| Webhook destinations CRUD            | ✅ Intacte   |
| Webhook HMAC signing                 | ✅ Inchangé  |
| Webhook test delivery (httpbin)      | ✅ HTTP 200  |
| StartTrial mapping réel              | ✅ Non touché |
| Purchase mapping réel                | ✅ Non touché |
| Idempotence                          | ✅ Intacte   |
| RBAC owner/admin                     | ✅ Intacte   |
| Token masking API                    | ✅ OK        |
| Token absent logs                    | ✅ OK        |
| Stripe billing                       | ✅ Non touché |
| Metrics                              | ✅ Non touché |
| PROD                                 | ✅ Inchangée |

---

## 8. Image DEV

| Élément  | Valeur                                                                    |
| -------- | ------------------------------------------------------------------------- |
| Tag      | `v3.5.99-meta-capi-test-endpoint-fix-dev`                                 |
| Registry | `ghcr.io/keybuzzio/keybuzz-api`                                           |
| Digest   | `sha256:8ce4f07d275538de2dbd02cdd22b5a9fb7c986ecaa402aa48e8b2273ea344ad9` |
| Build    | `docker build --no-cache` sur bastion (build-from-git)                    |
| Branche  | `ph147.4/source-of-truth`                                                 |
| Commit   | `9b461717`                                                                |
| Deploy   | `kubectl apply -f deployment.yaml` (GitOps strict)                        |

---

## 9. Rollback

```bash
kubectl apply -f keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml  # avec image v3.5.98
# ou
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.98-meta-capi-native-tenant-dev \
  -n keybuzz-api-dev
```

---

## 10. État PROD

| Élément     | Valeur                                                     |
| ----------- | ---------------------------------------------------------- |
| Image PROD  | `v3.5.95-outbound-destinations-api-prod` (inchangée)       |
| Impact PROD | **AUCUN**                                                  |

---

## VERDICT

```
META CAPI TEST ENDPOINT FIXED — PAGEVIEW TEST ACCEPTED — WEBHOOKS UNCHANGED — DEV ONLY
```

### Rapport : `keybuzz-infra/docs/PH-T8.7B.2-META-CAPI-TEST-ENDPOINT-FIX-01.md`

### STOP
