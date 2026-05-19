# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CRONJOB-FLIP-ALL-PLATFORMS-01

> Date : 2026-05-19
> Linear : NA (initiative Q-1T-4-B ad_spend daily sync orchestration)
> Phase : Q-1T-4-B-EXEC-CRONJOB-FLIP-ALL-PLATFORMS (DEV + PROD GitOps + apply runtime + observation 1er cycle naturel 14:00 UTC)
> Environnement : keybuzz-infra main + cluster K8s DEV (keybuzz-api-dev) + PROD (keybuzz-api-prod)

## VERDICT

GO PROD. CronJobs persistants DEV+PROD ad-spend-sync-daily flippes de body meta-only vers all-platforms le 2026-05-19. Cycle naturel 14:00 UTC succeeded en 7 secondes par environnement, account_count=2 (Meta + Google), ok=2 / error=0, sync Google operationnel post rotation refresh token, sync Meta croissance progressive coherente. Aucun bump image API, aucun Secret modifie, aucun Deployment touche, scope GitOps strict 2 fichiers manifest.

## Preflight

| Item                                                  | Verifie                                                     | Source                                                                |
|-------------------------------------------------------|-------------------------------------------------------------|-----------------------------------------------------------------------|
| Bastion install-v3 46.62.171.61                       | OK                                                          | ssh alias                                                             |
| keybuzz-infra HEAD pre-phase                          | `8858674` ops(website-prod) post EXEC-GOOGLE-OAUTH-PAGE     | git log -1                                                            |
| keybuzz-infra status                                  | clean                                                       | git status --short                                                    |
| keybuzz-api HEAD                                      | `01b163e4` ph147.4/source-of-truth (READ-ONLY, code inchange) | git log -1                                                            |
| Code endpoint sync-all                                | internal-routes.ts L11 type + L58 ternary + L67-69 SQL filter | grep                                                                  |
| Semantique platform absent vs "all"                   | strictement equivalent (platformFilter=null dans les 2 cas) | code analysis E2 PREFLIGHT-DIFF                                       |
| Manifests pre-phase                                   | body meta-only (commit `dc4ec40` EXEC-CRONJOB-FLIP-META-LIVE) | grep dans keybuzz-infra/k8s/                                          |
| Refresh token Google rotation                         | hash8 `a10b3c0e` DEV+PROD (post EXEC-GOOGLE-REFRESH-TOKEN-ROTATE) | kubectl get secret + sha256                                           |
| Smokes Google DEV+PROD one-shot precedents            | status:"ok" 2 rows 0.0628 GBP chacun                        | rapport precedent + logs Jobs                                         |
| Deploy keybuzz-api DEV pre-phase                      | ready=1/1 obsGen=490                                        | kubectl get deploy                                                    |
| Deploy keybuzz-api PROD pre-phase                     | ready=1/1 obsGen=414                                        | kubectl get deploy                                                    |
| Cron schedule pre-phase                               | "0 6,10,14,18 * * *" depuis FLIP-META-LIVE                  | kubectl get cronjob                                                   |

## Audit signaux

Etat pre-phase :
- Refresh token Google Ads rote le matin (2026-05-19T11:50 DEV / 11:55 PROD), hash8 nouveau `a10b3c0e` DEV+PROD.
- Smoke one-shot Google DEV+PROD avait prouve status:"ok" + 2 rows + 0.0628 GBP par environnement.
- CronJobs persistants ad-spend-sync-daily DEV+PROD restaient en body meta-only par construction (Q-1T-4-B-EXEC-CRONJOB-FLIP-META-LIVE commit `dc4ec40`), filtre SQL court-circuitait Google.
- Cycle naturel 06:00 UTC du jour avait sync Meta uniquement.
- Cycle naturel 10:00 UTC du jour avait sync Meta uniquement.

Decision : flip body permanent vers all-platforms maintenant que les pre-requis sont valides.

