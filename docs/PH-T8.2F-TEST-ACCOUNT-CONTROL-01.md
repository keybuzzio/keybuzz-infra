# PH-T8.2F — Test Account Control Safe

> Date : 2026-04-20
> Environnement : **DEV + PROD**
> Branche source : `ph147.4/source-of-truth`
> Commit source : `0c44b718` (PH-T8.2F: explicit test control)
> Commit infra : `0b532ce` (PH-T8.2F: test-control-safe v3.5.88)

---

## 1. RESUME

Verification et securisation du systeme d'exclusion des comptes test.
Remplacement des heuristiques (utilisees uniquement dans le script de marquage one-shot)
par un systeme purement explicite base sur `tenant_billing_exempt`.

---

## 2. AUDIT HEURISTIQUES

### 2.1. Heuristiques dans le code API


| Regle heuristique                       | Presente dans `routes.ts` ? | Action     |
| --------------------------------------- | --------------------------- | ---------- |
| Email domain `@ecomlg.`*                | **NON**                     | N/A        |
| Email domain `@switaa.`*                | **NON**                     | N/A        |
| Email domain `@keybuzz.`*               | **NON**                     | N/A        |
| Email pattern `ludo.gonthier+%`         | **NON**                     | N/A        |
| Tenant ID prefix `test-`                | **NON**                     | N/A        |
| Tenant name ILIKE `%test%`              | **NON**                     | N/A        |
| Tenant name ILIKE `%essai%`             | **NON**                     | N/A        |
| `tbe.exempt = true` (flag explicite DB) | **OUI**                     | **GARDER** |


**Resultat** : zero heuristique dans le code API. Le filtrage repose exclusivement sur le flag `tenant_billing_exempt.exempt = true`.

### 2.2. Heuristiques dans le script de marquage

Le script `ph-t82ebis-mark-test.sh` (phase T8.2Ebis) utilisait des heuristiques pour identifier les comptes test a marquer. Ce script etait **one-shot** — il ne fait pas partie du code API deploye. Les heuristiques ont servi a peupler `tenant_billing_exempt` une seule fois.

---

## 3. SYSTEME CIBLE

### Exclusion = flag explicite uniquement

```
tenant_billing_exempt.exempt = true
```

Pas de fallback automatique. Pas de detection par email/domaine/nom.
Un nouveau tenant est **inclus par defaut** (aucune entree dans `tenant_billing_exempt`).

### Methodes de filtrage SQL (inchangees)


| Requete            | Filtre                               |
| ------------------ | ------------------------------------ |
| customerBreakdown  | `tbe.exempt IS NOT TRUE`             |
| conversionSnapshot | `NOT EXISTS (... tbe.exempt = true)` |
| revenueResult      | `NOT EXISTS (... tbe.exempt = true)` |
| customersByPlan    | `tbe.exempt IS NOT TRUE`             |


### Pour marquer un nouveau compte test

```sql
INSERT INTO tenant_billing_exempt (tenant_id, exempt, reason)
VALUES ('<tenant_id>', true, 'test_account');
```

### Pour re-inclure un compte

```sql
DELETE FROM tenant_billing_exempt WHERE tenant_id = '<tenant_id>';
```

---

## 4. MODIFICATIONS CODE

Diff minimal (2 lignes) :

```diff
-  test_data_excluded: true,
+  test_data_excluded: testExcluded > 0,
   test_accounts_count: testExcluded,
+  exclusion_method: 'tenant_billing_exempt',
```


| Changement                     | Justification                                          |
| ------------------------------ | ------------------------------------------------------ |
| `test_data_excluded` dynamique | `true` hardcode etait inexact si 0 comptes exclus      |
| `exclusion_method` ajoute      | Explicite — documente la source du filtrage dans l'API |


---

## 5. TENANTS MARQUES (verifie)

### DEV (18 exclus, 1 reel)


