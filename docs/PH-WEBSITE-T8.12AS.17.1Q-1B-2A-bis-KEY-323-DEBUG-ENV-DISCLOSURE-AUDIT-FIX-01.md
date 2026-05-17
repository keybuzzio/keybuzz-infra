# PH-WEBSITE-T8.12AS.17.1Q-1B-2A-bis-KEY-323-DEBUG-ENV-DISCLOSURE-AUDIT-FIX-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-2A-bis debug-env disclosure audit/fix DEV+PROD
> Environnement : DEV + PROD Client keybuzz-client
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO DEBUG-ENV DEV+PROD FIXED.

Route `app/api/debug-env/route.ts` supprimee sur branche `ph148/onboarding-activation-replay` (commit `f61763a`). Bundle Client DEV+PROD verifies (api-dev correct DEV, api correct PROD, debug-env handler absent du compile). 2 images Docker buildees from Git + pushed GHCR avec OCI labels + manifests GitOps DEV+PROD updated + kubectl apply + rollout OK. Runtime = manifest = last-applied confirme sur DEV+PROD. HTTP probes /api/debug-env DEV+PROD retournent 307 middleware NextAuth (comportement identique pre-fix car middleware deja protegeait route - confirmation classification P3 disclosure auth-user uniquement, downgrade depuis P2 Q-1B-2A). Pods Client DEV+PROD Running 1/1 age 45s-2m34s, 0 restart, logs startup clean Next.js ready 467-478ms. Control negatif API/backend/ExternalSecrets : aucun impact cross-namespace, ages 22h unchanged, 30/30 ES True.

Phrase finale :
STOP AS.17.1Q-1B-2A-bis - GO DEBUG-ENV DEV+PROD FIXED. Rapport docs-only commit/push effectue si autorise. Q-1B-2B EXEC et PROD promotion AS.17.0/AS.17.0.1 restent NO GO.

## 2. Scope

### Inclus

- audit source `app/api/debug-env/route.ts` branche ph148/onboarding-activation-replay.
- audit runtime HTTP probes DEV+PROD avec/sans follow redirect.
- suppression route via `git rm` (decision defaut prompt + 0 dependance detectee).
- tests source local (tsc --noEmit).
- commit + push Client + build Docker DEV + verify bundle + push image + GitOps DEV + validation DEV.
- gate PROD : repo clean verify (single-file tsconfig.tsbuildinfo restore via git checkout HEAD -- sans git reset --hard).
- build Docker PROD + verify bundle + push image + GitOps PROD + validation PROD.
- rapport docs-only ASCII strict.

### Hors scope strict

- aucune rotation secret KV Vault.
- aucune mutation Vault.
- aucune modification keybuzz-api / keybuzz-backend / keybuzz-admin-v2 / keybuzz-website.
- aucune promotion AS.17.0 / AS.17.0.1.
- aucun changement OAuth provider / NextAuth config (hors suppression route debug).
- aucun faux event metrics.
- aucun Q-1B-2B EXEC.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports historiques + KEY-323

- keybuzz-infra/docs/PH_AUTH_FIX_P0-REPORT.md (mentionne H5 debug-env corrige DEV / guard PROD)
- keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-2A-...PROD-INTERNAL-LOW-RISK-DRYRUN-01.md (commit 4950f96)
- keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1F-1-...DEV-POST-ROTATION-VALIDATION-...md (commit 556772c)
- keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-1B-...DEV-INTERNAL-LOW-RISK-EXEC-...md (commit fcc1170)

### Commits attendus

| Repo | Commit | Description |
|---|---|---|
| keybuzz-infra | 4950f96 | Q-1B-2A dry-run PROD (baseline) |
| keybuzz-client (avant) | 3fe90ab | feat(security): inject x-user-email channels BFFs (KEY-314) |

## 4. Preflight

| Check | Attendu | Resultat | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 12:35 UTC | OK |
| keybuzz-infra HEAD | 4950f96 ou descendant | 4950f96 main | OK |
| keybuzz-client branch | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | OK |
| keybuzz-client HEAD | 3fe90ab clean | 3fe90ab clean | OK |
| Images runtime DEV | v3.5.197-channels-bff-userauth-dev | v3.5.197-channels-bff-userauth-dev | OK baseline |
| Images runtime PROD | v3.5.197-channels-bff-userauth-prod | v3.5.197-channels-bff-userauth-prod | OK baseline |
| PH_AUTH_FIX_P0-REPORT.md | present + mentionne H5 debug-env | present, lignes 16/79/113 reference H5 | OK contradiction confirmee |

