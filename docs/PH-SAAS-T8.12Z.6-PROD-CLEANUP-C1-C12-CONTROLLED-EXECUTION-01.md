# PH-SAAS-T8.12Z.6 - PROD Cleanup C1-C12 Controlled Execution

> Phase : PH-SAAS-T8.12Z.6-PROD-CLEANUP-C1-C12-CONTROLLED-EXECUTION-01
> Date : 2026-05-03
> Type : Cleanup PROD destructif controle, transactionnel
> Environnement : PROD
> Prerequis : Z.4 (validation Ludovic), Z.5 (backup)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z.5-PROD-CLEANUP-TARGETED-BACKUP-EXPORT-01.md`
- `PH-SAAS-T8.12Z.4-PROD-CLEANUP-LUDOVIC-VALIDATION-PACK-01.md`
- `PH-SAAS-T8.12Z.3-PROD-TEST-DATA-CLEANUP-REVIEW-ONLY-01.md`
- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`

---

## VALIDATION LUDOVIC

| Code | Decision |
|---|---|
| C1-C11 | **SUPPRIMER** |
| C12 | **SUPPRIMER AVEC PRECAUTION** — conserver le user admin partage avec ecomlg-001 |

---

## PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `be07a7e` | Pre-existant (non lie) | **GO** |

| Service | Runtime attendu | Modifie ? |
|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | Non |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non |
| Admin PROD | baseline actuelle | Non |
| Website PROD | baseline actuelle | Non |

Phase destructive PROD. Backup disponible. Transaction obligatoire. Mutation limitee C1-C12.

---

## ETAPE 1 — VERIFICATION BACKUP Z.5

| Check backup | Attendu | Resultat |
|---|---|---|
| Fichier existe | Oui | **OK** |
| Taille | 36 973 bytes | **36 973 bytes** |
| SHA256 | `3088274f...` | **Identique** |
| INSERT count | 99 | **99** |
| ecomlg-001 | 0 occurrence | **0** |
| Y.9B lifecycle | 0 occurrence | **0** |
| Secrets | 0 | **0** |
| C1-C12 presents | 12 IDs | **OK** |

Backup Z.5 valide et integre.

### Backup supplementaire

Tables decouvertes lors de la premiere tentative transactionnelle (FK `cancel_reasons`) :

