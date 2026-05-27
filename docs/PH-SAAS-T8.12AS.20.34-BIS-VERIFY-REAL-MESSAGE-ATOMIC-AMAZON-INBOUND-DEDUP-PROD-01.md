# PH-SAAS-T8.12AS.20.34-BIS-VERIFY-REAL-MESSAGE-ATOMIC-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.34-BIS (VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP PROD)
> Environnement : PROD (read-only strict ; aucun trigger/replay/fake/mutation)

## 1. Verdict

GO VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.34-BIS

Classement = READY_PROD_ATOMIC_PROVED. Le vrai message Ludovic ("Ok, j'imagines que tout le monde s'en fou !!!", amazonIds.messageId A007902311OYREHWN5VKM) est arrive en PROD en **4 POST quasi-simultanes** (~14:05:11-12Z) portant le MEME amazonIds.messageId. Sous v1.0.56-prod (advisory lock PH-20.26) la concurrence a ete SERIALISEE : "Dedup lock acquired scope=amzmsg" sur chaque livraison ; pour le tenant ecomlg-001, 1 "Created message" (cmmpo4z4n38...) + **2 "Idempotent skip"** -> **DB PROD keybuzz_prod = 1 message / 1 conversation / 1 raw MIME** pour ecomlg-001. La 4e livraison = tenant ecomlg-motxke32 (cross-tenant, message distinct attendu, non corrige ici). C'est exactement le scenario qui produisait 2-3 messages sous v1.0.55 (PH-20.25-BIS) ; **la race Amazon inbound intra-tenant est demontree FERMEE en PROD sur un vrai message concurrent.** PROD strictement read-only, 0 mutation/trigger/fake.

## 2. Preflight runtime (E0)

| Env | Service | Image | Ready | Restarts | Verdict |
|---|---|---|---|---|---|
| PROD | keybuzz-backend (565fc9df9-5rptj) | v1.0.56-amazon-inbound-dedup-prod (digest 9689875c) | 1/1 | 0 | OK |
| PROD | jobs-worker (dcd95d488-b5ql6) | v1.0.56-amazon-inbound-dedup-prod (digest 9689875c) | 1/1 | 0 | OK |
| DEV | keybuzz-backend | v1.0.56-amazon-inbound-dedup-dev | - | - | inchange |
| DEV | jobs-worker | v1.0.56-amazon-inbound-dedup-dev | - | - | inchange |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 14:12Z.

## 3. Fenetre + body (E1)

Fenetre : start 2026-05-27T14:00:00Z -> now. Body recherche : "tout le monde" (sous-chaine du message Ludovic "Ok, j'imagines que tout le monde s'en fou !!!"). UI Paris 16:05:11 = 14:05:11 UTC, coherent.

## 4. DB PROD keybuzz_prod (E2) -- PREUVE

| tenantId | amazonMessageId | messageRows | conversationRows | rawMimeCount | firstAt | lastAt | verdict |
|---|---|---|---|---|---|---|---|
| ecomlg-001 | A007902311OYREHWN5VKM | 1 | 1 | 1 | 14:05:11Z | 14:05:11Z | DEDUP OK (1 message logique) |
| ecomlg-motxke32 | A007902311OYREHWN5VKM | 1 | 1 | 1 | 14:05:12Z | 14:05:12Z | cross-tenant distinct (attendu) |

Message ecomlg-001 : id cmmpo4z4n38b049898b2806b6, conversation cmmpnxtgye537a4bdbc3c6aaf, direction inbound, threadKey sc:A08467981VCU78NJADWD5, raw_mime_sha256 47618bc3... . 1 seule ligne malgre les redeliveries concurrentes.

## 5. Logs backend PROD (E3) -- PREUVE CONCURRENCE

4 POST /api/v1/webhooks/inbound-email a ~14:05. 4 MessageNormalizer source=AMAZON messageId=A007902311OYREHWN5VKM.

