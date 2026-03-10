# PH_VAULT_REBUILD_02C — Rapport Cutover Vault HA

> Date : 2026-03-02
> Auteur : Agent Cursor
> Statut : **CUTOVER COMPLET**

---

## 1. Resume executif

Le cutover vers Vault HA Raft est **termine avec succes**. Tous les services KeyBuzz utilisent desormais le cluster Vault HA comme source de verite pour les secrets, via ESO (External Secrets Operator).

### Resultats cles
| Metrique | Avant | Apres |
|---|---|---|
| Vault | Standalone bastion (file storage) | **HA Raft 3 noeuds** |
| Shamir | 1/1 | **5/3** |
| ClusterSecretStores Ready | 0/2 | **2/2** |
| ExternalSecrets Ready | 0/20 | **20/20** |
| VAULT_TOKEN plaintext | 3 deployments | **0** |
| hostAliases 10.0.0.150 | 5 deployments | **0** |
| Paths ESO manquants | 22 | **0** |

---

## 2. Actions realisees

### Phase 1 — Structure Vault HA
- Active KV v2 engine sur `secret/`
- Cree la structure de paths standard KeyBuzz

### Phase 2 — Reinjection secrets (27 total)
- **22 secrets** depuis les dumps K8s (mappes exactement sur les paths ESO)
- **5 secrets** depuis l'ancien Vault (Amazon SP-API, tenants)

| Path Vault | Source | Nb cles |
|---|---|---|
| `secret/database/creds/keybuzz-admin` | K8s keybuzz-api-dev | 7 |
| `secret/keybuzz/ai/anthropic_api_key` | K8s keybuzz-api-dev | 1 |
| `secret/keybuzz/ai/openai_api_key` | K8s keybuzz-api-dev | 1 |
| `secret/keybuzz/auth` | K8s keybuzz-client-dev | 7 |
| `secret/keybuzz/dev/api-postgres` | K8s keybuzz-api-dev | 5 |
| `secret/keybuzz/dev/backend-postgres` | K8s keybuzz-backend-dev | 6 |
| `secret/keybuzz/dev/db_migrator` | K8s keybuzz-api-dev | 5 |
| `secret/keybuzz/dev/jwt` | K8s keybuzz-api-dev | 2 |
| `secret/keybuzz/dev/octopia` | K8s keybuzz-api-dev | 4 |
| `secret/keybuzz/dev/seller-api-postgres` | K8s keybuzz-seller-dev | 5 |
| `secret/keybuzz/litellm/database_url` | K8s keybuzz-ai | 1 |
| `secret/keybuzz/litellm/master_key` | K8s keybuzz-ai | 1 |
| `secret/keybuzz/litellm/use_prisma_migrate` | K8s keybuzz-ai | 1 |
| `secret/keybuzz/minio` | K8s keybuzz-api-dev | 5 |
| `secret/keybuzz/observability/slack/dev` | K8s observability | 2 |
| `secret/keybuzz/observability/smtp/dev` | K8s observability | 7 |
| `secret/keybuzz/prod/auth` | K8s keybuzz-client-prod | 6 |
| `secret/keybuzz/prod/db_api` | K8s keybuzz-api-prod | 5 |
| `secret/keybuzz/prod/jwt` | K8s keybuzz-api-prod | 2 |
| `secret/keybuzz/prod/minio` | K8s keybuzz-api-prod | 2 |
| `secret/keybuzz/ses` | K8s keybuzz-api-dev | 4 |
| `secret/keybuzz/stripe` | K8s keybuzz-api-dev | 12 |
| `secret/keybuzz/amazon_spapi` | Ancien Vault | 6 |
| `secret/keybuzz/amazon_spapi/app` | Ancien Vault | 6 |
| `secret/keybuzz/tenants/ecomlg-001/amazon_spapi` | Ancien Vault | 5 |
| `secret/keybuzz/tenants/tenant-.../amazon_spapi` | Ancien Vault | 5+5 |

### Phase 3 — Auth Kubernetes
- Auth method `kubernetes` activee
- Service account `vault-auth` dans namespace `keybuzz-system`
- ClusterRoleBinding `vault-auth-tokenreview` (system:auth-delegator)
- K8s API host : `https://10.0.0.100:6443`

### Phase 4 — Policies et Roles
| Policy | Capabilities | Paths |
|---|---|---|
| `keybuzz-eso-readonly` | read, list | `secret/data/keybuzz/*`, `secret/data/database/*` |
| `keybuzz-app-read` | read | `secret/data/keybuzz/*`, `secret/data/database/*` |

| Role Vault | SA | Namespace | Policy |
|---|---|---|---|
| `keybuzz-external-secrets` | external-secrets | external-secrets | keybuzz-eso-readonly |
| `eso-keybuzz` | external-secrets | external-secrets | keybuzz-eso-readonly |

### Phase 5 — ClusterSecretStores
| Store | Endpoint | Auth | Ready |
|---|---|---|---|
| `vault-backend` | `http://10.0.0.150:8200` | K8s role keybuzz-external-secrets | **True** |
| `vault-backend-database` | `http://10.0.0.150:8200` | K8s role eso-keybuzz | **True** |

K8s Endpoints `vault` (namespace default) mis a jour : 10.0.0.150, 10.0.0.154, 10.0.0.155

