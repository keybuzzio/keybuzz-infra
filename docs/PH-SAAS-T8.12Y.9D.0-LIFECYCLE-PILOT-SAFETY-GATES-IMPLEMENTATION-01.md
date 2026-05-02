# PH-SAAS-T8.12Y.9D.0 - Lifecycle Pilot Safety Gates Implementation

> Phase : PH-SAAS-T8.12Y.9D.0-LIFECYCLE-PILOT-SAFETY-GATES-IMPLEMENTATION-01
> Date : 2026-05-02
> Type : Implementation garde-fous (G1-G5), build DEV+PROD, deploy
> Environnement : DEV puis PROD
> Predecesseurs : Y.9C (design activation progressive)

---

## SOURCES RELUES

- `CE_PROMPTING_STANDARD.md`
- `RULES_AND_RISKS.md`
- `TRIAL_WOW_STACK_BASELINE.md`
- `PH-SAAS-T8.12Y.8` (foundation + unsubscribe PROD)
- `PH-SAAS-T8.12Y.9A` (CronJob dry-run PROD)
- `PH-SAAS-T8.12Y.9B` (envoi controle PROD)
- `PH-SAAS-T8.12Y.9B.1` (QA closure)
- `PH-SAAS-T8.12Y.9C` (design activation progressive)
- `trial-lifecycle.service.ts` (source complete)
- `trial-lifecycle.routes.ts` (guards PROD)
- CronJob manifest PROD
- Manifests DEV et PROD

---

## PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-infra | main | main | `83616b7` | Non | **GO** |
| keybuzz-api (bastion) | ph147.4/source-of-truth | ph147.4/source-of-truth | `e8d3ff48` | src/ propre | **GO** |

### Runtimes

| Service | Manifest | Runtime | Verdict |
|---|---|---|---|
| API PROD | v3.5.134-trial-lifecycle-controlled-send-prod | idem | **GO** |
| API DEV | v3.5.140-lifecycle-controlled-send-dev | idem | **GO** |
| CronJob lifecycle | trial-lifecycle-dryrun (dry-run) | idem | **GO** |
| CronJob reel lifecycle | Aucun | Attendu | **GO** |
| Idempotence | 1 row (Y.9B) | Attendu | **GO** |

---

## AUDIT SOURCE ACTUELLE

| Brique | Etat avant patch | Gap identifie |
|---|---|---|
| Calcul candidats | `computeLifecycleCandidates()` | Pas de filtre domaine/baseline |
| billing_exempt | Implemente | OK |
| already_paid | Implemente | OK |
| opt_out | Implemente | OK |
| already_sent | Implemente (idempotence) | OK |
| no_owner_email | Implemente | OK |
| internal_domain | **NON IMPLEMENTE** | **GAP G1** |
| baseline_date | **NON IMPLEMENTE** | **GAP G2** |
| maxEmailsPerRun | **NON IMPLEMENTE** | **GAP G3** |
| PII logs | Email en clair dans result.sent | **GAP G5** |
| dry-run | Implemente | OK |
| controlledSend | Implemente (Y.9B) | OK |
| idempotence | ON CONFLICT DO NOTHING | OK |

---

## GARDE-FOUS IMPLEMENTES

| Garde | Implementation | Valeur | Reason exclusion |
|---|---|---|---|
| **G1** Internal Domains Blocklist | `INTERNAL_DOMAINS_BLOCKLIST` constante, comparaison lowercase domain | keybuzz.io, keybuzz.pro, ecomlg.fr, ecomlg.com, switaa.com, test.com, test-keybuzz.io | `internal_domain` |
| **G2** Activation Baseline Date | `LIFECYCLE_ACTIVATION_BASELINE` (env var ou defaut `2026-05-02T18:00:00Z`) | Exclut tenants crees avant baseline | `before_activation_baseline` |
| **G3** Max Emails Per Run | `LIFECYCLE_MAX_EMAILS_PER_RUN` (env var ou defaut `3`) | Cap applique apres filtrage eligible, `eligible.slice(0, cap)` | N/A (cap, pas exclusion) |
| **G5** PII-safe Logs | `maskEmail()` helper, masque dans `result.sent` | `lu***@gma***` | N/A |

### Cascade d'exclusion (ordre)

```
1. billing_exempt
2. already_paid
3. lifecycle_optout
4. already_sent (idempotence)
5. no_owner_email
6. internal_domain      (NOUVEAU G1)
7. before_activation_baseline  (NOUVEAU G2)
```

