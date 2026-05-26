# PH-SAAS-T8.12AS.20.15I-APPLY-CLIENT-CLARITY-RESTORE-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; KEY-325 client Clarity
> Phase : PH-SAAS-T8.12AS.20.15I (APPLY CLIENT CLARITY RESTORE PROD)
> Environnement : PROD (GitOps strict ; bump image client v3.5.215 -> v3.5.217 ; aucun fake event)

## 1. Verdict

GO APPLY CLIENT CLARITY RESTORE PROD READY PH-SAAS-T8.12AS.20.15I

Le funnel client.keybuzz.io sert desormais le bundle v3.5.217-clarity-client-restore-prod qui reintegre Microsoft Clarity (project ID client wuk12h9i33), perdu depuis v3.5.201 (build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID omis, regression diagnostiquee en PH-20.15F). Apply GitOps strict : manifest commit+push AVANT apply, kubectl apply -f uniquement, rollout OK. Triple correspondance runtime = manifest = last-applied = digest GHCR sha256:e75ac3ad. Invariants KEY-263 (isolation PROD api.keybuzz.io=87, api-dev=0) et KEY-302 (sentinel MUST_BE_SET_BY_BUILD_ARG=0) preserves. Isolation tracking confirmee : wuk12h9i33 present, project website wrff07upjx absent du bundle client. Aucun fake event, aucune mutation DB, website PROD inchange. Reste la confirmation passive du dashboard Microsoft Clarity wuk12h9i33 cote Ludovic (PH-20.15J, non bloquant).

## 2. Preflight (E0)

| Signal | attendu | actual | verdict |
|---|---|---|---|
| bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| infra HEAD = origin | egal, clean | 5f73fd2 = 5f73fd2, 0 dirty | OK |
| GHCR v3.5.217 config digest | 6a20d9b79bf6 | 6a20d9b79bf6 | OK |
| runtime client PROD AVANT | v3.5.215 | v3.5.215, pod ready, restarts=0 | OK |
| manifest path / ligne image | k8s/keybuzz-client-prod/deployment.yaml L76 | L76 = v3.5.215 | OK |
| website PROD inchange | v0.6.22 | v0.6.22-clarity-restore-prod | OK |

## 3. Snapshot BEFORE live client (E1)

| Marker /register | attendu (incident) | actual | verdict |
|---|---|---|---|
| HTTP /register | 200 | 200 | OK |
| wuk12h9i33 (Clarity client) | 0 (absent = incident) | 0 | OK baseline |
| clarity.ms/tag | 0 | 0 | OK baseline |

## 4. Patch manifest (E2-E3)

| Element | valeur |
|---|---|
| fichier | k8s/keybuzz-client-prod/deployment.yaml |
| ligne | L76 (image, indent 10) |
| AVANT | v3.5.215-ai-draft-blocked-reason-prod |
| APRES | v3.5.217-clarity-client-restore-prod |
| fichiers modifies | 1 (image uniquement) |
| dry-run=client | deployment.apps/keybuzz-client configured | 
| dry-run=server | deployment.apps/keybuzz-client configured (server dry run) |

## 5. Commit + push AVANT apply (E4)

| Element | valeur |
|---|---|
| commit | fabcfe4 |
| message | chore(clarity): deploy client clarity restore prod v3.5.217 (PH-20.15I, KEY-322/325/337) |
| push | 5f73fd2..fabcfe4 main -> main |
| HEAD post-push = origin | fabcfe4 = fabcfe4 | 

## 6. Apply + rollout (E5)

| Element | resultat |
|---|---|
| kubectl apply -f | deployment.apps/keybuzz-client configured |
| rollout status | successfully rolled out |
| kubectl set/edit/patch utilise | NON (apply -f uniquement) |

## 7. Verification runtime = manifest = last-applied = digest (E6)

| Source | image | verdict |
|---|---|---|
| manifest spec | v3.5.217-clarity-client-restore-prod | OK |
| last-applied-configuration | v3.5.217-clarity-client-restore-prod | OK |
| runtime pod | v3.5.217-clarity-client-restore-prod, ready, restarts=0 | OK |
| imageID runtime | sha256:e75ac3ad...30a = digest GHCR | OK |

Pod : keybuzz-client-68cc6d5b8c-kg4br.

