# PH6-04 – AppRole Ansible & Intégration Complète

## Date
2025-12-03

## Contexte

Cette phase visait à créer un AppRole HashiCorp Vault dédié à Ansible avec des permissions en lecture seule, permettant à Ansible de récupérer les secrets sans utiliser le root token.

## Configuration AppRole

### Policy Créée

**Policy `ansible-policy` :**
```hcl
path "kv/data/keybuzz/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/*" {
  capabilities = ["read"]
}
```

Cette policy permet uniquement la lecture des secrets dans le chemin `kv/keybuzz/*`, sans possibilité d'écriture ou de suppression.

### AppRole Créé

**AppRole `ansible` :**
- **Token Policies** : `ansible-policy`
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)
- **Bind Secret ID** : true

### Identifiants Générés

**⚠️ IMPORTANT : Les identifiants suivants sont des PLACEHOLDERS. Les vrais identifiants sont stockés dans `/root/ansible_role_id.txt` et `/root/ansible_secret_id.txt` sur `install-v3`**

```
Role ID: <PLACEHOLDER_ROLE_ID>
Secret ID: <PLACEHOLDER_SECRET_ID>
```

## Script de Configuration

Le script `scripts/vault_setup_approle.py` automatise :
1. Création de la policy `ansible-policy`
2. Activation de l'auth method `approle`
3. Création de l'AppRole `ansible`
4. Génération et sauvegarde du `role_id` et `secret_id`

**Résultat :**
```
✅ Policy créée
✅ AppRole activé
✅ AppRole créé
✅ role_id récupéré et sauvegardé
✅ secret_id généré et sauvegardé
```

## Intégration dans Ansible

### Configuration `ansible.cfg`

```ini
[defaults]
vault_address = "https://vault.keybuzz.io:8200"
vault_verify = false
```

### Utilisation dans les Variables

Les variables utilisent maintenant le lookup Vault avec AppRole :

```yaml
redis_auth_password: "{{ lookup('community.hashi_vault.hashi_vault',
  'secret=kv/keybuzz/redis:password',
  url='https://vault.keybuzz.io:8200',
  auth_method='approle',
  role_id=lookup('file', '/root/ansible_role_id.txt'),
  secret_id=lookup('file', '/root/ansible_secret_id.txt'),
  verify=False) }}"
```

### Avantages de l'AppRole

1. **Sécurité** : Pas besoin du root token pour Ansible
2. **Permissions limitées** : Lecture seule sur `kv/keybuzz/*`
3. **Rotation** : Le `secret_id` peut être régénéré sans affecter le `role_id`
4. **Traçabilité** : Les tokens générés sont liés à l'AppRole `ansible`

## Test de l'Intégration

### Test de Lookup

```bash
# Tester le lookup Vault avec AppRole
python3 scripts/test_vault_lookup.py
```

**Résultat attendu :** Le mot de passe Redis récupéré depuis Vault

### Test avec Playbook

```bash
# Tester un playbook complet
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/redis_standalone_v3.yml \
  --check
```

**Résultat attendu :** Le playbook s'exécute sans erreur, les variables sont récupérées depuis Vault

## Sécurité et Bonnes Pratiques

### Rotation du Secret ID

Pour régénérer le `secret_id` :

```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="<root_token>"

# Générer un nouveau secret_id
vault write -format=json -f auth/approle/role/ansible/secret-id | jq -r .data.secret_id > /root/ansible_secret_id.txt
chmod 600 /root/ansible_secret_id.txt
```

### Monitoring

Surveiller l'utilisation de l'AppRole :

```bash
# Lister les tokens actifs pour l'AppRole
vault list auth/token/accessors
vault token lookup <accessor>
```

## Prochaines Étapes

- **PH6-05** : Intégration avec les applications (n8n, Chatwoot, KeyBuzz Apps)
- **PH6-06** : Documentation finale et tests complets de tous les playbooks

## Conclusion

✅ **PH6-04 est terminé :**
- AppRole `ansible` créé avec permissions en lecture seule
- Policy `ansible-policy` configurée
- Identifiants AppRole générés et sauvegardés
- Intégration Ansible fonctionnelle avec AppRole
- Aucun root token nécessaire pour Ansible

