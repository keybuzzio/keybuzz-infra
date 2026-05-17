# PH-WEBSITE-T8.12AS.17.1Q-1B-3D-1-KEY-323-GHCR-NAMING-HARMONIZATION-DRYRUN-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-3D-1
> Environnement : DEV + PROD (read-only)

## VERDICT

GO PARTIEL DESIGN REQUIRED

Inventaire cluster-wide complete sur 16 Secrets de type kubernetes.io/dockerconfigjson, repartis sur 15 namespaces. 15/16 ACTIF_GITOPS (references par 22 workloads + 24 pods Running+Pending + manifests Deployment actifs dans keybuzz-infra/k8s/). 1/16 ORPHAN strict identifie : keybuzz-client-dev/ghcr-secret (0 workload, 0 pod, age 137 jours, plus ancien que le ghcr-cred actif du meme namespace).

Pattern de fait emerge naturellement de la base :
- 11/16 nommes ghcr-cred (microservices backends + workers + Next.js SaaS : api, backend, client, seller, studio, studio-api)
- 5/16 nommes ghcr-secret (frontends public-facing : admin-v2, website + le doublon orphan client-dev)
- Une seule anomalie de doublon strict : keybuzz-client-dev (co-existence ghcr-cred actif + ghcr-secret orphan).

Dette infrastructurelle confirmee : AUCUN manifest GitOps ne CREE les Secrets dockerconfigjson eux-memes (tous crees manuellement via kubectl create secret docker-registry). Les Deployments referencent par nom, mais la source du secret n'est ni dans k8s/ ni dans helm/ ni dans argocd/, ni dans ESO/Vault.

Decision Ludovic requise sur deux dimensions avant EXEC Q-1B-3D-2 :
1. Choix du nom canonique cible (ghcr-pull-secret convention K8s standard / ghcr-cred majoritaire churn moindre / autre).
2. Choix du sequencement (mini-cleanup orphan client-dev immediat zero-risque versus harmonisation pleine 5+ namespaces avec risque image pull pendant rename).

Aucune mutation runtime. Aucun GitOps push. Aucun docker login/pull/push. Aucun base64 decode. Aucune lecture .dockerconfigjson. Aucune rotation PAT GHCR. PROD intouchee.

## Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion | install-v3 / 46.62.171.61 | install-v3 / 46.62.171.61 | OK |
| Repo keybuzz-infra HEAD | descendant e935dd9 (Q-1B-3B-1B) | e935dd9 = HEAD | OK |
| Worktree infra dirty | clean | clean | OK |
| Rapports dependances | 4 PH (Q-1B-3B-1B, Q-1B-3B-1A, Q-1B-3B-0, Q-1B-3A) | 4 OK | OK |
| /tmp residuels Q-1B-3D | absents | absents | OK |
| Workflow SCP runner | impose | applique (E1-E5 + E6-E7 runners) | OK |
| ASCII strict rapport | impose | applique (verif Python local + bastion) | OK |

## Audit signaux

### E1 Inventaire 16 Secrets dockerconfigjson cluster-wide

Methode corrigee per consigne Ludovic : kubectl get secret -A -o json | jq select(.type=="kubernetes.io/dockerconfigjson"). Metadata-only capture (size 4152 bytes, mode 600, 0 .data values, 0 JWT-like base64 detecte).

| ns | count | names_list |
|---|---|---|
| keybuzz-admin-v2-dev | 1 | ghcr-secret |
| keybuzz-admin-v2-prod | 1 | ghcr-secret |
| keybuzz-api-dev | 1 | ghcr-cred |
| keybuzz-api-prod | 1 | ghcr-cred |
| keybuzz-backend-dev | 1 | ghcr-cred |
| keybuzz-backend-prod | 1 | ghcr-cred |
| keybuzz-client-dev | 2 | ghcr-cred, ghcr-secret |
| keybuzz-client-prod | 1 | ghcr-cred |
| keybuzz-seller-dev | 1 | ghcr-cred |
| keybuzz-studio-api-dev | 1 | ghcr-cred |
| keybuzz-studio-api-prod | 1 | ghcr-cred |
| keybuzz-studio-dev | 1 | ghcr-cred |
| keybuzz-studio-prod | 1 | ghcr-cred |
| keybuzz-website-dev | 1 | ghcr-secret |
| keybuzz-website-prod | 1 | ghcr-secret |

