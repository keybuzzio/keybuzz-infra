# PH-SAAS-T8.12AB — 17TRACK Order Tracking Activation Layer DEV

> **Date** : 3 mai 2026
> **Type** : restauration activation CronJob + polling DEV
> **Environnement** : DEV uniquement
> **Priorite** : P0
> **Linear** : KEY-240
> **Mutations DB** : 18 (17 tracking_events + 1 order update, via poll controlé)
> **Builds** : 0
> **Deploys** : 0 (CronJob GitOps uniquement)

---

## SOURCES RELUES

| Document | Lu |
|---|:---:|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | OUI |
| `AI_MEMORY/RULES_AND_RISKS.md` | OUI |
| `PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md` | OUI |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | OUI |
| `keybuzz-infra/k8s/keybuzz-api-dev/outbound-tick-cronjob.yaml` | OUI (pattern reference) |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | reference |

---

## RAPPEL VERITE AA

| Couche | Etat AA | Etat AB verifie |
|---|---|---|
| Source API | OK — 6 fichiers branches app.ts | Idem |
| Runtime DEV | OK — dist compiles, routes 200 | Idem |
| `/tracking/status` | OK — `17track configured: true` | Idem |
| Secrets K8s | OK — `tracking-17track` DEV + PROD | Idem |
| DB schema | OK — `tracking_events` + colonnes orders | Idem |
| CronJob polling | **ABSENT** | **CREE via GitOps** |
| Webhook | DORMANT | Route active, accepte POST (200 OK) |
| Client UI | OK | Non modifie |
| IA context | OK | Non modifie |

---

## ETAPE 0 — PREFLIGHT

### Repos

| Repo | Branche attendue | Branche constatee | HEAD | Verdict |
|---|---|---|---|---|
| `keybuzz-infra` | `main` | `main` | `662f750` → `b0db751` (apres commit) | OK |
| `keybuzz-api` (bastion) | `ph147.4/source-of-truth` | Verifie via AA | `adaf1821` | OK |

### Runtime / Manifest

