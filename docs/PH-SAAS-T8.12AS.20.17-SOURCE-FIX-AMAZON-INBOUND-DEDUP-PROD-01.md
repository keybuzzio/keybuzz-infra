# PH-SAAS-T8.12AS.20.17-SOURCE-FIX-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.17 (SOURCE FIX AMAZON INBOUND DEDUP)
> Environnement : SOURCE DEV-first, commits LOCAUX, gate push (aucun build/deploy/kubectl/DB)

## 1. Verdict

GO SOURCE FIX AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.17

Patch source minimal (keybuzz-backend uniquement) rendant l'ingestion inbound Amazon idempotente sur la cle metier stable du message Amazon. Tests cibles 13/13 + tsc EXIT 0 + non-regression (ph2014w 10/10, ph2014o 9/9, ph2014i 11/11). Commits LOCAUX seulement (gate push). Aucun build/push/deploy/kubectl/DB mutation. Le P0 KEY-323 (pipeline restaure) n'est pas touche : message inbound toujours cree, guard validation/outbound inchanges. La contrainte unique DB (race-safety) + le cleanup data + la decision produit multi-adresse sont documentes pour des phases separees (non executes ici).

## 2. RCA rappel (PH-20.16)

Triple cause cumulative prouvee :
- B double adresse/tenant : 2 adresses Amazon FR VALIDATED pour le meme seller (ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom) -> ingestion sous 2 tenants.
- A/D livraisons multiples SES : externalId = SES Message-ID UNIQUE par livraison -> dedup par externalId structurellement inoperante.
- C dedup applicative insuffisante : chemin order:<ref> cree une conversation par copie ; chemin sc:<threadId> non race-safe ; pas de contrainte unique (tenant_id, thread_key).

## 3. Localisation (E1)

Ingestion produit = keybuzz-backend module webhooks (keybuzz-api : aucun match).

| Fichier | Fonction | Responsabilite | Risque doublon |
|---|---|---|---|
| webhooks/inboundEmailWebhook.routes.ts | webhook /inbound-email | cree ExternalMessage (idempotence par externalId=SES id + ON CONFLICT) puis appelle createInboxConversation | ExternalMessage dedup par SES id -> 1 par livraison (audit brut, non Inbox) |
| webhooks/messageNormalizer.service.ts | normalizeInboundMessage / extractAmazonIds | derive threadKey (sc:/order:) + metadata.amazonIds {threadId, messageId} | fournit la cle stable amazonIds.messageId |
| webhooks/inboxConversation.service.ts | createInboxConversation | idempotence message + grouping conversation + create message (Inbox visible) | idempotence keyee sur SES id (jamais matche) ; grouping non race-safe |

## 4. Design du fix (E2)

Cle canonique Amazon (E2.1) : `metadata.amazonIds.messageId` (ex A089466823REET8SHWBIX), IDENTIQUE entre redeliveries, extrait des markers du body par MessageNormalizer. JAMAIS le SES Message-ID. Fallback controle = null si absent (chemin order: / non-Amazon) -> comportement best-effort precedent conserve.

Dedup message (E2.2) : avant toute creation, si cle stable presente, SELECT message existant du MEME tenant par `metadata->'amazonIds'->>'messageId'`. Si trouve -> skip idempotent (retourne conversation+message existants, isNew=false), AUCUN doublon, log "Idempotent skip". Comme la creation de conversation suit l'idempotence message, ce seul point supprime AUSSI la conversation dupliquee pour le cas dominant (redelivery).

