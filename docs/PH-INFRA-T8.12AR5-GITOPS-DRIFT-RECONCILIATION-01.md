# PH-INFRA-T8.12AR5-GITOPS-DRIFT-RECONCILIATION-01 - Reconciliation GitOps post-AR.5

> Date : 2026-05-10
> Linear : KEY-295 (lie a KEY-292 / KEY-290 - AR.5.x)
> Phase : reconciliation GitOps - alignement clone bastion + annotations Kubernetes last-applied sur les manifests GitHub deja corrects
> Environnement : bastion install-v3 + clusters DEV + PROD
> Type : reconciliation declarative pure - pas de build, pas de changement d'image, pas de rollout

## VERDICT

GO RECONCILED - DRIFT RESOLVED - NO ROLLOUT

Le clone bastion keybuzz-infra est aligne sur origin/main (HEAD eeae935). Les 4 deployments concernes (keybuzz-api DEV+PROD et keybuzz-client DEV+PROD) ont ete reconcilies via kubectl apply -f strict sur leurs manifests respectifs. L'annotation kubectl.kubernetes.io/last-applied-configuration reflete maintenant le manifest courant. Aucun pod n'a ete redeploye (digest container identique avant/apres). Backend, OW, Website, Admin restent strictement intacts.

KEY-263 / AS.1 peut maintenant reprendre sur un etat propre.

---

## 1. Origine de l'incident

Le preflight de la phase PH-SAAS-T8.12AS.1-ESCALATION-PROACTIVE-NOTIFICATIONS-TRUTH-AUDIT-AND-DEV-01 a revele un drift GitOps majeur sur les annotations last-applied Kubernetes vs runtime spec :

| Service | runtime spec | annotation last-applied | drift |
|---|---|---|---|
| API DEV | v3.5.167-conversation-tone-metric-dev | v3.5.163-message-source-enrichment-dev | 4 versions |
| API PROD | v3.5.151-conversation-tone-metric-prod | v3.5.149-message-source-enrichment-prod | 2 versions |
| Client DEV | v3.5.176-conversation-tone-metric-ux-dev | v3.5.172-message-source-enrichment-ux-dev | 4 versions |
| Client PROD | v3.5.174-conversation-tone-metric-ux-prod | v3.5.172-message-source-enrichment-ux-prod | 2 versions |

Cause confirmee : le clone bastion /opt/keybuzz/keybuzz-infra etait a HEAD e722fd6 (AR.7.1) alors que origin/main etait a eeae935 (AR.5.2), avec 14 commits de retard. Les promotions AR.6, AR.6.1, AR.6.1A, AR.6.2, AR.5, AR.5.1, AR.5.2 et AR.7.1 avaient change le runtime spec via une voie autre que kubectl apply -f manifest depuis le bastion (probablement kubectl set image ou apply depuis un autre poste).

L'incident est de la meme nature que PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01 du 28 avril 2026.

---

## 2. Preflight bastion

| Element | Etat avant action |
|---|---|
| Repo | /opt/keybuzz/keybuzz-infra |
| git remote -v | https://github.com/keybuzzio/keybuzz-infra.git (sans token, post PH-SECURITY-01) |
| Branche | main |
| Working tree | clean (0 modifie, 0 untracked) |
| HEAD avant fetch | e722fd6 (AR.7.1 PROD message-source-enrichment) |
| HEAD origin/main | eeae935 (AR.5.2 conversation-tone PROD promotion) |
| Commits derriere origin | 14 (incluant AR.5, AR.5.1, AR.5.2, AR.6, AR.6.1, AR.6.1A, AR.6.2, AR.7.1) |
| Commits locaux en avance | 0 -> fast-forward possible |
| Presence des commits AR.5.x sur origin/main | confirmee : dc2213a (AR.5.1 gitops dev), 598ee7f (AR.5.2 gitops prod), da16d23 / eeae935 / 0eac4c3 (docs AR.5.x) |

---

## 3. Action 1 - git pull --ff-only origin main

Commande executee sur le bastion :

```
cd /opt/keybuzz/keybuzz-infra
git pull --ff-only origin main
```

