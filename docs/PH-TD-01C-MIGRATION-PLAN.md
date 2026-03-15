# PH-TD-01C — Safe DB Split Minimal — Plan de Migration

> Date : 15 mars 2026
> Auteur : Agent Cursor
> Prerequis : PH-TD-01A (28 fev 2026) + PH-TD-01B (1 mars 2026)
> Environnement : DEV + PROD
> Mode : migration controlee ultra securisee

---

## 0. ETAT ACTUEL (verifie 15 mars 2026)

### Patroni Cluster

| Noeud | IP | Role | Etat |
|---|---|---|---|
| db-postgres-01 | 10.0.0.120 | **REPLICA** | running |
| db-postgres-02 | 10.0.0.121 | **REPLICA** | running |
| db-postgres-03 | 10.0.0.122 | **PRIMARY** | running |

Le leader a change : db-postgres-03 est maintenant le PRIMARY.
db-postgres-02 est remonte — cluster sain (1 primary + 2 replicas).

### Databases existantes

| Database | Usage |
|---|---|
| keybuzz | DEV API |
| keybuzz_backend | DEV Backend (Prisma) |
| keybuzz_litellm | LiteLLM |
| keybuzz_prod | PROD (API + Backend partage) |
| **keybuzz_backend_prod** | **N'EXISTE PAS** — a creer |

### DB Users

| User | Usage |
|---|---|
| keybuzz_api_prod | API PROD + Backend PROD (actuellement) |
| kb_backend | Backend DEV |
| keybuzz_api_dev | API DEV |
| postgres | Superuser |

### PROD — Tables dans keybuzz_prod (87)

- **4 PascalCase** : ExternalMessage (3 rows), MessageAttachment (0), Order (0), OrderItem (0)
- **83 snake_case** : tables API (conversations, messages, orders, ai_*, billing_*, etc.)
- **4 amazon_backfill** : toutes vides (0 rows)

### Backend PROD — Config actuelle

```
DATABASE_URL     = postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
PRODUCT_DATABASE_URL = postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
PGDATABASE       = keybuzz_prod
```

Les deux pointent vers la meme DB. Aucune separation.

---

## 1. TABLES A DEPLACER (LISTE CONFIRMEE)

### 1.1 Tables Prisma PascalCase (du schema Prisma)

Toutes ces tables seront creees dans `keybuzz_backend_prod` via pg_dump schema du DEV backend :

| Table | Statut PROD | Rows PROD | Action |
|---|---|---|---|
| AiResponseDraft | n'existe pas | - | creer (vide) |
| AiRule | n'existe pas | - | creer (vide) |
| AiRuleAction | n'existe pas | - | creer (vide) |
| AiRuleCondition | n'existe pas | - | creer (vide) |
| AiRuleExecution | n'existe pas | - | creer (vide) |
| AiUsageLog | n'existe pas | - | creer (vide) |
| ApiKey | n'existe pas | - | creer (vide) |
| **ExternalMessage** | **EXISTE** | **3 rows** | **creer + copier data** |
| Job | n'existe pas | - | creer (vide) |
| MarketplaceConnection | n'existe pas | - | creer (vide) |
| MarketplaceOutboundMessage | n'existe pas | - | creer (vide) |
| MarketplaceSyncState | n'existe pas | - | creer (vide) |
| OAuthState | n'existe pas | - | creer (vide) |
| Order (PascalCase) | EXISTE | 0 rows | creer (vide) |
| OrderItem | EXISTE | 0 rows | creer (vide) |
| OutboundEmail | n'existe pas | - | creer (vide) |
| Team | n'existe pas | - | creer (vide) |
| TeamMembership | n'existe pas | - | creer (vide) |
| Tenant (PascalCase) | n'existe pas | - | creer (vide) |
| TenantAiBudget | n'existe pas | - | creer (vide) |
| TenantBillingPlan | n'existe pas | - | creer (vide) |
| TenantQuotaUsage | n'existe pas | - | creer (vide) |
| Ticket | n'existe pas | - | creer (vide) |
| TicketAssignment | n'existe pas | - | creer (vide) |
| TicketBillingUsage | n'existe pas | - | creer (vide) |
| TicketEvent | n'existe pas | - | creer (vide) |
| TicketMessage | n'existe pas | - | creer (vide) |
| User (PascalCase) | n'existe pas | - | creer (vide) |
| Webhook | n'existe pas | - | creer (vide) |
| _prisma_migrations | n'existe pas | - | creer (copie migrations) |

Tables generees par Prisma @@map (seront creees par le schema mais resteront vides) :
- inbound_connections (@@map)
- inbound_addresses (@@map)

### 1.2 Tables non-Prisma (backend exclusives)

| Table | Statut PROD | Rows PROD | Action |
|---|---|---|---|
| amazon_backfill_global_metrics_v2 | n'existe pas | - | creer via DDL |
| amazon_backfill_locks | EXISTE | 0 | creer via DDL |
| amazon_backfill_metrics_view | n'existe pas | - | creer via DDL |
| amazon_backfill_schedule | EXISTE | 0 | creer via DDL |
| amazon_backfill_tenant_metrics | EXISTE | 0 | creer via DDL |
| amazon_orders_backfill_state | EXISTE | 0 | creer via DDL |

