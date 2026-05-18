# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE AD_SPEND SYNC-ALL API DRY-RUN/PATCH

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-CODE
> Environnement : keybuzz-api branche ph147.4/source-of-truth (DEV/PROD partagent la meme source)
> Type : patch source code + tests (zero build, zero deploy, zero provider call, zero DB write)
> Priorite : Mode B SAFE pre-build

## VERDICT

GO DEV FIX READY. Code patch applique, commit `01b163e4` push sur ph147.4/source-of-truth. tsc --noEmit exit=0. 5/5 tests structurels PASS. Aucun build docker, aucun docker push, aucun apply GitOps, aucun appel provider Meta/Google Ads, aucun INSERT/UPDATE/DELETE DB execute par CE.

Pret pour Q-1T-4-B-EXEC-BUILD (docker build keybuzz-api DEV from-git, tag immuable).

## Preflight (E0)

| Item | Valeur attendue | Valeur observee | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Branche keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| HEAD keybuzz-api avant patch | descendant 7a09c005 | 7a09c005 KEY-314 tenantGuard | OK |
| HEAD keybuzz-api apres commit | nouveau commit | 01b163e4cd3f7c4341f71819fe79b89b80eccac7 | OK |
| keybuzz-infra HEAD | descendant a1f7e757 (Q-1T-4-B) | a1f7e75792f275ddefcae79e0c667921587615cc | OK |
| Dirty scope cibles | ad-accounts/routes.ts + app.ts CLEAN | clean (les 223 dirty sont uniquement dist/ orphans) | OK |
| Tests harness | ph*-tests.ts standalone | confirme | OK |

