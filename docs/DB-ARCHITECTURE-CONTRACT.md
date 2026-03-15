# KeyBuzz V3 — Contrat Architecture Base de Données

> Date : 15 mars 2026
> Statut : ACTIF — Source de vérité officielle
> Phase : PH-TD-01D
> Prérequis : PH-TD-01C (Safe DB Split)

---

## 1. Principe Fondamental

Le système KeyBuzz utilise une architecture **dual-DB** :

| Base | Usage | Accédée par |
|------|-------|-------------|
| `keybuzz_prod` | API / produit / tables partagées | API, backend (pg.Pool), workers, CronJobs |
| `keybuzz_backend_prod` | Tables Prisma backend exclusives | Backend (Prisma ORM) |

**Aucun service autre que le backend ne doit accéder à `keybuzz_backend_prod`.**

---

## 2. Variables d'Environnement

### Backend PROD (`keybuzz-backend-prod`)

| Variable | Valeur | Source | Usage |
|----------|--------|--------|-------|
| `DATABASE_URL` | `postgresql://...keybuzz_backend_prod` | Secret `keybuzz-backend-db` (manuellement géré, hors ESO) | Prisma ORM |
| `PRODUCT_DATABASE_URL` | `postgresql://...keybuzz_prod` | Secret `keybuzz-backend-secrets` (ESO) | Lectures explicites tables API |
| `PGDATABASE` | `keybuzz_prod` | Secret `keybuzz-backend-db` (ESO) | pg.Pool() default |
| `PGHOST` | `10.0.0.10` | Secret `keybuzz-backend-db` (ESO) | pg.Pool() default |

### API PROD (`keybuzz-api-prod`)

| Variable | Valeur | Source | Usage |
|----------|--------|--------|-------|
| `DATABASE_URL` | `postgresql://...keybuzz_prod` | Secret `keybuzz-api-db` | Tout accès DB (pg) |

### DEV (miroir)

| Namespace | DATABASE_URL | PRODUCT_DATABASE_URL | PGDATABASE |
|-----------|-------------|---------------------|------------|
| `keybuzz-backend-dev` | `keybuzz_backend` | `keybuzz` | `keybuzz` |
| `keybuzz-api-dev` | `keybuzz` | N/A | N/A |

---

## 3. Tables — Source de Vérité Officielle

### 3.1 Tables API (`keybuzz_prod`) — NE JAMAIS DÉPLACER

| Table | Rows (15 mars) | Service principal | Type accès |
|-------|----------------|-------------------|------------|
| `conversations` | 192 | API + backend | R/W |
| `messages` | 703 | API + backend | R/W |
| `orders` | 5316 | API + backend | R/W |
| `message_attachments` | 96 | API | R/W |
| `message_events` | 465 | API | R/W |
| `outbound_deliveries` | 30 | API (outbound worker) | R/W |
| `inbound_addresses` | 1 | API | R/W |
| `inbound_connections` | 1 | API | R/W |
| `tenants` | 3 | API + backend | R/W |
| `users` | 4 | API + backend | R/W |
| `user_tenants` | 3 | API | R/W |
| `user_preferences` | 3 | API | R/W |
| `billing_customers` | 2 | API (Stripe) | R/W |
| `billing_events` | 57 | API (Stripe) | R/W |
| `billing_subscriptions` | 2 | API (Stripe) | R/W |
| `ai_action_log` | 24 | API | R/W |
| `ai_actions_ledger` | 54 | API | R/W |
| `ai_actions_wallet` | 4 | API | R/W |
| `ai_budget_settings` | 4 | API | R/W |
| `ai_credits_wallet` | 4 | API | R/W |
| `ai_execution_audit` | 7 | API | R/W |
| `ai_global_settings` | 1 | API | R/W |
| `ai_journal_events` | 19 | API | R/W |
| `ai_rule_actions` | 108 | API | R/W |
| `ai_rule_conditions` | 12 | API | R/W |
| `ai_rules` | 45 | API | R/W |
| `ai_settings` | 1 | API | R/W |
| `ai_usage` | 43 | API | R/W |
| `ai_returns_decision_trace` | 0 | API | R/W |
| `channel_rules` | 0 | API | R/W |
| `conversation_events` | 0 | API | R/W |
| `conversation_tags` | 0 | API | R/W |
| `feature_flags` | 11 | API | R |
| `knowledge_templates` | 0 | API | R/W |
| `marketplace_connections` | 0 | API (Octopia) | R/W |
| `marketplace_octopia_accounts` | 0 | API (Octopia) | R/W |
| `marketplace_sync_states` | 0 | API (Octopia) | R/W |
| `notifications` | 0 | API | R/W |
| `oauth_states` | 0 | API | R/W |
| `otp_codes` | 0 | API (auth) | R/W |
| `return_analyses` | 0 | API | R/W |
| `sla_policies` | 5 | API + CronJob SLA | R/W |
| `space_invites` | 0 | API | R/W |
| `supplier_cases` | 7 | API | R/W |
| `suppliers` | 1 | API | R/W |
| `sync_states` | 0 | API | R/W |
| `teams` | 0 | API | R/W |
| `tenant_billing_exempt` | 1 | API | R |
| `tenant_metadata` | 3 | API | R/W |
| `tenant_profile_extra` | 1 | API | R/W |
| `tenant_settings` | 0 | API | R/W |
| `agents` | 0 | API | R/W |
| `amazon_returns` | 0 | Backend (Amazon worker) | R/W |
| `amazon_returns_sync_status` | 0 | Backend (Amazon worker) | R/W |
| `amazon_backfill_locks` | 0 | Backend | R/W |
| `amazon_backfill_schedule` | 0 | Backend | R/W |
| `amazon_backfill_tenant_metrics` | 0 | Backend | R/W |
| `amazon_orders_backfill_state` | 0 | Backend | R/W |
| `message_raw_mime` | 0 | API | R/W |
| `integration_required_credentials` | 0 | API | R/W |
| `integrations` | 0 | API | R/W |
| `admin_users` | 1 | Admin | R/W |
| `admin_setup_tokens` | 2 | Admin | R/W |
| `admin_notifications` | 0 | Admin | R/W |
| `admin_user_tenants` | 0 | Admin | R/W |
| `audit_logs` | 0 | Admin | R/W |
| `ai_evaluations` | 0 | API | R/W |
| `ai_followup_cases` | 0 | API | R/W |
| `ai_human_approval_queue` | 2 | API | R/W |
| `ai_provider_usage` | 0 | API | R/W |
| `cancel_reasons` | 1 | API | R |
| `conversation_learning_events` | 0 | API | R/W |
| `incident_events` | 0 | API | R/W |
| `incident_tenants` | 0 | API | R/W |
| `incidents` | 0 | API | R/W |
| `merchant_behavior_profiles` | 1 | API | R/W |
| `playbook_suggestions` | 0 | API | R/W |
| `tenant_ai_learning_settings` | 0 | API | R/W |
| `tenant_ai_policies` | 0 | API | R/W |
| `tenant_channels` | 2 | API | R/W |
| `ai_budget_alerts` | 0 | API | R/W |
| `ai_credits_ledger` | 0 | API | R/W |

