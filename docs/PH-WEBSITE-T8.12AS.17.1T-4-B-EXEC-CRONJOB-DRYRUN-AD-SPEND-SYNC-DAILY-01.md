# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CRONJOB-DRYRUN AD_SPEND SYNC DAILY CRONJOB DEV+PROD DRYRUN

> Date : 2026-05-19
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-CRONJOB-DRYRUN
> Environnement : keybuzz-api-dev + keybuzz-api-prod (CronJobs dryRun=true uniquement)
> Type : GitOps CronJob DEV+PROD en dryRun, apply manuel, run manual Job dryRun, aucun sync live
> Priorite : P1 validation scheduler avant activation live

## VERDICT

GO CRONJOB DRYRUN READY Q-1T-4-B-EXEC-CRONJOB. Deux CronJobs `ad-spend-sync-daily` installes en DEV+PROD avec schedule daily `0 6 * * *` (08:00 Paris), suspend=false, body `{"dryRun":true}` cable. Manual Jobs DEV (`succeeded=1` ~5s apres fix port DEV 3001) et PROD (`succeeded=1` ~6s) executes avec HTTP 200 dryRun, sync=planned, 2 comptes actifs detectes par environnement (1 google + 1 meta), tous status=skipped/message=dryRun, hash8 systematique, aucun token expose dans logs. API DEV/PROD Ready 1/1 INCHANGE (v3.5.250-ad-spend-sync-all-{dev,prod}, generations 488/412). 0 provider call Meta/Google Ads, 0 DB write, 0 fake metric/event, 0 deploy.

Activation live `dryRun=false` reste NO GO jusqu'au prompt separe Q-1T-4-B-EXEC-VALIDATE-LIVE et GO Ludovic explicite.

## Scope / hors scope

### Scope execute

- preflight read-only (bastion + repos + runtime API DEV/PROD + Secrets DEV/PROD Ready + ES Ready)
- analyse patterns CronJobs existants (`trial-lifecycle-dryrun-cronjob.yaml` PROD comme reference principale, `outbound-tick-processor-cronjob.yaml` PROD comme reference secondaire)
- generation 2 manifests CronJob (DEV+PROD) /tmp mode 600
- kubectl apply --dry-run=server + non-persistance verify pour les 2 manifests
- commit + push manifests GitOps (2 fichiers ensemble)
- kubectl apply DEV CronJob
- manual Job DEV from cronjob (echec initial port 80, fix port 3001 commit, re-apply, retry succeeded=1)
- STOP Gate PROD respecte (GO APPLY CRONJOB PROD DRYRUN explicit recu)
- kubectl apply PROD CronJob
- manual Job PROD from cronjob (succeeded=1)
- cleanup jobs manuels (DEV + PROD + ancien job DEV failed)
- non-regression API DEV+PROD + CronJobs existants
- cleanup /tmp manifests

### Hors scope (NON execute)

- Aucun dryRun=false
- Aucun sync live (flip vers production reel reserve Q-1T-4-B-EXEC-VALIDATE-LIVE)
- Aucun provider call Meta / Google Ads
- Aucune ecriture DB (`ad_spend_tenant` / `ad_platform_accounts`)
- Aucun build Docker
- Aucun deploy API
- Aucune mutation Vault
- Aucun changement client/admin/website/backend
- Aucun commentaire Linear
- Aucun base64 decode avec affichage
- Aucun `kubectl set/edit/patch`

## Sources relues

- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-DEV-01.md (commit 5125a51)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-PROD-01.md (commit ed3ed69)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-AD-SPEND-SYNC-INTERNAL-TOKEN-DEV-01.md (commit 0526349)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-PROD-AD-SPEND-SYNC-INTERNAL-TOKEN-01.md (commit 8d40f36)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-AD-SPEND-DAILY-SYNC-CRONJOB-DRYRUN-01.md (commit a1f7e75 design Option B)
- k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml (pattern principal, CronJob curl POST + auth header + dryRun body)
- k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml (pattern secondaire)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts (dryRun guard syncOneAccount)

## Preflight (E0)