Dedup conversation (E2.3) : le grouping existant (threadKey sc: puis order:, puis create) est conserve. La race-safety complete exige une contrainte unique DB -> NON appliquee ici (migration differee, voir section 8). Les tables conversations/messages vivent dans le DB PRODUIT keybuzz (SQL brut via productDb), PAS Prisma -> la contrainte sera un DDL SQL manuel sequence APRES cleanup data (sinon l'index unique echoue sur les doublons existants).

Multi-adresse/multi-tenant (E2.4) : l'idempotence est SCOPED par tenant_id -> les 2 tenants ne sont jamais fusionnes. La reduction a une seule adresse/tenant active par seller reel est une DECISION PRODUIT (section 7), pas un fix code. Aucun cleanup data ici.

## 5. Fichiers modifies (E3/E5)

| Repo | Fichier | Changement | Type |
|---|---|---|---|
| keybuzz-backend | src/modules/webhooks/inboundDedup.ts | NOUVEAU helper pur extractStableAmazonMessageKey (42 l) | source |
| keybuzz-backend | src/modules/webhooks/inboxConversation.service.ts | +import + bloc idempotence cle stable avant le bloc SES (fallback conserve) (30 l) | source |
| keybuzz-backend | tests/ph2017-inbound-dedup.test.ts | NOUVEAU test standalone ts-node (68 l) | test |

Commit backend LOCAL **78c450c** (ahead=1, origin/main reste d27f4a5). tsconfig.tsbuildinfo non touche ; amazon.routes.ts.bak (cruft untracked pre-existant) exclu.

## 6. Comportement avant/apres + tests (E3)

| Cas | Avant | Apres |
|---|---|---|
| 2 livraisons SES du meme message Amazon (sc:) | 2 conversations + 2 messages (SES id unique -> idempotence ratee) | 1er cree ; 2e skip idempotent (meme amazonIds.messageId, meme tenant) |
| order:<ref> redelivere (amazonIds present) | nouvelle conversation par copie | skip idempotent si amazonIds.messageId match |
| order:<ref> SANS amazonIds (generic_cleanup) | doublon possible | fallback best-effort (inchange) + grouping threadKey ; residuel -> contrainte unique differee |
| message Amazon distinct (amazonIds.messageId different) | nouveau | nouveau (correct, pas un doublon) |
| multi-tenant meme message | 1 par tenant | 1 par tenant (idempotence tenant-scoped ; pas de fusion) |
| amazonIds absent / vide / null | - | cle null -> fallback sur, aucune exception |
| message inbound normal | cree | cree (anti-regression) |

| Test | Cas | Attendu | Resultat |
|---|---|---|---|
| ph2017-inbound-dedup (13 cas) | cle stable / absence / robustesse / SES ignore | voir ci-dessus | 13/13 PASS |
| tsc --noEmit | typecheck projet | EXIT 0 | EXIT 0 |
| ph2014w real-inbound-validation | anti-regression validation | 10/10 | 10/10 PASS |
| ph2014o validation-address-casing | anti-regression casse | 9/9 | 9/9 PASS |
| ph2014i validation-address | anti-regression resolution | 11/11 | 11/11 PASS |

Le coeur DB (SELECT idempotence) est exerce au runtime/integration ; la regle "ne pas mocker la DB" est respectee (seules les fonctions pures sont unit-testees).

## 7. Decision produit multi-adresse (requise, NON tranchee ici)

Deux adresses Amazon FR VALIDATED coexistent pour le seller reel ecomlg (ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom). Tant qu'Amazon route le meme message vers les deux, le doublon CROSS-TENANT subsiste par design (l'idempotence tenant-scoped ne peut pas le supprimer sans fusionner deux tenants, ce qui serait une regression multi-tenant). Options a arbitrer par Ludovic :
- A. une seule adresse/tenant active+validee par seller/marketplace/country (desactiver/retirer l'adresse du 2e tenant cote Amazon Seller Central + KeyBuzz).
- B. notion de seller canonical regroupant plusieurs tenants (changement de modele, lourd).
Recommandation : A (simple, aligne au modele tenant actuel). A cadrer hors code.

## 8. Risques restants + plan phase suivante

- Race-safety conversation (2 livraisons simultanees memes amazonIds avant commit) : residuelle. Fix complet = index unique sur le DB PRODUIT keybuzz (DDL SQL manuel, PAS Prisma) `CREATE UNIQUE INDEX CONCURRENTLY ... ON conversations (tenant_id, channel, thread_key) WHERE thread_key IS NOT NULL` + INSERT ... ON CONFLICT cote code. NON applicable maintenant : les doublons existants feraient ECHOUER l'index -> sequencer APRES cleanup data. DOCUMENTE, non cree (eviter tout fichier auto-applicable).
- Cleanup data (doublons deja en base) : phase dediee SEPAREE (jamais DELETE/fusion ad hoc ; strategie a definir : garder la plus ancienne conversation par (tenant, thread_key), re-rattacher messages, archiver).
- order:<ref> sans amazonIds : couverture partielle (fallback) jusqu'a la contrainte unique.
- ExternalMessage reste 1 par livraison SES (audit brut, non Inbox) : acceptable ; dedup stable-key cote ExternalMessage = amelioration future (necessite colonne).

Plan : (1) GO PUSH (cette phase) ; (2) build+push+apply DEV backend + retrigger reel verif dedup ; (3) decision produit A ; (4) phase cleanup data ; (5) phase migration contrainte unique (post-cleanup) ; (6) promotion PROD.

## 9. No fake metrics / no fake events + interdits respectes

0 fake webhook/message/email/event/metric. Aucun build, docker push, deploy, kubectl, migration appliquee, DB mutation (DELETE/UPDATE/INSERT), Prisma migrate/db push, suppression/fusion, retry outbound, trigger Amazon, hardcode tenant/token/order, secret introduit. Bastion install-v3 / 46.62.171.61 exclusif. credentials/ et secrets/ non touches. Anti-regression : guard validation/outbound, suggestions IA, escalades, assignment, statuts conversation, historique, notes internes NON touches (1 seul fichier source modifie + 1 helper pur + 1 test).

## 10. Linear (E7) - texte prepare (NE PAS poster avant push)

Texte commentaire KEY-323 + KEY-337 :
"PH-20.17 (source fix dedup inbound Amazon) - READY, gate push, commits locaux. keybuzz-backend : nouvelle dedup idempotente sur la cle metier STABLE metadata.amazonIds.messageId (identique entre redeliveries SES), scopee par tenant -> N copies SES collapsent en 1 conversation + 1 message ; le SES Message-ID n'est plus utilise comme cle. Helper pur isole (inboundDedup.ts) + bloc idempotence dans createInboxConversation (fallback SES conserve). Tests 13/13 + tsc 0 + non-regression ph2014w/o/i. Commit backend local 78c450c (NON pousse). Differe (phases separees) : decision produit adresse unique par seller (doublon cross-tenant ecomlg-001/ecomlg-motxke32), cleanup data doublons existants, contrainte unique DB (post-cleanup). Aucun build/deploy/DB/trigger ; P0 KEY-323 non rouvert. Statut inchange."

## 11. Phrase cible

GO SOURCE FIX AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.17

STOP.
