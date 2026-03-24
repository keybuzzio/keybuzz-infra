# ROLLBACK-DEV-REPRO-SLOWDOWN-01 — Rapport

> Date : 2026-03-24
> Phase : Rollback DEV client — retour baseline saine
> Environnement : DEV uniquement
> Verdict : **DEV ROLLBACK COMPLETED — BASELINE RESTORED**

---

## Cause du rollback

Le build reproductible `v3.5.82-source-of-truth-fix-dev` fonctionne techniquement mais le product owner constate :
- Temps de chargement DEV trop longs
- Certaines pages ne chargent pas toujours correctement

Le DEV doit etre fluide pour etre utilisable.

---

## Images

| Element | Avant rollback | Apres rollback |
|---|---|---|
| Client DEV | `v3.5.82-source-of-truth-fix-dev` | `v3.5.77-ph119-role-access-guard-dev` |
| API DEV | `v3.5.49-amz-orders-list-sync-fix-dev` | Inchange |
| Backend DEV | `v1.0.40-amz-tracking-visibility-backfill-dev` | Inchange |
| Client PROD | `v3.5.77-ph119-role-access-guard-prod` | **NON TOUCHE** |

---

## Deploiement

| Etape | Resultat |
|---|---|
| Manifest modifie | `k8s/keybuzz-client-dev/deployment.yaml` |
| Commit Git | `6a16620` |
| Push GitHub | OK |
| `kubectl apply` | OK |
| Rollout | `successfully rolled out` |
| Zero-downtime | OUI — nouveau pod Ready avant kill ancien |

---

## Validation post-rollback

| Page | HTTP |
|---|---|
| /login | 200 |
| /dashboard | 200 |
| /inbox | 200 |
| /orders | 200 |
| /ai-dashboard | 200 |
| /billing | 200 |
| /settings | 200 |
| /register | 200 |

| API | Resultat |
|---|---|
| Health | `{"status":"ok"}` |
| Amazon | `connected=True, status=CONNECTED` |
| Orders | `count=3` |

---

## Confirmations

- PROD **non touchee** : `v3.5.77-ph119-role-access-guard-prod`
- API DEV **non touchee** : `v3.5.49-amz-orders-list-sync-fix-dev`
- Backend DEV **non touche** : `v1.0.40-amz-tracking-visibility-backfill-dev`
- Infra zero-downtime **non touchee** : probes et strategie RollingUpdate preservees

---

## Verdict

### DEV ROLLBACK COMPLETED — BASELINE RESTORED
