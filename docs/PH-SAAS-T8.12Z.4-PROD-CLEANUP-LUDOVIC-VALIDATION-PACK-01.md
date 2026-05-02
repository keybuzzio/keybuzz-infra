# PH-SAAS-T8.12Z.4 - PROD Cleanup Ludovic Validation Pack

> Phase : PH-SAAS-T8.12Z.4-PROD-CLEANUP-LUDOVIC-VALIDATION-PACK-01
> Date : 2026-05-03
> Type : Dossier de decision, zero mutation
> Environnement : PROD (lecture seule)
> Prerequis : Z (audit), Z.1 (exemptions), Z.2 (DEV cleanup), Z.3 (PROD review)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z-TEST-TENANTS-AND-VALIDATION-DATA-CLEANUP-TRUTH-AUDIT-01.md`
- `PH-SAAS-T8.12Z.1-TENANT-BILLING-EXEMPTIONS-DEV-PROD-PROTECTION-01.md`
- `PH-SAAS-T8.12Z.3-PROD-TEST-DATA-CLEANUP-REVIEW-ONLY-01.md`
- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`

---

## PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `0c1451e` | Non | **GO** |

| Service | Runtime attendu | Modifie ? |
|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | Non |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non |
| Admin PROD | v1.0.2 | Non |
| Website PROD | v0.5.1-ph3317b-prod-links | Non |

Confirme :
- Review-only, aucune mutation DB
- Aucun cleanup execute
- Aucun build/deploy

---

## ETAPE 1 — LES 12 CANDIDATS CLEANUP

### Tableau principal

| # | Tenant masque | Label | Domaine | Cree le | Plan | Status | Conv | Orders | Users | Billing sub | BE | Attr | Funnel | ConvEv | Spend | Lifecycle | Reco CE |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| C1 | ecomlg-mn3r...#1 | eComLG (test starter) | gmail.com | 2026-03-23 | starter | active | 0 | 0 | 1 | canceled | 0 | 0 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C2 | ecomlg-mn3r...#2 | eComLG (test PRO) | gmail.com | 2026-03-23 | PRO | pending_payment | 0 | 0 | 1 | - | 0 | 0 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C3 | test-mnyy... | test (PRO) | gmail.com | 2026-04-14 | PRO | pending_payment | 0 | 0 | 1 | - | 0 | 0 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C4 | ecomlg-mo45... | eComLG (test PRO) | gmail.com | 2026-04-18 | PRO | active | 0 | 0 | 1 | active | 0 | 0 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C5 | tiktok-prod-test... | TikTok PROD Test SAS | gmail.com | 2026-04-19 | PRO | pending_payment | 0 | 0 | 1 | - | 0 | 0 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C6 | tiktok-prod-v2... | TikTok PROD V2 SAS | gmail.com | 2026-04-19 | PRO | active | 0 | 0 | 1 | trialing | 0 | 1 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C7 | ludo-gonthier... | GA4MP Final test | gmail.com | 2026-04-19 | PRO | active | 0 | 0 | 1 | trialing | 0 | 1 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C8 | ecomlg07-mo9... | ecomlg07 | gmail.com | 2026-04-21 | PRO | active | 0 | 0 | 1 | trialing | 0 | 1 | 0 | 0 | 0 | 0 | **SUPPRIMER** |
| C9 | test-prod-w3lg... | Test PROD - W3LG | gmail.com | 2026-04-24 | PRO | active | 0 | 0 | 1 | trialing | 0 | 1 | 2 | 0 | 0 | 0 | **SUPPRIMER** |
| C10 | olyara-test-kb... | Olyara TEST KB | gmail.com | 2026-04-24 | AUTO | active | 0 | 0 | 1 | trialing | 0 | 1 | 4 | 0 | 0 | 0 | **SUPPRIMER** |
| C11 | test-codex-check... | Test Codex Checkout | gmail.com | 2026-04-25 | PRO | active | 0 | 0 | 1 | trialing | 0 | 1 | 2 | 1 | 0 | 0 | **SUPPRIMER** |
| C12 | trial-autopilot... | Trial Autopilot Validation J | keybuzz.pro | 2026-04-30 | STARTER | active | 0 | 0 | 2 | trialing | 0 | 1 | 1 | 0 | 0 | 0 | **ARBITRAGE** |

### Legende colonnes

