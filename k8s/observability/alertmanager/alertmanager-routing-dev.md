# Alertmanager Routing - KeyBuzz DEV

## Configuration actuelle

Le routage actuel envoie toutes les alertes vers le receiver `keybuzz-log-only` :

- **Webhook** : http://10.0.0.152:9099/alerts
- **Logs** : `/opt/keybuzz/logs/sre/alertmanager/alerts_YYYYMMDD.jsonl`
- **Service** : `keybuzz-alert-receiver.service` sur monitor-01

## Activation Slack / Email

### 1. Créer les secrets dans Vault

```bash
vault kv put kv/keybuzz/observability/slack/dev \
  webhook_url="https://hooks.slack.com/services/XXX/XXX/XXX"

vault kv put kv/keybuzz/observability/smtp/dev \
  host="smtp.example.com" \
  port="587" \
  username="alerts@keybuzz.io" \
  password="xxx" \
  from="alerts@keybuzz.io"
```

### 2. Mettre à jour les valeurs Helm

Copier `kube-prometheus-values-slack-smtp-placeholder.yaml` vers `kube-prometheus-values-dev.yaml` et remplacer les placeholders :

- `<SLACK_WEBHOOK_URL>` -> valeur Vault
- `<SMTP_HOST>` -> valeur Vault
- `<SMTP_PORT>` -> valeur Vault
- `<SMTP_USER>` -> valeur Vault
- `<SMTP_PASS>` -> valeur Vault
- `<SMTP_FROM>` -> valeur Vault

Décommenter les routes Slack/Email dans la section `route.routes`.

### 3. Appliquer la mise à jour

```bash
helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack \
  -n observability \
  -f /opt/keybuzz/keybuzz-infra/k8s/observability/alertmanager/kube-prometheus-values-dev.yaml \
  --wait --timeout 5m
```

## Routage programmé

| SévƩrité | Receiver | Behavior |
|--------|----------|----------|
| critical | keybuzz-slack-dev + email | Immédiat |
| warning | keybuzz-slack-dev | Groupé (5min) |
| info | log-only | Silencieux |
| Watchdog | null | Ignoré |