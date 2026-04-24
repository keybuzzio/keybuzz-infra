# PH-T8.2-REAL-SPEND-TRUTH-01 — METRICS DATA SOURCE CLEAN

> Date : 2026-04-20
> Type : Correction source de verite metrics
> Environnement : DEV uniquement
> Verdict : **METRICS DATA SOURCE CLEAN — NO FAKE DATA**

---

## Preflight


| Element          | Valeur                                           |
| ---------------- | ------------------------------------------------ |
| Image API avant  | `v3.5.82-metrics-dev`                            |
| Image API apres  | `v3.5.83-metrics-real-dev`                       |
| Client DEV       | `v3.5.83-linkedin-replay-dev` (INCHANGE)         |
| API PROD         | `v3.5.79-tiktok-api-replay-prod` (INCHANGE)      |
| Client PROD      | `v3.5.81-tiktok-attribution-fix-prod` (INCHANGE) |
| PROD touchee     | **NON**                                          |
| Client modifie   | **NON**                                          |
| Tracking modifie | **NON**                                          |


---

## 1. Audit ad_spend

### Donnees trouvees


| Nombre de lignes | Origine                     | Source reelle |
| ---------------- | --------------------------- | ------------- |
| 16               | `ph-t81-create-ad-spend.js` | TEST / MOCK   |


Toutes les 16 lignes ont ete inserees le 2026-04-20 par le script PH-T8.1.
Aucune donnee reelle de depense publicitaire n'a jamais ete importee.

### Donnees mock supprimees

```sql
DELETE FROM ad_spend;
-- 16 rows deleted
-- Table maintenant vide
```

---

## 2. Modifications API — Mode strict

### Avant (PH-T8.1)

- `cac` et `roas` calcules meme avec des donnees mock
- Pas de distinction entre donnees reelles et test
- Pas d'indicateur de qualite des donnees

### Apres (PH-T8.2)

- `cac` = **null** quand spend = 0
- `roas` = **null** quand spend = 0
- `spend.source` = `"no_data"` quand aucune donnee reelle
- `spend.source` = `"ad_spend_table"` quand donnees presentes
- Bloc `data_quality` pour transparence
- Verification existence table `ad_spend` (graceful si droppee)

### Fichier modifie

`src/modules/metrics/routes.ts` — 117 lignes (reecrit complet)

### Git commit

```
a8af9306 PH-T8.2: strict mode metrics — no fake data, null when no real spend
```

Branche : `ph147.4/source-of-truth`

---

## 3. Reponse API — Mode 0 spend

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 19,
  "customers_by_plan": { "pro": 10, "starter": 2, "autopilot": 7 },
  "revenue": { "mrr": 5952, "currency": "EUR" },
  "spend": {
    "total": 0,
    "by_channel": [],
    "currency": "EUR",
    "source": "no_data"
  },
  "cac": null,
  "roas": null,
  "data_quality": {
    "spend_available": false,
    "customers_available": true,
    "revenue_available": true
  },
  "computed_at": "2026-04-20T09:39:26.587Z"
}
```

---

## 4. Matrice de validation

### Cas 1 : Pas de spend reel


| Champ                          | Attendu   | Obtenu      |
| ------------------------------ | --------- | ----------- |
| `spend.total`                  | 0         | **0**       |
| `spend.by_channel`             | []        | **[]**      |
| `spend.source`                 | no_data   | **no_data** |
| `cac`                          | null      | **null**    |
| `roas`                         | null      | **null**    |
| `data_quality.spend_available` | false     | **false**   |
| `new_customers`                | reel (19) | **19**      |
| `revenue.mrr`                  | reel      | **5952**    |


### Non-regression


| Endpoint                      | Code attendu | Resultat |
| ----------------------------- | ------------ | -------- |
| `GET /health`                 | 200          | **200**  |
| `GET /messages/conversations` | 200          | **200**  |
| `GET /tenant-context/me`      | 200          | **200**  |
| `GET /dashboard/summary`      | 200          | **200**  |
| `GET /metrics/overview`       | 200          | **200**  |


---

## 5. Etat table ad_spend

La table `ad_spend` existe toujours (schema intact) mais est **vide**.
Elle est prete a recevoir des donnees reelles quand les APIs publicitaires
seront connectees (Meta, Google, TikTok, LinkedIn).

```sql
-- Schema preserve
CREATE TABLE ad_spend (
  id SERIAL PRIMARY KEY,
  date DATE NOT NULL,
  channel TEXT NOT NULL,
  spend NUMERIC(12,2) NOT NULL DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(date, channel)
);
```

---

## 6. Rollback

### API

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.82-metrics-dev \
  -n keybuzz-api-dev
```

### Restaurer mock (si necessaire)

Reexecuter `ph-t81-create-ad-spend.js` dans le pod.

---

## 7. Prochaines etapes


| #   | Action                                                   | Priorite |
| --- | -------------------------------------------------------- | -------- |
| 1   | Connecter Meta Ads API pour import automatique spend     | Haute    |
| 2   | Connecter Google Ads API pour import automatique spend   | Haute    |
| 3   | Connecter TikTok Ads API pour import automatique spend   | Moyenne  |
| 4   | Connecter LinkedIn Ads API pour import automatique spend | Basse    |
| 5   | CronJob d'import quotidien ad_spend                      | Haute    |


---

## Conclusion

### Resume

Les donnees mock ont ete purgees de la table `ad_spend` (16 lignes supprimees).
L'API `/metrics/overview` fonctionne desormais en **mode strict** :

- Retourne `null` pour CAC et ROAS quand aucune depense reelle n'est disponible
- Indique explicitement la source des donnees (`no_data` vs `ad_spend_table`)
- Expose un bloc `data_quality` pour la transparence
- Les metriques reelles (new_customers, MRR) continuent de fonctionner normalement

### Verdict

**METRICS DATA SOURCE CLEAN — NO FAKE DATA**

- Mock data purgee : 16 lignes supprimees
- Mode strict : cac=null, roas=null quand spend=0
- Source indicator : `spend.source` explicite
- Data quality block : transparence totale
- Table ad_spend : vide, prete pour donnees reelles
- Non-regression : tous endpoints OK
- PROD : intacte
- Client : intact

