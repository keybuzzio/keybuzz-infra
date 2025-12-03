# PH5-01 à PH5-03 – RabbitMQ HA Quorum – Déploiement et Tests End-to-End

## Date
2025-12-03

## Contexte

Cette phase visait à déployer un cluster RabbitMQ HA en mode Quorum Queues sur les nœuds `queue-01`, `queue-02` et `queue-03`, puis à exécuter des tests end-to-end pour valider le fonctionnement du cluster.

## Architecture Déployée

```
[queue-01 (10.0.0.126)] <---> [queue-02 (10.0.0.127)] <---> [queue-03 (10.0.0.128)]
         ↑                           ↑                           ↑
    (AMQP 5672, Management 15672, Cluster 25672, EPMD 4369)
```

## Problèmes Rencontrés et Résolutions

### 1. Configuration RabbitMQ invalide (`data_dir` et `quorum_queues.default_quorum_initial_group_size`)

**Problème** : Le template `rabbitmq.conf.j2` contenait des directives invalides :
- `data_dir = /data/rabbitmq` (n'existe pas dans RabbitMQ)
- `quorum_queues.default_quorum_initial_group_size = 3` (directive invalide)

**Erreur** :
```
Error: unable to set data_dir, but there is no setting with that name
Error: unable to set quorum_queues.default_quorum_initial_group_size
BOOT FAILED - Error during startup: {error,failed_to_prepare_configuration}
```

**Résolution** :
- Suppression des lignes invalides dans `rabbitmq.conf.j2`
- Ajout de `RABBITMQ_MNESIA_DIR=/data/rabbitmq` dans `/etc/rabbitmq/rabbitmq-env.conf` via le rôle Ansible
- Script `scripts/fix_rabbitmq_config.py` créé pour corriger les fichiers déjà déployés

### 2. Résolution DNS pour le cluster

**Problème** : Les hostnames `queue-01`, `queue-02`, `queue-03` n'étaient pas résolus entre les nœuds, empêchant la formation du cluster.

**Erreur** :
```
Error: unable to connect to epmd (port 4369) on queue-01: nxdomain (non-existing domain)
```

**Résolution** :
- Script `scripts/fix_rabbitmq_hosts.py` créé pour ajouter les entrées dans `/etc/hosts` sur tous les nœuds :
  ```
  10.0.0.126 queue-01
  10.0.0.127 queue-02
  10.0.0.128 queue-03
  ```

### 3. Cookies Erlang différents entre les nœuds

**Problème** : Les cookies Erlang (`/var/lib/rabbitmq/.erlang.cookie`) étaient différents sur chaque nœud, empêchant la formation du cluster.

**Erreur** :
```
Error: TCP connection succeeded but Erlang distribution failed
suggestion: check if the Erlang cookie is identical for all server nodes
```

**Résolution** :
- Script `scripts/sync_erlang_cookies.py` créé pour synchroniser le cookie de `queue-01` vers `queue-02` et `queue-03`
- Le cookie est copié avec les permissions correctes (`chmod 400`, `chown rabbitmq:rabbitmq`)

### 4. Formation du cluster

**Problème** : Après résolution des problèmes précédents, le cluster n'était pas automatiquement formé.

**Résolution** :
- Script `scripts/check_and_join_rabbitmq_cluster.py` créé pour :
  - Vérifier l'état du cluster
  - Joindre `queue-02` et `queue-03` au cluster de `queue-01` via `rabbitmqctl join_cluster rabbit@queue-01`

## Déploiement Final

### État du Cluster

```bash
$ rabbitmqctl cluster_status

Cluster status of node rabbit@queue-01 ...
Basics
  Cluster name: rabbit@queue-01
  Total CPU cores available cluster-wide: 6

Disk Nodes
  rabbit@queue-01
  rabbit@queue-02
  rabbit@queue-03

Running Nodes
  rabbit@queue-01
  rabbit@queue-02
  rabbit@queue-03

Versions
  rabbit@queue-01: RabbitMQ 3.12.1 on Erlang 25.3.2.8
  rabbit@queue-02: RabbitMQ 3.12.1 on Erlang 25.3.2.8
  rabbit@queue-03: RabbitMQ 3.12.1 on Erlang 25.3.2.8
```

✅ **Cluster formé avec succès : 3 nœuds actifs**

### Services RabbitMQ

- ✅ `queue-01`: `systemctl is-active rabbitmq-server` → `active`
- ✅ `queue-02`: `systemctl is-active rabbitmq-server` → `active`
- ✅ `queue-03`: `systemctl is-active rabbitmq-server` → `active`

## Tests End-to-End

### Script de Test

Un script Python `scripts/test_rabbitmq_on_node.py` a été créé pour tester :
1. ✅ Vérification du cluster (3 nœuds)
2. ✅ Création d'une Quorum Queue
3. ✅ Publication de messages
4. ✅ Vérification de la réplication sur les 3 nœuds
5. ✅ Nettoyage de la queue de test

### Résultats des Tests

```
=== Test RabbitMQ Quorum Queue ===
Host: 10.0.0.126
Queue: kb_test_1764760852

1. Cluster status...
   ✅ 3 nœuds dans le cluster

2. Création queue Quorum 'kb_test_1764760852'...
   ✅ Queue créée

3. Vérification queue...
   ✅ Queue trouvée, type: quorum

4. Publication de 5 messages...
   ✅ Messages publiés

5. Vérification messages...
   ✅ Messages dans la queue

6. Vérification réplication...
   ✅ queue-01: queue présente
   ✅ queue-02: queue présente
   ✅ queue-03: queue présente

7. Nettoyage...
   ✅ Queue supprimée

=== ✅ Tests terminés ===
```

**Résultat** : ✅ **Tous les tests sont passés avec succès**

## Configuration Finale

### Fichiers de Configuration

- `/etc/rabbitmq/rabbitmq.conf` : Configuration principale (ports, cluster formation, utilisateurs)
- `/etc/rabbitmq/rabbitmq-env.conf` : Variables d'environnement (`NODENAME`, `RABBITMQ_MNESIA_DIR`)
- `/etc/rabbitmq/advanced.config` : Configuration avancée (Quorum Queues)
- `/var/lib/rabbitmq/.erlang.cookie` : Cookie Erlang partagé (synchronisé sur les 3 nœuds)
- `/etc/hosts` : Entrées DNS pour résolution des hostnames

### Ports Ouverts

- **5672/TCP** : AMQP (clients RabbitMQ)
- **15672/TCP** : Management UI (HTTP API)
- **25672/TCP** : Communication inter-nœuds (cluster)
- **4369/TCP** : EPMD (Erlang Port Mapper Daemon)

## Scripts Créés

1. `scripts/fix_rabbitmq_config.py` : Correction de la configuration RabbitMQ
2. `scripts/fix_rabbitmq_hosts.py` : Ajout des entrées DNS dans `/etc/hosts`
3. `scripts/sync_erlang_cookies.py` : Synchronisation des cookies Erlang
4. `scripts/check_and_join_rabbitmq_cluster.py` : Formation du cluster
5. `scripts/test_rabbitmq_on_node.py` : Tests end-to-end

## Prochaines Étapes (PH5-04/05)

- **PH5-04** : Tests de failover (arrêt d'un nœud, vérification de la continuité de service)
- **PH5-05** : Intégration HAProxy pour exposer le cluster RabbitMQ via un point d'accès unique

## Conclusion

✅ **PH5-01 (Installation)** : TERMINÉ
✅ **PH5-02 (Cluster Join)** : TERMINÉ
✅ **PH5-03 (Quorum Queues Tests)** : TERMINÉ

Le cluster RabbitMQ HA Quorum est opérationnel avec :
- 3 nœuds actifs
- Quorum Queues fonctionnelles
- Réplication validée sur les 3 nœuds
- Tests end-to-end réussis

