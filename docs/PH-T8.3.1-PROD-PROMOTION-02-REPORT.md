# PH-T8.3.1 — PROD PROMOTION REPORT

> Date : 2026-04-20
> Phase : PH-T8.3.1-PROD-PROMOTION-02
> Type : Promotion PROD contrôlée — /metrics Admin V2
> Verdict : **ADMIN METRICS PROD OPERATIONAL — NO NAN — REAL SPEND — EUR NORMALIZED — GITOPS SAFE — ROLLBACK READY**

---

## 1. PRÉFLIGHT


| Élément            | Valeur                                        | Status        |
| ------------------ | --------------------------------------------- | ------------- |
| Branche            | `main`                                        | OK            |
| HEAD               | `f0c11a2fb8a83aca804cc33cf230b79a596ee36e`    | OK            |
| Repo clean         | `nothing to commit, working tree clean`       | OK            |
| Synced with GitHub | Local HEAD = Remote HEAD                      | OK            |
| Admin PROD avant   | `v2.10.2-ph-admin-87-16-prod`                 | Relevé        |
| Admin DEV          | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-dev` | OK            |
| API PROD           | `v3.5.88-test-control-safe-prod`              | **CONFIRMED** |


---

## 2. COMPATIBILITÉ BACKEND PROD

`GET https://api.keybuzz.io/metrics/overview` — **Tous champs requis présents :**


