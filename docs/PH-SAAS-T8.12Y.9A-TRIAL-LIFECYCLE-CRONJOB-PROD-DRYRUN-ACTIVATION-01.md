# PH-SAAS-T8.12Y.9A — Trial Lifecycle CronJob PROD Dry-Run Activation

> Date : 2026-05-02
> Environnement : DEV validation + PROD dry-run
> Type : Activation controlee CronJob PROD en dry-run uniquement
> Priorite : P1
> Image precedente API PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.132-trial-lifecycle-foundation-unsubscribe-prod`
> Image deployee API PROD : `ghcr.io/keybuzzio/keybuzz-api:v3.5.133-trial-lifecycle-cron-dryrun-prod`

---

## 1. OBJECTIF

Activer en PROD un CronJob lifecycle emails strictement dry-run, afin d'observer chaque jour les candidats lifecycle trial, les exclusions, l'idempotence et l'opt-out, sans envoyer le moindre email.

**Exclusions strictes** :
- ZERO email PROD envoye
- ZERO ligne `trial_lifecycle_emails_sent` creee par le dry-run
- ZERO mutation billing / Stripe / CAPI / GA4 / tracking
- ZERO modification Client / Admin / Website
- `dryRun=false` impossible en PROD
- `force=true` impossible en PROD
- `recipientOverride` impossible en PROD
- `sendEmail()` non reachable depuis les endpoints PROD

---

## 2. SOURCES RELUES

| Document | Chemin |
|---|---|
| CE Prompting Standard | `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` |
| Rules and Risks | `keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md` |
| Trial Wow Stack Baseline | `keybuzz-infra/docs/AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` |
| PH-SAAS-T8.12Y.4 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.4-TRANSACTIONAL-EMAIL-DESIGN-PROD-PROMOTION-01.md` |
| PH-SAAS-T8.12Y.5 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.5-TRIAL-LIFECYCLE-EMAIL-FOUNDATION-DEV-01.md` |
| PH-SAAS-T8.12Y.6 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.6-TRIAL-LIFECYCLE-UNSUBSCRIBE-AND-CONTROLLED-SEND-DEV-01.md` |
| PH-SAAS-T8.12Y.7 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7-TRIAL-LIFECYCLE-CONTROLLED-SEND-DEV-01.md` |
| PH-SAAS-T8.12Y.7.1 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7.1-LIFECYCLE-VISIBLE-UNSUBSCRIBE-AND-HYPHEN-COPY-HOTFIX-DEV-01.md` |
| PH-SAAS-T8.12Y.7.2 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.7.2-LIFECYCLE-EMAIL-QA-CLOSURE-DEV-01.md` |
| PH-SAAS-T8.12Y.8 | `keybuzz-infra/docs/PH-SAAS-T8.12Y.8-TRIAL-LIFECYCLE-FOUNDATION-UNSUBSCRIBE-PROD-PROMOTION-01.md` |

---

## 3. PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api (bastion) | ph147.4/source-of-truth | ph147.4/source-of-truth | `2b0b2adc` (Y.7.1) | dist/ seulement | **OK** |
| keybuzz-infra | main | main | `4070075` (Y.8 rapport) | scripts/docs autres phases | **OK** |

### Runtimes

| Service | Manifest | Runtime | Verdict |
|---|---|---|---|
| API PROD | v3.5.132-trial-lifecycle-foundation-unsubscribe-prod | Identique | **OK** |
| Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | Identique | **OK** |
| Website PROD | v0.6.8-tiktok-browser-pixel-prod | Identique | **OK** |

### Confirmations

- API PROD baseline = v3.5.132 : **OK**
- Client/Admin/Website inchanges : **OK**
- Aucun CronJob lifecycle PROD existant : **OK** (2 CronJobs: outbound-tick + sla-evaluator)
- Table idempotence vide avant phase : **OK** (0 rows)
- DNS interne API : `keybuzz-api.keybuzz-api-prod.svc.cluster.local:80`

---

## 4. AUDIT SOURCE LIFECYCLE

### Fichiers audites

| Brique | Fichier | Etat actuel | Risque |
|---|---|---|---|
| Service lifecycle | trial-lifecycle.service.ts (268 lignes) | `sendEmail` gate par `dryRun` (l.203) | Safe si dryRun=true |
| Routes internes | trial-lifecycle.routes.ts (87 lignes) | 404 en PROD (guard NODE_ENV) | A modifier |
| Unsubscribe | trial-lifecycle-unsubscribe.ts (97 lignes) | Actif tous envs, HMAC-SHA256 | OK, pas de changement |
| Email templates | emailTemplates.ts | Partage | Pas de changement |
| sendEmail | emailService.ts | Importe par service | Non reachable si dryRun=true |
| app.ts | Routing principal | trialLifecycleRoutes prefix `/internal` | OK |

### Confirmations

- tick/candidates 404 en PROD actuellement : **OUI**
- dryRun true par defaut : **OUI** (`body.dryRun !== false`)
- dryRun=false + force=true : DEV seulement
- recipientOverride : DEV-only (`validateRecipientOverride` retourne null en PROD)
- unsubscribe PROD actif : **OUI**
- CronJob lifecycle : **AUCUN**

---

## 5. DESIGN SECURISE PROD DRY-RUN

### Decisions

| Decision | Valeur | Justification |
|---|---|---|
| Auth | `X-Lifecycle-Token` header vs `COOKIE_SECRET` | Reutilise secret existant `keybuzz-api-jwt` |
| Comparaison | `crypto.timingSafeEqual` | Timing-safe, standard crypto Node.js |
| PROD routes | Enregistrees avec auth + `dryRun=true` hardcode | Permet au CronJob d'appeler |
| PROD rejections | 403 pour dryRun=false, force=true, recipientOverride | Triple protection |
| sendEmail reachable PROD | **NON** — `executeLifecycleTick(true, {})` hardcode | `if (dryRun) return result` avant sendEmail |
| DB write PROD dry-run | **NON** — dry-run ne fait aucun INSERT | Aucune mutation |
| Response PROD | PII-stripped (counts + exclusion reasons) | Safe pour logs |
| DEV | Comportement inchange | Zero regression |
| CronJob image | `curlimages/curl:8.7.1` (version fixe) | Pas de `:latest` |
| CronJob DNS | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80` | DNS interne K8s |
| CronJob auth | `keybuzz-api-jwt.COOKIE_SECRET` via `secretKeyRef` | Meme secret que l'API |

