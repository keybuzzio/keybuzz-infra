# PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5A
> Environnement : DEV + PROD (read-only)

## VERDICT

GO PARTIEL DESIGN REQUIRED Q-1B-5A LLM DEDUP DRY-RUN COMPLETE BUT DECISION NEEDED

Inventaire LLM/LiteLLM/Studio API complete cluster-wide : 8 K8s Secrets pattern LLM, 2 ExternalSecrets pattern LLM, 5 paths Vault deduits (sans aucune commande vault), 6 workloads consumers (4 Deployments distincts), 6 pods runtime references, 9 fichiers source code (3 repos sur 6), 59 lignes manifests GitOps actifs.

Findings cles :
1. **ALERTE CRITIQUE** : `LITELLM_MASTER_KEY` LITERAL commit en clair dans `keybuzz-infra/k8s/litellm/secret.yaml` ligne 8, tracked en HEAD et dans Git history (commit f437aff "feat: PH11-05D.0 deploy LiteLLM router"). Risque exposition dans GitHub keybuzzio/keybuzz-infra. La valeur est neutralisable par rotation Vault (Q-1B-5B) qui rend l'ancienne valeur obsolete sans necessiter force-push history.
2. **Conflit GitOps resolu en faveur d'ESO** : le manifest `secret.yaml` declare le K8s Secret `litellm-secret` ; ES `litellm-secrets` (target.name=litellm-secret, creationPolicy=Owner) en prend la propriete. Runtime owner = `ExternalSecret/litellm-secrets`. Le manifest static est FOSSILE Git non-applique mais reste un leak.
3. **Doublon strict api-dev** : `keybuzz-litellm` (manual, ACTIF runtime via pod keybuzz-api-587774dbb6-rzzmq) + `keybuzz-litellm-secrets` (ESO target name, 0 workload consume) = drift potentiel. Le pod consomme la version manuelle, l'ESO syncronise une cle qui n'est PAS lue par les pods.
4. **Asymetrie PROD majeure** : `keybuzz-api-prod` a UNIQUEMENT `keybuzz-litellm` manual, ZERO ES correspondante. Toute rotation Vault path `secret/keybuzz/litellm/master_key` mettra a jour les secrets ESO en DEV (orphan) et en keybuzz-ai (litellm-secret) mais PAS le manual api-prod qui restera fige.
5. **Studio API 100% manuel** : `keybuzz-studio-api-llm` cree manuellement en DEV + PROD, AUCUN ES, contient 9 keys distinctes (ANTHROPIC_API_KEY, GEMINI_API_KEY, LLM_API_KEY, LLM_MAX_TOKENS, LLM_MODEL, LLM_PROVIDER, LLM_TEMPERATURE, LLM_TIMEOUT_MS, PIPELINE_MODE). Non source-of-truth Vault.
6. **0 orphan K8s Secret strict** au sens cleanup safe-to-delete : keybuzz-litellm-secrets est target d'un ES (ferme la boucle ESO sync) mais ORPHAN consumer-side (cas particulier dedup, pas cleanup).
7. **Source code consumer LITELLM_MASTER_KEY** = `/opt/keybuzz/keybuzz-api/src/app.ts` (PROD path) + backup `src/app.ts.bak.20260316113610` (dette, a purger).
8. **LiteLLM pods stables** : 2 pods Running, restartCount=0, ages 41d + 2d (depuis Q-1B-3B-1B), /health/readiness=200, /health/liveliness=200 (sans Auth header, aucune cle consommee).

Decisions Ludovic requises avant Q-1B-5B EXEC :
- D1 : Strategie LITELLM_MASTER_KEY exposition Git (rotation invalidation seule OU rotation + git history rewrite + force-push).
- D2 : Migration api-dev (drop manual keybuzz-litellm, basculer Deployment env-var sur Secret ESO) AVANT rotation.
- D3 : Creation ES api-prod (`keybuzz-litellm-secrets` cote api-prod pointant meme Vault path) AVANT rotation.
- D4 : Migration keybuzz-studio-api vers ESO (creer Vault paths `secret/keybuzz/studio-api/llm/*`) - hors urgence rotation actuelle, candidat Q-1B-5C.
- D5 : Strategie cle `keybuzz-studio-api-llm/ANTHROPIC_API_KEY` (potentiellement valeur differente du Vault `secret/keybuzz/ai/anthropic_api_key`).

Aucune mutation runtime. Aucune lecture de valeur secret (.data jamais affichee, base64 jamais decode). Aucun provider call OpenAI/Anthropic/Gemini/LiteLLM. Aucun appel proxy LiteLLM /chat/completions. Aucun GitOps push. AUCUN vault kv get/list/put/patch/delete. PROD intouchee.

## Scope / hors scope

### Scope strict applique

