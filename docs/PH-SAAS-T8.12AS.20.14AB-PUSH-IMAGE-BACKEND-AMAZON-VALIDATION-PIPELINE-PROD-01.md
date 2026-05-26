# PH-SAAS-T8.12AS.20.14AB-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14AA (build PROD) / PH-20.14Z2 (verify DEV) / PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14AB (PUSH IMAGE PROD ONLY)
> Environnement : PROD preparation (aucun deploy, aucun runtime change, aucune mutation DB)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD DONE PH-SAAS-T8.12AS.20.14AB

Image v1.0.54-amazon-validation-pipeline-prod poussee sur GHCR depuis l'image locale construite en PH-20.14AA (source d27f4a5, meme code que DEV prouve en 14Z2). Manifest digest sha256:060abd98..., config digest remote == Image ID locale 831cc88204b4, OCI revision/version verifies, pull-back OK, latest non pousse. Aucun deploy, aucun manifest GitOps, runtime DEV (v1.0.54-dev) + PROD (v1.0.53-prod) inchanges. Tag unique pousse. STOP au gate apply PROD.

## 2. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD=origin=d27f4a5 | d27f4a5 | .bak cruft only | OK |
| keybuzz-infra | clean | clean | clean | OK |
| API/jobs-worker DEV | v1.0.54-amazon-validation-pipeline-dev | v1.0.54 | ready | OK (read-only) |
| API/jobs-worker PROD | v1.0.53-amazon-validation-pipeline-prod | v1.0.53-prod | ready | OK (read-only) |
| Bastion | install-v3 / 46.62.171.61 | install-v3 | - | OK |

## 3. Image locale (avant push)

| Attribut | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.54-amazon-validation-pipeline-prod |
| Image ID | sha256:831cc88204b4a80d4389a6386472b1eb7d2d1322e78de369a736bfeed181a897 |
| OCI revision | d27f4a51e6052121b03afcc2c302b76bf006ed1b |
| OCI version | v1.0.54-amazon-validation-pipeline-prod |
| markers dist (spot) | marked VALIDATED real=1, emailAddress insensitive=4, inboundAddress.updateMany svc=0 (bloquant casse absent), OUTBOUND_EMAIL_SEND not implemented=0 ; complet verifie en PH-20.14AA |

## 4. GHCR avant/apres

| Etape | etat GHCR v1.0.54-prod |
|---|---|
| avant push (E2 collision) | ABSENT |
| apres push (E3) | PRESENT, manifest digest sha256:060abd98c96db9f9a913761eddfa67476650840554c967954e5cd55dec15bda3 |
| latest | ABSENT (non pousse, hors scope) |

## 5. Digest match (pull-back)

| Item | local | remote | verdict |
|---|---|---|---|
| Image ID / config digest | sha256:831cc88204b4 | manifest config.digest = sha256:831cc88204b4 | MATCH |
| manifest digest (RepoDigest) | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:060abd98c96d | OK |
| pull-back Image ID (rmi + pull) | - | sha256:831cc88204b4 (identique) | MATCH |
| OCI revision | d27f4a5 | d27f4a51e605... | MATCH |
| OCI version | v1.0.54-amazon-validation-pipeline-prod | idem | MATCH |
| latest | - | ABSENT | OK |

## 6. Runtime preserve

| Signal | etat |
|---|---|
| DEV API/jobs-worker | inchange v1.0.54-amazon-validation-pipeline-dev |
| PROD API/jobs-worker | inchange v1.0.53-amazon-validation-pipeline-prod |
| restarts API DEV/PROD | 0 / 0 (aucun restart inattendu) |
| deploy referencant v1.0.54-prod | aucun |
| manifest GitOps modifie | aucun (infra clean, aucun v1.0.54-prod dans k8s) |

## 7. Interdits respectes

| Interdit | respecte |
|---|---|
| docker build | oui (aucun build) |
| docker push autre tag / latest | oui (seul v1.0.54-prod pousse) |
| kubectl apply/set/patch/edit | oui (read-only get uniquement) |
| deploy / manifest GitOps | oui (aucun) |
| trigger / email / DB mutation / retry outbound | oui (aucun) |
| PROD runtime mutation | oui (PROD intact v1.0.53-prod) |

## 8. Prochaine phase

GO APPLY AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14AC

Apply PROD GitOps : bump deployment.yaml API PROD + deployment-jobs-worker.yaml PROD de v1.0.53-prod vers v1.0.54-amazon-validation-pipeline-prod (commit + push manifest -> kubectl apply -f -> rollout -> verifier manifest=last-applied=runtime=digest 060abd98/config 831cc882 + no unintended processing). Apres promotion, un vrai message Amazon (ou self-test) validera l adresse PROD ecomlg-001 FR (cmmsdn4if / 4xfub8) via le chemin real-inbound, debloquant le guard outbound (objectif P0 KEY-323).

Phrase cible : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD DONE PH-SAAS-T8.12AS.20.14AB

STOP.
