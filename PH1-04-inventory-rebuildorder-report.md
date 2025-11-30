# PH1-04 – Génération automatique inventaire & rebuild_order

**Ticket:** KEY-12 (PH1-04)  
**Date:** 2024-11-30  
**Statut:** ✅ Génération complétée et validée

## Résumé technique

### Ce qui a été fait

1. **Génération de l'inventaire Ansible** ✅
   - Fichier généré: `ansible/inventory/hosts.yml`
   - Script utilisé: `scripts/generate_inventory.py`
   - Source: `servers/servers_v3.tsv`

2. **Génération du rebuild order** ✅
   - Fichier généré: `servers/rebuild_order_v3.json`
   - Script utilisé: `scripts/generate_rebuild_order.py`
   - Source: `servers/servers_v3.tsv`

3. **Vérification de cohérence** ✅
   - Script de vérification: `scripts/verify-inventory-rebuildorder.py`
   - Toutes les validations passées

## Détails de l'inventaire Ansible

### Statistiques

- **Total serveurs:** 49
- **Total groupes:** 21
- **Format:** YAML
- **ansible_host:** IP privée (10.0.0.x)
- **ansible_ssh_private_key_file:** `/root/.ssh/id_rsa_keybuzz_v3`

### Répartition par groupes

| Groupe | Nombre de serveurs |
|--------|-------------------|
| bastions | 2 |
| k8s_masters | 3 |
| k8s_workers | 5 |
| db_postgres | 3 |
| db_mariadb | 3 |
| db_proxysql | 2 |
| db_temporal | 1 |
| db_analytics | 1 |
| redis | 3 |
| rabbitmq | 3 |
| minio | 3 |
| vector_db | 1 |
| vault | 1 |
| siem | 1 |
| monitoring | 1 |
| backup | 1 |
| mail_core | 1 |
| mail_mx | 2 |
| builder | 1 |
| apps_misc | 9 |
| lb_internal | 2 |
| **TOTAL** | **49** |

### Variables globales (all:vars)

```yaml
ansible_user: root
ansible_python_interpreter: /usr/bin/python3
ansible_ssh_private_key_file: /root/.ssh/id_rsa_keybuzz_v3
os_version: ubuntu-24.04
```

## Détails du rebuild_order

### Métadonnées

```json
{
  "created": "2024-11-30",
  "purpose": "Ordered list of servers to rebuild for KeyBuzz v3",
  "batch_size": 5,
  "excluded_servers": ["install-01", "install-v3"],
  "total_servers": 47,
  "total_batches": 10
}
```

### Statistiques

- **Serveurs rebuildables:** 47 (49 - 2 exclus)
- **Batches:** 10 (9 batches de 5 serveurs + 1 batch de 2 serveurs)
- **Serveurs exclus:** `install-01`, `install-v3`

### Répartition par batches

| Batch | Nombre de serveurs |
|-------|-------------------|
| Batch 1 | 5 |
| Batch 2 | 5 |
| Batch 3 | 5 |
| Batch 4 | 5 |
| Batch 5 | 5 |
| Batch 6 | 5 |
| Batch 7 | 5 |
| Batch 8 | 5 |
| Batch 9 | 5 |
| Batch 10 | 2 |
| **TOTAL** | **47** |

### Tailles de volumes par rôle

| Rôle | Taille (GB) |
|------|-------------|
| k8s-master | 20 |
| k8s-worker | 50 |
| db-postgres | 100 |
| db-mariadb | 100 |
| db-proxysql | 20 |
| redis | 20 |
| rabbitmq | 30 |
| minio | 200 |
| backup | 500 |
| monitoring | 50 |
| builder | 100 |
| vault | 20 |
| siem | 50 |
| vector-db | 50 |
| (autres) | 20-50 |

## Validations effectuées

### ✓ Inventaire

- [x] Total serveurs = 49
- [x] Tous les groupes attendus présents (21 groupes)
- [x] `ansible_host` = IP privée pour tous les serveurs
- [x] `ansible_ssh_private_key_file` configuré correctement
- [x] Syntaxe YAML valide

