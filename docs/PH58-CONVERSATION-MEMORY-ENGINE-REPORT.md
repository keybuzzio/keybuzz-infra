# PH58 — Conversation Memory Engine

> Date : 1er mars 2026
> Auteur : Agent Cursor
> Image DEV : `v3.5.68-ph58-conversation-memory-dev`
> Rollback : `v3.5.67-ph57-supplier-warranty-intelligence-dev`
> PROD : non deploye (attente validation)

---

## 1. Objectif

Creer une couche memoire structuree permettant a l'IA de savoir ce qui a deja ete discute, demande et fourni dans une conversation. Eviter les repetitions, les questions redondantes et les pertes de contexte.

**Problemes resolus** :
- L'IA redemandait une photo deja demandee
- L'IA ignorait qu'un client avait deja fourni une reponse
- L'IA reproposait d'ouvrir une enquete deja ouverte
- L'IA reintroduisait la garantie comme si c'etait nouveau
- L'IA repetait "merci de nous indiquer..." alors que l'info etait deja dans le thread

---

## 2. Architecture

### Service
`src/services/conversationMemoryEngine.ts` (369 lignes)

### Fonction principale
`buildConversationMemory(context: ConversationMemoryContext): ConversationMemoryResult`

### Pattern
Heuristique pure — regex multi-langue (FR + EN) sur les messages inbound/outbound.
- 0 appel LLM
- 0 cout KBActions
- ~0.5ms par conversation (regex scan sur 10-20 messages)

---

## 3. Drapeaux memoire (12)

| # | Flag | Direction scannee | Description |
|---|---|---|---|
| 1 | `askedForPhotos` | outbound | L'agent a demande une photo/video/preuve |
| 2 | `photosMentionedByCustomer` | inbound | Le client dit avoir joint une photo |
| 3 | `askedForOrderConfirmation` | outbound | Le numero de commande a ete demande |
| 4 | `askedForTrackingCheck` | outbound | Le client a ete invite a verifier boite/voisin/relais |
| 5 | `deliveryExplained` | outbound | Le delai de livraison a ete explique |
| 6 | `investigationSuggested` | any | Une enquete a ete mentionnee |
| 7 | `investigationOpened` | outbound | L'agent a confirme l'ouverture d'enquete |
| 8 | `warrantyPathMentioned` | any | La voie garantie/SAV a ete evoquee |
| 9 | `replacementMentioned` | any | Le remplacement a ete evoque |
| 10 | `refundRequested` | inbound | Le client a demande un remboursement |
| 11 | `refundAlreadyRefused` | outbound | L'agent a refuse le remboursement |
| 12 | `customerProvidedAdditionalInfo` | inbound | Le client a fourni de nouvelles infos |

---

## 4. Regles de guidance

| Situation | Guidance |
|---|---|
| Photo demandee + non fournie | `do_not_repeat_photo_request_verbatim` |
| Photo demandee + client dit avoir envoye | `customer_claims_photos_sent_acknowledge_and_check` |
| Investigation ouverte | `investigation_already_in_progress_do_not_suggest_opening_new` |
| Garantie deja discutee | `warranty_already_discussed_continue_from_current_state` |
| Remboursement deja refuse | `refund_already_refused_do_not_reopen_without_new_elements` |
| Client a fourni nouvelles infos | `customer_provided_new_info_adapt_response_accordingly` |
| Livraison deja expliquee | `delivery_already_explained_do_not_repeat_same_timeline` |
| Tracking check deja demande | `tracking_check_already_suggested_do_not_repeat` |

---

## 5. Position dans le pipeline

```
 1. Base Prompt
 2. PH41 SAV Policy
 3. PH44 Tenant Policy
 4. PH43 Historical Engine
 5. PH45 Decision Tree
 6. PH46 Response Strategy
 7. PH49 Refund Protection
 8. PH50 Merchant Behavior
 9. PH52 Adaptive Response
10. PH53 Customer Tone
11. PH54 Customer Intent
12. PH55 Fraud Pattern
13. PH56 Delivery Intelligence
14. PH57 Supplier / Warranty Intelligence
15. PH58 Conversation Memory Engine   ← NOUVEAU
16. Order Context
17. Supplier Context
18. Tenant Rules
19. → LLM
```

---

## 6. Prompt block injecte

```
=== CONVERSATION MEMORY ENGINE (PH58) ===
Conversation memory confidence: 78%

Known case state:
- warranty/SAV path already discussed
- photo/proof request already sent by agent

Guidance:
- warranty already discussed continue from current state
- do not repeat photo request verbatim
- avoid repeating the same request verbatim
- continue from the current case state
- only ask for missing information not yet requested
=== END CONVERSATION MEMORY ENGINE ===
```

---

## 7. Decision context

Ajoute dans `decisionContext` de la response `/ai/assist` :

```json
{
  "conversationMemory": {
    "memoryState": { ... 12 flags ... },
    "confidence": 0.78,
    "signals": ["warranty_path_already_mentioned"],
    "guidance": ["warranty_already_discussed_continue_from_current_state"]
  }
}
```

---

## 8. Endpoint debug

`GET /ai/conversation-memory?tenantId=xxx&conversationId=xxx`

- Aucun appel LLM
- Aucun debit KBActions
- Retourne le memoryState + signals + guidance + promptBlock

Test reel effectue sur conversation `cmmk5yxi9sab46eab8e0af444` (20 messages) :
- Resultat : `warrantyPathMentioned=true`, confidence 78%

---

## 9. Tests

15 tests, 36 assertions, **100% PASS** :

| # | Test | Assertions |
|---|---|---|
| T1 | Photo deja demandee | askedForPhotos=true, signal |
| T2 | Client mentionne photos | photosMentionedByCustomer=true, signal |
| T3 | Investigation mentionnee | investigationSuggested=true, signal |
| T4 | Investigation ouverte | investigationOpened=true, signal |
| T5 | Garantie mentionnee | warrantyPathMentioned=true, signal |
| T6 | Remboursement demande | refundRequested=true, signal |
| T7 | Remboursement refuse | refundAlreadyRefused=true, refundRequested=true, guidance |
| T8 | Client fournit info | customerProvidedAdditionalInfo=true, signal |
| T9 | Photo demandee non fournie | guidance do_not_repeat |
| T10 | Conversation anglaise | 3 flags detectes en EN |
| T11 | Conversation vide | confidence <= 0.4, all flags false |
| T12 | Non-regression minimal | pas de crash, structure valide |
| T13 | Tracking check | askedForTrackingCheck=true |
| T14 | Replacement | replacementMentioned=true |
| T15 | Delivery explained | deliveryExplained=true |

---

## 10. Non-regression

Aucun engine PH41-PH57 modifie. Seuls fichiers touches :
- `src/services/conversationMemoryEngine.ts` (NOUVEAU)
- `src/modules/ai/ai-assist-routes.ts` (import + invocation + buildSystemPrompt + decisionContext)
- `src/modules/ai/ai-policy-debug-routes.ts` (import + endpoint debug)

Pas de modification de schema DB, pas de nouvelle table, pas de nouveau endpoint payant.

---

## 11. Fichiers

| Fichier | Action |
|---|---|
| `src/services/conversationMemoryEngine.ts` | Cree (369 lignes) |
| `src/modules/ai/ai-assist-routes.ts` | Modifie (5 points d'injection) |
| `src/modules/ai/ai-policy-debug-routes.ts` | Modifie (1 endpoint ajoute) |
| `src/tests/ph58-tests.ts` | Cree (15 tests) |

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.67-ph57-supplier-warranty-intelligence-dev -n keybuzz-api-dev
```
