# PH-SAAS-T8.12AS.20.15J-CLOSE-CLIENT-CLARITY-VERIFY-HANDOFF-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; KEY-325 client Clarity
> Phase : PH-SAAS-T8.12AS.20.15J (CLOSE CLIENT CLARITY VERIFY HANDOFF)
> Environnement : PROD (docs/Linear uniquement ; aucun build/deploy/kubectl ; aucun fake event)

## 1. Verdict

GO CLOSE CLIENT CLARITY VERIFY HANDOFF READY PH-SAAS-T8.12AS.20.15J

Restauration Microsoft Clarity du funnel client.keybuzz.io CONFIRMEE de bout en bout (runtime + navigateur). Volet runtime (PH-20.15I) : client PROD v3.5.217-clarity-client-restore-prod actif, bundle servi contient le project ID client wuk12h9i33 + clarity.ms/tag, isolation preservee (website wrff07upjx absent, api.keybuzz.io=87, api-dev=0). Volet navigateur (retour Ludovic, DevTools client.keybuzz.io/register apres consent opt-in) : requete clarity.ms/tag/wuk12h9i33 status 200, clarity.js status 200, beacon collect status 204, page rendue avec CSS. Le tracking reseau Clarity du funnel client est donc RESTAURE et fonctionnel. Reste a surveiller passivement l'apparition des nouveaux recordings post-deploiement cote dashboard Microsoft Clarity (projet client wuk12h9i33, non bloquant). Aucun fake event/recording.

## 2. Volet runtime client PROD (rappel PH-20.15I)

| Signal | valeur | verdict |
|---|---|---|
| image deployment | v3.5.217-clarity-client-restore-prod | OK |
| manifest = last-applied = runtime | egal | OK |
| imageID runtime | sha256:e75ac3ad...30a = digest GHCR | OK |
| pod | ready, restarts=0 | OK |
| bundle /app/.next : wuk12h9i33 | 2 (present) | OK |
| bundle /app/.next : clarity.ms/tag | present | OK |
| bundle /app/.next : wrff07upjx (website) | 0 (absent) | OK isolation |
| bundle /app/.next : api.keybuzz.io / api-dev | 87 / 0 | OK KEY-263 |
| bundle /app/.next : MUST_BE_SET_BY_BUILD_ARG | 0 | OK KEY-302 |

## 3. Volet navigateur / DevTools (retour Ludovic - CONFIRME)

Retour Ludovic apres ouverture de client.keybuzz.io/register et acceptation du bandeau consent (opt-in) :

| Verification | attendu | retour Ludovic | verdict |
|---|---|---|---|
| consent banner client funnel | acceptation opt-in | OK (accepte) | OK |
| requete clarity.ms/tag/wuk12h9i33 | 200 | status 200 | OK |
| script clarity.js | 200 | status 200 | OK |
| beacon collect (ingestion events Clarity) | 204 | status 204 | OK |
| rendu CSS cote navigateur | mise en forme correcte | page rendue avec CSS | OK |
| isolation projet | wuk12h9i33 (client), PAS wrff07upjx (website) | wuk12h9i33 confirme | OK |

Interpretation : la chaine complete Clarity du funnel client est operationnelle post-consent (tag wuk12h9i33 charge -> clarity.js charge -> events envoyes via collect 204). Le tracking reseau Clarity client est RESTAURE. La requete n'apparaissait pas en curl serveur car le script est gate par le consent opt-in client-side (comportement attendu, leve par la confirmation navigateur Ludovic). L'isolation est confirmee : le funnel client emet vers le projet client wuk12h9i33, distinct du projet website wrff07upjx.

## 4. Dashboard Microsoft Clarity (surveillance passive)

| Verification | source | etat |
|---|---|---|
| nouveaux recordings funnel client post-deploiement | Microsoft Clarity projet wuk12h9i33 (login Ludovic) | A SURVEILLER PASSIVEMENT (non bloquant) |
| recordings affiches AVEC CSS | Microsoft Clarity replay | attendu OK (CSS rendu navigateur confirme) |

Le tracking reseau etant restaure (collect 204), l'ingestion des sessions du funnel client reprend. L'apparition des recordings dans le dashboard suit le delai de traitement Microsoft Clarity (quelques minutes a quelques heures) ; surveillance passive, pas de blocage.

## 5. No fake metrics / no fake events

| Garantie | etat |
|---|---|
| fake Clarity event / recording | 0 |
| synthetic pageview / session / conversion | 0 |
| consent force par le CE | 0 (consent accepte par Ludovic en navigateur reel) |
| build / deploy / kubectl | 0 (docs + Linear uniquement) |
| DB mutation | 0 |

## 6. Anti-regression

| Garantie | etat |
|---|---|
| website keybuzz.pro Clarity wrff07upjx | restaure (PH-20.15E) + isole du client | preserve |
| client.keybuzz.io Clarity wuk12h9i33 | restaure (PH-20.15I) + isole du website | preserve |
| KEY-263 api.keybuzz.io / api-dev | 87 / 0 | preserve |
| KEY-323 Amazon ecomlg-001 FR | inbound VALIDATED + outbound delivered | preserve |
| doublons Amazon | differes (PH-20.16) | preserve |
| autres services | non touches | preserve |

## 7. Decision

READY runtime + navigateur. Incidents Clarity PH-20.15 (website) et PH-20.15F (client) TECHNIQUEMENT RESOLUS : le tracking reseau Clarity fonctionne sur keybuzz.pro (projet wrff07upjx) ET sur le funnel client.keybuzz.io (projet wuk12h9i33) post-consent, CSS rendu correctement, isolation des deux projets confirmee. KEY-322 / KEY-325 peuvent etre clos par Ludovic (GO explicite requis ; statuts laisses inchanges par le CE). Surveillance passive du dashboard Microsoft Clarity wuk12h9i33 pour confirmer l'historisation des nouveaux recordings funnel client (non bloquant).

Durcissement recommande (non fait) : ajouter les build-args Clarity (wuk12h9i33 client + wrff07upjx website) + Meta/TikTok aux scripts de build standard des deux repos pour prevenir une nouvelle perte silencieuse (footgun NEXT_PUBLIC). Differe : doublons Amazon PH-20.16 (P0 Amazon reste restaure, ne pas rouvrir).

## 8. Phrase cible

GO CLOSE CLIENT CLARITY VERIFY HANDOFF READY PH-SAAS-T8.12AS.20.15J

STOP.
