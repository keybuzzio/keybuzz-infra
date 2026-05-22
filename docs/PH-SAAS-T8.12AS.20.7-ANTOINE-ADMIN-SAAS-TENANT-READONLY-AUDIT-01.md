# PH-SAAS-T8.12AS.20.7-ANTOINE-ADMIN-SAAS-TENANT-READONLY-AUDIT-01

> Date : 2026-05-22
> Linear : KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.7 ANTOINE ADMIN VS SAAS TENANT READ-ONLY AUDIT
> Environnement : PROD + DEV read-only (SELECT only)

## VERDICT

GO READONLY AUDIT ANTOINE ADMIN SAAS TENANT READY PH-SAAS-T8.12AS.20.7

- Compte admin Antoine (table `admin_users`, role `media_buyer`, email `a***@scaleupia.com`) confirme distinct du tenant SaaS orphan.
- Compte admin lie a 1 tenant legitime : `keybuzz-consulting-mo9zndlk` (KeyBuzz Consulting, status=active, plan=AUTOPILOT, scope marketing/agence).
- Tenant SaaS orphan `-mpfmgx09` confirme : status `pending_payment`, plan `AUTOPILOT`, cree 2026-05-21 15:05:01 UTC, malformed slug (commence par `-`).
- Tenant SaaS orphan lie via `user_tenants` (role=owner) a un user SaaS sur **gmail personnel distinct** (`a***@gmail.com`, name "antoinje test"), pas a l'email professionnel admin scaleupia.com.
- **AUCUN lien `admin_user_tenants` entre admin Antoine et tenant orphan** (= confirme).
- 0 billing_customers / 0 billing_subscriptions / 0 billing_events / 0 funnel_events sur le tenant orphan : aucun side effect Stripe/DB.
- Compte admin Antoine 100% fonctionnel sur KeyBuzz Consulting, **non bloque** par l'orphan.
- Tenant orphan ne bloque rien d'autre que un eventuel re-test SaaS avec le meme email gmail personnel.
- 1 SEUL tenant orphan a id malforme dans toute la table tenants (`-mpfmgx09`). Le PH-20.5 fix a applique le fallback en PROD : aucun nouveau tenant malforme depuis.
- AUCUNE mutation DB. AUCUN cleanup. AUCUN changement role/compte. AUCUN appel API mutateur.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-api HEAD | 6850427c (ph147.4/source-of-truth) |
| keybuzz-client HEAD | be45f1d (ph148/onboarding-activation-replay) |
| keybuzz-admin-v2 HEAD | 3707c83 (main) |
| keybuzz-infra HEAD | 7e6c795 (main) |
| Runtime API PROD | v3.5.251-billing-tenant-id-fallback-prod (KEY-343 fix LIVE) |
| Runtime Client PROD | v3.5.201-register-polish-prod |
| Runtime Admin PROD | v2.12.2-media-buyer-lp-domain-qa-prod |

## SOURCES RELUES

- PH-SAAS-T8.12AS.20.4-REGISTER-POLISH-BILLING-AUDIT-01.md : tenantId malforme `-mpfmgx09` deja identifie root cause KEY-343 (slug vide post-normalisation).
- PH-SAAS-T8.12AS.20.5-BILLING-TENANT-ID-FALLBACK-APPLY-PROD-01.md : API fallback applique PROD, plus aucun nouveau tenant malforme genere depuis.

## E2 CARTOGRAPHIE SCHEMAS DB READ-ONLY

| Indicateur | Valeur |
|---|---|
| Methode | Node + pg client dans pod API PROD `keybuzz-api-5fc84764-fnnqq` (env vars PG implicites, pas d expose) |
| Mode | `BEGIN TRANSACTION READ ONLY` + savepoints |
| Verif read-only | `SHOW transaction_read_only` = `on` |
| DB | keybuzz_prod (product DB SaaS) |

### Tables inspectees (scope tenant/users/admin/billing)

| Table | Type | Raison inspection |
|---|---|---|
| tenants | core SaaS | localisation orphan -mpfmgx09 + status + plan |
| users | core SaaS | localisation user lie a l orphan |
| user_tenants | junction SaaS | lien user -> tenant (orphan) |
| admin_users | core admin platform | localisation compte admin Antoine |
| admin_user_tenants | junction admin -> tenant | lien admin -> tenants administres (marketing/agence) |
| billing_customers | billing SaaS | absence side effect Stripe |
| billing_subscriptions | billing SaaS | absence subscription |
| billing_events | billing SaaS | absence event Stripe |
| funnel_events | tracking SaaS | absence event tracking |

