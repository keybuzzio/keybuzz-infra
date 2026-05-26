# PH-SAAS-T8.12AS.20.14S-RCA-AMAZON-OUTBOUND-SEND-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14S / PH-20.14R / PH-20.14M
> Phase : PH-SAAS-T8.12AS.20.14S-RCA (READ-ONLY RCA)
> Environnement : DEV uniquement (PROD non touche)

## 1. Verdict

GO RCA AMAZON OUTBOUND SEND DEV PARTIAL PH-SAAS-T8.12AS.20.14S-RCA

RCA read-only menee de bout en bout (DB + code source 8f7122b + image v1.0.52 + image v1.0.40 + k8s + logs). Le symptome est entierement caracterise : le Job OUTBOUND_EMAIL_SEND cmpma3o1x est passe DONE (attempts=0, lockedBy=null, lastError=null, payload correct { outboundEmailId: cmpma3nsd }) en 320 ms, alors que l OutboundEmail cmpma3nsd reste PENDING (provider=null, sentAt=null, error=null), aucun SMTP a mail-core, et le jobs-worker v1.0.52 (seul consommateur scope OUTBOUND_EMAIL_SEND) ne loggue aucun claim/traitement.

Cause racine NON entierement close en read-only : l etat DB observe (DONE + OE PENDING + attempts=0 + error=null) est INCOMPATIBLE avec les deux seuls chemins du code v1.0.52 deploye (succes -> OE SENT/provider ; echec -> OE FAILED/error + Job RETRY/FAILED attempts++). Le seul appelant de markJobDone est jobsWorker.js, mais le pod jobs-worker n a emis aucun log au-dela du startup. Classification dominante : GAP D OBSERVABILITE (le consommateur reel et sa decision ne sont pas tracables) + hazard de configuration latent (claim non-scope). Une action minimale est proposee (instrumentation + scoping deterministe) AVANT toute conclusion definitive ou nouveau trigger.

## 2. Sources relues

PH-20.14S (retrigger PARTIAL), PH-20.14R (deploy v1.0.52), PH-20.14M (retrigger v1.0.51 OK), PH-20.14O (source patch). Source backend 8f7122b. Images v1.0.52 (jobs-worker, API) et v1.0.40 (amazon workers). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Runtime (E0)

| Service | namespace | image | digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend (API) | keybuzz-backend-dev | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK (scope OUTBOUND_EMAIL_SEND) |
| amazon-orders-worker | keybuzz-backend-dev | v1.0.40-amz-tracking-visibility-backfill-dev | - | 1/1 | 2 | STALE (poller dedie) |
| amazon-items-worker | keybuzz-backend-dev | v1.0.40-amz-tracking-visibility-backfill-dev | - | 1/1 | 0 | STALE (poller dedie) |
| backfill-scheduler | keybuzz-backend-dev | (v1.0.42) | - | 0/1 | ImagePullBackOff | NON RUNNING |
| keybuzz-backend (API) PROD | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | - | - | - | INTACT |

infra HEAD d8378f4, backend HEAD 8f7122b. DB observee = keybuzz_backend.

## 4. Objets DB cmpma3o1x / cmpma3nsd (E1 + E5)

| Objet | id | status | lockedBy | attempts | createdAt | updatedAt | sentAt | verdict |
|---|---|---|---|---|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | cmpma3o1x | DONE | null | 0 | 06:53:11.685 | 06:53:12.005 | n/a | DONE en 320 ms |
| OutboundEmail | cmpma3nsd | PENDING | n/a | n/a | 06:53:11.341 | 06:53:11.341 | null | JAMAIS ENVOYE (provider=null, error=null) |

Job payload = { "outboundEmailId": "cmpma3nsd0000bu01bi1bppj7" } : CORRECT (reference l OutboundEmail). Memes payload shape que les anciens OUTBOUND_EMAIL_SEND DONE (cmpls9p6g 14M, cmplq2ti 14G-TER). Donc le payload N EST PAS la cause. OutboundEmail.updatedAt == createdAt : la ligne n a jamais ete modifiee apres creation (ni SENT ni FAILED).

claimNextJob (jobs.service.ts L120-141) N INCREMENTE PAS attempts (il set RUNNING/lockedAt/lockedBy seulement). Donc attempts=0 est compatible avec un claim normal ; attempts ne s incremente que dans markJobFailed/markJobRetry. Le chemin FAILED n a donc PAS ete pris (sinon attempts=1 + Job RETRY/FAILED + OE FAILED + error).

## 5. Consommateurs potentiels de Job (E2 + E6)

