# PH-T8.2C-CURRENCY-NORMALIZATION-01 — Rapport Final

> Date : 2026-04-20
> Environnement : DEV uniquement
> Auteur : Agent Cursor

---

## 1. OBJECTIF

Normaliser toutes les metriques business (CAC, ROAS, spend) dans une devise unique **EUR**, en convertissant dynamiquement les depenses publicitaires stockees en devise etrangere (GBP pour Meta Ads).

---

## 2. CONTEXTE

### Avant (PH-T8.2B)


| Metrique      | Devise | Probleme                   |
| ------------- | ------ | -------------------------- |
| Revenue (MRR) | EUR    | OK                         |
| Meta Ad Spend | GBP    | Devise differente          |
| CAC           | GBP    | Incoherent (GBP/customers) |
| ROAS          | mixte  | Incoherent (EUR/GBP)       |


Le CAC etait calcule en GBP et le ROAS melangeait EUR (revenue) et GBP (spend), rendant les metriques non fiables.

---

## 3. STRATEGIE IMPLEMENTEE


| Decision             | Choix                                     |
| -------------------- | ----------------------------------------- |
| Devise de reference  | **EUR**                                   |
| Moment de conversion | Au calcul des metriques (pas au stockage) |
| Source de taux       | **ECB** via Frankfurter API               |
| Donnees brutes       | **Preservees intactes** dans `ad_spend`   |
| Taux hardcode        | **NON** — taux dynamique ECB              |


### Pourquoi cette approche ?

- Les donnees brutes restent dans leur devise originale (auditabilite)
- La conversion se fait au moment du calcul (precision temporelle)
- Le taux ECB est la reference officielle europeenne
- Un cache de 6h evite les appels excessifs

---

## 4. IMPLEMENTATION

### 4.1 Source de taux de change

- **API** : `https://api.frankfurter.app/latest?from=GBP&to=EUR`
- **Source sous-jacente** : Banque Centrale Europeenne (ECB)
- **Cache** : 6 heures en memoire (variable `fxCache`)
- **Fallback** : cache expire si API indisponible, puis `rate: 0` = metriques derivees `null`
- **Aucune valeur inventee** : si FX indisponible et pas de cache, rate = 0

### 4.2 Mapping devises par canal

```typescript
const CHANNEL_CURRENCIES: Record<string, string> = {
  meta: 'GBP',
  google: 'EUR',
  tiktok: 'EUR',
  linkedin: 'EUR',
};
```

Extensible : ajouter un canal = ajouter une entree.

### 4.3 Fonction de conversion

```typescript
function convertToEur(amount: number, fromCurrency: string, fxRate: number): number {
  if (fromCurrency === 'EUR') return amount;
  if (fromCurrency === 'GBP' && fxRate > 0) return amount * fxRate;
  return amount;
}
```

### 4.4 Structure de reponse `/metrics/overview`

**Avant (PH-T8.2B)** :

```json
{
  "spend": { "total": 445.20, "currency": "GBP" },
  "cac": 23.43,
  "roas": 13.37
}
```

**Apres (PH-T8.2C)** :

```json
{
  "spend": {
    "total_eur": 510.73,
    "by_channel": [{
      "channel": "meta",
      "spend_raw": 445.20,
      "currency_raw": "GBP",
      "spend_eur": 510.73,
      "impressions": 45374,
      "clicks": 892
    }],
    "currency": "EUR",
    "source": "ad_spend_table"
  },
  "fx": {
    "gbp_eur": 1.1472,
    "source": "ecb",
    "date": "2026-04-17"
  },
  "cac": 26.88,
  "roas": 11.65,
  "data_quality": {
    "spend_available": true,
    "customers_available": true,
    "revenue_available": true,
    "fx_available": true
  }
}
```

### 4.5 Champs ajoutes


| Champ                             | Type        | Description                                           |
| --------------------------------- | ----------- | ----------------------------------------------------- |
| `spend.total_eur`                 | number      | Total spend converti en EUR                           |
| `spend.by_channel[].spend_raw`    | number      | Montant brut (devise originale)                       |
| `spend.by_channel[].currency_raw` | string      | Devise originale du canal                             |
| `spend.by_channel[].spend_eur`    | number      | Montant converti en EUR                               |
| `fx`                              | object/null | Bloc taux de change                                   |
| `fx.gbp_eur`                      | number      | Taux GBP→EUR                                          |
| `fx.source`                       | string      | `ecb`, `ecb_cached`, `ecb_stale_cache`, `unavailable` |
| `fx.date`                         | string      | Date du taux ECB                                      |
| `data_quality.fx_available`       | boolean     | Taux FX disponible                                    |


---

## 5. VALIDATION

