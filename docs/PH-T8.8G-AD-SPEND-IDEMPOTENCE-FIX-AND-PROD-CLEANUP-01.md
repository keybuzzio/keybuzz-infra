# PH-T8.8G — AD SPEND IDEMPOTENCE FIX AND PROD CLEANUP

> Date : 2026-04-26
> Auteur : CE SaaS (Agent Cursor)
> Environnements : DEV + PROD
> Type : fix idempotence + cleanup chirurgical PROD
> Priorité : CRITIQUE

---

## RÉSUMÉ

Correction définitive des doublons logiques `ad_spend_tenant` causés par deux chemins d'import Meta Ads concurrents, puis nettoyage chirurgical des 8 lignes PROD doublonnées.

**Avant** : KBC PROD = 760.76 GBP (gonflé 71%)
**Après** : KBC PROD = 445.20 GBP (correct)

---

## PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| Commit initial | `808f2dae` (PH-T8.8E) |
| Image API DEV avant | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| Image API PROD avant | `v3.5.106-metrics-settings-currency-exclusion-prod` |
| Repo | clean |
| Rapport PH-T8.8F | relu et validé |

---

## DÉCISION TECHNIQUE — OPTION A

**Choix : déprécier strictement le chemin d'écriture tenant de `/metrics/import/meta`.**

### Justification

Les deux chemins d'import écrivaient dans `ad_spend_tenant` avec des granularités différentes :

| Chemin | campaign_id | Index COALESCE |
|---|---|---|
| `/metrics/import/meta` (legacy) | `NULL` | `'__none__'` |
| `/ad-accounts/:id/sync` (canonique) | `120241837833890344` | `120241837833890344` |

L'index unique `idx_ast_dedup` sur `(tenant_id, platform, date, COALESCE(campaign_id, '__none__'))` traitait ces deux valeurs comme distinctes, permettant deux lignes par jour avec le même spend.

### Comportement après fix

| Cas | Réponse |
|---|---|
| `POST /import/meta` sans `tenant_id` | `400 TENANT_ID_REQUIRED` (inchangé) |
| `POST /import/meta` avec `tenant_id` | `410 DEPRECATED_META_IMPORT_USE_AD_ACCOUNT_SYNC` |
| `POST /ad-accounts/:id/sync` | fonctionne normalement (chemin canonique) |

---

## PATCH

**Fichier** : `src/modules/metrics/routes.ts`

**Changement** : le bloc `if (tenantId)` dans le handler `POST /import/meta` est remplacé par un retour `410 DEPRECATED` immédiat. Zéro write dans `ad_spend_tenant` depuis ce chemin.

**Diff** : 4 insertions, 68 suppressions

**Commit** : `3207caf4`

```
PH-T8.8G: deprecate /import/meta tenant write path — returns 410 DEPRECATED_META_IMPORT_USE_AD_ACCOUNT_SYNC,
zero writes to ad_spend_tenant from legacy route, canonical sync is /ad-accounts/:id/sync only,
prevents duplicate rows from mismatched campaign_id granularity
```

---

## VALIDATION DEV

| Cas | Attendu | Résultat |
|---|---|---|
| A — import/meta sans tenant_id | 400 TENANT_ID_REQUIRED | ✅ |
| B — import/meta avec tenant_id KBC DEV | 410 DEPRECATED | ✅ |
| C — /ad-accounts KBC DEV | OK, token (encrypted) | ✅ |
| D — duplicate check DEV | 0 doublons, 16 rows, 445.20 GBP | ✅ |
| E — health | OK | ✅ |

---

## IMAGES

| Env | Tag | Digest | Commit |
|---|---|---|---|
| DEV | `v3.5.107-ad-spend-idempotence-fix-dev` | `sha256:2e5d5666dd92f4cb52bc61746f0941a30bb9cfb80de233eca2e7454865f21b5f` | `3207caf4` |
| PROD | `v3.5.107-ad-spend-idempotence-fix-prod` | `sha256:4f49a7486a8fef2d34b01cb2b39535104647823b7e1f38f95692a8282acdc096` | `3207caf4` |

---

## BACKUP PROD (avant cleanup)

**24 lignes** sauvegardées avec IDs, dates, montants, campaign_id, created_at.

Total avant : **760.76 GBP** (24 rows)

