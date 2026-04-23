# PH-T8.9B.1 — Funnel Metrics Tenant Scope

> **Phase** : PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01
> **Date** : 2026-04-23
> **Environnement** : DEV uniquement
> **Statut** : TERMINÉ

---

## 0. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| **Branche API** | `ph147.4/source-of-truth` |
| **HEAD avant** | `006c4bbb` (PH-T8.9B) |
| **HEAD après** | `2a61895e` (PH-T8.9B.1) |
| **Image DEV avant** | `v3.5.108-funnel-pretenant-foundation-dev` |
| **Image DEV après** | `v3.5.109-funnel-metrics-tenant-scope-dev` |
| **Image PROD** | `v3.5.107-ad-spend-idempotence-fix-prod` (INCHANGÉ) |
| **Client DEV** | `v3.5.108-funnel-pretenant-foundation-dev` (INCHANGÉ) |
| **Client PROD** | `v3.5.81-tiktok-attribution-fix-prod` (INCHANGÉ) |
| **Repo clean** | Oui |
| **Digest** | `sha256:07264afc922d433a9e5f687af017f7ac875738b6f4efadd9e4920537477b3237` |

---

## 1. PREUVE DU BUG

### Code avant fix

`GET /funnel/metrics` n'acceptait pas `tenant_id` dans son querystring :

```typescript
// AVANT — ligne 122
app.get('/metrics', async (request: FastifyRequest<{ Querystring: { from?: string; to?: string } }>, ...)
```

Le paramètre `tenant_id` était purement ignoré. L'agrégation était toujours globale.

`GET /funnel/events?tenant_id=X` utilisait un filtre naïf `WHERE tenant_id = $N`, ce qui excluait les 6 steps pré-tenant où `tenant_id = NULL`.

| Appel | Attendu | Observé (avant fix) |
|---|---|---|
| `/funnel/metrics` (global) | Agrégation globale | OK mais seul mode |
| `/funnel/metrics?tenant_id=X` | Données tenant X | **BUG** : `tenant_id` ignoré, retourne global |
| `/funnel/events?tenant_id=X` | Events tenant X (pré+post) | **BUG** : exclut les steps pré-tenant |

---

## 2. DESIGN DU FIX — TENANT COHORT STITCHING

### Principe

Un funnel appartient à un tenant si **au moins une de ses rows** porte ce `tenant_id`. En pratique, c'est toujours `tenant_created` ou `checkout_started` qui lie le funnel au tenant.

### Algorithme

```
1. Résoudre la cohorte: SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = :tenant_id
2. Agréger: SELECT ... FROM funnel_events WHERE funnel_id = ANY(:cohort) [AND date filters]
```

Cela inclut automatiquement les steps pré-tenant (`register_started`, `plan_selected`, etc.) car le filtre porte sur `funnel_id`, pas sur `tenant_id`.

### Décisions de design

| Point | Décision |
|---|---|
| **Source de cohorte** | Toute row `funnel_events` avec `tenant_id = :tenant_id` (all-time) |
| **Inclusion steps NULL** | Oui, par construction (filtre sur funnel_id, pas tenant_id) |
| **Règle from/to** | Cohorte résolue all-time, dates appliquées uniquement sur les events |
| **Mode global** | Inchangé si `tenant_id` absent |
| **Alignement /events** | Même logique de cohort stitching appliquée |
| **Réponse enrichie** | `cohort_size` ajouté quand tenant_id est présent |

### Helper

```typescript
async function resolveTenantFunnelCohort(pool, tenantId: string): Promise<string[]> {
  const result = await pool.query(
    'SELECT DISTINCT funnel_id FROM funnel_events WHERE tenant_id = $1',
    [tenantId]
  );
  return result.rows.map(r => r.funnel_id);
}
```

---

## 3. PATCH APPLIQUÉ

**Fichier** : `src/modules/funnel/routes.ts` (+61/-7 lignes)

### Changements

