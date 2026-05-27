# PH-SAAS-T8.12AS.20.32-PUSH-IMAGE-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.32 (PUSH IMAGE ONLY)
> Environnement : PROD preparation (PUSH GHCR uniquement ; aucun deploy/kubectl/DB/trigger)

## 1. Verdict

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP PROD DONE PH-SAAS-T8.12AS.20.32

Image PROD v1.0.56-amazon-inbound-dedup-prod (PH-20.31, Image ID 179af6fb0632) poussee sur GHCR. Manifest digest sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2. Config digest remote == Image ID local 179af6fb0632 (DIGEST_MATCH apres pull-back fresh). OCI labels remote conformes (revision 78bfb94, version v1.0.56-amazon-inbound-dedup-prod). latest NON pousse / NON touche (absent remote). Aucun build/deploy/kubectl/DB/trigger. Runtime DEV v1.0.56-dev + PROD v1.0.55-prod inchanges, PROD restarts=0, aucun manifest ne reference v1.0.56-prod.

## 2. Preflight (E0)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78bfb94 | 78bfb94 | (.bak cruft) | OK |
| keybuzz-infra | main | 6bd2597 | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 13:34Z. Runtime informatif : DEV v1.0.56-amazon-inbound-dedup-dev, PROD v1.0.55-amazon-inbound-dedup-prod.

## 3. Image locale (E1)

| Item | Attendu | Resultat | verdict |
|---|---|---|---|
| Image ID | sha256:179af6fb0632... | sha256:179af6fb0632dab8d91ebd362e3a1c20b39908d66448dc9fdd86bbeaa8495c2a | OK |
| OCI revision | 78bfb9424675... | 78bfb9424675dd01105792ec74635730d597c849 | OK |
| OCI version | v1.0.56-amazon-inbound-dedup-prod | idem | OK |
| OCI created | 2026-05-27T13:28:15Z | idem | OK |
| markers dist | computeInboundDedupLockScope=2, pg_advisory_xact_lock=1, "Dedup lock acquired"=1, "Idempotent skip"=1, OUTBOUND_EMAIL_SEND=5 | idem | OK |

Markers complets (amzmsg/thread/stableAmazonMessageKey/@map to/not-impl OUTBOUND=0/hardcode=0) deja prouves en PH-20.31 (E6) sur cette meme Image ID. Image inchangee -> markers inchanges.

## 4. Collision GHCR (E2)

docker manifest inspect du tag v1.0.56-amazon-inbound-dedup-prod = ABSENT avant push (ok). latest = absent remote avant push (documente, non modifie).

## 5. Docker push (E3)

docker push ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod : layers partages "already exists", 1 layer "Pushed" (ffe975c0432a). Resultat : digest sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2 size 2626. Aucune mention latest. Push unique du tag immuable.

## 6. Pull-back + digest match (E4)

| Item | Local | Remote | Verdict |
|---|---|---|---|
| config digest | sha256:179af6fb0632...8495c2a (Image ID) | sha256:179af6fb0632...8495c2a (manifest .config.digest) | DIGEST_MATCH |
| manifest digest | - | sha256:9689875ca556...1dcdd2 | OK |
| Image ID apres pull fresh | sha256:179af6fb0632...8495c2a | re-pull 179af6fb0632...8495c2a | OK |
| RepoDigest | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:9689875ca556...1dcdd2 | OK |
| OCI revision remote | 78bfb94 | 78bfb94 | match |
| OCI version remote | v1.0.56-amazon-inbound-dedup-prod | idem | match |
| latest | - | ABSENT | non touche |

Pull-back par docker rmi du tag local puis docker pull frais : Image ID re-telecharge identique a 179af6fb0632 -> integrite remote confirmee.

## 7. No runtime side-effect (E5)

| Garantie | etat |
|---|---|
| runtime DEV API + jobs-worker | v1.0.56-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.55-amazon-inbound-dedup-prod (inchange) |
| manifest ref v1.0.56-prod | aucun |
| pod restarts (PROD) | 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |
| build | 0 |
| latest | non touche (absent) |

## 8. AI feature parity / anti-regression

Aucune modification runtime (push registry uniquement). IA / escalades / assignment / statuts / historique non touches. Outbound reply + guard validation non touches (image non deployee). KEY-323 P0 non rouvert.

## 9. Limites restantes

- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des doublons existants : phase separee.
- v1.0.55-prod actuel non garanti race-safe (a remplacer par v1.0.56-prod a l'apply).

## 10. Next GO

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS PH-SAAS-T8.12AS.20.33 : bump deployment.yaml API PROD + deployment-jobs-worker.yaml PROD v1.0.55-prod -> v1.0.56-prod (digest GHCR 9689875c / config 179af6fb), commit+push manifest AVANT apply, kubectl apply -f, rollout, verifier manifest=last-applied=runtime=digest + no unintended processing (Job/OutboundEmail/MOM inchanges, AMAZON_POLL worker-1=0, SMTP PROD inchange).

## 11. Phrase cible

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP PROD DONE PH-SAAS-T8.12AS.20.32

STOP.
