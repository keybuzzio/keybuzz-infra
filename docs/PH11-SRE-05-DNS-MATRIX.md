# PH11-SRE-05 — Matrice DNS KeyBuzz

## Date de génération
3 janvier 2026

## Configuration DNS actuelle

### IPs Load Balancer K8s (Hetzner)
| IP | Rôle |
|----|------|
| 49.13.42.76 | Hetzner LB #1 |
| 138.199.132.240 | Hetzner LB #2 |

> **Note:** Ces IPs sont les Load Balancers Hetzner qui distribuent le trafic vers les NodePorts des workers K8s (HTTP: 31169, HTTPS: 31631).

---

## Endpoints DEV (Environnement de développement)

| FQDN | Type | Valeur(s) | Namespace K8s | Backend Service | Cert Status |
|------|------|-----------|---------------|-----------------|-------------|
| admin-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-admin-dev | keybuzz-admin:3000 | ✅ Ready |
| client-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-client-dev | keybuzz-client:3000 | ✅ Ready |
| api-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-api-dev | keybuzz-api:3001 | ✅ Ready |
| grafana-dev.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | observability | kube-prometheus-grafana:80 | ✅ Ready |

---

## Endpoints PROD (Environnement de production)

| FQDN | Type | Valeur(s) | Namespace K8s | Backend Service | Cert Status |
|------|------|-----------|---------------|-----------------|-------------|
| admin.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-admin | keybuzz-admin:3000 | ✅ Ready |
| platform-api.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-api | keybuzz-backend:4000 | ✅ Ready |
| llm.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | keybuzz-ai | litellm:80 | ✅ Ready |

---

## Endpoints à créer (préparation PROD)

| FQDN | Type | Valeur(s) | Notes |
|------|------|-----------|-------|
| grafana.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Grafana PROD (quand nécessaire) |
| prometheus.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Prometheus PROD (optionnel, accès interne recommandé) |
| client.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Client PROD (à déployer) |

---

## ⚠️ Conflit api.keybuzz.io

### Situation actuelle
- `api.keybuzz.io` résout vers: **49.13.42.76, 138.199.132.240** (K8s LB)
- Mais historiquement utilisé pour GoHighLevel (GHL)

### Recommandation
| Cas d'usage | FQDN recommandé | Configuration |
|-------------|-----------------|---------------|
| API KeyBuzz Platform | platform-api.keybuzz.io | ✅ Déjà configuré |
| API KeyBuzz DEV | api-dev.keybuzz.io | ✅ Déjà configuré |
| GoHighLevel | ghl.keybuzz.io | À créer si nécessaire (CNAME vers GHL) |

> **Action:** Si GHL est toujours utilisé, créer `ghl.keybuzz.io` comme CNAME vers le endpoint GHL et documenter la migration.

---

## Résumé des actions DNS

### ✅ Déjà configuré (aucune action requise)
- admin-dev.keybuzz.io
- client-dev.keybuzz.io
- api-dev.keybuzz.io
- grafana-dev.keybuzz.io
- admin.keybuzz.io
- platform-api.keybuzz.io
- llm.keybuzz.io

### 📋 À créer (quand PROD prêt)
| FQDN | Type | Valeur | Priorité |
|------|------|--------|----------|
| grafana.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | Medium |
| client.keybuzz.io | A | 49.13.42.76, 138.199.132.240 | High (après déploiement) |
| ghl.keybuzz.io | CNAME | (endpoint GHL) | Low (si GHL utilisé) |

---

## Vérification DNS

```bash
# Vérifier la résolution DNS
for host in admin-dev.keybuzz.io client-dev.keybuzz.io api-dev.keybuzz.io grafana-dev.keybuzz.io; do
    echo "$host: $(dig +short $host | tr '\n' ' ')"
done

# Vérifier les certificats
for host in admin-dev.keybuzz.io client-dev.keybuzz.io api-dev.keybuzz.io grafana-dev.keybuzz.io; do
    echo "$host: $(echo | openssl s_client -connect $host:443 -servername $host 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep notAfter)"
done
```

---

## Architecture réseau

```
                    Internet
                        │
            ┌───────────┴───────────┐
            │                       │
       49.13.42.76          138.199.132.240
       (Hetzner LB #1)      (Hetzner LB #2)
            │                       │
            └───────────┬───────────┘
                        │
                   NodePort
              (HTTP:31169, HTTPS:31631)
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   k8s-worker-01   k8s-worker-02   k8s-worker-03...
        │               │               │
        └───────────────┼───────────────┘
                        │
              ingress-nginx-controller
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   admin-dev       client-dev      grafana-dev
   api-dev         admin           platform-api
                   llm
```