### ✓ Rebuild Order

- [x] Total serveurs rebuildables = 47
- [x] Total batches = 10
- [x] Aucun serveur manquant
- [x] Aucun volume avec size = 0
- [x] Aucun doublon de hostname
- [x] `install-01` et `install-v3` correctement exclus
- [x] Tous les rôles v3 présents
- [x] Tous les serveurs répartis dans les batches

### ✓ Cohérence globale

- [x] Les 49 serveurs de l'inventaire correspondent aux 47 rebuildables + 2 exclus
- [x] Tous les serveurs rebuildables sont présents dans l'inventaire
- [x] Aucune incohérence détectée

## Commandes exécutées

```bash
# 1. Mise à jour du repository
cd /opt/keybuzz/keybuzz-infra
git pull --rebase

# 2. Génération de l'inventaire
python3 scripts/generate_inventory.py > ansible/inventory/hosts.yml

# 3. Génération du rebuild order
python3 scripts/generate_rebuild_order.py

# 4. Vérification de cohérence
python3 scripts/verify-inventory-rebuildorder.py
```

## Fichiers créés/modifiés

### Fichiers générés

- ✅ `ansible/inventory/hosts.yml` - Inventaire Ansible (49 serveurs, 21 groupes)
- ✅ `servers/rebuild_order_v3.json` - Ordre de rebuild (47 serveurs, 10 batches)

### Scripts créés

- ✅ `scripts/verify-inventory-rebuildorder.py` - Script de vérification de cohérence

### Scripts utilisés (déjà existants)

- ✅ `scripts/generate_inventory.py` - Génération de l'inventaire
- ✅ `scripts/generate_rebuild_order.py` - Génération du rebuild order

## Résultat de la vérification

```
PH1-04 - Verification of Inventory and Rebuild Order
======================================================================

✓ Inventory loaded successfully
✓ Rebuild order loaded successfully
✓ Total servers in inventory: 49
✓ Total servers to rebuild: 47
✓ Total batches: 10
✓ install-01 correctly excluded
✓ install-v3 correctly excluded
✓ No duplicate hostnames in rebuild list
✓ All volumes have valid sizes
✓ All servers are in batches
✓ Inventory has correct number of servers
✓ Rebuild order has correct number of servers
✓ Correct number of batches
✓ All expected groups present

======================================================================
✓✓✓ ALL VERIFICATIONS PASSED ✓✓✓
```

## Commit GitHub

- **Commit:** `feat: regenerate inventory & rebuild_order (PH1-04)`
- **Fichiers modifiés:**
  - `ansible/inventory/hosts.yml`
  - `servers/rebuild_order_v3.json`
  - `scripts/verify-inventory-rebuildorder.py`

## Anomalies détectées

**Aucune anomalie détectée.** ✅

Toutes les validations sont passées avec succès.

## Observations

1. **Génération automatique fonctionnelle** ✅
   - Les scripts Python génèrent correctement les fichiers à partir de `servers_v3.tsv`
   - Processus reproductible et fiable

2. **Cohérence totale** ✅
   - Inventaire et rebuild_order sont parfaitement alignés
   - Tous les serveurs sont présents où ils doivent être
   - Aucun serveur manquant ou en double

3. **Répartition équilibrée** ✅
   - Les batches sont équilibrés (5 serveurs chacun, dernier batch: 2)
   - Les groupes Ansible sont correctement définis

## Statut final

- ✅ **Ticket complètement résolu:** Génération automatique fonctionnelle
- ✅ **Inventaire généré:** 49 serveurs, 21 groupes
- ✅ **Rebuild order généré:** 47 serveurs, 10 batches
- ✅ **Toutes les validations passées**
- ✅ **Fichiers committés et poussés sur GitHub**

### Prochaine étape

Ticket suivant: **PH1-05**

---

**Scripts utilisés:**
- `scripts/generate_inventory.py`
- `scripts/generate_rebuild_order.py`
- `scripts/verify-inventory-rebuildorder.py`

