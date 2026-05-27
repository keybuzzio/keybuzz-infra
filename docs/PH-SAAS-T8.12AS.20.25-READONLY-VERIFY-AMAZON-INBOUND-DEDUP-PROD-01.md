# PH-SAAS-T8.12AS.20.25-READONLY-VERIFY-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.25 (READONLY VERIFY AMAZON INBOUND DEDUP PROD)
> Environnement : PROD read-only (SELECT + logs uniquement ; aucun fake webhook/event/trigger)

## 1. Verdict

GO READONLY VERIFY AMAZON INBOUND DEDUP PROD ACTION_REQUIRED PH-SAAS-T8.12AS.20.25

Le patch dedup v1.0.55-amazon-inbound-dedup-prod est ACTIF au runtime PROD (PH-20.24, digest b21e524a, runtime=manifest=last-applied). MAIS aucun vrai message Amazon inbound n'est arrive en PROD depuis le deploiement (pod API start 2026-05-27T10:15:35Z ; verify a 10:24Z, fenetre ~9 min) : 0 message Amazon cree, 0 marqueur d'ingestion en logs, 0 POST webhook inbound-email. Conformement au cadrage (pas de fake webhook / replay / trigger), je NE simule PAS. Action requise : Ludovic doit faire arriver une vraie reception Amazon en PROD (voir section 7), puis relancer le verify read-only. Non-regression OK, PROD intact, P0 KEY-323 non touche.

## 2. Preflight runtime (E0)

| Service | Namespace | Image | Digest | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | sha256:b21e524a...52e2 | true | 0 | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | sha256:b21e524a...52e2 | true | 0 | OK |
| keybuzz-backend | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | - | - | - | inchange |
| jobs-worker | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | - | - | - | inchange |

jobs-worker PROD JOB_TYPES=OUTBOUND_EMAIL_SEND. Bastion install-v3 / 46.62.171.61.

## 3. Heure de deploiement PH-20.24 (E1)

| Service | pod | startedAt | image | digest |
|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-797978c57d-cn68k | 2026-05-27T10:15:35Z | v1.0.55-prod | sha256:b21e524a...52e2 |
| jobs-worker | jobs-worker-75c884ffdc-nsfcp | 2026-05-27T10:16:10Z | v1.0.55-prod | sha256:b21e524a...52e2 |

Borne post-deploiement = 2026-05-27T10:15:35Z.

## 4. Vrais messages Amazon post-deploiement (E2)

| Signal | Valeur | Verdict |
|---|---|---|
| amazon inbound messages crees depuis 10:15:35Z | 0 | aucune preuve naturelle |
| groupes (tenant + amazonIds.messageId) depuis deploy | 0 | n/a |
| any inbound messages (tous canaux) depuis deploy | 0 | aucune activite |

DB produit keybuzz via pod backend PROD (PRODUCT_DATABASE_URL), SELECT only.

## 5. Logs dedup post-deploiement (E3)

| Marqueur | Compte depuis pod start | Verdict |
|---|---|---|
| MessageNormalizer / AmazonDetection / Idempotent skip / Created / Found existing / stableAmazonMessageKey | 0 | aucune ingestion |
| POST /api/v1/webhooks/inbound-email | 0 | aucune livraison mail |

Le log de skip idempotent (`[InboxConversation] Idempotent skip: Amazon message already ingested ...`) sera emis lors de la prochaine redelivery reelle.

## 6. Cas ecomlg-001 (E4) + non-regression (E7)

Aucun nouveau message ecomlg-001 (ni 4xfub8/3jcpvk/cp2hat/as0yom) depuis le deploiement. Etat preserve :

| Garantie | etat |
|---|---|
| ecomlg-001 FR amazon validationStatus / marketplaceStatus | VALIDATED / VALIDATED (inchange) |
| Job OUTBOUND_EMAIL_SEND (keybuzz_backend) | 0 (inchange) |
| OutboundEmail / MarketplaceOutboundMessage | 0 / 0 (inchange) |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 |
| jobs-worker heartbeat | claimed=0 (idle) |
| PROD restarts (backend + jobs-worker) | 0 / 0 |
| outbound reply restaure (PH-20.14AE) | non touche |
| trigger / retry / cleanup / fake | 0 |
| DEV | inchange (v1.0.55-dev) |

## 7. ACTION REQUISE (Ludovic)

Faire arriver une VRAIE reception Amazon en PROD pour exercer la dedup au runtime, puis relancer le verify read-only :
- Option 1 (recommandee) : un vrai message acheteur Amazon vers eComLG (ecomlg-001) ; Amazon/SES livre typiquement plusieurs copies (meme amazonIds.messageId) aux adresses reply-to -> le patch doit aboutir a 1 message logique par tenant (1 creation + skip idempotent sur les copies).
- Option 2 : tout vrai message Amazon entrant deja attendu sur un vendeur PROD connecte.
Puis re-run GO READONLY VERIFY AMAZON INBOUND DEDUP PROD : confirmer logs "Created" (1ere copie) + "Idempotent skip" (copies suivantes intra-tenant) et en DB countMessages=1 par (tenant, amazonIds.messageId).

Ne PAS : fabriquer un webhook, rejouer un payload, declencher Amazon, muter la DB.

## 8. Limites restantes

- RACE : dedup SELECT-puis-skip sans contrainte unique DB -> collapse non garantie sous redeliveries quasi-simultanees (cas PROD 06:29 = 4 POST en 229 ms). Contrainte unique DB produit (tenant_id, amazonIds.messageId / thread_key), phase separee.
- CROSS-TENANT : 4xfub8 (ecomlg-001) + as0yom (ecomlg-motxke32) non fusionnes (decision produit + cleanup data separes).
- Adresses reply-to obsoletes 3jcpvk/cp2hat cote Amazon Seller Central : retrait manuel separe.
- Doublons existants en DB : non nettoyes (phase cleanup dediee).

## 9. Prochain GO

ACTION_REQUIRED -> apres une vraie reception Amazon PROD, relancer PH-20.25 (verify read-only). Une fois READY : GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD PH-SAAS-T8.12AS.20.26 (plan read-only de retrait des reply-to obsoletes 3jcpvk/cp2hat + reconciliation cross-tenant, sans mutation).

## 10. Phrase cible

GO READONLY VERIFY AMAZON INBOUND DEDUP PROD ACTION_REQUIRED PH-SAAS-T8.12AS.20.25

STOP.
