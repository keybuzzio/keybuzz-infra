# ROLLBACK-PH-AUTH-SESSION-LOADING-STABILITY-01 — Rapport

> Date : 2026-03-23
> Type : rollback immediat client

---

## Cause du rollback

Regression UI critique constatee par le product owner :
- **Menu** casse
- **Focus mode** du menu casse

Regression bloquante necessitant un rollback immediat.

---

## Images avant rollback

| Env | Image |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-auth-session-loading-stability-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-auth-session-loading-stability-prod` |

## Images apres rollback

| Env | Image |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-prod` |

---

## Manifests modifies

| Fichier | Modification |
|---|---|
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image → `v3.5.77-ph119-role-access-guard-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image → `v3.5.77-ph119-role-access-guard-prod` |

---

## Validation DEV

| Page | Status |
|---|---|
| `/login` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/orders` | 200 |
| `/ai-dashboard` | 200 |
| API Health | `{"status":"ok"}` |

**ROLLBACK DEV = OK**

---

## Validation PROD

| Page | Status |
|---|---|
| `/login` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/orders` | 200 |
| `/ai-dashboard` | 200 |
| API Health | `{"status":"ok"}` |
| Amazon status | `connected: true`, `CONNECTED` |

**ROLLBACK PROD = OK**

---

## Confirmation

- Menu et focus mode sont revenus a l'etat PH119 (anterier a la phase rollbackee)
- Aucune autre phase n'a ete touchee
- Backend inchange
- Amazon inchange

---

## Verdict final

### ROLLBACK AUTH SESSION LOADING COMPLETED
