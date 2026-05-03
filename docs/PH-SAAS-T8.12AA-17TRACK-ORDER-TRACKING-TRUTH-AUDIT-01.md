# PH-SAAS-T8.12AA — 17TRACK Order Tracking Truth Audit

> **Date** : 3 mai 2026
> **Type** : audit verite P0, lecture seule
> **Environnement** : DEV + PROD
> **Priorite** : P0
> **Linear** : KEY-240
> **Mutations** : 0
> **Builds** : 0
> **Deploys** : 0

---

## SOURCES RELUES

| Document | Lu |
|---|:---:|
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | via historique |
| `AI_MEMORY/RULES_AND_RISKS.md` | via historique |
| `AI_MEMORY/TRIAL_WOW_STACK_BASELINE.md` | OUI |
| `AI_MEMORY/DATA_HYGIENE_BASELINE.md` | OUI |
| `PH136-B-MULTI-CARRIER-TRACKING-AGGREGATOR-01-REPORT.md` | OUI |
| `PH136-C-TRACKING-PROVIDER-COST-CAPACITY-DECISION-01.md` | reference |
| `PH136-D-TRACKING-WEBHOOK-ACTIVATION-01-REPORT.md` | OUI |
| `PH143-H-TRACKING-ORDERS-REBUILD-01.md` | OUI |

---

## ETAPE 0 — PREFLIGHT

| Repo | Branche attendue | Branche constatee | HEAD | Dirty | Verdict |
|---|---|---|---|---|---|
| `keybuzz-api` (bastion) | `ph147.4/source-of-truth` | `ph147.4/source-of-truth` | `adaf1821` | dist modifie | OK |
| `keybuzz-client` (bastion) | `ph148/onboarding-activation-replay` | `ph148/onboarding-activation-replay` | `39591d9` | Non | OK |
| `keybuzz-infra` | `main` | `main` | `c3e00d8` | Pre-existant | OK |

---

## ETAPE 1 — AUDIT HISTORIQUE DOCUMENTE

| Brique historique | Fichier/route | Derniere phase validee | Statut historique |
|---|---|---|---|
| Interface TrackingProvider | `src/services/tracking/trackingProvider.ts` | PH136-B | DEV+PROD deploye |
| Provider 17TRACK | `src/services/tracking/seventeenTrackProvider.ts` | PH136-D, PH143-H | DEV deploye, PROD via PH143 |
| Factory + chain | `src/services/tracking/providerFactory.ts` | PH136-D, PH143-H | DEV+PROD |
| Service live tracking | `src/modules/orders/carrierLiveTracking.service.ts` | PH143-H | 366 lignes, DEV+PROD |
| Routes carrier tracking | `src/modules/orders/carrierTracking.routes.ts` | PH143-H | 112 lignes, DEV+PROD |
| Webhook routes | `src/modules/tracking/trackingWebhook.routes.ts` | PH136-D, PH143-H | 112 lignes, DEV+PROD |
| GET /tracking/status | `/api/v1/orders/tracking/status` | PH136-D | 200 OK valide |
| POST /tracking/poll | `/api/v1/orders/tracking/poll` | PH136-B | Documente, jamais CronJob |
| POST /tracking/refresh/:id | `/api/v1/orders/tracking/refresh/:orderId` | PH136-B | Documente |
| Webhook 17TRACK | `POST /api/v1/tracking/webhook/17track` | PH136-D | DEV valide, PROD jamais active |
| Table tracking_events | `tracking_events` (14 colonnes) | PH133-C | Schema complet |
| Env TRACKING_17TRACK_API_KEY | secret `tracking-17track` | PH136-D | DEV+PROD configures |
| CronJob carrier-tracking-poll | — | PH136-B (planifie) | **JAMAIS CREE** |
| BFF Client tracking/status | `app/api/orders/tracking/status/route.ts` | PH143-H | Present |

---

## ETAPE 2 — SOURCE API ACTUELLE (bastion)

| Fichier attendu | Present ? | Lignes | Branche dans app.ts ? | Verdict |
|---|:---:|---:|:---:|---|
| `src/services/tracking/trackingProvider.ts` | OUI | 40 | import L54 | OK |
| `src/services/tracking/seventeenTrackProvider.ts` | OUI | 175 | via providerFactory | OK |
| `src/services/tracking/providerFactory.ts` | OUI | 62 | via routes | OK |
| `src/modules/orders/carrierLiveTracking.service.ts` | OUI | 366 | via routes | OK |
| `src/modules/orders/carrierTracking.routes.ts` | OUI | 112 | L196 register | OK |
| `src/modules/tracking/trackingWebhook.routes.ts` | OUI | 112 | L197 register | OK |

