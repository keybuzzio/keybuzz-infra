# PH-SAAS-T8.12Z.5 - PROD Cleanup Targeted Backup Export

> Phase : PH-SAAS-T8.12Z.5-PROD-CLEANUP-TARGETED-BACKUP-EXPORT-01
> Date : 2026-05-03
> Type : Export backup cible, zero mutation
> Environnement : PROD (lecture seule)
> Prerequis : Z.4 (validation Ludovic)

---

## SOURCES RELUES

- `PH-SAAS-T8.12Z.4-PROD-CLEANUP-LUDOVIC-VALIDATION-PACK-01.md`
- `PH-SAAS-T8.12Z.3-PROD-TEST-DATA-CLEANUP-REVIEW-ONLY-01.md`
- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`

---

## VALIDATION LUDOVIC

Decision validee (transmise dans le prompt Z.5) :

| Code | Decision |
|---|---|
| C1-C11 | **SUPPRIMER** |
| C12 | **SUPPRIMER AVEC PRECAUTION** — conserver le user admin partage avec ecomlg-001 |

Contraintes absolues :
- Ne jamais toucher la row lifecycle Y.9B
- Ne jamais toucher ecomlg-001, switaa-mnc..., keybuzz-consulting
- Ne jamais toucher les tenants KEEP_PROOF
- Ne jamais supprimer le user partage C12/ecomlg-001

---

## PREFLIGHT

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `7fe1327` | Pre-existant (non lie) | **GO** |

| Service | Runtime attendu | Modifie ? |
|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | Non |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non |
| Admin PROD | baseline actuelle | Non |
| Website PROD | baseline actuelle | Non |

Confirme :
- Export-only, aucune mutation DB
- Aucun cleanup execute
- Aucun build/deploy

---

## ETAPE 1 — LISTE FIGEE C1-C12

| Code | Tenant masque | Domaine | Risque | Decision Ludovic |
|---|---|---|---|---|
| C1 | ecomlg-mn3r...#1 | gmail.com | Faible | SUPPRIMER |
| C2 | ecomlg-mn3r...#2 | gmail.com | Faible | SUPPRIMER |
| C3 | test-mnyy... | gmail.com | Faible | SUPPRIMER |
| C4 | ecomlg-mo45... | gmail.com | Faible | SUPPRIMER |
| C5 | tiktok-prod-test... | gmail.com | Faible | SUPPRIMER |
| C6 | tiktok-prod-v2... | gmail.com | Faible | SUPPRIMER |
| C7 | ludo-gonthier... | gmail.com | Faible | SUPPRIMER |
| C8 | ecomlg07-mo9... | gmail.com | Faible | SUPPRIMER |
| C9 | test-prod-w3lg... | gmail.com | Faible | SUPPRIMER |
| C10 | olyara-test-kb... | gmail.com | Faible | SUPPRIMER |
| C11 | test-codex-check... | gmail.com | Faible | SUPPRIMER |
| C12 | trial-autopilot... | keybuzz.pro | Moyen | SUPPRIMER AVEC PRECAUTION |

12 tenants confirmes. Aucun tenant DO_NOT_TOUCH ou KEEP_PROOF inclus.
C12 user partage confirme (admin = owner ecomlg-001).

---

## ETAPE 2 — ROW COUNTS AVANT EXPORT

| Table | Rows liees C1-C12 | Attendu Z.4 | Verdict |
|---|---|---|---|
| `tenants` | 12 | 12 | **OK** |
| `tenant_metadata` | 12 | 12 | **OK** |
| `tenant_settings` | 0 | 0 | **OK** |
| `tenant_billing_exempt` | 12 | 12 | **OK** |
| `user_tenants` | 13 | 13 | **OK** |
| `billing_customers` | 12 | 12 | **OK** |
| `billing_subscriptions` | 9 | 9 | **OK** |
| `billing_events` | 0 | 0 | **OK** |
| `ai_actions_wallet` | 12 | 12 | **OK** |
| `signup_attribution` | 7 | 7 | **OK** |
| `funnel_events` | 9 | 9 | **OK** |
| `conversion_events` | 1 | 1 | **OK** |
| `ad_spend_tenant` | 0 | 0 | **OK** |
| `trial_lifecycle_emails_sent` | **0** | **0** | **OK (Y.9B safe)** |
| `conversations` | 0 | 0 | **OK** |
| `messages` | 0 | 0 | **OK** |
| `orders` | 0 | 0 | **OK** |

Totaux PROD inchanges : 24 tenants, 1 lifecycle row (Y.9B), 24/24 exempts.

---

## ETAPE 3 — EXPORT BACKUP PROD

| Attribut | Valeur |
|---|---|
| **Chemin** | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-20260502-213434.sql` |
| **Taille** | 36 973 bytes (36 KB) |
| **SHA256** | `3088274f93c0f50f6260b2c88831fcfe9e2383d0987ede5c0c2bfd66c2eef4a9` |
| **Lignes** | 166 |
| **INSERT statements** | 99 |
| **Format** | SQL INSERT restaurables |
| **PII** | Oui (emails, noms) — **non commite dans Git** |
| **Secrets** | Aucun (0 sk_live, 0 sk_test, 0 password, 0 api_key) |

