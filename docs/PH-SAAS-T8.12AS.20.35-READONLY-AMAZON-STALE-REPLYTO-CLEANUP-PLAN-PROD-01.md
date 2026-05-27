# PH-SAAS-T8.12AS.20.35-READONLY-AMAZON-STALE-REPLYTO-CLEANUP-PLAN-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.35 (READONLY AMAZON STALE REPLY_TO + CROSS-TENANT CLEANUP PLAN)
> Environnement : PROD read-only (SELECT/logs uniquement ; aucune mutation/cleanup/Seller Central)

## 1. Verdict

GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD READY PH-SAAS-T8.12AS.20.35

Inventaire read-only complet des restes structurels post-fermeture P0 (PH-20.34-BIS). Trois surfaces identifiees + plan sequence (sans mutation) : (1) reply-to obsoletes 3jcpvk/cp2hat ABSENTS de la DB mais encore configures cote Amazon Seller Central -> fan-out vers ecomlg-001 a couper a la source ; (2) doublons historiques pre-v1.0.56 (13 groupes messages / 20 lignes en trop + 67 groupes conversations / ~114 conversations en trop, tous ecomlg-001 quasi-exclusif) a nettoyer avec sauvegarde ; (3) contrainte unique DB a poser post-cleanup. Cross-tenant ecomlg-001 / ecomlg-motxke32 (4xfub8 / as0yom) = decision produit (2 tenants KeyBuzz pour le meme seller reel). Aucune mutation cette phase.

## 2. Preflight (E0)

| Element | Etat |
|---|---|
| Bastion | install-v3 / 46.62.171.61 |
| date | 2026-05-27 14:26Z |
| PROD API + jobs-worker | v1.0.56-amazon-inbound-dedup-prod (digest 9689875c), restarts=0 |
| DEV API + jobs-worker | v1.0.56-amazon-inbound-dedup-dev |
| infra | clean (HEAD e50d995) |

## 3. Cartographie inbound addresses Amazon (E1)

Deux stores distincts (architecture confirmee) : routage/validation webhook = backend DB keybuzz_backend_prod.inbound_addresses (tokens reply-to reels) ; guard outbound + Inbox = product DB keybuzz_prod.inbound_addresses (token generique "io"). Le fan-out d'adresses se joue cote BACKEND.

Backend keybuzz_backend_prod.inbound_addresses (Amazon), focus ecomlg :

| tenantId | country | token | validationStatus | marketplaceStatus | lastInboundAt | statut |
|---|---|---|---|---|---|---|
| ecomlg-001 | FR | 4xfub8 | VALIDATED | VALIDATED | 2026-05-27T14:05:13Z | ACTIF, a CONSERVER |
| ecomlg-001 | BE | ub0m1q | PENDING | PENDING | null | jamais recu |
| ecomlg-001 | ES | zul3wn | PENDING | PENDING | null | jamais recu |
| ecomlg-001 | IT | hz4alx | PENDING | PENDING | null | jamais recu |
| ecomlg-001 | PL | 36ngpp | PENDING | PENDING | null | jamais recu |
| ecomlg-motxke32 | FR | as0yom | VALIDATED | VALIDATED | 2026-05-27T14:05:13Z | ACTIF cross-tenant (decision produit) |
| compta-ecomlg-gmail--mnvu4649 | FR | 3eiuaq | PENDING | PENDING | null | jamais recu |
| ecomlg-mo4h93e7 | FR | ielk2l | PENDING | PENDING | null | jamais recu |
| bon-kb-mosf283z | FR/ES | fq7fep/11tkog | PENDING | PENDING | null | jamais recu |
| ludo-gonthier-ga4mpf-mo5ldw59 | FR | uid9zo | PENDING | PENDING | null | jamais recu |

NB : les tokens product keybuzz_prod (ecomlg-001 FR/ES/IT VALIDATED) portent un token interne "io" (distinct du token reply-to backend) -- c'est le store guard, pas le routage.

## 4. Tokens recus mais absents/obsoletes (E2)

| token | tenant derive | existe DB backend ? | status | derniere reception | verdict |
|---|---|---|---|---|---|
| 4xfub8 | ecomlg-001 | OUI | VALIDATED | 2026-05-27T14:05:13Z | reply-to VALIDE -> CONSERVER |
| as0yom | ecomlg-motxke32 | OUI | VALIDATED | 2026-05-27T14:05:13Z | cross-tenant ACTIF (decision produit) |
| 3jcpvk | ecomlg-001 (par localpart) | NON (absent DB) | n/a | recu via fan-out (logs PH-20.21B/30-BIS) | OBSOLETE -> RETIRER Seller Central |
| cp2hat | ecomlg-001 (par localpart) | NON (absent DB) | n/a | recu via fan-out | OBSOLETE -> RETIRER Seller Central |

