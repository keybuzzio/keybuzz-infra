# PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2-KEY-323-LLM-API-ENV-VAR-MIGRATION-DRYRUN-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5B-2
> Environnement : DEV + PROD (read-only + dry-run server, aucune mutation persistee)

## VERDICT

GO PARTIEL DESIGN REQUIRED Q-1B-5B-2 - DRIFT PROD DETECTE SUR STAKATER_VAULT_ROOT_TOKEN_SECRET

Validation dry-run server-side des patches Deployment `keybuzz-api` DEV + PROD migration env-var `LITELLM_MASTER_KEY` du Secret manuel `keybuzz-litellm` vers le Secret ESO `keybuzz-litellm-secrets` :
- DEV : patch valide, dry-run exit 0, diff montre UNIQUEMENT le changement env-var attendu (ligne 186-189), source manifest k8s/ inchange (correction 1 respectee).
- PROD : patch valide, dry-run exit 0, diff montre le changement env-var attendu (ligne 189-192) **MAIS ALERTE NOUVELLE** : drift IMPREVU sur env `STAKATER_VAULT_ROOT_TOKEN_SECRET` (ligne 221-222) - value runtime PROD != value source Git, exposee en clair dans le manifest Git PROD.

Findings cles :
1. **Patches DEV + PROD syntaxiquement et semantiquement valides** : kubectl apply --dry-run=server exit 0 pour les deux, kubectl diff (separe per correction 1) montre le changement attendu sur secretKeyRef.name uniquement.
2. **Comparaison metadata Secret manuel vs ESO** : key_names identiques (`[LITELLM_MASTER_KEY]`) dans les 2 environnements. Ages tres differents (DEV : ESO 124j > manuel 96j = ESO plus ancien que manuel, suspicion override manuel posterieur ; PROD : manuel 96j > ESO 0j = ESO cree hier en Q-1B-5B-1).
3. **Drift PROD STAKATER_VAULT_ROOT_TOKEN_SECRET DECOUVERT FORTUITEMENT** : la valeur runtime PROD `a0639b5a...` differe de la valeur source Git PROD `a2c303d9...` (2 tokens hex 40 chars distincts, valeurs masquees en sigle dans ce rapport). Le manifest expose CETTE valeur en `value:` plain text comme variable d'environnement, similaire au pattern d'exposition LITELLM_MASTER_KEY dans `k8s/litellm/secret.yaml` deja documente en Q-1B-5A. Ce drift bloque Q-1B-5B-2-EXEC-PROD tant qu'il n'est pas resolu (un kubectl apply du manifest Git ecraserait la valeur runtime avec la valeur Git plus ancienne, possiblement obsolete post-rotation Vault token).
4. **Risque drift valeur LITELLM_MASTER_KEY manual vs ESO** : INCONNU (valeurs jamais lues). Mitigable par rollback rapide en EXEC futur si auth 401 observable.
5. **Argo CD config** : DEV a 1 Application `keybuzz-api-dev` autoSync=**false** sync=Unknown health=Healthy ; PROD aucune Application. EXEC futur necessitera kubectl apply manuel pour les deux.
6. **Source manifests Git k8s/keybuzz-api-{dev,prod}/deployment.yaml** : INCHANGES (md5 stable, git status clean post-phase, correction 2 respectee : pas d'ecriture dans k8s/).

Decisions Ludovic requises avant Q-1B-5B-2-EXEC :
- D6 (NOUVELLE) : Strategie drift STAKATER_VAULT_ROOT_TOKEN_SECRET PROD - investigation prealable obligatoire (a) verifier si la valeur Git est obsolete post-rotation Q-1B-1B (alors commit le runtime dans Git AVANT apply manifest), OU (b) verifier si la valeur runtime a derive accidentellement (alors investigation root cause + alignment Git).
- D7 (NOUVELLE) : Sequence Q-1B-5B-2-EXEC apres resolution D6. Recommandation : EXEC-DEV en premier (pas de drift, safe), puis validation 24h, puis investigation D6 et resolution PROD, puis EXEC-PROD.
- D8 (NOUVELLE) : Strategie ALERTE STAKATER token expose plain-text dans Git keybuzz-infra. Pattern identique a LITELLM_MASTER_KEY Q-1B-5A. Candidat migration vers ESO + rotation, hors scope cette phase.

Aucune mutation runtime. Aucun apply effective. Aucune lecture valeur secret (.data jamais affichee). Aucun base64 decode. Aucun vault command. Aucun provider call LLM. Aucun appel proxy LiteLLM /chat /embeddings. Aucun kubectl run/exec/port-forward (verification 100% read-only via get/diff/apply --dry-run). PROD intouchee. Patches generes dans /tmp uniquement (mode 600), shred apres rapport.

## Scope / hors scope

### Scope strict applique
- Lecture cluster : Deployments + Secrets + ES + Pods DEV + PROD + LiteLLM baseline
- Generation patches dans `/tmp/keybuzz-q1b5b2-deployment-{dev,prod}-patched.yaml` (mode 600)
- `kubectl apply --dry-run=server` (validation server-side, non-persistante)
- `kubectl diff` (lecture comparative, separe de apply selon correction 1)
- Comparaison metadata manual vs ESO sans lecture valeur (correction 3 Q-1B-5A : sans vault command)

### Hors scope respecte (corrections 1+2+3)
- Correction 1 : `kubectl apply --dry-run=server` et `kubectl diff` executes en commandes SEPAREES, jamais combinees en une seule expression
- Correction 2 : pas d'attente de "generation bump" dans le diff dry-run (le bump est observe en runtime mais documente comme effet futur de l'EXEC, pas comme verification du dry-run)
- Correction 3 : rollback nominal = git revert / manifest inverse + commit/push + apply ; kubectl rollout undo = emergency uniquement (documente en E9 plan Q-1B-5B-2-EXEC step 4/5)
- AUCUNE ecriture dans `k8s/keybuzz-api-{dev,prod}/` (patches dans /tmp uniquement)
- AUCUN git add du Deployment patche
- AUCUNE mutation Vault (paths deduits via ES spec uniquement, comme Q-1B-5A/Q-1B-5B-0)
- AUCUN provider call LLM
- AUCUN appel proxy LiteLLM
- AUCUN kubectl run/exec/port-forward
- AUCUNE lecture valeur secret
- PROD autres surfaces : intouchees
- AS.17.0 / AS.17.0.1 : NO GO maintenue

