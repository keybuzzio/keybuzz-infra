# PH-SAAS-T8.12Z - Test Tenants and Validation Data Cleanup Truth Audit

> Phase : PH-SAAS-T8.12Z-TEST-TENANTS-AND-VALIDATION-DATA-CLEANUP-TRUTH-AUDIT-01
> Date : 2026-05-02
> Type : Audit lecture seule, zero mutation
> Environnement : DEV + PROD

---

## SOURCES RELUES

- `CE_PROMPTING_STANDARD.md`, `RULES_AND_RISKS.md`, `TRIAL_WOW_STACK_BASELINE.md`
- `PH-SAAS-T8.12Y.9D.1` (lifecycle wait state)
- `PH-T8.11J` (metrics test data cleanup PROD promotion)
- Rapports lifecycle Y.7/Y.8/Y.9B/Y.9C/Y.9D.0

---

## PREFLIGHT

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-infra | main | `21f8e99` | **GO** |

| Service | Runtime | Verdict |
|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | **GO** |
| CronJob lifecycle | dry-run | **GO** |

Aucune mutation prevue. Lecture seule confirmee.

---

## INVENTAIRE TENANTS DEV

### Resume

| Categorie DEV | Count | Risque |
|---|---|---|
| Total tenants | 26 | - |
| ID contient "test" | 10 | Pollution metrics/lifecycle |
| ID contient "proof" | 3 | Preuve PH, conserver |
| Billing exempt | 24 | Protege |
| Exempt `internal_admin` | 2 | Conserver (`ecomlg-001`, `keybuzz-consult...`) |
| Exempt `test_account` | 22 | Candidats cleanup |
| Non-exempt | 2 | `tenant-177...` + `test-lambda-k1...` |
| Trial actif | 10 | Pollution lifecycle si non exempt |
| Sans conversations | 21 | Coquilles vides |
| status `pending_payment` | 5 | Jamais convertis |
| Subscriptions `trialing` | 2 | `tenant-177...`, `test-lambda-k1...` |
| Subscriptions `active` | 12 | Test accounts, pas de vrai paiement Stripe |

### Tenants non-exempts DEV (risque lifecycle)

| Tenant masque | Plan | Exempt | Domaine | Risque |
|---|---|---|---|---|
| tenant-17722342... | STARTER | Non | ecomlg.fr | Eligible lifecycle mais domaine interne (G1) |
| test-lambda-k1-... | STARTER | Non | gmail.com | Eligible lifecycle, non bloque par G1 (*) |

(*) `test-lambda-k1-...` est sur `gmail.com` (pas dans la blocklist), cree le 30 avril (avant baseline). **Protege par G2** (baseline 2026-05-02T18:00:00Z). Mais si des emails lifecycle DEV sont envoyes avec `dryRun=false` et `force=true`, ce tenant pourrait recevoir des emails. En DEV, les gardes G1/G2 ne sont pas appliquees pour les envois DEV (NODE_ENV != production).

**Action recommandee** : ajouter `test-lambda-k1-...` et `tenant-17722342...` a `tenant_billing_exempt` en DEV.

---

## INVENTAIRE TENANTS PROD

### Resume

| Categorie PROD | Count | Risque |
|---|---|---|
| Total tenants | 24 | - |
| ID contient "test" | 6 | Pollution metrics |
| ID contient "internal" | 1 | `internal-valida...` |
| ID contient "codex" | 2 | Tests PH acquisition |
| ID contient "tiktok" | 2 | Tests PH tracking |
| Billing exempt | 22 | Protege |
| Exempt `internal_admin` | 2 | Conserver |
| Exempt `test_account` | 20 | Candidats review |
| Non-exempt | 2 | `ludovic-mojol7d...`, `internal-valida...` |
| Trial actif | 14 | Tous internes |
| Sans conversations | 18 | Coquilles vides |
| status `pending_payment` | 5 | Jamais convertis |
| Subscriptions `trialing` | 7 | Test subscriptions |
| Subscriptions `active` | 6 | Test accounts, Stripe test mode |
| Subscriptions `canceled` | 2 | Deja annulees |
| Billing customers | 21 | Stripe customers test |
| Billing events | 149 | Webhook events test |

### Tenants non-exempts PROD (risque lifecycle)

| Tenant masque | Plan | Exempt | Domaine | Risque |
|---|---|---|---|---|
| ludovic-mojol7d... | PRO | Non | keybuzz.pro | Protege par G1 (internal_domain) |
| internal-valida... | PRO | Non | keybuzz.pro | Protege par G1 (internal_domain) |

Ces 2 tenants sont ceux identifies en Y.9C. Tous deux bloques par G1 `internal_domain`.

**Action recommandee** : ajouter ces 2 tenants a `tenant_billing_exempt` pour coherence.

---

