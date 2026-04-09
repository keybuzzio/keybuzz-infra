# PH141-B — Agent Limits Alignment

**Date** : 3 avril 2026
**Status** : DEV + PROD OK
**Images DEV** :
- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.179-agent-limits-alignment-dev`
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.179-agent-limits-alignment-dev`

---

## Objectif

Corriger les limites agents posees en PH141-A (PRO=3, AUTOPILOT=5) vers les valeurs produit validees. Ajouter la regle Agent KeyBuzz.

---

## Cause du desalignement

PH141-A utilisait des limites inferees (PRO=3, AUTOPILOT=5) qui ne correspondaient pas aux regles produit validees par Ludovic.

---

## Limites avant / apres

### Agents internes (type `client`)

| Plan | PH141-A (incorrect) | PH141-B (correct) |
|---|---|---|
| Starter / Free | 1 | **1** (inchange) |
| **Pro** | **3** | **2** |
| **Autopilot** | **5** | **3** |
| Enterprise | Infinity | **Infinity** (inchange) |

### Agents KeyBuzz (type `keybuzz`) — NOUVEAU

| Plan | Limite |
|---|---|
| Starter / Free | 0 |
| Pro | 0 |
| **Autopilot** | **1** (si addon actif) |
| Enterprise | Illimite |

---

## Corrections apportees

### Backend (keybuzz-api)

| Fichier | Changement |
|---|---|
| `src/modules/agents/routes.ts` | `AGENT_LIMITS` : pro 3→2, autopilot 5→3 |
| `src/modules/agents/routes.ts` | Ajout `KEYBUZZ_AGENT_LIMITS` (starter=0, pro=0, autopilot=1, enterprise=999) |
| `src/modules/agents/routes.ts` | `getActiveAgentCount` filtre `type = $2` ('client') — l'agent KeyBuzz n'est plus compte dans la limite interne |
| `src/modules/agents/routes.ts` | Ajout validation KeyBuzz : si `type === 'keybuzz'`, verifie `KEYBUZZ_AGENT_LIMITS` → 403 `KEYBUZZ_AGENT_LIMIT_REACHED` |
| `src/modules/agents/routes.ts` | Fallback default : `?? 3` → `?? 2` |
| `src/modules/agents/routes.ts` | Type validation : accepte `['client', 'keybuzz']` (au lieu de `'client'` seulement) |

### Frontend (keybuzz-client)

| Fichier | Changement |
|---|---|
| `src/features/billing/planCapabilities.ts` | `maxAgents` : PRO 3→2, AUTOPILOT 5→3 |
| `app/settings/components/AgentsTab.tsx` | `activeAgents` filtre `a.type !== 'keybuzz'` — compteur n'inclut que les agents internes |

---

## Schema de donnees

La table `agents` a une colonne `type` :
- `client` = agent interne (humain)
- `keybuzz` = agent IA KeyBuzz

Etat actuel DB :
- 12 agents `client` (dont 5 actifs sur ecomlg-001)
- 1 agent `keybuzz` (support@keybuzz.io sur ecomlg-001)

---

## Tests DEV (verifies navigateur reel)

| Test | Resultat |
|---|---|
| Compteur "5 / 2" (ambre) visible | OK |
| Banniere upsell affichee | OK |
| "Passez au plan superieur pour ajouter plus d'agents" | OK |
| Bouton "Changer de plan" present | OK |
| Bouton "Ajouter" cache | OK |
| Agent KeyBuzz visible avec badge "KeyBuzz" | OK |
| Agent KeyBuzz NON compte dans la limite | OK |

### Non-regression

| Test | Resultat |
|---|---|
| Inbox (PH140-K/L/M) | OK |
| Priorite / urgence (PH140-M) | OK |
| Supervision (PH140-L) | OK |
| Agent lockdown (PH140-J) | Non touche |
| Billing | Non touche (Stripe non impacte) |

---

## Rollback DEV

```bash
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.178-agent-limits-dev -n keybuzz-client-dev
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.178-agent-limits-dev -n keybuzz-api-dev
```

---

## PROD

**Deploye le 3 avril 2026.**

### Images PROD

- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.179-agent-limits-alignment-prod`
  - sha256: `4d5f9ab413862380766885bd7e6fd359ce873086081cd40168acd0d37c1d207f`
  - Build args : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.179-agent-limits-alignment-prod`
  - sha256: `e2386f84f05881f282c5224627b75ae70fd57d68720a985804d7b5b3df09e0f3`

### Verification post-deploiement

| Verification | Resultat |
|---|---|
| Client pod | `1/1 Running`, 0 restarts |
| API pod | `1/1 Running`, 0 restarts |
| Health `client.keybuzz.io` | HTTP 200, 0.92s |
| Health `api.keybuzz.io/health` | HTTP 200, 0.20s |
| Image client | `v3.5.179-agent-limits-alignment-prod` |
| Image API | `v3.5.179-agent-limits-alignment-prod` |
| GitOps YAML | Mis a jour (client-prod + api-prod) |

### Rollback PROD

```bash
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.178-agent-limits-prod -n keybuzz-client-prod
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.178-agent-limits-prod -n keybuzz-api-prod
```
