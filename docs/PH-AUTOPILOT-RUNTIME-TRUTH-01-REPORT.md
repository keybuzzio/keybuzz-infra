# PH-AUTOPILOT-RUNTIME-TRUTH-01 — Rapport

> **Date** : 26 mars 2026
> **Phase** : PH-AUTOPILOT-RUNTIME-TRUTH-01
> **Environnement** : DEV uniquement
> **Type** : Audit verite — declenchement reel de l'autopilot

---

## 1. Conditions Exactes du Moteur (ph131c-engine.ts)

Le moteur `evaluateAndExecute` execute ces verifications dans l'ordre :

| # | Condition | Valeur requise | Refus |
|---|---|---|---|
| 1 | `autopilot_settings` existe | Row presente | `NO_SETTINGS` |
| 2 | `is_enabled` | `true` | `DISABLED` |
| 3 | Plan tenant | `AUTOPILOT` ou `ENTERPRISE` | `PLAN_INSUFFICIENT:{plan}` |
| 4 | Mode | `autonomous` | `MODE_NOT_AUTONOMOUS:{mode}` |
| 5 | KBActions wallet | > 0 | `WALLET_EMPTY` |
| 6 | Conversation | existe | `CONVERSATION_NOT_FOUND` |
| 7 | Dernier message | `direction = inbound` | `LAST_MESSAGE_NOT_INBOUND` |
| 8 | Rate limit | < 20 actions/heure | `RATE_LIMITED` |
| 9 | Confiance IA | >= 0.75 | escalade (pas de blocage) |
| 10 | `safe_mode` + action | `reply` bloque si safe_mode=true | escalade |
| 11 | `allow_auto_*` flags | true pour l'action concernee | blocage |

---

## 2. Etat Reel du Tenant de Test (ecomlg-001)

### autopilot_settings (DB)

| Champ | Valeur | Requis pour autopilot |
|---|---|---|
| `is_enabled` | **true** | true |
| `mode` | **supervised** | **autonomous** REQUIS |
| `allow_auto_reply` | **false** | true |
| `allow_auto_assign` | **false** | true |
| `allow_auto_escalate` | **false** | true |
| `safe_mode` | **true** | false pour auto-reply |
| `escalation_target` | client | - |

### ai_settings (API)

| Champ | Valeur |
|---|---|
| `mode` | supervised |
| `ai_enabled` | true |
| `safe_mode` | true |
| `kill_switch` | false |

### Plan / Billing

| Champ | Valeur | Requis pour autopilot |
|---|---|---|
| `plan` | **PRO** | **AUTOPILOT** ou **ENTERPRISE** REQUIS |
| `status` | active | - |

### Wallet

| Champ | Valeur |
|---|---|
| `kba_remaining` | 4.11 |
| `kba_purchased` | 50 |

---

## 3. Test Direct du Moteur

### POST /autopilot/evaluate (runtime)

```json
{
  "executed": false,
  "action": "none",
  "reason": "PLAN_INSUFFICIENT:PRO",
  "confidence": 0,
  "escalated": false,
  "kbActionsDebited": 0,
  "requestId": "req-mn83yt7lamd4vo"
}
```

Le moteur refuse a l'etape 3 : le plan est PRO, il faut AUTOPILOT ou ENTERPRISE.

### Historique Autopilot

```json
{ "actions": [], "total": 0 }
```

**Zero** actions autopilot executees dans l'historique complet du tenant.

---

## 4. Chaine de Blocage Complete

Si le plan etait correct (AUTOPILOT), les etapes suivantes bloqueraient egalement :

