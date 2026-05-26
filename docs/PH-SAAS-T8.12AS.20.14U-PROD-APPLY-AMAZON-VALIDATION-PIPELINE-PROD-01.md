# PH-SAAS-T8.12AS.20.14U-PROD-APPLY-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14U-PROD-PUSH / PH-20.14T / PH-20.14S-BIS / PH-20.14X
> Phase : PH-SAAS-T8.12AS.20.14U-PROD-APPLY (APPLY GITOPS PROD : API bump + jobs-worker creation)
> Environnement : PROD (premiere mutation runtime PROD de la chaine)

## 1. Verdict

GO APPLY AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14U-PROD-APPLY

Pipeline de validation Amazon applique en PROD via GitOps strict. API keybuzz-backend PROD bumpee v1.0.47-cross-env-guard-fix-prod -> v1.0.53-amazon-validation-pipeline-prod ; nouveau deployment jobs-worker PROD cree (image v1.0.53-prod, command node dist/workers/jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP inline mail-core-01 49.13.35.167:25 secure=false). manifest = last-applied = runtime = imageID digest GHCR sha256:18f54575 verifie pour les deux. jobs-worker startup observabilite active (Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw="OUTBOUND_EMAIL_SEND" pollMs=2000). No unintended processing : Job OUTBOUND_EMAIL_SEND PROD reste vide, OutboundEmail PROD reste vide, MarketplaceOutboundMessage PROD reste vide, 11 adresses Amazon toujours PENDING, 0 claim/done/OUTBOUND start, aucun SMTP/email/trigger. API boot sain (/health 200, listening 4000, 0 erreur Prisma). amazon-orders/items-worker inchanges (v1.0.40), backfill-scheduler non touche. Commit infra f220ec7 pousse AVANT apply.

Prochaine phrase GO : GO RETRIGGER AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14V-PROD (re-trigger PROD authentifie reel, une adresse a la fois, apres verif routage webhook mail-core PROD).

## 2. Sources relues

PH-20.14U-PROD-PUSH (image PROD GHCR), PH-20.14T (decision PROD READY), PH-20.14S-BIS (DEV READY), PH-20.14X (apply DEV). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/service | branche/runtime | HEAD/digest | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | f220ec7 (apres commit) | dirty=0 | OK |
| keybuzz-backend | main | HEAD=origin 1179c15 | clean (hors .bak untracked) | OK |
| GHCR v1.0.53-prod | - | manifest sha256:18f54575...886368 | present | OK (== attendu) |
| API PROD (avant) | v1.0.47-cross-env-guard-fix-prod | - | ready restarts=0 | OK |
| jobs-worker PROD (avant) | ABSENT | - | - | OK (a creer) |
| DEV v1.0.53 | - | - | ready | OK (read-only) |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

## 4. Snapshot BEFORE (E1)

| Signal | before | verdict |
|---|---|---|
| API PROD image / last-applied | v1.0.47 / v1.0.47 | OK |
| API PROD restarts / ready | 0 / true | OK |
| Job OUTBOUND_EMAIL_SEND | vide ([]) | OK |
| OutboundEmail | vide ([]) | OK |
| MarketplaceOutboundMessage | vide ([]) | OK |
| inbound Amazon PENDING | 11 | OK |
| jobs-worker PROD | absent | OK |

Aucun job pre-existant -> deployer le jobs-worker ne consomme rien par surprise.

## 5. Manifests modifies

| Fichier | changement | verdict |
|---|---|---|
| k8s/keybuzz-backend-prod/deployment.yaml | L27 image v1.0.47 -> v1.0.53-prod, commentaire PH-20.14U-PROD-APPLY rollback v1.0.47 | OK |
| k8s/keybuzz-backend-prod/deployment-jobs-worker.yaml | NOUVEAU : ns keybuzz-backend-prod, image v1.0.53-prod, command jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP inline 49.13.35.167:25 secure=false, envFrom (db/secrets/vault-token opt/amazon-spapi-creds), imagePullSecrets ghcr-cred, resources 256/512Mi, liveness ps jobsWorker | OK |

git diff = 2 fichiers, +81/-1. Patch API via Python str.replace. envFrom miroir API PROD (sans inbound-webhook-key, non requis cote worker). Aucun changement secrets/SMTP-secret/amazon-workers/backfill/DEV/keybuzz-api.

## 6. Dry-run

| Cible | dry-run client | dry-run server | verdict |
|---|---|---|---|
| deployment.yaml (API) | configured | configured | OK |
| deployment-jobs-worker.yaml | created | created | OK |

Verif : v1.0.53-prod present, 0 ref -dev, 0 :latest, JOB_TYPES + SMTP present, namespace keybuzz-backend-prod, secrets envFrom (db/secrets/vault-token/amazon-spapi-creds) + imagePullSecrets ghcr-cred TOUS presents en PROD.

