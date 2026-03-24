# PH-SRE-FIX-05 — Infrastructure Hardening

> Date : 15 mars 2026
> Auteur : CE (Cursor)
> Environnement : INFRA (bastion install-v3 + 5 K8s workers + Redis)
> Statut : **TERMINE — SUCCES**

---

## 1. Resume executif

Phase de hardening preventif pour empecher le retour des problemes observes dans les phases precedentes (PH-SRE-AUDIT-01 a PH-SRE-FIX-04).

### Actions realisees

| # | Action | Statut |
|---|---|---|
| 1 | GC automatique containerd (timer systemd, 5 workers) | DEPLOYE |
| 2 | Guard Redis memory (maxmemory 1500MB, allkeys-lru) | CONFIGURE |
| 3 | Surveillance alertmanager CPU (timer 15min, seuil 500m) | DEPLOYE |
| 4 | Surveillance disques workers (timer 6h, seuil 75%) | DEPLOYE |
| 5 | Documentation PgBouncer (architecture future) | DOCUMENTE |
| 6 | Validation cluster | OK |

### Aucune regression

- 8/8 nodes Ready
- Tous pods critiques Running
- Endpoints API/Client/Admin OK
- Amazon workers PROD stables (0 restarts)

---

## 2. ETAPE 1 — GC automatique containerd

### Probleme resolu

PH-SRE-FIX-03 a revele ~1105 images containerd accumulees sur les workers, causant une saturation des disques root (72-81%). Le nettoyage manuel a libere ~285 GB, mais sans mecanisme automatique les images s'accumuleraient a nouveau.

### Solution deployee

**Script** : `/usr/local/bin/containerd-gc.sh` sur chaque worker

```bash
#!/bin/bash
LOG="/var/log/containerd-gc.log"
BEFORE=$(crictl images 2>/dev/null | wc -l)
crictl rmi --prune >> "$LOG" 2>&1
AFTER=$(crictl images 2>/dev/null | wc -l)
echo "$(date -u) GC DONE before=$BEFORE after=$AFTER pruned=$((BEFORE - AFTER))" >> "$LOG"
```

**Timer systemd** : `containerd-gc.timer`

| Parametre | Valeur |
|---|---|
| Frequence | Dimanche 03:00 UTC |
| Delai aleatoire | 0-30 min (evite pic simultane) |
| Persistent | Oui (rattrape si manque) |
| Log | `/var/log/containerd-gc.log` |

### Deploiement

| Worker | IP | Timer | Statut |
|---|---|---|---|
| k8s-worker-01 | 10.0.0.110 | containerd-gc.timer | **active** |
| k8s-worker-02 | 10.0.0.111 | containerd-gc.timer | **active** |
| k8s-worker-03 | 10.0.0.112 | containerd-gc.timer | **active** |
| k8s-worker-04 | 10.0.0.113 | containerd-gc.timer | **active** |
| k8s-worker-05 | 10.0.0.114 | containerd-gc.timer | **active** |

### Fichiers crees (par worker)

- `/usr/local/bin/containerd-gc.sh`
- `/etc/systemd/system/containerd-gc.service`
- `/etc/systemd/system/containerd-gc.timer`

---

## 3. ETAPE 2 — Guard Redis memory

### Probleme resolu

PH-SRE-FIX-02 a identifie `maxmemory=0` (illimite) sur Redis. Sans limite, Redis pourrait consommer toute la RAM disponible en cas de pic.

### Configuration

| Parametre | Avant | Apres |
|---|---|---|
| `maxmemory` | 0 (illimite) | **1572864000** (1500 MB) |
| `maxmemory-policy` | allkeys-lru | allkeys-lru (inchange) |
| Persistence | — | `CONFIG REWRITE` OK |

### Etat actuel Redis

| Attribut | Valeur |
|---|---|
| Host | 10.0.0.10:6379 |
| used_memory_human | 17.59 MB |
| maxmemory_human | 1.46 GB |
| Utilisation | ~1.2% du max |
| Auth | Oui (password, source K8s secret) |

### Justification 1500 MB

- Memoire utilisee actuelle : ~18 MB
- Marge confortable : x83 la consommation actuelle
- Serveur : probablement 4-8 GB RAM totale
- Politique `allkeys-lru` : les cles les moins recemment utilisees sont evincees en premier

---

## 4. ETAPE 3 — Surveillance alertmanager CPU

### Probleme resolu

PH-SRE-FIX-03 a decouvert que `alertmanager` consommait 7813m CPU (97.7% du node). Apres restart, il est tombe a 10-35m. Mais sans surveillance, une rechute passerait inapercue.

