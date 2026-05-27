# PH-SAAS-T8.12AS.20.28-PUSH-IMAGE-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.28 (PUSH IMAGE ONLY)
> Environnement : DEV preparation (PUSH GHCR uniquement ; aucun deploy/kubectl/DB/trigger)

## 1. Verdict

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP DEV DONE PH-SAAS-T8.12AS.20.28

Image DEV v1.0.56-amazon-inbound-dedup-dev (PH-20.27, Image ID e3b5d2b30542) poussee sur GHCR. Manifest digest sha256:ed3d6c1a7f32...f81b. Config digest remote == Image ID local e3b5d2b30542 (DIGEST_MATCH apres pull-back fresh). OCI labels remote conformes (revision 78bfb94, version v1.0.56-amazon-inbound-dedup-dev, created 2026-05-27T11:59:44Z). latest NON pousse / NON touche. Aucun build/deploy/kubectl/DB/trigger. Runtime DEV v1.0.55-dev + PROD v1.0.55-prod inchanges, restarts=0.

## 2. Preflight (E0)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78bfb94 | 78bfb94 | (.bak cruft) | OK |
| keybuzz-infra | main | 5a70b8f | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 12:09Z. Runtime informatif : DEV v1.0.55-amazon-inbound-dedup-dev, PROD v1.0.55-amazon-inbound-dedup-prod.

## 3. Image locale (E1)

| Item | Attendu | Resultat | verdict |
|---|---|---|---|
| Image ID | sha256:e3b5d2b30542... | sha256:e3b5d2b30542d21516137f5a53a842ee0b696fbcc17710df644594c2e4459e4c | OK |
| OCI revision | 78bfb9424675... | 78bfb9424675dd01105792ec74635730d597c849 | OK |
| OCI version | v1.0.56-amazon-inbound-dedup-dev | idem | OK |
| OCI created | 2026-05-27T11:59:44Z | idem | OK |

Markers dist deja prouves en PH-20.27 (E6) sur cette meme Image ID (computeInboundDedupLockScope, pg_advisory_xact_lock, amzmsg/thread, stableAmazonMessageKey, @map to, OUTBOUND_EMAIL_SEND, heartbeat, not-implemented=0). Image inchangee (meme Image ID) -> markers inchanges.

## 4. Collision GHCR (E2)

docker manifest inspect du tag v1.0.56-amazon-inbound-dedup-dev = ABSENT avant push (ok). latest = absent remote avant push (documente, non modifie).

## 5. Docker push (E3)

docker push ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-dev : 6 layers "already exists" (partages avec v1.0.55), 1 layer "Pushed" (83315a5f2718). Resultat : digest sha256:ed3d6c1a7f322166635ec87ece6c804c7a689a6611c8eebea3d326a8fe66f81b size 2626. Aucune mention latest. Push unique du tag immuable.

## 6. Pull-back + digest match (E4)

| Item | Local | Remote | Verdict |
|---|---|---|---|
| config digest | sha256:e3b5d2b30542...4459e4c (Image ID) | sha256:e3b5d2b30542...4459e4c (manifest .config.digest) | DIGEST_MATCH |
| manifest digest | - | sha256:ed3d6c1a7f32...f81b | OK |
| Image ID apres pull fresh | sha256:e3b5d2b30542...4459e4c | re-pull e3b5d2b30542...4459e4c | OK |
| RepoDigest | - | ghcr.io/keybuzzio/keybuzz-backend@sha256:ed3d6c1a7f32...f81b | OK |
| OCI revision remote | 78bfb94 | 78bfb94 | match |
| OCI version remote | v1.0.56-amazon-inbound-dedup-dev | idem | match |
| OCI created remote | 2026-05-27T11:59:44Z | idem | match |
| latest | - | ABSENT | non touche |

Pull-back par docker rmi du tag local puis docker pull frais : Image ID re-telecharge identique a e3b5d2b30542 -> integrite remote confirmee.

## 7. No runtime side-effect (E5)

| Garantie | etat |
|---|---|
| runtime DEV API + jobs-worker | v1.0.55-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.55-amazon-inbound-dedup-prod (inchange) |
| manifest ref v1.0.56 | aucun |
| pod restarts | 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |
| build | 0 |
| latest | non touche (absent) |

## 8. AI feature parity / anti-regression

Aucune modification runtime (push registry uniquement). IA / escalades / assignment / statuts / historique non touches. Outbound reply + guard validation non touches (image non deployee). KEY-323 P0 non rouvert.

## 9. Limites restantes

- Preuve runtime concurrence a etablir (post-apply DEV, vrai message ; advisory lock = vraie DB).
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8/as0yom) : non fusionne (decision produit).
- Reply-to obsoletes 3jcpvk/cp2hat cote Amazon : retrait manuel separe.
- Cleanup doublons existants : phase separee.

## 10. Next GO

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.29 : bump deployment.yaml API DEV + deployment-jobs-worker.yaml DEV v1.0.55-dev -> v1.0.56-dev (digest GHCR ed3d6c1a / config e3b5d2b30542), commit+push manifest AVANT apply, kubectl apply -f, rollout, verifier manifest=last-applied=runtime=digest + no unintended processing (Job/OutboundEmail inchanges, AMAZON_POLL worker-1=0, SMTP DEV inchange). Puis verify concurrence runtime sur vrai message.

## 11. Phrase cible

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP DEV DONE PH-SAAS-T8.12AS.20.28

STOP.