### 1.3 Donnees a copier

| Table | Source | Rows | Methode |
|---|---|---|---|
| ExternalMessage | keybuzz_prod | 3 | pg_dump data-only + psql |

Total donnees a copier : **3 rows**. Risque minimal.

---

## 2. TABLES A NE PAS DEPLACER

Restent dans `keybuzz_prod` (aucune modification) :

- **83 tables snake_case API** (conversations, messages, orders, users, tenants, ai_*, billing_*, etc.)
- **MessageAttachment** (PascalCase legacy, partage avec API)
- **4 tables amazon_backfill** dans keybuzz_prod (pas de suppression dans cette phase)
- **Order/OrderItem** PascalCase dans keybuzz_prod (pas de suppression dans cette phase)
- **ExternalMessage** dans keybuzz_prod (pas de suppression, copie seulement)

---

## 3. SERVICES IMPACTES PAR LA BASCULE

### A modifier

| Service | Namespace | DATABASE_URL avant | DATABASE_URL apres |
|---|---|---|---|
| keybuzz-backend | keybuzz-backend-prod | keybuzz_prod | **keybuzz_backend_prod** |
| amazon-orders-worker | keybuzz-backend-prod | keybuzz_prod | **keybuzz_backend_prod** |
| amazon-items-worker | keybuzz-backend-prod | keybuzz_prod | **keybuzz_backend_prod** |

PRODUCT_DATABASE_URL reste `keybuzz_prod` pour tous.

### AUCUN changement

| Service | Namespace | Raison |
|---|---|---|
| keybuzz-api | keybuzz-api-prod | Utilise keybuzz_prod directement |
| keybuzz-outbound-worker | keybuzz-api-prod | Utilise keybuzz_prod (PGDATABASE) |
| CronJobs SLA | keybuzz-api-prod | SQL direct sur tables API |
| CronJobs outbound-tick | keybuzz-api-prod | POST vers API |
| CronJobs Amazon sync | keybuzz-backend-prod | cURL vers backend |

---

## 4. ETAPES DETAILLEES

### ETAPE 1 — Backup global

**Actions :**
1. `pg_dump keybuzz_prod` (structure + donnees) sur le leader (10.0.0.122)
2. `pg_dump --schema-only keybuzz_backend` (DEV schema) depuis 10.0.0.120
3. Nommer : `keybuzz_prod_backup_20260315_pre_split.sql`
4. Stocker dans `/opt/keybuzz/backups/` sur le bastion

**Tests :**
- Fichier backup existe et taille > 0
- Fichier schema existe

**Rollback :** N/A (lecture seule)

### ETAPE 2 — Creation keybuzz_backend_prod

**Actions :**
1. SSH au leader (10.0.0.122)
2. `CREATE DATABASE keybuzz_backend_prod OWNER postgres;`
3. `GRANT ALL ON DATABASE keybuzz_backend_prod TO keybuzz_api_prod;`
4. `GRANT ALL ON DATABASE keybuzz_backend_prod TO kb_backend;`
5. Appliquer le schema : `psql keybuzz_backend_prod < schema_keybuzz_backend.sql`
6. Accorder les permissions sur les tables/sequences

**Tests :**
- keybuzz_backend_prod existe dans pg_database
- Connexion OK avec keybuzz_api_prod
- Tables PascalCase presentes (count = 42 comme DEV)
- Enums presents
- Indexes presents
- Aucune table snake_case API (conversations, messages, etc.)

**Rollback :** `DROP DATABASE keybuzz_backend_prod;`

### ETAPE 3 — Copie des donnees

**Actions :**
1. Copier ExternalMessage (3 rows) depuis keybuzz_prod vers keybuzz_backend_prod
2. Copier _prisma_migrations depuis keybuzz_backend (DEV)

**Tests par table :**
- ExternalMessage : row count = 3, SELECT * OK
- _prisma_migrations : row count identique au DEV

**Rollback :** `TRUNCATE TABLE "ExternalMessage" CASCADE;`

### ETAPE 4 — Validation hors runtime (cold test)

