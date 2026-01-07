# PH15-AMAZON-DB-FOUNDATION-01 — Rapport

**Date** : 7 janvier 2026  
**Objectif** : Restaurer les tables Amazon/Inbound en DB DEV + synchroniser Prisma

---

## 📋 RÉSUMÉ EXÉCUTIF

| Élément | Statut |
|---------|--------|
| Tables DB | ✅ Toutes présentes |
| Enums PostgreSQL | ✅ Créés |
| Prisma migrate | ✅ Synchronisé |
| Données test | ✅ Présentes |
| keybuzz-backend routes | ⚠️ Non déployé sur K8s |

---

## 🔍 DÉCOUVERTE IMPORTANTE

### Architecture DB actuelle

| Serveur | Base | Rôle | Tables Amazon |
|---------|------|------|---------------|
| 10.0.0.121 | `keybuzz_backend` | **LEADER** (write) | ✅ Toutes présentes |
| 10.0.0.122 | `keybuzz_backend` | **REPLICA** (read-only) | ✅ Réplication OK |
| 10.0.0.121 | `keybuzz` | DB legacy | ❌ Tables absentes |

**Note** : Le rapport PH-RESTORE avait identifié des tables manquantes sur `keybuzz` (10.0.0.121), mais les tables existent bien sur `keybuzz_backend` (10.0.0.121/122).

---

## 📊 TABLES EXISTANTES

### Sur `keybuzz_backend` (10.0.0.121/122)

| Table | Owner | Données |
|-------|-------|---------|
| `MarketplaceConnection` | kb_backend | 2 connexions (tenant_test_dev, kbz_test) |
| `OAuthState` | kb_backend | 5 états OAuth |
| `inbound_connections` | kb_backend | 2 connexions |
| `inbound_addresses` | kb_backend | 5 adresses |
| `MarketplaceSyncState` | kb_backend | Vide |

### Enums créés

```sql
MarketplaceType: AMAZON, FNAC, CDISCOUNT, OTHER
MarketplaceConnectionStatus: PENDING, CONNECTED, ERROR, DISABLED
InboundConnectionStatus: DRAFT, WAITING_EMAIL, WAITING_AMAZON, READY, DEGRADED, ERROR
InboundValidationStatus: PENDING, VALIDATED, FAILED
```

### Indexes

```
marketplace_connections_tenantId_type_idx
inbound_connections_tenantId_marketplace_key
inbound_connections_status_idx
inbound_addresses_tenantId_marketplace_country_key
inbound_addresses_validationStatus_lastInboundAt_idx
inbound_addresses_pipelineStatus_marketplaceStatus_idx
oauth_states_state_key (UNIQUE)
oauth_states_state_idx
oauth_states_tenantId_idx
oauth_states_connectionId_idx
oauth_states_expiresAt_idx
```

---

## 🔧 ACTIONS EFFECTUÉES

### 1. Preflight & Backup
- Backup schema: `/tmp/ph15_backup/schema_backup_20260107_174759.sql` sur 10.0.0.121
- Vérification tables: toutes présentes

### 2. Migration SQL Baseline
- Fichier créé: `keybuzz-infra/docs/sql/PH15_AMAZON_BASELINE_TABLES.sql`
- Migration idempotente avec `CREATE TABLE IF NOT EXISTS`
- Appliquée sur 10.0.0.121 (keybuzz) - backup rétrospectif

### 3. Synchronisation Prisma
```bash
npx prisma migrate resolve --applied "20251220235148_add_oauth_state_table"
```
- Statut: `Database schema is up to date!`

---

## 📦 DONNÉES SEED EXISTANTES

### tenant_test_dev
| Marketplace | Country | Email | Status |
|-------------|---------|-------|--------|
| AMAZON | DE | `amazon.tenant_test_dev.de.97lo14@inbound.keybuzz.io` | VALIDATED |
| AMAZON | FR | `amazon.tenant_test_dev.fr.6v8gqm@inbound.keybuzz.io` | VALIDATED |
| AMAZON | UK | `amazon.tenant_test_dev.uk.2hpmad@inbound.keybuzz.io` | VALIDATED |

### kbz_test
| Marketplace | Country | Email | Status |
|-------------|---------|-------|--------|
| AMAZON | DE | `amazon.kbz_test.de.k9m2de@inbound.keybuzz.io` | VALIDATED |
| AMAZON | FR | `amazon.kbz_test.fr.x7p4fr@inbound.keybuzz.io` | VALIDATED |

### MarketplaceConnections
| ID | Tenant | Type | Status |
|----|--------|------|--------|
| mpc_amazon_tenant_test_dev | tenant_test_dev | AMAZON | CONNECTED |
| cmjecdiqj0000p0fvgljq171d | kbz_test | AMAZON | CONNECTED |

---

## ⚠️ PROBLÈME IDENTIFIÉ : Routes API

### Situation actuelle
- **keybuzz-api** (déployé) : Routes inbound/Amazon **absentes**
- **keybuzz-backend** (non déployé) : Routes Amazon **présentes** dans le code

### Routes manquantes dans keybuzz-api
```
GET  /api/v1/inbound-email/connections
GET  /api/v1/marketplaces/amazon/status  
POST /api/v1/marketplaces/amazon/oauth/start
GET  /api/v1/marketplaces/amazon/oauth/callback
```

### Solution requise (hors scope)
1. **Option A** : Déployer keybuzz-backend comme service distinct
2. **Option B** : Migrer routes Amazon de keybuzz-backend vers keybuzz-api

---

## 📁 FICHIERS CRÉÉS

| Fichier | Description |
|---------|-------------|
| `keybuzz-infra/docs/sql/PH15_AMAZON_BASELINE_TABLES.sql` | Migration SQL baseline |
| `keybuzz-infra/docs/PH15-AMAZON-DB-FOUNDATION-01-REPORT.md` | Ce rapport |

---

## ✅ CHECKLIST VALIDATION

- [x] Tables DB existent sur `keybuzz_backend`
- [x] Enums PostgreSQL créés
- [x] Prisma migrate status: up to date
- [x] Données tenant_test_dev présentes
- [x] Données kbz_test présentes
- [ ] Routes API Amazon accessibles (⚠️ keybuzz-backend non déployé)
- [ ] Admin UI lit données réelles (dépend des routes)

---

## 🔜 PROCHAINES ÉTAPES

1. **Déployer keybuzz-backend** ou migrer ses routes vers keybuzz-api
2. Vérifier que l'Admin UI appelle les bonnes URLs
3. Tester flow OAuth complet end-to-end

---

## 📝 CONCLUSION

Les tables PostgreSQL pour Amazon/Inbound **existaient déjà** dans la DB `keybuzz_backend` (pas `keybuzz`). La confusion venait de la multiplicité des bases de données.

- **DB `keybuzz_backend`** (10.0.0.121/122) : Utilisée par le backend Prisma - tables OK
- **DB `keybuzz`** (10.0.0.121) : DB legacy - tables absentes

Prisma est maintenant synchronisé. Le blocage restant est que les routes Amazon sont dans `keybuzz-backend` qui n'est pas déployé comme service K8s.
