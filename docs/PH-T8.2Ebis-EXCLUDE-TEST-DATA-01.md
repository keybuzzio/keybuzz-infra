# PH-T8.2Ebis — Exclude Test Data from Business Metrics

> Date : 2026-04-20
> Environnement : **DEV + PROD**
> Branche source : `ph147.4/source-of-truth`
> Commit source : `e8be2a74` (PH-T8.2Ebis: exclude test accounts from business metrics)
> Commit infra : `4250c73` (PH-T8.2Ebis: exclude test data from metrics - v3.5.87 DEV+PROD)

---

## 1. RESUME

Exclusion des comptes test/internes des metriques business (`/metrics/overview`).
Methode non-destructive utilisant la table existante `tenant_billing_exempt`.

**Impact business** : avant cette phase, les metriques incluaient 18 comptes internes en DEV et 12 en PROD, faussant CAC, ROAS, MRR et conversion.

---

## 2. AUDIT TENANTS

### DEV (19 tenants non-deleted)


| Tenant                      | Owner                                                                           | Verdict               |
| --------------------------- | ------------------------------------------------------------------------------- | --------------------- |
| `ecomlg-001`                | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (internal_admin) |
| `tenant-1772234265142`      | [ludovic@ecomlg.fr](mailto:ludovic@ecomlg.fr)                                   | TEST (ecomlg domain)  |
| `ecomlg-mmiyygfg`           | [contact@ecomlg.fr](mailto:contact@ecomlg.fr)                                   | TEST (ecomlg domain)  |
| `test-amz-truth02-*`        | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (test-prefix)    |
| `ecomlg07-gmail-com-*`      | [ecomlg07@gmail.com](mailto:ecomlg07@gmail.com)                                 | TEST (ecomlg)         |
| `switaa-sasu-mn9if5n2`      | [contact@switaa.com](mailto:contact@switaa.com)                                 | TEST (switaa domain)  |
| `switaa-mn9ioy5j`           | [contact+switaa@switaa.com](mailto:contact+switaa@switaa.com)                   | TEST (switaa domain)  |
| `switaa-sasu-mnc1x4eq`      | [switaa26@gmail.com](mailto:switaa26@gmail.com)                                 | TEST (switaa)         |
| `w3lg-mnfwmtof`             | [w3lgcom@gmail.com](mailto:w3lgcom@gmail.com)                                   | TEST (w3lg/ecomlg)    |
| `**olyara369-gmail-com-*`** | **[olyara369@gmail.com](mailto:olyara369@gmail.com)**                           | **REEL**              |
| `compta-ecomlg-gmail--*`    | [compta.ecomlg@gmail.com](mailto:compta.ecomlg@gmail.com)                       | TEST (ecomlg)         |
| `keybuzz-mnqnjna8`          | [keybuzz.pro@gmail.com](mailto:keybuzz.pro@gmail.com)                           | TEST (keybuzz)        |
| `compte-ecomlg-mnsv62np`    | [compta.ecomlg+test@gmail.com](mailto:compta.ecomlg+test@gmail.com)             | TEST (ecomlg+test)    |
| `test-conversion-t5-5-*`    | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (tracking test)  |
| `test-ga4-mp-t5-6-*`        | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (tracking test)  |
| `test-ph-t5-6-1-sas-*`      | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (tracking test)  |
| `test-e2e-ph563-*`          | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                       | TEST (tracking test)  |
| `tiktok-test-e2e-sas-*`     | [ludo.gonthier+tiktoktest@gmail.com](mailto:ludo.gonthier+tiktoktest@gmail.com) | TEST (tracking test)  |
| `tiktok-fix-test-sas-*`     | [ludo.gonthier+ph-t7224@gmail.com](mailto:ludo.gonthier+ph-t7224@gmail.com)     | TEST (tracking test)  |


**DEV : 18 test/internes, 1 reel (olyara369)**

### PROD (13 tenants non-deleted)


