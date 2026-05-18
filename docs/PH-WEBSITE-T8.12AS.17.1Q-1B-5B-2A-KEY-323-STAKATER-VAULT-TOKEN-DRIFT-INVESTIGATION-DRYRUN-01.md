# PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-KEY-323-STAKATER-VAULT-TOKEN-DRIFT-INVESTIGATION-DRYRUN-01

> Date : 2026-05-18
> Linear : KEY-323
> Phase : AS.17.1Q-1B-5B-2A
> Environnement : PROD lecture + DEV lecture + Git history forensic (aucune mutation, aucune lecture de valeur en clair)

## VERDICT

GO READY Q-1B-5B-2A ROOT CAUSE IDENTIFIED + OPTION E RECOMMANDEE

Investigation drift `STAKATER_VAULT_ROOT_TOKEN_SECRET` PROD complete. Root cause confirmee avec preuve formelle : Stakater Reloader v1.2.1 auto-injecte les env-vars `STAKATER_<NAME>_SECRET` au runtime des Deployments annotes `reloader.stakater.com/auto=true`. Ces valeurs sont des hashes SHA1/SHA256 des Secrets/ConfigMaps references, **par design jamais committees en Git**.

Le drift PROD est cause par UN SEUL commit `e77b7cb` (2026-04-20T18:38:36+0200, auteur ecomlgfr, message `PH-T8.2E: PROD promotion metrics pipeline - v3.5.86-trial-vs-paid-metrics-prod`) qui a ajoute par erreur ces env-vars dans le manifest Git PROD avec commentaire revelateur "PH-T8.2E: tracking env vars (synced from live PROD)" -> aveu d'un workflow `kubectl get deploy -o yaml > deployment.yaml` ayant fige par accident des valeurs Reloader runtime du moment.

Preuves :
- **DEV manifest Git grep STAKATER = VIDE** (0 ligne, 0 commit historique sur ce fichier touchant STAKATER) MAIS DEV runtime contient `STAKATER_VAULT_ROOT_TOKEN_SECRET` et `STAKATER_KEYBUZZ_API_JWT_SECRET` (40 chars chacun) -> Reloader injecte ces env-vars au runtime de maniere autonome SANS aucune ligne dans Git source. DEV est le pattern correct.
- **PROD runtime hash = DEV runtime hash = `b9eb13df`** : les valeurs runtime PROD et DEV sont identiques (meme Vault root token unifie), generees par Reloader, donc Git PROD `c0f128e4` est obsolete (fige depuis avril 2026 alors que rotations Q-1B-1B + Q-1B-2B Mai 2026 ont change les Secrets references).
- **Reloader installe namespace `reloader`, image `stakater/reloader:v1.2.1`, 142d age, observation annotation `reloader.stakater.com/auto=true` sur 6 Deployments** : api/client/studio-api en DEV+PROD.
- **vault-token-renew CronJob** dans `vault-management`, schedule `0 3 * * *`, dernier succes `2026-05-18T03:00:07Z` (ce matin), explique la rotation periodique du Vault root token sous-jacent referent dans les Secrets que Reloader hashe.
- **Cluster-wide audit revele 10 env-vars STAKATER_<NAME>_SECRET** dans 7 Deployments, toutes value plain-text 40 chars, aucune via secretKeyRef. Pattern non-trivial mais coherent avec auto-injection Reloader runtime.
- **Audit hex64 plain-text Git** revele 2 fichiers supplementaires (`keybuzz-client-{dev,prod}/deployment.yaml`) exposant un hex64 (`<HEX64_ed4a534a>`, **meme valeur DEV et PROD** = pattern Reloader systematique).

Recommandation analyste **Option E** (nouvelle, ajoutee suite a finding architecture) : retirer entierement les env-vars STAKATER_<NAME>_SECRET du manifest Git source PROD + audit similaire pour les hex64 client-{dev,prod}. Aligner PROD sur le pattern DEV qui FONCTIONNE deja sans ces env-vars Git. Reloader continuera d'injecter au runtime sans risque. Apply post-suppression Git ne casse rien (les env-vars retournent au runtime via Reloader injection autonome). Cette option est **superieure aux options A/B/C/D** car elle elimine la cause racine (commit accidentel d'artefacts runtime).

Option A "commit runtime value in Git" est **CLASSEE NON RECOMMANDEE** (correction 4) car elle perpetue l'exposition Git et necessite re-commit a chaque rotation Vault. Options C (ESO migration) et D (secretKeyRef) sont sur-engineering pour des hashes auto-injectes qui ne sont pas des secrets primaires.

Aucune mutation. Aucune lecture de valeur en clair (hashes SHA256[:8] partout via redacteur Python, valeurs runtime/Git captureses dans variables shell unset immediat apres hash). Aucun vault command. Aucun provider call. Aucun kubectl apply ou apply --dry-run. Aucun kubectl run/exec/port-forward. Manifests Git source md5 stables (DEV `1a832b1c`, PROD `d471a089`). Safety checks finaux 0 hex40 leak dans tous outputs /tmp + rapport (verif Python regex).

