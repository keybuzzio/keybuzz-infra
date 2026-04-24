# PH-ADMIN-T8.10K-OWNER-COCKPIT-PROD-PROMOTION-01 — TERMINÉ

**Verdict : GO STRUCTUREL MAIS VALIDATION NAVIGATEUR PARTIELLE**

**Date :** 2026-04-24
**Environnement :** PROD
**API/Client PROD inchangées :** oui

---

## Préflight

| Élément | Valeur | Conforme |
|---|---|---|
| Admin branche | `main` | OK |
| Admin HEAD | `dad2fa5` — fix(metrics): prevent race condition | OK |
| Admin status | clean | OK |
| Admin DEV validée | `v2.11.14-owner-cockpit-browser-truth-fix-dev` | OK |
| Admin PROD pré-promo | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` | OK |
| API PROD | `v3.5.116-marketing-owner-stack-prod` | INCHANGÉE |

---

## Source à promouvoir

Vérification complète de `main` (HEAD `dad2fa5`) :

| Brique | Point vérifié | Résultat |
|---|---|---|
| Owner cockpit UI | `scope=owner` dans 3 proxies (metrics, funnel/metrics, funnel/events) | OK |
| Bandeau owner Metrics | 4 refs `owner_cohort` dans page.tsx | OK |
| Bandeau owner Funnel | 4 refs `owner_cohort` dans page.tsx | OK |
| Labels funnel 16 steps | `activation_completed` présent (#16) | OK |
| Tenant guard | `assertTenantAccess()` dans proxy.ts (L21, L67, L85) + metrics/overview + delivery-logs | OK |
| Bypass super_admin/ops_admin | `GLOBAL_ROLES = ['super_admin', 'ops_admin']` | OK |
| 403 TENANT_NOT_ASSIGNED | Code erreur (L39) | OK |
| Browser fix Metrics | `if (!tenantId) return;` (L203, L287) | OK |
| Browser fix Funnel | `if (!tenantId) return;` (L97) | OK |

Source complète — build autorisé.

---

## Build PROD

| Élément | Valeur |
|---|---|
| Commit | `dad2fa5` |
| Branche | `main` |
| Repo | clean |
| Tag | `v2.11.14-owner-cockpit-browser-truth-fix-prod` |
| Digest | `sha256:145afb0ddf2a644f2594ae8407260a60643eed735d07a50898c53af6050731ee` |
| Build-from-git | oui |
| Next.js build | ✓ Compiled successfully, 42 pages, 0 errors |

---

## GitOps PROD

| Élément | Valeur |
|---|---|
| Manifest modifié | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `v2.11.11-funnel-metrics-tenant-proxy-fix-prod` |
| Image après | `v2.11.14-owner-cockpit-browser-truth-fix-prod` |
| Commit infra | `233ca43` |
| API PROD manifest | INCHANGÉ (`v3.5.116-marketing-owner-stack-prod`) |
| Client PROD manifest | INCHANGÉ (`v3.5.116-marketing-owner-stack-prod`) |
| Admin DEV manifest | INCHANGÉ (`v2.11.14-owner-cockpit-browser-truth-fix-dev`) |

### Rollback PROD

```bash
sed -i 's|v2.11.14-owner-cockpit-browser-truth-fix-prod|v2.11.11-funnel-metrics-tenant-proxy-fix-prod|' k8s/keybuzz-admin-v2-prod/deployment.yaml
```

---

## Déploiement PROD

| Élément | Valeur |
|---|---|
| Pod | `keybuzz-admin-v2-7749dfbd9b-6wjdv` |
| Phase | Running |
| Ready | true |
| Restarts | 0 |
| Image runtime | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.14-owner-cockpit-browser-truth-fix-prod` |
| Digest runtime | `sha256:145afb0ddf2a644f2594ae8407260a60643eed735d07a50898c53af6050731ee` |
| Méthode | `kubectl apply -f` manifest GitOps |

---

## Validation structurelle PROD

| Point | Attendu | Résultat |
|---|---|---|
| `owner_cohort` dans bundle | Présent | OK — 2 fichiers server |
| `owner-scoped` dans bundle | Présent | OK — 2 fichiers server |
| `TENANT_NOT_ASSIGNED` dans bundle | Présent | OK — 13 fichiers server |
| `scope=owner` dans bundle | Présent | OK — 6 fichiers server |
| Owner banner dans static chunks | Présent | OK — 6 chunks |
| `activation_completed` dans static | Présent | OK — 1 chunk |
| Proxy metrics/overview | Route `route.js` | OK |
| Proxy funnel/metrics | Route `route.js` | OK |
| Proxy funnel/events | Route `route.js` | OK |
| Proxy delivery-logs | Route `route.js` | OK |

---

## Validation navigateur PROD

| Test navigateur | Attendu | Résultat |
|---|---|---|
| Login super_admin PROD | Session active | **NON DISPONIBLE** — credentials non fournis |
| KBC /metrics owner banner | Visible | Validé structurellement |
| KBC /funnel owner banner | Visible | Validé structurellement |
| Compte non-global KBC | 403 cross-tenant | Validé structurellement |
| Pages marketing sans crash | UX intacte | Validé structurellement |

**Note :** La validation navigateur E2E nécessite les credentials de l'opérateur. La preuve est substituée par la validation structurelle du bundle déployé + validation directe API.

---

