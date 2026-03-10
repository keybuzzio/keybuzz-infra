# PH_VAULT_AUDIT - Verification HA Vault reelle

> **Date** : 2026-03-01
> **Type** : Audit READ-ONLY, preuves par commandes
> **Point d entree** : install-v3 (bastion, 10.0.0.251)

---

## VERDICT

| Question | Reponse | Preuve |
|----------|---------|--------|
| Vault en HA ? | **NON** | vault status -> HA Enabled: false |
| Storage backend | **file** | vault.hcl -> storage file |
| Raft cluster | **Aucun** | vault operator raft list-peers -> No raft cluster |
| Active node | **install-v3 (10.0.0.251)** | ss -lntp -> port 8200 OPEN |
| Standby nodes | **Aucun** | Scan 8200 tous serveurs -> seul 10.0.0.251 |
| vault-01 (10.0.0.150) | **FAILED depuis 7 jan 2026** | systemctl -> failed |
| Shamir key shares | **1/1 (INSECURE)** | Total Shares: 1, Threshold: 1 |

---

## A) Instances Vault identifiees

### Scan complet infrastructure (44 serveurs)

| Serveur | IP privee | Port 8200 | Process Vault | Etat |
|---------|-----------|-----------|---------------|------|
| **install-v3 (bastion)** | 10.0.0.251 | **OPEN** | PID 2214802, Feb 21 | **ACTIF** |
| **vault-01** | 10.0.0.150 | CLOSED | Aucun | **FAILED** |
| Tous les autres (30+) | 10.0.0.* | CLOSED | Aucun | N/A |

### Preuve install-v3 (ACTIF)

    hostname -> install-v3
    machine-id -> b1073a5d0e7a4ff096b09a0c7615831e
    ss -lntp 8200 -> LISTEN vault pid=2214802
    ss -lntp 8201 -> LISTEN vault pid=2214802
    systemctl is-active vault -> active
    vault version -> 1.21.1

### Preuve vault-01 (FAILED)

    hostname -> vault-01
    machine-id -> 39eb8bb4c2c643b891e3347f8dfce723
    ip addr enp7s0 -> inet 10.0.0.150/32
    ps aux grep vault -> (aucun)
    ss -lntp 8200/8201 -> (aucun)
    systemctl is-active vault -> failed

### Cause crash vault-01 (journal 7 janvier 2026)

    Jan 07 08:39:28 vault-01: Error initializing listener tcp:
      listen tcp4 0.0.0.0:8200: bind: address already in use
    Jan 07 08:39:44: Start request repeated too quickly
    Jan 07 08:39:44: Failed to start vault.service

Un processus bash /tmp/full_vault_fix.sh (PID 2731107, lance le 7 janvier)
tourne encore sur vault-01, bloquant le port 8200.

---

## B) Configuration Vault

### vault-01 et install-v3 - /etc/vault.d/vault.hcl (IDENTIQUES)

    ui = true
    listener "tcp" {
      address       = "0.0.0.0:8200"
      tls_cert_file = "/etc/vault.d/tls/vault.crt"
      tls_key_file  = "/etc/vault.d/tls/vault.key"
      tls_disable   = false
    }
    storage "file" {
      path = "/data/vault/storage"
    }
    disable_mlock = true

### Analyse config

| Element | Valeur | Commentaire |
|---------|--------|-------------|
| storage | file | Pas de Raft, pas de Consul - HA impossible |
| api_addr | ABSENT | Necessaire pour Raft |
| cluster_addr | ABSENT | Necessaire pour Raft |
| listener | TCP 0.0.0.0:8200 TLS | Standard |

### Storage on disk

| Serveur | Device | Mount | Taille |
|---------|--------|-------|--------|
| vault-01 | /dev/sdb (Hetzner vol) | /data/vault (XFS) | 20 Go |
| install-v3 | /dev/sda1 (root FS) | /data/vault (pas de vol dedie) | 38 Go total |

---

## C) Etat HA reel via CLI Vault

### vault status (install-v3)

    Seal Type       shamir
    Initialized     true
    Sealed          false
    Total Shares    1
    Threshold       1
    Version         1.21.1
    Storage Type    file
    Cluster Name    vault-cluster-dba69602
    Cluster ID      c180f580-f225-f32b-d410-60bf211810ce
    HA Enabled      false

### vault read sys/health

    cluster_id                   c180f580-f225-f32b-d410-60bf211810ce
    enterprise                   false
    initialized                  true
    replication_dr_mode          disabled
    replication_performance_mode disabled
    sealed                       false
    standby                      false

### vault read sys/leader

    ha_enabled              false
    is_self                 false
    leader_address          n/a
    leader_cluster_address  n/a

### vault operator raft list-peers

    No raft cluster configuration found

