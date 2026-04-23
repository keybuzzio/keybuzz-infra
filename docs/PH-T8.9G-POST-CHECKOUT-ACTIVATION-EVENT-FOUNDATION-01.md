# PH-T8.9G — Post-Checkout Activation Event Foundation

> **Date** : 2026-04-24  
> **Auteur** : Cursor Executor (CE)  
> **Phase** : PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01  
> **Environnement** : DEV uniquement  
> **Type** : Fondation events d'activation post-checkout  
> **Priorité** : P0  

---

## 1. OBJECTIF

Rendre observables les premières étapes réelles après checkout/trial en émettant 6 events d'activation internes dans `funnel_events`, réutilisant l'infrastructure existante (table, routes, cohort stitching). Ces events sont strictement internes au CRO produit — zéro pollution ads.

---

## 2. PRÉFLIGHT

### API — `keybuzz-api`

| Élément | Valeur |
|---------|--------|
| Branche | `ph147.4/source-of-truth` |
| HEAD avant | `2a61895e` |
| HEAD après | `d004d45e` |
| Image DEV avant | `v3.5.109-funnel-metrics-tenant-scope-dev` |
| Image DEV après | `v3.5.110-post-checkout-activation-foundation-dev` |
| Digest | `sha256:2d4e945faa3faa59619ff315fb90fcb4b168cc269caa1bf3dd22abf063be11df` |

### Client — `keybuzz-client`

| Élément | Valeur |
|---------|--------|
| Branche | `ph148/onboarding-activation-replay` |
| HEAD avant | `9d8b9a0` |
| HEAD après | `1db9852` |
| Image DEV avant | `v3.5.108-funnel-pretenant-foundation-dev` |
| Image DEV après | `v3.5.110-post-checkout-activation-foundation-dev` |
| Digest | `sha256:9896f9e08a1bc446abb013cd0f4ac7dcd9fa5477276aad8d8f69be795f92462e` |

### PROD inchangée

| Service | Image PROD |
|---------|------------|
| API | `v3.5.109-funnel-metrics-tenant-scope-prod` |
| Client | `v3.5.108-funnel-pretenant-foundation-prod` |

---

## 3. DESIGN DE STITCHING POST-CHECKOUT

| Point | Décision retenue |
|-------|-----------------|
| **Résolution funnel_id post-checkout** | `emitActivationEvent()` résout le canonical funnel_id depuis `funnel_events WHERE tenant_id = $1 ORDER BY created_at ASC LIMIT 1`. Fallback = tenant_id si aucun funnel antérieur. |
| **Utilisation de tenant_id** | Toujours stocké dans `tenant_id`. Sert de clé de jointure pour cohort stitching. |
| **Idempotence** | `ON CONFLICT (funnel_id, event_name) DO NOTHING` — un seul event par funnel, pas de doublon. |
| **Client-side dedup** | In-memory Set keyed par `activation:{tenantId}:{eventName}`. |
| **Gap billing → tenant** | `billing_events.tenant_id = NULL` reste non corrigé. Documenté comme gap. |
| **Schéma DB** | Aucune migration. Table `funnel_events` inchangée (schéma + index existants). |

---

## 4. ALLOWLIST ÉTENDUE

### Funnel canonique complet (15 events)

| # | Event | Phase | Source |
|---|-------|-------|--------|
| 1 | `register_started` | Pré-tenant | Client |
| 2 | `plan_selected` | Pré-tenant | Client |
| 3 | `email_submitted` | Pré-tenant | API (BFF) |
| 4 | `otp_verified` | Pré-tenant | Client + API |
| 5 | `oauth_started` | Pré-tenant | Client |
| 6 | `company_completed` | Pré-tenant | Client |
| 7 | `user_completed` | Pré-tenant | Client |
| 8 | `tenant_created` | Pré-tenant | API |
| 9 | `checkout_started` | Pré-tenant | API |
| 10 | **`success_viewed`** | Post-checkout | Client |
| 11 | **`dashboard_first_viewed`** | Post-checkout | Client |
| 12 | **`onboarding_started`** | Post-checkout | Client |
| 13 | **`marketplace_connected`** | Post-checkout | API |
| 14 | **`first_conversation_received`** | Post-checkout | API |
| 15 | **`first_response_sent`** | Post-checkout | API |

---

## 5. INSTRUMENTATION CLIENT

### A. `/register/success` — `success_viewed`

- **Fichier** : `app/register/success/page.tsx`
- **Trigger** : Quand `status === 'success'` (entitlement débloqué), AVANT `clearAttribution()`
- **Mécanisme** : `tenantIdRef` peuplé pendant le polling, `emitActivationStep('success_viewed', tenantId)` 
- **Guard** : `purchaseTracked.current` (one-shot), in-memory dedup dans `emitActivationStep`
- **Privacy** : Seul `tenant_id` et `plan` stockés. Pas d'email, pas de PII.

