# KeyBuzz V3 — Matrice de Duplication Tables DB

> Date : 16 mars 2026
> Phase : PH-TD-05 (ExternalMessage Unification)
> Dernière vérification : post-unification PH-TD-05 16 mars 2026

---

## 1. Vue d'Ensemble

| Base | Env | Tables | Tables avec données |
|------|-----|--------|---------------------|
| `keybuzz_prod` | PROD | **84** (3 legacy supprimées PH-TD-01E) | ~50 |
| `keybuzz_backend_prod` | PROD | **41** (ExternalMessage supprimée PH-TD-05) | 1 (_prisma_migrations) |
| `keybuzz` | DEV | 85 | ~55 |
| `keybuzz_backend` | DEV | 39 | ~15 |

---

## 2. Tables PascalCase — Prisma Fantômes dans `keybuzz_prod`

Tables créées par d'anciennes migrations Prisma qui ont laissé des traces dans la DB API.

| Table | keybuzz_prod (PROD) | keybuzz_backend_prod (PROD) | keybuzz (DEV) | keybuzz_backend (DEV) | Statut |
|-------|--------------------|-----------------------------|---------------|----------------------|--------|
| `ExternalMessage` | 5 rows | **SUPPRIMÉE** (PH-TD-05) | 41655 rows | **SUPPRIMÉE** (PH-TD-05) | **UNIFIÉE** — source unique = keybuzz_prod/keybuzz |
| ~~`MessageAttachment`~~ | — | N/A | 0 rows | N/A | **SUPPRIMÉE** PH-TD-01E (0 rows, 0 refs) |
| ~~`Order`~~ | — | 0 rows | N/A | 22891 rows | **SUPPRIMÉE** PH-TD-01E (0 rows, 0 refs) |
| ~~`OrderItem`~~ | — | 0 rows | N/A | 23290 rows | **SUPPRIMÉE** PH-TD-01E (0 rows, FK to Order) |

---

## 3. Tables snake_case Dupliquées (présentes dans PROD API + PROD Backend)

| Table | keybuzz_prod | keybuzz_backend_prod | DB Source de Vérité | Notes |
|-------|-------------|---------------------|---------------------|-------|
| `amazon_backfill_locks` | 0 | 0 | backend_prod | Backend-only (backfill) |
| `amazon_backfill_schedule` | 0 | 0 | backend_prod | Backend-only (backfill) |
| `amazon_backfill_tenant_metrics` | 0 | 0 | backend_prod | Backend-only (backfill) |
| `amazon_orders_backfill_state` | 0 | 0 | backend_prod | Backend-only (backfill) |
| `amazon_returns` | 0 | 0 | keybuzz_prod | API + Amazon workers |
| `amazon_returns_sync_status` | 0 | 0 | keybuzz_prod | Amazon workers |
| `inbound_addresses` | 1 | 0 | keybuzz_prod | API (données actives) |
| `inbound_connections` | 1 | 0 | keybuzz_prod | API (données actives) |
| `return_analyses` | 0 | 0 | keybuzz_prod | API (IA retours) |
| `ai_journal_events` | 19 | 0 | keybuzz_prod | API (journal IA) |

---

## 4. Tables Uniquement dans `keybuzz_backend_prod` (PascalCase Prisma)

Tables qui n'existent PAS dans `keybuzz_prod` (correctement isolées) :

| Table | Rows PROD | Rows DEV |
|-------|-----------|----------|
| `AiResponseDraft` | 0 | 0 |
| `AiRule` | 0 | 0 |
| `AiRuleAction` | 0 | 0 |
| `AiRuleCondition` | 0 | 0 |
| `AiRuleExecution` | 0 | 0 |
| `AiUsageLog` | 0 | 0 |
| `ApiKey` | 0 | 0 |
| `Job` | 0 | 59155 |
| `MarketplaceOutboundMessage` | 0 | 2 |
| `OutboundEmail` | 0 | 24 |
| `Team` | 0 | 0 |
| `TeamMembership` | 0 | 0 |
| `Tenant` | 0 | 15 |
| `TenantAiBudget` | 0 | 0 |
| `TenantBillingPlan` | 0 | 0 |
| `TenantQuotaUsage` | 0 | 0 |
| `Ticket` | 0 | 23 |
| `TicketAssignment` | 0 | 0 |
| `TicketBillingUsage` | 0 | 11 |
| `TicketEvent` | 0 | 21 |
| `TicketMessage` | 0 | 20 |
| `User` | 0 | 3 |
| `Webhook` | 0 | 0 |
| `MarketplaceConnection` | 0 | 10 |
| `MarketplaceSyncState` | 0 | 21 |
| `OAuthState` | 0 | 103 |

