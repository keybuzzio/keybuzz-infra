# PH61 — Marketplace Intelligence Engine

> Date : 2026-03-01
> Auteur : Cursor CE
> Environnement : DEV
> Image : `v3.5.71-ph61-marketplace-intelligence-dev`
> Rollback : `v3.5.70-ph60-decision-calibration-dev`

---

## Objectif

Fournir a l'IA un contexte specifique a chaque marketplace pour adapter ses reponses aux regles, risques d'escalade et politiques de chaque plateforme.

PH61 est une couche de **contexte marketplace**, pas de decision SAV.

---

## Profils marketplace

### AMAZON (`AMAZON_BUYER_PROTECTION`)
- **Escalation de base** : HIGH
- **Guideline** : BE_CONCILIATORY
- **Risque** : A-to-Z claims, metrics vendeur, auto-refund Amazon
- **Actions restreintes** : deny claim, blame customer, ignore delivery, delay > 24h, challenge credibility

### OCTOPIA (`OCTOPIA_STANDARD`)
- **Escalation de base** : MEDIUM
- **Guideline** : INVESTIGATE_FIRST (SUPPLIER_PATH_FIRST si defaut produit)
- **Risque** : SLA 48-72h, modere
- **Actions restreintes** : auto-refund sans investigation, bypass garantie

### FNAC/DARTY (`FNAC_DARTY_STANDARD`)
- **Escalation de base** : MEDIUM
- **Guideline** : STANDARD_PROCEDURE
- **Risque** : Processus retour structure
- **Actions restreintes** : auto-refund sans approbation, bypass retour

### MIRAKL (`MIRAKL_STANDARD`)
- **Escalation de base** : MEDIUM
- **Guideline** : STANDARD_PROCEDURE
- **Actions restreintes** : bypass process plateforme

### UNKNOWN (`GENERIC_ECOMMERCE`)
- **Escalation de base** : LOW
- **Confidence** : 0.5 (bloc prompt non injecte)

---

## Ajustement dynamique du risque

Le risque d'escalade est ajuste selon le contexte :

| Signal | Effet |
|---|---|
| REFUND_DEMAND / CHARGEBACK_THREAT | +1 niveau |
| LEGAL_THREAT | CRITICAL immediatement |
| Fraud HIGH | +1 niveau |
| Decision HUMAN_REQUIRED | +1 niveau |
| Amazon + intent DELIVERY | +1 niveau |

---

## Position dans le pipeline

```
PH55 Fraud Pattern
PH60 Decision Calibration
PH61 Marketplace Intelligence ← NOUVEAU
PH56 Delivery Intelligence
PH57 Supplier/Warranty
PH58 Conversation Memory
PH59 Context Compression
```

---

## Bloc prompt (exemple Amazon)

```
=== MARKETPLACE INTELLIGENCE (PH61) ===
Marketplace: AMAZON
Policy profile: AMAZON_BUYER_PROTECTION
Escalation risk: CRITICAL
Response guideline: BE_CONCILIATORY
Confidence: 90%

Guidelines:
- Amazon strongly favors buyers in A-to-Z claims — avoid confrontation.
- Ask for evidence politely, never demand it.
- Avoid promising refund unless authorized — Amazon may auto-refund.
- Respond within 24h to avoid negative seller metrics.
- Never blame Amazon logistics even if FBA.
- A-to-Z claim risk increases if customer feels ignored or dismissed.

Restricted actions:
- deny claim outright
- blame customer
- ignore delivery issue
- delay response beyond 24h
- make empty promises
- challenge buyer credibility
=== END MARKETPLACE INTELLIGENCE ===
```

---

## Tests

15 tests, 43 assertions — **43/43 PASS**

| Test | Scenario | Resultat |
|---|---|---|
| T1 | Amazon FR marketplace ID | PASS |
| T2 | Amazon + refund demand → CRITICAL | PASS |
| T3 | Amazon + delivery intent → elevated | PASS |
| T4 | Octopia channel | PASS |
| T5 | Octopia + defect → supplier path | PASS |
| T6 | Octopia delivery claim | PASS |
| T7 | Unknown marketplace | PASS |
| T8 | Amazon DE marketplace ID | PASS |
| T9 | Legal threat → CRITICAL any marketplace | PASS |
| T10 | Fraud HIGH escalates risk | PASS |
| T11 | HUMAN_REQUIRED escalates risk | PASS |
| T12 | Fnac channel | PASS |
| T13 | Prompt block structure | PASS |
| T14 | Prompt block empty for UNKNOWN | PASS |
| T15 | Empty context → stable | PASS |

---

## Non-regression

| Couche | Impact |
|---|---|
| PH41-PH60 | Aucun — PH61 lit les resultats en aval |
| PH49 Refund Protection | Aucun |
| PH45 Decision Tree | Aucun |
| PH60 Decision Calibration | Aucun |
| KBActions | 0 impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.70-ph60-decision-calibration-dev -n keybuzz-api-dev
```

---

## Cout

| Metrique | Valeur |
|---|---|
| Appels LLM | 0 |
| Impact KBActions | 0 |
| Lignes de code | 322 (service) |
