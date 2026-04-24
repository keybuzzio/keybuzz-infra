# PH144-MONITORING-ALERTING-01 — Monitoring & Alerting Critique

> Date : 10 avril 2026
> Statut : **DEPLOYE ET ACTIF**
> Environnements : PROD (DEV+PROD monitorés depuis un seul CronJob)

---

## 1. Objectif

Détection automatique des incidents critiques KeyBuzz avec alertes email/webhook.
Aucun outil externe requis, aucun impact runtime, rollback trivial.

---

## 2. Architecture

```
CronJob (*/2 min)
  └── curlimages/curl:8.7.1
       ├── K8s API → pod status, logs, restart counts, job status
       ├── Vault API → health endpoint
       ├── SMTP (10.0.0.160:25) → email alerts
       └── Webhook (optionnel) → Discord/Slack
```

- **Namespace** : `vault-management` (infrastructure partagée)
- **ServiceAccount** : `keybuzz-monitor` (ClusterRole read pods/logs/jobs)
- **Exécution** : ~10-12s par run, 0 impact performance

---

## 3. Les 8 Alertes Critiques

| # | Check | Niveau | Détection | Seuil |
|---|-------|--------|-----------|-------|
| 1 | **Vault accessible** | CRITICAL | HTTP health endpoint | 503=sealed, 000=down |
| 2 | **Vault token renew** | CRITICAL | Jobs Failed dans vault-management | >1 failure |
| 3 | **Amazon import-one** | WARNING | Logs API: `No SP-API creds`, `TOKEN_MISSING` | >0 erreur/3min |
| 4 | **Amazon sync CronJob** | WARNING | Jobs Failed dans keybuzz-backend | >2 failures |
| 5 | **Shopify webhooks** | WARNING | Logs API: `shopify.*error/fail` | >0 erreur/3min |
| 6 | **Autopilot errors** | WARNING | Logs API: `autopilot.*error/fail` | ≥5 erreurs/3min |
| 7 | **API HTTP 500 spike** | CRITICAL | Logs API: `"statusCode":50[0-9]` | ≥5 erreurs/3min |
| 8 | **Worker crash loop** | CRITICAL | Pod restart count | ≥3 restarts |

### Vault HTTP codes gérés
- `200` = active (OK)
- `429` = standby (OK — normal en HA)
- `473` = performance standby (OK)
- `503` = sealed (CRITICAL)
- `501` = not initialized (CRITICAL)
- `000` = unreachable (CRITICAL)

---

## 4. Canaux d'Alerte

### Email (actif)
- From: `alerts@keybuzz.io`
- To: `sre@keybuzz.io`
- SMTP: `10.0.0.160:25` (mail.keybuzz.io, sans TLS interne)
- Envoi confirmé lors du test initial

### Webhook (optionnel)
- Format Discord-compatible (embeds JSON)
- Compatible Slack avec adaptateur
- Configuré via Secret K8s `monitoring-webhook` (namespace `vault-management`)

```bash
# Activer le webhook Discord/Slack
kubectl create secret generic monitoring-webhook \
  --namespace=vault-management \
  --from-literal=url=https://discord.com/api/webhooks/XXXXXX/YYYYYY
```

---

## 5. Format des Messages d'Alerte

```
Subject: [KeyBuzz prod] 1 critical, 0 warning

[CRITICAL] vault: Vault sealed
  HTTP 503 — needs unseal

[WARNING] amazon-import: Import errors (3)
  Check API logs in keybuzz-api-prod

[CRITICAL] worker-restart: amazon-orders-worker crash loop (5x)
  Pod in keybuzz-backend-prod restarted 5 times
```

---

## 6. Fichiers GitOps

```
keybuzz-infra/k8s/monitoring-alerts/
  ├── rbac.yaml                    # SA + ClusterRole + ClusterRoleBinding
  ├── configmap-script.yaml        # Script monitoring (8 checks)
  ├── cronjob.yaml                 # CronJob */2 min
  └── secret-webhook-template.yaml # Template webhook (ne pas commit l'URL)
```

---

## 7. Ressources K8s Déployées