### E2 imagePullSecrets references depuis Deployments (22 workloads)

| ns | kind | workload | pull_secret_names |
|---|---|---|---|
| keybuzz-admin-v2-dev | deploy | keybuzz-admin-v2 | ghcr-secret |
| keybuzz-admin-v2-prod | deploy | keybuzz-admin-v2 | ghcr-secret |
| keybuzz-api-dev | deploy | keybuzz-api | ghcr-cred |
| keybuzz-api-dev | deploy | keybuzz-outbound-worker | ghcr-cred |
| keybuzz-api-prod | deploy | keybuzz-api | ghcr-cred |
| keybuzz-api-prod | deploy | keybuzz-outbound-worker | ghcr-cred |
| keybuzz-backend-dev | deploy | amazon-items-worker | ghcr-cred |
| keybuzz-backend-dev | deploy | amazon-orders-worker | ghcr-cred |
| keybuzz-backend-dev | deploy | keybuzz-backend | ghcr-cred |
| keybuzz-backend-prod | deploy | amazon-items-worker | ghcr-cred |
| keybuzz-backend-prod | deploy | amazon-orders-worker | ghcr-cred |
| keybuzz-backend-prod | deploy | keybuzz-backend | ghcr-cred |
| keybuzz-client-dev | deploy | keybuzz-client | ghcr-cred |
| keybuzz-client-prod | deploy | keybuzz-client | ghcr-cred |
| keybuzz-seller-dev | deploy | seller-api | ghcr-cred |
| keybuzz-seller-dev | deploy | seller-client | ghcr-cred |
| keybuzz-studio-api-dev | deploy | keybuzz-studio-api | ghcr-cred |
| keybuzz-studio-api-prod | deploy | keybuzz-studio-api | ghcr-cred |
| keybuzz-studio-dev | deploy | keybuzz-studio | ghcr-cred |
| keybuzz-studio-prod | deploy | keybuzz-studio | ghcr-cred |
| keybuzz-website-dev | deploy | keybuzz-website | ghcr-secret |
| keybuzz-website-prod | deploy | keybuzz-website | ghcr-secret |

Aucun StatefulSet, DaemonSet, CronJob, ni Job ne reference d'imagePullSecret (0 ligne).

### E3 imagePullSecrets references depuis Pods Running+Pending

24 pods comptes, 15 paires (ns, secret) uniques. Couverture coherente avec E2 (chaque Deployment a au moins 1 Pod actif). Aucune divergence Pod vs workload parent detectee.

### E4 ServiceAccounts imagePullSecrets

0 ServiceAccount avec imagePullSecrets dans le cluster (verif sur tous namespaces). Heritage automatique non utilise dans KeyBuzz. La consommation est exclusivement explicite par Deployment.

### E5 Manifests GitOps grep (k8s/ + helm/ + argocd/)

| metric | valeur |
|---|---|
| total lignes matchees | 69 |
| lignes dans fichiers actifs (hors .bak/.backup/.disabled) | 51 |
| backup files matchant | 0 visible dans active set (filtre OK) |
| references ghcr-cred (heuristique) | 24 |
| references ghcr-secret (heuristique) | 12 |
| manifests qui CREENT un Secret dockerconfigjson | 0 |

**Fichiers backups dette identifies** (presents mais hors active set):
- keybuzz-seller-dev/deployment-api.yaml.bak
- keybuzz-client-dev/deployment.yaml.bak-golden
- keybuzz-client-dev/deployment.yaml.bak-golden-v2
- keybuzz-api-dev/deployment.yaml.bak-golden
- keybuzz-api-dev/deployment.yaml.backup
- keybuzz-admin-dev/deployment.yaml.disabled
- keybuzz-admin-dev/deployment.yaml.backup_20251217124637

Ces fichiers contiennent des references ghcr-* mais ne participent pas a la classification ACTIF (filtre applique). A traiter dans un nettoyage GitOps separe.

### E5.3 + E5.4 Cross-checks runtime <-> manifest

| Verification | Resultat |
|---|---|
| Secret manifest-referenced mais absent runtime | 0 |
| Secret runtime mais aucune source GitOps Deployment | 0 (chaque secret a au moins 1 manifest Deployment qui le reference par nom) |
| Manifest creant un Secret dockerconfigjson (kind: Secret + type: kubernetes.io/dockerconfigjson) | 0 (creation 100% manuelle) |

