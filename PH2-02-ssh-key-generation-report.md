# PH2-02 – Génération Clé SSH install-v3

**Ticket Linear:** KEY-21 (PH2-02)  
**Date:** 2024-11-30  
**Statut:** ✅ Clé SSH générée et validée

---

## 🎯 Objectif

Créer la clé SSH unique utilisée par `install-v3` pour se connecter à tous les serveurs rebuildés (47 serveurs) dans le cadre du déploiement du SSH mesh.

---

## ✅ Résultats

### 1. Vérification Existence Clé

**Chemin :** `/root/.ssh/id_rsa_keybuzz_v3`

**État :**
- ✅ Clé privée : `/root/.ssh/id_rsa_keybuzz_v3` - **EXISTS**
- ✅ Clé publique : `/root/.ssh/id_rsa_keybuzz_v3.pub` - **EXISTS**

**Note :** La clé a été générée (ou existait déjà). Vérification idempotente effectuée.

---

### 2. Permissions

**Vérification des permissions :**

```
/root/.ssh/id_rsa_keybuzz_v3        : 600 (rw-------) ✅ Correct
/root/.ssh/id_rsa_keybuzz_v3.pub    : 644 (rw-r--r--) ✅ Correct
/root/.ssh/                          : 700 (drwx------) ✅ Correct
```

**✅ Résultat :** Toutes les permissions sont correctes.

---

### 3. Détails de la Clé

**Type :** RSA 4096 bits  
**Commentaire :** `install-v3-keybuzz-v3`  
**Générée avec :** `ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa_keybuzz_v3 -N "" -C "install-v3-keybuzz-v3"`

**Fingerprint (SHA256) :**
```
4096 SHA256:zz5iU+si8Yd6MfXKD5gzCEZg5Od1WwLf1xbMJQh7ORs install-v3-keybuzz-v3 (RSA)
```

---

### 4. Clé Publique (extrait)

**Format :** `ssh-rsa [key_data] install-v3-keybuzz-v3`

*(Clé publique complète disponible dans `/root/.ssh/id_rsa_keybuzz_v3.pub` sur install-v3)*

**Note de sécurité :** La clé publique complète n'est pas incluse dans ce rapport pour des raisons de sécurité. Elle sera déployée sur les serveurs via `ssh-copy-id` en PH2-04.

---

## 📋 Configuration

### Utilisation dans Ansible

Cette clé sera utilisée dans `ansible/inventory/hosts.yml` :

```yaml
all:
  vars:
    ansible_ssh_private_key_file: /root/.ssh/id_rsa_keybuzz_v3
```

### Utilisation pour SSH/ssh-copy-id

Les scripts PH2-03/04/05 utiliseront :

```bash
# Connexion SSH
ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@<IP_PUBLIC>

# Déploiement de la clé publique
ssh-copy-id -i /root/.ssh/id_rsa_keybuzz_v3.pub -o StrictHostKeyChecking=no root@<IP_PUBLIC>
```

---

## 🚀 Prochaines Étapes

Cette clé sera déployée sur **47 serveurs rebuildés** en **PH2-04** :

- ✅ Clé générée et prête
- ⏳ PH2-03 : Purge known_hosts (si nécessaire)
- ⏳ PH2-04 : Déploiement via ssh-copy-id sur les 47 serveurs
- ⏳ PH2-05 : Vérification SSH mesh

---

## ✅ Validation

**✅ Clé SSH générée :**
- Clé privée : `/root/.ssh/id_rsa_keybuzz_v3` (600)
- Clé publique : `/root/.ssh/id_rsa_keybuzz_v3.pub` (644)
- Permissions correctes
- Sans passphrase (prête pour automation)
- Type RSA 4096 bits

**✅ Prêt pour PH2-03/04/05 :**
- Clé disponible sur `install-v3`
- Format correct pour `ssh-copy-id`
- Prête pour déploiement automatique

---

**Généré le :** 2024-11-30  
**Par :** Script de génération PH2-02  
**Status :** ✅ VALIDÉ - Clé prête pour déploiement SSH mesh

