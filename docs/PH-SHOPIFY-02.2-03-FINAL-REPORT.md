# PH-SHOPIFY-02.2 + PH-SHOPIFY-03 — Rapport Final

> Date : 9 avril 2026
> API : `v3.5.237-ph-shopify-expiring-dev`
> TOML Shopify : `keybuzz-dev-7` (via Shopify CLI)
> Rollback : `v3.5.228-ph-shopify-021-scopes-dev`

---

## Résumé

Intégration complète Shopify en DEV :
- **OAuth managed install** avec tokens rotatifs (expiring=1, 1h, refresh_token)
- **Sync commandes** via GraphQL Admin API (initial + webhooks temps réel)
- **Webhooks conformité** (compliance GDPR + app/uninstalled)
- **Rotation automatique** des tokens avant expiration

## Problèmes résolus

### 1. Scopes non accordés
**Cause** : Le dev dashboard Shopify ne propose pas d'UI pour configurer les scopes.
**Fix** : Création de `shopify.app.toml` déployé via `shopify app deploy` (Shopify CLI v3.93.1).

### 2. Tokens non-expirants rejetés (403)
**Cause** : Depuis le 1er avril 2026, Shopify rejette les non-expiring offline tokens.
**Fix** : Ajout du paramètre `expiring: 1` dans la requête POST `/admin/oauth/access_token`.
La réponse inclut désormais `expires_in` (3599s) et `refresh_token`.

### 3. Managed install redirect → 404
**Cause** : Shopify redirige vers `application_url` (racine `/`) après l'install, pas vers le callback.
**Fix** : Handler `GET /` dans `app.ts` qui détecte les params Shopify (`hmac`, `shop`) et redirige vers OAuth authorize (sans `scope` param pour rester en mode managed).

### 4. Fastify content-type parser conflict
**Cause** : `addContentTypeParser('application/json')` entrait en conflit avec le parser par défaut.
**Fix** : Remplacement par `app.addHook('preParsing', ...)` pour capturer le rawBody pour la vérification HMAC.

## Architecture token rotation

```
OAuth callback → exchangeToken(code, expiring=1)
  → { access_token, scope, expires_in: 3599, refresh_token }
  → saveConnection(token, refresh_token, expires_at)

API call → getActiveConnection(tenantId)
  → if token_expires_at - now < 5min:
      rotateToken(refresh_token) via grant_type=refresh_token
      → { new access_token, expires_in, new refresh_token }
      → updateConnectionToken(...)
```

## Tables DB modifiées

```sql
ALTER TABLE shopify_connections ADD COLUMN token_expires_at TIMESTAMPTZ;
ALTER TABLE shopify_connections ADD COLUMN refresh_token_enc TEXT;
```

## Fichiers modifiés (sur le bastion)

| Fichier | Changements |
|---------|-------------|
| `src/app.ts` | Handler `GET /` pour managed install redirect |
| `src/modules/marketplaces/shopify/shopifyAuth.service.ts` | `expiring:1`, `rotateToken` via refresh_token, `saveConnection` avec refresh_token |
| `src/modules/marketplaces/shopify/shopifyOrders.service.ts` | `getActiveConnection` auto-rotate, lecture refresh_token_enc |
| `src/modules/marketplaces/shopify/shopify.routes.ts` | Passage refresh_token à saveConnection, managed install Redis mapping |
| `src/modules/marketplaces/shopify/shopifyWebhook.routes.ts` | preParsing hook pour rawBody HMAC, handlers compliance |

## Configuration Shopify (shopify.app.toml)

```toml
name = "KeyBuzz DEV"
client_id = "77b26855f61e20eb9b76b18fc9febfad"
application_url = "https://api-dev.keybuzz.io"
embedded = false

[access_scopes]
scopes = "read_orders,read_customers,read_fulfillments,read_returns"
use_legacy_install_flow = false

[auth]
redirect_urls = ["https://api-dev.keybuzz.io/shopify/callback"]

[webhooks]
api_version = "2024-10"
# orders/create, orders/updated, app/uninstalled (event subscriptions)
# customers/data_request, customers/redact, shop/redact (compliance)
```

## Validation E2E (9 avril 2026)

| Test | Résultat |
|------|----------|
| Connexion Shopify (managed install) | OK |
| Token expirant (expires_in=3599s) | OK |
| refresh_token stocké (chiffré AES-256-GCM) | OK |
| Scopes accordés (4/4) | OK |
| GraphQL orders sync (HTTP 200) | OK |
| Webhooks orders/create + orders/updated | OK |
| Webhook app/uninstalled | OK |
| Compliance webhooks (via TOML) | OK |
| HMAC verification + rejet invalide | OK |
| Non-régression Amazon (11 937 orders) | OK |
| Non-régression conversations (430) | OK |
| API health | OK |

## Versions

| Service | Image DEV |
|---------|-----------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-dev` |
| Rollback | `ghcr.io/keybuzzio/keybuzz-api:v3.5.228-ph-shopify-021-scopes-dev` |

## Note : boutique test vide

La boutique `keybuzz-dev.myshopify.com` n'a pas de commandes test.
Le sync retourne 0 orders, ce qui est le comportement attendu.
Pour tester avec des données réelles, créer des commandes test dans le Shopify admin.
