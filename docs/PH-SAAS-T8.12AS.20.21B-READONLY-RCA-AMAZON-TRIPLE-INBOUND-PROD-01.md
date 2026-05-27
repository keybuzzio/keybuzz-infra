# PH-SAAS-T8.12AS.20.21B-READONLY-RCA-AMAZON-TRIPLE-INBOUND-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.21B (READONLY RCA TRIPLE INBOUND AMAZON)
> Environnement : PROD read-only (SELECT + logs uniquement ; aucune mutation/trigger/fake)

## 1. Verdict

GO READONLY RCA AMAZON TRIPLE INBOUND PROD READY PH-SAAS-T8.12AS.20.21B

Cause prouvee par DB produit + logs webhook PROD. Le triple visible dans l'Inbox eComLG (ecomlg-001) = 3 messages reels, MEME conversation, MEME amazonIds.messageId, crees par 3 livraisons mail distinctes routees vers le MEME tenant ecomlg-001 via 3 adresses reply-to differentes (4xfub8 + 3jcpvk + cp2hat). Cause intra-tenant dominante. Une 4e copie existe sous un autre tenant (ecomlg-motxke32 / as0yom) = doublon cross-tenant distinct, NON visible dans l'Inbox eComLG. PROD tourne v1.0.54 (patch dedup PH-20.17 ABSENT). Aucune mutation/trigger/fake. PROD intact, P0 outbound non rouvert.

## 2. Preflight runtime (E0)

| Env | Service | Image | Ready | Restarts | Verdict |
|---|---|---|---|---|---|
| PROD | keybuzz-backend (hqvnn) | v1.0.54-amazon-validation-pipeline-prod | true | 0 | OK |
| PROD | jobs-worker (2vj8x) | v1.0.54-amazon-validation-pipeline-prod | true | 0 | OK |
| PROD | amazon-orders-worker | v1.0.40-...-prod | true | 4 | pre-existant, hors scope |
| PROD | keybuzz-api (tlwgp) | v3.5.257-autopilot-no-reply-kbactions-prod | true | - | proprietaire product DB |
| DEV | keybuzz-backend + jobs-worker | v1.0.55-amazon-inbound-dedup-dev | true | 0 | informatif (non touche) |

Bastion install-v3 / 46.62.171.61 (verifie). DB produit keybuzz lue via PRODUCT_DATABASE_URL du pod backend PROD (SELECT only).

## 3. Les occurrences reelles (E1)

Recherche body ilike '%je ne veux pas annuler%'. 4 messages, tous created_at 2026-05-27 06:29:51Z, MEME amazonIds.messageId A007339713VP35QN3Z82J, MEME threadKey sc:A08467981VCU78NJADWD5, MEME orderRef 403-2003407-5310706, sender "Ludovic 43vfy537czcw8nq+...@marketplace.amazon.fr".

| messageId | conversationId | tenantId | channel | raw_mime_sha256 (8) | amazonMessageId | threadKey |
|---|---|---|---|---|---|---|
| cmmpnopk54fbac65764819760 | cmmpml7hy973b1706b3f49631 | ecomlg-001 | amazon | 880408e3 | A007339713VP35QN3Z82J | sc:A08467981VCU78NJADWD5 |
| cmmpnopk566d3c61595b0bc61 | cmmpml7hy973b1706b3f49631 | ecomlg-001 | amazon | a93a3333 | A007339713VP35QN3Z82J | sc:A08467981VCU78NJADWD5 |
| cmmpnopk5if76acbd11ef01f9 | cmmpml7hy973b1706b3f49631 | ecomlg-001 | amazon | df074bb6 | A007339713VP35QN3Z82J | sc:A08467981VCU78NJADWD5 |
| cmmpnopk0u016884ec4a912a0 | cmmpml7i1z7009a32c30c5de1 | ecomlg-motxke32 | amazon | 5237d2b7 | A007339713VP35QN3Z82J | sc:A08467981VCU78NJADWD5 |

raw_mime_sha256 DISTINCT par copie (4 MIME differents) -> dedup par raw_mime_sha256 structurellement inoperante.

## 4. Doublon DB vs UI (E2)

| groupKey | count | tenantIds | conversationIds | verdict |
|---|---|---|---|---|
| ecomlg-001 / amazon / A007339713VP35QN3Z82J | 3 | ecomlg-001 | 1 (cmmpml7hy) | A : 3 lignes DB, 1 conversation = TRIPLE INTRA-TENANT (le visible eComLG) |
| ecomlg-motxke32 / amazon / A007339713VP35QN3Z82J | 1 | ecomlg-motxke32 | 1 (cmmpml7i1z) | C-bis : 4e copie cross-tenant, autre Inbox (non visible eComLG) |

Verdict : duplication DB reelle (pas un bug de rendu UI). Le triple = 3 messages DB dans 1 conversation du tenant ecomlg-001.

## 5. Chemin mail reel (E3) - sans supposer SES

