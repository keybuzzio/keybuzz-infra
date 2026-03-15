# PH-TD-01B — DB Access Mapping

> Date : 1 mars 2026
> Auteur : Agent Cursor
> Environnement : DEV + PROD (lecture seule)
> Prerequis : PH-TD-01A (28 fev 2026)

---

## 1. Inventaire Tables DEV vs PROD

### DEV — keybuzz (API DB) : 80 tables

```
MessageAttachment, admin_notifications, admin_setup_tokens, admin_user_tenants,
admin_users, agents, ai_action_log, ai_actions_ledger, ai_actions_wallet,
ai_budget_alerts, ai_budget_settings, ai_context_attachments, ai_credits_ledger,
ai_credits_wallet, ai_evaluations, ai_execution_audit, ai_followup_cases,
ai_global_settings, ai_human_approval_queue, ai_journal_events, ai_provider_usage,
ai_returns_decision_trace, ai_rule_actions, ai_rule_conditions, ai_rules,
ai_settings, ai_usage, amazon_returns, amazon_returns_sync_status, audit_logs,
billing_customers, billing_events, billing_subscriptions, cancel_reasons,
channel_rules, conversation_events, conversation_learning_events, conversation_tags,
conversations, feature_flags, inbound_addresses, inbound_connections, incident_events,
incident_tenants, incidents, integration_required_credentials, integrations,
knowledge_templates, marketplace_connections, marketplace_octopia_accounts,
merchant_behavior_profiles, message_attachments, message_events, message_raw_mime,
messages, notifications, oauth_states, orders, otp_codes, outbound_deliveries,
playbook_suggestions, return_analyses, sla_policies, space_invites, supplier_cases,
suppliers, sync_states, teams, tenant_ai_learning_settings, tenant_ai_policies,
tenant_billing_exempt, tenant_channels, tenant_metadata, tenant_profile_extra,
tenant_settings, tenants, user_preferences, user_tenants, users
```

### DEV — keybuzz_backend (Backend DB) : 42 tables

```
AiResponseDraft, AiRule, AiRuleAction, AiRuleCondition, AiRuleExecution,
AiUsageLog, ApiKey, ExternalMessage, Job, MarketplaceConnection,
MarketplaceOutboundMessage, MarketplaceSyncState, OAuthState, Order, OrderItem,
OutboundEmail, Team, TeamMembership, Tenant, TenantAiBudget, TenantBillingPlan,
TenantQuotaUsage, Ticket, TicketAssignment, TicketBillingUsage, TicketEvent,
TicketMessage, User, Webhook, _prisma_migrations,
ai_journal_events, amazon_backfill_global_metrics_v2, amazon_backfill_locks,
amazon_backfill_metrics_view, amazon_backfill_schedule, amazon_backfill_tenant_metrics,
amazon_orders_backfill_state, amazon_returns, amazon_returns_sync_status,
inbound_addresses, inbound_connections, return_analyses
```

### PROD — keybuzz_prod (PARTAGE) : 87 tables

Contient TOUTES les tables API + Backend dans une seule DB.

### Divergences DEV vs PROD

| Table | DEV API | DEV Backend | PROD |
|---|---|---|---|
| ExternalMessage | - | OK | OK |
| Order (PascalCase) | - | OK | OK |
| OrderItem | - | OK | OK |
| amazon_backfill_* (4 tables) | - | OK | OK |
| admin_* (4 tables) | OK | - | OK |
| incident_* (3 tables) | OK | - | OK |
| audit_logs | OK | - | OK |
| feature_flags | OK | - | OK |

---

## 2. Connexions DB par Service

### DECOUVERTE CRITIQUE : Architecture Dual-DB Backend

| Service | DATABASE_URL | PRODUCT_DATABASE_URL |
|---|---|---|
| **keybuzz-api DEV** | `keybuzz` (API DB) | - |
| **keybuzz-api PROD** | `keybuzz_prod` | - |
| **keybuzz-backend DEV** | `keybuzz_backend` (Prisma) | `keybuzz` (API DB!) |
| **keybuzz-backend PROD** | `keybuzz_prod` | `keybuzz_prod` |
| **amazon-orders-worker DEV** | `keybuzz_backend` | (vide) |
| **amazon-items-worker DEV** | `keybuzz_backend` | (vide) |
| **outbound-worker DEV** | `keybuzz` (PGDATABASE) | - |
| **outbound-worker PROD** | `keybuzz_prod` (PGDATABASE) | - |

