# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER CTA TRIAL COPY PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8`.
- Manifest digest GHCR : `sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281`.
- 11 layers total (6 reused base Next.js, 5 nouveaux chunks register PH-20.6C). ~100 MB compressed.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev |
| Image ID local | 7772629cf126 (sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8) |
| Size | 280 MB |
| Build commit | be45f1d (PH-20.6C source) |
| GHCR collision avant push | manifest unknown (LIBRE) |
| Runtime Client DEV | v3.5.208-register-polish-dev |
| Runtime Client PROD | v3.5.200-clarity-register-prod |

## E1 DOCKER PUSH GHCR

```
099ae0440151: Pushed
710fa0585dc7: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
50ed6c5afe12: Pushed
1fe67cde70d5: Pushed
336174b4e302: Pushed
v3.5.210-register-polish-dev: digest: sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6 |
| Layers nouveaux | 5 (chunks register PH-20.6C + Next.js standalone) |
| Manifest digest GHCR | sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 265 601 (~100 MB) |
| config.size | 12 884 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8 | sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8 | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV PH-20.6C).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUNE mutation DB.
- AUCUN appel Stripe.
- AUCUN faux register.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- 0 fake event delta vs baseline v3.5.208.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si apply DEV + rollout provoquent regression :
1. Rollback tag DEV runtime actuel : `v3.5.208-register-polish-dev`.
2. Procedure : editer manifest `k8s/keybuzz-client-dev/deployment.yaml` -> revenir v3.5.208 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev |
| Manifest digest GHCR | sha256:434025f2bc32f42cce71d58c774fa05bf9cc0194ac3e33ce6100275482bc9281 |
| Config digest match local==GHCR | sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8 |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Total compressed bytes | 105 265 601 (~100 MB) |
| Runtime Client DEV | v3.5.208-register-polish-dev INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6C`

STOP.
