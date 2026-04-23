# PH-T8.8F — Ad Spend Tenant Duplicate Truth Audit

> **Date** : 2026-04-23
> **Type** : Audit lecture seule — aucune modification
> **Environnements** : DEV + PROD

---

## 1. PRÉFLIGHT

| Env | Tenant ID | API image | Ad account | Rows tenant spend | Total GBP |
|-----|-----------|-----------|------------|-------------------|-----------|
| DEV | `keybuzz-consulting-mo9y479d` | `v3.5.106-metrics-settings-currency-exclusion-dev` | (interne DEV) | 16 | 445.20 |
| PROD | `keybuzz-consulting-mo9zndlk` | `v3.5.106-metrics-settings-currency-exclusion-prod` | `b8b89a18-aa86-4e34-9488-b53fc404b96a` | 24 | 760.76 |

---

## 2. SOURCE UTILISÉE PAR `/metrics/overview`

| Env | source | total GBP | total EUR | rows | OK ? |
|-----|--------|-----------|-----------|------|------|
| DEV | `ad_spend_tenant` | 445.20 | 512.30 | 16 | ✅ |
| PROD | `ad_spend_tenant` | 760.76 | 875.41 | 24 | ⚠️ Doublons |

Les deux environnements utilisent exclusivement `ad_spend_tenant` (scope `tenant`). Aucun fallback vers `ad_spend` global.

---

## 3. DB GLOBAL vs TENANT

| Env | Table | Rows | Spend | Min date | Max date |
|-----|-------|------|-------|----------|----------|
| DEV | `ad_spend` (global) | 16 | 445.20 | 2026-03-16 | 2026-03-31 |
| DEV | `ad_spend_tenant` (KBC) | 16 | 445.20 | 2026-03-16 | 2026-03-31 |
| DEV | `ad_spend_tenant` (range UI) | 16 | 445.20 | 2026-03-16 | 2026-03-31 |
| PROD | `ad_spend` (global) | 16 | 445.20 | 2026-03-16 | 2026-03-31 |
| PROD | `ad_spend_tenant` (KBC all) | 24 | 760.76 | 2026-03-16 | 2026-03-31 |
| PROD | `ad_spend_tenant` (range UI) | 24 | 760.76 | 2026-03-16 | 2026-03-31 |

**Observation** : PROD `ad_spend_tenant` a 24 rows vs 16 en DEV, mais les mêmes dates (16-31 mars). Le global `ad_spend` est identique dans les deux envs (16 rows, 445.20 GBP).

---

## 4. DÉTECTION DOUBLONS

### Requête duplicate check (HAVING COUNT > 1) : 0 résultat

L'index unique `idx_ast_dedup` est sur `(tenant_id, platform, date, COALESCE(campaign_id, '__none__'))`. Les doublons ne sont pas détectés par cette requête car les deux rows par date ont des clés **techniquement différentes** :

- Row 1 : `campaign_id = NULL` → `COALESCE = '__none__'`
- Row 2 : `campaign_id = '120241837833890344'` → `COALESCE = '120241837833890344'`

### Preuve PROD — Doublons logiques confirmés

| Env | Rows campaign_id NULL | Spend NULL | Rows campaign_id non-NULL | Spend non-NULL |
|-----|----------------------|------------|--------------------------|----------------|
| DEV | 16 | 445.20 | 0 | 0 |
| PROD | 16 | 445.20 | 8 | 315.56 |

Les 8 rows avec `campaign_id = '120241837833890344'` (campagne "CBO | Leadgen | Amazon") couvrent les dates **24-31 mars** et contiennent **exactement les mêmes montants** que les rows NULL correspondantes.

---

## 5. DÉTAIL PAR JOUR

