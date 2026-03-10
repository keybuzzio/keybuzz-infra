# PH63 — Abuse Pattern Engine

> Date : 2026-03-01
> Auteur : Cursor CE
> Environnement : DEV
> Image : `v3.5.73-ph63-abuse-pattern-dev`
> Rollback : `v3.5.72-ph62-evidence-intelligence-dev`

---

## Objectif

Detecter des patterns d'abus longitudinaux dans l'historique client (180 jours).
Completer PH55 (fraude cas courant) avec une analyse temporelle multi-commandes.

PH63 ne doit JAMAIS :
- Accuser le client
- Refuser automatiquement une demande
- Envoyer un message plus agressif
- Declencher une action punitive

PH63 rend uniquement l'IA plus prudente.

---

## Difference PH55 vs PH63

| | PH55 Fraud Pattern | PH63 Abuse Pattern |
|---|---|---|
| Perimetre | Cas courant | Historique 180 jours |
| Donnees | Message actuel | Conversations + commandes passees |
| Detection | Manipulation, pression | Repetitions, frequences, patterns temporels |
| Sortie | fraudRisk | abuseRisk |

---

## Signaux detectes (10)

| # | Signal | Condition |
|---|---|---|
| 1 | `repeat_non_delivery_across_orders` | >= 2 reclamations "non recu" sur commandes distinctes |
| 2 | `high_refund_frequency` | >= 3 mentions refund ou taux > 30% |
| 3 | `repeated_defect_claims` | >= 2 reclamations "defectueux" |
| 4 | `multi_order_complaint_pattern` | >= 3 commandes differentes avec plainte |
| 5 | `fast_repeat_claims` | < 15 jours entre reclamations, >= 3 conversations |
| 6 | `repeated_aggressive_escalation` | >= 2 mentions legales/agressives |
| 7 | `pattern_refund_after_delivery` | >= 2 cas resolus avec mention remboursement |
| 8 | `mixed_claim_instability` | 3+ types differents (livraison + defaut + refund) |
| 9 | `disproportionate_complaint_rate` | > 40% de commandes avec plainte |
| 10 | `suspicious_high_value_claims` | >= 2 plaintes sur commandes >= 100 EUR |

---

## Scoring

| Niveau | Score | Condition |
|---|---|---|
| LOW | 0-1 | Historique normal |
| MEDIUM | 2-4 | 2-3 signaux moderes |
| HIGH | 5+ | Patterns repetes, multi-commandes, concentration |

Amplificateurs externes : PH47 HIGH_RISK (+1), PH55 fraud HIGH (+1).

---

## Position dans le pipeline

```
PH62 Evidence Intelligence
PH63 Abuse Pattern Engine ← NOUVEAU
PH56 Delivery Intelligence
PH57 Supplier/Warranty
PH58 Conversation Memory
PH59 Context Compression
```

---

## Bloc prompt (exemple MEDIUM)

```
=== ABUSE PATTERN ENGINE (PH63) ===
Abuse risk: MEDIUM
Confidence: 75%
History window: 180 days
Conversations analyzed: 4

Detected history patterns:
- repeat non delivery across orders
- high refund frequency

Guidance:
- follow strict process
- require evidence
- avoid fast resolution
- remain professional non accusatory

IMPORTANT: These patterns are for internal AI calibration only.
Do NOT mention abuse suspicion to the customer.
Remain professional, empathetic, and non-accusatory.
=== END ABUSE PATTERN ENGINE ===
```

---

## Donnees source

- Table `conversations` : customer_handle, status, subject, last_message_preview, order_ref
- Table `orders` : external_order_id, total_amount, status, delivery_status
- Fenetre : 180 jours (configurable)

---

## Tests

15 tests, 29 assertions — **29/29 PASS**

| Test | Scenario | Resultat |
|---|---|---|
| T1 | No history | LOW, PASS |
| T2 | Normal orders | LOW, PASS |
| T3 | 3 non-received claims | HIGH, PASS |
| T4 | High refund frequency | Signal detecte, PASS |
| T5 | Repeated defects | MEDIUM, PASS |
| T6 | Aggressive escalation | MEDIUM, PASS |
| T7 | High value claims | Signal detecte, PASS |
| T8 | Light history | LOW, PASS |
| T9 | Mixed claims | Instability signal, PASS |
| T10 | Incomplete history | LOW + low confidence, PASS |
| T11 | English patterns | Detection stable, PASS |
| T12 | Fast repeat claims | Signal detecte, PASS |
| T13 | Prompt block structure | PASS |
| T14 | Empty block for LOW | PASS |
| T15 | External risk amplifiers | PASS |

---

## Non-regression

| Couche | Impact |
|---|---|
| PH41-PH62 | Aucun |
| PH55 Fraud Pattern | Complete, pas duplique |
| PH47 Customer Risk | Lu, pas modifie |
| KBActions | 0 impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.72-ph62-evidence-intelligence-dev -n keybuzz-api-dev
```

---

## Cout

| Metrique | Valeur |
|---|---|
| Appels LLM | 0 |
| Impact KBActions | 0 |
| Lignes de code | 330 (service) |
| Requetes DB | 1-2 SELECT (conversations + orders) |