Mecanisme : 3jcpvk/cp2hat ne sont plus provisionnes en DB ; quand Amazon delivre vers ces reply-to, parseInboundAddress derive le tenant du localpart (ecomlg-001) -> la livraison est routee vers ecomlg-001 quand meme. D'ou 3 livraisons concurrentes ecomlg-001 (4xfub8 + 3jcpvk + cp2hat) par message, desormais collapsees a 1 par l'advisory lock. Retirer 3jcpvk/cp2hat cote Amazon = couper le fan-out a la source (reduit le bruit, le verrou n'est plus sollicite inutilement).

## 5. Cross-tenant ecomlg (E3)

26 groupes cross-tenant (meme amazonIds.messageId sous >1 tenant), TOUS ecomlg-001 + ecomlg-motxke32. Echantillon recent :

| amazonMessageId | tenants | msg_rows | last_at | note |
|---|---|---|---|---|
| A007902311OYREHWN5VKM | ecomlg-001, ecomlg-motxke32 | 2 | 2026-05-27T14:05:12Z | post-deploy : 1+1 (intra deduped) |
| A10212573GGSJP1Z487RN | ecomlg-001, ecomlg-motxke32 | 3 | 2026-05-27T13:25:20Z | pre-deploy |
| A1032419E4LM7CSN28B6 | ecomlg-001, ecomlg-motxke32 | 4 | 2026-05-27T13:24:48Z | pre-deploy |
| A100493337L42M1RERYX6 | ecomlg-001, ecomlg-motxke32 | 4 | 2026-05-27T10:44:50Z | pre-deploy |

Cause : ecomlg-001 (4xfub8) ET ecomlg-motxke32 (as0yom) sont 2 connexions/tenants KeyBuzz VALIDATED pour le MEME seller reel eComLG -> chaque message buyer ingere sous 2 tenants. Non corrige par l'advisory lock (scope tenant). Impact UI : le meme message apparait dans 2 Inbox distinctes (2 comptes). Decision produit requise : (a) garder 2 tenants (statu quo, accepte) ou (b) declarer un tenant canonique et desactiver/retirer la connexion as0yom de ecomlg-motxke32. NE PAS fusionner les tenants automatiquement.

## 6. Doublons historiques pre-v1.0.56 (E4)

| type | tenant | groupes | extra rows/convs | fenetre | visibleImpact | cleanupCandidate |
|---|---|---|---|---|---|---|
| messages (tenant+amazonIds.messageId >1) | ecomlg-001 | 13 | 20 lignes | 2026-05-26 12:04 -> 2026-05-27 13:25:20 | OUI (messages repetes Inbox) | OUI |
| conversations (tenant+channel+thread_key >1) | ecomlg-001 | 65 | 112 convs | (race era) | OUI (conversations dupliquees Inbox) | OUI, audit par groupe |
| conversations | ecomlg-motxke32 | 1 | 1 | - | mineur | OUI |
| conversations | switaa-sasu-mnc1ouqu | 1 | 1 | - | mineur | a verifier (peut etre legitime) |

POINT CLE : le dernier doublon message intra-tenant date du 2026-05-27T13:25:20Z, soit AVANT le deploiement v1.0.56-prod (13:49:08Z). Aucun doublon intra-tenant post-deploiement (cf PH-20.34-BIS : A007902311 = 1 message). Le perimetre de cleanup est donc FERME (n'augmente plus). Total messages dup all-time = 13 groupes ; conversations dup = 67 groupes.

## 7. Plan cleanup data (E5) -- sans execution

- Canonique a conserver : pour chaque (tenant_id, amazonIds.messageId) garder le message le plus ancien (min(created_at), 1er insere) ; pour chaque (tenant_id, channel, thread_key) garder la conversation portant le plus de messages / la plus ancienne.
- Messages doublons : NE PAS DELETE direct. Strategie : (a) snapshot CSV/JSONL prealable (id, conversation_id, tenant_id, created_at, raw_mime_sha256, raw_mime_key) ; (b) si colonne visibility existe (messages.visibility present) -> envisager un statut "hidden"/"archived" plutot que DELETE ; sinon DELETE des seuls doublons stricts (meme amazonIds.messageId, meme tenant) APRES sauvegarde et conservation du raw MIME (MinIO) ; (c) re-parenter aucun message si le canonique porte deja la copie.
- Conversations doublons : audit par groupe AVANT action (65 groupes ecomlg-001) ; rattacher les messages des conversations non-canoniques vers la conversation canonique (UPDATE conversation_id) en preservant status/escalation_status/assigned_agent_id/unread/sla ; ne supprimer une conversation que si vide apres re-parentage ; preserver order_ref et historique.
- Dry-run obligatoire (SELECT COUNT par groupe) avant tout apply ; phase apply separee avec GO explicite + sauvegarde + plan de rollback.

## 8. Plan Seller Central / reply-to (E6) -- sans action

- A RETIRER cote Amazon Seller Central (messagerie ecomlg-001) : les 2 reply-to obsoletes 3jcpvk@... et cp2hat@... (absents DB, ne servent plus, generent le fan-out intra-tenant).
- A CONSERVER : 4xfub8@... (ecomlg-001 FR VALIDATED actif).
- as0yom@... (ecomlg-motxke32) : NE PAS toucher tant que la decision produit cross-tenant n'est pas prise (le retirer supprimerait l'ingestion du 2e tenant).
- Ordre recommande : retirer cp2hat d'abord, observer 1-2 vrais messages (doit passer de 3 a 2 POST ecomlg-001), puis retirer 3jcpvk (doit passer a 1 POST ecomlg-001 + 1 as0yom). Verification post-retrait : logs webhook PROD comptent les POST par amazonIds.messageId ; DB inchangee (toujours 1 message ecomlg-001).
- Risque si mauvais retrait : retirer 4xfub8 par erreur couperait l'ingestion ecomlg-001 (P0). Double-check le token exact avant tout retrait. Action 100% cote console Amazon (hors KeyBuzz), par Ludovic.

## 9. Plan contrainte unique DB (E7) -- sans execution

- Precondition : cleanup data E5 termine (sinon CREATE UNIQUE INDEX echoue sur doublons existants).
- messages : CREATE UNIQUE INDEX CONCURRENTLY sur (tenant_id, (metadata->'amazonIds'->>'messageId')) WHERE metadata->'amazonIds'->>'messageId' IS NOT NULL -- index partiel (n'impacte pas les messages non-Amazon / sans cle stable).
- conversations : CREATE UNIQUE INDEX CONCURRENTLY sur (tenant_id, channel, thread_key) WHERE thread_key IS NOT NULL.
- Strategie CONCURRENTLY (pas de lock long) ; valider d'abord en DEV (keybuzz) ; SQL brut (tables non-Prisma cote product, pas de migration Prisma).
- Rollback : DROP INDEX CONCURRENTLY <name>.
- Defense-in-depth : redondant avec l'advisory lock applicatif (PH-20.26) mais protege contre tout futur chemin d'ecriture non serialise.

## 10. AI feature parity / anti-regression

Phase 100% read-only (SELECT product + backend DB, kubectl get, logs). Aucune mutation/cleanup/trigger/Seller Central. Impacts potentiels d'un futur cleanup analyses : historique conversation, unread, escalation_status, assigned_agent_id, sla_state, order_ref -> tous a preserver (re-parentage plutot que suppression seche). Aucun cleanup destructif propose sans snapshot + audit par groupe + GO.

## 11. Recommandation finale / sequence (E8)

1. **PH-20.36 (Ludovic, Seller Central)** : retirer reply-to obsoletes cp2hat puis 3jcpvk de la messagerie Amazon ecomlg-001 ; conserver 4xfub8 ; ne pas toucher as0yom. Verif read-only post-retrait. = action la plus sure et a plus fort ROI (coupe le bruit a la source, 0 risque DB).
2. **PH-20.37 (decision produit cross-tenant)** : trancher ecomlg-001 vs ecomlg-motxke32 (canonique unique ou statu quo 2 tenants). Si canonique : plan de desactivation connexion as0yom (read-only d'abord).
3. **PH-20.38 (data cleanup historique)** : snapshot + dry-run + apply doublons messages (13 groupes) puis conversations (67 groupes), avec preservation etat + rollback.
4. **PH-20.39 (contrainte unique DB)** : index uniques partiels CONCURRENTLY post-cleanup, DEV puis PROD.

## 12. Limites restantes

- Cleanup data + contrainte unique = mutations DB -> phases dediees avec GO explicite, snapshot, rollback.
- Retrait Seller Central = action console Amazon par Ludovic (hors KeyBuzz / hors CE).
- Cross-tenant = decision produit, pas un bug ; aucune fusion automatique.
- P0 KEY-323 (race inbound) reste CLOS cote applicatif (advisory lock v1.0.56-prod actif + prouve PH-20.34-BIS) ; ces phases sont de l'hygiene P1, ne rouvrent pas le P0.

## 13. Phrase cible

GO READONLY AMAZON STALE REPLY_TO CLEANUP PLAN PROD READY PH-SAAS-T8.12AS.20.35

Prochaine phrase GO recommandee : GO AMAZON STALE REPLY_TO REMOVAL SELLER CENTRAL PROD PH-SAAS-T8.12AS.20.36 (retrait cp2hat puis 3jcpvk cote Amazon par Ludovic + verification read-only ; conserver 4xfub8 ; ne pas toucher as0yom).

STOP.
