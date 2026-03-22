# PH-SRE-MIGRATION-CHECKPOINT-01 — Hetzner Backups & Snapshots

> Date : 15 mars 2026
> Auteur : CE (Cursor)
> Statut : **TERMINE**

---

## 1. Resume executif

**Objectif** : creer un checkpoint serveur complet et immediat avant migration.

### Resultats

| Action | Resultat |
|---|---|
| Backups Hetzner actives | **52/52 serveurs** (3 nouvellement actives) |
| Snapshots manuels (14 mars) | **24 serveurs critiques** couverts |
| Backups automatiques actifs | **344+ images** en rotation 7 jours |
| Nouveaux snapshots (15 mars) | **Bloques** — limite images Hetzner atteinte |
| Cluster K8s | **8/8 nodes Ready**, tous pods Running |
| Endpoints DEV | **Tous OK** (API, Client, Admin) |
| Regressions | **Zero** |

### Conclusion

Le checkpoint pre-migration est **operationnel**. Rollback possible immediatement via :
- **Backups automatiques Hetzner** : 7 jours glissants, couvrent 52/52 serveurs
- **Snapshots manuels** : 24 serveurs d'infrastructure critique (DB, Redis, queues, storage, masters, LB, Vault, mail)

---

## 2. Liste des serveurs (52)

### Serveurs core (K8s + DB)

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 109780472 | k8s-master-01 | Control plane | cx33 | running | ON | 10-14 | nbg1-dc3 |
| 109783469 | k8s-master-02 | Control plane | cx33 | running | ON | 14-18 | nbg1-dc3 |
| 109783574 | k8s-master-03 | Control plane | cx33 | running | ON | 10-14 | nbg1-dc3 |
| 109782191 | k8s-worker-01 | Worker K8s | cx43 | running | ON | 22-02 | nbg1-dc3 |
| 109783643 | k8s-worker-02 | Worker K8s | cx43 | running | ON | 14-18 | nbg1-dc3 |
| 109784494 | k8s-worker-03 | Worker K8s | cx43 | running | ON | 14-18 | nbg1-dc3 |
| 109785006 | k8s-worker-04 | Worker K8s | cx43 | running | ON | 06-10 | nbg1-dc3 |
| 109884534 | k8s-worker-05 | Worker K8s | cx43 | running | ON | 18-22 | nbg1-dc3 |
| 109781629 | db-postgres-01 | PG Replica | ccx13 | running | ON | 06-10 | nbg1-dc3 |
| 109783838 | db-postgres-02 | PG Leader | cx22 | running | ON | 14-18 | nbg1-dc3 |
| 109884801 | db-postgres-03 | PG Replica | cx22 | running | ON | 18-22 | hel1-dc2 |

### Serveurs data (Redis, RabbitMQ, MinIO)

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 109781695 | redis-01 | Redis master | cpx11 | running | ON | 10-14 | nbg1-dc3 |
| 109784003 | redis-02 | Redis replica | cpx11 | running | ON | 22-02 | nbg1-dc3 |
| 109784037 | redis-03 | Redis replica | cpx11 | running | ON | 02-06 | nbg1-dc3 |
| 109783713 | queue-01 | RabbitMQ | cpx11 | running | ON | 18-22 | nbg1-dc3 |
| 109784070 | queue-02 | RabbitMQ | cpx11 | running | ON | 06-10 | nbg1-dc3 |
| 109784080 | queue-03 | RabbitMQ | cpx11 | running | ON | 14-18 | nbg1-dc3 |
| 109784414 | minio-01 | MinIO | cpx21 | running | ON | 18-22 | nbg1-dc3 |
| 109784158 | minio-02 | MinIO | cpx11 | running | ON | 22-02 | nbg1-dc3 |
| 109884423 | minio-03 | MinIO | cx22 | running | ON | 18-22 | nbg1-dc3 |

