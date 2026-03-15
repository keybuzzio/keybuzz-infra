# PH-TD-01 — Audit Complet des Bases de Donnees PostgreSQL

> Date : 15 mars 2026
> Cluster : Patroni `keybuzz-pg17` (PostgreSQL 17)
> Endpoint HAProxy : `10.0.0.10:5432`
> Leader : `db-postgres-01` (10.0.0.120)

---

## 1. Inventaire des Databases

| Database | Usage | Schema dominant | Taille estimee |
|---|---|---|---|
| `keybuzz` | DEV — keybuzz-api | snake_case (SQL brut, pg Pool) | 80 tables |
| `keybuzz_backend` | DEV — keybuzz-backend | PascalCase (Prisma ORM) | 42 tables |
| `keybuzz_prod` | PROD — keybuzz-api + keybuzz-backend (PARTAGE) | MIXTE snake_case + PascalCase | 80 tables |
| `keybuzz_litellm` | LiteLLM AI proxy | hors perimetre | - |
| `postgres` | systeme | hors perimetre | - |

---

## 2. Utilisateurs PostgreSQL

| User | Usage | Databases |
|---|---|---|
| `keybuzz_api_dev` | API DEV | `keybuzz` |
| `keybuzz_api_prod` | API PROD + Backend PROD | `keybuzz_prod` |
| `kb_backend` | Backend DEV | `keybuzz_backend` |
| `kb_litellm` | LiteLLM | `keybuzz_litellm` |
| `keybuzz_emergency` | Urgence | toutes |
| `keybuzz_migrator` | Migrations | toutes |
| `seller_api_dev` | Seller API DEV | - |
| `postgres` | superuser | toutes |
| `replicator` | replication Patroni | - |
| `vault_admin` / `vault_db_manager` | Vault (DOWN) | - |
| `v-kubernet-*` / `v-root-*` | Vault dynamic credentials (expires) | - |

---

## 3. Connexions Services vers Databases

### DEV

| Service | Variable | Database | User | Host |
|---|---|---|---|---|
| keybuzz-api | `PGDATABASE` | `keybuzz` | `keybuzz_api_dev` | `10.0.0.10:5432` |
| keybuzz-backend | `DATABASE_URL` | `keybuzz_backend` | `kb_backend` | `10.0.0.10:5432` |
| keybuzz-backend | `PRODUCT_DATABASE_URL` | `keybuzz` | `keybuzz_api_dev` | `10.0.0.10:5432` |

### PROD

| Service | Variable | Database | User | Host |
|---|---|---|---|---|
| keybuzz-api | `PGDATABASE` | `keybuzz_prod` | `keybuzz_api_prod` | `10.0.0.10:5432` |
| keybuzz-backend | `DATABASE_URL` | `keybuzz_prod` | `keybuzz_api_prod` | `10.0.0.10:5432` |
| keybuzz-backend | `PRODUCT_DATABASE_URL` | `keybuzz_prod` | `keybuzz_api_prod` | `10.0.0.10:5432` |

**CONSTAT CRITIQUE** : En PROD, le backend utilise le meme user (`keybuzz_api_prod`) et la meme DB (`keybuzz_prod`) que l'API. Les deux services partagent tout.

---

## 4. Tables par Database — Inventaire Complet

### 4.1. `keybuzz` (DEV API) — 80 tables

