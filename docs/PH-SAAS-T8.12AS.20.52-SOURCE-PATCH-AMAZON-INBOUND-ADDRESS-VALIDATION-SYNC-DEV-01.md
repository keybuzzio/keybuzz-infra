# PH-SAAS-T8.12AS.20.52-SOURCE-PATCH-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.52 (SOURCE PATCH DEV - sync statut validation inbound Backend -> product DB API)
> Environnement : DEV / source patch local uniquement ; AUCUN push, build, deploy, kubectl, mutation DB, backfill execute

## 1. Verdict

GO SOURCE PATCH AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.52

Patch source local pret (commit api LOCAL 798db37c, ahead 1 / behind 0, NON pushe). Corrige la
cause racine PH-20.51 STATUS_SPLIT : le sync bridge Backend -> product DB API ne recopiait jamais
le statut de validation reel, laissant l'adresse inbound figee a PENDING dans la base lue par le
worker outbound. tsc --noEmit propre, tests 23/23. Aucune mutation DB, aucun backfill execute
(plan dry-run seulement). Reste : revue + GO PUSH, puis build/deploy DEV dans une phase suivante.

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels et ce patch n'en cree aucun. La seule
action utilisateur disponible (retrait + reconnexion OAuth Amazon) a deja ete faite par Ludovic et
le connecteur est valide cote Backend. Ce patch repare uniquement la propagation de ce statut deja
valide vers la copie product DB API que lit le worker.

## 3. Preflight

| repo | branche | HEAD avant | dirty (hors dist) | bastion |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 15f0e5e5 | 0 | install-v3 46.62.171.61 |
| keybuzz-infra | main | 12ecbed | 0 | install-v3 46.62.171.61 |

Note : keybuzz-api porte 223 entrees `D dist/` pre-existantes (artefacts compiles non suivis comme
source) ; tolerees, non touchees, jamais ajoutees au commit.

## 4. Cause racine rappel (PH-20.51)

Le sync `channelsRoutes` AM.9.1 (Backend -> product DB API) faisait un INSERT de inbound_addresses
avec validationStatus='PENDING' code en dur, et le ON CONFLICT DO UPDATE ne mettait a jour que
connectionId / emailAddress / token / updatedAt - jamais le statut. Donc une adresse VALIDATED cote
Backend DB restait PENDING dans la product DB API. Le worker outbound (outboundWorker.ts:256, gate
WHERE validationStatus='VALIDATED') et la route messages (routes.ts:492, :1150, meme gate) lisaient
cette copie figee -> envoi bloque avant SMTP.

Signal d'entree confirme : le backend expose le statut par adresse via
GET /api/v1/marketplaces/amazon/inbound-connection -> addresses[].status = pipelineStatus Backend
(amazon.routes.ts). Le BFF client app/api/amazon/activate-channels/route.ts transmet ces adresses
(champ status) dans le POST /channels/activate-amazon, mais la route ignorait ce status.

## 5. Patch

| fichier | changement | risque | mitigation |
|---|---|---|---|
| keybuzz-api/src/lib/normalizeInboundValidationStatus.ts (nouveau) | helper pur exporte normalizeInboundValidationStatus(status?) : 'VALIDATED' seulement si entree explicitement 'VALIDATED' (insensible casse/espaces), sinon 'PENDING' | promotion fortuite | seul 'VALIDATED' explicite promeut ; PENDING/FAILED/inconnu/vide/absent -> PENDING |
| keybuzz-api/src/modules/channels/channelsRoutes.ts (modifie) | INSERT VALUES utilise $7 (statut normalise) au lieu de 'PENDING' fige ; ON CONFLICT DO UPDATE ajoute validationStatus/pipelineStatus/marketplaceStatus en CASE promote-only ; passe incomingStatus en param $7 | downgrade d'un VALIDATED existant | CASE WHEN $7=VALIDATED THEN VALIDATED ELSE inbound_addresses.<col> END -> ne descend jamais un VALIDATED deja en base |
| keybuzz-api/__tests__/normalizeInboundValidationStatus.test.ts (nouveau) | test standalone (tsc + node), 23 cas : truth-table + invariants source | regression silencieuse | echec si le patch est defait (gate, promote-only, hardcode) |

