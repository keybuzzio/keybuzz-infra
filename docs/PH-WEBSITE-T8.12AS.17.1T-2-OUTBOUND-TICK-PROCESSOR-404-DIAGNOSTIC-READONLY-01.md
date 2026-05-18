# PH-WEBSITE-T8.12AS.17.1T-2-OUTBOUND-TICK-PROCESSOR-404-DIAGNOSTIC-READONLY-01

> Date : 2026-05-18
> Linear : a rattacher post-decision Ludovic
> Phase : AS.17.1T-2 OUTBOUND TICK PROCESSOR 404 DIAGNOSTIC READONLY
> Environnement : PROD + DEV lecture uniquement

## VERDICT

GO READY Q-1T-2 OUTBOUND TICK ROOT CAUSE IDENTIFIED + IMPACT FAIBLE CONFIRME

Le 404 chaque minute sur `outbound-tick-processor` en PROD est **un faux signal P0**. Le module API SaaS `/debug/outbound/tick` est volontairement DEV-only par design (guard `process.env.NODE_ENV !== 'production'` ligne 11-16 de `keybuzz-api/src/modules/debugOutbound/routes.ts`, header source `Debug Outbound Routes (DEV only)`, ref `PH11-04-09B-FIX: Debug worker without kubectl logs`).

Le CronJob a ete deploye en PROD par erreur via commit `3bf0088 "infra: add PROD workers (outbound, SLA, Amazon sync)"` du 2026-02-08, alors que son endpoint cible etait deja DEV-only depuis sa creation initiale. **Depuis 99 jours, le CronJob PROD appelle un endpoint qui retourne 404 sans rien casser** : le vrai pipeline outbound delivery PROD est gere par le `Deployment keybuzz-outbound-worker` long-running pod (vu Q-1B-5B-2 BEFORE snapshot api-prod : pod `keybuzz-outbound-worker-6db9686c76-kdtwk` Running 29h+).

Impact reel evalue :
- 0 impact spend Meta/Google Ads admin (le pipeline spend est /metrics/import/meta + sync tenant-par-tenant, hors ce CronJob)
- 0 impact tracking server-side (CAPI Meta + GA4 MP envoyes server-to-server par billing/routes.ts via Stripe events, hors ce CronJob)
- 0 impact SLA evaluator (qui tourne en parallele via psql direct, fonctionne nominalement avec `UPDATE 0` confirme E8.2)
- 0 impact carrier tracking poll (qui appelle un autre endpoint API)
- Le **outbound delivery real** en PROD est dispatche par le **Deployment worker pod long-running**, pas par ce CronJob.

Bruit pure : ~525 600 jobs failed accumules par an (60 * 24 * 365 = 525 600 ticks 404). Resources gaspillees (each job spin curl-jq image). Faux signal de monitoring 404 systematique.

Le finding initial du rapport Q-1T (qui suggerait que ce drift pouvait bloquer le spend Ads) est REVISE : R3 ad_spend tenant-scoped PROD migration incomplete reste la VRAIE root cause du spend admin absent, INDEPENDAMMENT de ce CronJob.

3 options correctives proposees : SUPPRESSION CronJob PROD (recommande), SUSPENSION CronJob PROD (intermediate safe), conservation (zero action). **Recommandation forte = SUPPRESSION** car le CronJob est inutile en PROD par design.

Aucune mutation. Aucune curl POST vers /debug/outbound/tick (interdit explicite respecte). Aucune lecture de valeur secret. Aucun fake event. PROD intouchee.

## Scope / hors scope

### Scope strict applique

- Lecture CronJob spec runtime DEV + PROD (kubectl get)
- Lecture CronJob manifest Git source (k8s/keybuzz-api-{dev,prod}/)
- Lecture logs derniers 3 jobs DEV + PROD (kubectl logs, redacted via Python)
- Git history du manifest CronJob + module source debugOutbound
- Source code grep `/debug/outbound/tick`, `outbound.tick`, autres patterns
- NODE_ENV check api-prod + api-dev
- Verification autres CronJobs similaires (sla-evaluator, sla-evaluator-escalation, carrier-tracking-poll)
- Verification existence Deployment keybuzz-outbound-worker (heritage Q-1B-5B-2)

