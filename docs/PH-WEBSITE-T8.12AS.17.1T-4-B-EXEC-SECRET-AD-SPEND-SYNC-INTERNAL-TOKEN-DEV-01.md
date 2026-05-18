# PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-SECRET AD_SPEND SYNC INTERNAL TOKEN DEV

> Date : 2026-05-18
> Linear : KEY-323 (parent KEY-322 tracking diagnostic Q-1T)
> Phase : AS.17.1T-4-B-EXEC-SECRET
> Environnement : keybuzz-api-dev uniquement
> Type : mutation secret controlee DEV (Vault KV + ExternalSecret GitOps + apply DEV)
> Priorite : Mode B SAFE pre-deploy, prerequis bloquant Q-1T-4-B-EXEC-DEPLOY-DEV

## VERDICT

GO DEV SECRET READY Q-1T-4-B-EXEC-SECRET. Token AD_SPEND_SYNC_INTERNAL_TOKEN haute entropie (32 bytes raw / 64 hex chars) genere sans affichage, ecrit dans Vault KV path `secret/keybuzz/ad_spend_sync/dev/internal_token` version 1 (hash8 `9686f338`), ExternalSecret `keybuzz-internal-tokens` committe (`ce573c4` push origin/main) et applique en `keybuzz-api-dev`, ESO Ready=True/SecretSynced (refreshTime 2026-05-18T20:11:00Z), Secret K8s Opaque contient exactement la cle AD_SPEND_SYNC_INTERNAL_TOKEN (metadata-only, NO decode), runtime DEV/PROD inchange (v3.5.190-channels-tenantguard-{dev,prod}, pods 46h+7h uptime, 0 restart), 0 deploy, 0 provider call, 0 DB write, 0 endpoint call, 0 valeur secret exposee.

Phase suivante autorisee uniquement par prompt separe **Q-1T-4-B-EXEC-DEPLOY-DEV** avec GO Ludovic explicite.

## Scope / hors scope

### Scope execute

- preflight read-only bastion + repos + cluster + ESO + Vault auth
- analyse conventions ESO existantes (litellm, jwt, postgres-admin, redis, db-migrator)
- generation manifest ExternalSecret /tmp mode 600 + kubectl apply --dry-run=server
- commit + push manifest GitOps keybuzz-infra/main
- generation token via Python `secrets.token_hex(32)` (haute entropie, JAMAIS imprime)
- ecriture payload JSON mode 600 via `os.open O_EXCL` (anti-clobber)
- vault kv put DEV via @file (token jamais en CLI args)
- shred -u payload + script gen-token
- vault kv metadata get (verification version 1, jamais value)
- kubectl apply DEV de l'ExternalSecret seul
- wait Ready=True/SecretSynced
- Secret K8s metadata-only (DataKeys list, base64 length, NO decode)
- non-regression runtime DEV/PROD
- cleanup /tmp/keybuzz-q1t4b-secret-*

### Hors scope (NON execute)

- Aucun deploy DEV de l'image v3.5.250-ad-spend-sync-all-dev
- Aucun deploy PROD
- Aucun manifest deployment.yaml modifie
- Aucun CronJob cree
- Aucun appel POST /admin/internal/ad-accounts/sync-all
- Aucun appel provider Meta/Google Ads
- Aucune ecriture DB (INSERT/UPDATE/DELETE/ALTER/TRUNCATE)
- Aucune rotation/mutation d'autres secrets (litellm, jwt, postgres, redis, db-migrator, etc.)
- Aucun commentaire Linear
- Aucun cleanup /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/
- Aucun kubectl set/edit/patch
- Aucun base64 -d / .data.* affichage

## Sources relues

- /opt/keybuzz/keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-4-B-AD-SPEND-DAILY-SYNC-CRONJOB-DRYRUN-01.md (a1f7e75 design)
- /opt/keybuzz/keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-CODE-AD-SPEND-SYNC-ALL-API-DRYRUN-PATCH-01.md (22f1144 patch)
- /opt/keybuzz/keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-4-B-EXEC-BUILD-AD-SPEND-SYNC-ALL-API-DEV-IMAGE-01.md (8068caf build)
- /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/externalsecret-litellm.yaml (convention ESO)
- /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/externalsecret-jwt.yaml + postgres-admin + redis + db-migrator (path Vault convention)
- /opt/keybuzz/keybuzz-api/src/modules/ad-accounts/internal-routes.ts (env var `AD_SPEND_SYNC_INTERNAL_TOKEN` priorite, fallback `KEYBUZZ_INTERNAL_PROXY_TOKEN`)
- Rapports Q-1A-bis-exec Mode B (pattern depot token Vault hors-transcript par Ludovic dans /root/.vault-root-token.tmp)

