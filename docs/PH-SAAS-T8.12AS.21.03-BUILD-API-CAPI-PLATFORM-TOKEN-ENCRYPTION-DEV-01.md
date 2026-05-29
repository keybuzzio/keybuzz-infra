# PH-SAAS-T8.12AS.21.03 - BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV

Date UTC: 2026-05-29
Projet: KeyBuzz SaaS / API / Tracking server-side / Securite
Environnement: DEV build only
Scope: build Docker local depuis Git, aucun push image, aucun deploy, aucune DB/backfill.

## Verdict

`GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV NO_GO PH-SAAS-T8.12AS.21.03`

Image locale construite avec succes, mais non qualifiee READY.
Cause: l'image runtime contient `dist/tests`, dont le test PH-21.02 avec des tokens de test/fake key de test compiles dans `dist`.

Decision: ne pas pousser, ne pas deployer, ne pas utiliser cette image pour DEV runtime tant qu'une phase source separee n'exclut pas les tests du runtime image/dist.

## Sources relues

| source | statut |
|---|---|
| `C:\DEV\KeyBuzz\tmp\PH-21.03_CODEX_EXECUTOR_MISSION.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_PUSH_CE_RETURN.md` | relu |
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | relu |

## Preflight bastion

| point | resultat | verdict |
|---|---|---|
| bastion | `install-v3` | OK |
| SSH hostname | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| date UTC | `2026-05-29T10:30:41Z` | OK |

## Preflight repos

| repo | branche | HEAD local | origin | ahead/behind | dirty | verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `0d86d294` | `0d86d294` | `0/0` | 223 suppressions `dist/`, 0 hors `dist/` | OK, non build depuis ce workspace |
| keybuzz-infra | `main` | `33b3f10` | `33b3f10` | `0/0` | 0 | OK |

## Runtime read-only

| env | service | image actuelle | pod | restarts | verdict |
|---|---|---|---|---|---|
| DEV | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev` | `keybuzz-api-59b88c85fb-mlvhc` | 0 | inchange |
| PROD | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod` | `keybuzz-api-cf778495d-pfmls` | 0 | inchange |

Note: verification runtime effectuee en lecture seule uniquement. Aucun `kubectl apply/set/patch/edit/env`.

## Source propre de build

| check | attendu | resultat |
|---|---|---|
| chemin source temporaire | checkout propre hors workspace dirty | `/tmp/keybuzz-api-ph2103-0d86d294-20260529T1037Z` |
| commit complet | `0d86d294` | `0d86d2946bbd1b91c5c4394f4e0017625832d6fc` |
| `git status --porcelain` | 0 | 0 |
| `package.json` | present | present |
| `package-lock.json` | present | present |
| `Dockerfile` | present | present |
| build source | Git propre | OK |

Dockerfile identifie:

- multi-stage `node:lts` builder puis `node:lts-alpine` runner;
- `npm ci`;
- `COPY src ./src`;
- `npm run build`;
- `COPY --from=builder /app/dist ./dist`;
- labels OCI `org.opencontainers.image.revision`, `created`, `version`.

## Checks source PH-21.02

| check | attendu | resultat |
|---|---|---|
| `platform-token-crypto` | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | OK |
| `aes256gcm` | present | OK |
| `ADS_ENCRYPTION_KEY` reference | present, valeur non affichee | OK |
| `redactSecrets` | present | OK |
| manifests modifies | non | OK |
| source hardcode tenant dans outbound-conversions | absent | OK |

## Tests pre-build

| test | attendu | resultat |
|---|---|---|
| standalone PH-21.02 | 13/13 PASS | PASS |
| `tsc --noEmit` | PASS | PASS |
| `npm test` | script absent | non execute |

Commande standalone:

```text
./node_modules/.bin/tsc --target ES2022 --module commonjs --esModuleInterop --skipLibCheck --types node --rootDir src --outDir /tmp/ph2103-test-build src/tests/ph21_02-outbound-platform-token-crypto-tests.ts
node /tmp/ph2103-test-build/tests/ph21_02-outbound-platform-token-crypto-tests.js
./node_modules/.bin/tsc --noEmit
```

Resultat:

```text
=== ALL PH-21.02 OUTBOUND PLATFORM TOKEN TESTS PASSED (13/13) ===
```

## Build image locale

| image | tag | image ID | revision label | created | verdict |
|---|---|---|---|---|---|
| keybuzz-api | `v3.5.261-capi-platform-token-encryption-dev` | `sha256:05bbea2914ab4ad2162120049588a9d9f10440fcc2f12f60460a5fb99aff61c3` | `0d86d2946bbd1b91c5c4394f4e0017625832d6fc` | `2026-05-29T10:33:14Z` | built local |

Build command:

