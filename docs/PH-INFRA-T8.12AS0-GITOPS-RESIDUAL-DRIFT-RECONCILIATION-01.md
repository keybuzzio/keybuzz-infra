# PH-INFRA-T8.12AS0-GITOPS-RESIDUAL-DRIFT-RECONCILIATION-01 - Reconciliation des drifts GitOps residuels OW + Backend DEV

> Date : 2026-05-10
> Linear : KEY-297 (lie a KEY-295 pour la reconciliation principale et KEY-298 pour la strategie long terme `restartedAt`)
> Phase : reconciliation GitOps - alignement clone bastion + annotations Kubernetes last-applied + correction d'un manifest non idempotent
> Environnement : bastion install-v3 + clusters DEV + PROD
> Type : reconciliation declarative + correction manifest GitOps non idempotent - pas de build, pas de changement d'image, pas de rollout

## VERDICT

GO RECONCILED - DRIFT RESOLVED - NO ROLLOUT

Les 3 deployments residuels (keybuzz-outbound-worker DEV+PROD et keybuzz-backend DEV) sont maintenant alignes : runtime image = manifest image = last-applied image. Aucun pod n'a ete recree (meme imageID, meme nom de pod, meme restart_total avant/apres). Le manifest OW PROD a ete corrige pour retirer 25 lignes de champs Kubernetes generes/immutables qui empechaient kubectl apply de fonctionner. La valeur de `kubectl.kubernetes.io/restartedAt` a ete alignee sur la valeur runtime live (`2026-04-10T19:55:22Z`) pour eviter un rollout fonctionnel - la strategie long terme pour cette annotation est portee par KEY-298.

API DEV+PROD, Client DEV+PROD, Website, Admin, autres workers Backend (amazon-items, amazon-orders, backfill-scheduler) restent strictement intacts.

## 1. Origine de l'incident

Le preflight de la phase PH-SAAS-T8.12AS.1 (escalation proactive notifications) post-KEY-295 a revele que 3 drifts GitOps residuels n'avaient pas ete couverts par KEY-295 (qui ciblait strictement les 4 deployments API+Client) :

| Service | runtime image | last-applied image avant action | drift |
|---|---|---|---|
| OW DEV | v3.5.165-escalation-flow-dev | v0.1.112-dev | enorme |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.96-ph85-ops-action-center-prod | environ 70 versions |
| Backend DEV | v1.0.47-cross-env-guard-fix-dev | v1.0.46-amazon-oauth-activation-bridge-dev | 1 version |

KEY-297 a ete cree pour traiter ces 3 drifts residuels avant de reprendre AS.1 sur un etat propre.

L'audit initial a aussi revele que le manifest `k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` etait un dump complet de l'etat Kubernetes (probablement `kubectl get -o yaml > file.yaml` commit) avec 6 categories de champs problematiques :

- `metadata.uid` (immutable, genere par K8s)
- `metadata.creationTimestamp` (immutable)
- `metadata.resourceVersion` (immutable)
- `metadata.generation` (genere par K8s)
- `status:` block (genere par K8s)
- `spec.template.metadata.creationTimestamp: null` (artefact benin de dump)
- `spec.template.metadata.annotations.kubectl.kubernetes.io/restartedAt` (artefact runtime de `kubectl rollout restart`)

Le champ `metadata.uid` immutable empechait carrement `kubectl apply -f` de fonctionner (rejected with "field is immutable").

## 2. Preflight bastion

| Element | Etat avant action |
|---|---|
| Repo bastion `keybuzz-infra` | clean, aligne origin/main HEAD `e863733` post KEY-295 |
| `git remote -v` | `https://github.com/keybuzzio/keybuzz-infra.git` (sans token) |
| `git status --short` | (clean) |
| `git rev-list --left-right --count origin/main...HEAD` | `0 0` |
| keybuzz-api repo | branche `ph147.4/source-of-truth`, HEAD `0e26bfc3`, clean (sauf `dist/`) |
| keybuzz-client repo | branche `ph148/onboarding-activation-replay`, HEAD `0a7306a`, clean |
| keybuzz-backend repo | branche `main`, HEAD `c62f376`, untracked `.bak` pre-existant (hors scope) |
| Manifests cibles localises | OK |
| psql disponible | OK (non utilise dans cette phase) |

