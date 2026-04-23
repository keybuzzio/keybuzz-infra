# PH-ADMIN-T8.9C.2 — Funnel CRO UI Real Data Validation

**Phase** : PH-ADMIN-T8.9C.2-FUNNEL-CRO-UI-REAL-DATA-VALIDATION-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : validation réelle Funnel / CRO UI avec données tenant-scoped
**Priorité** : P0

---

## 0. PRÉFLIGHT

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Infra | `main` | OK |
| HEAD Infra | `f093d08` | OK |
| Admin DEV | `v2.11.10-funnel-menu-icon-fix-dev` | OK |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` | INCHANGÉ |
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | OK |
| Client DEV | `v3.5.108-funnel-pretenant-foundation-dev` | OK |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` | INCHANGÉ |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` | INCHANGÉ |
| Repo | clean | OK |

---

## 1. TENANTS DE TEST

La table `funnel_events` était vide au démarrage de la validation (données de PH-T8.9B.1 non persistantes).
12 events réinjectés via `POST /funnel/event` (endpoint existant, aucun changement API/DB), en utilisant des **tenant_ids réels** du système DEV.

| Tenant | tenant_id | Funnel ID | Events | Plan | Particularité |
|---|---|---|---|---|---|
| **KeyBuzz Consulting** (A) | `keybuzz-consulting-mo9y479d` | `funnel-kbc-001` | 8 (6 pré-tenant + 2 post-tenant) | pro | Funnel complet |
| **Keybuzz** (B) | `keybuzz-mnqnjna8` | `funnel-kb-001` | 4 (3 pré-tenant + 1 post-tenant) | starter | Funnel partiel |

---

## 2. VÉRIFICATION API DIRECTE

### API backend (depuis pod, sans proxy Admin)

| Appel | Attendu | Résultat |
|---|---|---|
| `GET /funnel/metrics` (global, sans dates) | 12 events, 2 funnels | **PASS** — register: 2, plan: 2, email: 2, otp: 1, tenant: 2, checkout: 1 |
| `GET /funnel/metrics?tenant_id=keybuzz-consulting-mo9y479d` (sans dates) | 8 events, cohort_size: 1 | **PASS** — register: 1, plan: 1, ..., checkout: 1, **tous counts = 1** |
| `GET /funnel/metrics?tenant_id=keybuzz-mnqnjna8` (sans dates) | 4 events, cohort_size: 1 | **PASS** — register: 1, plan: 1, email: 1, tenant: 1, rest: 0 |
| `GET /funnel/events?tenant_id=keybuzz-consulting-mo9y479d` | 8 events, 6 avec tenant_id=null | **PASS** — cohort stitching correct |
| `GET /funnel/events?tenant_id=keybuzz-mnqnjna8` | 4 events, aucune fuite KBC | **PASS** — isolation OK |
| `GET /funnel/metrics?from=2026-01-01&to=2026-04-23` | counts > 0 | **FAIL** — tous counts = 0 (voir Bug 2) |
| `GET /funnel/metrics?from=2026-01-01&to=2026-04-24` | counts > 0 | **PASS** — counts corrects |

**Conclusion API** : L'API backend fonctionne parfaitement. Le cohort stitching est correct. L'isolation tenant est confirmée.

---

## 3. VALIDATION NAVIGATEUR DEV

### A. Navigation

| Test | Résultat |
|---|---|
| Login OK | PASS |
| Menu Marketing visible | PASS — 6 items |
| Funnel en position 2 | PASS |
| Icône Funnel (Filter) visible | PASS |

### B. Tenant A (KeyBuzz Consulting)

| Test | Attendu | Résultat |
|---|---|---|
| Page /marketing/funnel charge | Oui | PASS (après correction date) |
| KPI "Funnels observés" | **1** (tenant-scoped) | **FAIL — affiche 2** (global) |
| KPI "Dernière étape" | **1** | PASS (identique global/tenant) |
| KPI "Conversion globale" | **100%** (1→1 pour KBC) | **FAIL — affiche 50%** (global) |
| Funnel steps register_started | **1** | **FAIL — affiche 2** (global) |
| Funnel steps tenant_created | **1** | **FAIL — affiche 2** (global) |
| Section "Événements récents" | 8 events KBC | **PASS — affiche 8 events** |
| Events sont tous funnel-kbc-001 | Oui | PASS |
| Events montrent tenant_id=null (pré-tenant) | 6 events avec "—" | PASS |
| Events montrent tenant_id=keybuzz- (post) | 2 events | PASS |
| NaN / undefined / Infinity | 0 | 0 — PASS |
| Mock / faux data | 0 | 0 — PASS |

### C. Asymétrie confirmée

| Section | Source | Scope |
|---|---|---|
| KPI cards | proxy metrics | **GLOBAL** (Bug 1) |
| Funnel visualisation | proxy metrics | **GLOBAL** (Bug 1) |
| Détail par étape | proxy metrics | **GLOBAL** (Bug 1) |
| Business Truth counts | proxy metrics | **GLOBAL** (Bug 1) |
| Événements récents | proxy events | **TENANT-SCOPED** (correct) |

---

## 4. BUGS IDENTIFIÉS

### Bug 1 — CRITIQUE : Proxy metrics ne transmet pas `tenant_id` au backend

**Fichier** : `src/app/api/admin/marketing/funnel/metrics/route.ts`

**Cause racine** : Le proxy lit `tenantId` depuis les search params et le passe comme 3e argument à `proxyGet()` (pour le header `x-tenant-id`), mais ne l'ajoute **PAS** aux `apiParams` en tant que query parameter `tenant_id`.

```typescript
// ACTUEL (bugué)
const apiParams = new URLSearchParams();
if (from) apiParams.set('from', from);
if (to) apiParams.set('to', to);
return proxyGet('/funnel/metrics', session, tenantId, apiParams);
// tenant_id ABSENT des apiParams → l'API backend ne filtre pas
```

**Comparaison** : Le proxy events fait correctement :
```typescript
if (tenantId) apiParams.set('tenant_id', tenantId);
```

**Impact** : Les métriques (KPIs, funnel, détail) affichent des données GLOBALES quel que soit le tenant sélectionné. Seule la section événements est correctement tenant-scoped.

**Fix attendu** : Ajouter `if (tenantId) apiParams.set('tenant_id', tenantId);` dans le proxy metrics.

### Bug 2 — MINEUR : Filtre date `to` exclut les events du jour courant

**Cause** : L'API traite le paramètre `to` comme `2026-04-23T00:00:00Z`, excluant les events créés plus tard le même jour.

**Impact** : Si `dateTo` est la date du jour (défaut de l'UI), les events injectés le même jour n'apparaissent pas.

**Workaround** : Mettre `dateTo = tomorrow` ou modifier l'API pour traiter `to` comme `to + 1 day` (end of day inclusive).

**Priorité** : Basse (edge case cosmétique, ne bloque pas la validation fondamentale).

---

## 5. VÉRITÉ MÉTIER

### Le bloc "Business Truth" est-il juste ?

**OUI** — Le bloc est factuellement correct :
- Il distingue clairement les micro-steps onboarding internes de la table `funnel_events`
- Il mentionne explicitement que `trial_started` et `purchase_completed` sont des événements Stripe envoyés vers Meta CAPI / webhooks via Destinations
- Il précise que les micro-steps "ne partent pas vers Meta/TikTok/Google"

### La page est-elle exploitable pour le CRO ?

**PARTIELLEMENT** — La visualisation du funnel, les taux de conversion step-by-step, les drop-offs et la section événements récents sont tous fonctionnels et corrects dans leur logique d'affichage. Cependant, le Bug 1 (metrics globales au lieu de tenant-scoped) rend les métriques trompeuses quand plusieurs tenants ont des funnels.

### Correction nécessaire avant PROD ?

**OUI — Bug 1 est BLOQUANT** : Le proxy metrics doit transmettre `tenant_id` au backend. Sans ce fix, l'UI montre des données cross-tenant, ce qui est une fuite de scope (même si non sensible dans le contexte admin, c'est une violation du principe de tenant isolation).

---

## 6. NON-RÉGRESSION

| Vérification | Résultat |
|---|---|
| /marketing/funnel | OK (avec données après fix date) |
| /marketing/metrics | OK (non testé en navigateur, pas de code modifié) |
| /marketing/ad-accounts | OK |
| /marketing/destinations | OK |
| /marketing/delivery-logs | OK |
| /marketing/integration-guide | OK |
| Ordre menu Marketing | OK (Metrics, Funnel, Ads, Dest, Logs, Guide) |
| Icônes menu | OK (tous visibles) |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` — INCHANGÉ |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` — INCHANGÉ |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` — INCHANGÉ |

