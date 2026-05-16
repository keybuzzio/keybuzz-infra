# PH-WEBSITE-T8.12AS.17.1Q-1A-bis-exec-KEY-323-VAULT-ADMIN-TOKEN-REPLACEMENT-MODE-B-SAFE-01

> Date : 2026-05-16
> Linear : KEY-323
> Phase : AS.17.1Q-1A-bis-exec Mode B SAFE B0-B8
> Environnement : Vault HA Raft + Kubernetes + External Secrets Operator
> Bastion : install-v3 (46.62.171.61)

## VERDICT

GO VAULT ADMIN TOKEN MODE B COMPLETE.

Nouveau vault-admin-token non-root actif avec policy keybuzz-vault-renewer.
Deux anciens root tokens revoques (Option C, decision Ludovic apres ambiguite documentee).
Effet cascade sur 3 tokens applicatifs enfants observe et remedie via sous-phase R1.
Root temp token self-revoque.
Sept fichiers temporaires shred sur bastion (1 deja absent).
Vault HA Raft 3/3 unsealed, sync Raft index 1124919.
ExternalSecrets 30/30 SecretSynced=True.
Apps critiques Running 1/1 apres restart reloader (ages 113-116s post-R1).
Aucun secret affiche.

Phrase cible :
GO VAULT ADMIN TOKEN MODE B COMPLETE. Nouveau vault-admin-token non-root deja actif, vault-token-renew manuel R1 Complete apres cascade revoke, 2 anciens root tokens revoques avec certitude par decision Ludovic Option C, root temp token self-revoque, fichiers temporaires shred, ExternalSecrets/apps stables, aucun secret affiche. Rapport PH pret. Brouillon Linear KEY-323 pret pour Codex. NO GO PROD promotion maintenu jusqu'a Q-1B/Q-1F decision.

## Contexte initial

Echec manuel Ludovic sur vault policy write avec 403 invalid token (export VAULT_TOKEN local incorrect). Decision : runner CE Mode B SAFE borne avec root token temp depose hors transcript par Ludovic dans /root/.vault-root-token.tmp mode 600.

Etat Vault et incident :
- Vault HA Raft 3/3 unsealed apres action manuelle Ludovic sur vault-02 en Phase 0.5.
- vault-03 (10.0.0.155) active leader.
- 19 serveurs perimetre restaures clean post-incident Hetzner.
- ExternalSecrets pre-rotation : 30/30 SecretSynced=True.
- CronJob vault-token-renew (0 3 * * *) actif depuis 35 jours.

## B0 - Preflight (read-only sauf metadata fichier)

| Check | Resultat |
|---|---|
| Bastion identite | install-v3 / 46.62.171.61 |
| Date UTC | 2026-05-16 12:21:23 |
| Git keybuzz-infra | clean, HEAD 1064c6e |
| Root token file | -rw------- root:root 28 bytes |
| Vault 3 nodes | unsealed, Raft 1123390/1123390 sync |
| Active leader | vault-03 |

## B1 - Runner policy + nouveau admin token + patch K8s Secret

Runner SCP depuis bastion (pas SSH heredoc multi-lignes).

### B1.1 Root temp metadata (redacted)
display_name=root, policies=[root], TTL=0, orphan=true.

### B1.2 Policy minimale keybuzz-vault-renewer
HCL 3 paths :
- auth/token/lookup-self : read
- auth/token/renew : update
- auth/token/create : create,update,sudo

Policy ecrite avec succes, readback confirme contenu.

### B1.3 Nouveau admin token cree
Display name : vault-admin-token-postincident-2026-05-16
Policies : [default, keybuzz-vault-renewer]
Renewable : true
Lease : 2764800s (768h / 32 jours)
Period : 768h
Orphan : true
Accessor redacted : 2JVSfmbKRn...REDACTED

Ecrit dans /root/.vault-admin-token.new mode 600 root:root.

### B1.4 K8s Secret patche
kubectl create secret generic vault-admin-token --from-literal=token=... --dry-run=client -o yaml | kubectl apply -f -
Resultat : secret/vault-admin-token configured.

### B1.5 Verify K8s Secret metadata
resourceVersion=69448163, type=Opaque, keys=token.

## B2 - Trigger manuel vault-token-renew (premiere passe)

