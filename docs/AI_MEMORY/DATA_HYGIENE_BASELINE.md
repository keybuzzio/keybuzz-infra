# Data Hygiene Baseline — PROD

> Date de baseline : **2026-05-03**
> Contexte : post PH-SAAS-T8.12Z.7
> Phase de cloture : PH-SAAS-T8.12Z.8
> Statut : **LOCKED**

---

## 1. BASELINE PROD POST-CLEANUP

| Domaine | Valeur |
|---|---:|
| Tenants PROD | **12** |
| Exempts | **12/12** |
| C1-C12 supprimes | **12/12** |
| Orphelins critiques | **0** |
| Lifecycle Y.9B | **conservee** |
| Cleanup candidates restants | **0** |

---

## 2. CLASSIFICATION DES TENANTS RESTANTS

### DO_NOT_TOUCH (3) — ne jamais supprimer sans validation explicite Ludovic

| Tenant masque | Plan | Raison |
|---|---|---|
| `ecomlg-***` | PRO | Production active, tenant pilote, 486 convos, 11889 orders |
| `switaa-sasu-mnc***` | AUTOPILOT | Vrai compte client Autopilot, 29 convos, 12 orders |
| `keybuzz-consulting-***` | AUTOPILOT | Entite interne KeyBuzz Consulting |

### KEEP_PROOF (5) — preuves techniques, reevaluable dans 90 jours

| Tenant masque | Plan | Preuve de |
|---|---|---|
| `ludovic-moj***` | PRO | Lifecycle Y.9B (premier email trial-welcome) |
| `internal-validation-***` | PRO | Runtime TikTok CAPI validation |
| `test-owner-runtime-***` | PRO | Runtime owner flow PROD |
| `codex-google-owner-***` | PRO | Google OAuth owner flow PROD |
| `codex-google-legacy-***` | PRO | Google OAuth legacy flow PROD |

### KEEP_EXEMPT (4) — exempts test, donnees non-zero utiles

| Tenant masque | Plan | Raison |
|---|---|---|
| `romruais-***` | starter | 1 convo, premier signup externe |
| `switaa-sasu-mn9***` | AUTOPILOT | 6 convos, 2 orders, test Autopilot |
| `compta-ecomlg-***` | starter | 3 convos, test comptabilite |
| `ecomlg-mo4***` | PRO | 2 convos, test PRO |

---

## 3. DONNEES A NE JAMAIS SUPPRIMER SANS VALIDATION LUDOVIC

