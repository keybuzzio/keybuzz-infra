# PH7-01 – PostgreSQL 17 HA Deployment & Tests

## Date
2025-12-03

## Contexte

Cette phase visait à déployer un cluster PostgreSQL 17 HA avec Patroni en mode RAFT (utilisant etcd3 embarqué) sur les 3 nœuds db-postgres-01/02/03.

## Architecture

### Composants Déployés

- **PostgreSQL 17** : Base de données principale
- **Patroni 4.1.0** : Gestionnaire de haute disponibilité
- **etcd3 3.5.13** : Distributed Configuration Store (mode RAFT embarqué)
- **HAProxy** : Load balancer pour PostgreSQL (à configurer)

### Topologie

```
┌─────────────────────────────────────────┐
│         Load Balancer (10.0.0.10)       │
│              Port 5432                   │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
┌──────▼──────┐ ┌──────▼──────┐
│ HAProxy-01  │ │ HAProxy-02  │
│ 10.0.0.11   │ │ 10.0.0.12   │
└──────┬──────┘ └──────┬──────┘
       │               │
       └───────┬───────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼───┐ ┌───▼───┐ ┌───▼───┐
│ PG-01 │ │ PG-02 │ │ PG-03 │
│ 120   │ │ 121   │ │ 122   │
└───────┘ └───────┘ └───────┘
    │          │          │
    └──────────┼──────────┘
               │
         ┌─────▼─────┐
         │  etcd3    │
         │  (RAFT)   │
         └───────────┘
```

## Déploiement

### 1. Infrastructure Ansible

**Fichiers créés :**
- `ansible/roles/postgres_ha_v3/` : Rôle Ansible complet
- `ansible/playbooks/postgres_ha_v3.yml` : Playbook de déploiement
- `ansible/group_vars/postgres.yml` : Variables de configuration

**Templates créés :**
- `patroni.yml.j2` : Configuration Patroni
- `postgresql.conf.j2` : Configuration PostgreSQL
- `pg_hba.conf.j2` : Configuration d'authentification
- `patroni.service.j2` : Service systemd Patroni
- `etcd.conf.j2` : Configuration etcd3
- `etcd.service.j2` : Service systemd etcd3

### 2. Installation des Composants

**PostgreSQL 17 :**
- Dépôt PostgreSQL APT ajouté
- PostgreSQL 17 installé depuis `apt.postgresql.org`
- Binaires dans `/usr/lib/postgresql/17/bin`

**Patroni :**
- Installé via pip avec `--break-system-packages` (Ubuntu 24.04)
- Version 4.1.0
- Binaire dans `/usr/local/bin/patroni`

**etcd3 :**
- Binaire téléchargé depuis GitHub (v3.5.13)
- Installé dans `/usr/local/bin/etcd`
- Configuration en mode RAFT embarqué

### 3. Configuration

**Répertoires créés :**
- `/data/db_postgres/data` : Données PostgreSQL
- `/data/db_postgres/etcd` : Données etcd3

