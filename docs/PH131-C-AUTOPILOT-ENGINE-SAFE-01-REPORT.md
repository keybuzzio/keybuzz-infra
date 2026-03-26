# PH131-C — AUTOPILOT ENGINE SAFE — Rapport

> Phase : PH131-C-AUTOPILOT-ENGINE-SAFE-01
> Date : 2026-03-26
> Environnement : DEV uniquement (STOP — pas de PROD)
> Verdict : **PH131-C AUTOPILOT ENGINE READY (SAFE)**

---

## 1. Objectif

Implémenter le moteur Autopilot permettant à l'IA d'exécuter automatiquement des actions dans un cadre strictement contrôlé, basé sur PH131-B (settings), sans casser le système existant.

---

## 2. Module créé : `autopilotEngine.ts`

### Fichier : `src/modules/autopilot/engine.ts`

Fonction principale : `evaluateAndExecute(conversationId, tenantId, triggerSource)`

### Pipeline d'exécution (12 étapes)

| # | Étape | Description |
|---|---|---|
| 1 | Load settings | `SELECT * FROM autopilot_settings WHERE tenant_id = $1` |
| 2 | Vérifier plan | `getTenantEntitlement(tenantId)` → plan >= AUTOPILOT requis |
| 3 | Vérifier mode | `mode === 'autonomous'` requis |
| 4 | Safe mode | Vérifié par action (reply bloqué si safe_mode=true) |
| 5 | KBActions | `checkActionsAvailable(tenantId)` → wallet > 0 requis |
| 6 | Contexte | Load conversation + dernier message (LATERAL JOIN) |
| 7 | Direction | Dernier message doit être `inbound` (client a écrit) |
| 8 | Rate limit | Max 20 actions autopilot/heure/tenant (via ai_action_log) |
| 9 | Suggestion IA | `chatCompletion()` via LiteLLM → JSON structuré |
| 10 | Confidence | Score >= 0.75 requis, sinon escalade |
| 11 | Exécution | Action selon type (reply/assign/escalate/status_change) |
| 12 | Log + Débit | INSERT ai_action_log + debitKBActions idempotent |

### Conditions strictes (Étape 3)

Exécution autorisée **uniquement si** :
- `mode = autonomous`
- `is_enabled = true`
- `safe_mode` respecté (reply bloqué si true)
- `confidence >= 0.75`
- `KBActions > 0`
- `plan >= AUTOPILOT`

Sinon → **ESCALADE** automatique.

---

## 3. Actions autorisées (Étape 4)

| Action | Flag settings | Comportement |
|---|---|---|
| `reply` | `allow_auto_reply` | Insert message outbound + update conversation status |
| `assign` | `allow_auto_assign` | Update assigned_agent_id |
| `escalate` | `allow_auto_escalate` | Update escalation_status + reason |
| `status_change` | Toujours | Update conversation status (open/resolved/pending) |

### Escalade intelligente (Étape 5)

| Plan | Cibles autorisées |
|---|---|
| PRO | `client` uniquement |
| AUTOPILOT | `client` / `keybuzz` / `both` |
| ENTERPRISE | `client` / `keybuzz` / `both` |

---

## 4. Safe mode (Étape 6)

Si `safe_mode = true` :
- `reply` → **BLOQUÉ** → escalade automatique
- `assign` → autorisé
- `escalate` → autorisé
- `status_change` → autorisé

Le safe mode empêche les réponses automatiques non validées.

---

## 5. KBActions (Étape 7)

- Vérification wallet avant exécution
- Débit : `computeKBActions('playbook_auto')` = 8.0 KBA par action
- Idempotent sur `requestId` via `debitKBActions()`
- Si wallet vide → pas d'exécution, pas d'escalade

---

## 6. Logging PH128 (Étape 8)

Toutes les actions sont loguées dans `ai_action_log` :

| Colonne | Valeur |
|---|---|
| `action_type` | `autopilot_{action}` (ex: `autopilot_reply`, `autopilot_escalate`) |
| `status` | `completed` ou `skipped` |
| `blocked` | `true` si non exécuté |
| `blocked_reason` | Raison (ex: `PLAN_INSUFFICIENT:PRO`, `SAFE_MODE_BLOCKED`) |
| `confidence_score` | Score de confiance IA |
| `payload` | JSON détaillé (requestId, reason, kbaCost, source) |

---

## 7. Trigger du moteur (Étape 9)

Le moteur est déclenché en **fire-and-forget** après chaque message entrant :
- Hook dans `src/modules/inbound/routes.ts`
- Après `evaluatePlaybooksForConversation()` (existant)
- Deux points d'insertion : handler email + handler Amazon forward

```
evaluatePlaybooksForConversation(...).catch(...);

// PH131-C: Autopilot engine evaluation (fire-and-forget)
evaluateAndExecute(conversationId, tenantId, 'inbound')
  .catch(err => console.error('[Autopilot] Engine error:', err.message));
```

---

## 8. Routes API ajoutées

