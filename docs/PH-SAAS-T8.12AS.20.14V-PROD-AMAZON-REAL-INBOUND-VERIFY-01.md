# PH-SAAS-T8.12AS.20.14V-PROD-AMAZON-REAL-INBOUND-VERIFY-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14V-PROD-VERIFY / PH-20.14S-BIS / PH-20.14O / PH-20.14I
> Phase : PH-SAAS-T8.12AS.20.14V-PROD-AMAZON-REAL-INBOUND-VERIFY (READONLY VERIFY message Amazon reel PROD)
> Environnement : PROD (read-only strict ; aucune mutation ; aucun trigger ; aucun envoi)

## 1. Verdict

GO READONLY VERIFY REAL AMAZON INBOUND PROD PARTIAL PH-SAAS-T8.12AS.20.14V-PROD-AMAZON-REAL-INBOUND-VERIFY

Un vrai message client Amazon (tenant ecomlg-001 / eComLG, marketplace FR, order 403-2003407-5310706, article TP-Link Switch Ethernet Gigabit, montant 32,77 EUR, subject "Demande de renseignements de la part du client Amazon Ludovic") est arrive a 2026-05-26T12:04 UTC (14:04 Paris). Resultat :

- Routage : OK. mail-core-01 a relaye le message vers le webhook backend PROD (relay=webhook status=sent) pour l adresse inbound amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io.
- Ingestion Inbox : OK. ExternalMessage + conversation crees en DB produit (order_ref 403-2003407-5310706, receivedAt 12:04:04Z) ; le message est visible en UI.
- Validation adresse : NON. L adresse FR cmmsdn4if reste validationStatus=PENDING, marketplaceStatus=PENDING, pipelineStatus=PENDING, lastInboundAt=null (updatedAt fige a 2026-03-15). Un message Amazon reel ne valide PAS l adresse.

Root cause (deux bugs source confirmes, voir section 6) : la fonction updateMarketplaceStatusIfAmazon et la mise a jour lastInboundAt filtrent inboundAddress sur marketplace='AMAZON' (majuscules) alors que la colonne stocke 'amazon' (minuscules). Les updateMany matchent 0 ligne : le log "[AmazonDetection] Updating marketplaceStatus to VALIDATED" est emis mais rien n est persiste. Au niveau global PROD : 0 adresse avec marketplaceStatus VALIDATED, 0 avec pipelineStatus VALIDATED, 0 avec validationStatus VALIDATED.

Guard outbound : il lit validationStatus='VALIDATED' (filtre marketplace='amazon' en minuscules, donc correct). Tant que validationStatus=PENDING, le chemin de reponse inbound-email reste non valide. Le self-test de validation ("Renvoyer la validation", PH-20.14V-PROD-VERIFY) reste le seul moyen actuel de passer validationStatus a VALIDATED (chemin processValidationEmail, resolution par emailAddress exact, non affecte par le bug de casse).

Aucune mutation, aucun trigger, aucun envoi marketplace, aucune reponse au client. 0 outbound_deliveries sur les 6 dernieres heures.

## 2. Runtime PROD (E0)

| Service | namespace | image | digest | ready | restarts |
|---|---|---|---|---|---|
| API keybuzz-backend | keybuzz-backend-prod | v1.0.53-amazon-validation-pipeline-prod | sha256:18f54575...886368 | 1/1 | 0 |
| jobs-worker | keybuzz-backend-prod | v1.0.53-amazon-validation-pipeline-prod | sha256:18f54575...886368 | 1/1 | 0 |

Bastion install-v3 (46.62.171.61), date bastion 2026-05-26 ~12:11 UTC. keybuzz-backend HEAD 1179c15 branch main.

## 3. Routage mail-core vers webhook (E1)

journalctl mail-core-01, fenetre 2026-05-26 11:30 a 12:30 UTC, entrees relay=webhook status=sent :

| Heure UTC | queue id | destinataire | token |
|---|---|---|---|
| 11:57:32 | B17A63E610 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | 4xfub8 |
| 12:00:22 | A514E3E606 | amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io | 3jcpvk |
| 12:04:06 | C2BC33E610 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | 4xfub8 |
| 12:04:06 | 7A1AF3E642 | amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io | 3jcpvk |

Le message client a 12:04:06 UTC (= 14:04 Paris) est bien relaye vers le webhook pour le token 4xfub8. Un second token 3jcpvk recoit en parallele (voir section 7).

## 4. Logs backend PROD (E2)

