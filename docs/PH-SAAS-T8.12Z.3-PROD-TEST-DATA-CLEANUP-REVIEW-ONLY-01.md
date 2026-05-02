# PH-SAAS-T8.12Z.3 - PROD Test Data Cleanup Review Only

> Phase : PH-SAAS-T8.12Z.3-PROD-TEST-DATA-CLEANUP-REVIEW-ONLY-01
> Date : 2026-05-02
> Type : Review-only, zero mutation
> Environnement : PROD
> Prerequis : Z (audit), Z.1 (exemptions), Z.2 (DEV cleanup)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z` (audit truth), `PH-SAAS-T8.12Z.1` (exemptions), `PH-SAAS-T8.12Z.2` (DEV cleanup)
- `PH-SAAS-T8.12Y.9B` (lifecycle controlled send Y.9B)
- `PH-SAAS-T8.12Y.9D.1` (lifecycle wait state)
- `CE_PROMPTING_STANDARD.md`, `RULES_AND_RISKS.md`

---

## PREFLIGHT

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-infra | main | `62c0159` | **GO** |

| Service | Runtime | Modifie ? |
|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | Non |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non |

Review-only. Aucune mutation, aucun cleanup.

---

## INVENTAIRE TENANTS PROD (24 tenants)

| # | Tenant masque | Domaine | Plan | Status | Conv | Orders | Billing | Exempt | Lifecycle | Signup | Funnel | Classification |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | ecomlg-001 | gmail.com | PRO | active | 486 | 11889 | - | internal_admin | 0 | 0 | 2 | **DO_NOT_TOUCH** |
| 2 | ecomlg-mn3r... | gmail.com | starter | active | 0 | 0 | canceled | test_account | 0 | 0 | 0 | CANDIDATE_CLEANUP |
| 3 | ecomlg-mn3r... | gmail.com | PRO | pending | 0 | 0 | - | test_account | 0 | 0 | 0 | CANDIDATE_CLEANUP |
| 4 | romruais-gma... | gmail.com | starter | active | 1 | 0 | canceled | test_account | 0 | 0 | 0 | KEEP_EXEMPT |
| 5 | switaa-sasu-mn9... | switaa.com | AUTO | active | 6 | 2 | active | test_account | 0 | 0 | 0 | KEEP_EXEMPT |
| 6 | switaa-sasu-mnc... | gmail.com | AUTO | active | 29 | 12 | active | test_account | 0 | 0 | 3 | **DO_NOT_TOUCH** |
| 7 | compta-ecol... | gmail.com | starter | active | 3 | 0 | canceled | test_account | 0 | 0 | 0 | KEEP_EXEMPT |
| 8 | test-mnyy... | gmail.com | PRO | pending | 0 | 0 | - | test_account | 0 | 0 | 0 | CANDIDATE_CLEANUP |
| 9 | ecomlg-mo45... | gmail.com | PRO | active | 0 | 0 | active | test_account | 0 | 0 | 0 | CANDIDATE_CLEANUP |
| 10 | ecomlg-mo4h... | gmail.com | PRO | active | 2 | 0 | active | test_account | 0 | 0 | 0 | KEEP_EXEMPT |
| 11 | tiktok-prod-test... | gmail.com | PRO | pending | 0 | 0 | - | test_account | 0 | 0 | 0 | CANDIDATE_CLEANUP |
| 12 | tiktok-prod-v2... | gmail.com | PRO | active | 0 | 0 | trialing | test_account | 0 | 1 | 0 | CANDIDATE_CLEANUP |
| 13 | ludo-gonthier... | gmail.com | PRO | active | 0 | 0 | trialing | test_account | 0 | 1 | 0 | CANDIDATE_CLEANUP |
| 14 | ecomlg07-mo9... | gmail.com | PRO | active | 0 | 0 | trialing | test_account | 0 | 1 | 0 | CANDIDATE_CLEANUP |
| 15 | keybuzz-consult... | keybuzz.pro | AUTO | active | 0 | 0 | - | internal_admin | 0 | 0 | 0 | **DO_NOT_TOUCH** |
| 16 | test-prod-w3lg... | gmail.com | PRO | active | 0 | 0 | trialing | test_account | 0 | 1 | 2 | CANDIDATE_CLEANUP |
| 17 | test-owner-runt... | keybuzz.io | PRO | pending | 0 | 0 | - | test_account | 0 | 1 | 2 | KEEP_PROOF |
| 18 | olyara-test-kb... | gmail.com | AUTO | active | 0 | 0 | trialing | test_account | 0 | 1 | 4 | CANDIDATE_CLEANUP |
| 19 | codex-google-own... | keybuzz.pro | PRO | pending | 0 | 0 | - | test_account | 0 | 1 | 0 | KEEP_PROOF |
| 20 | codex-google-leg... | keybuzz.pro | PRO | pending | 0 | 0 | - | test_account | 0 | 1 | 0 | KEEP_PROOF |
| 21 | test-codex-check... | gmail.com | PRO | active | 0 | 0 | trialing | test_account | 0 | 1 | 2 | CANDIDATE_CLEANUP |
| 22 | ludovic-mojol... | keybuzz.pro | PRO | active | 0 | 0 | trialing | test_account | 1 | 1 | 3 | **KEEP_PROOF** |
| 23 | internal-valid... | keybuzz.pro | PRO | pending | 0 | 0 | - | test_account | 0 | 1 | 0 | KEEP_PROOF |
| 24 | trial-autopilot... | keybuzz.pro | STARTER | active | 0 | 0 | trialing | test_account | 0 | 1 | 1 | CANDIDATE_CLEANUP |

---

## BILLING PROD REVIEW

| Surface | Count | Risque |
|---|---|---|
| billing_subscriptions | 15 | Aucun debit reel (Stripe test) |
| billing_customers | 21 | Customers test |
| billing_events | 149 | Webhook events test |

| Status | Count | Risque debit |
|---|---|---|
| active | 4 | Non (test mode) |
| trialing | 7 | Non (trial, pas de carte reelle) |
| canceled | 3 | Non (deja annulees) |

**Aucun risque de debit reel.** Toutes les subscriptions sont liees a des tenants test, Stripe en mode test.

---

## ATTRIBUTION / METRICS PROD REVIEW

| Surface | Rows PROD | Tenant exempt ? | Candidat cleanup ? |
|---|---|---|---|
| `signup_attribution` | 12 | Oui (tous exempts) | Oui, apres validation |
| `conversion_events` | 2 | Oui | Oui |
| `ad_spend_tenant` | 18 | Oui (keybuzz-consulting) | Review (pas de spend reel) |

Les 12 rows `signup_attribution` sont reparties sur 12 tenants differents, toutes test. Aucune attribution reelle.

Les campaigns sont : `prod_tiktok_launch`, `ph724_ga4mp_final`, `codex-prod-runtime-check`, `internal-validation-*`, etc. Toutes identifiables comme test.

---

## FUNNEL / ONBOARDING PROD REVIEW

| Surface | Rows | Dont test | Dont ecomlg-001 | Dont NULL | Cleanup futur ? |
|---|---|---|---|---|---|
| `funnel_events` | 60 | 19 (tenants test) | 2 (conserver) | 39 (pre-tenant, conserver) | 19 rows test |

Les 39 rows avec `tenant_id=NULL` sont des events pre-signup (`register_started`, `email_submitted`, `otp_verified`, `plan_selected`, `company_completed`, `user_completed`). Ils representent le funnel anonyme et n'ont pas de tenant associe.

---

## LIFECYCLE PROD REVIEW

| Element | Count | Classification |
|---|---|---|
| `trial_lifecycle_emails_sent` | 1 | **KEEP_PROOF** (Y.9B controlled send) |
| `lifecycle_email_optout` | 0 | - |
| CronJob | dry-run (`0 8 * * *`) | Inchange |
| Eligible external | 0 | Confirme |

La row Y.9B (`ludovic-mojol...`, `trial-welcome`, sent 2026-05-02) est la preuve de l'envoi controle. **Ne jamais supprimer.**

---

## CLASSIFICATION FINALE

| Classification | Tenants | Rows associees | Raison |
|---|---|---|---|
| **DO_NOT_TOUCH** | 3 (ecomlg-001, switaa-mnc..., keybuzz-consult...) | ecomlg: 486 convos + 2 funnel; switaa: 29 convos + 3 funnel | Tenant reel / donnees actives / internal admin |
| **KEEP_PROOF** | 5 (ludovic-moj..., internal-valid..., test-owner-runt..., codex-google-own..., codex-google-leg...) | 1 lifecycle + 5 signup_attr + 5 funnel | Preuves PH Y.9B, T8.10J, codex validation |
| **KEEP_EXEMPT** | 4 (romruais..., switaa-mn9..., compta..., ecomlg-mo4h...) | Convos existantes (1-6) | Donnees test mais contenu non-vide |
| **CANDIDATE_CLEANUP** | 12 tenants | 0 convos, 0 orders, coquilles vides | Nettoyables apres validation Ludovic |

### CANDIDATE_CLEANUP - Detail

| Tenant masque | Plan | Status | Billing | Signup attr | Funnel | Pourquoi candidate |
|---|---|---|---|---|---|---|
| ecomlg-mn3r... (#2) | starter | active | canceled | 0 | 0 | Coquille vide |
| ecomlg-mn3r... (#3) | PRO | pending | - | 0 | 0 | Coquille vide |
| test-mnyy... | PRO | pending | - | 0 | 0 | Coquille vide |
| ecomlg-mo45... | PRO | active | active | 0 | 0 | Coquille + sub active test |
| tiktok-prod-test... | PRO | pending | - | 0 | 0 | Coquille vide |
| tiktok-prod-v2... | PRO | active | trialing | 1 | 0 | Coquille + signup test |
| ludo-gonthier... | PRO | active | trialing | 1 | 0 | Coquille + signup test |
| ecomlg07-mo9... | PRO | active | trialing | 1 | 0 | Coquille + signup test |
| test-prod-w3lg... | PRO | active | trialing | 1 | 2 | Coquille + signup/funnel test |
| olyara-test-kb... | AUTO | active | trialing | 1 | 4 | Coquille + signup/funnel test |
| test-codex-check... | PRO | active | trialing | 1 | 2 | Coquille + signup/funnel test |
| trial-autopilot... | STARTER | active | trialing | 1 | 1 | Coquille + signup/funnel test |

---

## RISQUE PAR TYPE DE CLEANUP

| Cleanup possible | Benefice | Risque | Recommandation |
|---|---|---|---|
| Supprimer `signup_attribution` test (12 rows) | Metrics attribution propres | Perte preuve tracking PH | **Attendre validation Ludovic** |
| Supprimer `funnel_events` test (19 rows) | Funnel propre | Perte preuve onboarding PH | **Attendre** |
| Supprimer `conversion_events` (2 rows) | Moins bruit | Perte preuve conversion PH | **Attendre** |
| Supprimer `ad_spend_tenant` (18 rows) | Spend propre | Pas de spend reel, safe | **Low risk, attendre** |
| Supprimer lifecycle Y.9B row | Aucun | Perte preuve idempotence | **Ne jamais supprimer** |
| Supprimer billing_events (149) | Moins bruit | Risque audit billing | **Review manuelle** |
| Supprimer tenants coquilles (12) | Base propre | FK cascading, preuves | **Tenant-by-tenant** |

---

## PLAN FUTUR PROD CLEANUP

| Phase | Scope | Mutation | Prerequis |
|---|---|---|---|
| **Z.4** | Validation Ludovic sur 12 candidats | Non | Ce rapport fourni |
| **Z.5** | Export backup PROD cible | Non | Z.4 valide |
| **Z.6** | Cleanup PROD controle | Oui (transaction) | Z.5 fait, rollback documente |

---

## SQL DRAFT NON EXECUTE

```sql
-- Futur Z.6 : cleanup signup_attribution PROD (12 rows)
-- SELECT count(*) FROM signup_attribution;  -- attendu: 12
-- BEGIN;
-- DELETE FROM signup_attribution WHERE tenant_id IN (
--   SELECT id FROM tenants t
--   JOIN tenant_billing_exempt tbe ON tbe.tenant_id = t.id
--   WHERE tbe.exempt = true AND tbe.reason = 'test_account'
-- );
-- SELECT count(*) FROM signup_attribution;  -- attendu: 0
-- -- COMMIT; ou ROLLBACK;

