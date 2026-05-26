# PH-SAAS-T8.12AS.20.15E-READONLY-VERIFY-CLARITY-DASHBOARD-FRESHNESS-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; reference KEY-323 restored
> Phase : PH-SAAS-T8.12AS.20.15E (READONLY VERIFY CLARITY DASHBOARD FRESHNESS)
> Environnement : PROD (lecture seule ; aucun deploy, aucun fake event)
> MAJ 2026-05-26 (CLOSE HANDOFF) : retour Ludovic DevTools integre ; verdict releve de PARTIAL a READY.

## 1. Verdict

GO READONLY VERIFY CLARITY DASHBOARD FRESHNESS READY PH-SAAS-T8.12AS.20.15E

Restauration Clarity CONFIRMEE de bout en bout (runtime + navigateur). Volet serveur : website PROD v0.6.22-clarity-restore-prod actif (digest GHCR 974350d5), live keybuzz.pro sert le bundle avec Clarity wrff07upjx + clarity.ms/tag + Meta + TikTok, CSS 200 text/css. Volet navigateur (retour Ludovic, DevTools keybuzz.pro apres consent) : requete clarity.ms/tag/wrff07upjx status 200, clarity.js status 200, beacon collect status 204, CSS rendu correctement cote navigateur. Le tracking reseau Clarity est donc RESTAURE et fonctionnel. Reste a surveiller passivement l'apparition de nouveaux recordings post-deploiement cote dashboard Microsoft Clarity (non bloquant). Aucun fake event/recording.

## 2. Runtime website PROD

| Signal | valeur | verdict |
|---|---|---|
| image deployment | v0.6.22-clarity-restore-prod | OK |
| pods | 2/2 ready, restarts=0 | OK |
| imageID runtime | @sha256:974350d524ba...87ac = digest GHCR | OK |

## 3. Live keybuzz.pro (read-only serveur)

| Marker/check | attendu | actual | verdict |
|---|---|---|---|
| HTTP keybuzz.pro | 200 | 200 | OK |
| wrff07upjx (bundle) | present | 1 | OK |
| clarity.ms/tag | present | 1 | OK |
| Meta pixel 1234164602194748 | present | 1 | OK |
| TikTok D7PT12JC77U44OJIPC10 | present | 1 | OK |
| GA G-R3QQDYEBFG | present | 1 | OK |
| CSS asset | 200 text/css | 200 text/css | OK |

## 4. Volet navigateur / DevTools (retour Ludovic - CONFIRME)

Retour Ludovic apres ouverture de keybuzz.pro et acceptation du bandeau consent (opt-in) :

| Verification | attendu | retour Ludovic | verdict |
|---|---|---|---|
| consent banner keybuzz.pro | acceptation opt-in | OK (accepte) | OK |
| requete clarity.ms/tag/wrff07upjx | 200 | status 200 | OK |
| script clarity.js | 200 | status 200 | OK |
| beacon collect (ingestion events Clarity) | 204 | status 204 | OK |
| rendu CSS cote navigateur | mise en forme correcte | CSS rendu correctement | OK |

Interpretation : la chaine complete Clarity est operationnelle post-consent (tag charge -> clarity.js charge -> events envoyes via collect 204). Le tracking reseau Clarity est RESTAURE. La requete n'apparaissait pas en curl serveur car le script est gate par le consent opt-in client-side (comportement attendu, desormais leve par la confirmation navigateur Ludovic).

## 5. Dashboard Microsoft Clarity (surveillance passive)

| Verification | source | etat |
|---|---|---|
| nouveaux recordings post-2026-05-26 19:45 UTC | Microsoft Clarity projet wrff07upjx (login Ludovic) | A SURVEILLER PASSIVEMENT (non bloquant) |
| recordings affiches AVEC CSS | Microsoft Clarity replay | attendu OK (CSS asset 200 + rendu navigateur confirme) |

Le tracking reseau etant restaure (collect 204), l'ingestion des sessions reprend. L'apparition des recordings dans le dashboard suit le delai de traitement Microsoft Clarity (quelques minutes a quelques heures) ; surveillance passive, pas de blocage.

## 6. No fake metrics / no fake events

| Garantie | etat |
|---|---|
| fake Clarity event / recording | 0 |
| synthetic pageview / session / conversion | 0 |
| consent force par le CE | 0 (consent accepte par Ludovic en navigateur reel) |
| deploy / mutation runtime | 0 (lecture seule) |
| DB mutation | 0 |

## 7. Anti-regression

| Garantie | etat |
|---|---|
| client.keybuzz.io | non touche (Clarity desactive KEY-325) |
| KEY-323 Amazon ecomlg-001 FR | preserve (inbound VALIDATED + outbound delivered) |
| doublons Amazon | differes (PH-20.16) |
| autres services | non touches |

## 8. Decision

READY runtime + navigateur. Incident Clarity PH-20.15 RESOLU : le tracking reseau Clarity (+ Meta + TikTok restaures) fonctionne sur keybuzz.pro post-consent, CSS rendu correctement. KEY-322 peut etre clos par Ludovic (GO explicite requis ; statut laisse inchange par le CE). Surveillance passive du dashboard Microsoft Clarity pour confirmer l'historisation des nouveaux recordings (non bloquant). Durcissement recommande : ajouter les build-args Clarity/Meta/TikTok au script de build website standard pour prevenir une nouvelle perte silencieuse. Differe : doublons Amazon PH-20.16 (P0 Amazon reste restaure, ne pas rouvrir).

## 9. Phrase cible

GO READONLY VERIFY CLARITY DASHBOARD FRESHNESS READY PH-SAAS-T8.12AS.20.15E

STOP.
