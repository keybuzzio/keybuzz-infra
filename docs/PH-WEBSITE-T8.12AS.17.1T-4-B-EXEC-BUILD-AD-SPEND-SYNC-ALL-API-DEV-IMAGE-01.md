# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD AD_SPEND SYNC-ALL API DEV IMAGE BUILD

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-BUILD
> Environnement : keybuzz-api branche ph147.4/source-of-truth, image DEV uniquement
> Type : docker build + push GHCR (zero deploy, zero apply, zero manifest modifie)
> Priorite : Mode B SAFE pre-deploy

## VERDICT

GO DEV FIX READY. Image keybuzz-api DEV `v3.5.250-ad-spend-sync-all-dev` construite depuis Git commit `01b163e4` propre (git worktree detache), push GHCR reussi, digest sha256 `8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b` capture et verifie. Tests pre-build PASS (tsc + 5/5 PH118). OCI labels KEY-308 complets et preserves apres push. Aucun deploy, aucun apply, aucun manifest modifie, aucun rollout, aucun appel provider, aucune ecriture DB executes par CE.

Pret pour Q-1T-4-B-EXEC-DEPLOY-DEV (GitOps apply + rollout DEV + smoke read-only dryRun=true) avec GO Ludovic explicite.

## Preflight (E0)

| Item | Valeur attendue | Valeur observee | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Branche keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| HEAD keybuzz-api | descendant 01b163e4 | 01b163e4 (HEAD itself) | OK |
| keybuzz-infra HEAD | descendant 22f1144 (rapport Q-1T-4-B-EXEC-CODE) | 22f1144 | OK |
| Dirty scope cibles | aucun fichier source TS modifie | clean (les 223 dirty sont dist/ orphans, hors scope build) | OK |
| Docker | >= 24 | Docker version 29.1.3 | OK |
| GHCR auth | ghcr.io configure | ghcr.io auth present dans /root/.docker/config.json | OK |
| Dockerfile present | multi-stage avec ARG IMAGE_REVISION/CREATED/VERSION (KEY-308) | Dockerfile present, OCI labels via ARG | OK |

## Audit signaux (E1 pre-build)

### tsc --noEmit re-run

```
cd /opt/keybuzz/keybuzz-api
npx --no-install tsc --noEmit
```

Resultat : exit=0, zero erreur de type.

### Tests PH118 re-run

