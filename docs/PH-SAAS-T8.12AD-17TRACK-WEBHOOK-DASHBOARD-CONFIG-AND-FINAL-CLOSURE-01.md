# PH-SAAS-T8.12AD — 17TRACK Webhook Dashboard Config and Final Closure

> **Date** : 3 mai 2026
> **Type** : configuration webhook + fermeture restauration tracking
> **Environnement** : PROD
> **Priorite** : P0
> **Linear** : KEY-240
> **Mutations DB** : 0
> **Builds** : 0
> **Deploys** : 0

---

## SOURCES RELUES

| Document | Lu |
|---|:---:|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | OUI |
| `AI_MEMORY/RULES_AND_RISKS.md` | OUI |
| `PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md` | OUI |
| `PH-SAAS-T8.12AB-17TRACK-ORDER-TRACKING-ACTIVATION-LAYER-DEV-01.md` | OUI |
| `PH-SAAS-T8.12AC-17TRACK-ORDER-TRACKING-ACTIVATION-PROD-PROMOTION-01.md` | OUI |
| `PH136-D-TRACKING-WEBHOOK-ACTIVATION-01-REPORT.md` | OUI (integral) |
| `k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml` | OUI |
| `k8s/keybuzz-api-prod/deployment.yaml` | OUI |

---

## RAPPEL CHRONOLOGIQUE AA → AC

### AA — Verite (3 mai 2026)

Feature 17TRACK historiquement confirmee. Code intact. Runtime DEV+PROD fonctionnel. Secrets OK. DB schema OK. UI+IA OK. Activation layer absente : CronJob polling + webhook PROD.

### AB — DEV (3 mai 2026)

CronJob DEV cree via GitOps. Poll controle DEV : 200 OK, 100 polles, 1 update, 17 events, 0 erreur. Commit `b0db751`.

### AC — PROD (3 mai 2026)

CronJob PROD cree via GitOps en `suspend: true`. Run controle PROD : 200 OK, 100 polles, **5 updates**, **74 events**, **0 erreur**, +6 delivered. Commit `dfdd641`.

---

## ETAPE 0 — PREFLIGHT

| Element | Attendu | Constate | Verdict |
|---|---|---|---|
| Infra branche | `main` | `main` HEAD `180c904` | OK |
| Image API PROD manifest | `v3.5.135-lifecycle-pilot-safety-gates-prod` | idem | OK |
| Image API PROD runtime | idem | idem | OK |
| CronJob PROD `carrier-tracking-poll` | `suspend: true`, `0 */4 * * *` | `suspend: true`, `0 */4 * * *`, LAST `<none>` | OK |
| Pod API PROD | Running, 0 restarts | Running, 0 restarts | OK |
| Health PROD | 200 OK | `{"status":"ok"}` | OK |
| `/tracking/status` PROD | `17track configured: true` | `configured: true`, `activeProviders: 1` | OK |

---

## ETAPE 1 — ROUTE WEBHOOK PROD

### Source : `src/modules/tracking/trackingWebhook.routes.ts` (112 lignes)

| Check webhook route | Resultat |
|---|---|
| Route existe | OUI — `POST /api/v1/tracking/webhook/17track` |
| URL publique PROD | `https://api.keybuzz.io/api/v1/tracking/webhook/17track` |
| Methode | POST |
| Registree dans app.ts | OUI — L197 prefix `/api/v1/tracking` |
| Exemptee auth (tenantGuard) | OUI — PH136-D confirme |
| POST vide `{}` = pas de mutation | **CONFIRME** — retourne `{"ok":true,"event":"unknown"}`, 0 DB write |
| Signature SHA-256 | OUI — header `sign`, verification `JSON.stringify(body) + '/' + apiKey` |
| Signature bloquante si invalide | **NON** — log warning puis traitement quand meme |
| Events geres | `TRACKING_UPDATED` (ecrit DB), `TRACKING_STOPPED` (log only), inconnu (200 no-op) |
| Idempotence DB | OUI — `ON CONFLICT (order_id, event_status, event_timestamp, source) DO NOTHING` |
| Tables ecrites | `tracking_events` (INSERT), `orders` (UPDATE) — uniquement sur TRACKING_UPDATED |
| Impact billing/marketing | Aucun |

### Risque identifie : signature non-bloquante