## 5. Source/runtime audit

### Audit source pre-patch

| Check | Resultat |
|---|---|
| Path file | app/api/debug-env/route.ts (982 bytes, 30 lignes) |
| Guard PROD dans code source | ABSENT (contrairement a PH_AUTH_FIX_P0-REPORT.md affirmation) |
| Content GET handler | retourne JSON avec : hasGoogleId/Secret, hasAzureId/Secret, hasNextAuthSecret (booleens), nextAuthUrl (full), nodeEnv, googleIdPrefix (4 chars), azureIdPrefix (4 chars), envKeys filtre, totalEnvKeys |
| git log file | 2 commits historiques : 42e6bb4 (creation PH13) + 0bcf2f3 (refactor multi-tenant). Aucun commit guard PROD. |
| References dans autres fichiers | 0 reference (search ts/tsx/js/jsx/md/json/yaml/yml hors node_modules/.next/dist/build) |
| middleware.ts | utilise getToken() NextAuth, redirect /auth/signin si pas token, applique a TOUTES routes non publiques |

### Audit runtime pre-patch (HTTP probes baseline Q-1B-2A)

| Env | URL | Status | Metadata exposed publique ? | Verdict classification |
|---|---|---|---|---|
| DEV | https://client-dev.keybuzz.io/api/debug-env | HTTP 307 redirect /auth/signin | NON publique (middleware NextAuth proteges) | downgrade Q-1B-2A P2 publique -> P3 auth-user disclosure |
| PROD | https://client.keybuzz.io/api/debug-env | HTTP 307 redirect /auth/signin | NON publique (middleware NextAuth proteges) | idem |

Decouverte critique : middleware NextAuth global protege deja la route en runtime. Le risque reel etait disclosure aux utilisateurs **authentifies** uniquement, classifie P3 information disclosure (vs P2 publique annonce Q-1B-2A). Fix justifie quand meme car aucune utilite produit + expose prefix Client IDs + nextAuthUrl complet a auth users.

## 6. Decision fix

Decision : **SUPPRIMER `app/api/debug-env/route.ts`**.

Raisons :
- 0 dependance detectee source (E1).
- aucune utilite produit (route debug).
- conformite avec decision defaut prompt.
- nouvelle surface auth fragile inutile (middleware existe deja).
- elimine completement la surface d'exposition meme pour auth users.

Alternatives ecartees :
- ajouter guard PROD (incoherence avec PH_AUTH_FIX_P0-REPORT.md affirmation deja en place, fragile en cas de regression).
- ajouter NextResponse.json({error:'Not found'},{status:404}) : laisse code mort, surface inutile.

## 7. Patch

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| keybuzz-client/app/api/debug-env/route.ts | git rm (30 lignes deleted) | minimal (0 dependance source) | OK |
| keybuzz-client/app/api/debug-env/ (directory) | auto-removed (empty post-rm) | aucun | OK |

git status post-patch local : `D  app/api/debug-env/route.ts` + ` M tsconfig.tsbuildinfo` (artefact tsc E4, sera restaure pre-build PROD).

## 8. Tests source

| Test | Resultat | Note |
|---|---|---|
| `tsc --noEmit` timeout 90s | 2 errors `.next/types/.../debug-env/route.ts` | stale cache Next.js, auto-regenere prochain build, non-bloquant |
| residual references `debug-env` source | 0 match (clean) | confirme aucune dependance |
| package.json scripts | next dev/build/start/lint + prebuild metadata.py | standard Next.js |
| node_modules + tsc + next binaires | presents | environment OK |

## 9. Build DEV

