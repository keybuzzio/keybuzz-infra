# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-PUSH-IMAGE-PROD-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER POLISH PUSH IMAGE PROD
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d`.
- Manifest digest GHCR : `sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5`.
- 11 layers (6 reused base Next.js, 5 nouveaux chunks register PH-20.6C PROD). ~100 MB compressed.
- Runtime Client DEV `v3.5.210-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY PROD.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod |
| Image ID local | 9fb8c455125b (sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d) |
| Size | 280 MB |
| Build commit | be45f1d (PH-20.6C source) |
| GHCR collision avant push | manifest unknown (LIBRE) |
| Runtime Client DEV | v3.5.210-register-polish-dev |
| Runtime Client PROD | v3.5.200-clarity-register-prod |

## E1 DOCKER PUSH GHCR

```
c85a2317b15b: Pushed
c9cf46f75eea: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
ed42e7735270: Pushed
779dfa2e0cba: Pushed
40a2caf7aacc: Pushed
v3.5.201-register-polish-prod: digest: sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 6 |
| Layers nouveaux | 5 (chunks register PH-20.6C + Next.js standalone) |
| Manifest digest GHCR | sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 265 612 (~100 MB) |
| config.size | 12 888 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD PROD PH-20.6C).
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
- 0 fake event delta vs baseline v3.5.200 PROD.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si apply PROD + rollout provoquent regression :
1. Rollback tag PROD runtime actuel : `v3.5.200-clarity-register-prod`.
2. Procedure GitOps : editer manifest `k8s/keybuzz-client-prod/deployment.yaml` -> revenir v3.5.200 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR PROD clean, digest match, runtime inchange.
2. GO PROD explicit Ludovic requis avant APPLY PROD.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod |
| Manifest digest GHCR | sha256:cdac2eccba00f83a967441d043e567620c1b9349c7a30314cbea17ccbdbd4cc5 |
| Config digest match local==GHCR | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Total compressed bytes | 105 265 612 (~100 MB) |
| Runtime Client DEV | v3.5.210-register-polish-dev INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT REGISTER POLISH PROD PH-SAAS-T8.12AS.20.6C`

GO PROD explicit Ludovic requis (DEV avant PROD - validation explicite obligatoire dans la conversation courante avant tout apply PROD).

STOP.
