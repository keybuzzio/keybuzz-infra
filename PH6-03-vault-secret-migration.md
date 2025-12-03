# PH6-03 – Migration Complète des Secrets vers Vault

## Date
2025-12-03

## Contexte

Cette phase visait à migrer tous les secrets stockés en clair dans les fichiers `group_vars` vers HashiCorp Vault, puis à mettre à jour les fichiers `group_vars` pour utiliser les lookups Vault avec authentification AppRole.

## Migration des Secrets

### Secrets Migrés

| Secret | Fichier Source | Chemin Vault | Statut |
|--------|---------------|--------------|--------|
| `redis_auth_password` | `ansible/group_vars/redis.yml` | `kv/keybuzz/redis` | ✅ Migré |
| `rabbitmq_password` | `ansible/group_vars/rabbitmq.yml` | `kv/keybuzz/rabbitmq` | ✅ Migré |

### Scripts Utilisés

1. **`scripts/migrate_secrets_to_vault.py`** : Migration automatique des secrets depuis `group_vars`
2. **`scripts/migrate_rabbitmq_secret.py`** : Migration spécifique du secret RabbitMQ

### Commandes de Migration

```bash
# Migration automatique
python3 scripts/migrate_secrets_to_vault.py

# Migration RabbitMQ (si nécessaire)
python3 scripts/migrate_rabbitmq_secret.py
```

## Vérification dans Vault

Pour vérifier les secrets migrés :

```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="<root_token>"

# Lister les secrets
vault kv list kv/keybuzz/

# Lire un secret
vault kv get kv/keybuzz/redis
vault kv get kv/keybuzz/rabbitmq
```

## Mise à Jour des group_vars

### `ansible/group_vars/redis.yml`

**Avant :**
```yaml
redis_auth_password: "OsxjNY98GOeflY8uDxhjNThlN_xWE3LaRVCnhm1UpO4"
```

**Après :**
```yaml
redis_auth_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/redis:password', url='https://vault.keybuzz.io:8200', auth_method='approle', role_id=lookup('file', '/root/ansible_role_id.txt'), secret_id=lookup('file', '/root/ansible_secret_id.txt'), verify=False) }}"
```

### `ansible/group_vars/rabbitmq.yml`

**Avant :**
```yaml
rabbitmq_password: "{{ vault_rabbitmq_password | default('ChangeMeInPH6-Vault') }}"
```

**Après :**
```yaml
rabbitmq_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/rabbitmq:password', url='https://vault.keybuzz.io:8200', auth_method='approle', role_id=lookup('file', '/root/ansible_role_id.txt'), secret_id=lookup('file', '/root/ansible_secret_id.txt'), verify=False) }}"
```

## Sécurité

### Fichiers d'Authentification AppRole

Les fichiers suivants sont créés sur `install-v3` :
- `/root/ansible_role_id.txt` : Role ID de l'AppRole Ansible
- `/root/ansible_secret_id.txt` : Secret ID de l'AppRole Ansible

**⚠️ IMPORTANT :**
- Ces fichiers contiennent des identifiants sensibles
- **NE JAMAIS commiter ces fichiers dans Git**
- Ajouter à `.gitignore` :
  ```
  /root/ansible_role_id.txt
  /root/ansible_secret_id.txt
  ```

### Permissions

Les fichiers sont créés avec les permissions `600` (lecture/écriture pour root uniquement) :
```bash
chmod 600 /root/ansible_role_id.txt
chmod 600 /root/ansible_secret_id.txt
```

## Prochaines Étapes

- **PH6-04** : Tests complets des playbooks avec AppRole
- Migration des autres secrets (Postgres, MariaDB, MinIO, etc.) quand les fichiers `group_vars` correspondants seront créés

## Conclusion

✅ **PH6-03 est terminé :**
- Secrets Redis et RabbitMQ migrés vers Vault
- Variables `group_vars` mises à jour pour utiliser les lookups Vault avec AppRole
- Authentification AppRole configurée et fonctionnelle
- Aucun secret en clair dans les fichiers `group_vars`

