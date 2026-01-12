# PH15-TRACKING-PROVENANCE-AUDIT-01 â€” Audit provenance tracking

**Date** : 2026-01-12
**Auteur** : Assistant IA
**Statut** : âœ… TERMINÃ‰

---

## Objectif

Identifier la SOURCE exacte des donnÃ©es de tracking affichÃ©es dans KeyBuzz et corriger si nÃ©cessaire.

---

## RÃ©sumÃ© exÃ©cutif

| Question | RÃ©ponse |
|----------|---------|
| **Source tracking avant audit** | âŒ DonnÃ©es de test manuelles (fausses) |
| **SP-API fournit carrier ?** | âœ… Oui via `AutomatedShippingSettings.AutomatedCarrierName` |
| **SP-API fournit trackingNumber ?** | âŒ Non via l'API Orders |
| **Correctif appliquÃ©** | âœ… Extraction du vrai carrier + suppression des faux |

---

## 1. Ã‰tat initial (avant audit)

### Preuve DB

```sql
SELECT COUNT(*) as total,
       SUM(CASE WHEN carrier IS NOT NULL THEN 1 ELSE 0 END) as with_tracking
FROM "Order" WHERE "tenantId" = 'ecomlg-001';
```

| total | with_tracking |
|-------|---------------|
| 100 | 3 |

**Les 3 commandes avec tracking Ã©taient des donnÃ©es de test insÃ©rÃ©es manuellement :**
- `407-8949262-6149120` : Chronopost / XY987654321FR (FAUX)
- `407-1325008-2788316` : AMZN_FR / TBA123456789000 (FAUX)
- `407-2379794-2051544` : Colissimo / 8R123456789FR (FAUX)

---

## 2. Analyse du code

### Mapping initial (amazonOrders.service.ts)

```typescript
// PROBLÃˆME: Le backfill n'extrayait JAMAIS carrier/trackingCode
await prisma.order.upsert({
  create: {
    // ...
    // carrier: absent !
    // trackingCode: absent !
  }
});
```

### Interface AmazonOrder

```typescript
interface AmazonOrder {
  AmazonOrderId: string;
  OrderStatus: string;
  // AutomatedShippingSettings: absent de l'interface !
}
```

---

## 3. RÃ©ponse brute SP-API

### Endpoint de debug crÃ©Ã©

`GET /api/v1/orders/debug/spapi-raw`

### RÃ©sultat (masquÃ© PII)

```json
{
  "orderCount": 5,
  "allFieldsInOrder": [
    "AmazonOrderId",
    "AutomatedShippingSettings",
    "BuyerInfo",
    "FulfillmentChannel",
    "NumberOfItemsShipped",
    "OrderStatus",
    "ShipServiceLevel",
    ...
  ],
  "shipmentRelatedFields": [
    "AutomatedShippingSettings",
    "NumberOfItemsShipped",
    "FulfillmentChannel",
    "ShipServiceLevel"
  ]
}
```

### Champ `AutomatedShippingSettings` (DÃ‰COUVERTE)

```json
{
  "AutomatedCarrier": "UPS FR",
  "HasAutomatedShippingSettings": true,
  "AutomatedShipMethod": "UPS Standard Single",
  "AutomatedShipMethodName": "UPS Standard Single",
  "AutomatedCarrierName": "UPS FR"
}
```

### Conclusion API

| DonnÃ©e | Disponible | Champ source |
|--------|------------|--------------|
| **Carrier** | âœ… | `AutomatedShippingSettings.AutomatedCarrierName` |
| **TrackingNumber** | âŒ | Non fourni par l'API Orders |

**Le TrackingNumber nÃ©cessiterait l'API Shipping ou les Reports.**

---

## 4. Correctif appliquÃ©

### 4.1 Suppression des fausses donnÃ©es

```sql
UPDATE "Order" SET carrier=NULL, "trackingCode"=NULL 
WHERE "tenantId"='ecomlg-001' AND carrier IS NOT NULL;
-- 3 lignes supprimÃ©es
```

### 4.2 Mise Ã  jour du code

**Interface AmazonOrder** :
```typescript
interface AmazonOrder {
  // ...existing...
  AutomatedShippingSettings?: {
    AutomatedCarrier?: string;
    AutomatedCarrierName?: string;
    HasAutomatedShippingSettings?: boolean;
  };
}
```

**Fonction extractCarrier** :
```typescript
function extractCarrier(order: AmazonOrder): string | null {
  if (order.AutomatedShippingSettings?.AutomatedCarrierName) {
    return order.AutomatedShippingSettings.AutomatedCarrierName;
  }
  return order.AutomatedShippingSettings?.AutomatedCarrier || null;
}
```

**Backfill & Sync** :
```typescript
await prisma.order.upsert({
  create: {
    carrier: extractCarrier(amzOrder), // â† VRAI carrier
    trackingCode: null, // Non disponible via Orders API
  },
  update: {
    carrier: extractCarrier(amzOrder),
  }
});
```

### 4.3 Backfill exÃ©cutÃ©

```bash
curl -X POST /api/v1/orders/backfill -d '{"days":120}'
```

**RÃ©sultat** : 98 commandes importÃ©es

---

## 5. Ã‰tat final (aprÃ¨s audit)

### Preuve DB

```sql
SELECT COALESCE(carrier, '(no carrier)') as carrier, COUNT(*) 
FROM "Order" WHERE "tenantId" = 'ecomlg-001' 
GROUP BY carrier;
```

| carrier | count |
|---------|-------|
| UPS FR | 82 |
| (no carrier) | 116 |

**82 commandes ont maintenant le VRAI carrier "UPS FR" depuis Amazon SP-API !**

### Sample commandes avec carrier rÃ©el

| OrderId | Carrier | TrackingCode | Status |
|---------|---------|--------------|--------|
| 402-7417438-1143555 | UPS FR | (null) | SHIPPED |
| 171-8770054-0316330 | UPS FR | (null) | SHIPPED |
| 403-6456142-4135521 | UPS FR | (null) | CANCELLED |

---

## 6. DÃ©cision : CAS B

**Le TrackingNumber n'est PAS fourni par l'API Orders d'Amazon.**

Pour obtenir le numÃ©ro de suivi, il faudrait :
1. **API Shipping** : `getShipment` (nÃ©cessite shipmentId)
2. **Reports API** : `GET_MERCHANT_FULFILLED_SHIPMENTS_DATA`
3. **Webhooks** : Si le vendeur uploade le tracking via confirmShipment

### Affichage UI actuel

| DonnÃ©e | Affichage |
|--------|-----------|
| Carrier prÃ©sent, tracking absent | "UPS FR" (sans lien) |
| Carrier absent | "(pas de suivi)" |

---

## 7. Commits

| Repo | Commit | Message |
|------|--------|---------|
| keybuzz-backend | `575e457` | fix(tracking): PH15 audit - extract REAL carrier from AutomatedShippingSettings |
| keybuzz-infra | `336f623` | feat(k8s): PH15 backend 1.0.18 with real carrier |

---

## 8. TODO Future

- [ ] ImplÃ©menter l'API Shipping pour rÃ©cupÃ©rer le trackingNumber
- [ ] Ou utiliser Reports API pour le bulk tracking
- [ ] Afficher "Suivi disponible sur Amazon" avec lien vers la page commande
