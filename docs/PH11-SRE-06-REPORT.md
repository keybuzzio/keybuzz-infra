# PH11-SRE-06 — Rapport Final TLS/DNS/Ingress Hardening

## Date d'exécution
3 janvier 2026

---

## Résumé

✅ **DEV OK / PROD UNTOUCHED**

Toutes les améliorations ont été déployées en DEV uniquement. Aucune modification en production.

---

## 1. Ce qui a été déployé

### Cert-Manager Monitoring
| Fichier | Description |
|---------|-------------|
| `k8s/observability/cert-manager-servicemonitor.yaml` | ServiceMonitor pour scraper les métriques cert-manager |
| `k8s/observability/cert-manager-alerts.yaml` | PrometheusRule avec 7 alertes TLS |

**Alertes créées:**
- `CertificateExpiringIn14Days` (warning)
- `CertificateExpiringIn7Days` (critical)
- `CertificateExpiringIn3Days` (critical)
- `CertificateNotReady` (critical)
- `ACMEChallengesFailing` (warning)
- `CertManagerDown` (critical)
- `CertificateRenewalFailed` (critical)

### Ingress-Nginx Monitoring
| Fichier | Description |
|---------|-------------|
| `k8s/observability/ingress-nginx-metrics-service.yaml` | Service pour exposer les métriques (port 10254) |
| `k8s/observability/ingress-nginx-servicemonitor.yaml` | ServiceMonitor pour Prometheus |
| `k8s/observability/ingress-nginx-alerts.yaml` | PrometheusRule avec 7 alertes |

**Alertes créées:**
- `IngressNginxControllerDown` (critical)
- `IngressNginxControllerPodCrashLooping` (warning)
- `IngressNginxHighErrorRate` (warning, >5%)
- `IngressNginxCriticalErrorRate` (critical, >15%)
- `IngressHostHighErrorRate` (warning)
- `IngressNginxHighLatency` (warning)
- `IngressNginxSSLExpiringSoon` (warning)

### Endpoint Checker (monitor-01)
| Fichier | Description |
|---------|-------------|
| `scripts/ph11_sre06_check_endpoints_dev.sh` | Script de vérification automatique |
| `scripts/ph11_sre06_install_endpoint_checker_monitor01.sh` | Script d'installation |

**Installé sur monitor-01:**
- Service: `keybuzz-endpoints-checker.service`
- Timer: `keybuzz-endpoints-checker.timer` (60s)
- Logs: `/opt/keybuzz/logs/sre/endpoints/*.json`

### Documentation
| Fichier | Description |
|---------|-------------|
| `docs/PH11-SRE-06-DNS-TLS-RUNBOOK.md` | Runbook complet DNS/TLS |
| `docs/PH11-SRE-06-REPORT.md` | Ce rapport |

---

## 2. Preuves kubectl

### PrometheusRules créées
```
$ kubectl get prometheusrules -n observability | grep -E "cert-manager|ingress-nginx"
cert-manager-alerts    3m
ingress-nginx-alerts   3m
```

### ServiceMonitors créés
```
$ kubectl get servicemonitor -n observability | grep -E "cert-manager|ingress-nginx"
cert-manager     3m
ingress-nginx    3m
```

### Certificats DEV (tous Ready)
```
NAMESPACE            NAME                    READY   SECRET
keybuzz-admin-dev    keybuzz-admin-dev-tls   True    keybuzz-admin-dev-tls
keybuzz-client-dev   keybuzz-client-tls      True    keybuzz-client-tls
keybuzz-api-dev      api-dev-tls             True    api-dev-tls
observability        grafana-tls             True    grafana-tls
```

---

## 3. Preuves Endpoint Checker

