# PH-AUTOPILOT-RUNTIME-TRUTH-02 — Rapport Final

> **Date** : 27 mars 2026
> **Phase** : PH-AUTOPILOT-RUNTIME-TRUTH-02
> **Environnement** : DEV uniquement
> **Tenant audite** : `srv-performance-mn7ds3oj` (SRV Performance)

---

## 1. Tenant Exact Audite

| Champ | Valeur |
|---|---|
| **tenant_id** | `srv-performance-mn7ds3oj` |
| **name** | SRV Performance |
| **plan** | **AUTOPILOT** |
| **status** | active |
| **billing status** | trialing |
| **owner** | ludo.gonthier@gmail.com |

### Autopilot Settings (runtime)

| Parametre | Valeur | Requis |
|---|---|---|
| is_enabled | **true** | true |
| mode | **autonomous** | autonomous |
| allow_auto_reply | **true** | true |
| allow_auto_assign | **true** | true |
| allow_auto_escalate | **true** | true |
| safe_mode | **true** | - |
| escalation_target | client | - |

### Wallet

| Champ | Valeur |
|---|---|
| KBActions restants | **2500** (2000 inclus + 500 achetes) |
| Utilises aujourd'hui | **0** |
| Utilises 7j | **0** |
| Calls today | **0** |
| Calls 7d | **0** |

> Le wallet n'a **JAMAIS ete utilise**. Zero appel IA. Zero KBAction debite.

---

## 2. Scenario Exact Reproduit

### Conversations existantes

| Conversation | Canal | Status | Date | Messages |
|---|---|---|---|---|
| `cmmn8j6o7w378ab6e3e7f531d` | amazon | open | 27 mars 06:39 | 2 inbound (HUMAN) |
| `cmmn7g3swfb8674b61f901ec9` | amazon | open | 26 mars 12:25 | 1 inbound (HUMAN) |
| `cmmn7e7x0061a0a7b0b43ee1e` | amazon | open | 26 mars 11:32 | 1 inbound (HUMAN) |
| `cmmn7e6oucad9120d391f4331` | amazon | open | 26 mars 11:31 | 1 inbound (HUMAN) |

Toutes les conversations sont :
- Canal **amazon**
- Status **open**
- Messages **inbound** de source **HUMAN**
- Agent assigne : **null**

### Test effectue

Conversation cible : `cmmn8j6o7w378ab6e3e7f531d` (la plus recente, 2 messages inbound Amazon).

---

## 3. Trigger Inbound — Cablage Verifie

Le code compile `/app/dist/modules/inbound/routes.js` contient bien le trigger autopilot :

```
Ligne 4:   const engine_1 = require("../autopilot/engine");
Ligne 206: // PH131-C: Autopilot engine evaluation (fire-and-forget)
Ligne 208: (0, engine_1.evaluateAndExecute)(conversationId, body.tenantId, 'inbound')
Ligne 438: // PH131-C: Autopilot engine evaluation (fire-and-forget)
Ligne 440: (0, engine_1.evaluateAndExecute)(conversationId, inboundPayload.tenantId, 'inbound')
```

**Le trigger est correctement cable** :
- Sur le path email (ligne 208)
- Sur le path Amazon (ligne 440)
- Les deux en fire-and-forget avec `.catch()`

Le module autopilot est enregistre dans app.js :
```
Ligne 59:  const routes_22 = require("./modules/autopilot/routes");
Ligne 175: app.register(routes_22.autopilotRoutes, { prefix: '/autopilot' });
```

---

## 4. Pipeline de Decision — Trace Complete

### AVANT le fix (image `v3.5.115`)

| Etape | Check | Resultat | Detail |
|---|---|---|---|
| 1 | Load settings | OK | is_enabled=true |
| 2 | Plan >= AUTOPILOT | OK | plan=AUTOPILOT |
| 3 | Mode = autonomous | OK | mode=autonomous |
| 4 | Safe mode | DEFERE | Verifie per-action plus tard |
| 5 | Wallet > 0 | OK | 2500 KBA |
| 6 | **Load conversation context** | **CRASH SQL** | `column c.message_count does not exist` |