| Champ                              | Valeur PROD                             | Compatible Admin v2.10.5 |
| ---------------------------------- | --------------------------------------- | ------------------------ |
| `period`                           | `{from, to}`                            | OK                       |
| `new_customers`                    | `1`                                     | OK                       |
| `customers_by_plan`                | `{starter: 1}`                          | OK                       |
| `revenue.mrr`                      | `0`                                     | OK (pas d'abonné actif)  |
| `spend.total_eur`                  | `511.45`                                | OK                       |
| `spend.by_channel[].spend_eur`     | `511.45`                                | OK                       |
| `spend.by_channel[].spend_raw`     | `445.2`                                 | OK                       |
| `spend.by_channel[].currency_raw`  | `GBP`                                   | OK                       |
| `spend.currency`                   | `EUR`                                   | OK                       |
| `spend.source`                     | `ad_spend_table`                        | OK                       |
| `cac`                              | `511.45`                                | OK                       |
| `roas`                             | `null` (MRR=0)                          | OK (safe handling)       |
| `fx`                               | `{gbp_eur: 1.1488, source: ecb_cached}` | OK                       |
| `data_quality`                     | Complet + `fx_available: true`          | OK                       |
| `data_quality.test_data_excluded`  | `true`                                  | OK                       |
| `data_quality.test_accounts_count` | `12`                                    | OK                       |


Champs additionnels du backend (trial/paid) : présents et ignorés par l'Admin (compatibilité forward).

---

## 3. VERSION ADMIN PROMUE

### Contenu inclus


| Phase      | Feature                                               | Status |
| ---------- | ----------------------------------------------------- | ------ |
| PH-T8.3.1  | `/metrics` page, proxy server-side, RBAC              | Inclus |
| PH-T8.3.1B | Gestion null (cac/roas), no-data, empty state         | Inclus |
| PH-T8.3.1C | Currency mapping (total_eur, spend_eur), FX, anti-NaN | Inclus |


### Code compilé PROD vérifié


| Check                               | Résultat                               |
| ----------------------------------- | -------------------------------------- |
| `total_eur` dans client chunk       | **FOUND** (`page-4b67643c46af33c6.js`) |
| `spend_eur` dans client chunk       | **FOUND**                              |
| `v2.10.5` dans server chunks        | **FOUND**                              |
| `/metrics` page route               | **FOUND**                              |
| `/api/admin/metrics/overview` proxy | **FOUND**                              |
| API URL `api.keybuzz.io`            | **FOUND** (PROD)                       |
| Ancien `spend.total` (sans _eur)    | **ABSENT**                             |


---

## 4. BUILD PROD


| Élément       | Valeur                                                                    |
| ------------- | ------------------------------------------------------------------------- |
| Méthode       | `build-admin-from-git.sh prod`                                            |
| Source        | Clone propre GitHub (`f0c11a2`)                                           |
| Repo state    | `Working tree CLEAN`                                                      |
| Tag           | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod`                            |
| Digest        | `sha256:4b7c320929369ecde81a95c2941fb96f7600907fe6b031b15e8e9ba795b19d16` |
| API URL build | `https://api.keybuzz.io`                                                  |
| App Env build | `production`                                                              |


---

## 5. GITOPS PROD


| Élément       | Valeur                                                                         |
| ------------- | ------------------------------------------------------------------------------ |
| Manifest      | `k8s/keybuzz-admin-v2-prod/deployment.yaml`                                    |
| GitOps commit | `700da53` (rebased + pushed)                                                   |
| Image avant   | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.2-ph-admin-87-16-prod`                  |
| Image après   | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod` |
| Déploiement   | `kubectl apply -f` (pas de `set image`)                                        |
| Rollout       | `successfully rolled out`                                                      |


---

## 6. VALIDATION NAVIGATEUR RÉELLE PROD

### Pod PROD


| Élément  | Valeur                                         |
| -------- | ---------------------------------------------- |
| Pod      | `keybuzz-admin-v2-d88fbc5cc-tkrjn`             |
| Status   | `1/1 Running`                                  |
| Restarts | `0`                                            |
| Image    | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod` |


### Non-régression


| Route            | HTTP                 | Temps |
| ---------------- | -------------------- | ----- |
| `/`              | 307 (redirect login) | 1.49s |
| `/login`         | 200                  | 0.21s |
| `/metrics`       | 307 (redirect, RBAC) | OK    |
| `/billing`       | 307                  | OK    |
| `/incidents`     | 307                  | OK    |
| `/system-health` | 307                  | OK    |


### RBAC


| Route                         | Sans auth                        | Attendu |
| ----------------------------- | -------------------------------- | ------- |
| `/metrics`                    | 307 (redirect)                   | OK      |
| `/api/admin/metrics/overview` | 307 (redirect)                   | OK      |
| Rôles autorisés               | `super_admin`, `account_manager` | OK      |


### Données affichées (via API PROD)


| KPI              | Valeur PROD                              | Status                  |
| ---------------- | ---------------------------------------- | ----------------------- |
| Spend total      | 511 € (Meta, converti GBP→EUR)           | OK                      |
| New customers    | 1                                        | OK                      |
| MRR              | 0 €                                      | OK (pas d'abonné actif) |
| CAC              | 511.45 €                                 | OK (non-NaN)            |
| ROAS             | — (null, MRR=0)                          | OK (safe handling)      |
| Spend by Channel | Meta: 511 €, 45k impressions, 892 clicks | OK                      |
| Badge GBP→EUR    | Affiché sur Meta                         | OK                      |
| Bannière FX      | BCE, GBP/EUR 1.1488, taux du 20/04/2026  | OK                      |
| NaN              | **AUCUN**                                | OK                      |


---

## 7. ROLLBACK PROD

### Image avant promotion

```
ghcr.io/keybuzzio/keybuzz-admin:v2.10.2-ph-admin-87-16-prod
```

### Image après promotion

```
ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod
Digest: sha256:4b7c320929369ecde81a95c2941fb96f7600907fe6b031b15e8e9ba795b19d16
```

### Procédure rollback GitOps

```bash
# 1. Modifier le manifest PROD
cd /opt/keybuzz/keybuzz-infra
sed -i 's|ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod|ghcr.io/keybuzzio/keybuzz-admin:v2.10.2-ph-admin-87-16-prod|' \
  k8s/keybuzz-admin-v2-prod/deployment.yaml

# 2. Commit + push
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "rollback(admin-prod): v2.10.5 → v2.10.2"
git push origin main

# 3. Appliquer
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=120s

# 4. Vérifier
kubectl get pods -n keybuzz-admin-v2-prod -o wide
```

---

## 8. DEV INTACTE

```
ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-dev
```

Aucun changement sur l'environnement DEV.

---

## 9. RÉSUMÉ


| Critère                            | Status |
| ---------------------------------- | ------ |
| Aucun NaN                          | **OK** |
| Mapping aligné PH-T8.2C            | **OK** |
| CAC / ROAS non-NaN (ou — si null)  | **OK** |
| Spend Meta réel EUR                | **OK** |
| Multi-devise gérée (GBP→EUR)       | **OK** |
| Bannière FX                        | **OK** |
| RBAC super_admin + account_manager | **OK** |
| Non-régression                     | **OK** |
| DEV intacte                        | **OK** |
| Rollback documenté                 | **OK** |
| GitOps strict                      | **OK** |
| build-from-git                     | **OK** |
| Aucun kubectl set image            | **OK** |
| Aucun hotfix bastion               | **OK** |
| Aucun hardcode                     | **OK** |
| Aucun mock                         | **OK** |
| Aucun recalcul CAC/ROAS frontend   | **OK** |
| image buildée = déployée = visible | **OK** |


---

**VERDICT : ADMIN METRICS PROD OPERATIONAL — NO NAN — REAL SPEND — EUR NORMALIZED — GITOPS SAFE — ROLLBACK READY**