Semantique platform code endpoint internal-routes.ts :
- Ligne 11 : `platform?: 'meta' | 'google' | 'all'` (type optional)
- Ligne 58 : `const platformFilter = body.platform && body.platform !== 'all' ? body.platform : null;`
- Ligne 66-69 : si platformFilter truthy, SQL WHERE append `AND platform = $X`
- Resultat : body sans platform OU body avec platform:"all" -> platformFilter=null -> SELECT charge tous comptes status='active'
- Choix retenu : `{"dryRun":false,"platform":"all"}` (explicit auto-documenting, coherent avec output endpoint `"platform_filter":"all"`)

## Patch

| Fichier                                                                    | Changement                                                                                              | Risque                                            |
|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|---------------------------------------------------|
| keybuzz-infra/k8s/keybuzz-api-dev/cronjob-ad-spend-sync-daily.yaml          | +7/-7 (4 commentaires entete + log start + body curl + log complete)                                    | bas (idempotent, rolling Cron au prochain horaire) |
| keybuzz-infra/k8s/keybuzz-api-prod/cronjob-ad-spend-sync-daily.yaml         | +7/-7 (identique symetrique : namespace PROD + URL port 80 + source-commit-hash PROD)                   | bas (idempotent)                                  |

### Diff strict ligne-par-ligne (DEV identique PROD modulo references PROD)

| Ligne | Avant | Apres |
|---|---|---|
| Commentaire L1 | `Q-1T-4-B-EXEC-CRONJOB-FLIP-META-LIVE` | `Q-1T-4-B-EXEC-CRONJOB-FLIP-ALL-PLATFORMS` |
| Commentaire L2 | `Meta platform only.` | `all platforms (Meta + Google).` |
| Commentaire L6 (Body doc) | `{"dryRun":false,"platform":"meta"} - Google jamais charge cote SQL (WHERE platform = 'meta').` | `{"dryRun":false,"platform":"all"} - charge tous comptes actifs (Meta + Google) cote SQL (platformFilter=null endpoint internal-routes.ts L58).` |
| Commentaire L8 (Google OAuth handling) | `hors phase, attend validation Google OAuth app + remediation refresh tokens.` | `refresh token rote 2026-05-19 (Q-1T-4-B-EXEC-GOOGLE-REFRESH-TOKEN-ROTATE), hash8 a10b3c0e DEV+PROD, smoke Google DEV+PROD status:"ok" 2 rows 0.0628 GBP.` |
| Log start string | `live meta-only starting` | `live all-platforms starting` |
| Body curl | `'{"dryRun":false,"platform":"meta"}'` | `'{"dryRun":false,"platform":"all"}'` |
| Log complete string | `live meta-only complete` | `live all-platforms complete` |

### Champs critiques preserves

`metadata.name=ad-spend-sync-daily`, `metadata.namespace=keybuzz-api-{dev,prod}`, `spec.schedule="0 6,10,14,18 * * *"`, `spec.concurrencyPolicy=Forbid`, `spec.suspend=false`, `successfulJobsHistoryLimit=3`, `failedJobsHistoryLimit=3`, `jobTemplate.spec.backoffLimit=1`, `activeDeadlineSeconds=300`, `ttlSecondsAfterFinished=86400`, `containers[0].image=curlimages/curl:8.7.1`, `env.INTERNAL_TOKEN.secretKeyRef=keybuzz-internal-tokens/AD_SPEND_SYNC_INTERNAL_TOKEN`, URL DEV `:3001`, URL PROD `:80`, `--connect-timeout 5`, `--max-time 120`, `restartPolicy=Never`, `resources` (cpu 50m/100m, mem 32Mi/64Mi).

## Tests