| Resource | Nom | Namespace |
|----------|-----|-----------|
| ServiceAccount | `keybuzz-monitor` | vault-management |
| ClusterRole | `keybuzz-monitor` | — |
| ClusterRoleBinding | `keybuzz-monitor` | — |
| ConfigMap | `monitoring-alert-script` | vault-management |
| CronJob | `monitoring-alerts` | vault-management |

### RBAC (permissions minimales)
- `pods`, `pods/log` : get, list (lecture logs + status)
- `cronjobs`, `jobs` : get, list (status CronJobs)

---

## 8. Validation

### Test manuel initial
```
CHECK 1: Vault accessible → OK (HTTP 429 = standby)
CHECK 2: Vault token renew → OK
CHECK 3: Amazon import-one → OK
CHECK 4: Amazon sync CronJob → OK
CHECK 5: Shopify webhooks → OK
CHECK 6: Autopilot errors → OK (errors=0)
CHECK 7: API HTTP 500 spike → OK (5xx=0)
CHECK 8: Worker restarts → OK
COMPLETE: 0 alerts
```

### Test alerte réelle (Vault faux positif corrigé)
- Run initial avec `curl -sf` : HTTP 429 (standby) interprété comme erreur → email envoyé
- Fix : `curl -s` (sans `-f`) + case statement pour 200/429/473
- Après fix : 3 runs consécutifs, 0 faux positif

### Stabilité
- 5+ runs automatiques successifs sans alerte erronée
- Temps d'exécution constant : 10-13s
- Aucun pod en erreur

---

## 9. Paramètres Configurables

| Variable | Défaut | Description |
|----------|--------|-------------|
| `VAULT_ADDR` | `http://vault.default.svc.cluster.local:8200` | Endpoint Vault |
| `ALERT_ENV` | `prod` | Environnement à monitorer (dev/prod) |
| `LOG_WINDOW` | `180` | Fenêtre de logs en secondes (3 min) |
| `RESTART_THRESHOLD` | `3` | Seuil restarts pour alerte |
| `ERROR_RATE_THRESHOLD` | `5` | Seuil erreurs pour spike |
| `SMTP_HOST` | `10.0.0.160` | Serveur SMTP |
| `SMTP_TO` | `sre@keybuzz.io` | Destinataire email |
| `WEBHOOK_URL` | *(vide)* | URL webhook (optionnel) |

---

## 10. Opérations

### Vérifier le statut
```bash
kubectl get cronjob monitoring-alerts -n vault-management
kubectl get jobs -n vault-management -l app.kubernetes.io/component=monitoring-alerts
```

### Voir les logs du dernier run
```bash
LATEST=$(kubectl get pods -n vault-management -l app.kubernetes.io/component=monitoring-alerts \
  --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
kubectl logs "$LATEST" -n vault-management
```

### Test manuel
```bash
kubectl create job --from=cronjob/monitoring-alerts monitoring-manual-test -n vault-management
```

### Suspendre le monitoring
```bash
kubectl patch cronjob monitoring-alerts -n vault-management -p '{"spec":{"suspend":true}}'
```

### Reprendre
```bash
kubectl patch cronjob monitoring-alerts -n vault-management -p '{"spec":{"suspend":false}}'
```

### Rollback complet
```bash
kubectl delete cronjob monitoring-alerts -n vault-management
kubectl delete configmap monitoring-alert-script -n vault-management
kubectl delete clusterrolebinding keybuzz-monitor
kubectl delete clusterrole keybuzz-monitor
kubectl delete sa keybuzz-monitor -n vault-management
```

---

## 11. Cohabitation avec Alertmanager Existant

Le CronJob complète (ne remplace pas) le stack Prometheus/Alertmanager :

| Alertmanager (existant) | CronJob monitoring-alerts (nouveau) |
|------------------------|--------------------------------------|
| Métriques Prometheus (CPU, mémoire, disk) | Health checks applicatifs |
| Règles PrometheusRules | Scan de logs en temps réel |
| Alertes infrastructure | Alertes business (Amazon, Shopify) |
| Receiver: email + webhook monitor | Receiver: email + webhook Discord/Slack |

Les deux systèmes sont indépendants et ne se chevauchent pas.
