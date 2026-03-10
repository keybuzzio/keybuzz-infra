# PH_VAULT_REBUILD_02A - Provisioning Vault HA (1er mars 2026)

## Serveurs

| Node | ID | Location | Type | IP Publique | IP Privee | Status |
|---|---|---|---|---|---|---|
| vault-01 | 109883784 | nbg1 (Nuremberg) | cx22 | 116.203.61.22 | 10.0.0.150 | running |
| vault-02 | 122460339 | fsn1 (Falkenstein) | cx23 | 46.224.136.26 | 10.0.0.154 | running |
| vault-03 | 122460431 | hel1 (Helsinki) | cx23 | 89.167.74.210 | 10.0.0.155 | running |

## Volumes

| Volume | ID | Size | Location | Server | Mount |
|---|---|---|---|---|---|
| kbv3-vault-01-data | 104100733 | 20 GB | nbg1 | vault-01 | /data/vault |
| kbv3-vault-02-data | 104883802 | 20 GB | fsn1 | vault-02 | /data/vault |
| kbv3-vault-03-data | 104883806 | 20 GB | hel1 | vault-03 | /data/vault |

## Reseau

- Reseau: keybuzz (ID 11477771)
- Subnet: 10.0.0.0/24 (zone eu-central)
- Les 3 serveurs sont dans le meme reseau prive

## Firewall (v3-vault, ID 10290882)

| Direction | Protocol | Port | Source | Description |
|---|---|---|---|---|
| in | tcp | 22 | 0.0.0.0/0, ::/0 | SSH |
| in | tcp | 8200 | 10.0.0.0/16 | Vault API (prive uniquement) |
| in | tcp | 8201 | 10.0.0.0/16 | Vault Raft cluster (prive uniquement) |

Applique a : vault-01, vault-02, vault-03
8200 et 8201 ne sont PAS accessibles publiquement.

## Vault Version

| Node | Version |
|---|---|
| vault-01 (10.0.0.150) | Vault v1.21.1 (2453aac2638a6ae243341b4e0657fd8aea1cbf18) |
| vault-02 (10.0.0.154) | Vault v1.21.1 (2453aac2638a6ae243341b4e0657fd8aea1cbf18) |
| vault-03 (10.0.0.155) | Vault v1.21.1 (2453aac2638a6ae243341b4e0657fd8aea1cbf18) |

## Ping Test (reseau prive)

| Source | Destination | Resultat |
|---|---|---|
| 10.0.0.150 | 10.0.0.154 | OK |
| 10.0.0.150 | 10.0.0.155 | OK |
| 10.0.0.154 | 10.0.0.150 | OK |
| 10.0.0.154 | 10.0.0.155 | OK |
| 10.0.0.155 | 10.0.0.150 | OK |
| 10.0.0.155 | 10.0.0.154 | OK |

## Etat des repertoires

| Node | /data/vault | /data/vault/raft |
|---|---|---|
| vault-01 | monte (20GB) | cree, vide |
| vault-02 | monte (20GB XFS) | cree, vide |
| vault-03 | monte (20GB XFS) | cree, vide |

## Notes

- vault-01 conserve aussi /data/vault/storage/ (ancien backend file, backup)
- Aucun Vault n'est initialise ni configure a ce stade
- SSH key: install-v3-keybuzz (ID 104277690)
- Les anciens ports 80/443 publics ont ete retires du firewall