**Constats :**

1. En DEV, le backend utilise DEUX DBs : `keybuzz_backend` (Prisma) + `keybuzz` (API, via `PRODUCT_DATABASE_URL`)
2. En PROD, tout pointe vers `keybuzz_prod` (pas de separation)
3. Le outbound-worker utilise la meme DB que l'API (il lit `outbound_deliveries`, `conversations`, etc.)
4. Les Amazon workers n'ont PAS de `PRODUCT_DATABASE_URL` en DEV

---

## 3. Cartographie Services → Tables (keybuzz-api)

### 3.1 Tables accedees par l'API (51 tables identifiees)

| Table | Access | Modules |
|---|---|---|
| **agents** | READ | agents, teams |
| **ai_action_log** | READ_WRITE | ai-assist-routes, conversationLearningEngine |
| **ai_actions_ledger** | READ_WRITE | ai-actions.service, billing, ai-assist-routes |
| **ai_actions_wallet** | READ_WRITE | ai-actions.service, billing, tenant-context |
| **ai_budget_alerts** | WRITE | ai-credits.service |
| **ai_budget_settings** | READ_WRITE | ai-credits.service |
| **ai_credits_ledger** | WRITE | ai-credits.service |
| **ai_credits_wallet** | READ_WRITE | ai-credits.service |
| **ai_execution_audit** | READ | sellerDNAEngine, globalLearningEngine |
| **ai_followup_cases** | READ | globalLearningEngine |
| **ai_global_settings** | READ | ai-assist-routes |
| **ai_human_approval_queue** | READ | globalLearningEngine |
| **ai_rule_actions** | READ_WRITE | playbooks, ai-assist-routes |
| **ai_rule_conditions** | READ_WRITE | playbooks, ai-assist-routes |
| **ai_rules** | READ_WRITE | playbooks, ai-assist-routes, playbook-seed |
| **ai_settings** | READ | ai-assist-routes, litellm.service |
| **ai_usage** | READ_WRITE | ai-credits.service, litellm.service |
| **amazon_returns** | READ_WRITE | returns, customerRiskEngine, buyerReputationEngine, merchantBehaviorEngine |
| **amazon_returns_sync_status** | READ_WRITE | returns |
| **billing_customers** | READ_WRITE | billing, channels |
| **billing_events** | READ_WRITE | billing |
| **billing_subscriptions** | READ_WRITE | billing, channels, entitlement.service |
| **cancel_reasons** | WRITE | billing |
| **channel_rules** | READ_WRITE | channel-rules |
| **conversation_events** | READ | sla |
| **conversation_learning_events** | READ_WRITE | adaptiveResponseEngine, conversationLearningEngine, sellerDNAEngine, globalLearningEngine |
| **conversations** | READ_WRITE | messages, inbound, orders, sla, stats, kpi, suppliers, health, octopiaImport, AI engines (12+) |
| **inbound_addresses** | READ | messages, compat |
| **inbound_connections** | READ | compat |
| **integrations** | READ | integrations |
| **knowledge_templates** | READ_WRITE | knowledge |
| **marketplace_octopia_accounts** | READ_WRITE | octopia, octopiaStatus.service, octopiaImport.service |
| **merchant_behavior_profiles** | WRITE | merchantBehaviorEngine |
| **message_attachments** | READ_WRITE | attachments, messages, inbound, evidenceIntelligenceEngine |
| **message_events** | WRITE | messages |
| **messages** | READ_WRITE | messages, inbound, suppliers, health, stats, octopiaImport, AI engines |
| **notifications** | READ_WRITE | notifications, sla |
| **orders** | READ_WRITE | orders, stats, AI engines (10+) |
| **outbound_deliveries** | READ_WRITE | messages, outbound, debugOutbound, health, suppliers |
| **playbook_suggestions** | READ | playbooks |
| **sla_policies** | READ | sla, slaPolicy.service |
| **space_invites** | READ_WRITE | space-invites-routes |
| **supplier_cases** | READ_WRITE | suppliers, AI engines |
| **suppliers** | READ_WRITE | suppliers, AI engines |
| **sync_states** | READ_WRITE | orders |
| **teams** | READ | teams |
| **tenant_ai_learning_settings** | READ_WRITE | learningControlService |
| **tenant_ai_policies** | READ | tenantPolicyLoader |
| **tenant_billing_exempt** | READ | entitlement.service, tenant-context |
| **tenant_channels** | READ_WRITE | channels |
| **tenant_metadata** | READ_WRITE | tenant-context, suppliers |
| **tenant_settings** | READ_WRITE | settings |
| **tenants** | READ_WRITE | auth, billing, channels, tenants, kpi, entitlement |
| **user_preferences** | READ_WRITE | space-invites, tenant-context |
| **user_tenants** | READ_WRITE | auth, billing, kpi, tenantGuard |
| **users** | READ_WRITE | auth, billing, space-invites, tenantGuard |

