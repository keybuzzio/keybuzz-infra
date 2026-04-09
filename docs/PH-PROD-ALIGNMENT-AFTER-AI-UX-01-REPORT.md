# PH-PROD-ALIGNMENT-AFTER-AI-UX-01 — Rapport Final

> **Date** : 27 mars 2026
> **Phase** : PH-PROD-ALIGNMENT-AFTER-AI-UX-01
> **Type** : Promotion controlee DEV → PROD

---

## 1. Source de Verite

| Check | Resultat |
|---|---|
| Git local (main) | Up to date with origin |
| Bastion API source | Fix autopilot present (COUNT subquery + summary) |
| Bastion Client source | AISuggestionSlideOver avec auto-retry present |
| Images DEV correspondent au code | OUI |

**SOURCE OF TRUTH DEV = OK**

---

## 2. Images Promues

### Avant promotion

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.48-ph-autopilot-engine-fix-dev` | `v3.5.115-ph-amz-false-connected-prod` |
| Client | `v3.5.119-ph-ai-assist-reliability-dev` | `v3.5.113-ph-trial-plan-fix-prod` |

### Apres promotion

| Service | DEV | PROD | Aligne |
|---|---|---|---|
| API | `v3.5.48-ph-autopilot-engine-fix-dev` | `v3.5.48-ph-autopilot-engine-fix-prod` | OUI |
| Client | `v3.5.119-ph-ai-assist-reliability-dev` | `v3.5.119-ph-ai-assist-reliability-prod` | OUI |

**Meme codebase, seules les variables d'environnement different (API URLs, DB).**

---

## 3. Compatibilite PROD Verifiee

| Element | DEV | PROD | Compatible |
|---|---|---|---|
| `autopilot_settings` table | EXISTS | EXISTS (identique) | OUI |
| `ai_action_log.summary` | NOT NULL | NOT NULL (identique) | OUI |
| `conversations.message_count` | ABSENT | ABSENT (identique) | OUI |
| `messages.body` | EXISTS | EXISTS (identique) | OUI |
| `entitlement.service` | EXISTS | EXISTS | OUI |
| `ai-actions.service` | EXISTS | EXISTS | OUI |
| `litellm.service` | EXISTS | EXISTS | OUI |
| Module autopilot | engine.js + routes.js | engine.js + routes.js | OUI |

**PROD COMPATIBILITY = OK**

---

## 4. Phases Incluses dans la Promotion

| Phase | Description | Type |
|---|---|---|
| PH-AI-INBOX-UNIFIED-ENTRY-03 | Unification entree IA inbox (suppression Assist IA, Aide IA unique) | Client |
| PH-AI-ASSIST-RELIABILITY-01 | Fix generation IA instable (auto-retry sur status limited) | Client |
| PH-AUTOPILOT-RUNTIME-TRUTH-02 | Fix SQL autopilot engine (c.message_count + logAction summary) | API |

### Changements API (PH-AUTOPILOT-RUNTIME-TRUTH-02)

```diff
- c.assigned_agent_id, c.message_count,
+ c.assigned_agent_id,
+ (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id) as message_count,

