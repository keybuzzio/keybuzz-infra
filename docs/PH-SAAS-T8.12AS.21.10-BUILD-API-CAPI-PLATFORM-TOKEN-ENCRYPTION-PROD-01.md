# PH-SAAS-T8.12AS.21.10 - BUILD API CAPI PLATFORM TOKEN ENCRYPTION PROD

Date UTC : 2026-05-29
Projet : KeyBuzz SaaS
Service : keybuzz-api
Environnement : PROD build only
Type : build Docker local depuis Git
Verdict : GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION PROD READY PH-SAAS-T8.12AS.21.10

## Resume

Image API PROD construite localement depuis Git propre `9797bedf`.

Image cible :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod`

Image locale creee :

`sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45`

Le build est local uniquement. Aucun `docker push`, aucun deploy, aucun `kubectl`, aucune DB mutation, aucun backfill PROD, aucun event tracking et aucune mutation Linear n'ont ete executes.

## Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.10_CODEX_EXECUTOR_MISSION.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.09_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.08_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.07_CE_RETURN.md` | lu |
| `C:\DEV\KeyBuzz\tmp\PH-21.05_CE_RETURN.md` | lu |
| `AI_MEMORY/CURRENT_STATE.md` | lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | lu via contexte precedent |
| rapports PH-21.05 / PH-21.07 / PH-21.08 / PH-21.09 | relus via retours et docs infra |

## Preflight bastion

| Controle | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Host SSH | `install-v3` | `install-v3` | OK |
| IPv4 | `46.62.171.61` | `46.62.171.61` | OK |
| IP interdite | `51.159.99.247` absente | absente | OK |
| Date UTC preflight | informatif | `2026-05-29T14:54:16Z` | OK |

## Preflight repos

| Repo | Branche | HEAD local | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| `/opt/keybuzz/keybuzz-api` | `ph147.4/source-of-truth` | `9797bedf` | `9797bedf` | `0/0` | 0 hors `dist` | OK |
| `/opt/keybuzz/keybuzz-infra` | `main` | `4674d0e` | `4674d0e` | `0/0` | 0 | OK |

## Runtime baseline

PH-21.10 interdit `kubectl`. Aucune commande Kubernetes n'a donc ete executee pendant cette phase. La baseline runtime est reprise des derniers rapports read-only et des manifests GitOps inchanges.

| Env | Source de verification | Image actuelle | Restarts | Verdict |
| --- | --- | --- | --- | --- |
| DEV | PH-21.09 + manifest GitOps inchange | `v3.5.261-capi-platform-token-encryption-dev` | `0` dans PH-21.09 | inchangee |
| PROD | PH-21.09 + manifest GitOps inchange | `v3.5.260-amazon-inbound-address-sync-prod` | `0` dans PH-21.09 | inchangee |

Manifests observes inchanges :

| Manifest | Image |
| --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| `k8s/keybuzz-api-prod/deployment.yaml` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod` |

## Source propre

Source temporaire :

`/tmp/keybuzz-api-ph2110-prod-20260529T151020Z-9797bedf`

| Check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| HEAD full | `9797bedf1c16ed45467874abb195a87e979be47a` | `9797bedf1c16ed45467874abb195a87e979be47a` | OK |
| `git status --porcelain` avant `node_modules` | 0 | 0 | OK |
| `git status` hors symlink `node_modules` | 0 | 0 | OK |
| `package.json` build | `tsc -p tsconfig.build.json` | `tsc -p tsconfig.build.json` | OK |
| `tsconfig.build.json` | exclut tests | `src/tests/**/*`, `src/**/__tests__/**/*`, `*.test.ts`, `*.spec.ts` exclus | OK |
| Dockerfile | copie `tsconfig.build.json` | `COPY tsconfig.json tsconfig.build.json ./` | OK |
| `.dockerignore` | exclut `node_modules` | `node_modules` exclu | OK |

Le symlink `node_modules` a ete utilise uniquement dans la source temporaire pour compiler/tester sans mutation de la source API. Il est exclu du contexte Docker par `.dockerignore`.

## Tests pre-build

| Test/check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.02 standalone | 13/13 PASS | 13/13 PASS | OK |
| `tsc --noEmit` | PASS | PASS | OK |
| `npm run build` | PASS | PASS | OK |
| Clean outDir | `tests` absent | absent | OK |
| Clean outDir fake tokens/fake key | absent | absent | OK |

Marqueurs verifies dans clean outDir :

| Marker | Resultat |
| --- | --- |
| `platform-token-crypto` | PRESENT |
| `encryptOutboundPlatformTokenForStorage` | PRESENT |
| `decryptOutboundPlatformTokenForProvider` | PRESENT |
| `prepareOutboundPlatformTokenUpdate` | PRESENT |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | PRESENT |
| `aes256gcm` | PRESENT |
| `ADS_ENCRYPTION_KEY` | PRESENT, nom seulement |
| `redactSecrets` | PRESENT |

## Build image locale PROD

Commande logique executee :

```bash
docker build \
  --build-arg IMAGE_REVISION=9797bedf1c16ed45467874abb195a87e979be47a \
  --build-arg IMAGE_CREATED=2026-05-29T15:10:58Z \
  --build-arg IMAGE_VERSION=v3.5.261-capi-platform-token-encryption-prod \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod .
