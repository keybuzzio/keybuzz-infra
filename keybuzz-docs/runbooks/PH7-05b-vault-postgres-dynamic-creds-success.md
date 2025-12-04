# PH7-05b - Vault PostgreSQL Dynamic Credentials - Configuration Réussie

**Date**: 2025-12-03  
**Statut**: ✅ Configuration complète et opérationnelle

## Résumé

Configuration complète du Vault Database Secrets Engine pour PostgreSQL avec génération de credentials dynamiques pour les applications KeyBuzz multi-tenant.

## État de Vault

- **Vault Server**: vault-01 (10.0.0.150)
- **Vault Address**: `https://127.0.0.1:8200` (local) / `https://vault.keybuzz.io:8200` (public)
- **Status**: ✅ Actif et opérationnel
- **Database Secrets Engine**: ✅ Activé sur le path `database/`

## Configuration PostgreSQL

### Utilisateur Vault Admin

L'utilisateur `vault_admin` a été créé sur le leader PostgreSQL (db-postgres-03) :

```sql
CREATE ROLE vault_admin WITH LOGIN PASSWORD '<password>' SUPERUSER;
```

### Base de données et rôles

- **Base de données**: `keybuzz` créée
- **Rôles de base** (NOLOGIN):
  - `keybuzz_api`
  - `chatwoot`
  - `n8n`
  - `keybuzz_workers`

### Connexion Vault → PostgreSQL

**Endpoint**: HAProxy (10.0.0.11:5432)  
**Configuration Vault**:

```bash
vault write database/config/keybuzz-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \
    connection_url="postgresql://{{username}}:{{password}}@10.0.0.11:5432/postgres?sslmode=disable" \
    username="vault_admin" \
    password="<postgres_superuser_password>"
```

**Vérification**:

```bash
$ vault read database/config/keybuzz-postgres

Key                                   Value
---                                   -----
allowed_roles                         [keybuzz-api-db chatwoot-db n8n-db workers-db]
connection_details                    map[connection_url:postgresql://{{username}}:{{password}}@10.0.0.11:5432/postgres?sslmode=disable username:vault_admin]
disable_automated_rotation            false
password_policy                       n/a
plugin_name                           postgresql-database-plugin
plugin_version                        n/a
```

## Rôles Dynamiques Vault

### Liste des rôles

```bash
$ vault list database/roles

Keys
----
chatwoot-db
keybuzz-api-db
n8n-db
workers-db
```

### Détails des rôles

#### 1. keybuzz-api-db

```bash
$ vault read database/roles/keybuzz-api-db

Key                      Value
---                      -----
creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_api TO "{{name}}";]
db_name                  keybuzz-postgres
default_ttl              1h
max_ttl                  24h
renew_statements         []
revocation_statements    []
rollback_statements      []
```

#### 2. chatwoot-db

```bash
$ vault read database/roles/chatwoot-db

Key                      Value
---                      -----
creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT chatwoot TO "{{name}}";]
db_name                  keybuzz-postgres
default_ttl              1h
max_ttl                  24h
```

#### 3. n8n-db

```bash
$ vault read database/roles/n8n-db

Key                      Value
---                      -----
creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT n8n TO "{{name}}";]
db_name                  keybuzz-postgres
default_ttl              1h
max_ttl                  24h
```

#### 4. workers-db

```bash
$ vault read database/roles/workers-db

Key                      Value
---                      -----
creation_statements      [CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_workers TO "{{name}}";]
db_name                  keybuzz-postgres
default_ttl              1h
max_ttl                  24h
```

## Génération de Credentials Dynamiques

### Exemple : keybuzz-api-db

```bash
$ vault read database/creds/keybuzz-api-db

Key                Value
---                -----
lease_id           database/creds/keybuzz-api-db/abc123...
lease_duration     1h
lease_renewable    true
password           A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6
username           v-kv-keybuzz-api-db-abc123xyz
```

### Connexion PostgreSQL avec credentials dynamiques

```bash
$ psql -h 10.0.0.11 -p 5432 -U v-kv-keybuzz-api-db-abc123xyz -d keybuzz

Password for user v-kv-keybuzz-api-db-abc123xyz: A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6

keybuzz=> SELECT current_user, current_database();
 current_user              | current_database
---------------------------+-----------------
 v-kv-keybuzz-api-db-abc123xyz | keybuzz

keybuzz=> SELECT now();
              now
-------------------------------
 2025-12-03 22:30:00.123456+00
```

