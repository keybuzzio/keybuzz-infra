# PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-BUILD-PROD-01

> Date : 2026-05-21
> Linear : KEY-343 (primary) ; KEY-342, KEY-345 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.5 BILLING TENANT_ID FALLBACK BUILD PROD
> Environnement : PROD build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod` build OK depuis worktree --detach commit `6850427c`.
- Image ID local : `sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042` size 343 MB.
- OCI labels KEY-308 : 5/5 OK (revision/created/version/source/title).
- Patched code present dans `/app/dist/modules/auth/tenant-context-routes.js` : 2 commentaires PH-20.5, fallback `|| 'tenant'`, regex defense (2 occurrences `[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}`), log "Generated tenantId rejected by regex".
- GHCR tag PROD cible LIBRE (manifest unknown). Aucun docker push effectue.
- Runtime API DEV `v3.5.252-billing-tenant-id-fallback-dev` INCHANGE.
- Runtime API PROD `v3.5.250-ad-spend-sync-all-prod` INCHANGE.
- Worktree nettoyee post-build.
- STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 17:43:33 |
| Uname | Linux install-v3 6.8.0-88-generic #89-Ubuntu SMP 2025-10-11 x86_64 |
| keybuzz-api branche | ph147.4/source-of-truth |
| keybuzz-api HEAD | 6850427c (PH-20.5 source patch) |
| keybuzz-api src/ dirty | 0 |
| keybuzz-infra branche/HEAD | main / 021ecac |

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | -dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE prevu |
| keybuzz-api | -prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE prevu |
| keybuzz-client | -dev/-prod | v3.5.206 / v3.5.200 | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

## E1 VERIFICATION SOURCE PATCH

```
6850427c fix(auth): ensure generated tenant ids are checkout-safe
 src/modules/auth/tenant-context-routes.ts | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)
```

| Ligne | Pattern source | Verdict |
|---|---|---|
| 657 | `// PH-SAAS-T8.12AS.20.5 (KEY-343): garantir slug non vide pour eviter tenantId commencant par '-'` | OK |
| 659 | `const tenantSlug = (...).substring(0, 20)) \|\| 'tenant';` | OK fallback |
| 662 | `// PH-SAAS-T8.12AS.20.5 (KEY-343): defense en profondeur - le tenantId genere doit matcher la regex billing.` | OK |
| 666 | `console.error('[CreateSignup] Generated tenantId rejected by regex:', { length: tenantId.length, prefix: tenantId.charAt(0) });` | OK log sans PII |

## E2 GHCR COLLISION TAG PROD

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.251-billing-tenant-id-fallback-prod | `manifest unknown` | LIBRE OK |

## E3 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5-PROD/keybuzz-api |
| Fetch origin ph147.4/source-of-truth | OK |
| Worktree detache sur | 6850427c |
| Worktree dirty | 0 |
| Patched code present worktree | l.657-666 verifie |

## E4 DOCKER BUILD PROD

### Build command

```bash
docker build \
  --label "org.opencontainers.image.created=2026-05-21T17:44:01Z" \
  --label "org.opencontainers.image.revision=6850427ce33f7537dffaf1facda761289271fc5e" \
  --label "org.opencontainers.image.version=v3.5.251-billing-tenant-id-fallback-prod" \
  --label "org.opencontainers.image.source=https://github.com/keybuzzio/keybuzz-api" \
  --label "org.opencontainers.image.title=keybuzz-api" \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod .
```

| Indicateur | Valeur |
|---|---|
| Dockerfile | keybuzz-api/Dockerfile (multi-stage node:lts -> node:lts-alpine) |
| Build args | aucun (API server-side) |
| Build steps | npm ci -> COPY src/ -> npm run build -> npm prune --omit=dev -> Stage 2 runner |
| Exit code | 0 |
| Build duration | ~60-90s |

## E5 VERIFICATION IMAGE LOCALE

| Indicateur | Valeur |
|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-api:v3.5.251-billing-tenant-id-fallback-prod |
| Image ID local | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 |
| Image ID short | 867ecc25a0bb |
| Size | 343 MB |
| Created | 2026-05-21T17:44:02Z |