---

## 5. Tables API Uniquement dans `keybuzz_prod`

Tables qui n'existent que dans `keybuzz_prod` (correctement isolées, pas de duplication) :

Catégorie **Core** : `conversations`, `messages`, `orders`, `outbound_deliveries`, `tenants`, `users`, `user_tenants`, `user_preferences`

Catégorie **Billing** : `billing_customers`, `billing_events`, `billing_subscriptions`, `tenant_billing_exempt`

Catégorie **IA** : `ai_action_log`, `ai_actions_ledger`, `ai_actions_wallet`, `ai_budget_settings`, `ai_credits_wallet`, `ai_execution_audit`, `ai_global_settings`, `ai_rules`, `ai_rule_actions`, `ai_rule_conditions`, `ai_settings`, `ai_usage`, `ai_returns_decision_trace`, `ai_evaluations`, `ai_followup_cases`, `ai_human_approval_queue`, `ai_provider_usage`, `ai_budget_alerts`, `ai_credits_ledger`, `ai_context_attachments`

Catégorie **Marketplace** : `marketplace_connections`, `marketplace_octopia_accounts`, `marketplace_sync_states`, `oauth_states`

Catégorie **Support** : `supplier_cases`, `suppliers`, `sla_policies`, `space_invites`, `knowledge_templates`

Catégorie **Admin** : `admin_users`, `admin_setup_tokens`, `admin_notifications`, `admin_user_tenants`, `audit_logs`

Catégorie **Infra** : `feature_flags`, `cancel_reasons`, `channel_rules`, `conversation_events`, `conversation_tags`, `message_attachments`, `message_events`, `message_raw_mime`, `notifications`, `otp_codes`, `sync_states`, `teams`, `tenant_metadata`, `tenant_profile_extra`, `tenant_settings`, `agents`, `integration_required_credentials`, `integrations`, `tenant_channels`, `tenant_ai_learning_settings`, `tenant_ai_policies`, `conversation_learning_events`, `incident_events`, `incident_tenants`, `incidents`, `merchant_behavior_profiles`, `playbook_suggestions`

---

## 6. Divergences DEV / PROD

| Aspect | DEV | PROD | Impact |
|--------|-----|------|--------|
| `keybuzz_backend` ExternalMessage | 41046 rows | 3 rows | DEV a beaucoup plus de données (activité dev) |
| `keybuzz_backend` Job | 59155 rows | 0 rows | Jobs accumulés en DEV uniquement |
| `keybuzz_backend` Order/OrderItem | 22891/23290 | 0/0 | PROD utilise `orders` snake_case dans keybuzz_prod |
| `keybuzz_backend` OAuthState | 103 | 0 | États OAuth DEV accumulés |
| `keybuzz` (DEV) orders | 11591 | N/A | Plus de commandes en DEV |
| ~~`MessageAttachment` PascalCase~~ | DEV keybuzz: 0 | — | **SUPPRIMÉE** PH-TD-01E |

---

## 7. Statut Post PH-TD-05

1. **FAIT** : `MessageAttachment`, `Order`, `OrderItem` supprimées de `keybuzz_prod` (PH-TD-01E)
2. **FAIT** : `ExternalMessage` unifiée — supprimée de `keybuzz_backend_prod` et `keybuzz_backend`, source unique dans `keybuzz_prod` et `keybuzz` (PH-TD-05)
3. **À évaluer** : copies snake_case vides dans `keybuzz_backend_prod` qui ont leur source dans keybuzz_prod
4. **Conserver** : les `amazon_backfill_*` dans les deux DBs (backend les utilise via Prisma)

### Changements PH-TD-05
- Backend utilise `externalMessageStore.ts` (raw SQL via `productDb`) au lieu de `prisma.externalMessage`
- Image backend : `v1.0.39-td05-externalmsg-dev` / `v1.0.39-td05-externalmsg-prod`
- Backups : `/opt/keybuzz/backups/td05/`
