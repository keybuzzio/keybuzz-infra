# PH-SAAS-T8.12AS.20.36-VERIFY-STALE-REPLYTO-REMOVAL-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.36 (VERIFY SELLER CENTRAL STALE REPLY_TO REMOVAL)
> Environnement : PROD read-only (SELECT/logs uniquement ; aucune mutation)

## 1. Verdict

GO VERIFY STALE REPLY_TO REMOVAL PROD PARTIAL PH-SAAS-T8.12AS.20.36

DB confirmee : 4xfub8 = ecomlg-001 FR VALIDATED (conserve, actif), as0yom = ecomlg-motxke32 FR VALIDATED (non touche), 3jcpvk + cp2hat ABSENTS de la DB (count=0, jamais provisionnes). MAIS le retrait Seller Central n'est PAS encore observe effectif au runtime : un batch Amazon post-action (14:36-14:37Z, soit apres le message buyer de 14:05) a ENCORE ete delivre vers amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io ET ...cp2hat@... . Ces livraisons sont des NOTIFICATIONS Amazon Seller Central (donotreply) suivant un ancien thread reply-to ; 4xfub8 et as0yom n'ont recu aucune de ces notifs (0 sur 25 min). Constat additionnel surface : ces emails de notification ne portent PAS d'amazonIds (method=generic_cleanup, amazonIds=undefined) -> ils tombent sur le fallback de lock thread:<tenant>:<threadKey> (serialise mais NON collapse), donc 1 message cree par livraison (la dedup atomique amzmsg ne couvre que les messages porteurs d'amazonIds.messageId). PROD strictement read-only, aucune mutation. Re-verification necessaire apres propagation Amazon.

## 2. Preflight (E0)

| Element | Etat |
|---|---|
| Bastion | install-v3 / 46.62.171.61 |
| date | 2026-05-27 14:39Z |
| PROD API + jobs-worker | v1.0.56-amazon-inbound-dedup-prod (digest 9689875c), restarts=0 |
| DEV | v1.0.56-amazon-inbound-dedup-dev (inchange) |

## 3. Verification DB inbound addresses (E1)

Backend keybuzz_backend_prod.inbound_addresses (routage reply-to reel) :

| token | tenant/localpart | DB status | validation | action | verdict |
|---|---|---|---|---|---|
| 4xfub8 | ecomlg-001 FR | PRESENT | VALIDATED/VALIDATED | CONSERVER | OK conserve |
| as0yom | ecomlg-motxke32 FR | PRESENT | VALIDATED/VALIDATED | hors scope (cross-tenant) | inchange |
| 3jcpvk | ecomlg-001 (localpart) | ABSENT (count=0) | n/a | retire Seller Central (Ludovic) | absent DB OK |
| cp2hat | ecomlg-001 (localpart) | ABSENT (count=0) | n/a | retire Seller Central (Ludovic) | absent DB OK |