## Sources relues

| Source | Sha256 / commit | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-1-KEY-323-LLM-PROD-ESO-MIGRATION-EXEC-01.md | c46d50af023ae10020b938f3d56144b2ff268d5eee67dae30c12151f3be76cbb | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-0-KEY-323-LLM-PROD-ESO-MIGRATION-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01.md | present (D2 migration approuvee) | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01.md | present | OK |
| k8s/keybuzz-api-dev/deployment.yaml | source canonique runtime DEV | OK lecture |
| k8s/keybuzz-api-prod/deployment.yaml | source canonique runtime PROD | OK lecture (drift detecte) |
| keybuzz-infra HEAD | 5945f8774361fc86fabe154dc54e500a9fa4b86f | OK |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host | install-v3 | install-v3 | OK |
| Bastion IPv4 | 46.62.171.61 | 46.62.171.61 | OK |
| keybuzz-infra branch / HEAD / status | main / desc 5945f87 / clean | match | OK |
| Rapport Q-1B-5B-1 sha256 | c46d50af | match | OK |
| /tmp residuels Q-1B-5B-2 | absent | absent | OK |
| CSS vault-backend Ready | True | True/Valid | OK |
| ES DEV keybuzz-litellm-secrets Ready/refresh | True/SecretSynced/< 1h | True/SecretSynced/refresh 10:26:42Z (35min ago) | OK |
| ES PROD keybuzz-litellm-secrets Ready/refresh | True/SecretSynced/< 2h | True/SecretSynced/refresh 10:38:07Z (23min ago, post-Q-1B-5B-1) | OK |
| Argo Application matching keybuzz-api-dev | (a determiner) | 1 trouvee : autoSync=false sync=Unknown health=Healthy | OK identifie |
| Argo Application matching keybuzz-api-prod | (a determiner) | AUCUNE | OK identifie (kubectl apply manuel obligatoire en EXEC) |

## BEFORE snapshot Deployments + Secrets DEV + PROD (E2)

Snapshot persiste dans `/tmp/keybuzz-q1b5b2-before-metadata.jsonl` mode 600 (12 lignes, 0 base64-payload leak), shred apres rapport.

### DEV (keybuzz-api-dev)

| Resource | Field | Value |
|---|---|---|
| Deployment keybuzz-api | generation / observedGeneration | 487 / 487 |
| Deployment keybuzz-api | replicas spec/avail/ready | 1 / 1 / 1 |
| Deployment keybuzz-api | image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-dev |
| Deployment keybuzz-api | strategy | RollingUpdate |
| Deployment keybuzz-api | env LITELLM_MASTER_KEY secret/key | keybuzz-litellm / LITELLM_MASTER_KEY (optional: true) |
| Secret manuel keybuzz-litellm | rv / created / age / keys | 22449413 / 2026-02-11T03:43:16Z / 96 jours / [LITELLM_MASTER_KEY] |
| Secret ESO keybuzz-litellm-secrets | rv / created / age / keys / owner | 31857821 / 2026-01-14T23:29:37Z / 124 jours / [LITELLM_MASTER_KEY] / ExternalSecret/keybuzz-litellm-secrets (controller) |
| ES keybuzz-litellm-secrets | ready / reason / refreshTime / rv | True / SecretSynced / 2026-05-18T10:26:42Z / 70432787 |
| Pod keybuzz-api-587774dbb6-rzzmq | phase / restarts / startTime / age | Running / 0 / 2026-05-16T21:02:07Z / ~38h |

### PROD (keybuzz-api-prod)

