# PH-SAAS-T8.12AS.21.223 - Admin tenants column filters PROD

## Verdict

READY.

Promotion PROD terminee pour les filtres et tris de colonnes de la page Admin `/tenants`.

## Scope

- Service: keybuzz-admin-v2 PROD.
- Page: `/tenants`.
- Changement utilisateur: tri par clic sur titres de colonnes, filtres par colonne, compteur visible/total, reset des filtres.
- Hors scope: API, Client, Website, Backend, DB, tracking, billing, impersonation logic.

## Source

| Repo | Branch | Commit | Dirty |
| --- | --- | --- | --- |
| keybuzz-admin-v2 | main | af5eaaaf1d87de2c42839db7afe98e204be724f1 | 0 |
| keybuzz-infra | main | 1aaa4e8f3cd2 | 0 |

## Image PROD

| Field | Value |
| --- | --- |
| Tag | ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-prod |
| RepoDigest | ghcr.io/keybuzzio/keybuzz-admin@sha256:67935abe5df86e3215c48a98eb66ec9239fad7af2edc6a1e1b6ff781626fbdec |
| Image ID | sha256:089f887ceee6418fedda4c724b0c357e6e0073178b3fd20fb8bb78afd66be99a |
| OCI revision | af5eaaaf1d87de2c42839db7afe98e204be724f1 |
| latest | Not touched |

## GitOps

| File | Change |
| --- | --- |
| k8s/keybuzz-admin-v2-prod/deployment.yaml | image only, v2.12.3-support-impersonation-prod -> v2.12.4-tenant-column-filters-prod |

GitOps commit pushed before apply:

- 1aaa4e8f3cd2 deploy(admin-prod): apply tenant column filters

Apply method:

- `kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml`
- No `kubectl set image`, no `kubectl set env`, no `kubectl patch`, no `kubectl edit`.

Rollback image:

- ghcr.io/keybuzzio/keybuzz-admin:v2.12.3-support-impersonation-prod

## Runtime PROD

| Check | Result |
| --- | --- |
| Deployment image | ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-prod |
| Runtime digest | sha256:67935abe5df86e3215c48a98eb66ec9239fad7af2edc6a1e1b6ff781626fbdec |
| Ready | 1/1 |
| Generation | 104/104 |
| Available | True |
| Pod | keybuzz-admin-v2-79ff4b4f5c-fnrpj |
| Restarts | 0 |
| last-applied tag | OK |

Note: the first verification script selected the old ReplicaSet pod during termination and stopped on digest mismatch. A second read-only verification targeted the Running pod and passed. Rollout itself was successful.

## Tests

| Test | Expected | Result |
| --- | --- | --- |
| Docker pull-back | RepoDigest matches | PASS |
| Image source revision | af5eaaaf... | PASS |
| Image markers | SortHeader / visibleTenants / columnFilters / empty filtered state | PASS |
| kubectl dry-run client | valid manifest | PASS |
| kubectl dry-run server | valid manifest | PASS |
| rollout status | successful | PASS |
| HTTPS `/login` | 200 | PASS |
| HTTPS `/tenants` unauth | redirect/auth safe | 307 PASS |

## Non-regression read-only

| Service | Runtime |
| --- | --- |
| Admin DEV | ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-dev, Ready 1/1, generation 126/126 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod, Ready 1/1, generation 438/438 |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod, Ready 1/1, generation 439/439 |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-prod, Ready 2/2, generation 39/39 |

## No side-effect

- 0 DB mutation.
- 0 fake event.
- 0 checkout.
- 0 secret displayed.
- 0 Client/API/Website/Backend mutation.
- No `latest` retag.

## Final state

Admin tenants column filters are live in PROD and DEV.

STOP.
