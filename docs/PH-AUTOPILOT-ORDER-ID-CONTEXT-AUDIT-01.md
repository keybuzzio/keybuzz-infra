# PH-AUTOPILOT-ORDER-ID-CONTEXT-AUDIT-01 — TERMINÉ

**Verdict : GO** (cause racine identifiée, correction recommandée)

**Date** : 2026-04-20
**Environnement** : DEV + PROD (lecture seule)
**Type** : Audit ciblé extraction / usage numéro de commande dans Autopilot

---

## Préflight

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `4f60aad5` |
| Repo clean | OUI |
| Image DEV | `v3.5.89-autopilot-inbound-trigger-dev` |
| Image PROD | `v3.5.89-autopilot-inbound-trigger-prod` |
| DEV/PROD alignés | OUI |

---

## Reproduction

### Cas reproductible

| Env | Conversation | Canal | Numéro visible dans message ? | order_ref DB | Draft redemande le numéro ? |
|---|---|---|---|---|---|
| PROD | `conv-4837f801` | email | **OUI** (`402-1234567-8901234` dans body) | `null` | **OUI** — "Pourriez-vous me confirmer le numéro de commande" |
| DEV | `cmmnzpvt3oec776e94a6dd17a` | amazon | **OUI** (`407-9914898-6385166` dans body) | `407-9914898-6385166` | **NON** — draft référence correctement le numéro |
| DEV | `conv-35462218` | email | **NON** (pas de numéro dans body) | `null` | OUI — demande logique car info absente |

### Observation clé

La différence entre le cas OK et le cas KO est le champ `order_ref` dans la table `conversations` :
- Quand `order_ref` est peuplé (canal Amazon → extraction par `amazonForward.ts`), le draft utilise le numéro correctement
- Quand `order_ref` est null (canal email → aucune extraction), le draft ignore le numéro même s'il est visible dans le body

### Preuve PROD — conv-4837f801

**Message inbound** :
```
"Bonjour, je voudrais savoir ou en est ma commande numero 402-1234567-8901234. Merci."
```

**Draft Autopilot généré** :
```
"Bonjour, merci pour votre message. Pourriez-vous me confirmer le numéro de commande ou de suivi ?"
```

**ai_action_log** :
```json
{
  "id": "alog-1776720356907-4xhpzow65",
  "action_type": "autopilot_escalate",
  "blocked_reason": "ESCALATION_DRAFT:0.75",
  "payload": { "draftText": "...Pourriez-vous me confirmer le numéro de commande ou de suivi ?..." }
}
```

---

## Parsing

### Fonction `extractOrderRef()` (src/modules/inbound/amazonForward.ts:181)

```typescript
function extractOrderRef(text: string): string | undefined {
  const patterns = [
    /ORDER[-\s#]*(\d+)/i,
    /commande[-\s#]*(\d+)/i,
  ];
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) return `ORDER-${match[1]}`;
  }
  return undefined;
}
```

| Fichier | Fonction | Rôle | Support format Amazon `\d{3}-\d{7}-\d{7}` ? |
|---|---|---|---|
| `inbound/amazonForward.ts` | `extractOrderRef()` | Extraction order ref pour canal Amazon uniquement | **NON** — ne match que `ORDER-\d+` et `commande-\d+` |
| `inbound/routes.ts` (email) | *(aucune)* | Aucune extraction depuis body | **NON** — attend `body.orderRef` du caller |
| `inbound/routes.ts` (amazon-forward) | *(via amazonForward.ts)* | Delegue a `extractOrderRef` | **NON** — regex inadaptée |
| `orders/routes.ts` | Validation format | Regex `^\d{3}-\d{7}-\d{7}$` utilisée pour valider | OUI — mais jamais utilisée pour extraction |

### Conclusion parsing

1. **Le handler email (`POST /inbound/email`) n'a AUCUNE logique d'extraction** d'order ID depuis le body. Il passe `body.orderRef || null`, et personne ne fournit ce champ.
2. **`extractOrderRef()` ne reconnaît pas le format Amazon** (`\d{3}-\d{7}-\d{7}`) — il ne match que des formats simples `ORDER-\d+` ou `commande-\d+`.
3. **Le bon regex existe** dans `orders/routes.ts` (ligne 1005 : `/^\d{3}-\d{7}-\d{7}$/`) mais n'est jamais réutilisé pour l'extraction.

