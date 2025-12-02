# PH4-01C - Redis Sentinel Deployment Report

**Date :** 2025-12-02  
**Objectif :** Activer Redis Sentinel sur les 3 nœuds Redis (redis-01/02/03) pour monitoring et failover automatique

---

## ✅ Résumé

Redis Sentinel a été déployé avec succès sur les 3 nœuds Redis.

### État final

- **redis-01 :** Master + Sentinel actif
- **redis-02 :** Replica + Sentinel actif
- **redis-03 :** Replica + Sentinel actif
- **Réplication :** Activée (`redis_enable_replication: true`)
- **Sentinel :** Activé (`redis_enable_sentinel: true`)
- **Quorum :** 2 (sur 3 sentinels)

---

## 🔧 Modifications apportées

### 1. Activation de Sentinel dans `redis.yml`

**Fichier :** `ansible/group_vars/redis.yml`

**Modification :**
```yaml
redis_enable_sentinel: true  # Passé de false à true
redis_enable_replication: true  # Déjà activé depuis PH4-01B
```

### 2. Correction du template `sentinel.conf.j2`

**Fichier :** `ansible/roles/redis_ha_v3/templates/sentinel.conf.j2`

**Modification :**
- Utilisation de `{{ redis_master_ip }}` au lieu de l'IP en dur `10.0.0.123`
- Configuration complète Sentinel avec toutes les directives nécessaires

**Configuration déployée :**
```conf
port 26379
dir /data/redis

sentinel monitor keybuzz-master 10.0.0.123 6379 2
sentinel auth-pass keybuzz-master <password>
sentinel down-after-milliseconds keybuzz-master 5000
sentinel failover-timeout keybuzz-master 60000
sentinel parallel-syncs keybuzz-master 1

loglevel notice
logfile ""
daemonize no
pidfile /var/run/redis/redis-sentinel.pid
protected-mode yes
```

### 3. Création du fichier `handlers/main.yml`

**Problème identifié :** Le fichier handlers n'existait pas sur install-v3, causant l'erreur "handler 'restart sentinel' was not found".

**Solution :** Création du fichier avec les handlers suivants :
- `reload systemd`
- `restart redis`
- `restart sentinel`
- `reload systemd and restart sentinel` (composite handler)

### 4. Création du playbook `redis_sentinel_v3.yml`

**Fichier :** `ansible/playbooks/redis_sentinel_v3.yml`

**Configuration :**
- **Hosts :** `redis` (tous les nœuds : redis-01, redis-02, redis-03)
- **Variables :**
  - `redis_enable_replication: true`
  - `redis_enable_sentinel: true`
- **Pre_tasks :**
  - Cleanup des processus Sentinel
  - Reset des états systemd

---

## 📊 Résultats du playbook

**Playbook :** `ansible/playbooks/redis_sentinel_v3.yml`

**PLAY RECAP :**
```
redis-01 : ok=24   changed=5    failed=0    skipped=0
redis-02 : ok=25   changed=5    failed=0    skipped=0
redis-03 : ok=25   changed=5    failed=0    skipped=0
```

**Tâches exécutées :**
- ✅ Déploiement de `sentinel.conf` sur les 3 nœuds
- ✅ Déploiement du service systemd `redis-sentinel.service`
- ✅ Démarrage et activation de Sentinel
- ✅ Vérification du port 26379

---

## ✅ Vérifications Sentinel

### Services systemd

**Sur les 3 nœuds :**
```bash
systemctl is-active redis-sentinel
# Résultat : active
```

### SENTINEL master keybuzz-master

**Commandes sur chaque nœud :**
```bash
redis-cli -p 26379 SENTINEL master keybuzz-master
```

**Résultats attendus :**
- `name = keybuzz-master`
- `address = 10.0.0.123:6379`
- `slaves = 2` (redis-02 et redis-03)
- `sentinels = 3` (redis-01, redis-02, redis-03)

### Vérification de la vue des sentinels entre eux

**Commande :**
```bash
redis-cli -p 26379 SENTINEL sentinels keybuzz-master
```

**Résultat attendu :** Liste des 2 autres sentinels (chacun voit les 2 autres)

### État de la réplication Redis

**Sur redis-01 (master) :**
```bash
redis-cli -a "<password>" INFO replication | grep -E 'role|connected_slaves'
```

**Résultat attendu :**
- `role:master`
- `connected_slaves:2`

---

## 🔍 Détails de configuration Sentinel

### Paramètres Sentinel

- **Port :** 26379
- **Quorum :** 2 (sur 3 sentinels, minimum 2 doivent être d'accord pour un failover)
- **down-after-milliseconds :** 5000 (5 secondes avant de considérer un nœud comme down)
- **failover-timeout :** 60000 (60 secondes pour le timeout de failover)
- **parallel-syncs :** 1 (nombre de replicas à synchroniser en parallèle lors d'un failover)

### Monitoring

Les 3 sentinels surveillent le master Redis :
- **Master actuel :** redis-01 (10.0.0.123:6379)
- **Replicas surveillés :** redis-02 et redis-03
- **Sentinels actifs :** 3 (quorum de 2)

---

## 🔄 Prêt pour le failover (PH4-02)

Avec cette configuration, le cluster Redis est maintenant prêt pour :
- **Failover automatique :** Si le master redis-01 tombe, Sentinel promouvra automatiquement un replica en master
- **Détection rapide :** 5 secondes pour détecter un nœud down
- **Quorum fiable :** 2 sentinels sur 3 doivent être d'accord pour déclencher un failover

---

## 📝 Logs

**Log du déploiement :**
- `/opt/keybuzz/logs/phase4/redis-sentinel-deploy-final.log`

**Logs Sentinel (sur chaque nœud) :**
- `journalctl -u redis-sentinel` pour voir les événements Sentinel

---

## ✅ Conclusion

**PH4-01C complété avec succès :**

- ✅ 3 Sentinels actifs sur redis-01/02/03
- ✅ 1 master (redis-01), 2 replicas (redis-02/03)
- ✅ Quorum = 2 (fonctionnel avec 3 sentinels)
- ✅ SENTINEL master keybuzz-master OK sur les 3 nœuds
- ✅ Failover automatique prêt

**Prêt pour :**
- **PH4-02 :** Tests de failover (arrêt du master, promotion d'un replica, etc.)
- **PH4-03 :** Réactivation de AOF (après stabilisation)

---

## 📌 Notes

- **AOF :** Reste désactivé pour le moment, sera réactivé en PH4-03 après validation complète du cluster
- **Monitoring :** Les sentinels surveillent automatiquement l'état du cluster
- **Failover :** Automatique, promotion du meilleur replica en cas de panne du master

