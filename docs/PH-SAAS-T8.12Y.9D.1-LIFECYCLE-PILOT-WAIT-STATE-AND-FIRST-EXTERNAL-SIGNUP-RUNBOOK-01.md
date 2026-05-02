# PH-SAAS-T8.12Y.9D.1 - Lifecycle Pilot Wait State & First External Signup Runbook

> Phase : PH-SAAS-T8.12Y.9D.1-LIFECYCLE-PILOT-WAIT-STATE-AND-FIRST-EXTERNAL-SIGNUP-RUNBOOK-01
> Date : 2026-05-02
> Type : Documentation operationnelle + runbook (aucun code, build, deploy, email)
> Environnement : PROD (lecture seule)
> Predecesseur : Y.9D.0 (pilot safety gates implementation)

---

## SOURCES RELUES

- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `TRIAL_WOW_STACK_BASELINE.md`
- `PH-SAAS-T8.12Y.9C` (design activation progressive)
- `PH-SAAS-T8.12Y.9D.0` (pilot safety gates implementation)
- `trial-lifecycle.service.ts` (source Y.9D.0, commit `adaf1821`)
- `trial-lifecycle.routes.ts` (source Y.9B, commit `e8d3ff48`)
- Manifest API PROD (`v3.5.135-lifecycle-pilot-safety-gates-prod`)
- Manifest CronJob `trial-lifecycle-dryrun`

---

## PREFLIGHT

### Repos

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-infra | main | `621e05d` | Non (legacy scripts/docs non lies) | **GO** |

### Runtimes

| Service | Manifest | Runtime | Verdict |
|---|---|---|---|
| API PROD | v3.5.135-lifecycle-pilot-safety-gates-prod | idem | **GO** |
| CronJob lifecycle | trial-lifecycle-dryrun (dry-run) | idem | **GO** |
| CronJob reel lifecycle | Aucun | Attendu | **GO** |
| Idempotence | 1 row (Y.9B inchange) | Attendu | **GO** |

### Baselines preservees

| Service | Image attendue | Statut |
|---|---|---|
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Non touche |
| Admin PROD | v2.11.37-acquisition-baseline-truth-prod | Non touche |
| Website PROD | v0.6.8-tiktok-browser-pixel-prod | Non touche |

---

## ETAT LIFECYCLE PROD ACTUEL

**Statut : READY BUT WAITING FIRST EXTERNAL SIGNUP**

### Configuration active

| Parametre | Valeur | Source |
|---|---|---|
| `LIFECYCLE_ACTIVATION_BASELINE_DATE` | `2026-05-02T18:00:00Z` (defaut code) | Non set comme env var, defaut hardcode |
| `LIFECYCLE_MAX_EMAILS_PER_RUN` | `3` (defaut code) | Non set comme env var, defaut hardcode |
| `INTERNAL_DOMAINS_BLOCKLIST` | keybuzz.io, keybuzz.pro, ecomlg.fr, ecomlg.com, switaa.com, test.com, test-keybuzz.io | Constante code |
| CronJob mode | dry-run | `dryRun:true` dans le body curl |
| controlledSend | Disponible mais non utilise | Guards Y.9B actifs |

### Garde-fous actifs (Y.9D.0)

| Garde | Statut | Effet PROD |
|---|---|---|
| G1 Internal Domains Blocklist | **ACTIF** | 3 candidats exclus |
| G2 Activation Baseline Date | **ACTIF** | Tous les tenants existants exclus |
| G3 Max Emails Per Run | **ACTIF** | Cap = 3 |
| G5 PII-safe Logs | **ACTIF** | maskEmail() applique |

---

## SNAPSHOT DRY-RUN PROD (2026-05-02T17:11:20Z)

### Matrice agregee (sans PII)

| Categorie | Count |
|---|---|
| Total candidats (tenant x template) | 48 |
| Excluded billing_exempt | 44 |
| Excluded already_sent | 1 |
| Excluded internal_domain | 3 |
| Excluded before_activation_baseline | 0 (*) |
| Excluded already_paid | 0 |
| Excluded opt_out | 0 |
| **Eligible** | **0** |