**Root cause** : La requete SQL dans `loadConversationContext()` reference `c.message_count` mais la table `conversations` n'a PAS de colonne `message_count`.

**Bug secondaire** : Le handler `catch` appelle `logAction()` qui insere dans `ai_action_log` SANS la colonne `summary` (NOT NULL), provoquant un second crash silencieux.

Resultat : ZERO log, ZERO historique, erreur totalement invisible.

### APRES le fix (image `v3.5.48-ph-autopilot-engine-fix`)

| Etape | Check | Resultat | Detail |
|---|---|---|---|
| 1 | Load settings | OK | is_enabled=true |
| 2 | Plan >= AUTOPILOT | OK | plan=AUTOPILOT |
| 3 | Mode = autonomous | OK | mode=autonomous |
| 4 | Safe mode | DEFERE | Verifie per-action plus tard |
| 5 | Wallet > 0 | OK | 2500 KBA |
| 6 | Load conversation context | **OK** | message_count=2 via COUNT subquery |
| 7 | Last message direction = inbound | OK | direction=inbound |
| 8 | Rate limit | OK | 0 actions/heure |
| 9 | AI suggestion | OK | action=reply, confidence=0.9 |
| 10 | Safe mode check | **BLOQUE** | safe_mode=true, reply est dans SAFE_MODE_BLOCKED_ACTIONS |
| 11 | Escalation | OK | Conversation escaladee |
| 12 | Log action | **OK** | summary rempli, log cree dans ai_action_log |

---

## 5. Bugs Identifies et Corriges

### Bug 1 : SQL `c.message_count` inexistant (CRITIQUE)

**Fichier** : `/opt/keybuzz/keybuzz-api/src/modules/autopilot/engine.ts`
**Fonction** : `loadConversationContext()`

```
AVANT :
  c.assigned_agent_id, c.message_count,

APRES :
  c.assigned_agent_id,
  (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id) as message_count,
```

**Impact** : Le moteur crashait a CHAQUE appel, rendant l'autopilot 100% non fonctionnel sur TOUS les tenants.

### Bug 2 : `logAction` sans colonne `summary` (CRITIQUE)

**Fichier** : meme fichier
**Fonction** : `logAction()`

```
AVANT :
  INSERT INTO ai_action_log (id, tenant_id, conversation_id, action_type, status, blocked, ...)
  VALUES ($1, $2, $3, $4, $5, $6, ...)

APRES :
  INSERT INTO ai_action_log (id, tenant_id, conversation_id, action_type, status, summary, blocked, ...)
  VALUES ($1, $2, $3, $4, $5, $6, $7, ...)
  + ajout du parametre reason || `Autopilot ${action}` pour la colonne summary
```

**Impact** : Meme les erreurs n'etaient pas loguees. Le bug etait totalement invisible — aucun log, aucun historique, aucune trace.

---

## 6. Historique Autopilot

### Avant le fix

```json
{"actions": [], "total": 0}
```

L'historique etait vide car :
1. Le moteur crashait avant toute action (bug SQL)
2. Le log d'erreur crashait aussi (bug summary NOT NULL)
3. Aucune trace n'etait creee nulle part

### Apres le fix

```json
{
  "actions": [{
    "id": "alog-1774599683207-oqa5twya7",
    "conversation_id": "cmmn8j6o7w378ab6e3e7f531d",
    "action_type": "autopilot_reply",
    "status": "skipped",
    "blocked": true,
    "blocked_reason": "SAFE_MODE_BLOCKED",
    "confidence_score": "0.90",
    "payload": {
      "reason": "SAFE_MODE_BLOCKED",
      "source": "autopilot_engine",
      "kbaCost": 0,
      "requestId": "req-mn8mtwajfft5wq"
    },
    "created_at": "2026-03-27T08:21:23.220Z"
  }],
  "total": 1
}
```