| Element | Raison |
|---|---|
| Tenants `ecomlg-001`, `switaa-sasu-mnc1ouqu`, `keybuzz-consulting` | Production active |
| Row lifecycle Y.9B (`ludovic-moj***`, `trial-welcome`, 2026-05-02) | Preuve premier email lifecycle |
| Tenants KEEP_PROOF | Preuves techniques necessaires |
| Users partages entre tenants | Risque de casser un tenant actif |
| Backups Z.5 (jusqu'au 1er aout 2026 minimum) | Seule restauration possible |
| Spend reel `ad_spend_tenant` (Meta/Google) | Donnees financieres reelles |

---

## 4. BACKUPS DISPONIBLES

| Backup | Chemin bastion | Taille | SHA256 |
|---|---|---:|---|
| Principal | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-20260502-213434.sql` | 36 973 o | `3088274f...eef4a9` |
| Supplementaire | `/opt/keybuzz/backups/PH-SAAS-T8.12Z.5/prod-cleanup-c1-c12-supplementary-20260503.sql` | 13 445 o | `8e49113f...30c602` |

### Regles backups

- **Ne jamais committer les dumps SQL dans Git** (contiennent PII)
- Conservation recommandee : **90 jours minimum** (jusqu'au 1er aout 2026)
- Apres 90 jours sans probleme detecte : archivage ou suppression possible
- SHA256 complets dans le rapport Z.7

---

## 5. REGLES DE CLEANUP FUTUR

Tout futur cleanup PROD doit suivre cette procedure en sequence stricte :

### Sequence obligatoire

1. **Audit** (read-only) : inventaire + classification des tenants cibles
2. **Validation pack Ludovic** : rapport detaille + approbation explicite avant toute deletion
3. **Backup cible** : export SQL `INSERT` de toutes les rows touchees, SHA256, stockage bastion
4. **Transaction** : deletion dans une seule transaction PostgreSQL, avec `ROLLBACK` si echec
5. **FK discovery via `pg_constraint`** : decouvrir toutes les FK avant le DELETE, pas apres
6. **Dry-run counts** : compter les rows avant et apres dans la transaction, avant COMMIT
7. **Post-verify** : verification integrite post-cleanup (orphelins, lifecycle, billing, metrics)
8. **Rapport complet** : documenter chaque etape, chaque count, chaque verdict

### Stop conditions

Arreter immediatement si :

- Un tenant reel (non-test) est ambigu → validation Ludovic
- Un user partage n'est pas compris → analyser `user_tenants` croise
- Une FK inconnue bloque le DELETE → `pg_constraint` + backup supplementaire
- Un backup est introuvable ou SHA256 ne match pas
- Un row count pre/post ne correspond pas
- Une row lifecycle proof est impliquee
- Une billing subscription active n'est pas comprise
- Un rollback n'est pas documente
- Des PII sont pretes a etre commitees dans Git

---

## 6. TABLES SENSIBLES OBSERVEES

Tables touchees lors du cleanup Z.6, a verifier systematiquement lors de tout futur cleanup :

| Table | Type de donnee | FK vers `tenants` | Attention |
|---|---|---|---|
| `tenants` | Tenant principal | — | Cible du DELETE |
| `tenant_metadata` | Metadata tenant | OUI | Supprimer avant `tenants` |
| `tenant_billing_exempt` | Exemptions | OUI | Supprimer avant `tenants` |
| `tenant_settings` | Parametres | OUI | Verifier avant DELETE |
| `user_tenants` | Associations user/tenant | OUI | **Users partages** : UPDATE pas DELETE |
| `user_preferences` | Preferences user | FK `current_tenant_id` | SET NULL, ne pas supprimer |
| `billing_customers` | Clients Stripe | OUI | Verifier pas de sub active |
| `billing_subscriptions` | Subscriptions | OUI | Verifier pas d'active |
| `billing_events` | Events Stripe | indirect | Via subscription_id |
| `signup_attribution` | Attribution marketing | OUI | Verifier pas de spend reel |
| `funnel_events` | Evenements funnel | OUI (nullable) | Events pre-signup = tenant NULL (normal) |
| `conversion_events` | Conversions | OUI | Verifier pas de conversion reelle |
| `ad_spend_tenant` | Depenses publicitaires | OUI | **STOP** si spend reel Meta/Google |
| `cancel_reasons` | Raisons d'annulation | OUI | Decouverte Z.6 : FK non documentee initialement |
| `ai_actions_ledger` | Ledger IA | OUI | Supprimer avant `tenants` |
| `ai_credits_wallet` | Wallet credits | OUI | Supprimer avant `tenants` |
| `ai_actions_wallet` | Wallet KBActions | OUI | Supprimer avant `tenants` |
| `trial_lifecycle_emails_sent` | Emails lifecycle | OUI | **STOP** si Y.9B impliquee |

---

## 7. BASELINES RUNTIME (ne pas ecraser)

| Service | Image PROD | Contenu cle |
|---|---|---|
| API | `v3.5.135-lifecycle-pilot-safety-gates-prod` | Lifecycle pilot + safety gates |
| Client | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Demo + tracking complet |
| Admin | `v2.11.37-acquisition-baseline-truth-prod` | Acquisition baseline truth |
| Website | `v0.6.8-tiktok-browser-pixel-prod` | TikTok browser pixel |

---

## 8. DETTE RESIDUELLE (hors scope Z)

| Element | Severite | Phase recommandee |
|---|---|---|
| 17 users sans tenant | Moyenne | Sprint D-ORPHANS dedie |
| 3 orphelins `ai_*` | Faible | Optionnel, sprint dedie |
| 12 `user_preferences` NULL | Info | Resultat attendu de Z.6 |
| KEEP_PROOF reevaluation | Faible | Reevaluer dans 90 jours (aout 2026) |

---

*Memoire generee par PH-SAAS-T8.12Z.8 — 3 mai 2026*