| Champ | Valeur |
|---|---|
| Git HEAD source | f61763a (commit fix(security): disable debug env endpoint + Co-Authored-By Claude Opus 4.7) |
| Tag image | v3.5.198-debug-env-disabled-dev |
| Image local ID | sha256:93657118649c21b3f38cff2b9eab05db67b4d38ad5c72f382e9e78c0d5af7f91 |
| Digest pushed | sha256:8a2df6278b730e791e148a7d2c22af0fc8295bc847e893c17823d38e938426eb |
| Build args | NEXT_PUBLIC_APP_ENV=development, NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io, IMAGE_REVISION=f61763a..., IMAGE_CREATED=2026-05-17T12:42:26Z, IMAGE_VERSION=v3.5.198-debug-env-disabled-dev |
| OCI labels | org.opencontainers.image.revision/created/version/source/title appliques |
| Build args guard | PASS (script check-client-build-args.sh succeed) |

### Verify bundle DEV

| Check | Count | Verdict |
|---|---|---|
| https://api-dev.keybuzz.io in .next/static | 2 occurrences | PASS PRESENT |
| https://api.keybuzz.io in .next/static | 0 occurrences | PASS ABSENT |
| debug-env handler in /app/.next/server/app/api | 0 match docker export tar grep | PASS supprime du bundle compile |

## 10. GitOps DEV

| Etape | Resultat |
|---|---|
| docker push GHCR DEV | digest sha256:8a2df6278b730e791e148a7d2c22af0fc8295bc847e893c17823d38e938426eb |
| Manifest update | k8s/keybuzz-client-dev/deployment.yaml line 77 image tag v3.5.197... -> v3.5.198-debug-env-disabled-dev + commentaire phase PH-AS17-1Q-1B-2A-bis KEY-323 + rollback v3.5.197 + digest |
| Commit infra | 08c8313 "chore(client-dev): bump image v3.5.198-debug-env-disabled-dev (KEY-323 AS.17.1Q-1B-2A-bis)" + Co-Authored-By |
| Push infra | 4950f96..08c8313 main -> main |
| kubectl apply | deployment.apps/keybuzz-client configured |
| Rollout status | successfully rolled out (timeout 180s respecte) |
| Runtime = manifest = last-applied | OK 3 sources coherentes |

## 11. Validation DEV

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| HTTP probe DEV /api/debug-env (no follow) | 307/404/410/403 | HTTP 307 redirect /auth/signin (middleware NextAuth, comportement identique pre-fix) | OK |
| Body size HTTP 307 | url path | 43 bytes URL `/auth/signin?callbackUrl=%2Fapi%2Fdebug-env` | OK |
| Body type | non-JSON (redirect) | (not JSON) | OK |
| Bundle compile contains debug-env handler | absent | 0 match docker export grep | PASS supprime |
| Pod Client DEV | Running 1/1 | keybuzz-client-c95894fb4-skjq2 Running 1/1 age 2m34s restarts=0 | OK |
| Logs DEV --since=5m | clean Next.js startup | 6 lines, ready 467ms, 0 error/warn/Vault/403/500 | OK |
| Runtime image vs manifest | identique | v3.5.198-debug-env-disabled-dev = v3.5.198-debug-env-disabled-dev | OK |

## 12. PROD gate / status

| Etape | Resultat |
|---|---|
| Gate dirty pre-build PROD | seul tsconfig.tsbuildinfo dirty (artefact tsc E4, tracked at HEAD, JSON typescript build info header confirme) |
| Cleanup tsconfig.tsbuildinfo | git checkout HEAD -- tsconfig.tsbuildinfo (single-file safe, sans git reset --hard ni git clean) |
| Workspace post-restore | clean (0 dirty) |
| Git HEAD pour build PROD | f61763a (identique build DEV, no rebuild source) |

## 13. Build / GitOps / validation PROD

### Build PROD

| Champ | Valeur |
|---|---|
| Git HEAD source | f61763a (meme commit que DEV, build-from-git identique) |
| Tag image | v3.5.198-debug-env-disabled-prod |
| Image local ID | sha256:ee078c9105c50172a43397ef75934d2d1b0b4f1e5ebf7de2f1555509de0c94f8 |
| Digest pushed | sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa |
| Build args | NEXT_PUBLIC_APP_ENV=production, NEXT_PUBLIC_API_URL=https://api.keybuzz.io, NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io, IMAGE_REVISION=f61763a..., IMAGE_CREATED=2026-05-17T13:02:28Z, IMAGE_VERSION=v3.5.198-debug-env-disabled-prod |
| OCI labels | org.opencontainers.image.revision/created/version/source/title appliques |
| Build args guard | PASS |