(*) Aucun tenant n'atteint le check G2 car G1 (internal_domain) les intercepte avant dans la cascade.

### Par template

| Template | Jour | Eligible | Exclus |
|---|---|---|---|
| trial-welcome | 0 | 0 | 11 |
| trial-day-2 | 2 | 0 | 11 |
| trial-day-5 | 5 | 0 | 8 |
| trial-day-10 | 10 | 0 | 2 |
| trial-day-13 | 13 | 0 | 0 |
| trial-ended | 14 | 0 | 9 |
| trial-grace | 16 | 0 | 7 |

### Resultat

**eligible = 0** - Aucun candidat externe. Le systeme est en attente active.

---

## CRITERES "VRAI SIGNUP EXTERNE"

Un tenant peut entrer dans le pilot lifecycle Y.9D seulement s'il remplit **tous** les criteres suivants :

| # | Critere | Source DB/code | Obligatoire |
|---|---|---|---|
| C1 | Cree apres `LIFECYCLE_ACTIVATION_BASELINE_DATE` (2026-05-02T18:00:00Z) | `tenant_metadata.created_at` vs `LIFECYCLE_ACTIVATION_BASELINE` | Oui |
| C2 | Owner email avec domaine externe (hors `INTERNAL_DOMAINS_BLOCKLIST`) | `users.email` split domain | Oui |
| C3 | Pas `billing_exempt` | `tenant_billing_exempt.exempt = false` ou absent | Oui |
| C4 | Pas subscription active/paid | `billing_subscriptions.status != 'active'` ou absent | Oui |
| C5 | Pas opt-out lifecycle | `tenant_settings.lifecycle_email_optout != true` ou absent | Oui |
| C6 | Template `trial-welcome` non deja envoye | `trial_lifecycle_emails_sent` absent pour ce tenant+template | Oui |
| C7 | Owner email valide (non null) | `users.email IS NOT NULL` via `user_tenants(role=owner)` | Oui |
| C8 | `is_trial = true` et `trial_ends_at IS NOT NULL` | `tenant_metadata` | Oui |
| C9 | Trial actif (`days_remaining > 0`) pour trial-welcome | `EXTRACT(DAY FROM trial_ends_at - NOW())` | Oui |
| C10 | Tenant ID ne contient pas "test", "internal", "proof" | `tenants.id` | Recommande (*) |
| C11 | Tenant status = active | `tenants.status` | Recommande (*) |

(*) C10 et C11 ne sont pas encore implementes dans le code mais les garde-fous G1+G2 couvrent les cas actuels. A ajouter dans Y.9E.

### Domaines externes valides (exemples)

Tout domaine **hors** blocklist : `gmail.com`, `outlook.com`, `hotmail.com`, `yahoo.com`, tout domaine entreprise externe (`example.com`, `shopowner.fr`, etc.)

### Comment detecter un premier signup externe

Via le dry-run CronJob quotidien (`0 8 * * *`) :
- Si `eligible > 0` dans les logs du CronJob dry-run, un candidat externe existe
- Verification manuelle via `POST /internal/trial-lifecycle/tick` avec `dryRun:true`
- Le dry-run ne revele pas les emails (PII-stripped en PROD)

---

## RUNBOOK Y.9D PILOT SEND

### Pre-conditions (TOUTES obligatoires)

- [ ] Dry-run PROD montre `eligible >= 1`
- [ ] Candidat confirme comme vrai client externe (domaine non blockliste)
- [ ] API PROD = `v3.5.135-lifecycle-pilot-safety-gates-prod` (ou successeur documente)
- [ ] CronJob = dry-run seulement
- [ ] Aucun CronJob reel lifecycle
- [ ] Rapport Y.9D.0 relu
- [ ] Rapport Y.9D.1 relu

### Procedure (etape par etape)

