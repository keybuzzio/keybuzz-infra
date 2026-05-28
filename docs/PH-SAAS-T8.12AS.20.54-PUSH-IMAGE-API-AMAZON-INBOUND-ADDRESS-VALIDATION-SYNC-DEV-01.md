# PH-SAAS-T8.12AS.20.54-PUSH-IMAGE-API-AMAZON-INBOUND-ADDRESS-VALIDATION-SYNC-DEV-01

> Date : 2026-05-28
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.54 (PUSH IMAGE ONLY - image API DEV PH-20.53 sur GHCR)
> Environnement : DEV preparation / PUSH IMAGE ONLY ; AUCUN build, deploy, kubectl, mutation DB, backfill

## 1. Verdict

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV DONE PH-SAAS-T8.12AS.20.54

Image API DEV PH-20.53 poussee sur GHCR (tag cible uniquement, non-force). Digest prouve par
pull-back : config digest remote == Image ID local, pull frais Image ID identique, RepoDigest =
manifest digest pousse. latest non touche, runtime DEV/PROD inchange. Reste : revue + GO APPLY
GITOPS DEV (PH-20.55).

## 2. Rappel UX (important)

Il n'existe PAS de bouton de validation Amazon dans Channels et cette phase n'en cree aucun. Cette
phase pousse seulement l'image API DEV du correctif de synchronisation de statut Backend -> product
DB API.

## 3. Preflight (E0)

| signal | attendu | resultat | verdict |
|---|---|---|---|
| bastion / IP | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 (pas de 51.159.99.247) | OK |
| keybuzz-api origin ph147.4 | contient 798db37c | origin HEAD = 798db37ca108... | OK |
| keybuzz-infra | clean | main 8ca85c8, dirty 0 | OK |
| runtime API PROD | v3.5.259 inchange | v3.5.259, 1/1, restarts=0 | OK |
| runtime API DEV | v3.5.259 inchange | v3.5.259, 1/1 | OK |
| manifest referencant tag cible | aucun | aucun | OK |

## 4. Image (E1) + re-audit markers (E2)

| tag | Image ID | OCI revision | OCI version | verdict |
|---|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev | sha256:87c8d01b49fad6862565fb0aed8020dbd6779ece3d217fa113b8b23779d88632 | 798db37ca108c792a79749b939d9f7420120b7a5 | v3.5.260-amazon-inbound-address-sync-dev | OK (== PH-20.53) |

created OCI label = 2026-05-28T09:01:21Z (coherent PH-20.53).

| marker | count/resultat | verdict |
|---|---|---|
| dist helper normalizeInboundValidationStatus.js | 2 | present |
| route utilise helper | 2 | present |
| route validationStatus | 2 | present |
| route marketplaceStatus | 2 | present |
| worker gate validationStatus='VALIDATED' | 1 | intact |
| determineAmazonProvider | 3 | present |
| determineAiAssistNotificationSkip | 2 | present |
| hardcode tenant/token dans les 2 fichiers du patch | 0 | OK |

## 5. Collision GHCR + latest (E3)

- tag cible v3.5.260-amazon-inbound-address-sync-dev : ABSENT sur GHCR avant push.
- latest API snapshot avant push : sha256sum manifest = 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549.
- aucun manifest GitOps ne reference le tag cible.

## 6. Docker push (E4)

docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev
- 3 layers Pushed (f8c03dcd8f3b, b1abef52520e, 6b092c02106c), 4 Layer already exists.
- manifest digest : sha256:b05da3d78801a432851d2cd14c58cc6a4141f314c8539c12cc3a126b821b7a7e (size 2416).
- latest NON pousse.

## 7. Pull-back digest match (E5)

| signal | local | remote/pull-back | verdict |
|---|---|---|---|
| config digest | sha256:87c8d01b49fad686... (Image ID) | docker manifest inspect config.digest = sha256:87c8d01b49fad686... | MATCH |
| Image ID pull-back | sha256:87c8d01b49fad686... | apres rmi + docker pull frais = sha256:87c8d01b49fad686... | MATCH |
| manifest digest | - | RepoDigest = ghcr.io/keybuzzio/keybuzz-api@sha256:b05da3d78801... | OK |
| pull status | - | Downloaded newer image, Digest sha256:b05da3d78801... | OK |

Le digest config remote correspond bien a l'Image ID local PH-20.53, et le pull frais redonne
exactement le meme Image ID -> l'image GHCR est l'image construite en PH-20.53, sans alteration.

## 8. No side-effect (E6)

| signal | attendu | resultat | verdict |
|---|---|---|---|
| latest API | inchange | sha256sum manifest = 71d7e988869441ff... (== avant push) | OK |
| runtime API PROD | inchange | v3.5.259, 1/1, restarts=0 | OK |
| runtime API DEV | inchange | v3.5.259, 1/1 | OK |
| manifests k8s | sans tag cible | aucun ref | OK |
| build | aucun | aucun | OK |
| deploy / kubectl mutation | aucun | aucun (kubectl get read-only) | OK |
| DB write / backfill | aucun | aucun | OK |
| fake metric/event | aucun | aucun | OK |

## 9. Prochaine action

GO APPLY API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV GITOPS PH-SAAS-T8.12AS.20.55 : bump manifest
keybuzz-api DEV vers v3.5.260-amazon-inbound-address-sync-dev (commit+push AVANT apply), kubectl
apply -f, rollout, verifier runtime=manifest=last-applied=digest, puis re-test envoi
ecomlg-motxke32 et backfill Option A. PROD reste bloquee jusqu'a validation DEV complete.

## 10. Phrase cible

GO PUSH IMAGE API AMAZON INBOUND ADDRESS VALIDATION SYNC DEV DONE PH-SAAS-T8.12AS.20.54

STOP.