### Verify bundle PROD

| Check | Count | Verdict |
|---|---|---|
| https://api.keybuzz.io in .next/static | 2 occurrences | PASS PRESENT |
| https://api-dev.keybuzz.io in .next/static | 0 occurrences | PASS ABSENT |
| debug-env handler in /app/.next/server/app/api | 0 match docker export tar grep | PASS supprime du bundle compile |

### GitOps PROD

| Etape | Resultat |
|---|---|
| docker push GHCR PROD | digest sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa |
| Manifest update | k8s/keybuzz-client-prod/deployment.yaml line 76 image tag v3.5.197... -> v3.5.198-debug-env-disabled-prod + commentaire phase PH-AS17-1Q-1B-2A-bis-PROD KEY-323 + rollback v3.5.197 + digest |
| Commit infra | bb35226 "chore(client-prod): bump image v3.5.198-debug-env-disabled-prod (KEY-323 AS.17.1Q-1B-2A-bis)" + Co-Authored-By |
| Push infra | 08c8313..bb35226 main -> main |
| kubectl apply | deployment.apps/keybuzz-client configured |
| Rollout status | successfully rolled out (timeout 180s respecte) |
| Runtime = manifest = last-applied | OK 3 sources coherentes |

### Validation PROD

| Test | Attendu | Resultat | Verdict |
|---|---|---|---|
| HTTP probe PROD /api/debug-env (no follow) | 307/404/410/403 | HTTP 307 redirect /auth/signin (middleware NextAuth) | OK |
| Body type | non-JSON (redirect) | non-JSON, body=43 bytes URL | OK |
| Pod Client PROD | Running 1/1 | keybuzz-client-6b588c69fc-7897p Running 1/1 age 45s restarts=0 | OK |
| Logs PROD --since=5m | clean Next.js startup | 6 lines, ready 478ms, 0 error/warn/Vault/403/500 | OK |
| Pod image | v3.5.198-debug-env-disabled-prod | v3.5.198-debug-env-disabled-prod | OK |

## 14. AI feature parity / anti-regression

| Surface | Check | Resultat | Verdict |
|---|---|---|---|
| Inbox visible logs | aucune regression error burst | logs Client PROD+DEV 6 lines startup uniquement | OK |
| IA / autopilot | aucun changement | repo keybuzz-api/keybuzz-backend non touches, 0 mutation | OK |
| Connecteurs marketplace | aucune erreur massive | aucune mutation, runtime ages keybuzz-api-prod/backend-prod 22h unchanged | OK |
| Auth flows OAuth/NextAuth | aucun changement hors suppression route debug | middleware.ts inchange, NextAuth config inchange, OAuth Google/Azure routes inchanges | OK |
| Messages/orders/tracking | aucun appel | 0 mutation API/backend | OK |

## 15. No fake metrics / no fake events

| Verification | Resultat |
|---|---|
| fake signup_complete | 0 |
| fake purchase | 0 |
| fake CAPI/GA4 event | 0 |
| paiement test provider | 0 |
| provider call (Stripe/SES/OpenAI/Anthropic/Amazon/Shopify/Octopia/Slack) | 0 |
| event dashboard invente | 0 |
| webhook mutationnel | 0 |
| email envoye | 0 |
| message client | 0 |

Toutes observations issues de :
- kubectl get/logs (metadata + status, no values)
- docker build/push/inspect (manifest + labels)
- HTTP curl probe (status + body size + redirect URL, no JSON body if redirect)
- jq filter sans .data values
- grep code env-var counts seulement

## 16. Risk register

| Risk | Severity | Status | Mitigation |
|---|---|---|---|
| Classification Q-1B-2A initiale P2 disclosure publique | downgrade P3 | observe | middleware NextAuth global proteges deja la route en runtime ; classification corrigee P3 disclosure auth-user ; fix supprime completement la surface meme pour auth users |
| Contradiction PH_AUTH_FIX_P0-REPORT.md (guard PROD pretendu en place) | P2 documentation | clarifie | rapport historique probable obsolete, branche ph148 ne contient pas le guard, fix actuel par suppression resout definitivement |
| KEYBUZZ_INTERNAL_TOKEN cross-env (Q-1B-2B futur) | P0 critique | hors scope Q-1B-2A-bis | bloquer Q-1B-2B EXEC tant que decisions Ludovic non prises |
| Rollback debug-env disclosure | low (regression) | observe | rollback rapide via kubectl apply ancienne version manifest OR git revert + re-build + redeploy ; tag v3.5.197 toujours present GHCR |
| Image OCI labels metadata exposure | P3 | accepte | labels OCI standard, contiennent revision git hash + version tag (publiques git), pas de secret |
| Other debug routes potentielles | P3 | observe | aucune autre `debug-` route identifiee dans search ; future audit complet recommande |

