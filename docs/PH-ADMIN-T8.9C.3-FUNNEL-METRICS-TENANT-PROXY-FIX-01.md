# PH-ADMIN-T8.9C.3 — Funnel Metrics Tenant Proxy Fix

**Phase** : PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : micro-fix proxy Admin Funnel metrics tenant scope
**Priorité** : P0

---

## 0. PRÉFLIGHT

| Élément | Valeur | Conforme |
|---|---|---|
| Branche Infra | `main` | OK |
| HEAD Infra | `2dd81e6` | OK |
| Admin DEV avant | `v2.11.10-funnel-menu-icon-fix-dev` | OK |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` | INCHANGÉ |
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` | OK |
| HEAD Admin avant | `2c3db25` | OK |
| Repo | clean | OK |

---

## 1. CAUSE RACINE

Le proxy Admin `src/app/api/admin/marketing/funnel/metrics/route.ts` lisait `tenantId` depuis les search params mais ne le forwardait **pas** comme query parameter `tenant_id` vers l'API backend.

| Proxy | `tenantId` lu ? | `tenant_id` forwardé ? | Statut |
|---|---|---|---|
| **metrics** | OUI | **NON** | BUG |
| **events** | OUI | **OUI** | OK |

L'API backend `GET /funnel/metrics` attend `tenant_id` dans le querystring (pas dans le header `x-tenant-id`). Sans ce paramètre, elle retourne les métriques globales (tous tenants confondus).

---

## 2. PATCH MINIMAL

**Fichier** : `src/app/api/admin/marketing/funnel/metrics/route.ts`

**Changement** : 1 ligne ajoutée après les paramètres `from`/`to` :

```typescript
if (tenantId) apiParams.set('tenant_id', tenantId);
```

**Commit** : `63f9ed3` — `fix(proxy): forward tenant_id query param in funnel/metrics proxy route`

Rien d'autre n'a été modifié. Ni l'API, ni la DB, ni la page Funnel, ni le proxy events, ni le menu.

---

## 3. VALIDATION API (via navigateur)

L'API backend a été confirmée fonctionnelle via `curl` depuis le pod API (données test réinjectées lors de PH-ADMIN-T8.9C.2) :

| Appel | Attendu | Résultat |
|---|---|---|
| `/funnel/metrics?tenant_id=keybuzz-consulting-mo9y479d` | register: 1, tous steps: 1, cohort: 1 | PASS |
| `/funnel/metrics?tenant_id=keybuzz-mnqnjna8` | register: 1, email: 1, otp: 0, checkout: 0, cohort: 1 | PASS |
| `/funnel/events?tenant_id=keybuzz-consulting-mo9y479d` | 8 events | PASS |
| `/funnel/events?tenant_id=keybuzz-mnqnjna8` | 4 events, 0 fuite KBC | PASS |

---

## 4. VALIDATION NAVIGATEUR DEV

### Tenant A — KeyBuzz Consulting

| Test | Attendu | Résultat |
|---|---|---|
| Page /marketing/funnel charge | Oui | PASS |
| Tenant selector | KeyBuzz Consulting | PASS |
| KPI "Funnels observés" | **1** | **PASS** (avant fix : 2 global) |
| KPI "Dernière étape" | 1 | PASS |
| KPI "Conversion globale" | **100.0%** | **PASS** (avant fix : 50% global) |
| Steps register → checkout | Tous à 1 (sauf oauth: 0) | PASS |
| Événements récents | 8 events | PASS |
| NaN / undefined / Infinity | 0 | PASS |

### Tenant B — Keybuzz

| Test | Attendu | Résultat |
|---|---|---|
| Tenant selector | Keybuzz | PASS |
| KPI "Funnels observés" | 1 | PASS |
| KPI "Dernière étape" | **0** | **PASS** (checkout: 0, funnel incomplet) |
| KPI "Conversion globale" | **0.0%** | **PASS** |
| Steps register/plan/email | 1 | PASS |
| Steps otp/company/user/checkout | **0** | **PASS** (funnel partiel) |
| tenant_created | 1 | PASS |
| Événements récents | **4** | **PASS** (vs 8 pour Tenant A — aucune fuite) |

### Vérifications globales

| Test | Résultat |
|---|---|
| Icône Funnel (Filter) | Visible |
| Menu Marketing ordre | Inchangé |
| NaN / undefined | 0 |
| Token brut visible | 0 |
| Mock / faux data | 0 |
| Overlap visuel | 0 |

---

## 5. IMAGE DEV

| Élément | Valeur |
|---|---|
| Image DEV avant | `v2.11.10-funnel-menu-icon-fix-dev` |
| Image DEV après | `v2.11.11-funnel-metrics-tenant-proxy-fix-dev` |
| Commit Admin | `63f9ed3` |
| Digest | `sha256:895bf61551d4ea58a4524bf62239975aba4cf41354a0cffa82b90fb4a6353bc2` |
| Commit Infra | `9ef4cc2` |
| ROLLBACK DEV | `v2.11.10-funnel-menu-icon-fix-dev` |

---

## 6. NON-RÉGRESSION

| Vérification | Résultat |
|---|---|
| /marketing/funnel | OK — tenant-scoped confirmé |
| /marketing/metrics | OK (non modifié) |
| /marketing/ad-accounts | OK |
| /marketing/destinations | OK |
| /marketing/delivery-logs | OK |
| /marketing/integration-guide | OK |
| Menu Marketing ordre | OK |
| Icône Funnel | OK |
| Admin PROD | `v2.11.8-agency-tracking-playbook-prod` — INCHANGÉ |
| API DEV | `v3.5.109-funnel-metrics-tenant-scope-dev` — INCHANGÉ |
| API PROD | `v3.5.107-ad-spend-idempotence-fix-prod` — INCHANGÉ |
| Client PROD | `v3.5.81-tiktok-attribution-fix-prod` — INCHANGÉ |

---

## 7. LIMITATION CONNUE

### Filtre date `to` (API-side)

Le paramètre `to` de l'API `GET /funnel/metrics` est traité comme `2026-04-23T00:00:00Z`, excluant les events créés plus tard dans la même journée.

**Impact** : Si la date "au" dans l'UI est la date du jour, les events injectés le même jour n'apparaissent pas.

**Workaround** : Utiliser `to = lendemain` dans le sélecteur de dates.

**Correction** : À faire dans une future phase SaaS API si nécessaire (modifier le backend pour traiter `to` comme fin de journée inclusive : `to + '23:59:59'` ou `to + 1 day`).

**Non corrigé dans cette phase** : Conformément aux règles, seul le proxy Admin a été modifié.

---

## 8. CHEMIN COMPLET DU RAPPORT

```
keybuzz-infra/docs/PH-ADMIN-T8.9C.3-FUNNEL-METRICS-TENANT-PROXY-FIX-01.md
```

---

**VERDICT** : FUNNEL METRICS TENANT PROXY FIXED IN DEV — UI NOW MATCHES TENANT-SCOPED API TRUTH — NO REGRESSION — PROD UNTOUCHED
