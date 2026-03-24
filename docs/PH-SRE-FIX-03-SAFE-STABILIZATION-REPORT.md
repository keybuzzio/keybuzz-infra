# PH-SRE-FIX-03 — Stabilisation safe immediate post-audit

> Date : 15 mars 2026
> Auteur : CE (Cursor Agent)
> Bastion : install-v3 (46.62.171.61)
> Prerequis : PH-SRE-AUDIT-01 (14 mars), PH-SRE-FIX-02 (15 mars)
> Statut : TERMINE

---

## 1. Resume executif

### Ce qui a ete fait

| # | Action | Resultat |
|---|--------|----------|
| A | Redemarrage alertmanager (observability) | CPU worker-02 : **100% -> 3%** |
| B | Nettoyage containerd workers K8s (01/02/05) | **~273 GB liberes**, workers sous 20% |
| C | Nettoyage root install-v3 (npm/pip/logs) | Root **85% -> 52%**, ~12 GB liberes |

### Ce qui n'a PAS ete touche

- Workers Amazon PROD (CrashLoopBackOff — tables Prisma manquantes, hors perimetre)
- Migrations Prisma PROD
- Configuration Redis (maxmemory=0 documente mais pas modifie)
- PostgreSQL (asymetrie RAM, pas de switchover)
- Admin v1 legacy (quarantaine maintenue)
- Aucun serveur Hetzner supprime/modifie
- Aucune modification applicative
- Aucun reboot

---

## 2. FIX A — Alertmanager

### Diagnostic

Le pod `alertmanager-kube-prometheus-kube-prome-alertmanager-0` (namespace `observability`) etait en boucle CPU depuis **70 jours** sur k8s-worker-02. Il consommait la quasi-totalite des ressources du node.

### Metriques avant/apres

| Metrique | AVANT | APRES | Delta |
|----------|-------|-------|-------|
| Alertmanager CPU | **7370m** (7.37 cores) | **35m** (0.035 cores) | **-99.5%** |
| Alertmanager RAM | **4093 Mi** (4.0 GB) | **39 Mi** (0.04 GB) | **-99.0%** |
| Worker-02 CPU total | **8000m (100%)** | **298m (3%)** | **-96.3%** |
| Worker-02 RAM total | **7403 Mi (47%)** | **3286 Mi (21%)** | **-55.6%** |
| Worker-02 load avg | 8.29 / 8.34 / 8.45 | Normal (< 1.0) | Stabilise |

### Action effectuee

```
kubectl delete pod alertmanager-kube-prometheus-kube-prome-alertmanager-0 -n observability
```

Le StatefulSet a recree le pod automatiquement. Le nouveau pod a demarre normalement avec une consommation de ressources standard (35m CPU, 39Mi RAM).

### Impact sur le cluster

Le redemarrage a libere **~7.3 CPU cores** et **~4 GB RAM** sur worker-02, rendant le node disponible pour les workloads applicatifs. Aucun effet de bord observe.

### Surveillance

Si le probleme se reproduit (CPU alertmanager > 500m), investiguer :
- Volume des alertes Prometheus (trop de rules ?)
- Boucle de notification (Slack/SMTP retry infini ?)
- Fuite memoire dans la version alertmanager installee

---

## 3. FIX B — Nettoyage workers K8s

### Diagnostic

Les disques root des workers contenaient des **centaines d'images containerd obsoletes** (anciennes versions GHCR de keybuzz-api, keybuzz-client, keybuzz-admin-v2, etc.) qui n'etaient plus referencees par aucun pod.

### Metriques avant/apres

| Worker | Root avant | Root apres | Espace libere | Images avant | Images apres |
|--------|-----------|-----------|--------------|-------------|-------------|
| k8s-worker-01 | **72% (103G/150G)** | **7% (9.5G/150G)** | **~93.5 GB** | 123 | 17 |
| k8s-worker-02 | **79% (114G/150G)** | **12% (17G/150G)** | **~97 GB** | 531 | 23 |
| k8s-worker-05 | **76% (109G/150G)** | **18% (26G/150G)** | **~83 GB** | 451 | 21 |
| **TOTAL** | | | **~273.5 GB** | 1105 | 61 |

### Actions effectuees par worker

| Action | Worker-01 | Worker-02 | Worker-05 |
|--------|-----------|-----------|-----------|
| `journalctl --vacuum-time=7d` | 4.0G -> 2.0G | 4.0G (inchange) | 4.0G (inchange) |
| `apt-get clean` | OK | OK | OK |
| `apt-get autoremove -y` | 0 paquets | 0 paquets | 0 paquets |
| Suppression logs rotated (*.gz, *.old, *.1 > 7j) | OK | OK | OK |
| `crictl rmi --prune` | **106 images** | **508 images** | **430 images** |
| Nettoyage /tmp (> 7j) | OK | OK | OK |

