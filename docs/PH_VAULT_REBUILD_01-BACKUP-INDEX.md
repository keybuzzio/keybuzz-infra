# PH_VAULT_REBUILD_01 - Index Backup Vault (1er mars 2026)

## Localisation

Bastion install-v3 (10.0.0.251) : /opt/keybuzz/vault-backup-20260301/
Taille totale : 916K

## Fichiers

### Vault Core
| Fichier | Contenu |
|---|---|
| storage-snapshot/ | Copie complete /data/vault/storage/ (340K) |
| vault.hcl | Configuration Vault (storage file, listener TLS) |
| vault-status.json | vault status -format=json |
| tls-certs/ | vault.crt + vault.key (self-signed, expire 2028) |

### Policies
| Fichier | Contenu |
|---|---|
| policy-default.hcl | Policy default Vault |
| policy-keybuzz-api.hcl | secret/data/keybuzz/* CRUD |
| policy-root.hcl | Placeholder (built-in) |

### Auth et Engines
| Fichier | Contenu |
|---|---|
| auth-methods.json | Liste auth methods (token/ uniquement) |
| secrets-engines.json | Liste engines (secret/ KV v2 uniquement) |

### KV Export
| Fichier | Contenu |
|---|---|
| kv-full-export.json | TOUTES les valeurs des 5 secrets (SENSIBLE) |
| kv-keys-index.json | Index cles uniquement (safe) |
| kv-list-root.json | Liste racine secret/ |
| kv-list-keybuzz.json | Liste secret/keybuzz/ |
| kv-list-amazon.json | Liste secret/keybuzz/amazon_spapi/ |
| kv-list-tenants.json | Liste secret/keybuzz/tenants/ |
| kv-keys-amazon_spapi.json | Noms des cles amazon_spapi |

### K8s Secrets (73 fichiers)
| Dossier | Namespaces | Contenu |
|---|---|---|
| k8s-secrets/keybuzz-api-dev/ | 17 secrets | JWT, Postgres, Stripe, SES, MinIO, etc. |
| k8s-secrets/keybuzz-api-prod/ | 8 secrets | JWT, Postgres, Stripe, SES, MinIO |
| k8s-secrets/keybuzz-client-dev/ | 4 secrets | Auth (NextAuth+OAuth), MinIO |
| k8s-secrets/keybuzz-client-prod/ | 3 secrets | Auth, internal-proxy |
| k8s-secrets/keybuzz-backend-dev/ | 5 secrets | DB, Amazon SPAPI, vault-token |
| k8s-secrets/keybuzz-backend-prod/ | 6 secrets | DB, Amazon SPAPI, webhook-key |
| k8s-secrets/keybuzz-seller-dev/ | 4 secrets | Postgres, vault-token |
| k8s-secrets/keybuzz-ai/ | 4 secrets | LiteLLM (master key, DB, API keys) |
| k8s-secrets/observability/ | 14 secrets | Slack, SMTP, Grafana, Prometheus |

Tous les fichiers contiennent les valeurs base64 completes (exploitables pour migration).

### ESO Manifests
| Fichier | Contenu |
|---|---|
| eso-manifests/all-externalsecrets.json | 20 ExternalSecrets (tous en erreur) |
| eso-manifests/all-clustersecretstores.json | 2 ClusterSecretStores (tous en erreur) |

### K8s Vault Resources
| Fichier | Contenu |
|---|---|
| k8s-vault-svc.json | Service vault (default ns, ClusterIP 10.111.0.31) |
| k8s-vault-endpoints.json | Endpoint vers 10.0.0.251:8200 |

## Verification

Pour verifier le backup depuis le bastion :
`
ls -la /opt/keybuzz/vault-backup-20260301/
du -sh /opt/keybuzz/vault-backup-20260301/
`

## Securite

- kv-full-export.json contient des VALEURS SENSIBLES (Amazon SP-API creds)
- k8s-secrets/ contient des valeurs base64 de TOUS les secrets K8s
- NE PAS copier ces fichiers hors du bastion
- Supprimer apres migration reussie