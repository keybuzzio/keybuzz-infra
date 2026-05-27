# PH-SAAS-T8.12AS.20.30-BIS-VERIFY-REAL-MESSAGE-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.30-BIS (VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP)
> Environnement : DEV preuve + PROD informatif (read-only strict)

## 1. Verdict

GO VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.30-BIS

Classement = READY_DEV_ATOMIC_PROVED. Le vrai message Ludovic ("Et voila, de nouveau un message pour relancer", amazonIds.messageId A10199723W0X6V0H2T2A1) est arrive en DEV en **4 POST quasi-simultanes** (13:00:13.319-.344Z, ~25 ms, 4 IPs cluster distinctes) portant le MEME amazonIds.messageId. Sous v1.0.56 (advisory lock PH-20.26) la concurrence a ete SERIALISEE : "Dedup lock acquired scope=amzmsg" sur chaque livraison ; pour le tenant ecomlg-001, 1 "Created message" (cmmpo2njce...) + **2 "Idempotent skip"** -> **DB DEV = 1 message logique, 1 conversation, 1 raw MIME**. La 4e livraison = tenant ecomlg-motxke32 (cross-tenant, message distinct attendu, non corrige ici). C'est exactement le scenario qui produisait 2-3 messages sous v1.0.55 (PH-20.25-BIS) ; la race est demontree FERMEE en DEV. PROD v1.0.55 a recu le meme message (4 POST aussi) et l'a affiche 1 fois par tenant CETTE FOIS, mais SANS advisory lock (timing favorable) -> bon signal, PAS une preuve de fermeture race PROD. Promotion v1.0.56 PROD recommandee sur la base de la preuve DEV. PROD strictement intact, 0 mutation/trigger/fake.

## 2. Preflight runtime (E0)

| Env | Service | Image | Ready | Restarts | Verdict |
|---|---|---|---|---|---|
| DEV | keybuzz-backend | v1.0.56-amazon-inbound-dedup-dev | 1/1 | 0 | OK |
| DEV | jobs-worker | v1.0.56-amazon-inbound-dedup-dev | 1/1 | 0 | OK |
| PROD | keybuzz-backend | v1.0.55-amazon-inbound-dedup-prod | 1/1 | 0 | INTACT |
| PROD | jobs-worker | v1.0.55-amazon-inbound-dedup-prod | 1/1 | 0 | INTACT |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 13:05Z.

## 3. Fenetre + body (E1)

Fenetre : start 2026-05-27T12:55:00Z -> now. Body recherche : "de nouveau un message pour relancer" (sous-chaine sans accent du message Ludovic "Et voila, de nouveau un message pour relancer"). UI Paris ~15:00:13 = 13:00:13 UTC, coherent.

## 4. DB DEV keybuzz (E2) -- PREUVE

| tenantId | amazonMessageId | messageRows | conversationRows | rawMimeCount | firstAt | lastAt | verdict |
|---|---|---|---|---|---|---|---|
| ecomlg-001 | A10199723W0X6V0H2T2A1 | 1 | 1 | 1 | 13:00:13Z | 13:00:13Z | DEDUP OK |

Message cree : id cmmpo2njce4447197e8924aeb, conversation cmmkfq1qp83d5d8146f80a1c2, direction inbound, threadKey sc:A08467981VCU78NJADWD5, raw_mime_sha256 ccffb3a7..., raw_mime_key raw-mime/ecomlg-001/cmmpo2njce4447197e8924aeb.eml. 1 seule ligne malgre les redeliveries.

## 5. Logs backend DEV (E3) -- PREUVE CONCURRENCE

4 POST /api/v1/webhooks/inbound-email a 13:00:13 (reqId req-6c/6d/6e/6f ; t=1779886813319/.333/.340/.344 ; remoteAddress 10.244.7.152 / .183.128 / .95.0 / .78.197). 4 MessageNormalizer source=AMAZON messageId=A10199723W0X6V0H2T2A1.

| timestamp (approx) | marker | tenantId | amazonMessageId | lockScope | action | verdict |
|---|---|---|---|---|---|---|
| 13:00:13Z | Dedup lock acquired | ecomlg-001 | A10199723... | amzmsg | Found existing conversation sc:... -> Created message cmmpo2njce... | 1ere copie creee |
| 13:00:13Z | Dedup lock acquired | ecomlg-motxke32 | A10199723... | amzmsg | Created message (autre tenant) | cross-tenant distinct (attendu) |
| 13:00:13Z | Dedup lock acquired | ecomlg-001 | A10199723... | amzmsg | Idempotent skip: already ingested | redelivery skippee |
| 13:00:13Z | Dedup lock acquired | ecomlg-001 | A10199723... | amzmsg | Idempotent skip: already ingested | redelivery skippee |

