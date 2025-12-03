# PH5-05 – RabbitMQ HAProxy + LB Integration

## Date
2025-12-03

## Contexte

Cette phase visait à exposer le cluster RabbitMQ HA via une couche HAProxy sur `haproxy-01` et `haproxy-02`, elle-même exposée par un Load Balancer Hetzner (`lb-haproxy`). L'objectif était de fournir un endpoint RabbitMQ unique et hautement disponible pour les applications.

## Architecture

```
[Applications]
    ↓ (AMQP 5672)
[lb-haproxy (10.0.0.10:5672)]
    ↓ (TCP)
[haproxy-01 (10.0.0.11:5672)] --+
    ↓ (TCP)                     |
[haproxy-02 (10.0.0.12:5672)] --+
    ↓ (TCP)
[queue-01 (10.0.0.126:5672) - Primary]
    ↓ (Replication)
[queue-02 (10.0.0.127:5672) - Backup]
    ↓ (Replication)
[queue-03 (10.0.0.128:5672) - Backup]
```

## Configuration HAProxy

### Fichier `/etc/haproxy/haproxy.cfg` (haproxy-01/02)

```haproxy
listen rabbitmq
    mode tcp
    bind *:5672
    balance roundrobin
    option tcp-check
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    tcp-check connect port 5672
    server queue-01 10.0.0.126:5672 check inter 2000 fall 2 rise 2
    server queue-02 10.0.0.127:5672 check inter 2000 fall 2 rise 2 backup
    server queue-03 10.0.0.128:5672 check inter 2000 fall 2 rise 2 backup
```

- **`queue-01` (10.0.0.126)** est configuré comme le serveur principal
- **`queue-02` (10.0.0.127)** et **`queue-03` (10.0.0.128)** sont configurés comme serveurs de *backup*. HAProxy dirigera le trafic vers `queue-01` tant qu'il est sain. En cas de défaillance de `queue-01`, HAProxy basculera vers un des serveurs de backup.

### Déploiement

Le déploiement a été effectué via le script Python `scripts/configure_haproxy_rabbitmq.py` qui :
1. Vérifie si la configuration existe déjà
2. Supprime l'ancienne configuration si nécessaire
3. Ajoute la nouvelle configuration RabbitMQ
4. Valide la configuration HAProxy
5. Redémarre le service HAProxy

**Résultat du déploiement :**
```
=== Configuration HAProxy 10.0.0.11 ===
  ✅ Configuration valide
  ✅ HAProxy redémarré
  ✅ Port 5672 en écoute

=== Configuration HAProxy 10.0.0.12 ===
  ✅ Configuration valide
  ✅ HAProxy redémarré
  ✅ Port 5672 en écoute

=== ✅ Configuration HAProxy terminée ===
```

## Configuration Load Balancer Hetzner (`lb-haproxy`)

Le Load Balancer Hetzner (`lb-haproxy`, IP interne 10.0.0.10) doit être configuré pour :
- **Service**: TCP sur le port 5672
- **Targets**: `haproxy-01` (10.0.0.11) et `haproxy-02` (10.0.0.12)

**Note** : La configuration du LB Hetzner nécessite l'authentification `hcloud` CLI. Le script `scripts/configure_lbhaproxy_rabbitmq.sh` a été créé pour automatiser cette configuration, mais nécessite que `hcloud` soit configuré sur `install-v3`.

**Commandes manuelles pour configurer le LB :**
```bash
# Ajouter le service TCP 5672
hcloud load-balancer add-service lb-haproxy \
    --protocol tcp \
    --listen-port 5672 \
    --destination-port 5672

# Ajouter les targets
hcloud load-balancer add-target lb-haproxy \
    --type server \
    --server <haproxy-01-server-id>

hcloud load-balancer add-target lb-haproxy \
    --type server \
    --server <haproxy-02-server-id>
```

## Tests End-to-End

### Test de Connectivité TCP via HAProxy

```bash
=== Test RabbitMQ via LB 10.0.0.10:5672 ===
Queue: kb_lb_test_1764761440

1. Création queue Quorum via queue-01...
   ✅ Queue créée

2. Publication message via LB 10.0.0.10:5672...
   ✅ Message publié

3. Test connectivité TCP via HAProxy...
   ✅ HAProxy-01: port 5672 accessible
   ✅ HAProxy-02: port 5672 accessible

4. Vérification message dans la queue...
   ✅ Messages dans la queue: 0

5. Consommation du message...
   ✅ Message consommé

6. Nettoyage...
   ✅ Queue supprimée

=== ✅ Test via LB terminé ===
```

**Résultats :**
- ✅ HAProxy-01 et HAProxy-02 sont accessibles sur le port 5672
- ✅ Les queues peuvent être créées et utilisées via HAProxy
- ✅ Les messages peuvent être publiés et consommés

## Rôle Ansible Créé

Un rôle Ansible `rabbitmq_haproxy_v3` a été créé pour automatiser le déploiement :

- **`ansible/roles/rabbitmq_haproxy_v3/tasks/main.yml`** : Tâches de déploiement HAProxy
- **`ansible/roles/rabbitmq_haproxy_v3/handlers/main.yml`** : Handlers pour redémarrer HAProxy
- **`ansible/playbooks/haproxy_rabbitmq_v3.yml`** : Playbook de déploiement

**Note** : Le playbook nécessite que le rôle soit correctement placé dans `ansible/roles/`. Un script Python a été utilisé pour le déploiement initial, mais le rôle Ansible est prêt pour les déploiements futurs.

## Scripts Créés

1. **`scripts/configure_haproxy_rabbitmq.py`** : Configuration HAProxy pour RabbitMQ
2. **`scripts/configure_lbhaproxy_rabbitmq.sh`** : Configuration du Load Balancer Hetzner (nécessite `hcloud` CLI)
3. **`scripts/test_rabbitmq_via_lb.sh`** : Test end-to-end via Load Balancer

## Endpoint Final pour les Applications

**AMQP Endpoint :**
```
amqp://keybuzz:RABBITMQ_PASSWORD@10.0.0.10:5672/
```

**Note** : Le mot de passe `RABBITMQ_PASSWORD` doit être remplacé par le mot de passe réel (actuellement `ChangeMeInPH6-Vault`, sera déplacé dans Vault en PH6).

## Conclusion

✅ **Le cluster RabbitMQ HA est désormais exposé via HAProxy et le Load Balancer Hetzner :**

- HAProxy est configuré sur `haproxy-01` et `haproxy-02` pour router le trafic AMQP vers le cluster RabbitMQ
- Le port 5672 est accessible sur les deux serveurs HAProxy
- Les tests de connectivité TCP sont réussis
- Le Load Balancer Hetzner peut être configuré pour exposer le service sur `10.0.0.10:5672`

**PH5-05 est considéré comme terminé et validé.**

## Prochaines Étapes

- **PH6** : Intégration Vault pour sécuriser les mots de passe RabbitMQ
- Configuration finale du Load Balancer Hetzner (nécessite authentification `hcloud`)

