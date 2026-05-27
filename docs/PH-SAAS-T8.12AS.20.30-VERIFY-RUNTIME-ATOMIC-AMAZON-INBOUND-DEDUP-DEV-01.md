# PH-SAAS-T8.12AS.20.30-VERIFY-RUNTIME-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.30 (VERIFY RUNTIME ATOMIC AMAZON INBOUND DEDUP)
> Environnement : DEV (read-only ; PROD strictement intact ; aucun trigger/replay/fake)

## 1. Verdict

GO VERIFY ATOMIC AMAZON INBOUND DEDUP DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.30

Mode de preuve = ACTION_REQUIRED. Le patch atomique v1.0.56 (advisory lock PH-20.26) est CONFIRME VIVANT au runtime DEV (markers dist presents dans le pod en cours). La preuve structurelle de la race pre-patch est FORTE (11 groupes de doublons reels sous v1.0.55 dans la base DEV keybuzz). MAIS aucun declenchement de concurrence n'est observable : 0 message Amazon inbound arrive en DEV depuis le deploiement v1.0.56 (pod start 12:33:24Z ; verify 12:45-12:50Z). Le replay controle (Mode B) est hors scope car la route webhook DEV exige le secret INBOUND_WEBHOOK_KEY (interdit de toucher aux secrets) ET un payload JSON reconstruit (enveloppe fabriquee interdite). Conclusion : la fermeture de la race ne peut etre prouvee au runtime sans un VRAI message inbound. Action requise = Ludovic envoie un vrai message acheteur Amazon vers le vendeur test eComLG (tenant ecomlg-001) ; mail-core dual-poste vers backend-dev v1.0.56 ; puis re-run verify read-only. DEV product DB (keybuzz) et PROD (keybuzz_prod) sont des bases DISTINCTES -> un futur test DEV n'atteint pas PROD.

## 2. Preflight runtime (E0)

| Service | Namespace | Image | Digest | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | sha256:ed3d6c1a...f81b | 1/1 | 0 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | sha256:ed3d6c1a...f81b | 1/1 | 0 | OK |
| keybuzz-backend | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | (inchange) | Running | 0 | INTACT |
| jobs-worker | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | (inchange) | Running | 0 | INTACT |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 12:45Z. jobs-worker DEV JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP 49.13.35.167:25 secure=false. API pod start 2026-05-27T12:33:24Z.

## 3. Patch vivant au runtime DEV (preuve dist dans le pod)

| Marker (pod keybuzz-backend-7c98d5c544-q56f5) | Attendu | Resultat |
|---|---|---|
| dist/modules/webhooks/inboxConversation.service.js : pg_advisory_xact_lock | >=1 | 1 |
| dist .. : "Dedup lock acquired" | >=1 | 1 |
| dist .. : "Idempotent skip" | >=1 | 1 |
| dist/modules/webhooks/inboundDedup.js : computeInboundDedupLockScope | >=1 | 2 |

Markers de log exacts du patch (source 78bfb94 = image deployee) :
- "[InboxConversation] Dedup lock acquired scope=<prefixe> tenant=<tenantId>"
- "[InboxConversation] Idempotent skip: Amazon message already ingested for tenant <tenantId> (stable key present)"
- "[InboxConversation] Created message: <id>, threaded=<bool>"

## 4. Mode de preuve (E1)

| Piste | Resultat |
|---|---|
| Preuve naturelle live (messages Amazon DEV depuis deploiement v1.0.56) | ABSENTE : 0 POST /webhooks/inbound-email, 0 marker ingestion, 0 message cree depuis 12:33:24Z |
| Replay controle Mode B faisable ? | NON dans le scope |
| - payload Amazon reel capture complet (enveloppe JSON webhook) ? | NON disponible (seul du raw MIME existe en DB ; reconstruire {from,to,messageId,body,...} = enveloppe fabriquee, interdit) |
| - rejouable sans secret expose ? | NON : POST /webhooks/inbound-email exige header x-internal-key == INBOUND_WEBHOOK_KEY (secret K8s via envFrom secretRef ; interdit de toucher aux secrets) |
| - DEV only ? | oui (mais bloque par les 2 points ci-dessus) |

Decision E1 = ni preuve naturelle, ni replay dans le scope -> ACTION_REQUIRED. Aucun webhook fabrique, aucun payload invente.

## 5. Architecture confirmee (determinant pour la securite du test)

| Element | DEV | PROD | Note |
|---|---|---|---|
| product DB (conversations/messages) | keybuzz @ 10.0.0.10:5432 | keybuzz_prod @ 10.0.0.10:5432 | bases DISTINCTES, meme hote |
| transport inbound | mail-core/Postfix -> webhook | idem (dual-post DEV ET PROD) | un vrai message hit DEV + PROD |
| consequence | test DEV ecrit dans keybuzz seulement | keybuzz_prod jamais touche par un test DEV | PROD intact garanti |

Le dual-post mail-core (backend-dev ET backend-prod) implique qu'un prochain vrai message acheteur sera AUSSI poste vers DEV v1.0.56 -> c'est le declencheur naturel Mode A.

## 6. Preuve structurelle DB (E5, read-only base DEV keybuzz)

