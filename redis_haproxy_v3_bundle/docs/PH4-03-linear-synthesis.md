# PH4-03 - Synthèse pour Linear

**Date :** 2025-12-02  
**EPIC :** KB-PH4-REDIS-HAPROXY  
**Objectif :** Intégration Redis HA avec HAProxy + lb-haproxy

---

## 📋 EPIC Linear

### Titre EPIC
**KB-PH4-REDIS-HAPROXY** – Intégration Redis HA avec HAProxy + lb-haproxy

### Description EPIC

Intégration du cluster Redis HA (1 master + 2 replicas + Sentinel) derrière HAProxy (haproxy-01/02) et le load balancer Hetzner lb-haproxy.

**Objectif :** Que toutes les applications KeyBuzz utilisent un endpoint unique (par ex. `redis://:PASSWORD@10.0.0.10:6379/0`) pour accéder à Redis avec haute disponibilité, sans devoir gérer elles-mêmes la logique de Sentinel.

### Labels
- `keybuzz-v3`
- `infra`
- `redis`
- `haproxy`
- `phase4`
- `critical`

### Dépendances
- **Dépend de :** KB-PH3 (Volumes XFS) et KB-PH4-01 (Redis HA doit être OK avant)
- **Alimente :** KB-FEAT-CORE et KB-FEAT-CONNECT (connecteurs marketplaces, Chatwoot, n8n, etc.)

---

## 🎫 Tickets PH4-03

### PH4-03-01 – Créer rôle Ansible redis_haproxy_v3

**ID Linear :** `KB-PH4-03-01`  
**Assigné :** CE  
**Statut :** ✅ Complété

