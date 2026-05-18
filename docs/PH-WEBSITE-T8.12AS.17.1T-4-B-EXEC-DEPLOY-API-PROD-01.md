# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-PROD AD_SPEND SYNC-ALL API PROD DEPLOY

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-DEPLOY-API-PROD
> Environnement : keybuzz-api-prod (Mode B SAFE PROD)
> Type : GitOps PROD deployment image + rollout + smoke dryRun
> Priorite : P1 activation endpoint sync-all PROD avant CronJob daily

## VERDICT

GO PROD DEPLOY READY Q-1T-4-B-EXEC-DEPLOY-API-PROD. Manifest GitOps PROD committe (`9a9a45d`) et pousse sur origin/main avec image `v3.5.250-ad-spend-sync-all-prod` (digest `sha256:93cc663d...`) et env var `AD_SPEND_SYNC_INTERNAL_TOKEN` referencee depuis Secret PROD `keybuzz-internal-tokens`. `kubectl apply` PROD exit 0, rollout success ~30s, nouveau pod `keybuzz-api-768c76c558-fsd89` Running 1/1 restarts=0. Endpoint `POST /admin/internal/ad-accounts/sync-all` actif sur `api.keybuzz.io`. Smoke negatif (sans + wrong token same length) -> 403 FORBIDDEN_INTERNAL_ONLY x2. Smoke positif dryRun=true -> HTTP 200 sync=planned, 2 comptes actifs (1 google + 1 meta) tous skipped/dryRun, hash8 partout. Token PROD hash8 `ef85e12d` MATCH end-to-end Vault PROD -> ESO -> Secret K8s -> pod env -> endpoint, distinct du DEV (`9686f338`) confirme. Runtime DEV strictement inchange (`v3.5.250-ad-spend-sync-all-dev` generation 488, pod ~1h25 uptime). 0 provider call, 0 DB write, 0 fake metrics, 0 valeur secret exposee.

Phase suivante (Q-1T-4-B-EXEC-CRONJOB DEV puis PROD avec dryRun puis flip LIVE) attendra prompt + GO Ludovic distinct.

## Scope / hors scope

### Scope execute

- preflight read-only PROD (bastion + repos + runtime PROD/DEV + Secret PROD + image GHCR digest)
- patch manifest `k8s/keybuzz-api-prod/deployment.yaml` : image v3.5.190 -> v3.5.250 + ajout env var AD_SPEND_SYNC_INTERNAL_TOKEN via secretKeyRef (12-space indent PROD)
- kubectl apply --dry-run=server + kubectl diff (validation pre-commit)
- commit + push manifest GitOps keybuzz-infra/main
- STOP Gate Apply PROD (attente GO APPLY explicit) - respecte
- kubectl apply PROD (1 deployment)
- kubectl rollout status 180s timeout, success ~30s
- smoke E4.1 negative auth (sans token + wrong token same length) -> 403 x2
- smoke E4.2 positive auth dryRun=true (token PROD via Python urllib, sans cmdline leak) -> HTTP 200
- non-regression DEV + PROD final state + ES PROD Ready preserve
- cleanup /tmp temp files

### Hors scope (NON execute)

- Aucun CronJob cree
- Aucun appel sync non-dryRun
- Aucun provider call Meta / Google Ads
- Aucune ecriture DB (`ad_spend_tenant` / `ad_platform_accounts`)
- Aucun build Docker
- Aucune mutation Vault
- Aucun changement DEV
- Aucun changement client / admin / website / backend
- Aucun commentaire Linear
- Aucun base64 decode avec affichage
- Aucun `kubectl set image / env / patch / edit`
- Aucun `kubectl exec / run / port-forward / cp`

## Sources relues

- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE-AD-SPEND-SYNC-ALL-API-DRYRUN-PATCH-01.md (commit 22f1144)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-AD-SPEND-SYNC-ALL-API-DEV-IMAGE-01.md (commit 8068caf)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-AD-SPEND-SYNC-INTERNAL-TOKEN-DEV-01.md (commit 0526349)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-DEV-01.md (commit 5125a51, smoke dryRun DEV OK)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-PROD-AD-SPEND-SYNC-INTERNAL-TOKEN-01.md (commit 8d40f36, Secret PROD hash8 ef85e12d)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-PROD-AD-SPEND-SYNC-ALL-API-IMAGE-01.md (commit 7e323a1, image PROD digest sha256:93cc663d...)
- k8s/keybuzz-api-prod/deployment.yaml (manifest avant patch ligne 106 image + lignes 339-343 derniere env GOOGLE_ADS_REFRESH_TOKEN)
- k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml (ES PROD)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts (auth pattern AD_SPEND_SYNC_INTERNAL_TOKEN priority + KEYBUZZ_INTERNAL_PROXY_TOKEN fallback)

## Preflight (E0)

| Item | Attendu | Observe | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD avant | descendant 7e323a1 | 7e323a1 (clean) | OK |
| keybuzz-api HEAD | 01b163e4 reachable | reachable (lecture seule) | OK |
| PROD deploy image avant | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | OK |
| PROD deploy generation avant | n | 411 | OK |
| PROD ready | 1/1 | 1/1 | OK |
| PROD pod avant | keybuzz-api-5874f4d576-4zr29 started 2026-05-18T13:05:01Z restarts=0 | 8h45m uptime, 0 restart | OK |
| Warning events PROD 15m | 0 | 0 | OK |
| DEV deploy image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev (inchange) | OK |
| DEV deploy generation | 488 | 488 | OK |
| ES PROD keybuzz-internal-tokens | Ready=True/SecretSynced | Ready=True/SecretSynced refreshTime 2026-05-18T21:10:37Z | OK |
| Secret PROD K8s | Opaque 1 key | Opaque, RV 70661978, OwnerRef ExternalSecret/keybuzz-internal-tokens, keys=['AD_SPEND_SYNC_INTERNAL_TOKEN'] | OK |
| Image GHCR PROD digest | sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d | sha256:93cc663d9005338b3028808c359230df9c22f18104e650a6c48ac17df45bfe4d (match) | OK |

## Manifest patch PROD (E1)

### Fichier patch

`k8s/keybuzz-api-prod/deployment.yaml`

### Modifications (scope strict 2 sections)

```diff
@@ -103,7 +103,7 @@ spec:
           # PREVIOUS: v3.5.186-ai-rules-mut-tenantguard-prod
           # PREVIOUS: v3.5.187-google-observability-tenantguard-prod
           # PREVIOUS: v3.5.188-outbound-deliveries-tenantguard-prod
-          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod  # PH-SAAS-T8.12AS.14.1-PROD KEY-314 ... digest: sha256:71f0ddc5...
+          image: ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod  # PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-PROD (2026-05-18): deploy ad_spend sync-all API ; rollback: v3.5.190-channels-tenantguard-prod ; digest: sha256:93cc663d...

@@ -341,6 +341,11 @@ spec:
                 secretKeyRef:
                   name: keybuzz-google-ads
                   key: GOOGLE_ADS_REFRESH_TOKEN
+            - name: AD_SPEND_SYNC_INTERNAL_TOKEN
+              valueFrom:
+                secretKeyRef:
+                  name: keybuzz-internal-tokens
+                  key: AD_SPEND_SYNC_INTERNAL_TOKEN
           resources:
             requests:
               cpu: "200m"
```

Statistique : 6 insertions, 1 deletion. Aucun autre champ touche. Indentation PROD = 12 spaces avant `- name:` (vs DEV 8 spaces) ; le script `patch-deploy-prod.py` adapte.

### Note STAKATER deja cleanup PROD

Confirme : grep `STAKATER_VAULT_ROOT_TOKEN_SECRET|STAKATER_KEYBUZZ_API_JWT_SECRET` dans deployment.yaml PROD retourne 0 lignes. Cleanup Q-1B-5B-2A-EXEC bien applique (Option E retirer les env vars STAKATER de Git source). Cette phase ne reintroduit aucune env var Stakater.