| Test                                                                              | Attendu                                | Resultat                              |
|-----------------------------------------------------------------------------------|----------------------------------------|---------------------------------------|
| PREFLIGHT-DIFF semantique platform code review                                     | platform absent == "all" equivalent    | OK (E2 lignes 58 + 67-69)             |
| PREFLIGHT-DIFF greps manifests cibles                                              | meta absent, all present 2x            | OK chaque manifest                    |
| PREFLIGHT-DIFF kubectl --dry-run=server cible                                      | configured (server dry run)            | OK (test execute, sans mutation)      |
| Edit local 2 manifests (DEV + PROD) 7 modifications chacun                         | sha256 stable post-edit                | OK DEV `3344146e...`, PROD `afc0940c...` |
| git diff post-mv                                                                   | 5 hunks par fichier, scope strict      | OK (`+7/-7` chaque)                   |
| Greps validation : platform meta absent, platform all present, schedule conserve, ports preserves | tous OK                                | OK DEV+PROD                           |
| `kubectl apply --dry-run=server` DEV                                               | configured (server dry run)            | OK                                    |
| `kubectl diff` DEV cluster                                                         | gen 3->4, body change uniquement       | OK exit code 1 (attendu)              |
| `kubectl apply -f` DEV                                                             | `cronjob.batch/ad-spend-sync-daily configured` | OK                                    |
| Runtime DEV post-apply                                                             | gen=4, body platform:all, schedule conserve | OK                                    |
| `kubectl apply --dry-run=server` PROD                                              | configured (server dry run)            | OK                                    |
| `kubectl diff` PROD cluster                                                        | gen 2->3, body change uniquement       | OK exit code 1                        |
| `kubectl apply -f` PROD                                                            | `cronjob.batch/ad-spend-sync-daily configured` | OK                                    |
| Runtime PROD post-apply                                                            | gen=3, body platform:all, schedule conserve | OK                                    |
| 1er cycle naturel 14:00 UTC declenche                                              | Job auto-cree par CronJob scheduler    | OK Job `ad-spend-sync-daily-29653320` DEV+PROD |
| Job DEV duration                                                                   | ~5-15s                                 | OK 7s (14:00:00Z -> 14:00:07Z)        |
| Job PROD duration                                                                  | ~5-15s                                 | OK 7s (14:00:00Z -> 14:00:07Z)        |
| Response DEV `sync` + `dryRun` + `platform_filter`                                 | `"completed"` + `false` + `"all"`      | OK                                    |
| Response DEV `account_count`                                                       | 2 (Meta + Google)                      | OK                                    |
| Response DEV `ok` / `error`                                                        | 2 / 0                                  | OK                                    |
| Response DEV Meta + Google entries                                                 | status:"ok" chacun                     | OK                                    |
| Response PROD identique structure                                                  | account_count=2 ok=2 error=0           | OK                                    |
| Aucun Job manuel cree                                                              | seuls Jobs CronJob-owned               | OK (29652840 + 29653080 + 29653320)   |

## Build

Aucun build dans cette phase. Images runtime keybuzz-api DEV+PROD inchangees depuis Q-1T-4-B-EXEC-BUILD-PROD (tag v3.5.250-ad-spend-sync-all-{dev,prod}). Code endpoint sync-all deploye depuis Q-1T-4-B-EXEC-DEPLOY-DEV/PROD, supporte platform:"all" sans modification (filtre SQL conditionnel deja en place).

## GitOps

| Commit                                                                              | Repo / Branche       | Scope                                                                 |
|-------------------------------------------------------------------------------------|----------------------|-----------------------------------------------------------------------|
| `6c6daca4964d419c1c52a829ee4ae2740f0200b5` ops(api): flip CronJobs ad-spend-sync-daily vers all-platforms | keybuzz-infra main   | +14 / -14 lignes sur k8s/keybuzz-api-{dev,prod}/cronjob-ad-spend-sync-daily.yaml |

Push origin OK : `8858674..6c6daca  main -> main`. HEAD local == origin/main sync.

kubectl apply executions :
- DEV namespace=keybuzz-api-dev : `configured`, generation 3 -> 4
- PROD namespace=keybuzz-api-prod : `configured`, generation 2 -> 3
- Aucun rollout deployment necessaire (CronJob = ressource Batch, pas Deployment ; le scheduler interne K8s utilise le nouveau spec.jobTemplate au prochain horaire cron sans restart pod existant)