```
mkdir -p /tmp/ph118-build-precheck
npx --no-install tsc --outDir /tmp/ph118-build-precheck --skipLibCheck
cd /tmp/ph118-build-precheck
NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules node tests/ph118-tests.js
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

Cleanup precheck : `rm -rf /tmp/ph118-build-precheck` execute. Resultat : 5/5 PASS. Pre-conditions build OK.

## Tag determination (E2)

### Convention KEY-309

Pattern observe dans rapports recents (PH-T8.12AS.13.1, PH-T8.12AS.14.1, PH-T8.12AS.13.2A, etc.) :

```
v3.5.<N>-<slug-descriptif>-<env>
```

- N : entier croissant globalement (peut etre reutilise entre features distinctes, mais slug discrimine)
- slug : descriptif kebab-case de la feature ou phase
- env : `dev` ou `prod`

### Runtime actuel

| Service | Image actuelle | Tag N |
|---|---|---|
| keybuzz-api DEV (keybuzz-api-dev) | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev | 190 |
| keybuzz-api PROD (keybuzz-api-prod) | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod | 190 |
| keybuzz-outbound-worker DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev | 165 |
| keybuzz-outbound-worker PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod | 165 |

### Tags GHCR recents

Plus haut N observe dans registry GHCR `keybuzzio/keybuzz-api` : 243 (v3.5.243-ph145.4-amz-ui-status-fix-dev). Sample listing premieres 1000 entrees inclut v3.5.240..243 (ph145* lignee). Tags plus recents (v3.5.249, v3.5.237-239) mentionnes dans rapports mais possiblement dans page suivante de pagination.

### Choix tag

Tag DEV retenu : **v3.5.250-ad-spend-sync-all-dev**.

- N = 250 (au-dela du max observe 243, slack pour eviter collision avec tags non listes)
- slug = `ad-spend-sync-all` (descriptif endpoint nouveau)
- env = `dev`

### Collision check

Verification via `docker manifest inspect` :

```
v3.5.250-ad-spend-sync-all-dev : ABSENT (safe a utiliser)
v3.5.249-ad-spend-sync-all-dev : ABSENT (safe a utiliser)
v3.5.251-ad-spend-sync-all-dev : ABSENT (safe a utiliser)
```

Tag immuable retenu : `v3.5.250-ad-spend-sync-all-dev`.

Tag PROD futur (Q-1T-4-B-EXEC-DEPLOY-PROD, distinct meme code) : `v3.5.250-ad-spend-sync-all-prod`.

## Build (E3)

### Isolation propre via git worktree

Plutot que builder depuis le worktree principal `/opt/keybuzz/keybuzz-api` (223 dist/ orphans non modifies mais presents), creation d'un worktree detache propre :

```
cd /opt/keybuzz/keybuzz-api
git worktree add --detach /tmp/build-ph118 01b163e4
```

Le worktree resulte (`/tmp/build-ph118`) :
- HEAD : 01b163e4cd3f7c4341f71819fe79b89b80eccac7
- git status : (vide, parfaitement clean)
- aucun dist/ orphan, aucun fichier non commit

### Verif sha256 sources dans worktree de build

```
98f666fe73605f653189cf662b7a4cea199fffa9845cd40b8b71ddd92c865b31  src/modules/ad-accounts/routes.ts
33ebef7d8f2457c237ab4a1047c67c5b0457b3c9148bfce32353f7ee10697a79  src/modules/ad-accounts/internal-routes.ts
35519042e327e143498f08b69911ed190fa8b063f29e75bc102977c39e878bed  src/tests/ph118-tests.ts
22886e1f1313b18e5d6d9ab000870515e6100580175acf767f30a2724952b4bd  src/app.ts
```

Identique au commit `01b163e4` (cross-check Q-1T-4-B-EXEC-CODE rapport).

### Commande docker build

```
TAG="v3.5.250-ad-spend-sync-all-dev"
REV="01b163e4cd3f7c4341f71819fe79b89b80eccac7"
CREATED="2026-05-18T17:38:58Z"

docker build \
  --no-cache \
  --build-arg IMAGE_REVISION="$REV" \
  --build-arg IMAGE_CREATED="$CREATED" \
  --build-arg IMAGE_VERSION="$TAG" \
  -t ghcr.io/keybuzzio/keybuzz-api:$TAG \
  .
```

Resultat : `Successfully built 17762eed8802` + `Successfully tagged ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev`. Exit=0.

### Inspection image locale

| Champ | Valeur |
|---|---|
| Image ID local | `sha256:17762eed88028cbef4b33c6703f50148708921cb325a76a0b83025543970a8cb` |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev` |
| Architecture | amd64 |
| Size | 343,490,798 bytes (327.6 MB) |
| OCI label revision | `01b163e4cd3f7c4341f71819fe79b89b80eccac7` |
| OCI label created | `2026-05-18T17:38:58Z` |
| OCI label version | `v3.5.250-ad-spend-sync-all-dev` |
| OCI label source | `https://github.com/keybuzzio/keybuzz-api` |
| OCI label title | `keybuzz-api` |

### Verification dist/ compile dans image

```
docker run --rm --entrypoint sh ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev \
  -c "ls dist/modules/ad-accounts/ ; node -e 'console.log(Object.keys(require(\"/app/dist/modules/ad-accounts/internal-routes\")))'"
```

Sortie :

```
internal-routes.js
routes.js
[ 'adAccountsInternalRoutes' ]
```

L'endpoint compile est present dans l'image, export verifie.

### Cleanup worktree

```
cd /opt/keybuzz/keybuzz-api
git worktree remove --force /tmp/build-ph118
```