Resultat :

| Indicateur | Valeur |
|---|---|
| Type | Fast-forward (e722fd6 -> eeae935) |
| Fichiers changes | 12 |
| Manifests deployment.yaml modifies | 4 (api-dev, api-prod, client-dev, client-prod), +2 / -2 lignes chacun (image + commentaire rollback) |
| Nouveaux rapports docs | 8 (AR.5, AR.5.1, AR.5.2, AR.6, AR.6.1, AR.6.1A, AR.6.2, AR.7.1) |
| HEAD post-pull | eeae935 |
| Working tree post-pull | clean |
| git rev-parse HEAD == git rev-parse origin/main | YES |

Aucun git reset --hard, aucun git clean, aucun merge commit cree.

---

## 4. Action 2 - Verification manifests

Contenu des 4 manifests post-pull :

| Manifest | Image conformement attendue ? |
|---|---|
| k8s/keybuzz-api-dev/deployment.yaml | OK v3.5.167-conversation-tone-metric-dev (rollback documente v3.5.166-performance-sav-encoding-fix-dev) |
| k8s/keybuzz-api-prod/deployment.yaml | OK v3.5.151-conversation-tone-metric-prod (rollback v3.5.150-performance-sav-milestones-prod) |
| k8s/keybuzz-client-dev/deployment.yaml | OK v3.5.176-conversation-tone-metric-ux-dev (rollback v3.5.175-performance-sav-encoding-fix-dev) |
| k8s/keybuzz-client-prod/deployment.yaml | OK v3.5.174-conversation-tone-metric-ux-prod (rollback v3.5.173-performance-sav-milestones-ux-prod) |

Aucun rollback n'utilise kubectl set image ou kubectl edit - uniquement des references d'images en commentaire.

---

## 5. Action 3 - kubectl diff -f (lecture seule, pre-apply)

Pour les 4 manifests, kubectl diff retourne vide : le runtime spec est deja identique au manifest local. Le seul ecart est sur l'annotation kubectl.kubernetes.io/last-applied-configuration, qui n'est pas comparee par kubectl diff (elle est geree separement par apply).

Conclusion : kubectl apply -f fera uniquement un patch d'annotation, sans mutation du spec.template, donc sans rollout.

---

## 6. Snapshot pre-apply

| Service | runtime image | last-applied image | imageID (digest pod) | pods | ready | restart |
|---|---|---|---|---|---|---|
| API DEV | v3.5.167 | v3.5.163 | sha256:68c99e1c5d9482af3f3c8257f2e6933a9d6cf3fb0f6 | 1 | 1 | 0 |
| API PROD | v3.5.151 | v3.5.149 | sha256:29e53af3db701c45a6d321bc527ee232d9249529102 | 1 | 1 | 0 |
| Client DEV | v3.5.176 | v3.5.172 | sha256:4be6eeaafd5bcf433afe352b9cb4f2a764a814e9 | 1 | 1 | 0 |
| Client PROD | v3.5.174 | v3.5.172 | sha256:8d2e195ae6cf0d2d8c07f5e3534f60985522ae15 | 1 | 1 | 0 |

---

## 7. Action 4 - kubectl apply -f sur les 4 manifests

Commandes executees sequentiellement depuis le bastion (working dir /opt/keybuzz/keybuzz-infra) :

```
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
kubectl rollout status -n keybuzz-api-dev deploy/keybuzz-api --timeout=60s

kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status -n keybuzz-api-prod deploy/keybuzz-api --timeout=60s

kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml
kubectl rollout status -n keybuzz-client-dev deploy/keybuzz-client --timeout=60s

kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml
kubectl rollout status -n keybuzz-client-prod deploy/keybuzz-client --timeout=60s
```

Resultats :

| Apply | Reponse kubectl | Rollout status |
|---|---|---|
| api-dev | deployment.apps/keybuzz-api configured | successfully rolled out (instantane) |
| api-prod | deployment.apps/keybuzz-api configured | successfully rolled out (instantane) |
| client-dev | deployment.apps/keybuzz-client configured | successfully rolled out (instantane) |
| client-prod | deployment.apps/keybuzz-client configured | successfully rolled out (instantane) |