| Table | Lignes | Categorie |
|---|---|---|
| `MessageAttachment` | 0 | legacy/orphan |
| `admin_notifications` | 0 | admin |
| `admin_setup_tokens` | 1 | admin |
| `admin_user_tenants` | 0 | admin |
| `admin_users` | 1 | admin |
| `agents` | 0 | core |
| `ai_action_log` | 1264 | IA |
| `ai_actions_ledger` | 276 | IA |
| `ai_actions_wallet` | 3 | IA |
| `ai_budget_alerts` | 3 | IA |
| `ai_budget_settings` | 3 | IA |
| `ai_context_attachments` | 1 | IA |
| `ai_credits_ledger` | 27 | IA |
| `ai_credits_wallet` | 2 | IA |
| `ai_evaluations` | 0 | IA |
| `ai_execution_audit` | 5 | IA |
| `ai_followup_cases` | 0 | IA |
| `ai_global_settings` | 1 | IA |
| `ai_human_approval_queue` | 1 | IA |
| `ai_journal_events` | 0 | IA |
| `ai_provider_usage` | 0 | IA |
| `ai_returns_decision_trace` | 18 | IA |
| `ai_rule_actions` | 216 | IA |
| `ai_rule_conditions` | 24 | IA |
| `ai_rules` | 90 | IA |
| `ai_settings` | 1 | IA |
| `ai_usage` | 373 | IA |
| `amazon_returns` | 1 | marketplace |
| `amazon_returns_sync_status` | 0 | marketplace |
| `audit_logs` | 0 | ops |
| `billing_customers` | 3 | billing |
| `billing_events` | 61 | billing |
| `billing_subscriptions` | 3 | billing |
| `cancel_reasons` | 1 | ops |
| `channel_rules` | 1 | core (DEV only) |
| `conversation_events` | 0 | messaging |
| `conversation_learning_events` | 9 | IA (DEV only) |
| `conversation_tags` | 0 | messaging |
| `conversations` | 204 | messaging |
| `feature_flags` | 11 | ops |
| `inbound_addresses` | 1 | messaging |
| `inbound_connections` | 1 | messaging |
| `incident_events` | 0 | ops |
| `incident_tenants` | 0 | ops |
| `incidents` | 0 | ops |
| `integration_required_credentials` | 0 | integrations |
| `integrations` | 0 | integrations |
| `knowledge_templates` | 1 | core (DEV only) |
| `marketplace_connections` | 0 | marketplace |
| `marketplace_octopia_accounts` | 0 | marketplace |
| `marketplace_sync_states` | 0 | marketplace |
| `merchant_behavior_profiles` | 1 | IA (DEV only) |
| `message_attachments` | 92 | messaging |
| `message_events` | 364 | messaging |
| `message_raw_mime` | 0 | messaging |
| `messages` | 706 | messaging |
| `notifications` | 0 | core |
| `oauth_states` | 0 | auth |
| `orders` | 11587 | orders |
| `otp_codes` | 1 | auth (DEV only) |
| `outbound_deliveries` | 202 | messaging |
| `playbook_suggestions` | 0 | IA |
| `return_analyses` | 7 | IA |
| `sla_policies` | 5 | ops |
| `space_invites` | 9 | core |
| `supplier_cases` | 9 | suppliers |
| `suppliers` | 1 | suppliers |
| `sync_states` | 3 | ops (DEV only) |
| `teams` | 0 | core |
| `tenant_ai_learning_settings` | 2 | IA |
| `tenant_ai_policies` | 0 | IA |
| `tenant_billing_exempt` | 1 | billing |
| `tenant_channels` | 6 | core |
| `tenant_metadata` | 4 | core |
| `tenant_profile_extra` | 1 | core |
| `tenant_settings` | 1 | core (DEV only) |
| `tenants` | 6 | core |
| `user_preferences` | 4 | core |
| `user_tenants` | 4 | core |
| `users` | 7 | core |

### 4.2. `keybuzz_backend` (DEV Backend Prisma) — 42 tables

