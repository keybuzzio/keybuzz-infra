# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-PUSH-IMAGE-PROD-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK PUSH IMAGE PROD
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042`.
- Manifest digest GHCR (repo digest) : `sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8`.
- 10 layers total tous reused (deja sur GHCR via push DEV PH-20.5). Manifest+config nouveaux uniquement.
- Total compressed bytes : 112 041 037 (~107 MB).
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime API PROD `v3.5.250-ad-spend-sync-all-prod` INCHANGE.
- Runtime Client + Website + Admin DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY PROD (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| Image ID local | 867ecc25a0bb (sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042) |
| Size | 343 MB |
| Build commit | 6850427c (PH-20.5 source patch) |
| OCI labels KEY-308 | 5/5 OK |
| Patched code dist/ | present (commentaires + fallback + regex defense + log) |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod |

### GHCR collision check final avant push

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.251-billing-tenant-id-fallback-prod | `manifest unknown` | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
f31ae70cd8aa: Layer already exists
d3901d53f250: Layer already exists
e0979a834c94: Layer already exists
c8b0f2c8a629: Layer already exists
8e6fce276d7b: Layer already exists
7a7517ab2e5a: Layer already exists
e61d2a995383: Layer already exists
9cc01943aa82: Layer already exists
1162d08df74c: Layer already exists
29df493baa13: Layer already exists
v3.5.251-billing-tenant-id-fallback-prod: digest: sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 10 |
| Layers already exists | 10/10 (reuse complet depuis push DEV PH-20.5 v3.5.252) |
| Layers Pushed nouveaux | 0 |
| Manifest digest GHCR | sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |
| Manifest size | 2416 bytes |
| Total layer bytes (compressed) | 112 041 037 (~107 MB) |
| config.size | 12 484 bytes |
| Push exit code | 0 |

Note : 10/10 layers reused = optimisation parfaite. Le code TypeScript compile produit le meme contenu binaire DEV/PROD (server-side, pas de NEXT_PUBLIC_* differents). Seuls les labels OCI (revision/version/title pour PROD vs DEV) different dans la config image, ce qui produit un nouvel image ID + manifest digest specifique PROD.

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD PROD).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN evenement marketing.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement (operation registry).
- Aucun event Lead/Purchase/StartTrial/CompletePayment.
- Aucun pixel Meta/TikTok/LinkedIn.
- Aucun checkout PROD reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation phase APPLY PROD)

Si push image + apply PROD provoquent regression :

1. Rollback tag PROD runtime actuel : `v3.5.250-ad-spend-sync-all-prod` (digest GHCR a documenter en phase apply).
2. Rollback procedure : editer `k8s/keybuzz-api-prod/deployment.yaml` -> revenir image v3.5.250-ad-spend-sync-all-prod + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

Suppression image GHCR push (cas extreme) :

- Suppression via GitHub Packages UI manuelle.

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange, layers reuse complet.
2. Note : la branche `existingPending` reste non patchee dans le code (decision PH-20.5 scope). Tenant orphan PROD `-mpfmgx09` Antoine non touche par cette phase. Cleanup PH-20.7 separe.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| Manifest digest GHCR | sha256:25fc2c42170567b87c60fc2adf9ea70536452f74206748153b43fc5c82fb32b8 |
| Config digest match local==GHCR | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 |
| Manifest size | 2416 |
| Layers | 10 (10/10 reused) |
| Total compressed bytes | 112 041 037 (~107 MB) |
| Runtime API DEV | v3.5.252-billing-tenant-id-fallback-dev INCHANGE |
| Runtime API PROD | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Runtime Client/Website/Admin DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API BILLING TENANT_ID FALLBACK PROD PH-SAAS-T8.12AS.20.5`

STOP.