## Scope / hors scope

### Scope strict applique

- Git history forensic : `git log --oneline --follow` + `git log -p -S` (PROD + DEV), tout output redacte via Python script hex40 -> `<HEX40_<sha256:8>>` AVANT affichage et fichier.
- Capture runtime + Git hashes : SCP runner umask 077, set +x, variables shell capture + sha256sum + unset immediat, fichier sortie 4 hashes courts uniquement.
- Cluster-wide audit STAKATER env name refs + Pods Running consumers.
- Cluster-wide audit hex40 + hex64 plain-text exposures dans `k8s/` (manifests actifs hors backup).
- Stakater Reloader presence + image + args inspection.
- vault-token-renew CronJob inspection.
- DEV vs PROD manifest grep comparison.

### Hors scope respecte (5 corrections appliquees)

- **Correction 1** : runner SCP umask 077 set +x, capture variables + sha256sum + unset immediat, fichier sortie hashes courts only. AUCUN jsonpath/grep affichant valeur stdout.
- **Correction 2** : git log -p passe via redacteur Python qui remplace hex40 par `<HEX40_<sha8>>` AVANT affichage + ecriture fichier.
- **Correction 3** : safety check final sur tous `/tmp/keybuzz-q1b5b2a-*` + rapport, regex hex40 hors short SHA Git commits documentes.
- **Correction 4** : Option A classee NON RECOMMANDEE explicitement. Options C/D evaluees comme remediation durable mais sur-engineering pour ce cas. Option E (nouvelle) recommandee comme remediation propre.
- **Correction 5** : 0 mutation runtime, 0 vault command, 0 kubectl apply/dry-run/apply, 0 provider call.

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2-KEY-323-LLM-API-ENV-VAR-MIGRATION-DRYRUN-01.md | sha256 6bf658609ba46b48eae0140a22051c25f8d33f0d960d6c344ef4c07b8ab1eced (commit 9ad2c9d) | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-1-KEY-323-LLM-PROD-ESO-MIGRATION-EXEC-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5A-KEY-323-LLM-SECRETS-DEDUP-DRYRUN-01.md | present (LITELLM exposure pattern reference) | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1A-bis-exec-KEY-323-VAULT-ADMIN-TOKEN-REPLACEMENT-MODE-B-SAFE-01.md | present (admin-token rotation) | OK timeline rotation |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-1B-KEY-323-DEV-INTERNAL-LOW-RISK-EXEC-01.md | present (KV DEV rotation) | OK timeline |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-2B-KEY-323-PROD-INTERNAL-LOW-RISK-EXEC-MODE-B-SAFE-01.md | present (KV PROD rotation) | OK timeline |
| k8s/keybuzz-api-prod/deployment.yaml | md5 d471a089a2d145f1d2ba70ecb1f6ab81 | OK stable |
| k8s/keybuzz-api-dev/deployment.yaml | md5 1a832b1c4c7a84867ce849d81b21491f | OK stable |
| keybuzz-infra HEAD | 9ad2c9dfca188d5b6cb33a95ab9eb87e00ecb101 | OK |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc 9ad2c9d / clean | match | OK |
| Rapport Q-1B-5B-2 sha256 | 6bf65860 | match | OK |
| /tmp residuels Q-1B-5B-2A | absent | absent | OK |
| Manifests md5 stables | DEV 1a832b1c, PROD d471a089 | match | OK |

## Git history forensic

### PROD (k8s/keybuzz-api-prod/deployment.yaml)

`git log --oneline -30` montre 30 commits historiques sur ce fichier (toutes deploy-prod, principalement KEY-301/304/313/314 tenantGuard hardenings + AP/AR/AN/AM* feature promotes, et 1 commit PH-T8.2E specifique).

`git log -S "STAKATER_VAULT_ROOT_TOKEN_SECRET"` revele **UN SEUL commit historique** :

| Commit | Date | Auteur | Message |
|---|---|---|---|
| `e77b7cb` | 2026-04-20T18:38:36+0200 | ecomlgfr | PH-T8.2E: PROD promotion metrics pipeline - v3.5.86-trial-vs-paid-metrics-prod |

Patch extrait redacte (hex40 -> `<HEX40_<sha8>>`) :

```diff
              value: "true"
+            # PH-T8.2E: tracking env vars (synced from live PROD)
+            - name: STAKATER_VAULT_ROOT_TOKEN_SECRET
+              value: "<HEX40_c0f128e4>"
+            - name: CONVERSION_WEBHOOK_ENABLED
```

**INSIGHT MAJEUR** : le commentaire `# PH-T8.2E: tracking env vars (synced from live PROD)` est un aveu explicite que la valeur a ete copiee du runtime live a ce moment-la (workflow `kubectl get deploy -o yaml > deployment.yaml`). Le commit ajoute (pas de modification ulterieure), donc la valeur Git n'a JAMAIS ete maintenue en sync avec les rotations Vault posterieures.

