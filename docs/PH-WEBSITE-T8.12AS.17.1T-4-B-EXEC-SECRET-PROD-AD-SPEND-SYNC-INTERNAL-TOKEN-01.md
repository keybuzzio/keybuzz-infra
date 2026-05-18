# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-PROD AD_SPEND SYNC INTERNAL TOKEN PROD

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-SECRET-PROD
> Environnement : keybuzz-api-prod uniquement (ESO/Secret PROD, aucune image/deploy)
> Type : mutation secret PROD controlee (Vault KV PROD + ExternalSecret GitOps + apply PROD)
> Priorite : Mode B SAFE pre-deploy PROD, prerequis bloquant Q-1T-4-B-EXEC-DEPLOY-API-PROD

## VERDICT

GO PROD SECRET READY Q-1T-4-B-EXEC-SECRET-PROD. Token PROD haute entropie (32 bytes raw / 64 hex chars) **distinct du DEV** (hash8 PROD `ef85e12d` != hash8 DEV `9686f338`), genere sans affichage, ecrit dans Vault KV path `secret/keybuzz/ad_spend_sync/prod/internal_token` version 1 (created_time 2026-05-18T21:10:19Z), ExternalSecret `keybuzz-internal-tokens` committe (`4189ae3` push origin/main) et applique en `keybuzz-api-prod`, ESO Ready=True/SecretSynced (refreshTime 2026-05-18T21:10:37Z), Secret K8s Opaque OwnerRef ExternalSecret contient exactement la cle `AD_SPEND_SYNC_INTERNAL_TOKEN` (metadata-only, NO decode), runtime PROD strictement inchange (`v3.5.190-channels-tenantguard-prod`, generation 411, pod `keybuzz-api-5874f4d576-4zr29` 8h uptime restartCount=0), DEV strictement inchange (`v3.5.250-ad-spend-sync-all-dev`, generation 488, ES Ready=True), 0 deploy, 0 provider call, 0 DB write, 0 endpoint call, 0 valeur secret exposee.

Phase suivante autorisee uniquement par prompt + GO Ludovic separe (Q-1T-4-B-EXEC-BUILD-PROD puis Q-1T-4-B-EXEC-DEPLOY-API-PROD en Mode B SAFE).

## Scope / hors scope

### Scope execute

- preflight read-only (bastion + repos + runtime PROD/DEV + ES PROD absent + Vault auth)
- analyse conventions ESO existantes via DEV manifest et 6 ES PROD existants (jwt, postgres, litellm, minio, octopia, redis)
- generation manifest ExternalSecret PROD /tmp mode 600 + kubectl apply --dry-run=server + non-persistance
- commit + push manifest GitOps keybuzz-infra/main
- generation token PROD via Python `secrets.token_hex(32)` (haute entropie, JAMAIS imprime), guard hash8 != DEV
- ecriture payload JSON mode 600 via `os.open O_EXCL` (anti-clobber)
- vault kv put PROD via `@file` (token jamais en CLI args)
- shred -u payload + script gen-token
- vault kv metadata get PROD (verification version 1, jamais value)
- kubectl apply PROD du seul ExternalSecret
- wait Ready=True/SecretSynced
- Secret K8s metadata-only (DataKeys list, base64 length, NO decode)
- non-regression runtime PROD/DEV (images inchangees, generations inchangees, pods uptime preserve)
- cleanup /tmp/keybuzz-q1t4b-secret-prod-*

### Hors scope (NON execute)

- Aucun deploy PROD de l'image v3.5.250
- Aucun deploy DEV
- Aucun manifest deployment.yaml modifie (ni PROD ni DEV)
- Aucun CronJob cree
- Aucun build Docker
- Aucun appel `POST /admin/internal/ad-accounts/sync-all`
- Aucun appel provider Meta / Google Ads
- Aucune ecriture DB (`ad_spend_tenant` / `ad_platform_accounts`)
- Aucune rotation/mutation d'autres secrets
- Aucun commentaire Linear
- Aucun base64 decode avec affichage
- Aucun `kubectl set image / env / patch / edit`
- Aucun `kubectl exec / run / port-forward`
- Aucun cleanup /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/

