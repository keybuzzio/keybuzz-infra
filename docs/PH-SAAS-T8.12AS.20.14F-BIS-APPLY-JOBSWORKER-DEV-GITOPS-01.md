# PH-SAAS-T8.12AS.20.14F-BIS-APPLY-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C-BIS / PH-20.14D-BIS / PH-20.14E-BIS / PH-20.14F-SMTP
> Phase : PH-SAAS-T8.12AS.20.14F-BIS-APPLY-JOBSWORKER-DEV-GITOPS
> Environnement : DEV (GitOps strict ; no PROD, no trigger)

## 1. Verdict

GO APPLY JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14F-BIS

Le jobsWorker DEV scope (image v1.0.49, JOB_TYPES=OUTBOUND_EMAIL_SEND) est deploye en GitOps strict et tourne (Running, READY=1, 0 restart). Logs confirment le scope (types=OUTBOUND_EMAIL_SEND). Aucun AMAZON_POLL claim par ce worker (0 lock worker-1). Aucun email envoye (queue OUTBOUND vide). Aucune validation declenchee. mail-core stable (KEY-323). v1.0.48 generique non utilisee.

## 2. Sources relues

PH-20.14C-BIS (scope JOB_TYPES), PH-20.14D-BIS (build v1.0.49), PH-20.14E-BIS (push v1.0.49 digest sha256:16a864a1c31b), PH-20.14F-SMTP (SMTP DEV 49.13.35.167:25).

## 3. Preflight

| Element | Valeur | Verdict |
|---|---|---|
| Bastion install-v3 | 46.62.171.61 | OK |
| infra | main / HEAD e7b97a5 / clean | OK |
| image GHCR v1.0.49 | accessible | OK |
| jobs-worker DEV avant | absent | OK |

## 4. Image / SMTP confirmation

| Check | Attendu | Observe | Verdict |
|---|---|---|---|
| image GHCR | v1.0.49-amazon-validation-pipeline-dev | present | OK |
| manifest digest | sha256:16a864a1c31b... | confirme (imageID pod) | OK |
| SMTP DEV (PH-20.14F-SMTP) | 49.13.35.167:25 secure=false sans auth | applique en env | OK |

## 5. Queue snapshot BEFORE (read-only)

| Type | Status | Count before |
|---|---|---|
| AMAZON_POLL | PENDING | 4 |
| AMAZON_POLL | RUNNING | 3 |
| AMAZON_POLL | DONE | 150709 |
| OUTBOUND_EMAIL_SEND | DONE | 9 |
| OUTBOUND_EMAIL_SEND | FAILED | 16 |
| OUTBOUND_EMAIL_SEND | PENDING/RETRY | 0 |
| AMAZON_SEND_REPLY | DONE/FAILED | 1 / 1 |
| OutboundEmail (total) | - | 24 |

OUTBOUND_EMAIL_SEND PENDING/RETRY = 0 -> le worker scope ne consomme rien spontanement (aucun envoi). AMAZON_POLL actif draine par les workers dedies.

## 6. Manifest design

Deployment jobs-worker (keybuzz-backend-dev), replicas 1, image v1.0.49, command node dist/workers/jobsWorker.js, imagePullSecrets ghcr-cred (standard sain, PAS le bug ImagePullBackOff du backfill-scheduler), envFrom keybuzz-backend-db + keybuzz-backend-secrets + vault-token(optional) + amazon-spapi-creds (mirror API), env inline JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP_HOST=49.13.35.167 + SMTP_PORT=25 + SMTP_SECURE=false (pas de SMTP_USER/PASS), livenessProbe exec ps (pas de health HTTP inventee), restartPolicy Always.

## 7. Diff GitOps

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | nouveau Deployment scope | faible | OK |

dry-run client + server : created (validation OK). 1 seul fichier. Pas v1.0.48.

## 8. Commit/push

| Commit | Files | Push | Verdict |
|---|---|---|---|
| fe07fba (keybuzz-infra main) | 1 (deployment-jobs-worker.yaml) | e7b97a5..fe07fba OK | OK |

## 9. Apply DEV