| timestamp | marker | tenantId | amazonMessageId | lockScope | action | verdict |
|---|---|---|---|---|---|---|
| 14:05:11Z | Dedup lock acquired | ecomlg-001 | A007902311... | amzmsg | Found existing conversation sc:... -> Created message cmmpo4z4n38... | 1ere copie creee |
| 14:05:12Z | Dedup lock acquired | ecomlg-motxke32 | A007902311... | amzmsg | Created message cmmpo4z4oo... (autre tenant) | cross-tenant distinct (attendu) |
| 14:05:1xZ | Dedup lock acquired | ecomlg-001 | A007902311... | amzmsg | Idempotent skip: already ingested | redelivery skippee |
| 14:05:1xZ | Dedup lock acquired | ecomlg-001 | A007902311... | amzmsg | Idempotent skip: already ingested | redelivery skippee |

4 lock acquisitions (3 ecomlg-001 + 1 ecomlg-motxke32) = 4 POST serialises. ecomlg-001 : 1 Created + 2 Idempotent skip. Aucune erreur transaction/advisory lock.

## 6. Cross-tenant / reply-to (E4)

| tenantId | recipient | amazonMessageId | messageRows | skippedLogs | verdict |
|---|---|---|---|---|---|
| ecomlg-001 | fan-out reply-to (4xfub8 + obsoletes) | A007902311OYREHWN5VKM | 1 | 2 | intra-tenant FERME (1 message) |
| ecomlg-motxke32 | as0yom | A007902311OYREHWN5VKM | 1 | 0 | cross-tenant distinct (non corrige, decision produit) |

Les 3 livraisons ecomlg-001 (correspondant aux reply-to 4xfub8 + obsoletes 3jcpvk/cp2hat) sont collapsees a 1 message par l'advisory lock. Le cross-tenant ecomlg-motxke32 reste 1 message distinct = comportement attendu, hors scope de ce patch.

## 7. Conclusion technique (E5)

READY_PROD_ATOMIC_PROVED : PROD montre (1) plusieurs POST (4) pour le meme amazonMessageId ; (2) "Dedup lock acquired scope=amzmsg" par livraison ; (3) 1 message final ecomlg-001 ; (4) 2 skip idempotents. La race PH-20.25-BIS est fermee au runtime PROD, prouvee sur un VRAI message concurrent (parite avec la preuve DEV PH-20.30-BIS).

## 8. Non-regression (E6)

| Garantie | etat |
|---|---|
| API + jobs-worker PROD restarts | 0 |
| jobs-worker heartbeat | claimed=0 types=OUTBOUND_EMAIL_SEND (no job) |
| AMAZON_POLL lockedBy worker-1 (backend DB PROD) | 0 |
| Job OUTBOUND_EMAIL_SEND / OutboundEmail / MOM | vides (0), coherents |
| outbound reply / guard validation | non touches (message entrant uniquement) |
| cleanup / retry / trigger / fake | 0 |
| DEV (API + jobs-worker) | v1.0.56-dev, restarts=0, inchange |

## 9. AI feature parity / anti-regression

Phase read-only (SELECT + logs). L'inbound a cree 1 message Inbox legitime cote ecomlg-001 (vrai message acheteur) ; aucun outbound declenche. jobs-worker reste scope OUTBOUND_EMAIL_SEND (ne claim pas AMAZON_POLL). Guard validation + pipeline outbound restaure (KEY-323) non touches. IA/escalades/assignment/statuts/historique non modifies.

## 10. Limites restantes

- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige -> chaque message reste dans 2 tenants (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : fan-out vers ecomlg-001 collapse cote dedup, mais retrait Seller Central reste a faire (reduit le bruit en amont).
- Cleanup des doublons existants (pre-v1.0.56) : phase separee.
- CONTRAINTE UNIQUE DB : durcissement differe (post-cleanup).

## 11. Recommandation suivante

GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD PH-SAAS-T8.12AS.20.35 : plan read-only de retrait des reply-to obsoletes 3jcpvk/cp2hat + reconciliation cross-tenant (4xfub8/as0yom), sans mutation. Le P0 KEY-323 (race inbound) est techniquement clos cote applicatif en PROD ; restent les leviers de bruit en amont (Seller Central) et le durcissement DB.

## 12. Phrase cible

GO VERIFY REAL MESSAGE ATOMIC AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.34-BIS

STOP.
