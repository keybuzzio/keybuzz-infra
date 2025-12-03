# PH5-00 – RabbitMQ HA Quorum Cluster – Initialisation

**Date** : 2025-12-02  
**Phase** : PH5  
**Statut** : ✅ Initialisation complétée

---

## Résumé

L'arborescence complète pour le déploiement du cluster RabbitMQ Quorum HA a été créée et initialisée.

---

## Fichiers Créés

### Rôle Ansible

- ✅ `ansible/roles/rabbitmq_ha_v3/tasks/main.yml`
- ✅ `ansible/roles/rabbitmq_ha_v3/templates/rabbitmq.conf.j2`
- ✅ `ansible/roles/rabbitmq_ha_v3/templates/advanced.config.j2`
- ✅ `ansible/roles/rabbitmq_ha_v3/handlers/main.yml`

### Playbook

- ✅ `ansible/playbooks/rabbitmq_ha_v3.yml`

### Variables

- ✅ `ansible/group_vars/rabbitmq.yml`

### Scripts

- ✅ `scripts/rabbitmq_ha_end_to_end.sh`

### Documentation

- ✅ `keybuzz-docs/runbooks/phase5_rabbitmq_ha.md`

---

## Configuration Cible

### Nœuds

- **queue-01** : 10.0.0.131 (Premier nœud du cluster)
- **queue-02** : 10.0.0.132 (Rejoint queue-01)
- **queue-03** : 10.0.0.133 (Rejoint queue-01)

### Ports

- **5672** : AMQP (clients)
- **15672** : Management UI (interne)
- **4369** : epmd (Erlang Port Mapper)
- **25672** : Cluster inter-nodes

### Stockage

- **Data directory** : `/data/rabbitmq` (XFS monté par PH3)

---

## Prochaines Étapes

1. **PH5-01** : Installation du cluster RabbitMQ sur queue-01/02/03
2. **PH5-02** : Configuration du cluster join (queue-02/03 → queue-01)
3. **PH5-03** : Validation des Quorum Queues
4. **PH5-04** : HAProxy RabbitMQ (si nécessaire)
5. **PH5-05** : Tests de failover
6. **PH5-06** : Documentation finale

---

## Commandes de Déploiement

```bash
# Depuis install-v3
cd /opt/keybuzz/keybuzz-infra

# Déployer le cluster RabbitMQ
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/rabbitmq_ha_v3.yml \
  | tee /opt/keybuzz/logs/phase5/rabbitmq-ha-deploy.log

# Tester le cluster
export RABBITMQ_PASSWORD="<PASSWORD>"
bash scripts/rabbitmq_ha_end_to_end.sh
```

---

## Notes Importantes

- Le mot de passe RabbitMQ est temporairement dans `group_vars/rabbitmq.yml`
- Il sera déplacé dans Vault en PH6
- Les Quorum Queues sont activées par défaut (meilleure résilience que les mirrored queues)
- Le cluster utilise la découverte classique (classic_config)

---

**Auteur** : Ansible Automation  
**Dernière mise à jour** : 2025-12-02

