# PH137-C-IA-CONSISTENCY-ENGINE-01 — Rapport

> Date : 1 mars 2026
> Auteur : Agent Cursor (CE)
> Version DEV : `v3.5.149-ai-consistency-dev`
> Version PROD : `v3.5.149-ai-consistency-prod`
> Environnement : DEV + PROD deploye

---

## 1. Objectif

Unifier la logique IA entre Autopilot (AUTOPILOT) et Aide IA (PRO) pour que les deux moteurs utilisent les memes donnees, le meme prompt et la meme qualite de reponse.

---

## 2. Problemes identifies (Audit)

| Aspect | Autopilot (engine.ts) | AI Assist (ai-assist-routes.ts) |
|---|---|---|
| System prompt | 7 cas scenarios detailles | Regles generiques |
| Tracking reel | `carrier_delivery_status`, `deliveredAt`, `trackingSource`, `lastCarrierCheckAt` | Absent |
| Contexte temporel | `daysSinceOrder`, `deliveryDelayDays`, `isPotentiallyLate`, `hasLiveTracking` | Absent |
| Customer name | Injecte dans le prompt user | Absent du prompt |
| Temperature LLM | 0.3 (precis) | 0.7 (trop creatif) |
| Historique multi-turn | 5 derniers messages structures (CLIENT/AGENT) | Messages sans structure |

---

## 3. Solution implementee

### 3.1 Module partage : `shared-ai-context.ts` (NOUVEAU)

Fichier : `src/modules/ai/shared-ai-context.ts`

Contient les fonctions partagees entre Autopilot et AI Assist :

| Fonction | Role |
|---|---|
| `loadEnrichedOrderContext(pool, orderRef, tenantId)` | Charge toutes les colonnes commande (tracking live, delivered_at, shipped_at, carrier_normalized, tracking_source) |
| `computeTemporalContext(orderContext)` | Calcule jours depuis commande, retard, tracking live |
| `loadFullConversationContext(pool, convId, tenantId)` | Charge conversation + customer_name + 5 derniers messages |
| `getScenarioRules()` | Retourne les 7 cas scenarios (identiques a engine.ts) |
| `getWritingRules()` | Retourne les regles de redaction + interdictions |
| `buildEnrichedUserPrompt(params)` | Construit le prompt user enrichi (commande + livraison + temporel + historique + nom client) |

Types exportes : `EnrichedOrderContext`, `TemporalContext`, `ConversationContextShared`

### 3.2 Patch AI Assist (`ai-assist-routes.ts`)

7 patches appliques :

| # | Patch | Description |
|---|---|---|
| 1 | Import shared module | Import des fonctions et types depuis `shared-ai-context.ts` |
| 2 | Scenario rules | Injection de `getScenarioRules()` + `getWritingRules()` dans le system prompt |
| 3 | Tracking enrichi | Injection de `carrierDeliveryStatus`, `deliveredAt`, `shippedAt`, `trackingSource` + analyse temporelle |
| 4 | Temperature | 0.7 → 0.3 |
| 5 | Enriched context loading | Appel `loadEnrichedOrderContext()` + `computeTemporalContext()` + `loadFullConversationContext()` |
| 6 | System prompt call | Passage des donnees enrichies a `buildSystemPrompt()` |
| 7 | Customer name + temporal | Injection du nom client et de l'analyse temporelle dans le user prompt |

### 3.3 Differenciation des modes

| Mode | Plan | Comportement |
|---|---|---|
| **AI Assist** | PRO+ | Suggestion uniquement (draft pour validation humaine) |
| **Autopilot** | AUTOPILOT+ | Suggestion + execution automatique (safe_mode = draft) |

La logique IA (prompt, contexte, donnees) est maintenant IDENTIQUE. Seule la couche d'execution differe.

---

## 4. Fichiers modifies

| Fichier | Action |
|---|---|
| `src/modules/ai/shared-ai-context.ts` | **NOUVEAU** — module partage |
| `src/modules/ai/ai-assist-routes.ts` | 7 patches (import, prompt, tracking, temp, context, customer_name) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image `v3.5.149-ai-consistency-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | Image `v3.5.149-ai-consistency-prod` |
| `keybuzz-infra/k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` | Image `v3.5.149-ai-consistency-prod` |

---

## 5. Non-regressions

### DEV

| Endpoint | Status |
|---|---|
| API /health | 200 |
| Client /login | 200 |
| Client /inbox | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

### PROD

| Endpoint | Status |
|---|---|
| API /health | 200 |
| Client /login | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

---

## 6. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.147-autopilot-smart-response-dev -n keybuzz-api-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.147-autopilot-smart-response-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.147-autopilot-smart-response-prod -n keybuzz-api-prod
```

Source sauvegardee : `ai-assist-routes.ts.bak-pre-ph137c`

---

## 7. Verdict

**AI CONSISTENCY ACHIEVED — SAME LOGIC — SAME DATA — DIFFERENT MODE ONLY**

- Module partage cree et operationnel
- AI Assist utilise maintenant les memes scenarios, tracking, temporel et customer_name que Autopilot
- Temperature alignee (0.3)
- Image DEV : `v3.5.149-ai-consistency-dev` — Pod 1/1 Running
- Image PROD : `v3.5.149-ai-consistency-prod` — API + Worker 1/1 Running
- Non-regressions DEV + PROD : OK (tous endpoints 200)
- GitOps : 3 deployment.yaml mis a jour (API DEV, API PROD, Worker PROD)
- PROD deploye le 1 mars 2026 apres validation Ludovic