### 3.2 Tables NON accedees par l'API (dans la DB mais pas dans le code)

| Table | Probable usage |
|---|---|
| MessageAttachment | Legacy Prisma, remplace par `message_attachments` |
| admin_notifications | Admin panel (keybuzz-admin) |
| admin_setup_tokens | Admin panel |
| admin_user_tenants | Admin panel |
| admin_users | Admin panel |
| ai_context_attachments | Upload contexte IA (probablement hors scan) |
| ai_evaluations | Evaluations IA (probablement hors scan) |
| ai_journal_events | Journal IA legacy |
| ai_provider_usage | Usage providers IA |
| ai_returns_decision_trace | Trace decisions retours |
| audit_logs | Audit logging |
| conversation_tags | Tags conversations (UI feature) |
| feature_flags | Feature flags system |
| incident_events | Incident management |
| incident_tenants | Incident management |
| incidents | Incident management |
| integration_required_credentials | Setup integrations |
| marketplace_connections | Connexions marketplace (snake_case, distinct de PascalCase) |
| marketplace_sync_states | Etats sync marketplace |
| message_raw_mime | MIME brut emails |
| oauth_states | OAuth state management |
| otp_codes | OTP auth codes |
| return_analyses | Cache analyses retours IA |
| tenant_profile_extra | Profil etendu tenant |

**Note** : certaines de ces tables sont accedees par du code non scanne (admin panel, anciens modules, ou par des endpoints non encore audites).

---

## 4. Cartographie Services → Tables (keybuzz-backend)

### 4.1 Modeles Prisma actifs (26 modeles declares, 19 utilises)

| Modele Prisma | Table DB | Access | Fichiers |
|---|---|---|---|
| **Tenant** | Tenant | READ | tenants.service.ts |
| **User** | User | READ | auth.service.ts |
| **Ticket** | Ticket | READ_WRITE | tickets.service.ts, amazon.service.ts, workers |
| **TicketMessage** | TicketMessage | READ_WRITE | messages.service.ts, aiRules.service.ts, amazon.service.ts |
| **TicketEvent** | TicketEvent | WRITE | ticketEvents.service.ts, messages.service.ts, workers |
| **TicketBillingUsage** | TicketBillingUsage | READ_WRITE | messages.service.ts, billingUsage.service.ts |
| **AiRule** | AiRule | READ | aiRules.service.ts |
| **AiRuleExecution** | AiRuleExecution | WRITE | aiRules.service.ts |
| **AiResponseDraft** | AiResponseDraft | READ_WRITE | aiRules.service.ts |
| **AiUsageLog** | AiUsageLog | READ_WRITE | aiUsageLogger.service.ts, budgetController.service.ts |
| **TenantAiBudget** | TenantAiBudget | READ | budgetController.service.ts, aiEngine.service.ts |
| **TenantBillingPlan** | TenantBillingPlan | READ | billingGuards.service.ts, aiExecutionPolicy.service.ts |
| **TenantQuotaUsage** | TenantQuotaUsage | READ_WRITE | billingGuards.service.ts, billingUsage.service.ts |
| **MarketplaceConnection** | MarketplaceConnection | READ_WRITE | amazon.service.ts, amazon.oauth.ts, amazon.poller.ts |
| **MarketplaceSyncState** | MarketplaceSyncState | READ_WRITE | amazon.oauth.ts, amazon.poller.ts |
| **ExternalMessage** | ExternalMessage | READ_WRITE | amazon.service.ts |
| **InboundAddress** | inbound_addresses | READ_WRITE | inbound.service.ts |
| **MarketplaceOutboundMessage** | MarketplaceOutboundMessage | READ_WRITE | amazonSendReplyWorker.ts |
| **OAuthState** | OAuthState | READ_WRITE | amazon.routes.ts, amazon.oauth.ts (raw SQL) |

