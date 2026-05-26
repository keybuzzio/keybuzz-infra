# PH-SAAS-T8.12AS.20.14W-SOURCE-PATCH-AMAZON-REAL-INBOUND-VALIDATES-ADDRESS-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14V-PROD-AMAZON-REAL-INBOUND-VERIFY
> Phase : PH-SAAS-T8.12AS.20.14W (SOURCE PATCH ONLY, gate push)
> Environnement : DEV source first (aucun build, aucun deploy, aucune mutation DB)

## 1. Verdict

GO SOURCE PATCH AMAZON REAL INBOUND VALIDATES ADDRESS READY PH-SAAS-T8.12AS.20.14W

Patch source local pret. Un vrai message Amazon recu sur une adresse inbound CONNUE valide desormais cette adresse (validationStatus=VALIDATED). Le bug de casse marketplace ('AMAZON' filtre vs 'amazon' stocke) est elimine : la resolution se fait par emailAddress exact (case-insensitive), comme le self-test. tsc OK, ph2014w 10/10, non-regression 9/9 + 11/11 + 17/17 + 15/15 + 16/16. Commits locaux backend + infra. Aucun push, aucun build, aucun deploy, aucune mutation DB. STOP au gate push.

## 2. RCA (rappel PH-20.14V)

| Element | constat |
|---|---|
| Vrai message Amazon ecomlg-001 FR (order 403-2003407-5310706, 2026-05-26 12:04 UTC) | route mail-core puis webhook PROD puis ExternalMessage/conversation Inbox : OK |
| Adresse FR cmmsdn4if (token 4xfub8) | restait PENDING (validationStatus/marketplaceStatus/pipelineStatus), lastInboundAt null |
| Cause 1 | updateMarketplaceStatusIfAmazon : updateMany WHERE marketplace=marketplace.toUpperCase()='AMAZON' ; colonne stocke 'amazon' minuscule -> 0 ligne ; ne set jamais validationStatus |
| Cause 2 | webhook updateMany lastInboundAt : WHERE marketplace enum AMAZON -> 0 ligne -> lastInboundAt jamais MAJ |
| Effet | log "[AmazonDetection] Updating marketplaceStatus to VALIDATED" emis mais rien persiste ; global PROD 0 VALIDATED ; guard outbound (lit validationStatus) reste bloquant |

## 3. Fichiers modifies

