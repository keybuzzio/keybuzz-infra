# PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01

> Date : 2026-05-17
> Linear : KEY-323
> Phase : AS.17.1Q-1B-3D-2A
> Environnement : DEV (keybuzz-client-dev)

## VERDICT

GO Q-1B-3D-2A GHCR ORPHAN CLEANUP COMPLETE

Suppression effective de l'unique orphelin keybuzz-client-dev/ghcr-secret identifie en Q-1B-3D-1. Cleanup execute apres double validation pre-delete (re-verification 5/5 PASS de l'absence de toute reference workload, pod, ServiceAccount et manifest GitOps actif) et apres reception de la phrase exacte Ludovic. Post-delete :

- keybuzz-client-dev/ghcr-secret NotFound, 0 residual cluster-wide
- keybuzz-client-dev/ghcr-cred preserve avec resourceVersion identique au BEFORE snapshot (rv 41700540 inchange = aucune mutation collaterale)
- Deployment keybuzz-client : Available=True, Progressing=True (NewReplicaSetAvailable), replicas 1/1/1/1, generation 1006 = observedGeneration 1006 (aucun rollout declenche)
- Pod keybuzz-client-c95894fb4-skjq2 : Running 1/1, restartCount=0, ready=true, pullSecret=ghcr-cred, age 8h inchange (preuve qu'aucun redeploy n'a eu lieu)
- 0 ImagePullBackOff, 0 ErrImagePull, 0 CreateContainerConfigError
- 0 evenement Warning ou Error sur la fenetre 15m post-delete
- Etat 60s post-delete identique a la baseline immediate

Aucune autre mutation. Aucun docker login/pull/push. Aucune rotation PAT GHCR. Aucune modification manifest. Aucun rollout restart. Aucune valeur secret affichee. PROD intouchee. Harmonisation globale GHCR reste NO GO.

## Scope / hors scope

### Scope strict applique

Une seule mutation cluster autorisee et executee :

```
kubectl -n keybuzz-client-dev delete secret ghcr-secret
```

### Hors scope respecte

- Pas de suppression d'un autre Secret (ghcr-cred preserve, 14 autres ghcr-* intouches dans 14 namespaces)
- Pas de creation de Secret
- Pas de rename / patch / annotate / label
- Pas de modification manifest
- Pas de rollout restart
- Pas de docker login/pull/push
- Pas de gh auth
- Pas de rotation PAT GHCR
- Pas de decode .dockerconfigjson
- Pas de lecture/affichage valeur secret
- Pas de touch PROD
- Pas d'harmonisation globale

## Sources relues

| Source | Sha256 / commit | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-1-KEY-323-GHCR-NAMING-HARMONIZATION-DRYRUN-01.md | cad646d591df1f72e5e59393a953594159bb3176dde8f132db137d5d2df6d57a | OK |
| keybuzz-infra HEAD | 32715c82d19c62e97ca802cbf0cd405c6725c937 | OK ancestor de cette phase |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1B-KEY-323-ORPHANS-CLEANUP-EXEC-01.md | present | OK pattern Q-1B-3B-1B applique |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-1A-KEY-323-ORPHANS-CLEANUP-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3B-0-KEY-323-PROVIDER-MANUAL-DECISIONS-DRYRUN-01.md | present | OK |
| docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3A-KEY-323-PROVIDER-MANUAL-SECRETS-INVENTORY-READONLY-01.md | present | OK |

## Preflight

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host | install-v3 | install-v3 | OK |
| Bastion IPv4 | 46.62.171.61 | 46.62.171.61 | OK |
| IPv6 public present | acceptable (Hetzner standard) | 2a01:4f9:c013:87d6::1 | OK |
| Banned IP 51.159.99.247 | absent | absent | OK |
| keybuzz-infra branch | main | main | OK |
| keybuzz-infra HEAD descendant | 32715c8 | 32715c8 (HEAD exact) | OK |
| keybuzz-infra status | clean | clean | OK |
| keybuzz-client HEAD descendant | f61763a | f61763a (HEAD exact) | OK |
| keybuzz-client branch | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | OK |
| Temp files Q-1B-3D-* | absent | absent | OK |
| Token temp KEY-323 | absent | absent | OK |
| Rapports dependances | 5 PH presents | 5 PH presents | OK |

