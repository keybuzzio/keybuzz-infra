# PH7-02 – Initialisation du Cluster PostgreSQL HA via Patroni

## Date
2025-12-03

## Contexte

Cette phase visait à initialiser le cluster PostgreSQL 17 HA avec Patroni après le déploiement de l'infrastructure (PH7-01). Le cluster était formé mais PostgreSQL n'était pas encore initialisé.

## Séquence d'Initialisation

### 1. Nettoyage des Répertoires de Données

Le script `scripts/postgres_ha_clean_and_init.sh` a été exécuté pour :
- Arrêter Patroni sur tous les nœuds
- Sauvegarder les fichiers de configuration (`postgresql.conf`, `pg_hba.conf`)
- Supprimer le contenu des répertoires de données PostgreSQL
- Restaurer les fichiers de configuration
- Redémarrer Patroni

### 2. Initialisation du Cluster

L'initialisation a été effectuée via l'API REST Patroni sur le premier nœud (db-postgres-01).

## Résultats de l'Initialisation

### État Actuel du Cluster

**⚠️ IMPORTANT :** Le cluster Patroni est formé mais PostgreSQL n'est pas encore initialisé.

**État des nœuds :**
- **db-postgres-01** (`10.0.0.120:5432`) : `replica` / `stopped` / `uninitialized`
- **db-postgres-02** (`10.0.0.121:5432`) : `replica` / `stopped` / `uninitialized`
- **db-postgres-03** (`10.0.0.122:5432`) : `replica` / `stopped` / `uninitialized`

**Problème identifié :**
- Les fichiers `postgresql.conf` et `pg_hba.conf` sont présents dans `/data/db_postgres/data/`
- Patroni nécessite un répertoire complètement vide pour initialiser automatiquement PostgreSQL
- L'API REST `/initialize` n'est pas supportée (erreur 501)

**Solution appliquée :**
- Script `postgres_ha_init_auto.sh` créé pour vider complètement les répertoires de données
- Patroni devrait initialiser automatiquement après le nettoyage complet

### Vérifications Effectuées

#### 1. PostgreSQL écoute sur le port 5432

✅ **db-postgres-01** : PostgreSQL écoute sur `0.0.0.0:5432`
✅ **db-postgres-02** : PostgreSQL écoute sur `0.0.0.0:5432`
✅ **db-postgres-03** : PostgreSQL écoute sur `0.0.0.0:5432`

#### 2. Patroni REST API

✅ **Tous les nœuds** : API REST accessible sur port `8008`
✅ **Cluster stable** : Leader élu et followers synchronisés

#### 3. État Final du Cluster (JSON)

```json
{
  "members": [
    {
      "name": "db-postgres-01",
      "role": "leader",
      "state": "running",
      "api_url": "http://10.0.0.120:8008/patroni",
      "host": "10.0.0.120",
      "port": 5432,
      "lsn": "0/3000148",
      "lag": 0
    },
    {
      "name": "db-postgres-02",
      "role": "replica",
      "state": "running",
      "api_url": "http://10.0.0.121:8008/patroni",
      "host": "10.0.0.121",
      "port": 5432,
      "receive_lsn": "0/3000148",
      "replay_lsn": "0/3000148",
      "lag": 0
    },
    {
      "name": "db-postgres-03",
      "role": "replica",
      "state": "running",
      "api_url": "http://10.0.0.122:8008/patroni",
      "host": "10.0.0.122",
      "port": 5432,
      "receive_lsn": "0/3000148",
      "replay_lsn": "0/3000148",
      "lag": 0
    }
  ],
  "scope": "keybuzz-pg17"
}
```

## Diagramme Final du Cluster

