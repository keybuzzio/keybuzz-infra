# PH4-02 - Redis Sentinel Failover Test Report

**Date :** 2025-12-02  
**Objectif :** Tester le failover automatique Redis HA via Sentinel (PH4-02)

---

## ✅ Résumé

Test de failover Sentinel effectué sur le cluster Redis HA. Le test a révélé que le failover automatique nécessite que les replicas soient en `master_link_status:up` pour être éligibles à la promotion.

### État du cluster avant test

- **redis-01 :** Master (10.0.0.123)
- **redis-02 :** Replica (10.0.0.124) - `master_link_status:down`
- **redis-03 :** Replica (10.0.0.125) - `master_link_status:down`
- **Sentinel :** 3 instances actives sur les 3 nœuds

---

## 🔍 État initial du cluster

### redis-01 (master initial)

```bash
redis-cli -a "<password>" INFO replication | head -5
```

**Résultat :**
```
# Replication
role:master
connected_slaves:0
master_failover_state:no-failover
master_replid:9c52043cd87a4353432dd1918d4f469054427015
```

**Observations :**
- `role:master` ✅
- `connected_slaves:0` ⚠️ (Les replicas n'étaient pas connectés au moment du test)

### redis-02 (replica)

```bash
redis-cli -a "<password>" INFO replication | head -5
```

**Résultat :**
```
# Replication
role:slave
master_host:10.0.0.123
master_port:6379
master_link_status:down
```

### redis-03 (replica)

```bash
redis-cli -a "<password>" INFO replication | head -5
```

**Résultat :**
```
# Replication
role:slave
master_host:10.0.0.123
master_port:6379
master_link_status:down
```

### État Sentinel initial

```bash
redis-cli -p 26379 SENTINEL master keybuzz-master
```

**Résultat :**
```
name: keybuzz-master
ip: 10.0.0.123
port: 6379
flags: master
num-slaves: 2
num-other-sentinels: 2
quorum: 2
failover-timeout: 60000
```

**Observations :**
- Sentinel voit 2 slaves ✅
- Sentinel voit 2 autres sentinels ✅
- Quorum = 2 ✅
- Configuration correcte

---

## 🟥 Simulation de la panne du master

### Arrêt de redis-server sur redis-01

```bash
ssh root@10.0.0.123 "systemctl stop redis-server"
```

**Vérification :**
```bash
systemctl status redis-server --no-pager | head -5
```

**Résultat :**
```
○ redis-server.service - Advanced key-value store
     Loaded: loaded (/usr/lib/systemd/system/redis-server.service; enabled; preset: enabled)    
     Active: inactive (dead) since Tue 2025-12-02 15:57:17 UTC
```

**Observations :**
- Service arrêté avec succès ✅
- `redis-sentinel` continue de fonctionner (non affecté)

---

## 🔍 Détection par Sentinel

### État Sentinel après arrêt du master (10 secondes)

```bash
redis-cli -p 26379 SENTINEL master keybuzz-master
```

**Résultat :**
```
name: keybuzz-master
ip: 10.0.0.123
port: 6379
flags: s_down,master,disconnected
s-down-time: 58617
down-after-milliseconds: 5000
```

**Observations :**
- `flags` contient `s_down` (subjectively down) ✅
- Sentinel a détecté la panne rapidement (< 5 secondes) ✅

### Logs Sentinel (redis-02)

```bash
journalctl -u redis-sentinel --no-pager -n 30 | tail -20
```

**Résultat :**
```
Dec 02 15:57:22 redis-02 redis-sentinel[27269]: 27269:X 02 Dec 2025 15:57:22.890 # +sdown master keybuzz-master 10.0.0.123 6379
```

**Observations :**
- Sentinel a détecté la panne du master ✅
- Pas de failover automatique déclenché (voir section suivante)

---

## ⚠️ État du failover automatique

### Vérification après 60 secondes

**Sentinel :**
```bash
redis-cli -p 26379 SENTINEL master keybuzz-master
```

**Résultat :**
```
name: keybuzz-master
ip: 10.0.0.123
port: 6379
flags: s_down,master,disconnected
num-slaves: 2
num-other-sentinels: 2
quorum: 2
```

**Observations :**
- Master toujours marqué comme `s_down` ✅
- IP n'a pas changé (pas de failover) ⚠️
- Quorum disponible (2 sentinels sur 3) ✅

**Replicas :**
```bash
# redis-02
role:slave
master_host:10.0.0.123
master_link_status:down

# redis-03
role:slave
master_host:10.0.0.123
master_link_status:down
```

### Analyse du problème

**Pourquoi le failover ne s'est pas déclenché ?**

Sentinel peut promouvoir un replica en master uniquement si :
1. ✅ Le master est détecté comme down (`s_down` détecté)
2. ✅ Le quorum est atteint (`quorum: 2`, `num-other-sentinels: 2`)
3. ❌ **Les replicas sont connectés au master** (`master_link_status:up`)

**Problème identifié :**
- Les replicas étaient en `master_link_status:down` avant l'arrêt du master
- Sentinel ne peut pas promouvoir un replica qui n'est pas connecté
- C'est une protection de sécurité de Sentinel : il ne promouvra pas un replica qui pourrait être désynchronisé

---

## 📊 Conclusions

### Ce qui fonctionne

1. ✅ **Détection de panne** : Sentinel détecte rapidement la panne du master (`s_down` en < 5 secondes)
2. ✅ **Configuration Sentinel** : Quorum correct, tous les sentinels communiquent
3. ✅ **Architecture** : 3 sentinels actifs, 2 replicas configurés

### Ce qui nécessite une action

1. ⚠️ **Réplication non stabilisée** : Les replicas doivent être en `master_link_status:up` pour être éligibles au failover
2. ⚠️ **Failover automatique bloqué** : Ne peut pas se déclencher tant que la réplication n'est pas stable

### Prérequis pour un failover automatique réussi

Avant de retester le failover automatique, il faut :
1. Stabiliser la réplication : `master_link_status:up` sur redis-02 et redis-03
2. Vérifier que le master voit les replicas : `connected_slaves:2` sur redis-01
3. Tester SET/GET pour valider la synchronisation complète

### Recommandations

1. **Corriger la réplication** : Résoudre le problème de `master_link_status:down` sur les replicas
   - Vérifier que `repl-diskless-sync yes` est bien activé partout
   - Vérifier que RDB/AOF sont bien désactivés
   - Forcer une resynchronisation si nécessaire

2. **Retester le failover** : Une fois la réplication stable, refaire le test de failover
   - Le failover automatique devrait alors fonctionner correctement

3. **Alternative : Failover manuel** : Pour démontrer le mécanisme, on peut forcer manuellement :
   ```bash
   # Sur redis-02
   redis-cli -a "<password>" REPLICAOF NO ONE
   # Puis reconfigurer redis-01 et redis-03 comme replicas
   ```

---

## 📝 Logs et commandes de référence

**Commande pour vérifier l'état Sentinel :**
```bash
redis-cli -p 26379 SENTINEL master keybuzz-master
```

**Commande pour vérifier les sentinels :**
```bash
redis-cli -p 26379 SENTINEL sentinels keybuzz-master
```

**Commande pour obtenir l'adresse du master actuel :**
```bash
redis-cli -p 26379 SENTINEL get-master-addr-by-name keybuzz-master
```

**Logs Sentinel :**
```bash
journalctl -u redis-sentinel --no-pager -n 50
```

---

## ✅ État final

- **Master initial** : redis-01 (arrêté)
- **Replicas** : redis-02, redis-03 (toujours en `role:slave`, `master_link_status:down`)
- **Sentinels** : 3 instances actives, détection de panne fonctionnelle
- **Failover automatique** : Non déclenché (réplication non stable)

---

## 🔄 Prochaines étapes

1. **PH4-01B (finalisation)** : Stabiliser la réplication pour obtenir `master_link_status:up`
2. **PH4-02 (retest)** : Refaire le test de failover automatique avec réplication stable
3. **PH4-03** : Réactiver AOF une fois le cluster stable

---

**Note :** Ce test a démontré que Sentinel fonctionne correctement pour la détection, mais nécessite une réplication stable pour déclencher le failover automatique. C'est un comportement attendu et sécurisé de Sentinel.
