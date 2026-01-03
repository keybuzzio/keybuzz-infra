# PH11-SRE-05 — Rapport Final DNS + Ingress/Certs

## Date d'exécution
3 janvier 2026

---

## Résumé

✅ **Tous les endpoints DEV sont fonctionnels avec TLS valide.**

---

## 1. Ce qui a été détecté

### Ingress existants (7 total)

| Namespace | Host | Backend | TLS |
|-----------|------|---------|-----|
| keybuzz-admin-dev | admin-dev.keybuzz.io | keybuzz-admin:3000 | ✅ Ready |
| keybuzz-client-dev | client-dev.keybuzz.io | keybuzz-client:3000 | ✅ Ready |
| keybuzz-api-dev | api-dev.keybuzz.io | keybuzz-api:3001 | ✅ Ready |
| observability | grafana-dev.keybuzz.io | kube-prometheus-grafana:80 | ✅ Ready |
| keybuzz-admin | admin.keybuzz.io | keybuzz-admin:3000 | ✅ Ready |
| keybuzz-api | platform-api.keybuzz.io | keybuzz-backend:4000 | ✅ Ready |
| keybuzz-ai | llm.keybuzz.io | litellm:80 | ✅ Ready |

### DNS configuré
Tous les FQDN pointent vers les Load Balancers Hetzner:
- **49.13.42.76**
- **138.199.132.240**

### ClusterIssuers
- `letsencrypt-prod` ✅ Ready
- `letsencrypt-staging` ✅ Ready

---

## 2. Ce qui a été modifié

| Fichier | Action | Description |
|---------|--------|-------------|
| `docs/PH11-SRE-05-DNS-MATRIX.md` | Créé | Matrice DNS complète DEV/PROD |
| `k8s/observability/grafana-ingress.yaml` | Existant | Déjà configuré (PH11-SRE-04) |

---

## 3. Validation HTTP/TLS

### DEV Endpoints

| Host | HTTP | TLS | Expiration |
|------|------|-----|------------|
| admin-dev.keybuzz.io | ✅ 200 | ✅ Valid | 9 mars 2026 |
| client-dev.keybuzz.io | ✅ 200 | ✅ Valid | 31 mars 2026 |
| api-dev.keybuzz.io | 404* | ✅ Valid | 23 mars 2026 |
| grafana-dev.keybuzz.io | ✅ 302 | ✅ Valid | 3 avril 2026 |

> *404 sur api-dev est normal : l'API n'a pas de route sur `/`, utiliser `/health` ou `/api/v1/...`

### PROD Endpoints (lecture seule)

| Host | HTTP | TLS | Expiration |
|------|------|-----|------------|
| admin.keybuzz.io | ✅ 200 | ✅ Valid | 9 mars 2026 |
| platform-api.keybuzz.io | 404* | ✅ Valid | 16 mars 2026 |
| llm.keybuzz.io | ✅ 200 | ✅ Valid | 12 mars 2026 |

---

## 4. Conflit api.keybuzz.io

### Situation
- `api.keybuzz.io` pointe vers les LB K8s (49.13.42.76, 138.199.132.240)
- Historiquement utilisé pour GoHighLevel (GHL)

### Recommandation
- **KeyBuzz API:** Utiliser `platform-api.keybuzz.io` (✅ déjà configuré)
- **KeyBuzz API DEV:** Utiliser `api-dev.keybuzz.io` (✅ déjà configuré)
- **GoHighLevel:** Créer `ghl.keybuzz.io` si GHL est toujours utilisé

---

## 5. Commandes de vérification

### Vérifier les Ingress
```bash
kubectl get ingress -A
```

### Vérifier les certificats
```bash
kubectl get certificate -A
```

### Tester un endpoint
```bash
curl -Ik https://grafana-dev.keybuzz.io
```

### Vérifier l'expiration TLS
```bash
echo | openssl s_client -connect grafana-dev.keybuzz.io:443 -servername grafana-dev.keybuzz.io 2>/dev/null | openssl x509 -noout -dates
```

---

## 6. Fichiers livrables

| Fichier | Chemin |
|---------|--------|
| Matrice DNS | `keybuzz-infra/docs/PH11-SRE-05-DNS-MATRIX.md` |
| Logs validation | `/opt/keybuzz/logs/sre/ph11-sre-05/validation_*.log` |
| Rapport | `keybuzz-infra/docs/PH11-SRE-05-REPORT.md` |

---

## 7. Actions futures (PROD)

| Action | FQDN | Priorité |
|--------|------|----------|
| Créer DNS | grafana.keybuzz.io | Medium |
| Créer DNS | client.keybuzz.io | High (après déploiement client PROD) |
| Créer DNS | ghl.keybuzz.io | Low (si GHL nécessaire) |
| Créer Ingress PROD | grafana.keybuzz.io → observability | À planifier |

---

## Commit Git

```
PH11-SRE-05: DNS Matrix + Ingress/Certs documentation
```
