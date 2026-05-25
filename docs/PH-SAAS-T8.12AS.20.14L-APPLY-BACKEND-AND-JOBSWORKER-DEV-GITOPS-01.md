# PH-SAAS-T8.12AS.20.14L-APPLY-BACKEND-AND-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14I / J / K
> Phase : PH-SAAS-T8.12AS.20.14L (GitOps DEV deployment API + jobs-worker)
> Environnement : DEV (keybuzz-backend-dev uniquement ; aucun PROD)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14L

API/backend DEV et jobs-worker DEV tournent desormais tous deux sur v1.0.51-amazon-validation-pipeline-dev (pod imageID digest = GHCR sha256:92f164d2), embarquant le fix PH-20.14I (resolution exacte d adresse par emailAddress). jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV (49.13.35.167:25 secure=false). Rollouts OK, pods Running 1/1, restarts=0. Aucun traitement involontaire : jobs-worker (workerId worker-1) detient 0 AMAZON_POLL ; OutboundEmail et jobs OUTBOUND_EMAIL_SEND inchanges ; 0 email, 0 trigger. Aucun PROD touche.

Prochaine phrase GO : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14M.

## 2. Sources relues

PH-20.14K (push v1.0.51), PH-20.14J (build), PH-20.14I (source patch resolution), PH-20.14F-TER (deploy v1.0.50), PH-20.14G-TER (root cause). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra HEAD avant | 87e0a62 main, clean | OK |
| API DEV image avant | v1.0.50, Running, restarts=0 | OK |
| jobs-worker DEV image avant | v1.0.50, Running, restarts=0 | OK |
| GHCR v1.0.51 | present (digest 92f164d2) | OK |

## 4. Snapshot before

| Signal | Before | Verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND | DONE 10 / FAILED 16 | OK |
| Job OUTBOUND_EMAIL_SEND PENDING/RUNNING | 0 | OK (pas de job ambigu) |
| OutboundEmail | SENT 11 / FAILED 14 | OK |
| API / worker | v1.0.50 Running r=0 | OK |

## 5. Diff GitOps

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | image v1.0.50 -> v1.0.51 (+ rollback comment v1.0.50) | API runtime mis a jour | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | image v1.0.50 -> v1.0.51 (+ rollback comment v1.0.50) | scope conserve | OK |

git diff : 2 files changed, 2 insertions(+), 2 deletions(-). Namespace keybuzz-backend-dev uniquement. Aucun PROD. Dry-run client + server : configured.

## 6. Commit / push

| Commit | Files | Diff | Push | Verdict |
|---|---|---|---|---|
| ac622fc chore(backend): deploy Amazon validation pipeline DEV v1.0.51 | 2 | +2/-2 | 87e0a62..ac622fc origin/main | OK |

## 7. Apply API DEV

| Check API | Attendu | Observe | Verdict |
|---|---|---|---|
| kubectl apply | configured | configured | OK |
| rollout status | rolled out | successfully rolled out | OK |
| pod | Running v1.0.51 | keybuzz-backend-c957dc849-nlkd6 Running restarts=0 | OK |
| imageID digest | GHCR 92f164d2 | sha256:92f164d2...7801 | OK |
| logs boot Prisma | aucune erreur column/Prisma | "Server listening port 4000" (SP-API 429 = rate-limit Amazon non lie) | OK |
| replicas | 1/1 | ready 1/1 updated 1 | OK |

## 8. Apply jobs-worker DEV

| Check jobs-worker | Attendu | Observe | Verdict |
|---|---|---|---|
| kubectl apply | configured | configured | OK |
| rollout status | rolled out | successfully rolled out | OK |
| pod | Running v1.0.51 | jobs-worker-6cc78d4ff-7c2hs Running restarts=0 | OK |
| imageID digest | GHCR 92f164d2 | sha256:92f164d2...7801 | OK |
| JOB_TYPES | OUTBOUND_EMAIL_SEND | value "OUTBOUND_EMAIL_SEND" + log "types=OUTBOUND_EMAIL_SEND" | OK |
| SMTP DEV | 49.13.35.167 / 25 / false | present manifest | OK |
| logs nouveau pod | startup only, pas AMAZON_POLL, pas SMTP send | "Starting worker worker-1 types=OUTBOUND_EMAIL_SEND" seul | OK |
| replicas | 1/1 | ready 1/1 updated 1 | OK |

