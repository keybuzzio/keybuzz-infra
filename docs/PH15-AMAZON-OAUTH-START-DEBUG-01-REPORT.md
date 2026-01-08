# PH15-AMAZON-OAUTH-START-DEBUG-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

L'erreur "Failed to start Amazon OAuth" était causée par l'impossibilité du pod backend-dev d'accéder à Vault (10.0.0.150) depuis le cluster K8s.

---

## 1. Cause Racine

### Erreur Initiale

```json
{"error":"Failed to start Amazon OAuth","details":"Amazon SP-API client_id not configured"}
```

puis après ajout du secret vault-token :

```json
{"error":"Failed to start Amazon OAuth","details":"fetch failed"}
```

### Analyse

1. Le pod `keybuzz-backend-dev` avait `VAULT_ADDR=https://10.0.0.150:8200` configuré
2. Le réseau K8s ne peut pas atteindre le réseau interne 10.0.0.0/8
3. Le fetch vers Vault échouait, et le code propageait l'erreur sans fallback

### Solution

Supprimer les références à Vault et injecter les credentials Amazon directement via env vars :

```bash
# Créer le secret avec les credentials Amazon
kubectl -n keybuzz-backend-dev create secret generic amazon-spapi-creds \
  --from-literal=AMAZON_SPAPI_CLIENT_ID=amzn1.application-oa2-client.*** \
  --from-literal=AMAZON_SPAPI_CLIENT_SECRET=amzn1.oa2-cs.v1.*** \
  --from-literal=AMAZON_SPAPI_APP_ID=amzn1.sp.solution.*** \
  --from-literal=AMAZON_SPAPI_REDIRECT_URI=https://platform-api.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback

# Supprimer VAULT_ADDR pour forcer le fallback env vars
kubectl -n keybuzz-backend-dev set env deployment/keybuzz-backend VAULT_ADDR- VAULT_TOKEN-
```

---

## 2. Preuve Backend Fonctionne

### Avant

```bash
curl -X POST backend-dev.keybuzz.io/.../oauth/start ...
# {"error":"Failed to start Amazon OAuth","details":"fetch failed"}
```

### Après

```bash
curl -X POST backend-dev.keybuzz.io/.../oauth/start \
  -H "X-User-Email: ludo.gonthier@gmail.com" \
  -H "X-Tenant-Id: kbz-001" \
  -d '{}'

# Réponse (authUrl tronquée) :
{
  "success": true,
  "authUrl": "https://sellercentral.amazon.com/apps/authorize/consent?application_id=amzn1.sp.solution.***&state=75a623ee-***&version=beta&redirect_uri=https%3A%2F%2Fplatform-api.keybuzz.io%2Fapi%2Fv1%2Fmarketplaces%2Famazon%2Foauth%2Fcallback",
  "state": "75a623ee-2e14-4d76-85ea-70a02a5298bc",
  "expiresAt": "2026-01-08T09:29:21.707Z"
}
```

---

## 3. Flow Corrigé

```
┌─────────────────────────────────────────────────────────────┐
│  1. Client fetch POST /api/amazon/oauth/start               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Route Next.js → POST backend-dev/oauth/start            │
│     Headers: X-User-Email, X-Tenant-Id                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Backend lit credentials depuis ENV (pas Vault)          │
│     → Génère authUrl Amazon Seller Central                  │
│     → Retourne JSON { authUrl, state }                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Client: window.location.assign(authUrl)                 │
│     → Navigation vers Amazon Seller Central                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Configuration Backend-Dev Finale

```yaml
# Deployment keybuzz-backend-dev
env:
  - name: NODE_ENV
    value: production
  - name: PORT
    value: "4000"
  - name: JWT_SECRET
    value: keybuzz-dev-jwt-secret-2026
  - name: KEYBUZZ_DEV_MODE
    value: "true"
  # PAS de VAULT_ADDR, VAULT_TOKEN
envFrom:
  - secretRef:
      name: keybuzz-backend-db
  - secretRef:
      name: amazon-spapi-creds  # Credentials Amazon
```

---

## 5. Commits

| Repo | Commit | Description |
|------|--------|-------------|
| keybuzz-infra | `3a37d87` | backend-dev uses env vars for Amazon SPAPI |

---

## 6. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-client | v0.2.41-dev (inchangé) |
| keybuzz-backend | v0.1.9-dev (config modifiée) |

---

## 7. Recommandation Future

Pour utiliser Vault depuis K8s, il faudrait :
- Exposer Vault via un Ingress accessible depuis le cluster
- OU utiliser Vault Agent Injector
- OU External Secrets Operator avec un backend Vault accessible

Pour DEV, l'approche env vars est acceptable.

---

**Fin du rapport PH15-AMAZON-OAUTH-START-DEBUG-01**
