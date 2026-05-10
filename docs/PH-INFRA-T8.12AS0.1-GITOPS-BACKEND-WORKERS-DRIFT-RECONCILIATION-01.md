# PH-INFRA-T8.12AS0.1-GITOPS-BACKEND-WORKERS-DRIFT-RECONCILIATION-01 - Reconciliation des drifts GitOps residuels Backend Amazon workers

> Date : 2026-05-10
> Linear : KEY-299 (lie a KEY-295/KEY-297 pour reconciliation principale, KEY-298 strategie restartedAt long terme, KEY-300 dette future tracking visibility + worker resilience merge)
> Phase : reconciliation GitOps - alignement manifest sur runtime live pour 6 workers Backend, sans rollout fonctionnel
> Environnement : bastion install-v3 + clusters DEV + PROD
> Type : reconciliation declarative + correction de manifests obsoletes

## VERDICT

GO RECONCILED - DRIFT RESOLVED - NO ROLLOUT - GLOBAL SCAN CLEAN

Les 6 deployments residuels (amazon-items-worker DEV+PROD, amazon-orders-worker DEV+PROD, backfill-scheduler DEV+PROD) sont maintenant alignes : runtime image = manifest image = last-applied image. Aucun pod n'a ete recree (meme pod_name, meme imageID, meme restart_total avant/apres). Les 6 manifests Git ont ete corriges pour refleter les images runtime validees par les rapports PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02 (workers Amazon) et PH-TD-02 (scheduler).

Le scan global final sur tous les Deployments KeyBuzz (10 namespaces) confirme `Total drift: 0`.

API DEV/PROD, Client DEV/PROD, OW DEV/PROD, Backend principal DEV/PROD, Website, Admin restent strictement inchanges.

## 1. Origine de l'incident

Le preflight de la reprise PH-SAAS-T8.12AS.1 (escalation proactive notifications) post-KEY-297 a revele 6 drifts residuels que les phases precedentes n'avaient pas couverts (le scan KEY-295/KEY-297 ciblait des deployments specifiques) :

| Service | runtime image avant action | last-applied image avant action | drift |
|---|---|---|---|
| backend-dev/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.34-ph263 | environ 6 versions |
| backend-dev/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.34-ph263 | environ 6 versions |
| backend-dev/backfill-scheduler | v1.0.42-td02-worker-resilience-dev | v1.0.41-ph263b-scheduler-dev | 1 version |
| backend-prod/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.34-ph263 | environ 6 versions |
| backend-prod/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.34-ph263 | environ 6 versions |
| backend-prod/backfill-scheduler | v1.0.42-td02-worker-resilience-prod | v1.0.41-ph263b-scheduler-prod | 1 version |

Cas particulier : pour les 4 workers Amazon DEV+PROD, le **manifest Git** etait aussi different du **runtime image** (manifest = v1.0.41-ph263b-scheduler, runtime = v1.0.40-amz-tracking-visibility-backfill ou v1.0.42-td02-worker-resilience). Apply direct du manifest aurait declenche un rollout fonctionnel non desire (rollback vers une image anterieure).

## 2. Audit lecture seule (source-of-truth des images)

### Chronologie reconstitute

| Date | Phase | Commit infra | Image cible | Workers concernes |
|---|---|---|---|---|
| 2026-03-05 | PH26.3B Amazon Backfill Hyperscalable - Scheduler + Fairness | 2dcea27 (DEV), 2e97e75 (PROD) - GitOps clean | v1.0.41-ph263b-scheduler-{dev,prod} | items, orders, scheduler (les 3) |
| 2026-03-15 | PH-TD-02 Worker Resilience | rapport docs uniquement, pas de gitops sur manifests workers | v1.0.42-td02-worker-resilience-{dev,prod} | scheduler (et possiblement workers si appliques via kubectl set image) |
| 2026-03-23 | PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02 | rapport docs, commit backend 12b6aa9, pas de gitops sur manifests workers | v1.0.40-amz-tracking-visibility-backfill-{dev,prod} | items + orders (re-promu apres TD-02, ecrasant la resilience sur les workers) |
| 2026-04-10 | rollout supplementaire | (pods amazon workers recrees, meme image) | idem | items + orders |