## Validation runtime

### Runtime CronJobs post-apply

| Champ | DEV | PROD |
|---|---|---|
| metadata.namespace | keybuzz-api-dev | keybuzz-api-prod |
| metadata.generation | **4** (etait 3) | **3** (etait 2) |
| spec.schedule | "0 6,10,14,18 * * *" | identique |
| spec.suspend | false | false |
| spec.concurrencyPolicy | Forbid | Forbid |
| body args dryRun | false | false |
| body args platform | "all" | "all" |
| URL host:port | keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001 | keybuzz-api.keybuzz-api-prod.svc.cluster.local:80 |
| env.INTERNAL_TOKEN.secretKeyRef | keybuzz-internal-tokens/AD_SPEND_SYNC_INTERNAL_TOKEN | identique |
| lastScheduleTime post cycle 14:00 | 2026-05-19T14:00:00Z | 2026-05-19T14:00:00Z |
| lastSuccessfulTime | 2026-05-19T14:00:07Z | 2026-05-19T14:00:07Z |

### Job DEV cycle 14:00 UTC

- Name : `ad-spend-sync-daily-29653320`
- Owner : CronJob/ad-spend-sync-daily
- start : 2026-05-19T14:00:00Z
- completion : 2026-05-19T14:00:07Z
- duration : ~7s
- succeeded=1, failed=0

Response endpoint DEV (logs container) :
```
[2026-05-19T14:00:02Z] ad-spend-sync-daily DEV live all-platforms starting
Response: {"sync":"completed","dryRun":false,"platform_filter":"all",
  "period":{"since":"2026-04-19","until":"2026-05-19"},
  "account_count":2,"ok":2,"error":0,
  "accounts":[
    {"hash8":"0055f31c","tenant_hash8":"87fd9f6b","platform":"google","status":"ok",
     "rows_upserted":2,"totals":{"rows":2,"spend":0.0628,"currency":"GBP"}},
    {"hash8":"6fd93032","tenant_hash8":"aa528bf1","platform":"meta","status":"ok",
     "rows_upserted":7,"totals":{"rows":7,"spend":268.55,"currency":"GBP"}}
  ]}
[2026-05-19T14:00:05Z] ad-spend-sync-daily DEV live all-platforms complete
```

### Job PROD cycle 14:00 UTC

- Name : `ad-spend-sync-daily-29653320`
- Owner : CronJob/ad-spend-sync-daily
- start : 2026-05-19T14:00:00Z
- completion : 2026-05-19T14:00:07Z
- duration : ~7s
- succeeded=1, failed=0

Response endpoint PROD (logs container) :
```
[2026-05-19T14:00:02Z] ad-spend-sync-daily PROD live all-platforms starting
Response: {"sync":"completed","dryRun":false,"platform_filter":"all",
  "period":{"since":"2026-04-19","until":"2026-05-19"},
  "account_count":2,"ok":2,"error":0,
  "accounts":[
    {"hash8":"0055f31c","tenant_hash8":"78dea947","platform":"google","status":"ok",
     "rows_upserted":2,"totals":{"rows":2,"spend":0.0628,"currency":"GBP"}},
    {"hash8":"6fd93032","tenant_hash8":"78dea947","platform":"meta","status":"ok",
     "rows_upserted":7,"totals":{"rows":23,"spend":713.75,"currency":"GBP"}}
  ]}
[2026-05-19T14:00:04Z] ad-spend-sync-daily PROD live all-platforms complete
```

### Effet DB observe (preuves via endpoint response, snapshot DB direct ecarte)