### Architecture de securite PROD

```
CronJob (curl avec X-Lifecycle-Token)
  -> POST /internal/trial-lifecycle/tick {dryRun: true}
    -> verifyLifecycleToken() [timingSafeEqual vs COOKIE_SECRET]
    -> Rejet 403 si dryRun=false / force=true / recipientOverride
    -> executeLifecycleTick(true, {})  [dryRun TOUJOURS true]
      -> Calcul candidats (SELECT, zero mutation)
      -> return result [AVANT sendEmail]
    -> Response PII-stripped
```

`sendEmail()` est IMPOSSIBLE a atteindre en PROD : `executeLifecycleTick(true, {})` avec le premier argument hardcode a `true` fait que la ligne `if (dryRun) return result;` (service.ts:203) execute TOUJOURS le return avant d'atteindre `sendEmail` (service.ts:240).

---

## 6. PATCH API

### Fichier modifie (1 seul)

| Fichier | Changement | Risque | Validation |
|---|---|---|---|
| `trial-lifecycle.routes.ts` | +101/-3 : PROD dry-run routes avec auth | Faible (dryRun hardcode) | tsc OK, runtime OK |

### Modifications

1. **Suppression guard `NODE_ENV !== 'production'`** : remplace par deux branches `isProd` / `!isProd`
2. **Ajout `verifyLifecycleToken()`** : comparaison `X-Lifecycle-Token` vs `COOKIE_SECRET` via `timingSafeEqual`
3. **Ajout `aggregateExclusions()`** : agrege les raisons d'exclusion sans PII
4. **PROD branch** : `executeLifecycleTick(true, {})` hardcode, rejets 403, response PII-stripped
5. **DEV branch** : comportement identique a Y.7.1 (inchange)
6. **Unsubscribe routes** : aucune modification

