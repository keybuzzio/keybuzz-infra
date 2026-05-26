# PH-SAAS-T8.12AS.20.14S-RETRIGGER-AMAZON-INBOUND-VALIDATION-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14R / PH-20.14O / PH-20.14M
> Phase : PH-SAAS-T8.12AS.20.14S (RETRIGGER + VERIFY DEV)
> Environnement : DEV uniquement (PROD non touche)

## 1. Verdict

GO RETRIGGER AMAZON INBOUND VALIDATION DEV PARTIAL PH-SAAS-T8.12AS.20.14S

Trigger DEV legitime unique effectue (HTTP 200) sur l adresse PENDING cible. API a cree l OutboundEmail et enqueue le Job OUTBOUND_EMAIL_SEND. MAIS l adresse cible n est PAS passee VALIDATED. NOUVEAU mode d echec distinct de PH-20.14M : l email self-test n a jamais ete ENVOYE. L OutboundEmail cmpma3nsd reste PENDING (provider=null, sentAt=null), aucun SMTP n est parti (mail-core sans entree a 06:53), donc aucun webhook inbound, aucun processValidationEmail, aucune transition. Le Job cmpma3o1x est marque DONE en 320 ms sans envoi correspondant, alors que le jobs-worker (seul consommateur OUTBOUND_EMAIL_SEND, vivant mais silencieux depuis son demarrage) n affiche aucune activite de claim/traitement. Le correctif casse-marketplace (PH-20.14O) n a donc PAS pu etre exerce au niveau du webhook ce run. Aucun flip DB, aucun retry outbound, l autre adresse VALIDATED cmj9z9r1k non re-touchee, AMAZON_POLL lockedBy=worker-1 = 0, PROD intact.

NE PAS promouvoir en PROD. Prochaine etape : RCA read-only sur la jambe d envoi OutboundEmail / consommation jobs-worker en v1.0.52 (pourquoi le Job passe DONE sans envoi et sans log worker, OutboundEmail bloquee PENDING provider=null).

## 2. Sources relues

PH-20.14R (apply v1.0.52), PH-20.14O (source patch casse marketplace), PH-20.14M (retrigger PARTIAL casse). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight runtime (E0)

| Service | namespace | image runtime | digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend (API) | keybuzz-backend-dev | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.52 | sha256:4e60d0e8...f92676 | true | 0 | OK |
| keybuzz-backend (API) PROD | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | - | - | - | INTACT |

jobs-worker env : JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP_HOST=49.13.35.167, SMTP_PORT=25, SMTP_SECURE=false. API KEYBUZZ_DEV_MODE=true. infra HEAD 16a2959, backend HEAD 8f7122b.

## 4. Adresse cible before/after (E1 + E6)

Note importante : les ids fournis dans le prompt (cmk5caxx7 / cmj9z9r1k) etaient des PREFIXES tronques. Les adresses existent avec les ids COMPLETS ci-dessous, dans la DB keybuzz_backend (et non product DB keybuzz : c est keybuzz_backend que processValidationEmail lit/ecrit ; compteurs amazon 39 PENDING / 4 VALIDATED = ceux de PH-20.14M).

| Address id | tenant | country | marketplace | token | status before | status after | lastInboundAt | updatedAt | verdict |
|---|---|---|---|---|---|---|---|---|---|
| cmk5caxx700037d01tglfhe3v (cible) | tenant_test_dev | FR | amazon (minuscule) | 812g37 | PENDING | PENDING | null -> null | 2026-01-08 -> 2026-01-08 (inchange) | NON VALIDE |
| cmj9z9r1k0005p0ek1er5obos (autre FR) | tenant_test_dev | FR | AMAZON (majuscule) | 6v8gqm | VALIDATED | VALIDATED | 2026-05-25T22:34 (inchange) | inchange | OK (non re-touchee) |

## 5. Snapshot BEFORE (E2)

| Signal | before | verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND DONE/FAILED | 11 / 16 | OK |
| OutboundEmail SENT/FAILED | 12 / 14 | OK |
| AMAZON_POLL lockedBy='worker-1' (exact) | 0 | OK |
| mail-core queue / storm 454-421 (10 min) | 1 req / 0 | STABLE |

## 6. Trigger (E3)

| Trigger | endpoint | auth mode | cible | HTTP | verdict |
|---|---|---|---|---|---|
| unique | POST /api/v1/marketplaces/amazon/inbound-address/send-validation (curl interne pod -> 127.0.0.1:4000) | DEV-mode X-User-Email: dev@keybuzz.io (KEYBUZZ_DEV_MODE=true) | country FR (resout token 812g37) | 200 | OK |

Body : {"ok":true,"message":"Validation email sent"}. Aucun JWT forge, aucun appel direct service, une seule requete. API log : "Enqueued job cmpma3o1x (OUTBOUND_EMAIL_SEND)" + "Queued email to amazon.tenant_test_dev.fr.812g37@inbound.keybuzz.io".

## 7. OutboundEmail / Job (E4)

| Object | id | status before | status after | worker | verdict |
|---|---|---|---|---|---|
| OutboundEmail | cmpma3nsd | (cree) | PENDING (provider=null, sentAt=null) | aucun | NON ENVOYE |
| Job OUTBOUND_EMAIL_SEND | cmpma3o1x | (enqueue PENDING) | DONE en 320 ms (06:53:11.685 -> 06:53:12.005, lockedBy=null) | aucun log worker | ANORMAL (DONE sans envoi) |
| AMAZON_POLL lockedBy=worker-1 | - | 0 | 0 | - | OK |

