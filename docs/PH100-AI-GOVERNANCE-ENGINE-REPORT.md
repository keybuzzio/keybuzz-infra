# PH100 — AI Governance Engine — Rapport

> **Date** : 2026-03-16
> **Environnement** : DEV uniquement
> **Image** : `ghcr.io/keybuzzio/keybuzz-api:v3.6.02-ph100-ai-governance-dev`
> **Rollback** : `v3.6.01-pj-fix-dev`

---

## 1. Objectif

Créer une couche AI Governance Engine centrale qui définit et applique les règles globales de gouvernance IA :
- Niveau d'autonomie autorisé
- Limites de sécurité
- Seuils de confiance minimaux
- Plafonds de risque
- Conditions de blocage automatique

PH100 agit au-dessus de PH66/PH76/PH98/PH99 comme gouvernance centrale.

---

## 2. Dimensions de gouvernance (10)

| # | Dimension | Description | Seuils |
|---|-----------|-------------|--------|
| 1 | `autonomy_level` | Niveau d'autonomie IA autorisé | MANUAL_ONLY → FULL_AUTOPILOT |
| 2 | `confidence_threshold` | Seuil de confiance minimum | 0.75 autopilot / 0.60 suggestion |
| 3 | `risk_ceiling` | Plafond de risque maximum | LOW → CRITICAL |
| 4 | `refund_governance` | Contrôle remboursements | High value + low confidence → review |
| 5 | `escalation_governance` | Escalation humaine obligatoire | High risk → force escalation |
| 6 | `marketplace_governance` | Restrictions marketplace | Compliance risk high → downgrade |
| 7 | `seller_governance` | Politique vendeur | Strict seller → restrict refund |
| 8 | `quality_governance` | Basé PH98 quality score | Score < 0.50 → ASSISTED_ONLY |
| 9 | `self_improvement_governance` | Basé PH99 weak signals | >= 3 signals → ASSISTED_ONLY |
| 10 | `system_safety` | État système global | >= 3 blocking → LOCKED |

---

## 3. Niveaux d'autonomie

| Niveau | Description | Conditions |
|--------|-------------|------------|
| `FULL_AUTOPILOT` | Autonomie complète | Tous les checks pass |
| `LIMITED_AUTOPILOT` | Autopilot avec limites | Défaut si aucune violation |
| `ASSISTED_ONLY` | Suggestions uniquement | Quality < 0.50, risk > 0.60, marketplace risk high |
| `MANUAL_ONLY` | Intervention humaine obligatoire | Fraud + abuse, >= 3 blocking violations |

---

## 4. États de gouvernance

| État | Condition |
|------|-----------|
| `NOMINAL` | 0 blocking, < 3 warnings |
| `DEGRADED` | 0 blocking, >= 3 warnings |
| `RESTRICTED` | 1-2 blocking violations |
| `LOCKED` | >= 3 blocking violations |

---

## 5. Règles appliquées

### Cas 1 : Quality low → ASSISTED
- `qualityScore < 0.50` → `ASSISTED_ONLY`
- Violation `quality_too_low_for_autonomy`

### Cas 2 : Fraud + abuse → MANUAL
- `customerRisk.category == high` ET `buyerReputation.classification == abusive`
- `MANUAL_ONLY` + `force_manual_review`

### Cas 3 : High value refund + low confidence
- `orderValue > 100` ET `confidence < 0.75`
- Violation `high_value_low_confidence_refund`
- Action `require_human_review_for_refund`

### Cas 4 : Seller strict + refund
- `sellerDNA == cost_guardian` ET `refundTolerance == very_low`
- Action `restrict_refund_autonomy`

### Cas 5 : Escalation forced
- `customerPatience.escalationRisk == high|critical`
- Action `force_human_escalation`

### Cas 6 : Marketplace compliance
- `complianceRisk == high|critical`
- Downgrade autonomie → `ASSISTED_ONLY`

### Cas 7 : Weak signals PH99
- `pipelineWeakSignals.length >= 3`
- Downgrade autonomie → `ASSISTED_ONLY`

---

## 6. Position dans le pipeline

