# PH-SAAS-T8.12AS.20.63-READONLY-CLOSE-AMAZON-OUTBOUND-VALIDATION-STATUS-SPLIT-PROD-01

> Date : 2026-05-29
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.63 (cloture read-only / synthese finale Amazon outbound validation status split)
> Environnement : PROD ; LECTURE SEULE stricte (aucune mutation runtime/DB, aucun envoi, retry, build, deploy, docker, kubectl apply, trigger bridge, OAuth ; rapport docs-only + commentaires Linear, statuts inchanges)

## 1. Verdict

GO READONLY CLOSE AMAZON OUTBOUND VALIDATION STATUS SPLIT PROD READY PH-SAAS-T8.12AS.20.63

La cause racine STATUS_SPLIT qui bloquait les reponses Amazon de KeyBuzz pour ecomlg-motxke32/as0yom
est corrigee en PROD, prouvee de bout en bout (PH-20.61 sync + PH-20.62 delivery reelle delivered), et
confirmee read-only dans cette phase : Product/API as0yom VALIDATED, Backend as0yom READY/VALIDATED,
delivery dlv-1779991815148-eeiyo0rxh delivered, aucune nouvelle erreur de validation depuis la preuve.
Le sujet est techniquement clos cote applicatif pour ce perimetre. Les 8 deliveries failed historiques
restent terminales (next_retry_at=null) et NE sont PAS rejouees : leur traitement eventuel est une
decision business separee, hors de cette phase.

Aucune mutation, aucun envoi, aucun retry, aucun changement de statut Linear dans cette phase.

## 2. Preflight read-only (E0)

| repo/service | attendu | reel | dirty/restarts | verdict |
|---|---|---|---|---|
| bastion | install-v3 / 46.62.171.61 | install-v3 / IPv4 46.62.171.61 | - | OK |
| kube context | kubernetes-admin@kubernetes | idem | - | OK |
| keybuzz-infra | main, HEAD origin | main f3b52a8 | dirty 0, ahead/behind 0/0 | OK |
| keybuzz-api | ph147.4/source-of-truth contient 798db37c | branche OK, contient 798db37c | - | OK |
| API PROD | v3.5.260-amazon-inbound-address-sync-prod | idem (pod keybuzz-api-cf778495d-pfmls), deploy spec = pod | restarts=0 | OK |
| Client PROD | v3.5.259-ai-assist-notification-scope-prod | idem | - | OK |
| Backend PROD | v1.0.56-amazon-inbound-dedup-prod | idem | - | OK |
| outbound-worker PROD | v3.5.165-escalation-flow-prod | idem (pod keybuzz-outbound-worker-7bfb4944c4-tnsl6) | restarts=2 (pre-existant) | OK |

Runtime equality PH-20.60 conservee (deploy spec image = pod image = v3.5.260). Aucun deploy/build/push.
Lectures via node + module pg in-pod (variables PG* / DATABASE_URL deja presentes, aucune valeur secret
affichee ; runners /tmp des pods supprimes).

## 3. Timeline / reconciliation des preuves (E1)

| phase | finding | preuve | statut final |
|---|---|---|---|
| PH-20.50 | RCA outbound : ecomlg-001 OK (From connecteur), ecomlg-motxke32 bloque AVANT SMTP | logs worker DEV+PROD | cause = config tenant, pas bug code |
| PH-20.51 | cause racine = STATUS_SPLIT : Backend VALIDATED, Product/API PENDING (lue par worker) | gate worker validationStatus='VALIDATED' | identifiee |
| PH-20.52 | patch source API : helper normalizeInboundValidationStatus, sync Backend -> Product, promote-only (jamais downgrade) | commit api 798db37c, tests 23/23 | patch valide |
| PH-20.55 / 20.56 | patch applique DEV + verifie runtime DEV | pod DEV markers + promote-only | DEV OK |
| PH-20.58 / 20.59 / 20.60 | build/push/apply API PROD v3.5.260 | digest sha256:778f7556c5aa187be21b8a72a5246594c83e561c68abfaa053600fa7cbda43b8 | runtime PROD actif |
| PH-20.61 | trigger bridge flux produit/BFF (user-assisted, HTTP 200) | as0yom Product/API PENDING/PENDING -> VALIDATED/VALIDATED ; VALIDATED 8->9, PENDING 5->4 | sync fait |
| PH-20.62 | vrai outbound Amazon prouve | delivery dlv-1779991815148-eeiyo0rxh DELIVERED, From connecteur, gate validated, capture Amazon visible | READY_DELIVERY_PROVED |