### Serveurs infrastructure (LB, Vault, mail, bastion)

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 110171270 | haproxy-01 | LB interne | cx22 | running | ON | 22-02 | nbg1-dc3 |
| 110171338 | haproxy-02 | LB interne | cx22 | running | ON | 02-06 | nbg1-dc3 |
| 109883784 | vault-01 | Vault | cx22 | running | ON | 18-22 | nbg1-dc3 |
| 122460339 | vault-02 | Vault HA | cx23 | running | **ON** *(nouveau)* | 18-22 | fsn1-dc14 |
| 122460431 | vault-03 | Vault HA | cx23 | running | **ON** *(nouveau)* | 22-02 | hel1-dc2 |
| 109784583 | mail-core-01 | SMTP/IMAP | cpx11 | running | ON | 06-10 | hel1-dc2 |
| 109784607 | mail-mx-01 | MX | cpx11 | running | ON | 10-14 | nbg1-dc3 |
| 109784668 | mail-mx-02 | MX | cpx11 | running | ON | 14-18 | fsn1-dc14 |
| 114294716 | install-v3 | Bastion | cx23 | running | ON | 18-22 | hel1-dc2 |
| 110030455 | backend-01 | Backend legacy | cx22 | running | ON | 18-22 | nbg1-dc3 |
| 109784108 | backup-01 | Backup | cpx11 | running | ON | 18-22 | nbg1-dc3 |

### Serveurs MariaDB / ProxySQL

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 112572482 | maria-01 | MariaDB Galera | cx23 | running | ON | 06-10 | fsn1-dc14 |
| 112572478 | maria-02 | MariaDB Galera | cx23 | running | ON | 06-10 | fsn1-dc14 |
| 112572479 | maria-03 | MariaDB Galera | cx23 | running | ON | 06-10 | fsn1-dc14 |
| 112572480 | proxysql-01 | ProxySQL | cx23 | running | ON | 06-10 | fsn1-dc14 |
| 112572481 | proxysql-02 | ProxySQL | cx23 | running | ON | 06-10 | fsn1-dc14 |

### Serveurs applicatifs et auxiliaires

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 109784894 | analytics-01 | Analytics | cpx21 | running | ON | 14-18 | nbg1-dc3 |
| 109784916 | analytics-db-01 | Analytics DB | cpx11 | running | ON | 18-22 | nbg1-dc3 |
| 109784201 | api-gateway-01 | API Gateway | cpx11 | **off** | ON | 06-10 | nbg1-dc3 |
| 110237162 | baserow-01 | Baserow | cpx11 | running | ON | 18-22 | nbg1-dc3 |
| 109885044 | builder-01 | CI/CD | cx22 | **off** | ON | 22-02 | nbg1-dc3 |
| 109784173 | crm-01 | CRM | cpx11 | running | ON | 18-22 | nbg1-dc3 |
| 109784945 | etl-01 | ETL | cpx21 | running | ON | 02-06 | nbg1-dc3 |
| 109784396 | litellm-01 | LLM Proxy | cpx21 | **off** | ON | 14-18 | nbg1-dc3 |
| 109784981 | ml-platform-01 | ML Platform | cpx41 | running | ON | 22-02 | nbg1-dc3 |
| 109784447 | monitor-01 | Monitoring | cpx21 | running | ON | 02-06 | nbg1-dc3 |
| 109884364 | nocodb-01 | NocoDB | cx22 | **off** | ON | 10-14 | nbg1-dc3 |
| 109883991 | siem-01 | SIEM | cx32 | running | ON | 14-18 | nbg1-dc3 |
| 109784816 | temporal-01 | Temporal | cpx21 | **off** | ON | 18-22 | nbg1-dc3 |
| 109784838 | temporal-db-01 | Temporal DB | cpx11 | **off** | ON | 02-06 | nbg1-dc3 |
| 109784364 | vector-db-01 | Qdrant | cpx21 | running | ON | 22-02 | nbg1-dc3 |

### Serveur quarantaine

| ID | Serveur | Role | Type | Status | Backup | Fenetre | DC |
|---|---|---|---|---|---|---|---|
| 123508703 | kb-admin-quarantine-01 | Admin legacy | cax11 | running | **ON** *(nouveau)* | 02-06 | fsn1-dc14 |

---

## 3. Backups actives dans cette phase

| Serveur | ID | Etat avant | Etat apres | Fenetre assignee |
|---|---|---|---|---|
| vault-02 | 122460339 | OFF | **ON** | 18-22 UTC |
| vault-03 | 122460431 | OFF | **ON** | 22-02 UTC |
| kb-admin-quarantine-01 | 123508703 | OFF | **ON** | 02-06 UTC |

Les 49 autres serveurs avaient deja les backups actives.

---

## 4. Snapshots existants (14 mars 2026)

24 snapshots manuels crees la veille, couvrant l'infrastructure critique :

