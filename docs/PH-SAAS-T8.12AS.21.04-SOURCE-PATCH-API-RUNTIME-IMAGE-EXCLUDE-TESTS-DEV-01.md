# PH-SAAS-T8.12AS.21.04 - SOURCE PATCH API RUNTIME IMAGE EXCLUDE TESTS DEV

Date UTC: 2026-05-29
Projet: KeyBuzz SaaS / API / Build hygiene / Securite
Environnement: SOURCE DEV first
Scope: patch source/build config API, commits locaux uniquement, aucun push/deploy/DB.

## 1. Verdict

`GO SOURCE PATCH API RUNTIME IMAGE EXCLUDE TESTS DEV READY PH-SAAS-T8.12AS.21.04`

Le blocage PH-21.03 est corrige en source.

Le build runtime API utilise maintenant `tsconfig.build.json`, qui exclut les tests de la sortie runtime. Le Dockerfile copie ce fichier avant `npm run build`.

Image smoke locale non poussee validee: `/app/dist/tests` absent, fake tokens de test absents, marqueurs PH-21.02 presents.

## 2. Resume

- Commit API local: `9797bedf fix(build): exclude tests from API runtime image (PH-21.04)`.
- Fichiers API modifies: `Dockerfile`, `package.json`, `tsconfig.build.json`.
- Tests PH-21.02 standalone: 13/13 PASS.
- Typecheck complet: `tsc --noEmit` PASS.
- Build runtime equivalent: PASS, `tests` absent dans la sortie.
- Smoke image locale: `ghcr.io/keybuzzio/keybuzz-api:ph21.04-local-smoke-no-push`.
- Aucun push Git, aucun docker push, aucun deploy, aucune DB/backfill/event.
- Runtime DEV/PROD inchange.

## 3. Sources relues

| source | statut |
|---|---|
| `C:\DEV\KeyBuzz\tmp\PH-21.04_CODEX_EXECUTOR_MISSION.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.02_PUSH_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-21.03_CE_RETURN.md` | relu |
| `C:\DEV\KeyBuzz\tmp\PH-SAAS-T8.12AS.21.03-BUILD-API-CAPI-PLATFORM-TOKEN-ENCRYPTION-DEV-01.md` | relu |
| `AI_MEMORY/CURRENT_STATE.md` | relu |
| `AI_MEMORY/RULES_AND_RISKS.md` | relu |
| `AI_MEMORY/CE_FILE_HANDOFF_PROTOCOL.md` | relu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | relu |
| `AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md` | relu |

## 4. Preflight

| point | resultat | verdict |
|---|---|---|
| bastion | `install-v3` | OK |
| IP publique obligatoire | `46.62.171.61` | OK |
| IP interdite `51.159.99.247` | non observee | OK |
| date UTC | `2026-05-29T11:00:56Z` | OK |

| repo | branche | HEAD local depart | origin depart | ahead/behind depart | dirty depart | verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | `ph147.4/source-of-truth` | `0d86d294` | `0d86d294` | `0/0` | 223 suppressions `dist/`, 0 hors `dist/` | OK, dirty connu hors scope |
| keybuzz-infra | `main` | `00b0500` | `00b0500` | `0/0` | 0 | OK |

| env | service | image actuelle | restarts | verdict |
|---|---|---|---|---|
| DEV | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-dev` | 0 | inchange |
| PROD | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.5.260-amazon-inbound-address-sync-prod` | 0 | inchange |

## 5. Cause racine `dist/tests`

| fichier | observation | impact |
|---|---|---|
| `package.json` | `build` appelait `tsc` sans projet build dedie | compile tout ce que `tsconfig.json` inclut |
| `tsconfig.json` | `include` = `src/**/*`; `exclude` ne retirait pas `src/tests` | `src/tests` produit `dist/tests` |
| `Dockerfile` | copie `/app/dist` complet dans le runtime | `dist/tests` embarque dans image |
| `.dockerignore` | exclut `node_modules`, `.git`, logs, env, md; pas la cause | pas bloquant |
| `src/tests` | 37 fichiers de tests source conserves | doivent rester executables explicitement |

PH-21.03 a prouve que l'image locale contenait `/app/dist/tests/ph21_02-outbound-platform-token-crypto-tests.js`, avec fake tokens/fake key de test.

## 6. Design retenu

| option | retenue | raison | risque |
|---|---|---|---|
| `tsconfig.build.json` dedie au runtime | oui | solution minimale, durable, conserve les tests source | faible |
| suppression `dist/tests` dans Dockerfile | non | masque le symptome apres compilation | risque de stale output |
| suppression/deplacement tests source | non | contraire au scope, perd la capacite de test | non acceptable |

Decision:

- garder `tsconfig.json` comme config globale/typecheck;
- ajouter `tsconfig.build.json` pour le runtime;
- faire pointer `npm run build` vers `tsc -p tsconfig.build.json`;
- copier `tsconfig.build.json` dans le stage Docker builder.

