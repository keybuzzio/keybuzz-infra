# PH-T8.7A — Marketing Tenant Attribution Foundation

> Date : 22 avril 2026
> Environnement : **DEV UNIQUEMENT**
> Branche : `ph147.4/source-of-truth`
> Commit : `db14cb03`
> Image DEV : `ghcr.io/keybuzzio/keybuzz-api:v3.5.97-marketing-tenant-foundation-dev`
> Digest : `sha256:231bee30181eabe9fd84545160aa11a70c0cf3c3ec59c7857b3ed36d1c0a52a9`
> PROD : **INCHANGÉE** (`v3.5.95-outbound-destinations-api-prod`)

---

## Objectif

Rendre le pipeline marketing server-side tenant-native de bout en bout :

- Attribution, events outbound, destinations, métriques alignés sur un `tenant_id` explicite
- Aucune ambiguïté sur le rattachement d'un événement à un tenant
- Préparation du framework pour les connecteurs plateforme-natifs (Meta, TikTok, Google, LinkedIn)

---

## 1. Audit Complet

Voir : `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md`

### Résumé


| Composant                                         | Tenant-native avant | Tenant-native après     | Action       |
| ------------------------------------------------- | ------------------- | ----------------------- | ------------ |
| `signup_attribution`                              | OUI                 | OUI                     | Aucune       |
| StartTrial / Purchase events                      | OUI                 | OUI                     | Aucune       |
| Emitter (`emitOutboundConversion`)                | OUI                 | OUI                     | Aucune       |
| Destinations (`outbound_conversion_destinations`) | OUI                 | OUI                     | Aucune       |
| Test exclusion                                    | OUI                 | OUI                     | Aucune       |
| `**/metrics/overview`**                           | **NON (global)**    | **OUI (tenant-scoped)** | **PATCHÉ**   |
| Delivery logs                                     | OUI (indirect)      | OUI                     | Aucune       |
| `ad_spend`                                        | NON (global)        | NON (par design)        | Phase future |


---

## 2. Source de Vérité Tenant Marketing

**La source de vérité tenant marketing officielle est le `tenant_id` canonical**, utilisé dans :

1. `signup_attribution.tenant_id` — attribution à la création du compte
2. `session.metadata.tenant_id` — checkout Stripe (défini par le backend)
3. `emitOutboundConversion(eventName, tenantId, ...)` — paramètre explicite
4. `outbound_conversion_destinations.tenant_id` — destinations scopées par tenant
5. `conversion_events.tenant_id` — idempotence des events
6. `/metrics/overview?tenant_id=X` — métriques filtrées par tenant

**Règle unique** : tout événement marketing est rattaché au `tenant_id` canonical via la chaîne `signup → Stripe metadata → emitter → destination → logs`.

---

## 3. Business Events Alignés

### Avant / Après


| Event           | Avant                                                  | Après    | Impact BC |
| --------------- | ------------------------------------------------------ | -------- | --------- |
| StartTrial      | `tenantId` explicite dans payload `customer.tenant_id` | Inchangé | Aucun     |
| Purchase        | `tenantId` explicite dans payload `customer.tenant_id` | Inchangé | Aucun     |
| Idempotence key | `conv_${tenantId}_${eventName}_${subId}`               | Inchangé | Aucun     |


Les events étaient déjà tenant-native. Aucune modification nécessaire.

---

## 4. `/metrics/overview` Tenant-Scoped

### Modification

Ajout du paramètre query optionnel `tenant_id` à `/metrics/overview`.

**Fichier modifié** : `src/modules/metrics/routes.ts`

### Comportement


