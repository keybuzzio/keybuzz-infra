# PH6-01 – Vault Installation & Initialisation

## Date
2025-12-03

## Contexte

Cette phase visait à installer et initialiser HashiCorp Vault sur `vault-01` (10.0.0.150) pour la gestion centralisée des secrets de l'infrastructure KeyBuzz v3.

## Architecture

```
[vault-01 (10.0.0.150)]
    ↓
[Vault API: https://vault.keybuzz.io:8200]
    ↓
[Storage Backend: file (/data/vault/storage)]
```

## Installation

### Rôle Ansible Créé

- **`ansible/roles/vault_v3/`** : Rôle complet pour l'installation de Vault
  - `tasks/main.yml` : Installation, configuration TLS, systemd
  - `templates/vault.hcl.j2` : Configuration Vault
  - `templates/vault.service.j2` : Service systemd
  - `handlers/main.yml` : Handlers pour redémarrage

### Configuration

**Fichier `/etc/vault.d/vault.hcl` :**
```hcl
ui = true

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/tls/vault.crt"
  tls_key_file  = "/etc/vault.d/tls/vault.key"
  tls_disable   = false
}

cluster_addr = "https://vault.keybuzz.io:8201"
api_addr     = "https://vault.keybuzz.io:8200"

storage "file" {
  path = "/data/vault/storage"
}

disable_mlock = true
```

**Certificat TLS :** Auto-signé pour l'instant (sera remplacé par un certificat Let's Encrypt en production)

### Déploiement

```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/vault_v3.yml \
  | tee /opt/keybuzz/logs/phase6/vault-install.log
```

**Résultat :** ✅ Vault installé et démarré avec succès

## Initialisation

### Script d'Initialisation

Le script `scripts/vault_reset_and_init.py` a été créé pour :
1. Arrêter Vault
2. Supprimer les données existantes (si réinitialisation)
3. Redémarrer Vault
4. Initialiser Vault avec `vault operator init -key-shares=1 -key-threshold=1`
5. Sauvegarder les clés dans `/root/vault_init.txt`
6. Unseal Vault avec l'unseal key

### Clés Générées

**⚠️ IMPORTANT : Les clés suivantes sont des PLACEHOLDERS. Les vraies clés sont stockées dans `/root/vault_init.txt` sur vault-01**

```
Unseal Key 1: <PLACEHOLDER_UNSEAL_KEY>
Initial Root Token: <PLACEHOLDER_ROOT_TOKEN>
```

**⚠️ SECURITÉ :**
- Les vraies clés sont stockées dans `/root/vault_init.txt` sur `vault-01`
- **NE JAMAIS commiter ce fichier dans Git**
- Sauvegarder les clés dans un coffre sécurisé externe (1Password, Bitwarden, etc.)

### Statut Final

```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.21.1
Storage Type    file
HA Enabled      false
```

✅ **Vault est initialisé et unsealed**

## Configuration des Secrets Engines

### Activation KV v2

```bash
vault secrets enable -path=kv kv-v2
```

✅ **KV v2 activé**

### Arborescence des Secrets Créée

Les chemins suivants ont été créés dans Vault :

- `kv/keybuzz/redis` - Mot de passe Redis
- `kv/keybuzz/rabbitmq` - Mot de passe RabbitMQ
- `kv/keybuzz/postgres` - Mot de passe Postgres (à migrer)
- `kv/keybuzz/mariadb` - Mot de passe MariaDB (à migrer)
- `kv/keybuzz/minio` - Credentials MinIO (à migrer)
- `kv/keybuzz/haproxy` - Secrets HAProxy (à migrer)
- `kv/keybuzz/n8n` - Secrets n8n (à migrer)
- `kv/keybuzz/chatwoot` - Secrets Chatwoot (à migrer)

## Migration des Secrets

### Script de Migration

Le script `scripts/migrate_secrets_to_vault.py` a été créé pour migrer les secrets depuis `group_vars` vers Vault.

**Secrets migrés :**
- ✅ `redis_auth_password` → `kv/keybuzz/redis`

**Secrets ignorés (placeholders) :**
- ⚠️ `rabbitmq_password` : Contient une expression Jinja2 avec valeur par défaut

## Prochaines Étapes

- **PH6-02** : Configuration de l'intégration Ansible avec Vault
- **PH6-03** : Migration complète de tous les secrets
- **PH6-04** : Intégration avec les applications (n8n, Chatwoot, etc.)

## Conclusion

✅ **PH6-01 est terminé :**
- Vault installé et configuré sur `vault-01`
- Vault initialisé et unsealed
- Secrets engine KV v2 activé
- Arborescence des secrets créée
- Migration partielle des secrets effectuée

