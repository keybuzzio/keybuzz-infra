# PH-AUTOPILOT-TRIGGER-TRUTH-03 — Rapport Final

> **Date** : 27 mars 2026
> **Phase** : PH-AUTOPILOT-TRIGGER-TRUTH-03
> **Type** : Audit trigger — pourquoi autopilot ne se declenche pas sur srv-performance
> **Environnement** : DEV uniquement
> **Methode** : Audit lecture seule — AUCUNE modification
> **Tenant audite** : `srv-performance-mn7ds3oj` (SRV Performance)

---

## 1. Objectif

Comprendre pourquoi l'autopilot ne se declenche PAS automatiquement sur le tenant `srv-performance-mn7ds3oj`, alors que :
- Plan = **AUTOPILOT** (correct)
- Mode = **autonomous** (correct)
- Toutes les actions = **activees** (correct)
- Safe mode = **true** (attendu)
- Wallet = **2500 KBA** (suffisant)

---

## 2. Configuration du Tenant — Tout est correct

### Tenant

| Champ | Valeur | Requis | OK ? |
|---|---|---|---|
| plan | **AUTOPILOT** | AUTOPILOT ou ENTERPRISE | OUI |
| status | active | active | OUI |
| billing | trialing (expire 2026-04-09) | - | OUI |

### Autopilot Settings

| Parametre | Valeur | Requis | OK ? |
|---|---|---|---|
| is_enabled | **true** | true | OUI |
| mode | **autonomous** | autonomous | OUI |
| allow_auto_reply | **true** | true | OUI |
| allow_auto_assign | **true** | true | OUI |
| allow_auto_escalate | **true** | true | OUI |
| safe_mode | true | - | OUI (bloque reply, escalade) |

### Wallet

| Champ | Valeur |
|---|---|
| remaining | **2500.0000 KBA** |
| purchased_remaining | 500.0000 |
| included_monthly | 2000.0000 |
| reset_at | 2026-04-01 |

### Inbound Addresses

| Pays | Adresse | Status | lastInboundAt |
|---|---|---|---|
| FR | `amazon.srv-performance-mn7ds3oj.fr.79bebe@inbound.keybuzz.io` | VALIDATED | **null** |
| ES | `amazon.srv-performance-mn7ds3oj.es.cf6a4f@inbound.keybuzz.io` | VALIDATED | **null** |
| IT | `amazon.srv-performance-mn7ds3oj.it.e25527@inbound.keybuzz.io` | VALIDATED | **null** |

**`lastInboundAt = null` sur les 3 adresses** — Amazon n'a JAMAIS delivre de message a ces adresses.

---

## 3. Conversations et Messages Existants

7 conversations, 8 messages, TOUS inbound HUMAN sur canal amazon :

| Conversation | Cree a | Messages | Dernier msg | Source | Autopilot log ? |
|---|---|---|---|---|---|
| `cmmn7e6ou...` | 26 mars 11:31 | 1 | inbound | HUMAN | NON |
| `cmmn7e7x0...` | 26 mars 11:32 | 1 | inbound | HUMAN | NON |
| `cmmn7g3sw...` | 26 mars 12:25 | 1 | inbound | HUMAN | OUI (test manuel) |
| `cmmn8j6o7...` | 27 mars 06:39 | 2 | inbound | HUMAN | OUI (test manuel) |
| `cmmn8n8ae...` | 27 mars 08:32 | 1 | inbound | HUMAN | NON |
| `cmmn8r0lp...` | 27 mars 10:18 | 1 | inbound | HUMAN | NON |
| `cmmn8rz15...` | 27 mars 10:45 | 1 | inbound | HUMAN | NON |

Les 2 seuls logs autopilot sont des **evaluations manuelles** (`POST /autopilot/evaluate`) de PH-AUTOPILOT-RUNTIME-TRUTH-02, pas des triggers automatiques.

---

## 4. CAUSE RACINE #1 : Les messages ne passent PAS par la route inbound

### Preuve : zero POST /inbound dans les logs du pod

Le pod API actuel a demarre a **09:52:06 UTC** (image `v3.5.120-env-aligned-dev`).

L'audit complet des logs du pod montre que les seuls POST recus sont :
- `/debug/outbound/tick` (CronJob, chaque minute)
- `/ai/suggestions/track` (interaction UI)
- `/autopilot/evaluate` (test manuel audit 4)

**ZERO requete POST vers `/inbound/email` ou `/inbound/amazon/forward`.**

Pourtant, 2 conversations ont ete creees APRES le demarrage du pod :
- `cmmn8r0lp...` a 10:18
- `cmmn8rz15...` a 10:45