### 4.2 Modeles Prisma NON utilises

| Modele | Statut |
|---|---|
| Team | Declare, non utilise |
| TeamMembership | Declare, non utilise |
| ApiKey | Declare, non utilise |
| Webhook | Declare, non utilise |
| TicketAssignment | Declare, non utilise |
| AiRuleCondition | Via relation AiRule uniquement |
| AiRuleAction | Via relation AiRule uniquement |

### 4.3 Acces raw SQL dans le backend

| Fichier | Table | Operation |
|---|---|---|
| amazon.routes.ts | OAuthState | SELECT, UPDATE |
| amazon.oauth.ts | OAuthState | INSERT |
| lib/db.ts | (health) | SELECT 1 |

---

## 5. Cartographie Moteurs IA → Tables

| Engine | PH | Tables | Access |
|---|---|---|---|
| abusePatternEngine | PH63 | conversations, orders | READ |
| adaptiveResponseEngine | PH52 | conversation_learning_events | READ |
| buyerReputationEngine | PH91 | orders, amazon_returns, conversations | READ |
| conversationLearningEngine | PH51 | conversation_learning_events, ai_action_log, messages, conversations | READ_WRITE |
| costAwarenessEngine | PH90 | conversations, orders, supplier_cases, suppliers | READ |
| customerPatienceEngine | PH93 | messages, conversations, orders | READ |
| customerRiskEngine | - | orders, amazon_returns, conversations | READ |
| evidenceIntelligenceEngine | PH62 | message_attachments, messages | READ |
| globalLearningEngine | PH95 | conversation_learning_events, ai_execution_audit, ai_human_approval_queue, ai_followup_cases, conversations | READ |
| learningControlService | - | tenant_ai_learning_settings | READ_WRITE |
| marketplacePolicyEngine | PH92 | conversations | READ |
| merchantBehaviorEngine | PH50 | conversations, amazon_returns, supplier_cases, merchant_behavior_profiles | READ_WRITE |
| multiOrderContextEngine | PH97 | orders, messages, conversations | READ |
| productValueAwareness | - | orders, conversations | READ |
| sellerDNAEngine | PH96 | conversation_learning_events, ai_execution_audit | READ |
| tenantPolicyLoader | PH41 | tenant_ai_policies | READ |

### Moteurs IA sans acces DB direct (contexte passe en parametre)

contextCompressionEngine (PH59), responseStrategyEngine (PH46), decisionCalibrationEngine (PH60), marketplaceIntelligenceEngine (PH61), refundProtectionLayer (PH49), conversationMemoryEngine (PH58), historicalResolutionEngine (PH43), resolutionCostOptimizer (PH94), fraudPatternEngine (PH55), deliveryIntelligenceEngine (PH56), supplierWarrantyEngine (PH57), decisionTreeEngine (PH45), customerToneEngine (PH53), customerIntentEngine (PH54), customerEmotionEngine (PH68), promptStabilityEngine (PH69), workflowOrchestrationEngine (PH70), caseAutopilotEngine (PH71), actionExecutionEngine (PH72), carrierIntegrationEngine (PH73), returnManagementEngine (PH74), supplierCaseAutomationEngine (PH75), autopilotExecutionEngine (PH76), executionAuditTrailEngine (PH77), aiPerformanceMetricsEngine (PH78), aiHealthMonitoringEngine (PH79), safetySimulationEngine (PH80), humanApprovalQueueEngine (PH81), followupEngine (PH82), aiControlCenterEngine (PH83), followupSchedulerEngine (PH84), opsActionCenterEngine (PH85), escalationIntelligenceEngine (PH65), selfProtectionEngine (PH66), knowledgeRetrievalEngine (PH67), resolutionPredictionEngine (PH64), savPolicyEngine (PH41)

---

## 6. Tables Partagees CRITIQUES (Cross-Service)

Ces tables sont accedees par PLUSIEURS services et ne doivent PAS etre separees lors du split DB.

### 6.1 Tables lues/ecrites par l'API ET presentes dans la DB Backend

| Table | API | Backend | Raison du partage |
|---|---|---|---|
| **amazon_returns** | READ_WRITE (returns module, AI engines) | READ (dans DB backend) | Sync Amazon retours |
| **amazon_returns_sync_status** | READ_WRITE (returns module) | Present dans DB backend | Etat sync retours |
| **inbound_addresses** | READ (messages, compat) | READ_WRITE (inbound.service.ts) | Adresses email entrant |
| **inbound_connections** | READ (compat) | Present dans DB backend | Connexions entrant |
| **return_analyses** | Present dans DB API | Present dans DB backend | Cache analyses retours |

