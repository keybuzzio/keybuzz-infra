# PH-AUDIT-FIX — Client DEV Alignment Report

> Date : 2026-03-20
> Environnement : DEV uniquement
> Statut : **TERMINE — SUCCES**

## Probleme

L'audit PH-AUDIT-CLIENT-API-PARITY-01 a revele que le client DEV (`v3.5.59-channels-stripe-sync-dev`) ne contenait pas les features PH117 (AI Dashboard), alors que le client PROD les contenait. La cause racine etait un build DEV effectue **avant** la synchronisation des fichiers PH117 sur le bastion.

## Correction appliquee

### Etape 1 — Verification source

Fichiers PH117 confirmes presents sur le bastion :

| Fichier | Status |
|---|---|
| `app/ai-dashboard/page.tsx` | Present (17353 bytes) |
| `app/api/ai/dashboard/route.ts` | Present (1667 bytes) |
| `ClientLayout.tsx` (ai-dashboard) | Present (ligne 56) |
| `I18nProvider.tsx` (ai_dashboard) | Present (ligne 46) |

### Etape 2 — Build

```
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev .
```

Duree : ~2m36s, image SHA256: `c8490e88b9e30370d001b5ef7682f1ef10c3fc498d5664bb6a2bf6ecb95ab5df`

### Etape 3 — Verification bundle

| Check | Resultat |
|---|---|
| `/ai-dashboard` (html, meta, rsc) | PRESENT |
| `/api/ai/dashboard/route.js` (BFF) | PRESENT |
| Label "IA Performance" dans chunks | PRESENT |
| Zero `api.keybuzz.io` (PROD) | CLEAN |
| `api-dev.keybuzz.io` present | CONFIRME |

### Etape 4 — Deploiement

ArgoCD gere le namespace `keybuzz-client-dev`. Le deploiement a necessite :
1. Push de l'image vers GHCR
2. Mise a jour du manifest dans `keybuzz-infra` (GitHub)
3. `kubectl apply` du manifest mis a jour
4. ArgoCD sync automatique

Nouveau pod : `keybuzz-client-59f9f8bd94-qfxkl` sur `k8s-worker-05`

### Etape 5 — Tests runtime

| Test | Resultat |
|---|---|
| Pod Running, 0 restarts | PASS |
| `/ai-dashboard` compile | PASS |
| BFF `/api/ai/dashboard` compile | PASS |
| Label "IA Performance" | PASS |
| Zero URL PROD | PASS |
| `api-dev.keybuzz.io` present | PASS |
| `/channels` | OK |
| `/billing` | OK |
| `/inbox` | OK |
| `/orders` | OK |
| `/dashboard` | OK |
| `/settings` | OK |

**6/6 PASS, 6/6 pages core OK**

## Versions

| Env | Image | Digest |
|---|---|---|
| DEV | `v3.5.60-ph117-aligned-dev` | `c8490e88...` |
| PROD | `v3.5.59-channels-stripe-sync-prod` | inchange |

## Rollback

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-dev -n keybuzz-client-dev
```

## Lecon apprise

Le desalignement DEV/PROD etait cause par un build fait AVANT la synchronisation des fichiers source PH117. La solution PH-TD-06 (Build Pipeline Hardening) est necessaire pour prevenir ce type d'incident.

## GitOps

- Bastion `keybuzz-infra` : commit `b307d03` pousse sur `main`
- Local `deployment.yaml` : mis a jour
- ArgoCD : synced