| Table | Lignes | Schema |
|---|---|---|
| `AiResponseDraft` | 0 | PascalCase Prisma |
| `AiRule` | 0 | PascalCase Prisma |
| `AiRuleAction` | 0 | PascalCase Prisma |
| `AiRuleCondition` | 0 | PascalCase Prisma |
| `AiRuleExecution` | 0 | PascalCase Prisma |
| `AiUsageLog` | 0 | PascalCase Prisma |
| `ApiKey` | 0 | PascalCase Prisma |
| `ExternalMessage` | 40821 | PascalCase Prisma |
| `Job` | 58931 | PascalCase Prisma |
| `MarketplaceConnection` | 10 | PascalCase Prisma |
| `MarketplaceOutboundMessage` | 2 | PascalCase Prisma |
| `MarketplaceSyncState` | 21 | PascalCase Prisma |
| `OAuthState` | 103 | PascalCase Prisma |
| `Order` | 22885 | PascalCase Prisma |
| `OrderItem` | 23284 | PascalCase Prisma |
| `OutboundEmail` | 24 | PascalCase Prisma |
| `Team` | 0 | PascalCase Prisma |
| `TeamMembership` | 0 | PascalCase Prisma |
| `Tenant` | 15 | PascalCase Prisma |
| `TenantAiBudget` | 0 | PascalCase Prisma |
| `TenantBillingPlan` | 0 | PascalCase Prisma |
| `TenantQuotaUsage` | 0 | PascalCase Prisma |
| `Ticket` | 23 | PascalCase Prisma |
| `TicketAssignment` | 0 | PascalCase Prisma |
| `TicketBillingUsage` | 11 | PascalCase Prisma |
| `TicketEvent` | 21 | PascalCase Prisma |
| `TicketMessage` | 20 | PascalCase Prisma |
| `User` | 3 | PascalCase Prisma |
| `Webhook` | 0 | PascalCase Prisma |
| `_prisma_migrations` | 4 | Prisma system |
| `ai_journal_events` | 0 | snake_case (legacy) |
| `amazon_backfill_global_metrics_v2` | 1 | snake_case |
| `amazon_backfill_locks` | 0 | snake_case |
| `amazon_backfill_metrics_view` | 1 | snake_case |
| `amazon_backfill_schedule` | 9 | snake_case |
| `amazon_backfill_tenant_metrics` | 9 | snake_case |
| `amazon_orders_backfill_state` | 1 | snake_case |
| `amazon_returns` | 0 | snake_case (shared) |
| `amazon_returns_sync_status` | 0 | snake_case (shared) |
| `inbound_addresses` | 17 | snake_case (shared) |
| `inbound_connections` | 13 | snake_case (shared) |
| `return_analyses` | 0 | snake_case (shared) |

### 4.3. `keybuzz_prod` (PROD partage) — 80 tables

| Table | Lignes | Proprietaire |
|---|---|---|
| `ExternalMessage` | 3 | Backend Prisma |
| `MessageAttachment` | 0 | legacy/orphan |
| `Order` | **0** | Backend Prisma (VIDE) |
| `OrderItem` | **0** | Backend Prisma (VIDE) |
| `admin_notifications` | 0 | admin |
| `admin_setup_tokens` | 2 | admin |
| `admin_user_tenants` | 0 | admin |
| `admin_users` | 1 | admin |
| `agents` | 0 | API |
| `ai_action_log` | 20 | API |
| `ai_actions_ledger` | 50 | API |
| `ai_actions_wallet` | 4 | API |
| `ai_budget_alerts` | 0 | API |
| `ai_budget_settings` | 4 | API |
| `ai_context_attachments` | 0 | API |
| `ai_credits_ledger` | 0 | API |
| `ai_credits_wallet` | 4 | API |
| `ai_evaluations` | 0 | API |
| `ai_execution_audit` | 7 | API |
| `ai_followup_cases` | 0 | API |
| `ai_global_settings` | 1 | API |
| `ai_human_approval_queue` | 2 | API |
| `ai_journal_events` | 19 | API |
| `ai_provider_usage` | 0 | API |
| `ai_returns_decision_trace` | 0 | API |
| `ai_rule_actions` | 108 | API |
| `ai_rule_conditions` | 12 | API |
| `ai_rules` | 45 | API |
| `ai_settings` | 1 | API |
| `ai_usage` | 39 | API |
| `amazon_backfill_locks` | 0 | Backend |
| `amazon_backfill_schedule` | 0 | Backend |
| `amazon_backfill_tenant_metrics` | 0 | Backend |
| `amazon_orders_backfill_state` | 0 | Backend |
| `amazon_returns` | 0 | shared |
| `amazon_returns_sync_status` | 0 | shared |
| `audit_logs` | 0 | ops |
| `billing_customers` | 2 | API |
| `billing_events` | 57 | API |
| `billing_subscriptions` | 2 | API |
| `cancel_reasons` | 1 | ops |
| `conversation_events` | 0 | API |
| `conversation_tags` | 0 | API |
| `conversations` | 191 | API |
| `feature_flags` | 11 | ops |
| `inbound_addresses` | 1 | shared |
| `inbound_connections` | 1 | shared |
| `incident_events` | 0 | ops |
| `incident_tenants` | 0 | ops |
| `incidents` | 0 | ops |
| `integration_required_credentials` | 0 | API |
| `integrations` | 0 | API |
| `marketplace_connections` | 0 | shared |
| `marketplace_octopia_accounts` | 0 | API |
| `marketplace_sync_states` | 0 | shared |
| `message_attachments` | 96 | API |
| `message_events` | 465 | API |
| `message_raw_mime` | 0 | API |
| `messages` | 702 | API |
| `notifications` | 0 | API |
| `oauth_states` | 0 | shared |
| `orders` | 5315 | API |
| `outbound_deliveries` | 30 | API |
| `playbook_suggestions` | 0 | API |
| `return_analyses` | 0 | shared |
| `sla_policies` | 5 | API |
| `space_invites` | 0 | API |
| `supplier_cases` | 7 | API |
| `suppliers` | 1 | API |
| `teams` | 0 | API |
| `tenant_ai_learning_settings` | 0 | API |
| `tenant_ai_policies` | 0 | API |
| `tenant_billing_exempt` | 1 | API |
| `tenant_channels` | 2 | API |
| `tenant_metadata` | 3 | API |
| `tenant_profile_extra` | 1 | API |
| `tenants` | 3 | API |
| `user_preferences` | 3 | API |
| `user_tenants` | 3 | API |
| `users` | 4 | API |

