# PH66 — Self-Protection Layer (AI Response Safety Gate)

> Date : 2026-03-01
> Phase : PH66
> Environnement : DEV

---

## Objectif

Couche finale de securite qui analyse la reponse generee par le LLM, detecte les formulations dangereuses et les corrige/neutralise avant envoi au client.

PH66 agit **uniquement sur la reponse finale**, pas sur le prompt ni les couches precedentes.

---

## Position dans le pipeline

```
PH41-PH65 → Engines pre-LLM (prompt enrichment)
     ↓
   LLM Response
     ↓
parseLLMResponse()
     ↓
PH66 Self-Protection Layer  ← analyse + correction
     ↓
Response finale envoyee
```

---

## Regles de detection (12)

### Regles pattern (Phase 1)

| # | Rule ID | Detection | Action | Severite |
|---|---------|-----------|--------|----------|
| R1 | `direct_refund` | "je vais vous rembourser", "remboursement immediat" | Remplace par proposition procedure | HIGH |
| R2 | `refund_commitment` | "vous serez rembourse", "nous vous rembourserons" | Neutralise formulation | MEDIUM |
| R3 | `fault_admission` | "c'est notre faute", "nous sommes responsables" | Formulation neutre | HIGH |
| R4 | `warranty_guarantee` | "la garantie prendra en charge" | "verifier conditions garantie" | MEDIUM |
| R5 | `carrier_blame` | "le transporteur est responsable" | "investiguer avec le transporteur" | MEDIUM |
| R6 | `fraud_validation` | "pas besoin de preuve", "sans verification" | **BLOQUE** | HIGH |
| R11 | `contradiction` | Remboursement + investigation simultanes | Signal contradiction | MEDIUM |
| R12 | `aggressive_tone` | "vous devez comprendre", "vous avez tort" | Ton neutre | MEDIUM |

### Regles contextuelles (Phase 2 — prioritaire)

| # | Rule ID | Condition | Action | Severite |
|---|---------|-----------|--------|----------|
| R7 | `refund_high_value` | Remboursement + orderValue > 200 | Investigation redirect | HIGH |
| R8 | `refund_risky_customer` | Remboursement + customerRisk RISKY/HIGH | Verification redirect | HIGH |
| R9 | `refund_defect_no_evidence` | Remboursement + defaut + pas de preuve | Demande photo | MEDIUM |
| R10 | `refund_delivery_unconfirmed` | Remboursement + livraison non confirmee perdue | Investigation transporteur | MEDIUM |

### Ordre d'execution

1. **Bloc check** : detection patterns bloquants (fraud_validation) → BLOCK immediat
2. **Context rules** : appliquees en priorite sur le texte original (plus specifiques)
3. **Pattern rules** : appliquees sur le texte deja context-modifie (generiques)

---

## Exemples avant/apres

### Remboursement direct
- **Avant** : "Je vais vous rembourser le montant total de votre commande."
- **Apres** : "Nous allons examiner votre demande et vous proposer la meilleure solution."

### Aveu de faute
- **Avant** : "C'est notre faute si le colis n'est pas arrive."
- **Apres** : "Nous comprenons votre situation et nous allons faire le necessaire."

### Haute valeur + remboursement
- **Avant** : "Nous allons proceder au remboursement de votre commande." (500 EUR)
- **Apres** : "Nous allons examiner votre dossier en detail avant de determiner la meilleure resolution."

### Defaut sans preuve
- **Avant** : "Nous allons proceder au remboursement suite au defaut du produit."
- **Apres** : "Pourriez-vous nous envoyer des photos du produit afin que nous puissions evaluer la situation."

### Validation fraude
- **Avant** : "Pas besoin de preuve, nous allons vous rembourser."
- **Apres** : **[BLOQUE]** — reponse non envoyee

---

## Output

```json
{
  "safeResponse": "...",
  "modifications": [
    { "rule": "direct_refund", "original": "je vais vous rembourser", "replacement": "examiner votre demande" }
  ],
  "blocked": false,
  "protectionSignals": ["direct_refund_promise"],
  "riskLevel": "HIGH"
}
```

---

## decisionContext

```json
{
  "selfProtection": {
    "riskLevel": "HIGH",
    "modifications": [...],
    "protectionSignals": [...],
    "blocked": false
  }
}
```

---

## Endpoint debug

`GET /ai/self-protection?tenantId=xxx&response=texte_encode`

- Aucun appel LLM
- Aucun debit KBActions
- Retourne : responseBefore, responseAfter, modifications, riskLevel, signals

---

## Tests

12 tests, 38 assertions — tous passes.

| Test | Scenario | Resultat |
|------|----------|----------|
| T1 | Remboursement direct | Corrige — PASS |
| T2 | Aveu de faute | Neutralise — PASS |
| T3 | Blame transporteur | Neutralise — PASS |
| T4 | Refund + haute valeur | Investigation — PASS |
| T5 | Refund + client risque | Verification — PASS |
| T6 | Refund + defaut sans preuve | Demande photo — PASS |
| T7 | Ton agressif | Reformule — PASS |
| T8 | Reponse normale | Aucune modif — PASS |
| T9 | Validation fraude | BLOQUE — PASS |
| T10 | Garantie promise | Corrige — PASS |
| T11 | Delivery non confirmee | Investigation — PASS |
| T12 | Reponse vide | No crash — PASS |

---

## Non-regression

- Zero appel LLM supplementaire
- Zero impact KBActions
- PH41-PH65 intacts (PH66 agit uniquement post-LLM)
- Compilation TypeScript : zero erreur

---

## Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/services/selfProtectionEngine.ts` | **CREE** — moteur de protection |
| `src/modules/ai/ai-assist-routes.ts` | Import + post-LLM gate sur suggestions + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.75-ph65-escalation-intelligence-dev -n keybuzz-api-dev
```

---

## Image DEV

- Tag : `v3.5.76-ph66-self-protection-dev`
- Rollback : `v3.5.75-ph65-escalation-intelligence-dev`
