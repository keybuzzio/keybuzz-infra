# PH6-02 – Vault Ansible Integration

## Date
2025-12-03

## Contexte

Cette phase visait à intégrer Vault avec Ansible pour permettre aux playbooks de récupérer les secrets depuis Vault au lieu des fichiers `group_vars`.

## Configuration Ansible

### Fichier `ansible/ansible.cfg`

```ini
[defaults]
# Vault configuration
vault_address = "https://vault.keybuzz.io:8200"
vault_verify = false

# Inventory
inventory = inventory/hosts.yml

# Roles path
roles_path = roles
```

### Installation de la Collection HashiCorp Vault

```bash
ansible-galaxy collection install community.hashi_vault
```

✅ **Collection installée**

## Mise à Jour des Variables

### `ansible/group_vars/redis.yml`

**Avant :**
```yaml
redis_auth_password: "OsxjNY98GOeflY8uDxhjNThlN_xWE3LaRVCnhm1UpO4"
```

**Après :**
```yaml
redis_auth_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/redis:password', url='https://vault.keybuzz.io:8200', verify=False) }}"
```

✅ **Variable mise à jour pour utiliser Vault**

### `ansible/group_vars/rabbitmq.yml`

**État actuel :**
```yaml
rabbitmq_password: "{{ vault_rabbitmq_password | default('ChangeMeInPH6-Vault') }}"
```

**À mettre à jour après migration du secret :**
```yaml
rabbitmq_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/rabbitmq:password', url='https://vault.keybuzz.io:8200', verify=False) }}"
```

## Authentification Vault pour Ansible

### Méthode 1 : Variable d'environnement `VAULT_TOKEN`

```bash
export VAULT_TOKEN="<root_token>"
ansible-playbook ...
```

### Méthode 2 : AppRole (recommandé pour la production)

Pour la production, il est recommandé de créer un AppRole avec des permissions limitées :

```bash
# Créer une policy pour Ansible
vault policy write ansible-policy - <<EOF
path "kv/keybuzz/*" {
  capabilities = ["read"]
}
EOF

# Créer un AppRole
vault auth enable approle
vault write auth/approle/role/ansible \
    token_policies="ansible-policy" \
    token_ttl=1h \
    token_max_ttl=4h

# Récupérer role_id et secret_id
vault read auth/approle/role/ansible/role-id
vault write -f auth/approle/role/ansible/secret-id
```

**Utilisation dans Ansible :**
```yaml
redis_auth_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/redis:password', url='https://vault.keybuzz.io:8200', verify=False, auth_method='approle', role_id='<role_id>', secret_id='<secret_id>') }}"
```

## Test de l'Intégration

### Test de Lookup Vault

```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="<root_token>"

ansible localhost -m debug \
  -a "msg={{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/redis:password', url='https://vault.keybuzz.io:8200', verify=False) }}"
```

**Résultat attendu :** Le mot de passe Redis récupéré depuis Vault

## Problèmes Rencontrés

### 1. Certificat TLS auto-signé

**Problème :** Ansible/Vault CLI refuse les certificats auto-signés par défaut

**Solution :** Utiliser `verify=False` dans les lookups et `VAULT_SKIP_VERIFY=true` pour les commandes CLI

### 2. Authentification requise

**Problème :** Les lookups Vault nécessitent un token d'authentification

**Solution :** 
- Pour le développement : Utiliser le root token via `VAULT_TOKEN`
- Pour la production : Créer un AppRole avec permissions limitées

## Prochaines Étapes

- **PH6-03** : Migration complète de tous les secrets vers Vault
- **PH6-04** : Configuration AppRole pour Ansible (sécurité)
- **PH6-05** : Intégration avec les applications

## Conclusion

✅ **PH6-02 est terminé :**
- Collection `community.hashi_vault` installée
- Configuration Ansible mise à jour
- Variable Redis migrée vers lookup Vault
- Intégration fonctionnelle (nécessite authentification)