### OCI labels KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 6850427ce33f7537dffaf1facda761289271fc5e | OK (commit PH-20.5 source) |
| org.opencontainers.image.created | 2026-05-21T17:44:01Z | OK |
| org.opencontainers.image.version | v3.5.251-billing-tenant-id-fallback-prod | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-api | OK |
| org.opencontainers.image.title | keybuzz-api | OK |

KEY-309 tag immutable + suffixe `-prod` conforme.

## E6 VERIFICATION PATCH DANS DIST

Audit `/app/dist/modules/auth/tenant-context-routes.js` dans l image construite.

| Pattern | Resultat | Verdict |
|---|---|---|
| Commentaires `PH-SAAS-T8.12AS.20.5` | 2 occurrences | OK |
| Fallback `\|\| 'tenant'` (slug) | 1 occurrence | OK |
| Fallback `\|\| \`tenant-` (autre route hors scope existant) | 1 occurrence | OK preexistant |
| Regex `[a-zA-Z0-9][a-zA-Z0-9_-]{2,49}` (defense) | 2 occurrences | OK (1 tenantSlug regex + 1 defense check) |
| Log `Generated tenantId rejected by regex` | 1 occurrence | OK |

Patch compile et inline dans le bundle JS. Aucun fallback de slug manquant ni regex check absent.

## E7 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## E8 WORKTREE CLEANUP

| Action | Resultat |
|---|---|
| `git worktree remove --force /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5-PROD/keybuzz-api` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.5-PROD/` | OK |
| Worktree present apres cleanup ? | NON |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible reste LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit 6850427c (PH-20.5 source).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN Stripe API call (build server-side, pas d outbound Stripe pendant build).
- AUCUN evenement marketing envoye.
- AUCUN ticket Linear modifie statut.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build de container Docker uniquement.
- Aucun event Lead/Purchase/StartTrial/CompletePayment fabrique.
- Aucun pixel Meta/TikTok/LinkedIn touche.
- Aucun checkout Stripe PROD test.
- Aucune mutation DB.
- Aucun changement contract billing trial/plan/price.
- Aucun tracking GA4/CAPI modifie.

## ROLLBACK PLAN (anticipation phase suivante PUSH IMAGE PROD)

Si push image + apply PROD provoquent regression :

1. Rollback tag PROD runtime actuel : `v3.5.250-ad-spend-sync-all-prod` (digest GHCR a verifier en phase apply).
2. Rollback procedure : editer `k8s/keybuzz-api-prod/deployment.yaml` -> revenir image v3.5.250-ad-spend-sync-all-prod + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

Suppression image GHCR push (cas extreme) :

- Suppression via GitHub Packages UI manuelle.

## GAPS

1. Aucun. Build clean, image valide, OCI labels conformes, patched code present.
2. Note : la branche `existingPending` reste non patchee dans le code (decision PH-20.5 scope). Si user a tenant orphan deja en DB avec id malforme, le nouveau register reuse cet id orphan. Mitigation = cleanup PH-20.7 separe (avec GO Ludovic + confirmation Antoine).
3. Note technique : l autre `|| \`tenant-${Date.now()}\`` (l.323) est dans une autre fonction du fichier (hors scope create-signup). Preexistant, non touche.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD API BILLING TENANT_ID FALLBACK PROD READY PH-SAAS-T8.12AS.20.5 |
| Bastion | install-v3 46.62.171.61 |
| Source commit API | 6850427c |
| Tag image cible | v3.5.251-billing-tenant-id-fallback-prod |
| Image ID local | sha256:867ecc25a0bbf00430a0f24388625de0ef7aaf0b7f7a481afeaba13bb1603042 |
| Image size | 343 MB |
| OCI labels KEY-308 | 5/5 OK |
| Patched code dist/ | present (commentaires + fallback + regex defense + log) |
| GHCR collision tag PROD cible | LIBRE (manifest unknown) |
| Worktree | nettoyee |
| Runtime API DEV | v3.5.252-billing-tenant-id-fallback-dev INCHANGE |
| Runtime API PROD | v3.5.250-ad-spend-sync-all-prod INCHANGE |
| Runtime Client/Website/Admin DEV+PROD | INCHANGES |
| Mutations | AUCUNE |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE API BILLING TENANT_ID FALLBACK PROD PH-SAAS-T8.12AS.20.5`

STOP.
