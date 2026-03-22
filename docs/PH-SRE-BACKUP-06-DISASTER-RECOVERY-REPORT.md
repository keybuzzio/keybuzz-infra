# PH-SRE-BACKUP-06 — Disaster Recovery Report

> Date : 15 mars 2026
> Auteur : CE (Cursor)
> Statut : **TERMINE**

---

## 1. Resume executif

### Ce qui est sauvegarde

| Brique | Methode | Taille | Frequence | Stockage |
|---|---|---|---|---|
| **PostgreSQL** (3 bases + globals) | `pg_dump -Fc` + `pg_dumpall --globals-only` | 12.2 MB | Quotidien 04:00 UTC | install-v3 |
| **Redis** | `redis-cli --rdb` (remote dump) | 175 bytes | Quotidien 04:00 UTC | install-v3 |
| **MinIO** | `kubectl cp` | 4 KB (1 bucket vide) | Quotidien 04:00 UTC | install-v3 |
| **Kubernetes state** | `kubectl get -o yaml` (12 namespaces) | 1.5 MB | Quotidien 04:00 UTC | install-v3 |
| **Total quotidien** | | **~14 MB** | | |

### Ce qui n'est PAS sauvegarde

| Brique | Raison |
|---|---|
| RabbitMQ | **Absent de l'infra** — KeyBuzz n'utilise pas RabbitMQ |
| Vault | Backup separee existante (`/opt/keybuzz/vault-backup-20260301/`) |
| Secrets K8s (valeurs) | Exclus volontairement — seule la liste des noms est exportee |
| Logs applicatifs | Non critique — reconstructibles depuis les pods |

### Backup pre-existant conserve

Le cron existant (`/opt/keybuzz/backups/backup-db.sh` a 03:00 UTC) reste actif.
Il couvre `keybuzz_prod` et `keybuzz` (DEV) avec retention 30 jours.
Le nouveau systeme DR ajoute `keybuzz_backend` + globals + Redis + MinIO + K8s state.

---

## 2. Backup PostgreSQL

### Methode

| Aspect | Detail |
|---|---|
| Outil | `pg_dump --format=custom` + `pg_dumpall --globals-only` |
| Leader Patroni | `db-postgres-02` (10.0.0.121) |
| Cluster | 3 nodes, TL 16, zero lag |
| Acces `keybuzz_prod` / `keybuzz` | Via utilisateurs K8s secrets (`keybuzz_api_prod` / `keybuzz_api_dev`) |
| Acces `keybuzz_backend` | Via SSH leader (`sudo -u postgres pg_dump`) |

### Bases couvertes

| Base | Taille live | Taille dump | Entries |
|---|---|---|---|
| `keybuzz_prod` | 29 MB | 1.8 MB | 640 |
| `keybuzz` (DEV) | 105 MB | 3.2 MB | 629 |
| `keybuzz_backend` | 81 MB | 7.2 MB | 289 |
| Globals (roles) | — | 40 KB | 82 roles |

Total PostgreSQL live : 215 MB → dump compresse : 12.2 MB (~94% compression)

### Restauration

```bash
# Restaurer une base
sudo -u postgres createdb keybuzz_prod_restored
sudo -u postgres pg_restore -d keybuzz_prod_restored --no-owner keybuzz_prod.dump

# Restaurer les roles globaux
sudo -u postgres psql -f globals.sql
```

### Test de restauration a blanc

| Etape | Resultat |
|---|---|
| `pg_restore -l` verification | **3/3 dumps lisibles** |
| Creation DB temporaire | OK (via leader, user postgres) |
| Restauration `keybuzz_prod.dump` | **80 tables restaurees** |
| Seule erreur | `schema "public" already exists` (benin) |
| Cleanup | DB temporaire supprimee |

**Verdict : PASSE**

---

## 3. Backup Redis

### Architecture

| Aspect | Detail |
|---|---|
| Serveur | 10.0.0.10 (serveur dedie, **pas install-v3**) |
| Version | Redis 7.0.15, standalone |
| Acces SSH | **BLOQUE** (firewall PH-INFRA-02) |
| Acces redis-cli | OK depuis install-v3 (port 6379 ouvert) |
| Password | Extrait de K8s secret `redis-credentials` (Vault + ESO) |
| Persistence | RDB uniquement (AOF desactive) |
| Data dir (sur le serveur) | `/data/redis/temp-sync.rdb` |

### Methode

