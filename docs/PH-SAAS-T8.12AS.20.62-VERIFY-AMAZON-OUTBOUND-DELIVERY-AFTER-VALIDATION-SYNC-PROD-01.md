# PH-SAAS-T8.12AS.20.62-VERIFY-AMAZON-OUTBOUND-DELIVERY-AFTER-VALIDATION-SYNC-PROD-01

> Date : 2026-05-29
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.62 (verification livraison outbound Amazon reelle apres sync validation, flux produit)
> Environnement : PROD ; verification LECTURE SEULE uniquement (aucun build, docker push, deploy, kubectl apply, SQL manuel, SMTP direct, trigger bridge, OAuth, retry, envoi par CE)

## 1. Verdict

GO VERIFY AMAZON OUTBOUND DELIVERY AFTER VALIDATION SYNC PROD READY_DELIVERY_PROVED PH-SAAS-T8.12AS.20.62

L'outbound Amazon reel envoye par Ludovic le 28/05/2026 vers 20:10 CEST (18:10 UTC) pour le tenant
ecomlg-motxke32 est prouve techniquement de bout en bout, par lecture seule de la DB Product/API
(keybuzz_prod) et des logs du worker outbound PROD. La delivery est passee de bloquee a DELIVERED :
worker NON bloque sur la validation, From = adresse connecteur du tenant (jamais noreply@), transport
SMTP delivered, ET message visible cote Amazon (captures fournies par Ludovic). La cause racine
STATUS_SPLIT (KEY-323) est desormais corrigee bout-en-bout en PROD pour ecomlg-motxke32.

Cette phase n'a declenche AUCUN envoi, AUCUN retry, AUCUN SQL, AUCUNE mutation. L'envoi avait deja ete
realise par Ludovic via le flux produit (compte Amazon acheteur de test SWITA -> reponse depuis l'Inbox
KeyBuzz PROD). CE n'a fait que confirmer cet envoi existant en lecture seule.

## 2. Rappel UX

Il n'existe PAS de bouton de validation Amazon dans Settings > Channels. L'action utilisateur a ete un
envoi normal depuis l'Inbox sur une conversation Amazon de TEST (compte acheteur test de Ludovic), pas
un vrai client. Aucune instruction "cliquer valider dans Channels".

## 3. Preflight (E0)

| repo/service | attendu | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| bastion | install-v3 / 46.62.171.61 | install-v3 / IPv4 46.62.171.61 | - | OK |
| keybuzz-infra | main | main ec530f3 | dirty 0, ahead/behind 0/0 | OK |
| API PROD | v3.5.260-amazon-inbound-address-sync-prod | idem (pod keybuzz-api-cf778495d-pfmls) | restarts=0 | OK |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | idem (pod keybuzz-outbound-worker-7bfb4944c4-tnsl6) | restarts=2 (pre-existant 5j, heartbeat actif) | OK |