- **Conv** : conversations
- **BE** : billing_events (via subscription join)
- **Attr** : signup_attribution
- **ConvEv** : conversion_events
- **Spend** : ad_spend_tenant

### Constats globaux

- **12/12** ont 0 conversations, 0 orders, 0 messages
- **12/12** ont 0 billing_events
- **12/12** ont 0 lifecycle rows (safe, aucune preuve Y.9B impliquee)
- **12/12** sont exempt=true dans `tenant_billing_exempt`
- **9/12** ont une billing_subscription (7 trialing, 1 canceled, 1 active Stripe test)
- **7/12** ont 1 signup_attribution (test)
- **3/12** ont des funnel_events (2, 4, 2 rows)
- **1/12** a 1 conversion_event (C11)
- **1/12** a un **utilisateur partage avec ecomlg-001** (C12)

---

## ETAPE 2 — DETAIL RISQUE PAR TENANT

| Tenant | Risque | Preuve PH | Billing | Ads/Spend | Lifecycle | User partage | Recommandation CE |
|---|---|---|---|---|---|---|---|
| C1 ecomlg-mn3r...#1 | **Faible** | Non | canceled, 0 events | Non | Non | Non | Suppression safe |
| C2 ecomlg-mn3r...#2 | **Faible** | Non | Aucune sub | Non | Non | Non | Suppression safe |
| C3 test-mnyy... | **Faible** | Non | Aucune sub | Non | Non | Non | Suppression safe |
| C4 ecomlg-mo45... | **Faible** | Non | active (Stripe test) | Non | Non | Non | Suppression safe, cancel Stripe avant |
| C5 tiktok-prod-test... | **Faible** | Non | Aucune sub | Non | Non | Non | Suppression safe |
| C6 tiktok-prod-v2... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C7 ludo-gonthier... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C8 ecomlg07-mo9... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C9 test-prod-w3lg... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C10 olyara-test-kb... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C11 test-codex-check... | **Faible** | Non | trialing, 0 events | Non | Non | Non | Suppression safe |
| C12 trial-autopilot... | **Moyen** | Non directement | trialing, 0 events | Non | Non | **OUI (ecomlg-001)** | Arbitrage : user partage |

### Detail C12 — Risque utilisateur partage

Le tenant C12 (`trial-autopilot-vali...`) a **2 utilisateurs** :
- 1 owner (int***@keybuzz.pro)
- 1 admin = **meme user_id que le owner de ecomlg-001**