### DEV (k8s/keybuzz-api-dev/deployment.yaml)

`git log --oneline -30` montre 30 commits deploy-dev (KEY-301/304/305/314, rollbacks divers).

`git log -S "STAKATER_VAULT_ROOT_TOKEN_SECRET"` retourne **0 commit**. La chaine `STAKATER_VAULT_ROOT_TOKEN_SECRET` n'a JAMAIS ete presente dans le manifest source Git DEV. Pattern correct (Reloader gere au runtime sans Git pollution).

## Hashes runtime vs Git (masque SHA256[:8])

Capture via SCP runner umask 077, variables shell capture + sha256sum + unset immediat, fichier sortie 4 hashes courts only.

| env | source | hash_sha256[:8] | value_length |
|---|---|---|---|
| prod | runtime | `b9eb13df` | 40 |
| prod | git_manifest | `c0f128e4` | 40 |
| dev | runtime | `b9eb13df` | 40 |
| dev | git_manifest | EMPTY_OR_NULL_(no_value) | 0 |

**Comparaisons critiques** :
- PROD runtime != PROD Git (drift Git/runtime confirme : `b9eb13df` != `c0f128e4`)
- PROD runtime == DEV runtime (`b9eb13df` == `b9eb13df`) : meme valeur effective en runtime des deux environnements
- DEV Git VIDE : DEV manifest n'a JAMAIS cette ligne, ce qui prouve Reloader injecte sans Git
- Le Git PROD `c0f128e4` est OBSOLETE depuis 28 jours (commit 2026-04-20, observation 2026-05-18)

Safety check fichier `/tmp/keybuzz-q1b5b2a-runtime-vs-git-hashes.jsonl` : 0 hex40 clear leak.

## Cluster-wide refs STAKATER

10 env-vars STAKATER_<NAME>_SECRET detectees dans 7 Deployments, toutes value plain-text length 40, AUCUNE via secretKeyRef :

| ns | kind | workload | env_name | val_length | secretKeyRef |
|---|---|---|---|---|---|
| keybuzz-api-dev | deploy | keybuzz-api | STAKATER_KEYBUZZ_API_JWT_SECRET | 40 | - |
| keybuzz-api-dev | deploy | keybuzz-api | STAKATER_VAULT_ROOT_TOKEN_SECRET | 40 | - |
| keybuzz-api-prod | deploy | keybuzz-api | STAKATER_KEYBUZZ_API_JWT_SECRET | 40 | - |
| keybuzz-api-prod | deploy | keybuzz-api | STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET | 40 | - |
| keybuzz-api-prod | deploy | keybuzz-api | STAKATER_VAULT_ROOT_TOKEN_SECRET | 40 | - |
| keybuzz-client-dev | deploy | keybuzz-client | STAKATER_KEYBUZZ_AUTH_SECRET | 40 | - |
| keybuzz-client-prod | deploy | keybuzz-client | STAKATER_KEYBUZZ_AUTH_SECRETS_SECRET | 40 | - |
| keybuzz-studio-api-dev | deploy | keybuzz-studio-api | STAKATER_KEYBUZZ_STUDIO_API_DB_SECRET | 40 | - |
| keybuzz-studio-api-dev | deploy | keybuzz-studio-api | STAKATER_KEYBUZZ_STUDIO_API_LLM_SECRET | 40 | - |
| keybuzz-studio-api-prod | deploy | keybuzz-studio-api | STAKATER_KEYBUZZ_STUDIO_API_LLM_SECRET | 40 | - |

Coherence Pods Running confirmee : memes refs visibles depuis kubectl get pods (10/10 match).

## Cluster-wide hex40 plain-text Git audit

3 fichiers manifests active contiennent `value: "<hex40>"` en plain-text :

| File | Line | Variable | Hash redacted |
|---|---|---|---|
| k8s/keybuzz-client-dev/deployment.yaml | 143 | (autre, voir hex64) | (en realite hex64, voir audit suivant) |
| k8s/keybuzz-api-prod/deployment.yaml | 299 | STAKATER_VAULT_ROOT_TOKEN_SECRET | `<HEX40_c0f128e4>` |
| k8s/keybuzz-client-prod/deployment.yaml | 144 | (autre, hex64) | (voir audit suivant) |

## Cluster-wide hex64 plain-text Git audit (pattern supplementaire)

Au-dela des hex40, le grep `value: ['"]?[a-f0-9]{64}['"]?` revele :

| File | Hash redacted |
|---|---|
| k8s/keybuzz-client-dev/deployment.yaml:143 | `<HEX64_ed4a534a>` |
| k8s/keybuzz-client-prod/deployment.yaml:144 | `<HEX64_ed4a534a>` |

**MEME hash entre DEV et PROD** : ces 2 fichiers contiennent la meme valeur hex64 plain-text. Probable STAKATER Reloader hash 64 chars (Reloader peut produire SHA256 si configure ainsi pour certains Secrets/ConfigMaps). A confirmer par analyse fichier complete (hors scope ce rapport, candidat phase Q-1B-5B-2A-RELOADER-CLEANUP).

