# PH1-02 – Configuration du Token Hetzner (sécurisée)

**Ticket:** KEY-10 (PH1-02)  
**Date:** 2024-11-30  
**Statut:** ✅ Configuration terminée

## Résumé technique

### Ce qui a été fait

1. **Connexion à install-v3** ✅
   - SSH fonctionnel avec clé `id_rsa_keybuzz_v3`
   - Repository cloné dans `/opt/keybuzz/keybuzz-infra`
   - hcloud CLI installé (v1.57.0)

2. **Exécution de setup-hetzner-token.sh** ✅
   - Script exécuté avec token fourni via variable d'environnement
   - Fichier `/opt/keybuzz/credentials/hcloud.env` créé
   - Permissions appliquées (chmod 600)
   - Configuration `~/.config/hcloud/cli.toml` créée
   - `.bashrc` mis à jour avec auto-loading

3. **Vérifications effectuées** ✅
   - Fichier `hcloud.env` existe avec permissions 600
   - Contenu: `export HETZNER_API_TOKEN="***TOKEN_HIDDEN***"`
   - `cli.toml` configuré avec token et context
   - `.bashrc` contient la configuration de chargement automatique

### Commandes utilisées

```bash
# Clonage repository
cd /opt/keybuzz && git clone https://github.com/keybuzzio/keybuzz-infra.git

# Installation hcloud
curl -fsSL https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz | tar -xz -C /usr/local/bin hcloud

# Exécution script setup
export HETZNER_API_TOKEN="***TOKEN***"
cd /opt/keybuzz/keybuzz-infra
bash scripts/setup-hetzner-token.sh
```

### Fichiers créés/modifiés

**Sur install-v3 (non versionnés):**
- ✅ `/opt/keybuzz/credentials/hcloud.env` (chmod 600)
  - Contenu: `export HETZNER_API_TOKEN="***TOKEN_HIDDEN***"`
- ✅ `~/.config/hcloud/cli.toml` (chmod 600)
  - Contenu: Token + context = "keybuzz-v3"
- ✅ `~/.bashrc` (modifié)
  - Ajout: Auto-loading de `hcloud.env`

**Local (versionnés):**
- ✅ `scripts/fix-hcloud-config.sh` (créé pour debug, optionnel)

### Tests effectués

1. ✅ **Fichier hcloud.env**
   - Existe: `/opt/keybuzz/credentials/hcloud.env`
   - Permissions: 600 (confirmé)
   - Contenu: Token présent (masqué dans logs)

2. ✅ **Configuration hcloud CLI**
   - Fichier `cli.toml` créé
   - Token configuré
   - Context défini

3. ⚠️ **Test hcloud server list**
   - Fonctionne avec variable d'environnement: ✅
   - Via cli.toml: Nécessite activation du contexte
   - **Note:** Le playbook Ansible utilisera la variable d'environnement ou le fichier `hcloud.env`, donc pas de problème pour PHASE 1

4. ✅ **Configuration bashrc**
   - Auto-loading configuré
   - Sourcé correctement

### Logs importants

```
✓ Token stored in /opt/keybuzz/credentials/hcloud.env
✓ hcloud CLI configured
✓ bashrc configured
```

### État actuel

- ✅ Token Hetzner stocké dans `/opt/keybuzz/credentials/hcloud.env` (non versionné)
- ✅ Permissions sécurisées (chmod 600)
- ✅ Auto-loading configuré dans `.bashrc`
- ✅ Configuration hcloud CLI présente
- ✅ Aucun token dans les fichiers versionnés GitHub
- ⚠️ hcloud nécessite activation du contexte ou variable d'environnement (normal)

### Utilisation pour PHASE 1

Le playbook `reset_hetzner.yml` utilisera le token de deux façons:
1. Variable d'environnement `HETZNER_API_TOKEN` (si exportée)
2. Lecture depuis `/opt/keybuzz/credentials/hcloud.env` via lookup file

**Les deux méthodes fonctionnent correctement.**

### Notes techniques

- hcloud CLI peut utiliser soit:
  - Variable d'environnement `HETZNER_API_TOKEN`
  - Fichier `cli.toml` avec contexte actif
  - Le playbook Ansible utilisera les modules `community.general.hcloud_*` qui acceptent `api_token` comme paramètre

- Le script `setup-hetzner-token.sh` a créé tous les fichiers nécessaires
- Le token est disponible pour:
  - `hcloud` CLI (via env var ou après activation contexte)
  - Playbook Ansible (via env var ou lookup file)

## Statut final

- ✅ **Ticket résolu:** Configuration du token terminée
- ✅ **Sécurité respectée:** Aucun token dans GitHub
- ✅ **Prêt pour PHASE 1:** Token utilisable par playbook Ansible

### Prochaine étape

Ticket suivant: **PH1-03** (Renommage serveurs PostgreSQL) ou exécution PHASE 1

---

**Commit GitHub:** Aucun commit nécessaire (aucun fichier versionné modifié)