Coherence verifiee : timestamps (created 18:10:15Z / delivered 18:10:17Z = 20:10 CEST de la capture),
IDs (dlv-1779991815148-eeiyo0rxh, order 403-2003407-5310706) et From (as0yom) concordent entre DB, logs
worker et captures Ludovic. L'ancien verdict ACTION_REQUIRED_TEST_TARGET du fichier retour PH-20.62 est
PERIME : il a ete ecrit AVANT le test de Ludovic (ne connaissait que les deliveries <= 08:00). Le rapport
final PH-20.62 (READY_DELIVERY_PROVED, commit infra f3b52a8) est la source de verite la plus recente.
Aucune preuve contradictoire posterieure.

## 4. Etat final read-only DB/runtime (E2)

| signal | attendu | observe | verdict |
|---|---|---|---|
| Product/API as0yom (ecomlg-motxke32/amazon/FR) | VALIDATED | validationStatus=VALIDATED, pipelineStatus=VALIDATED, marketplaceStatus=VALIDATED | OK |
| Product/API as0yom emailAddress | adresse connecteur | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io | OK |
| inbound_addresses counts | VALIDATED 9 / PENDING 4 (total 13) | VALIDATED 9 / PENDING 4 / total 13 | OK (conforme PH-20.61 after) |
| delivery dlv-1779991815148-eeiyo0rxh | delivered | status=delivered, provider=SMTP_AMAZON_NONORDER, attempt_count=1, last_error null, delivered_at 2026-05-28T18:10:17.386Z, orderId 403-2003407-5310706 | OK |
| deliveries ecomlg-motxke32 par statut | 8 failed + 1 delivered | failed 8 / delivered 1 | OK |
| deliveries ecomlg-motxke32 creees apres preuve (>18:10:17Z) | 0 | 0 | OK (aucun nouveau failed validation) |
| Backend as0yom | VALIDATED | inbound_addresses validation_status=VALIDATED | OK |
| Backend connection ecomlg-motxke32 amazon | READY | inbound_connections status=READY | OK |
| worker erreurs "Amazon inbound address not validated" (6h) | 0 | 0 | OK |
| API PROD restarts | 0 | 0 | OK |
| outbound-worker restarts | 2 (pre-existant) | 2 | OK (inchange) |

Backend (source) et Product/API (lue par le worker) sont desormais tous deux VALIDATED : le split est
resorbe pour as0yom. Derniere activite worker pour ce tenant = la delivery reussie a 18:10:17Z ; aucune
erreur de validation posterieure.

## 5. Backlog des 8 deliveries failed historiques (E3)

| categorie | count | etat | recommandation |
|---|---|---|---|
| failed sur conversation de TEST cmmpml7i1z (compte SWITA) | 3 | terminales (next_retry=null), datees 28/05 06:12-08:00Z | MOOT : la reponse finale sur cette meme conversation a ete delivered en PH-20.62 (18:10Z) ; pas de replay |
| failed sur conversations ACHETEURS REELS (4 conversations : cmmpir54mg, cmmpgup49g, cmmpgvv0kc, cmmpik8yxq) | 5 | terminales (next_retry=null), datees 25/05 11:06-13:59Z (~3-4 jours) | NE PAS rejouer automatiquement ; decision business par conversation/contenu ; phase dediee + GO explicite si envoi souhaite |

Caracteristiques communes des 8 : provider=spapi, attempt_count=5, next_retry_at=null (terminales,
AUCUN auto-retry possible), last_error="Amazon inbound address not validated...". Emails acheteurs
masques. Aucun risque de replay tardif automatique.

Decision de cloture sur le backlog :
- ne PAS rejouer automatiquement ;
- conserver la trace en DB (aucune suppression) ;
- les 3 deliveries de la conversation test sont superflues (reponse deja delivered) ;
- pour les 5 deliveries des 4 conversations acheteurs reels : si le vendeur souhaite (re)contacter ces
  acheteurs, ouvrir une phase dediee avec revue humaine cible par cible (contenu potentiellement perime
  apres plusieurs jours), priorisation et GO explicite -> GO READONLY REVIEW HISTORICAL AMAZON FAILED
  DELIVERIES PROD PH-SAAS-T8.12AS.20.64.