Apres cleanup : `git worktree list` retourne uniquement le worktree principal `/opt/keybuzz/keybuzz-api`.

## Push GHCR + verification (E4-E5)

### docker push

```
docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev
```

Output final :

```
v3.5.250-ad-spend-sync-all-dev: digest: sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b size: 2416
push exit=0
```

5 layers nouvelles pushed (9e6b13a63704, 969ca816bd34, 9a5cc19b6013, 01bc30c03837, c61220512eb0, 6514d666d85a), 5 layers existaient deja (base node:lts-alpine + curl deps reutilises).

### Digest sha256 capture

**Manifest digest (immuable, source de verite GitOps)** :

```
sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b
```

**Config digest (Image ID)** :

```
sha256:17762eed88028cbef4b33c6703f50148708921cb325a76a0b83025543970a8cb
```

### docker manifest inspect remote verify

```
docker manifest inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev --verbose
```

Champs cles :

| Champ | Valeur |
|---|---|
| Descriptor.digest | `sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b` |
| Descriptor.size | 2416 |
| mediaType | application/vnd.docker.distribution.manifest.v2+json |
| schemaVersion | 2 |
| config.digest | `sha256:17762eed88028cbef4b33c6703f50148708921cb325a76a0b83025543970a8cb` |
| layers count | 10 |
| total layer size | 112,041,252 bytes (106.9 MB compressed) |

### Pull-back validate (reproductibilite par digest)

```
docker pull ghcr.io/keybuzzio/keybuzz-api@sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b
```

Sortie :

```
Digest: sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b
Status: Image is up to date
```

Le pull-back par digest resoud sur l'image locale deja construite : sha256 manifest immuable confirme. OCI labels preserves apres pull-back (revision/created/version/source/title identiques).

### Cross-check local vs remote

```
docker inspect ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev --format \
  "{{.RepoDigests}} {{.Id}} {{.Created}}"
```

Output :

```
[ghcr.io/keybuzzio/keybuzz-api@sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b]
sha256:17762eed88028cbef4b33c6703f50148708921cb325a76a0b83025543970a8cb
2026-05-18T17:40:10.834324049Z
```

RepoDigest local = digest remote. Image ID local = config digest remote.

## NO-DEPLOY / NO-APPLY confirmation (E5.4)

### Runtime DEV/PROD inchange

| Namespace | Deployment | Image runtime apres push | Etat attendu |
|---|---|---|---|
| keybuzz-api-dev | keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev | INCHANGE (precedent) |
| keybuzz-api-prod | keybuzz-api | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod | INCHANGE (precedent) |

### Pods uptime preserve

| Namespace | Pod | Etat | Age | Restart cause Q-1T-4-B-EXEC-BUILD ? |
|---|---|---|---|---|
| keybuzz-api-dev | keybuzz-api-587774dbb6-rzzmq | 1/1 Running | 44h | NON |
| keybuzz-api-prod | keybuzz-api-5874f4d576-4zr29 | 1/1 Running | 4h45m | NON |

Aucun rollout, aucun restart cote runtime. Les pods continuent de servir l'image precedente `v3.5.190-channels-tenantguard-{dev,prod}`.

### Manifests GitOps inchanges

```
cd /opt/keybuzz/keybuzz-infra
git status --short  # (vide)
git log -1 --oneline  # 22f1144 docs(Q-1T-4-B): EXEC-CODE rapport patch ad_spend sync-all endpoint
```

Aucun manifest modifie. HEAD keybuzz-infra reste sur le commit precedent (rapport Q-1T-4-B-EXEC-CODE). Aucun `kubectl apply -f`, aucun `kubectl set image`, aucun `kubectl patch`, aucun `kubectl edit` execute.

### Provider / DB / Secrets / CronJob