## Preflight (E0)

| Item | Valeur attendue | Valeur observee | Status |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD | descendant 8068caf | 8068caf -> ce573c4 (apres E3) | OK |
| keybuzz-infra dirty pre-E3 | clean | clean | OK |
| keybuzz-api HEAD | 01b163e4 reachable | reachable + endpoint mention + register OK | OK |
| ClusterSecretStore vault-backend | Ready=True/Valid | True/Valid | OK |
| ExternalSecret keybuzz-internal-tokens pre-E5 | absent | absent (NotFound) | OK |
| Secret keybuzz-internal-tokens pre-E5 | absent | absent (NotFound) | OK |
| Runtime DEV image | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-dev | OK |
| Runtime PROD image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | OK |
| Vault status | unsealed v1.21.1 Raft 3/5 | unsealed v1.21.1 Raft 3/5 | OK |
| Token depose Ludovic | /root/.vault-root-token.tmp mode 600 non-vide | 95 bytes mode 600 (2eme depot, 1er vide) | OK |
| Capabilities path data | create, read, update | create, read, update | OK |
| Capabilities metadata | read | read | OK |
| Path Vault target pre-E4 | absent | "No value found at secret/metadata/keybuzz/ad_spend_sync/dev/internal_token" | OK |

### Note pattern token Ludovic

Premier depot Ludovic : fichier `/root/.vault-root-token.tmp` mode 600 size **0 bytes** (vide). STOP propre annonce dans la conversation, aucune mutation. Deuxieme depot : 95 bytes mode 600, mtime 2026-05-18T19:53:17Z, valide. lookup-self silencieux (token type batch/limited probable, sans policies affichees par lookup-self grep) MAIS capabilities-self confirme les permissions adequates (create/read/update sur data path + read sur metadata path).

## Conventions ESO/Vault retenues (E1)

### Convention ExternalSecret existante (echantillon DEV)

```yaml
# externalsecret-litellm.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: keybuzz-litellm-secrets
  namespace: keybuzz-api-dev
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

| Existant | Path |
|---|---|
| litellm DEV | `secret/keybuzz/litellm/master_key` |
| db-migrator DEV | `secret/keybuzz/dev/db_migrator` |
| Q-1T-4-B-EXEC-SECRET DEV (new) | `secret/keybuzz/ad_spend_sync/dev/internal_token` |

Le path retenu inclut `ad_spend_sync` comme feature folder et `dev` comme env segment, coherent avec `secret/keybuzz/dev/db_migrator` (env explicit) mais avec un sous-segment feature additionnel pour clarte. Property `value` partagee avec toutes les conventions existantes.

### Collisions verifiees

- Aucun fichier `externalsecret-ad-spend*` existant dans `k8s/keybuzz-api-dev/`
- Aucun ExternalSecret nomme `keybuzz-internal-tokens` ni en DEV ni en PROD
- Aucun Secret K8s `keybuzz-internal-tokens` ni en DEV ni en PROD
- 10 ExternalSecrets DEV existants tous Ready=True (jwt, postgres-admin, postgres-kv, db-migrator, litellm, ses, stripe, minio, octopia, redis)

## Manifest ExternalSecret DEV (E2)

### Fichier final

`/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml`

```yaml
# Q-1T-4-B-EXEC-SECRET: Internal token for POST /admin/internal/ad-accounts/sync-all
# Materializes Secret keybuzz-internal-tokens (key AD_SPEND_SYNC_INTERNAL_TOKEN)
# Source : Vault KV secret/keybuzz/ad_spend_sync/dev/internal_token property value
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: keybuzz-internal-tokens
  namespace: keybuzz-api-dev
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
        key: secret/keybuzz/ad_spend_sync/dev/internal_token
        property: value