Le moteur fonctionne correctement : il a suggere un reply avec confidence=0.90, mais safe_mode l'a bloque et escalade a la place.

---

## 7. Observation : safe_mode=true

**Note importante pour le PO** : meme avec le fix, `safe_mode=true` BLOQUE l'action `reply` automatique. C'est un **comportement attendu** du moteur — le safe mode escalade au lieu de repondre directement.

Si le PO souhaite que l'autopilot reponde automatiquement aux clients, il faut :

```sql
UPDATE autopilot_settings SET safe_mode = false WHERE tenant_id = 'srv-performance-mn7ds3oj';
```

Ou via l'UI dans les settings autopilot.

Avec `safe_mode=false`, le moteur aurait :
- Envoye la reponse IA (confidence=0.90, au-dessus du seuil de 0.75)
- Debite les KBActions correspondants
- Logue l'action comme `completed`

---

## 8. Validations DEV

### Image deployee

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph-autopilot-engine-fix-dev
```

### Resultats

| Test | Resultat | Detail |
|---|---|---|
| Health check | OK | `{"status":"ok","service":"keybuzz-api"}` |
| Evaluate conv1 | OK | action=reply, confidence=0.9, SAFE_MODE_BLOCKED, escalated=true |
| Evaluate conv2 | OK | action=none, LOW_CONFIDENCE:0, escalated=true |
| AI Action Log | OK | 1 entree creee avec summary rempli |
| Autopilot History | OK | 1 action visible |
| Pod logs | OK | Pas d'erreur SQL, pas d'erreur logAction |

### Non-regressions

| Service | Status |
|---|---|
| API /health | OK |
| Inbox conversations | OK (4 conversations listees) |
| Wallet status | OK (2500 KBA) |
| Billing current | OK (AUTOPILOT, trialing) |
| AI settings | OK |

---

## 9. Diff Minimal

```diff
--- engine.ts.bak-truth02
+++ engine.ts
@@ -273 +273,2 @@
-           c.assigned_agent_id, c.message_count,
+           c.assigned_agent_id,
+           (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id) as message_count,
@@ -463,2 +464,2 @@
-      `INSERT INTO ai_action_log (id, tenant_id, conversation_id, action_type, status, blocked, blocked_reason, confidence_score, payload, created_at)
-       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, now())`,
+      `INSERT INTO ai_action_log (id, tenant_id, conversation_id, action_type, status, summary, blocked, blocked_reason, confidence_score, payload, created_at)
+       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, now())`,
@@ -468 +470 @@
+        reason || `Autopilot ${action}`,
```

3 lignes modifiees, 1 ajoutee. **Diff minimal.**

---

## 10. Rollback

| Env | Rollback safe | Commande |
|---|---|---|
| DEV | `v3.5.115-ph-amz-false-connected-dev` | `kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.115-ph-amz-false-connected-dev -n keybuzz-api-dev` |

---

## Verdict Final

# AUTOPILOT BUG CONFIRMED ON SRV PERFORMANCE

**Deux bugs SQL critiques dans le moteur autopilot** rendaient l'engine 100% non fonctionnel sur TOUS les tenants :

1. **`c.message_count`** : colonne inexistante dans la table `conversations` — crash SQL a chaque appel
2. **`logAction` sans `summary`** : colonne NOT NULL manquante — crash silencieux du logging, rendant le bug invisible

**Fix applique** : `v3.5.48-ph-autopilot-engine-fix-dev` — 3 lignes modifiees, 1 ajoutee.

**Resultat apres fix** : le moteur fonctionne, suggere des actions (confidence=0.90), mais `safe_mode=true` bloque les replies automatiques (comportement attendu). Si le PO veut des replies auto, desactiver safe_mode.