### 6.2 Tables accedees par l'API ET le Outbound Worker

Le outbound-worker est un deployment separe mais utilise la MEME DB que l'API :

| Table | API | Outbound Worker |
|---|---|---|
| outbound_deliveries | READ_WRITE | READ_WRITE (tick processing) |
| conversations | READ_WRITE | READ (pour envoi) |
| messages | READ_WRITE | READ (pour contenu) |
| message_attachments | READ_WRITE | READ (pour pieces jointes) |
| inbound_addresses | READ | READ (pour from address) |

### 6.3 Tables accedees par l'API ET les CronJobs SLA

| Table | Usage |
|---|---|
| conversations | UPDATE sla_state par sla-evaluator CronJob |
| notifications | INSERT escalation par sla-evaluator-escalation |

### 6.4 Backend PRODUCT_DATABASE_URL → API DB

**DECOUVERTE CRITIQUE** : En DEV, le backend a `PRODUCT_DATABASE_URL=keybuzz` (la DB API). Cela signifie que le backend lit des donnees depuis la DB API. Les tables exactes accedees via cette connexion n'ont pas pu etre determinees par scan statique (necessite inspection du code backend utilisant cette variable).

---

## 7. Tables Backend EXCLUSIVES

Tables utilisees UNIQUEMENT par le backend (Prisma PascalCase) :

| Table | Modele Prisma | Usage |
|---|---|---|
| **AiResponseDraft** | AiResponseDraft | Brouillons reponses IA |
| **AiRule** | AiRule | Regles IA backend |
| **AiRuleAction** | AiRuleAction | Actions regles IA |
| **AiRuleCondition** | AiRuleCondition | Conditions regles IA |
| **AiRuleExecution** | AiRuleExecution | Executions regles IA |
| **AiUsageLog** | AiUsageLog | Logs usage IA |
| **ApiKey** | ApiKey | Cles API (non utilise) |
| **ExternalMessage** | ExternalMessage | Messages externes Amazon |
| **Job** | Job | Jobs internes |
| **MarketplaceConnection** | MarketplaceConnection | Connexions marketplace (PascalCase) |
| **MarketplaceOutboundMessage** | MarketplaceOutboundMessage | Messages sortants marketplace |
| **MarketplaceSyncState** | MarketplaceSyncState | Etats sync marketplace (PascalCase) |
| **OAuthState** | OAuthState | Etats OAuth Amazon |
| **Order** | Order | Commandes (PascalCase, **VIDE en PROD**) |
| **OrderItem** | OrderItem | Items commandes (**VIDE en PROD**) |
| **OutboundEmail** | OutboundEmail | Emails sortants |
| **Team** | Team | Equipes (non utilise) |
| **TeamMembership** | TeamMembership | Membres equipes (non utilise) |
| **Tenant** | Tenant | Tenants (PascalCase, READ only) |
| **TenantAiBudget** | TenantAiBudget | Budget IA tenant |
| **TenantBillingPlan** | TenantBillingPlan | Plan facturation |
| **TenantQuotaUsage** | TenantQuotaUsage | Usage quotas |
| **Ticket** | Ticket | Tickets (= conversations backend) |
| **TicketAssignment** | TicketAssignment | Assignation tickets (non utilise) |
| **TicketBillingUsage** | TicketBillingUsage | Facturation tickets |
| **TicketEvent** | TicketEvent | Evenements tickets |
| **TicketMessage** | TicketMessage | Messages tickets |
| **User** | User | Utilisateurs (PascalCase, READ only) |
| **Webhook** | Webhook | Webhooks (non utilise) |
| **_prisma_migrations** | - | Historique migrations Prisma |
| **amazon_backfill_**** | - | Backfill Amazon (4 tables) |

**Note** : `Order` et `OrderItem` (PascalCase) sont VIDES en PROD. Les commandes reelles sont dans `orders` (snake_case, API).

---

## 8. Tables API EXCLUSIVES

Tables utilisees UNIQUEMENT par l'API (snake_case) :