```

- Size : 701 bytes
- ASCII strict : OK, no BOM
- sha256 : `373847e4bca49acfb3827831e7a77af151f29d9fdee67d7ed5765d5ac742c3fd`

### kubectl apply --dry-run=server

```
externalsecret.external-secrets.io/keybuzz-internal-tokens created (server dry run)
```

Validation server-side passee. Re-verif post-dry-run : `kubectl get externalsecret keybuzz-internal-tokens` retourne NotFound (non-persistant confirme).

## Commit/push manifest GitOps (E3)

### git scope strict

```
git status --short :
?? k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml

git diff --cached --stat :
 k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml | 21 +++++
 1 file changed, 21 insertions(+)
```

### Commit + push

```
[main ce573c4] feat(api-dev): add ad_spend sync internal token ExternalSecret (AS.17.1T-4-B-EXEC-SECRET)
 1 file changed, 21 insertions(+)
 create mode 100644 k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml

To https://github.com/keybuzzio/keybuzz-infra.git
   8068caf..ce573c4  main -> main
push exit=0
```

HEAD post-push : `ce573c4`. status clean (0 lignes).

## Vault write DEV metadata-only (E4)

### Generation token (Python `secrets.token_hex(32)`)

| Champ | Valeur |
|---|---|
| Methode | `secrets.token_hex(32)` (32 bytes random raw -> 64 hex chars) |
| Charset | hex (verifie : tous chars dans [0-9a-f]) |
| Affichage stdout | NON, jamais |
| **hash8 sha256[:8]** | `9686f338` |
| Payload temp | `/tmp/keybuzz-q1t4b-secret-vault-payload.json` mode 600 (O_EXCL anti-clobber) |
| Payload size | 77 bytes (JSON `{"value":"<64-hex>"}`) |
| Script gen | `/tmp/keybuzz-q1t4b-secret-gen-token.py` mode 600 (SCP depuis local) |

### Commande vault kv put

```
vault kv put -mount=secret keybuzz/ad_spend_sync/dev/internal_token \
  @/tmp/keybuzz-q1t4b-secret-vault-payload.json
```

Sortie :

```
========== Secret Path ==========
secret/data/keybuzz/ad_spend_sync/dev/internal_token

======= Metadata =======
Key                Value
---                -----
created_time       2026-05-18T20:07:44.134532246Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```

Exit=0. Token JAMAIS en CLI args (passe via `@file`).

### Verification metadata-only

```
vault kv metadata get -mount=secret keybuzz/ad_spend_sync/dev/internal_token
```

Sortie :

```
===================== Metadata Path =====================
secret/metadata/keybuzz/ad_spend_sync/dev/internal_token

