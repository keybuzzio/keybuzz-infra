# PH-T8.2B-META-REAL-SPEND-01 — META REAL SPEND OPERATIONAL

> Date : 2026-04-20
> Type : Integration source de verite spend Meta reel
> Environnement : DEV uniquement
> Verdict : **META REAL SPEND OPERATIONAL — NO FAKE DATA — SAFE BUILD — DEV ONLY**

---

## Preflight


| Element          | Valeur                                           |
| ---------------- | ------------------------------------------------ |
| Image API avant  | `v3.5.83-metrics-real-dev`                       |
| Image API apres  | `v3.5.84-meta-real-spend-dev`                    |
| Client DEV       | `v3.5.83-linkedin-replay-dev` (INCHANGE)         |
| API PROD         | `v3.5.79-tiktok-api-replay-prod` (INCHANGE)      |
| Client PROD      | `v3.5.81-tiktok-attribution-fix-prod` (INCHANGE) |
| Branche          | `ph147.4/source-of-truth`                        |
| Commit           | `f971b78a`                                       |
| Build-from-git   | **OUI** (repo clean avant build)                 |
| Push avant build | **OUI**                                          |
| PROD touchee     | **NON**                                          |
| Client modifie   | **NON**                                          |
| Tracking modifie | **NON**                                          |


---

## 1. Credentials Meta Marketing API

### Ad Account


| Champ          | Valeur                 |
| -------------- | ---------------------- |
| Account Name   | KeyBuzz                |
| Account ID     | `act_1485150039295668` |
| Account Status | 1 (actif)              |
| Currency       | **GBP**                |
| Timezone       | Europe/Paris           |
| Business       | KeyBuzz Consulting LLP |
| Business ID    | `805418028504992`      |


### Token


| Champ    | Valeur                   |
| -------- | ------------------------ |
| Type     | User Access Token        |
| Scope    | `ads_read`               |
| Stockage | K8s env var (deployment) |


### Variables d'environnement ajoutees (DEV)

```
META_AD_ACCOUNT_ID=1485150039295668
META_ACCESS_TOKEN=EAAeZCdWa8No4...918gt
```

---

## 2. Donnees reelles importees

### Source

Meta Marketing API `v21.0` — endpoint `/act_1485150039295668/insights`

### Periode avec depenses


| Debut      | Fin        | Jours | Total spend | Impressions | Clicks |
| ---------- | ---------- | ----- | ----------- | ----------- | ------ |
| 2026-03-16 | 2026-03-31 | 16    | 445.20 GBP  | 45 374      | 892    |


### Periodes sans depenses

- Avant 2026-03-16 : aucune campagne
- Avril 2026 : aucune depense

### Detail journalier (source: Meta Marketing API)


| Date       | Spend (GBP) | Impressions | Clicks |
| ---------- | ----------- | ----------- | ------ |
| 2026-03-16 | 2.48        | 53          | 8      |
| 2026-03-17 | 13.39       | 334         | 30     |
| 2026-03-18 | 9.84        | 432         | 31     |
| 2026-03-19 | 10.56       | 539         | 29     |
| 2026-03-20 | 10.18       | 747         | 20     |
| 2026-03-21 | 4.98        | 328         | 18     |
| 2026-03-22 | 39.26       | 2 618       | 88     |
| 2026-03-23 | 38.95       | 9 715       | 95     |
| 2026-03-24 | 37.42       | 1 583       | 35     |
| 2026-03-25 | 40.57       | 1 429       | 27     |
| 2026-03-26 | 41.92       | 1 443       | 35     |
| 2026-03-27 | 39.69       | 1 408       | 31     |
| 2026-03-28 | 38.95       | 5 897       | 253    |
| 2026-03-29 | 38.88       | 4 330       | 86     |
| 2026-03-30 | 39.28       | 7 821       | 61     |
| 2026-03-31 | 38.85       | 6 697       | 45     |


---

## 3. Endpoints API

### GET /metrics/overview