Conclusion : depuis PH26.3B (5 mars), aucun commit GitOps n'a touche les manifests workers Backend. Les promotions TD-02 et TRACKING-VISIBILITY-BACKFILL ont ete appliquees au runtime via une voie autre que `kubectl apply -f` depuis le bastion (probablement `kubectl set image`).

### Images recommandees (runtime live valide par rapports)

| Deployment | Image recommandee | Rapport validant | Confiance |
|---|---|---|---|
| backend-dev/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-dev | PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02 | HAUTE |
| backend-dev/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-dev | idem | HAUTE |
| backend-dev/backfill-scheduler | v1.0.42-td02-worker-resilience-dev | PH-TD-02 | HAUTE |
| backend-prod/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02 | HAUTE |
| backend-prod/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | idem | HAUTE |
| backend-prod/backfill-scheduler | v1.0.42-td02-worker-resilience-prod | PH-TD-02 | HAUTE |

## 3. Preflight bastion

| Element | Etat avant action |
|---|---|
| Repo bastion `keybuzz-infra` | clean, aligne origin/main HEAD `0082c09` (post KEY-297) |
| `git remote -v` | `https://github.com/keybuzzio/keybuzz-infra.git` (sans token, post KEY-296) |
| `git status --short` | (clean) |
| `git rev-list --left-right --count origin/main...HEAD` | `0 0` |
| keybuzz-api repo | branche `ph147.4/source-of-truth`, HEAD `0e26bfc3`, clean (sauf `dist/`) |
| keybuzz-client repo | branche `ph148/onboarding-activation-replay`, HEAD `0a7306a`, clean |
| keybuzz-backend repo | branche `main`, HEAD `c62f376`, untracked `.bak` pre-existant (hors scope) |
| 6 manifests cibles localises | OK |

## 4. Snapshot pre-action

| Service | runtime image | last-applied | imageID (pod digest) | pod name | restart_total |
|---|---|---|---|---|---|
| backend-dev/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.34-ph263 | sha256:bd299dd2... | amazon-items-worker-5d78cd99c7-p7tj7 | 2 |
| backend-dev/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.34-ph263 | sha256:bd299dd2... | amazon-orders-worker-7988c9c6cb-qprmt | 4 |
| backend-dev/backfill-scheduler | v1.0.42-td02-worker-resilience-dev | v1.0.41-ph263b-scheduler-dev | sha256:a6b821e1... | backfill-scheduler-8654c9f646-n9chk | 0 |
| backend-prod/amazon-items-worker | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.34-ph263 | sha256:972476dc... | amazon-items-worker-8554cc9cf9-md72c | 0 |
| backend-prod/amazon-orders-worker | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.34-ph263 | sha256:972476dc... | amazon-orders-worker-5f4947c457-dq2xk | 4 |
| backend-prod/backfill-scheduler | v1.0.42-td02-worker-resilience-prod | v1.0.41-ph263b-scheduler-prod | sha256:3d3f8159... | backfill-scheduler-65dd74c776-94l8w | 0 |

## 5. Modifications appliquees aux 6 manifests (alignement minimal sur runtime)

### 5.1 Manifests DEV - 1 modif chacun (CRLF preserves)

| Fichier | Changement |
|---|---|
| `k8s/keybuzz-backend-dev/deployment-amazon-items-worker.yaml` | image v1.0.41-ph263b-scheduler-dev -> v1.0.40-amz-tracking-visibility-backfill-dev ; command `[node, -e, <inline>]` -> `[node, dist/workers/itemsWorkerResilient.js]` (suppression bloc inline 7 lignes) |
| `k8s/keybuzz-backend-dev/deployment-amazon-orders-worker.yaml` | image idem ; command `[node, -e, <inline>]` -> `[node, dist/workers/ordersWorkerResilient.js]` |
| `k8s/keybuzz-backend-dev/deployment-backfill-scheduler.yaml` | image v1.0.41-ph263b-scheduler-dev -> v1.0.42-td02-worker-resilience-dev (+ commentaire rollback) |

### 5.2 Manifests PROD - modifs chirurgicales (LF)