### Phase 6 — ExternalSecrets (20/20 Ready)
| Namespace | ExternalSecret | Store | Ready |
|---|---|---|---|
| keybuzz-ai | litellm-secrets | vault-backend | True |
| keybuzz-api-dev | keybuzz-api-jwt | vault-backend | True |
| keybuzz-api-dev | keybuzz-api-postgres-admin | vault-backend-database | True |
| keybuzz-api-dev | keybuzz-api-postgres-kv | vault-backend | True |
| keybuzz-api-dev | keybuzz-db-migrator | vault-backend | True |
| keybuzz-api-dev | keybuzz-litellm-secrets | vault-backend | True |
| keybuzz-api-dev | keybuzz-ses-secrets | vault-backend | True |
| keybuzz-api-dev | keybuzz-stripe-secrets | vault-backend | True |
| keybuzz-api-dev | minio-credentials | vault-backend | True |
| keybuzz-api-dev | octopia-credentials | vault-backend | True |
| keybuzz-api-prod | keybuzz-api-jwt | vault-backend | True |
| keybuzz-api-prod | keybuzz-api-postgres | vault-backend | True |
| keybuzz-api-prod | minio-credentials | vault-backend | True |
| keybuzz-backend-dev | keybuzz-backend-db | vault-backend | True |
| keybuzz-client-dev | keybuzz-auth-secrets | vault-backend | True |
| keybuzz-client-dev | minio-credentials | vault-backend | True |
| keybuzz-client-prod | keybuzz-auth-secrets | vault-backend | True |
| keybuzz-seller-dev | seller-api-postgres | vault-backend | True |
| observability | alerting-slack-dev | vault-backend | True |
| observability | alerting-smtp-dev | vault-backend | True |

### Phase 7 — Nettoyage deployments

#### hostAliases supprimees (5 deployments)
- keybuzz-backend-dev/amazon-items-worker
- keybuzz-backend-dev/amazon-orders-worker
- keybuzz-backend-dev/keybuzz-backend
- keybuzz-backend-prod/amazon-items-worker
- keybuzz-backend-prod/amazon-orders-worker

#### VAULT_TOKEN plaintext elimines (3 deployments)
- keybuzz-api-prod/keybuzz-api
- keybuzz-backend-dev/keybuzz-backend
- keybuzz-backend-prod/keybuzz-backend

Remplace par `secretKeyRef` vers `vault-app-token` (token periodic, policy `keybuzz-app-read`).

#### VAULT_ADDR mis a jour (8 deployments)
Tous pointes vers `http://vault.default.svc.cluster.local:8200` (service K8s avec 3 endpoints HA).

---

## 3. Etat final du cluster Vault HA

| Node | IP | Port | State | Voter |
|---|---|---|---|---|
| vault-01 | 10.0.0.150 | 8201 | **leader** | true |
| vault-02 | 10.0.0.154 | 8201 | follower | true |
| vault-03 | 10.0.0.155 | 8201 | follower | true |

- **Sealed** : false (3 noeuds)
- **HA Enabled** : true
- **Shamir** : 5 shares / 3 threshold
- **Storage** : Raft
- **Cluster** : vault-cluster-bec03650

---

## 4. Sante des services post-cutover

| Service | Namespace | Status |
|---|---|---|
| keybuzz-api | keybuzz-api-dev | Running, 1/1 Ready |
| keybuzz-api | keybuzz-api-prod | Running, 1/1 Ready |
| keybuzz-backend | keybuzz-backend-dev | Running, 1/1 Ready |
| keybuzz-backend | keybuzz-backend-prod | Running, 1/1 Ready |
| amazon-items-worker | keybuzz-backend-dev | Running, 1/1 Ready |
| amazon-items-worker | keybuzz-backend-prod | Running, 1/1 Ready |
| amazon-orders-worker | keybuzz-backend-dev | Running, 2/2 Ready |
| amazon-orders-worker | keybuzz-backend-prod | Running, 1/1 Ready |
| keybuzz-client | keybuzz-client-dev | Running, 1/1 Ready |
| keybuzz-client | keybuzz-client-prod | Running, 1/1 Ready |

API Health :
- `https://api-dev.keybuzz.io/health` : `{"status":"ok"}`
- `https://api.keybuzz.io/health` : `{"status":"ok"}`

---

## 5. Rollback plan

En cas de probleme :

1. **Restaurer les Endpoints K8s** vers le standalone bastion :
   `kubectl patch endpoints vault -n default -p '{"subsets":[{"addresses":[{"ip":"10.0.0.251"}],"ports":[{"port":8200}]}'`

2. **Re-ajouter hostAliases** dans les deployments backend si necessaire

3. **Le standalone bastion est toujours intact** et operationnel

4. **Les secrets K8s manuels n'ont PAS ete supprimes** — ils existent toujours en parallele

---

## 6. Actions post-validation (NE PAS EXECUTER SANS VALIDATION)

1. Shutdown du Vault standalone sur le bastion (apres confirmation 48h de stabilite)
2. Supprimer les anciens secrets K8s manuels (optionnel, ESO les gere)
3. Ajouter auto-unseal (Transit ou KMS) pour eviter l'unseal manuel apres restart
4. Configurer monitoring Vault (Prometheus metrics sur `/v1/sys/metrics`)
5. Rotation periodique du token applicatif (`vault-app-token`)
6. Mettre a jour les deployment.yaml GitOps dans keybuzz-infra

---

## 7. Fichiers sensibles (NE PAS COMMITTER)

| Fichier | Contenu |
|---|---|
| `/opt/keybuzz/logs/ph_vault_rebuild_02/unseal_keys.txt` | 5 cles Shamir |
| `/opt/keybuzz/logs/ph_vault_rebuild_02/root_token.txt` | Root token Vault HA |
| `/opt/keybuzz/logs/ph_vault_rebuild_02/vault_init_output.json` | Init output complet |

---

## 8. Standalone bastion

Le Vault standalone sur le bastion (install-v3, 10.0.0.251) **n'a PAS ete modifie ni arrete**. Il reste disponible comme fallback.