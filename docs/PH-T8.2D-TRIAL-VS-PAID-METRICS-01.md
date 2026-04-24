# PH-T8.2D-TRIAL-VS-PAID-METRICS-01 — Rapport Final

> Date : 2026-04-20
> Environnement : DEV uniquement
> Auteur : Agent Cursor

---

## 1. OBJECTIF

Corriger la couche metrics pour distinguer clairement les clients en essai (trial) des clients reellement payants (paid), afin que le pilotage acquisition ne se base plus sur une metrique optimiste.

---

## 2. AUDIT DES STATUTS (donnees reelles DEV)

### Source de verite : `billing_subscriptions.status`


| Source                                      | Champ/statut                  | Signification metier               | Compte comme paid ? |
| ------------------------------------------- | ----------------------------- | ---------------------------------- | ------------------- |
| `billing_subscriptions.status = 'trialing'` | Trial Stripe actif            | En essai, aucun paiement reel      | **NON**             |
| `billing_subscriptions.status = 'active'`   | Abonnement actif post-trial   | Client converti, CB debitee        | **OUI**             |
| `billing_subscriptions` absent              | Pas de subscription Stripe    | Jamais souscrit ou exempt          | **NON**             |
| `tenant_billing_exempt.exempt = true`       | Exempt facturation            | Compte interne                     | **NON**             |
| `tenant_metadata.is_trial`                  | Toujours `true` a la creation | **NON FIABLE** — jamais mis a jour | Ignore              |


### Constat critique

`tenant_metadata.is_trial` est **toujours `true`** pour tous les tenants. Ce champ n'est jamais mis a jour quand un trial se convertit en abonnement actif. **Seul `billing_subscriptions.status`** est fiable pour distinguer trial vs paid.

### Donnees reelles (20 avril 2026)


| Statut                | Nombre | Detail                               |
| --------------------- | ------ | ------------------------------------ |
| `active` (paid)       | **8**  | 1 PRO + 7 AUTOPILOT                  |
| `trialing`            | **8**  | 6 test + 1 compte-ecomlg + 1 keybuzz |
| Sans subscription     | **3**  | 1 exempt (ecomlg-001) + 2 legacy     |
| **Total non-deleted** | **19** |                                      |


### Subscriptions `active` (paid) — detail


| Tenant               | Plan      | Period start |
| -------------------- | --------- | ------------ |
| ecomlg-mmiyygfg      | PRO       | 2026-03-23   |
| ecomlg07-gmail-com   | AUTOPILOT | 2026-04-09   |
| switaa-sasu-mn9if5n2 | AUTOPILOT | 2026-04-10   |
| switaa-mn9ioy5j      | AUTOPILOT | 2026-04-10   |
| switaa-sasu-mnc1x4eq | AUTOPILOT | 2026-04-12   |
| w3lg-mnfwmtof        | AUTOPILOT | 2026-04-15   |
| olyara369-gmail-com  | AUTOPILOT | 2026-04-02   |
| compta-ecomlg-gmail  | AUTOPILOT | 2026-04-05   |


---

## 3. DEFINITION METRIQUES RETENUE


| Metrique                        | Definition                              | Formule                                            |
| ------------------------------- | --------------------------------------- | -------------------------------------------------- |
| `customers.signups`             | Tenants crees dans la periode           | `COUNT(*) FROM tenants WHERE created_at IN period` |
| `customers.trial`               | Signups avec subscription `trialing`    | LEFT JOIN billing_subscriptions, FILTER `trialing` |
| `customers.paid`                | Signups avec subscription `active`      | LEFT JOIN billing_subscriptions, FILTER `active`   |
| `customers.no_subscription`     | Signups sans subscription et non-exempt | LEFT JOIN, FILTER null + non-exempt                |
| `customers.billing_exempt`      | Signups exempts de facturation          | `tenant_billing_exempt.exempt = true`              |
| `conversion.trial_to_paid_rate` | Taux de conversion (snapshot all-time)  | `paid / (paid + trial)`                            |
| `cac.blended_eur`               | CAC blended (legacy)                    | `spend_eur / signups`                              |
| `cac.paid_eur`                  | CAC reel                                | `spend_eur / paid_customers`                       |
| Revenue (MRR)                   | Revenue des abonnes actifs uniquement   | Exclut `trialing`                                  |


### Regle : `paid_customers <= signups` — toujours

---

## 4. PAYLOAD AVANT / APRES

### Avant (PH-T8.2C)

```json
{
  "new_customers": 19,
  "cac": 26.88,
  "roas": 11.65,
  "revenue": { "mrr": 5952 }
}
```

Problemes :

