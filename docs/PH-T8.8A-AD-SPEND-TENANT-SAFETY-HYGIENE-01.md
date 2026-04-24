# PH-T8.8A — AD SPEND TENANT SAFETY & HYGIENE

> Date : 2026-04-22
> Agent : Cursor Executor (CE)
> Environnement : **DEV uniquement** — PROD inchangée
> Priorité : P0
> Branche API : `ph147.4/source-of-truth`
> Branche Infra : `main`

---

## VERDICT

**AD SPEND TENANT SAFETY RESTORED IN DEV — NO GLOBAL SPEND LEAK IN TENANT METRICS — KEYBUZZ CONSULTING READY FOR TENANT-SCOPED SPEND PILOT**

---

## 0 — PRÉFLIGHT


| Élément               | Valeur                                                         |
| --------------------- | -------------------------------------------------------------- |
| Branche API           | `ph147.4/source-of-truth`                                      |
| HEAD API (avant)      | `df4a2c5e`                                                     |
| HEAD API (après)      | `f4c3d910`                                                     |
| Image API DEV (avant) | `v3.5.101-outbound-destinations-delete-route-dev`              |
| Image API DEV (après) | `v3.5.102-ad-spend-tenant-safety-dev`                          |
| Image API PROD        | `v3.5.101-outbound-destinations-delete-route-prod` (inchangée) |
| Repo API clean        | Oui                                                            |
| Repo Infra clean      | Oui                                                            |
| Rapport T8.8 lu       | Oui                                                            |
| PROD modifiée         | **NON**                                                        |


---

## 1 — AUDIT CODE / DB

### Fichier audité : `src/modules/metrics/routes.ts`


| Point                                      | Résultat | Preuve                                                             |
| ------------------------------------------ | -------- | ------------------------------------------------------------------ |
| `tenant_id` filtre spend ?                 | **NON**  | Requête `FROM ad_spend` sans filtre tenant (L173-178 original)     |
| CAC tenant utilise spend global ?          | **OUI**  | `totalSpendEur / signups` calculé avec le spend global             |
| ROAS tenant utilise spend global ?         | **OUI**  | `revenue / totalSpendEur` calculé avec le spend global             |
| Import Meta écrit dans `ad_spend` global ? | **OUI**  | `INSERT INTO ad_spend` sans `tenant_id`                            |
| Token Meta exposé dans réponse API ?       | **NON**  | Token utilisé dans `fetchMetaInsights` uniquement, jamais retourné |


### Risque critique confirmé

Quand `/metrics/overview?tenant_id=X` est appelé :

- Customers, Revenue, Conversion sont correctement filtrés par tenant
- **Spend** est lu depuis `ad_spend` SANS filtre tenant → 100% du spend KeyBuzz global fuit dans les KPIs tenant
- **CAC** = spend GLOBAL / signups TENANT → valeur aberrante
- **ROAS** = revenue TENANT / spend GLOBAL → valeur aberrante

---

## 2 — SCHÉMA DEV TENANT-SPEND

### Table `ad_platform_accounts` (créée)


| Colonne      | Type                        | Description                               |
| ------------ | --------------------------- | ----------------------------------------- |
| id           | UUID PK                     | gen_random_uuid()                         |
| tenant_id    | TEXT NOT NULL               | Tenant propriétaire                       |
| platform     | TEXT NOT NULL               | meta, google, tiktok, etc.                |
| account_id   | TEXT NOT NULL               | ID compte plateforme                      |
| account_name | TEXT                        | Nom lisible                               |
| currency     | TEXT DEFAULT 'EUR'          | Devise du compte                          |
| timezone     | TEXT DEFAULT 'Europe/Paris' | Fuseau horaire                            |
| token_ref    | TEXT                        | Référence chiffrée (jamais le token brut) |
| status       | TEXT DEFAULT 'active'       | active, paused, revoked                   |
| last_sync_at | TIMESTAMPTZ                 | Dernière sync réussie                     |
| last_error   | TEXT                        | Dernière erreur                           |
| created_by   | TEXT NOT NULL               | Auteur                                    |
| created_at   | TIMESTAMPTZ                 | Auto                                      |
| updated_at   | TIMESTAMPTZ                 | Auto                                      |
| deleted_at   | TIMESTAMPTZ                 | Soft delete                               |


**Index unique** : `(tenant_id, platform, account_id) WHERE deleted_at IS NULL`

### Table `ad_spend_tenant` (créée)