| Mode              | Paramètre             | Résultat                                   |
| ----------------- | --------------------- | ------------------------------------------ |
| Global            | Aucun `tenant_id`     | Toutes les données (comportement existant) |
| Tenant A          | `?tenant_id=tenant-a` | Données filtrées pour tenant A uniquement  |
| Tenant B          | `?tenant_id=tenant-b` | Données filtrées pour tenant B uniquement  |
| Tenant inexistant | `?tenant_id=xyz`      | 0 partout (pas d'erreur)                   |


### Champs ajoutés à la réponse

```json
{
  "scope": "global" | "tenant",
  "tenant_id": null | "tenant-id-value",
  ...
}
```

### SQL modifié

Chaque requête SQL (customers, conversion rate, revenue, customers by plan) inclut désormais :

```sql
AND ($N::text IS NULL OR t.id = $N)
```

Quand `tenant_id` est `null`, le filtre est un no-op. Quand il est fourni, seul ce tenant est inclus.

### Limitation connue

`ad_spend` reste global — cette table n'a pas de colonne `tenant_id` (la dépense publicitaire est au niveau SaaS, pas par tenant). Le CAC/ROAS restent donc globaux même en mode tenant-scoped.

---

## 5. Sécurité Tenant → Destinations

### Preuves de non-fuite cross-tenant


| Couche                    | Mécanisme                                             | Preuve                                                    |
| ------------------------- | ----------------------------------------------------- | --------------------------------------------------------- |
| `getActiveDestinations()` | `WHERE tenant_id = $1 AND is_active = true`           | Un tenant ne reçoit QUE ses destinations                  |
| `sendToDestination()`     | Reçoit la destination déjà filtrée                    | Pas de requête DB supplémentaire                          |
| RBAC destinations API     | `checkAccess()` vérifie `user_tenants`                | Un user ne peut gérer que les destinations de ses tenants |
| Idempotence               | Clé `conv_${tenantId}_${event}_${sub}`                | Pas de collision inter-tenant                             |
| Delivery logs             | Via `destination_id` (FK) → destination → `tenant_id` | Logs liés au bon tenant                                   |
| Test cross-tenant (T7)    | `tenant-does-not-exist` → "Insufficient permissions"  | **Confirmé en DEV**                                       |


---

## 6. Framework Platform-Native (Préparation)

### Modèle cible

La table `outbound_conversion_destinations` est préparée pour les connecteurs natifs :


| Colonne               | Type | Statut        | Usage                                                                                   |
| --------------------- | ---- | ------------- | --------------------------------------------------------------------------------------- |
| `destination_type`    | TEXT | **Existante** | `webhook` (défaut), futur : `meta_capi`, `tiktok_events`, `google_ads`, `linkedin_capi` |
| `platform_account_id` | TEXT | **AJOUTÉE**   | ID compte plateforme (ex: Meta Ad Account ID)                                           |
| `platform_pixel_id`   | TEXT | **AJOUTÉE**   | ID pixel/événement (ex: Meta Pixel ID, TikTok Pixel)                                    |
| `platform_token_ref`  | TEXT | **AJOUTÉE**   | Référence au token d'accès (Vault path ou encrypted ref)                                |
| `mapping_strategy`    | TEXT | **AJOUTÉE**   | Stratégie de mapping : `direct` (défaut), `custom`                                      |


### Types de destination prévus

```typescript
const DESTINATION_TYPES = [
  'webhook',        // Webhook générique (actuel)
  'meta_capi',      // Meta Conversions API
  'tiktok_events',  // TikTok Events API
  'google_ads',     // Google Ads Enhanced Conversions
  'linkedin_capi',  // LinkedIn Conversions API
] as const;
```

### Ce qui est prêt pour les phases suivantes

- Schema DB avec colonnes platform-native
- Enum `DESTINATION_TYPES` dans le code
- Type TypeScript `DestinationType`
- `destination_type` dynamique à la création (plus hardcodé `'webhook'`)
- Chaque destination est déjà tenant-scoped

### Ce qui reste à faire (phases PH-T8.7B+)

- Implémentation des adapters par plateforme (Meta CAPI, TikTok Events, etc.)
- Logic de mapping event → platform payload
- Gestion des tokens plateforme (Vault)
- UI Admin pour configurer les destinations natives

---

## 7. Validation DEV


| Cas                             | Attendu                           | Résultat                                                                                |
| ------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------- |
| T1: Health                      | `status: ok`                      | **OK**                                                                                  |
| T2: Metrics global              | `scope: global`, données agrégées | **OK** — 1 client, MRR=497, 19 test exclus                                              |
| T3: Metrics tenant (ecomlg-001) | `scope: tenant`, données filtrées | **OK** — 0 (exempt)                                                                     |
| T4: Metrics tenant inexistant   | `scope: tenant`, 0 partout        | **OK**                                                                                  |
| T5: Destinations list           | Liste pour ecomlg-001             | **OK** — vide (aucune configurée)                                                       |
| T6: Platform columns            | 4 colonnes ajoutées               | **OK** — `mapping_strategy, platform_account_id, platform_pixel_id, platform_token_ref` |
| T7: Cross-tenant safety         | Rejet pour tenant étranger        | **OK** — "Insufficient permissions"                                                     |
| T8: Billing                     | Plan PRO active                   | **OK**                                                                                  |
| T9: PROD inchangée              | Image PROD non modifiée           | **OK** — `v3.5.95-outbound-destinations-api-prod`                                       |


---

## 8. Non-Régression


| Domaine                   | Résultat | Détail                                                       |
| ------------------------- | -------- | ------------------------------------------------------------ |
| Health                    | **OK**   | `status: ok`                                                 |
| Stripe webhooks           | **OK**   | Code inchangé dans `billing/routes.ts` (handler non modifié) |
| Billing                   | **OK**   | `ecomlg-001` = PRO active                                    |
| Metrics globales          | **OK**   | Réponse identique sans `tenant_id`                           |
| Outbound conversions      | **OK**   | Emitter inchangé                                             |
| Destinations self-service | **OK**   | API fonctionnelle, RBAC actif                                |
| Test exclusion            | **OK**   | 19 comptes test exclus dans metrics                          |
| Trial vs Paid             | **OK**   | Distinction maintenue dans metrics                           |


---

## 9. Image DEV


| Élément    | Valeur                                                                    |
| ---------- | ------------------------------------------------------------------------- |
| Tag        | `v3.5.97-marketing-tenant-foundation-dev`                                 |
| Digest     | `sha256:231bee30181eabe9fd84545160aa11a70c0cf3c3ec59c7857b3ed36d1c0a52a9` |
| Commit     | `db14cb03`                                                                |
| Branche    | `ph147.4/source-of-truth`                                                 |
| Repo clean | OUI                                                                       |
| Build      | `docker build --no-cache` depuis bastion                                  |


---

## 10. Rollback DEV

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.96-admin-bypass-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 11. État PROD

**INCHANGÉ**. Image PROD = `v3.5.95-outbound-destinations-api-prod`. Aucun manifest PROD modifié.

---

## 12. Documents lus


| Document                                            | Trouvé ?        |
| --------------------------------------------------- | --------------- |
| `PH-T8.2E-PROD-PROMOTION-METRICS-01.md`             | OUI             |
| `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`               | OUI             |
| `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md` | OUI             |
| `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`  | OUI             |
| `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`              | OUI             |
| `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`          | OUI             |
| `PH-T8.6C-SAAS-PROD-PROMOTION-01.md`                | OUI             |
| `PH-ADMIN-TENANT-FOUNDATION-01.md`                  | OUI (référencé) |
| `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`   | OUI (référencé) |


---

## Fichiers modifiés


| Fichier                                             | Modification                                                                                              |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `src/modules/metrics/routes.ts`                     | Ajout `tenant_id` query param, filtre SQL conditionnel, `scope` + `tenant_id` dans la réponse             |
| `src/modules/outbound-conversions/routes.ts`        | Ajout `DESTINATION_TYPES`, colonnes platform-native (ALTER TABLE), `destination_type` dynamique au CREATE |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image → `v3.5.97-marketing-tenant-foundation-dev`                                                         |


---

## VERDICT

**MARKETING TENANT FOUNDATION READY — EVENTS + METRICS + DESTINATIONS ALIGNED — MULTI-TENANT SAFE — DEV ONLY**