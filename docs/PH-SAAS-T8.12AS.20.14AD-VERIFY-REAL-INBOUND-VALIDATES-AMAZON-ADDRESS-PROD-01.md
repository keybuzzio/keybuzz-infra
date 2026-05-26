# PH-SAAS-T8.12AS.20.14AD-VERIFY-REAL-INBOUND-VALIDATES-AMAZON-ADDRESS-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14AC (apply PROD) / PH-20.14W (source patch) / PH-20.14Z2 (verify DEV)
> Phase : PH-SAAS-T8.12AS.20.14AD (READONLY VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS PROD)
> Environnement : PROD (lecture seule ; aucune mutation, aucun trigger, aucun envoi)

## 1. Verdict

GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS PROD READY PH-SAAS-T8.12AS.20.14AD

Un vrai message Amazon Seller Central entrant a valide en PROD l'adresse inbound ecomlg-001 FR (cmmsdn4if0003at01cwu3p6if / token 4xfub8) via le chemin real-inbound PH-20.14W actif depuis PH-20.14AC. validationStatus + pipelineStatus + marketplaceStatus = VALIDATED, lastInboundAt = 2026-05-26T16:32:38Z, lastError = null. Le guard outbound est desormais ouvert pour ecomlg-001 FR. Aucun traitement parasite : Job / OutboundEmail / MarketplaceOutboundMessage restent vides, aucun envoi, aucun retry, jobs-worker restarts=0. Phase entierement en lecture seule.

## 2. Runtime PROD (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 17:12.

| Service | image | digest | ready | restarts | verdict |
|---|---|---|---|---|---|
| keybuzz-backend (pod hqvnn) | v1.0.54-amazon-validation-pipeline-prod | sha256:060abd98...bda3 | true | 0 | OK |
| jobs-worker (pod 2vj8x) | v1.0.54-amazon-validation-pipeline-prod | sha256:060abd98...bda3 | true | 0 | OK |

Runtime conforme a PH-20.14AC (meme digest, aucun restart depuis le deploy).

## 3. DB courant (E1/E4)

SELECT / count / groupBy uniquement (script read-only execute dans le pod backend, supprime apres lecture).

| Objet | etat | lastInboundAt | verdict |
|---|---|---|---|
| cmmsdn4if (ecomlg-001 / amazon / FR / 4xfub8) validationStatus | VALIDATED | 2026-05-26T16:32:38.449Z | VALIDATED |
| cmmsdn4if pipelineStatus | VALIDATED | - | VALIDATED |
| cmmsdn4if marketplaceStatus | VALIDATED | - | VALIDATED |
| cmmsdn4if lastInboundMessageId | 0102019e6521846c-...amazonses.com-prod | - | real Amazon SES |
| cmmsdn4if lastError | null | - | OK |
| InboundAddress global validationStatus | VALIDATED 2 / PENDING 9 | - | seules les adresses ayant recu un vrai inbound sont validees |
| Adresses avec lastInboundAt non-null | cmmsdn4if (ecomlg-001 FR) + cmotxn8bs (ecomlg-motxke32 FR) | 16:32:38Z | 2 tenants, real inbound |

Rappel etat avant PH-20.14AC : 11 PENDING / 0 VALIDATED, cmmsdn4if lastInboundAt null. Le delta est exactement l'effet du chemin real-inbound, sans aucune ecriture manuelle.

## 4. Logs ingress + validation (E2/E3)

Preuve d'arrivee : POST /api/v1/webhooks/inbound-email recu par le backend PROD avec le messageId AmazonSES, ce qui correspond au dual-post mail-core. SSH imbrique mail-core non utilise (phase read-only ; cle non disponible pour ce chemin). L'ingress backend constitue la preuve.

| Pattern log backend PROD | resultat | verdict |
|---|---|---|
| Webhook Received inbound email to amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | present (req-h0) | OK |
| AmazonDetection Checking from=Communications Amazon Seller Central (ne pas repondre) messageId 0102019e6521846c...amazonses | present | vrai message Amazon |
| AmazonDetection Real Amazon message detected for ecomlg-001/amazon/FR; resolving inbound address by emailAddress | present | chemin 14W |
| AmazonDetection Inbound address cmmsdn4if0003at01cwu3p6if marked VALIDATED from real Amazon message (ecomlg-001/amazon/FR) | present | VALIDATION |
| AmazonDetection ecomlg-001/amazon/FR token 3jcpvk Address not found - no validation | present | aucun faux positif (doublon 3jcpvk non resolu) |
| Address not found / ambiguous / token mismatch / update count warning pour 4xfub8 | absent | resolution exacte par emailAddress |

Note : une premiere validation de cmmsdn4if a egalement eu lieu plus tot (~16:12Z, messageId 0102019e650f5f76) ; l'etat courant reflete le dernier inbound 16:32Z.

## 5. Validation state (E4)

| Adresse | avant PH-20.14AC | courant | verdict |
|---|---|---|---|
| cmmsdn4if ecomlg-001 FR (4xfub8) | PENDING / PENDING / PENDING | VALIDATED / VALIDATED / VALIDATED | VALIDE via real inbound |
| cmotxn8bs ecomlg-motxke32 FR | PENDING | VALIDATED (real inbound 16:32Z) | VALIDE (autre tenant, real inbound legitime) |
| 9 autres adresses PENDING | PENDING | PENDING (inchangees) | aucun effet de bord |

Aucune adresse n'a ete validee sans un vrai inbound correspondant.

## 6. Guard readiness (E5)

| Entree guard | valeur | bloque outbound ? | verdict |
|---|---|---|---|
| cmmsdn4if validationStatus | VALIDATED | non | guard ouvert |
| cmmsdn4if pipelineStatus | VALIDATED | non | guard ouvert |
| cmmsdn4if marketplaceStatus | VALIDATED | non | guard ouvert |
| self-test selection (marketplaceStatus != VALIDATED) | exclut cmmsdn4if | n/a | adresse deja validee |
| outbound deliveries / pending retry ecomlg-001 FR | aucun (Job/OutboundEmail/MOM vides) | n/a | rien a renvoyer |

Le guard lit l'etat de validation de l'adresse inbound ; les trois champs etant VALIDATED, l'entree du guard est satisfaite pour ecomlg-001 FR. Aucune reponse envoyee par cette phase.

## 7. No unintended processing (E6)

| Signal | etat | verdict |
|---|---|---|
| Job total / OUTBOUND_EMAIL_SEND | 0 / 0 | aucun job, jobs-worker n'a rien claime |
| OutboundEmail | 0 | aucun envoi declenche |
| MarketplaceOutboundMessage | 0 | aucun message marketplace envoye |
| retry outbound | aucun | OK |
| fake webhook / event / job / email | aucun | OK |
| jobs-worker restarts | 0 | OK |
| mutation DB / flip manuel | aucun | lecture seule stricte |

## 8. Decision (E7)

cmmsdn4if validationStatus = VALIDATED => Verdict READY.

Prochaine phase recommandee :
GO READONLY AMAZON OUTBOUND DELIVERY STATUS PROD PH-SAAS-T8.12AS.20.14AE
(ou, si un message client attend une reponse : GO TEST AMAZON OUTBOUND REPLY PROD PH-SAAS-T8.12AS.20.14AE).

Hygiene separee (hors P0) : reconcilier le doublon token 4xfub8 / 3jcpvk pour ecomlg-001 FR (3jcpvk reste non resolu cote PROD, log Address not found) ; upgrade amazon-orders / amazon-items-worker hors v1.0.40.

## 9. Phrase cible

GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS PROD READY PH-SAAS-T8.12AS.20.14AD

STOP.