| Resource | Field | Value |
|---|---|---|
| Deployment keybuzz-api | generation / observedGeneration | 410 / 410 |
| Deployment keybuzz-api | replicas spec/avail/ready | 1 / 1 / 1 |
| Deployment keybuzz-api | image | ghcr.io/keybuzzio/keybuzz-api:v3.5.190-channels-tenantguard-prod |
| Deployment keybuzz-api | strategy | RollingUpdate |
| Deployment keybuzz-api | env LITELLM_MASTER_KEY secret/key | keybuzz-litellm / LITELLM_MASTER_KEY (sans optional) |
| Secret manuel keybuzz-litellm | rv / created / age / keys | 22599356 / 2026-02-11T10:53:34Z / 96 jours / [LITELLM_MASTER_KEY] |
| Secret ESO keybuzz-litellm-secrets | rv / created / age / keys / owner | 70436873 / 2026-05-18T10:38:07Z / 23 minutes / [LITELLM_MASTER_KEY] / ExternalSecret/keybuzz-litellm-secrets (controller) |
| ES keybuzz-litellm-secrets | ready / reason / refreshTime / rv | True / SecretSynced / 2026-05-18T10:38:07Z / 70436874 |
| Pod keybuzz-api-7685645f49-jx6m7 | phase / restarts / startTime / age | Running / 0 / 2026-05-17T14:19:11Z / ~21h |

### LiteLLM keybuzz-ai baseline

| Pod | phase | restarts | startTime |
|---|---|---|---|
| litellm-55bcfd7769-sfw8l | Running | 0 | 2026-04-06T09:40:46Z |
| litellm-55bcfd7769-xlhm7 | Running | 0 | 2026-05-15T10:59:31Z |

## Argo CD config DEV + PROD (E0.7)

| ns | name | path | autoSync | sync | health |
|---|---|---|---|---|---|
| argocd | keybuzz-api-dev | k8s/keybuzz-api-dev | false | Unknown | Healthy |
| argocd | (aucune pour api-prod) | - | - | - | - |

Decision EXEC futur : kubectl apply manuel obligatoire pour DEV + PROD (DEV : autoSync=false donc pas d'auto-apply meme avec Application existante ; PROD : pas d'Application).

Note : DEV sync=Unknown suggere un possible drift entre Git et runtime cote DEV egalement, a investiguer en parallele (hors scope cette phase).

## Comparaison metadata manual vs ESO (E3, sans lecture valeur)

### DEV (keybuzz-api-dev)

| Field | Secret manuel `keybuzz-litellm` | Secret ESO `keybuzz-litellm-secrets` | Diff verdict |
|---|---|---|---|
| type | Opaque | Opaque | identique |
| rv | 22449413 | 31857821 | distincts (rv ESO posterieur cluster-wide) |
| created | 2026-02-11T03:43:16Z | 2026-01-14T23:29:37Z | **ESO plus ANCIEN (124j) que manuel (96j)** |
| key_names | [LITELLM_MASTER_KEY] | [LITELLM_MASTER_KEY] | MATCH |
| key_count | 1 | 1 | identiques |
| ownerReferences | [] | [{ExternalSecret/keybuzz-litellm-secrets, controller}] | ESO owned by ES |
| labels | [] | [reconcile.external-secrets.io/created-by, /managed] | ESO labels reconcile |

**Insight DEV** : Le Secret ESO existe depuis le 14 janvier 2026, le Secret manuel a ete cree le 11 fevrier 2026 (~1 mois APRES). Hypothese probable : creation manuelle d'override apres l'existence ESO, possiblement pour debug ou rotation manuelle isolee de DEV. Le Deployment a ensuite ete pointe sur le manuel (suspect override post-creation). Risque drift valeur MOYEN-ELEVE en DEV.

### PROD (keybuzz-api-prod)

| Field | Secret manuel `keybuzz-litellm` | Secret ESO `keybuzz-litellm-secrets` | Diff verdict |
|---|---|---|---|
| type | Opaque | Opaque | identique |
| rv | 22599356 | 70436873 | distincts |
| created | 2026-02-11T10:53:34Z | 2026-05-18T10:38:07Z | **manuel ANCIEN (96j), ESO RECENT (23min, Q-1B-5B-1)** |
| key_names | [LITELLM_MASTER_KEY] | [LITELLM_MASTER_KEY] | MATCH |
| key_count | 1 | 1 | identiques |
| ownerReferences | [] | [{ExternalSecret/keybuzz-litellm-secrets, controller}] | ESO owned by ES |
| labels | [] | [reconcile.external-secrets.io/created-by, /managed] | ESO labels reconcile |

**Insight PROD** : Le Secret manuel est l'historique original (96 jours), le Secret ESO est tout neuf (Q-1B-5B-1). Le risque drift valeur depend de la maintenance Vault path : si le path Vault `secret/keybuzz/litellm/master_key` a ete maintenu en sync avec le manuel jusqu'a Q-1B-5B-1, valeurs probablement identiques. Si pas maintenu, valeurs probablement differentes. Risque drift valeur MOYEN.

## Manifest patch Deployment DEV (E4, YAML diff inline)