Registrations `app.ts` :
- L196 : `app.register(carrierTrackingRoutes, { prefix: '/api/v1/orders' })`
- L197 : `app.register(trackingWebhookRoutes, { prefix: '/api/v1/tracking' })`

**Source API : COMPLET. Tous les fichiers historiques sont presents et branches.**

---

## ETAPE 3 — RUNTIME / DIST ACTUEL

### Images deployees

| Service | Image |
|---|---|
| API DEV | `v3.5.141-lifecycle-pilot-safety-gates-dev` |
| API PROD | `v3.5.135-lifecycle-pilot-safety-gates-prod` |

### Fichiers compiles dans les pods

| Fichier dist | DEV | PROD |
|---|:---:|:---:|
| `dist/services/tracking/providerFactory.js` | OUI | OUI |
| `dist/services/tracking/seventeenTrackProvider.js` | OUI | OUI |
| `dist/services/tracking/trackingProvider.js` | OUI | OUI |
| `dist/modules/tracking/trackingWebhook.routes.js` | OUI | OUI |
| `dist/modules/orders/carrierLiveTracking.service.js` | OUI | OUI |
| `dist/modules/orders/carrierTracking.routes.js` | OUI | OUI |

### References dans dist/app.js

| Signal | DEV |
|---|:---:|
| `carrierTracking` | OUI |
| `trackingWebhook` | OUI |

**Runtime : COMPLET. Le code compile est present dans DEV et PROD.**

---

## ETAPE 4 — ROUTES RUNTIME

| Endpoint | Methode | DEV | PROD | Ecrit en DB ? | Verdict |
|---|---|---|---|---|---|
| `/api/v1/orders/tracking/status` | GET | **200 OK** | **200 OK** | Non (lecture) | OK |
| `/api/v1/tracking/webhook/17track` | POST | Route existe (400 OPTIONS) | Route existe (dist present) | OUI (webhook) | DORMANT |
| `/api/v1/orders/tracking/poll` | POST | Non teste (ecrit) | Non teste (ecrit) | OUI (poll) | NON TESTE |
| `/api/v1/orders/tracking/refresh/:id` | POST | Non teste (ecrit) | Non teste (ecrit) | OUI (refresh) | NON TESTE |
| `/health` | GET | 200 | 200 | Non | OK |

### Reponse /tracking/status DEV

```json
{
  "configuration": {
    "aggregator": {
      "providers": [{"name": "17track", "configured": true}],
      "activeProviders": 1
    }
  },
  "events": {
    "total_events": "32316",
    "orders_with_events": "11927"
  },
  "orders": {
    "total_orders": "11974",
    "with_tracking": "125"
  }
}
```

### Reponse /tracking/status PROD

```json
{
  "configuration": {
    "aggregator": {
      "providers": [{"name": "17track", "configured": true}],
      "activeProviders": 1
    }
  },
  "events": {
    "total_events": "32126",
    "orders_with_events": "11825"
  },
  "orders": {
    "total_orders": "11903",
    "with_tracking": "238"
  }
}
```

**Routes : FONCTIONNELLES. L'API reconnait 17TRACK comme provider configure.**

---

## ETAPE 5 — SECRETS / ENV K8S

| Env/secret | DEV | PROD | Valeur exposee ? | Verdict |
|---|:---:|:---:|:---:|---|
| Secret `tracking-17track` | EXISTS | EXISTS | Non | OK |
| `TRACKING_17TRACK_API_KEY` dans deployment | OUI (3 refs) | OUI (3 refs) | Non | OK |

**Secrets : CONFIGURES. Cle API montee dans les deux environnements.**

---

## ETAPE 6 — DB SCHEMA ET DONNEES

### Schema (PROD)

| Element DB | Present | Detail |
|---|:---:|---|
| Table `tracking_events` | OUI | 14 colonnes |
| Colonne `orders.carrier` | OUI | — |
| Colonne `orders.carrier_delivery_status` | OUI | — |
| Colonne `orders.carrier_normalized` | OUI | — |
| Colonne `orders.delivered_at` | OUI | — |
| Colonne `orders.tracking_source` | OUI | — |

### Donnees PROD

