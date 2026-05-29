# PH-SAAS-T8.12AS.21.05 - BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV

Date UTC: 2026-05-29
Projet: KeyBuzz SaaS / API / Tracking server-side / Securite
Environnement: DEV build only
Scope: build Docker local depuis Git, aucun push image, aucun deploy, aucune DB/backfill.

## Verdict

`GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV READY PH-SAAS-T8.12AS.21.05`

Image API DEV reconstruite localement depuis Git propre `9797bedf`.

Le patch PH-21.02 est present dans l'image et le blocage PH-21.03 est ferme: `/app/dist/tests` est absent de l'image runtime, les fake tokens/fake key de test sont absents, et aucun RepoDigest n'existe car l'image n'a pas ete poussee.

## Sources relues

| source | statut |
|---|---|
| `C:\DEV\KeyBuzz\tmp\PH-21.05_CODEX_EXECUTOR_MISSION.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.03_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.04_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.04_PUSH_CE_RETURN.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| rapports PH-21.02 / PH-21.03 / PH-21.04 locaux | relus |

## Preflight

| point | resultat | verdict |
|---|---|---|
| bastion | `install-v3` | OK |
| IPv4 obligatoire | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| date UTC | `2026-05-29T12:12:48Z` | OK |

| repo | branche | HEAD local | origin | ahead/behind | dirty | verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `9797bedf` | `9797bedf` | `0/0` | 223 suppressions `dist/`, 0 hors `dist/` | OK |
| keybuzz-infra | `main` | `6a929ba` | `6a929ba` | `0/0` | 0 | OK |

Runtime:

- Aucun `kubectl` execute, car la mission PH-21.05 interdit explicitement `kubectl`.
- Aucun deploy ni mutation runtime n'a ete effectue.
- Baseline attendue conservee par absence d'action runtime: DEV `v3.5.260-amazon-inbound-address-sync-dev`, PROD `v3.5.260-amazon-inbound-address-sync-prod`.

## Source propre

| check | attendu | resultat |
|---|---|---|
| source temporaire | checkout propre hors workspace dirty | `/tmp/keybuzz-api-ph2105-9797bedf-20260529T1219Z` |
| full SHA | `9797bedf...` | `9797bedf1c16ed45467874abb195a87e979be47a` |
| short SHA | `9797bedf` | OK |
| `git status --porcelain` | 0 | 0 |
| `package.json` build | `tsc -p tsconfig.build.json` | OK |
| `tsconfig.build.json` | present | OK |
| test exclusions | `src/tests`, `__tests__`, `*.test.ts`, `*.spec.ts` | OK |

Note: le repo API principal reste dirty uniquement a cause de suppressions `dist/` preexistantes, non utilise pour build.

## Tests pre-build

| test/check | attendu | resultat |
|---|---|---|
| PH-21.02 standalone | 13/13 PASS | PASS |
| `tsc --noEmit` | PASS | PASS |
| `npm run build` | PASS | PASS |
| outDir propre avec `tsc -p tsconfig.build.json --outDir /tmp/ph2105-runtime-outdir-...` | PASS | PASS |
| outDir propre `tests` | absent | absent |
| outDir propre fake tokens/fake key | 0 | 0 |

Standalone result:

```text
=== ALL PH-21.02 OUTBOUND PLATFORM TOKEN TESTS PASSED (13/13) ===
```

Nuance source:

- Le checkout Git contient des fichiers `dist/tests` historiques suivis par Git.
- `npm run build` ne supprime pas ces fichiers dans le workspace source.
- La verification decisive a donc ete faite avec un `outDir` propre et dans l'image Docker runtime, dont le stage builder part de `/app` vide et copie seulement `src`.

## Build image DEV locale

| image | tag | image ID | revision label | created | RepoDigests | verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` | `9797bedf1c16ed45467874abb195a87e979be47a` | `2026-05-29T12:14:53Z` | `[]` | OK |

Build command:

```text
docker build \
  --build-arg IMAGE_REVISION=9797bedf1c16ed45467874abb195a87e979be47a \
  --build-arg IMAGE_CREATED=2026-05-29T12:14:53Z \
  --build-arg IMAGE_VERSION=v3.5.261-capi-platform-token-encryption-dev \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev .
```

Resultat:

```text
Successfully built 484617bb49ef
Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev
```

Aucun `docker push`.

## Audit image

| marker/check | attendu | resultat |
|---|---|---|
| `/app/dist/server.js` | present | present |
| `/app/dist/tests` | absent | absent |
| fake tokens PH-21.02 | absent | 0 |
| fake key PH-21.02 | absent | 0 |
| `meta_test_token` | absent | 0 |
| `tiktok_test_token` | absent | 0 |
| `linkedin_test_token` | absent | 0 |
| `latest` dans runtime outbound/server | absent | 0 |
| `platform-token-crypto` | present | present |
| `encryptOutboundPlatformTokenForStorage` | present | present |
| `decryptOutboundPlatformTokenForProvider` | present | present |
| `prepareOutboundPlatformTokenUpdate` | present | present |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present |
| `aes256gcm` | present | present |
| `ADS_ENCRYPTION_KEY` reference | present, valeur non affichee | present |
| `platform_token_ref` | present | present |
| `redactSecrets` | present | present |

## GHCR / manifests / no side effect

| controle | resultat | verdict |
|---|---|---|
| GHCR target tag avant build | `manifest unknown` | absent |
| GHCR target tag apres build | `manifest unknown` | absent |
| local image RepoDigests | `[]` | non poussee |
| manifest infra reference tag cible | seulement rapport PH-21.03, aucun manifest | OK |
| docker push | non execute | OK |
| deploy/kubectl | non execute | OK |
| DB/backfill/event | non execute | OK |
| latest | non touche | OK |
| source API | non modifiee | OK |

## No side-effect

| interdit | resultat |
|---|---|
| modification source | non |
| commit source | non |
| push Git API | non |
| docker push | non |
| deploy | non |
| kubectl | non |
| SQL mutation | non |
| DB/backfill | non |
| rotation token | non |
| event tracking / test endpoint CAPI | non |
| Linear mutation | non |
| secrets/credentials paths | non touches |

## Livrables

| livrable | chemin / valeur |
|---|---|
| rapport infra | `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.05-BUILD-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` |
| copie locale rapport | `C:\DEV\KeyBuzz\tmp\PH-SAAS-T8.12AS.21.05-BUILD-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` |
| image locale | `ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev` |
| image ID | `sha256:484617bb49efd43365da68346f93f3bcd21524738d7f0e873c7bb78fb0128d1b` |

## Prochaine phase recommandee

1. Si Ludovic valide, push docs-only du rapport PH-21.05 si pas deja pousse.
2. Phase separee de deploy DEV GitOps depuis l'image construite, uniquement apres decision explicite.
3. Backfill DEV des tokens legacy plaintext dans une phase dediee, apres runtime DEV valide.

Phrase finale:

`GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV READY PH-SAAS-T8.12AS.21.05`