| Tenant                     | Owner                                                                                 | Verdict               |
| -------------------------- | ------------------------------------------------------------------------------------- | --------------------- |
| `ecomlg-001`               | [ludo.gonthier@gmail.com](mailto:ludo.gonthier@gmail.com)                             | TEST (internal_admin) |
| `ecomlg-mn3rdmf6`          | [keybuzz.pro@gmail.com](mailto:keybuzz.pro@gmail.com)                                 | TEST (keybuzz)        |
| `ecomlg-mn3roi1v`          | [ecomlgswitaa@gmail.com](mailto:ecomlgswitaa@gmail.com)                               | TEST (ecomlg/switaa)  |
| `**romruais-gmail-com-*`** | **[romruais@gmail.com](mailto:romruais@gmail.com)**                                   | **REEL** (canceled)   |
| `switaa-sasu-mn9c3eza`     | [contact@switaa.com](mailto:contact@switaa.com)                                       | TEST (switaa)         |
| `switaa-sasu-mnc1ouqu`     | [switaa26@gmail.com](mailto:switaa26@gmail.com)                                       | TEST (switaa)         |
| `compta-ecomlg-gmail--`*   | [compta.ecomlg@gmail.com](mailto:compta.ecomlg@gmail.com)                             | TEST (ecomlg)         |
| `test-mnyycio7`            | [antoine.seremet@gmail.com](mailto:antoine.seremet@gmail.com)                         | TEST (test-prefix)    |
| `ecomlg-mo45atga`          | [ecomlg26@gmail.com](mailto:ecomlg26@gmail.com)                                       | TEST (ecomlg)         |
| `ecomlg-mo4h93e7`          | [ecomlg26+test@gmail.com](mailto:ecomlg26+test@gmail.com)                             | TEST (ecomlg+test)    |
| `tiktok-prod-test-*`       | [ludo.gonthier+testtiktokok@gmail.com](mailto:ludo.gonthier+testtiktokok@gmail.com)   | TEST (tracking)       |
| `tiktok-prod-v2-*`         | [ludo.gonthier+testtiktokok2@gmail.com](mailto:ludo.gonthier+testtiktokok2@gmail.com) | TEST (tracking)       |
| `ludo-gonthier-ga4mpf-*`   | [ludo.gonthier+ga4mpfinal@gmail.com](mailto:ludo.gonthier+ga4mpfinal@gmail.com)       | TEST (tracking)       |


**PROD : 12 test/internes, 1 reel (romruais, subscription canceled)**

---

## 3. STRATEGIE


| Critere             | Decision                                |
| ------------------- | --------------------------------------- |
| Methode de marquage | Table existante `tenant_billing_exempt` |
| Raison              | `reason = 'test_account'`               |
| Non-destructif      | INSERT avec ON CONFLICT DO NOTHING      |
| Reversible          | DELETE pour re-inclure un tenant        |
| Schema change       | Aucun                                   |
| Donnees supprimees  | Aucune                                  |


### Regles d'identification


| Regle                                                             | Exemples                                                                                                   |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `tenant_billing_exempt.exempt = true` (existant)                  | ecomlg-001                                                                                                 |
| Tenant ID commence par `test-`                                    | test-mnyycio7                                                                                              |
| Tenant name contient "test" ou "essai"                            | "Test AMZ Truth 02", "Essai"                                                                               |
| Owner email @ecomlg.*                                             | [contact@ecomlg.fr](mailto:contact@ecomlg.fr), [ludovic@ecomlg.fr](mailto:ludovic@ecomlg.fr)               |
| Owner email @switaa.*                                             | [contact@switaa.com](mailto:contact@switaa.com)                                                            |
| Owner email ecomlg*@gmail.com                                     | [ecomlg07@gmail.com](mailto:ecomlg07@gmail.com), [compta.ecomlg@gmail.com](mailto:compta.ecomlg@gmail.com) |
| Owner email [keybuzz.pro@gmail.com](mailto:keybuzz.pro@gmail.com) | keybuzz interne                                                                                            |
| Owner email ludo.gonthier+*@gmail.com                             | aliases test tracking                                                                                      |
| Owner email switaa*@gmail.com                                     | [switaa26@gmail.com](mailto:switaa26@gmail.com)                                                            |


---

## 4. MODIFICATIONS CODE