| Attribut | Valeur |
|---|---|
| Chemin | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-supplementary-20260503.sql` |
| Taille | 13 445 bytes |
| SHA256 | `8e49113feac9309d6152c7b94f6aa982228373bc1016bfdb3f917ff97030c602` |
| Tables | cancel_reasons (5), user_preferences (12), ai_actions_ledger (28), ai_credits_wallet (5) |
| Total rows | 50 |

---

## ETAPE 2 — CIBLE C1-C12 FIGEE

| Code | Tenant masque | Decision | Risque |
|---|---|---|---|
| C1 | ecomlg-mn3r...#1 | SUPPRIMER | Faible |
| C2 | ecomlg-mn3r...#2 | SUPPRIMER | Faible |
| C3 | test-mnyy... | SUPPRIMER | Faible |
| C4 | ecomlg-mo45... | SUPPRIMER | Faible |
| C5 | tiktok-prod-test... | SUPPRIMER | Faible |
| C6 | tiktok-prod-v2... | SUPPRIMER | Faible |
| C7 | ludo-gonthier... | SUPPRIMER | Faible |
| C8 | ecomlg07-mo9... | SUPPRIMER | Faible |
| C9 | test-prod-w3lg... | SUPPRIMER | Faible |
| C10 | olyara-test-kb... | SUPPRIMER | Faible |
| C11 | test-codex-check... | SUPPRIMER | Faible |
| C12 | trial-autopilot... | SUPPRIMER (precaution) | Moyen |

12 tenants. 0 DO_NOT_TOUCH. 0 KEEP_PROOF. C12 user partage confirme (uid: 43a1d34c...).

---

## ETAPE 3 — COUNTS AVANT MUTATION

| Table | Count C1-C12 avant | Attendu Z.5 | Verdict |
|---|---|---|---|
| `tenants` | 12 | 12 | **OK** |
| `cancel_reasons` | 5 | *(decouverte Z.6)* | **OK** |
| `tenant_metadata` | 12 | 12 | **OK** |
| `tenant_billing_exempt` | 12 | 12 | **OK** |
| `user_tenants` | 13 | 13 | **OK** |
| `user_preferences` | 12 | *(decouverte Z.6)* | **OK** |
| `billing_customers` | 12 | 12 | **OK** |
| `billing_subscriptions` | 9 | 9 | **OK** |
| `billing_events` | 0 | 0 | **OK** |
| `ai_actions_wallet` | 12 | 12 | **OK** |
| `ai_actions_ledger` | 28 | *(decouverte Z.6)* | **OK** |
| `ai_credits_wallet` | 5 | *(decouverte Z.6)* | **OK** |
| `signup_attribution` | 7 | 7 | **OK** |
| `funnel_events` | 9 | 9 | **OK** |
| `conversion_events` | 1 | 1 | **OK** |
| `trial_lifecycle_emails_sent` | **0** | **0** | **OK** |
| `conversations` | 0 | 0 | **OK** |
| `messages` | 0 | 0 | **OK** |
| `orders` | 0 | 0 | **OK** |

Totaux avant : 24 tenants, 1 lifecycle (Y.9B), 24 exempts.

---

## ETAPE 4 — PLAN DELETE FK-SAFE CORRIGE

### Premiere tentative et FK decouverte

La premiere tentative transactionnelle a echoue sur `cancel_reasons_tenant_id_fkey`. Analyse pg_constraint a revele 4 tables supplementaires avec des rows liees : `cancel_reasons` (FK), `user_preferences`, `ai_actions_ledger`, `ai_credits_wallet`.

Backup supplementaire cree avant la deuxieme tentative.

### Ordre de suppression corrige

| Ordre | Table | Action | Rows |
|---|---|---|---|
| 1 | `cancel_reasons` | DELETE | 5 |
| 2 | `signup_attribution` | DELETE | 7 |
| 3 | `funnel_events` | DELETE | 9 |
| 4 | `conversion_events` | DELETE | 1 |
| 5 | `ai_actions_ledger` | DELETE | 28 |
| 6 | `ai_credits_wallet` | DELETE | 5 |
| 7 | `ai_actions_wallet` | DELETE | 12 |
| 8 | `billing_subscriptions` | DELETE | 9 |
| 9 | `billing_customers` | DELETE | 12 |
| 10 | `user_preferences` | UPDATE SET NULL | 12 |
| 11 | `tenant_billing_exempt` | DELETE | 12 |
| 12 | `tenant_metadata` | DELETE | 12 |
| 13 | `user_tenants` | DELETE | 13 |
| 14 | `tenants` | DELETE | 12 |

**C12 precaution** : `user_tenants` supprime 2 rows pour C12 (1 owner + 1 admin). Le user admin partage avec ecomlg-001 n'est PAS supprime — aucun `DELETE FROM users` dans le plan. Le user conserve son association avec ecomlg-001.

---

## ETAPE 5 — ROWS SUPPRIMEES

| Table | Rows supprimees | Attendu | Verdict |
|---|---|---|---|
| `cancel_reasons` | 5 | 5 | **OK** |
| `signup_attribution` | 7 | 7 | **OK** |
| `funnel_events` | 9 | 9 | **OK** |
| `conversion_events` | 1 | 1 | **OK** |
| `ai_actions_ledger` | 28 | 28 | **OK** |
| `ai_credits_wallet` | 5 | 5 | **OK** |
| `ai_actions_wallet` | 12 | 12 | **OK** |
| `billing_subscriptions` | 9 | 9 | **OK** |
| `billing_customers` | 12 | 12 | **OK** |
| `user_preferences` (SET NULL) | 12 | 12 | **OK** |
| `tenant_billing_exempt` | 12 | 12 | **OK** |
| `tenant_metadata` | 12 | 12 | **OK** |
| `user_tenants` | 13 | 13 | **OK** |
| `tenants` | 12 | 12 | **OK** |
| **Total DELETE** | **137** | - | - |
| **Total UPDATE** | **12** | - | - |

---

## ETAPE 6 — VALIDATION PRE-COMMIT

| Validation | Attendu | Resultat |
|---|---|---|
| C1-C12 absents | 0 | **0** |
| Total tenants | 12 (24-12) | **12** |
| Lifecycle | 1 (Y.9B) | **1** |
| ecomlg-001 present | Oui | **Oui** |
| switaa-mnc... present | Oui | **Oui** |
| keybuzz-consulting present | Oui | **Oui** |
| 3/3 DO_NOT_TOUCH presents | Oui | **Oui** |
| User partage C12 dans ecomlg-001 | Oui | **Oui** |
| tenants.DELETE = 12 | 12 | **12** |

**COMMIT execute.**

---

## ETAPE 7 — VALIDATION POST-COMMIT

| Check | Attendu | Resultat |
|---|---|---|
| Total tenants PROD | 12 | **12** |
| C1-C12 restants | 0 | **0** |
| Lifecycle rows | 1 (Y.9B) | **1** |
| Exempt total | 12 | **12** |
| DO_NOT_TOUCH presents | 3/3 | **3/3** |
| User partage dans ecomlg-001 | 1 | **1** |

---

## ETAPE 8 — NON-REGRESSION PROD

| Surface | Attendu | Resultat |
|---|---|---|
| API PROD image | v3.5.135-lifecycle-pilot-safety-gates-prod | **Inchange** |
| Client PROD image | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | **Inchange** |
| API pod status | Running | **Running (1/1)** |
| Lifecycle CronJob | dry-run (`0 8 * * *`) | **Inchange** |
| ecomlg-001 conversations | ~486 | **486** |
| ecomlg-001 orders | ~11889 | **11 889** |
| ecomlg-001 user_tenants | 2 | **2** |
| Emails envoyes | 0 | **0** |
| CAPI events | 0 | **0** |
| Stripe mutations | 0 | **0** |
| Build/deploy | 0 | **0** |
| Code modifie | 0 | **0** |

### Tenants PROD restants (12)

| # | Tenant masque | Plan | Status | Classification |
|---|---|---|---|---|
| 1 | ecomlg-001 | PRO | active | **DO_NOT_TOUCH** |
| 2 | romruais... | starter | active | KEEP_EXEMPT |
| 3 | switaa-mn9... | AUTOPILOT | active | KEEP_EXEMPT |
| 4 | switaa-mnc... | AUTOPILOT | active | **DO_NOT_TOUCH** |
| 5 | compta-ecol... | starter | active | KEEP_EXEMPT |
| 6 | ecomlg-mo4h... | PRO | active | KEEP_EXEMPT |
| 7 | keybuzz-consult... | AUTOPILOT | active | **DO_NOT_TOUCH** |
| 8 | test-owner-runt... | PRO | pending | KEEP_PROOF |
| 9 | codex-google-own... | PRO | pending | KEEP_PROOF |
| 10 | codex-google-leg... | PRO | pending | KEEP_PROOF |
| 11 | ludovic-mojol... | PRO | active | KEEP_PROOF |
| 12 | internal-valid... | PRO | pending | KEEP_PROOF |

---

## ETAPE 9 — ROLLBACK DATA

### Backup principal Z.5

| Attribut | Valeur |
|---|---|
| Chemin | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-20260502-213434.sql` |
| SHA256 | `3088274f93c0f50f6260b2c88831fcfe9e2383d0987ede5c0c2bfd66c2eef4a9` |
| Rows | 99 INSERT (10 tables) |