| Etape | Condition | Etat actuel | Bloquerait ? |
|---|---|---|---|
| 3 | Plan >= AUTOPILOT | PRO | **OUI (1er blocage)** |
| 4 | Mode = autonomous | supervised | **OUI** |
| 10 | safe_mode + reply | safe_mode=true | **OUI** (escalade au lieu d'execution) |
| 11a | allow_auto_reply | false | **OUI** |
| 11b | allow_auto_assign | false | **OUI** |
| 11c | allow_auto_escalate | false | **OUI** |

L'autopilot est bloque par **6 conditions simultanees**.

---

## 5. Reponse Verite Finale

### Le moteur ne s'est pas declenche parce que :

**A. Plan insuffisant (PRO au lieu de AUTOPILOT/ENTERPRISE)**
- C'est le premier point de blocage dans le pipeline du moteur
- Le moteur retourne `PLAN_INSUFFICIENT:PRO` et s'arrete immediatement

**B. Mode non-autonome (supervised au lieu de autonomous)**
- Meme avec le bon plan, le mode `supervised` empecherait l'execution

**C. Toutes les actions auto sont desactivees**
- `allow_auto_reply = false`
- `allow_auto_assign = false`
- `allow_auto_escalate = false`
- Meme avec le bon plan ET le bon mode, aucune action ne serait autorisee

**D. Safe mode bloque les reponses automatiques**
- `safe_mode = true` bloque specifiquement l'action `reply`

### Comportement = ATTENDU, PAS un bug

Le moteur fonctionne exactement comme designe. Les conditions ne sont pas reunies.

---

## 6. Reproduction du Test Product Owner

Le PO a active le toggle "Activer le pilotage IA" (`is_enabled=true`) dans Settings > IA, mais :
- N'a pas change le plan (reste PRO)
- N'a pas change le mode (reste supervised)
- N'a pas active les flags auto (tous false)
- N'a pas desactive safe_mode

**Resultat previsible** : rien ne se passe, car le moteur refuse au premier check.

---

## 7. Pour que l'Autopilot Fonctionne Reellement

Le PO devrait, dans cet ordre :

| # | Action | Actuel | Requis |
|---|---|---|---|
| 1 | Changer de plan | PRO | **AUTOPILOT** ($497/mois) |
| 2 | Changer le mode IA | supervised | **autonomous** |
| 3 | Activer auto-reply | false | **true** |
| 4 | Desactiver safe_mode | true | **false** (ou laisser si seule l'assignation est voulue) |
| 5 | S'assurer de KBActions suffisantes | 4.11 + 50 purchased | OK |

### Alternative pour tester (DEV uniquement)

Pour tester en DEV sans changer de plan, il faudrait modifier la logique du moteur pour accepter PRO en dev, ou simuler un plan AUTOPILOT sur le tenant de test. Mais ce n'est PAS recommande car cela ne reflete pas le comportement production.

---

## 8. Declencheurs du Moteur

| Trigger | Source | Actif ? |
|---|---|---|
| Message entrant (inbound) | `src/modules/inbound/routes.ts` → `evaluateAndExecute(conversationId, tenantId, 'inbound')` | OUI (cable dans PH131-C) |
| Evaluation manuelle | `POST /autopilot/evaluate` | OUI (fonctionne, retourne PLAN_INSUFFICIENT) |
| Automatique periodique | Aucun CronJob autopilot configure | NON |

Le trigger inbound est actif : chaque nouveau message entrant appelle `evaluateAndExecute` en fire-and-forget. Mais le moteur refuse immediatement a cause du plan.

---

## 9. Ce qui n'a PAS ete modifie

| Element | Statut |
|---|---|
| Backend API | INTACT |
| Moteur autopilot | INTACT |
| Base de donnees | INTACT (lecture seule) |
| Billing | INTACT |
| Amazon | INTACT |
| AI inbox | INTACT |

---

## 10. Verdict Final

**AUTOPILOT BEHAVIOR EXPLAINED**

Le moteur autopilot fonctionne **exactement comme designe**. Il ne s'est pas declenche parce que le tenant de test `ecomlg-001` :

1. A un plan **PRO** (il faut **AUTOPILOT** ou **ENTERPRISE**)
2. Est en mode **supervised** (il faut **autonomous**)
3. A tous les flags auto a **false**
4. A **safe_mode** actif

**Ce n'est PAS un bug.** C'est le comportement attendu du moteur de securite.

Zero actions autopilot n'ont jamais ete executees sur ce tenant.
