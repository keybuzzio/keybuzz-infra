# PH11-SRE-07 - ALERTING (DEV)

> Runbook alerting KeyBuzz DEV - à jour le 3 janvier 2026

## 🎯 Vérification rapide

```bash
# Sur install-v3

# Est-ce que le receiver tourne ?
ssh root@10.0.0.152 "systemctl status keybuzz-alert-receiver --no-pager"

# Combien d'alertes aujourd'hui ?
ssh root@10.0.0.152 "wc -l /opt/keybuzz/logs/sre/alertmanager/alerts_*.jsonl"

# Dernieres alertes
ssh root@10.0.0.152 "tail -3 /opt/keybuzz/logs/sre/alertmanager/alerts_*.jsonl"

# Alertmanager OK ?
kubectl get pods -n observability | grep alertmanager
```

## 📦 Architecture

```
  Prometheus                 Alertmanager                    monitor-01
 +------------+    alerts    +------------+    webhook      +------------+
  |  rules   |------------->|   route    |--------------->| alert-recvr |
  +-----------+              |  receiver  |                |  JSONL log  |
                            +------------+                +------------+
```

### Composants

| Composant | Localisation | Port |
|-----------|-------------|------|
| Alertmanager | k8s observability | 9093 |
| Receiver log-only | monitor-01 (10.0.0.152) | 9099 |
| Logs JSONL | monitor-01 /opt/keybuzz/logs/sre/alertmanager/ | - |

## 🔲 Routage actuel

| Type alerte | Destination | Notes |
|-------------|-------------|-------|
| Toutes (default) | keybuzz-log-only | Webhook vers monitor-01 |
| Watchdog | null | Ignoré (normal) |
| critical/warning (via AlertmanagerConfig) | keybuzz-log-only | Merged |

## 🔧 Prochaines étapes (Slack/Email)

Quand Slack/SMTP seront disponibles :

1. Créer les secrets Vault (`runbooks/alertmanager-routing-dev.md`)
2. Mettre à jour `kube-prometheus-values-dev.yaml` depuis le placeholder
3. Helm upgrade

## 🛠 Diagnostic

### Le receiver ne recoit rien

1. Vérifier le service : `ssh root@10.0.0.152 "systemctl status keybuzz-alert-receiver"`
2. Tester le webhook : `curl -X POST http://10.0.0.152:9099/alerts -H "Content-Type: application/json" -d '{}'`
3. Vérifier Alertmanager : `kubectl get pods -n observability | grep alertmanager`

### Les alertes arrivent mais sont incomplètes

Vérifier les logs Alertmanager :
```bash
kubectl logs -n observability alertmanager-kube-prometheus-kube-prome-alertmanager-0 -c alertmanager --tail=50
```

### Redémarrer le receiver

```bash
ssh root@10.0.0.152 "systemctl restart keybuzz-alert-receiver"
```

### Re-deployer la config Alertmanager

```bash
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  -f /opt/keybuzz/keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml \
  --wait --timeout 5m
```

## 📁 Fichiers

| Fichier | Description |
|---------|-------------|
| `keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml` | Valeurs Helm actuelles |
| `.../alertmanager/alertmanager-config-dev.yaml` | AlertmanagerConfig CRD |
| `.../alertmanager/kube-prometheus-values-slack-smtp-placeholder.yaml` | Template pour Slack/Email |
| `keybuzz-infra/sre/alert-receiver/alert_receiver.py` | Script receiver Python |
| `keybuzz-infra/scripts/ph11_sre07_*` | Scripts installation |

## ✅ Checklist validation

- [ ] Service `keybuzz-alert-receiver.eervice` actif
- [ ] Alertmanager recoit les alertes
- [ ] Fichiers JSONL créés dans `/opt/keybuzz/logs/sre/alertmanager/`
- [ ] PROD non touchée