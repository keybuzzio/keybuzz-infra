# PH-SAAS-T8.12Y.5 — Trial Lifecycle Email Foundation DEV

> Date : 2026-05-02
> Environnement : DEV uniquement
> Type : Fondation lifecycle trial emails (idempotence, opt-out, dry-run)
> Priorité : P1

---

## 1. OBJECTIF

Préparer l'architecture lifecycle emails pour le trial KeyBuzz, sans activer d'envoi automatique :
- Table d'idempotence pour ne jamais envoyer deux fois le même email lifecycle
- Mécanisme opt-out lifecycle (colonne `tenant_settings.lifecycle_email_optout`)
- Headers `List-Unsubscribe` préparés dans le service d'envoi
- Endpoint interne DEV-only dry-run par défaut
- Mapping des 7 templates trial aux jours correspondants
- Aucun CronJob, aucun envoi automatique, aucune modification PROD

---

## 2. PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatée | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `b1390a1a` | Clean | **OK** |
| `keybuzz-infra` | `main` | `main` | `9b4c2d2` | Clean | **OK** |

### Runtimes avant déploiement

| Service | Attendu | Runtime | Verdict |
|---|---|---|---|
| API DEV | `v3.5.134-email-subject-encoding-hotfix-dev` | Identique | **OK** |
| API PROD | `v3.5.131-transactional-email-design-prod` | Identique | **OK** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | Identique | **OK** |

---

## 3. AUDIT SOURCE TRIAL

| Donnée | Table/source | Champ | Fiabilité | Note |
|---|---|---|---|---|
| Tenant trial actif | `tenant_metadata` | `is_trial` (boolean, default `true`) | Haute | Source de vérité |
| Date début trial | `tenant_metadata` | `created_at` (timestamptz) | Haute | Trial commence à la création |
| Date fin trial | `tenant_metadata` | `trial_ends_at` (timestamptz) | Haute | Toujours peuplé, `created_at + 14j` |
| Plan choisi | `tenants` | `plan` (varchar) | Haute | STARTER / PRO / AUTOPILOT |
| Owner email | `users` JOIN `user_tenants` | `email` WHERE `role = 'owner'` | Haute | 1 owner par tenant |
| Subscription payée | `billing_subscriptions` | `status = 'active'` | Haute | Stop lifecycle si payé |
| Tenants exemptés | `tenant_billing_exempt` | `exempt = true` | Haute | 23 entrées test/internal |
| Opt-out existant | `tenant_settings` | Aucun champ pré-existant | N/A | **Créé dans cette phase** |

**Verdict : source trial fiable.** `trial_ends_at` toujours peuplé pour les trials.

---

## 4. TABLE IDEMPOTENCE

### `trial_lifecycle_emails_sent`

| Champ | Type | Rôle | Risque |
|---|---|---|---|
| `id` | UUID (gen_random_uuid) | PK | Aucun |
| `tenant_id` | TEXT NOT NULL | FK logique tenant | Aucun |
| `template_name` | TEXT NOT NULL | Nom template lifecycle | Aucun |
| `recipient_email` | TEXT NOT NULL | Email destinataire | Aucun |
| `sent_at` | TIMESTAMPTZ DEFAULT NOW() | Date d'envoi | Aucun |
| `status` | TEXT NOT NULL DEFAULT 'sent' | Statut ('sent') | Aucun |
| `provider_message_id` | TEXT | ID message SMTP | Nullable |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | Date de création | Aucun |

**Contrainte unique : `(tenant_id, template_name)`** — empêche tout doublon.

Index : `idx_lifecycle_tenant`, `idx_lifecycle_template`.

Migration appliquée en DEV uniquement. PROD non touchée.

---

## 5. OPT-OUT / UNSUBSCRIBE FOUNDATION

| Mécanisme | Existait | Action DEV | Impact |
|---|---|---|---|
| Colonne `lifecycle_email_optout` | Non | **Créée** dans `tenant_settings` (BOOLEAN DEFAULT false) | Seuls les emails lifecycle sont affectés |
| Opt-out transactionnels (OTP, billing, invite) | N/A | **Inchangé** — jamais bloqué | Aucun |
| Token unsubscribe signé | Non | **URL préparée** dans les headers mais pas de endpoint fonctionnel | Pas de lien actif |

L'opt-out lifecycle ne coupe PAS les emails transactionnels critiques (OTP, billing, invite).

---

## 6. LIST-UNSUBSCRIBE

