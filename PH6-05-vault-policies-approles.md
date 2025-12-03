# PH6-05 – Vault Policies & AppRoles pour Applications

## Date
2025-12-03

## Contexte

Ce document détaille les policies et AppRoles créés pour chaque application dans le cadre de PH6-05.

## Architecture de Sécurité

### Principe de Séparation Minimale

Chaque application a :
- **Sa propre policy** : Permissions limitées à ses propres secrets
- **Son propre AppRole** : Authentification isolée
- **Ses propres identifiants** : Role ID et Secret ID uniques

### Avantages

1. **Isolation** : Une compromission d'une application ne compromet pas les autres
2. **Traçabilité** : Chaque token peut être tracé à son application
3. **Rotation** : Rotation indépendante des identifiants par application
4. **Audit** : Logs séparés par application

## Policies Détaillées

### chatwoot-policy

```hcl
path "kv/data/keybuzz/apps/chatwoot/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/apps/chatwoot/*" {
  capabilities = ["read"]
}
```

**Permissions :**
- ✅ Lecture des secrets dans `kv/keybuzz/apps/chatwoot/*`
- ❌ Pas d'écriture
- ❌ Pas d'accès aux autres applications

### n8n-policy

```hcl
path "kv/data/keybuzz/apps/n8n/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/apps/n8n/*" {
  capabilities = ["read"]
}
```

**Permissions :**
- ✅ Lecture des secrets dans `kv/keybuzz/apps/n8n/*`
- ❌ Pas d'écriture
- ❌ Pas d'accès aux autres applications

### keybuzz-api-policy

```hcl
path "kv/data/keybuzz/apps/keybuzz-api/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/apps/keybuzz-api/*" {
  capabilities = ["read"]
}
```

**Permissions :**
- ✅ Lecture des secrets dans `kv/keybuzz/apps/keybuzz-api/*`
- ❌ Pas d'écriture
- ❌ Pas d'accès aux autres applications

### keybuzz-workers-policy

```hcl
path "kv/data/keybuzz/apps/keybuzz-workers/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/apps/keybuzz-workers/*" {
  capabilities = ["read"]
}
```

**Permissions :**
- ✅ Lecture des secrets dans `kv/keybuzz/apps/keybuzz-workers/*`
- ❌ Pas d'écriture
- ❌ Pas d'accès aux autres applications

## AppRoles Détaillés

### AppRole chatwoot

```bash
vault write auth/approle/role/chatwoot \
    token_policies="chatwoot-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

**Configuration :**
- **Token Policies** : `chatwoot-policy`
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)

### AppRole n8n

```bash
vault write auth/approle/role/n8n \
    token_policies="n8n-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

**Configuration :**
- **Token Policies** : `n8n-policy`
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)

### AppRole keybuzz-api

```bash
vault write auth/approle/role/keybuzz-api \
    token_policies="keybuzz-api-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

**Configuration :**
- **Token Policies** : `keybuzz-api-policy`
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)

### AppRole keybuzz-workers

```bash
vault write auth/approle/role/keybuzz-workers \
    token_policies="keybuzz-workers-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

**Configuration :**
- **Token Policies** : `keybuzz-workers-policy`
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)

## Gestion des Identifiants

### Stockage

Les identifiants sont stockés dans `roles/` sur `install-v3` :
- Format JSON pour faciliter le parsing
- Permissions `600` (root uniquement)
- **NE JAMAIS commités dans Git**

### Structure des Fichiers

**`roles/{app}-role.json` :**
```json
{
  "role_id": "ba6c12bc-d415-9b42-9211-b08506619acc"
}
```

**`roles/{app}-secret.json` :**
```json
{
  "secret_id": "507a4057-08e5-43ae-5..."
}
```

### Rotation

Pour régénérer un Secret ID :

```bash
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN="<root_token>"

# Régénérer le secret_id
vault write -format=json -f auth/approle/role/{app}/secret-id | \
  jq -r .data.secret_id > roles/{app}-secret.json
```

## Utilisation dans Kubernetes

### Injection via Init Container

Les identifiants AppRole peuvent être injectés dans les pods Kubernetes via :
1. **Init Container** : Récupère les secrets depuis Vault
2. **Secret Kubernetes** : Stocke les secrets récupérés
3. **Volume Mount** : Expose les secrets aux containers

### Exemple avec Ansible

```yaml
- name: Create Kubernetes Secret from Vault
  k8s:
    state: present
    definition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: chatwoot-secrets
      data:
        database-url: "{{ lookup('community.hashi_vault.hashi_vault', 
          'secret=kv/keybuzz/apps/chatwoot:database-url',
          url='https://vault.keybuzz.io:8200',
          auth_method='approle',
          role_id=lookup('file', '/vault/chatwoot-role-id'),
          secret_id=lookup('file', '/vault/chatwoot-secret-id'),
          verify=False) | b64encode }}"
```

## Monitoring et Audit

### Vérification des Tokens Actifs

```bash
# Lister les tokens actifs pour un AppRole
vault list auth/token/accessors

# Inspecter un token
vault token lookup <accessor>
```

### Logs Vault

Les accès aux secrets sont loggés dans Vault avec :
- **AppRole utilisé** : Identifie l'application
- **Secret accédé** : Chemin complet
- **Timestamp** : Date et heure de l'accès

## Conclusion

✅ **Configuration complète :**
- 4 policies créées avec permissions minimales
- 4 AppRoles créés avec isolation complète
- Identifiants générés et sécurisés
- Prêt pour intégration Kubernetes (PH9/PH10)

