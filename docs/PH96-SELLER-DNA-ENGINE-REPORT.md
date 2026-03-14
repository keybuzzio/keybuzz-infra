# PH96 — Seller DNA / Policy Memory Engine — Rapport

> Date : 14 mars 2026
> Auteur : Agent Cursor
> Environnement : DEV → PROD
> Image : `v3.5.97-ph96-seller-dna-dev` / `v3.5.97-ph96-seller-dna-prod`
> Rollback : `v3.5.96-ph95-global-learning-dev` / `v3.5.96-ph95-global-learning-prod`

---

## 1. Objectif

Apprendre le style réel de gestion SAV de chaque vendeur pour que l'IA devienne fidèle au comportement du vendeur, pas seulement intelligente.

## 2. Profil Seller DNA

| Dimension | Valeurs possibles | Signification |
|---|---|---|
| refundTolerance | LOW / MEDIUM / HIGH | Accepte facilement les remboursements ? |
| warrantyPreference | LOW / MEDIUM / HIGH | Préfère la garantie fournisseur ? |
| evidenceRequirement | LOW / MEDIUM / HIGH | Exige des preuves avant action ? |
| escalationStyle | EARLY / BALANCED / LATE | Escalade vers humain rapidement ? |
| abuseSensitivity | LOW / MEDIUM / HIGH | Sévère face aux clients abusifs ? |
| valueSensitivity | LOW / MEDIUM / HIGH | Sensible à la valeur des commandes ? |

## 3. Classifications vendeur

| Classification | Condition |
|---|---|
| WARRANTY_FIRST_SELLER | warrantyRate > refundRate × 2 et warrantyRate > 20% |
| REFUND_FIRST_SELLER | refundRate > 30% |
| INVESTIGATION_FIRST_SELLER | investigationRate > 40% |
| HIGH_CONTROL_SELLER | escalationRate > 25% et refundRate < 15% |
| CUSTOMER_FIRST_SELLER | refundRate > 20% et escalationRate < 10% |
| BALANCED_SELLER | fallback par défaut |

## 4. Sources de données

| Table | Données extraites |
|---|---|
| `conversation_learning_events` | human_final_action, ai_suggested_action → résolutions choisies |
| `ai_execution_audit` | workflow_stage, carrier/supplier/return actions → patterns opérationnels |

Les deux sources sont fusionnées pour calculer les métriques globales du vendeur.

## 5. Données réelles DEV (ecomlg-001)

```json
{
  "classification": "INVESTIGATION_FIRST_SELLER",
  "profile": {
    "refundTolerance": "LOW",
    "warrantyPreference": "LOW",
    "evidenceRequirement": "HIGH",
    "escalationStyle": "EARLY",
    "abuseSensitivity": "LOW",
    "valueSensitivity": "HIGH"
  },
  "behaviorMetrics": {
    "refundRate": 0.07,
    "warrantyRate": 0.07,
    "investigationRate": 0.71,
    "replacementRate": 0,
    "escalationRate": 0.36
  },
  "learningSignals": {
    "totalCases": 14,
    "refunds": 1,
    "warranties": 1,
    "investigations": 10,
    "replacements": 0,
    "escalations": 5
  },
  "confidence": 0.65
}
```

Interprétation : eComLG privilégie l'investigation (71%), escalade tôt (36%), rembourse très rarement (7%).

## 6. Position pipeline

```
PH92 Marketplace Policy
PH96 Seller DNA          ← nouveau
PH90 Cost Awareness
PH91 Buyer Reputation
PH93 Customer Patience
PH94 Resolution Cost Optimizer
...
LLM
```

## 7. Injection prompt

```
=== SELLER DNA ENGINE (PH96) ===
Seller classification: INVESTIGATION_FIRST_SELLER
Refund tolerance: LOW
Warranty preference: LOW
Evidence requirement: HIGH
Escalation style: EARLY
...
Guidance:
- Align suggestions with seller's investigation first seller profile
- Avoid suggesting refund unless absolutely necessary
- Request evidence before proceeding with resolution
=== END SELLER DNA ENGINE ===
```

## 8. Decision context

```json
{
  "sellerDNA": {
    "classification": "INVESTIGATION_FIRST_SELLER",
    "refundTolerance": "LOW",
    "warrantyPreference": "LOW",
    "evidenceRequirement": "HIGH",
    "confidence": 0.65
  }
}
```

## 9. Endpoints

| Route | Description |
|---|---|
| `GET /ai/seller-dna` | DNA complet (profile, metrics, signals, classification) |
| `GET /ai/seller-dna/profile` | Classification et profile uniquement |
| `GET /ai/seller-dna/metrics` | Métriques comportementales uniquement |

Paramètre requis : `tenantId`

## 10. Résultats tests

```
25 PASS / 0 FAIL / 25 TESTS / 61 ASSERTIONS
```

| Test | Description | Résultat |
|---|---|---|
| T1-T2 | Structure complète, tenantId | PASS |
| T3 | Classification valide | PASS |
| T4-T5 | Profile complet, enums valides | PASS |
| T6 | Metrics dans [0,1] | PASS |
| T7 | Signals non-négatifs | PASS |
| T8 | Confidence dans [0.30, 0.95] | PASS |
| T9 | Unknown tenant → BALANCED fallback | PASS |
| T10-T11 | Endpoints profile et metrics | PASS |
| T12-T13 | Validation tenantId et auth | PASS |
| T14-T15 | Idempotence, source valide | PASS |
| T16-T17 | Fallback confidence et profile | PASS |
| T18-T23 | Non-régression PH91-PH95 + health | PASS |
| T24-T25 | Metrics et signals keys complets | PASS |

## 11. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.96-ph95-global-learning-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.96-ph95-global-learning-prod -n keybuzz-api-prod
```

## 12. Fichiers

| Fichier | Action |
|---|---|
| `src/services/sellerDNAEngine.ts` | CRÉÉ |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIÉ (import, pipeline, prompt, context) |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIÉ (3 endpoints PH96) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | MODIFIÉ |
| `keybuzz-infra/docs/PH96-SELLER-DNA-ENGINE-REPORT.md` | CRÉÉ |
| `scripts/ph96-tests.sh` | CRÉÉ |
