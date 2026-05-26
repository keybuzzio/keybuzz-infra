# PH-SAAS-T8.12AS.20.16-READONLY-AMAZON-INBOUND-DUPLICATE-MESSAGES-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.16 (READONLY RCA doublons inbound Amazon)
> Environnement : PROD lecture seule (SELECT + logs ; aucune mutation, aucun retry, aucun trigger)

## 1. Verdict

GO READONLY AMAZON INBOUND DUPLICATE MESSAGES PROD READY PH-SAAS-T8.12AS.20.16

Les doublons inbound Amazon observes le 2026-05-26 (~13:37 / 13:52 / 16:32 UTC) sur le seller ecomlg sont caracterises et la cause est prouvee par DB + logs applicatifs. Trois mecanismes cumulatifs, chacun avec preuve :
- B (double adresse/tenant) : DEUX adresses inbound Amazon FR VALIDATED actives pour le meme seller reel ecomlg -> ecomlg-001/token 4xfub8 et ecomlg-motxke32/token as0yom. Chaque message buyer est livre aux deux et ingere sous DEUX tenants.
- A/D (livraisons multiples) : Amazon/SES delivre PLUSIEURS copies du meme message buyer, chacune avec un SES Message-ID distinct, a la meme adresse en ~1 s.
- C (dedup applicatif insuffisant) : l'ingestion dedup par threadKey mais (a) le chemin order:<ref> (marqueurs Amazon absents, generic_cleanup) ne retrouve pas la conversation existante et en cree une nouvelle a chaque copie ; (b) absence de contrainte unique (tenant_id, thread_key) -> deux copies quasi-simultanees creent deux conversations (race). La dedup par externalId est structurellement inoperante car externalId = SES Message-ID, unique par livraison.

Aucun patch, aucune suppression, aucune fusion, aucune mutation. ecomlg-001 FR 4xfub8 reste VALIDATED, P0 KEY-323 non rouvert.

## 2. Preflight (E0)

| Repo/Service | Branche/Runtime | HEAD/Image | dirty | verdict |
|---|---|---|---|---|
| keybuzz-backend | main | d27f4a5 | 1 (working copy bastion) | OK lecture |
| keybuzz-api | ph147.4/source-of-truth | 38c048c0 | 223 (working copy bastion) | OK lecture |
| keybuzz-infra | main | 4e3755c = origin | 0 | OK |
| backend PROD (keybuzz-backend + jobs-worker) | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | ready | OK |
| api PROD | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | ready | OK |

bastion install-v3 / 46.62.171.61 confirme. Aucune commande write prevue ni executee.
Note : pod keybuzz-backend demarre 2026-05-26T15:16Z -> logs applicatifs de la fenetre 13:37-13:56 non disponibles dans le pod courant ; preuve principale = DB (persistante) + logs de l'evenement 16:32 (postface au demarrage du pod).

## 3. Fenetre analysee (E1) - ExternalMessage produit (DB keybuzz)

Fenetre 2026-05-26 13:00-15:30 UTC. 10 ExternalMessage type AMAZON.

| createdAt UTC | tenantId | externalId (SES msg-id, abrege) | receivedAt | thread (conversation) |
|---|---|---|---|---|
| 13:37:59.681 | ecomlg-motxke32 | 0102019e64819ce9... | 13:37:57 | elie / sc:A04326063DUUE7GG369VX |
| 13:37:59.817 | ecomlg-001 | 0102019e64819bed... | 13:37:57 | elie / sc:A04326063DUUE7GG369VX |
| 13:37:59.927 | ecomlg-001 | 0102019e64819f14... | 13:37:58 | elie / sc:A04326063DUUE7GG369VX |
| 13:52:44.735 | ecomlg-001 | 0102019e648f1d5c... | 13:52:42 | Mehdi / sc:A02189252V7WL6DTID17N |
| 13:52:44.774 | ecomlg-motxke32 | 0102019e648f1e60... | 13:52:42 | Mehdi / sc:A02189252V7WL6DTID17N |
| 13:52:44.792 | ecomlg-001 | 0102019e648f205e... | 13:52:43 | Mehdi (2e copie 001) |
| 13:56:12.796 | ecomlg-motxke32 | 0102019e64924ca9... | 13:56:11 | Ludovic / sc:A08467981VCU78NJADWD5 |
| 13:56:13.037 | ecomlg-001 | 0102019e64924eac... | 13:56:11 | Ludovic / sc:A08467981VCU78NJADWD5 |
| 13:56:13.045 | ecomlg-001 | 0102019e64924baf... | 13:56:11 | Ludovic (2e copie 001) |
| 15:00:29.546 | ecomlg-001 | 0102019e64cd2421... | 15:00:27 | Anthony / sc:A0450685XSQIONDDQW0Y (ES) |

