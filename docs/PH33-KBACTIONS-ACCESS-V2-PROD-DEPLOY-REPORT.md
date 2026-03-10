# PH33.KBACTIONS.ACCESS.V2 — PROD Deploy Report

## Deploiement
| Composant | Tag | Digest |
|-----------|-----|--------|
| API PROD | `v3.4.1-ph33kb-access-v2-prod-1` | `sha256:bcfae126...` |
| Client PROD | `v3.4.2-ph33kb-access-v2-prod-1` | `sha256:385a07ed...` |

## Rollback
| Composant | Tag rollback |
|-----------|--------------|
| API | `v3.4.1-ph343-daily-budget-fix-prod` |
| Client | `v3.4.2-ph343-budget-ux-prod` |

## Tests E2E PROD — 4/4 PASS

| Test | Resultat | Detail |
|------|----------|--------|
| A. Starter remaining>0 ALLOWED | PASS | `tenant-1771372406836, remaining=994.36, allowed=true, isAiAllowed=true` |
| B. remaining=0 BLOCKED | PASS | `allowed=false, reason=ACTIONS_EXHAUSTED` |
| C. Idempotent grant | PASS | `r1=1000, r2=1000 (PRO, identical after replay)` |
| D. HTTP wallet/status | PASS | `HTTP 200, isAiAllowed=true, remaining=901.48, includedRemaining=901.48` |

## Git
Commit `25d3fda` — `[PROD-APPROVED] PH33.KBACTIONS.ACCESS.V2`

## Changements deployes
- `isAiAllowed = remaining > 0` (independant du plan)
- `includedRemaining` dans la reponse wallet/status
- Debit order: included d'abord, purchased ensuite
- Monthly reset: `remaining = includedMonthly + purchasedRemaining`
- UI: plus de "L'IA n'est pas incluse dans le plan Starter"
- Message unifie: "KBActions epuisees — Achetez un pack"

Date: 2026-02-18