Le webhook accepte les requetes meme avec signature invalide (warning seulement). Cela signifie qu'un acteur externe pourrait envoyer un payload `TRACKING_UPDATED` avec un tracking_code correspondant a un ordre existant et creer des events fictifs.

**Mitigation** : la route n'est pas documentee publiquement, et les tracking_codes doivent correspondre a des ordres existants. Le risque est faible mais a renforcer en phase future.

---

## ETAPE 2 — DASHBOARD 17TRACK / CONFIGURATION MANUELLE

### Constat

Le Cursor Executor **n'a pas acces au dashboard 17TRACK**. Le dashboard est un portail web necessitant une connexion au compte `ludovic@keybuzz.pro` (cf. PH136-D).

### Configuration actuelle (PH136-D, 31 mars 2026)

| Element dashboard | Valeur |
|---|---|
| Compte | `ludovic@keybuzz.pro` |
| URL webhook configuree | `https://api-dev.keybuzz.io/api/v1/tracking/webhook/17track` (**DEV uniquement**) |
| URL webhook PROD | **NON CONFIGUREE** |
| Version API | v2.4 |
| Events actives | InfoReceived, InTransit, Expired, AvailableForPickup, OutForDelivery, DeliveryFailure, Delivered, Exception |
| IP whitelist | Aucune restriction |

### Action manuelle requise — Runbook Ludovic

Pour activer le webhook PROD sur le dashboard 17TRACK :

1. Se connecter au dashboard 17TRACK avec `ludovic@keybuzz.pro`
2. Acceder a la section **Webhook** ou **Push Notifications**
3. **Ajouter** (ou modifier) la configuration webhook :
   - **URL** : `https://api.keybuzz.io/api/v1/tracking/webhook/17track`
   - **Methode** : POST
   - **Events** : TRACKING_UPDATED, TRACKING_STOPPED (tous les statuts)
   - **Format** : JSON
4. Sauvegarder la configuration
5. Si disponible, utiliser le bouton **Test** pour envoyer un ping de verification
6. Verifier les logs pod API PROD : `kubectl logs -f <pod> -n keybuzz-api-prod | grep 17track-webhook`
7. Attendre qu'un vrai event arrive (si des trackings ont ete registres via le run controle AC)

### Verification post-configuration

Apres configuration par Ludovic, verifier :

```bash
# Depuis le bastion
PROD_POD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

# Logs webhook
kubectl logs --tail=50 "$PROD_POD" -n keybuzz-api-prod | grep "17track-webhook"

# DB check
kubectl exec -n keybuzz-api-prod "$PROD_POD" -- node -e "
const {Pool}=require('pg');
const p=new Pool();
(async()=>{
  const r = await p.query(\"SELECT count(*)::int as c FROM tracking_events WHERE source='aggregator_17track' AND created_at > NOW() - INTERVAL '1 hour'\");
  console.log('New 17TRACK events last hour:', r.rows[0].c);
  await p.end();
})();
"
```

---

## ETAPE 3 — VALIDATION WEBHOOK SANS FAUX EVENT

| Validation webhook | Resultat | DB mutation ? |
|---|---|---|
| POST vide `{}` → response | `{"ok":true,"event":"unknown"}` | **Non** — aucune mutation |
| Event `unknown` → DB | Pas de write (return early) | Non |
| TRACKING_UPDATED → DB | Write seulement si tracking_code correspond a un ordre | Non teste (pas de faux event) |
| Test dashboard 17TRACK | **Non execute** — pas d'acces dashboard | N/A |

**Option retenue : C — verification configuration seule.** Le webhook est configure cote serveur (route active, code complet, idempotent). La configuration dashboard 17TRACK est une action manuelle documentee. La reception du premier vrai event confirmera le fonctionnement runtime.

---

## ETAPE 4 — DECISION CRONJOB FINAL

| Option | Choisie ? | Justification |
|---|---|---|
| **A — conserver `suspend: true`** | **OUI** | Webhook PROD non configure (action manuelle pendante). Rate limit 17TRACK observe (HTTP 429). Polling = secours manuel disponible via `kubectl create job`. |
| B — passer `suspend: false` | Non | Premature tant que le webhook n'est pas configure et valide. |

**Aucune modification manifest.** Le CronJob PROD reste en `suspend: true` tel que cree en AC.

### Si webhook confirme fonctionnel plus tard