Lecture cluster-wide :
- `kubectl get secret -A -o json | jq` projete metadata-only (JAMAIS .data values)
- `kubectl get externalsecret -A -o json` 
- `kubectl get deploy/sts/ds/cronjob/job -A -o json` (envFrom + env.valueFrom)
- `kubectl get pods -A -o json` Running+Pending uniquement
- `kubectl get clustersecretstore -o json`
- LiteLLM `/health/readiness` + `/health/liveliness` via pod ephemere curl SANS Authorization header
- LiteLLM pod conditions + container statuses (sans logs)
- grep dans manifests GitOps actifs (hors backup)
- grep dans 6 repos source code

### Hors scope respecte

- AUCUN vault command (interdiction stricte, paths deduits via ES spec uniquement)
- AUCUN provider call externe (api.openai.com, api.anthropic.com, generativelanguage.googleapis.com)
- AUCUN proxy LiteLLM /chat/completions ou /embeddings
- AUCUN log LiteLLM contenant key/token/secret/auth pattern (pod status + /health uniquement)
- AUCUNE lecture .data, AUCUN base64 -d, AUCUN -o jsonpath sur data
- AUCUN kubectl create/patch/edit/apply/delete/annotate/label/rollout
- AUCUN git push (rapport en attente GO explicite E18)
- PROD intouchee
- Q-1B-5B EXEC rotation : NO GO maintenu
- Q-1B-5B-MIGRATE-PROD-ESO : NO GO maintenu (prerequis cette phase)
- AS.17.0 / AS.17.0.1 PROD promotion : NO GO maintenue

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01.md | commit 101da65 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-1-KEY-323-GHCR-NAMING-HARMONIZATION-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1B-KEY-323-ORPHANS-CLEANUP-EXEC-01.md | present | OK (litellm-runtime-key supprime, verifie absent) |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1A-KEY-323-ORPHANS-CLEANUP-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-0-KEY-323-PROVIDER-MANUAL-DECISIONS-DRYRUN-01.md | present | OK (asymetrie LLM PROD documentee) |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3A-KEY-323-PROVIDER-MANUAL-SECRETS-INVENTORY-READONLY-01.md | present | OK |
| keybuzz-infra HEAD | 101da655ce2274d22df7939b4e427a29530a0ec5 | OK |

## Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host | install-v3 | install-v3 | OK |
| Bastion IPv4 | 46.62.171.61 | 46.62.171.61 | OK |
| Banned IP 51.159.99.247 | absent | absent | OK |
| keybuzz-infra branch | main | main | OK |
| keybuzz-infra HEAD descendant | 101da65 | 101da65 (HEAD exact) | OK |
| keybuzz-infra status | clean | clean | OK |
| keybuzz-api branch | ph147.4/source-of-truth | ph147.4/source-of-truth (dirty 223 lignes, normal developpement actif) | OK lecture seulement |
| keybuzz-backend branch | main | main (dirty 1 ligne, OK lecture seulement) | OK |
| keybuzz-client branch | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay (HEAD f61763a, clean) | OK |
| keybuzz-admin-v2 branch | main | main (clean) | OK |
| keybuzz-website branch | main | main (clean) | OK |
| keybuzz-studio-api .git | acceptable (snapshot) | .git absent (snapshot bastion) | OK lecture seulement, flag origine non-tracee |
| Temp files Q-1B-5A | absent | absent (au demarrage) | OK |
| Rapports dependances | 6 PH presents | 6 OK | OK |

## Audit signaux

### E1 Inventaire K8s Secrets pattern LLM (8 secrets, metadata-only)

Snapshot dans `/tmp/keybuzz-q1b5a-inventory-secrets.jsonl` mode 600, safety check 0 base64-payload pattern.

| ns | name | type | keys | key_names | source_type |
|---|---|---|---|---|---|
| keybuzz-ai | litellm-db-secret | Opaque | 3 | DATABASE_URL,LITELLM_DATABASE_URL,USE_PRISMA_MIGRATE | manual ou ESO ? a verifier |
| keybuzz-ai | litellm-secret | Opaque | 6 | ANTHROPIC_API_KEY,DATABASE_URL,LITELLM_DATABASE_URL,LITELLM_MASTER_KEY,OPENAI_API_KEY,USE_PRISMA_MIGRATE | ESO Owner (target ES litellm-secrets) |
| keybuzz-ai | litellm-tls | kubernetes.io/tls | 2 | tls.crt,tls.key | cert-manager (hors scope LLM dedup) |
| keybuzz-api-dev | keybuzz-litellm | Opaque | 1 | LITELLM_MASTER_KEY | manual ACTIF runtime |
| keybuzz-api-dev | keybuzz-litellm-secrets | Opaque | 1 | LITELLM_MASTER_KEY | ESO target (orphan consumer-side) |
| keybuzz-api-prod | keybuzz-litellm | Opaque | 1 | LITELLM_MASTER_KEY | manual SEUL (asymetrie PROD) |
| keybuzz-studio-api-dev | keybuzz-studio-api-llm | Opaque | 9 | ANTHROPIC_API_KEY,GEMINI_API_KEY,LLM_API_KEY,LLM_MAX_TOKENS,LLM_MODEL,LLM_PROVIDER,LLM_TEMPERATURE,LLM_TIMEOUT_MS,PIPELINE_MODE | manual (0 ES) |
| keybuzz-studio-api-prod | keybuzz-studio-api-llm | Opaque | 9 | (idem DEV) | manual (0 ES) |

