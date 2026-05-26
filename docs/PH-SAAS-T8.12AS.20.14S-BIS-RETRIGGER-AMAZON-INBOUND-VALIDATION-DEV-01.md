# PH-SAAS-T8.12AS.20.14S-BIS-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14X / PH-20.14W / PH-20.14U / PH-20.14S-RCA / PH-20.14S
> Phase : PH-SAAS-T8.12AS.20.14S-BIS (RETRIGGER + VERIFY DEV sous observabilite v1.0.53)
> Environnement : DEV uniquement (PROD non touche)

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION DEV READY PH-SAAS-T8.12AS.20.14S-BIS

Re-trigger DEV legitime UNIQUE sur l adresse PENDING cmk5caxx700037d01tglfhe3v (tenant_test_dev, FR, token 812g37), API + jobs-worker DEV tous deux sur v1.0.53 (digest 5b893934) avec observabilite PH-20.14U. Le pipeline reel est PROUVE de bout en bout : send-validation HTTP 200 -> OutboundEmail cmpmh03bf cree -> Job OUTBOUND_EMAIL_SEND cmpmh03kt -> jobs-worker claim (worker-1) -> OUTBOUND_EMAIL_SEND start -> result outcome=SENT status=SENT -> done durationMs=1164 -> SMTP provider=SMTP sentAt 10:06:24 -> mail-core relay=webhook status=sent (token 812g37) -> webhook POST /api/v1/webhooks/inbound-email -> processValidationEmail "Recipient address marked as VALIDATED (resolved by exact emailAddress)" -> **cmk5caxx700037d01tglfhe3v PENDING -> VALIDATED** (lastInboundAt 10:06:25). Aucune zone grise : contrairement a PH-20.14S (Job DONE sans SMTP), l email a bien ete envoye et la chaine complete tracee. Le fix casse-marketplace 14O a fonctionne malgre marketplace="amazon" minuscule (resolution par emailAddress exact insensible). No unintended processing : +1 OutboundEmail SENT, +1 Job DONE, 0 AMAZON_POLL worker-1, autre adresse cmj9z9r1k non retouchee, 0 message marketplace, PROD intact v1.0.47, mail-core stable.

Prochaine phrase GO : GO READONLY PROMOTION DECISION AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14T (analyse read-only de promotion PROD ; aucune mutation PROD sans GO explicite).

## 2. Sources relues

PH-20.14X (apply v1.0.53), PH-20.14W (push image), PH-20.14U (observabilite + JOB_TYPES), PH-20.14S-RCA (gap observabilite), PH-20.14S (retrigger PARTIAL). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Runtime (E0)

| Service | image | digest | ready | restarts | env non-secret | verdict |
|---|---|---|---|---|---|---|
| API keybuzz-backend DEV | v1.0.53 | sha256:5b893934...886368 | true | 0 | KEYBUZZ_DEV_MODE=true | OK |
| jobs-worker DEV | v1.0.53 | sha256:5b893934...886368 | true | 0 | JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false | OK |
| PROD backend | v1.0.47-cross-env-guard-fix-prod | - | - | - | - | INTACT (read-only) |

Startup observabilite : "Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000". Heartbeat actif (polls=300+, claimed=0 avant trigger).

## 4. DB before / after (E1, E6)

| Address | validationStatus before | validationStatus after | marketplaceStatus | lastInboundAt before/after | verdict |
|---|---|---|---|---|---|
| cmk5caxx700037d01tglfhe3v (cible, amazon minuscule, FR, 812g37) | PENDING | **VALIDATED** | PENDING | null -> 2026-05-26T10:06:25.208Z | TRANSITION OK |
| cmj9z9r1k0005p0ek1er5obos (autre, AMAZON, FR, VALIDATED) | VALIDATED | VALIDATED | VALIDATED | 2026-05-25T22:34:01 (inchange) | NON RETOUCHEE |

Compteurs : Job OUTBOUND_EMAIL_SEND DONE 12 -> 13 / FAILED 16 -> 16 ; OutboundEmail SENT 12 -> 13 / FAILED 14 -> 14 / PENDING 1 -> 1 (le PENDING residuel = cmpma3nsd de 14S, distinct, non rejoue). AMAZON_POLL lockedBy worker-1 = 0 -> 0.

## 5. Trigger (E3)

| Item | Valeur |
|---|---|
| Endpoint | POST /api/v1/marketplaces/amazon/inbound-address/send-validation |
| Auth | DEV-mode legitime : header X-User-Email: dev@keybuzz.io (KEYBUZZ_DEV_MODE=true) ; pas de JWT forge |
| Body | {"country":"FR"} |
| Trigger UTC | 2026-05-26T10:06:21.646Z |
| HTTP status | 200 |
| Body reponse | {"ok":true,"message":"Validation email sent","note":"..."} |
| Nombre de triggers | 1 (unique) |

La route resout inboundConnection par tenant+amazon puis sendValidationEmail(connection.id, FR) -> cible le token 812g37 (cmk5caxx7).

## 6. Job / OutboundEmail logs (E4)

