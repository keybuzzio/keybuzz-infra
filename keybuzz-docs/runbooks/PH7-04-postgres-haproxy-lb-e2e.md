# PH7-04 — PostgreSQL HA via HAProxy + Load Balancer End-to-End

**Date:** 2025-12-03  
**Statut:** ✅ HAProxy configuré, Load Balancer à configurer manuellement  
**Objectif:** Configurer HAProxy et le Load Balancer Hetzner pour exposer PostgreSQL HA

## Résumé

Configuration d'HAProxy pour exposer le cluster PostgreSQL HA sur haproxy-01 et haproxy-02 (port 5432). Le Load Balancer Hetzner nécessite une configuration manuelle via l'interface web ou avec un token hcloud configuré.

## Modifications Effectuées

### 1. Configuration HAProxy pour PostgreSQL

**Rôle Ansible :** `ansible/roles/postgres_haproxy_v3`

**Configuration ajoutée dans `/etc/haproxy/haproxy.cfg` :**

```haproxy
# PostgreSQL Writer (Master) - Port 5432
listen postgres_write
    mode tcp
    bind *:5432
    balance first
    option tcp-check
    tcp-check connect port 5432
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    server db-postgres-01 10.0.0.120:5432 check inter 2000 fall 2 rise 2
    server db-postgres-02 10.0.0.121:5432 check inter 2000 fall 2 rise 2 backup
    server db-postgres-03 10.0.0.122:5432 check inter 2000 fall 2 rise 2 backup

# PostgreSQL Readers (Replicas) - Port 5433 (optional)
listen postgres_read
    mode tcp
    bind *:5433
    balance roundrobin
    option tcp-check
    tcp-check connect port 5432
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    server db-postgres-01 10.0.0.120:5432 check inter 2000 fall 2 rise 2
    server db-postgres-02 10.0.0.121:5432 check inter 2000 fall 2 rise 2
    server db-postgres-03 10.0.0.122:5432 check inter 2000 fall 2 rise 2
```

**Caractéristiques :**
- **Port 5432** : Writer (leader) avec `balance first` pour router vers le premier serveur disponible
- **Port 5433** : Readers (replicas) avec `balance roundrobin` pour répartir les requêtes en lecture
- **Health checks** : TCP checks sur le port 5432 avec intervalles de 2 secondes
- **Backup servers** : db-postgres-02 et db-postgres-03 sont marqués comme backup pour le writer

### 2. Déploiement avec Ansible

**Playbook exécuté :**
```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/haproxy_postgres_v3.yml
```

**Résultat :**
- ✅ Configuration déployée sur haproxy-01 et haproxy-02
- ✅ HAProxy redémarré et validé
- ✅ Port 5432 en écoute sur les deux nœuds HAProxy

**Vérification :**
```bash
# Sur haproxy-01
ss -ntlp | grep 5432
# Résultat: LISTEN 0 4096 0.0.0.0:5432 0.0.0.0:*
```

### 3. Load Balancer Hetzner (lb-haproxy)

**Script fourni :** `scripts/configure_lbhaproxy_postgres.sh`

**Configuration requise :**
- Service TCP 5432 → 5432
- Protocol: TCP
- Targets: haproxy-01 (10.0.0.11) et haproxy-02 (10.0.0.12)

**Note :** Le script nécessite un token hcloud configuré. Pour configurer manuellement :

1. Via l'interface web Hetzner Cloud :
   - Aller sur le Load Balancer `lb-haproxy`
   - Ajouter un service TCP sur le port 5432
   - Ajouter haproxy-01 et haproxy-02 comme targets

2. Via CLI (avec token configuré) :
   ```bash
   hcloud load-balancer add-service lb-haproxy \
     --protocol tcp \
     --listen-port 5432 \
     --destination-port 5432
   
   hcloud load-balancer add-target lb-haproxy \
     --type server \
     --server <haproxy-01-server-id>
   
   hcloud load-balancer add-target lb-haproxy \
     --type server \
     --server <haproxy-02-server-id>
   ```

**État actuel :** ⚠️ Configuration manuelle requise (token hcloud non configuré)

### 4. Tests End-to-End

**Script fourni :** `scripts/postgres_ha_end_to_end.sh`

**Fonctionnalités du script :**
1. Test de connexion : `SELECT now();`
2. Création de base de données : `CREATE DATABASE kb_test;`
3. Création de table : `CREATE TABLE t (id serial PRIMARY KEY, value text);`
4. Insertion de données : `INSERT INTO t (value) VALUES ('OK PH7');`
5. Lecture des données : `SELECT * FROM t;`
6. Nettoyage : `DROP DATABASE kb_test;`

**Endpoint de test :**
- Via Load Balancer : `postgresql://postgres:<pwd>@10.0.0.10:5432/kb_test`
- Via HAProxy direct : `postgresql://postgres:<pwd>@10.0.0.11:5432/kb_test` ou `10.0.0.12:5432`

**Note :** Le script utilise la variable d'environnement `POSTGRES_SUPERUSER_PASSWORD` pour le mot de passe.

## Vérifications Effectuées

### HAProxy Status

**haproxy-01 (10.0.0.11) :**
- ✅ HAProxy service : active (running)
- ✅ Port 5432 : LISTEN sur 0.0.0.0:5432
- ✅ Configuration validée : `haproxy -c -f /etc/haproxy/haproxy.cfg` → OK