## 7. Patch exact

| fichier | changement | raison | risque |
|---|---|---|---|
| `package.json` | `build` passe de `tsc` a `tsc -p tsconfig.build.json` | build runtime exclut les tests | faible |
| `tsconfig.build.json` | nouveau fichier, etend `tsconfig.json`, exclut tests/specs | separer runtime build et tests source | faible |
| `Dockerfile` | copie `tsconfig.json tsconfig.build.json` avant `npm run build` | Docker build reste reproductible | faible |

Fichiers business outbound conversions non modifies.
Tests source non supprimes.
`package-lock.json` non modifie.

## 8. Tests et verifications

| test/check | attendu | resultat |
|---|---|---|
| PH-21.02 standalone | 13/13 PASS | PASS |
| `tsc --noEmit` | PASS | PASS |
| build runtime equivalent `tsc -p tsconfig.build.json --outDir /tmp/ph2104-runtime-build...` | PASS | PASS |
| sortie runtime `tests` | absent | absent |
| fichiers tests runtime | 0 | 0 |
| fake tokens/fake key PH-21.02 dans sortie runtime | 0 | 0 |
| `platform-token-crypto` | present | present |
| `encryptOutboundPlatformTokenForStorage` | present | present |
| `decryptOutboundPlatformTokenForProvider` | present | present |
| `prepareOutboundPlatformTokenUpdate` | present | present |
| `OUTBOUND_PLATFORM_TOKEN_MASK` | present | present |
| `aes256gcm` | present | present |
| `ADS_ENCRYPTION_KEY` reference | present, valeur non affichee | present |
| `platform_token_ref` | present | present |
| `redactSecrets` | present | present |

Standalone result:

```text
=== ALL PH-21.02 OUTBOUND PLATFORM TOKEN TESTS PASSED (13/13) ===
```

## 9. Optional image smoke local

Effectue pour prouver que le Dockerfile runtime ne copie plus de tests.

| controle | resultat |
|---|---|
| source smoke | `/tmp/keybuzz-api-ph2104-smoke-9797bedf-20260529T1115Z` |
| source smoke HEAD | `9797bedf` |
| source smoke dirty | 0 |
| image smoke | `ghcr.io/keybuzzio/keybuzz-api:ph21.04-local-smoke-no-push` |
| image ID | `sha256:cf2addb92c67602c78d6e32e4fb3e72d1b8140055210d49d262ad82579e3e050` |
| revision label | `9797bedf1c16ed45467874abb195a87e979be47a` |
| created label | `2026-05-29T11:04:25Z` |
| version label | `ph21.04-local-smoke-no-push` |
| RepoDigests | `[]` |
| docker push | non |

Audit image:

| check | attendu | resultat |
|---|---|---|
| `/app/dist/tests` | absent | absent |
| fake tokens/fake key de test dans `/app/dist` | 0 | 0 |
| outbound runtime files | presents | presents |
| marqueurs PH-21.02 | presents | presents |

Le tag smoke est local uniquement et ne doit pas etre deploye.

## 10. No side-effect

| interdit | resultat |
|---|---|
| push Git API | non |
| push Git infra | non |
| docker push | non |
| deploy | non |
| `kubectl apply/set/patch/edit/env` | non |
| SQL mutation | non |
| DB/backfill | non |
| rotation token | non |
| event tracking/provider endpoint | non |
| Linear mutation | non |
| manifests K8s modifies | non |
| Admin/Client/Website/Backend modifies | non |
| secrets/credentials paths | non touches |

`kubectl get` read-only a ete utilise uniquement pour verifier les images runtime.

## 11. Commits locaux

| repo | commit local | ahead | dirty residuel | push |
|---|---|---|---|---|
| keybuzz-api | `9797bedf fix(build): exclude tests from API runtime image (PH-21.04)` | 1 | 223 suppressions `dist/` preexistantes, 0 hors `dist/` | non |
| keybuzz-infra | rapport PH-21.04 docs-only | 1 apres commit rapport | 0 attendu | non |

API commit files:

```text
Dockerfile
package.json
tsconfig.build.json
```

## 12. Prochaine phase recommandee

1. Push separe du commit API `9797bedf` et du rapport infra PH-21.04, si Ludovic valide.
2. Rebuild API DEV depuis Git pousse avec tag immuable dedie.
3. Re-audit image cible DEV: `/app/dist/tests` absent, fake tokens absents, marqueurs PH-21.02 presents.
4. Ensuite seulement deploy DEV GitOps sous GO separe.
5. Backfill DEV des tokens legacy plaintext seulement dans une phase separee.

Phrase finale:

`GO SOURCE PATCH API RUNTIME IMAGE EXCLUDE TESTS DEV READY PH-SAAS-T8.12AS.21.04`
