# PH-SAAS-T8.12AS.20.14Q-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14P / PH-20.14O / PH-20.14M
> Phase : PH-SAAS-T8.12AS.20.14Q (PUSH IMAGE ONLY vers GHCR)
> Environnement : DEV (push registry uniquement ; aucun deploy, aucun GitOps apply, aucun runtime change)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14Q

Image backend DEV v1.0.52-amazon-validation-pipeline-dev (construite en PH-20.14P from-git depuis 8f7122b) poussee sur GHCR. Manifest digest sha256:4e60d0e865420fd76b6433e4eeb31d36d1c68324f31ac66347a5647872f92676. Config digest remote sha256:645f326612d8e5b33717c03a7e772044f1a4af7fb961ccc9b0c8f412c56f65ee == Image ID locale. Pull-back DIGEST_MATCH_OK. OCI revision 8f7122b et version v1.0.52 confirmees remote. Aucun build, aucun deploy, aucun GitOps, aucun kubectl, aucune DB mutation, aucun trigger, aucun email. Runtime DEV (API + jobs-worker) reste v1.0.51, PROD intact (v1.0.47-cross-env-guard-fix-prod).

Prochaine phrase GO : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14R (deploy API + jobs-worker DEV sur v1.0.52). Non executee dans cette phase.

## 2. Sources relues

PH-20.14P (build v1.0.52), PH-20.14O (source patch casse marketplace), PH-20.14M (root cause), PH-20.14L (deploy v1.0.51). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight (repo / branche / HEAD / dirty)

| Repo | branche | HEAD local | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 8f7122b | 8f7122b | non (hors amazon.routes.ts.bak tracke) | OK |
| keybuzz-infra | main | 6366fce | 6366fce | non | OK |
| Bastion install-v3 / 46.62.171.61 | - | - | - | - | OK |

## 4. Image locale (E1)

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.52-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:645f326612d8e5b33717c03a7e772044f1a4af7fb961ccc9b0c8f412c56f65ee | OK |
| Size | 613904720 octets | OK |
| OCI revision | 8f7122bfec4e2ade80b0b98c8a82d3b658f12efb | OK (== 8f7122b) |
| OCI version | v1.0.52-amazon-validation-pipeline-dev | OK |
| OCI created | 2026-05-26T05:30:52Z | OK |

Contenu image re-verifie (dist extrait read-only) : decideValidationAddress present ; query emailAddress equals: to.trim() + mode insensitive present ; garde isValidationEmail(subject) present ; updateMarketplaceStatusIfAmazon present ; ancien pre-filtre marketplace.toUpperCase() dans inbound.service.js = 0 ; sendOutboundEmailById present ; OUTBOUND_EMAIL_SEND present ; JOB_TYPES present ; not implemented OUTBOUND = 0 ; @map("to") ligne 538 du client Prisma genere.

## 5. Collision GHCR avant push (E2) et GHCR avant/apres

| Registry | tag | etat avant | etat apres | verdict |
|---|---|---|---|---|
| GHCR | v1.0.52-amazon-validation-pipeline-dev | ABSENT | PRESENT | OK (aucun overwrite) |

## 6. Push + digest match (E3 + E4)

| Item | local | remote | verdict |
|---|---|---|---|
| Manifest digest | (push) sha256:4e60d0e865420fd76b6433e4eeb31d36d1c68324f31ac66347a5647872f92676 | pull Digest sha256:4e60d0e8...f92676 | MATCH |
| Config digest | Image ID sha256:645f326612d8...65ee | manifest.config.digest sha256:645f326612d8...65ee | MATCH |
| RepoDigest (apres pull) | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:4e60d0e8...f92676 | OK |
| OCI revision | 8f7122b | 8f7122b | MATCH |
| OCI version | v1.0.52-amazon-validation-pipeline-dev | v1.0.52-amazon-validation-pipeline-dev | MATCH |

docker push unique du tag v1.0.52 ; aucun retag, aucun latest, aucun autre tag.

## 7. Runtime preserve (E5)

| Service | namespace | image runtime | attendu | verdict |
|---|---|---|---|---|
| keybuzz-backend (API) | keybuzz-backend-dev | v1.0.51-amazon-validation-pipeline-dev | v1.0.51 | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.51-amazon-validation-pipeline-dev | v1.0.51 | OK |
| keybuzz-backend (API) | keybuzz-backend-prod | v1.0.47-cross-env-guard-fix-prod | intact | OK |
| Deploys cluster-wide referencant v1.0.52 | - | 0 | 0 | OK |

Pods DEV inchanges (start 2026-05-25T22:25, restarts=0) : aucun restart du a cette phase. infra git clean (aucun manifest modifie).

## 8. AI feature parity / anti-regression (E6)

| Feature | Contrat | Etat | Verdict |
|---|---|---|---|
| Guard outbound validationStatus=VALIDATED | non bypasse | inchange (push registry seul) | OK |
| From Amazon | amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | inchange | OK |
| jobs-worker scope JOB_TYPES=OUTBOUND_EMAIL_SEND | protege AMAZON_POLL | present dans image v1.0.52 (sera actif a l apply PH-20.14R) | OK |
| AMAZON_POLL consomme par worker-1 | 0 | runtime v1.0.51 inchange | OK |
| retry outbound / webhook fake / email reel | 0 | aucun | OK |
| PH-20.11C / PH-20.12B | preserve | non touche | OK |
| PH-20.13B Client push | suspendu | non repris | OK |

## 9. No fake metrics / no fake events (E7)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / fake event / fake webhook | 0 | OK |
| fake OutboundEmail / fake Job | 0 | OK |
| DB mutation / validationStatus flip | 0 | OK |

Phase strictement registry : aucune ecriture DB, aucun event, aucune metrique.

## 10. Interdits respectes

| Interdit | Respecte | Preuve |
|---|---|---|
| Build / rebuild | OUI | 0 docker build (push d image PH-20.14P existante) |
| Autre tag / latest / retag | OUI | push unique v1.0.52 |
| Deploy / kubectl apply/set/patch/edit / rollout restart | OUI | 0 |
| Manifest GitOps modifie | OUI | infra git clean |
| Migration / prisma migrate / db push | OUI | 0 |
| Trigger validation / POST send-validation / retry outbound | OUI | 0 |
| Email reel | OUI | 0 |
| PROD | OUI | non touche (v1.0.47 intact) |
| Secrets / token / PII affiches | OUI | aucun (runner Linear token non imprime) |
| Deploy v1.0.48/49/50/51 | OUI | runtime reste v1.0.51, aucun re-deploy |

## 11. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Push GHCR v1.0.52 | irreversible cote registry (tag immuable) | aucun tant que PH-20.14R non applique |
| Runtime | N/A (aucune image deployee) | aucun |
| Image invalide apres push | ne jamais deployer ce tag ; builder v1.0.53 dans une phase separee | aucun |
| Docs | revert commit rapport infra si erreur | aucun |

## 12. Prochaines phases

1. GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14R : bump manifests API + jobs-worker DEV vers v1.0.52, commit + push infra, kubectl apply, rollout status, verifier manifest=runtime=digest GHCR 4e60d0e8.
2. Puis re-trigger PH-20.14M-bis (uniquement quand API ET jobs-worker DEV tournent tous les deux sur v1.0.52) pour prouver cmk5caxx7 PENDING -> VALIDATED.
3. Ne pas re-deployer v1.0.48/49/50/51.

Phrase cible : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14Q

STOP.