## Classification finale

| ns | secret_name | type | age_days | rv | dockerconfig_size_b64 | classification | manifest_active_refs | reasoning_short |
|---|---|---|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | ghcr-secret | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 6 | wl=1 pod=1 |
| keybuzz-admin-v2-prod | ghcr-secret | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 6 | wl=1 pod=1 |
| keybuzz-api-dev | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=2 pod=2 |
| keybuzz-api-prod | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=2 pod=2 |
| keybuzz-backend-dev | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=3 pod=4 |
| keybuzz-backend-prod | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=3 pod=3 |
| keybuzz-client-dev | ghcr-cred | dockerconfigjson | 56 | 41700540 | 272 | ACTIF_GITOPS | 21 | wl=1 pod=1, recent |
| keybuzz-client-dev | ghcr-secret | dockerconfigjson | 137 | 5877360 | 276 | ORPHAN | 6 (autres ns) | wl=0 pod=0, fossile |
| keybuzz-client-prod | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=1 pod=1 |
| keybuzz-seller-dev | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=2 pod=2 |
| keybuzz-studio-api-dev | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=1 pod=1 |
| keybuzz-studio-api-prod | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=1 pod=1 |
| keybuzz-studio-dev | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=1 pod=1 |
| keybuzz-studio-prod | ghcr-cred | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 21 | wl=1 pod=1 |
| keybuzz-website-dev | ghcr-secret | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 6 | wl=1 pod=1 |
| keybuzz-website-prod | ghcr-secret | dockerconfigjson | n/a | n/a | n/a | ACTIF_GITOPS | 6 | wl=1 pod=2 |

Note : "manifest_active_refs" est un compteur d'occurences textuelles dans tous les fichiers actifs (la convention nominale identique cross-ns gonfle le compteur ; la verite "ACTIF" derive de wl+pod refs, pas de manifest_active_refs).

## Zoom diff client-dev ghcr-cred vs ghcr-secret

| field | ghcr-cred | ghcr-secret | diff_verdict |
|---|---|---|---|
| type | kubernetes.io/dockerconfigjson | kubernetes.io/dockerconfigjson | identique |
| created | 2026-03-22T11:14:08Z | 2025-12-31T12:28:10Z | ghcr-secret plus ancien |
| age (jours) | 56 | 137 | delta 81 jours |
| resourceVersion | 41700540 | 5877360 | rv ghcr-cred plus recent (cluster a evolue) |
| labels count | 0 | 0 | identiques (aucun) |
| annotations count | 0 | 0 | identiques (aucun) |
| ownerReferences | [] | [] | identiques (none, creation manuelle) |
| key_names | [.dockerconfigjson] | [.dockerconfigjson] | identiques |
| key_count | 1 | 1 | identiques |
| dockerconfig_size base64 | 272 | 276 | delta 4 bytes (taille comparable, PAT probable identique ou tres proche, mais NON decode/compare ici) |
| workload references | 1 (keybuzz-client deploy) | 0 | ghcr-cred ACTIF, ghcr-secret ORPHAN |
| pod references Running+Pending | 1 (keybuzz-client pod) | 0 | ghcr-cred ACTIF, ghcr-secret ORPHAN |

**Heuristique de seniorite resolutive** :
- ghcr-secret (137d) = fossile de la convention ancienne (alignee avec admin-v2 + website).
- ghcr-cred (56d) = aligne sur la convention majoritaire backends/microservices, cree probablement lors d'une normalisation manuelle non documentee de keybuzz-client-dev pour conformer a api/backend/seller/studio.

**Verdict zoom** : ghcr-cred = ACTIF unique de keybuzz-client-dev. ghcr-secret = ORPHAN strict, candidat suppression immediate zero-risque (pattern identique a Q-1B-3B-1B : 0 reference cluster-wide).

## Mapping harmonisation propose

Trois options pour le nom canonique cible. Decision Ludovic bloquante.

### Option A : ghcr-pull-secret (convention K8s standard)