### Note KEYBUZZ_INTERNAL_PROXY_TOKEN existant PROD

`KEYBUZZ_INTERNAL_PROXY_TOKEN: "true"` deja present ligne 295 (valeur litterale legacy pour endpoint `/internal-keybuzz`). Le code `internal-routes.ts` priorite `AD_SPEND_SYNC_INTERNAL_TOKEN || KEYBUZZ_INTERNAL_PROXY_TOKEN || ''`. Apres cette phase :
- AD_SPEND_SYNC_INTERNAL_TOKEN est resolu (Secret K8s, valeur entropie 64 hex chars distincte) -> utilisee en priorite par `/admin/internal/ad-accounts/sync-all`
- KEYBUZZ_INTERNAL_PROXY_TOKEN=`"true"` reste fallback theorique mais jamais utilise pour sync-all (priorite)
- `/internal-keybuzz` endpoint (agents/routes.ts) continue d'utiliser KEYBUZZ_INTERNAL_PROXY_TOKEN comme avant (legacy preserve)

Aucun risque ouvert par cette phase. Gap d'hygiene legacy documente : `KEYBUZZ_INTERNAL_PROXY_TOKEN="true"` reste un secret value faible mais hors scope cette phase (a aborder ulterieurement si besoin).

### Validation pre-commit