## 3. Snapshot pre-action

| Service | runtime image | last-applied | imageID (pod digest) | pods | ready | restart_total |
|---|---|---|---|---|---|---|
| OW DEV | v3.5.165-escalation-flow-dev | v0.1.112-dev | sha256:60423d4de2db21d92035e7f49340fdcbe680260bcbfab580a3f2c457f1a5ead | 1 | 1 | 8 |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.96-ph85-ops-action-center-prod | sha256:53833cf95a3e94ba217e59765424683c91b7777ae32517ac6d0cc2d49a56e01 | 1 | 1 | 7 |
| Backend DEV | v1.0.47-cross-env-guard-fix-dev | v1.0.46-amazon-oauth-activation-bridge-dev | sha256:b9f9b5a7b82781e688e58af323c782fd5086f0874a540c34709fa4c988b | 1 | 1 | 0 |

Note : restart_total OW DEV=8 et OW PROD=7 - signal independant du drift, hors scope KEY-297.

## 4. Action 1 - Correction du manifest OW PROD non idempotent

Le manifest `k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` a ete nettoye via 2 passes (sed + python) pour retirer les artefacts Kubernetes generes/immutables qui empechaient apply :

| Element retire | Type | Lignes | Justification |
|---|---|---|---|
| `metadata.creationTimestamp: "2026-02-08T11:38:13Z"` | immutable | 1 | autorise par KEY-297 |
| `metadata.generation: 16` | genere | 1 | autorise par KEY-297 |
| `metadata.resourceVersion: "26332058"` | immutable | 1 | autorise par KEY-297 |
| `metadata.uid: cbfd1adf-...` | immutable | 1 | bloquait apply, autorise par KEY-297 |
| `spec.template.metadata.creationTimestamp: null` | artefact dump | 1 | autorise par KEY-297 |
| `spec.template.metadata.annotations:` (vide apres retrait restartedAt) | structurel devenu vide | 1 | suite logique |
| `kubectl.kubernetes.io/restartedAt: "2026-02-19T..."` | artefact runtime | (modifie, pas retire) | aligne sur runtime live `2026-04-10T19:55:22Z` (decision KEY-297 B4 + KEY-298 long terme) |
| `status:` block complet | genere | 19 | autorise par KEY-297 |
| Total | | 24 lignes retirees + 1 ligne modifiee + 0 ligne applicative touchee | |

Note importante - decision B4 KEY-297 : la valeur `kubectl.kubernetes.io/restartedAt` n'a pas ete supprimee (cela aurait modifie `spec.template` et declenche un rollout fonctionnel). Elle a ete alignee sur la valeur runtime live `2026-04-10T19:55:22Z` de sorte que `kubectl apply` ne touche pas `spec.template`. La strategie long terme pour cette annotation (par exemple ArgoCD `ignoreDifferences` ou server-side apply avec field manager dedie pour `kubectl rollout restart`) est suivie dans KEY-298.

Validation YAML post-cleanup :
- `image` = `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod` (preserve)
- `replicas` = 1 (preserve)
- `command` = `["node", "dist/workers/outboundWorker.js"]` (preserve)
- 13 env vars (preserve)
- 2 envFrom secrets (preserve)
- `resources` (limits 200m/256Mi, requests 50m/128Mi) (preserve)
- liveness + readiness probes (preserve)
- imagePullSecret `ghcr-cred` (preserve)
- `selector.matchLabels.app = keybuzz-outbound-worker` (preserve)
- `template.metadata.labels.app = keybuzz-outbound-worker` (preserve)
- `template.metadata.annotations.kubectl.kubernetes.io/restartedAt = "2026-04-10T19:55:22Z"` (aligne runtime)
- `strategy.type = RollingUpdate` (preserve)

YAML toujours valide via `python3 -c "import yaml; yaml.safe_load(open(...))"`.

## 5. Action 2 - kubectl diff -f post-cleanup (lecture seule)

Apres correction du manifest OW PROD :

