# PH15-AMAZON-COMMISSION-RATES-API

## Endpoint

```
POST https://backend-dev.keybuzz.io/api/internal/amazon/commission-rates
```

## Authentication

Bearer token via `Authorization` header:

```
Authorization: Bearer <KEYBUZZ_INTERNAL_TOKEN>
```

**Token**: Stored in environment variable `KEYBUZZ_INTERNAL_TOKEN` on the backend.

## Request

### Headers

| Header | Value | Required |
|--------|-------|----------|
| Authorization | Bearer \<token\> | Yes |
| Content-Type | application/json | Yes |

### Body

```json
{
  "items": [
    {
      "sku": "PRODUCT-SKU-001",
      "ean": "3760000000001",
      "country": "FR",
      "price": 29.99
    },
    {
      "sku": "PRODUCT-SKU-002",
      "asin": "B08EXAMPLE",
      "country": "DE",
      "price": 49.99
    }
  ],
  "tenant_id": "ecomlg-001"
}
```

### Parameters

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| items | array | Yes | Array of items (max 100) |
| items[].sku | string | Yes | Product SKU |
| items[].ean | string | No | EAN barcode |
| items[].asin | string | No | Amazon ASIN (prioritized for SP-API) |
| items[].country | string | Yes | Country code (FR, DE, IT, ES, UK, etc.) |
| items[].price | number | No | Price for fee estimation (default: 19.99) |
| tenant_id | string | No | Tenant ID (default: ecomlg-001) |

## Response

### Success (200)

```json
{
  "items": [
    {
      "sku": "PRODUCT-SKU-001",
      "ean": "3760000000001",
      "country": "FR",
      "rate": 0.15,
      "source": "spapi",
      "updated_at": "2026-01-12T18:53:08.830Z"
    },
    {
      "sku": "PRODUCT-SKU-002",
      "country": "DE",
      "rate": 0.15,
      "source": "fallback",
      "category": "DEFAULT",
      "updated_at": "2026-01-12T18:53:08.960Z",
      "error": "SPAPI_ERROR_403"
    }
  ],
  "errors": [
    {
      "sku": "INVALID-SKU",
      "country": "XX",
      "rate": null,
      "source": "error",
      "error": "UNKNOWN_COUNTRY"
    }
  ],
  "meta": {
    "total_requested": 3,
    "total_success": 2,
    "total_errors": 1,
    "tenant_id": "ecomlg-001"
  }
}
```

### Response Fields

| Field | Description |
|-------|-------------|
| items | Successful results |
| items[].rate | Commission rate (0.15 = 15%) or null if error |
| items[].source | "spapi" (from Amazon API) or "fallback" (default table) |
| items[].category | Category used for fallback rate |
| items[].error | Error code if source is "fallback" or "error" |
| errors | Items with errors (rate = null) |
| meta | Request metadata |

### Error Codes

| Code | Description |
|------|-------------|
| NO_CREDENTIALS | Amazon SP-API not connected for tenant |
| UNKNOWN_COUNTRY | Country code not supported |
| SPAPI_ERROR_403 | Amazon API returned 403 (permissions) |
| SPAPI_ERROR_* | Amazon API error |
| NO_REFERRAL_FEE | No referral fee found in response |
| NO_RESULT | No result from Amazon API |

### Error Responses

**401 Unauthorized** - Missing or invalid token:
```json
{"error": "Unauthorized", "message": "Missing or invalid Authorization header"}
```

**400 Bad Request** - Invalid payload:
```json
{"error": "Bad Request", "message": "Missing or invalid 'items' array"}
```

**500 Internal Server Error** - Server error:
```json
{"error": "Internal Server Error", "message": "Failed to process commission rates"}
```

## Supported Countries

| Code | Marketplace | Currency |
|------|-------------|----------|
| FR | Amazon.fr | EUR |
| DE | Amazon.de | EUR |
| IT | Amazon.it | EUR |
| ES | Amazon.es | EUR |
| UK/GB | Amazon.co.uk | GBP |
| NL | Amazon.nl | EUR |
| BE | Amazon.be | EUR |
| PL | Amazon.pl | PLN |
| SE | Amazon.se | SEK |
| US | Amazon.com | USD |
| CA | Amazon.ca | CAD |
| MX | Amazon.com.mx | MXN |

## Default Referral Fee Rates (Fallback)

| Category | Rate |
|----------|------|
| Amazon Device Accessories | 45% |
| Jewelry | 20% |
| Clothing & Accessories | 17% |
| Books, Music, Software, Video Games | 15% |
| Home, Kitchen, Furniture, Garden, Sports | 15% |
| Automotive | 12% |
| Beauty, Baby, Grocery, Health | 8% |
| Electronics, Computers, Camera | 8% |
| DEFAULT | 15% |

## Curl Examples

### Basic Request

```bash
curl -X POST 'https://backend-dev.keybuzz.io/api/internal/amazon/commission-rates' \
  -H 'Authorization: Bearer <TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{
    "items": [
      {"sku": "SKU-001", "country": "FR", "price": 29.99},
      {"sku": "SKU-002", "country": "DE", "price": 49.99}
    ]
  }'
```

### With ASIN

```bash
curl -X POST 'https://backend-dev.keybuzz.io/api/internal/amazon/commission-rates' \
  -H 'Authorization: Bearer <TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{
    "items": [
      {"sku": "SKU-001", "asin": "B08EXAMPLE", "country": "FR", "price": 29.99}
    ]
  }'
```

### Health Check

```bash
curl 'https://backend-dev.keybuzz.io/api/internal/amazon/commission-rates/health'
```

Response:
```json
{"status": "ok", "service": "amazon-commission-rates", "configured": true, "timestamp": "..."}
```

## Configuration

### Environment Variable

```
KEYBUZZ_INTERNAL_TOKEN=<secure-random-token>
```

Set in Kubernetes deployment:
```bash
kubectl set env deploy/keybuzz-backend -n keybuzz-backend-dev KEYBUZZ_INTERNAL_TOKEN=<token>
```

### Current Token (DEV)

```
fca299a68a2ff8180b88cf24a397832dd2c8f7ca27fa32b02f63615b7c76deac
```

**Note**: This token should be rotated for production use.

## Implementation Details

### Files

- `src/modules/marketplaces/amazon/amazonFees.service.ts` - Service logic
- `src/modules/marketplaces/amazon/amazonFees.routes.ts` - Route handlers

### SP-API Integration

The endpoint tries to fetch real referral fee rates from Amazon SP-API:
1. Gets tenant credentials from Vault
2. Obtains access token
3. Calls `POST /products/fees/v0/feesEstimate`
4. Extracts `ReferralFee` from response

If SP-API fails (permissions, rate limit, etc.), fallback rates are used.

### Limitations

- Amazon SP-API Product Fees requires specific permissions
- Currently falling back to default rates (15%) due to 403 errors
- Solution: Enable "Product Fees" permission in Amazon Seller Central

## Versions

- Backend: `1.0.24-dev`
- Endpoint: `/api/internal/amazon/commission-rates`

---
*Date*: 2026-01-12
*Phase*: PH15-AMAZON-COMMISSION-RATES