| Fichier | Changement |
|---|---|
| `k8s/keybuzz-backend-prod/amazon-items-worker-deployment.yaml` | image v1.0.41-ph263b-scheduler-prod -> v1.0.40-amz-tracking-visibility-backfill-prod (+ rollback) ; command `[node, -e]` -> `[node, dist/workers/itemsWorkerResilient.js]` (args inline conserve) ; env DATABASE_URL deplace du debut a la fin du bloc env (alignement ordre runtime) ; suppression `spec.template.metadata.creationTimestamp: null` (artefact dump) |
| `k8s/keybuzz-backend-prod/amazon-orders-worker-deployment.yaml` | idem avec `ordersWorkerResilient.js` |
| `k8s/keybuzz-backend-prod/deployment-backfill-scheduler.yaml` | image v1.0.41-ph263b-scheduler-prod -> v1.0.42-td02-worker-resilience-prod (+ rollback) |

### 5.3 Champs strictement non modifies (par construction)

Pour les 6 manifests : selector, replicas, strategy, template.metadata.labels, container.name, livenessProbe, readinessProbe, resources, imagePullSecrets, restartPolicy, dnsPolicy, schedulerName, securityContext, terminationGracePeriodSeconds, terminationMessagePath, terminationMessagePolicy.

### 5.4 Validation YAML post-modifs

Tous les 6 manifests reparses (yaml.safe_load_all) avec succes apres modification :
- DEV items : doc[0]=Deployment (image=v1.0.40-amz-tracking-visibility-backfill-dev), doc[1]=ConfigMap (preserve)
- DEV orders : doc[0]=Deployment, doc[1]=ConfigMap (preserve)
- DEV scheduler : doc[0]=Deployment
- PROD items : doc[0]=Deployment (env order: VAULT_TOKEN, VAULT_ADDR, NODE_ENV, WORKER_TYPE, DATABASE_URL)
- PROD orders : idem
- PROD scheduler : doc[0]=Deployment

### 5.5 Integrite line endings

| Manifest | line ending pre-action | line ending post-action |
|---|---|---|
| DEV items | CRLF (86/87 lignes) | CRLF (79/79 lignes - 100%) |
| DEV orders | CRLF (87/88 lignes) | CRLF (81/81 lignes - 100%) |
| DEV scheduler | LF | LF |
| PROD items | LF | LF |
| PROD orders | LF | LF |
| PROD scheduler | LF | LF |

Note : un sed precedent avait converti la ligne `image:` des 2 manifests DEV de CRLF a LF. Cette phase a restaure le CRLF sur la ligne image, retablissant 100% d'homogeneite CRLF dans ces fichiers.

## 6. kubectl diff -f post-modifs (lecture seule, pre-apply)

| Manifest | kubectl diff |
|---|---|
| DEV items | EMPTY |
| DEV orders | EMPTY |
| DEV scheduler | EMPTY |
| PROD items | metadata-only (deployment.kubernetes.io/revision 27 -> 1, generation 27 -> 28, last-applied-configuration) |
| PROD orders | idem |
| PROD scheduler | EMPTY |

Aucun diff applicatif (command, args, env, envFrom, image, resources, probes, selector, labels, replicas, strategy) sur aucun des 6 manifests. Conforme aux conditions du prompt KEY-299 : `vide ou strictement metadata/last-applied`.

## 7. Apply 6 manifests

Commandes executees sequentiellement depuis le bastion :

```
kubectl apply -f k8s/keybuzz-backend-dev/deployment-amazon-items-worker.yaml
kubectl apply -f k8s/keybuzz-backend-dev/deployment-amazon-orders-worker.yaml
kubectl apply -f k8s/keybuzz-backend-dev/deployment-backfill-scheduler.yaml
kubectl apply -f k8s/keybuzz-backend-prod/amazon-items-worker-deployment.yaml
kubectl apply -f k8s/keybuzz-backend-prod/amazon-orders-worker-deployment.yaml
kubectl apply -f k8s/keybuzz-backend-prod/deployment-backfill-scheduler.yaml

kubectl rollout status -n <ns> deploy/<deploy> --timeout=30s   # apres chaque apply
```

Resultats :

