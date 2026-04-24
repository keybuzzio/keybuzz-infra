# PH-ADMIN-T8.8E — PROD Promotion Metrics Currency & CAC Controls UI

> **Phase** : PH-ADMIN-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-UI-01
> **Date** : 2026-04-23
> **Environnement** : PROD
> **Image PROD** : `v2.11.6-metrics-currency-cac-controls-prod`
> **Digest** : `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57`
> **Commit source** : `461e08a` (branche `main`)
> **Image PROD precedente** : `v2.11.5-ad-accounts-ui-hardening-prod`
> **API PROD** : `v3.5.106-metrics-settings-currency-exclusion-prod`

---

## 1. PREFLIGHT

| Element | Valeur |
|---------|--------|
| Branche Admin | `main` |
| HEAD Admin | `461e08a` |
| Repo clean | OUI |
| Local = Remote | OUI |
| Admin DEV validee | `v2.11.6-metrics-currency-cac-controls-dev` |
| Admin PROD avant | `v2.11.5-ad-accounts-ui-hardening-prod` |
| API PROD | `v3.5.106-metrics-settings-currency-exclusion-prod` |
| API PROD prete | OUI |

---

## 2. RAPPORTS RELUS

- `PH-T8.8E-PROD-PROMOTION-METRICS-CURRENCY-CAC-CONTROLS-API-01.md`
- `PH-ADMIN-T8.8E-METRICS-CURRENCY-CAC-CONTROLS-UI-01.md`
- `PH-ADMIN-T8.8E.1-METRICS-OUTBOUND-READINESS-COMPLETION-01.md`
- `PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01.md`

---

## 3. VERIFICATION SOURCE

| Point | Resultat |
|-------|----------|
| Proxy `/api/admin/metrics/settings/tenants` | OK (440 octets) |
| Proxy `/api/admin/metrics/settings/tenants/[tenant_id]` (GET+PATCH) | OK (1208 octets) |
| `display_currency` forward dans overview | OK (2 occurrences) |
| `display_currency` toujours envoye (fix 461e08a) | OK |
| Headers `x-user-email`, `x-admin-role` | OK (2 occurrences) |
| `redactTokens` dans overview | OK (3 occurrences) |
| Selecteur devise EUR/GBP/USD | OK (13 references) |
| `isSuperAdmin`/`super_admin` dans metrics page | OK (6 checks) |
| PATCH RBAC `super_admin` uniquement | OK (ligne 27) |
| Menu Marketing : Metrics, Ads Accounts, Destinations, Delivery Logs, Integration Guide | OK |

---

## 4. BUILD PROD