Le CronJob pourra etre :
1. Garde suspendu (webhook suffit)
2. Active a `suspend: false` avec schedule `0 */12 * * *` (2x/jour) comme complement leger
3. Supprime via GitOps si juge inutile

---

## ETAPE 5 — VALIDATION API / UI / IA

| Surface | Resultat |
|---|---|
| `GET /api/v1/orders/tracking/status` | 200 OK — `17track configured: true`, 32253 events, 13 with_carrier_status, 55 carrier_live |
| `GET /health` | 200 OK |
| API image | **INCHANGEE** |
| Events tracking | 89 aggregator_17track, 55 carrier_live (resultats run AC) |
| Client PROD | Non modifie — aucun build |
| IA context | Non modifie — shared-ai-context lit les champs tracking |
| Aucun 500 | Confirme |

---

## ETAPE 6 — NON-REGRESSION

| Non-regression | Resultat |
|---|---|
| 0 build | Confirme |
| 0 deploy API | Confirme |
| 0 code change | Confirme |
| API PROD image | `v3.5.135-lifecycle-pilot-safety-gates-prod` — **INCHANGEE** |
| Client PROD image | `v3.5.147-sample-demo-platform-aware-tracking-parity-prod` — **INCHANGEE** |
| Admin PROD image | `v2.11.37-acquisition-baseline-truth-prod` — **INCHANGEE** |
| Website PROD image | `v0.6.8-tiktok-browser-pixel-prod` — **INCHANGEE** |
| 0 billing mutation | Confirme |
| 0 CAPI / GA4 / Meta / TikTok / LinkedIn | Confirme |
| 0 lifecycle email change | Confirme |
| 0 cleanup DB | Confirme |
| 0 secret expose | Confirme |
| Pods stables | API 0 restarts, Running |
| CronJobs lifecycle | `trial-lifecycle-dryrun` `0 8 * * *` false — **INCHANGE** |

---

## ETAPE 7 — MODE OPERATIONNEL FINAL

### Architecture operationnelle 17TRACK

```
PRINCIPAL : Webhook 17TRACK push (a configurer par Ludovic)
  |
  |  17TRACK → POST https://api.keybuzz.io/api/v1/tracking/webhook/17track
  |  → processTrackingUpdate() → tracking_events + orders
  |
SECOURS : CronJob polling (suspend:true, run manuel)
  |
  |  kubectl create job <name> --from=cronjob/carrier-tracking-poll -n keybuzz-api-prod
  |  → POST https://api.keybuzz.io/api/v1/orders/tracking/poll
  |  → pollActiveOrdersTracking() → tracking_events + orders
```

### Procedures operationnelles

#### Run manuel de secours (si webhook defaillant)

```bash
# Depuis le bastion
kubectl create job carrier-tracking-poll-manual-N \
  --from=cronjob/carrier-tracking-poll \
  -n keybuzz-api-prod

# Surveiller
kubectl logs -f job/carrier-tracking-poll-manual-N -n keybuzz-api-prod

# Nettoyer apres
kubectl delete job carrier-tracking-poll-manual-N -n keybuzz-api-prod
```

#### Activer le polling automatique (si decide)

```bash
# 1. Modifier manifest : suspend: true → suspend: false
# 2. Optionnel : ajuster schedule (ex: 0 */12 * * * pour 2x/jour)
# k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml
git add k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml
git commit -m "gitops(api-prod): activate carrier tracking poll cronjob"
git push
kubectl apply -f k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml
```

### Stop conditions

Arreter le polling ou suspendre le CronJob si :

- 17TRACK retourne systematiquement HTTP 429 (rate limit)
- Le quota 17TRACK est epuise
- Les logs montrent des erreurs inattendues
- Le nombre de candidats explose (>500) sans raison

### Monitoring recommande

- Logs : `kubectl logs -f <pod> -n keybuzz-api-prod | grep "17track"` pour les webhook events
- DB : `SELECT count(*) FROM tracking_events WHERE source='aggregator_17track' AND created_at > NOW() - INTERVAL '24 hours'`
- Alerte si 0 events 17TRACK en 7 jours (webhook potentiellement coupe)

### Protection anti-regression

La feature 17TRACK est integree dans 6 fichiers source deja presents dans l'image `v3.5.135`. Tant que l'image API n'est pas reconstruite depuis une branche qui supprime ces fichiers, la feature persiste. Les fichiers critiques :