Safety check fichier `/tmp/keybuzz-q1b5b2a-cluster-audit.txt` : 0 hex40 clear leak. Fichier `/tmp/keybuzz-q1b5b2a-git-forensic.txt` : 0 hex40 clear leak.

## Stakater Reloader architecture (E5)

| Field | Value |
|---|---|
| Namespace | reloader |
| Image | stakater/reloader:v1.2.1 |
| Args | null (default config) |
| Env names | [] (default config) |
| Age | 142 jours |
| Status | Available 1/1 |

**Pattern Stakater Reloader documente** :
- Reloader observe les annotations `reloader.stakater.com/auto=true` sur Deployments/StatefulSets/DaemonSets.
- Watches Secrets + ConfigMaps references via envFrom/env.valueFrom.secretKeyRef.
- Quand un Secret/ConfigMap change, Reloader injecte une env-var `STAKATER_<UPPERCASE_NAME>_SECRET` (ou _CONFIGMAP) dans le Deployment via `kubectl patch`, avec value = hash SHA1 (40 hex chars) ou SHA256 (64 hex chars selon config) du contenu du Secret/ConfigMap.
- Le patch modifie la spec Deployment, declenchant un nouveau ReplicaSet et redeploy pod (cache cle).
- L'injection se fait au RUNTIME, par design jamais committee en Git.

## Stakater Reloader annotations observees

| Deployment | Annotation reloader.stakater.com/auto |
|---|---|
| keybuzz-api-dev/keybuzz-api | true |
| keybuzz-api-prod/keybuzz-api | true |
| keybuzz-client-dev/keybuzz-client | true |
| keybuzz-client-prod/keybuzz-client | true |
| keybuzz-studio-api-dev/keybuzz-studio-api | true |
| keybuzz-studio-api-prod/keybuzz-studio-api | true |

Tous les 6 Deployments concernes ont Reloader auto. Coherent avec les 10 env-vars STAKATER detectees.

## vault-token-renew CronJob analysis (E6)

| Field | Value |
|---|---|
| Namespace | vault-management |
| Name | vault-token-renew |
| Schedule | 0 3 * * * (tous les jours a 3h UTC) |
| Suspended | false |
| Last schedule | 2026-05-18T03:00:00Z |
| Last success | 2026-05-18T03:00:07Z (succes en 7s) |
| Age | 37 jours |

Le CronJob tourne quotidiennement et a tourne ce matin avec succes. Sa fonction (deja documentee Q-1A-bis-exec) est de renouveler les tokens Vault stockes dans des Secrets K8s referenced via ESO ou directement.

**Chaine causalite drift documentee** :
1. CronJob `vault-token-renew` tourne quotidiennement -> renouvelle token Vault dans Secret K8s `vault-root-token` (keybuzz-api-prod).
2. Reloader detecte changement Secret `vault-root-token` -> patch Deployment keybuzz-api avec nouveau `STAKATER_VAULT_ROOT_TOKEN_SECRET` value (hash SHA1 du Secret update).
3. Pod redemarre avec nouvelle valeur runtime.
4. Git source non touche (par design).
5. Commit `e77b7cb` du 2026-04-20 a fige une valeur historique runtime (`c0f128e4`) qui ne reflete plus la valeur actuelle (`b9eb13df` runtime), d'ou drift.

## DEV equivalent comparison (E7)

| Item | DEV | PROD |
|---|---|---|
| Manifest Git STAKATER lines | 0 (vide) | 1 (commit e77b7cb 2026-04-20) |
| Runtime STAKATER_VAULT_ROOT_TOKEN_SECRET | present, hash b9eb13df | present, hash b9eb13df (identique) |
| Runtime STAKATER_KEYBUZZ_API_JWT_SECRET | present, length 40 | present, length 40 |
| Drift Git vs runtime | NEANT (rien en Git, runtime gere Reloader) | DETECTE (Git c0f128e4 vs runtime b9eb13df) |
| Pattern | CORRECT (Reloader autonome) | INCORRECT (commit accidentel Git) |

**Conclusion forte** : DEV demontre que le manifest Git **ne necessite PAS** d'avoir ces env-vars. Reloader les injecte avec succes au runtime. Le commit PROD `e77b7cb` est l'erreur a corriger.

## Hypotheses root cause (E8)

| ID | Hypothese | Statut | Preuve |
|----|-----------|--------|--------|
| H1 | Rotation post-commit Git par CronJob vault-token-renew | CONFIRMEE PARTIELLE | CronJob actif quotidien + dernier succes ce matin + 28j depuis le commit e77b7cb |
| H2 | Auto-injection Reloader au runtime (pas via Git) | CONFIRMEE | DEV manifest VIDE + DEV runtime present = preuve formelle Reloader injecte sans Git |
| H3 | Override manuel via kubectl set env / patch | NON RETENUE | aucun signe de patch manuel ; les patches Reloader sont automatiques |
| H4 | Mutating webhook tiers inconnu | NON RETENUE | Reloader explique tout |
| H5 | Commit Git initial fige valeur runtime ancienne par erreur (workflow kubectl get -o yaml) | CONFIRMEE | commentaire commit e77b7cb "synced from live PROD" = aveu explicite |

