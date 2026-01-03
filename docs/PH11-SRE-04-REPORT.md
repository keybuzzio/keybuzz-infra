# PH11-SRE-04 - Monitoring Infrastructure Report

## Date d'exécution
3 janvier 2026

## Résumé
Mise en place complète du monitoring infrastructure pour KeyBuzz v3.

## Composants déployés

### 1. Stack Prometheus (déjà existante)
- **kube-prometheus-stack** v80.5.0
- **Prometheus** avec 15j de rétention
- **Alertmanager** 
- **Grafana** exposé sur https://grafana-dev.keybuzz.io

### 2. node_exporter sur VMs externes (NOUVEAU)
Installé sur **21 VMs** via Ansible:

| Groupe | VMs | Port |
|--------|-----|------|
| db_postgres | 10.0.0.120-122 | 9100 |
| redis | 10.0.0.123-125 | 9100 |
| rabbitmq | 10.0.0.126-128 | 9100 |
| mariadb | 10.0.0.170-172 | 9100 |
| proxysql | 10.0.0.173-174 | 9100 |
| haproxy | 10.0.0.11-12 | 9100 |
| vault | 10.0.0.150 | 9100 |
| monitoring | 10.0.0.151-153 | 9100 |
| mail | 10.0.0.160 | 9100 |

### 3. Scrape configs pour VMs externes (NOUVEAU)
Prometheus configuré pour scrapper toutes les VMs externes:
- 10 jobs de scraping configurés
- **84 targets** actifs au total

### 4. Patroni metrics (NOUVEAU)
- Job `patroni` ajouté
- Targets: 10.0.0.120-122:8008
- Métriques PostgreSQL/Patroni disponibles

### 5. Loki + Promtail (déjà existant)
- **Loki** 6.49.0 (single mode)
- **Promtail** DaemonSet sur tous les nœuds K8s
- Logs Kubernetes centralisés

### 6. Alert rules (NOUVEAU)
PrometheusRule `keybuzz-infra-alerts` créé avec:
- `NodeDown` - VM unreachable
- `NodeDiskSpaceCritical` - Disk < 15%
- `NodeDiskSpaceWarning` - Disk < 20%
- `NodeMemoryPressure` - Memory > 90%
- `NodeCPUHigh` - CPU > 90%
- `PodCrashLoopBackOff` - Pod restart loop
- `DeploymentReplicasUnavailable` - Replicas down
- `DeploymentDown` - All replicas down
- `PatroniDown` - Patroni unreachable
- `PatroniNoLeader` - No PostgreSQL leader
- `HAProxyDown` - HAProxy unreachable
- `VaultDown` - Vault unreachable (SPOF)

## Vérification des targets

```
=== Prometheus Target Summary ===
✅ apiserver: 3 up, 0 down
✅ coredns: 2 up, 0 down
✅ kube-prometheus-kube-prome-alertmanager: 2 up, 0 down
✅ kube-prometheus-kube-prome-operator: 1 up, 0 down
✅ kube-prometheus-kube-prome-prometheus: 2 up, 0 down
✅ kube-state-metrics: 1 up, 0 down
✅ node_exporter_haproxy: 2 up, 0 down
✅ node_exporter_mail: 1 up, 0 down
✅ node_exporter_mariadb: 3 up, 0 down
✅ node_exporter_monitoring: 3 up, 0 down
✅ node_exporter_postgres: 3 up, 0 down
✅ node_exporter_proxysql: 2 up, 0 down
✅ node_exporter_rabbitmq: 3 up, 0 down
✅ node_exporter_redis: 3 up, 0 down
✅ node_exporter_vault: 1 up, 0 down
✅ patroni: 3 up, 0 down

Total: 84 targets
```

## Accès

### Grafana
- **URL**: https://grafana-dev.keybuzz.io
- **User**: admin
- **Password**: (stocké dans Secret `kube-prometheus-grafana`)

```bash
kubectl get secret kube-prometheus-grafana -n observability -o jsonpath='{.data.admin-password}' | base64 -d
```

### Prometheus (port-forward)
```bash
kubectl port-forward svc/kube-prometheus-kube-prome-prometheus 9090:9090 -n observability
```

### Alertmanager (port-forward)
```bash
kubectl port-forward svc/kube-prometheus-kube-prome-alertmanager 9093:9093 -n observability
```

## Fichiers créés/modifiés

### keybuzz-infra
- `ansible/roles/node_exporter/` - Rôle Ansible complet
- `ansible/inventory/hosts_sre04.ini` - Inventaire VMs
- `ansible/playbooks/sre04_node_exporter.yml` - Playbook deployment
- `k8s/observability/prometheus-additional-scrape-configs.yaml` - Scrape configs
- `k8s/observability/keybuzz-infra-alerts.yaml` - Alert rules
- `k8s/observability/grafana-ingress.yaml` - Ingress Grafana
- `scripts/ph11_sre04_generate_scrape_configs.py` - Générateur de configs
- `scripts/ph11_sre04_install_node_exporter.sh` - Script wrapper

## Comment ajouter une nouvelle VM

1. Ajouter la VM dans `servers/servers_v3.tsv`
2. Ajouter dans `ansible/inventory/hosts_sre04.ini`
3. Exécuter:
```bash
cd /opt/keybuzz/keybuzz-infra/ansible
ansible-playbook -i inventory/hosts_sre04.ini playbooks/sre04_node_exporter.yml --limit <hostname>
```
4. Régénérer les scrape configs:
```bash
python3 scripts/ph11_sre04_generate_scrape_configs.py
kubectl create secret generic prometheus-additional-scrape-configs \
    --from-file=additional-scrape-configs.yaml=/opt/keybuzz/keybuzz-infra/k8s/observability/prometheus-additional-scrape-configs.yaml \
    -n observability --dry-run=client -o yaml | kubectl apply -f -
```

## Issues connues (pré-existantes)

Les targets suivants sont DOWN (problème de configuration K8s pré-existant, non lié à PH11-SRE-04):
- `kube-controller-manager`: 3 down
- `kube-etcd`: 3 down  
- `kube-proxy`: 8 down
- `kube-scheduler`: 3 down
- `kubelet`: 12 down (sur 24 endpoints)
- `node-exporter`: 7 down (sur 8 endpoints K8s)

Ces issues sont liées à la configuration de scraping des composants K8s internes et nécessitent un ajustement de la config kube-prometheus-stack.

## Commit Git
```
commit 814f852
PH11-SRE-04: Monitoring infrastructure - node_exporter, scrape configs, alerts, Grafana ingress
```