## BEFORE metadata-only summary

Capture en metadata-only deposee dans /tmp/keybuzz-q1b3d2a-before-metadata.jsonl (mode 600) puis shred en E10 apres redaction du rapport. Aucune valeur .data lue ni journalisee. Verification anti-leak : 0 pattern base64-payload detecte.

| Namespace | Secret | Exists | RV | Keys | Dockerconfig size (b64) | Age (jours) | Verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-client-dev | ghcr-secret | true | 5877360 | 1 (.dockerconfigjson) | 276 | 137 | DELETE_CANDIDATE (orphan strict) |
| keybuzz-client-dev | ghcr-cred | true | 41700540 | 1 (.dockerconfigjson) | 56 | PRESERVE (actif reference) |

Heuristique de seniorite : ghcr-secret plus ancien (137 jours), ghcr-cred plus recent (56 jours) = fossile de l'ancienne convention d'avant alignement client-dev sur le groupe ghcr-cred des microservices.

## Re-verify active/orphan status (5/5 PASS)

| Signal | Expected | Observed | Verdict |
|---|---|---|---|
| Deployment keybuzz-client.imagePullSecrets | [ghcr-cred] | [ghcr-cred] | OK |
| Pods Running/Pending pull_secrets | ghcr-cred | keybuzz-client-c95894fb4-skjq2 Running ghcr-cred | OK |
| Workloads ref ghcr-secret cluster-wide dans client-dev | 0 | 0 | OK |
| Pods ref ghcr-secret dans client-dev | 0 | 0 | OK |
| ServiceAccounts ref ghcr-secret dans client-dev | 0 | 0 | OK |
| Manifests GitOps actifs (hors .bak) ref ghcr-secret dans k8s/keybuzz-client-dev/ | 0 | 0 | OK |
| ghcr-cred a une consommation active (pod Running) | OUI | OUI (pod skjq2) | OK |

## STOP Gate 1 / GO Ludovic

| Item | Statut |
|---|---|
| Phrase exacte attendue | GO DELETE GHCR ORPHAN keybuzz-client-dev/ghcr-secret |
| Phrase exacte recue | identique verbatim |
| Rollback reality affiche | IRRECUPERABLE local, 0 impact runtime (orphan), reconstruction via Ludovic + nouveau PAT |
| Validation plan affiche | E6 absence + ghcr-cred preserve + E7 Deployment Ready + restartCount + ImagePullBackOff + events 15m |

## Delete command exact

| Namespace | Secret | Command | Result | Verdict |
|---|---|---|---|---|
| keybuzz-client-dev | ghcr-secret | kubectl -n keybuzz-client-dev delete secret ghcr-secret | secret "ghcr-secret" deleted (exit 0) | OK |

Aucune autre commande mutation kubernetes / docker / git executee dans cette phase.

## Post-delete absence verification

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| kubectl get secret ghcr-secret -n keybuzz-client-dev | NotFound | NotFound | OK |
| kubectl get secret ghcr-cred -n keybuzz-client-dev | exists | exists rv=41700540 | OK |
| rv ghcr-cred inchange vs BEFORE snapshot | 41700540 | 41700540 | OK (aucune mutation collaterale) |
| Cluster-wide residual scan keybuzz-client-dev/ghcr-secret | 0 | 0 | OK |
| Affichage valeur .dockerconfigjson | jamais | jamais | OK |

## Health validation

| Domain | Expected | Observed | Verdict |
|---|---|---|---|
| Deployment keybuzz-client conditions.Available | True | True (MinimumReplicasAvailable) | OK |
| Deployment keybuzz-client conditions.Progressing | True | True (NewReplicaSetAvailable) | OK |
| Replicas spec / available / ready / updated | 1 / 1 / 1 / 1 | 1 / 1 / 1 / 1 | OK |
| generation = observedGeneration | OUI | 1006 = 1006 | OK (aucun rollout en cours) |
| Pod state | Running 1/1 | Running 1/1 | OK |
| Pod restartCount | 0 (baseline) | 0 (inchange) | OK |
| Pod ready | true | true | OK |
| Pod imagePullSecrets | [ghcr-cred] | [ghcr-cred] | OK |
| Pod age | 8h (preuve absence redeploy) | 8h | OK |
| ImagePullBackOff / ErrImagePull / CreateContainerConfigError | 0 | 0 | OK |
| Events 15m Warning+Error | 0 nouveau | 0 | OK |
| Etat 60s post-delete | identique baseline | identique | OK |

