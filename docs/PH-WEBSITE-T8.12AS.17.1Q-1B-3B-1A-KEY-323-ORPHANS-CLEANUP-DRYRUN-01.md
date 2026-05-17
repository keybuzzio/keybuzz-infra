# PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1A-KEY-323-ORPHANS-CLEANUP-DRYRUN-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-3B-1A orphans cleanup DRY-RUN read-only
> Environnement : DEV + keybuzz-ai read-only
> Bastion : install-v3 (46.62.171.61)

## 1. Verdict

GO Q-1B-3B-1A ORPHANS DRY-RUN READY.

5/5 Secrets cibles existent encore + metadata identiques a Q-1B-3A (0 labels + 0 annotations + 0 ownerReferences). 5/5 CONFIRMED 0 workload reference (deploy/sts/ds/cronjob/job specs 15 namespaces) + 0 pod consumer (running specs). 5/5 CONFIRMED 0 source code reference (6 repos applicatifs). 5/5 references trouvees uniquement dans docs/rapports historiques keybuzz-infra/docs (informational only, pas GitOps manifest actif). 5/5 Helm chart 0 reference (/opt/keybuzz/keybuzz-infra/helm contient 3 values files chatwoot/keybuzz/n8n, aucun litellm-runtime-key match). ESO alternatives Ready=True verifiees pour 4/5 doublons (keybuzz-api-jwt + octopia-credentials + keybuzz-api-postgres-kv + litellm-secret). vault-emergency-token cas particulier : **PH-VAULT-COMPATIBILITY-CHECK-01 recommande deja explicitement `kubectl delete secret vault-emergency-token -n keybuzz-api-dev`** (classification historique FAIBLE risque + recommandation supprimer). Revision Q-1B-3B-0 classification "RETAIN BREAK-GLASS" non justifiee par evidence runtime.

**Classification finale : 5/5 DELETE CANDIDATE SAFE** (avec nuances Ludovic pour vault-emergency-token retain optionnel break-glass + keybuzz-api-postgres-static retain optionnel ESO-fallback).

Phrase finale :
STOP AS.17.1Q-1B-3B-1A - GO Q-1B-3B-1A ORPHANS DRY-RUN READY. Rapport docs-only pret, en attente GO Ludovic commit/push. Q-1B-3B-1B EXEC et tous les autres lots restent NO GO.

## 2. Scope / hors scope

### Scope read-only strict

- Verify metadata 5 Secrets cibles (sans valeurs).
- Cross-reference workload + pods 15 namespaces.
- Cross-reference GitOps manifests keybuzz-infra.
- Cross-reference source code 6 repos applicatifs.
- Cross-reference Helm charts /opt/keybuzz/keybuzz-infra/helm.
- ESO alternatives Ready verification.
- Historical context (PH-VAULT-COMPATIBILITY-CHECK-01, PH_VAULT_REBUILD_01).
- Risk classification + future execution design.
- AI feature parity (focus litellm-runtime-key).

### Hors scope strict

- aucune suppression Secret.
- aucun patch/annotate/label.
- aucune lecture valeur secret.
- aucun base64 decode.
- aucun kubectl mutation.
- aucun vault kv mutation.
- aucun provider call.
- aucun build/deploy.
- aucun changement source/manifest.
- aucun commit/push sans GO final.

## 3. Sources relues

### Standards KeyBuzz

- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
- /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md

### Rapports KEY-323 + historiques pertinents