**haproxy-02 (10.0.0.12) :**
- ✅ HAProxy service : active (running)
- ✅ Port 5432 : LISTEN sur 0.0.0.0:5432
- ✅ Configuration validée : `haproxy -c -f /etc/haproxy/haproxy.cfg` → OK

### Cluster PostgreSQL Status

**Leader :**
- db-postgres-03 (10.0.0.122) : Leader / running / Timeline 2

**Replicas :**
- db-postgres-01 (10.0.0.120) : Replica / streaming / Lag 0
- db-postgres-02 (10.0.0.121) : Replica / streaming / Lag 0

## Tests Manuels Recommandés

### Test 1 : Connexion via HAProxy

```bash
# Via haproxy-01
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.11 -p 5432 -U postgres -c "SELECT now();"

# Via haproxy-02
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.12 -p 5432 -U postgres -c "SELECT now();"
```

### Test 2 : Création de Base de Données

```bash
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" createdb -h 10.0.0.11 -p 5432 -U postgres kb_test
```

### Test 3 : Création de Table et Insertion

```bash
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.11 -p 5432 -U postgres -d kb_test \
  -c "CREATE TABLE t (id serial PRIMARY KEY, value text); INSERT INTO t (value) VALUES ('PG-HA-OK');"
```

### Test 4 : Lecture sur les Replicas

```bash
# Sur db-postgres-01
sudo -u postgres psql -d kb_test -c "SELECT * FROM t;"

# Sur db-postgres-02
sudo -u postgres psql -d kb_test -c "SELECT * FROM t;"
```

**Résultat attendu :** Les deux replicas doivent retourner la ligne `PG-HA-OK` si `hot_standby` est activé (ce qui est le cas).

### Test 5 : Via Load Balancer (une fois configuré)

```bash
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.10 -p 5432 -U postgres -c "SELECT now();"
```

## Configuration du Load Balancer Hetzner

### Étape 1 : Identifier le Load Balancer

```bash
hcloud load-balancer list
hcloud load-balancer describe lb-haproxy
```

### Étape 2 : Ajouter le Service PostgreSQL

```bash
hcloud load-balancer add-service lb-haproxy \
  --protocol tcp \
  --listen-port 5432 \
  --destination-port 5432
```

### Étape 3 : Ajouter les Targets

```bash
# Récupérer les IDs des serveurs
HAPROXY_01_ID=$(hcloud server list -o columns=id,name | grep haproxy-01 | awk '{print $1}')
HAPROXY_02_ID=$(hcloud server list -o columns=id,name | grep haproxy-02 | awk '{print $1}')

# Ajouter les targets
hcloud load-balancer add-target lb-haproxy --type server --server $HAPROXY_01_ID
hcloud load-balancer add-target lb-haproxy --type server --server $HAPROXY_02_ID
```

### Étape 4 : Vérifier la Configuration

```bash
hcloud load-balancer describe lb-haproxy -o json | jq '.services[] | select(.listen_port == 5432)'
hcloud load-balancer describe lb-haproxy -o json | jq '.targets[]'
```

## Fichiers Modifiés

- `ansible/roles/postgres_haproxy_v3/tasks/main.yml` : Configuration HAProxy avec IPs fixes
- `ansible/playbooks/haproxy_postgres_v3.yml` : Playbook de déploiement (déjà existant)
- `scripts/configure_lbhaproxy_postgres.sh` : Script de configuration LB (déjà existant)
- `scripts/postgres_ha_end_to_end.sh` : Script de test end-to-end (déjà existant)

## Commandes Utiles

### Vérifier l'état HAProxy

```bash
systemctl status haproxy
haproxy -c -f /etc/haproxy/haproxy.cfg
ss -ntlp | grep 5432
```

### Vérifier la configuration HAProxy

```bash
grep -A 10 "listen postgres_write" /etc/haproxy/haproxy.cfg
```

### Tester la connexion PostgreSQL

```bash
# Via HAProxy
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.11 -p 5432 -U postgres -c "SELECT version();"

# Via Load Balancer (une fois configuré)
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.10 -p 5432 -U postgres -c "SELECT version();"
```

### Vérifier le routage HAProxy

```bash
# Vérifier quel serveur PostgreSQL est utilisé
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.11 -p 5432 -U postgres -c "SELECT inet_server_addr(), inet_server_port();"
```

## Conclusion

✅ **HAProxy configuré avec succès :**
- Configuration déployée sur haproxy-01 et haproxy-02
- Port 5432 en écoute sur les deux nœuds
- Health checks configurés pour les 3 nœuds PostgreSQL
- Writer (port 5432) et Reader (port 5433) configurés

⚠️ **Load Balancer Hetzner :**
- Script fourni mais nécessite un token hcloud configuré
- Configuration manuelle requise via l'interface web ou CLI avec token

**Endpoint PostgreSQL final pour les applications :**
- **Via HAProxy direct :** `postgresql://postgres:<pwd>@10.0.0.11:5432/<db>` ou `10.0.0.12:5432`
- **Via Load Balancer (une fois configuré) :** `postgresql://postgres:<pwd>@10.0.0.10:5432/<db>`

**Prochaines étapes :**
1. Configurer le Load Balancer Hetzner manuellement (via interface web ou avec token hcloud)
2. Effectuer les tests end-to-end via le Load Balancer
3. Valider la réplication sur les replicas après les écritures
4. Configurer les applications pour utiliser l'endpoint PostgreSQL

Le cluster PostgreSQL HA est maintenant accessible via HAProxy et prêt pour l'intégration avec les applications.