| Header | Implémenté | Utilisé maintenant | Note |
|---|---|---|---|
| `List-Unsubscribe` | Oui (helper dans service) | Non (dryRun par défaut) | URL préparée, endpoint pas encore créé |
| `List-Unsubscribe-Post` | Oui | Non | RFC 8058 conforme |

Les headers sont ajoutés dans `executeLifecycleTick()` lors d'un envoi réel (`dryRun: false + force: true`).

---

## 7. ENDPOINT INTERNE DRY-RUN

### Routes créées (DEV-only)

| Method | Route | Description |
|---|---|---|
| POST | `/internal/trial-lifecycle/tick` | Calcul candidats + envoi conditionnel |
| GET | `/internal/trial-lifecycle/candidates` | Vue lecture seule des candidats |

### Guards de sécurité

1. `if (process.env.NODE_ENV === 'production') return;` — aucune route en PROD
2. `dryRun !== false` — dryRun=true par défaut
3. `force: true` requis avec `dryRun: false` — double sécurité
4. Exclusion automatique des tenants exemptés, payés, opt-out, déjà envoyés

### Résultats runtime

| Cas | Attendu | Résultat |
|---|---|---|
| dryRun absent | aucun envoi | **OK** (`sent: []`) |
| dryRun true | candidats listés | **49 candidats, 3 éligibles** |
| dryRun false sans force | 400 | **HTTP 400** |
| opt-out tenant | exclu | **OK** (via `lifecycle_email_optout`) |
| already sent | exclu | **OK** (via table idempotence) |
| tenant test/exempt | exclu | **46 exclus** (`billing_exempt`) |
| tenant paid | exclu | **OK** (via `billing_subscriptions.status = 'active'`) |

---

## 8. MAPPING TEMPLATES

| Template | Jour | Condition | Stop |
|---|---|---|---|
| `trial-welcome` | J0 | Trial actif | opt-out / upgrade |
| `trial-day-2` | J2 | Trial actif | opt-out / upgrade |
| `trial-day-5` | J5 | Trial actif | opt-out / upgrade |
| `trial-day-10` | J10 | Trial actif | opt-out / upgrade |
| `trial-day-13` | J13 | Trial actif | opt-out / upgrade |
| `trial-ended` | J14 | Trial terminé | opt-out / upgrade |
| `trial-grace` | J16 | Trial expiré sans upgrade | opt-out / upgrade |

---

## 9. MIGRATION DEV

| Objet DB | Créé DEV | Vérifié | Note |
|---|---|---|---|
| `trial_lifecycle_emails_sent` | Oui | 8 colonnes, PK + UNIQUE | OK |
| `uq_lifecycle_tenant_template` | Oui | UNIQUE constraint | OK |
| `idx_lifecycle_tenant` | Oui | Index | OK |
| `idx_lifecycle_template` | Oui | Index | OK |
| `tenant_settings.lifecycle_email_optout` | Oui | BOOLEAN DEFAULT false | OK |

PROD non touchée.

---

## 10. BUILD DEV

| Élément | Valeur |
|---|---|
| Source commit API | `a88715eb` — feat(lifecycle): trial lifecycle email foundation (PH-SAAS-T8.12Y.5) |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.135-trial-lifecycle-foundation-dev` |
| Digest | `sha256:ff0163941674d1409bdf196641f0a69f3fed1b9f7c43a46a9231e66bb9a9fdaf` |
| Build method | `docker build --no-cache` depuis source propre |
| tsc build | Succès (0 erreur) |
| Rollback | `v3.5.134-email-subject-encoding-hotfix-dev` |

---

## 11. GITOPS DEV

| Étape | Résultat |
|---|---|
| Manifest modifié | `k8s/keybuzz-api-dev/deployment.yaml` |
| Commit infra | `d8b8907` — gitops(api-dev): deploy v3.5.135-trial-lifecycle-foundation-dev |
| Push | `main -> main` OK |
| `kubectl apply -f` | `deployment.apps/keybuzz-api configured` |
| `kubectl rollout status` | `successfully rolled out` |
| Manifest = runtime | **Oui** (`v3.5.135-trial-lifecycle-foundation-dev`) |

### Rollback GitOps strict

```bash
# 1. Modifier deployment.yaml -> v3.5.134-email-subject-encoding-hotfix-dev
# 2. git commit + push
# 3. kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml
# 4. kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 12. VALIDATION STATIQUE