### B. `/dashboard` — `dashboard_first_viewed`

- **Fichier** : `app/dashboard/page.tsx`
- **Trigger** : Premier render avec `currentTenantId` disponible
- **Mécanisme** : `dashboardEmitted` ref + `useEffect([currentTenantId])`
- **Guard** : Ref one-shot + in-memory dedup
- **Privacy** : Seul `tenant_id` stocké.

### C. `/start` — `onboarding_started`

- **Fichier** : `app/start/page.tsx` (réécrit)
- **Trigger** : Premier render avec `currentTenantId`
- **Mécanisme** : `emitted` ref + `useEffect([currentTenantId])`
- **Guard** : Ref one-shot + in-memory dedup
- **Privacy** : Seul `tenant_id` stocké.

---

## 6. INSTRUMENTATION API

### A. `marketplace_connected` + `first_conversation_received`

- **Fichier** : `src/modules/inbound/routes.ts`
- **Trigger** : Après INSERT d'une NOUVELLE conversation (2 chemins : Amazon et email/MIME)
- **Mécanisme** : `emitActivationEvent(tenantId, 'marketplace_connected')` + `emitActivationEvent(tenantId, 'first_conversation_received')`
- **Idempotence** : `ON CONFLICT DO NOTHING` — émis à chaque nouvelle conversation mais seul le premier est enregistré
- **Non-bloquant** : try/catch silencieux, ne casse jamais le flow inbound

### B. `first_response_sent`

- **Fichier** : `src/modules/messages/routes.ts`
- **Trigger** : Après INSERT d'un message `direction === 'outbound'`
- **Mécanisme** : `emitActivationEvent(tenantId, 'first_response_sent')`
- **Idempotence** : idem
- **Non-bloquant** : idem

### Helper `emitActivationEvent`

- **Fichier** : `src/modules/funnel/routes.ts`
- **Signature** : `emitActivationEvent(tenantId, eventName, source?, opts?)`
- **Résolution funnel_id** : `SELECT funnel_id FROM funnel_events WHERE tenant_id = $1 ORDER BY created_at ASC LIMIT 1` — fallback = `tenantId`
- **Insert** : `ON CONFLICT (funnel_id, event_name) DO NOTHING`

---

## 7. PRIVACY / DATA

| Event | Données stockées | PII | Secrets |
|-------|-----------------|-----|---------|
| `success_viewed` | `tenant_id`, `plan` | ❌ Non | ❌ Non |
| `dashboard_first_viewed` | `tenant_id` | ❌ Non | ❌ Non |
| `onboarding_started` | `tenant_id` | ❌ Non | ❌ Non |
| `marketplace_connected` | `tenant_id` | ❌ Non | ❌ Non |
| `first_conversation_received` | `tenant_id` | ❌ Non | ❌ Non |
| `first_response_sent` | `tenant_id` | ❌ Non | ❌ Non |

- Aucun email, aucun token, aucun secret
- `properties_json` = `{}` par défaut
- Events purement internes — jamais envoyés vers des destinations outbound

---

## 8. VALIDATION DEV

| Cas | Attendu | Résultat |
|-----|---------|----------|
| A — `success_viewed` | `recorded` | ✅ `recorded` (id: `f22f6d0b...`) |
| B — `dashboard_first_viewed` | `recorded` | ✅ `recorded` (id: `c4cabc1a...`) |
| C — `onboarding_started` | `recorded` | ✅ `recorded` (id: `c9c2e518...`) |
| D — `marketplace_connected` | `recorded` | ✅ `recorded` (id: `5124c571...`) |
| E — `first_conversation_received` | `recorded` | ✅ `recorded` (id: `1a44d097...`) |
| F — `first_response_sent` | `recorded` | ✅ `recorded` (id: `824e9fc9...`) |
| G — Idempotence (replay 6 events) | `already_recorded` x6 | ✅ 6/6 `already_recorded` |
| H — GET /funnel/events par funnel_id | 6 events retournés | ✅ 6 events |
| I — GET /funnel/events par tenant_id | Cohort stitching OK | ✅ 6 events pour `ecomlg-001` |
| J — GET /funnel/metrics | 15 steps avec counts | ✅ Funnel complet 15 steps |

---

## 9. PREUVES DB / SQL

### Events de test créés et vérifiés

```
success_viewed              | client | ecomlg-001
dashboard_first_viewed      | client | ecomlg-001
onboarding_started          | client | ecomlg-001
marketplace_connected       | api    | ecomlg-001
first_conversation_received | api    | ecomlg-001
first_response_sent         | api    | ecomlg-001
```

### Idempotence prouvée

