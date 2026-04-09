# PH-SHOPIFY-PROD-APP-SETUP-01 — Alignement app Shopify PROD

> Date : 9 avril 2026
> Statut : PRÉPARATION UNIQUEMENT — aucune activation PROD
> PROD API : `v3.5.225-ph-playbooks-v2-prod` (inchangée)
> DEV API : `v3.5.237-ph-shopify-expiring-dev` (référence Shopify validée)

---

## 1. Configuration Shopify PROD figée

### App Shopify PROD

| Paramètre | Valeur |
|-----------|--------|
| App name | **KeyBuzz** |
| Client ID | `f3bdeaa03490add7e39c7dabb812d726` |
| Client Secret | *(dans Shopify Partner Dashboard, pas en clair)* |
| Application URL | `https://api.keybuzz.io` |
| Embedded | `false` |

### URLs PROD

| Endpoint | URL |
|----------|-----|
| OAuth callback | `https://api.keybuzz.io/shopify/callback` |
| Webhook endpoint | `https://api.keybuzz.io/webhooks/shopify` |
| Frontend return | `https://client.keybuzz.io/channels` |
| Managed install | `https://admin.shopify.com/store/{handle}/oauth/install?client_id=f3bdeaa03490add7e39c7dabb812d726` |

### Scopes V1

```
read_orders, read_customers, read_fulfillments, read_returns
```

### Webhooks enregistrés (via TOML)

| Topic | Type |
|-------|------|
| `orders/create` | Event |
| `orders/updated` | Event |
| `app/uninstalled` | Event |
| `customers/data_request` | Compliance |
| `customers/redact` | Compliance |
| `shop/redact` | Compliance |

---

## 2. TOML PROD

Fichier : `shopify-app-config/shopify.app.prod.toml`

```toml
name = "KeyBuzz"
client_id = "f3bdeaa03490add7e39c7dabb812d726"
application_url = "https://api.keybuzz.io"
embedded = false

[access_scopes]
scopes = "read_orders,read_customers,read_fulfillments,read_returns"
use_legacy_install_flow = false

[auth]
redirect_urls = ["https://api.keybuzz.io/shopify/callback"]

[webhooks]
api_version = "2024-10"
# orders/create, orders/updated, app/uninstalled (event)
# customers/data_request, customers/redact, shop/redact (compliance)
```

Déploiement TOML PROD :
```bash
cd keybuzz-infra/shopify-app-config
shopify app deploy --config shopify.app.prod.toml
```

---

## 3. Stratégie secrets PROD

### Secret K8s : `keybuzz-shopify` dans `keybuzz-api-prod`

| Clé | Source |
|-----|--------|
| `SHOPIFY_CLIENT_ID` | Shopify Partner Dashboard |
| `SHOPIFY_CLIENT_SECRET` | Shopify Partner Dashboard |
| `SHOPIFY_ENCRYPTION_KEY` | Auto-généré (32 bytes hex, unique PROD) |

### Création

```bash
# Sur le bastion (PAS dans Git)
bash scripts/ph-shopify-prod/create-prod-secret.sh \
  "<CLIENT_ID_PROD>" \
  "<CLIENT_SECRET_PROD>"
```

Le script génère automatiquement l'`ENCRYPTION_KEY` PROD (différente de DEV).

### Env vars à ajouter au deployment.yaml PROD

Bloc préparé dans : `scripts/ph-shopify-prod/prod-deployment-env-block.yaml`

| Variable | Type | Valeur PROD |
|----------|------|-------------|
| `SHOPIFY_REDIRECT_URI` | plain | `https://api.keybuzz.io/shopify/callback` |
| `SHOPIFY_CLIENT_REDIRECT_URL` | plain | `https://client.keybuzz.io/channels` |
| `SHOPIFY_CLIENT_ID` | secretKeyRef | `keybuzz-shopify/SHOPIFY_CLIENT_ID` |
| `SHOPIFY_CLIENT_SECRET` | secretKeyRef | `keybuzz-shopify/SHOPIFY_CLIENT_SECRET` |
| `SHOPIFY_ENCRYPTION_KEY` | secretKeyRef | `keybuzz-shopify/SHOPIFY_ENCRYPTION_KEY` |
| `SHOPIFY_WEBHOOK_URL` | plain | `https://api.keybuzz.io/webhooks/shopify` |

---

## 4. Tableau de vérité DEV vs PROD