### Tables incluses dans le backup

| Table | Rows exportees |
|---|---|
| `tenants` | 12 |
| `tenant_metadata` | 12 |
| `tenant_billing_exempt` | 12 |
| `user_tenants` | 13 |
| `billing_customers` | 12 |
| `billing_subscriptions` | 9 |
| `ai_actions_wallet` | 12 |
| `signup_attribution` | 7 |
| `funnel_events` | 9 |
| `conversion_events` | 1 |
| **Total** | **99 rows** |

---

## ETAPE 4 — VALIDATION BACKUP

| Validation | Attendu | Resultat |
|---|---|---|
| Fichier existe | Oui | **OK** |
| Taille > 0 | Oui | **36 973 bytes** |
| SHA256 calcule | Oui | `3088274f...` |
| Contient C1-C12 (12 tenant IDs) | 12 IDs presents | **OK** (7-12 occurrences chacun) |
| Ne contient PAS ecomlg-001 | 0 occurrence | **OK** |
| Ne contient PAS switaa-sasu-mnc1 | 0 occurrence | **OK** |
| Ne contient PAS keybuzz-consulting (donnees) | 0 row exportee | **OK** (*) |
| Ne contient PAS Y.9B lifecycle row | 0 occurrence ludovic-mojol | **OK** |
| Ne contient PAS trial-welcome | 0 occurrence | **OK** |
| Ne contient PAS secrets | 0 sk_live/sk_test/password/api_key | **OK** |
| INSERT count = row count | 99 = 99 | **OK** |

(*) Note : `keybuzz-consulting-mo9z...` apparait 3 fois comme **reference** (`marketing_owner_tenant_id`) dans les donnees de C11. Ce ne sont PAS des rows du tenant keybuzz-consulting — uniquement des valeurs de foreign key dans les rows de C11. La suppression de C11 n'affectera pas keybuzz-consulting.

---

## ETAPE 5 — PLAN DE RESTAURATION

### Prerequis
- Acces bastion `install-v3` (46.62.171.61)
- Acces kubectl vers `keybuzz-api-prod`
- Fichier backup : `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-20260502-213434.sql`
- Verification SHA256 avant restauration

### Procedure de restauration (NON EXECUTEE)

```sql
-- 1. Verifier le backup
-- SHA256 attendu : 3088274f93c0f50f6260b2c88831fcfe9e2383d0987ede5c0c2bfd66c2eef4a9

-- 2. Dans une transaction
BEGIN;

-- 3. Re-inserer dans l'ordre (inverse du delete) :
--    a. tenants (12 rows)
--    b. tenant_metadata (12 rows)
--    c. tenant_billing_exempt (12 rows)
--    d. user_tenants (13 rows)
--    e. billing_customers (12 rows)
--    f. billing_subscriptions (9 rows)
--    g. ai_actions_wallet (12 rows)
--    h. signup_attribution (7 rows)
--    i. funnel_events (9 rows)
--    j. conversion_events (1 row)

-- 4. Valider
-- SELECT count(*) FROM tenants WHERE id = ANY('{...}'::text[]);
-- Attendu : 12

-- 5. Si OK
COMMIT;
-- Si NOK
-- ROLLBACK;
```

### Gestion des conflits
- Utiliser `INSERT ... ON CONFLICT DO NOTHING` si des rows ont ete partiellement restaurees
- Verifier FK integrity apres restauration

### Rollback de la restauration
- Si la restauration echoue : `ROLLBACK` (transaction non commitee)
- Si la restauration a ete commitee et doit etre annulee : re-executer le cleanup Z.6

---

## ETAPE 6 — PLAN Z.6 CLEANUP (NON EXECUTE)

### Ordre de suppression FK-safe

