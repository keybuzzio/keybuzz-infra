# PH-SHOPIFY-PROD-PROMOTION-01 — Promotion Shopify en PROD

> Date : 9 avril 2026
> Image PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod`
> Digest : `sha256:46522071903796f196552b4caecae1247b34104b92d4ae2d838ac229ba87c6f5`
> Rollback : `ghcr.io/keybuzzio/keybuzz-api:v3.5.225-ph-playbooks-v2-prod`

---

## Résumé

Promotion du module Shopify de DEV vers PROD :
- Image buildée depuis le même codebase que DEV (`v3.5.237`)
- Secret K8s créé avec clé d'encryption PROD séparée
- Tables DB migrées dans `keybuzz_prod`
- Env vars PROD injectées via deployment.yaml GitOps
- Zéro impact sur les fonctionnalités existantes

---

## Étape 1 — Build image

```
Tag:    ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod
Digest: sha256:46522071903796f196552b4caecae1247b34104b92d4ae2d838ac229ba87c6f5
Build:  docker build --no-cache (bastion, rebuild/ph143-api)
```

---

## Étape 2 — Manifest diff

```diff
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.225-ph-playbooks-v2-prod
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod

+ # --- Shopify PROD (PH-SHOPIFY-PROD-PROMOTION-01) ---
+ - name: SHOPIFY_REDIRECT_URI
+   value: "https://api.keybuzz.io/shopify/callback"
+ - name: SHOPIFY_CLIENT_REDIRECT_URL
+   value: "https://client.keybuzz.io/channels"
+ - name: SHOPIFY_CLIENT_ID
+   valueFrom: { secretKeyRef: { name: keybuzz-shopify, key: SHOPIFY_CLIENT_ID } }
+ - name: SHOPIFY_CLIENT_SECRET
+   valueFrom: { secretKeyRef: { name: keybuzz-shopify, key: SHOPIFY_CLIENT_SECRET } }
+ - name: SHOPIFY_ENCRYPTION_KEY
+   valueFrom: { secretKeyRef: { name: keybuzz-shopify, key: SHOPIFY_ENCRYPTION_KEY } }
+ - name: SHOPIFY_WEBHOOK_URL
+   value: "https://api.keybuzz.io/webhooks/shopify"
```

---

## Étape 3 — Secret PROD

```
Secret: keybuzz-shopify
Namespace: keybuzz-api-prod
Keys: SHOPIFY_CLIENT_ID (set), SHOPIFY_CLIENT_SECRET (set), SHOPIFY_ENCRYPTION_KEY (set)
Encryption key: unique PROD (différente de DEV), 64 hex chars
```

---

## Étape 4 — DB PROD

Tables créées dans `keybuzz_prod` :
- `shopify_connections` (avec `token_expires_at`, `refresh_token_enc`)
- `shopify_webhook_events`
- Index : `idx_shopify_conn_tenant`, `idx_shopify_webhook_topic`

Vérification : Amazon orders (11 835) et conversations (447) intactes.

---

## Étape 6 — Validation PROD

| Test | Résultat |
|------|----------|
| API health | OK |
| 6 env vars Shopify chargées | OK |
| 6 modules Shopify présents | OK |
| Root handler (managed install) | OK (6 refs) |
| `/shopify/status` endpoint | OK (`connected: false`) |
| Tables DB Shopify | OK (vides, prêtes) |
| Startup logs | Clean (aucune erreur) |

---

## Étape 7 — Non-régression

| Système | Avant | Après | Verdict |
|---------|-------|-------|---------|
| Amazon orders | 11 835 | 11 835 | OK |
| Conversations | 447 | 447 | OK |
| Conv. status | 43 open, 20 pending, 384 resolved | identique | OK |
| AI Wallet ecomlg | 899.03 KBA | 899.03 KBA | OK |
| Client PROD | HTTP 307 | HTTP 307 | OK |
| API health | ok | ok | OK |

---

## Étape 8 — Rollback

### Procédure

```bash
# 1. Modifier deployment.yaml
# image: ghcr.io/keybuzzio/keybuzz-api:v3.5.225-ph-playbooks-v2-prod
# (retirer le bloc env Shopify)

# 2. Appliquer
kubectl apply -f deployment.yaml

# 3. OU rollback rapide
kubectl rollout undo deployment/keybuzz-api -n keybuzz-api-prod
```

### Image rollback

```
ghcr.io/keybuzzio/keybuzz-api:v3.5.225-ph-playbooks-v2-prod
```

Les tables DB Shopify restent présentes mais sont inoffensives (aucune requête ne les touche dans l'ancienne image).

---

## Alignement DEV / PROD

| Élément | DEV | PROD |
|---------|-----|------|
| Image | `v3.5.237-ph-shopify-expiring-dev` | `v3.5.237-ph-shopify-expiring-prod` |
| Codebase | identique | identique |
| Shopify modules | 6 fichiers | 6 fichiers |
| Root handler | present | present |
| Secret | `keybuzz-shopify` (dev) | `keybuzz-shopify` (prod) |
| Encryption key | DEV key | PROD key (différente) |
| Redirect URI | `api-dev.keybuzz.io/shopify/callback` | `api.keybuzz.io/shopify/callback` |
| Webhook URL | `api-dev.keybuzz.io/webhooks/shopify` | `api.keybuzz.io/webhooks/shopify` |
| Client return | `client-dev.keybuzz.io/channels` | `client.keybuzz.io/channels` |

---

## Prochaine étape

Pour activer Shopify sur un tenant PROD :
1. Déployer le TOML PROD via `shopify app deploy --config shopify.app.prod.toml`
2. Connecter une boutique Shopify réelle depuis la page Canaux en PROD
3. L'OAuth managed install + tokens rotatifs fonctionneront identiquement au DEV

---

## Verdict

**SHOPIFY PROD PROMOTION COMPLETE — DEV/PROD ALIGNED — ZERO DRIFT**