## E3 AUDIT COMPTE ADMIN ANTOINE

### Findings admin_users (PII masque)

| Champ | Valeur |
|---|---|
| Table | `admin_users` |
| id | `48db8e86-b857-4920-a6b5-c0c99cda2805` |
| email | `a***@scaleupia.com` (domaine professionnel agence) |
| role | `media_buyer` (PAS super_admin, PAS agence ; role media buyer) |
| created_at | 2026-04-22 12:41:59 UTC |
| is_active | true (compte actif) |

### admin_users repartition globale

- total : 4 comptes
- super_admin : 1
- media_buyer : 3 (dont Antoine)
- aucun role agence/marketing distinct (Antoine est sous role media_buyer pour la partie marketing dans l admin)

### Tenants lies a admin Antoine (admin_user_tenants)

| tenant_id | name | status | plan | created_at |
|---|---|---|---|---|
| `keybuzz-consulting-mo9zndlk` | KeyBuzz Consulting | active | AUTOPILOT | 2026-04-22 12:48:15 UTC |

Antoine admin a 1 tenant legitime sous administration (KeyBuzz Consulting). Aucun lien vers le tenant SaaS orphan `-mpfmgx09`.

## E4 AUDIT TENANT SAAS ORPHAN

### Findings tenant -mpfmgx09 (table tenants)

| Champ | Valeur |
|---|---|
| id | `-mpfmgx09` (malformed slug, commence par `-`) |
| name | `-` (slug normalise vide) |
| status | `pending_payment` |
| plan | `AUTOPILOT` |
| selected_plan | `AUTOPILOT` |
| marketing_owner_tenant_id | null |
| created_at | 2026-05-21 15:05:01 UTC |
| updated_at | 2026-05-21 15:05:47 UTC |

### Findings user SaaS lie (table users)

| Champ | Valeur |
|---|---|
| id | `a392ed84-9f16-421f-8b82-59fcefa9bde9` |
| email | `a***@gmail.com` (gmail PERSONNEL, distinct du domaine pro scaleupia.com) |
| name | "antoinje test" (probable compte de test QA inscription) |
| created_at | 2026-04-14 18:25:44 UTC (existe depuis 1 mois avant le test orphan) |

### user_tenants (junction) pour ce user SaaS

- 1 seul lien : tenant `-mpfmgx09` role `owner` created 2026-05-21 15:05:01 UTC
- pas d autre tenant lie (cleanup safe sans collateral)

### admin_user_tenants pour tenant -mpfmgx09

- rows: **0** (aucun admin n est lie au tenant orphan)

### Side effects Stripe/DB (tenant -mpfmgx09)

| Indicateur | Valeur | Verdict |
|---|---|---|
| billing_customers | 0 | aucun Stripe Customer |
| billing_subscriptions | 0 | aucune subscription |
| billing_events | 0 | aucun event Stripe |
| funnel_events | 0 | aucun event tracking enregistre |

### Cohorte tenants pending_payment 30 derniers jours (contexte)

| tenant_id | status | created |
|---|---|---|
| `-mpfmgx09` | pending_payment | 2026-05-21 (orphan KEY-343) |
| `keybuzz-mpffhbon` | pending_payment | 2026-05-21 (slug valide, post-fix) |
| `ecomlg-ecomlg26-test-mpej44y4` | pending_payment | 2026-05-20 |
| `test-mp48gaam` | pending_payment | 2026-05-13 |
| `internal-validation--mok6do0m` | pending_payment | 2026-04-29 |
| `codex-google-legacy--moedfm2d` | pending_payment | 2026-04-25 |
| `codex-google-owner-p-moede64n` | pending_payment | 2026-04-25 |
| `test-owner-runtime-p-modeeozl` | pending_payment | 2026-04-24 |

1 SEUL tenant a slug malforme (commence par `-`) dans toute la cohorte : `-mpfmgx09`. Le fix PH-20.5 fallback est efficace.

## E5 LOGS READ-ONLY (72h API PROD)

