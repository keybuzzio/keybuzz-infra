# PH143-P-PROD-PROMOTION-02

> Date : 2026-04-06
> Phase : PH143-P — Promotion contrôlée finale vers PROD
> Verdict : **GO — PROD PROMOTED SAFELY — DEV AND PROD ALIGNED — REAL PRODUCT LIVE**

---

## 1. Images PROD déployées

| Service | Image PROD | Source branch | Commit |
|---------|-----------|---------------|--------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.211-ph143-final-prod` | `rebuild/ph143-api` | `81e3754` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ph143-final-prod` | `rebuild/ph143-client` | `61a0257` |

Les builds ont été effectués depuis un **clone Git propre** (build-from-git), pas depuis le repo local.

---

## 2. Étapes exécutées

| # | Étape | Résultat |
|---|-------|----------|
| 1 | Build API PROD (clone propre) | `v3.5.211-ph143-final-prod` built + pushed |
| 2 | Deploy API PROD | Rollout OK, health `{"status":"ok"}` |
| 3 | Build Client PROD (clone propre, build-args PROD) | `v3.5.211-ph143-final-prod` built + pushed |
| 4 | Deploy Client PROD | Rollout OK, HTTP 200 |
| 5 | pre-prod-check-v2.sh prod | **25/25 ALL GREEN** |
| 6 | Smoke tests PROD | **ALL PASS** (7/7) |
| 7 | GitOps PROD | Manifests mis à jour, commit `8e5c5be` |

---

## 3. Health API / Client

```
API:    {"status":"ok","timestamp":"2026-04-06T22:00:23.585Z","service":"keybuzz-api","version":"1.0.0"}
Client: HTTP 200 (https://client.keybuzz.io/login)
```

---

## 4. Sortie pre-prod-check-v2 prod

```
============================================
  PRE-PROD SAFETY CHECK V2 — prod
  PH142-M
============================================

--- A. Git Source of Truth ---
  [OK] Git clean: keybuzz-client
  [OK] Git clean: keybuzz-api

--- B. External Health ---
  [OK] API health (https://api.keybuzz.io)
  [OK] Client health (https://client.keybuzz.io)

--- C. API Internal (kubectl exec) ---
  [OK] Inbox API endpoint
  [OK] Dashboard API endpoint
  [OK] AI Settings endpoint
  [OK] AI Journal endpoint
  [OK] Autopilot draft endpoint
  [OK] Signature config in DB
  [OK] Orders count > 0
  [OK] Channels count > 0
  [OK] Billing current endpoint
  [OK] Agent KeyBuzz status API
  [OK] DB has_agent_keybuzz_addon col
  [OK] Addon API structure valid
  [OK] billing/current hasAddon field
  [OK] Agents API endpoint
  [OK] Signature API endpoint

--- D. Client Compiled Routes ---
  [OK] Route: billing_plan_page compiled
  [OK] Route: billing_ai_page compiled
  [OK] Route: settings_page compiled
  [OK] Route: dashboard_page compiled
  [OK] Route: inbox_page compiled
  [OK] Route: orders_page compiled

============================================
  RESULT: 25/25 passed — ALL GREEN
  >>> PROD PUSH AUTHORIZED <<<
============================================
```

---

## 5. Smoke tests PROD

| Test | Résultat | Détails |
|------|----------|---------|
| Escalade (promesse) | **PASS** | `escalatedByReply: true`, DB `escalated`, raison "je vais vérifier, je reviens vers vous" |
| Contrôle négatif (factuel) | **PASS** | DB `none`, 0 promesses détectées |
| Dashboard | **PASS** | 393 convs, 9 open, 14 pending |
| Settings/Signature | **PASS** | API OK |
| Orders | **PASS** | 11 826 commandes |
| Billing | **PASS** | Plan PRO, status active |
| AI Wallet | **PASS** | 899.03 KBA restants |

### Logs PH143-E.9 en PROD
```
PH143-E.9: Reply content received for false promise scan
  contentLength: 61
  contentPreview: "Je vais vérifier votre commande et je reviens vers vous."
  detectedCount: 3
  detectedPromises: ["je vais vérifier", "je reviens vers vous", "je vais vérifier (alt)"]

PH143-E.9: Reply content received for false promise scan
  contentLength: 45
  contentPreview: "Votre colis sera livré demain. Bonne journée."
  detectedCount: 0
  detectedPromises: []
```

---

## 6. GitOps mis à jour

Commit infra : `8e5c5be` sur `origin/main`

Fichiers modifiés :
- `k8s/keybuzz-api-prod/deployment.yaml` → `v3.5.211-ph143-final-prod`
- `k8s/keybuzz-client-prod/deployment.yaml` → `v3.5.211-ph143-final-prod`
- `k8s/keybuzz-api-dev/deployment.yaml` → `v3.5.209-ph143-final-escalation-fix-dev`
- `k8s/keybuzz-client-dev/deployment.yaml` → `v3.5.210-ph143-real-browser-escalation-fix-dev`

---

## 7. Rollback documenté

### Rollback API PROD
```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.189-draft-lifecycle-kbactions-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

### Rollback Client PROD
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.190-signature-tab-restore-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

### Images précédentes (avant promotion)
| Service | Image précédente |
|---------|-----------------|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.189-draft-lifecycle-kbactions-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.190-signature-tab-restore-prod` |
| Outbound Worker PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod` (inchangé) |

---

## 8. Verdict final

### **GO — PROD PROMOTED SAFELY — DEV AND PROD ALIGNED — REAL PRODUCT LIVE**

Résumé de la ligne PH143 promue en PROD :

| Feature | Phase | Status |
|---------|-------|--------|
| Escalade auto (faux promesses) | E.8 + E.9 | 22 patterns, accent-safe, diagnostic logging |
| UI escalade après reply | E.10 | forceRefresh bypass cache, badge visible immédiatement |
| Signature save/load | PH143-F | Onglet restauré, fallback synchronisé |
| Dashboard supervision | PH143-G | SLA panel, KPI agents |
| Tracking/Orders | PH143-H | Import, sync, enrichissement |
| Autopilot escalation UX | E.2 → E.7 | Classification draft, visibilité, handoff |

### Alignement DEV / PROD

| Service | DEV | PROD |
|---------|-----|------|
| API | v3.5.209 | v3.5.211 (même codebase, suffixe env différent) |
| Client | v3.5.210 | v3.5.211 (même codebase, build-args PROD) |

Les deux environnements sont fonctionnellement identiques.
