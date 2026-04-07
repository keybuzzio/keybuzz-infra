# PH143-UX-PROD-PROMOTION-01

**Date** : 7 avril 2026
**Type** : Promotion contrôlée UX-only vers PROD
**Scope** : Client uniquement (2 polish UX)
**Environnement** : PROD

---

## 1. Image PROD déployée

| Service | Image | Tag |
|---------|-------|-----|
| **Client PROD** | `ghcr.io/keybuzzio/keybuzz-client` | `v3.5.215-ph143-ux-polish-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.211-ph143-final-prod` (inchangé) |

### Polish inclus
1. **PH143-UX-ESCALATION-CLEAN-01** — Badge compact "Escaladé" + tooltip info
2. **PH143-UX-MON-TRAVAIL-CLEAN-01** — Filtres compacts sans scroll horizontal, "Tous" toujours visible

### Source
- Branche : `rebuild/ph143-client`
- HEAD : `df3aca9` — "PH143 UX: Tous filter always visible (never in overflow)"
- Build : clone git propre (`git clone --depth 1`), repo clean confirmé

---

## 2. Étapes exécutées

| # | Étape | Résultat |
|---|-------|----------|
| 1 | Confirmation validation visuelle DEV | ✅ Validé par Ludovic |
| 2 | Build-from-git PROD (clone propre) | ✅ `v3.5.215-ph143-ux-polish-prod` |
| 3 | Deploy client PROD + rollout | ✅ Rollout OK, pod Running |
| 4 | `pre-prod-check-v2.sh prod` | ✅ **25/25 ALL GREEN** |
| 5 | Smoke tests PROD | ✅ Tous les endpoints OK |
| 6 | GitOps PROD mis à jour | ✅ Commit `d78ec4e` |
| 7 | Rollback documenté | ✅ Voir section 7 |

---

## 3. Health checks

| Vérification | Résultat |
|--------------|----------|
| `client.keybuzz.io/login` | ✅ HTTP 200 |
| `api.keybuzz.io/health` | ✅ `{"status":"ok"}` |
| Auth check-user | ✅ `exists: true, hasTenants: true` |

---

## 4. Sortie pre-prod-check-v2 prod

```
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

RESULT: 25/25 passed — ALL GREEN
>>> PROD PUSH AUTHORIZED <<<
```

---

## 5. Smoke tests PROD

| Endpoint | Résultat |
|----------|----------|
| Conversations (200 conv) | ✅ 1 escaladée en PROD |
| Dashboard summary | ✅ 6 keys, 11826 orders |
| Orders | ✅ 3 orders returned |
| Billing current | ✅ plan=PRO, status=active |
| Stats conversations | ✅ total=396, open=14, pending=12 |
| Pages client (7 routes) | ✅ Toutes accessibles |

### Pages PROD
| Page | HTTP |
|------|------|
| /login | 200 |
| /inbox | 307 (auth redirect, normal) |
| /dashboard | 307 |
| /settings | 307 |
| /orders | 307 |
| /billing | 307 |
| /channels | 307 |

---

## 6. GitOps mis à jour

| Manifest | Ancien tag | Nouveau tag |
|----------|-----------|-------------|
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.211-ph143-final-prod` | `v3.5.215-ph143-ux-polish-prod` |
| `k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.210-ph143-real-browser-escalation-fix-dev` | `v3.5.214-ph143-tous-visible-dev` |

Commit GitOps : `d78ec4e` — "GitOps: client PROD v3.5.215 (UX polish) + DEV v3.5.214"

---

## 7. Rollback

En cas de problème, exécuter :

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.211-ph143-final-prod \
  -n keybuzz-client-prod

kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod --timeout=120s
```

Image de rollback : `v3.5.211-ph143-final-prod`

---

## 8. Verdict

### ✅ UX POLISHES PROMOTED SAFELY — PROD CLEANER — NO REGRESSION

- ✅ Build depuis clone git propre (repo clean, working tree clean)
- ✅ Build args PROD corrects (api.keybuzz.io, APP_ENV=production)
- ✅ Rollout PROD réussi, pod Running
- ✅ pre-prod-check-v2.sh : **25/25 ALL GREEN**
- ✅ Smoke tests PROD : tous les endpoints fonctionnels
- ✅ Données cohérentes (396 conversations, 1 escaladée, 11826 orders)
- ✅ GitOps mis à jour (PROD + DEV)
- ✅ Rollback documenté et prêt
- ✅ API PROD inchangée (client-only promotion)
