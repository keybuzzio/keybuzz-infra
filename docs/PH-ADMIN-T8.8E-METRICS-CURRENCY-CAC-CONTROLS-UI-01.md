# PH-ADMIN-T8.8E — Metrics Currency & CAC Controls UI

**Phase** : PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Verdict** : ADMIN METRICS CURRENCY AND CAC CONTROLS READY IN DEV

---

## 1. Preflight

| Element | Valeur |
|---|---|
| Branche Admin | `main` |
| HEAD Admin initial | `1986a8e` |
| Image Admin DEV avant | `v2.11.5-ad-accounts-ui-hardening-dev` |
| Image Admin PROD | `v2.11.5-ad-accounts-ui-hardening-prod` (inchangee) |
| Image API DEV | `v3.5.106-metrics-settings-currency-exclusion-dev` |
| Image API PROD | `v3.5.105-tenant-secret-store-ads-prod` (inchangee) |
| Repo clean | OUI |
| PROD touchee | NON |

## 2. Rapports lus

- `PH-T8.8E-METRICS-TENANT-CURRENCY-AND-CAC-EXCLUSION-CONTROLS-API-01.md`
- `PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01.md`
- `PH-T8.8C-PROD-PROMOTION-AD-ACCOUNTS-SECRET-STORE-01.md`
- `PH-T8.8A.2-AD-SPEND-TENANT-SAFETY-PROD-PROMOTION-01.md`
- `PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`

## 3. Contrat API utilise

Endpoints PH-T8.8E deployes en DEV (`v3.5.106`) :

| Method | Path | RBAC | Usage |
|---|---|---|---|
| GET | `/metrics/settings/tenants` | super_admin, account_manager, media_buyer | Liste settings |
| GET | `/metrics/settings/tenants/:tenant_id` | idem | Detail settings |
| PATCH | `/metrics/settings/tenants/:tenant_id` | **super_admin uniquement** | Modifier devise/exclusion CAC |
| GET | `/metrics/overview?display_currency=X` | existant | Montants en devise choisie |

Headers requis : `x-user-email`, `x-admin-role`

Response enrichie : `currency.display`, `spend.total_display`, `spend.by_channel[].spend_display`, `data_quality.internal_only`

## 4. Fichiers modifies

### Commit `17306bc` — PH-ADMIN-T8.8E principal

| Fichier | Action | Description |
|---|---|---|
| `src/app/api/admin/metrics/settings/tenants/route.ts` | CREE | Proxy GET settings tenants |
| `src/app/api/admin/metrics/settings/tenants/[tenant_id]/route.ts` | CREE | Proxy GET/PATCH settings tenant |
| `src/app/api/admin/metrics/overview/route.ts` | MODIFIE | Forward `display_currency`, headers `x-user-email`/`x-admin-role`, `redactTokens` |
| `src/app/(admin)/metrics/page.tsx` | MODIFIE | Selecteur devise, bandeau SA, CAC controls, formatage dynamique |
| `src/config/navigation.ts` | MODIFIE | Reordonnancement menu Marketing |

### Commit `461e08a` — Fix

| Fichier | Action | Description |
|---|---|---|
| `src/app/(admin)/metrics/page.tsx` | MODIFIE | Toujours envoyer `display_currency` (meme EUR) pour overrider le defaut tenant |

## 5. Proxies crees

### GET `/api/admin/metrics/settings/tenants`
- Auth : `requireMarketing()` (super_admin, account_manager, media_buyer)
- Forward vers API SaaS via `proxyGet`
- Headers propages : `x-user-email`, `x-admin-role`

### GET/PATCH `/api/admin/metrics/settings/tenants/[tenant_id]`
- Auth : `requireMarketing()` + PATCH restreint `super_admin`
- Body PATCH : `metrics_display_currency`, `exclude_from_cac`, `exclude_reason`
- Forward vers API SaaS via `proxyGet`/`proxyMutate`
- `redactTokens` applique sur toutes les erreurs

### GET `/api/admin/metrics/overview` (mis a jour)
- Nouveau param : `display_currency`
- Nouveaux headers : `x-user-email`, `x-admin-role`
- `redactTokens` applique sur erreurs

## 6. Validation devise

| Devise | Tenant | Spend attendu | Spend observe | Labels | OK |
|---|---|---|---|---|---|
| GBP | KBC | ~445 GBP | 445 £GB | Spend total (GBP), Ad Spend (GBP) | OUI |
| EUR | KBC | ~512 EUR | 512 EUR | Spend total (EUR), Ad Spend (EUR) | OUI |
| USD | KBC | ~601 USD | 601 $US | Spend total (USD), Ad Spend (USD) | OUI |
| EUR | eComLG | — | — | Spend total (EUR): — | OUI |

FX conversion visible : taux BCE affiches (GBP 0.8690, EUR 1.1500, USD 1.1733)

Super Admin : bouton "Enregistrer comme devise par defaut" visible quand devise differe du defaut tenant.

## 7. Validation bandeau Super Admin