**Description :**
Créer rôle `ansible/roles/redis_haproxy_v3` (ou vérifier s'il existe déjà)

**Tâches :**
- Définir `templates/redis-haproxy.cfg.j2`
- Définir `tasks/main.yml` (install, template, include, restart)
- Définir `handlers/main.yml` (restart haproxy)

**Critères d'acceptation :**
- ✅ Fichiers présents dans `keybuzz-infra/ansible/roles/redis_haproxy_v3/`
- ✅ HAProxy valide (`haproxy -c`)
- ✅ Template utilise les variables depuis `group_vars/redis.yml`

**Fichiers Git :**
- `keybuzz-infra/ansible/roles/redis_haproxy_v3/tasks/main.yml`
- `keybuzz-infra/ansible/roles/redis_haproxy_v3/templates/redis-haproxy.cfg.j2`
- `keybuzz-infra/ansible/roles/redis_haproxy_v3/handlers/main.yml`

---

### PH4-03-02 – Créer playbook redis_haproxy_v3.yml

**ID Linear :** `KB-PH4-03-02`  
**Assigné :** CE  
**Statut :** ✅ Complété

**Description :**
Assembler un playbook qui applique le rôle sur les deux nœuds haproxy-01 et haproxy-02.

**Tâches :**
- Créer `ansible/playbooks/redis_haproxy_v3.yml`
- Cibler `haproxy-01` et `haproxy-02`
- Inclure le rôle `redis_haproxy_v3`

**Critères d'acceptation :**
- ✅ Playbook présent dans `keybuzz-infra/ansible/playbooks/redis_haproxy_v3.yml`
- ✅ Playbook exécutable avec `ansible-playbook`
- ✅ Cible correctement haproxy-01 et haproxy-02

**Fichiers Git :**
- `keybuzz-infra/ansible/playbooks/redis_haproxy_v3.yml`

---

### PH4-03-03 – Vérifier/adapter la config haproxy.cfg pour include conf.d/

**ID Linear :** `KB-PH4-03-03`  
**Assigné :** CE  
**Statut :** ✅ Complété (vérifié dans le rôle)

**Description :**
Vérifier que `include /etc/haproxy/conf.d/*.cfg` est bien présent et correct dans `/etc/haproxy/haproxy.cfg`.

**Tâches :**
- Vérifier la présence de la directive `include`
- Si absente, l'ajouter après la section `global`
- S'assurer que le répertoire `/etc/haproxy/conf.d/` existe

**Critères d'acceptation :**
- ✅ Directive `include /etc/haproxy/conf.d/*.cfg` présente dans haproxy.cfg
- ✅ Répertoire `/etc/haproxy/conf.d/` existe
- ✅ Configuration HAProxy valide après inclusion

**Fichiers Git :**
- `keybuzz-infra/ansible/roles/redis_haproxy_v3/tasks/main.yml` (tâche "Ensure main HAProxy config includes conf.d/*")

---

### PH4-03-04 – Vérifier / configurer lb-haproxy (service TCP 6379)

**ID Linear :** `KB-PH4-03-04`  
**Assigné :** CE (ou exécuter les commandes hcloud manuellement)

**Description :**
Produire un script `configure_lbhaproxy_redis.sh` contenant les commandes hcloud load-balancer add-service & add-target.

**Tâches :**
- Créer le script `keybuzz-infra/scripts/configure_lbhaproxy_redis.sh`
- Script doit ajouter le service TCP 6379 au LB Hetzner
- Script doit ajouter haproxy-01 et haproxy-02 comme targets

**Critères d'acceptation :**
- ✅ Script présent et exécutable
- ✅ lb-haproxy expose `10.0.0.10:6379` vers haproxy-01/02
- ✅ Configuration vérifiable via `hcloud load-balancer describe`

**Fichiers Git :**
- `keybuzz-infra/scripts/configure_lbhaproxy_redis.sh`

**Commandes hcloud :**
```bash
hcloud load-balancer add-service <LB_ID> \
  --protocol tcp \
  --listen-port 6379 \
  --destination-port 6379

hcloud load-balancer add-target <LB_ID> \
  --type server \
  --server haproxy-01

hcloud load-balancer add-target <LB_ID> \
  --type server \
  --server haproxy-02
```

---

### PH4-03-05 – Créer script de test redis_ha_end_to_end.sh

**ID Linear :** `KB-PH4-03-05`  
**Assigné :** CE  
**Statut :** ✅ Complété

**Description :**
Créer script de test `redis_ha_end_to_end.sh` qui teste PING, SET/GET via `10.0.0.10:6379`.

**Tâches :**
- Créer le script `keybuzz-infra/scripts/redis_ha_end_to_end.sh`
- Tester PING/PONG
- Tester SET/GET
- Tester INFO replication
- Générer un log complet
- Retourner "OK" si tous les tests passent

**Critères d'acceptation :**
- ✅ Script présent et exécutable
- ✅ Teste PING via `10.0.0.10:6379`
- ✅ Teste SET/GET via `10.0.0.10:6379`
- ✅ Log complet avec timestamp
- ✅ Retour "OK" attendu si succès

**Fichiers Git :**
- `keybuzz-infra/scripts/redis_ha_end_to_end.sh`

---

### PH4-03-06 – Test de failover applicatif via HAProxy

**ID Linear :** `KB-PH4-03-06`  
**Assigné :** CE

**Description :**
Scénario de test de failover :
1. `systemctl stop redis-server` sur redis-01
2. Lancer `redis_ha_end_to_end.sh`
3. Vérifier que les commandes continuent de réussir (HAProxy bascule sur redis-02/03)
4. Noter le temps de bascule

**Tâches :**
- Documenter le scénario de test
- Exécuter le test de failover
- Mesurer le temps de bascule
- Vérifier que HAProxy route vers le nouveau master

**Critères d'acceptation :**
- ✅ Test de failover documenté
- ✅ Temps de bascule < 10 secondes
- ✅ Les commandes Redis continuent de fonctionner après failover
- ✅ HAProxy route vers le nouveau master (redis-02 ou redis-03)

**Documentation :**
- Scénario documenté dans `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md`

---

### PH4-03-07 – Mise à jour documentation

**ID Linear :** `KB-PH4-03-07`  
**Assigné :** CB  
**Statut :** ✅ Complété

**Description :**
Ajouter un chapitre dans `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md` avec :
- Schémas : Apps → lb-haproxy → haproxy-01/02 → Redis cluster
- Détails des ports
- Comment tester
- Comment opérationnaliser (stop/start, rollback, etc.)

**Tâches :**
- Créer le runbook complet
- Inclure les schémas d'architecture
- Documenter les tests
- Documenter les procédures opérationnelles

**Critères d'acceptation :**
- ✅ Runbook présent dans `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md`
- ✅ Schémas d'architecture inclus
- ✅ Procédures de test documentées
- ✅ Procédures opérationnelles documentées

**Fichiers Git :**
- `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md`

---

### PH4-03-08 – Mettre à jour la doc produit (où pointer pour config Redis)

**ID Linear :** `KB-PH4-03-08`  
**Assigné :** CB  
**Statut :** ✅ Complété

**Description :**
Dans la doc "KeyBuzz App Architecture" (dans `keybuzz-docs/blueprint/`), préciser :
- Les apps doivent utiliser `redis://:PASSWORD@10.0.0.10:6379/0`
- Ne jamais se connecter directement aux IPs redis-01/02/03
- Comment récupérer le mot de passe (plus tard via Vault)

**Tâches :**
- Mettre à jour `keybuzz-docs/blueprint/infra_v3_overview.md`
- Ajouter section "Redis HA - Configuration pour les applications"
- Inclure exemples de code (Python, Node.js, Docker, K8s)

**Critères d'acceptation :**
- ✅ Documentation blueprint mise à jour
- ✅ Endpoint unique documenté (`10.0.0.10:6379`)
- ✅ Exemples de code pour différentes langages
- ✅ Instructions pour récupérer le mot de passe

**Fichiers Git :**
- `keybuzz-docs/blueprint/infra_v3_overview.md`

---

## 🔗 Dépendances et liens

### Dépendances EPIC

- **Dépend de :**
  - KB-PH3 (Volumes XFS) - `keybuzz-infra/PH3-03-xfs-mount-report.md`
  - KB-PH4-01 (Redis HA) - `keybuzz-infra/PH4-01A-redis-standalone-report.md`, `PH4-01B-redis-replication-report.md`, `PH4-01C-redis-sentinel-report.md`

- **Alimente :**
  - KB-FEAT-CORE (Applications KeyBuzz core)
  - KB-FEAT-CONNECT (Connecteurs marketplaces, Chatwoot, n8n, etc.)

### Fichiers Git référencés

**Rôles Ansible :**
- `keybuzz-infra/ansible/roles/redis_ha_v3/` (PH4-01)
- `keybuzz-infra/ansible/roles/redis_haproxy_v3/` (PH4-03)

**Playbooks :**
- `keybuzz-infra/ansible/playbooks/redis_standalone_v3.yml` (PH4-01A)
- `keybuzz-infra/ansible/playbooks/redis_replication_v3.yml` (PH4-01B)
- `keybuzz-infra/ansible/playbooks/redis_sentinel_v3.yml` (PH4-01C)
- `keybuzz-infra/ansible/playbooks/redis_haproxy_v3.yml` (PH4-03)

**Scripts :**
- `keybuzz-infra/scripts/configure_lbhaproxy_redis.sh` (PH4-03-04)
- `keybuzz-infra/scripts/redis_ha_end_to_end.sh` (PH4-03-05)

**Documentation :**
- `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md` (PH4-03-07)
- `keybuzz-docs/blueprint/infra_v3_overview.md` (PH4-03-08)
- `keybuzz-infra/PH4-01A-redis-standalone-report.md` (PH4-01A)
- `keybuzz-infra/PH4-01B-redis-replication-report.md` (PH4-01B)
- `keybuzz-infra/PH4-01C-redis-sentinel-report.md` (PH4-01C)
- `keybuzz-infra/PH3-03-xfs-mount-report.md` (PH3-03)

---

## ✅ Résumé pour Linear

### IDs des tickets PH4-03

1. **KB-PH4-03-01** – Créer rôle Ansible redis_haproxy_v3
2. **KB-PH4-03-02** – Créer playbook redis_haproxy_v3.yml
3. **KB-PH4-03-03** – Vérifier/adapter la config haproxy.cfg pour include conf.d/
4. **KB-PH4-03-04** – Vérifier / configurer lb-haproxy (service TCP 6379)
5. **KB-PH4-03-05** – Créer script de test redis_ha_end_to_end.sh
6. **KB-PH4-03-06** – Test de failover applicatif via HAProxy
7. **KB-PH4-03-07** – Mise à jour documentation
8. **KB-PH4-03-08** – Mettre à jour la doc produit

### Confirmations

✅ **EPIC KB-PH4-REDIS-HAPROXY dépend de :**
- KB-PH3 (Volumes XFS)
- KB-PH4-01 (Redis HA standalone, réplication, Sentinel)

✅ **EPIC KB-PH4-REDIS-HAPROXY alimente :**
- KB-FEAT-CORE (Applications KeyBuzz core)
- KB-FEAT-CONNECT (Connecteurs marketplaces, Chatwoot, n8n, etc.)

✅ **Documentation liée :**
- `keybuzz-docs/runbooks/phase4_redis_ha_haproxy.md` (PH4-03)
- `keybuzz-docs/blueprint/infra_v3_overview.md` (PH4-03-08)
- `keybuzz-infra/PH4-01A-redis-standalone-report.md` (PH4-01A)
- `keybuzz-infra/PH4-01B-redis-replication-report.md` (PH4-01B)
- `keybuzz-infra/PH4-01C-redis-sentinel-report.md` (PH4-01C)
- `keybuzz-infra/PH3-03-xfs-mount-report.md` (PH3-03)

---

**Statut global :** ✅ Documentation et scripts créés, prêts pour déploiement