## 17. Rollback

### Procedure rollback DEV

```
# 1. Revert manifest
cd /opt/keybuzz/keybuzz-infra
git revert 08c8313 --no-edit
git push

# 2. Apply ancien manifest
kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl -n keybuzz-client-dev rollout status deployment keybuzz-client --timeout=180s

# 3. (Optionnel) Revert source Client si suppression a casse autre chose
cd /opt/keybuzz/keybuzz-client
git revert f61763a --no-edit
git push origin ph148/onboarding-activation-replay
# Puis rebuild + redeploy ancien comportement
```

### Procedure rollback PROD

```
cd /opt/keybuzz/keybuzz-infra
git revert bb35226 --no-edit
git push
kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl -n keybuzz-client-prod rollout status deployment keybuzz-client --timeout=180s
```

### Garanties

- Images precedentes v3.5.197-channels-bff-userauth-dev/prod toujours presentes GHCR (rollback rapide possible).
- Source Client commit f61763a peut etre revert si necessaire (1 file 30 lignes a remettre).
- Aucune mutation Vault/secret/DB requise pour rollback.

## 18. Linear draft comment (a poster par Codex apres commit)

```
AS.17.1Q-1B-2A-bis debug-env disclosure audit/fix COMPLETE

Commit rapport Q-1B-2A : 4950f96 (PROD dry-run baseline)
Commit Client : f61763a (fix(security): disable debug env endpoint)
Commit infra DEV : 08c8313 (chore(client-dev): bump image v3.5.198-debug-env-disabled-dev)
Commit infra PROD : bb35226 (chore(client-prod): bump image v3.5.198-debug-env-disabled-prod)
Commit rapport Q-1B-2A-bis : <CE remplira apres push>
Verdict : GO DEBUG-ENV DEV+PROD FIXED.

Resume technique :
- Route `app/api/debug-env/route.ts` SUPPRIMEE (1 file, 30 lignes) branche ph148/onboarding-activation-replay.
- Classification corrigee de Q-1B-2A initiale P2 disclosure publique -> P3 disclosure auth-user uniquement (middleware NextAuth global protege deja route en runtime). Fix justifie quand meme : aucune utilite produit + exposait nextAuthUrl complet + prefix 4 chars Client IDs Google/Azure + booleens has* + filtre envKeys aux users authentifies.
- Contradiction PH_AUTH_FIX_P0-REPORT.md clarifiee : rapport historique mentionne guard PROD mais branche ph148 n'a aucun guard ; suppression definitive resout le probleme racine.
- Build Docker DEV+PROD from Git commit f61763a (build-from-git strict, repo clean validate via git checkout HEAD -- tsconfig.tsbuildinfo single-file restore).
- Build args guard PASS DEV+PROD.
- Bundle verifies pre-push : DEV api-dev=2 present + api=0 absent ; PROD api=2 present + api-dev=0 absent. Bundle handler debug-env=0 (supprime du compile).
- Images pushed GHCR :
  - v3.5.198-debug-env-disabled-dev digest sha256:8a2df6278b730e791e148a7d2c22af0fc8295bc847e893c17823d38e938426eb
  - v3.5.198-debug-env-disabled-prod digest sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa
- Manifests GitOps DEV+PROD updated (1 line each) + commit + push + kubectl apply + rollout OK.
- Runtime = manifest = last-applied confirme DEV (v3.5.198-debug-env-disabled-dev) + PROD (v3.5.198-debug-env-disabled-prod).
- HTTP probes /api/debug-env DEV+PROD : 307 redirect signin (middleware NextAuth identique pre-fix, mais bundle compile ne contient plus le handler -> 404 Next.js standard pour users authentifies).
- Pods Client DEV+PROD Running 1/1, age 45s-2m34s, 0 restart, logs startup clean Next.js ready 467-478ms.
- Control negatif : keybuzz-api-prod/backend-prod ages 22h unchanged, ExternalSecrets 30/30 True, aucun impact cross-namespace.
- Conformite : aucun secret/env value affiche, aucun kubectl set/edit/patch, aucun git reset --hard ni git clean (tsconfig.tsbuildinfo restore via git checkout HEAD -- single-file).

Gaps :
- Q-1B-2B EXEC reste NO GO jusqu'a decisions Ludovic (10 items section 17 rapport Q-1B-2A).
- Q-1B-3/4/5/6 (provider/infra/LLM/marketplace) NO GO maintenus.
- PROD promotion AS.17.0/AS.17.0.1 NO GO maintenu.
- backfill-scheduler ImagePullBackOff dev+prod hors scope.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

## 19. Conformite interdits

| Interdit Q-1B-2A-bis | Respect |
|---|---|
| Rotation secret KV Vault | OK : aucune |
| Mutation Vault | OK : aucune |
| Modification keybuzz-api/backend/admin-v2/website | OK : aucune |
| Promotion AS.17.0/AS.17.0.1 | OK : NO GO maintenu |
| Changement OAuth provider | OK : aucun |
| Changement NextAuth config hors route debug | OK : middleware.ts + auth-options.ts inchange |
| Faux event metrics | OK : 0 event mutationnel |
| Aucun secret/token/env value affiche | OK : redacts partout |
| kubectl set image/env/patch/edit/annotate (mutation interdite) | OK : aucun (utilise kubectl apply -f uniquement) |
| git reset --hard / git clean | OK : aucun (tsconfig.tsbuildinfo restore via git checkout HEAD -- single-file safe) |
| build depuis pod/runtime/dist/SCP | OK : build-from-git strict (Docker context = working dir, .dockerignore exclut .next/node_modules/.git/.env*) |
| Build depuis workspace dirty | OK : workspace clean pre-build DEV (3fe90ab baseline) + pre-build PROD (tsconfig.tsbuildinfo restore) |
| Token statique hardcode | OK : aucun |
| Bypass IP/user hardcode | OK : aucun |
| Conserver route active PROD sous pretexte debug | OK : route supprimee definitivement |
| Bastion install-v3 only | OK |
| /opt/keybuzz/credentials/ non touche | OK |
| /opt/keybuzz/secrets/ non touche | OK |
| ASCII strict rapport | a verifier post-Write |
| STOP avant commit/push rapport | OK (E15 STOP) |

## 20. Resume commits / digests / runtime

| Item | Valeur |
|---|---|
| Commit Client (source) | f61763a4554e88d3f2651e4dde1aec1a0c54f0c7 |
| Commit infra Q-1B-2A baseline | 4950f96 |
| Commit infra DEV bump image | 08c8313 |
| Commit infra PROD bump image | bb35226 |
| Tag image DEV | v3.5.198-debug-env-disabled-dev |
| Digest DEV | sha256:8a2df6278b730e791e148a7d2c22af0fc8295bc847e893c17823d38e938426eb |
| Tag image PROD | v3.5.198-debug-env-disabled-prod |
| Digest PROD | sha256:0b96435cdc2b5d56e42c3fbce8da65901956d09275688885b4bf9c72e70c2faa |
| Runtime DEV pod | keybuzz-client-c95894fb4-skjq2 |
| Runtime PROD pod | keybuzz-client-6b588c69fc-7897p |
| Bundle DEV api-dev count | 2 (PASS) |
| Bundle DEV api count | 0 (PASS) |
| Bundle PROD api count | 2 (PASS) |
| Bundle PROD api-dev count | 0 (PASS) |
| Bundle handler debug-env DEV | absent (PASS) |
| Bundle handler debug-env PROD | absent (PASS) |

STOP final : rapport pret, en attente GO Ludovic commit/push E16.

Q-1B-2B EXEC reste NO GO.
Q-1B-3/4/5/6 (provider/infra/LLM/marketplace) restent NO GO.
PROD promotion AS.17.0/AS.17.0.1 reste NO GO.
backfill-scheduler ImagePullBackOff hors scope.