## No fake metrics / no fake events

Aucun appel provider externe. Aucun docker login/pull/push. Aucun gh auth. Aucun webhook. Aucun checkout. Aucun email. Aucun event GA4 / CAPI / TikTok / LinkedIn. Aucun KPI dashboard touche. Aucune metric KeyBuzz creee.

## AI feature parity / anti-regression

N/A direct. Cette phase ne touche ni l'IA, ni l'Inbox, ni les messages, ni les connecteurs marketplace au runtime, ni les commandes, ni le tracking colis, ni les playbooks, ni les escalades, ni l'Agent KeyBuzz, ni l'autopilot, ni le dashboard, ni les metriques derivees, ni LiteLLM, ni billing.

## Cleanup temporary files

| Fichier | Mode | Statut | Verdict |
|---|---|---|---|
| /tmp/keybuzz-q1b3d2a-before-metadata.jsonl | 600 | shred -u -n 3 -z | OK |
| /tmp/keybuzz-q1b3d2a-e1-e4-runner.sh | 644 | shred -u -n 3 -z | OK |
| /tmp/keybuzz-q1b3d2a-* | - | tous absents post-shred | OK |

## Rollback reality

| Aspect | Statut |
|---|---|
| Backup local de la valeur .dockerconfigjson de ghcr-secret | Aucun (by design, prevent exposure) |
| Reconstruction locale possible | NON |
| Reconstruction depuis Vault | NON (les Secrets dockerconfigjson ne sont pas stockes dans Vault, 100% creation manuelle confirme Q-1B-3D-1) |
| Reconstruction depuis manifest GitOps | NON (0 manifest GitOps ne cree de dockerconfigjson, confirme Q-1B-3D-1) |
| Reconstruction operationnelle | OUI via Ludovic : regenerer ou reutiliser GHCR PAT existant + kubectl create secret docker-registry |
| Impact runtime de la non-restauration | NEANT (ghcr-secret etait ORPHAN, 0 consumer, 0 fonction operationnelle perdue) |
| Risque d'avoir besoin de la restauration | TRES FAIBLE (orphan confirme 5/5, aucun consumer documente, age 137 jours sans incident lie a son absence) |

Note importante : la suppression rend la dette structurelle "creation 100% manuelle des dockerconfigjson" plus visible, mais ne l'aggrave pas (le secret restant ghcr-cred est aussi cree manuellement). Cette dette sera traitee dans une phase distincte Q-1B-3D-3 (proposee) si Ludovic l'ouvre.

## Compliance

| Interdit | Evidence | Verdict |
|---|---|---|
| Suppression d'un autre Secret | 1 seule commande kubectl delete executee, sur ghcr-secret uniquement | OK |
| Suppression de ghcr-cred | ghcr-cred preserve avec rv inchange | OK |
| Creation de Secret | 0 kubectl create | OK |
| Rename / patch / annotate / label | 0 commande de ce type | OK |
| Modification manifest | git status infra clean post-action | OK |
| Rollout restart | 0 commande rollout, pod age 8h inchange | OK |
| docker login/pull/push | 0 commande docker | OK |
| gh auth / API call | 0 commande gh | OK |
| Rotation PAT GHCR | 0 action sur ghcr.io | OK |
| Decode .dockerconfigjson | 0 base64 -d, 0 jq sur .data | OK |
| Affichage valeur secret | safety check 0 base64-payload pattern dans snapshot | OK |
| Toucher PROD | 0 commande sur namespace *-prod | OK |
| Harmonisation globale | 14 autres Secrets ghcr-* intouches | OK |
| Bastion incorrect | install-v3 / 46.62.171.61 confirme | OK |
| Path /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ | 0 acces | OK |
| Commit/push sans GO | rapport ecrit puis STOP, aucun commit avant E12+GO | OK |

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
| GitHub PAT GHCR | non touche | non touche | 0 |
| Vault KV PROD | non touche | non touche | 0 |
| Argo CD applications | non touche | non touche | 0 |

