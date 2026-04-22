# PH-T8.8A.2 — AD SPEND TENANT SAFETY — PROD PROMOTION

> Date : 2026-04-23
> Agent : Cursor Executor (CE)
> Environnement : **PROD**
> Priorité : P0
> Branche API : `ph147.4/source-of-truth`
> Branche Infra : `main`
> Prérequis : PH-T8.8A (DEV) + PH-T8.8A.1 (DEV)

---

## VERDICT

**AD SPEND TENANT SAFETY LIVE IN PROD — GLOBAL IMPORT LOCKED — KEYBUZZ CONSULTING TENANT SPEND READY — ORPHAN DESTINATIONS CLEANED**

---

## 0 — PRÉFLIGHT

| Élément | Valeur |
|---------|--------|
| HEAD API | `954eea74` ✓ |
| Image DEV validée | `v3.5.103-ad-spend-global-import-lock-dev` ✓ |
| Image PROD (avant) | `v3.5.101-outbound-destinations-delete-route-prod` |
| Image PROD (après) | `v3.5.103-ad-spend-global-import-lock-prod` |
| Repo API clean | Oui ✓ |
| Repo Infra clean | Oui ✓ |
| Rapport T8.8A lu | Oui ✓ |
| Rapport T8.8A.1 lu | Oui ✓ |

---

## 1 — VÉRIFICATION SOURCE

| Check | Résultat |
|-------|----------|
| `/metrics/overview?tenant_id=X` lit `ad_spend_tenant` | ✓ L178, L405 |
| `/metrics/overview?tenant_id=X` ne lit jamais `ad_spend` global | ✓ `FROM ad_spend` uniquement en mode global (L220) |
| Import sans `tenant_id` → 400 TENANT_ID_REQUIRED | ✓ L429 |
| 0 `INSERT INTO ad_spend` global | ✓ 0 occurrences |
| `INSERT INTO ad_spend_tenant` présent | ✓ L389 |
| `TENANT_SCOPED_AD_ACCOUNT_REQUIRED` présent | ✓ L365 |
| Token jamais retourné en réponse API | ✓ Utilisé uniquement dans `fetchMetaInsights` |

---

## 2 — TABLES PROD

| Table | Existe | Index OK | Rows |
|-------|--------|----------|------|
| `ad_platform_accounts` | ✓ | 3 (PK + tenant + unique tenant/platform/account) | 1 |
| `ad_spend_tenant` | ✓ | 4 (PK + dedup + tenant_date + account) | 16 |

Indexes créés :
- `ad_platform_accounts_pkey`
- `idx_apa_tenant`
- `idx_apa_tenant_platform_account`
- `ad_spend_tenant_pkey`
- `idx_ast_dedup`
- `idx_ast_tenant_date`
- `idx_ast_account`

Migrations idempotentes (`CREATE TABLE IF NOT EXISTS`, `CREATE UNIQUE INDEX IF NOT EXISTS`).

---

## 3 — BACKFILL PROD KEYBUZZ CONSULTING

| Source | Rows | Tenant cible | Spend total | Currency | Résultat |
|--------|------|--------------|-------------|----------|----------|
| `ad_spend` (global) | 16 | `keybuzz-consulting-mo9zndlk` | 445.20 | GBP | Migré vers `ad_spend_tenant` ✓ |

- Tenant PROD vérifié : `keybuzz-consulting-mo9zndlk` (KeyBuzz Consulting, AUTOPILOT, active)
- Compte `ad_platform_accounts` créé : `b8b89a18-aa86-4e34-9488-b53fc404b96a`
- Platform : `meta`
- Account ID Meta : `1485150039295668`
- `created_by` : `system-migration-ph-t8.8a-prod`
- 16 rows migrées, ON CONFLICT idempotent

---

## 4 — CLEANUP DESTINATIONS PROD ORPHELINES

| ID | Tenant | Type | Avant | Après | Résultat |
|----|--------|------|-------|-------|----------|
| `291a5797` | ecomlg-001 | meta_capi | is_active=false, deleted_at=null | deleted_at=NOW(), deleted_by=system-cleanup | ✓ Soft-deleted |
| `28cbc2be` | ecomlg-001 | meta_capi | is_active=false, deleted_at=null | deleted_at=NOW(), deleted_by=system-cleanup | ✓ Soft-deleted |
| `7464753d` | ecomlg-001 | meta_capi | is_active=false, deleted_at=null | deleted_at=NOW(), deleted_by=system-cleanup | ✓ Soft-deleted |

- Pré-check effectué : tenant, type, is_active, deleted_at vérifiés
- `deleted_by` : `system-cleanup-ph-t8.8a-prod`
- Orphans restants après cleanup : **0**
- Toutes les 9 destinations PROD sont désormais soft-deleted

