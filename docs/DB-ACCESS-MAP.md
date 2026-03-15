# KeyBuzz V3 — Carte d'Accès Base de Données

> Date : 15 mars 2026
> Phase : PH-TD-01D
> Source : PH-TD-01B (DB Access Mapping) + audit PH-TD-01D
> Architecture : Dual-DB post-split PH-TD-01C

---

## 1. Services et Leurs Bases

| Service | Namespace K8s | Database(s) | Méthode accès |
|---------|---------------|-------------|---------------|
| `keybuzz-api` | keybuzz-api-prod | keybuzz_prod | pg.Pool() |
| `keybuzz-outbound-worker` | keybuzz-api-prod | keybuzz_prod | pg.Pool() |
| `keybuzz-backend` | keybuzz-backend-prod | keybuzz_backend_prod (Prisma) + keybuzz_prod (pg.Pool/PRODUCT_DATABASE_URL) | Prisma + pg |
| `amazon-orders-worker` | keybuzz-backend-prod | keybuzz_backend_prod (Prisma) + keybuzz_prod (pg.Pool) | Prisma + pg |
| `amazon-items-worker` | keybuzz-backend-prod | keybuzz_backend_prod (Prisma) + keybuzz_prod (pg.Pool) | Prisma + pg |
| CronJob `sla-evaluator` | keybuzz-api-prod | keybuzz_prod | psql (SQL direct) |
| CronJob `sla-evaluator-escalation` | keybuzz-api-prod | keybuzz_prod | psql (SQL direct) |
| CronJob `outbound-tick-processor` | keybuzz-api-prod | keybuzz_prod (via API HTTP) | curl → API |
| CronJob `amazon-orders-sync` | keybuzz-backend-prod | keybuzz_backend_prod + keybuzz_prod (via backend HTTP) | curl → backend |
| `keybuzz-admin` | keybuzz-admin | keybuzz_prod | Via API HTTP |

---

## 2. Carte d'Accès par Table — `keybuzz_prod`

### Tables Core (haute fréquence)

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `conversations` | API, outbound-worker, SLA CronJob, AI engines | R/W | Très haute |
| `messages` | API, outbound-worker, AI engines | R/W | Très haute |
| `orders` | API, backend (PRODUCT_DB), AI engines | R/W | Haute |
| `outbound_deliveries` | API, outbound-worker | R/W | Haute |
| `tenants` | API, backend (PRODUCT_DB) | R/W | Moyenne |
| `users` | API, backend (PRODUCT_DB) | R/W | Moyenne |
| `user_tenants` | API (tenantGuard) | R/W | Très haute (chaque requête) |

### Tables Billing

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `billing_customers` | API (Stripe) | R/W | Basse |
| `billing_events` | API (Stripe webhook) | R/W | Basse |
| `billing_subscriptions` | API (entitlement, billing) | R/W | Moyenne |
| `tenant_billing_exempt` | API (entitlement) | R | Basse |

### Tables IA

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `ai_action_log` | API (ai-assist, journal) | R/W | Haute |
| `ai_actions_ledger` | API (wallet) | R/W | Moyenne |
| `ai_actions_wallet` | API (wallet) | R/W | Moyenne |
| `ai_budget_settings` | API (credits) | R/W | Basse |
| `ai_credits_wallet` | API (credits) | R/W | Basse |
| `ai_execution_audit` | API (engines PH96) | R | Basse |
| `ai_global_settings` | API (ai-assist) | R | Basse |
| `ai_journal_events` | API (journal legacy) | R/W | Basse |
| `ai_rule_actions` | API (playbooks) | R/W | Basse |
| `ai_rule_conditions` | API (playbooks) | R/W | Basse |
| `ai_rules` | API (playbooks) | R/W | Basse |
| `ai_settings` | API (ai-assist) | R | Basse |
| `ai_usage` | API (credits) | R/W | Moyenne |
| `conversation_learning_events` | API (AI learning engines) | R/W | Basse |
| `ai_human_approval_queue` | API (PH81) | R/W | Basse |
| `ai_followup_cases` | API (PH82) | R | Basse |
| `merchant_behavior_profiles` | API (PH50) | R/W | Basse |
| `tenant_ai_learning_settings` | API (learning control) | R/W | Basse |
| `tenant_ai_policies` | API (policy loader) | R | Basse |

### Tables Support / Marketplace

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `inbound_addresses` | API | R/W | Basse |
| `inbound_connections` | API | R | Basse |
| `marketplace_connections` | API (Octopia) | R/W | Basse |
| `marketplace_octopia_accounts` | API (Octopia) | R/W | Basse |
| `marketplace_sync_states` | API (Octopia) | R/W | Basse |
| `oauth_states` | API (auth) | R/W | Basse |
| `supplier_cases` | API | R/W | Basse |
| `suppliers` | API | R/W | Basse |
| `sla_policies` | API, SLA CronJob | R | Basse |
| `space_invites` | API | R/W | Basse |
| `knowledge_templates` | API | R/W | Basse |
| `amazon_returns` | Backend (Amazon worker) | R/W | Basse |
| `amazon_returns_sync_status` | Backend (Amazon worker) | R/W | Basse |

### Tables Admin

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `admin_users` | Admin panel | R/W | Très basse |
| `admin_setup_tokens` | Admin panel | R/W | Très basse |
| `admin_notifications` | Admin panel | R/W | Très basse |
| `admin_user_tenants` | Admin panel | R/W | Très basse |
| `audit_logs` | Admin panel | R/W | Très basse |
| `feature_flags` | API (feature flags) | R | Basse |

---

## 3. Carte d'Accès par Table — `keybuzz_backend_prod`

