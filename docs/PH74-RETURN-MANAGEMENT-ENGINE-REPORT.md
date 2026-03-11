# PH74 — Return Management Engine

> Date : 1er mars 2026
> Auteur : Agent Cursor (CE)
> Environnement : DEV uniquement (PROD sur validation Ludovic)

---

## 1. Objectif

PH74 structure et prépare les cas de retour produit. Il évalue l'éligibilité, détecte les données manquantes, distingue retour simple vs sensible, et produit un plan d'action retour exploitable.

PH74 ne crée **aucun retour réel** — il prépare uniquement le plan.

---

## 2. Architecture

### Fichier créé
- `src/services/returnManagementEngine.ts` (~290 lignes)

### Fonctions exportées
- `buildReturnManagementPlan(context)` — calcul du plan retour
- `buildReturnManagementBlock(result)` — formatage pour injection prompt LLM

---

## 3. Scénarios détectés (8)

| Scénario | Description | Éligibilité |
|---|---|---|
| `RETURN_NOT_APPLICABLE` | Retour non pertinent | NOT_APPLICABLE |
| `RETURN_INFORMATION_REQUIRED` | Informations manquantes | PARTIAL |
| `RETURN_READY` | Retour prêt | READY |
| `RETURN_BLOCKED_MISSING_DATA` | Données insuffisantes | BLOCKED |
| `LOW_VALUE_SIMPLIFIED_RETURN` | Procédure simplifiée faible valeur | READY |
| `HIGH_VALUE_SUPERVISED_RETURN` | Supervision haute valeur | REVIEW_REQUIRED |
| `DEFECT_RETURN_WITH_PROOF` | Défaut confirmé avec preuve | READY |
| `RETURN_REVIEW_REQUIRED` | Validation humaine requise | REVIEW_REQUIRED |

---

## 4. Types de retour (5)

| Type | Usage |
|---|---|
| `STANDARD_RETURN` | Retour classique |
| `SIMPLIFIED_RETURN` | Faible valeur, procédure allégée |
| `SUPERVISED_RETURN` | Haute valeur ou risqué |
| `DEFECT_RETURN` | Défaut produit avec preuve |
| `NOT_APPLICABLE` | Pas de retour |

---

## 5. Règles de sécurité

| Niveau | Déclencheurs |
|---|---|
| `SAFE` | Retour standard, faible valeur |
| `REVIEW_REQUIRED` | Haute valeur, fraude medium, supervision |
| `RESTRICTED` | Fraude HIGH, abus HIGH |

---

## 6. Actions recommandées

| Action | Cas |
|---|---|
| `INITIATE_RETURN` | Retour prêt |
| `REQUEST_RETURN_INFORMATION` | Données manquantes |
| `REQUEST_PROOF_PHOTOS` | Défaut sans preuve |
| `ESCALATE_RETURN_REVIEW` | Supervision requise |
| `ROUTE_TO_WARRANTY` | Garantie prioritaire |
| `NO_ACTION` | Pas de retour |

---

## 7. Position dans le pipeline IA

```
PH70 Workflow Orchestration
PH71 Case Autopilot
PH72 Action Execution
PH73 Carrier Integration
PH74 Return Management Engine  ← NOUVEAU
PH67 Knowledge Retrieval → ... → PH59 Context Compression → LLM
PH66 Self Protection
```

---

## 8. Intégration

### ai-assist-routes.ts
- Import de `buildReturnManagementPlan`, `buildReturnManagementBlock`
- Exécution après PH73, avant PH67
- Injection dans `buildSystemPrompt()` via `returnManagementBlock`
- Ajout dans `decisionContext.returnManagement`

### ai-policy-debug-routes.ts
- Endpoint `GET /ai/return-management`
- `pipelineOrder` mis à jour (inclut PH74)
- `pipelineLayers.returnManagement: true`
- `finalPromptSections` inclut `RETURN_MANAGEMENT_ENGINE`

---

## 9. Résultats des tests

| Métrique | Résultat |
|---|---|
| Tests | **17** |
| Assertions | **44** |
| Passed | **44** |
| Failed | **0** |
| TypeScript | **0 erreur** |

### Détail des tests
| # | Scénario | Résultat | Status |
|---|---|---|---|
| T1 | Retour simple | RETURN_READY | PASS |
| T2 | Sans raison | RETURN_INFORMATION_REQUIRED | PASS |
| T3 | Faible valeur | LOW_VALUE_SIMPLIFIED_RETURN | PASS |
| T4 | Haute valeur | HIGH_VALUE_SUPERVISED_RETURN | PASS |
| T5 | Défaut + preuve | DEFECT_RETURN_WITH_PROOF | PASS |
| T6 | Fraude HIGH | RETURN_REVIEW_REQUIRED + RESTRICTED | PASS |
| T7 | Abus HIGH | RETURN_REVIEW_REQUIRED | PASS |
| T8 | Garantie prioritaire | RETURN_NOT_APPLICABLE + WARRANTY | PASS |
| T9 | Données manquantes | RETURN_BLOCKED_MISSING_DATA | PASS |
| T10 | Pas d'intent retour | RETURN_NOT_APPLICABLE | PASS |
| T11 | Anglais | RETURN_READY | PASS |
| T12 | PH72 + RETURN_PROCESS | Cohérent | PASS |
| T13 | Amazon | Valid scenario | PASS |
| T14 | Workflow RETURN_PROCESS | RETURN_READY | PASS |
| T15 | Défaut sans preuve | REQUEST_PROOF_PHOTOS | PASS |
| T16 | Format bloc | Header/footer OK | PASS |
| T17 | Fraude medium | RETURN_REVIEW_REQUIRED | PASS |

---

## 10. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.84-ph73-carrier-integration-dev -n keybuzz-api-dev
```

---

## 11. Tags images

| Env | Tag |
|---|---|
| DEV | `v3.5.85-ph74-return-management-dev` |
| Rollback | `v3.5.84-ph73-carrier-integration-dev` |
