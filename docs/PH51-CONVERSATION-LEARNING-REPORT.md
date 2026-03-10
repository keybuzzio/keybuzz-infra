# PH51 — Conversation Learning Loop — Rapport

> Date : 9 mars 2026
> Auteur : Agent Cursor (CE)
> Environnement : DEV uniquement
> Image : `v3.5.59-ph51-conversation-learning-dev`

---

## 1. Objectif

Creer une **Conversation Learning Loop** permettant a KeyBuzz d'apprendre automatiquement a partir de la boucle reelle :

```
message client → suggestion IA → reponse humaine finale → resolution observee → signal d'apprentissage
```

Phase d'**apprentissage passif uniquement** : aucune modification du comportement IA, aucun envoi marketplace, aucun message client.

---

## 2. Architecture

### Pipeline IA complet apres PH51

```
1  Base Prompt
2  PH41 SAV Policy (global)
3  PH44 Tenant Policy
4  PH43 Historical Engine
5  PH45 Decision Tree
6  PH46 Response Strategy
7  PH49 Refund Protection
8  PH50 Merchant Behavior Engine
9  Order Context
10 Supplier Context
11 Tenant Rules
```

PH51 n'injecte **aucun bloc prompt** — il ajoute uniquement des donnees dans `decisionContext` et `/ai/policy/effective` pour l'observabilite.

---

## 3. Table DB

```sql
CREATE TABLE conversation_learning_events (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  message_id TEXT,
  suggestion_id TEXT,
  learning_type TEXT NOT NULL,      -- AI_ACCEPTED | AI_MODIFIED | AI_REJECTED | HUMAN_ONLY | OUTCOME_OBSERVED
  scenario TEXT,
  ai_suggested_action TEXT,
  human_final_action TEXT,
  difference_score FLOAT DEFAULT 0, -- 0.0 = match, 1.0 = total mismatch
  outcome_status TEXT,
  was_accepted BOOLEAN DEFAULT false,
  was_modified BOOLEAN DEFAULT false,
  was_rejected BOOLEAN DEFAULT false,
  metadata_json JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

Index : `tenant_id`, `conversation_id`, `learning_type`

---

## 4. Algorithme de comparaison

### Detection d'action par mots-cles

| Categorie | Mots-cles |
|---|---|
| refund | rembours*, refund*, credit* |
| replacement | remplac*, envoy*nouveau*, reexpedi* |
| warranty | garantie, fournisseur, SAV, prise en charge |
| investigation | enquete, verif*, track*, suivi, transport, livraison |
| information | information, confirm*, precis*, detail*, photo* |
| apology | desole, excuse, sorry |

### Score de difference

| Score | Interpretation | LearningType |
|---|---|---|
| 0.0 | Action identique | AI_ACCEPTED |
| 0.4 | Meme famille (ex: refund → replacement) | AI_MODIFIED |
| 0.5 | Action inconnue | AI_MODIFIED |
| 0.8 | Familles differentes | AI_REJECTED |
| 1.0 | Pas de suggestion IA | HUMAN_ONLY |

### Familles d'actions
- **resolution** : refund, replacement, warranty
- **inquiry** : investigation, information
- **soft** : apology, information

---

## 5. Backfill

Le backfill analyse les donnees existantes : conversations ayant BOTH un `AI_DECISION_TRACE` et un message outbound humain.

**Resultat DEV** : **9 events** backfilles depuis 25 conversations appariees.

### Distribution observee (ecomlg-001)
- `acceptedRate` = 42.86% (3/7 suggestions IA acceptees)
- `modifiedRate` = 0% (0 modifications detectees)
- `rejectedRate` = 57.14% (4/7 suggestions IA rejetees)
- `humanOnlyRate` = 22.22% (2/9 sans suggestion IA)
- `topPatterns` : investigation, apology, information, refund, warranty

---

## 6. Fichiers crees/modifies

| Fichier | Action | Description |
|---|---|---|
| `src/services/conversationLearningEngine.ts` | **CREE** | Moteur principal : comparison, detection, backfill, summary, cache Redis |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE | Import + appel getLearningSummary, ajout learningSignals dans decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE | Import + endpoint GET /conversation-learning, POST /conversation-learning/backfill, ajout learningSignals dans /policy/effective |

---

## 7. Endpoints

### GET /ai/conversation-learning?tenantId=...
Retour :
```json
{
  "tenantId": "ecomlg-001",
  "totalEvents": 9,
  "acceptedRate": 0.4286,
  "modifiedRate": 0,
  "rejectedRate": 0.5714,
  "humanOnlyRate": 0.2222,
  "topPatterns": ["investigation","apology","information","refund","warranty"],
  "source": "live"
}
```

### POST /ai/conversation-learning/backfill (DEV only)
- Analyse les paires AI trace + reponse humaine existantes
- Cree les learning events manquants
- Retourne : `{ tenantId, recorded, status }`

### GET /ai/policy/effective
Nouveau champ `learningSignals` :
```json
{
  "learningSignals": {
    "acceptedRate": 0.4286,
    "modifiedRate": 0,
    "rejectedRate": 0.5714,
    "topPatterns": ["investigation","apology","information","refund","warranty"],
    "totalEvents": 9
  }
}
```
Nouveau dans `policyLayers` : `learningSignals: true`
Nouveau dans `finalPromptSections` : `LEARNING_SIGNALS`

### decisionContext
```json
{
  "learningSignals": {
    "acceptedRate": 0.4286,
    "modifiedRate": 0,
    "rejectedRate": 0.5714,
    "topPatterns": ["investigation","apology","information","refund","warranty"]
  }
}
```

---

## 8. Preuve /ai/policy/effective (conversation reelle)

Conversation : `cmmmchoh274c076872da12d91` (resolved, avec AI_DECISION_TRACE)

```
merchantBehavior=ok
learningSignals=ok
sections=GLOBAL_POLICY,SAV_POLICY,HISTORICAL_CONTEXT,DECISION_TREE,RESPONSE_STRATEGY,
         REFUND_PROTECTION,MERCHANT_BEHAVIOR,LEARNING_SIGNALS,ORDER_CONTEXT
