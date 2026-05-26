# PH-SAAS-T8.12AS.20.14W-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14V / PH-20.14U / PH-20.14S-RCA
> Phase : PH-SAAS-T8.12AS.20.14W (PUSH IMAGE ONLY image backend DEV vers GHCR)
> Environnement : DEV (push registry uniquement ; aucun build, aucun deploy, aucun kubectl, aucun manifest)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14W

Image backend DEV immuable v1.0.53-amazon-validation-pipeline-dev (construite en PH-20.14V from-git depuis commit 1179c15) poussee sur GHCR. Digest manifest sha256:5b893934ad7fdfa69093c90d4067e81e3cb649dd9cd964c4797a74fbba886368. Config digest remote (Image ID apres pull-back) == Image ID locale sha256:377764c8bcb2. Labels OCI remote revision=1179c15 / version=v1.0.53-amazon-validation-pipeline-dev == local. latest non pousse. Aucun autre tag pousse. Aucun build, aucun deploy, aucun kubectl, aucun manifest GitOps modifie, aucune mutation DB, aucun email, aucun trigger. Runtime DEV reste v1.0.52 (API + jobs-worker, pods inchanges age 06:43, restarts=0). PROD intact v1.0.47.

Prochaine phrase GO : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14X (bump manifests DEV API + jobs-worker vers v1.0.53 -> commit -> push -> kubectl apply -> rollout -> verify manifest=runtime=digest), puis re-trigger PH-20.14S-bis SOUS observabilite.

## 2. Sources relues

PH-20.14V (build image v1.0.53), PH-20.14U (source patch observabilite + durcissement JOB_TYPES), PH-20.14S-RCA (gap observabilite). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight (repo / runtime)

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD 1179c15 | origin/main 1179c15 | clean | OK |
| keybuzz-infra | HEAD 09add1d | origin/main 09add1d | dirty=0 | OK |
| API DEV (runtime) | v1.0.52 | v1.0.52 (non touche) | ready | OK |
| jobs-worker DEV (runtime) | v1.0.52 | v1.0.52 (non touche) | ready | OK |
| PROD backend | v1.0.47-cross-env-guard-fix-prod | intact | - | INTACT |
| image locale v1.0.53 | presente (377764c8bcb2) | rev 1179c15 / ver v1.0.53 | ready | OK |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

## 4. Image locale (avant push)

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.53-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:377764c8bcb24823a8bf9e059913c626cdc49792e8a0632fb6fc86fc7406d268 | OK |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | OK (== 1179c15) |
| OCI version | v1.0.53-amazon-validation-pipeline-dev | OK |

Markers dist verifies (read-only) : heartbeat, claim/done/fail jobId, OUTBOUND start/result, claim DISABLED guard, parseJobTypesEnv (raw == null), JOB_TYPES (2 fichiers), sendOutboundEmailById (2), emailAddress insensitive (equals: to.trim() ligne 200), isValidationEmail(subject) : TOUS presents. OUTBOUND_EMAIL_SEND not implemented = 0.

NB : grep large marketplace.toUpperCase() dans inbound.service.js = 1 occurrence (ligne 140) ; verification : il s agit du updateMany WHERE de updateMarketplaceStatusIfAmazon (normalisation de la cible d ecriture du write-back VALIDATED : marketplace + country uppercase), PAS l ancien pre-filtre casse-dependant supprime en 14O. La resolution du candidat utilise bien emailAddress equals insensitive (ligne 200). Pas de regression ; le marker 0 du rapport 14V utilisait un pattern plus etroit.

## 5. GHCR avant / apres

| Etat | v1.0.53 sur GHCR | latest | autre tag pousse |
|---|---|---|---|
| avant push | ABSENT | ABSENT | - |
| apres push | PRESENT (digest sha256:5b893934...) | ABSENT | aucun |

E2 collision : tag v1.0.53 ABSENT avant push -> pas de STOP. E3 : un seul docker push de v1.0.53-amazon-validation-pipeline-dev (10 layers already exist, 1 layer pushed : 48b9b907354d).

## 6. Digest match (pull-back depuis GHCR)

Procedure : suppression image locale -> docker pull depuis GHCR (preuve registry, pas cache local) -> inspect.

| Item | local | remote (pull-back) | verdict |
|---|---|---|---|
| Image ID (config digest) | sha256:377764c8bcb2... | sha256:377764c8bcb2... | MATCH |
| RepoDigest (manifest) | - | sha256:5b893934ad7fdfa69093c90d4067e81e3cb649dd9cd964c4797a74fbba886368 | DOCUMENTE |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | 1179c1547de3c06db9c0accd2fd2179a87da7151 | MATCH |
| OCI version | v1.0.53-amazon-validation-pipeline-dev | v1.0.53-amazon-validation-pipeline-dev | MATCH |
| latest | - | ABSENT | OK |

## 7. Runtime preserve (no side-effect)

| Check | etat | verdict |
|---|---|---|
| API DEV | v1.0.52 inchange | OK |
| jobs-worker DEV | v1.0.52 inchange | OK |
| pods DEV restarts | 0 (age 06:43, anterieurs a la phase) | OK (aucun restart provoque) |
| PROD backend | v1.0.47 intact | OK |
| manifests infra referencant v1.0.53 | 0 | OK |
| infra git dirty | 0 | OK |
| deploy / kubectl apply / set / patch / edit | 0 | OK |
| DB mutation / email / trigger | 0 | OK |

## 8. Interdits respectes

| Interdit | etat |
|---|---|
| docker build | 0 |
| docker push autre tag / latest | 0 |
| kubectl apply / set image / set env / patch / edit | 0 |
| deploy | 0 |
| manifest GitOps modifie | 0 |
| trigger validation / email reel | 0 |
| DB mutation / retry outbound | 0 |
| PROD | non touche |
| git reset --hard / git clean | 0 |
| acces /opt/keybuzz/credentials ou /opt/keybuzz/secrets | 0 |
| secret affiche | 0 |

## 9. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee cette phase) | aucun |
| Tag GHCR v1.0.53 | immuable ; non reference par aucun manifest -> inerte tant que non applique | aucun |
| Docs | revert commit rapport infra si erreur | aucun |

## 10. Prochaine phase

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14X : bump manifests DEV keybuzz-backend + jobs-worker de v1.0.52 vers v1.0.53 -> git diff -> commit -> push -> kubectl apply -f -> rollout status -> verifier manifest = runtime = last-applied = digest sha256:5b893934. Puis re-trigger PH-20.14S-bis SOUS observabilite (les logs claim/done/heartbeat/OUTBOUND start+result identifieront enfin le consommateur reel + la decision d envoi du job). Phase config separee : upgrader amazon-orders/items-worker hors v1.0.40 + fixer leur JOB_TYPES. Ne pas promouvoir PROD, ne pas retry outbound, ne pas flip DB.

Phrase cible : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14W

STOP.