| Date | DEV spend | DEV rows | PROD spend | PROD rows | Diff | Commentaire |
|------|-----------|----------|------------|-----------|------|-------------|
| 16 mars | 2.48 | 1 | 2.48 | 1 | 0 | Identique |
| 17 mars | 13.39 | 1 | 13.39 | 1 | 0 | Identique |
| 18 mars | 9.84 | 1 | 9.84 | 1 | 0 | Identique |
| 19 mars | 10.56 | 1 | 10.56 | 1 | 0 | Identique |
| 20 mars | 10.18 | 1 | 10.18 | 1 | 0 | Identique |
| 21 mars | 4.98 | 1 | 4.98 | 1 | 0 | Identique |
| 22 mars | 39.26 | 1 | 39.26 | 1 | 0 | Identique |
| 23 mars | 38.95 | 1 | 38.95 | 1 | 0 | Identique |
| **24 mars** | 37.42 | 1 | **74.84** | **2** | **+37.42** | **DOUBLÉ** |
| **25 mars** | 40.57 | 1 | **81.14** | **2** | **+40.57** | **DOUBLÉ** |
| **26 mars** | 41.92 | 1 | **83.84** | **2** | **+41.92** | **DOUBLÉ** |
| **27 mars** | 39.69 | 1 | **79.38** | **2** | **+39.69** | **DOUBLÉ** |
| **28 mars** | 38.95 | 1 | **77.90** | **2** | **+38.95** | **DOUBLÉ** |
| **29 mars** | 38.88 | 1 | **77.76** | **2** | **+38.88** | **DOUBLÉ** |
| **30 mars** | 39.28 | 1 | **78.56** | **2** | **+39.28** | **DOUBLÉ** |
| **31 mars** | 38.85 | 1 | **77.70** | **2** | **+38.85** | **DOUBLÉ** |
| **TOTAL** | **445.20** | **16** | **760.76** | **24** | **+315.56** | |

**Écart = 760.76 − 445.20 = 315.56 GBP** → exactement la somme des 8 rows dupliquées.

---

## 6. CAUSE RACINE

### Deux chemins d'import distincts ont écrit dans la même table

| Chemin | Fichier | Date created_at | campaign_id | Rows |
|--------|---------|-----------------|-------------|------|
| **Backfill PROD** (PH-T8.8A.2/T8.8C) | `src/modules/metrics/routes.ts` (`/import/meta`) | 22 avril 23:29:39 | **NULL** | 16 |
| **Sync Ad Account** (PH-T8.8C PROD validation) | `src/modules/ad-accounts/routes.ts` (`/ad-accounts/:id/sync`) | 23 avril 09:01:19 | **120241837833890344** | 8 |

### Pourquoi 8 et pas 16 ?

Le sync `/ad-accounts/:id/sync` du 23 avril a été lancé avec une plage par défaut de ~30 jours avant cette date, soit environ du 24 mars au 23 avril. Comme Meta Ads n'a des données que du 16 au 31 mars, seules les dates 24-31 mars avaient des données à importer → 8 rows.

### Pourquoi l'upsert ne les a pas fusionnées ?

L'index unique `idx_ast_dedup` utilise `COALESCE(campaign_id, '__none__')` :

- `/import/meta` insère SANS `campaign_id` → `COALESCE(NULL, '__none__') = '__none__'`
- `/ad-accounts/:id/sync` insère AVEC `campaign_id = '120241837833890344'` → différent de `'__none__'`

Les deux inserts ont des clés uniques différentes → pas de conflit → pas d'upsert → **deux rows par date**.

### Code source des deux chemins

**`routes.ts` (legacy `/import/meta`)** :
```sql
INSERT INTO ad_spend_tenant (tenant_id, account_id, platform, date, spend, ...)
-- PAS de campaign_id → NULL
ON CONFLICT (tenant_id, platform, date, COALESCE(campaign_id, '__none__'))
DO UPDATE SET spend = EXCLUDED.spend ...
```

**`ad-accounts/routes.ts` (`/ad-accounts/:id/sync`)** :
```sql
INSERT INTO ad_spend_tenant (tenant_id, account_id, platform, campaign_id, campaign_name, ...)
-- AVEC campaign_id réel
ON CONFLICT (tenant_id, platform, date, COALESCE(campaign_id, '__none__'))
DO UPDATE SET spend = EXCLUDED.spend ...
```

---

## 7. PREUVE : ZÉRO GLOBAL LEAK

| Env | API total GBP | Tenant DB sum | Global DB sum | Tenant + global | Verdict |
|-----|---------------|---------------|---------------|-----------------|---------|
| DEV | 445.20 | 445.20 | 445.20 | 890.40 | ✅ API = tenant only |
| PROD | 760.76 | 760.76 | 445.20 | 1205.96 | ✅ API = tenant only |