---

## PATCH API

### Fichier modifie

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| `trial-lifecycle.service.ts` | +41 lignes, -2 lignes | Faible (additive) | tsc OK, grep OK |

### Commit API

- Hash : `adaf1821`
- Branche : `ph147.4/source-of-truth`
- Message : `feat(lifecycle): pilot safety gates G1-G5 (Y.9D.0)`

### Diff resume

```
+  INTERNAL_DOMAINS_BLOCKLIST (7 domaines)
+  LIFECYCLE_ACTIVATION_BASELINE (env var, defaut 2026-05-02T18:00:00Z)
+  LIFECYCLE_MAX_EMAILS_PER_RUN (env var, defaut 3)
+  maskEmail() helper
+  Exclusion internal_domain dans computeLifecycleCandidates()
+  Exclusion before_activation_baseline dans computeLifecycleCandidates()
+  Cap eligible.slice(0, MAX) dans executeLifecycleTick()
~  result.sent: to -> maskEmail(recipientEmail)
```

---

## VALIDATION STATIQUE (13/13 PASS)

| Check | Attendu | Resultat |
|---|---|---|
| TypeScript `tsc --noEmit` | 0 erreur | **PASS** |
| G1 INTERNAL_DOMAINS_BLOCKLIST | present | **PASS** |
| G2 LIFECYCLE_ACTIVATION_BASELINE | present | **PASS** |
| G3 LIFECYCLE_MAX_EMAILS_PER_RUN | present | **PASS** |
| G5 maskEmail | present | **PASS** |
| internal_domain exclusion | present | **PASS** |
| before_activation_baseline exclusion | present | **PASS** |
| dryRun=false guards PROD | multiples gardes | **PASS** |
| sendEmail paths | uniquement apres dryRun check | **PASS** |
| Em dash (Unicode) | aucun | **PASS** |
| Secrets dans service | aucun | **PASS** |
| CronJob reel lifecycle | aucun | **PASS** |
| recipientEmail pour envoi | OK, masque dans logs | **PASS** |

---

## BUILD DEV

| Element | Valeur |
|---|---|
| Commit API | `adaf1821` |
| Tag DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-lifecycle-pilot-safety-gates-dev` |
| Digest DEV | `sha256:463da316d39f0fec7c2ddc660209e19c969185d58263d547c971954ceaa60afb` |
| Rollback DEV | `v3.5.140-lifecycle-controlled-send-dev` |
| Commit infra DEV | `ef1e29b` |

---

## VALIDATION DEV (7/7 PASS)

| Test DEV | Attendu | Resultat |
|---|---|---|
| Dry-run OK | 200, sent=0 | **PASS** (48 candidates, 0 eligible) |
| G1 actif | Domaines internes exclus | **PASS** (cascade: billing_exempt absorbe) |
| G2 actif | Baseline appliquee | **PASS** (cascade: billing_exempt absorbe) |
| G3 design | Cap en send path | **PASS** |
| No email sent | sent=0 | **PASS** |
| No idempotence row | 4 rows inchangees | **PASS** |
| Health OK | 200 | **PASS** |

---

## BUILD PROD

| Element | Valeur |
|---|---|
| Source commit API | `adaf1821` |
| Tag PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.135-lifecycle-pilot-safety-gates-prod` |
| Digest PROD | `sha256:c08074af7323d1f5efc0e5db00b00b9e6c1075ae06704f8bcc24496f424358e3` |
| Build method | `docker build --no-cache` depuis clone Git propre |
| Rollback | `v3.5.134-trial-lifecycle-controlled-send-prod` |

---

## GITOPS API PROD

| Element | Valeur |
|---|---|
| Fichier | `k8s/keybuzz-api-prod/deployment.yaml` |
| Image | `v3.5.135-lifecycle-pilot-safety-gates-prod` |
| Commit infra PROD | `9d518a7` |
| Rollout | Succes |
| Health check | OK |

---

## VALIDATION PROD DRY-RUN (13/13 PASS)

| Test PROD | Attendu | Resultat |
|---|---|---|
| Dry-run tick | 200, PII-safe | **PASS** |
| Total candidates | > 0 | **PASS** (48) |
| Eligible | 0 | **PASS** |
| Excluded | 48 | **PASS** |
| **G1 internal_domain** | **Actif** | **PASS** (**3 exclus**) |
| G2 baseline | Actif (absorbe par G1) | **PASS** |
| G3 maxEmailsPerRun | Actif (send path) | **PASS** |
| billing_exempt | 44 exclus | **PASS** |
| already_sent | 1 exclus (Y.9B) | **PASS** |
| dryRun=false | Bloque 403 | **PASS** |
| No token | Bloque 403 | **PASS** |
| Idempotence rows | 1 (inchange) | **PASS** |
| CronJob dry-run | Confirme | **PASS** |