Job : vault-token-renew-manual-20260516122240
Status : Complete 1/1
Duration : 7s
Pod : vault-token-renew-manual-20260516122240-fp7tr Completed 0 restart.

Note : aucune mutation supplementaire de K8s Secrets en B2 car les tokens app existants etaient encore valides (TTL > threshold 7 jours). Script a fait lookup-self OK et skip rotate.

## B3 - Validation post-B1/B2

| Check | Resultat |
|---|---|
| Vault HA Raft 3/3 | unsealed, Raft 1123410/1123410 |
| ExternalSecrets | 30/30 SecretSynced=True |
| ClusterSecretStore valid events | 2x Normal Valid 18s post-job |
| ESO pods | 3/3 Running 0 restart |
| Apps critiques | toutes Running, 0 nouveau crashloop |
| Warning UnexpectedJob | normal pour job --from=cronjob |
| backfill-scheduler | ImagePullBackOff pre-existant (hors scope) |

## B4 - Inventaire accessors redacted

Outil : root temp + vault list auth/token/accessors + lookup -accessor par chaque accessor + redaction (10 premiers chars + REDACTED).

7 accessors observes (redacted) :

| Class | Accessor | display_name | policies | TTL | Period | issue_time | orphan | path |
|---|---|---|---|---|---|---|---|---|
| NEW_ADMIN | 2JVSfmbKRn...REDACTED | token-vault-admin-token-postincident-2026-05-16 | default,keybuzz-vault-renewer | 2759126 | 768h | 2026-05-16T12:22:22Z | true | auth/token/create |
| ROOT temp Ludovic | NKFcd4qiVL...REDACTED | root | root | 0 | - | ~2026-05-16T11:53 | true | auth/token/root |
| ROOT ancien #1 | vrMCXE0T38...REDACTED | root | root | 0 | - | ~2026-03-04 | true | auth/token/root |
| ROOT ancien #2 | IE2JZ90CMt...REDACTED | root | root | 0 | - | ~2026-03-14 | true | auth/token/root |
| keybuzz-app v2 | NtpyMB874S...REDACTED | token-keybuzz-k8s-app-2026-04-v2 | default,keybuzz-app-read,keybuzz-backend-rw | 1861389 | 768h | 2026-04-10T19:55Z | false | auth/token/create |
| keybuzz-backend 2026-04 | hIgUBlUnzx...REDACTED | token-keybuzz-k8s-backend-2026-04 | default,keybuzz-app-read,keybuzz-backend-rw | 1861389 | 768h | 2026-04-10T19:58Z | false | auth/token/create |
| keybuzz-backend auto | fj1XWAYtSm...REDACTED | token-keybuzz-k8s-backend-auto | default,keybuzz-app-read,keybuzz-backend-rw | 2725389 | 768h | 2026-05-16T03:00Z | false | auth/token/create |

Ambiguite documentee : Vault token lookup -accessor n'expose pas parent_accessor ni parent_id. Impossible de prouver via metadata seule lequel de vrMCXE0T38 ou IE2JZ90CMt etait l'ancien admin-token utilise par CronJob.

## B4.1 - Option C : revocation des 2 anciens roots (decision Ludovic)

Decision Ludovic apres presentation des 3 options A/B/C : Option C retenue (revoque les deux roots ambigus).

Runner SCP avec garde-fous :
- Prefixes cibles : vrMCXE0T38, IE2JZ90CMt
- Prefixes proteges : 2JVSfmbKRn, NKFcd4qiVL, NtpyMB874S, hIgUBlUnzx, fj1XWAYtSm
- Verification policy=root requise avant revoke
- Lookup metadata avant revoke (redacted)
- Verify no longer lookupable apres revoke

Resultat :

| Cible | Action | Resultat |
|---|---|---|
| vrMCXE0T38...REDACTED | vault token revoke -accessor | OK, no longer lookupable |
| IE2JZ90CMt...REDACTED | vault token revoke -accessor | OK, no longer lookupable |

Post-revoke accessor count : 2 (au lieu de 5 attendu).

### Effet cascade observe (non-anticipe au plan initial)

Les 3 tokens applicatifs (NtpyMB874S, hIgUBlUnzx, fj1XWAYtSm) etaient orphan=false donc enfants implicites d'un parent revoque. Vault les a revoque automatiquement en cascade. Cet effet n'est pas un bug, c'est le comportement standard documente de vault token revoke avec mode non-orphan.