| Pod/deploy | command | image | utilise claimNextJob/markJobDone ? | peut consommer OUTBOUND_EMAIL_SEND | preuve |
|---|---|---|---|---|---|
| jobs-worker | node dist/workers/jobsWorker.js | v1.0.52 | OUI (scope JOB_TYPES=OUTBOUND_EMAIL_SEND) | OUI (consommateur prevu) | source + env |
| amazon-orders-worker | node dist/workers/ordersWorkerResilient.js | v1.0.40 | NON (poller dedie SP-API) | NON | grep dist : pas de claimNextJob/markJobDone/OUTBOUND ; logs "[OrdersWorker] IDLE iteration=NNN totalPersisted=0" |
| amazon-items-worker | node dist/workers/itemsWorkerResilient.js | v1.0.40 | NON (poller dedie) | NON | meme nature |
| backfill-scheduler | runSchedulerLoop | v1.0.42 | non running (ImagePullBackOff) | non | non demarre |
| CronJobs (orders sync/backfill/reports) | curlimages/curl POST API | curl | NON | NON | curl-only, pas de worker:jobs |
| keybuzz-backend (API) | (api) | v1.0.52 | enqueueJob seulement | NON (n appelle pas markJobDone) | enqueueJob = INSERT PENDING + log, pas de NOTIFY/inline process |

Recherche cluster-wide : UN SEUL pod lance jobsWorker.js (jobs-worker f4qxm). Aucun pod jobsWorker dans un autre namespace. Aucun CronJob worker:jobs:once. Aucun NOTIFY/LISTEN/EventEmitter dans jobs.service / route / validation.

## 6. Logs (E3)

| Source log | pattern | resultat | interpretation |
|---|---|---|---|
| API pod | cmpma3o1x | 2 hits : "Enqueued job cmpma3o1x" + "Queued email ... (job: cmpma3o1x)" | l API a cree OE + enqueue ; rien de plus |
| jobs-worker f4qxm | Claimed / Processing / OUTBOUND / done / marked DONE / cmpma3o1x | 0 (uniquement "Starting worker worker-1 types=OUTBOUND_EMAIL_SEND" depuis 06:43) | jobs-worker n a PAS logge de traitement de ce job |
| amazon-orders/items-worker | cmpma3o1x / OUTBOUND / Claimed | 0 | non concernes (pollers IDLE) |
| mail-core mail.log | 812g37 / validator@ a 06:53 | 0 (dernieres entrees 812g37 = 25 mai 21:32 et 22:34) | aucun SMTP self-test envoye ce run |

## 7. Code paths v1.0.52 (E4)

| Code path | comportement attendu | constat |
|---|---|---|
| sendValidationEmail (API) | cree OutboundEmail PENDING + enqueueJob OUTBOUND_EMAIL_SEND ; pas d envoi inline | conforme (logs Enqueued+Queued) |
| enqueueJob | INSERT Job PENDING + log ; aucune completion/NOTIFY | conforme |
| jobsWorker.runWorker | poll toutes les 2000 ms ; claimNextJob(scope) -> processJob -> markJobDone ; sur erreur markJobFailed | aucun log de claim pour ce job |
| processJob OUTBOUND_EMAIL_SEND | parseOutboundEmailJobPayload -> sendOutboundEmailById -> log "skipped/done" | aucun log |
| sendOutboundEmailById | findById ; decideOutboundEmailAction(PENDING)=send ; sender SMTP -> markSent(SENT/provider) ; sur throw markFailed(FAILED/error)+rethrow | NI SENT NI FAILED en DB -> ce code n a pas tourne sur cmpma3nsd |
| decideOutboundEmailAction | skip seulement si status=SENT | cmpma3nsd=PENDING -> aurait du SEND |
| parseJobTypesEnv("") | retourne undefined -> claim TOUS les types (pas "claim nothing") | HAZARD latent (voir sec.8) |

Conclusion code : le chemin v1.0.52 sendOutboundEmailById aurait laisse l OutboundEmail en SENT ou FAILED, jamais PENDING. L etat PENDING + Job DONE n est produit par AUCUN chemin du binaire v1.0.52. Le markJobDone observe n a pas ete precede d un sendOutboundEmailById reussi/echoue sur cette ligne.

## 8. RCA (E8)

Reponses explicites :

1. Qui a mis cmpma3o1x en DONE ? NON identifiable par les logs. Le seul code markJobDone = jobsWorker.js:95 ; le seul jobsWorker.js actif (f4qxm v1.0.52) n a emis aucun log de claim/done. Aucun autre consommateur (amazon workers = pollers ; API = enqueue seul ; pas de cron once ; pas de 2e jobsWorker). => completion par un chemin non observable.

2. Pourquoi OutboundEmail cmpma3nsd reste PENDING ? Parce que sendOutboundEmailById (qui aurait mis SENT ou FAILED) n a pas tourne sur cette ligne (updatedAt==createdAt, provider/sentAt/error null). Le Job a ete clos sans passer par la jambe d envoi.

