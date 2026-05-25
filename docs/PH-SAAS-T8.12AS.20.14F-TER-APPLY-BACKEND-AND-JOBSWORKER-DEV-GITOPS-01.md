# PH-SAAS-T8.12AS.20.14F-TER-APPLY-BACKEND-AND-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C-TER / D-TER / E-TER / F-BIS
> Phase : PH-SAAS-T8.12AS.20.14F-TER (GitOps DEV deployment API + jobs-worker)
> Environnement : DEV (keybuzz-backend-dev uniquement ; aucun PROD)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14F-TER

API/backend DEV et jobs-worker DEV tournent desormais tous deux sur v1.0.50-amazon-validation-pipeline-dev (pod imageID digest = GHCR sha256:6e00ad07). jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV (49.13.35.167:25 secure=false). Rollouts OK, pods Running 1/1, restarts=0. Aucun traitement involontaire : AMAZON_POLL locke par worker-1 = 0, OutboundEmail et jobs OUTBOUND_EMAIL_SEND inchanges, aucun email, aucun trigger. Aucun PROD touche.

Prochaine phrase GO : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14G-TER.

## 2. Sources relues

PH-20.14E-TER (push v1.0.50), PH-20.14D-TER (build), PH-20.14C-TER (schema map), PH-20.14F-BIS (deploy jobs-worker initial), PH-20.14G (retrigger PARTIAL). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 / 46.62.171.61 | OK | OK |
| infra branche/HEAD | main / 571525c (avant) | OK |
| API DEV image (avant) | v1.0.47-cross-env-guard-fix-dev, ready 1/1, restarts=0 | OK |
| jobs-worker DEV image (avant) | v1.0.49-amazon-validation-pipeline-dev, Running, restarts=0 | OK |
| GHCR v1.0.50 | present (digest 6e00ad07) | OK |
| Anti-regression cross-env guard | commit c62f376 (cross-env guard KEYBUZZ_DEV_MODE) dans historique de 2a14258 -> v1.0.50 superset de v1.0.47 | OK |

## 4. Snapshot before

| Signal | Before | Verdict |
|---|---|---|
| API pod | keybuzz-backend-...zbqhz Running restarts=0 (v1.0.47) | OK |
| jobs-worker pod | jobs-worker-...r8pk4 Running restarts=0 (v1.0.49) scope types=OUTBOUND_EMAIL_SEND | OK |
| Job AMAZON_POLL | DONE 150999 / PENDING 14 / RUNNING 3 (workers amazon dedies) | OK |
| Job OUTBOUND_EMAIL_SEND | DONE 9 / FAILED 16 (terminaux) | OK |
| Job OUTBOUND_EMAIL_SEND PENDING/RUNNING | 0 | OK (pas de job ambigu) |
| OutboundEmail | SENT 10 / FAILED 14 | OK |

## 5. Diff GitOps

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | image v1.0.47-cross-env-guard-fix-dev -> v1.0.50-amazon-validation-pipeline-dev (+ rollback comment) | API runtime mis a jour, superset verifie | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | image v1.0.49-amazon-validation-pipeline-dev -> v1.0.50-amazon-validation-pipeline-dev (+ rollback comment) | mapping Prisma present, scope conserve | OK |

git diff --stat : 2 files changed, 2 insertions(+), 2 deletions(-). Namespace keybuzz-backend-dev uniquement. Aucun PROD.

## 6. Commit / push

| Commit | Files | Diff | Push | Verdict |
|---|---|---|---|---|
| 1460d9c chore(backend): deploy Amazon validation pipeline DEV v1.0.50 | 2 | +2/-2 | 571525c..1460d9c origin/main | OK |

## 7. Apply API DEV

| Check API | Attendu | Observe | Verdict |
|---|---|---|---|
| kubectl apply | configured | configured | OK |
| rollout status | rolled out | successfully rolled out | OK |
| pod | Running v1.0.50 | keybuzz-backend-7bbbb67d54-2hbmn Running restarts=0 | OK |
| imageID digest | GHCR 6e00ad07 | sha256:6e00ad07...39da | OK |
| logs boot Prisma | aucune erreur column/Prisma | "Server listening port 4000", aucune erreur | OK |
| replicas | 1/1 | ready 1/1 updated 1 | OK |

## 8. Apply jobs-worker DEV