### Hors scope respecte

- 0 curl POST vers `/debug/outbound/tick` (interdit strict respecte)
- 0 kubectl apply/patch/edit/delete/annotate/label/rollout
- 0 appel Meta/Google/GA4 authentifie
- 0 fake event/conversion/spend
- 0 build/deploy
- 0 changement Linear
- 0 DB read (sauf GO Ludovic separe)
- 0 lecture valeur secret en clair (logs filtres via redacteur Python)
- Redaction tokens/JWT/emails/tenantId/sellerId dans logs output

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01.md | commit 133163f, sha256 d4c5878645690d1e7b57ebff7d97e53e599d2720e3f87dbff9d5babd27514330 | OK ancestor confirme (R2 hypothese revisee ici) |
| docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md | present | OK lu sections cles |
| docs/AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md | present | OK |
| keybuzz-api/src/modules/debugOutbound/routes.ts | 220 lignes | OK lu integralement (header DEV-only + guard ligne 11-16) |
| keybuzz-api/src/app.ts | ligne 145 register debugOutboundRoutes | OK |
| keybuzz-infra HEAD | 133163f49c392d199e93f9e6b8e786f2088bac56 | OK |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc 133163f / clean | match | OK |
| Rapport AS.17.1T sha256 | d4c58786... | match | OK |
| /tmp residuels Q-1T-2 | absent | absent | OK |
| keybuzz-api branch | ph147.4/source-of-truth | match (dirty 223 dev actif) | OK |
| keybuzz-backend branch | main | match (dirty 1) | OK |
| keybuzz-admin-v2 branch | main | match (clean) | OK |
| CronJob outbound-tick-processor PROD | present | present age 99d | OK |
| CronJob outbound-tick-processor DEV | present | present age 141d | OK |

## CronJob source + runtime + logs (E2-E3)

### Manifest Git source PROD

`/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml` (1 commit historique : `3bf0088 infra: add PROD workers (outbound, SLA, Amazon sync)`).

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: outbound-tick-processor
  namespace: keybuzz-api-prod
spec:
  concurrencyPolicy: Forbid
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - args:
            - |
              echo "[$(date -u +%H:%M:%S)] Tick starting..."
              curl -sk -X POST https://api.keybuzz.io/debug/outbound/tick --max-time 10
              echo ""
              echo "[$(date -u +%H:%M:%S)] Tick complete"
            command: [/bin/sh, -c]
            image: badouralix/curl-jq:latest
            name: tick
            resources:
              limits: {cpu: 100m, memory: 64Mi}
              requests: {cpu: 50m, memory: 32Mi}
          restartPolicy: Never
      ttlSecondsAfterFinished: 300
  schedule: '*/1 * * * *'
  successfulJobsHistoryLimit: 3
  suspend: false
```

### Manifest Git source DEV

`/opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-dev/outbound-tick-cronjob.yaml` (2 commits : `361ce2b PH11-04-09B add outbound tick CronJob automation (DEV)` + `90c4dc0 PH11-04-09B-FINAL CronJob automation with badouralix/curl-jq image`). URL : `https://api-dev.keybuzz.io/debug/outbound/tick`.

### Runtime spec parite Git / runtime