3. Pourquoi aucun SMTP mail-core ? Corollaire de (2) : aucun appel sender/SMTP.

4. Pourquoi aucun log jobs-worker ? Soit le jobs-worker n a pas traite ce job (un autre chemin l a clos), soit ses logs par-job ne sont pas captures (gap d observabilite). Les deux convergent vers un manque d instrumentation : impossible de prouver le consommateur.

5. Type de cause : DOMINANT = OBSERVABILITY GAP (instrumentation insuffisante pour identifier le consommateur et sa decision ; etat DB incoherent avec le code deploye non explicable read-only). SECONDAIRE = HAZARD DE CONFIG : (a) parseJobTypesEnv("") => undefined => claim-all (une valeur JOB_TYPES vide ne protege PAS) ; (b) amazon-orders/items-worker sur image STALE v1.0.40 avec JOB_TYPES="" (sans parseJobTypesEnv) ; meme si actuellement pollers dedies, c est une derive de version non maitrisee. PAS un bug du patch PH-20.14O (qui ne touche ni le worker ni la jambe d envoi). PAS un mismatch DB (API et worker pointent keybuzz_backend, current_database confirme). PAS un payload incompatible (payload correct).

6. Pourquoi v1.0.51 (14M) a envoye mais pas v1.0.52 (14S), alors que 14O ne touche pas le worker ? Le code worker/send est identique v1.0.51 -> v1.0.52. La difference est donc RUNTIME/NON-DETERMINISTE (timing/observabilite), pas une regression de code introduite par 14O. En 14M le flux a abouti (OE SENT, mail-core relay=webhook, logs worker presents) ; en 14S la jambe d envoi n a pas tourne et aucun log worker n est present. Hypothese la plus coherente : instrumentation/consommation non deterministe a clarifier par logs avant re-test.

7. Action minimale suivante : instrumenter (jobsWorker : log structure claim/skip/done avec jobId+workerId+image+outcome ; heartbeat de poll ; logguer le resultat sendOutboundEmailById) ; durcir parseJobTypesEnv (vide => claim nothing, pas claim-all) ; garantir UN SEUL consommateur deterministe scope. Puis re-trigger sous observabilite. C est un patch SOURCE d observabilite + durcissement config, sans changer la logique metier.

## 9. AI feature parity / anti-regression (E9)

| Feature | Etat | Verdict |
|---|---|---|
| Guard outbound validationStatus=VALIDATED | intact | OK |
| From Amazon amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | intact | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | intact (env present) | OK |
| AMAZON_POLL claime par worker-1 | 0 | OK |
| retry outbound / fake webhook / fake email | 0 | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | OK |

## 10. No fake metrics / no fake events (E10)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation / UPDATE Job-OutboundEmail / flip validationStatus | 0 (SELECT only) | OK |

RCA strictement read-only : SELECT DB, kubectl get/describe/logs/exec read-only, grep dist. Aucune ecriture.

## 11. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| build / push / deploy / kubectl apply / set / patch / edit / restart / scale / delete | OUI | 0 |
| mutation DB / UPDATE / INSERT / DELETE / migrate | OUI | SELECT only |
| trigger send-validation / retry / fake | OUI | 0 (aucun nouveau trigger ce RCA) |
| secrets / DATABASE_URL / DSN affiches | OUI | connectionString jamais imprime, emails masques (token seul) |
| PROD | OUI | non touche |
| credentials/ secrets/ | OUI | non touches |

## 12. Prochaine phase

GO SOURCE PATCH AMAZON OUTBOUND JOB OBSERVABILITY DEV PH-SAAS-T8.12AS.20.14U (instrumentation + durcissement, read-write source DEV) :
- jobsWorker : logs structures claim/skip/done (jobId, workerId, image/version, type, outcome) + heartbeat de poll + log explicite du resultat sendOutboundEmailById ;
- parseJobTypesEnv : valeur vide "" => claim NOTHING (et non claim-all) pour eviter qu un worker mal configure draine OUTBOUND_EMAIL_SEND ;
- garantir un consommateur unique deterministe (scope) ;
- (config, phase separee) upgrader amazon-orders/items-worker hors v1.0.40 et fixer leur JOB_TYPES.
Puis rebuild -> push -> apply -> re-trigger PH-20.14S-bis SOUS observabilite. Ne pas promouvoir PROD, ne pas retry outbound, ne pas flip DB tant que la cible DEV n est pas reellement VALIDATED via le flow trace.

Phrase cible : GO RCA AMAZON OUTBOUND SEND DEV PARTIAL PH-SAAS-T8.12AS.20.14S-RCA

STOP.