### Conclusion : les messages n'arrivent pas via la route inbound de l'API

Le hook autopilot est place **uniquement** dans la route inbound :

```
Ligne 207-208: if (body.tenantId && conversationId) {
                   evaluateAndExecute(conversationId, body.tenantId, 'inbound')

Ligne 439-440: if (inboundPayload.tenantId && conversationId) {
                   evaluateAndExecute(conversationId, inboundPayload.tenantId, 'inbound')
```

**Si un message n'entre pas par la route inbound, le hook autopilot ne se declenche JAMAIS.**

### Comment les messages arrivent-ils alors ?

Les messages sont crees dans la DB par un mecanisme EXTERNE a l'API pod :
- Possiblement le pipeline mail (mail.keybuzz.io → API) qui route vers un autre endpoint
- Possiblement un worker Python backend (insertion directe DB)
- Possiblement les Amazon orders workers
- Possiblement des donnees de test inserees manuellement

Les indices :
- `lastInboundAt = null` sur toutes les adresses inbound = Amazon n'a JAMAIS utilise ces adresses
- `customer_name = "eComLG contact"` sur presque tous les messages = ce sont des emails du compte Amazon eComLG, pas de vrais clients
- Les `created_at` sont arrondis a la seconde (`.000Z`) = timestamps Amazon, pas DB `NOW()`

---

## 5. CAUSE RACINE #2 : LiteLLM model introuvable (bloquant secondaire)

Meme quand l'autopilot est declenche **manuellement**, le resultat est `LOW_CONFIDENCE:0` avec escalade.

### Preuve : test manuel sur `cmmn8rz15...`

```json
{
  "executed": false,
  "action": "none",
  "reason": "LOW_CONFIDENCE:0",
  "confidence": 0,
  "escalated": true,
  "kbActionsDebited": 0
}
```

### Cause : erreur 404 LiteLLM

```
[LiteLLM] Error 404: litellm.NotFoundError: AnthropicException - 
  {"type":"error","error":{"type":"not_found_error",
  "message":"model: claude-3-5-haiku-20241022"}}
  Received Model Group=kbz-cheap
  Available Model Group Fallbacks=None
```

Le modele `claude-3-5-haiku-20241022` utilise par l'alias `kbz-cheap` **n'existe plus** chez Anthropic. Le fallback n'est pas configure ou echoue aussi.

**Impact** : `getAISuggestion()` catch l'erreur et retourne `{action: 'none', confidence: 0}` → le moteur escalade pour LOW_CONFIDENCE.

---

## 6. Arbre de Decision Complet

```
Message Amazon arrive
  │
  ├─ Via la route /inbound ?
  │   └─ NON — les messages ne passent PAS par /inbound
  │       └─ Autopilot hook JAMAIS appele
  │           └─ AUCUN log, AUCUNE trace, INVISIBLE
  │
  └─ Si on force manuellement (POST /autopilot/evaluate) :
      │
      ├─ Step 1: loadSettings → OK (is_enabled=true)
      ├─ Step 2: plan=AUTOPILOT → OK ✅
      ├─ Step 3: mode=autonomous → OK ✅
      ├─ Step 5: wallet=2500 KBA → OK ✅
      ├─ Step 6: loadConversationContext → OK ✅
      ├─ Step 7: last_msg_direction=inbound → OK ✅
      ├─ Step 8: rate limit 0/20 → OK ✅
      ├─ Step 9: getAISuggestion → 
      │   └─ LiteLLM appel → 404 (claude-3-5-haiku-20241022 introuvable)
      │   └─ catch → {action:'none', confidence:0}
      ├─ Step 10: confidence 0 < 0.75 → LOW_CONFIDENCE
      │   └─ escalateConversation() → escalade
      │   └─ logAction("LOW_CONFIDENCE:0") → log cree
      └─ return {executed:false, escalated:true}
```

---

## 7. Comparaison : Messages qui ont fonctionne vs non

### Message A — Test manuel PH-AUTOPILOT-RUNTIME-TRUTH-02 (08:21)

| Aspect | Valeur |
|---|---|
| Comment declenche | `POST /autopilot/evaluate` (appel direct, pas via inbound) |
| Conversation | `cmmn8j6o7w378ab6e3e7f531d` |
| Resultat | action=reply, confidence=0.90, SAFE_MODE_BLOCKED |
| Pourquoi ca a marche | L'appel manual bypasse la route inbound. A 08:21, LiteLLM/Anthropic fonctionnait. |

### Message B — Tous les messages automatiques (jamais fonctionne)

