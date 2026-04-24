# PH-T8.2E — PROD Promotion: Metrics Pipeline Complete

> Date : 2026-04-20
> Environnement : **PROD uniquement**
> Branche source : `ph147.4/source-of-truth`
> Commit source : `7950a829` (PH-T8.2D: trial vs paid metrics)
> Commit infra : `e77b7cb` (PH-T8.2E: PROD promotion metrics pipeline)

---

## 1. RESUME

Promotion en PROD de la chaine complete de metriques business :

- **PH-T8.2B** : Import reel Meta Ads (plus de fake data)
- **PH-T8.2C** : Normalisation EUR via ECB (taux Frankfurter API)
- **PH-T8.2D** : Distinction trial/paid, CAC granulaire, MRR strict

---

## 2. PREFLIGHT


| Element              | Valeur                              |
| -------------------- | ----------------------------------- |
| Branche              | `ph147.4/source-of-truth`           |
| Repo                 | Clean (zero unstaged)               |
| Commit source        | `7950a829`                          |
| Image PROD avant     | `v3.5.79-tiktok-api-replay-prod`    |
| Image DEV validee    | `v3.5.86-trial-vs-paid-metrics-dev` |
| PROD avait T8.2B/C/D | **Non** — promotion necessaire      |


---

## 3. CODE SOURCE VERIFIE


| Feature                 | Lignes trouvees                                                                                          |
| ----------------------- | -------------------------------------------------------------------------------------------------------- |
| T8.2B Meta import       | `fetchMetaInsights` (2), `META_AD_ACCOUNT_ID` (4), `import/meta` (1)                                     |
| T8.2C EUR normalization | `getGbpToEurRate` (3), `convertToEur` (3), `frankfurter` (1), `spend_eur` (4)                            |
| T8.2D trial/paid        | `trialCustomers` (2), `paidCustomers` (5), `trial_to_paid_rate` (1), `cac_detail` (1), `roas_detail` (1) |
| Backward compat         | `new_customers` (L205), `cac` (L245), `roas` (L253)                                                      |


---

## 4. IMAGE PROD


| Element         | Valeur                                                                    |
| --------------- | ------------------------------------------------------------------------- |
| Tag             | `ghcr.io/keybuzzio/keybuzz-api:v3.5.86-trial-vs-paid-metrics-prod`        |
| Digest local    | `sha256:7465efc66ebf49524c3f31b652f9fc7777fbea58509b765040d83af12db74e0d` |
| Digest registry | `sha256:01ff7b1517bf569a264f8eb11924db1b5658df2fe3ef5d7e2d5af9db4726b110` |
| Build           | `docker build --no-cache` depuis repo clean `ph147.4/source-of-truth`     |


---

## 5. CONFIG PROD