`configured` (et non `unchanged`) est attendu : kubectl apply a mis a jour l'annotation last-applied-configuration, mais l'absence de mutation du spec.template a evite tout rollout. Les rollout status sont instantanes (aucun pod recree).

Aucune commande kubectl set image, kubectl set env, kubectl patch ou kubectl edit n'a ete utilisee.

---

## 8. Snapshot post-apply

| Service | runtime image | last-applied image | match | imageID (digest pod) | identique pre-apply ? | pods | ready | restart |
|---|---|---|---|---|---|---|---|---|
| API DEV | v3.5.167 | v3.5.167 | OK | sha256:68c99e1c5d9482af3f3c8257f2e6933a9d6cf3fb0f6 | OK identique | 1 | 1 | 0 |
| API PROD | v3.5.151 | v3.5.151 | OK | sha256:29e53af3db701c45a6d321bc527ee232d9249529102 | OK identique | 1 | 1 | 0 |
| Client DEV | v3.5.176 | v3.5.176 | OK | sha256:4be6eeaafd5bcf433afe352b9cb4f2a764a814e9 | OK identique | 1 | 1 | 0 |
| Client PROD | v3.5.174 | v3.5.174 | OK | sha256:8d2e195ae6cf0d2d8c07f5e3534f60985522ae15 | OK identique | 1 | 1 | 0 |

Drift resolu sur les 4 deployments. Pod count, ready replicas, restart count, et imageID strictement identiques avant/apres -> aucun rollout fonctionnel.

---

## 9. Validation runtime

| Surface | Test | Resultat |
|---|---|---|
| API DEV | GET https://api-dev.keybuzz.io/health | HTTP 200 |
| API PROD | GET https://api.keybuzz.io/health | HTTP 200 |
| Client DEV | GET https://client-dev.keybuzz.io | HTTP 307 (redirect /login normal) |
| Client PROD | GET https://client.keybuzz.io | HTTP 307 (redirect /login normal) |

La carte "Tonalite des conversations" sur /performance (live depuis AR.5.2) reste fonctionnelle puisque l'image runtime n'a pas change. La QA UI complete releve de Ludovic.

---

## 10. Non-regression services non touches

Verification que les services hors scope sont strictement inchanges :

| Service | Image avant action AR5-RECONCILIATION | Image apres action | Verdict |
|---|---|---|---|
| keybuzz-backend (DEV) | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-dev | inchange |
| keybuzz-backend (PROD) | v1.0.47-cross-env-guard-fix-prod | v1.0.47-cross-env-guard-fix-prod | inchange |
| amazon-items-worker / amazon-orders-worker DEV+PROD | v1.0.40-amz-tracking-visibility-backfill-* | v1.0.40-amz-tracking-visibility-backfill-* | inchange |
| backfill-scheduler DEV+PROD | v1.0.42-td02-worker-resilience-* | v1.0.42-td02-worker-resilience-* | inchange |
| keybuzz-outbound-worker DEV | v3.5.165-escalation-flow-dev | v3.5.165-escalation-flow-dev | inchange |
| keybuzz-outbound-worker PROD | v3.5.165-escalation-flow-prod | v3.5.165-escalation-flow-prod | inchange |
| keybuzz-website DEV+PROD | v0.6.12-linkedin-insight-seo-* | v0.6.12-linkedin-insight-seo-* | inchange |
| keybuzz-admin-v2 DEV+PROD | v2.12.2-media-buyer-lp-domain-qa-* | v2.12.2-media-buyer-lp-domain-qa-* | inchange |

Aucune mutation hors des 4 deployments cibles.

---

## 11. AI Feature Parity / Anti-regression

Phase de reconciliation declarative pure. Aucun code, aucun build, aucune image changee. Toutes les baselines AI/messaging/lifecycle sont preservees par construction (le spec.template.spec.containers[*] n'a pas change entre pre et post apply, donc aucun pod n'a ete recree).

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
| Amazon connector | preserve (Backend image inchangee) |
| Shopify disabled state | preserve |
| 17TRACK posture | preserve |
| Tracking server-side | preserve |
| Promo funnel | preserve |