| Item | Attendu | Observe | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD avant | descendant ed3ed69 | ed3ed69 (clean) | OK |
| DEV API runtime | v3.5.250-ad-spend-sync-all-dev Ready 1/1 | match | OK |
| PROD API runtime | v3.5.250-ad-spend-sync-all-prod Ready 1/1 | match | OK |
| DEV Secret keybuzz-internal-tokens | Opaque, key AD_SPEND_SYNC_INTERNAL_TOKEN, RV 70640708 | match | OK |
| PROD Secret keybuzz-internal-tokens | Opaque, key AD_SPEND_SYNC_INTERNAL_TOKEN, RV 70661978 | match | OK |
| DEV ES | Ready=True/SecretSynced | match | OK |
| PROD ES | Ready=True/SecretSynced | match | OK |
| DEV svc keybuzz-api port | 3001 (different de PROD) | 3001 | OK |
| PROD svc keybuzz-api port | 80 | 80 | OK |
| Aucun CronJob ad-spend-sync-daily existant | absent DEV+PROD | absent | OK |

### Note port service DEV vs PROD

Verifie via `kubectl get svc keybuzz-api`. Detail crucial qui differe DEV/PROD :
- `kubectl -n keybuzz-api-dev get svc keybuzz-api` -> PORT 3001/TCP (port = targetPort)
- `kubectl -n keybuzz-api-prod get svc keybuzz-api` -> PORT 80/TCP (port 80 -> targetPort 3001)

Memoire CLAUDE.md confirme : "Port service K8s, pas port container : API PROD = port 80, API DEV = port 3001". Ce detail a cause un premier echec manual job DEV (curl timeout exit 28 sur port 80 inaccessible), corrige immediatement (cf section Apply DEV).

## Manifest CronJob DEV/PROD (E1)

### Pattern de reference

`k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml` :
- batch/v1 CronJob
- container `curlimages/curl:8.7.1`
- curl `-sf` (fail-on-error) + `-X POST` + `-H "Content-Type: application/json"` + auth header + `-d '{"dryRun":true}'`
- env from `secretKeyRef`
- restartPolicy Never

### Manifest DEV (apres fix port 3001)

`k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml` (size ~2450 bytes, ASCII strict, sha256 post-fix differe initial)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: ad-spend-sync-daily
  namespace: keybuzz-api-dev
spec:
  # Daily at 06:00 UTC (08:00 Paris)
  schedule: "0 6 * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  suspend: false
  jobTemplate:
    spec:
      backoffLimit: 1
      activeDeadlineSeconds: 300
      ttlSecondsAfterFinished: 86400
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: sync
              image: curlimages/curl:8.7.1
              command: ["/bin/sh", "-c"]
              args:
                - |
                  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ad-spend-sync-daily DEV dryRun starting"
                  if [ -z "${INTERNAL_TOKEN}" ]; then
                    echo "ERROR: INTERNAL_TOKEN missing"
                    exit 1
                  fi
                  RESPONSE=$(curl -sf \
                    -X POST \
                    -H "Content-Type: application/json" \
                    -H "X-Internal-Token: ${INTERNAL_TOKEN}" \
                    -d '{"dryRun":true}' \
                    --connect-timeout 5 \
                    --max-time 60 \
                    "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/admin/internal/ad-accounts/sync-all")
                  EXIT=$?
                  if [ $EXIT -ne 0 ]; then
                    echo "ERROR: curl failed with exit code $EXIT"
                    exit 1
                  fi
                  echo "Response: ${RESPONSE}"
                  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ad-spend-sync-daily DEV dryRun complete"
              env:
                - name: INTERNAL_TOKEN
                  valueFrom:
                    secretKeyRef:
                      name: keybuzz-internal-tokens
                      key: AD_SPEND_SYNC_INTERNAL_TOKEN
              resources:
                requests:
                  cpu: 50m
                  memory: 32Mi
                limits:
                  cpu: 100m
                  memory: 64Mi