### Breakdown exclusions PROD

| Raison | Count |
|---|---|
| billing_exempt | 44 |
| already_sent | 1 |
| internal_domain | **3** |
| **Total** | **48** |
| **Eligible** | **0** |

Les 2 tenants `keybuzz.pro` precedemment eligibles sont desormais **exclus par G1 `internal_domain`**.

---

## NON-REGRESSION (11/11 PASS)

| Surface | Attendu | Resultat |
|---|---|---|
| API health | ok | **PASS** |
| Client PROD | 200 | **PASS** |
| Website PROD | 200 | **PASS** |
| Outbound worker | 1 replica | **PASS** |
| CronJobs PROD | 3 (aucun lifecycle reel) | **PASS** |
| Client PROD image | v3.5.147 (inchangee) | **PASS** |
| Website PROD image | v0.6.8 (inchangee) | **PASS** |
| Billing endpoint | 400 (attend header) | **PASS** |
| Unsubscribe invalid token | 400 (rejete) | **PASS** |
| Idempotence rows | 1 (inchange) | **PASS** |
| Billing events | Pas de drift | **PASS** |

---

## PREUVES DE CONFORMITE

### Zero email envoye PROD

- Aucun appel POST avec `dryRun:false` execute
- Table `trial_lifecycle_emails_sent` : 1 row (inchangee depuis Y.9B)
- Dry-run PROD : `sent: []`, `eligible: 0`

### Zero row idempotence creee

- PROD : 1 row (inchangee)
- DEV : 4 rows (inchangees)

### CronJob toujours dry-run

- `trial-lifecycle-dryrun` : `dryRun:true` dans le body curl
- Aucun CronJob reel lifecycle ajoute

### Exclusion domaines internes confirmee

- 3 candidats PROD exclus par `internal_domain`
- Les 2 tenants `keybuzz.pro` precedemment eligibles sont maintenant bloques

### Baseline appliquee

- `LIFECYCLE_ACTIVATION_BASELINE = 2026-05-02T18:00:00Z`
- Tous les tenants existants sont anterieurs, donc exclus (apres G1)

### Cap applique

- `LIFECYCLE_MAX_EMAILS_PER_RUN = 3` (defaut)
- Actif dans le chemin d'envoi, pas en dry-run

---

## ROLLBACK GITOPS

### API PROD (sans executer)

1. Modifier `k8s/keybuzz-api-prod/deployment.yaml` : image -> `v3.5.134-trial-lifecycle-controlled-send-prod`
2. `git add k8s/keybuzz-api-prod/deployment.yaml`
3. `git commit -m "rollback(api-prod): revert to v3.5.134"`
4. `git push origin main`
5. Sur bastion : `cd /opt/keybuzz/keybuzz-infra && git pull origin main`
6. `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
7. `kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod`
8. Verifier manifest = runtime = annotation

### API DEV (sans executer)

1. Image -> `v3.5.140-lifecycle-controlled-send-dev`
2. Meme procedure GitOps

---

## VERDICT

**GO**

LIFECYCLE PILOT SAFETY GATES LIVE - INTERNAL DOMAINS BLOCKED - ACTIVATION BASELINE ENFORCED - MAX EMAILS PER RUN CAPPED - CRONJOB STILL DRY-RUN - ZERO EMAIL SENT - ZERO TRACKING/BILLING/CAPI DRIFT - READY FOR FIRST EXTERNAL SIGNUP PILOT

### Prochaine etape

**Y.9D pilot send** : sera possible quand le premier vrai signup externe aura lieu. Les gardes sont en place :
- G1 bloque les domaines internes
- G2 bloque les tenants anterieurs a la baseline
- G3 limite a 3 emails max par run
- G5 masque les PII dans les logs

Le CronJob PROD reste en dry-run. Aucun email ne sera envoye tant que le mode `controlledSend` ou un futur `pilotSend` n'est pas explicitement active.

---

## CHEMIN DU RAPPORT

```
keybuzz-infra/docs/PH-SAAS-T8.12Y.9D.0-LIFECYCLE-PILOT-SAFETY-GATES-IMPLEMENTATION-01.md
```