## 9. No unintended processing

| Signal | Before | After | Delta | Verdict |
|---|---|---|---|---|
| AMAZON_POLL lockedBy EXACT worker-1 (jobs-worker) | 0 | 0 | 0 | OK |
| AMAZON_POLL RUNNING (amazon-orders/items workers worker-4070019 / worker-533412) | n/a | inchange (workers dedies) | n/a | OK |
| OutboundEmail SENT/FAILED | 11 / 14 | 11 / 14 | 0 | OK |
| Job OUTBOUND_EMAIL_SEND DONE/FAILED | 10 / 16 | 10 / 16 | 0 | OK |
| Email SMTP envoye / trigger | 0 | 0 | 0 | OK |

Note : un LIKE large %worker-1% renvoyait 1 (faux positif sur un id numerique d un worker amazon dedie type worker-1xxxxx) ; la verif exacte lockedBy=worker-1 = 0 confirme que le jobs-worker ne claim aucun AMAZON_POLL. Logs nouveau pod : aucun claim, aucun send.

## 10. Runtime consistency

| Component | Manifest | Deploy | Pod imageID | Verdict |
|---|---|---|---|---|
| keybuzz-backend (API) | v1.0.51 | v1.0.51 | sha256:92f164d2 (= GHCR) | OK |
| jobs-worker | v1.0.51 | v1.0.51 | sha256:92f164d2 (= GHCR) | OK |

GHCR tag v1.0.51 : manifest digest 92f164d2, config fca5a28a. Les deux pods referencent le meme digest. Aucune autre ressource modifiee.

## 11. Anti-regression / AI feature parity

| Feature | Contrat | Change cette phase | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange | OK |
| Guard validationStatus=VALIDATED | non bypasse | renforce (adresse exacte) | OK |
| Inbound webhook | resolution exacte par emailAddress active au runtime | corrige | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | non touche | OK |
| outbound deliveries marketplace | pas de retry | non touche | OK |
| Workers Amazon dedies AMAZON_POLL | continuent | inchange (worker-4070019 / 533412) | OK |

## 12. No fake metrics / events

| Objet | Change | Verdict |
|---|---|---|
| validation / webhook / OutboundEmail / KBActions / dashboard | aucun fake, aucun flip DB | OK |

Tous les counts sont des lectures reelles. Aucune metrique forgee.

## 13. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| PROD | OUI | namespace keybuzz-backend-dev uniquement |
| trigger send-validation / retry outbound | OUI | 0 |
| DB UPDATE | OUI | SELECT only |
| build / docker push | OUI | 0 |
| kubectl set/patch/edit/rollout restart | OUI | apply -f manifest only |
| v1.0.48 / 49 / 50 deploye | OUI | non, v1.0.51 uniquement |
| JOB_TYPES retire / SMTP retire | OUI | conserves |
| secret dump | OUI | aucun |

## 14. Rollback

| Element | Rollback | Risque |
|---|---|---|
| API DEV | git revert ac622fc (image -> v1.0.50) + push + kubectl apply -f deployment.yaml | faible |
| jobs-worker DEV | meme revert (image -> v1.0.50) + apply -f deployment-jobs-worker.yaml | faible |

Rollback GitOps uniquement (revert commit), jamais kubectl set image.

## 15. Prochaine phrase GO

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14M

Conditions reunies : API DEV + jobs-worker DEV tous deux sur v1.0.51, jobs-worker healthy scope OUTBOUND_EMAIL_SEND, 0 AMAZON_POLL traite par worker-1, 0 job traite involontairement, SMTP DEV configure, aucun PROD touche. Le re-trigger sur l adresse PENDING cmk5caxx7 doit la faire passer PENDING -> VALIDATED (resolution exacte par emailAddress).

STOP.