| Snapshot ID | Serveur | Taille | Statut |
|---|---|---|---|
| 366760175 | db-postgres-01 | 2.60 GB | available |
| 366761167 | db-postgres-02 | 2.12 GB | available |
| 366761813 | db-postgres-03 | 2.26 GB | available |
| 366762487 | redis-01 | 1.58 GB | available |
| 366763124 | redis-02 | 1.60 GB | available |
| 366763437 | redis-03 | 1.52 GB | available |
| 366764127 | queue-01 | 1.85 GB | available |
| 366764739 | queue-02 | 2.11 GB | available |
| 366765388 | queue-03 | 2.02 GB | available |
| 366765808 | minio-01 | 1.65 GB | available |
| 366766335 | minio-02 | 1.75 GB | available |
| 366766972 | minio-03 | 1.70 GB | available |
| 366767594 | vault-01 | 1.85 GB | available |
| 366768171 | mail-core-01 | 1.72 GB | available |
| 366768512 | mail-mx-01 | 1.06 GB | available |
| 366768781 | mail-mx-02 | 1.18 GB | available |
| 366769427 | backup-01 | 1.74 GB | available |
| 366770215 | k8s-master-01 | 3.46 GB | available |
| 366771596 | k8s-master-02 | 3.53 GB | available |
| 366772425 | k8s-master-03 | 3.36 GB | available |
| 366773488 | haproxy-01 | 1.64 GB | available |
| 366773957 | haproxy-02 | 1.75 GB | available |
| 366774449 | monitor-01 | 1.81 GB | available |
| 366774834 | siem-01 | 1.64 GB | available |

**Total snapshots** : ~48.75 GB

---

## 5. Limite de snapshots Hetzner

La creation de nouveaux snapshots a ete bloquee par l'erreur :

```
hcloud: image limit exceeded (resource_limit_exceeded)
```

Le projet Hetzner a atteint sa limite d'images (snapshots). Les 30 snapshots existants + 344 backups automatiques occupent le quota.

### Impact

Les serveurs suivants n'ont **PAS** de snapshot manuel mais **ONT** des backups automatiques quotidiens :

| Serveur | Couverture |
|---|---|
| k8s-worker-01 a 05 | Backup auto (fenetre 06-22 UTC) |
| install-v3 | Backup auto (18-22 UTC) |
| maria-01/02/03 | Backup auto (06-10 UTC) |
| proxysql-01/02 | Backup auto (06-10 UTC) |
| vault-02/03 | Backup auto (18-22/22-02 UTC, nouvellement active) |
| Tous les serveurs applicatifs | Backup auto (fenetres variees) |

### Recommandation

Pour liberer du quota snapshot, supprimer les 5 anciens snapshots `pre-mount-20251022-*` (octobre 2025, 0.39 GB chacun) qui ne sont plus utiles. Cela libererait 5 slots pour de nouveaux snapshots.

---

## 6. Backups automatiques du 15 mars (jour de la phase)

21 backups automatiques Hetzner crees aujourd'hui dans les fenetres planifiees :

| Heure | Serveurs backupes |
|---|---|
| 02:11 UTC | redis-03, etl-01, temporal-db-01, haproxy-02 |
| 06:13 UTC | api-gateway-01, mail-core-01, db-postgres-01, k8s-worker-04, queue-02, maria-01/02/03, proxysql-01/02 |
| 10:10 UTC | redis-01, mail-mx-01, k8s-master-01/03, nocodb-01 |
| 10:56 UTC | kb-admin-quarantine-01 (1er backup apres activation) |

---

## 7. Acces au token Hetzner

| Aspect | Detail |
|---|---|
| Stockage | `/opt/keybuzz/credentials/hcloud.env` (permissions 600) |
| Format | `HCLOUD_TOKEN='...'` (64 caracteres) |
| hcloud CLI | v1.57.0, installe a `/usr/local/bin/hcloud` |
| Contexte | `keybuzz-v3` (pre-existant, token charge via env) |
| Source Ansible | `lookup('file', hcloud_env_file)` dans les playbooks |

Le token n'est **PAS** dans Vault. Il est stocke sur le filesystem d'install-v3 avec permissions root-only.

---

## 8. Validation cluster

### Nodes Kubernetes

| Node | Status | Age | Version |
|---|---|---|---|
| k8s-master-01 | Ready | 96d | v1.30.14 |
| k8s-master-02 | Ready | 96d | v1.30.14 |
| k8s-master-03 | Ready | 96d | v1.30.14 |
| k8s-worker-01 | Ready | 78d | v1.30.14 |
| k8s-worker-02 | Ready | 78d | v1.30.14 |
| k8s-worker-03 | Ready | 78d | v1.30.14 |
| k8s-worker-04 | Ready | 78d | v1.30.14 |
| k8s-worker-05 | Ready | 78d | v1.30.14 |