Impact runtime potentiel : les 4 namespaces apps (keybuzz-api-prod/dev, keybuzz-backend-prod/dev) avaient des K8s Secrets vault-token/vault-app-token/vault-root-token contenant des tokens devenus invalides. Toute interaction Vault API des apps devait alors echouer 403.

## R1 - Remediation immediate (decision Ludovic apres alerte CE)

Decision Ludovic R1 immediate avant B5 : trigger nouveau job vault-token-renew avec nouveau admin-token deja en place dans vault-management/vault-admin-token, root temp encore actif comme filet de secours.

### R1 Job

Job : vault-token-renew-r1-20260516143206
Status : Complete 1/1
Duration : 15s
Logs filtres (egrep -v hvs|hvr|hvb|token=|X-Vault-Token|client_token|Authorization) :
```
[2026-05-16 14:32:09 UTC] OK: Root token read (95 chars)
[2026-05-16 14:32:09 UTC] OK: Root token valid (ttl=2757012, 0=never)
[2026-05-16 14:32:10 UTC] --- GROUP 1: API + Amazon workers ---
[2026-05-16 14:32:10 UTC] TOKEN1: ttl=-1s (0h)
[2026-05-16 14:32:10 UTC] WARN: TOKEN1 INVALID
[2026-05-16 14:32:13 UTC] OK: TOKEN1 recreated + secrets patched
[2026-05-16 14:32:13 UTC] --- GROUP 2: Backend ---
[2026-05-16 14:32:13 UTC] TOKEN2: ttl=-1s (0h)
[2026-05-16 14:32:13 UTC] WARN: TOKEN2 INVALID
[2026-05-16 14:32:15 UTC] OK: TOKEN2 recreated + secrets patched
[2026-05-16 14:32:18 UTC] OK: All restarts triggered
[2026-05-16 14:32:18 UTC] === COMPLETE: renewed=0 recreated=2 errors=0 ===
```

Le script a correctement detecte TTL=-1s (token revoque), cree 2 nouveaux tokens enfants via le nouveau admin-token, patche les 8 K8s Secrets, restart les 10 deployments.

### R1 K8s Secrets resourceVersion diff

| Namespace | Secret | Avant | Apres | Delta |
|---|---|---|---|---|
| keybuzz-api-prod | vault-root-token | 51176725 | 69494306 | BUMPED |
| keybuzz-api-prod | vault-app-token | 69247852 | 69494373 | BUMPED |
| keybuzz-api-dev | vault-root-token | 51176711 | 69494329 | BUMPED |
| keybuzz-api-dev | vault-app-token | 69247864 | 69494375 | BUMPED |
| keybuzz-backend-prod | vault-token | 51176768 | 69494359 | BUMPED |
| keybuzz-backend-prod | vault-app-token | 69247842 | 69494371 | BUMPED |
| keybuzz-backend-dev | vault-token | 51176757 | 69494365 | BUMPED |
| keybuzz-backend-dev | vault-app-token | 69247843 | 69494372 | BUMPED |

8/8 secrets bumped.

### R1 Deployment restartedAt annotation

Annotation vault-token-renew/restartedAt observee sur 10 deployments :
- keybuzz-api-prod/keybuzz-api : 2026-05-16T14:32:15Z
- keybuzz-api-prod/keybuzz-outbound-worker : 2026-05-16T14:32:15Z
- keybuzz-api-dev/keybuzz-api : 2026-05-16T14:32:16Z
- keybuzz-api-dev/keybuzz-outbound-worker : 2026-05-16T14:32:16Z
- keybuzz-backend-prod/keybuzz-backend : 2026-05-16T14:32:16Z
- keybuzz-backend-prod/amazon-orders-worker : 2026-05-16T14:32:16Z
- keybuzz-backend-prod/amazon-items-worker : 2026-05-16T14:32:17Z
- keybuzz-backend-dev/keybuzz-backend : 2026-05-16T14:32:17Z
- keybuzz-backend-dev/amazon-orders-worker : 2026-05-16T14:32:17Z
- keybuzz-backend-dev/amazon-items-worker : 2026-05-16T14:32:17Z

### R1 Inventaire accessors post-R1 (redacted)

4 accessors restants :