### 5.1 CAS A — Avec spend (periode avec donnees Meta)

```
GET /metrics/overview
```


| Metrique    | Avant (PH-T8.2B) | Apres (PH-T8.2C) |
| ----------- | ---------------- | ---------------- |
| spend total | 445.20 GBP       | 510.73 EUR       |
| CAC         | 23.43 GBP        | 26.88 EUR        |
| ROAS        | 13.37 (mixte)    | 11.65 (EUR/EUR)  |


**Verification mathematique** :

- 445.20 GBP x 1.1472 = **510.73 EUR** OK
- 510.73 / 19 customers = **26.88** OK
- 5952 / 510.73 = **11.65** OK

### 5.2 CAS B — Sans spend (periode vide)

```
GET /metrics/overview?from=2020-01-01&to=2020-01-31
```


| Champ                        | Valeur |
| ---------------------------- | ------ |
| spend.total_eur              | 0      |
| spend.by_channel             | []     |
| cac                          | null   |
| roas                         | null   |
| data_quality.spend_available | false  |


### 5.3 Cache FX

- 1er appel : `source: "ecb"` (appel API)
- 2e appel (<6h) : `source: "ecb_cached"` (cache memoire)

### 5.4 Non-regression


| Endpoint                  | Status             |
| ------------------------- | ------------------ |
| `/health`                 | OK                 |
| `/messages/conversations` | OK                 |
| `/tenant-context/me`      | OK                 |
| `/dashboard/summary`      | OK                 |
| `/metrics/overview`       | OK (normalise EUR) |


---

## 6. FICHIER MODIFIE


| Fichier                         | Commit     | Changement     |
| ------------------------------- | ---------- | -------------- |
| `src/modules/metrics/routes.ts` | `4f9e0daf` | +83/-29 lignes |


**Aucun autre fichier modifie. Aucune table DB modifiee. Aucune donnee supprimee.**

---

## 7. IMAGES


| Etat      | Image                                                           |
| --------- | --------------------------------------------------------------- |
| **AVANT** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.84-meta-real-spend-dev`     |
| **APRES** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.85-currency-normalized-dev` |


---

## 8. ROLLBACK

```bash
# Rollback immediat
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.84-meta-real-spend-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

**Aucune migration DB a annuler** — la table `ad_spend` n'a pas ete modifiee.

---

## 9. GIT


| Info    | Valeur                                                  |
| ------- | ------------------------------------------------------- |
| Branche | `ph147.4/source-of-truth`                               |
| Commit  | `4f9e0daf`                                              |
| Message | `PH-T8.2C: currency normalization — all metrics in EUR` |
| Parent  | `f971b78a` (PH-T8.2B)                                   |
| Push    | OK                                                      |


---

## 10. ARCHITECTURE FX — DECISIONS TECHNIQUES

### Pourquoi Frankfurter/ECB ?


| Critere           | Frankfurter | exchangerate.host | Fixer.io        |
| ----------------- | ----------- | ----------------- | --------------- |
| Gratuit           | Oui         | Non (freemium)    | Non (payant)    |
| Source officielle | ECB         | Multiple          | Multiple        |
| Fiabilite         | Haute       | Moyenne           | Haute           |
| Rate limit        | Liberal     | 100/mois (free)   | 100/mois (free) |
| HTTPS             | Oui         | Payant            | Payant          |


### Strategie de cache

```
Appel API -> cache 6h en memoire -> re-fetch apres expiration
                                  -> fallback cache expire si API down
                                  -> rate=0 si aucun cache (metriques null)
```

### Extensibilite multi-devises futures

Pour ajouter USD (ex: Google Ads US) :

1. Ajouter `google_us: 'USD'` dans `CHANNEL_CURRENCIES`
2. Etendre `getGbpToEurRate` en `getFxRates` (multi-devises)
3. Adapter `convertToEur` pour USD→EUR

---

## 11. PROCHAINES ETAPES


| #   | Action                                  | Priorite |
| --- | --------------------------------------- | -------- |
| 1   | CronJob import Meta spend quotidien     | Haute    |
| 2   | Google Ads integration (canal `google`) | Moyenne  |
| 3   | Taux FX historiques par jour de depense | Moyenne  |
| 4   | Dashboard UI avec metriques normalisees | Basse    |
| 5   | Alertes si FX indisponible >24h         | Basse    |


---

## 12. VERDICT

**CURRENCY NORMALIZED — METRICS COHERENT — SAFE BUILD**

- Toutes les metriques sont en EUR
- Les donnees brutes sont preservees
- Le taux ECB est dynamique et cache
- Le rollback est immediat et sans risque
- Aucune donnee n'a ete supprimee ou modifiee
- Non-regression validee sur tous les endpoints critiques