### Tables Prisma Actives (Backend uniquement)

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `Ticket` | Backend (tickets.service) | R/W | Moyenne |
| `TicketMessage` | Backend (messages.service) | R/W | Moyenne |
| `TicketEvent` | Backend (ticketEvents.service) | W | Moyenne |
| `TicketBillingUsage` | Backend (billingUsage) | R/W | Basse |
| `ExternalMessage` | Backend (amazon.service) | R/W | Haute |
| `MarketplaceConnection` | Backend (amazon.service, amazon.oauth) | R/W | Moyenne |
| `MarketplaceSyncState` | Backend (amazon.poller) | R/W | Moyenne |
| `OAuthState` | Backend (amazon.routes, amazon.oauth) | R/W | Basse |
| `MarketplaceOutboundMessage` | Backend (amazonSendReplyWorker) | R/W | Basse |
| `Job` | Backend (jobs) | R/W | Haute (DEV) |
| `Order` | Backend (Prisma model) | R/W | Haute (DEV) |
| `OrderItem` | Backend (Prisma model) | R/W | Haute (DEV) |
| `OutboundEmail` | Backend (outbound) | R/W | Basse |
| `AiRule` | Backend (aiRules.service) | R | Basse |
| `AiRuleExecution` | Backend (aiRules.service) | W | Basse |
| `AiResponseDraft` | Backend (aiRules.service) | R/W | Basse |
| `AiUsageLog` | Backend (aiUsageLogger) | R/W | Basse |
| `TenantAiBudget` | Backend (budgetController) | R | Basse |
| `TenantBillingPlan` | Backend (billingGuards) | R | Basse |
| `TenantQuotaUsage` | Backend (billingGuards) | R/W | Basse |
| `Tenant` | Backend (tenants.service, read-only) | R | Basse |
| `User` | Backend (auth.service, read-only) | R | Basse |

### Tables Prisma Inutilisées

| Table | Statut |
|-------|--------|
| `Team` | Déclaré, non utilisé |
| `TeamMembership` | Déclaré, non utilisé |
| `ApiKey` | Déclaré, non utilisé |
| `Webhook` | Déclaré, non utilisé |
| `TicketAssignment` | Déclaré, non utilisé |
| `AiRuleCondition` | Via relation AiRule uniquement |
| `AiRuleAction` | Via relation AiRule uniquement |

### Tables snake_case Backend

| Table | Service | Type | Fréquence |
|-------|---------|------|-----------|
| `amazon_backfill_locks` | Backend (backfill) | R/W | Basse |
| `amazon_backfill_schedule` | Backend (backfill) | R/W | Basse |
| `amazon_backfill_tenant_metrics` | Backend (backfill) | R/W | Basse |
| `amazon_orders_backfill_state` | Backend (backfill) | R/W | Basse |
| `inbound_addresses` | Backend (inbound.service) | R/W | Basse |
| `inbound_connections` | Backend (Prisma schema) | R | Basse |
| `amazon_returns` | Backend (Prisma schema) | R/W | Basse |
| `amazon_returns_sync_status` | Backend (Prisma schema) | R/W | Basse |
| `return_analyses` | Backend (Prisma schema) | R | Basse |
| `ai_journal_events` | Backend (Prisma schema) | R/W | Basse |
| `_prisma_migrations` | Prisma runtime | R | Au démarrage |

---

## 4. Moteurs IA → Tables (tous dans `keybuzz_prod` via API)

| Engine | Phase | Tables lues | Type |
|--------|-------|-------------|------|
| multiOrderContextEngine | PH97 | orders, messages, conversations | READ |
| sellerDNAEngine | PH96 | conversation_learning_events, ai_execution_audit | READ |
| globalLearningEngine | PH95 | conversation_learning_events, ai_execution_audit, ai_human_approval_queue, ai_followup_cases | READ |
| merchantBehaviorEngine | PH50 | conversations, amazon_returns, supplier_cases, merchant_behavior_profiles | R/W |
| buyerReputationEngine | PH91 | orders, amazon_returns, conversations | READ |
| conversationLearningEngine | PH51 | conversation_learning_events, ai_action_log, messages, conversations | R/W |
| adaptiveResponseEngine | PH52 | conversation_learning_events | READ |
| evidenceIntelligenceEngine | PH62 | message_attachments, messages | READ |
| customerRiskEngine | — | orders, amazon_returns, conversations | READ |

Tous les autres moteurs IA reçoivent le contexte en paramètre (pas d'accès DB direct).

---

## 5. CronJobs → Tables

| CronJob | Schedule | DB | Tables | Type |
|---------|----------|-----|--------|------|
| sla-evaluator | */1 min | keybuzz_prod | conversations | UPDATE sla_state |
| sla-evaluator-escalation | */1 min | keybuzz_prod | conversations, notifications | R/W |
| outbound-tick-processor | */1 min | keybuzz_prod (via API) | outbound_deliveries | R/W |
| amazon-orders-sync | */5 min | keybuzz_backend_prod + keybuzz_prod (via backend) | orders, Order | R/W |

---

## 6. Règle d'Isolation

```
┌─────────────────────────────────┐      ┌──────────────────────────┐
│       keybuzz_prod              │      │  keybuzz_backend_prod    │
│  ❌ Aucun accès depuis le       │      │  ❌ Aucun accès depuis   │
│     backend via Prisma          │      │     l'API ou les workers  │
│  ✅ Accès depuis l'API (pg)     │      │  ✅ Accès depuis le       │
│  ✅ Accès depuis le backend     │      │     backend (Prisma)      │
│     via pg.Pool() / PRODUCT_DB  │      │                          │
│  ✅ Accès depuis les CronJobs   │      │                          │
│  ✅ Accès depuis outbound-worker│      │                          │
└─────────────────────────────────┘      └──────────────────────────┘
```