| Action | Execute par CE ? |
|---|---|
| Appel Meta Ads API (graph.facebook.com) | NON |
| Appel Google Ads API (googleads.googleapis.com) | NON |
| POST /admin/internal/ad-accounts/sync-all (DEV ou PROD) | NON |
| POST /ad-accounts/:id/sync | NON |
| INSERT/UPDATE/DELETE/ALTER/TRUNCATE DB (postgres keybuzz / keybuzz_backend) | NON |
| Creation/modification Secret K8s | NON |
| Creation/modification ExternalSecret | NON |
| Creation/modification Vault KV | NON |
| Creation/modification CronJob | NON |
| Modification namespace *-prod | NON |
| Modification ingress-nginx ou cert-manager | NON |

## No fake metrics / no fake events

Cette phase BUILD ne touche pas la donnee. Aucun event GA4/Meta CAPI/TikTok/LinkedIn emis. Aucune mutation `ad_spend_tenant`. Aucun KPI affiche/calcule. Le build produit un artefact statique (image OCI) dont le contenu est determine par le commit Git `01b163e4`.

## AI feature parity

N/A. Cette phase ne touche pas l'IA, Inbox, messages, connecteurs, commandes, tracking colis, playbooks, escalades, Agent KeyBuzz, autopilot, dashboard. Le build cree une image API dont le code embarque le nouveau endpoint ad_spend ; ce code n'a pas d'effet runtime tant que l'image n'est pas deployee.

## Non-regression PROD

| Surface | Avant push GHCR | Apres push GHCR (cette phase) | Apres deploy futur Q-1T-4-B-EXEC-DEPLOY-DEV |
|---|---|---|---|
| Runtime API DEV (keybuzz-api-dev) | v3.5.190-channels-tenantguard-dev | inchange | v3.5.250-ad-spend-sync-all-dev (futur) |
| Runtime API PROD (keybuzz-api-prod) | v3.5.190-channels-tenantguard-prod | inchange | inchange (DEV first) |
| Outbound worker DEV/PROD | v3.5.165-escalation-flow-* | inchange | inchange (separe) |
| Pods restart causes par CE | 0 | 0 | inevitable au rollout futur |
| Manifests keybuzz-infra | clean | clean | a editer au futur deploy |
| Image GHCR `:v3.5.250-ad-spend-sync-all-dev` | inexistante | NEW digest 8ee7ebad... | reference futur manifest |
| Endpoint `/admin/internal/ad-accounts/sync-all` runtime | inexistant | inexistant tant que pas deploy | servi par pods apres rollout |

## Resume conformite contraintes prompt CE

| Contrainte prompt | Verifiee ? |
|---|---|
| 0 deploy DEV | OK : aucun apply, runtime DEV image inchange |
| 0 deploy PROD | OK : aucun apply, runtime PROD image inchange |
| 0 kubectl apply | OK : aucun apply execute |
| 0 rollout | OK : pods DEV 44h uptime + PROD 4h45m uptime preserve |
| 0 manifest k8s modifie | OK : keybuzz-infra git status clean, HEAD inchange |
| 0 tag latest | OK : tag immuable `v3.5.250-ad-spend-sync-all-dev` |
| 0 build depuis workspace dirty | OK : build via `git worktree add --detach 01b163e4` clean |
| 0 build depuis pod/runtime/dist/SCP | OK : build depuis Git worktree detache, jamais depuis runtime ni dist deja existant |
| 0 appel provider Meta/Google Ads | OK : aucun appel reseau provider |
| 0 appel `/admin/internal/ad-accounts/sync-all` | OK : aucun POST emis vers cet endpoint |
| 0 creation Secret/Vault/ESO | OK : aucune mutation secret |
| 0 creation CronJob | OK : aucun manifest CronJob touche |
| 0 modification admin/client/website/backend | OK : seule l'image keybuzz-api est concernee |
| 0 commentaire Linear sans GO separe | OK : aucun comment ni transition de statut |
| Tag immuable convention KEY-309 | OK : `v3.5.<N>-<slug>-<env>` respecte, N=250 unique |
| Digest documente | OK : `sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b` |
| OCI labels KEY-308 complets | OK : revision/created/version/source/title presents et verifies apres pull-back |
| Source de build prouvee propre | OK : git worktree detache 01b163e4 + sha256 sources match |
| Source = commit 01b163e4 | OK : worktree HEAD = 01b163e4 + IMAGE_REVISION label = 01b163e4 |
| Bastion install-v3 | OK : 46.62.171.61 confirme |
| Branche imposee ph147.4/source-of-truth | OK : HEAD ph147.4 ancestor du build |

