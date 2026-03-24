# PH98 — AI Quality Scoring Engine + DB Routing Audit

> Date : 16 mars 2026
> Phase : PH98
> Auteur : Cursor Agent
> Statut : **COMPLETE (DEV)** — En attente validation PROD

---

## 1. Vue d'Ensemble

PH98 introduit deux briques :

1. **AI Quality Scoring Engine** — Evaluation de la qualite des decisions IA SAV (observabilite pure)
2. **DB Routing Audit** — Verification que toutes les connexions PostgreSQL passent par HAProxy

---

## 2. AI Quality Scoring Engine

### 2.1 Fichier principal

`keybuzz-api/src/services/aiQualityScoringEngine.ts`

### 2.2 Fonction principale

```typescript
computeAiQualityScore(input: QualityScoringInput): AiQualityScoreResult
```

### 2.3 Retour

```json
{
  "qualityScore": 0.87,
  "confidenceScore": 0.81,
  "riskScore": 0.12,
  "decisionConsistency": "HIGH",
  "issuesDetected": [],
  "signalsUsed": ["policy_alignment", "cost_efficiency", "fraud_protection", ...],
  "dimensions": [
    { "dimension": "policy_alignment", "score": 0.92, "weight": 0.20, "issues": [], "signals": [...] },
    ...
  ],
  "timestamp": "2026-03-16T07:15:00.000Z"
}
```

### 2.4 Les 8 dimensions scorees

| Dimension | Poids | Sources |
|---|---|---|
| `policy_alignment` | 0.20 | PH41 SAV Policy, PH44 Tenant Policy, PH45 Decision Tree |
| `cost_efficiency` | 0.15 | PH90 Cost Awareness, PH94 Resolution Cost Optimizer |
| `fraud_protection` | 0.15 | PH47 Customer Risk, PH49 Refund Protection, PH91 Buyer Reputation |
| `buyer_context` | 0.10 | PH91 Buyer Reputation, PH93 Customer Patience, PH97 Multi-Order |
| `seller_strategy` | 0.10 | PH96 Seller DNA, PH50 Merchant Behavior, PH52 Adaptive Response |
| `marketplace_compliance` | 0.10 | PH92 Marketplace Policy |
| `escalation_logic` | 0.10 | PH65 Escalation (nextBestStep, allowed/forbidden actions, missing signals) |
| `autopilot_safety` | 0.10 | PH76 SAV confidence, decision confidence, refund guardrails |

### 2.5 Scores agreges

| Score | Calcul |
|---|---|
| `qualityScore` | Moyenne ponderee des 8 dimensions |
| `riskScore` | Moyenne inverse des dimensions risk-related (fraud, autopilot, marketplace, escalation) |
| `confidenceScore` | Basee sur le nombre de signaux, la couverture dimensionnelle, et les issues |
| `decisionConsistency` | Ecart-type des scores : HIGH (<0.10 et avg>0.6), MEDIUM (<0.18), LOW (>0.18) |

### 2.6 Integration dans decisionContext

Apres le calcul du decisionContext dans `/ai/assist`, PH98 ajoute automatiquement :

```json
{
  "aiQualityScore": {
    "qualityScore": 0.89,
    "riskScore": 0.07,
    "confidenceScore": 0.81,
    "decisionConsistency": "HIGH"
  }
}
```

Le scoring est **non-bloquant** : en cas d'erreur, un `console.warn` est emis et le flux normal continue.

### 2.7 Endpoint debug

```
GET /ai/quality-score?tenantId=xxx&conversationId=yyy
Header: X-User-Email (requis)
```

Recupere le dernier `decision_context` de `ai_actions_ledger` pour la conversation et calcule le score.

---

## 3. DB Routing Audit

### 3.1 Resultat

**11 PASS / 0 FAIL** — Toutes les connexions DB passent par le proxy HAProxy.

### 3.2 Variables d'environnement verifiees

| Service | Variable | Valeur | Statut |
|---|---|---|---|
| keybuzz-api PROD | PGHOST | 10.0.0.10 | PASS |
| keybuzz-api DEV | PGHOST | 10.0.0.10 | PASS |
| keybuzz-backend PROD | DATABASE_URL | ...@10.0.0.10:5432/keybuzz_backend_prod | PASS |
| keybuzz-backend PROD | PGHOST | 10.0.0.10 | PASS |
| keybuzz-backend PROD | PRODUCT_DATABASE_URL | ...@10.0.0.10:5432/keybuzz_prod | PASS |
| keybuzz-backend DEV | DATABASE_URL | ...@10.0.0.10:5432/keybuzz_backend | PASS |
| keybuzz-backend DEV | PGHOST | 10.0.0.10 | PASS |
| keybuzz-backend DEV | PRODUCT_DATABASE_URL | ...@10.0.0.10:5432/keybuzz | PASS |
| outbound-worker PROD | PGHOST | 10.0.0.10 | PASS |
| amazon-orders-worker PROD | DATABASE_URL | ...@10.0.0.10 | PASS |
| amazon-items-worker PROD | DATABASE_URL | ...@10.0.0.10 | PASS |