---

## 5. Duplication de Tables (Order vs orders)

### PROD : `Order` (Prisma) vs `orders` (API)

| Aspect | `orders` (API) | `Order` (Prisma) |
|---|---|---|
| **Lignes** | **5 315** | **0** |
| **Convention** | snake_case | PascalCase |
| **ORM** | pg Pool (SQL brut) | Prisma Client |
| **Colonnes** | 20 (snake_case) | 24 (camelCase) |
| **FK** | aucune | `OrderItem.orderId -> Order.id` |
| **Statut** | ACTIVE, donnees reelles | VIDE, jamais utilisee en PROD |

#### Colonnes `orders` (API, 20 colonnes)

```
id, tenant_id, external_order_id, channel, status, total_amount,
currency, order_date, fulfillment_channel, customer_name, customer_email,
customer_address, carrier, tracking_code, tracking_url, delivery_status,
products, raw_data, created_at, updated_at
```

#### Colonnes `Order` (Prisma, 24 colonnes)

```
id, tenantId, externalOrderId, orderRef, marketplace, customerName,
customerEmail, orderDate, currency, totalAmount, orderStatus,
deliveryStatus, savStatus, slaStatus, carrier, trackingCode,
shippingAddress, createdAt, updatedAt, shippedAt, deliveredAt,
fulfillmentChannel, trackingUrl, trackingSource
```

**Conclusion** : Les deux tables representent le meme concept mais avec des schemas incompatibles. En PROD, seule `orders` (API) contient des donnees. La table `Order` (Prisma) a ete creee par une migration Prisma mais n'est jamais alimentee.

### Meme situation pour ExternalMessage

| Table | PROD | DEV Backend |
|---|---|---|
| `ExternalMessage` | 3 lignes | 40 821 lignes |

En DEV, le Backend remplit `ExternalMessage` via l'import Amazon. En PROD, il semble ne pas ecrire dans cette table.

---

## 6. Differences DEV vs PROD

### Tables presentes en DEV mais absentes en PROD (7)

| Table | Lignes DEV | Impact |
|---|---|---|
| `channel_rules` | 1 | Fonctionnalite manquante en PROD |
| `conversation_learning_events` | 9 | Moteurs IA PH51/PH95/PH96 impactes |
| `knowledge_templates` | 1 | Base de reponses manquante |
| `merchant_behavior_profiles` | 1 | Moteur PH50 impacte |
| `otp_codes` | 1 | Auth OTP Redis (pas critique, Redis gere) |
| `sync_states` | 3 | Sync marketplace impacte |
| `tenant_settings` | 1 | Parametres tenant manquants |