| Element | Valeur |
|---------|--------|
| Commit source | `461e08a` |
| Repo | clean, build-from-git |
| Build | `docker build --no-cache` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.6-metrics-currency-cac-controls-prod` |
| Digest | `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57` |
| Push GHCR | OK |

---

## 5. GITOPS PROD

| Element | Valeur |
|---------|--------|
| Manifest | `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `v2.11.5-ad-accounts-ui-hardening-prod` |
| Image apres | `v2.11.6-metrics-currency-cac-controls-prod` |
| Commit infra | `8c9b824` |
| Push | OK (origin/main) |
| Apply | `kubectl apply -f` — `deployment.apps/keybuzz-admin-v2 configured` |
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-admin-v2-74bdbc659c-hq4ts` — Running 1/1, 0 restarts |
| Digest runtime | `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57` (correspond) |

---

## 6. VALIDATION NAVIGATEUR PROD

### 6.1 Navigation

| Test | Resultat |
|------|----------|
| Login `admin.keybuzz.io` | OK |
| Topbar | OK |
| Tenant selector | OK (16 tenants visibles) |
| Sidebar | OK |
| Menu Marketing dans l'ordre | OK (Metrics, Ads Accounts, Destinations, Delivery Logs, Integration Guide) |

### 6.2 Metrics — KeyBuzz Consulting PROD

| Devise | Spend observe | Labels | OK |
|--------|---------------|--------|-----|
| GBP (defaut KBC) | **761 £GB** | Spend total (GBP) | OUI |
| EUR | **875 EUR** | Spend total (EUR) | OUI |
| USD | **1 027 $US** | Spend total (USD) | OUI |

- Aucun NaN / undefined
- Labels coherents avec devise
- Bouton "Enregistrer comme devise par defaut" visible (Super Admin, devise != default)
- Controle CAC "Inclus dans le CAC" visible (Super Admin)

### 6.3 Metrics — eComLG (isolation tenant)

| Test | Resultat |
|------|----------|
| Aucun spend KBC visible | OK |
| Bandeau amber "Aucune donnee reelle de depenses" | OK |
| Isolation tenant | OK |
| Controle CAC visible (Super Admin) | OK |

### 6.4 Super Admin

| Test | Resultat |
|------|----------|
| Bandeau "Donnees reelles" | Visible (KBC avec test data excluded) |
| Badge "Internal only" | Present |
| Controle CAC | Visible |
| Bouton devise defaut | Visible quand devise != default |

### 6.5 Non-Super Admin

| Test | Methode | Resultat |
|------|---------|----------|
| Bandeau masque | Code review | `isSuperAdmin` verifie |
| CAC masque | Code review | `isSuperAdmin` verifie |
| PATCH bloque | Code review | 403 si non-super_admin |

**Limite** : Pas de session non-Super Admin disponible en PROD.

---

## 7. VALIDATION PAGES MARKETING PROD

| Page | Resultat |
|------|----------|
| `/marketing/ad-accounts` | OK — KBC visible, token "Encrypted" |
| `/marketing/destinations` | OK — page charge |
| `/marketing/delivery-logs` | OK — page charge |
| `/marketing/integration-guide` | OK — Quick Start, Events, HMAC, Bonnes pratiques |

---

## 8. TOKEN SAFETY PROD

| Surface | Token absent | Preuve |
|---------|-------------|--------|
| DOM | OUI | "Encrypted" badge |
| Proxies | OUI | `redactTokens` server-side |
| Console | OUI | Uniquement Next-Auth polling (non-bloquant) |
| Ce rapport | OUI | Aucun token brut |

---

## 9. NON-REGRESSION

| Page | Resultat |
|------|----------|
| `/metrics` | OK — devises, bandeau, CAC, tenant scope |
| `/marketing/ad-accounts` | OK — KBC visible, Encrypted |
| `/marketing/destinations` | OK |
| `/marketing/delivery-logs` | OK |
| `/marketing/integration-guide` | OK |
| Tenant selector | OK |
| Sidebar / topbar | OK |
| Login / session | OK |
| Aucun NaN / undefined / mock | OK |
| API PROD | `v3.5.106` — inchangee |
| Admin DEV | `v2.11.6-metrics-currency-cac-controls-dev` — inchangee |

---

## 10. ROLLBACK PROD

**Image rollback** : `v2.11.5-ad-accounts-ui-hardening-prod`

**Procedure GitOps stricte** :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`
2. Remettre `image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.5-ad-accounts-ui-hardening-prod`
3. `git add` + `git commit` + `git push`
4. `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod`

**AUCUN** `kubectl set image` / `kubectl patch` / `kubectl edit` — GitOps strict uniquement.

---

## 11. LIMITES

| Limite | Impact | Resolution |
|--------|--------|------------|
| Pas de session non-Super Admin en PROD | Faible | Code review confirme RBAC. A tester avec compte dedie |
| CAC toggle non teste (pas de modification en PROD) | Attendu | Conformement aux regles : ne pas modifier sans restaurer |
| Aucune destination Meta CAPI creee | Attendu | Phase dediee Meta CAPI a venir |

---

## 12. PROCHAINE ETAPE

- Configuration reelle outbound Meta CAPI KBC
- Enrichissement Integration Guide (Ads Accounts, Meta Ads sync, anti-doublon, Addingwell)
- Test non-Super Admin avec compte dedie

---

## 13. VERDICT

**ADMIN METRICS CURRENCY AND CAC CONTROLS LIVE IN PROD — SUPER ADMIN INTERNAL DATA ONLY — TENANT DISPLAY CURRENCY WORKING — API V3.5.106 CONSUMED SAFELY**

| Element | Valeur |
|---------|--------|
| Image PROD | `v2.11.6-metrics-currency-cac-controls-prod` |
| Digest | `sha256:532bc30177982eb6fda2febc885dc1605952c2b0562c1b7f1da480ea074f0d57` |
| Commit source | `461e08a` |
| Commit infra | `8c9b824` |
| KBC GBP | 761 £GB |
| KBC EUR | 875 EUR |
| KBC USD | 1 027 $US |
| Token safety | Defense-in-depth sur tous les chemins |
| Isolation tenant | eComLG voit 0 donnee KBC |
| API PROD | `v3.5.106-metrics-settings-currency-exclusion-prod` |