Manifest source `k8s/keybuzz-api-dev/deployment.yaml` (14467 bytes) lu en read-only. Copie patchee generee dans `/tmp/keybuzz-q1b5b2-deployment-dev-patched.yaml` (mode 600), 1 patch applique avec succes :

```diff
--- /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml
+++ /tmp/keybuzz-q1b5b2-deployment-dev-patched.yaml
@@ -167,7 +167,7 @@
         - name: LITELLM_MASTER_KEY
           valueFrom:
             secretKeyRef:
-              name: keybuzz-litellm
+              name: keybuzz-litellm-secrets
               key: LITELLM_MASTER_KEY
               optional: true
         - name: BACKEND_INTERNAL_URL
```

Aucun autre changement (verification md5 du reste du manifest). Source k8s/ INCHANGE (correction 1).

## Manifest patch Deployment PROD (E5, YAML diff inline)

Manifest source `k8s/keybuzz-api-prod/deployment.yaml` (16969 bytes) lu en read-only. Copie patchee generee dans `/tmp/keybuzz-q1b5b2-deployment-prod-patched.yaml` (mode 600), 1 patch applique avec succes :

```diff
--- /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
+++ /tmp/keybuzz-q1b5b2-deployment-prod-patched.yaml
@@ -263,7 +263,7 @@
             - name: LITELLM_MASTER_KEY
               valueFrom:
                 secretKeyRef:
-                  name: keybuzz-litellm
+                  name: keybuzz-litellm-secrets
                   key: LITELLM_MASTER_KEY
             - name: BACKEND_INTERNAL_URL
               value: "http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:3001"
```

Aucun autre changement intentionnel. Source k8s/ INCHANGE.

## kubectl apply --dry-run=server DEV (E6.1, correction 1)

| Field | Value |
|---|---|
| Command | `kubectl apply -f /tmp/keybuzz-q1b5b2-deployment-dev-patched.yaml --dry-run=server` |
| stdout | `deployment.apps/keybuzz-api configured (server dry run)` |
| exit code | 0 |
| Server-side validation | OK (schema strategic merge accepte) |

## kubectl diff DEV (E6.2, separe de apply per correction 1)

Diff montre les changements applicables (uniquement le patch env-var attendu + bump generation runtime futur, ce dernier NON considere comme verification dry-run per correction 2) :

```diff
@@ -186,7 +186,7 @@
           valueFrom:
             secretKeyRef:
               key: LITELLM_MASTER_KEY
-              name: keybuzz-litellm
+              name: keybuzz-litellm-secrets
               optional: true
```

| Field | Value |
|---|---|
| Command | `kubectl diff -f /tmp/keybuzz-q1b5b2-deployment-dev-patched.yaml` |
| exit code | 1 (= differences exist, attendu) |
| Changement focus | secretKeyRef.name : keybuzz-litellm -> keybuzz-litellm-secrets (1 occurrence) |
| Autres changements | aucun (last-applied-configuration annotation refresh est cosmetique, non operationnel) |
| Note correction 2 | le bump generation 487 -> 488 visible dans le diff est effet futur runtime, PAS verification dry-run |

## kubectl apply --dry-run=server PROD (E6.3, correction 1)

| Field | Value |
|---|---|
| Command | `kubectl apply -f /tmp/keybuzz-q1b5b2-deployment-prod-patched.yaml --dry-run=server` |
| stdout | `deployment.apps/keybuzz-api configured (server dry run)` |
| exit code | 0 |
| Server-side validation | OK |

## kubectl diff PROD (E6.4, separe, ALERTE DRIFT)

Diff montre **2 changements** :

1. **Changement intentionnel** (notre patch env-var) :
```diff
@@ -189,7 +189,7 @@
           valueFrom:
             secretKeyRef:
               key: LITELLM_MASTER_KEY
-              name: keybuzz-litellm
+              name: keybuzz-litellm-secrets
         - name: BACKEND_INTERNAL_URL
```

2. **DRIFT IMPREVU detecte** (valeurs masquees au format `<HEX_40_TOKEN_A>` et `<HEX_40_TOKEN_B>`) :
```diff
@@ -219,7 +219,7 @@
         - name: STAKATER_VAULT_ROOT_TOKEN_SECRET
-          value: <HEX_40_TOKEN_A_LIVE_RUNTIME>
+          value: <HEX_40_TOKEN_B_GIT_SOURCE>
         - name: CONVERSION_WEBHOOK_ENABLED
           value: "true"
```

| Field | Value |
|---|---|
| Command | `kubectl diff -f /tmp/keybuzz-q1b5b2-deployment-prod-patched.yaml` |
| exit code | 1 (attendu, differences exist) |
| Changement intentionnel | secretKeyRef.name : keybuzz-litellm -> keybuzz-litellm-secrets (1 occurrence) |
| **DRIFT IMPREVU** | env STAKATER_VAULT_ROOT_TOKEN_SECRET value diverge runtime vs source Git (2 valeurs hex 40 chars distincts) |
| Impact si EXEC apply Q-1B-5B-2-EXEC-PROD | apply manifest Git ecraserait la valeur runtime avec la valeur Git (possiblement obsolete) |