---

## Contexte

### Chaîne tracée de bout en bout

```
message entrant (POST /inbound/email)
  → body.orderRef = undefined (caller ne fournit pas)
  → INSERT conversations ... order_ref = null
  → message stocké avec body intact
  → evaluateAndExecute(conversationId, tenantId, 'inbound')
    → loadFullConversationContext() → order_ref = null
    → context.order_ref ? loadEnrichedOrderContext() : null
      → null (court-circuit immédiat)
    → orderContext = null
    → temporalContext = {nul}
    → userPrompt: "Aucune commande liée... Demande le numéro"
    → userPrompt: "Dernier message: ...commande numero 402-1234567..."
    → systemPrompt CAS 1: "Demande poliment le numéro"
    → LLM obéit aux instructions explicites → "Pourriez-vous confirmer..."
```

| Étape | État | Preuve |
|---|---|---|
| Numéro extrait du body ? | **NON** — aucune extraction dans le handler email | `grep -rn 'extract.*order' src/modules/inbound/routes.ts` → 0 résultat |
| `order_ref` propagé ? | **NON** — reste null | `conversations.order_ref = null` pour conv-4837f801 |
| Lookup order tenté ? | **NON** — court-circuité car `order_ref = null` | `engine.ts:236-237` : `context.order_ref ? ... : null` |
| Résultat du lookup | **JAMAIS EXÉCUTÉ** | `orderContext = null` |
| Prompt sait qu'un order_id existe ? | **NON** — le prompt dit "Aucune commande liée" | Injection explicite dans user prompt |
| Body du message inclus dans le prompt ? | **OUI** — via `last_message_body` | `engine.ts:745` : `context.last_message_body` |

---

## Lookup

| Test | Résultat |
|---|---|
| lookup direct par order ID | **FONCTIONNE** — `SELECT * FROM orders WHERE external_order_id = $1` |
| lookup via conversation (order_ref) | **FONCTIONNE** quand `order_ref` est peuplé (canal Amazon) |
| lookup via parsing body | **ABSENT** — aucun code ne parse le body pour extraire un order ID |
| Order `402-1234567-8901234` en DB | **NON TROUVÉ** — ordre fictif du test, mais même un vrai ordre ne serait pas trouvé car le lookup n'est jamais déclenché |

---

## Prompt

### Deux systèmes de prompt divergents

| Système | Fichier | Utilise `getScenarioRules()` ? | CAS 1 (pas de commande) |
|---|---|---|---|
| **Autopilot** (automatique) | `engine.ts` | **NON** — importé mais jamais utilisé | "Demande poliment le numéro de commande" |
| **AI Assist** (suggestion manuelle) | `ai-assist-routes.ts` | **OUI** (ligne 344) | "Vérifie D'ABORD si le client a mentionné un numéro" |

### Prompt Autopilot — Instructions contradictoires

Le prompt `engine.ts` dit simultanément :
1. **System prompt CAS 1** : *"Demande poliment le numéro de commande ou de suivi pour mieux l'aider"*
2. **User prompt** : *"Aucune commande liée... → Demande poliment le numéro de commande ou de suivi"*
3. **User prompt (body)** : *"Dernier message du client: Bonjour, je voudrais savoir ou en est ma commande numero 402-1234567-8901234. Merci."*

Le LLM obéit aux instructions explicites (1 et 2) plutôt qu'à l'information implicite (3).

### Prompt AI Assist (suggestion manuelle) — Correct

Le prompt `ai-assist-routes.ts` inclut `getScenarioRules()` qui contient :
```
RÈGLE PRIORITAIRE ABSOLUE
- Tu ne dois JAMAIS redemander une information déjà présente dans le message ou l'historique
- Même si le contexte commande n'est pas lié en base, utilise les infos du message
CAS 1 - Pas de commande liée:
-> Vérifie D'ABORD si le client a mentionné un numéro de commande/suivi dans son message
-> Si OUI : utilise-le directement
-> Si NON : demande poliment le numéro
```

Cette règle n'est **JAMAIS injectée** dans le prompt Autopilot.