| Source | Commit | Facts extracted | Verdict |
|---|---|---|---|
| Q-1B-3A | 42dd9a6 | 5 orphelins identifies + 0 workload ref baseline | SOURCE PRINCIPALE |
| Q-1B-3B-0 | 52ddad9 | classification preliminaire RETAIN/DELETE/INVESTIGATE | reference (revision proposee) |
| Q-1F-2 | 9d82413 | infra stability OK baseline | reference |
| Q-1B-2B | 41b80a0 | rotator pattern Mode B SAFE | reference |
| PH-VAULT-COMPATIBILITY-CHECK-01 | historique | recommande explicitement DELETE vault-emergency-token + classification FAIBLE risque | **revision Q-1B-3B-0 vault-emergency-token RETAIN BREAK-GLASS non justifiee** |
| PH_VAULT_REBUILD_01-CURRENT-STATE | historique | mentionne litellm-runtime-key dans backup count K8s secrets (73 total) | informational |
| PH-WEBSITE-T8.12AS.17.1Q-0 | e6e0f26 | inventory baseline initial KEY-323 | reference |
| PH-WEBSITE-T8.12AS.17.1Q-1A | b27e94a | Vault verification rotation design | reference |
| PH-WEBSITE-T8.12AS.17.1Q-1A-bis | 1064c6e | Vault admin token replacement design | reference |
| PH-SRE-DB-ENDPOINT-NONREGRESSION-02 | historique | keybuzz-api-postgres-static = "OK" marker dans tableau | informational |
| PH17.1-API-ASSIST-RESTORE-01 | historique | keybuzz-api-postgres-static cree comme "backup" historique 2026-01-08 | informational |
| PH16-API-CONNECTION-RESTORE-01 | historique | meme contexte creation backup statique 2026-01-08 | informational |

## 4. Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Date | 2026-05-17 | 2026-05-17 18:42 UTC | OK |
| Git infra HEAD | descendant 52ddad9 | 52ddad9c... clean | OK |
| Git client HEAD | descendant f61763a | f61763a ancestor | OK |
| 6 fichiers temp KEY-323 | tous absents | 6/6 absent | OK |
| Rapports Q-1B-3A + Q-1B-3B-0 + Q-1F-2 + Q-1B-2B | presents | 4/4 OK | OK |

## 5. Target baseline (5 cibles strict)

Strict liste :
1. keybuzz-api-dev/vault-emergency-token
2. keybuzz-api-dev/keybuzz-api-postgres-static
3. keybuzz-api-dev/keybuzz-api-auth
4. keybuzz-api-dev/keybuzz-octopia
5. keybuzz-ai/litellm-runtime-key

Aucun autre Secret inclus.

## 6. Metadata-only verification (E2)

| Namespace | Secret | Exists | Type | Created | RV | Keys count | Key names | Labels | Annotations | Owner | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| keybuzz-api-dev | vault-emergency-token | YES | Opaque | 2026-02-06T15:00:22Z | 27323662 | 2 | DESCRIPTION, VAULT_TOKEN | {} | {} | [] | orphan |
| keybuzz-api-dev | keybuzz-api-postgres-static | YES | Opaque | 2026-01-08T06:23:39Z | 12186195 | 5 | PGDATABASE, PGHOST, PGPASSWORD, PGPORT, PGUSER | {} | {} | [] | orphan |
| keybuzz-api-dev | keybuzz-api-auth | YES | Opaque | 2026-02-11T03:43:15Z | 22449411 | 2 | COOKIE_SECRET, JWT_SECRET | {} | {} | [] | orphan |
| keybuzz-api-dev | keybuzz-octopia | YES | Opaque | 2026-02-11T03:43:16Z | 22449414 | 1 | OCTOPIA_CLIENT_SECRET | {} | {} | [] | orphan |
| keybuzz-ai | litellm-runtime-key | YES | Opaque | 2025-12-12T12:44:14Z | 869234 | 1 | LITELLM_RUNTIME_KEY | {} | {} | [] | orphan |

5/5 cibles existent. 5/5 metadata coherentes avec Q-1B-3A (0 changement depuis). 5/5 sans labels/annotations/ownerReferences = vraiment manuels orphelins (creation manuelle Ludovic ou script historique).