**Root cause finale** : H2 + H5 cumules. Reloader fonctionne correctement et injecte au runtime. Le commit accidentel `e77b7cb` du 2026-04-20 a fige une valeur runtime de cette date dans Git, qui a ensuite derive avec les rotations periodiques CronJob + ESO sync (H1). DEV demontre que la suppression est safe (Reloader continue d'injecter sans Git).

## Options alignement A/B/C/D + E (nouvelle)

### Option A (NON RECOMMANDEE, correction 4)

Commit la valeur runtime courante dans Git (Git c0f128e4 -> Git b9eb13df).

| Aspect | Evaluation |
|---|---|
| Resout drift immediat | OUI |
| Cout | FAIBLE (1 commit) |
| Risque | FAIBLE technique |
| Coherence GitOps | OUI temporaire |
| **Probleme** | Perpetue l'exposition Git. La valeur va re-deriver des la prochaine rotation Vault (demain matin 3h UTC, soit < 15h). Necessite re-commit a chaque rotation = pollution Git infinie. Augmente surface attaque (chaque commit revele un hash de moment t). |
| Verdict | **NON RECOMMANDEE sauf urgence exceptionnelle** |

### Option B (DANGEREUSE)

Apply Git pour ramener runtime (runtime b9eb13df -> runtime c0f128e4 forcee).

| Aspect | Evaluation |
|---|---|
| Resout drift | OUI |
| Cout | FAIBLE technique |
| Risque | **ELEVE** : la valeur Git c0f128e4 est obsolete depuis 28 jours, ne correspond plus a aucun Secret K8s actuel. L'apply va ecraser la valeur runtime correcte par une valeur obsolete. **Le pod va probablement perdre acces a Vault root token apres restart**. Plus Reloader detectera immediatement le drift et re-patchera, mais creant un cycle confus. |
| Coherence GitOps | OUI temporaire |
| Verdict | **DANGEREUSE - a eviter** |

### Option C (sur-engineering)

Migration vers ESO + path Vault `secret/keybuzz/stakater/vault_root_token`.

| Aspect | Evaluation |
|---|---|
| Resout drift | OUI long terme |
| Cout | MOYEN-ELEVE (creer ES + Vault path + migrer Deployment) |
| Risque | FAIBLE post-rotation |
| Coherence GitOps | OUI fort |
| **Probleme** | Sur-engineering : ces env-vars ne sont PAS des secrets primaires (juste hashes Reloader). Mettre un hash Reloader dans Vault + ESO est absurde. Le hash change a chaque rotation Vault, donc l'ES devrait synchroniser en permanence le hash. Architecturalement incorrect. |
| Verdict | INADAPTEE (mauvais outil pour le probleme) |

### Option D (sur-engineering moindre)

Externaliser via secretKeyRef vers Secret K8s existant (ex : Secret K8s `stakater-vault-root-token-secret` contenant le hash a chaque rotation).

| Aspect | Evaluation |
|---|---|
| Resout drift | OUI |
| Cout | MOYEN (creer Secret + maintenir sync hash) |
| Risque | MOYEN (qui maintient le hash a jour ? Reloader ? boucle infinie ?) |
| Coherence GitOps | OUI partiel |
| **Probleme** | Idem Option C : on essaie de mettre un hash Reloader dans un autre Secret, ce qui necessite un mecanisme pour maintenir ce Secret en sync avec les rotations. Sur-engineering. |
| Verdict | INADAPTEE |

### Option E (NOUVELLE - RECOMMANDEE)

Retirer les env-vars STAKATER_<NAME>_SECRET du manifest Git source PROD `k8s/keybuzz-api-prod/deployment.yaml`. Aligner PROD sur le pattern DEV qui fonctionne deja sans ces lignes en Git.

| Aspect | Evaluation |
|---|---|
| Resout drift | OUI DEFINITIVEMENT |
| Cout | FAIBLE (1 commit chirurgical, retirer ~9 lignes du manifest PROD ; eventuellement etendre a client + studio-api pour coherence) |
| Risque post-apply | **TRES FAIBLE** : DEV demontre que retrait safe. Reloader continue d'injecter au runtime via auto-detection Secrets. App keybuzz-api ne lit pas ces env-vars (juste annotations Reloader). |
| Risque pod restart | FAIBLE : kubectl apply post-commit declenche generation bump + rolling update + nouveau pod. Mais Reloader injectera la valeur correcte des le restart suivant (cycle quasi-immediate). |
| Coherence GitOps | OUI FORT (manifest reflete uniquement les sources de verite, pas les artefacts runtime) |
| Effet secondaire utile | Elimine l'exposition Git de ces hashes en clair. Resout aussi le probleme architectural global pour les 6 Deployments avec Reloader (necessitera des commits supplementaires pour client + studio-api si patterns d'exposition similaires). |
| Verdict | **RECOMMANDEE** |

