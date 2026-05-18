# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-DEV AD_SPEND SYNC-ALL API DEV DEPLOY

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-DEPLOY-API-DEV
> Environnement : keybuzz-api-dev uniquement (PROD strictly read-only)
> Type : GitOps DEV deployment image + rollout + smoke dryRun
> Priorite : Mode B SAFE pre-PROD, validation runtime DEV

## VERDICT

GO DEV DEPLOY READY Q-1T-4-B-EXEC-DEPLOY-API-DEV. Manifest GitOps DEV committe (`386ce72`) et pousse sur origin/main avec image `v3.5.250-ad-spend-sync-all-dev` (digest `sha256:8ee7ebad...`) et env var `AD_SPEND_SYNC_INTERNAL_TOKEN` referencee depuis Secret `keybuzz-internal-tokens`. `kubectl apply` DEV exit 0, rollout success en ~30s, nouveau pod `keybuzz-api-68cc9c967d-68pbx` Running 1/1 restarts=0. Endpoint `POST /admin/internal/ad-accounts/sync-all` actif en DEV via ingress `api-dev.keybuzz.io`. Smoke negatif (sans token + mauvais token) -> 403 FORBIDDEN_INTERNAL_ONLY. Smoke positif dryRun=true -> HTTP 200 avec response structurelle `sync:planned`, 2 comptes actifs (1 google + 1 meta) tous `status:skipped/message:dryRun`, hash8 partout, 0 provider call, 0 DB write. Token hash8 = `9686f338` MATCH end-to-end Vault -> ESO -> Secret -> pod env -> endpoint. Runtime PROD strictement inchange (`v3.5.190-channels-tenantguard-prod`, generation 411, pod 7h uptime, 0 restart).

Phase suivante autorisee uniquement par prompt + GO Ludovic separe (Q-1T-4-B-EXEC-SECRET-PROD, Q-1T-4-B-EXEC-BUILD-PROD, Q-1T-4-B-EXEC-DEPLOY-API-PROD, Q-1T-4-B-EXEC-CRONJOB).

## Scope / hors scope

### Scope execute

- preflight read-only (bastion + repos + runtime + Secret + image GHCR digest)
- patch manifest `keybuzz-api-dev/deployment.yaml` : image v3.5.190 -> v3.5.250 + ajout env var AD_SPEND_SYNC_INTERNAL_TOKEN via secretKeyRef
- kubectl apply --dry-run=server + kubectl diff (validation)
- commit + push manifest GitOps keybuzz-infra/main
- kubectl apply DEV (1 deployment)
- kubectl rollout status (180s timeout, success ~30s)
- smoke E4.1 negative auth (sans token + wrong token) -> 403
- smoke E4.2 positive auth (token via Secret, urllib Python sans cmdline leak) -> 200 dryRun=true
- non-regression PROD (image + generation + pods uptime)
- cleanup /tmp temp files

### Hors scope (NON execute)

- Aucune mutation PROD
- Aucun build Docker
- Aucun docker push
- Aucune mutation Vault
- Aucune creation CronJob
- Aucun appel sync non-dryRun
- Aucun provider call Meta / Google Ads
- Aucune ecriture `ad_spend_tenant` / `ad_platform_accounts`
- Aucun changement client / admin / website / backend
- Aucun commentaire Linear
- Aucun base64 decode avec affichage
- Aucun `kubectl set image / env / patch / edit`
- Aucun `kubectl exec / run / port-forward`

## Sources relues

- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-AD-SPEND-DAILY-SYNC-CRONJOB-DRYRUN-01.md (a1f7e75 design Option B)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE-AD-SPEND-SYNC-ALL-API-DRYRUN-PATCH-01.md (22f1144 source code)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-AD-SPEND-SYNC-ALL-API-DEV-IMAGE-01.md (8068caf build image)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-AD-SPEND-SYNC-INTERNAL-TOKEN-DEV-01.md (0526349 Secret DEV)
- k8s/keybuzz-api-dev/deployment.yaml (manifest pre-patch ligne 316 image + ligne 289 derniere env)
- k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml (cree par Q-1T-4-B-EXEC-SECRET)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts (auth pattern + hash8 + dryRun guard)

