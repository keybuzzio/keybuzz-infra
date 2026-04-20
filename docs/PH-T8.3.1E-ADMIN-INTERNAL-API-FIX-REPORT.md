# PH-T8.3.1E — Admin Internal API Fix Report

**Date** : 2026-04-20
**Phase** : PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-01
**Environnement** : DEV + PROD
**Type** : Correction infra / routing interne Admin → API

---

## 1. Cause Racine

Le proxy API route (`/api/admin/metrics/overview`) utilise `KEYBUZZ_API_INTERNAL_URL` pour communiquer avec l'API SaaS en interne via le réseau K8s.

**Problème PROD** : L'URL interne pointait vers le port container (3001) au lieu du port service K8s (80). Le port 3001 n'est pas exposé au niveau réseau inter-pod par le service — seul le port 80 est routé.

**Résultat** : `ConnectTimeoutError` après ~10 secondes → "Fetch failed" dans le navigateur.

---

## 2. Architecture Réseau K8s

### Services API

| Env | Service | Port Service | TargetPort (container) | DNS |
|---|---|---|---|---|
| **PROD** | `keybuzz-api` | **80/TCP** | 3001 | `keybuzz-api.keybuzz-api-prod.svc.cluster.local` |
| **DEV** | `keybuzz-api` | **3001/TCP** | 3001 | `keybuzz-api.keybuzz-api-dev.svc.cluster.local` |

### Règle

> TOUJOURS utiliser le **port service** K8s, JAMAIS le port container directement.
> Le port service est le seul accessible via le DNS cluster.

---

## 3. Configuration Avant / Après

### PROD

| État | Valeur | Résultat |
|---|---|---|
| **AVANT** | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:3001` | ConnectTimeoutError (10s) |
| **APRÈS** | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local` | 200 OK (690ms) |

Le port 80 est le défaut HTTP, pas besoin de le spécifier.

### DEV

| État | Valeur | Résultat |
|---|---|---|
| **Actuel** | `http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001` | 200 OK (944ms) |

En DEV, le service expose directement le port 3001, donc `:3001` est le port service correct.

---

## 4. Pourquoi DEV et PROD diffèrent

| Aspect | PROD | DEV |
|---|---|---|
| Service port | 80 (standard HTTP) | 3001 (port applicatif) |
| TargetPort | 3001 | 3001 |
| URL correcte | Sans port (→ 80) | Avec `:3001` |

Les deux utilisent le **port service** (pas le port container). La différence vient de la définition des services K8s :
- PROD suit la convention standard (service port 80 → container 3001)
- DEV expose directement le port applicatif

Les deux configurations sont correctes et fonctionnelles.

---

## 5. Preuves Inter-Pod

### PROD — wget
```
URL: http://keybuzz-api.keybuzz-api-prod.svc.cluster.local/metrics/overview
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
```

### DEV — wget
```
URL: http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/metrics/overview
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
```

---

## 6. Preuves Node.js Fetch

### PROD
```
Status: 200  Time: 690 ms
spend.total_eur = 511.45
cac_detail.paid_eur = null (0 paid customers)
data_quality.test_data_excluded = true
RESULT: OK
```

### DEV
```
Status: 200  Time: 944 ms
spend.total_eur = 511.45
cac_detail.paid_eur = 511.45
data_quality.test_data_excluded = true
RESULT: OK
```

---

## 7. Validation UI

| URL | PROD | DEV |
|---|---|---|
| `/` | 307 | 307 |
| `/login` | 200 | 200 |
| `/metrics` | 307 (RBAC) | 307 (RBAC) |

---

## 8. GitOps

| Commit | Description |
|---|---|
| `da744ab` | `fix(admin-prod): correct KEYBUZZ_API_INTERNAL_URL port 3001 -> 80 (service port)` |

Manifests modifiés :
- `k8s/keybuzz-admin-v2-prod/deployment.yaml` — URL corrigée (suppression `:3001`)

Manifests non modifiés :
- `k8s/keybuzz-admin-v2-dev/deployment.yaml` — URL déjà correcte (`:3001` = port service DEV)

---

## 9. Rollback

### PROD — Rollback URL interne
```bash
cd /opt/keybuzz/keybuzz-infra
sed -i 's|http://keybuzz-api.keybuzz-api-prod.svc.cluster.local|http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:3001|' k8s/keybuzz-admin-v2-prod/deployment.yaml
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "ROLLBACK: revert KEYBUZZ_API_INTERNAL_URL to :3001"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=120s
```

> **Note** : le rollback rétablirait le timeout. Ne l'exécuter qu'en cas de régression causée par le fix.

### PROD — Rollback image Admin
```bash
TAG_PREV="v2.10.5-ph-t8-3-1c-metrics-currency-fix-prod"
sed -i "s|image: ghcr.io/keybuzzio/keybuzz-admin:.*|image: ghcr.io/keybuzzio/keybuzz-admin:${TAG_PREV}|" k8s/keybuzz-admin-v2-prod/deployment.yaml
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "ROLLBACK PROD: revert Admin to ${TAG_PREV}"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod --timeout=120s
```

---

## 10. Verdict

```
ADMIN INTERNAL API — FIXED — DEV OK — PROD OK — NO TIMEOUT — GITOPS SAFE — ROLLBACK READY
```

| Critère | Status |
|---|---|
| Aucun fetch timeout | OK |
| Admin stable | OK (0 restarts DEV + PROD) |
| Config correcte PROD | OK (port 80 service) |
| Config correcte DEV | OK (port 3001 service) |
| GitOps respecté | OK |
| Rollback documenté | OK |
| Node fetch < 1s | OK (690ms PROD, 944ms DEV) |