========== Metadata ==========
Key                     Value
---                     -----
cas_required            false
created_time            2026-05-18T20:07:44.134532246Z
current_version         1
custom_metadata         <nil>
delete_version_after    0s
last_updated_by         map[actor:token client_id:IYHGX1otZGEfsu2/etJawC4ynYhgqc+T36I6S8FlsDg= operation:create]
max_versions            0
oldest_version          0
updated_time            2026-05-18T20:07:44.134532246Z
```

Aucun `vault kv get` execute (qui aurait affiche la valeur). Seul metadata-only utilise.

### Cleanup token

```
shred -u /tmp/keybuzz-q1t4b-secret-vault-payload.json
shred -u /tmp/keybuzz-q1t4b-secret-gen-token.py
```

Verification post-shred : `ls /tmp/keybuzz-q1t4b-secret-vault-payload.json` -> `No such file or directory`. Variable Python `token` set to `None` apres ecriture, JAMAIS retournee.

## Apply DEV + ESO Ready (E5)

### kubectl apply

```
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/externalsecret-ad-spend-sync-internal-token.yaml
externalsecret.external-secrets.io/keybuzz-internal-tokens created
```

### Wait Ready

```
kubectl -n keybuzz-api-dev wait --for=condition=Ready externalsecret/keybuzz-internal-tokens --timeout=60s
externalsecret.external-secrets.io/keybuzz-internal-tokens condition met
wait exit=0
```

### Status ESO

| Champ | Valeur |
|---|---|
| ExternalSecret | keybuzz-internal-tokens |
| Ready | True |
| Reason | SecretSynced |
| RefreshTime | 2026-05-18T20:11:00Z |
| Last Transition Time | 2026-05-18T20:11:01Z |
| Events Warning | 0 |
| Events Normal | "secret created" |

## Secret K8s metadata-only (E5.3)

| Champ | Valeur |
|---|---|
| Name | keybuzz-internal-tokens |
| Namespace | keybuzz-api-dev |
| Type | Opaque |
| ResourceVersion | 70640708 |
| OwnerReferences[0] | ExternalSecret/keybuzz-internal-tokens (ESO owner correct, Owner mode) |
| DataKeys | `['AD_SPEND_SYNC_INTERNAL_TOKEN']` |
| KeyCount | 1 (convention single-key respectee) |
| Base64 length AD_SPEND_SYNC_INTERNAL_TOKEN | 88 chars (NO decode, NO display) |

L'encodage base64 de 64 chars hex (ASCII) donne 88 chars base64 (ceil(64/3*4) = 88), coherent avec token genere. AUCUN `base64 -d`, AUCUN jsonpath `.data.AD_SPEND_SYNC_INTERNAL_TOKEN` affichant valeur, AUCUN `kubectl get secret -o yaml` qui exposerait `.data`.

## Runtime non-regression (E6)

| Surface | Avant Q-1T-4-B-EXEC-SECRET | Apres E5 (cette phase) | Verdict |
|---|---|---|---|
| Runtime keybuzz-api DEV image | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-dev | INCHANGE |
| Runtime keybuzz-api PROD image | v3.5.190-channels-tenantguard-prod | v3.5.190-channels-tenantguard-prod | INCHANGE |
| Pod DEV keybuzz-api-587774dbb6-rzzmq | ready=true restarts=0 age=2026-05-16T21:02:07Z | identique 46h+ | INCHANGE |
| Pod PROD keybuzz-api-5874f4d576-4zr29 | ready=true restarts=0 age=2026-05-18T13:05:01Z | identique 7h+ | INCHANGE |
| Rollout DEV | aucun | aucun | INCHANGE |
| Rollout PROD | aucun | aucun | INCHANGE |
| Events Warning keybuzz-api-dev | aucun | aucun | INCHANGE |
| keybuzz-internal-tokens DEV ES | absent | Ready=True SecretSynced | NEW (attendu cette phase) |
| keybuzz-internal-tokens DEV Secret | absent | Opaque 1 key | NEW (attendu cette phase) |

## No fake metrics / no fake events (E7)

| Action | Execute par CE ? |
|---|---|
| Appel POST /admin/internal/ad-accounts/sync-all (DEV ou PROD) | NON |
| Appel POST /ad-accounts/:id/sync | NON |
| Appel Meta Ads API (graph.facebook.com) | NON |
| Appel Google Ads API (googleads.googleapis.com) | NON |
| Event GA4 / Meta CAPI / TikTok / LinkedIn emis | NON |
| Ecriture ad_spend_tenant ou ad_platform_accounts | NON |
| Modification dashboard/admin metrics | NON |
| Restart deploy DEV/PROD | NON |
| Logs API DEV grep `/sync-all` 20min | 0 matches confirme |

## Security / secret handling

| Risque | Mitigation appliquee |
|---|---|
| Token en stdout | Python `secrets.token_hex` capture en var locale, jamais print ; payload JSON via `os.open O_EXCL` ; vault kv put via `@file` jamais CLI arg |
| Token en bash history | aucun `export TOKEN=...` ; aucun `<<<` heredoc shell ; SCP du script gen-token avant exec ; shred apres |
| Token en /proc/cmdline | `vault kv put @file` -> argv liste `@/tmp/...path...json`, jamais la valeur |
| Token en rapport PH | hash8 sha256[:8] = `9686f338` seul, jamais la valeur |
| Token persist /tmp | shred -u immediat apres vault put (verifie absence) |
| Token persist Git | aucun fichier token committe ; .gitignore non requis car aucun fichier dans worktree |
| Token persist K8s manifest | manifest contient SEULEMENT le path Vault, pas la valeur ; ESO injecte la valeur cote cluster jamais en Git |
| Token via kubectl get secret | aucun `-o yaml`, aucun `-o jsonpath="{.data.AD_SPEND_SYNC_INTERNAL_TOKEN}"`, aucun base64 decode |
| .vault-root-token.tmp residual | fichier depose par Ludovic encore present `/root/.vault-root-token.tmp` 95B mode 600 ; cleanup par Ludovic recommande post-phase (CE ne touche pas /root/ files de Ludovic) |
| Audit Vault | `last_updated_by` capture le client_id token operation:create ; revue Vault audit log possible cote Ludovic |

## Cleanup temporary files (E8)

| Fichier | Statut |
|---|---|
| /tmp/keybuzz-q1t4b-secret-vault-payload.json | shred -u OK (absent confirme) |
| /tmp/keybuzz-q1t4b-secret-gen-token.py | shred -u OK (absent confirme) |
| /tmp/keybuzz-q1t4b-secret-externalsecret-dev.yaml | shred -u OK (absent confirme) post E5 |
| /tmp/ph118-backup/{routes.ts.bak,app.ts.bak} | CONSERVE (rollback Q-1T-4-B-EXEC-CODE, hors scope) |
| /root/.vault-root-token.tmp | non touche (responsabilite Ludovic, depose hors-transcript) |

## Rollback

### Rollback nominal (avant deploy futur)

1. `git revert ce573c4` sur keybuzz-infra/main
2. `git push origin main`
3. Pas de `kubectl apply` jusqu'a phrase rollback separee
4. ExternalSecret reste applique sur cluster mais le manifest n'est plus en source-of-truth

### Rollback destructif - phrases exactes requises

Pour supprimer l'ExternalSecret du cluster DEV :

```
GO ROLLBACK DELETE ADSPEND SYNC SECRET DEV Q-1T-4-B-EXEC-SECRET
```

Commande autorisee uniquement apres phrase :

```
kubectl -n keybuzz-api-dev delete externalsecret keybuzz-internal-tokens
```

Pour supprimer le path Vault DEV :

```
GO ROLLBACK DELETE VAULT ADSPEND SYNC TOKEN DEV Q-1T-4-B-EXEC-SECRET
```

Commande autorisee uniquement apres phrase (capabilities check : token Ludovic n'a peut-etre pas `delete` sur metadata path, a verifier) :

```
vault kv metadata delete secret/keybuzz/ad_spend_sync/dev/internal_token
```

### Rollback partiel (si compromission token suspectee)

1. Generer nouveau token via meme procedure
2. `vault kv put` cree version 2 (incremente)
3. ESO sync automatique (refreshInterval=1h, ou kubectl annotate force-sync)
4. Pod restart au prochain deploy (Reloader n'est pas configure sur cette image DEV pour ce Secret, donc restart manuel necessaire si pod deja deploye)

## Gaps restants pour Q-1T-4-B complet

1. **Q-1T-4-B-EXEC-DEPLOY-API-DEV** : patch manifest `keybuzz-api-dev/deployment.yaml` :
   - Image -> `ghcr.io/keybuzzio/keybuzz-api:v3.5.250-ad-spend-sync-all-dev` (digest pinned conseille `sha256:8ee7ebad...`)
   - env reference `AD_SPEND_SYNC_INTERNAL_TOKEN` via `secretKeyRef.name=keybuzz-internal-tokens, key=AD_SPEND_SYNC_INTERNAL_TOKEN`
   - commit + push + `kubectl apply -f` + `rollout status` + smoke `/admin/internal/ad-accounts/sync-all` dryRun=true avec curl + X-Internal-Token
2. **Q-1T-4-B-EXEC-SECRET-PROD** : phase symetrique sur namespace `keybuzz-api-prod` avec un AUTRE token genere (jamais reutiliser le token DEV en PROD). Path Vault `secret/keybuzz/ad_spend_sync/prod/internal_token` ou convention equivalente. GO Ludovic explicite distinct.
3. **Q-1T-4-B-EXEC-DEPLOY-API-PROD** : build PROD tag `v3.5.250-ad-spend-sync-all-prod` (meme commit 01b163e4, tag distinct), Mode B SAFE PROD avec GO Ludovic explicite.
4. **Q-1T-4-B-EXEC-CRONJOB** : commit manifest `cronjobs/ad-accounts-sync-daily.yaml` (draft Q-1T-4-B a1f7e75) + apply + premier run dryRun verifie.
5. **Q-1T-4-B-EXEC-VALIDATE** : premier cron tick LIVE + verify `last_sync_at` mis a jour + admin Acquisition payee affiche les valeurs synchronisees.

## Phases suivantes

| Phase | Pre-requis | Effet runtime |
|---|---|---|
| Q-1T-4-B-EXEC-DEPLOY-API-DEV | (1) image GHCR v3.5.250-ad-spend-sync-all-dev (DONE), (2) Secret keybuzz-internal-tokens AD_SPEND_SYNC_INTERNAL_TOKEN (DONE par cette phase) | rollout DEV |
| Q-1T-4-B-EXEC-SECRET-PROD | GO Ludovic explicite separe | aucun runtime (creation Secret PROD seulement) |
| Q-1T-4-B-EXEC-BUILD-PROD | meme commit 01b163e4, tag prod distinct | aucun runtime (image GHCR PROD nouvelle) |
| Q-1T-4-B-EXEC-DEPLOY-API-PROD | Mode B SAFE PROD GO explicite | rollout PROD |
| Q-1T-4-B-EXEC-CRONJOB | DEPLOY-API DONE | nouveau CronJob daily 06:00 UTC |
| Q-1T-4-B-EXEC-VALIDATE | CRONJOB DONE | live sync, premier remplissage ad_spend_tenant via cron |

## Brouillon Linear (NON poste sans GO separe)

```
KEY-323 update Q-1T-4-B-EXEC-SECRET DEV done