ExternalMessage doublon par externalId : 0 groupe (chaque livraison a un SES Message-ID distinct).

## 4. Analyse mail-core (E2)

| Constat | preuve | verdict |
|---|---|---|
| mail-core dans le cluster | aucun pod mail/smtp/inbound, aucun ingress inbound.keybuzz.io | hors cluster (relais SES->webhook externe) |
| livraisons multiples vers backend | logs [Webhook] : POST distincts avec messageId SES differents pour le meme threadKey | PROUVE cote webhook |
| postfix maillog par recipient | non lu (mail-core hors cluster, pas d'acces RO etabli sans secret) | PARTIAL (non bloquant : preuve webhook suffit) |

## 5. Analyse backend PROD logs (E3) - evenement 16:32 (disponible)

| marqueur log | threadKey | action | verdict |
|---|---|---|---|
| [Webhook] to: ...motxke32...as0yom + to: ...001...4xfub8 | - | meme batch, 2 tenants | B confirme |
| [MessageNormalizer] method=amazon_markers, threadKey=sc:A08467981... | sc:<threadId> | dedup par marqueurs Amazon | OK |
| [InboxConversation] Found existing conversation by threadKey: sc:A08467981... | sc:... | append message (threaded=true) | dedup sc: fonctionne quand espace dans le temps |
| [MessageNormalizer] method=generic_cleanup, threadKey=order:408-6501671-5129133, amazonIds=undefined | order:<ref> | marqueurs Amazon absents | - |
| [InboxConversation] Created new conversation: ...4k... puis ...ff..., threadKey: order:408-6501671-5129133 | order:... | DEUX nouvelles conversations pour le meme order: | C PROUVE (chemin order: ne dedup pas) |

## 6. DB doublons (E4) - conversations + messages (DB keybuzz)

Conversations dupliquees (meme thread_key) :

| thread_key | n | conversationIds | tenants | order_ref | cause |
|---|---|---|---|---|---|
| sc:A04326063DUUE7GG369VX | 3 | cmmpmok97s / cmmpmok90j / cmmpmok97o | 001, motxke32, 001 | 402-4474059-9728309 | B (2 tenants) + race intra-001 (2 conv) |
| sc:A02189252V7WL6DTID17N | 3 | cmmohk01(27 avr) / cmmpmp37y0 / cmmpmp37ya | -, motxke32, 001 | 407-9819118-7936329 | B + thread re-cree (ancienne conv avril) |
| order:408-6501671-5129133 | 2 | cmmpmusu4k / cmmpmusuff | (16:32) | 408-6501671 | C (chemin order: cree nouvelle conv par copie) |

Messages doublon par raw_mime_sha256 : 0 groupe (chaque copie a un MIME distinct -> dedup par hash inoperante). Exemple message-level : conversation cmmpmp37yac (Mehdi/001) contient 2 messages inbound (cmmpmp37z4 + cmmpmp380h) = 2 copies appended dans une meme conversation dedupee.

## 7. Inbound addresses (E5) - DB backend keybuzz_backend (table inbound_addresses Prisma)

| tenantId | country | token | emailAddress | validationStatus | lastInboundAt | role |
|---|---|---|---|---|---|---|
| ecomlg-001 | FR | 4xfub8 | amazon.ecomlg-001.fr.4xfub8@inbound.keybuzz.io | VALIDATED | 2026-05-26T16:32:38.449Z | PROD restaure KEY-323 |
| ecomlg-motxke32 | FR | as0yom | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io | VALIDATED | 2026-05-26T16:32:38.062Z | 2e tenant/adresse (cause B) |
| ecomlg-001 | BE/ES/IT/PL | ub0m1q/zul3wn/hz4alx/36ngpp | ... | PENDING | null | non actif |
| autres tenants (compta-ecomlg, ludo-gonthier, bon-kb, ecomlg-mo4h93e7) | FR/ES | divers | ... | PENDING | null | non actif |

Le token 3jcpvk evoque dans le contexte n'existe PAS dans la table : le doublon reel est as0yom/ecomlg-motxke32 (FR VALIDATED). DB produit keybuzz.inbound_addresses = 0 ligne pour ces tokens (la source de verite des adresses est la DB backend). Deux connexions Amazon FR distinctes VALIDATED (cmmsdn4fs ecomlg-001, cmotxn8b6 ecomlg-motxke32) -> le meme seller ecomlg a deux comptes/adresses keybuzz.

## 8. Classification RCA (E6)

| Classe | retenue | preuve |
|---|---|---|
| A double reception mail-core | PARTIEL | logs [Webhook] = POST multiples distincts ; postfix par recipient non lu |
| B double token/adresse inbound | OUI (dominant) | 2 adresses FR VALIDATED 4xfub8/ecomlg-001 + as0yom/ecomlg-motxke32, lastInboundAt identiques |
| C dedup applicatif insuffisant | OUI | logs : order:<ref> cree une conv par copie ; 2 conv meme sc: thread_key (race) ; externalId=SES msg-id unique |
| D retry Amazon/SES | OUI (contributeur) | SES Message-IDs distincts pour le meme buyer message, receivedAt a ~1 s d'intervalle |
| E autre | NON | - |

Cause exacte = combinaison B x (A/D) x C : deux adresses validees pour un meme seller, Amazon/SES livrant plusieurs copies (msg-id distincts), et une dedup applicative qui (chemin order:) ne reconnait pas l'existant et (chemin sc:) n'est pas race-safe, sans contrainte unique (tenant_id, thread_key) ni dedup par identifiant de message Amazon stable (amazonIds.messageId).

## 9. Non-regression (E7)

| Garantie | etat |
|---|---|
| ecomlg-001 FR 4xfub8 VALIDATED | confirme (E5) |
| outbound reply restaure | non touche (aucune lecture/mutation outbound) |
| Job / OutboundEmail / MarketplaceOutboundMessage | non modifies |
| retry / trigger / fake webhook / fake event | 0 |
| mutation DB (UPDATE/DELETE/INSERT/Prisma write) | 0 (SELECT only) |
| suppression / fusion conversations ou messages | 0 |
| Agent KeyBuzz / IA / escalades / playbooks / assignment / status workflow | non touches |

## 10. No fake metrics / no fake events (E8)

0 fake event, 0 fake webhook, 0 fake pageview, 0 synthetic conversion, 0 email genere, 0 message genere, 0 metric artificielle, 0 mutation DB.

## 11. Risques

- Tant que deux adresses FR VALIDATED existent pour le meme seller (B), tout message buyer restera duplique cross-tenant. Decision produit requise : un seul tenant/adresse actif par seller reel, ou separation explicite.
- Le chemin order:<ref> (C) cree des conversations dupliquees des qu'Amazon livre >1 copie sans marqueurs sc: -> correction source (upsert sur (tenant_id, thread_key) + dedup par amazonIds.messageId + contrainte unique) necessaire.
- Risque data : conversations/messages dupliques deja en base ; un eventuel cleanup devra etre une phase dediee SEPAREE (hors scope ici), jamais un DELETE ad hoc.

## 12. Prochaine phrase GO recommandee

GO SOURCE FIX AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.17 (correction source dedup : amazonIds.messageId + upsert (tenant_id, thread_key) + contrainte unique ; DEV d'abord), puis decision produit B (adresse unique par seller) et plan de cleanup data dedie. Ne pas rouvrir KEY-323 P0.

## 13. Interdits respectes

Aucun build, docker push, deploy, rollout, restart, kubectl set/patch/edit, mutation DB, suppression/fusion, retry outbound, trigger validation, fake event, lecture/affichage de secret. Bastion install-v3 / 46.62.171.61 exclusif. credentials/ et secrets/ non touches.

## 14. Phrase cible

GO READONLY AMAZON INBOUND DUPLICATE MESSAGES PROD READY PH-SAAS-T8.12AS.20.16

STOP.