1. **Nouveau helper** : `resolveTenantFunnelCohort()` — résout les funnel_ids d'un tenant
2. **`GET /metrics`** : accepte `tenant_id` dans querystring, utilise le cohort stitching
3. **`GET /events`** : remplace le naïf `WHERE tenant_id = $N` par le cohort stitching
4. **Réponses enrichies** : `tenant_id` et `cohort_size` dans la réponse quand applicable
5. **Early return** : cohort vide → retour immédiat avec 0s (pas de query inutile)

---

## 4. VALIDATION DEV

| Cas | Attendu | Résultat |
|---|---|---|
| **A. Global** | Agrégation des 2 funnels test (12 rows total) | **PASS** — 2 register, 2 plan, 2 email, 1 otp, 2 tenant, 1 checkout |
| **B. Tenant-A** | 8 events (6 pré-tenant + 2 post-tenant), cohort_size=1 | **PASS** — tous inclus |
| **C. Tenant-B** | 4 events (3 pré-tenant + 1 post-tenant), pas de fuite A | **PASS** — isolation OK |
| **D. Tenant-X** | 0 partout, cohort_size=0 | **PASS** |
| **E. /events cohort** | 8 events incluant tenant_id=NULL | **PASS** — stitching correct |
| **F. Idempotence** | `already_recorded` | **PASS** |
| **G. conversion_events** | 0 micro-steps | **PASS** |
| **H. PROD** | Inchangé | **PASS** |

---

## 5. PREUVES SQL / DATA

### Données test (2 funnels, 2 tenants)

```
funnel-A | register_started     | NULL         | pro
funnel-A | plan_selected        | NULL         | pro
funnel-A | email_submitted      | NULL         | pro
funnel-A | otp_verified         | NULL         | pro
funnel-A | company_completed    | NULL         | pro
funnel-A | user_completed       | NULL         | pro
funnel-A | tenant_created       | tenant-A     | pro       ← couture tenant
funnel-A | checkout_started     | tenant-A     | pro

funnel-B | register_started     | NULL         | starter
funnel-B | plan_selected        | NULL         | starter
funnel-B | email_submitted      | NULL         | starter
funnel-B | tenant_created       | tenant-B     | starter   ← couture tenant
```

### Preuve de stitching

`/funnel/metrics?tenant_id=tenant-A` retourne 8 events (les 6 rows pré-tenant à `NULL` + 2 post-tenant) — c'est le funnel complet.

### Preuve d'isolation

`/funnel/metrics?tenant_id=tenant-B` retourne 4 events — aucune fuite de `funnel-A`.

### Preuve d'unicité

`DUPLICATES: NONE (PASS)` — la contrainte `UNIQUE(funnel_id, event_name)` est respectée.

---

## 6. NON-RÉGRESSION

| Vérification | Résultat |
|---|---|
| `/funnel/event` POST | OK |
| `/funnel/metrics` global | OK (non régressé) |
| `/funnel/metrics?tenant_id=X` | OK (fix appliqué) |
| `/funnel/events?tenant_id=X` | OK (cohort stitching aligné) |
| Idempotence UNIQUE | OK |
| conversion_events | 0 micro-steps |
| outbound destinations | Inchangées |
| register / OTP / create-signup / checkout | Code non touché |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` (INCHANGÉ) |
| Client DEV | `v3.5.108-funnel-pretenant-foundation-dev` (INCHANGÉ) |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` (INCHANGÉ) |
| Admin DEV/PROD | INCHANGÉ |

---

## 7. IMAGE DEV

| Service | Tag | Commit | Digest |
|---|---|---|---|
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | `2a61895e` | `sha256:07264afc922d...` |

### Manifest modifié

- `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml`

### Rollback DEV

```
v3.5.108-funnel-pretenant-foundation-dev
```

---

## 8. GAP RÉSIDUEL

Aucun gap résiduel. `/funnel/events` et `/funnel/metrics` utilisent tous deux le cohort stitching. Les deux endpoints sont alignés.

---

## VERDICT

**FUNNEL METRICS TENANT SCOPE READY IN DEV — PRE-TENANT STEPS INCLUDED BY FUNNEL COHORT — NO ADS POLLUTION — PROD UNTOUCHED**

### Rapport : `keybuzz-infra/docs/PH-T8.9B.1-FUNNEL-METRICS-TENANT-SCOPE-01.md`