| Ordre | Table | Condition | Rows | Notes |
|---|---|---|---|---|
| 1 | `signup_attribution` | `tenant_id IN (C1..C12)` | 7 | Pas de FK downstream |
| 2 | `funnel_events` | `tenant_id IN (C1..C12)` | 9 | Pas de FK downstream |
| 3 | `conversion_events` | `tenant_id IN (C1..C12)` | 1 | Pas de FK downstream |
| 4 | `ai_actions_wallet` | `tenant_id IN (C1..C12)` | 12 | Pas de FK downstream |
| 5 | `billing_subscriptions` | `tenant_id IN (C1..C12)` | 9 | Cancel Stripe d'abord |
| 6 | `billing_customers` | `tenant_id IN (C1..C12)` | 12 | Apres subscriptions |
| 7 | `tenant_billing_exempt` | `tenant_id IN (C1..C12)` | 12 | Avant tenant |
| 8 | `tenant_metadata` | `tenant_id IN (C1..C12)` | 12 | Avant tenant |
| 9 | `user_tenants` | `tenant_id IN (C1..C12)` | 13 | **C12 : ne PAS supprimer le user partage** |
| 10 | `tenants` | `id IN (C1..C12)` | 12 | Dernier |

### Securites Z.6

```sql
BEGIN;

-- Verification pre-delete
SELECT count(*) FROM tenants WHERE id IN (...); -- attendu: 12
SELECT count(*) FROM conversations WHERE tenant_id IN (...); -- attendu: 0
SELECT count(*) FROM trial_lifecycle_emails_sent WHERE tenant_id IN (...); -- attendu: 0

-- Si un count != attendu : ROLLBACK immediatement

-- Deletions (ordre 1-10)
-- ...

-- Verification post-delete
SELECT count(*) FROM tenants; -- attendu: 12 (24-12)
SELECT count(*) FROM trial_lifecycle_emails_sent; -- attendu: 1 (Y.9B intacte)

-- Si tout OK : COMMIT
-- Sinon : ROLLBACK
```

### Precaution C12

Pour `user_tenants` de C12 :
- Supprimer les 2 rows `user_tenants` ou `tenant_id = 'trial-autopilot-vali-mol86nif'`
- **NE PAS** supprimer le user dont `user_id` est partage avec `ecomlg-001`
- La suppression de `user_tenants` ne supprime pas le user — c'est safe si on ne fait pas de `DELETE FROM users`
- Aucun `DELETE FROM users` dans le plan Z.6

---

## ETAPE 7 — NON-REGRESSION

| Check | Attendu | Resultat |
|---|---|---|
| Row counts C1-C12 identiques avant/apres | Identiques | **OK** (0 mutation) |
| API PROD health | OK | **OK** (pod running) |
| API PROD image | v3.5.135-lifecycle-pilot-safety-gates-prod | **Inchange** |
| Client PROD image | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | **Inchange** |
| Lifecycle CronJob | dry-run (`0 8 * * *`) | **Inchange** |
| TOTAL tenants PROD | 24 | **24** |
| TOTAL lifecycle PROD | 1 (Y.9B) | **1** |
| TOTAL exempt PROD | 24 | **24** |
| Emails envoyes | 0 | **0** |
| CAPI events | 0 | **0** |
| Billing events | 0 | **0** |
| Stripe mutations | 0 | **0** |
| Build/deploy | 0 | **0** |
| Code modifie | 0 | **0** |

---

## CONFIRMATION ZERO MUTATION

- Aucun INSERT/UPDATE/DELETE execute
- Aucun build/deploy
- Aucun email
- Aucune modification Stripe
- Aucune modification code/manifests
- PROD 100% inchangee
- Backup cree en lecture seule (SELECT uniquement)
- Backup non commite dans Git (contient PII)

---

## VERDICT

**GO**

PROD CLEANUP TARGETED BACKUP CREATED — C1-C12 EXPORT COMPLETE — RESTORE PLAN DOCUMENTED — Z.6 CLEANUP READY — NO MUTATION — NO CLEANUP EXECUTED — PROD RUNTIME UNCHANGED

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Z.5-PROD-CLEANUP-TARGETED-BACKUP-EXPORT-01.md
```

## CHEMIN DU BACKUP (bastion, PII, non commite)

```
/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-20260502-213434.sql
SHA256: 3088274f93c0f50f6260b2c88831fcfe9e2383d0987ede5c0c2bfd66c2eef4a9
```