- 19 "customers" = tous les signups (trials inclus)
- CAC 26.88 = optimiste (divise par 19 au lieu de 8 paid)
- Revenue 5952 = inclut les trialing (jamais paye)
- ROAS gonfle artificiellement

### Apres (PH-T8.2D)

```json
{
  "new_customers": 19,
  "customers": {
    "signups": 19,
    "trial": 8,
    "paid": 8,
    "no_subscription": 2,
    "billing_exempt": 1
  },
  "conversion": {
    "trial_to_paid_rate": 0.5,
    "snapshot": { "paid_all_time": 8, "trial_all_time": 8 }
  },
  "revenue": {
    "mrr": 3776,
    "currency": "EUR",
    "note": "MRR from active subscriptions only (excludes trialing)"
  },
  "cac": 26.88,
  "cac_detail": {
    "blended_eur": 26.88,
    "paid_eur": 63.84,
    "currency": "EUR",
    "note": "blended = spend/signups, paid = spend/paid_customers"
  },
  "roas": 7.39,
  "roas_detail": {
    "value": 7.39,
    "currency": "EUR",
    "note": "revenue (active MRR) / spend (EUR), trialing revenue excluded"
  }
}
```

---

## 5. PREUVES SQL ET COHERENCE

### Verification mathematique


| Metrique               | Calcul                                                   | Resultat       |
| ---------------------- | -------------------------------------------------------- | -------------- |
| Signups                | COUNT tenants created 2026-01-01..2026-04-20 non-deleted | **19**         |
| Trial                  | billing_subscriptions.status = 'trialing'                | **8**          |
| Paid                   | billing_subscriptions.status = 'active'                  | **8**          |
| No sub                 | tenants sans subscription, non-exempt                    | **2**          |
| Exempt                 | tenant_billing_exempt.exempt = true                      | **1**          |
| **19 = 8 + 8 + 2 + 1** |                                                          | **OK**         |
| Spend EUR              | 445.20 GBP x 1.1472                                      | **510.73 EUR** |
| CAC blended            | 510.73 / 19                                              | **26.88 EUR**  |
| CAC paid               | 510.73 / 8                                               | **63.84 EUR**  |
| Revenue (active only)  | 1x PRO (297) + 7x AUTOPILOT (3479)                       | **3776 EUR**   |
| ROAS                   | 3776 / 510.73                                            | **7.39**       |
| Conversion rate        | 8 / (8 + 8)                                              | **0.50**       |


### Comparaison CAC avant/apres


|             | Avant                        | Apres                                                      |
| ----------- | ---------------------------- | ---------------------------------------------------------- |
| CAC blended | 26.88 EUR (tous les signups) | 26.88 EUR (inchange)                                       |
| CAC paid    | **n'existait pas**           | **63.84 EUR** (realite)                                    |
| Ecart       |                              | **+137%** — le vrai cout d'acquisition est 2.4x plus eleve |


### Comparaison Revenue avant/apres


|       | Avant                      | Apres                                             |
| ----- | -------------------------- | ------------------------------------------------- |
| MRR   | 5952 EUR (trialing inclus) | 3776 EUR (active only)                            |
| Ecart |                            | **-36.5%** — 2176 EUR de "revenue fantome" retire |


### Comparaison ROAS avant/apres


|       | Avant                  | Apres                                                    |
| ----- | ---------------------- | -------------------------------------------------------- |
| ROAS  | 11.65 (revenue gonfle) | 7.39 (revenue reel)                                      |
| Ecart |                        | **-36.6%** — le ROAS reel est significativement plus bas |


---

## 6. VALIDATION

### CAS A — Periode avec trials et paid (default)

```
GET /metrics/overview
signups=19, trial=8, paid=8
cac_blended=26.88, cac_paid=63.84
paid_customers <= signups ✓
```

### CAS B — Periode recente (trials uniquement)

```
GET /metrics/overview?from=2026-04-17&to=2026-04-20
signups=6, trial=6, paid=0
cac_paid=null ✓ (pas de paid)
```

### CAS C — Periode sans spend

```
GET /metrics/overview?from=2020-01-01&to=2020-01-31
spend=0, cac=null, roas=null ✓
```

### Non-regression


| Endpoint                  | Status                  |
| ------------------------- | ----------------------- |
| `/health`                 | OK                      |
| `/messages/conversations` | OK                      |
| `/tenant-context/me`      | OK                      |
| `/dashboard/summary`      | OK                      |
| `/metrics/overview`       | OK (enrichi trial/paid) |


### PROD


|             | Valeur                                     |
| ----------- | ------------------------------------------ |
| Image PROD  | `v3.5.79-tiktok-api-replay-prod` (INTACTE) |
| Health PROD | OK                                         |


---

## 7. FICHIER MODIFIE