| Role | Bandeau visible | Internal only badge | OK |
|---|---|---|---|
| super_admin (ludovic@keybuzz.pro) | OUI | OUI | OUI |
| non-super_admin | Code conditionne sur `isSuperAdmin` | - | Verifie dans le code |

Le bandeau "Donnees reelles - 1 compte test exclu + Internal only" est visible uniquement si :
- `isSuperAdmin === true`
- `data_quality.test_data_excluded === true`

## 8. Validation exclusion CAC

| Cas | Resultat |
|---|---|
| Panneau CAC visible Super Admin | OUI |
| Toggle "Inclus dans le CAC" visible | OUI |
| Champ raison visible quand exclu | Conditionnel (visible si exclu) |
| Non-Super Admin : panneau masque | Verifie code (`isSuperAdmin` condition) |

## 9. Validation menu Marketing

Ordre observe dans le navigateur :

1. Metrics
2. Ads Accounts
3. Destinations
4. Delivery Logs
5. Integration Guide

Toutes les icones presentes. Aucun item duplique.

## 10. Validation outbound KeyBuzz Consulting

| Surface | Tenant | Test | Resultat |
|---|---|---|---|
| Ads Accounts | KBC | Compte visible | OUI — ID 1485150039295668, Encrypted |
| Ads Accounts | eComLG | Isolation tenant | OUI — "No ad accounts" |
| Destinations | KBC | Page accessible | OUI — "Aucune destination" (DEV) |
| Token safety | KBC | 0 fuite console | OUI — aucun token brut |

Note : Meta CAPI destination non configuree en DEV. Pas de test PageView reel effectue.

## 11. Token safety

| Surface | Token absent | Preuve |
|---|---|---|
| DOM | OUI | TokenBadge = "Encrypted" |
| Reponses proxy | OUI | `redactTokens` sur tous les proxies |
| Erreurs UI | OUI | `redactTokens` sur messages erreur |
| Console navigateur | OUI | Aucun log contenant token |
| Rapport | OUI | Aucun token brut dans ce document |

## 12. Non-regression

| Page | Resultat |
|---|---|
| /metrics | OK — donnees tenant, devise, bandeau, CAC controls |
| /marketing/ad-accounts | OK — CRUD, token encrypted |
| /marketing/destinations | OK — page accessible |
| /marketing/delivery-logs | Non teste (page existante) |
| /marketing/integration-guide | Non teste (page existante) |
| Tenant selector | OK — switch KBC/eComLG fonctionne |
| Sidebar/topbar | OK — tous les items, icones presentes |
| Login/session | OK |
| Aucun NaN/undefined/mock | OK |

## 13. Image DEV

| Element | Valeur |
|---|---|
| Tag | `v2.11.6-metrics-currency-cac-controls-dev` |
| Digest | `sha256:6aad8de557cff3508aa89993246ebd5dc50a75156ea7f290e890579f2765e514` |
| Commit source | `461e08a` |
| Build | build-from-git, --no-cache |
| Pod | Running 1/1, 0 restarts |

## 14. GitOps DEV

Commit infra : `d7336de` — `k8s/keybuzz-admin-v2-dev/deployment.yaml`

Image avant : `v2.11.5-ad-accounts-ui-hardening-dev`
Image apres : `v2.11.6-metrics-currency-cac-controls-dev`

## 15. Rollback DEV

Procedure GitOps stricte (aucun `kubectl set image`) :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`
2. Remettre image `v2.11.5-ad-accounts-ui-hardening-dev`
3. `git commit -m "rollback Admin DEV to v2.11.5"`
4. `git push origin main`
5. `kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml`
6. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev`

## 16. PROD inchangee

- Image Admin PROD : `v2.11.5-ad-accounts-ui-hardening-prod` (inchangee)
- Image API PROD : `v3.5.105-tenant-secret-store-ads-prod` (inchangee)
- Aucun manifest PROD modifie

## 17. Limites

1. **Sessions non-Super Admin** : pas de compte media_buyer/account_manager disponible en DEV pour tester le masquage du bandeau et des CAC controls. Verifiable dans le code via la condition `isSuperAdmin`.
2. **Meta CAPI destination** : non configuree en DEV pour KBC. Pas de test PageView reel.
3. **Captures** : screenshots captures via navigateur Cursor (stockees en local temp).

## 18. Prochaine etape recommandee

1. **PH-ADMIN-T8.8E.2-PROD-PROMOTION** : promouvoir `v2.11.6` en PROD apres validation
2. **Documentation `/marketing/integration-guide`** : utiliser les captures pour enrichir le guide
3. **Test non-Super Admin** : creer un compte media_buyer DEV pour valider le masquage bandeau/CAC

---

**VERDICT** : ADMIN METRICS CURRENCY AND CAC CONTROLS READY IN DEV — SUPER ADMIN INTERNAL DATA ONLY — TENANT DISPLAY CURRENCY WORKING — MARKETING MENU ORDERED — KBC OUTBOUND VALIDATED