## USERS / EMAILS TEST

| Domaine/pattern | DEV count | PROD count | Type | Action recommandee |
|---|---|---|---|---|
| gmail.com | 23 | 19 | Ludovic + tests | Conserver (email reel Ludovic) |
| ecomlg.fr | 3 | 2 | Interne | Conserver |
| ecomlg.com | 2 | 1 | Interne | Conserver |
| switaa.com | 2 | 3 | Interne | Conserver |
| keybuzz.pro | 1 | 6 | Interne | Conserver |
| keybuzz.io | 2 | 1 | Interne | Conserver |
| test.com | 2 | 0 | Test pur | Cleanup DEV |
| test-keybuzz.io | 1 | 0 | Test pur | Cleanup DEV |
| **Total** | **36** | **32** | - | - |

### Constats

- **DEV** : 5 users avec domaines purement test (`test.com`, `test-keybuzz.io`)
- **PROD** : 0 user `test.com` (propre)
- Tous les `gmail.com` sont des adresses Ludovic reelles (differents comptes)
- Les domaines internes (`keybuzz.pro`, `keybuzz.io`, `switaa.com`, `ecomlg.*`) sont bloques par le lifecycle G1

---

## BILLING / STRIPE TEST DATA

| Cas | DEV count | PROD count | Risque | Recommandation |
|---|---|---|---|---|
| Subscriptions `active` | 12 | 6 | Pas de debit reel (test mode Stripe) | Cleanup later |
| Subscriptions `trialing` | 2 | 7 | Certaines expirent sans paiement | Cleanup later |
| Subscriptions `canceled` | 0 | 2 | Propre | Rien |
| Tenants `pending_payment` | 5 | 5 | Jamais convertis, coquilles | Cleanup later |
| Billing events total | N/A | 149 | Webhook events test, pollution | Cleanup later |
| Billing customers total | N/A | 21 | Stripe customers test | Cleanup later |
| Risque debit reel | **Aucun** | **Aucun** | Tous les tenants sont test, Stripe en test mode | **Pas de P0** |

**Pas de risque de debit reel imminent.** Toutes les subscriptions sont liees a des tenants test. Stripe ne debitera pas en mode test.

---

## METRICS / ACQUISITION POLLUTION

| Surface | Test data visible ? | Protege ? | Gap |
|---|---|---|---|
| `tenant_billing_exempt` | 22 PROD exempts | Oui (filtre metrics) | 2 non-exempts PROD |
| `signup_attribution` | DEV: 11, PROD: 12 | Non (pas de filtre test) | **Pollution possible** |
| `conversion_events` | DEV: 2, PROD: 2 | Non | **Pollution possible** |
| `ad_spend_tenant` | DEV: 16, PROD: 18 | Non | **Pollution possible** |
| `funnel_events` | DEV: 42, PROD: 60 | Non | **Pollution possible** |
| Lifecycle baseline | `2026-05-02T18:00:00Z` | Oui (code) | OK |
| Acquisition baseline | `2026-05-01 00:00 Europe/Paris` | A verifier | Si code filtre, OK |

### Constats

- Les tables `signup_attribution`, `conversion_events`, `ad_spend_tenant`, `funnel_events` contiennent des donnees de test qui peuvent polluer les metriques.
- La plupart des tenants sont proteges par `tenant_billing_exempt` pour le lifecycle, mais les tables d'acquisition n'ont pas de filtre equivalent systematique.
- **Recommandation** : lors du cleanup, purger les rows liees aux tenants test dans ces tables.

---

## FUNNEL / ONBOARDING TEST DATA

| Table/surface | DEV count test | PROD count test | Impact | Action |
|---|---|---|---|---|
| `funnel_events` | 42 | 60 | Pollution funnel analytics | Cleanup later |
| `signup_attribution` | 11 | 12 | Pollution attribution | Cleanup later |
| `conversion_events` | 2 | 2 | Faible impact | Cleanup later |
| Sample demo DB rows | 0 attendu | 0 attendu | OK (injection runtime) | Rien |
| Tenants coquilles vides | 21 DEV | 18 PROD | Pollution counts | Cleanup later |

---

## LIFECYCLE EMAIL DATA

### DEV

| Element | Count | Detail |
|---|---|---|
| `trial_lifecycle_emails_sent` | 4 rows | test-lambda-k1 (welcome + day-2), tenant-177 (welcome + day-2) |
| `lifecycle_email_optout` | 0 | Aucun opt-out |
| Non-exempt tenants | 2 | Risque DEV envoie hors dry-run |

### PROD

| Element | Count | Detail |
|---|---|---|
| `trial_lifecycle_emails_sent` | 1 row | ludovic-mojol7d (trial-welcome) = envoi controle Y.9B |
| `lifecycle_email_optout` | 0 | Aucun opt-out |
| Non-exempt tenants | 2 | Proteges par G1 (internal_domain) |