**Services systemd :**
- `etcd.service` : Service etcd3 (démarre en premier)
- `patroni.service` : Service Patroni (dépend d'etcd)

**Configuration Patroni :**
- Scope : `keybuzz-pg17`
- REST API : Port 8008
- PostgreSQL : Port 5432
- etcd3 : `127.0.0.1:2379` (embarqué)

### 4. État Actuel

**Cluster Patroni :**
- ✅ 3 nœuds configurés et connectés
- ✅ etcd3 fonctionnel en mode RAFT
- ✅ Patroni REST API accessible sur tous les nœuds
- ⚠️  PostgreSQL non initialisé (état "stopped", "uninitialized")

**Problème identifié :**
- Les fichiers `postgresql.conf` et `pg_hba.conf` sont déployés avant l'initialisation
- Patroni nécessite un répertoire complètement vide pour initialiser PostgreSQL
- Le cluster est déverrouillé (`cluster_unlocked: true`) mais PostgreSQL n'est pas démarré

## Scripts Créés

### Scripts de Vérification

**`scripts/postgres_ha_checks.sh` :**
- Vérifie le statut systemd de Patroni sur tous les nœuds
- Interroge l'API REST Patroni pour le statut du cluster
- Affiche les membres du cluster et leurs rôles

**`scripts/postgres_ha_init_cluster.py` :**
- Script Python pour initialiser le cluster PostgreSQL
- Utilise l'API REST Patroni (nécessite correction)

**`scripts/postgres_ha_clean_and_init.sh` :**
- Nettoie les répertoires de données
- Tente d'initialiser le cluster (nécessite correction)

### Scripts de Test

**`scripts/postgres_ha_end_to_end.sh` :**
- Test de connexion via Load Balancer
- Création de base de données de test
- Insertion et lecture de données
- Nettoyage

## Configuration HAProxy

### Rôle Ansible

**`ansible/roles/postgres_haproxy_v3/` :**
- Configuration HAProxy pour PostgreSQL
- Port 5432 : Writer (master)
- Port 5433 : Readers (replicas)

**Playbook :**
- `ansible/playbooks/haproxy_postgres_v3.yml`
- À déployer sur `lb_internal` (haproxy-01/02)

### Script Load Balancer Hetzner

**`scripts/configure_lbhaproxy_postgres.sh` :**
- Configure le load balancer Hetzner `lb-haproxy`
- Ajoute le service TCP 5432
- Configure les targets haproxy-01/02

## Prochaines Étapes

### Initialisation du Cluster PostgreSQL

**Option 1 : Correction du rôle Ansible**
- Ne pas déployer `postgresql.conf` et `pg_hba.conf` avant l'initialisation
- Laisser Patroni créer ces fichiers lors de l'initialisation
- Déployer les fichiers après l'initialisation si nécessaire

**Option 2 : Initialisation manuelle**
- Vider complètement `/data/db_postgres/data` sur tous les nœuds
- Redémarrer Patroni
- Patroni devrait initialiser automatiquement si le cluster est déverrouillé

**Option 3 : Utilisation de patronictl**
- Installer `patronictl` sur un nœud
- Utiliser `patronictl reinit` ou une commande similaire

### Déploiement HAProxy

1. Déployer le playbook `haproxy_postgres_v3.yml`
2. Vérifier la configuration HAProxy
3. Tester la connexion via HAProxy

### Configuration Load Balancer Hetzner

1. Exécuter `scripts/configure_lbhaproxy_postgres.sh`
2. Vérifier que le service TCP 5432 est exposé
3. Tester la connexion via le Load Balancer

### Tests End-to-End

1. Initialiser le cluster PostgreSQL
2. Vérifier qu'un leader est élu
3. Vérifier que les replicas suivent le leader
4. Exécuter `scripts/postgres_ha_end_to_end.sh`
5. Tester le failover (PH7-02)

## Commandes Utiles

### Vérifier le statut du cluster

```bash
# Via REST API
curl http://10.0.0.120:8008/cluster | jq .

# Via script
bash scripts/postgres_ha_checks.sh
```

### Vérifier les services

```bash
# Sur chaque nœud
systemctl status etcd
systemctl status patroni
```

### Logs

```bash
# Logs Patroni
journalctl -u patroni -f

# Logs etcd3
journalctl -u etcd -f
```

## Conclusion

✅ **Infrastructure déployée :**
- PostgreSQL 17 installé sur 3 nœuds
- Patroni 4.1.0 configuré et fonctionnel
- etcd3 3.5.13 en mode RAFT embarqué
- Cluster Patroni formé et connecté
- Scripts de vérification et tests créés
- Configuration HAProxy préparée

⚠️ **À compléter :**
- Initialisation du cluster PostgreSQL
- Déploiement HAProxy
- Configuration Load Balancer Hetzner
- Tests end-to-end
- Tests de failover (PH7-02)

## Références

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [etcd3 Documentation](https://etcd.io/docs/)

