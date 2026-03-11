# PH69 — Prompt Stability Guard

> Date : 11 mars 2026
> Environnement : DEV uniquement
> Version : v3.5.80-ph69-prompt-stability-dev

---

## 1. Objectif

Detecter les contradictions entre couches IA et produire un prompt final stabilise. PH69 est une couche d'arbitrage, pas une couche metier.

## 2. Familles de conflits detectes (10)

| # | Type | Couches | Resolution |
|---|---|---|---|
| 1 | `TONE_RISK_CONFLICT` | customerTone + fraudPattern | Ton adouci mais procedural |
| 2 | `RESOLUTION_ESCALATION_CONFLICT` | resolutionPrediction + escalationIntelligence | Escalation prioritaire |
| 3 | `REFUND_BLOCK_CONFLICT` | refundProtection + resolutionPrediction | Refund bloque |
| 4 | `DELIVERY_INTERPRETATION_CONFLICT` | deliveryIntelligence + customerIntent | Guidance livraison unifiee |
| 5 | `WARRANTY_REFUND_CONFLICT` | supplierWarranty + resolutionPrediction | Garantie prioritaire |
| 6 | `FRAUD_TONE_CONFLICT` | fraudPattern + customerTone | Ton professionnel neutre |
| 7 | `ADAPTIVE_POLICY_CONFLICT` | adaptiveResponse + tenantPolicy | Tenant policy prioritaire |
| 8 | `MEMORY_DUPLICATION_CONFLICT` | conversationMemory + evidenceIntelligence | Eviter repetition |
| 9 | `MARKETPLACE_GUIDELINE_CONFLICT` | marketplaceIntelligence + customerTone | Marketplace policy prioritaire |
| 10 | `SELF_PROTECTION_FINAL_CONFLICT` | selfProtection + resolutionPrediction | Minimiser reecritures |

## 3. Ordre de priorite

```
1. SelfProtection
2. RefundProtection
3. DecisionCalibration
4. EscalationIntelligence
5. MarketplaceIntelligence
6. FraudPattern / AbusePattern
7. DeliveryIntelligence / SupplierWarranty
8. DecisionTree
9. MerchantBehavior / AdaptiveResponse / Tone / Emotion
10. ResolutionPrediction
11. KnowledgeRetrieval / ConversationMemory
```

## 4. Stability Score

```
score = 1.0 - (nb_conflits x 0.07)
min = 0.30
```

| Conflits | Score |
|---|---|
| 0 | 1.00 |
| 1 | 0.93 |
| 2 | 0.86 |
| 3 | 0.79 |
| 5+ | 0.65 |

## 5. Position pipeline

```
... PH67 Knowledge Retrieval
PH69 Prompt Stability Guard   ← nouveau
const messages (buildSystemPrompt)
LLM
PH66 Self-Protection (post-LLM)
```

## 6. Prompt block

```
=== PROMPT STABILITY GUARD ===
Stability score: 0.86

Resolved conflicts:
- REFUND_BLOCK_CONFLICT: refund_blocked_by_protection
- TONE_RISK_CONFLICT: tone_softened_but_procedural

Priority guidance:
- do not mention refund
- prefer investigation or warranty path
- keep professional and non-accusatory wording
=== END PROMPT STABILITY GUARD ===
```

## 7. Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/services/promptStabilityGuard.ts` | **Nouveau** — 10 regles, scoring, guidance |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline block + buildSystemPrompt + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Import + endpoint debug |

## 8. Tests

```
Tests: 15 | Assertions: 34 | PASS: 34 | FAIL: 0
RESULT: ALL PASS
```

| # | Test | Resultat |
|---|---|---|
| T1 | Tone empathique + fraud HIGH | TONE_RISK_CONFLICT — PASS |
| T2 | Refund + protection active | REFUND_BLOCK_CONFLICT — PASS |
| T3 | Warranty + human review | RESOLUTION_ESCALATION — PASS |
| T4 | Photo deja demandee | MEMORY_DUPLICATION — PASS |
| T5 | Adaptive vs tenant policy | ADAPTIVE_POLICY — PASS |
| T6 | Amazon + ton ferme | MARKETPLACE_GUIDELINE — PASS |
| T7 | Delivery shipped + delay | DELIVERY_INTERPRETATION — PASS |
| T8 | Abuse HIGH + frustration | TONE_RISK — PASS |
| T9 | Warranty + refund prediction | WARRANTY_REFUND — PASS |
| T10 | Contexte propre | 0 conflits, score 1.0 — PASS |
| T11 | Conflits multiples | Score <= 0.80 — PASS |
| T12 | Self-protection high + refund | SELF_PROTECTION_FINAL — PASS |
| T13 | Fraud HIGH + empathique | FRAUD_TONE — PASS |
| T14 | Contexte vide | 0 conflits, score 1.0 — PASS |
| T15 | Non-regression KBActions | Aucun impact — PASS |

## 9. Non-regression

TypeScript : 0 erreur. PH41-PH68 intacts. 0 appel LLM. 0 KBActions.

## 10. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.79-ph67b-pipeline-debug-dev -n keybuzz-api-dev
```

---

*Rapport genere le 11 mars 2026 — DEV uniquement.*
