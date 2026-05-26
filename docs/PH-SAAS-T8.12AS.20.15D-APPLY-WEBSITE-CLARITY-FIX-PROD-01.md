# PH-SAAS-T8.12AS.20.15D-APPLY-WEBSITE-CLARITY-FIX-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; reference KEY-323 restored
> Phase : PH-SAAS-T8.12AS.20.15D (APPLY WEBSITE CLARITY FIX PROD)
> Environnement : PROD (mutation runtime website via GitOps strict)

## 1. Verdict

GO APPLY WEBSITE CLARITY FIX PROD READY PH-SAAS-T8.12AS.20.15D

Website PROD deploye v0.6.22-clarity-restore-prod via GitOps strict. manifest = last-applied = runtime = v0.6.22 ; imageID runtime @sha256:974350d524ba... = digest GHCR ; 2 pods ready, restarts=0, ancien pod v0.6.21 termine. Live keybuzz.pro (HTTP 200) : Clarity wrff07upjx PRESENT (etait 0 avant), clarity.ms/tag PRESENT, Meta + TikTok pixels RESTAURES, GA preserve, 0 fuite api-dev, CSS 200 text/css. Le script Clarity ne fait sa requete reseau qu'apres consent (gating client-side) -> handoff Ludovic pour QA consent + recording. client.keybuzz.io non touche, KEY-323 Amazon preserve. Rollback v0.6.21 documente.

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 19:45.

| Service/check | before | expected | verdict |
|---|---|---|---|
| keybuzz-infra | main 99453aa = origin, clean | clean | OK |
| GHCR v0.6.22 | present, config digest 619afbd9 | present | OK |
| website PROD runtime | v0.6.21-pricing-action-recover-prod, 2/2 ready | v0.6.21 | OK |
| keybuzz.pro live (baseline) | HTTP 200, wrff07upjx 0 / Meta 0 / TikTok 0 / GA 1 | Clarity absent | OK (incident confirme) |
| manifest path | k8s/website-prod/deployment.yaml | - | OK |

## 3. Snapshot before (E1)

| Signal | before | verdict |
|---|---|---|
| manifest spec image | v0.6.21-pricing-action-recover-prod | baseline |
| last-applied image | v0.6.21-pricing-action-recover-prod | baseline |
| runtime imageID | @sha256:8fefca2e... (v0.6.21) | baseline |
| pods | 2/2 ready, restarts=0 | baseline |
| keybuzz.pro wrff07upjx / clarity.ms/tag | 0 / 0 | Clarity absent (incident) |
| keybuzz.pro Meta / TikTok / GA | 0 / 0 / 1 | Meta+TikTok absents, GA present |

## 4. Manifest diff (E2)

