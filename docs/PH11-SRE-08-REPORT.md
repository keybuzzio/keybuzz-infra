# PH11-SRE-08 - RAPPORT ALERTING SLACK/EMAIL (DEV)

> Date : 3 janvier 2026

## �� Résumé

Alerting DEV configuré avec : Slack + Email + log-only (fallback)

## ✅ Composants déployés

| Composant | Statut | Notes |
|-----------|--------|-------|
| Vault secrets (slack/smtp) | ✅ | `secret/keybuzz/observability/slack/dev` - **CHANGE_ME** |
| ExternalSecrets | ✅ | `alerting-slack-dev`, `alerting-smtp-dev` |
| Alertmanager receivers | ✅ | Slack + Email + log-only |
| Routing | ✅ | critical → Slack/Email, warning → Slack |

## 🔐 Statut actuel

### ExternalSecrets
```
k.get externalsecrets -n observability
NAME                 STATUS         READY
alerting-slack-dev   SecretSynced   True
alerting-smtp-dev    SecretSynced   True
```

### Alertmanager routing
```
route:
  receiver: keybuzz-log-only
  routes:
  - receiver: "null"                   # Watchdog
  - receiver: keybuzz-slack-dev        # critical
  - receiver: keybuzz-email-dev        # critical
  - receiver: keybuzz-slack-dev        # warning
```

### Log-only toujours actif
Aujourd'hui : 13 alertes reçues dans `/opt/keybuzz/logs/sre/alertmanager/alerts_20260103.jsonl`

## ⚠️ Action requise

**Le webhook Slack est un placeholder.** Pour activer Slack :

1. Créer un webhook Slack (https://api.slack.com/apps)
2. Mettre à jour Vault :
   ```bash
   ssh root@10.0.0.150 'export VAULT_ADDR=https://127.0.0.1:8200; export VAULT_SKIP_VERIFY=true; vault kv patch secret/keybuzz/observability/slack/dev webhook_url="https://hooks.slack.com/services/..."'
   ```
3. Forcer ESO a resync :
   ```bash
   kubectl annotate externalsecret alerting-slack-dev -n observability force-sync=$(date +%s)
   ```

## 📁 Fichiers livrés

| Fichier | Description |
|---------|-------------|
| `k8s/observability/kube-prometheus-values-dev.yaml` | Config Helm avec receivers |
| `.../alertmanager/externalsecret-alerting-slack-dev.yaml` | ESO Slack |
| `.../alertmanager/externalsecret-alerting-smtp-dev.yaml` | ESO SMTP |
| `scripts/ph11_sre08_send_test_alert.sh` | Script de test |
| `scripts/ph11_sre08_rollback_to_log_only.sh` | Rollback |
| `scripts/ph11_sre08_setup_alerting_vault_secrets_dev.sh` | Création secrets Vault |

## 🔙 Rollback (si problème)

```bash
bash /opt/keybuzz/keybuzz-infra/scripts/ph11_sre08_rollback_to_log_only.sh
```

Restaure le routing log-only uniquement.

## ✅ PROD non touchée