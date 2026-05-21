# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK BUILD DEV
> Environnement : BUILD DEV uniquement (aucun docker push, aucun deploy)

## VERDICT

GO BUILD API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev` build OK depuis worktree --detach commit `6850427c`.
- Image ID local : `sha256:027f44281761...` size 343 MB.
- OCI labels KEY-308 : 5/5 OK (revision, created, version, source, title).
- Patched code present dans `/app/dist/modules/auth/tenant-context-routes.js` : commentaires PH-20.5 + fallback `|| 'tenant'` + regex check defensive + log "Generated tenantId rejected by regex".
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push effectue.
- Runtime API DEV `v3.5.251-register-cro-dev` INCHANGE.
- Runtime API PROD `v3.5.250-ad-spend-sync-all-prod` INCHANGE.
- Worktree nettoyee post-build.
- STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 17:01 |
| keybuzz-api branche | ph147.4/source-of-truth |
| keybuzz-api HEAD avant build | 6850427c (PH-20.5 source patch) |
| keybuzz-api local == origin | OK |
| keybuzz-api src/ dirty | 0 |
| keybuzz-infra HEAD | 89c8f38 (rapport PH-20.5 source) |
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5/keybuzz-api |
| Worktree detache sur | 6850427c |
| Worktree dirty | 0 |
| GHCR tag cible v3.5.252-billing-tenant-id-fallback-dev | `manifest unknown` LIBRE OK |

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | -dev | v3.5.251-register-cro-dev | INCHANGE prevu |
| keybuzz-api | -prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE prevu |
| keybuzz-client | -dev/-prod | v3.5.206 / v3.5.200 | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Baseline DEV v3.5.251-register-cro-dev OCI labels :
- revision: 39e332eaa49a53433f403742837e56a75dda49cc
- created: 2026-05-20T06:58:49Z
- version: v3.5.251-register-cro-dev
- source: https://github.com/keybuzzio/keybuzz-api
- title: keybuzz-api

## E1 DOCKER BUILD

### Build command

```bash
docker build \
  --label "org.opencontainers.image.revision=6850427ce33f7537dffaf1facda761289271fc5e" \
  --label "org.opencontainers.image.created=2026-05-21T17:02:14Z" \
  --label "org.opencontainers.image.version=v3.5.252-billing-tenant-id-fallback-dev" \
  --label "org.opencontainers.image.source=https://github.com/keybuzzio/keybuzz-api" \
  --label "org.opencontainers.image.title=keybuzz-api" \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev .
```

| Indicateur | Valeur |
|---|---|
| Dockerfile | keybuzz-api/Dockerfile (multi-stage node:lts -> node:lts-alpine) |
| Build args | aucun (API server-side, pas de NEXT_PUBLIC_* requis) |
| Build steps | npm ci -> COPY src/ -> npm run build -> npm prune --omit=dev -> Stage 2 runner |
| Exit code | 0 |
| Build duration | ~60-90s (estimee via background task) |

### Image locale

| Indicateur | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.252-billing-tenant-id-fallback-dev |
| Image ID local | sha256:027f44281761 |
| Size | 343 MB |
| Created | 2026-05-21T17:03:20Z |

### OCI labels KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 6850427ce33f7537dffaf1facda761289271fc5e | OK (commit PH-20.5 source) |
| org.opencontainers.image.created | 2026-05-21T17:02:14Z | OK |
| org.opencontainers.image.version | v3.5.252-billing-tenant-id-fallback-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E2 VERIFY PATCHED CODE IN BUILT IMAGE

Audit `/app/dist/modules/auth/tenant-context-routes.js` dans l image construite.

| Pattern | Resultat | Verdict |
|---|---|---|
| Commentaire `PH-SAAS-T8.12AS.20.5 (KEY-343): garantir slug non vide` | present | OK |
| Commentaire `PH-SAAS-T8.12AS.20.5 (KEY-343): defense en profondeur` | present | OK |
| Fallback `\|\| 'tenant'` (concat slug + tenantId final) | present (compile en `\|\| \`tenant-\`` + `\|\| 'tenant'`) | OK |
| Regex `[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}` (defense) | 2 occurrences (1 dans tenantSlug regex, 1 dans defense check) | OK |
| Log message `Generated tenantId rejected by regex` | present | OK |

Patch compile et inline dans le bundle JS. Aucun fallback de slug manquant ni regex check absent.

## E3 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR.
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit 6850427c (PH-20.5 source).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call.
- AUCUN evenement marketing envoye.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## WORKTREE CLEANUP

| Action | Resultat |
|---|---|
| `git worktree remove --force /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5/keybuzz-api` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5/` | OK |
| Worktree present apres cleanup ? | NON |

## ROLLBACK PLAN (anticipation phase suivante)

Si push image + apply DEV provoquent regression :

1. Rollback tag DEV runtime actuel : `v3.5.251-register-cro-dev` (digest GHCR a verifier).
2. Rollback procedure : editer `k8s/keybuzz-api-dev/deployment.yaml` -> revenir image v3.5.251-register-cro-dev + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, image valide, OCI labels conformes, patched code present.
2. Note : la branche `existingPending` (UPDATE tenant existant) reste non patchee. Si un user a un tenant orphan avec id malforme deja en DB, le nouveau register reuse cet id. Mitigation = cleanup PH-20.7 separe.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API BILLING TENANT_ID FALLBACK DEV READY PH-SAAS-T8.12AS.20.5 |
| Bastion | install-v3 46.62.171.61 |
| Source commit API | 6850427c |
| Tag image cible | v3.5.252-billing-tenant-id-fallback-dev |
| Image ID local | sha256:027f44281761 |
| Image size | 343 MB |
| OCI labels KEY-308 | 5/5 OK |
| Patched code dist/ | present (commentaires + fallback + regex defense + log) |
| GHCR collision tag DEV cible | LIBRE (manifest unknown) |
| Worktree | nettoyee |
| Runtime API DEV | v3.5.251-register-cro-dev INCHANGE |
| Runtime API PROD | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Mutations | AUCUNE |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API BILLING TENANT_ID FALLBACK DEV PH-SAAS-T8.12AS.20.5`

STOP.
