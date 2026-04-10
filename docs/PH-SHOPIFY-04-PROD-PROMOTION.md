# PH-SHOPIFY-04-PROD-PROMOTION — Promotion PROD IA Shopify + Policy Engine

**Date** : 10 avril 2026
**Phase** : PH-SHOPIFY-04-PROD-PROMOTION
**Environnement** : PROD
**Statut** : VALIDÉ

---

## 1. Source DEV promue

| Composant | Image DEV validée |
|---|---|
| API | `v3.5.238-ph-shopify-04-ai-dev` |
| Client | `v3.5.228-ph-shopify-04-dev` (déjà aligné PROD via PH-SHOPIFY-PROD-CLIENT-ALIGN-01) |

### Fichiers API modifiés (PH-SHOPIFY-04)
1. `src/services/marketplaceIntelligenceEngine.ts` — profil SHOPIFY_STANDARD
2. `src/modules/ai/shared-ai-context.ts` — enrichissement Shopify (payment/fulfillment/refund/tracking)
3. `src/modules/ai/ai-assist-routes.ts` — marketplace dynamique, plus de hardcode Amazon
4. `src/modules/marketplaces/shopify/shopifyOrders.service.ts` — `tracking_source = 'shopify'`
5. `src/modules/orders/routes.ts` — `shopifyPaymentStatus` / `shopifyFulfillmentStatus` dans l'API

---

## 2. Image PROD

| Service | Avant | Après |
|---|---|---|
| API PROD | `v3.5.237-ph-shopify-expiring-prod` | `v3.5.238-ph-shopify-04-ai-prod` |
| Client PROD | `v3.5.238-ph-shopify-client-prod` | Inchangé |

**Digest API PROD** : `sha256:1e13a2865aef7f1c9518f8daef517d4d28a033b55048a02993955cfec69e0953`

---

## 3. Diff manifest

```yaml
# k8s/keybuzz-api-prod/deployment.yaml
- image: ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod
+ image: ghcr.io/keybuzzio/keybuzz-api:v3.5.238-ph-shopify-04-ai-prod
```

Variables Shopify PROD déjà configurées (aucun changement) :
- `SHOPIFY_REDIRECT_URI`, `SHOPIFY_CLIENT_REDIRECT_URL`
- `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_ENCRYPTION_KEY` (via K8s secret `keybuzz-shopify`)
- `SHOPIFY_WEBHOOK_URL`

---

## 4. Validations Shopify PROD

### Marketplace Intelligence Engine
| Test | Résultat |
|---|---|
| Marketplace detection `shopify` | **SHOPIFY** |
| Policy profile | **SHOPIFY_STANDARD** |
| Escalation risk | **LOW** |
| Response guideline | **INVESTIGATE_FIRST** |
| Intelligence block | **1084 chars** — 10 guidelines injectées |
| Allowed actions | acknowledge, investigate, tracking, replacement, verify, evidence, escalate |
| Restricted actions | auto_refund, immediate_replacement, close_without_investigation |

### AI Context Enrichment
| Test | Résultat |
|---|---|
| `extractShopifyOrderContext()` | Fonctionnel |
| `paymentStatus` (paid → PAID) | **OK** |
| `fulfillmentStatus` (unfulfilled → UNFULFILLED) | **OK** |
| `itemCount` (2 items → 2) | **OK** |
| `hasTracking` (no fulfillments → false) | **OK** |
| `refundIndicator` (no refunds → none) | **OK** |

### Marketplace Detection (plus de hardcode Amazon)
| Channel | Detected As |
|---|---|
| `shopify` | **SHOPIFY** |
| `amazon` | **AMAZON** |
| `octopia` | **OCTOPIA** |
| `email` | UNKNOWN |
| `unknown` | UNKNOWN |

### Données PROD
- Shopify connections : 0 (aucune boutique connectée encore)
- Shopify orders : 0

---

## 5. Non-régression PROD

| Vérification | Avant | Après | Statut |
|---|---|---|---|
| API Health | `{"status":"ok"}` | `{"status":"ok"}` | **OK** |
| Amazon orders | 11 835 | 11 835 | **OK** |
| Conversations | 449 | 449 | **OK** |
| AI Wallet ecomlg-001 | 899.03 / 1000 | 899.03 / 1000 | **OK** |
| Playbooks actifs | 48 (6 tenants) | 48 (6 tenants) | **OK** |
| Billing subscriptions | 3 | 3 | **OK** |
| Amazon tracking_source | amazon_estimate: 11783, amazon_report: 50, aggregator: 2 | Inchangé | **OK** |
| Amazon marketplace intelligence | AMAZON / AMAZON_BUYER_PROTECTION | Inchangé | **OK** |
| Startup logs | Propres | Propres (uniquement Octopia sync info) | **OK** |

---

## 6. Rollback

```bash
# API PROD rollback
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.237-ph-shopify-expiring-prod \
  -n keybuzz-api-prod
```

Ou via GitOps : restaurer `v3.5.237-ph-shopify-expiring-prod` dans `k8s/keybuzz-api-prod/deployment.yaml`.

---

## 7. État final DEV / PROD

| Service | DEV | PROD | Aligné |
|---|---|---|---|
| API | `v3.5.238-ph-shopify-04-ai-dev` | `v3.5.238-ph-shopify-04-ai-prod` | **OUI** |
| Client | `v3.5.228-ph-shopify-04-dev` | `v3.5.238-ph-shopify-client-prod` | **OUI** (même code) |
| Backend | `v1.0.38-vault-tls-dev` | `v1.0.38-vault-tls-prod` | **OUI** |

---

## Verdict

**SHOPIFY AI PROD PROMOTED — POLICY ACTIVE — DEV/PROD ALIGNED — ZERO REGRESSION**