## Preflight (E0)

| Item | Attendu | Observe | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | descendant 0526349 | 0526349 (clean) | OK |
| keybuzz-infra dirty | none | none | OK |
| keybuzz-api commit 01b163e4 | reachable | reachable | OK |
| DEV deploy image avant | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-dev | OK |
| DEV deploy generation avant | n | 487 | OK |
| DEV pods | 1/1 ready | keybuzz-api-587774dbb6-rzzmq ready=true restarts=0 started=2026-05-16T21:02:07Z | OK |
| DEV Warning events 15m | 0 | 0 | OK |
| PROD deploy image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | OK |
| PROD deploy generation | n | 411 | OK |
| ExternalSecret keybuzz-internal-tokens | Ready=True/SecretSynced | Ready=True/SecretSynced refreshTime 2026-05-18T20:11:00Z | OK |
| Secret keybuzz-internal-tokens | Opaque, 1 key | Opaque, RV 70640708, OwnerRef ExternalSecret/keybuzz-internal-tokens, keys=['AD_SPEND_SYNC_INTERNAL_TOKEN'] | OK |
| Image GHCR digest | sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b | sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b (match) | OK |
| Ingress DEV path | /(Prefix) -> keybuzz-api:3001 | api-dev.keybuzz.io /(Prefix) -> keybuzz-api:3001 | OK |

## Manifest patch DEV (E1)

### Fichier patch

`k8s/keybuzz-api-dev/deployment.yaml`

### Modifications (scope strict 2 sections)

```diff
@@ -287,6 +287,11 @@ spec:
           value: ""
         - name: OUTBOUND_CONVERSIONS_WEBHOOK_SECRET
           value: ""
+        - name: AD_SPEND_SYNC_INTERNAL_TOKEN
+          valueFrom:
+            secretKeyRef:
+              name: keybuzz-internal-tokens
+              key: AD_SPEND_SYNC_INTERNAL_TOKEN
         # PREVIOUS: v3.5.99-meta-capi-test-endpoint-fix-dev  # PH-T8.7B.2
@@ -313,7 +318,7 @@ spec:
         # PREVIOUS: v3.5.187-google-observability-tenantguard-dev  # PH-SAAS-T8.12AS.13.1 KEY-313 (2026-05-14)
         # PREVIOUS: v3.5.188-outbound-deliveries-tenantguard-dev  # PH-SAAS-T8.12AS.13.2A KEY-313 (2026-05-14)
-        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev  # PH-SAAS-T8.12AS.14.1 KEY-314 (2026-05-14): ... rollback: v3.5.189-compat-amazon-tenantguard-dev ; digest: sha256:20033380...
+        image: ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev  # PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-DEV (2026-05-18): deploy ad_spend sync-all API ; rollback: v3.5.190-channels-tenantguard-dev ; digest: sha256:8ee7ebad8a52625e41f6e34528c1444a05f906152320bebb520a32aff1bc239b
         livenessProbe:
```

Statistique : 6 insertions, 1 deletion. Aucun autre champ touche.

### Validation pre-commit

| Check | Resultat |
|---|---|
| ASCII strict du manifest | NA (manifest contient em-dash dans commentaires historiques pre-existants, kubectl/YAML supportent UTF-8 ; ASCII strict ne s'applique qu'au rapport) |
| `kubectl apply --dry-run=server` | "deployment.apps/keybuzz-api configured (server dry run)" PASS |
| `kubectl diff -f` | exit=0, montre image change + env add + drift Stakater hex40 connu (hors scope, redacted ci-dessous) |

### Note drift Stakater Reloader hex40

`kubectl diff` revele 2 env vars runtime non-Git issues du Stakater Reloader auto-injection :
- `STAKATER_VAULT_ROOT_TOKEN_SECRET` value=`<REDACTED-stakater-hash40>`
- `STAKATER_KEYBUZZ_API_JWT_SECRET` value=`<REDACTED-stakater-hash40>`