6/6 replays retournent `already_recorded` — zéro doublon.

### Non-pollution conversion_events

```
conversion_events: [] (vide)
Activation events in conversion_events: 0 (expected: 0)
```

### Aucune destination outbound

Aucune référence à `conversion_events`, `outbound`, `destination`, `deliverConversion` dans le module funnel.

### Cleanup

6 rows de test supprimées après validation.

---

## 10. NON-RÉGRESSION

| Point | Résultat |
|-------|----------|
| `/register` flow | ✅ Inchangé (instrumentation non-bloquante) |
| `/register/success` | ✅ Polling + trackPurchase + redirect intacts |
| `/dashboard` | ✅ Render + data fetch intacts |
| `/start` | ✅ Render OnboardingHub intact |
| plan/cycle/OAuth continuity | ✅ Inchangé |
| `trackPurchase()` | ✅ Intact (emit avant, non-bloquant) |
| `signup_attribution` | ✅ 6 rows, intact |
| `funnel/events` route | ✅ Fonctionne avec 15 events |
| `funnel/metrics` route | ✅ 15 steps avec conversion rates |
| `conversion_events` | ✅ 0 événements d'activation |
| Outbound conversions | ✅ Intactes (module funnel isolé) |
| Health API DEV | ✅ `{"status":"ok"}` |
| PROD | ✅ **Zéro impact** — images inchangées |
| Admin V2 | ✅ **Zéro impact** — non modifié |

---

## 11. IMAGES DEV

| Service | Avant | Après |
|---------|-------|-------|
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | `v3.5.110-post-checkout-activation-foundation-dev` |
| Client DEV | `v3.5.108-funnel-pretenant-foundation-dev` | `v3.5.110-post-checkout-activation-foundation-dev` |

### Digests

| Image | Digest |
|-------|--------|
| API | `sha256:2d4e945faa3faa59619ff315fb90fcb4b168cc269caa1bf3dd22abf063be11df` |
| Client | `sha256:9896f9e08a1bc446abb013cd0f4ac7dcd9fa5477276aad8d8f69be795f92462e` |

### Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-api | `d004d45e` | PH-T8.9G: post-checkout activation event foundation |
| keybuzz-client | `1db9852` | PH-T8.9G: post-checkout activation instrumentation |
| keybuzz-infra | (this commit) | PH-T8.9G: DEV manifests + report |

---

## 12. ROLLBACK DEV

### API

```yaml
# keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.109-funnel-metrics-tenant-scope-dev
```

### Client

```yaml
# keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml
image: ghcr.io/keybuzzio/keybuzz-client:v3.5.108-funnel-pretenant-foundation-dev
```

---

## 13. GAPS RESTANTS

| # | Gap | Impact | Phase ultérieure |
|---|-----|--------|------------------|
| G1 | `billing_events.tenant_id = NULL` (244 rows) | Impossible de corréler checkout → tenant en DB | Phase dédiée billing fix |
| G2 | `OnboardingWizard` = code mort | Non routé, non utilisé | Décision produit : supprimer ou rebrancher |
| G3 | `OnboardingHub` = checklist statique | Pas d'API, pas de progression réelle | Phase UX onboarding |
| G4 | `activation_completed` non implémenté | Event dérivé (marketplace + conversation) non trivial à formaliser | Phase G2 (agrégation activation metrics) |
| G5 | Filtre `to` funnel = minuit exclusif | Workaround: `to = lendemain` | Phase ultérieure |

---

## 14. DOCUMENTS DE RÉFÉRENCE

| Document | Chemin |
|----------|--------|
| Audit post-checkout | `keybuzz-infra/docs/PH-T8.9F-POST-CHECKOUT-ACTIVATION-FUNNEL-TRUTH-AUDIT-01.md` |
| Audit funnel CRO | `keybuzz-infra/docs/PH-T8.9A-ONBOARDING-FUNNEL-CRO-TRUTH-AUDIT-01.md` |
| Fondation pré-tenant | `keybuzz-infra/docs/PH-T8.9B-PRE-TENANT-FUNNEL-VISIBILITY-FOUNDATION-01.md` |
| Promotion PROD funnel | `keybuzz-infra/docs/PH-T8.9D-FUNNEL-FOUNDATION-PROD-PROMOTION-01.md` |
| **Ce rapport** | `keybuzz-infra/docs/PH-T8.9G-POST-CHECKOUT-ACTIVATION-EVENT-FOUNDATION-01.md` |

---

## VERDICT

**POST-CHECKOUT ACTIVATION EVENT FOUNDATION READY IN DEV — INTERNAL ACTIVATION STEPS CAPTURED — FUNNEL STITCHING PRESERVED — NO ADS POLLUTION — PROD UNTOUCHED**
