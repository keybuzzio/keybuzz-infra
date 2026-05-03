# PH-SAAS-T8.12AK — SHOPIFY API SOURCE RESTORE DEV

> Date : 2026-05-03
> Verdict : **GO DEV — FULL RESTORE VALIDÉ**
> Phase précédente : PH-SAAS-T8.12AJ (audit → GO PARTIEL, API 404)

---

## Résumé exécutif

Le connecteur Shopify dont les routes API retournaient 404 (constaté lors de l'audit T8.12AJ) a été **entièrement restauré** côté API DEV. Les 5 fichiers source ont été reconstruits depuis les scripts historiques `keybuzz-infra/scripts/ph-shopify-0X/`, compilés, déployés, et validés.

---

## Matrice de validation

| Test | Attendu | Résultat |
|------|---------|----------|
| `GET /shopify/status` | 200 `{connected:false}` | **OK** |
| `POST /shopify/connect` | 200 + authUrl OAuth | **OK** |
| `GET /shopify/callback` | 302 (redirect) | **OK** |
| `POST /webhooks/shopify` (HMAC invalide) | 401 | **OK** |
| Fichiers dist Shopify | 6 fichiers | **OK** (6/6) |
| IA `direct_seller_controlled` | Présent | **OK** |
| `/messages/conversations` | 200 | **OK** |
| `/tenant-context/me` | 200 | **OK** |
| `/api/v1/orders` | 200 | **OK** |
| `/billing/current` | 200 | **OK** |
| Outbound 15min | 0 | **OK** |
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | **INCHANGÉ** |
| Client PROD | `v3.5.147-*-prod` | **INCHANGÉ** |

---

## Fichiers restaurés

| Fichier | Source | Description |
|---------|--------|-------------|
| `shopifyCrypto.service.ts` | `ph-shopify-02-api.py` | AES-256-GCM token encryption |
| `shopifyAuth.service.ts` | `ph-shopify-02-api.py` + `ph-shopify-021-fix-scopes.py` | OAuth, HMAC, state Redis, scopes read_returns |
| `shopifyOrders.service.ts` | `ph-shopify-03/shopifyOrders.service.ts` | GraphQL sync, webhook mapping, order upsert |
| `shopify.routes.ts` | `ph-shopify-02-api.py` + `ph-shopify-03/apply-all.py` | Routes /status, /connect, /callback, /disconnect, /orders/sync |
| `shopifyWebhook.routes.ts` | `ph-shopify-03/apply-all.py` | Route /webhooks/shopify (HMAC, events log) |
| `index.ts` | Nouveau | Barrel export |

### Registrations dans `app.ts`
```typescript
import { shopifyRoutes, shopifyWebhookRoutes } from './modules/marketplaces/shopify';
app.register(shopifyRoutes, { prefix: '/shopify' });
app.register(shopifyWebhookRoutes, { prefix: '/webhooks' });
```

---

## Cause racine du problème

Les fichiers source Shopify existaient dans les images `v3.5.237/238/239` mais ont été **perdus** lors des rebase/rebuild de la branche `ph147.4/source-of-truth`. Les scripts infra `ph-shopify-0X/` contenaient le code original qui n'a jamais été réintégré dans le repo API.

---

## Déploiement

| Item | Valeur |
|------|--------|
| Image DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.145-shopify-api-restore-dev` |
| Image PROD | **INCHANGÉE** (`v3.5.137-conversation-order-tracking-link-prod`) |
| Commit API | `7af350f0` (branche `ph147.4/source-of-truth`) |
| Commit Infra | Manifest DEV mis à jour |
| Digest | `dfca74e67aea` |

---

## Sécurité

- **HMAC** : Vérifié — requête avec HMAC invalide → 401
- **Token encryption** : AES-256-GCM via `SHOPIFY_ENCRYPTION_KEY` (K8s secret)
- **OAuth state** : Redis avec TTL 600s
- **Aucun OAuth réel déclenché** : Pas de boutique connectée
- **Aucun webhook réel configuré**
- **Aucune mutation PROD**

---

## Non-régression

| Service | Status |
|---------|--------|
| Health | OK |
| Conversations | OK (3 retournées) |
| Auth/me | OK |
| Orders | OK (3 retournées) |
| Billing | OK (200) |
| Outbound | 0 envoi parasite |
| PROD API | Inchangé |
| PROD Client | Inchangé |

---

## Actions suivantes recommandées

1. **Test E2E avec boutique Shopify DEV** — Connecter une vraie boutique de test pour valider OAuth complet
2. **Webhooks DEV** — Configurer un tunnel (ngrok) pour tester les webhooks en conditions réelles
3. **Promotion PROD** — Après validation E2E, promouvoir vers PROD
4. **Sync CronJob** — Créer un K8s CronJob pour la synchronisation périodique des commandes Shopify