| Fichier | changement | risque | verdict |
|---|---|---|---|
| backend src/modules/inbound/inbound.service.ts | + helper pur buildRealInboundValidationData() ; updateMarketplaceStatusIfAmazon recoit `to`, resout l'adresse EXACTE par emailAddress insensitive (decideValidationAddress) puis update validationStatus/marketplaceStatus/pipelineStatus=VALIDATED + lastError=null ; warn si non resolu ; suppression de l'updateMany casse-dependant | faible (reutilise le chemin 14O deja prouve ; resolution plus stricte que l'ancien blanket updateMany) | OK |
| backend src/modules/webhooks/inboundEmailWebhook.routes.ts | call updateMarketplaceStatusIfAmazon recoit `to: payload.to` ; lastInboundAt updateMany resolu par emailAddress insensitive (au lieu du filtre enum marketplace) + warn si count=0 ; import MarketplaceType retire (devenu inutilise ; le cast SQL "MarketplaceType" reste litteral) | faible | OK |
| backend tests/ph2014w-real-inbound-validation.test.ts | nouveau test standalone (10 assertions) | nul | OK |

Champs mis a jour et pourquoi (decision produit OUI documentee) :
- validationStatus=VALIDATED : champ LU par le guard outbound (keybuzz-api messages/routes.ts + outboundWorker.ts). Un vrai message Amazon recu sur l'adresse prouve sa validite -> deblocage des reponses.
- marketplaceStatus=VALIDATED + pipelineStatus=VALIDATED : memes etats de bout-en-bout, coherence UI/pipeline.
- lastError=null : reset d'une eventuelle erreur anterieure.
- lastInboundAt + lastInboundMessageId : bookkeeping de reception, gere par le webhook pour TOUT inbound (case-fixe). Separation claire validation (service) vs bookkeeping (webhook).

## 4. Comportement avant/apres

| Scenario | avant | apres |
|---|---|---|
| Vrai message Amazon sur adresse connue (token 4xfub8) | log VALIDATED mais 0 ligne MAJ ; adresse reste PENDING | adresse resolue par emailAddress -> validationStatus/marketplaceStatus/pipelineStatus VALIDATED + lastInboundAt MAJ |
| Marketplace stocke 'amazon' minuscule | exclu par le filtre toUpperCase -> jamais valide | resolu (casse non pertinente) |
| Marketplace stocke 'AMAZON' majuscule | aurait matche (mais data jamais en majuscule en prod) | resolu (casse non pertinente) |
| Message vers token inconnu (ex 3jcpvk, hors DB) | blanket updateMany aurait pu valider une AUTRE adresse du tenant | aucune validation (Address not found) ; pas de validation de la mauvaise adresse |
| Self-test de validation (processValidationEmail) | OK | INCHANGE (skip guard isValidationEmail + chemin emailAddress exact intacts) |
| lastInboundAt bookkeeping | jamais MAJ (filtre enum casse) | MAJ sur l'adresse exacte ; warn si 0 |

## 5. Tests

| Test | attendu | resultat |
|---|---|---|
| ph2014w (nouveau, 10 assertions) | real inbound valide adresse (casse 'amazon' et 'AMAZON') ; recipient insensible casse ; fields VALIDATED + lastError null ; ambiguous/token mismatch/not found refuses | 10/10 |
| ph2014o | resolution casse marketplace (self-test) | 9/9 |
| ph2014i | resolution adresse exacte | 11/11 |
| ph2014u | JOB_TYPES hardening | 17/17 |
| ph2014c | sendOutboundEmailById | 15/15 |
| ph2014cbis | jobscope worker | 16/16 |
| prisma generate | DMMF genere | OK |
| tsc --noEmit | 0 erreur | OK (EXIT 0) |

## 6. No side-effect

| Signal | etat |
|---|---|
| docker build | aucun (pas de v1.0.54 ; v1.0.53 = builds anterieurs) |
| docker push | aucun |
| kubectl apply/patch/set | aucun (E0/E5 read-only get uniquement) |
| manifest GitOps | infra clean (aucun manifest touche) |
| DB mutation (UPDATE/INSERT/DELETE) | aucune |
| prisma migrate / db push | aucun |
| trigger send-validation / email reel | aucun |
| runtime API/jobs-worker PROD | inchange v1.0.53-amazon-validation-pipeline-prod |
| runtime DEV | inchange v1.0.53-amazon-validation-pipeline-dev |
| backend git scope | 2 fichiers source + 1 test (+ .bak cruft pre-existant ignore) |

## 7. AI feature parity / anti-regression

| Garantie | etat |
|---|---|
| Guard outbound validationStatus | INTACT (lit toujours validationStatus='VALIDATED', marketplace='amazon' minuscule) ; le patch alimente ce champ, ne le contourne pas |
| Contrat "From Amazon" (isAmazonForwardedEmail) | INTACT (detection inchangee) |
| Self-test processValidationEmail | INTACT (resolution emailAddress exact + token + ambiguite ; tests 14I/14O verts) |
| Real inbound valide l'adresse | NOUVEAU comportement attendu (decision produit OUI) |
| jobs-worker scope (JOB_TYPES=OUTBOUND_EMAIL_SEND) | INCHANGE (hors patch) |
| retry outbound | aucun |
| fake webhook / fake event / fake job / fake email | aucun |
| dedup token 4xfub8/3jcpvk + ExternalMessage/conversation | HORS SCOPE (non touche ; la resolution emailAddress evite simplement de valider une mauvaise adresse) |
| PH-20.11C / PH-20.12B / PH-20.13B | preserves (aucun fichier de ces domaines touche) |

## 8. Rollback

| Niveau | action |
|---|---|
| Source backend | git revert d27f4a5 (commit local, non pousse) ; ou drop du commit local avant push |
| Runtime | aucun (rien deploye) ; PROD/DEV restent v1.0.53 inchanges |
| Infra | git revert du commit docs local (non pousse) |

## 9. Etat git (gate push)

| Repo | commit local | origin | etat |
|---|---|---|---|
| keybuzz-backend | d27f4a5 (fix amazon real inbound validates address) | 1179c15 (inchange) | LOCAL, non pousse |
| keybuzz-infra | (ce rapport, commit local) | 8a1e1b8 (inchange) | LOCAL, non pousse |

## 10. Prochaine phase

GATE PUSH. En attente GO explicite Ludovic :
GO PUSH SOURCE PATCH AMAZON REAL INBOUND VALIDATES ADDRESS PH-SAAS-T8.12AS.20.14W

Apres push : build image DEV v1.0.54-amazon-validation-pipeline-dev from-git (commit pousse), push GHCR, apply DEV GitOps, re-trigger DEV pour prouver qu'un vrai message Amazon (ou self-test) passe l'adresse PENDING a VALIDATED via le chemin real-inbound, puis promotion PROD (image -prod, GitOps) sur GO. Cote PROD, l'adresse FR ecomlg-001 cmmsdn4if pourra etre validee soit par le self-test "Renvoyer la validation", soit par le prochain vrai message Amazon (une fois v1.0.54 deploye). Hygiene separee : reconcilier le doublon de token 4xfub8/3jcpvk + dedup ExternalMessage/conversation ; upgrade amazon-orders/items-worker hors v1.0.40.

Phrase cible : GO SOURCE PATCH AMAZON REAL INBOUND VALIDATES ADDRESS READY PH-SAAS-T8.12AS.20.14W

STOP.