| Table | Access | Modules |
|---|---|---|
| **agents** | READ | agents, teams |
| **ai_action_log** | READ_WRITE | IA pipeline |
| **ai_actions_ledger** | READ_WRITE | billing, AI debit |
| **ai_actions_wallet** | READ_WRITE | billing, AI wallet |
| **ai_budget_alerts** | WRITE | credits service |
| **ai_budget_settings** | READ_WRITE | credits service |
| **ai_credits_ledger** | WRITE | credits service |
| **ai_credits_wallet** | READ_WRITE | credits service |
| **ai_execution_audit** | READ | AI engines |
| **ai_followup_cases** | READ | globalLearningEngine |
| **ai_global_settings** | READ | AI pipeline |
| **ai_human_approval_queue** | READ | globalLearningEngine |
| **ai_rule_actions** | READ_WRITE | playbooks |
| **ai_rule_conditions** | READ_WRITE | playbooks |
| **ai_rules** | READ_WRITE | playbooks |
| **ai_settings** | READ | AI pipeline |
| **ai_usage** | READ_WRITE | credits, litellm |
| **billing_customers** | READ_WRITE | billing |
| **billing_events** | READ_WRITE | billing (Stripe webhook) |
| **billing_subscriptions** | READ_WRITE | billing, channels, entitlement |
| **cancel_reasons** | WRITE | billing |
| **channel_rules** | READ_WRITE | channel-rules |
| **conversation_events** | READ | sla |
| **conversation_learning_events** | READ_WRITE | AI engines |
| **conversations** | READ_WRITE | messages, inbound, orders, sla, stats, kpi, suppliers, octopia, AI |
| **knowledge_templates** | READ_WRITE | knowledge |
| **marketplace_octopia_accounts** | READ_WRITE | octopia |
| **merchant_behavior_profiles** | WRITE | merchantBehaviorEngine |
| **message_attachments** | READ_WRITE | attachments, messages, inbound, AI |
| **message_events** | WRITE | messages |
| **messages** | READ_WRITE | messages, inbound, suppliers, stats, octopia, AI |
| **notifications** | READ_WRITE | notifications, sla |
| **orders** | READ_WRITE | orders, stats, AI engines |
| **outbound_deliveries** | READ_WRITE | messages, outbound, debugOutbound, health |
| **playbook_suggestions** | READ | playbooks |
| **sla_policies** | READ | sla |
| **space_invites** | READ_WRITE | auth |
| **supplier_cases** | READ_WRITE | suppliers, AI engines |
| **suppliers** | READ_WRITE | suppliers, AI engines |
| **sync_states** | READ_WRITE | orders |
| **teams** | READ | teams |
| **tenant_ai_learning_settings** | READ_WRITE | learningControl |
| **tenant_ai_policies** | READ | tenantPolicyLoader |
| **tenant_billing_exempt** | READ | entitlement |
| **tenant_channels** | READ_WRITE | channels |
| **tenant_metadata** | READ_WRITE | auth, suppliers |
| **tenant_settings** | READ_WRITE | settings |
| **tenants** | READ_WRITE | auth, billing, channels, tenants |
| **user_preferences** | READ_WRITE | auth |
| **user_tenants** | READ_WRITE | auth, billing, kpi, tenantGuard |
| **users** | READ_WRITE | auth, billing |

---

## 9. Analyse Prisma Schema

### 9.1 Modeles Prisma declares (23 modeles)

Tenant, User, Team, TeamMembership, ApiKey, Webhook, Ticket, TicketMessage, TicketEvent, TicketAssignment, AiRule, AiRuleCondition, AiRuleAction, AiRuleExecution, AiResponseDraft, TenantBillingPlan, TenantQuotaUsage, TicketBillingUsage, AiUsageLog, TenantAiBudget, MarketplaceConnection, MarketplaceSyncState, ExternalMessage

### 9.2 Modeles utilises dans le code mais absents du schema

| Modele | Usage |
|---|---|
| InboundAddress | inbound.service.ts |
| MarketplaceOutboundMessage | amazonSendReplyWorker.ts |

### 9.3 Tables creees par Prisma mais non utilisees

| Table | Statut |
|---|---|
| Order | VIDE en PROD — `orders` (snake_case API) est la source de verite |
| OrderItem | VIDE en PROD — non utilise |
| Team (PascalCase) | Declare mais non utilise |
| TeamMembership | Declare mais non utilise |
| ApiKey | Declare mais non utilise |
| Webhook | Declare mais non utilise |
| TicketAssignment | Declare mais non utilise |

