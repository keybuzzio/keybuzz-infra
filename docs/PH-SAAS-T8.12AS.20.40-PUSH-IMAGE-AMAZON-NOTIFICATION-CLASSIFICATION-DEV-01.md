# PH-SAAS-T8.12AS.20.40-PUSH-IMAGE-AMAZON-NOTIFICATION-CLASSIFICATION-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.40 (PUSH IMAGE AMAZON NOTIFICATION CLASSIFICATION DEV)
> Environnement : DEV push-image only, AUCUN build/deploy/kubectl/DB

## 1. Verdict

GO PUSH IMAGE AMAZON NOTIFICATION CLASSIFICATION DEV DONE PH-SAAS-T8.12AS.20.40

Les 2 images DEV construites en PH-20.39 sont poussees sur GHCR, et le pull-back frais prouve config_digest_remote == Image ID local et RepoDigest == manifest digest pour chacune. Aucun build, aucun deploy, aucun kubectl, aucune mutation DB. Runtime DEV/PROD inchanges, manifests GitOps inchanges (aucune reference aux tags cibles), latest non touche (absent avant et apres). Le PARTIAL de PH-20.39 (ph119 api non re-execute) est non bloquant pour un push d'image et n'affecte pas la conformite des digests.

## 2. Preflight (E0)

| repo | branche | HEAD | origin | ahead | dirty | verdict |
|---|---|---|---|---:|---|---|
| keybuzz-backend | main | c38583a | c38583a | 0 | 1 (.bak untracked historique) | OK |
| keybuzz-api | ph147.4/source-of-truth | 8f050f06 | 8f050f06 | 0 | dist/ pre-existant (0 non-dist) | OK |
| keybuzz-infra | main | 1549ce3 | 1549ce3 | 0 | 0 | OK |

| service | namespace | image runtime | restarts |
|---|---|---|---:|
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | n/a |
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 0 |
| keybuzz-api | keybuzz-api-dev | v3.5.256-autopilot-no-reply-kbactions-dev | n/a |
| keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | n/a |

Bastion install-v3 / 46.62.171.61, 2026-05-27 ~16:04Z.

## 3. Images locales (E1)

| image | Image ID local | OCI revision | OCI version | verdict |
|---|---|---|---|---|
| keybuzz-backend:v1.0.57-amazon-notification-classification-dev | sha256:5d965707a087b3e93c8fb2925bf2c07de11de1f1d30fb6fb2db67c9ac30a3f6c | c38583a8548e60d21d817b85f028cb1868aea532 | v1.0.57-amazon-notification-classification-dev | OK |
| keybuzz-api:v3.5.258-amazon-notification-classification-dev | sha256:cb6f3601e97de61d7cc364f7e5ea5a628dff9b945039647a353f246e2611b4eb | 8f050f0644c0a1fb98d9b2d1430db03a956713b9 | v3.5.258-amazon-notification-classification-dev | OK |

## 4. Collision GHCR + latest (E2)

- GHCR backend v1.0.57-amazon-notification-classification-dev : ABSENT avant push.
- GHCR api v3.5.258-amazon-notification-classification-dev : ABSENT avant push.
- latest backend : ABSENT avant ET apres (non touche).
- latest api : ABSENT avant ET apres (non touche).

## 5. Push + pull-back BACKEND (E3/E4)

| signal | local | remote / pull-back | verdict |
|---|---|---|---|
| manifest digest (push) | n/a | sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806 | pousse |
| config digest remote | sha256:5d965707a087...c2c | sha256:5d965707a087...c2c | == Image ID local |
| pull-back Image ID | sha256:5d965707a087...c2c | sha256:5d965707a087...c2c (docker pull frais) | MATCH |
| RepoDigest | n/a | ghcr.io/keybuzzio/keybuzz-backend@sha256:ab583b9c57bb... | contient manifest digest |
| layers | n/a | 4 already-exist + 1 Pushed (b03a20cf61bc) | OK |

Tag pousse : ghcr.io/keybuzzio/keybuzz-backend:v1.0.57-amazon-notification-classification-dev. Aucune reference latest dans le push.

## 6. Push + pull-back API (E5/E6)

| signal | local | remote / pull-back | verdict |
|---|---|---|---|
| manifest digest (push) | n/a | sha256:732e307befa75c23945fd3088b90e23361dba1ea98efa84245da6aa37d9a033b | pousse |
| config digest remote | sha256:cb6f3601e97d...eb | sha256:cb6f3601e97d...eb | == Image ID local |
| pull-back Image ID | sha256:cb6f3601e97d...eb | sha256:cb6f3601e97d...eb (docker pull frais) | MATCH |
| RepoDigest | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:732e307befa7... | contient manifest digest |
| layers | n/a | 1 already-exist + 3 Pushed | OK |

Tag pousse : ghcr.io/keybuzzio/keybuzz-api:v3.5.258-amazon-notification-classification-dev. Aucune reference latest dans le push.

Note tooling : la presence remote est prouvee par docker (push -> manifest digest ; docker manifest inspect -> config digest ; docker rmi + docker pull frais -> RepoDigest). skopeo inspect sur le tag exact n'a pas renvoye de manifest (difference d'auth skopeo vs docker) ; cela n'infirme pas la presence remote car un docker pull frais ne peut reussir si le tag est absent du registry.

## 7. No side-effect (E7)

| signal | attendu | resultat |
|---|---|---|
| runtime backend DEV/PROD | inchange | v1.0.56-*-dev / -prod (inchange) |
| runtime api DEV/PROD | inchange | v3.5.256-*-dev / v3.5.257-*-prod (inchange) |
| backend pod restarts | 0 / inchange | 0 |
| manifests GitOps references tags cibles | aucune | aucune (K8s manifests, hors .git/COMMIT_EDITMSG) |
| latest backend/api | non touche | ABSENT avant/apres |
| build / docker build | aucun | aucun |
| kubectl apply/set/patch/edit/restart | aucun | aucun |
| DB mutation / migration / trigger / fake event | aucun | aucun |
| tags remote cibles | presents uniquement apres push | presents (pull-back reussi) |

## 8. AI feature parity / no fake metrics

Phase push-image only : aucun runtime modifie -> messages buyer Amazon, advisory lock amzmsg PH-20.26, outbound KEY-323, jobs-worker OUTBOUND_EMAIL_SEND, autopilot skip = tous intacts (rien deploye). Le skip ai-assist + le marquage notification + le guard buyer-first (!stableAmazonMessageKey, BUYER_HANDLE_RX) sont embarques dans les images DEV mais NON deployes. message_source=SYSTEM non introduit (confirme dist en PH-20.39). Aucun fake event/metric/webhook/ledger : aucune ecriture DB ni emission dans cette phase.

## 9. Prochaine etape recommandee

GO APPLY AMAZON NOTIFICATION CLASSIFICATION DEV GITOPS PH-SAAS-T8.12AS.20.41 : bump GitOps DEV des manifests vers backend v1.0.57-amazon-notification-classification-dev (deployment API + jobs-worker DEV si convention image partagee) et keybuzz-api DEV v3.5.258-amazon-notification-classification-dev ; commit+push manifest AVANT apply, kubectl apply -f uniquement, rollout, runtime=manifest=last-applied=digest, no unintended processing.

## 10. Phrase cible

GO PUSH IMAGE AMAZON NOTIFICATION CLASSIFICATION DEV DONE PH-SAAS-T8.12AS.20.40

STOP.
