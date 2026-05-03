# PH-SAAS-T8.12Z.7 — PROD Post-Cleanup Baseline & Integrity Verify

> **Date** : 3 mai 2026  
> **Type** : verification post-cleanup, lecture seule  
> **Environnement** : PROD  
> **Priorite** : P1  
> **Mutations** : 0

---

## SOURCES RELUES

| Document | Lu |
|---|:---:|
| `CE_PROMPTING_STANDARD.md` | via historique |
| `RULES_AND_RISKS.md` | via historique |
| `PH-SAAS-T8.12Z.3-...-REVIEW-ONLY-01.md` | via historique |
| `PH-SAAS-T8.12Z.4-...-VALIDATION-PACK-01.md` | via historique |
| `PH-SAAS-T8.12Z.5-...-BACKUP-EXPORT-01.md` | via historique |
| `PH-SAAS-T8.12Z.6-...-CONTROLLED-EXECUTION-01.md` | via historique |
| `PH-SAAS-T8.12Y.9D.1-...-RUNBOOK-01.md` | via historique |

---

## ETAPE 0 — PREFLIGHT

### Repo

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| `keybuzz-infra` | `main` | `732b3c9` (Z.6 rapport) | Non | OK |

### Runtimes (aucune modification)

| Service | Runtime attendu | Runtime reel | Modifie ? |
|---|---|---|:---:|
| API PROD | `v3.5.135-lifecycle-pilot-safety-gates-prod` | `v3.5.135-lifecycle-pilot-safety-gates-prod` | Non |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Non |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | `v2.11.37-acquisition-baseline-truth-prod` | Non |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | `v0.6.8-tiktok-browser-pixel-prod` | Non |

### Confirmations preflight

- Lecture seule : OUI
- Aucune mutation : OUI
- Cleanup Z.6 deja execute : OUI (3 mai 2026)
- Backups Z.5/Z.6 accessibles : OUI

---

## ETAPE 1 — BACKUPS DISPONIBLES

| Backup | Existe | Taille | SHA256 |
|---|:---:|---:|---|
| `prod-cleanup-c1-c12-20260502-213434.sql` | OUI | 36 973 o | `3088274f93c0f50f6260b2c88831fcfe9e2383d0987ede5c0c2bfd66c2eef4a9` |
| `prod-cleanup-c1-c12-supplementary-20260503.sql` | OUI | 13 445 o | `8e49113feac9309d6152c7b94f6aa982228373bc1016bfdb3f917ff97030c602` |

Chemin bastion : `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/`

SHA256 identiques aux valeurs documentees dans le rapport Z.5 et Z.6. Backups intacts.

---

## ETAPE 2 — TENANTS BASELINE POST-CLEANUP

### Counts globaux

| Categorie | Attendu | Resultat | Verdict |
|---|---:|---:|---|
| Total tenants PROD | 12 | **12** | OK |
| Total exempts | 12 | **12** | OK |
| C1-C12 restants | 0 | **0** | OK |
| DO_NOT_TOUCH presents | 3 | **3** | OK |
| KEEP_PROOF presents | 5 | **5** | OK |
| KEEP_EXEMPT presents | 4 | **4** | OK |

### Tenants PROD restants (12/12)

| # | Tenant (masque) | Plan | Status | Classification | Conv | Orders | Exempt |
|---|---|---|---|---|---:|---:|---|
| 1 | `ecomlg-***` | PRO | active | DO_NOT_TOUCH | 486 | 11889 | `internal_admin` |
| 2 | `switaa-sasu-mnc***` | AUTOPILOT | active | DO_NOT_TOUCH | 29 | 12 | `test_account` |
| 3 | `keybuzz-consulting-***` | AUTOPILOT | active | DO_NOT_TOUCH | 0 | 0 | `internal_admin` |
| 4 | `romruais-***` | starter | active | KEEP_EXEMPT | 1 | 0 | `test_account` |
| 5 | `switaa-sasu-mn9***` | AUTOPILOT | active | KEEP_EXEMPT | 6 | 2 | `test_account` |
| 6 | `compta-ecomlg-***` | starter | active | KEEP_EXEMPT | 3 | 0 | `test_account` |
| 7 | `ecomlg-mo4***` | PRO | active | KEEP_EXEMPT | 2 | 0 | `test_account` |
| 8 | `ludovic-moj***` | PRO | active | KEEP_PROOF | 0 | 0 | `test_account` |
| 9 | `internal-validation-***` | PRO | pending_payment | KEEP_PROOF | 0 | 0 | `test_account` |
| 10 | `test-owner-runtime-***` | PRO | pending_payment | KEEP_PROOF | 0 | 0 | `test_account` |
| 11 | `codex-google-owner-***` | PRO | pending_payment | KEEP_PROOF | 0 | 0 | `test_account` |
| 12 | `codex-google-legacy-***` | PRO | pending_payment | KEEP_PROOF | 0 | 0 | `test_account` |

Tous les 12 tenants restants sont exempts. Aucun tenant C1-C12 present.

---

## ETAPE 3 — USER PARTAGE C12 / ECOMLG

