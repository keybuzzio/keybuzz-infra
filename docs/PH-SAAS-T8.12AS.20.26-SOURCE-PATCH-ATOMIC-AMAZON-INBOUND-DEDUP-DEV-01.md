# PH-SAAS-T8.12AS.20.26-SOURCE-PATCH-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.26 (SOURCE PATCH ATOMIC, DEV-first, commits locaux gate push)
> Environnement : SOURCE (keybuzz-backend) ; aucun build/push/deploy/kubectl/DB/migration

## 1. Verdict

GO SOURCE PATCH ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.26

Patch source qui FERME la race concurrente inbound Amazon prouvee en PROD (PH-20.25-BIS) : la section dedup-critique (idempotence + resolution/creation conversation + insert message) est desormais serialisee sous un verrou transactionnel Postgres (pg_advisory_xact_lock) sur une cle deterministe unique. tsc EXIT 0 ; tests ph2026 14/14 (nouveau) + ph2017 13/13 + ph2014w 10/10 + ph2014o 9/9 + ph2014i 11/11. Commit backend LOCAL 78bfb94 (NON pousse, origin reste 78c450c). Aucun build/push/deploy/kubectl/DB/migration/CREATE INDEX. La contrainte unique DB reste un durcissement ulterieur (apres cleanup des doublons existants). STOP au gate push.

## 2. Preflight (E0)

| Repo | Branche | HEAD | origin | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78c450c (avant) -> 78bfb94 (commit local) | 78c450c | .bak historique seul | OK |
| keybuzz-infra | main | 2d4aa2c | - | rapport docs-only | OK |

Bastion install-v3 / 46.62.171.61. Runtime informatif : DEV + PROD v1.0.55-amazon-inbound-dedup-{dev,prod}.

## 3. Code relu (E1)

| Fichier | Fonction | Role | Risque race (avant) |
|---|---|---|---|
| src/modules/webhooks/inboundDedup.ts | extractStableAmazonMessageKey | cle metier stable amazonIds.messageId | n/a (pur) |
| src/modules/webhooks/inboxConversation.service.ts | createInboxConversation | idempotence + resolve/create conversation + insert message | SELECT-puis-skip via productDb (pool), AUCUNE transaction, AUCUN lock -> 3-4 POST concurrents passent tous le SELECT avant tout commit -> doublons |
| src/lib/productDb.ts | productDb.query / getClient | pool pg (max=5), getClient=pool.connect | n/a |

## 4. Strategie du patch atomique (E2)

- Helper PUR `computeInboundDedupLockScope(tenantId, marketplace, stableAmazonMessageKey, threadKey)` (inboundDedup.ts) : retourne une cle de scope DETERMINISTE, toujours tenant-prefixee :
  - cle stable presente -> `amzmsg:<tenant>:<messageId>` (collapse toutes les redeliveries du meme message buyer dans le tenant) ;
  - sinon threadKey present -> `thread:<tenant>:<channel>:<threadKey>` (serialise les inserts concurrents du meme thread -> 1 conversation) ;
  - sinon null -> chemin legacy non serialise conserve (fallback inchange).
- createInboxConversation : si lockScope non-null, ouvre une transaction sur un client dedie (productDb.getClient) : `BEGIN` -> `SELECT pg_advisory_xact_lock(hashtextextended($1,0))` (verrou xact-scoped, auto-libere au COMMIT/ROLLBACK) -> section critique (idempotence stable + idempotence SES fallback + resolution/creation conversation + insert message) routee via `runQuery` sur CE client -> `COMMIT` (libere le verrou). Le travail NON critique (raw MIME MinIO, attachments, stats conversation, callback autopilot) s'execute APRES le commit sur le pool, pour garder la transaction courte.
- 1 SEULE cle de verrou par appel -> AUCUN ordre de lock -> AUCUN risque de deadlock.
- 1 connexion par appel pendant la section critique (le runQuery cible le client verrouille, pas le pool) -> pas d'epuisement du pool (max=5) meme sous burst.
- try/catch : ROLLBACK + release sur erreur. finally : filet de securite (skip idempotent en early-return) -> COMMIT (read-only) + release.
- Logs structures : `[InboxConversation] Dedup lock acquired scope=<amzmsg|thread> tenant=...`, `Idempotent skip`, `Created new conversation`, `Created message`.

## 5. Tests (E3)

| Test | Cas | Attendu | Resultat |
|---|---|---|---|
| tsc --noEmit | compilation stricte | EXIT 0 | EXIT 0 |
| ph2026 case 1 | 2 concurrents (tenant,msgId) | meme scope (=> 1 message) | PASS |
| ph2026 case 2 | 3 concurrents (tenant,msgId) | meme scope | PASS |
| ph2026 case 3 | 2 concurrents (tenant,threadKey), pas de cle stable | meme thread scope (=> 1 conversation) | PASS |
| ph2026 case 4 | messages differents meme tenant | scopes differents (pas de collapse) | PASS |
| ph2026 case 5 | meme msgId, tenants differents | scopes differents (cross-tenant NON fusionne) | PASS |
| ph2026 case 6 | ni cle stable ni threadKey / tenant vide | null (fallback) | PASS |
| ph2026 case 7 | determinisme | scope identique sur appels repetes | PASS |
| ph2026 case 8 | priorite cle stable > threadKey | scope amzmsg | PASS |
| ph2026 total | | 14/14 | 14 passed, 0 failed |
| ph2017 | anti-regression cle stable | 13/13 | 13 passed |
| ph2014w / ph2014o / ph2014i | anti-regression validation | 10/10 / 9/9 / 11/11 | tous PASS |

