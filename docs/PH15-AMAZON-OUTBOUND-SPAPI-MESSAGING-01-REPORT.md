# PH15-AMAZON-OUTBOUND-SPAPI-MESSAGING-01 - Rapport

**Date** : 2026-01-09
**Objectif** : Reponses Amazon via SP-API Messaging
**Statut** : TERMINE (avec fallback SMTP)

## 1. Implementation

### Fichiers modifies

| Fichier | Description |
|---------|-------------|
| messages/routes.ts | determineProvider() retourne 'spapi' pour channel amazon |
| services/spapiMessaging.ts | Client SP-API Messaging (nouveau) |
| workers/outboundWorker.ts | Support SPAPI + fallback SMTP |

### Logique implementee

1. Pour channel = amazon, provider = spapi
2. Worker tente SP-API si orderId disponible
3. Si pas d'orderId ou SP-API echoue : fallback SMTP
4. Tracabilite complete dans delivery_trace

## 2. Flow Decision

`
delivery.provider == 'spapi'
    |
    v
orderId disponible ?
    |
    +-- OUI --> Essayer SP-API Messaging
    |              |
    |              +-- Succes --> delivered (SPAPI)
    |              |
    |              +-- Echec --> Fallback SMTP
    |
    +-- NON --> Fallback SMTP direct
                   |
                   +-- Succes --> delivered (SMTP_FALLBACK)
                   |
                   +-- Echec --> failed
`

## 3. SP-API Messaging

### Endpoint utilise
`
POST /messaging/v1/orders/{orderId}/messages/confirmCustomizationDetails
`

### Credentials
- App credentials : Vault secret/keybuzz/amazon_spapi/app
- Tenant credentials : Vault secret/keybuzz/tenants/{tenantId}/amazon_spapi

### Scopes requis
- messaging_orders (Messaging API)

## 4. Test E2E

### Test sans orderId (fallback SMTP)
`
delivery_id: dlv-1767929695824-n8x4rabuh
channel: amazon
provider initial: spapi
provider final: SMTP_FALLBACK
status: delivered
note: No orderId - SMTP fallback used
emailMessageId: <75188208-bbb6-f1f3-ed05-bdaa5b4cb9de@keybuzz.io>
`

## 5. Limitation connue

Pour que SP-API Messaging fonctionne, il faut :
- orderId dans conversation.order_ref ou thread_key
- Scopes Messaging autorises sur l'app Amazon

Sans orderId, le fallback SMTP est utilise automatiquement.

## 6. Versions deployees

| Service | Version |
|---------|---------|
| keybuzz-api | 0.1.77 |
| outbound-worker | 0.1.77 (3.0.1-spapi-fallback) |

## 7. Conclusion

- SP-API Messaging implemente
- Fallback SMTP operationnel
- Tracabilite complete
- Pas de regression sur l'inbound