| Check | Attendu | Resultat | Verdict |
|---|---|---|---|
| User partage toujours present | OUI | **OUI** | OK |
| Lien `user_tenants` vers `ecomlg-001` | OUI (role: owner) | **OUI** (owner) | OK |
| Liens restants vers C12 supprime | 0 | **0** | OK |
| `ecomlg-001` fonctionnel logiquement | OUI | **OUI** | OK |

Le user partage (anciennement lie a C12 et ecomlg-001) est intact. Le lien vers C12 a ete correctement supprime en Z.6. Le lien owner vers ecomlg-001 est intact et unique.

---

## ETAPE 4 — INTEGRITE ORPHELINS

### Tables touchees par Z.6

| Table | Orphelins | Attendu | Verdict |
|---|---:|---|---|
| `tenant_metadata` | 0 | 0 | OK |
| `tenant_settings` | 0 | 0 | OK |
| `tenant_billing_exempt` | 0 | 0 | OK |
| `user_tenants` | 0 | 0 | OK |
| `signup_attribution` | 0 | 0 | OK |
| `funnel_events` | 0 | 0 | OK |
| `conversion_events` | 0 | 0 | OK |
| `ad_spend_tenant` | 0 | 0 | OK |
| `billing_subscriptions` | 0 | 0 | OK |
| `billing_customers` | 0 | 0 | OK |
| `cancel_reasons` | 0 | 0 | OK |
| `ai_actions_ledger` | 1 | pre-existant | MINEUR |
| `ai_credits_wallet` | 1 | pre-existant | MINEUR |
| `ai_actions_wallet` | 1 | pre-existant | MINEUR |
| `conversations` | 0 | 0 | OK |
| `orders` | 0 | 0 | OK |

### Autres orphelins non-critiques

| Surface | Count | Verdict |
|---|---:|---|
| `user_preferences` avec `current_tenant_id = NULL` | 12 | ATTENDU (Z.6 SET NULL) |
| Users sans aucun tenant (`users_no_tenant`) | 17 | PRE-EXISTANT (connu) |

### Verdict orphelins

- **0 orphelin critique** issu de Z.6
- 3 orphelins mineurs pre-existants (`ai_*`) : non bloquants, non lies a Z.6
- 12 `user_preferences` NULL : resultat attendu de Z.6 (UPDATE SET NULL pour preserver users)
- 17 users sans tenant : pre-existant, documente dans la dette technique (D-ORPHANS)

---

## ETAPE 5 — LIFECYCLE POST-CLEANUP

| Check lifecycle | Attendu | Resultat | Verdict |
|---|---|---|---|
| Row Y.9B presente | 1 | **1** | OK |
| Tenant Y.9B | `ludovic-***` | `ludovic-moj***` | OK |
| Template Y.9B | `trial-welcome` | `trial-welcome` | OK |
| Date envoi Y.9B | 2026-05-02 | **2026-05-02** | OK |
| Total `trial_lifecycle_emails_sent` | 1 | **1** | OK |
| CronJob `trial-lifecycle-dryrun` | actif | **actif** (0 8 * * *, suspend=false) | OK |
| `lifecycle_email_optout` | 0 | **0** | OK |
| Emails envoyes depuis Y.9B | 0 | **0** (dry-run only) | OK |

La row Y.9B est intacte. Le CronJob lifecycle dry-run est actif. Aucun email reel envoye.

---

## ETAPE 6 — METRICS / ATTRIBUTION POST-CLEANUP

| Surface | Count | Verdict |
|---|---:|---|
| `signup_attribution` | 5 | OK (tenants restants uniquement) |
| `conversion_events` | 1 | OK |
| `ad_spend_tenant` | 18 | OK (spend reel Meta/Google intact) |

- Aucune donnee de spend reel Meta/Google n'a ete supprimee (les tenants C1-C12 n'avaient pas de spend reel)
- Les attributions restantes concernent les tenants DO_NOT_TOUCH / KEEP_PROOF / KEEP_EXEMPT
- Acquisition baseline inchangee

---

## ETAPE 7 — FUNNEL / ONBOARDING POST-CLEANUP

| Surface | Count | Verdict |
|---|---:|---|
| `funnel_events` total | 51 | OK |
| `funnel_events` avec tenant | 10 | OK (tenants restants) |
| `funnel_events` sans tenant (pre-signup) | 41 | OK (normal) |

- Events lies aux tenants supprimes : **absents** (confirme par orphan check = 0)
- Ecomlg/proofs intacts
- Onboarding/sample demo logique non affectee

---

## ETAPE 8 — BILLING POST-CLEANUP

| Billing surface | Count | Risque |
|---|---:|---|
| `billing_customers` | 9 | Aucun |
| `billing_subscriptions` | 6 | Aucun |
| dont `active` | 3 | Aucun |
| dont `trialing` | 1 | Aucun |
| dont `canceled` | 2 | Aucun |
| `billing_events` | 149 | Aucun |

- 0 orphelins billing (customers/subscriptions sans tenant = 0)
- Aucun risque de debit reel : les subscriptions restantes sont liees aux tenants existants
- Ecomlg billing intact
- Les tenants supprimes n'avaient pas de subscriptions Stripe actives residuelles

