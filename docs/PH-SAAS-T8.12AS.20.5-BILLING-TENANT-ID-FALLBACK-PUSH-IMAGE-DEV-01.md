# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-PUSH-IMAGE-DEV-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK PUSH IMAGE DEV
> Environnement : Push GHCR uniquement / aucun build / aucun deploy / aucun manifest change

## VERDICT

GO PUSH IMAGE API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5

- Image Docker `ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev` pushee sur GHCR.
- Config digest match local == GHCR : `sha256:027f442817612d8c9982b3ffab1a953ce756f779624ff3a6f5cdd1b5e4b91f89`.
- Manifest digest GHCR (repo digest) : `sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea`.
- 10 layers total (6 reused base Node.js, 3 nouveaux app + 1 config) ; ~107 MB compressed.
- Runtime API DEV `v3.5.251-register-cro-dev` INCHANGE.
- Runtime API PROD `v3.5.250-ad-spend-sync-all-prod` INCHANGE.
- Runtime Client DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Aucun build. Aucun deploy. Aucun manifest GitOps modifie.

STOP avant APPLY DEV (kubectl apply -f).

## E0 PREFLIGHT

### Image locale verifiee avant push

| Item | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev |
| Image ID local | 027f44281761 (sha256:027f442817612d8c9982b3ffab1a953ce756f779624ff3a6f5cdd1b5e4b91f89) |
| Size | 343 MB |
| Build commit | 6850427c |
| OCI labels KEY-308 | 5/5 OK |
| Patched code dist/ | present (fallback + regex defense + log) |

### Runtime avant push

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |

### GHCR collision avant push

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.252-billing-tenant-id-fallback-dev | `manifest unknown` | LIBRE OK |

## E1 DOCKER PUSH GHCR

### Push log

```
d3901d53f250: Layer already exists
7a7517ab2e5a: Layer already exists
e61d2a995383: Layer already exists
9cc01943aa82: Layer already exists
1162d08df74c: Layer already exists
29df493baa13: Layer already exists
e0979a834c94: Pushed
f31ae70cd8aa: Pushed
8e6fce276d7b: Pushed
v3.5.252-billing-tenant-id-fallback-dev: digest: sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea size: 2416
```

| Indicateur | Valeur |
|---|---|
| Layers total (manifest count) | 10 |
| Layers already exists (reuse Node.js base) | 6 |
| Layers Pushed nouveaux | 3 (dist/ avec patch + node_modules pruned + package files) |
| Manifest digest GHCR | sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea |
| Manifest size | 2416 bytes |
| Total layer bytes (compressed) | 112 041 037 (~107 MB) |
| config.size | 12 480 bytes |
| Push exit code | 0 |

## E2 MATCH VERIFY GHCR vs LOCAL

| Item | Local | GHCR | Verdict |
|---|---|---|---|
| Config digest (image ID) | sha256:027f442817612d8c9982b3ffab1a953ce756f779624ff3a6f5cdd1b5e4b91f89 | sha256:027f442817612d8c9982b3ffab1a953ce756f779624ff3a6f5cdd1b5e4b91f89 | **MATCH OK** |
| Manifest digest | n/a | sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-api@sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea | OK |
| Pull idempotence | n/a | `Image is up to date for ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev` | OK |

## E3 RUNTIME INCHANGE POST-PUSH

| Service | Namespace | Image runtime apres push | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun kubectl apply. Aucun manifest GitOps modifie.

## CONFIRMATIONS SECURITE

- AUCUN docker build (image existait deja en local apres BUILD DEV).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source.
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN Linear ticket modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Aucun rollback runtime necessaire (push only).

Pour la phase APPLY DEV suivante :

- Rollback tag DEV runtime actuel : `v3.5.251-register-cro-dev`.
- Rollback procedure : editer `k8s/keybuzz-api-dev/deployment.yaml` -> revenir image v3.5.251-register-cro-dev + commit + push + apply.

Suppression image GHCR push (cas extreme) :

- Suppression via GitHub Packages UI manuelle (non execute par CE).

## GAPS

1. Aucun. Push GHCR clean, digest match, runtime inchange.
2. Note : la branche `existingPending` reste non patchee dans le code (decision PH-20.5 scope). Si user a un tenant orphan deja en DB, le nouveau register reuse cet id orphan. Cleanup PH-20.7 separe.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO PUSH IMAGE API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5 |
| Bastion | install-v3 46.62.171.61 |
| Tag pushe | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev |
| Manifest digest GHCR | sha256:5dc670ab8690b77fd65b4cd95290d005087c74b043a7d4b6d7c8e8436c7f8eea |
| Config digest match local==GHCR | sha256:027f442817612d8c9982b3ffab1a953ce756f779624ff3a6f5cdd1b5e4b91f89 |
| Manifest size | 2416 |
| Layers | 10 (6 reused + 3 new + 1 config) |
| Total compressed bytes | 112 041 037 (~107 MB) |
| Runtime API DEV | v3.5.251-register-cro-dev INCHANGE |
| Runtime API PROD | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Runtime Client/Website/Admin DEV+PROD | INCHANGES |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-PUSH-IMAGE-DEV-01.md` |

### Prochaine phrase GO attendue

`GO APPLY API BILLING TENANT_ID FALLBACK DEV PH-SAAS-T8.12AS.20.5`

STOP.