- DB DEV ad_spend_tenant : 2 UPSERTs compte Google (`0055f31c / 87fd9f6b`) + 7 UPSERTs compte Meta (`6fd93032 / aa528bf1`)
- DB PROD ad_spend_tenant : 2 UPSERTs compte Google (`0055f31c / 78dea947`) + 7 UPSERTs compte Meta (`6fd93032 / 78dea947`)
- ad_platform_accounts.last_sync_at : 4 updates (2 comptes x 2 environnements)
- Idempotence ON CONFLICT preservee : Meta PROD totals.rows=23 vs rows_upserted=7 -> 16 lignes deja en DB identiques skipped

## No fake metrics / no fake events

Les spend observes sont des donnees Meta Graph API insights + Google Ads API insights reelles, persistees verbatim en ad_spend_tenant via UPSERT ON CONFLICT idempotent (helper syncOneAccount PH148 known-good). Aucune valeur synthetique, aucun mock, aucun KPI invente. Les hash8 hash8 utilises (`0055f31c`, `6fd93032`, `87fd9f6b`, `aa528bf1`, `78dea947`) sont des sha256[0:8] reproductibles a partir des IDs reels en DB.

### Evolution spend Meta sur la journee (donnees reelles cumulees, no fake)

| Cycle / Source | DEV Meta spend | PROD Meta spend |
|---|---|---|
| 07:28 UTC EXEC-VALIDATE-LIVE-DEV one-shot all-platforms | 251.83 GBP | - |
| 07:43 UTC EXEC-VALIDATE-LIVE-PROD-META one-shot | - | 698.07 GBP |
| 10:00 UTC cycle naturel FLIP-META-LIVE | 261.93 GBP | 707.13 GBP |
| 14:00 UTC cycle naturel FLIP-ALL-PLATFORMS (cette phase) | **268.55 GBP** | **713.75 GBP** |

Croissance progressive coherente avec accumulation spend journee, UPSERT idempotent.

### Google sync stable post-rotation

| Env | Google spend cycle 14:00 | rows_upserted | Status |
|---|---|---|---|
| DEV | 0.0628 GBP | 2 | ok (identique smoke 11:49) |
| PROD | 0.0628 GBP | 2 | ok (identique smoke 11:55) |

Refresh token `a10b3c0e` Google Ads operationnel sans degradation depuis rotation 11:50-11:55 UTC. 4h depuis rotation, OAuth refresh stable.

## AI feature parity

