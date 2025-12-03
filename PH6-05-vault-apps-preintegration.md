# PH6-05 – Vault Application Integration (Preparation Phase)

## Date
2025-12-03

## Contexte

Cette phase visait à préparer l'intégration complète de Vault pour les applications (n8n, Chatwoot, KeyBuzz Apps) sans encore installer les applications. L'objectif était de créer toute l'infrastructure Vault nécessaire pour PH9 (Kubernetes) et PH10 (Applications).

## Structure des Chemins Vault

### Arborescence Créée

```
kv/keybuzz/apps/
├── info
├── chatwoot/
│   ├── database-url
│   ├── redis-url
│   ├── rabbitmq-url
│   └── smtp-password
├── n8n/
│   ├── rabbitmq-url
│   ├── redis-url
│   ├── webhook-secret
│   └── jwt-secret
├── keybuzz-api/
│   ├── postgres-url
│   ├── redis-url
│   ├── rabbitmq-url
│   └── jwt-secret
└── keybuzz-workers/
    ├── api-token
    ├── rabbitmq-url
    └── redis-url
```

### Script de Création

Le script `scripts/vault_setup_apps_structure.py` automatise la création de cette structure.

**Résultat :**
- ✅ 16 secrets créés avec valeurs placeholder
- ✅ Structure prête pour les applications

## Policies par Application

### Policies Créées

1. **`chatwoot-policy`** : Lecture seule sur `kv/keybuzz/apps/chatwoot/*`
2. **`n8n-policy`** : Lecture seule sur `kv/keybuzz/apps/n8n/*`
3. **`keybuzz-api-policy`** : Lecture seule sur `kv/keybuzz/apps/keybuzz-api/*`
4. **`keybuzz-workers-policy`** : Lecture seule sur `kv/keybuzz/apps/keybuzz-workers/*`

### Fichiers de Policies

Les policies sont stockées dans `scripts/vault_policies/` :
- `policy-chatwoot.hcl`
- `policy-n8n.hcl`
- `policy-keybuzz-api.hcl`
- `policy-keybuzz-workers.hcl`

### Application des Policies

Le script `scripts/vault_setup_apps_policies.py` applique automatiquement toutes les policies.

**Résultat :**
- ✅ 4 policies créées et appliquées

## AppRoles par Application

### AppRoles Créés

Chaque application a son propre AppRole avec :
- **Token TTL** : 1h
- **Token Max TTL** : 4h
- **Secret ID TTL** : 0 (pas d'expiration)
- **Bind Secret ID** : true

**AppRoles créés :**
- ✅ `chatwoot`
- ✅ `n8n`
- ✅ `keybuzz-api`
- ✅ `keybuzz-workers`

### Identifiants Générés

Les identifiants sont sauvegardés dans `roles/` sur `install-v3` :
- `roles/chatwoot-role.json`
- `roles/chatwoot-secret.json`
- `roles/n8n-role.json`
- `roles/n8n-secret.json`
- `roles/keybuzz-api-role.json`
- `roles/keybuzz-api-secret.json`
- `roles/keybuzz-workers-role.json`
- `roles/keybuzz-workers-secret.json`

**⚠️ IMPORTANT :**
- Ces fichiers ne sont **PAS** commités dans Git
- Ajoutés à `.gitignore`
- Stockés uniquement sur `install-v3`

## Secrets Préparés

### Chatwoot

- `database-url` : Placeholder
- `redis-url` : Placeholder
- `rabbitmq-url` : Placeholder
- `smtp-password` : Placeholder

### n8n

- `rabbitmq-url` : Placeholder
- `redis-url` : Placeholder
- `webhook-secret` : Placeholder
- `jwt-secret` : Placeholder

### KeyBuzz API

- `postgres-url` : Placeholder
- `redis-url` : Placeholder
- `rabbitmq-url` : Placeholder
- `jwt-secret` : Placeholder

### KeyBuzz Workers

- `api-token` : Placeholder
- `rabbitmq-url` : Placeholder
- `redis-url` : Placeholder

## Templates Helm/K8s

### Templates Créés

**`k8s/templates/apps/` :**
- `chatwoot-secret.yaml.j2`
- `n8n-secret.yaml.j2`
- `keybuzz-api-secret.yaml.j2`
- `keybuzz-workers-secret.yaml.j2`

Chaque template utilise les lookups Vault avec AppRole pour récupérer les secrets et les injecter dans des Secrets Kubernetes.

### Values Helm

**`helm/` :**
- `values-chatwoot.yaml`
- `values-n8n.yaml`
- `values-keybuzz.yaml`

Ces fichiers contiennent les configurations Helm avec les placeholders Vault pour PH9/PH10.

## Scripts de Test

### Scripts Créés

**`scripts/vault_tests/` :**
- `test_chatwoot_vault.py`
- `test_n8n_vault.py`
- `test_keybuzz_api_vault.py`
- `test_keybuzz_workers_vault.py`

Chaque script :
1. Charge les identifiants AppRole depuis `roles/`
2. S'authentifie auprès de Vault avec AppRole
3. Récupère tous les secrets de l'application
4. Affiche SUCCESS ou FAILURE

### Exécution des Tests

```bash
python3 scripts/vault_tests/test_chatwoot_vault.py
python3 scripts/vault_tests/test_n8n_vault.py
python3 scripts/vault_tests/test_keybuzz_api_vault.py
python3 scripts/vault_tests/test_keybuzz_workers_vault.py
```

## Prochaines Étapes

- **PH9** : Déploiement Kubernetes avec injection des secrets Vault
- **PH10** : Installation des applications avec secrets depuis Vault
- Migration des valeurs placeholder vers les vrais secrets lors de l'installation

## Conclusion

✅ **PH6-05 est terminé :**
- Structure Vault créée pour toutes les applications
- Policies et AppRoles configurés pour chaque application
- Secrets préparés avec valeurs placeholder
- Templates Helm/K8s prêts pour PH9/PH10
- Scripts de test créés et fonctionnels
- Infrastructure 100% prête pour l'intégration Kubernetes

