# PH-ADMIN-T8.8A.4 — METRICS TENANT SCOPE PROD PROMOTION

**Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-ADMIN-T8.8A.4-METRICS-TENANT-SCOPE-PROD-PROMOTION-01.md`

**Date** : 2026-04-23
**Environnement** : PROD
**Type** : promotion PROD — metrics tenant-scoped UI/proxy fix
**Priorité** : P0

---

## 1. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| Branche Admin | `main` |
| HEAD Admin | `286c80c` |
| Repo Admin clean | OUI |
| Image DEV validée | `v2.11.3-metrics-tenant-scope-fix-dev` |
| Digest DEV | `sha256:0bb88cc0f98ae8ad3214efb0db657373ef44659c986bce45e7eab1e21e6002e2` |
| Image Admin PROD avant | `v2.11.2-meta-capi-ui-hardening-prod` |
| Image API PROD | `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |

---

## 2. VÉRIFICATION SOURCE

| Check | Résultat |
|---|---|
| Proxy accepte `tenant_id` | ✓ (`searchParams.get('tenant_id')`) |
| Proxy accepte `tenantId` (compat) | ✓ (`|| searchParams.get('tenantId')`) |
| Proxy forwarde `tenant_id` vers API SaaS | ✓ (`params.set('tenant_id', tenantId)`) |
| Page envoie `tenant_id` (snake_case) | ✓ (`params.set('tenant_id', tenantId)`) |
| Page recharge au changement de tenant | ✓ (`useEffect` deps `[from, to, tenantId]`) |
| Page conserve `from`/`to` | ✓ |

---

## 3. IMAGE PROD

| Élément | Valeur |
|---|---|
| Tag | `v2.11.3-metrics-tenant-scope-fix-prod` |
| Registry | `ghcr.io/keybuzzio/keybuzz-admin` |
| Digest | `sha256:0c2bc611daa451ab5f7706b7c74d73e4f0b8d4cb148a31813b002b6821a36dad` |
| Build | `--no-cache`, build-from-git |
| Commit source | `286c80c` |

---

## 4. GITOPS PROD

| Élément | Valeur |
|---|---|
| Manifest | `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Commit infra | `b167abe` |
| Image avant | `v2.11.2-meta-capi-ui-hardening-prod` |
| Image après | `v2.11.3-metrics-tenant-scope-fix-prod` |
| ROLLBACK commentaire | `v2.11.2-meta-capi-ui-hardening-prod` |
| GitOps strict | OUI (commit + push + kubectl apply) |

---

## 5. DEPLOY PROD

| Élément | Valeur |
|---|---|
| Rollout | `successfully rolled out` |
| Pod | `keybuzz-admin-v2-5f487b56f9-h4pdk` — 1/1 Running |
| Restarts | 0 |
| Image runtime | `v2.11.3-metrics-tenant-scope-fix-prod` ✓ |
| Digest runtime | `sha256:0c2bc611daa451ab5f7706b7c74d73e4f0b8d4cb148a31813b002b6821a36dad` ✓ |

---

## 6. VALIDATION API PROXY PROD

Tests directs sur l'API PROD (`api.keybuzz.io`) :

| Appel | `spend.scope` | `spend.source` | `spend.total_eur` | OK |
|---|---|---|---|---|
| `tenant_id=ecomlg-001` | `tenant` | `no_data` | 0 | ✓ |
| `tenant_id=keybuzz-consulting-mo9zndlk` | `tenant` | `ad_spend_tenant` | 512.29 | ✓ |
| sans `tenant_id` | `global` | `ad_spend_global` | 512.29 | ✓ |

Note : le tenant ID PROD de KeyBuzz Consulting est `keybuzz-consulting-mo9zndlk` (différent du DEV `mo9y479d`).

---

## 7. VALIDATION NAVIGATEUR PROD

Sur `https://admin.keybuzz.io/metrics` avec session `ludovic@keybuzz.pro` :

| Tenant | Spend attendu | Spend observé | OK |
|---|---|---|---|
| **KeyBuzz Consulting** | ~512 EUR (tenant spend Meta) | **512 EUR** | ✓ |
| **eComLG** | — / 0 (aucun spend tenant) | **— (aucune donnée)** + bannière jaune | ✓ |
| **Retour KeyBuzz Consulting** | ~512 EUR | **512 EUR** (pas de résidu) | ✓ |

Vérifications :
- Bannière "Aucune donnée réelle de dépenses publicitaires disponible" pour eComLG : ✓
- CAC/ROAS : `—` quand pas de spend tenant : ✓
- Aucun NaN : ✓
- Aucun undefined : ✓
- Dates from/to fonctionnelles : ✓
- Changement de tenant recharge automatiquement : ✓

---

## 8. NON-RÉGRESSION ADMIN PROD

| Page | État | OK |
|---|---|---|
| `/metrics` | Tenant-scoped, fonctionnel | ✓ |
| `/marketing/destinations` | Charge normalement | ✓ |
| `/marketing/delivery-logs` | Accessible | ✓ |
| `/marketing/integration-guide` | Accessible | ✓ |
| Sidebar / Topbar | Intactes | ✓ |
| Tenant selector | Fonctionnel, liste complète PROD | ✓ |
| Login / Session | OK (`ludovic@keybuzz.pro`) | ✓ |
| Aucun NaN / undefined / mock | ✓ | ✓ |
| API PROD non modifiée | `v3.5.103-ad-spend-global-import-lock-prod` | ✓ |
| Admin DEV inchangé | `v2.11.3-metrics-tenant-scope-fix-dev` Running | ✓ |

---

## 9. ROLLBACK PROD

| Élément | Valeur |
|---|---|
| Image rollback | `v2.11.2-meta-capi-ui-hardening-prod` |
| Méthode | GitOps strict |

Procédure (ne pas exécuter sauf incident) :
1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`
2. Remplacer l'image par `ghcr.io/keybuzzio/keybuzz-admin:v2.11.2-meta-capi-ui-hardening-prod`
3. Commit + push
4. `kubectl apply -f keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml`

**Aucun `kubectl set image`.**

---

## VERDICT

**ADMIN METRICS TENANT SCOPE LIVE IN PROD — KEYBUZZ CONSULTING SPEND ISOLATED — NO GLOBAL SPEND DISPLAYED FOR OTHER TENANTS**