### Fichier modifie

`src/modules/metrics/routes.ts` — 4 requetes SQL modifiees.

### 4.1. customerBreakdown — exclure test des compteurs

**Avant :**

```sql
COUNT(*) as total_signups,
COUNT(*) FILTER (WHERE bs.status = 'trialing') as trial,
COUNT(*) FILTER (WHERE bs.status = 'active') as paid,
COUNT(*) FILTER (WHERE bs.tenant_id IS NULL AND COALESCE(tbe.exempt, false) = false) as no_subscription,
COUNT(*) FILTER (WHERE tbe.exempt = true) as billing_exempt
```

**Apres :**

```sql
COUNT(*) FILTER (WHERE tbe.exempt IS NOT TRUE) as real_signups,
COUNT(*) FILTER (WHERE bs.status = 'trialing' AND tbe.exempt IS NOT TRUE) as trial,
COUNT(*) FILTER (WHERE bs.status = 'active' AND tbe.exempt IS NOT TRUE) as paid,
COUNT(*) FILTER (WHERE bs.tenant_id IS NULL AND tbe.exempt IS NOT TRUE) as no_subscription,
COUNT(*) FILTER (WHERE tbe.exempt = true) as test_excluded
```

### 4.2. conversionSnapshot — exclure test subs

**Avant :** `FROM billing_subscriptions` (sans filtre)

**Apres :**

```sql
FROM billing_subscriptions bs
WHERE NOT EXISTS (
  SELECT 1 FROM tenant_billing_exempt tbe
  WHERE tbe.tenant_id = bs.tenant_id AND tbe.exempt = true
)
```

### 4.3. revenueResult — exclure test subs du MRR

**Avant :** `WHERE bs.status = 'active'` (sans filtre test)

**Apres :**

```sql
WHERE bs.status = 'active'
AND NOT EXISTS (
  SELECT 1 FROM tenant_billing_exempt tbe
  WHERE tbe.tenant_id = bs.tenant_id AND tbe.exempt = true
)
```

### 4.4. customersByPlan — exclure test

**Avant :** Pas de filtre test

**Apres :** `AND tbe.exempt IS NOT TRUE` ajoute au WHERE

### 4.5. data_quality enrichi

```json
{
  "test_data_excluded": true,
  "test_accounts_count": 12
}
```

### 4.6. Backward compatibility


| Champ                      | Avant                 | Apres                                                          |
| -------------------------- | --------------------- | -------------------------------------------------------------- |
| `customers.billing_exempt` | Present               | **Supprime** (remplace par `data_quality.test_accounts_count`) |
| `new_customers`            | Total tous tenants    | Signups reels uniquement                                       |
| `cac`                      | Incluait test         | Reels uniquement                                               |
| `roas`                     | Incluait test revenue | Reels uniquement                                               |
| `customers.signups`        | Incluait test         | Reels uniquement                                               |


**Note** : le champ `billing_exempt` est retire de `customers` car il polluait les compteurs. L'information est maintenant dans `data_quality.test_accounts_count`.

---

## 5. IMAGES


| Service  | Tag                              | Digest                                |
| -------- | -------------------------------- | ------------------------------------- |
| API DEV  | `v3.5.87-exclude-test-data-dev`  | `sha256:8073500782de...`              |
| API PROD | `v3.5.87-exclude-test-data-prod` | `sha256:8073500782de...` (meme image) |


---

## 6. VALIDATION

### 6.1. DEV

```json
{
  "new_customers": 1,
  "customers": { "signups": 1, "trial": 0, "paid": 1, "no_subscription": 0 },
  "conversion": { "trial_to_paid_rate": 1, "snapshot": { "paid_all_time": 1, "trial_all_time": 0 } },
  "revenue": { "mrr": 497 },
  "cac": 511.45,
  "cac_detail": { "blended_eur": 511.45, "paid_eur": 511.45 },
  "roas": 0.97,
  "data_quality": { "test_data_excluded": true, "test_accounts_count": 18 }
}
```

**Interpretation DEV** : 1 client reel (olyara369, AUTOPILOT active, MRR 497 EUR).

### 6.2. PROD