### Commit

- Commit : `6afa4b1a` — `feat(lifecycle): PROD dry-run-only routes with X-Lifecycle-Token auth (PH-SAAS-T8.12Y.9A)`
- Branche : `ph147.4/source-of-truth`
- Push : `origin/ph147.4/source-of-truth`

---

## 7. VALIDATION STATIQUE

| Check | Attendu | Resultat |
|---|---|---|
| tsc --noEmit | 0 erreur | **0** |
| sendEmail reachable PROD | Non | **Non** (executeLifecycleTick(true) hardcode) |
| dryRun=false rejection | 403 | **OUI** (l.62) |
| force=true rejection | 403 | **OUI** (l.65) |
| recipientOverride rejection | 403 | **OUI** (l.69) |
| timingSafeEqual | Present | **OUI** (l.30) |
| Secrets dans fichiers lifecycle | 0 | **0** |
| em dash dans runtime | 0 | **0** (commentaires seulement) |
| CronJob/setInterval/setTimeout | 0 | **0** |

---

## 8. BUILD DEV

| Element | Valeur |
|---|---|
| Source commit | `6afa4b1a` |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.139-trial-lifecycle-prod-dryrun-guard-dev` |
| Digest | `sha256:42276ce4375f5cddf901449ee9f8403d7aef604c63af3773c1de7e87cd495e91` |
| Build method | `docker build --no-cache` depuis source propre |
| tsc build | Succes (0 erreur) |
| Rollback | `v3.5.138-lifecycle-visible-unsubscribe-copy-dev` |

---

## 9. VALIDATION DEV (6/6 PASS)

| Test DEV | Attendu | Resultat |
|---|---|---|
| dry-run tick (no auth needed DEV) | 200, dryRun=true, 0 sent | **PASS** (47 candidats) |
| candidates | 200, dryRun=true | **PASS** |
| dryRun=false sans force | 400 | **PASS** |
| unsubscribe sans token | 400 | **PASS** |
| health | 200 | **PASS** |
| idempotence rows | inchange (2, tests Y.7) | **PASS** |

GitOps DEV : commit `7f17632`, push OK, rollout OK, health OK.

---

## 10. BUILD PROD

| Element | Valeur |
|---|---|
| Source commit | `6afa4b1a` |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.133-trial-lifecycle-cron-dryrun-prod` |
| Digest | `sha256:de1fd2704a73d1d3464a6ad1a3748d806bfc350bada90c421b8a2c8ed275c095` |
| Build method | `docker build --no-cache` depuis source propre |
| tsc build | Succes |
| Rollback | `v3.5.132-trial-lifecycle-foundation-unsubscribe-prod` |

---

## 11. GITOPS API PROD

| Etape | Resultat |
|---|---|
| Manifest modifie | `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` |
| Image | `v3.5.132-...` -> `v3.5.133-trial-lifecycle-cron-dryrun-prod` |
| Commit infra | `c026425` |
| Push | `main -> main` OK |
| kubectl apply | `deployment.apps/keybuzz-api configured` |
| Rollout status | `successfully rolled out` |
| Manifest = runtime | **OUI** (`v3.5.133-trial-lifecycle-cron-dryrun-prod`) |
| Pod | `keybuzz-api-549478ccd7-wtptg 1/1 Running` |
| Health | `HTTP 200 {"status":"ok"}` |

---

## 12. GITOPS CRONJOB PROD

### Manifest cree

