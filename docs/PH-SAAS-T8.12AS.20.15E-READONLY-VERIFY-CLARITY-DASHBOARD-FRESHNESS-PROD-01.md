# PH-SAAS-T8.12AS.20.15E-READONLY-VERIFY-CLARITY-DASHBOARD-FRESHNESS-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; reference KEY-323 restored
> Phase : PH-SAAS-T8.12AS.20.15E (READONLY VERIFY CLARITY DASHBOARD FRESHNESS)
> Environnement : PROD (lecture seule ; aucun deploy, aucun fake event)

## 1. Verdict

GO READONLY VERIFY CLARITY DASHBOARD FRESHNESS PARTIAL PH-SAAS-T8.12AS.20.15E

Volet serveur READY : website PROD v0.6.22-clarity-restore-prod confirme actif (digest GHCR 974350d5), live keybuzz.pro sert le bundle avec Clarity wrff07upjx + clarity.ms/tag + Meta + TikTok, CSS 200 text/css. Volet dashboard PENDING : la confirmation de la requete reseau clarity.ms/tag/wrff07upjx apres consent (DevTools) + la presence de NOUVEAUX recordings AVEC CSS cote Microsoft Clarity (projet wrff07upjx) exige un login Microsoft + acceptation consent navigateur, non realisables par le CE et non encore fournis par Ludovic. Aucun fake event/recording cree.

## 2. Runtime website PROD

| Signal | valeur | verdict |
|---|---|---|
| image deployment | v0.6.22-clarity-restore-prod | OK |
| pods | 2/2 ready, restarts=0 | OK |
| imageID runtime | @sha256:974350d524ba...87ac = digest GHCR | OK |

## 3. Live keybuzz.pro (read-only)

| Marker/check | attendu | actual | verdict |
|---|---|---|---|
| HTTP keybuzz.pro | 200 | 200 | OK |
| wrff07upjx (bundle) | present | 1 | OK |
| clarity.ms/tag | present | 1 | OK |
| Meta pixel 1234164602194748 | present | 1 | OK |
| TikTok D7PT12JC77U44OJIPC10 | present | 1 | OK |
| GA G-R3QQDYEBFG | present | 1 | OK |
| CSS asset | 200 text/css | 200 text/css | OK |

## 4. Volet dashboard / DevTools (retour Ludovic - PENDING)

| Verification | source requise | etat |
|---|---|---|
| requete reseau clarity.ms/tag/wrff07upjx status 200 apres consent | DevTools navigateur Ludovic (consent opt-in) | EN ATTENTE |
| nouveau recording Clarity post-2026-05-26 19:45 UTC | Microsoft Clarity projet wrff07upjx (login) | EN ATTENTE |
| recording affiche AVEC CSS (mise en forme correcte) | Microsoft Clarity replay | EN ATTENTE |

Le CE ne peut ni se connecter a Microsoft Clarity ni accepter le consent navigateur (gating client-side opt-in) ; aucun retour Ludovic fourni dans la phase. Ces 3 points constituent le handoff Ludovic restant. Rappel : le script Clarity est present dans le bundle servi mais ne declenche sa requete reseau qu'apres acceptation explicite du consent ; l'absence de requete en curl est donc normale et n'invalide pas le fix.

## 5. No fake metrics / no fake events

| Garantie | etat |
|---|---|
| fake Clarity event / recording | 0 |
| synthetic pageview / session / conversion | 0 |
| consent force | 0 |
| deploy / mutation runtime | 0 (lecture seule) |
| DB mutation | 0 |

## 6. Anti-regression

| Garantie | etat |
|---|---|
| client.keybuzz.io | non touche (Clarity desactive KEY-325) |
| KEY-323 Amazon ecomlg-001 FR | preserve (inbound VALIDATED + outbound delivered) |
| doublons Amazon | differes (PH-20.16) |
| autres services | non touches |

## 7. Decision

Server-side restauration confirmee READY (runtime v0.6.22 + bundle live Clarity/Meta/TikTok + CSS 200). Freshness dashboard = PENDING handoff Ludovic. Verdict PARTIAL jusqu'a confirmation Ludovic des 3 points dashboard/DevTools.

Prochaine action : handoff Ludovic (ouvrir keybuzz.pro, accepter consent, verifier DevTools requete clarity.ms/tag/wrff07upjx 200, puis Microsoft Clarity nouveaux recordings AVEC CSS). Une fois confirme, clore KEY-322. Durcissement recommande : ajouter build-args Clarity/Meta/TikTok au script de build website standard.

## 8. Phrase cible

GO READONLY VERIFY CLARITY DASHBOARD FRESHNESS PARTIAL PH-SAAS-T8.12AS.20.15E

STOP.