```text
docker build \
  --build-arg IMAGE_REVISION=0d86d2946bbd1b91c5c4394f4e0017625832d6fc \
  --build-arg IMAGE_CREATED=2026-05-29T10:33:14Z \
  --build-arg IMAGE_VERSION=v3.5.261-capi-platform-token-encryption-dev \
  -t ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev .
```

Build result:

- `Successfully built 05bbea2914ab`;
- `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.261-capi-platform-token-encryption-dev`;
- no `docker push`.

Build warning observed:

- `npm prune --omit=dev` reported existing npm audit output: 14 vulnerabilities (1 low, 5 moderate, 8 high).
- This phase did not change dependencies.

## Image / dist audit

| marker | attendu | resultat |
|---|---|---|
| `platform-token-crypto` | present | OK |
| `encryptOutboundPlatformTokenForStorage` | present | OK |
| `decryptOutboundPlatformTokenForProvider` | present | OK |
| `prepareOutboundPlatformTokenUpdate` | present | OK |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | OK |
| `aes256gcm` | present | OK |
| `ADS_ENCRYPTION_KEY` reference | present, valeur non affichee | OK |
| `platform_token_ref` response masking | present | OK |
| routes create/update encrypt | present | OK |
| test endpoint decrypts provider token | present | OK |
| emitter decrypts Meta | present | OK |
| emitter decrypts TikTok | present | OK |
| emitter decrypts LinkedIn | present | OK |
| `redactSecrets` | present | OK |

Evidence files:

```text
/app/dist/modules/outbound-conversions/platform-token-crypto.js
/app/dist/modules/outbound-conversions/routes.js
/app/dist/modules/outbound-conversions/emitter.js
/app/dist/modules/outbound-conversions/redact-secrets.js
```

## Image / dist absence checks

| controle | attendu | resultat | verdict |
|---|---|---|---|
| raw PH-21.02 test token/fake key patterns in dist | absent | present in `/app/dist/tests/ph21_02-outbound-platform-token-crypto-tests.js` | FAIL |
| tenant-specific hardcode patterns in outbound runtime modules | absent | absent in `/app/dist/modules/outbound-conversions` | OK |
| tenant-specific hardcode patterns in dist tests | absent | present in `/app/dist/tests/ph115-tests.js`, `ph116-tests.js`, `ph117-tests.js` | FAIL for runtime image hygiene |
| `latest` string in outbound modules/tests | absent | absent | OK |
| image tag `latest` | absent | absent |
| RepoDigests | none, because no push | OK |

Root cause probable:

- `tsconfig.json` includes `src/**/*`;
- Dockerfile builds full source with `npm run build`;
- Dockerfile copies the full `/app/dist` into the runtime stage;
- therefore `src/tests/*` becomes `/app/dist/tests/*` inside the image.

This is not a PH-21.02 encryption logic failure, but it blocks READY qualification for this build artifact.

## GHCR / manifests / runtime no side effect

| controle | resultat | verdict |
|---|---|---|
| local target image before build | absent | OK |
| GHCR manifest before build | `manifest unknown` | OK |
| GHCR manifest after build | `manifest unknown` | OK, not pushed |
| local image RepoTags after build | target tag only | OK |
| local image RepoDigests after build | `[]` | OK, not pushed |
| infra manifests reference target tag | no match | OK |
| DEV runtime image after build | still `v3.5.260-amazon-inbound-address-sync-dev` | OK |
| PROD runtime image after build | still `v3.5.260-amazon-inbound-address-sync-prod` | OK |
| `docker push` | not executed | OK |

## No side-effect

| interdit | resultat |
|---|---|
| source modification | non |
| source commit | non |
| source push | non |
| docker push | non |
| deploy | non |
| mutating kubectl | non |
| SQL mutation | non |
| DB/backfill | non |
| rotation token | non |
| event tracking/provider endpoint | non |
| Linear mutation | non |
| secrets/credentials paths | non touches |

## Gaps / next action

| gap | impact | suite recommandee |
|---|---|---|
| runtime image includes `dist/tests` | test token/fake key and tenant test patterns ship in image | phase source separee: exclude tests from runtime build/image |
| no image push | expected by scope | keep as-is |
| no deploy | expected by scope | keep as-is |
| legacy plaintext DB rows | still not backfilled | phase DEV backfill dediee apres image READY |

## Conclusion

Build local realise depuis Git propre `0d86d294`, image locale conservee, aucun push/deploy/DB/backfill.

Le build ne peut pas etre qualifie READY car l'audit impose "pas de token brut de test dans dist" et l'image contient `dist/tests`.

Phrase finale:

`GO BUILD API CAPI PLATFORM TOKEN ENCRYPTION DEV NO_GO PH-SAAS-T8.12AS.21.03`
