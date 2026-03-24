# PH-AMZ-PROD-SYNC-BUTTON-TRUTH-05 — Rapport

**Date** : 23 mars 2026
**Phase** : PH-AMZ-PROD-SYNC-BUTTON-TRUTH-05
**Type** : fix cible — bouton "Synchroniser Amazon Seller" absent en PROD
**Verdict** : **AMZ SYNC BUTTON PROD REALLY FIXED AND VALIDATED**

---

## Probleme

Le bouton "Synchroniser Amazon Seller" etait absent en PROD sur la page Commandes & SAV, alors que :
- Le connecteur Amazon etait bien present et actif
- Les commandes Amazon etaient visibles
- Le bouton "Exporter CSV" apparaissait normalement
- En DEV, le bouton Synchroniser apparaissait correctement

## Root cause exacte

La route BFF `app/api/amazon/status/route.ts` utilisait la variable d'environnement `AMAZON_BACKEND_URL` en priorite sur `BACKEND_URL` :

```typescript
// ANCIEN CODE (FAUTIF)
const BACKEND_URL = process.env.AMAZON_BACKEND_URL || process.env.BACKEND_URL || '';
```

| Variable | Valeur PROD | Service pointe |
|---|---|---|
| `AMAZON_BACKEND_URL` | `http://keybuzz-backend.keybuzz-backend-prod.svc:4000` | Python backend |
| `BACKEND_URL` | `http://keybuzz-api.keybuzz-api-prod.svc:80` | Fastify API |

Consequence :
- Le BFF appelait le **Python backend** (`keybuzz-backend:4000`) au lieu du **Fastify API** (`keybuzz-api:80`)
- Le Python backend en PROD a une table `MarketplaceConnection` **vide** → retournait `{"connected": false}`
- Le Fastify API a la route compat avec fallback `inbound_connections` → retourne `{"connected": true}`

### Pourquoi DEV fonctionnait

En DEV, le Python backend (`keybuzz-backend-dev:4000`) contient des donnees de connexion Amazon → retournait `connected: true`. Le bug etait masque.

### Chaine de causalite complete

```
Page Commandes → useEffect detectMarketplaces
  → fetch /api/amazon/status?tenant_id=ecomlg (BFF)
    → BFF lit AMAZON_BACKEND_URL (prioritaire)
    → appelle http://keybuzz-backend.keybuzz-backend-prod.svc:4000/api/v1/marketplaces/amazon/status
    → Python backend: MarketplaceConnection vide → connected: false
  → connectedMarketplaces = [{connected: false}]
  → activeMarketplaces.length === 0
  → UI affiche "Aucune marketplace connectee" au lieu du bouton
```

## Correction

Modification de `app/api/amazon/status/route.ts` sur le bastion :

```typescript
// NOUVEAU CODE (CORRIGE)
const BACKEND_URL = process.env.BACKEND_URL || '';
```

Le BFF appelle desormais toujours le Fastify API qui a la route compat avec :
1. Query `inbound_connections` pour le tenant ID exact
2. Fallback LIKE `tenantId-%` si le display ID est passe

## Fichiers modifies

| Fichier | Modification |
|---|---|
| `keybuzz-client/app/api/amazon/status/route.ts` (bastion) | Suppression `AMAZON_BACKEND_URL` de la resolution |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | Image → `v3.5.76-amz-sync-button-truth-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | Image → `v3.5.76-amz-sync-button-truth-prod` |

## Validation DEV

| Test | Resultat |
|---|---|
| BFF → Fastify API | `connected: true` ✓ |
| `AMAZON_BACKEND_URL` dans BFF compile | 0 occurrences ✓ |
| Image deployee | `v3.5.76-amz-sync-button-truth-dev` ✓ |

**AMZ SYNC BUTTON DEV REAL = OK**

## Validation PROD

| Test | Resultat |
|---|---|
| `AMAZON_BACKEND_URL` dans BFF compile | **0** (elimine) ✓ |
| BFF → Fastify API (display ID `ecomlg`) | `connected: true, status: CONNECTED` ✓ |
| BFF → Fastify API (canonical ID `ecomlg-001`) | `connected: true, status: CONNECTED` ✓ |
| Ancien Python backend (comparaison) | `Unauthorized` (confirme = mauvais endpoint) |
| API Health | `ok` ✓ |
| Orders list | 3 orders (total 5732) ✓ |
| Tracking commande cible 406-7738696-7078755 | `889685676345 FedEx hasTracking: true` ✓ |
| Sync status | `completed` ✓ |
| Image deployee | `v3.5.76-amz-sync-button-truth-prod` ✓ |

**AMZ SYNC BUTTON PROD REAL = OK**

## Non-regressions

| Element | Resultat |
|---|---|
| API Health | `ok` ✓ |
| Tracking dans Messages | Inchange ✓ |
| Tracking dans liste Commandes | Inchange ✓ |
| Export CSV | Inchange ✓ |
| Orders list | 5732 commandes ✓ |
| Autres BFF Amazon (OAuth, inbound-address) | Non touches ✓ |

## Images deployees

| Service | DEV | PROD |
|---|---|---|
| Client | `v3.5.76-amz-sync-button-truth-dev` | `v3.5.76-amz-sync-button-truth-prod` |
| API | `v3.5.49-amz-orders-list-sync-fix-dev` | `v3.5.49-amz-orders-list-sync-fix-prod` |

## Rollback

| Env | Image rollback |
|---|---|
| Client DEV | `v3.5.75-amz-orders-list-sync-fix-dev` |
| Client PROD | `v3.5.75-amz-orders-list-sync-fix-prod` |

Rollback via manifests GitOps uniquement.

## Verdict

**AMZ SYNC BUTTON PROD REALLY FIXED AND VALIDATED**