## 6. No side-effect / no fake events (E4)

| signal | reference PH-20.62 | observe PH-20.63 | delta | interpretation |
|---|---|---|---|---|
| outbound_deliveries total | 309 | 309 | 0 | aucune delivery creee |
| outbound_deliveries ecomlg-motxke32 | 9 (8 failed + 1 delivered) | 9 (8 failed + 1 delivered) | 0 | aucun envoi/retry |
| deliveries creees depuis 2026-05-28 17:30Z | 1 (ecomlg-motxke32 seul) | 1 (ecomlg-motxke32 seul) | 0 | aucun mass retry, aucun autre tenant |
| inbound_addresses (VALIDATED/PENDING/total) | 9 / 4 / 13 | 9 / 4 / 13 | 0 | aucune mutation statut |
| as0yom validationStatus | VALIDATED | VALIDATED | 0 | inchange |
| API PROD / worker restarts | 0 / 2 | 0 / 2 | 0 | aucun restart cause par la phase |

Phase strictement lecture seule : aucun outbound_delivery, aucun message, aucun ai_suggestion_events,
aucun ai_actions_ledger, aucun job, aucun deploy, aucun restart genere par cette phase. Aucun fake
event/metric/KBActions.

## 7. AI feature parity / anti-regression

| feature | source de verite | preuve read-only | verdict |
|---|---|---|---|
| worker outbound gate VALIDATED (PH-20.50/51) | validationStatus='VALIDATED' | gate satisfait pour as0yom, non contourne | OK |
| sync statut validation promote-only (PH-20.52) | normalizeInboundValidationStatus | as0yom VALIDATED, jamais de downgrade observe | OK |
| trigger sync PROD (PH-20.61) | bridge flux produit | as0yom reste VALIDATED | OK |
| delivery From connecteur (PH-20.62) | adresse inbound tenant | amazon.ecomlg-motxke32.fr.as0yom@inbound.keybuzz.io, jamais noreply@ | OK |
| AI Assist notification skip (PH-20.42-TER/49) | classifier message-level | API PROD v3.5.260, non touche | OK |
| generation AI Assist + KBActions (PH-20.46-QUATER) | - | non touches | OK |
| advisory lock Amazon inbound amzmsg (PH-20.26/34-BIS) | backend | non touche | OK |
| bouton validation Channels | n'existe pas | aucun invente | OK |
| Client UI / Autopilot / escalade / playbooks / billing / tracking | - | non touches | OK |

## 8. Risques restants / recommandations futures

- Le backlog des 5 deliveries failed sur acheteurs reels = decision business, PAS un bug technique actif.
- Hardening possible (phases dediees, non bloquantes) :
  - alerting sur status split Backend/Product (detecter une divergence validationStatus entre les 2 DB) ;
  - alerte sur outbound failure reason "Amazon inbound address not validated" (signaler tot un connecteur
    non synchronise) ;
  - visibilite Admin/UX de l'etat de reconciliation des statuts inbound ;
  - rappel : il n'existe pas de bouton de validation Amazon dans Channels ; l'action utilisateur reste
    retirer/reconnecter via OAuth, puis verifier la synchronisation DB/runtime.

## 9. Decision de cloture

- Statut technique : STATUS_SPLIT corrige en PROD ; patch API runtime actif (v3.5.260) ; as0yom Product/API
  VALIDATED ; Backend READY/VALIDATED ; outbound reel delivered ; From connecteur correct ; aucune erreur
  de validation gate -> KEY-323 techniquement clos cote applicatif pour ce perimetre.
- Statut backlog historique : 8 failed non rejouees ; pas de replay automatique ; decision business
  separee si besoin.
- Statuts Linear : commentaire de cloture technique uniquement ; statuts INCHANGES dans cette phase
  read-only. Toute transition de statut Linear = instruction explicite / phase separee.

## 10. Linear / memoire

- Linear : commentaires de cloture sur KEY-323 et KEY-337, statuts inchanges (voir fichier retour CE pour
  les commentIds).
- Memoire projet : project_amazon_validation_pipeline_gap.md complete avec l'entree PH-20.63 (sans
  doublon).

## 11. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-20.63_CE_RETURN.md

## 12. Phrase cible

GO READONLY CLOSE AMAZON OUTBOUND VALIDATION STATUS SPLIT PROD READY PH-SAAS-T8.12AS.20.63

STOP.
