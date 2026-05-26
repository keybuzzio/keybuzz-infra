# PH-SAAS-T8.12AS.20.14X-APPLY-BACKEND-AND-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14W / PH-20.14V / PH-20.14U / PH-20.14S-RCA / PH-20.14R
> Phase : PH-SAAS-T8.12AS.20.14X (APPLY GITOPS DEV : API + jobs-worker vers v1.0.53)
> Environnement : DEV uniquement (PROD non touche)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14X

API keybuzz-backend DEV + jobs-worker DEV deployes via GitOps strict de v1.0.52 vers v1.0.53-amazon-validation-pipeline-dev (revision 1179c15, digest GHCR sha256:5b893934). manifest = last-applied = runtime = imageID digest 5b893934 verifie pour les deux. jobs-worker conserve command node dist/workers/jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV 49.13.35.167:25 secure=false. Observabilite PH-20.14U active au runtime : startup enrichi "Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000" (image=unknown attendu : env IMAGE_VERSION non injectee, best-effort). No unintended processing : 0 AMAZON_POLL claime par worker-1, counts Job OUTBOUND_EMAIL_SEND (DONE 12/FAILED 16) et OutboundEmail (PENDING 1/FAILED 14/SENT 12) INCHANGES avant/apres, 0 claim, 0 OUTBOUND start, aucun SMTP/email/trigger volontaire. API boot sain (/health 200, 0 erreur Prisma). PROD intact v1.0.47.

Prochaine phrase GO : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14S-BIS (re-trigger DEV legitime unique sous observabilite ; les logs claim/done/heartbeat/OUTBOUND start+result identifieront le consommateur reel + la decision d envoi).

## 2. Sources relues

PH-20.14W (push image v1.0.53), PH-20.14V (build), PH-20.14U (source patch observabilite + JOB_TYPES), PH-20.14S-RCA (gap observabilite), PH-20.14R (apply v1.0.52). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/service | branche/runtime | HEAD/digest | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | HEAD=origin 5135179 | dirty=0 | OK |
| keybuzz-backend | main | HEAD=origin 1179c15 | dirty=1 (amazon.routes.ts.bak untracked, hors scope) | OK |
| API DEV (avant) | v1.0.52 | digest 4e60d0e8 | ready | OK |
| jobs-worker DEV (avant) | v1.0.52 | digest 4e60d0e8 | ready | OK |
| GHCR v1.0.53 | - | manifest digest sha256:5b893934...886368 | present | OK (== attendu) |
| PROD backend | v1.0.47-cross-env-guard-fix-prod | - | - | INTACT |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

last-applied avant = v1.0.52 pour API + jobs-worker = manifest = runtime (pas de divergence -> pas de STOP).

## 4. Runtime before / after

| Service | image avant | image apres | imageID digest apres | ready | restarts | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend (API) | v1.0.52 | v1.0.53 | sha256:5b893934...886368 | true | 0 | OK |
| jobs-worker | v1.0.52 | v1.0.53 | sha256:5b893934...886368 | true | 0 | OK |

Nouveaux pods : keybuzz-backend-54457d5d5f-g77fw (start 09:53), jobs-worker-84d8484cdf-4tmv4 (start 09:53). Anciens pods v1.0.52 termines. imageID digest des 2 pods == GHCR manifest digest 5b893934.

## 5. Manifests modifies

| Fichier | changement | preserve | verdict |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | L32 image v1.0.52 -> v1.0.53, commentaire PH-20.14X rollback v1.0.52 | command API, ports, probes, envFrom, resources, ns, labels | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | L32 image v1.0.52 -> v1.0.53, commentaire PH-20.14X rollback v1.0.52 | command node dist/workers/jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false, envFrom, imagePullSecrets | OK |

git diff = 2 fichiers, +2/-2 (1 ligne chacun). Patch via Python str.replace (sed echoue sur le delimiteur | du commentaire). Aucune ref v1.0.48-52 residuelle dans l image (seul "rollback: v1.0.52" dans le commentaire). PROD/secrets/SMTP/JOB_TYPES non modifies.

## 6. Dry-run

| Cible | dry-run client | dry-run server | verdict |
|---|---|---|---|
| deployment.yaml (API) | configured (dry run) | configured (server dry run) | OK |
| deployment-jobs-worker.yaml | configured (dry run) | configured (server dry run) | OK |