| Reason           | Count | Exemples                                        |
| ---------------- | ----- | ----------------------------------------------- |
| `internal_admin` | 1     | ecomlg-001                                      |
| `test_account`   | 17    | switaa-*, test-*, ecomlg-*, keybuzz-*, tiktok-* |
| **REEL**         | **1** | `olyara369-gmail-com-`* (AUTOPILOT active)      |


### PROD (12 exclus, 1 reel)


| Reason           | Count | Exemples                             |
| ---------------- | ----- | ------------------------------------ |
| `internal_admin` | 1     | ecomlg-001                           |
| `test_account`   | 11    | switaa-*, test-*, ecomlg-*, tiktok-* |
| **REEL**         | **1** | `romruais-gmail-com-`* (canceled)    |


Chaque marquage a ete verifie manuellement : tenant name, owner email, subscription status.

---

## 6. VALIDATION

### CAS A — tenant marque test → exclu


| Env  | test_accounts_count | test_data_excluded | exclusion_method      | Verdict |
| ---- | ------------------- | ------------------ | --------------------- | ------- |
| DEV  | 18                  | true               | tenant_billing_exempt | PASS    |
| PROD | 12                  | true               | tenant_billing_exempt | PASS    |


### CAS B — tenant non marque → inclus


| Env  | real signups  | MRR              | Verdict |
| ---- | ------------- | ---------------- | ------- |
| DEV  | 1 (olyara369) | 497 EUR          | PASS    |
| PROD | 1 (romruais)  | 0 EUR (canceled) | PASS    |


### CAS C — nouveau client → inclus par defaut

Par design : un nouveau tenant n'a **aucune entree** dans `tenant_billing_exempt`.
Le filtre `tbe.exempt IS NOT TRUE` evalue a TRUE → le tenant est inclus.
Preuve : les tenants reels (olyara369, romruais) n'ont aucun flag et sont comptes.

### Non-regression


| Endpoint                      | DEV          | PROD         |
| ----------------------------- | ------------ | ------------ |
| `GET /health`                 | OK           | OK           |
| `GET /messages/conversations` | OK           | OK           |
| `GET /tenant-context/me`      | OK           | OK           |
| `GET /dashboard/summary`      | OK           | OK           |
| Tracking                      | Aucun impact | Aucun impact |
| Stripe                        | Aucun impact | Aucun impact |


---

## 7. IMAGES


| Env  | Tag                              | Digest                            |
| ---- | -------------------------------- | --------------------------------- |
| DEV  | `v3.5.88-test-control-safe-dev`  | `sha256:edcc7d63...`              |
| PROD | `v3.5.88-test-control-safe-prod` | `sha256:edcc7d63...` (meme image) |


---

## 8. ROLLBACK


| Env  | Rollback vers                    | Action          |
| ---- | -------------------------------- | --------------- |
| DEV  | `v3.5.87-exclude-test-data-dev`  | Manifest revert |
| PROD | `v3.5.87-exclude-test-data-prod` | Manifest revert |


Les donnees dans `tenant_billing_exempt` restent en place (non-destructif).

---

## 9. GARANTIES


| Garantie                              | Preuve                                            |
| ------------------------------------- | ------------------------------------------------- |
| Zero heuristique dans le code API     | `grep` confirme : aucun email/domain/name pattern |
| Exclusion = flag explicite uniquement | `tbe.exempt = true` dans SQL                      |
| Nouveau client = inclus par defaut    | Pas d'entree → `tbe.exempt IS NOT TRUE` → inclus  |
| Reversible                            | `DELETE FROM tenant_billing_exempt`               |
| Non-destructif                        | INSERT + flag, aucune deletion                    |
| Pas de false positive                 | Chaque marquage verifie manuellement              |


---

## 10. VERDICT

**TEST ACCOUNT CONTROL SAFE — NO FALSE POSITIVE**

---

## 11. PROCHAINES ETAPES


| #   | Action                                          | Priorite |
| --- | ----------------------------------------------- | -------- |
| 1   | CronJob import Meta spend quotidien             | Haute    |
| 2   | Admin V2 : dashboard metrics UI                 | Haute    |
| 3   | Admin V2 : interface pour marquer test accounts | Moyenne  |