| Apply | Reponse kubectl | Rollout status |
|---|---|---|
| DEV items | `deployment.apps/amazon-items-worker configured` + `configmap/amazon-items-worker-config unchanged` | successfully rolled out (instantane) |
| DEV orders | `deployment.apps/amazon-orders-worker configured` + `configmap/amazon-orders-worker-config unchanged` | successfully rolled out (instantane) |
| DEV scheduler | `deployment.apps/backfill-scheduler configured` | successfully rolled out (instantane) |
| PROD items | `deployment.apps/amazon-items-worker configured` | successfully rolled out (instantane) |
| PROD orders | `deployment.apps/amazon-orders-worker configured` | successfully rolled out (instantane) |
| PROD scheduler | `deployment.apps/backfill-scheduler configured` | successfully rolled out (instantane) |

`configured` (et non `unchanged`) est attendu : kubectl apply a mis a jour l'annotation `last-applied-configuration`, mais l'absence de mutation `spec.template` a evite tout rollout fonctionnel.

Aucune commande `kubectl set image`, `kubectl set env`, `kubectl patch` ou `kubectl edit` n'a ete utilisee.

## 8. Snapshot post-apply

| Service | runtime tag | last-applied tag | match | imageID identique pre-apply ? | pod_name identique ? | restart_total |
|---|---|---|---|---|---|---|
| DEV items | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.40-amz-tracking-visibility-backfill-dev | OK | OK | OK (5d78cd99c7-p7tj7) | 2 (inchange) |
| DEV orders | v1.0.40-amz-tracking-visibility-backfill-dev | v1.0.40-amz-tracking-visibility-backfill-dev | OK | OK | OK (7988c9c6cb-qprmt) | 4 (inchange) |
| DEV scheduler | v1.0.42-td02-worker-resilience-dev | v1.0.42-td02-worker-resilience-dev | OK | OK | OK (8654c9f646-n9chk) | 0 (inchange) |
| PROD items | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.40-amz-tracking-visibility-backfill-prod | OK | OK | OK (8554cc9cf9-md72c) | 0 (inchange) |
| PROD orders | v1.0.40-amz-tracking-visibility-backfill-prod | v1.0.40-amz-tracking-visibility-backfill-prod | OK | OK | OK (5f4947c457-dq2xk) | 4 (inchange) |
| PROD scheduler | v1.0.42-td02-worker-resilience-prod | v1.0.42-td02-worker-resilience-prod | OK | OK | OK (65dd74c776-94l8w) | 0 (inchange) |

Verifications :
- runtime image = manifest image = last-applied image pour les 6 deployments (OK)
- imageID strictement identique avant/apres apply (OK)
- pod_count, ready, restart_total inchanges (OK)
- meme nom de pod avant/apres pour les 6 (zero pod recree, zero rollout fonctionnel)

## 9. Scan global final - tous Deployments KeyBuzz

Verification pour chaque deployment de chaque namespace KeyBuzz que `runtime image == last-applied image` :

| Namespace | Deployments scannes | Drifts detectes |
|---|---:|---:|
| keybuzz-api-dev | 2 | 0 |
| keybuzz-api-prod | 2 | 0 |
| keybuzz-client-dev | 1 | 0 |
| keybuzz-client-prod | 1 | 0 |
| keybuzz-backend-dev | 4 | 0 |
| keybuzz-backend-prod | 4 | 0 |
| keybuzz-website-dev | 1 | 0 |
| keybuzz-website-prod | 1 | 0 |
| keybuzz-admin-v2-dev | 1 | 0 |
| keybuzz-admin-v2-prod | 1 | 0 |
| **Total** | **18** | **0** |

`Total drift: 0`. L'ensemble des Deployments KeyBuzz est desormais aligne runtime = manifest = last-applied.

## 10. Non-regression services non touches par cette phase

Verification que les autres services (hors 6 cibles) sont strictement inchanges :