Limite des tests unitaires : la SERIALISATION reelle (pg_advisory_xact_lock) requiert une vraie base Postgres ; elle n'est PAS unit-testable sans DB. Les tests prouvent la derivation et le determinisme de la cle de verrou (condition necessaire). La preuve de collapse runtime sous redeliveries concurrentes reste a etablir au runtime DEV/PROD (verify post-deploy d'une vraie reception, sans fake event).

## 6. Non-regression (E4)

- Aucun hardcode tenant/order/token (grep 4xfub8/3jcpvk/cp2hat/as0yom/403-2003407 = 0 ; les seules constantes des tests sont l'amazonIds.messageId/threadKey reels comme fixtures).
- Aucun CREATE INDEX / ALTER TABLE / prisma migrate / db push.
- Aucun secret.
- Outbound reply + guard validation : non touches (fichiers hors patch).
- IA / escalades / assignment / statuts / historique : non touches.
- jobs-worker : non touche.
- Fallback (pas de cle stable ni threadKey) : chemin legacy productDb conserve a l'identique.
- Le travail post-commit (attachments/stats/autopilot) est inchange (memes requetes productDb, juste deplacees apres le COMMIT). Le diff important sur le service (612 lignes) provient surtout de la RE-INDENTATION (bloc place dans un try) ; la logique metier est preservee.

## 7. Pourquoi la contrainte unique DB reste un durcissement ulterieur

L'advisory lock serialise les ecritures concurrentes au niveau applicatif (suffisant tant qu'un seul process backend OU plusieurs replicas partageant la meme base : pg_advisory_lock est global a la base, donc valable multi-replicas). Une contrainte unique DB serait une garantie defense-en-profondeur au niveau stockage, MAIS :
- elle ne peut pas etre creee tant que les doublons EXISTANTS sont presents (l'index unique echouerait) -> cleanup data d'abord (phase separee) ;
- elle est hors scope de cette phase (interdits : CREATE INDEX, migration appliquee).
Sequencement cible : (1) ce patch advisory lock (ferme la race au runtime) -> (2) cleanup doublons existants -> (3) contrainte unique DB (durcissement stockage).

## 8. Commits locaux (E5)

- backend LOCAL **78bfb94** : `fix(amazon): serialize inbound dedup by stable message key (PH-20.26, advisory lock, KEY-323)` (3 fichiers : inboundDedup.ts, inboxConversation.service.ts, tests/ph2026-inbound-dedup-lock.test.ts ; .bak exclu). origin/main reste 78c450c, ahead=1. NON pousse.
- infra LOCAL : ce rapport (NON pousse).

## 9. Texte Linear prepare (E7 - a poster seulement apres push)

PH-20.26 SOURCE PATCH (local, gate push) : inbound Amazon dedup is now serialized under a Postgres transaction-scoped advisory lock (pg_advisory_xact_lock) keyed on a single deterministic scope (amzmsg:<tenant>:<messageId>, else thread:<tenant>:<channel>:<threadKey>, else legacy fallback). Closes the race proven in PH-20.25-BIS (4 POSTs in ~190 ms -> 3 ecomlg-001 messages, 0 skip). Single key per call => no deadlock ; 1 connection per call => no pool exhaustion ; non-critical work (MinIO/attachments/stats/autopilot) runs post-commit so the transaction stays short. tsc EXIT 0 ; ph2026 14/14 + ph2017 13/13 + ph2014w/o/i green. Backend commit LOCAL 78bfb94 (not pushed). No build/push/deploy/kubectl/DB/migration. DB unique constraint remains a later hardening (after cleanup of existing duplicates). Cross-tenant (4xfub8/as0yom) + stale reply-to (3jcpvk/cp2hat) unchanged (separate phases). Statut inchange.

## 10. Limites restantes

- Race fermee au runtime par l'advisory lock ; durcissement stockage (contrainte unique DB) differe post-cleanup.
- Cross-tenant (ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom) NON fusionne (decision produit).
- Reply-to obsoletes 3jcpvk/cp2hat cote Amazon : retrait manuel separe (reduit le fan-out a la source).
- Doublons existants en DB : cleanup dedie separe.

## 11. Phrase cible

GO SOURCE PATCH ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.26

Prochain : GO PUSH SOURCE PATCH ATOMIC AMAZON INBOUND DEDUP DEV PH-SAAS-T8.12AS.20.26

STOP.
