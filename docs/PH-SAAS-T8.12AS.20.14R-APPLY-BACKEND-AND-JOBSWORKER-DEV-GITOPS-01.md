# PH-SAAS-T8.12AS.20.14R-APPLY-BACKEND-AND-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14Q / PH-20.14P / PH-20.14O
> Phase : PH-SAAS-T8.12AS.20.14R (APPLY GITOPS DEV : API + jobs-worker -> v1.0.52)
> Environnement : DEV uniquement (PROD non touche)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14R

API keybuzz-backend DEV et jobs-worker DEV deployes en v1.0.52-amazon-validation-pipeline-dev via GitOps strict (manifest -> commit fc99376 -> push -> kubectl apply -f -> rollout -> verif). Runtime = manifest = last-applied = digest GHCR sha256:4e60d0e8 pour les deux. jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV 49.13.35.167:25 secure=false + command node dist/workers/jobsWorker.js. No unintended processing : 0 AMAZON_POLL claime par worker-1, OUTBOUND_EMAIL_SEND DONE 11/FAILED 16 inchanges, OutboundEmail SENT 12/FAILED 14 inchanges, aucun trigger, aucun email volontaire, aucune mutation DB hors rollout K8s. PROD intact (v1.0.47-cross-env-guard-fix-prod).

Prochaine phrase GO : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14S (re-trigger sur l adresse PENDING cible). Non executee dans cette phase.

## 2. Sources relues

PH-20.14Q (push v1.0.52), PH-20.14P (build), PH-20.14O (source patch casse marketplace), PH-20.14L (deploy v1.0.51). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight (repos)

| Repo | branche | HEAD local | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-infra | main | fc99376 (apres E5) | fc99376 | non | OK |
| keybuzz-backend | main | 8f7122b | 8f7122b | non (hors amazon.routes.ts.bak) | OK |
| Bastion install-v3 / 46.62.171.61 | - | - | - | - | OK |
| GHCR v1.0.52 digest | - | - | sha256:4e60d0e865...f92676 | - | OK (match attendu) |

## 4. Runtime before / after

| Service | namespace | image avant | image apres | imageID digest apres | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend (API) | keybuzz-backend-dev | v1.0.51 | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.51 | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| keybuzz-backend (API) | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | inchange | - | - | - | OK (non touche) |

Anciens pods v1.0.51 (imageID 92f164d2) termines apres rollout ; seuls 2 pods v1.0.52 Running.

## 5. Manifests modifies (E3)

| Fichier | changement | risque | verdict |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | image L32 v1.0.51 -> v1.0.52 ; comment PH 20.14L -> 20.14R ; rollback v1.0.50 -> v1.0.51 | faible (image tag seul) | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | image L32 v1.0.51 -> v1.0.52 ; comment PH 20.14L -> 20.14R ; rollback v1.0.50 -> v1.0.51 | faible (image tag seul) | OK |

git diff = 2 lignes image seulement. command, JOB_TYPES, SMTP_HOST/PORT/SECURE, envFrom, imagePullSecrets, probes, resources, namespace, labels/selectors NON modifies (hors diff). Patch applique via python str.replace exact (sed initial echoue sur delimiteur `|` du commentaire ; aucune ecriture partielle).

## 6. Dry-run (E4)

| Commande | resultat | verdict |
|---|---|---|
| kubectl apply --dry-run=client -f deployment.yaml | deployment.apps/keybuzz-backend configured (dry run) | OK |
| kubectl apply --dry-run=client -f deployment-jobs-worker.yaml | deployment.apps/jobs-worker configured (dry run) | OK |
| kubectl apply --dry-run=server -f deployment.yaml | configured (server dry run) | OK |
| kubectl apply --dry-run=server -f deployment-jobs-worker.yaml | configured (server dry run) | OK |
| refs v1.0.48/49/50/51 (image lines) | 0 | OK |
| v1.0.52 image lines | 2 | OK |
| JOB_TYPES + SMTP env present | oui | OK |

## 7. Rollout (E6)