```json
{
  "new_customers": 1,
  "customers": { "signups": 1, "trial": 0, "paid": 0, "no_subscription": 0 },
  "conversion": { "trial_to_paid_rate": null },
  "revenue": { "mrr": 0 },
  "cac": 511.45,
  "cac_detail": { "blended_eur": 511.45, "paid_eur": null },
  "roas": null,
  "data_quality": { "test_data_excluded": true, "test_accounts_count": 12 }
}
```

**Interpretation PROD** : 1 client reel (romruais, subscription canceled, MRR 0). CAC paid = null (aucun client payant reel). C'est la verite des donnees.

### 6.3. Non-regression


| Endpoint                      | DEV              | PROD             |
| ----------------------------- | ---------------- | ---------------- |
| `GET /health`                 | OK               | OK               |
| `GET /messages/conversations` | 1 row OK         | 1 row OK         |
| `GET /tenant-context/me`      | ludo.gonthier OK | ludo.gonthier OK |
| `GET /dashboard/summary`      | OK               | OK               |
| Tracking                      | Aucun impact     | Aucun impact     |
| Stripe                        | Aucun impact     | Aucun impact     |
| Client SaaS                   | Aucun impact     | Aucun impact     |


---

## 7. ROLLBACK

### 7.1. Code (images)


| Env  | Rollback vers                        |
| ---- | ------------------------------------ |
| DEV  | `v3.5.86-trial-vs-paid-metrics-dev`  |
| PROD | `v3.5.86-trial-vs-paid-metrics-prod` |


### 7.2. Donnees (re-inclure un tenant)

```sql
DELETE FROM tenant_billing_exempt WHERE tenant_id = '<id>' AND reason = 'test_account';
```

### 7.3. Re-inclure TOUS les comptes test

```sql
DELETE FROM tenant_billing_exempt WHERE reason = 'test_account';
```

Le code revient automatiquement a inclure tous les tenants si `tenant_billing_exempt` est vide.

---

## 8. DECISION TECHNIQUE


| Decision                                    | Justification                                      |
| ------------------------------------------- | -------------------------------------------------- |
| Utiliser `tenant_billing_exempt` (existant) | Zero schema change, table+colonnes existantes      |
| `reason = 'test_account'`                   | Distinction claire vs `internal_admin`             |
| Filtrage SQL avec `NOT EXISTS`              | Performant, explicite, zero ORM                    |
| Supprimer `billing_exempt` de `customers`   | Ce champ polluait les compteurs business           |
| MRR exclut test subs                        | Les subs test (switaa AUTOPILOT) faussaient le MRR |


---

## 9. AVANT / APRES

### PROD


| Metrique    | Avant (T8.2E) | Apres (T8.2Ebis)                 |
| ----------- | ------------- | -------------------------------- |
| Signups     | 13            | **1** (reel)                     |
| Paid        | 2             | **0** (test subs exclues)        |
| Trial       | 6             | **0** (test subs exclues)        |
| MRR         | 994 EUR       | **0 EUR** (plus de subs reelles) |
| CAC blended | 39.34 EUR     | **511.45 EUR**                   |
| CAC paid    | 255.73 EUR    | **null**                         |
| ROAS        | 1.94          | **null**                         |


### Interpretation business

La verite PROD est que sur 13 comptes, **12 sont internes/test** et **1 seul est un vrai client externe** (romruais) qui a ensuite annule sa subscription. Les metriques precedentes donnaient une image artificiellement positive (ROAS 1.94, CAC 39 EUR) qui ne reflétait pas la realite business.

---

## 10. VERDICT

**METRICS CLEAN — TEST DATA EXCLUDED — BUSINESS SAFE**

---

## 11. PROCHAINES ETAPES


| #   | Action                                               | Priorite |
| --- | ---------------------------------------------------- | -------- |
| 1   | CronJob import Meta spend quotidien                  | Haute    |
| 2   | Admin V2 : dashboard metrics UI                      | Haute    |
| 3   | Alertes si nouveau tenant est marque test par erreur | Moyenne  |
| 4   | Historique spend complet (backfill)                  | Moyenne  |