POST /api/v1/webhooks/inbound-email recus a 12:04 UTC depuis mail-core (host backend.keybuzz.io) pour les deux tokens. Le log "[AmazonDetection] Updating marketplaceStatus to VALIDATED for ecomlg-001/amazon/FR" est emis a chaque message Amazon detecte (4xfub8 et 3jcpvk). Le body parse contient "# 403-2003407-5310706" et "TP-Link Switch Ethernet Gigabit". Aucun log "marked as VALIDATED" cote validationStatus, aucun "Address not found", aucun "Ambiguous", aucun "Token mismatch".

Important : le log [AmazonDetection] est emis AVANT l updateMany et ne reflete pas le resultat reel de la mise a jour (voir section 6).

## 5. Message ingere en DB produit (E3)

ExternalMessage et conversation sont stockes dans la DB PRODUIT (keybuzz), pas dans keybuzz_backend (la table ExternalMessage n existe pas cote backend ; migration PH-TD-05). C est pourquoi le message est visible en UI.

| Objet | evidence | verdict |
|---|---|---|
| ExternalMessage | subject "Demande de renseignements de la part du client Amazon Ludovic", receivedAt 2026-05-26T12:04:04Z, type AMAZON | cree |
| ExternalMessage order hit | 2 lignes referencant 403-2003407-5310706 | cree (doublon) |
| conversation | id cmmpml7hy..., channel amazon, order_ref 403-2003407-5310706, created 12:04:04Z | cree |
| conversation order hit | 2 conversations pour le meme order | doublon |

PII client masquee. Seules les adresses inbound infra (4xfub8, 3jcpvk @inbound.keybuzz.io) et l email owner (ludo.gonthier@gmail.com) sont affichees, conformement au scope.

## 6. Etat adresse inbound + root cause (E4)

| Address id | pays | token | validationStatus | marketplaceStatus | pipelineStatus | lastInboundAt | updatedAt |
|---|---|---|---|---|---|---|---|
| cmmsdn4if0003at01cwu3p6if | FR | 4xfub8 | PENDING | PENDING | PENDING | null | 2026-03-15T23:19:48Z |
| cmnvwpyk500036i01rm59ill8 | BE | ub0m1q | PENDING | PENDING | PENDING | null | 2026-04-12 |
| cmnvwpykn00056i01c3biprug | ES | zul3wn | PENDING | PENDING | PENDING | null | 2026-04-12 |
| cmnvwpyl000076i01ceti7ggf | IT | hz4alx | PENDING | PENDING | PENDING | null | 2026-04-12 |
| cmnvwsiz2000b6i01k1cwyqqe | PL | 36ngpp | PENDING | PENDING | PENDING | null | 2026-04-12 |

5 adresses ecomlg-001, toutes PENDING. L adresse FR cible (4xfub8) n a PAS bouge malgre le message reel : updatedAt reste 2026-03-15, lastInboundAt reste null.

Root cause (source keybuzz-backend, commit 1179c15) :

1. src/modules/inbound/inbound.service.ts, updateMarketplaceStatusIfAmazon : updateMany avec where { marketplace: marketplace.toUpperCase() } = 'AMAZON' et data { marketplaceStatus:'VALIDATED', pipelineStatus:'VALIDATED' }. La colonne inboundAddress.marketplace stocke 'amazon' (minuscules). Preuve : count(marketplace='AMAZON', country='FR', tenant ecomlg-001) = 0 ; count(marketplace='amazon', ...) = 1. L updateMany matche 0 ligne.
2. src/modules/webhooks/inboundEmailWebhook.routes.ts : updateMany lastInboundAt avec where { marketplace: MarketplaceType.AMAZON } (valeur enum 'AMAZON'). Meme mismatch : lastInboundAt n est jamais mis a jour (confirme null).

Preuve globale PROD : DISTINCT marketplace = ['amazon'] uniquement ; count(marketplaceStatus='VALIDATED')=0 ; count(pipelineStatus='VALIDATED')=0 ; count(validationStatus='VALIDATED')=0. Aucune adresse jamais validee par le chemin message reel.

Le chemin self-test (processValidationEmail) n est PAS affecte : il resout l adresse par emailAddress exact (decideValidationAddress) et met a jour par id (validationStatus + pipelineStatus), sans filtre marketplace. C est lui qui a valide cmk5caxx7 en DEV (PH-20.14S-BIS).

## 7. Second token 3jcpvk (reconciliation)

mail-core relaye aussi vers amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io, mais le token 3jcpvk n existe dans AUCUNE des 5 adresses inbound ecomlg-001 (seul 4xfub8 est l adresse FR active). Le webhook resout tenantId + marketplace + country a partir du localpart de l adresse (parseInboundAddress), pas a partir d une correspondance token en base ; il accepte donc 3jcpvk. Consequence : le meme message Amazon arrive via deux adresses (4xfub8 et 3jcpvk), genere deux ExternalMessage (externalId distincts) et deux conversations Inbox = doublon. Origine probable de 3jcpvk : une adresse inbound anterieure communiquee a Amazon (avant regeneration du token FR). A investiguer en phase dediee (nettoyage doublon + archivage adresse obsolete).

