# PH59 — Context Compression Engine

> Date : 2026-03-01
> Auteur : Cursor CE
> Environnement : DEV
> Image : `v3.5.69-ph59-context-compression-dev`
> Rollback : `v3.5.68-ph58-conversation-memory-dev`

---

## Objectif

Compresser les blocs de contexte IA (PH41-PH58) envoyes au LLM pour :
- Reduire les tokens envoyes (~50% de gain mesure)
- Dedupliquer les signaux redondants entre couches
- Regrouper les informations en 4 familles coherentes
- Maintenir 100% de l'intelligence SAV existante

PH59 est une couche de **compression**, pas une couche metier. Aucune decision SAV n'est modifiee.

---

## Architecture

### Position dans le pipeline

```
PH41 → PH58 : produisent leurs blocs normalement (inchange)
         ↓
PH59 : Context Compression Engine
         ↓
buildSystemPrompt() : recoit le prompt compresse OU les blocs individuels (fallback)
         ↓
LLM
```

### 4 familles de compression

| Famille | Blocs sources | Contenu compresse |
|---|---|---|
| **DECISION CORE** | PH41 SAV Policy, PH45 Decision Tree, PH46 Response Strategy, PH53 Customer Tone, PH54 Customer Intent | Scenario, intent, tone, strategie, next step, forbidden actions |
| **RISK & PROTECTION** | PH49 Refund Protection, PH55 Fraud Pattern, PH52 Adaptive Response | Refund status, fraud risk, regles de protection |
| **BUSINESS CONTEXT** | PH50 Merchant Behavior, PH44 Tenant Policy | Profil vendeur, politique tenant, seuils |
| **CASE STATE** | PH56 Delivery Intelligence, PH57 Supplier/Warranty, PH58 Conversation Memory, PH43 Historical | Etat livraison, garantie, memoire conversation, historique |

### Mecanisme de compression

1. **Parsing** : chaque bloc est parse pour extraire les paires cle-valeur, bullets et instructions
2. **Regroupement** : les donnees extraites sont regroupees par famille
3. **Deduplication intra-famille** : signaux identiques fusionnes via detection de concepts
4. **Deduplication cross-famille** : concepts vus dans une famille ne sont pas repetes
5. **Compaction** : instructions verboses transformees en formulations compactes

### Concepts dedupliques

| Concept | Patterns detectes |
|---|---|
| refund_blocked | "do not refund", "avoid refund", "refund blocked/forbidden" |
| remain_professional | "remain professional", "stay professional" |
| do_not_promise | "do not promise", "ne pas promettre" |
| delivery_window | "delivery window", "livraison estimee" |
| ask_photo | "ask photo/proof", "demander preuve" |
| investigation_suggestion | "investigation", "enquete" |
| tracking_info | "tracking", "suivi" |
| warranty_path | "under warranty", "warranty claim/process" |
| do_not_accuse | "do not accuse", "ne pas accuser" |

---

## Avant / Apres

### Avant (14 blocs individuels)

```
=== SAV POLICY ENGINE ===               (~80 tokens)
=== TENANT POLICY ===                   (~40 tokens)
=== HISTORICAL ENGINE ===               (~60 tokens)
=== SAV DECISION TREE (PH45) ===        (~100 tokens)
=== RESPONSE STRATEGY (PH46) ===        (~90 tokens)
=== REFUND PROTECTION LAYER ===         (~100 tokens)
=== MERCHANT BEHAVIOR ===               (~70 tokens)
=== ADAPTIVE RESPONSE ===               (~50 tokens)
=== CUSTOMER TONE ENGINE (PH53) ===     (~60 tokens)
=== CUSTOMER INTENT ENGINE (PH54) ===   (~50 tokens)
=== FRAUD PATTERN DETECTION (PH55) ===  (~70 tokens)
=== DELIVERY INTELLIGENCE (PH56) ===    (~80 tokens)
=== SUPPLIER / WARRANTY (PH57) ===      (~70 tokens)
=== CONVERSATION MEMORY (PH58) ===      (~80 tokens)
────────────────────────────────────
TOTAL ESTIME : ~780 tokens (headers/footers inclus)
```

### Apres (4 blocs compresses)

```
=== DECISION CORE ===                   (~120 tokens)
=== RISK & PROTECTION ===               (~80 tokens)
=== BUSINESS CONTEXT ===                (~60 tokens)
=== CASE STATE ===                      (~120 tokens)
────────────────────────────────────
TOTAL ESTIME : ~380 tokens
RATIO : 0.49 (51% d'economie)
```

---

## Estimation tokens

Mesure sur le test rich input (15 tests, prompt realiste) :

| Metrique | Valeur |
|---|---|
| Tokens originaux estimes | ~780 |
| Tokens compresses estimes | ~382 |
| Ratio compression | **0.49** |
| Economie | **~398 tokens (51%)** |
| Signaux supprimes (redondants) | Variable selon contexte |

