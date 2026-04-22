# PH-T8.8A.1 — AD SPEND GLOBAL IMPORT LOCK

> Date : 2026-04-22
> Agent : Cursor Executor (CE)
> Environnement : **DEV uniquement** — PROD inchangée
> Priorité : P0
> Branche API : `ph147.4/source-of-truth`
> Branche Infra : `main`
> Prérequis : PH-T8.8A complété

---

## VERDICT

**GLOBAL AD SPEND IMPORT LOCKED IN DEV — TENANT-SPEND ONLY — READY FOR PROD PROMOTION**

---

## 0 — PRÉFLIGHT

| Élément | Valeur |
|---------|--------|
| Rapport T8.8A lu | Oui |
| HEAD API (avant) | `f4c3d910` |
| HEAD API (après) | `954eea74` |
| Image DEV (avant) | `v3.5.102-ad-spend-tenant-safety-dev` |
| Image DEV (après) | `v3.5.103-ad-spend-global-import-lock-dev` |
| Image PROD | `v3.5.101-outbound-destinations-delete-route-prod` (inchangée) |
| Repo API clean | Oui |
| Repo Infra clean | Oui |
| PROD modifiée | **NON** |

---

## 1 — AUDIT ROUTE IMPORT META

### Fichier : `src/modules/metrics/routes.ts` — `POST /import/meta`

| Point | État pré-patch (T8.8A) |
|-------|------------------------|
| Auth/RBAC | X-Internal-Token + X-Admin-Role via middleware global |
| Sans `tenant_id` | **Écrit dans `ad_spend` global** — 44 lignes de code de write global |
| Avec `tenant_id` + compte ads | Écrit dans `ad_spend_tenant` — OK |
| Avec `tenant_id` sans compte | 400 TENANT_SCOPED_AD_ACCOUNT_REQUIRED — OK |
| Token Meta | Env vars globales, jamais retourné — OK |

### Risque identifié

Le rapport T8.8A documente que l'import global était toujours fonctionnel :

> | Sans `tenant_id` | Écrit dans `ad_spend` global (inchangé) |

Ce comportement ne doit **jamais** partir en PROD. Un appel sans `tenant_id` écrirait du spend dans la table globale, polluant les KPIs de tous les tenants.

---

## 2 — PATCH SAFETY

### Modification

**44 lignes supprimées** (bloc global write) → **4 lignes** (rejection 400).

Le bloc supprimé contenait :
- `fetchMetaInsights(since, until)` sans contexte tenant
- `INSERT INTO ad_spend` sans `tenant_id`
- Calcul de totaux sur `ad_spend` global
- Réponse avec `target: 'ad_spend_global'`

Remplacé par :

```json
{
  "error": "TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT",
  "message": "Global ad spend import is disabled. Provide a tenant_id to import into ad_spend_tenant.",
  "hint": "POST /metrics/import/meta with body { \"tenant_id\": \"<your-tenant>\", \"since\": \"YYYY-MM-DD\", \"until\": \"YYYY-MM-DD\" }"
}
```

### Vérification code

| Vérification | Résultat |
|-------------|----------|
| `INSERT INTO ad_spend ` (global) dans le fichier | **0 occurrences** |
| `INSERT INTO ad_spend_tenant` (tenant) dans le fichier | **1 occurrence** (L389) |
| `TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT` présent | **Oui** (L429) |
| `TENANT_SCOPED_AD_ACCOUNT_REQUIRED` présent | **Oui** (L365) |
| Table `ad_spend` non supprimée | **Oui** — la table existe toujours, seul l'écriture est bloquée |

---

## 3 — VALIDATION DEV

| # | Cas | Attendu | HTTP | Résultat |
|---|-----|---------|------|----------|
| 1 | Health | ok | 200 | **PASS** |
| 2 | Import Meta sans tenant_id | 400 + TENANT_ID_REQUIRED | **400** | **PASS** — aucun write global |
| 3 | Import Meta tenant inexistant | 400 + TENANT_SCOPED_AD_ACCOUNT_REQUIRED | **400** | **PASS** |
| 4 | Import Meta KeyBuzz Consulting | 200 + ad_spend_tenant | **200** | **PASS** — 16 rows imported |
| 5 | Overview global | spend.source=ad_spend_global | **200** | **PASS** — total_eur=512.29 |
| 6 | Overview ecomlg-001 | spend=0, pas de global leak | **200** | **PASS** — source=no_data |
| 7 | Overview KeyBuzz Consulting | spend tenant OK | **200** | **PASS** — source=ad_spend_tenant, total_eur=512.29 |
| 8 | Token brut absent | aucun pattern EAA* | — | **PASS** |
| 9 | NaN/undefined absent | aucun NaN | — | **PASS** |
| 10 | PROD inchangée | v3.5.101 | — | **PASS** |

---

## 4 — IMAGE DEV

| Élément | Valeur |
|---------|--------|
| Tag | `v3.5.103-ad-spend-global-import-lock-dev` |
| Digest | `sha256:25355f81839edf11066679f073099b60e71452e13204f1a482e0ac25553b2c1f` |
| Build source | Commit `954eea74` (branche `ph147.4/source-of-truth`) |
| Build method | `docker build --no-cache` |
| Repo clean au build | Oui |
| Commit infra | `b4d004c` (keybuzz-infra main) |
| Restarts | 0 |

### Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.102-ad-spend-tenant-safety-dev -n keybuzz-api-dev
```

---

## 5 — ÉTAT PROD

| Vérification | Résultat |
|-------------|----------|
| Image API PROD | `v3.5.101-outbound-destinations-delete-route-prod` (inchangée) |
| Code PROD modifié | **NON** |
| Tables PROD modifiées | **NON** |
| Import global possible en PROD | **OUI** — c'est pourquoi la promotion est nécessaire |

---

## 6 — RECOMMANDATION PROMOTION PROD CUMULATIVE

La promotion PROD doit inclure les deux patches en une seule image :

### Image PROD cible

`v3.5.103-ad-spend-global-import-lock-prod`

### Contenu cumulé (T8.8A + T8.8A.1)

| Feature | Description |
|---------|-------------|
| `/metrics/overview?tenant_id=X` | Lit uniquement `ad_spend_tenant` — jamais `ad_spend` global |
| `/metrics/import/meta` sans `tenant_id` | **400 TENANT_ID_REQUIRED_FOR_AD_SPEND_IMPORT** |
| `/metrics/import/meta` avec `tenant_id` | Écrit dans `ad_spend_tenant` uniquement |
| CAC/ROAS tenant | Calculés avec spend tenant uniquement |

### Actions requises en PROD

1. Créer tables `ad_platform_accounts` + `ad_spend_tenant`
2. Backfiller `ad_spend` → `ad_spend_tenant` pour KeyBuzz Consulting PROD (`keybuzz-consulting-mo9zndlk`)
3. Builder + déployer `v3.5.103-ad-spend-global-import-lock-prod`
4. Soft-delete 3 destinations PROD orphelines (`291a5797`, `28cbc2be`, `7464753d`)
5. Validation PROD complète

---

## COMMITS

| Repo | Hash | Message |
|------|------|---------|
| keybuzz-api | `954eea74` | PH-T8.8A.1: lock global ad spend import — POST /import/meta without tenant_id returns 400 |
| keybuzz-infra | `b4d004c` | PH-T8.8A.1: DEV deploy global import lock — v3.5.103-ad-spend-global-import-lock-dev |