### Ce qui n'a PAS ete supprime

- Images referencees par des pods en cours
- Volumes Kubernetes
- Donnees applicatives
- Manifests
- Configuration systeme

### Cause racine de l'accumulation

Les deployments K8s successifs (PH31 a PH96, 60+ phases) pullent de nouvelles images Docker a chaque mise a jour mais containerd ne les garbage-collecte pas automatiquement. Sans nettoyage periodique, les images s'accumulent indefiniment sur le disque root.

### Recommandation

Mettre en place un CronJob ou un DaemonSet de nettoyage periodique des images containerd (ex: `crictl rmi --prune` hebdomadaire) sur tous les workers.

---

## 4. FIX C — Nettoyage root install-v3

### Diagnostic

Le disque root d'install-v3 (bastion) etait a 85% malgre le nettoyage Docker effectue dans PH-SRE-FIX-02 (volume Docker a 22%). Les principaux consommateurs etaient dans `/root/` et les journaux systeme.

### Metriques avant/apres

| Metrique | AVANT | APRES | Delta |
|----------|-------|-------|-------|
| Root disk (/) | **85% (31G/38G)** | **52% (19G/38G)** | **-12 GB** |
| Journalctl | 3.7 GB | 210 MB | **-3.5 GB** |
| npm cache (/root/.npm) | 4.6 GB | 0 | **-4.6 GB** |
| pip cache (/root/.cache/pip) | 6.5 MB | 0 | -6.5 MB |
| Volume Docker (/dev/sdb) | 22% | 22% | Inchange |

### Actions effectuees

| Action | Espace libere |
|--------|--------------|
| `journalctl --vacuum-time=7d` | ~3.5 GB |
| `apt-get clean` | Marginal |
| `rm -rf /root/.npm/_cacache` | ~4.6 GB |
| `rm -rf /root/.cache/pip` | ~6.5 MB |
| Suppression logs rotated anciens | Marginal |
| Nettoyage /tmp (> 7j) | Marginal |

### Ce qui n'a PAS ete supprime

- Repos Git `/opt/keybuzz/*`
- Manifests K8s
- Cles SSH
- Vault tokens
- Docker images en usage
- Fichiers de configuration systeme

---

## 5. Etat du cluster apres corrections

### Nodes

| Node | CPU | CPU% | Memory | Memory% | Status |
|------|-----|------|--------|---------|--------|
| k8s-master-01 | 773m | 19% | 1851 Mi | 24% | Ready |
| k8s-master-02 | 483m | 12% | 4144 Mi | 54% | Ready |
| k8s-master-03 | 708m | 17% | 5931 Mi | 77% | Ready |
| k8s-worker-01 | 187m | 2% | 3724 Mi | 24% | Ready |
| **k8s-worker-02** | **298m** | **3%** | **3286 Mi** | **21%** | **Ready** |
| k8s-worker-03 | 248m | 3% | 7017 Mi | 45% | Ready |
| k8s-worker-04 | 204m | 2% | 6287 Mi | 40% | Ready |
| k8s-worker-05 | 368m | 4% | 6912 Mi | 44% | Ready |

### Top pods CPU (alertmanager n'apparait plus)

| Pod | Namespace | CPU | Memory |
|-----|-----------|-----|--------|
| etcd-k8s-master-01 | kube-system | 531m | 144Mi |
| prometheus-...-prometheus-0 | observability | 336m | 1274Mi |
| etcd-k8s-master-03 | kube-system | 328m | 150Mi |
| etcd-k8s-master-02 | kube-system | 284m | 150Mi |
| kube-apiserver-master-01 | kube-system | 153m | 1015Mi |
| kube-apiserver-master-03 | kube-system | 145m | 971Mi |
| kube-apiserver-master-02 | kube-system | 91m | 958Mi |
| calico-node-hxf6t | kube-system | 86m | 234Mi |

### Disques root

| Serveur | AVANT (PH-SRE-AUDIT-01) | APRES FIX-03 | Delta |
|---------|------------------------|-------------|-------|
| k8s-worker-01 | 72% | **7%** | -65 pts |
| k8s-worker-02 | 81% | **12%** | -69 pts |
| k8s-worker-05 | 77% | **18%** | -59 pts |
| install-v3 | 86% | **52%** | -34 pts |

### Validation endpoints

| Endpoint | Resultat |
|----------|----------|
| `kubectl get nodes` | 8/8 Ready |
| API DEV health | `{"status":"ok","service":"keybuzz-api","version":"1.0.0"}` |
| Client DEV version | `{"version":"0.5.11-ph29.3-parity"}` |
| Admin DEV | Redirect `/login` (OK, auth requise) |

### Pods en erreur (connus, hors perimetre)