| Accessor | display_name | policies | TTL | period | orphan | renewable | issue_time |
|---|---|---|---|---|---|---|---|
| 3wjhHVy01J...REDACTED | token-keybuzz-k8s-api-auto | default,keybuzz-app-read,keybuzz-backend-rw | 2764753 | 2764800 | false | true | 2026-05-16T14:32:10Z |
| BdBzLPH4e8...REDACTED | token-keybuzz-k8s-backend-auto | default,keybuzz-app-read,keybuzz-backend-rw | 2764757 | 2764800 | false | true | 2026-05-16T14:32:14Z |
| NKFcd4qiVL...REDACTED | root | root | 0 | - | true | - | (root temp Ludovic, sera revoque B5) |
| 2JVSfmbKRn...REDACTED | token-vault-admin-token-postincident-2026-05-16 | default,keybuzz-vault-renewer | 2756965 | 2764800 | true | true | 2026-05-16T12:22:22Z |

### R1 Apps post-restart

| Namespace | Pod | Status | Age | Restarts |
|---|---|---|---|---|
| keybuzz-api-prod | keybuzz-api-7d5fd7d697-kf9dz | Running 1/1 | 40s | 0 |
| keybuzz-api-prod | keybuzz-outbound-worker-7bfb4944c4-tnsl6 | Running 1/1 | 39s | 0 |
| keybuzz-api-dev | keybuzz-api-594fbc5f76-qpfzj | Running 1/1 | 39s | 0 |
| keybuzz-api-dev | keybuzz-outbound-worker-6db9686c76-kdtwk | Running 1/1 | 39s | 0 |
| keybuzz-backend-prod | keybuzz-backend-56b9bc977d-v6jrw | Running 1/1 | 40s | 0 |
| keybuzz-backend-dev | keybuzz-backend-5bf66858f7-9kg42 | Running 1/1 | 39s | 0 |

Anciens pods en Terminating, nouveaux Running.

## B5 - Self-revoke root temp token

Commande : vault token revoke -self avec root token depuis /root/.vault-root-token.tmp.

| Etape | Resultat |
|---|---|
| Metadata before (redacted) | display_name=root, policies=[root], TTL=0, orphan=true |
| Self-revoke | OK |
| Verify lookup after | OK : token no longer valid |

## B6 - Cleanup fichiers temporaires

| Fichier | Action |
|---|---|
| /root/.vault-admin-token.new | shredded |
| /root/.vault-root-token.tmp | shredded |
| /tmp/keybuzz-vault-token-accessors-redacted.jsonl | shredded |
| /tmp/keybuzz-as17q1abis-b1-runner.sh | deja absent (shred apres B1) |
| /tmp/keybuzz-as17q1abis-b4-runner.sh | shredded |
| /tmp/keybuzz-as17q1abis-b41-runner.sh | shredded |
| /tmp/keybuzz-as17q1abis-r1-runner.sh | shredded |
| /tmp/keybuzz-last-vault-token-renew-job.txt | shredded |

Verification finale : tous 8 fichiers absents.

## B7 - Validation finale read-only

| Domaine | Resultat |
|---|---|
| Vault 3 nodes | unsealed, Raft 1124919/1124919, vault-03 active |
| ExternalSecrets | 30/30 SecretSynced=True |
| ClusterSecretStore valid events | 2x Normal Valid 72s post-R1 |
| ESO pods | 3/3 Running 0 restart |
| vault-management jobs | 3 jobs Complete (scheduled + manual + R1) |
| Apps keybuzz-api dev/prod | Running 1/1 age ~115s |
| Apps keybuzz-backend dev/prod | Running 1/1 age ~114s |
| Apps keybuzz-client dev/prod | Running 1/1 age 27h (non touche) |
| Apps seller-api/seller-client | Running 1/1 age 89d/27h (non touche) |
| backfill-scheduler | ImagePullBackOff pre-existant 27h, hors scope |
| Warning UnexpectedJob | 1x normal pour R1 --from=cronjob |
| Warning Unhealthy promtail | pre-existant, hors scope observability |
| Erreurs Vault auth | aucune |
| CrashLoopBackOff nouveau | aucun |

## Conformite interdits