| Element | Attendu | Constate | Verdict |
|---|---|---|---|
| Image API DEV manifest | `v3.5.141-lifecycle-pilot-safety-gates-dev` | `v3.5.141-lifecycle-pilot-safety-gates-dev` | OK |
| Image API DEV runtime | idem | `ghcr.io/keybuzzio/keybuzz-api:v3.5.141-lifecycle-pilot-safety-gates-dev` | OK |
| Image API PROD runtime | `v3.5.135-lifecycle-pilot-safety-gates-prod` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.135-lifecycle-pilot-safety-gates-prod` | OK |
| CronJobs DEV (avant) | 3 (outbound-tick, sla-evaluator, sla-escalation) | 3 CronJobs confirmes | OK |
| CronJobs PROD (avant) | 3 (outbound-tick, sla-evaluator, trial-lifecycle-dryrun) | 3 CronJobs confirmes | OK |
| CronJob carrier-tracking-poll | ABSENT | ABSENT (avant creation) | OK |

### Confirmations

- PROD ne sera pas modifiee : **CONFIRME**
- Aucun build prevu : **CONFIRME**
- Objectif = activation DEV par GitOps : **CONFIRME**

---

## ETAPE 1 — CONTRAT ENDPOINT POLLING

Source : `src/modules/orders/carrierTracking.routes.ts` + `carrierLiveTracking.service.ts` (366 lignes)

| Element | Valeur | Preuve source |
|---|---|---|
| Endpoint | `POST /api/v1/orders/tracking/poll` | carrierTracking.routes.ts L62-67 |
| Methode | POST | idem |
| Auth requise | Non — pas de middleware auth, X-Tenant-Id optionnel | idem |
| Payload requis | Body JSON vide `{}` (sinon Fastify 400) | Teste en AB |
| Limite batch | `LIMIT 100` ordres par poll | carrierLiveTracking.service.ts L260 |
| Filtres SQL | tracking_code non vide, pas cancelled, pas delivered, pas checke < 30 min | carrierLiveTracking.service.ts L250-258 |
| Auto-register 17TRACK | 5 premiers ordres par poll | carrierLiveTracking.service.ts L270 |
| Tables ecrites | `tracking_events` (INSERT ON CONFLICT DO NOTHING), `orders` (UPDATE) | carrierLiveTracking.service.ts L283-320 |
| Idempotence | OUI — `ON CONFLICT (order_id, event_status, event_timestamp, source) DO NOTHING` | carrierLiveTracking.service.ts L283-293 |
| Erreurs possibles | HTTP 429 17TRACK (rate limit), No data (tracking non enregistre) | Logs observes |
| Impact billing | Aucun | Verifie — aucune reference wallet/billing/KBActions |
| Impact marketing | Aucun | Verifie — aucune reference CAPI/GA4/LinkedIn |
| Logs | `[PH133-C] Tracking poll triggered`, `[PH133-C] Poll result:`, `[Carrier] Polling N orders` | Source |

---

## ETAPE 2 — AUDIT DB DEV AVANT ACTIVATION

| Metrique DEV avant | Valeur |
|---|---|
| tracking_events total | 32 316 |
| tracking_events source `aggregator_17track` | 87 |
| max created_at 17TRACK | 2026-03-31T07:27:58Z |
| orders total | 11 974 |
| orders avec tracking_code | 125 |
| orders tracking_source = `aggregator_17track` | 8 |
| orders avec carrier_delivery_status | 8 |
| orders candidats poll | 117 |
| tracking_source breakdown | amazon_estimate: 11924, amazon_report: 40, aggregator_17track: 8, shopify: 2 |

---

## ETAPE 3 — VERIFICATION SECRET / ENV DEV

| Check | Resultat | Secret expose ? |
|---|---|---|
| Secret `tracking-17track` existe DEV | OUI (`EXISTS`) | Non |
| Cle `TRACKING_17TRACK_API_KEY` presente | OUI (44 chars base64) | Non — longueur seule |
| Env montee dans deployment API DEV | OUI — L193-198 deployment.yaml | Non |
| Route `/tracking/status` voit `configured: true` | OUI — `"17track","configured":true` | Non |

---

## ETAPE 4 — TEST CONTROLE POLLING DEV

### Premier essai (echec attendu)

| Test | Attendu | Resultat |
|---|---|---|
| POST sans body JSON | Erreur parsing | 400 `Unexpected end of JSON input` |
| Cause | Fastify parse content-type application/json avec body vide | Confirme |

### Deuxieme essai (succes)

| Test | Attendu | Resultat |
|---|---|---|
| POST avec body `{}`, tenant `ecomlg-001` | Poll des candidats | **200 OK** |
| Reponse | `{polled, updated, errors, noAdapter}` | `{"polled":100,"updated":1,"errors":0,"noAdapter":99}` |
| Duree | < 2 min | ~30s |
| Pod restarts | 0 | 0 |

### Logs observes

```
[Tracking] 17track failed: No data (x6)
[Tracking] 17track failed: HTTP 429 (x4)
[PH133-C] Poll result: { polled: 100, updated: 1, errors: 0, noAdapter: 99 }
```

Interpretation :
- 99 ordres n'ont pas de donnees 17TRACK (non enregistres ou tracking non reconnu) → `noAdapter`
- 1 ordre UPS a recu des events carrier_live → `updated: 1`
- HTTP 429 = rate limit 17TRACK atteint sur certains appels → attendu avec 100 ordres simultanes
- 0 erreurs critiques

### DB DEV apres poll controle

| Metrique | Avant | Apres | Delta |
|---|---|---|---|
| tracking_events total | 32 316 | 32 333 | +17 |
| tracking_events 17TRACK | 87 | 87 | 0 |
| orders tracking_source carrier_live | 0 | 1 | +1 |
| orders carrier_delivery_status | 8 | 9 | +1 |
| orders recently_updated (<5min) | 0 | 1 | +1 |
| recent_events (<10min) | 0 | 17 | +17 |

Les 17 nouveaux events viennent d'un tracking UPS resolut via UPS API directe (source `carrier_live`), pas via 17TRACK. Le polling a fonctionne exactement comme prevu : chain 17TRACK → fallback UPS adapter.

---

## ETAPE 5 — CREATION CRONJOB DEV VIA GITOPS

### Manifest cree

`keybuzz-infra/k8s/keybuzz-api-dev/carrier-tracking-poll-cronjob.yaml`

| Champ CronJob | Valeur | Justification |
|---|---|---|
| name | `carrier-tracking-poll` | Convention AA + historique PH136-B |
| namespace | `keybuzz-api-dev` | DEV uniquement |
| schedule | `0 */2 * * *` (toutes les 2h) | Eviter rate limit 17TRACK (HTTP 429 observe a 100/poll) |
| concurrencyPolicy | `Forbid` | Pas de polls simultanes |
| suspend | `false` | Poll prouve safe et idempotent |
| backoffLimit | 1 | Un seul retry en cas d'echec |
| activeDeadlineSeconds | 300 (5 min) | Timeout raisonnable |
| image | `badouralix/curl-jq:latest` | Pattern identique outbound-tick-processor |
| method | `POST` avec body `{}` et content-type `application/json` | Eviter erreur 400 Fastify |
| endpoint | `https://api-dev.keybuzz.io/api/v1/orders/tracking/poll` | URL publique DEV via Ingress |
| max-time curl | 120s | Laisser le poll completer |
| resources | cpu 50m/100m, memory 32Mi/64Mi | Identique outbound-tick |
| successfulJobsHistoryLimit | 3 | Nettoyage automatique |
| failedJobsHistoryLimit | 5 | Plus de visibilite sur les erreurs |