| Object | id | status before | status after | log evidence | verdict |
|---|---|---|---|---|---|
| OutboundEmail | cmpmh03bf000062010dejp2tx | (cree) | SENT (provider=SMTP, sentAt 10:06:24.914Z) | OUTBOUND_EMAIL_SEND result outcome=SENT status=SENT | OK |
| Job OUTBOUND_EMAIL_SEND | cmpmh03kt00016201mwu12i6q | (cree) | DONE (durationMs=1164) | claim/start/result/done tous traces (worker-1) | OK |

Logs jobs-worker (v1.0.53, observabilite PH-20.14U) :
- claim jobId=cmpmh03kt type=OUTBOUND_EMAIL_SEND tenant=tenant_test_dev worker=worker-1
- OUTBOUND_EMAIL_SEND start jobId=cmpmh03kt outboundEmailId=cmpmh03bf worker=worker-1
- OUTBOUND_EMAIL_SEND result jobId=cmpmh03kt id=cmpmh03bf outcome=SENT status=SENT
- done jobId=cmpmh03kt type=OUTBOUND_EMAIL_SEND outcome=DONE durationMs=1164

Le gap RCA 14S (Job DONE sans SMTP, non tracable) est leve : le path est entierement visible et l envoi reel confirme.

## 7. SMTP / mail-core / webhook (E5)

| Etape | evidence | verdict |
|---|---|---|
| Queue email API | "[Validation] Queued email to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io (job: cmpmh03kt)" | OK |
| SMTP envoi | OutboundEmail provider=SMTP, sentAt 2026-05-26T10:06:24.914Z | OK |
| mail-core relay | B2B8D3E606 from=validator@inbound.keybuzz.io to=amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io relay=webhook status=sent (delivered via webhook service) 10:06:26 | OK |
| webhook recu | POST /api/v1/webhooks/inbound-email (to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io) | OK |
| processValidationEmail | "[Validation] Recipient address marked as VALIDATED (resolved by exact emailAddress)" | OK |
| erreurs | 0 "Address not found" / 0 ambiguous / 0 token mismatch | OK |

DKIM signe (s=kbz1, d=inbound.keybuzz.io). Aucune lecture de contenu mailbox.

## 8. No unintended processing (E7)

| Signal | attendu | observe | verdict |
|---|---|---|---|
| OutboundEmail | +1 | SENT 12 -> 13 | OK |
| Job OUTBOUND_EMAIL_SEND | +1 | DONE 12 -> 13 | OK |
| AMAZON_POLL lockedBy worker-1 | 0 | 0 | OK |
| retry outbound | 0 | 0 | OK |
| message marketplace | 0 | 0 | OK |
| autre adresse cmj9z9r1k | inchangee | inchangee (lastInboundAt 25 mai) | OK |
| PROD | intact | v1.0.47 intact | OK |
| mail-core | stable | stable (autres flux sre@keybuzz.io non perturbes) | OK |

## 9. Interdits respectes

| Interdit | etat |
|---|---|
| build / docker push / deploy / kubectl apply / set / patch / edit / rollout restart | 0 |
| manifest GitOps | 0 |
| mutation DB / UPDATE / INSERT / DELETE manuel / flip validationStatus | 0 (transition via flow reel uniquement) |
| prisma migrate / db push | 0 |
| JWT forge / appel direct sendValidationEmail / fake webhook / fake event / fake email | 0 |
| trigger PROD / trigger multi-adresses | 0 (1 seul trigger, 1 seule adresse) |
| lecture/dump secret / contenu mailbox | 0 |
| workers Amazon v1.0.40 | non touches (read-only seulement) |

## 10. Decision (E8)

cmk5caxx700037d01tglfhe3v est passe PENDING -> VALIDATED via le flow reel complet. Verdict READY. Le pipeline de validation inbound Amazon fonctionne de bout en bout en DEV sur v1.0.53. Bloqueurs historiques tous leves : drift schema toAddress (14C-TER @map), resolution adresse exacte (14I), casse marketplace (14O), observabilite + JOB_TYPES (14U). NB : marketplaceStatus de la cible reste PENDING (champ distinct, mis a VALIDATED seulement par un message marketplace entrant reel, hors scope self-test ; la garde 14O empeche un self-test de blanket-update). La VALIDATION d adresse (validationStatus) est l objectif de cette phase et il est atteint.

## 11. Prochaine phase

GO READONLY PROMOTION DECISION AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14T : analyse read-only de la promotion PROD (PROD n a jamais eu de jobs-worker deploye ; verifier inboundConnection/adresses PENDING PROD, baseline images, plan de deploiement API+jobs-worker PROD, secrets SMTP PROD, rollback). AUCUNE mutation PROD sans GO explicite de Ludovic. Phase config separee : upgrader amazon-orders/items-worker hors v1.0.40 + fixer leur JOB_TYPES.

Phrase cible : GO RETRIGGER AMAZON INBOUND VALIDATION DEV READY PH-SAAS-T8.12AS.20.14S-BIS

STOP.
