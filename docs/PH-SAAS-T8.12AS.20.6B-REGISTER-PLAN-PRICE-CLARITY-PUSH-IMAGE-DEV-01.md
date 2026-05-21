# PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6B REGISTER PLAN PRICE CLARITY PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892`.
- Manifest digest GHCR : `sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622`.
- 11 layers total (6 reused base Next.js, 5 nouveaux chunks register PH-20.6B). ~100 MB compressed.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev |
| Image ID local | e329ea4d11af (sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892) |
| Size | 280 MB |
| Build commit | 97bdd5b (PH-20.6B QA fix source) |
| GHCR collision avant push | manifest unknown (LIBRE) |
| Runtime Client DEV | v3.5.208-register-polish-dev |
| Runtime Client PROD | v3.5.200-clarity-register-prod |

## E1 DOCKER PUSH GHCR

```
059ce65e6e0e: Pushed
67838733acbf: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
1b84bb75ef92: Pushed
af97f77ae2d3: Pushed
89bbb9ed641c: Pushed
v3.5.209-register-polish-dev: digest: sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused (base Next.js) | 6 |
| Layers nouveaux | 5 (chunks register PH-20.6B + Next.js standalone) |
| Manifest digest GHCR | sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 265 295 (~100 MB) |
| config.size | 12 883 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev` | OK |

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

- AUCUN docker build (image deja construite en BUILD DEV PH-20.6B).
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
| Verdict | GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev |
| Manifest digest GHCR | sha256:2f2981fd0807adf900b4e27f9045b206b56edcba3efd2c664e9f6e831515d622 |
| Config digest match local==GHCR | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Total compressed bytes | 105 265 295 (~100 MB) |
| Runtime Client DEV | v3.5.208-register-polish-dev INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6B`

STOP.