### 3.2 Tables Backend Prisma (`keybuzz_backend_prod`) — BACKEND EXCLUSIF

| Table | Rows (15 mars) | Usage |
|-------|----------------|-------|
| `AiResponseDraft` | 0 | Brouillons réponses IA |
| `AiRule` | 0 | Règles IA backend |
| `AiRuleAction` | 0 | Actions règles IA |
| `AiRuleCondition` | 0 | Conditions règles IA |
| `AiRuleExecution` | 0 | Exécutions règles IA |
| `AiUsageLog` | 0 | Log usage IA |
| `ApiKey` | 0 | Clés API |
| `ExternalMessage` | 3 | Messages externes SP-API |
| `Job` | 0 | Jobs asynchrones |
| `MarketplaceConnection` | 0 | Connexions marketplace |
| `MarketplaceOutboundMessage` | 0 | Messages sortants marketplace |
| `MarketplaceSyncState` | 0 | États sync marketplace |
| `OAuthState` | 0 | États OAuth |
| `Order` | 0 | Commandes (modèle Prisma) |
| `OrderItem` | 0 | Items commandes (Prisma) |
| `OutboundEmail` | 0 | Emails sortants |
| `Team` | 0 | Équipes |
| `TeamMembership` | 0 | Membres équipes |
| `Tenant` | 0 | Tenants (modèle Prisma) |
| `TenantAiBudget` | 0 | Budget IA tenant |
| `TenantBillingPlan` | 0 | Plan facturation |
| `TenantQuotaUsage` | 0 | Usage quotas |
| `Ticket` | 0 | Tickets support |
| `TicketAssignment` | 0 | Assignations tickets |
| `TicketBillingUsage` | 0 | Usage facturation tickets |
| `TicketEvent` | 0 | Événements tickets |
| `TicketMessage` | 0 | Messages tickets |
| `User` | 0 | Users (modèle Prisma) |
| `Webhook` | 0 | Webhooks |
| `_prisma_migrations` | 4 | Historique migrations |
| `ai_journal_events` | 0 | Événements journal IA |
| `amazon_backfill_locks` | 0 | Verrous backfill |
| `amazon_backfill_schedule` | 0 | Planification backfill |
| `amazon_backfill_tenant_metrics` | 0 | Métriques backfill |
| `amazon_orders_backfill_state` | 0 | État backfill commandes |
| `amazon_returns` | 0 | Retours Amazon |
| `amazon_returns_sync_status` | 0 | Statut sync retours |
| `inbound_addresses` | 0 | Adresses inbound |
| `inbound_connections` | 0 | Connexions inbound |
| `return_analyses` | 0 | Analyses retours |

---

## 4. Tables Legacy (Prisma fantômes dans `keybuzz_prod`)

Après PH-TD-01E, seule `ExternalMessage` reste en PascalCase dans `keybuzz_prod` :