---

## 7. RÉSUMÉ DES PREUVES

### API backend (directe, sans proxy)

- `GET /funnel/metrics?tenant_id=keybuzz-consulting-mo9y479d` → register: 1, checkout: 1, cohort_size: 1 ✓
- `GET /funnel/metrics?tenant_id=keybuzz-mnqnjna8` → register: 1, email: 1, checkout: 0, cohort_size: 1 ✓
- `GET /funnel/events?tenant_id=keybuzz-consulting-mo9y479d` → 8 events, 6 pré-tenant (null) stitchés ✓
- `GET /funnel/events?tenant_id=keybuzz-mnqnjna8` → 4 events, 0 fuite KBC ✓

### UI navigateur

- Metrics (KPIs, funnel, détail) : GLOBAL ✗ (Bug 1)
- Events récents : TENANT-SCOPED ✓ (8 events KBC correctement isolés)
- Section Business Truth : CORRECTE ✓
- Icône menu : VISIBLE ✓
- Aucun NaN/undefined/mock : ✓

---

## 8. VERDICT

**NO GO** — 1 bug bloquant identifié.

### Bug bloquant

**Bug 1** : Le proxy Admin `metrics/route.ts` ne transmet pas `tenant_id` en query param au backend API. Les métriques affichées sont globales au lieu de tenant-scoped.

**Fix requis** : Ajouter 1 ligne dans `src/app/api/admin/marketing/funnel/metrics/route.ts` :
```typescript
if (tenantId) apiParams.set('tenant_id', tenantId);
```

### Ce qui fonctionne

- API backend : cohort stitching OK, tenant isolation OK
- Proxy events : tenant-scoped OK
- Page UI : logique d'affichage OK, Business Truth OK
- Menu + icône : OK
- PROD : inchangée

### Prochaine action recommandée

Un prompt correctif `PH-ADMIN-T8.9C.3-FUNNEL-METRICS-PROXY-TENANT-FIX-01` pour :
1. Ajouter `tenant_id` au proxy metrics
2. (Optionnel) Fixer le edge case `dateTo` pour inclure la fin de journée
3. Rebuild + redeploy Admin DEV
4. Re-valider avec données tenant-scoped

---

## 9. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.9C.2-FUNNEL-CRO-UI-REAL-DATA-VALIDATION-01.md
```
