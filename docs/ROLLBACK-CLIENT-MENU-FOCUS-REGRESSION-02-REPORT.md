# ROLLBACK-CLIENT-MENU-FOCUS-REGRESSION-02 — Rapport

**Date** : 23 mars 2026
**Type** : Rollback immediat client
**Cause** : Regression menu fixe / focus mode / lenteur chargement

---

## Cause du rollback

Le product owner constate apres PH120-01 :
- Menu redevenu fixe
- Focus mode du menu active de maniere incoherente
- Temps de chargement redevenu long

## Images avant rollback

| Env | Image avant |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-ph120-tenant-context-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.79-ph120-tenant-context-prod` |

## Images apres rollback

| Env | Image apres |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-prod` |

## Manifests modifies

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` — image tag uniquement
- `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` — image tag uniquement

## Confirmations

- **API inchangee** : `v3.5.48-amz-prod-truth-fix-dev/prod` — non touchee
- **Infra hard-refresh inchangee** : readinessProbe, livenessProbe, zero-downtime strategy — non touchees
- **Amazon backend inchange** : tracking, enrichissement, statut connecteur — non touches
- **Backend Python inchange** : workers, sync — non touches

## Validation DEV

| Route | HTTP |
|---|---|
| /login | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /ai-dashboard | 200 |
| /billing | 200 |

**ROLLBACK CLIENT DEV = OK**

## Validation PROD

| Route | HTTP |
|---|---|
| /login | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /ai-dashboard | 200 |
| /billing | 200 |

**ROLLBACK CLIENT PROD = OK**

---

## Verdict

**CLIENT MENU FOCUS ROLLBACK COMPLETED**
