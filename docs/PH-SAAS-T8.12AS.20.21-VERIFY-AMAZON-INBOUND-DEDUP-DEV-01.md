# PH-SAAS-T8.12AS.20.21-VERIFY-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.21 (VERIFY RUNTIME DEDUP DEV)
> Environnement : DEV (read-only ; aucune mutation, aucun fake webhook/event)

## 1. Verdict

GO VERIFY AMAZON INBOUND DEDUP DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.21

Le patch dedup PH-20.17 est PROUVE ACTIF au runtime DEV v1.0.55 (code present dans le dist du pod en cours, cle metier peuplee dans les vraies donnees, pattern de doublon pre-patch confirme). MAIS le declenchement live du skip idempotent n'a PAS pu etre observe : AUCUN message Amazon inbound reel n'est arrive en DEV depuis le deploiement v1.0.55 (0 message cree apres 22:16Z). Conformement au cadrage (pas de fake webhook, pas de payload synthetique), je NE simule PAS. Action requise : Ludovic doit generer une vraie redelivery Amazon en DEV (voir section 9). Aucune mutation, aucun fake event ; PROD intact ; P0 KEY-323 preserve.

## 2. Preflight runtime (E0)

| Service | Namespace | Image | Digest | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | sha256:b314826...9702 | true | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | sha256:b314826...9702 | true | 0 | OK |
| keybuzz-backend | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | - | - | - | inchange |
| jobs-worker | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | - | - | - | inchange |

jobs-worker DEV : JOB_TYPES=OUTBOUND_EMAIL_SEND.

## 3. Code dedup vivant au runtime (preuve structurelle)

Dans le conteneur backend DEV en cours d'execution (pas seulement l'image) :
- dist/modules/webhooks/inboundDedup.js : extractStableAmazonMessageKey present (2 occurrences).
- dist/modules/webhooks/inboxConversation.service.js : requete idempotence `metadata->'amazonIds'->>'messageId'` presente.

Le patch PH-20.17 est donc reellement charge et executable par le runtime DEV.

## 4. Baseline DEV read-only (E1) + recherche preuve naturelle (E2)

| Signal | Valeur | Verdict |
|---|---|---|
| pod backend DEV start | 2026-05-26T22:16:27Z (deploiement v1.0.55) | OK |
| logs ingestion (inbound-email/AmazonDetection/Idempotent skip/Created) depuis start | 0 | aucun inbound post-deploy |
| messages crees depuis 22:16Z | 0 | aucune preuve naturelle disponible |
| conversations amazon < 24h | 6 | activite PRE-deploy (v1.0.54) |
| messages inbound < 24h | 21 | activite PRE-deploy |
| ExternalMessage AMAZON < 24h | 33 | activite PRE-deploy |
| jobs-worker AMAZON_POLL worker-1 | 0 | OK |
| jobs-worker heartbeat | claimed=0 (no job this poll) | idle, no spontaneous processing |

Conclusion E2 : aucune redelivery Amazon reelle post-deploy -> pas de preuve naturelle du skip idempotent. Pas de simulation (gate E3).

## 5. DB evidence - doublon pre-patch (E5)

La cle de dedup est PEUPLEE dans les vraies donnees DEV et le bug pre-patch est demontre : 5 groupes ou un meme metadata.amazonIds.messageId apparait dans 2 messages (tenant ecomlg-001).

| amazonMessageId | tenant | conversations | messages | nature |
|---|---|---|---|---|
| A089466823REET8SHWBIX | ecomlg-001 | 1 (cmmkfq1qp) | 2 | redelivery -> 2 messages dans 1 conversation (dup message-level intra-tenant, v1.0.54) |
| A072088936ZFUK4R8598C | ecomlg-001 | - | 2 | idem (groupe pre-patch) |
| A037959231V4441HYVKCN | ecomlg-001 | - | 2 | idem |
| A080202427SVYTM4KNFAW | ecomlg-001 | - | 2 | idem |
| A10155483BLNULTHXRSSL | ecomlg-001 | - | 2 | idem |

Interpretation : sous v1.0.54 (sans dedup message), la redelivery SES d'un meme message Amazon (meme amazonIds.messageId) creait un 2e message dans la conversation existante. Avec v1.0.55, l'idempotence sur metadata.amazonIds.messageId (scopee tenant) interceptera la 2e livraison AVANT toute creation -> 1 message logique (skip idempotent). Le messageId A089466823REET8SHWBIX est celui identifie en PH-20.16. NB : ces doublons sont PRE-existants ; aucun cleanup effectue (hors scope, phase separee).

## 6. Log evidence (E6)

Aucun log stableAmazonMessageKey / Idempotent skip / Created depuis le deploiement (0 inbound). Le log de skip idempotent (`[InboxConversation] Idempotent skip: Amazon message already ingested`) sera emis lors de la prochaine redelivery reelle.

## 7. Non-regression (E7)

| Garantie | etat |
|---|---|
| jobs-worker AMAZON_POLL worker-1 | 0 |
| API DEV ready / restarts | true / 0 |
| jobs-worker DEV ready / restarts | true / 0 |
| Inbox creation messages Amazon reels | preservee (code ingestion intact ; fallback SES conserve) |
| IA / escalades / assignment / statuts / historique | non touches |
| PROD | intact (v1.0.54-prod, aucun manifest/apply PROD) |
| KEY-323 P0 | restaure, non rouvert |

## 8. Mode de preuve

natural = NON (0 inbound post-deploy) ; replay controle = NON execute (eviter tout payload reconstruit/synthetique au niveau enveloppe webhook, conformement au cadrage) ; action required = OUI.

## 9. ACTION REQUISE (Ludovic) pour preuve runtime definitive

Generer une VRAIE redelivery Amazon en DEV sur le tenant test ecomlg-001 DEV :
- Option 1 (recommandee) : envoyer un vrai message acheteur Amazon vers le vendeur DEV (comme PH-20.14Z2 : compte test Switaa -> vendeur eComLG). Amazon/SES redelivre typiquement le meme message en plusieurs copies (SES Message-ID distincts, meme amazonIds.messageId) -> le patch doit aboutir a 1 conversation + 1 message (1 creation + skip idempotent sur la/les copie(s)).
- Option 2 : si une vraie redelivery Amazon peut etre provoquee sur un message existant, l'envoyer vers l'adresse inbound DEV ecomlg-001.
Puis relancer une phase VERIFY read-only : confirmer dans les logs DEV "Created message" (1ere copie) puis "Idempotent skip: Amazon message already ingested" (copies suivantes), et en DB 1 seul message logique par amazonIds.messageId pour ce groupe.

Ne PAS : fabriquer un webhook, reconstruire un payload, muter la DB, toucher PROD.

## 10. Limites restantes

- Doublon CROSS-TENANT (ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom) : NON corrige par ce patch (decision produit + cleanup data, phases separees).
- Doublons intra-tenant PRE-existants en DB : non nettoyes (phase cleanup dediee).
- Promotion PROD (PH-20.22+) : a conditionner a la preuve runtime DEV (cette phase ACTION_REQUIRED) OU a une decision explicite de Ludovic d'accepter la preuve structurelle (code live + key peuplee + dup pre-patch) comme suffisante.

## 11. Phrase cible

GO VERIFY AMAZON INBOUND DEDUP DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.21

STOP.