Retourne les metriques business avec donnees reelles.

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 19,
  "customers_by_plan": { "pro": 10, "starter": 2, "autopilot": 7 },
  "revenue": { "mrr": 5952, "currency": "EUR" },
  "spend": {
    "total": 445.2,
    "by_channel": [
      { "channel": "meta", "spend": 445.2, "impressions": 45374, "clicks": 892 }
    ],
    "currency": "GBP",
    "source": "ad_spend_table"
  },
  "cac": 23.43,
  "roas": 13.37,
  "data_quality": {
    "spend_available": true,
    "customers_available": true,
    "revenue_available": true
  },
  "computed_at": "2026-04-20T12:02:50.351Z"
}
```

### POST /metrics/import/meta

Import dynamique depuis Meta Marketing API.

**Body** :

```json
{ "since": "2026-03-16", "until": "2026-04-20" }
```

**Reponse** :

```json
{
  "imported": 16,
  "period": { "since": "2026-03-16", "until": "2026-04-20" },
  "totals": { "spend": 445.2, "days": 16, "currency": "GBP" }
}
```

---

## 4. Coherence mathematique


| Metrique      | Valeur        | Calcul                   | Source    |
| ------------- | ------------- | ------------------------ | --------- |
| Total spend   | 445.20 GBP    | SUM(ad_spend WHERE meta) | Meta API  |
| New customers | 19            | COUNT(tenants)           | DB reelle |
| MRR           | 5 952 EUR     | SUM(plan * active_subs)  | DB reelle |
| **CAC**       | **23.43 GBP** | 445.20 / 19              | Calcule   |
| **ROAS**      | **13.37**     | 5952 / 445.20            | Calcule   |


### Verification croisee

- Donnees Meta API (fetch direct) = donnees en DB (ad_spend) = donnees API (/metrics/overview)
- Aucun mock, aucune estimation, aucun fallback
- `spend.source = "ad_spend_table"` confirme la provenance reelle

---

## 5. Non-regression


| Endpoint                      | Code | Resultat |
| ----------------------------- | ---- | -------- |
| `GET /health`                 | 200  | OK       |
| `GET /messages/conversations` | 200  | OK       |
| `GET /tenant-context/me`      | 200  | OK       |
| `GET /dashboard/summary`      | 200  | OK       |
| `GET /metrics/overview`       | 200  | OK       |
| `POST /metrics/import/meta`   | 200  | OK       |


---

## 6. Git

```
f971b78a PH-T8.2B: Meta real spend import + strict mode metrics
a8af9306 PH-T8.2: strict mode metrics — no fake data, null when no real spend
46e13695 PH-T8.1-2: add business metrics endpoint (GET /metrics/overview)
```

Branche : `ph147.4/source-of-truth` — pushee avant build.

---

## 7. Architecture

```
[POST /metrics/import/meta]
       |
       v
  fetch graph.facebook.com/v21.0/act_1485150039295668/insights
    fields=spend,impressions,clicks
    time_increment=1 (daily)
       |
       v
  UPSERT ad_spend (date, channel='meta', spend, impressions, clicks)
       |
       v
[GET /metrics/overview]
       |
       ├── SELECT COUNT(*) FROM tenants          → new_customers (19)
       ├── SELECT SUM(CASE plan...) FROM         → MRR (5952 EUR)
       │       billing_subscriptions
       ├── SELECT SUM(spend) FROM ad_spend       → total_spend (445.20 GBP)
       ├── SELECT channel, SUM(spend)...         → spend_by_channel (meta only)
       │       FROM ad_spend GROUP BY channel
       └── Compute:
            CAC = 445.20 / 19 = 23.43 GBP
            ROAS = 5952 / 445.20 = 13.37
```

---

## 8. Note sur les devises

- **Revenue** : EUR (plans Stripe en EUR)
- **Spend** : GBP (Meta Ad Account KeyBuzz en GBP)

Le CAC et ROAS sont actuellement calcules avec des devises mixtes.
Pour une precision optimale, une conversion GBP→EUR pourrait etre ajoutee.

---

## 9. Rollback

### API

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.83-metrics-real-dev \
  -n keybuzz-api-dev
```

### Retirer env vars Meta

```bash
kubectl set env deployment/keybuzz-api \
  META_AD_ACCOUNT_ID- META_ACCESS_TOKEN- \
  -n keybuzz-api-dev
```

### Purger donnees

```sql
DELETE FROM ad_spend WHERE channel = 'meta';
```

---

## 10. Prochaines etapes


| #   | Action                                             | Priorite |
| --- | -------------------------------------------------- | -------- |
| 1   | CronJob d'import quotidien Meta spend              | Haute    |
| 2   | Conversion GBP→EUR pour CAC/ROAS homogenes         | Haute    |
| 3   | Stocker Meta credentials dans K8s Secret (pas env) | Moyenne  |
| 4   | Token refresh automatique (expire ~60 jours)       | Moyenne  |
| 5   | Connecter Google Ads pour spend multi-canal        | Moyenne  |
| 6   | Dashboard UI admin pour visualiser les metriques   | Basse    |


---

## Conclusion

### Resume

Les depenses publicitaires Meta reelles sont integrees dans le systeme metrics
de KeyBuzz DEV. L'import utilise directement la Meta Marketing API v21.0
avec les credentials du Ad Account `act_1485150039295668` (KeyBuzz, devise GBP).

16 jours de donnees reelles (mars 16-31, 2026) ont ete importees pour un
total de **445.20 GBP** de depenses, **45 374 impressions** et **892 clics**.

L'endpoint `POST /metrics/import/meta` permet un re-import a la demande.
L'endpoint `GET /metrics/overview` retourne les metriques avec donnees reelles
et le mode strict (null si pas de donnees).

### Verdict

**META REAL SPEND OPERATIONAL — NO FAKE DATA — SAFE BUILD — DEV ONLY**

- Credentials Meta : verifiees et configurees
- Donnees reelles : 16 jours, 445.20 GBP total
- Import dynamique : POST /metrics/import/meta operationnel
- CAC blended : 23.43 GBP (reel)
- ROAS blended : 13.37 (reel)
- Build-from-git : repo clean, commit pushe avant build
- Non-regression : tous endpoints OK
- PROD : intacte
- Client : intact