Note : litellm-runtime-key supprime en Q-1B-3B-1B, confirme absent. litellm-tls hors scope (cert TLS LiteLLM ingress, gere par cert-manager separement).

### E2 Inventaire ExternalSecrets pattern LLM (2 ES)

| ns | name | store | kind | target | refresh | Ready | reason | data_remote_keys |
|---|---|---|---|---|---|---|---|---|
| keybuzz-ai | litellm-secrets | vault-backend | ClusterSecretStore | litellm-secret (creationPolicy=Owner) | 1h | True | SecretSynced | secret/keybuzz/ai/anthropic_api_key, secret/keybuzz/ai/openai_api_key, secret/keybuzz/litellm/database_url, secret/keybuzz/litellm/master_key, secret/keybuzz/litellm/use_prisma_migrate |
| keybuzz-api-dev | keybuzz-litellm-secrets | vault-backend | ClusterSecretStore | keybuzz-litellm-secrets (creationPolicy=Owner) | 1h | True | SecretSynced | secret/keybuzz/litellm/master_key |

### E3 Vault KV paths deduits via ES spec UNIQUEMENT (aucun vault command)

| store | remote_key | property | used_by_ES_count | classification |
|---|---|---|---|---|
| vault-backend | secret/keybuzz/litellm/master_key | value | 2 (litellm-secrets, keybuzz-litellm-secrets) | CANONICAL |
| vault-backend | secret/keybuzz/ai/anthropic_api_key | value | 1 (litellm-secrets) | CANONICAL |
| vault-backend | secret/keybuzz/ai/openai_api_key | value | 1 (litellm-secrets) | CANONICAL |
| vault-backend | secret/keybuzz/litellm/database_url | value | 1 (litellm-secrets) | CANONICAL |
| vault-backend | secret/keybuzz/litellm/use_prisma_migrate | value | 1 (litellm-secrets) | CANONICAL non-secret-value (boolean) |

ClusterSecretStores observees Ready=True : `vault-backend` (provider vault), `vault-backend-database` (provider vault).

### E4 envFrom/env refs Deployments (6 refs)

| ns | kind | workload | container | ref_kind | secret_name | key | env_var |
|---|---|---|---|---|---|---|---|
| keybuzz-ai | deploy | litellm | litellm | envFrom | litellm-db-secret | - | - |
| keybuzz-ai | deploy | litellm | litellm | envFrom | litellm-secret | - | - |
| keybuzz-api-dev | deploy | keybuzz-api | keybuzz-api | env | keybuzz-litellm | LITELLM_MASTER_KEY | LITELLM_MASTER_KEY |
| keybuzz-api-prod | deploy | keybuzz-api | keybuzz-api | env | keybuzz-litellm | LITELLM_MASTER_KEY | LITELLM_MASTER_KEY |
| keybuzz-studio-api-dev | deploy | keybuzz-studio-api | keybuzz-studio-api | envFrom | keybuzz-studio-api-llm | - | - |
| keybuzz-studio-api-prod | deploy | keybuzz-studio-api | keybuzz-studio-api | envFrom | keybuzz-studio-api-llm | - | - |

### E5 Pods Running+Pending refs (8 refs)

Coherence E4 -> E5 confirmee (chaque Deployment a 1 Pod actif minimum). Aucun drift Pod vs Deployment detecte.

| ns | pod | container | ref_kind | secret_name | env_var |
|---|---|---|---|---|---|
| keybuzz-ai | litellm-55bcfd7769-sfw8l | litellm | envFrom | litellm-db-secret | - |
| keybuzz-ai | litellm-55bcfd7769-sfw8l | litellm | envFrom | litellm-secret | - |
| keybuzz-ai | litellm-55bcfd7769-xlhm7 | litellm | envFrom | litellm-db-secret | - |
| keybuzz-ai | litellm-55bcfd7769-xlhm7 | litellm | envFrom | litellm-secret | - |
| keybuzz-api-dev | keybuzz-api-587774dbb6-rzzmq | keybuzz-api | env | keybuzz-litellm | LITELLM_MASTER_KEY |
| keybuzz-api-prod | keybuzz-api-7685645f49-jx6m7 | keybuzz-api | env | keybuzz-litellm | LITELLM_MASTER_KEY |
| keybuzz-studio-api-dev | keybuzz-studio-api-89b545c8f-rrhrm | keybuzz-studio-api | envFrom | keybuzz-studio-api-llm | - |
| keybuzz-studio-api-prod | keybuzz-studio-api-7c6d58877b-zsfqz | keybuzz-studio-api | envFrom | keybuzz-studio-api-llm | - |

### E6 Manifests GitOps grep LLM (59 lignes active, hors backup)

