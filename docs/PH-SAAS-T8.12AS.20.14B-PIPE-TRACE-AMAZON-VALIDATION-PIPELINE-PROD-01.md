# PH-SAAS-T8.12AS.20.14B-PIPE-READONLY-TRACE-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14 / PH-20.14A / PH-20.14B / PH-20.14B-VERIFY
> Phase : PH-SAAS-T8.12AS.20.14B-PIPE-READONLY-TRACE-AMAZON-VALIDATION-PIPELINE-PROD
> Environnement : PROD (READ-ONLY STRICT ; aucune mutation)

## 1. Verdict

GO READONLY TRACE AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14B-PIPE

Root cause identifiee et CODE-PROUVEE. La validation self-test Amazon ne peut pas produire d email en PROD pour DEUX raisons cumulatives independantes :
1. Le handler de job OUTBOUND_EMAIL_SEND est un STUB NON IMPLEMENTE (TODO) dans src/workers/jobsWorker.ts (depuis PH11-06C) : il logge "OUTBOUND_EMAIL_SEND not implemented" et ne fait rien.
2. AUCUN deploy/cronjob ne lance jobsWorker en PROD (4 deploys + 2 cronjobs ; aucun ne lance dist/workers/jobsWorker.js ; absent des manifests GitOps). Donc meme les jobs enqueues ne sont jamais traites.

En complement, la table OutboundEmail est VIDE (tout historique) -> pour les tenants PENDING actuels, la route send-validation n atteint meme pas sendValidationEmail (probable 404 "No inbound connection"). Mais c est secondaire : meme en amont OK, l envoi serait bloque par (1)+(2).

backfill-scheduler en ImagePullBackOff est NON LIE : il lance amazonBackfillScheduler.runSchedulerLoop, pas jobsWorker, pas l email de validation.

Correctif = SOURCE PATCH DEV (implementer OUTBOUND_EMAIL_SEND) + DEPLOY d un jobsWorker en PROD. Pas un simple re-trigger. DEV avant PROD.

PH-20.13B push Client reste SUSPENDU. Aucune mutation, aucun trigger, aucun retry.

## 2. Sources relues

PH-20.14 / 20.14A / 20.14B / 20.14B-VERIFY ; KEY-323-APPLY ; backend src (jobsWorker.ts, inboundEmailValidation.service.ts, amazon.routes.ts, outboundEmail.service.ts) ; manifests k8s/keybuzz-backend-prod ; AI_MEMORY RULES_AND_RISKS.

## 3. Preflight (runtimes PROD, read-only)

| Component | Namespace | Image | Ready | Verdict |
|---|---|---|---|---|
| keybuzz-backend (API) | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | 1/1 | OK |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-...-backfill-prod | 1/1 | OK (items) |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-...-backfill-prod | 1/1 | OK (orders) |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | 0/1 ImagePullBackOff 10j | CASSE (non lie) |
| cronjobs | keybuzz-backend-prod | amazon-orders-sync, amazon-reports-tracking-sync | - | aucun = jobsWorker |
| mail-core-01 | infra | n/a | active | stable (KEY-323 contenu) |

## 4. Trace UI -> route (read-only)

| Layer | File/Route | Method | Target | Effet attendu |
|---|---|---|---|---|
| API compat (proxy) | keybuzz-api compat/routes.ts:154 POST /api/v1/marketplaces/amazon/inbound-address/send-validation | POST | legacy backend | proxy |
| Backend route | keybuzz-backend amazon.routes.ts:533 (preHandler authenticate) | POST | sendValidationEmail | envoyer self-test |

Auth = devAuthenticateOrJwt (JWT/X-User-Email), tenant resolu depuis l utilisateur. (Non appele dans cette phase.)

## 5. Trace route -> service validation

amazon.routes.ts:533 handler : auth -> lookup prisma.inboundConnection (tenantId_marketplace) -> si absent 404 "No inbound connection" (sendValidationEmail JAMAIS appele) -> sinon sendValidationEmail(connection.id, country) -> reponse "Validation email sent".

Point critique : updatedAt d une adresse peut bouger sans validation via un re-sync channel (channelsRoutes activate-amazon ON CONFLICT updatedAt=NOW()), distinct de la validation. C est coherent avec ecomlg-mot FR updatedAt=14:02 sans VALIDATED.