4 POST /api/v1/webhooks/inbound-email a time=1779863392918 / 393055 / 393108 / 393147 (= 2026-05-27 06:29:52.918 .. 06:29:53.147Z, fenetre ~229 ms), reqId 5vy/5vz/5w0/5w1, source IP = 10.244.151.128 / 10.244.95.0 / 10.244.78.197 / 10.244.36.194 (toutes IPs INTERNES cluster = poster mail-core, PAS des IPs SES externes).

| # | composant | source IP | messageId Amazon (body) | status |
|---|---|---|---|---|
| POST 1 (06:29:52.918) | webhook backend | 10.244.151.128 (interne) | A007339713VP35QN3Z82J | Found existing conv sc: |
| POST 2 (06:29:53.055) | webhook backend | 10.244.95.0 (interne) | A007339713VP35QN3Z82J | Found existing conv sc: |
| POST 3 (06:29:53.108) | webhook backend | 10.244.78.197 (interne) | A007339713VP35QN3Z82J | Found existing conv sc: |
| POST 4 (06:29:53.147) | webhook backend | 10.244.36.194 (interne) | A007339713VP35QN3Z82J | Found existing conv sc: |

Recipients (To) observes dans les logs pour amazon FR eComLG (le mapping exact POST<->recipient n'est PAS persiste par message ; il est INFERE par coherence de comptage 4 POST = 4 messages = 4 recipients distincts) :
- amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io -> tenant ecomlg-001 (adresse VALIDATED actuelle)
- amazon.ecomlg-001.fr.3jcpvk@inbound.keybuzz.io -> tenant ecomlg-001 ("lastInboundAt matched 0 inbound address" = token obsolete absent de inbound_addresses, tenant derive du localpart)
- amazon.ecomlg-001.fr.cp2hat@inbound.keybuzz.io -> tenant ecomlg-001 (idem, token obsolete)
- amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io -> tenant ecomlg-motxke32

3 recipients -> ecomlg-001 + 1 -> ecomlg-motxke32 = exactement les 3+1 messages constates en DB (E1/E2). 4x "Found existing conversation by threadKey: sc:A08467981VCU78NJADWD5", 0x "Created new conversation", 0x "Idempotent skip" (v1.0.54 sans dedup message). Les 4 copies source Amazon ont des MIME distincts (boundaries Part_321411/321414/347658/347664, series SPC-EUAmazon-...912/...913/...914/...916).

Conclusion obligatoire :
- KeyBuzz transport entrant = mail-core / Postfix -> POST webhook backend (source = IPs internes cluster 10.244.x.x, PAS des IPs SES externes). Multi-livraison = mail-core relaie 1 POST par email Amazon recu.
- Amazon sender/header = Amazon expedie via SES (PROUVE : inbound_addresses.lastInboundMessageId du 4xfub8 = "0102019db094ced0-...@eu-west-1.amazonses.com-prod" ; le Message-ID SES est UNIQUE par email). Le contenu body porte amazonIds.messageId stable (identique aux 4 copies).
- Le mot SES : prouve cote EXPEDITION Amazon (eu-west-1.amazonses.com), mais ce n'est NI le transport entrant KeyBuzz NI le mecanisme de dedup. Cause de la multiplicite = emails Amazon multiples (multi-adresse) relayes par mail-core, PAS une redelivery SES de KeyBuzz.

## 6. Metadata Amazon (E4)

| messageId | amazonMessageId | externalId(meta) | rawMimeSha (8) | threadKey | extractionMethod | verdict |
|---|---|---|---|---|---|---|
| cmmpnopk54.. | A007339713VP35QN3Z82J | absent (non persiste) | 880408e3 | sc:A08467981VCU78NJADWD5 | amazon_markers | cle stable presente |
| cmmpnopk56.. | A007339713VP35QN3Z82J | absent | a93a3333 | sc:A08467981VCU78NJADWD5 | amazon_markers | cle stable presente |
| cmmpnopk5i.. | A007339713VP35QN3Z82J | absent | df074bb6 | sc:A08467981VCU78NJADWD5 | amazon_markers | cle stable presente |
| cmmpnopk0u.. | A007339713VP35QN3Z82J | absent | 5237d2b7 | sc:A08467981VCU78NJADWD5 | amazon_markers | cross-tenant motxke32 |

ExternalMessage pour ce thread/order = 0 (le chemin inbound-email ecrit conversations/messages, PAS ExternalMessage qui est le chemin SP-API). Le SES Message-ID (unique/livraison) n'est PAS persiste dans message.metadata ; seul amazonIds.messageId (stable) l'est -> c'est la bonne cle de dedup.

## 7. Adresses inbound actives (E5)

inbound_addresses amazon FR (6). Pertinentes pour eComLG :

| tenantId | token | emailAddress | validationStatus | lastInboundAt |
|---|---|---|---|---|
| ecomlg-001 | 4xfub8 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | VALIDATED | 2026-04-21 |
| ecomlg-motxke32 | as0yom | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io | PENDING | null |

Tokens 3jcpvk et cp2hat (ecomlg-001 FR) NE sont PAS dans inbound_addresses (obsoletes) mais restent configures cote Amazon comme reply-to -> Amazon y livre encore, et parseInboundAddress route au tenant ecomlg-001 (tenant derive du localpart, pas du token). D'ou 3 livraisons -> ecomlg-001. La double inscription cross-tenant (4xfub8 ecomlg-001 + as0yom ecomlg-motxke32) ajoute la 4e copie.

## 8. Impact de v1.0.55 / PH-20.17 (E6)

| Cause | v1.0.55 corrige ? | Preuve | Reste a corriger |
|---|---|---|---|
| Dedup message keyee sur Message-ID SES (unique/livraison) en v1.0.54 | OUI (sequentiel) | PH-20.17 re-key sur amazonIds.messageId stable, scope tenant ; les 3 msg ecomlg-001 ont meme amazonIds.messageId + meme tenant -> collapse 3->1 | - |
| Triple intra-tenant ecomlg-001 (3 msg, 1 conv) | OUI en sequentiel ; RISQUE RACE | les 4 POST en 229 ms ; dedup = SELECT-puis-skip SANS contrainte unique -> non race-safe (SELECT-SELECT-INSERT-INSERT possible) | contrainte unique DB (tenant_id, amazonIds.messageId ou thread_key) pour GARANTIR 1 message |
| 4e copie cross-tenant (ecomlg-motxke32) | NON | idempotence tenant-scopee ne fusionne pas entre tenants | decision produit : 1 adresse/tenant unique par seller reel |
| Adresses reply-to obsoletes 3jcpvk/cp2hat cote Amazon | NON | tokens absents de inbound_addresses, encore livres par Amazon | nettoyage cote Amazon Seller Central + archivage adresses |

Reponse chiffree : si v1.0.55 etait en PROD, le triple visible ecomlg-001 passerait de 3 a 1 message (2 evites) dans le cas sequentiel. La copie motxke32 (autre tenant) resterait. Le triple est INTRA-TENANT ; le cas global est MIXTE (intra-tenant visible + cross-tenant cache).

## 9. RCA finale (E7)

Cause dominante du TRIPLE VISIBLE = **A (livraisons mail multiples intra-tenant)**, declenchee par un facteur **B (multi-adresse)** : Amazon livre le meme message buyer (meme amazonIds.messageId) a 3 adresses reply-to differentes (4xfub8 + 3jcpvk + cp2hat) qui mappent toutes au tenant ecomlg-001, chacune relayee par mail-core en 1 POST webhook ; la dedup message v1.0.54 (keyee Message-ID SES unique/livraison) ne deduplique pas -> 3 messages dans 1 conversation (le threadKey sc: deduplique correctement la CONVERSATION). NON cause C (pas de multi-conversation intra-tenant ; sc: a trouve l'existante). NON cause D au sens strict de la creation (sequentiel observe), mais RISQUE D (race) pour la robustesse de v1.0.55. NON cause E (duplication DB reelle, pas un rendu UI). Facteur **B cross-tenant** = 4e copie sous ecomlg-motxke32 (double inscription du meme seller reel), distinct du triple.

Chaque conclusion est prouvee : E1/E2 (DB), E3 (logs webhook 4 POST + Found existing), E4 (metadata amazonIds), E5 (adresses + tokens obsoletes), E7 derive de E3+E5.

## 10. Non-regression (E8)

| Garantie | etat |
|---|---|
| ecomlg-001 FR 4xfub8 validationStatus | VALIDATED (inchange) |
| outbound reply restaure (PH-20.14AE) | non touche (aucune ecriture) |
| jobs/outbound counts | non touches (aucune mutation) |
| retry / trigger / fake webhook | 0 |
| PROD restarts backend + jobs-worker | 0 / 0 |
| DEV | non touche (informatif seulement) |
| Phase | SELECT + kubectl logs uniquement |

## 11. Recommandation / prochain GO

1. **GO PROMOTE v1.0.55 PROD (PH-20.22+)** : NECESSAIRE (corrige le bug de keying Message-ID -> amazonIds.messageId) ; collapse le triple intra-tenant 3->1 en sequentiel. NON SUFFISANT seul (race + cross-tenant). DEV avant PROD deja fait (v1.0.55 actif DEV).
2. **GO SOURCE FIX / DB UNIQUE CONSTRAINT** : ajouter une contrainte unique (tenant_id, amazonIds.messageId) ou (tenant_id, thread_key+messageId) sur le DB produit (SQL brut, PAS Prisma) pour garantir l'idempotence sous redelivery quasi-simultanee (les 4 POST en 229 ms exposent une race). A sequencer APRES cleanup data.
3. **GO DATA CLEANUP PLAN + decision produit** : (a) cross-tenant ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom = meme seller reel -> 1 adresse/tenant unique ; (b) adresses reply-to obsoletes 3jcpvk/cp2hat cote Amazon Seller Central a retirer ; (c) cleanup des doublons existants (jamais DELETE ad hoc). Hors P0, phases dediees.

## 12. Phrase cible

GO READONLY RCA AMAZON TRIPLE INBOUND PROD READY PH-SAAS-T8.12AS.20.21B

STOP.
