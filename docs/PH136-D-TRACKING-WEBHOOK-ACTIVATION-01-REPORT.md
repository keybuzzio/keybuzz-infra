# PH136-D — 17TRACK Webhook Activation Report

> Date : 2026-03-31
> Statut : DEV VALIDE — STOP AVANT PROD

---

## 1. Objectif

Activer le tracking transporteur reel via 17TRACK en utilisant :
- API v2.4 (register + gettrackinfo)
- Webhook push (prioritaire, gratuit apres registration)
- Polling fallback (securite)

## 2. Configuration Securisee

### Secret K8s
```
Secret: tracking-17track (namespace: keybuzz-api-dev)
Cle: TRACKING_17TRACK_API_KEY
Injection: env var dans deployment keybuzz-api via secretKeyRef
```

### Dashboard 17TRACK
- Compte : ludovic@keybuzz.pro
- Webhook URL configuree : `https://api-dev.keybuzz.io/api/v1/tracking/webhook/17track`
- Version API : v2.4
- Statuts actives pour webhook : InfoReceived, InTransit, Expired, AvailableForPickup, OutForDelivery, DeliveryFailure, Delivered, Exception
- IP whitelist : aucune (pas de restriction)

## 3. Codes Carrier Corriges

| Carrier | Code 17TRACK |
|---------|-------------|
| UPS | 100002 |
| FedEx | 100003 |
| DHL Express | 100001 |
| Colissimo/La Poste | 6051 |
| Chronopost | 100273 |
| DPD FR | 100072 |
| GLS | 100005 |
| TNT | 100004 |
| Mondial Relay | 100304 |

## 4. Fichiers Modifies/Crees

| Fichier | Action | Description |
|---------|--------|-------------|
| `src/services/tracking/seventeenTrackProvider.ts` | Reecrit | Provider v2.4 avec register() + track() + parseTrackInfo() |
| `src/services/tracking/providerFactory.ts` | Reecrit | Factory avec registerTracking() export |
| `src/modules/tracking/trackingWebhook.routes.ts` | Cree | Endpoint webhook POST /api/v1/tracking/webhook/17track |
| `src/modules/orders/carrierLiveTracking.service.ts` | Modifie | Auto-register lors du polling |
| `src/app.ts` | Modifie | Import + registration trackingWebhookRoutes |
| `src/plugins/tenantGuard.ts` | Modifie | Exemption webhook route de l'auth |

## 5. Architecture Implementee

```
Nouveau tracking enregistre
        |
        v
   17TRACK API v2.4
   POST /register
        |
        v
17TRACK scrape UPS/Colissimo/etc.
        |
        v
   WEBHOOK PUSH ──────────────────> KeyBuzz API
   TRACKING_UPDATED                 POST /api/v1/tracking/webhook/17track
        |                                    |
        v                                    v
   Verification SHA-256 (sign)      processTrackingUpdate()
                                             |
                                    ┌────────┴────────┐
                                    v                  v
                             tracking_events      orders
                             INSERT (dedup)    UPDATE carrier_delivery_status
                                               UPDATE delivered_at
                                               UPDATE tracking_source='aggregator_17track'
```

### Fallback : Polling
```
pollActiveOrdersTracking()
        |
        v
   registerTracking()  ←── Auto-enregistre sur 17TRACK
        |
        v
   trackWithProviderChain()
        |
        v
   gettrackinfo API v2.4
        |
        v
   Update DB (meme logique que webhook)
```

## 6. Validation DEV

### Test API 17TRACK
- Register 6 numeros UPS : **5 accepted, 1 deja enregistre**
- GetTrackInfo : **3 Delivered avec 9-12 evenements reels, 3 NotFound (anciens)**

### Test Webhook
- Ping test : `{"ok":true,"event":"unknown"}` ✅
- TRACKING_UPDATED reel recu : `1Z4223916897893965` → 13 events, delivered ✅
- Logs : `[17track-webhook] Updated order 402-5200517-9042745: delivered (13 events)` ✅

### Resultats DB (31 mars 2026)
| Metrique | Valeur |
|----------|--------|
| Ordres mis a jour via 17TRACK | **8** |
| Evenements tracking stockes | **87** |
| Numeros de suivi distincts | **8** |
| Statuts reels avec localisation | delivered (FR, PT, IT) |

### Exemples d'evenements reels
| Date | Statut | Description | Localisation |
|------|--------|-------------|-------------|
| 2026-03-27 11:04 | delivered | DELIVERED | SAINT-ETIENNE, FR |
| 2026-03-27 10:36 | delivered | DELIVERED | SETUBAL, PT |
| 2026-03-27 09:36 | delivered | DELIVERED | CAMPIGLIA MARITTIMA, IT |
| 2026-03-27 09:09 | out_for_delivery | Out For Delivery Today | Livorno, Italy |
| 2026-03-27 08:32 | out_for_delivery | Out For Delivery Today | L Etrat, France |

### Tracking Status Endpoint
```json
{
  "configuration": {
    "aggregator": {
      "providers": [{"name": "17track", "configured": true}],
      "activeProviders": 1
    }
  },
  "orders": {
    "total_orders": "11928",
    "with_tracking": "50"
  }
}
```

## 7. Non-Regressions

| Composant | Statut |
|-----------|--------|
| Health check | ✅ OK |
| Inbox | ✅ Inchange |
| Autopilot | ✅ Inchange |
| Billing/Wallet | ✅ Inchange |
| Outbound Amazon | ✅ Inchange |
| Email inbound/outbound | ✅ Inchange |
| Playbooks | ✅ Inchange |
| Orders API | ✅ Enrichi avec tracking_source=aggregator_17track |

## 8. Versions

| Composant | Tag DEV |
|-----------|---------|
| API | `v3.5.146c-tracking-webhook-dev` |
| Worker | `v3.5.146c-tracking-webhook-dev` (manifest) |
| Rollback | `v3.5.145b-tracking-aggregator-dev` |

## 9. Impact IA

Le moteur Autopilot (engine.ts) utilise deja les champs `carrier_delivery_status`, `tracking_source`, et `delivered_at` dans le contexte commande (PH133-A). Les donnees 17TRACK enrichissent automatiquement les drafts IA :
- Statuts reels (delivered, in_transit, out_for_delivery)
- Dates de livraison precises
- Localisations transporteur

## 10. Cout

- 6 trackings enregistres = 6 credits consommes sur le quota
- Webhook pushes = gratuits (inclus dans le credit de registration)
- Cout mensuel estime MVP : ~$47/mois (cf. PH136-C)

## 11. Prochaines Etapes (hors scope PH136-D)

1. Deployer en PROD (attente validation Ludovic)
2. Creer CronJob d'auto-registration des nouveaux trackings
3. Activer webhook PROD (URL : `https://api.keybuzz.io/api/v1/tracking/webhook/17track`)

---

## VERDICT

**TRACKING LIVE ACTIVE — WEBHOOK ENABLED — POLLING FALLBACK — AI CONTEXT REAL — TENANT SAFE — ROLLBACK READY**

DEV valide. STOP avant PROD. J'attends la validation explicite de Ludovic : "Tu peux push PROD".