Note : keybuzz-api-auth + keybuzz-octopia crees meme date 2026-02-11T03:43:15-16Z (5 secondes d'ecart) = batch creation script probable.

## 7. Workload references verify (E3)

| Secret | Workload refs (15 ns) | Pod consumer refs | Evidence | Verdict |
|---|---|---|---|---|
| vault-emergency-token | 0 | 0 | jq filter deploy/sts/ds/cronjob/job specs + pods running specs 15 namespaces | CONFIRMED ORPHAN |
| keybuzz-api-postgres-static | 0 | 0 | idem | CONFIRMED ORPHAN |
| keybuzz-api-auth | 0 | 0 | idem | CONFIRMED ORPHAN |
| keybuzz-octopia | 0 | 0 | idem | CONFIRMED ORPHAN |
| litellm-runtime-key | 0 | 0 | idem | CONFIRMED ORPHAN |

Methode : kubectl get deploy,statefulset,daemonset,cronjob,job + kubectl get pods -A -> jq filter envFrom.secretRef.name + env[].valueFrom.secretKeyRef.name + volumes[].secret.secretName + imagePullSecrets[].name.

## 8. GitOps / source / helm references (E4+E5)

| Secret | GitOps manifest actif | GitOps docs/rapports historiques | Source code 6 repos | Helm charts | Meaning | Verdict |
|---|---|---|---|---|---|---|
| vault-emergency-token | 0 | 6 rapports docs (PH-VAULT-COMPATIBILITY-CHECK-01 incl. recommandation DELETE + Q-1B-3A + Q-1A KEY-323 + Q-0 + Q-1A-bis + Q-1B-3B-0) | 0 | 0 | docs historiques uniquement, aucun manifest actif | CONFIRMED ORPHAN + recommandation DELETE historique |
| keybuzz-api-postgres-static | 0 | 7 rapports docs (Q-1B-3A + Q-1A + PH-SRE-DB + PH17.1-API + PH16-API + Q-0 + Q-1B-3B-0) | 0 | 0 | docs historiques uniquement, cree 2026-01-08 comme backup PH16-API-CONNECTION-RESTORE | CONFIRMED ORPHAN historique backup |
| keybuzz-api-auth | 0 | 2 rapports docs (Q-1B-3A + Q-1B-3B-0) | 0 | 0 | docs uniquement (recents) | CONFIRMED ORPHAN |
| keybuzz-octopia | 0 | 3 rapports docs (Q-1B-3A + Q-0 + Q-1B-3B-0) | 0 | 0 | docs uniquement | CONFIRMED ORPHAN |
| litellm-runtime-key | 0 | 5 rapports docs (Q-1B-3A + Q-1A + PH_VAULT_REBUILD_01 backup count + Q-0 + Q-1B-3B-0) | 0 | 0 | docs uniquement, mentionne dans backup count historique | CONFIRMED ORPHAN historique LiteLLM ancien |

5/5 references trouvees = docs/rapports informationals uniquement. 0 GitOps manifest actif, 0 source code, 0 Helm chart values.

## 9. ESO duplicate / source-of-truth verification (E6)

| Secret | Active ESO alternative | ESO Ready | Target Secret rv | Keys match | Duplicate? | Verdict |
|---|---|---|---|---|---|---|
| vault-emergency-token | NO ESO equivalent (different keys DESCRIPTION+VAULT_TOKEN vs vault-app-token VAULT_TOKEN+token vs vault-admin-token token) | N/A | N/A | NO | NO STRICT DUPLICATE | orphan break-glass historique 2026-02-06, PH-VAULT-COMPATIBILITY-CHECK-01 recommande supprimer |
| keybuzz-api-postgres-static | ESO keybuzz-api-postgres-kv -> target keybuzz-api-postgres | Ready=True refreshTime 18:44:37Z | 31857810 | YES exactes (PGDATABASE+PGHOST+PGPASSWORD+PGPORT+PGUSER) | **YES DUPLICATE** | orphan backup historique, ESO source-of-truth active |
| keybuzz-api-auth | ESO keybuzz-api-jwt -> target keybuzz-api-jwt | Ready=True refreshTime 18:02:07Z | 69633483 (post Q-1B-1B rotation) | YES exactes (COOKIE_SECRET+JWT_SECRET) | **YES DUPLICATE** | orphan obsolete, ESO source-of-truth active rotated |
| keybuzz-octopia | ESO octopia-credentials -> target octopia-credentials | Ready=True refreshTime 18:26:41Z | 31857837 | YES subset (orphan a 1 key OCTOPIA_CLIENT_SECRET subset des 4 keys ESO) | **YES DUPLICATE** | orphan obsolete, ESO source-of-truth active complete |
| litellm-runtime-key | ESO litellm-secrets -> target litellm-secret | Ready=True | 31857794 | NO (orphan key LITELLM_RUNTIME_KEY pas dans ESO keys [ANTHROPIC_API_KEY, DATABASE_URL, LITELLM_DATABASE_URL, LITELLM_MASTER_KEY, OPENAI_API_KEY, USE_PRISMA_MIGRATE]) | NO STRICT DUPLICATE | orphan historique LiteLLM ancien deployment, helm chart 0 ref |

ESO Ready confirmes pour 4 alternatives (a part vault-emergency-token qui n'a pas d'ESO equivalent direct).

litellm Deployment runtime envFrom = [litellm-secret, litellm-db-secret] - **litellm-runtime-key non reference par le Deployment actuel**.

## 10. Risk classification (revision finale)

| Secret | Q-1B-3B-0 proposition | Q-1B-3B-1A revision finale | Rationale | Future action | Rollback reality | Validation future |
|---|---|---|---|---|---|---|
| vault-emergency-token | RETAIN BREAK-GLASS + label | **DELETE_CANDIDATE_SAFE** (Ludovic decision retain-or-delete) | 0 workload ref + 0 source ref + 0 helm + PH-VAULT-COMPATIBILITY-CHECK-01 historique recommande DELETE + classifie FAIBLE risque. Si Ludovic veut RETAIN BREAK-GLASS, documenter usage explicite + ajouter label keybuzz.io/purpose=break-glass-do-not-delete. Sinon DELETE. | Q-1B-3B-1B exec `kubectl delete secret vault-emergency-token -n keybuzz-api-dev` (apres GO Ludovic explicite) | irreversible si Ludovic n'a pas backup offline (rare cas usage break-glass) | post-delete : verify backend stability + Vault token-renew CronJob inchange |
| keybuzz-api-postgres-static | RETAIN BACKUP/ESO-FALLBACK + label | **DELETE_CANDIDATE_SAFE** (Ludovic decision retain-or-delete) | 0 workload ref + ESO keybuzz-api-postgres rv=31857810 Ready=True confirme = source-of-truth active. Si Ludovic veut RETAIN BACKUP, documenter pattern explicite + add label keybuzz.io/purpose=eso-fallback-backup. Sinon DELETE. | Q-1B-3B-1B exec `kubectl delete secret keybuzz-api-postgres-static -n keybuzz-api-dev` (apres GO Ludovic) | irreversible si ESO casse pendant outage (rare scenario) | post-delete : verify keybuzz-api-dev/keybuzz-api pod stable + ESO keybuzz-api-postgres-kv toujours Ready |
| keybuzz-api-auth | DELETE CANDIDATE | **DELETE_CANDIDATE_SAFE** | 0 workload ref + ESO keybuzz-api-jwt rv=69633483 Ready=True rotated Q-1B-1B = source-of-truth active. Keys IDENTIQUES (COOKIE_SECRET, JWT_SECRET) = doublon strict. | Q-1B-3B-1B exec `kubectl delete secret keybuzz-api-auth -n keybuzz-api-dev` | reversible via recreate manuel mais inutile car ESO actif | post-delete : verify keybuzz-api Deployment stable (consomme keybuzz-api-jwt ESO) |
| keybuzz-octopia | DELETE CANDIDATE | **DELETE_CANDIDATE_SAFE** | 0 workload ref + ESO octopia-credentials rv=31857837 Ready=True keys complete [OCTOPIA_API_URL, OCTOPIA_AUTH_URL, OCTOPIA_CLIENT_ID, OCTOPIA_CLIENT_SECRET] = source-of-truth active. Orphan keys = subset (1/4) = doublon partiel obsolete. | Q-1B-3B-1B exec `kubectl delete secret keybuzz-octopia -n keybuzz-api-dev` | reversible mais inutile | post-delete : verify keybuzz-api Deployment stable (consomme octopia-credentials ESO via outbound-worker) |
| litellm-runtime-key | INVESTIGATE OWNER (helm chart) | **DELETE_CANDIDATE_SAFE** | 0 workload ref + 0 helm chart ref + 0 source ref + litellm Deployment envFrom n'utilise PAS litellm-runtime-key + LITELLM_RUNTIME_KEY pas dans ESO litellm-secret. PH_VAULT_REBUILD_01 mentionne seulement dans backup count historique. | Q-1B-3B-1B exec `kubectl delete secret litellm-runtime-key -n keybuzz-ai` | irreversible MAIS aucun consumer detecte = safe | post-delete : verify litellm pods stable (envFrom litellm-secret + litellm-db-secret unchanged) |

**Synthese : 5/5 DELETE_CANDIDATE_SAFE** apres revision E6 ESO + helm + historique.

Note revision Q-1B-3B-0 :
- vault-emergency-token : Q-1B-3B-0 disait RETAIN BREAK-GLASS, Q-1B-3B-1A revise DELETE_CANDIDATE_SAFE (recommandation PH-VAULT-COMPATIBILITY-CHECK-01 explicite + 0 evidence runtime). Ludovic decide retain explicite si veut break-glass officiel.
- keybuzz-api-postgres-static : Q-1B-3B-0 disait RETAIN BACKUP/ESO-FALLBACK, Q-1B-3B-1A revise DELETE_CANDIDATE_SAFE (ESO active OK, pattern resilience non documente par evidence). Ludovic decide retain explicite si veut backup pattern formel.

## 11. Future Q-1B-3B-1B execution design

| Secret | Proposed execution command | GO wording required | Validation | Stop condition |
|---|---|---|---|---|
| vault-emergency-token | `kubectl -n keybuzz-api-dev delete secret vault-emergency-token` | "GO DELETE vault-emergency-token keybuzz-api-dev" explicite Ludovic | post-delete: `kubectl get secret vault-emergency-token -n keybuzz-api-dev` returns NotFound + vault-token-renew CronJob next run OK + backend stability check | STOP si Ludovic veut RETAIN BREAK-GLASS (alors execute `kubectl label secret vault-emergency-token -n keybuzz-api-dev keybuzz.io/purpose=break-glass-do-not-delete --overwrite` au lieu de delete - mais ce serait kubectl label = mutation, hors scope Q-1B-3B-1A, requires Mode B SAFE separe) |
| keybuzz-api-postgres-static | `kubectl -n keybuzz-api-dev delete secret keybuzz-api-postgres-static` | "GO DELETE keybuzz-api-postgres-static keybuzz-api-dev" explicite | post-delete: keybuzz-api-postgres ESO toujours Ready + keybuzz-api Deployment stable | STOP si Ludovic veut RETAIN BACKUP (kubectl label keybuzz.io/purpose=eso-fallback-backup) |
| keybuzz-api-auth | `kubectl -n keybuzz-api-dev delete secret keybuzz-api-auth` | "GO DELETE keybuzz-api-auth keybuzz-api-dev" explicite | post-delete: ESO keybuzz-api-jwt Ready + keybuzz-api Deployment stable | aucun (consensus DELETE) |
| keybuzz-octopia | `kubectl -n keybuzz-api-dev delete secret keybuzz-octopia` | "GO DELETE keybuzz-octopia keybuzz-api-dev" explicite | post-delete: ESO octopia-credentials Ready + outbound-worker stable | aucun (consensus DELETE) |
| litellm-runtime-key | `kubectl -n keybuzz-ai delete secret litellm-runtime-key` | "GO DELETE litellm-runtime-key keybuzz-ai" explicite | post-delete: litellm Deployment 2 pods stable + envFrom unchanged | aucun (consensus DELETE) |

Pattern execution recommande Q-1B-3B-1B :

1. **STOP Gate 1** : Ludovic confirme decision per secret (5 GO individuels OR groupe par "GO DELETE 5 orphans (cleanup safe consensus)").
2. **Capture BEFORE** : metadata-only snapshot pour audit trail (sans valeurs).
3. **Execute** : kubectl delete par secret avec namespace/name EXACT (zero wildcard, zero bulk).
4. **Verify post-delete** : `kubectl get secret <name> -n <ns>` returns NotFound + workloads stables.
5. **STOP Gate 2** : Validation runtime apps stables 5min + Ludovic UX si applicable.
6. **Rapport docs-only** : commit/push.

Pas de Mode B SAFE Vault rotator necessaire (kubectl delete = pas Vault mutation). Mais pattern STOP gates Ludovic per secret reste mandatory.

Si Ludovic prefere labeling avant suppression (e.g., grace period 7d), phase intermediaire **Q-1B-3B-1B-label** :
- `kubectl label secret <name> -n <ns> keybuzz.io/cleanup-pending=2026-05-17 --overwrite`
- Attente 7d observation runtime
- Puis Q-1B-3B-1C-delete

Cette option labeling = mutation autorisee uniquement avec GO Ludovic explicite (kubectl label exclu Q-1B-3B-1A interdits mais accepte Q-1B-3B-1B/1C avec GO).

## 12. AI feature parity / anti-regression

| Feature | Dependencies | Orphan impact if deleted future | Validation future | Verdict |
|---|---|---|---|---|
| LiteLLM gateway | litellm-secret (ESO) + litellm-db-secret (manual doublon) | litellm-runtime-key delete : 0 impact (litellm Deployment envFrom = [litellm-secret, litellm-db-secret] unchanged) | post-delete pods Running 1/1 + logs litellm no error 5min | OK safe to delete |
| OpenAI / Anthropic via LiteLLM | OPENAI_API_KEY + ANTHROPIC_API_KEY dans litellm-secret (ESO) | 0 impact (orphan key unrelated) | aucun | OK |
| Studio API LLM | keybuzz-studio-api-llm (separate from keybuzz-ai) | 0 impact (orphan keybuzz-ai unrelated to keybuzz-studio-api) | aucun | OK |
| API AI assist / Inbox / Autopilot | keybuzz-api consume keybuzz-litellm + ESO + LiteLLM gateway | 0 impact (orphan unrelated) | aucun | OK |
| Backend Amazon Fees (KEYBUZZ_INTERNAL_TOKEN) | keybuzz-backend-secrets ESO (rotated Q-1B-2B) | keybuzz-api-auth + keybuzz-api-postgres-static orphans DELETE : 0 impact (different secrets) | aucun | OK |
| Backend Octopia | octopia-credentials ESO (active source-of-truth) | keybuzz-octopia orphan DELETE : 0 impact (workloads consume ESO octopia-credentials, not orphan) | aucun | OK |
| Vault auto-rotation (vault-token-renew CronJob) | vault-admin-token + vault-app-token + vault-root-token (auto-managed) | vault-emergency-token orphan DELETE : 0 impact CronJob (CronJob ne reference pas vault-emergency-token) | post-delete CronJob next run vault-token-renew OK | OK safe |

5/5 features unaffected si tous 5 orphans supprimes.

## 13. No fake metrics / no fake events

Verifications conformite Q-1B-3B-1A :

| Interdit | Action | Verdict |
|---|---|---|
| 0 Stripe call | aucun | OK |
| 0 SES email | aucun | OK |
| 0 Slack webhook | aucun | OK |
| 0 Ads provider call | aucun | OK |
| 0 marketplace API call | aucun | OK |
| 0 17track API call | aucun | OK |
| 0 LLM provider call (OpenAI/Anthropic/Gemini/LiteLLM) | aucun | OK |
| 0 fake business event | aucun | OK |
| 0 mutationnel | aucun | OK |
| 0 secret value displayed | aucun | OK |
| 0 base64 decode | aucun | OK |

## 14. Decisions Ludovic required (avant Q-1B-3B-1B)

Pour debloquer **Q-1B-3B-1B EXEC** :

### Decisions per secret

1. **vault-emergency-token** : DELETE direct OU RETAIN BREAK-GLASS avec label ?
   - PH-VAULT-COMPATIBILITY-CHECK-01 recommande DELETE.
   - Si retain : add label keybuzz.io/purpose=break-glass-do-not-delete via kubectl label (mutation, Q-1B-3B-1B-label phase).

2. **keybuzz-api-postgres-static** : DELETE direct OU RETAIN ESO-FALLBACK avec label ?
   - ESO keybuzz-api-postgres rv=31857810 source-of-truth active confirmed.
   - Si retain : add label keybuzz.io/purpose=eso-fallback-backup.

3. **keybuzz-api-auth** : DELETE confirme (doublon strict ESO keybuzz-api-jwt, 0 ambiguity) ?

4. **keybuzz-octopia** : DELETE confirme (doublon partiel ESO octopia-credentials, 0 ambiguity) ?

5. **litellm-runtime-key** : DELETE confirme (orphan historique, 0 helm chart ref, 0 envFrom, ESO sans cette key) ?

### Decisions process

6. Sequence d'execution :
   - A. Tous en un seul Q-1B-3B-1B EXEC (5 deletes + verify atomique) ?
   - B. Sequence individuelle 5 phases Q-1B-3B-1B-1 a Q-1B-3B-1B-5 (1 GO + 1 verify par secret) ?

7. **Grace period labeling** : avant DELETE, phase Q-1B-3B-1B-label avec `kubectl label keybuzz.io/cleanup-pending=2026-05-17` + observation 7d puis Q-1B-3B-1C-delete ?

8. **Capture BEFORE backup** :
   - Recommande : metadata-only audit trail (namespace + name + keys + rv + created) - PAS de values.
   - Pas de value backup (irrecuperable apres delete pour vault-emergency-token + keybuzz-api-postgres-static qui ne sont pas doublon ESO).
   - Pour 3 doublons (api-auth, octopia, litellm-runtime-key) : ESO regenerera Secret K8s si jamais ESO Ready cesse de pointer.

### Decisions Mode

9. **Mode execution Q-1B-3B-1B** :
   - A. CE direct via kubectl delete avec GO par secret (pas de Mode B SAFE necessaire car pas Vault mutation).
   - B. Ludovic execute Mode A direct (kubectl delete depuis bastion par Ludovic).
   - C. Mode B SAFE avec rotator dedie pour kubectl delete (over-engineering ; pas necessaire).

## 15. Compliance

| Interdit Q-1B-3B-1A | Evidence | Verdict |
|---|---|---|
| Aucune suppression Secret | seul lecture metadata + jq projection | OK |
| Aucun patch/annotate/label | aucune commande kubectl mutation | OK |
| Aucune lecture valeur Secret | jq projection sans .data | OK |
| Aucun base64 -d | aucun decode | OK |
| Aucun vault kv mutation | aucune commande Vault | OK |
| Aucun provider call | aucun curl/API call | OK |
| Aucun build/deploy/restart | aucune commande mutationnelle | OK |
| Aucun fake metric/event | aucun event business | OK |
| 5 Secrets cibles seulement | strict liste preservee, 0 autre secret touche | OK |
| Bastion install-v3 only | confirme E0 | OK |
| /opt/keybuzz/credentials/ non touche | aucun acces | OK |
| /opt/keybuzz/secrets/ non touche | aucun acces | OK |
| Read-only strict | seul rapport docs-only ecrit local | OK |
| ASCII strict rapport | a verifier post-Write | a verifier |
| STOP avant commit/push | OK E12 STOP | OK |

## 16. Brouillon Linear KEY-323

```
AS.17.1Q-1B-3B-1A orphans cleanup DRY-RUN read-only COMPLETE

Commit rapport Q-1B-3B-0 : 52ddad9 (provider/manual decisions dry-run)
Commit rapport Q-1B-3B-1A : <CE remplira apres push>
Verdict : GO Q-1B-3B-1A ORPHANS DRY-RUN READY.

Resume technique :
- 5/5 Secrets cibles existent + metadata identiques Q-1B-3A (0 labels + 0 annotations + 0 ownerReferences).
- 5/5 CONFIRMED 0 workload reference (deploy/sts/ds/cronjob/job specs + pods running specs 15 namespaces).
- 5/5 CONFIRMED 0 source code reference (6 repos applicatifs).
- 5/5 references trouvees uniquement docs/rapports historiques keybuzz-infra/docs (informational, pas GitOps actif).
- 5/5 Helm charts /opt/keybuzz/keybuzz-infra/helm 0 reference (3 values files chatwoot/keybuzz/n8n).
- ESO alternatives Ready=True verifiees 4/5 doublons :
  - keybuzz-api-auth = doublon STRICT ESO keybuzz-api-jwt (COOKIE_SECRET+JWT_SECRET identiques)
  - keybuzz-octopia = doublon PARTIEL ESO octopia-credentials (OCTOPIA_CLIENT_SECRET subset)
  - keybuzz-api-postgres-static = doublon STRICT ESO keybuzz-api-postgres (5 keys Postgres identiques)
  - litellm-runtime-key = ORPHAN HISTORIQUE LiteLLM (LITELLM_RUNTIME_KEY pas dans ESO litellm-secret, 0 helm chart ref, 0 envFrom)
  - vault-emergency-token = ORPHAN HISTORIQUE break-glass (PH-VAULT-COMPATIBILITY-CHECK-01 recommande DELETE explicitement)

Classification finale : 5/5 DELETE_CANDIDATE_SAFE.

Revision Q-1B-3B-0 :
- vault-emergency-token : RETAIN BREAK-GLASS reconsidere -> DELETE_CANDIDATE_SAFE (PH-VAULT-COMPATIBILITY-CHECK-01 evidence + 0 runtime evidence).
- keybuzz-api-postgres-static : RETAIN BACKUP reconsidere -> DELETE_CANDIDATE_SAFE (ESO active source-of-truth confirmee).

Decisions Ludovic requises :
1. vault-emergency-token : DELETE OR RETAIN BREAK-GLASS avec label ?
2. keybuzz-api-postgres-static : DELETE OR RETAIN ESO-FALLBACK avec label ?
3. keybuzz-api-auth : DELETE confirme ?
4. keybuzz-octopia : DELETE confirme ?
5. litellm-runtime-key : DELETE confirme ?
6. Sequence : 5 deletes atomique OU 5 phases individuelles ?
7. Grace period 7d labeling avant DELETE ?
8. Mode execution Q-1B-3B-1B : CE direct kubectl delete OR Ludovic direct OR Mode B SAFE ?

AI feature parity : 5/5 features non-impactees (LiteLLM gateway + Studio + OpenAI/Anthropic + API + Backend Amazon Fees + Octopia + Vault auto-rotation).

Compliance : 0 secret value affiche, 0 mutation, 0 base64 decode, 0 provider call, 0 fake event.

Gaps :
- PH-VAULT-COMPATIBILITY-CHECK-01 historique evidence pertinente pour vault-emergency-token.
- PH16-API-CONNECTION-RESTORE-01 historique evidence pertinente pour keybuzz-api-postgres-static creation.
- PH_VAULT_REBUILD_01 historique evidence pertinente pour litellm-runtime-key backup count.

NO GO Q-1B-3B-1B EXEC + Q-1B-3B + Q-1B-3C + Q-1B-3D + Q-1B-3E + Q-1B-4/5/6/7 + PROD promotion AS.17.0/AS.17.0.1 maintenus.

Pas de changement status KEY-323 ou KEY-322 sans GO supplementaire.
```

STOP final : rapport pret, en attente GO Ludovic commit/push E12.

Aucun enchainement sur Q-1B-3B-1B EXEC.
Aucun enchainement sur Q-1B-3B/3C/3D/3E.
Aucun enchainement sur Q-1B-4/5/6/7.
Aucun enchainement sur PROD promotion AS.17.0/AS.17.0.1.
