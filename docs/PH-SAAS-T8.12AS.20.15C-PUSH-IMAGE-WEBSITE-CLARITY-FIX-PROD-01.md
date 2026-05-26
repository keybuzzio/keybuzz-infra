# PH-SAAS-T8.12AS.20.15C-PUSH-IMAGE-WEBSITE-CLARITY-FIX-PROD-01

> Date : 2026-05-26
> Linear : KEY-337 parent PH-20 ; KEY-322 Clarity/tracking ; reference KEY-323 restored
> Phase : PH-SAAS-T8.12AS.20.15C (PUSH WEBSITE IMAGE ONLY)
> Environnement : PROD preparation (push GHCR uniquement ; aucun build, deploy, kubectl, manifest)

## 1. Verdict

GO PUSH IMAGE WEBSITE CLARITY FIX PROD DONE PH-SAAS-T8.12AS.20.15C

Image v0.6.22-clarity-restore-prod poussee sur GHCR. Manifest digest sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac ; config digest remote sha256:619afbd95b82... == Image ID locale (DIGEST_MATCH) ; OCI revision 907689bf... + version v0.6.22-clarity-restore-prod confirmes remote ; pull-back rmi+pull OK (RepoDigest @974350d5). latest NON pousse par cette phase (latest preexistant pointe sur un digest different 8b129ecf). Aucun runtime modifie : website PROD reste v0.6.21-pricing-action-recover-prod (2 pods ready, restarts=0), aucun manifest GitOps ne reference v0.6.22, repo infra clean. Pret pour la phase apply (15D).

## 2. Preflight (E0)

Bastion install-v3 / 46.62.171.61 confirme ; date UTC 2026-05-26 19:26.

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-website | main 907689b | 907689b | clean | OK |
| keybuzz-infra | - | - | 0 dirty | OK |
| runtime website PROD | v0.6.21-pricing-action-recover-prod | v0.6.21 (inchange) | 2/2 ready | OK |
| image locale v0.6.22 | ID 619afbd95b82 | presente | - | OK |
| GHCR v0.6.22 avant push | ABSENT | absent | - | OK (pas de collision) |

## 3. Image locale (E1)

| Item | valeur |
|---|---|
| Tag local | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod |
| Image ID | sha256:619afbd95b82eca17f3fc7af0005ab5d7566b4e0835a7e096c11c49340841568 |
| OCI revision | 907689bf51678c4d97785d9316f21f03ea074f9f |
| OCI version | v0.6.22-clarity-restore-prod |
| OCI created | 2026-05-26T19:19:54Z |
| Bundle markers (PH-20.15B, meme Image ID) | wrff07upjx=2, clarity.ms/tag=2, clarity-init=2, Meta=2, TikTok=2, GA=18, CSS 1 + JS 17, 0 api-dev |

Image ID identique a celui audite en PH-20.15B : bundle inchange (Clarity + Meta + TikTok restaures).

## 4. GHCR avant/apres (E2/E3)

| Etape | resultat |
|---|---|
| GHCR avant push | ABSENT (docker manifest inspect KO) |
| docker push (tag unique) | 3 layers Pushed + 2 already exists |
| Manifest digest | sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac |
| size manifest | 2619 |
| Autre tag pousse | aucun (tag unique uniquement) |

## 5. Digest match (E4)

| Item | local | remote | verdict |
|---|---|---|---|
| config digest | 619afbd95b82...841568 (Image ID) | 619afbd95b82...841568 (manifest config) | MATCH |
| manifest digest | - | sha256:974350d524ba...87ac | documente |
| RepoDigest (pull-back) | - | @sha256:974350d524ba...87ac | OK |
| Image ID apres pull | 619afbd95b82 | 619afbd95b82 | MATCH (inchange) |
| OCI revision | 907689bf51678c4d... | 907689bf51678c4d... | MATCH |
| OCI version | v0.6.22-clarity-restore-prod | v0.6.22-clarity-restore-prod | MATCH |
| latest | non pousse | latest preexistant = config 8b129ecf (DIFFERENT) | OK (non touche par cette phase) |

## 6. Runtime preserve (E5)

| Signal | etat | verdict |
|---|---|---|
| runtime website PROD | v0.6.21-pricing-action-recover-prod | inchange |
| pods website PROD | 2/2 ready, restarts=0, image v0.6.21 | inchange |
| deploy referencant v0.6.22 | aucun | OK |
| manifest infra ref v0.6.22 | ABSENT | OK |
| repo infra | 0 dirty | clean |
| restart inattendu | aucun | OK |

## 7. Interdits respectes

| Interdit | etat |
|---|---|
| build / docker build | aucun |
| deploy / kubectl apply/set/patch/edit | aucun |
| manifest GitOps modifie | aucun |
| autre tag / latest pousse | aucun (tag unique v0.6.22) |
| DNS / CSP / CDN change | aucun |
| fake Clarity event / pageview / conversion | aucun |
| client.keybuzz.io | non touche |
| doublons Amazon / Amazon runtime | non touches (KEY-323 preserve) |

## 8. Prochaine phase

GO APPLY WEBSITE CLARITY FIX PROD PH-SAAS-T8.12AS.20.15D : GitOps bump deployment website PROD v0.6.21-pricing-action-recover-prod -> v0.6.22-clarity-restore-prod (commit manifest + push AVANT apply -> kubectl apply -f -> rollout status -> verifier manifest=last-applied=runtime=digest 974350d5/config 619afbd9) + QA Ludovic consent (avant consent 0 requete clarity.ms ; apres consent requete clarity.ms/tag/wrff07upjx) + nouveau recording AVEC CSS. Rollback documente : v0.6.21-pricing-action-recover-prod conserve. Durcissement recommande : ajouter les build-args Clarity/Meta/TikTok au script de build website standard.

## 9. Phrase cible

GO PUSH IMAGE WEBSITE CLARITY FIX PROD DONE PH-SAAS-T8.12AS.20.15C

STOP.
