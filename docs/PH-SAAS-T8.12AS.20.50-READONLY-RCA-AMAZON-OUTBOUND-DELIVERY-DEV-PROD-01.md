# PH-SAAS-T8.12AS.20.50-READONLY-RCA-AMAZON-OUTBOUND-DELIVERY-DEV-PROD-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.50 (READONLY RCA Amazon outbound delivery)
> Environnement : DEV + PROD ; read-only strict (SELECT/logs/get/exec lecture) ; 0 mutation/0 envoi/0 fake

## 1. Verdict

GO READONLY RCA AMAZON OUTBOUND DELIVERY DEV PROD READY PH-SAAS-T8.12AS.20.50

Cause racine identifiee, distincte par tenant. La chaine outbound KeyBuzz (API -> outbound_deliveries
-> keybuzz-outbound-worker -> getInboundAddressForTenant -> SMTP From = adresse inbound VALIDATED ->
Postfix mail.keybuzz.io:25) FONCTIONNE pour les tenants dont le connecteur est VALIDATED (ecomlg-001
DEV+PROD : delivered, From = adresse connecteur validee). Les echecs observes ne viennent PAS d'un
bug code ni de PH-20.49, mais de la configuration connecteur tenant et de l'absence d'envoi reel.

## 2. Reponse a la question centrale de Ludovic

OUI : KeyBuzz expedie bien depuis l'adresse inbound/connecteur VALIDATED du tenant. Preuve directe
(logs worker DEV + PROD) :
- PROD : "[Guard] Amazon outbound config validated for ecomlg-001: from=amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io"
  puis "SMTP sending ... from amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io via mail.keybuzz.io:25".
