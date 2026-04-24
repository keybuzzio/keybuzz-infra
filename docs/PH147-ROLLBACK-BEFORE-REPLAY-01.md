# PH147-ROLLBACK-BEFORE-REPLAY-01

> Date : 01 mars 2026
> Type : Rollback exact
> Environnement : DEV uniquement

---

## Preflight

| Env | Image avant rollback |
|---|---|
| DEV | `v3.5.84-ph154.1.3-inbox-fix-dev` |
| PROD | `v3.5.63-ph151.2-case-summary-clean-prod` |

## Action

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.63-ph151.2-case-summary-clean-dev \
  -n keybuzz-client-dev
```

Rollout : `successfully rolled out`

## Verification

| Env | Image apres rollback | Status |
|---|---|---|
| DEV | `v3.5.63-ph151.2-case-summary-clean-dev` | 1/1 Running |
| PROD | `v3.5.63-ph151.2-case-summary-clean-prod` | Inchangee |

## Verdict

GO — Base stable restauree. Aucun build, aucun patch.
