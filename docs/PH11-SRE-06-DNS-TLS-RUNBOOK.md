# PH11-SRE-06 — Runbook DNS/TLS KeyBuzz

## Date de création
3 janvier 2026

---

## 1. Architecture DNS

### Load Balancers Hetzner (entrée publique)
| IP | Rôle | Ports |
|----|------|-------|
| 49.13.42.76 | Hetzner LB #1 | 80, 443 |
| 138.199.132.240 | Hetzner LB #2 | 80, 443 |

Ces LBs distribuent le trafic vers les NodePorts K8s:
- HTTP: 31169
- HTTPS: 31631

### Flux réseau
```
Internet → Hetzner LBs (49.13.42.76, 138.199.132.240)
         → K8s NodePorts (31169/31631)
         → ingress-nginx DaemonSet
         → Services K8s internes
```

---

## 2. Endpoints DEV (Actifs)

| FQDN | Type | IPs | Namespace | Service Backend | Cert Expiry |
|------|------|-----|-----------|-----------------|-------------|
| admin-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-admin-dev | keybuzz-admin:3000 | 9 mars 2026 |
| client-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-client-dev | keybuzz-client:3000 | 31 mars 2026 |
| api-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-api-dev | keybuzz-api:3001 | 23 mars 2026 |
| grafana-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | observability | kube-prometheus-grafana:80 | 3 avril 2026 |

### Vérification DEV
```bash
# Script automatique (tourne toutes les 60s sur monitor-01)
ssh root@10.0.0.152 'cat /opt/keybuzz/logs/sre/endpoints/check_*.json | tail -1 | python3 -m json.tool'

# Vérification manuelle
for host in admin-dev.keybuzz.io client-dev.keybuzz.io api-dev.keybuzz.io grafana-dev.keybuzz.io; do
    echo "$host: $(curl -s -o /dev/null -w '%{http_code}' https://$host)"
done
```

---

## 3. Endpoints PROD (Actifs)

| FQDN | Type | IPs | Namespace | Service Backend | Cert Expiry |
|------|------|-----|-----------|-----------------|-------------|
| admin.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-admin | keybuzz-admin:3000 | 9 mars 2026 |
| platform-api.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-api | keybuzz-backend:4000 | 16 mars 2026 |
| llm.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-ai | litellm:80 | 12 mars 2026 |

---

## 4. Endpoints PROD à créer (Préparation)

### Checklist pré-déploiement PROD

| FQDN | Type | IPs | Action requise | Status |
|------|------|-----|----------------|--------|
| grafana.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Créer record DNS + Ingress | ⏳ À planifier |
| client.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Créer record DNS + Ingress | ⏳ Après déploiement |
| prometheus.keybuzz.io | A | (optionnel) | Accès interne recommandé | ⏸️ Non prioritaire |

### Manifests prêts (non appliqués)

```yaml
# k8s/observability/grafana-ingress-prod.yaml (À CRÉER)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-prod
  namespace: observability
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - grafana.keybuzz.io
    secretName: grafana-prod-tls
  rules:
  - host: grafana.keybuzz.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-grafana
            port:
              number: 80
```

---

## 5. Conflit api.keybuzz.io

### Situation actuelle
- `api.keybuzz.io` résout vers: 49.13.42.76, 138.199.132.240 (K8s LB)
- Historiquement utilisé pour GoHighLevel (GHL)
- **RISQUE**: Modifier ce record pourrait casser des intégrations existantes

### Plan de bascule (quand validé par Ludovic)

1. **Inventorier** les usages actuels de `api.keybuzz.io`
2. **Créer** `ghl.keybuzz.io` comme alias CNAME vers l'endpoint GHL actuel
3. **Migrer** les intégrations GHL vers `ghl.keybuzz.io`
4. **Rediriger** `api.keybuzz.io` vers la nouvelle API KeyBuzz (ou supprimer si plus utilisé)

### Recommandation actuelle
| Cas d'usage | FQDN | Status |
|-------------|------|--------|
| KeyBuzz API PROD | platform-api.keybuzz.io | ✅ Actif |
| KeyBuzz API DEV | api-dev.keybuzz.io | ✅ Actif |
| GoHighLevel | ghl.keybuzz.io | ⏳ À créer |
| Legacy | api.keybuzz.io | ⚠️ Ne pas modifier |

---

## 6. TLS / Cert-Manager