### Decision suspend: false

Le run controle a prouve :
- Idempotence (ON CONFLICT DO NOTHING)
- Volume limite (LIMIT 100)
- Aucun impact billing/marketing
- 0 erreurs, 0 restarts pod
- Schedule 2h = max 12 polls/jour = safe

---

## ETAPE 6 — GITOPS DEV

| Action | Commande | Resultat |
|---|---|---|
| git add | `git add k8s/keybuzz-api-dev/carrier-tracking-poll-cronjob.yaml` | OK |
| git commit | `gitops(api-dev): add 17track carrier tracking poll cronjob` | `b0db751` |
| git push | `main → main` | `662f750..b0db751` |
| kubectl apply | `kubectl apply -f carrier-tracking-poll-cronjob.yaml` | `cronjob.batch/carrier-tracking-poll created` |

**Commit infra** : `b0db751` sur `main`

---

## ETAPE 7 — VALIDATION CRONJOB DEV

| Validation | Resultat |
|---|---|
| CronJob existe | OUI |
| Schedule | `0 */2 * * *` |
| Suspend | `false` |
| ConcurrencyPolicy | `Forbid` |
| Derniere execution | `<none>` (vient d'etre cree) |
| Total CronJobs DEV | 4 (carrier-tracking-poll, outbound-tick, sla-evaluator, sla-escalation) |

---

## ETAPE 8 — WEBHOOK READINESS DEV

| Check webhook | Resultat |
|---|---|
| Route POST `/api/v1/tracking/webhook/17track` | **200 OK** — `{"ok":true,"event":"unknown"}` |
| Route OPTIONS | 400 Invalid Preflight (normal, pas de CORS webhook) |
| Route registree dans app.ts | OUI — L197 `trackingWebhookRoutes` prefix `/api/v1/tracking` |
| URL DEV attendue | `https://api-dev.keybuzz.io/api/v1/tracking/webhook/17track` |
| Secret/signature | Pas de verification signature dans le code actuel (accepte tout POST) |
| Activation dashboard 17TRACK | **MANUELLE** — necessite configuration sur le dashboard 17TRACK |

### Runbook activation webhook DEV

1. Se connecter au dashboard 17TRACK (credentials dans secret `tracking-17track`)
2. Configurer le webhook push URL : `https://api-dev.keybuzz.io/api/v1/tracking/webhook/17track`
3. Activer le webhook pour les mises a jour de tracking
4. Verifier qu'un premier push arrive (logs pod API DEV)
5. Surveiller `tracking_events` avec `source='aggregator_17track'`

**Cette activation est manuelle et hors scope de cette phase AB.**

---

## ETAPE 9 — VALIDATION API / UI / IA DEV

| Surface | Resultat |
|---|---|
| GET /api/v1/orders/tracking/status | 200 OK — `17track configured: true`, 32333 events, 125 with_tracking |
| GET /health | 200 OK — `{"status":"ok","service":"keybuzz-api"}` |
| carrier_live_events apres poll | 17 (nouveaux) |
| Client DEV | Non modifie — pas de build/deploy client |
| IA context | Non modifie — shared-ai-context lit les champs tracking existants |
| Aucun 500 | Confirme |

---

## ETAPE 10 — NON-REGRESSION

| Non-regression | Resultat |
|---|---|
| PROD API image | `v3.5.135-lifecycle-pilot-safety-gates-prod` — **INCHANGEE** |
| PROD Client image | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` — **INCHANGEE** |
| PROD Admin image | `v2.11.37-acquisition-baseline-truth-prod` — **INCHANGEE** |
| PROD Website image | `v0.6.8-tiktok-browser-pixel-prod` — **INCHANGEE** |
| PROD CronJobs | 3 (outbound-tick, sla-evaluator, trial-lifecycle-dryrun) — **INCHANGES** |
| 0 billing mutation | Confirme |
| 0 tracking marketing mutation | Confirme |
| 0 CAPI | Confirme |
| 0 GA4 | Confirme |
| 0 fake spend | Confirme |
| 0 secret expose | Confirme |
| Pod API DEV restarts | 0 |
| CronJobs lifecycle email | INCHANGES (trial-lifecycle-dryrun PROD) |

---

## ETAPE 11 — PLAN PROD FUTUR

Phase suivante recommandee :

**PH-SAAS-T8.12AC-17TRACK-ORDER-TRACKING-ACTIVATION-PROD-PROMOTION-01**

Plan :

1. **Preflight PROD** — verifier image, secrets, routes, DB schema
2. **CronJob PROD GitOps** — creer `k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml`
   - Schedule : `0 */4 * * *` (toutes les 4h PROD, plus conservateur)
   - `suspend: true` initialement
3. **Premier run PROD controle** — `kubectl create job --from=cronjob/carrier-tracking-poll test-poll-prod-1 -n keybuzz-api-prod`
4. **Monitoring 24h** — surveiller tracking_events, orders, logs, erreurs
5. **Si OK** — passer `suspend: false` via GitOps
6. **Webhook PROD** — configurer `https://api.keybuzz.io/api/v1/tracking/webhook/17track` sur dashboard 17TRACK
7. **Rollback GitOps** — `kubectl delete cronjob carrier-tracking-poll -n keybuzz-api-prod` + revert manifest

---

## GAPS RESTANTS

| Gap | Severite | Action |
|---|---|---|
| Webhook 17TRACK DEV non configure sur dashboard 17TRACK | Faible | Manuel — voir runbook ci-dessus |
| HTTP 429 17TRACK lors du poll de 100 ordres | Faible | Schedule 2h suffit, ou reduire LIMIT |
| 99/100 ordres sans donnees 17TRACK (non enregistres) | Attendu | Les ordres doivent etre d'abord `register` (5 par poll max) |
| Pas de verification signature webhook | Moyen | A ajouter en phase future (securite) |
| Image CronJob curl-jq:latest | Note | Meme pattern que outbound-tick, a versionner en phase future |

---

## ROLLBACK GITOPS

```bash
# Supprimer le CronJob DEV
kubectl delete cronjob carrier-tracking-poll -n keybuzz-api-dev

# Revert le manifest
cd /opt/keybuzz/keybuzz-infra
git revert b0db751
git push
```

---

## CONFIRMATIONS FINALES

- **PROD inchangee** : OUI — toutes les images et CronJobs PROD sont identiques avant/apres
- **Aucun secret expose** : OUI — aucune valeur de cle dans ce rapport, logs ou scripts
- **Aucun faux tracking event** : OUI — les 17 nouveaux events proviennent d'un poll reel UPS
- **Aucun build** : OUI — seul un CronJob curl a ete cree
- **Aucun code modifie** : OUI — le endpoint existe deja dans l'image runtime

---

## VERDICT

**GO PARTIEL DEV CRONJOB CREATED WEBHOOK MANUAL**

17TRACK ACTIVATION LAYER READY IN DEV — CARRIER TRACKING POLL CRONJOB CREATED VIA GITOPS — POLLING VALIDATED SAFELY — WEBHOOK READINESS DOCUMENTED — NO PROD TOUCH — NO BILLING/TRACKING/CAPI DRIFT — READY FOR PROD PROMOTION PLAN