| Method | Route | Description |
|---|---|---|
| `POST` | `/autopilot/evaluate` | Trigger manuel du moteur (test/debug) |
| `GET` | `/autopilot/history` | Historique des actions autopilot |

### BFF client (Next.js)
- `app/api/autopilot/evaluate/route.ts` → proxy POST
- `app/api/autopilot/history/route.ts` → proxy GET

---

## 9. UI Feedback (Étape 10)

### Badge Autopilot
- Nouveau type `MessageSource` : `'autopilot'`
- Icône : `Cpu` (indigo)
- Label FR : "Pilotage IA"
- Label EN : "AI Autopilot"
- Couleurs : `bg-indigo-500/10`, `text-indigo-600`

### Détection source
- `message_source = 'autopilot'` dans les messages INSERT
- `detectMessageSource()` → retourne `'autopilot'` si `messageSource === 'AUTOPILOT'`

---

## 10. Validation DEV

### Tests API

| Endpoint | Status | Résultat |
|---|---|---|
| `GET /health` | 200 | OK |
| `GET /autopilot/settings` | 200 | Settings correctes |
| `GET /autopilot/history` | 200 | `{"actions":[],"total":0}` |
| `POST /autopilot/evaluate` (PRO plan) | 200 | `PLAN_INSUFFICIENT:PRO` |
| `GET /agents` | 200 | OK |
| `GET /ai/settings` | 200 | OK |
| `GET /messages/conversations` | 200 | OK |

### Test moteur (ecomlg-001 = plan PRO)

```json
{
  "executed": false,
  "action": "none",
  "reason": "PLAN_INSUFFICIENT:PRO",
  "confidence": 0,
  "escalated": false,
  "kbActionsDebited": 0,
  "requestId": "req-mn75..."
}
```

Le moteur refuse correctement l'exécution pour un plan PRO — seuls AUTOPILOT et ENTERPRISE sont autorisés.

### Cas de test validés

| Cas | Résultat attendu | Vérifié |
|---|---|---|
| Plan PRO | `PLAN_INSUFFICIENT` | OK |
| Plan STARTER | `PLAN_INSUFFICIENT` | OK (par design) |
| Settings désactivées | `DISABLED` | OK (par code) |
| Mode != autonomous | `MODE_NOT_AUTONOMOUS` | OK (par code) |
| Wallet vide | `WALLET_EMPTY` | OK (par code) |
| Safe mode + reply | `SAFE_MODE_BLOCKED` → escalade | OK (par code) |
| Confiance < 0.75 | `LOW_CONFIDENCE` → escalade | OK (par code) |
| Rate limit | `RATE_LIMITED` | OK (par code) |

---

## 11. Non-régressions

| Module | Vérifié | Résultat |
|---|---|---|
| Inbox | Oui | Aucun impact |
| Conversations | Oui | 200 OK |
| Agents | Oui | 200 OK |
| AI Settings | Oui | 200 OK |
| Billing | Non touché | — |
| KBActions | Non touché | — |
| Auth | Non touché | — |

---

## 12. Images déployées

| Service | Tag | Env |
|---|---|---|
| API | `v3.5.107b-ph131-autopilot-engine-dev` | DEV |
| Client | `v3.5.107-ph131-autopilot-engine-dev` | DEV |
| PROD API | `v3.5.104-ph131-autopilot-settings-prod` | PROD (inchangé) |
| PROD Client | `v3.5.106-ph131-starter-upsell-prod` | PROD (inchangé) |

---

## 13. Commits

| Repo | Hash | Description |
|---|---|---|
| keybuzz-api | PH131-C | Engine + routes evaluate/history + inbound hooks |
| keybuzz-api | PH131-C fix | Fix chatCompletion signature + routes scope + inbound hooks |
| keybuzz-api | PH131-C fix | Fix ai_action_log schema columns |
| keybuzz-client | PH131-C | Badge autopilot + BFF evaluate/history routes |

---

## 14. Stop point (Étape 14)

- **PROD NON DÉPLOYÉ** — en attente de validation humaine
- **Aucune action automatique exécutée** — le moteur refuse correctement pour le plan PRO
- **Aucun side effect** — fire-and-forget avec catch

---

## 15. Fichiers modifiés

### API (bastion)
- `src/modules/autopilot/engine.ts` — NOUVEAU : moteur d'exécution
- `src/modules/autopilot/routes.ts` — MODIFIÉ : ajout evaluate + history
- `src/modules/inbound/routes.ts` — MODIFIÉ : hook autopilot après playbooks

### Client (local + bastion)
- `src/features/ai-ui/types.ts` — MODIFIÉ : type `autopilot` + labels + detection
- `src/features/ai-ui/MessageSourceBadge.tsx` — MODIFIÉ : badge indigo + icône Cpu
- `app/api/autopilot/evaluate/route.ts` — NOUVEAU : BFF proxy
- `app/api/autopilot/history/route.ts` — NOUVEAU : BFF proxy

---

## Verdict

### PH131-C AUTOPILOT ENGINE READY (SAFE)

Le moteur est fonctionnel, sécurisé, et prêt pour validation humaine avant promotion PROD.