| Colonne        | Type                   | Description               |
| -------------- | ---------------------- | ------------------------- |
| id             | UUID PK                | gen_random_uuid()         |
| tenant_id      | TEXT NOT NULL          | Tenant propriétaire       |
| account_id     | UUID FK                | Réf. ad_platform_accounts |
| platform       | TEXT NOT NULL          | meta, google, etc.        |
| campaign_id    | TEXT                   | ID campagne (optionnel)   |
| campaign_name  | TEXT                   | Nom campagne              |
| adset_id       | TEXT                   | ID adset (optionnel)      |
| adset_name     | TEXT                   | Nom adset                 |
| date           | DATE NOT NULL          | Date du spend             |
| spend          | NUMERIC(12,4) NOT NULL | Montant dépensé           |
| spend_currency | TEXT DEFAULT 'EUR'     | Devise                    |
| impressions    | INTEGER DEFAULT 0      | Impressions               |
| clicks         | INTEGER DEFAULT 0      | Clics                     |
| conversions    | INTEGER DEFAULT 0      | Conversions               |
| created_at     | TIMESTAMPTZ            | Auto                      |


**Index unique (dedup)** : `(tenant_id, platform, date, COALESCE(campaign_id, '__none__'))`
**Index** : `(tenant_id, date DESC)`
**Index** : `(account_id)`

---

## 3 — BACKFILL DEV KEYBUZZ CONSULTING


| Source              | Rows | Tenant cible                  | Spend total | Currency | Résultat                     |
| ------------------- | ---- | ----------------------------- | ----------- | -------- | ---------------------------- |
| `ad_spend` (global) | 16   | `keybuzz-consulting-mo9y479d` | 445.20      | GBP      | Migré vers `ad_spend_tenant` |


- Compte `ad_platform_accounts` créé : `e4c2ed4e-7a63-4c6b-a614-f944405567ed`
- Platform : `meta`
- Account ID Meta : `1485150039295668`
- Marqué comme migration legacy : `created_by = 'system-migration-ph-t8.8a'`
- Toutes les 16 rows migrées avec ON CONFLICT idempotent

---

## 4 — PATCH /metrics/overview

### Comportement après patch


| Mode                            | Source spend                 | Comportement                   |
| ------------------------------- | ---------------------------- | ------------------------------ |
| **Global** (sans `tenant_id`)   | `ad_spend`                   | Inchangé — vue agrégée globale |
| **Tenant** (avec `tenant_id=X`) | `ad_spend_tenant` uniquement | **JAMAIS** `ad_spend` global   |


### Champs ajoutés dans la réponse spend

```json
{
  "spend": {
    "total_eur": 512.29,
    "source": "ad_spend_tenant",
    "scope": "tenant",
    "spend_available": true,
    "warnings": []
  }
}
```

### Résultats de validation


| Cas                | Attendu                                         | Résultat                                             |
| ------------------ | ----------------------------------------------- | ---------------------------------------------------- |
| Global sans tenant | spend.source=ad_spend_global, CAC/ROAS calculés | **OK** — total_eur=512.29, cac=512.29, roas=0.97     |
| ecomlg-001 tenant  | spend=0, pas de global leak                     | **OK** — source=no_data, scope=tenant, cac=null      |
| Tenant inexistant  | 0 propre, pas de NaN                            | **OK** — total_eur=0, cac=null, roas=null, aucun NaN |
| KeyBuzz Consulting | spend tenant depuis ad_spend_tenant             | **OK** — source=ad_spend_tenant, total_eur=512.29    |


---

## 5 — PATCH /metrics/import/meta

### Comportement après patch


| Mode                                 | Comportement                              |
| ------------------------------------ | ----------------------------------------- |
| Sans `tenant_id`                     | Écrit dans `ad_spend` global (inchangé)   |
| Avec `tenant_id` + compte Meta actif | Écrit dans `ad_spend_tenant` uniquement   |
| Avec `tenant_id` sans compte Meta    | **400 TENANT_SCOPED_AD_ACCOUNT_REQUIRED** |


### Résultats de validation


| Cas                      | HTTP    | target          | imported |
| ------------------------ | ------- | --------------- | -------- |
| Import global            | 200     | ad_spend_global | 16       |
| Import KBC tenant        | 200     | ad_spend_tenant | 16       |
| Import tenant inexistant | **400** | —               | —        |


---

## 6 — HYGIÈNE DESTINATIONS

### DEV


| ID       | Tenant             | Type      | is_active | deleted_at | État           |
| -------- | ------------------ | --------- | --------- | ---------- | -------------- |
| 0a573633 | ecomlg-001         | webhook   | false     | 2026-04-22 | Soft deleted ✓ |
| d3302752 | ecomlg-001         | meta_capi | false     | 2026-04-22 | Soft deleted ✓ |
| f0a9d8cb | ecomlg-001         | webhook   | false     | 2026-04-22 | Soft deleted ✓ |
| b5404bd6 | ecomlg-001         | meta_capi | false     | 2026-04-22 | Soft deleted ✓ |
| a50d9402 | keybuzz-consulting | webhook   | false     | 2026-04-22 | Soft deleted ✓ |
| 166fd366 | keybuzz-consulting | meta_capi | false     | 2026-04-22 | Soft deleted ✓ |


**DEV propre** : 6 destinations, toutes `is_active=false` + `deleted_at` set. Aucune destination active.

### PROD (lecture seule)