## Sources relues

- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE-AD-SPEND-SYNC-ALL-API-DRYRUN-PATCH-01.md (commit 22f1144, source code)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-AD-SPEND-SYNC-ALL-API-DEV-IMAGE-01.md (commit 8068caf, image GHCR)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET-AD-SPEND-SYNC-INTERNAL-TOKEN-DEV-01.md (commit 0526349, Secret DEV jumeau, hash8 ref 9686f338)
- docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-DEPLOY-API-DEV-01.md (commit 5125a51, deploy DEV smoke OK)
- k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml (DEV reference)
- k8s/keybuzz-api-prod/externalsecret-litellm.yaml + autres ES PROD (convention pattern)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts (env var priority)

## Preflight (E0)

| Item | Attendu | Observe | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD avant | descendant 5125a51 | 5125a51 -> 4189ae3 (apres E3) | OK |
| keybuzz-infra dirty pre-E3 | clean | clean | OK |
| keybuzz-api HEAD | 01b163e4 reachable | reachable (lecture seule) | OK |
| PROD deploy image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | OK |
| PROD generation | n | 411 | OK |
| PROD ready | 1/1 | 1/1 | OK |
| PROD pod uptime | preserve | keybuzz-api-5874f4d576-4zr29 started 2026-05-18T13:05:01Z (8h) restarts=0 | OK |
| DEV deploy image | v3.5.250-ad-spend-sync-all-dev (post Q-1T-4-B-EXEC-DEPLOY-DEV) | v3.5.250-ad-spend-sync-all-dev | OK |
| DEV generation | 488 (post-deploy) | 488 | OK |
| DEV ES Ready | True/SecretSynced (post Q-1T-4-B-EXEC-SECRET DEV) | True/SecretSynced rv 70640709 | OK |
| ES PROD keybuzz-internal-tokens pre-E5 | absent | NotFound | OK |
| Secret K8s PROD keybuzz-internal-tokens pre-E5 | absent | NotFound | OK |
| Warning events PROD 15m | 0 | 0 | OK |
| ClusterSecretStore vault-backend | Ready=True/Valid | True/Valid | OK |
| Token Vault depose Ludovic | /root/.vault-root-token.tmp 600 non-vide | 95B mode 600 mtime 2026-05-18 21:07:50Z | OK |
| Capabilities PROD data | create, read, update | create, read, update | OK |
| Capabilities PROD metadata | read | read | OK |
| Target PROD path pre-E4 | absent | "No value found at secret/metadata/keybuzz/ad_spend_sync/prod/internal_token" | OK |

### Note pattern token Ludovic