### 5.1. Table `ad_spend` creee en PROD

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
```

### 5.2. Secret K8s `keybuzz-meta-ads` cree

Namespace : `keybuzz-api-prod`
Cles : `META_AD_ACCOUNT_ID`, `META_ACCESS_TOKEN`
Valeurs copiees depuis DEV (meme compte Meta, memes credentials)

### 5.3. Env vars ajoutees au manifest PROD


| Variable                           | Source                           | Raison                  |
| ---------------------------------- | -------------------------------- | ----------------------- |
| `META_AD_ACCOUNT_ID`               | `secretKeyRef: keybuzz-meta-ads` | Import Meta reel        |
| `META_ACCESS_TOKEN`                | `secretKeyRef: keybuzz-meta-ads` | Import Meta reel        |
| `STAKATER_VAULT_ROOT_TOKEN_SECRET` | inline                           | Sync manifest avec live |
| `CONVERSION_WEBHOOK_ENABLED`       | inline                           | Sync manifest avec live |
| `CONVERSION_WEBHOOK_URL`           | inline                           | Sync manifest avec live |
| `GA4_MP_API_SECRET`                | inline                           | Sync manifest avec live |
| `CONVERSION_WEBHOOK_SECRET`        | inline                           | Sync manifest avec live |
| `GA4_MEASUREMENT_ID`               | inline                           | Sync manifest avec live |


### 5.4. Corrections manifest

- Bug fix : `KEYBUZZ_INTERNAL_PROXY_TOKEN` avait deux `value:` (corrige)
- Historique image : ajout des tags intermediaires PREVIOUS

---

## 6. DEPLOIEMENT


| Etape                       | Resultat                                           |
| --------------------------- | -------------------------------------------------- |
| `git pull` infra bastion    | OK (fast-forward)                                  |
| `kubectl apply -f` manifest | `deployment.apps/keybuzz-api configured`           |
| Rollout                     | `deployment "keybuzz-api" successfully rolled out` |
| Pod                         | `keybuzz-api-dc75cb7d-z87pd` Running, 0 restarts   |
| Image deployee              | `v3.5.86-trial-vs-paid-metrics-prod`               |


---

## 7. VALIDATION PROD

### 7.1. Import Meta Ads

```
Imported: 16 days
spend_raw: 445.20 GBP
spend_eur: 511.45 EUR
```

Donnees reelles du compte Meta `act_1485150039...` (periode 01/03/2026 — 20/04/2026).

### 7.2. Payload PROD `/metrics/overview`

```json
{
  "period": { "from": "2026-01-01", "to": "2026-04-20" },
  "new_customers": 13,
  "customers": {
    "signups": 13,
    "trial": 6,
    "paid": 2,
    "no_subscription": 3,
    "billing_exempt": 1
  },
  "conversion": {
    "trial_to_paid_rate": 0.25,
    "snapshot": { "paid_all_time": 2, "trial_all_time": 6 }
  },
  "revenue": {
    "mrr": 994,
    "currency": "EUR",
    "note": "MRR from active subscriptions only (excludes trialing)"
  },
  "spend": {
    "total_eur": 511.45,
    "by_channel": [{ "channel": "meta", "spend_raw": 445.20, "currency_raw": "GBP", "spend_eur": 511.45, "impressions": 45374, "clicks": 892 }],
    "currency": "EUR",
    "source": "ad_spend_table"
  },
  "fx": { "gbp_eur": 1.1488, "source": "ecb_cached", "date": "2026-04-20" },
  "cac": 39.34,
  "cac_detail": {
    "blended_eur": 39.34,
    "paid_eur": 255.73,
    "currency": "EUR"
  },
  "roas": 1.94,
  "roas_detail": { "value": 1.94, "currency": "EUR" },
  "data_quality": {
    "spend_available": true,
    "customers_available": true,
    "paid_customers_available": true,
    "revenue_available": true,
    "fx_available": true
  }
}
```

### 7.3. Coherence metriques


| Metrique    | Formule         | Resultat | Verifie                               |
| ----------- | --------------- | -------- | ------------------------------------- |
| CAC blended | 511.45 / 13     | 39.34    | 511.45/13 = 39.342                    |
| CAC paid    | 511.45 / 2      | 255.73   | 511.45/2 = 255.725                    |
| ROAS        | 994 / 511.45    | 1.94     | 994/511.45 = 1.943                    |
| Conversion  | 2 / (2+6)       | 0.25     | 2/8 = 0.25                            |
| FX          | ECB Frankfurter | 1.1488   | Taux reel du 2026-04-20               |
| Spend EUR   | 445.20 x 1.1488 | 511.45   | 445.20 x 1.1488 = 511.47 (arrondi DB) |


### 7.4. Preuves

- **Revenue = active subs only** : MRR 994 EUR exclut les 6 trialing
- **Spend = reel Meta** : 445.20 GBP importes via Meta Marketing API
- **Devise = EUR** : normalisation via ECB (Frankfurter API), taux 1.1488
- **Pas de mock** : `data_quality.spend_available: true`, `source: "ad_spend_table"`

### 7.5. Non-regression


| Endpoint                      | Resultat                     |
| ----------------------------- | ---------------------------- |
| `GET /health`                 | `{"status":"ok"}`            |
| `GET /messages/conversations` | 1 row OK                     |
| `GET /tenant-context/me`      | `ludo.gonthier@gmail.com` OK |
| `GET /dashboard/summary`      | conversations, sla OK        |
| DEV health                    | OK (inchange)                |
| Impact Stripe                 | Aucun (endpoint read-only)   |
| Impact tracking               | Aucun                        |
| Impact client SaaS            | Aucun                        |


---

## 8. ROLLBACK PROD

### Procedure

```bash
# 1. Modifier le manifest
vim /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
# Changer l'image vers :
# ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-prod

# 2. Appliquer
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```


| Element                   | Valeur                                             |
| ------------------------- | -------------------------------------------------- |
| Image avant               | `v3.5.79-tiktok-api-replay-prod`                   |
| Image apres               | `v3.5.86-trial-vs-paid-metrics-prod`               |
| Manifest a remettre       | Revenir a l'image `v3.5.79-tiktok-api-replay-prod` |
| Table `ad_spend`          | Reste en place (inoffensive, pas de FK)            |
| Secret `keybuzz-meta-ads` | Reste en place (pas utilise par l'ancien code)     |


---

## 9. IMAGES


| Service | PROD                                           |
| ------- | ---------------------------------------------- |
| API     | `v3.5.86-trial-vs-paid-metrics-prod`           |
| DEV     | `v3.5.86-trial-vs-paid-metrics-dev` (inchange) |


---

## 10. DECISIONS TECHNIQUES


| Decision                           | Justification                                                                 |
| ---------------------------------- | ----------------------------------------------------------------------------- |
| Secret K8s pour Meta (pas inline)  | Credentials sensibles hors git                                                |
| Sync manifest avec live PROD       | 6 env vars ajoutees (tracking, GA4) pour eviter regression au `kubectl apply` |
| Fix `KEYBUZZ_INTERNAL_PROXY_TOKEN` | Bug yaml pre-existant (2 values) — corrige en passant                         |
| Meme commit source DEV/PROD        | `7950a829` — zero divergence                                                  |


---

## 11. ETAT DB PROD


| Table                 | Contenu                            |
| --------------------- | ---------------------------------- |
| billing_subscriptions | 2 active, 6 trialing, 1 canceled   |
| tenants (non-deleted) | 13                                 |
| ad_spend              | 16 rows (meta, 01/03 — 16/04/2026) |


---

## 12. VERDICT

**METRICS PROD ALIGNED — REAL SPEND + EUR + TRIAL/PAID OPERATIONAL — ADMIN READY**

---

## 13. PROCHAINES ETAPES


| #   | Action                                                     | Priorite |
| --- | ---------------------------------------------------------- | -------- |
| 1   | CronJob import Meta spend quotidien                        | Haute    |
| 2   | Admin V2 : dashboard metrics UI                            | Haute    |
| 3   | Historique spend complet (backfill depuis debut campagnes) | Moyenne  |
| 4   | Alertes budget (seuil spend/jour)                          | Basse    |


