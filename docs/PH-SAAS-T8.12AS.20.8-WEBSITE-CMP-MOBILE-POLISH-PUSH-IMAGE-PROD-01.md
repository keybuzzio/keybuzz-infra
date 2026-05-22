# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-PUSH-IMAGE-PROD-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH PUSH IMAGE PROD
> Environnement : Push GHCR uniquement / aucun build / aucun deploy

## VERDICT

GO PUSH IMAGE WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8

- Image Docker `ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e`.
- Manifest digest GHCR : `sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23`.
- 11 layers (8 reused base Next.js + 3 nouveaux chunks CMP mobile polish PROD). ~74 MB compressed.
- Runtime Website DEV `v0.6.20-cmp-mobile-polish-dev` INCHANGE.
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Runtime Client+API+Admin INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY PROD. GO PROD explicit Ludovic requis.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-website HEAD | bb49798 |
| keybuzz-infra HEAD | 64fe02e |
| Tag | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod |
| Image ID local | e804b22e0b83 (sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e) |
| Size | 214 MB |
| GHCR collision avant push | manifest unknown (LIBRE) |
| Runtime Website DEV | v0.6.20-cmp-mobile-polish-dev |
| Runtime Website PROD | v0.6.19-cta-tracking-prod |

## E1 GHCR COLLISION CHECK

| Tag | docker manifest inspect avant push | Verdict |
|---|---|---|
| v0.6.20-cmp-mobile-polish-prod | manifest unknown | LIBRE OK |

## E2 DOCKER PUSH GHCR

```
2b9a2f2ce418: Layer already exists
7b97cad5e745: Layer already exists
ad82ae140432: Layer already exists
4cbec844eef7: Layer already exists
afa543f85b46: Layer already exists
e10358715ead: Layer already exists
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
fbe3adf424be: Pushed
49fe9d98a008: Pushed
14699cceca12: Pushed
v0.6.20-cmp-mobile-polish-prod: digest: sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 size: 2619
```

| Indicateur | Valeur |
|---|---|
| Layers total | 11 |
| Layers reused | 8 |
| Layers nouveaux | 3 (chunks Next.js standalone post-build CookieConsent.tsx PROD) |
| Manifest digest GHCR | sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 |
| Manifest size | 2619 bytes |
| config.size | 12 797 bytes |
| Total layer bytes (compressed) | 74 395 262 (~74 MB) |
| Push exit code | 0 |

## E3 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod` | OK |

## E4 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD PROD PH-20.8).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register / lead / formulaire.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Push container Docker uniquement.
- 0 fake event delta vs baseline v0.6.19 PROD (deja audite BUILD PROD).
- Aucun pixel touche.
- Aucun lead cree.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation APPLY PROD)

Si apply PROD + rollout provoquent regression :
1. Rollback tag PROD runtime actuel : `v0.6.19-cta-tracking-prod`.
2. Procedure GitOps : editer manifest `k8s/website-prod/deployment.yaml` -> revenir v0.6.19 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Push GHCR PROD clean, digest match, runtime inchange.
2. GO PROD explicit Ludovic requis avant APPLY PROD (DEV avant PROD).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod |
| Manifest digest GHCR | sha256:f936b7b4e72a37b81d697f13fba1f040396ff1d9789fbb7df0ea874d84e5df23 |
| Config digest match local==GHCR | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e |
| Manifest size | 2619 |
| Layers | 11 (8 reused + 3 new) |
| Total compressed bytes | 74 395 262 (~74 MB) |
| Runtime Website DEV | v0.6.20-cmp-mobile-polish-dev INCHANGE |
| Runtime Website PROD | v0.6.19-cta-tracking-prod INCHANGE |
| Runtime Client+API+Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-PUSH-IMAGE-PROD-01.md` |

### Prochaine phrase GO attendue

`GO APPLY WEBSITE CMP MOBILE POLISH PROD PH-SAAS-T8.12AS.20.8`

GO PROD explicit Ludovic requis dans la conversation courante avant tout apply PROD.

STOP.