---

## 12. No fake events / no external send / no DB drift

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

---

## 13. Rollback

Aucun rollback operationnel n'est necessaire - la phase n'a change aucune image ni aucun pod.

Si jamais un rollback etait requis (par exemple si on decouvrait que les manifests AR.5.x etaient eux-memes errones) :
1. git revert eeae935 dc2213a 598ee7f -m 1 (cote local), git push origin main
2. git pull --ff-only cote bastion
3. kubectl apply -f sur les 4 deployments -> annotation revient au manifest precedent
4. Si le spec.image du manifest pre-AR.5 differait du runtime, kubectl declencherait un rollout vers les images precedentes (rollback fonctionnel + GitOps).

Mais aucune raison a ce jour de revenir en arriere : les images AR.5.1/5.2 sont les versions en production validees, et la QA Ludovic post-AR.5.2 est en cours selon le canal habituel.

---

## 14. Linear

Mise a jour a porter sur KEY-295 :
- Drift GitOps reconcilie sur API DEV+PROD et Client DEV+PROD.
- Bastion aligne sur origin/main HEAD eeae935.
- 4 deployments reconcilies via kubectl apply -f, annotation last-applied mise a jour.
- 0 nouveau pod, 0 image change, 0 rollout fonctionnel.
- Statut suggere : Done.

KEY-263 (AS.1) peut etre deverrouille.

KEY-296 et KEY-292 / KEY-290 : aucun impact.

---

## 15. Gaps restants

1. Procedure de promotion future : la cause racine du drift est qu'une promotion (probablement AR.5.2) a ete appliquee via une voie autre que kubectl apply -f depuis le bastion (probablement kubectl set image localement ou apply depuis un autre poste sans push manifest). Le risque de recidive existe tant que les agents qui font les promotions ne disposent pas tous d'un chemin homogene : pull bastion -> apply manifest -> push annotation. Recommandation : ajouter dans process-lock.mdc une verification systematique post-apply que runtime image == last-applied image, et faire echouer la phase si ce n'est pas le cas.
2. Pas de retrait du commentaire rollback dans les manifests : on conserve la convention KeyBuzz. A noter que ce commentaire n'est pas une instruction kubectl set image mais un repere humain - conforme aux regles.
3. Pas de verification de coherence GitOps automatisee : un job CI (par exemple workflow GitHub Actions sur keybuzz-infra) pourrait, apres chaque merge sur main, verifier qu'une fois le manifest pulled cote bastion, kubectl diff -f retourne vide sur les manifests modifies. Cela alerterait immediatement en cas de divergence runtime <-> manifest.
4. Cas Outbound Worker : pas dans le scope de cette phase, mais le namespace keybuzz-api-{dev,prod} heberge aussi keybuzz-outbound-worker (image v3.5.165-escalation-flow-*). Cette image est differente de l'image API mais reste dans le meme namespace. Il faudrait a un moment verifier si OW a aussi un drift last-applied (hors scope KEY-295).

---

## 16. Phrase cible finale

GITOPS DRIFT RECONCILED - BASTION CLONE ALIGNED ON origin/main HEAD eeae935 - 4 DEPLOYMENTS (API DEV+PROD, CLIENT DEV+PROD) NOW HAVE runtime image == manifest image == last-applied image - NO POD RESTART - NO IMAGE CHANGE - NO BUILD - NO kubectl set image / set env / patch / edit USED - NO git reset / git clean USED - NO DB / STRIPE / BILLING / TRACKING / CAPI DRIFT - BACKEND / OUTBOUND-WORKER / WEBSITE / ADMIN STRICTLY UNCHANGED - KEY-263 / AS.1 NOW READY TO RESUME - KEY-295 READY TO CLOSE.

STOP

---

## Rapport

keybuzz-infra/docs/PH-INFRA-T8.12AR5-GITOPS-DRIFT-RECONCILIATION-01.md