### Secrets Engines

    cubbyhole/    cubbyhole
    identity/     identity
    secret/       kv          -> secret/keybuzz/ (secrets applicatifs)
    sys/          system

### Auth Methods

    token/    token    token based credentials

**CRITIQUE** : Seule auth token configuree.
Pas de kubernetes auth -> ESO ne peut pas se connecter.

---

## D) Comment Kubernetes atteint Vault

### Service et Endpoint K8s

    default  vault  ClusterIP  10.111.0.31  8200/TCP  77d
    Endpoint: 10.0.0.251:8200 (bastion)

Service manuel sans selector, endpoint statique vers le bastion.

### VAULT_ADDR par deployment (3 patterns)

| # | VAULT_ADDR | Resolution | Deployments | Etat |
|---|------------|------------|-------------|------|
| 1 | vault.default.svc.cluster.local:8200 | K8s DNS -> 10.0.0.251 | api-dev/prod, backend-dev/prod | **OK** |
| 2 | vault.keybuzz.io:8200 + hostAliases 10.0.0.150 | -> vault-01 DOWN | amazon workers dev/prod (x4) | **CASSE** |
| 3 | vault.keybuzz.io:8200 (ESO) | DNS -> ? | ClusterSecretStores (x2) | **CASSE** |

### hostAliases incoherents (4 deployments -> vault-01 DOWN)

    keybuzz-backend-dev/amazon-items-worker   -> 10.0.0.150
    keybuzz-backend-dev/amazon-orders-worker  -> 10.0.0.150
    keybuzz-backend-prod/amazon-items-worker  -> 10.0.0.150
    keybuzz-backend-prod/amazon-orders-worker -> 10.0.0.150

### ESO ClusterSecretStores

| Store | Auth | Status |
|-------|------|--------|
| vault-backend | kubernetes (role: keybuzz-external-secrets) | Ready=False, unable to create client |
| vault-backend-database | kubernetes (role: eso-keybuzz) | Ready=False, unable to create client |

Cause : auth kubernetes absente dans Vault.

---

## E) Conclusion factuelle

### Resume

| Critere | Valeur |
|---------|--------|
| Vault storage | file (incompatible HA) |
| HA enabled | false |
| Active node | install-v3 / bastion (10.0.0.251) |
| Standby nodes | Aucun |
| Raft peers | Aucun |
| K8s Vault address | vault.default.svc:8200 -> 10.0.0.251 |
| Auth methods | token uniquement |
| Shamir | 1/1 (aucune securite) |
| ESO | CASSE (Ready=False) |
| vault-01 | FAILED depuis 53 jours |

### Incoherences detectees

1. hostAliases obsoletes : 4 workers Amazon -> 10.0.0.150 (DOWN)
2. ESO non fonctionnel : auth kubernetes absente
3. Vault sur le bastion : data sur root FS sans volume dedie
4. Tokens en clair : certains deployments PROD exposent VAULT_TOKEN
5. Shamir 1/1 : aucun quorum
6. Script zombie : full_vault_fix.sh PID 2731107 sur vault-01 depuis jan 07

### Ce qui fonctionne

- keybuzz-api et keybuzz-backend atteignent Vault via vault.default.svc -> bastion
- Secrets KV (secret/keybuzz/) accessibles
- Vault unseal et operationnel

### Ce qui est casse

- ESO (auth kubernetes absente)
- Amazon workers (hostAliases -> vault-01 DOWN)
- Aucun failover (pas de HA/Raft/standby)
- vault-01 failed depuis 53 jours

---

## Annexe - Commandes executees (preuves)

Audit READ-ONLY depuis bastion install-v3 le 2026-03-01.

    # A) Identification
    ssh 10.0.0.150 hostname               -> vault-01
    ssh 10.0.0.150 /etc/machine-id        -> 39eb8bb4...
    ssh 10.0.0.150 systemctl vault        -> failed
    ssh 10.0.0.150 journalctl -u vault    -> bind: address already in use
    bastion: systemctl vault              -> active
    bastion: ss -lntp 8200               -> LISTEN pid=2214802

    # B) Configuration
    ssh 10.0.0.150 vault.hcl             -> storage file
    bastion: vault.hcl                   -> storage file

    # C) Etat HA
    vault status                         -> HA Enabled: false
    vault operator raft list-peers       -> No raft cluster
    vault read sys/leader                -> ha_enabled: false
    vault auth list                      -> token uniquement

    # D) Kubernetes
    kubectl get svc vault -n default     -> ClusterIP 10.111.0.31
    kubectl get endpoints vault          -> 10.0.0.251:8200
    kubectl get ClusterSecretStore       -> Ready=False (x2)

---

STOP POINT - Audit termine. Aucune modification effectuee.