### ClusterIssuers
| Nom | Status | Usage |
|-----|--------|-------|
| letsencrypt-prod | ✅ Ready | Production |
| letsencrypt-staging | ✅ Ready | Tests |

### Alerting TLS
Les alertes suivantes sont configurées (PrometheusRule `cert-manager-alerts`):
- `CertificateExpiringIn14Days` (warning)
- `CertificateExpiringIn7Days` (critical)
- `CertificateExpiringIn3Days` (critical)
- `CertificateNotReady` (critical)
- `ACMEChallengesFailing` (warning)
- `CertManagerDown` (critical)

### Vérifier les certificats
```bash
# Tous les certificats
kubectl get certificate -A

# Détails d'un certificat
kubectl describe certificate <name> -n <namespace>

# Expiration via openssl
echo | openssl s_client -connect admin-dev.keybuzz.io:443 -servername admin-dev.keybuzz.io 2>/dev/null | openssl x509 -noout -dates
```

---

## 7. Procédures de Rollback

### Si cert-manager bloque un renouvellement

1. **Diagnostiquer**:
```bash
kubectl describe certificate <name> -n <namespace>
kubectl describe certificaterequest -n <namespace>
kubectl logs -n cert-manager deploy/cert-manager
```

2. **Forcer le renouvellement**:
```bash
# Supprimer le secret TLS (cert-manager va recréer)
kubectl delete secret <tls-secret-name> -n <namespace>
# Le Certificate va automatiquement déclencher un nouveau CertificateRequest
```

3. **Si ACME rate-limited**:
- Attendre (limite = 5 échecs/h, 50 certs/semaine/domaine)
- Utiliser `letsencrypt-staging` pour tests

### Si issuer KO

1. **Vérifier le ClusterIssuer**:
```bash
kubectl describe clusterissuer letsencrypt-prod
```

2. **Recréer si nécessaire**:
```bash
kubectl delete clusterissuer letsencrypt-prod
kubectl apply -f keybuzz-infra/k8s/cert-manager/clusterissuer-prod.yaml
```

### Si Ingress ne route plus

1. **Vérifier les pods ingress-nginx**:
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <pod-name>
```

2. **Redémarrer si nécessaire**:
```bash
kubectl rollout restart daemonset ingress-nginx-controller -n ingress-nginx
```

---

## 8. Monitoring

### Endpoints checker (monitor-01)
- **Service**: `keybuzz-endpoints-checker.service`
- **Timer**: `keybuzz-endpoints-checker.timer` (60s)
- **Logs**: `/opt/keybuzz/logs/sre/endpoints/*.json`

```bash
# Status
ssh root@10.0.0.152 'systemctl status keybuzz-endpoints-checker.timer'

# Dernier check
ssh root@10.0.0.152 'cat $(ls -t /opt/keybuzz/logs/sre/endpoints/check_*.json | head -1) | python3 -m json.tool'
```

### Prometheus alerts
- **cert-manager-alerts**: Expiration TLS, ACME errors
- **ingress-nginx-alerts**: Controller down, error rates
- **keybuzz-infra-alerts**: NodeDown, DiskSpace, etc.

---

## 9. Contacts & Escalation

| Niveau | Contact | Délai |
|--------|---------|-------|
| L1 | Alertes Prometheus/Grafana | Automatique |
| L2 | SRE on-call | 15 min |
| L3 | Ludovic | 1h (heures ouvrées) |

---

## 10. Annexes

### Records DNS à créer (pour fournisseur DNS)

| Type | Nom | Valeur | TTL | Environnement |
|------|-----|--------|-----|---------------|
| A | admin-dev | 49.13.42.76 | 300 | DEV ✅ |
| A | admin-dev | 138.199.132.240 | 300 | DEV ✅ |
| A | client-dev | 49.13.42.76 | 300 | DEV ✅ |
| A | client-dev | 138.199.132.240 | 300 | DEV ✅ |
| A | api-dev | 49.13.42.76 | 300 | DEV ✅ |
| A | api-dev | 138.199.132.240 | 300 | DEV ✅ |
| A | grafana-dev | 49.13.42.76 | 300 | DEV ✅ |
| A | grafana-dev | 138.199.132.240 | 300 | DEV ✅ |
| A | grafana | 49.13.42.76 | 300 | PROD ⏳ |
| A | grafana | 138.199.132.240 | 300 | PROD ⏳ |
| A | client | 49.13.42.76 | 300 | PROD ⏳ |
| A | client | 138.199.132.240 | 300 | PROD ⏳ |
