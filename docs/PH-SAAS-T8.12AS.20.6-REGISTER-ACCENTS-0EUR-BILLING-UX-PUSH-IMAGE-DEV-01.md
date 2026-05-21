# PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-PUSH-IMAGE-DEV-01

> Date : 2026-05-21
> Linear : KEY-342 (accents FR) ; KEY-345 (0 EUR every step + benefits) ; KEY-343 (UX billing error) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6 REGISTER POLISH PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f`.
- Manifest digest GHCR (repo digest) : `sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1`.
- 11 layers total (6 reused base Next.js, 5 nouveaux chunks register polish). ~100 MB compressed.
- Runtime Client DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime API PROD `v3.5.251-billing-tenant-id-fallback-prod` INCHANGE.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev |
| Image ID local | 2817c455a964 (sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f) |
| Size | 280 MB |
| Build commit | 3f88217 (PH-20.6 source patch) |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | api-dev=87, api-prod=0 |
| KEY-302 Clarity | wuk12h9i33=2 preservee |
| Register polish markers | trial-banner=2, Cockpit SAV=2, UX billing=2 |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod |

### GHCR collision check final

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.207-register-polish-dev | manifest unknown | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
4d27693c4928: Pushed
cc2ff9db470c: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
bef66f13d766: Pushed
be48a1f92a31: Pushed
b6d437800723: Pushed
v3.5.207-register-polish-dev: digest: sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 11 |
| Layers already exists (reuse base Next.js) | 6 |
| Layers Pushed nouveaux | 5 (chunks register polish + Next.js standalone build) |
| Manifest digest GHCR | sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 265 515 (~100 MB) |
| config.size | 12 880 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f | sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN appel Stripe.
- AUCUN faux register.
- AUCUN evenement marketing.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute (0 delta vs baseline v3.5.206).
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation phase APPLY DEV)

Si apply DEV + rollout provoquent regression :

1. Rollback tag DEV runtime actuel : `v3.5.206-clarity-register-dev`.
2. Rollback procedure : editer `k8s/keybuzz-client-dev/deployment.yaml` -> revenir image v3.5.206-clarity-register-dev + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange.
2. Note : delta layers 5/11 nouveaux (vs 3/9 pour PH-20.5 API) reflete les chunks Next.js standalone regeneres du fait du changement source +20 lignes dans app/register/page.tsx + TrialValueBanner. Normal Next.js, pas d'optimisation reuse possible sur les chunks JSX modifies.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev |
| Manifest digest GHCR | sha256:ef12b83eeac2aff61602431de9f685eb9537af7ee91f436e9c5baf9a31c14fb1 |
| Config digest match local==GHCR | sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Total compressed bytes | 105 265 515 (~100 MB) |
| Runtime Client DEV | v3.5.206-clarity-register-dev INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6`

STOP.