**ALERTE STAKATER_VAULT_ROOT_TOKEN_SECRET** :
- Token expose en clair `value:` dans manifest Git PROD (pattern identique au leak LITELLM_MASTER_KEY documente en Q-1B-5A).
- Pattern hex 40 chars (sha1-like ou token Vault generique).
- Le drift Git vs runtime indique soit :
  - (a) Rotation post-commit Git (ex : Q-1B-1B Vault token rotation a modifie le runtime sans commit Git correspondant)
  - (b) Modification runtime hors-GitOps (kubectl set env / patch / edit bypass)
- Bloquant Q-1B-5B-2-EXEC-PROD jusqu'a investigation root cause + alignment Git.

## Simulation post-apply attendue (E7, NON execute)

### DEV (Q-1B-5B-2-EXEC-DEV future)

| Resource | Pre-EXEC | Post-EXEC attendu | Impact runtime |
|---|---|---|---|
| Deployment generation | 487 | 488 (effet du apply) | bump (effet apply, pas verif dry-run) |
| Deployment env LITELLM_MASTER_KEY secret | keybuzz-litellm | keybuzz-litellm-secrets | switched |
| ReplicaSet | actuel | nouveau cree | redeploy |
| Pod | rzzmq Running age 38h | nouveau pod cree puis ancien terminate | rolling update |
| Pod restartCount | 0 | 0 (nouveau pod = restart counter reset) | nouvelle instance |
| Downtime LLM features | 0 | < 30s (rolling update, readiness probe 5s+10s) | court |
| Drift valeur LITELLM_MASTER_KEY | INCONNU | si != : auth 401 immediat ; si == : 0 impact | INCONNU |

### PROD (Q-1B-5B-2-EXEC-PROD future)

**BLOCKED** par drift STAKATER_VAULT_ROOT_TOKEN_SECRET. Apres resolution D6 :

| Resource | Pre-EXEC | Post-EXEC attendu | Impact runtime |
|---|---|---|---|
| Deployment generation | 410 | 411 | bump |
| Deployment env LITELLM_MASTER_KEY secret | keybuzz-litellm | keybuzz-litellm-secrets | switched |
| Deployment env STAKATER_VAULT_ROOT_TOKEN_SECRET | runtime <HEX_A> | Git <HEX_B> (si non resolu : casse Vault token PROD) | DEPEND resolution D6 |
| Pod | jx6m7 Running age 21h | redeploy | rolling update |
| Downtime LLM features + Vault token impact | 0 | < 30s ou plus si STAKATER drift impacte Vault | DEPEND |