Logique cle (extrait) :

    const incomingStatus = normalizeInboundValidationStatus(addr.status);
    ...
    "validationStatus" = CASE WHEN $7::"InboundValidationStatus" = 'VALIDATED'::"InboundValidationStatus"
      THEN 'VALIDATED'::"InboundValidationStatus"
      ELSE inbound_addresses."validationStatus" END

Diff scope strict : 3 fichiers non-dist (1 modifie + 2 nouveaux), 12 insertions / 3 suppressions
sur channelsRoutes.ts.

## 6. Tests

| id | cas | attendu | resultat |
|---|---|---|---|
| A1 | Backend 'VALIDATED' | 'VALIDATED' (promotion) | PASS |
| A2 | 'validated' minuscule | 'VALIDATED' | PASS |
| A3 | '  VALIDATED  ' espaces | 'VALIDATED' | PASS |
| A4 | 'PENDING' | 'PENDING' | PASS |
| A5 | 'FAILED' | 'PENDING' | PASS |
| A6 | undefined (source absente) | 'PENDING' | PASS |
| A7 | null | 'PENDING' | PASS |
| A8 | '' | 'PENDING' | PASS |
| A9 | 'WHATEVER' (inconnu) | 'PENDING' (pas de promotion fortuite) | PASS |
| A10 | idempotence | egal | PASS |
| B1/B1b | INSERT propage $7, plus de triple 'PENDING' fige | present / absent | PASS |
| B2/B2b | ON CONFLICT promote-only, ELSE conserve l'existant (never-downgrade) | present | PASS |
| B3 | la route appelle normalizeInboundValidationStatus(addr.status) | present | PASS |
| B4 | gate worker outbound intact (validationStatus='VALIDATED') | present | PASS |
| B5 | gate route messages intact | present | PASS |
| B6 | aucun hardcode tenant/token/noreply dans channelsRoutes | absent | PASS |

Total : 23 passed, 0 failed. tsc --noEmit projet complet : 0 erreur.

## 7. AI feature parity / anti-regression

| invariant | etat | preuve |
|---|---|---|
| gate worker outbound validationStatus='VALIDATED' | intact | outboundWorker.ts:256 inchange (test B4) |
| gate route messages validationStatus='VALIDATED' | intact | routes.ts:492/1150 inchanges (test B5) |
| provider Amazon (determineAmazonProvider) | non touche | hors scope, fichier inchange |
| KBActions / couts LLM | non touches | patch limite au sync statut inbound |
| From / connecteur | non touche, aucun noreply@ reintroduit | test B6 |
| multi-tenant (pas de hardcode tenant/token/marketplace) | respecte | test B6 + diff vide sur patterns interdits |
| promote-only (jamais de downgrade VALIDATED -> PENDING) | garanti SQL | CASE ... ELSE inbound_addresses.<col> (test B2/B2b) |

## 8. No fake metrics / no fake events

Sans objet : le patch ne touche ni dashboard, ni KPI, ni tracking, ni billing. Aucune fabrication
d'evenement, aucun pourcentage. Le statut ecrit est strictement celui transmis par le Backend.

## 9. Backfill as0yom - PLAN DRY-RUN (NON execute)

NON execute dans cette phase (aucune mutation DB, aucun kubectl). A jouer apres build+deploy du
patch dans une phase ulterieure avec GO explicite.

Option A (recommandee, sans SQL manuel) : une fois la nouvelle image API deployee, re-declencher le
sync bridge pour le(s) tenant(s) impacte(s) (re-activation Amazon / reconnexion qui rappelle
POST /channels/activate-amazon). Le ON CONFLICT corrige promeut alors la ligne product DB API a
VALIDATED a partir du statut Backend. Zero SQL manuel, zero hardcode.