```

### Manifest PROD

`k8s/keybuzz-api-prod/cronjob-ad-spend-sync-daily.yaml` (size 2460 bytes, ASCII strict, sha256 `fad3a0b697b0b33bcbac60f38aef0dec90997fb4b363bca7b848dcc6882eb2ff`)

Identique au DEV avec adaptations :
- namespace: `keybuzz-api-prod`
- URL: `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80/admin/internal/ad-accounts/sync-all` (port 80 PROD)
- logs message `PROD` au lieu de `DEV`

### Validation pre-commit

| Check | DEV | PROD |
|---|---|---|
| ASCII strict (no BOM, no non-ASCII) | OK | OK |
| `kubectl apply --dry-run=server` | "cronjob.batch/ad-spend-sync-daily created (server dry run)" | "cronjob.batch/ad-spend-sync-daily created (server dry run)" |
| Non-persistance verify post dry-run | NotFound (confirme non-persist) | NotFound (confirme non-persist) |

## Commit/push GitOps (E2)

### Git scope strict

```
git status --short :
?? k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml
?? k8s/keybuzz-api-prod/cronjob-ad-spend-sync-daily.yaml
```

### Commit initial + push (E2)

```
[main d30eee5] feat(api): add ad_spend sync daily CronJobs dryRun (AS.17.1T-4-B-EXEC-CRONJOB-DRYRUN)
 2 files changed, 128 insertions(+)
 create mode 100644 k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml
 create mode 100644 k8s/keybuzz-api-prod/cronjob-ad-spend-sync-daily.yaml

To https://github.com/keybuzzio/keybuzz-infra.git
   ed3ed69..d30eee5  main -> main
push exit=0
```

### Commit fix DEV port (E4 follow-up)

Suite a un curl timeout exit 28 sur manual job DEV initial (port 80 ne route pas en DEV qui expose 3001), fix manifest DEV via 1-ligne sed :

```diff
-                    "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:80/admin/internal/ad-accounts/sync-all")
+                    "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/admin/internal/ad-accounts/sync-all")
```

```
[main 7cbef38] fix(api-dev): cronjob ad_spend sync DEV service port 80 -> 3001 (AS.17.1T-4-B-EXEC-CRONJOB-DRYRUN)
 1 file changed, 1 insertion(+), 1 deletion(-)

To https://github.com/keybuzzio/keybuzz-infra.git
   d30eee5..7cbef38  main -> main