### Backup supplementaire

| Attribut | Valeur |
|---|---|
| Chemin | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-supplementary-20260503.sql` |
| SHA256 | `8e49113feac9309d6152c7b94f6aa982228373bc1016bfdb3f917ff97030c602` |
| Rows | 50 INSERT (4 tables) |

### Procedure de restauration (NON EXECUTEE)

```sql
BEGIN;

-- 1. Restaurer depuis backup principal (ordre: tenants first, then children)
-- psql < prod-cleanup-c1-c12-20260502-213434.sql

-- 2. Restaurer depuis backup supplementaire
-- psql < prod-cleanup-c1-c12-supplementary-20260503.sql

-- 3. Restaurer user_preferences (UPDATE inverse)
-- UPDATE user_preferences SET current_tenant_id = '<original_value>'
-- WHERE user_id IN (SELECT user_id FROM user_tenants WHERE tenant_id IN (...));

-- 4. Valider
SELECT count(*) FROM tenants WHERE id = ANY('{...}'::text[]);
-- Attendu : 12 (re-crees)

COMMIT;
```

---

## CONFIRMATION

- Phase destructive executee en transaction
- COMMIT apres validation pre-commit reussie
- 137 rows supprimees + 12 rows mises a jour (user_preferences SET NULL)
- 12 tenants test supprimes
- 3 DO_NOT_TOUCH intacts (ecomlg-001, switaa-mnc, keybuzz-consulting)
- 5 KEEP_PROOF intacts
- 4 KEEP_EXEMPT intacts
- Row lifecycle Y.9B intacte
- User partage C12/ecomlg-001 intact
- API PROD, Client PROD, Admin PROD, Website PROD inchanges
- Aucun build, deploy, email, CAPI, Stripe event
- Backup restauration disponible

---

## VERDICT

**GO**

PROD CLEANUP C1-C12 COMPLETED — BACKUP VERIFIED — 12 EMPTY TENANTS REMOVED — SHARED USER PRESERVED — Y.9B PROOF PRESERVED — DO_NOT_TOUCH TENANTS INTACT — PROD HEALTHY — NO CODE — NO BUILD — NO DEPLOY

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.6-PROD-CLEANUP-C1-C12-CONTROLLED-EXECUTION-01.md
```
