# PH143-H — Tracking / Orders Rebuild

> Phase : PH143-H-TRACKING-ORDERS-REBUILD-01
> Date : 2026-04-06
> Branches : rebuild/ph143-api / rebuild/ph143-client
> Tags : v3.5.201-ph143-tracking-dev (API + Client)

---

## Objectif

Reconstruire completement le systeme tracking multi-transporteurs, integration 17TRACK, BFF tracking, coherence avec orders, et utilisation par l'IA.

---

## Travail realise

### API (rebuild/ph143-api)

| Fichier | Action |
|---------|--------|
| `src/modules/orders/carrierTracking.routes.ts` | Porte depuis main (112 lignes) |
| `src/modules/orders/carrierLiveTracking.service.ts` | Porte depuis main (366 lignes) |
| `src/modules/tracking/trackingWebhook.routes.ts` | Porte depuis main (112 lignes) |
| `src/services/tracking/providerFactory.ts` | Porte depuis main (62 lignes) |
| `src/services/tracking/seventeenTrackProvider.ts` | Porte depuis main (175 lignes) |
| `src/services/tracking/trackingProvider.ts` | Deja present |
| `src/modules/orders/routes.ts` | Porte (version enrichie avec tracking fields) |
| `src/app.ts` | Ajoute imports + registrations carrierTracking + trackingWebhook |

Commits : `a2aee1f`, `91ac940` (fix providerFactory)

### Client (rebuild/ph143-client)

| Fichier | Action |
|---------|--------|
| `app/api/orders/tracking/status/route.ts` | Cree BFF proxy vers API |

Commit : `924f4a1`

### Elements deja presents sur le rebuild (pas de modification)

| Element | Fichier | Status |
|---------|---------|--------|
| extractTrackingFromPackages | `orders/routes.ts` | OK (multi-carrier URL builder) |
| carrierIntegrationEngine | `services/carrierIntegrationEngine.ts` | OK |
| suggestion-tracking-routes | `modules/ai/suggestion-tracking-routes.ts` | OK |
| shared-ai-context (tracking) | `modules/ai/shared-ai-context.ts` | OK (carrier, trackingCode, trackingUrl, trackingSource, carrierDeliveryStatus) |
| ai-assist-routes (tracking) | `modules/ai/ai-assist-routes.ts` | OK (injection tracking dans prompt IA) |
| Orders list page | `app/orders/page.tsx` | OK (tracking links affichés) |
| Orders detail page | `app/orders/[orderId]/page.tsx` | OK (tab tracking + carrier info) |
| OrderSidePanel | `src/features/inbox/components/OrderSidePanel.tsx` | OK (tracking section) |
| BFF orders routes | `app/api/orders/` | OK (list, detail, sync, export, import) |

---

## Architecture tracking

```
Transporteur -> 17TRACK API -> trackingWebhook -> DB events
                 ^
                 |
carrierTracking.routes.ts
  GET /tracking/status -> config + stats events
  POST /tracking/refresh/:orderId -> live refresh via providerFactory

providerFactory.ts
  └─ seventeenTrackProvider.ts (17TRACK integration)
  └─ trackingProvider.ts (interface)

carrierLiveTracking.service.ts
  └─ loadTrackingEvents() -> enrichit orders avec carrier live data
  └─ normalizeCarrier() -> normalise noms transporteurs

orders/routes.ts
  └─ extractTrackingFromPackages() -> multi-carrier URL builder
  └─ champs enrichis: trackingSource, carrierNormalized, carrierDeliveryStatus

shared-ai-context.ts
  └─ OrderContext includes: carrier, trackingCode, trackingUrl, trackingSource,
     carrierNormalized, carrierDeliveryStatus

ai-assist-routes.ts
  └─ Inject tracking dans prompt IA: "Numero de suivi disponible: {code} ({carrier})"
  └─ PH137-C: Enriched tracking data (carrier live, delivery status)
```

### Transporteurs supportes (URL builder)

UPS, DHL, FedEx, Chronopost, Colissimo/La Poste, Amazon, GLS, DPD, TNT, Mondial Relay + fallback ParcelsApp

---

## Tests realises

### API (kubectl exec)

| Endpoint | Status | Donnees |
|----------|--------|---------|
| `GET /health` | 200 | OK |
| `GET /api/v1/orders/tracking/status` | 200 | 17TRACK configure, 32316 events, 11927 orders avec events |
| `GET /api/v1/orders?tenantId=ecomlg-001&limit=3` | 200 | Orders avec tracking fields enrichis |
| `GET /dashboard/supervision` | 200 | OK (non-regression PH143-G) |
| `GET /tenant-context/signature` | 200 | OK (non-regression PH143-F) |
| `GET /billing/current` | 200 | OK (non-regression PH143-B) |

### Navigateur (client-dev.keybuzz.io)

| Page | Validation |
|------|-----------|
| `/orders` | Liste commandes avec tracking links (UPS, Colissimo) |
| `/orders` | KPIs: Total 6, En transit 5, En retard 3, SAV 2 |
| `/orders` | Liens tracking cliquables : "UPS — 1Z497..." |
| `/dashboard` | SupervisionPanel + KPIs OK |
| `/dashboard` | Activite recente + SLA badges OK |

### Non-regression

| Feature | Status |
|---------|--------|
| Dashboard + Supervision | OK |
| Inbox + SLA badges | OK |
| Signature | OK |
| Billing | OK |
| IA (shared-ai-context tracking) | OK (identique main) |

---

## Verdict

**TRACKING RELIABLE — ORDERS CONNECTED — AI CONTEXT COMPLETE**

- Tracking multi-transporteurs fonctionnel (17TRACK + URL builder)
- Orders enrichis avec tracking fields complets
- IA injecte le tracking dans le prompt (carrier, code, status)
- BFF tracking/status disponible
- Non-regression validee sur tous les blocs precedents

**GO pour PH143-I**