-- Futur Z.6 : cleanup funnel_events test PROD (19 rows)
-- DELETE FROM funnel_events WHERE tenant_id IS NOT NULL
--   AND tenant_id NOT IN ('ecomlg-001', 'switaa-sasu-mnc1ouqu')
-- -- preserve ecomlg-001 (2 rows) + switaa (3 rows)
-- -- supprimerait 14 rows test-tenant + 5 rows proof-tenant
-- -- ATTENTION: certaines sont KEEP_PROOF, filtrer
```

---

## LINEAR / TICKETS

### Ticket : PROD Test Data Cleanup Approval

```
Titre : [Data Hygiene] PROD cleanup - validation Ludovic requise
Priorite : P2
Labels : data-hygiene, prod, needs-approval

Description :
- 12 tenants PROD candidats au cleanup (coquilles vides, 0 convos)
- 12 signup_attribution test, 19 funnel_events test
- 2 conversion_events test, 18 ad_spend_tenant test
- 149 billing_events test
- 1 lifecycle row Y.9B a CONSERVER
- Aucun risque debit Stripe identifie
- Tous 24/24 exempts

Action requise : Ludovic valide quels tenants supprimer, quels garder

Ref : PH-SAAS-T8.12Z.3
```

---

## CONFIRMATION ZERO MUTATION

- Aucun INSERT/UPDATE/DELETE execute
- Aucun build/deploy
- Aucun email
- Aucune modification Stripe
- Aucune modification code/manifests
- PROD 100% inchangee

---

## VERDICT

**GO**

PROD TEST DATA CLEANUP REVIEW COMPLETE -- TENANTS/BILLING/ATTRIBUTION/FUNNEL/LIFECYCLE CLASSIFIED -- NO MUTATION -- NO CLEANUP EXECUTED -- LUDOVIC APPROVAL REQUIRED BEFORE ANY PROD DELETE

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.3-PROD-TEST-DATA-CLEANUP-REVIEW-ONLY-01.md
```