| Fichier | avant | apres |
|---|---|---|
| k8s/website-prod/deployment.yaml L36 image | v0.6.21-pricing-action-recover-prod (digest 8fefca2e, PH-20.10B) | v0.6.22-clarity-restore-prod (# PH-20.15D, digest 974350d5, rollback v0.6.21) |

Diff = 1 ligne (image L36 + commentaire). namespace/env/probes/resources/labels/selectors/imagePullSecrets/service inchanges. Aucun autre service touche. Note : la chaine v0.6.21-pricing-action-recover-prod subsiste 1x dans le commentaire (mention rollback volontaire), pas dans l'image active.

## 5. Dry-run (E3)

| Commande | resultat |
|---|---|
| apply --dry-run=client | deployment configured (dry run) ; service + namespace configured |
| apply --dry-run=server | deployment configured (server dry run) ; service + namespace unchanged |
| v0.6.22 present / latest absent / namespace | 1 / 0 / keybuzz-website-prod | 

## 6. Rollout (E5)

| Etape | resultat |
|---|---|
| commit infra avant apply | 0f490fd (manifest) pousse origin/main AVANT apply |
| kubectl apply -f | deployment configured ; service + namespace unchanged |
| rollout status | successfully rolled out (2 nouveaux replicas, ancien termine) |
| pods | keybuzz-website-6b5b7bc868-4qxpd + -x2lqk : ready, restarts=0, v0.6.22 |
| ancien pod v0.6.21 | termine (plus present) |

GitOps strict : commit+push AVANT apply ; kubectl apply -f uniquement (aucun set image/patch/edit/rollout restart).

## 7. Runtime digest (E6)

| Service | manifest | last-applied | runtime | digest | ready | verdict |
|---|---|---|---|---|---|---|
| keybuzz-website PROD | v0.6.22-clarity-restore-prod | v0.6.22-clarity-restore-prod | v0.6.22-clarity-restore-prod | imageID @sha256:974350d524ba... = GHCR manifest digest | 2/2 true | OK |

Triple egalite manifest=last-applied=runtime confirmee ; digest runtime == GHCR 974350d5.

## 8. Live QA keybuzz.pro (E7)

| Marker/check | expected | actual | verdict |
|---|---|---|---|
| HTTP keybuzz.pro | 200 | 200 | OK |
| wrff07upjx dans bundle | present | 1 (etait 0 avant) | RESTAURE |
| clarity.ms/tag | present | 1 | RESTAURE |
| Meta pixel 1234164602194748 | present | 1 (etait 0) | RESTAURE |
| TikTok D7PT12JC77U44OJIPC10 | present | 1 (etait 0) | RESTAURE |
| GA G-R3QQDYEBFG | present | 1 | OK |
| api-dev leak | 0 | 0 | OK |
| CSS asset | 200 text/css | 200 text/css | OK |
| 5xx | aucun | aucun | OK |

Note comptes : echantillon = chunks de la home uniquement (1 occurrence) vs image complete (2) ; le marqueur PRESENT (vs 0 avant) prouve la restauration. x-nextjs-cache HIT sert deja le HTML du nouveau build (chunks avec Clarity). Le script Clarity s'execute uniquement APRES consent (opt-in client-side) : aucune requete reseau clarity.ms en curl sans consent = comportement attendu, pas un echec.

## 9. No fake metrics / no fake events (E8)

| Garantie | etat |
|---|---|
| fake Clarity event / pageview / session | 0 |
| synthetic conversion | 0 |
| analytics backfill | 0 |
| DB mutation | 0 |
| consent/cookie force | 0 |

## 10. AI feature parity / anti-regression (E9)

| Garantie | etat |
|---|---|
| client.keybuzz.io | non touche (Clarity reste desactive, KEY-325) |
| Amazon KEY-323 ecomlg-001 FR (inbound VALIDATED + outbound delivered) | preserve |
| inbound/outbound pipeline Amazon / runtime PH-20.14 | non touche |
| doublons Amazon | differes (PH-20.16) |
| KBActions / AI suggestions | non touches |
| autres services (API/client/backend/admin) | non touches (apply website-only) |

## 11. Handoff Ludovic

Ouvrir https://keybuzz.pro , accepter le bandeau consent (opt-in), puis dans DevTools (onglet Network) verifier la requete vers clarity.ms/tag/wrff07upjx (status 200). Ensuite, cote Microsoft Clarity (projet wrff07upjx), verifier l'apparition de NOUVEAUX recordings post-2026-05-26 19:45 UTC AVEC CSS (mise en forme correcte). Verifier aussi (optionnel) Meta Events Manager + TikTok pour la reprise des pixels. Ne PAS faker d'event.

## 12. Rollback

| Niveau | action |
|---|---|
| Manifest | repasser image L36 v0.6.22 -> v0.6.21-pricing-action-recover-prod (digest 8fefca2e toujours sur GHCR) + commit + push + kubectl apply -f + rollout |
| Methode | GitOps strict uniquement ; JAMAIS kubectl set image |
| Note | v0.6.21 = etat sans Clarity/Meta/TikTok (revient a l'incident) ; rollback seulement si regression fonctionnelle website |

## 13. Prochaine phase

GO READONLY VERIFY CLARITY DASHBOARD FRESHNESS PH-SAAS-T8.12AS.20.15E (handoff Ludovic : confirmer nouveaux recordings Clarity wrff07upjx AVEC CSS + reprise data). Durcissement recommande : ajouter les build-args Clarity/Meta/TikTok au script de build website standard pour eviter une nouvelle perte silencieuse. Differe : doublons Amazon PH-20.16 (P0 Amazon ecomlg-001 FR reste restaure, ne pas rouvrir).

## 14. Phrase cible

GO APPLY WEBSITE CLARITY FIX PROD READY PH-SAAS-T8.12AS.20.15D

STOP.