| ID       | Tenant             | Type      | is_active | deleted_at | Action requise            |
| -------- | ------------------ | --------- | --------- | ---------- | ------------------------- |
| 291a5797 | ecomlg-001         | meta_capi | false     | **null**   | Soft-delete en phase PROD |
| 28cbc2be | ecomlg-001         | meta_capi | false     | **null**   | Soft-delete en phase PROD |
| 7464753d | ecomlg-001         | meta_capi | false     | **null**   | Soft-delete en phase PROD |
| 48dc53c2 | ecomlg-001         | webhook   | false     | 2026-04-22 | OK ✓                      |
| ba40f5ce | ecomlg-001         | meta_capi | false     | 2026-04-22 | OK ✓                      |
| 5b96f0d1 | ecomlg-001         | webhook   | false     | 2026-04-22 | OK ✓                      |
| 4b7ae65e | ecomlg-001         | meta_capi | false     | 2026-04-22 | OK ✓                      |
| 16c2dd43 | keybuzz-consulting | webhook   | false     | 2026-04-22 | OK ✓                      |
| f768d05f | keybuzz-consulting | meta_capi | false     | 2026-04-22 | OK ✓                      |


**Plan cleanup PROD** : 3 destinations `ecomlg-001` meta_capi avec `deleted_at=null` à soft-delete lors de la phase PH-T8.8A-PROD-PROMOTION.

---

## 7 — IMAGE DEV


| Élément             | Valeur                                                                    |
| ------------------- | ------------------------------------------------------------------------- |
| Tag                 | `v3.5.102-ad-spend-tenant-safety-dev`                                     |
| Digest              | `sha256:5178f39c5df537a7d0cb1b5c726bc3a9a289c76ff63d799eeaa0ce1e32c42601` |
| Build source        | Commit `f4c3d910` (branche `ph147.4/source-of-truth`)                     |
| Build method        | `docker build --no-cache`                                                 |
| Repo clean au build | Oui                                                                       |
| Commit infra        | `912045e` (keybuzz-infra main)                                            |
| Restarts            | 0                                                                         |


### Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-dev -n keybuzz-api-dev
```

---

## 8 — ÉTAT PROD


| Vérification                 | Résultat                                                       |
| ---------------------------- | -------------------------------------------------------------- |
| Image API PROD               | `v3.5.101-outbound-destinations-delete-route-prod` (inchangée) |
| Code PROD modifié            | **NON**                                                        |
| Tables PROD ajoutées         | **NON**                                                        |
| Destinations PROD supprimées | **NON**                                                        |
| Backfill PROD                | **NON**                                                        |


---

## 9 — PREUVES ANTI-FUITE TENANT


| Preuve                                        | Résultat                                                |
| --------------------------------------------- | ------------------------------------------------------- |
| `ecomlg-001` ne voit PAS le spend global      | ✓ — spend.source=no_data, total_eur=0                   |
| `ecomlg-001` CAC ≠ global CAC                 | ✓ — cac=null (pas de spend tenant)                      |
| `ecomlg-001` ROAS ≠ global ROAS               | ✓ — roas=null (pas de spend tenant)                     |
| KeyBuzz Consulting voit SON spend tenant      | ✓ — source=ad_spend_tenant, total_eur=512.29            |
| Tenant inexistant = 0, pas NaN                | ✓ — total_eur=0, cac=null, roas=null                    |
| Token Meta absent des réponses API            | ✓ — jamais retourné dans aucun endpoint                 |
| Import tenant sans compte = 400               | ✓ — TENANT_SCOPED_AD_ACCOUNT_REQUIRED                   |
| `ad_spend` global inaccessible en mode tenant | ✓ — code ne requête jamais ad_spend quand tenant_id set |


---

## 10 — PROCHAIN PLAN RECOMMANDÉ

### Phase PH-T8.8A-PROD-PROMOTION (recommandée)

1. Créer tables `ad_platform_accounts` + `ad_spend_tenant` en PROD
2. Backfiller `ad_spend` → `ad_spend_tenant` pour KeyBuzz Consulting PROD
3. Builder + déployer `v3.5.102-ad-spend-tenant-safety-prod`
4. Soft-delete les 3 destinations PROD orphelines (`291a5797`, `28cbc2be`, `7464753d`)
5. Validation PROD complète

### Phase PH-T8.8B — Inbound Collector (future)

- Connecteur d'import automatique Meta Ads → `ad_spend_tenant`
- Configuration par tenant via `ad_platform_accounts`
- Scheduler de sync périodique

---

## COMMITS


| Repo          | Hash       | Message                                                                                 |
| ------------- | ---------- | --------------------------------------------------------------------------------------- |
| keybuzz-api   | `f4c3d910` | PH-T8.8A: ad spend tenant safety — metrics overview uses ad_spend_tenant in tenant mode |
| keybuzz-infra | `912045e`  | PH-T8.8A: DEV deploy ad spend tenant safety — v3.5.102-ad-spend-tenant-safety-dev       |