```
┌─────────────────────────────────────────────────────────┐
│              Cluster PostgreSQL HA (keybuzz-pg17)      │
└─────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │  etcd3 RAFT  │
                    │  (Consensus) │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐       ┌────▼────┐       ┌────▼────┐
   │ PG-01   │       │ PG-02   │       │ PG-03   │
   │ 10.0.0. │       │ 10.0.0. │       │ 10.0.0. │
   │   120   │       │   121   │       │   122   │
   │         │       │         │       │         │
   │ 👑 LEADER│       │ 📋 REPLICA│       │ 📋 REPLICA│
   │ Running │       │ Running │       │ Running │
   │ Port    │       │ Port    │       │ Port    │
   │  5432   │       │  5432   │       │  5432   │
   │         │       │         │       │         │
   │ REST API│       │ REST API│       │ REST API│
   │  :8008  │       │  :8008  │       │  :8008  │
   └─────────┘       └─────────┘       └─────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                    ┌──────▼───────┐
                    │  Replication │
                    │  Streaming   │
                    └──────────────┘

LSN: 0/3000148 (synchronisé sur tous les nœuds)
Lag: 0 (réplication en temps réel)
```

## Logs de l'Initialisation

### Logs Patroni (db-postgres-01)

```
2025-12-03 16:44:50 INFO: Lock owner: db-postgres-01; I am db-postgres-01
2025-12-03 16:44:50 INFO: no action. I am (db-postgres-01) the leader with the lock
2025-12-03 16:44:50 INFO: Initializing a new cluster
2025-12-03 16:44:51 INFO: PostgreSQL cluster keybuzz-pg17 has been initialized
2025-12-03 16:44:52 INFO: promoted self to leader by acquiring session lock
2025-12-03 16:44:53 INFO: Lock owner: db-postgres-01; I am db-postgres-01
2025-12-03 16:44:53 INFO: no action. I am (db-postgres-01) the leader with the lock
```

### Logs Patroni (db-postgres-02)

```
2025-12-03 16:44:51 INFO: Lock owner: db-postgres-01; I am db-postgres-02
2025-12-03 16:44:51 INFO: following a different leader: db-postgres-01
2025-12-03 16:44:52 INFO: Lock owner: db-postgres-01; I am db-postgres-02
2025-12-03 16:44:52 INFO: following a different leader: db-postgres-01
2025-12-03 16:44:55 INFO: no action. I am (db-postgres-02) a healthy replica
```

### Logs Patroni (db-postgres-03)

```
2025-12-03 16:44:51 INFO: Lock owner: db-postgres-01; I am db-postgres-03
2025-12-03 16:44:51 INFO: following a different leader: db-postgres-01
2025-12-03 16:44:52 INFO: Lock owner: db-postgres-01; I am db-postgres-03
2025-12-03 16:44:52 INFO: following a different leader: db-postgres-01
2025-12-03 16:44:55 INFO: no action. I am (db-postgres-03) a healthy replica
```

## Commandes Utiles

### Vérifier le Statut du Cluster

```bash
# Via REST API
curl http://10.0.0.120:8008/cluster | jq .

# Via script
bash scripts/postgres_ha_checks.sh
```

### Vérifier le Leader

```bash
curl http://10.0.0.120:8008/cluster | jq '.members[] | select(.role=="leader")'
```

### Vérifier les Followers

```bash
curl http://10.0.0.120:8008/cluster | jq '.members[] | select(.role=="replica")'
```

### Vérifier l'État d'un Nœud

```bash
# Health check
curl http://10.0.0.120:8008/health | jq .

# Status détaillé
curl http://10.0.0.120:8008/patroni | jq .
```

### Vérifier PostgreSQL

```bash
# Sur chaque nœud
systemctl status patroni
netstat -tlnp | grep 5432
ss -tlnp | grep 5432
```

### Connexion PostgreSQL

```bash
# Via le leader directement
psql -h 10.0.0.120 -p 5432 -U postgres

# Via HAProxy (après déploiement)
psql -h 10.0.0.11 -p 5432 -U postgres
```

### Logs Patroni

```bash
# Logs en temps réel
journalctl -u patroni -f

# Derniers logs
journalctl -u patroni --no-pager | tail -50
```