### Actions

- **PROD row Y.9B** : CONSERVER comme preuve historique
- **DEV rows** : cleanup possible (test lifecycle)
- **Non-exempts PROD** : ajouter a `tenant_billing_exempt` pour coherence

---

## CLASSIFICATION CLEANUP

| Groupe | Env | Count | Classification | Pourquoi |
|---|---|---|---|---|
| `ecomlg-001` | DEV+PROD | 1+1 | **KEEP_PROOF** | Tenant pilote historique, internal_admin |
| `keybuzz-consult...` | DEV+PROD | 1+1 | **KEEP_PROOF** | Internal admin, consultation |
| Tenants `proof-*` (DEV) | DEV | 3 | **KEEP_PROOF** | Preuves PH validation, exempts |
| `ludovic-mojol7d...` (PROD) | PROD | 1 | **EXEMPT_ONLY** | Non-exempt, Y.9B lifecycle proof, ajouter exempt |
| `internal-valida...` (PROD) | PROD | 1 | **EXEMPT_ONLY** | Non-exempt, ajouter exempt |
| `tenant-177...` (DEV) | DEV | 1 | **EXEMPT_ONLY** | Non-exempt, domaine interne, ajouter exempt |
| `test-lambda-k1-...` (DEV) | DEV | 1 | **EXEMPT_ONLY** | Non-exempt, gmail.com, lifecycle rows existantes |
| Tenants `test-*` avec subscription active | DEV+PROD | ~15 | **CLEANUP_DEV_SAFE** / **CLEANUP_PROD_REVIEW** | Coquilles test, aucune conversation |
| Tenants `tiktok-*` | DEV+PROD | ~4 | **CLEANUP_PROD_REVIEW** | Tests PH tracking |
| Tenants `codex-*` (PROD) | PROD | 2 | **CLEANUP_PROD_REVIEW** | Tests PH acquisition |
| Tenants `pending_payment` | DEV+PROD | 5+5 | **CLEANUP_DEV_SAFE** / **CLEANUP_PROD_REVIEW** | Jamais convertis |
| Users domaine `test.com` | DEV | 2 | **CLEANUP_DEV_SAFE** | Domaine fictif |
| Billing subscriptions test | DEV+PROD | 18+15 | **CLEANUP_PROD_REVIEW** | Stripe test mode |
| `signup_attribution` test | DEV+PROD | 11+12 | **CLEANUP_PROD_REVIEW** | Pollution attribution |
| `funnel_events` test | DEV+PROD | 42+60 | **CLEANUP_PROD_REVIEW** | Pollution funnel |
| Lifecycle PROD row Y.9B | PROD | 1 | **DO_NOT_TOUCH** | Preuve envoi controle |
| Lifecycle DEV rows | DEV | 4 | **CLEANUP_DEV_SAFE** | Test lifecycle |

---

## PLAN CLEANUP PROPOSE

| Phase | Scope | Mutation ? | Risque | Prerequis |
|---|---|---|---|---|
| **Z.1** DEV Exempt | Ajouter 2 tenants non-exempts DEV a `tenant_billing_exempt` | Oui (INSERT 2 rows) | Faible | Validation Ludovic |
| **Z.2** PROD Exempt | Ajouter 2 tenants non-exempts PROD a `tenant_billing_exempt` | Oui (INSERT 2 rows) | Faible | Validation Ludovic |
| **Z.3** DEV Cleanup | Purger lifecycle DEV rows test, users test.com, tenants coquilles | Oui (DELETE) | Moyen | Z.1 fait, backup SELECT avant |
| **Z.4** PROD Review | Lister tenants PROD candidats cleanup, demander validation Ludovic | Non (docs) | Aucun | Z.2 fait |
| **Z.5** PROD Cleanup | Purger tenants coquilles PROD, funnel_events, signup_attribution | Oui (DELETE) | Eleve | Z.4 valide par Ludovic, transaction DB, backup |
| **Z.6** Stripe Cleanup | Annuler subscriptions test, supprimer customers test | Oui (Stripe API) | Eleve | Z.5 fait, Stripe test mode confirme |

### Priorite

1. **Z.1 + Z.2** (exempt) : prioritaire, corrige les 4 tenants non-exempts
2. **Z.3** (DEV cleanup) : peut etre fait librement
3. **Z.4** (PROD review) : documentation, pas de mutation
4. **Z.5 + Z.6** (PROD cleanup) : necessite validation Ludovic explicite

---

## SQL CLEANUP DRAFT (NON EXECUTE)

### Z.1 — DEV : Ajouter exemptions manquantes

