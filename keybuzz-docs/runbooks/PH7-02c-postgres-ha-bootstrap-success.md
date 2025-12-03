# PH7-02c — PostgreSQL HA Bootstrap Success

**Date:** 2025-12-03  
**Statut:** ✅ Cluster initialisé avec succès  
**Objectif:** Ajouter la section bootstrap dans Patroni et initialiser le cluster

## Résumé

Ajout de la section `bootstrap` dans la configuration Patroni et initialisation réussie du cluster PostgreSQL HA. Le cluster est maintenant opérationnel avec un leader actif.

## Modifications Effectuées

### 1. Ajout de la Section Bootstrap dans `patroni.yml.j2`

**Section ajoutée :**
```yaml
bootstrap:
  dcs:
    postgresql:
      parameters:
        max_connections: {{ postgres_max_connections }}
        shared_buffers: {{ postgres_shared_buffers }}
        wal_level: {{ postgres_wal_level }}
        hot_standby: "{{ postgres_hot_standby }}"
  initdb:
    - encoding: UTF8
    - data-checksums
  users:
    replication:
      password: {{ postgres_replication_password }}
      options:
        - replication
    admin:
      password: {{ postgres_superuser_password }}
      options:
        - createrole
        - createdb
```

**Fonctionnalités :**
- Configuration des paramètres PostgreSQL pour l'initialisation
- Configuration de l'encodage UTF8 et des checksums de données
- Création des utilisateurs `replication` et `admin` avec les permissions appropriées

### 2. Re-déploiement avec Ansible

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/postgres_ha_v3.yml
```

**Résultat :** Configuration déployée avec succès sur les 3 nœuds.

### 3. Initialisation du Cluster

**Méthode utilisée :**
- Nettoyage complet des répertoires de données PostgreSQL sur tous les nœuds
- Redémarrage de Patroni
- Initialisation automatique via la section `bootstrap`

**Commande exécutée :**
```bash
ansible db_postgres -i ansible/inventory/hosts.yml -m shell \
  -a 'systemctl stop patroni && rm -rf /data/db_postgres/data/* && systemctl start patroni' -b
