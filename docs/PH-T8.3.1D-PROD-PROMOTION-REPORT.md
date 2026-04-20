# PH-T8.3.1D-PROD-PROMOTION-01 — Rapport Final

**Date** : 2026-04-20
**Phase** : PH-T8.3.1D-PROD-PROMOTION-01
**Environnement** : PROD
**Type** : Promotion contrôlée Admin V2 — Metrics Business (trial/paid)

---

## 1. Résumé

Promotion PROD de la version Admin V2 `v2.10.6` incluant :
- **PH-T8.3.1** — Metrics UI (page /metrics)
- **PH-T8.3.1B** — No-data safe (null cac/roas)
- **PH-T8.3.1C** — Currency mapping EUR (total_eur, spend_eur, fx)
- **PH-T8.3.1D** — Trial vs Paid + Data Quality (cac_detail, roas_detail, customers breakdown)

---

## 2. Preflight (ÉTAPE 0)

| Vérification | Résultat |
|---|---|
| Source repo | `main` @ `6485d18` |
| Sync local = remote | OK |
| Git status | Clean |
| Admin PROD avant | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod` |
| Admin DEV | `v2.10.6-ph-t8-3-1d-metrics-trial-paid-dev` |
| API PROD | `v3.5.88-test-control-safe-prod` |

---

## 3. Backend PROD (ÉTAPE 1)

| Champ API | Valeur PROD | Status |
|---|---|---|
| `spend.total_eur` | 511.45 | FOUND |
| `spend.by_channel[0].spend_eur` | 511.45 | FOUND |
| `cac_detail.paid_eur` | null | NULL (0 paid — acceptable) |
| `roas_detail.value` | null | NULL (0 MRR — acceptable) |
| `customers.signups` | 1 | FOUND |
| `customers.trial` | 0 | FOUND |
| `customers.paid` | 0 | FOUND |
| `conversion.trial_to_paid_rate` | null | FOUND (null = pas de conversion) |
| `data_quality.test_data_excluded` | true | FOUND |
| `data_quality.test_accounts_count` | 12 | FOUND |
| `fx` | gbp_eur:1.1488, ecb_cached | FOUND |

---

## 4. Code compilé PROD (ÉTAPE 2 + 5)

| Pattern | Résultat |
|---|---|
| `total_eur` | FOUND |
| `spend_eur` | FOUND |
| `cac_detail` | FOUND |
| `paid_eur` | FOUND |
| `roas_detail` | FOUND |
| `test_data_excluded` | FOUND |
| `trial_to_paid_rate` | FOUND |
| `v2.10.6` | FOUND |
| `CAC (paid)` | FOUND |
| `Customers Breakdown` | FOUND |
| `spend.total` (ancien) | ABSENT (clean) |

---

## 5. Build PROD (ÉTAPE 3)

| Champ | Valeur |
|---|---|
| Tag | `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod` |
| Image | `ghcr.io/keybuzzio/keybuzz-admin:v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod` |
| Digest | `sha256:5f071e7a49e25fc015916b1cca3268207f78efe3b5c421224c744b0764b0b131` |
| Commit source | `6485d185b4c5ead8da95549f6a9361d11a7a7a76` |
| Build method | `build-admin-from-git.sh prod` (clone Git propre) |

---

## 6. GitOps (ÉTAPE 4)

| Champ | Valeur |
|---|---|
| Manifest | `k8s/keybuzz-admin-v2-prod/deployment.yaml` |
| Commit infra | `0f9f2cb` |
| Image BEFORE | `v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod` |
| Image AFTER | `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod` |
| DEV untouched | `v2.10.6-ph-t8-3-1d-metrics-trial-paid-dev` |
| Rollout | `deployment "keybuzz-admin-v2" successfully rolled out` |
| Pod | `keybuzz-admin-v2-5df5495659-wpdwl` |
| Restarts | 0 |
| API URL | `https://api.keybuzz.io` |

---

## 7. Non-Régression PROD (ÉTAPE 5)

| URL | Code | Attendu |
|---|---|---|
| `admin.keybuzz.io/` | 307 | 307 (auth redirect) |
| `admin.keybuzz.io/login` | 200 | 200 |
| `admin.keybuzz.io/metrics` | 307 | 307 (RBAC) |
| `admin.keybuzz.io/billing` | 307 | 307 |
| `admin.keybuzz.io/incidents` | 307 | 307 |
| `admin.keybuzz.io/system-health` | 307 | 307 |
| `/api/admin/metrics/overview` | 307 | 307 (RBAC proxy) |

---

## 8. Validation Métier (ÉTAPE 6)

| Vérification | Résultat |
|---|---|
| CAC paid = null (0 paid) | CORRECT |
| ROAS = null (0 MRR) | CORRECT |
| Trial non inclus dans CAC paid | CORRECT (0 trial) |
| Test accounts exclus | CORRECT (12 comptes) |
| Spend EUR = 511.45 | CORRECT |
| Signups: 1, Trial: 0, Paid: 0 | CORRECT |

**NaN** : ABSENT
**Infinity** : ABSENT
**Crash** : ABSENT

---

## 9. Rollback PROD (ÉTAPE 7)

### Image précédente
```
ghcr.io/keybuzzio/keybuzz-admin:v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod
```

### Procédure
```bash
cd /opt/keybuzz/keybuzz-infra
TAG_PREV="v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod"
sed -i "s|image: ghcr.io/keybuzzio/keybuzz-admin:.*|image: ghcr.io/keybuzzio/keybuzz-admin:${TAG_PREV}|" k8s/keybuzz-admin-v2-prod/deployment.yaml
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "ROLLBACK PROD: revert to ${TAG_PREV}"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=120s
```

### Vérification post-rollback
```bash
kubectl get pods -n keybuzz-admin-v2-prod -o wide
kubectl get pod <POD> -n keybuzz-admin-v2-prod -o jsonpath='{.spec.containers[0].image}'
```

---

## 10. Verdict

```
ADMIN METRICS PROD — BUSINESS READY — CAC PAID — TRIAL/PAID — NO NAN — GITOPS SAFE — ROLLBACK READY
```

| Critère | Status |
|---|---|
| CAC paid affiché | OK (null safe, 0 paid) |
| ROAS business affiché | OK (null safe, 0 MRR) |
| Trial vs Paid visible | OK |
| Data Quality visible | OK (12 test exclus) |
| Aucun NaN | OK |
| UI intacte | OK |
| PROD stable | OK (0 restarts) |
| Rollback documenté | OK |
| DEV intacte | OK |
| GitOps strict | OK |
| Build-from-git | OK |