### 9.4 Tables NON gerees par Prisma (creees manuellement)

Toutes les tables snake_case de l'API sont creees manuellement (pas de migration Prisma). Cela inclut les 51+ tables listees dans la section 8.

Les tables suivantes dans la DB backend sont aussi hors Prisma :
- `ai_journal_events`
- `amazon_backfill_*` (4 tables)
- `amazon_returns`, `amazon_returns_sync_status`
- `inbound_addresses`, `inbound_connections`
- `return_analyses`

---

## 10. Acces Raw SQL dans le backend

| Fichier | Type | Table | Operation |
|---|---|---|---|
| amazon.routes.ts | $queryRaw | OAuthState | SELECT |
| amazon.routes.ts | $executeRaw | OAuthState | UPDATE |
| amazon.oauth.ts | $executeRaw | OAuthState | INSERT |
| lib/db.ts | $queryRaw | (aucune) | SELECT 1 (health) |

---

## 11. Matrice Finale

### Legende

- **R** = READ
- **W** = WRITE
- **RW** = READ_WRITE
- **-** = non accede
- **P** = Prisma (PascalCase)

### Tables API (snake_case)

| Table | API | Backend | Workers | IA Engines |
|---|---|---|---|---|
| agents | R | - | - | - |
| ai_action_log | RW | - | - | R |
| ai_actions_ledger | RW | - | - | - |
| ai_actions_wallet | RW | - | - | - |
| ai_budget_alerts | W | - | - | - |
| ai_budget_settings | RW | - | - | - |
| ai_credits_ledger | W | - | - | - |
| ai_credits_wallet | RW | - | - | - |
| ai_execution_audit | R | - | - | R |
| ai_followup_cases | R | - | - | R |
| ai_global_settings | R | - | - | - |
| ai_human_approval_queue | R | - | - | R |
| ai_rule_actions | RW | - | - | - |
| ai_rule_conditions | RW | - | - | - |
| ai_rules | RW | - | - | - |
| ai_settings | R | - | - | - |
| ai_usage | RW | - | - | - |
| amazon_returns | RW | R* | - | R |
| amazon_returns_sync_status | RW | R* | - | - |
| billing_customers | RW | - | - | - |
| billing_events | RW | - | - | - |
| billing_subscriptions | RW | - | - | - |
| cancel_reasons | W | - | - | - |
| channel_rules | RW | - | - | - |
| conversation_events | R | - | - | - |
| conversation_learning_events | RW | - | - | RW |
| conversations | RW | - | RW** | RW |
| inbound_addresses | R | RW* | - | - |
| inbound_connections | R | R* | - | - |
| integrations | R | - | - | - |
| knowledge_templates | RW | - | - | - |
| marketplace_octopia_accounts | RW | - | - | - |
| merchant_behavior_profiles | W | - | - | W |
| message_attachments | RW | - | R** | R |
| message_events | W | - | - | - |
| messages | RW | - | R** | R |
| notifications | RW | - | - | - |
| orders | RW | - | - | R |
| outbound_deliveries | RW | - | RW** | - |
| playbook_suggestions | R | - | - | - |
| return_analyses | R | R* | - | - |
| sla_policies | R | - | - | - |
| space_invites | RW | - | - | - |
| supplier_cases | RW | - | - | R |
| suppliers | RW | - | - | R |
| sync_states | RW | - | - | - |
| teams | R | - | - | - |
| tenant_ai_learning_settings | RW | - | - | - |
| tenant_ai_policies | R | - | - | R |
| tenant_billing_exempt | R | - | - | - |
| tenant_channels | RW | - | - | - |
| tenant_metadata | RW | - | - | - |
| tenant_settings | RW | - | - | - |
| tenants | RW | R(P) | - | - |
| user_preferences | RW | - | - | - |
| user_tenants | RW | - | - | - |
| users | RW | R(P) | - | - |

`*` = acces via DB backend DEV (tables dupliquees entre les deux DBs)
`**` = outbound-worker (meme DB que API)
`(P)` = acces via Prisma model (PascalCase Tenant/User)

### Tables Backend (PascalCase Prisma)