## Linear

Aucun comment ni transition de statut sur KEY-323. Toute action engagante attend les verdicts des phases suivantes :
- Q-1T-4-B-EXEC-SECRET verdict (Vault path + ESO + Secret K8s)
- Q-1T-4-B-EXEC-DEPLOY-DEV verdict (apply + smoke dryRun=true)
- Q-1T-4-B-EXEC-DEPLOY-PROD verdict (Mode B SAFE PROD GO)
- Q-1T-4-B-EXEC-CRONJOB verdict (premier run dryRun + live)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-SECRET** : Vault path keybuzz-api/data/internal-tokens.AD_SPEND_SYNC_INTERNAL_TOKEN + ExternalSecret refresh + Secret K8s `keybuzz-internal-tokens` (DEV puis PROD namespaces). Token genere via `openssl rand -hex 32` (32 bytes hex = 64 chars).
2. **Q-1T-4-B-EXEC-DEPLOY-API-DEV** : patch manifest `keybuzz-api-dev/deployment.yaml` image tag -> `v3.5.250-ad-spend-sync-all-dev` (digest pinned conseille) + commit infra + push + `kubectl apply -f` + `kubectl rollout status` + smoke `/admin/internal/ad-accounts/sync-all` dryRun=true avec le token interne.
3. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : build PROD tag `v3.5.250-ad-spend-sync-all-prod` (meme commit, tag distinct), Mode B SAFE PROD avec GO Ludovic explicite.
4. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B existant a1f7e75) + apply + premier run dryRun verifie.
5. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

Important : la phase Q-1T-4-B-EXEC-SECRET DOIT precedee Q-1T-4-B-EXEC-DEPLOY-DEV, sinon le pod demarrera sans `AD_SPEND_SYNC_INTERNAL_TOKEN` ni fallback `KEYBUZZ_INTERNAL_PROXY_TOKEN`, et toute requete `/sync-all` retournera 403 (comportement defensif desire mais bloque smoke).

## Rollback

Cas 1 : abandon image avant deploy -> `docker rmi ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev` sur le bastion. Le tag GHCR persiste (registry GHCR ne supporte pas la suppression de tag par client standard sans token specifique) mais aucun pod ne reference l'image. Aucun impact runtime.

Cas 2 : tag GHCR fantome a nettoyer -> via GHCR UI ou API avec PAT ayant scope `delete:packages` (intervention manuelle Ludovic, non-prioritaire).

Cas 3 : si deploy DEV deja fait + bug -> rollback image tag precedent via manifest deployment.spec.template.spec.containers.image -> `git revert` manifest -> `kubectl apply` -> `kubectl rollout status`. Le tag `v3.5.190-channels-tenantguard-dev` reste accessible sur GHCR pour rollback.

Cas 4 : si build s'avere casse en runtime post-deploy (panic startup) -> Cas 3 + Linear comment urgence + Ludovic GO.

## Phrase cible finale

Build DEV keybuzz-api Q-1T-4-B-EXEC-BUILD complete depuis Git propre commit `01b163e4` sur `ph147.4/source-of-truth`, tests pre-build tsc + PH118 5/5 PASS, tag immutable `v3.5.250-ad-spend-sync-all-dev` pousse sur GHCR, digest OCI `sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b` documente et verifie par pull-back, runtime DEV/PROD inchange (pods 44h+4h45m uptime preserve), 0 deploy, 0 kubectl apply, 0 provider call, 0 DB write, 0 manifest modifie. Image prete pour phase separee Q-1T-4-B-EXEC-SECRET puis Q-1T-4-B-EXEC-DEPLOY-DEV avec GO Ludovic explicite.

STOP