| Interdit | Respect |
|---|---|
| Aucun token affiche | OK : seules metadata + accessor prefix 10 chars + REDACTED |
| Aucun root token | OK |
| Aucun unseal key | OK : Shamir generate-root manuel par Ludovic offline |
| Aucun accessor complet | OK : 10 premiers chars + REDACTED partout |
| Aucun KV secret | OK : pas de lecture KV |
| Aucun base64 secret data | OK : pas de kubectl get secret -o yaml/json complet |
| Ancien vault-admin-token NON lu | OK |
| kubectl patch/edit/set | OK : create secret --dry-run -o yaml + apply -f - uniquement |
| Bastion install-v3 | OK : seul bastion utilise |
| credentials/secrets locaux | OK : non touches |
| git reset/clean/force | OK : non utilises |

## Gaps restants

| Gap | Severite | Status | Next action |
|---|---|---|---|
| KV secrets rotation Q-1B | P0 | a planifier | Q-1B suite separe |
| Option 3 token-role allowed_policies | P2 | future amelioration | post Q-1B/Q-1F |
| backfill-scheduler ImagePullBackOff | P1 | pre-existant 27h | phase dediee |
| PROD promotion AS.17.0 / AS.17.0.1 | P0 NO GO | bloque jusqu'a Q-1B done | dependance Q-1B |
| KEY-322 webhook events DEV | P1 | related, non modifie | hors scope |
| Origine 2 anciens roots revoques | P3 | Option C decision | accepte par Ludovic |

## No fake metrics / no fake events

Toutes les observations sont issues de :
- kubectl get/describe/logs sur cluster reel
- vault status / vault list / vault token lookup sur Vault HA Raft reel
- vault token revoke / vault token create executions reelles
- vault policy write / read executions reelles

Aucune validation inventee. Aucun event/metric fabrique.

## AI feature parity / anti-regression

Read-only :
- keybuzz-api dev/prod (route Inbox, AI assist/evaluate/execute/guard, channels, autopilot) : pods Running post-restart, aucun crashloop nouveau.
- keybuzz-backend dev/prod (amazon orders/items workers, backfill) : pods Running post-restart.
- keybuzz-ai litellm-secrets : SecretSynced=True (unchanged).
- AI providers : non appeles.
- Messages/email/commande client : non declenches.

Pas de regression detectee dans le delta B0 -> B7.

## Brouillon Linear KEY-323 (a poster par Codex apres commit)

```
AS.17.1Q-1A-bis-exec Mode B SAFE COMPLETE

Commit rapport : <CE remplira apres push>
Verdict : GO VAULT ADMIN TOKEN MODE B COMPLETE.

Resume technique :
- Nouveau vault-admin-token non-root cree avec policy minimale keybuzz-vault-renewer (lookup-self read + renew update + create create+update+sudo).
- K8s Secret vault-management/vault-admin-token remplace (resourceVersion bumped).
- 2 anciens root tokens revoques sur decision Ludovic Option C (ambiguite documentee, Vault n'expose pas parent_accessor via lookup metadata).
- Effet cascade observe : 3 tokens applicatifs enfants revoques automatiquement.
- Remediation R1 : nouveau job vault-token-renew avec nouveau admin-token, 2 nouveaux tokens app crees, 8/8 K8s Secrets bumped, 10 deployments restartedAt via reloader, pods Running 1/1 post-restart.
- Root temp Ludovic self-revoke (B5).
- 7 fichiers temporaires shred sur bastion + 1 deja absent (B6).
- Validation finale (B7) : Vault HA Raft 3/3 unsealed Raft sync, ExternalSecrets 30/30 SecretSynced=True, ESO 3/3 Running, apps keybuzz-api/backend Running 1/1, ClusterSecretStores re-validated.
- Aucun secret affiche, aucun accessor complet, aucun KV value, runner SCP (pas SSH heredoc).

Gaps :
- Q-1B KV secrets rotation future.
- Option 3 token-role allowed_policies future amelioration.
- backfill-scheduler ImagePullBackOff dev+prod hors scope.
- PROD promotion AS.17.0 / AS.17.0.1 NO GO maintenu jusqu'a Q-1B.

Pas de changement de status KEY-323 ou KEY-322 sans GO supplementaire.
```

## STOP final

Aucun enchainement automatique sur Q-1B (KV rotation).
Aucun enchainement automatique sur PROD promotion.
Aucun enchainement automatique sur provider rotations externes.
Aucun enchainement automatique sur backfill-scheduler ImagePullBackOff.

Commit + push rapport en attente GO Ludovic explicite (Phase B9).