DB interrogee = keybuzz_prod (current_database confirme), via node + module pg in-pod (variables
d'environnement PG* deja presentes dans le pod API, aucune valeur de secret affichee). Runners node
temporaires ecrits dans /tmp du pod puis supprimes (rm). Aucun deploy/build/push/kubectl mutation.
as0yom VALIDATED re-confirme avant lecture.

## 4. Source / runtime contract outbound (E1)

| brique | preuve runtime | resultat |
|---|---|---|
| gate validation | log worker "[Guard] Amazon outbound config validated for ecomlg-motxke32" | gate present, satisfait, NON contourne |
| From connecteur | log worker "[Worker] Using From address: amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io" | From = adresse connecteur du tenant, PAS noreply@ |
| SMTP fallback Amazon | log "[EmailService] SMTP sending ... via mail.keybuzz.io:25" | envoi via SMTP mail-core (SP-API messaging desactive) |
| status transitions | outbound_deliveries status=delivered + delivered_at renseigne | transport positif prouve |

Le gate worker (validationStatus='VALIDATED' sur la product DB) est satisfait par as0yom desormais
VALIDATED (promu en PH-20.61). L'envoi n'a PAS contourne le gate ; il l'a franchi parce que le statut
est valide.

## 5. Snapshot BEFORE / contexte PROD

| signal | valeur |
|---|---|
| as0yom Product/API (ecomlg-motxke32 / amazon / FR) | validationStatus=VALIDATED, pipelineStatus=VALIDATED, marketplaceStatus=VALIDATED |
| as0yom emailAddress | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io |
| outbound_deliveries total (apres test) | 309 (baseline PH-20.61 before = 308) |
| outbound_deliveries ecomlg-motxke32 | 9 = 8 failed historiques + 1 delivered (l'envoi du test) |
| 8 failed historiques | provider=spapi, attempt_count=5, last_error="Amazon inbound address not validated...", next_retry_at=null (terminales) |

Les 8 deliveries failed historiques ont toutes next_retry_at=null : terminales, donc AUCUN auto-retry,
aucun envoi automatique a craindre du seul fait de la validation. Etat stable.

## 6. Cible test (E3)

| conversation / commande | tenant | canal | raison cible sure | verdict |
|---|---|---|---|---|
| conv cmmpml7i1z, commande 403-2003407-5310706 (switch TP-Link) | ecomlg-motxke32 | Amazon FR | compte Amazon ACHETEUR de TEST de Ludovic (SWITA), confirme par captures, pas un vrai client | OK |

## 7. Action user-assisted / flux produit (E4)

Action realisee par Ludovic (hors CE) le 28/05 vers 20:10 CEST :
1. Depuis son compte Amazon acheteur de TEST (SWITA), envoi d'un message au vendeur ecomlg-motxke32
   (storefront FR), creant la conversation de test (commande 403-2003407-5310706).
2. Depuis l'Inbox KeyBuzz PROD (tenant ecomlg-motxke32), reponse a cette conversation puis clic Envoyer.

Un seul envoi. CE n'a declenche aucun envoi, aucun retry, aucun SQL, aucun SMTP direct, aucun trigger
bridge.

## 8. Delivery / logs (E5)

Delivery reelle (unique nouvelle delivery) :

| champ | valeur |
|---|---|
| id | dlv-1779991815148-eeiyo0rxh |
| status | delivered |
| provider | SMTP_AMAZON_NONORDER |
| attempt_count | 1 |
| last_error | (vide) |
| created_at | 2026-05-28T18:10:15.187Z |
| delivered_at | 2026-05-28T18:10:17.386Z (+2s) |
| next_retry_at | null |
| conversation_id | cmmpml7i1z... |
| delivery_trace.orderId | 403-2003407-5310706 (= commande de la capture Amazon) |

Logs worker (acheteur masque <BUYER>) :
- [Worker] Processing dlv-1779991815148-eeiyo0rxh (provider: spapi, attempt: 1)
- [Worker] Matched inbound address for marketplace .fr. -> amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io
- [Guard] Amazon outbound config validated for ecomlg-motxke32: from=amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io
- [Worker] Using From address: amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io
- [EmailService] SMTP sending to Ludovic <BUYER>@marketplace.amazon.fr from amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io via mail.keybuzz.io:25
- [Worker] dlv-1779991815148-eeiyo0rxh delivered via SMTP_AMAZON_NONORDER

Aucune erreur "Amazon inbound address not validated" pour ce nouvel envoi (last_error vide en DB ; gate
"config validated" dans les logs). From = adresse connecteur du tenant, pas noreply@.

## 9. Snapshot AFTER / diff (E6)

| signal | before (ref PH-20.61) | after | delta | interpretation |
|---|---|---|---|---|
| as0yom Product/API | VALIDATED | VALIDATED | 0 | reste valide |
| outbound_deliveries ecomlg-motxke32 | 8 failed | 8 failed + 1 delivered = 9 | +1 delivered | la seule delivery du test |
| outbound_deliveries total | 308 | 309 | +1 | un seul envoi |
| deliveries creees depuis 2026-05-28 17:30Z | - | 1 (tenant ecomlg-motxke32 seul) | +1 | aucun autre tenant, aucun mass retry |
| 8 failed historiques | next_retry_at=null | next_retry_at=null | 0 | terminales, non rejouees |
| API PROD restarts | 0 | 0 | 0 | OK |

Anti-mass-retry confirme : sur la fenetre created_at >= 2026-05-28T17:30:00Z, il existe exactement
1 delivery, pour le seul tenant ecomlg-motxke32. Aucun autre tenant impacte. Les 8 historiques restent
terminales (non rejouees).

## 10. No fake metrics / no fake events

Une seule delivery creee, correspondant a l'unique envoi utilisateur reel. Aucun mass retry. Aucun fake
event marketing, aucun ai_suggestion_events, aucun ai_actions_ledger, aucun fake message ou fake
outbound_delivery genere par CE. Lecture seule stricte.

## 11. Seller Central / Amazon visibilite (E7)

Captures fournies par Ludovic :
- Vue acheteur Amazon (conversation avec eComLG, commande 403-2003407-5310706) : la reponse KeyBuzz du
  28 mai 2026 20:10 ("Bonjour Ludovic ... Cordialement, Ludovic GONTHIER, eComLG") est VISIBLE cote
  Amazon.
- Vue Inbox KeyBuzz (tenant ecomlg-motxke32) : la meme reponse envoyee.

20:10 CEST = 18:10 UTC, ce qui correspond exactement au delivered_at 18:10:17Z de la delivery
dlv-1779991815148-eeiyo0rxh. Worker delivered + visible Amazon = READY_DELIVERY_PROVED.

## 12. AI feature parity / anti-regression

| feature | source de verite | preuve runtime | verdict |
|---|---|---|---|
| worker outbound gate VALIDATED (PH-20.50/51) | gate validationStatus='VALIDATED' | log "config validated", gate satisfait, NON contourne | OK |
| sync statut validation (PH-20.52) | promote-only Backend -> Product | as0yom reste VALIDATED | OK |
| trigger sync PROD (PH-20.61) | bridge flux produit | promotion conservee | OK |
| From connecteur tenant | adresse inbound du tenant | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io | OK |
| AI Assist notification skip (PH-20.42-TER/49) | classifier message-level | present runtime API PROD v3.5.260, non touche | OK |
| advisory lock backend amzmsg (PH-20.26/34-BIS) | backend | non touche | OK |
| bouton validation Channels | n'existe pas | aucun invente | OK |
| Client UI / Autopilot / billing / tracking | - | non touches | OK |

## 13. Reconciliation des artefacts de handoff

| artefact | verdict porte | statut reel | explication |
|---|---|---|---|
| tmp/PH-20.62_CE_RETURN.md | ACTION_REQUIRED_TEST_TARGET | PERIME | ecrit AVANT le test de Ludovic ; ne connaissait que les deliveries <= 08:00 (dlv-...r9tmg83ka failed). Etait correct a cet instant. |
| tmp/PH-2062-report.md | READY_DELIVERY_PROVED | EXACT | seul l'id etait tronque (dlv-177999181514 vs complet dlv-1779991815148-eeiyo0rxh) ; timing, commande, From confirmes par DB + logs |
| captures Ludovic | visibilite Amazon | CONFIRME | face Amazon visible de la meme delivery (reponse 20:10) |

Conclusion : le test a bien ete execute apres l'ecriture du RETURN, et a reussi de bout en bout. Le
present rapport fige le verdict reel READY_DELIVERY_PROVED.

## 14. Limites

- Preuve etablie sur 1 conversation de test (compte acheteur test de Ludovic). Le comportement est
  generalisable (gate satisfait + From connecteur + SMTP delivered), deja confirme en parallele par le
  connecteur ecomlg-001 (PH-20.50).
- Les 8 deliveries failed historiques (vrais acheteurs, 2 a 3 jours) restent failed/terminales
  (next_retry_at=null). Les re-livrer serait une decision business du vendeur, hors scope de cette
  phase, et exigerait un GO dedie (contenu potentiellement perime).

## 15. Compensation / rollback

- Pas de rollback DB. Le message de test envoye par Ludovic est reel et reste trace (delivered).
- Pas de retry en boucle. Pas de deploy rollback dans cette phase (lecture seule).

## 16. Prochain GO recommande

GO READONLY CLOSE AMAZON OUTBOUND VALIDATION STATUS SPLIT PROD PH-SAAS-T8.12AS.20.63 : cloture
read-only du dossier KEY-323 (recap de la chaine PH-20.50 -> 20.62, etat final as0yom, decision sur le
backlog des 8 failed historiques), sans mutation.

## 17. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.62_CE_RETURN.md

## 18. Phrase cible

GO VERIFY AMAZON OUTBOUND DELIVERY AFTER VALIDATION SYNC PROD READY_DELIVERY_PROVED PH-SAAS-T8.12AS.20.62

STOP.