## 8. QA technique live + bundle runtime pod (E7)

Live client.keybuzz.io :

| Check | attendu | actual | verdict |
|---|---|---|---|
| HTTP / | 307 (redirect login) | 307 | OK |
| HTTP /register | 200 | 200 | OK |
| wuk12h9i33 (bundle funnel /register) | present | 1 | OK |
| clarity.ms/tag (bundle funnel) | present | 1 | OK |
| wrff07upjx (website, bundle client) | absent | 0 | OK |
| api-dev.keybuzz.io (bundle funnel) | absent | 0 | OK |
| MUST_BE_SET_BY_BUILD_ARG (bundle funnel) | absent | 0 | OK |

Bundle runtime pod /app/.next (autoritaire) :

| Marker | attendu | actual | verdict |
|---|---|---|---|
| api.keybuzz.io | present (KEY-263) | 87 | OK |
| api-dev.keybuzz.io | 0 | 0 | OK |
| wuk12h9i33 (Clarity client) | present | 2 | OK |
| wrff07upjx (website) | 0 | 0 | OK |
| MUST_BE_SET_BY_BUILD_ARG (KEY-302) | 0 | 0 | OK |
| logs 5xx/error/fatal/unhandled | 0 | 0 | OK |

Note : api.keybuzz.io = 0 dans les 13 chunks JS de /register est attendu (l'URL API est dans les chunks de l'app authentifiee, pas la page register) ; le bundle runtime complet du pod confirme api.keybuzz.io=87.

## 9. No fake metrics / no fake events

| Garantie | etat |
|---|---|
| fake Clarity event / recording | 0 |
| synthetic pageview / session / conversion | 0 |
| consent force par le CE | 0 (Clarity reste gate par consent opt-in client-side) |
| fake event GA4 / CAPI / TikTok / LinkedIn | 0 |
| DB mutation | 0 |

## 10. Anti-regression PROD

| Garantie | avant | apres | etat |
|---|---|---|---|
| website PROD keybuzz.pro | v0.6.22 | v0.6.22 | inchange |
| client Clarity wuk12h9i33 | absent (v3.5.215) | present (v3.5.217) | restaure |
| isolation website wrff07upjx | absent du client | absent du client | preserve |
| KEY-263 api.keybuzz.io / api-dev | 87 / 0 | 87 / 0 | preserve |
| KEY-302 sentinel | 0 | 0 | preserve |
| KEY-323 Amazon ecomlg-001 FR | inbound VALIDATED + outbound delivered | non touche | preserve |
| doublons Amazon | differes (PH-20.16) | non touche | preserve |
| autres services | - | non touches | preserve |

## 11. GitOps strict (recapitulatif)

| Regle | respect |
|---|---|
| commit + push AVANT apply | OUI (fabcfe4 pousse avant apply) |
| build-from-git (image deja construite/push 15G/15H) | OUI |
| tag immuable (jamais :latest) | OUI (v3.5.217-clarity-client-restore-prod) |
| digest documente | OUI (manifest e75ac3ad ; config 6a20d9b79bf6) |
| rollback prevu | OUI (v3.5.215-ai-draft-blocked-reason-prod) |
| kubectl apply -f uniquement | OUI |

## 12. Linear

KEY-337 / KEY-322 / KEY-325 : commentaire d'avancement uniquement (apply client Clarity PROD READY). Aucun changement de statut (laisse a Ludovic, GO explicite requis).

## 13. Gaps restants

- PH-20.15J : confirmation passive dashboard Microsoft Clarity wuk12h9i33 (apparition recordings funnel client post-2026-05-26 ; delai traitement Microsoft, non bloquant). Handoff QA navigateur Ludovic (client.keybuzz.io + consent + DevTools clarity.ms/tag/wuk12h9i33 200 / collect 204).
- Durcissement : ajouter les build-args Clarity (NEXT_PUBLIC_CLARITY_PROJECT_ID) au script de build client standard pour prevenir une nouvelle perte silencieuse (meme footgun que website PH-20.15).
- PH-20.16 : doublons Amazon inbound (differe ; P0 Amazon reste restaure, ne pas rouvrir).

## 14. Phrase cible

GO APPLY CLIENT CLARITY RESTORE PROD READY PH-SAAS-T8.12AS.20.15I

STOP.