## Brouillon Linear KEY-323

Brouillon disponible pour Ludovic, NON poste sans GO separe explicite :

```
KEY-323 - AS.17.1Q-1B-3D-2A GHCR orphan cleanup EXEC

Status: COMPLETE
Scope: DEV uniquement, keybuzz-client-dev

Action effective:
- Suppression d'un (1) Secret dockerconfigjson orphelin: keybuzz-client-dev/ghcr-secret
- Justification: identifie en Q-1B-3D-1 comme ORPHAN strict (0 workload, 0 pod, 0 SA, 0 manifest GitOps actif)
- Age: 137 jours (fossile de l'ancienne convention de nommage)

Garanties preservees:
- keybuzz-client-dev/ghcr-cred (Secret actif) preserve, resourceVersion inchange
- Deployment keybuzz-client Available=True, replicas 1/1/1/1
- Pod keybuzz-client-c95894fb4-skjq2 Running, restartCount=0, age inchange 8h (aucun redeploy)
- 0 ImagePullBackOff, 0 Warning event 15m post-delete

Hors scope respecte:
- Pas d'harmonisation globale GHCR (14 autres Secrets ghcr-* intouches)
- Pas de rotation PAT GHCR
- Pas de modification manifest
- Pas de rollout restart
- PROD intouchee

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1Q-1B-3D-2A-KEY-323-GHCR-ORPHAN-CLEANUP-EXEC-01.md
```

## Gaps restants

1. **Q-1B-3D-2B harmonisation pleine** : NO GO maintenu, requiert decision Ludovic sur option A (ghcr-pull-secret K8s standard) vs option B (ghcr-cred majoritaire 5 renames). Decision differable, recommandee couplee a Q-1B-3D-5 rotation PAT future.
2. **Q-1B-3D-3 (proposee)** : creation GitOps des Secrets dockerconfigjson via Helm chart ou ESO pour cloturer la dette "creation 100% manuelle" (15 secrets restants tous crees a la main).
3. **Q-1B-3D-4 (proposee)** : purge des backup files keybuzz-infra/k8s/ (.bak / .backup / .disabled / .bak-golden) qui polluent les grep.
4. **Q-1B-3D-5 Rotation PAT GHCR** : NO GO maintenu, prerequis Q-1B-3D-2B harmonisation pour reduire surface manipulee.
5. **Q-1B-5A LLM SECRETS DEDUP DRY-RUN** : prerequis Q-1B-5B rotation LLM (3 secrets litellm confus).
6. **Q-1B-3E-inbound-webhook MIGRATION ESO PROD** : divergence DEV/PROD.
7. **Q-1B-3B PROVIDER LOW-RISK** : Stripe TEST + SES + Slack + Ads sub-batched.
8. **Q-1B-3C OAUTH LOGIN, Q-1B-6 MARKETPLACE OAUTH, Q-1B-4 INFRA DIRECT, Q-1B-5B LLM ROTATION, Q-1B-7 ADS-ENCRYPTION STRATEGIC DESIGN, Q-1F-3 VALIDATION CUMULEE** restent dans la file.
9. **AS.17.0 / AS.17.0.1 PROD PROMOTION** : NO GO maintenu tant que tenantGuardPlugin INACTIF (KEY-301 AS.3) non patche.
10. **backfill-scheduler ImagePullBackOff** : hors scope, phase dediee.

## Phrase cible finale

STOP AS.17.1Q-1B-3D-2A - GO Q-1B-3D-2A GHCR ORPHAN CLEANUP COMPLETE. keybuzz-client-dev/ghcr-secret deleted and absent, ghcr-cred remains active with resourceVersion unchanged, Deployment keybuzz-client Available 1/1 with pod age 8h confirming no redeploy triggered, health validation OK, 0 ImagePullBackOff, 0 Warning event, rapport docs-only pret, en attente GO Ludovic commit/push. GHCR harmonization globale et PAT rotation restent NO GO.

STOP