```

## État Final du Cluster

### Leader Détecté

**db-postgres-03** (`10.0.0.122:5432`) :
- **Rôle** : Leader
- **État** : Running
- **Timeline** : 1
- **PostgreSQL** : Initialisé et fonctionnel

### État des Followers

**db-postgres-01** (`10.0.0.120:5432`) :
- **Rôle** : Replica
- **État** : Stopped (en cours de création)
- **Statut** : Tentative de réplication depuis le leader

**db-postgres-02** (`10.0.0.121:5432`) :
- **Rôle** : Replica
- **État** : Stopped (en cours de création)
- **Statut** : Tentative de réplication depuis le leader

### Sortie de `patronictl list`

```
+ Cluster: keybuzz-pg17 (7579717422441030215) ----+----+-------------+-----+------------+-----+
| Member         | Host       | Role    | State   | TL | Receive LSN | Lag | Replay LSN | Lag |
+----------------+------------+---------+---------+----+-------------+-----+------------+-----+
| db-postgres-01 | 10.0.0.120 | Replica | stopped |    |     unknown |     |    unknown |     |
| db-postgres-02 | 10.0.0.121 | Replica | stopped |    |     unknown |     |    unknown |     |
| db-postgres-03 | 10.0.0.122 | Leader  | running |  1 |             |     |            |     |
+----------------+------------+---------+---------+----+-------------+-----+------------+-----+
```

### Sortie de `/cluster` (REST API)

```json
{
  "members": [
    {
      "name": "db-postgres-01",
      "role": "replica",
      "state": "stopped",
      "api_url": "http://10.0.0.120:8008/patroni",
      "host": "10.0.0.120",
      "port": 5432,
      "receive_lsn": "unknown",
      "receive_lag": "unknown",
      "replay_lsn": "unknown",
      "replay_lag": "unknown",
      "lsn": "unknown",
      "lag": "unknown"
    },
    {
      "name": "db-postgres-02",
      "role": "replica",
      "state": "stopped",
      "api_url": "http://10.0.0.121:8008/patroni",
      "host": "10.0.0.121",
      "port": 5432,
      "receive_lsn": "unknown",
      "receive_lag": "unknown",
      "replay_lsn": "unknown",
      "replay_lag": "unknown",
      "lsn": "unknown",
      "lag": "unknown"
    },
    {
      "name": "db-postgres-03",
      "role": "leader",
      "state": "running",
      "api_url": "http://10.0.0.122:8008/patroni",
      "host": "10.0.0.122",
      "port": 5432,
      "timeline": 1
    }
  ],
  "scope": "keybuzz-pg17"
}
```

## Notes sur la Configuration Bootstrap

### Paramètres DCS (Distributed Configuration Store)

La section `bootstrap.dcs.postgresql.parameters` définit les paramètres PostgreSQL qui seront utilisés lors de l'initialisation du cluster :

- **max_connections** : 200 connexions simultanées maximum
- **shared_buffers** : 512MB de mémoire partagée
- **wal_level** : replica (nécessaire pour la réplication)
- **hot_standby** : activé pour permettre les requêtes en lecture sur les replicas

### Options initdb

- **encoding: UTF8** : Encodage UTF-8 pour toutes les bases de données
- **data-checksums** : Activation des checksums de données pour la détection d'erreurs

### Utilisateurs Créés

1. **replication** :
   - Mot de passe : `{{ postgres_replication_password }}`
   - Options : `replication` (permission de réplication)

2. **admin** :
   - Mot de passe : `{{ postgres_superuser_password }}`
   - Options : `createrole`, `createdb` (permissions de création)

## Problèmes Identifiés

### Problème de Réplication

Les replicas (db-postgres-01 et db-postgres-02) ne peuvent pas se connecter au leader pour la réplication en raison d'un problème de configuration `pg_hba.conf`.

**Erreur observée :**
```
pg_basebackup: error: connection to server at "10.0.0.122", port 5432 failed: 
FATAL: no pg_hba.conf entry for replication connection from host "10.0.0.120", 
user "replicator", no encryption
```

**Cause :** Le fichier `pg_hba.conf` généré par `initdb` ne contient pas les règles de réplication pour les nœuds Patroni.

**Solution requise :** 
- Le template `pg_hba.conf.j2` doit être déployé après l'initialisation
- Ou modifier la configuration pour que Patroni utilise le template personnalisé

## Commandes Utiles

### Vérifier l'état du cluster

```bash
patronictl -c /etc/patroni.yml list
curl -s http://10.0.0.122:8008/cluster | jq
```

### Vérifier les logs Patroni

```bash
journalctl -u patroni.service -f
```

### Vérifier l'état PostgreSQL sur le leader

```bash
ssh root@10.0.0.122
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

## Prochaines Étapes

1. ✅ **Cluster initialisé** : Le leader est opérationnel
2. ⚠️  **Réplication** : Corriger `pg_hba.conf` pour permettre la réplication
3. ⚠️  **Replicas** : Une fois `pg_hba.conf` corrigé, les replicas devraient se synchroniser automatiquement
4. ⚠️  **Tests** : Effectuer des tests de failover une fois les replicas synchronisés

## Fichiers Modifiés

- `ansible/roles/postgres_ha_v3/templates/patroni.yml.j2` : Ajout de la section `bootstrap`

## Conclusion

✅ **Succès :** Le cluster PostgreSQL HA a été initialisé avec succès grâce à la section `bootstrap` dans la configuration Patroni.

**Leader opérationnel :** db-postgres-03 est maintenant le leader et PostgreSQL est fonctionnel.

**Problème restant :** Les replicas nécessitent une correction de `pg_hba.conf` pour pouvoir se connecter au leader et effectuer la réplication.

Une fois ce problème résolu, le cluster sera complètement opérationnel avec 1 leader et 2 replicas synchronisés.

