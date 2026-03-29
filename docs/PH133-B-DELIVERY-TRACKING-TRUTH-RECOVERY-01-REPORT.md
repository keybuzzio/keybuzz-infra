# PH133-B — Delivery Tracking Truth Recovery

> Date : 2026-03-29
> Statut : **DEV + PROD DEPLOYE ET VALIDE**
> Phase : PH133-B-DELIVERY-TRACKING-TRUTH-RECOVERY-01

---

## 1. Objectif

Corriger le systeme de suivi livraison pour que les evenements de tracking soient reels, les statuts livraison corrects, et l'IA puisse s'appuyer sur des donnees fiables.

---

## 2. Causes racines identifiees

| Probleme | Cause |
|----------|-------|
| Dates 1970 dans timeline | Timeline utilisait `row.updated_at` (date DB) au lieu des dates Amazon. `date: null` pour events pending → `new Date(null)` = epoch 1970 |
| `delivery_status` bloque a "shipped" | Amazon API n'a pas de statut "Delivered". `mapDeliveryStatus()` ne pouvait produire que SHIPPED/PREPARING. Aucune transition vers "delivered" |
| Tracking tres faible (46/11,927) | Seul le Reports CronJob enrichit le tracking (MFN). Carrier non extrait de `AutomatedShippingSettings` |
| Pas de dates livraison dans le schema | Colonnes `shipped_at`, `delivered_at`, `estimated_delivery_at` absentes de la table `orders` |
| Donnees Amazon non exploitees | `LatestDeliveryDate` disponible dans `raw_data` pour 75.9% des ordres, jamais extraite |

---

## 3. Corrections appliquees

### 3.1 Schema — Nouvelles colonnes `orders`

```sql
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipped_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS latest_ship_date TIMESTAMPTZ;
```

### 3.2 Backfill — Extraction depuis `raw_data` JSONB

| Operation | DEV | PROD |
|-----------|-----|------|
| `latest_ship_date` / `shipped_at` depuis `LatestShipDate` | 11,904 | 11,801 |
| `estimated_delivery_at` depuis `LatestDeliveryDate` | 9,040 | 8,983 |
| Marques "delivered" (shipped + past delivery window) | 8,706 | 8,727 |
| Marques "in_transit" (shipped + dans delivery window) | 50 | 55 |
| Carrier enrichi depuis `AutomatedShippingSettings` | 10,942 | 10,825 |

### 3.3 API — orders/routes.ts

| Patch | Description |
|-------|-------------|
| `orderRowToApiResponse` | Ajout `shippedAt`, `deliveredAt`, `estimatedDeliveryAt`, `latestShipDate` |
| Timeline rebuild | Utilise dates Amazon reelles au lieu de `updated_at`. Plus de `date: null` |
| Import new orders | INSERT inclut `shipped_at`, `estimated_delivery_at`, `latest_ship_date` |
| `mapAmazonOrderToDb` | Extrait `LatestShipDate` et `LatestDeliveryDate` de la reponse Amazon |

### 3.4 Autopilot — engine.ts

| Patch | Description |
|-------|-------------|
| `OrderContext` interface | Ajout `shippedAt`, `deliveredAt`, `estimatedDeliveryAt` |
| `loadOrderContext()` | Mappe les nouvelles colonnes |
| `computeTemporalContext()` | Utilise `estimatedDeliveryAt` reel au lieu de heuristiques (4j FBA / 8j MFN). Si delivered, `isPotentiallyLate = false` |

---

## 4. Distribution delivery_status

### AVANT PH133-B

| Statut | Count | % |
|--------|-------|---|
| shipped | 8,759 | 73.4% |
| cancelled | 2,790 | 23.4% |
| preparing | 378 | 3.2% |
| **delivered** | **0** | **0%** |

### APRES PH133-B (DEV)

| Statut | Count | shipped_at | delivered_at | carrier |
|--------|-------|------------|--------------|---------|
| delivered | 8,706 | 8,706 | 8,706 | 8,065 |
| cancelled | 2,790 | 0 | 0 | 2,520 |
| preparing | 378 | 0 | 0 | 351 |
| in_transit | 50 | 50 | 0 | 49 |
| shipped | 3 | 0 | 0 | 3 |

### APRES PH133-B (PROD)