## 6. Trace service -> OutboundEmail / queue

inboundEmailValidation.service.ts:39-60 : sendValidationEmail cree prisma.outboundEmail.create({ status: PENDING, from: validator@inbound.keybuzz.io, subject: "KeyBuzz Validation <token>" }) PUIS enqueueJob({ type: OUTBOUND_EMAIL_SEND, payload: { outboundEmailId } }).

| Table/Queue | Count total | Validation rows | Verdict |
|---|---|---|---|
| OutboundEmail (Prisma backend DB) | 0 (tout historique) | 0 | VIDE -> sendValidationEmail non execute pour ces tenants |

Colonnes OutboundEmail : id,tenantId,ticketId,to,from,subject,body,provider,status,error,sentAt,createdAt,updatedAt.

## 7. Trace worker OUTBOUND_EMAIL_SEND -- ROOT CAUSE

Code src/workers/jobsWorker.ts (commit PH11-06C 3ab02a2, jamais modifie depuis) :
```
case "OUTBOUND_EMAIL_SEND":
  // TODO: Implement outbound email sending
  console.log("[JobsWorker] OUTBOUND_EMAIL_SEND not implemented");
  break;
```
-> handler NON IMPLEMENTE.

| Worker candidate | Deploy/CronJob | Command | Status | Verdict |
|---|---|---|---|---|
| jobsWorker (dist/workers/jobsWorker.js) | AUCUN | - | absent | NON DEPLOYE en PROD |
| amazon-items-worker | deploy | itemsWorkerResilient.js | 1/1 | ne traite PAS les jobs email |
| amazon-orders-worker | deploy | ordersWorkerResilient.js | 1/1 | idem |
| backfill-scheduler | deploy | amazonBackfillScheduler.runSchedulerLoop | ImagePullBackOff | NON LIE a l email |
| cronjobs (orders-sync, reports-tracking-sync) | cronjob | - | - | ne lancent pas jobsWorker |
| GitOps manifests | grep jobsWorker dans k8s | - | aucun | jobsWorker jamais defini en manifest |

Double rupture : (a) handler stub non implemente ; (b) aucun process jobsWorker deploye. Resultat : un job OUTBOUND_EMAIL_SEND enqueue ne serait jamais traite ET le code ne sait pas l envoyer.

## 8. backfill-scheduler ImagePullBackOff

| Component | Image | Error | Role | Blocks validation ? |
|---|---|---|---|---|
| backfill-scheduler | v1.0.42-td02-worker-resilience-prod | Back-off pulling image (10j) | amazonBackfillScheduler.runSchedulerLoop (backfill commandes Amazon) | NON (ne traite ni jobs ni email) |

A signaler comme incident infra distinct (image absente du registry), mais hors scope validation email.

## 9. Logs PROD

| Source | Pattern | Observe | Interpretation |
|---|---|---|---|
| backend API pod | send-validation / Queued email / Validation | aucun (30 min) | route non atteinte / pas de log recent |
| mail-core | validator@ / amazon.* / relay=webhook | aucun (12 min) | aucun self-test envoye |
| jobsWorker | - | aucun pod | worker inexistant |

## 10. Root cause

| Hypothese | Evidence for | Evidence against | Probabilite | Next action |
|---|---|---|---|---|
| E. OutboundEmail cree mais worker absent/down | aucun deploy/cronjob jobsWorker ; absent GitOps | OutboundEmail vide (rien a traiter) | HAUTE (worker absent confirme) | deployer jobsWorker |
| Code bug : OUTBOUND_EMAIL_SEND non implemente | stub TODO dans jobsWorker.ts depuis PH11-06C | - | CERTAINE (code lu) | implementer handler |
| D. sendValidationEmail n ecrit pas OutboundEmail | table vide all-time | code fait bien create() | MOYENNE (route 404 amont probable) | verifier inboundConnection presence |
| C. route touche channel sans sendValidationEmail | updatedAt bump sans email | - | POSSIBLE (re-sync channel) | a confirmer cote UI/log |
| A/B/F/G | - | mail-core OK, webhook OK, auth route existe | FAIBLE | - |

