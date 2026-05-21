# PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-PUSH-IMAGE-PROD-01

> Date : 2026-05-21
> Linear : KEY-339 (primary) ; KEY-337 (parent) ; KEY-338, KEY-340, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.2 CLARITY CLIENT REGISTER PUSH IMAGE PROD
> Environnement : Push GHCR PROD uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27`.
- Manifest digest GHCR (repo digest) : `sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987`.
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-client@sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987`.
- 11 layers total (6 already exists reuse, 5 nouveaux pushes Clarity-related).
- Runtime PROD `v3.5.199-register-state-persistence-prod` INCHANGE.
- Runtime DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY PROD (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod |
| Image ID local | 7fa9a3d22205 (sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27) |
| Size | 280 MB |
| Build commit | dad5f89 |
| OCI labels KEY-308 | 5/5 OK |
| Bundle PROD KEY-263 isolation | api.keybuzz.io=2, api-dev.keybuzz.io=0 |
| Bundle PROD Clarity | wuk12h9i33=1, clarity.ms=1, ms-clarity=1 |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod |

### GHCR collision avant push

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.200-clarity-register-prod | `manifest unknown` | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
8fa343c8b051: Pushed
dc42c7184e57: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
39f0a8a6b78e: Pushed
10bd921121b1: Pushed
c159e00be9f4: Pushed
v3.5.200-clarity-register-prod: digest: sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 11 |
| Layers already exists (reuse partagee avec PH-19.x ou v3.5.206 DEV) | 6 |
| Layers Pushed nouveaux | 5 (Clarity injection PROD + config) |
| Manifest digest GHCR | sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 264 555 (~100 MB) |
| config.size | 12 890 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27 | sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27 | **MATCH OK** |
| Manifest digest | n/a | sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

Verification immediate post-push :

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev / -prod | v0.6.18-ga4-cleanup-dev / -prod | INCHANGE |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev / -prod | v2.12.2-media-buyer-lp-domain-qa-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image existait deja en local apres BUILD-PROD).
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

Pour la phase APPLY PROD suivante :

- Rollback tag PROD runtime actuel : `v3.5.199-register-state-persistence-prod` (digest GHCR `sha256:dbeb9d53966d71949f723a1eac1266e56dd557e6dab6df16916c29e46651720a`).
- Rollback procedure : editer `k8s/keybuzz-client-prod/deployment.yaml` -> revenir image v3.5.199 + commit + push + apply.

Suppression image GHCR push (cas extreme, non execute par CE) :

- Suppression via GitHub Packages UI manuelle.

## GAPS

1. Aucun.
2. Clarity Project ID `wuk12h9i33` immutable dans le bundle v3.5.200 PROD. Toute rotation Clarity necessitera un nouveau build (rebuild from-git avec nouveau ID).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT CLARITY REGISTER PROD READY PH-SAAS-T8.12AS.20.2 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushee | ghcr.io/keybuzzio/keybuzz-client:v3.5.200-clarity-register-prod |
| Manifest digest GHCR | sha256:f22413551a3cf2c7cfc2b056c4a83e3deaaec360bd2213e0981f530e870ea987 |
| Config digest match local==GHCR | sha256:7fa9a3d222055846f2d0a86fa104687c5e9852bf68b6cecfdafc40d7f394ad27 |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Runtime DEV | v3.5.206-clarity-register-dev INCHANGE |
| Runtime PROD | v3.5.199-register-state-persistence-prod INCHANGE |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.2-CLARITY-CLIENT-REGISTER-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT CLARITY REGISTER PROD PH-SAAS-T8.12AS.20.2`

STOP.