### Lignes legacy identifiées pour suppression

| Date | ID | Spend | campaign_id | created_at |
|---|---|---|---|---|
| 2026-03-24 | ad5dec8d... | 37.42 | NULL | 2026-04-22T23:29:39 |
| 2026-03-25 | 6e6c1f1a... | 40.57 | NULL | 2026-04-22T23:29:39 |
| 2026-03-26 | 52651ad9... | 41.92 | NULL | 2026-04-22T23:29:39 |
| 2026-03-27 | bd87a18c... | 39.69 | NULL | 2026-04-22T23:29:39 |
| 2026-03-28 | dc634373... | 38.95 | NULL | 2026-04-22T23:29:39 |
| 2026-03-29 | b0d1be75... | 38.88 | NULL | 2026-04-22T23:29:39 |
| 2026-03-30 | 5fae2660... | 39.28 | NULL | 2026-04-22T23:29:39 |
| 2026-03-31 | 15d90556... | 38.85 | NULL | 2026-04-22T23:29:39 |

**Total legacy** : 315.56 GBP (8 rows)

### Safety check

- SELECT retourne exactement **8 rows** ✅
- Total = **315.56 GBP** (tolérance < 0.10) ✅
- Tous `campaign_id IS NULL` ✅
- Tous `date BETWEEN 2026-03-24 AND 2026-03-31` ✅
- DELETE exécuté par IDs exacts ✅

---

## CLEANUP PROD — RÉSULTAT

| Métrique | Avant | Après |
|---|---|---|
| Rows | 24 | **16** |
| Total spend | 760.76 GBP | **445.20 GBP** |
| Doublons logiques | 8 | **0** |

---

## VALIDATION PROD APRÈS CLEANUP

| Test | Résultat |
|---|---|
| `/metrics/overview` KBC GBP | spend_display = **445.20** GBP ✅ |
| spend source | `ad_spend_tenant` ✅ |
| data_quality.internal_only | true ✅ |
| `/metrics/overview` global | OK (512.30 EUR) ✅ |
| `/import/meta` sans tenant | 400 TENANT_ID_REQUIRED ✅ |
| `/import/meta` avec tenant | **410 DEPRECATED** ✅ |
| `/ad-accounts` KBC PROD | OK, token (encrypted), active ✅ |
| eComLG isolation | spend = 0, source = no_data ✅ |
| `ad_spend` global | 16 rows, 445.20 — inchangé ✅ |
| DEV image | `v3.5.107-ad-spend-idempotence-fix-dev` ✅ |
| health DEV/PROD | OK ✅ |

---

## GITOPS

| Fichier | Image |
|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.107-ad-spend-idempotence-fix-dev` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.107-ad-spend-idempotence-fix-prod` |

### Rollback

| Env | Rollback vers |
|---|---|
| DEV | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| PROD | `v3.5.106-metrics-settings-currency-exclusion-prod` |

---

## NON-RÉGRESSION

| Vérification | Résultat |
|---|---|
| health DEV | OK ✅ |
| health PROD | OK ✅ |
| /metrics/overview global | OK ✅ |
| /metrics/overview KBC | 445.20 GBP ✅ |
| /metrics/overview eComLG | 0, no_data ✅ |
| /ad-accounts KBC | OK, token masked ✅ |
| /import/meta legacy ne peut plus écrire | 410 DEPRECATED ✅ |
| ad_spend global inchangé | 16 rows, 445.20 ✅ |
| aucun token leak | (encrypted) dans toutes les réponses ✅ |
| currency/CAC model inchangé | intact ✅ |
| Admin V2 non touché | intact ✅ |
| outbound destinations non touché | intact ✅ |
| tracking conversions non touché | intact ✅ |

---

## ÉTAT FINAL KBC

| Env | Tenant ID | Rows | Spend | Doublons |
|---|---|---|---|---|
| DEV | keybuzz-consulting-mo9y479d | 16 | 445.20 GBP | 0 |
| PROD | keybuzz-consulting-mo9zndlk | 16 | 445.20 GBP | 0 |

---

## VERDICT

**AD SPEND TENANT IDEMPOTENCE FIXED — PROD DUPLICATES CLEANED — KBC METRICS RESTORED TO 445.20 GBP — GLOBAL LEAK STILL DISPROVEN**
