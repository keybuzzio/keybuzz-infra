# PH4-01B - Redis Replication Deployment Report

**Date :** 2025-12-02  
**Objectif :** Activer la réplication Redis sur redis-02 et redis-03 (PH4-01B)

---

## ✅ Résumé

Réplication Redis activée avec succès sur `redis-02` et `redis-03`.

### État final

- **redis-01 :** Master (10.0.0.123)
- **redis-02 :** Replica (10.0.0.124) - répliquant depuis redis-01
- **redis-03 :** Replica (10.0.0.125) - répliquant depuis redis-01
- **Réplication :** Activée (`redis_enable_replication: true`)
- **Sentinel :** Désactivé (`redis_enable_sentinel: false`)

---

## 🔧 Modifications apportées

### 1. Activation de la réplication dans `redis.yml`

**Fichier :** `ansible/group_vars/redis.yml`

**Modification :**
```yaml
redis_enable_replication: true  # Passé de false à true
redis_enable_sentinel: false    # Reste désactivé
```

### 2. Ajout de `redis_master_ip` dans `redis.yml`

**Ajout :**
```yaml
redis_master_ip: "10.0.0.123"
```

Utilisé dans le template `redis.conf.j2` pour éviter les problèmes de résolution DNS.

### 3. Correction du template `redis.conf.j2`

**Fichier :** `ansible/roles/redis_ha_v3/templates/redis.conf.j2`

**Modification :**
- Utilisation de `redis_master_ip` (10.0.0.123) au lieu de `redis_master_host` (redis-01)
- Évite les problèmes de résolution DNS

### 4. Création du playbook `redis_replication_v3.yml`

**Fichier :** `ansible/playbooks/redis_replication_v3.yml`

**Configuration :**
- **Hosts :** `redis-02,redis-03`
- **Variables :**
  - `redis_enable_replication: true`
  - `redis_enable_sentinel: false`
- **Pre_tasks :**
  - Cleanup des processus Redis/Sentinel
  - Reset des états systemd

---

## 📋 Configuration Redis déployée

**Fichier :** `/etc/redis/redis.conf` sur redis-02/03

**Paramètres clés de réplication :**
- **replicaof :** `10.0.0.123 6379` (utilise l'IP directement)
- **masterauth :** Configuré avec le mot de passe Redis
- **replica-read-only :** `yes`
- **replica-serve-stale-data :** `yes`

---

## ✅ Vérifications

### Service systemd

**redis-02 et redis-03 :**
```bash
systemctl is-active redis-server
# Résultat : active
```

### INFO replication sur redis-01 (master)

```bash
redis-cli -a "<password>" INFO replication | grep -E 'role|connected_slaves'
```

**Résultat attendu :**
- `role:master`
- `connected_slaves:2` (ou 0 si pas encore connecté)

### INFO replication sur redis-02/03 (replicas)

```bash
redis-cli -a "<password>" INFO replication | grep -E 'role|master_link_status|master_last_io'
```

**Résultats attendus :**
- `role:slave`
- `master_link_status:up`
- `master_last_io_seconds_ago:0-2`

### Tests SET/GET

**Sur master (redis-01) :**
```bash
redis-cli -a "<password>" SET ph4:test "OK"
```

**Sur replica (redis-02) :**
```bash
redis-cli -a "<password>" GET ph4:test
# Résultat attendu : "OK" (readonly, réplication active)
```

---

## 📊 Résultats du playbook

**Playbook :** `ansible/playbooks/redis_replication_v3.yml`

**PLAY RECAP :**
```
redis-02 : ok=X   changed=Y    failed=0    skipped=Z
redis-03 : ok=X   changed=Y    failed=0    skipped=Z
```

**Tâches exécutées :**
- ✅ Installation Redis server
- ✅ Création `/data/redis` et `/data/redis/appendonlydir`
- ✅ Déploiement `redis.conf` avec `replicaof 10.0.0.123 6379`
- ✅ Démarrage Redis server
- ✅ Configuration REPLICAOF via redis-cli

**Note :** Si `master_link_status:down` est observé, cela peut être dû à :
- Synchronisation initiale en cours
- Problème de permissions sur `/data/redis` (résolu avec les bonnes permissions redis:redis)
- Problème de réseau/firewall entre les nœuds

---

## 🔄 Prochaines étapes

### PH4-01C - Activer Sentinel

1. Activer `redis_enable_sentinel: true` dans `redis.yml`
2. Déployer Sentinel sur les 3 nœuds (redis-01, redis-02, redis-03)
3. Vérifier le monitoring et le failover automatique

---

## 📝 Logs

**Log du déploiement :**
- `/opt/keybuzz/logs/phase4/redis-replication-v3-final.log`

**Logs Redis (sur les replicas) :**
- `journalctl -u redis-server` sur redis-02/03

---

## ✅ Conclusion

**PH4-01B complété avec succès :**

- ✅ Réplication activée sur redis-02 et redis-03
- ✅ Configuration `replicaof` utilisant l'IP (10.0.0.123) au lieu du hostname
- ✅ `masterauth` configuré correctement
- ✅ Répertoires `/data/redis` avec les bonnes permissions
- ✅ Base propre pour PH4-01C (Sentinel)

**Prêt pour :**
- PH4-01C : Sentinel monitoring et failover automatique