L'API `/metrics/overview?tenant_id=X` ne somme **que** `ad_spend_tenant`. Il n'y a aucun fallback ni mélange avec `ad_spend` global.

Le problème est **interne à `ad_spend_tenant`** : doublons logiques entre deux chemins d'import.

---

## 8. VERDICT

### **CAS B CONFIRMÉ : doublon dans `ad_spend_tenant` PROD**

| Question | Réponse |
|----------|---------|
| L'écart est-il normal (PROD plus fraîche) ? | **NON** — les deux envs couvrent les mêmes dates |
| Existe-t-il un doublon dans `ad_spend_tenant` ? | **OUI — 8 rows dupliquées en PROD (mars 24-31)** |
| Le spend global est-il encore pris en compte ? | **NON — zéro global leak confirmé** |
| La plage de dates explique-t-elle l'écart ? | **NON — même plage 16-31 mars** |
| L'idempotence/upsert est-elle insuffisante ? | **OUI — deux chemins d'import utilisent des campaign_id différents (NULL vs réel)** |

### Montant impact

| Métrique | Valeur correcte | Valeur actuelle PROD | Surplus |
|----------|-----------------|---------------------|---------|
| Spend GBP | 445.20 | 760.76 | +315.56 (71% trop haut) |
| Spend EUR | 512.30 | 875.41 | +363.11 |

### Peut-on faire confiance au 761 GBP PROD ?

**NON.** Le chiffre réel est **445.20 GBP**. Les 315.56 GBP excédentaires sont des doublons logiques.

### Faut-il nettoyer des lignes ?

**OUI.** Les 8 rows avec `campaign_id = NULL` ET `date BETWEEN '2026-03-24' AND '2026-03-31'` sont les rows legacy à supprimer en PROD, car les rows avec `campaign_id` réel sont plus riches (contiennent le nom de campagne).

### Faut-il corriger l'idempotence ?

**OUI.** Le chemin `/import/meta` (legacy dans `routes.ts`) insère sans `campaign_id`, tandis que `/ad-accounts/:id/sync` insère avec. Deux options :
1. **Option A** : supprimer le chemin legacy `/import/meta` (il est déjà bloqué sans `tenant_id`, mais la branche tenant insère encore sans `campaign_id`)
2. **Option B** : harmoniser les deux chemins pour toujours insérer avec `campaign_id` (ou toujours sans)

### Faut-il resynchroniser DEV ?

**OUI**, si on veut aligner DEV avec PROD. DEV n'a que les rows legacy (NULL campaign_id). Un sync via `/ad-accounts/:id/sync` en DEV ajouterait les mêmes doublons.

### Risque KPI/CAC/ROAS faux ?

**OUI en PROD actuellement.** Le spend est gonflé de 71%, ce qui :
- Sous-estime le ROAS (revenue / spend trop élevé)
- Sur-estime le CAC (spend / signups trop élevé)

---

## 9. RECOMMANDATIONS

### Immédiat (phase corrective)

1. **Supprimer en PROD** les 8 rows legacy (campaign_id NULL, dates 24-31 mars) — elles sont redondantes avec les rows riches
2. **Supprimer en DEV** les 16 rows legacy et relancer un sync via `/ad-accounts/:id/sync` pour avoir des données propres avec campaign_id
3. **OU** supprimer les 8 rows non-legacy en PROD (campaign_id non-NULL) pour revenir à 445.20 GBP — moins idéal car on perd les noms de campagne

### Structurel (prochaine phase)

4. **Modifier `/import/meta`** (branche tenant) pour inclure `campaign_id` dans le fetch Meta Ads, aligné avec `/ad-accounts/:id/sync`
5. **OU** déprécier `/import/meta` au profit exclusif de `/ad-accounts/:id/sync`
6. Documenter que le chemin canonique de sync est `/ad-accounts/:id/sync`

### Aucune modification effectuée dans cet audit

Cet audit est **strictement en lecture seule**. Aucune row n'a été modifiée, supprimée ou insérée.

---

## VERDICT

**AD SPEND TENANT TRUTH ESTABLISHED — DUPLICATE CONFIRMED IN PROD (8 ROWS, +315.56 GBP) — GLOBAL LEAK DISPROVEN — IDEMPOTENCE FIX REQUIRED**