---

## 5 — IMAGE PROD

| Élément | Valeur |
|---------|--------|
| Tag | `v3.5.103-ad-spend-global-import-lock-prod` |
| Digest | `sha256:9acd6b518535d49c858e0375852ae04a5ca4d11edf44f086230e108f42f7ed84` |
| Build source | Commit `954eea74` (branche `ph147.4/source-of-truth`) |
| Build method | `docker build --no-cache` |
| Repo clean au build | Oui |
| Commit infra | `73be006` (keybuzz-infra main) |
| Restarts | 0 |

### Contenu cumulé

| Feature | Description |
|---------|-------------|
| PH-T8.8A | `/metrics/overview?tenant_id=X` lit `ad_spend_tenant` uniquement |
| PH-T8.8A.1 | `/metrics/import/meta` sans `tenant_id` → 400 |
| PH-T8.8A.1 | Import tenant écrit dans `ad_spend_tenant` uniquement |
| Cumul | CAC/ROAS tenant calculés avec spend tenant, jamais global |

---

## 8 — VALIDATION PROD MÉTRIQUES

| Cas | Attendu | Résultat |
|-----|---------|----------|
| Overview global | spend.source=ad_spend_global | ✓ total_eur=512.29 |
| Overview ecomlg-001 | pas de global leak | ✓ source=no_data, scope=tenant, total_eur=0 |
| Overview KeyBuzz Consulting | spend tenant | ✓ source=ad_spend_tenant, total_eur=512.29 |
| Overview tenant inexistant | 0 propre, pas NaN | ✓ total_eur=0, cac=null, roas=null |
| Token brut absent | aucun EAA* | ✓ absent |

---

## 9 — VALIDATION PROD IMPORT META

| Cas | HTTP | Résultat |
|-----|------|----------|
| Import sans tenant_id | **400** | TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT ✓ |
| Import tenant inexistant | **400** | TENANT_SCOPED_AD_ACCOUNT_REQUIRED ✓ |
| Import KeyBuzz Consulting | **200** | target=ad_spend_tenant, imported=16 ✓ |

### Preuve anti-write global

| Métrique | Avant import | Après import |
|----------|-------------|-------------|
| `ad_spend` rows | 16 | **16** (inchangé) |
| `ad_spend_tenant` rows | 16 | 16 (upsert idempotent) |

---

## 10 — NON-RÉGRESSION PROD

| Check | Résultat |
|-------|----------|
| Health API | ✓ `{"status":"ok"}` |
| Billing | ✓ OK |
| Outbound destinations visible | ✓ 0 (toutes soft-deleted) |
| Token sanitization delivery logs | ✓ Aucun token |
| DEV inchangé | ✓ `v3.5.103-ad-spend-global-import-lock-dev` |
| Admin V2 non modifié | ✓ |
| Client SaaS non modifié | ✓ |

---

## 11 — ROLLBACK PROD

### Procédure GitOps uniquement

1. Modifier `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
2. Remettre l'image précédente :

```yaml
image: ghcr.io/keybuzzio/keybuzz-api:v3.5.101-outbound-destinations-delete-route-prod
```

3. Commit + push keybuzz-infra
4. `kubectl apply -f` le manifest
5. Vérifier rollout

**AUCUN `kubectl set image` autorisé.**

### Note

Les tables `ad_platform_accounts` et `ad_spend_tenant` resteront en PROD même après rollback. L'image `v3.5.101` ne les utilise pas et ignore leur existence. Le rollback est safe.

---

## COMMITS

| Repo | Hash | Message |
|------|------|---------|
| keybuzz-api | `954eea74` | PH-T8.8A.1: lock global ad spend import |
| keybuzz-infra | `73be006` | PH-T8.8A.2: PROD deploy ad spend tenant safety + global import lock |

---

## HISTORIQUE IMAGES

| Env | Avant | Après |
|-----|-------|-------|
| DEV | `v3.5.103-ad-spend-global-import-lock-dev` | Inchangé |
| PROD | `v3.5.101-outbound-destinations-delete-route-prod` | `v3.5.103-ad-spend-global-import-lock-prod` |

---

## PROCHAINES ÉTAPES RECOMMANDÉES

### PH-T8.8B — Inbound Collector (future)

- Connecteur d'import automatique Meta Ads → `ad_spend_tenant`
- Configuration par tenant via `ad_platform_accounts`
- Scheduler de sync périodique
- UI Admin V2 pour gérer les comptes ads

### PH-T8.8C — Multi-platform (future)

- Support Google Ads, TikTok Ads via `ad_platform_accounts`
- Import tenant-scoped pour chaque plateforme
- Dashboard spend multi-plateforme par tenant