| ns | current_names | proposed_canonical | action_per_secret | total_renames |
|---|---|---|---|---|
| keybuzz-admin-v2-dev | ghcr-secret | ghcr-pull-secret | RENAME | 1 |
| keybuzz-admin-v2-prod | ghcr-secret | ghcr-pull-secret | RENAME | 1 |
| keybuzz-api-dev | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-api-prod | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-backend-dev | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-backend-prod | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-client-dev | ghcr-cred, ghcr-secret | ghcr-pull-secret | RENAME ghcr-cred + DELETE ghcr-secret | 2 |
| keybuzz-client-prod | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-seller-dev | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-studio-api-dev | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-studio-api-prod | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-studio-dev | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-studio-prod | ghcr-cred | ghcr-pull-secret | RENAME | 1 |
| keybuzz-website-dev | ghcr-secret | ghcr-pull-secret | RENAME | 1 |
| keybuzz-website-prod | ghcr-secret | ghcr-pull-secret | RENAME | 1 |

Total : 16 secrets touches, 15 manifests Deployment patches (1 par ns + 0 supplementaire pour client-dev car le delete du orphan ne modifie pas le manifest), 14 rollouts requis DEV+PROD melanges (6 DEV-only seraient acceptables sans GO, 8 PROD necessiteraient GO Ludovic).

### Option B : ghcr-cred (majoritaire 11/16, churn moindre)

| ns | current_names | proposed_canonical | action_per_secret | total_renames |
|---|---|---|---|---|
| keybuzz-admin-v2-dev | ghcr-secret | ghcr-cred | RENAME | 1 |
| keybuzz-admin-v2-prod | ghcr-secret | ghcr-cred | RENAME | 1 |
| keybuzz-website-dev | ghcr-secret | ghcr-cred | RENAME | 1 |
| keybuzz-website-prod | ghcr-secret | ghcr-cred | RENAME | 1 |
| keybuzz-client-dev | ghcr-cred, ghcr-secret | ghcr-cred | DELETE ghcr-secret seulement | 1 |
| (11 autres ns) | ghcr-cred | ghcr-cred | KEEP_AS_IS | 0 |

Total : 5 secrets touches, 4 manifests Deployment patches (admin-v2-dev, admin-v2-prod, website-dev, website-prod), 4 rollouts requis (2 DEV + 2 PROD), 1 simple delete orphan client-dev.

### Option C : Mini-cleanup seul + Status quo

Suppression de l'unique ORPHAN keybuzz-client-dev/ghcr-secret. Aucun rename. Tous les autres secrets gardent leur nom actuel. Convention divergente acceptee comme dette structurelle a faible cout d'usage.

Total : 1 secret touche (delete), 0 manifest patche, 0 rollout, 0 risque image pull.

## Decision matrix consolidee

Table operationnelle directe pour Q-1B-3D-2 selon option retenue.

| ns | secret_name | classification | action_option_A | action_option_B | action_option_C | dependent_workloads | rollout_restart_required_A | rollout_restart_required_B | risk_level_A | risk_level_B | rollback_plan |
|---|---|---|---|---|---|---|---|---|---|---|---|
| keybuzz-admin-v2-dev | ghcr-secret | ACTIF_GITOPS | RENAME_TO_CANONICAL | RENAME_TO_GHCR-CRED | KEEP | keybuzz-admin-v2 | OUI | OUI | MOYEN | MOYEN | redeposer ancien secret + rollback manifest |
| keybuzz-admin-v2-prod | ghcr-secret | ACTIF_GITOPS | RENAME_TO_CANONICAL | RENAME_TO_GHCR-CRED | KEEP | keybuzz-admin-v2 | OUI | OUI | ELEVE (PROD) | ELEVE (PROD) | idem + GO Ludovic obligatoire |
| keybuzz-api-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-api + keybuzz-outbound-worker | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-api-prod | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-api + keybuzz-outbound-worker | OUI | NON | ELEVE (PROD) | NEANT | idem + GO Ludovic |
| keybuzz-backend-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-backend + amazon-items-worker + amazon-orders-worker | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-backend-prod | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | 3 workloads PROD | OUI | NON | ELEVE (PROD) | NEANT | idem + GO Ludovic |
| keybuzz-client-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-client | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-client-dev | ghcr-secret | ORPHAN | DELETE_ORPHAN | DELETE_ORPHAN | DELETE_ORPHAN | (aucun) | NON | NON | FAIBLE | FAIBLE | recreer manuellement si Ludovic conserve backup PAT |
| keybuzz-client-prod | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-client | OUI | NON | ELEVE (PROD) | NEANT | idem + GO Ludovic |
| keybuzz-seller-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | seller-api + seller-client | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-studio-api-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-studio-api | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-studio-api-prod | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-studio-api | OUI | NON | ELEVE (PROD) | NEANT | idem + GO Ludovic |
| keybuzz-studio-dev | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-studio | OUI | NON | MOYEN | NEANT | redeposer + rollback |
| keybuzz-studio-prod | ghcr-cred | ACTIF_GITOPS | RENAME_TO_CANONICAL | KEEP | KEEP | keybuzz-studio | OUI | NON | ELEVE (PROD) | NEANT | idem + GO Ludovic |
| keybuzz-website-dev | ghcr-secret | ACTIF_GITOPS | RENAME_TO_CANONICAL | RENAME_TO_GHCR-CRED | KEEP | keybuzz-website | OUI | OUI | MOYEN | MOYEN | redeposer + rollback |
| keybuzz-website-prod | ghcr-secret | ACTIF_GITOPS | RENAME_TO_CANONICAL | RENAME_TO_GHCR-CRED | KEEP | keybuzz-website | OUI | OUI | ELEVE (PROD) | ELEVE (PROD) | idem + GO Ludovic |

