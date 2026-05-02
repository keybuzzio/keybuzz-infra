# PH-SAAS-T8.12Z.2 - DEV Test Data Cleanup Controlled

> Phase : PH-SAAS-T8.12Z.2-DEV-TEST-DATA-CLEANUP-CONTROLLED-01
> Date : 2026-05-02
> Type : Cleanup DEV controle, PROD intouchee
> Environnement : DEV uniquement
> Prerequis : PH-SAAS-T8.12Z (audit), PH-SAAS-T8.12Z.1 (exemptions)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z` (audit truth), `PH-SAAS-T8.12Z.1` (exemptions)
- `CE_PROMPTING_STANDARD.md`, `RULES_AND_RISKS.md`

---

## PREFLIGHT

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-infra | main | `e2e8078` | **GO** |

| Point | Valeur |
|---|---|
| DB cible | DEV (keybuzz-api-dev pod) |
| PROD touchee | Non |
| Build/deploy | Non |
| Email | Non |
| Export avant mutation | Oui |

---

## CLASSIFICATION DEV FINALE

### DO NOT TOUCH

| Tenant | Raison |
|---|---|
| ecomlg-001 | Tenant reel DEV (462 convos, 11952 orders) |
| keybuzz-consulting-mo9y479d | Internal admin, fixtures acquisition |
| switaa-sasu-mnc1x4eq | 75 convos, 152 msgs, donnees test actives |

### KEEP_FIXTURE (donnees test utiles)

| Tenant masque | Convos | Orders | Billing | Decision |
|---|---|---|---|---|
| ecomlg07-gmail... | 4 | 3 | active | Conserver |
| switaa-mn9ioy5j | 3 | 1 | active | Conserver |
| compta-ecomlg... | 3 | 0 | active | Conserver |

### KEEP_PROOF (preuves PH)

| Tenant masque | Raison |
|---|---|
| proof-owner-valid... | Preuve PH-T8.10B.1 |
| proof-no-owner... | Preuve PH-T8.10B.1 |
| proof-child-funnel... | Preuve PH-T8.10D.1 |

### EXEMPT_ONLY (coquilles vides, gardees mais exemptees)

Tous les autres 17 tenants : 0 convos, 0 msgs, exempts, pas de suppression dans cette phase.

---

## SCOPE CLEANUP SAFE

| Objet | Count avant | Action | Risque |
|---|---|---|---|
| `trial_lifecycle_emails_sent` | 4 | DELETE all (test DEV Y.7) | Faible |
| `signup_attribution` | 11 | DELETE all (100% test tenants) | Faible |
| `conversion_events` | 2 | DELETE all (proof tenants) | Faible |
| `ad_spend_tenant` | 16 | DELETE all (keybuzz-consulting) | Faible |
| `funnel_events` (test tenants) | 12 | DELETE (excl. ecomlg-001, switaa-sasu-mnc1x4eq, NULL) | Faible |

Tenants, users, billing_subscriptions, tenant_metadata : **non touches** dans cette phase.

---

## EXPORT BACKUP

L'export complet des rows supprimees a ete capture dans le JSON de sortie du script avant DELETE. Contenu exporte :
- 4 lifecycle rows (IDs, templates, emails, timestamps)
- 11 signup_attribution rows (IDs, tenants, UTMs, landing URLs)
- 2 conversion_events rows (IDs, payloads complets)
- 16 ad_spend_tenant rows (counts par tenant)
- 12 funnel_events rows (IDs, event_names, tenants)

Export stocke dans l'output du script d'execution, non committe (contient PII).

---

## PLAN SQL TRANSACTIONNEL

```
BEGIN
  SELECT counts avant (lifecycle, signup, conversion, ad_spend, funnel)
  DELETE FROM trial_lifecycle_emails_sent
  DELETE FROM signup_attribution
  DELETE FROM conversion_events
  DELETE FROM ad_spend_tenant
  DELETE FROM funnel_events WHERE tenant_id NOT IN (ecomlg-001, switaa-sasu-mnc1x4eq) AND tenant_id IS NOT NULL
  SELECT counts apres
  VERIFY tenants=26, ecomlg_convos>=400, funnel_ecomlg=2
  IF safety_ok: COMMIT
  ELSE: ROLLBACK
```

---

## ROWS AFFECTEES

| Table | Avant | Supprime | Apres | Verdict |
|---|---|---|---|---|
| `trial_lifecycle_emails_sent` | 4 | 4 | 0 | OK |
| `signup_attribution` | 11 | 11 | 0 | OK |
| `conversion_events` | 2 | 2 | 0 | OK |
| `ad_spend_tenant` | 16 | 16 | 0 | OK |
| `funnel_events` | 42 | 12 | 30 | OK |
| **Total** | **75** | **45** | **30** | **COMMIT** |

Transaction commitee. Aucun safety rollback.

---

## VALIDATION DEV APRES CLEANUP

| Check | Attendu | Resultat |
|---|---|---|
| Tenants total | 26 | **26** |
| ecomlg-001 convos | >=400 | **462** |
| ecomlg-001 funnel | 2 | **2** |
| funnel_events restants | 30 | **30** |
| lifecycle rows | 0 | **0** |
| signup_attribution | 0 | **0** |
| conversion_events | 0 | **0** |
| ad_spend_tenant | 0 | **0** |

---

## NON-REGRESSION

| Surface | Attendu | Resultat |
|---|---|---|
| PROD tenants | 24 | **24** |
| PROD exempt | 24 | **24** |
| PROD lifecycle | 1 (Y.9B proof) | **1** |
| PROD billing_events | 149 | **149** |
| PROD signup_attr | 12 | **12** |
| PROD funnel | 60 | **60** |
| API DEV image | inchangee | **v3.5.141-lifecycle-pilot-safety-gates-dev** |
| API PROD image | inchangee | **v3.5.135-lifecycle-pilot-safety-gates-prod** |
| CronJob lifecycle | dry-run | **dry-run (0 8 * * *)** |
| Email envoye | 0 | **0** |
| Build/deploy | 0 | **0** |
| Code modifie | 0 | **0** |

---

## ROLLBACK DATA (NON EXECUTE)

Si rollback necessaire, re-inserer depuis l'export JSON :

```sql
-- Rollback: re-INSERT les rows supprimees depuis le backup JSON
-- Transaction obligatoire
-- Ordre: lifecycle, signup_attribution, conversion_events, ad_spend_tenant, funnel_events
-- Valider counts apres restauration
```

Export disponible dans l'output terminal du script d'execution (non committe, contient PII).

---

## VERDICT

**GO**

DEV TEST DATA CLEANUP COMPLETED -- FIXTURES PRESERVED -- BACKUP CREATED -- LIFECYCLE/METRICS DEV CLEANER -- PROD UNTOUCHED -- NO CODE -- NO BUILD -- NO DEPLOY -- NO TRACKING/BILLING/CAPI DRIFT

### Resume

- 45 rows test supprimees en DEV (5 tables)
- 26 tenants preserves (aucun supprime)
- ecomlg-001 intact (462 convos, 11952 orders)
- PROD 100% inchangee
- 0 build, 0 deploy, 0 email, 0 code

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.2-DEV-TEST-DATA-CLEANUP-CONTROLLED-01.md
```
