# PH-SAAS-T8.12AS.20.37-READONLY-RCA-AMAZON-NOTIFICATION-DEDUP-GAP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.37 (READONLY RCA AMAZON NOTIFICATION DEDUP GAP)
> Environnement : PROD read-only (SELECT/logs uniquement ; aucune mutation)

## 1. Verdict

GO READONLY RCA AMAZON NOTIFICATION DEDUP GAP PROD READY PH-SAAS-T8.12AS.20.37

RCA claire et CORRIGE le cadrage PH-20.36. Les emails recus via 3jcpvk/cp2hat (batch 14:36-14:37Z + historique) NE SONT PAS des doublons : sur 7 jours, ecomlg-001 = 41 messages notification avec 41 raw_mime DISTINCTS et 41 rawPreview DISTINCTS, et le test de groupe de doublons exacts (tenant+threadKey+rawSubject+rawPreview) retourne ZERO. Ce sont des NOTIFICATIONS Amazon Seller Central (donotreply, subject "Notification de compte vendeur Amazon", orderRef null, pas d'amazonIds) genuinement differentes a chaque livraison. Il n'y a donc PAS de probleme de dedup a resoudre ; le fallback thread-scope qui "ne collapse pas" est CORRECT (collapser couperait des notifications distinctes). Le vrai sujet est une question de CLASSIFICATION : ces notifications donotreply sont ingerees comme conversations client (message_source=HUMAN), arment un SLA 2h, et alimentent la surface de generation de suggestions IA. Un classifier dedie (classifyNoReplyPlatformNotification, PH-20.12B) EXISTE deja et matche exactement ces emails (subtype AMAZON_SELLER_CENTRAL_NOTIFICATION), mais il n'est branche QUE sur l'engine Autopilot (skip draft/LLM/KBActions) ; il n'est PAS applique a l'ingestion (SLA/message_source/visibilite) ni a la surface assist/generation de suggestions. Impact mesure : sur 7 jours, 44 conversations portent une notification (36 pures, 8 mixtes), ~72 KBActions debites sur les conversations PURES de notification (reason=ai_generation), 136 suggestions generees jamais actionnees, et un SLA arme sur chaque notification. Recommandation : etendre le gate du classifier existant a l'ingestion et a la generation de suggestions (pas de nouveau helper de dedup). PROD strictement read-only.

## 2. Preflight (E0)

| Element | Etat |
|---|---|
| Bastion | install-v3 / 46.62.171.61 |
| date | 2026-05-27 14:49Z |
| PROD API keybuzz-backend | v1.0.56-amazon-inbound-dedup-prod, restarts=0 |
| PROD jobs-worker | v1.0.56-amazon-inbound-dedup-prod, restarts=0 |
| DEV | v1.0.56-amazon-inbound-dedup-dev (inchange) |
| Repo keybuzz-api bastion | branche ph147.4/source-of-truth, HEAD 38c048c0 |

## 3. Caracterisation des notifications sans amazonIds (E1)

Structure metadata (commune aux notifications) : source=AMAZON, rawFrom, orderRef, threadKey, rawPreview, rawSubject, extractionMethod=generic_cleanup, parserVersion, encodingFixed, marketplaceLinks. PAS de bloc headers (donc PAS de Message-ID / In-Reply-To / References stockes). message_source=HUMAN. Pas de bloc amazonIds (amazonIds=undefined).

Batch 14:36-14:37Z (conversation cmmpo62v5ib853977ab2af257, ecomlg-001) :

| createdAt (Z) | subject | orderRef | preview_md5 | raw_mime_sha256 (8) |
|---|---|---|---|---|
| 14:36:06 | Notification de compte vendeur Amazon | null | 9e45c22b... | 93cc95ec |
| 14:36:06 | Notification de compte vendeur Amazon | null | 04889370... | 1d29de99 |
| 14:36:06 | Notification de compte vendeur Amazon | null | 9ad12aa5... | ab54f814 |
| 14:36:51 | Notification de compte vendeur Amazon | null | 57954434... | e6a25b3b |
| 14:36:54 | Notification de compte vendeur Amazon | null | 44f01839... | 0da3c645 |
| 14:37:00 | Notification de compte vendeur Amazon | null | c2777dd2... | 1f2574f4 |
| 14:37:03 | Notification de compte vendeur Amazon | null | e69e5ae9... | c2025438 |

7 preview_md5 DISTINCTS + 7 raw_mime DISTINCTS => 7 notifications de contenu different, regroupees dans 1 seule conversation par threadKey hash:714e46e17d88. customer_name de la conversation = "Notifications Amazon Seller Central (Ne pas repondre) donotreply", channel=amazon, status=open, priority=normal, escalation_status=none.

## 4. Volumetrie (E2)

Notifications (source=AMAZON, sans amazonIds), 7 jours :

| tenant | msgs | convs | distinct threadKeys | distinct raw_mime | distinct previews | duplicateGroups exacts |
|---|---|---|---|---|---|---|
| ecomlg-001 | 41 | 23 | 22 | 41 | 41 | 0 |
| ecomlg-motxke32 | 16 | 14 | 13 | 16 | 16 | 0 |
| switaa-sasu-mnc1ouqu | 7 | 7 | 6 | 7 | 7 | 0 |

Total ~64 messages / 7j sur 3 tenants (~9/j). Par jour ecomlg-001 : 27/05=15, 26/05=6, 25/05=4, 24/05=3, 23/05=2, 22/05=4, 21/05=6, 20/05=1. duplicateGroups (memes tenant+threadKey+rawSubject+rawPreview, count>1) = 0 partout => AUCUN doublon exact a collapser.

## 5. Impact UI / IA / SLA (E3)

Conversations notification, 7 jours (SELECT sur conversations + tables ai_*) :

| Dimension | Constat |
|---|---|
| Visible Inbox | OUI (channel=amazon, conversations creees ; customer_name = donotreply Seller Central) |
| Statut | 18 open + 26 resolved (44 convs au total portant une notification) |
| message_source | HUMAN pour les 64 (classees comme message client) |
| SLA | sla_due_at arme (now+120min) sur les 44 conversations ; 2 assignees |
| Escalade | ai_human_approval_queue=0, ai_case_state=0, ai_followup_cases=0, playbook_suggestions=0, ai_execution_audit=0 (aucune escalade declenchee) |
| Suggestions IA | ai_suggestion_events=172 (86 type=reply + 86 type=status, action=none) ; derniere 27/05 09:19Z |
| KBActions | ai_actions_ledger=17 (reason=ai_generation) totalisant ~101.67 KBActions (cost_usd attribue=0) |

Attribution PURE vs MIXTE (8 conversations contiennent AUSSI un vrai message buyer porteur d'amazonIds) :

| bucket | convs | ai_generation rows | KBActions | suggestion_events |
|---|---|---|---|---|
| pure_notification | 36 | 12 | 72.19 | 136 |
| mixed (buyer+notif) | 8 | 5 | 29.48 | 36 |

Le gaspillage NON AMBIGU = 72.19 KBActions / 7j + 136 suggestions sur les 36 conversations PURES de notification. Les 8 conversations mixtes peuvent legitimement consommer pour le vrai message buyer (non compte comme gaspillage). Le skip Autopilot PH-20.12B (engine.ts step 6.5, cout 0) protege l'engine Autopilot mais PAS cette surface assist/generation (reason=ai_generation) ni l'ingestion.

## 6. Recherche d'une cle stable de dedup (E4)

| CandidateKey | Stable across duplicates ? | Risque faux positif | Risque faux negatif | Reco |
|---|---|---|---|---|
| Message-ID mail | N/A | N/A | N/A | INDISPONIBLE (headers non stockes) |
| In-Reply-To / References | N/A | N/A | N/A | INDISPONIBLE (headers non stockes) |
| raw_mime_sha256 | NON (distinct par livraison) | faible | TOTAL | inutile |
| body hash / rawPreview | NON (distinct par notification) | ELEVE (collapse notifs distinctes) | eleve | dangereux |
| rawSubject normalise | NON (sujet generique repete) | TRES ELEVE | eleve | dangereux |
| threadKey (hash:...) | trop grossier (collapse des notifs differentes) | TRES ELEVE | n/a | deja utilise pour le threading, pas pour dedup |

Conclusion E4 : aucune cle stable de dedup sure n'existe, et AUCUNE n'est necessaire (0 doublon exact). Le helper extractStableAmazonNotificationKey n'est PAS recommande. Le levier correct est la CLASSIFICATION (isAmazonSellerCentralNotification deja couvert par classifyNoReplyPlatformNotification), pas la dedup.

## 7. Decision produit recommandee (E5)

Type unique observe : AMAZON_SELLER_CENTRAL_NOTIFICATION (donotreply, sans amazonIds, BUYER_HANDLE_RX faux). Reco :

| Lever | Decision recommandee |
|---|---|
| Filtrer completement (drop) | NON (conserver pour audit/visibilite) |
| Afficher mais dedupliquer | SANS OBJET (pas de doublon) |
| Conserver tel quel | NON (pollue SLA + Inbox + KBActions) |
| Exclure IA/suggestions | OUI (etendre le gate noReplyClassifier a la surface assist/generation) |
| Ne pas armer le SLA | OUI (sla_due_at NULL pour un email donotreply non repondable) |
| message_source | SYSTEM (ou type NOTIFICATION), pas HUMAN |
| Visibilite Inbox | conserver visible mais segregue (non-unread, sans SLA) ou vue "Notifications" -- CHOIX PRODUIT Ludovic |

Garde-fous absolus : decision SENDER-driven uniquement ; BUYER_HANDLE_RX (@marketplace.amazon.) gagne toujours (un vrai buyer ne doit JAMAIS etre classe no-reply) ; jamais au niveau conversation (8 conversations mixtes) ; ne jamais masquer un message porteur d'amazonIds.

## 8. Proposition de patch source (E6) -- sans patcher

Reutiliser le classifier existant src/services/noReplyClassifier.ts (classifyNoReplyPlatformNotification). PAS de nouveau helper de dedup.

Points d'integration proposes (DEV d'abord) :
1. Ingestion src/modules/inbound/routes.ts (les 2 chemins d'insert, l.99 et l.389) : si isNoReply => message_source=SYSTEM, NE PAS armer sla_due_at (laisser NULL / sla_state neutre), poser metadata.platformNotification=true. NE PAS bloquer le message (conserve pour audit). NE PAS modifier le SLA d'une conversation qui porte deja un message buyer.
2. Surface assist/generation de suggestions (chemin emettant ai_suggestion_events type reply/status + ai_actions_ledger reason=ai_generation) : appliquer le meme gate pour SKIP la generation sur un message classe no-reply => supprime les ~72 KBActions/sem de gaspillage et les 136 suggestions inutiles.

Tests requis : etendre src/tests/ph119-tests.ts au niveau ingestion (notification => pas de SLA, message_source SYSTEM ; vrai buyer => SLA arme, HUMAN ; conversation mixte => SLA du buyer preserve) ; verifier que le skip generation n'affecte aucun message porteur d'amazonIds ni un handle @marketplace.amazon.

Rollout : DEV (build-from-git, tag immuable, GitOps, validation negative-only + QA Inbox) puis PROD sur GO explicite Ludovic. Aucune migration DB, aucun cleanup historique dans ce patch.

## 9. Non-regression (E7)

| Garantie | Etat |
|---|---|
| Messages buyer (amazonIds) couverts par amzmsg (PH-20.26) | inchange (verrou advisory actif, prouve PH-20.34-BIS) |
| outbound reply KEY-323 | intact |
| jobs / outbound | inchanges (aucun outbound declenche par les notifs entrantes) |
| API + jobs-worker PROD restarts | 0 |
| mutation DB / cleanup / trigger / fake / replay | 0 (phase 100% SELECT + logs + git read) |
| DEV | v1.0.56-dev inchange |

## 10. AI feature parity / no fake metrics

Phase read-only : aucune modification IA/suggestions/escalades/assignment/statuts/historique. Aucun webhook/email/message/event/metric/conversion genere. Le P0 KEY-323 (race buyer-message intra-tenant, amazonIds) reste CLOS. Le constat de ce rapport (notifications donotreply non gatees a l'ingestion + a la generation de suggestions) est DISTINCT du P0 et candidat a une phase de patch separee. Aucune reco de filtrage ne masque un vrai message client sans preuve (gardes BUYER_HANDLE_RX + niveau message + amazonIds).

## 11. Limites / risques restants

- Retrait Seller Central 3jcpvk/cp2hat : effectivite a re-verifier apres propagation Amazon (PH-20.36, hors scope ici).
- Cross-tenant ecomlg-001 / ecomlg-motxke32 : decision produit differee (candidate PH-20.38).
- Cleanup data historique (conversations/SLA notifications deja creees) + contrainte unique DB : phases differees.
- Attribution KBActions sur conversations mixtes (29.48) non comptee comme gaspillage (peut servir le buyer) : le patch devra mesurer le gain sur les conversations PURES.

## 12. Recommandation / prochain GO

Le gap n'est pas une dedup mais une classification non branchee. Prochaine phase recommandee : GO SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION DEV PH-SAAS-T8.12AS.20.38 (brancher classifyNoReplyPlatformNotification a l'ingestion et a la generation de suggestions : message_source=SYSTEM, SLA non arme, skip generation ; tests ph119 etendus ; DEV d'abord, PROD sur GO). La decision cross-tenant (ecomlg-001 / ecomlg-motxke32) peut etre traitee en parallele dans une phase distincte (READONLY AMAZON CROSS_TENANT DECISION PROD).

## 13. Phrase cible

GO READONLY RCA AMAZON NOTIFICATION DEDUP GAP PROD READY PH-SAAS-T8.12AS.20.37

STOP.