Top files : `k8s/litellm/configmap.yaml` (20), `k8s/litellm/external-secret.yaml` (12), `k8s/litellm/deployment.yaml` (8), `k8s/keybuzz-api-prod/deployment.yaml` (4), `k8s/keybuzz-api-dev/externalsecret-litellm.yaml` (4), `k8s/keybuzz-api-dev/deployment.yaml` (4), `k8s/litellm/ingress.yaml` (3), `k8s/litellm/service.yaml` (2), `k8s/litellm/secret.yaml` (2).

**ALERTE CRITIQUE LEAK** : `k8s/litellm/secret.yaml` ligne 8 contient `LITELLM_MASTER_KEY: "<valeur hex 64 chars REDACTED dans ce rapport>"`. File tracked in HEAD, 1 commit Git touche ce fichier (`f437aff feat: PH11-05D.0 deploy LiteLLM router (llm.keybuzz.io)`). Remote = `https://github.com/keybuzzio/keybuzz-infra.git`.

Note : LiteLLM configmap.yaml utilise `os.environ/OPENAI_API_KEY` et `os.environ/ANTHROPIC_API_KEY` qui sont fournis via envFrom litellm-secret (lui-meme ESO depuis Vault) -> coherent.

### E7 Source code refs (3 repos sur 6 ont des matches)

| repo | files_with_match | branche | tracked |
|---|---|---|---|
| keybuzz-api | 1 (+ 1 backup) | ph147.4/source-of-truth | OUI (dirty 223 lignes dev actif) |
| keybuzz-backend | 3 | main | OUI (dirty 1 ligne) |
| keybuzz-client | 0 | ph148/onboarding-activation-replay | OUI (clean) |
| keybuzz-admin-v2 | 0 | main | OUI (clean) |
| keybuzz-website | 0 | main | OUI (clean) |
| keybuzz-studio-api | 4 | snapshot | NON .git absent |

Pattern occurrences (active source, hors node_modules) :
- LITELLM_MASTER_KEY : 2
- LITELLM_BASE_URL : 1
- ANTHROPIC_API_KEY : 4
- GEMINI_API_KEY : 6
- LLM_API_KEY : 8
- LLM_MASTER_KEY : 2
- OPENAI_API_KEY : 0 (consomme uniquement par LiteLLM proxy via configmap os.environ)
- LITELLM_API_KEY : 0
- LITELLM_PROXY_URL : 0
- LITELLM_API_BASE : 0
- GOOGLE_AI_KEY : 0

LITELLM_MASTER_KEY consommee dans : `/opt/keybuzz/keybuzz-api/src/app.ts` (PROD path) + `/opt/keybuzz/keybuzz-api/src/app.ts.bak.20260316113610` (backup dette).

### E8 LiteLLM pods consommation (sans logs sensible)

| pod | phase | restarts | ready | image | envFrom_secrets | env_secrets | volume_secrets |
|---|---|---|---|---|---|---|---|
| litellm-55bcfd7769-sfw8l | Running | 0 | true | ghcr.io/berriai/litellm:main-v1.81.14-stable | litellm-db-secret, litellm-secret | (vide) | (vide) |
| litellm-55bcfd7769-xlhm7 | Running | 0 | true | ghcr.io/berriai/litellm:main-v1.81.14-stable | litellm-db-secret, litellm-secret | (vide) | (vide) |

Conditions both pods : PodReadyToStartContainers=True, Initialized=True, Ready=True, ContainersReady=True, PodScheduled=True. ContainerStatuses : ready=true, restarts=0, state=running.

LiteLLM Service `/health/readiness` = HTTP 200 (52ms), `/health/liveliness` = HTTP 200 (15ms) - sans Auth header, aucune cle LLM consommee.

## Source-of-truth identification (Tableau 10)

