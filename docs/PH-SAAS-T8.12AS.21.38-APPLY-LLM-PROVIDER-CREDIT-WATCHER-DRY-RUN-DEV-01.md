# PH-SAAS-T8.12AS.21.38 - Apply LLM Provider Credit Watcher Dry Run DEV

## Verdict

GO APPLY LLM PROVIDER CREDIT WATCHER DRY RUN DEV ACTION_REQUIRED_ALERT_RISK PH-SAAS-T8.12AS.21.38

## Objectif

Apply GitOps DEV uniquement du watcher monitoring-alerts LLM provider credit en mode dry-run/log-only. Aucun build, docker push, deploy API, DB mutation, LLM call, fake event, Slack/email/webhook, Linear ou PROD.

## Sources relues

| Source | Statut |
| --- | --- |
| AI_MEMORY CURRENT_STATE/RULES_AND_RISKS/DOCUMENT_MAP/CE_PROMPTING_STANDARD | relu localement |
| Modele PH-T8.10J | relu selon standard CE |
| PH-21.28 / PH-21.34 / PH-21.35-BIS / PH-21.35-TER / PH-21.36 / PH-21.37 returns | relus |
| Rapports distants PH-21.28 / 21.34 / 21.36 / 21.37 | relus |
| Manifests monitoring-alerts et tests PH-21.28/21.34 | audites |

## Preflight

| Point | Observe | Verdict |
| --- | --- | --- |
| Bastion | install-v3 46.62.171.61 10.0.0.251 172.17.0.1 2a01:4f9:c013:87d6::1 2026-06-03T09:13:46Z  | OK |
| Kube context | kubernetes-admin@kubernetes | OK |

| Repo | Branche attendue | Branche observee | HEAD | Origin | Ahead/Behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-infra | main | main | 70dd1cc102d8 | 70dd1cc102d8 | 0/0 | 1 | OK |
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 76483e3a0e10 | 76483e3a0e10 | read-only | 223 preexisting dist deletions | OK |

## Phase lineage

| Phase | Fait prouve | Commit/Image/Digest | Impact PH-21.38 |
| --- | --- | --- | --- |
| PH-21.28 | Endpoint et watcher source ajoutes | API 76483e3a, Infra 00a2958 | source LLM watcher |
| PH-21.34 | Secret source/config prepare et pousse | Infra 41f963b | secretRef dedie |
| PH-21.36 | ExternalSecrets + API env appliques | API DEV digest sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 | token synchronise metadata-only |
| PH-21.37 | Endpoint authentifie 200, response safe | Infra docs 70dd1cc1 | watcher peut appeler API DEV |

## Tests

| Test | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.28 monitoring-alerts tests | PASS | PH21.28 monitoring-alerts tests PASS | PASS |
| PH-21.34 manifest tests | PASS | PH21.34 manifest tests PASS | PASS |
| YAML parse monitoring-alerts | PASS | YAML_PARSE=PASS | PASS |
| git diff --check cible | PASS | DIFF_CHECK=PASS | PASS |
| dry-run client/server | non execute | stop pre-apply apres detection SMTP/email active | ACTION_REQUIRED_ALERT_RISK |

## Manifest Audit

| Fichier | Marker/setting | Attendu | Observe | Verdict |
| --- | --- | --- | --- | --- |
 |  | configmap-script.yaml | check_llm_provider_credit | present | present | OK |
 |  | configmap-script.yaml | self-test marker | present | present | OK |
 |  | configmap-script.yaml | monitor header | present | present | OK |
 |  | configmap-script.yaml | LLM dry/log-only return before add_alert | present | present | OK |
 |  | cronjob.yaml | target env | dev | dev | OK |
 |  | cronjob.yaml | dry run | true | true | OK |
 |  | cronjob.yaml | log only | true | true | OK |
 |  | cronjob.yaml | DEV URL | keybuzz-api-dev | http://keybuzz-api.keybuzz-api-dev.svc.cluster.local:3001/internal/monitoring/llm-provider-credit | OK |
 |  | cronjob.yaml | DEV window seconds | 3600 | 3600 | OK |
 |  | cronjob.yaml | DEV threshold | 1 | 1 | OK |
 |  | cronjob.yaml | DEV debounce seconds | 21600 | 21600 | OK |
 |  | cronjob.yaml | token secretRef | monitoring-llm-provider-credit-token/token | monitoring-llm-provider-credit-token/token optional=true | OK |
| configmap-script.yaml | alert delivery global | LLM path must return before add_alert | Existing non-LLM deliver_alerts remains a documented SRE debt; LLM path log-only returns | OK_WITH_DEBT |