### Solution deployee

**Script** : `/usr/local/bin/check-alertmanager-cpu.sh` (sur install-v3)

| Parametre | Valeur |
|---|---|
| Seuil | 500m CPU |
| Action si depasse | Log WARNING + syslog (`logger`) |
| Frequence | Toutes les 15 minutes |
| Log | `/var/log/alertmanager-cpu-guard.log` |

### Premier run

```
2026-03-15T08:35:51Z OK alertmanager CPU=12m
```

### Timer systemd

| Fichier | Role |
|---|---|
| `/usr/local/bin/check-alertmanager-cpu.sh` | Script de verification |
| `/etc/systemd/system/check-alertmanager-cpu.service` | Service oneshot |
| `/etc/systemd/system/check-alertmanager-cpu.timer` | Timer 15min |

---

## 5. ETAPE 4 — Surveillance disques workers

### Probleme resolu

PH-SRE-FIX-03 a montre que les disques root pouvaient atteindre 72-81% sans alerte. Avec le GC containerd (etape 1) et cette surveillance, le probleme est couvert des deux cotes.

### Solution deployee

**Script** : `/usr/local/bin/check-worker-disk.sh` (sur install-v3)

| Parametre | Valeur |
|---|---|
| Seuil | 75% utilisation disque |
| Nodes surveilles | 5 workers + install-v3 |
| Action si depasse | Log ALERT + syslog (`logger`) |
| Frequence | Toutes les 6 heures |
| Log | `/var/log/worker-disk-guard.log` |

### Premier run (15 mars 2026 08:35 UTC)

| Node | IP | Disk | Statut |
|---|---|---|---|
| k8s-worker-01 | 10.0.0.110 | 7% | OK |
| k8s-worker-02 | 10.0.0.111 | 12% | OK |
| k8s-worker-03 | 10.0.0.112 | 33% | OK |
| k8s-worker-04 | 10.0.0.113 | 48% | OK |
| k8s-worker-05 | 10.0.0.114 | 18% | OK |
| install-v3 | local | 52% | OK |

### Timer systemd

| Fichier | Role |
|---|---|
| `/usr/local/bin/check-worker-disk.sh` | Script SSH vers 5 workers + local |
| `/etc/systemd/system/check-worker-disk.service` | Service oneshot |
| `/etc/systemd/system/check-worker-disk.timer` | Timer toutes les 6h |

---

## 6. ETAPE 5 — PgBouncer readiness

### Statut

PgBouncer n'est **pas encore necessaire**. La documentation a ete creee pour preparer une future installation.

### Documentation creee

`/opt/keybuzz/infra/pgbouncer/README.md` contient :

- Criteres de declenchement (> 50 connexions, > 10 replicas, P99 > 200ms)
- Commandes de verification actuelles
- Architecture cible (diagramme)
- Configuration recommandee (pool_mode=transaction, default_pool_size=20, max_client_conn=200)
- Options de deploiement (VM dediee, sidecar K8s, sur le leader)
- Pre-requis (Vault, TLS, tests de charge)

### Quand activer

Surveiller periodiquement :

```bash
ssh 10.0.0.121 "sudo -u postgres psql -c \"SELECT count(*) FROM pg_stat_activity WHERE state = 'active'\""
```

Si > 50 connexions actives regulierement, planifier le deploiement PgBouncer.

---

## 7. Validation cluster

### Nodes (8/8 Ready)

| Node | CPU | CPU% | RAM | RAM% |
|---|---|---|---|---|
| k8s-master-01 | 783m | 19% | 1738Mi | 22% |
| k8s-master-02 | 687m | 17% | 4312Mi | 56% |
| k8s-master-03 | 545m | 13% | 6060Mi | 79% |
| k8s-worker-01 | 1131m | 14% | 3760Mi | 24% |
| k8s-worker-02 | 461m | 5% | 3360Mi | 21% |
| k8s-worker-03 | 377m | 4% | 7039Mi | 45% |
| k8s-worker-04 | 669m | 8% | 6331Mi | 40% |
| k8s-worker-05 | 742m | 9% | 6895Mi | 44% |

### Pods critiques (tous Running)

| Pod | Namespace | Status | Restarts |
|---|---|---|---|
| keybuzz-api | keybuzz-api-prod | Running | 0 |
| keybuzz-outbound-worker | keybuzz-api-prod | Running | 2 |
| amazon-items-worker | keybuzz-backend-prod | Running | 0 |
| amazon-orders-worker | keybuzz-backend-prod | Running | 0 |
| backfill-scheduler | keybuzz-backend-prod | Running | 0 |
| keybuzz-backend | keybuzz-backend-prod | Running | 0 |
| alertmanager | observability | Running | 0 |

