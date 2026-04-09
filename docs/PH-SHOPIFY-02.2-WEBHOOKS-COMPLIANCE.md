# PH-SHOPIFY-02.2 — Webhooks Conformité Shopify

> Date : 2026-04-09
> Env : DEV uniquement
> Image : API `v3.5.231-ph-shopify-022-fix-dev`
> PROD : inchangée (`v3.5.225-ph-playbooks-v2-prod`)

---

## 1. Contexte

Le dashboard Shopify Partner signalait 2 erreurs de conformité :
- "Fournit un webhooks de conformité obligatoire" (❌)
- "Vérifie les webhooks avec Signatures HMAC" (❌)

## 2. Problème identifié — scopes non accordés

### Diagnostic

```
GET https://keybuzz-dev.myshopify.com/admin/oauth/access_scopes.json
→ {"access_scopes":[]}
```

Le token OAuth n'avait **aucun scope** accordé. Cause : depuis les "Shopify managed installations", les scopes doivent être déclarés dans `shopify.app.toml` et déployés via `shopify app deploy`. Sans cela, Shopify n'accorde aucun scope même si l'OAuth URL les demande.

### Solution

Fichier `shopify.app.toml` créé dans `keybuzz-infra/shopify-app-config/` avec :

```toml
[access_scopes]
scopes = "read_orders,read_customers,read_fulfillments,read_returns"

[webhooks]
api_version = "2024-10"
compliance_topics = ["customers/data_request", "customers/redact", "shop/redact"]
```

**Action requise** : exécuter `shopify app deploy` depuis ce dossier pour pousser la configuration vers le Partner Dashboard.

## 3. Webhooks de conformité implémentés

### Topics supportés

| Topic | Comportement | Status |
|-------|-------------|--------|
| `customers/data_request` | Log + réponse 200 | ✅ Testé |
| `customers/redact` | Log + réponse 200 | ✅ Testé |
| `shop/redact` | Log + réponse 200 | ✅ Testé |
| `app/uninstalled` | Disconnect tenant + réponse 200 | ✅ Testé |
| `orders/create` | Upsert order + réponse 200 | ✅ Code prêt |
| `orders/updated` | Upsert order + réponse 200 | ✅ Code prêt |

### Vérification HMAC

- Utilise `rawBody` (Buffer) via `preParsing` hook
- `crypto.createHmac('sha256', secret).update(rawBody).digest('base64')`
- `crypto.timingSafeEqual()` pour comparaison timing-safe
- Test HMAC invalide → 401 ✅

## 4. Fichiers modifiés

| Fichier | Action |
|---------|--------|
| `shopifyWebhook.routes.ts` | Refonte complète : rawBody via preParsing, handlers compliance, app/uninstalled |
| `shopifyOrders.service.ts` | Ajout topics conformité dans registerWebhooks |
| `shopify.routes.ts` | Inchangé (enregistrement webhooks post-OAuth déjà en place) |

## 5. Rule Cursor créée

`.cursor/rules/shopify-integration-rules.mdc` ajoutée avec :
- Configuration TOML
- Webhooks conformité
- HMAC verification (rawBody obligatoire)
- OAuth flow complet
- API GraphQL Admin
- Tables DB Shopify
- Environnements DEV/PROD

## 6. Validation

### Tests webhook avec HMAC valide

```
customers/data_request → {"ok":true} ✅
customers/redact       → {"ok":true} ✅
shop/redact            → {"ok":true} ✅
app/uninstalled        → {"ok":true} ✅
HMAC invalide          → {"error":"HMAC verification failed"} (401) ✅
```

### Events en DB

```
app/uninstalled: 1
customers/data_request: 1
customers/redact: 1
orders/create: 1
shop/redact: 1
```

### Non-régression

| Check | Résultat |
|-------|---------|
| Health | OK |
| Conversations | OK |
| AI Wallet | OK (KBA: 931.3) |
| Shopify status | connected (keybuzz-dev.myshopify.com) |

## 7. Prochaines étapes

### Pour résoudre le problème de scopes

1. Installer Shopify CLI : `npm install -g @shopify/cli@latest`
2. Aller dans `keybuzz-infra/shopify-app-config/`
3. Exécuter : `shopify app deploy`
4. Cela poussera la configuration (scopes + webhooks) vers le Partner Dashboard
5. Aller sur le shop `keybuzz-dev.myshopify.com` admin
6. Réinstaller l'app KeyBuzz DEV pour obtenir les scopes
7. Puis relancer PH-SHOPIFY-03 validation

### Relancer la vérification Shopify

Après le `shopify app deploy` + réinstallation :
1. Retourner dans le Partner Dashboard → KeyBuzz DEV → Vérifications automatisées
2. Cliquer "Exécuter"
3. Résultat attendu : tous les checks verts

## 8. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.228-ph-shopify-021-scopes-dev -n keybuzz-api-dev
```