| Action | Resultat | Verdict |
|---|---|---|
| kubectl apply -f deployment-jobs-worker.yaml | deployment.apps/jobs-worker created | OK |
| rollout status (180s) | successfully rolled out | OK |

## 10. Runtime verify

| Check | Attendu | Observe | Verdict |
|---|---|---|---|
| deploy jobs-worker | existe | existe | OK |
| pod | Running | Running (jobs-worker-85c688bddb-r8pk4) | OK |
| restarts | 0 | 0 | OK |
| image tag | v1.0.49-amazon-validation-pipeline-dev | idem | OK |
| imageID | digest GHCR sha256:16a864a1c31b... | match | OK |
| env JOB_TYPES | OUTBOUND_EMAIL_SEND | OUTBOUND_EMAIL_SEND | OK |
| env SMTP | 49.13.35.167:25 secure=false | idem | OK |
| log scope | types=OUTBOUND_EMAIL_SEND | "[JobsWorker] Starting worker worker-1 types=OUTBOUND_EMAIL_SEND" | OK |
| erreurs DB/SMTP immediates | aucune | aucune | OK |

## 11. Queue snapshot AFTER / no unintended processing

| Signal | Before | After | Delta | Verdict |
|---|---|---|---|---|
| OUTBOUND_EMAIL_SEND DONE | 9 | 9 | 0 | OK |
| OUTBOUND_EMAIL_SEND FAILED | 16 | 16 | 0 | OK |
| OUTBOUND_EMAIL_SEND PENDING/RETRY | 0 | 0 | 0 | OK |
| OutboundEmail total | 24 | 24 | 0 | OK (aucun email cree/envoye) |
| AMAZON_POLL lockedBy worker-1 (jobs-worker) | n/a | 0 | 0 | OK (jamais claim AMAZON_POLL) |
| logs jobs-worker AMAZON_POLL / Processing / sent | n/a | aucun | - | OK |

AMAZON_POLL DONE/PENDING evoluent (150709->150716, 4->17) = workers dedies, PAS jobs-worker. mail-core-01 postfix active, queue stable (containment KEY-323 tient).

## 12. Anti-regression / AI feature parity

| Feature | Contrat | Change | Verdict |
|---|---|---|---|
| Workers Amazon dedies (orders/items) | gerent AMAZON_POLL | non touche ; jobs-worker scope ne claim pas AMAZON_POLL (0 lock) | PRESERVE |
| Amazon outbound From / guard VALIDATED | inchange | aucun | PRESERVE |
| inbound webhook / PH-20.11C / PH-20.12B | inchange | aucun | PRESERVE |
| PH-20.13B Client | suspendu | non repris | SUSPENDU |
| outbound deliveries marketplace | non retry | aucun | PRESERVE |

## 13. No fake metrics / events

Aucun fake validation/webhook/OutboundEmail/delivery/KBActions. Aucun job traite, aucun email. OutboundEmail inchange (24).

## 14. Interdits respectes

| Interdit | Respecte |
|---|---|
| PROD touche | OUI (DEV only) |
| trigger send-validation / retry outbound | OUI (0) |
| DB UPDATE manuel | OUI (read-only SELECT) |
| build / docker push | OUI |
| kubectl set/patch/edit/restart | OUI (apply -f GitOps uniquement) |
| v1.0.48 deploye | OUI (v1.0.49 uniquement) |
| AMAZON_POLL consomme par jobs-worker | OUI (0 lock) |

## 15. Rollback

| Element | Rollback | Risque |
|---|---|---|
| Deployment jobs-worker | git revert fe07fba + push + kubectl delete -f deployment-jobs-worker.yaml (documente) | faible (DEV, worker isole) |
| Manifest | revert commit GitOps | aucun |

## 16. Prochaine phrase GO

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14G

Conditions remplies : worker DEV healthy, logs propres, aucun AMAZON_POLL traite, aucun job involontaire, SMTP DEV configure, aucun PROD touche. Le re-trigger creera un OUTBOUND_EMAIL_SEND que le jobs-worker scope consommera -> SMTP self-test -> webhook -> VALIDATED. Verifier mail-core stable avant/apres. Ne PAS retry outbound marketplace.

STOP.
