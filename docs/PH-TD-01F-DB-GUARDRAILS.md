# PH-TD-01F — DB Guardrails & Anti-Drift Enforcement

> Date : 15 mars 2026
> Statut : TERMINÉ
> Prérequis : PH-TD-01A/B/C/D/E

---

## 1. Objectif

Empêcher toute régression de l'architecture dual-DB établie en PH-TD-01C :

- Réintroduction de tables Prisma fantômes dans `keybuzz_prod`
- Mélange backend/API dans la mauvaise DB
- Dérive silencieuse des accès DB
- Confusion entre `DATABASE_URL`, `PRODUCT_DATABASE_URL`, `PGDATABASE`

---

## 2. Source de Vérité

Les documents suivants font foi :

| Document | Contenu |
|----------|---------|
| `DB-ARCHITECTURE-CONTRACT.md` | Contrat dual-DB officiel |
| `DB-TABLE-MATRIX.md` | Matrice tables par DB |
| `DB-ACCESS-MAP.md` | Mapping accès services → tables |

---

## 3. Script Anti-Drift

### Fichier

`scripts/db-architecture-check.sh`

### Usage

```bash
bash /opt/keybuzz/scripts/db-architecture-check.sh
```

Utilisable :
- Manuellement (ops quotidien)
- Dans une pipeline CI future
- Comme routine de vérification post-déploiement

### Sections du script

| Section | Tests | Description |
|---------|-------|-------------|
| 1. ENV VAR ISOLATION | 8 | Variables d'env correctement séparées |
| 2. FORBIDDEN PASCAL TABLES | 29 | Aucune table PascalCase interdite dans keybuzz_prod |
| 3. ALLOWED PASCAL CHECK | 2 | Tables PascalCase autorisées présentes |
| 4. REQUIRED BACKEND TABLES | 15 | Tables Prisma backend présentes dans keybuzz_backend_prod |
| 5. REQUIRED PROD TABLES | 10 | Tables API présentes dans keybuzz_prod |
| 6. NO PROD LEAK | 6 | Tables critiques produit absentes de la backend DB |
| 7. PRISMA MIGRATIONS | 2 | _prisma_migrations cohérent, pas de migration échouée |
| 8. ESO MANAGEMENT | 1 | DATABASE_URL non géré par ExternalSecrets |
| 9. CONNECTIVITY | 4 | Backend DB, Product DB, API, Backend health |
| **TOTAL** | **77** | |

---

## 4. Classification Stricte

### Tables API autorisées dans keybuzz_prod

```
conversations, messages, orders, tenants, users, user_tenants,
billing_subscriptions, billing_customers, billing_events,
ai_actions_wallet, ai_actions_ledger, ai_credits_wallet, ai_credits_ledger,
ai_action_log, ai_budget_settings, ai_budget_alerts, ai_global_settings,
ai_context_attachments, ai_journal_events, ai_returns_decision_trace,
ai_settings, ai_usage, ai_rule_actions, ai_rule_conditions, ai_rules,
outbound_deliveries, sla_policies, amazon_returns, amazon_returns_sync_status,
inbound_addresses, inbound_connections, marketplace_connections,
marketplace_octopia_accounts, marketplace_sync_states,
message_attachments, message_events, message_raw_mime,
conversation_events, conversation_tags,
notifications, oauth_states, otp_codes, return_analyses,
channel_rules, knowledge_templates, integration_required_credentials,
integrations, sync_states, teams, agents,
tenant_metadata, tenant_profile_extra, tenant_settings,
tenant_billing_exempt, space_invites, supplier_cases, suppliers,
user_preferences
```

### Tables PascalCase autorisées dans keybuzz_prod

```
ExternalMessage (legacy partagée, usage actif backend + API)
```

### Tables interdites dans keybuzz_prod

```
Order, OrderItem, MessageAttachment (supprimées PH-TD-01E)
Ticket, TicketMessage, TicketEvent, TicketAssignment, TicketBillingUsage
MarketplaceConnection, MarketplaceSyncState, MarketplaceOutboundMessage
OAuthState, Job, OutboundEmail
AiRule, AiRuleAction, AiRuleCondition, AiRuleExecution, AiResponseDraft, AiUsageLog
ApiKey, Team, TeamMembership, Tenant, User, Webhook
TenantAiBudget, TenantBillingPlan, TenantQuotaUsage
```

### Tables backend exclusives (keybuzz_backend_prod)

```
ExternalMessage, Ticket, TicketMessage
MarketplaceConnection, OAuthState, Job
Order, OrderItem
AiRule, AiResponseDraft, AiUsageLog
TenantAiBudget, TenantBillingPlan, TenantQuotaUsage
_prisma_migrations
```

### Tables interdites dans keybuzz_backend_prod

```
conversations, messages, outbound_deliveries
billing_subscriptions, billing_customers, billing_events
```

---

## 5. Guardrail Logging

Le script émet un log structuré exploitable :

```
[DB-ARCHITECTURE-CHECK]
service: db-architecture-check
database: keybuzz_prod / keybuzz_backend_prod
status: COMPLIANT / DRIFT DETECTED
reason: <détail>
```

Sortie : exit code 0 (compliant) ou 1 (drift).

---

## 6. Résultats

### Exécution du 15 mars 2026

```
RESULT: 77 passed, 0 failed, 0 warnings / 77 total
STATUS: DB ARCHITECTURE COMPLIANT
```

Toutes les vérifications passent :
- Variables d'env correctement séparées
- Aucune table PascalCase interdite dans keybuzz_prod
- Toutes les tables backend présentes dans keybuzz_backend_prod
- Toutes les tables API présentes dans keybuzz_prod
- Aucune table critique produit dans la backend DB
- Prisma migrations cohérentes
- DATABASE_URL non géré par ESO
- Connectivité OK

---

## 7. Usage Ops

```bash
# Vérification post-déploiement
bash /opt/keybuzz/scripts/db-architecture-check.sh

# Si drift détecté (exit code 1)
# → Investiguer les tables listées en FAIL
# → Ne PAS corriger automatiquement sans analyse

# CI future
# → Ajouter comme step post-deploy dans la pipeline
# → Bloquer le merge si exit code != 0
```

---

## 8. Rollback

Script en lecture seule, aucune modification DB. Pas de rollback nécessaire.