## 7. Rollout API PROD (E6)

| Item | resultat | verdict |
|---|---|---|
| kubectl apply -f deployment.yaml | configured | OK |
| rollout status | successfully rolled out | OK |
| pod | keybuzz-backend-74df4f6c64-4j6rv | OK |
| image runtime | v1.0.53-prod | OK |
| imageID digest | sha256:18f54575...886368 | MATCH |
| ready / restarts | true / 0 | OK |
| boot | Server listening 4000, /health 200, 0 erreur Prisma | OK |

NB : warning NODE_EXTRA_CA_CERTS vault-ca.pem (cert absent, ignore) pre-existant (deja en v1.0.47), benin, API saine.

## 8. Rollout jobs-worker PROD (E7)

| Item | resultat | verdict |
|---|---|---|
| kubectl apply -f deployment-jobs-worker.yaml | created | OK |
| rollout status | successfully rolled out | OK |
| pod | jobs-worker-5dd949465-wvv8k | OK |
| image runtime | v1.0.53-prod | OK |
| imageID digest | sha256:18f54575...886368 | MATCH |
| ready / restarts | true / 0 | OK |
| startup observabilite | "Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000" | OK |
| claim spontane | 0 | OK |

## 9. Snapshot AFTER no unintended processing (E8)

| Signal | before | after | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | vide | vide | INCHANGE |
| OutboundEmail | vide | vide | INCHANGE |
| MarketplaceOutboundMessage | vide | vide | INCHANGE |
| inbound Amazon PENDING | 11 | 11 | INCHANGE |
| jobs-worker claim/done/OUTBOUND start | - | 0 | OK |
| SMTP send / email / trigger | - | 0 | OK |
| amazon-orders/items-worker | v1.0.40 | v1.0.40 | INCHANGE |
| backfill-scheduler | non touche | non touche | OK |

## 10. Verification digest (E9)

| Service | manifest | last-applied | runtime imageID digest | verdict |
|---|---|---|---|---|
| API keybuzz-backend | v1.0.53-prod | v1.0.53-prod | sha256:18f54575...886368 | MATCH |
| jobs-worker | v1.0.53-prod | v1.0.53-prod | sha256:18f54575...886368 | MATCH |

GHCR manifest digest = sha256:18f545750b991c8900be3ee8dab5874971e4c6cd468d3b1458bb80e6dfaa5730.

## 11. AI feature parity / anti-regression (E10)

| Feature | Etat | Verdict |
|---|---|---|
| Guard outbound validationStatus=VALIDATED | non touche (embarque, non re-exerce) | OK |
| From Amazon contract | non touche | OK |
| SP-API messaging | non active | OK |
| retry outbound / fake webhook / fake email / fake job | 0 | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | actif (jamais AMAZON_POLL) | OK |
| amazon pollers v1.0.40 | non modifies | OK |
| backfill-scheduler | hors scope | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserves | OK |
| PH-20.13B Client push | reste suspendu | OK |

## 12. No fake metrics / no fake events (E11)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation / migration / validationStatus flip | 0 | OK |

Aucune ecriture runtime hors la bascule d image + creation du deployment worker. Snapshots DB read-only via prisma groupBy/count.

## 13. Rollback (phase dediee si necessaire)

| Element | Rollback | Runtime impact |
|---|---|---|
| API PROD | re-apply deployment.yaml image v1.0.47-cross-env-guard-fix-prod via GitOps (git revert f220ec7 + apply), jamais kubectl set image | retour v1.0.47 |
| jobs-worker PROD (nouveau) | supprimer/scaler a 0 via GitOps manifest (git revert) + apply, pas kubectl scale direct | suppression worker, aucun autre service impacte |
| Image v1.0.53-prod GHCR | immuable, conservee | aucun |

## 14. Prochaine phase

GO RETRIGGER AMAZON INBOUND VALIDATION PROD PH-SAAS-T8.12AS.20.14V-PROD : re-trigger PROD CIBLE, UNE adresse a la fois, via send-validation AUTHENTIFIE reel (KEYBUZZ_DEV_MODE=false PROD -> pas de header X-User-Email dev-mode ; utiliser session seller/UI legitime). VERIFICATION BLOQUANTE prealable : confirmer le routage webhook mail-core des @inbound.keybuzz.io PROD vers le backend PROD (/api/v1/webhooks/inbound-email) ; signal positif = API PROD porte inbound-webhook-key. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40. Ne pas retry outbound (0 backlog). Ne pas flip DB.

Phrase cible : GO APPLY AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14U-PROD-APPLY

STOP.