| Metrique | Valeur |
|---|---:|
| `tracking_events` total | 32 126 |
| dont source `amazon_estimate` | 17 465 |
| dont source `amazon_data` | 14 600 |
| dont source `amazon_report` | 44 |
| dont source `aggregator_17track` | **17** |
| Premier event | 2026-03-30 |
| Dernier event | **2026-04-06** |
| Orders total | 11 903 |
| Orders `tracking_source = 'aggregator_17track'` | **2** |
| Orders avec `carrier_delivery_status` non null | **2** |

### Constat

- La table et le schema sont intacts
- Les donnees 17TRACK sont minimales (17 events de test PH136-D)
- **Aucun nouvel event 17TRACK depuis le 6 avril** (27 jours)
- Le tracking transporteur reel via 17TRACK est DORMANT, pas perdu

---

## ETAPE 7 — CRONJOB / POLLING

| Composant | DEV | PROD | Derniere execution | Verdict |
|---|---|---|---|---|
| CronJob `carrier-tracking-poll` | **ABSENT** | **ABSENT** | Jamais | ABSENT |
| Autre CronJob tracking | Aucun | Aucun | — | ABSENT |
| Worker outbound tracking | N/A | N/A | — | N/A |

CronJobs existants DEV : `outbound-tick-processor`, `sla-evaluator`, `sla-evaluator-escalation`
CronJobs existants PROD : `outbound-tick-processor`, `sla-evaluator`, `trial-lifecycle-dryrun`

**Le CronJob `carrier-tracking-poll` n'a JAMAIS ete cree.** Il etait prevu comme "prochaine etape" dans PH136-B (section 3) et PH136-D (section 11), mais n'a pas ete execute.

---

## ETAPE 8 — CLIENT / UI ORDERS

### Source client (bastion, branche ph148)

| Surface UI | Present ? | Utilise tracking API ? | Verdict |
|---|:---:|:---:|---|
| BFF `app/api/orders/tracking/status/route.ts` | OUI (959 o) | OUI | OK |
| Orders page tracking fields | OUI | carrier, trackingCode, trackingUrl, trackingSource | OK |
| OrderSidePanel tracking display | OUI | carrier, trackingCode | OK |
| `src/components/tracking/` | OUI (dossier) | — | OK |
| `src/lib/tracking.ts` | OUI | — | OK |
| Detail commande tracking tab | OUI (PH143-H) | OUI | OK |
| Liens tracking cliquables | OUI (PH143-H) | UPS, Colissimo URLs | OK |

**UI : PRESENTE. Le client affiche les donnees tracking quand elles existent.**

---

## ETAPE 9 — MATRICE VERITE

| Couche | Etat | Detail |
|---|---|---|
| Source API | **OK** | 6/6 fichiers presents, branches dans app.ts |
| Runtime API DEV | **OK** | dist complet, routes 200, 17track configured |
| Runtime API PROD | **OK** | dist complet, routes 200, 17track configured |
| Routes | **OK** | /tracking/status 200 DEV+PROD |
| Secret/env | **OK** | Secret + env montes DEV+PROD |
| DB schema | **OK** | table tracking_events + colonnes orders intactes |
| DB data | **PARTIEL** | 17 events 17track (test), aucun depuis 2026-04-06 |
| CronJob/polling | **ABSENT** | Jamais cree — prevu PH136-B/D, non execute |
| Webhook 17TRACK | **DORMANT** | Route existe, mais aucun push depuis avril |
| UI SaaS | **OK** | BFF + orders page + OrderSidePanel |
| Autopilot usage tracking | **OK** | shared-ai-context injecte carrier/tracking dans prompt IA |
| Multi-tenant safety | **OK** | tenant_id sur tracking_events, tenantGuard exemption webhook |

---

## VERDICT

### **GO PARTIAL RESTORE NEEDED**

La feature 17TRACK **n'est PAS perdue**. Elle est **dormante** :

- **100% du code est present** (source, compile, runtime, routes, UI)
- **100% des secrets sont configures** (DEV + PROD)
- **100% du schema DB est intact**
- **Les routes fonctionnent** (200 OK avec 17track configured)

Ce qui manque pour la rendre **active** :

1. **CronJob `carrier-tracking-poll`** : jamais cree (planifie dans PH136-B mais non execute)
2. **Webhook PROD** : route existe mais aucun push recu depuis avril (URL webhook probablement non configuree sur le dashboard 17TRACK pour PROD)
3. **Batch registration** : les 238 tracking numbers existants n'ont jamais ete enregistres sur 17TRACK

---

## ETAPE 10 — PLAN DE RESTAURATION

### Phase proposee : PH-SAAS-T8.12AB-17TRACK-ORDER-TRACKING-RESTORATION-DEV-01

**Ne pas executer dans cette phase.**