- DEV : "from=amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io" -> delivered.
Quand le connecteur n'est PAS validated, le worker REFUSE l'envoi ("Amazon inbound address not
validated") au lieu d'expedier depuis noreply@ : la protection From historique est ACTIVE et
correcte. Aucune trace de From=noreply@keybuzz.io.

## 3. Runtime

| env | service | namespace | image | ready | restarts | verdict |
|---|---|---|---|---:|---:|---|
| DEV | keybuzz-api | keybuzz-api-dev | v3.5.259-ai-assist-notification-scope-dev | 1 | 0 | OK |
| DEV | keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | 1 | 2 (stable, 05-16) | actif |
| DEV | keybuzz-backend/jobs-worker | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | 1 | 0 | OK |
| PROD | keybuzz-api | keybuzz-api-prod | v3.5.259-ai-assist-notification-scope-prod | 1 | 0 | OK |
| PROD | keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | 1 | 2 (stable, 05-16) | actif |
| PROD | keybuzz-backend/jobs-worker | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 1 | 0 | OK |

Note : keybuzz-outbound-worker (image v3.5.165, workerVersion interne 4.8.0-visual-line-preservation)
est SEPARE de jobs-worker. Il claim et envoie correctement (ecomlg-001 delivered). Pas de
WORKER_RUNTIME_STALE constate sur le chemin SMTP_AMAZON_NONORDER.

## 4. Candidats outbound (PROD, 72h)

| env | tenant | conversation | provider | status | attempt | target (relay Amazon) | candidat |
|---|---|---|---|---|---:|---|---|
| PROD | ecomlg-motxke32 | cmmpml7i1z... | spapi->SMTP | failed | 5 | 43vfy...@marketplace.amazon.fr | OUI (echec) |
| PROD | ecomlg-001 | cmmpnszneu... | SMTP_AMAZON_NONORDER | delivered | 1 | 54ms9...@marketplace.amazon.fr | OUI (succes) |
| PROD | ecomlg-001 | (x9 72h) | SMTP_AMAZON_NONORDER | delivered | 1 | *@marketplace.amazon.fr | OUI (succes) |
| PROD | ecomlg-motxke32 | (x7 72h) | spapi->SMTP | failed | 5 | *@marketplace.amazon.fr | OUI (echec) |
| PROD | switaa-sasu-mnc1ouqu | - | - | - | - | - | AUCUN envoi 7j (dernier 05-17) |

DEV (72h) : ecomlg-001 SMTP_AMAZON_NONORDER delivered (06:09Z) ; switaa-sasu-mnc1x4eq SMTP_FALLBACK
delivered (05-25). Pipeline DEV fonctionnel.

## 5. Delivery DB (PROD)

| tenant | provider | status | attempt | last_error | From (logs) | verdict |
|---|---|---|---:|---|---|---|
| ecomlg-001 | SMTP_AMAZON_NONORDER | delivered | 1 | - | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | PASS (Postfix 250) |
| ecomlg-motxke32 | spapi (SPAPI msg disabled) -> SMTP | failed | 5 | Amazon inbound address not validated | (bloque avant envoi) | FAIL connecteur |

delivery_trace ne stocke pas From/replyTo (calcules au send par le worker via
getInboundAddressForTenant). spapiEnabled=false ; AMAZON_SPAPI_MESSAGING_ENABLED=false -> meme les
conversations AVEC commande (orderId 403-2003407) passent par SMTP (fallback documente).

## 6. Adresse connecteur (inbound_addresses)

| env | tenant | pays | validation | localpart inbound | match From |
|---|---|---|---|---|---|
| PROD | ecomlg-001 | FR | VALIDATED | amazon.ecomlg-001.fr.4xfub8 | PASS (From = ce localpart) |
| PROD | ecomlg-001 | ES/IT | VALIDATED | ... | PASS |
| PROD | ecomlg-001 | PL/BE | PENDING | ... | n/a (pays non utilise) |
| PROD | ecomlg-motxke32 | FR | PENDING | amazon.ecomlg-motxke32.fr.as0yom | FAIL (jamais valide, lastInboundAt=null) |
| PROD | switaa-sasu-mnc1ouqu | FR/BE/ES | VALIDATED | amazon.switaa-...* | PASS (mais aucun envoi recent) |

Cause directe de l'echec ecomlg-motxke32 : son SEUL connecteur (FR) est en validationStatus=PENDING
(jamais valide cote marketplace, lastInboundAt=null). Le worker bloque donc tout envoi de ce tenant.

## 7. Provider decision

| env | conversation | order_ref | expected | observed | verdict |
|---|---|---|---|---|---|
| PROD | ecomlg-001 nonorder | non | SMTP_AMAZON_NONORDER | SMTP_AMAZON_NONORDER | OK |
| PROD | ecomlg-motxke32 order | oui (403-2003407) | SPAPI_ORDER (fallback SMTP autorise) | spapi -> SMTP (SPAPI messaging disabled) | OK (fallback), bloque ensuite par connecteur |

AMAZON_SPAPI_MESSAGING_ENABLED=false en PROD -> tout passe par SMTP. Conforme a la source de verite
(fallback SMTP autorise). Pas de PROVIDER_DECISION_WRONG.

## 8. Worker logs (preuves)

| env | marker | interpretation |
|---|---|---|
| PROD | [Guard] config validated ecomlg-001 from=...inbound.keybuzz.io | From = connecteur valide |
| PROD | [EmailService] SMTP sending ... from amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io via mail.keybuzz.io:25 | envoi SMTP depuis bonne adresse |
| PROD | [Worker] dlv-... delivered via SMTP_AMAZON_NONORDER | Postfix a accepte (250) |
| PROD | [Worker] AMAZON_SPAPI_MESSAGING_ENABLED=false ; Using UNIFIED SMTP | SP-API messaging off, fallback SMTP |
| PROD | [Worker] dlv-... failed: Amazon inbound address not validated | ecomlg-motxke32 bloque (connecteur PENDING) |
| DEV | [Guard] config validated ecomlg-001 from=amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io -> delivered | DEV identique |

## 9. Postfix / SP-API

- SP-API : AMAZON_SPAPI_MESSAGING_ENABLED=false -> non utilise pour l'envoi ; fallback SMTP. Pas de
  SPAPI_FAILURE.
- Postfix : worker obtient "delivered" = mail.keybuzz.io (Postfix) a accepte (250). Le relais
  Postfix -> Amazon (inbound-smtp.*.amazonaws.com, dsn=2.0.0) N'EST PAS verifiable depuis install-v3
  (pas de maillog local ; mail-core non joignable dans cette phase read-only). Sous-point
  SMTP_ACCEPTED_BUT_NOT_VISIBLE non confirme/infirme pour les envois ecomlg-001 delivered.

## 10. Reply path / regression PH-20.49

Pas de regression : ecomlg-001 a delivered en DEV (06:09Z 2026-05-28) et en PROD (recent) APRES le
deploy PH-20.49 (API/Client v3.5.259). Le chemin reply -> outbound_deliveries -> worker -> SMTP est
intact. switaa a genere des brouillons IA (PH-20.46-QUATER) mais 0 message outbound sur 7j : generer
un brouillon Aide IA n'est PAS un envoi ; il faut cliquer Envoyer pour creer une delivery.

## 11. Root cause classification

| env | tenant | primary_cause | evidence | next_action |
|---|---|---|---|---|
| PROD | ecomlg-motxke32 | WRONG_CONNECTOR_FROM (connecteur FR PENDING) | 7 deliveries failed "inbound address not validated" ; inbound_addresses.validationStatus=PENDING | valider le connecteur Amazon FR du tenant (Settings > Channels) - config, pas code |
| PROD | switaa-sasu-mnc1ouqu | INSUFFICIENT_REAL_ATTEMPTS | 0 message outbound 7j, derniere delivery 05-17 ; brouillons IA != envoi | faire 1 envoi reel (clic Envoyer) puis re-auditer |
| PROD/DEV | ecomlg-001 | OK (delivered, From connecteur valide) | worker Guard + delivered ; residual = visibilite Amazon non verifiee | confirmer relais Postfix->Amazon + Seller Central (phase mail-core) |

Cause dominante du ressenti "les messages n'arrivent pas" : connecteur tenant NON valide
(ecomlg-motxke32) -> envoi bloque par design ; et brouillons non envoyes (switaa). Le From est
correct partout (adresse connecteur validee).

## 12. No side-effect

| signal | observe | verdict |
|---|---|---|
| pods restart causes par la phase | 0 (api-prod restarts=0 depuis rollout PH-20.49 ; outbound-workers stables 05-16) | OK |
| DB mutation | aucune (SELECT only) | OK |
| envoi email / POST reply / fake | aucun | OK |
| KBActions | non touches | OK |
| inbound advisory lock backend | non touche | OK |

## 13. Gaps restants

- Confirmation Postfix mail.keybuzz.io -> Amazon (relais 250 inbound-smtp.*.amazonaws.com) pour les
  envois ecomlg-001 delivered : non realisable read-only depuis install-v3 (mail-core requis).
- Visibilite Seller Central des messages delivered : non verifiable cote infra (verification humaine
  vendeur / mail-core).
- ecomlg-motxke32 : aucun connecteur valide -> action produit/config tenant.

## 14. Prochaine phase recommandee

1. Config (Ludovic / produit) : valider le connecteur Amazon FR de ecomlg-motxke32 (Settings >
   Channels) ; puis re-test envoi. Aucun patch code.
2. PH-20.51 (read-only mail-core) : lire les logs Postfix mail.keybuzz.io pour un envoi ecomlg-001
   delivered et confirmer le relais 250 vers inbound-smtp.*.amazonaws.com (statuer
   SMTP_ACCEPTED_BUT_NOT_VISIBLE vs delivered-et-visible).
3. switaa : faire un envoi reel pour generer une delivery exploitable.

## 15. Phrase cible

GO READONLY RCA AMAZON OUTBOUND DELIVERY DEV PROD READY PH-SAAS-T8.12AS.20.50

STOP.