| Check | Resultat |
|---|---|
| `kubectl apply --dry-run=server` | "deployment.apps/keybuzz-api configured (server dry run)" PASS |
| `kubectl diff -f` | exit=0, montre generation 411->412 + image change + env add ; pas de STAKATER hex40 |
| ASCII strict | Manifest contient 51 em-dash UTF-8 dans commentaires historiques pre-existants ; non introduits par patch, kubectl/YAML OK (ASCII strict s'applique uniquement au rapport PH) |

## Commit/push GitOps (E2)

### Git scope strict

```
git status --short :
 M k8s/keybuzz-api-prod/deployment.yaml
```

### Commit + push

```
[main 9a9a45d] feat(api-prod): deploy ad_spend sync-all API image (AS.17.1T-4-B-EXEC-DEPLOY-PROD)
 1 file changed, 6 insertions(+), 1 deletion(-)

To https://github.com/keybuzzio/keybuzz-infra.git
   7e323a1..9a9a45d  main -> main
push exit=0
```

HEAD post-push : `9a9a45d`. status clean (0 lignes).

### STOP Gate Apply PROD (E2.4)

Post-push, verification avant apply :
- Argo CD : aucun auto-sync sur keybuzz-api-prod (push n'a pas declenche rollout)
- Runtime PROD POST-PUSH : `v3.5.190-channels-tenantguard-prod` generation `411` INCHANGE (confirme pas d'auto-sync)
- Apply = seule mutation runtime de cette phase

STOP annonce, attente GO APPLY explicit. GO recu : `GO APPLY API PROD Q-1T-4-B-EXEC-DEPLOY-PROD`.

## Apply + rollout PROD (E3)

### kubectl apply

```
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
deployment.apps/keybuzz-api configured
```

### Rollout status

```
kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=180s
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-api" successfully rolled out
rollout exit=0
```

### Before/After

| Item | Before | After |
|---|---|---|
| Image | v3.5.190-channels-tenantguard-prod | v3.5.250-ad-spend-sync-all-prod |
| Generation | 411 | 412 |
| Observed generation | 411 | 412 |
| Ready/replicas | 1/1 | 1/1 |
| Updated replicas | 1 | 1 |
| Pod name | keybuzz-api-5874f4d576-4zr29 | keybuzz-api-768c76c558-fsd89 |
| Pod started | 2026-05-18T13:05:01Z | 2026-05-18T21:55:31Z |
| Pod restart count | 0 | 0 |
| New ReplicaSet | keybuzz-api-5874f4d576 (active) | keybuzz-api-768c76c558 (new, desired=1 ready=1) |

### Image pull et startup

```
Pulling image "ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod"
Successfully pulled image "ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-prod" in 8.456s. Image size: 112054664 bytes.
```

Pas d'ImagePullBackoff, pas de CrashLoopBackoff, pas de CreateContainerConfigError. Pod status: Running, Restart Count: 0.

### Env AD_SPEND_SYNC_INTERNAL_TOKEN resolu

```
kubectl get pod keybuzz-api-768c76c558-fsd89 -o jsonpath='{...AD_SPEND_SYNC_INTERNAL_TOKEN...}'
AD_SPEND_SYNC_INTERNAL_TOKEN: secretRef=keybuzz-internal-tokens/AD_SPEND_SYNC_INTERNAL_TOKEN
```

Metadata-only ; la valeur n'est PAS inspectee ni decodee.

### Logs startup PROD (cleaned, no secrets)

```
[Compat] Amazon marketplace proxy routes registered
[CHANNELS-SAFETY] LEGACY_BACKEND_URL=http://keybuzz-backend.keybuzz-backend-prod.svc.cluster.local:4000
[CHANNELS-SAFETY] tenantId=bon-kb-mosf283z provider=amazon status=READY
[CHANNELS-SAFETY] tenantId=ecomlg-001 provider=amazon status=READY
[CHANNELS-SAFETY] tenantId=ecomlg-motxke32 provider=amazon status=READY
[CHANNELS-SAFETY] tenantId=romruais-gmail-com-mn7mc6xl provider=amazon status=READY
[CHANNELS-SAFETY] tenantId=switaa-sasu-mn9c3eza provider=amazon status=READY
[CHANNELS-SAFETY] tenantId=switaa-sasu-mnc1ouqu provider=amazon status=READY
[CHANNELS-SAFETY] Total Amazon connections: 6
[Channels] tenant_channels routes registered (/channels)
```

API PROD demarrage normal, 6 connexions Amazon multi-tenant restaurees, routes channels enregistrees. Aucune erreur startup.

### Health endpoint sanity (Ingress public PROD)

```
curl https://api.keybuzz.io/health
HTTP=200 time=0.201s
```

## Smoke tests dryRun (E4)

### E4.1 Negative auth PROD

#### Sans token (header absent)

```
curl -X POST -H "Content-Type: application/json" -d '{"dryRun":true}' \
  https://api.keybuzz.io/admin/internal/ad-accounts/sync-all
HTTP=403 time=0.205s
Body: {"error":"FORBIDDEN_INTERNAL_ONLY"}
```

#### Avec mauvais token (meme longueur 64 hex chars, secrets.token_hex(32) random different)

```
curl -X POST -H "Content-Type: application/json" \
  -H "X-Internal-Token: <random-wrong-token-not-shown>" \
  -d '{"dryRun":true}' https://api.keybuzz.io/admin/internal/ad-accounts/sync-all
HTTP=403 time=0.179s
Body: {"error":"FORBIDDEN_INTERNAL_ONLY"}
```

Auth defensive `timingSafeEqual` + length pre-check confirme OK PROD : meme avec token meme longueur, timingSafeEqual retourne false et renvoie 403.

### E4.2 Positive dryRun PROD

Realise via script Python `smoke-prod-positive.py` (urllib + base64 decode en variable Python). Token PROD lu depuis Secret K8s via `kubectl get secret keybuzz-internal-tokens`, decode base64 en variable Python (jamais print), envoye en header `X-Internal-Token`, variable wipe immediatement apres requete. Script shred -u apres execution.

```
Token PROD hash8 (verify match Vault PROD ef85e12d): ef85e12d
Token PROD distinct DEV (9686f338): True
HTTP_STATUS: 200
BODY_LENGTH: 348 bytes
STRUCTURED_RESPONSE:
{
  "account_count": 2,
  "accounts": [
    {
      "hash8": "0055f31c",
      "message": "dryRun",
      "platform": "google",
      "status": "skipped",
      "tenant_hash8": "78dea947"
    },
    {
      "hash8": "6fd93032",
      "message": "dryRun",
      "platform": "meta",
      "status": "skipped",
      "tenant_hash8": "78dea947"
    }
  ],
  "dryRun": true,
  "period": {
    "since": "2026-04-18",
    "until": "2026-05-18"
  },
  "platform_filter": "all",
  "sync": "planned"
}
```

### Synthese smoke

| Verification | Resultat |
|---|---|
| HTTP code negative no token | 403 |
| HTTP code negative wrong token same length | 403 (timingSafeEqual safe) |
| HTTP code positive dryRun=true | 200 |
| sync field | "planned" (dryRun mode, jamais "completed") |
| dryRun field | true |
| account_count | 2 (1 google + 1 meta) |
| accounts[*].status | tous "skipped" |
| accounts[*].message | tous "dryRun" |
| accounts[*].hash8 | hash sha256 8 chars (jamais account_id raw) |
| accounts[*].tenant_hash8 | hash sha256 8 chars sur PROD tenant (jamais tenant_id raw) |
| period defaults | since=now-30d (2026-04-18), until=today (2026-05-18) |
| Token hash8 client PROD | ef85e12d |
| Token hash8 Vault PROD ref (Q-1T-4-B-EXEC-SECRET-PROD) | ef85e12d |
| **Hash8 match end-to-end PROD** | MATCH (Vault PROD -> ESO -> Secret K8s -> pod env -> endpoint OK) |
| Token PROD distinct DEV | True (ef85e12d != 9686f338) |

### Comparaison smoke DEV vs PROD

| Champ | DEV smoke (Q-1T-4-B-EXEC-DEPLOY-API-DEV) | PROD smoke (cette phase) |
|---|---|---|
| Token hash8 client | 9686f338 | ef85e12d (distinct) |
| HTTP positive | 200 | 200 |
| account_count | 2 | 2 |
| accounts[0].hash8 (google) | 0055f31c | 0055f31c (meme account_id source) |
| accounts[1].hash8 (meta) | 6fd93032 | 6fd93032 (meme account_id source) |
| accounts[0].tenant_hash8 | 87fd9f6b (DEV tenant) | 78dea947 (PROD tenant) |
| accounts[1].tenant_hash8 | aa528bf1 (DEV tenant) | 78dea947 (PROD tenant) |

Account_id source identique DEV/PROD : les memes comptes Ads (Meta + Google) sont configures dans DEV et PROD (probablement KBC tenant Ludovic utilise les memes comptes Meta/Google Ads reels en DEV et PROD pour developpement + production). Tenants distincts confirme multi-tenant correct (multi-tenancy isolated par tenant_id, accounts partages possibles entre tenants si meme proprietaire). Aucun leak transverse.

## No DB write / no provider call (E4.3 + E6)

| Action | Execute par CE / par endpoint dryRun ? |
|---|---|
| POST /admin/internal/ad-accounts/sync-all dryRun=true | OUI 1x (smoke E4.2 PROD) |
| POST /admin/internal/ad-accounts/sync-all dryRun=false | NON |
| POST /ad-accounts/:id/sync | NON |
| Appel reseau Meta Ads API (graph.facebook.com) | NON (dryRun guard avant fetchFn dans syncOneAccount) |
| Appel reseau Google Ads API (googleads.googleapis.com) | NON (dryRun guard avant fetchFn dans syncOneAccount) |
| INSERT ad_spend_tenant | NON (dryRun guard avant INSERT loop) |
| UPDATE ad_platform_accounts (last_sync_at) | NON (dryRun guard skip cette mise a jour) |
| SELECT totals ad_spend_tenant | NON (dryRun retourne `rows:0, spend:0` sans SELECT) |
| Event GA4 / Meta CAPI / TikTok / LinkedIn | NON (endpoint INTERNAL, jamais branche outbound) |
| Dashboard metric force/fake | NON (aucun KPI touche) |

Logs PROD nouveau pod 5min confirment exactement 3 POST /admin/internal/ad-accounts/sync-all (req-6, req-7, req-d) correspondant aux smoke E4.1 negative (2x 403) + E4.2 positive (1x 200). Aucune autre requete vers cet endpoint.

DB read-only verification : non executee par CE (defer au code review Q-1T-4-B-EXEC-CODE qui prouve dryRun guard, confirme empiriquement par response `dryRun:true, all skipped`).

## Runtime non-regression PROD/DEV (E5)

### PROD apres deploy

| Item | Valeur |
|---|---|
| Deployment generation | 411 -> 412 (bump attendu cette phase) |
| Observed generation | 412 (match) |
| Ready replicas | 1/1 |
| Image runtime | v3.5.250-ad-spend-sync-all-prod (new) |
| ExternalSecret keybuzz-internal-tokens | Ready=True/SecretSynced (preserve) |
| Secret K8s RV | 70661978 (preserve, deja existant pre-deploy) |
| Pod | keybuzz-api-768c76c558-fsd89 Running 1/1 restarts=0 ~3min uptime |
| Events Warning PROD 10m | 0 |
| /health endpoint via ingress | HTTP 200 |
| Startup logs | Amazon channels READY (6 connexions multi-tenant) + tenant_channels routes registered |

### DEV strictement inchange

| Item | Avant | Apres | Verdict |
|---|---|---|---|
| Deployment image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev | INCHANGE |
| Deployment generation | 488 | 488 | INCHANGE |
| Ready replicas | 1/1 | 1/1 | INCHANGE |
| Pod | keybuzz-api-68cc9c967d-68pbx | keybuzz-api-68cc9c967d-68pbx (~1h25 uptime preserve) | INCHANGE |
| Pod restarts | 0 | 0 | INCHANGE |

Aucun rollout DEV, aucun apply DEV, aucun touch manifest DEV.

## No fake metrics / no fake events (E6)

- dryRun=true uniquement (smoke E4.2 retourne sync=planned, jamais sync=completed)
- 0 event GA4 / Meta CAPI / TikTok / LinkedIn emis (endpoint INTERNAL hors chaine outbound)
- 0 provider call Meta/Google Ads (dryRun guard verifie par smoke + code review)
- 0 ecriture ad_spend_tenant (dryRun guard avant INSERT)
- 0 dashboard metric force/fake (aucun KPI cluster touche)
- 0 admin Acquisition payee metric change PROD (sera observable seulement apres premier cron LIVE non-dryRun, hors scope cette phase)

## Rollback

### Rollback nominal PROD (si deploy KO)

1. `git revert 9a9a45d` sur keybuzz-infra/main
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml` (re-apply ancien manifest)
4. `kubectl rollout status` (verifier retour a v3.5.190-channels-tenantguard-prod)

### Rollback destructif (necessite phrase exacte)

```
GO ROLLBACK API PROD Q-1T-4-B-EXEC-DEPLOY-PROD
```

### Emergency runtime rollback (necessite phrase exacte, sans toucher Git)

```
GO ROLLBACK EMERGENCY UNDO API PROD Q-1T-4-B-EXEC-DEPLOY-PROD
```

Commande autorisee uniquement apres phrase :

```
kubectl -n keybuzz-api-prod rollout undo deploy/keybuzz-api
```

(A eviter sauf urgence car cree un drift Git/runtime.)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-CRONJOB DEV (dryRun)** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` DEV (draft Q-1T-4-B a1f7e75) avec body `dryRun:true` + apply + premier tick observe.
2. **Q-1T-4-B-EXEC-CRONJOB PROD (dryRun)** : symetrique PROD apres validation DEV CronJob.
3. **Q-1T-4-B-EXEC-VALIDATE (flip LIVE)** : modification CronJob body `dryRun:false` apres 24-48h dryRun OK observation + GO Ludovic explicite. Premier sync LIVE remplit `ad_spend_tenant` PROD + admin Acquisition payee affiche les valeurs synchronisees.

Important :
- Premier flip LIVE conseille en DEV d'abord pour validation provider call + DB write, puis PROD apres 24-48h observation DEV LIVE.
- Monitoring conseille : K8s events PROD + logs `[AdAccountsInternal]` + Vault audit log (jamais decoder le token) + comparer ad_spend_tenant.count avant/apres.

## Phases suivantes (ordre conseille)

| Sequence | Phase | Effet runtime | Pre-requis |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-CRONJOB DEV (dryRun) | CronJob daily 06:00 UTC DEV en mode dryRun | GO Ludovic |
| 2 | Q-1T-4-B-EXEC-CRONJOB PROD (dryRun) | CronJob daily 06:00 UTC PROD en mode dryRun | GO Ludovic + observation DEV cron OK |
| 3 | Q-1T-4-B-EXEC-VALIDATE flip DEV LIVE | premier sync LIVE non-dryRun DEV, INSERT ad_spend_tenant DEV | GO Ludovic |
| 4 | Q-1T-4-B-EXEC-VALIDATE flip PROD LIVE | premier sync LIVE PROD, admin Acquisition payee affiche valeurs reelles | observation 24h DEV LIVE OK + GO Ludovic |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-DEPLOY-API-PROD done

keybuzz-api PROD deploye sur image v3.5.250-ad-spend-sync-all-prod (digest
sha256:93cc663d...) via GitOps Mode B SAFE :
- manifest commit 9a9a45d push origin/main (image bump + env var
  AD_SPEND_SYNC_INTERNAL_TOKEN secretKeyRef)
- STOP Gate Apply PROD respecte (GO APPLY API PROD explicit recu)
- kubectl apply PROD + rollout successful (~30s)
- nouveau pod Running 1/1 restarts=0 (8.456s image pull)
- endpoint /admin/internal/ad-accounts/sync-all actif sur api.keybuzz.io
- smoke E4.1 negatif (sans + wrong token) -> 403 FORBIDDEN_INTERNAL_ONLY x2
- smoke E4.2 positif dryRun=true -> HTTP 200 sync=planned, 2 comptes
  actifs (1 google + 1 meta) tous status=skipped, hash8 systematique
- Token PROD hash8 ef85e12d MATCH end-to-end Vault PROD -> ESO -> Secret
  -> pod env -> endpoint, distinct DEV (9686f338) confirme

Runtime DEV strictement inchange : v3.5.250-ad-spend-sync-all-dev,
generation 488, pod 1h25 uptime preserve.

Contraintes : 0 provider call / 0 DB write / 0 endpoint non-dryRun /
0 fake metric / 0 valeur secret exposee.

Prochaines phases (chacune GO separee, prompt CE distinct) :
1. Q-1T-4-B-EXEC-CRONJOB DEV (dryRun=true)
2. Q-1T-4-B-EXEC-CRONJOB PROD (dryRun=true)
3. Q-1T-4-B-EXEC-VALIDATE (flip dryRun:false DEV puis PROD)
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

Deploy PROD keybuzz-api Q-1T-4-B-EXEC-DEPLOY-API-PROD complete : manifest GitOps PROD committe (`9a9a45d`) et pousse avec image `v3.5.250-ad-spend-sync-all-prod` (digest `sha256:93cc663d...`) + env `AD_SPEND_SYNC_INTERNAL_TOKEN` depuis Secret `keybuzz-internal-tokens`, STOP Gate Apply PROD respecte (GO APPLY explicit recu), kubectl apply PROD exit 0, rollout Ready 1/1 ~30s, pod `keybuzz-api-768c76c558-fsd89` Running restartCount=0, endpoint `POST /admin/internal/ad-accounts/sync-all` present sur api.keybuzz.io, smoke E4.1 negatif HTTP 403 x2, smoke E4.2 dryRun=true HTTP 200 sync=planned avec 2 comptes actifs (1 google + 1 meta) status=skipped, hash8 token `ef85e12d` match end-to-end Vault PROD->ESO->Secret->pod->endpoint distinct DEV `9686f338`, 0 provider call, 0 DB write, 0 fake metrics/events, DEV strictement inchangee (`v3.5.250-ad-spend-sync-all-dev`, generation 488, pod 1h25 uptime). Phase suivante Q-1T-4-B-EXEC-CRONJOB DEV+PROD (dryRun puis flip LIVE) uniquement via prompt separe et GO Ludovic explicite.

STOP
