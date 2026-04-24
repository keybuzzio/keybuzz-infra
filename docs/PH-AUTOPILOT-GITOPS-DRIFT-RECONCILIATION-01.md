# PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01

> Date : 2026-03-01
> Type : Réconciliation GitOps — correction dette process
> Priorité : P0
> Environnements : DEV + PROD

---

## 1. CONSTAT DE DETTE PROCESS

### Origine

Lors de `PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01`, la commande
`kubectl set image` a été utilisée pour promouvoir l'image API PROD, en violation des
règles GitOps KeyBuzz (`deployment-safety.mdc` Règle 4, `process-lock.mdc` §5).

### Preuve dans le rapport précédent

Fichier : `keybuzz-infra/docs/PH-AUTOPILOT-PROMISE-DETECTION-GUARDRAIL-PROD-PROMOTION-01.md`

```
| `kubectl set image` | ✅ `deployment.apps/keybuzz-api image updated` |
```

Le rollback proposé utilisait aussi `kubectl set image` :

```
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.91-autopilot-escalation-handoff-fix-prod -n keybuzz-api-prod
```

### Impact observé

Le manifest GitOps PROD (`e0d3681`) a été correctement mis à jour avec le bon tag image,
mais l'annotation `kubectl.kubernetes.io/last-applied-configuration` était périmée :

- **Attendu** : `v3.5.92-autopilot-promise-detection-guardrail-prod`
- **Observé** : `v3.5.90-autopilot-orderid-prompt-fix-prod`

Cela signifie que les 2 dernières promotions (v3.5.91 et v3.5.92) ont utilisé `kubectl set image`
au lieu de `kubectl apply -f` depuis le manifest, causant la désynchronisation de l'annotation.

---

## 2. ÉTAPE 0 — PREFLIGHT

| Élément | Valeur |
|---|---|
| Repo infra | keybuzz-infra |
| Branche | main |
| HEAD | `e0d3681` |
| Repo clean | ✅ oui (`git status --short` = vide) |
| Commit promotion | `e0d3681` — `GitOps: API PROD → v3.5.92-autopilot-promise-detection-guardrail-prod` |
| Manifest API PROD | `k8s/keybuzz-api-prod/deployment.yaml` |

---

## 3. ÉTAPE 1 — AUDIT MANIFEST GITOPS

