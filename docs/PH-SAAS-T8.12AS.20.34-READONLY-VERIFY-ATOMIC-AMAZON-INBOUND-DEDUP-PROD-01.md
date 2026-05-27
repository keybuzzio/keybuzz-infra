# PH-SAAS-T8.12AS.20.34-READONLY-VERIFY-ATOMIC-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.34 (READONLY VERIFY ATOMIC AMAZON INBOUND DEDUP PROD)
> Environnement : PROD (read-only strict ; aucun trigger/replay/fake/mutation)

## 1. Verdict

GO READONLY VERIFY ATOMIC AMAZON INBOUND DEDUP PROD ACTION_REQUIRED PH-SAAS-T8.12AS.20.34

Mode = ACTION_REQUIRED. Le patch atomique v1.0.56-amazon-inbound-dedup-prod est CONFIRME ACTIF au runtime PROD (imageID digest 9689875c sur API + jobs-worker, restarts=0). MAIS aucun vrai message Amazon inbound n'est arrive en PROD depuis le deploiement PH-20.33 (API pod start 2026-05-27T13:49:08Z ; verify a 13:59Z, fenetre ~10 min) : 0 message amazon cree (product DB keybuzz_prod), 0 POST /webhooks/inbound-email, 0 marqueur dedup. Conformement au cadrage (pas de fake webhook / replay / trigger), le skip live n'est PAS simule. La preuve de fermeture de la race en concurrence reelle a deja ete obtenue en DEV (PH-20.30-BIS : meme code/commit 78bfb94, 4 POST -> 1 Created + 2 Idempotent skip) ; il manque uniquement un vrai message PROD post-deploiement pour confirmer au runtime PROD.

## 2. Preflight runtime (E0)

| Service | Namespace | Image | Digest | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | sha256:9689875c...1dcdd2 | 1/1 | 0 | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | sha256:9689875c...1dcdd2 | 1/1 | 0 | OK |
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | - | - | - | inchange |
| jobs-worker | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | - | - | - | inchange |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 13:59Z. jobs-worker PROD JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP 49.13.35.167:25.

## 3. Heure de deploiement PH-20.33 (E1)

| Service | pod | startedAt | image | digest |
|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-565fc9df9-5rptj | 2026-05-27T13:49:08Z | v1.0.56-prod | sha256:9689875c...1dcdd2 |
| jobs-worker | jobs-worker-dcd95d488-b5ql6 | 2026-05-27T13:49:36Z | v1.0.56-prod | sha256:9689875c...1dcdd2 |

Borne post-deploiement = 2026-05-27T13:49:08Z.

## 4. Messages Amazon post-deploiement (E2) -- DB PROD keybuzz_prod

| Signal | Valeur | Verdict |
|---|---|---|
| messages amazon (amazonIds.messageId non null) crees >= 13:49:08Z | 0 | aucune ingestion live post-v1.0.56-prod |
| groupes (tenant + amazonIds.messageId) post-deploiement | 0 | n/a |
| groupes de doublons intra-tenant post-deploiement | 0 | aucun doublon (rien a deduper) |

## 5. Logs atomic dedup post-deploiement (E3)

| Recherche logs backend PROD depuis 13:49:08Z | Resultat |
|---|---|
| POST /api/v1/webhooks/inbound-email (Received inbound email) | 0 |
| Dedup lock acquired / Idempotent skip / Created message | 0 |
| erreur transaction / advisory lock | 0 |

Aucun trafic inbound a exercer -> aucune trace runtime de dedup encore disponible (attendu en ACTION_REQUIRED).

## 6. Cas ecomlg-001 (E4)

Aucun nouveau message ecomlg-001 (ni cross-tenant ecomlg-motxke32) post-deploiement. Reply-to obsoletes 3jcpvk/cp2hat : non observables sans trafic. Rien a evaluer tant qu'un vrai message n'est pas arrive.

## 7. Non-regression (E7)

| Garantie | etat |
|---|---|
| API + jobs-worker PROD restarts | 0 |
| jobs-worker heartbeat | claimed=0 types=OUTBOUND_EMAIL_SEND (no job) |
| AMAZON_POLL lockedBy worker-1 (backend DB PROD) | 0 |
| Job OUTBOUND_EMAIL_SEND / OutboundEmail / MOM | vides (0), inchanges |
| ecomlg-001 FR VALIDATED (guard outbound) | inchange (aucune mutation cette phase ; etat VALIDATED depuis PH-20.14AE) |
| outbound reply restaure (KEY-323 PH-20.14AE) | non touche |
| cleanup / retry / trigger / fake event / mutation | 0 |
| DEV (API + jobs-worker) | v1.0.56-dev inchange |

## 8. AI feature parity / anti-regression

Phase 100% read-only (SELECT + grep logs + kubectl get/logs/exec read). Aucune mutation, trigger, envoi. jobs-worker reste scope OUTBOUND_EMAIL_SEND (ne claim pas AMAZON_POLL). Le pipeline outbound restaure KEY-323 reste intact. Le patch atomique advisory lock (PH-20.26) est present et actif dans le binaire PROD en cours, pret a serialiser la prochaine ingestion concurrente.

## 9. Limites restantes

- Preuve runtime PROD de fermeture de la race = EN ATTENTE d'un vrai message inbound PROD (les redeliveries Amazon/mail-core arrivent generalement en plusieurs POST quasi-simultanes -> exercera l'advisory lock).
- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des doublons existants : phase separee.
- CONTRAINTE UNIQUE DB : durcissement differe (post-cleanup).

## 10. ACTION REQUISE (Ludovic)

1. Envoyer (ou faire envoyer par le compte test) un VRAI message acheteur Amazon vers le vendeur eComLG (tenant ecomlg-001), comme en PH-20.30-BIS. Aucune action CE.
2. Attendre l'arrivee/traitement (mail-core -> webhook PROD, generalement plusieurs POST quasi-simultanes du meme amazonIds.messageId).
3. Re-run verify read-only PH-20.34 : attendu en PROD =
   - log "Dedup lock acquired scope=amzmsg tenant=ecomlg-001" par livraison concurrente ;
   - 1 "Created message" + "Idempotent skip" pour les copies suivantes ;
   - DB keybuzz_prod : 1 message / 1 conversation par (tenant ecomlg-001, amazonIds.messageId) ;
   - cross-tenant ecomlg-motxke32 reste un message distinct (attendu, non corrige ici).

## 11. Next GO

Apres preuve runtime PROD (READY) : GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD PH-SAAS-T8.12AS.20.35 (plan read-only retrait reply-to obsoletes 3jcpvk/cp2hat + reconciliation cross-tenant, sans mutation).

## 12. Phrase cible

GO READONLY VERIFY ATOMIC AMAZON INBOUND DEDUP PROD ACTION_REQUIRED PH-SAAS-T8.12AS.20.34

STOP.