| Pod | Namespace | Status | Cause |
|-----|-----------|--------|-------|
| amazon-items-worker | keybuzz-backend-prod | CrashLoopBackOff (580 restarts) | Table `Order` manquante en PROD |
| amazon-orders-worker | keybuzz-backend-prod | CrashLoopBackOff (551 restarts) | Table `amazon_orders_backfill_state` manquante en PROD |

---

## 6. Risques restants (non traites)

| # | Risque | Severite | Phase recommandee |
|---|--------|----------|-------------------|
| 1 | **Workers Amazon PROD en CrashLoopBackOff** | HAUTE | PH-SRE-FIX-04 : creer tables Prisma manquantes en PROD |
| 2 | **Redis maxmemory=0** (pas de limite) | MOYENNE | Configurer a 1.5 GB (80% RAM node) |
| 3 | **PostgreSQL leader sur machine 3.7 GB** | MOYENNE | Upgrader db-postgres-02 ou switchover vers db-postgres-01 (7.6 GB) |
| 4 | **7 serveurs idle** (~96 EUR/mois) | BASSE | Eteindre via Hetzner Cloud |
| 5 | **Alertmanager peut reboucler** | MOYENNE | Investiguer config prometheus/alertmanager |
| 6 | **Pas de GC containerd automatique** | MOYENNE | Mettre en place un nettoyage periodique |
| 7 | **master-03 memory 77%** | BASSE | Surveiller, upgrader si > 85% |
| 8 | **Journalctl worker-02/05 = 4 GB en 7 jours** | BASSE | Reduire la verbosity des logs ou augmenter le vacuum |

---

## 7. Recommandation phase suivante

### PH-SRE-FIX-04 (propose)

**Objectif** : Corriger les CrashLoopBackOff Amazon workers PROD

**Actions** :
1. Lister les tables Prisma manquantes en PROD par rapport a DEV
2. Creer les tables manquantes (`Order`, `amazon_orders_backfill_state`, et potentiellement d'autres)
3. Verifier que les workers redemarrent et fonctionnent
4. Mettre en place un process de migration Prisma pour PROD

**Prerequis** : Validation par Ludovic avant toute modification de la base PROD.

### PH-SRE-FIX-05 (propose)

**Objectif** : Hardening et automatisation

**Actions** :
1. Mettre en place un DaemonSet de nettoyage containerd periodique
2. Configurer Redis maxmemory
3. Investiguer la config alertmanager pour prevenir la recurrence
4. Planifier l'extinction des serveurs idle

---

## 8. Logs de phase

Tous les logs sont stockes dans :
```
/opt/keybuzz/logs/ph-sre/ph-sre-fix-03/
├── 00_start.txt
├── 01_top_nodes_before.txt
├── 02_top_pods_cpu_before.txt
├── 03_observability_pods.txt
├── 04_all_pods_before.txt
├── 05_worker01_before.txt
├── 06_worker02_before.txt
├── 07_worker05_before.txt
├── 08_installv3_before.txt
├── 09_installv3_du_root.txt
├── 10_top_nodes_after.txt
├── 11_top_pods_cpu_after.txt
└── 99_end.txt
```

---

## 9. Commandes executees

```bash
# FIX A — Alertmanager
kubectl delete pod alertmanager-kube-prometheus-kube-prome-alertmanager-0 -n observability

# FIX B — Workers K8s (sur chaque worker via SSH)
journalctl --vacuum-time=7d
apt-get clean
apt-get autoremove -y
find /var/log -name '*.gz' -mtime +7 -delete
find /var/log -name '*.old' -mtime +7 -delete
find /var/log -name '*.1' -mtime +7 -delete
crictl rmi --prune
find /tmp -type f -mtime +7 -delete

# FIX C — install-v3
journalctl --vacuum-time=7d
apt-get clean
apt-get autoremove -y
rm -rf /root/.npm/_cacache
rm -rf /root/.cache/pip
find /var/log -name '*.gz' -mtime +7 -delete
find /var/log -name '*.old' -mtime +7 -delete
find /var/log -name '*.1' -mtime +7 -delete
find /tmp -type f -mtime +7 -delete
```

---

## 10. Bilan quantitatif total

| Metrique | Avant PH-SRE-FIX-03 | Apres | Amelioration |
|----------|---------------------|-------|-------------|
| CPU worker-02 | 100% (8000m) | 3% (298m) | **-97 points** |
| RAM worker-02 | 47% (7403 Mi) | 21% (3286 Mi) | **-26 points** |
| Disk worker-01 | 72% | 7% | **-65 points** |
| Disk worker-02 | 79% | 12% | **-67 points** |
| Disk worker-05 | 76% | 18% | **-58 points** |
| Disk install-v3 root | 85% | 52% | **-33 points** |
| Espace total libere | — | — | **~285 GB** |
| Images containerd supprimees | 1105 | 61 | **-1044 images** |
| Alertmanager CPU | 7370m | 35m | **/ 210** |
| Alertmanager RAM | 4093 Mi | 39 Mi | **/ 105** |