## Risques harmonisation

| ID | Risque | Mitigation |
|----|--------|------------|
| R1 | Image pull failure pendant la fenetre rename : Pod en ImagePullBackOff si Deployment patche avant que le nouveau Secret existe | Pattern "create new secret first (avec le meme .dockerconfigjson) -> apply manifest patche -> rollout restart -> verifier Running -> delete ancien secret" - jamais rename atomique |
| R2 | Pod evicte sans secret valide -> downtime PROD jusqu'au redeploy | Sequence DEV avant PROD obligatoire. Pour chaque PROD : GO Ludovic explicite + ImagePullBackOff watcher 5min minimum + rollback documented |
| R3 | ServiceAccount imagePullSecret heritage modifie sans rollout pods existants | N/A confirme E4 : 0 SA avec imagePullSecrets dans le cluster, heritage non utilise |
| R4 | Suppression d'un DOUBLON_STRICT avant verification CronJob non-triggere | N/A : 0 CronJob/Job avec imagePullSecrets dans tout le cluster (verif E2) |
| R5 | Modification manuelle (ACTIF_MANUAL) drift permanent vs GitOps | Confirme : 0/16 Secret dockerconfigjson est cree via GitOps. Toute creation/rename necessite documentation post-action dans rapport PH + ajout d'une ressource ESO ou Helm chart pour cloturer la dette structurelle (hors scope Q-1B-3D-2, candidat Q-1B-3D-3) |
| R6 | Backup files .yaml.bak/.disabled/.backup contiennent des references obsoletes induisant en erreur les grep futurs | A nettoyer dans une phase Q-1B-3D-4 separee (purge GitOps backup files keybuzz-infra/k8s/) |
| R7 | Rotation PAT GHCR future (Q-1B-3D-5 hypothetique) necessitera patch + rollout des 16 secrets simultanement | Hors scope Q-1B-3D-1. Recommandation : aligner les noms en Q-1B-3D-2 AVANT la rotation PAT pour reduire la surface manipulee |

## Plan EXEC Q-1B-3D-2 propose (NON execute)

### Variante 1 : Mini-cleanup orphan client-dev (option C ou pre-requis A/B)

Phase atomique zero-risque type Q-1B-3B-1B :

| step | action | dependency | gate | risk | rollback |
|---|---|---|---|---|---|
| 1 | E0 PREFLIGHT bastion + HEAD + clean | rapport Q-1B-3D-1 commit + push | STOP si non-aligne | FAIBLE | none |
| 2 | E1 BEFORE metadata-only snapshot (mode 600) | E0 | safety check no .data values | FAIBLE | snapshot a shred apres rapport |
| 3 | E2 Re-verify orphan status (0 workload + 0 pod + 0 GitOps active + 0 source code) | E1 | STOP Gate 1 phrase exacte "GO DELETE 1 ORPHAN GHCR Q-1B-3D-2-MINI" | NEANT | none |
| 4 | E3 kubectl delete secret ghcr-secret -n keybuzz-client-dev | E2 + phrase | FAIBLE (ORPHAN confirme) | IRRECUPERABLE local | reconstruction via PAT GHCR si Ludovic backup |
| 5 | E4 Verify NotFound + 0 ImagePullBackOff sur keybuzz-client pod | E3 | rapport docs-only | NEANT | recreate secret si urgence |
| 6 | E5 Rapport PH + STOP commit/push | E4 | GO Ludovic separe pour commit | none | none |