| Etape | resultat | verdict |
|---|---|---|
| commit infra (E5) | fc99376 chore(amazon): deploy validation pipeline dev v1.0.52 ; push origin/main ; manifests distants = v1.0.52 | OK |
| kubectl apply -f deployment.yaml | deployment.apps/keybuzz-backend configured | OK |
| rollout status keybuzz-backend | successfully rolled out | OK |
| kubectl apply -f deployment-jobs-worker.yaml | deployment.apps/jobs-worker configured | OK |
| rollout status jobs-worker | successfully rolled out | OK |

Aucun kubectl set image/patch/edit, aucun rollout restart.

## 8. Digest runtime (E7)

| Service | image manifest | last-applied | runtime | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend | v1.0.52 | v1.0.52 | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| jobs-worker | v1.0.52 | v1.0.52 | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |

API boot : "Server listening at http://127.0.0.1:4000" + "KeyBuzz backend listening on port 4000", aucune erreur Prisma. jobs-worker boot : "Starting worker worker-1 types=OUTBOUND_EMAIL_SEND", aucune erreur Prisma/SMTP. env runtime jobs-worker : JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false (preserves).

## 9. No unintended processing (E2 before / E8 after)

| Signal | before | after | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND DONE | 11 | 11 | INCHANGE |
| Job OUTBOUND_EMAIL_SEND FAILED | 16 | 16 | INCHANGE |
| OutboundEmail SENT | 12 | 12 | INCHANGE |
| OutboundEmail FAILED | 14 | 14 | INCHANGE |
| AMAZON_POLL lockedBy='worker-1' (exact) | 0 | 0 | OK (scope respecte) |
| Nouveau pod jobs-worker logs | - | startup only (Starting worker worker-1 types=OUTBOUND_EMAIL_SEND) | OK (aucun claim) |

Les lignes "Claimed cmpls9p6g ... sent (provider=smtp)" observees dans le log agrege provenaient du POD v1.0.51 en terminaison (job PH-20.14M deja DONE) ; le nouveau pod v1.0.52 (f4qxm) ne loggue que le startup. Compteurs DONE/SENT inchanges = preuve : aucun job re-traite, aucun email re-envoye. AMAZON_POLL global a bouge (PENDING 3->11, DONE 153111->153122) = workers Amazon dedies normaux, jamais worker-1.

## 10. AI feature parity / anti-regression (E9)

| Feature | Contrat | Etat | Verdict |
|---|---|---|---|
| Guard outbound validationStatus=VALIDATED | non bypasse | intact | OK |
| From Amazon | amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | intact | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | protege AMAZON_POLL | intact (0 claim worker-1) | OK |
| retry outbound / fake webhook / fake email | 0 | aucun | OK |
| PH-20.11C / PH-20.12B | preserve | non touche | OK |
| PH-20.13B Client push | suspendu | non repris | OK |

## 11. No fake metrics / no fake events (E10)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook | 0 | OK |
| fake OutboundEmail / fake Job | 0 | OK |
| DB mutation (hors rollout K8s) | 0 | OK |
| validationStatus flip | 0 | OK |

## 12. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| build / docker push | OUI | 0 |
| kubectl set image/env/patch/edit / rollout restart | OUI | apply -f + rollout status uniquement |
| PROD | OUI | non touche (v1.0.47 intact) |
| mutation DB / prisma migrate / db push | OUI | 0 |
| trigger validation / POST send-validation / retry outbound | OUI | 0 |
| email reel volontaire | OUI | 0 (compteurs inchanges) |
| changement SMTP / secret | OUI | 0 (env preserves) |
| deploy v1.0.48/49/50/51 | OUI | v1.0.52 uniquement |
| git reset --hard / git clean | OUI | 0 |

## 13. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Deploy DEV v1.0.52 | phase GitOps rollback dediee : manifests DEV -> v1.0.51, commit+push, kubectl apply -f, rollout, verif runtime=manifest=last-applied | retour v1.0.51 |
| Methode interdite | kubectl set image | - |
| Image v1.0.52 GHCR | conservee (immuable) | - |

## 14. Prochaine phase

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14S : re-trigger legitime (send-validation DEV-mode) sur l adresse PENDING cible, pour prouver la transition PENDING -> VALIDATED via le flow reel sur v1.0.52 (resolution emailAddress case-insensitive). Conditions remplies : API ET jobs-worker DEV tournent tous les deux sur v1.0.52.

Phrase cible : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14R

STOP.