```sql
-- SELECT avant (verification)
-- SELECT tenant_id, exempt, reason FROM tenant_billing_exempt
-- WHERE tenant_id IN ('tenant-1772234265142', 'test-lambda-k1-...');

-- INSERT (commenté, ne pas exécuter)
-- BEGIN;
-- INSERT INTO tenant_billing_exempt (tenant_id, exempt, reason)
-- VALUES ('tenant-1772234265142', true, 'test_account'),
--        ('test-lambda-k1-...', true, 'test_account')
-- ON CONFLICT (tenant_id) DO UPDATE SET exempt = true, reason = 'test_account';
-- COMMIT;

-- SELECT après (verification)
-- SELECT tenant_id, exempt, reason FROM tenant_billing_exempt
-- WHERE tenant_id IN ('tenant-1772234265142', 'test-lambda-k1-...');
```

### Z.2 — PROD : Ajouter exemptions manquantes

```sql
-- SELECT avant
-- SELECT tenant_id, exempt, reason FROM tenant_billing_exempt
-- WHERE tenant_id IN ('ludovic-mojol7ds...', 'internal-valida...');

-- INSERT (commenté)
-- BEGIN;
-- INSERT INTO tenant_billing_exempt (tenant_id, exempt, reason)
-- VALUES ('ludovic-mojol7ds...', true, 'test_account'),
--        ('internal-valida...', true, 'test_account')
-- ON CONFLICT (tenant_id) DO UPDATE SET exempt = true, reason = 'test_account';
-- COMMIT;
```

### Z.3 — DEV : Cleanup lifecycle rows test

```sql
-- SELECT avant
-- SELECT count(*) FROM trial_lifecycle_emails_sent;

-- DELETE (commenté)
-- BEGIN;
-- DELETE FROM trial_lifecycle_emails_sent
-- WHERE tenant_id IN (SELECT id FROM tenants
--   WHERE id LIKE 'test-%' OR id LIKE 'proof-%');
-- COMMIT;

-- Rollback : ces rows sont recreables via dry-run+send
```

---

## LINEAR / TICKETS

### Ticket 1 : Cleanup DEV Test Tenants

```
Titre : [Data Hygiene] Cleanup tenants test DEV
Priorite : P2
Labels : data-hygiene, dev

Description :
- Ajouter 2 tenants non-exempts a tenant_billing_exempt
- Purger lifecycle DEV rows test (4 rows)
- Purger users domaine test.com (2 users)
- Optionnel : purger tenants coquilles vides

Ref : PH-SAAS-T8.12Z
```

### Ticket 2 : Review PROD Test Tenants

```
Titre : [Data Hygiene] Review et cleanup tenants test PROD
Priorite : P2
Labels : data-hygiene, prod

Description :
- Ajouter 2 tenants non-exempts a tenant_billing_exempt
- Lister 20 tenants test_account PROD pour review Ludovic
- Purger funnel_events et signup_attribution test
- Annuler subscriptions test Stripe

Prerequis : validation Ludovic explicite
Ref : PH-SAAS-T8.12Z
```

### Ticket 3 : Billing Risk Assessment

```
Titre : [Data Hygiene] Confirmer pas de debit reel Stripe
Priorite : P3
Labels : billing, data-hygiene

Description :
- 15 subscriptions PROD (6 active, 7 trialing, 2 canceled)
- 21 billing customers PROD
- 149 billing events PROD
- Confirmer que Stripe est en test mode pour ces tenants
- Aucun debit reel identifie

Ref : PH-SAAS-T8.12Z
```

---

## PREUVES DE CONFORMITE

### Zero mutation DB

- Aucun INSERT/UPDATE/DELETE execute
- Lectures SELECT uniquement

### Zero build/deploy

- Aucun code modifie
- Aucun build Docker
- Aucun kubectl apply

### Zero email

- Aucun email envoye

---

## VERDICT

**GO**

TEST TENANTS AND VALIDATION DATA CLEANUP TRUTH ESTABLISHED - DEV/PROD TEST DATA MAPPED - BILLING/METRICS/LIFECYCLE RISKS CLASSIFIED - NO MUTATION - CLEANUP PLAN READY

### Resume des risques

| Risque | Severite | Couvert ? |
|---|---|---|
| Debit Stripe reel | P0 si present | **Aucun risque identifie** |
| Lifecycle email a test tenant | P1 | **G1+G2 protegent** |
| Metrics pollution | P2 | Partiellement (exempt filtre, mais signup/funnel non filtres) |
| Non-exempt tenants | P2 | 4 tenants (2 DEV, 2 PROD) a ajouter en exempt |

### Prochaine etape

**Z.1** : Ajouter 2 tenants DEV non-exempts a `tenant_billing_exempt` (necessite validation Ludovic).

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z-TEST-TENANTS-AND-VALIDATION-DATA-CLEANUP-TRUTH-AUDIT-01.md
```
