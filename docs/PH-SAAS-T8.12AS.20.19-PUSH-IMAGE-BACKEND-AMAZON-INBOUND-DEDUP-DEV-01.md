# PH-SAAS-T8.12AS.20.19-PUSH-IMAGE-BACKEND-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.19 (PUSH IMAGE BACKEND AMAZON INBOUND DEDUP DEV)
> Environnement : DEV preparation, PUSH IMAGE ONLY (aucun deploy / kubectl / DB / trigger)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP DEV DONE PH-SAAS-T8.12AS.20.19

Image backend DEV v1.0.55-amazon-inbound-dedup-dev (construite en PH-20.18 from-git 78c450c) poussee sur GHCR. Pull-back DIGEST_MATCH : config digest remote == Image ID local sha256:8e2b4d0399be. OCI labels remote conformes. latest non touche. Aucun deploy, aucun kubectl, aucune DB/migration/trigger/fake event. Runtime DEV + PROD inchanges (v1.0.54). P0 KEY-323 non touche.

## 2. Image poussee

| Item | Local | Remote | Verdict |
|---|---|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.55-amazon-inbound-dedup-dev | meme | OK |
| Image ID (config blob) | sha256:8e2b4d0399be748a2436160412fa270a03ea36248a13c34f2adbf04efe1e9e8e | manifest config digest sha256:8e2b4d0399be...e9e8e | DIGEST_MATCH |
| manifest digest (RepoDigest) | - | sha256:b314826112725790130c5849b26bbd4e7c1b82b40a6e29d55bb835245a9a9702 | OK |
| OCI revision | 78c450c3e23746b42b121e08dc63942922797777 | 78c450c3e23746b42b121e08dc63942922797777 | OK |
| OCI version | v1.0.55-amazon-inbound-dedup-dev | v1.0.55-amazon-inbound-dedup-dev | OK |
| pull-back fresh (docker rmi + pull) | - | Image ID = 8e2b4d0399be (identique) | OK |

## 3. Verification image locale avant push (E1)

| Item | Attendu | Resultat | verdict |
|---|---|---|---|
| Image ID | sha256:8e2b4d0399be... | sha256:8e2b4d0399be... | OK |
| OCI revision | 78c450c3...7777 | 78c450c3...7777 | OK |
| OCI version | v1.0.55-amazon-inbound-dedup-dev | identique | OK |
| extractStableAmazonMessageKey (dist) | present | 2 | OK |
| SQL metadata->'amazonIds'->>'messageId' | present | present | OK |
| fallback SES "based on messageId" | present | 1 | OK |
| OUTBOUND_EMAIL_SEND | present | 5 | OK |
| OUTBOUND not implemented | 0 | 0 | OK |

## 4. Collision GHCR (E2)

docker manifest inspect du tag v1.0.55 AVANT push = ABSENT (pas de collision). Push autorise.

## 5. Push (E3) + pull-back (E4)

docker push (un seul, tag unique) : manifest digest sha256:b314826..., 1 layer nouveau (dist patche) + layers partages avec v1.0.54 (already exists), aucune mention latest. Pull-back : config digest remote == Image ID local (DIGEST_MATCH), labels OCI remote revision/version conformes. latest NON pousse (commande push ciblait uniquement le tag v1.0.55).

## 6. No side-effect (E5)

| Garantie | etat |
|---|---|
| runtime backend DEV | v1.0.54-amazon-validation-pipeline-dev (inchange) |
| runtime jobs-worker DEV | v1.0.54-amazon-validation-pipeline-dev (inchange) |
| runtime backend PROD | v1.0.54-amazon-validation-pipeline-prod (inchange) |
| runtime jobs-worker PROD | v1.0.54-amazon-validation-pipeline-prod (inchange) |
| manifests referencant v1.0.55 | aucun |
| pods backend DEV restarts | 0 |
| deploy / kubectl / DB / migration / email / trigger / replay / fake event | 0 |
| latest | non touche |

## 7. AI feature parity / anti-regression

Push image uniquement, aucun runtime modifie. IA / escalades / assignment / statuts / historique / outbound reply / guard validation non touches. Pipeline restaure KEY-323 non regresse. Le doublon cross-tenant (ecomlg-001/4xfub8 + ecomlg-motxke32/as0yom) reste une decision produit / data cleanup separee (hors scope, le patch v1.0.55 ne corrige que la dedup intra-tenant par message Amazon stable).

## 8. Next GO

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.20 : bump k8s/keybuzz-backend-dev/deployment.yaml (API) + deployment-jobs-worker.yaml v1.0.54 -> v1.0.55 (commit+push manifest AVANT apply -> kubectl apply -f -> rollout -> verifier manifest=last-applied=runtime=digest b314826/config 8e2b4d0399be) + no unintended processing, puis verif runtime dedup sur vrai message ou replay controle (sans fake event).

## 9. Phrase cible

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP DEV DONE PH-SAAS-T8.12AS.20.19

STOP.