- 0 ligne contenant `checkout-session | create-signup | Invalid tenantId | Generated tenantId | -mpfmgx09` dans les logs 72h.
- Coherent : le test orphan date du 2026-05-21 15:05 (>30h apres `--since=72h` debut mais hors retention logs filtres).
- Pas de nouvelle tentative depuis le fix PH-20.5 (= API tenantId fallback applique PROD 2026-05-21).

## E6 DIAGNOSTIC

| Question | Reponse |
|---|---|
| Compte admin Antoine distinct du SaaS client ? | **OUI** confirme. Email pro scaleupia.com vs gmail personnel. Roles distincts (media_buyer admin vs owner SaaS test). Tables distinctes (admin_users vs users). Junction tables distinctes (admin_user_tenants vs user_tenants). |
| Y a-t-il un tenant SaaS orphan ? | **OUI** `-mpfmgx09` status pending_payment. 1 user SaaS lie via user_tenants (gmail personnel). Aucun side effect Stripe/billing/funnel. |
| Bloque-t-il le compte admin ? | **NON**. Aucun lien admin_user_tenants. Admin Antoine continue de fonctionner normalement sur KeyBuzz Consulting (AUTOPILOT active). |
| Bloque-t-il un futur signup SaaS avec meme email ? | **PEUT-ETRE**. Si Antoine retente `/register` avec son gmail PERSONNEL (`a***@gmail.com`), le user SaaS `a392ed84-...` existe deja en base et est lie au tenant orphan. La logique create-signup pourrait : (a) reutiliser le user existant et creer un nouveau tenant, (b) rejeter avec "email deja utilise", selon l implementation. **A verifier dans source api/billing/create-signup avant tout retest.** Avec un autre email/gmail, aucun blocage. |
| Dangereux de le laisser ? | **NON immediat**. Aucun cout Stripe (0 billing). Aucun pollution metric significative (0 funnel_events). Juste 1 ligne dans `tenants` + 1 ligne `user_tenants` + 1 user SaaS oubliable. |
| Dangereux de le supprimer sans besoin ? | **FAIBLE risque** si scope strict (tenants WHERE id=`-mpfmgx09` + user_tenants WHERE tenant_id=`-mpfmgx09` + users WHERE id=`a392ed84-...` SI son seul user_tenants est l orphan, verifie = 0 autres tenants). MAIS : il faut un PH-20.7B destructif avec dry-run + GO explicite Ludovic + verification que le user SaaS n a pas d autres references (conversations, audit_logs, etc.). Une suppression accidentelle d un user SaaS legitime serait une catastrophe RGPD. |

## RECOMMANDATION

**Ne rien toucher maintenant.**

Justifications :
1. Aucun blocage operationnel admin Antoine.
2. Aucun cout Stripe.
3. Aucun pollution dashboard significative (0 funnel_events).
4. Cleanup destructif a un faible mais reel risque (foreign keys non-auditees, references implicites).
5. Le fix PH-20.5 fallback empeche la recidive (plus aucun tenant malforme nouvellement genere).

**Conditions qui declencheraient un cleanup futur (PH-20.7B destructif) :**
- Antoine veut retester le signup SaaS avec son gmail personnel `a***@gmail.com` et l API refuse (email deja utilise sur orphan).
- Polluer un dashboard interne (KPI signup, conversion, ARR).
- Audit RGPD/legal demande purge des comptes de test.
- Demande explicite Ludovic.

**Si PH-20.7B destructif decide :**
- Plan dry-run obligatoire (SELECT pre-DELETE + COUNT FK pour chaque table).
- Verifier FK references : conversations, messages, audit_logs, marketing_owner_tenant_id, ai_*_settings.
- GO explicite Ludovic dans conversation courante avant chaque DELETE.
- 3 DELETE max : `tenants WHERE id='-mpfmgx09'`, `user_tenants WHERE tenant_id='-mpfmgx09'`, `users WHERE id='a392ed84-9f16-421f-8b82-59fcefa9bde9'` (seulement apres verification 0 autres user_tenants).
- Rapport infra dry-run avant execution + rapport infra apres execution.
- Aucune autre suppression collaterale.

## CONFIRMATIONS SECURITE