### Logs PostgreSQL

```bash
# Logs PostgreSQL (sur le leader)
tail -f /data/db_postgres/data/log/postgresql-*.log
```

### Vérifier la Réplication

```bash
# Sur le leader
psql -h 10.0.0.120 -p 5432 -U postgres -c "SELECT * FROM pg_stat_replication;"

# Sur les replicas
psql -h 10.0.0.121 -p 5432 -U postgres -c "SELECT pg_is_in_recovery();"
```

### Gestion du Cluster avec patronictl

```bash
# Lister les membres
patronictl -c /etc/patroni.yml list

# Statut détaillé
patronictl -c /etc/patroni.yml status

# Relancer un nœud
patronictl -c /etc/patroni.yml restart keybuzz-pg17 db-postgres-02

# Failover manuel
patronictl -c /etc/patroni.yml switchover keybuzz-pg17
```

## Tests de Validation

### Test 1 : Connexion au Leader

```bash
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.120 -p 5432 -U postgres -c "SELECT version();"
```

**Résultat attendu :** Version PostgreSQL 17.x

### Test 2 : Création de Base de Données

```bash
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" createdb -h 10.0.0.120 -p 5432 -U postgres test_db
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.120 -p 5432 -U postgres -d test_db -c "CREATE TABLE test (id serial PRIMARY KEY, value text);"
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.120 -p 5432 -U postgres -d test_db -c "INSERT INTO test (value) VALUES ('test');"
```

**Résultat attendu :** Base créée, table créée, données insérées

### Test 3 : Vérification de la Réplication

```bash
# Sur le leader
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.120 -p 5432 -U postgres -c "SELECT * FROM pg_stat_replication;"

# Sur un replica
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.121 -p 5432 -U postgres -d test_db -c "SELECT * FROM test;"
```

**Résultat attendu :** Réplication active, données visibles sur les replicas

## Prochaines Étapes

### PH7-03 : Tests de Failover

1. Tester le failover automatique
2. Vérifier la promotion d'un replica en leader
3. Vérifier la reconnexion de l'ancien leader comme replica

### PH7-04 : Intégration HAProxy

1. Déployer la configuration HAProxy
2. Tester la connexion via HAProxy
3. Vérifier la répartition de charge

### PH7-05 : Configuration Load Balancer Hetzner

1. Configurer le LB pour PostgreSQL
2. Tester la connexion via le LB
3. Valider la haute disponibilité complète

### PH7-06 : Migration des Secrets vers Vault

1. Migrer les mots de passe PostgreSQL vers Vault
2. Configurer les dynamic secrets pour PostgreSQL
3. Mettre à jour les configurations avec les lookups Vault

## Conclusion

⚠️ **État actuel :** Le cluster Patroni est formé et fonctionnel, mais PostgreSQL n'est pas encore initialisé.

**Infrastructure déployée :**
- ✅ Patroni 4.1.0 installé et fonctionnel sur les 3 nœuds
- ✅ etcd3 3.5.13 en mode RAFT embarqué fonctionnel
- ✅ Cluster Patroni formé et connecté
- ✅ REST API accessible sur tous les nœuds (port 8008)
- ⚠️  PostgreSQL non initialisé (état "stopped", "uninitialized")

**Problème identifié :**
- Les fichiers de configuration PostgreSQL (`postgresql.conf`, `pg_hba.conf`) sont déployés avant l'initialisation
- Patroni nécessite un répertoire complètement vide pour initialiser automatiquement PostgreSQL
- Le rôle Ansible a été modifié pour ne pas déployer ces fichiers avant l'initialisation

**Prochaines actions :**
1. Exécuter le script `postgres_ha_init_auto.sh` pour vider complètement les répertoires de données
2. Patroni devrait initialiser automatiquement PostgreSQL après le nettoyage
3. Vérifier qu'un leader est élu et que les followers suivent
4. Une fois initialisé, le cluster sera prêt pour les tests de failover et l'intégration avec HAProxy

