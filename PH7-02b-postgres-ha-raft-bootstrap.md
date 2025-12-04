# PH7-02b — PostgreSQL HA RAFT Bootstrap Fix

**Date:** 2025-12-03  
**Statut:** En cours  
**Objectif:** Corriger le problème "waiting for leader to bootstrap" en basculant Patroni vers le mode RAFT natif

## Résumé

Migration de la configuration Patroni d'etcd3 vers RAFT natif pour résoudre le problème d'initialisation du cluster PostgreSQL HA.

## Modifications Effectuées

### 1. Modification du Template Patroni (`patroni.yml.j2`)

**Avant (etcd3) :**
```yaml
etcd3:
  protocol: http
  host: 127.0.0.1:2379
  allow_reconnect: true
  use_proxies: false
  request_timeout: 10
  lock_ttl: 30
```

**Après (RAFT natif) :**
```yaml
raft:
  data_dir: {{ postgres_data_dir }}/raft
  self_addr: {{ ansible_host }}:5010
  partner_addrs:
{% for host in groups['db_postgres'] if host != inventory_hostname %}
    - {{ hostvars[host].ansible_host }}:5010
{% endfor %}
```

### 2. Installation de `pysyncobj`

Le module RAFT de Patroni nécessite le package Python `pysyncobj` :

```yaml
- name: Install Patroni via pip
  pip:
    name:
      - patroni
      - psycopg2-binary
      - pysyncobj  # Requis pour RAFT
    state: present
    extra_args: --break-system-packages
```

### 3. Déploiement

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/postgres_ha_v3.yml
```

## État Actuel

### Infrastructure

- ✅ **Patroni 4.1.0** : Installé et fonctionnel sur les 3 nœuds
- ✅ **pysyncobj 0.3.14** : Installé sur tous les nœuds
- ✅ **RAFT** : Configuration déployée, répertoires créés
- ✅ **Port 5010** : Écoute sur tous les nœuds
- ⚠️  **PostgreSQL** : Non initialisé (état "stopped", "uninitialized")

### État du Cluster

```json
{
  "members": [
    {
      "name": "db-postgres-01",
      "role": "replica",
      "state": "stopped",
      "api_url": "http://10.0.0.120:8008/patroni",
      "host": "10.0.0.120",
      "port": 5432
    },
    {
      "name": "db-postgres-02",
      "role": "replica",
      "state": "stopped",
      "api_url": "http://10.0.0.121:8008/patroni",
      "host": "10.0.0.121",
      "port": 5432
    },
    {
      "name": "db-postgres-03",
      "role": "replica",
      "state": "stopped",
      "api_url": "http://10.0.0.122:8008/patroni",
      "host": "10.0.0.122",
      "port": 5432
    }
  ],
  "scope": "keybuzz-pg17"
}
```

### Logs Patroni

```
INFO: Lock owner: None; I am db-postgres-01
INFO: waiting for leader to bootstrap
```

**Problème identifié :**
- Le cluster RAFT est formé et fonctionnel
- Les nœuds communiquent via RAFT (fichiers de journal présents dans `/data/db_postgres/raft/`)
- Aucun nœud n'acquiert le lock pour devenir leader et initialiser PostgreSQL
- Le répertoire PostgreSQL (`/data/db_postgres/data/`) est complètement vide

## Actions Effectuées

1. ✅ Modification du template `patroni.yml.j2` pour utiliser RAFT
2. ✅ Installation de `pysyncobj` sur tous les nœuds
3. ✅ Re-déploiement de la configuration avec Ansible
4. ✅ Nettoyage complet des répertoires de données PostgreSQL
5. ✅ Vérification de la connectivité réseau sur le port 5010
6. ⚠️  Tentative d'initialisation automatique (en attente)

## Prochaines Étapes

### Option 1 : Vérifier la connectivité RAFT ✅

**Résultat :** La connectivité réseau est fonctionnelle entre tous les nœuds sur le port 5010.

```bash
# Test effectué sur tous les nœuds
db-postgres-01: Connection to 10.0.0.120/121/122 5010 port [tcp/*] succeeded!
db-postgres-02: Connection to 10.0.0.120/121/122 5010 port [tcp/*] succeeded!
db-postgres-03: Connection to 10.0.0.120/121/122 5010 port [tcp/*] succeeded!
```

**Conclusion :** Le problème n'est pas lié à la connectivité réseau.

### Option 2 : Forcer l'initialisation via API REST

Essayer d'initialiser manuellement via l'API REST (si supporté) :

```bash
curl -X POST http://10.0.0.120:8008/initialize \
  -H 'Content-Type: application/json' \
  -d '{"initdb": []}'
```

### Option 3 : Utiliser `patronictl`

Vérifier les commandes disponibles :

```bash
patronictl -c /etc/patroni.yml --help
```

### Option 4 : Vérifier la configuration RAFT

Vérifier que la configuration RAFT est correcte et que tous les nœuds sont listés dans `partner_addrs`.

## Fichiers Modifiés

- `ansible/roles/postgres_ha_v3/templates/patroni.yml.j2` : Migration vers RAFT
- `ansible/roles/postgres_ha_v3/tasks/main.yml` : Ajout de `pysyncobj`

## Commandes Utiles

### Vérifier l'état du cluster

```bash
curl -s http://10.0.0.120:8008/cluster | jq
patronictl -c /etc/patroni.yml list
```

### Vérifier les logs Patroni

```bash
journalctl -u patroni.service -f
```

### Vérifier la connectivité RAFT

```bash
netstat -tuln | grep 5010
ls -la /data/db_postgres/raft/
```

## Conclusion

La migration vers RAFT natif a été effectuée avec succès. Patroni démarre correctement avec RAFT, mais le cluster n'initialise pas automatiquement PostgreSQL. Les nœuds attendent qu'un leader bootstrap le cluster, mais aucun nœud ne prend l'initiative.

**Problème restant :** Initialisation automatique du cluster PostgreSQL avec RAFT.

**Prochaines actions :** Vérifier la connectivité réseau entre les nœuds et explorer les options d'initialisation manuelle si nécessaire.