L'etat DB est conforme a l'attendu PH-20.35 (3jcpvk/cp2hat n'ont jamais ete provisionnes ; leur retrait Seller Central ne change pas la DB).

## 4. Baseline historique avant retrait (E2)

| token | vu avant ? | evidence |
|---|---|---|
| 4xfub8 | OUI | message buyer 14:05 (A007902311) -> reply-to valide -> Created (PH-20.34-BIS) |
| 3jcpvk | OUI | message buyer 14:05 fan-out -> "Address not found" -> Idempotent skip (advisory lock amzmsg) |
| cp2hat | OUI | idem 14:05 fan-out -> Idempotent skip |
| as0yom | OUI | message 14:05 -> ecomlg-motxke32 cross-tenant (Created distinct) |

Avant retrait, le message buyer 14:05 (porteur d'amazonIds A007902311OYREHWN5VKM) etait collapse a 1 message ecomlg-001 par l'advisory lock amzmsg malgre le fan-out 4xfub8+3jcpvk+cp2hat (preuve PH-20.34-BIS).

## 5. Verification logs apres action (E3) -- RETRAIT NON ENCORE EFFECTIF

Fenetre : derniers ~25 min (jusqu'a 14:39Z). Tokens recipients observes :

| token | seenAfterAction (25m) | dernieres receptions | verdict |
|---|---|---|---|
| 4xfub8 | 0 | aucune depuis 14:05 | pas de message buyer recent |
| as0yom | 0 | aucune depuis 14:05 | pas de message recent |
| 3jcpvk | 6 | 14:36:52Z, 14:37:03Z (+ autres) | ENCORE RECU -> retrait non effectif |
| cp2hat | 8 | 14:36:55Z, 14:37:01Z (+ autres) | ENCORE RECU -> retrait non effectif |

Detail batch 14:36-14:37 (4 POST) : from = "Notifications Amazon Seller Central (Ne pas repondre) donotreply@amazon.com" ; to = amazon.ecomlg-001.fr.{3jcpvk|cp2hat}@inbound.keybuzz.io ; chaque POST -> "[AmazonDetection] Real Amazon inbound for ecomlg-001/amazon/FR but address not resolved (Address not found)" -> MessageNormalizer source=AMAZON method=generic_cleanup amazonIds=undefined threadKey=hash:714e46e17d88 -> "Dedup lock acquired scope=thread tenant=ecomlg-001" -> "Created message" (PAS d'Idempotent skip).

Interpretation : (a) le retrait Seller Central de 3jcpvk/cp2hat n'est PAS encore propage / pas effectif sur les threads existants -> Amazon continue d'expedier vers ces reply-to obsoletes ; (b) ces emails sont des NOTIFICATIONS (donotreply), pas des messages buyer, et ne portent PAS d'amazonIds -> la dedup atomique amzmsg (PH-20.26) ne s'applique pas ; le fallback thread-scope serialise mais ne collapse pas (chaque notification = 1 message). 4xfub8 n'a recu aucune de ces notifs : elles suivent l'ancien thread reply-to (3jcpvk/cp2hat) cote Amazon, pas l'adresse valide.

## 6. Pas de preuve READY sur message buyer post-retrait (E4)

Aucun NOUVEAU message buyer porteur d'amazonIds n'est arrive depuis 14:05 (dernier amazon_msg_id en DB keybuzz_prod = A007902311OYREHWN5VKM @ 14:05:11). La preuve complete "4xfub8 seul, 3jcpvk/cp2hat ne reapparaissent plus" sur un vrai message buyer reste a etablir APRES propagation effective du retrait Amazon. Aucune simulation/replay (cadrage respecte).

## 7. Non-regression (E6)

| Garantie | etat |
|---|---|
| ecomlg-001 FR 4xfub8 | VALIDATED/VALIDATED (inchange) |
| API + jobs-worker PROD restarts | 0 |
| AMAZON_POLL lockedBy worker-1 | 0 |
| Job OUTBOUND_EMAIL_SEND / OutboundEmail / MOM | vides (0), inchanges (aucun outbound declenche par les notifs entrantes) |
| outbound reply restaure (KEY-323) | non touche |
| mutation DB / cleanup / trigger / fake | 0 |
| DEV | v1.0.56-dev inchange |

## 8. AI feature parity / anti-regression

Phase 100% read-only (SELECT + logs). Aucune modification IA/escalades/assignment/statuts/historique. Le P0 KEY-323 (race buyer-message intra-tenant, amazonIds) reste CLOS (advisory lock amzmsg actif + prouve PH-20.34-BIS). Le constat E5 (notifications sans amazonIds -> thread-scope, non collapsees) est un cas DISTINCT du P0, a evaluer separement.

## 9. Limites restantes / risques

- Retrait Seller Central 3jcpvk/cp2hat NON encore effectif au runtime (livraisons a 14:36-14:37) : propagation Amazon a attendre, ou retrait a re-verifier (peut concerner uniquement les nouveaux threads, pas les threads existants embarquant l'ancien reply-to). Risque si mauvais retrait : NE PAS retirer 4xfub8 (couperait l'ingestion ecomlg-001).
- NOUVEAU : emails de notification Amazon (donotreply, sans amazonIds) -> dedup thread-scope uniquement -> creation d'un message par livraison/reply-to. Hors P0 ; candidat a une phase d'analyse separee (dedup des notifications sans cle stable, ou filtrage donotreply).
- Cross-tenant as0yom (ecomlg-motxke32) : decision produit, non touche.
- Cleanup data historique + contrainte unique DB : phases differees (PH-20.38/39).

## 10. Recommandation / next GO

Re-verifier le retrait apres propagation (re-run read-only de cette phase sur un vrai message buyer ulterieur : attendu 4xfub8 seul cote ecomlg-001, 0 reception 3jcpvk/cp2hat). En parallele, poursuivre la sequence d'hygiene. Prochaine phase recommandee : GO READONLY AMAZON CROSS_TENANT DECISION PROD PH-SAAS-T8.12AS.20.37 (analyse read-only ecomlg-001 / ecomlg-motxke32 = 2 tenants pour le meme seller reel, decision canonique ou statu quo, sans mutation).

## 11. Phrase cible

GO VERIFY STALE REPLY_TO REMOVAL PROD PARTIAL PH-SAAS-T8.12AS.20.36

STOP.