### Variante 2 : Harmonisation option A (ghcr-pull-secret) ou B (ghcr-cred)

Sequence par namespace, DEV strictement avant PROD :

| step | action | dependency | gate | risk | rollback |
|---|---|---|---|---|---|
| 1 | Mini-cleanup orphan (Variante 1) | aucune | GO Ludovic Mini | FAIBLE | covered above |
| 2 | Choix nom canonique definitif | mini-cleanup OK | GO Ludovic produit (A / B / autre) | none | none |
| 3 | Preparer patch manifests GitOps : pour chaque ns DEV (admin-v2-dev, website-dev en option B ; +9 autres en option A), modifier `imagePullSecrets: [name: <new>]` dans deployment.yaml | step 2 | review diff complet + GO Ludovic AVANT push | FAIBLE pour preparation | git revert simple |
| 4 | Pour chaque ns DEV (sequentiel, 1 ns a la fois) : creer Secret <new_name> via kubectl create secret docker-registry avec le meme .dockerconfigjson (extrait offline du Secret existant via kubectl get -o yaml | mais sans logger la sortie). Verifier que le nouveau Secret existe. | step 3 | STOP intra-step si erreur creation | FAIBLE (additif) | kubectl delete secret <new_name> |
| 5 | Pour le meme ns DEV : git commit + push manifests Deployment patche. Verifier que ArgoCD sync ou kubectl apply -f. | step 4 | STOP si sync diff > attendu | MOYEN (rollout pending) | git revert manifest + rollout undo |
| 6 | Verifier rollout : kubectl rollout status + ImagePullBackOff watcher 5min. Si OK, kubectl delete secret <ancien_name>. | step 5 | STOP si pod KO | MOYEN | recreate ancien secret + rollback manifest |
| 7 | Rapport intermediaire PH-Q-1B-3D-2-DEV-<ns>-01.md, commit + push apres GO Ludovic | step 6 | GO Ludovic | none | none |
| 8 | Repeter steps 4-7 pour chaque ns DEV restant | step 7 | GO per ns | MOYEN cumule | DEV recoverable |
| 9 | Apres TOUS les DEV stables 24h+, GO Ludovic explicite pour PROD | step 8 + monitoring | GO Ludovic PROD-promote | ELEVE | DEV serve de validation |
| 10 | Repeter steps 4-7 pour chaque ns PROD (sequentiel, monitoring renforce, rollback pret) | step 9 | GO per PROD ns | ELEVE | rollback per ns immediat |
| 11 | Rapport final Q-1B-3D-2 + cloture dette si plan converge | step 10 | GO commit/push | none | none |

### Recommandation analyste (non-engageante)

L'option C (mini-cleanup orphan seul) clot la moitie du probleme (la doublon strict) sans risque ni churn, et permet de differer la decision sur le nom canonique. L'option A (ghcr-pull-secret) est la plus propre semantiquement mais coute 16 renames + 14 rollouts dont 8 PROD. L'option B (ghcr-cred) est le meilleur ratio cout/benefice si Ludovic accepte ghcr-cred comme convention de fait : 5 secrets touches + 4 rollouts dont 2 PROD.

Une voie hybride pragmatique : executer C immediatement (zero-risque), puis ouvrir Q-1B-3D-3 pour la dette structurelle "creer manifests Secret dockerconfigjson via Helm ou ESO pour eliminer la dependance kubectl create", puis seulement ensuite, si Ludovic juge le rename utile, executer B en post-rotation PAT GHCR (Q-1B-3D-5).

## No fake metrics

N/A. Phase inventaire + decision matrix sans impact dashboard, KPI, billing, acquisition, reporting, tracking. Aucune metrique creee. Aucun event GA4/CAPI/TikTok/LinkedIn.

## AI feature parity