Secret K8s keybuzz-internal-tokens cree en keybuzz-api-dev via ExternalSecret GitOps :
- Vault KV secret/keybuzz/ad_spend_sync/dev/internal_token version 1 (hash8 9686f338)
- ExternalSecret manifest commit ce573c4 push origin/main
- ESO Ready=True SecretSynced
- Secret K8s Opaque cle AD_SPEND_SYNC_INTERNAL_TOKEN (metadata only)

Runtime DEV/PROD inchange (v3.5.190-channels-tenantguard-{dev,prod}, pods 46h+7h uptime).
0 deploy / 0 provider call / 0 DB write / 0 endpoint call / 0 valeur exposee.

Prochaines phases (sequence, chacune GO separee) :
1. Q-1T-4-B-EXEC-DEPLOY-API-DEV (patch deployment + apply + smoke dryRun)
2. Q-1T-4-B-EXEC-SECRET-PROD (nouveau token PROD distinct)
3. Q-1T-4-B-EXEC-BUILD-PROD (tag PROD same commit)
4. Q-1T-4-B-EXEC-DEPLOY-API-PROD (Mode B SAFE)
5. Q-1T-4-B-EXEC-CRONJOB (daily cron apply)
6. Q-1T-4-B-EXEC-VALIDATE (first live tick)
```

NON poste. Attente GO Linear separe par Ludovic.

## Phrase cible finale

Secret DEV AD_SPEND_SYNC_INTERNAL_TOKEN pret pour Q-1T-4-B-EXEC-DEPLOY-DEV : token haute entropie genere sans affichage (hash8 `9686f338` seul documente), Vault path DEV `secret/keybuzz/ad_spend_sync/dev/internal_token` version 1 ecrit avec metadata-only verifie, ExternalSecret `keybuzz-internal-tokens` committe (`ce573c4`) et pousse origin/main et applique en `keybuzz-api-dev`, ESO Ready=True/SecretSynced, Secret K8s Opaque OwnerRef=ExternalSecret contient la cle `AD_SPEND_SYNC_INTERNAL_TOKEN` metadata-only (base64 length 88 chars, NO decode, NO display), runtime DEV/PROD inchange (v3.5.190-channels-tenantguard-{dev,prod}, pods 46h+7h uptime, 0 restart), 0 deploy, 0 provider call, 0 DB write, 0 endpoint call, 0 valeur secret exposee. Phase suivante autorisee seulement par prompt separe Q-1T-4-B-EXEC-DEPLOY-DEV.

STOP