### 3.3 pg_stat_activity

| Source | Type | Connexions |
|---|---|---|
| 10.0.0.11 | PROXY (HAProxy) | 2 |
| 10.0.0.12 | PROXY (HAProxy) | 5 |
| local | Patroni interne | 16 |

**Aucune connexion directe depuis les pods vers les noeuds Patroni (10.0.0.120/121/122/123).**

### 3.4 Guardrail

Script cree : `scripts/db-routing-check.sh`

Verifie :
1. DATABASE_URL pointe vers 10.0.0.10
2. PRODUCT_DATABASE_URL pointe vers 10.0.0.10
3. PGHOST pointe vers 10.0.0.10
4. pg_stat_activity ne montre aucune connexion directe aux noeuds Patroni

---

## 4. Tests

### 4.1 Tests unitaires (ph98-tests.ts)

**20 tests / 66 assertions**

| Test | Description | Resultat |
|---|---|---|
| 1 | Full context — structure valide | PASS |
| 2 | Scores dans [0, 1] | PASS |
| 3 | Full context → high quality (>= 0.7) | PASS |
| 4 | Full context → low risk (<= 0.3) | PASS |
| 5 | Full context → HIGH consistency | PASS |
| 6 | 8 dimensions scorees | PASS |
| 7 | Noms des dimensions corrects | PASS |
| 8 | Signals utilises | PASS |
| 9 | Empty context → degraded scores | PASS |
| 10 | Empty context → issues detectees | PASS |
| 11 | Risky context → low quality | PASS |
| 12 | Risky context → high risk | PASS |
| 13 | Risky context → LOW/MEDIUM consistency | PASS |
| 14 | Anti-patterns → policy alignment penalty | PASS |
| 15 | Missing signals → escalation penalty | PASS |
| 16 | Risky customer → fraud protection penalty | PASS |
| 17 | Critical profitability → cost efficiency penalty | PASS |
| 18 | Weights sum to 1.0 | PASS |
| 19 | Each dimension score in [0, 1] | PASS |
| 20 | Full > risky quality differential | PASS |

### 4.2 Tests runtime (DEV)

| Test | Resultat |
|---|---|
| /health → 200 OK | PASS |
| /ai/quality-score → 200 | PASS |
| qualityScore retourne | PASS |
| riskScore retourne | PASS |
| 8 dimensions retournees | PASS |
| Image = v3.5.99-ph98-ai-quality-score-dev | PASS |
| Pod Running, 0 restarts | PASS |

### 4.3 DB Routing

| Test | Resultat |
|---|---|
| 11 variables d'env verifiees | 11 PASS |
| pg_stat_activity clean | PASS |

---

## 5. Non-regression

| Endpoint | Statut |
|---|---|
| `/health` | 200 OK |
| `/ai/quality-score` (nouveau) | 200 OK |
| Aucun impact sur `/ai/assist` | Confirme (scoring non-bloquant, try/catch) |
| PH41 → PH97 | Aucune modification du code metier IA |
| KBActions | Aucun cout (PH98 = pure computation) |

---

## 6. Fichiers modifies

| Fichier | Action |
|---|---|
| `src/services/aiQualityScoringEngine.ts` | **NOUVEAU** — moteur de scoring |
| `src/modules/ai/ai-policy-debug-routes.ts` | Import + endpoint GET /ai/quality-score |
| `src/modules/ai/ai-assist-routes.ts` | Import + integration decisionContext.aiQualityScore |
| `src/tests/ph98-tests.ts` | **NOUVEAU** — suite de tests |
| `scripts/db-routing-check.sh` | **NOUVEAU** — guardrail DB routing |
| `scripts/ph98-db-routing-audit.sh` | **NOUVEAU** — audit complet DB |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image mise a jour |

---

## 7. Image DEV

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.99-ph98-ai-quality-score-dev
```

**Rollback** :
```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.98-ph97-multi-order-context-dev -n keybuzz-api-dev
```

---

## 8. Caracteristiques PH98

- **Zero appel LLM** : pure computation
- **Zero impact KBActions** : aucun debit
- **Non-bloquant** : erreurs du scoring n'affectent pas la reponse IA
- **100% observabilite** : score, dimensions, issues, signals — tout est expose
- **Prepare PH99** : le quality score servira de signal d'entree pour le Self-Improvement Loop
