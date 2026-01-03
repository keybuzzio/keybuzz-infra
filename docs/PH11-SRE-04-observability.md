# PH11-SRE-04 - Observability Stack Runbook

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Prometheus  │  │ Alertmanager │  │   Grafana    │          │
│  │   (scrape)   │  │   (alerts)   │  │  (dashboard) │          │
│  └──────┬───────┘  └──────────────┘  └──────────────┘          │
│         │                                                        │
│  ┌──────┴────────────────────────────────────────┐              │
│  │              Service Discovery                 │              │
│  │  - K8s nodes (DaemonSet node_exporter)        │              │
│  │  - K8s services (ServiceMonitor)               │              │
│  │  - External VMs (static_configs Secret)        │              │
│  └───────────────────────────────────────────────┘              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │    Loki      │  │   Promtail   │                             │
│  │   (logs)     │  │  (DaemonSet) │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Scrape (HTTP :9100, :8008)
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External VMs                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │ PostgreSQL │  │   Redis    │  │  RabbitMQ  │                 │
│  │ (Patroni)  │  │            │  │            │                 │
│  │ :9100,:8008│  │   :9100    │  │   :9100    │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │  MariaDB   │  │  ProxySQL  │  │  HAProxy   │                 │
│  │   :9100    │  │   :9100    │  │   :9100    │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │   Vault    │  │  Monitor   │  │   SIEM     │                 │
│  │   :9100    │  │   :9100    │  │   :9100    │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## Composants

### Prometheus
- **Chart**: kube-prometheus-stack v80.5.0
- **Retention**: 15 jours
- **Storage**: PVC 20Gi
- **Port**: 9090

### Alertmanager
- **Storage**: PVC 10Gi
- **Port**: 9093

### Grafana
- **Ingress**: https://grafana-dev.keybuzz.io
- **Port**: 80
- **Datasources**: Prometheus, Loki

### Loki
- **Chart**: loki 6.49.0
- **Mode**: Single (DEV)
- **Port**: 3100

### Promtail
- **Chart**: promtail 6.17.1
- **Mode**: DaemonSet
- **Source**: /var/log/pods

## Opérations

### Vérifier les targets Prometheus

```bash
# Depuis install-v3
ssh root@10.0.0.100 'curl -s http://10.98.159.10:9090/api/v1/targets' | \
  python3 -c 'import sys,json; d=json.load(sys.stdin); \
  targets=d["data"]["activeTargets"]; \
  jobs={}; \
  [jobs.setdefault(t["labels"]["job"], {"up":0,"down":0}).update({"up": jobs[t["labels"]["job"]]["up"]+1} if t["health"]=="up" else {"down": jobs[t["labels"]["job"]]["down"]+1}) for t in targets]; \
  [print(f"{job}: {c[\"up\"]} up, {c[\"down\"]} down") for job,c in sorted(jobs.items())]'
```

### Accéder à Grafana

```bash
# Récupérer le mot de passe admin
kubectl get secret kube-prometheus-grafana -n observability \
  -o jsonpath='{.data.admin-password}' | base64 -d && echo

# Ou port-forward si Ingress non disponible
kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n observability
```

### Accéder à Prometheus

```bash
kubectl port-forward svc/kube-prometheus-kube-prome-prometheus 9090:9090 -n observability
```

### Ajouter un nouveau scrape target

1. Modifier `/opt/keybuzz/keybuzz-infra/scripts/ph11_sre04_generate_scrape_configs.py`
2. Régénérer:
```bash
cd /opt/keybuzz/keybuzz-infra
python3 scripts/ph11_sre04_generate_scrape_configs.py
kubectl create secret generic prometheus-additional-scrape-configs \
    --from-file=additional-scrape-configs.yaml=k8s/observability/prometheus-additional-scrape-configs.yaml \
    -n observability --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart statefulset prometheus-kube-prometheus-kube-prome-prometheus -n observability
```

### Installer node_exporter sur une nouvelle VM

```bash
cd /opt/keybuzz/keybuzz-infra/ansible
# Ajouter la VM dans inventory/hosts_sre04.ini
ansible-playbook -i inventory/hosts_sre04.ini playbooks/sre04_node_exporter.yml --limit <hostname>
```

### Vérifier les alertes actives

```bash
# Via Alertmanager API
kubectl port-forward svc/kube-prometheus-kube-prome-alertmanager 9093:9093 -n observability
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | {alertname: .labels.alertname, state: .status.state}'
```

### Vérifier les logs Loki

```bash
# Via Grafana -> Explore -> Loki
# Ou via CLI
kubectl port-forward svc/loki 3100:3100 -n observability
curl -s 'http://localhost:3100/loki/api/v1/query_range?query={namespace="keybuzz-api-dev"}&limit=10' | jq
```

## Troubleshooting

### Target DOWN

1. Vérifier la connectivité:
```bash
curl -s http://<IP>:9100/metrics | head
```

2. Vérifier le service sur la VM:
```bash
ssh root@<IP> 'systemctl status node_exporter'
```

3. Vérifier le firewall:
```bash
ssh root@<IP> 'ufw status | grep 9100'
```

### Prometheus ne scrape pas les nouvelles configs

1. Vérifier le secret:
```bash
kubectl get secret prometheus-additional-scrape-configs -n observability -o yaml
```

2. Vérifier le Prometheus CR:
```bash
kubectl get prometheus -n observability -o yaml | grep -A5 additionalScrapeConfigs
```

3. Redémarrer Prometheus:
```bash
kubectl rollout restart statefulset prometheus-kube-prometheus-kube-prome-prometheus -n observability
```

### Alertmanager ne reçoit pas les alertes

1. Vérifier les règles:
```bash
kubectl get prometheusrules -n observability
```

2. Vérifier la config Alertmanager:
```bash
kubectl get secret alertmanager-kube-prometheus-kube-prome-alertmanager -n observability -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d
```

## Références

- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Loki](https://grafana.com/docs/loki/latest/)
- [node_exporter](https://prometheus.io/docs/guides/node-exporter/)