Forensic : grep des ids cmpma3o1x / cmpma3nsd sur TOUS les pods du namespace -> 2 hits dans le pod API (lignes enqueue + queued uniquement), 0 hit dans jobs-worker et dans tous les autres workers. jobs-worker (PID 1 node dist/workers/jobsWorker.js, vivant, restarts=0, aucune erreur) n a logge que "Starting worker worker-1 types=OUTBOUND_EMAIL_SEND" depuis son demarrage (06:43) : aucune ligne Claimed/Processing/sent/done. Le Job est donc passe DONE sans claim worker visible et sans envoi SMTP.

## 8. SMTP / mail-core / webhook (E5)

| Maillon | preuve | resultat | verdict |
|---|---|---|---|
| OutboundEmail -> SMTP | OutboundEmail PENDING, provider=null | aucun envoi | ABSENT |
| mail-core self-test (token 812g37) | mail.log : dernieres entrees 812g37 = 2026-05-25 21:32 et 22:34 (14G-TER / 14M) ; AUCUNE a 2026-05-26 06:53 | aucun self-test ce run | ABSENT |
| relay=webhook | non observe ce run | - | ABSENT |
| webhook /inbound-email + processValidationEmail | non atteint (aucun email entrant) | - | ABSENT |
| mail-core stabilite | queue stable, 0 storm | - | STABLE |

Le correctif PH-20.14O (resolution emailAddress case-insensitive) n a pas pu etre teste au webhook : l email self-test n a jamais ete dispatche.

## 9. No unintended processing (E7)

| Signal | before | after | attendu | verdict |
|---|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND DONE | 11 | 12 | +1 si trigger | OK (mais DONE sans envoi) |
| OutboundEmail total | SENT 12 / FAILED 14 | SENT 12 / FAILED 14 / PENDING 1 | +1 cree | OK cree, NON envoye |
| AMAZON_POLL lockedBy=worker-1 (exact) | 0 | 0 | 0 | OK |
| outbound_deliveries retry | - | aucun | 0 | OK |
| message marketplace | - | aucun | 0 | OK |
| jobs-worker restarts / API restarts | 0 / 0 | 0 / 0 | 0 | OK |
| PROD | intact | intact | intact | OK |
| mail-core | stable | stable | stable | OK |
| cmj9z9r1k (autre VALIDATED) | VALIDATED 22:34 | VALIDATED 22:34 (inchange) | non touchee | OK (garde self-test OK) |

## 10. AI feature parity / anti-regression (E8)

| Feature | Contrat | Etat | Verdict |
|---|---|---|---|
| Guard outbound validationStatus=VALIDATED | non bypasse | intact | OK |
| From Amazon | amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | intact | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | protege AMAZON_POLL | 0 AMAZON_POLL worker-1 | OK |
| updateMarketplaceStatusIfAmazon guard self-test (PH-20.14O) | ne re-touche pas une autre adresse | cmj9z9r1k inchangee | OK |
| retry outbound / fake webhook / fake email | 0 | aucun | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | non touche | OK |

## 11. No fake metrics / no fake events (E9)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation manuelle / validationStatus flip | 0 | OK |

OutboundEmail + Job reels (crees par le flow). Aucun forcage. cmk5caxx7 reflete l etat reel (NON valide). cmj9z9r1k inchangee.

## 12. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| build / docker push / deploy / kubectl apply / set / patch / edit | OUI | 0 |
| mutation DB / UPDATE inbound_addresses / flip PENDING->VALIDATED | OUI | SELECT only ; cible reste PENDING |
| retry outbound_deliveries / message marketplace | OUI | 0 |
| fake webhook / event / OutboundEmail / Job | OUI | 0 |
| JWT forge / secret / appel direct sendValidationEmail | OUI | route DEV-mode legitime uniquement |
| trigger plusieurs adresses / PROD | OUI | 1 trigger FR, DEV uniquement |
| dump secrets / DSN | OUI | connectionString non imprime, emails masques (token seul) |

## 13. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Trigger | N/A (email legitime, mais ici non envoye) | aucun |
| DB | aucun flip manuel a annuler | aucun |
| Runtime v1.0.52 | si regression confirmee : rollback GitOps DEV vers v1.0.51 en phase dediee (manifest commit + apply, jamais kubectl set image) | retour v1.0.51 |

## 14. Prochaine phase

GO RCA AMAZON OUTBOUND SEND DEV PH-SAAS-T8.12AS.20.14S-RCA (read-only) : diagnostiquer pourquoi en v1.0.52 le Job OUTBOUND_EMAIL_SEND passe DONE sans envoi (OutboundEmail bloquee PENDING provider=null, sentAt=null) et pourquoi jobs-worker (vivant) ne loggue aucun claim/traitement. Verifier : qui marque le Job DONE (claim worker reel vs autre chemin), si sendOutboundEmailById skip/echoue silencieusement, etat de la boucle de poll du worker, comparaison comportement v1.0.51 (14M, envoi OK) vs v1.0.52. Ne PAS flip DB, ne PAS retry outbound, ne PAS promouvoir PROD tant que la cible DEV n est pas reellement VALIDATED via le flow.

Phrase cible : GO RETRIGGER AMAZON INBOUND VALIDATION DEV PARTIAL PH-SAAS-T8.12AS.20.14S

STOP.