| Check | Attendu | Résultat |
|---|---|---|
| `tsc --noEmit` | 0 erreur | **0** |
| No secrets | 0 | **0** |
| No fake send | 0 | **0** (sendEmail protégé par dryRun+force) |
| dryRun default | true | **OK** (`dryRun !== false`) |
| Idempotence unique | oui | **OK** (`ON CONFLICT DO NOTHING`) |
| Transactionnels inchangés | oui | **OK** (invite + billing intacts) |
| Lifecycle no auto-send | oui | **0** scheduler/cron/interval |
| DEV-only guard | oui | **1** (`NODE_ENV === 'production' return`) |

---

## 13. NON-RÉGRESSION

| Surface | Attendu | Résultat |
|---|---|---|
| API DEV health | OK | **OK** |
| API PROD | `v3.5.131-transactional-email-design-prod` | **Identique** |
| Client PROD | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` | **Identique** |
| Admin PROD | `v2.11.37-acquisition-baseline-truth-prod` | **Identique** |
| Website PROD | `v0.6.8-tiktok-browser-pixel-prod` | **Identique** |
| Billing DB | Aucune mutation métier | **OK** (table idempotence vide) |
| Stripe | Aucune mutation | **Non touché** |
| CAPI | Aucun event | **Non touché** |
| Tracking | Aucun event | **Non touché** |
| CronJobs PROD | Inchangés | **2** (`outbound-tick-processor`, `sla-evaluator`) |
| Lifecycle automatic send | Absent | **Aucun CronJob lifecycle** |
| PROD lifecycle endpoint | 404 | **404** (guard actif) |

---

## 14. FICHIERS MODIFIÉS / CRÉÉS

| Fichier | Action |
|---|---|
| `src/modules/lifecycle/trial-lifecycle.service.ts` | **Créé** — service idempotence + opt-out + dry-run |
| `src/modules/lifecycle/trial-lifecycle.routes.ts` | **Créé** — endpoint DEV-only |
| `src/app.ts` | **Modifié** — import + register route `/internal` |

---

## 15. GAPS RESTANTS

| # | Description | Impact | Prochaine phase |
|---|---|---|---|
| G1 | Pas de endpoint unsubscribe fonctionnel | Le header `List-Unsubscribe` pointe vers une URL non-fonctionnelle | Y.6 ou décision produit |
| G2 | Pas de CronJob lifecycle | Les emails ne sont pas envoyés automatiquement | Y.6 (après validation Ludovic) |
| G3 | OTP utilise son propre template | Incohérence visuelle | Phase séparée |
| G4 | Migration PROD non faite | Table idempotence et opt-out absentes en PROD | Y.6 PROD promotion |
| G5 | Pas de UI opt-out dans le client | L'opt-out est uniquement DB | Phase client séparée |

---

## 16. PROCHAINE PHASE RECOMMANDÉE

**PH-SAAS-T8.12Y.6 — Trial Lifecycle Email Activation DEV** :
1. Créer un CronJob K8s DEV qui appelle `/internal/trial-lifecycle/tick` avec `dryRun: true`
2. Tester l'envoi contrôlé d'un email lifecycle sur un tenant test (avec `dryRun: false, force: true`)
3. Créer l'endpoint `/lifecycle/unsubscribe` fonctionnel
4. Valider la séquence complète J0→J16 sur un tenant test
5. Puis promotion PROD (migration + CronJob + endpoint unsubscribe)

---

## 17. CONFIRMATIONS EXPLICITES

- **Rapport** : `keybuzz-infra/docs/PH-SAAS-T8.12Y.5-TRIAL-LIFECYCLE-EMAIL-FOUNDATION-DEV-01.md`
- **Tag DEV** : `v3.5.135-trial-lifecycle-foundation-dev`
- **Digest** : `sha256:ff0163941674d1409bdf196641f0a69f3fed1b9f7c43a46a9231e66bb9a9fdaf`
- **Commit API** : `a88715eb` (branche `ph147.4/source-of-truth`)
- **Commit infra** : `d8b8907` (branche `main`)
- **Aucun email automatique** : dryRun=true par défaut, aucun envoi
- **Aucun email PROD** : endpoint 404 en PROD
- **CronJob absent** : aucun CronJob lifecycle créé
- **dryRun par défaut** : `body.dryRun !== false` (true sauf demande explicite)
- **PROD inchangée** : toutes baselines préservées

---

## VERDICT

**TRIAL LIFECYCLE EMAIL FOUNDATION READY IN DEV — IDEMPOTENCE TABLE CREATED — OPT-OUT/LIST-UNSUBSCRIBE FOUNDATION PREPARED — INTERNAL DRY-RUN ENDPOINT VALIDATED — NO AUTOMATIC EMAILS — NO TRACKING/BILLING/CAPI DRIFT — PROD UNCHANGED**
