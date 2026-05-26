# PH-SAAS-T8.12AS.20.14Y-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14X2 (build) / PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14Y (PUSH IMAGE ONLY, DEV)
> Environnement : DEV (aucun deploy, aucun runtime change, aucune mutation DB)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14Y

Image v1.0.54-amazon-validation-pipeline-dev poussee sur GHCR depuis l'image locale construite en PH-20.14X2 (source d27f4a5, patch PH-20.14W). Manifest digest sha256:f1a6e19d5433..., config digest remote == Image ID locale 3c826354f164, OCI revision/version verifies, pull-back OK, latest non pousse. Aucun deploy, aucun manifest GitOps, runtime DEV+PROD inchanges v1.0.53. Tag unique pousse. STOP au gate apply.

## 2. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD=origin=d27f4a5 | d27f4a5 | .bak cruft only | OK |
| keybuzz-infra | clean | clean | clean | OK |
| API/jobs-worker DEV | v1.0.53-amazon-validation-pipeline-dev | v1.0.53 | ready | OK (read-only) |
| API/jobs-worker PROD | v1.0.53-amazon-validation-pipeline-prod | v1.0.53-prod | ready | OK (read-only) |
| Bastion | install-v3 / 46.62.171.61 | install-v3 | - | OK |

## 3. Image locale (avant push)

| Attribut | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.54-amazon-validation-pipeline-dev |
| Image ID | sha256:3c826354f164f18d9937de1087910de6086ac97b43c301f2be549fa2174a828f |
| OCI revision | d27f4a51e6052121b03afcc2c302b76bf006ed1b |
| OCI version | v1.0.54-amazon-validation-pipeline-dev |
| markers dist | verifies en PH-20.14X2 sur cet Image ID identique (real-inbound validates, emailAddress insensitive, self-test preserve, @map(to), jobsWorker observability, updateMany bloquant casse=0, OUTBOUND_EMAIL_SEND not implemented=0) |

## 4. GHCR avant/apres

| Etape | etat GHCR v1.0.54-dev |
|---|---|
| avant push (E2 collision) | ABSENT |
| apres push (E3) | PRESENT, manifest digest sha256:f1a6e19d5433cde7e5ac416fcd6ddc2cd6c8bf017311e31075ed4f604cc20cc9 |
| latest | ABSENT (non pousse, hors scope) |

## 5. Digest match (pull-back)

| Item | local | remote | verdict |
|---|---|---|---|
| Image ID / config digest | sha256:3c826354f164 | manifest config.digest = sha256:3c826354f164 | MATCH |
| manifest digest (RepoDigest) | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:f1a6e19d5433 | OK |
| pull-back Image ID (rmi + pull fresh) | - | sha256:3c826354f164 (identique) | MATCH |
| OCI revision | d27f4a5 | d27f4a51e605... | MATCH |
| OCI version | v1.0.54-amazon-validation-pipeline-dev | idem | MATCH |
| latest | - | ABSENT | OK |

## 6. Runtime preserve

| Signal | etat |
|---|---|
| DEV API/jobs-worker | inchange v1.0.53-amazon-validation-pipeline-dev |
| PROD API/jobs-worker | inchange v1.0.53-amazon-validation-pipeline-prod |
| restarts API DEV/PROD | 0 / 0 (aucun restart inattendu) |
| deploy referencant v1.0.54 | aucun |
| manifest GitOps modifie | aucun (infra clean, aucun v1.0.54 dans k8s) |

## 7. Interdits respectes

| Interdit | respecte |
|---|---|
| docker build | oui (aucun build) |
| docker push autre tag / latest | oui (seul v1.0.54-dev pousse) |
| kubectl apply/set/patch/edit | oui (read-only get uniquement) |
| deploy / manifest GitOps | oui (aucun) |
| trigger / email / DB mutation / retry outbound | oui (aucun) |
| PROD runtime mutation | oui (PROD intact) |

## 8. Prochaine phase

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14Z

Apply DEV GitOps : bump deployment.yaml + deployment-jobs-worker.yaml DEV de v1.0.53 vers v1.0.54-amazon-validation-pipeline-dev (manifest commit + push + kubectl apply -f + rollout + verifier manifest=last-applied=runtime=digest f1a6e19d/config 3c826354), no unintended processing. Puis re-trigger DEV pour prouver PENDING -> VALIDATED via le chemin real-inbound (self-test ou vrai message Amazon). Promotion PROD (image -prod build/push/apply) sur GO ulterieur.

Phrase cible : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14Y

STOP.