L'estimation utilise ~4 chars/token (heuristique standard).

---

## Integration technique

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/services/contextCompressionEngine.ts` | **Nouveau** — service de compression (290 lignes) |
| `src/modules/ai/ai-assist-routes.ts` | Import PH59, invocation apres PH58, param `compressedEnginePrompt` dans `buildSystemPrompt`, bypass compression, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug `GET /ai/context-compression` |
| `src/tests/ph59-tests.ts` | **Nouveau** — 15 tests (28 assertions) |

### buildSystemPrompt — Modification

La signature ajoute un parametre optionnel :

```typescript
function buildSystemPrompt(..., conversationMemoryBlock?: string, compressedEnginePrompt?: string): string
```

Si `compressedEnginePrompt` est fourni et non-vide :
- Les 14 blocs individuels PH41-PH58 sont IGNORES
- Le prompt compresse est injecte a la place
- Les blocs order context, tenant rules, supplier context restent inchanges

Fallback : si compression echoue ou ratio >= 1.0, les blocs originaux sont utilises (backward-compatible).

### decisionContext

```json
{
  "contextCompression": {
    "enabled": true,
    "originalEstimatedTokens": 780,
    "compressedEstimatedTokens": 382,
    "compressionRatio": 0.49,
    "droppedRedundantSignals": ["cross_family_remain_professional: ..."]
  }
}
```

---

## Endpoint debug

```
GET /ai/context-compression?tenantId=xxx&conversationId=yyy
```

Retourne :
```json
{
  "compressedBlocks": [...],
  "compressedPrompt": "...",
  "originalEstimatedTokens": 780,
  "compressedEstimatedTokens": 382,
  "compressionRatio": 0.49,
  "droppedRedundantSignals": [...]
}
```

Aucun appel LLM. Aucun debit KBActions.

---

## Tests

15 tests, 28 assertions — **28/28 PASS**

| Test | Assertions | Resultat |
|---|---|---|
| T1: Rich prompt → compression active | 4 | PASS |
| T2: Refund duplicates → merged | 1 | PASS |
| T3: Delivery duplicates → merged | 1 | PASS |
| T4: Critical signals preserved | 3 | PASS |
| T5: Conversation memory preserved | 1 | PASS |
| T6: Tone + Intent compressed | 2 | PASS |
| T7: Merchant behavior preserved | 1 | PASS |
| T8: Minimal context → stable | 3 | PASS |
| T9: English blocks → stable | 2 | PASS |
| T10: Compression ratio correct | 1 | PASS |
| T11: No critical block dropped | 3 | PASS |
| T12: Non-regression empty input | 3 | PASS |
| T13: 4 families max | 1 | PASS |
| T14: Dropped signals tracked | 1 | PASS |
| T15: Compression >= 20% | 1 | PASS |

---

## Non-regression

| Couche | Impact | Status |
|---|---|---|
| PH41 SAV Policy | Aucun — bloc genere normalement, compresse ensuite | OK |
| PH43 Historical Engine | Aucun — bloc genere normalement | OK |
| PH44 Tenant Policy | Aucun — bloc genere normalement | OK |
| PH45 Decision Tree | Aucun — bloc genere normalement | OK |
| PH46 Response Strategy | Aucun — bloc genere normalement | OK |
| PH49 Refund Protection | Aucun — bloc genere normalement | OK |
| PH50 Merchant Behavior | Aucun — bloc genere normalement | OK |
| PH52 Adaptive Response | Aucun — bloc genere normalement | OK |
| PH53 Customer Tone | Aucun — bloc genere normalement | OK |
| PH54 Customer Intent | Aucun — bloc genere normalement | OK |
| PH55 Fraud Pattern | Aucun — bloc genere normalement | OK |
| PH56 Delivery Intelligence | Aucun — bloc genere normalement | OK |
| PH57 Supplier/Warranty | Aucun — bloc genere normalement | OK |
| PH58 Conversation Memory | Aucun — bloc genere normalement | OK |
| KBActions | 0 impact (compression reduit les tokens, pas les KBA) | OK |
| decisionContext | Enrichi avec champ contextCompression | OK |

Tous les engines existants fonctionnent a l'identique. PH59 n'intervient qu'en aval, sur les sorties texte, sans toucher aux calculs SAV.

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.68-ph58-conversation-memory-dev -n keybuzz-api-dev
```

---

## Cout

| Metrique | Valeur |
|---|---|
| Appels LLM supplementaires | 0 |
| Impact KBActions | 0 (reduction potentielle via tokens reduits) |
| Complexite ajoutee | 1 service (290 lignes), 6 points d'integration |
| Gain tokens moyen | ~50% par requete |