| Champ manifest | Valeur | OK |
|---|---|---|
| image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.92-autopilot-promise-detection-guardrail-prod` | ✅ |
| rollback | `v3.5.91-autopilot-escalation-handoff-fix-prod` (commentaire) | ✅ |
| namespace | `keybuzz-api-prod` | ✅ |
| deployment | `keybuzz-api` | ✅ |
| container | `keybuzz-api-jwt` | ✅ |

Aucun changement parasite dans le manifest.

---

## 4. ÉTAPE 2 — AUDIT RUNTIME PROD

| Élément runtime | Valeur | Match manifest ? |
|---|---|---|
| deployment image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.92-autopilot-promise-detection-guardrail-prod` | ✅ |
| pod image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.92-autopilot-promise-detection-guardrail-prod` | ✅ |
| imageID | `sha256:d4a26f468e11c13a7c0db9ba1afcdb1c24709a4e9ae426d433f17d36e3fa92ad` | ✅ |
| generation | 343 | ✅ |
| observedGeneration | 343 | ✅ |
| restarts | 0 | ✅ |
| rollout status | successfully rolled out | ✅ |
| last-applied annotation | `v3.5.90-autopilot-orderid-prompt-fix-prod` | ❌ PÉRIMÉE |
| pod name | `keybuzz-api-76cbcdf96c-hkw76` | — |

**Verdict** : zéro drift fonctionnel (image spec correcte), mais annotation `last-applied-configuration` désynchronisée.

---

## 5. ÉTAPE 3 — DIFF MANIFEST VS CLUSTER

```
kubectl diff -f k8s/keybuzz-api-prod/deployment.yaml
```

**Résultat** : sortie vide, exit code 0

| Diff | Résultat |
|---|---|
| Spec image | ✅ aucun drift |
| Env | ✅ aucun drift |
| Labels | ✅ aucun drift |
| Annotations | annotation `last-applied` périmée (metadata seulement) |
| Drift fonctionnel ? | ❌ NON |

---

## 6. ÉTAPE 4 — RÉCONCILIATION

### Action effectuée

Aucun drift fonctionnel détecté. L'action de réconciliation a visé uniquement la synchronisation
de l'annotation `kubectl.kubernetes.io/last-applied-configuration` :

```bash
cd /opt/keybuzz/keybuzz-infra
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
```

**Résultat** : `deployment.apps/keybuzz-api configured`

### Vérification post-apply

| Vérification | Avant | Après |
|---|---|---|
| generation | 343 | 344 (annotation updated) |
| last-applied image | `v3.5.90-...` | `v3.5.92-autopilot-promise-detection-guardrail-prod` ✅ |
| Pod | `keybuzz-api-76cbcdf96c-hkw76` Running | **même pod**, 0 restarts ✅ |
| Nouveau rollout | — | ❌ NON (aucun pod recréé) |

### Réconciliation DEV (bonus)

Même opération effectuée sur DEV :

```bash
kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
```

- Résultat : `deployment.apps/keybuzz-api configured`
- last-applied synchronisée : `v3.5.92-autopilot-promise-detection-guardrail-dev` ✅
- Pod DEV inchangé, 0 restart ✅

---

## 7. ÉTAPE 5 — DURCISSEMENT RÈGLES CURSOR

### Audit des règles existantes

| Fichier | Mention `kubectl set image` | État |
|---|---|---|
| `deployment-safety.mdc` Règle 4 | "JAMAIS utiliser `kubectl set image`" | ✅ existante |
| `deployment-safety.mdc` Règle 8 | "JAMAIS proposer `kubectl set image` comme rollback" | ✅ existante |
| `process-lock.mdc` §5 | **absente** | ❌ ajoutée |
| `git-source-of-truth.mdc` | non concerné (source code, pas deploy) | — |

### Modification appliquée

Ajout dans `.cursor/rules/process-lock.mdc` §5 (DEPLOIEMENT — LIMITES PAR PHASE) :

**Nouvelle sous-section : "INTERDIT — Commandes impératives Kubernetes"**

Contenu ajouté :
- `kubectl set image` — interdit
- `kubectl set env` — interdit
- `kubectl edit` — interdit
- `kubectl patch` — interdit (sauf réconciliation depuis manifest GitOps)
- Workflow obligatoire : manifest YAML → commit → push → `kubectl apply -f`
- Référence cause : PH-AUTOPILOT-GITOPS-DRIFT-RECONCILIATION-01

Ajout dans la checklist "Après chaque deploy" :
- `kubectl apply -f` depuis le manifest GitOps pour garantir la synchronisation annotation

---

## 8. ÉTAPE 6 — VALIDATION POST-RÉCONCILIATION

| Check | Résultat |
|---|---|
| API health PROD | ✅ HTTP 200 |
| Runtime image PROD | ✅ `v3.5.92-autopilot-promise-detection-guardrail-prod` |
| Manifest image PROD | ✅ `v3.5.92-autopilot-promise-detection-guardrail-prod` |
| last-applied annotation | ✅ `v3.5.92-autopilot-promise-detection-guardrail-prod` |
| Pod restarts | ✅ 0 |
| Backend PROD inchangé | ✅ `v1.0.46-ph-recovery-01-prod` |
| Client PROD inchangé | ✅ `v3.5.81-tiktok-attribution-fix-prod` |
| kubectl diff PROD | ✅ zéro diff |
| kubectl diff DEV | ✅ zéro diff |
| Drift final | ✅ AUCUN |

---

## 9. RÉSUMÉ

| Aspect | État |
|---|---|
| Changement fonctionnel | ❌ AUCUN |
| Build effectué | ❌ AUCUN |
| Rollback effectué | ❌ AUCUN |
| Image modifiée | ❌ NON |
| Drift spec détecté | ❌ NON |
| Drift annotation détecté | ✅ OUI — `last-applied` périmée (v3.5.90 au lieu de v3.5.92) |
| Réconciliation annotation | ✅ `kubectl apply -f` depuis manifest GitOps |
| Nouveau rollout déclenché | ❌ NON |
| Règle Cursor durcie | ✅ `process-lock.mdc` §5 enrichi |
| Validation finale | ✅ runtime = manifest = annotation |

---

## VERDICT

**GITOPS DRIFT RECONCILED — RUNTIME MATCHES MANIFEST — IMPERATIVE DEPLOYMENT DEBT CLOSED**
