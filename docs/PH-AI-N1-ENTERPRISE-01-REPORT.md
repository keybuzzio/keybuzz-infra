# PH-AI-N1-ENTERPRISE-01 â€” LiteLLM Enterprise Integration

**Date**: 2026-01-15  
**Statut**: âœ… TERMINÃ‰  
**Environnement**: DEV (api-dev.keybuzz.io / client-dev.keybuzz.io)

---

## RÃ©sumÃ© ExÃ©cutif

| Objectif | Statut |
|----------|--------|
| Remplacer mock par LiteLLM | âœ… Fait |
| Tracking tokens/â‚¬ par tenant | âœ… Fait |
| Budgets quotidiens par plan | âœ… Fait |
| UI consommation IA | âœ… Fait |
| Rollback documentÃ© | âœ… Fait |

---

## 1. Versions DÃ©ployÃ©es

| Service | Version | Image |
|---------|---------|-------|
| keybuzz-api | 0.1.102 | `ghcr.io/keybuzzio/keybuzz-api:0.1.102` |
| keybuzz-client | 0.2.105 | `ghcr.io/keybuzzio/keybuzz-client:0.2.105` |

---

## 2. Architecture ImplÃ©mentÃ©e

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                      NOUVELLE ARCHITECTURE                       â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                                                                 â”‚
â”‚  keybuzz-client                                                â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”‚ POST /api/ai/assist (Next.js proxy)                    â”‚
â”‚       â–¼                                                         â”‚
â”‚  keybuzz-api                                                   â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”œâ”€â–º checkGuardrails() â†’ OK?                              â”‚
â”‚       â”‚       â”‚                                                 â”‚
â”‚       â”‚       â”œâ”€â–º global_kill_switch â†’ ai_global_settings      â”‚
â”‚       â”‚       â”œâ”€â–º tenant_kill_switch â†’ ai_settings             â”‚
â”‚       â”‚       â””â”€â–º budget check â†’ SUM(ai_usage) < plan_budget   â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”œâ”€â–º getTenantPlan() â†’ starter|pro|autopilot              â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”œâ”€â–º getModelForPlan()                                    â”‚
â”‚       â”‚       â”œâ”€â–º starter â†’ kbz-cheap (GPT-4o-mini)            â”‚
â”‚       â”‚       â”œâ”€â–º pro â†’ kbz-standard (Claude Sonnet 4)         â”‚
â”‚       â”‚       â””â”€â–º autopilot â†’ kbz-premium (GPT-4o)             â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”œâ”€â–º fetch(llm.keybuzz.io/v1/chat/completions)            â”‚
â”‚       â”‚       Headers: Authorization: Bearer <master_key>       â”‚
â”‚       â”‚                X-Tenant-Id: <tenantId>                 â”‚
â”‚       â”‚                                                         â”‚
â”‚       â””â”€â–º logUsage() â†’ INSERT ai_usage (tokens, cost, tenant)  â”‚
â”‚                                                                 â”‚
â”‚  LiteLLM (llm.keybuzz.io)                                      â”‚
â”‚       â”‚                                                         â”‚
â”‚       â”œâ”€â–º Route â†’ kbz-cheap|standard|premium                   â”‚
â”‚       â”œâ”€â–º Retry (3x) / Fallback multi-provider                 â”‚
â”‚       â””â”€â–º Provider: OpenAI | Anthropic                         â”‚
â”‚                                                                 â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 3. Fichiers CrÃ©Ã©s/ModifiÃ©s

### Backend (keybuzz-api)

| Fichier | Action | Description |
|---------|--------|-------------|
| `migrations/026_create_ai_usage.sql` | CrÃ©Ã© | Table ai_usage + colonnes plan/budget |
| `src/services/litellm.service.ts` | CrÃ©Ã© | Client LiteLLM + tracking + budgets |
| `src/modules/ai/ai-assist-routes.ts` | ModifiÃ© | Appel LiteLLM rÃ©el (remplace mock) |
| `src/modules/ai/usage-routes.ts` | CrÃ©Ã© | Endpoints admin /ai/usage |
| `src/app.ts` | ModifiÃ© | Initialisation LiteLLM + routes usage |

### Frontend (keybuzz-client)

| Fichier | Action | Description |
|---------|--------|-------------|
| `app/components/ai/AIUsageCard.tsx` | CrÃ©Ã© | Widget consommation IA |
| `app/api/admin/ai/usage/today/route.ts` | CrÃ©Ã© | Proxy API usage |
| `app/settings/page.tsx` | ModifiÃ© | IntÃ©gration AIUsageCard |

### Infrastructure

| Fichier | Action | Description |
|---------|--------|-------------|
| `k8s/keybuzz-api-dev/externalsecret-litellm.yaml` | CrÃ©Ã© | ESO pour master_key |

---

## 4. Table ai_usage