```

Log build :

`/tmp/ph2110-docker-build-20260529T151020Z.log`

| Image | Tag | Image ID | Revision label | Created label | RepoDigests | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | `v3.5.261-capi-platform-token-encryption-prod` | `sha256:20e857ec5815ebbd8d08392d09f72d22e25ccc078cf32d4eabadabc418e9ba45` | `9797bedf1c16ed45467874abb195a87e979be47a` | `2026-05-29T15:10:58Z` | `[]` | OK |

RepoTags local :

`["ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-prod"]`

## Audit image

| Marker/check | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| `/app/dist/server.js` | present | present | OK |
| `/app/dist/tests` | absent | absent | OK |
| fake tokens PH-21.02 | absent | absent | OK |
| fake encryption key PH-21.02 | absent | absent | OK |
| `latest` dans runtime outbound/server | absent | absent | OK |
| `platform-token-crypto` | present | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present | OK |
| `aes256gcm` | present | present | OK |
| `ADS_ENCRYPTION_KEY` | nom present, valeur non affichee | present | OK |
| `redactSecrets` | present | present | OK |
| OCI revision label | full SHA source | OK | OK |
| OCI version label | tag cible | OK | OK |
| OCI created label | UTC build | OK | OK |
| RepoDigests local | vide | `[]` | OK |

## GHCR / push

| Controle | Resultat | Verdict |
| --- | --- | --- |
| Tag cible GHCR avant build | absent, `manifest unknown` | OK |
| Tag cible GHCR apres build | absent | OK |
| Collision tag remote | aucune | OK |
| Docker push | non execute | OK |
| Pull-back digest | non applicable, aucun push | OK |

## No side effect

| Interdit / controle | Resultat |
| --- | --- |
| Docker push | non execute |
| Deploy | non execute |
| `kubectl` | non execute |
| SQL mutation | non execute |
| DB/backfill PROD | non execute |
| Event tracking / test endpoint CAPI | non execute |
| Rotation token | non execute |
| Secret/env value dans logs/rapport | aucun affiche |
| `/opt/keybuzz/credentials` | non touche |
| `/opt/keybuzz/secrets` | non touche |
| Push Git API | non execute |
| Source API | inchangee |
| Manifests GitOps | inchanges |
| Runtime DEV/PROD | aucune action de modification |
| `latest` | non utilise, non tagge |
| Linear | aucune mutation |

## Artefacts

| Artefact | Chemin |
| --- | --- |
| Source temporaire | `/tmp/keybuzz-api-ph2110-prod-20260529T151020Z-9797bedf` |
| Test output | `/tmp/keybuzz-api-ph2110-tests-20260529T151020Z` |
| Clean outDir | `/tmp/keybuzz-api-ph2110-clean-outdir-20260529T151020Z` |
| Build log | `/tmp/ph2110-docker-build-20260529T151020Z.log` |
| Script mission | `/tmp/ph2110_execute.sh` |

## Rollback

Aucun rollback runtime n'est necessaire : aucune image n'a ete poussee et aucun manifest/runtime n'a ete modifie.

Si une phase future poussait ou deployait cette image et devait revenir en arriere, le rollback documente reste GitOps strict vers l'image PROD actuelle :

`ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod`

## Verdict

GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION PROD READY PH-SAAS-T8.12AS.21.10

STOP.
