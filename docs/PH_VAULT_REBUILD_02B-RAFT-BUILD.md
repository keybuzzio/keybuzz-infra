# PH_VAULT_REBUILD_02B - Build Vault HA Raft (1er mars 2026)

## Resultat

Cluster Vault HA Raft operationnel : 3 noeuds, 1 leader, 2 followers, Shamir 5/3.

## Raft Peers

| Node | Address | State | Voter |
|---|---|---|---|
| vault-01 | 10.0.0.150:8201 | **leader** | true |
| vault-02 | 10.0.0.154:8201 | follower | true |
| vault-03 | 10.0.0.155:8201 | follower | true |

## Vault Status par noeud

| Propriete | vault-01 | vault-02 | vault-03 |
|---|---|---|---|
| Sealed | false | false | false |
| HA Enabled | true | true | true |
| HA Mode | **active** | standby | standby |
| Storage Type | raft | raft | raft |
| Version | 1.21.1 | 1.21.1 | 1.21.1 |
| Cluster Name | vault-cluster-bec03650 | idem | idem |
| Cluster ID | 44ee17d7-a4de-d363-00d6-6aae72150d74 | idem | idem |
| Raft Index | 43 | 43 | 43 |

## Configuration

Identique sur les 3 noeuds (adapte par IP/node_id) :
- Storage : raft sur /data/vault/raft
- Listener : 0.0.0.0:8200 (TLS disable pour interne)
- Cluster : port 8201 sur IP privee
- disable_mlock = true
- UI activee

## Securite

### Shamir
- Total Shares : 5
- Threshold : 3
- Cles sauvegardees : /opt/keybuzz/logs/ph_vault_rebuild_02/unseal_keys.txt (chmod 600)
- Root token : /opt/keybuzz/logs/ph_vault_rebuild_02/root_token.txt (chmod 600)

### Ports publics
- 8200 et 8201 ne sont PAS accessibles publiquement (firewall v3-vault)
- Verifie par openssl connect sur les 3 IP publiques : toutes refusees

### Firewall v3-vault (ID 10290882)
| Port | Source | Description |
|---|---|---|
| 22 | 0.0.0.0/0 | SSH |
| 8200 | 10.0.0.0/16 | Vault API (prive) |
| 8201 | 10.0.0.0/16 | Raft cluster (prive) |

## Standalone bastion (intact)

| Propriete | Valeur |
|---|---|
| Sealed | false |
| Storage | file |
| HA Enabled | false |
| Donnees | intactes (keybuzz/amazon_spapi, tenants/) |
| Adresse | https://127.0.0.1:8200 (bastion local) |
| K8s Service | vault.default.svc -> 10.0.0.251:8200 |

Le standalone n'a PAS ete modifie. Il continue de servir les apps K8s.

## Ce qui reste a faire (prochaines etapes)

1. Importer secrets dans le nouveau cluster (R02-C DATA)
2. Configurer auth kubernetes + ESO (R02-D AUTH)
3. Cutover K8s vers le cluster HA (R02-E CUTOVER)
4. Cleanup hostAliases + tokens plaintext (R02-F)
5. Shutdown standalone (apres validation)