`redis-cli --rdb` effectue un dump RDB distant (protocole SYNC).
Le fichier est ecrit directement sur install-v3 sans necessiter d'acces SSH au serveur Redis.

### Etat actuel

| Metrique | Valeur |
|---|---|
| DBSIZE | 0 keys |
| Memoire utilisee | 17.65 MB |
| Memoire peak | 17.67 MB |
| Taille dump | 175 bytes |
| Uptime | 8 jours |

Redis est principalement utilise comme cache/session — les donnees sont ephemeres et reconstructibles.

### Test de restauration a blanc

| Verification | Resultat |
|---|---|
| Fichier RDB existe | Oui (175 bytes) |
| Magic header `REDIS` | **Present** |

**Verdict : PASSE** — dump valide, restaurable via `redis-server --dbfilename dump.rdb`

---

## 4. Backup RabbitMQ

**ANNULE** — RabbitMQ n'est pas present dans l'infrastructure KeyBuzz.

Verification effectuee :
- Scan SSH ports 10.0.0.30-42, 10.0.0.70-72 : aucun `rabbitmqctl` trouve
- `kubectl get svc -A | grep rabbit` : aucun resultat

KeyBuzz utilise :
- Redis pour le cache/sessions
- PostgreSQL pour la persistance
- Des workers K8s pour le traitement asynchrone (pas de message broker)

---

## 5. Backup MinIO

### Architecture

| Aspect | Detail |
|---|---|
| Deployment | Pod K8s dans namespace `minio` |
| Pod | `minio-74849bc7cc-h94tx` |
| PVC | `minio-data` (10 Gi, local-path) |
| Stockage | 1 bucket : `keybuzz-attachments` |
| Volumetrie | ~4 KB (bucket quasi-vide) |

### Methode

`kubectl cp` copie les donnees depuis le pod MinIO vers install-v3.
Seuil de securite : si les donnees depassent 500 MB, seule la metadata est sauvegardee (strategie incrementale a implementer).

### Test de restauration a blanc

| Verification | Resultat |
|---|---|
| Liste buckets | 1 bucket (`keybuzz-attachments`) |
| Copie fichiers | OK (0 fichiers — bucket vide) |

**Verdict : PASSE** — le mecanisme fonctionne, les donnees sont simplement vides pour l'instant.

---

## 6. Backup Kubernetes

### Ressources exportees

| Ressource | Format | Par namespace |
|---|---|---|
| Deployments | YAML | Oui |
| Services | YAML | Oui |
| Ingress | YAML | Oui |
| ConfigMaps | YAML | Oui |
| CronJobs | YAML | Oui |
| PVC | YAML | Oui |
| HPA | YAML | Oui |
| Secrets | **Liste noms + types seulement** | Oui |
| Nodes | YAML | Global |
| StorageClasses | YAML | Global |
| ArgoCD Applications | YAML | Global |
| Namespaces | YAML | Global |

### Namespaces couverts (12)

`keybuzz-api-dev`, `keybuzz-api-prod`, `keybuzz-backend-dev`, `keybuzz-backend-prod`, `keybuzz-client-dev`, `keybuzz-client-prod`, `keybuzz-admin-v2-dev`, `keybuzz-admin-v2-prod`, `minio`, `observability`, `argocd`, `default`

### Exclusions

- **Valeurs des secrets** : non exportees (securite)
- **Namespaces systeme** (`kube-system`, `kube-public`) : non exportes
- **Contenu des pods** : non exporte (reconstructible via image Docker)

### Test de restauration a blanc

| Verification | Resultat |
|---|---|
| Total fichiers YAML | 88 |
| YAML valides | **88/88** |
| YAML invalides | 0 |

**Verdict : PASSE**

---

## 7. Automatisation

### Timer systemd

| Aspect | Detail |
|---|---|
| Script | `/usr/local/bin/keybuzz-dr-backup.sh` |
| Service | `keybuzz-dr-backup.service` (Type=oneshot) |
| Timer | `keybuzz-dr-backup.timer` |
| Frequence | Quotidien a 04:00 UTC (+/- 10 min alea) |
| Timeout | 3600s (1h max) |
| Persistence | Oui (rattrapage si serveur eteint) |
| Statut | **ACTIF** |
| Prochain run | Lun 16 mars 2026 ~04:05 UTC |

### Cohabitation avec le cron existant

