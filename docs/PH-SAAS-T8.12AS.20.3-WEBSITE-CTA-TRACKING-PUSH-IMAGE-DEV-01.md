# PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-PUSH-IMAGE-DEV-01

> Date : 2026-05-21
> Linear : KEY-340 (primary) ; KEY-337 (parent) ; KEY-338, KEY-339, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.3 WEBSITE CTA TRACKING PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3

- Image Docker `ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc`.
- Manifest digest GHCR (repo digest) : `sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed`.
- Repo digest pulled-back : `ghcr.io/keybuzzio/keybuzz-website@sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed`.
- 11 layers total (8 already exists reuse, 3 nouveaux pushes).
- Runtime Website DEV `v0.6.18-ga4-cleanup-dev` INCHANGE.
- Runtime Website PROD `v0.6.18-ga4-cleanup-prod` INCHANGE.
- Runtime Client DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev |
| Image ID local | 9802b2602e5d (sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc) |
| Size | 214 MB |
| Build commit | 6af74a2 |
| OCI labels KEY-308 | 5/5 OK |
| Bundle KEY-263 isolation DEV | api-dev=2, api.keybuzz.io seul=0 |
| Bundle marketing IDs preserves vs v0.6.18 | GA4 18, SGTM 54, Meta 2, TikTok 2, LinkedIn 2 |
| Bundle trackMarketingClick | 40 (vs baseline 26) |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |

### GHCR collision avant push

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v0.6.19-cta-tracking-dev | `manifest unknown` | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
4983b93ee796: Layer already exists
29df493baa13: Layer already exists
ad82ae140432: Layer already exists
7b97cad5e745: Layer already exists
2b9a2f2ce418: Layer already exists
4cbec844eef7: Layer already exists
e10358715ead: Layer already exists
afa543f85b46: Layer already exists
0894f5b2df7d: Pushed
479cf24f5a8d: Pushed
8c1f0936ee75: Pushed
v0.6.19-cta-tracking-dev: digest: sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed size: 2619
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 11 |
| Layers already exists (reuse partagee baseline) | 8 |
| Layers Pushed nouveaux | 3 (Next.js standalone + .next builds avec CTA tracking changes) |
| Manifest digest GHCR | sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed |
| Manifest size | 2619 bytes |
| Total layer bytes (compressed) | 74 398 882 (~71 MB) |
| config.size | 12 772 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc | sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc | **MATCH OK** |
| Manifest digest | n/a | sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image existait deja en local apres BUILD DEV).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/LinkedIn/Google Ads.
- AUCUN faux Lead/Purchase/StartTrial ajoute.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Aucun rollback runtime necessaire (push only).

Pour la phase APPLY DEV suivante :

- Rollback tag DEV runtime actuel : `v0.6.18-ga4-cleanup-dev` (digest GHCR `sha256:63882ba57960726fe8689784e0d3325be327019acc466e8239635588fb47baec`).
- Rollback procedure : editer `k8s/website-dev/deployment.yaml` -> revenir image v0.6.18-ga4-cleanup-dev + commit + push + apply.

Suppression image GHCR push (cas extreme) :

- Suppression via GitHub Packages UI manuelle (non execute par CE).

## GAPS

1. Aucun.
2. 11 nouveaux cta_id PH-20.3 inline dans le bundle, immutable apres push. Rotation IDs necessite rebuild.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev |
| Manifest digest GHCR | sha256:2ec4789efa2ae74e3c4b84fa047f8f513c5ab06ad2ea1a98629170a2df1e66ed |
| Config digest match local==GHCR | sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc |
| Manifest size | 2619 |
| Layers | 11 (8 reused + 3 new) |
| Runtime Website DEV | v0.6.18-ga4-cleanup-dev INCHANGE |
| Runtime Website PROD | v0.6.18-ga4-cleanup-prod INCHANGE |
| Runtime Client DEV/PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3`

STOP.