```
PH41 SAV Policy
PH44 Tenant Policy
PH43 Historical
PH45 Decision Tree
PH46 Response Strategy
PH49 Refund Protection
PH50 Merchant Behavior
PH52 Adaptive Response
PH90 Cost Awareness
PH91 Buyer Reputation
PH92 Marketplace Policy
PH93 Customer Patience
PH94 Resolution Cost Optimizer
PH96 Seller DNA
PH97 Multi-Order Context
PH100 AI Governance ← NOUVEAU (pre-LLM: prompt block)
LLM Call
PH98 Quality Scoring (post-LLM)
PH100 AI Governance (post-LLM: decisionContext enrichment)
Persist to ai_actions_ledger
```

PH100 s'exécute en deux temps :
1. **Pre-LLM** : calcule la gouvernance à partir des signaux disponibles et injecte un bloc dans le prompt système
2. **Post-LLM** : enrichit le `decisionContext` avec les données de gouvernance pour observabilité

---

## 7. Endpoints debug

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/ai/governance?tenantId=X&conversationId=Y` | État complet gouvernance |
| GET | `/ai/governance/limits?tenantId=X` | Limites simplifiées |
| GET | `/ai/governance/eligibility?tenantId=X` | Éligibilité autonomie |

Aucun appel LLM. Aucun coût KBActions.

---

## 8. Intégration decisionContext

```json
{
  "aiGovernance": {
    "autonomyLevelAllowed": "LIMITED_AUTOPILOT",
    "governanceState": "NOMINAL",
    "minimumConfidenceRequired": 0.75,
    "maxAllowedRisk": "LOW",
    "violations": [],
    "actions": []
  }
}
```

---

## 9. Prompt block injecté

```
=== AI GOVERNANCE ENGINE ===
Autonomy allowed: LIMITED_AUTOPILOT
Governance state: NOMINAL
Minimum confidence required: 0.75
Max allowed risk: LOW
=== END AI GOVERNANCE ENGINE ===
```

---

## 10. Tests

| # | Test | Résultat |
|---|------|----------|
| 1 | Empty context → defaults | PASS |
| 2 | Healthy context → NOMINAL | PASS |
| 3 | Quality < 0.50 → ASSISTED | PASS |
| 4 | Fraud + abuse → MANUAL | PASS |
| 5 | High value refund + low confidence | PASS |
| 6 | Strict seller + refund | PASS |
| 7 | Marketplace risk → ASSISTED | PASS |
| 8 | Weak signals → ASSISTED | PASS |
| 9 | Safe context → autopilot | PASS |
| 10 | Prompt block builder | PASS |
| 11 | Escalation forced | PASS |
| 12 | Confidence threshold | PASS |
| 13 | Risk > 0.70 → CRITICAL | PASS |
| 14 | Multi-tenant isolation | PASS |
| 15 | Idempotence | PASS |
| 16 | Limits accessor | PASS |
| 17 | Violations accessor | PASS |
| 18 | Eligibility accessor | PASS |
| 19 | Empty context stable | PASS |
| 20 | Multiple violations → LOCKED | PASS |

**20 tests, 52 assertions, 100% PASS**

---

## 11. Non-régression

| Endpoint | Status |
|----------|--------|
| `/health` | 200 OK |
| `/ai/quality-score` (PH98) | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/governance/limits` (PH100) | 200 OK |
| `/ai/governance/eligibility` (PH100) | 200 OK |

Pipeline PH41 → PH99 intact.

---

## 12. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.01-pj-fix-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 13. Fichiers modifiés

| Fichier | Action |
|---------|--------|
| `src/services/aiGovernanceEngine.ts` | **NOUVEAU** — moteur de gouvernance |
| `src/modules/ai/ai-policy-debug-routes.ts` | Ajout endpoints `/ai/governance*` |
| `src/modules/ai/ai-assist-routes.ts` | Import, prompt block, decisionContext |
| `src/tests/ph100-tests.ts` | **NOUVEAU** — 20 tests |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image mise à jour |

---

## 14. Résumé

PH100 ajoute une couche de gouvernance IA centrale qui :
- Évalue 10 dimensions de gouvernance
- Détermine le niveau d'autonomie autorisé
- Détecte et signale les violations
- Injecte les contraintes dans le prompt LLM
- Persiste l'état dans le decisionContext
- Fournit 3 endpoints debug sans coût

**STOP POINT** — Aucun déploiement PROD. Attente validation.