| # | Etape future | Check | STOP si |
|---|---|---|---|
| R1 | Relire Y.9D.0 + Y.9D.1 | Sources verifiees | Rapport manquant |
| R2 | Preflight PROD complet | API, CronJob, idempotence | Runtime != manifest |
| R3 | Dry-run PROD | Confirmer eligible >= 1 | eligible = 0 |
| R4 | Identifier le candidat | Domaine externe, pas test/internal | Domaine interne ou test |
| R5 | Choisir mode d'envoi | `controlledSend` (Y.9B) ou nouveau `pilotSend` | Mode non disponible |
| R6 | Envoyer 1 email | template `trial-welcome`, 1 seul tenant | sentCount > 1 |
| R7 | Verifier provider accepted | Log stdout, pas d'erreur SMTP | provider error |
| R8 | Verifier idempotence +1 | `trial_lifecycle_emails_sent` = rows_before + 1 | Pas de nouvelle row |
| R9 | Relancer meme envoi | Doit retourner sentCount=0 (already_sent) | sentCount > 0 |
| R10 | Verifier CronJob dry-run | Toujours dry-run, pas de CronJob reel | CronJob modifie |
| R11 | Non-regression | API health, billing, client, website | Regression |
| R12 | QA inbox (si possible) | Email recu, pas spam, correct | Non recu ou spam |
| R13 | Rapport + verdict | GO PARTIEL ou GO | echec |

### Notes importantes

- **Le mode `controlledSend` Y.9B est restreint a `ludo.gonthier@gmail.com`**. Pour un vrai client externe, il faudra :
  - Soit elargir l'allowlist dans `controlledSend` (modification code)
  - Soit creer un nouveau mode `pilotSend` avec les gardes G1-G5 actifs
  - Soit utiliser le mode DEV (non recommande en PROD)
- **Le `maxEmailsPerRun=3` protege contre tout bulk accidentel**
- **L'idempotence empeche les doublons** (ON CONFLICT DO NOTHING)

---

## OBSERVABILITE A SURVEILLER

### Lors du pilot send (futur)

| Signal | Attendu | Ou regarder |
|---|---|---|
| sentCount | 1 (premier pilot) | Reponse JSON du POST tick |
| provider accepted | 1 | Log stdout du pod API |
| provider failed | 0 | Log stdout du pod API |
| idempotence skipped | 0 (premier envoi) | Reponse JSON + DB query |
| opt-out count | 0 | DB `tenant_settings` |
| SMTP errors | 0 | Log stdout du pod API |
| unsubscribe count | 0 (avant clic) | DB `tenant_settings` |
| CronJob mode | dry-run | `kubectl get cronjob` |
| logs PII-safe | Emails masques | Log stdout (maskEmail) |
| billing events | 0 nouveau | DB `billing_events` |
| CAPI events | 0 | Pas d'integration lifecycle-CAPI |

### En attente (quotidien)

| Signal | Attendu | Ou regarder |
|---|---|---|
| CronJob dry-run logs | eligible = 0 | Logs du job `trial-lifecycle-dryrun` |
| eligible change | Notification si > 0 | Pas d'alerte auto (manuel via dry-run) |
| idempotence rows | 1 (inchange) | DB |

---

## STOP CONDITIONS RAPPEL

| # | Stop condition | Action immediate |
|---|---|---|
| S1 | sentCount > 1 pendant pilot | STOP, audit, rollback si necessaire |
| S2 | Email envoye a domaine interne | STOP, audit garde G1, rollback |
| S3 | Email envoye a tenant avant baseline | STOP, audit garde G2, rollback |
| S4 | Double insertion idempotence | STOP, audit ON CONFLICT, DB check |
| S5 | CronJob real-send active par erreur | STOP, suspendre CronJob, audit |
| S6 | Provider error (SMTP reject) | STOP run, investiguer delivrabilite |
| S7 | Token/secret en log | STOP, purge logs, audit |
| S8 | Billing/tracking/CAPI mutation | STOP, audit, confirmer pas de drift |
| S9 | Plainte utilisateur | STOP, review contenu email, opt-out si demande |
| S10 | Email recu en spam | Investiguer SPF/DKIM/DMARC, ne pas re-envoyer |