Premier depot Ludovic post Q-1T-4-B-EXEC-SECRET DEV : ABSENT (Ludovic l'avait shred apres DEV, recommandation respectee). STOP propre annonce dans la conversation. Deuxieme depot : token avec scope **DEV-only** (capabilities DEV path : `create/read/update` ; capabilities PROD path : `deny`). STOP propre re-annonce. Troisieme depot : token avec scope PROD adequat (`create/read/update` sur PROD data + `read` sur PROD metadata). Verification capabilities-self confirme permissions minimales requises sans surplus (principle of least privilege respecte par Ludovic).

## Conventions ESO/Vault retenues (E1)

### Convention ExternalSecret PROD existante (echantillon)

```yaml
# externalsecret-litellm-prod (sample)
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: keybuzz-litellm-secrets
  namespace: keybuzz-api-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: keybuzz-litellm-secrets
    creationPolicy: Owner
  data:
    - secretKey: LITELLM_MASTER_KEY
      remoteRef:
        key: secret/keybuzz/litellm/master_key
        property: value
```

### Pattern Vault path observe

| ES | Vault path |
|---|---|
| litellm PROD | `secret/keybuzz/litellm/master_key` |
| Q-1T-4-B-EXEC-SECRET DEV (existant) | `secret/keybuzz/ad_spend_sync/dev/internal_token` |
| **Q-1T-4-B-EXEC-SECRET-PROD (new)** | **`secret/keybuzz/ad_spend_sync/prod/internal_token`** |

Le path PROD utilise un sous-segment `/prod/` symetrique au DEV `/dev/` pour distinguer clairement les deux environnements. Property `value` partagee. Token PROD distinct du DEV (verification hash8 dans script Python).

### Collisions verifiees

- Aucun fichier `externalsecret-ad-spend-sync-internal-token.yaml` existant en `k8s/keybuzz-api-prod/`
- Aucun ExternalSecret nomme `keybuzz-internal-tokens` en PROD (NotFound confirme)
- Aucun Secret K8s `keybuzz-internal-tokens` en PROD (NotFound confirme)
- 6 ES PROD existants Ready=True (jwt, postgres, litellm, minio, octopia, redis)

## Manifest ExternalSecret PROD (E2)

### Fichier final

`/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml`

```yaml
# Q-1T-4-B-EXEC-SECRET-PROD: Internal token for POST /admin/internal/ad-accounts/sync-all
# Materializes Secret keybuzz-internal-tokens (key AD_SPEND_SYNC_INTERNAL_TOKEN)
# Source : Vault KV secret/keybuzz/ad_spend_sync/prod/internal_token property value
# Token PROD distinct from DEV (path /prod/ vs /dev/)
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: keybuzz-internal-tokens
  namespace: keybuzz-api-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: keybuzz-internal-tokens
    creationPolicy: Owner
  data:
    - secretKey: AD_SPEND_SYNC_INTERNAL_TOKEN
      remoteRef:
        key: secret/keybuzz/ad_spend_sync/prod/internal_token
        property: value
```

- Size : 763 bytes (4 commentaires d'en-tete vs 3 en DEV qui ajoutent 1 ligne)
- ASCII strict : OK, no BOM
- sha256 : `ee7d0f448fe529cdd9bba1710ea67a0b893cf710b9b19bebc0ae607e47b73b55`

### Diff conceptuel DEV vs PROD

| Champ | DEV manifest | PROD manifest |
|---|---|---|
| metadata.namespace | keybuzz-api-dev | keybuzz-api-prod |
| remoteRef.key | secret/keybuzz/ad_spend_sync/dev/internal_token | secret/keybuzz/ad_spend_sync/prod/internal_token |
| autres champs | identiques | identiques |

### kubectl apply --dry-run=server

```
externalsecret.external-secrets.io/keybuzz-internal-tokens created (server dry run)
```

Validation server-side OK. Non-persistance verifiee : `kubectl get externalsecret keybuzz-internal-tokens -n keybuzz-api-prod` retourne NotFound apres dry-run.

## Commit/push manifest GitOps (E3)

### git scope strict

```
git status --short :
?? k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml

git diff --cached --stat :
 k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml | 22 +++++
 1 file changed, 22 insertions(+)
```

### Commit + push

```
[main 4189ae3] feat(api-prod): add ad_spend sync internal token ExternalSecret (AS.17.1T-4-B-EXEC-SECRET-PROD)
 1 file changed, 22 insertions(+)
 create mode 100644 k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml

To https://github.com/keybuzzio/keybuzz-infra.git
   5125a51..4189ae3  main -> main
push exit=0
```

HEAD post-push : `4189ae3`. status clean.

## Vault write PROD metadata-only (E4)

### Generation token

| Champ | Valeur |
|---|---|
| Methode | `secrets.token_hex(32)` (32 bytes random raw -> 64 hex chars) |
| Charset | hex (verifie all chars dans [0-9a-f]) |
| **hash8 PROD sha256[:8]** | `ef85e12d` |
| **hash8 DEV ref Q-1T-4-B-EXEC-SECRET DEV** | `9686f338` |
| distinct_from_dev | True (ef85e12d != 9686f338) |
| Affichage stdout | NON, jamais |
| Payload temp | `/tmp/keybuzz-q1t4b-secret-prod-vault-payload.json` mode 600 (O_EXCL) |
| Payload size | 77 bytes |
| Script gen | `/tmp/keybuzz-q1t4b-secret-prod-gen-token.py` mode 600 (SCP depuis local) |

### Guard distinct DEV

Le script Python `gen-token-prod.py` integre un guard explicite :

```python
if hash8 == DEV_HASH8:
    print(f"FATAL: PROD hash8 collision with DEV {DEV_HASH8}, regenerate", file=sys.stderr)
    sys.exit(1)
```

Probabilite de collision sha256[:8] = 1 / 2^32 ~= 2.3e-10, mais defensive. Pas declenche cette execution.

### Commande vault kv put

```
vault kv put -mount=secret keybuzz/ad_spend_sync/prod/internal_token \
  @/tmp/keybuzz-q1t4b-secret-prod-vault-payload.json
```

Sortie :

```
========== Secret Path ==========
secret/data/keybuzz/ad_spend_sync/prod/internal_token

======= Metadata =======
Key                Value
---                -----
created_time       2026-05-18T21:10:19.303674012Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

Exit=0. Token JAMAIS en CLI args (passe via `@file`).

### Verification metadata-only

```
vault kv metadata get -mount=secret keybuzz/ad_spend_sync/prod/internal_token
```

Sortie :

```
===================== Metadata Path =====================
secret/metadata/keybuzz/ad_spend_sync/prod/internal_token

========== Metadata ==========
Key                     Value
---                     -----
cas_required            false
created_time            2026-05-18T21:10:19.303674012Z
current_version         1
custom_metadata         <nil>
delete_version_after    0s
last_updated_by         map[actor:token client_id:oSXwcR9h5aWFE6NSPEFt5uRr9JPYHL9Q/CW5eWOO5h0= operation:create]
max_versions            0
oldest_version          0
updated_time            2026-05-18T21:10:19.303674012Z
```

Aucun `vault kv get` execute. Seul metadata-only utilise. client_id du token PROD differe de celui du token DEV (operation:create par token operateur PROD distinct).

### Cleanup token

```
shred -u /tmp/keybuzz-q1t4b-secret-prod-vault-payload.json
shred -u /tmp/keybuzz-q1t4b-secret-prod-gen-token.py
```

Verification post-shred : `ls /tmp/keybuzz-q1t4b-secret-prod-vault-payload.json` -> `No such file or directory`. Variable Python `token` set to `None` apres ecriture, JAMAIS retournee.

`/root/.vault-root-token.tmp` NON shred par CE (hors scope ; cleanup par Ludovic recommande post-phase).

## Apply PROD + ESO Ready (E5)

### kubectl apply

```
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/externalsecret-ad-spend-sync-internal-token.yaml
externalsecret.external-secrets.io/keybuzz-internal-tokens created
```

### Wait Ready

```
kubectl -n keybuzz-api-prod wait --for=condition=Ready externalsecret/keybuzz-internal-tokens --timeout=60s
externalsecret.external-secrets.io/keybuzz-internal-tokens condition met
wait exit=0
```

### Status ESO

| Champ | Valeur |
|---|---|
| ExternalSecret | keybuzz-internal-tokens |
| Namespace | keybuzz-api-prod |
| Ready | True |
| Reason | SecretSynced |
| RefreshTime | 2026-05-18T21:10:37Z |
| Events Warning | 0 |
| Events Normal | "secret created" (27s ago at observation time) |

## Secret K8s PROD metadata-only (E5.3)

| Champ | Valeur |
|---|---|
| Name | keybuzz-internal-tokens |
| Namespace | keybuzz-api-prod |
| Type | Opaque |
| ResourceVersion | 70661978 |
| OwnerReferences[0] | ExternalSecret/keybuzz-internal-tokens (ESO Owner) |
| DataKeys | `['AD_SPEND_SYNC_INTERNAL_TOKEN']` |
| KeyCount | 1 (convention single-key respectee) |
| Base64 length AD_SPEND_SYNC_INTERNAL_TOKEN | 88 chars (NO decode, NO display) |

AUCUN `base64 -d`, AUCUN jsonpath `.data.AD_SPEND_SYNC_INTERNAL_TOKEN` affichant valeur, AUCUN `kubectl get secret -o yaml` qui exposerait `.data`.

## Runtime non-regression PROD/DEV (E6)

| Surface | Avant Q-1T-4-B-EXEC-SECRET-PROD | Apres E5 (cette phase) | Verdict |
|---|---|---|---|
| Runtime keybuzz-api PROD image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | INCHANGE |
| Runtime keybuzz-api PROD generation | 411 | 411 | INCHANGE |
| Runtime keybuzz-api PROD observed | 411 | 411 | INCHANGE |
| Runtime keybuzz-api PROD ready | 1/1 | 1/1 | INCHANGE |
| Pod PROD keybuzz-api-5874f4d576-4zr29 | started 2026-05-18T13:05:01Z restarts=0 | identique (~8h uptime) | INCHANGE |
| Rollout PROD | aucun | aucun | INCHANGE |
| Runtime keybuzz-api DEV image | v3.5.250-ad-spend-sync-all-dev | v3.5.250-ad-spend-sync-all-dev | INCHANGE |
| Runtime keybuzz-api DEV generation | 488 | 488 | INCHANGE |
| DEV ES keybuzz-internal-tokens | Ready=True/SecretSynced | Ready=True/SecretSynced rv 70640709 | INCHANGE |
| Events Warning PROD 10m | 0 | 0 | INCHANGE |
| PROD ES keybuzz-internal-tokens | absent | Ready=True/SecretSynced rv 70661978 | NEW (attendu cette phase) |
| PROD Secret keybuzz-internal-tokens | absent | Opaque 1 key | NEW (attendu cette phase) |

## No fake metrics / no fake events (E7)

| Action | Execute par CE ? |
|---|---|
| Appel POST /admin/internal/ad-accounts/sync-all (DEV ou PROD) | NON |
| Appel POST /ad-accounts/:id/sync | NON |
| Appel Meta Ads API (graph.facebook.com) | NON |
| Appel Google Ads API (googleads.googleapis.com) | NON |
| Event GA4 / Meta CAPI / TikTok / LinkedIn emis | NON |
| Ecriture ad_spend_tenant / ad_platform_accounts | NON |
| Modification dashboard/admin metrics | NON |
| Restart deploy DEV/PROD | NON |
| Build image | NON |
| Push GHCR | NON |

## Security / secret handling

| Risque | Mitigation appliquee |
|---|---|
| Token PROD identique DEV | guard Python `if hash8 == DEV_HASH8: sys.exit(1)`, verify `distinct_from_dev: True` documente |
| Token PROD reuse DEV par accident | path Vault distinct (`/prod/` vs `/dev/`), namespace K8s distinct (`-prod` vs `-dev`), commit message explicit |
| Token en stdout | Python capture en var locale, jamais print ; payload JSON via `os.open O_EXCL` ; vault kv put via `@file` jamais CLI arg |
| Token en bash history | aucun `export TOKEN=...` ; aucun heredoc shell `<<<` ; SCP du script gen-token avant exec ; shred apres |
| Token en /proc/cmdline | `vault kv put @file` -> argv liste `@/tmp/...path...json`, jamais la valeur |
| Token en rapport PH | hash8 sha256[:8] = `ef85e12d` seul, jamais la valeur (et hash8 DEV `9686f338` documente comme reference, sans le token DEV non plus) |
| Token persist /tmp | shred -u immediat apres vault put (verifie absence) |
| Token persist Git | aucun fichier token committe ; manifest contient SEULEMENT le path Vault, pas la valeur |
| Token via kubectl get secret | aucun `-o yaml`, aucun `-o jsonpath='{.data.AD_SPEND_SYNC_INTERNAL_TOKEN}'` affichant value, aucun base64 decode |
| .vault-root-token.tmp residual | encore present sur /root/ 95B mode 600 ; cleanup recommande post-phase (responsabilite Ludovic, CE ne touche pas /root/) |
| Audit Vault | `last_updated_by` capture le client_id token PROD distinct du client_id token DEV ; revue Vault audit log possible cote Ludovic |

## Cleanup temporary files (E8)

| Fichier | Statut |
|---|---|
| /tmp/keybuzz-q1t4b-secret-prod-vault-payload.json | shred -u OK (absent confirme) |
| /tmp/keybuzz-q1t4b-secret-prod-gen-token.py | shred -u OK (absent confirme) |
| /tmp/keybuzz-q1t4b-secret-prod-externalsecret.yaml | shred -u OK (absent confirme) post E5 |
| /tmp/ph118-backup/{routes.ts.bak,app.ts.bak} | CONSERVE (rollback Q-1T-4-B-EXEC-CODE, hors scope) |
| /root/.vault-root-token.tmp | non touche (responsabilite Ludovic ; recommandation `shred -u /root/.vault-root-token.tmp` post-phase) |

## Rollback

### Rollback nominal (avant deploy futur)

1. `git revert 4189ae3` sur keybuzz-infra/main
2. `git push origin main`
3. Pas de `kubectl apply` jusqu'a phrase rollback separee
4. ExternalSecret reste applique sur cluster mais le manifest n'est plus en source-of-truth Git

### Rollback destructif - phrases exactes requises

Pour supprimer l'ExternalSecret PROD du cluster :

```
GO ROLLBACK DELETE ADSPEND SYNC SECRET PROD Q-1T-4-B-EXEC-SECRET-PROD
```

Commande autorisee uniquement apres phrase :

```
kubectl -n keybuzz-api-prod delete externalsecret keybuzz-internal-tokens
```

Pour supprimer le path Vault PROD :

```
GO ROLLBACK DELETE VAULT ADSPEND SYNC TOKEN PROD Q-1T-4-B-EXEC-SECRET-PROD
```

Commande autorisee uniquement apres phrase (capabilities check : token actuel n'a pas `delete` sur metadata, necessitera autre token) :

```
vault kv metadata delete secret/keybuzz/ad_spend_sync/prod/internal_token
```

### Rollback partiel (si compromission token PROD suspectee)

1. Generer nouveau token via meme procedure
2. `vault kv put` cree version 2 (incremente)
3. ESO sync automatique au refreshInterval=1h OU kubectl annotate force-sync
4. Pod PROD restart au prochain deploy ou via Reloader si configure (a verifier sur PROD)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-BUILD-PROD** : docker build keybuzz-api PROD depuis commit `01b163e4` avec tag `v3.5.250-ad-spend-sync-all-prod` (meme code que DEV, tag distinct), OCI labels KEY-308, push GHCR, digest verify.
2. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : Mode B SAFE PROD avec GO Ludovic explicite. Patch manifest `k8s/keybuzz-api-prod/deployment.yaml` :
   - image v3.5.190 -> v3.5.250
   - ajout env var `AD_SPEND_SYNC_INTERNAL_TOKEN` via secretKeyRef vers `keybuzz-internal-tokens`
   - smoke dryRun=true PROD avec token PROD.
3. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B a1f7e75) DEV puis PROD + apply + premier run dryRun verifie.
4. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE non-dryRun + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

Important :
- Q-1T-4-B-EXEC-SECRET-PROD (cette phase) DOIT preceder Q-1T-4-B-EXEC-DEPLOY-API-PROD, sinon pod PROD demarrera sans token et endpoint retournera 403.
- Q-1T-4-B-EXEC-CRONJOB conseille en dryRun=true premier run, puis flip vers LIVE apres 24-48h d'observation.

## Phases suivantes (ordre conseille)

| Sequence | Phase | Effet runtime | Pre-requis |
|---|---|---|---|
| 1 | Q-1T-4-B-EXEC-BUILD-PROD | aucun runtime (image GHCR PROD nouvelle) | GO Ludovic + commit 01b163e4 reachable |
| 2 | Q-1T-4-B-EXEC-DEPLOY-API-PROD | rollout PROD | Mode B SAFE PROD GO explicite + Secret PROD ready (DONE cette phase) |
| 3 | Q-1T-4-B-EXEC-CRONJOB DEV (dryRun) | CronJob daily 06:00 UTC DEV en mode dryRun | GO Ludovic |
| 4 | Q-1T-4-B-EXEC-CRONJOB PROD (dryRun) | CronJob daily 06:00 UTC PROD en mode dryRun | GO Ludovic + DEPLOY-API-PROD done |
| 5 | Q-1T-4-B-EXEC-VALIDATE (flip vers LIVE) | premier sync LIVE non-dryRun, ad_spend_tenant remplit | observation 24h dryRun OK + GO Ludovic |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-SECRET-PROD done

Secret K8s keybuzz-internal-tokens cree en keybuzz-api-prod via
ExternalSecret GitOps :
- Vault KV secret/keybuzz/ad_spend_sync/prod/internal_token version 1
  (hash8 ef85e12d, distinct du DEV hash8 9686f338)
- ExternalSecret manifest commit 4189ae3 push origin/main
- ESO Ready=True/SecretSynced
- Secret K8s Opaque cle AD_SPEND_SYNC_INTERNAL_TOKEN (metadata only)

Runtime PROD inchange (v3.5.190-channels-tenantguard-prod, generation
411, pod 8h uptime, 0 restart). DEV inchange (v3.5.250-ad-spend-sync-all-dev,
generation 488, ES DEV Ready=True).

Token PROD genere par Python secrets.token_hex(32) avec guard explicite
distinct DEV. Vault audit log capture client_id distinct par environnement.

Contraintes : 0 deploy / 0 provider call / 0 DB write / 0 endpoint call /
0 valeur exposee.

Prochaines phases (sequence, chacune GO separee) :
1. Q-1T-4-B-EXEC-BUILD-PROD (tag PROD same commit)
2. Q-1T-4-B-EXEC-DEPLOY-API-PROD (Mode B SAFE)
3. Q-1T-4-B-EXEC-CRONJOB DEV+PROD (dryRun puis LIVE)
4. Q-1T-4-B-EXEC-VALIDATE (first live tick)
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

Secret PROD AD_SPEND_SYNC_INTERNAL_TOKEN pret pour Q-1T-4-B-EXEC-DEPLOY-API-PROD : token PROD distinct du DEV (hash8 `ef85e12d` != `9686f338`) genere sans affichage, Vault path PROD `secret/keybuzz/ad_spend_sync/prod/internal_token` version 1 ecrit avec metadata-only verifie, ExternalSecret `keybuzz-internal-tokens` committe (`4189ae3`) et pousse origin/main et applique en `keybuzz-api-prod`, ESO Ready=True/SecretSynced, Secret K8s Opaque OwnerRef=ExternalSecret contient la cle `AD_SPEND_SYNC_INTERNAL_TOKEN` metadata-only (base64 length 88 chars, NO decode), runtime PROD inchange (`v3.5.190-channels-tenantguard-prod`, generation 411, pod 8h uptime), DEV inchange (`v3.5.250-ad-spend-sync-all-dev`, generation 488), 0 deploy, 0 provider call, 0 DB write, 0 endpoint call, 0 valeur secret exposee. Phase suivante PROD deploy autorisee seulement par prompt separe Q-1T-4-B-EXEC-BUILD-PROD / DEPLOY-PROD avec GO Ludovic explicite.

STOP
