# PH-T8.3.1 — Audit verite API GET /metrics/overview

> Date : 20 avril 2026
> Environnement teste : DEV (api-dev.keybuzz.io)

---

## 1. Endpoint

`GET /metrics/overview`

### Parametres

| Parametre | Type   | Defaut      | Description             |
|-----------|--------|-------------|-------------------------|
| `from`    | string | 2026-01-01  | Date debut (YYYY-MM-DD) |
| `to`      | string | aujourd'hui | Date fin (YYYY-MM-DD)   |

### Comportement sans parametres

Retourne les metriques sur la periode par defaut (2026-01-01 a aujourd'hui). HTTP 200.

### Comportement avec parametres

`?from=2026-01-01&to=2026-04-20` — retourne les metriques filtrees par la periode specifiee. HTTP 200.

---

## 2. Payload reel (capture 20 avril 2026)

```json
{
  "period": {
    "from": "2026-01-01",
    "to": "2026-04-20"
  },
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
  "computed_at": "2026-04-20T08:56:22.046Z"
}
```

---

## 3. Verification champs

| Champ              | Present | Type              | Valeur DEV           |
|--------------------|---------|-------------------|----------------------|
| `period`           | OUI     | `{from, to}`      | 2026-01-01 → 04-20   |
| `new_customers`    | OUI     | number            | 19                   |
| `customers_by_plan`| OUI     | Record<string, n> | pro:10, starter:2, autopilot:7 |
| `revenue.mrr`      | OUI     | number            | 5952                 |
| `revenue.currency` | OUI     | string            | EUR                  |
| `spend.total`      | OUI     | number            | 2715                 |
| `spend.by_channel` | OUI     | ChannelSpend[]    | 4 canaux             |
| `spend.currency`   | OUI     | string            | EUR                  |
| `cac`              | OUI     | number            | 142.89               |
| `roas`             | OUI     | number            | 2.19                 |
| `computed_at`      | OUI     | ISO 8601 string   | 2026-04-20T08:56:22Z |

---

## 4. Format computed_at

ISO 8601 avec millisecondes : `2026-04-20T08:56:22.046Z`

Fuseau : UTC (suffixe `Z`)

---

## 5. Verdict

**ENDPOINT FONCTIONNEL — PAYLOAD CONFORME A LA DOCUMENTATION**

Tous les champs attendus sont presents. Les valeurs sont coherentes avec les donnees DB DEV.
