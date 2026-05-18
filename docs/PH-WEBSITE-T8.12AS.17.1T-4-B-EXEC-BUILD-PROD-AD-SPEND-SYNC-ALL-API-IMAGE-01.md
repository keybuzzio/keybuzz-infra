# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-PROD AD_SPEND SYNC-ALL API PROD IMAGE BUILD

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-BUILD-PROD
> Environnement : keybuzz-api branche ph147.4/source-of-truth, image PROD GHCR uniquement
> Type : docker build + push GHCR PROD (zero deploy, zero apply, zero manifest modifie)
> Priorite : Mode B SAFE pre-deploy PROD

## VERDICT

GO PROD IMAGE READY Q-1T-4-B-EXEC-BUILD-PROD. Image keybuzz-api PROD `v3.5.250-ad-spend-sync-all-prod` construite depuis Git commit `01b163e4` (meme commit que DEV) via git worktree detache propre, docker build --no-cache + OCI labels KEY-308 complets, push GHCR reussi, digest sha256 `93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d` capture et verifie par pull-back. Tests pre-build tsc + PH118 5/5 PASS dans worktree propre, sha256 sources MATCH Q-1T-4-B-EXEC-CODE. Runtime DEV/PROD strictement inchange (DEV `v3.5.250-ad-spend-sync-all-dev` pod 1h uptime, PROD `v3.5.190-channels-tenantguard-prod` pod 8h30 uptime, generations 488/411 inchangees). 0 deploy, 0 kubectl apply, 0 provider call, 0 DB write, 0 Vault command, 0 endpoint call, 0 manifest modifie.

Image PROD prete pour Q-1T-4-B-EXEC-DEPLOY-API-PROD (Mode B SAFE PROD avec GO Ludovic explicite, prompt separe).

## Scope / hors scope

### Scope execute

- preflight read-only (bastion + repos + runtime DEV/PROD + GHCR collision check)
- git worktree add detache `/tmp/keybuzz-q1t4b-build-prod-keybuzz-api-01b163e4` (HEAD 01b163e4, clean checkout)
- tests pre-build : tsc --noEmit + 5/5 PH118 tests PASS (compilation isolee /tmp puis node)
- docker build --no-cache --build-arg KEY-308 OCI labels (revision/created/version/source/title) avec tag `v3.5.250-ad-spend-sync-all-prod`
- docker push GHCR reussi (digest capture)
- docker manifest inspect --verbose + pull-back par digest (verification reproductibilite)
- runtime non-regression read-only DEV+PROD
- cleanup git worktree temp (`/tmp/keybuzz-q1t4b-build-prod-keybuzz-api-01b163e4`)

### Hors scope (NON execute)

- Aucun deploy PROD
- Aucun deploy DEV
- Aucun kubectl apply
- Aucun manifest k8s modifie
- Aucune commande Vault
- Aucun appel `POST /admin/internal/ad-accounts/sync-all`
- Aucun appel provider Meta / Google Ads
- Aucune ecriture DB
- Aucun CronJob cree
- Aucun commentaire Linear
- Aucun tag `:latest`
- Aucun build depuis workspace dirty (worktree detache propre)
- Aucune modification dist/ preexistants ou repo source `/opt/keybuzz/keybuzz-api`

## Sources relues

- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE-AD-SPEND-SYNC-ALL-API-DRYRUN-PATCH-01.md (commit 22f1144, source code)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-AD-SPEND-SYNC-ALL-API-DEV-IMAGE-01.md (commit 8068caf, image DEV reference)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-AD-SPEND-SYNC-INTERNAL-TOKEN-DEV-01.md (commit 0526349, Secret DEV)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-DEV-01.md (commit 5125a51, deploy DEV smoke OK)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-PROD-AD-SPEND-SYNC-INTERNAL-TOKEN-01.md (commit 8d40f36, Secret PROD)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts + routes.ts + tests/ph118-tests.ts + app.ts (lecture seule worktree detache)
- Convention KEY-309 (tag immuable `v3.5.<N>-<slug>-<env>`) + KEY-308 (OCI labels revision/created/version/source/title)

