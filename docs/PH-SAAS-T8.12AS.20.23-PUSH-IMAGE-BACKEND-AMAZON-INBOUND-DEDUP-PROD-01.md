# PH-SAAS-T8.12AS.20.23-PUSH-IMAGE-BACKEND-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.23 (PUSH IMAGE ONLY)
> Environnement : PROD preparation (PUSH GHCR uniquement ; aucun deploy/kubectl/DB/trigger)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP PROD DONE PH-SAAS-T8.12AS.20.23

Image PROD v1.0.55-amazon-inbound-dedup-prod (PH-20.22, Image ID 7e2f123673ed) poussee sur GHCR. Manifest digest sha256:b21e524a9d98...52e2. Config digest remote == Image ID local 7e2f123673ed (DIGEST_MATCH apres pull-back fresh). OCI labels remote conformes (revision 78c450c, version v1.0.55-amazon-inbound-dedup-prod, created 2026-05-27T08:41:51Z). latest NON pousse / NON touche (absent remote avant et apres). Aucun build/deploy/kubectl/DB/trigger. Runtime DEV v1.0.55-dev + PROD v1.0.54-prod inchanges, PROD restarts=0. Limites connues conservees (race sans contrainte unique DB + cross-tenant + reply-to obsoletes = phases separees). P0 KEY-323 non touche.

## 2. Preflight (E0)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78c450c | 78c450c | - | OK |
| keybuzz-infra | main | 72eed25 | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 09:03Z. Runtime informatif : DEV v1.0.55-amazon-inbound-dedup-dev, PROD v1.0.54-amazon-validation-pipeline-prod.

## 3. Image locale (E1)

| Item | Attendu | Resultat | verdict |
|---|---|---|---|
| Image ID | sha256:7e2f123673ed... | sha256:7e2f123673edd54a91fe2465002463f448bf83d5ab59a687504a13e87006c4b2 | OK |
| OCI revision | 78c450c... | 78c450c3e23746b42b121e08dc63942922797777 | OK |
| OCI version | v1.0.55-amazon-inbound-dedup-prod | v1.0.55-amazon-inbound-dedup-prod | OK |
| OCI created | 2026-05-27T08:41:51Z | 2026-05-27T08:41:51Z | OK |

Markers dist deja prouves en PH-20.22 (E6) sur cette meme Image ID : extractStableAmazonMessageKey, idempotence amazonIds.messageId, fallback SES, @map to, OUTBOUND_EMAIL_SEND, heartbeat, not-implemented OUTBOUND=0. Image inchangee depuis PH-20.22 (meme Image ID) -> markers inchanges.

## 4. Collision GHCR (E2)

docker manifest inspect du tag v1.0.55-amazon-inbound-dedup-prod = ABSENT avant push (ok). latest = absent remote avant push (documente, non modifie).

## 5. Docker push (E3)

docker push ghcr.io/keybuzzio/keybuzz-backend:v1.0.55-amazon-inbound-dedup-prod : 6 layers "already exists" (partages avec DEV v1.0.55, code identique), 1 layer "Pushed" (e590e6a3fea5). Resultat : digest sha256:b21e524a9d9843cf841b9765fcfe771e10816e0bf326aa35b1969d3a93bc52e2 size 2626. Aucune mention latest dans la sortie. Push unique du tag immuable.

## 6. Pull-back + digest match (E4)

| Item | Local | Remote | Verdict |
|---|---|---|---|
| config digest | sha256:7e2f123673ed...c4b2 (Image ID) | sha256:7e2f123673ed...c4b2 (manifest .config.digest) | DIGEST_MATCH |
| manifest digest | - | sha256:b21e524a9d98...52e2 | OK |
| Image ID apres pull fresh | sha256:7e2f123673ed...c4b2 | (re-pull) sha256:7e2f123673ed...c4b2 | OK |
| RepoDigest | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:b21e524a9d98...52e2 | OK |
| OCI revision remote | 78c450c | 78c450c | match |
| OCI version remote | v1.0.55-amazon-inbound-dedup-prod | idem | match |
| OCI created remote | 2026-05-27T08:41:51Z | idem | match |
| latest | - | ABSENT | non touche |

Pull-back effectue par docker rmi du tag local puis docker pull frais : Image ID re-telecharge identique a 7e2f123673ed -> integrite remote confirmee.

## 7. No runtime side-effect (E5)

| Garantie | etat |
|---|---|
| runtime DEV API + jobs-worker | v1.0.55-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.54-amazon-validation-pipeline-prod (inchange) |
| manifest PROD ref v1.0.55-prod | aucun |
| PROD pod restarts (backend + jobs-worker) | 0 / 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |
| build | 0 |
| latest | non touche (absent) |

## 8. AI feature parity / anti-regression

Aucune modification runtime (push registry uniquement). IA / escalades / assignment / statuts / historique non touches. Outbound reply + guard validation non touches (image non deployee). KEY-323 P0 non rouvert.

## 9. Limites restantes

- RACE : dedup SELECT-puis-skip sans contrainte unique DB -> collapse non garantie sous redeliveries quasi-simultanees (cas PROD 06:29 = 4 POST en 229 ms). Contrainte unique DB produit (tenant_id, amazonIds.messageId / thread_key), phase separee.
- CROSS-TENANT : non corrige par l'idempotence tenant-scopee (decision produit + cleanup data separes).
- Adresses reply-to obsoletes 3jcpvk/cp2hat cote Amazon Seller Central : retrait manuel separe.
- Fallback pre-existant tenant_id || "ecomlg-001" (amazonFees.routes.ts) hors patch dedup, hygiene separee.

## 10. Next GO

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS PH-SAAS-T8.12AS.20.24 : bump deployment.yaml API PROD + deployment-jobs-worker.yaml PROD v1.0.54-prod -> v1.0.55-prod (digest GHCR b21e524a / config 7e2f123673ed), commit+push manifest AVANT apply, kubectl apply -f, rollout, verifier manifest=last-applied=runtime=digest + no unintended processing (Job/OutboundEmail/MOM inchanges, AMAZON_POLL worker-1=0, SMTP DEV/PROD inchange).

## 11. Phrase cible

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP PROD DONE PH-SAAS-T8.12AS.20.23

STOP.