Si le tenant C12 est supprime, la suppression de `user_tenants` pour ce tenant est safe (l'utilisateur conserve son association avec `ecomlg-001`). Mais il faut **imperativement ne PAS supprimer le user lui-meme** — uniquement la ligne `user_tenants` pour C12.

**Recommendation CE** : suppression possible si le script respecte l'ordre FK et ne cascade pas la suppression de l'utilisateur. Besoin d'arbitrage Ludovic.

---

## ETAPE 3 — DONNEES LIEES PAR TABLE

### Rows par table pour les 12 candidats

| Table | Rows liees | Tenants concernes | Suppression proposee ? | Risque |
|---|---|---|---|---|
| `tenants` | 12 | C1-C12 | Oui (dernier) | FK cascading |
| `tenant_metadata` | 12 | C1-C12 | Oui | Aucun (metadata test) |
| `tenant_settings` | 0 | - | N/A | - |
| `tenant_billing_exempt` | 12 | C1-C12 | Oui (avant tenant) | Aucun |
| `user_tenants` | 13 | C1-C12 (C12 a 2 rows) | Oui | **C12 user partage** |
| `users` | 0 a supprimer | - | Non (users partages) | - |
| `billing_customers` | 12 | C1-C12 | Oui | Aucun (Stripe test) |
| `billing_subscriptions` | 9 | C1,C4,C6-C12 | Oui (cancel Stripe d'abord) | Stripe test mode |
| `billing_events` | 0 | - | N/A | - |
| `signup_attribution` | 7 | C6-C12 | Oui | Test data |
| `funnel_events` | 9 | C9(2), C10(4), C11(2), C12(1) | Oui | Test data |
| `conversion_events` | 1 | C11 | Oui | Test data |
| `ad_spend_tenant` | 0 | - | N/A | - |
| `ai_actions_wallet` | 12 | C1-C12 | Oui | Test wallets |
| `trial_lifecycle_emails_sent` | **0** | - | N/A | **SAFE (Y.9B non implique)** |

### Controles de securite

- **trial_lifecycle_emails_sent** : 0 rows pour les 12 candidats. La row Y.9B (`ludovic-mojol...`) est sur un tenant KEEP_PROOF, non concerne. **Aucun risque.**
- **billing_events** : 0 rows liees via subscription_id pour les 12 candidats. Les 149 billing_events PROD totales sont sur d'autres tenants (KEEP_PROOF/KEEP_EXEMPT).
- **Utilisateurs** : Aucun user ne sera orpheline si on ne supprime que les `user_tenants` rows. La plupart des owners PROD ont d'autres tenants. C12 a un user partage avec ecomlg-001 (a ne PAS supprimer).

### Ordre de suppression FK-safe

```
1. signup_attribution      (7 rows, pas de FK downstream)
2. funnel_events           (9 rows, pas de FK downstream)
3. conversion_events       (1 row, pas de FK downstream)
4. ai_actions_wallet       (12 rows)
5. billing_subscriptions   (9 rows, cancel Stripe d'abord)
6. billing_customers       (12 rows)
7. tenant_billing_exempt   (12 rows)
8. tenant_metadata         (12 rows)
9. user_tenants            (13 rows, ne PAS supprimer le user partage)
10. tenants                (12 rows, dernier)
```

---

## ETAPE 4 — PROPOSITION DE DECISION

### Liste A — Suppression recommandee (11 tenants)

Tenants quasi vides, 0 conversations, 0 orders, 0 preuve PH, billing non risque.

| # | Tenant masque | Raison suppression |
|---|---|---|
| C1 | ecomlg-mn3r...#1 | Coquille vide, sub canceled, 0 donnees |
| C2 | ecomlg-mn3r...#2 | Coquille vide, pending_payment, 0 donnees |
| C3 | test-mnyy... | Coquille vide, pending_payment, 0 donnees |
| C4 | ecomlg-mo45... | Coquille vide, sub active (Stripe test), 0 donnees |
| C5 | tiktok-prod-test... | Coquille vide, pending_payment, 0 donnees |
| C6 | tiktok-prod-v2... | Coquille vide, 1 signup attr test |
| C7 | ludo-gonthier... | Coquille vide, 1 signup attr test (GA4MP) |
| C8 | ecomlg07-mo9... | Coquille vide, 1 signup attr test |
| C9 | test-prod-w3lg... | Coquille vide, 1 signup + 2 funnel test |
| C10 | olyara-test-kb... | Coquille vide, 1 signup + 4 funnel test |
| C11 | test-codex-check... | Coquille vide, 1 signup + 2 funnel + 1 conversion test |

### Liste B — Garder pour preuve / audit

Aucun des 12 candidats n'est directement lie a une preuve PH critique.

> Note : les preuves PH (Y.9B lifecycle, codex validation, T8.10J signup) sont sur les tenants KEEP_PROOF, qui ne font PAS partie de ces 12 candidats.

### Liste C — Arbitrage Ludovic (1 tenant)

| # | Tenant masque | Raison arbitrage |
|---|---|---|
| C12 | trial-autopilot... | **Utilisateur admin partage avec ecomlg-001**. Suppression du tenant safe si on ne supprime que user_tenants (pas le user). Mais besoin confirmation Ludovic car c'est le seul tenant avec un lien vers le tenant pilote. |

---

## ETAPE 5 — BLOC DE REPONSE LUDOVIC

Copier-coller ce bloc et completer chaque ligne avec SUPPRIMER / GARDER / BESOIN INFO :

```
Validation Ludovic — PH-SAAS-T8.12Z.4

C1  (ecomlg-mn3r...#1, starter, canceled, 0 data)       : SUPPRIMER / GARDER / BESOIN INFO
C2  (ecomlg-mn3r...#2, PRO, pending, 0 data)            : SUPPRIMER / GARDER / BESOIN INFO
C3  (test-mnyy..., PRO, pending, 0 data)                : SUPPRIMER / GARDER / BESOIN INFO
C4  (ecomlg-mo45..., PRO, active sub test, 0 data)      : SUPPRIMER / GARDER / BESOIN INFO
C5  (tiktok-prod-test..., PRO, pending, 0 data)         : SUPPRIMER / GARDER / BESOIN INFO
C6  (tiktok-prod-v2..., PRO, trialing, 1 signup)        : SUPPRIMER / GARDER / BESOIN INFO
C7  (ludo-gonthier..., PRO, trialing, 1 signup GA4MP)   : SUPPRIMER / GARDER / BESOIN INFO
C8  (ecomlg07-mo9..., PRO, trialing, 1 signup)          : SUPPRIMER / GARDER / BESOIN INFO
C9  (test-prod-w3lg..., PRO, trialing, 1 signup+funnel) : SUPPRIMER / GARDER / BESOIN INFO
C10 (olyara-test-kb..., AUTO, trialing, 1 signup+funnel): SUPPRIMER / GARDER / BESOIN INFO
C11 (test-codex-check..., PRO, trialing, conversion)    : SUPPRIMER / GARDER / BESOIN INFO
C12 (trial-autopilot..., STARTER, user partage ecomlg)  : SUPPRIMER / GARDER / BESOIN INFO

Commentaires :
-
```

### Aide a la decision

- **C1-C5** : Aucune donnee liee, suppression sans risque.
- **C6-C8** : 1 signup_attribution test chacun, suppression tres faible risque.
- **C9-C11** : Donnees funnel/conversion test, suppression faible risque.
- **C12** : Seul cas avec un utilisateur partage avec ecomlg-001. Le tenant lui-meme n'a aucune donnee. Le user admin ne sera PAS supprime — seule l'association `user_tenants` sera retiree.

---

## ETAPE 6 — PLAN Z.5 / Z.6 CONDITIONNEL

### Z.5 — Backup/export PROD cible

| Aspect | Detail |
|---|---|
| **Declencheur** | Ludovic valide les tenants a supprimer |
| **Mutation** | Non (export SELECT uniquement) |
| **Prerequis** | Z.4 valide par Ludovic |
| **Scope** | Export SQL complet des 10 tables pour chaque tenant valide |
| **Format** | JSON masque PII, stocke dans `keybuzz-infra/docs/exports/` |
| **Contenu** | tenants, tenant_metadata, tenant_billing_exempt, user_tenants, billing_customers, billing_subscriptions, signup_attribution, funnel_events, conversion_events, ai_actions_wallet |

### Z.6 — Cleanup PROD controle

| Aspect | Detail |
|---|---|
| **Declencheur** | Z.5 fait et verifie |
| **Mutation** | Oui (DELETE dans transaction) |
| **Prerequis** | Z.5 export complet, rollback documente |
| **Scope** | Suppression FK-safe des tenants valides |
| **Securites** | Transaction PostgreSQL, SELECT count avant/apres, ROLLBACK si ecart |
| **Stripe** | Cancel subscriptions test AVANT delete DB |
| **Rollback** | Re-INSERT depuis export Z.5 |

### Tableau recapitulatif

| Phase | Declencheur | Mutation | Prerequis |
|---|---|---|---|
| Z.5 — Export backup | Ludovic valide Z.4 | Non | Z.4 valide |
| Z.6 — Cleanup PROD | Z.5 export fait | Oui (transaction) | Z.5 verifie, rollback documente |

### Estimation rows Z.6

| Table | Rows a supprimer (si 12/12 valides) |
|---|---|
| signup_attribution | 7 |
| funnel_events | 9 |
| conversion_events | 1 |
| ai_actions_wallet | 12 |
| billing_subscriptions | 9 |
| billing_customers | 12 |
| tenant_billing_exempt | 12 |
| tenant_metadata | 12 |
| user_tenants | 13 |
| tenants | 12 |
| **Total** | **~99 rows** |

---

## CONFIRMATION ZERO MUTATION

- Aucun INSERT/UPDATE/DELETE execute
- Aucun build/deploy
- Aucun email
- Aucune modification Stripe
- Aucune modification code/manifests
- Aucune modification `tenant_billing_exempt`
- Aucune modification `trial_lifecycle_emails_sent`
- Aucune modification `signup_attribution`
- Aucune modification `funnel_events`
- Aucune modification `billing_*`
- PROD 100% inchangee

---

## VERDICT

**GO**

PROD CLEANUP VALIDATION PACK READY — 12 CANDIDATE TENANTS DETAILED — RISKS AND RECOMMENDATIONS DOCUMENTED — LUDOVIC APPROVAL REQUIRED — NO MUTATION — NO CLEANUP EXECUTED

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.4-PROD-CLEANUP-LUDOVIC-VALIDATION-PACK-01.md
```