Option B (backfill SQL cible, dry-run, NON execute) :

    -- Etape 1 (LECTURE, product DB API) : adresses amazon encore non VALIDATED dans la copie API
    SELECT "tenantId", country, "emailAddress", "validationStatus", "updatedAt"
      FROM inbound_addresses
     WHERE marketplace = 'amazon' AND "validationStatus" <> 'VALIDATED';

    -- Etape 2 (LECTURE, Backend DB) : adresses amazon VALIDATED cote source de verite
    SELECT "tenantId", country, "emailAddress", "validationStatus", "lastInboundAt"
      FROM inbound_addresses
     WHERE marketplace = 'amazon' AND "validationStatus" = 'VALIDATED';

    -- Etape 3 (ECRITURE, product DB API) -- NON executee : promeut UNIQUEMENT les lignes API
    -- dont la ligne Backend correspondante (tenantId, country) est VALIDATED (etape 2).
    UPDATE inbound_addresses
       SET "validationStatus"  = 'VALIDATED'::"InboundValidationStatus",
           "pipelineStatus"    = 'VALIDATED'::"InboundValidationStatus",
           "marketplaceStatus" = 'VALIDATED'::"InboundValidationStatus",
           "updatedAt"         = NOW()
     WHERE marketplace = 'amazon'
       AND "validationStatus" <> 'VALIDATED'
       AND ("tenantId", country) IN ( <lignes confirmees VALIDATED a l'etape 2> );

Candidat connu (PH-20.51) : tenant ecomlg-motxke32 FR (localpart ...as0yom), API DB PENDING vs
Backend VALIDATED. A confirmer par les etapes 1-2 au moment du backfill, jamais code en dur.

## 10. No side-effect / no mutation (cette phase)

| signal | observe | verdict |
|---|---|---|
| mutation DB (INSERT/UPDATE/DELETE/DDL) | aucune | OK |
| backfill execute | aucun (plan dry-run seulement) | OK |
| push git / docker build / docker push | aucun | OK |
| kubectl apply/set/patch/edit/restart | aucun | OK |
| runtime DEV/PROD | inchange | OK |
| manifests PH-20.49 (api+client prod v3.5.259) | intacts | OK |
| Linear (statut / commentaire) | inchange (texte prepare, NON envoye) | OK |

## 11. Build / GitOps / Validation runtime

Sans objet pour cette phase (SOURCE PATCH DEV). Aucun build, aucun push image, aucun apply. La
validation runtime se fera dans la phase build/deploy DEV suivante (apres GO PUSH).

## 12. Linear (texte prepare, NON envoye)

A poster sur KEY-323 (primary) et KEY-337 (parent) lors d'une phase autorisant Linear :

"PH-20.52 SOURCE PATCH DEV = READY. Corrige la cause racine PH-20.51 (STATUS_SPLIT) : le sync bridge
Backend -> product DB API (channelsRoutes AM.9.1) ne recopiait jamais le statut de validation, donc
une adresse inbound VALIDATED cote Backend restait PENDING dans la copie API lue par le worker
outbound -> envoi bloque avant SMTP. Le sync propage desormais le statut Backend (addr.status =
pipelineStatus) via un helper pur normalizeInboundValidationStatus ; promotion seulement si Backend
dit explicitement VALIDATED ; ON CONFLICT promote-only (jamais de downgrade d'un VALIDATED existant).
Aucun hardcode tenant/token, aucun DDL, gates worker+messages intacts, aucun noreply From. Test
standalone 23/23, tsc propre. Commit api LOCAL 798db37c (NON pushe). Backfill as0yom prepare en
dry-run uniquement (non execute). Pas de bouton Channels (inexistant). Prochaine etape : GO PUSH puis
build/deploy DEV."

## 13. Gaps restants

1. Le patch ne prend effet qu'apres build + deploy de la nouvelle image API (phase suivante).
2. Backfill as0yom non execute (plan dry-run) : a jouer apres deploy, Option A recommandee.
3. Le signal Backend transmis par le bridge est pipelineStatus (et non validationStatus
   directement) ; il suit validationStatus cote Backend mais la verification finale du flux se fera
   au re-test d'envoi apres deploy. La gate effective reste validationStatus dans la product DB API.
4. lastInboundAt n'est pas transmis par le payload bridge {country,email,status} : non synchronise
   ici (et non requis par la gate, qui ne lit que validationStatus). Hors scope.

## 14. Prochaine action

GO PUSH SOURCE PATCH AMAZON INBOUND ADDRESS VALIDATION SYNC DEV (push commit api 798db37c), puis
phase build API DEV from-git, deploy DEV, re-test envoi ecomlg-motxke32, backfill Option A.

## 15. Phrase cible

GO SOURCE PATCH AMAZON INBOUND ADDRESS VALIDATION SYNC DEV READY PH-SAAS-T8.12AS.20.52

STOP.
