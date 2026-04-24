# PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01 — BUSINESS METRICS OPERATIONAL

> Date : 2026-04-20
> Type : Data layer + metrics API
> Environnement : DEV uniquement
> Verdict : **BUSINESS METRICS OPERATIONAL**

---

## Preflight


| Element          | Valeur                                                                                                                              |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Image API avant  | `v3.5.81-linkedin-api-replay-dev`                                                                                                   |
| Image API apres  | `v3.5.82-metrics-dev`                                                                                                               |
| Client DEV       | `v3.5.83-linkedin-replay-dev` (INCHANGE)                                                                                            |
| Client PROD      | `v3.5.81-tiktok-attribution-fix-prod` (INCHANGE)                                                                                    |
| API PROD         | `v3.5.79-tiktok-api-replay-prod` (INCHANGE)                                                                                         |
| PROD touchee     | **NON**                                                                                                                             |
| Client modifie   | **NON**                                                                                                                             |
| Tracking modifie | **NON**                                                                                                                             |
| Rollback         | `kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.81-linkedin-api-replay-dev -n keybuzz-api-dev` |


---

## 1. Mapping des tables


| Table                   | Colonnes cles                             | Rows DEV | Utilisation                      |
| ----------------------- | ----------------------------------------- | -------- | -------------------------------- |
| `tenants`               | id, plan, status, created_at              | 19       | new_customers (COUNT par date)   |
| `billing_subscriptions` | tenant_id, plan, status, billing_cycle    | 16       | revenue (MRR par plan actif)     |
| `billing_events`        | event_type, payload (jsonb), created_at   | 242      | audit evenements Stripe          |
| `billing_customers`     | tenant_id, stripe_customer_id, email      | -        | mapping Stripe                   |
| `signup_attribution`    | tenant_id, user_email, utm_*, created_at  | 6        | attribution source               |
| `ad_spend` **NOUVELLE** | date, channel, spend, impressions, clicks | 16       | depenses publicitaires par canal |


---

## 2. Table `ad_spend` — Schema

```sql
CREATE TABLE IF NOT EXISTS ad_spend (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  channel TEXT NOT NULL,
  spend NUMERIC(12,2) NOT NULL DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(date, channel)
);

CREATE INDEX idx_ad_spend_date ON ad_spend(date);
CREATE INDEX idx_ad_spend_channel ON ad_spend(channel);
```

### Donnees test inserees


| Date       | Meta   | Google | TikTok | LinkedIn |
| ---------- | ------ | ------ | ------ | -------- |
| 2026-01-15 | 150.00 | 200.00 | 80.00  | 120.00   |
| 2026-02-01 | 180.00 | 220.00 | 95.00  | 140.00   |
| 2026-02-15 | 200.00 | 250.00 | 110.00 | 160.00   |
| 2026-03-01 | 220.00 | 280.00 | 130.00 | 180.00   |


**Total spend** : 2 715.00 EUR

---

## 3. Formules metriques

### New Customers

```sql
SELECT COUNT(*) FROM tenants
WHERE created_at >= :from AND created_at < :to + 1 day
AND status != 'deleted'
```

### Revenue (MRR)

```sql
SELECT COALESCE(SUM(
  CASE LOWER(plan)
    WHEN 'starter' THEN 97
    WHEN 'pro' THEN 297
    WHEN 'autopilot' THEN 497
    WHEN 'autopilote' THEN 497
    ELSE 0
  END
), 0) as mrr
FROM billing_subscriptions
WHERE status IN ('active', 'trialing')
```


| Plan      | Prix EUR/mois |
| --------- | ------------- |
| Starter   | 97            |
| Pro       | 297           |
| Autopilot | 497           |


### CAC Blended

```
CAC = SUM(ad_spend.spend) / COUNT(new_customers)
```

### ROAS Blended

```
ROAS = MRR / SUM(ad_spend.spend)
```

---

## 4. Endpoint API

### `GET /metrics/overview`


| Parametre | Type   | Defaut      | Description             |
| --------- | ------ | ----------- | ----------------------- |
| `from`    | string | 2026-01-01  | Date debut (YYYY-MM-DD) |
| `to`      | string | aujourd'hui | Date fin (YYYY-MM-DD)   |