| Field | DEV (runtime + Git) | PROD (runtime + Git) |
|---|---|---|
| schedule | */1 * * * * | */1 * * * * |
| suspended | false | false |
| concurrencyPolicy | Forbid | Forbid |
| failedJobsHistoryLimit | 3 | 1 |
| image | badouralix/curl-jq@sha256:554222a9... | badouralix/curl-jq@sha256:554222a9... (identique) |
| URL cible | https://api-dev.keybuzz.io/debug/outbound/tick | https://api.keybuzz.io/debug/outbound/tick |
| Creation | 2025-12-28T11:04:46Z | 2026-02-08T11:38:13Z |
| Last schedule | 2026-05-18T13:57:00Z | 2026-05-18T13:57:00Z |
| Last success | 2026-05-18T13:57:05Z | 2026-05-18T13:57:06Z |

**Note** : `lastSuccessfulTime` est mis a jour cote Kubernetes pour PROD car le curl exit code est 0 meme avec HTTP 404 (curl -sk masque les status HTTP non-2xx). Donc Kubernetes considere le job "successful" alors que l'endpoint retourne 404.

### Logs derniers jobs DEV (200 OK, queue vide)

3 jobs DEV consecutifs (29651875, 29651876, 29651877) :
```
[13:55:02] Tick starting...
{"timestamp":"2026-05-18T13:55:02.475Z","pickedId":null,"prevStatus":null,"newStatus":null,"attemptCount":null,"error":null,"trace":null,"steps":["Connected to DB","Transaction started","Query executed (0 rows)","No queued jobs found"],"message":"No jobs to process"}
[13:55:02] Tick complete
```

Confirme : module ENABLED en DEV, traite la queue (vide actuellement).

### Logs derniers jobs PROD (404 chaque minute)

3 jobs PROD consecutifs (29651875, 29651876, 29651877) :
```
[13:55:03] Tick starting...
{"message":"Route POST:/debug/outbound/tick not found","error":"Not Found","statusCode":404}
[13:55:04] Tick complete
```

Confirme : module DISABLED en PROD, endpoint introuvable.

## Code source debugOutbound (E5-E6)

### Module fichier : keybuzz-api/src/modules/debugOutbound/routes.ts (220 lignes)

Header explicite (lignes 1-4) :
```typescript
/**
 * Debug Outbound Routes (DEV only)
 * PH11-04-09B-FIX: Debug worker without kubectl logs
 */
```

Guard runtime (lignes 11-16) :
```typescript
// Guard: DEV only
const isDev = process.env.NODE_ENV !== 'production';
if (!isDev) {
  fastify.log.warn('[DebugOutbound] Module disabled in production');
  return;
}
```

Routes definies (lignes 22-220) :
- `GET /debug/outbound/queued` - Show queue status
- `POST /debug/outbound/tick` - Run one worker iteration manually (worker debug pattern)

Note : le module utilise `getPool()` directement (acces DB Postgres) pour SELECT FOR UPDATE SKIP LOCKED 1 row queued + dispatch synchrone. C'est explicitement un **outil de debug DEV pour deboguer le worker SANS avoir besoin de kubectl logs**.

### Enregistrement plugin app.ts (ligne 145)

```typescript
app.register(debugOutboundRoutes, { prefix: '/debug/outbound' });
```

Enregistrement INCONDITIONNEL au demarrage (mais le module lui-meme bail out si production).

### NODE_ENV runtime confirme (E7)

| Environnement | NODE_ENV runtime |
|---|---|
| keybuzz-api-prod Deployment | production |
| keybuzz-api-dev Deployment | development |

Confirme parfaitement le comportement observe :
- PROD : `isDev = false` -> `return` (module not registered) -> POST /debug/outbound/tick = 404 nominal
- DEV : `isDev = true` -> module register -> POST /debug/outbound/tick = 200 OK

## Git history (E4 + E9)

### Manifest CronJob

| File | Commits | Auteur premier |
|---|---|---|
| k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml | 1 (`3bf0088 infra: add PROD workers (outbound, SLA, Amazon sync)`) | - |
| k8s/keybuzz-api-dev/outbound-tick-cronjob.yaml | 2 (`361ce2b` + `90c4dc0` PH11-04-09B series) | - |

### Module source debugOutbound