| Systeme | Heure | Couverture | Retention |
|---|---|---|---|
| Cron existant (`backup-db.sh`) | 03:00 UTC | `keybuzz_prod` + `keybuzz` (DEV) | 30 jours |
| Timer DR (`keybuzz-dr-backup.sh`) | 04:00 UTC | 3 bases + globals + Redis + MinIO + K8s | 7j + 4 hebdo |

Les deux systemes coexistent sans conflit (heures differentes).

### Logs

- Script DR : `/opt/keybuzz/backups/dr/logs/dr-backup.log`
- Phase SRE : `/opt/keybuzz/logs/ph-sre/ph-sre-backup-06/`

---

## 8. Retention

### Strategie

| Type | Duree | Methode |
|---|---|---|
| Quotidien | 7 jours | Purge automatique des repertoires daily/ > 7j |
| Hebdomadaire | 28 jours (4 semaines) | Promotion hardlinks le dimanche, purge > 28j |

### Arborescence

```
/opt/keybuzz/backups/dr/
├── daily/
│   └── 20260315/
│       ├── postgres/
│       │   ├── keybuzz_prod.dump     (1.8 MB)
│       │   ├── keybuzz.dump          (3.2 MB)
│       │   ├── keybuzz_backend.dump  (7.2 MB)
│       │   ├── globals.sql           (40 KB)
│       │   └── patroni_state.txt
│       ├── redis/
│       │   ├── dump.rdb              (175 B)
│       │   ├── keyspace.txt
│       │   ├── memory_info.txt
│       │   └── dbsize.txt
│       ├── minio/
│       │   ├── buckets.txt
│       │   ├── bucket_sizes.txt
│       │   └── data/
│       └── kubernetes/
│           ├── namespaces.yaml
│           ├── nodes.yaml
│           ├── storageclasses.yaml
│           ├── argocd-applications.yaml
│           └── <12 namespace dirs>/
│               ├── deployments.yaml
│               ├── services.yaml
│               ├── ingress.yaml
│               ├── configmaps.yaml
│               ├── cronjobs.yaml
│               ├── pvc.yaml
│               ├── hpa.yaml
│               └── secrets_list.txt
├── weekly/
│   └── 20260315/  (hardlinks vers daily)
└── logs/
    └── dr-backup.log
```

### Estimation espace disque

| Periode | Taille estimee |
|---|---|
| 1 jour | 14 MB |
| 7 jours (daily) | ~100 MB |
| 4 semaines (weekly, hardlinks) | ~60 MB additionnels |
| **Total max** | **~160 MB** |

Le disque install-v3 (38 GB, 52% utilise, 18 GB libres) a largement la capacite.

---

## 9. Tests de restauration

### Synthese

| Brique | Test | Resultat |
|---|---|---|
| PostgreSQL | `pg_restore -l` (3 dumps) | **PASSE** — 640+629+289 entries |
| PostgreSQL | Restauration reelle sur DB temp | **PASSE** — 80 tables restaurees |
| PostgreSQL | Globals | **PASSE** — 280 lignes, 82 roles |
| Redis | Magic header RDB | **PASSE** — header `REDIS` valide |
| MinIO | Copie via kubectl cp | **PASSE** — mecanisme fonctionne |
| K8s | Validation YAML | **PASSE** — 88/88 valides |

### Limites des tests

- La restauration PostgreSQL n'a pas ete testee sur un serveur vierge (seulement sur le leader existant)
- La restauration Redis n'a pas ete testee (necessiterait un Redis secondaire)
- MinIO est quasi-vide — le test de restauration avec donnees reelles reste a faire quand le bucket sera peuple

---

## 10. Risques restants

### Risque CRITIQUE : stockage single-point