Verif rendu manifest jobs-worker : image v1.0.53 True, JOB_TYPES=OUTBOUND_EMAIL_SEND True, SMTP_HOST 49.13.35.167 True, SMTP_PORT present, SMTP_SECURE present.

## 7. Rollout

| Service | apply | rollout status | verdict |
|---|---|---|---|
| keybuzz-backend (API) | configured | successfully rolled out | OK |
| jobs-worker | configured | successfully rolled out | OK |

Apply uniquement via kubectl apply -f <manifest>. Aucun set image / patch / edit / rollout restart. Commit infra e82b69d pousse AVANT apply.

## 8. Digest

| Service | manifest | last-applied | runtime (pod img) | imageID digest | verdict |
|---|---|---|---|---|---|
| API | v1.0.53 | v1.0.53 | v1.0.53 | sha256:5b893934...886368 | MATCH |
| jobs-worker | v1.0.53 | v1.0.53 | v1.0.53 | sha256:5b893934...886368 | MATCH |

GHCR manifest digest = sha256:5b893934ad7fdfa69093c90d4067e81e3cb649dd9cd964c4797a74fbba886368.

## 9. No unintended processing

| Signal | before (E2) | after (E8) | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND DONE | 12 | 12 | INCHANGE |
| Job OUTBOUND_EMAIL_SEND FAILED | 16 | 16 | INCHANGE |
| OutboundEmail PENDING | 1 | 1 | INCHANGE |
| OutboundEmail FAILED | 14 | 14 | INCHANGE |
| OutboundEmail SENT | 12 | 12 | INCHANGE |
| AMAZON_POLL lockedBy worker-1 | 0 | 0 | OK |
| jobs-worker claim jobId / OUTBOUND start | - | 0 / 0 | OK (aucun traitement spontane) |
| SMTP send / email self-test / trigger | - | 0 | OK |
| API boot | - | /health 200, 0 erreur Prisma | OK |
| jobs-worker startup observabilite | - | enrichi (scope+jobTypesRaw+pollMs) | OK |

Heartbeat (30 polls x 2s = 60s) non encore emis au moment de la verif (pod a ~46s). Startup observability presente = suffisant.

## 10. AI feature parity / anti-regression

| Feature | Etat | Verdict |
|---|---|---|
| Guard outbound validationStatus=VALIDATED | non touche | OK |
| From Amazon amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | non touche | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | preserve (jamais AMAZON_POLL ; 0 claime) | OK |
| sendOutboundEmailById / resolution casse (14O/14I) | embarque v1.0.53, non re-exerce cette phase | OK |
| retry outbound / fake webhook / fake email | 0 | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve | OK |
| PH-20.13B Client push | reste suspendu | OK |

## 11. No fake metrics / no fake events

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation / migration | 0 | OK |
| validationStatus flip manuel | 0 | OK |

Aucune ecriture runtime hors la bascule d image (deploiement). Snapshots DB read-only via prisma groupBy/count dans le pod API.

## 12. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| API DEV | re-apply deployment.yaml avec image v1.0.52 (rollback documente dans commentaire) | retour v1.0.52 |
| jobs-worker DEV | re-apply deployment-jobs-worker.yaml avec image v1.0.52 | retour v1.0.52 |
| Manifests | git revert e82b69d | retour v1.0.52 |
| Image v1.0.53 GHCR | immuable, conservee | aucun |

## 13. Prochaine phase

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PH-SAAS-T8.12AS.20.14S-BIS : re-trigger DEV legitime unique (X-User-Email dev@keybuzz.io + KEYBUZZ_DEV_MODE, pas un bypass) sur la cible PENDING cmk5caxx700037d01tglfhe3v ; sous l observabilite v1.0.53 les logs claim/done/heartbeat/OUTBOUND start+result identifieront le consommateur reel + la decision d envoi du job OUTBOUND_EMAIL_SEND (gap RCA 14S). Phase config separee : upgrader amazon-orders/items-worker hors v1.0.40 + fixer leur JOB_TYPES. Ne pas promouvoir PROD, ne pas retry outbound, ne pas flip DB.

Phrase cible : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14X

STOP.