```

---

## 9. Tests (10/10 PASS)

### Simulations (8 tests, aucun envoi marketplace)
| # | Test | Resultat |
|---|---|---|
| 1 | Suggestion IA acceptee (investigation → investigation) | PASS (AI_ACCEPTED) |
| 2 | Suggestion IA modifiee (refund → replacement, meme famille) | PASS (AI_MODIFIED) |
| 3 | Suggestion IA rejetee (investigation → refund) | PASS (AI_REJECTED) |
| 4 | Reponse humaine sans suggestion IA | PASS (HUMAN_ONLY) |
| 5 | Resolution warranty | PASS (humanAction=warranty) |
| 6 | Investigation first | PASS (AI_ACCEPTED) |
| 7 | Refund avoided (IA dit no refund, humain demande photos) | PASS (information) |
| 8 | Multi-langue (anglais) | PASS (investigation detecte) |

### Verifications reelles (2 tests, lecture seule)
| # | Test | Resultat |
|---|---|---|
| A | /policy/effective sur conversation reelle | PASS (merchantBehavior + learningSignals presents) |
| B | GET /conversation-learning endpoint | PASS (9 events, acceptedRate=0.4286) |

---

## 10. Non-regression

| Module | Statut |
|---|---|
| API Health | OK |
| PH41-PH50 | Inchanges |
| KBActions | Aucun cout additionnel |
| Aucun message envoye | Confirme (simulation only) |
| Aucun appel marketplace | Confirme |

---

## 11. Infra

| Element | Valeur |
|---|---|
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.59-ph51-conversation-learning-dev` |
| Namespace | `keybuzz-api-dev` |
| Rollback | `v3.5.58-ph50-merchant-behavior-dev` |

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.58-ph50-merchant-behavior-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 13. Impact Produit

PH51 permet a KeyBuzz de :
- Comprendre si les suggestions IA sont suivies ou ignorees
- Identifier les patterns de correction humaine recurrents
- Preparer la base d'apprentissage pour les futures ameliorations IA
- Sans aucun impact sur le comportement IA actuel
- Sans aucun cout additionnel

---

## STOP POINT

DEV uniquement. Aucun deploiement PROD. Attente validation Ludovic.
