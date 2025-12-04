# PH8-02 - MariaDB Galera Rebuild Status

**Date**: 2025-12-04  
**Statut**: 🚧 En attente - Scripts prêts, nécessite configuration SSH sur serveurs rebuilds  
**Objectif**: Rebuild complet des serveurs MariaDB et ProxySQL

## Résumé

Tentative de rebuild complet des serveurs MariaDB et ProxySQL. Les scripts de rebuild ont été créés mais l'exécution rencontre des problèmes de connectivité réseau et de bootstrap Galera.

## État Actuel

### Connectivité Serveurs

- **maria-01 (10.0.0.170)** : ❌ Inaccessible (SSH timeout)
- **maria-02 (10.0.0.171)** : ❌ Inaccessible (SSH timeout)
- **maria-03 (10.0.0.172)** : ✅ Accessible
- **proxysql-01 (10.0.0.173)** : ✅ Accessible
- **proxysql-02 (10.0.0.174)** : ✅ Accessible

### Scripts Créés ✅

1. **`scripts/ph8-02-rebuild-servers.sh`** : Rebuild via hcloud API (nécessite token)
2. **`scripts/ph8-02-format-volumes.sh`** : Formatage XFS et montage volumes
3. **`scripts/ph8-02-deploy-ssh-keys.sh`** : Déploiement clés SSH
4. **`scripts/ph8-02-complete-rebuild.sh`** : Processus complet de rebuild
5. **`scripts/ph8-02-simple-rebuild.sh`** : Rebuild simplifié (reconfiguration)
6. **`scripts/ph8-02-final-bootstrap.sh`** : Bootstrap final avec corrections

### Corrections Appliquées ✅

1. **Template galera.cnf.j2** : Suppression de `wsrep_replicate_myisam` et `pxc_strict_mode` (variables non supportées)
2. **Playbook proxysql_v3** : Correction syntaxe YAML ligne 100

### Problèmes Rencontrés

1. **Connectivité réseau** :
   - maria-01 et maria-02 ne sont pas accessibles via SSH
   - Problème de firewall ou serveurs arrêtés

2. **Bootstrap Galera** :
   - MariaDB échoue au démarrage avec signal fatal
   - Variables Galera non supportées dans la configuration
   - Problème d'initialisation de la base de données

3. **hcloud API** :
   - Token non configuré sur install-v3
   - Impossible de rebuild via API sans token

## Actions Réalisées

### 1. Scripts de Rebuild

Tous les scripts nécessaires ont été créés et sont prêts à être exécutés une fois la connectivité rétablie.

### 2. Corrections Configuration

- Template `galera.cnf.j2` corrigé
- Playbook `proxysql_v3` corrigé
- Scripts de bootstrap améliorés

### 3. Documentation

Rapport créé avec état actuel et procédures.

## État Actuel

### Serveurs Rebuilds ✅
- Les 5 serveurs ont été rebuilds manuellement
- Serveurs accessibles mais nécessitent configuration SSH

### Problème Identifié ⚠️
- Les serveurs rebuilds n'ont pas les clés SSH configurées
- Impossible de se connecter sans clés SSH ou mot de passe
- Les scripts sont prêts mais nécessitent SSH fonctionnel

## Prochaines Étapes

### 1. Configurer les Clés SSH

**Option A - Via cloud-init lors du rebuild** (recommandé) :
- Configurer cloud-init avec la clé SSH publique lors du rebuild
- La clé sera automatiquement déployée

**Option B - Déploiement manuel depuis install-v3** :
```bash
cd /opt/keybuzz/keybuzz-infra
# Si les serveurs acceptent les mots de passe temporairement
bash scripts/ph8-02-deploy-ssh-keys-manual.sh
```

**Option C - Via Hetzner Cloud Console** :
- Ajouter la clé SSH publique dans les paramètres du serveur
- Ou utiliser cloud-init avec user-data

### 2. Une fois SSH Configuré

Exécuter le script complet :
```bash
cd /opt/keybuzz/keybuzz-infra
bash scripts/ph8-02-complete-deployment.sh
```

Ou utiliser le script avec attente automatique :
```bash
bash scripts/ph8-02-wait-and-deploy.sh
```

### 2. Rebuild via hcloud (si token configuré)

```bash
cd /opt/keybuzz/keybuzz-infra
export HCLOUD_TOKEN="<token>"
bash scripts/ph8-02-rebuild-servers.sh
```

### 3. Rebuild Simplifié (reconfiguration)

```bash
cd /opt/keybuzz/keybuzz-infra
bash scripts/ph8-02-simple-rebuild.sh
```

### 4. Bootstrap Final

```bash
cd /opt/keybuzz/keybuzz-infra
bash scripts/ph8-02-final-bootstrap.sh
```

## Commandes de Vérification

### Vérifier Cluster

```bash
bash scripts/ph8-01-check-cluster.sh
bash scripts/mariadb_ha_checks.sh
```

### Vérifier ProxySQL

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml --limit proxysql-01,proxysql-02
```

### Tests End-to-End

```bash
bash scripts/mariadb_ha_end_to_end.sh
```

## Résultats Attendus

Une fois le rebuild réussi :

- **wsrep_cluster_size** : 1 (maria-03 seul) ou 3 (si maria-01 et maria-02 accessibles)
- **wsrep_local_state_comment** : 'Synced' sur tous les nœuds
- **ProxySQL** : Déployé et configuré avec backends MariaDB
- **Tests E2E** : CREATE DATABASE, INSERT, SELECT réussis

## Conclusion

Scripts et corrections créés. Le rebuild nécessite :
1. Résolution des problèmes de connectivité réseau (maria-01, maria-02)
2. Configuration du token hcloud si rebuild via API souhaité
3. Bootstrap réussi sur au moins un nœud (maria-03 accessible)

Une fois la connectivité rétablie, les scripts permettront de finaliser le rebuild automatiquement.