| Manifest | kubectl diff |
|---|---|
| OW DEV | vide - safe to apply |
| OW PROD | metadata-only (annotations + generation) - aucun changement spec.template - safe to apply |
| Backend DEV | vide - safe to apply |

Pour OW PROD, le diff observe etait strictement :
- `metadata.annotations.deployment.kubernetes.io/revision: "25" -> "16"` (annotation reecrite par K8s a la prochaine update)
- `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration: |...` (sera mise a jour - c'est le but)
- `metadata.generation: 25 -> 26` (auto-incremente par chaque apply)

Aucune mutation de `spec.template`, donc aucun rollout attendu. Verifie conforme aux conditions du prompt KEY-297 : "Continuer uniquement si le diff est vide ou strictement attendu pour annotation/last-applied".

## 6. Action 3 - kubectl apply -f sur les 3 manifests

Commandes executees sequentiellement depuis le bastion (working dir `/opt/keybuzz/keybuzz-infra`) :

```
kubectl apply -f k8s/keybuzz-api-dev/outbound-worker-deployment.yaml
kubectl apply -f k8s/keybuzz-api-prod/outbound-worker-deployment.yaml
kubectl apply -f k8s/keybuzz-backend-dev/deployment.yaml

kubectl rollout status -n keybuzz-api-dev deploy/keybuzz-outbound-worker --timeout=30s
kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-outbound-worker --timeout=30s
kubectl rollout status -n keybuzz-backend-dev deploy/keybuzz-backend --timeout=30s
```

Resultats :

| Apply | Reponse kubectl | Rollout status |
|---|---|---|
| OW DEV | `deployment.apps/keybuzz-outbound-worker configured` | `successfully rolled out` (instantane) |
| OW PROD | `deployment.apps/keybuzz-outbound-worker configured` | `successfully rolled out` (instantane) |
| Backend DEV | `deployment.apps/keybuzz-backend configured` | `successfully rolled out` (instantane) |

`configured` (et non `unchanged`) est attendu : kubectl apply a mis a jour l'annotation `last-applied-configuration`, mais l'absence de mutation de `spec.template` a evite tout rollout. Les rollout status sont instantanes.

Aucune commande `kubectl set image`, `kubectl set env`, `kubectl patch` ou `kubectl edit` n'a ete utilisee.

## 7. Snapshot post-apply

| Service | runtime tag | last-applied tag | match | imageID identique pre-apply ? | pods | ready | restart_total |
|---|---|---|---|---|---|---|---|
| OW DEV | v3.5.165-escalation-flow-dev | v3.5.165-escalation-flow-dev | OK | OK identique sha256:60423d4d... | 1 | 1 | 8 (inchange) |
| OW PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | OK | OK identique sha256:53833cf9... | 1 | 1 | 7 (inchange) |
| Backend DEV | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-dev | OK | OK identique sha256:b9f9b5a7... | 1 | 1 | 0 (inchange) |

Verifications :
- runtime image = manifest image = last-applied image pour les 3 deployments (OK)
- imageID strictement identique avant/apres apply (OK)
- pod_count = 1 inchange (OK)
- ready = 1 inchange (OK)
- restart_total inchange pour les 3 (OK)
- meme nom de pod avant/apres pour les 3 (zero pod recree)

Events Kubernetes post-apply (30 dernieres secondes) sur les 3 namespaces ne montrent que des CronJobs periodiques (sla-evaluator, outbound-tick-processor, amazon-orders-backfill). Aucun event lie a un rollout des 3 deployments cibles.

## 8. Validation runtime fonctionnelle

OW est un worker (pas d'endpoint HTTP) - pas de healthcheck externe a tester directement. Verifications indirectes :

| Verification | Resultat |
|---|---|
| Pods ready (1/1 pour les 3) | OK |
| restart_total inchange | OK (8/7/0 avant et apres) |
| imageID identique | OK |
| Aucun pod en CrashLoopBackoff/Pending | OK |
| Manifest YAML toujours valide | OK |

Backend DEV est une API web (mais la phase ne touche pas les routes externes). Pas de test HTTP runtime pertinent ici. La QA fonctionnelle relevera de Ludovic apres reprise AS.1.

## 9. Non-regression services non touches

Verification que les services hors scope sont strictement inchanges :

| Service | Image avant | Image apres | Verdict |
|---|---|---|---|
| keybuzz-api-dev/keybuzz-api | v3.5.167-conversation-tone-metric-dev | v3.5.167-conversation-tone-metric-dev | inchange |
| keybuzz-api-prod/keybuzz-api | v3.5.151-conversation-tone-metric-prod | v3.5.151-conversation-tone-metric-prod | inchange |
| keybuzz-client-dev/keybuzz-client | v3.5.176-conversation-tone-metric-ux-dev | v3.5.176-conversation-tone-metric-ux-dev | inchange |
| keybuzz-client-prod/keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod | v3.5.174-conversation-tone-metric-ux-prod | inchange |
| keybuzz-backend-prod/keybuzz-backend | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | inchange |
| amazon-items-worker DEV+PROD | v1.0.40-amz-tracking-visibility-backfill-* | v1.0.40-amz-tracking-visibility-backfill-* | inchange |
| amazon-orders-worker DEV+PROD | v1.0.40-amz-tracking-visibility-backfill-* | v1.0.40-amz-tracking-visibility-backfill-* | inchange |
| backfill-scheduler DEV+PROD | v1.0.42-td02-worker-resilience-* | v1.0.42-td02-worker-resilience-* | inchange |
| keybuzz-website DEV+PROD | v0.6.12-linkedin-insight-seo-* | v0.6.12-linkedin-insight-seo-* | inchange |
| keybuzz-admin-v2 DEV+PROD | v2.12.2-media-buyer-lp-domain-qa-* | v2.12.2-media-buyer-lp-domain-qa-* | inchange |

Aucune mutation hors des 3 deployments cibles.

## 10. AI feature parity / Anti-regression

Phase de reconciliation declarative pure. Aucun code, aucun build, aucune image changee. Toutes les baselines sont preservees par construction (le `spec.template.spec.containers[*]` n'a pas change entre pre et post apply, donc aucun pod n'a ete recree).

| Baseline | Verdict |
|---|---|
| no-reask AP.1A->AP.1F | preserve (image API inchangee) |
| author_name AP.2.2/2.3 | preserve |
| auto-assignment AP.2.7/2.8 | preserve |
| lifecycle AP.2.4/2.5/2.6 | preserve |
| message_source AR.7 | preserve |
| milestones AR.6 / AR.6.1 / AR.6.1A / AR.6.2 | preserve |
| performance dashboard AR.2 -> AR.6.2 | preserve |
| conversation tone AR.5.1 / AR.5.2 (ToneKpiCard) | preserve |
| escalation flow OW (v3.5.165-escalation-flow-*) | preserve - aucune modification spec, runtime intact |
| Amazon connector | preserve |
| Shopify disabled state | preserve |
| 17TRACK posture | preserve |
| Tracking server-side | preserve |

## 11. No fake events / no external send / no DB drift

| Risque | Controle | Resultat |
|---|---|---|
| Mutation DB | aucune | 0 |
| Build / push image | aucun | 0 |
| Tag image modifie | aucun | 0 |
| kubectl set image / set env / patch / edit | aucun | 0 |
| git reset --hard / git clean | aucun | 0 |
| Email / message marketplace / webhook externe | aucun | 0 |
| Event GA4 / CAPI / TikTok / LinkedIn | aucun | 0 |
| Mutation Stripe / billing | aucune | 0 |
| Tracking drift | aucun | 0 |
| Token affiche dans logs / rapport | aucune occurrence | 0 |
| Modification d'une spec applicative (image/env/probes/resources/command/secrets/replicas/strategy) | aucune | 0 |

## 12. Rollback

Aucun rollback operationnel n'est necessaire - la phase n'a change aucune image runtime ni aucun pod.

Si jamais un rollback documentaire etait requis (par exemple si on voulait revenir a un manifest OW PROD avec `metadata.uid` cabled-in pour une raison particuliere) :
1. `git revert` du commit AS0 dans keybuzz-infra
2. `git push origin main`
3. `git pull --ff-only` cote bastion
4. `kubectl apply -f k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` -> echouerait a nouveau avec "field is immutable" comme avant cette phase
5. Donc le rollback recreerait l'incident original

Rollback recommande : aucun. Le manifest nettoye est strictement plus correct que le manifest pre-existant.

## 13. Linear

Mise a jour a porter sur **KEY-297** :
- 3 drifts GitOps residuels (OW DEV, OW PROD, Backend DEV) reconcilies.
- 1 manifest GitOps non idempotent corrige (OW PROD - 25 lignes generees retirees + restartedAt aligne runtime).
- 0 nouveau pod, 0 image change, 0 rollout fonctionnel.
- Statut suggere : Done.

**KEY-298** (cree pour la strategie long terme `restartedAt`) reste en backlog. Cette phase a alige court terme la valeur de l'annotation, mais une politique GitOps long terme (ArgoCD ignoreDifferences ou server-side apply avec field manager dedie) reste a definir.

KEY-263 / AS.1 peut etre repris des que ce rapport est commit/push et merge.

KEY-295 / KEY-296 / KEY-292 / KEY-290 : aucun impact - tous restent dans leurs etats respectifs.

## 14. Gaps restants

1. **Strategie long terme `kubectl.kubernetes.io/restartedAt`** : portee par KEY-298. Court terme, le manifest contient la valeur runtime (`2026-04-10T19:55:22Z`), donc `kubectl diff` est propre. Si `kubectl rollout restart` est invoque sur OW PROD a l'avenir sans mise a jour du manifest, le drift `last-applied` reapparaitra. Solution : ArgoCD `ignoreDifferences` sur `/spec/template/metadata/annotations/kubectl.kubernetes.io~1restartedAt` pour les Deployments.

2. **restart_total OW DEV=8 et OW PROD=7** : signal independant du drift GitOps. Ces pods ont redemarre plusieurs fois depuis leur creation. Hors scope KEY-297. A investiguer dans une phase distincte si necessaire (par exemple PH-INFRA-OW-RESTART-TRUTH-AUDIT-01).

3. **Manifest pre-existant sous forme de dump complet** : OW PROD etait un dump complet de l'etat Kubernetes (avec `status:`, `uid`, etc.). C'est une mauvaise pratique GitOps qui suggere qu'a un moment quelqu'un a fait `kubectl get -o yaml > file.yaml` et l'a commit. Recommandation generale : auditer les autres manifests pour detecter d'autres dumps similaires (hors scope KEY-297, mais potentiel KEY-NEW si necessaire).

4. **Workers Backend autres** (`amazon-items-worker`, `amazon-orders-worker`, `backfill-scheduler`) : aucun drift detecte pour eux car le preflight ne les a pas listes comme cibles. Verifier dans une phase suivante si necessaire.

5. **Cron jobs et autres ressources** : non auditees dans ce preflight (uniquement Deployments). Un drift sur des CronJobs ou ConfigMaps pourrait passer sous le radar. Hors scope KEY-297.

## 15. Phrase cible finale

GITOPS RESIDUAL DRIFT RECONCILED - 3 DEPLOYMENTS (OW DEV, OW PROD, BACKEND DEV) NOW HAVE runtime image == manifest image == last-applied image - OW PROD MANIFEST FIXED FROM NON-IDEMPOTENT DUMP TO IDEMPOTENT DECLARATIVE FORM (25 GENERATED FIELDS REMOVED, restartedAt ALIGNED ON RUNTIME LIVE VALUE) - NO POD RESTART - NO IMAGE CHANGE - NO BUILD - NO `kubectl set image` / `set env` / `patch` / `edit` USED - NO `git reset` / `git clean` USED - NO DB / STRIPE / BILLING / TRACKING / CAPI DRIFT - API DEV+PROD / CLIENT DEV+PROD / BACKEND PROD / WEBSITE / ADMIN / OTHER WORKERS STRICTLY UNCHANGED - LONG-TERM `restartedAt` POLICY DEFERRED TO KEY-298 - KEY-263 / AS.1 NOW READY TO RESUME - KEY-297 READY TO CLOSE.

STOP

## Rapport

`keybuzz-infra/docs/PH-INFRA-T8.12AS0-GITOPS-RESIDUAL-DRIFT-RECONCILIATION-01.md`