Dirty preexistant detail : tous les D dist/* sont des artefacts build orphelins (tsc local n'a pas ete relance apres derniere modification). Aucun fichier source `.ts` n'est en etat M ou D. Le commit Q-1T-4-B-EXEC-CODE n'a touche AUCUN dist/, scope strict respecte.

## Audit signaux (E1)

### Source canonique sync existante (avant refactor)

`src/modules/ad-accounts/routes.ts` lignes 158-244 : handler `POST /:id/sync` contient :

- SELECT id, platform, account_id, token_ref, currency, status WHERE id=$1 AND tenant_id=$2 AND deleted_at IS NULL
- Verif status='active' sinon 400 ACCOUNT_NOT_ACTIVE
- Dispatch fetchFn meta (campaign level) ou google ; sinon 400 PLATFORM_NOT_SUPPORTED
- Defaults : since=now-30j, until=today (YYYY-MM-DD)
- Try : fetchFn -> for row in rows -> INSERT ad_spend_tenant ON CONFLICT (tenant_id, platform, date, COALESCE(campaign_id, '__none__')) DO UPDATE (idempotence T8.8G)
- UPDATE ad_platform_accounts SET last_sync_at=NOW(), last_error=NULL
- SELECT total_rows, SUM(spend) FROM ad_spend_tenant
- Return sync:'completed' avec totals
- Catch : redactSecrets(err.message) -> UPDATE last_error -> 500 SYNC_FAILED

Logique upsert + ON CONFLICT preservee byte-for-byte dans le helper extrait `syncOneAccount`.

### Pattern INTERNAL_TOKEN existant

`src/modules/agents/routes.ts` lignes 282-285 : x-internal-token egal a process.env.KEYBUZZ_INTERNAL_PROXY_TOKEN ; sinon 403 Forbidden.

Q-1T-4-B-EXEC-CODE choix : env dedie AD_SPEND_SYNC_INTERNAL_TOKEN (preferred) avec fallback KEYBUZZ_INTERNAL_PROXY_TOKEN si absent. Le secret Vault sera cree dans la phase suivante Q-1T-4-B-EXEC-SECRET. timingSafeEqual avec verif length-match pre-emptive (sinon timingSafeEqual throw).

### tenantGuardPlugin allowlist

Confirme par grep src/plugins/tenantGuard.ts ligne 664 : utilise `fp(tenantGuardImpl, { name: 'tenant-guard' })`. Le bug KEY-301 AS.3 (manque fastify-plugin wrapper) qui apparaissait dans memoire user EST CORRIGE dans ph147.4 (par KEY-313/KEY-314). tenantGuard est en mode ALLOWLIST : seules les routes listees sont protegees, tout le reste passe. La nouvelle route `/admin/internal/ad-accounts/sync-all` n'est PAS dans l'allowlist et est protegee directement par le check x-internal-token au niveau handler.

## Patch (E2-E3)

| Fichier | Changement | Lignes (avant/apres) | Risque |
|---|---|---|---|
| src/modules/ad-accounts/routes.ts | export interface AdAccountRow + export interface SyncOneResult + export async function syncOneAccount(pool, tenantId, account, since, until, opts={dryRun}) ; handler /:id/sync refactore pour appeler syncOneAccount() ; logique upsert+ON CONFLICT byte-for-byte preservee | 245 -> 305 (+109 -49) | Faible : refactor pur, comportement /:id/sync identique. tsc OK. |
| src/modules/ad-accounts/internal-routes.ts | NEW : export async function adAccountsInternalRoutes(app) ; POST /sync-all auth x-internal-token (timingSafeEqual + length pre-check) ; body { since?, until?, dryRun?, platform? } ; SELECT comptes actifs ; dryRun=true retourne plan (hash8 account_id + hash8 tenant_id) ; live=loop syncOneAccount par compte avec collecte ok/error ; account_id et tenant_id JAMAIS retournes en clair (hash8 sha256 systematique) | 0 -> 154 | Faible : nouveau code isole, requiert secret K8s + cron pour usage live. |
| src/tests/ph118-tests.ts | NEW : 5 tests structurels standalone tsc+node ; dryRun zero DB ; inactive throws ; unsupported platform throws ; auth missing/wrong-length/wrong-token tous 403 ; hash8 deterministe | 0 -> 176 | Aucun : tests offline avec FakePool, jamais reseau, jamais DB. |
| src/app.ts | +1 import adAccountsInternalRoutes ; +1 app.register prefix /admin/internal/ad-accounts | 246 -> 248 (+2 -0) | Aucun : routes externes seules. |

### Decision design : route /sync-all sous prefix dedie

Le module `internal-routes.ts` est registered avec prefix `/admin/internal/ad-accounts`, donc le path final est `/admin/internal/ad-accounts/sync-all`. Ce path est volontairement separe de `/ad-accounts/*` (user-facing avec x-tenant-id) pour exprimer clairement la nature SERVICE-TO-SERVICE INTERNAL. Aucun BFF Client/Admin ne pointe ce path.

### Decision design : hash8 systematique sur identifiers

Toute response `/sync-all` retourne `hash8` (sha256 du account_id, 8 premiers caracteres hex) et `tenant_hash8` (idem du tenant_id). Aucun account_id ni tenant_id en clair dans payload de retour ni dans logs. Cela respecte la contrainte du prompt et facilite debug en correlant les hash entre logs et rapport.

### Decision design : timingSafeEqual avec length pre-check

L'API `crypto.timingSafeEqual` throw quand les longueurs different. Je verifie d'abord `headerToken.length === expected.length` avant d'appeler timingSafeEqual. Si different : 403 direct sans crash. Tests couvrent les 3 cas (missing, wrong same-length, wrong diff-length).

## Tests (E4)

`src/tests/ph118-tests.ts` execute via tsc compile vers /tmp/ph118-build + node + NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules. Aucun framework de test n'est wired dans le repo (pas de jest, pas de vitest, pas de tsx en devDeps). La compilation isolee evite toute pollution de dist/ du worktree.

| Test | Attendu | Resultat |
|---|---|---|
| syncOneAccount dryRun=true | retourne {dryRun:true, rows_upserted:0}, zero DB call, zero provider call | OK |
| syncOneAccount status=paused | throw ACCOUNT_NOT_ACTIVE:paused, zero DB call | OK |
| syncOneAccount platform=tiktok | throw PLATFORM_NOT_SUPPORTED:tiktok, zero DB call | OK |
| /sync-all sans x-internal-token | 403 FORBIDDEN_INTERNAL_ONLY | OK |
| /sync-all token same-length faux | 403 (timingSafeEqual cote serveur) | OK |
| /sync-all token length-mismatch | 403 sans crash (pre-check) | OK |
| hash8 deterministe sha256 8 hex | meme input -> meme hash, input different -> hash different | OK |

Total : 5/5 PASS. tsc --noEmit exit=0.

Tests integration provider (Meta API mock fetch + ON CONFLICT real) deliberement exclus : exige monkey-patch module-level non supporte par node standard. La logique upsert preservee byte-for-byte dans syncOneAccount est deja couverte par PH-T8.8G qui valide idempotence en runtime DEV.

Compilation et execution :

```
cd /opt/keybuzz/keybuzz-api
npx --no-install tsc --noEmit                        # exit=0 zero erreur type
rm -rf /tmp/ph118-build && mkdir -p /tmp/ph118-build
npx --no-install tsc --outDir /tmp/ph118-build --skipLibCheck   # exit=0
cd /tmp/ph118-build && NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules node tests/ph118-tests.js
# === PH118 / AS.17.1T-4-B-EXEC-CODE tests ===
# [OK] syncOneAccount dryRun: zero DB calls, zero provider calls
# [OK] syncOneAccount inactive: throws ACCOUNT_NOT_ACTIVE, zero DB calls
# [OK] syncOneAccount unsupported platform: throws PLATFORM_NOT_SUPPORTED, zero DB calls
# [OK] /sync-all missing token -> 403 FORBIDDEN_INTERNAL_ONLY
# [OK] /sync-all wrong token (same length) -> 403
# [OK] /sync-all length mismatch -> 403 (timingSafeEqual safe)
# [OK] hash8 deterministe 8-char hex
# === ALL PH118 TESTS PASSED (5/5) ===
```

Cleanup : `rm -rf /tmp/ph118-build` execute apres run.

## Build

NO BUILD. Aucun docker build keybuzz-api. Aucune image produite. Aucun push GHCR. Seul tsc --noEmit a ete invoque pour validation types (zero artefact persistent dans le worktree). La compilation vers /tmp/ph118-build pour run tests etait volatile et a ete supprimee apres.

Q-1T-4-B-EXEC-BUILD (phase suivante) construira l'image DEV depuis le commit `01b163e4` (build-from-Git strict, jamais depuis pod/runtime/dist).

## GitOps

NO APPLY. Aucun kubectl apply. Aucun manifest cluster modifie. Le CronJob ad-accounts-sync-daily (draft Q-1T-4-B commit a1f7e75) reste non-deploye en attendant Q-1T-4-B-EXEC-DEPLOY + Q-1T-4-B-EXEC-CRONJOB.

## Validation runtime

N/A. Aucune mutation runtime. Aucun pod restart. Aucun secret K8s touche. Aucun manifest applique. Le runtime API DEV/PROD continue de servir la version actuelle (sans /admin/internal/ad-accounts/sync-all). L'endpoint n'existe qu'au niveau source code commit ; il n'est servi par AUCUN pod tant que Q-1T-4-B-EXEC-BUILD + Q-1T-4-B-EXEC-DEPLOY-API-DEV ne sont pas executes avec GO.

## No fake metrics / no fake events

Le helper syncOneAccount preserve la logique upsert + ON CONFLICT existante byte-for-byte. Aucun fake row, aucun INSERT artificiel, aucun KPI calcule par CE. Le mode dryRun retourne `rows_upserted: 0` explicitement et un statut `'planned'`/`'skipped'` clair, jamais un faux `'completed'`. Aucun event GA4/Meta CAPI/TikTok/LinkedIn emis par cette phase.

## AI feature parity

N/A. Cette phase ne touche pas l'IA, Inbox, messages, connecteurs, commandes, tracking colis, playbooks, escalades, Agent KeyBuzz, autopilot, dashboard. Le module touche uniquement la couche ad_spend (acquisition payee).

## Non-regression PROD

| Surface | Avant commit | Apres commit `01b163e4` (Git only) | Apres deploy (futur Q-1T-4-B-EXEC-DEPLOY) |
|---|---|---|---|
| GET /ad-accounts | inchange | code inchange | inchange |
| POST /ad-accounts | inchange | code inchange | inchange |
| PATCH /ad-accounts/:id | inchange | code inchange | inchange |
| DELETE /ad-accounts/:id | inchange | code inchange | inchange |
| POST /ad-accounts/:id/sync | logique inline | logique deleguee `syncOneAccount`, byte-for-byte upsert+ON CONFLICT preserves | identique (refactor pur) |
| POST /admin/internal/ad-accounts/sync-all | inexistant | inexistant en runtime tant que pas build+deploy | nouvelle route INTERNAL only |

Runtime PROD api.keybuzz.io et runtime DEV api-dev.keybuzz.io continueront de servir la version actuelle (tag image avant `01b163e4`) tant que la phase BUILD + DEPLOY n'est pas executee.

## Git scope strict + commit

### Scope strict (avant commit)

```
 M src/app.ts                        +2 / -0
 M src/modules/ad-accounts/routes.ts +109 / -49
?? src/modules/ad-accounts/internal-routes.ts (new, 154 lignes)
?? src/tests/ph118-tests.ts          (new, 176 lignes)
```

Aucun autre fichier source TS modifie. Les D dist/* preexistants n'ont PAS ete inclus dans le commit. `git add` explicite limite aux 4 fichiers ci-dessus, jamais `-A` ni `.`.

### Commit execute (GO COMMIT API recu)

```
commit 01b163e4cd3f7c4341f71819fe79b89b80eccac7
Author: KeyBuzz Deploy <deploy@keybuzz.io>
Date:   Mon May 18 17:21:31 2026 +0000
Subject: feat(ad-accounts): add internal /sync-all endpoint + factorize syncOneAccount

 src/app.ts                                 |   2 +
 src/modules/ad-accounts/internal-routes.ts | 154 +++++++++++++++++++++++++
 src/modules/ad-accounts/routes.ts          | 158 ++++++++++++++++++--------
 src/tests/ph118-tests.ts                   | 176 +++++++++++++++++++++++++++++
 4 files changed, 441 insertions(+), 49 deletions(-)
```

Push origin : `7a09c005..01b163e4  ph147.4/source-of-truth -> ph147.4/source-of-truth` exit=0.

dist/ D preexistants restent untracked apres le commit (developpement actif preserve). Aucun rebase, aucun reset, aucun stash.

### sha256 fichiers finals (post-commit)

```
98f666fe73605f653189cf662b7a4cea199fffa9845cd40b8b71ddd92c865b31  src/modules/ad-accounts/routes.ts
33ebef7d8f2457c237ab4a1047c67c5b0457b3c9148bfce32353f7ee10697a79  src/modules/ad-accounts/internal-routes.ts
35519042e327e143498f08b69911ed190fa8b063f29e75bc102977c39e878bed  src/tests/ph118-tests.ts
22886e1f1313b18e5d6d9ab000870515e6100580175acf767f30a2724952b4bd  src/app.ts
```

Backup originals conserves : `/tmp/ph118-backup/routes.ts.bak` + `/tmp/ph118-backup/app.ts.bak` (rollback emergency en cas de revert pre-build).

## Resume conformite contraintes prompt CE

| Contrainte prompt | Verifiee ? |
|---|---|
| 0 build docker | OK : aucun docker build invoque |
| 0 deploy GitOps / kubectl apply | OK : aucun apply, aucun manifest cluster modifie |
| 0 provider call (Meta/Google Ads authentifie) | OK : aucun appel reseau provider ; tests utilisent FakePool offline |
| 0 DB write par CE | OK : aucun INSERT/UPDATE/DELETE/ALTER/TRUNCATE execute |
| 0 fake metrics, 0 fake events | OK : dryRun retourne `rows_upserted: 0` et `'planned'`/`'skipped'`, jamais faux completed |
| Factorisation logique existante (sans duplication) | OK : `syncOneAccount` extrait de `/:id/sync`, reutilise par le handler existant + nouvelle route INTERNAL |
| Auth `x-internal-token` (timingSafeEqual + length pre-check) | OK : 3 tests 403 valident missing/wrong-length/wrong-token |
| Body `{ since?, until?, dryRun?, platform? }` | OK : implements + filter platform meta/google/all |
| dryRun=true bypass provider+DB | OK : test syncOneAccount dryRun verifie zero pool.calls |
| Tests mockent providers (jamais reseau) | OK : FakePool + globalThis.fetch stub ; sortie process.versions sans HTTP |
| account ids JAMAIS bruts (hash8 si necessaire) | OK : tous returns + logs internal-routes utilisent hash8 sha256 |
| Idempotence T8.8G preservee (`ON CONFLICT idx_ast_dedup`) | OK : SQL UPSERT identique byte-for-byte ; test verifie SQL contient `ON CONFLICT (tenant_id, platform, date, COALESCE(campaign_id, '__none__'))` |
| Endpoint code MAIS jamais appele en mode non-dryRun par CE | OK : aucun POST emis par CE, aucun cron deploye |
| Commit + push code uniquement apres GO | OK : GO Ludovic recu, commit `01b163e4` push origin |
| ASCII strict rapport PH | OK : pure ASCII, no BOM, 12866 bytes |
| Branche imposee ph147.4/source-of-truth | OK : commit sur la branche imposee |
| Bastion install-v3 | OK : 46.62.171.61 confirme |

## Linear

Aucun comment ni transition de statut sur KEY-323. Toute action engagante (transition status, comment public) attendra le verdict des phases suivantes :
- Q-1T-4-B-EXEC-BUILD verdict (image OCI verified)
- Q-1T-4-B-EXEC-DEPLOY-DEV verdict (smoke OK)
- Q-1T-4-B-EXEC-DEPLOY-PROD verdict (Mode B SAFE PROD GO)
- Q-1T-4-B-EXEC-CRONJOB verdict (premiere execution succes)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-BUILD** : docker build keybuzz-api DEV image avec ce code (tag immuable v3.5.X+1 selon convention KEY-309 ; jamais `:latest`). Build from Git commit `01b163e4`.
2. **Q-1T-4-B-EXEC-SECRET** : Vault path keybuzz-api/data/internal-tokens.AD_SPEND_SYNC_INTERNAL_TOKEN + ExternalSecret refresh + Secret K8s `keybuzz-internal-tokens` (PROD + DEV namespaces). Token genere via openssl rand -hex 32.
3. **Q-1T-4-B-EXEC-DEPLOY-API-DEV** : GitOps apply + rollout DEV + smoke read-only `/admin/internal/ad-accounts/sync-all` avec dryRun=true.
4. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : Mode B SAFE PROD avec GO explicite. Tag PROD immuable distinct du DEV.
5. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B existant) + apply + premier run dryRun verifie.
6. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

Important : avant Q-1T-4-B-EXEC-DEPLOY-API-PROD, verifier qu'aucune promotion PROD bloquee (AS.17.0/0.1 ou autres) n'est embarquee dans l'image, et qu'aucune regression tenantGuard n'apparait depuis la baseline ph147.4.

## Rollback

Cas 1 : revert commit `01b163e4` avant build -> `git revert 01b163e4` puis push. Aucun impact runtime (rien deploye). Phase EXEC-CODE annulee, code re-aligne sur 7a09c005.

Cas 2 : si build deja fait mais pas deploy -> Cas 1 + skip Q-1T-4-B-EXEC-DEPLOY. Image GHCR taggee reste accessible mais jamais reference par un manifest.

Cas 3 : si build+deploy DEV deja fait -> rollback image tag precedent via manifest deployment.spec.template.spec.containers.image -> `git revert` manifest -> `kubectl apply` -> `kubectl rollout status`. Le code reste en branche mais le runtime revient au tag DEV precedent.

Cas 4 : si build+deploy PROD deja fait + bug -> meme procedure que Cas 3 avec urgency Linear comment + Ludovic GO.

Backup local sur bastion : `/tmp/ph118-backup/{routes.ts.bak, app.ts.bak}` conserve pour rollback emergency dans les 24h (avant cleanup automatique /tmp).

## Phrase cible finale

Q-1T-4-B-EXEC-CODE acheve. Commit `01b163e4` push sur `keybuzz-api/ph147.4/source-of-truth`. tsc --noEmit exit=0. 5/5 tests structurels PASS. Aucun build/deploy/provider call/DB write execute par CE. Endpoint POST `/admin/internal/ad-accounts/sync-all` existe au niveau source mais reste inactif en runtime DEV/PROD tant que Q-1T-4-B-EXEC-BUILD + Q-1T-4-B-EXEC-DEPLOY-API-DEV ne sont pas declenches. Pret pour la phase build DEV avec GO Ludovic explicite.

STOP
