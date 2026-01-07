# PH7-SEC-ESO-SECRETS-01 — Centralisation Secrets via Vault + ESO

**Date**: 2026-01-07  
**Environnement**: DEV (`keybuzz-api-dev`, `keybuzz-client-dev`)  
**Status**: ✅ **VAULT → ESO → K8s OPÉRATIONNEL**

---

## 📋 Résumé

| Élément | Status |
|---------|--------|
| Vault opérationnel | ✅ Initialized, Unsealed |
| ESO opérationnel | ✅ 3 pods Running |
| ClusterSecretStore | ✅ vault-backend (Ready) |
| Secrets migrés | ✅ stripe, auth, ses |
| ExternalSecrets créés | ✅ 3 nouveaux |
| Secrets manuels supprimés | ✅ 3 supprimés |
| Pods fonctionnels | ✅ API + Client Running |

---

## 1. État Initial

### 1.1 Secrets K8s Manuels (AVANT)

| Namespace | Secret | Type | Clés |
|-----------|--------|------|------|
| keybuzz-api-dev | keybuzz-stripe | Manuel | 12 clés |
| keybuzz-api-dev | keybuzz-ses | Manuel | 4 clés |
| keybuzz-client-dev | keybuzz-auth | Manuel | 7 clés |

### 1.2 ExternalSecrets Existants (AVANT)

| Namespace | ExternalSecret | Store |
|-----------|----------------|-------|
| keybuzz-api-dev | keybuzz-api-postgres | vault-backend-database |
| keybuzz-ai | litellm-secrets | vault-backend |
| observability | alerting-* | vault-backend |

---

## 2. Migration vers Vault

### 2.1 Secrets Migrés

#### `secret/keybuzz/stripe`
```
api_base_url
app_base_url
price_addon_channel_annual
price_addon_channel_monthly
price_autopilot_annual
price_autopilot_monthly
price_pro_annual
price_pro_monthly
price_starter_annual
price_starter_monthly
secret_key
webhook_secret
```

#### `secret/keybuzz/auth`
```
azure_ad_client_id
azure_ad_client_secret
azure_ad_tenant_id
google_client_id
google_client_secret
nextauth_secret
nextauth_url
```

#### `secret/keybuzz/ses`
```
access_key_id
from_email
region
secret_access_key
```

---

## 3. ExternalSecrets Créés

### 3.1 Manifests

| Fichier | Namespace | Target Secret |
|---------|-----------|---------------|
| `keybuzz-stripe-secrets.yaml` | keybuzz-api-dev | keybuzz-stripe |
| `keybuzz-ses-secrets.yaml` | keybuzz-api-dev | keybuzz-ses |
| `keybuzz-auth-secrets.yaml` | keybuzz-client-dev | keybuzz-auth |

### 3.2 Status

```
NAMESPACE            NAME                     STATUS         READY
keybuzz-api-dev      keybuzz-ses-secrets      SecretSynced   True
keybuzz-api-dev      keybuzz-stripe-secrets   SecretSynced   True
keybuzz-client-dev   keybuzz-auth-secrets     SecretSynced   True
```

---

## 4. Architecture Finale

```
┌─────────────────────────────────────────────────────────────────┐
│                         VAULT                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  secret/keybuzz/                                         │   │
│  │  ├── stripe (12 keys)                                    │   │
│  │  ├── auth (7 keys)                                       │   │
│  │  ├── ses (4 keys)                                        │   │
│  │  ├── smtp (5 keys)                                       │   │
│  │  └── redis (2 keys)                                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SECRETS OPERATOR                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ClusterSecretStore: vault-backend                       │   │
│  │  ├── ExternalSecret: keybuzz-stripe-secrets → keybuzz-stripe │
│  │  ├── ExternalSecret: keybuzz-ses-secrets → keybuzz-ses   │
│  │  └── ExternalSecret: keybuzz-auth-secrets → keybuzz-auth │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      KUBERNETES SECRETS                          │
│  keybuzz-api-dev:                                               │
│  ├── keybuzz-stripe (12 keys) ← ESO                             │
│  ├── keybuzz-ses (4 keys) ← ESO                                 │
│  └── keybuzz-api-postgres (5 keys) ← ESO (database)             │
│                                                                  │
│  keybuzz-client-dev:                                            │
│  └── keybuzz-auth (7 keys) ← ESO                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Secrets Manuels Supprimés

| Secret | Namespace | Remplacé par |
|--------|-----------|--------------|
| keybuzz-stripe | keybuzz-api-dev | ESO keybuzz-stripe-secrets |
| keybuzz-ses | keybuzz-api-dev | ESO keybuzz-ses-secrets |
| keybuzz-auth | keybuzz-client-dev | ESO keybuzz-auth-secrets |

---

## 6. Vérifications

| Check | Résultat |
|-------|----------|
| ExternalSecrets Ready | ✅ 3/3 SecretSynced |
| Secrets K8s créés | ✅ keybuzz-stripe, keybuzz-ses, keybuzz-auth |
| Pod keybuzz-api | ✅ 1/1 Running |
| Pod keybuzz-client | ✅ 1/1 Running |

---

## 7. Avantages

| Avant | Après |
|-------|-------|
| Secrets créés manuellement via `kubectl create secret` | Secrets synchronisés automatiquement depuis Vault |
| Secrets dispersés (K8s + .env) | Source unique: Vault |
| Rotation manuelle | Rotation automatique (refreshInterval: 1h) |
| Risque de commit de secrets | Zéro secret dans Git |

---

## 8. Recommandations

### Immédiat
- ✅ Tous les secrets DEV sont maintenant gérés via ESO

### Pour la PROD
1. Créer les mêmes secrets dans Vault sous `secret/keybuzz/prod/`
2. Créer les ExternalSecrets dans les namespaces prod
3. Ne jamais créer de secrets manuellement

### Monitoring
- Surveiller le status des ExternalSecrets
- Alerter si `Ready: False`

---

## 9. Fichiers Créés

```
keybuzz-infra/k8s/dev/external-secrets/
├── keybuzz-auth-secrets.yaml
├── keybuzz-ses-secrets.yaml
└── keybuzz-stripe-secrets.yaml
```

---

## 10. Commits Git

| Repository | Message |
|------------|---------|
| keybuzz-infra | `feat(PH7): centralize secrets via Vault + ESO (DEV)` |
| keybuzz-infra | `docs(PH7): ESO secrets centralization report` |

---

**Migration terminée avec succès** ✅  
**Vault → ESO → K8s opérationnel**  
**Zéro secret manuel restant**