## Manifests appliques

| Manifest | Action | Sortie |
| --- | --- | --- |
| k8s/monitoring-alerts/configmap-state.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |
| k8s/monitoring-alerts/configmap-script.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |
| k8s/monitoring-alerts/cronjob.yaml | not applied | blocked before Etape 6/7 by active SMTP/email delivery markers |

## Dry-run Kubernetes

```text
Not executed. CE stopped before dry-run/apply because recent natural monitoring-alerts jobs already sent emails:
- 2026-06-03T09:08:00Z Sending 2 alerts / Email OK
- 2026-06-03T09:10:00Z Sending 2 alerts / Email OK
- 2026-06-03T09:12:00Z Sending 2 alerts / Email OK
```

## Runtime monitoring-alerts before

```text
UTC=2026-06-03T09:13:47Z
KUBE_CONTEXT=kubernetes-admin@kubernetes
API_DEV_DEPLOY=ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502

API_DEV_IMAGEID=ghcr.io/keybuzzio/keybuzz-api@sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996

API_DEV_RESTARTS=0

API_PROD_DEPLOY=ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422

API_PROD_IMAGEID=ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6

API_PROD_RESTARTS=0

CRON_IMAGE=curlimages/curl:8.7.1
CRON_SCHEDULE=*/2 * * * *
CRON_SUSPEND=false
CRON_LAST_SCHEDULE=2026-06-03T09:12:00Z
ENV_NAMES=VAULT_ADDR,ALERT_ENV,LOG_WINDOW,RESTART_THRESHOLD,ERROR_RATE_THRESHOLD,SMTP_HOST,SMTP_PORT,SMTP_FROM,SMTP_TO,WEBHOOK_URL
WATCHER_EXTERNALSECRET=NAME                                   STORETYPE            STORE           REFRESH INTERVAL   STATUS         READY
monitoring-llm-provider-credit-token   ClusterSecretStore   vault-backend   1h                 SecretSynced   True
WATCHER_SECRET_METADATA=NAME                                   TYPE     DATA   AGE
monitoring-llm-provider-credit-token   Opaque   1      111m
WEBHOOK_SECRET_METADATA=
STATE_CONFIGMAP=exists
STATE_CONFIGMAP_KEYS=none
LIVE_SCRIPT_HAS_CHECK=false
LIVE_SCRIPT_HAS_DRYRUN_LOGONLY=false
LIVE_SCRIPT_HAS_MONITOR_HEADER=false
LIVE_SCRIPT_HAS_DELIVER_ALERTS=true
```

## Runtime monitoring-alerts after

```text
Not captured. No manifest was applied because ACTION_REQUIRED_ALERT_RISK was reached before mutation.
```

## Observation execution naturelle CronJob

| Job/Pod | Heure UTC | Marker observe | Slack/email | Token leak | Verdict |
| --- | --- | --- | --- | --- | --- |
| none | n/a | pre-apply SMTP/email markers already active in recent natural jobs | see before logs | 0 | ACTION_REQUIRED_ALERT_RISK |

Blocage exact:

- `monitoring-alerts-29674628` a logge `Sending 2 alerts` puis `Email OK` a 2026-06-03 09:08:11 UTC.
- `monitoring-alerts-29674630` a logge `Sending 2 alerts` puis `Email OK` a 2026-06-03 09:10:09 UTC.
- `monitoring-alerts-29674632` a logge `Sending 2 alerts` puis `Email OK` a 2026-06-03 09:12:10 UTC.
- Ces envois etaient deja actifs avant tout apply PH-21.38; CE a donc stoppe sans mutation.

Safe log excerpts:

```text
[2026-06-03 09:08:11 UTC] Sending 2 alerts
[2026-06-03 09:08:11 UTC]   Email OK
[2026-06-03 09:10:09 UTC] Sending 2 alerts
[2026-06-03 09:10:09 UTC]   Email OK
[2026-06-03 09:12:10 UTC] Sending 2 alerts
[2026-06-03 09:12:10 UTC]   Email OK
```

## No fake metrics / no fake events

| Interdit | Statut |
| --- | --- |
| fake ai_usage / provider credit | non effectue |
| fake tracking/conversion/KBActions | non effectue |
| LLM call | non effectue |
| manual CronJob trigger | non effectue |
| Slack/email/webhook volontaire | non effectue par CE; risque actif preexistant detecte avant apply |
| Natural provider credit incident | TRAFFIC_REQUIRED / NO_NATURAL_PROVIDER_CREDIT_INCIDENT si count=0 |

## AI feature parity / anti-regression