**ALERTE** : `conversation_learning_events` est necessaire pour les moteurs PH51, PH95 (Global Learning) et PH96 (Seller DNA). Son absence en PROD signifie que ces moteurs retournent des fallbacks.

### Tables presentes en PROD mais absentes en DEV (7)

| Table | Lignes PROD | Proprietaire |
|---|---|---|
| `ExternalMessage` | 3 | Backend Prisma |
| `Order` | 0 | Backend Prisma (vide) |
| `OrderItem` | 0 | Backend Prisma (vide) |
| `amazon_backfill_locks` | 0 | Backend |
| `amazon_backfill_schedule` | 0 | Backend |
| `amazon_backfill_tenant_metrics` | 0 | Backend |
| `amazon_orders_backfill_state` | 0 | Backend |

---

## 7. Foreign Key Constraints

### DEV (`keybuzz`) — 5 FK

```
admin_setup_tokens.user_id      -> admin_users.id
admin_user_tenants.user_id      -> admin_users.id
incident_events.incident_id     -> incidents.id
incident_tenants.incident_id    -> incidents.id
supplier_cases.supplier_id      -> suppliers.id
```

### PROD (`keybuzz_prod`) — 6 FK

```
OrderItem.orderId               -> Order.id            (Prisma, tables vides)
admin_setup_tokens.user_id      -> admin_users.id
admin_user_tenants.user_id      -> admin_users.id
incident_events.incident_id     -> incidents.id
incident_tenants.incident_id    -> incidents.id
supplier_cases.supplier_id      -> suppliers.id
```

**Note** : Les tables principales (`conversations`, `messages`, `orders`, `users`, `tenants`, `user_tenants`) n'ont PAS de FK entre elles. Elles utilisent des references logiques par `tenant_id` (TEXT).

---

## 8. Tables Partagees (utilisees par API ET Backend)

| Table | API | Backend | Risque split |
|---|---|---|---|
| `inbound_addresses` | lecture | lecture/ecriture | MOYEN |
| `inbound_connections` | lecture | lecture/ecriture | MOYEN |
| `marketplace_connections` | lecture | lecture/ecriture | MOYEN |
| `marketplace_sync_states` | lecture | lecture/ecriture | MOYEN |
| `oauth_states` | lecture/ecriture | lecture/ecriture | HAUT |
| `amazon_returns` | lecture | lecture/ecriture | MOYEN |
| `amazon_returns_sync_status` | lecture | ecriture | BAS |
| `return_analyses` | lecture/ecriture | lecture | BAS |
| `users` | lecture (auth debug) | lecture | BAS |
| `user_tenants` | lecture (auth debug) | lecture | BAS |

---

## 9. Utilisation de `users` / `user_tenants` par l'API

L'API utilise ces tables dans 2 requetes (`ai-policy-debug-routes.ts`) :

```sql
SELECT ut.role FROM user_tenants ut
JOIN users u ON u.id = ut.user_id
WHERE u.email = $1 AND ut.tenant_id = $2
```

Usage : verification du role pour les endpoints `/ai/policy/effective` et POST `/ai/learning-control`.

Ces tables sont lues, jamais ecrites par l'API.

---

## 10. Prisma dans le Backend

### DEV

- `_prisma_migrations` : 4 migrations executees
- `DATABASE_URL` : `postgresql://kb_backend:***@10.0.0.10:5432/keybuzz_backend`
- Schema : PascalCase (Ticket, TicketMessage, Order, User, Tenant, etc.)

### PROD

- `_prisma_migrations` : **absente** (les tables Prisma ont ete creees mais pas via le systeme de migration)
- `DATABASE_URL` : `postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod`
- Les tables Prisma (Order, OrderItem, ExternalMessage) existent mais sont VIDES

---

## 11. Volume de Donnees

### DEV

| Donnee | Volume |
|---|---|
| Orders (API) | 11 587 |
| Orders (Backend Prisma) | 22 885 |
| ExternalMessage (Backend) | 40 821 |
| Jobs (Backend) | 58 931 |
| Conversations (API) | 204 |
| Messages (API) | 706 |
| AI Action Log | 1 264 |
| AI Actions Ledger | 276 |