## Validation contrat proxy / API

| Couche | Point vérifié | Résultat |
|---|---|---|
| API PROD `/metrics/overview?scope=owner` | `scope=owner`, `owner_cohort.total=2`, `new_customers=1` | OK |
| API PROD `/funnel/metrics?scope=owner` | `scope=owner`, `cohort_size=1`, 16 steps, 3 events non-zero | OK |
| API PROD `/funnel/events?scope=owner` | `scope=owner`, `count=3`, `owner_cohort.total=2` | OK |
| Admin proxy metrics/overview | `scope=owner` dans route.js compilé | OK (1 match) |
| Admin proxy funnel/metrics | `scope=owner` dans route.js compilé | OK (1 match) |
| Admin proxy funnel/events | `scope=owner` dans route.js compilé | OK (1 match) |
| Tenant guard | `TENANT_NOT_ASSIGNED` dans 13 fichiers server | OK |
| Bypass super_admin/ops_admin | `GLOBAL_ROLES` dans 22 fichiers server | OK |

### Données owner-scoped PROD (vérité API)

- **Owner :** `keybuzz-consulting-mo9zndlk`
- **Enfants :** `test-owner-runtime-p-modeeozl`
- **Cohorte total :** 2 tenants
- **new_customers :** 1
- **spend.total_display :** 512.89 EUR
- **Funnel cohort_size :** 1
- **Funnel steps non-zero :** register_started=1, plan_selected=1, email_submitted=1
- **Funnel events :** 3

---

## Non-régression

| Surface | Attendu | Résultat |
|---|---|---|
| Marketing ad-accounts route | Présente | OK |
| Marketing destinations route | Présente | OK |
| Marketing delivery-logs route | Présente | OK |
| Marketing funnel/metrics route | Présente | OK |
| Marketing funnel/events route | Présente | OK |
| API PROD health | `status=ok` | OK |
| Admin PROD pod | Running, Ready, 0 restarts | OK |
| Metrics tenant-scoped legacy | `scope=tenant`, pas d'owner_cohort | OK |
| Tenant selector route | Présente | OK |
| API PROD | `v3.5.116-marketing-owner-stack-prod` | INCHANGÉE |
| Client PROD | `v3.5.116-marketing-owner-stack-prod` | INCHANGÉE |

---

## Captures

Non réalisables — session navigateur non authentifiable (credentials non disponibles). La validation est basée sur :
- Preuve structurelle du bundle déployé
- Preuve API directe via kubectl exec sur les pods PROD

---

## Digest

| Service | Tag | Digest |
|---|---|---|
| Admin PROD | `v2.11.14-owner-cockpit-browser-truth-fix-prod` | `sha256:145afb0ddf2a644f2594ae8407260a60643eed735d07a50898c53af6050731ee` |

---

## Gaps restants

| Gap | Description | Priorité |
|---|---|---|
| Validation navigateur E2E PROD | Login non réalisable sans credentials — substituée par preuves structurelles + API | À compléter par l'opérateur |
| Captures screenshots PROD | Non réalisables sans session authentifiée | À compléter par l'opérateur |
| Preuve runtime StartTrial/payment owner-aware | Non atteinte — nécessite signup réel/simulé | Phase ultérieure |
| Funnel borne haute `to` en PROD API | Le fix `created_at < date + 1 day` est en DEV API uniquement (`v3.5.116-owner-cockpit-browser-truth-fix-dev`) — pas encore en PROD API | À promouvoir séparément |
| Owner agency RBAC fin | Pas de granularité fine read-only vs write pour `media_buyer` | Basse |
| Polish UI owner cockpit | Tooltips, détail enfants, storytelling | Cosmétique |
| Contrat LP/funnels externes owner-scoped | Source funnels externes non finalisée | Phase ultérieure |

---

## API/Client PROD inchangées

| Service | Image PROD | Modifié ? |
|---|---|---|
| API | `v3.5.116-marketing-owner-stack-prod` | **NON** |
| Client | `v3.5.116-marketing-owner-stack-prod` | **NON** |

---

## Conclusion

La promotion PROD de l'Admin owner cockpit est complète :

1. **Proxies owner-scoped** : Les 3 proxies marketing (metrics/overview, funnel/metrics, funnel/events) transmettent `scope=owner` à l'API PROD
2. **Bandeau owner** : Le bandeau `owner_cohort` est présent dans le bundle pour `/metrics` et `/marketing/funnel`
3. **16 steps funnel** : Labels complets avec `activation_completed` en #16
4. **Tenant guard** : `assertTenantAccess()` bloque les appels cross-tenant forgés pour les rôles non-globaux, avec bypass pour `super_admin`/`ops_admin`
5. **Fix navigateur Metrics** : Le guard `if (!tenantId) return;` empêche la race condition qui écrasait les données owner-scoped
6. **API PROD** confirme la vérité owner-scoped : `scope=owner`, `owner_cohort.total=2`, `new_customers=1`, 1 funnel avec 3 events

**Rapport :** `keybuzz-infra/docs/PH-ADMIN-T8.10K-OWNER-COCKPIT-PROD-PROMOTION-01.md`

**OWNER COCKPIT LIVE IN PROD — ADMIN MARKETING PAGES NOW CONSUME OWNER-SCOPED DATA — TENANT GUARD PRESERVED — API/CLIENT PROD UNCHANGED**