## Risk matrix (E8)

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Drift valeur LITELLM_MASTER_KEY ESO vs manual DEV (auth 401) | MOYEN-ELEVE (ESO 124j > manuel 96j, suspicion override manuel) | MOYEN (DEV) | EXEC-DEV en heure faible trafic + rollback git revert rapide |
| R2 | Drift valeur LITELLM_MASTER_KEY ESO vs manual PROD (auth 401) | MOYEN (ESO recent 23min, depend si Vault path maintenu sync avec manuel) | ELEVE (PROD) | EXEC-PROD apres validation DEV + rollback rapide |
| R3 | Rollout RollingUpdate cause downtime > 30s | FAIBLE (replicas=1, readiness probe initialDelay 5s + period 10s) | MOYEN | EXEC heure faible trafic + monitor pod Ready |
| R4 | Argo CD auto-sync apply pendant dry-run | NEANT (DEV autoSync=false, PROD pas d'Application, manifests dans /tmp hors Git) | NEANT | non-applicable |
| R5 | Patch perd des champs Deployment | NEANT (patch chirurgical ligne unique secretKeyRef.name, verifie diff complet) | ELEVE | E4-E5 diff source vs patched verifie 1 ligne unique |
| R6 | EXEC-PROD declenche avant validation 24h DEV | NEANT (Mode B SAFE gates en EXEC) | ELEVE | sequence Q-1B-5B-2-EXEC-DEV + 24h + Q-1B-5B-2-EXEC-PROD |
| R7 | Rollback nominal (git revert + apply) cause encore rolling update | FAIBLE (effet symetrique attendu) | MOYEN | rollback documente, accepter petit downtime supplementaire |
| R8 | Rollback emergency kubectl rollout undo necessite GO explicite (correction 3) | NEANT par defaut | ELEVE si non-respecte | correction 3 documente phrase exacte `GO ROLLBACK EMERGENCY UNDO Q-1B-5B-2-EXEC` |
| R9 | LiteLLM ESO sync interim ecrase valeur Vault apres rotation Q-1B-5B-5 | NEANT (cette phase ne touche pas Vault) | NEANT | hors scope |
| R10 | Parite IA messaging baseline cassee post-switch | MOYEN si R1/R2 active | ELEVE | EXEC-DEV step 5 smoke test + EXEC-PROD step 9 parite messaging baseline obligatoire |
| R11 | **DRIFT STAKATER_VAULT_ROOT_TOKEN_SECRET PROD bloque apply manifest Git** | CERTAIN (confirme par diff E6.4) | ELEVE | D6 investigation + alignement Git AVANT EXEC-PROD |
| R12 | **STAKATER token expose plain-text dans Git keybuzz-infra** | CERTAIN | ELEVE | pattern identique LITELLM_MASTER_KEY Q-1B-5A, candidat migration ESO + rotation (D8) |

## Plan EXEC Q-1B-5B-2-EXEC Variante A propose (E9, NON execute)

| step | action | dependency | gate | risk | rollback NOMINAL | rollback EMERGENCY (correction 3) | required_GO_phrase |
|---|---|---|---|---|---|---|---|
| 1 | Prompt CE Q-1B-5B-2-EXEC-DEV Mode B SAFE | Q-1B-5B-2 rapport commit | GO Ludovic | FAIBLE | none | none | (separe) |
| 2 | Commit + push patch deployment.yaml DEV (1 fichier) | step 1 GO | scope strict | FAIBLE | `git revert <commit> && git push` | none | GO COMMIT DEPLOYMENT DEV Q-1B-5B-2-EXEC |
| 3 | kubectl apply -f deployment.yaml DEV (Argo Application existe mais autoSync=false donc apply manuel) | step 2 push | STOP Gate apply Mode B SAFE | MOYEN | `git revert <commit> && git push && kubectl apply -f <manifest-reverted>` | `kubectl rollout undo deployment/keybuzz-api -n keybuzz-api-dev` apres `GO ROLLBACK EMERGENCY UNDO DEV Q-1B-5B-2-EXEC` exact | GO APPLY DEPLOYMENT DEV Q-1B-5B-2-EXEC |
| 4 | Wait rollout status DEV + verify pod Ready + 0 ImagePullBackOff/ErrImagePull | step 3 | STOP si pod KO | MOYEN | rollback NOMINAL step 3 | rollback EMERGENCY step 3 | (auto-monitor) |
| 5 | Smoke test endpoint LLM DEV (1 appel non-engageant) | step 4 | STOP si auth fail | ELEVE | rollback NOMINAL | rollback EMERGENCY | (auto + visual Ludovic) |
| 6 | Validation 24h+ DEV : restartCount, ErrImagePull, 401, parite IA messaging | step 5 OK | (continue 24h) | none | none | none | (continue) |
| 7 | **Q-1B-5B-2-PROD-PRE : Resolution D6 drift STAKATER** | step 6 stable | GO Ludovic separe | ELEVE | none | none | GO Q-1B-5B-2-PROD-PRE INVESTIGATE STAKATER DRIFT |
| 8 | Prompt CE Q-1B-5B-2-EXEC-PROD Mode B SAFE PROD (apres D6 resolu) | step 7 + GO PROD | GO Ludovic PROD obligatoire | ELEVE | rollback complete | rollback complete | GO Q-1B-5B-2-EXEC-PROD MODE B SAFE |
| 9 | Idem steps 2-5 pour PROD avec gates Mode B SAFE PROD | step 8 | gates par mutation | ELEVE | git revert PROD + push + apply revert | kubectl rollout undo PROD apres `GO ROLLBACK EMERGENCY UNDO PROD Q-1B-5B-2-EXEC` | GO COMMIT/PUSH/APPLY DEPLOYMENT PROD Q-1B-5B-2-EXEC |
| 10 | Validation 24h+ PROD + parite IA messaging baseline obligatoire | step 9 | (continue 24h) | none | none | none | (continue) |
| 11 | Apres stabilisation : passer a Q-1B-5B-4 (delete Secrets manuels) | step 10 stable | GO Ludovic Q-1B-5B-4 | FAIBLE post-validation | recreate manual si urgence | recreate manual emergency | GO Q-1B-5B-4 (separe) |

### Notes correction 3 - Rollback NOMINAL vs EMERGENCY

- **Rollback NOMINAL** (default attendu) : `git revert <commit>` + `git commit/push manifest revert` + `kubectl apply -f <manifest-reverted>`. Preserve la coherence GitOps source-of-truth, traceabilite via Git log, reviewable.
- **Rollback EMERGENCY** (uniquement avec GO phrase exacte) : `kubectl rollout undo deployment/keybuzz-api -n <ns>`. Necessite `GO ROLLBACK EMERGENCY UNDO <env> Q-1B-5B-2-EXEC` exact. Casse temporaire la coherence GitOps (runtime != Git), a corriger immediatement apres par commit revert Git. A reserver aux situations ou git revert + apply prendrait trop de temps face a un incident production critique.

## No fake metrics (E10)

N/A. Phase dry-run pure, aucun KPI/dashboard touche.

## AI feature parity (E11)

Phase dry-run zero-impact runtime confirme par E6.5 (Deployments runtime inchanges, pas de rollout).

EXEC futur Q-1B-5B-2-EXEC impactera transitoirement :
- DEV step 3 : rolling update Deployment keybuzz-api -> pod nouveau cree avant ancien terminate -> ~5-15s degradation endpoints /api/ai/* possible
- PROD step 9 : meme impact, plus risque eleve (apres validation DEV)
- Test parite IA messaging baseline OBLIGATOIRE en step 10

Reference `AI_MEMORY/AI_MESSAGING_FEATURE_PARITY_BASELINE.md` a verifier en EXEC :
- Smoke test recommande : 1 message tenant test + verif tonalite + verif latence < SLO + verif Brouillon IA fonctionne
- Verif Agent KeyBuzz endpoint /ai/execute repond 200
- Verif autopilot tick processor pas de 401 LiteLLM

LiteLLM keybuzz-ai pods : 0 impact attendu (consume litellm-secret ESO depuis Vault, independant de cette phase).

## Cleanup temporary files (E12)

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1b5b2-before-metadata.jsonl | 600 | shred apres redaction rapport |
| /tmp/keybuzz-q1b5b2-deployment-dev-patched.yaml | 600 | shred (contenu inline diff dans rapport pour traceability) |
| /tmp/keybuzz-q1b5b2-deployment-prod-patched.yaml | 600 | shred (contenu inline diff dans rapport pour traceability) |
| /tmp/keybuzz-q1b5b2-e1-e3-runner.sh | 755 | shred |
| /tmp/keybuzz-q1b5b2-e4-e6-runner.sh | 755 | shred |

Aucun manifest persiste dans `k8s/` (correction 1 respectee). Sources `k8s/keybuzz-api-{dev,prod}/deployment.yaml` md5 INCHANGES.

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1B-5B-2 | Impact |
|---|---|---|---|
| keybuzz-api-prod Deployment | gen=410 obs=410 env=keybuzz-litellm | inchange (dry-run non-persistant) | 0 |
| keybuzz-api-prod Pod jx6m7 | Running 1/1 age 21h restartCount=0 | inchange | 0 |
| keybuzz-api-prod Secret manuel keybuzz-litellm | rv=22599356 | inchange | 0 |
| keybuzz-api-prod Secret ESO keybuzz-litellm-secrets | rv=70436873 (Q-1B-5B-1) | inchange | 0 |
| keybuzz-api-prod ES keybuzz-litellm-secrets | Ready=True | inchange | 0 |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-ai litellm 2 pods | Running 0 restart | inchanges (baseline B0.7 maintenu) | 0 |
| Vault KV PROD | non touche | non touche | 0 |
| Argo CD applications | inchange | inchange (manifests /tmp hors Git) | 0 |
| Providers LLM | non touche | non touche | 0 |
| k8s/keybuzz-api-{dev,prod}/deployment.yaml | md5 stable | md5 stable | 0 (correction 1) |
| Git history | HEAD 5945f87 | HEAD 5945f87 | 0 |

## Compliance read-only + dry-run

| Interdit | Evidence | Verdict |
|---|---|---|
| Apply effective | 0 (uniquement --dry-run=server, E6.5 confirme runtime gen inchange) | OK |
| kubectl create/patch/edit/delete/annotate/label/rollout | 0 commande | OK |
| kubectl run/exec/port-forward (correction 4 Q-1B-5B-1 maintenue) | 0 commande, verifications read-only via get/diff/apply --dry-run | OK |
| Lecture .data value secret | 0, projection `(.data // {}) | keys` uniquement | OK |
| base64 -d / decode | 0 | OK |
| Vault command | 0 | OK |
| Provider call LLM externe | 0 | OK |
| Proxy LiteLLM /chat /embeddings | 0 | OK |
| Manifest persiste dans k8s/ (correction 1) | 0, patches dans /tmp uniquement, md5 source stable | OK |
| git add du Deployment patche | 0 | OK |
| kubectl diff combine avec apply (correction 1) | 0, deux commandes separees E6.1+E6.2 et E6.3+E6.4 | OK |
| Attendre generation bump dans diff (correction 2) | bump observe en diff mais documente comme effet EXEC futur, pas verification dry-run | OK |
| Rollback nominal default = kubectl rollout undo (correction 3) | rollback NOMINAL = git revert + push + apply ; EMERGENCY undo necessite phrase GO exacte | OK |
| Commit/push sans GO Gate E14 | rapport en untracked, attente GO `GO E14 commit/push rapport Q-1B-5B-2` | OK |
| Tenant/user/email hardcode | 0 | OK |
| Toucher PROD mutation | 0 | OK |
| Affichage valeur LITELLM_MASTER_KEY | 0 (jamais lue) | OK |
| Affichage valeur STAKATER_VAULT_ROOT_TOKEN_SECRET | tokens hex 40 chars masques en `<HEX_40_TOKEN_A>` / `<HEX_40_TOKEN_B>` dans le rapport (mais visibles dans diff stdout output dry-run, exposition partielle) | WARN partielle, voir D8 |

22/22 contraintes Mode B SAFE respectees + 1 alerte WARN partielle sur exposition STAKATER token dans diff stdout (mitigation D8).

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5B-2 LLM API ENV-VAR MIGRATION DRY-RUN

Status: COMPLETE - DESIGN DECISIONS D6/D7/D8 REQUIRED
Scope: DEV + PROD read-only + dry-run server-side

Findings:
- Patches Deployment DEV + PROD valides via kubectl apply --dry-run=server exit 0
- kubectl diff (separe per correction 1) montre uniquement changement secretKeyRef.name attendu en DEV
- ALERTE NOUVELLE PROD: drift IMPREVU detecte sur env STAKATER_VAULT_ROOT_TOKEN_SECRET (value runtime != source Git)
- Pattern d'exposition plain-text token PROD similaire LITELLM_MASTER_KEY Q-1B-5A

Comparaison metadata manual vs ESO sans lecture valeur:
- DEV : ESO 124j > manuel 96j (suspicion override manuel posterieur)
- PROD : manuel 96j > ESO 23min (Q-1B-5B-1 cree hier)
- key_names identiques [LITELLM_MASTER_KEY] dans les 2

Decisions Ludovic requises:
- D6: Strategie drift STAKATER_VAULT_ROOT_TOKEN_SECRET PROD (resolu AVANT Q-1B-5B-2-EXEC-PROD)
- D7: Sequence Q-1B-5B-2-EXEC apres resolution D6 (recommande DEV-first + validation 24h)
- D8: Strategie STAKATER token expose plain-text Git keybuzz-infra (candidat migration ESO + rotation, similar to LITELLM_MASTER_KEY)

Plan EXEC Q-1B-5B-2-EXEC Variante A 11 steps documente avec rollback NOMINAL (git revert + apply) et EMERGENCY (kubectl rollout undo avec GO phrase exacte) per correction 3.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2-KEY-323-LLM-API-ENV-VAR-MIGRATION-DRYRUN-01.md
NO GO maintenus: Q-1B-5B-2-EXEC (DEV + PROD), Q-1B-5B-4, Q-1B-5B-5, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **D6 (NOUVELLE)** : investigation root cause + resolution drift STAKATER_VAULT_ROOT_TOKEN_SECRET PROD AVANT Q-1B-5B-2-EXEC-PROD.
2. **D7 (NOUVELLE)** : confirmation sequence DEV-first + 24h + GO PROD apres D6 resolu.
3. **D8 (NOUVELLE)** : strategie migration STAKATER token vers ESO + rotation (similar pattern LITELLM_MASTER_KEY Q-1B-5A).
4. **Q-1B-5B-2-EXEC-DEV** : NO GO maintenu, requires GO Ludovic separe + prompt CE Mode B SAFE dedicace.
5. **Q-1B-5B-2-EXEC-PROD** : NO GO maintenu (prerequis D6 + validation DEV stable 24h).
6. **Q-1B-5B-4 delete Secrets manuels** : NO GO maintenu.
7. **Q-1B-5B-5 rotation Vault master_key** : NO GO maintenu.
8. **Q-1B-5B-6 sync + restart + parite messaging** : NO GO maintenu.
9. **Q-1B-5B-7 cleanup k8s/litellm/secret.yaml expose Git** : NO GO maintenu.
10. **Q-1B-5C studio-api migration ESO** : NO GO maintenu.
11. **Q-1B-3D-2B harmonisation pleine GHCR** : NO GO maintenu.
12. **Q-1B-3D-3 + Q-1B-3E + Q-1B-3B + Q-1B-3C + Q-1B-6 + Q-1B-4 + Q-1B-7 + Q-1F-3** : restent dans la file.
13. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue.
14. **backfill-scheduler ImagePullBackOff** : hors scope.
15. **DEV Argo sync=Unknown** : a investiguer en parallele (suggere drift potentiel cote DEV egalement).

## Phrase cible finale

Validation dry-run Deployment keybuzz-api DEV + PROD migration env-var LITELLM_MASTER_KEY de Secret manuel `keybuzz-litellm` vers Secret ESO `keybuzz-litellm-secrets` complete (BEFORE snapshot Deployments + Secrets + Pods DEV + PROD + LiteLLM baseline, comparaison metadata manual vs ESO documentee sans lecture valeur, patches dans /tmp uniquement mode 600 shred apres rapport, kubectl apply --dry-run=server exit 0 sur les 2 patches, kubectl diff separe per correction 1 montre changement env-var attendu + generation bump effet futur per correction 2), **ALERTE NOUVELLE drift PROD IMPREVU detecte sur STAKATER_VAULT_ROOT_TOKEN_SECRET (value runtime != value source Git) bloquant Q-1B-5B-2-EXEC-PROD jusqu'a investigation D6**, plan EXEC Q-1B-5B-2-EXEC Variante A 11 steps documente avec rollback NOMINAL git revert + apply et EMERGENCY kubectl rollout undo avec GO phrase exacte per correction 3 - aucune mutation runtime, aucune apply effective, aucune lecture de valeur secret, 0 vault command, 0 provider call, 0 ecriture dans k8s/, sources Git md5 stable, PROD intouchee - Q-1B-5B-2-EXEC-DEV reste NO GO en attente GO Ludovic + Q-1B-5B-2-EXEC-PROD reste NO GO en attente D6 + GO Ludovic PROD.

STOP