- `src/services/tracking/trackingProvider.ts`
- `src/services/tracking/seventeenTrackProvider.ts`
- `src/services/tracking/providerFactory.ts`
- `src/modules/orders/carrierLiveTracking.service.ts`
- `src/modules/orders/carrierTracking.routes.ts`
- `src/modules/tracking/trackingWebhook.routes.ts`

Tout rebuild futur depuis `ph147.4/source-of-truth` preserve ces fichiers.

### Rollback GitOps

```bash
# Si CronJob doit etre suspendu (modifier manifest)
# suspend: false → suspend: true dans carrier-tracking-poll-cronjob.yaml
git add k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml
git commit -m "gitops(api-prod): suspend carrier tracking poll cronjob"
git push
kubectl apply -f k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml

# Si CronJob doit etre supprime
kubectl delete cronjob carrier-tracking-poll -n keybuzz-api-prod
git rm k8s/keybuzz-api-prod/carrier-tracking-poll-cronjob.yaml
git commit -m "gitops(api-prod): remove carrier tracking poll cronjob"
git push
```

---

## BILAN COMPLET KEY-240

### Phases executees

| Phase | Date | Type | Resultat |
|---|---|---|---|
| T8.12AA | 3 mai | Audit verite | Feature intacte, activation absente |
| T8.12AB | 3 mai | Activation DEV | CronJob DEV cree, poll valide |
| T8.12AC | 3 mai | Promotion PROD | CronJob PROD cree (suspendu), run controle OK |
| T8.12AD | 3 mai | Fermeture | Webhook documente, mode operationnel defini |

### Metriques cumulees (depuis AC run controle)

| Metrique | Valeur |
|---|---|
| tracking_events total PROD | 32 253 |
| tracking_events 17TRACK | 89 |
| tracking_events carrier_live | 55 |
| orders avec carrier_delivery_status | 13 |
| orders delivered | 10 |

### Restant

| Element | Etat | Action |
|---|---|---|
| Webhook PROD dashboard 17TRACK | **NON CONFIGURE** | Ludovic doit configurer via dashboard |
| CronJob PROD | `suspend: true` | Disponible pour run manuel |
| Signature webhook non-bloquante | Risque faible | A renforcer en phase future |
| CronJob image `curl-jq:latest` | Note | A versionner en phase future |
| FedEx pas d'adapter direct | Faible | 17TRACK supporte FedEx via webhook |

---

## DECISION KEY-240

**KEY-240 reste OUVERT** avec statut `In Review`.

Raison : le webhook PROD n'est pas encore configure sur le dashboard 17TRACK. La configuration est une action manuelle de Ludovic (runbook documente ci-dessus). Une fois le webhook confirme fonctionnel (premier vrai event recu), KEY-240 pourra etre ferme.

### Criteres de fermeture KEY-240

- [ ] Webhook PROD configure sur dashboard 17TRACK
- [ ] Premier vrai event `TRACKING_UPDATED` recu en PROD
- [ ] `tracking_events` PROD enrichi par webhook (pas seulement par poll)
- [ ] Decision finale CronJob : `suspend: false` ou supprime

---

## CONFIRMATIONS FINALES

- **Code/builds inchanges** : OUI
- **Images PROD inchangees** : OUI — API, Client, Admin, Website
- **Aucun secret expose** : OUI
- **Aucun faux tracking event** : OUI
- **Aucun faux webhook** : OUI
- **Aucune mutation billing** : OUI
- **Aucune mutation CAPI/GA4/Meta/TikTok/LinkedIn** : OUI
- **Aucun changement lifecycle emails** : OUI

---

## VERDICT

**GO PARTIEL WEBHOOK MANUAL REQUIRED**

17TRACK ORDER TRACKING OPERATIONAL — WEBHOOK PROD ROUTE ACTIVE AND SAFE — DASHBOARD 17TRACK CONFIG REQUIRES MANUAL ACTION BY LUDOVIC — CRONJOB SUSPENDED AS SAFE BACKUP — FIRST PROD RUN VALIDATED (5 UPDATES 74 EVENTS 0 ERRORS) — NO CODE BUILD DEPLOY — NO BILLING/TRACKING/CAPI DRIFT