- Fichier : `keybuzz-infra/k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml`
- Commit : `2fd4864`
- Push : `main -> main` OK

### Configuration CronJob

| Champ | Valeur | Justification |
|---|---|---|
| name | `trial-lifecycle-dryrun` | Descriptif, prefix `trial-lifecycle` |
| namespace | `keybuzz-api-prod` | Meme namespace que l'API |
| schedule | `0 8 * * *` (daily 08:00 UTC = 10:00 Paris) | Quotidien, heure de bureau |
| image | `curlimages/curl:8.7.1` | Version fixe, pas de `:latest` |
| auth | `X-Lifecycle-Token` via `secretKeyRef` `keybuzz-api-jwt.COOKIE_SECRET` | Reutilise secret existant |
| body | `{"dryRun":true}` | Hardcode dans le manifest |
| URL | `http://keybuzz-api.keybuzz-api-prod.svc.cluster.local:80` | DNS interne K8s |
| concurrencyPolicy | Forbid | Pas d'execution parallele |
| successfulJobsHistoryLimit | 3 | Historique raisonnable |
| failedJobsHistoryLimit | 3 | Historique raisonnable |
| ttlSecondsAfterFinished | 86400 | Nettoyage apres 24h |
| restartPolicy | Never | Pas de retry automatique |

### Deploiement

```
kubectl apply -f k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml
cronjob.batch/trial-lifecycle-dryrun created
```

### CronJobs PROD apres Y.9A

| CronJob | Schedule | Age |
|---|---|---|
| outbound-tick-processor | */1 * * * * | 83d |
| sla-evaluator | */1 * * * * | 83d |
| trial-lifecycle-dryrun | 0 8 * * * | **nouveau** |

---

## 13. VALIDATION RUNTIME PROD (12/12 PASS)

| # | Test | Attendu | Resultat |
|---|---|---|---|
| 0 | idempotence rows before | 0 | **0 PASS** |
| 1 | GET /health | 200 | **200 PASS** |
| 2 | candidates WITH auth token | 200, dryRun=true, prodSafe=true | **200 PASS** (47 total, 4 eligible, 43 exclus) |
| 3 | candidates WITHOUT token | 403 | **403 PASS** |
| 4 | tick dryRun WITH auth | 200, sent=[] | **200 PASS** (0 sent) |
| 5 | tick dryRun=false WITH auth | 403 | **403 PASS** |
| 6 | force=true WITH auth | 403 | **403 PASS** |
| 7 | recipientOverride WITH auth | 403 | **403 PASS** |
| 8 | tick WITHOUT auth | 403 | **403 PASS** |
| 9 | unsubscribe invalid token | 400 | **400 PASS** |
| 10 | idempotence rows after | 0 | **0 PASS** |
| 11 | CronJob manual trigger | Complete, dryRun=true, sent=[] | **PASS** (Job Complete 1/1 en 5s) |
| 12 | idempotence rows after CronJob | 0 | **0 PASS** |

### Preuve CronJob dry-run (log reel)

```
[2026-05-02T12:56:37Z] trial-lifecycle-dryrun starting
Response: {"dryRun":true,"prodSafe":true,"timestamp":"2026-05-02T12:56:37.422Z",
  "total":47,"eligible":4,"excluded":43,"sent":[],"errors":[],
  "byExclusion":{"billing_exempt":43},
  "byTemplate":[
    {"template":"trial-welcome","day":0,"eligible":2,"excluded":9},
    {"template":"trial-day-2","day":2,"eligible":2,"excluded":9},
    {"template":"trial-day-5","day":5,"eligible":0,"excluded":8},
    {"template":"trial-day-10","day":10,"eligible":0,"excluded":2},
    {"template":"trial-day-13","day":13,"eligible":0,"excluded":0},
    {"template":"trial-ended","day":14,"eligible":0,"excluded":8},
    {"template":"trial-grace","day":16,"eligible":0,"excluded":7}]}
[2026-05-02T12:56:37Z] trial-lifecycle-dryrun complete
```

