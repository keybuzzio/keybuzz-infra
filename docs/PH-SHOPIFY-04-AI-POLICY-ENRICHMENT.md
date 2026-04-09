# PH-SHOPIFY-04 — IA Shopify enrichie + Policy Engine Shopify

**Date** : 9 avril 2026
**Phase** : PH-SHOPIFY-04
**Environnement** : DEV uniquement
**Statut** : VALIDÉ

---

## 1. État initial

| Élément | Avant |
|---|---|
| API DEV | `v3.5.237-ph-shopify-expiring-dev` |
| Client DEV | `v3.5.227-ph-shopify-021-dev` |
| Shopify DEV | 1 connexion active (`keybuzz-mnqnjna8` / `keybuzz-dev.myshopify.com`) |
| Commandes Shopify | 2 ordres (#1001, #1002) |
| `tracking_source` Shopify | `amazon_estimate` (incorrect) |
| Marketplace Intelligence | AMAZON, OCTOPIA, FNAC, MIRAKL, UNKNOWN — **pas de SHOPIFY** |
| Contexte IA Shopify | **Aucun** — pas d'enrichissement raw_data |
| Policy Shopify | **Aucune** — tombait sur UNKNOWN/GENERIC_ECOMMERCE |
| Hardcode marketplace | `marketplace: 'amazon'` hardcodé en 2 endroits dans ai-assist-routes.ts |
| OrderSidePanel Shopify | Pas de statut paiement/fulfillment spécifique |

---

## 2. Audit données Shopify disponibles

### Champs immédiatement exploitables (table `orders`)
- `external_order_id`, `channel`, `status`, `total_amount`, `currency`
- `customer_name`, `customer_email`, `customer_address`
- `order_date`, `delivery_status`, `fulfillment_channel`
- `carrier`, `tracking_code`, `tracking_url`
- `products` (JSONB)

### Champs Shopify dans `raw_data` non exploités avant PH-SHOPIFY-04
- `displayFinancialStatus` (PAID, PENDING, REFUNDED, PARTIALLY_REFUNDED, VOIDED)
- `displayFulfillmentStatus` (UNFULFILLED, IN_PROGRESS, FULFILLED, PARTIALLY_FULFILLED)
- `fulfillments[].trackingInfo` (number, url, company)
- `fulfillments[].status` (in_transit, delivered, success)

### Anomalies corrigées
- `tracking_source` était `amazon_estimate` pour les commandes Shopify → corrigé en `shopify`

---

## 3. Enrichissements de contexte IA ajoutés

### `shared-ai-context.ts`
- Nouvel interface `ShopifyOrderEnrichment` avec : `paymentStatus`, `fulfillmentStatus`, `refundIndicator`, `itemCount`, `hasTracking`, `isPartiallyRefunded`, `isFullyRefunded`
- Nouvelle fonction `extractShopifyOrderContext(rawData)` : extraction automatique depuis raw_data (GraphQL ou REST webhook)
- `loadEnrichedOrderContext` : enrichi avec `rawData` et `shopifyContext` quand `channel === 'shopify'`
- `buildEnrichedUserPrompt` : nouveau bloc `--- CONTEXTE SHOPIFY ---` injecté dans le prompt IA avec paiement, fulfillment, remboursement, articles, tracking
- `trackingSource` : détection automatique `shopify` au lieu de `amazon_estimate` pour les commandes Shopify

### `ai-assist-routes.ts`
- Import de `analyzeMarketplaceContext` et `buildMarketplaceIntelligenceBlock`
- Injection du bloc Marketplace Intelligence dans le system prompt (avant "Contexte:")
- Remplacement de `marketplace: 'amazon'` hardcodé → détection dynamique du canal (`sharedConvCtx?.channel || 'unknown'`) dans :
  - Human Approval Queue (PH81)
  - Follow-up Engine (PH82)

---

## 4. Policy Shopify ajoutée

### `marketplaceIntelligenceEngine.ts`
- Nouveau type `SHOPIFY` dans `MarketplaceName`
- Nouveau type `SHOPIFY_STANDARD` dans `PolicyProfile`
- Nouveau profil `SHOPIFY_PROFILE` :
  - **Risque d'escalation** : LOW (pas de A-to-Z comme Amazon)
  - **Guideline par défaut** : INVESTIGATE_FIRST
  - **Actions autorisées** : acknowledge, investigation, tracking, replacement, verify fulfillment/payment, evidence request, escalation
  - **Actions restreintes** : remboursement sans investigation, promesse de remboursement sans vérification, contournement process retour, divulgation coûts internes
  - **10 guidelines Shopify** spécifiques couvrant : contrôle marchand, vérification paiement/fulfillment, capture vs remboursement, preuves dommages, priorité échange sur remboursement, pas de SLA marketplace imposé

### Détection automatique
- `channel.includes('shopify')` → `SHOPIFY_PROFILE` dans `resolveMarketplace()`

### Validation
```
Marketplace: SHOPIFY
Policy: SHOPIFY_STANDARD
Risk: LOW
Guideline: INVESTIGATE_FIRST
Guidelines count: 10
```

---

## 5. Enrichissements Side Panel / Inbox

### `OrderSidePanel.tsx` (client)
- Interface `OrderSummary` enrichie avec `shopifyPaymentStatus?` et `shopifyFulfillmentStatus?`
- Nouveau bloc "Statut Shopify" affiché quand `channel === 'shopify'` :
  - **Paiement** : badge coloré (Payé/En attente/Remboursé/Partiellement remboursé/Annulé)
  - **Fulfillment** : badge coloré (Expédié/En cours/Non expédié/Partiellement expédié)
- Style cohérent avec l'existant (bg-*, text-*, rounded-full badges)

### `orders/routes.ts` (API)
- `orderRowToApiResponse` enrichi : extraction `shopifyPaymentStatus` et `shopifyFulfillmentStatus` depuis `raw_data` pour les commandes Shopify
- Pas d'impact sur les commandes Amazon/Octopia

### `shopifyOrders.service.ts`
- `tracking_source = 'shopify'` ajouté dans INSERT et UPDATE
- Les commandes existantes corrigées lors du resync

---

## 6. Impact Playbooks Shopify

### Ce qui marche déjà sans code
- Le moteur playbooks (`playbook-engine.service.ts`) supporte `channel` comme condition
- Les triggers textuels (tracking_request, delivery_delay, return_request, defective_product, etc.) fonctionnent par analyse du message, sans filtre canal
- Les 8 playbooks starter d'ecomlg-001 et les 9 de keybuzz-mnqnjna8 sont seedés avec `channel: null` → compatibles tous canaux
- **Shopify est 100% compatible sans modification**

### Ce qui est reporté
- Playbooks spécifiques Shopify (ex: vérification paiement Shopify) → à créer manuellement par le tenant si besoin
- Auto-seed de playbooks Shopify dédiés → reporté à une phase ultérieure

---

## 7. Validations réelles DEV

| Test | Résultat |
|---|---|
| Health `/health` | OK |
| Commandes Shopify visibles dans Orders | 2 commandes, channel=shopify |
| Resync Shopify (tracking_source fix) | 2 updated, 0 errors |
| tracking_source corrigé | #1001 → shopify, #1002 → shopify |
| API order detail Shopify fields | shopifyPaymentStatus=PAID, shopifyFulfillmentStatus=IN_PROGRESS |
| Marketplace Intelligence Shopify | SHOPIFY / SHOPIFY_STANDARD / LOW / INVESTIGATE_FIRST |
| Marketplace Intelligence Amazon | AMAZON / AMAZON_BUYER_PROTECTION / HIGH (inchangé) |
| extractShopifyOrderContext | paymentStatus=PAID, fulfillmentStatus=IN_PROGRESS, refund=none |
| Amazon orders inchangés | 11 937 commandes, tracking_source=amazon_estimate |
| Conversations | 431 (inchangé) |
| AI Wallet ecomlg-001 | 931.3 KBA remaining, plan=pro (inchangé) |
| Playbooks ecomlg-001 | 8 actifs (inchangé) |
| Playbooks keybuzz-mnqnjna8 | 9 actifs (inchangé) |
| Multi-tenant isolation | Strict (Shopify sur keybuzz-mnqnjna8 uniquement, Amazon sur ecomlg-001 uniquement) |

---

## 8. Non-régression

| Vérification | Résultat |
|---|---|
| `/health` | OK |
| Amazon orders (11 937) | Inchangés |
| Amazon tracking_source | `amazon_estimate` préservé |
| Amazon marketplace intelligence | AMAZON / BUYER_PROTECTION / HIGH |
| Conversations (431) | Inchangées |
| AI Wallet ecomlg-001 | Inchangé (931.3 KBA) |
| Playbooks actifs | Inchangés |
| Multi-tenant isolation | Stricte |
| Billing | Non impacté |

---

## 9. Rollback

### API DEV
```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-dev -n keybuzz-api-dev
```

### Client DEV
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.227-ph-shopify-021-dev -n keybuzz-client-dev
```

### Revert policy Shopify
Le profil SHOPIFY dans `marketplaceIntelligenceEngine.ts` est additif. Le supprimer ferait retomber Shopify sur UNKNOWN/GENERIC_ECOMMERCE (comportement pré-PH-SHOPIFY-04).

---

## 10. Images déployées

| Service | Image | Tag |
|---|---|---|
| API DEV | `ghcr.io/keybuzzio/keybuzz-api` | `v3.5.238-ph-shopify-04-ai-dev` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client` | `v3.5.228-ph-shopify-04-dev` |

---

## 11. Fichiers modifiés

### API (keybuzz-api)
| Fichier | Modification |
|---|---|
| `src/services/marketplaceIntelligenceEngine.ts` | Ajout profil SHOPIFY (type, profile, detection) |
| `src/modules/ai/shared-ai-context.ts` | ShopifyOrderEnrichment, extractShopifyOrderContext, enrichissement prompt |
| `src/modules/ai/ai-assist-routes.ts` | Import marketplace intelligence, injection prompt, fix marketplace dynamique |
| `src/modules/marketplaces/shopify/shopifyOrders.service.ts` | Fix tracking_source='shopify' |
| `src/modules/orders/routes.ts` | Ajout shopifyPaymentStatus/shopifyFulfillmentStatus dans API response |

### Client (keybuzz-client)
| Fichier | Modification |
|---|---|
| `src/features/inbox/components/OrderSidePanel.tsx` | Interface enrichie + bloc Statut Shopify |

### Infrastructure (keybuzz-infra)
| Fichier | Modification |
|---|---|
| `k8s/keybuzz-api-dev/deployment.yaml` | Image → v3.5.238-ph-shopify-04-ai-dev |
| `k8s/keybuzz-client-dev/deployment.yaml` | Image → v3.5.228-ph-shopify-04-dev |

---

## Verdict

**SHOPIFY AI CONTEXT ENRICHED — POLICY ACTIVE — DEV READY FOR PROD PROMOTION**