| Élément | DEV | PROD |
|---------|-----|------|
| **App Shopify** | KeyBuzz DEV | KeyBuzz |
| **Client ID** | `77b26855...` | `f3bdeaa0...` |
| **Store test** | `keybuzz-dev.myshopify.com` | `keybuzz-2.myshopify.com` |
| **Application URL** | `https://api-dev.keybuzz.io` | `https://api.keybuzz.io` |
| **OAuth callback** | `https://api-dev.keybuzz.io/shopify/callback` | `https://api.keybuzz.io/shopify/callback` |
| **Webhook URL** | `https://api-dev.keybuzz.io/webhooks/shopify` | `https://api.keybuzz.io/webhooks/shopify` |
| **Frontend return** | `https://client-dev.keybuzz.io/channels` | `https://client.keybuzz.io/channels` |
| **Scopes** | `read_orders,read_customers,read_fulfillments,read_returns` | identique |
| **API version** | `2024-10` | identique |
| **Managed install** | `use_legacy_install_flow = false` | identique |
| **Token type** | Expiring (1h) + refresh | identique |
| **Encryption** | AES-256-GCM (clé DEV) | AES-256-GCM (clé PROD séparée) |
| **Secret K8s** | `keybuzz-shopify` dans `keybuzz-api-dev` | `keybuzz-shopify` dans `keybuzz-api-prod` |
| **TOML** | `shopify.app.toml` | `shopify.app.prod.toml` |
| **DB** | `keybuzz` | `keybuzz_prod` |

---

## 5. Prérequis avant promotion KeyBuzz PROD

### Ordre d'exécution obligatoire

1. **Déployer le TOML PROD** via Shopify CLI
   ```bash
   shopify app deploy --config shopify.app.prod.toml
   ```

2. **Créer le secret K8s PROD**
   ```bash
   bash scripts/ph-shopify-prod/create-prod-secret.sh <CLIENT_ID> <CLIENT_SECRET>
   ```

3. **Migrer la DB PROD** (créer tables)
   ```bash
   bash scripts/ph-shopify-prod/migrate-prod-db.sh
   ```

4. **Ajouter les env vars** au deployment.yaml PROD
   (copier le bloc de `prod-deployment-env-block.yaml`)

5. **Build l'image PROD** depuis le code DEV validé
   ```bash
   cd /opt/keybuzz/keybuzz-api
   docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod .
   docker push ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod
   ```

6. **Mettre à jour** le deployment.yaml avec le nouveau tag

7. **Déployer** et vérifier
   ```bash
   kubectl set image deploy/keybuzz-api keybuzz-api=<NEW_TAG> -n keybuzz-api-prod
   kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
   ```

8. **Vérifier** la readiness
   ```bash
   bash scripts/ph-shopify-prod/verify-prod-readiness.sh
   ```

### Checklist pré-promotion

- [ ] TOML PROD déployé via Shopify CLI
- [ ] Secret `keybuzz-shopify` créé dans `keybuzz-api-prod`
- [ ] Tables DB créées dans `keybuzz_prod`
- [ ] Env vars ajoutées au deployment.yaml PROD
- [ ] Image PROD buildée et pushée (depuis code DEV validé)
- [ ] deployment.yaml PROD mis à jour (image + env vars)
- [ ] API PROD healthy après déploiement
- [ ] Connexion test Shopify fonctionnelle en PROD

---

## 6. Non-régression confirmée

| Vérification | Résultat |
|-------------|----------|
| Image PROD API | `v3.5.225-ph-playbooks-v2-prod` — **INCHANGÉE** |
| Image PROD Client | `v3.5.225-ph-playbooks-v2-prod` — **INCHANGÉE** |
| Shopify env vars PROD | **AUCUNE** |
| Secret `keybuzz-shopify` PROD | **N'EXISTE PAS** |
| Code Shopify dans image PROD | **ABSENT** |
| PROD API health | **OK** |
| PROD orders (Amazon) | 11 835 |
| PROD conversations | 447 |
| Feature Shopify visible PROD | **NON** |

**ZÉRO activation PROD confirmée.**

---

## 7. Artefacts livrés

| Fichier | Rôle |
|---------|------|
| `shopify-app-config/shopify.app.prod.toml` | Config TOML pour Shopify CLI |
| `scripts/ph-shopify-prod/create-prod-secret.sh` | Création secret K8s (sans secrets en clair) |
| `scripts/ph-shopify-prod/migrate-prod-db.sh` | Migration DB PROD |
| `scripts/ph-shopify-prod/prod-deployment-env-block.yaml` | Bloc env vars prêt à copier |
| `scripts/ph-shopify-prod/verify-prod-readiness.sh` | Script de vérification pré/post promotion |

---

## Verdict

**SHOPIFY PROD APP READY — KEYBUZZ PROD PROMOTION CAN BE PREPARED**

Toute la configuration externe (app Shopify, TOML, secrets, migration DB, env vars) est documentée et prête.
Aucune activation côté PROD. Le prochain step est PH-SHOPIFY-PROD-PROMOTION-01 sur validation explicite.