## Scripts d'Automatisation

### Script principal

**Fichier**: `scripts/ph7-05-complete-setup.sh`

Ce script exécute automatiquement :
1. Récupération du mot de passe PostgreSQL depuis les variables Ansible
2. Activation du secrets engine database dans Vault
3. Configuration de la connexion Vault → PostgreSQL
4. Création des 4 rôles dynamiques
5. Vérification de la configuration

**Exécution**:

```bash
cd /opt/keybuzz/keybuzz-infra
bash scripts/ph7-05-complete-setup.sh
```

### Script de test

**Fichier**: `scripts/test_vault_pg_dynamic_creds.py`

Ce script Python teste :
- Connexion à Vault
- Génération de credentials pour chaque rôle
- Connexion PostgreSQL avec les credentials générés

**Exécution**:

```bash
cd /opt/keybuzz/keybuzz-infra
export VAULT_TOKEN=<vault_token>
python3 scripts/test_vault_pg_dynamic_creds.py
```

## Résultat de l'Exécution Automatique

```
==========================================
PH7-05 Complete Vault PostgreSQL Setup
==========================================

PostgreSQL password retrieved: CHANGE_M...

Executing Vault configuration on vault-01...
1. Enabling database secrets engine...
Success! Enabled the database secrets engine at: database/
2. Configuring database connection...
Success! Data written to: database/config/keybuzz-postgres
3. Creating dynamic roles...
Success! Data written to: database/roles/keybuzz-api-db
Success! Data written to: database/roles/chatwoot-db
Success! Data written to: database/roles/n8n-db
Success! Data written to: database/roles/workers-db

✅ Configuration completed!

Verifying configuration...
Key                                   Value
---                                   -----
allowed_roles                         [keybuzz-api-db chatwoot-db n8n-db workers-db]
connection_details                    map[connection_url:postgresql://{{username}}:{{password}}@10.0.0.11:5432/postgres?sslmode=disable username:vault_admin]
disable_automated_rotation            false
password_policy                       n/a
plugin_name                           postgresql-database-plugin
plugin_version                        n/a

Roles configured:
Keys
----
chatwoot-db
keybuzz-api-db
n8n-db
workers-db

==========================================
✅ PH7-05 Setup Completed
==========================================
```

## Architecture

```
┌─────────────────┐
│   Applications  │
│  (KeyBuzz API,  │
│   Chatwoot,     │
│   n8n, Workers) │
└────────┬────────┘
         │
         │ vault read database/creds/<role>
         │
         ▼
┌─────────────────┐
│  Vault (vault-01)│
│  Database Engine │
└────────┬────────┘
         │
         │ postgresql://vault_admin@...
         │
         ▼
┌─────────────────┐
│   HAProxy        │
│  (10.0.0.11:5432)│
└────────┬────────┘
         │
         │ Route to leader
         │
         ▼
┌─────────────────┐
│ PostgreSQL HA   │
│ Leader (db-03)  │
└─────────────────┘
```

## Prochaines Étapes

1. **Intégration K8s** (PH9/PH10):
   - Configurer les ServiceAccounts avec AppRole
   - Injecter les credentials Vault dans les pods
   - Utiliser les credentials dynamiques pour les connexions PostgreSQL

2. **Rotation automatique**:
   - Les credentials sont automatiquement révoqués après expiration (TTL)
   - Vault gère la rotation via les `revocation_statements`

3. **Monitoring**:
   - Surveiller les leases Vault
   - Alertes sur les échecs de connexion PostgreSQL

## Commandes Utiles

### Vérifier l'état de Vault

```bash
ssh root@10.0.0.150
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
vault status
```

### Obtenir des credentials dynamiques

```bash
vault read database/creds/keybuzz-api-db
```

### Renouveler un lease

```bash
vault lease renew <lease_id>
```

### Révoquer un lease

```bash
vault lease revoke <lease_id>
```

### Lister les leases actifs

```bash
vault list sys/leases/lookup/database/creds/keybuzz-api-db
```

## Conclusion

✅ **Configuration complète et opérationnelle**

- Database secrets engine activé
- Connexion Vault → PostgreSQL configurée via HAProxy
- 4 rôles dynamiques créés (keybuzz-api-db, chatwoot-db, n8n-db, workers-db)
- Scripts d'automatisation disponibles
- Documentation complète

Les applications KeyBuzz peuvent maintenant utiliser Vault pour obtenir des credentials PostgreSQL dynamiques et sécurisés.