| Fichier                         | Commit     | Changement     |
| ------------------------------- | ---------- | -------------- |
| `src/modules/metrics/routes.ts` | `7950a829` | +96/-15 lignes |


**Aucun autre fichier modifie. Aucune table DB modifiee. Aucune donnee supprimee.**

---

## 8. IMAGES


| Etat      | Image                                                                       |
| --------- | --------------------------------------------------------------------------- |
| **AVANT** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.85-currency-normalized-dev`             |
| **APRES** | `ghcr.io/keybuzzio/keybuzz-api:v3.5.86-trial-vs-paid-metrics-dev`           |
| **PROD**  | `ghcr.io/keybuzzio/keybuzz-api:v3.5.79-tiktok-api-replay-prod` (NON TOUCHE) |


---

## 9. ROLLBACK

```bash
kubectl set image deploy/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.85-currency-normalized-dev \
  -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

**Aucune migration DB a annuler.**

---

## 10. GIT


| Info    | Valeur                                                    |
| ------- | --------------------------------------------------------- |
| Branche | `ph147.4/source-of-truth`                                 |
| Commit  | `7950a829`                                                |
| Message | `PH-T8.2D: trial vs paid metrics — honest CAC separation` |
| Parent  | `4f9e0daf` (PH-T8.2C)                                     |
| Push    | OK                                                        |


---

## 11. BACKWARD COMPATIBILITY


| Champ legacy        | Statut   | Action                               |
| ------------------- | -------- | ------------------------------------ |
| `new_customers`     | Conserve | Identique a `customers.signups`      |
| `cac`               | Conserve | Identique a `cac_detail.blended_eur` |
| `roas`              | Conserve | Identique a `roas_detail.value`      |
| `customers_by_plan` | Conserve | Inchange                             |
| `spend`             | Conserve | Inchange (PH-T8.2C)                  |
| `fx`                | Conserve | Inchange (PH-T8.2C)                  |


Les anciens consommateurs de l'API ne sont pas casses. Les nouveaux champs enrichissent la reponse.

---

## 12. DECISIONS TECHNIQUES

### Pourquoi `billing_subscriptions.status` et pas `tenant_metadata.is_trial` ?

`tenant_metadata.is_trial` est **toujours `true`** pour tous les tenants. Ce champ est ecrit a la creation et jamais mis a jour. Il n'a aucune valeur pour distinguer trial vs paid. Seul `billing_subscriptions.status` reflete l'etat Stripe reel.

### Pourquoi exclure trialing du MRR ?

Un abonnement en `trialing` n'a genere aucun paiement. Inclure ces montants dans le MRR donne une vision faussee du chiffre d'affaires recurrent. Le MRR doit refleter uniquement les paiements recurrents reels.

### Pourquoi un taux de conversion all-time ?

Le taux de conversion (trial_to_paid_rate) est un snapshot global car un trial peut se convertir en paid a tout moment pendant la periode d'essai de 14 jours. Filtrer par periode de creation du tenant donnerait un taux incomplet pour les signups recents.

---

## 13. IMPACT BUSINESS


| Insight                                   | Valeur                                                             |
| ----------------------------------------- | ------------------------------------------------------------------ |
| Le vrai CAC est **63.84 EUR** (pas 26.88) | Le cout d'acquisition est 2.4x plus eleve que la lecture optimiste |
| Le vrai MRR est **3776 EUR** (pas 5952)   | 36.5% de "revenue fantome" retire                                  |
| Le vrai ROAS est **7.39** (pas 11.65)     | La rentabilite publicitaire est 36.6% plus basse                   |
| Taux de conversion trial->paid : **50%**  | 8 payes sur 16 avec subscription                                   |


---

## 14. PROCHAINES ETAPES


| #   | Action                                                          | Priorite |
| --- | --------------------------------------------------------------- | -------- |
| 1   | CronJob import Meta spend quotidien                             | Haute    |
| 2   | Fixer `tenant_metadata.is_trial` (update sur conversion Stripe) | Moyenne  |
| 3   | Metrique LTV (Lifetime Value) par plan                          | Moyenne  |
| 4   | Cohorte analysis (conversion par semaine d'inscription)         | Basse    |
| 5   | Dashboard UI avec separation trial/paid                         | Basse    |


---

## 15. VERDICT

**TRIAL VS PAID METRICS OPERATIONAL — CAC BUSINESS SAFER — DEV ONLY — ROLLBACK READY**

- Le CAC reel (paid) est visible et distingue du CAC blended
- Le MRR exclut correctement les trials
- Le ROAS est calcule sur du revenue reel
- Le taux de conversion trial->paid est expose
- Les metriques legacy sont preservees (backward compat)
- PROD est intacte
- Le rollback est immediat et sans risque