Ces values sont des SHA1 hashes du Secret K8s (utilises par Reloader pour declencher restart pod quand un Secret rotated), pas des valeurs secret en clair. Drift connu et documente dans memoire `STAKATER_VAULT_ROOT_TOKEN_SECRET drift Git/runtime` (consequence Q-1B-5B-2A-EXEC option E = retirer ces vars de Git source). Cette phase NE TOUCHE PAS ces env vars (scope strict respecte). Hash40 redactes par convention.

## Commit/push GitOps (E2)

### Git scope strict

```
git status --short :
 M k8s/keybuzz-api-dev/deployment.yaml
```

Un seul fichier modifie. `git add` explicite par nom (jamais `-A` ni `.`).

### Commit + push

```
[main 386ce72] feat(api-dev): deploy ad_spend sync-all API image (AS.17.1T-4-B-EXEC-DEPLOY-DEV)
 1 file changed, 6 insertions(+), 1 deletion(-)

To https://github.com/keybuzzio/keybuzz-infra.git
   0526349..386ce72  main -> main
push exit=0
```

HEAD post-push : `386ce72`. status clean (0 lignes).

## Apply + rollout DEV (E3)

### kubectl apply

```
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
deployment.apps/keybuzz-api configured
```

### Rollout status

```
kubectl -n keybuzz-api-dev rollout status deploy/keybuzz-api --timeout=180s
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "keybuzz-api" rollout to finish: 1 old replicas are pending termination...
deployment "keybuzz-api" successfully rolled out
rollout exit=0
```

### Before/After

| Item | Before | After |
|---|---|---|
| Image | v3.5.190-channels-tenantguard-dev | v3.5.250-ad-spend-sync-all-dev |
| Generation | 487 | 488 |
| Observed | 487 | 488 |
| Ready/replicas | 1/1 | 1/1 |
| Updated replicas | 1 | 1 |
| Pod name | keybuzz-api-587774dbb6-rzzmq | keybuzz-api-68cc9c967d-68pbx |
| Pod started | 2026-05-16T21:02:07Z | 2026-05-18T20:32:43Z |
| Pod restart count | 0 | 0 |
| New ReplicaSet | n/a | keybuzz-api-68cc9c967d (desired=1, ready=1) |

### Image pull et startup

```
Pulling image "ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev"
Successfully pulled image "ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev" in 8.696s (8.696s including waiting). Image size: 112055319 bytes.
```

Pas d'ImagePullBackoff, pas de CrashLoopBackoff, pas de CreateContainerConfigError. Pod status: Running, Restart Count: 0.

### Env AD_SPEND_SYNC_INTERNAL_TOKEN resolu

```
kubectl get pod keybuzz-api-68cc9c967d-68pbx -o jsonpath='{...AD_SPEND_SYNC_INTERNAL_TOKEN...}'
AD_SPEND_SYNC_INTERNAL_TOKEN: secretRef=keybuzz-internal-tokens/AD_SPEND_SYNC_INTERNAL_TOKEN
```

Metadata-only ; la valeur n'est PAS inspectee ni decodee.

### Health endpoint sanity (via Ingress public DEV)

```
curl https://api-dev.keybuzz.io/health
HTTP=200
```

## Smoke tests dryRun (E4)

### E4.1 Negative auth

#### Sans token (header absent)

```
curl -X POST -H "Content-Type: application/json" -d '{"dryRun":true}' \
  https://api-dev.keybuzz.io/admin/internal/ad-accounts/sync-all
HTTP=403 time=0.156s
Body: {"error":"FORBIDDEN_INTERNAL_ONLY"}
```

#### Avec mauvais token (meme longueur, secrets.token_hex(32) random different)

```
curl -X POST -H "Content-Type: application/json" \
  -H "X-Internal-Token: <random-wrong-token-hash8-not-shown>" \
  -d '{"dryRun":true}' https://api-dev.keybuzz.io/admin/internal/ad-accounts/sync-all
HTTP=403 time=0.193s
Body: {"error":"FORBIDDEN_INTERNAL_ONLY"}
```

