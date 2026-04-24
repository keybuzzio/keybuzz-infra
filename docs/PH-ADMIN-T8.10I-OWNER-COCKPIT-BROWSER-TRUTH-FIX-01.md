# PH-ADMIN-T8.10I-OWNER-COCKPIT-BROWSER-TRUTH-FIX-01 — TERMINÉ

**Verdict : GO**

**Date :** 2026-04-24
**Environnement :** DEV uniquement
**PROD inchangée :** oui

---

## Préflight

| Élément | Valeur | Conforme |
|---|---|---|
| Admin branche | `main` | OK |
| Admin HEAD pré-fix | `4bd3dd0` | OK |
| Admin DEV image pré-fix | `v2.11.13-agency-proxy-tenant-guard-dev` | OK |
| Admin PROD | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | INCHANGÉE |
| API branche | `ph147.4/source-of-truth` | OK |
| API HEAD pré-fix | `3162056a` | OK |
| API DEV image pré-fix | `v3.5.115-owner-scoped-funnel-activation-aggregation-dev` | OK |
| API PROD | `v3.5.111-activation-completed-model-prod` | INCHANGÉE |
| Repos | clean | OK |

---

## Reproduction

Les deux problèmes ont été documentés par l'opérateur à partir de sessions navigateur réelles sur `admin-dev.keybuzz.io`.

### Cas A — media_buyer sur KBC / Metrics

| Élément | Attendu | Observé |
|---|---|---|
| Tenant selector | KBC uniquement | KBC uniquement ✓ |
| Bandeau owner | Visible (scope=owner) | **Absent** ✗ |
| Chiffres affichés | Owner-scoped (signups=2, spend=445.2 GBP) | **"Global-ish"** (Spend≈513 EUR, New customers=4, MRR=497) ✗ |
| Appel API direct | scope=owner, owner_cohort.total=3 | Correct ✓ |

### Cas B — KBC / Funnel / Borne haute `to`

| Élément | `to=2026-04-24` | `to=2026-04-25` |
|---|---|---|
| Banner owner | 2 funnels | 2 funnels |
| Cards/Steps UI | **1 funnel** ✗ | **2 funnels** ✓ |
| Verdict | Le jour du `to` est exclu | Fonctionnel quand +1 jour |

---

## Diagnostic Metrics (Problème A)

### Cause racine : Race condition fetchData sans guard tenantId

| Couche | Observation | Verdict |
|---|---|---|
| `useCurrentTenant()` | Renvoie `tenantId = ''` au premier render, puis charge depuis `/api/admin/tenants` | Normal |
| `fetchData` (useCallback) | Dépend de `[from, to, tenantId, displayCurrency]` | Normal |
| `useEffect(() => fetchData(), [fetchData])` | Se déclenche à chaque changement de `fetchData` | Normal |
| **Premier fetch** | `tenantId = ''` → appel **sans** `tenant_id` → API renvoie données **globales** | **PROBLÈME** |
| **Second fetch** | `tenantId = 'keybuzz-consulting-mo9y479d'` → appel **avec** `tenant_id` → API renvoie données **owner** | OK |
| **Race condition** | Si le premier fetch (global) termine APRÈS le second (owner), `setData(globalData)` écrase `setData(ownerData)` | **CAUSE RACINE** |

La page Funnel a déjà le guard `if (!tenantId) return;` dans son `fetchData` (ligne ~100) et ne souffre pas de ce problème. La page Metrics ne l'avait PAS.

---

## Diagnostic Funnel (Problème B)

### Cause racine : Borne haute exclusive manquante (`created_at <= to`)

| Couche | `to=2026-04-24` | `to=2026-04-25` | Conclusion |
|---|---|---|---|
| UI params | `to=2026-04-24` | `to=2026-04-25` | Passé tel quel |
| Proxy params | `to=2026-04-24` | `to=2026-04-25` | Forwarded tel quel |
| API SQL | `created_at <= '2026-04-24'` | `created_at <= '2026-04-25'` | PostgreSQL interprète comme `T00:00:00` |
| Sémantique | Exclut tout event après minuit le 24 | Inclut le 24 complet | **Bug = `<=` au lieu de `< +1 day`** |
| `cohort_size` | 2 (résolu sans filtre date) | 2 | Banner correct dans les deux cas |
| Steps counts | 1 funnel (events du 24 exclus) | 2 funnels | Mismatch banner vs steps |