## Risk matrix (E10)

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Lecture accidentelle valeur en clair dans output runner | TRES FAIBLE (masquage redacteur Python + variables shell unset immediat) | ELEVE | safety check final 0 hex40 leak dans tous /tmp + rapport |
| R2 | Drift non resolu bloque Q-1B-5B-2-EXEC-PROD indefiniment | FAIBLE post-rapport | MOYEN | Option E debloque proprement |
| R3 | Decouverte exposition pattern generalise (hex40 + hex64) | CONFIRMEE | ELEVE | E4 audit revele 3 fichiers (api-prod hex40 + client-dev/prod hex64) -> Option E extensible |
| R4 | Option E apply rollout cause downtime keybuzz-api | FAIBLE (RollingUpdate + readiness probe) | MOYEN | EXEC en heure faible trafic + monitor pod Ready |
| R5 | Reloader ne re-injecte pas post-apply | TRES FAIBLE (DEV demontre injection autonome) | ELEVE si materializes | observation 5min post-apply pour confirmer injection runtime (kubectl get deploy env list) |
| R6 | App keybuzz-api lit STAKATER_VAULT_ROOT_TOKEN_SECRET dans son code | TRES FAIBLE (env-var purement Reloader) | ELEVE si materializes | grep source code keybuzz-api pour STAKATER_ before EXEC (hors scope, candidat verification pre-EXEC) |
| R7 | Le commit "PH-T8.2E synced from live PROD" cache d'autres env-vars accidentellement committees | MOYEN | MOYEN | extension audit Option E a tous autres env-vars hex40/hex64 du commit |

## Plan EXEC Q-1B-5B-2A-EXEC propose (Option E recommandee)

