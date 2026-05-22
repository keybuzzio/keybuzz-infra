# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8

- Image Docker `ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8`.
- Manifest digest GHCR : `sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe`.
- 11 layers (8 reused base Next.js + 3 nouveaux chunks CMP mobile polish). ~74 MB compressed.
- Runtime Website DEV `v0.6.19-cta-tracking-dev` INCHANGE.
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Runtime Client DEV+PROD INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev |
| Image ID local | 5bd890c75448 (sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8) |
| Size | 214 MB |
| Build commit | bb49798 (PH-20.8 source) |
| GHCR collision avant push | manifest unknown (LIBRE) |
| Runtime Website DEV | v0.6.19-cta-tracking-dev |
| Runtime Website PROD | v0.6.19-cta-tracking-prod |

## E1 DOCKER PUSH GHCR

```
2b9a2f2ce418: Layer already exists
7b97cad5e745: Layer already exists
ad82ae140432: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
77c63e7b0fad: Pushed
1a95080afc4f: Pushed
a27f21a8cdd5: Pushed
v0.6.20-cmp-mobile-polish-dev: digest: sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe size: 2619
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 8 |
| Layers nouveaux | 3 (chunks Next.js standalone post-build CookieConsent.tsx) |
| Manifest digest GHCR | sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe |
| Manifest size | 2619 bytes |
| Total layer bytes (compressed) | 74 397 852 (~74 MB) |
| config.size | 12 788 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev/-prod | v3.5.252 / v3.5.251 | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV PH-20.8).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- 0 fake event delta vs baseline v0.6.19.
- Aucun pixel touche.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation APPLY DEV)

Si apply DEV + rollout provoquent regression :
1. Rollback tag DEV runtime actuel : `v0.6.19-cta-tracking-dev`.
2. Procedure GitOps : editer manifest `k8s/keybuzz-website-dev/deployment.yaml` -> revenir v0.6.19 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev |
| Manifest digest GHCR | sha256:e7e09b2653a539079090307070876c40cd13b772d382a5ee6b2dbce5e3f833fe |
| Config digest match local==GHCR | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 |
| Manifest size | 2619 |
| Layers | 11 (8 reused + 3 new) |
| Total compressed bytes | 74 397 852 (~74 MB) |
| Runtime Website DEV | v0.6.19-cta-tracking-dev INCHANGE |
| Runtime Website PROD | v0.6.19-cta-tracking-prod INCHANGE |
| Runtime Client+API+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY WEBSITE CMP MOBILE POLISH DEV PH-SAAS-T8.12AS.20.8`

STOP.