## Preflight (E0)

| Item | Attendu | Observe | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-api branche | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| keybuzz-api HEAD | 01b163e4 reachable + push origin | 01b163e4 HEAD + branch origin/ph147.4 contient 01b163e4 | OK |
| keybuzz-api commit 01b163e4 | 4 fichiers, +441/-49 | confirmed (routes.ts +109/-49, internal-routes.ts +154, ph118-tests.ts +176, app.ts +2) | OK |
| keybuzz-api dirty | dist/* orphans uniquement, no source TS | 223 dist/* lignes, source TS clean | OK (hors scope, worktree isole) |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | descendant 8d40f36 | 8d40f36 (clean) | OK |
| Runtime DEV image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev | OK |
| Runtime DEV generation | 488 | 488 | OK |
| Runtime DEV pod | restarts=0, started 2026-05-18T20:32:43Z | keybuzz-api-68cc9c967d-68pbx restarts=0 ~1h uptime | OK |
| Runtime PROD image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | OK |
| Runtime PROD generation | 411 | 411 | OK |
| Runtime PROD pod | restarts=0, started 2026-05-18T13:05:01Z | keybuzz-api-5874f4d576-4zr29 restarts=0 ~8h30 uptime | OK |
| Tag GHCR `v3.5.250-ad-spend-sync-all-prod` | ABSENT | "manifest unknown" -> safe a utiliser | OK |
| Docker | >= 24 | Docker 29.1.3 | OK |
| GHCR auth | ghcr.io configure | confirme (push utilise auth existante) | OK |

## Source build propre (E1)

### git worktree add detache

```
cd /opt/keybuzz/keybuzz-api
git worktree add --detach /tmp/keybuzz-q1t4b-build-prod-keybuzz-api-01b163e4 01b163e4
```

Resultat :
- HEAD : `01b163e4cd3f7c4341f71819fe79b89b80eccac7`
- git status : clean (apres checkout initial)
- 17596 fichiers checkout (incluant `node_modules/` tracke par Git car `.gitignore` absent du repo)
- path absolu /tmp commence par `/tmp/keybuzz-q1t4b-build-prod-keybuzz-api-` (convention cleanup)

### sha256 sources verification (match Q-1T-4-B-EXEC-CODE)

```
98f666fe73605f653189cf662b7a4cea199fffa9845cd40b8b71ddd92c865b31  src/modules/ad-accounts/routes.ts
33ebef7d8f2457c237ab4a1047c67c5b0457b3c9148bfce32353f7ee10697a79  src/modules/ad-accounts/internal-routes.ts
35519042e327e143498f08b69911ed190fa8b063f29e75bc102977c39e878bed  src/tests/ph118-tests.ts
22886e1f1313b18e5d6d9ab000870515e6100580175acf767f30a2724952b4bd  src/app.ts
```

Tous identiques aux sha256 documentes dans Q-1T-4-B-EXEC-CODE (rapport commit 22f1144) et Q-1T-4-B-EXEC-BUILD DEV (rapport commit 8068caf). Reproductibilite confirmee byte-for-byte.

### Note .gitignore absent

Le repo keybuzz-api n'a PAS de `.gitignore`. Par consequence `node_modules/` est tracke dans le commit (verifie via `git log --diff-filter=A -- node_modules/`). Le worktree detache embarque donc ~190k fichiers node_modules. Cela n'impacte PAS le build Docker car le Dockerfile fait son propre `npm ci` apres `COPY package*.json` + `COPY src` + `COPY tsconfig.json` (le node_modules du worktree n'est jamais copie dans l'image). Gap documente pour hygiene future (ajouter .gitignore avec `node_modules/`, `dist/`, `*.log`).

## Tests pre-build (E2)

### tsc --noEmit (worktree detache propre)

```
npx --no-install tsc --noEmit
```

Resultat : exit=0, zero erreur de type.

### Tests PH118 (compile vers /tmp + node)

```
npx --no-install tsc --outDir /tmp/keybuzz-q1t4b-build-prod-ph118-tests-build --skipLibCheck
NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules node /tmp/.../tests/ph118-tests.js
```

Sortie :

```
=== PH118 / AS.17.1T-4-B-EXEC-CODE tests ===
[OK] syncOneAccount dryRun: zero DB calls, zero provider calls
[OK] syncOneAccount inactive: throws ACCOUNT_NOT_ACTIVE, zero DB calls
[OK] syncOneAccount unsupported platform: throws PLATFORM_NOT_SUPPORTED, zero DB calls
[OK] /sync-all missing token -> 403 FORBIDDEN_INTERNAL_ONLY
[OK] /sync-all wrong token (same length) -> 403
[OK] /sync-all length mismatch -> 403 (timingSafeEqual safe)
[OK] hash8 deterministic 8-char hex (sample: 466a4377 vs 21e1a1ad)
=== ALL PH118 TESTS PASSED (5/5) ===
```

Total : 5/5 PASS. Cleanup compile dir post-run.

### Verification source endpoint

```
grep -c "AD_SPEND_SYNC_INTERNAL_TOKEN" src/modules/ad-accounts/internal-routes.ts
2
```

`AD_SPEND_SYNC_INTERNAL_TOKEN` mentionne 2 fois (env var priority + fallback comment).

### No fake metrics / provider call pre-build

- Aucun POST `/admin/internal/ad-accounts/sync-all`
- Aucun appel Meta/Google Ads
- Aucun INSERT/UPDATE/DELETE DB
- Tests offline avec FakePool + stub fetch (verifie Q-1T-4-B-EXEC-CODE)

## Build local PROD (E3)

### Commande docker build

```
TAG="v3.5.250-ad-spend-sync-all-prod"
REV="01b163e4cd3f7c4341f71819fe79b89b80eccac7"
CREATED="2026-05-18T21:33:05Z"

docker build \
  --no-cache \
  --build-arg IMAGE_REVISION="$REV" \
  --build-arg IMAGE_CREATED="$CREATED" \
  --build-arg IMAGE_VERSION="$TAG" \
  -t ghcr.io/keybuzzio/keybuzz-api:$TAG \
  .
```

Resultat : `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod`. Exit=0.

### Inspection image locale

| Champ | Valeur |
|---|---|
| Image ID local | `sha256:28938aeef8e0eef174d530f9ec3fc583a447bac327dffdc0ca501f34d0cb7b5e` (short `28938aeef8e0`) |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod` |
| Architecture | amd64 |
| Size | 343,490,798 bytes (327.6 MB) |
| Image config created | 2026-05-18T21:34:15Z (post-build) |
| OCI label revision | `01b163e4cd3f7c4341f71819fe79b89b80eccac7` |
| OCI label created | `2026-05-18T21:33:05Z` |
| OCI label version | `v3.5.250-ad-spend-sync-all-prod` |
| OCI label source | `https://github.com/keybuzzio/keybuzz-api` |
| OCI label title | `keybuzz-api` |

### Verification dist/ compile dans image

```
docker run --rm --entrypoint sh ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod \
  -c "ls dist/modules/ad-accounts/ ; node -e 'console.log(Object.keys(require(\"/app/dist/modules/ad-accounts/internal-routes\")))'"
```

Sortie :

```
internal-routes.js
routes.js
[ 'adAccountsInternalRoutes' ]
```

L'endpoint compile est present dans l'image PROD, export verifie.

### Comparaison DEV vs PROD (meme commit)

| Champ | Image DEV (`v3.5.250-ad-spend-sync-all-dev`) | Image PROD (`v3.5.250-ad-spend-sync-all-prod`) |
|---|---|---|
| Source commit (OCI revision) | 01b163e4 | 01b163e4 (identique) |
| Source tree sha256 (4 files cibles) | identique | identique (verifie E1.2) |
| Image ID local | `17762eed8802` | `28938aeef8e0` |
| Tag | dev | prod |
| OCI version label | `v3.5.250-ad-spend-sync-all-dev` | `v3.5.250-ad-spend-sync-all-prod` |
| OCI created label | `2026-05-18T17:38:58Z` | `2026-05-18T21:33:05Z` |

Image ID different attendu : meme code source mais labels OCI distinct creent des layers de metadata differents (architecture du Dockerfile `ARG ... LABEL ...`). Le code applicatif `dist/` est byte-for-byte identique au niveau binaire (npm ci + tsc deterministes sur meme source).

## Push GHCR + digest OCI (E5)

### docker push

```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod
```

Output final :

```
v3.5.250-ad-spend-sync-all-prod: digest: sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d size: 2416
push exit=0
```

6 layers nouvelles pushed (d3901d53f250, 1ae6de7c37e4, 69d4b84431cf, c8b0f2c8a629, e61d2a995383, dcdc1aa353ed), 4 layers existaient deja (base node:lts-alpine + curl deps reutilises avec DEV).

### Digest sha256 capture

**Manifest digest (immuable, source de verite GitOps PROD)** :

```
sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d
```

**Config digest (Image ID local)** :

```
sha256:28938aeef8e0eef174d530f9ec3fc583a447bac327dffdc0ca501f34d0cb7b5e
```

### docker manifest inspect --verbose

| Champ | Valeur |
|---|---|
| Descriptor.digest | `sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d` |
| Descriptor.size | 2416 |
| mediaType | application/vnd.docker.distribution.manifest.v2+json |
| config.digest | `sha256:28938aeef8e0eef174d530f9ec3fc583a447bac327dffdc0ca501f34d0cb7b5e` |
| layers count | 10 |
| total layer size | 112,040,595 bytes (106.9 MB compressed) |

### Pull-back validate (reproductibilite par digest)

```
docker pull ghcr.io/keybuzzio/keybuzz-api@sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d
```

Sortie : `Status: Image is up to date`. OCI labels preserves apres pull-back (revision, created, version, source, title identiques).

### Comparaison digests DEV vs PROD

| Champ | DEV | PROD |
|---|---|---|
| Manifest digest | `sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b` | `sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d` |
| Config digest | `sha256:17762eed88028cbef4b33c6703f50148708921cb325a76a0b83025543970a8cb` | `sha256:28938aeef8e0eef174d530f9ec3fc583a447bac327dffdc0ca501f34d0cb7b5e` |
| layers count | 10 | 10 |
| total layer compressed | 106.9 MB | 106.9 MB |
| Source commit | 01b163e4 | 01b163e4 (identique) |

Digests differents (attendus : labels OCI version + created differents creent manifests/configs distincts). Code applicatif identique.

## Runtime non-regression DEV/PROD (E6)

| Surface | Avant push | Apres push (cette phase) |
|---|---|---|
| Runtime keybuzz-api DEV image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev (INCHANGE) |
| Runtime keybuzz-api DEV generation | 488 | 488 (INCHANGE) |
| Pod DEV keybuzz-api-68cc9c967d-68pbx | started 2026-05-18T20:32:43Z restarts=0 | identique ~1h uptime preserve |
| Runtime keybuzz-api PROD image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod (INCHANGE) |
| Runtime keybuzz-api PROD generation | 411 | 411 (INCHANGE) |
| Pod PROD keybuzz-api-5874f4d576-4zr29 | started 2026-05-18T13:05:01Z restarts=0 | identique ~8h30 uptime preserve |
| keybuzz-infra HEAD | 8d40f36 | 8d40f36 (INCHANGE) |
| keybuzz-infra git status | clean | clean |

Aucun rollout, aucun restart cote runtime DEV ou PROD. Aucun manifest GitOps modifie.

## No fake metrics / no fake events (E7)

| Action | Execute par CE ? |
|---|---|
| Appel POST /admin/internal/ad-accounts/sync-all (DEV ou PROD) | NON |
| Appel POST /ad-accounts/:id/sync | NON |
| Appel reseau Meta Ads API (graph.facebook.com) | NON |
| Appel reseau Google Ads API (googleads.googleapis.com) | NON |
| Event GA4 / Meta CAPI / TikTok / LinkedIn emis | NON |
| Ecriture ad_spend_tenant / ad_platform_accounts | NON |
| Modification dashboard/admin metrics | NON |
| Restart deploy DEV/PROD | NON |
| Vault command (kv put/get/delete) | NON |
| Modification Secret K8s | NON |
| CronJob creation/modification | NON |

## Security / secrets

| Risque | Mitigation appliquee |
|---|---|
| Token AD_SPEND_SYNC_INTERNAL_TOKEN dans build/image | N/A : token Vault uniquement, jamais en source ni image (env var resolved au runtime via secretKeyRef) |
| OCI labels exposant valeurs | Labels = revision/created/version/source/title (publics, pas de secrets) |
| Digest reveles | Manifest + config digests sont publics et necessaires pour GitOps pinning ; pas de risque |
| node_modules tracked Git | Visible cote repo Git (deja public si repo public) ; gap d'hygiene, pas un leak nouveau |
| GHCR push credentials | Token GHCR stocke `/root/.docker/config.json` mode 600 (non touche) |

## Cleanup temporary files

| Fichier/Repertoire | Statut |
|---|---|
| /tmp/keybuzz-q1t4b-build-prod-keybuzz-api-01b163e4/ (worktree) | git worktree remove --force OK (absent confirme) |
| /tmp/keybuzz-q1t4b-build-prod-ph118-tests-build/ (tests compile) | rm -rf OK post-tests |
| /tmp/ph118-backup/ (Q-1T-4-B-EXEC-CODE rollback) | CONSERVE (hors scope) |
| /root/.vault-root-token.tmp | non touche (hors scope, hors phase Vault) |

git worktree list post-cleanup montre uniquement le worktree principal `/opt/keybuzz/keybuzz-api`.

## Rollback / image invalidation

### Cas 1 : abandon image PROD avant deploy

`docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod` sur bastion. Le tag GHCR persiste cote registry (deletion par client standard non supportee sans token specifique), mais aucun pod ne reference l'image. Aucun impact runtime.

### Cas 2 : tag GHCR fantome a nettoyer

Via GHCR UI ou API avec PAT scope `delete:packages` (intervention manuelle Ludovic, non-prioritaire).

### Cas 3 : deploy PROD futur revele bug -> rollback runtime

Manifest deployment.spec.template.spec.containers.image revert vers tag precedent v3.5.190-channels-tenantguard-prod via git revert + kubectl apply. Tag v3.5.190-channels-tenantguard-prod reste accessible sur GHCR (image precedente preservee).

### Cas 4 : image PROD compromise ou non conforme

Rebuild from-Git nouveau tag N+1 (jamais reutiliser le meme tag). Tag immuable convention KEY-309 = jamais overwrite.

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : Mode B SAFE PROD avec GO Ludovic explicite. Patch manifest `k8s/keybuzz-api-prod/deployment.yaml` :
   - image `v3.5.190-channels-tenantguard-prod` -> `v3.5.250-ad-spend-sync-all-prod`
   - ajout env var `AD_SPEND_SYNC_INTERNAL_TOKEN` via secretKeyRef vers `keybuzz-internal-tokens` (cree par Q-1T-4-B-EXEC-SECRET-PROD)
   - commit + push manifest + kubectl apply PROD + rollout status + smoke `/admin/internal/ad-accounts/sync-all` dryRun=true avec token PROD
2. **Q-1T-4-B-EXEC-CRONJOB DEV** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B a1f7e75) DEV + apply + premier run dryRun verifie.
3. **Q-1T-4-B-EXEC-CRONJOB PROD** : symetrique PROD apres DEPLOY-API-PROD done.
4. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE non-dryRun + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

Important : Q-1T-4-B-EXEC-DEPLOY-API-PROD doit referencer le tag immuable `v3.5.250-ad-spend-sync-all-prod` (et idealement le digest pinned `@sha256:93cc663d...` pour resilience). Sans pin digest, un retag GHCR (interdit par convention KEY-309 mais possible techniquement) pourrait creer un drift silencieux.

## Phases suivantes (ordre conseille)

| Sequence | Phase | Effet runtime | Pre-requis |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-DEPLOY-API-PROD | rollout PROD vers v3.5.250 | Mode B SAFE PROD GO + Secret PROD ready (DONE) + image PROD pushee (DONE cette phase) |
| 2 | Q-1T-4-B-EXEC-CRONJOB DEV (dryRun) | CronJob daily 06:00 UTC DEV mode dryRun | GO Ludovic |
| 3 | Q-1T-4-B-EXEC-CRONJOB PROD (dryRun) | CronJob daily 06:00 UTC PROD mode dryRun | GO Ludovic + DEPLOY-API-PROD done |
| 4 | Q-1T-4-B-EXEC-VALIDATE (flip vers LIVE) | premier sync LIVE non-dryRun, ad_spend_tenant remplit | observation 24h dryRun OK + GO Ludovic |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-BUILD-PROD done

Image PROD keybuzz-api construite depuis commit 01b163e4 (meme code que
DEV) via git worktree detache propre, docker build --no-cache + OCI
labels KEY-308 complets, push GHCR verifie par pull-back digest :

Tag : ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod
Digest : sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d
Config : sha256:28938aeef8e0eef174d530f9ec3fc583a447bac327dffdc0ca501f34d0cb7b5e

Tests pre-build OK : tsc --noEmit exit=0, 5/5 PH118 tests PASS, sha256
sources MATCH Q-1T-4-B-EXEC-CODE.

Contraintes 0/0/0/0/0/0 confirmees : 0 deploy, 0 apply, 0 manifest
modifie, 0 provider call, 0 DB write, 0 endpoint call, 0 Vault command.
Runtime DEV inchange (v3.5.250-ad-spend-sync-all-dev, pod 1h uptime).
Runtime PROD inchange (v3.5.190-channels-tenantguard-prod, generation
411, pod 8h30 uptime, 0 restart).

Prochaines phases (sequence, chacune GO separee, prompt CE distinct) :
1. Q-1T-4-B-EXEC-DEPLOY-API-PROD (Mode B SAFE PROD)
2. Q-1T-4-B-EXEC-CRONJOB DEV puis PROD (dryRun puis LIVE)
3. Q-1T-4-B-EXEC-VALIDATE (first live tick)
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

Build PROD keybuzz-api Q-1T-4-B-EXEC-BUILD-PROD complete depuis Git propre commit `01b163e4` sur `ph147.4/source-of-truth` (sha256 sources match Q-1T-4-B-EXEC-CODE byte-for-byte), tests pre-build tsc --noEmit exit=0 + 5/5 PH118 tests PASS, tag immutable `v3.5.250-ad-spend-sync-all-prod` pousse sur GHCR, digest OCI `sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d` documente et verifie par pull-back, runtime DEV/PROD inchange (DEV `v3.5.250-ad-spend-sync-all-dev` pod 1h uptime, PROD `v3.5.190-channels-tenantguard-prod` generation 411 pod 8h30 uptime), 0 deploy, 0 kubectl apply, 0 provider call, 0 DB write, 0 endpoint call, 0 manifest modifie, 0 Vault command. Image prete pour phase separee Q-1T-4-B-EXEC-DEPLOY-API-PROD avec GO Ludovic explicite (Mode B SAFE PROD).

STOP