| Check jobs-worker | Attendu | Observe | Verdict |
|---|---|---|---|
| kubectl apply | configured | configured | OK |
| rollout status | rolled out | successfully rolled out | OK |
| pod | Running v1.0.50 | jobs-worker-d87cb7cb4-6jmqr Running restarts=0 | OK |
| imageID digest | GHCR 6e00ad07 | sha256:6e00ad07...39da | OK |
| JOB_TYPES | OUTBOUND_EMAIL_SEND | value "OUTBOUND_EMAIL_SEND" (manifest) ; log "types=OUTBOUND_EMAIL_SEND" | OK |
| SMTP DEV | 49.13.35.167 / 25 / false | present manifest (sans dump secret) | OK |
| logs scope | types=OUTBOUND_EMAIL_SEND, pas AMAZON_POLL | confirme | OK |
| replicas | 1/1 | ready 1/1 updated 1 | OK |

## 9. No unintended processing

| Signal | Before | After | Delta | Verdict |
|---|---|---|---|---|
| AMAZON_POLL locke par worker-1 | n/a | 0 | 0 | OK |
| OutboundEmail SENT | 10 | 10 | 0 | OK |
| OutboundEmail FAILED | 14 | 14 | 0 | OK |
| Job OUTBOUND_EMAIL_SEND DONE | 9 | 9 | 0 | OK |
| Job OUTBOUND_EMAIL_SEND FAILED | 16 | 16 | 0 | OK |
| Email SMTP envoye | 0 | 0 | 0 | OK |
| Trigger validation | 0 | 0 | 0 | OK |

Logs jobs-worker : aucune ligne AMAZON_POLL, aucun sendOutboundEmailById, aucun SMTP send. Worker idle (aucun job PENDING a claim).

## 10. Runtime consistency

| Component | Manifest | Deploy | Pod imageID | Verdict |
|---|---|---|---|---|
| keybuzz-backend (API) | v1.0.50 | v1.0.50 | sha256:6e00ad07 (= GHCR) | OK |
| jobs-worker | v1.0.50 | v1.0.50 | sha256:6e00ad07 (= GHCR) | OK |

GHCR tag v1.0.50 : manifest digest 6e00ad07, config 7e8a056c. Les deux pods referencent le meme digest. Aucune autre ressource modifiee.

## 11. Anti-regression / AI feature parity

| Feature | Contrat | Change cette phase | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange (code stable + cross-env guard inclus) | OK |
| Guard validationStatus=VALIDATED | requis | non bypasse | OK |
| Inbound webhook | preserve | non touche | OK |
| PH-20.11C guardrails | preserve | non touche | OK |
| PH-20.12B no-reply KBActions | preserve | non touche | OK |
| PH-20.13B Client | suspendu | non touche | OK |
| outbound deliveries marketplace | pas de retry | non touche | OK |
| Workers Amazon dedies AMAZON_POLL | continuent | jobs-worker scope, 0 lock AMAZON_POLL | OK |
| cross-env guard (v1.0.47) | conserve | commit c62f376 dans v1.0.50 | OK |

## 12. No fake metrics / events

| Objet | Change | Verdict |
|---|---|---|
| validation / webhook / OutboundEmail / delivery / KBActions / dashboard | aucun fake, aucun create runtime | OK |

Aucun flip DB, aucune metrique forgee. Tous les counts sont des lectures reelles.

## 13. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| PROD | OUI | namespace keybuzz-backend-dev uniquement |
| trigger send-validation / retry outbound | OUI | 0 |
| DB UPDATE | OUI | SELECT only |
| build / docker push | OUI | 0 |
| kubectl set/patch/edit/rollout restart | OUI | apply -f manifest only |
| v1.0.48 / v1.0.49 deploye | OUI | non, v1.0.50 uniquement |
| JOB_TYPES retire / SMTP retire | OUI | conserves |
| secret dump | OUI | aucun |

## 14. Rollback

| Element | Rollback | Risque |
|---|---|---|
| API DEV | git revert 1460d9c (image -> v1.0.47-cross-env-guard-fix-dev) + push + kubectl apply -f deployment.yaml | faible (image precedente connue) |
| jobs-worker DEV | meme revert (image -> v1.0.49-amazon-validation-pipeline-dev) + apply -f deployment-jobs-worker.yaml | faible |

Rollback GitOps uniquement (revert commit), jamais kubectl set image.

## 15. Prochaine phrase GO

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14G-TER

Conditions reunies : API DEV + jobs-worker DEV tous deux sur v1.0.50, jobs-worker healthy scope OUTBOUND_EMAIL_SEND, 0 AMAZON_POLL traite, 0 job traite involontairement, SMTP DEV configure, aucun PROD touche.

STOP.
