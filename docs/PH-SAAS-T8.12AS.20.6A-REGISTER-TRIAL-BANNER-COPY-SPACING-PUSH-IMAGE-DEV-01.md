# PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-PUSH-IMAGE-DEV-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6A REGISTER POLISH QA FIX PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A

- Image Docker `ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:ebac2d7b4e0ffb47788e5edda9f5e24487d9732365b6fb3560aa703463b0f786`.
- Manifest digest GHCR : `sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0`.
- 11 layers total (6 reused base Next.js, 5 nouveaux chunks register PH-20.6A). ~100 MB compressed.
- Runtime Client DEV `v3.5.207-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Runtime API DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev |
| Image ID local | ebac2d7b4e0f (sha256:ebac2d7b4e0ffb47788e5edda9f5e24487d9732365b6fb3560aa703463b0f786) |
| Size | 280 MB |
| Build commit | dbdc46f (PH-20.6A QA fix source) |
| OCI labels KEY-308 | 5/5 OK (revision=dbdc46f) |
| Bundle markers PH-20.6A live | trial-banner=2, Toutes les fonctionnalit=2, Inbox marketplace=2, Contexte commande=2, KeyBuzz rassemble=2 |
| Phrases interdites bundle | 0 (Autopilot inclus, Avant de regarder, Aucune CB, ancien Cockpit SAV banner) |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.207-register-polish-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod |

### GHCR collision check final

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.208-register-polish-dev | manifest unknown | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
cf26ea899bbf: Pushed
d51be7c52dff: Pushed
ff88504cd133: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
36e4b4cc8976: Pushed
68d7a47076ce: Pushed
f26aedc37350: Pushed
v3.5.208-register-polish-dev: digest: sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 size: 2631
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 11 |
| Layers already exists (reuse base Next.js) | 6 |
| Layers Pushed nouveaux | 5 (chunks register polish PH-20.6A + Next.js standalone build) |
| Manifest digest GHCR | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Manifest size | 2631 bytes |
| Total layer bytes (compressed) | 105 265 519 (~100 MB) |
| config.size | 12 882 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:ebac2d7b4e0ffb47788e5edda9f5e24487d9732365b6fb3560aa703463b0f786 | sha256:ebac2d7b4e0ffb47788e5edda9f5e24487d9732365b6fb3560aa703463b0f786 | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-client@sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.207-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV PH-20.6A).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUNE mutation DB.
- AUCUN appel Stripe.
- AUCUN faux register.
- AUCUN evenement marketing.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- Aucun event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- ajoute (0 delta vs baseline v3.5.207).
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation phase APPLY DEV)

Si apply DEV + rollout provoquent regression :

1. Rollback tag DEV runtime actuel : `v3.5.207-register-polish-dev`.
2. Rollback procedure : editer `k8s/keybuzz-client-dev/deployment.yaml` -> revenir image v3.5.207-register-polish-dev + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange.
2. Note : delta layers 5/11 nouveaux reflete les chunks Next.js standalone regeneres du fait du changement source -1 ligne net dans app/register/page.tsx (refonte TrialValueBanner + ReassurancePanel). Normal Next.js.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev |
| Manifest digest GHCR | sha256:327bed7b3d62cdab630cb852206b8edfd43178909ac593c1da0bb6a7732b32f0 |
| Config digest match local==GHCR | sha256:ebac2d7b4e0ffb47788e5edda9f5e24487d9732365b6fb3560aa703463b0f786 |
| Manifest size | 2631 |
| Layers | 11 (6 reused + 5 new) |
| Total compressed bytes | 105 265 519 (~100 MB) |
| Runtime Client DEV | v3.5.207-register-polish-dev INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod INCHANGE |
| Runtime API+Website+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6A`

STOP.