Auth defensive `timingSafeEqual` + length pre-check confirme OK : meme avec token meme longueur (donc passe length pre-check), `timingSafeEqual` retourne false et renvoie 403.

### E4.2 Positive dryRun

Realise via script Python `smoke-positive.py` (urllib + base64 decode en variable Python) afin d'eviter toute exposition cmdline shell. Token lu depuis Secret via `kubectl get secret ... -o jsonpath='{.data.AD_SPEND_SYNC_INTERNAL_TOKEN}'`, decode base64 en variable Python (jamais print), envoye en header `X-Internal-Token`, variable wipe immediatement apres requete. Script shred -u apres execution.

```
Token hash8 (verify match Vault Q-1T-4-B-EXEC-SECRET): 9686f338
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
      "tenant_hash8": "87fd9f6b"
    },
    {
      "hash8": "6fd93032",
      "message": "dryRun",
      "platform": "meta",
      "status": "skipped",
      "tenant_hash8": "aa528bf1"
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

| Verification | Resultat |
|---|---|
| HTTP code | 200 (auth accepte) |
| sync field | "planned" (dryRun mode, non "completed") |
| dryRun field | true |
| account_count | 2 (1 google + 1 meta) |
| accounts[*].status | tous "skipped" |
| accounts[*].message | tous "dryRun" |
| accounts[*].hash8 | hash sha256 8 chars (jamais account_id raw) |
| accounts[*].tenant_hash8 | hash sha256 8 chars (jamais tenant_id raw) |
| period.since | 2026-04-18 (defaults to today - 30d) |
| period.until | 2026-05-18 (defaults to today) |
| Token hash8 client | 9686f338 |
| Token hash8 Vault (Q-1T-4-B-EXEC-SECRET) | 9686f338 |
| Hash8 match end-to-end | MATCH (Vault -> ESO -> Secret -> pod env -> endpoint OK) |

## No DB write / no provider call (E4.3 + E6)

| Action | Execute par CE / par endpoint dryRun ? |
|---|---|
| POST /admin/internal/ad-accounts/sync-all dryRun=true | OUI 1x (smoke E4.2) |
| POST /admin/internal/ad-accounts/sync-all dryRun=false | NON |
| POST /ad-accounts/:id/sync | NON |
| Appel reseau Meta Ads API (graph.facebook.com) | NON (dryRun guard avant fetchFn dans syncOneAccount) |
| Appel reseau Google Ads API (googleads.googleapis.com) | NON (dryRun guard avant fetchFn dans syncOneAccount) |
| INSERT ad_spend_tenant | NON (dryRun guard avant INSERT loop) |
| UPDATE ad_platform_accounts (last_sync_at) | NON (dryRun guard skip cette mise a jour) |
| SELECT totals ad_spend_tenant | NON (dryRun retourne `rows:0, spend:0` sans SELECT) |
| Event GA4 / Meta CAPI / TikTok / LinkedIn | NON (endpoint INTERNAL, jamais branche outbound) |
| Dashboard metric force/fake | NON (aucun KPI touche) |

DB read-only verification : non executee par CE (defer au code review Q-1T-4-B-EXEC-CODE qui prouve dryRun guard, confirme empiriquement par response `dryRun:true, all skipped`).

## Runtime non-regression DEV/PROD (E5)

### DEV apres deploy

| Item | Valeur |
|---|---|
| Deployment generation | 487 -> 488 (bump attendu cette phase) |
| Observed generation | 488 (match) |
| Ready replicas | 1/1 |
| Image runtime | v3.5.250-ad-spend-sync-all-dev (new) |
| ExternalSecret keybuzz-internal-tokens | Ready=True/SecretSynced |
| Pod | keybuzz-api-68cc9c967d-68pbx Running 1/1 restarts=0 ~ 2min uptime |
| Events Warning DEV 10m | 0 |
| /health endpoint via ingress | HTTP 200 |

### PROD strictement inchange

| Item | Avant | Apres | Verdict |
|---|---|---|---|
| Deployment image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | INCHANGE |
| Deployment generation | 411 | 411 | INCHANGE |
| Observed generation | 411 | 411 | INCHANGE |
| Ready replicas | 1/1 | 1/1 | INCHANGE |
| Pod | keybuzz-api-5874f4d576-4zr29 | keybuzz-api-5874f4d576-4zr29 | INCHANGE |
| Pod restarts | 0 | 0 | INCHANGE |
| Pod started | 2026-05-18T13:05:01Z | 2026-05-18T13:05:01Z (~7h uptime preserve) | INCHANGE |

Aucun rollout PROD, aucun apply PROD, aucun touch manifest PROD.

## No fake metrics / no fake events (E6)

- dryRun=true uniquement (smoke E4.2 retourne sync=planned, jamais sync=completed)
- 0 event GA4 / Meta CAPI / TikTok / LinkedIn emis (endpoint INTERNAL hors chaine outbound)
- 0 provider call Meta/Google Ads (dryRun guard verifie par smoke + code review)
- 0 ecriture ad_spend_tenant (dryRun guard avant INSERT)
- 0 dashboard metric force/fake (aucun KPI cluster touche)
- 0 admin Acquisition payee metric change (sera observable seulement apres premier cron LIVE non-dryRun, hors scope cette phase)

## Cleanup temporary files

| Fichier | Statut |
|---|---|
| /tmp/keybuzz-q1t4b-deploy-resp-noauth.json | shred -u OK |
| /tmp/keybuzz-q1t4b-deploy-resp-wrongauth.json | shred -u OK |
| /tmp/keybuzz-q1t4b-deploy-smoke-positive.py | shred -u OK |
| /tmp/deployment.yaml.before (backup) | shred -u OK |
| /tmp/patch-deploy-dev.py (script local) | rm OK |
| /tmp/ph118-backup/ (Q-1T-4-B-EXEC-CODE rollback backup) | CONSERVE (hors scope) |
| /root/.vault-root-token.tmp | non touche (hors scope, responsabilite Ludovic, cleanup recommande post Q-1T-4-B-EXEC-SECRET-PROD) |

## Rollback

### Rollback nominal DEV (si deploy KO)

1. `git revert 386ce72` sur keybuzz-infra/main
2. `git push origin main`
3. `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml` (re-apply ancien manifest)
4. `kubectl rollout status` (verifier retour a v3.5.190-channels-tenantguard-dev)

### Rollback destructif (necessite phrase exacte)

```
GO ROLLBACK API DEV Q-1T-4-B-EXEC-DEPLOY-DEV
```

### Emergency runtime rollback (necessite phrase exacte, sans toucher Git source)

```
GO ROLLBACK EMERGENCY UNDO API DEV Q-1T-4-B-EXEC-DEPLOY-DEV
```

Commande autorisee uniquement apres phrase :

```
kubectl -n keybuzz-api-dev rollout undo deploy/keybuzz-api
```

(A eviter sauf urgence car cree un drift Git/runtime.)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-SECRET-PROD** : phase symetrique sur namespace `keybuzz-api-prod` avec un AUTRE token genere (jamais reutiliser le token DEV en PROD). Path Vault `secret/keybuzz/ad_spend_sync/prod/internal_token`. GO Ludovic explicite distinct.
2. **Q-1T-4-B-EXEC-BUILD-PROD** : docker build keybuzz-api PROD depuis commit `01b163e4` avec tag `v3.5.250-ad-spend-sync-all-prod`, OCI labels KEY-308, push GHCR PROD, digest verify.
3. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : Mode B SAFE PROD avec GO Ludovic explicite. Patch manifest `keybuzz-api-prod/deployment.yaml`, smoke dryRun=true PROD avec token PROD.
4. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B a1f7e75) DEV puis PROD + apply + premier run dryRun verifie.
5. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE non-dryRun + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

Important :
- Q-1T-4-B-EXEC-SECRET-PROD doit preceder Q-1T-4-B-EXEC-DEPLOY-API-PROD, sinon pod PROD demarrera sans token et endpoint retournera 403.
- Q-1T-4-B-EXEC-CRONJOB premier run conseille en dryRun=true via patch manifest CronJob, puis flip vers dryRun=false ou retire pour LIVE.

## Phases suivantes (ordre conseille)

| Sequence | Phase | Effet runtime | Pre-requis |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-SECRET-PROD | aucun runtime (Secret PROD seulement) | GO Ludovic |
| 2 | Q-1T-4-B-EXEC-BUILD-PROD | aucun runtime (image GHCR PROD nouvelle) | GO Ludovic + commit code 01b163e4 reachable |
| 3 | Q-1T-4-B-EXEC-DEPLOY-API-PROD | rollout PROD | Mode B SAFE PROD GO explicite + verify Secret PROD ready |
| 4 | Q-1T-4-B-EXEC-CRONJOB DEV (dryRun) | CronJob daily 06:00 UTC DEV en mode dryRun | GO Ludovic |
| 5 | Q-1T-4-B-EXEC-CRONJOB PROD (dryRun) | CronJob daily 06:00 UTC PROD en mode dryRun | GO Ludovic + DEPLOY-API-PROD done |
| 6 | Q-1T-4-B-EXEC-VALIDATE (flip vers LIVE) | premier sync LIVE non-dryRun, ad_spend_tenant remplit | observation 24h dryRun OK + GO Ludovic |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-DEPLOY-API-DEV done

keybuzz-api DEV deploye sur image v3.5.250-ad-spend-sync-all-dev (digest
sha256:8ee7ebad...) via GitOps :
- manifest commit 386ce72 push origin/main (image bump + env var
  AD_SPEND_SYNC_INTERNAL_TOKEN secretKeyRef)
- kubectl apply DEV + rollout successful (~30s)
- nouveau pod Running 1/1 restarts=0
- endpoint /admin/internal/ad-accounts/sync-all actif via ingress
  api-dev.keybuzz.io
- smoke E4.1 negatif (sans + mauvais token) -> 403 FORBIDDEN_INTERNAL_ONLY x2
- smoke E4.2 positif dryRun=true -> HTTP 200, sync=planned, 2 comptes
  actifs (1 google + 1 meta) tous status=skipped, hash8 systematique
- Vault -> ESO -> Secret -> pod env -> endpoint hash8 match end-to-end

Runtime PROD strictement inchange : image v3.5.190-channels-tenantguard-prod,
generation 411, pod 7h uptime, 0 restart.

Contraintes : 0 deploy PROD / 0 provider call / 0 DB write / 0 endpoint
non-dryRun / 0 fake metric / 0 valeur secret exposee.

Prochaines phases (chacune GO separee, prompt CE distinct) :
1. Q-1T-4-B-EXEC-SECRET-PROD
2. Q-1T-4-B-EXEC-BUILD-PROD
3. Q-1T-4-B-EXEC-DEPLOY-API-PROD (Mode B SAFE)
4. Q-1T-4-B-EXEC-CRONJOB DEV puis PROD (dryRun -> LIVE)
5. Q-1T-4-B-EXEC-VALIDATE
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

Deploy DEV keybuzz-api Q-1T-4-B-EXEC-DEPLOY-API-DEV complete : manifest GitOps DEV committe (`386ce72`) et pousse avec image `v3.5.250-ad-spend-sync-all-dev` + env `AD_SPEND_SYNC_INTERNAL_TOKEN` depuis Secret `keybuzz-internal-tokens`, kubectl apply DEV exit 0, rollout Ready 1/1 ~30s, pod `keybuzz-api-68cc9c967d-68pbx` Running restartCount=0, endpoint `POST /admin/internal/ad-accounts/sync-all` present, smoke E4.1 negatif HTTP 403 x2, smoke E4.2 dryRun=true HTTP 200 sync=planned avec 2 comptes actifs (1 google + 1 meta) status=skipped, hash8 token `9686f338` match end-to-end Vault->ESO->Secret->pod->endpoint, 0 provider call, 0 DB write, 0 fake metrics/events, PROD strictement inchangee (`v3.5.190-channels-tenantguard-prod`, generation 411, pod 7h uptime). Phase suivante PROD / Secret-PROD / CronJob uniquement via prompt separe et GO Ludovic explicite.

STOP