---

## ETAPE 9 — NON-REGRESSION RUNTIME

| Surface | Attendu | Resultat | Verdict |
|---|---|---|---|
| API PROD image | `v3.5.135-lifecycle-pilot-safety-gates-prod` | identique | OK |
| Client PROD image | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | identique | OK |
| Admin PROD image | `v2.11.37-acquisition-baseline-truth-prod` | identique | OK |
| Website PROD image | `v0.6.8-tiktok-browser-pixel-prod` | identique | OK |
| API pod status | Running 1/1 | Running 1/1 | OK |
| CronJob `outbound-tick-processor` | actif | actif (*/1, suspend=false) | OK |
| CronJob `sla-evaluator` | actif | actif (*/1, suspend=false) | OK |
| CronJob `trial-lifecycle-dryrun` | actif | actif (0 8, suspend=false) | OK |
| Emails envoyes | 0 | 0 | OK |
| CAPI events | 0 | 0 | OK |
| Tracking events | 0 | 0 | OK |
| Stripe events mutes | 0 | 0 | OK |

Aucun runtime modifie. Aucun side effect.

---

## ETAPE 10 — BASELINE DATA HYGIENE FINALE

| Domaine | Nouvelle valeur |
|---|---:|
| Tenants PROD | **12** |
| Exempt tenants | **12** |
| DO_NOT_TOUCH | **3** |
| KEEP_PROOF | **5** |
| KEEP_EXEMPT | **4** |
| Cleanup candidates restants | **0** |
| Lifecycle rows | **1** (Y.9B) |
| `signup_attribution` | **5** |
| `funnel_events` | **51** (10 tenant, 41 null) |
| `conversion_events` | **1** |
| `ad_spend_tenant` | **18** |
| `billing_events` | **149** |
| `billing_customers` | **9** |
| `billing_subscriptions` | **6** (3 active, 1 trialing, 2 canceled) |
| Eligible external lifecycle | **0** (dry-run) |
| Users sans tenant | **17** (pre-existant) |
| Orphelins critiques | **0** |

---

## ETAPE 11 — GAPS RESTANTS

### Ce qu'on garde volontairement

| Element | Raison |
|---|---|
| 12 tenants (3 DNT + 5 KP + 4 KE) | Production active ou preuve technique necessaire |
| 17 users sans tenant | Pre-existant (D-ORPHANS), hors scope Z.6 |
| 3 orphelins mineurs `ai_*` | Pre-existants, non bloquants, non lies a Z.6 |
| 12 `user_preferences` NULL | Resultat attendu de Z.6 (preservation users) |
| 41 funnel_events sans tenant | Events pre-signup (normal, pas des orphelins) |

### Ce qu'il ne faut PAS supprimer

| Element | Raison |
|---|---|
| Backups Z.5 | Seule restauration possible si probleme decouvert |
| Row Y.9B lifecycle | Preuve premier email lifecycle |
| Tenants KEEP_PROOF | Preuves techniques (onboarding, OAuth, TikTok, Stripe) |
| Tenants DO_NOT_TOUCH | Production active (ecomlg, switaa, keybuzz-consulting) |
| Spend reel `ad_spend_tenant` | Donnees Meta/Google reelles |

### Cleanup futur necessaire ?

| Question | Reponse |
|---|---|
| Un cleanup futur est-il encore utile ? | **NON** — 0 cleanup candidates restants |
| Les 17 users orphelins meritent-ils un cleanup ? | Oui, mais dans un sprint D-ORPHANS dedie, pas dans cette serie |
| Les 3 orphelins `ai_*` ? | Negligeables, cleanup optionnel si sprint dedie |
| KEEP_PROOF tenants a terme ? | Evaluable dans 90j — si plus necessaires comme preuve |

### Conservation des backups

| Backup | Conservation recommandee |
|---|---|
| `prod-cleanup-c1-c12-20260502-213434.sql` | **90 jours minimum** (jusqu'au 1er aout 2026) |
| `prod-cleanup-c1-c12-supplementary-20260503.sql` | **90 jours minimum** (jusqu'au 1er aout 2026) |

Apres 90 jours, les backups peuvent etre archives ou supprimes si aucun probleme n'a ete detecte.

---

## CONFIRMATION FINALE

- **Mutations** : 0
- **Builds/deploys** : 0
- **Emails** : 0
- **Stripe events** : 0
- **Backups restaures** : 0

---

## VERDICT

**PROD POST-CLEANUP BASELINE VERIFIED — 12 TENANTS REMAIN — DO_NOT_TOUCH/KEEP_PROOF/KEEP_EXEMPT INTACT — NO ORPHAN CRITICAL — LIFECYCLE DRY-RUN CLEAN — METRICS/BILLING/FUNNEL CONSISTENT — NO MUTATION**

---

*Rapport : `keybuzz-infra/docs/PH-SAAS-T8.12Z.7-PROD-POST-CLEANUP-BASELINE-AND-INTEGRITY-VERIFY-01.md`*