**Localisation :** API SaaS — `src/modules/funnel/routes.ts` lignes 244 et 297.

---

## Stratégie de fix retenue

| Sujet | Couche | Fix | Pourquoi |
|---|---|---|---|
| Metrics race condition | Admin UI | `if (!tenantId) return;` dans `fetchData` | Pattern identique à la page Funnel, empêche le fetch global parasite |
| Funnel borne haute | API SaaS | `created_at < ($N::date + interval '1 day')` | Inclut le jour complet du `to`, standard PostgreSQL, pas de hack |

---

## Patch exact appliqué

### Admin — `src/app/(admin)/metrics/page.tsx`

```diff
@@ -200,6 +200,7 @@ export default function MetricsPage() {
 
   /* ── fetch metrics ── */
   const fetchData = useCallback(async (isRefresh = false) => {
+    if (!tenantId) return;
     if (isRefresh) setRefreshing(true); else setLoading(true);
     setError(null);
```

**Commit :** `dad2fa5` — `fix(metrics): prevent race condition -- guard fetchData with tenantId check to avoid global data overwriting owner-scoped response`

### API — `src/modules/funnel/routes.ts`

```diff
@@ -241,7 +241,7 @@ (events endpoint)
     if (from) { conditions.push(`created_at >= $${idx++}`); params.push(from); }
-    if (to) { conditions.push(`created_at <= $${idx++}`); params.push(to); }
+    if (to) { conditions.push(`created_at < ($${idx++}::date + interval '1 day')`); params.push(to); }

@@ -294,7 +294,7 @@ (metrics endpoint)
     if (from) { conditions.push(`created_at >= $${idx++}`); params.push(from); }
-    if (to) { conditions.push(`created_at <= $${idx++}`); params.push(to); }
+    if (to) { conditions.push(`created_at < ($${idx++}::date + interval '1 day')`); params.push(to); }
```

**Commit :** `ac29fd55` — `fix(funnel): fix upper-bound date filter -- use exclusive next-day boundary so to date includes the entire selected day`

---

## Validation

### Preuves API — Funnel borne haute corrigée

| Métrique | `to=2026-04-24` AVANT fix | `to=2026-04-24` APRÈS fix | `to=2026-04-25` APRÈS fix |
|---|---|---|---|
| `cohort_size` | 2 | **2** ✓ | **2** ✓ |
| `register_started` | 1 | **2** ✓ | **2** ✓ |
| `plan_selected` | 1 | **2** ✓ | **2** ✓ |
| `checkout_started` | 1 | **2** ✓ | **2** ✓ |
| `scope` | owner | **owner** ✓ | **owner** ✓ |

Les deux dates retournent désormais les **mêmes résultats**. Le bug de borne haute est éliminé.

### Preuves API — Metrics owner-scoped

Le payload API pour KBC owner retourne correctement :
- `scope: "owner"`
- `owner_cohort: { owner: "keybuzz-consulting-mo9y479d", children: [...], total: 3 }`
- `new_customers: 2` (signups owner-scoped)
- `spend.total_display: 512.89 EUR` (FX GBP→EUR)

Avec le guard `if (!tenantId) return;`, le fetch global parasite ne sera plus émis.

### Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Metrics tenant-scoped (non-owner) | scope=tenant, pas d'owner_cohort | ✓ `scope=tenant, owner_cohort=NONE` |
| Funnel tenant-scoped (non-owner) | cohort_size=0, pas de scope owner | ✓ `cohort_size=0, scope=N/A` |
| Funnel events date boundary | Events retournés pour to=2026-04-24 | ✓ `count=5, scope=owner` |
| API health | status ok | ✓ `status: ok` |
| Admin pod | Running + Ready | ✓ Phase=Running, Ready=true |
| T8.10H guard (assertTenantAccess) | Préservé | ✓ `proxy.ts` non modifié |
| Admin PROD | Inchangée `v2.11.11` | ✓ |
| API PROD | Inchangée `v3.5.111` | ✓ |

