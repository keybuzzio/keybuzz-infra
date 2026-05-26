# PH-SAAS-T8.12AS.20.14U-PROD-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14U-PROD-BUILD / PH-20.14T / PH-20.14S-BIS
> Phase : PH-SAAS-T8.12AS.20.14U-PROD-PUSH (PUSH IMAGE PROD ONLY vers GHCR)
> Environnement : PROD preparation (push registry uniquement ; aucun build, aucun deploy, aucun kubectl)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD DONE PH-SAAS-T8.12AS.20.14U-PROD-PUSH

Image backend PROD dediee v1.0.53-amazon-validation-pipeline-prod (construite en PH-20.14U-PROD-BUILD from-git depuis commit 1179c15, option A) poussee sur GHCR. Digest manifest sha256:18f545750b991c8900be3ee8dab5874971e4c6cd468d3b1458bb80e6dfaa5730. Config digest remote (Image ID apres pull-back) == Image ID locale sha256:8932a4558998. Labels OCI remote revision=1179c15 / version=v1.0.53-amazon-validation-pipeline-prod == local. latest non pousse. Aucun autre tag pousse. Aucun build, aucun deploy, aucun kubectl, aucun manifest GitOps, aucune mutation DB, aucun email, aucun trigger. Runtime PROD reste v1.0.47 (restarts=0), jobs-worker PROD absent, DEV reste v1.0.53.

Prochaine phrase GO : GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD-APPLY (bump API PROD v1.0.47 -> v1.0.53-prod + creer jobs-worker PROD via GitOps strict -> verifier digest + no unintended processing -> STOP avant trigger).

## 2. Sources relues

PH-20.14U-PROD-BUILD (image PROD locale), PH-20.14T (decision PROD READY), PH-20.14S-BIS (DEV READY). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD 1179c15 | origin/main 1179c15 | clean (hors .bak untracked) | OK |
| keybuzz-infra | HEAD c7eda33 | origin/main c7eda33 | dirty=0 | OK |
| PROD API (runtime) | v1.0.47-cross-env-guard-fix-prod | inchange | restarts=0 | OK (non touche) |
| jobs-worker PROD | ABSENT | absent | - | OK |
| DEV API (runtime) | v1.0.53-amazon-validation-pipeline-dev | inchange | ready | OK (non touche) |
| image locale PROD v1.0.53 | presente (8932a455) | rev 1179c15 / ver -prod | ready | OK |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

## 4. Image locale (avant push)

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.53-amazon-validation-pipeline-prod | OK |
| Image ID | sha256:8932a4558998203fa355e2c10f1c94a6a4defaa2dc137dfca8b5b661d1044407 | OK |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | OK (== 1179c15) |
| OCI version | v1.0.53-amazon-validation-pipeline-prod | OK |

Markers dist verifies (read-only) : observabilite jobsWorker (heartbeat/claim/done/fail/OUTBOUND start+result/claim DISABLED) PRESENT, parseJobTypesEnv raw==null PRESENT, JOB_TYPES (2 fichiers), emailAddress insensitive (to.trim) + isValidationEmail(subject) PRESENT, @map("to") (client genere) PRESENT, OUTBOUND_EMAIL_SEND not implemented = 0. Code identique au DEV v1.0.53 valide.

## 5. GHCR avant / apres

| Etat | v1.0.53-prod sur GHCR | latest | autre tag pousse |
|---|---|---|---|
| avant push | ABSENT | ABSENT | - |
| apres push | PRESENT (digest sha256:18f54575...) | ABSENT | aucun |

E2 collision : tag v1.0.53-prod ABSENT avant push -> pas de STOP. E3 : un seul docker push de v1.0.53-amazon-validation-pipeline-prod (10 layers already exist, 1 layer pushed : a42309a7a5b4).

## 6. Digest match (pull-back depuis GHCR)

Procedure : suppression image locale -> docker pull depuis GHCR (preuve registry) -> inspect.

| Item | local | remote (pull-back) | verdict |
|---|---|---|---|
| Image ID (config digest) | sha256:8932a4558998... | sha256:8932a4558998... | MATCH |
| RepoDigest (manifest) | - | sha256:18f545750b991c8900be3ee8dab5874971e4c6cd468d3b1458bb80e6dfaa5730 | DOCUMENTE |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | 1179c1547de3c06db9c0accd2fd2179a87da7151 | MATCH |
| OCI version | v1.0.53-amazon-validation-pipeline-prod | v1.0.53-amazon-validation-pipeline-prod | MATCH |
| latest | - | ABSENT | OK |

## 7. Runtime preserve (no side-effect)

| Check | etat | verdict |
|---|---|---|
| PROD API | v1.0.47 inchange (restarts=0) | OK |
| jobs-worker PROD | absent inchange | OK |
| DEV API | v1.0.53 inchange | OK |
| manifests infra referencant v1.0.53-prod | 0 | OK |
| infra git dirty | 0 | OK |
| deploy / kubectl apply / set / patch / edit | 0 | OK |
| DB mutation / email / trigger | 0 | OK |

## 8. Interdits respectes

| Interdit | etat |
|---|---|
| docker build | 0 |
| docker push autre tag / latest | 0 |
| kubectl apply / set / patch / edit | 0 |
| deploy / manifest GitOps modifie | 0 |
| trigger validation / email reel / retry outbound | 0 |
| DB mutation | 0 |
| PROD runtime mutation | 0 (push registry uniquement) |
| git reset --hard / git clean | 0 |
| acces credentials / secrets | 0 |
| secret affiche | 0 |

## 9. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee cette phase) | aucun |
| Tag GHCR v1.0.53-prod | immuable ; non reference par aucun manifest -> inerte tant que non applique | aucun |
| Docs | revert commit rapport infra si erreur | aucun |

## 10. Prochaine phase

GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD-APPLY : bump deployment.yaml API PROD v1.0.47 -> v1.0.53-amazon-validation-pipeline-prod + creer deployment-jobs-worker.yaml PROD (command node dist/workers/jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP inline mail-core-01 49.13.35.167:25 secure=false, envFrom keybuzz-backend-db + keybuzz-backend-secrets + vault-token(optional) + amazon-spapi-creds, imagePullSecrets ghcr-cred, namespace keybuzz-backend-prod) -> dry-run -> commit/push infra -> kubectl apply -f -> rollout status -> verifier manifest=runtime=last-applied=digest 18f54575 + no unintended processing (Job/OutboundEmail PROD restent vides) -> STOP avant trigger. Re-trigger PROD ulterieur = send-validation AUTHENTIFIE reel (KEYBUZZ_DEV_MODE=false PROD), 1 adresse a la fois, apres verif routage webhook mail-core PROD. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40. Ne pas promouvoir PROD sans GO explicite.

Phrase cible : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD DONE PH-SAAS-T8.12AS.20.14U-PROD-PUSH

STOP.
