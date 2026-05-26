# PH-SAAS-T8.12AS.20.15H-PUSH-IMAGE-CLIENT-CLARITY-RESTORE-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322/KEY-325 Clarity tracking
> Phase : PH-SAAS-T8.12AS.20.15H (PUSH CLIENT IMAGE ONLY)
> Environnement : PROD preparation (push GHCR uniquement ; aucun build, deploy, kubectl, manifest)

## 1. Verdict

GO PUSH IMAGE CLIENT CLARITY RESTORE PROD DONE PH-SAAS-T8.12AS.20.15H

Image v3.5.217-clarity-client-restore-prod poussee sur GHCR. Manifest digest sha256:e75ac3ad37ed6643ea5a69b2546c286f0646d1ed719e9022fcbd1b677e45030a ; config digest remote sha256:6a20d9b79bf6... == Image ID locale (DIGEST_MATCH) ; OCI revision ef239e8 + version v3.5.217-clarity-client-restore-prod confirmes remote ; pull-back rmi+pull OK (RepoDigest @e75ac3ad). latest NON pousse par cette phase (latest preexistant pointe sur config dfdb7dce, different). Aucun runtime modifie : client PROD reste v3.5.215-ai-draft-blocked-reason-prod (1 pod ready, restarts=0), aucun manifest GitOps ne reference v3.5.217, repo infra clean. Pret pour la phase apply (15I).

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 20:30.

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-client | ph148/onboarding-activation-replay ef239e8 | ef239e8 | clean | OK |
| keybuzz-infra | - | - | 0 dirty | OK |
| runtime client PROD | v3.5.215-ai-draft-blocked-reason-prod | v3.5.215 (inchange) | ready | OK |
| image locale v3.5.217 | ID 6a20d9b79bf6 | presente | - | OK |
| GHCR v3.5.217 avant push | ABSENT | absent | - | OK (pas de collision) |

## 3. Image locale (E1)

| Item | valeur |
|---|---|
| Tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.217-clarity-client-restore-prod |
| Image ID | sha256:6a20d9b79bf65ca44e77a61624614af6f7da910989b68bed00fd02dedad2a6ea |
| OCI revision | ef239e898887ba052ede3f9592991e1093f74985 |
| OCI version | v3.5.217-clarity-client-restore-prod |
| OCI created | 2026-05-26T20:22:59Z |
| Bundle markers (PH-20.15G, meme Image ID) | wuk12h9i33=2, clarity.ms/tag=2, ms-clarity=2, data-clarity-mask=2, wrff07upjx=0, api.keybuzz.io=87, api-dev=0, MUST_BE_SET_BY_BUILD_ARG=0, CSS 2 + JS 83 |

Image ID identique a celui audite en PH-20.15G : bundle inchange (Clarity client wuk12h9i33 restaure, API PROD, anti KEY-263/302).

## 4. GHCR avant/apres (E2/E3)

| Etape | resultat |
|---|---|
| GHCR avant push | ABSENT (docker manifest inspect KO) |
| docker push (tag unique) | 3 layers Pushed + 2 already exists |
| Manifest digest | sha256:e75ac3ad37ed6643ea5a69b2546c286f0646d1ed719e9022fcbd1b677e45030a |
| size manifest | 2631 |
| Autre tag pousse | aucun (tag unique uniquement) |

## 5. Digest match (E4)

| Item | local | remote | verdict |
|---|---|---|---|
| config digest | 6a20d9b79bf6...a6ea (Image ID) | 6a20d9b79bf6...a6ea (manifest config) | MATCH |
| manifest digest | - | sha256:e75ac3ad37ed...030a | documente |
| RepoDigest (pull-back) | - | @sha256:e75ac3ad37ed...030a | OK |
| Image ID apres pull | 6a20d9b79bf6 | 6a20d9b79bf6 | MATCH (inchange) |
| OCI revision | ef239e8988...f74985 | ef239e8988...f74985 | MATCH |
| OCI version | v3.5.217-clarity-client-restore-prod | idem | MATCH |
| latest | non pousse | latest preexistant = config dfdb7dce (DIFFERENT) | OK (non touche) |

## 6. Runtime preserve (E5)

| Signal | etat | verdict |
|---|---|---|
| runtime client PROD | v3.5.215-ai-draft-blocked-reason-prod | inchange |
| pods client PROD | 1 ready, restarts=0, image v3.5.215 | inchange |
| deploy referencant v3.5.217 | aucun | OK |
| manifest infra ref v3.5.217 | ABSENT | OK |
| repo infra | 0 dirty | clean |

## 7. Interdits respectes

| Interdit | etat |
|---|---|
| build / docker build | aucun |
| deploy / kubectl apply/set/patch/edit | aucun |
| manifest GitOps modifie | aucun |
| autre tag / latest pousse | aucun (tag unique v3.5.217) |
| website / Amazon | non touches |
| fake Clarity event / pageview / conversion | aucun |

## 8. Prochaine phase

GO APPLY CLIENT CLARITY RESTORE PROD PH-SAAS-T8.12AS.20.15I : GitOps bump deployment client PROD v3.5.215-ai-draft-blocked-reason-prod -> v3.5.217-clarity-client-restore-prod (commit manifest + push AVANT apply -> kubectl apply -f -> rollout status -> verifier manifest=last-applied=runtime=digest e75ac3ad/config 6a20d9b79bf6) + QA consent funnel (sur /register apres consent : requete clarity.ms/tag/wuk12h9i33). Rollback documente : v3.5.215 conserve. Durcissement recommande : ajouter build-args Clarity (client wuk12h9i33 + website wrff07upjx) aux scripts de build standard.

## 9. Phrase cible

GO PUSH IMAGE CLIENT CLARITY RESTORE PROD DONE PH-SAAS-T8.12AS.20.15H

STOP.