### Pods

Tous les pods en status `Running` — zero anomalie.

### Endpoints

| Service | URL | Reponse |
|---|---|---|
| API DEV | `https://api-dev.keybuzz.io/health` | `{"status":"ok"}` |
| Client DEV | `https://client-dev.keybuzz.io/debug/version` | `v0.5.11-ph29.3-parity` |
| Admin DEV | `https://admin-dev.keybuzz.io` | Redirect `/login` (normal) |

### Zero regression

Aucun service impacte par l'activation des backups ou la creation de snapshots.

---

## 9. Couverture du checkpoint

### Matrice de couverture

| Serveur | Backup auto | Snapshot 14/03 | Fenetre backup | Rollback possible |
|---|---|---|---|---|
| db-postgres-01/02/03 | OUI | OUI | 06-18h | **OUI (snapshot + backup)** |
| redis-01/02/03 | OUI | OUI | 02-14h | **OUI (snapshot + backup)** |
| queue-01/02/03 | OUI | OUI | 06-18h | **OUI (snapshot + backup)** |
| minio-01/02/03 | OUI | OUI | 18-22h | **OUI (snapshot + backup)** |
| k8s-master-01/02/03 | OUI | OUI | 10-18h | **OUI (snapshot + backup)** |
| haproxy-01/02 | OUI | OUI | 22-06h | **OUI (snapshot + backup)** |
| vault-01 | OUI | OUI | 18-22h | **OUI (snapshot + backup)** |
| vault-02/03 | OUI | NON | 18-02h | OUI (backup seul) |
| mail-core/mx-01/mx-02 | OUI | OUI | 06-14h | **OUI (snapshot + backup)** |
| backup-01 | OUI | OUI | 18-22h | **OUI (snapshot + backup)** |
| monitor-01 / siem-01 | OUI | OUI | 02-18h | **OUI (snapshot + backup)** |
| k8s-worker-01 a 05 | OUI | NON | 06-22h | OUI (backup seul) |
| install-v3 | OUI | NON | 18-22h | OUI (backup seul) |
| maria-01/02/03 | OUI | NON | 06-10h | OUI (backup seul) |
| proxysql-01/02 | OUI | NON | 06-10h | OUI (backup seul) |
| Serveurs applicatifs | OUI | NON | Varies | OUI (backup seul) |
| Serveurs off (6) | OUI | NON | Varies | OUI (backup seul) |

**Couverture rollback : 52/52 serveurs (100%)**

---

## 10. Serveurs eteints (6)

| Serveur | Statut | Remarque |
|---|---|---|
| api-gateway-01 | off | Doublon avec Ingress K8s |
| builder-01 | off | CI/CD non utilise |
| litellm-01 | off | LLM Proxy migre en K8s |
| nocodb-01 | off | NocoDB non utilise |
| temporal-01 | off | Temporal non utilise |
| temporal-db-01 | off | Temporal DB non utilise |

Ces serveurs ont les backups actives et recevraient des snapshots s'ils etaient rallumes.

---

## 11. Inventaire datacenter

| Datacenter | Serveurs |
|---|---|
| **nbg1-dc3** (Nuremberg) | 38 serveurs |
| **fsn1-dc14** (Falkenstein) | 8 serveurs (maria, proxysql, vault-02, mail-mx-02, kb-admin-quarantine) |
| **hel1-dc2** (Helsinki) | 6 serveurs (db-postgres-03, vault-03, mail-core-01, install-v3) |

---

## 12. Recommandations

### Immediat

1. **Supprimer les 5 snapshots `pre-mount-20251022-*`** pour liberer du quota et permettre la creation de nouveaux snapshots
2. **Migrer le token Hetzner dans Vault** (actuellement sur filesystem, non gere par ESO)

### Court terme

3. **Creer un snapshot des workers K8s** apres liberation du quota (servers stateless mais configuration containerd + kubelet utile)
4. **Automatiser un script de snapshot pre-migration** qui nettoie les anciens snapshots et cree les nouveaux

### Moyen terme

5. **Augmenter la limite d'images** aupres de Hetzner si necessaire (support ticket)
6. **Combiner avec le DR PH-SRE-BACKUP-06** : les backups Hetzner (serveur complet) completent les pg_dumps (donnees seulement)