N/A. Phase cleanup K8s registry credentials. Ne touche ni l'IA, ni l'Inbox, ni les messages, ni les connecteurs marketplace au runtime, ni les commandes, ni le tracking colis, ni les playbooks, ni les escalades, ni l'Agent KeyBuzz, ni l'autopilot, ni le dashboard, ni les metriques derivees. Aucune cle API LLM, aucun appel LiteLLM. (Note : la rotation PAT GHCR future devra rollout les pods et impactera transitoirement la disponibilite, mais cette phase ne touche pas les pods.)

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres | Impact |
|---|---|---|---|
| keybuzz-api-prod | non touche | non touche | 0 |
| keybuzz-backend-prod | non touche | non touche | 0 |
| keybuzz-client-prod | non touche | non touche | 0 |
| keybuzz-admin-v2-prod | non touche | non touche | 0 |
| keybuzz-studio-prod | non touche | non touche | 0 |
| keybuzz-studio-api-prod | non touche | non touche | 0 |
| keybuzz-website-prod | non touche | non touche | 0 |
| GHCR registry (ghcr.io/keybuzzio) | non touche | non touche | 0 |
| Vault KV PROD | non touche | non touche | 0 |
| ESO ClusterSecretStores | non touche | non touche | 0 |
| Argo CD applications | non touche | non touche | 0 |
| GitHub PAT GHCR | non touche | non touche | 0 |

Aucune commande mutation executee dans aucun namespace. Aucun GitOps push. Aucun docker login/pull/push. Aucune lecture de .dockerconfigjson decode.

## Linear

Aucun changement de statut KEY-323. Aucun commentaire engageant prepare ni poste. KEY-323 reste OPEN avec le commit Q-1B-3B-1B (e935dd9) comme dernier livrable cloture. Commit/push rapport Q-1B-3D-1 en attente de GO Ludovic explicite (E16).

## Gaps restants

1. **Q-1B-3D-2 EXEC** : NO GO maintenu, requiert decision Ludovic sur option A/B/C + sequence.
2. **Q-1B-3D-3 (proposee nouvelle)** : creation des Secrets dockerconfigjson via Helm chart ou ESO pour cloturer la dette "100% creation manuelle". Hors scope Q-1B-3D-1.
3. **Q-1B-3D-4 (proposee nouvelle)** : purge des backup files keybuzz-infra/k8s/ (.bak, .backup, .disabled, .bak-golden, .bak-golden-v2, .backup_<ts>) qui polluent les grep et induisent des risques de drift. Hors scope.
4. **Q-1B-3D-5 (Rotation PAT GHCR)** : NO GO maintenu, requiert harmonisation prealable Q-1B-3D-2 pour reduire la surface.
5. **Q-1B-5A LLM SECRETS DEDUP DRY-RUN** : prerequis a Q-1B-5B rotation LLM. 3 secrets litellm distincts a clarifier (keybuzz-litellm, keybuzz-litellm-secrets, litellm-secret).
6. **Q-1B-3E-inbound-webhook MIGRATION ESO PROD** : divergence DEV(ESO) / PROD(manual).
7. **Q-1B-3B PROVIDER LOW-RISK** : Stripe TEST + SES + Slack + Ads sub-batched.
8. **Q-1B-3C OAUTH LOGIN, Q-1B-6 MARKETPLACE OAUTH, Q-1B-4 INFRA DIRECT, Q-1B-5B LLM ROTATION, Q-1B-7 ADS-ENCRYPTION STRATEGIC DESIGN, Q-1F-3 VALIDATION CUMULEE** restent dans la file.
9. **AS.17.0 / AS.17.0.1 PROD PROMOTION** : NO GO maintenu tant que tenantGuardPlugin INACTIF (KEY-301 AS.3) non patche.
10. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.

## Phrase cible finale

Inventaire GHCR cluster-wide complete sur 15 namespaces (16 secrets dockerconfigjson recenses, 1 orphan strict identifie keybuzz-client-dev/ghcr-secret, 0 doublon ailleurs, convention de fait majoritaire ghcr-cred 11/16 vs ghcr-secret 5/16), plan d'harmonisation propose avec 3 options A/B/C et sequencement EXEC Q-1B-3D-2 documente - aucune mutation runtime, aucun GitOps push, aucun GHCR PAT rotation, PROD intouchee - EXEC reste NO GO en attente decision Ludovic explicite sur nom canonique et sequence.

STOP
