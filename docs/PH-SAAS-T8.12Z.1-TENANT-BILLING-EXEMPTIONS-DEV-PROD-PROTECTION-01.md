# PH-SAAS-T8.12Z.1 - Tenant Billing Exemptions DEV/PROD Protection

> Phase : PH-SAAS-T8.12Z.1-TENANT-BILLING-EXEMPTIONS-DEV-PROD-PROTECTION-01
> Date : 2026-05-02
> Type : Data fix minimal, exemptions uniquement
> Environnement : DEV + PROD
> Prerequis : PH-SAAS-T8.12Z (audit truth, commit `a107fd3`)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z-TEST-TENANTS-AND-VALIDATION-DATA-CLEANUP-TRUTH-AUDIT-01.md`
- `CE_PROMPTING_STANDARD.md`, `RULES_AND_RISKS.md`
- `PH-SAAS-T8.12Y.9D.1` (lifecycle wait state)
- `PH-T8.11J` (metrics test data cleanup)

---

## PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `a107fd3` | Fichiers pre-existants (non lies) | **GO** |

| Service | Runtime | Modifie ? |
|---|---|---|
| API DEV | v3.5.141-lifecycle-pilot-safety-gates-dev | Non |
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | Non |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non |

Aucun build/deploy. Mutation autorisee : `tenant_billing_exempt` uniquement.

---

## TENANTS CIBLES RECONFIRMES

### DEV (2 tenants)

| Env | Tenant ID | Name | Owner masque | Plan | Status | Convos | Billing | Deja exempt ? | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| DEV | `tenant-1772234265142` | Essai | lu***@eco*** | STARTER | active | 0 | trialing | Non | INSERT |
| DEV | `test-lambda-k1-sas-molcr3ha` | Test Lambda K1 SAS | sw***@gma*** | STARTER | active | 0 | trialing | Non | INSERT |

### PROD (2 tenants)

| Env | Tenant ID | Name | Owner masque | Plan | Status | Convos | Billing | Deja exempt ? | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| PROD | `ludovic-mojol7ds` | Ludovic | lu***@key*** | PRO | active | 0 | trialing | Non | INSERT |
| PROD | `internal-validation--mok6do0m` | INTERNAL-VALIDATION TikTok | in***@key*** | PRO | pending_payment | 0 | null | Non | INSERT |

Aucun de ces tenants ne ressemble a un vrai client externe. Tous sont des comptes test/internes.

---

## BACKUP SELECT AVANT MUTATION

### DEV

| Check | Count avant |
|---|---|
| Total tenants | 26 |
| `tenant_billing_exempt` (exempt=true) | 24 |
| Non-exempts cibles | 2 |

### PROD

| Check | Count avant |
|---|---|
| Total tenants | 24 |
| `tenant_billing_exempt` (exempt=true) | 22 |
| Non-exempts cibles | 2 |
| `trial_lifecycle_emails_sent` | 1 (Y.9B proof) |
| `billing_events` | 149 |

---

## MUTATIONS EXECUTEES

### DEV - INSERT 2 exemptions

```sql
INSERT INTO tenant_billing_exempt (tenant_id, exempt, reason)
VALUES ('tenant-1772234265142', true, 'test_account'),
       ('test-lambda-k1-sas-molcr3ha', true, 'test_account')
ON CONFLICT (tenant_id)
DO UPDATE SET exempt = true, reason = 'test_account'
```

| Env | Tenant masque | Action | Resultat |
|---|---|---|---|
| DEV | tenant-177... | INSERT exempt=true, reason=test_account | OK |
| DEV | test-lambda-k1... | INSERT exempt=true, reason=test_account | OK |

### PROD - INSERT 2 exemptions

```sql
INSERT INTO tenant_billing_exempt (tenant_id, exempt, reason)
VALUES ('ludovic-mojol7ds', true, 'test_account'),
       ('internal-validation--mok6do0m', true, 'test_account')
ON CONFLICT (tenant_id)
DO UPDATE SET exempt = true, reason = 'test_account'
```

| Env | Tenant masque | Action | Resultat |
|---|---|---|---|
| PROD | ludovic-moj... | INSERT exempt=true, reason=test_account | OK |
| PROD | internal-val... | INSERT exempt=true, reason=test_account | OK |

---

## VALIDATION DEV

| Check DEV | Attendu | Resultat |
|---|---|---|
| `tenant_billing_exempt` (exempt=true) | 26 | **26** |
| tenant-177... exempt | true | **true** |
| test-lambda-k1... exempt | true | **true** |

---

## VALIDATION PROD

| Check PROD | Attendu | Resultat |
|---|---|---|
| `tenant_billing_exempt` (exempt=true) | 24 | **24** |
| ludovic-moj... exempt | true | **true** |
| internal-val... exempt | true | **true** |
| Non-exempt restants | 0 | **0** |
| `trial_lifecycle_emails_sent` | 1 (inchange) | **1** |

---

## NON-REGRESSION

| Surface | Attendu | Resultat |
|---|---|---|
| API DEV image | v3.5.141-lifecycle-pilot-safety-gates-dev | **Inchange** |
| API PROD image | v3.5.135-lifecycle-pilot-safety-gates-prod | **Inchange** |
| Client PROD image | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | **Inchange** |
| CronJob lifecycle PROD | dry-run (schedule 0 8 * * *) | **Inchange** |
| `billing_events` PROD | 149 | **149** |
| `trial_lifecycle_emails_sent` PROD | 1 | **1** |
| Emails envoyes | 0 | **0** |
| Build/deploy | 0 | **0** |
| Code modifie | 0 | **0** |
| Stripe mutation | 0 | **0** |

---

## ROLLBACK DOCUMENTE (NON EXECUTE)

Si necessaire, rollback possible :

```sql
-- DEV rollback
-- DELETE FROM tenant_billing_exempt
-- WHERE tenant_id IN ('tenant-1772234265142', 'test-lambda-k1-sas-molcr3ha');

-- PROD rollback
-- DELETE FROM tenant_billing_exempt
-- WHERE tenant_id IN ('ludovic-mojol7ds', 'internal-validation--mok6do0m');
```

Ces rows n'existaient pas avant cette phase. La suppression les restaure a l'etat precedent.

---

## VERDICT

**GO**

TENANT BILLING EXEMPTIONS COMPLETED -- DEV 26/26 PROTECTED -- PROD 24/24 PROTECTED -- METRICS/LIFECYCLE SAFER -- NO DELETE -- NO CODE -- NO BUILD -- NO DEPLOY -- NO TRACKING/BILLING/CAPI DRIFT

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.1-TENANT-BILLING-EXEMPTIONS-DEV-PROD-PROTECTION-01.md
```
