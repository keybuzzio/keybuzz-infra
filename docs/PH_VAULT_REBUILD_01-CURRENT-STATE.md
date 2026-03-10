# PH_VAULT_REBUILD_01 - Etat Actuel Vault (1er mars 2026)

## Verdict

Vault tourne en **standalone sur le bastion** (install-v3, 10.0.0.251). Pas de HA. vault-01 est down. ESO est casse. Les services fonctionnent grace aux secrets K8s manuels.

---

## 1. Instance Active

| Propriete | Valeur |
|---|---|
| Serveur | install-v3 (bastion) |
| IP | 10.0.0.251 |
| Version | Vault v1.21.1 (2025-11-18) |
| Storage | file - /data/vault/storage/ (340K) |
| HA | **Desactive** (file storage) |
| Seal | Shamir **1/1** (insecure) |
| Systemd | vault.service active depuis 2026-02-21 |
| TLS | Self-signed (CN=Vault, pas de SAN FQDN), expire 2028-12-13 |
| Config | /etc/vault.d/vault.hcl |
| Listener | 0.0.0.0:8200 (TLS enabled) |

## 2. vault-01 (10.0.0.150) - DOWN

- Down depuis 7 janvier 2026
- Cause : script zombie (/tmp/full_vault_fix.sh, PID 2731107) bloque le port 8200
- Config identique au bastion (storage file)
- Pas de cluster HA entre les deux

## 3. Auth et Policies

### Auth Methods
- token/ uniquement (pas de kubernetes, approle, etc.)