| env_var | canonical_vault_path | consumer_count | k8s_secrets_reflecting | classification |
|---|---|---|---|---|
| LITELLM_MASTER_KEY | secret/keybuzz/litellm/master_key | 3 deployments (litellm keybuzz-ai, keybuzz-api dev+prod) | litellm-secret (ESO), keybuzz-litellm (manual dev+prod), keybuzz-litellm-secrets (ESO dev, orphan consumer) | CANONICAL_BUT_DRIFT_RISK (4 K8s Secrets pour 1 path Vault) |
| OPENAI_API_KEY | secret/keybuzz/ai/openai_api_key | 1 (litellm pods via configmap os.environ) | litellm-secret (ESO) | UNIQUE_CANONICAL |
| ANTHROPIC_API_KEY | secret/keybuzz/ai/anthropic_api_key | 2 (litellm pods + keybuzz-studio-api pods) | litellm-secret (ESO, keybuzz-ai), keybuzz-studio-api-llm (manual, dev+prod) | DUPLICATE_SUSPECTED (meme env var, valeurs potentiellement differentes entre keybuzz-ai et studio-api) |
| GEMINI_API_KEY | aucun path Vault deduit (pas d'ES) | 1 (keybuzz-studio-api pods) | keybuzz-studio-api-llm (manual) | MANUAL_NO_VAULT |
| GOOGLE_AI_KEY | non utilise | 0 | (aucun) | UNUSED |
| LITELLM_DATABASE_URL | secret/keybuzz/litellm/database_url | 1 (litellm pods) | litellm-secret (ESO), litellm-db-secret (separe, a investiguer) | DUAL_SOURCE_LITELLM_DB (litellm-secret contient LITELLM_DATABASE_URL ET litellm-db-secret aussi) |
| DATABASE_URL | secret/keybuzz/litellm/database_url ? (a verifier) | 1 (litellm pods) | litellm-secret + litellm-db-secret | DUAL_SOURCE_LITELLM_DB |
| USE_PRISMA_MIGRATE | secret/keybuzz/litellm/use_prisma_migrate | 1 (litellm pods) | litellm-secret + litellm-db-secret | DUAL_SOURCE (key partagee, valeur boolean non-secret-sensitive) |
| LLM_API_KEY, LLM_MODEL, LLM_PROVIDER, LLM_MAX_TOKENS, LLM_TEMPERATURE, LLM_TIMEOUT_MS, PIPELINE_MODE | aucun (pas d'ES studio-api) | 1 (keybuzz-studio-api pods) | keybuzz-studio-api-llm (manual) | MANUAL_NO_VAULT |

## Doublons stricts et partiels (Tableau 11)

| key | source_a | source_b | overlap_type | decision_proposed |
|---|---|---|---|---|
| LITELLM_MASTER_KEY | keybuzz-api-dev/keybuzz-litellm (manual) | keybuzz-api-dev/keybuzz-litellm-secrets (ESO target) | STRICT_SAME_NS | Q-1B-5B Step 2 : migrer Deployment env-var sur Secret ESO + delete manual |
| LITELLM_MASTER_KEY | keybuzz-api-prod/keybuzz-litellm (manual) | (aucun ES PROD) | ASYMETRIE_DEV_PROD | Q-1B-5B Step 1 : creer ES keybuzz-litellm-secrets api-prod AVANT rotation |
| LITELLM_MASTER_KEY | k8s/litellm/secret.yaml (manifest Git, hardcoded) | ES litellm-secrets target litellm-secret (runtime owner) | GIT_VS_RUNTIME_CONFLICT | Q-1B-5B Step 5 : delete manifest secret.yaml du repo apres rotation (rotation neutralise la valeur exposee) |
| ANTHROPIC_API_KEY | keybuzz-ai/litellm-secret (ESO -> secret/keybuzz/ai/anthropic_api_key) | keybuzz-studio-api-dev/keybuzz-studio-api-llm (manual, key ANTHROPIC_API_KEY) | DUPLICATE_CROSS_NS | Q-1B-5C : unifier source via ESO studio-api -> meme Vault path OU paths separes (decision Ludovic D5) |
| ANTHROPIC_API_KEY | keybuzz-ai/litellm-secret (ESO) | keybuzz-studio-api-prod/keybuzz-studio-api-llm (manual) | DUPLICATE_CROSS_NS_PROD | idem D5 |
| LITELLM_DATABASE_URL | keybuzz-ai/litellm-secret | keybuzz-ai/litellm-db-secret | OVERLAP_PARTIAL_SAME_NS | Q-1B-5B audit : determiner si l'un consomme l'autre, ou si duplication accidentelle. Probablement separation par concern (db connection vs LLM API), valeurs potentiellement identiques |

## Orphans LLM (Tableau 12)

| ns/name | age_days | wl_refs | pod_refs | sa_refs | manifest_refs | classification | proposed_action |
|---|---|---|---|---|---|---|---|
| keybuzz-api-dev/keybuzz-litellm-secrets | ? | 0 | 0 | 0 | 1 (ES sync target) | ORPHAN_CONSUMER_SIDE | NOT_SAFE_DELETE alone (delete ES first) ; Q-1B-5B step 2 : migrate Deployment to use this + delete manual |
| litellm-runtime-key | N/A | N/A | N/A | N/A | N/A | DELETED_Q-1B-3B-1B | verifie absent, OK |

Aucun orphan strict safe-to-delete type Q-1B-3B-1B (1-shot mini-cleanup). Tous les Secrets restants ont au moins une dependance.

## Asymetries DEV vs PROD (Tableau 13)

| env_var | DEV_source | PROD_source | drift_type | blocker_for_Q-1B-5B |
|---|---|---|---|---|
| LITELLM_MASTER_KEY (api) | keybuzz-litellm manual + keybuzz-litellm-secrets ESO orphan | keybuzz-litellm manual SEUL | DEV_HAS_ES_PROD_DOES_NOT | OUI (rotation Vault path n'atteindra pas api-prod tant qu'ES non cree) |
| LITELLM_MASTER_KEY (ai) | litellm-secret ESO (keybuzz-ai unique, pas de PROD distinct pour litellm) | (idem keybuzz-ai sert DEV+PROD) | NONE | NON |
| LLM_API_KEY, LLM_MODEL, etc (studio-api) | keybuzz-studio-api-llm manual | keybuzz-studio-api-llm manual | NONE (symetrique mais 100% manuel) | OUI faible (manuel = drift permanent, mais pas bloquant rotation LITELLM_MASTER_KEY specifique) |
| ANTHROPIC_API_KEY | ESO (litellm-secrets/keybuzz-ai) + manual (studio-api-dev) | ESO (litellm-secrets/keybuzz-ai shared) + manual (studio-api-prod) | DUAL_SOURCE_BOTH_ENVS | OUI moderee (rotation Vault impactera LiteLLM mais PAS studio-api ; risque incoherence cles) |

## Plan EXEC Q-1B-5B propose (Tableau 14, NON execute)

| step | action | dependency | gate | risk | rollback | required_GO_phrase |
|---|---|---|---|---|---|---|
| 0 | Decision Ludovic D1-D5 + ouverture sous-phases dediees | Q-1B-5A docs/ | GO Ludovic sur les 5 decisions | none | none | (decision text Ludovic) |
| 1 | Q-1B-5B-MIGRATE-PROD-ESO : creer ExternalSecret `keybuzz-litellm-secrets` cote api-prod pointant `secret/keybuzz/litellm/master_key`, attendre Ready=True | D3 GO | STOP si sync ne se fait pas | FAIBLE | kubectl delete externalsecret + Secret cree par Owner disparait | GO MIGRATE PROD ESO LITELLM Q-1B-5B-1 |
| 2 | Q-1B-5B-MIGRATE-API-DEV-TO-ES : patcher Deployment `keybuzz-api` api-dev env LITELLM_MASTER_KEY secretKeyRef.name de `keybuzz-litellm` vers `keybuzz-litellm-secrets`, rollout, validation 24h | D2 + step 1 | STOP si pod KO | MOYEN (drift potentiel valeurs differentes entre les 2 secrets) | revert Deployment + rollout | GO MIGRATE API-DEV ESO Q-1B-5B-2 |
| 3 | Q-1B-5B-MIGRATE-API-PROD-TO-ES : meme chose api-prod, GO Ludovic explicite PROD | D2 + step 2 stable 24h | STOP si pod KO | ELEVE (PROD) | revert Deployment + rollout PROD | GO MIGRATE API-PROD ESO Q-1B-5B-3 |
| 4 | Q-1B-5B-CLEANUP-MANUAL : delete keybuzz-api-dev/keybuzz-litellm + keybuzz-api-prod/keybuzz-litellm (manuels devenus orphans apres steps 2+3) | step 3 stable 24h | STOP Gate exact phrase per delete | FAIBLE | non-recuperable local | GO DELETE LLM MANUAL Q-1B-5B-4 (par ns) |
| 5 | Q-1B-5B-ROTATION : generate openssl rand -hex 32 offline + vault kv patch property-only `secret/keybuzz/litellm/master_key` via runner SCP + unset NEW_* immediat | step 4 + GO rotation | STOP si Vault patch echoue | MOYEN | vault kv rollback -version=N | GO ROTATE LITELLM MASTER KEY Q-1B-5B-5 |
| 6 | Q-1B-5B-SYNC : kubectl annotate ExternalSecret force-sync=now (litellm-secrets keybuzz-ai + keybuzz-litellm-secrets api-dev + api-prod), wait rv bump des Secrets cibles, restart pods (litellm 2 pods + keybuzz-api dev+prod) | step 5 | wait Ready + ImagePullBackOff watcher | MOYEN-ELEVE (downtime LiteLLM ~30-60s + downtime keybuzz-api LLM features) | revert Vault + restart | GO SYNC LITELLM ROTATION Q-1B-5B-6 |
| 7 | Q-1B-5B-VALIDATE-AI-PARITY : tester baseline AI messaging (envoi message tenant test, verif tonalite, latence < SLO) selon AI_MESSAGING_FEATURE_PARITY_BASELINE.md | step 6 | NO GO upstream si parite cassee | ELEVE (rollback complet) | step 5+6 reverse | NON (controle automatique) |
| 8 | Q-1B-5B-CLEANUP-MANIFEST-GIT : delete `k8s/litellm/secret.yaml` du repo, commit + push (la valeur exposee est invalidee par rotation step 5). Optionnel : git filter-repo pour purger history (engageant, requires GO explicite) | step 7 OK | none | FAIBLE (cle deja obsolete) | git revert | GO DELETE LITELLM SECRET YAML MANIFEST Q-1B-5B-8 |
| 9 | (futur Q-1B-5C) Migration keybuzz-studio-api vers ESO : creer Vault paths secret/keybuzz/studio-api/llm/* + ES + patch Deployment + delete manual | D4 GO + sequence dediee | hors urgence rotation | MOYEN | sequence inverse | (prompt CE dedie Q-1B-5C) |

**Recommandation analyste non-engageante** :

Sequence pragmatique recommandee (D1 = rotation invalidation simple, sans force-push history) :
1. Step 1 (MIGRATE-PROD-ESO) immediate, zero-risque additif (creation ES + Secret nouveau cote PROD).
2. Step 2 + 3 sequentiel DEV-puis-PROD avec 24h validation entre les deux.
3. Step 5 (rotation atomique cross-env) UNE FOIS step 4 complete (les manuels suprimes garantissent qu'il n'y a plus qu'une seule source ESO).
4. Step 7 (AI parity) bloque ouvrir l'etape 8 si echec.
5. Step 8 cleanup manifest Git (la valeur Git devient inert post-rotation, donc force-push history n'est pas strictement requis).

Decision optimiste si Ludovic accepte : durer total ~3-4 jours calendaires avec 2 GO PROD distincts (step 3 et step 6).

## No fake metrics

N/A. Phase inventaire pure. Aucun KPI dashboard touche. Aucun event GA4/CAPI/TikTok/LinkedIn declenche. Aucune metric KeyBuzz creee. Aucun appel KBAction.

## AI feature parity / anti-regression

Cette phase touche INDIRECTEMENT l'IA via inventaire des cles consommees par LiteLLM proxy (modeles gpt-4o-mini, claude-3-5-haiku, claude-sonnet-4), keybuzz-api/agent (consume LITELLM_MASTER_KEY via env-var), keybuzz-studio-api/playbooks (consume LLM_API_KEY + provider keys via envFrom).

En read-only Q-1B-5A : AUCUNE consequence runtime observable :
- LiteLLM pods : 0 restart, ready=true, /health=200, age 41d + 2d inchanges
- keybuzz-api dev+prod : pods stable
- keybuzz-studio-api dev+prod : pods stable

Plan Q-1B-5B EXEC futur impactera transitoirement la disponibilite :
- Step 6 SYNC : downtime LiteLLM ~30-60s pendant rollout des 2 pods
- Step 6 impacte aussi keybuzz-api rollout (perte des features LLM pendant ~30-60s)
- Step 7 controle obligatoire de parite IA messaging baseline AVANT validation

Si step 7 echoue, rollback complet Vault + restart obligatoire avant nouvelle tentative. NO GO maintenu Q-1B-5B EXEC tant que ces decisions ne sont pas tranchees explicitement par Ludovic.

## Cleanup temporary files

| Fichier | Mode | Statut planned |
|---|---|---|
| /tmp/keybuzz-q1b5a-inventory-secrets.jsonl | 600 | shred apres redaction rapport |
| /tmp/keybuzz-q1b5a-inventory-es.jsonl | 600 | shred apres redaction rapport |
| /tmp/keybuzz-q1b5a-refs-workloads.jsonl | 600 | shred |
| /tmp/keybuzz-q1b5a-refs-pods.jsonl | 600 | shred |
| /tmp/keybuzz-q1b5a-manifests.txt | 600 | shred |
| /tmp/keybuzz-q1b5a-source-code.txt | 600 | shred |
| /tmp/keybuzz-q1b5a-litellm-pods.jsonl | 600 | shred |
| /tmp/keybuzz-q1b5a-e1-e8-runner.sh + e4-e8-runner.sh | 755 | shred |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres | Impact |
|---|---|---|---|
| keybuzz-api-prod (1 pod Running) | non touche | non touche | 0 |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod (1 pod Running) | non touche | non touche | 0 |
| keybuzz-ai litellm (2 pods Running) | non touche | non touche | 0 |
| keybuzz-client-prod | non touche | non touche | 0 |
| keybuzz-admin-v2-prod | non touche | non touche | 0 |
| Vault KV PROD paths | non touche (0 vault command) | non touche | 0 |
| ESO ClusterSecretStores | non touche | non touche | 0 |
| GitOps Argo CD | non touche | non touche | 0 |
| Providers LLM (OpenAI, Anthropic, Gemini) | non touche (0 provider call) | non touche | 0 |
| LiteLLM proxy /chat/completions, /embeddings | non touche (0 appel) | non touche | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| Mutation cluster K8s | 0 commande create/patch/edit/apply/delete | OK |
| Mutation Vault | 0 vault kv get/list/put/patch/delete | OK (paths deduits via ES spec uniquement) |
| Provider call LLM | 0 curl/wget vers api.openai/anthropic/gemini/litellm | OK |
| Lecture valeur secret | 0 .data value, 0 base64 -d, safety check 0 regex match (eyJ/sk-/sk-ant-/AIza) sur tous les outputs | OK |
| LiteLLM /chat ou /embeddings | 0 appel ; /health/readiness + /health/liveliness sans Auth header uniquement | OK |
| Logs LiteLLM contenant key/token/secret/auth | 0 lecture logs sensibles ; pod conditions + container statuses uniquement | OK |
| Modification source code | git status repos source inchange (sauf dirty pre-existants documentes preflight) | OK |
| Commit/push sans GO | rapport en untracked apres E16, commit uniquement apres GO E18 | OK |
| Toucher PROD | 0 commande mutation namespace *-prod | OK |
| SSH heredoc multi-lignes | 0 utilisation, SCP runner pattern partout (3 runners SCP : e1-e8, e4-e8 retry, e9-e12 inline court) | OK |
| Tenant/user/email hardcode | 0 dans le rapport | OK |
| Affichage valeur LITELLM_MASTER_KEY commit Git | REDACTED dans le rapport (4 chars REDACTED uniquement) | OK |

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5A LLM SECRETS DEDUP DRY-RUN

Status: COMPLETE - DECISIONS REQUIRED
Scope: DEV + PROD read-only inventory + plan EXEC

Findings:
- 8 K8s Secrets pattern LLM + 2 ExternalSecrets + 5 paths Vault deduits
- ALERTE: LITELLM_MASTER_KEY commit en clair dans keybuzz-infra/k8s/litellm/secret.yaml ligne 8 (HEAD + commit f437aff)
- Conflit ESO/manifest resolu en faveur d'ESO (runtime owner = ExternalSecret/litellm-secrets)
- Doublon strict api-dev: keybuzz-litellm (manual ACTIF) + keybuzz-litellm-secrets (ESO orphan consumer)
- Asymetrie PROD majeure: api-prod a SEUL le manual, ZERO ES correspondante
- Studio-api 100% manuel (9 keys, 0 ES)
- LiteLLM stable (2 pods Running, /health=200, 0 restart)

Decisions requises Ludovic:
- D1: Strategie LITELLM_MASTER_KEY expose Git (rotation seule vs rotation + history rewrite)
- D2: Migration api-dev manual -> ESO
- D3: Creation ES keybuzz-litellm-secrets api-prod
- D4: Migration studio-api vers ESO (hors urgence)
- D5: Strategie ANTHROPIC_API_KEY dupliquee LiteLLM + studio-api

Plan EXEC Q-1B-5B en 9 steps documente.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01.md
NO GO maintenus: Q-1B-5B EXEC, Q-1B-5B-MIGRATE-PROD-ESO, GHCR PAT rotation, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **Q-1B-5B EXEC rotation LITELLM_MASTER_KEY** : NO GO maintenu, requires D1-D5 decisions Ludovic + sequence 9 steps.
2. **Q-1B-5B-MIGRATE-PROD-ESO** : NO GO maintenu (prerequis Q-1B-5A complete = ce rapport).
3. **Q-1B-5C (proposee)** : migration keybuzz-studio-api vers ESO (creer Vault paths + ES + patch Deployment + delete manual).
4. **Q-1B-5D (proposee)** : audit valeurs ANTHROPIC_API_KEY (verifier si LiteLLM scope et studio-api scope utilisent la meme cle source provider ou des cles distinctes, decision unification).
5. **Q-1B-3D-2B harmonisation pleine GHCR** : NO GO maintenu (decision option A/B/C).
6. **Q-1B-3D-3 (proposee)** : creation GitOps des Secrets dockerconfigjson via Helm/ESO.
7. **Q-1B-3E-inbound-webhook MIGRATION ESO PROD** : divergence DEV/PROD a resorber.
8. **Q-1B-3B PROVIDER LOW-RISK** : Stripe TEST + SES + Slack + Ads sub-batched.
9. **Q-1B-3C OAUTH LOGIN, Q-1B-6 MARKETPLACE OAUTH, Q-1B-4 INFRA DIRECT, Q-1B-7 ADS-ENCRYPTION STRATEGIC DESIGN, Q-1F-3 VALIDATION CUMULEE** restent dans la file.
10. **AS.17.0 / AS.17.0.1 PROD PROMOTION** : NO GO maintenu tant que tenantGuardPlugin INACTIF (KEY-301 AS.3) non patche.
11. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.
12. **Dette source code** : `keybuzz-api/src/app.ts.bak.20260316113610` (backup contenant LITELLM_MASTER_KEY ref, a purger).

## Phrase cible finale

Inventaire LLM/LiteLLM/Studio API complete sur 6 namespaces (8 K8s Secrets pattern LLM, 2 ExternalSecrets, 5 paths Vault deduits via ES UNIQUEMENT, 4 workloads consumers, 6 pods runtime, 9 fichiers source code), source-of-truth canonique identifie par variable d'environnement (LITELLM_MASTER_KEY = secret/keybuzz/litellm/master_key avec drift risk 4 K8s Secrets pour 1 path Vault), 6 doublons stricts ou partiels classifies, 0 orphan strict safe-to-delete mais 1 orphan consumer-side (keybuzz-litellm-secrets), 3 asymetries DEV/PROD majeures (api-prod sans ES, studio-api 100% manuel, ANTHROPIC_API_KEY dual-source), plan EXEC Q-1B-5B propose en 9 steps avec migration PROD-ESO en prerequis et test parite IA messaging bloquant - aucune mutation runtime, aucune lecture de valeur secret, 0 vault command, 0 provider call, 0 GitOps push, PROD intouchee - EXEC Q-1B-5B reste NO GO en attente GO Ludovic explicite et resolution decisions D1-D5. ALERTE CRITIQUE : LITELLM_MASTER_KEY commit en clair dans keybuzz-infra/k8s/litellm/secret.yaml ligne 8 (commit f437aff), neutralisable par rotation Q-1B-5B step 5.

STOP