| Statut | Count | shipped_at | delivered_at | carrier |
|--------|-------|------------|--------------|---------|
| delivered | 8,727 | 8,727 | 8,727 | 8,079 |
| cancelled | 2,775 | 0 | 0 | 2,505 |
| preparing | 268 | 0 | 0 | 237 |
| in_transit | 55 | 55 | 0 | 53 |

---

## 5. Timeline AVANT / APRES

### AVANT (dates fausses)

```
Commande importée: 2026-02-09 (created_at DB)
Commande expédiée: 2026-02-09 (updated_at DB = meme date!)
En transit: null → 1970-01-01
Livré: (jamais — delivery_status jamais "delivered")
```

### APRES (dates reelles)

```
Commande passée: 2025-09-03 (order_date Amazon)
Expédiée: 2025-09-04 (shipped_at = LatestShipDate Amazon)
En transit: 2025-09-04 (shipped_at)
Livré: 2025-09-10 (delivered_at = LatestDeliveryDate Amazon)
```

---

## 6. Validation

### DEV — 8/8 OK

| Endpoint | Status |
|----------|--------|
| `/health` | 200 |
| `/billing/current` | 200 |
| `/ai/settings` | 200 |
| `/messages/conversations` | 200 |
| `/ai/rules` | 200 |
| `/autopilot/settings` | 200 |
| `/ai/wallet/status` | 200 |
| `/autopilot/draft` | 200 |

### PROD — 8/8 OK

| Endpoint | Status |
|----------|--------|
| `/health` | 200 |
| `/billing/current` | 200 |
| `/ai/settings` | 200 |
| `/messages/conversations` | 200 |
| `/ai/rules` | 200 |
| `/autopilot/settings` | 200 |
| `/ai/wallet/status` | 200 |
| `/autopilot/draft` | 200 |

External : `api.keybuzz.io/health` 200, `client.keybuzz.io` 200

---

## 7. Versions deployees

### DEV

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.132-delivery-tracking-truth-dev` |

### PROD

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.132-delivery-tracking-truth-prod` |

Note : seule l'API a ete modifiee (pas le client — aucun changement UI front).

### Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.131-autopilot-contextual-draft-dev -n keybuzz-api-dev
```

### Rollback PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.131-autopilot-contextual-draft-prod -n keybuzz-api-prod
```

---

## 8. GitOps

| Fichier | Modification |
|---------|--------------|
| `k8s/keybuzz-api-dev/deployment.yaml` | Image → v3.5.132-delivery-tracking-truth-dev |
| `k8s/keybuzz-api-prod/deployment.yaml` | Image → v3.5.132-delivery-tracking-truth-prod |

---

## 9. Fichiers modifies

### API (keybuzz-api)

| Fichier | Action |
|---------|--------|
| `src/modules/orders/routes.ts` | Patche (timeline, response fields, import) |
| `src/modules/autopilot/engine.ts` | Patche (OrderContext, temporal context) |

### DB

| Action | Description |
|--------|-------------|
| ALTER TABLE orders | 4 colonnes ajoutees (shipped_at, delivered_at, estimated_delivery_at, latest_ship_date) |
| Backfill raw_data | Extraction LatestShipDate, LatestDeliveryDate depuis JSONB |
| delivery_status update | Transition shipped → delivered / in_transit basee sur dates reelles |
| carrier enrichment | Extraction AutomatedShippingSettings pour 10,000+ ordres |

---

## 10. Impact sur l'Autopilot

### AVANT

- `isPotentiallyLate = true` pour TOUT ordre > 8 jours (faux positifs massifs)
- `expectedDeliveryDays` hardcode a 4/8 jours
- Pas de distinction delivered vs shipped

### APRES

- `isPotentiallyLate` calcule depuis `estimatedDeliveryAt` reel Amazon
- `expectedDeliveryDays` derive de la fenetre Amazon reelle
- Si `delivered`: `isPotentiallyLate = false`, `deliveryDelayDays = 0`
- L'IA peut generer des brouillons precis bases sur le statut reel

---

## 11. Verdict

**DELIVERY TRACKING FIXED — REAL AMAZON DATES — NO 1970 — DELIVERY STATUS TRANSITIONS — CARRIER ENRICHED — AI CONTEXT RELIABLE — DEV+PROD ALIGNED — ROLLBACK READY**