### PROD

| Donnee | Volume |
|---|---|
| Orders (API) | 5 315 |
| Conversations | 191 |
| Messages | 702 |
| Message Events | 465 |
| Message Attachments | 96 |
| AI Rules | 45 |
| Billing Events | 57 |
| AI Actions Ledger | 50 |
| AI Usage | 39 |
| Outbound Deliveries | 30 |

---

## 12. Recommandations

### R1 — PRIORITE HAUTE : Creer les 7 tables manquantes en PROD

Les tables `conversation_learning_events`, `merchant_behavior_profiles`, `channel_rules`, `knowledge_templates`, `otp_codes`, `sync_states`, `tenant_settings` doivent etre creees en PROD pour que les moteurs IA PH50/PH51/PH95/PH96 fonctionnent correctement.

**Risque actuel** : Les moteurs retournent des fallbacks au lieu de donnees reelles.

### R2 — PRIORITE HAUTE : Splitter keybuzz_prod

Creer `keybuzz_backend_prod` pour le Backend PROD :
1. Creer la DB et le user dedie
2. Executer les migrations Prisma
3. Migrer `ExternalMessage` (3 lignes) vers la nouvelle DB
4. Mettre a jour `DATABASE_URL` du Backend PROD
5. Conserver `PRODUCT_DATABASE_URL` pointant vers `keybuzz_prod`

### R3 — PRIORITE MOYENNE : Nettoyer les tables Prisma vides en PROD

Supprimer `Order`, `OrderItem` de `keybuzz_prod` (0 lignes, jamais utilisees). Cela eliminera aussi la FK orpheline `OrderItem.orderId -> Order.id`.

### R4 — PRIORITE BASSE : Renommer les DB DEV

Evaluer le renommage :
- `keybuzz` -> `keybuzz_api_dev`
- `keybuzz_backend` -> `keybuzz_backend_dev`

**Risque** : Necessite la mise a jour de tous les secrets K8s et un restart complet. Benefice faible (nommage seulement).

### R5 — PRIORITE BASSE : Aligner Prisma en PROD

Initialiser `_prisma_migrations` dans `keybuzz_backend_prod` pour permettre les futures migrations schema.

---

## 13. Diagramme Architecture Cible

```
DEV (actuel, deja split)
  keybuzz-api        --> keybuzz          (80 tables snake_case)
  keybuzz-backend    --> keybuzz_backend  (42 tables PascalCase)
                     --> keybuzz (PRODUCT_DATABASE_URL, lecture seule)

PROD (cible apres split)
  keybuzz-api        --> keybuzz_prod     (tables API snake_case)
  keybuzz-backend    --> keybuzz_backend_prod (NEW, tables Prisma PascalCase)
                     --> keybuzz_prod (PRODUCT_DATABASE_URL, lecture seule)
```

---

## 14. Risques du Split PROD

| Risque | Probabilite | Impact | Mitigation |
|---|---|---|---|
| Perte de donnees ExternalMessage | Faible | Moyen | Backup avant migration |
| Tables partagees inaccessibles | Moyen | Haut | Conserver PRODUCT_DATABASE_URL |
| OAuth flow casse | Moyen | Haut | Tester oauth_states apres split |
| Downtime Backend PROD | Faible | Haut | Maintenance window planifiee |
| FK OrderItem orpheline | Nul | Nul | Tables vides, suppression safe |

---

## 15. Prochaines Etapes

1. **PH-TD-02** : Creer les 7 tables manquantes en PROD (migration SQL)
2. **PH-TD-03** : Creer `keybuzz_backend_prod` + user + permissions
3. **PH-TD-04** : Migrer les tables Backend vers la nouvelle DB
4. **PH-TD-05** : Tester non-regression complete
5. **PH-TD-06** : Nettoyer les tables Prisma vides de `keybuzz_prod`

---

## Annexe : Scripts d'Audit

- `scripts/db-audit.sh` : Audit initial (databases, tables, env vars, users)
- `scripts/db-audit-deep.sh` : Audit approfondi (row counts, FK, colonnes, comparaison Order vs orders)