- INSERT INTO ai_action_log (id, ... status, blocked, ...)
+ INSERT INTO ai_action_log (id, ... status, summary, blocked, ...)
+ reason || `Autopilot ${action}`,
```

### Changements Client (PH-AI-INBOX-UNIFIED-ENTRY-03 + PH-AI-ASSIST-RELIABILITY-01)

- Suppression bouton "Assist IA" et `AIDecisionPanel` de l'inbox
- "Aide IA" = entree unique IA (PRO+ only via FeatureGate)
- "Modeles" = accessible a tous les plans
- Auto-retry transparent sur status "limited" dans `AISuggestionSlideOver`

---

## 5. Validation Technique PROD

| Test | Resultat | Detail |
|---|---|---|
| Pods API | Running | 0 restarts |
| Pods Client | Running | 0 restarts |
| /health | 200 | `{"status":"ok","service":"keybuzz-api"}` |
| Autopilot SQL fix | VERIFIE | COUNT subquery present dans engine.js compile |
| Autopilot summary fix | VERIFIE | summary dans INSERT ai_action_log |
| Pod logs | CLEAN | Aucune erreur |

---

## 6. Validation Produit PROD

| Endpoint | Status | Detail |
|---|---|---|
| /billing/current | 200 | plan=PRO, status=active, channelsUsed=1 |
| /ai/settings | 200 | mode=supervised, ai_enabled=true |
| /ai/wallet/status | 200 | remaining=388.67, includedMonthly=1000 |
| /autopilot/settings | 200 | mode=off (ecomlg-001 = PRO, pas AUTOPILOT) |
| /messages/conversations | 200 | 3483 bytes de donnees |
| /integrations | 200 | OK |

### Inbox (via client)

| Element | Attendu | Resultat |
|---|---|---|
| Bouton "Aide IA" | PRO+ | Deploye (FeatureGate PRO) |
| Bouton "Assist IA" | ABSENT | Supprime |
| Bouton "Modeles" | Tous plans | Deploye (pas de gate) |
| Auto-retry IA | Actif | Code deploye (retry 2x sur limited) |

### Autopilot

| Element | Resultat |
|---|---|
| Settings endpoint | 200 OK |
| History endpoint | 200 OK |
| Engine SQL fix | Verifie dans build compile |
| Comportement identique DEV | OUI |

---

## 7. Comparaison DEV vs PROD

| Service | DEV Tag | PROD Tag | Meme code |
|---|---|---|---|
| API | `v3.5.48-ph-autopilot-engine-fix-dev` | `v3.5.48-ph-autopilot-engine-fix-prod` | OUI |
| Client | `v3.5.119-ph-ai-assist-reliability-dev` | `v3.5.119-ph-ai-assist-reliability-prod` | OUI |
| Backend | `v1.0.40-amz-tracking-visibility-backfill-dev` | `v1.0.40-amz-tracking-visibility-backfill-prod` | OUI |
| Outbound Worker | `v3.6.00-td02-worker-resilience-dev` | `v3.6.00-td02-worker-resilience-prod` | OUI |
| Website | `v0.5.1-ph3317b-prod-links` | `v0.5.1-ph3317b-prod-links` | OUI |

**Tous les services sont alignes DEV = PROD.**

---

## 8. Rollback

| Service | Env | Rollback safe | Commande |
|---|---|---|---|
| API | DEV | `v3.5.115-ph-amz-false-connected-dev` | `kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.115-ph-amz-false-connected-dev -n keybuzz-api-dev` |
| API | PROD | `v3.5.115-ph-amz-false-connected-prod` | `kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.115-ph-amz-false-connected-prod -n keybuzz-api-prod` |
| Client | DEV | `v3.5.118-ph-ai-inbox-unified-entry-dev` | `kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.118-ph-ai-inbox-unified-entry-dev -n keybuzz-client-dev` |
| Client | PROD | `v3.5.113-ph-trial-plan-fix-prod` | `kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.113-ph-trial-plan-fix-prod -n keybuzz-client-prod` |

---

## 9. Fichiers GitOps Mis a Jour

| Fichier | Changement |
|---|---|
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.115-...` → `v3.5.48-ph-autopilot-engine-fix-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.115-...` → `v3.5.48-ph-autopilot-engine-fix-prod` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.113-...` → `v3.5.119-ph-ai-assist-reliability-prod` |
| `keybuzz-infra/docs/ROLLBACK-SOURCE-OF-TRUTH-01.md` | Etat aligne DEV=PROD |

---

## Verdict Final

# PROD FULLY ALIGNED WITH DEV

Tous les services sont alignes. Meme codebase DEV et PROD. Zero regression detectee. Validation technique et produit OK.
