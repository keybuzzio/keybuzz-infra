# PH15-AMAZON-BACKFILL-ORDERS-01 - Backfill Amazon Orders

## Date: 2026-01-11

## Objectif
Purger les donnees de test Orders pour ecomlg-001 et effectuer un backfill Amazon 90 jours.

---

## Infrastructure creee

### 1. Tables PostgreSQL (keybuzz_backend)

\\\sql
-- Enums
OrderStatus: PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED, RETURNED
DeliveryStatus: PREPARING, SHIPPED, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED, DELAYED, LOST
SavStatus: NONE, OPEN, IN_PROGRESS, RESOLVED
SlaStatus: OK, AT_RISK, BREACHED

-- Table Order
id, tenantId, externalOrderId, orderRef, marketplace, customerName, customerEmail,
orderDate, currency, totalAmount, orderStatus, deliveryStatus, savStatus, slaStatus,
carrier, trackingCode, shippingAddress (JSON), createdAt, updatedAt, shippedAt, deliveredAt

-- Table OrderItem
id, orderId, sku, asin, title, quantity, unitPrice

-- Index unique: (tenantId, marketplace, externalOrderId)
\\\

### 2. Services backend (keybuzz-backend v1.0.9-dev)

- \mazonOrders.service.ts\: Service SP-API Orders
  - \etchAmazonOrders()\: Recupere les commandes via SP-API
  - \etchOrderItems()\: Recupere les items d'une commande
  - \ackfillAmazonOrders()\: Backfill complet avec upsert
  - \getOrdersForTenant()\: Liste les commandes pour l'UI

- \mazonOrders.routes.ts\: Routes API
  - \GET /api/v1/orders\: Liste les commandes
  - \POST /api/v1/orders/backfill\: Lance un backfill

### 3. Deployment

\\\
keybuzz-backend:1.0.9-dev deploye avec routes Orders
\\\

---

## Probleme rencontre

### Credentials Amazon non disponibles dans Vault

Le backfill a echoue avec l'erreur:
\\\
 Amazon OAuth not connected - no refresh token
\\\

**Analyse:**
- MarketplaceConnection existe pour ecomlg-001 avec status=CONNECTED
- Vault est accessible sur https://10.0.0.150:8200
- Les credentials Amazon (refresh_token) n'existent PAS dans Vault au path:
  \secret/data/keybuzz/tenants/ecomlg-001/amazon_spapi\

**Raison probable:**
L'OAuth Amazon n'a pas ete complete correctement, ou les credentials ont ete supprimees.

---

## Action requise: Reconnexion Amazon

L'utilisateur doit reconnecter Amazon via OAuth pour obtenir un nouveau refresh_token:

1. Appeler POST /api/v1/marketplaces/amazon/oauth/start avec X-Tenant-Id: ecomlg-001
2. Suivre l'authUrl retournee pour autoriser l'application KeyBuzz
3. Le callback stockera le refresh_token dans Vault
4. Relancer le backfill: POST /api/v1/orders/backfill { days: 90 }

**AuthUrl generee (valide 10min):**
\\\
https://sellercentral.amazon.com/apps/authorize/consent?application_id=amzn1.sp.solution.d1630702-2e5b-4cd2-95a0-cc6121dc797a&state=...&redirect_uri=https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/oauth/callback
\\\

---

## UI Orders

Le module Orders UI utilise actuellement des donnees MOCK statiques (\MOCK_ORDERS\).
Pour afficher les vraies commandes, le frontend devra etre modifie pour appeler:
\\\
GET /api/v1/orders
\\\

**Note:** Le prompt indiquait de ne pas modifier le module Orders UI, donc cette modification
est documentee mais non implementee.

---

## Git Commits

### keybuzz-backend
\\\
- Ajout modele Order/OrderItem dans schema.prisma
- Ajout amazonOrders.service.ts (SP-API Orders)
- Ajout amazonOrders.routes.ts (GET/POST /api/v1/orders)
- Bump version 1.0.8 -> 1.0.9
\\\

---

## Resume

| Element | Statut |
|---------|--------|
| Tables Order/OrderItem creees | OK |
| Service SP-API Orders | OK |
| Routes /api/v1/orders | OK |
| Backend v1.0.9-dev deploye | OK |
| Credentials Vault | MANQUANT |
| Backfill execute | ECHEC (credentials) |
| UI Orders modifiee | NON (per spec) |

---

## Prochaines etapes

1. Reconnecter Amazon OAuth pour tenant ecomlg-001
2. Verifier credentials dans Vault
3. Relancer backfill: POST /api/v1/orders/backfill
4. (Optionnel) Modifier UI Orders pour appeler l'API reelle