| Service | Image avant | Image apres | Verdict |
|---|---|---|---|
| keybuzz-api-dev/keybuzz-api | v3.5.167-conversation-tone-metric-dev | idem | inchange |
| keybuzz-api-prod/keybuzz-api | v3.5.151-conversation-tone-metric-prod | idem | inchange |
| keybuzz-api-dev/keybuzz-outbound-worker | v3.5.165-escalation-flow-dev | idem | inchange |
| keybuzz-api-prod/keybuzz-outbound-worker | v3.5.165-escalation-flow-prod | idem | inchange |
| keybuzz-client-dev/keybuzz-client | v3.5.176-conversation-tone-metric-ux-dev | idem | inchange |
| keybuzz-client-prod/keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | idem | inchange |
| keybuzz-backend-dev/keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | idem | inchange |
| keybuzz-backend-prod/keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | idem | inchange |
| keybuzz-website-dev/keybuzz-website | v0.6.12-linkedin-insight-seo-dev | idem | inchange |
| keybuzz-website-prod/keybuzz-website | v0.6.12-linkedin-insight-seo-prod | idem | inchange |
| keybuzz-admin-v2-dev/keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | idem | inchange |
| keybuzz-admin-v2-prod/keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod | idem | inchange |

## 11. AI feature parity / Anti-regression

Phase de reconciliation declarative pure. Aucun code applicatif modifie, aucun build, aucune image runtime changee. Toutes les baselines sont preservees par construction (le `spec.template.spec.containers[*]` runtime n'a pas change entre pre et post apply, donc aucun pod n'a ete recree).

| Baseline | Verdict |
|---|---|
| no-reask AP.1A->AP.1F | preserve |
| author_name AP.2.2/2.3 | preserve |
| auto-assignment AP.2.7/2.8 | preserve |
| lifecycle AP.2.4/2.5/2.6 | preserve |
| message_source AR.7 | preserve |
| milestones AR.6 / AR.6.1 / AR.6.1A / AR.6.2 | preserve |
| performance dashboard AR.2 -> AR.6.2 | preserve |
| conversation tone AR.5.1 / AR.5.2 (ToneKpiCard) | preserve |
| escalation flow OW (v3.5.165-escalation-flow-*) | preserve |
| Amazon connector tracking visibility (PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02) | preserve |
| Amazon backfill scheduler (PH26.3B + TD-02 resilience) | preserve |
| Backend cross-env guard (v1.0.47) | preserve |
| Shopify disabled state | preserve |
| 17TRACK posture | preserve |
| Tracking server-side | preserve |

## 12. No fake events / no external send / no DB drift

| Risque | Controle | Resultat |
|---|---|---|
| Mutation DB | aucune | 0 |
| Build / push image | aucun | 0 |
| Tag image runtime modifie | aucun | 0 |
| kubectl set image / set env / patch / edit | aucun | 0 |
| git reset --hard / git clean | aucun | 0 |
| Email / message marketplace / webhook externe | aucun | 0 |
| Event GA4 / CAPI / TikTok / LinkedIn | aucun | 0 |
| Mutation Stripe / billing | aucune | 0 |
| Tracking drift | aucun | 0 |
| Token affiche dans logs / rapport | aucune occurrence | 0 |
| Modification spec applicative (image runtime, env, command, probes, resources, replicas, strategy) | aucune | 0 |

## 13. Rollback

Aucun rollback operationnel n'est necessaire - la phase n'a change aucune image runtime ni aucun pod.

Si jamais un rollback documentaire etait requis (ex : revenir aux anciens manifests v1.0.41-ph263b-scheduler) :
1. `git revert` du commit AS0.1 dans keybuzz-infra
2. `git push origin main`
3. `git pull --ff-only` cote bastion
4. `kubectl apply -f` sur les 6 manifests -> declencherait un rollback fonctionnel des 6 deployments vers v1.0.41-ph263b-scheduler. Workers Amazon perdraient le fix tracking-visibility-backfill, scheduler perdrait la resilience TD-02. Verdict : non recommande sans validation produit explicite.

Rollback recommande : aucun. Les images runtime actuelles sont validees par les rapports PH-AMZ-TRACKING-VISIBILITY-BACKFILL-02 et PH-TD-02.

## 14. Linear

Mise a jour a porter sur **KEY-299** :
- 6 drifts GitOps residuels (workers Backend Amazon DEV+PROD + scheduler DEV+PROD) reconcilies.
- 0 nouveau pod, 0 image runtime change, 0 rollout fonctionnel.
- Scan global final : 0 drift sur 18 deployments KeyBuzz.
- Statut suggere : Done.