---

## 14. NON-REGRESSION PROD (11/11 PASS)

| # | Surface | Attendu | Resultat |
|---|---|---|---|
| 1 | API health | 200 | **PASS** |
| 2 | auth/check-user | 200 | **PASS** |
| 3 | conversations | 200 | **PASS** |
| 4 | dashboard summary | 200 | **PASS** |
| 5 | AI wallet | 200 | **PASS** |
| 6 | billing current | 200 | **PASS** |
| 7 | outbound worker | 1/1 Running | **PASS** |
| 8 | CronJobs existants | inchanges (outbound-tick + sla-evaluator) | **PASS** |
| 9 | Client PROD | v3.5.147-sample-demo-platform-aware-tracking-parity-prod | **PASS (inchange)** |
| 10 | Website PROD | v0.6.8-tiktok-browser-pixel-prod | **PASS (inchange)** |
| 11 | External health | 200 | **PASS** |

---

## 15. OBSERVABILITE / LOGS

| Log | Present | Secret-free |
|---|---|---|
| dryRun=true | Oui | Oui |
| prodSafe=true | Oui | Oui |
| nombre candidats (47) | Oui | Oui |
| nombre exclus billing_exempt (43) | Oui | Oui |
| nombre eligibles (4) | Oui | Oui |
| sent=[] | Oui | Oui |
| byTemplate (7 templates avec counts) | Oui | Oui |
| token | Absent | Oui |
| secret | Absent | Oui |
| liens unsubscribe signes | Absent | Oui |
| contenu HTML email | Absent | Oui |
| emails personnels | Absent | Oui |
| tenant IDs personnels | Absent | Oui |

---

## 16. PREUVES

### Preuve 0 email PROD

- `sent: []` dans la reponse du tick PROD
- `sent: []` dans les logs CronJob PROD
- `idempotence_rows_before: 0`, `idempotence_rows_after: 0`, `idempotence_rows_after_cronjob: 0`

### Preuve 0 row idempotence creee par dry-run

- Table `trial_lifecycle_emails_sent` : 0 rows avant, pendant et apres le dry-run

### Preuve dryRun=false impossible

- `POST /internal/trial-lifecycle/tick {dryRun: false}` -> HTTP 403 `"PROD: dryRun=false is forbidden"`
- `POST /internal/trial-lifecycle/tick {force: true}` -> HTTP 403 `"PROD: force=true is forbidden"`
- `POST /internal/trial-lifecycle/tick {recipientOverride: ...}` -> HTTP 403 `"PROD: recipientOverride is forbidden"`
- `executeLifecycleTick(true, {})` : premier argument hardcode, sendEmail JAMAIS atteint

### Preuve no secret dans logs

- Reponse JSON : counts et templates uniquement, pas de tenant ID, pas d'email, pas de token
- CronJob logs : identique a la reponse JSON

### Preuve no tracking / billing / CAPI drift

- Zero Stripe event
- Zero CAPI event
- Zero GA4 event
- Zero billing mutation
- Zero tracking mutation

---

## 17. ROLLBACK GITOPS STRICT

### Rollback API PROD

```bash
# 1. Modifier deployment.yaml -> v3.5.132-trial-lifecycle-foundation-unsubscribe-prod
cd /opt/keybuzz/keybuzz-infra
sed -i 's|v3.5.133-trial-lifecycle-cron-dryrun-prod|v3.5.132-trial-lifecycle-foundation-unsubscribe-prod|' \
  k8s/keybuzz-api-prod/deployment.yaml

# 2. Commit + push
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "rollback(api-prod): revert to v3.5.132-trial-lifecycle-foundation-unsubscribe-prod"
git push origin main

# 3. Apply + verify
kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

### Rollback CronJob PROD

```bash
# 1. Supprimer ou suspendre le CronJob
cd /opt/keybuzz/keybuzz-infra

