# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-PUSH-IMAGE-DEV-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2`.
- Manifest digest GHCR (repo digest) : `sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d`.
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-client@sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d`.
- 9 layers total (6 already exists reuse PH-19.7, 3 nouveaux pushes).
- Runtime DEV `v3.5.205-register-state-persistence-dev` INCHANGE.
- Runtime PROD `v3.5.199-register-state-persistence-prod` INCHANGE.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev |
| Image ID local | a06f30e847ab (sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2) |
| Size | 280 MB |
| Build commit | dad5f89 |
| OCI labels KEY-308 | 5/5 OK |
| Bundle Clarity | wuk12h9i33 inline (1), clarity.ms/tag (1), ms-clarity script (1) |
| KEY-263 isolation | api-dev=2, api.keybuzz.io seul=0 |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.205-register-state-persistence-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod |

### GHCR collision avant push

| Item | Valeur |
|---|---|
| docker manifest inspect tag v3.5.206-clarity-register-dev | `manifest unknown` (LIBRE, OK) |

## E1 DOCKER PUSH GHCR

### Push log

```
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
22fdc6baabcc: Pushed
820a6c5e5d4a: Pushed
d7832e322ab6: Pushed
v3.5.206-clarity-register-dev: digest: sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 9 |
| Layers already exists (reuse PH-19.7 v3.5.205) | 6 |
| Layers Pushed nouveaux | 3 (Clarity injection + Dockerfile ENV change + cache .next) |
| Manifest digest GHCR | sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d |
| Manifest size | 2631 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2 | sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2 | **MATCH OK** |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

Verification immediate post-push :

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.205-register-state-persistence-dev | INCHANGE (push n affecte pas le runtime) |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image existait deja en local apres BUILD-DEV).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/Google Ads/Clarity.
- AUCUN faux Lead/Purchase/StartTrial ajoute.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Aucun rollback runtime necessaire (push only).

Pour la phase APPLY suivante :

- Rollback tag DEV runtime actuel : `v3.5.205-register-state-persistence-dev` (digest GHCR `sha256:be24d91500c21ee752b15d260a1ad16a24b67973918453bc17fed80ce1b23621`).
- Rollback procedure : editer `k8s/keybuzz-client-dev/deployment.yaml` -> revenir image v3.5.205-register-state-persistence-dev + commit + push + apply.

Suppression image GHCR push (cas extreme) :

- Suppression via GitHub Packages UI (ne sera pas execute par CE).

## GAPS

1. Aucun.
2. Clarity Project ID `wuk12h9i33` est desormais immutable dans le bundle de l image v3.5.206. Toute rotation Clarity necessitera un nouveau build (rebuild from-git avec nouveau ID).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT CLARITY REGISTER DEV READY PH-SAAS-T8.12AS.20.2 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushee | ghcr.io/keybuzzio/keybuzz-client:v3.5.206-clarity-register-dev |
| Manifest digest GHCR | sha256:16e95517b0c45fda0bb4e7bb1700f9832d98fea0bf3d9b7d5ce2a9db6d55408d |
| Config digest match local==GHCR | sha256:a06f30e847ab7a96c41743a654271816e7c79eb033364c29ecf208d5bfe078b2 |
| Manifest size | 2631 |
| Layers | 9 (6 reused + 3 new) |
| Runtime DEV | v3.5.205-register-state-persistence-dev INCHANGE |
| Runtime PROD | v3.5.199-register-state-persistence-prod INCHANGE |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT CLARITY REGISTER DEV PH-SAAS-T8.12AS.20.2`

STOP.
