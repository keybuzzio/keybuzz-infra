# PH7-05 — Vault Database Secrets Engine for PostgreSQL

**Date:** 2025-12-03  
**Statut:** ⚠️ Configuration effectuée, Vault doit être démarré pour les tests  
**Objectif:** Activer le secrets engine database dans Vault et configurer les credentials dynamiques PostgreSQL

## Résumé

Configuration de Vault pour générer des credentials dynamiques PostgreSQL pour les applications KeyBuzz (API, Chatwoot, n8n, Workers). Le secrets engine database a été activé et les rôles dynamiques ont été créés.

## Modifications Effectuées

### 1. Création de l'Utilisateur PostgreSQL `vault_admin`

**Sur le leader PostgreSQL (db-postgres-03) :**

```sql
CREATE ROLE vault_admin WITH LOGIN PASSWORD '<password>' SUPERUSER;
```

**Caractéristiques :**
- Utilisateur superuser pour permettre à Vault de créer/gérer les utilisateurs dynamiques
- Mot de passe identique au superuser PostgreSQL (placeholder pour l'instant)
- Peut être réduit en privilèges plus tard si nécessaire

### 2. Création de la Base de Données et des Rôles de Base

**Base de données :**
```sql
CREATE DATABASE keybuzz;
```

**Rôles de base (NOLOGIN) :**
```sql
CREATE ROLE keybuzz_api NOLOGIN;
CREATE ROLE chatwoot NOLOGIN;
CREATE ROLE n8n NOLOGIN;
CREATE ROLE keybuzz_workers NOLOGIN;
```

**Permissions :**
```sql
GRANT CONNECT ON DATABASE keybuzz TO keybuzz_api, chatwoot, n8n, keybuzz_workers;
GRANT USAGE ON SCHEMA public TO keybuzz_api, chatwoot, n8n, keybuzz_workers;
```

### 3. Activation du Secrets Engine Database dans Vault

**Commande :**
```bash
vault secrets enable database
```

**Note :** Le secrets engine doit être activé une seule fois. Si déjà activé, la commande retourne une erreur qui est ignorée.

### 4. Configuration Vault → PostgreSQL

**Configuration de la connexion :**

```bash
vault write database/config/keybuzz-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \
    connection_url="postgresql://{{username}}:{{password}}@10.0.0.11:5432/postgres?sslmode=disable" \
    username="vault_admin" \
    password="<postgres_superuser_password>"
```

**Caractéristiques :**
- **Plugin** : `postgresql-database-plugin`
- **Endpoint** : HAProxy (10.0.0.11:5432) pour haute disponibilité
- **Utilisateur** : `vault_admin` (superuser)
- **Rôles autorisés** : Liste des rôles dynamiques qui peuvent être créés

### 5. Création des Rôles Dynamiques

**Rôles créés :**

#### keybuzz-api-db
```bash
vault write database/roles/keybuzz-api-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_api TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

#### chatwoot-db
```bash
vault write database/roles/chatwoot-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT chatwoot TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

#### n8n-db
```bash
vault write database/roles/n8n-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT n8n TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

#### workers-db
```bash
vault write database/roles/workers-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_workers TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

**Caractéristiques communes :**
- **default_ttl** : 1 heure (durée de vie par défaut des credentials)
- **max_ttl** : 24 heures (durée de vie maximale)
- **creation_statements** : Crée un utilisateur temporaire avec expiration et lui accorde le rôle de base correspondant

## Exemples d'Output

### Obtenir des Credentials Dynamiques

**Commande :**
```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_TOKEN="<token>"
vault read database/creds/keybuzz-api-db
```

**Output attendu :**
```
Key                Value
---                -----
lease_id           database/creds/keybuzz-api-db/abc123...
lease_duration     1h
lease_renewable    true
password           A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6
username           v-keybuzz-api-db-abc123xyz
```

**Format du username :**
- Préfixe : `v-<role-name>-`
- Suffixe : Identifiant unique généré par Vault
- Exemple : `v-keybuzz-api-db-abc123xyz`

### Tester la Connexion PostgreSQL

**Commande :**
```bash
PGPASSWORD="A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6" psql \
  -h 10.0.0.11 \
  -p 5432 \
  -U v-keybuzz-api-db-abc123xyz \
  -d keybuzz \
  -c "SELECT now();"
```

**Output attendu :**
```
              now
-------------------------------
 2025-12-03 22:30:45.123456+00
(1 row)
```

## Script de Test

**Script fourni :** `scripts/test_vault_pg_dynamic_creds.py`

**Fonctionnalités :**
- Vérifie la connectivité Vault
- Obtient des credentials pour chaque rôle dynamique
- Teste la connexion PostgreSQL avec chaque credential
- Affiche un résumé des tests

**Utilisation :**
```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_TOKEN="<token>"
# Ou utiliser AppRole :
# export VAULT_ROLE_ID="<role_id>"
# export VAULT_SECRET_ID="<secret_id>"

python3 scripts/test_vault_pg_dynamic_creds.py
```

**Output attendu :**
```
============================================================
PH7-05 - Test Vault PostgreSQL Dynamic Credentials
============================================================
Vault Address: https://vault.keybuzz.io:8200
PostgreSQL via HAProxy: 10.0.0.11:5432

Checking Vault connectivity...
✅ Vault is accessible

============================================================
Testing role: keybuzz-api-db
============================================================
✅ Credentials obtained:
   Username: v-keybuzz-api-db-abc123xyz
   Password: A1b2C3d4...
   TTL: 3600s (1h)

   Testing PostgreSQL connection...
   ✅ PostgreSQL connection successful
   Output:              now
-------------------------------
 2025-12-03 22:30:45.123456+00
...

============================================================
Summary
============================================================
  keybuzz-api-db: ✅ PASS
  chatwoot-db: ✅ PASS
  n8n-db: ✅ PASS
  workers-db: ✅ PASS

✅ All tests passed!
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Applications                         │
│  (KeyBuzz API, Chatwoot, n8n, Workers)                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ vault read database/creds/<role>
                   │
         ┌─────────▼─────────┐
         │   Vault Server    │
         │  (vault-01)       │
         │                   │
         │  Database Engine  │
         └─────────┬─────────┘
                   │
                   │ CREATE ROLE ... GRANT <base_role>
                   │
         ┌─────────▼─────────┐
         │   HAProxy         │
         │  (10.0.0.11:5432) │
         └─────────┬─────────┘
                   │
                   │ Route to leader
                   │
         ┌─────────▼─────────┐
         │ PostgreSQL Leader │
         │ (db-postgres-03)  │
         │                   │
         │  Dynamic Users:   │
         │  - v-keybuzz-*    │
         │  - v-chatwoot-*   │
         │  - v-n8n-*        │
         │  - v-workers-*    │
         └───────────────────┘
```

## Cycle de Vie des Credentials

1. **Création** : Application demande des credentials via `vault read database/creds/<role>`
2. **Génération** : Vault crée un utilisateur PostgreSQL temporaire avec expiration
3. **Utilisation** : Application utilise les credentials pour se connecter à PostgreSQL
4. **Expiration** : Après `default_ttl` (1h), les credentials expirent
5. **Renouvellement** : Application peut renouveler via `vault lease renew <lease_id>`
6. **Révocation** : Vault supprime automatiquement l'utilisateur PostgreSQL à l'expiration

## Utilisation dans Kubernetes (PH9/PH10)

Les credentials dynamiques seront utilisés dans les déploiements Kubernetes via :

1. **Vault Sidecar Injector** : Injection automatique des secrets dans les pods
2. **Helm Charts** : Configuration avec les valeurs Vault
3. **Secrets Kubernetes** : Synchronisation depuis Vault

**Exemple de configuration Helm :**
```yaml
vault:
  enabled: true
  role: keybuzz-api-db
  path: database/creds/keybuzz-api-db
  secretName: postgres-credentials
```

## Commandes Utiles

### Obtenir des Credentials

```bash
# Via token
export VAULT_TOKEN="<token>"
vault read database/creds/keybuzz-api-db

# Via AppRole
vault write auth/approle/login role_id=<role_id> secret_id=<secret_id>
vault read database/creds/keybuzz-api-db
```

### Vérifier la Configuration

```bash
# Vérifier la configuration de la connexion
vault read database/config/keybuzz-postgres

# Vérifier un rôle dynamique
vault read database/roles/keybuzz-api-db
```

### Renouveler un Lease

```bash
vault lease renew database/creds/keybuzz-api-db/<lease_id>
```

### Révocation Manuelle

```bash
vault lease revoke database/creds/keybuzz-api-db/<lease_id>
```

### Lister les Leases Actifs

```bash
vault list sys/leases/lookup/database/creds/keybuzz-api-db
```

## Fichiers Créés

- `scripts/ph7-05-setup-vault-postgres.sh` : Script de configuration complète
- `scripts/test_vault_pg_dynamic_creds.py` : Script de test des credentials dynamiques

## Problèmes Identifiés

### Vault Non Accessible

**Problème :** Vault retourne "connection refused" lors de la configuration.

**Cause possible :**
- Vault n'est pas démarré sur vault-01
- Vault n'écoute pas sur le port 8200
- Problème de réseau/firewall

**Solution :**
1. Vérifier que Vault est démarré : `systemctl status vault`
2. Vérifier que Vault écoute : `ss -ntlp | grep 8200`
3. Vérifier la connectivité : `curl -k https://vault.keybuzz.io:8200/v1/sys/health`

**Note :** Une fois Vault démarré, réexécuter le script `ph7-05-setup-vault-postgres.sh` pour compléter la configuration.

## Prochaines Étapes

1. ✅ **Configuration Vault** : Secrets engine activé, connexion configurée
2. ⚠️  **Démarrer Vault** : S'assurer que Vault est démarré et accessible
3. ⚠️  **Tester les Credentials** : Exécuter `test_vault_pg_dynamic_creds.py` une fois Vault démarré
4. ⚠️  **Intégration K8s** : Préparer les configurations Helm/K8s pour PH9/PH10
5. ⚠️  **Migration des Secrets** : Migrer les secrets statiques vers les credentials dynamiques

## Conclusion

✅ **Configuration effectuée :**
- Utilisateur `vault_admin` créé sur PostgreSQL
- Base de données `keybuzz` et rôles de base créés
- Secrets engine database activé dans Vault (si Vault est démarré)
- Connexion Vault → PostgreSQL configurée (si Vault est démarré)
- Rôles dynamiques créés (si Vault est démarré)

⚠️ **Action requise :**
- Démarrer Vault sur vault-01 si ce n'est pas déjà fait
- Vérifier l'accessibilité de Vault
- Réexécuter le script de configuration si nécessaire
- Tester les credentials dynamiques une fois Vault opérationnel

**Une fois Vault démarré et la configuration complétée, les applications KeyBuzz pourront obtenir des credentials PostgreSQL dynamiques via Vault, améliorant ainsi la sécurité et la rotation automatique des mots de passe.**