# Option A : suppression complete
rm k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml
git add k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml
git commit -m "rollback(cronjob-prod): remove trial-lifecycle-dryrun CronJob"
git push origin main
kubectl delete cronjob trial-lifecycle-dryrun -n keybuzz-api-prod

# Option B : suspension (garder le manifest, desactiver)
# Modifier le manifest: spec.suspend: true
# git add + commit + push
# kubectl apply -f k8s/keybuzz-api-prod/trial-lifecycle-dryrun-cronjob.yaml
```

---

## 18. GAPS RESTANTS

| # | Description | Impact | Phase |
|---|---|---|---|
| G1 | DEV en avance sur PROD (v3.5.139 DEV vs v3.5.133 PROD) | Normal (tags differents, meme source) | - |
| G2 | 4 tenants eligibles en PROD mais pas encore envoyes | Attendu (dry-run uniquement) | Y.9B |
| G3 | 43 tenants exclus `billing_exempt` | Normal (tenants test/internal) | - |
| G4 | Pas de UI opt-out dans le client | L'opt-out est uniquement DB + lien email | Phase client future |
| G5 | CronJob utilise `curlimages/curl:8.7.1` (image tierce) | Acceptable, version fixe | - |

---

## 19. PROCHAINE PHASE Y.9B

**PH-SAAS-T8.12Y.9B — Trial Lifecycle Controlled Send PROD** :

1. Observer les logs CronJob dry-run pendant quelques jours
2. Verifier les candidats eligibles sont coherents
3. Activer l'envoi reel progressif :
   - D'abord un seul template (trial-welcome) sur un tenant test
   - Puis tous les templates sur les tenants eligibles
4. Modifier le CronJob pour passer en mode envoi reel (`dryRun: false`)
5. Configurer les exclusions appropriees
6. Valider la reception et la delivrabilite
7. Monitoring post-activation

---

## 20. VERSIONS DEPLOYEES POST-Y.9A

| Service | DEV | PROD |
|---|---|---|
| API | `v3.5.139-trial-lifecycle-prod-dryrun-guard-dev` | `v3.5.133-trial-lifecycle-cron-dryrun-prod` |
| Client | inchange | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` |
| Website | inchange | `v0.6.8-tiktok-browser-pixel-prod` |

---

## 21. ARTEFACTS

| Type | Valeur |
|---|---|
| Rapport | `keybuzz-infra/docs/PH-SAAS-T8.12Y.9A-TRIAL-LIFECYCLE-CRONJOB-PROD-DRYRUN-ACTIVATION-01.md` |
| Commit API | `6afa4b1a` (branche `ph147.4/source-of-truth`) |
| Tag DEV | `v3.5.139-trial-lifecycle-prod-dryrun-guard-dev` |
| Digest DEV | `sha256:42276ce4375f5cddf901449ee9f8403d7aef604c63af3773c1de7e87cd495e91` |
| Tag PROD | `v3.5.133-trial-lifecycle-cron-dryrun-prod` |
| Digest PROD | `sha256:de1fd2704a73d1d3464a6ad1a3748d806bfc350bada90c421b8a2c8ed275c095` |
| Commit infra DEV | `7f17632` |
| Commit infra PROD API | `c026425` |
| Commit infra CronJob | `2fd4864` |
| CronJob | `trial-lifecycle-dryrun` (namespace `keybuzz-api-prod`) |

---

## VERDICT

**GO**

TRIAL LIFECYCLE PROD DRY-RUN CRONJOB ACTIVE — CANDIDATES OBSERVABLE — DRYRUN FALSE BLOCKED — ZERO EMAIL SENT — ZERO IDEMPOTENCE ROW CREATED BY DRY-RUN — UNSUBSCRIBE PRESERVED — NO TRACKING/BILLING/CAPI DRIFT — GITOPS STRICT — READY FOR CONTROLLED SEND PHASE
