# PH16-API-CONNECTION-RESTORE-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Restauration de la connexion Front ↔ API après découverte que :
1. Le leader PostgreSQL avait changé (failover 10.0.0.121 → 10.0.0.120)
2. Les credentials Vault dynamiques avaient expiré
3. Les secrets K8s pointaient vers un replica en lecture seule

---

## 1. Cause Racine

### PostgreSQL Failover
- **Avant** : Leader = 10.0.0.121, Replicas = 10.0.0.120, 10.0.0.122
- **Après** : Leader = **10.0.0.120**, Replicas = 10.0.0.121, 10.0.0.122

```
+ Cluster: keybuzz-pg17
| Member         | Host       | Role    | State     |
| db-postgres-01 | 10.0.0.120 | Leader  | running   |
| db-postgres-02 | 10.0.0.121 | Replica | running   |
| db-postgres-03 | 10.0.0.122 | Replica | streaming |
```

### Vault Credentials Expirés
Les credentials dynamiques générés par Vault pour keybuzz-api-dev avaient expiré et ESO ne pouvait plus les régénérer car Vault pointait vers un replica (read-only).

---

## 2. Corrections Appliquées

### 2.1 Création d'un utilisateur DB statique pour DEV

```sql
CREATE ROLE keybuzz_api_dev WITH LOGIN PASSWORD 'KeyBuzz_Dev_2026!';
GRANT ALL PRIVILEGES ON DATABASE keybuzz TO keybuzz_api_dev;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_backend TO keybuzz_api_dev;
```

### 2.2 Secret keybuzz-api-postgres (keybuzz-api-dev)

```bash
kubectl -n keybuzz-api-dev create secret generic keybuzz-api-postgres \
  --from-literal=PGHOST=10.0.0.120 \
  --from-literal=PGPORT=5432 \
  --from-literal=PGDATABASE=keybuzz \
  --from-literal=PGUSER=keybuzz_api_dev \
  --from-literal=PGPASSWORD='KeyBuzz_Dev_2026!'
```

### 2.3 Secret keybuzz-backend-db (keybuzz-backend-dev)

```bash
kubectl -n keybuzz-backend-dev create secret generic keybuzz-backend-db \
  --from-literal=PGHOST=10.0.0.120 \
  --from-literal=PGPORT=5432 \
  --from-literal=PGDATABASE=keybuzz_backend \
  --from-literal=PGUSER=keybuzz_api_dev \
  --from-literal=PGPASSWORD='KeyBuzz_Dev_2026!' \
  --from-literal=DATABASE_URL='postgresql://keybuzz_api_dev:KeyBuzz_Dev_2026!@10.0.0.120:5432/keybuzz_backend'
```

### 2.4 Seed de keybuzz_backend

```sql
INSERT INTO "Tenant" (id, slug, name, plan, status) 
VALUES 
  ('kbz-001', 'kbz-001', 'KeyBuzz Demo', 'DEV', 'ACTIVE'),
  ('kbz-002', 'kbz-002', 'KeyBuzz Test', 'DEV', 'ACTIVE');

INSERT INTO "User" (id, email, fullName, role, tenantId, passwordHash)
VALUES 
  ('user_demo', 'demo@keybuzz.io', 'Demo User', 'ADMIN', 'kbz-001', 'dev-no-password'),
  ('user_ludo', 'ludo.gonthier@gmail.com', 'Ludo Gonthier', 'ADMIN', 'kbz-001', 'dev-no-password');
```

---

## 3. Tests E2E

### API Health
```bash
curl -sk https://api-dev.keybuzz.io/health
# {"status":"ok","timestamp":"2026-01-08T00:38:33.910Z","service":"keybuzz-api","version":"1.0.0"}
```

### Tenant Context
```bash
curl -sk -H 'X-User-Email: ludo.gonthier@gmail.com' https://api-dev.keybuzz.io/tenant-context/me
# {"user":{"id":"...","email":"ludo.gonthier@gmail.com","name":"ludo.gonthier"},"tenants":[{"id":"kbz-001",...},{"id":"kbz-002",...}],"currentTenantId":"kbz-001"}
```

### Conversations (API Data)
```bash
curl -sk -H 'X-User-Email: demo@keybuzz.io' 'https://api-dev.keybuzz.io/messages/conversations?tenantId=kbz-001&limit=1'
# [{"id":"conv-001","tenant_id":"kbz-001","subject":"Commande 404 retardée - urgent SVP",...}]
```

### Backend-dev (Amazon Status)
```bash
curl -sk -H 'X-User-Email: demo@keybuzz.io' -H 'X-Tenant-Id: kbz-001' https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
# {"connected":false,"status":"DISCONNECTED",...}
```

---

## 4. Versions

| Service | Version |
|---------|---------|
| keybuzz-api | v0.1.59-dev |
| keybuzz-backend | v0.1.9-dev |
| keybuzz-client | v0.2.38-dev |

---

## 5. Points d'attention

### IA Assistante
L'endpoint `POST /ai/assist` retourne 404 car l'image déployée (v0.1.59-dev) est ancienne. Le code local est v0.1.72-dev. Un rebuild de keybuzz-api est nécessaire pour activer les nouvelles routes IA.

### Vault → ESO
Les credentials dynamiques ESO ne fonctionnent plus car Vault était configuré pour 10.0.0.121 (maintenant replica). Une correction de la configuration Vault est nécessaire pour restaurer les credentials dynamiques.

### Recommandation
Pour la stabilité DEV, utiliser des credentials statiques est acceptable. Pour la production, les credentials dynamiques Vault doivent être restaurés.

---

## 6. Fichiers créés/modifiés

| Chemin | Action |
|--------|--------|
| Secret `keybuzz-api-postgres` | Recréé avec PGHOST=10.0.0.120 |
| Secret `keybuzz-api-postgres-static` | Créé (backup) |
| Secret `keybuzz-backend-db` | Recréé avec PGHOST=10.0.0.120 |
| DB `keybuzz` (10.0.0.120) | Role `keybuzz_api_dev` créé |
| DB `keybuzz_backend` (10.0.0.120) | Tenants/Users seedés |

---

**Fin du rapport PH16-API-CONNECTION-RESTORE-01**