| Signal | Valeur | Verdict |
|---|---|---|
| messages crees depuis le deploiement (>= 12:33:00Z) | 0 | aucune ingestion live post-v1.0.56 |
| messages portant amazonIds.messageId stable | 299 | cle de dedup PEUPLEE |
| groupes (tenant_id + amazonIds.messageId) avec >1 message | 11 | signature race pre-patch (sous v1.0.55) |

Top groupes de doublons (tous tenant ecomlg-001, tous AVANT le deploiement v1.0.56 12:33Z) :

| amazonIds.messageId | msg_rows | conv_rows | created_at |
|---|---|---|---|
| A100493337L42M1RERYX6 | 2 | 1 | 2026-05-27T10:44:50Z |
| A00271791C6FBHMZH5CAM | 2 | 1 | 2026-05-27T10:02:25Z |
| A00365023D73G5MXSHMM1 | 2 | 1 | 2026-05-27T09:55:25Z |
| A04182872PQEL4KVALNOR | 3 | 1 | 2026-05-27T09:19:27Z |
| A10347493QI7N1U0REUU3 | 2 | 1 | 2026-05-27T08:29:40Z |
| A007339713VP35QN3Z82J | 3 | 1 | 2026-05-27T06:29:51Z |
| A089466823REET8SHWBIX | 2 | 1 | 2026-05-26T16:12:48Z |
| A072088936ZFUK4R8598C | 2 | 1 | 2026-05-26T13:56:11Z |

Lecture : ces groupes sont les vrais messages Amazon dual-postes vers backend-dev et ingere sous v1.0.55 (race active, SELECT-puis-skip sans verrou) -> 2-3 messages logiques pour 1 meme amazonIds.messageId dans 1 conversation. C'est exactement le defaut que le verrou advisory de v1.0.56 doit fermer. A100493337L42M1RERYX6 (PH-20.25-BIS) et A007339713VP35QN3Z82J (PH-20.21B) sont les memes incidents prouves cote PROD, refletes ici cote DEV par le dual-post.

## 7. Log evidence (E4)

| Recherche logs backend DEV depuis 12:33Z | Resultat |
|---|---|
| Dedup lock acquired | 0 (aucune ingestion) |
| Idempotent skip | 0 |
| Created message / Found existing conversation | 0 |
| erreur transaction / advisory lock | 0 |

Aucun trafic inbound a exercer -> aucune trace runtime de dedup encore disponible (attendu en ACTION_REQUIRED).

## 8. Non-regression (E6)

| Garantie | etat |
|---|---|
| API + jobs-worker DEV restarts | 0 |
| jobs-worker heartbeat | claimed=0 types=OUTBOUND_EMAIL_SEND (no job this poll) |
| AMAZON_POLL lockedBy worker-1 (backend DB DEV) | 0 |
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 (inchange vs PH-20.29) |
| OutboundEmail | PENDING 1 / SENT 13 / FAILED 14 (inchange) |
| MarketplaceOutboundMessage | 2 (inchange) |
| outbound reply / guard validation | non touches |
| IA / escalades / assignment / statuts / historique | non touches |
| PROD (keybuzz-backend + jobs-worker) | v1.0.55-prod, restarts=0, INTACT |
| cleanup / fusion / suppression / DB write manuel | 0 |
| fake event / fake metric / message synthetique | 0 |

## 9. AI feature parity / anti-regression

Phase 100% read-only (SELECT + grep + kubectl get/logs/exec read). Aucune mutation, aucun trigger, aucun envoi. jobs-worker reste scope OUTBOUND_EMAIL_SEND (ne claim pas AMAZON_POLL). Le pipeline outbound restaure KEY-323 (PH-20.14AE) reste intact. Le patch atomique est present et actif dans le binaire en cours d'execution (markers dist), pret a serialiser la prochaine ingestion concurrente.

## 10. Limites restantes

- Preuve runtime de la fermeture de la race = EN ATTENTE d'un vrai message inbound DEV (Mode A).
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8/as0yom) : non corrige (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des 11 groupes de doublons existants : phase separee (jamais DELETE ad hoc).

## 11. ACTION REQUISE (Ludovic)

1. Envoyer (ou faire envoyer par le compte test, ex. Switaa) un VRAI message acheteur Amazon vers le vendeur eComLG (tenant ecomlg-001), comme en PH-20.14Z2. Aucune action CE.
2. mail-core dual-poste vers backend-dev v1.0.56 (et backend-prod v1.0.55, sans impact sur la preuve DEV).
3. Re-run verify read-only PH-20.30 : attendu en DEV (base keybuzz + logs pod) =
   - log "Dedup lock acquired scope=amzmsg tenant=ecomlg-001" (1 fois par livraison concurrente) ;
   - log "Created message" pour la 1ere copie ;
   - log "Idempotent skip: Amazon message already ingested" pour les redeliveries ;
   - DB : msg_rows = 1 et conv_rows = 1 pour le nouveau (tenant ecomlg-001, amazonIds.messageId) ;
   - cross-tenant (ecomlg-motxke32) reste un message distinct = comportement attendu non corrige ici.

## 12. Next GO

- Si la preuve runtime confirme la fermeture : GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.31.
- Sinon (anomalie residuelle) : analyse PARTIAL avant promotion.

## 13. Phrase cible

GO VERIFY ATOMIC AMAZON INBOUND DEDUP DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.30

STOP.