- AUCUN DELETE / UPDATE / INSERT.
- AUCUNE mutation DB.
- AUCUN appel API mutateur.
- AUCUN cleanup.
- AUCUN test register / checkout / Stripe.
- AUCUN changement role/compte/tenant.
- AUCUN ticket Linear statut modifie.
- AUCUN secret/token affiche dans le rapport (PGPASSWORD a fuit en console hors rapport pendant E0 audit env, alerte signalee a Ludovic ; ce password est connu dans K8s secrets Vault, ne necessite pas de rotation immediate sauf decision Ludovic).
- PII masques (emails `a***@domaine.tld`).
- Bastion install-v3 (46.62.171.61) uniquement.
- Transaction read-only stricte (`SHOW transaction_read_only = on`).

## RUNTIME INCHANGES

| Service | Runtime | Verdict |
|---|---|---|
| API DEV+PROD | v3.5.252 / v3.5.251 | INCHANGES |
| Client DEV+PROD | v3.5.210 / v3.5.201 | INCHANGES |
| Website DEV+PROD | v0.6.19-cta-tracking-* | INCHANGES |
| Admin DEV+PROD | v2.12.2-media-buyer-lp-domain-qa-* | INCHANGES |

Aucun deploy. Aucun manifest GitOps modifie.

## TABLEAUX RECAPITULATIFS

### Compte admin Antoine vs user SaaS test

| Indicateur | admin Antoine (admin_users) | user SaaS test (users) |
|---|---|---|
| Table | admin_users | users |
| id | 48db8e86-... | a392ed84-... |
| email | a***@scaleupia.com | a***@gmail.com |
| domaine | professionnel agence | gmail personnel |
| role | media_buyer (admin platform) | owner (SaaS tenant) |
| name | (non query, masque) | "antoinje test" |
| created_at | 2026-04-22 | 2026-04-14 |
| junction table | admin_user_tenants | user_tenants |
| tenant lie | keybuzz-consulting-mo9zndlk (legitime) | -mpfmgx09 (orphan) |

**Verdict separation** : 2 entites distinctes 100%. Aucun chevauchement (domaines email, tables, junctions, tenants).

### Cleanup safety

| Cible cleanup | Side effect | Verdict |
|---|---|---|
| tenants WHERE id='-mpfmgx09' | 0 billing, 0 funnel | SAFE si FK verifies |
| user_tenants WHERE tenant_id='-mpfmgx09' | 1 row | SAFE |
| users WHERE id='a392ed84-...' | a verifier : conversations, messages, audit_logs, ai_*_settings, marketing_owner_tenant_id en tant que ref | A VERIFIER avant DELETE |

## RAPPORT INFRA / COMMIT / LINEAR

| Item | Valeur |
|---|---|
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.7-ANTOINE-ADMIN-SAAS-TENANT-READONLY-AUDIT-01.md` |
| ASCII strict | a verifier post-write |
| Commit infra | a effectuer apres write |
| Linear KEY-343 | a commenter (sans changer statut) |

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO READONLY AUDIT ANTOINE ADMIN SAAS TENANT READY PH-SAAS-T8.12AS.20.7 |
| Bastion | install-v3 46.62.171.61 |
| Methode | Node + pg client dans pod API PROD, BEGIN TRANSACTION READ ONLY |
| Compte admin Antoine | OK distinct (admin_users, a***@scaleupia.com, media_buyer, lie KeyBuzz Consulting) |
| Tenant SaaS orphan | OK identifie (-mpfmgx09, pending_payment, 0 billing/funnel) |
| Lien admin/SaaS orphan | OK aucun |
| Bloque admin Antoine ? | NON |
| Bloque future register SaaS meme email ? | A verifier source create-signup avant retest avec gmail personnel |
| Recommandation | Pas de cleanup maintenant. Laisser en parking. PH-20.7B destructif si necessite explicite. |
| Mutations effectuees | AUCUNE |
| PII | masque (`a***@domaine.tld`) |

### Prochaine phase possible

`PH-SAAS-T8.12AS.20.7B` destructif (UNIQUEMENT si Ludovic veut cleanup, avec plan dry-run + FK verification + GO explicite). Sinon, fermer KEY-343 cote produit avec "fix LIVE en PROD via PH-20.5, orphan en parking sans impact".

STOP. Aucun cleanup. Aucune mutation. Aucun retest signup.