### Exemple de sortie JSON
```json
{
    "timestamp": "2026-01-03T18:29:29+00:00",
    "checker": "ph11_sre06_check_endpoints_dev",
    "endpoints": [
        {
            "host": "admin-dev.keybuzz.io",
            "dns": { "ok": true, "ips": "49.13.42.76,138.199.132.240" },
            "http": { "ok": true, "status": 200 },
            "tls": { "ok": true, "expiry": "Mar  9 17:23:42 2026 GMT", "days_remaining": 64 },
            "overall": "OK"
        },
        {
            "host": "client-dev.keybuzz.io",
            "dns": { "ok": true, "ips": "138.199.132.240,49.13.42.76" },
            "http": { "ok": true, "status": 200 },
            "tls": { "ok": true, "expiry": "Mar 31 11:42:30 2026 GMT", "days_remaining": 86 },
            "overall": "OK"
        },
        {
            "host": "api-dev.keybuzz.io",
            "dns": { "ok": true, "ips": "49.13.42.76,138.199.132.240" },
            "http": { "ok": true, "status": 404 },
            "tls": { "ok": true, "expiry": "Mar 23 19:21:16 2026 GMT", "days_remaining": 79 },
            "overall": "OK"
        },
        {
            "host": "grafana-dev.keybuzz.io",
            "dns": { "ok": true, "ips": "49.13.42.76,138.199.132.240" },
            "http": { "ok": true, "status": 302 },
            "tls": { "ok": true, "expiry": "Apr  3 15:41:27 2026 GMT", "days_remaining": 89 },
            "overall": "OK"
        }
    ],
    "status": "OK"
}
```

---

## 4. Preuves TLS - Expiration des certs DEV

| Host | Expiration | Jours restants |
|------|------------|----------------|
| admin-dev.keybuzz.io | 9 mars 2026 | 64 |
| client-dev.keybuzz.io | 31 mars 2026 | 86 |
| api-dev.keybuzz.io | 23 mars 2026 | 79 |
| grafana-dev.keybuzz.io | 3 avril 2026 | 89 |

**Tous les certificats ont plus de 60 jours de validité.**

---

## 5. PROD Status

### ✅ Non modifié
Les endpoints PROD suivants n'ont **PAS** été touchés:
- admin.keybuzz.io
- platform-api.keybuzz.io
- llm.keybuzz.io

### Préparation documentée
Le runbook `PH11-SRE-06-DNS-TLS-RUNBOOK.md` contient:
- Liste des records DNS PROD à créer
- Manifests Ingress prêts (non appliqués)
- Plan de migration `api.keybuzz.io`
- Procédures de rollback

---

## 6. Commandes de vérification

### Vérifier les alertes
```bash
kubectl get prometheusrules -n observability | grep -E "cert-manager|ingress"
```

### Vérifier les ServiceMonitors
```bash
kubectl get servicemonitor -n observability | grep -E "cert-manager|ingress"
```

### Vérifier l'endpoint checker
```bash
ssh root@10.0.0.152 'systemctl status keybuzz-endpoints-checker.timer'
ssh root@10.0.0.152 'cat $(ls -t /opt/keybuzz/logs/sre/endpoints/check_*.json | head -1)'
```

### Vérifier les certificats
```bash
kubectl get certificate -A
for host in admin-dev.keybuzz.io client-dev.keybuzz.io api-dev.keybuzz.io grafana-dev.keybuzz.io; do
    echo "$host: $(echo | openssl s_client -connect $host:443 -servername $host 2>/dev/null | openssl x509 -noout -enddate)"
done
```

---

## 7. Fichiers Git

### keybuzz-infra (commit PH11-SRE-06)
```
k8s/observability/cert-manager-servicemonitor.yaml     (new)
k8s/observability/cert-manager-alerts.yaml             (new)
k8s/observability/ingress-nginx-metrics-service.yaml   (new)
k8s/observability/ingress-nginx-servicemonitor.yaml    (new)
k8s/observability/ingress-nginx-alerts.yaml            (new)
scripts/ph11_sre06_check_endpoints_dev.sh              (new)
scripts/ph11_sre06_install_endpoint_checker_monitor01.sh (new)
docs/PH11-SRE-06-DNS-TLS-RUNBOOK.md                    (new)
docs/PH11-SRE-06-REPORT.md                             (new)
```

---

## 8. Critères d'acceptation

| Critère | Status |
|---------|--------|
| Aucun changement en PROD | ✅ |
| Cert-manager a des alert rules | ✅ |
| Ingress-nginx scrapé/monitoré | ✅ |
| Endpoint checker sur monitor-01 | ✅ |
| Docs claires (matrice DNS + runbook) | ✅ |
| Tout commité/pushé | ✅ |

---

## 9. Conclusion

**PH11-SRE-06 COMPLET**

Le hardening TLS/DNS/Ingress est en place avec:
- Alerting proactif sur les certificats
- Monitoring complet d'ingress-nginx
- Vérification automatique des endpoints DEV
- Documentation exhaustive pour PROD