```sql
CREATE TABLE ai_usage (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL,
    user_id TEXT,
    feature TEXT NOT NULL,           -- assist | autopilot | journal
    provider TEXT NOT NULL,          -- litellm | mock | fallback
    model TEXT NOT NULL,             -- kbz-cheap | kbz-standard | kbz-premium
    prompt_tokens INTEGER NOT NULL DEFAULT 0,
    completion_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER NOT NULL DEFAULT 0,
    cost_usd_est NUMERIC(10,6) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'success',  -- success | blocked | error
    error_code TEXT,
    request_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 5. Budgets par Plan

| Plan | Budget/jour | ModÃ¨le | Fallback |
|------|-------------|--------|----------|
| Starter | $1.00 | kbz-cheap (GPT-4o-mini) | Claude Haiku |
| Pro | $10.00 | kbz-standard (Claude Sonnet 4) | GPT-4o-mini |
| Autopilot | $50.00 | kbz-premium (GPT-4o) | Claude Sonnet 4 |

### CoÃ»ts ModÃ¨les (USD / 1M tokens)

| ModÃ¨le | Input | Output |
|--------|-------|--------|
| kbz-cheap | $0.15 | $0.60 |
| kbz-standard | $3.00 | $15.00 |
| kbz-premium | $2.50 | $10.00 |

---

## 6. Endpoints API

### /ai/assist (POST)
Appel LLM avec suggestions et explications.

**Request:**
```json
{
  "tenantId": "ecomlg-001",
  "contextType": "conversation",
  "contextId": "conv-123",
  "payload": {
    "messages": [
      {"role": "customer", "content": "Ma commande est en retard"}
    ]
  }
}
```

**Response:**
```json
{
  "status": "success",
  "suggestions": [...],
  "explanations": [...],
  "confidenceLevel": "high",
  "provider": "litellm",
  "model": "kbz-standard",
  "usage": {
    "tokens": 331,
    "costUsd": 0.002589
  }
}
```

### /ai/assist/status (GET)
Statut IA et budget.

```json
{
  "available": true,
  "provider": "litellm",
  "plan": "pro",
  "model": "kbz-standard",
  "budget": {
    "dailyBudget": 10,
    "used": 0.002589,
    "remaining": 9.997411,
    "allowed": true
  }
}
```

### /admin/ai/usage/today (GET)
Consommation du jour.

```json
{
  "tenantId": "ecomlg-001",
  "date": "2026-01-14",
  "plan": "pro",
  "calls": 1,
  "tokens": 331,
  "costUsd": 0.002589,
  "budget": {
    "daily": 10,
    "used": 0.002589,
    "remaining": 9.997411,
    "percentUsed": 0.02589
  }
}
```

### /admin/ai/usage (GET)
Analytics complets (7j/30j).

```json
{
  "summary": {
    "totalCalls": 1,
    "totalTokens": 331,
    "totalCostUsd": 0.002589,
    "successCalls": 1,
    "blockedCalls": 0,
    "errorCalls": 0
  },
  "byFeature": {...},
  "byModel": {...},
  "byDay": [...]
}
```

---

## 7. Preuves E2E

### 7.1 Appel LiteLLM RÃ©el

```bash
curl -X POST https://api-dev.keybuzz.io/ai/assist \
  -H 'Content-Type: application/json' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -d '{"tenantId":"ecomlg-001","contextType":"conversation",...}'
```

**RÃ©sultat:**
- `provider`: "litellm" âœ…
- `model`: "kbz-standard" âœ…
- `tokens`: 331 âœ…
- `costUsd`: 0.002589 âœ…

### 7.2 Tracking DB

```bash
curl https://api-dev.keybuzz.io/admin/ai/usage/today?tenantId=ecomlg-001
```

**RÃ©sultat:**
- `calls`: 1 âœ…
- `tokens`: 331 âœ…
- `costUsd`: 0.002589 âœ…
- `budget.used`: 0.002589 âœ…

### 7.3 Budget Block (si dÃ©passÃ©)

Quand `SUM(cost_usd_est) >= plan_budget`:
- HTTP 402
- `status`: "budget_exceeded"
- `upgradeRequired`: true

---

## 8. Rollback Plan

### DÃ©sactiver LiteLLM (fallback mock)

1. Supprimer la variable d'environnement:
```bash
kubectl -n keybuzz-api-dev set env deploy/keybuzz-api LITELLM_MASTER_KEY-
```

2. L'API dÃ©tectera automatiquement l'absence de clÃ©:
```typescript
if (!litellmMasterKey) {
  console.warn('[App] LITELLM_MASTER_KEY not set - AI will use fallback mode');
}
```

3. Les appels /ai/assist retourneront `provider: "fallback"` avec suggestions gÃ©nÃ©riques.

### Rollback complet

```bash
# API
kubectl -n keybuzz-api-dev set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:0.1.101

# Client
kubectl -n keybuzz-client-dev set image deploy/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:0.2.104
```

---

## 9. Secrets (sans valeurs)

| Secret K8s | Namespace | Source Vault | ClÃ©s |
|------------|-----------|--------------|------|
| `keybuzz-litellm-secrets` | keybuzz-api-dev | secret/keybuzz/litellm/master_key | LITELLM_MASTER_KEY |
| `litellm-secret` | keybuzz-ai | secret/keybuzz/litellm/* | OPENAI_API_KEY, ANTHROPIC_API_KEY, etc. |

---

## 10. Checklist Prod Readiness

- [x] LiteLLM connectÃ© et fonctionnel
- [x] Tracking tokens/coÃ»t actif
- [x] Budgets par plan implÃ©mentÃ©s
- [x] Block si budget dÃ©passÃ©
- [x] UI consommation IA
- [x] Secrets via Vault/ESO
- [x] Rollback documentÃ©
- [ ] Tests de charge (N2)
- [ ] Alerting coÃ»ts (N2)
- [ ] Dashboard temps rÃ©el (N2)

---

## 11. Prochaines Ã‰tapes (N2)

| ID | TÃ¢che | PrioritÃ© |
|----|-------|----------|
| N2-01 | Cache embeddings (Qdrant) | MOYENNE |
| N2-02 | Routing intelligent (cheap vs premium) | MOYENNE |
| N2-03 | Queue Autopilot async | MOYENNE |
| N2-04 | Alerting coÃ»ts (>$X/jour) | HAUTE |
| N2-05 | Dashboard temps rÃ©el | MOYENNE |

---

**Auteur**: Agent CE  
**ValidÃ© par**: â€”  
**ImplÃ©mentation**: 2026-01-15