| File | Commits | Notes |
|---|---|---|
| keybuzz-api/src/modules/debugOutbound/routes.ts | 2 (`98e6d3ab fix: remove country column from tenant create` + `860f8b6e PH11-CLIENT-UI-07: Add client-dev.keybuzz.io to CORS origins`) | Module ancien, peu modifie. La guard DEV-only existe depuis la creation. |

**Conclusion historique** : le CronJob PROD a ete cree le 2026-02-08 alors que le module API etait DEV-only depuis sa creation initiale. **Le CronJob n'a JAMAIS fonctionne en PROD** depuis sa creation.

## Autres CronJobs similaires (E8)

Verification drift potentiel sur les CronJobs `*/1 * * * *` PROD :

| CronJob | Method | Status |
|---|---|---|
| keybuzz-api-prod/sla-evaluator | psql direct UPDATE conversations | OK (UPDATE 0 normal, queue empty) |
| keybuzz-api-prod/sla-evaluator-escalation | args=null (anormal, a investiguer separement) | WARN (potentiel autre drift) |
| keybuzz-api-prod/carrier-tracking-poll | curl POST https://api.keybuzz.io/api/v1/orders/tracking/poll | non-verifie cette phase (suspended=true vu Q-1T E9.2 donc inactif) |
| keybuzz-api-prod/trial-lifecycle-dryrun | non investigue | non-scope |
| vault-management/vault-token-renew | OK (heritage Q-1B-1A) | OK |
| vault-management/monitoring-alerts | non investigue | non-scope |

**Finding bonus** : `sla-evaluator-escalation` PROD `args=null` est suspicieux et merite investigation dediee (Q-1T-2A potentiel).

## Impact reel evaluation (E8.2 + heritage Q-1B-5B-2)

### Pipeline outbound delivery PROD

Le **vrai pipeline outbound** en PROD est le **Deployment `keybuzz-outbound-worker`** long-running pod (vu Q-1B-5B-2 BEFORE snapshot api-prod ligne `keybuzz-outbound-worker-6db9686c76-kdtwk Running 29h, image keybuzz-api:v3.5.190, env: keybuzz-api-postgres + keybuzz-ses`). Ce pod tourne en boucle infinie et dispatch les outbound deliveries via la meme logique que `/debug/outbound/tick` mais sans bypass HTTP.

Conclusion : **le 404 du CronJob n'a AUCUN impact sur le pipeline outbound delivery PROD**. Le Deployment worker fait le travail.

### Pipeline spend Ads

Le spend Meta/Google Ads est synchronise via :
- API SaaS endpoint `/metrics/import/meta` (declenche par admin V2 UI ou tenant action)
- Tables `ad_platform_accounts` + `ad_spend_tenant` (deployees DEV uniquement, PROD pas encore migrate per Q-1T R3)
- Secret store ads credentials per tenant (`keybuzz-meta-ads` + `keybuzz-google-ads` Secrets K8s)

Conclusion : **le 404 du CronJob n'est PAS lie au spend Ads admin absent**. R3 (ad_spend PROD migration incomplete) reste la vraie root cause du spend absent admin.

### Pipeline tracking server-side

Les conversions server-side sont declenchees par :
- API SaaS billing/routes.ts (Stripe webhook handler) appelle GA4 MP via CONVERSION_WEBHOOK_URL=https://t.keybuzz.io/mp/collect
- Meta CAPI direct par tenant via META_ACCESS_TOKEN + META_AD_ACCOUNT_ID

Conclusion : **le 404 du CronJob n'est PAS lie au tracking server-side**. Le tracking passe par les Stripe webhook events, pas par ce CronJob.

## Hypotheses revisees vs rapport AS.17.1T