| Élément prompt | Présent dans Autopilot ? | Suffisant ? |
|---|---|---|
| RÈGLE PRIORITAIRE ABSOLUE (ne pas redemander) | **NON** | N/A |
| CAS 1 "demande le numéro" (sans vérification body) | **OUI** | **NON** — instruction directe sans nuance |
| "Aucune commande liée... Demande le numéro" | **OUI** | **NON** — amplifie l'instruction |
| Body du message (contient le numéro) | **OUI** (via `last_message_body`) | OUI mais écrasé par les instructions |
| `getScenarioRules()` | **IMPORTÉ mais JAMAIS UTILISÉ** | — |
| `getWritingRules()` | **IMPORTÉ mais JAMAIS UTILISÉ** | — |

---

## Cause racine

### Hiérarchie des causes

| # | Cause | Type | Impact | Fichier |
|---|---|---|---|---|
| **1** | **Handler email ne fait aucune extraction d'order ID depuis le body** | Parsing absent | `order_ref` toujours null pour canal email | `inbound/routes.ts` |
| **2** | **Prompt Autopilot instruit explicitement de redemander le numéro** quand orderContext est null, sans vérifier le body | Prompt contradictoire | IA ignore le numéro même s'il est dans le message | `autopilot/engine.ts` |
| **3** | **`getScenarioRules()` importé mais jamais injecté** dans le prompt Autopilot | Règle de sécurité manquante | La "RÈGLE PRIORITAIRE ABSOLUE" (ne jamais redemander une info du message) n'est pas appliquée | `autopilot/engine.ts` |
| **4** | **`extractOrderRef()` ne supporte pas le format Amazon** `\d{3}-\d{7}-\d{7}` | Regex inadaptée | Même pour le canal Amazon-forward, certains ordres ne seraient pas extraits | `inbound/amazonForward.ts` |

### Cause racine unique

**La chaîne de défaillance repose sur l'absence d'extraction d'order ID depuis le body du message (Cause 1), amplifiée par un prompt Autopilot qui instruit de redemander l'info sans vérifier le message (Causes 2+3).**

---

## Correction recommandée

### Fix minimal (2 actions) :

**Action A — Injecter `getScenarioRules()` dans le prompt Autopilot** (`engine.ts`)
- Modifier la construction du `systemPrompt` pour inclure `getScenarioRules()` (déjà importé)
- Cela apporte la "RÈGLE PRIORITAIRE ABSOLUE" qui dit de ne jamais redemander une info du message
- Impact : le LLM utilisera les infos du body même sans `orderContext`
- Fichier : `src/modules/autopilot/engine.ts`, dans `getAISuggestion()`
- Risque : minimal, la règle est déjà testée dans `ai-assist`

**Action B — Extraire l'order ID du body dans le handler email** (`inbound/routes.ts`)
- Ajouter une fonction `extractOrderRefFromBody(body)` qui utilise le regex Amazon `\d{3}-\d{7}-\d{7}`
- L'utiliser pour peupler `order_ref` à la création de la conversation
- Impact : permet le lookup commande + enrichissement du contexte
- Fichier : `src/modules/inbound/routes.ts`
- Risque : moyen, nécessite de tester que le regex ne match pas de faux positifs

**Action C (optionnelle) — Mettre à jour `extractOrderRef()` dans `amazonForward.ts`**
- Ajouter le pattern `\d{3}-\d{7}-\d{7}` pour le format Amazon standard
- Impact : meilleure extraction même pour le canal Amazon-forward
- Fichier : `src/modules/inbound/amazonForward.ts`

### Priorité

L'**Action A** seule résout le problème visible (le draft ne redemandera plus une info déjà dans le message) avec un changement minimal (1 ligne). L'**Action B** résout le problème structurel (order context enrichi pour les emails) mais nécessite plus de travail.

---

## Conclusion

- Aucune modification effectuée
- Aucun build
- Aucun deploy
- Audit en lecture seule uniquement
- 4 causes racines identifiées et hiérarchisées
- Correction recommandée documentée

---

## VERDICT FINAL

**ORDER ID CONTEXT ROOT CAUSE IDENTIFIED**

Cause principale : absence d'extraction d'order ID dans le handler email + prompt Autopilot qui instruit de redemander sans vérifier le body + `getScenarioRules()` importé mais jamais injecté dans le prompt Autopilot.