| Surface IA | Point verifie | Source/log/runtime | Resultat |
| --- | --- | --- | --- |
| API DEV | image v3.5.263 conservee | runtime snapshot | OK |
| API DEV | endpoint /internal/monitoring/llm-provider-credit present | PH-21.37 + runtime marker | OK |
| API DEV | marker PROVIDER_CREDIT_EXHAUSTED conserve | source PH-21.28/21.37 | OK |
| Runtime API | dist/tests absent | image audit anterieure PH-21.31/21.32, non touchee ici | OK |
| Watcher | aucun appel LLM | script monitoring logs + scope | OK |
| KBActions | aucun debit | DB delta | OK |
| AI Assist / Autopilot / Returns Analysis | non modifies | scope monitoring-alerts only | OK |
| Amazon outbound/inbound | aucun trigger manuel | logs/scope | OK |

## Snapshots DB/logs before/after

| Signal | Before | After | Delta | Verdict |
| --- | --- | --- | --- | --- |
| ai_usage | 637 | not captured | n/a | OK_NO_MUTATION_BEFORE_STOP |
| ai_actions_ledger | 556 | not captured | n/a | OK_NO_MUTATION_BEFORE_STOP |
| ai_suggestion_events | 2736 | not captured | n/a | OK_NO_MUTATION_BEFORE_STOP |
| conversion_events | 0 | not captured | n/a | OK_NO_MUTATION_BEFORE_STOP |
| outbound_delivery_logs | ABSENT | not captured | n/a | OK_NO_MUTATION_BEFORE_STOP |
| monitoring-alerts delivery markers before | 3 | not captured | n/a | ACTION_REQUIRED_ALERT_RISK |
| token-like markers after | n/a | 0 | n/a | OK |

## Non-regression DEV/PROD

| Service | Namespace | Image avant | Image apres | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | keybuzz-api-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev 1/1 generation=502 observed=502 | unchanged by CE; no apply executed | 1/1 before stop | 0 before stop | OK_NO_MUTATION |
| keybuzz-api | keybuzz-api-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod 1/1 generation=422 observed=422 | unchanged by CE; no apply executed | 1/1 before stop | 0 before stop | OK_NO_MUTATION |
| monitoring-alerts | vault-management | curlimages/curl:8.7.1 | unchanged by CE; no apply executed | cron active before stop | n/a | OK_NO_MUTATION |

## Interdits respectes

| Interdit | Statut |
| --- | --- |
| Secret/token/cookie/header affiche | 0 valeur affichee |
| Secret.data / base64 decode | 0 |
| Vault value read/write | 0 |
| build/docker push/API deploy/PROD | 0 |
| kubectl set/patch/edit/replace/create job | 0 |
| DB mutation/LLM/fake event/Linear | 0 |

## Rollback GitOps

Rollback non execute. Si GO explicite: revert du commit source/config monitoring-alerts concerne, push normal, puis kubectl apply -f du configmap-script et cronjob revenus par Git. Pas de kubectl patch/edit/set/replace.

## Dettes et limites

- Le canal SMTP global preexistant dans monitoring-alerts reste une dette SRE hors scope. Le chemin LLM provider credit retourne avant add_alert quand DRY_RUN ou LOG_ONLY vaut true.
- Si aucun incident naturel PROVIDER_CREDIT_EXHAUSTED n'apparait, la preuve live reste TRAFFIC_REQUIRED / NO_NATURAL_PROVIDER_CREDIT_INCIDENT.
- L'observation est limitee a une fenetre de 5 minutes sans trigger manuel.

## Rapport / Git

| Repo | HEAD | Origin | Ahead/Behind | Dirty |
| --- | --- | --- | --- | --- |
| keybuzz-infra | 70dd1cc102d8 | 70dd1cc102d8 | 0/0 | 1 |
| keybuzz-api | 76483e3a0e10 | 76483e3a0e10 | read-only | dist deletions preexistantes |

## Prochain GO recommande

ACTION REQUIRED before retrying PH-21.38: resolve or isolate the preexisting monitoring-alerts SMTP/email delivery risk. Recommended next GO:

GO READONLY DESIGN MONITORING-ALERTS EMAIL DELIVERY SAFETY DEV PH-SAAS-T8.12AS.21.38-BIS

## LINEAR_PREPARED_TEXT

PH-21.38 s'est arretee avant apply: les jobs naturels monitoring-alerts envoyaient deja des emails (Sending 2 alerts / Email OK) avant mutation. Aucun manifest n'a ete applique, aucun build, Docker push, DB mutation, LLM call, fake event, trigger manuel, Linear ou PROD. Action requise: traiter/isoler le risque SMTP/email avant de relancer l'apply watcher dry-run/log-only.