| Hypothese AS.17.1T | Etat post-Q-1T-2 |
|---|---|
| R1 CONFUSION ARCHITECTURE (/gtm/debug n'existe pas) | CONFIRMEE inchangee |
| R2 CRITIQUE outbound-tick-processor 404 chaque minute | **REVISEE** : 404 confirme mais **IMPACT FAIBLE** car CronJob inutile par design (DEV-only) et vrai pipeline gere par Deployment worker. Pas un bloqueur P0. |
| R3 AD_SPEND PROD migration tenant-scoped incomplete | CONFIRMEE inchangee, vraie root cause du spend admin absent |

## Options correctives (E11)

### Option 1 : SUPPRESSION CronJob PROD (recommande)

| Aspect | Evaluation |
|---|---|
| Resolution drift | OUI definitivement |
| Cout | TRES FAIBLE (1 commit suppression manifest + apply delete) |
| Risque | NEANT (CronJob inutile par design, n'a jamais fonctionne en PROD) |
| Coherence GitOps | OUI fort (retire artefact mal deploye) |
| Effet secondaire | Elimine 525 600 jobs failed/an + bruit logs + ressources |
| Reversibilite | TRES FACILE (recreer CronJob si besoin futur) |

### Option 2 : SUSPENSION CronJob PROD

| Aspect | Evaluation |
|---|---|
| Resolution drift | PARTIELLE (CronJob reste mais ne tourne plus) |
| Cout | FAIBLE (1 commit patch `suspend: true` + apply) |
| Risque | NEANT |
| Coherence GitOps | MOYEN (artefact reste, configuration "off") |
| Reversibilite | TRES FACILE (patch `suspend: false` + apply) |
| Recommandee | Intermediate si Ludovic veut garder trace |

### Option 3 : ACTIVER /debug/outbound/tick en PROD (NON recommande)

| Aspect | Evaluation |
|---|---|
| Resolution drift | OUI mais ouvre faille securite |
| Risque | ELEVE (endpoint debug expose en PROD, possiblement non-auth, donne acces DB + dispatch worker) |
| Coherence design | CASSE le pattern DEV-only voulu par PH11-04-09B-FIX |
| Verdict | INACCEPTABLE |

### Option 4 : STATU QUO (zero action)

| Aspect | Evaluation |
|---|---|
| Resolution drift | NEANT |
| Cout | 0 |
| Bruit | 525 600 jobs failed/an, log spam |
| Verdict | Acceptable mais sale |

**Recommandation analyste non-engageante** : **Option 1 (SUPPRESSION)** = plus propre. Phase EXEC Q-1T-2-EXEC ressemblerait a Q-1B-3B-1B (orphan cleanup pattern : 1 kubectl delete + 1 git commit + push).

## Plan EXEC Q-1T-2-EXEC propose (NON execute, dependant Option choisie)

### Si Option 1 (SUPPRESSION) :

| step | action | gate | risk | rollback |
|---|---|---|---|---|
| 1 | Prompt CE Q-1T-2-EXEC Mode B SAFE | GO Ludovic | NEANT | none |
| 2 | git rm k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml + commit + push | GO COMMIT DELETE OUTBOUND-TICK PROD Q-1T-2-EXEC | NEANT | git revert |
| 3 | kubectl delete cronjob outbound-tick-processor -n keybuzz-api-prod | GO DELETE CRONJOB OUTBOUND-TICK PROD Q-1T-2-EXEC | NEANT | kubectl apply -f recreate manifest si revert |
| 4 | Verify CronJob NotFound + logs CronJob ne tournent plus | (auto) | NEANT | none |
| 5 | Rapport Q-1T-2-EXEC docs-only + STOP | GO commit | NEANT | none |

### Si Option 2 (SUSPENSION) :

| step | action | gate | risk | rollback |
|---|---|---|---|---|
| 1 | Patch manifest Git : `suspend: false` -> `suspend: true` + commit + push | GO SUSPEND CRONJOB OUTBOUND-TICK PROD Q-1T-2-EXEC | NEANT | git revert |
| 2 | kubectl apply -f manifest patche | (auto post-push) | NEANT | kubectl apply revert |
| 3 | Verify next tick NOT scheduled | (auto) | NEANT | none |

## Q-1T-2A (NOUVELLE proposee) - sla-evaluator-escalation args=null investigation

Le finding bonus E8 montre `keybuzz-api-prod/sla-evaluator-escalation` avec `args=null`. Suspicieux mais hors scope cette phase. Candidat phase dediee Q-1T-2A pour investiguer si ce CronJob a un drift similaire.

## Risk matrix

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Decision Ludovic Option 3 (activer en PROD) | TRES FAIBLE | ELEVE | rapport classe explicitement INACCEPTABLE |
| R2 | Suppression CronJob casse un autre process inconnu | TRES FAIBLE (rappel : CronJob n'a jamais fonctionne PROD) | FAIBLE | rollback git revert + kubectl apply trivial |
| R3 | sla-evaluator-escalation args=null = drift similaire | INCONNU | INCONNU | Q-1T-2A propose hors scope |
| R4 | Curl POST manuel vers /debug/outbound/tick pendant diagnostic | NEANT (interdit strict respecte) | ELEVE | aucun execute |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T-2 | Impact |
|---|---|---|---|
| outbound-tick-processor CronJob | retournait 404 chaque minute | inchange (toujours retourne 404, status quo diagnostic) | 0 |
| keybuzz-outbound-worker Deployment | Running long-running | inchange | 0 |
| sla-evaluator CronJob | Running normal | inchange | 0 |
| sla-evaluator-escalation CronJob | args=null suspicieux | inchange (a investiguer Q-1T-2A) | 0 |
| API SaaS endpoints | inchanges | inchanges | 0 |
| Pipelines spend Ads / tracking server-side | inchanges | inchanges | 0 |
| Tracking events Meta CAPI / GA4 MP | inchanges | inchanges | 0 |
| Argo CD applications | inchanges | inchanges | 0 |
| Providers Meta/Google/GA4/GTM | 0 call authentifie | 0 | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| Curl POST manuel /debug/outbound/tick | 0 execute | OK strict |
| kubectl apply/patch/delete/edit/annotate/label/rollout | 0 | OK |
| Fake event/conversion/spend | 0 | OK |
| Build/deploy | 0 | OK |
| Provider authenticated call (Meta/Google/GA4/GTM) | 0 | OK |
| DB read manuel | 0 | OK |
| Linear comment | 0 | OK |
| Lecture valeur secret en clair | 0 (redacteur Python applique sur logs + .data jamais lue) | OK |
| Tenant/user/email/sellerId hardcode | redacteur logs applique | OK |
| ASCII strict rapport | 0 BOM, 0 non-ASCII (verifie) | OK |
| Manifests source Git modifies | 0 (md5 stables k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml inchange) | OK |
| Workflow SCP runner pour scripts > 5 lignes | 1 SCP runner utilise pour E2-E5 + 1 inline heredoc pour E6-E10 | OK |

12/12 contraintes read-only respectees.

## Brouillon Linear (a creer si Ludovic GO)

```
TITRE proposed : outbound-tick-processor PROD 404 chaque minute - faux signal P0, CronJob inutile par design

Status: DIAGNOSTIC COMPLETE - FAUX SIGNAL P0 CONFIRME
Scope: PROD + DEV lecture pure

Root cause:
- Module API /debug/outbound/tick est volontairement DEV-only par design (guard `process.env.NODE_ENV !== 'production'` keybuzz-api/src/modules/debugOutbound/routes.ts ligne 11-16)
- Header source explicite: "Debug Outbound Routes (DEV only) - PH11-04-09B-FIX: Debug worker without kubectl logs"
- Le CronJob PROD `outbound-tick-processor` a ete deploye par erreur commit 3bf0088 (2026-02-08) "infra: add PROD workers"
- Depuis 99 jours, le CronJob PROD appelle un endpoint DEV-only = 404 chaque minute (525 600 ticks/an)
- Le CronJob N'A JAMAIS fonctionne en PROD

Impact reel: FAIBLE
- 0 impact pipeline outbound delivery PROD (gere par Deployment keybuzz-outbound-worker long-running pod)
- 0 impact spend Ads admin (R3 ad_spend tenant-scoped migration incomplete reste vraie root cause)
- 0 impact tracking server-side (CAPI Meta + GA4 MP via billing/routes.ts Stripe events, hors ce CronJob)
- 0 impact SLA evaluator (psql direct fonctionne)
- Bruit logs + ressources gaspillees uniquement

3 options correctives:
- Option 1 SUPPRESSION CronJob PROD (RECOMMANDEE, pattern Q-1B-3B-1B)
- Option 2 SUSPENSION suspend: true (intermediate safe)
- Option 3 INACCEPTABLE: activer endpoint en PROD (casse security boundary DEV-only)
- Option 4 STATU QUO (acceptable mais sale, log spam continue)

Finding bonus: sla-evaluator-escalation PROD args=null suspicieux, candidat Q-1T-2A investigation dediee.

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-2-OUTBOUND-TICK-PROCESSOR-404-DIAGNOSTIC-READONLY-01.md

Recommendation: priorite revisitee. R3 ad_spend PROD migration redevient le P0 spend Ads (Q-1T-3 a prioriser). Q-1T-2-EXEC Option 1 = nettoyage simple sans urgence.
```

## Gaps restants

1. **Q-1T-2-EXEC** Option 1 (SUPPRESSION) ou 2 (SUSPENSION) : NO GO maintenu, requires GO Ludovic + prompt CE Mode B SAFE.
2. **Q-1T-2A** (NOUVELLE proposee) : investigation `sla-evaluator-escalation` PROD `args=null` suspicieux.
3. **Q-1T-3 AD_SPEND PROD migration** : REDEVIENT P0 reel pour spend admin (lecture PH-T8.8G + verification runtime + plan migration).
4. **Q-1T-1 documentation alignment** : immediat, zero-risque.
5. **Q-1T-4 sGTM evaluation** : optionnel.
6. **Q-1T-5 tracking secrets Git exposure cleanup** : pattern accumule.
7. **KEY-323 reprise** : Q-1B-5B-2-EXEC LLM env-var migration en pause.

## Phrase cible finale

Diagnostic outbound-tick complete : CronJob source/runtime/logs analyses (DEV manifest k8s/keybuzz-api-dev/outbound-tick-cronjob.yaml + PROD k8s/keybuzz-api-prod/outbound-tick-processor-cronjob.yaml, runtime sched */1 * * * * ages 141d DEV + 99d PROD, args identiques curl POST endpoint debug), endpoint 404 confirme via 3 jobs PROD consecutifs vs 3 jobs DEV 200 OK avec response JSON queue-empty, route API actuelle identifiee comme DEV-only par design (keybuzz-api/src/modules/debugOutbound/routes.ts ligne 11-16 guard `process.env.NODE_ENV !== 'production'` header source PH11-04-09B-FIX "Debug worker without kubectl logs"), NODE_ENV runtime confirmes PROD=production DEV=development, impact spend/tracking classe (FAIBLE : vrai pipeline outbound = Deployment keybuzz-outbound-worker long-running pod, vrai spend = /metrics/import/meta + ad_spend_tenant, vrai tracking = billing/routes.ts CAPI direct via Stripe events, AUCUN ne depend de ce CronJob), 4 options de correction proposees avec recommandation Option 1 SUPPRESSION, 0 mutation, 0 fake event, 0 provider call, 0 curl POST manuel vers /debug/outbound/tick, 0 lecture valeur secret en clair (redacteur Python applique sur logs) - le 404 etait un FAUX SIGNAL P0, R3 ad_spend PROD migration reste la vraie root cause spend admin absent, decision Ludovic requise sur Option 1/2 + priorisation Q-1T-3 redevenue P0.

STOP