Conclusion : root cause dominante = code bug (OUTBOUND_EMAIL_SEND non implemente) + worker jobsWorker non deploye. La fonctionnalite "Renvoyer la validation" self-test n a probablement JAMAIS fonctionne via ce chemin (le stub existe depuis PH11-06C) ; les 8 adresses VALIDATED historiques ont ete validees autrement (emails entrants reels / mecanisme anterieur au job-queue). Ce n est donc PAS une regression KEY-323 mais un gap applicatif latent, revele par la reactivation post-incident.

## 11. Plan correctif futur (NON applique, DEV avant PROD)

| Fix candidate | Scope | Risk | Build ? | Deploy ? | Rollback |
|---|---|---|---|---|---|
| Implementer OUTBOUND_EMAIL_SEND dans jobsWorker.ts (appel outboundEmail.service sendEmail -> SMTP mail.keybuzz.io, update OutboundEmail status) | backend src | moyen | OUI (build-from-git DEV puis PROD) | non (code) | revert commit + rebuild |
| Deployer un jobsWorker (deploy K8s qui lance dist/workers/jobsWorker.js) | infra GitOps | moyen | non | OUI (manifest + apply) | supprimer deploy |
| Verifier inboundConnection present pour tenants PENDING (sinon route 404) | DB read-only / produit | faible | non | non | n/a |
| Reparer backfill-scheduler image (incident infra distinct) | infra | faible | non | OUI | revert image tag |

Ordre recommande : DEV d abord (implementer handler + tester self-test loop en DEV : OutboundEmail PENDING -> SMTP -> webhook -> VALIDATED), build-from-git, puis PROD (push image + deploy jobsWorker GitOps), puis PH-20.14B re-trigger authentifie + verify. AUCUN retry outbound tant que PENDING.

## 12. Amazon feature parity / anti-regression

| Feature | Contrat | Change now | Risk |
|---|---|---|---|
| Amazon outbound From = amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | inchange | NON | aucun |
| Guard validationStatus=VALIDATED | inchange | NON | aucun |
| PH-20.11C / PH-20.12B | code API inchange | NON | aucun |
| inbound webhook Amazon | preserve | NON | aucun |
| outbound_deliveries | non touche | NON | aucun |
| PH-20.13B Client | suspendu | NON | aucun |

## 13. No fake metrics / events

| Object | Allowed source | Fake forbidden | Verdict |
|---|---|---|---|
| validationStatus | webhook processValidationEmail reel | flip DB | aucun |
| OutboundEmail | sendValidationEmail reel | insert manuel | aucun |
| validation | self-test loop reel | fake webhook | aucun |

## 14. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Trigger send-validation / curl POST / appel route | OUI | 0 |
| Mutation DB / flip VALIDATED / retry outbound | OUI | 0 (SELECT read-only) |
| kubectl apply/set/patch/edit/rollout/delete/scale | OUI | 0 (get/describe/logs + exec node read-only) |
| build/push/deploy / patch source / patch manifest | OUI | 0 |
| Postfix/MX/DNS | OUI | 0 |
| secret/env dump / DATABASE_URL affiche | OUI | connectionString non imprime, PII masquee |
| Push Client PH-20.13B | OUI | suspendu |
| Bastion install-v3 | OUI | verifie |

## 15. Rollback

N/A - phase read-only, aucune mutation.

## 16. Prochaine phrase GO

GO SOURCE PATCH AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14C

Objet : implementer le handler OUTBOUND_EMAIL_SEND (jobsWorker.ts) pour envoyer reellement l email via outboundEmail.service / SMTP et mettre a jour OutboundEmail, tester le self-test loop en DEV (PENDING -> SMTP -> webhook -> VALIDATED), build-from-git ; PUIS phase separee de deploiement jobsWorker PROD (GitOps) ; PUIS PH-20.14B re-trigger authentifie + verify. Traiter aussi (sous-phase) le 404 inboundConnection eventuel et l incident backfill-scheduler ImagePullBackOff (distinct). NE PAS retry outbound tant que les adresses restent PENDING. DEV avant PROD, GO PROD explicite requis.

STOP.