**KEY-300** (cree pour la dette future) reste en backlog. Cette phase n'a pas merge tracking visibility + worker resilience pour les workers Amazon. Action future : produire une image v1.0.43+ qui combine les deux fix et la promouvoir proprement via GitOps.

KEY-263 / AS.1 peut etre repris des que ce rapport est commit/push.

KEY-295 / KEY-296 / KEY-297 : aucun impact - tous restent dans leurs etats Done respectifs.

## 15. Gaps restants

1. **Workers Amazon (items + orders) sans resilience TD-02** : leur image v1.0.40-amz-tracking-visibility-backfill ne contient pas les entrypoints resilients TD-02. En cas de coupure PostgreSQL Patroni, ces pods crasheront au lieu de se reconnecter avec backoff. Restart_total observe : DEV items=2, DEV orders=4, PROD orders=4. Acceptable a court terme, mais a fixer via KEY-300.

2. **`deployment.kubernetes.io/revision` desynchronise sur PROD workers Amazon** : le manifest contient `revision: "1"` (valeur initiale) mais le runtime est a `27/28` apres les apply. K8s gere automatiquement cette annotation, ce n'est pas un drift fonctionnel.

3. **Manifests DEV en CRLF** : conserves tels quels. Si une convention KeyBuzz future impose LF partout, cette migration pourra etre faite dans une phase dediee.

4. **`v1.0.40 < v1.0.41` semver bizarre** : la version v1.0.40-amz-tracking-visibility-backfill a un numero semver inferieur a v1.0.41-ph263b-scheduler bien qu'elle soit posterieure chronologiquement (23 mars vs 5 mars). Indique probablement une branche divergente ou un fix urgent issu d'une version anterieure du code. Hors scope KEY-299, sera clarifie dans KEY-300.

5. **Audit historique des `kubectl set image`** : aucune annotation `kubernetes.io/change-cause` sur les rollout history, donc impossible de remonter aux causes des 27 revisions des workers Amazon PROD. Recommandation : ajouter `--record=true` ou utiliser des manifests annotes pour les promotions futures.

6. **Workers Amazon args inline conserve** : les manifests PROD continuent de definir un `args` avec inline code (preserve runtime). Le rapport TD-02 indique que les fichiers `*WorkerResilient.js` "remplacent les commandes inline node -e dans les deployments K8s" - mais en PROD le `args` inline est toujours present comme heritage. Pas un drift puisque le runtime live l'a aussi. Sera nettoye dans KEY-300.

## 16. Phrase cible finale

GITOPS RESIDUAL DRIFT BACKEND WORKERS RECONCILED - 6 DEPLOYMENTS (DEV+PROD AMAZON ITEMS WORKER, DEV+PROD AMAZON ORDERS WORKER, DEV+PROD BACKFILL SCHEDULER) NOW HAVE runtime image == manifest image == last-applied image - GLOBAL SCAN ON 18 KEYBUZZ DEPLOYMENTS RETURNS 0 DRIFT - CRLF PRESERVED ON DEV MANIFESTS - command ALIGNED ON RESILIENT ENTRYPOINTS (DEV WORKERS) - command + env ORDER ALIGNED ON RUNTIME (PROD WORKERS) - args INLINE PRESERVED (PROD) - creationTimestamp:null CLEANED (2 PROD MANIFESTS) - NO POD RESTART - NO IMAGE RUNTIME CHANGE - NO BUILD - NO `kubectl set image` / `set env` / `patch` / `edit` USED - NO `git reset` / `git clean` USED - NO DB / STRIPE / BILLING / TRACKING / CAPI DRIFT - API DEV+PROD / CLIENT DEV+PROD / OW DEV+PROD / BACKEND PRINCIPAL DEV+PROD / WEBSITE / ADMIN STRICTLY UNCHANGED - LONG TERM TRACKING+RESILIENCE MERGE DEFERRED TO KEY-300 - KEY-263 / AS.1 NOW READY TO RESUME - KEY-299 READY TO CLOSE.

STOP

## Rapport

`keybuzz-infra/docs/PH-INFRA-T8.12AS0.1-GITOPS-BACKEND-WORKERS-DRIFT-RECONCILIATION-01.md`