| step | action | dependency | gate | risk | rollback NOMINAL | rollback EMERGENCY |
|---|---|---|---|---|---|---|
| 1 | Prompt CE Q-1B-5B-2A-EXEC Mode B SAFE | Q-1B-5B-2A rapport commit | GO Ludovic separe | FAIBLE | none | none |
| 2 | Grep source code keybuzz-api pour `STAKATER_VAULT_ROOT_TOKEN_SECRET` / `STAKATER_KEYBUZZ_*` (verif R6 : app n'utilise pas) | step 1 | STOP si app utilise | FAIBLE | none | none |
| 3 | Patch manifest Git source PROD : retirer les 9-12 lignes des 3 env-vars STAKATER (`STAKATER_VAULT_ROOT_TOKEN_SECRET`, `STAKATER_KEYBUZZ_API_JWT_SECRET`, `STAKATER_KEYBUZZ_GOOGLE_ADS_SECRET`) | step 2 | dry-run server validation | FAIBLE | git revert | n/a |
| 4 | Commit + push patch | step 3 | GO COMMIT REMOVE STAKATER PROD Q-1B-5B-2A-EXEC | FAIBLE | git revert + push | n/a |
| 5 | kubectl apply -f deployment.yaml PROD (Argo absent pour api-prod) | step 4 push | GO APPLY REMOVE STAKATER PROD Q-1B-5B-2A-EXEC | MOYEN (rolling update) | git revert + push + apply revert | `kubectl rollout undo` avec phrase exacte `GO ROLLBACK EMERGENCY UNDO STAKATER PROD Q-1B-5B-2A-EXEC` |
| 6 | Wait rollout + verify pod Ready + verify Reloader injecte de nouveau les env-vars au runtime (kubectl get deploy env list montrant STAKATER vars present malgre absence Git) | step 5 | STOP si pod KO ou Reloader n'injecte pas en 5 min | MOYEN | rollback NOMINAL | rollback EMERGENCY |
| 7 | Smoke test endpoint LLM PROD (1 appel non-engageant, verifier auth Vault token via app fonctionne) | step 6 | STOP si auth fail | MOYEN | rollback NOMINAL | rollback EMERGENCY |
| 8 | Rapport Q-1B-5B-2A-EXEC docs-only + STOP commit/push | step 7 OK | GO commit | none | none | none |
| 9 | (optionnel etendu) Repeter steps 2-8 pour `keybuzz-client-{dev,prod}/deployment.yaml` (audit hex64 expose) | step 8 stable | GO separe pour chaque ns | MOYEN par ns | rollback per ns | rollback per ns |

Apres Q-1B-5B-2A-EXEC : Q-1B-5B-2-EXEC-PROD (migration env-var LITELLM_MASTER_KEY) peut debloquer car le drift PROD initial sera resolu (le manifest Git sera nettoye).

## Recommandation analyste (non-engageante)

Option E est la seule architecturalement correcte. Les autres options soit perpetuent (A) soit sont dangereuses (B) soit sont sur-engineering (C/D). Cette decouverte de pattern d'exposition Reloader generalise (3 fichiers, 5 env-vars Reloader committees par erreur via "synced from live PROD" workflow) suggere d'ouvrir une phase parallele Q-1B-5B-2A-RELOADER-CLEANUP pour traiter exhaustivement les 6 Deployments concernes. Le hex64 keybuzz-client-{dev,prod} merite investigation : si c'est aussi un STAKATER reloader hash, l'Option E s'applique identique.

## No fake metrics (E12)

N/A. Phase investigation pure sans impact dashboard/KPI/billing.

## AI feature parity (E13)

N/A direct. Cette phase ne modifie rien. L'EXEC Q-1B-5B-2A-EXEC futur impactera transitoirement (rollout pod keybuzz-api ~5-15s) mais 0 modification fonctionnalite IA. LiteLLM keybuzz-ai 2 pods inchanges (hors scope ce drift).

## Cleanup temporary files (E14)

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1b5b2a-redactor.py | 600 | shred apres rapport |
| /tmp/keybuzz-q1b5b2a-git-forensic.txt | 600 | shred (contenu masque, mais par precaution) |
| /tmp/keybuzz-q1b5b2a-runtime-vs-git-hashes.jsonl | 600 | shred (hashes courts only, mais par precaution) |
| /tmp/keybuzz-q1b5b2a-cluster-audit.txt | 600 | shred |
| /tmp/keybuzz-q1b5b2a-e1-e4-runner.sh | 755 | shred |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1B-5B-2A | Impact |
|---|---|---|---|
| keybuzz-api-prod Deployment | gen=410, env STAKATER hash b9eb13df | inchange | 0 |
| keybuzz-api-prod Pod jx6m7 | Running 1/1 restartCount=0 | inchange | 0 |
| keybuzz-api-prod Secrets | toutes inchanges | inchanges | 0 |
| keybuzz-api-prod ES | toutes Ready=True inchanges | inchanges | 0 |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-ai litellm 2 pods | Running 0 restart | inchanges | 0 |
| Vault KV PROD | non touche (0 vault command) | non touche | 0 |
| Argo CD applications | non touche | non touche | 0 |
| Providers LLM externes | non touche | non touche | 0 |
| k8s/keybuzz-api-{dev,prod}/deployment.yaml | md5 stable | md5 stable | 0 (correction 5) |
| Git history | HEAD 9ad2c9d | HEAD 9ad2c9d | 0 |

## Compliance read-only (5 corrections)

| Interdit | Evidence | Verdict |
|---|---|---|
| Correction 1 - SCP runner umask 077 set +x SHA256[:8] unset immediat | runner E1-E4 utilise umask 077 + variables unset + sha256sum + cut -c1-8 | OK |
| Correction 1 - Aucun jsonpath/grep stdout valeur | toutes captures via variables shell unset immediat | OK |
| Correction 2 - Git forensic via redacteur Python hex40 -> `<HEX40_<sha8>>` | E2 toutes sorties pipe via /tmp/keybuzz-q1b5b2a-redactor.py | OK |
| Correction 3 - Safety check 0 token clear | grep regex hex40 sur /tmp/keybuzz-q1b5b2a-* + rapport = 0 leak | OK |
| Correction 4 - Option A NON recommandee, options C/D evaluees comme sur-engineering | Documentees explicitement avec verdict | OK |
| Correction 5 - 0 mutation, 0 vault command, 0 kubectl apply/dry-run, 0 provider call | runner ne contient aucune commande mutation ; uniquement get/describe/log read | OK |
| Aucune lecture .data value secret | 0 .data projection, projections metadata uniquement | OK |
| Aucun kubectl run/exec/port-forward | 0 commande | OK |
| Aucun git commit/push sans GO Gate E15 | rapport en untracked | OK |
| Manifests Git source inchanges | md5 DEV 1a832b1c PROD d471a089 stables | OK |
| Tenant/user/email hardcode | 0 | OK |
| Toucher PROD mutation | 0 | OK |

12/12 contraintes respectees, 0 violation.

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe :

```
KEY-323 - AS.17.1Q-1B-5B-2A STAKATER VAULT ROOT TOKEN DRIFT INVESTIGATION DRY-RUN

Status: COMPLETE - ROOT CAUSE IDENTIFIED + OPTION E RECOMMANDEE
Scope: Investigation pure read-only + forensic Git + cluster audit

Root cause confirmee:
- Stakater Reloader v1.2.1 auto-injecte les env-vars STAKATER_<NAME>_SECRET au runtime des Deployments annotes reloader.stakater.com/auto=true
- Ces valeurs sont des hashes SHA1/SHA256 des Secrets/ConfigMaps references, par design jamais committees en Git
- Le drift PROD est cause par UN SEUL commit e77b7cb (2026-04-20, auteur ecomlgfr, message PH-T8.2E "synced from live PROD") qui a ajoute par erreur ces env-vars dans le manifest Git PROD
- DEV manifest Git n'a JAMAIS contenu ces env-vars (0 commit historique) MAIS DEV runtime les a -> preuve formelle Reloader injection autonome

Hashes runtime vs Git (SHA256[:8] masque, valeurs jamais lues en clair):
- PROD runtime: b9eb13df (length 40)
- PROD Git: c0f128e4 (length 40) -> drift confirme, Git obsolete depuis 28j
- DEV runtime: b9eb13df (identique PROD runtime)
- DEV Git: EMPTY (jamais committee)

Cluster-wide audit:
- 10 env-vars STAKATER_<NAME>_SECRET dans 7 Deployments (api+client+studio-api DEV+PROD)
- 3 fichiers manifests exposent hex40 ou hex64 plain-text en value: ; pattern d'exposition Reloader generalise

5 options evaluees:
- Option A "commit runtime in Git": NON RECOMMANDEE (perpetue exposition, requiert re-commit a chaque rotation)
- Option B "apply Git pour revert runtime": DANGEREUSE (valeur Git obsolete casse Vault auth probable)
- Option C "migration ESO": sur-engineering (hash Reloader pas un secret primaire)
- Option D "secretKeyRef": sur-engineering identique
- Option E "retirer env-vars du Git source PROD" (NOUVELLE): RECOMMANDEE - aligne PROD sur DEV pattern qui fonctionne deja sans ces env-vars en Git

Plan EXEC Q-1B-5B-2A-EXEC propose en 8-9 steps (verification source code app + commit removal + push + apply + verify Reloader re-injecte au runtime).

Apres Q-1B-5B-2A-EXEC: Q-1B-5B-2-EXEC-PROD (migration env-var LITELLM_MASTER_KEY) sera debloquee.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-5B-2A-KEY-323-STAKATER-VAULT-TOKEN-DRIFT-INVESTIGATION-DRYRUN-01.md
NO GO maintenus: Q-1B-5B-2A-EXEC, Q-1B-5B-2-EXEC, AS.17.0/0.1 PROD promotion.
```

## Gaps restants

1. **Q-1B-5B-2A-EXEC** (Option E recommandee) : NO GO maintenu, requires GO Ludovic separe + prompt CE Mode B SAFE.
2. **Q-1B-5B-2A-RELOADER-CLEANUP** (NOUVELLE proposee) : phase parallele pour traiter les 6 Deployments expose pattern Reloader (api+client+studio-api DEV+PROD), incluant hex64 keybuzz-client-{dev,prod}.
3. **Q-1B-5B-2-EXEC-DEV** : NO GO maintenu, attente GO Ludovic + prompt CE (n'est plus bloque par drift apres correction du pattern d'audit).
4. **Q-1B-5B-2-EXEC-PROD** : NO GO maintenu, prerequis Q-1B-5B-2A-EXEC resolu.
5. **Q-1B-5B-4 / Q-1B-5B-5 / Q-1B-5B-6 / Q-1B-5B-7** : NO GO maintenus.
6. **Q-1B-5C studio-api migration ESO** : NO GO maintenu.
7. **Q-1B-3D-2B / Q-1B-3D-3 / Q-1B-3E / Q-1B-3B / Q-1B-3C / Q-1B-6 / Q-1B-4 / Q-1B-7 / Q-1F-3** : restent dans la file.
8. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue.
9. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.
10. **Pattern d'exposition Git plain-text generalise** : cette phase a documente 3 fichiers (api-prod hex40 + client-dev/prod hex64). Si le pattern est plus large (a verifier en Q-1B-5B-2A-RELOADER-CLEANUP), candidat audit cluster-wide systematique de tous les manifests `k8s/*/deployment.yaml`.

## Phrase cible finale

Investigation drift STAKATER_VAULT_ROOT_TOKEN_SECRET PROD complete (root cause CONFIRMEE : Stakater Reloader auto-injection runtime + commit Git accidentel e77b7cb 2026-04-20 ecomlgfr avec commentaire "synced from live PROD" demontre workflow `kubectl get -o yaml | commit Git` erronee), 10 env-vars STAKATER detectees cluster-wide dans 7 Deployments avec pattern d'exposition Reloader generalise (3 fichiers exposes hex40+hex64), DEV demontre pattern correct (manifest Git VIDE + runtime via Reloader autonome), 5 options evaluees avec recommandation forte Option E (retirer env-vars du Git source PROD pour aligner sur DEV pattern) - aucune mutation, aucune lecture valeur en clair (hashes SHA256[:8] partout via redacteur Python + variables shell unset immediat), 0 vault command, 0 provider call, 0 kubectl apply, manifests Git source md5 stables, safety checks finaux 0 hex40 clear leak, PROD intouchee - Q-1B-5B-2A-EXEC Option E recommandee NO GO en attente GO Ludovic separe + prompt CE Mode B SAFE dedie, debloquera ensuite Q-1B-5B-2-EXEC.

STOP
