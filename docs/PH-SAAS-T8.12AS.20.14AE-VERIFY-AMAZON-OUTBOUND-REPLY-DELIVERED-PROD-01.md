# PH-SAAS-T8.12AS.20.14AE-VERIFY-AMAZON-OUTBOUND-REPLY-DELIVERED-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14AD (verify inbound) / PH-20.14AC (apply PROD) / PH-20.14V (RCA)
> Phase : PH-SAAS-T8.12AS.20.14AE (READONLY VERIFY AMAZON OUTBOUND REPLY DELIVERED)
> Environnement : PROD (lecture seule ; aucun envoi, aucun retry, aucune mutation)

## 1. Verdict

GO VERIFY AMAZON OUTBOUND REPLY DELIVERED PROD READY_RESTORED PH-SAAS-T8.12AS.20.14AE

La reponse envoyee par Ludovic depuis KeyBuzz (eComLG / ecomlg-001) vers la conversation Amazon FR (order 403-2003407-5310706) a ete LIVREE avec succes : outbound_delivery dlv-1779812128984-f4focufpx status=delivered via provider SMTP_AMAZON_NONORDER, attempt_count=1, last_error=null, delivered_at 2026-05-26T16:15:32Z (~4s apres l'envoi). Le guard outbound n'a pas bloque (aucun INBOUND_NOT_VALIDATED ; product inbound_addresses ecomlg-001 FR validationStatus=VALIDATED). Reception confirmee cote Amazon par Ludovic. Aucun doublon outbound, aucun retry, aucune mutation, jobs-worker restarts=0. P0 KEY-323 RESTAURE pour ecomlg-001 / Amazon FR.

## 2. Runtime PROD (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 18:47.

| Service / signal | value | verdict |
|---|---|---|
| keybuzz-backend PROD | v1.0.54-prod, digest 060abd98, ready, restarts=0 | OK |
| jobs-worker PROD | v1.0.54-prod, digest 060abd98, ready, restarts=0 | OK |
| keybuzz-api PROD | v3.5.257-autopilot-no-reply-kbactions-prod, ready | OK |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod, ready | OK (sert le canal SMTP Amazon) |
| ecomlg-001 FR validationStatus (backend InboundAddress cmmsdn4if) | VALIDATED (PH-20.14AD) | OK |
| ecomlg-001 FR validationStatus (product inbound_addresses addr_a8a7eead) | VALIDATED | OK (entree guard) |

## 3. Message outbound (E1)

DB produit keybuzz (SELECT only, PII masquee).

| Conversation | order | outbound message id | timestamp (UTC) | source | status conv | verdict |
|---|---|---|---|---|---|---|
| cmmpml7hy973b1706b3f49631 | 403-2003407-5310706 | msg-1779812128870-b938s10v8 | 2026-05-26T16:15:28.885Z | AI_ASSISTED, direction=outbound, body 853 car | open / escalated | reponse agent enregistree |

Conversation : last_inbound_at 16:12:48Z (vrai message client), first_response_at + last_agent_message_at 16:15:28.9Z (reponse agent posee), channel=amazon. Agent = 43a1d34c-b8de-4226-b8db-0f4da87924a7 (compte owner Ludovic, ecomlg-001). NB : status reste open + escalation_status=escalated (workflow escalade PH142-D distinct ; la reponse EST enregistree via first_response_at/last_agent_message_at).

## 4. Delivery / provider (E2)

| Delivery id | provider | status | sentAt/deliveredAt (UTC) | attempt | last_error | verdict |
|---|---|---|---|---|---|---|
| dlv-1779812128984-f4focufpx | SMTP_AMAZON_NONORDER | delivered | created 16:15:29.027Z / delivered 16:15:32.828Z | 1 | null | LIVRE |

Cible (masquee) 43v***.fr = adresse anonymisee Amazon buyer-seller-messaging (@marketplace.amazon.fr). Aucun message "inbound address not validated". Distribution all-time ecomlg-001 amazon : SMTP_AMAZON_NONORDER delivered 234, SMTP_FALLBACK delivered 2, spapi failed 5 (incident historique 2026-05-15, hors scope). Le canal email SMTP est le chemin nominal d'expedition Amazon.

## 5. Logs outbound (E3)

| Log source | evidence | verdict |
|---|---|---|
| keybuzz-outbound-worker | "Processing dlv-1779812128984-f4focufpx (attempt: 1)" | claim unique |
| keybuzz-outbound-worker | "Using UNIFIED SMTP for Amazon (orderId: 403-2003407-5310706)" + "using SMTP (not SP-API)" | routage SMTP (message avec order_ref) |
| keybuzz-outbound-worker | "dlv-1779812128984-f4focufpx delivered via SMTP_AMAZON_NONORDER" | SUCCESS |
| keybuzz-api | POST /messages/conversations/cmmpml7hy.../reply?tenantId=ecomlg-001 (16:15:28.759Z) | requete reponse Ludovic |
| keybuzz-api | "[SLA] Updated outbound: conv=cmmpml7hy..., state=OK" + "AP.2.7 Auto-assigned to replier" | reponse traitee, assignee a l'agent |
| keybuzz-api / worker | INBOUND_NOT_VALIDATED / "not validated" | ABSENT (guard non bloquant) |
| worker | retry / error / 2e tentative | ABSENT |

## 6. Guard (E4)

| Guard input | value | blocks? | verdict |
|---|---|---|---|
| product inbound_addresses ecomlg-001 FR validationStatus | VALIDATED | non | guard ouvert |
| backend InboundAddress cmmsdn4if validationStatus (PH-20.14AD) | VALIDATED | non | coherent |
| log INBOUND_NOT_VALIDATED pour cette delivery | absent | non | OK |
| route outbound | reply -> outbound_delivery -> SMTP_AMAZON_NONORDER | n/a | route correcte |

Le guard outbound (keybuzz-api) lit le store product inbound_addresses ; ecomlg-001 FR y est VALIDATED -> envoi autorise. Le store backend (cmmsdn4if) valide en PH-20.14AD est egalement VALIDATED (coherence des deux stores).

## 7. No unintended processing (E5)

| Signal | etat | verdict |
|---|---|---|
| outbound messages ecomlg-001 amazon 12h | 1 (la reponse) | aucun doublon |
| outbound_deliveries ecomlg-001 amazon 12h | 1 (dlv-...f4focufpx) | aucun doublon |
| attempt_count | 1 | aucun retry |
| next_retry_at | n/a (delivered) | aucun retry programme |
| message marketplace inattendu | aucun | OK |
| mutation DB manuelle / flip / fake | aucune | lecture seule stricte |
| jobs-worker restarts | 0 | OK |

## 8. Decision (E6)

outbound delivery success confirme (DB status=delivered + logs worker "delivered via SMTP_AMAZON_NONORDER" + reception Amazon confirmee par Ludovic) => Verdict READY_RESTORED.

- KEY-323 RESTAURE pour ecomlg-001 / Amazon FR : reponse client Amazon expediee et livree depuis KeyBuzz, guard ouvert, aucune erreur, aucun retry.
- Prochaine phase recommandee : GO READONLY AMAZON CONNECTORS VALIDATION STATUS PROD PH-SAAS-T8.12AS.20.14AF -- lister les autres pays/adresses encore PENDING (ecomlg-001 BE/PL en PENDING cote product ; autres tenants) et decider un traitement une par une. Ne pas proposer de retry global.

## 9. Phrase cible

GO VERIFY AMAZON OUTBOUND REPLY DELIVERED PROD READY_RESTORED PH-SAAS-T8.12AS.20.14AE

STOP.