**Actions :**
1. Test connexion Prisma vers keybuzz_backend_prod
2. Test lecture ExternalMessage
3. Test lecture MarketplaceConnection (vide, pas d'erreur)
4. Test PRODUCT_DATABASE_URL vers keybuzz_prod (lectures partagees)
5. Script : `scripts/td01c-cold-test.sh`

**Tests :**
- Prisma connect OK
- ExternalMessage SELECT OK (3 rows)
- MarketplaceConnection SELECT OK (0 rows, pas d'erreur)
- Conversations via PRODUCT_DATABASE_URL OK
- Orders via PRODUCT_DATABASE_URL OK

**Rollback :** N/A (pas de changement runtime)

### ETAPE 5 — Bascule DEV d'abord

**Prerequis :** DEV utilise deja la separation (keybuzz_backend + keybuzz via PRODUCT_DATABASE_URL).
On verifie simplement que DEV fonctionne toujours correctement.

**Tests DEV :**
- Backend health OK
- Backend endpoints OK
- Amazon OAuth state OK
- Marketplace status OK

**Rollback :** N/A (pas de changement, verification seulement)

### ETAPE 6 — Bascule runtime PROD

**Actions :**
1. Modifier le secret K8s `keybuzz-backend-env` dans `keybuzz-backend-prod`
   - `DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_backend_prod`
   - `PRODUCT_DATABASE_URL` reste inchange
2. Restart rolling des pods backend

**Config avant :**
```
DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
PRODUCT_DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
```

**Config apres :**
```
DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_backend_prod
PRODUCT_DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
```

**Tests immediats :**
- Backend health /health OK
- Backend endpoints critiques OK
- OAuth state OK
- Marketplace status OK
- API inchangee (health, billing, channels, conversations, AI)
- Workers inchanges (outbound-worker health)
- Zero erreur Prisma dans les logs

**Go/No-Go :**
Si UNE route critique casse → rollback immediat

**Rollback :**
Remettre DATABASE_URL vers keybuzz_prod :
```
DATABASE_URL=postgresql://keybuzz_api_prod:***@10.0.0.10:5432/keybuzz_prod
```
Restart pods.

### ETAPE 7 — Observation post-bascule

**Actions :**
1. Surveiller logs backend pendant 5-10 minutes
2. Verifier erreurs Prisma
3. Verifier erreurs SQL
4. Verifier /health
5. Verifier endpoints cles

**Duree :** 10 minutes minimum

### ETAPE 8 — Rapport + commit

**PAS de cleanup dans cette phase :**
- NE PAS supprimer les tables PascalCase de keybuzz_prod
- NE PAS nettoyer Order/OrderItem PascalCase
- NE PAS realigner Prisma migrations
- NE PAS supprimer les duplications

**Livrable :** `keybuzz-infra/docs/PH-TD-01C-SAFE-DB-SPLIT-REPORT.md`

---

## 5. RISQUES IDENTIFIES

| # | Risque | Impact | Mitigation |
|---|---|---|---|
| R1 | InboundAddress/InboundConnection (@@map) vides dans la nouvelle DB | Backend perd visibilite inbound | Ces tables sont creees mais vides. Si le backend les lit via Prisma, il obtient 0 results. Non critique car le backend en PROD ne semble pas utiliser ces modeles activement. |
| R2 | Tenant/User PascalCase vides | Backend Prisma queries sur Tenant/User retournent vide | Non critique : ces modeles ne sont pas appeles en PROD (table "Tenant" n'existait deja pas avant le split). |
| R3 | Amazon workers perdent acces aux tables partagees | Workers ne peuvent plus lire orders/conversations | Non concerne : les workers utilisent PRODUCT_DATABASE_URL pour les lectures produit. |
| R4 | Schema DEV diverge de PROD | Tables creees avec mauvaise structure | Risque faible : meme PG17, meme codebase, schema DEV = reference. |
| R5 | Permissions insuffisantes | Prisma ne peut pas ecrire dans keybuzz_backend_prod | Mitigation : GRANT ALL sur toutes tables + sequences a keybuzz_api_prod. |

---

## 6. CHECKLIST GO/NO-GO

- [ ] Backup keybuzz_prod cree et valide
- [ ] Schema DEV backend exporte
- [ ] keybuzz_backend_prod creee
- [ ] Permissions OK
- [ ] Tables presentes (42)
- [ ] ExternalMessage copiee (3 rows)
- [ ] Cold test Prisma OK
- [ ] Cold test PRODUCT_DATABASE_URL OK
- [ ] DEV smoke check OK
- [ ] PROD bascule DATABASE_URL
- [ ] Backend health OK
- [ ] Endpoints critiques OK
- [ ] API inchangee OK
- [ ] Workers inchanges OK
- [ ] Billing inchange OK
- [ ] Channels inchanges OK
- [ ] IA endpoints inchanges OK
- [ ] Zero erreur Prisma critique
- [ ] Observation 10 min OK
- [ ] Rollback pret

---

## 7. COMMANDE DE ROLLBACK URGENTE

```bash
# Sur le bastion
PODBK=$(kubectl get pods -n keybuzz-backend-prod -l app=keybuzz-backend -o jsonpath='{.items[0].metadata.name}')

# Remettre DATABASE_URL
kubectl set env deployment/keybuzz-backend -n keybuzz-backend-prod DATABASE_URL="postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod"
kubectl set env deployment/amazon-orders-worker -n keybuzz-backend-prod DATABASE_URL="postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod"
kubectl set env deployment/amazon-items-worker -n keybuzz-backend-prod DATABASE_URL="postgresql://keybuzz_api_prod:PASSWORD@10.0.0.10:5432/keybuzz_prod"

# Attendre restart
kubectl rollout status deployment/keybuzz-backend -n keybuzz-backend-prod
kubectl rollout status deployment/amazon-orders-worker -n keybuzz-backend-prod
kubectl rollout status deployment/amazon-items-worker -n keybuzz-backend-prod
```

Temps estime rollback : < 2 minutes.