### Precedence

1. **Immediat (S1-S5, S7-S8)** : arret total, audit avant reprise
2. **Investigation (S6, S10)** : pause, corriger avant reprise
3. **Review (S9)** : intervention humaine, opt-out si demande

---

## LINEAR / TICKETS

Acces Linear non disponible. Commentaires prets a copier :

### Ticket 1 : Lifecycle First External Signup Pilot Pending

```
Titre : [Lifecycle] Attente premier signup externe - pilot send pret
Priorite : P2 (pas de deadline externe)
Labels : lifecycle, email, waiting

Description :
Le systeme lifecycle email est en etat d'attente active :
- Garde-fous G1-G5 deployes (v3.5.135-lifecycle-pilot-safety-gates-prod)
- CronJob dry-run actif (0 8 * * *)
- 0 candidat externe eligible actuellement
- Tous les tenants existants sont internes/test

Action requise :
- Surveiller le dry-run quotidien pour eligible > 0
- Quand un vrai signup externe apparait, suivre le runbook Y.9D.1
- Ne pas activer l'envoi general avant validation pilot

Ref : PH-SAAS-T8.12Y.9D.0 + Y.9D.1
```

### Ticket 2 : Lifecycle Monitor First Eligible External Tenant

```
Titre : [Lifecycle] Monitorer premier tenant externe eligible
Priorite : P3
Labels : lifecycle, monitoring

Description :
Le CronJob dry-run tourne tous les jours a 8h UTC.
Quand les logs montrent eligible > 0, c'est le signal
pour lancer le pilot send (runbook Y.9D.1).

Pour le moment, eligible = 0 (tous internes/test).

Option future : ajouter une alerte Slack/email quand
eligible > 0 dans les logs du CronJob.

Ref : PH-SAAS-T8.12Y.9D.1
```

---

## PREUVES DE CONFORMITE

### Zero code/build/deploy

- Aucun fichier source modifie
- Aucun `docker build` execute
- Aucun `kubectl apply` execute
- API PROD inchangee : v3.5.135-lifecycle-pilot-safety-gates-prod

### Zero email envoye

- Aucun appel POST avec `dryRun:false` execute
- Idempotence : 1 row (inchangee depuis Y.9B)

### CronJob toujours dry-run

- `trial-lifecycle-dryrun` : `dryRun:true`, schedule `0 8 * * *`
- Aucun CronJob reel lifecycle

### Zero mutation DB

- Aucun INSERT/UPDATE/DELETE execute
- Lecture SELECT uniquement (dry-run)

---

## VERDICT

**GO**

LIFECYCLE PILOT WAIT STATE DOCUMENTED - ZERO ELIGIBLE EXTERNAL TENANT CURRENTLY - CRONJOB STILL DRY-RUN - FIRST EXTERNAL SIGNUP RUNBOOK READY - ZERO EMAIL SENT - ZERO CODE - ZERO BUILD - ZERO DEPLOY

### Prochaine etape conditionnelle

**Quand** le dry-run quotidien montre `eligible > 0` avec un vrai client externe :
1. Suivre le runbook section "RUNBOOK Y.9D PILOT SEND" ci-dessus
2. Creer un prompt `PH-SAAS-T8.12Y.9D.2-LIFECYCLE-FIRST-EXTERNAL-PILOT-SEND-01`
3. Envoyer 1 email `trial-welcome` maximum
4. Valider inbox + idempotence + non-regression
5. Rapporter GO/GO PARTIEL

**Tant que** `eligible = 0` : aucune action requise. Le systeme est pret et en attente.

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Y.9D.1-LIFECYCLE-PILOT-WAIT-STATE-AND-FIRST-EXTERNAL-SIGNUP-RUNBOOK-01.md
```