### Reponse

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 19,
  "customers_by_plan": {
    "pro": 10,
    "starter": 2,
    "autopilot": 7
  },
  "revenue": {
    "mrr": 5952,
    "currency": "EUR"
  },
  "spend": {
    "total": 2715,
    "by_channel": [
      { "channel": "google", "spend": 950, "impressions": 40500, "clicks": 1330 },
      { "channel": "meta", "spend": 750, "impressions": 60000, "clicks": 1760 },
      { "channel": "linkedin", "spend": 600, "impressions": 15000, "clicks": 410 },
      { "channel": "tiktok", "spend": 415, "impressions": 75000, "clicks": 980 }
    ],
    "currency": "EUR"
  },
  "cac": 142.89,
  "roas": 2.19,
  "computed_at": "2026-04-20T06:38:52.986Z"
}
```

---

## 5. Module API

### Fichier cree

`src/modules/metrics/routes.ts` — 98 lignes

### Registration dans `app.ts`

```typescript
import { metricsRoutes } from './modules/metrics/routes';
// ...
app.register(metricsRoutes, { prefix: '/metrics' });
```

### Git commit

```
46e13695 PH-T8.1-2: add business metrics endpoint (GET /metrics/overview)
```

Branche : `ph147.4/source-of-truth`

---

## 6. Validation

### Endpoint fonctionnel


| Test                             | Resultat | HTTP Code |
| -------------------------------- | -------- | --------- |
| `GET /metrics/overview`          | OK       | 200       |
| `GET /metrics/overview?from=...` | OK       | 200       |
| `GET /health`                    | OK       | 200       |
| `GET /messages/conversations`    | OK       | 200       |
| `GET /tenant-context/me`         | OK       | 200       |
| `GET /dashboard/summary`         | OK       | 200       |


### Coherence mathematique


| Metrique      | Valeur calculee | Verification                    |
| ------------- | --------------- | ------------------------------- |
| new_customers | 19              | = COUNT(tenants) confirmé       |
| MRR           | 5 952 EUR       | = SUM(plan_price * active_subs) |
| Total spend   | 2 715 EUR       | = SUM(ad_spend) confirmé        |
| CAC           | 142.89 EUR      | = 2715 / 19 = 142.89 ✓          |
| ROAS          | 2.19            | = 5952 / 2715 = 2.19 ✓          |


### Non-regression

- Health : 200
- Conversations : 200
- Tenant context : 200
- Dashboard : 200 (avec params)
- Billing : 400 (params requis — attendu)
- AUCUN endpoint existant impacte

---

## 7. Architecture

```
[GET /metrics/overview?from=&to=]
       |
       v
  metricsRoutes (src/modules/metrics/routes.ts)
       |
       ├── SELECT COUNT(*) FROM tenants          → new_customers
       ├── SELECT SUM(CASE plan...) FROM         → MRR (revenue)
       │       billing_subscriptions
       ├── SELECT SUM(spend) FROM ad_spend       → total_spend
       ├── SELECT channel, SUM(spend)...         → spend_by_channel
       │       FROM ad_spend GROUP BY channel
       └── Compute:
            CAC = total_spend / new_customers
            ROAS = MRR / total_spend
```

---

## 8. Donnees DEV actuelles (snapshot)


| Metrique           | Valeur                         |
| ------------------ | ------------------------------ |
| Tenants totaux     | 19                             |
| Plans              | STARTER:2, PRO:10, AUTOPILOT:7 |
| Subscriptions      | active:8, trialing:8           |
| MRR                | 5 952 EUR                      |
| Total ad spend     | 2 715 EUR                      |
| Canaux ad          | Meta, Google, TikTok, LinkedIn |
| CAC blended        | 142.89 EUR                     |
| ROAS blended       | 2.19x                          |
| signup_attribution | 6 lignes                       |


---

## 9. Rollback

### API

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.81-linkedin-api-replay-dev \
  -n keybuzz-api-dev
```

### Table ad_spend

```sql
DROP TABLE IF EXISTS ad_spend;
```

### Impact rollback

- L'endpoint `/metrics/overview` retournera 404 apres rollback API
- La table `ad_spend` peut etre supprimee sans impact sur le reste du SaaS
- AUCUN autre service n'utilise `ad_spend` ni `/metrics/overview`

---

## 10. Prochaines etapes


| #   | Action                                                                         | Priorite         |
| --- | ------------------------------------------------------------------------------ | ---------------- |
| 1   | Connecter les vraies depenses publicitaires (Meta/Google/TikTok/LinkedIn APIs) | Haute            |
| 2   | Dashboard UI admin pour visualiser les metriques                               | Moyenne          |
| 3   | Historique MRR (snapshot mensuel vs MRR actuel)                                | Moyenne          |
| 4   | CAC par canal (pas seulement blended)                                          | Basse            |
| 5   | LTV et LTV/CAC ratio                                                           | Basse            |
| 6   | Promotion PROD                                                                 | Apres validation |


---

## Conclusion

### Resume

Les metriques business fondamentales sont operationnelles en DEV :

- **Table `ad_spend`** creee avec donnees test (4 canaux, 4 dates)
- **Endpoint `GET /metrics/overview`** deploye et fonctionnel
- **CAC blended, ROAS blended, MRR, new_customers** calcules dynamiquement
- Filtrage par date (`from`/`to`) operationnel
- Zero impact sur les services existants

### Verdict

**BUSINESS METRICS OPERATIONAL**

- Table ad_spend : creee ✅
- Endpoint /metrics/overview : deploye ✅
- CAC blended : calcule (142.89 EUR) ✅
- ROAS blended : calcule (2.19x) ✅
- Revenue MRR : calcule (5 952 EUR) ✅
- New customers : calcule (19) ✅
- Non-regression : confirmee ✅
- PROD : intacte ✅
- Client : intact ✅

