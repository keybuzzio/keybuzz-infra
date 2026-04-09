# PH141-A — Agent Limits & Gating

**Date** : 3 avril 2026
**Status** : DEV + PROD OK
**Images DEV** :
- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.178-agent-limits-dev`
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.178-agent-limits-dev`

---

## Objectif

Limiter le nombre d'agents par plan avec blocage propre, message clair et upsell naturel.

---

## Avant / Apres

| Avant | Apres |
|---|---|
| Agents illimites pour tous les plans | Limite par plan : Starter=1, Pro=3, Autopilot=5, Enterprise=illimite |
| Bouton "Ajouter" toujours visible | Bouton cache quand limite atteinte |
| Pas de compteur | Compteur **"6 / 3"** ambre quand limite atteinte |
| Pas d'upsell | Banniere upsell avec CTA "Changer de plan" |
| Pas de validation backend | **403 AGENT_LIMIT_REACHED** si tentative de depassement |

---

## Limites par plan

| Plan | maxAgents |
|---|---|
| Starter / Free | 1 |
| Pro | 3 |
| Autopilot | 5 |
| Enterprise | Illimite |

Les agents inactifs ne sont PAS comptes dans la limite.

---

## Fichiers modifies

### Client (keybuzz-client)

| Fichier | Action |
|---|---|
| `src/features/billing/planCapabilities.ts` | Ajoute `maxAgents` dans l'interface + 4 plans |
| `src/features/billing/useCurrentPlan.tsx` | Ajoute hook `useAgentLimit()` |
| `src/features/billing/index.ts` | Export `useAgentLimit` |
| `app/settings/components/AgentsTab.tsx` | Compteur, bouton conditionnel, banniere upsell |

### API (keybuzz-api)

| Fichier | Action |
|---|---|
| `src/modules/agents/routes.ts` | Validation limite dans POST /agents (403 si depassement) |

---

## Backend validation

```
POST /agents
├── Count active agents: SELECT COUNT(*) FROM agents WHERE tenant_id = $1 AND is_active = true
├── Get tenant plan: SELECT plan FROM tenants WHERE id = $1
├── Compare: currentCount >= AGENT_LIMITS[plan]
├── Si limite → 403 { error: 'AGENT_LIMIT_REACHED', currentCount, limit, plan }
└── Sinon → creation normale
```

---

## Frontend UX

1. **Compteur** : badge `activeAgents / maxAgents` (ambre si limite atteinte)
2. **Bouton** : "Ajouter" cache quand `limitReached = true`
3. **Banniere upsell** : fond ambre, message "Limite d'agents atteinte (X/Y)", CTA gradient bleu "Changer de plan" → `/billing/plan`

---

## Tests DEV (verifies navigateur reel)

| Test | Resultat |
|---|---|
| Compteur "6 / 3" (ambre) visible | OK |
| Banniere upsell affichee | OK |
| "Passez au plan superieur pour ajouter plus d'agents" | OK |
| Bouton "Changer de plan" present | OK |
| Bouton "Ajouter" cache | OK |
| Accents corrects | OK |

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
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.177-sla-priority-dev -n keybuzz-client-dev
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.173-invite-login-ux-polish-dev -n keybuzz-api-dev
```

---

## PROD

**Deploye le 3 avril 2026.**

### Images PROD

- Client : `ghcr.io/keybuzzio/keybuzz-client:v3.5.178-agent-limits-prod`
  - sha256: `4cc7c13f20f3bbae02ef1ec7d25e8d2e70beb657cbec2789f1e84ab31d3c4720`
  - Build args : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
- API : `ghcr.io/keybuzzio/keybuzz-api:v3.5.178-agent-limits-prod`
  - sha256: `fee2932e0f8a904c95e353a54939d59d009c35b6615d32fcf602c23df0cf5afd`

### Verification post-deploiement

| Verification | Resultat |
|---|---|
| Client pod | `1/1 Running`, 0 restarts |
| API pod | `1/1 Running`, 0 restarts |
| Health `client.keybuzz.io` | HTTP 200, 0.54s |
| Health `api.keybuzz.io/health` | HTTP 200, 0.19s |
| Image client deployee | `v3.5.178-agent-limits-prod` |
| Image API deployee | `v3.5.178-agent-limits-prod` |
| GitOps YAML mis a jour | Oui (client-prod + api-prod) |

### Rollback PROD

```bash
# Client
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.177-sla-priority-prod -n keybuzz-client-prod
# API
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.173-invite-login-ux-polish-prod -n keybuzz-api-prod
```