| Table | Statut | Raison |
|-------|--------|--------|
| `ExternalMessage` | **CONSERVÉE** | 4 rows actives (delta 1 row vs backend_prod) |
| ~~`MessageAttachment`~~ | **SUPPRIMÉE** (PH-TD-01E) | 0 rows, 0 refs code, 0 refs runtime |
| ~~`Order`~~ | **SUPPRIMÉE** (PH-TD-01E) | 0 rows, 0 refs code, 0 refs runtime |
| ~~`OrderItem`~~ | **SUPPRIMÉE** (PH-TD-01E) | 0 rows, FK to Order, 0 refs code |

`keybuzz_prod` : 87 tables → **84 tables** après cleanup.

---

## 5. Tables Dupliquées (présentes dans les 2 DBs PROD)

Ces tables snake_case existent dans **les deux** bases PROD :

| Table | keybuzz_prod rows | keybuzz_backend_prod rows | DB officielle |
|-------|-------------------|--------------------------|---------------|
| `amazon_backfill_locks` | 0 | 0 | keybuzz_backend_prod |
| `amazon_backfill_schedule` | 0 | 0 | keybuzz_backend_prod |
| `amazon_backfill_tenant_metrics` | 0 | 0 | keybuzz_backend_prod |
| `amazon_orders_backfill_state` | 0 | 0 | keybuzz_backend_prod |
| `amazon_returns` | 0 | 0 | keybuzz_prod |
| `amazon_returns_sync_status` | 0 | 0 | keybuzz_prod |
| `inbound_addresses` | 1 | 0 | keybuzz_prod |
| `inbound_connections` | 1 | 0 | keybuzz_prod |
| `return_analyses` | 0 | 0 | keybuzz_prod |
| `ai_journal_events` | 19 | 0 | keybuzz_prod |

Les versions dans `keybuzz_backend_prod` sont des copies de schéma issues du Prisma initial (aucune donnée). La donnée réelle réside dans `keybuzz_prod`.

---

## 6. Mécanisme de Connexion

```
                           ┌─────────────────────────┐
                           │     keybuzz-backend      │
                           │  (Prisma + pg.Pool())    │
                           └──────┬─────────┬────────┘
                                  │         │
                     DATABASE_URL │         │ PGDATABASE + PRODUCT_DATABASE_URL
                    (Prisma ORM)  │         │ (pg.Pool() raw SQL)
                                  │         │
                    ┌─────────────▼─┐   ┌───▼─────────────┐
                    │ keybuzz_      │   │ keybuzz_prod     │
                    │ backend_prod  │   │ (API/produit)    │
                    │ 42 tables     │   │ 87 tables        │
                    │ Prisma models │   │ snake_case + 4   │
                    └───────────────┘   │ PascalCase legacy│
                                        └────────┬────────┘
                                                 │
                           ┌─────────────────────┤
                           │                     │
                    ┌──────▼──────┐    ┌─────────▼────────┐
                    │ keybuzz-api │    │ Workers/CronJobs  │
                    │ (pg)        │    │ (API image)       │
                    └─────────────┘    └──────────────────┘
```

---

## 7. Règles de Sécurité

1. **JAMAIS** modifier `keybuzz_backend_prod` depuis l'API ou les CronJobs
2. **JAMAIS** modifier `PGDATABASE` — il DOIT rester `keybuzz_prod` pour pg.Pool()
3. **JAMAIS** supprimer les tables dupliquées sans validation PH-TD-01E
4. **TOUJOURS** vérifier que `DATABASE_URL` pointe vers `keybuzz_backend_prod` pour le backend
5. **TOUJOURS** vérifier que `PRODUCT_DATABASE_URL` pointe vers `keybuzz_prod`
6. Le champ `DATABASE_URL` dans le secret `keybuzz-backend-db` est **géré manuellement** (retiré de ESO)
7. Les champs `PG*` dans le secret `keybuzz-backend-db` restent **gérés par ESO** (Vault)

---

## 8. Procédure de Rollback

En cas de problème, revenir à l'architecture mono-DB :

```bash
# 1. Remettre DATABASE_URL vers keybuzz_prod
kubectl set env deployment/keybuzz-backend -n keybuzz-backend-prod \
  DATABASE_URL=postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod

# 2. Même chose pour les workers
kubectl set env deployment/amazon-orders-worker -n keybuzz-backend-prod \
  DATABASE_URL=postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod
kubectl set env deployment/amazon-items-worker -n keybuzz-backend-prod \
  DATABASE_URL=postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod

# 3. Vérifier
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod
curl -s https://backend.keybuzz.io/health
```

---

## 9. Historique

| Date | Phase | Action |
|------|-------|--------|
| 28 fév 2026 | PH-TD-01 | Audit initial DB |
| 1 mars 2026 | PH-TD-01B | Mapping accès DB |
| 15 mars 2026 | PH-TD-01C | Split DB sécurisé |
| 15 mars 2026 | PH-TD-01D | Alignement secrets + contrat |
