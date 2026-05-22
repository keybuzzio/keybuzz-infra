# PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-PUSH-IMAGE-DEV-01

> Date : 2026-05-22
> Linear : KEY-337 (parent PH-20) ; KEY-338 (primary) ; KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.9B PUSH IMAGE API DEV Meta CAPI EMQ
> Environnement : Push GHCR DEV only (aucun build, aucun deploy, aucune migration)

## VERDICT

GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f`.
- Manifest digest GHCR : `sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4`.
- 10 layers (7 reused + 3 new chunks compile PH-20.9B). Total compressed ~112 MB.
- OCI revision label = d88aa7d0b72e6f14874f8cfa87c366139b7c4b17.
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime API PROD `v3.5.251-billing-tenant-id-fallback-prod` INCHANGE.
- Runtime Client + Website + Admin INCHANGES.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie. Aucune migration appliquee live.

STOP avant APPLY DEV. Migration 032 doit etre appliquee sur DB DEV AVANT rollout image.

## E0 PREFLIGHT

| Item | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22T12:06:55Z |
| Tag image cible | ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev |
| Image ID local | 22b70fe18d17 (sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f) |
| Size local | 343 MB |
| OCI revision label | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |

## E1 GHCR COLLISION CHECK

| Tag | Inspect avant push | Verdict |
|---|---|---|
| v3.5.253-meta-capi-emq-dev | manifest unknown | LIBRE OK |

## E2 DOCKER PUSH GHCR

```
d3901d53f250: Layer already exists
c8b0f2c8a629: Layer already exists
e61d2a995383: Layer already exists
7a7517ab2e5a: Layer already exists
9cc01943aa82: Layer already exists
1162d08df74c: Layer already exists
29df493baa13: Layer already exists
eb5831b8cbeb: Pushed
161cc9e6fa43: Pushed
5df05835a6c6: Pushed
v3.5.253-meta-capi-emq-dev: digest: sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total | 10 |
| Layers reused | 7 |
| Layers nouveaux | 3 (chunks compile PH-20.9B) |
| Manifest digest GHCR | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 |
| Manifest size | 2416 bytes |
| config.size | 12 476 bytes |
| Total layer bytes (compressed) | 112 042 855 (~112 MB) |
| Push exit code | 0 |

## E3 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f | **MATCH OK** |
| Manifest digest (repo digest) | n/a | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev` | OK |
| OCI revision label | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 | preserve via push | OK |

## E4 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.201-register-polish-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.20-cmp-mobile-polish-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun kubectl apply. Aucun manifest GitOps modifie. Aucune migration DB appliquee.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image deja construite en BUILD DEV PH-20.9B).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token / pixel ID affiche.
- AUCUNE mutation DB / Stripe.
- AUCUNE migration appliquee live (032 reste fichier source uniquement).
- AUCUN faux register / lead / formulaire / event Meta.
- AUCUN test register/checkout.
- AUCUN ticket Linear statut modifie.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN (anticipation APPLY DEV futur)

Si apply DEV + rollout provoquent regression :
1. Rollback tag DEV runtime actuel : `v3.5.252-billing-tenant-id-fallback-dev`.
2. Procedure GitOps : editer manifest `k8s/keybuzz-api-dev/deployment.yaml` -> revenir v3.5.252 + commit + push + apply.
3. Optionnel : DROP COLUMN migration 032 si schema instable (reversible).

INTERDIT : kubectl set image / git reset --hard / git clean.

## SEQUENCING APPLY DEV (a venir, GO requis)

1. Appliquer migration 032 sur DB DEV `keybuzz` via `node migrate.js` ou tooling dedie.
2. Verifier `SELECT column_name FROM information_schema.columns WHERE table_name=signup_attribution AND column_name IN ('client_ip_address', 'client_user_agent')` retourne 2 lignes.
3. Bump manifest `k8s/keybuzz-api-dev/deployment.yaml` v3.5.252 -> v3.5.253-meta-capi-emq-dev.
4. Commit infra + push origin/main.
5. kubectl apply -f + rollout status timeout 180s.
6. Smoke API DEV /health + verifier triple match last-applied = manifest = pod imageID.
7. Logs API DEV : verifier emitter pulls IP/UA + tenant_metadata fn/ln/phone sans error.

## GAPS

1. Aucun. Push GHCR DEV clean, digest match, runtime inchange, OCI label revision preserve.
2. **Sequencing critique pour APPLY DEV** : migration 032 doit etre appliquee AVANT rollout pour eviter degradation silencieuse (try/catch non-blocking degrade vers fallback null si colonne absente, pas de crash mais EMQ pas enrichi).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API META CAPI EVENT MATCH QUALITY DEV READY PH-SAAS-T8.12AS.20.9B |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.253-meta-capi-emq-dev |
| Manifest digest GHCR | sha256:eeee4dfb1ad2d31758b976a0c2b20cc8697d8a65ffaf72ccd416dd8ef58bf5c4 |
| Config digest match local==GHCR | sha256:22b70fe18d17b4d9e2034c40b01d1f161bac14f541136a4b566ca9573fbd0d2f |
| Manifest size | 2416 |
| Layers | 10 (7 reused + 3 new) |
| Total compressed bytes | 112 042 855 (~112 MB) |
| OCI revision preserve | d88aa7d0b72e6f14874f8cfa87c366139b7c4b17 |
| Runtime API DEV/PROD | v3.5.252 / v3.5.251 INCHANGES |
| Runtime Client/Website/Admin | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.9B-META-CAPI-EVENT-MATCH-QUALITY-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API META CAPI EVENT MATCH QUALITY DEV PH-SAAS-T8.12AS.20.9B`

Rappel critique APPLY DEV : migration 032 a appliquer sur DB DEV AVANT rollout image.

STOP. Aucun deploy, aucun kubectl apply, aucune migration appliquee live.