### Policies
| Policy | Scope |
|---|---|
| root | Built-in, acces total |
| default | Policy par defaut Vault |
| keybuzz-api | secret/data/keybuzz/* CRUD + secret/metadata/keybuzz/* list/read/delete |

### Secrets Engines
| Mount | Type | Version |
|---|---|---|
| secret/ | KV | v2 |
| cubbyhole/ | cubbyhole | built-in |
| identity/ | identity | built-in |

## 4. Donnees KV dans Vault (5 secrets seulement)

| Path | Nb cles |
|---|---|
| secret/keybuzz/amazon_spapi | 6 |
| secret/keybuzz/amazon_spapi/app | 6 |
| secret/keybuzz/tenants/ecomlg-001/amazon_spapi | 5 |
| secret/keybuzz/tenants/tenant-1771372217854/amazon_spapi | 5 |
| secret/keybuzz/tenants/tenant-1771372406836/amazon_spapi | 5 |

**Tous les autres paths references par ESO (22 paths) sont ABSENTS de Vault.**

## 5. ESO - Totalement casse

### ClusterSecretStores
| Store | Status | Erreur |
|---|---|---|
| vault-backend | Ready=False | InvalidProviderConfig - auth kubernetes non activee |
| vault-backend-database | Ready=False | Idem + mount database inexistant |

### ExternalSecrets (20 ressources, TOUTES en erreur)

| Namespace | Nom | Secret cible | Vault Path(s) |
|---|---|---|---|
| keybuzz-ai | litellm-secrets | litellm-secret | secret/keybuzz/litellm/*, secret/keybuzz/ai/* |
| keybuzz-api-dev | keybuzz-api-jwt | keybuzz-api-jwt | keybuzz/dev/jwt |
| keybuzz-api-dev | keybuzz-api-postgres-admin | keybuzz-api-postgres-admin | database/creds/keybuzz-admin |
| keybuzz-api-dev | keybuzz-api-postgres-kv | keybuzz-api-postgres | secret/data/keybuzz/dev/api-postgres |
| keybuzz-api-dev | keybuzz-db-migrator | keybuzz-db-migrator | secret/keybuzz/dev/db_migrator |
| keybuzz-api-dev | keybuzz-litellm-secrets | keybuzz-litellm-secrets | secret/keybuzz/litellm/master_key |
| keybuzz-api-dev | keybuzz-ses-secrets | keybuzz-ses | secret/keybuzz/ses |
| keybuzz-api-dev | keybuzz-stripe-secrets | keybuzz-stripe | secret/keybuzz/stripe |
| keybuzz-api-dev | minio-credentials | minio-credentials | secret/data/keybuzz/minio |
| keybuzz-api-dev | octopia-credentials | octopia-credentials | secret/keybuzz/dev/octopia |
| keybuzz-api-prod | keybuzz-api-jwt | keybuzz-api-jwt | keybuzz/prod/jwt |
| keybuzz-api-prod | keybuzz-api-postgres | keybuzz-api-postgres | secret/keybuzz/prod/db_api |
| keybuzz-api-prod | minio-credentials | minio-credentials | secret/keybuzz/prod/minio |
| keybuzz-backend-dev | keybuzz-backend-db | keybuzz-backend-db | keybuzz/dev/backend-postgres |
| keybuzz-client-dev | keybuzz-auth-secrets | keybuzz-auth | secret/keybuzz/auth |
| keybuzz-client-dev | minio-credentials | minio-credentials | secret/data/keybuzz/minio |
| keybuzz-client-prod | keybuzz-auth-secrets | keybuzz-auth-secrets | secret/keybuzz/prod/auth |
| keybuzz-seller-dev | seller-api-postgres | seller-api-postgres | secret/data/keybuzz/dev/seller-api-postgres |
| observability | alerting-slack-dev | alerting-slack-dev | keybuzz/observability/slack/dev |
| observability | alerting-smtp-dev | alerting-smtp-dev | keybuzz/observability/smtp/dev |

## 6. K8s - Comment ca marche actuellement

### Service Vault K8s
- vault (namespace default) - ClusterIP 10.111.0.31 - Endpoint 10.0.0.251:8200 (bastion)

### hostAliases pointant vers 10.0.0.150 (DOWN)
| Namespace | Deployment |
|---|---|
| keybuzz-backend-dev | amazon-items-worker |
| keybuzz-backend-dev | amazon-orders-worker |
| keybuzz-backend-dev | keybuzz-backend |
| keybuzz-backend-prod | amazon-items-worker |
| keybuzz-backend-prod | amazon-orders-worker |

### VAULT_TOKEN expose
| Deployment | Mode |
|---|---|
| keybuzz-api-dev | secretKeyRef(vault-root-token) OK |
| keybuzz-api-prod | **PLAINTEXT** |
| keybuzz-backend-dev | **PLAINTEXT** |
| keybuzz-backend-prod | **PLAINTEXT** |
| amazon-*-workers (dev+prod) | secretKeyRef(vault-token) OK |

## 7. Secrets K8s manuels (source de verite actuelle)

Les services fonctionnent car les secrets ont ete crees manuellement dans K8s (pas via ESO).

| Namespace | Secrets notables |
|---|---|
| keybuzz-api-dev | api-jwt, postgres (x3), ses, stripe (12 keys), minio, octopia, litellm |
| keybuzz-api-prod | api-jwt, postgres, ses, stripe (10 keys), minio, litellm |
| keybuzz-client-dev | auth (7 keys: NextAuth+Google+Azure), minio, internal-proxy |
| keybuzz-client-prod | auth-secrets (6 keys), internal-proxy |
| keybuzz-backend-dev | backend-db (6 keys), amazon-spapi-creds, vault-token |
| keybuzz-backend-prod | backend-db, amazon-spapi-creds, inbound-webhook-key, vault-token |
| keybuzz-seller-dev | seller-api-postgres, vault-token |
| keybuzz-ai | litellm-secret (6 keys), litellm-db-secret, litellm-runtime-key |
| observability | alerting-slack-dev, alerting-smtp-dev |

**Total : 73 secrets K8s sauvegardes dans le backup.**

## 8. Problemes a corriger (PH_VAULT_REBUILD_02)

1. Storage file vers Raft (activer HA)
2. Shamir 1/1 vers 3/5 (securite)
3. Activer auth kubernetes (pour ESO)
4. Creer TOUS les 22 paths KV manquants (depuis les secrets K8s existants)
5. Supprimer hostAliases 10.0.0.150 (5 deployments)
6. Supprimer VAULT_TOKEN plaintext (3 deployments PROD)
7. Generer un vrai certificat TLS avec SAN FQDN
8. Tuer le script zombie sur vault-01 et reutiliser le serveur