push exit=0
```

HEAD post-fix : `7cbef38`. status clean.

PROD manifest n'a pas necessite de fix (port 80 deja correct cote PROD service).

## Apply DEV + manual job DEV (E3+E4)

### Apply DEV CronJob (initial puis post-fix)

```
kubectl apply -f k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml
cronjob.batch/ad-spend-sync-daily created
```

Post-fix port 3001 :

```
kubectl apply -f k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml
cronjob.batch/ad-spend-sync-daily configured
```

### Manual Job DEV initial (FAIL pre-fix)

| Champ | Valeur |
|---|---|
| Job name | ad-spend-sync-daily-manual-q1t4b-1779168066 |
| Result | failed=2 (backoffLimit=1, 2 attempts total) |
| Container exit | curl exit code 28 (Operation timed out) |
| Root cause | DEV svc keybuzz-api port = 3001, manifest pointait :80 |

Cleanup job initial : `kubectl delete job` apres logs captures.

### Manual Job DEV post-fix (SUCCESS)

| Champ | Valeur |
|---|---|
| Job name | ad-spend-sync-daily-manual-q1t4b-fix-1779168227 |
| Result | succeeded=1 |
| Start | 2026-05-19T05:23:48Z |
| Completion | 2026-05-19T05:23:53Z (~5s) |

Logs Job DEV :

```
[2026-05-19T05:23:50Z] ad-spend-sync-daily DEV dryRun starting
Response: {"sync":"planned","dryRun":true,"platform_filter":"all","period":{"since":"2026-04-19","until":"2026-05-19"},"account_count":2,"accounts":[{"hash8":"0055f31c","tenant_hash8":"87fd9f6b","platform":"google","status":"skipped","message":"dryRun"},{"hash8":"6fd93032","tenant_hash8":"aa528bf1","platform":"meta","status":"skipped","message":"dryRun"}]}
[2026-05-19T05:23:51Z] ad-spend-sync-daily DEV dryRun complete
```

### Verifications DEV

| Verification | Resultat |
|---|---|
| HTTP code (via curl -sf) | 200 (sinon curl fail + exit code != 0) |
| sync field | "planned" (dryRun mode) |
| dryRun field | true |
| platform_filter | "all" |
| account_count | 2 (1 google + 1 meta) |
| accounts[*].status | tous "skipped" |
| accounts[*].message | tous "dryRun" |
| accounts[0].hash8 | 0055f31c (google) |
| accounts[1].hash8 | 6fd93032 (meta) |
| tenant_hash8 DEV | 87fd9f6b (google), aa528bf1 (meta) - match Q-1T-4-B-EXEC-DEPLOY-API-DEV smoke direct |
| Token dans logs | AUCUN (curl -sf + env var, jamais print, header masked) |

Cleanup manual job DEV : `kubectl delete job` apres logs captures.

## Apply PROD + manual job PROD (E5-E7)

### STOP Gate Apply PROD respecte (E5)

Pattern Mode B SAFE PROD : STOP apres apply DEV + manual job DEV success, attente GO APPLY CRONJOB PROD DRYRUN explicit. GO recu, continuation autorisee.

### Apply PROD CronJob (E6)

```
kubectl apply -f k8s/keybuzz-api-prod/cronjob-ad-spend-sync-daily.yaml
cronjob.batch/ad-spend-sync-daily created
```

### Manual Job PROD (E7)

| Champ | Valeur |
|---|---|
| Job name | ad-spend-sync-daily-manual-q1t4b-1779168654 |
| Result | succeeded=1 |
| Start | 2026-05-19T05:30:54Z |
| Completion | 2026-05-19T05:31:00Z (~6s) |

Logs Job PROD :

```
[2026-05-19T05:30:57Z] ad-spend-sync-daily PROD dryRun starting
Response: {"sync":"planned","dryRun":true,"platform_filter":"all","period":{"since":"2026-04-19","until":"2026-05-19"},"account_count":2,"accounts":[{"hash8":"0055f31c","tenant_hash8":"78dea947","platform":"google","status":"skipped","message":"dryRun"},{"hash8":"6fd93032","tenant_hash8":"78dea947","platform":"meta","status":"skipped","message":"dryRun"}]}
[2026-05-19T05:30:57Z] ad-spend-sync-daily PROD dryRun complete
```

### Verifications PROD

| Verification | Resultat |
|---|---|
| HTTP code | 200 (curl -sf success) |
| sync field | "planned" (dryRun mode) |
| dryRun field | true |
| account_count | 2 (1 google + 1 meta) |
| accounts[*].status | tous "skipped" |
| accounts[*].message | tous "dryRun" |
| accounts[0].hash8 | 0055f31c (google) - identique DEV (memes account_id Ads source) |
| accounts[1].hash8 | 6fd93032 (meta) - identique DEV |
| tenant_hash8 PROD | 78dea947 (sur les 2 accounts) - distinct DEV |
| Token dans logs | AUCUN |

Account_id Ads identiques DEV+PROD confirme : memes comptes Meta+Google Ads reels utilises en DEV+PROD (probable KBC tenant Ludovic, comptes Ads reels partages pour developpement + production). Tenants distincts confirme multi-tenant correct.

Cleanup manual job PROD : `kubectl delete job` apres logs captures.

## DB no-write / no provider call (E8)

| Action | Execute par CE ou job ? |
|---|---|
| POST /admin/internal/ad-accounts/sync-all dryRun=true (via cluster-internal Service) | OUI 2x (1 DEV + 1 PROD manual jobs) |
| POST /admin/internal/ad-accounts/sync-all dryRun=false | NON |
| Appel Meta Ads API (graph.facebook.com) | NON (dryRun guard avant fetchFn dans syncOneAccount) |
| Appel Google Ads API (googleads.googleapis.com) | NON (dryRun guard avant fetchFn) |
| INSERT ad_spend_tenant | NON (dryRun guard avant INSERT loop) |
| UPDATE ad_platform_accounts (last_sync_at) | NON (dryRun guard skip cet UPDATE) |
| SELECT totals ad_spend_tenant | NON (dryRun retourne rows:0 spend:0 sans SELECT) |
| Event GA4 / Meta CAPI / TikTok / LinkedIn | NON (endpoint INTERNAL hors chaine outbound) |

DB read-only query non executee par CE (defer code review Q-1T-4-B-EXEC-CODE qui prouve dryRun guard, confirme empiriquement par response `dryRun:true, all skipped`).

## Non-regression (E9)

| Surface | Avant Q-1T-4-B-EXEC-CRONJOB-DRYRUN | Apres E7 (cette phase) | Verdict |
|---|---|---|---|
| Runtime DEV image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev | INCHANGE |
| Runtime DEV generation | 488 | 488 | INCHANGE |
| Runtime DEV pod | keybuzz-api-68cc9c967d-68pbx restarts=0 | identique restart=0 | INCHANGE |
| Runtime PROD image | v3.5.250-ad-spend-sync-all-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| Runtime PROD generation | 412 | 412 | INCHANGE |
| Runtime PROD pod | keybuzz-api-768c76c558-fsd89 restarts=0 | identique restart=0 | INCHANGE |
| CronJob DEV `ad-spend-sync-daily` | absent | schedule "0 6 * * *", suspend false, lastSuccessful 2026-05-19T05:23:53Z | NEW (attendu cette phase) |
| CronJob PROD `ad-spend-sync-daily` | absent | schedule "0 6 * * *", suspend false, lastSuccessful 2026-05-19T05:31:00Z | NEW (attendu cette phase) |
| CronJobs DEV existants (sla-evaluator, carrier-tracking-poll, outbound-tick, sla-evaluator-escalation) | actifs | actifs | INCHANGE |
| CronJobs PROD existants (sla-evaluator, carrier-tracking-poll, outbound-tick-processor, trial-lifecycle-dryrun) | actifs | actifs | INCHANGE |
| Events Warning DEV 10m | 0 | 3 (`BackoffLimitExceeded` du job initial port 80, + 2 `UnexpectedJob` sur jobs manuels --from=cronjob, normaux et cleanup OK) | OK (transitoires) |
| Events Warning PROD 10m | 0 | 1 (`UnexpectedJob` sur job manuel --from=cronjob, normal et cleanup OK) | OK |

### Note Warning `UnexpectedJob`

`kubectl create job --from=cronjob` cree un Job qui n'a pas le `OwnerReference` vers CronJob (CronJob controller ne le reconnait pas comme l'un des siens). Cela genere un Warning event `UnexpectedJob` qui est purement informatif. Les jobs manuels ont ete supprimes apres logs captures, donc plus reference. Aucun impact runtime.

### Note Warning `BackoffLimitExceeded`

Le job DEV initial avait curl exit 28 (port 80 inaccessible en DEV, fix port 3001 commit `7cbef38`). Job supprime apres diagnostic. Le job retry post-fix a reussi (succeeded=1). Aucun impact runtime.

## No fake metrics / no fake events

- dryRun=true uniquement (jamais `sync=completed`, toujours `sync=planned/skipped`)
- 0 event GA4 / Meta CAPI / TikTok / LinkedIn emis
- 0 appel provider Meta/Google Ads
- 0 ecriture `ad_spend_tenant` / `ad_platform_accounts`
- 0 dashboard metric force/fake
- 0 admin Acquisition payee metric change (sera observable seulement apres flip LIVE)

## Cleanup temporary files

| Fichier | Statut |
|---|---|
| /tmp/keybuzz-q1t4b-cronjob-dev.yaml | shred -u OK (absent confirme) |
| /tmp/keybuzz-q1t4b-cronjob-prod.yaml | shred -u OK (absent confirme) |
| /tmp/ph118-backup/ (Q-1T-4-B-EXEC-CODE rollback) | CONSERVE (hors scope, ancienne phase) |
| /root/.vault-root-token.tmp | non touche cette phase (hors scope, aucune commande vault) |

## Rollback

### Rollback nominal

1. `git revert 7cbef38` puis `git revert d30eee5` (annule fix DEV puis manifests originaux)
2. `git push origin main`
3. Pas de `kubectl delete cronjob` jusqu'a phrase rollback separee
4. CronJobs DEV+PROD restent appliques mais Git source-of-truth annule

### Rollback destructif (necessite phrase exacte)

```
GO ROLLBACK DELETE CRONJOB ADSPEND DRYRUN Q-1T-4-B-EXEC-CRONJOB
```

Commandes autorisees uniquement apres phrase :

```
kubectl -n keybuzz-api-dev delete cronjob ad-spend-sync-daily
kubectl -n keybuzz-api-prod delete cronjob ad-spend-sync-daily
```

### Suspendre temporairement sans delete

```
kubectl -n keybuzz-api-{dev,prod} patch cronjob ad-spend-sync-daily -p '{"spec":{"suspend":true}}'
```

Mais `kubectl patch` est interdit sans GO emergency separe : `GO PATCH SUSPEND CRONJOB ADSPEND Q-1T-4-B-EXEC-CRONJOB`. Alternative GitOps : modifier `suspend: false -> true` dans manifest + commit + push + apply.

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-VALIDATE-LIVE DEV** : flip `dryRun:false` dans CronJob DEV via patch manifest + commit + apply + premier tick LIVE observe. INSERT ad_spend_tenant DEV + UPDATE last_sync_at DEV. Provider call REAL Meta+Google Ads DEV.
2. **Q-1T-4-B-EXEC-VALIDATE-LIVE PROD** : symetrique PROD apres 24-48h observation DEV LIVE OK. Admin Acquisition payee PROD affichera valeurs reelles.

Important :
- Premier flip LIVE conseille en DEV uniquement, puis observation 24-48h des logs, ad_spend_tenant counts, ad_platform_accounts last_sync_at avant flip PROD.
- Plan suspendu : si premier tick LIVE PROD revele bug, suspendre CronJob PROD via `suspend: true` GitOps + investigation + correction code/manifest + rollback si necessaire.
- Monitoring : K8s events PROD + logs `[AdAccountsInternal]` + comparer counts ad_spend_tenant avant/apres.

## Phases suivantes (ordre conseille)

| Sequence | Phase | Effet runtime | Pre-requis |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-VALIDATE-LIVE DEV | premier sync LIVE non-dryRun DEV, INSERT ad_spend_tenant DEV | GO Ludovic explicite + observation cron DEV 24h dryRun OK |
| 2 | Q-1T-4-B-EXEC-VALIDATE-LIVE PROD | premier sync LIVE PROD, admin Acquisition payee affiche valeurs reelles | observation 24h DEV LIVE OK + GO Ludovic |
| 3 | Q-1T-4-B closeout | KEY-323 marquage Done | GO Ludovic + Linear |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-CRONJOB-DRYRUN done

Deux CronJobs ad-spend-sync-daily DEV+PROD installes via GitOps en mode
dryRun=true uniquement :
- DEV manifest commit d30eee5 puis fix port 3001 commit 7cbef38 push
  origin/main (DEV svc keybuzz-api expose 3001, pas 80 comme PROD)
- PROD manifest commit d30eee5 push origin/main
- Schedule "0 6 * * *" (08:00 Paris) daily
- concurrencyPolicy Forbid, ttl 24h, activeDeadline 5min

Manual Jobs verifies :
- DEV (post-fix) : succeeded=1 ~5s, HTTP 200 dryRun sync=planned, 2 comptes
  actifs (1 google + 1 meta) status=skipped, hash8 systematique, 0 token
  expose
- PROD : succeeded=1 ~6s, idem DEV avec tenant_hash8 PROD distinct

Contraintes : 0 provider call / 0 DB write / 0 endpoint non-dryRun /
0 fake metric / 0 valeur secret exposee. API DEV/PROD Ready 1/1 INCHANGE
(v3.5.250-ad-spend-sync-all-{dev,prod}, generations 488/412).

Prochaine phase : Q-1T-4-B-EXEC-VALIDATE-LIVE DEV puis PROD (flip
dryRun:false) apres observation 24h dryRun OK + GO Ludovic explicite.
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

CronJobs `ad-spend-sync-daily` DEV+PROD installes en dryRun=true uniquement (schedule "0 6 * * *", concurrencyPolicy Forbid, suspend false), manual jobs DEV (post-fix port 3001) et PROD executes avec succeeded=1 HTTP 200 dryRun/planned/skipped sur 2 comptes actifs par environnement (hash8 systematique account_id et tenant_id), aucun token expose dans logs, 0 provider call, 0 DB write, 0 fake metric/event, API DEV/PROD Ready 1/1 INCHANGE (v3.5.250-ad-spend-sync-all-{dev,prod}). Activation live `dryRun=false` reste NO GO jusqu'au prompt separe Q-1T-4-B-EXEC-VALIDATE-LIVE et GO Ludovic explicite.

STOP
