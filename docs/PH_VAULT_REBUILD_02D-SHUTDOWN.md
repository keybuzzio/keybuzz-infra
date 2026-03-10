# PH_VAULT_REBUILD_02D - Shutdown Standalone + Securisation Finale

> Date : 2026-03-02T09:16:45Z
> Auteur : Agent Cursor
> Statut : SHUTDOWN COMPLETE

---

## 1. Resume

Le Vault standalone sur le bastion (install-v3, 10.0.0.251) a ete eteint definitivement.
Le cluster Vault HA Raft (3 noeuds) est la seule source de verite active.

---

## 2. Phase 1 - Verifications pre-shutdown

| Check | Resultat |
|---|---|
| Raft peers | 3 (vault-01 leader, vault-02/03 followers) |
| Vault sealed | false |
| HA Enabled | true |
| K8s Endpoints vault | 10.0.0.150, 10.0.0.154, 10.0.0.155 |
| 10.0.0.251 dans endpoints | ABSENT (OK) |
| ExternalSecrets Ready | 20/20 |
| Pods Running | Tous OK |

---

## 3. Phase 2 - Revocation root token initial

- Ancien root token (issu de vault operator init) : REVOQUE
- Verification : 403 permission denied / invalid token (confirme)
- Nouveau root token genere via unseal keys (generate-root)
- Fichier vault_init_output.json : champ root_token remplace par REVOKED
- Nouveau token sauvegarde dans new_root_token.txt (chmod 600)

Note : le premier nouveau token cree via vault token create a ete revoque
en cascade avec le parent. Le token definitif a ete genere via
vault operator generate-root avec 3 des 5 cles Shamir.

---

## 4. Phase 3 - Arret Vault standalone

- systemctl stop vault : OK
- systemctl disable vault : OK
- Statut : inactive (dead)
- Le service ne redemarrera PAS au boot

---

## 5. Phase 4 - Blocage ports bastion

- iptables DROP sur port 8200/tcp : APPLIQUE
- iptables DROP sur port 8201/tcp : APPLIQUE
- Regles persistees dans /etc/iptables.rules
- Verification ss -tulnp : ports 8200/8201 non actifs

---

## 6. Phase 5 - Validation finale

### Cluster Vault HA

| Node | IP | State | Voter |
|---|---|---|---|
| vault-01 | 10.0.0.150:8201 | leader | true |
| vault-02 | 10.0.0.154:8201 | follower | true |
| vault-03 | 10.0.0.155:8201 | follower | true |

- Version : 1.21.1
- Cluster : vault-cluster-bec03650
- Raft Index : 708
- Sealed : false
- HA Mode : active

### Health depuis pod K8s

curl http://vault.default.svc.cluster.local:8200/v1/sys/health
- initialized: true
- sealed: false
- ha_connection_healthy: true

### ExternalSecrets

- Total : 20
- Ready : 20
- NotReady : 0

### Services KeyBuzz

| Namespace | Pods Running |
|---|---|
| keybuzz-api-dev | 2/2 |
| keybuzz-api-prod | 2/2 |
| keybuzz-backend-dev | 4/4 |
| keybuzz-backend-prod | 3/3 |
| keybuzz-client-dev | 1/1 |
| keybuzz-client-prod | 1/1 |
| keybuzz-ai | 2/2 |

### API Health

- api-dev.keybuzz.io : {"status":"ok"}
- api.keybuzz.io : {"status":"ok"}

### Bastion standalone

- Service : inactive (dead)
- Port 8200 : not listening
- Boot : disabled

---

## 7. Standalone bastion - Etat final

Le Vault standalone est :
- ARRETE (systemctl stop + disable)
- HORS TRAFIC (iptables DROP 8200/8201)
- CONSERVE comme archive disque (donnees dans /data/vault/storage/)
- Les donnees N'ONT PAS ete supprimees

---

## 8. Fichiers sensibles (NE PAS COMMITTER)

| Fichier | Contenu |
|---|---|
| /opt/keybuzz/logs/ph_vault_rebuild_02/unseal_keys.txt | 5 cles Shamir |
| /opt/keybuzz/logs/ph_vault_rebuild_02/new_root_token.txt | Root token actif |
| /opt/keybuzz/logs/ph_vault_rebuild_02/vault_init_output.json | Init output (root_token=REVOKED) |

---

## 9. Prochaines etapes enterprise (non executees)

1. Activer auto-unseal (Transit seal ou cloud KMS)
2. Configurer snapshots automatiques Raft
3. Activer metriques Prometheus (/v1/sys/metrics)
4. Script DR restore test
5. Rotation periodique du token applicatif (vault-app-token)
6. Mettre a jour les deployment.yaml GitOps dans keybuzz-infra

---

## 10. Chronologie complete du rebuild

| Etape | Date | Description |
|---|---|---|
| 02A | 2026-03-01 | Provisionnement vault-02 + vault-03 (Hetzner) |
| 02B | 2026-03-01 | Build cluster Raft HA (3 noeuds, Shamir 5/3) |
| 02C | 2026-03-02 | Import 27 secrets + Auth K8s + ESO 20/20 + nettoyage |
| 02D | 2026-03-02 | Shutdown standalone + revocation + blocage ports |

Date/heure extinction officielle : 2026-03-02T09:16:45Z