| Table | API | Backend | Workers |
|---|---|---|---|
| AiResponseDraft | - | RW | - |
| AiRule | - | R | - |
| AiRuleExecution | - | W | - |
| AiUsageLog | - | RW | - |
| ExternalMessage | - | RW | - |
| MarketplaceConnection | - | RW | - |
| MarketplaceOutboundMessage | - | - | RW |
| MarketplaceSyncState | - | RW | - |
| OAuthState | - | RW | - |
| Order (VIDE) | - | - | - |
| OrderItem (VIDE) | - | - | - |
| Tenant (PascalCase) | - | R | - |
| TenantAiBudget | - | R | - |
| TenantBillingPlan | - | R | - |
| TenantQuotaUsage | - | RW | - |
| Ticket | - | RW | R |
| TicketBillingUsage | - | RW | - |
| TicketEvent | - | W | W |
| TicketMessage | - | RW | - |
| User (PascalCase) | - | R | - |

---

## 12. Recommandations pour PH-TD-01C (Safe DB Split)

### 12.1 NE PAS SEPARER (shared critical)

Ces tables doivent rester dans une seule DB accessible par tous les services :

| Table | Raison |
|---|---|
| conversations | API RW + outbound-worker RW + SLA CronJob |
| messages | API RW + outbound-worker R |
| orders | API RW + AI engines R |
| outbound_deliveries | API RW + outbound-worker RW |
| amazon_returns | API RW + backend R |
| inbound_addresses | API R + backend RW |
| users | API RW + backend R (Prisma) |
| tenants | API RW + backend R (Prisma) |

### 12.2 SEPARABLES (backend exclusif)

Tables PascalCase Prisma qui peuvent aller dans une DB backend separee :

AiResponseDraft, AiRuleExecution, AiUsageLog, ExternalMessage, MarketplaceConnection, MarketplaceOutboundMessage, MarketplaceSyncState, OAuthState, Ticket, TicketBillingUsage, TicketEvent, TicketMessage, TenantAiBudget, TenantBillingPlan, TenantQuotaUsage, Order (vide), OrderItem (vide)

### 12.3 NETTOYABLES (tables vides ou non utilisees)

| Table | Raison |
|---|---|
| Order (PascalCase) | VIDE en PROD, `orders` (API) est la source de verite |
| OrderItem (PascalCase) | VIDE en PROD |
| Team, TeamMembership (PascalCase) | Non utilises dans le code backend |
| ApiKey, Webhook (PascalCase) | Non utilises |
| TicketAssignment (PascalCase) | Non utilise |

### 12.4 Architecture recommandee pour PH-TD-01C

```
keybuzz_api_dev / keybuzz_api_prod
  └── 51+ tables snake_case (conversations, orders, messages, ai_*, billing_*, etc.)
  └── Tables partagees (amazon_returns, inbound_addresses, etc.)
  └── Tables users/tenants (source de verite auth)

keybuzz_backend_dev / keybuzz_backend_prod
  └── Tables PascalCase Prisma (Ticket, TicketMessage, MarketplaceConnection, etc.)
  └── Tables backfill (amazon_backfill_*)
  └── PRODUCT_DATABASE_URL → keybuzz_api_* (lecture cross-DB)
```

### 12.5 Risques identifies

1. **PRODUCT_DATABASE_URL** : Le backend accede a la DB API via cette variable. Toute separation doit maintenir cette connexion cross-DB.
2. **Outbound Worker** : Utilise la MEME DB que l'API. Ne peut pas etre separe.
3. **SLA CronJobs** : Executent du SQL directement sur les tables API (conversations, notifications). Ne peuvent pas etre separes.
4. **Tables dupliquees DEV** : `amazon_returns`, `inbound_addresses`, etc. existent dans les DEUX DBs DEV. Source de verite ambigue.
5. **Prisma models non-alignes** : Le backend a des modeles (`User`, `Tenant`) qui lisent depuis la meme DB en PROD mais pas en DEV.

---

## 13. Scripts utilises

| Script | Usage |
|---|---|
| `scripts/td01b-table-inventory.sh` | Inventaire tables DEV vs PROD |
| `scripts/td01b-scan-bastion-api.sh` | Scan complet modules API (bastion) |
| `scripts/td01b-check-backend-env.sh` | Verification env vars tous services |

---

## 14. Prochaines Etapes

| Phase | Description | Statut |
|---|---|---|
| **PH-TD-01A** | PROD DB Functional Gap Closure | TERMINE |
| **PH-TD-01B** | DB Access Mapping | **TERMINE** |
| PH-TD-01C | Safe DB Split | En attente validation |