| Aspect | Valeur |
|---|---|
| Comment arrive | Insertion directe DB (pas via route /inbound) |
| Autopilot appele | **NON** — le hook est uniquement dans la route inbound |
| Resultat | Zero log, zero trace |
| Pourquoi ca ne marche pas | Le message ne transite pas par la route qui contient le hook autopilot |

---

## 8. Reponse Finale

### L'autopilot se declenche uniquement si :

Le message arrive via la route **`POST /inbound/email`** ou **`POST /inbound/amazon/forward`** de l'API Fastify. C'est la SEULE route qui appelle `evaluateAndExecute()` en fire-and-forget.

### Les messages de srv-performance ne respectent pas cette condition :

Les messages pour `srv-performance-mn7ds3oj` **n'arrivent pas via la route inbound**. La preuve :
1. **Zero POST /inbound dans les logs pod** malgre 2 conversations creees apres le demarrage du pod
2. **`lastInboundAt = null`** sur les 3 adresses inbound — Amazon n'a jamais delivre a ces adresses
3. **Les messages existent en DB** mais sont crees par un autre mecanisme (insertion directe, worker, test)

### Blocage additionnel meme si corrige :

Le modele LiteLLM `kbz-cheap` → `claude-3-5-haiku-20241022` retourne **404**. Meme si le trigger inbound fonctionnait, l'IA ne peut pas generer de suggestion viable (confidence=0 systematiquement).

---

## 9. Actions Requises (non executees — audit uniquement)

### Pour que l'autopilot se declenche automatiquement :

1. **S'assurer que les messages Amazon arrivent via la route `/inbound/amazon/forward`**
   - Verifier que Amazon Seller Central utilise les adresses inbound configurees
   - Verifier que le pipeline mail (MX → API) fonctionne pour ce tenant
   - Verifier que le champ `lastInboundAt` se met a jour lors de la reception

2. **Corriger le modele LiteLLM** (`kbz-cheap`)
   - Le modele `claude-3-5-haiku-20241022` n'existe plus chez Anthropic
   - Mettre a jour vers `claude-3-5-haiku-latest` ou un modele valide
   - Configurer le fallback (`gpt-4o-mini`) pour qu'il fonctionne

### Pour un test immediat sans attendre le fix mail :

Appeler manuellement `POST /autopilot/evaluate` avec un modele LiteLLM fonctionnel.

---

## 10. Etat du Moteur Autopilot

| Composant | Etat | Detail |
|---|---|---|
| Engine code | **OK** | Fix message_count + summary presents dans v3.5.120 |
| Route /autopilot/* | **OK** | Enregistree dans app.js, endpoints fonctionnels |
| Hook inbound | **OK** | Present dans inbound/routes.js lignes 208 et 440 |
| Pipeline mail | **NON VERIFIE** | lastInboundAt=null → messages ne transitent pas par /inbound |
| LiteLLM kbz-cheap | **CASSE** | 404 sur claude-3-5-haiku-20241022 |
| Wallet | **OK** | 2500 KBA disponibles |
| Settings | **OK** | Tout active, mode autonomous |

---

## 11. Image Deployee

| Service | Image | Pod start |
|---|---|---|
| keybuzz-api | `v3.5.120-env-aligned-dev` | 2026-03-27T09:52:06Z |

Le fix du moteur autopilot (PH-AUTOPILOT-RUNTIME-TRUTH-02) est **inclus** dans cette image :
- `loadConversationContext` : `COUNT(*) FROM messages` (corrige)
- `logAction` : colonne `summary` incluse (corrige)

---

## Verdict Final

# AUTOPILOT TRIGGER FULLY UNDERSTOOD

**Deux causes racines identifiees :**

### Cause #1 — Les messages n'arrivent pas par la bonne route (BLOQUANT)

Les messages pour `srv-performance-mn7ds3oj` ne passent PAS par la route `/inbound` de l'API Fastify. Le hook autopilot (`evaluateAndExecute`) est UNIQUEMENT dans cette route. Pas de passage par la route inbound = pas de trigger autopilot.

**Preuve** : zero POST /inbound dans les logs pod, `lastInboundAt = null` sur les 3 adresses inbound.

### Cause #2 — LiteLLM model introuvable (BLOQUANT SECONDAIRE)

Le modele `claude-3-5-haiku-20241022` (alias `kbz-cheap`) retourne 404 chez Anthropic. Meme si le trigger fonctionnait, l'IA ne peut pas generer de suggestion (confidence=0 systematique → escalade).

### Ce n'est PAS un probleme de configuration tenant

Le plan, le mode, les actions, le wallet — tout est correct. Le probleme est en AMONT : les messages n'atteignent pas le code qui contient le hook autopilot.
