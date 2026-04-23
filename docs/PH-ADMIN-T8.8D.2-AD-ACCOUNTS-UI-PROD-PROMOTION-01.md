# PH-ADMIN-T8.8D.2 — Ad Accounts UI PROD Promotion

**Phase** : PH-ADMIN-T8.8D.2-AD-ACCOUNTS-UI-PROD-PROMOTION-01
**Date** : 2026-04-23
**Environnement** : PROD
**Type** : Promotion PROD — UI Ads Accounts + token safety + tenant isolation
**Priorité** : P0

---

## 1. RAPPORTS RELUS

- `PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01.md` — DEV validation
- `PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md` — précédent PROD

---

## 2. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| HEAD Admin | `1986a8e` |
| Branche Admin | `main` |
| Image Admin DEV | `v2.11.5-ad-accounts-ui-hardening-dev` |
| Image Admin PROD (avant) | `v2.11.3-metrics-tenant-scope-fix-prod` |
| API PROD | `v3.5.105-tenant-secret-store-ads-prod` (inchangée) |
| KEYBUZZ_API_INTERNAL_URL PROD | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local` |
| Repo Admin | clean |
| Repo Infra | clean |

---

## 3. VÉRIFICATION SOURCE

| Check | Résultat |
|---|---|
| Page `/marketing/ad-accounts` | OK — `redactTokens` importé |
| TokenBadge fallback | OK — `Masked` (jamais de valeur brute) |
| Token input type=password | OK |
| `last_error` filtré | OK — `redactTokens(acct.last_error?.substring(0, 80))` |
| 5 error handlers filtrés | OK — `redactTokens(b.detail \|\| b.error)` |
| Proxy `buildHeaders` | OK — `x-user-email`, `x-tenant-id`, `x-admin-role` |
| Proxy `redactTokens` server-side | OK — erreurs API et exceptions |
| Proxy routes | OK — GET/POST, PATCH/DELETE/[id], POST/[id]/sync |
| Navigation `Ads Accounts` | OK — icon `Megaphone` |
| Sidebar iconMap | OK — `Megaphone`, `Webhook`, `ScrollText`, `BookOpen` |

---

## 4. BUILD PROD

| Élément | Valeur |
|---|---|
| Commit source | `1986a8e` (même que DEV validé) |
| Image PROD | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.5-ad-accounts-ui-hardening-prod` |
| Digest | `sha256:40bbfd671b6470dcd373fe7f09345851c94eade6dc912bbf11de0d8a1490c3af` |
| Build | `--no-cache`, from git, repo clean |

---

## 5. GITOPS PROD

| Élément | Valeur |
|---|---|
| Manifest | `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Image avant | `v2.11.3-metrics-tenant-scope-fix-prod` |
| Image après | `v2.11.5-ad-accounts-ui-hardening-prod` |
| Commit infra | `d8f5001` — `PH-ADMIN-T8.8D.2: PROD Admin v2.11.5-ad-accounts-ui-hardening-prod` |
| Push | OK → `origin/main` |
| Apply | `kubectl apply --force` — `deployment.apps/keybuzz-admin-v2 configured` |

---

## 6. VALIDATION RUNTIME PROD

| Check | Résultat |
|---|---|
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-admin-v2-797f464ffb-f84fn` — Running 1/1 |
| Restarts | 0 |
| Image runtime | `v2.11.5-ad-accounts-ui-hardening-prod` |
| Admin DEV | `v2.11.5-ad-accounts-ui-hardening-dev` — inchangée |
| API PROD | `v3.5.105-tenant-secret-store-ads-prod` — inchangée |

---

## 7. VALIDATION NAVIGATEUR PROD

### 7.1 Navigation & Login

| Test | Résultat |
|---|---|
| Login `admin.keybuzz.io` | OK |
| Sidebar complète | OK — toutes icônes visibles |
| Marketing > Ads Accounts | OK — visible et accessible |
| Page `/marketing/ad-accounts` | OK |

### 7.2 Liste — Tenant KeyBuzz Consulting

| Test | Résultat |
|---|---|
| Compte KBC visible | OK — "KeyBuzz Consulting (legacy migration)" |
| Account ID | `1485150039295668` |
| Currency / Timezone | GBP · Europe/Paris |
| Token badge | **Encrypted** (badge vert) |
| Aucun token brut | OK |

### 7.3 Sync KBC PROD

| Métrique | Valeur |
|---|---|
| Rows upserted | **8** |
| Total rows | **24** |
| Total spend | **760.76 GBP** |
| Period | 2026-03-24 → 2026-04-23 |
| Last sync updated | 23/04/2026 11:01 |
| Token dans l'UI | **AUCUN** |

### 7.4 Cross-tenant — eComLG

| Test | Résultat |
|---|---|
| Switch vers eComLG | OK |
| Comptes KBC visibles ? | **NON** — "No ad accounts" |
| Empty state propre | OK |
| Aucun résidu KBC | OK |

### 7.5 États UI

| État | Résultat |
|---|---|
| Loading | OK |
| Empty | OK — eComLG |
| Success | OK — sync completed |
| Aucun NaN | OK |
| Aucun undefined | OK |
| Aucun mock | OK |

---

## 8. TOKEN SAFETY PROD

| Surface | Token absent ? | Preuve |
|---|---|---|
| DOM | OUI | Badge "Encrypted", fallback "Masked" |
| Réponses proxy Admin | OUI | `redactTokens()` côté serveur dans `proxy.ts` |
| Erreurs UI | OUI | `redactTokens()` sur tous les error handlers |
| Console navigateur | OUI | Seuls logs pré-existants next-auth |
| Ce rapport | OUI | Aucun token |
| Token input | OUI | `type="password"` |

---

## 9. NON-RÉGRESSION ADMIN PROD

| Page | Résultat |
|---|---|
| `/marketing/ad-accounts` | OK — fonctionnel |
| `/metrics` | OK — page charge |
| `/marketing/destinations` | OK — page charge |
| Tenant selector | OK |
| Sidebar/topbar | OK — icônes complètes |
| Login/session | OK |
| Aucun NaN / undefined / mock | OK |
| API PROD | `v3.5.105-tenant-secret-store-ads-prod` — inchangée |
| Admin DEV | `v2.11.5-ad-accounts-ui-hardening-dev` — inchangée |

---

## 10. ROLLBACK PROD

**Image rollback** : `v2.11.3-metrics-tenant-scope-fix-prod`

**Procédure GitOps** :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`
2. Remettre `image: ghcr.io/keybuzzio/keybuzz-admin:v2.11.3-metrics-tenant-scope-fix-prod`
3. `git add` + `git commit` + `git push`
4. `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod`

**AUCUN** `kubectl set image` — GitOps strict uniquement.

---

## 11. PROCHAINE ÉTAPE

Documentation `/marketing/integration-guide` pour les instructions de configuration ad-accounts.

---

## 12. VERDICT

**ADMIN ADS ACCOUNTS UI LIVE IN PROD — TOKEN SAFE — TENANT SCOPED — KBC META ADS SYNC AVAILABLE — API PROD READY**

### Résumé :
- Image PROD : `v2.11.5-ad-accounts-ui-hardening-prod`
- Digest : `sha256:40bbfd671b6470dcd373fe7f09345851c94eade6dc912bbf11de0d8a1490c3af`
- Sync KBC PROD : 8 rows upserted, 760.76 GBP, période 30 jours
- Token safety : defense-in-depth sur tous les chemins (UI + proxy)
- Isolation tenant : eComLG voit 0 compte KBC
- Non-régression : toutes pages Admin OK
- API PROD inchangée
- DEV inchangée