4 lock acquisitions (3 ecomlg-001 + 1 ecomlg-motxke32) = 4 POST serialises. ecomlg-001 : 1 Created + 2 Idempotent skip. Aucune erreur transaction/advisory lock. Raw MIME stocke 1 fois (PH26.5K, 39608 bytes, sha256 ccffb3a7...).

## 6. DB PROD keybuzz_prod (E4) -- INFORMATIF

| tenantId | amazonMessageId | messageRows | conversationRows | rawMimeCount | firstAt | lastAt | verdict |
|---|---|---|---|---|---|---|---|
| ecomlg-001 | A10199723W0X6V0H2T2A1 | 1 | 1 | 1 | 13:00:13Z | 13:00:13Z | 1 fois (signal positif) |
| ecomlg-motxke32 | A10199723W0X6V0H2T2A1 | 1 | 1 | 1 | 13:00:13Z | 13:00:13Z | cross-tenant distinct |

Messages PROD : ecomlg-001 cmmpo2nk9g... (conv cmmpnxtgyg...) ; ecomlg-motxke32 cmmpo2nkd... (conv cmmpml7i1z...). raw_mime_sha256 distincts entre DEV et PROD (envois separes, normal). PROD a aussi recu 4 POST.

## 7. Logs backend PROD (E5) -- INFORMATIF, PAS DE PREUVE RACE PROD

PROD = 4 POST. PROD v1.0.55 N'A PAS d'advisory lock : AUCUN "Dedup lock acquired" (attendu). La dedup applicative v1.0.55 (SELECT-puis-skip sur amazonIds.messageId, PH-20.17) a NEANMOINS collapse ecomlg-001 a 1 (1 "Created message" cmmpo2nk9g... + 2 "Idempotent skip") cette fois -- timing favorable, les SELECT n'ont pas tous precede les INSERT. ecomlg-motxke32 = 1 Created (cmmpo2nkd...). **Ne PAS conclure que PROD est race-safe** : PH-20.25-BIS a prouve la meme dedup v1.0.55 defaite sous concurrence reelle (3 messages). Le resultat PROD ici est un bon signal, pas une garantie ; seul v1.0.56 (advisory lock) garantit la serialisation.

## 8. Conclusion technique (E6)

READY_DEV_ATOMIC_PROVED : DEV montre (1) plusieurs POST (4) pour le meme amazonMessageId ; (2) "Dedup lock acquired scope=amzmsg" sur chaque livraison ; (3) 1 message final ecomlg-001 ; (4) 2 skip idempotents pour les copies. La race PH-20.25-BIS est fermee au niveau applicatif par l'advisory lock transactionnel, prouve sur un VRAI message concurrent.

## 9. Non-regression (E7)

| Garantie | etat |
|---|---|
| API + jobs-worker DEV restarts | 0 |
| API + jobs-worker PROD restarts | 0 |
| jobs-worker DEV heartbeat | claimed=0 types=OUTBOUND_EMAIL_SEND (no job) |
| AMAZON_POLL lockedBy worker-1 (backend DB DEV) | 0 |
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 (inchange) |
| OutboundEmail | PENDING 1 / SENT 13 / FAILED 14 (inchange) |
| MarketplaceOutboundMessage | 2 (inchange) |
| outbound reply / guard validation | non touches (message entrant uniquement) |
| IA / escalades / assignment / statuts / historique | non touches |
| cleanup / retry / trigger / fake event | 0 |

## 10. AI feature parity / anti-regression

Phase read-only (SELECT + logs). L'inbound a cree 1 message Inbox legitime (vrai message acheteur) ; aucun outbound declenche (Job/OutboundEmail inchanges). jobs-worker reste scope OUTBOUND_EMAIL_SEND (ne claim pas AMAZON_POLL). Guard validation + pipeline outbound restaure (KEY-323) non touches.

## 11. Limites restantes

- PROD v1.0.55 ne contient pas l'advisory lock : la fermeture race PROD n'est PAS prouvee (ce resultat = signal favorable, non garantie).
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige -> chaque message reste dans 2 tenants (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des doublons existants : phase separee.

## 12. Recommandation promotion

Preuve DEV SUFFISANTE pour promouvoir v1.0.56 en PROD (l'advisory lock garantit la serialisation independamment du timing, contrairement a la dedup v1.0.55 defaite en PH-20.25-BIS). Prochain : GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.31.

## 13. Phrase cible

GO VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.30-BIS

STOP.