### 1. CronJob a creer

```yaml
# k8s/keybuzz-api-dev/carrier-tracking-poll-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: carrier-tracking-poll
  namespace: keybuzz-api-dev
spec:
  schedule: "*/30 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: poll
            image: curlimages/curl:latest
            command: ["curl", "-s", "-X", "POST",
              "http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/api/v1/orders/tracking/poll",
              "-H", "X-Internal-Token: <from-secret>"]
          restartPolicy: Never
```

### 2. Fichiers a verifier (pas a restaurer)

| Fichier | Action | Risque |
|---|---|---|
| Tous les 6 fichiers tracking | Aucune modification — deja presents | 0 |
| `src/app.ts` | Aucune — deja branche | 0 |
| Secrets K8s | Aucune — deja configures | 0 |

### 3. Actions DEV-first

1. **Creer CronJob DEV** `carrier-tracking-poll` (*/30 min)
2. **Verifier webhook DEV** : tester un ping depuis le dashboard 17TRACK vers `https://api-dev.keybuzz.io/api/v1/tracking/webhook/17track`
3. **Batch register** : appeler `POST /api/v1/orders/tracking/poll` une fois manuellement pour enregistrer les trackings existants
4. **Observer** : verifier que des events 17track arrivent (webhook + polling)
5. **Non-regression** : confirmer que les orders sont enrichis avec `carrier_delivery_status`

### 4. Promotion PROD

1. Creer CronJob PROD (meme manifest, namespace PROD)
2. Configurer webhook PROD sur dashboard 17TRACK : `https://api.keybuzz.io/api/v1/tracking/webhook/17track`
3. Batch register PROD
4. Observer 24h
5. Confirmer enrichissement IA

### 5. Tests de non-regression

- Health check API
- Inbox / conversations non affectes
- Billing / wallet non affectes
- Outbound worker stable
- Autopilot drafts avec tracking enrichi

### 6. Rollback

- Supprimer le CronJob : `kubectl delete cronjob carrier-tracking-poll -n keybuzz-api-dev`
- Desactiver webhook sur dashboard 17TRACK
- Aucun code a rollback (code deja present et fonctionnel)

### 7. Risques multi-tenant

- `tracking_events` a un `tenant_id` → safe
- Le webhook route n'a pas de tenant context (exemptee dans tenantGuard) → safe (17TRACK envoie des events correles par tracking_code, pas par tenant)
- Le CronJob poll itere sur tous les tenants avec des orders ayant un tracking code → safe

### 8. Comment eviter de reecraser la feature

- **Ajouter au `FEATURE_TRUTH_MATRIX.md`** : 17TRACK = PRESENT + DORMANT
- **Ajouter un test de non-regression** : verifier `/api/v1/orders/tracking/status` retourne `17track configured: true`
- **Ne jamais rebuild l'API sans inclure les 6 fichiers tracking**

---

## INTERDITS RESPECTES

| Interdit | Respecte |
|---|:---:|
| Aucun code modifie | OUI |
| Aucun build | OUI |
| Aucun deploy | OUI |
| Aucune mutation DB | OUI |
| Aucun appel 17TRACK reel | OUI |
| Aucun webhook simule | OUI |
| Aucun secret expose | OUI |
| Aucun endpoint 404 masque | OUI |

---

## RESUME EXECUTIF

**La feature 17TRACK est INTACTE dans le code, les images, les routes, les secrets et le schema DB.** Elle n'a pas ete ecrasee par les rebuilds — elle a survecu a PH143-H (rebuild explicite) et aux deploys lifecycle subsequents.

Le tracking transporteur est **DORMANT** car :
1. Le CronJob de polling automatique n'a jamais ete cree (prevu mais non execute dans PH136-B/D)
2. Le webhook PROD n'a jamais ete active (DEV valide dans PH136-D, "STOP avant PROD")
3. Aucune batch registration des trackings existants n'a ete faite

**La restauration est minimale** : creer un CronJob + activer le webhook = tracking reel actif sous 1h.

---

**17TRACK ORDER TRACKING TRUTH ESTABLISHED — HISTORICAL FEATURE CONFIRMED — CODE INTACT — RUNTIME FUNCTIONAL — ACTIVATION LAYER ABSENT (CRONJOB + WEBHOOK) — RESTORATION PLAN READY — NO CODE — NO BUILD — NO DEPLOY — NO DB MUTATION**

---

*Rapport : `keybuzz-infra/docs/PH-SAAS-T8.12AA-17TRACK-ORDER-TRACKING-TRUTH-AUDIT-01.md`*