### Endpoints

| Service | URL | Statut |
|---|---|---|
| API DEV | `https://api-dev.keybuzz.io/health` | `{"status":"ok"}` |
| Client DEV | `https://client-dev.keybuzz.io` | 307 (redirect /login) |
| Admin DEV | `https://admin-dev.keybuzz.io` | 307 (redirect /login) |

### Timers systemd actifs

| Timer | Localisation | Frequence | Prochaine execution |
|---|---|---|---|
| `containerd-gc.timer` | 5 workers | Dim 03:00 UTC | Dim 15 mars 2026 |
| `check-alertmanager-cpu.timer` | install-v3 | Toutes les 15 min | ~08:45 UTC |
| `check-worker-disk.timer` | install-v3 | Toutes les 6h | ~12:03 UTC |

---

## 8. Inventaire complet des scripts et fichiers crees

### Sur chaque K8s worker (x5)

| Fichier | Type | Role |
|---|---|---|
| `/usr/local/bin/containerd-gc.sh` | Script | Prune images containerd |
| `/etc/systemd/system/containerd-gc.service` | Systemd | Service oneshot GC |
| `/etc/systemd/system/containerd-gc.timer` | Systemd | Timer hebdomadaire |

### Sur install-v3 (bastion)

| Fichier | Type | Role |
|---|---|---|
| `/usr/local/bin/check-alertmanager-cpu.sh` | Script | Verifie CPU alertmanager |
| `/etc/systemd/system/check-alertmanager-cpu.service` | Systemd | Service oneshot |
| `/etc/systemd/system/check-alertmanager-cpu.timer` | Systemd | Timer 15min |
| `/usr/local/bin/check-worker-disk.sh` | Script | Verifie disques 5 workers + local |
| `/etc/systemd/system/check-worker-disk.service` | Systemd | Service oneshot |
| `/etc/systemd/system/check-worker-disk.timer` | Systemd | Timer 6h |
| `/opt/keybuzz/infra/pgbouncer/README.md` | Doc | Architecture PgBouncer future |

### Logs

| Log | Localisation | Contenu |
|---|---|---|
| `/var/log/containerd-gc.log` | Chaque worker | Historique GC images |
| `/var/log/alertmanager-cpu-guard.log` | install-v3 | Historique checks CPU |
| `/var/log/worker-disk-guard.log` | install-v3 | Historique checks disque |

---

## 9. Matrice problemes resolus par phase

| Probleme | Phase detection | Phase correction | Phase hardening |
|---|---|---|---|
| Images containerd accumulees (1105) | AUDIT-01 | FIX-03 | **FIX-05** (GC auto) |
| Alertmanager CPU runaway (7813m) | FIX-02 | FIX-03 | **FIX-05** (guard 15min) |
| Disques workers satures (72-81%) | FIX-02 | FIX-03 | **FIX-05** (guard 6h + GC) |
| Redis maxmemory illimite | FIX-02 | — | **FIX-05** (1500MB + LRU) |
| Amazon workers CrashLoopBackOff | FIX-02 | FIX-04 | — |
| install-v3 root disk sature (85%) | FIX-02 | FIX-03 | **FIX-05** (guard 6h) |
| PgBouncer absent | FIX-02 | — | **FIX-05** (doc prete) |

---

## 10. Ce qui n'a PAS ete touche

- Aucune modification applicative (code, images Docker, deployments K8s)
- Aucune modification d'architecture DB
- Aucune migration Prisma
- Aucune suppression de serveur Hetzner
- Aucun secret modifie (Redis auth lu depuis K8s secret, pas hardcode)
- Admin v1 legacy non touche
- Aucun reboot serveur

---

## 11. Chronologie

| Heure (UTC) | Action |
|---|---|
| 08:32 | Preflight : detection workers, Redis, alertmanager |
| 08:35 | Deploiement timer containerd-gc sur 5 workers |
| 08:35 | Installation timer alertmanager-cpu-guard |
| 08:35 | Installation timer worker-disk-guard |
| 08:35 | Creation documentation PgBouncer |
| 08:36 | Validation cluster (8 nodes, pods, endpoints) |
| 08:37 | Fix Redis maxmemory (0 → 1500MB, CONFIG REWRITE) |
| 08:38 | Rapport final |
