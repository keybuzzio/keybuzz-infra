# PH143-R3 — Clean Release PROD Promotion

> Date : 2026-04-07
> Type : Promotion PROD controlee
> Branche source : `release/client-v3.5.220`
> Prerequis : PH143-R2 DEV valide + validation visuelle Ludovic

---

## 1. Branche source

| Element | Valeur |
|---|---|
| Branche | `release/client-v3.5.220` |
| Repo | `keybuzz-client` (bastion) |
| Base | `e87da0e` (PH143-FR.3) |
| Commits ajoutes | 3 (2 cherry-picks playbooks + 1 dockerignore) |
| Studio files | **0** |

## 2. SHA exact builde

| Commit | SHA | Description |
|---|---|---|
| HEAD branche release | `4e499b6` | PH143-R2: add Studio exclusions to .dockerignore |
| Cherry-pick 1 | `ac8e63f` | PH-PLAYBOOKS-BACKEND-MIGRATION-02 |
| Cherry-pick 2 | `56095eb` | PH-PLAYBOOKS-ENGINE-ALIGNMENT-02B |
| Base | `e87da0e` | PH143-FR.3 |

## 3. Image PROD construite

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.220-ph143-clean-release-prod
```

| Element | Valeur |
|---|---|
| Digest | `sha256:61c704404549970bcc5c635d737c7688f7ecf2d38a450fcea283fd5a7a939f7d` |
| Taille | 279 MB |
| Build | `docker build --no-cache` |
| Build args | `NEXT_PUBLIC_API_URL=https://api.keybuzz.io` |
| | `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io` |
| | `NEXT_PUBLIC_APP_ENV=production` |

## 4. Preuve Git clean

| Verification | Resultat |
|---|---|
| Branche | `release/client-v3.5.220` |
| Working tree | 0 fichiers dirty |
| Studio files dans tree | **0** |
| Build depuis `main` | **Non** |
| Build depuis `rebuild/ph143-client` | **Non** |

## 5. Manifest PROD mis a jour

| Element | Avant | Apres |
|---|---|---|
| Image | `v3.5.216-ph143-francisation-prod` | `v3.5.220-ph143-clean-release-prod` |
| Fichier | `k8s/keybuzz-client-prod/deployment.yaml` | |
| GitOps SHA | `c15ca17` | `102f8f6` |

## 6. Rollout PROD

| Element | Valeur |
|---|---|
| Methode | `rollback-service.sh client prod v3.5.220-ph143-clean-release-prod` |
| Rollout | `deployment "keybuzz-client" successfully rolled out` |
| Pod | `keybuzz-client-66668c779d-xzl9j` — 1/1 Running |
| Image cluster | `v3.5.220-ph143-clean-release-prod` (confirme) |

## 7. Pre-prod check v2 PROD

```
============================================
  PRE-PROD SAFETY CHECK V2 — prod
============================================

  25/25 passed — ALL GREEN
  >>> PROD PUSH AUTHORIZED <<<

============================================
```

Detail des 25 checks :
- Git clean (client + API) : OK
- External health (API + Client) : OK
- API internal (Inbox, Dashboard, AI Settings, AI Journal, Autopilot, Signature, Orders, Channels, Billing, Agent KeyBuzz, DB addon, Addon API, billing hasAddon, Agents, Signature API) : 15/15 OK
- Client compiled routes (billing_plan, billing_ai, settings, dashboard, inbox, orders) : 6/6 OK

## 8. Smoke tests PROD

### Pages HTTP

| Page | HTTP |
|---|---|
| `/` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/settings` | 200 |
| `/playbooks` | 200 |
| `/billing` | 200 |
| `/orders` | 200 |
| `/ai-journal` | 200 |
| `/channels` | 200 |
| `/suppliers` | 200 |
| `/knowledge` | 200 |

### API PROD

| Endpoint | Resultat |
|---|---|
| Health | `{"status":"ok"}` |
| Playbooks | **15 playbooks** |
| Dashboard | 402 conversations |
| Billing | plan PRO, status active |
| Conversations | reponse OK |

## 9. Preuve absence Studio

| Verification | Resultat |
|---|---|
| `keybuzz-studio/` dans container PROD | **Absent** |
| `keybuzz-studio-api/` dans container PROD | **Absent** |
| `.dockerignore` anti-Studio dans branche | **Present** |
| `usePlaybooks` dans chunks JS | **Present** (4 fichiers) |
| Ancien service `getPlaybooks` | **Absent** |
| URL `api-dev.keybuzz.io` dans chunks PROD | **Absent** (pas de split-brain) |
| URL `api.keybuzz.io` dans chunks PROD | **Present** (correct) |

## 10. Rollback documente

### Rollback PROD immediat

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client prod v3.5.216-ph143-francisation-prod
```

### Rollback DEV immediat

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh client dev v3.5.218-ph143-fr-real-fix-dev
```

## 11. Etat final aligne

| Env | Image | Branche source | Studio |
|---|---|---|---|
| **DEV** | `v3.5.220-ph143-clean-release-dev` | `release/client-v3.5.220` | **0** |
| **PROD** | `v3.5.220-ph143-clean-release-prod` | `release/client-v3.5.220` | **0** |

Les deux environnements sont sur le meme codebase (meme branche, meme SHA `4e499b6`), seuls les build args API URL different.

---

## Verdict

```
CLEAN RELEASE PROMOTED TO PROD
```

| Critere | Statut |
|---|---|
| Build depuis branche propre | **OK** |
| 0 Studio | **OK** |
| Pre-prod check 25/25 | **OK** |
| 11 pages HTTP 200 | **OK** |
| 15 playbooks API | **OK** |
| Pas de split-brain URL | **OK** |
| GitOps coherent | **OK** |
| Rollback documente | **OK** |
| DEV/PROD alignes | **OK** |
