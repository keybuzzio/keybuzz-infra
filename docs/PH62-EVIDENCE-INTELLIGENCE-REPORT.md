# PH62 — Evidence Intelligence Engine

> Date : 2026-03-01
> Auteur : Cursor CE
> Environnement : DEV
> Image : `v3.5.72-ph62-evidence-intelligence-dev`
> Rollback : `v3.5.71-ph61-marketplace-intelligence-dev`

---

## Objectif

Analyser les pieces jointes des conversations SAV pour fournir a l'IA un contexte structure sur les preuves disponibles : photos de dommages, etiquettes de livraison, factures, captures ecran, etc.

PH62 est une couche d'**analyse heuristique des preuves**, pas de decision SAV.

---

## Classification des preuves

### Types detectes
| Type | MIME | Signaux possibles |
|---|---|---|
| `photo` | `image/*` | product_damage, package_damage, delivery_proof, screenshot |
| `video` | `video/*` | evidence visuelle |
| `document` | `application/pdf`, `word`, `text` | invoice, generic_document |
| `screenshot` | `image/*` + pattern filename | order_issue_screenshot |
| `unknown` | autre | - |

### Signaux heuristiques
| Pattern filename | Signal |
|---|---|
| casse, broken, damage, defaut | `product_damage` |
| colis, package, carton, emballage | `package_damage` |
| etiquette, label, tracking, livraison | `delivery_proof` |
| facture, invoice, recu | `invoice` |
| Screenshot_, capture, screen | `order_issue_screenshot` |
| mauvais, wrong, different, mismatch | `product_mismatch` |

### Niveaux
| Niveau | Condition |
|---|---|
| `EVIDENCE_NONE` | 0 attachments |
| `EVIDENCE_PRESENT` | 1 attachment |
| `EVIDENCE_STRONG` | >= 2 attachments |

---

## Position dans le pipeline

```
PH60 Decision Calibration
PH61 Marketplace Intelligence
PH62 Evidence Intelligence ← NOUVEAU
PH56 Delivery Intelligence
PH57 Supplier/Warranty
PH58 Conversation Memory
PH59 Context Compression
```

---

## Bloc prompt (exemple)

```
=== EVIDENCE INTELLIGENCE (PH62) ===
Evidence present: YES
Evidence level: EVIDENCE_STRONG
Attachments: 3
Evidence types: photo, document
Confidence: 95%

Possible signals:
- package damage
- invoice
- delivery proof

Guidelines:
- Damage evidence detected — consider warranty or replacement path.
- Avoid requesting additional damage photos if already provided.
- Invoice or receipt attached — use for order verification.
- Delivery proof attached — verify tracking information before disputing.
=== END EVIDENCE INTELLIGENCE ===
```

---

## Donnees source

Table : `message_attachments`
Colonnes utilisees : `filename`, `mime_type`, `size_bytes`
Jointure : `messages.conversation_id` pour filtrer par conversation

---

## Tests

15 tests, 40 assertions — **40/40 PASS**

| Test | Scenario | Resultat |
|---|---|---|
| T1 | No attachments | PASS |
| T2 | 1 photo | PASS |
| T3 | 2 photos → STRONG | PASS |
| T4 | Photo damage → product_damage | PASS |
| T5 | PDF invoice | PASS |
| T6 | Mixed attachments | PASS |
| T7 | Large file | PASS |
| T8 | Non-image document | PASS |
| T9 | Delivery label | PASS |
| T10 | Package damage | PASS |
| T11 | Product mismatch | PASS |
| T12 | Screenshot | PASS |
| T13 | Prompt block structure | PASS |
| T14 | Empty block no evidence | PASS |
| T15 | Video attachment | PASS |

---

## Non-regression

| Couche | Impact |
|---|---|
| PH41-PH61 | Aucun |
| PH49 Refund Protection | Aucun |
| PH45 Decision Tree | Aucun |
| PH60 Decision Calibration | Aucun |
| PH61 Marketplace Intelligence | Aucun |
| KBActions | 0 impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.71-ph61-marketplace-intelligence-dev -n keybuzz-api-dev
```

---

## Cout

| Metrique | Valeur |
|---|---|
| Appels LLM | 0 |
| Impact KBActions | 0 |
| Lignes de code | 262 (service) |
| Requete DB | 1 SELECT (message_attachments JOIN messages) |