Non applicable. Phase tracking ad_spend daily sync. Aucune surface IA (Inbox, Agent KeyBuzz, autopilot, playbooks, escalades) touchee. Endpoint /admin/internal/* est interne batch sync, hors perimetre AI parity.

## Non-regression PROD

| Indicateur                                              | Avant phase                | Apres phase                | Verdict                  |
|---------------------------------------------------------|----------------------------|----------------------------|--------------------------|
| Deploy keybuzz-api PROD image                           | (post Q-1T-4-B-EXEC-DEPLOY-PROD) | identique                  | INCHANGE                 |
| Deploy keybuzz-api PROD replicas/ready/avail            | 1/1/1                       | 1/1/1                       | INCHANGE                 |
| Deploy keybuzz-api PROD observedGeneration              | 414                         | 414                         | INCHANGE                 |
| Deploy keybuzz-api DEV ready                            | 1/1                         | 1/1                         | INCHANGE                 |
| Deploy keybuzz-api DEV observedGeneration               | 490                         | 490                         | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD suspend                | false                       | false                       | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD schedule               | "0 6,10,14,18 * * *"       | "0 6,10,14,18 * * *"       | INCHANGE                 |
| CronJob ad-spend-sync-daily PROD body platform          | "meta"                      | **"all"**                  | UPGRADE intentionnel     |
| CronJob ad-spend-sync-daily PROD generation             | 2                           | 3                           | +1 (apply expected)      |
| CronJob ad-spend-sync-daily DEV suspend                 | false                       | false                       | INCHANGE                 |
| CronJob ad-spend-sync-daily DEV body platform           | "meta"                      | **"all"**                  | UPGRADE intentionnel     |
| Secret keybuzz-google-ads hash8 GOOGLE_ADS_REFRESH_TOKEN DEV | a10b3c0e                    | a10b3c0e                    | PRESERVE                 |
| Secret keybuzz-google-ads hash8 GOOGLE_ADS_REFRESH_TOKEN PROD | a10b3c0e                    | a10b3c0e                    | PRESERVE                 |
| keybuzz-website PROD runtime                            | v0.6.15-google-ads-oauth-page-prod | identique                  | INCHANGE                 |
| Autres deployments (client, admin, backend)             | inchanges                   | inchanges                   | INCHANGE                 |
| Aucun :latest, aucun kubectl set/edit/patch             | OK                          | OK                          | INCHANGE                 |

## Linear

Pas de ticket Linear unique pour cette phase. Initiative Q-1T-4-B = orchestration daily ad_spend sync. Linear creation eventuelle si necessaire pour tracker :
- Stabilite Google Ads OAuth long-terme (observation cycles 18:00 UTC ce jour + cycles J+1 et au-dela).
- Eventuelle migration Secret keybuzz-google-ads vers ExternalSecret + Vault (audit trail + rotation property-only Q-1B pattern).

A discuter avec Ludovic.

## Gaps restants

1. Surveillance long-terme OAuth Google
   - Symptome : refresh token Google Ads rote depuis 4h, cycle 14:00 UTC OK, mais stabilite jour-apres-jour non encore prouvee.
   - Action : observer cycles naturels 18:00 UTC ce jour + 06:00 UTC J+1 + jours suivants. Si invalid_grant reapparait, declencher nouvelle rotation OAuth.

2. Migration Secret keybuzz-google-ads vers ESO + Vault
   - Symptome : Secret K8s actuel est manuel (pas Labels/Annotations ESO, pas d'ExternalSecret correspondant). Rotation se fait via kubectl patch direct (pattern Q-1T-4-B-EXEC-GOOGLE-REFRESH-TOKEN-ROTATE).
   - Action recommandee : phase distincte Q-1T-4-B-EXEC-GOOGLE-ADS-ESO-MIGRATION pour migrer vers pattern ESO+Vault property-only rotation (audit trail + symetrie autres secrets KeyBuzz).
   - Hors scope cette phase.

3. Verification consommateurs spend Google dans Admin Acquisition payee
   - Symptome : ad_spend_tenant PROD contient maintenant Google rows pour tenant `78dea947`. Verifier que l'UI Admin v2 affiche ces valeurs et ne reste pas en placeholder hardcode.
   - Action recommandee : QA navigateur Ludovic post deploy. Hors scope sync.

4. Audit isolation refresh token DEV vs PROD
   - Symptome : DEV et PROD partagent le meme refresh token Google Ads `a10b3c0e` (decision Ludovic acceptee pour debloquer rapidement).
   - Risque : revoke OAuth cote Google affecterait simultanement les 2 environnements.
   - Action recommandee future : reauthoriser des comptes Google Ads separes DEV vs PROD si volonte d'isolation stricte.
   - Hors scope cette phase.

5. Aucun snapshot DB direct
   - Symptome : preuve principale = endpoint response (rows_upserted + totals + status par compte).
   - Compensation : snapshot SQL ecartee par choix de surete (eviter kubectl exec, port-forward, touche credentials Vault DB).
   - Suffisant : endpoint expose deja l'effet DB par compte de maniere structuree.

## Phrase cible finale

Les CronJobs persistants ad-spend-sync-daily DEV+PROD sont bascules en LIVE all-platforms 4x/jour le 2026-05-19, refresh token Google Ads precedemment rote operationnel, sync Meta + Google ensemble verifies au 1er cycle naturel 14:00 UTC (DEV+PROD ok=2 error=0, 268.55 GBP Meta DEV + 0.0628 GBP Google DEV + 713.75 GBP Meta PROD + 0.0628 GBP Google PROD), sans regression cote autres deploys ni cote schedule ni cote Secret K8s, sans GitOps drift residuel.

GO PROD.

STOP.