## 8. Guard outbound + outbound_deliveries (E5)

Le guard de reponse Amazon lit validationStatus='VALIDATED' (filtre marketplace='amazon' en minuscules, donc correct) :
- keybuzz-api src/modules/messages/routes.ts L488-500 : guard Amazon non-order ; sinon code INBOUND_NOT_VALIDATED.
- keybuzz-api src/workers/outboundWorker.ts L256/L335 : meme check ; sinon throw "Amazon inbound address not validated - configure and validate in Settings > Channels".

marketplaceStatus PENDING ne bloque pas (le guard ne lit pas ce champ). C est validationStatus=PENDING qui empeche le chemin de reponse inbound-email.

outbound_deliveries ecomlg-001 (DB produit) :

| canal | provider | status | n | dernier |
|---|---|---|---|---|
| amazon | spapi | delivered | 235 | 2026-05-22 |
| amazon | spapi | failed | 5 | 2026-05-15 |
| email | SMTP | delivered | 6 | 2026-02-12 |
| email | SMTP | failed | 1 | 2026-02-11 |

Failed sans retry (E5) : 5 amazon (2026-05-15, attempt_count=5, next_retry_at=null, "SMTP failed for Amazon address: Connection timeout" = fenetre incident mail KEY-323) + 1 email (2026-02-11, "Unknown provider: SMTP"). Aucun failed recent. 0 outbound_deliveries sur les 6 dernieres heures.

Observation a flaguer : 235 envois amazon delivered (provider spapi, dernier 2026-05-22) existent alors que validationStatus=PENDING. Cela indique que le canal SP-API Messaging (provider=spapi) n est pas gate par la validationStatus de l adresse inbound-email ; le guard validationStatus concerne le chemin de reponse via relais email. A clarifier dans la phase de design outbound.

## 9. No unintended processing (E6)

| Signal | etat | verdict |
|---|---|---|
| outbound_deliveries ecomlg-001 sur 6h | 0 | aucun envoi declenche |
| reponse au client Amazon | aucune | conforme read-only |
| mutation DB | aucune | conforme |
| flip validationStatus / marketplaceStatus | aucun | conforme |
| trigger send-validation | aucun | conforme |
| fake event / fake message / fake job | aucun | conforme |
| API / jobs-worker restarts | 0 / 0 | stable |

## 10. Decision (E7)

PARTIAL. Routage inbound OK ; ingestion Inbox OK (message visible) ; mais la validation de l adresse ne se fait PAS sur un message Amazon reel. Deux causes :
1. Par design, un message Amazon reel cible marketplaceStatus/pipelineStatus, pas validationStatus (que lit le guard). Seul le self-test "Renvoyer la validation" met validationStatus a VALIDATED.
2. De plus, le chemin marketplaceStatus/lastInboundAt est casse (bug de casse 'AMAZON' vs 'amazon') et ne persiste rien.

Conclusion : pour debloquer la reponse inbound-email Amazon FR ecomlg-001 aujourd hui, l action UI "Renvoyer la validation" (PH-20.14V-PROD-VERIFY) reste necessaire. Pour que la reception d un vrai message valide l adresse de bout en bout (comportement attendu produit), un patch source cible est requis.

## 11. Prochaine phase (proposition, GO requis)

Aucune action executee ici. Propositions, par priorite :

1. Court terme (deblocage) : action UI Ludovic "Renvoyer la validation" Amazon FR ecomlg-001, puis re-run VERIFY pour confirmer validationStatus PENDING vers VALIDATED via le self-test (chemin deja prouve en DEV).
2. Patch source P0 (KEY-323) : corriger le filtre de casse marketplace dans updateMarketplaceStatusIfAmazon et dans l updateMany lastInboundAt (utiliser 'amazon' minuscules, coherent avec la colonne et avec le guard). Decider si la reception d un message Amazon reel doit aussi mettre validationStatus a VALIDATED (alignement du chemin reel sur l attendu produit). DEV avant PROD, build-from-git, tag immuable.
3. Hygiene : reconcilier le doublon de token (4xfub8 vs 3jcpvk), archiver l adresse obsolete, dedupliquer ExternalMessage/conversation. Upgrade amazon-orders/items-worker hors v1.0.40 (hors scope KEY-323).

Phrase cible : GO READONLY VERIFY REAL AMAZON INBOUND PROD PARTIAL PH-SAAS-T8.12AS.20.14V-PROD-AMAZON-REAL-INBOUND-VERIFY

STOP.