**Tous les backups sont sur install-v3** (38 GB, meme disque que l'OS).

| Risque | Impact | Probabilite |
|---|---|---|
| Panne disque install-v3 | **Perte de TOUS les backups** | Moyenne |
| Compromission install-v3 | Backup expose | Faible |
| Saturation disque | Backups echouent | Faible (14 MB/jour) |

**Recommandation** : provisionner un serveur `backup-01` dedie (Hetzner, CX22, 40 Go) ou utiliser le volume 100 GB non monte de `maria-01` (10.0.0.170, `/dev/sdb`).

### Risque MODERE : Redis sans SSH

Le serveur Redis (10.0.0.10) n'est pas accessible en SSH (firewall PH-INFRA-02).
Le backup fonctionne via `redis-cli --rdb` mais :
- Pas d'acces aux logs Redis
- Pas de monitoring disk Redis
- En cas de panne, restauration necessite un acces physique/SSH

### Risque FAIBLE : pas de backup WAL (PITR)

Les dumps `pg_dump` permettent une restauration a l'instant du dump.
Pour un RPO < 24h (Point-in-Time Recovery), il faudrait :
- Activer l'archivage WAL continu (`archive_mode = on`)
- Utiliser `pgBackRest` ou `pg_basebackup` + WAL archiving

### Risque FAIBLE : pas de chiffrement

Les dumps PostgreSQL contiennent des donnees sensibles en clair sur le disque d'install-v3.
**Recommandation** : ajouter `gpg --symmetric` ou `age` pour chiffrer les dumps.

---

## 11. Inventaire des fichiers crees

### Sur install-v3 (bastion)

| Fichier | Role |
|---|---|
| `/usr/local/bin/keybuzz-dr-backup.sh` | Script DR principal |
| `/etc/systemd/system/keybuzz-dr-backup.service` | Service systemd |
| `/etc/systemd/system/keybuzz-dr-backup.timer` | Timer systemd (04:00 UTC) |
| `/opt/keybuzz/backups/dr/` | Arborescence de backup |
| `/opt/keybuzz/backups/dr/logs/dr-backup.log` | Journal d'execution |
| `/opt/keybuzz/logs/ph-sre/ph-sre-backup-06/` | Logs de phase |

---

## 12. Cartographie infra decouverte

### Serveurs reseau prive (10.0.0.0/8)

| IP | Hostname | Role | Acces SSH |
|---|---|---|---|
| 10.0.0.10 | ? | **Redis standalone** | NON (firewall) |
| 10.0.0.100 | k8s-master-01 | Control plane | Oui |
| 10.0.0.110 | k8s-worker-01 | Worker K8s | Oui |
| 10.0.0.111 | k8s-worker-02 | Worker K8s | Oui |
| 10.0.0.112 | k8s-worker-03 | Worker K8s | Oui |
| 10.0.0.113 | k8s-worker-04 | Worker K8s | Oui |
| 10.0.0.114 | k8s-worker-05 | Worker K8s | Oui |
| 10.0.0.120 | db-postgres-01 | PG Replica | Oui |
| 10.0.0.121 | db-postgres-02 | **PG Leader** | Oui |
| 10.0.0.122 | db-postgres-03 | PG Replica | Oui |
| 10.0.0.150 | vault-01 | Vault | Oui |
| 10.0.0.160 | mail-core-01 | SMTP + Redis local | Oui |
| 10.0.0.170 | maria-01 | MariaDB + 100 GB libre | Oui |
| 10.0.0.250 | backend-01 | Backend legacy | Oui |
| 10.0.0.251 | install-v3 | **Bastion** | Oui (public) |

---

## 13. Validation finale

### Cluster

| Verification | Resultat |
|---|---|
| Nodes K8s (8/8 Ready) | **OK** |
| Pods critiques (tous Running) | **OK** |
| API DEV health | **OK** |
| Client DEV version | **OK** (v0.5.11-ph29.3) |
| Admin DEV | **OK** (redirect login) |
| Disk install-v3 | 52% (18 GB libres) |

### Zero regression

- Aucun pod arrete
- Aucun service impacte
- Aucune donnee modifiee (sauf DB temp de test, supprimee)
- Backup existant (cron 03:00) inchange

---

## 14. Recommandations phase suivante

### Priorite HAUTE

1. **Serveur backup dedie** : provisionner `backup-01` ou monter le volume 100 GB de `maria-01`, et repliquer les backups hors du bastion
2. **Chiffrement dumps** : ajouter GPG/age sur les dumps PostgreSQL avant ecriture disque

### Priorite MOYENNE

3. **WAL archiving** : activer `archive_mode` pour PITR (RPO < 1h au lieu de 24h)
4. **Monitoring backup** : alerte si le backup DR echoue (scraper le log pour ERRORS > 0)
5. **Ouvrir SSH vers Redis** (10.0.0.10) pour monitoring et maintenance

### Priorite BASSE

6. **PgBouncer** : deploiement prevu dans PH-SRE-FIX-05 readiness (doc a `/opt/keybuzz/infra/pgbouncer/`)
7. **Backup Vault periodique** : le backup Vault existe (`vault-backup-20260301/`) mais n'est pas automatise
8. **Test DR complet** : restauration sur infra vierge (exercice semestriel recommande)