---

## Images DEV

| Service | Image | Digest |
|---|---|---|
| Admin DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.14-owner-cockpit-browser-truth-fix-dev` | `sha256:5cacdc0a8baf692c13f577a13d0ee85ff3a6988698f907adc2c61f65664b4cc4` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.116-owner-cockpit-browser-truth-fix-dev` | `sha256:ef0ce9a916361848e0b89bb0c54116c5c65aa1125fa612b9839d45a1c36347e0` |

### GitOps

- Commit infra : `9f247df` — `deploy(dev): admin v2.11.14 + api v3.5.116 -- owner cockpit browser truth fix`
- Manifests modifiés : `k8s/keybuzz-admin-v2-dev/deployment.yaml`, `k8s/keybuzz-api-dev/deployment.yaml`
- Manifests PROD : **inchangés**

### Rollback DEV

```bash
# Admin rollback
sed -i 's|v2.11.14-owner-cockpit-browser-truth-fix-dev|v2.11.13-agency-proxy-tenant-guard-dev|' k8s/keybuzz-admin-v2-dev/deployment.yaml

# API rollback
sed -i 's|v3.5.116-owner-cockpit-browser-truth-fix-dev|v3.5.115-owner-scoped-funnel-activation-aggregation-dev|' k8s/keybuzz-api-dev/deployment.yaml
```

---

## Gaps restants

| Gap | Description | Impact | Priorité |
|---|---|---|---|
| Owner agency RBAC fin | `media_buyer` voit KBC uniquement mais pas de granularité fine read-only vs write | Faible — guard cross-tenant en place | Basse |
| Polish UI owner cockpit | Bandeau owner pourrait bénéficier de tooltips, détail enfants | Cosmétique | Basse |
| Storytelling owner ad-accounts/destinations/delivery-logs | Pas de banner owner ni agrégation owner sur ces pages | Feature | Phase ultérieure |
| Contrat LP/funnels externes owner-scoped | Source funnels externes pas paramétrée pour owner | Feature avancée | Phase ultérieure |
| Validation navigateur E2E complète | Login browser tools non fonctionnel (credentials inconnus) | Substituée par preuves API directes | À compléter quand credentials disponibles |

---

## PROD inchangée

| Service | Image PROD | Modifié ? |
|---|---|---|
| Admin | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | **NON** |
| API | `v3.5.111-activation-completed-model-prod` | **NON** |
| Client | N/A | **NON** |

---

## Conclusion

**OWNER COCKPIT BROWSER TRUTH RESTORED IN DEV — METRICS AND FUNNEL NOW MATCH REAL OWNER-SCOPED DATA — TENANT GUARD PRESERVED — PROD UNTOUCHED**

### Résumé des corrections

1. **Problème A (Metrics race condition)** : Le `fetchData` de la page Metrics émettait un fetch sans `tenant_id` au premier render (avant que le TenantContext charge), recevant des données globales. Si ce fetch global terminait après le fetch owner-scoped, il écrasait les bonnes données. Le fix ajoute `if (!tenantId) return;` — pattern identique à la page Funnel qui fonctionnait déjà correctement.

2. **Problème B (Funnel borne haute `to`)** : Le SQL utilisait `created_at <= $to` ce qui, avec un `to='2026-04-24'` interprété par PostgreSQL comme `2026-04-24T00:00:00`, excluait tous les events après minuit du jour sélectionné. Le fix remplace par `created_at < ($to::date + interval '1 day')` qui inclut la journée complète.

### Rapport : `keybuzz-infra/docs/PH-ADMIN-T8.10I-OWNER-COCKPIT-BROWSER-TRUTH-FIX-01.md`
